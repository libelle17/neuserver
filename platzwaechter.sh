#!/bin/bash
# platzwaechter.sh - haelt auf einem Snapper-verwalteten btrfs-/DATA (Reserver linux0) Platz frei, indem er
# die AELTESTEN Snapshots einzeln loescht, bevor die Platte vollaeuft.
#
# Anlass (21.9.2026): /DATA auf linux0 lief mit 90 MiB frei voll. Die Tagesaenderungen der nachts gespiegelten
# Daten (grob 100-170 GB/Tag) bleiben in den Snapshots haengen; Snapper-Cleanup greift beim freien Platz nicht
# ein (FREE_LIMIT stand auf 0.2, QGROUP ist leer, Ursache ungeklaert), und die Platzvorpruefung in kopiermt()
# (bugem.sh) kennt den von Snapshots festgehaltenen Platz nicht.
#
# Ablauf: freien Platz von $MP messen (df). Ab MIN_FREI % oder mehr: nichts tun. Darunter: Snapshots der Config
# $CFG von alt nach neu je einzeln mit "snapper delete --sync" loeschen, nach jedem neu messen, bis ZIEL_FREI %
# frei sind. Jedes Loeschen wird gemailt.
# Schutz (nie geloescht):
#   - alle Snapshots der neuesten BEHALTE_TAGE Kalendertage, an denen es Snapshots gibt (Rechner ist oft tagelang
#     aus; "Tage mit Snapshots" statt "letzte 3 Tage"). Sie sind das Netz gegen gespiegelte Loeschungen/Verschluesselung.
#   - Snapshots, die nicht von Snapper selbst stammen (Bereinigungsalgorithmus weder timeline noch number)
# Sperre: faellt der freie Platz seit dem letzten Lauf (<= 6 h her) um mehr als MAX_SPRUNG_GB, wird NICHT geloescht,
# sondern gemailt und fuer SPERRE_STUNDEN gesperrt. Grund: bei Verschluesselung auf der Quelle wuerde der Waechter
# sonst genau die Snapshots mit den unverschluesselten Originalen loeschen. Aufheben: rm $ZUSTAND/gesperrt_bis
# Mails: Loeschungen immer; Sperre/KRITISCH (nichts mehr loeschbar) hoechstens alle 24 h.
#
# Aufruf:  platzwaechter.sh [-n] [-s] [-t] [-v]
#   -n   Anzeigemodus: nichts loeschen, nichts mailen, Zustand nicht veraendern
#   -s   Status (Messwert, letzter Lauf, Sperre, Kandidaten); wie -n
#   -t   Testmail senden (Betreff mit TEST)
#   -v   Verbrauchsuebersicht je Tag aus $VERBRAUCH (Verbrauch/Freigabe in GiB, davon nachts 21-07 Uhr); nur lesend
# Rechner ohne Snapper-Config "$CFG" oder ohne eingehaengtes $MP: tut nichts (Exitcode 0).
# Einstellungen per Umgebung: PW_MIN_FREI_PROZENT (8), PW_ZIEL_FREI_PROZENT (12), PW_BEHALTE_TAGE (3),
# PW_MAX_SPRUNG_GB (250), PW_SPERRE_STUNDEN (24), PW_CONFIG (data), PW_MOUNT (/DATA), PW_ZUSTAND (/var/lib/platzwaechter).
# Verbrauchsprotokoll: bei jedem echten Lauf ggf. eine Zeile nach $VERBRAUCH (PW_VERBRAUCH, Vorgabe
# /var/log/platzwaechter_verbrauch.csv): zeit;frei_bytes;frei_prozent;snapshots;geloescht - geschrieben bei der ersten Zeile,
# bei neuer Stunde, bei Aenderung des freien Platzes um >= 1 GiB und nach jedem Loeschen. Grundlage, um die Schwellen und die
# Aufbewahrung (snapper TIMELINE_LIMIT_*) aus Messwerten statt Schaetzungen festzulegen (Stand 21.9.2026: ~100-170 GB/Tag geschaetzt).
# Empfaenger: PW_EMPFAENGER ueberschreibt die Praxisadresse (z.B. fuer "-t" an eine eigene Adresse).
# Testhilfen: PW_LISTE_DATEI (Snapshotliste als CSV statt snapper), PW_MAILDATEI (Mails dorthin statt versenden).
EMPFAENGER=${PW_EMPFAENGER:-diabetologie@dachau-mail.de}
VERBRAUCH=${PW_VERBRAUCH:-/var/log/platzwaechter_verbrauch.csv}
CFG=${PW_CONFIG:-data}
MP=${PW_MOUNT:-/DATA}
MIN_FREI=${PW_MIN_FREI_PROZENT:-8}
ZIEL_FREI=${PW_ZIEL_FREI_PROZENT:-12}
BEHALTE_TAGE=${PW_BEHALTE_TAGE:-3}
MAX_SPRUNG_GB=${PW_MAX_SPRUNG_GB:-250}
SPERRE_H=${PW_SPERRE_STUNDEN:-24}
ZUSTAND=${PW_ZUSTAND:-/var/lib/platzwaechter}
NUR_ANZEIGEN=; STATUS=; TESTMAIL=; UEBERSICHT=
for a in "$@"; do case "$a" in -n) NUR_ANZEIGEN=1;; -s) STATUS=1; NUR_ANZEIGEN=1;; -t) TESTMAIL=1;; -v) UEBERSICHT=1;; *) sed -n '2,40p' "$0"; exit 1;; esac; done

