# -*- coding: utf-8 -*-
# Archiviert Patientenmails (M-Net Posteingang+Archiv, Lokale Ordner/Praxis/
# Patientenmails) als PDF nach P:\dok\<fpatnr>\, benannt nach
# "<Nachname> <Vorname> (angek./gesan.) Email <yymmdd> <hhmmss>, <Betreff>.pdf".
# Anhaenge werden im Originalformat mit demselben Basisnamen + "; " +
# Original-Anhangsname gespeichert. Der Aenderungszeitpunkt (mtime) von Email-
# PDF und Anhaengen wird auf das im Dateinamen enthaltene Mail-Datum gesetzt.
#
# Patienten-Zuordnung: ueber die in Medical Office hinterlegte FEmail-Adresse
# (Absender bei "angek.", Empfaenger bei "gesan."). Mails ohne zuordenbaren
# Patienten werden uebersprungen (nicht geraten).
#
# Dedup gegen bereits Vorhandenes: der Text der zu erzeugenden PDF wird mit
# dem Text bereits vorhandener "* Email *.pdf"-Dateien im Zielordner
# verglichen (nicht nur der Dateiname) - nur bei Uebereinstimmung wird
# uebersprungen.
#
# Ohne --apply: reiner Trockenlauf (nur Zaehlung, keine Dateien werden
# angelegt) - PDF-Rendering und Textvergleich laufen aber schon mit, damit
# die Zahlen realistisch sind.
import re, os, sys, email, email.header, email.policy, email.utils, html, hashlib, time
import collections
import logging, contextlib
import multiprocessing as mp
import pymysql

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import patient_addresses_db as padb

CACHE_BUILD_BUDGET_SECONDS = 60
MAX_CACHE_FILE_BYTES = 30 * 1024 * 1024

sys.stdout.reconfigure(line_buffering=True)
from io import BytesIO, StringIO


@contextlib.contextmanager
def silence():
    """Unterdrueckt Logging UND stdout/stderr innerhalb des with-Blocks.
    Noetig, weil PDF-Rendering/-Textextraktions-Bibliotheken bei nicht
    unterstuetzten Konstrukten Warnungen mit Ausschnitten des geparsten
    Inhalts ausgeben koennen - das darf niemals in eine Werkzeug-Ausgabe
    gelangen, da der Inhalt Patientendaten enthalten kann."""
    sink = StringIO()
    previous_level = logging.root.manager.disable
    logging.disable(logging.CRITICAL)
    try:
        with contextlib.redirect_stdout(sink), contextlib.redirect_stderr(sink):
            yield
    finally:
        logging.disable(previous_level)

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from find_missing_patient_emails import (
    OWN_ACCOUNT_EMAILS, decode_header_val, parse_from_header, iter_full_messages,
    iter_headers, dob_in_text, phone_tails_of_patient, phone_tails_in_text,
    normalize_text, normalize_word, PHONE_FIELDS,
)
from audit_log import AuditLog, get_run_ts, get_run_phase
import mail_id_cache
# secure_pwd (Windows-DPAPI/win32crypt) bewusst NICHT hier auf Modul-Ebene
# importiert, sondern lokal in main() (siehe dort) - poll_diabetologie_inbox.py
# importiert einzelne Namen aus dieser Datei, ohne main() je aufzurufen, und
# soll auf Linux lauffaehig bleiben koennen (siehe [[project-missing-patient-emails]]).

# Passwort DPAPI-verschluesselt (siehe secure_pwd.py) - nur unter diesem
# Windows-Konto auf diesem PC entschluesselbar. Neu erstellen bei
# Passwort-/PC-/Kontowechsel: Datei mit neuem Klartext-Passwort
# ueberschreiben, dann "python migrate_pwd_to_dpapi.py" ausfuehren.
PWD_FILE = r"C:\Mail\Thunderbird\Profiles\medoff.pwd"
MNET_ROOT = r"C:\Mail\Thunderbird\Profiles\Schade\Mail\pop.mnet-online.de"
LOCAL_ROOT = r"C:\Mail\Thunderbird\Profiles\Schade\Mail\Local Folders"
# Windows-Pfad (Samba-Freigabe von linux1) als Default; ueberschreibbar fuer
# einen kuenftigen Linux-Einsatz von poll_diabetologie_inbox.py, wo dies ein
# lokaler Pfad waere statt eines gemappten Laufwerks - siehe
# [[project-missing-patient-emails]].
DOK_ROOT = os.environ.get("DOK_ROOT", r"P:\dok")

# Dokumenten-Import-Protokoll (dokprotlist/dokprotinh/dokprotvz), dieselbe
# Datenbank die auch DokimpKurz.au3 (v:\autoit) und die VB6-Programme
# (Dateilese.exe etc.) verwenden. Das Passwort rotiert und wird deshalb bei
# jedem Lauf frisch aus der zentralen Freigabe gelesen, nie lokal gespeichert
# (auf Wunsch des Nutzers - ein Passwort, eine Quelle, fuer alle Programme).
# connect_dokprot()/read_dokprot_password() leben in patient_addresses_db.py
# (dort auch fuer pat_email_adr genutzt) - hier nur re-exportiert, damit
# archive_institutional_emails.py sie unveraendert von hier importieren kann.
from patient_addresses_db import (
    DOKPROT_HOST, DOKPROT_PORT, DOKPROT_USER, DOKPROT_DB, DOKPROT_PWD_SHARE,
    read_dokprot_password, connect_dokprot,
)
DOKPROT_MITARBEITER = "AUTO"  # Kuerzel fuer automatisiert (per Skript) erzeugte Eintraege


def _mb3_safe(s):
    """Entfernt Zeichen ausserhalb der Basic Multilingual Plane (z.B. Emoji).
    Die quelle-DB (dokprotlist) ist mit utf8mb3 kollationiert (max. 3 Byte je
    Zeichen) - 4-Byte-Unicode-Zeichen in Datei-/Anhangsnamen wuerden sonst
    einen DataError (1366, 'Incorrect string value') auslösen."""
    return "".join(c for c in (s or "") if ord(c) <= 0xFFFF)


