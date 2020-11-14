<?php 
// session_destroy();
function tausch(&$a,&$b) {
 $c=$a;
 $a=$b;
 $b=$c;
}

function dotausch($conn, $i) {        
        tausch($_SESSION['arr'][$i],$_SESSION['arr'][$i-1]);
        tausch($_SESSION['erl'][$i],$_SESSION['erl'][$i-1]);
        tausch($_SESSION['gel'][$i],$_SESSION['gel'][$i-1]);
        tausch($_SESSION['per'][$i],$_SESSION['per'][$i-1]);
        $eintrag="update zutun set pos=0 where pat_id =".$_SESSION['pat_id']." and pos=".($i+1)." and date(aktzeit)=date(now());";
        $ergeb=$conn->query($eintrag);
        $eintrag="update zutun set pos=".($i+1)." where pat_id =".$_SESSION['pat_id']." and pos=".($i)." and date(aktzeit)=date(now());";
        $ergeb=$conn->query($eintrag);
        $eintrag="update zutun set pos=".($i)." where pat_id =".$_SESSION['pat_id']." and pos=0 and date(aktzeit)=date(now());";
        $ergeb=$conn->query($eintrag);
}        

// $pc=$_SERVER['SERVER_NAME'];
$pc="localhost";
$user="praxis";
$pwt="sonne";
$db="quelle";
// $link = mysqli_connect($pc,$user,$pwt) or die ("Keine Verbindung zu $pc als $user moeglich");
// mysqli_select_db($link,$db) or die ("Die Datenbank $db existiert nicht"); 
// echo "pc: ".$pc." user: ".$user." pwt: ".$pwt." db: ".$db."<br>";
$conn = new mysqli($pc,$user,$pwt,$db);
if ($conn->connect_error) {
  if ($conn->connect_error=="Connection refused") {
    $ergeb=shell_exec('sudo systemctl start mysql');
    if ($ergeb) {
      echo("Ergebnis beim Versuch, mysql zu starten: <pre>".$ergeb."</pre><br>");
    } else {
      $conn = new mysqli($pc,$user,$pwt,$db);
    }
  }
  echo "Fehler: ".$conn->connect_error."<br>";
  if (substr($conn->connect_error,0,16)=="Unknown database") {
    echo "unbekannte Datenbank<br>";
    $conn=new mysqli($pc,$user,$pwt);
    if (!$conn->connect_error) {
      $sql="CREATE DATABASE `".$db."`;";
      $result=$conn->query($sql);
      $sql="USE `".$db."`";
      $result=$conn->query($sql);
    }
  }
} // $conn->connect_error
if ($conn->connect_error) {
 echo("Datenbankverbindung zu '".$pc."' als '".$user."' fehlgeschlagen: ".$conn->connect_error."<br>");
} else {
  $sql="CREATE TABLE if not exists `zutun` (`id` int(10) unsigned NOT NULL AUTO_INCREMENT, `Pat_ID` int(10) unsigned NOT NULL,`pos` int(10) unsigned NOT NULL,".
  "`Beschreib` varchar(200) COLLATE latin1_german2_ci NOT NULL,`AktZeit` datetime NOT NULL, `AktPC` varchar(20) COLLATE latin1_german2_ci NOT NULL,".
  "`Person` char(1) NOT NULL comment \"A=anwesend, A=anwesend an Behandler, V=Vorbereiter, v=Vorbereiter an Behandler, B=Behandler\",".
  "`Vorbereiter` char(5) NOT NULL comment \"Namenskuerzel Vorbereiter\",".
  "`Behandler` char(5) NOT NULL comment \"Namenskuerzel Behandler\",".
  "`erlZeit` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',`erlPC` varchar(20) COLLATE latin1_german2_ci NOT NULL DEFAULT '',".
  "`gelZeit` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',`gelPC` varchar(20) COLLATE latin1_german2_ci NOT NULL DEFAULT '',".
  "PRIMARY KEY (`id`),KEY `PAT_ID` (`Pat_ID`,`AktZeit`)) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT CHARSET=latin1 COLLATE=latin1_german2_ci COMMENT='elektrifizierter Laufzettel'";
  $result=$conn->query($sql);
  $sql="CREATE TABLE if not exists `aktiv` (".
    "`id` int(10) unsigned NOT NULL AUTO_INCREMENT,".
    "`Pat_ID` int(10) unsigned NOT NULL,".
    "`Person` char(1) NOT NULL comment \"A=anwesend, A=anwesend an Behandler, V=Vorbereiter, v=Vorbereiter an Behandler, B=Behandler\",".
    "`Vorbereiter` char(5) NOT NULL comment \"Namenskuerzel Vorbereiter\",".
    "`Behandler` char(5) NOT NULL comment \"Namenskuerzel Behandler\",".
    "`ob` int(1) comment \"0=inaktiv, 1=aktiv\",".
    "`AktZeit` datetime NOT NULL,".
    "`AktPC` varchar(20) COLLATE latin1_german2_ci NOT NULL,".
    "PRIMARY KEY (`id`),".
    "KEY `PAT_ID` (`Pat_ID`,`AktZeit`)".
    ") ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 COLLATE=latin1_german2_ci COMMENT='Laufzettel Bearbeitungsdokumentation';";
  $result=$conn->query($sql);
}
// echo "<pre>"; var_dump($_POST); echo "</pre>";
$basen=ltrim(basename("..".$_SERVER['PHP_SELF']));
$copyq="../plz/".$basen;
$zvorb="../vorb/".$basen;
$zvorbakt="../vorb/  ".$basen;
$zbehand="../behand/".$basen;
$zbehandakt="../behand/  ".$basen;
$zfertig="../fertig/".$basen;
$sqlzutun="select beschreib,(erlZeit!=date(0)) erl,(gelZeit!=date(0)) gel,Person per  from zutun ".
          "where pat_id =".$pat_id." and date(aktzeit)=date(now()) order by pos;";
