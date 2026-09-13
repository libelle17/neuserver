# -*- coding: utf-8 -*-
# Sucht in M-Net Posteingang+Archiv nach mutmasslichen Patienten-/Angehoerigen-Mails,
# deren Absender noch nicht in Medical Office hinterlegt ist. Schreibt Kandidaten
# ausschliesslich in eine lokale Datei - gibt auf der Konsole nur Zahlen aus,
# keine Patientendaten.
import re, sys, os, email, email.header, email.policy, email.utils, csv, hashlib
from datetime import timedelta, date, datetime
import pymysql

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mitarbeiter_filter import load_mitarbeiter_emails
import patient_addresses_db as padb
import mail_id_cache
# secure_pwd (Windows-DPAPI/win32crypt) bewusst NICHT hier auf Modul-Ebene
# importiert, sondern lokal in main() (siehe dort) - archive_patient_emails.py
# importiert einzelne Namen aus dieser Datei (und darueber wiederum
# poll_diabetologie_inbox.py), ohne main() je aufzurufen, und soll auf Linux
# lauffaehig bleiben koennen (siehe [[project-missing-patient-emails]]).

sys.stdout.reconfigure(encoding="utf-8", errors="replace", line_buffering=True)

# Passwort DPAPI-verschluesselt (siehe secure_pwd.py) - nur unter diesem
# Windows-Konto auf diesem PC entschluesselbar. Neu erstellen bei
# Passwort-/PC-/Kontowechsel: Datei mit neuem Klartext-Passwort
# ueberschreiben, dann "python migrate_pwd_to_dpapi.py" ausfuehren.
PWD_FILE = r"C:\Mail\Thunderbird\Profiles\medoff.pwd"
MNET_ROOT = r"C:\Mail\Thunderbird\Profiles\Schade\Mail\pop.mnet-online.de"
DOK_ROOT = r"P:\dok"
OUT_DIR = r"C:\Mail\Thunderbird\Profiles"

OWN_ACCOUNT_EMAILS = {
    "diabd_buch@gmx.de", "diabdachau@kv.dox.kim.telematik",
    "diabetologie@dachau-mail.de", "g.schade@gmx.de", "g1s@gmx.de",
    "g1s@gmx.net", "gerald.schade@freenet.de", "gerald.schade@gmail.com",
    "gerald.schade@gmx.de", "gerald.schade@web.de", "geraldschade@gmx.de",
    "geraldschade@web.de", "gerascha@gmx.de", "gs@aufwindfuerbayern.de",
    "libelle17@gmx.net", "schadegerald@gmail.com",
    "gschade@dachau-mail.de", "schade@dachau-mail.de", "netz@dachau-mail.de",
}
EXCLUDED_SUROGAT = {1022, 45964}  # Praxisinhaber/Kollege - oft im Text erwaehnt, keine Kandidaten

EXCLUDED_SPAM_SENDERS = {
    "un.ondispaatch@gmail.com", "follyjoesph0@gmail.com", "elinor300joseph@gmail.com",
    "tyuxd015@gmail.com", "sorosgeorgewww@gmail.com",
    "foodlover213@gmail.com", "mr.michaelchojones7@gmail.com",
    "abbdel@gmx.de", "abdur2000raheem@gmail.com", "aduval724@gmail.com", "ayimrsen@gmail.com",
    "jasminegardinier1994@outlook.com", "dj-ralf.zinnowitz@gmx.de",
    "stanislav_likhachyov693lo6@hotmail.com",
}

EXCLUDED_COLLEAGUE_SENDERS = {
    "aekd-wama@t-online.de", "arzt.karlsfeld@gmx.de",
}

# Bei mehr als so vielen Patienten mit demselben Nachnamen ist der reine
# Nachname-Fallback zu unspezifisch (z.B. haeufige Nachnamen, oder ein im
# Text vorkommendes Wort, das zufaellig ein Nachname ist) - dann lieber
# gar nichts vorschlagen als zu viel Rauschen erzeugen.
LASTNAME_FALLBACK_MAX = 4

# Ab so vielen VERSCHIEDENEN Absendern innerhalb CLUSTER_WINDOW_DAYS, die
# alle nur ueber reine Namensnennung (Abschnitt 0b, ohne Geburtsdatum/
# Telefonnummer im Text) auf denselben Patienten treffen, ist das eher eine
# Scam-/Phishing-Welle (Name z.B. aus einem Datenleck in generischem Text
# verwendet) als echte Korrespondenz - siehe [[project-missing-patient-emails]],
# Fall Patient 2146 (2026-09-09: 7 verschiedene Wegwerf-Adressen binnen 8
# Wochen). Wird als eigener Abschnitt 11 ausgewiesen, nicht verworfen.
CLUSTER_MIN_ADDRESSES = 4
CLUSTER_WINDOW_DAYS = 90

AUTOMATED_LOCAL_PARTS = {
    "postmaster", "mailer-daemon", "mail-daemon", "mailerdaemon", "bounce",
    "bounces", "delivery-notification", "delivery-notifications", "automated",
    "no-reply", "noreply", "auto-reply", "autoreply", "notification",
    "notifications", "system", "abuse", "root",
}


def is_automated_sender(addr):
    local = addr.split("@", 1)[0].lower()
    return local in AUTOMATED_LOCAL_PARTS

STUDY_RECRUITMENT_PATTERNS = [
    re.compile(r"GHR\s*Ref", re.IGNORECASE),
    re.compile(r"€\s*\d+\s*/\s*\d+\s*minuten", re.IGNORECASE),
    re.compile(r"\bOnline-Studie\b", re.IGNORECASE),
    re.compile(r"\bStudienlage\b", re.IGNORECASE),
    # Bewerbungen/Verwaltungskram: unabhaengig von zufaelligen Namenstreffern
    # im Text (z.B. eine im Lebenslauf genannte Referenzperson) nie einer
    # Patientin/einem Patienten zuordnen.
    re.compile(r"\bBewerbung(en)?\b", re.IGNORECASE),
    re.compile(r"\bBewerbungsunterlagen\b", re.IGNORECASE),
    re.compile(r"\bLebenslauf\b", re.IGNORECASE),
    re.compile(r"\bStellenausschreibung\b", re.IGNORECASE),
    re.compile(r"\bStellenanzeige\b", re.IGNORECASE),
    re.compile(r"\bStellenangebot\b", re.IGNORECASE),
    re.compile(r"\bTonerbestellung\b", re.IGNORECASE),
    re.compile(r"\bWeiterbildung\b", re.IGNORECASE),
]

EXCLUDED_SUBJECTS_SUBSTR = [
    "CD-Brenner",
    "Überprüfung einer Rezension auf Ihrem Unternehmensprofil",
    "Herr Dr. Kothny Bitte um Mitarbeit und Link zu Online-Studie",
    "Endokrinologische Forschung",
    "Ernährungsstudie",
    "Hypoparathyreoidismusforschung",
    "Film und Party",
    "Suche Praxisraum",
    "Bogenhausener Diabetologen Treffen",
    "Der neue Katzenkalender ist da",
    "Neues von T2med, Fertigstellung",
]


def is_excluded_subject(subject):
    if not subject:
        return False
    for pat in STUDY_RECRUITMENT_PATTERNS:
        if pat.search(subject):
            return True
    for s in EXCLUDED_SUBJECTS_SUBSTR:
        if s in subject:
            return True
    return False

PERSONAL_DOMAINS = {
    "gmx.de", "gmx.net", "gmx.at", "gmx.ch", "gmx.info", "gmx.com",
    "web.de", "gmail.com", "googlemail.com", "t-online.de", "icloud.com",
    "me.com", "mac.com", "yahoo.de", "yahoo.com", "hotmail.de", "hotmail.com",
    "outlook.de", "outlook.com", "live.de", "live.com", "freenet.de",
    "arcor.de", "aol.com", "mail.de", "posteo.de", "vodafonemail.de",
    "o2online.de", "1und1.de", "1und1.net", "kabelmail.de", "onlinehome.de",
}

# Apotheken-Absender: im Lokalteil (vor dem "@") kommt "apo" vor, direkt
# gefolgt von entweder nichts mehr (Ende des Lokalteils), einem Nicht-
# Buchstaben (z.B. "-", ".", "_", eine Ziffer) oder der Buchstabenfolge "th"
# (z.B. "apo-dachau@", "apotheke.stadt@", "stadtapo@" - aber nicht "apollo@").
APOTHEKE_LOCAL_RE = re.compile(r"apo(?:$|[^a-z]|th)", re.IGNORECASE)

# Weitere, noch nicht in earzt/epraxis/patrelation dokumentierte Praxen/
# Pflegedienste/Heime - anhand verdaechtiger Woerter im Lokalteil oder
# Anzeigenamen vermutet, muss vor Weiterverarbeitung von Hand in Medical
# Office dokumentiert werden.
INSTITUTION_KEYWORD_RE = re.compile(r"(praxis|pflege|heim|dienst)", re.IGNORECASE)

EMAIL_RE = re.compile(r"^[^@\s,;/]+@[^@\s,;/]+\.[^@\s,;/]+$")
SPLIT_RE = re.compile(r"\s*(?:,|;|/|\boder\b|\bund\b)\s*", re.IGNORECASE)
TITLE_WORDS = {"dr", "dr.", "prof", "prof.", "med", "med.", "univ", "univ.", "dipl", "dipl."}


def normalize_word(w):
    w = (w or "").lower()
    w = w.replace("ä", "ae").replace("ö", "oe").replace("ü", "ue").replace("ß", "ss")
    w = re.sub(r"[^a-z-]", "", w)
    return w


def normalize_text(s):
    s = (s or "").lower()
    s = s.replace("ä", "ae").replace("ö", "oe").replace("ü", "ue").replace("ß", "ss")
    return s


def normalize_name_parts(raw):
    raw = raw.strip().strip('"')
    raw = re.sub(r"\(.*?\)", "", raw)
    parts = re.split(r"[,\s]+", raw)
    parts = [normalize_word(p) for p in parts if p]
    parts = [p for p in parts if p and p not in TITLE_WORDS]
    return parts


def split_emails(raw):
    if not raw:
        return []
    parts = [p.strip().lower() for p in SPLIT_RE.split(raw)]
    return [p for p in parts if EMAIL_RE.match(p)]


def decode_header_val(raw):
    try:
        parts = email.header.decode_header(raw)
        return "".join(t.decode(e or "utf-8", "replace") if isinstance(t, bytes) else t for t, e in parts)
    except Exception:
        return raw


def parse_from_header(raw):
    raw = decode_header_val(raw)
    m = re.match(r"^\s*(.*?)\s*<([^<>]+)>\s*$", raw)
    if m:
        name, addr = m.group(1), m.group(2)
    else:
        name, addr = "", raw
    name = name.strip().strip('"')
    addr = addr.strip().lower()
    return name, addr


