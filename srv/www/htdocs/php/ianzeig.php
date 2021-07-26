<?php 
class zutun_cls 
{
  public static $basen; // =ltrim(basename("..".$_SERVER['PHP_SELF']));
  public static $copyq; // ="../plz/".$basen;
// Einzug, damit in vim alt-gr+[ funktioniert, um zum Funktionsanfang zu kommen
// tauscht zwei Variable aus
function tausch(&$a,&$b) 
{
    $c=$a;
    $a=$b;
    $b=$c;
  }

  // tauscht die Reihenfolge zweier Zutun-Eiintraege aus:
function dotausch($conn, $pat_id, $i) 
{
    //      ... auf dem Bildschirm ...
    self::tausch($_SESSION['arr'][$i],$_SESSION['arr'][$i-1]);
    self::tausch($_SESSION['erl'][$i],$_SESSION['erl'][$i-1]);
    self::tausch($_SESSION['gel'][$i],$_SESSION['gel'][$i-1]);
    self::tausch($_SESSION['obk'][$i],$_SESSION['obk'][$i-1]);
    self::tausch($_SESSION['kom'][$i],$_SESSION['kom'][$i-1]);
    self::tausch($_SESSION['per'][$i],$_SESSION['per'][$i-1]);
    self::tausch($_SESSION['aut'][$i],$_SESSION['aut'][$i-1]);
    //      ... und in der Datenbank.
    $sql="UPDATE zutun SET pos=0 WHERE pat_id =".$pat_id." AND pos=".($i+1)." AND DATE(aktzeit)=DATE(now());";
    //$ergeb=$conn->query($sql);
    $ergeb=self::abfrage($conn,$sql);
    $sql="UPDATE zutun SET pos=".($i+1)." WHERE pat_id =".$pat_id." AND pos=".($i)." AND DATE(aktzeit)=DATE(now());";
    //$ergeb=$conn->query($sql);
    $ergeb=self::abfrage($conn,$sql);
    $sql="UPDATE zutun SET pos=".($i)." WHERE pat_id =".$pat_id." AND pos=0 AND DATE(aktzeit)=DATE(now());";
    //$ergeb=$conn->query($sql);
    $ergeb=self::abfrage($conn,$sql);
  }        

