# -*- coding: utf-8 -*-
# Stuendlicher, von Thunderbird UNABHAENGIGER Lauf: holt neue Nachrichten
# direkt per POP3 vom M-Net-Konto (demselben Konto, das auch Thunderbird
# nutzt - "diabetologie@dachau-mail.de" ist nur eine von mehreren dort
# konfigurierten Absender-Identitaeten, siehe prefs.js: account8/server8,
# hostname pop.mnet-online.de, Port 110, STARTTLS, Login "m1000031511").
# Fuer Nachrichten von/an TARGET_ALIAS: gegen bekannte Patientenadressen
# (patstamm.FEmail + quelle.pat_email_adr, wie archive_patient_emails.py)
# pruefen, bei Treffer als PDF nach P:\dok ablegen und in quelle.dokprotlist
# eintragen - schreibt NIE nach medoff.
#
# Bewusst READ-ONLY per POP3 (kein DELE, leave_on_server bleibt unberuehrt) -
# Thunderbird kann parallel ganz normal weiter dieselbe Mailbox abholen,
# ohne dass sich beide in die Quere kommen. "Ab dem Zeitpunkt des letzten
# Laufs" wird ueber zwei sich ergaenzende Mechanismen sichergestellt:
#   1. UIDL-Checkpoint (poll_diabetologie_uidl.txt) - verhindert, dass bei
#      jedem stuendlichen Lauf die GESAMTE Mailbox erneut abgeholt wird.
#   2. archive_seen_cache.sqlite (dieselbe Datei wie archive_patient_emails.py)
#      - Absicherung nach Inhalts-Hash. Da eine per POP3 frisch geholte
#      Nachricht (noch ohne die X-Mozilla-*-Header, die Thunderbird beim
#      lokalen Speichern ergaenzt) einen ANDEREN Rohtext-Hash hat als
#      dieselbe, spaeter von Thunderbird lokal gespeicherte Kopie, greift
#      dieser schnelle Kurzschluss zwischen den beiden Skripten nicht
#      zuverlaessig - als eigentliche Absicherung gegen doppelte PDFs dient
#      daher (wie in archive_patient_emails.py) der inhaltliche Text-
#      Vergleich gegen bereits in P:\dok vorhandene Dateien (emails.
#      dok_text_cache) VOR dem tatsaechlichen Speichern.
import email, email.policy, email.utils, hashlib, os, poplib, ssl, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.stdout.reconfigure(encoding="utf-8", errors="replace", line_buffering=True)

from archive_patient_emails import (
    DOK_ROOT, OWN_ACCOUNT_EMAILS, decode_header_val, parse_from_header,
    parse_addr_list, sanitize, cap_filename_length, gebdat_to_sql,
    log_dokprot, open_seen_cache, mark_seen, connect_dokprot,
    render_message, extract_attachments, extract_pdf_text, normalize_pdf_text,
    get_header, build_name_prefix,
)
import patient_addresses_db as padb
import mail_id_cache
from audit_log import AuditLog, get_run_ts, get_run_phase
import pymysql
from io import BytesIO

# Windows: Passwortdateien DPAPI-verschluesselt (siehe secure_pwd.py) - nur
# unter diesem Windows-Konto auf diesem PC entschluesselbar. Neu erstellen
# bei Passwort-/PC-/Kontowechsel: jeweilige Datei mit neuem Klartext-
# Passwort ueberschreiben, dann "python migrate_pwd_to_dpapi.py" ausfuehren.
# Linux (linux1, Cron - siehe [[project-missing-patient-emails]]): kein DPAPI
# verfuegbar/noetig - medoff-Zugang wie bei den anderen linux1-Skripten ueber
# linux1_medoff_connect.py (/root/.modbpwd), POP3-Passwort als einfache
# Klartextdatei mit restriktiven Unix-Rechten (gleiche Konvention wie
# /root/.modbpwd/.mariadbrpwd auf diesem Rechner - kein Windows-DPAPI-
# Aequivalent unter Linux vorhanden/ueblich).
PWD_FILE = r"C:\Mail\Thunderbird\Profiles\medoff.pwd"
POP_HOST = "pop.mnet-online.de"
POP_PORT = 110
POP_USER = "m1000031511"
POP_PWD_FILE = r"C:\Mail\Thunderbird\Profiles\diabetologie_pop.pwd"
POP_PWD_FILE_LINUX = "/root/.diabetologie_pop_pwd"
UIDL_CHECKPOINT_FILE = os.environ.get(
    "UIDL_CHECKPOINT_FILE", r"C:\Mail\Thunderbird\Profiles\diabetologie_pop_uidl.txt")
