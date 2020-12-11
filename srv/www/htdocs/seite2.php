<?php
$email = $_POST["email"];
$kommentar = $_POST["kommentar"];

if($email=="" OR $kommentar=="")
{
  echo "Bitte füllen Sie alle Felder aus";
}

else
{
  echo "Ihr Eintrag wurde gespeichert";
}
?>
