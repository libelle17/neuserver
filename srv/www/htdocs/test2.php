<!-- test2.php - einfacher Seitenzähler: liest den Stand aus "counter.txt"
     im aktuellen Verzeichnis (relativ zum Arbeitsverzeichnis des
     PHP-Prozesses, nicht zwingend zum Skriptverzeichnis - s. die
     auskommentierte robustere dirname(__FILE__)-Variante darunter),
     erhöht ihn um 1, gibt ihn aus und schreibt ihn zurück. Kein Teil der
     eigentlichen Patientenlaufzettel-Anwendung. Aufruf: test2.php im
     Browser, keine Parameter. -->
<?php
// $datei = fopen(dirname(__FILE__)."/counter.txt","r+");
$datei = fopen("counter.txt","a+");
$counterstand = fgets($datei, 10);
if($counterstand == "")
{
  $counterstand = 0;
}
$counterstand++;
echo $counterstand;
rewind($datei);
fwrite($datei, $counterstand);
fclose($datei);
?>
