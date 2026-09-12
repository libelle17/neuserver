# -*- coding: utf-8 -*-
# Gemeinsam genutzte Tabelle quelle.pat_email_adr (MariaDB, Host linux1) -
# alle bei der Vorschlagslisten-Pruefung bestaetigten Email-Adressen je
# Patient, unabhaengig davon, ob/wann der eigentliche medoff-Schreibvorgang
# (patstamm.FEmail/FStaatsangehoerigkeit) schon stattgefunden hat.
#
# Liegt bewusst in derselben MariaDB-Datenbank "quelle" wie dokprotlist
# (statt einer lokalen SQLite-Datei): dort laufen ohnehin schon die selbst
# verwalteten Tabellen dieses Projekts, und linux1 ist derselbe Rechner, der
# P:\dok als Samba-Freigabe bereitstellt - die Datengrundlage fuer die
# Email-Ablage liegt damit auf derselben Maschine wie die Ablage selbst.
#
# Zweck: patstamm.FEmail haelt nur EINE Adresse, FStaatsangehoerigkeit (70
# Zeichen) reicht als Freitext-Merker fuer weitere Adressen oft nicht (siehe
# [[project-missing-patient-emails]]). Hier steht daher JEDE bei der Pruefung
# bestaetigte Adresse als eigene Zeile - archive_patient_emails.py kann so
# saemtliche bekannten Adressen eines Patienten archivieren, nicht nur die
# eine, die zufaellig in FEmail gelandet ist. Ausserdem erlaubt das einen
# zweiphasigen Ablauf: apply_patient_emails.py schreibt zunaechst nur hierher
# (Phase "gestaged"), archive_patient_emails.py kann direkt danach schon
# archivieren, und erst ein spaeterer, eigener Schritt uebertraegt die
# Hauptadresse + Merker tatsaechlich nach medoff (Phase "committed") - bis
# dahin ist medoff unangetastet, ein Fehlschlag beim Archivieren kostet
# nichts.
#
# Spalte heisst pat_id (nicht patientennummer) - 2026-09-08 umbenannt, auf
# Wunsch, fuer Konsistenz mit sonstigen kurzen ID-Spaltennamen.
#
# Eindimensionales Adressmodell seit 2026-09-09: JEDE Adresse eines Patienten
# ist eine eigene Zeile mit einer Rollen-Kennung (rolle), statt wie zuvor eine
# Haupt-/Nebenadresse-Unterscheidung ueber ein Boolean-Feld plus eine
# verdraengte alte Adresse als Freitext (alt_mo_adresse) auf DERSELBEN Zeile
# zu fuehren. Grund: eine verdraengte alte Adresse muss selbst eine
# vollwertige, abfragbare Zeile sein - sonst "vergisst" find_missing_patient_
# emails.py sie beim naechsten Lauf wieder und schlaegt sie erneut als neuen
# Kandidaten vor (genau das ist am 2026-09-08 bei Patient 54171 passiert,
# siehe [[project-missing-patient-emails]]). all_known_emails() liefert daher
# ausnahmslos ALLE jemals bestaetigten Adressen (jede Rolle), die
# find_missing_patient_emails.py in known_emails aufnimmt.
#
# Spalte "bezug" (2026-09-11) fuer die geplante manuelle Pflege dieser
# Tabelle aus dem Patientenlaufzettel heraus (separates PHP-Projekt, siehe
# [[project-missing-patient-emails]]): freier Text fuer die Beziehung des
# Absenders zum Patienten, falls nicht der Patient selbst (z.B.
# "Schwiegersohn", "Rechtspfleger"). Fuer diese manuelle Pflege gilt: keine
# neuen rolle-/quelle-Buchstaben noetig - quelle='m' war schon fuer genau
# diesen Zweck reserviert, rolle bleibt h/a/n; eine Korrektur der aktuell in
# patstamm.FEmail stehenden Adresse sollte denselben Staging-Musters folgen
# wie apply_patient_emails.py (neue Zeile rolle='h' committed=0, alte Zeile
# auf rolle='a' zurueckgestuft) statt patstamm direkt zu beschreiben - sonst
# geht die bestehende Sicherheitspruefung beim eigentlichen medoff-Commit
# verloren.
#
# Spalten AktPC/Person/Vorbereiter/Behandler (2026-09-11), fuer denselben
# Zweck: 1:1 aus quelle.zutun/aktiv uebernommen (dort NOT NULL, hier NULL,
# da nur bei manuellen Eintraegen relevant) - dokumentieren, von welchem PC
# und durch wen (in welcher Rolle) eine manuelle Aenderung vorgenommen
# wurde, in genau der Konvention, die im uebrigen Praxissystem schon
# etabliert ist. Ebenfalls neu: Tabelle pat_email_adr_audit (gleiche
# Datenbank) - nur-anhaengendes Aenderungsprotokoll fuer die manuelle
# Pflege, Pendant zu den AendProt_Phase_*.csv-Dateien dieser Windows-
# seitigen Pipeline (siehe audit_log.py), aber als DB-Tabelle, weil der
# schreibende Prozess (PHP, linux1) keinen Zugriff auf die Windows-lokalen
# Protokolldateien hat. Wird ausschliesslich von der geplanten PHP-Pflege
# geschrieben/gelesen - deshalb hier kein Python-Gegenstueck zu stage() o.ae.
import os
import re
import pymysql