def build_name_prefix(patient):
    """Nachname [Titel ][Vorsatzwort ][Zusatzwort ]Vorname - fuer Dateinamen/
    Patientenname, ersetzt die frueheren "(angek.)"/"(gesan.)"-Markierungen
    (seit der EmailAdresse-Migration 2026-09-12, siehe
    migrate_dokprotlist_email_adresse.py und [[project-missing-patient-emails]]:
    die tatsaechliche Email-Adresse im Namen macht die Herkunft eindeutiger,
    als es die reine Richtungsangabe je konnte)."""
    parts = [(patient.get("FNachname") or "").strip()]
    for key in ("FTitel", "FNamensvorsatz", "FNamenszusatz"):
        v = (patient.get(key) or "").strip()
        if v:
            parts.append(v)
    parts.append((patient.get("FVorname") or "").strip())
    return " ".join(x for x in parts if x)


def log_dokprot(cur, fpatnr, nachname, vorname, gebdat_sql, ursp_name, dat_name,
                 groesse, typ, laend_dt, email_adresse=None):
    """Traegt eine erzeugte Datei (Email-PDF oder Anhang) in dokprotlist ein,
    analog zum Vorgehen in DokimpKurz.au3 (Archivierungsmodus, kopart=0 - kein
    Sicherheits-/Zielverzeichnis, da die Datei direkt in P:\\dok landet).

    email_adresse: Absenderadresse (empfangene Email) bzw. Empfaengeradresse
    (gesandte Email) - seit der EmailAdresse-Migration 2026-09-12, None fuer
    alle anderen (nicht email-bezogenen) Aufrufer."""
    pc = os.environ.get("COMPUTERNAME", "")[:10]
    benutzer = os.environ.get("USERNAME", "")[:10]
    patientenname = _mb3_safe(f"{nachname}, {vorname}")[:50]
    ursp_name = _mb3_safe(ursp_name)[:200]
    dat_name = _mb3_safe(dat_name)[:360]
    cur.execute(
        "INSERT INTO dokprotlist "
        "(kPatN, ntum, nImp, urspnm, Patientenname, Gebdat, Ort, Pat_ID, "
        " urspName, datName, EmailAdresse, lAend, groesse, Typ, Mitarbeiter, PC, Benutzer, eingetragen) "
        "VALUES (0, 0, 1, 0, %s, %s, '', %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW())",
        (patientenname, gebdat_sql, fpatnr, ursp_name, dat_name, email_adresse,
         laend_dt, groesse, typ[:7], DOKPROT_MITARBEITER, pc, benutzer),
    )

SEEN_CACHE_PATH = os.environ.get(
    "SEEN_CACHE_PATH", r"C:\Mail\Thunderbird\Profiles\archive_seen_cache.sqlite")


def open_seen_cache():
    """Persistenter Cache (Hash der Rohnachricht -> bereits archiviert), damit
    wiederholte Laeufe bereits erledigte Nachrichten sofort ueberspringen
    koennen, statt sie erneut zu rendern/vergleichen."""
    import sqlite3
    conn = sqlite3.connect(SEEN_CACHE_PATH)
    conn.execute("CREATE TABLE IF NOT EXISTS seen (hash TEXT PRIMARY KEY, eingetragen TEXT)")
    conn.commit()
    return conn


def mark_seen(conn, msg_hash):
    conn.execute("INSERT OR IGNORE INTO seen (hash, eingetragen) VALUES (?, datetime('now'))", (msg_hash,))
    conn.commit()


SOURCES = [
    (f"{MNET_ROOT}\\Inbox", None),
    (f"{MNET_ROOT}\\Archiv", None),
    (f"{LOCAL_ROOT}\\Praxis.sbd\\Patientenmails", None),
]

INVALID_FS_CHARS = re.compile(r'[\\/:*?"<>|\x00-\x1f\x7f]')


def sanitize(name):
    name = INVALID_FS_CHARS.sub("_", name or "")
    name = re.sub(r"\s+", " ", name)  # eingebettete Zeilenumbrueche/mehrfache Leerzeichen normalisieren
    return name.strip().rstrip(".")


MAX_FILENAME_LEN = 230  # Sicherheitsmarge unter Windows' MAX_PATH (260 Zeichen inkl. "P:\dok\<fpatnr>\")


def cap_filename_length(fn, max_len=MAX_FILENAME_LEN):
    """Kuerzt einen Dateinamen auf max_len Zeichen (Endung bleibt erhalten),
    damit weder das Windows-Pfadlimit noch die 360-Zeichen-Spalte
    dokprotlist.datName ueberschritten wird."""
    if len(fn) <= max_len:
        return fn
    root, ext = os.path.splitext(fn)
    return root[:max_len - len(ext)].rstrip() + ext


def parse_addr_list(raw):
    if not raw:
        return []
    raw = decode_header_val(raw)
    return [a.strip().lower() for a in re.findall(r"[^\s,<>]+@[^\s,<>]+", raw)]


def get_header(raw, name):
    header_end = raw.find(b"\n\n")
    scope = raw[:header_end] if header_end != -1 else raw
    padded = b"\n" + scope
    pat = re.compile(rb"\n" + re.escape(name.encode("ascii")) + rb":", re.IGNORECASE)
    m = pat.search(padded)
    if not m:
        return ""
    start = m.end()
    end = padded.find(b"\n", start)
    while end != -1 and end + 1 < len(padded) and padded[end + 1:end + 2] in (b" ", b"\t"):
        end = padded.find(b"\n", end + 1)
    val = padded[start:end if end != -1 else None]
    return val.strip().decode("utf-8", "replace")


def extract_body_html(msg):
    html_part, text_part = None, None
    if msg.is_multipart():
        for part in msg.walk():
            if part.get_filename():
                continue
            ctype = part.get_content_type()
            if ctype == "text/html" and html_part is None:
                payload = part.get_payload(decode=True)
                if payload:
                    charset = part.get_content_charset() or "utf-8"
                    html_part = payload.decode(charset, "replace")
            elif ctype == "text/plain" and text_part is None:
                payload = part.get_payload(decode=True)
                if payload:
                    charset = part.get_content_charset() or "utf-8"
                    text_part = payload.decode(charset, "replace")
    else:
        payload = msg.get_payload(decode=True)
        if payload:
            charset = msg.get_content_charset() or "utf-8"
            text = payload.decode(charset, "replace")
            if msg.get_content_type() == "text/html":
                html_part = text
            else:
                text_part = text
    if html_part:
        return html_part
    if text_part:
        return "<pre>" + html.escape(text_part) + "</pre>"
    return "<i>(kein Textinhalt)</i>"


