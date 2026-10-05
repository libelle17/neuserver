#!/bin/bash
# wurzelwacht.sh - prueft, ob die Platte mit dem Wurzeldateisystem (/) auszufallen droht, und haelt ein
# vorbereitetes Ersatz-Betriebssystem auf einer ANDEREN Platte mit den wichtigsten Inhalten dieses Rechners aktuell.
#
# Anlass (5.10.2026): KDE meldete auf linux7, dass das Wurzellaufwerk auszufallen droht; ein zweites Laufwerk
# mit derselben Distribution war schon eingerichtet. Laeuft unveraendert auf linux0, linux1 und linux7 - alles
# Rechnerspezifische (Platten, Partitionen, Subvolumes) wird selbst ermittelt.
#
# Ablauf:
#  1. Platte(n) von / bestimmen (auch durch btrfs-Subvolume/LVM hindurch) und per smartctl pruefen:
#     Gesamtbewertung FAILED, Vorausfall-Attribut unter Schwelle, wiederzugewiesene/ausstehende/nicht
#     korrigierbare Sektoren > 0, Attribut mit WHEN_FAILED; bei NVMe Critical Warning, Verschleiss >= 90 %,
#     Medienfehler > 0.
#  2. Ersatzsystem suchen: Linux-Dateisysteme (btrfs/ext4/xfs) auf anderen Platten, die nicht / sind, kurz
#     schreibgeschuetzt einhaengen und /etc/os-release vergleichen (ID und VERSION_ID wie hier).
#     Beschrieben wird ein Kandidat NUR, wenn dort die Markierungsdatei /etc/ersatzwurzel liegt und als erstes
#     Wort den Kurznamen dieses Rechners enthaelt - einmal von Hand anlegen, z.B.:
#        d=$(mktemp -d) && mount /dev/sdX2 $d && echo linux7 > $d/etc/ersatzwurzel && umount $d && rmdir $d
#     (nicht /mnt verwenden: das wuerde dort eingehaengte Freigaben wie /mnt/wser verdecken)
#     (Schutz davor, versehentlich in ein fremdes installiertes System zu schreiben.)
#  3. Kopieren, wenn ein Ausfall droht, sonst mindestens alle KOPIE_TAGE Tage (Platten fallen oft ohne
#     SMART-Vorwarnung aus), oder mit -k. Das Ersatzsystem wird mit allen Subvolumes/Partitionen laut SEINER
#     /etc/fstab eingehaengt. Kopiert werden nur ausgewaehlte Inhalte, Kernel/Bootloader/fstab des Ersatzes
#     bleiben unangetastet (bleibt bootbar):
#       - Verzeichnisse $VERZEICHNISSE (gespiegelt, --delete; ohne .cache/.snapshots)
#       - aus /etc nur $ETC_AUSWAHL; ganz /etc zum Nachschlagen nach /root/wurzelwacht/etc_aktuell
#       - Programme in /usr/bin, /usr/sbin, die zu keinem Paket gehoeren (selbst gebaute wie autofax)
#       - MariaDB als Dump /root/wurzelwacht/mariadb_alle.sql.gz (laufende Datenbankdateien waeren inkonsistent)
#       - Paketliste, fehlende Pakete, Benutzerliste und LIESMICH.txt mit den Schritten beim Umstieg
#     /DATA ist eine eigene Platte und nicht betroffen.
#  4. Mail bei drohendem Ausfall (bei Aenderung des Befunds, sonst hoechstens alle 24 h) und bei Kopierfehlern.
#
# Aufruf:  wurzelwacht.sh [-e] [-k] [-h]
#   -e   echt: kopieren und mailen; ohne -e nur anzeigen (Pruefung und Kandidatensuche laufen, nur lesend)
#   -k   Kopie erzwingen, auch ohne Warnung und vor Ablauf von KOPIE_TAGE
# Aufgerufen von wecklauf.sh (linux0/linux7, in jedem Sicherungsfenster unter dessen Shutdown-Inhibitor) und
# per cron (linux1, 2x taeglich). Einstellungen per Umgebung: WW_EMPFAENGER, WW_KOPIE_TAGE (7),
# WW_VERZEICHNISSE, WW_ZUSTAND (/var/lib/wurzelwacht).
EMPFAENGER=${WW_EMPFAENGER:-diabetologie@dachau-mail.de}
KOPIE_TAGE=${WW_KOPIE_TAGE:-7}
VERZEICHNISSE=${WW_VERZEICHNISSE:-/root /home /opt /srv /usr/local /var/spool /var/lib/samba /var/lib/wecklauf /var/lib/bumonitor /var/lib/platzwaechter}
ETC_AUSWAHL="hostname hosts exports auto.master samba postfix ssh cups zypp/repos.d leiste.conf"
ZUSTAND=${WW_ZUSTAND:-/var/lib/wurzelwacht}
BASIS=/run/wurzelwacht
MARKE=etc/ersatzwurzel
obecht=; erzwingen=
for a in "$@"; do case "$a" in -e) obecht=1;; -k) erzwingen=1;; *) sed -n '2,38p' "$0"; exit 1;; esac; done
h=$(hostname); h=${h%%.*}
exec 9>/run/wurzelwacht.lock; flock -n 9 || { echo "wurzelwacht.sh laeuft schon"; exit 0; }
blau="\033[1;34m"; rot="\033[1;31m"; reset="\033[0m"
JETZT=$(date +%s)
log() { printf '%s %b\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }
BEFUND=""; befund() { BEFUND="${BEFUND}${1}"$'\n'; }
BERICHT=""; bericht() { BERICHT="${BERICHT}${1}"$'\n'; log "$1"; }

platten_von() { lsblk -rspno NAME,TYPE "$1" 2>/dev/null | awk '$2=="disk"{print $1}' | sort -u; }

# pruefe_platte <Platte> - ergaenzt BEFUND um alle Auffaelligkeiten
pruefe_platte() {
  local d=$1 aus rc
  aus=$(LC_ALL=C smartctl -H -A "$d" 2>&1); rc=$?
  if [ $((rc & 2)) -ne 0 ] || ! printf '%s' "$aus" | grep -q 'SMART'; then
    log "$d: SMART nicht abfragbar (smartctl-Exitcode $rc) - keine Bewertung"; return
  fi
  [ $((rc & 8)) -ne 0 ] && befund "$d: SMART-Gesamtbewertung FAILED - Platte meldet drohenden Ausfall"
  [ $((rc & 16)) -ne 0 ] && befund "$d: ein Vorausfall-Attribut liegt unter seiner Schwelle"
  # SATA/SAS-Attributtabelle: ID# NAME FLAG VALUE WORST THRESH TYPE UPDATED WHEN_FAILED RAW_VALUE
  while read -r z; do befund "$d: $z"; done < <(printf '%s\n' "$aus" | awk '
    $1 ~ /^[0-9]+$/ && NF >= 10 {
      roh=$10+0
      if (($1==5 || $1==187 || $1==197 || $1==198) && roh > 0) print $2 " = " roh
      else if ($9 != "-") print $2 " zeigt WHEN_FAILED " $9 }')
  # NVMe
  while read -r z; do befund "$d: $z"; done < <(printf '%s\n' "$aus" | awk -F: '
    /^Critical Warning:/ { v=$2; gsub(/ /,"",v); if (v != "0x00") print "NVMe Critical Warning " v }
    /^Percentage Used:/ { v=$2; gsub(/[ %]/,"",v); if (v+0 >= 90) print "NVMe Verschleiss " v " %" }
    /^Media and Data Integrity Errors:/ { v=$2; gsub(/[ .,]/,"",v); if (v+0 > 0) print "NVMe Medienfehler " v }')
}

# Wurzel bestimmen und pruefen
WQ=$(findmnt -no SOURCE / | sed 's/\[.*//'); WUUID=$(findmnt -no UUID /)
WPLATTEN=$(platten_von "$WQ")
[ -n "$WPLATTEN" ] || { log "Platte von / ($WQ) nicht ermittelbar - Abbruch"; exit 1; }
command -v smartctl >/dev/null || { log "smartctl fehlt (zypper in smartmontools)"; exit 1; }
for d in $WPLATTEN; do pruefe_platte "$d"; done
. /etc/os-release; EIGEN_OS="$ID $VERSION_ID"
log "$h: / = $WQ auf $(echo $WPLATTEN), $EIGEN_OS"
if [ -n "$BEFUND" ]; then log "${rot}Wurzelplatte droht auszufallen:${reset}"; printf '%s' "$BEFUND" | sed 's/^/   /'
else log "Wurzelplatte ohne SMART-Befund"; fi

# Ersatzsystem suchen
mkdir -p "$BASIS"
ERSATZ=; ERSATZ_FS=; ERSATZ_MP=
while read -r zeile; do
  NAME=; FSTYPE=; TYPE=; MOUNTPOINT=; UUID=
  eval "$zeile"
  case "$FSTYPE" in btrfs|ext4|xfs) ;; *) continue;; esac
  [ "$UUID" = "$WUUID" ] && continue
  echo "$(platten_von "$NAME")" | grep -qxF -f <(echo "$WPLATTEN") && continue
  wurzel=$MOUNTPOINT; selbst=
  if [ -z "$wurzel" ]; then
    case "$FSTYPE" in ext4) o=ro,noload;; xfs) o=ro,norecovery;; *) o=ro;; esac
    mkdir -p "$BASIS/pruef"; mount -t "$FSTYPE" -o "$o" "$NAME" "$BASIS/pruef" 2>/dev/null || continue
    wurzel=$BASIS/pruef; selbst=1
  fi
  if [ -f "$wurzel/etc/os-release" ]; then
    os=$(sed -n 's/^\(ID\|VERSION_ID\)=["'"'"']\?\([^"'"'"']*\).*/\1 \2/p' "$wurzel/etc/os-release" | sort | awk '{print $2}' | paste -sd' ')
    marke=$(awk 'NR==1{print $1}' "$wurzel/$MARKE" 2>/dev/null)
    if [ "$os" != "$EIGEN_OS" ]; then log "Kandidat $NAME: $os - andere Distribution/Version, nicht verwendet"
    elif [ "$marke" != "$h" ]; then
      log "Kandidat $NAME: $os, aber ohne Markierung fuer $h - nicht verwendet. Freigeben mit:"
      log "   d=\$(mktemp -d) && mount $NAME \$d && echo $h > \$d/$MARKE && umount \$d && rmdir \$d"
    elif [ -z "$ERSATZ" ]; then ERSATZ=$NAME; ERSATZ_FS=$FSTYPE; ERSATZ_MP=$MOUNTPOINT; log "${blau}Ersatzsystem: $NAME ($os)${reset}"
    fi
  fi
  [ "$selbst" ] && umount "$BASIS/pruef"