  // holt die zu einem Patienten gespeicherten Zutun-Eintraege aus der Datenbank
function getdb($conn,$pat_id) 
{
    if (isset($_SESSION['arr'])) unset($_SESSION['arr']);
    if (isset($_SESSION['erl'])) unset($_SESSION['erl']);
    if (isset($_SESSION['gel'])) unset($_SESSION['gel']);
    if (isset($_SESSION['obk'])) unset($_SESSION['obk']);
    if (isset($_SESSION['kom'])) unset($_SESSION['kom']);
    if (isset($_SESSION['per'])) unset($_SESSION['per']);
    if (isset($_SESSION['aut'])) unset($_SESSION['aut']);
    $_SESSION['aufgaben']="";
//    $_SESSION['anbeh']=0;
    $sqlzutun="SELECT beschreib,kommentar kom,(erlZeit!=DATE(0)) erl,(gelZeit!=DATE(0)) gel,Person per,".
      "IF(Person='a','__',IF(Person='v',Vorbereiter,BehANDler)) aut ".
      "FROM zutun WHERE pat_id =".$pat_id." AND DATE(aktzeit)=DATE(now()) ORDER BY pos;";
    //$ergeb=$conn->query($sqlzutun);
    $ergeb=self::abfrage($conn,$sqlzutun);
    // echo "<pre>";var_dump($conn);echo "</pre>";
    // echo "<pre>Ergeb: "; var_dump($ergeb); echo "</pre>";
    if ($ergeb->num_rows >0) {
      while($row = $ergeb->fetch_assoc()) {
        $_SESSION['arr'][]=$row['beschreib']; // Zutun-Texte
        $_SESSION['kom'][]=$row['kom'];       // Kommentar
        $_SESSION['erl'][]=$row['erl'];       // erledigt-Kennzeichen
        $_SESSION['gel'][]=$row['gel'];       // geloescht-Kennzeichen
        $_SESSION['obk'][]=($row['kom']!=''); // obKommentar-Kennzeichen
        $_SESSION['per'][]=$row['per'];       // Personenart des Eintragenden (Person)
        $_SESSION['aut'][]=$row['aut'];       // Autor, Kuerzel des Eintragenden (Vorbereiter/Behandler)
      }
    } 

    $_SESSION['anwesend']=0;
    unset($_SESSION['anwseit']);
    $sqlaktiv="SELECT AktZeit az FROM aktiv WHERE pat_id=".$pat_id." AND person IN ('A','a') AND DATE(AktZeit)=DATE(now()) ORDER BY aktzeit DESC;";
    //$ergeb=$conn->query($sqlaktiv);
    $ergeb=self::abfrage($conn,$sqlaktiv);
    if ($ergeb->num_rows >0) {
      while($row=$ergeb->fetch_assoc()) {
        $_SESSION['anwseit']=new DateTime($row['az']); // anwesend seit
        $_SESSION['anwesend']=1;
        break;
      }
    }
    if (!isset($_SESSION['anwseit'])) {
      $_SESSION['anwseit']=new DateTime("00:00");
    }

//    $_SESSION['obvorb']=0;
    unset($_SESSION['vorseit']);
    $sqlaktiv="SELECT AktZeit az FROM aktiv WHERE pat_id=".$pat_id." AND person IN ('V','v') AND DATE(AktZeit)=DATE(now()) ORDER BY aktzeit DESC;";
    //$ergeb=$conn->query($sqlaktiv);
    $ergeb=self::abfrage($conn,$sqlaktiv);
    if ($ergeb->num_rows >0) {
      while($row=$ergeb->fetch_assoc()) {
        $_SESSION['vorseit']=new DateTime($row['az']); // obvorb seit
        $_SESSION['obvorb']=1;
        break;
      }
    }
    if (!isset($_SESSION['vorseit'])) {
      $_SESSION['vorseit']=new DateTime("00:00");
    }

//    $_SESSION['obbeha']=0;
    unset($_SESSION['behseit']);
    $sqlaktiv="SELECT AktZeit az FROM aktiv WHERE pat_id=".$pat_id." AND person IN ('B','b') AND DATE(AktZeit)=DATE(now()) ORDER BY aktzeit DESC;";
    //$ergeb=$conn->query($sqlaktiv);
    $ergeb=self::abfrage($conn,$sqlakiv);
    if ($ergeb->num_rows >0) {
      while($row=$ergeb->fetch_assoc()) {
        $_SESSION['behseit']=new DateTime($row['az']); // obbeha seit
        $_SESSION['obvorb']=0;
        $_SESSION['obbeha']=1;
        break;
      }
    }
    if (!isset($_SESSION['behseit'])) {
      $_SESSION['behseit']=new DateTime("00:00");
    }
  } // getdb

// zeigt alle bisherigen Eintraege zu aktuellem Patienten an
function zeiggeschichte($conn,$pat_id)
{
  /*  ?> <script>alert("rufe zeiggeschichte() auf!");</script> <?php */
$sqlzutun="SELECT beschreib inh, kommentar kom, (erlZeit!=DATE(0)) erl,(gelZeit!=DATE(0)) gel, Person per,".
"IF(Person='a','__', IF(Person='v',Vorbereiter,Behandler)) aut, aktzeit az, pos ".
"FROM zutun WHERE pat_id =".$pat_id." ORDER BY aktzeit, pos;"; //AND DATE(AktZeit)<DATE(now()) 
//$ergeb=$conn->query($sqlzutun);
$ergeb=self::abfrage($conn,$sqlzutun);
if ($ergeb->num_rows >0) {
  while($row = $ergeb->fetch_assoc()) {
    $obgel=$row['gel']?"text-decoration: line-through;":"";
    $orange=$row['erl']?"Khaki":"orange";
    $schwarz=$row['erl']?"gray":"black";
    $orgrau=$row['erl']?"BurlyWood":"B18904";
    $blau=$row['erl']?"cyan":"blue";
    $az=new DateTime($row['az']); // anwesend seit
    echo "<span style=\"".$obgel."\">".
      //            "<span style=\"color:".$orgrau.";\">".$row['az']."</span>".
      "<span style=\"color:".$orgrau.";\">".$az->format("d.m.y H:i:s")."</span>".
      "  <span style=\"color:".$schwarz.";\">".$row['aut']." ".$row['per']."</span>".
      "  <span style=\"color:".$orgrau.";\">(".$row['pos'].")</span>".
      "  <span style=\"color:".$orange.";display:inline-block;".$obgel."width:40rem;\">".$row['inh']."</span>".
      "  <span style=\"color:".$blau.";display:inline-block;".$obgel."width:15rem;\">".$row['kom']."</span>".
      "  </span><br>";
  }
}
}

function tragein($conn, $pat_id, $eintrag) 
{
    $schondrin=0;
    if (isset($_SESSION['arr'])) 
      for($i=0;$i<count($_SESSION['arr']);$i++) if ($_SESSION['arr'][$i]==$eintrag) {
        // wenn geloescht, wieder aktivieren; wenn erledigt, dann erledigt lassen 
        if ($_SESSION['gel'][$i]) {
          $_SESSION['gel'][$i]=0;
          $sql="UPDATE zutun SET gelZeit=DATE(0),gelpc='' ".
            "WHERE pat_id = ".$pat_id." AND pos = ".($i+1)." AND DATE(aktzeit)=DATE(now());";
          //$ergeb=$conn->query($sql);
          $ergeb=self::abfrage($conn,$sql);
        }
        $schondrin=1;
        break;
      }
    if (!$schondrin) {
      // neue Zeile
      $_SESSION['arr'][]=$eintrag;
      $_SESSION['erl'][]=0;
      $_SESSION['gel'][]=0;
      $_SESSION['per'][]=$_SESSION['person'];
      $_SESSION['obk'][]=0;
      $_SESSION['kom'][]="";
      $aut="__";
      switch ($_SESSION['person']) {
        case "v": case "V": $aut=$_SESSION['ma']; break;
        case "B":           $aut=$_SESSION['bh']; break;
      }
      $_SESSION['aut'][]=$aut;
      $sql="INSERT INTO zutun(pat_id,pos,beschreib,AktZeit,AktPC,Person,Vorbereiter,Behandler) ".
        "VALUES(".$pat_id.",".count($_SESSION['arr']).",'".$eintrag."',now(),'".$_SERVER['REMOTE_ADDR']
        ."','".$_SESSION['person']."','".$_SESSION['ma']."','".$_SESSION['bh']."');";
      //    echo $sql."<br>";
      //  $ergeb=$conn->query($sql);
      $ergeb=self::abfrage($conn,$sql);
      ?> <script>var erg=<?php echo json_encode($ergeb, JSON_HEX_TAG); ?>;if (!erg) alert("nicht gespeichert!");</script> <?php
      $_SESSION['aufgaben']="";
    }
  }

function abfrage($conn,$sql)
{
  $ret=true;
  if ($sql) {
    if (!($ret=$conn->query($sql))) {
      printf("<pre>Fehler bei: %s </pre>", $sql);
      echo "<pre>"; var_dump($conn->error); echo "</pre>";
      //    printf("Fehler bei: %s %s\n", $sql, $conn->error);
    } else {
//      printf("<pre>Erfolg bei: %s</pre>",$sql);
    } 
  }
  return $ret;
} 

function verarbeite($pat_id,$telnr) 
{
//    echo "<br>obbeha: ".$_SESSION['obbeha']."</br>";
  // Teil 1: Verarbeitungen
//  echo "<pre>Post: "; var_dump($_POST); echo "</pre>";
//  echo "<pre>Session: "; var_dump($_SESSION); echo "</pre>";
  self::$basen=ltrim(basename("..".$_SERVER['PHP_SELF']));
  self::$copyq="../plz/".self::$basen;
  $pc="localhost";      // $pc=$_SERVER['SERVER_NAME'];
  $user="praxis";
  $pwt="sonne";
  $db="quelle";
  date_default_timezone_set("Europe/Berlin");
  // $link = mysqli_connect($pc,$user,$pwt) or die ("Keine Verbindung zu $pc als $user moeglich");
  // mysqli_SELECT_db($link,$db) or die ("Die Datenbank $db existiert nicht"); 
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
        //    $result=$conn->query($sql);
        $ergeb=self::abfrage($conn,$sql);
        $sql="USE `".$db."`";
        // $result=$conn->query($sql);
        $ergeb=self::abfrage($conn,$sql);
      }
    }
  } // $conn->connect_error
  if ($conn->connect_error) {
    echo("Datenbankverbindung zu '".$pc."' als '".$user."' fehlgeschlagen: ".$conn->connect_error."<br>");
  } else {
    $sql="CREATE TABLE if not exists `zutun` (`id` int(10) unsigned NOT NULL AUTO_INCREMENT, `Pat_ID` int(10) unsigned NOT NULL,".
      "`pos` int(10) unsigned NOT NULL,".
      "`Beschreib` varchar(200) COLLATE latin1_german2_ci NOT NULL,".
      "`Kommentar`  varchar(70) COLLATE latin1_german2_ci NOT NULL DEFAULT '',".
      "`AktZeit` datetime NOT NULL, `AktPC` varchar(20) COLLATE latin1_german2_ci NOT NULL,".
      "`Person` char(1) NOT NULL comment \"A=anwesend, a=anwesend an Behandler, V=Vorbereiter, v=Vorbereiter an Behandler, B=Behandler\",".
      "`Vorbereiter` char(5) NOT NULL comment \"Namenskuerzel Vorbereiter\",".
      "`Behandler` char(5) NOT NULL comment \"Namenskuerzel Behandler\",".
      "`erlZeit` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',`erlPC` varchar(20) COLLATE latin1_german2_ci NOT NULL DEFAULT '',".
      "`gelZeit` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',`gelPC` varchar(20) COLLATE latin1_german2_ci NOT NULL DEFAULT '',".
      "PRIMARY KEY (`id`),KEY `PAT_ID` (`Pat_ID`,`AktZeit`)) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT".
      "CHARSET=latin1 COLLATE=latin1_german2_ci COMMENT='elektrifizierter Laufzettel'";
    //      $result=$conn->query($sql);
    //echo "<pre>"; echo("SQL davor: ");var_dump($sql); echo "</pre>";
    $result=self::abfrage($conn, $sql);
    $sql="CREATE TABLE IF NOT EXISTS covdat (".
        "id int(10) UNSIGNED NOT NULL AUTO_INCREMENT,".
        "pfad VARCHAR(256) NOT NULL,".
        "DatEintrag datetime not null,".
        "`AktZeit` DATETIME NOT NULL DEFAULT 0,".
        "PRIMARY KEY (id),".
        "KEY `AktZeit` (`AktZeit`)".
        ") ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8 COLLATE=utf8_german2_ci COMMENT='Covid-Dateiliste';";
    $result=self::abfrage($conn,$sql);
    $sql="CREATE TABLE IF NOT EXISTS `covid` (".
      "`id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,".
      "`Pat_ID` INT(10) UNSIGNED NOT NULL,".
      "`Eintrag` VARCHAR(256) NOT NULL,".
      "`Name` VARCHAR(256) NOT NULL,".
      "`PAlter` FLOAT(6,2) NOT NULL DEFAULT 0,".
      "`Dt` VARCHAR(2) NOT NULL DEFAULT '',".
      "`Hinweise` VARCHAR(256) NOT NULL DEFAULT '',".
      "`Stand` VARCHAR(60) NOT NULL DEFAULT '',".
      "`Tel1` VARCHAR(60) NOT NULL,".
      "`Tel2` VARCHAR(60) NOT NULL,".
      "fertig INT(1) NOT NULL DEFAULT 0,".
      "`DatAustrag` DATETIME NOT NULL DEFAULT 0,".
      "cdid int(10) UNSIGNED NOT NULL COMMENT 'Bezug zu `covdat`',".
      "PRIMARY KEY (`id`),".
      "KEY `PAT_ID` (`Pat_ID`),".
      "CONSTRAINT `FK_covid_covdat` FOREIGN KEY (`cdid`) REFERENCES `covdat` (`id`) ON UPDATE CASCADE ON DELETE CASCADE".
      ") ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8 COLLATE=utf8_german2_ci COMMENT='Covid-Impfliste';";
    //   $result=$conn->query($sql);
    $result=self::abfrage($conn,$sql);
    $verz="/DATA/Patientendokumente/Listen";
    if ($handle = opendir($verz)) {
      while (false !== ($entry = readdir($handle))) {
        if (stristr($entry,'Covid') && stristr($entry,".csv")) {
          $sql="SELECT COUNT(0) zl FROM covdat WHERE pfad='".$verz."/".$entry."'";
          $ergeb=self::abfrage($conn,$sql);
          $row = $ergeb->fetch_assoc();
          if ($row['zl']==0) {
            //          echo "$entry";
            $ft=filemtime($verz."/".$entry);
            //          echo " ".date("d.m.Y H:i:s",$ft)."<br>";
            $hd = fopen($verz."/".$entry, "r");
            if ($hd) {
              $jetzt = new DateTime(date());
              $sql="INSERT INTO covdat(pfad,dateintrag,aktzeit) VALUES('".$verz."/".$entry."','".date("YmdHis",$ft)."','".$jetzt->format('YmdHis')."')";
              $result=self::abfrage($conn,$sql);
              $cdid=$conn->insert_id;
              while (($line = fgets($hd)) !== false) {
                //              echo ">   :".$line."<br>";
                $line=str_replace("'","",str_replace("\\","",iconv("Windows-1252","UTF-8",$line)));
                $tl = preg_split("/;/",$line);
                if ($tl[0]!="inhalt" && trim($tl[0])!="") {
                  $pat=preg_split("/[, ]/",$tl[0]);
                  $pid=0;
                  $inh=$tl[0];
                  $palt=0;
                  $dt="";
                  if (is_numeric($pat[0])) {
                    $pid=$pat[0];
                    $sql="SELECT PatAltBr(".$pid.") pa, dmtyp(".$pid.") dt";
                    $ergeb=self::abfrage($conn,$sql);
                    $reihe = $ergeb->fetch_assoc();
                    $palt=$reihe['pa'];
                    $dt=$reihe['dt'];
                  }
                  $sql="INSERT INTO covid(Pat_id,Eintrag,Name,Tel1,Tel2,cdid,PAlter,Dt) VALUES ('".$pid."','".$tl[0]."','".$tl[1]."','".$tl[3]."','".$tl[4]."','".$cdid."',".$palt.",'".$dt."')";
                  $result=self::abfrage($conn,$sql);
//                  print_r($tl);
                }
                //              echo $tl[0]."<br>";
                // process the line read.
              }
              fclose($hd);
            } else {
              // error opening the file.
            }
          }
        }
      }
      closedir($handle);
      $sql="SELECT eintrag, pat_id, gesname(pat_id) Name, PAlter, Dt, Tel1, Tel2, SUBSTRING_INDEX(pfad, '/', -1) DName, dateintrag".
        " FROM covdat cd LEFT JOIN covid ci on ci.cdid=cd.id ORDER BY pat_id,eintrag,dateintrag;";
      $ergeb=self::abfrage($conn,$sql);
      if ($ergeb->num_rows >0) {
        echo "<table style='width: 100%'>";
        echo " <tr>";
        echo "  <th style='width:37%' title='Eintrag'>Eintrag</th>";
        echo "  <th title='Pat_ID'>Pat_ID</th>";
        echo "  <th title='Name'>Name</th>";
        echo "  <th title='PAlter'>PAlter</th>";
        echo "  <th title='DTyp'>DTyp</th>";
        echo "  <th style='width:20%' title='Tel1'>Tel1</th>";
        echo "  <th title='Tel2'>Tel2</th>";
        echo "  <th title='Dname'>Dname</th>";
        echo "  <th title='DatEintrag'>DatEintrag</th>";
        echo " </tr>";
        while($row = $ergeb->fetch_assoc()) {
          echo " <tr>";
          echo "  <td>".$row['eintrag']."</td>";
          echo "  <td>".$row['pat_id']."</td>";
          echo "  <td>".$row['Name']."</td>";
          echo "  <td>".$row['PAlter']."</td>";
          echo "  <td>".$row['Dt']."</td>";
          echo "  <td>".$row['Tel1']."</td>";
          echo "  <td>".$row['Tel2']."</td>";
          echo "  <td>".$row['Dname']."</td>";
          echo "  <td>".$row['dateintrag']."</td>";
          echo " </tr>";
        }
        echo "</table>";
      }
    } else {
      echo "$verz immer noch nicht gefunden";
    } // if ($handle = opendir($verz)) else
  } // if ($conn->connect_error) else
  $conn->close();
} // verarbeite()