# Dieselbe Datenbank/dasselbe Passwort-Verfahren wie dokprotlist (siehe
# [[project-email-archiving-feature]]) - auch von archive_patient_emails.py
# genutzt (importiert connect_dokprot etc. von hier, um Duplizierung und
# einen Zirkel-Import zu vermeiden).
DOKPROT_HOST = "linux1"
DOKPROT_PORT = 3306
DOKPROT_USER = "praxis"
DOKPROT_DB = "quelle"
# Windows erreicht die Datei nur per UNC-Freigabe; auf linux1 selbst (siehe
# geplante Cron-Jobs, [[project-missing-patient-emails]]) ist es ein
# normaler lokaler Pfad - per Umgebungsvariable ueberschreibbar, damit
# dieses Modul unveraendert auf beiden Seiten funktioniert.
DOKPROT_PWD_SHARE = os.environ.get("DOKPROT_PWD_SHARE", r"\\linux1\dbverbfreigabe\dbverb.cfg")

TABLE_LABEL = "quelle.pat_email_adr"  # fuer Protokoll-Anzeigen

ROLLE_HAUPT = "h"    # aktuell in patstamm.FEmail
ROLLE_ALT = "a"      # fruehere Hauptadresse, durch neuere ersetzt
ROLLE_NEBEN = "n"    # weitere bestaetigte Adresse (z.B. Abschn. 3/5)

QUELLE_CLAUDE = "c"
QUELLE_MANUELL = "m"
QUELLE_SYNC = "s"    # automatisch von einer direkten medoff-Aenderung uebernommen (siehe sync_from_medoff())


def read_dokprot_password():
    with open(DOKPROT_PWD_SHARE, encoding="utf-8", errors="replace") as f:
        lines = f.readlines()
    uid = pwd = None
    for line in lines:
        line = line.strip()
        if line.startswith("uid="):
            uid = line[4:]
        elif line.startswith("pwd="):
            pwd = line[4:]
    if uid != DOKPROT_USER:
        raise RuntimeError("Unerwarteter uid in " + DOKPROT_PWD_SHARE)
    return pwd


def connect_dokprot():
    pwd = read_dokprot_password()
    return pymysql.connect(host=DOKPROT_HOST, port=DOKPROT_PORT, user=DOKPROT_USER,
                            password=pwd, database=DOKPROT_DB, connect_timeout=10,
                            autocommit=True, cursorclass=pymysql.cursors.DictCursor)


