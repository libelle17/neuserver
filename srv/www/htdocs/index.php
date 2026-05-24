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
