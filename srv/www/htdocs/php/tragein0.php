<?php
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