log() { printf '%s %s\n' "$(date '+%F %T')" "$*"; }
gib() { LC_ALL=C awk -v b="$1" 'BEGIN{printf "%.1f", b/1073741824}'; }
mailen() { # Betreff Text
  [ -n "$NUR_ANZEIGEN" ] && { log "(keine Mail im Anzeigemodus: $1)"; return 0; }
  local text="$2"$'\n\n'"(platzwaechter.sh auf $(hostname), $(date '+%d.%m.%Y %H:%M'))"
  if [ -n "$PW_MAILDATEI" ]; then printf 'BETREFF: %s\n%s\n---\n' "$1" "$text" >>"$PW_MAILDATEI"
  else printf '%s\n' "$text" | mail -s "$1" "$EMPFAENGER"; fi
}
mailen_selten() { # Schluessel Betreff Text - hoechstens alle 24 h
  local f="$ZUSTAND/mail_$1" t
  t=$(cat "$f" 2>/dev/null); [ -n "$t" ] && [ $(( $(date +%s) - t )) -lt 86400 ] && return 0
  mailen "$2" "$3"; [ -z "$NUR_ANZEIGEN" ] && date +%s >"$f"; return 0
}
frei_messen() { # setzt FREI_B, GROESSE_B, FREI_P (ganzzahlig, abgerundet)
  set -- $(df -B1 --output=avail,size "$MP" | tail -1)
  FREI_B=$1; GROESSE_B=$2; FREI_P=$(( FREI_B * 100 / GROESSE_B ))
}
verbrauch_zeile() { # Anzahl_geloescht: protokolliert (s. Kopf), nur im echten Lauf
  [ -n "$NUR_ANZEIGEN" ] && return 0
  local zeit letzt lz lb n=0
  zeit=$(date '+%F %T'); [ -f "$VERBRAUCH" ] || echo "zeit;frei_bytes;frei_prozent;snapshots;geloescht" >"$VERBRAUCH" 2>/dev/null || return 0
  letzt=$(tail -n 1 "$VERBRAUCH" 2>/dev/null); lz=$(printf '%s' "$letzt" | cut -d';' -f1); lb=$(printf '%s' "$letzt" | cut -d';' -f2)
  if [ "$1" -gt 0 ] || [ "$lz" = zeit ] || [ -z "$lb" ] || [ "${lz:0:13}" != "${zeit:0:13}" ] \
     || [ $(( lb > FREI_B ? lb - FREI_B : FREI_B - lb )) -ge 1073741824 ]; then
    n=$(liste | wc -l); printf '%s;%s;%s;%s;%s\n' "$zeit" "$FREI_B" "$FREI_P" "$n" "$1" >>"$VERBRAUCH"
  fi
  return 0
}
verbrauch_uebersicht() { # je Tag: Verbrauch (Rueckgang des freien Platzes), Freigabe (Anstieg), davon nachts; aus den Protokollzeilen
  [ -f "$VERBRAUCH" ] || { echo "kein Verbrauchsprotokoll ($VERBRAUCH)"; return 0; }
  LC_ALL=C awk -F';' 'NR>1 && $1!="zeit" {
      d=substr($1,1,10); h=substr($1,12,2)+0; nacht=(h>=21||h<7)
      if (have) { delta=prev-$2; if (delta>0) { v[d]+=delta; if (nacht) vn[d]+=delta } else { f[d]-=delta } }
      prev=$2; have=1; ende[d]=$2; l[d]+=$5; tage[d]=1 }
    END { printf "%-10s %12s %12s %12s %10s %12s\n","Tag","Verbrauch","davon nachts","Freigabe","geloescht","frei am Ende"
      n=asort_keys(tage, k); for(i=1;i<=n;i++){d=k[i]; printf "%-10s %9.1f GiB %9.1f GiB %9.1f GiB %10d %9.1f GiB\n", d, v[d]/1073741824, vn[d]/1073741824, f[d]/1073741824, l[d], ende[d]/1073741824} }
    function asort_keys(a,k,  i,n,x,j,t){ n=0; for(x in a) k[++n]=x; for(i=2;i<=n;i++){t=k[i]; for(j=i-1;j>=1&&k[j]>t;j--)k[j+1]=k[j]; k[j+1]=t} return n }' "$VERBRAUCH"
  echo "(Zeilen nur bei Stundenwechsel/Aenderung >= 1 GiB/Loeschen; Verbrauch und Freigabe sind Nettoaenderungen zwischen den Zeilen)"
}
liste() { # Snapshotzeilen "nummer;typ;datum;cleanup" (ohne Kopf, ohne Nr. 0)
  { if [ -n "$PW_LISTE_DATEI" ]; then cat "$PW_LISTE_DATEI"
    else snapper -c "$CFG" --iso --machine-readable csv --separator ';' list --columns number,type,date,cleanup 2>/dev/null; fi; } \
  | awk -F';' 'NR>1 && $1+0>0 && $3!=""'
}
geschuetzte_tage() { liste | awk -F';' '{print substr($3,1,10)}' | sort -u | tail -n "$BEHALTE_TAGE" | tr '\n' ' '; }
kandidaten() { # "nummer;datum", aelteste zuerst, ohne geschuetzte Tage und fremde Snapshots
  local g; g=$(geschuetzte_tage)
  liste | sort -t';' -k3,3 -k1,1n | awk -F';' -v g="$g" 'BEGIN{n=split(g,a," "); for(i=1;i<=n;i++) s[a[i]]=1}
    ($4=="timeline"||$4=="number") && !(substr($3,1,10) in s) {print $1";"$3}'
}

