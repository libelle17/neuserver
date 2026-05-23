<?php
if (isset($_GET['email'])) {
if ( $_GET['email'] <> "" )
{
  // und nun die Daten in eine Datei schreiben
  // Datei wird zum Schreiben ge?ffnet
  $handle = fopen ( "anfragen.txt", "w" );

  // schreiben des Inhaltes von email
  fwrite ( $handle, $_GET['email'] );

  // Trennzeichen einf?gen, damit Auswertung m?glich wird
  fwrite ( $handle, "|" );

  // schreiben des Inhalts von name
  fwrite ( $handle, $_GET['name'] );
  // fwrite ( $handle, "\n");
  fwrite ( $handle, PHP_EOL);

  // Datei schlie?en
  fclose ( $handle );

  echo "Danke - Ihre Daten wurden speichert";

  // Datei wird nicht weiter ausgef?hrt
  exit;
}
}
?>
<form action="fdatei.php" method="get">

<p>Ihre E-Mail-Adresse<br />
<input type="Text" name="email" ></p>

<p>Name:<br />
<input type="Text" name="name" ></p>

<input type="Submit" name="" value="fertig">

</form>