//  echo "session pat_id ".$_SESSION['pat_id']." pat_id: ".$pat_id."<br>";
if (!isset($_SESSION['pat_id'])) $init=1; else if ($_SESSION['pat_id']!=$pat_id) $init=1; else $init=0;
if ($init) {
    unset($_SESSION['arr']);
    unset($_SESSION['erl']);
    unset($_SESSION['gel']);
    unset($_SESSION['per']);
    unset($_SESSION['aufgaben']);
    $_SESSION['blenden'] = 1;
    $_SESSION['anwesend']=0;
    $_SESSION['obvorb']=0;
    $_SESSION['anbeh']=0;
    $_SESSION['obbeha']=0;
    $ergeb=$conn->query($sqlzutun);
    $_SESSION['numrows'] = (!$ergeb->num_rows);
    $_SESSION['loeschen'] = (!$ergeb->num_rows);
}

$_SESSION['pat_id']=$pat_id;
/*
if (!isset($_SESSION['anwesend'])) $_SESSION['anwesend']=0;
if (!isset($_SESSION['obvorb'])) $_SESSION['obvorb']=0;
if (!isset($_SESSION['anbeh'])) $_SESSION['anbeh']=0;
if (!isset($_SESSION['obbeha'])) $_SESSION['obbeha']=0;
if (!isset($_SESSION['blenden'])) $_SESSION['blenden']=0;
if (!isset($_SESSION['loeschen'])) $_SESSION['loeschen']=0;
*/
$_SESSION['person']=$_SESSION['obvorb']?($_SESSION['anbeh']?"v":"V"):($_SESSION['obbeha']?"B":($_SESSION['anbeh']?"a":"A"));