def extract_attachments(msg):
    atts = []
    if msg.is_multipart():
        for part in msg.walk():
            fn = part.get_filename()
            if fn:
                payload = part.get_payload(decode=True)
                if payload:
                    atts.append((decode_header_val(fn), payload))
    return atts


def build_pdf_html(von, an, datum_str, betreff, body_html):
    return f"""<html><body style="font-family: Helvetica, Arial, sans-serif; font-size: 10pt;">
<p><b>Von:</b> {html.escape(von)}<br/>
<b>An:</b> {html.escape(an)}<br/>
<b>Datum:</b> {html.escape(datum_str)}<br/>
<b>Betreff:</b> {html.escape(betreff)}</p>
<hr/>
{body_html}
</body></html>"""


def render_pdf(html_content):
    from xhtml2pdf import pisa
    buf = BytesIO()
    try:
        with silence():
            result = pisa.CreatePDF(html_content, dest=buf, encoding="utf-8")
    except Exception:
        # xhtml2pdf/reportlab koennen bei ungewoehnlichem HTML (z.B. komplexe
        # verschachtelte Tabellen aus Outlook-generierten Mails) intern
        # abstuerzen - dann diese eine Mail als Fehler zaehlen statt den
        # gesamten Lauf abzubrechen.
        return None
    if result.err:
        return None
    return buf.getvalue()


RENDER_TIMEOUT_SECONDS = 30
_render_pool = None


def _get_render_pool():
    global _render_pool
    if _render_pool is None:
        ctx = mp.get_context("spawn")
        _render_pool = ctx.Pool(processes=1)
    return _render_pool


def _restart_render_pool():
    global _render_pool
    if _render_pool is not None:
        try:
            _render_pool.terminate()
            _render_pool.join()
        except Exception:
            pass
    _render_pool = None


def render_pdf_safe(html_content):
    """Wie render_pdf(), aber mit Zeitlimit: manche Mails (z.B. mit sehr
    grossen/verschachtelten Outlook-Tabellen) lassen reportlab intern extrem
    lange rechnen, ohne einen Fehler zu werfen - das darf den gesamten Lauf
    nicht blockieren. Rendert in einem separaten Worker-Prozess; wird das
    Zeitlimit ueberschritten, wird der Worker abgebrochen und neu gestartet."""
    pool = _get_render_pool()
    try:
        async_result = pool.apply_async(render_pdf, (html_content,))
        return async_result.get(timeout=RENDER_TIMEOUT_SECONDS)
    except mp.TimeoutError:
        _restart_render_pool()
        return None
    except Exception:
        _restart_render_pool()
        return None


def extract_pdf_text(path):
    import pdfplumber
    try:
        with silence():
            with pdfplumber.open(path) as pdf:
                return "\n".join((p.extract_text() or "") for p in pdf.pages)
    except Exception:
        return None


def normalize_pdf_text(text):
    return re.sub(r"\s+", " ", (text or "")).strip().lower()


def render_message(msg, from_raw, to_raw, date_raw, subject_raw):
    body_html = extract_body_html(msg)
    von_disp = decode_header_val(from_raw)
    an_disp = decode_header_val(to_raw)
    pdf_html = build_pdf_html(von_disp, an_disp, date_raw, subject_raw, body_html)
    return render_pdf_safe(pdf_html)


def gebdat_to_sql(yyyymmdd):
    yyyymmdd = (yyyymmdd or "").strip()
    if len(yyyymmdd) == 8 and yyyymmdd.isdigit():
        return f"{yyyymmdd[0:4]}-{yyyymmdd[4:6]}-{yyyymmdd[6:8]}"
    return None


PATSTAMM_SELECT_FIELDS = (
    "FSurogat, FVorname, FNachname, FTitel, FNamensvorsatz, FNamenszusatz, "
    "FEmail, FGeburtsdatum, " + ", ".join(PHONE_FIELDS)
)


def build_by_email():
    """Adresse (klein geschrieben) -> Liste der Patienten, die diese Adresse
    fuehren (patstamm.FEmail ODER in patient_addresses_db.py gestagt - siehe
    unten). WICHTIG: eine Liste, NICHT ein einzelner Patient - dieselbe
    Adresse kann inzwischen (z.B. Ehepaar, oder eine ueber Abschnitt 3 der
    Vorschlagsliste bestaetigte gemeinsame Adresse) zu MEHREREN Patienten
    gehoeren. Ein frueherer Bug hier (by_email als 1:1-Zuordnung, per
    setdefault() nur der erste gewinnt) haette bei so einer Adresse
    stillschweigend alle bis auf einen Patienten von neuer Archivierung
    ausgeschlossen - siehe resolve_ambiguous_patients() fuer die
    Entscheidung, bei WEM konkret eine mehrdeutige Adresse einsortiert wird."""
    import secure_pwd
    password = secure_pwd.read_protected_password(PWD_FILE)
    try:
        conn = pymysql.connect(host="wser", port=2020, user="medoff", password=password,
                                database="medoff", connect_timeout=10,
                                cursorclass=pymysql.cursors.DictCursor)
    except Exception as e:
        print(f"FEHLER: medoff-Datenbank (wser) nicht erreichbar: {e}")
        sys.exit(3)
    cur = conn.cursor()
    cur.execute(f"SELECT {PATSTAMM_SELECT_FIELDS} FROM patstamm "
                f"WHERE FEmail IS NOT NULL AND FEmail <> ''")
    patients = cur.fetchall()

    by_email = {}
    seen_pairs = set()  # (addr, FSurogat) - Dubletten vermeiden (FEmail + gestaged identisch)
    for p in patients:
        addr = (p["FEmail"] or "").strip().lower()
        if addr:
            by_email.setdefault(addr, []).append(p)
            seen_pairs.add((addr, p["FSurogat"]))

    # Zusaetzlich alle in patient_addresses_db.py "gestagten" Adressen
    # beruecksichtigen - auch fuer Patienten, deren medoff-Eintrag (noch)
    # nicht geschrieben wurde (siehe [[project-missing-patient-emails]],
    # zweiphasiger Ablauf von apply_patient_emails.py). So kann archiviert
    # werden, BEVOR medoff veraendert ist, und es werden auch aeltere
    # gefundene Adressen erfasst, die nie in FEmail landen.
    padb_conn = padb.connect()
    staged = padb.addresses_by_patient(padb_conn)
    padb_conn.close()
    if staged:
        placeholders = ",".join(["%s"] * len(staged))
        cur.execute(f"SELECT {PATSTAMM_SELECT_FIELDS} FROM patstamm "
                    f"WHERE FSurogat IN ({placeholders})", tuple(staged.keys()))
        staged_patients = {str(p["FSurogat"]): p for p in cur.fetchall()}
        for patientennummer, addrs in staged.items():
            info = staged_patients.get(patientennummer)
            if info is None:
                continue
            for addr in addrs:
                addr_l = addr.strip().lower()
                key = (addr_l, info["FSurogat"])
                if key in seen_pairs:
                    continue
                seen_pairs.add(key)
                by_email.setdefault(addr_l, []).append(info)

    conn.close()
    return by_email


