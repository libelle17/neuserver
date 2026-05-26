<?php
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