def connect():
    conn = connect_dokprot()
    conn.cursor().execute("""
        CREATE TABLE IF NOT EXISTS pat_email_adr (
            pat_id VARCHAR(20) NOT NULL COMMENT 'Patientennummer (patstamm.FSurogat)',
            email VARCHAR(100) NOT NULL COMMENT 'Email-Adresse',
            rolle VARCHAR(1) NOT NULL DEFAULT 'h'
                COMMENT 'h(aupt) = aktuell in patstamm.FEmail; a(lt) = fruehere Hauptadresse, durch neuere ersetzt; n(eben) = weitere bestaetigte Adresse (z.B. Abschn. 3/5)',
            quelle VARCHAR(1) NOT NULL DEFAULT 'c'
                COMMENT 'c(laude) = automatisch per Vorschlagsliste gefunden; m(anuell) = von Hand eingetragen; s(ync) = automatisch von einer direkten medoff-Aenderung uebernommen (durch commit_medoff erkannt)',
            bezug VARCHAR(60) NULL
                COMMENT 'Beziehung des Absenders zum Patienten, falls nicht der Patient selbst (z.B. Schwiegersohn, Rechtspfleger, Betreuer) - freier Text, hauptsaechlich bei manuellen Eintraegen (quelle=m) relevant',
            AktPC VARCHAR(20) NULL
                COMMENT 'Name des PC, von dem aus die Aenderung vorgenommen wurde (wie zutun/aktiv.AktPC) - nur bei manuellen Eintraegen (quelle=m) relevant',
            Person CHAR(1) NULL
                COMMENT 'A=anwesend, a=anwesend an Behandler, V=Vorbereiter, v=Vorbereiter an Behandler, B=Behandler (wie zutun/aktiv.Person) - nur bei manuellen Eintraegen (quelle=m) relevant',
            Vorbereiter CHAR(5) NULL
                COMMENT 'Namenskuerzel Vorbereiter (wie zutun/aktiv.Vorbereiter) - nur bei manuellen Eintraegen (quelle=m) relevant',
            Behandler CHAR(5) NULL
                COMMENT 'Namenskuerzel Behandler (wie zutun/aktiv.Behandler) - nur bei manuellen Eintraegen (quelle=m) relevant',
            marker VARCHAR(70) NULL
                COMMENT 'Text, der bei Commit in patstamm.FStaatsangehoerigkeit geschrieben wurde (nur rolle=h)',
            erfasst_am DATETIME NOT NULL COMMENT 'Zeitpunkt des Stagings/Eintrags',
            committed TINYINT NOT NULL DEFAULT 0
                COMMENT '1 = bereits nach patstamm.FEmail uebertragen (nur rolle=h relevant)',
            PRIMARY KEY (pat_id, email)
        ) CHARACTER SET utf8mb4
    """)
    conn.cursor().execute("""
        CREATE TABLE IF NOT EXISTS pat_email_adr_audit (
            id INT AUTO_INCREMENT PRIMARY KEY,
            zeitstempel DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Zeitpunkt der Aenderung',
            aktion VARCHAR(100) NOT NULL COMMENT 'z.B. hinzugefuegt / geaendert / geloescht / FEmail geaendert / FStaatsangehoerigkeit geaendert / FEmail manuell in medoff geaendert - pat_email_adr synchronisiert',
            pat_id VARCHAR(20) NOT NULL COMMENT 'Patientennummer (patstamm.FSurogat)',
            alt_email VARCHAR(100) NULL COMMENT 'Wert vor der Aenderung (leer bei Neuanlage)',
            neu_email VARCHAR(100) NULL COMMENT 'Wert nach der Aenderung (leer bei Loeschung)',
            bezug VARCHAR(60) NULL COMMENT 'Beziehung des Absenders zum Patienten, wie pat_email_adr.bezug',
            AktPC VARCHAR(20) NULL COMMENT 'wie pat_email_adr.AktPC',
            Person CHAR(1) NULL COMMENT 'wie pat_email_adr.Person (A/a/V/v/B, siehe zutun/aktiv)',
            Vorbereiter CHAR(5) NULL COMMENT 'wie pat_email_adr.Vorbereiter',
            Behandler CHAR(5) NULL COMMENT 'wie pat_email_adr.Behandler',
            bemerkung VARCHAR(200) NULL COMMENT 'freier Text, optional'
        ) CHARACTER SET utf8mb4
        COMMENT 'Nur-anhaengendes Aenderungsprotokoll fuer manuelle Pflege von pat_email_adr ueber den Patientenlaufzettel (PHP, linux1) und die linux1-Wartungsskripte - Pendant zu den AendProt_Phase_*.csv-Dateien der Windows-seitigen Pipeline, siehe audit_log.py. Schreibt NIE waehrend eines Trockenlaufs (siehe log_audit()).'
    """)
    return conn


