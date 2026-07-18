<?php
// tragein.php - Session-Bootstrap eines älteren "Aufgabenformular"-Ablaufs
// (initialisiert defensiv einige POST-/SESSION-Schlüssel gegen PHP-8-
// Warnungen bei fehlenden Array-Indizes) und bindet am Ende die
// aufrufende Seite per include($_SERVER['HTTP_REFERER']) wieder ein.
// Wird von KEINER anderen Datei in diesem Repository per include/require
// eingebunden - wirkt wie ein verwaister Rest der älteren "tragein*"-
// Generation (vgl. tragein0.php/tragein1.php/form_alt.php/datalist.php),
// die durch anzeig.php/ianzeig.php + i0S/i1S/i2S.php abgelöst wurde.
// ACHTUNG (falls doch reaktiviert): include() auf einen Wert aus
// $_SERVER['HTTP_REFERER'] bindet einen vom Client kontrollierten
// HTTP-Header als Datei ein - das ist ein bekanntes Local/Remote-File-
// Inclusion-Risiko, falls der Referer nicht strikt validiert wird.
session_start();
// PHP 8.x Kompatibilität: POST-Keys sicher initialisieren
$post_keys = ["obvorb", "history", "ausblend", "anwesend", "ma",
"obbeha", "aktual"];
foreach ($post_keys as $key) {
    if (!isset($_POST[$key])) $_POST[$key] = "";
}
// PHP 8.x Kompatibilität: SESSION-Keys sicher initialisieren
if (session_status() === PHP_SESSION_ACTIVE) {
    $session_keys = ["history", "ausblend", "arr", "loeschen"];
    foreach ($session_keys as $key) {
        if (!isset($_SESSION[$key])) $_SESSION[$key] = "";
    }
}
$werteins="Premiere";
$_SESSION['werteins']="Premiere";
//header("Location:tragein1.php");
// header("Location:".$_SERVER['HTTP_REFERER']);
// header ("Location:K.html");
//$zeilen= readfile($_SERVER['HTTP_REFERER']);
// echo $zeilen;
include $_SERVER['HTTP_REFERER'];
?>
