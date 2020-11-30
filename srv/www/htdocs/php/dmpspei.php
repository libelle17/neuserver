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
	$sql = "INSERT INTO dmperg(pat_id,dmp,zp,pc) VALUES('$pid','$resu','$zp','$pc')";
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
 