if(isset($_POST['ma']))  $_SESSION['ma']=$_POST['ma'];
if(isset($_POST['bh']))  $_SESSION['bh']=$_POST['bh'];
if(isset($_POST['eintragen'])) {
  if(isset($_POST['aufgaben'])) if ($_POST['aufgaben']) {
    $obneu=0;
    if(isset($_SESSION['aufgaben'])) {
      if ($_POST['aufgaben']!=$_SESSION['aufgaben']) $obneu=1;
    } else $obneu=1;
    if ($obneu) {
      $schondrin=0;
      if (isset($_SESSION['arr'])) for($i=0;$i<count($_SESSION['arr']);$i++) if ($_SESSION['arr'][$i]==$_POST['aufgaben']) {
        // wenn geloescht, wieder aktivieren; wenn erledigt, dann erledigt lassen 
        if ($_SESSION['gel'][$i]) {
         $_SESSION['gel'][$i]=0;
        } else {
         $schondrin=1;
        }
        break;
      }
      if (!$schondrin) {
        $_SESSION['arr'][]=$_POST['aufgaben'];
        $_SESSION['erl'][]=0;
        $_SESSION['gel'][]=0;
        $_SESSION['per'][]=$_SESSION['person'];
        $eintrag="insert into zutun(pat_id,pos,beschreib,AktZeit,AktPC,Person,Vorbereiter,Behandler) ".
                 "values (".$_SESSION['pat_id'].",".count($_SESSION['arr']).",'".$_POST['aufgaben']."',now(),'".$_SERVER['REMOTE_ADDR']
                 ."','".$_SESSION['person']."','".$_SESSION['ma']."','".$_SESSION['bh']."');";
        //    echo $eintrag."<br>";
        $ergeb=$conn->query($eintrag);
      }
    }
    $_SESSION['aufgaben']=$_POST['aufgaben'];
  } else {
  }
} else {
  $myaktiv=0;
  $myvorb=0;
  $mybeh=0;
  if(isset($_POST['anwesend'])) {
   $_SESSION['anwesend']=!$_SESSION['anwesend'];
   if (file_exists($zvorbakt)) unlink($zvorbakt);
   if (file_exists($zbehand)) unlink($zbehand);
   if (file_exists($zbehandakt)) unlink($zbehandakt);
   if (file_exists($zfertig)) unlink($zfertig);
   if ($_SESSION['anwesend']==1) {
    if (!file_exists($zvorb)) copy($copyq,$zvorb);
   } else {
     if (file_exists($zvorb)) unlink($zvorb);
   }
   if ($_SESSION['obvorb']) {
     $_SESSION['obvorb']=0;
     $myvorb=1;
   }
   if ($_SESSION['obbeha']) {
     $_SESSION['obbeha']=0;
     $mybeh=1;
   }
   $myaktiv=1;
} else if(isset($_POST['obvorb'])) {
   if ($_SESSION['ma']=='') {
    echo "<script>alert('Wer sind Sie (bitte Kuerzel eingeben)?');</script>";
   } else {
   $_SESSION['obvorb']=!$_SESSION['obvorb'];
   $_SESSION['anbeh']=0;
   $_SESSION['obbeha']=0;
   if (!$_SESSION['anwesend']) {
     $_SESSION['anwesend']=1;
     $myaktiv=1;
   }
   if (file_exists($zvorb)) rename($zvorb,$zvorbakt);
   if ($_SESSION['obvorb']==1) {
     if (file_exists($zbehand)) unlink($zbehand);
     if (file_exists($zfertig)) unlink($zfertig);
     if (!file_exists($zvorbakt)) copy($copyq,$zvorbakt);
   } else {
     if (file_exists($zvorbakt)) rename($zvorbakt,$zbehand);
     else copy($copyq,$zbehand);
   }
   $myvorb=1;
   }
} else if(isset($_POST['obbeha'])) {
   if ($_SESSION['bh']=='') {
    echo "<script>alert('Wer sind Sie (bitte Kuerzel eingeben)?');</script>";
   } else {
   $_SESSION['obbeha']=!$_SESSION['obbeha'];
   $_SESSION['anbeh']=0;
   if ($_SESSION['obvorb']) {
     $_SESSION['obvorb']=0;
     $myvorb=1;
   }
   if (!$_SESSION['anwesend']) {
     $_SESSION['anwesend']=1;
     $myaktiv=1;
   }
     if (file_exists($zbehand)) rename($zbehand,$zbehandakt);
   if ($_SESSION['obbeha']==1) {
     if (file_exists($zvorb)) unlink($zvorb);
     if (file_exists($zfertig)) unlink($zfertig);
     if (!file_exists($zbehandakt)) copy($copyq,$zbehandakt);
   } else {
     if (file_exists($zbehandakt)) rename($zbehandakt,$zfertig);
     else copy($copyq,$zfertig);
   }
   $mybeh=1;
   }
} else if(isset($_POST['anbeh'])) {
  $_SESSION['anbeh']=!$_SESSION['anbeh'];
  if ($_SESSION['obbeha']==1) {
    $_SESSION['obbeha']=0;
    $mybeh=1;
  }
} else if(isset($_POST['alleloeschen']) || isset($_POST['blenden'])) {
  if(isset($_POST['alleloeschen'])) {
    $_SESSION['loeschen']=!$_SESSION['loeschen'];
    if ($_SESSION['loeschen']) {
      $eintrag="update zutun set gelZeit=date(0),gelpc='' ".
        "where pat_id = ".$_SESSION['pat_id']." and date(aktzeit)=date(now());";
    } else {
      $eintrag="update zutun set gelZeit=now(),gelpc='".$_SERVER['REMOTE_ADDR'].
        "' where pat_id = ".$_SESSION['pat_id']." and date(aktzeit)=date(now());";
    }
    $ergeb=$conn->query($eintrag);
  } else if(isset($_POST['blenden'])) {
   $_SESSION['blenden']=!$_SESSION['blenden'];
  }
  unset($_SESSION['arr']);
  unset($_SESSION['erl']);
  unset($_SESSION['gel']);
  unset($_SESSION['per']);
  unset($_SESSION['aufgaben']);
} else {
  if (isset($_SESSION['arr'])) {
    for ($i=0;$i<count($_SESSION['arr']);$i++) {
      $erlknopf="erlknopf".$i;
      if (isset($_POST[$erlknopf])) {
        $_SESSION['erl'][$i]=!$_SESSION['erl'][$i];
        $eintrag="update zutun set erlZeit=if(erlZeit=date(0),now(),date(0)),erlPC='".$_SERVER['REMOTE_ADDR'].
               "' where pat_id = ".$_SESSION['pat_id']." and date(aktzeit)=date(now()) and pos=".($i+1).";";
        //    echo $eintrag."<br>";
        $ergeb=$conn->query($eintrag);
        $allefertig=1;
        for($j=0;$j<count($_SESSION['erl']);$j++) {
         if (!$_SESSION['erl'][$j]) {$allefertig=0;break;}
        }
        if ($allefertig) {
          if (file_exists($zfertig)) unlink($zfertig);
          $_SESSION['anwesend']=0;
          echo "<meta http-equiv='refresh' content='0; URL=http://linux1/fertig/'>";
          exit;
        } else {
         if (!$_SESSION['obvorb']) if (!$_SESSION['obbeha'])
         if (!file_exists($zfertig)) copy($copyq,$zfertig);
        }
        break;
      }
      $gelknopf="gelknopf".$i;
      if (isset($_POST[$gelknopf])) {
        $_SESSION['gel'][$i]=!$_SESSION['gel'][$i];
        $eintrag="update zutun set gelZeit=if(gelZeit=date(0),now(),date(0)),gelPC='".$_SERVER['REMOTE_ADDR'].
               "' where pat_id = ".$_SESSION['pat_id']." and date(aktzeit)=date(now()) and pos=".($i+1).";";
        //    echo $eintrag."<br>";
        $ergeb=$conn->query($eintrag);
        break;
      }
      $aufknopf="aufknopf".$i;
      if ($i) if (isset($_POST[$aufknopf])) {
        dotausch($conn, $i);
        break;
      }
      $abknopf="abknopf".$i;
      if ($i<count($_SESSION['arr'])-1) if (isset($_POST[$abknopf])) {
        dotausch($conn, $i+1);
        break;
      }
    }
  }
}
// in Datenbank eintragen, wann anwesend gedrueckt wurde
if ($myaktiv) {
   $eintrag="insert into aktiv(pat_id,Person,Vorbereiter,Behandler,ob,AktZeit,AktPC) ".
            "values(".$_SESSION['pat_id'].",'".($_SESSION['anbeh']?"a":"A")."','".$_SESSION['ma']."','".$_SESSION['bh']."','".($_SESSION['anwesend']?"1":"0")."',now(),'".$_SERVER['REMOTE_ADDR']."');";
   $ergeb=$conn->query($eintrag);
}
// in Datenbank eintragen, wann Vorbereitung gedrueckt wurde
if ($myvorb) {
     $eintrag="insert into aktiv(pat_id,Person,Vorbereiter,Behandler,ob,AktZeit,AktPC) ".
              "values(".$_SESSION['pat_id'].",'".($_SESSION['anbeh']?"v":"V")."','".$_SESSION['ma']."','".$_SESSION['bh']."','".($_SESSION['obvorb']?"1":"0")."',now(),'".$_SERVER['REMOTE_ADDR']."');";
     $ergeb=$conn->query($eintrag);
}
// in Datenbank eintragen, wann Behandlung gedrueckt wurde
if ($mybeh) {
     $eintrag="insert into aktiv(pat_id,Person,Vorbereiter,Behandler,ob,AktZeit,AktPC) ".
              "values(".$_SESSION['pat_id'].",'B','".$_SESSION['ma']."','".$_SESSION['bh']."','".($_SESSION['obbeha']?"1":"0")."',now(),'".$_SERVER['REMOTE_ADDR']."');";
     $ergeb=$conn->query($eintrag);
}
}
if ($_SESSION['blenden']) {
  if (!isset($_SESSION['arr'])) {
    $ergeb=$conn->query($sqlzutun);
    if ($ergeb->num_rows >0) {
      while($row = $ergeb->fetch_assoc()) {
        $_SESSION['arr'][]=$row["beschreib"];
        $_SESSION['erl'][]=$row["erl"];
        $_SESSION['gel'][]=$row["gel"];
        $_SESSION['per'][]=$row["per"];
      }
    }
  }
}
if (isset($_SESSION['arr'])) {
  echo "<form action='".$copyq."' method=\"POST\"><ol style=\"margin-top:0em;margin-bottom:-1em;\">";
  foreach ($_SESSION['arr'] as $nr => $value) {
    if (!$_SESSION['gel'][$nr]) {
      if (!$_SESSION['erl'][$nr]) {
        $stil="border-style:groove;border-width:thin;border-color:blue;color:".($_SESSION['per'][$nr]=="a"||$_SESSION['per'][$nr]=="v"?"blue":"crimson").";background-color:cornsilk;";
      } else {
        $stil="color:silver;background-color:white;";
      }
      echo "<li><div style=\"height:1em;overflow:hidden;float:left;\">".
      "<div style=\"".$stil."width:170px;white-space:nowrap;float:left;height:2.25em;padding-right:15px;overflow:auto;position:relative;\">".
      $value."</div></div>";
      echo "<button type=\"submit\" style=\"width:60px;\" name=\"erlknopf".$nr."\">".($_SESSION['erl'][$nr]?"aktivier":"erledigt")."</button>";
      echo "<button type=\"submit\" name =\"aufknopf".$nr."\">&uarr;</button>";
      echo "<button type=\"submit\" name =\"abknopf".$nr."\">&darr;</button>";
      echo "<button type=\"submit\" name =\"gelknopf".$nr."\">löschen</button></li>";
    }
  }
  echo "</ol></form>";
}
$conn->close();

