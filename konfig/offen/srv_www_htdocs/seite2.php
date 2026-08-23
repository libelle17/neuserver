<!-- seite2.php - PHP-Lernübung: erwartet die POST-Felder "email" und
     "kommentar" (z.B. aus einem Formular wie in test1.php) und meldet nur,
     ob beide ausgefüllt sind oder nicht - es wird nirgends tatsächlich
     etwas gespeichert, trotz der Meldung "Ihr Eintrag wurde gespeichert".
     Kein Teil der eigentlichen Patientenlaufzettel-Anwendung. Aufruf: nur
     per POST mit den Feldern email/kommentar sinnvoll (direkter GET-Aufruf
     im Browser liefert wegen fehlender POST-Werte eine PHP-Warnung je
     Feld, je nach php.ini-Fehleranzeige sichtbar). -->
<?php
$email = $_POST["email"];
$kommentar = $_POST["kommentar"];

if($email=="" OR $kommentar=="")
{
  echo "Bitte füllen Sie alle Felder aus";
}

else
{
  echo "Ihr Eintrag wurde gespeichert";
}
?>