done < <(lsblk -Ppno NAME,FSTYPE,TYPE,MOUNTPOINT,UUID)
[ -n "$ERSATZ" ] || log "kein freigegebenes Ersatzsystem gefunden"

# Kopieren?
LETZTE=$(cat "$ZUSTAND/letzte_kopie" 2>/dev/null); LETZTE=${LETZTE:-0}
grund=
if [ -n "$BEFUND" ]; then grund="drohender Ausfall"
elif [ "$erzwingen" ]; then grund="-k"
elif [ $((JETZT - LETZTE)) -gt $((KOPIE_TAGE * 86400)) ]; then grund="letzte Kopie aelter als $KOPIE_TAGE Tage"; fi

EINGEHAENGT=()
aushaengen() { local i; for ((i=${#EINGEHAENGT[@]}-1; i>=0; i--)); do umount "${EINGEHAENGT[i]}" 2>/dev/null; done; EINGEHAENGT=(); }
trap 'aushaengen; umount "$BASIS/pruef" 2>/dev/null' EXIT

# kopieren - haengt das Ersatzsystem samt Subvolumes laut seiner fstab ein und kopiert; 0 = ohne Fehler
kopieren() {
  local Z fehler=0 src ziel typ opt dev D T uebersprungen="" w="/root/wurzelwacht" sql
  if [ -n "$ERSATZ_MP" ]; then
    Z=$ERSATZ_MP; findmnt -no OPTIONS "$Z" | grep -qw rw || { bericht "Ersatz $ERSATZ ist nur lesend eingehaengt ($Z)"; return 1; }
  else
    Z=$BASIS/ersatz; mkdir -p "$Z"
    mount -t "$ERSATZ_FS" "$ERSATZ" "$Z" || { bericht "Ersatz $ERSATZ nicht einhaengbar"; return 1; }
    EINGEHAENGT+=("$Z")
  fi
  # Subvolumes/Partitionen des Ersatzes einhaengen, soweit sie fuer die Zielverzeichnisse gebraucht werden
  while read -r src ziel typ opt; do
    src=$(printf '%b' "$src"); ziel=$(printf '%b' "$ziel") # findmnt -r schreibt Leerzeichen als \x20
    [ "$ziel" = / ] && continue
    case "$typ" in btrfs|ext4|xfs) ;; *) continue;; esac
    gebraucht=; for D in $VERZEICHNISSE /root/wurzelwacht /usr/bin /etc; do case "$D/" in "$ziel"/*) gebraucht=1;; esac; done
    [ "$gebraucht" ] || continue
    case "$src" in /dev/*) dev=$src;; *) dev=$(findfs "$src" 2>/dev/null);; esac
    if [ -z "$dev" ] || echo "$(platten_von "$dev")" | grep -qxF -f <(echo "$WPLATTEN"); then
      bericht "Ersatz-fstab: $ziel liegt auf der Wurzelplatte oder ist nicht auffindbar ($src) - wird nicht beschrieben"
      uebersprungen="$uebersprungen $ziel"; continue
    fi
    opt=$(echo "$opt" | sed 's/\(^\|,\)noauto\(,\|$\)/\1\2/;s/,,/,/;s/^,//;s/,$//')
    mkdir -p "$Z$ziel"
    if mount -t "$typ" ${opt:+-o "$opt"} "$dev" "$Z$ziel"; then EINGEHAENGT+=("$Z$ziel")
    else bericht "Ersatz: $ziel nicht einhaengbar"; uebersprungen="$uebersprungen $ziel"; fi
  done < <(findmnt --fstab --tab-file "$Z/etc/fstab" -rno SOURCE,TARGET,FSTYPE,OPTIONS 2>/dev/null)
  istuebersprungen() { local u; for u in $uebersprungen; do case "$1/" in "$u"/*) return 0;; esac; done; return 1; }
  RS="rsync -aAXH --numeric-ids --delete --exclude=.cache/ --exclude=.snapshots/"
  for D in $VERZEICHNISSE; do
    [ -d "$D" ] || continue
    istuebersprungen "$D" && continue
    mkdir -p "$Z$D"
    ionice -c3 $RS "$D/" "$Z$D/" || { bericht "Kopie $D fehlerhaft (rsync $?)"; fehler=1; }
  done
  if istuebersprungen /root; then bericht "/root des Ersatzes nicht beschreibbar - etc, Dump, Listen entfallen"; return 1; fi
  mkdir -p "$Z$w"
  $RS /etc/ "$Z$w/etc_aktuell/" || { bericht "Kopie /etc nach $w/etc_aktuell fehlerhaft"; fehler=1; }
  for e in $ETC_AUSWAHL; do
    [ -e "/etc/$e" ] || continue
    if [ -d "/etc/$e" ]; then mkdir -p "$Z/etc/$e"; $RS "/etc/$e/" "$Z/etc/$e/"; else rsync -aAX "/etc/$e" "$Z/etc/$e"; fi \
      || { bericht "Kopie /etc/$e fehlerhaft"; fehler=1; }
  done
  # selbst gebaute Programme (keinem Paket zugehoerig)
  find /usr/bin /usr/sbin -maxdepth 1 -type f -print0 | xargs -0 -r env LC_ALL=C rpm -qf 2>/dev/null \
    | sed -n 's/^file \(.*\) is not owned by any package$/\1/p' > "$Z$w/programme_ohne_paket.txt"
  rsync -aAX --files-from="$Z$w/programme_ohne_paket.txt" / "$Z/" || { bericht "Kopie der Programme ohne Paket fehlerhaft"; fehler=1; }
  # Pakete, Benutzer
  rpm -qa --qf '%{NAME}\n' | sort -u > "$Z$w/pakete.txt"
  rpm --root "$Z" -qa --qf '%{NAME}\n' 2>/dev/null | sort -u | comm -23 "$Z$w/pakete.txt" - > "$Z$w/pakete_fehlen.txt"
  awk -F: '$3>=1000 && $3<60000' /etc/passwd > "$Z$w/benutzer.txt"
  # MariaDB
  if [ -z "$WW_OHNE_DB" ] && { systemctl -q is-active mariadb 2>/dev/null || systemctl -q is-active mysql 2>/dev/null; }; then
    sql=$Z$w/mariadb_alle.sql.gz
    if [ -f /root/.mysqlpwd ] && mariadb-dump --defaults-extra-file=/root/.mysqlpwd --all-databases --single-transaction \
         --routines --events --triggers --quick 2>"$Z$w/mariadb_dump.err" | gzip > "$sql.tmp" && [ "${PIPESTATUS[0]}" = 0 ]; then
      mv "$sql.tmp" "$sql"
    else rm -f "$sql.tmp"; bericht "MariaDB-Dump fehlgeschlagen (s. $w/mariadb_dump.err auf dem Ersatz)"; fehler=1; fi
  fi
  cat > "$Z$w/LIESMICH.txt" <<EOF
Ersatzsystem fuer $h, zuletzt befuellt am $(date '+%d.%m.%Y %H:%M') von wurzelwacht.sh (Quelle: $WQ).
Grund: $grund

Beim Umstieg (nach dem ersten Start von diesem Laufwerk):
 1. Fehlende Pakete:     zypper in \$(cat $w/pakete_fehlen.txt)
 2. Benutzer anlegen:    s. $w/benutzer.txt (gleiche UID/GID wie bisher verwenden)
 3. Datenbank:           zcat $w/mariadb_alle.sql.gz | mariadb
 4. /etc vergleichen:    $w/etc_aktuell/ (uebernommen wurden nur: $ETC_AUSWAHL)
 5. eigene Programme:    aus $w/programme_ohne_paket.txt sind kopiert; ggf. cd /root/neuserver && ./los.sh
 6. crontab:             liegt mit /var/spool/cron schon da; danach crontab_uebernehmen.sh
 7. /DATA, /etc/fstab:   fstab des Ersatzes um die /DATA-Eintraege aus $w/etc_aktuell/fstab ergaenzen
 8. Markierung:          rm /$MARKE (sonst haelt sich das neue System selbst nicht fuer die Wurzel)
EOF
  [ "$fehler" = 0 ] && { mkdir -p "$ZUSTAND"; echo "$JETZT" > "$ZUSTAND/letzte_kopie"; }
  sync; aushaengen
  return $fehler
}

KOPIE_OK=
if [ -n "$grund" ] && [ -n "$ERSATZ" ]; then
  if [ "$obecht" ]; then
    log "${blau}Kopiere auf $ERSATZ${reset} (Grund: $grund)"
    if kopieren; then KOPIE_OK=1; bericht "Kopie auf Ersatzsystem $ERSATZ abgeschlossen"; else KOPIE_OK=0; bericht "Kopie auf $ERSATZ mit Fehlern"; fi
  else log "Simulation: wuerde auf $ERSATZ kopieren (Grund: $grund): $VERZEICHNISSE, /etc-Auswahl, Programme, MariaDB-Dump"; fi
elif [ -n "$ERSATZ" ]; then log "letzte Kopie $(date -d "@$LETZTE" '+%d.%m.%Y %H:%M') - noch keine neue noetig"; fi

# Mail
mailen() { command -v mail >/dev/null && printf '%s\n' "$2" | mail -s "$1" "$EMPFAENGER"; }
if [ "$obecht" ] && { [ -n "$BEFUND" ] || [ "$KOPIE_OK" = 0 ]; }; then
  sig=$(printf '%s%s' "$BEFUND" "$KOPIE_OK" | sha256sum | cut -c1-16)
  read -r lsig lzeit 2>/dev/null < "$ZUSTAND/mail"
  if [ "$sig" != "$lsig" ] || [ $((JETZT - ${lzeit:-0})) -gt 86400 ]; then
    if [ -n "$BEFUND" ]; then betreff="WARNUNG $h: Systemplatte droht auszufallen"; else betreff="WARNUNG $h: Kopie aufs Ersatzsystem fehlerhaft"; fi
    if [ -n "$ERSATZ" ]; then ers="Ersatzsystem: $ERSATZ"; else ers="KEIN freigegebenes Ersatzsystem gefunden - bitte einrichten (s. wurzelwacht.sh -h)."; fi
    mailen "$betreff" "Auf $h (/ = $WQ auf $(echo $WPLATTEN)):"$'\n\n'"${BEFUND:-(kein SMART-Befund)}"$'\n'"$ers"$'\n'"$BERICHT"$'\n'"(wurzelwacht.sh, $(date '+%d.%m.%Y %H:%M'))"
    mkdir -p "$ZUSTAND"; echo "$sig $JETZT" > "$ZUSTAND/mail"; log "Warnmail an $EMPFAENGER gesendet"
  fi
fi
[ "$KOPIE_OK" = 0 ] && exit 1
exit 0