echo "<a name='AnkerEing' href='#AnkerEing' accesskey='e'></a>";

$stilaus="color:lightgray;background-color:white;";
$stilan="border-style:groove;border-width:thin;border-color:blue;color:crimson;background-color:cornsilk;";

echo "<form id='aufgabenform' name='aufgabenform' action='".$copyq."' method='POST'>";
$focus1="";$focus2="";$focus3="";
if (!$_SESSION['obvorb'] && !$_SESSION['obbeha'] && !$_SESSION['anbeh']) {
    if ($_SESSION['ma']=='') $fucus2="autofocus"; else $focus3="autofocus";
} else $focus1="autofocus";
if ($_SESSION['anwesend']) {
  echo "<input type='submit' style=\"position:absolute;width:0px;left:622px;\" value='&crarr;' name='eintragen' />"; 
  $text="&#9993;Beh.";
  if ($_SESSION['anbeh']) {
    $stil=$stilan;
  } else {
    $stil=$stilaus;
  }
  echo "<button style='.$stil.' name='anbeh' >".$text."</button>";

  if ($_SESSION['anbeh']) $li="li1"; else if ($_SESSION['obbeha'] || $_SESSION['obvorb']) $li="li2"; else $li="li0";
  echo "<input type='text' id='aufgaben' name='aufgaben' list='$li' autocomplete='off' size='90' style='border-right-width:13px;height:22px;background-color: #FFCC99;' ".$focus1.">";
}
?>
<datalist id="li0">
<!-- DL1a Anmeldung an Vorbereiter-->
  <option value="HA nochmal anrufen wegen Vorbefuden">
  <option value="neues BZ-Meßgerät">
  <option value="neues Blutdruckmessgerät">
  <option value="pass auf!">
