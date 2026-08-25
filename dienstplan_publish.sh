#!/bin/bash
# Wandelt den jeweils neuesten Dienstplan (*.doc) aus
# /DATA/Patientendokumente/Dienstplan/ in HTML um und veroeffentlicht ihn
# unter /srv/www/htdocs/fachliches/dienstplan/index.html (dort per
# Basic-Auth geschuetzt, siehe /etc/apache2/vhosts.d/fachliches-extern.conf).
# Wird per Cron alle 15 Minuten aufgerufen (/etc/cron.d/dienstplan-publish).
set -u

SRC_DIR="/DATA/Patientendokumente/Dienstplan"
STATE_DIR="/var/lib/dienstplan-publish"
STATE_FILE="$STATE_DIR/last_source"
OUT_DIR="/srv/www/htdocs/fachliches/dienstplan"
OUT_FILE="$OUT_DIR/index.html"
LOG="/var/log/dienstplan_publish.log"

log() { echo "$(date '+%F %T') $*" >>"$LOG"; }

mountpoint -q /DATA || exit 0

mkdir -p "$STATE_DIR" "$OUT_DIR"

# Neueste passende Datei suchen (Muster: enthaelt "dienstplan", endet auf
# .doc), Word-/LO-Sperr- und Temporaerdateien (beginnen mit ~) ausschliessen.
latest=$(find "$SRC_DIR" -maxdepth 1 -type f -iname "*dienstplan*.doc" -not -name "~*" -printf '%T@ %p\n' 2>/dev/null \
    | sort -rn | head -1 | cut -d' ' -f2-)

if [ -z "$latest" ]; then
    exit 0
fi

# Wird die Datei gerade in Word bearbeitet (Sperrdatei "~$<name>" vorhanden)?
# Dann in diesem Lauf nichts tun, beim naechsten Mal erneut versuchen.
lockfile="$(dirname "$latest")/~\$$(basename "$latest")"
if [ -e "$lockfile" ]; then
    exit 0
fi

last=""
[ -f "$STATE_FILE" ] && last=$(cat "$STATE_FILE" 2>/dev/null)
current_marker="$latest|$(stat -c %Y "$latest" 2>/dev/null)"
if [ "$current_marker" = "$last" ]; then
    exit 0
fi

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

if ! timeout 90 /usr/bin/soffice --headless --norestore --convert-to html --outdir "$tmp_dir" "$latest" >>"$LOG" 2>&1; then
    log "FEHLER: Konvertierung von '$latest' fehlgeschlagen"
    exit 1
fi

converted="$tmp_dir/$(basename "${latest%.*}").html"
if [ ! -f "$converted" ]; then
    log "FEHLER: erwartete Ausgabedatei '$converted' fehlt"
    exit 1
fi

# Style-Regeln (p.western usw.) und den Koerper der LibreOffice-Ausgabe
# herausloesen (nur der Inhalt, ohne die <style>/<body>-Tags selbst) und in
# unsere Seitenvorlage einbetten.
styles=$(sed -n '/<style/,/<\/style>/p' "$converted" | sed '1s/^[[:space:]]*<style[^>]*>//' | sed '$s/<\/style>[[:space:]]*$//')
body_inner=$(sed -n '/<body/,/<\/body>/p' "$converted" | sed '1s/^[[:space:]]*<body[^>]*>//' | sed '$s/<\/body>[[:space:]]*$//')
stand=$(date -d "@$(stat -c %Y "$latest")" '+%d.%m.%Y %H:%M')

out_tmp="$tmp_dir/index.html.out"
cat > "$out_tmp" <<HTMLEOF
<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8">
<title>Dienstplan</title>
<style>
  :root {
    --header-bg: #1f6f8b;
    --header-bg2: #123f50;
    --header-fg: #ffffff;
    --page-bg: #eef4f6;
    --text: #1b2530;
    --border: #bcd6e0;
  }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    font-family: "Liberation Sans", Arial, sans-serif;
    color: var(--text);
    background: var(--page-bg);
  }
  .topbar {
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
  }
  .topbar nav a:hover { background: #ffe9b3; color: #6b4a00; border-color: #ffe9b3; }
  .stand {
    max-width: 62rem;
    margin: 0.8rem auto 0 auto;
    font-size: 0.8rem;
    color: #506672;
  }
  .content-wrap {
    max-width: 62rem;
    margin: 0.5rem auto 2rem auto;
    padding: 1rem;
    overflow-x: auto;
    background: #ffffff;
    border: 1px solid var(--border);
    border-radius: 8px;
  }
  .content-wrap table { border-collapse: collapse; }
$styles
</style>
</head>
<body>
<div class="topbar">
  <h1>Dienstplan</h1>
  <nav><a href="../index.html">Fachliches</a></nav>
</div>
<p class="stand">Stand: $stand</p>
<div class="content-wrap">
$body_inner
</div>
</body>
</html>
HTMLEOF

install -m 644 -o wwwrun -g www "$out_tmp" "$OUT_FILE"
restorecon "$OUT_FILE" >/dev/null 2>&1

echo "$current_marker" > "$STATE_FILE"
log "OK: '$latest' veroeffentlicht"
