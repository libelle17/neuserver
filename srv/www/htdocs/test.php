<h2>Herzlich Willkommen</h2>
<?php
echo "Ergebnisse: <b>".$_GET["email"].", Name: ".$_GET["name"]."</b><br>"
?>
<form action="?email=$email&name=$name" method="get">
E-Mail:<br>
<input type="Text" name="email"><br><br>
Name:<br>
<input type="Text" name="name"><br><br>

Kommentar:<br>
<textarea name="kommentar" cols="30" rows="5">
</textarea>

<input type="Submit" value="Absenden">
</form>
