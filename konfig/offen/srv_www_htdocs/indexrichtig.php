<!-- indexrichtig.php - offenbar eine frühere/alternative Fassung von
     index.php (gleicher Inhalt, ohne den einleitenden Link und ohne die
     ini_set()-Fehleranzeige-Zeilen); ebenfalls Diagnoseseite mit
     phpinfo()/$_SERVER-Ausgabe, kein Teil der eigentlichen
     Patientenlaufzettel-Anwendung. Wird von keiner anderen Datei in
     diesem Repository verlinkt oder eingebunden. Aufruf: indexrichtig.php
     im Browser, keine Parameter. -->
<?php
    $ip = $_SERVER['REMOTE_ADDR'];
    $host = gethostbyaddr($ip);
$fb = '<span style="color:red">';
$fe = '</span>';
echo 'PC-Name des Apache-Servers: '; 
echo $fb, gethostname(), $fe;
echo ' und IP:', $fb, getenv ("SERVER_ADDR"), $fe;
echo '<br>';
echo 'aktuelles Datum: ', $fb, date("d.m.y h:m:s"), $fe, '    Zeit in Sekunden: ', $fb, (time()), $fe; 
echo '<br>';
echo 'IP Adresse des Aufrufers: ', "$fb$ip<br />$fe";  
echo 'var_dump($_SERVER):';
echo '<br>';
echo var_dump($_SERVER);
phpinfo(); ?>
