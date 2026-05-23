<h1>Myschen von HTML und PHP</h1>
<?php
echo "PHP_SELF: ". $_SERVER['PHP_SELF'];
echo "<br>";
echo "REMOTE_ADDR: ". $_SERVER['REMOTE_ADDR'];
echo "<br>";
echo "HTTP_HOST: ". $_SERVER['HTTP_HOST'];
$vari = $_SERVER['HTTP_HOST'];
echo "<br>";
echo "$vari<br>";
$a = '1.234';
$b = '5';

echo bcadd($a, $b)."<br>";     // 6
echo bcadd($a, $b, 2);  // 6.2340
$teilnehmer = 5;
$teilnehmerinnen = 4;
?>
<?php
date_default_timezone_set('Europe/Berlin');
echo "<br>heutiges Datum: ". date("d.m.Y H.i.s");
echo "<br>heutiges Datum: ". date("d.m.y H.i.s");
?>
<?php
$ergebnis = $teilnehmer + $teilnehmerinnen;

echo "<p>Ergebnis Teilnehmeranzahl: ". $ergebnis . "</p>";
echo "<p>Ergebnis Teilnehmeranzahl: $ergebnis</p>";
echo "<p>Ergebnis Teilnehmeranzahl: ".
($teilnehmer + $teilnehmerinnen) . "</p>";
echo "<p>Ergebnis Teilnehmeranzahl: ".
($teilnehmer + $teilnehmerinnen) . "</p>";
echo phpinfo();
?>

