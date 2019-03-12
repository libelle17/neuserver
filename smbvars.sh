# diese Datei wurde von Hand erstellt; bitte nicht maschinell verändern
BEGIN {
	N[0]="usershare allow guests"; 	I[0]="No";
	N[1]="usershare max shares"; 		I[1]="1000";
	N[2]="passdb backend"; 					I[2]="tdbsam";
	N[3]="ntlm auth"; 							I[3]="yes";
	N[4]="wins server"; 						I[4]="";
	N[5]="wins support"; 						I[5]="No";
	N[6]="WORKGROUP"; 							I[6]="praxis";
	N[7]="map to guest"; 						I[7]="bad user";
	N[8]="logon drive";							I[8]="P:";
  N[9]="unix charset"; 						I[9]="UTF-8";
N[10]="dos charset"; 							I[10]="CP1250";
N[11]="security"; 								I[11]="user";
N[12]="add machine script"; 			I[12]="/usr/sbin/useradd -c Machine -d /var/lib/nobody -s /bin/false %m$";
N[13]="domain logons"; 						I[13]="No";
N[14]="domain master"; 						I[14]="Auto";
N[15]="username map"; 						I[15]="/etc/samba/smbusers";
N[16]="socket options"; 					I[16]="TCP_NODELAY";
N[17]="hosts allow"; 	 						I[17]="192.168.178.0/24 10.0.0.0/14 10.5.0.";
N[18]="interfaces"; 	 						I[18]="192.168.178.0/24 10.0.0.0/14 10.5.0.";
N[19]="time server"; 				  		I[19]="Yes";
Na[0]="comment";									Ia[0]="";
Na[1]="path";											Ia[1]="";
Na[2]="directory mask";						Ia[2]="0660";
Na[3]="browseable";								Ia[3]="Yes";
Na[4]="read only";								Ia[4]="no";
Na[5]="vfs objects";							Ia[5]="recycle";
Na[6]="recycle:versions";					Ia[6]="Yes";
Na[7]="recycle:keeptree";					Ia[7]="Yes";
Na[8]="recycle:repository";				Ia[8]="Papierkorb";
Na[9]="available";								Ia[9]="Yes";
}
