<?php
if (!isset($_SESSION['anwesend'])) $_SESSION['anwesend']=0;
if (!isset($_SESSION['vorbereiter'])) $_SESSION['vorbereiter']=0;
if (!isset($_SESSION['behandler'])) $_SESSION['behandler']=0;
$stilaus="color:lightgray;background-color:white;";
$stilan="border-style:groove;border-width:thin;border-color:blue;color:crimson;background-color:cornsilk;";

echo "<form id='aufgabenform' name='aufgabenform' action='".$_SERVER['PHP_SELF']."' method='POST'>";
if (isset($_SESSION['anwesend']) && $_SESSION['anwesend']) {
  echo "<input type='text' id='aufgaben' name='aufgaben' list='zutunlst' autocomplete='off' size='90' style='height:22px;background-color: #FFCC99;'>";
}
?>
<datalist id="zutunlst">
<!-- DL1a -->
<option value="Composer">
<option value="Rezepte">
<option value="BZ-Vergleich">
<option value="wiegen">
<option value="Termin">
<!-- DL1e -->
</datalist>
</input>
<?php
if (!$_SESSION['anwesend']) {
  $stil=$stilaus;
} else {
  $stil=$stilan;
  echo "<input type='submit' value='&crarr;' name='eintragen' />";
}
// echo "Beginn/Ende:";
echo "<input type='submit' style='.$stil.' value=".(!$_SESSION['anwesend']?"Anwesend":'&#8594;alles&#160;fertig')." name='anwesend' />";
if (!$_SESSION['vorbereiter']) {
  $stil=$stilaus;
} else {
  $stil=$stilan;
}
echo "<input type='submit' style='.$stil.' value=".(!$_SESSION['vorbereiter']?"Vorbereiter":'&#8594;Vorb.fertig')." name='vorbereiter' />";
if (!$_SESSION['behandler']) {
  $stil=$stilaus;
} else {
  $stil=$stilan;
}
echo "<input type='submit' style='.$stil.' value=".(!$_SESSION['behandler']?"Behandler":'&#8594;Beh.fertig')." name='behandler' />";
?>

alle: 
<?php
echo "<input type='submit' value=".(!isset($_SESSION['blenden']) || $_SESSION['blenden']?"ausblenden":"einblenden")." name='blenden' />";
?>
<input type="submit" value="loeschen" name="alleloeschen" />
<input type="submit" value="wiederherstellen" name="wiederherstellen" />
</form>