def stage(conn, pat_id, email, rolle=ROLLE_HAUPT, quelle=QUELLE_CLAUDE, marker=None, bezug=None,
          aktpc=None, person=None, vorbereiter=None, behandler=None):
    conn.cursor().execute(
        "INSERT INTO pat_email_adr "
        "(pat_id, email, rolle, quelle, bezug, AktPC, Person, Vorbereiter, Behandler, marker, erfasst_am, committed) "
        "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), 0) "
        "ON DUPLICATE KEY UPDATE rolle=VALUES(rolle), quelle=VALUES(quelle), "
        "bezug=VALUES(bezug), AktPC=VALUES(AktPC), Person=VALUES(Person), "
        "Vorbereiter=VALUES(Vorbereiter), Behandler=VALUES(Behandler), "
        "marker=VALUES(marker), erfasst_am=VALUES(erfasst_am)",
        (pat_id, email, rolle, quelle, bezug, aktpc, person, vorbereiter, behandler, marker)
    )


def addresses_by_patient(conn):
    """pat_id -> Liste ALLER bekannten Adressen (Hauptadresse zuerst, dann
    Neben-, dann Alt-Adressen) - fuer archive_patient_emails.py, das von
    saemtlichen Adressen eines Patienten archivieren soll, auch von laengst
    verdraengten alten."""
    cur = conn.cursor()
    cur.execute(
        "SELECT pat_id, email FROM pat_email_adr "
        "ORDER BY pat_id, FIELD(rolle, 'h', 'n', 'a'), email"
    )
    out = {}
    for row in cur.fetchall():
        out.setdefault(str(row["pat_id"]), []).append(row["email"])
    return out


def all_known_emails(conn):
    """Flache Menge ALLER jemals bestaetigten Adressen, jede Rolle - fuer
    find_missing_patient_emails.py: eine einmal verdraengte oder als weitere
    Adresse bestaetigte Adresse soll nie wieder als neuer Kandidat auftauchen."""
    cur = conn.cursor()
    cur.execute("SELECT email FROM pat_email_adr")
    return {row["email"] for row in cur.fetchall()}


def alt_addresses_by_patient(conn):
    """pat_id -> Menge der verdraengten alten Hauptadressen (rolle='a') -
    fuer die Sicherheitspruefung in commit_phase (apply_patient_emails.py):
    das aktuelle patstamm.FEmail muss entweder leer oder eine dieser
    erwarteten alten Adressen sein, sonst hat sich seit dem Staging etwas
    zwischenzeitlich geaendert."""
    cur = conn.cursor()
    cur.execute("SELECT pat_id, email FROM pat_email_adr WHERE rolle=%s", (ROLLE_ALT,))
    out = {}
    for row in cur.fetchall():
        out.setdefault(str(row["pat_id"]), set()).add(row["email"])
    return out


def pending_main_addresses(conn):
    """pat_id -> (hauptadresse, marker) fuer noch nicht nach medoff
    uebernommene Hauptadress-Zeilen."""
    cur = conn.cursor()
    cur.execute(
        "SELECT pat_id, email, marker FROM pat_email_adr "
        "WHERE rolle=%s AND committed=0", (ROLLE_HAUPT,)
    )
    return {str(row["pat_id"]): (row["email"], row["marker"])
            for row in cur.fetchall()}


def mark_committed(conn, pat_id):
    conn.cursor().execute(
        "UPDATE pat_email_adr SET committed=1 WHERE pat_id=%s", (pat_id,)
    )


