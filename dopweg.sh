#/bin/bash
find /DATA/Patientendokumente/dok -iname "*(30)*" | awk '
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
                    print rename_cmd
                    system(rename_cmd)
                }
            }
        }
    }
}'