def _match_candidates_in_text(candidates, text):
    """Prueft fuer jeden Kandidaten (patstamm-Zeile), ob Name, Geburtsdatum
    oder Telefonnummer im (bereits normalize_text()-normalisierten) Text
    vorkommen. Liefert die Teilmenge von candidates mit mindestens einem
    Treffer.

    WICHTIG (dieselbe Regel wie in find_missing_patient_emails.py, Stichwort
    nachname_ist_eindeutig): der Nachname zaehlt nur als Signal, wenn er
    innerhalb DIESER Kandidatengruppe eindeutig ist - bei einer gemeinsamen
    Adresse tragen Ehepaare/Familien fast immer denselben Nachnamen, so dass
    ein Nachname-Treffer sonst praktisch JEDES Familienmitglied faelschlich
    "bestaetigen" wuerde, statt zu unterscheiden. Ist der Nachname geteilt,
    zaehlen nur noch Vorname, Geburtsdatum oder Telefonnummer."""
    nachnamen = collections.Counter(
        normalize_word((c["FNachname"] or "").strip()) for c in candidates
    )
    hits = []
    for c in candidates:
        nachname = normalize_word((c["FNachname"] or "").strip())
        vorname = normalize_word((c["FVorname"] or "").strip())
        nachname_eindeutig = nachname and nachnamen[nachname] == 1
        name_ok = (nachname_eindeutig and len(nachname) >= 3 and
                   re.search(r"\b" + re.escape(nachname) + r"\b", text)) or \
                  (len(vorname) >= 3 and re.search(r"\b" + re.escape(vorname) + r"\b", text))
        dob_ok = dob_in_text((c["FGeburtsdatum"] or "").strip(), text)
        phone_ok = bool(phone_tails_of_patient(c) & phone_tails_in_text(text))
        if name_ok or dob_ok or phone_ok:
            hits.append(c)
    return hits


def _staff_filed_hash_match(candidates, attachment_digest):
    """Prueft, ob der Anhang (per Inhalts-Hash) bereits OHNE das automatische
    'Email'-Namensmuster im P:\\dok-Ordner GENAU EINES Kandidaten liegt - ein
    starkes Indiz, dass eine Mitarbeiterin/ein Mitarbeiter die Datei bereits
    von Hand dem richtigen Patienten zugeordnet hat. Nur die Ordner der
    uebergebenen (wenigen) Kandidaten werden durchsucht, nicht ganz P:\\dok."""
    if not attachment_digest:
        return []
    hits = []
    for c in candidates:
        pat_dir = os.path.join(DOK_ROOT, str(c["FSurogat"]))
        if not os.path.isdir(pat_dir):
            continue
        try:
            filenames = os.listdir(pat_dir)
        except OSError:
            continue
        for fn in filenames:
            if " email " in fn.lower():
                continue
            fp = os.path.join(pat_dir, fn)
            if not os.path.isfile(fp):
                continue
            try:
                with open(fp, "rb") as f:
                    digest = hashlib.sha256(f.read()).hexdigest()
            except OSError:
                continue
            if digest == attachment_digest:
                hits.append(c)
                break
    return hits


def _ocr_pdf_bytes(pdf_bytes):
    """Letzter Schritt der Kaskade in resolve_ambiguous_patients() (teuer,
    daher nur wenn alle vorherigen Stufen nichts ergeben haben): rastert die
    ersten Seiten und laesst Tesseract den Text erkennen. Liefert "", wenn
    Tesseract/die noetigen Bibliotheken hier nicht verfuegbar sind oder OCR
    fehlschlaegt - der Aufrufer faellt dann auf den sicheren "bei allen
    Kandidaten archivieren"-Standard zurueck. TESSERACT_CMD/TESSDATA_DIR
    per Umgebungsvariable ueberschreibbar (fuer die Linux-Portierung)."""
    try:
        import fitz
        import pytesseract
        from PIL import Image
    except ImportError:
        return ""
    tesseract_cmd = os.environ.get("TESSERACT_CMD", r"C:\Program Files\Tesseract-OCR\tesseract.exe")
    tessdata_dir = os.environ.get("TESSDATA_DIR", r"C:\Mail\Thunderbird\Profiles\Scripts\tessdata_custom")
    if not os.path.isfile(tesseract_cmd):
        return ""
    try:
        pytesseract.pytesseract.tesseract_cmd = tesseract_cmd
        Image.MAX_IMAGE_PIXELS = None
        doc = fitz.open(stream=pdf_bytes, filetype="pdf")
        parts = []
        for i, page in enumerate(doc):
            if i >= 3:
                break
            pix = page.get_pixmap(dpi=300)
            img = Image.open(BytesIO(pix.tobytes("png")))
            parts.append(pytesseract.image_to_string(img, lang="deu",
                                                       config=f"--tessdata-dir {tessdata_dir}"))
        doc.close()
        return "\n".join(parts)
    except Exception:
        return ""


