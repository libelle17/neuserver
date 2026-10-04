#!/opt/tinytuya/bin/python
"""Steuerung der Tuya-Steckdosenleisten (Logilink Smart Power Strip SH0104) im Praxisnetz.

Aufruf:
  leiste                                   Status aller Leisten, diese Hilfe und die Konfiguration
  leiste <leiste> [status]                 Status einer Leiste
  leiste <leiste> <dose> ein|aus
  leiste <leiste> <dose> neustart [sek]    aus, nach sek Sekunden (Standard 10) schaltet
                                           die Leiste selbst wieder ein
  leiste <alias> ein|aus|neustart [sek]    wie oben, Alias steht fuer Leiste und Dose

  <leiste>: Name aus [leisten] der Konfiguration (eindeutige Abkuerzung genuegt)
  <dose>:   1-4 | usb
  <alias>:  aus [aliase] der Konfiguration, z.B. linux0

Vorher die App "Smart Life" auf allen Handys im WLAN ganz schliessen - die Leiste
erlaubt nur eine Verbindung (sonst Fehler 901).
Einrichtung: los.sh -tuya; Schluessel in /root/tinytuya/devices.json (nicht anzeigen/weitergeben),
nach Neueinrichtung einer Leiste in der App: steckdosenleiste.sh schluessel.
Von szn4 (Windows-Konto sturm): leiste.bat mit "@ssh linux1 sudo /usr/local/bin/leiste %*".
"""
import json, sys

KEYDATEI = "/root/tinytuya/devices.json"
KONFIG = "/etc/leiste.conf"
# Datenpunkte: Schalter und zugehoeriger Countdown (Countdown schaltet nach Ablauf um)
DOSEN = {"1": ("1", "9"), "2": ("2", "10"), "3": ("3", "11"), "4": ("4", "12"), "usb": ("5", "13")}
NAMEN = {"1": "Dose 1", "2": "Dose 2", "3": "Dose 3", "4": "Dose 4", "5": "USB"}

LEISTEN = {}     # Name -> (Geraete-ID, IP)
ALIASE = {}      # Alias -> (Leiste, Dose) wie in der Datei
GESCHUETZT = set()


def konfig_lesen():
    abschnitt = None
    try:
        zeilen = open(KONFIG, encoding="utf-8").read().splitlines()
    except OSError as e:
        sys.exit("Konfiguration fehlt: %s (make shziel bzw. /root/neuserver/leiste.conf)" % e)
    for nr, z in enumerate(zeilen, 1):
        z = z.split("#")[0].strip()
        if not z:
            continue
        if z.startswith("[") and z.endswith("]"):
            abschnitt = z[1:-1].strip().lower()
            continue
        teile = z.replace("=", " ").split()
        if abschnitt == "leisten" and len(teile) == 3:
            LEISTEN[teile[0].lower()] = (teile[1], teile[2])
        elif abschnitt == "aliase" and len(teile) == 3:
            ALIASE[teile[0].lower()] = (teile[1].lower(), teile[2].lower())
        elif abschnitt == "geschuetzt" and len(teile) == 1:
            GESCHUETZT.add(teile[0].lower())
        else:
            print("%s Zeile %d nicht verstanden: %s" % (KONFIG, nr, z), file=sys.stderr)


def leiste_finden(kurz):
    # eindeutige Abkuerzung erlaubt, z.B. "se" oder "a"
    treffer = [n for n in LEISTEN if n.startswith(kurz.lower())]
    if kurz.lower() in LEISTEN:
        return kurz.lower()
    if len(treffer) != 1:
        sys.exit("Unbekannte oder mehrdeutige Leiste '%s' (Leisten: %s; Aliase: %s)"
                 % (kurz, ", ".join(LEISTEN), ", ".join(ALIASE)))
    return treffer[0]


def alias_von(name, dps):
    for a, (l, d) in ALIASE.items():
        try:
            if leiste_finden(l) == name and DOSEN.get(d, (None,))[0] == dps:
                return a
        except SystemExit:
            pass
    return None


def hilfe(mit_konfig=False):
    print(__doc__.split("Einrichtung:")[0].rstrip())
    if mit_konfig:
        print("\nKonfiguration %s:" % KONFIG)
        for z in open(KONFIG, encoding="utf-8").read().splitlines():
            if z.strip() and not z.lstrip().startswith("#"):
                print("  " + z)


