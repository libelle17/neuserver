# -*- coding: utf-8 -*-
# Persistenter Message-ID -> (Absender, Empfaenger)-Cache in der separaten
# MariaDB-Datenbank "emails" (Host linux1, gleiche Zugangsdaten wie quelle).
# Bewusst NICHT in quelle: dort liegen die patientenbezogenen Tabellen dieses
# Projekts (pat_email_adr, dokprotlist), waehrend hier JEDE gescannte
# Nachricht landet - auch die grosse Mehrheit ohne jeden Patientenbezug.
# "emails" enthaelt bereits andere, nicht patientenbezogene Mail-Tabellen
# (lmail*) eines anderen/aelteren Programms - eigene Tabelle mit eigenem
# Namen, keine Beruehrung mit denen.
#
# Zweck: archive_patient_emails.py muss sonst bei JEDEM Lauf fuer JEDE der
# oft zehntausenden Nachrichten ohne Patientenbezug erneut die volle
# Nachricht lesen, hashen und die Header dekodieren, nur um erneut
# festzustellen, dass sie zu keinem Patienten gehoert. Hier wird NUR das
# Ergebnis der (billigen) Adress-EXTRAKTION gespeichert, NICHT das Ergebnis
# des (teuren) Patienten-ABGLEICHS - bei jedem Lauf wird die gecachte Adresse
# erneut gegen den AKTUELLEN Patientenstand geprueft (patient_addresses_db +
# patstamm.FEmail). Sonst wuerde eine Nachricht, die heute noch niemandem
# zuordenbar ist, aber morgen (weil genau diese Adresse neu bei einem
# Patienten hinterlegt wird) zuordenbar waere, faelschlich fuer immer
# uebersprungen - siehe [[project-missing-patient-emails]], Fall Patient
# 54171 (derselbe Fehler, den die Restrukturierung von pat_email_adr schon
# einmal beheben musste).
import json
import pymysql
from patient_addresses_db import DOKPROT_HOST, DOKPROT_PORT, DOKPROT_USER, read_dokprot_password

DB_NAME = "emails"
TABLE_LABEL = "emails.mail_adressen_cache"


