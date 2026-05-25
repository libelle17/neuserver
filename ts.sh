#!/bin/sh

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