def schluessel():
    try:
        return {d["id"]: d["key"] for d in json.load(open(KEYDATEI))}
    except (OSError, ValueError, KeyError) as e:
        sys.exit("Schluessel fehlen (%s): %s - auf linux1 einrichten bzw. los.sh -kl, los.sh -tuya" % (KEYDATEI, e))


def verbinden(name):
    import tinytuya
    dev_id, ip = LEISTEN[name]
    keys = schluessel()
    if dev_id not in keys:
        sys.exit("Leiste %s fehlt in %s - steckdosenleiste.sh schluessel" % (name, KEYDATEI))
    dev = tinytuya.OutletDevice(dev_id, ip, keys[dev_id], version=3.3)
    dev.set_socketTimeout(5)
    return dev


def pruefen(antwort):
    if not antwort or "Error" in antwort:
        hinweis = {"901": " (App Smart Life geoeffnet? Leiste nicht im WLAN?)",
                   "904": " (Schluessel passt nicht: steckdosenleiste.sh schluessel)",
                   "914": " (Schluessel passt nicht: steckdosenleiste.sh schluessel)"}
        err = str((antwort or {}).get("Err"))
        sys.exit("Fehler: %s%s" % ((antwort or {}).get("Error", "keine Antwort"), hinweis.get(err, "")))
    return antwort


def bezeichnung(name, dps):
    g = alias_von(name, dps)
    return "%s (%s)" % (NAMEN[dps], g) if g else NAMEN[dps]


def status(name):
    dps = pruefen(verbinden(name).status())["dps"]
    zeilen = ["%s: %s" % (bezeichnung(name, k), "EIN" if dps[k] else "aus") for k in sorted(NAMEN) if k in dps]
    print("%-10s %s" % (name, " | ".join(zeilen)))


def main(argv):
    konfig_lesen()
    if not argv or argv[0] in ("-h", "--help", "hilfe"):
        if not argv:
            for name in LEISTEN:
                try:
                    status(name)
                except SystemExit as e:
                    print("%-10s %s" % (name, e))
            print()
        hilfe(mit_konfig=True)
        return
    if argv[0].lower() in ALIASE:
        argv = list(ALIASE[argv[0].lower()]) + argv[1:]
        if len(argv) == 2:
            argv.append("status")
    name = leiste_finden(argv[0])
    if argv[1:] in ([], ["status"]):
        return status(name)
    if len(argv) < 3 or argv[1].lower() not in DOSEN:
        hilfe()
        sys.exit(1)
    schalter, countdown = DOSEN[argv[1].lower()]
    befehl = argv[2].lower()
    if befehl == "status":
        dps = pruefen(verbinden(name).status())["dps"]
        return print("%s %s: %s" % (name, bezeichnung(name, schalter), "EIN" if dps.get(schalter) else "aus"))
    if befehl == "aus" and name in GESCHUETZT and "--wirklich" not in argv:
        sys.exit("%s %s: 'aus' bleibt aus, bis jemand per App/von Hand einschaltet - lieber 'neustart'. "
                 "Wenn wirklich gewollt: leiste %s %s aus --wirklich" % (name, bezeichnung(name, schalter), name, argv[1]))
    dev = verbinden(name)
    if befehl in ("ein", "aus"):
        pruefen(dev.set_value(schalter, befehl == "ein"))
        print("%s %s: %s" % (name, bezeichnung(name, schalter), befehl.upper()))
    elif befehl == "neustart":
        sek = int(argv[3]) if len(argv) > 3 and argv[3].isdigit() else 10
        # Aus + Countdown in einem Befehl: die Leiste schaltet selbst wieder ein,
        # auch wenn an der Dose die Netzwerkverbindung zu diesem Rechner haengt.
        pruefen(dev.set_multiple_values({schalter: False, countdown: sek}))
        print("%s %s: aus, schaltet in %d s selbst wieder ein" % (name, bezeichnung(name, schalter), sek))
    else:
        hilfe()
        sys.exit(1)


if __name__ == "__main__":
    main(sys.argv[1:])