MESSAGE_ID_RE = re.compile(rb"\nMessage-ID:\s*([^\r\n]*)", re.IGNORECASE)


def extract_message_id(raw):
    """Liest den Message-ID-Header direkt aus den Rohbytes (case-insensitiv,
    da hier - anders als From/Date/Subject - keine feste Gross-/
    Kleinschreibung vorausgesetzt werden soll)."""
    m = MESSAGE_ID_RE.search(b"\n" + raw)
    if not m:
        return ""
    return m.group(1).strip().decode("utf-8", "replace")


def iter_headers(path):
    try:
        f = open(path, "rb")
    except FileNotFoundError:
        return
    with f:
        first = f.readline()
        while first in (b"\n", b"\r\n"):
            first = f.readline()
        if not first.startswith(b"From "):
            return
        headers = {}
        last_key = None
        in_headers = True
        line = first
        started = True
        while True:
            if not started:
                line = f.readline()
                if not line:
                    break
            started = False
            if in_headers:
                if line in (b"\n", b"\r\n"):
                    in_headers = False
                    yield headers
                    headers = {}
                    last_key = None
                    continue
                if line[0:1] in (b" ", b"\t") and last_key:
                    headers[last_key] = headers.get(last_key, b"") + b" " + line.strip()
                elif b":" in line:
                    k, v = line.split(b":", 1)
                    k = k.strip().lower()
                    v = v.strip()
                    headers[k] = v
                    last_key = k
                else:
                    last_key = None
            else:
                if line.startswith(b"From "):
                    in_headers = True
                    continue


def iter_full_messages(path):
    try:
        f = open(path, "rb")
    except FileNotFoundError:
        return
    with f:
        first = f.readline()
        while first in (b"\n", b"\r\n"):
            first = f.readline()
        if not first.startswith(b"From "):
            return
        buf = bytearray(first)
        prev_blank = False
        line = f.readline()
        while line:
            if line.startswith(b"From ") and prev_blank:
                yield bytes(buf)
                buf = bytearray(line)
                prev_blank = False
                line = f.readline()
                continue
            buf.extend(line)
            prev_blank = (line in (b"\n", b"\r\n"))
            line = f.readline()
        if buf:
            yield bytes(buf)


def parse_message_bits(raw_bytes, body_limit=3000):
    """Liefert (body_text, [(filename, size), ...]) einer Nachricht."""
    try:
        msg = email.message_from_bytes(raw_bytes, policy=email.policy.compat32)
    except Exception:
        return "", []
    text_parts = []
    attachments = []
    try:
        if msg.is_multipart():
            for part in msg.walk():
                ctype = part.get_content_type()
                disp = str(part.get("Content-Disposition", ""))
                fname = part.get_filename()
                if fname:
                    fname = decode_header_val(fname)
                    payload = part.get_payload(decode=True)
                    size = len(payload) if payload else 0
                    digest = hashlib.sha256(payload).hexdigest() if payload else None
                    attachments.append((fname, size, digest))
                elif ctype == "text/plain" and sum(len(t) for t in text_parts) <= body_limit:
                    payload = part.get_payload(decode=True)
                    if payload:
                        charset = part.get_content_charset() or "utf-8"
                        text_parts.append(payload.decode(charset, "replace"))
        else:
            payload = msg.get_payload(decode=True)
            if payload:
                charset = msg.get_content_charset() or "utf-8"
                text_parts.append(payload.decode(charset, "replace"))
    except Exception:
        pass
    combined = " ".join(text_parts)
    combined = re.sub(r"<[^>]+>", " ", combined)
    return combined[:body_limit], attachments


def build_dok_index(root):
    """Groesse (Bytes) -> [(patient_nr, pfad, mtime), ...].
    Beim Abspeichern in P:\\dok wird der Dateiname regelmaessig geaendert
    (Patientenname vorangestellt u.a.), daher ist der Dateiname als
    Schluessel nicht verlaesslich - stattdessen wird spaeter per Datei-
    groesse vorgefiltert und dann der tatsaechliche Inhalt gehasht."""
    index = {}
    total = 0
    try:
        entries = os.listdir(root)
    except OSError:
        return index, total
    for d in entries:
        p = os.path.join(root, d)
        if not os.path.isdir(p):
            continue
        if not d.isdigit():
            continue
        try:
            for dirpath, dirnames, filenames in os.walk(p):
                for fn in filenames:
                    fp = os.path.join(dirpath, fn)
                    try:
                        st = os.stat(fp)
                    except OSError:
                        continue
                    index.setdefault(st.st_size, []).append((d, fp, st.st_mtime))
                    total += 1
        except OSError:
            continue
    return index, total


def hash_file(path, cache):
    if path in cache:
        return cache[path]
    h = hashlib.sha256()
    try:
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(1 << 20), b""):
                h.update(chunk)
        digest = h.hexdigest()
    except OSError:
        digest = None
    cache[path] = digest
    return digest


DOB_PATTERNS_CACHE = {}

def dob_regexes(yyyymmdd):
    if not yyyymmdd or len(yyyymmdd) != 8 or not yyyymmdd.isdigit():
        return []
    if yyyymmdd in DOB_PATTERNS_CACHE:
        return DOB_PATTERNS_CACHE[yyyymmdd]
    y, m, d = yyyymmdd[0:4], yyyymmdd[4:6], yyyymmdd[6:8]
    yy = y[2:]
    d_ = str(int(d))
    m_ = str(int(m))
    variants = {
        f"{d}.{m}.{y}", f"{d_}.{m_}.{y}", f"{d}.{m}.{yy}", f"{d_}.{m_}.{yy}",
        f"{y}-{m}-{d}", f"{d}/{m}/{y}", f"{d_}.{m_}.{yy}",
    }
    DOB_PATTERNS_CACHE[yyyymmdd] = list(variants)
    return DOB_PATTERNS_CACHE[yyyymmdd]


def dob_in_text(yyyymmdd, text):
    for v in dob_regexes(yyyymmdd):
        if v in text:
            return True
    return False


PHONE_FIELDS = ("FTelefonprivat", "FTelefonmobil", "FTelefondienst")
PHONE_TAIL_LEN = 8


def phone_tails_of_patient(row):
    """Liefert die Menge der letzten PHONE_TAIL_LEN Ziffern jeder in MO
    hinterlegten Telefonnummer des Patienten (Landesvorwahl-/Formatierungs-
    unabhaengiger Vergleich - 0163... und +49163... liefern denselben
    Tail)."""
    tails = set()
    for field in PHONE_FIELDS:
        digits = re.sub(r"\D", "", row.get(field) or "")
        if len(digits) >= PHONE_TAIL_LEN:
            tails.add(digits[-PHONE_TAIL_LEN:])
    return tails


PHONE_CANDIDATE_RE = re.compile(r"\+?\d[\d \-/()]{5,}\d")


def phone_tails_in_text(text):
    """Findet zusammenhaengende, telefonnummernartige Ziffernfolgen im Text
    und liefert deren letzte PHONE_TAIL_LEN Ziffern als Menge."""
    tails = set()
    for m in PHONE_CANDIDATE_RE.findall(text):
        digits = re.sub(r"\D", "", m)
        if len(digits) >= PHONE_TAIL_LEN:
            tails.add(digits[-PHONE_TAIL_LEN:])
    return tails


def dob_year_in_local_part(yyyymmdd, addr):
    """Prueft, ob das Geburtsjahr als 4-stellige Zahl im Lokalteil (vor dem @)
    der Email-Adresse vorkommt, z.B. 'mmustermann1985@gmail.com'."""
    if not yyyymmdd or len(yyyymmdd) != 8 or not yyyymmdd.isdigit():
        return False
    year = yyyymmdd[0:4]
    local = addr.split("@", 1)[0]
    return year in re.findall(r"\d+", local)


def edit_distance(a, b, max_d=3):
    """Einfache Levenshtein-Distanz, bricht ab wenn max_d sicher ueberschritten ist."""
    if abs(len(a) - len(b)) > max_d:
        return max_d + 1
    if a == b:
        return 0
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        cur = [i] + [0] * len(b)
        for j, cb in enumerate(b, 1):
            cost = 0 if ca == cb else 1
            cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost)
        prev = cur
    return prev[len(b)]


def find_typo_match(candidate_email, stored_emails):
    """Liefert die gespeicherte Adresse, wenn sie sich von candidate_email nur
    um 1-2 Zeichen unterscheidet (vermutlich Tippfehler), sonst None."""
    for stored in stored_emails:
        if stored == candidate_email:
            continue
        d = edit_distance(stored, candidate_email, max_d=2)
        if d <= 2:
            return stored
    return None


RELATIONSHIP_WORDS = {
    normalize_word(w) for w in [
        "Mutter", "Vater", "Sohn", "Tochter", "Onkel", "Tante",
        "Schwiegermutter", "Schwiegervater", "Bruder", "Schwester",
        "Ehefrau", "Ehemann", "Gatte", "Gattin", "Schwager", "Schwaegerin",
    ]
}


def find_relationship_mentions(text, name_index):
    """Sucht Beziehungswoerter (Mutter, Vater, ...) gefolgt von einem bekannten
    Vor+Nachname im Text. Liefert Liste von (beziehungswort, surogat)."""
    words = re.findall(r"[a-z-]+", text)
    results = []
    for i, w in enumerate(words):
        if w not in RELATIONSHIP_WORDS:
            continue
        if i + 2 < len(words):
            a, b = words[i + 1], words[i + 2]
            if (a, b) in name_index:
                for s in name_index[(a, b)]:
                    results.append((w, s))
            if (b, a) in name_index:
                for s in name_index[(b, a)]:
                    results.append((w, s))
    return results


def find_names_in_text(text, name_index):
    """Durchsucht den normalisierten Text nach JEDER bekannten Vor+Nachname-
    Kombination (in beiden Wortreihenfolgen), unabhaengig vom Absender-
    Anzeigenamen. Liefert die Menge der so gefundenen Patientennummern.

    Neben einzelnen Woertern werden auch je zwei benachbarte Woerter
    zusammengefuegt als Kandidat geprüft - so wird z.B. "Miller Schmidt"
    im Text noch als Treffer fuer den in MO mit Bindestrich gespeicherten
    Namen "Miller-Schmidt" erkannt (der Bindestrich wird beim Schreiben
    einer Mail haeufig durch ein Leerzeichen ersetzt oder ganz weggelassen)."""
    words = re.findall(r"[a-z-]+", text)
    n = len(words)
    spans = []
    for i in range(n):
        if len(words[i]) >= 2:
            spans.append((i, i + 1, words[i]))
        if i + 1 < n:
            joined = words[i] + words[i + 1]
            if len(joined) >= 2:
                spans.append((i, i + 2, joined))
    found = set()
    for s1 in spans:
        for s2 in spans:
            if s2[0] != s1[1]:
                continue
            a, b = s1[2], s2[2]
            if (a, b) in name_index:
                found.update(name_index[(a, b)])
            if (b, a) in name_index:
                found.update(name_index[(b, a)])
    return found