TARGET_ALIAS = "diabetologie@dachau-mail.de"
# Takt fuer --daemon (linux1): im Normalfall (nichts Neues) nur zwei billige
# indexierte Abfragen + eine POP3-UIDL-Abfrage pro Zyklus - von der
# Netzwerklatenz zu POP_HOST dominiert, nicht von CPU/DB-Last, siehe
# [[project-missing-patient-emails]].
POLL_INTERVAL_SECONDS = 120


def read_pop_password():
    if sys.platform == "win32":
        import secure_pwd
        return secure_pwd.read_protected_password(POP_PWD_FILE)
    with open(POP_PWD_FILE_LINUX, encoding="utf-8") as f:
        return f.read().strip()


def load_last_uidl():
    if os.path.exists(UIDL_CHECKPOINT_FILE):
        with open(UIDL_CHECKPOINT_FILE, encoding="utf-8") as f:
            return f.read().strip() or None
    return None


def save_last_uidl(uidl):
    with open(UIDL_CHECKPOINT_FILE, "w", encoding="utf-8") as f:
        f.write(uidl)


def pop_connect(pwd):
    ctx = ssl.create_default_context()
    c = poplib.POP3(POP_HOST, POP_PORT, timeout=30)
    c.stls(context=ctx)
    c.user(POP_USER)
    c.pass_(pwd)
    return c


def connect_medoff():
    if sys.platform != "win32":
        import linux1_medoff_connect as conn_helper
        try:
            return conn_helper.connect_medoff()
        except Exception as e:
            print(f"FEHLER: medoff-Datenbank nicht erreichbar: {type(e).__name__}")
            sys.exit(3)
    import secure_pwd
    password = secure_pwd.read_protected_password(PWD_FILE)
    try:
        return pymysql.connect(host="wser", port=2020, user="medoff", password=password,
                                database="medoff", connect_timeout=10,
                                cursorclass=pymysql.cursors.DictCursor)
    except Exception as e:
        print(f"FEHLER: medoff-Datenbank (wser) nicht erreichbar: {type(e).__name__}")
        sys.exit(3)


def build_by_email():
    conn = connect_medoff()
    cur = conn.cursor()
    cur.execute("SELECT FSurogat, FVorname, FNachname, FTitel, FNamensvorsatz, FNamenszusatz, "
                "FEmail, FGeburtsdatum FROM patstamm "
                "WHERE FEmail IS NOT NULL AND FEmail <> ''")
    by_email = {}
    for p in cur.fetchall():
        addr = (p["FEmail"] or "").strip().lower()
        if addr:
            by_email[addr] = p

    padb_conn = padb.connect()
    staged = padb.addresses_by_patient(padb_conn)
    padb_conn.close()
    if staged:
        placeholders = ",".join(["%s"] * len(staged))
        cur.execute(f"SELECT FSurogat, FVorname, FNachname, FTitel, FNamensvorsatz, FNamenszusatz, "
                    f"FEmail, FGeburtsdatum FROM patstamm "
                    f"WHERE FSurogat IN ({placeholders})", tuple(staged.keys()))
        staged_patients = {str(p["FSurogat"]): p for p in cur.fetchall()}
        for pat_id, addrs in staged.items():
            info = staged_patients.get(pat_id)
            if info is None:
                continue
            for addr in addrs:
                by_email.setdefault(addr.strip().lower(), info)
    conn.close()
    return by_email


