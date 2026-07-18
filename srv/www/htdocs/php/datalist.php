<!-- datalist.php - reine Fragment-Datei mit "echo"-Zeilen für <option>s
     eines HTML-<datalist>-Autocomplete (vgl. die inline <datalist> in
     tragein.php, dort mit einem zusätzlichen "Composer"-Eintrag). Wird von
     KEINER anderen Datei in diesem Repository per include/require
     eingebunden - wirkt wie ein verwaister, nicht mehr verdrahteter Rest
     der älteren, durch anzeig.php/ianzeig.php + i0S/i1S/i2S.php abgelösten
     "tragein*"-Aufgabenformular-Variante.
     WICHTIG: diese Datei hat KEIN öffnendes "<?php" - die "echo"-Zeilen
     werden deshalb, egal ob direkt aufgerufen oder eingebunden, NICHT als
     PHP ausgeführt, sondern wörtlich als Text/HTML ausgegeben (kein
     PHP-Interpreter zur Verfügung, um das hier nachzustellen, aber PHP
     verlangt für Code-Ausführung zwingend ein öffnendes "<?php"/"<?"). -->
echo "<option value=\"Rezepte\">";
echo "<option value=\"BZ-Vergleich\">";
echo "<option value=\"wiegen\">";
echo "<option value=\"Termin\">";
