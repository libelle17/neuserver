<?php
session_start();
$werteins="Premiere";
$_SESSION['werteins']="Premiere";
//header("Location:tragein1.php");
// header("Location:".$_SERVER['HTTP_REFERER']);
// header ("Location:K.html");
//$zeilen= readfile($_SERVER['HTTP_REFERER']);
// echo $zeilen;
include $_SERVER['HTTP_REFERER'];
?>
