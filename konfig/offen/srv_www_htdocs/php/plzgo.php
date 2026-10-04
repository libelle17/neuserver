<?php
// Aufloeser fuer Links auf den Patientenlaufzettel eines anderen Patienten.
// Aufruf: ../php/plzgo.php?pid=<Pat_id> aus dem Knopf "Bezuege" im Patientenlaufzettel
// (Laufzettelneu.bas, Sub BezuegeTeile).
//
// Sucht im Laufzettel-Verzeichnis nach beiden Namenssyntaxen aus dodoplz
// (s. dort "DateiNameRoh ="):
//   php-Variante:   <Nachname>_<Vorname>,Pid_<id>[,<Arzt>][_...].html
//   Datei-Variante: <Nachname> <Vorname>,   Pid <id>[, <Arzt>], Patientenlaufzettel[_...].html
// und leitet auf die juengste Fundstelle weiter. Das Komma bzw. der Unterstrich direkt
// hinter der Nummer verhindert Treffer auf laengere Pat_ids (705 vs. 70506).
//
// Die Aufloesung geschieht erst beim Klick; der Link funktioniert deshalb auch dann,
// wenn der Laufzettel des anderen Patienten erst spaeter erstellt wird. Existiert er noch
// nicht, bietet die 404-Seite einen "oeffneplz:"-Knopf zur Erstellung an (Mechanismus wie
// "oeffneverz:"/"oeffnedual:", registriert in Laufzettelneu.bas/RegistriereOeffnePlz).

$plzdir = dirname(__DIR__) . '/plz';
$pid = isset($_GET['pid']) ? $_GET['pid'] : '';

if (!ctype_digit($pid) || strlen($pid) > 12 || $pid[0] === '0') {
    header('Content-Type: text/plain; charset=utf-8', true, 400);
    echo "Aufruf: plzgo.php?pid=<Pat_id>";
    exit;
}

$muster = array(
    '*,Pid_' . $pid . '.html',                      // php-Variante, ohne Arzt
    '*,Pid_' . $pid . ',*.html',                    // php-Variante, mit Arzt
    '*,Pid_' . $pid . '_*.html',                    // php-Variante, ohne Arzt, mit Kollisions-"_"
    '*Pid ' . $pid . ',*Patientenlaufzettel*.html', // Datei-Variante (mit und ohne Arzt)
);

$best = '';
$bestzp = -1;
foreach ($muster as $m) {
    $treffer = glob($plzdir . '/' . $m, GLOB_NOESCAPE);
    if ($treffer === false) {
        continue;
    }
    foreach ($treffer as $f) {
        $zp = @filemtime($f);   // dodoplz setzt die Schreibzeit auf Termindatum + -uhrzeit
        if ($zp !== false && $zp > $bestzp) {
            $bestzp = $zp;
            $best = basename($f);
        }
    }
}

if ($best !== '') {
    header('Location: ../plz/' . rawurlencode($best));
    exit;
}

$zurueck = isset($_SERVER['REQUEST_URI']) ? $_SERVER['REQUEST_URI'] : '';
header('Content-Type: text/html; charset=utf-8', true, 404);
echo '<!DOCTYPE html><html lang="de"><head><meta charset="utf-8">',
     '<title>Kein Patientenlaufzettel</title></head><body>',
     '<p>Zu Pat_id ', htmlspecialchars($pid), ' liegt in <code>', htmlspecialchars($plzdir),
     '</code> noch kein Patientenlaufzettel.</p>',
     '<p><a href="oeffneplz:', htmlspecialchars($pid), '">Patientenlaufzettel jetzt erstellen</a>',
     ' (&ouml;ffnet DateiLese.exe auf diesem Rechner; danach hier erneut versuchen)</p>',
     '<p><a href="', htmlspecialchars($zurueck), '">Erneut versuchen</a>',
     ' &nbsp; <a href="javascript:history.back()">Zur&uuml;ck</a></p>',
     '</body></html>';