def split_scam_clusters(rows_content):
    """Erkennt je Patient Haeufungen von >= CLUSTER_MIN_ADDRESSES verschiedenen
    Absendern innerhalb eines CLUSTER_WINDOW_DAYS-Fensters, bei denen NUR die
    reine Namensnennung vorliegt (kein Geburtsdatum/keine Telefonnummer im
    Text) - typisches Muster einer Scam-/Phishing-Welle. Verschiebt
    betroffene Zeilen aus rows_content in eine eigene Rueckgabeliste - keine
    Zeile wird verworfen, nur gesondert ausgewiesen (Abschnitt 11)."""
    by_surogat = {}
    for i, e in enumerate(rows_content):
        by_surogat.setdefault(e["surogat"], []).append(i)

    cluster_idx = set()
    for surogat, idxs in by_surogat.items():
        weak = [i for i in idxs
                if "Geburtsdatum" not in rows_content[i]["kind"]
                and "Telefonnummer" not in rows_content[i]["kind"]]
        dated = []
        for i in weak:
            d = rows_content[i].get("maildatum") or ""
            try:
                dd = datetime.strptime(d[:10], "%Y-%m-%d").date()
            except ValueError:
                continue
            dated.append((i, dd))
        dated.sort(key=lambda x: x[1])
        n = len(dated)
        for a in range(n):
            cnt = 1
            for b in range(a + 1, n):
                if (dated[b][1] - dated[a][1]).days <= CLUSTER_WINDOW_DAYS:
                    cnt += 1
                else:
                    break
            if cnt >= CLUSTER_MIN_ADDRESSES:
                for k in range(a, a + cnt):
                    cluster_idx.add(dated[k][0])

    kept = [e for i, e in enumerate(rows_content) if i not in cluster_idx]
    moved = [e for i, e in enumerate(rows_content) if i in cluster_idx]
    return kept, moved