<!-- DL_e -->
</datalist>
<datalist id="li1">
<!-- DL2a Vorbereiter an Behandler -->
  <option value="Fußpulse überprüfen">
  <option value="Pat. vom DMP überzeugen">
  <option value="kleine Zehe anschauen">
<!-- DL_e -->
</datalist>
<datalist id="li2">
<!-- DL3a Vorbereiter/Behandler an Anmeldung -->
  <option value="RR-Vergleich nochmal">
  <option value="Rezept">
  <option value="Kompressionsverband">
  <option value="Labor: Dia, Eingang, TSH">
  <option value="DMP klären">
  <option value="Wundverband">
<!-- DL_e -->
</datalist>
</input>
<script>
// habe ich leider noch nicht zum funzen gebracht
/*
function welcher() {
 var person=prompt("Bitte Namenskuerzel eingeben");
// if (person!=NULL) {
  document.getElementById("Mitarbeiter").value = person;
  document.getElementByName("aufgabenform").submit();
// }
}
*/
</script>
<?php
// echo "<input type='hidden' id='Mitarbeiter' value=''>";
if ($_SESSION['anwesend']) {
  $stil=$stilan;
//  $text="&#10170;alles&#160;<u>f</u>ertig";
  $text="&#10170;von&#160;vo<u>r</u>ne";
  $accessk="r";
} else {
  $stil=$stilaus;
  $text="an<u>w</u>esend";
  $accessk="w";
}
echo "<button type='submit' style='.$stil.' id='anwesend' name='anwesend' accesskey='$accessk'>".$text."</button>";

