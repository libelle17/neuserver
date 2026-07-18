#!/bin/sh
# ts.sh - wie treesize.sh (Größe der direkten Unterverzeichnisse/Dateien von
# DIR, bleibt im selben Dateisystem, -x), aber mit Schwellwert-Filter: nur
# Einträge, deren Größe mindestens $THRESHOLD_KB (aus einem optionalen
# Parameter wie "-500M"/"-2G"/"-100k" abgeleitet) beträgt, werden
# ausgegeben, alle in GB formatiert (keine automatische Einheitenwahl wie
# bei treesize.sh). Aufruf: ts.sh [-<Zahl><k|K|m|M|g|G|t|T>] [<Verzeichnis>]
# (beide Parameter optional, Vorgabe: kein Schwellwert, aktuelles
# Verzeichnis), z.B. "ts.sh -500M /DATA".

DIR="."
THRESHOLD_KB=0

for arg in "$@"; do
    case "$arg" in
        -[0-9]*[kKmMgGtT]*)
            val="${arg#-}"
            num="${val%%[kKmMgGtT]*}"
            unit="${val#$num}"
            case "$unit" in
                k|K|kb|KB) THRESHOLD_KB=$num ;;
                m|M|mb|MB) THRESHOLD_KB=$((num * 1024)) ;;
                g|G|gb|GB) THRESHOLD_KB=$((num * 1024 * 1024)) ;;
                t|T|tb|TB) THRESHOLD_KB=$((num * 1024 * 1024 * 1024)) ;;
            esac
            ;;
        -*)
            ;;  # unbekannte Flags ignorieren
        *)
            DIR="$arg"
            ;;
    esac
done

du "$DIR" -x -k --max-depth=1 | sort -nr | awk -v threshold="$THRESHOLD_KB" '
    {
        if ($1 >= threshold) {
            gb = $1 / 1024 / 1024;
            $1 = sprintf("%.3f GB", gb);
            print $0;
        }
    }
'
