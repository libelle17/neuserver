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
    $sqlzutun="SELECT beschreib,kommentar kom, (erlZeit!=DATE(0)) erl,(gelZeit!=DATE(0)) gel,Person per,".
      "if(Person='a','__',if(Person='v',Vorbereiter,BehANDler)) aut ".
      "FROM zutun WHERE pat_id =".$pat_id." AND DATE(aktzeit)=DATE(now()) order by pos;";
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
    $sqlaktiv="SELECT AktZeit az FROM aktiv WHERE pat_id=".$pat_id." AND person in ('A','a') AND DATE(AktZeit)=DATE(now()) order by aktzeit desc;";
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
    $sqlaktiv="SELECT AktZeit az FROM aktiv WHERE pat_id=".$pat_id." AND person in ('V','v') AND DATE(AktZeit)=DATE(now()) order by aktzeit desc;";
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
    $sqlaktiv="SELECT AktZeit az FROM aktiv WHERE pat_id=".$pat_id." AND person in ('B','b') AND DATE(AktZeit)=DATE(now()) order by aktzeit desc;";
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
"if(Person='a','__', if(Person='v',Vorbereiter,Behandler)) aut, aktzeit az, pos ".
"FROM zutun WHERE pat_id =".$pat_id." order by aktzeit, pos;"; //AND DATE(AktZeit)<DATE(now()) 
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
        "values (".$pat_id.",".count($_SESSION['arr']).",'".$eintrag."',now(),'".$_SERVER['REMOTE_ADDR']
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
      echo "<pre>"; var_dump($mysqli->error); echo "</pre>";
      //    printf("Fehler bei: %s %s\n", $sql, $mysqli->error);
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
    $sql="CREATE TABLE if not exists `aktiv` (".
      "`id` int(10) unsigned NOT NULL AUTO_INCREMENT,".
      "`Pat_ID` int(10) unsigned NOT NULL,".
      "`Person` char(1) NOT NULL comment \"A=anwesend, a=anwesend an Behandler, V=Vorbereiter, v=Vorbereiter an Behandler, B=Behandler\",".
      "`Vorbereiter` char(5) NOT NULL comment \"Namenskuerzel Vorbereiter\",".
      "`Behandler` char(5) NOT NULL comment \"Namenskuerzel Behandler\",".
      "`ob` int(1) comment \"0=inaktiv, 1=aktiv\",".
      "`AktZeit` datetime NOT NULL,".
      "`AktPC` varchar(20) COLLATE latin1_german2_ci NOT NULL,".
      "PRIMARY KEY (`id`),".
      "KEY `PAT_ID` (`Pat_ID`,`AktZeit`)".
      ") ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 COLLATE=latin1_german2_ci COMMENT='Laufzettel Bearbeitungsdokumentation';";
    //   $result=$conn->query($sql);
    $result=self::abfrage($conn,$sql);
  }
  $zvorb="../vorb/".self::$basen;
  $zvorbakt="../vorb/  ".self::$basen;
  $zbehand="../behand/".self::$basen;
  $zbehandakt="../behand/  ".self::$basen;
  $zfertig="../fertig/".self::$basen;
//  echo "session pat_id ".$_SESSION['pat_id']." pat_id: ".$pat_id."<br>"; // 1.11.20
  if (!isset($_SESSION['pat_id'])) $init=1; else if ($_SESSION['pat_id']!=$pat_id) $init=1; else $init=0/*0*/;
  if ($init) {
    unset($_SESSION['telnr']);
 include '../php/i2S.php';
  }
  if (isset($_SESSION['aktual'])) $init=1;
  if ($init) {
    $_SESSION['pat_id']=$pat_id;
    self::getdb($conn,$pat_id);
//    echo "session pat_id ".$_SESSION['pat_id']." pat_id: ".$pat_id."<br>"; // 1.11.20
//    $_SESSION['history']=0;
//    echo "<span> hier telnr: ".$telnr."</span><br>"; // 1.11.20
    if (!isset($_SESSION['telnr'])) $_SESSION['telnr']=$telnr;
    $_SESSION['aktual']=0;
  }
//  echo "session telnr ".$_SESSION['telnr']." telnr: ".$telnr."<br>"; // 1.11.20
  if ($_SESSION['telnr'] && !isset($_POST['telnr'])) {
    $sql="SELECT SUBDATE(NOW(),92)>tgeprueft zp FROM namen WHERE pat_id=".$pat_id;
    //$ergeb=$conn->query($sqlzutun);
    $ergeb=self::abfrage($conn,$sql);
    // echo "<pre>";var_dump($conn);echo "</pre>";
    // echo "<pre>Ergeb: "; var_dump($ergeb); echo "</pre>";
    if ($ergeb->num_rows >0) {
      $row = $ergeb->fetch_assoc();
      if (!$row['zp']) {
//        echo "aendere!<br>"; // 1.11.20
        $_SESSION['telnr']=0;
      }
    }
  }