[ -n "$UEBERSICHT" ] && { verbrauch_uebersicht; exit 0; }
command -v snapper >/dev/null 2>&1 || exit 0
snapper -c "$CFG" get-config >/dev/null 2>&1 || exit 0
mountpoint -q "$MP" || exit 0
[ -n "$NUR_ANZEIGEN" ] || mkdir -p "$ZUSTAND"
if [ -n "$TESTMAIL" ]; then mailen "TEST Platzwaechter $(hostname)" "Testmail von platzwaechter.sh."; exit 0; fi
if [ -z "$NUR_ANZEIGEN" ]; then exec 9>"$ZUSTAND/lock"; flock -n 9 || { log "laeuft schon"; exit 0; }; fi

JETZT=$(date +%s); SPRUNG=
frei_messen
if [ -n "$STATUS" ]; then
  log "$MP: frei $(gib $FREI_B) von $(gib $GROESSE_B) GiB = $FREI_P % (Schwelle $MIN_FREI %, Ziel $ZIEL_FREI %)"
  [ -f "$ZUSTAND/letzt" ] && { read -r t b p <"$ZUSTAND/letzt"; log "letzter Lauf: $(date -d "@$t" '+%F %T'), frei damals $(gib $b) GiB = $p %"; }
  [ -f "$ZUSTAND/gesperrt_bis" ] && log "Sperre bis $(date -d "@$(cat "$ZUSTAND/gesperrt_bis")" '+%F %T')"
  log "geschuetzte Tage:$(geschuetzte_tage)"; log "loeschbare Kandidaten (aelteste zuerst): $(kandidaten | tr '\n' ' ')"
  exit 0
fi

# 1) auffaelliger Verbrauch seit dem letzten Lauf?
if [ -f "$ZUSTAND/letzt" ]; then
  read -r t b p <"$ZUSTAND/letzt"
  if [ -n "$t" ] && [ $(( JETZT - t )) -le 21600 ] && [ $(( b - FREI_B )) -gt $(( MAX_SPRUNG_GB * 1073741824 )) ]; then
    SPRUNG=1
    log "AUFFAELLIG: frei fiel seit $(date -d "@$t" '+%H:%M') von $(gib $b) auf $(gib $FREI_B) GiB - Loeschen gesperrt"
    if [ -z "$NUR_ANZEIGEN" ]; then echo $(( JETZT + SPERRE_H * 3600 )) >"$ZUSTAND/gesperrt_bis"; fi
    mailen_selten sprung "Platzwaechter $(hostname): auffaelliger Platzverbrauch, Loeschen gesperrt" \