def connect():
    pwd = read_dokprot_password()
    conn = pymysql.connect(host=DOKPROT_HOST, port=DOKPROT_PORT, user=DOKPROT_USER,
                            password=pwd, database=DB_NAME, connect_timeout=10,
                            autocommit=True, cursorclass=pymysql.cursors.DictCursor)
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS mail_adressen_cache (
            message_id VARCHAR(255) NOT NULL COMMENT 'Message-ID Header der Nachricht (RFC-eindeutig)',
            absender VARCHAR(255) NULL COMMENT 'Absenderadresse (From), klein geschrieben',
            empfaenger TEXT NULL COMMENT 'Empfaengeradressen (To+Cc), durch Semikolon getrennt, klein geschrieben',
            quelle_datei VARCHAR(255) NULL COMMENT 'mbox-Datei, in der die Nachricht zuletzt gesehen wurde',
            erfasst_am DATETIME NOT NULL COMMENT 'Zeitpunkt der ersten Erfassung',
            PRIMARY KEY (message_id)
        ) CHARACTER SET utf8mb4
    """)
    # Extrahierter, normalisierter PDF-Text einer gerenderten Nachricht - reine
    # Funktion des (unveraenderlichen) Nachrichteninhalts, daher unbegrenzt
    # cachebar (anders als der Adress-Cache oben gibt es hier KEINE
    # Aktualitaetsfrage). Erspart erneutes Rendern (teuer) bei wiederholten
    # Laeufen (auch Trockenlaeufen) fuer Nachrichten, die sich als bereits
    # vorhanden herausstellen - das war der dominante Zeitanteil beim
    # zweiten Testlauf am 2026-09-09.
    cur.execute("""
        CREATE TABLE IF NOT EXISTS mail_render_cache (
            message_id VARCHAR(255) NOT NULL COMMENT 'Message-ID Header der Nachricht (RFC-eindeutig)',
            text_normalisiert LONGTEXT NULL COMMENT 'Normalisierter Text aus dem gerenderten Email-PDF (fuer Duplikat-Vergleich)',
            erfasst_am DATETIME NOT NULL COMMENT 'Zeitpunkt der ersten Erfassung',
            PRIMARY KEY (message_id)
        ) CHARACTER SET utf8mb4
    """)
    # Extrahierter, normalisierter Text bereits in P:\dok liegender PDFs -
    # ebenfalls unveraenderlich, solange sich die Datei nicht aendert (Pruefung
    # ueber mtime+Groesse). Erspart die wiederholte Textextraktion derselben
    # bestehenden Dateien beim Aufbau von existing_text_cache in jedem Lauf
    # (Ursache der wiederkehrenden "Zeitbudget ueberschritten"-Warnungen).
    cur.execute("""
        CREATE TABLE IF NOT EXISTS dok_text_cache (
            pfad VARCHAR(500) NOT NULL COMMENT 'Pfad der PDF-Datei in P:\\dok',
            mtime_unix BIGINT NOT NULL COMMENT 'Aenderungszeitpunkt der Datei (Unix-Zeitstempel) beim Erfassen',
            groesse BIGINT NOT NULL COMMENT 'Dateigroesse in Bytes beim Erfassen',
            text_normalisiert LONGTEXT NULL COMMENT 'Normalisierter extrahierter Text (fuer Duplikat-Vergleich)',
            erfasst_am DATETIME NOT NULL COMMENT 'Zeitpunkt der Erfassung',
            PRIMARY KEY (pfad)
        ) CHARACTER SET utf8mb4
    """)
    # Extrahierter Body-Text + Anhang-Metadaten (Dateiname/Groesse/Hash, NICHT
    # der Anhangsinhalt selbst) einer Nachricht - reine Funktion des
    # unveraenderlichen Nachrichteninhalts, unbegrenzt cachebar. Erspart
    # find_missing_patient_emails.py das erneute volle MIME-Parsen (inkl.
    # Anhang-Hashing) bei jedem Aufruf fuer Nachrichten von Kandidaten-
    # Adressen, die schon in einem frueheren Lauf so analysiert wurden.
    cur.execute("""
        CREATE TABLE IF NOT EXISTS mail_content_cache (
            message_id VARCHAR(255) NOT NULL COMMENT 'Message-ID Header der Nachricht (RFC-eindeutig)',
            body LONGTEXT NULL COMMENT 'Extrahierter Body-Text (erste body_limit Zeichen, wie im Original)',
            attachments TEXT NULL COMMENT 'JSON-Liste [[dateiname, groesse, sha256-hash], ...] der Anhaenge',
            erfasst_am DATETIME NOT NULL COMMENT 'Zeitpunkt der ersten Erfassung',
            PRIMARY KEY (message_id)
        ) CHARACTER SET utf8mb4
    """)
    # Dauerhafte Ausschlussliste bekannter GENERISCHER Anhaenge (z.B.
    # Produktbroschueren), die routinemaessig an mehrere Patienten
    # verschickt werden - deren Inhalts-Hash bei mehreren Patienten in
    # P:\dok liegen KANN, ohne dass das etwas ueber die Identitaet des
    # Absenders/Empfaengers aussagt. Der bestehende len(cand)==1-Check in
    # find_missing_patient_emails.py (Anhang-Matching) erkennt eine solche
    # Ueberschneidung nur, wenn zum Pruefzeitpunkt BEREITS bei mehr als
    # einem Patienten eine Datei mit demselben Hash archiviert ist - beim
    # ERSTEN Versand (nur ein Patient hat die Datei bisher) schlaegt das
    # nicht an. Diese Tabelle faengt genau diesen Fall ab, sobald ein
    # solcher Hash einmal von Hand als generisch erkannt wurde (2026-09-12,
    # Fall Patient 53594/63872, Omnipod-5-Broschuere) - siehe
    # [[project-missing-patient-emails]].
    cur.execute("""
        CREATE TABLE IF NOT EXISTS generic_attachment_hashes (
            hash CHAR(64) NOT NULL COMMENT 'SHA256-Hash des Anhangsinhalts',
            groesse BIGINT NULL COMMENT 'Dateigroesse in Bytes (nur zur Information)',
            erfasst_am DATETIME NOT NULL COMMENT 'Zeitpunkt der Eintragung',
            bemerkung VARCHAR(200) NULL COMMENT 'Freitext, z.B. worum es sich handelt',
            PRIMARY KEY (hash)
        ) CHARACTER SET utf8mb4
        COMMENT 'Von Hand gepflegte Ausschlussliste - Anhaenge mit diesem Hash zaehlen nicht als Beweis fuer die Identitaet des Absenders/Empfaengers'
    """)
    return conn


def load_generic_attachment_hashes(conn):
    """Menge aller als generisch bekannten Anhangs-Hashes."""
    cur = conn.cursor()
    cur.execute("SELECT hash FROM generic_attachment_hashes")
    return {row["hash"] for row in cur.fetchall()}


def mark_generic_attachment(conn, digest, groesse=None, bemerkung=None):
    conn.cursor().execute(
        "INSERT IGNORE INTO generic_attachment_hashes (hash, groesse, erfasst_am, bemerkung) "
        "VALUES (%s, %s, NOW(), %s)",
        (digest, groesse, bemerkung)
    )


def load_all(conn):
    """message_id -> (absender, [empfaenger, ...]) - kompletter Cache, auf
    einmal geladen (wie dok_index/known_emails anderswo im Projekt)."""
    cur = conn.cursor()
    cur.execute("SELECT message_id, absender, empfaenger FROM mail_adressen_cache")
    out = {}
    for row in cur.fetchall():
        empf = [e for e in (row["empfaenger"] or "").split(";") if e]
        out[row["message_id"]] = (row["absender"] or "", empf)
    return out


def insert_batch(conn, rows):
    """rows: Liste von (message_id, absender, empfaenger_liste, quelle_datei).
    INSERT IGNORE, da dieselbe Message-ID (z.B. durch Verschieben zwischen
    Ordnern) mehrfach in einer Quelle auftauchen kann."""
    if not rows:
        return
    cur = conn.cursor()
    cur.executemany(
        "INSERT IGNORE INTO mail_adressen_cache "
        "(message_id, absender, empfaenger, quelle_datei, erfasst_am) "
        "VALUES (%s, %s, %s, %s, NOW())",
        [(mid, sender, ";".join(recips), src) for mid, sender, recips, src in rows]
    )


def load_render_cache(conn):
    """message_id -> normalisierter Text bereits gerenderter Nachrichten."""
    cur = conn.cursor()
    cur.execute("SELECT message_id, text_normalisiert FROM mail_render_cache")
    return {row["message_id"]: row["text_normalisiert"] or "" for row in cur.fetchall()}


def insert_render_batch(conn, rows):
    """rows: Liste von (message_id, text_normalisiert)."""
    if not rows:
        return
    cur = conn.cursor()
    cur.executemany(
        "INSERT IGNORE INTO mail_render_cache (message_id, text_normalisiert, erfasst_am) "
        "VALUES (%s, %s, NOW())",
        rows
    )


def load_dok_text_cache(conn, paths):
    """pfad -> (mtime_unix, groesse, text_normalisiert), NUR fuer die
    uebergebenen Pfade (nicht der ganze P:\\dok-Baum - der ist zu gross fuer
    einen vollstaendigen Bulk-Load, waehrend ein Lauf ohnehin nur die
    Ordner weniger hundert Patienten anfasst)."""
    if not paths:
        return {}
    cur = conn.cursor()
    placeholders = ",".join(["%s"] * len(paths))
    cur.execute(
        f"SELECT pfad, mtime_unix, groesse, text_normalisiert FROM dok_text_cache "
        f"WHERE pfad IN ({placeholders})", paths
    )
    return {row["pfad"]: (row["mtime_unix"], row["groesse"], row["text_normalisiert"] or "")
            for row in cur.fetchall()}


def upsert_dok_text_batch(conn, rows):
    """rows: Liste von (pfad, mtime_unix, groesse, text_normalisiert)."""
    if not rows:
        return
    cur = conn.cursor()
    cur.executemany(
        "INSERT INTO dok_text_cache (pfad, mtime_unix, groesse, text_normalisiert, erfasst_am) "
        "VALUES (%s, %s, %s, %s, NOW()) "
        "ON DUPLICATE KEY UPDATE mtime_unix=VALUES(mtime_unix), groesse=VALUES(groesse), "
        "text_normalisiert=VALUES(text_normalisiert), erfasst_am=VALUES(erfasst_am)",
        rows
    )


def load_content_cache(conn):
    """message_id -> (body, [(dateiname, groesse, hash), ...]) - fuer
    find_missing_patient_emails.py."""
    cur = conn.cursor()
    cur.execute("SELECT message_id, body, attachments FROM mail_content_cache")
    out = {}
    for row in cur.fetchall():
        atts_raw = json.loads(row["attachments"]) if row["attachments"] else []
        out[row["message_id"]] = (row["body"] or "", [tuple(a) for a in atts_raw])
    return out


def insert_content_batch(conn, rows):
    """rows: Liste von (message_id, body, attachments_liste)."""
    if not rows:
        return
    cur = conn.cursor()
    cur.executemany(
        "INSERT IGNORE INTO mail_content_cache (message_id, body, attachments, erfasst_am) "
        "VALUES (%s, %s, %s, NOW())",
        [(mid, body, json.dumps(list(atts))) for mid, body, atts in rows]
    )