def sync_from_medoff(conn, pat_id, aktuelles_email, verdraengte_email, verdraengte_rolle=ROLLE_NEBEN):
    """Uebernimmt eine DIREKT in medoff.patstamm.FEmail vorgenommene Aenderung
    (nicht ueber pat_email_adr/den PHP-Dialog) nach pat_email_adr. Zwei
    Aufrufer mit unterschiedlicher Bedeutung von "verdraengte_email":

    1. commit_phase() (apply_patient_emails.py): erkennt DURCH ZUFALL beim
       Versuch, eine noch nicht committete Zeile zu schreiben, dass medoff
       zwischenzeitlich einen ANDEREN Wert bekommen hat. "verdraengte_email"
       ist hier die verworfene, nie tatsaechlich committete Zeile - hat also
       nie wirklich als Hauptadresse in medoff gestanden, daher Default
       verdraengte_rolle=ROLLE_NEBEN (nicht ROLLE_ALT).
    2. Ein periodischer Abgleichs-Job (z.B. Cron auf linux1) betrachtet
       GEZIELT alle bereits committeten (rolle=h, committed=1) Zeilen und
       vergleicht sie mit dem aktuellen medoff-Stand. Hier WAR
       "verdraengte_email" tatsaechlich die bisherige Hauptadresse - hier
       verdraengte_rolle=ROLLE_ALT uebergeben.

    Ohne diese Funktion wuerde eine so entdeckte Abweichung entweder bei
    jedem kuenftigen Commit-Lauf erneut uebersprungen (Fall 1) oder schlicht
    nie bemerkt (Fall 2). Uebernimmt den neuen Ist-Stand als eigene, bereits
    abgeschlossene Zeile (rolle=h, quelle=s, committed=1 - er steht ja schon
    in medoff, nichts mehr zu tun)."""
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO pat_email_adr (pat_id, email, rolle, quelle, erfasst_am, committed) "
        "VALUES (%s, %s, %s, %s, NOW(), 1) "
        "ON DUPLICATE KEY UPDATE rolle=VALUES(rolle), quelle=VALUES(quelle), "
        "erfasst_am=VALUES(erfasst_am), committed=1",
        (pat_id, aktuelles_email, ROLLE_HAUPT, QUELLE_SYNC)
    )
    cur.execute(
        "UPDATE pat_email_adr SET rolle=%s WHERE pat_id=%s AND email=%s AND rolle=%s",
        (verdraengte_rolle, pat_id, verdraengte_email, ROLLE_HAUPT)
    )


def demote_to_alt(conn, pat_id, email):
    """Stuft eine rolle='h'-Zeile auf rolle='a' zurueck, OHNE eine neue
    Hauptadresse einzutragen - fuer den Fall, dass patstamm.FEmail komplett
    geleert wurde (keine Ersatzadresse bekannt). Absichtlich keine leere
    email-Zeile eingefuegt, da email Teil des Primaerschluessels und
    NOT NULL ist - eine "leere Hauptadresse" laesst sich in diesem Schema
    nicht abbilden, nur ihr Fehlen."""
    conn.cursor().execute(
        "UPDATE pat_email_adr SET rolle=%s WHERE pat_id=%s AND email=%s AND rolle=%s",
        (ROLLE_ALT, pat_id, email, ROLLE_HAUPT)
    )


def log_audit(conn, aktion, pat_id, alt="", neu="", bemerkung=None, apply_changes=True):
    """Schreibt eine Zeile in pat_email_adr_audit - das DB-seitige Pendant
    zu den AendProt_Phase_*.csv-Dateien der Windows-Pipeline (siehe
    audit_log.py), fuer alle Schreibzugriffe, die von linux1 aus erfolgen
    (PHP-Dialog, linux1_commit_medoff.py, linux1_sync_medoff_changes.py) -
    dort ist die Windows-lokale Protokolldatei nicht erreichbar.

    apply_changes=False (Trockenlauf) schreibt bewusst GAR NICHTS - anders
    als audit_log.AuditLog.log() (das eine neue, pro Lauf eigene CSV-Datei
    auch fuer simulierte Aenderungen fuellt, was dort folgenlos ist), waere
    ein INSERT in diese gemeinsame, dauerhafte Tabelle bei einem
    Trockenlauf ein echter, nicht als solcher kenntlich gemachter Eintrag
    in einem sonst nur echte Aenderungen enthaltenden Protokoll - gefunden
    beim ersten Testlauf auf linux1, siehe [[project-missing-patient-emails]]."""
    if not apply_changes:
        return
    conn.cursor().execute(
        "INSERT INTO pat_email_adr_audit (aktion, pat_id, alt_email, neu_email, bemerkung) "
        "VALUES (%s, %s, %s, %s, %s)",
        (aktion, pat_id, alt, neu, bemerkung)
    )


