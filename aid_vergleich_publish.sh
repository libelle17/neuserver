#!/bin/bash
# aid_vergleich_publish.sh - wandelt eine AID-Vergleich-ODS-Datei (Blatt
# "Tabelle1", fixierte erste Zeile/Spalte in Calc) nach
# /srv/www/htdocs/fachliches/aid-vergleich.html um, im selben Design wie
# die HbA1c-Umrechnung/Dienstplan-Seiten (sticky Kopfzeile+erste Spalte,
# farbige Abschnitts-Trennzeilen).
#
# Aufruf: aid_vergleich_publish.sh ["/Pfad/zur/Datei.ods"]
# Ohne Argument: nimmt automatisch die zuletzt geaenderte Datei nach dem
# Muster "AID-Vergleich*.ods" in "/DATA/eigene Dateien/DM/".
set -euo pipefail

QUELLVERZ="/DATA/eigene Dateien/DM"
ZIEL="/srv/www/htdocs/fachliches/aid-vergleich.html"

if [ $# -ge 1 ]; then
  ods="$1"
else
  ods=$(find "$QUELLVERZ" -maxdepth 1 -type f -iname "AID-Vergleich*.ods" -not -name "~*" -printf '%T@ %p\n' 2>/dev/null \
    | sort -rn | head -1 | cut -d' ' -f2-)
fi

if [ -z "$ods" ]; then
  echo "Keine Datei nach Muster \"AID-Vergleich*.ods\" in \"$QUELLVERZ\" gefunden." >&2
  echo "Aufruf mit explizitem Pfad moeglich: $0 \"/Pfad/zur/Datei.ods\"" >&2
  exit 1
fi
if [ ! -f "$ods" ]; then
  echo "Datei nicht gefunden: $ods" >&2
  exit 1
fi

echo "Quelle: $ods"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

if ! out=$(soffice --headless --norestore --convert-to 'html:HTML (StarCalc)' --outdir "$tmp" "$ods" 2>&1); then
  echo "Konvertierung fehlgeschlagen:" >&2
  echo "$out" >&2
  exit 1
fi

converted="$tmp/$(basename "${ods%.*}").html"
if [ ! -f "$converted" ]; then
  echo "Erwartete Ausgabedatei fehlt: $converted" >&2
  echo "$out" >&2
  exit 1
fi

python3 - "$converted" "$tmp/out.html" <<'PYEOF'
import sys
from html.parser import HTMLParser
from html import escape

src, outpath = sys.argv[1], sys.argv[2]

class TableParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.rows = []
        self.cur_row = None
        self.cur_cell = None
        self.in_td = False
        self.bold_depth = 0

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "tr":
            self.cur_row = []
        elif tag == "td":
            self.in_td = True
            self.cur_cell = {"text": "", "bold": False, "border_top": False}
            if "border-top" in attrs.get("style", ""):
                self.cur_cell["border_top"] = True
        elif tag == "b" and self.in_td:
            self.bold_depth += 1

    def handle_endtag(self, tag):
        if tag == "tr" and self.cur_row is not None:
            self.rows.append(self.cur_row)
            self.cur_row = None
        elif tag == "td":
            self.in_td = False
            self.cur_row.append(self.cur_cell)
            self.cur_cell = None
        elif tag == "b" and self.in_td:
            self.bold_depth = max(0, self.bold_depth - 1)

    def handle_data(self, data):
        if self.in_td:
            self.cur_cell["text"] += data
            if self.bold_depth > 0:
                self.cur_cell["bold"] = True

with open(src, encoding="utf-8") as f:
    p = TableParser()
    p.feed(f.read())

cleaned = [r for r in p.rows if any(c["text"].strip() for c in r)]
if not cleaned:
    print("Keine Datenzeilen gefunden - Tabelle leer?", file=sys.stderr)
    sys.exit(1)

n_cols = max(len(r) for r in cleaned)

def cell_html(c, is_first_col):
    text = c["text"].strip()
    classes = []
    if c["bold"]:
        classes.append("bold")
    if c["border_top"]:
        classes.append("sep")
    if is_first_col:
        classes.append("rowhead")
    cls = f' class="{" ".join(classes)}"' if classes else ""
    return f"<td{cls}>{escape(text)}</td>"

body_rows_html = []
for r in cleaned:
    cells = []
    for i in range(n_cols):
        c = r[i] if i < len(r) else {"text": "", "bold": False, "border_top": False}
        cells.append(cell_html(c, i == 0))
    body_rows_html.append("<tr>" + "".join(cells) + "</tr>")

header_row = cleaned[0]
header_cells = []
for i in range(n_cols):
    c = header_row[i] if i < len(header_row) else {"text": ""}
    header_cells.append(f"<th>{escape(c['text'].strip())}</th>")
header_html = "<tr>" + "".join(header_cells) + "</tr>"
body_html = "\n".join(body_rows_html[1:])

template = """<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8">
<title>AID-Vergleich</title>
<style>
  :root {
    --header-bg: #1f6f8b;
    --header-bg2: #123f50;
    --header-fg: #ffffff;
    --rowhead-bg: #dcedf3;
    --rowhead-fg: #123f50;
    --section-bg: #ffe9b3;
    --section-border: #e0a300;
    --section-fg: #6b4a00;
    --row-alt: #eaf5f9;
    --row-hover: #fff3cf;
    --border: #bcd6e0;
    --text: #1b2530;
    --page-bg: #eef4f6;
  }
  * { box-sizing: border-box; }
  html, body { height: 100%; margin: 0; }
  body {
    display: flex;
    flex-direction: column;
    font-family: "Liberation Sans", Arial, sans-serif;
    color: var(--text);
    background: var(--page-bg);
  }
  .topbar {
    flex: 0 0 auto;
    background: linear-gradient(90deg, var(--header-bg), var(--header-bg2));
    color: var(--header-fg);
    padding: 0.6rem 1rem;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
    box-shadow: 0 2px 4px rgba(0,0,0,0.2);
  }
  .topbar h1 { font-size: 1.1rem; margin: 0; font-weight: 600; }
  .topbar nav a {
    color: var(--header-fg);
    text-decoration: none;
    background: rgba(255,255,255,0.15);
    border: 1px solid rgba(255,255,255,0.5);
    border-radius: 4px;
    padding: 0.35rem 0.8rem;
    font-size: 0.85rem;
    margin-left: 0.4rem;
  }
  .topbar nav a:hover {
    background: var(--section-bg);
    color: var(--section-fg);
    border-color: var(--section-bg);
  }
  .table-wrap {
    flex: 1 1 auto;
    min-height: 0;
    overflow: auto;
    margin: 1rem;
    border: 1px solid var(--border);
    border-radius: 8px;
    background: #ffffff;
    box-shadow: 0 1px 3px rgba(0,0,0,0.12);
  }
  table { border-collapse: separate; border-spacing: 0; font-size: 0.85rem; white-space: nowrap; }
  th, td {
    padding: 0.35rem 0.6rem;
    border-right: 1px solid var(--border);
    border-bottom: 1px solid var(--border);
    text-align: left;
    vertical-align: top;
  }
  thead th {
    position: sticky; top: 0; z-index: 20;
    background: linear-gradient(180deg, var(--header-bg), var(--header-bg2));
    color: var(--header-fg);
    font-weight: 600;
    white-space: normal;
    min-width: 9rem;
    max-width: 16rem;
  }
  td.rowhead, thead th:first-child {
    position: sticky; left: 0; z-index: 10;
    background: var(--rowhead-bg);
    color: var(--rowhead-fg);
    font-weight: 600;
    white-space: normal;
    min-width: 12rem;
    max-width: 18rem;
  }
  thead th:first-child { z-index: 25; background: var(--header-bg2); color: var(--header-fg); }
  tbody tr:nth-child(even) td:not(.rowhead) { background: var(--row-alt); }
  tbody tr:hover td:not(.rowhead) { background: var(--row-hover); }
  tbody tr:hover td.rowhead { background: #c3e0ec; }
  td.bold { font-weight: 600; }
  td.sep { border-top: 2px solid var(--section-border); background: var(--section-bg); color: var(--section-fg); }
  footer.pagefoot {
    max-width: 900px;
    margin: 0.6rem 0 0;
    padding: 0.6rem 1rem 1.2rem;
    font-size: 0.72rem;
    line-height: 1.5;
    color: #4d5a63;
    border-top: 1px solid var(--border);
  }
  footer.pagefoot .fnav { margin: 0 0 0.6rem; }
  footer.pagefoot .imp { margin-top: 0.9rem; padding-top: 0.8rem; border-top: 1px solid var(--border); }
  footer.pagefoot .imp:first-of-type { margin-top: 0; padding-top: 0; border-top: none; }
  footer.pagefoot h2 { font-size: 0.85rem; color: var(--text); margin: 0 0 0.4rem; }
  footer.pagefoot h3 { font-size: 0.72rem; color: var(--text); margin: 0.6rem 0 0.15rem; }
  footer.pagefoot p { margin: 0 0 0.4rem; }
  footer.pagefoot a { color: var(--header-bg2); }
</style>
</head>
<body>
<div class="topbar">
  <h1>AID-Vergleich &ndash; Insulinpumpen</h1>
  <nav><a href="index.html">Fachliches</a></nav>
</div>
<div class="table-wrap">
<table>
<thead>
__HEADER__
</thead>
<tbody>
__BODY__
</tbody>
</table>
<footer class="pagefoot">
<p class="fnav"><a href="#impressum">Impressum</a> &middot; <a href="#datenschutz">Datenschutz</a></p>

<section class="imp" id="impressum">
<h2>Impressum</h2>

<h3>Angaben gem&auml;&szlig; &sect; 5 DDG</h3>
<p>Gerald Schade<br>
Mittermayerstra&szlig;e 13<br>
85221 Dachau<br>
Deutschland</p>

<h3>Kontakt</h3>
<p>Telefon: <a href="tel:+498131616380">08131 616380</a><br>
E-Mail: <a href="mailto:gerald.schade@gmail.com">gerald.schade@gmail.com</a></p>

<h3>Berufsbezeichnung und berufsrechtliche Regelungen</h3>
<p>Gesetzliche Berufsbezeichnung: Arzt, verliehen in der Bundesrepublik Deutschland<br>
Facharzt f&uuml;r Innere Medizin, Angiologie, Diabetologie<br>
Zust&auml;ndige Kammer: Bayerische Landes&auml;rztekammer,
M&uuml;hlbaurstra&szlig;e 16, 81677 M&uuml;nchen<br>
Berufsrechtliche Regelungen: Berufsordnung f&uuml;r die &Auml;rzte Bayerns sowie
Heilberufe-Kammergesetz (HKaG) des Freistaats Bayern<br>
Einsehbar unter:
<a href="https://www.blaek.de/kammerrecht/berufsordnung-fuer-die-aerzte-bayerns" target="_blank" rel="noopener">blaek.de/kammerrecht/berufsordnung-fuer-die-aerzte-bayerns</a></p>

<h3>Verantwortlich f&uuml;r den Inhalt nach &sect; 18 Abs. 2 MStV</h3>
<p>Gerald Schade, Anschrift wie oben</p>

<h3>Haftung f&uuml;r Inhalte</h3>
<p>Die Inhalte dieser Seite wurden mit Sorgfalt erstellt. F&uuml;r die Richtigkeit, Vollst&auml;ndigkeit
und Aktualit&auml;t der Inhalte wird jedoch keine Gew&auml;hr &uuml;bernommen. Als Diensteanbieter bin ich
gem&auml;&szlig; &sect; 7 Abs. 1 DDG f&uuml;r eigene Inhalte auf diesen Seiten nach den allgemeinen Gesetzen
verantwortlich; nach &sect;&sect; 8 bis 10 DDG bin ich als Diensteanbieter jedoch nicht verpflichtet,
&uuml;bermittelte oder gespeicherte fremde Informationen zu &uuml;berwachen oder nach Umst&auml;nden zu
forschen, die auf eine rechtswidrige T&auml;tigkeit hinweisen.</p>

<h3>Haftung f&uuml;r Links</h3>
<p>Diese Seite enth&auml;lt gegebenenfalls Links zu externen Websites Dritter, auf deren Inhalte
kein Einfluss besteht. F&uuml;r die Inhalte der verlinkten Seiten ist stets der jeweilige Anbieter
oder Betreiber der Seiten verantwortlich.</p>

<h3>Urheberrecht</h3>
<p>Die durch den Seitenbetreiber erstellten Inhalte und Werke auf diesen Seiten unterliegen
dem deutschen Urheberrecht. Beitr&auml;ge Dritter sind als solche gekennzeichnet.</p>

<h3>Medizinischer Hinweis</h3>
<p>Dieses Angebot richtet sich an medizinische Fachkreise (&Auml;rztinnen und &Auml;rzte,
Diabetesberaterinnen und -berater). Diese Seite dient ausschlie&szlig;lich der
Information und Fortbildung. Sie stellt keine
medizinische Beratung dar und ersetzt weder die &auml;rztliche Betreuung noch die Gebrauchsanweisung
des jeweiligen AID-Systems.</p>
</section>

<section class="imp" id="datenschutz">
<h2>Datenschutzerkl&auml;rung</h2>

<h3>1. Verantwortlicher</h3>
<p>Verantwortlicher im Sinne des Art. 4 Nr. 7 DSGVO ist:<br>
Gerald Schade, Mittermayerstra&szlig;e 13, 85221 Dachau, Deutschland<br>
Telefon: 08131 616380 &middot; E-Mail:
<a href="mailto:gerald.schade@gmail.com">gerald.schade@gmail.com</a></p>

<h3>2. Umfang der Verarbeitung</h3>
<p>Diese Seite ist eine rein statische HTML-Seite. Sie setzt keine Cookies, bindet keine
externen Schriften, Skripte oder sonstigen Inhalte Dritter ein und f&uuml;hrt keine Reichweiten-
oder Nutzungsanalyse durch. Es besteht keine Registrierung und kein Nutzerkonto; es werden
keine Formulardaten erhoben.</p>

<h3>3. Server-Logfiles</h3>
<p>Die Seite wird auf einem selbst betriebenen Server gehostet. Beim Abruf der Seite
verarbeitet der Webserver technisch notwendige Zugriffsdaten, insbesondere IP-Adresse,
Datum und Uhrzeit des Abrufs, die abgerufene Datei, &uuml;bertragene Datenmenge, Referrer-URL
sowie Browsertyp und Betriebssystem.</p>
<p>Rechtsgrundlage ist Art. 6 Abs. 1 lit. f DSGVO. Das berechtigte Interesse liegt in der
sicheren, stabilen und st&ouml;rungsfreien Bereitstellung des Angebots sowie der Abwehr von
Angriffen. Eine Auswertung dieser Daten zu Analyse-, Profilbildungs- oder Marketingzwecken
findet nicht statt; die Logdateien werden automatisiert nach sp&auml;testens 12 Monaten
gel&ouml;scht.</p>

<h3>4. Kontaktaufnahme</h3>
<p>Wenn Sie per E-Mail oder Telefon Kontakt aufnehmen, werden die von Ihnen mitgeteilten
Daten zur Bearbeitung Ihres Anliegens verarbeitet. Rechtsgrundlage ist Art. 6 Abs. 1 lit. f
DSGVO, bei vertragsbezogenen Anfragen Art. 6 Abs. 1 lit. b DSGVO. Die Daten werden
gel&ouml;scht, sobald die Anfrage abschlie&szlig;end bearbeitet ist und keine gesetzlichen
Aufbewahrungspflichten entgegenstehen.</p>

<h3>5. Ihre Rechte</h3>
<p>Sie haben das Recht auf Auskunft (Art. 15 DSGVO), Berichtigung (Art. 16 DSGVO), L&ouml;schung
(Art. 17 DSGVO), Einschr&auml;nkung der Verarbeitung (Art. 18 DSGVO) und Daten&uuml;bertragbarkeit
(Art. 20 DSGVO) sowie das Recht, der Verarbeitung auf Grundlage von Art. 6 Abs. 1 lit. f
DSGVO aus Gr&uuml;nden Ihrer besonderen Situation zu widersprechen (Art. 21 DSGVO). Wenden Sie
sich dazu an die oben genannten Kontaktdaten.</p>

<h3>6. Beschwerderecht</h3>
<p>Sie haben das Recht, sich bei einer Datenschutz-Aufsichtsbeh&ouml;rde zu beschweren
(Art. 77 DSGVO). Zust&auml;ndig ist das Bayerische Landesamt f&uuml;r Datenschutzaufsicht (BayLDA),
Promenade 27, 91522 Ansbach.</p>
</section>
</footer>
</div>
</body>
</html>
"""

out = template.replace("__HEADER__", header_html).replace("__BODY__", body_html)
with open(outpath, "w", encoding="utf-8") as f:
    f.write(out)
print(f"Zeilen: {len(cleaned)}, Spalten: {n_cols}", file=sys.stderr)
PYEOF

install -m 644 -o wwwrun -g www "$tmp/out.html" "$ZIEL"
command -v restorecon >/dev/null 2>&1 && restorecon "$ZIEL" >/dev/null 2>&1 || true

echo "Veroeffentlicht: $ZIEL"
