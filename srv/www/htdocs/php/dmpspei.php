<?php
// dmpspei.php - "DMP speichern": AJAX-Endpunkt, der von anzeig.php und
// ianzeig.php aus aufgerufen wird, wenn im Patientenlaufzettel der
// DMP-Status (Disease-Management-Programm, z.B. Diabetes) geändert wird.
// Erwartet POST-Felder pid (Patienten-ID), dmp (Textstatus, s.
// $de-Zuordnung unten) und zp (Zeitpunkt); schreibt zusammen mit der
// Aufrufer-IP einen neuen Datensatz in die Tabelle dmperg (History-Tabelle,
// kein UPDATE - jede Änderung bleibt als eigene Zeile erhalten) und gibt
// {"statusCode":200} bzw. bei SQL-Fehler {"statusCode":201} (plus das
// SQL-Statement im Klartext - nur zur Fehlersuche, nicht für den
// Produktivbetrieb gedacht) als JSON zurück. Zugangsdaten kommen aus
// phppwd.php (von setmariadbpwdfuerpraxis.sh gepflegt).
	$servername = "linux1";
include '../../phppwd.php';
	$db="quelle";
	$conn = mysqli_connect($servername, $user, $pwt,$db);
  $pid=$_POST['pid'];
	$resu=$_POST['dmp'];
  $zp=$_POST['zp'];
  $pc=$_SERVER['REMOTE_ADDR'];
  switch($resu){case"ungeklaert":$de=0;break;case"nein":$de=1;break;case"HA":$de=2;break;case"hier":$de=3;break;case"ausgeschrieben":$de=4;break;}
	$sql = "INSERT INTO dmperg(pat_id,dmp,zp,pc) VALUES('$pid','$de','$zp','$pc')";
	if (mysqli_query($conn, $sql)) {
		echo json_encode(array("statusCode"=>200));
     $_SESSION['dmpf']=0;
	} 
	else {
		echo json_encode(array("statusCode"=>201));
    echo $sql;
	}
	mysqli_close($conn);
?>
 