def is_latin1_safe(s):
    try:
        (s or "").encode("latin-1")
        return True
    except UnicodeEncodeError:
        return False


# Format aus apply_patient_emails.build_marker(): "->YYMMDD" + optional
# " (<alte-mo-adresse>)". Damit laesst sich unterscheiden, ob
# patstamm.FStaatsangehoerigkeit einen eigenen, frueher von dieser
# Pipeline selbst gesetzten Marker enthaelt (unbedenklich, kann bei einer
# erneuten Korrektur ueberschrieben werden) oder einen echten, fremden
# Inhalt (z.B. tatsaechliche Nationalitaetsdaten - dort weiter blockieren).
OWN_MARKER_RE = re.compile(r"^->\d{6}(?: \(.+\))?$")


def is_own_marker(value):
    return bool(OWN_MARKER_RE.match(value or ""))


def commit_pending_main_addresses(padb_conn, medoff_cursor, apply_changes, log):
    """Zentrale, plattform-unabhaengige Commit-Logik (2026-09-12 aus
    apply_patient_emails.py.commit_phase() herausgezogen, nachdem zwei
    getrennte Nachbauten dieser Logik - hier und im geplanten PHP-Dialog -
    bereits einmal auseinandergedriftet waren und zu einem echten Bug
    gefuehrt hatten, siehe [[project-missing-patient-emails]]). Uebertraegt
    wartende Hauptadressen (rolle='h', committed=0) aus pat_email_adr nach
    medoff.patstamm.FEmail/FStaatsangehoerigkeit.

    Der Aufrufer stellt bereit:
      - padb_conn: offene quelle-Verbindung (patient_addresses_db.connect()).
      - medoff_cursor: offener Cursor auf einer medoff-Verbindung, Zeilen
        als dict-artiges Objekt (z.B. pymysql.cursors.DictCursor).
      - apply_changes: False = Trockenlauf (nur zaehlen/melden).
      - log(aktion, pat_id, alt="", neu=""): fuer die Audit-Protokollierung
        der tatsaechlich aenderungsrelevanten Aktionen (Windows: schreibt
        AendProt_Phase_F.csv via audit_log.AuditLog.log - kann direkt als
        log=audit.log uebergeben werden; Linux: INSERT in
        pat_email_adr_audit).

    Commit/Rollback beider Verbindungen bleibt Sache des Aufrufers - diese
    Funktion ruft weder .commit() noch .close() auf. Gibt ein dict mit den
    Ergebniszaehlern zurueck (n_written, n_already_current,
    n_skipped_changed, n_synced, n_skipped_belegt, n_skipped_encoding)."""
    pending = pending_main_addresses(padb_conn)
    alt_by_patient = alt_addresses_by_patient(padb_conn)
    print(f"Noch nicht in medoff uebernommene Patienten: {len(pending)}")

    n_written = 0
    n_already_current = 0
    n_skipped_changed = 0
    n_synced = 0
    n_skipped_belegt = 0
    n_skipped_encoding = 0
    n_error = 0

    for pat_id, (neu_email, marker) in pending.items():
        try:
            # Bereits vor dem Latin1-Fix (2026-09-08) gestagte Zeilen tragen
            # noch den alten Unicode-Pfeil "→" statt "->" - hier
            # normalisieren, damit sie nicht erneut UEBERSPRUNGEN werden
            # bzw. nicht erneut abstuerzen.
            marker = (marker or "").replace("→", "->")
            if not (is_latin1_safe(marker) and is_latin1_safe(neu_email)):
                n_skipped_encoding += 1
                print(f"UEBERSPRUNGEN (Zeichen ausserhalb Latin-1): Patient {pat_id}")
                continue

            medoff_cursor.execute("SELECT FEmail, FStaatsangehoerigkeit FROM patstamm WHERE FSurogat=%s", (pat_id,))
            row = medoff_cursor.fetchone()
            if row is None:
                n_skipped_changed += 1
                print(f"UEBERSPRUNGEN (Patient nicht mehr gefunden): {pat_id}")
                continue
            aktuelles_email = (row["FEmail"] or "").strip().lower()
            aktuelle_marke = (row["FStaatsangehoerigkeit"] or "").strip()

            if aktuelles_email == neu_email:
                # medoff zeigt bereits exakt den gewuenschten Wert - z.B. wenn
                # eine gestagte Zeile per "Rueckgaengig" (PHP-Pflege) wieder auf
                # eine Adresse zurueckgesetzt wurde, die dort ohnehin schon
                # unveraendert steht. Nichts zu schreiben, nur als erledigt
                # markieren - sonst wuerde der naechste Vergleich unten
                # faelschlich "zwischenzeitlich veraendert" auswerten und
                # sync_from_medoff() faelschlich ausloesen.
                n_already_current += 1
                if apply_changes:
                    mark_committed(padb_conn, pat_id)
                continue

            erwartet = alt_by_patient.get(pat_id, set())
            if aktuelles_email not in ({""} | erwartet):
                # Jemand hat FEmail direkt in medoff geaendert (nicht ueber
                # pat_email_adr) - den neuen Ist-Stand uebernehmen, statt diese
                # Zeile bei jedem kuenftigen Lauf erneut zu uebergehen.
                n_skipped_changed += 1
                n_synced += 1
                print(f"UEBERSPRUNGEN, aber pat_email_adr synchronisiert (FEmail zwischenzeitlich veraendert): Patient {pat_id}")
                if apply_changes:
                    sync_from_medoff(padb_conn, pat_id, aktuelles_email, neu_email)
                log("FEmail manuell in medoff geaendert - pat_email_adr synchronisiert",
                    pat_id, alt=neu_email, neu=aktuelles_email)
                continue
            if aktuelle_marke and not is_own_marker(aktuelle_marke):
                # Nur bei WIRKLICH fremdem Inhalt blockieren (z.B. echte
                # Nationalitaetsdaten) - ein eigener, frueherer Marker dieser
                # Pipeline darf bei einer erneuten Korrektur ueberschrieben
                # werden. Ohne diese Unterscheidung blieb JEDER Patient nach
                # seinem ersten Commit fuer immer blockiert, da das Feld nie
                # wieder geleert wird - real bestaetigt am 2026-09-12: alle
                # 1310 Patienten mit nicht-leerem FStaatsangehoerigkeit hatten
                # ausschliesslich eigene Marker, keine fremden Daten.
                n_skipped_belegt += 1
                print(f"UEBERSPRUNGEN (FStaatsangehoerigkeit bereits belegt): Patient {pat_id}")
                continue

            n_written += 1
            if apply_changes:
                medoff_cursor.execute(
                    "UPDATE patstamm SET FEmail=%s, FStaatsangehoerigkeit=%s WHERE FSurogat=%s",
                    (neu_email, marker, pat_id)
                )
                mark_committed(padb_conn, pat_id)
            log("FEmail geaendert", pat_id, alt=aktuelles_email, neu=neu_email)
            log("FStaatsangehoerigkeit geaendert", pat_id, alt=aktuelle_marke, neu=marker)
        except Exception as e:
            # Ein unerwarteter Fehler bei EINEM Patienten (z.B. ein
            # fehlschlagender log()-Aufruf) soll nicht die Verarbeitung
            # aller anderen wartenden Patienten in diesem Lauf abbrechen -
            # gefunden beim ersten Testlauf auf linux1 (zu kurze
            # aktion-Spalte liess log_audit() mitten in der Schleife
            # abstuerzen), siehe [[project-missing-patient-emails]]. Nie
            # str(e) ausgeben (kann Patientendaten enthalten).
            n_error += 1
            print(f"FEHLER ({type(e).__name__}) bei Patient {pat_id} - uebersprungen")

    return {
        "n_written": n_written,
        "n_already_current": n_already_current,
        "n_error": n_error,
        "n_skipped_changed": n_skipped_changed,
        "n_synced": n_synced,
        "n_skipped_belegt": n_skipped_belegt,
        "n_skipped_encoding": n_skipped_encoding,
    }