# Billige Aenderungserkennung fuer den Dauerdienst (--daemon, siehe unten):
# by_email (Namen+Emails+Geburtsdaten) wird bewusst NUR im Arbeitsspeicher
# gehalten, nie auf die Platte gecacht (keine neue Klartext-Ablage von
# Patientendaten) - build_by_email() (oben, teuer: liest patstamm komplett)
# wird daher nur neu aufgerufen, wenn sich seit dem letzten Check TATSAECHLICH
# etwas an einer der beiden Quellen geaendert hat:
#   - direkte medoff-Aenderungen -> dbsprot (dasselbe Muster wie
#     linux1_sync_medoff_changes.py: FSurogat waechst monoton, billiger
#     Cursor, gefiltert auf patstamm+<Email>-Tag).
#   - pat_email_adr-Aenderungen (Email-Adr.-Widget/Automatisierung) -> das
#     append-only pat_email_adr_audit, MAX(id) waechst monoton bei JEDER
#     Aktion (Insert/Update/Delete) - reiner Rollenwechsel (h/n/a) aendert
#     zwar addresses_by_patient()'s Ergebnis nicht inhaltlich, ein
#     unnoetiger Rebuild dabei ist aber nur verschwendete Arbeit, kein
#     Korrektheitsproblem.
def get_watermarks(medoff_conn, quelle_conn):
    mcur = medoff_conn.cursor()
    mcur.execute(
        "SELECT MAX(FSurogat) AS m FROM dbsprot "
        "WHERE FTablename='patstamm' AND FXmlinhalt LIKE '%<Email>%'"
    )
    dbsprot_max = (mcur.fetchone() or {}).get("m") or 0
    qcur = quelle_conn.cursor()
    qcur.execute("SELECT MAX(id) AS m FROM pat_email_adr_audit")
    audit_max = (qcur.fetchone() or {}).get("m") or 0
    return dbsprot_max, audit_max