//  echo "2 session telnr ".$_SESSION['telnr']." telnr: ".$telnr."<br>"; // 1.11.20

  $_SESSION['pat_id']=$pat_id;
  $_SESSION['person']=$_SESSION['obvorb']?($_SESSION['anbeh']?"v":"V"):($_SESSION['obbeha']?"B":($_SESSION['anbeh']?"a":"A"));


  if(isset($_POST['ma']))  $_SESSION['ma']=$_POST['ma']; else if (!isset($_SESSION['ma'])) $_SESSION['ma']="";
  if(isset($_POST['bh']))  $_SESSION['bh']=$_POST['bh']; else if (!isset($_SESSION['bh'])) $_SESSION['bh']="";
  if (!file_exists(self::$copyq)) {
    copy("..".$_SERVER['PHP_SELF'],self::$copyq);
  }
  // pruefen, ob ein Kommentarfeld eroeffnet war, dann auf Return gedrueckt wurde ($_POST['erknopf0']) ...
  $komaktiv=-1;
  if (isset($_SESSION['arr']))
    for($i=0;$i<count($_SESSION['arr']);$i++) {
      if ($_SESSION['obk'][$i]) {$komaktiv=$i;break;}
    }
  // echo "kommaktiv: ".$komaktiv."<br>";
  // echo "<pre>"; var_dump($_POST); echo "</pre>";
