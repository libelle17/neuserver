<?php
// tragein1.php - generisches Debug-Template ("Superglobals"-Anzeige aller
// $_SERVER/$_ENV/$_REQUEST/$_GET/$_POST/$_COOKIE/$_FILES-Werte plus einer
// Beispiel-Variable $_CUSTOM mit Phantasiedaten "john"/"18068416846") -
// erkennbar eine unveränderte, aus einem allgemeinen PHP-Tutorial
// übernommene Vorlage, nicht praxisspezifisch angepasst. Wird von KEINER
// anderen Datei in diesem Repository eingebunden - verwaister Debug-Helfer
// wie tragein0.php. Aufruf: tragein1.php im Browser, keine Parameter
// nötig.
// Generate a formatted list with all globals
//----------------------------------------------------
// Custom global variable $_CUSTOM
$_CUSTOM = array('USERNAME' => 'john', 'USERID' => '18068416846');

// List here whichever globals you want to print
// This could be your own custom globals
$globals = array(
    '$_SERVER' => $_SERVER, '$_ENV' => $_ENV,
    '$_REQUEST' => $_REQUEST, '$_GET' => $_GET,
    '$_POST' => $_POST, '$_COOKIE' => $_COOKIE,
    '$_FILES' => $_FILES, '$_CUSTOM' => $_CUSTOM
    );
?>
<html>
<style>
<?php // Adjust CSS formatting for your output  ?>
.left {
  font-weight: 700;
}
.right {
  font-weight: 700;
color: #009;
}
.key {
color: #d00;
       font-style: italic;
}
</style>
<body>
<?php
// Generate the output
echo '<h1>Superglobals</h1>';
foreach ($globals as $globalkey => $global) {
  echo '<h3>' . $globalkey . '</h3>';
  foreach ($global as $key => $value) {
    echo '<span class="left">' . $globalkey . '[<span class="key">\'' . $key . '\'</span>]</span> = <span class="right">' . $value . '</span><br />';
  }
}
?>
</body>
</html>
