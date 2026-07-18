#/bin/bash
# dopweg.sh - bereinigt Fehlimporte unter /DATA/Patientendokumente/dok:
# Windows/Turbomed hängt bei einem Datei-Konflikt automatisch " (30)" (o.ä.
# Zahl) an den Dateinamen an - findet also eine Datei mit "(30)" im Namen,
# deren Basisdatei (ohne " (30)") dasselbe Änderungsdatum und dieselbe
# Größe hat (also ein reiner Doppelimport ist), wird sie (und alle
# weiteren Varianten " (1)".." (100)" mit demselben Datum/derselben
# Größe) zu "zulöschen ..." umbenannt und danach gelöscht.
# -e: echt umbenennen/löschen; ohne -e (Standard): Trockenlauf, zeigt nur an,
# was geschehen würde. Wird obecht vom aufrufenden Mutterskript (bumo.sh)
# durchgereicht - läuft bumo.sh auf linux0/linux7, wird dieses Skript dort
# per ssh auf linux1 ausgeführt, da die Fehlimporte an der Quelle liegen.
obecht=;
[ "$1" = "-e" ] && obecht=1;
[ "$obecht" ] && echo "Lösche Fehlimporte" || echo "Lösche Fehlimporte (Trockenlauf, -e für Echtlauf)"
find /DATA/Patientendokumente/dok -iname "*(30)*" | awk -v obecht="$obecht" '
{
    fullpath = $0
    n = split(fullpath, parts, "/")
    filename = parts[n]
    dir = substr(fullpath, 1, length(fullpath) - length(filename))

    gsub(/ \(30\)/, "", filename)
    basefile = dir filename

    # Prüfe ob die Basisdatei existiert
    cmd = "test -f \"" basefile "\" && echo exists"
    cmd | getline result
    close(cmd)

    if (result == "exists") {
        # Hole Änderungsdatum und Größe der Basisdatei
        stat_cmd = "stat -c \"%Y %s\" \"" basefile "\" 2>/dev/null"
        stat_cmd | getline base_stats
        close(stat_cmd)

        split(base_stats, base_info)
        base_mtime = base_info[1]
        base_size = base_info[2]

        # Umbenennen aller Dateien xy (1).z bis xy (100).z
        for (i = 1; i <= 100; i++) {
            base_without_ext = filename
            sub(/\.[^.]+$/, "", base_without_ext)
            match(filename, /\.[^.]+$/)
            ext = substr(filename, RSTART)

            oldname = dir base_without_ext " (" i ")" ext
            newname = dir "zulöschen " base_without_ext " (" i ")" ext

            # Prüfe ob Datei existiert
            check_cmd = "test -f \"" oldname "\" && echo exists"
            check_cmd | getline file_exists
            close(check_cmd)

            if (file_exists == "exists") {
                # Hole Änderungsdatum und Größe der aktuellen Datei
                stat_cmd2 = "stat -c \"%Y %s\" \"" oldname "\" 2>/dev/null"
                stat_cmd2 | getline file_stats
                close(stat_cmd2)

                split(file_stats, file_info)
                file_mtime = file_info[1]
                file_size = file_info[2]

                # Vergleiche Änderungsdatum und Größe
                if (file_mtime == base_mtime && file_size == base_size) {
                    rename_cmd = "mv \"" oldname "\" \"" newname "\""
                    if (obecht) {
                        print rename_cmd
                        system(rename_cmd)
                    } else {
                        print "[Simulation] " rename_cmd
                    }
                }
            }
        }
    }
}'
if [ "$obecht" ]; then
  find /DATA/Patientendokumente/dok -iname "zulöschen*" -delete
else
  find /DATA/Patientendokumente/dok -iname "zulöschen*" -printf "[Simulation] rm \"%p\"\n"
fi