function gibaus() 
{
    // Teil 2: Ausgabe
  if (!$_SESSION['ausblend']) {
      if (isset($_SESSION['arr'])) {
        echo "<form action='".self::$copyq."' method='POST'><ol style=\"margin-top:0em;margin-bottom:-1em;\">";
        foreach ($_SESSION['arr'] as $nr => $value) {
          if (!$_SESSION['gel'][$nr]) {
            if (!$_SESSION['erl'][$nr]) {
              if ($_SESSION['per'][$nr]=="a") $farbe="green";
              else if ($_SESSION['per'][$nr]=="v") $farbe="blue";
              else $farbe="crimson";
              $stil="border-style:groove;border-width:thin;border-color:white;".
                "color:".$farbe.";background-color:wheat;";
            } else {
              $stil="color:silver;background-color:white;";
            }
            // Aufgaben
            // die zwei Bereiche ineinander ermoeglichen sinnvollen Ueberlauf
            $komknopf="komknopf".$nr;
            if ($_SESSION['obk'][$nr] || $_SESSION['kom'][$nr]!='') {
              $breite=32; 
            } else {
              $breite=45;
            }
            echo "<li><div style=\"height:1.2rem;overflow:hidden;padding-top:1px;float:left;padding-right:0.1rem;\">".
              "<div style=\"".$stil."width:".$breite.
              "rem;white-space:nowrap;float:left;font-size:0.9rem;height:1.85rem;padding-right:1rem;overflow:auto;position:relative;\">".
              $value."</div>";
            if ($_SESSION['obk'][$nr]) {
              echo "<input style='width:13rem;' name='kommentar' value='".$_SESSION['kom'][$nr]."' autofocus/>";
              //         echo "<input style='width:13rem;' name='kommentar'  autofocus/>";
            } else if ($_SESSION['kom'][$nr]!="") {
              echo "<div style='color:orange;background-color:wheat;width:13rem;white-space:nowrap;float:left;font-size:0.9rem;".
                "height:1.75rem;paadding-right:1rem;overflow:auto;position:relative;'>".$_SESSION['kom'][$nr]."</div>";
            }
            echo "</div>";
            // erledigt/aktivier
            echo "<button type=\"submit\" style=\"width:2.9rem;font-size:0.7rem;height:1.3rem\" name=\"erlknopf".$nr."\">".
              ($_SESSION['erl'][$nr]?"aktivier":"erledigt")."</button>";
            // ändern
            echo "<button type=\"submit\" style=\"width:2.9rem;font-size:0.7rem;height:1.3rem\" name =\"aenknopf".$nr."\">ändern</button>";
            // aufwärtss
            echo "<button type=\"submit\" style=\"width:1rem;font-size:0.7rem;height:1.3rem\" name =\"aufknopf".$nr."\">&uarr;</button>";
            // abwärts
            echo "<button type=\"submit\" style=\"width:1rem;font-size:0.7rem;height:1.3rem\" name =\"abknopf".$nr."\">&darr;</button>";
            // löschen
            echo "<button type=\"submit\" style=\"width:3rem;font-size:0.7rem;height:1.3rem\" name =\"gelknopf".$nr."\">löschen</button>";
            // Kommentar
            echo "<button type=\"submit\" style=\"width:4rem;font-size:0.7rem;height:1.3rem\" name =\"komknopf".$nr."\">Kommentar</button>";
            // Autor
            echo "<span style='background-color:cornsilk;color:".($_SESSION['per'][$nr]=="V"||$_SESSION['per'][$nr]=="v"?"gray":"silver").
              ";float:left;width:15;'>".$_SESSION['aut'][$nr]."</span>";
            echo "</li>";
          }
        }
        echo "</ol></form>";
      }
    }

    echo "<a name='AnkerEing' href='#AnkerEing' accesskey='e'></a>";

    $stilaus="padding-left:0;border-style:groove;border-width:thin;border-color:blue;color:black;background-color:white;";
    $stilan="padding-left:0;border-style:groove;border-width:thin;border-color:blue;color:crimson;background-color:cornsilk;";
    $stilan="padding-left:0;border-style:groove;border-width:thin;border-color:blue;color:crimson;background-color:cornsilk;text-decoration:blink;";
    $eingbr=35; // Eingabefeldbreite
    // Zeile aufgabe
    // echo "<form id='aufgabenform' name='aufgabenform' action='".$copyq."' onfocus='this.selectionStart = this.selectionEnd = this.value.length;' method='POST'>";
    echo "<form id='aufgabenform' name='aufgabenform' action='".self::$copyq."' onfocus='ansEnde(this)' method='POST'>";
    $focus1="";$focus2="";$focus3="";
    //echo "<br>anwesend: ".$_SESSION['anwesend']."</br>";
    //echo "<br>obvorb: ".$_SESSION['obvorb']."</br>";
    //echo "<br>obbeha: ".$_SESSION['obbeha']."</br>";
    //echo "<br>anbeh: ".$_SESSION['anbeh']."</br>";
    if ($_SESSION['aufgaben']) $focus1="autofocus";
    else if (!$_SESSION['obvorb'] && !$_SESSION['obbeha'] && !$_SESSION['anbeh']) {
      $focus2="autofocus";
    } else if ($_SESSION['obvorb'] && !$_SESSION['obbeha'] && !$_SESSION['anbeh']) {
      if (!isset($_SESSION['ma']) || $_SESSION['ma']=='') $focus2="autofocus"; else $focus3="autofocus";
    } else $focus1="autofocus";
    if ($_SESSION['anwesend']) {
      // Return
      echo "<input type='submit' style=\"position:absolute;left:".($eingbr + 4.81)."rem;width:1.2rem;\" value='&crarr;' name='eintragen' />"; 
      $text="&#9993;Beh.";
      if ($_SESSION['anbeh']) {
        $stil=$stilan;
      } else {
        $stil=$stilaus;
      }
      // Anwesenheitsdatum, Knopf Brief an Beh.
      echo $_SESSION['anwseit']->format("H:i")." <button style=".$stil." name='anbeh' >".$text."</button>";

      if ($_SESSION['anbeh']) $li="li1"; else if ($_SESSION['obbeha'] || $_SESSION['obvorb']) $li="li2"; else $li="li0";
      // Aufgaben
      echo "<input type='text' name='aufgaben' list='$li' autocomplete='off' value='".$_SESSION['aufgaben']."' style='width:".$eingbr.
        "rem;border-right-width:1rem;height:22px;background-color: #FFCC99;' ".$focus1.">";
      echo "</input>";
    }

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
    /*     ?> <script>alert("rolle durch");</script> <?php  */
    // anwesend / ->von vorne
    echo "<button type='submit' style=".$stil." id='anwesend' name='anwesend' accesskey='$accessk'>".$text."</button>";

    if ($_SESSION['obvorb']) {
      $stil=$stilan;
      $text="&#10170;<u>V</u>orb.fertig";
    } else {
      $stil=$stilaus;
      $text="<u>V</u>orbereiter";
    }
    // if (isset($_POST['Mitarbeiter'])) echo "Mitarbeiter: ".$_POST['Mitarbeiter'];
    if (!isset($_SESSION['ma'])) $_SESSION['ma']='';
    if (!$_SESSION['obvorb']) {
      // Mitarbeiter (1): Vorbereiter
      echo "<u>M</u>A: <input type='text' name='ma' accesskey='m' style='width:30px;background-color:peachpuff;' ".
        "value='".$_SESSION['ma']."' ".$focus2."/> ";
    } else {
      echo "MA: <font color=blue>".$_SESSION['ma']."</font> ";
    }
    // Vorbereiter / Vorbereiter fertig
    echo "<button type='submit' style=".$stil." name='obvorb' accesskey='v'>".$text."</button>";

    if (!isset($_SESSION['bh'])) $_SESSION['bh']='';
    if (!$_SESSION['obbeha']) {
      // Behandler
      echo "Bh: <input type='text' name='bh' accesskey='m' style='width:30px;background-color:peachpuff;' value='".$_SESSION['bh']."' ".$focus3."/> ";
    } else {
      echo "Bh: <font color=blue>".$_SESSION['bh']."</font> ";
    }
    if ($_SESSION['obbeha']) {
      $stil=$stilan;
      $text="&#10170;Beh<u>.</u>fertig";
      $accessk=".";
      $weite=70;
    } else {
      $stil=$stilaus;
      $text="Beha<u>n</u>dler";
      $accessk="n";
      $weite=60;
    }
    // Behandler / Behandler fertig
    echo "<button type='submit' style='width:".$weite.";".$stil."' name='obbeha' accesskey='$accessk'>".$text."</button>";
    // if (isset($_SESSION['arr']))
    $welcheda=0;
    $nurwelcheweg=0;
    if (isset($_SESSION['arr'])) {
      foreach ($_SESSION['arr'] as $nr => $value) {
        if (!$_SESSION['gel'][$nr]) {
          $_SESSION['loeschen']=1;
          $welcheda=1;
          break;
        }
      }
      if (!$welcheda)
        foreach ($_SESSION['arr'] as $nr => $value) {
          if ($_SESSION['gel'][$nr]) {
            $_SESSION['loeschen']=0;
            $nurwelcheweg=1;
            break;
          }
        }
    }
    if ($welcheda)
      echo "<input type='submit' value=".($_SESSION['ausblend']?"einblenden":"ausblenden")." name='ausblend' ".
        "style='padding-left:0;padding-right:0;width:38px;'/>";
    if (!$_SESSION['ausblend'])
      if ($welcheda || $nurwelcheweg) {
        echo "<input type='submit' value=".($_SESSION['loeschen']?"alle&#160;loeschen":"wiederherstellen").
          " name='alleloeschen' style='padding-left:0;padding-right:0;width:".($_SESSION['loeschen']?40:60)."px;'/>";
      }
    if (1) {
      echo "<input type='submit' value='".($_SESSION['history']?"&empty; Hist":"Hist")."' name='history' ".
        "style='padding-left:0;padding-right:0;width:".($_SESSION['history']?45:30)."px;'/>";
      echo "<input type='submit' value='Aktu' name='aktual' ".
        "style='padding-left:0;padding-right:0;width:30px;'/>";
    }
    echo "<br>";
//    echo "</form>";
//    echo "<form id='knopfform' name='knopfform' method='POST'>";
//    echo "<span> SESSION['pat_id']: ".$_SESSION['pat_id'].", pat_id: ".$pat_id."</span><br>";
//  echo "3 session telnr ".$_SESSION['telnr']." telnr: ".$telnr."<br>"; // 1.11.20
    if ($_SESSION['obtelnr']) {
      if ($_SESSION['telnr']) {
        $stil=cave;
        $text=$_SESSION['tel']." überprüfen";
      } else {
        $stil=unauff;
        $text=$_SESSION['tel']." überprüft";
      }
      echo "<button class='".$stil."' name='telnr'>".$text."</button>";
    }
    if ($_SESSION['falarzt']) {
      echo "<button class='cave' name='farzt'>".$_SESSION['wiefalar']."</button>";
    }
    if (!$_SESSION['kdmp']) {
      if ($_SESSION['dmpa']&&$_SESSION['dmpk']<>'hier'&&!$_SESSION['dmpf']) {
        $stil=cave;
      } else {
        $stil=unauff;
      }
      $text="DMP: ".$_SESSION['dmpk']." ".$_SESSION['dmpp'];
      echo "<button class='".$stil."' name='dmpp' id='dmpp' type='button'>".$text."</button>";
//      echo "<button class='".$stil."' name='dmpp' onclick='dmpFrage()'>".$text."</button>";
//      echo "<section><button class='".$stil."' name='dmpp' data-js='confirm'>".$text."</button></section>";
    }
    include '../php/i1S.php';
    echo "</form>";
//    echo "<dialog id='my-dialog' role='dialog' aria-labelledby='my-dialog-heading'><button class='close'>Schließen</button><h2 id='my-dialog-heading'>Eingabe</h2><p class='button-row'><button name='ok' id='dmpok'>OK</button><button name='cancel'>Abbrechen</button></p></dialog>";
    echo "<dialog id='my-dialog' role='dialog' aria-labelledby='my-dialog-heading'><h2 id='my-dialog-heading'>Eingabe</h2><p class='button-row'><button name='ok' id='dmpok'>OK</button><button name='cancel'>Abbrechen</button></p></dialog>";
} // gibaus