/*        ?> <script>alert("in verarbeite()");</script> <?php
  ?> <script>var hist=<?php echo json_encode($_SESSION['history'], JSON_HEX_TAG); ?>;alert("stelle history auf "+hist);</script> <?php
 */
  if ($komaktiv>-1 && isset($_POST['erlknopf0']) && isset($_POST['kommentar'])) {
    $sql="UPDATE zutun SET kommentar='".$_POST['kommentar'].
      "' WHERE pat_id = ".$pat_id." AND DATE(aktzeit)=DATE(now()) AND pos=".($komaktiv+1).";";
    echo $sql."<br>";
    $_SESSION['kom'][$komaktiv]=$_POST['kommentar'];
    $_SESSION['obk'][$komaktiv]=0;
    // $ergeb=$conn->query($sql);
    $ergeb=self::abfrage($conn,$sql);
    //    echo "Kommentar einzutragen: ".$_POST['kommentar']." auf Position: ".$komaktiv."<br>";
  } else {
    if (isset($_SESSION['arr'])) {
      $obkomkn=0;
      for($i=0;$i<count($_SESSION['obk']);$i++) {
        $kk="komknopf".$i;
        if (isset($_POST[$kk])) {$obkomkn=1;break;}
      }
      // falls was anderes gedrueckt wurde als Kommentar, dann Kommentarfeld nicht mehr anzeigen
      if (!$obkomkn) {
        for($i=0;$i<count($_SESSION['obk']);$i++) {
          $_SESSION['obk'][$i]=0;
        }
      }
    }
    // den eingegebenen Text zur Zutunliste hinzufuegen
        include '../php/i0S.php';
    if(isset($_POST['eintragen'])) {
      if(isset($_POST['aufgaben'])) if ($_POST['aufgaben']) {
        self::tragein($conn, $pat_id, $_POST['aufgaben']);
      }
      $_SESSION['anbeh']=0;
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
          if (!file_exists($zvorb)) copy(self::$copyq,$zvorb);
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
          $_SESSION['obbeha']=0;
        } else {
          $_SESSION['obvorb']=!$_SESSION['obvorb'];
//          $_SESSION['anbeh']=0;
          $_SESSION['obbeha']=0;
          if (!$_SESSION['anwesend']) {
            $_SESSION['anwesend']=1;
            $myaktiv=1;
          }
          if (file_exists($zvorb)) rename($zvorb,$zvorbakt);
          if ($_SESSION['obvorb']==1) {
            if (file_exists($zbehand)) unlink($zbehand);
            if (file_exists($zfertig)) unlink($zfertig);
            if (!file_exists($zvorbakt)) copy(self::$copyq,$zvorbakt);
          } else {
            if (file_exists($zvorb)) rename($zvorb,$zvorbakt);
            if (file_exists($zvorbakt)) rename($zvorbakt,$zbehand);
            else copy(self::$copyq,$zbehand);
            echo "<meta http-equiv='refresh' content='0; URL=http://linux1/vorb/'>";
          }
          $myvorb=1;
        }
      } else if(isset($_POST['obbeha'])) {
        if ($_SESSION['bh']=='') {
          echo "<script>alert('Wer sind Sie (bitte Kuerzel eingeben)?');</script>";
          $_SESSION['obvorb']=0;
        } else {
          $_SESSION['obbeha']=!$_SESSION['obbeha'];
//          $_SESSION['anbeh']=0;
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
            if (!file_exists($zbehandakt)) copy(self::$copyq,$zbehandakt);
          } else {
            if (file_exists($zvorb)) unlink($zvorb);
            if (file_exists($zvorbakt)) unlink($zvorbakt);
            if (file_exists($zbehandakt)) rename($zbehandakt,$zfertig);
            else copy(self::$copyq,$zfertig);
            echo "<meta http-equiv='refresh' content='0; URL=http://linux1/behand/'>";
          }
          $mybeh=1;
        }
      } else if(isset($_POST['anbeh'])) {
        $_SESSION['anbeh']=!$_SESSION['anbeh'];
        if ($_SESSION['obbeha']==1) {
          $_SESSION['obbeha']=0;
          $mybeh=1;
        }
      } else if(isset($_POST['telnr'])) {
//        echo "stelle um<br>"; // 1.11.20
        $_SESSION['telnr']=!$_SESSION['telnr'];
        $telnr=$_SESSION['telnr'];
        $_SESSION['tgeprueft']=date("YmdHis");
        $sql="UPDATE namen SET tgeprueft='".$_SESSION['tgeprueft']."' WHERE pat_id=".$_SESSION['pat_id'];
//        echo "<span>sql: ".$sql."</span><br>"; // 1.11.20
        $ergeb=self::abfrage($conn,$sql);
//        $_SESSION['aufrufe']=$_SESSION['aufrufe']+1;
      } else if(isset($_POST['history'])) {
        $_SESSION['history']=!$_SESSION['history'];
        /*
        ?> <script>
          var ghist=<?php echo json_encode($_SESSION['ghist'], JSON_HEX_TAG); ?>;
          var hist=<?php echo json_encode($_SESSION['history'], JSON_HEX_TAG); ?>;
        alert("vor history: "+hist+" ghist: "+ghist);
        </script> <?php
        if ($_SESSION['history']==0) $_SESSION['history']=1; else $_SESSION['history']=0;
        if ($_SESSION['ghist']==0) $_SESSION['ghist']=1; else $_SESSION['ghist']=0;
        ?> <script>
          var ghist=<?php echo json_encode($_SESSION['ghist'], JSON_HEX_TAG); ?>;
          var hist=<?php echo json_encode($_SESSION['history'], JSON_HEX_TAG); ?>;
        alert("nach history: "+hist+" ghist: "+ghist);
        </script> <?php
         */
      } else if(isset($_POST['alleloeschen'])) {
        $_SESSION['loeschen']=!$_SESSION['loeschen'];
        if ($_SESSION['loeschen']) {
          $sql="UPDATE zutun SET gelZeit=DATE(0),gelpc='' ".
            "WHERE pat_id = ".$pat_id." AND DATE(aktzeit)=DATE(now());";
          for ($i=0;$i<count($_SESSION['arr']);$i++) {
            $_SESSION['gel'][$i]=0;
          }
          $_SESSION['ausblend']=0;
        } else {
          $sql="UPDATE zutun SET gelZeit=now(),gelpc='".$_SERVER['REMOTE_ADDR'].
            "' WHERE pat_id = ".$pat_id." AND DATE(aktzeit)=DATE(now());";
          for ($i=0;$i<count($_SESSION['arr']);$i++) {
            $_SESSION['gel'][$i]=1;
          }
        }
    //    $ergeb=$conn->query($sql);
        $ergeb=self::abfrage($conn,$sql);
      } else if(isset($_POST['ausblend'])) {
        $_SESSION['ausblend']=!$_SESSION['ausblend'];
      //  if ($_SESSION['ausblend']) unset($_SESSION['aufgaben']);
      } else {
        if (isset($_SESSION['arr'])) {
          for ($i=0;$i<count($_SESSION['arr']);$i++) {
            $erlknopf="erlknopf".$i;
            if (isset($_POST[$erlknopf])) {
              $_SESSION['erl'][$i]=!$_SESSION['erl'][$i];
              $sql="UPDATE zutun SET erlZeit=if(erlZeit=DATE(0),now(),DATE(0)),erlPC='".$_SERVER['REMOTE_ADDR'].
                "' WHERE pat_id = ".$pat_id." AND DATE(aktzeit)=DATE(now()) AND pos=".($i+1).";";
              //    echo $sql."<br>";
              //          $ergeb=$conn->query($sql);
              $ergeb=self::abfrage($conn,$sql);
              $allefertig=1;
              for($j=0;$j<count($_SESSION['erl']);$j++) {
                if (!$_SESSION['erl'][$j] && !$_SESSION['gel'][$j]) {
                  $allefertig=0;
                  break;
                }
              }
              if ($allefertig) {
                if (file_exists($zfertig)) unlink($zfertig);
                $_SESSION['anwesend']=0;
                echo "<meta http-equiv='refresh' content='0; URL=http://linux1/fertig/'>";
                exit;
              } else {
                if (!$_SESSION['obvorb']) if (!$_SESSION['obbeha'])
                  if (!file_exists($zfertig)) copy(self::$copyq,$zfertig);
              }
              break;
            }
            $gelknopf="gelknopf".$i;
            if (isset($_POST[$gelknopf])) {
              $_SESSION['gel'][$i]=!$_SESSION['gel'][$i];
              $sql="UPDATE zutun SET gelZeit=if(gelZeit=DATE(0),now(),DATE(0)),gelPC='".$_SERVER['REMOTE_ADDR'].
                "' WHERE pat_id = ".$pat_id." AND DATE(aktzeit)=DATE(now()) AND pos=".($i+1).";";
              //    echo $sql."<br>";
              //          $ergeb=$conn->query($sql);
              $ergeb=self::abfrage($conn,$sql);
              break;
            }
            $komknopf="komknopf".$i;
            if (isset($_POST[$komknopf])) {
              //        echo "i: ".$i." session obk ".$_SESSION['obk'][$i]."<br>";
              $_SESSION['obk'][$i]=!$_SESSION['obk'][$i];
            } else {
              $_SESSION['obk'][$i]=0;
            }
            $aufknopf="aufknopf".$i;
            if ($i) if (isset($_POST[$aufknopf])) {
              self::dotausch($conn, $pat_id, $i);
              break;
            }
            $aenknopf="aenknopf".$i;
            if (isset($_POST[$aenknopf])) {
              $_SESSION['gel'][$i]=1;
              $sql="UPDATE zutun SET gelZeit=if(gelZeit=DATE(0),now(),DATE(0)),gelPC='".$_SERVER['REMOTE_ADDR'].
                "' WHERE pat_id = ".$pat_id." AND DATE(aktzeit)=DATE(now()) AND pos=".($i+1).";";
              //    echo $sql."<br>";
              //          $ergeb=$conn->query($sql);
              $ergeb=self::abfrage($conn,$sql);
              $_SESSION['aufgaben']=$_SESSION['arr'][$i];
              break;
            }
            $abknopf="abknopf".$i;
            if ($i<count($_SESSION['arr'])-1) if (isset($_POST[$abknopf])) {
              self::dotausch($conn, $pat_id, $i+1);
              break;
            }
          }
        }
      }
      // in Datenbank eintragen, wann anwesend gedrueckt wurde
      if ($myaktiv) {
        $_SESSION['anwseit']=new DateTime(date("Y-m-d H:i:s"));
        $sql="INSERT INTO aktiv(pat_id,Person,Vorbereiter,Behandler,ob,AktZeit,AktPC) ".
          "values(".$pat_id.",'".($_SESSION['anbeh']?"a":"A")."','".$_SESSION['ma']."','".
          $_SESSION['bh']."','".($_SESSION['anwesend']?"1":"0")."',now(),'".$_SERVER['REMOTE_ADDR']."');";
        //    $ergeb=$conn->query($sql);
        $ergeb=self::abfrage($conn,$sql);
      }
      // in Datenbank eintragen, wann Vorbereitung gedrueckt wurde
      if ($myvorb) {
        $sql="INSERT INTO aktiv(pat_id,Person,Vorbereiter,Behandler,ob,AktZeit,AktPC) ".
          "values(".$pat_id.",'".($_SESSION['anbeh']?"v":"V")."','".$_SESSION['ma']."','".
          $_SESSION['bh']."','".($_SESSION['obvorb']?"1":"0")."',now(),'".$_SERVER['REMOTE_ADDR']."');";
        //     $ergeb=$conn->query($sql);
        $ergeb=self::abfrage($conn,$sql);
      }
      // in Datenbank eintragen, wann Behandlung gedrueckt wurde
      if ($mybeh) {
        $sql="INSERT INTO aktiv(pat_id,Person,Vorbereiter,Behandler,ob,AktZeit,AktPC) ".
          "values(".$pat_id.",'B','".$_SESSION['ma']."','".$_SESSION['bh']."','".($_SESSION['obbeha']?"1":"0").
          "',now(),'".$_SERVER['REMOTE_ADDR']."');";
        //    $ergeb=$conn->query($sql);
        $ergeb=self::abfrage($conn,$sql);
      }
    }
  }
  if ($_SESSION['history'])
    self::zeiggeschichte($conn,$pat_id);
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
 include '../php/i1S.php';
      echo "</form>";
} // gibaus


function __construct() 
{
    global $pat_id; // globale Definition und Zuweisung außerhalb dieses scripts
    global $telnr;
    self::verarbeite($pat_id,$telnr);
    self::gibaus();
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
</script>
