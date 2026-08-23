<!-- test1.php - PHP-Lernübung: einfache Seiten-Weiche über den GET-Parameter
     "seite" (index/start/beliebig/fehlend). Kein Teil der eigentlichen
     Patientenlaufzettel-Anwendung. Aufruf: test1.php[?seite=index|start|...]. -->
<?php
if(!isset($_GET["seite"]))
{
  $seite="fehlt";
} else {
 $seite=$_GET["seite"];
}

if($seite=="index")
{
  echo "Indexseite";
} else 

if($seite=="start")
{
  echo "Startseite";
} else {
  echo "Seite: $seite";
}
?>