if ($_SESSION['obvorb']) {
  $stil=$stilan;
  $text="&#10170;<u>V</u>orb.fertig";
} else {
  $stil=$stilaus;
  $text="<u>V</u>orbereiter";
}
// if (isset($_POST['Mitarbeiter'])) echo "Mitarbeiter: ".$_POST['Mitarbeiter'];
if (!isset($_SESSION['ma'])) $_SESSION['ma']='';
if (!$_SESSION['obvorb'] && !$_SESSION['obbeha']) {
  echo "<u>M</u>A: <input type='text' name='ma' accesskey='m' style='width:20px;background-color:peachpuff;' value='".$_SESSION['ma']."' ".$focus2."/> ";
} else {
  echo "MA: <font color=blue>".$_SESSION['ma']."</font> ";
}
echo "<button type='submit' /*onclick='welcher()'*/ style='.$stil.' name='obvorb' accesskey='v'>".$text."</button>";

if ($_SESSION['obbeha']) {
  $stil=$stilan;
  $text="&#10170;Beh<u>.</u>fertig";
  $accessk=".";
} else {
  $stil=$stilaus;
  $text="Beha<u>n</u>dler";
  $accessk="n";
}
if (!isset($_SESSION['bh'])) $_SESSION['bh']='';
if (!$_SESSION['obvorb'] && !$_SESSION['obbeha']) {
  echo "Bh: <input type='text' name='bh' accesskey='m' style='width:20px;background-color:peachpuff;' value='".$_SESSION['bh']."' ".$focus3."/> ";
} else {
  echo "Bh: <font color=blue>".$_SESSION['bh']."</font> ";
}
echo "<button type='submit' style='.$stil.' name='obbeha' accesskey='$accessk'>".$text."</button>";
echo "<input type='submit' value=".($_SESSION['blenden']?"ausblenden":"einblenden")." name='blenden' />";
echo "session numrows: ".$_SESSION['numrows']." count: ".count($_SESSION['arr']);
if ($_SESSION['numrows'] || count($_SESSION['arr'])) {
    echo "<input type='submit' value=".($_SESSION['loeschen']?"alle&#160;loeschen":"wiederherstellen")." name='alleloeschen' />";
    }
?>
</form>