RENDERED_HEADER_RE = re.compile(r"betreff\s*:.*?(\n|$)", re.IGNORECASE)


def strip_rendered_header(text):
    """Die von build_pdf_html() erzeugten Basis-PDFs beginnen mit Von:/An:/
    Datum:/Betreff:-Kopfzeilen - der Anzeigename der Mailbox (Von:/An:) darf
    NICHT als Inhaltssignal gewertet werden, da er bei JEDER Nachricht von
    dieser Adresse identisch ist, unabhaengig davon, wen die konkrete
    Nachricht betrifft (z.B. "Max & Erika Mustermann" bei einer Ehepaar-
    Adresse wuerde sonst beide Vornamen faelschlich in jeder Nachricht
    bestaetigen). Schneidet daher alles bis einschliesslich der ersten
    'Betreff:'-Zeile ab."""
    m = RENDERED_HEADER_RE.search(text or "")
    return text[m.end():] if m else (text or "")


def _match_via_other_messages(candidates, addr):
    """Letzte Kaskadenstufe, NUR wenn diese eine Nachricht selbst (Stufen 1-4)
    keinerlei Beleg liefert: prueft ANDERE, bereits archivierte Nachrichten
    DERSELBEN Absenderadresse (ueber dokprotlist.EmailAdresse) auf denselben
    Name/Geburtsdatum/Telefon-Beleg. Bewusst nur als letzter Ausweg (nicht
    routinemaessig) - Nutzer-Entscheidung 2026-09-14: ein woanders in der
    Korrespondenz dieser Adresse gefundener Bezug ist ein schwaches, aber
    besseres Signal als der blinde 'bei allen archivieren'-Standard."""
    if not addr:
        return []
    try:
        conn = padb.connect()
        cur = conn.cursor()
        cur.execute("SELECT Pat_ID, datName FROM dokprotlist WHERE EmailAdresse=%s "
                    "AND datName NOT LIKE '%%; %%'", (addr,))
        rows = cur.fetchall()
        conn.close()
    except Exception:
        return []
    hit_ids = set()
    for row in rows:
        fpath = os.path.join(DOK_ROOT, str(row["Pat_ID"]), row["datName"])
        if not os.path.isfile(fpath):
            continue
        text = strip_rendered_header(extract_pdf_text(fpath))
        if not text.strip():
            continue
        hits = _match_candidates_in_text(candidates, normalize_text(text))
        hit_ids.update(str(c["FSurogat"]) for c in hits)
    return [c for c in candidates if str(c["FSurogat"]) in hit_ids]


GREETING_WINDOW = 150


def _html_to_text(html_content):
    """Grobe HTML->Text-Umwandlung, nur fuer den Gruss-Fensterausschnitt
    (Kriterium 4) - muss nicht perfekt sein, nur Tags/Entities weit genug
    entfernen, dass ein Wort am Ende des sichtbaren Textes nicht durch
    Markup verdeckt wird."""
    if not html_content:
        return ""
    text = re.sub(r"<(script|style)[^>]*>.*?</\1>", " ", html_content, flags=re.IGNORECASE | re.DOTALL)
    text = re.sub(r"<[^>]+>", " ", text)
    text = html.unescape(text)
    return text


def _match_via_greeting(candidates, body_html, direction):
    """Kriterium 4 (Nutzer-Vorschlag 2026-09-14): bei EMPFANGENEN Mails
    (direction == 'angek.') steht der Absender-Vorname haeufig - ggf. auf
    den Anfangsbuchstaben abgekuerzt ('Gruesse, P.' oder auch nur 'P.' ganz
    ohne Grussformel) - in den letzten Zeilen. Nur der volle Vorname zaehlt
    hier als eigenstaendig ausreichender Beleg; ein blosser Anfangsbuchstabe
    ist zu schwach fuer eine alleinige automatische Zuordnung und wird NICHT
    zurueckgegeben, wenn mehrere Kandidaten denselben Anfangsbuchstaben
    teilen (sonst kein Gewinn gegenueber dem bisherigen Zustand).
    Fuer GESENDETE Mails ('gesan.') wurde die spiegelbildliche Idee
    (Anrede am Anfang) empirisch gegen echte Daten getestet und verworfen -
    bei einer Ehepaar-/Familienadresse lautet die Anrede praktisch immer
    'Liebe Familie <gemeinsamer Nachname>' und liefert daher keinen
    zusaetzlichen, echten Unterscheidungswert (getestet 2026-09-14)."""
    if direction != "angek." or not body_html:
        return []
    fenster = normalize_text(_html_to_text(body_html))[-GREETING_WINDOW:]
    hits_voll = []
    letter_to_candidates = {}
    for c in candidates:
        vor = normalize_word((c["FVorname"] or "").strip())
        if not vor:
            continue
        if len(vor) >= 3 and re.search(r"\b" + re.escape(vor) + r"\b", fenster):
            hits_voll.append(c)
        letter_to_candidates.setdefault(vor[0], []).append(c)
    if hits_voll:
        return hits_voll
    hits_buchstabe = []
    for letter, cs in letter_to_candidates.items():
        if len(cs) != 1:
            continue  # Anfangsbuchstabe nicht eindeutig unter den Kandidaten
        if re.search(r"\b" + re.escape(letter) + r"\.?\b", fenster):
            hits_buchstabe.extend(cs)
    return hits_buchstabe


