<?php
// tragein0.php - Debug-Hilfsseite: gibt bei einem POST-Aufruf $_POST,
// $GLOBALS, $_FILES, $_SESSION und $_ENV formatiert (htmlspecialchars-
// escaped) aus. Wird von KEINER anderen Datei in diesem Repository
// eingebunden - wirkt wie ein verwaister Debug-Helfer aus der Entwicklung
// der älteren "tragein*"-Formulargeneration (s. tragein.php). Aufruf: nur
// über einen POST-Request sinnvoll, sonst keine Ausgabe.
if ($_POST) {
  echo "Post:";
  echo '<pre>';
  echo htmlspecialchars(print_r($_POST, true));
  echo '</pre>';
  echo "Globals:";
  echo '<pre>';
  echo htmlspecialchars(print_r($GLOBALS, true));
  echo '</pre>';
  echo "Files:";
  echo '<pre>';
  echo htmlspecialchars(print_r($_FILES, true));
  echo '</pre>';
  echo "Session:";
  echo '<pre>';
  echo htmlspecialchars(print_r($_SESSION, true));
  echo '</pre>';
  echo "Env:";
  echo '<pre>';
  echo htmlspecialchars(print_r($_ENV, true));
  echo '</pre>';
}
// header ("Location:K.html");
?>
