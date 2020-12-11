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
