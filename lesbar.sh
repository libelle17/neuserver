# lesbar.sh - macht eine rohe BDT-Datei ("roh.BDT" im aktuellen Verzeichnis,
# Behandlungsdaten-Transfer-Format: erste 3 Zeichen je Zeile = Satzlänge,
# nächste 4 = Satzart) lesbar und schreibt das Ergebnis nach "lesbar.BDT":
#   1. sed:  behält nur die Satzarten 3000 (Name/Neuer Patientenblock), 3650
#            und 6001, alle anderen Zeilen werden verworfen.
#   2. sed:  entfernt unmittelbar aufeinanderfolgende Dublettenzeilen
#            (klassischer sed-"uniq"-Trick über N/P/D).
#   3. sed:  schneidet bei allen Zeilen die 7-stellige BDT-Kopfzeile
#            (Satzlänge+Satzart) ab; bei 3000-Zeilen wird zusätzlich per
#            x;p;x eine (mangels vorherigem "h" stets leere) Zeile aus dem
#            Hold-Space gedruckt - wirkt dadurch als Leerzeilen-Trenner vor
#            jedem neuen Patientenblock.
# Aufruf ohne Parameter (kein Shebang - im Verzeichnis mit roh.BDT z.B. per
# "sh lesbar.sh" ausführen).
sed -nr '/^...(3000|3650|6001)/p;' roh.BDT | sed -nr 'N;/^(.*)\n\1$/!P;D;'|sed -rn '/^...3000/{x;p;x};s/^.{7}//p' > lesbar.BDT
