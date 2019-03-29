function liesein(var,datei) {
	i=0;
	while ((getline var[++i] < datei)>0) {
	}
	delete var[i];
	close(datei);
}

BEGIN {
	IGNORECASE=1;
	liesein(ch,"cronhier");
	liesein(cl,"cronslinux1");

	for(i in ch) {
		obschreib=1;
		for(j in cl) {
			if (ch[i]==cl[j]) {
				obschreib=0;
			  break;
			}
		}
		if (obschreib) {
			print i,ch[i];
		}
	}
	for(j in cl) {
		print j,cl[j];
	}
}
