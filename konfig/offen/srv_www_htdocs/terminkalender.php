<!-- terminkalender.php - PHP-Lernübung zu Arrays/foreach: baut eine feste
     Liste von Terminen (Datum/Ort/Band) und zerlegt sie in Parallel-Arrays
     $band/$ort/$datum; sollte danach Sortierlinks (nach Datum/Band/Ort)
     ausgeben. Kein Teil der eigentlichen Patientenlaufzettel-Anwendung
     (trotz ähnlichen Namens - die echte Terminverwaltung läuft über
     htdocs/php/anzeig.php & Co.).
     ACHTUNG: das rohe HTML "<p>sortieren nach ...</p>" weiter unten steht
     OHNE vorheriges "?>" noch innerhalb des offenen <?php-Blocks - das ist
     kein gültiges PHP und dürfte beim Aufruf mit einem Parse-Fehler
     ("syntax error, unexpected '<'") abbrechen, bevor überhaupt eine
     Ausgabe erfolgt (kein PHP-Interpreter zur Verfügung, um das hier
     nachzustellen, aber die Stelle ist eindeutig). -->
<?php
$termin[] = array('Datum' => 20121208,
    'Ort'   => "Wangen", 
    'Band'  => "cOoL RoCk oPaS");

$termin[] = array('Datum' => 20120311, 
    'Ort'   => "Stuttgart", 
    'Band'  => "Die Hosenbodenband");

$termin[] = array('Datum' => 20120628, 
    'Ort'   => "T?bingen", 
    'Band'  => "flying socks");

$termin[] = array('Datum' => 20120628, 
    'Ort'   => "Stuttgart", 
    'Band'  => "flying socks");

// echo "<pre>";
// print_r ($termin);


foreach ($termin as $nr => $inhalt)
{
  $band[$nr]  = $inhalt['Band'] ;
  $ort[$nr]   = $inhalt['Ort'] ;
  $datum[$nr] = $inhalt['Datum'] ;
}



<p>sortieren nach ...
<a href="terminkalender.php?sortierung=d">Datum</a>
<a href="terminkalender.php?sortierung=b">Band</a>
<a href="terminkalender.php?sortierung=o">Ort</a>
</p>



?>
