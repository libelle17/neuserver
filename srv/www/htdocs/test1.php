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