def resolve_ambiguous_patients(candidates, subject_raw, body_html, attachment_name, attachment_bytes, addr=None,
                                direction=None):
    """Bei einer Adresse, die zu MEHREREN Patienten gehoert (siehe
    pat_email_adr): versucht anhand des Inhalts DIESER Nachricht
    herauszufinden, wen sie tatsaechlich betrifft. Kaskade, jede Stufe nur
    wenn die vorherige(n) noch nichts ergeben haben:
      1. Name/Geburtsdatum/Telefonnummer in Betreff+Body+Anhangname.
      2. Anhang-Inhalts-Hash bereits (ohne 'Email'-Namensmuster, also von
         Hand durch Mitarbeiter) in genau eines Kandidaten P:\\dok-Ordner.
      3. Nativer Text aus dem Anhang (PDF) - dieselbe Name/Geburtsdatum/
         Telefon-Pruefung.
      4. OCR des Anhangs (nur wenn 1-3 nichts ergeben haben).
      5. Bei EMPFANGENEN Mails: Absender-Vorname (ggf. nur Anfangsbuchstabe,
         wenn dieser unter den Kandidaten eindeutig ist) in den letzten
         Zeilen des Textes (Gruss/Signatur) - siehe _match_via_greeting().
      6. ANDERE bereits archivierte Nachrichten derselben Absenderadresse
         (nur als letzter Ausweg, siehe _match_via_other_messages()).
    Gibt die Teilmenge von 'candidates' zurueck, fuer die ein Beleg gefunden
    wurde - leere Liste, wenn keine Stufe irgendeinen Kandidaten
    unterscheiden konnte (der Aufrufer archiviert dann sicherheitshalber bei
    ALLEN Kandidaten - fehlende Dokumentation waere das groessere Risiko als
    eine zusaetzliche Kopie, siehe [[project-email-archiving-feature]])."""
    combined = normalize_text(f"{subject_raw} {body_html or ''} {attachment_name or ''}")
    hits = _match_candidates_in_text(candidates, combined)
    if hits:
        return hits

    if attachment_bytes:
        attachment_digest = hashlib.sha256(attachment_bytes).hexdigest()
        hits = _staff_filed_hash_match(candidates, attachment_digest)
        if len(hits) == 1:
            return hits

        native_text = normalize_pdf_text(extract_pdf_text(BytesIO(attachment_bytes)))
        if native_text:
            hits = _match_candidates_in_text(candidates, normalize_text(f"{combined} {native_text}"))
            if hits:
                return hits

        ocr_text = _ocr_pdf_bytes(attachment_bytes)
        if ocr_text:
            hits = _match_candidates_in_text(candidates, normalize_text(f"{combined} {ocr_text}"))
            if hits:
                return hits

    hits = _match_via_greeting(candidates, body_html, direction)
    if hits:
        return hits

    hits = _match_via_other_messages(candidates, addr)
    if hits:
        return hits

    return []