"der freie Platz auf $MP fiel seit $(date -d "@$t" '+%d.%m. %H:%M') von $(gib $b) GiB auf $(gib $FREI_B) GiB (mehr als $MAX_SPRUNG_GB GiB).
Das kann eine grosse legitime Kopie sein, aber auch Verschluesselung (Ransomware) auf der Quelle. Der Waechter loescht deshalb
bis $(date -d "@$(( JETZT + SPERRE_H * 3600 ))" '+%d.%m. %H:%M') KEINE Snapshots. Aufheben: rm $ZUSTAND/gesperrt_bis"
  fi
fi
[ -n "$NUR_ANZEIGEN" ] || echo "$JETZT $FREI_B $FREI_P" >"$ZUSTAND/letzt"
verbrauch_zeile 0

# 2) genug Platz: nichts zu tun
[ "$FREI_P" -ge "$MIN_FREI" ] && exit 0

# 3) zu wenig Platz
if [ -f "$ZUSTAND/gesperrt_bis" ] && [ "$(cat "$ZUSTAND/gesperrt_bis")" -gt "$JETZT" ]; then
  log "nur noch $FREI_P % frei, Loeschen aber gesperrt bis $(date -d "@$(cat "$ZUSTAND/gesperrt_bis")" '+%F %T')"
  [ -z "$SPRUNG" ] && mailen_selten gesperrt "Platzwaechter $(hostname): $MP nur noch $FREI_P % frei, Loeschen gesperrt" \
"$MP hat nur noch $(gib $FREI_B) GiB ($FREI_P %) frei, der Waechter ist wegen auffaelligen Verbrauchs gesperrt (rm $ZUSTAND/gesperrt_bis hebt die Sperre auf)."
  exit 0
fi
if [ -n "$NUR_ANZEIGEN" ]; then
  log "$FREI_P % frei (< $MIN_FREI %): wuerde nacheinander loeschen, bis $ZIEL_FREI % frei sind: $(kandidaten | tr '\n' ' ')"; exit 0
fi
GELOESCHT=
while IFS=';' read -r nr datum; do
  frei_messen; [ "$FREI_P" -ge "$ZIEL_FREI" ] && break
  vorher=$FREI_B
  log "loesche Snapshot $nr ($datum); frei vorher $(gib $FREI_B) GiB = $FREI_P %"
  if ! timeout 10800 snapper -c "$CFG" delete --sync "$nr" </dev/null; then
    mailen "Platzwaechter $(hostname): FEHLER beim Loeschen von Snapshot $nr" "snapper delete --sync $nr auf $MP schlug fehl; frei $(gib $FREI_B) GiB = $FREI_P %. Bereits geloescht:${GELOESCHT:- nichts}"
    exit 1
  fi
  frei_messen; log "Snapshot $nr geloescht; frei nun $(gib $FREI_B) GiB = $FREI_P %"
  GELOESCHT="$GELOESCHT"$'\n'"  Snapshot $nr vom $datum (+$(gib $(( FREI_B - vorher ))) GiB)"
done < <(kandidaten)
frei_messen; echo "$(date +%s) $FREI_B $FREI_P" >"$ZUSTAND/letzt"
verbrauch_zeile "$(printf '%s' "$GELOESCHT" | grep -c Snapshot)"
[ -n "$GELOESCHT" ] && mailen "Platzwaechter $(hostname): Snapshots geloescht, $MP jetzt $FREI_P % frei" \
"$MP war unter $MIN_FREI % frei. Geloeschte Snapshots (aelteste zuerst):$GELOESCHT

Nun frei: $(gib $FREI_B) von $(gib $GROESSE_B) GiB = $FREI_P % (Ziel $ZIEL_FREI %). Geschuetzt sind die Snapshots der neuesten $BEHALTE_TAGE Tage."
if [ "$FREI_P" -lt "$MIN_FREI" ]; then
  log "KRITISCH: $FREI_P % frei, kein weiterer Snapshot loeschbar"
  mailen_selten kritisch "Platzwaechter $(hostname): KRITISCH, $MP nur $FREI_P % frei, nichts mehr loeschbar" \
"$MP hat nur noch $(gib $FREI_B) GiB ($FREI_P %) frei, und es gibt keinen loeschbaren Snapshot mehr (geschuetzt: die neuesten $BEHALTE_TAGE Tage, fremde Snapshots). Bitte von Hand Platz schaffen."
fi
exit 0