def poll_once(pwd, by_email, apply_changes, full=False):
    """Ein einzelner Abholzyklus (POP3-Verbindung, neue Nachrichten seit dem
    UIDL-Checkpoint verarbeiten) mit einer BEREITS aufgebauten by_email-
    Zuordnung - weder hier noch in run_daemon() wird patstamm dafuer erneut
    gelesen. Fuer den Einzelaufruf (main(), CLI/Cron-Kompatibilitaet) baut
    der Aufrufer by_email frisch; fuer den Dauerdienst (run_daemon())
    wird sie nur bei tatsaechlicher Aenderung neu aufgebaut.

    full=True (--full, gedacht fuer einen seltenen naechtlichen Cron-Lauf,
    NICHT fuer run_daemon()): Backstop gegen einen fehlerhaft fortgeschriebenen
    UIDL-Checkpoint, der sonst Nachrichten fuer immer unbemerkt uebersehen
    wuerde (Postfach behaelt Mails auf dem Server, siehe leave_on_server) -
    prueft ALLE Nachrichten auf dem Server, unabhaengig vom Checkpoint, und
    schreibt den Checkpoint dabei bewusst NICHT fort (reiner Lesevorgang,
    verlaesst sich auf den bereits vorhandenen Inhalts-Hash-/dok_text_cache-
    Abgleich weiter unten, um keine Duplikate anzulegen)."""
    conn = pop_connect(pwd)
    try:
        resp, lines, octets = conn.uidl()
        pairs = []
        for line in lines:
            parts = line.decode("ascii", "replace").split(" ", 1)
            if len(parts) == 2:
                pairs.append((parts[0], parts[1]))

        last_uidl = load_last_uidl()
        if full:
            to_process = pairs
            print(f"Voll-Scan (Backstop): {len(pairs)} Nachrichten auf Server werden "
                  f"vollstaendig geprueft, UIDL-Checkpoint bleibt unveraendert")
        else:
            start_idx = 0
            if last_uidl:
                for i, (num, uid) in enumerate(pairs):
                    if uid == last_uidl:
                        start_idx = i + 1
                        break
            to_process = pairs[start_idx:]
            print(f"Nachrichten auf Server: {len(pairs)}, neu seit letztem Checkpoint: {len(to_process)}")

        seen_cache = open_seen_cache()
        mail_cache_conn = mail_id_cache.connect()
        dokprot_conn = connect_dokprot() if apply_changes else None
        dokprot_cur = dokprot_conn.cursor() if dokprot_conn else None
        audit = AuditLog(get_run_ts(), apply_changes, "poll_diabetologie_inbox.py", get_run_phase("Wartung"))

        n_relevant = 0
        n_created = 0
        n_duplicate = 0
        n_error = 0
        n_reconnects = 0
        newest_uidl = last_uidl

        n_processed = 0
        for num, uid in to_process:
            n_processed += 1
            if n_processed % 500 == 0:
                print(f"  ... {n_processed}/{len(to_process)} geprueft (nur Header), {n_relevant} bisher relevant")

            # Billiger Vorfilter per POP3 TOP (nur Header, kein voller
            # Abruf): diese Mailbox bedient mehrere Absender-Identitaeten
            # gleichzeitig, dieses Skript ist bewusst nur fuer TARGET_ALIAS
            # zustaendig - ein voller RETR lohnt sich nur fuer den kleinen
            # Bruchteil, der ueberhaupt in Frage kommt (wichtig beim ersten
            # Lauf mit grossem Nachholbedarf).
            try:
                resp, hdr_lines, octets = conn.top(int(num), 0)
            except Exception:
                # Verbindung war vermutlich unterbrochen (SSL-/Protokoll-
                # fehler nach laengerer Sitzung, z.B. bei einem grossen
                # Nachholbedarf) - EINMAL neu verbinden und dieselbe
                # Nachricht erneut versuchen, statt gleich aufzugeben.
                try:
                    conn = pop_connect(pwd)
                    n_reconnects += 1
                    resp, hdr_lines, octets = conn.top(int(num), 0)
                except Exception as e:
                    print(f"FEHLER beim Header-Abruf von Nachricht {num}: {type(e).__name__}")
                    newest_uidl = uid
                    continue
            hdr_raw = b"\n".join(hdr_lines) + b"\n\n"

            from_raw_h = get_header(hdr_raw, "From")
            to_raw_h = get_header(hdr_raw, "To")
            cc_raw_h = get_header(hdr_raw, "Cc")
            _, sender_addr_h = parse_from_header(from_raw_h) if from_raw_h else ("", "")
            recipients_h = parse_addr_list(to_raw_h) + parse_addr_list(cc_raw_h)

            if TARGET_ALIAS not in (recipients_h + [sender_addr_h]) and sender_addr_h != TARGET_ALIAS:
                newest_uidl = uid
                continue

            try:
                resp, msg_lines, octets = conn.retr(int(num))
            except Exception:
                try:
                    conn = pop_connect(pwd)
                    n_reconnects += 1
                    resp, msg_lines, octets = conn.retr(int(num))
                except Exception as e:
                    print(f"FEHLER beim Abholen von Nachricht {num}: {type(e).__name__}")
                    newest_uidl = uid
                    continue
            raw = b"\n".join(msg_lines)

            newest_uidl = uid
            msg_hash = hashlib.sha256(raw).hexdigest()
            if seen_cache.execute("SELECT 1 FROM seen WHERE hash=?", (msg_hash,)).fetchone():
                continue

            try:
                msg = email.message_from_bytes(raw, policy=email.policy.compat32)
            except Exception:
                n_error += 1
                continue

            from_raw = get_header(raw, "From")
            to_raw = get_header(raw, "To")
            cc_raw = get_header(raw, "Cc")
            date_raw = get_header(raw, "Date")
            subject_raw = decode_header_val(get_header(raw, "Subject"))

            _, sender_addr = parse_from_header(from_raw) if from_raw else ("", "")
            recipients = parse_addr_list(to_raw) + parse_addr_list(cc_raw)

            patient = None
            direction = None
            partner_addr = None
            if sender_addr in OWN_ACCOUNT_EMAILS:
                for r in recipients:
                    if r in by_email:
                        patient = by_email[r]
                        direction = "gesan."
                        partner_addr = r
                        break
            elif sender_addr in by_email:
                patient = by_email[sender_addr]
                direction = "angek."
                partner_addr = sender_addr

            if patient is None:
                continue
            n_relevant += 1

            try:
                msg_date = email.utils.parsedate_to_datetime(date_raw) if date_raw else None
            except Exception:
                msg_date = None
            if msg_date is None:
                n_error += 1
                print(f"FEHLER (kein/ungueltiges Datum) bei Patient {patient['FSurogat']}")
                continue

            fpatnr = str(patient["FSurogat"])
            nachname = sanitize((patient["FNachname"] or "").strip())
            vorname = sanitize((patient["FVorname"] or "").strip())
            zeitstempel = msg_date.strftime("%y%m%d %H%M%S")
            betreff_sane = sanitize(subject_raw)[:100]
            richtungswort = "von" if direction == "angek." else "an"
            name_prefix_sane = sanitize(build_name_prefix(patient))
            base_name = (f"{name_prefix_sane} Email {richtungswort} {partner_addr} "
                         f"{zeitstempel}, {betreff_sane}")
            try:
                mtime_ts = msg_date.timestamp()
            except (OverflowError, OSError, ValueError):
                mtime_ts = None

            target_dir = os.path.join(DOK_ROOT, fpatnr)
            existing = {}
            if os.path.isdir(target_dir):
                candidates = []
                for fn in os.listdir(target_dir):
                    if not (fn.lower().endswith(".pdf") and " email " in fn.lower()):
                        continue
                    fp = os.path.join(target_dir, fn)
                    try:
                        st = os.stat(fp)
                    except OSError:
                        continue
                    candidates.append((fp, int(st.st_mtime), st.st_size))
                cached = mail_id_cache.load_dok_text_cache(mail_cache_conn, [c[0] for c in candidates])
                new_dok_rows = []
                for fp, mtime_unix, groesse in candidates:
                    hit = cached.get(fp)
                    if hit is not None and hit[0] == mtime_unix and hit[1] == groesse:
                        txt = hit[2]
                    else:
                        txt = normalize_pdf_text(extract_pdf_text(fp))
                        new_dok_rows.append((fp, mtime_unix, groesse, txt))
                    if txt:
                        existing[fp] = txt
                if new_dok_rows:
                    mail_id_cache.upsert_dok_text_batch(mail_cache_conn, new_dok_rows)

            pdf_bytes = render_message(msg, from_raw, to_raw, date_raw, subject_raw)
            if pdf_bytes is None:
                n_error += 1
                print(f"FEHLER (Rendern fehlgeschlagen) bei Patient {patient['FSurogat']}")
                continue
            candidate_text = normalize_pdf_text(extract_pdf_text(BytesIO(pdf_bytes)))

            if any(candidate_text == t for t in existing.values()):
                n_duplicate += 1
                if apply_changes:
                    mark_seen(seen_cache, msg_hash)
                continue

            gebdat_sql = gebdat_to_sql(patient["FGeburtsdatum"])
            pdf_path = os.path.join(target_dir, cap_filename_length(base_name + ".pdf"))
            try:
                if apply_changes:
                    os.makedirs(target_dir, exist_ok=True)
                    suffix = 2
                    while os.path.exists(pdf_path):
                        pdf_path = os.path.join(target_dir, cap_filename_length(f"{base_name} ({suffix}).pdf"))
                        suffix += 1
                    with open(pdf_path, "wb") as f:
                        f.write(pdf_bytes)
                    if mtime_ts is not None:
                        os.utime(pdf_path, (mtime_ts, mtime_ts))
                    log_dokprot(dokprot_cur, fpatnr, nachname, vorname, gebdat_sql,
                                "", os.path.basename(pdf_path), len(pdf_bytes), "pdf", msg_date,
                                email_adresse=partner_addr)
                audit.log("Email als PDF abgelegt (POP3-Direktabruf)", fpatnr,
                          neu=os.path.basename(pdf_path), pfad=target_dir)
                n_created += 1
            except Exception as e:
                n_error += 1
                print(f"FEHLER bei Email-PDF fuer Patient {fpatnr}: {type(e).__name__}")
                continue

            for att_name, att_data in extract_attachments(msg):
                try:
                    att_name_disp = decode_header_val(att_name)
                    att_name_sane = sanitize(att_name_disp)
                    att_root, att_ext = os.path.splitext(att_name_sane)
                    att_path = os.path.join(target_dir, cap_filename_length(f"{base_name}; {att_name_sane}"))
                    if apply_changes:
                        suffix = 2
                        while os.path.exists(att_path):
                            att_path = os.path.join(target_dir, cap_filename_length(f"{base_name}; {att_root} ({suffix}){att_ext}"))
                            suffix += 1
                        with open(att_path, "wb") as f:
                            f.write(att_data)
                        if mtime_ts is not None:
                            os.utime(att_path, (mtime_ts, mtime_ts))
                        log_dokprot(dokprot_cur, fpatnr, nachname, vorname, gebdat_sql,
                                    att_name_disp, os.path.basename(att_path), len(att_data),
                                    att_ext.lstrip("."), msg_date, email_adresse=partner_addr)
                    audit.log("Anhang abgelegt (POP3-Direktabruf)", fpatnr,
                              neu=os.path.basename(att_path), pfad=target_dir)
                except Exception as e:
                    n_error += 1
                    print(f"FEHLER bei Anhang fuer Patient {fpatnr}: {type(e).__name__}")

            if apply_changes:
                mark_seen(seen_cache, msg_hash)

        if apply_changes and not full and newest_uidl:
            save_last_uidl(newest_uidl)

        if dokprot_conn:
            dokprot_conn.close()
        seen_cache.close()
        mail_cache_conn.close()
        audit.close()

        return {
            "n_abgeholt": len(to_process),
            "n_relevant": n_relevant,
            "n_created": n_created,
            "n_duplicate": n_duplicate,
            "n_error": n_error,
            "n_reconnects": n_reconnects,
            "audit_path": audit.path,
        }
    finally:
        try:
            conn.quit()
        except Exception:
            pass