function __construct() 
{
    global $pat_id; // globale Definition und Zuweisung außerhalb dieses scripts
    global $telnr;
    self::verarbeite($pat_id,$telnr);
//    self::gibaus();
  }
} // class zutun

$zutun = new zutun_cls();
?>

<!-- Auswahllisten fuer 'aufgaben' -->
<datalist id="li0">
<!-- DL1a Anmeldung an Vorbereiter-->
  <option value="HA nochmal anrufen wegen Vorbefuden">
  <option value="neues BZ-Meßgerät">
  <option value="neues Blutdruckmessgerät">
  <option value="DMP klären">
<!-- DL_e -->
</datalist>
<datalist id="li1">
<!-- DL2a Vorbereiter an Behandler -->
  <option value="Fußpulse überprüfen">
  <option value="Füße nochmal anschauen">
  <option value="Pat. vom DMP überzeugen">
  <option value="kleine Zehe anschauen">
<!-- DL_e -->
</datalist>
<datalist id="li2">
<!-- DL3a Vorbereiter/Behandler an Anmeldung -->
  <option value="Eingangsuntersuchung">
  <option value="Diabetesprofil">
  <option value="Metanephrine+IgF-BP3 i. S. ">
  <option value="Blutbild">
  <option value="K+">
  <option value="Aldost.-Renin-Quotient i. S. ">
  <option value="Gamma-GT und GPT">
  <option value="Dexa-Hemmtest">
  <option value="TSH basal">
  <option value="nt-proBNP">
  <option value="Vit B12">
  <option value="Holotranscobolamin">
  <option value="GAD-AK , IA2-AK">
  <option value="GAD-AK , IA2-AK, ZnT8-Ak">
  <option value="Insulin-AK">
  <option value="Transglutaminase-Ak und IgA">
  <option value="Pankreaselastase im Stuhl">
  <option value="25-OH Vit. D">
  <option value="Urin Status">
  <option value="Urinsediment">
  <option value="U-Bakt ">
  <option value="24h-Sammelurin auf:">
  <option value="Alb. und Creat. im Spontanurin">
  <option value="Proteinuriediagnostik">
  <option value="Parietalzell AK und AK intrinsic factor">
  <option value="25-OH Vit. D">
  <option value="Labor faxen an:">
  <option value="Blutdruck messen">
  <option value="Blutdruckvergleichsmessung">
  <option value="Langzeitblutdruckmessung">
  <option value="Blutzuckervergleichmessung">
  <option value="Blutzucker messen">
  <option value="BZ-Meßgerät auslesen">
  <option value="Neurostatus">
  <option value="Taille messen">
  <option value="Gewicht bestimmen">
  <option value="GPD ausstellen">
  <option value="Laborwerte, Befunde anfordern">
  <option value="Labor mitgeben">
  <option value="Medikamentenplan ausdrucken">
  <option value="Medikamentenplan unterschrieben">
  <option value="Überweisung bereits gespeichert">
  <option value="Überweisung Augenarzt">
  <option value="Überweisung Dermatologie">
  <option value="Überweisung Gynäkologie">
  <option value="Überweisung Hausarzt">
  <option value="Überweisung Hämatologie">
  <option value="Überweisung HNO">
  <option value="Überweisung Innere Medizin">
  <option value="Überweisung Kardiologie">
  <option value="Überweisung Neurologie">
  <option value="Überweisung Nephrologie">
  <option value="Überweisung Radiologie">
  <option value="Überweisung Urologie">
  <option value="Patienteninfo Straßenverkehr">
  <option value="Patienteninfo wie spritze ich Insulin">
  <option value="Patienteninfo Metformin und DPP4">
  <option value="Patienteninfo Hypoglykämie">
  <option value="Merkblatt Fußsyndrom">
  <option value="Flugbescheinigung">
  <option value="Verordnung häusl. Krankenpflg.">
  <option value="Rehasportverordnung">
  <option value="Einweisung in Karteikarte">
  <option value="Termin in  Tagen">
  <option value="Termin in  Wochen">
  <option value="Termin in 1 Woche">
  <option value="Termin in 2 Wochen">
  <option value="Termin in 4 Wochen">
  <option value="Termin in 6 Wochen">
  <option value="Termin in 3 Monaten">
  <option value="Termin in 3 Monaten mit Labor">
  <option value="Termin in 3 Monaten nach Labor">
  <option value="Termin in 3 Monaten nach Labor HA">
  <option value="Termin in 6 Monaten">
  <option value="Termin nach Antikoagulation">
  <option value="Termin für Carotisduplex">
  <option value="Termin für Nierenarterienduplex">
  <option value="Termin für Beinarterien- oder venenduplex">
  <option value="Duplex-Kontrolle in 6 Wochen">
  <option value="Duplex-Kontrolle in 6 Monaten">
  <option value="Termin für Sono Abdomen">
  <option value="Termin für IDA ">
  <option value="Termin bei Diabetesberaterin">
  <option value="Termin für Wundkontrolle">
  <option value="Termin für Kontrolle">
  <option value="Termin für Labor">
  <option value="Termin für Laborbesprechung">
  <option value="Doppeltermin">
  <option value="BZ-TB mitgeben">
  <option value="RR-TB mitgeben">
  <option value="RR-TB mitgeben Sturm">
  <option value="Ernähr'for.mitgeben">
  <option value="Typ1 Stammtischeinladung">
  <option value="Termin Nordic Walking Kurs ">
  <option value="U25 Stammtischeinladung">
  <option value="Seminar Basis">
  <option value="Seminar Experten">
  <option value="Seminar ICT">
  <option value="Seminar Typ 1">
  <option value="Seminar Bluthochdruck">
  <option value="DMP - Aktualisierung">
  <option value="DMP mit Hausarzt klären">
  <option value="Ins DMP einschreiben">
  <option value="DMP-Zettel mitgeben">
  <option value="Rezept für Teststreifen">
  <option value="Rezept für Pennadeln">
  <option value="Rezept für Lanzetten">
  <option value="Rezept für alles">
  <option value="Rezept für neues Blutzuckermessgerät">
  <option value="neues Blutzuckermessgerät">
  <option value="neues Blutdruckmessgerät">
  <option value="Podologierezept">
  <option value="Wundverband anlegen">
  <option value="Aufräumen/Aufkehren">
  <option value="Kompressionverband anlegen">
  <option value="Rezept Kompressionsbinden">
  <option value="Rezept Kompressionsstrumpf US Klasse 2 nach Maß mit offenen Zehen">
  <option value="Rezept Kompressionsstrumpf US Klasse 2 nach Maß mit geschlossen Zehen">
  <option value="Rezept Kompressionsstrumpf OS Klasse 2 nach Maß mit offenen Zehen">
  <option value="Rezept Kompressionsstrumpf OS Klasse 2 nach Maß mit geschlossen Zehen">
  <option value="Rezept Kompressionsstrumpfhose Klasse 2 nach Maß mit geschlossen Zehen">
  <option value="Rezept Kompressionsstrumpfhose Klasse 2 nach Maß mit offenen Zehen">
  <option value="Arixtra 2,5 mg spritzen zeigen">
  <option value="Arixtra 7,5 mg spritzen zeigen">
  <option value="innohep spritzen zeigen">
  <option value="Clivarodi spritzen zeigen">
  <option value="1 Tbl. Xarelto 15 mg geben">
  <option value="2 Tbl. Eliquis 5 mg geben">
  <option value="Xareltoausweis">
  <option value="Eliquisausweis">
  <option value="Lixianaausweis">
  <option value="Marcumarausweis">
  <option value="Ernährungsberatung für Nichtdiabetiker mit Rechnung">
  <option value="Ernährungsberatung Zöliakie">
  <option value="Unterlagen scannen">
  <option value="nix">
