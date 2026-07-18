<!-- index.php - Diagnose-/Testseite direkt unter htdocs (kein Teil der
     eigentlichen Patientenlaufzettel-Anwendung unter htdocs/php/): zeigt
     Servername, IP, Datum und den kompletten $_SERVER-Inhalt sowie
     phpinfo() an; verlinkt zusätzlich auf intern/strong.php. Aufruf:
     index.php im Browser, keine Parameter.
     Hinweis: da dies die Standard-Startseite des Docroot ist (index.php),
     bekommt jeder, der den Webserver erreichen kann, ungefragt die volle
     phpinfo()-Ausgabe (PHP-Version, geladene Module, Pfade, teils
     Umgebungsvariablen) sowie den kompletten $_SERVER-Inhalt zu sehen -
     relevant, falls dieser Apache über die reine Praxis-LAN-Nutzung
     hinaus erreichbar sein sollte. -->
<a href="intern/strong.php">Link<br></a>
<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
$ip = $_SERVER['REMOTE_ADDR'];  
$host = gethostbyaddr($ip);
$fb = '<span style="color:red">';
$fe = '</span>';
echo 'PC-Name des Apache-Servers: '; 
echo $fb, gethostname(), $fe;
echo ' und IP:', $fb, getenv ("SERVER_ADDR"), $fe;
echo '<br>';
echo 'aktuelles Datum: ', $fb, date("d.m.y h:m:s"), $fe, '    Zeit in Sekunden: ', $fb, time(), $fe; 
echo '<br>';
echo 'IP Adresse des Aufrufers: ', "$fb$ip<br />$fe";  
echo 'var_dump($_SERVER):';
echo '<br>';
echo var_dump($_SERVER);
phpinfo(); ?>