def print_stats(stats, apply_changes):
    print("=== Ergebnis ===")
    print(f"Abgeholt: {stats['n_abgeholt']}")
    print(f"Relevant (TARGET_ALIAS + bekannter Patient): {stats['n_relevant']}")
    print(f"Erzeugt: {stats['n_created']}")
    print(f"Bereits vorhanden (inhaltlich): {stats['n_duplicate']}")
    print(f"Fehler: {stats['n_error']}")
    print(f"POP3-Wiederverbindungen: {stats['n_reconnects']}")
    print(f"Aenderungsprotokoll: {stats['audit_path']}")
    if not apply_changes:
        print("Trockenlauf beendet. Zum tatsaechlichen Ablegen erneut mit --apply aufrufen.")


def main():
    """Einzelaufruf (CLI/manueller Test, sowie Cron-Kompatibilitaet, falls
    --daemon je zurueckgebaut werden muss) - baut by_email immer frisch,
    genau ein Abholzyklus, druckt das Ergebnis.

    --full: seltener naechtlicher Backstop-Cron-Lauf, siehe poll_once()."""
    apply_changes = "--apply" in sys.argv
    full = "--full" in sys.argv
    pwd = read_pop_password()
    by_email = build_by_email()
    print(f"Patienten mit hinterlegter oder gestagter Email-Adresse: {len(by_email)}")
    stats = poll_once(pwd, by_email, apply_changes, full=full)
    print_stats(stats, apply_changes)


