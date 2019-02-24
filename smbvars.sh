# diese Datei wurde von Hand erstellt; bitte nicht maschinell verändern
BEGIN {
	N[0]="usershare allow guests"; 	I[0]="No";
	N[1]="usershare max shares"; 		I[1]="1000";
	N[2]="passdb backend"; 					I[2]="tdbsam";
	N[3]="ntlm auth"; 							I[3]="yes";
	N[4]="wins server"; 						I[4]="";
	N[5]="wins support"; 						I[5]="No";
	N[6]="WORKGROUP"; 							I[6]="GSHEIM";
	N[7]="passdb backend";					I[7]="tdbsam";
	N[8]="map to guest"; 						I[8]="bad user";
	N[9]="logon drive";							I[9]="P:";
N[10]="unix charset"; 						I[10]="UTF-8";
N[11]="dos charset"; 							I[11]="CP1250";
N[12]="security"; 								I[12]="user";
N[13]="add machine script"; 			I[13]="/usr/sbin/useradd -c Machine -d /var/lib/nobody -s /bin/false %m$";
N[14]="domain logons"; 						I[14]="No";
N[15]="domain master"; 						I[15]="Auto";
N[16]="username map"; 						I[16]="/etc/samba/smbusers";
N[17]="socket options"; 					I[17]="TCP_NODELAY";
N[18]="hosts allow"; 	 						I[18]="192.168.178.0/24 10.0.0.0/14 10.5.0.";
N[19]="interfaces"; 	 						I[19]="192.168.178.0/24 10.0.0.0/14 10.5.0.";
N[20]="time server"; 				  		I[20]="Yes";
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
