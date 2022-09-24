<?php
	$servername = "linux1";
	$username = "praxis";
	$password = "sonne";
	$db="quelle";
	$conn = mysqli_connect($servername, $username, $password,$db);
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
 
