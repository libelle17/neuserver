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
