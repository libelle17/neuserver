#!/opt/tinytuya/bin/python
"""Steuerung der Tuya-Steckdosenleisten (Logilink Smart Power Strip SH0104) im Praxisnetz.

Aufruf:
  leiste                                   Status aller Leisten und diese Hilfe
  leiste <leiste> [status]                 Status einer Leiste
  leiste <leiste> <dose> ein|aus
  leiste <leiste> <dose> neustart [sek]    aus, nach sek Sekunden (Standard 10) schaltet
                                           die Leiste selbst wieder ein

  <leiste>: serverraum | anmeldung | sz2   (eindeutige Abkuerzung genuegt: se, a, sz)
  <dose>:   1-4 | usb

Vorher die App "Smart Life" auf allen Handys im WLAN ganz schliessen - die Leiste
erlaubt nur eine Verbindung (sonst Fehler 901).
Einrichtung: los.sh -tuya; Schluessel in /root/tinytuya/devices.json (nicht anzeigen/weitergeben),
nach Neueinrichtung einer Leiste in der App: steckdosenleiste.sh schluessel.
Von szn4 (Windows-Konto sturm): leiste.bat mit "@ssh linux1 sudo /usr/local/bin/leiste %*".
"""
import json, sys

KEYDATEI = "/root/tinytuya/devices.json"
LEISTEN = {
    "serverraum": ("0031545070039f0e28e4", "192.168.178.73"),
    "anmeldung":  ("0031545070039f0e7f1f", "192.168.178.76"),
    "sz2":        ("0031545070039f0ecb14", "192.168.178.159"),
}
# Was an den Dosen haengt (s. Sicherungskonzept Abschnitt 8); fehlt ein Eintrag, nur "Dose n"
GERAETE = {
    "serverraum": {"1": "linux0", "2": "linux1", "3": "KoCoBox", "4": "Telefonanlage"},
}
# Datenpunkte: Schalter und zugehoeriger Countdown (Countdown schaltet nach Ablauf um)
DOSEN = {"1": ("1", "9"), "2": ("2", "10"), "3": ("3", "11"), "4": ("4", "12"), "usb": ("5", "13")}
NAMEN = {"1": "Dose 1", "2": "Dose 2", "3": "Dose 3", "4": "Dose 4", "5": "USB"}
# "aus" hier nur mit --wirklich: ohne Strom kaeme die Dose nur per App/von Hand wieder an
KRITISCH = {("serverraum", "1"), ("serverraum", "2"), ("serverraum", "3"), ("serverraum", "4")}


def hilfe():
    print(__doc__.split("Einrichtung:")[0].rstrip())


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
    g = GERAETE.get(name, {}).get(dps)
    return "%s (%s)" % (NAMEN[dps], g) if g else NAMEN[dps]


def status(name):
    dps = pruefen(verbinden(name).status())["dps"]
    zeilen = ["%s: %s" % (bezeichnung(name, k), "EIN" if dps[k] else "aus") for k in sorted(NAMEN) if k in dps]
    print("%-10s %s" % (name, " | ".join(zeilen)))


def main(argv):
    if not argv or argv[0] in ("-h", "--help", "hilfe"):
        if not argv:
            for name in LEISTEN:
                try:
                    status(name)
                except SystemExit as e:
                    print("%-10s %s" % (name, e))
            print()
        hilfe()
        return
    # eindeutige Abkuerzung erlaubt, z.B. "se" oder "a"
    treffer = [n for n in LEISTEN if n.startswith(argv[0].lower())]
    if len(treffer) != 1:
        sys.exit("Unbekannte oder mehrdeutige Leiste '%s' (moeglich: %s)" % (argv[0], ", ".join(LEISTEN)))
    name = treffer[0]
    if argv[1:] in ([], ["status"]):
        return status(name)
    if len(argv) < 3 or argv[1].lower() not in DOSEN:
        hilfe()
        sys.exit(1)
    schalter, countdown = DOSEN[argv[1].lower()]
    befehl = argv[2].lower()
    if befehl == "aus" and (name, schalter) in KRITISCH and "--wirklich" not in argv:
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