def run_daemon():
    """Dauerdienst (linux1, systemd - siehe poll-diabetologie-inbox.service):
    haelt by_email nur im Arbeitsspeicher, baut sie NUR bei tatsaechlicher
    Aenderung (siehe get_watermarks()) neu auf, sonst wiederverwendet.
    Laeuft immer mit apply_changes=True (kein Dry-Run-Dauerbetrieb - fuer
    Tests weiterhin main() ohne --apply verwenden)."""
    apply_changes = True
    pwd = read_pop_password()

    medoff_conn = connect_medoff()
    padb_conn = padb.connect()
    dbsprot_max, audit_max = get_watermarks(medoff_conn, padb_conn)
    medoff_conn.close()
    padb_conn.close()

    by_email = build_by_email()
    print(f"[Start] Patienten mit hinterlegter oder gestagter Email-Adresse: {len(by_email)}", flush=True)

    while True:
        medoff_conn = connect_medoff()
        padb_conn = padb.connect()
        try:
            neu_dbsprot, neu_audit = get_watermarks(medoff_conn, padb_conn)
        finally:
            medoff_conn.close()
            padb_conn.close()
        if neu_dbsprot != dbsprot_max or neu_audit != audit_max:
            by_email = build_by_email()
            dbsprot_max, audit_max = neu_dbsprot, neu_audit
            print(f"[Neuaufbau] Aenderung erkannt (dbsprot={dbsprot_max}, audit={audit_max}), "
                  f"Patienten mit hinterlegter oder gestagter Email-Adresse: {len(by_email)}", flush=True)

        try:
            stats = poll_once(pwd, by_email, apply_changes)
        except Exception as e:
            print(f"FEHLER im Abholzyklus: {type(e).__name__}", flush=True)
            time.sleep(POLL_INTERVAL_SECONDS)
            continue

        if stats["n_relevant"] or stats["n_error"]:
            print_stats(stats, apply_changes)

        time.sleep(POLL_INTERVAL_SECONDS)


if __name__ == "__main__":
    if "--daemon" in sys.argv:
        run_daemon()
    else:
        main()
