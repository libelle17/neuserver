#!/usr/bin/python3
# dokdubletten.py - raeumt die Kopien "Name (2).ext" ... "Name (100).ext" weg, die
# DokimpKurz.au3 bei wiederholten Importversuchen anlegt (Aufraeum() -> dok\<pat_id>\,
# SicherheitsKopie() -> eingelesen\<Jahr>\). Sind dort (2)..(100) belegt, scheitert der
# naechste Import desselben Namens.
#
# Geloescht wird eine Kopie nur, wenn ALLES zutrifft:
#  - Name endet auf " (n)" mit n >= 2 (so wie AutoIt ihn bildet: vor der letzten Endung),
#  - im selben Verzeichnis gibt es eine inhaltsgleiche Datei gleichen Stamms, die bleibt
#    (Vorrang: Original ohne Nummer, sonst kleinste Nummer); gleiche Groesse und SHA-1,
#    unmittelbar vor dem Loeschen nochmals Byte fuer Byte verglichen,
#  - kein tmbrie.Pfad verweist auf sie (dort stehen ~140 echte Originale mit " (n)"),
#  - sie wurde seit mindestens MINALTER Minuten nicht veraendert (Import evtl. noch im Gang).
#
# Aufruf: dokdubletten.py              nur anzeigen, was geloescht wuerde
#         dokdubletten.py --anwenden   loeschen (fuer cron)
import os, re, sys, time, hashlib, subprocess, fcntl, filecmp

B = '/DATA/Patientendokumente'
BEREICHE = ('dok', 'eingelesen')
MINALTER = 60      # Minuten
NUMMER = re.compile(r'^(.*) \((\d{1,3})\)(\.[^.]*)?$')

anwenden = sys.argv[1:] == ['--anwenden']
if sys.argv[1:] and not anwenden:
    sys.exit(open(__file__).read().split('\nimport ')[0])


def log(s):
    print(time.strftime('%F %T'), 'dokdubletten:', s, flush=True)


def db_referenzen():
    """casefold-normalisierte absolute Pfade aller tmbrie-Eintraege mit ' (n)' im Namen"""
    r = subprocess.run(['mariadb', '--defaults-extra-file=/root/.mysqlrpwd', '-N', '--raw', 'quelle',
                        '-e', r"SELECT Pfad FROM tmbrie WHERE Pfad REGEXP ' \\([0-9]+\\)'"],
                       capture_output=True, text=True, timeout=300)
    if r.returncode:
        sys.exit('dokdubletten: DB-Abfrage fehlgeschlagen, nichts geloescht: ' + r.stderr.strip())
    refs = set()
    for p in r.stdout.splitlines():
        p = p.strip().replace('\\', '/')
        if p[:2].lower() == 'p:':
            refs.add((B + '/' + p[2:].lstrip('/')).casefold())
    return refs


def inhalt(pfad, _c={}):
    if pfad not in _c:
        h = hashlib.sha1()
        with open(pfad, 'rb') as f:
            for blk in iter(lambda: f.read(1 << 20), b''):
                h.update(blk)
        _c[pfad] = h.digest()
    return _c[pfad]


def gruppen():
    """liefert (verzeichnis, stamm, {nummer: name}) mit 0 = Original ohne Nummer"""
    for bereich in BEREICHE:
        for vz, _, namen in os.walk(os.path.join(B, bereich)):
            nset = set(namen)
            g = {}
            for n in namen:
                m = NUMMER.match(n)
                if m and int(m.group(2)) >= 2:
                    stamm = m.group(1) + (m.group(3) or '')
                    g.setdefault(stamm, {})[int(m.group(2))] = n
            for stamm, nummern in g.items():
                if stamm in nset:
                    nummern[0] = stamm
                if len(nummern) > 1:
                    yield vz, stamm, nummern


def main():
    lock = open('/run/dokdubletten.lock', 'w')
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        return
    if not os.path.ismount('/DATA') or not os.path.isdir(B + '/dok'):
        return
    refs = db_referenzen()
    jetzt = time.time()
    zahl = 0
    for vz, stamm, nummern in gruppen():
        # nach Groesse, dann Inhalt buendeln; je Buendel bleibt die Datei mit kleinster Nummer
        nachgr = {}
        for nr in sorted(nummern):
            p = os.path.join(vz, nummern[nr])
            try:
                st = os.lstat(p)
            except FileNotFoundError:
                continue
            if not os.path.isfile(p) or os.path.islink(p):
                continue
            nachgr.setdefault(st.st_size, []).append((nr, p, st))
        for liste in nachgr.values():
            if len(liste) < 2:
                continue
            behalten = {}
            for nr, p, st in liste:
                try:
                    h = inhalt(p)
                except OSError as e:
                    log(f'nicht lesbar, uebersprungen: {p}: {e}')
                    continue
                if h not in behalten:
                    behalten[h] = p
                    continue
                if nr == 0 or p.casefold() in refs:
                    continue
                if jetzt - max(st.st_mtime, st.st_ctime) < MINALTER * 60:
                    continue
                if anwenden:
                    if not filecmp.cmp(p, behalten[h], shallow=False):
                        log(f'SHA-1 gleich, Inhalt verschieden?! belassen: {p}')
                        continue
                    os.remove(p)
                    log(f'geloescht: {p} (= {os.path.basename(behalten[h])})')
                else:
                    log(f'wuerde loeschen: {p} (= {os.path.basename(behalten[h])})')
                zahl += 1
    if zahl:
        log(f'{zahl} Kopie(n) {"geloescht" if anwenden else "gefunden (nur angezeigt)"}')


main()