<!-- DL_e -->
</datalist>

<script>

function ansEnde(el) {
  window.setTimeout(function () {
      if (typeof el.selectionStart == "number") {
      el.selectionStart = el.selectionEnd = el.value.length;
      } else if (typeof el.createTextRange != "undefined") {
      var range = el.createTextRange();
      range.collapse(false);
      range.select();
      }
      }, 1);
}

'use strict';
function zaehlEigs(obj) {
    var count = 0;
    for(var prop in obj) {
        if(obj.hasOwnProperty(prop))
            ++count;
    }
    return count;
}
function GetComputerName() {
    try {
        var network = new ActiveXObject('WScript.Network');
        // Show a pop up if it works
        alert(network.computerName);
    }
    catch (e) { }
}
document.addEventListener("DOMContentLoaded", function () {
//	var button = document.querySelector("body button");
  var button = document.querySelector('[name="dmpp"]');
  // Polyfill für Browser, die das dialog-Element nicht komplett unterstützen
	(function () {
		var backdrop;
		Array.prototype.slice.call(document.querySelectorAll("dialog"))
			.forEach(function (dialog) {
				var callBacks = {
						cancel: function () {},
						ok: function () {}
					},
					close = dialog.querySelector(".close");
				if (!dialog.close) {
					dialog.close = function () {
						if (dialog.hasAttribute("open")) {
							dialog.removeAttribute("open");
						}
						if (backdrop && backdrop.parentNode) {
							backdrop.parentNode.removeChild(backdrop);
						}
					}
				}
				if (!dialog.show) {
					dialog.show = function () {
						var closeButton = dialog.querySelector(".close");
						dialog.setAttribute("open", "open");
						// after displaying the dialog, focus the closeButton inside it
						if (closeButton) {
							closeButton.focus();
						}
						if (!backdrop) {
							backdrop = document.createElement("div");
							backdrop.id = "backdrop";
						}
						document.body.appendChild(backdrop);
					}
				}
				dialog.setCallback = function (key, f) {
					callBacks[key] = f;
				};
				dialog.triggerCallback = function (key) {
					if (typeof callBacks[key] == "function") {
						callBacks[key]();
					}
				};
				if (close) {
					close.addEventListener("click", function () {
						dialog.close();
						dialog.triggerCallback("cancel");
					});
				}
				// handle buttons for user input
			["cancel", "ok"].forEach(function (n) {
					var button = dialog.querySelector('[name="' + n + '"]');
					if (button) {
						button.addEventListener("click", function () {
							dialog.close();
							dialog.triggerCallback(n);
						});
					}
				});
			});
		// ESC and ENTER closes open dialog and triggers corresponding callback
		document.addEventListener("keydown", function (event) {
			var currentElement = event.target || event.soureElement,
				prevent = (currentElement.tagName && currentElement.tagName.match(
					/^button|input|select|textarea$/i));
			Array.prototype.slice.call(document.querySelectorAll("dialog"))
				.forEach(function (dialog) {
					if (dialog.hasAttribute("open")) {
						// ENTER
						if (event.keyCode == 13 && !prevent) {
							dialog.close();
							setTimeout(function () {
								dialog.triggerCallback("ok");
							}, 50);
						}
						// ESC
						if (event.keyCode == 27) {
							dialog.close();
							setTimeout(function () {
								dialog.triggerCallback("cancel");
							}, 50);
						}
					}
				});
		}, true);
	}());
	// komplexere Dialog-Box anzeigen
	window.myDialog = function (data, OK, cancel) {
			var dialog = document.querySelector("#my-dialog"),
				buttonRow = document.querySelector("#my-dialog .button-row"),
				heading = document.querySelector("#my-dialog-heading"),
				element, p, prop;
			if (dialog && buttonRow) {
				// Standard-Titel
				if (heading) {
					heading.textContent = "Eingabe";
				}
				// jedes <ul> und <p> entfernen, außer <p class="button-row">
				Array.prototype.slice.call(dialog.querySelectorAll(
						"ul, p:not(.button-row)"))
					.forEach(function (p) {
						p.parentNode.removeChild(p);
					});
				// Elemente erstellen und gegebenenfalls mit Inhalten befüllen
				for (prop in data) {
					// alles bekommt ein <p> drumherum
					p = document.createElement("p");
					buttonRow.parentNode.insertBefore(p, buttonRow);
					// simple Textausgabe
					if (data[prop].type && data[prop].type == "info") {
						p.textContent = data[prop].text;
					}
					// anderer Titel
					if (data[prop].type && data[prop].type == "title" && heading) {
						heading.textContent = data[prop].text;
						// neues <p> wird hierfür nicht benötigt
						p.parentNode.removeChild(p);
					}
					// numerischer Wert
					if (data[prop].type && data[prop].type == "number") {
						// <label> als Kindelement für Beschriftung
						p.appendChild(document.createElement("label"));
						p.lastChild.appendChild(document.createTextNode(data[prop].text + " "));
						// <input type="number">
						element = p.appendChild(document.createElement("input"));
						if (data[prop].hasOwnProperty("max")) {
							element.max = data[prop]["max"];
						}
						if (data[prop].hasOwnProperty("min")) {
							element.min = data[prop]["min"];
						}
						if (data[prop].hasOwnProperty("step")) {
							element.step = data[prop]["step"];
						}
						element.name = prop;
						element.type = "number";
						element.value = element.min = data[prop]["min"] || 0;
						if (data[prop].default) {
							element.value = data[prop].default;
						}
					}
					// Mehrfachauswahl
          if (data[prop].type && data[prop].type == "multiple"
          ) {
						p.textContent = data[prop].text;
						// alle Optionen wandern in ein <ul>
						element = document.createElement("ul");
						buttonRow.parentNode.insertBefore(element, buttonRow);
						data[prop].options.forEach(function (d, index) {
							var input = document.createElement("input"),
								label = document.createElement("label"),
								li = document.createElement("li");
							// <li> in <ul> einhängen
							element.appendChild(li);
							input.id = prop + "-" + index;
							input.name = prop + "-" + index;
							input.type = "checkbox";
							input.value = d;
							li.appendChild(input);
							label.htmlFor = prop + "-" + index;
							label.textContent = " " + d
							li.appendChild(label);
							if (data[prop].default && data[prop].default == d) {
								input.setAttribute("checked", "checked");
							}
						});
					}
					// Radiobutton
					if (data[prop].type && data[prop].type == "radio") {
						p.textContent = data[prop].text;
            if (zaehlEigs(buttonRow.parentNode)<5) {
						data[prop].options.forEach(function (d, index) {
							var input = document.createElement("input"),
								label = document.createElement("label")
                ,nl=document.createElement("br")
                ;
							input.id = prop + "-" + index;
							input.name = prop;
							input.type = "radio";
							input.value = d;
              buttonRow.parentNode.insertBefore(input,buttonRow);
							label.htmlFor = prop + "-" + index;
							label.textContent = " " + d
							buttonRow.parentNode.insertBefore(label,buttonRow);
							if (data[prop].default && data[prop].default == d) {
								input.setAttribute("checked", "checked");
							}
              buttonRow.parentNode.insertBefore(nl,buttonRow);
						});
            }
					}
					// Einfachauswahl
					if (data[prop].type && data[prop].type == "select") {
						// <label> als Kindelement für Beschriftung
						p.appendChild(document.createElement("label"));
						p.lastChild.appendChild(document.createTextNode(data[prop].text + " "));
						// alle Optionen wandern in ein <ul>
						element = p.appendChild(document.createElement("select"));
						element.name = prop;
						data[prop].options.forEach(function (d) {
							var o = document.createElement("option");
							o.textContent = d;
							o.value = d;
							element.appendChild(o);
							if (data[prop].default && data[prop].default == d) {
								o.setAttribute("selected", "selected");
							}
						});
					}
					// Texteingabe
					if (data[prop].type && data[prop].type == "text") {
						// <label> als Kindelement für Beschriftung
						p.appendChild(document.createElement("label"));
						p.lastChild.appendChild(document.createTextNode(data[prop].text));
						// alle Optionen wandern in ein <ul>
						element = p.appendChild(document.createElement("textarea"));
						element.name = prop;
						if (data[prop].default) {
							element.textContent = data[prop].default;
						}
					}
				}
				dialog.setCallback("cancel", cancel);
				dialog.setCallback("ok", function () {
					var result = {},
						elements;
					// Ergebnisse ermitteln
					for (prop in data) {
						elements = Array.prototype.slice.call(dialog.querySelectorAll(
							'[name^="' + prop + '"]'));
            if (data[prop].type && (data[prop].type == "multiple" || data[prop].type == "radio")
            ) {
							result[prop] = [];
							elements.forEach(function (element) {
								if (element.checked) {
									result[prop].push(element.value);
								}
							});
						} else {
							if (data[prop].type != "title" && data[prop].type != "info") {
								result[prop] = null;
								if (elements[0]) {
									result[prop] = elements[0].value;
								}
							}
						}
					}
					// Ergebnisse an die Callback-Funktion zurück geben
					OK(result);
				});
        dialog.backgroundColor='green';
				dialog.show();
			}
		}
		// anzeigen-Button aktivieren
	if (button) {
		button.addEventListener("click", function () {
			myDialog(
				// data
				{
          auswahl: {
            "default": "hier",
            options: ["ungeklaert","nein","HA","hier","ausgeschrieben"],
            text: "DMP?",
            type: "radio"
    }
				},
				// OK
				function (data) {
					var output = document.querySelector("body pre"),
						prop,
						result = "Ergebnis:\r\n=========\r\n\r\n";
					for (prop in data) {
						result += prop + ":";
						if (typeof data[prop] == "object") {
							data[prop].forEach(function (value, index) {
                if (data[prop].type="radio") {
                  result = data[prop];
                } else {
                  result += (index ? "," : "") + "\r\n\t" + value;
                }
							});
						} else {
              result += " " + data[prop];
            }
            if (data[prop].type!="radio") {
              result += "\r\n";
            }
					}
          if (data[prop].type=="radio") {
          var d = new Date();
          var jetzt =d.getFullYear()+("0"+(d.getMonth()+1)).slice(-2)+("0"+d.getDate()).slice(-2)+("0"+d.getHours()).slice(-2)+("0"+d.getMinutes()).slice(-2)+("0"+d.getSeconds()).slice(-2);
			$.ajax({
				type: "POST",
        url: "../php/dmpspei.php",
				data: {
          pid: '<?php echo $_SESSION["pat_id"]; ?>',
          dmp: result[0],
          zp: jetzt,
            },
				cache: false,
				success: function(dataResult){
					var dataResult = JSON.parse(dataResult);
					if(dataResult.statusCode==200){
					}
					else if(dataResult.statusCode==201){
					   alert("Error occured !");
					}
				}
			});
          var el=document.getElementById("dmpp");
          var cl=el.classList;
          el.firstChild.data="DMP: "+result+" "+d.getDate()+"."+(d.getMonth()+1)+"."+d.getFullYear()+" "+d.getHours()+":"+d.getMinutes()+":"+d.getSeconds();
          if (cl.contains('cave')) {
            cl.remove('cave');
            cl.add('unauff');
          }
          }
            if (output) {
              output.textContent = result;
					}
				},
				// cancel
				function () {
					var output = document.querySelector("body pre");
					if (output) {
						output.textContent = "(kein Ergebnis)";
					}
				});
		});
	}
});
</script>