def main():
    apply_changes = "--apply" in sys.argv
    by_email = build_by_email()

    dokprot_conn = None
    dokprot_cur = None
    if apply_changes:
        try:
            dokprot_conn = connect_dokprot()
        except Exception as e:
            print(f"FEHLER: quelle-Datenbank (linux1) nicht erreichbar: {e}")
            sys.exit(4)
        dokprot_cur = dokprot_conn.cursor()
    audit = AuditLog(get_run_ts(), apply_changes, "archive_patient_emails.py", get_run_phase("D"))

    print(f"Patienten mit hinterlegter oder gestagter Email-Adresse: {len(by_email)}")

    n_total = 0
    n_no_patient = 0
    n_duplicate = 0
    n_created = 0
    n_error = 0
    n_cached_skip = 0
    n_ambiguous_resolved = 0
    n_ambiguous_fallback_all = 0
    existing_text_cache = {}  # dok-Ordner -> {pfad: normalisierter_text}
    seen_cache = open_seen_cache()

    # Persistenter Message-ID -> (Absender, Empfaenger)-Cache (emails.
    # mail_adressen_cache auf linux1, siehe mail_id_cache.py) - vermeidet,
    # dass bei jedem Lauf fuer JEDE der oft zehntausenden Nachrichten ohne
    # Patientenbezug erneut voll gelesen/gehasht/dekodiert werden muss.
    mail_cache_conn = mail_id_cache.connect()
    mail_cache = mail_id_cache.load_all(mail_cache_conn)
    print(f"Bekannte Message-ID-Adressen (Cache): {len(mail_cache)}")

    # Persistenter Render-Text-Cache (emails.mail_render_cache) - der
    # extrahierte Text einer bereits gerenderten Nachricht aendert sich nie,
    # daher unbegrenzt wiederverwendbar (auch ueber Trockenlauf/Echtlauf
    # hinweg). Erspart erneutes PDF-Rendern fuer Nachrichten, die sich als
    # bereits vorhanden herausstellen.
    render_cache = mail_id_cache.load_render_cache(mail_cache_conn)
    print(f"Bekannte gerenderte Nachrichten (Cache): {len(render_cache)}")
    new_render_rows = []
    new_dok_text_rows = []

    def flush_caches():
        if new_render_rows:
            mail_id_cache.insert_render_batch(mail_cache_conn, new_render_rows)
            new_render_rows.clear()
        if new_dok_text_rows:
            mail_id_cache.upsert_dok_text_batch(mail_cache_conn, new_dok_text_rows)
            new_dok_text_rows.clear()

    for src_path, _ in SOURCES:
        print(f"--- Quelle: {src_path} ---")

        # Pass 1 (billig, nur Header): Absender/Empfaenger aus dem Cache
        # oder frisch aus den Headern ermitteln, gegen den AKTUELLEN
        # Patientenstand pruefen (nie ein gecachtes Ergebnis, nur die
        # gecachte Adresse!) und die moeglichen Treffer fuer Pass 2 sammeln.
        wanted_message_ids = set()
        new_cache_rows = []
        n_src1 = 0
        for headers in iter_headers(src_path):
            n_src1 += 1
            message_id = headers.get(b"message-id", b"").decode("utf-8", "replace").strip()

            if message_id and message_id in mail_cache:
                sender_addr, recipients = mail_cache[message_id]
            else:
                from_raw_h = headers.get(b"from", b"").decode("utf-8", "replace")
                to_raw_h = headers.get(b"to", b"").decode("utf-8", "replace")
                cc_raw_h = headers.get(b"cc", b"").decode("utf-8", "replace")
                _, sender_addr = parse_from_header(from_raw_h) if from_raw_h else ("", "")
                recipients = parse_addr_list(to_raw_h) + parse_addr_list(cc_raw_h)
                if message_id:
                    new_cache_rows.append((message_id, sender_addr, recipients, os.path.basename(src_path)))
                    mail_cache[message_id] = (sender_addr, recipients)

            is_match = False
            if sender_addr in OWN_ACCOUNT_EMAILS:
                if any(r in by_email for r in recipients):
                    is_match = True
            elif sender_addr in by_email:
                is_match = True

            if is_match and message_id:
                wanted_message_ids.add(message_id)

        if new_cache_rows:
            mail_id_cache.insert_batch(mail_cache_conn, new_cache_rows)
        print(f"  Pass 1 (nur Header): {n_src1} Nachrichten, {len(wanted_message_ids)} moegliche Treffer, "
              f"{len(new_cache_rows)} neu in Adress-Cache")

        # Pass 2 (wie bisher): volle Verarbeitung - Nicht-Treffer mit bereits
        # bekannter Message-ID werden sofort uebersprungen, ohne Hash/Header-
        # Dekodierung. Nachrichten ganz ohne Message-ID (selten) durchlaufen
        # unveraendert die volle Pruefung wie zuvor.
        n_src = 0
        for raw in iter_full_messages(src_path):
            n_total += 1
            n_src += 1
            if n_src % 5000 == 0:
                print(f"  ... {n_src} Nachrichten aus dieser Quelle verarbeitet")
                flush_caches()

            message_id = get_header(raw, "Message-ID").strip()
            if message_id and message_id not in wanted_message_ids and message_id in mail_cache:
                n_no_patient += 1
                continue

            msg_hash = hashlib.sha256(raw).hexdigest()
            if seen_cache.execute("SELECT 1 FROM seen WHERE hash=?", (msg_hash,)).fetchone():
                n_cached_skip += 1
                continue

            from_raw = get_header(raw, "From")
            to_raw = get_header(raw, "To")
            cc_raw = get_header(raw, "Cc")
            date_raw = get_header(raw, "Date")
            subject_raw = decode_header_val(get_header(raw, "Subject"))

            _, sender_addr = parse_from_header(from_raw) if from_raw else ("", "")
            recipients = parse_addr_list(to_raw) + parse_addr_list(cc_raw)

            matched_patients = None
            direction = None
            partner_addr = None
            if sender_addr in OWN_ACCOUNT_EMAILS:
                for r in recipients:
                    if r in by_email:
                        matched_patients = by_email[r]
                        direction = "gesan."
                        partner_addr = r
                        break
            elif sender_addr in by_email:
                matched_patients = by_email[sender_addr]
                direction = "angek."
                partner_addr = sender_addr

            if not matched_patients:
                n_no_patient += 1
                continue

            try:
                msg_date = email.utils.parsedate_to_datetime(date_raw) if date_raw else None
            except Exception:
                msg_date = None
            if msg_date is None:
                n_error += 1
                continue

            try:
                mtime_ts = msg_date.timestamp()
            except (OverflowError, OSError, ValueError):
                mtime_ts = None

            try:
                msg = email.message_from_bytes(raw, policy=email.policy.compat32)
            except Exception:
                n_error += 1
                continue

            if len(matched_patients) == 1:
                resolved_patients = matched_patients
            else:
                # Adresse gehoert (in pat_email_adr) zu MEHREREN Patienten
                # (z.B. Ehepaar mit gemeinsamer Adresse, oder eine ueber
                # Abschnitt 3 der Vorschlagsliste bestaetigte gemeinsame
                # Adresse) - resolve_ambiguous_patients() versucht anhand
                # dieser konkreten Nachricht herauszufinden, wen sie
                # tatsaechlich betrifft. Ohne jeden Beleg werden
                # sicherheitshalber ALLE Kandidaten bedient (fehlende
                # Dokumentation im richtigen Patienten waere das groessere
                # Risiko als eine zusaetzliche Kopie bei einem falschen).
                body_text_raw = extract_body_html(msg)
                first_att_name, first_att_data = next(iter(extract_attachments(msg)), (None, None))
                resolved_patients = resolve_ambiguous_patients(
                    matched_patients, subject_raw, body_text_raw, first_att_name, first_att_data,
                    addr=partner_addr, direction=direction)
                if resolved_patients:
                    n_ambiguous_resolved += 1
                else:
                    n_ambiguous_fallback_all += 1
                    resolved_patients = matched_patients

            richtungswort = "von" if direction == "angek." else "an"

            # Nachrichteninhalt (Rendering/Text) ist patientenunabhaengig -
            # einmal pro Nachricht ermittelt/gerendert, nicht pro Patient
            # (auch wenn resolved_patients mehrere enthaelt).
            pdf_bytes = None
            candidate_text = render_cache.get(message_id) if message_id else None

            for patient in resolved_patients:
                fpatnr = str(patient["FSurogat"])
                nachname = sanitize((patient["FNachname"] or "").strip())
                vorname = sanitize((patient["FVorname"] or "").strip())
                zeitstempel = msg_date.strftime("%y%m%d %H%M%S")
                betreff_sane = sanitize(subject_raw)[:100]
                name_prefix_sane = sanitize(build_name_prefix(patient))
                base_name = (f"{name_prefix_sane} Email {richtungswort} {partner_addr} "
                             f"{zeitstempel}, {betreff_sane}")

                target_dir = os.path.join(DOK_ROOT, fpatnr)
                if target_dir not in existing_text_cache:
                    cache = {}
                    if os.path.isdir(target_dir):
                        # Erst alle in Frage kommenden Dateien mit aktuellem
                        # mtime/Groesse einsammeln, dann den persistenten Cache
                        # (dok_text_cache) in EINER Abfrage fuer genau diese
                        # Pfade abfragen - unveraenderte Dateien muessen so bei
                        # wiederholten Laeufen nicht erneut per pdfplumber
                        # ausgelesen werden (Ursache der wiederkehrenden
                        # "Zeitbudget ueberschritten"-Warnungen).
                        candidates = []  # (fp, mtime_unix, groesse)
                        for fn in os.listdir(target_dir):
                            if not (fn.lower().endswith(".pdf") and " email " in fn.lower()):
                                continue
                            fp = os.path.join(target_dir, fn)
                            try:
                                st = os.stat(fp)
                            except OSError:
                                continue
                            if st.st_size > MAX_CACHE_FILE_BYTES:
                                continue
                            candidates.append((fp, int(st.st_mtime), st.st_size))

                        cached = mail_id_cache.load_dok_text_cache(mail_cache_conn, [c[0] for c in candidates])

                        # Zeitbudget gilt nur noch fuer tatsaechliche Extraktion
                        # (Cache-Treffer sind praktisch kostenlos) - manche
                        # Patienten haben viele/grosse bestehende PDFs (z.B.
                        # umfangreiche Scans), deren Textextraktion kein eigenes
                        # Zeitlimit hat und daher den ganzen Lauf blockieren
                        # koennte. Nach Ablauf des Budgets werden restliche neue/
                        # geaenderte Dateien fuer den Duplikat-Vergleich einfach
                        # ausgelassen (im schlimmsten Fall entsteht dadurch mal
                        # eine redundante PDF, statt dass der Lauf haengen bleibt).
                        cache_build_start = time.monotonic()
                        for fp, mtime_unix, groesse in candidates:
                            hit = cached.get(fp)
                            if hit is not None and hit[0] == mtime_unix and hit[1] == groesse:
                                txt = hit[2]
                            else:
                                if time.monotonic() - cache_build_start > CACHE_BUILD_BUDGET_SECONDS:
                                    print(f"WARNUNG: Zeitbudget beim Cache-Aufbau fuer Patient {fpatnr} "
                                          f"ueberschritten - restliche bestehende Dateien nicht verglichen.")
                                    break
                                txt = normalize_pdf_text(extract_pdf_text(fp))
                                new_dok_text_rows.append((fp, mtime_unix, groesse, txt))
                            if txt:
                                cache[fp] = txt
                    existing_text_cache[target_dir] = cache

                # Ohne Vergleichsziel (Ordner noch leer) und im Trockenlauf lohnt
                # sich das aufwendige PDF-Rendering nicht - der Duplikat-Vergleich
                # haette ohnehin nichts, womit er vergleichen koennte. Email und
                # Anhaenge werden trotzdem informativ ins Aenderungsprotokoll
                # geschrieben (nur ohne tatsaechliches Rendern).
                if not apply_changes and not existing_text_cache[target_dir]:
                    n_created += 1
                    audit.log("Email als PDF abgelegt", fpatnr, neu=base_name + ".pdf", pfad=target_dir)
                    for att_name, _ in extract_attachments(msg):
                        att_name_sane = sanitize(decode_header_val(att_name))
                        audit.log("Anhang abgelegt", fpatnr, neu=f"{base_name}; {att_name_sane}", pfad=target_dir)
                    continue

                # Gerenderter/extrahierter Text einer Nachricht aendert sich nie -
                # aus dem persistenten Cache wiederverwenden, wenn vorhanden
                # (spart das teure Rendern, das war beim wiederholten Testlauf
                # der dominante Zeitanteil). pdf_bytes bleibt dann zunaechst
                # None - erst tatsaechlich rendern, wenn sich unten herausstellt,
                # dass die Nachricht wirklich neu abgelegt werden muss.
                if candidate_text is None:
                    pdf_bytes = render_message(msg, from_raw, to_raw, date_raw, subject_raw)
                    if pdf_bytes is None:
                        n_error += 1
                        continue
                    candidate_text = normalize_pdf_text(extract_pdf_text(BytesIO(pdf_bytes)))
                    if message_id:
                        new_render_rows.append((message_id, candidate_text))
                        render_cache[message_id] = candidate_text

                is_duplicate = any(candidate_text == t for t in existing_text_cache[target_dir].values())
                if is_duplicate:
                    n_duplicate += 1
                    continue

                if pdf_bytes is None:
                    # Text kam aus dem Cache, aber die Nachricht ist (noch) nicht
                    # bei DIESEM Patienten abgelegt - jetzt tatsaechlich rendern,
                    # um sie speichern zu koennen.
                    pdf_bytes = render_message(msg, from_raw, to_raw, date_raw, subject_raw)
                    if pdf_bytes is None:
                        n_error += 1
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
                        existing_text_cache[target_dir][pdf_path] = candidate_text
                        log_dokprot(dokprot_cur, fpatnr, nachname, vorname, gebdat_sql,
                                    "", os.path.basename(pdf_path), len(pdf_bytes), "pdf", msg_date,
                                    email_adresse=partner_addr)
                    audit.log("Email als PDF abgelegt", fpatnr, neu=os.path.basename(pdf_path), pfad=target_dir)
                    n_created += 1
                except Exception as e:
                    # Nur Fehlertyp + Patientennummer ausgeben, NIE die Exception-
                    # Nachricht selbst (kann den vollen Dateipfad inkl. Patienten-
                    # name enthalten).
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
                        audit.log("Anhang abgelegt", fpatnr, neu=os.path.basename(att_path), pfad=target_dir)
                    except Exception as e:
                        # Nur Fehlertyp + Patientennummer ausgeben, NIE die
                        # Exception-Nachricht selbst (kann den vollen Dateipfad
                        # inkl. Patientenname enthalten, z.B. bei OSError).
                        n_error += 1
                        print(f"FEHLER bei Anhang fuer Patient {fpatnr}: {type(e).__name__}")

            if apply_changes:
                mark_seen(seen_cache, msg_hash)

    flush_caches()
    if dokprot_conn:
        dokprot_conn.close()
    seen_cache.close()
    mail_cache_conn.close()
    audit.close()
    print(f"Aenderungsprotokoll: {audit.path}")

    print("=== Ergebnis ===")
    print(f"Nachrichten gesamt: {n_total}")
    print(f"Uebersprungen (bereits in frueherem Lauf archiviert, Cache): {n_cached_skip}")
    print(f"Kein Patient zuordenbar: {n_no_patient}")
    print(f"Fehler (Datum/Parsing/PDF-Rendering): {n_error}")
    print(f"Bereits vorhanden (inhaltlich, uebersprungen): {n_duplicate}")
    print(("Erzeugt" if apply_changes else "Wuerde erzeugt (Trockenlauf)") + f": {n_created}")
    print(f"Mehrdeutige Adresse (mehrere Patienten) - per Inhalt eingegrenzt: {n_ambiguous_resolved}")
    print(f"Mehrdeutige Adresse - kein Beleg gefunden, sicherheitshalber bei allen archiviert: {n_ambiguous_fallback_all}")


if __name__ == "__main__":
    main()