def main():
    import secure_pwd
    password = secure_pwd.read_protected_password(PWD_FILE)

    conn = pymysql.connect(host="wser", port=2020, user="medoff", password=password,
                            database="medoff", connect_timeout=10,
                            cursorclass=pymysql.cursors.DictCursor)
    cur = conn.cursor()
    excluded_list = ",".join(str(p) for p in EXCLUDED_SUROGAT)
    cur.execute(f"SELECT FSurogat, FVorname, FNachname, FGeburtsdatum, FEmail, "
                f"FTelefonprivat, FTelefonmobil, FTelefondienst FROM patstamm "
                f"WHERE FSurogat NOT IN ({excluded_list})")
    patients = cur.fetchall()

    mitarbeiter_emails = load_mitarbeiter_emails()
    # Patienten, deren eigene medoff-Email-Adresse auf der Mitarbeiterliste
    # steht (z.B. eine ehemalige Mitarbeiterin, die auch Patientin ist):
    # komplett von der Namens-/Inhaltssuche ausschliessen. Sonst wuerden
    # voellig unbeteiligte Absender (die diese Person z.B. im Rahmen einer
    # Veranstaltung erwaehnen) faelschlich als "das ist ihre Email-Adresse"
    # vorgeschlagen.
    patients = [p for p in patients
                if not (set(split_emails(p["FEmail"])) & mitarbeiter_emails)]

    cur.execute("SELECT FPatid, FReferenzid FROM patrelation")
    existing_relations = set()
    for row in cur.fetchall():
        a, b = row["FPatid"], row["FReferenzid"]
        if a is not None and b is not None:
            existing_relations.add(frozenset((a, b)))

    # Sonderpatienten (Sammel-/Pseudopatienten, siehe Lese5.frm ->
    # SonderpatientenAnzeigen_Click): keine echten Personen, ihre Treffer
    # werden daher nicht in den normalen Abschnitten, sondern wie Praxis-/
    # Pflegedienst-Treffer in Abschnitt 9 gefuehrt.
    cur.execute(
        "SELECT FSurogat FROM patstamm WHERE FNachname LIKE 'zutun%%' "
        "OR (FStrasse LIKE 'mittermayer%%' AND FHausnr LIKE '13%%' "
        "AND FNachname NOT REGEXP %s)",
        ("|".join(["Kreitmeier", "Mauck", "Steinert"]),)
    )
    sonderpatient_surogate = {row["FSurogat"] for row in cur.fetchall()}

    # Bekannte Arztpraxen/Pflegedienste/Heime/Abholdienste - werden nie als
    # Patienten-eigene Adresse vorgeschlagen, sondern (bei inhaltlichem
    # Patientenbezug je Nachricht) in Abschnitt 9 gefuehrt.
    institutional_known_emails = set()
    cur.execute("SELECT FEmail FROM earzt WHERE FEmail IS NOT NULL AND TRIM(FEmail) <> ''")
    institutional_known_emails |= {r["FEmail"].strip().lower() for r in cur.fetchall()}
    cur.execute("SELECT FEmail FROM epraxis WHERE FEmail IS NOT NULL AND TRIM(FEmail) <> ''")
    institutional_known_emails |= {r["FEmail"].strip().lower() for r in cur.fetchall()}
    cur.execute("SELECT FData FROM patrelation WHERE FReferenztyp IN (0,5) AND FData LIKE '%(Email %'")
    fdata_re = re.compile(r'\(Email\s+"([^"]*)"\)')
    for r in cur.fetchall():
        m = fdata_re.search(r["FData"] or "")
        if m and m.group(1).strip():
            institutional_known_emails.add(m.group(1).strip().lower())

    # Datum des letzten Behandlungsfalls je Patient - hilft bei der
    # Plausibilitaetspruefung (eine aktuelle Mail zu einem seit Jahren
    # inaktiven Patienten ist unwahrscheinlicher als zu einem aktiven).
    cur.execute("SELECT FPatnr, DATE_ADD('1890-01-01', INTERVAL MAX(FBis) DAY) AS letzter "
                "FROM patfall WHERE FBis > 0 GROUP BY FPatnr")
    last_fall = {row["FPatnr"]: row["letzter"] for row in cur.fetchall()}

    # Alle einzelnen Fall-Zeitraeume je Patient (fuer die +/-3-Monats-
    # Plausibilitaetspruefung bei Mehrdeutigkeit).
    cur.execute("SELECT FPatnr, DATE_ADD('1890-01-01', INTERVAL FVon DAY) AS von, "
                "DATE_ADD('1890-01-01', INTERVAL FBis DAY) AS bis FROM patfall "
                "WHERE FVon > 0 AND FBis > 0")
    fall_ranges = {}
    for row in cur.fetchall():
        fall_ranges.setdefault(row["FPatnr"], []).append((row["von"], row["bis"]))
    conn.close()

    known_emails = set()
    name_index = {}
    lastname_index = {}
    info_by_surogat = {}
    for p in patients:
        surogat = p["FSurogat"]
        vor = normalize_word(p["FVorname"] or "")
        nach = normalize_word(p["FNachname"] or "")
        emails = split_emails(p["FEmail"])
        known_emails.update(emails)
        info_by_surogat[surogat] = {
            "vorname": (p["FVorname"] or "").strip(),
            "nachname": (p["FNachname"] or "").strip(),
            "vorname_norm": vor,
            "nachname_norm": nach,
            "geburtsdatum": (p["FGeburtsdatum"] or "").strip(),
            "emails": emails,
            "letzter_fall": last_fall.get(surogat),
            "phone_tails": phone_tails_of_patient(p),
            "fall_ranges": fall_ranges.get(surogat, []),
        }
        if nach:
            lastname_index.setdefault(nach, []).append(surogat)
            if vor:
                name_index.setdefault((nach, vor), []).append(surogat)
                # Bindestrich-unempfindliche Zusatzeintraege (z.B. "anna-maria"
                # vs. "annamaria"), damit Schreibweise-Abweichungen nicht zum
                # Verfehlen des Treffers fuehren.
                vor_nh = vor.replace("-", "")
                nach_nh = nach.replace("-", "")
                if vor_nh != vor:
                    name_index.setdefault((nach, vor_nh), []).append(surogat)
                if nach_nh != nach:
                    name_index.setdefault((nach_nh, vor), []).append(surogat)
                if vor_nh != vor and nach_nh != nach:
                    name_index.setdefault((nach_nh, vor_nh), []).append(surogat)

    known_emails |= OWN_ACCOUNT_EMAILS

    # Jede jemals bestaetigte Adresse (jede Rolle: aktuelle Hauptadresse,
    # verdraengte alte Hauptadresse, weitere Nebenadresse) aus quelle.
    # pat_email_adr - verhindert, dass eine einmal gepruefte und dann durch
    # eine neuere ersetzte Adresse beim naechsten Lauf wieder als "neuer"
    # Kandidat auftaucht (siehe [[project-missing-patient-emails]], Fall
    # Patient 54171 am 2026-09-08). Braucht die quelle-DB - dieses Skript
    # muss deshalb ueber PowerShell laufen, nicht Bash (UNC-Passwortpfad).
    padb_conn = padb.connect()
    known_emails |= padb.all_known_emails(padb_conn)
    padb_conn.close()

    print("Baue P:\\dok Dateiindex auf...")
    dok_index, dok_file_count = build_dok_index(DOK_ROOT)
    dok_hash_cache = {}
    print(f"P:\\dok Index: {dok_file_count} Dateien, {len(dok_index)} unterschiedliche Dateigroessen")

    sources = [f"{MNET_ROOT}\\Inbox", f"{MNET_ROOT}\\Archiv"]

    # --- Pass 1: Header-only - Absenderkandidaten (persoenliche Domain, nicht bekannt) ---
    candidate_senders = {}  # addr -> {"names": set(), "subject": first_subject}
    all_seen_emails = set()
    institutional_addr_info = {}  # addr -> {"confirmed": bool, "name": str}

    n_msgs = 0
    for src in sources:
        for headers in iter_headers(src):
            n_msgs += 1
            if n_msgs % 10000 == 0:
                print(f"  ... Pass 1: {n_msgs} Nachrichten gescannt")
            from_raw = headers.get(b"from", b"").decode("utf-8", "replace")
            if not from_raw:
                continue
            name, addr = parse_from_header(from_raw)
            if not addr or "@" not in addr:
                continue
            all_seen_emails.add(addr)
            if (addr in known_emails or addr in EXCLUDED_SPAM_SENDERS or
                    addr in EXCLUDED_COLLEAGUE_SENDERS or addr in mitarbeiter_emails or
                    is_automated_sender(addr)):
                continue

            local = addr.split("@", 1)[0]
            is_confirmed_inst = addr in institutional_known_emails or bool(APOTHEKE_LOCAL_RE.search(local))
            is_suspected_inst = (not is_confirmed_inst) and bool(
                INSTITUTION_KEYWORD_RE.search(local) or INSTITUTION_KEYWORD_RE.search(name or "")
            )
            if is_confirmed_inst or is_suspected_inst:
                info = institutional_addr_info.setdefault(addr, {"confirmed": False, "name": name or ""})
                info["confirmed"] = info["confirmed"] or is_confirmed_inst
                continue  # nicht zusaetzlich als normaler (Patienten-eigene-Adresse-)Kandidat pruefen

            domain = addr.rsplit("@", 1)[-1]
            if domain not in PERSONAL_DOMAINS:
                continue
            entry = candidate_senders.setdefault(addr, {"names": set(), "subject": None, "subjects": []})
            if name:
                entry["names"].add(name)
            subj = decode_header_val(headers.get(b"subject", b"").decode("utf-8", "replace")).strip()
            if subj:
                entry["subjects"].append(subj)
            if entry["subject"] is None:
                entry["subject"] = subj

    print(f"Kandidaten-Absenderadressen (persoenliche Domain, unbekannt): {len(candidate_senders)}")
    print(f"Kandidaten-Absenderadressen (Praxis/Pflegedienst/Apotheke, bestaetigt oder vermutet): {len(institutional_addr_info)}")

    # --- Pass 2: Fuer jeden Kandidaten ALLE Nachrichten einsammeln: Body + Anhaenge ---
    needed = set(candidate_senders.keys())
    institutional_needed = set(institutional_addr_info.keys())
    bodies = {}       # addr -> [body, ...] ueber ALLE Nachrichten dieser Adresse
    attachments = {}  # addr -> [(filename, size, hash, msg_date), ...] ueber alle Nachrichten
    msg_dates = {}    # addr -> [Nachrichtendatum, ...] ueber alle Nachrichten dieser Adresse
    institutional_messages = []  # je EINZELNE Nachricht (nicht ueber Adresse aggregiert)

    # Persistenter Body+Anhang-Cache (emails.mail_content_cache) - das volle
    # MIME-Parsen (inkl. Anhang-Hashing) ist der teure Teil von Pass 2 und
    # eine reine Funktion des unveraenderlichen Nachrichteninhalts, daher
    # unbegrenzt wiederverwendbar - Zuordnung/Ausschlusskriterien werden
    # trotzdem bei jedem Lauf neu (in Pass 1) gegen den aktuellen Stand
    # geprueft, hier wird nur die teure Extraktion selbst gespart.
    content_cache_conn = mail_id_cache.connect()
    content_cache = mail_id_cache.load_content_cache(content_cache_conn)
    print(f"Bekannte analysierte Nachrichten (Cache): {len(content_cache)}")
    generic_attachment_hashes = mail_id_cache.load_generic_attachment_hashes(content_cache_conn)
    print(f"Bekannte generische Anhaenge (Ausschlussliste): {len(generic_attachment_hashes)}")
    new_content_rows = []
    n_pass2 = 0

    def flush_content_cache():
        if new_content_rows:
            mail_id_cache.insert_content_batch(content_cache_conn, new_content_rows)
            new_content_rows.clear()

    for src in sources:
        for raw in iter_full_messages(src):
            idx = raw.find(b"\nFrom:")
            if idx == -1:
                continue
            end = raw.find(b"\n", idx + 1)
            from_line = raw[idx + 1:end if end != -1 else None]
            try:
                _, addr = parse_from_header(from_line.split(b":", 1)[1].decode("utf-8", "replace"))
            except Exception:
                continue
            is_normal = addr in needed
            is_inst = addr in institutional_needed
            if not is_normal and not is_inst:
                continue

            n_pass2 += 1
            if n_pass2 % 5000 == 0:
                print(f"  ... {n_pass2} Kandidaten-Nachrichten analysiert")
                flush_content_cache()

            message_id = extract_message_id(raw)
            if message_id and message_id in content_cache:
                body, atts = content_cache[message_id]
            else:
                body, atts = parse_message_bits(raw)
                if message_id:
                    new_content_rows.append((message_id, body, atts))
                    content_cache[message_id] = (body, atts)

            msg_date = None
            didx = raw.find(b"\nDate:")
            if didx != -1:
                dend = raw.find(b"\n", didx + 1)
                try:
                    date_raw = raw[didx + 1:dend].split(b":", 1)[1].strip().decode("utf-8", "replace")
                    msg_date = email.utils.parsedate_to_datetime(date_raw)
                    if msg_date is not None and msg_date.tzinfo is None:
                        # Manche Date-Header ohne Zeitzone - als lokale Zeit
                        # interpretieren, damit spaeter alle Zeitstempel
                        # (zeitzonenbewusst) vergleichbar sind (sonst TypeError
                        # bei max() zwischen naiven und bewussten datetimes).
                        msg_date = msg_date.astimezone()
                except Exception:
                    msg_date = None

            if is_normal:
                bodies.setdefault(addr, []).append(body)
                if msg_date is not None:
                    msg_dates.setdefault(addr, []).append(msg_date)
                if atts:
                    attachments.setdefault(addr, []).extend(
                        (fn, sz, dg, msg_date) for fn, sz, dg in atts
                    )

            if is_inst:
                subj = ""
                sidx = raw.find(b"\nSubject:")
                if sidx != -1:
                    send_ = raw.find(b"\n", sidx + 1)
                    try:
                        subj_raw = raw[sidx + 1:send_ if send_ != -1 else None].split(b":", 1)[1].strip()
                        subj = decode_header_val(subj_raw.decode("utf-8", "replace"))
                    except Exception:
                        subj = ""
                institutional_messages.append({
                    "addr": addr, "subject": subj, "body": body, "atts": atts, "date": msg_date,
                    "confirmed": institutional_addr_info[addr]["confirmed"],
                })

    flush_content_cache()
    content_cache_conn.close()
    print("Anhang- und Textanalyse abgeschlossen.")

    def email_status(info):
        current_emails = info["emails"]
        if not current_emails:
            return "leer", True
        if any(e in all_seen_emails for e in current_emails):
            return "aktiv genutzt", False
        return "vorhanden aber unbenutzt: " + "; ".join(current_emails), True

    def attachment_match(addr):
        """Vergleicht den Anhang per Inhalts-Hash (nicht Dateinamen, da dieser
        beim Ablegen in P:\\dok haeufig geaendert wird) gegen alle P:\\dok-
        Dateien derselben Groesse. Als Plausibilitaetspruefung wird verlangt,
        dass die Datei nicht deutlich vor der Email angelegt/geaendert wurde
        (1 Tag Toleranz fuer Zeitzonen/Rundung).

        Gibt (surogat, msg_dates) zurueck, wobei msg_dates die Menge der
        unterschiedlichen Nachrichtendaten ist, aus denen ein passender
        Anhang stammt (Naeherung fuer "Anzahl unabhaengiger Nachrichten mit
        diesem Signal", da Anhaenge selbst keine Message-ID hier tragen) -
        sonst (None, set())."""
        cand = {}
        cand_dates = {}
        for fname, size, digest, msg_date in attachments.get(addr, []):
            if not digest:
                continue
            if digest in generic_attachment_hashes:
                # Bekannter generischer Anhang (z.B. eine Produktbroschuere,
                # die routinemaessig an mehrere Patienten verschickt wird) -
                # zaehlt nicht als Beweis fuer die Identitaet, selbst wenn
                # aktuell nur bei einem Patienten eine Datei mit diesem Hash
                # archiviert ist (siehe mail_id_cache.generic_attachment_hashes).
                continue
            email_ts = None
            if msg_date is not None:
                try:
                    email_ts = msg_date.timestamp()
                except (OverflowError, OSError, ValueError):
                    email_ts = None
            for patient_nr, path, mtime in dok_index.get(size, []):
                if hash_file(path, dok_hash_cache) != digest:
                    continue
                if email_ts is not None and mtime < email_ts - 86400:
                    continue
                if not patient_nr.isdigit():
                    continue
                s = int(patient_nr)
                cand[s] = cand.get(s, 0) + 1
                cand_dates.setdefault(s, set()).add(msg_date)
        if len(cand) == 1:
            s = next(iter(cand))
            return s, cand_dates[s]
        return None, set()

    def count_messages_with_name(addr, surogat):
        """Naeherung fuer 'Anzahl unabhaengiger Nachrichten dieser Adresse, die
        den Namen von surogat im Betreff ODER im Body nennen' - zaehlt beide
        Kanaele getrennt (Betreff-Liste und Body-Liste sind nicht
        garantiert index-gleich, da in getrennten Durchlaeufen befuellt) und
        nimmt das Maximum, statt eine exakte Paarung zu unterstellen."""
        n_subj = sum(1 for s in candidate_senders.get(addr, {}).get("subjects", [])
                      if surogat in find_names_in_text(normalize_text(s), name_index))
        n_body = sum(1 for b in bodies.get(addr, [])
                     if surogat in find_names_in_text(normalize_text(b), name_index))
        return max(n_subj, n_body)

    rows_attach = []       # per Anhang eindeutig identifiziert
    rows_content = []      # per Namensnennung im Inhalt eindeutig identifiziert
    rows_conflict = []     # Anhang/Inhalt und Anzeigename widersprechen sich
    rows_typo = []         # gefundene Adresse aehnelt stark einer hinterlegten (vermutl. Tippfehler)
    rows_relations = []    # im Text erwaehnte, noch nicht dokumentierte Beziehung
    unique_confirmed = {}
    ambiguous_by_addr = {}  # addr -> {"subject":..., "candidates": [(surogat, kind, status), ...]}
    rows_dropped_unconfirmed = []
    rows_dropped_multi = []
    n_dropped_unconfirmed = 0
    n_dropped_multi_conflict = 0

    def record_dropped(bucket, addr, subject, surogats, reason):
        nrs = ", ".join(str(s) for s in sorted(surogats)) if surogats else ""
        bucket.append({"addr": addr, "subject": subject, "surogats": nrs, "reason": reason})

    def check_relations(surogat, addr, combined, subject):
        for word, other_surogat in find_relationship_mentions(combined, name_index):
            if other_surogat == surogat:
                continue
            if frozenset((surogat, other_surogat)) in existing_relations:
                continue
            rows_relations.append({
                "primary": surogat, "other": other_surogat, "word": word,
                "email": addr, "subject": subject,
            })

    def check_typo(surogat, addr):
        info = info_by_surogat[surogat]
        return find_typo_match(addr, info["emails"])

    def resolve_nickname_group(surogats):
        """Wenn alle uebergebenen Patienten denselben Nachnamen tragen und
        ihre Vornamen paarweise in einer Praefix-Beziehung stehen (z.B.
        'Alex' vs. 'Alexander'), wird der Patient mit dem LAENGSTEN Vornamen
        zurueckgegeben - Menschen kuerzen im Schriftverkehr eher ab, als
        einen Namen willkuerlich zu verlaengern. Als Gegenprobe: wird ein
        Kandidat mit kuerzerem Vornamen deutlich AKTIVER (juengerer letzter
        Behandlungsfall) gefuehrt als der mit dem laengsten Vornamen, ist die
        Heuristik hier nicht verlaesslich - dann wird None zurueckgegeben."""
        if len(surogats) < 2:
            return None
        infos = [info_by_surogat[s] for s in surogats]
        if len({i["nachname_norm"] for i in infos}) != 1:
            return None
        if any(not i["vorname_norm"] for i in infos):
            return None
        order = sorted(surogats, key=lambda s: len(info_by_surogat[s]["vorname_norm"]))
        for i in range(len(order) - 1):
            shorter = info_by_surogat[order[i]]["vorname_norm"]
            longer = info_by_surogat[order[i + 1]]["vorname_norm"]
            if shorter == longer or not longer.startswith(shorter):
                return None
        longest = order[-1]
        longest_last = info_by_surogat[longest]["letzter_fall"]
        for s in order[:-1]:
            s_last = info_by_surogat[s]["letzter_fall"]
            if s_last and longest_last and s_last > longest_last:
                return None
        return longest

    def to_date(x):
        if x is None:
            return None
        if isinstance(x, datetime):
            return x.date()
        if isinstance(x, date):
            return x
        if isinstance(x, str):
            try:
                return datetime.strptime(x[:10], "%Y-%m-%d").date()
            except ValueError:
                return None
        return None

    def has_case_near(surogat, dates, window_days=90):
        """Prueft, ob der Patient einen Behandlungsfall (patfall, FVon-FBis)
        hat, der bis zu window_days Tage vor oder nach einem der Mail-Daten
        liegt bzw. diesen Zeitraum ueberschneidet. Ohne ermittelbares Mail-
        Datum wird die Regel nicht angewendet (True); ohne jeden Fall gilt
        der Patient als nicht plausibel (False)."""
        valid_dates = [to_date(d) for d in dates]
        valid_dates = [d for d in valid_dates if d is not None]
        if not valid_dates:
            return True
        ranges = info_by_surogat[surogat]["fall_ranges"]
        if not ranges:
            return False
        for dd in valid_dates:
            lo, hi = dd - timedelta(days=window_days), dd + timedelta(days=window_days)
            for von, bis in ranges:
                von_d, bis_d = to_date(von), to_date(bis)
                if von_d and bis_d and von_d <= hi and bis_d >= lo:
                    return True
        return False

    def lastname_conflict_check(surogat, combined):
        """Bei reinem Nachnamen-Fallback (Vorname nicht ueberprueft): prueft,
        ob im Text der Vorname eines ANDEREN Patienten mit demselben
        Nachnamen auftaucht. Falls ja, ist die Zuordnung unsicher und wird
        als Widerspruch gemeldet statt als (un)bestaetigter Treffer."""
        nach = info_by_surogat[surogat]["nachname_norm"]
        for other in lastname_index.get(nach, []):
            if other == surogat:
                continue
            vor = info_by_surogat[other]["vorname_norm"]
            if vor and len(vor) >= 2 and re.search(r"\b" + re.escape(vor) + r"\b", combined):
                return other
        return None

    for addr, data in candidate_senders.items():
        subject = data["subject"] or ""
        if is_excluded_subject(subject):
            continue
        # Ueber ALLE Mails dieser Adresse hinweg zusammengefuehrt (nicht nur
        # die erste), damit z.B. ein Geburtsdatum oder ein Name, der erst in
        # einer spaeteren Mail auftaucht, ebenfalls erkannt wird.
        all_subjects = " ".join(data.get("subjects", []))
        all_bodies = " ".join(bodies.get(addr, []))
        # Sperr-Marker zwischen den Feldern, damit bei der Namenssuche kein
        # Wort ueber Feldgrenzen (Adresse/Betreff/Inhalt) hinweg als
        # "benachbart" gilt.
        FIELD_BOUNDARY = " xxfeldgrenzexx "
        combined = normalize_text(addr + FIELD_BOUNDARY + all_subjects + FIELD_BOUNDARY + all_bodies)
        phone_tails_text = phone_tails_in_text(all_subjects + " " + all_bodies)
        addr_dates = [d for d in msg_dates.get(addr, []) if d is not None]
        maildatum = max(addr_dates).astimezone().strftime("%Y-%m-%d") if addr_dates else ""

        # Namensabgleich (ueber alle bei dieser Adresse gesehenen Anzeigenamen)
        found = set()
        kind_base = None
        for name in data["names"]:
            parts = normalize_name_parts(name)
            if len(parts) < 2:
                continue
            for i, a in enumerate(parts):
                for j, b in enumerate(parts):
                    if i == j:
                        continue
                    if (a, b) in name_index:
                        found.update(name_index[(a, b)])
            if found:
                kind_base = "eigene Email (Namensuebereinstimmung)"
        if not found:
            for name in data["names"]:
                parts = normalize_name_parts(name)
                for p in parts:
                    hits = lastname_index.get(p, [])
                    # Bei sehr haeufigen Nachnamen ist der Treffer zu unspezifisch
                    # (z.B. ein im Text vorkommender Vorname wird faelschlich als
                    # Nachname interpretiert) - dann lieber gar nicht vorschlagen.
                    if hits and len(hits) <= LASTNAME_FALLBACK_MAX:
                        found.update(hits)
                if found:
                    kind_base = "vermutlich Angehoerige/r (nur Nachname eindeutig)"

        att_surogat, att_msg_dates = attachment_match(addr)
        if att_surogat is not None and att_surogat not in info_by_surogat:
            # P:\dok-Ordner ohne (mehr) zugehoerigen patstamm-Eintrag (z.B.
            # geloeschter/zusammengefuehrter Patient) - Anhangstreffer verwerfen.
            att_surogat = None
        if att_surogat is not None and att_surogat in sonderpatient_surogate and found:
            # Ein Sonderpatient (Pseudopatient) im Anhangs-Index widerspricht
            # einem echten Anzeigename-Treffer - kein echter Widerspruch,
            # das Anhangs-Signal wird einfach ignoriert statt einen
            # Konflikt zu melden.
            att_surogat = None

        if att_surogat is not None:
            conflict_att = found and att_surogat not in found
            if conflict_att:
                # Widerspruch: Anhang deutet auf anderen Patienten hin als der
                # Name - AUSSER die Anhang-Seite wird zusaetzlich durch
                # Telefonnummer oder Geburtsdatum im Text bestaetigt, dann
                # gilt der Widerspruch als aufgeloest (starkes Signal schlaegt
                # den reinen Anzeigenamen) - siehe [[project-missing-patient-
                # emails]], Faelle 68717/62540 am 2026-09-09.
                info_a = info_by_surogat[att_surogat]
                dob_ok_a = dob_in_text(info_a["geburtsdatum"], combined) or dob_year_in_local_part(info_a["geburtsdatum"], addr)
                phone_ok_a = bool(info_a["phone_tails"] & phone_tails_text)
                if not (dob_ok_a or phone_ok_a):
                    status_a, _ = email_status(info_a)
                    rows_conflict.append({
                        "addr": addr, "subject": subject, "source": "Anhang",
                        "att_surogat": att_surogat, "att_info": info_a, "att_status": status_a,
                        "name_surogats": found, "n_messages": len(att_msg_dates),
                    })
                    continue
            check_relations(att_surogat, addr, combined, subject)
            info = info_by_surogat[att_surogat]
            status, ok = email_status(info)
            if not ok:
                continue
            typo = check_typo(att_surogat, addr)
            if typo:
                rows_typo.append({"surogat": att_surogat, "email": addr, "stored": typo,
                                   "subject": subject, "quelle": "Anhang-Abgleich", "maildatum": maildatum})
                continue
            dob_ok = dob_in_text(info["geburtsdatum"], combined) or dob_year_in_local_part(info["geburtsdatum"], addr)
            phone_ok = bool(info["phone_tails"] & phone_tails_text)
            grund = subject if subject else "(Anhang-Abgleich)"
            kind = "Anhang in P:\\dok eindeutig zugeordnet" + (" + Geburtsdatum im Text" if dob_ok else "") + \
                   (" + Telefonnummer im Text" if phone_ok else "")
            if conflict_att:
                kind += " (Widerspruch zum Anzeigenamen durch Telefonnummer/Geburtsdatum aufgeloest)"
            rows_attach.append({
                "surogat": att_surogat, "email": addr, "subject": grund,
                "kind": kind,
                "status": status, "maildatum": maildatum,
            })
            continue

        # Inhaltsbasierte Namenssuche: unabhaengig vom Absender-Anzeigenamen
        # nach JEDER bekannten Vor+Nachname-Kombination suchen. Der Betreff
        # hat Vorrang vor dem Nachrichtentext (er benennt meist eindeutig,
        # um wen es geht), und die Email-Adresse selbst wird hier bewusst
        # NICHT durchsucht - eine "sprechende" Absenderadresse ist ein
        # Signal zur Absender-IDENTITAET (wie der Anzeigename), aber kein
        # verlaesslicher Beleg dafuer, ueber welchen Patienten die Mail
        # tatsaechlich inhaltlich handelt.
        subj_norm = normalize_text(FIELD_BOUNDARY.join(data.get("subjects", [])))
        body_norm = normalize_text(FIELD_BOUNDARY.join(bodies.get(addr, [])))
        subject_found = find_names_in_text(subj_norm, name_index)
        if len(subject_found) == 1:
            content_found = subject_found
        else:
            content_found = subject_found | find_names_in_text(body_norm, name_index)

        # Bevor ein Widerspruch zwischen Anzeigename und Inhalt gemeldet
        # (oder eine mehrdeutige Inhaltsnennung verworfen) wird: pruefen, ob
        # sich das ueber eine Spitzname/Vollname-Beziehung (gleicher
        # Nachname, ein Vorname ist Praefix des anderen) aufloesen laesst.
        nickname_pool = content_found | found
        if len(nickname_pool) > 1:
            resolved = resolve_nickname_group(nickname_pool)
            if resolved is not None:
                content_found = {resolved}
                found = {resolved}
                if kind_base is None:
                    kind_base = "eigene Email (Namensuebereinstimmung)"

        if found:
            # Ein Sonderpatient (Pseudopatient), der zufaellig im Inhalt
            # erwaehnt wird, darf einen echten Anzeigename-Treffer weder
            # als Widerspruch noch als Mehrdeutigkeit ausbremsen - das
            # Signal wird nur genutzt, wenn found sonst leer waere.
            content_found = content_found - sonderpatient_surogate

        if len(content_found) > 1 and found and not (content_found & found):
            # Betreff/Inhalt benennen mehrere bekannte, aber andere Patienten
            # als der per Anzeigename/Nachname gefundene Kandidat (z.B.
            # Sammel-/Institutionsadresse mit mehreren genannten Patienten) -
            # zu unsicher fuer einen Vorschlag, daher verworfen.
            n_dropped_multi_conflict += 1
            record_dropped(rows_dropped_multi, addr, subject, content_found,
                            "Betreff/Inhalt nennen andere bekannte Patienten als der Anzeigename (evtl. Sammeladresse)")
            continue

        if len(content_found) == 1:
            content_surogat = next(iter(content_found))
            conflict_content = found and content_surogat not in found
            if conflict_content:
                # Wie beim Anhang-Widerspruch: durch Telefonnummer/Geburtsdatum
                # im Text bestaetigt loest den Widerspruch mit dem
                # Anzeigenamen auf, statt ihn nur zu melden.
                info_c = info_by_surogat[content_surogat]
                dob_ok_c = dob_in_text(info_c["geburtsdatum"], combined) or dob_year_in_local_part(info_c["geburtsdatum"], addr)
                phone_ok_c = bool(info_c["phone_tails"] & phone_tails_text)
                if not (dob_ok_c or phone_ok_c):
                    status_c, _ = email_status(info_c)
                    rows_conflict.append({
                        "addr": addr, "subject": subject, "source": "Name im Inhalt",
                        "att_surogat": content_surogat, "att_info": info_c, "att_status": status_c,
                        "name_surogats": found,
                        "n_messages": count_messages_with_name(addr, content_surogat),
                    })
                    continue
            check_relations(content_surogat, addr, combined, subject)
            info = info_by_surogat[content_surogat]
            status, ok = email_status(info)
            if ok:
                typo = check_typo(content_surogat, addr)
                if typo:
                    rows_typo.append({"surogat": content_surogat, "email": addr, "stored": typo,
                                       "subject": subject, "quelle": "Name im Inhalt", "maildatum": maildatum})
                    continue
                dob_ok = dob_in_text(info["geburtsdatum"], combined) or dob_year_in_local_part(info["geburtsdatum"], addr)
                phone_ok = bool(info["phone_tails"] & phone_tails_text)
                kind = "Vor- und Nachname im Betreff/Inhalt gefunden" + \
                       (" + Geburtsdatum im Text" if dob_ok else "") + \
                       (" + Telefonnummer im Text" if phone_ok else "")
                if conflict_content:
                    kind += " (Widerspruch zum Anzeigenamen durch Telefonnummer/Geburtsdatum aufgeloest)"
                rows_content.append({
                    "surogat": content_surogat, "email": addr, "subject": subject,
                    "kind": kind,
                    "status": status, "maildatum": maildatum,
                })
            continue

        if not found:
            continue

        if len(found) == 1:
            surogat = next(iter(found))
            if kind_base == "vermutlich Angehoerige/r (nur Nachname eindeutig)":
                conflict_other = lastname_conflict_check(surogat, combined)
                if conflict_other is not None:
                    info_c = info_by_surogat[conflict_other]
                    status_c, _ = email_status(info_c)
                    rows_conflict.append({
                        "addr": addr, "subject": subject,
                        "source": "Vorname eines anderen Patienten mit gleichem Nachnamen im Inhalt",
                        "att_surogat": conflict_other, "att_info": info_c, "att_status": status_c,
                        "name_surogats": {surogat},
                        "n_messages": count_messages_with_name(addr, conflict_other),
                    })
                    continue
            check_relations(surogat, addr, combined, subject)
            info = info_by_surogat[surogat]
            status, ok = email_status(info)
            if not ok:
                continue
            typo = check_typo(surogat, addr)
            if typo:
                rows_typo.append({"surogat": surogat, "email": addr, "stored": typo,
                                   "subject": subject, "quelle": kind_base, "maildatum": maildatum})
                continue
            dob_ok = dob_in_text(info["geburtsdatum"], combined) or dob_year_in_local_part(info["geburtsdatum"], addr)
            phone_ok = bool(info["phone_tails"] & phone_tails_text)
            name_ok = bool(info["vorname_norm"]) and bool(info["nachname_norm"]) and \
                re.search(r"\b" + re.escape(info["vorname_norm"]) + r"\b", combined) and \
                re.search(r"\b" + re.escape(info["nachname_norm"]) + r"\b", combined)
            if not (name_ok or dob_ok or phone_ok):
                # Keine weiteren Anhaltspunkte ausser der urspruenglichen
                # Namensuebereinstimmung im Anzeigenamen/Nachnamen (kein
                # Vorname/Geburtsdatum/Telefonnummer im Betreff/Inhalt, kein
                # Anhang) - zu unsicher fuer einen Vorschlag, daher verworfen.
                n_dropped_unconfirmed += 1
                record_dropped(rows_dropped_unconfirmed, addr, subject, {surogat},
                                "nur Anzeigename/Nachname, keine weiteren Anhaltspunkte im Text")
                continue
            entry = {
                "email": addr, "subject": subject, "status": status,
                "kind": kind_base + (" + Geburtsdatum im Text" if dob_ok else "") +
                        (" + Telefonnummer im Text" if phone_ok else ""),
                "maildatum": maildatum,
            }
            unique_confirmed.setdefault(surogat, []).append(entry)
        else:
            # Plausibilitaetsfilter: ein Kandidat, der in keinem Behandlungs-
            # fall (patfall, FVon-FBis) innerhalb von 3 Monaten vor/nach dem
            # Mail-Datum vorkommt (oder ueberhaupt keinen Fall hat), scheidet
            # aus - eine aktuelle Mail zu einem so inaktiven Patienten ist zu
            # unwahrscheinlich, um ihn weiter zur Auswahl zu stellen.
            dates_for_addr = msg_dates.get(addr, [])
            plausible = {s for s in found if has_case_near(s, dates_for_addr)}
            if not plausible:
                n_dropped_unconfirmed += 1
                record_dropped(rows_dropped_unconfirmed, addr, subject, found,
                                "kein Behandlungsfall (patfall) nahe dem Mail-Datum")
                continue
            if len(plausible) == 1:
                surogat = next(iter(plausible))
                info = info_by_surogat[surogat]
                status, ok = email_status(info)
                if not ok:
                    continue
                typo = check_typo(surogat, addr)
                if typo:
                    rows_typo.append({"surogat": surogat, "email": addr, "stored": typo,
                                       "subject": subject, "quelle": kind_base, "maildatum": maildatum})
                    continue
                check_relations(surogat, addr, combined, subject)
                unique_confirmed.setdefault(surogat, []).append({
                    "email": addr, "subject": subject,
                    "status": status,
                    "kind": kind_base + " + einziger Kandidat mit Behandlungsfall nahe Mail-Datum",
                    "maildatum": maildatum,
                })
                continue
            found = plausible

            raw_list = []
            for surogat in found:
                info = info_by_surogat[surogat]
                status, _ = email_status(info)
                dob_ok = dob_in_text(info["geburtsdatum"], combined) or dob_year_in_local_part(info["geburtsdatum"], addr)
                phone_ok = bool(info["phone_tails"] & phone_tails_text)
                name_ok = bool(info["vorname_norm"]) and bool(info["nachname_norm"]) and \
                    re.search(r"\b" + re.escape(info["vorname_norm"]) + r"\b", combined) and \
                    re.search(r"\b" + re.escape(info["nachname_norm"]) + r"\b", combined)
                raw_list.append((surogat, status, dob_ok, phone_ok, name_ok))
            # Bei gleichnamigen Kandidaten ist die reine Namensnennung im
            # Text fuer ALLE automatisch wahr und damit nicht unterscheidungs-
            # kraeftig. Sobald irgendein Kandidat ein starkes, tatsaechlich
            # trennendes Signal hat (Geburtsdatum oder Telefonnummer), zaehlt
            # die blosse Namensnennung bei den anderen nicht mehr als
            # Bestaetigung.
            has_strong_signal = any(dob_ok or phone_ok for _, _, dob_ok, phone_ok, _ in raw_list)
            cand_list = []
            for surogat, status, dob_ok, phone_ok, name_ok in raw_list:
                strong_ok = dob_ok or phone_ok
                bestaetigt = strong_ok or (name_ok and not has_strong_signal)
                kind = (f"MEHRDEUTIG ({len(found)} moegliche Patienten) - {kind_base} - " +
                        ("bestaetigt" if bestaetigt else "nicht bestaetigt") +
                        (" + Geburtsdatum im Text" if dob_ok else "") +
                        (" + Telefonnummer im Text" if phone_ok else ""))
                cand_list.append((surogat, kind, status, bestaetigt))
            bestaetigte = [c for c in cand_list if c[3]]
            if not bestaetigte:
                # Keiner der moeglichen Kandidaten hat weitere Anhaltspunkte
                # (Vorname/Geburtsdatum/Telefonnummer im Text) - reines
                # Rauschen, verworfen.
                n_dropped_unconfirmed += 1
                record_dropped(rows_dropped_unconfirmed, addr, subject, found,
                                "mehrdeutig, keiner der Kandidaten inhaltlich bestaetigt")
                continue
            if len(bestaetigte) == 1:
                # Genau ein Kandidat ist inhaltlich bestaetigt (Geburtsdatum,
                # Telefonnummer oder eigener Name im Text) - die anderen
                # waren nur ueber den Anzeigenamen/Nachnamen mehrdeutig und
                # werden zugunsten des bestaetigten aufgeloest, statt als
                # "mehrdeutig" nebeneinander stehen zu bleiben.
                surogat = bestaetigte[0][0]
                info = info_by_surogat[surogat]
                status, ok = email_status(info)
                if not ok:
                    continue
                typo = check_typo(surogat, addr)
                if typo:
                    rows_typo.append({"surogat": surogat, "email": addr, "stored": typo,
                                       "subject": subject, "quelle": kind_base, "maildatum": maildatum})
                    continue
                check_relations(surogat, addr, combined, subject)
                unique_confirmed.setdefault(surogat, []).append({
                    "email": addr, "subject": subject, "status": status,
                    "kind": bestaetigte[0][1], "maildatum": maildatum,
                })
                continue
            ambiguous_by_addr[addr] = {"subject": subject, "candidates": cand_list}

    # --- Abschnitt 9/10: bestaetigte/vermutete Praxen, Pflegedienste,
    # Apotheken und Sonderpatienten (Sammel-/Pseudopatienten) - nie eine
    # Patienten-eigene Adresse, aber inhaltlich einem Patienten zuordenbar. ---
    rows_confirmed_institutional = []   # Abschnitt 9
    rows_suspected_institutional = []   # Abschnitt 10

    def is_sonderpatient(surogat):
        return surogat in sonderpatient_surogate

    def split_sonderpatient(rows, key="surogat"):
        keep, moved = [], []
        for e in rows:
            (moved if is_sonderpatient(e[key]) else keep).append(e)
        return keep, moved

    rows_attach, moved_attach = split_sonderpatient(rows_attach)
    rows_content, moved_content = split_sonderpatient(rows_content)
    rows_typo, moved_typo = split_sonderpatient(rows_typo)

    for e in moved_attach + moved_content:
        rows_confirmed_institutional.append({
            "surogat": e["surogat"], "email": e["email"], "subject": e["subject"],
            "kind": e["kind"] + " (Sonderpatient/Sammeleintrag)", "status": e["status"],
            "maildatum": e.get("maildatum", ""),
        })
    for e in moved_typo:
        rows_confirmed_institutional.append({
            "surogat": e["surogat"], "email": e["email"], "subject": e["subject"],
            "kind": f"{e['quelle']} (Sonderpatient/Sammeleintrag, Tippfehler-Logik uebersprungen)",
            "status": "-", "maildatum": e.get("maildatum", ""),
        })
    for s in [s for s in unique_confirmed if is_sonderpatient(s)]:
        for e in unique_confirmed.pop(s):
            rows_confirmed_institutional.append({
                "surogat": s, "email": e["email"], "subject": e["subject"],
                "kind": e["kind"] + " (Sonderpatient/Sammeleintrag)", "status": e["status"],
                "maildatum": e.get("maildatum", ""),
            })

    # Praxen/Pflegedienste/Apotheken: je einzelne Nachricht geprueft (nicht
    # ueber die Adresse aggregiert wie oben - eine solche Adresse kann zu
    # vielen verschiedenen Patienten gehoeren).
    for msg in institutional_messages:
        subject = decode_header_val(msg["subject"] or "")
        if is_excluded_subject(subject):
            continue
        body_norm = normalize_text(msg["body"] or "")
        subject_norm = normalize_text(subject)
        found = find_names_in_text(subject_norm, name_index)
        if not found:
            found = find_names_in_text(subject_norm + "\n" + body_norm, name_index)

        att_cand = {}
        email_ts = None
        if msg["date"] is not None:
            try:
                email_ts = msg["date"].timestamp()
            except (OverflowError, OSError, ValueError):
                email_ts = None
        for fname, size, digest in (msg["atts"] or []):
            if not digest:
                continue
            if digest in generic_attachment_hashes:
                continue
            for patient_nr, path, mtime in dok_index.get(size, []):
                if hash_file(path, dok_hash_cache) != digest:
                    continue
                if email_ts is not None and mtime < email_ts - 86400:
                    continue
                if not patient_nr.isdigit():
                    continue
                s = int(patient_nr)
                att_cand[s] = att_cand.get(s, 0) + 1
        att_surogat = next(iter(att_cand)) if len(att_cand) == 1 else None

        surogats = set(found)
        if att_surogat is not None:
            surogats.add(att_surogat)
        if len(surogats) != 1:
            continue
        surogat = next(iter(surogats))
        if surogat not in info_by_surogat:
            continue

        info = info_by_surogat[surogat]
        combined = subject_norm + "\n" + body_norm
        dob_ok = dob_in_text(info["geburtsdatum"], combined)
        phone_ok = bool(info["phone_tails"] & phone_tails_in_text(combined))

        kind = "Praxis/Pflegedienst-Nachricht, Patientenbezug erkannt"
        if att_surogat is not None and att_surogat == surogat:
            kind += " (Anhang in P:\\dok eindeutig zugeordnet)"
        if found:
            kind += " (Name im Betreff/Inhalt gefunden)"
        if dob_ok:
            kind += " + Geburtsdatum im Text"
        if phone_ok:
            kind += " + Telefonnummer im Text"

        maildatum = msg["date"].astimezone().strftime("%Y-%m-%d") if msg["date"] else ""
        row = {"surogat": surogat, "email": msg["addr"], "subject": subject,
               "kind": kind, "status": "-", "maildatum": maildatum}
        if msg["confirmed"]:
            rows_confirmed_institutional.append(row)
        else:
            rows_suspected_institutional.append(row)

    rows_content, rows_suspected_cluster = split_scam_clusters(rows_content)

    def fmt_last_fall(surogat):
        d = info_by_surogat[surogat]["letzter_fall"]
        if not d:
            return "-"
        return d.isoformat() if hasattr(d, "isoformat") else str(d)

    def write_comment(out, text):
        # Zweite Zeile direkt unter jeder Abschnittsueberschrift: erklaert,
        # was mit den Zeilen dieses Abschnitts geschieht. Beginnt bewusst
        # NICHT mit "###" (sonst wuerde sie als neue Abschnittsgrenze
        # missverstanden) und enthaelt keine Tabs, daher als einfeldrige
        # Zeile in der CSV immer harmlos - jedes verarbeitende Skript
        # verwirft sie ueber die bestehende "len(row) < 10"-Pruefung, ohne
        # dass dort etwas geaendert werden musste.
        out.write(f"# {text}\n")

    def write_section(out, title, comment, data):
        out.write(f"### {title} ###\n")
        write_comment(out, comment)
        n = 0
        for surogat, entries in sorted(data.items()):
            info = info_by_surogat[surogat]
            full_name = f"{info['nachname']}, {info['vorname']}"
            for e in entries:
                subj = e["subject"][:80].replace("\t", " ").replace("\r", " ").replace("\n", " ")
                out.write(f"{full_name}\t{surogat}\t{info['geburtsdatum']}\t{e['email']}\t{e['kind']}\t{e['status']}\t{fmt_last_fall(surogat)}\t{subj}\t{e.get('maildatum', '')}\t-\n")
                n += 1
        return n

    run_ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    out_txt = os.path.join(OUT_DIR, f"Patientenmails_Vorschlagsliste_{run_ts}.txt")
    out_csv = os.path.join(OUT_DIR, f"Patientenmails_Vorschlagsliste_{run_ts}.csv")

    header = ("Name\tPatientennummer\tGeburtsdatum\tEmail-Adresse\tArt\tAktueller Email-Status\tLetzter Fall\t"
               "Grund (Betreff-Ausschnitt)\tMail-Datum\tZusatz (Abschn. 5: falsche Adresse / Abschn. 6: 2. Patientennummer)\n")
    with open(out_txt, "w", encoding="utf-8") as out:
        out.write(header)

        # Abschnitte, die direkt in die Bearbeitung (Eintragung FEmail) einfliessen, zuerst.
        out.write("### 0) Ueber Anhang in P:\\dok eindeutig zugeordnet ###\n")
        write_comment(out, "Wird bei Bestaetigung automatisch nach medoff.patstamm.FEmail uebernommen (apply_patient_emails.py, Phase D Staging + Phase F Commit).")
        n0 = 0
        for e in sorted(rows_attach, key=lambda x: x["surogat"]):
            info = info_by_surogat[e["surogat"]]
            full_name = f"{info['nachname']}, {info['vorname']}"
            subj = e["subject"][:80].replace("\t", " ").replace("\r", " ").replace("\n", " ")
            out.write(f"{full_name}\t{e['surogat']}\t{info['geburtsdatum']}\t{e['email']}\t{e['kind']}\t{e['status']}\t{fmt_last_fall(e['surogat'])}\t{subj}\t{e.get('maildatum', '')}\t-\n")
            n0 += 1
        out.write("\n")

        out.write("### 0b) Ueber Namensnennung im Betreff/Inhalt eindeutig zugeordnet (unabhaengig vom Absender-Anzeigenamen) ###\n")
        write_comment(out, "Wird bei Bestaetigung automatisch nach medoff.patstamm.FEmail uebernommen, wie Abschnitt 0 (apply_patient_emails.py).")
        n0b = 0
        for e in sorted(rows_content, key=lambda x: x["surogat"]):
            info = info_by_surogat[e["surogat"]]
            full_name = f"{info['nachname']}, {info['vorname']}"
            subj = e["subject"][:80].replace("\t", " ").replace("\r", " ").replace("\n", " ")
            out.write(f"{full_name}\t{e['surogat']}\t{info['geburtsdatum']}\t{e['email']}\t{e['kind']}\t{e['status']}\t{fmt_last_fall(e['surogat'])}\t{subj}\t{e.get('maildatum', '')}\t-\n")
            n0b += 1
        out.write("\n")

        n1 = write_section(out, "1) Eindeutig (Name), inhaltlich bestaetigt (Name oder Geburtsdatum im Text)",
                            "Wird bei Bestaetigung automatisch nach medoff.patstamm.FEmail uebernommen, wie Abschnitt 0 (apply_patient_emails.py).",
                            unique_confirmed)
        out.write("\n")

        out.write("### 5) Vermutlich Tippfehler in hinterlegter Email-Adresse (statt neuer Adresse) ###\n")
        write_comment(out, "Wird bei Bestaetigung automatisch uebernommen wie Abschnitt 0/0b/1 - ersetzt dabei die vermutlich falsche vorhandene Adresse (apply_patient_emails.py).")
        n5 = 0
        for e in sorted(rows_typo, key=lambda x: x["surogat"]):
            info = info_by_surogat[e["surogat"]]
            full_name = f"{info['nachname']}, {info['vorname']}"
            subj = e["subject"][:80].replace("\t", " ").replace("\r", " ").replace("\n", " ")
            out.write(f"{full_name}\t{e['surogat']}\t{info['geburtsdatum']}\t{e['email']}\t"
                      f"vermutlich Tippfehler ({e['quelle']})\thinterlegt: {e['stored']}\t{fmt_last_fall(e['surogat'])}\t{subj}\t{e.get('maildatum', '')}\t{e['stored']}\n")
            n5 += 1
        out.write("\n")

        # Ab hier: informative Abschnitte, die NICHT automatisch in die FEmail-
        # Eintragung einfliessen (Abschnitte 3, 4, 6 - manuell/gesondert zu pruefen).
        out.write("### 3) Mehrdeutig (Name) - je Absender alle moeglichen Patienten, bestaetigte zuerst ###\n")
        write_comment(out, "Keine automatische Verarbeitung. Bei Bestaetigung fuer ALLE gelisteten Patienten: manuell an archive_institutional_emails.py uebergeben (archiviert bei jedem, FEmail bleibt ueberall unangetastet).")
        n3 = 0
        for addr in sorted(ambiguous_by_addr):
            data = ambiguous_by_addr[addr]
            subj = data["subject"][:80].replace("\t", " ").replace("\r", " ").replace("\n", " ")
            cands = sorted(data["candidates"], key=lambda c: (not c[3], c[0]))
            for surogat, kind, status, bestaetigt in cands:
                info = info_by_surogat[surogat]
                full_name = f"{info['nachname']}, {info['vorname']}"
                out.write(f"{full_name}\t{surogat}\t{info['geburtsdatum']}\t{addr}\t{kind}\t{status}\t{fmt_last_fall(surogat)}\t{subj}\t-\t-\n")
                n3 += 1

        out.write("\n")
        out.write("### 4a) WIDERSPRUCH, aber mehrfach bestaetigt: Anhang/Name in mindestens 2 unabhaengigen Nachrichten derselben Adresse zeigt auf denselben Patienten ###\n")
        write_comment(out, "Keine automatische Verarbeitung. Wiederholtes Signal ueber mehrere Nachrichten hinweg - deutlich staerkerer Hinweis, dass die Adresse trotz abweichendem Anzeigenamen tatsaechlich diesem Patienten gehoert (z.B. Zweitadresse), als ein einzelner Treffer. Bei Bestaetigung von Hand in Medical Office eintragen, oder die Zeile manuell in Abschnitt 1 verschieben.")
        n4a = 0
        n4b = 0
        rows_conflict_sorted = sorted(rows_conflict, key=lambda c: -c.get("n_messages", 1))
        for c in rows_conflict_sorted:
            if c.get("n_messages", 1) < 2:
                continue
            att_full = f"{c['att_info']['nachname']}, {c['att_info']['vorname']}"
            name_list = ", ".join(str(s) for s in c["name_surogats"])
            subj = c["subject"][:80].replace("\t", " ").replace("\r", " ").replace("\n", " ")
            out.write(f"{att_full}\t{c['att_surogat']}\t{c['att_info']['geburtsdatum']}\t{c['addr']}\t"
                      f"{c['source']} zeigt in {c['n_messages']} unabhaengigen Nachrichten auf {c['att_surogat']}, Anzeigename passt zu Patientennr(n) {name_list}\t{c['att_status']}\t{fmt_last_fall(c['att_surogat'])}\t{subj}\t-\t-\n")
            n4a += 1

        out.write("\n")
        out.write("### 4b) WIDERSPRUCH: Anhang oder Name im Inhalt deutet auf anderen Patienten hin als der Absender-Anzeigename (nur einzelner Beleg) ###\n")
        write_comment(out, "Keine automatische Verarbeitung (echte Widersprueche werden schon vorab durch Telefonnummer/Geburtsdatum im Text aufgeloest, wenn moeglich). Bei Bedarf von Hand in Medical Office klaeren, oder die Zeile manuell in Abschnitt 1 verschieben.")
        for c in rows_conflict_sorted:
            if c.get("n_messages", 1) >= 2:
                continue
            att_full = f"{c['att_info']['nachname']}, {c['att_info']['vorname']}"
            name_list = ", ".join(str(s) for s in c["name_surogats"])
            subj = c["subject"][:80].replace("\t", " ").replace("\r", " ").replace("\n", " ")
            out.write(f"{att_full}\t{c['att_surogat']}\t{c['att_info']['geburtsdatum']}\t{c['addr']}\t"
                      f"{c['source']} zeigt auf {c['att_surogat']}, Anzeigename passt zu Patientennr(n) {name_list}\t{c['att_status']}\t{fmt_last_fall(c['att_surogat'])}\t{subj}\t-\t-\n")
            n4b += 1
        n4 = n4a + n4b

        out.write("\n")
        out.write("### 6) Vermutlich fehlende Beziehungsdokumentation (patrelation) ###\n")
        write_comment(out, "Keine automatische Verarbeitung. Bei Bedarf die Beziehung von Hand in patrelation eintragen.")
        n6 = 0
        for r in rows_relations:
            info_p = info_by_surogat[r["primary"]]
            info_o = info_by_surogat[r["other"]]
            full_p = f"{info_p['nachname']}, {info_p['vorname']}"
            full_o = f"{info_o['nachname']}, {info_o['vorname']}"
            subj = r["subject"][:80].replace("\t", " ").replace("\r", " ").replace("\n", " ")
            out.write(f"{full_p}\t{r['primary']}\t{info_p['geburtsdatum']}\t{r['email']}\t"
                      f"'{r['word']}' verweist auf Patientennr {r['other']} ({full_o}, geb. {info_o['geburtsdatum']}) - noch nicht in patrelation\t"
                      f"-\t{fmt_last_fall(r['primary'])}\t{subj}\t-\t{r['other']}\n")
            n6 += 1

        # Verworfene Kandidaten (zur Nachvollziehbarkeit angehaengt, fliessen
        # in keine Bearbeitung ein).
        out.write("\n")
        out.write("### 7) Verworfen: keine ausreichenden Anhaltspunkte ###\n")
        write_comment(out, "Keine weitere Aktion - nur zur Nachvollziehbarkeit protokolliert.")
        n7 = 0
        for d in rows_dropped_unconfirmed:
            subj = d["subject"][:80].replace("\t", " ").replace("\r", " ").replace("\n", " ")
            out.write(f"-\t{d['surogats']}\t-\t{d['addr']}\t{d['reason']}\t-\t-\t{subj}\t-\t-\n")
            n7 += 1

        out.write("\n")
        out.write("### 8) Verworfen: Betreff/Inhalt nennen andere Patienten (evtl. Sammeladresse) ###\n")
        write_comment(out, "Keine weitere Aktion.")
        n8 = 0
        for d in rows_dropped_multi:
            subj = d["subject"][:80].replace("\t", " ").replace("\r", " ").replace("\n", " ")
            out.write(f"-\t{d['surogats']}\t-\t{d['addr']}\t{d['reason']}\t-\t-\t{subj}\t-\t-\n")
            n8 += 1

        # Praxen/Pflegedienste/Apotheken/Sonderpatienten: nie eine Patienten-
        # eigene Adresse (fliesst NIE in apply_patient_emails.py ein), aber
        # inhaltlich einem Patienten zuordenbar - fuer die Weiterverarbeitung
        # durch archive_institutional_emails.py.
        out.write("\n")
        out.write("### 9) Bestaetigte Praxis/Pflegedienst/Apotheke/Sonderpatient ###\n")
        write_comment(out, "Wird bei Bestaetigung automatisch verschoben und archiviert (archive_institutional_emails.py) - patstamm.FEmail bleibt unangetastet.")
        n9 = 0
        for e in sorted(rows_confirmed_institutional, key=lambda x: x["surogat"]):
            info = info_by_surogat[e["surogat"]]
            full_name = f"{info['nachname']}, {info['vorname']}"
            subj = e["subject"][:80].replace("\t", " ").replace("\r", " ").replace("\n", " ")
            out.write(f"{full_name}\t{e['surogat']}\t{info['geburtsdatum']}\t{e['email']}\t{e['kind']}\t{e['status']}\t{fmt_last_fall(e['surogat'])}\t{subj}\t{e.get('maildatum', '')}\t-\n")
            n9 += 1

        out.write("\n")
        out.write("### 10) Vermutete Praxis/Pflegedienst (noch nicht in earzt/epraxis/patrelation dokumentiert) ###\n")
        write_comment(out, "Zuerst von Hand in Medical Office dokumentieren (earzt/epraxis bei echter Arztpraxis, sonst eine patrelation-Beziehung) - danach wie Abschnitt 9 an archive_institutional_emails.py uebergeben.")
        n10 = 0
        for e in sorted(rows_suspected_institutional, key=lambda x: x["surogat"]):
            info = info_by_surogat[e["surogat"]]
            full_name = f"{info['nachname']}, {info['vorname']}"
            subj = e["subject"][:80].replace("\t", " ").replace("\r", " ").replace("\n", " ")
            out.write(f"{full_name}\t{e['surogat']}\t{info['geburtsdatum']}\t{e['email']}\t{e['kind']}\t{e['status']}\t{fmt_last_fall(e['surogat'])}\t{subj}\t{e.get('maildatum', '')}\t-\n")
            n10 += 1

        out.write("\n")
        out.write("### 11) Verdacht: Namens-Haeufung (evtl. Scam/Phishing, mehrere verschiedene Absender in kurzer Zeit) ###\n")
        write_comment(out, "Keine automatische Verarbeitung. Ein einzelner echter Treffer darunter kann von Hand wie Abschnitt 0b behandelt werden (Zeile manuell in Abschnitt 1 verschieben), der Rest bleibt unbeachtet.")
        n11 = 0
        for e in sorted(rows_suspected_cluster, key=lambda x: (x["surogat"], x.get("maildatum") or "")):
            info = info_by_surogat[e["surogat"]]
            full_name = f"{info['nachname']}, {info['vorname']}"
            subj = e["subject"][:80].replace("\t", " ").replace("\r", " ").replace("\n", " ")
            out.write(f"{full_name}\t{e['surogat']}\t{info['geburtsdatum']}\t{e['email']}\t{e['kind']}\t{e['status']}\t{fmt_last_fall(e['surogat'])}\t{subj}\t{e.get('maildatum', '')}\t-\n")
            n11 += 1

    with open(out_txt, encoding="utf-8") as f_in, open(out_csv, "w", encoding="utf-8-sig", newline="") as f_out:
        writer = csv.writer(f_out, delimiter=";", quoting=csv.QUOTE_MINIMAL)
        for line in f_in:
            line = line.rstrip("\n")
            if line.startswith("###") or not line:
                writer.writerow([line])
            else:
                writer.writerow(line.split("\t"))

    print(f"Nachrichten gescannt: {n_msgs}")
    print(f"Abschnitt 0 (Anhang-Treffer): {n0}")
    print(f"Abschnitt 0b (Name im Inhalt gefunden): {n0b}")
    print(f"Abschnitt 1 (eindeutig, bestaetigt): {n1}")
    print(f"Abschnitt 5 (vermutlich Tippfehler): {n5}")
    print(f"Abschnitt 3 (mehrdeutig, gruppiert je Absender): {n3}")
    print(f"Abschnitt 4 (Widersprueche Anhang/Name): {n4}")
    print(f"  davon 4a) mehrfach bestaetigt (>=2 unabhaengige Nachrichten): {n4a}")
    print(f"  davon 4b) nur einzelner Beleg: {n4b}")
    print(f"Abschnitt 6 (fehlende Beziehungsdokumentation): {n6}")
    print(f"Abschnitt 7 (verworfen, keine Anhaltspunkte): {n7}")
    print(f"Abschnitt 8 (verworfen, evtl. Sammeladresse): {n8}")
    print(f"Abschnitt 9 (bestaetigte Praxis/Pflegedienst/Apotheke/Sonderpatient): {n9}")
    print(f"Abschnitt 10 (vermutete Praxis/Pflegedienst): {n10}")
    print(f"Abschnitt 11 (Verdacht Namens-Haeufung, evtl. Scam): {n11}")
    print(f"Dateien: {out_txt} / {out_csv}")

if __name__ == "__main__":
    main()
