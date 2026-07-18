<!-- test.php - PHP-Lernübung: zeigt die GET-Parameter email/name an und
     bietet ein Formular für email/name/kommentar. Kein Teil der
     eigentlichen Patientenlaufzettel-Anwendung. Aufruf: test.php im
     Browser, optional mit ?email=...&name=....
     Hinweis: "$email"/"$name" im form-action-Attribut unten stehen
     außerhalb der <?php ?>-Tags und werden deshalb NICHT durch PHP ersetzt -
     sie erscheinen im HTML wörtlich als "$email"/"$name" statt der
     tatsächlichen Werte. -->
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
