<?php
// emailspei.php - manuelle Pflege von quelle.pat_email_adr aus dem Patientenlaufzettel
// heraus (PHP-Variante). Ergaenzt/aendert/loescht eine Email-Adresse eines Patienten, erlaubt
// die Rangvergabe (welche Adresse nach patstamm.FEmail soll) und haengt dazu immer genau eine
// Zeile an pat_email_adr_audit an. Schreibt NIE direkt nach patstamm - das bleibt Sache des
// (Windows- bzw. kuenftig gemeinsamen) Commit-Schritts. committed/marker werden hier aber
// gezielt zurueckgesetzt (auf 0/NULL), wenn eine Zeile neu als rolle='h' vorgesehen wird, damit
// der naechste Commit-Lauf sie garantiert erneut verarbeitet - siehe Abstimmung mit der
// Windows-Instanz vom 2026-09-12 zu den Rueckgaengig-Faellen.
// Verbindungs-/Session-Muster wie tragein2.php.
//
// Rueckgaengig-Funktion: $_SESSION['eundo_stack'] ist ein Stapel (Array) der in DIESER
// Sitzung fuer den AKTUELLEN Patienten ausgefuehrten Aktionen (jederlei Art, in der
// Reihenfolge ihrer Ausfuehrung). Jeder Klick auf "Rueckgaengig" macht genau die zuletzt
// noch nicht rueckgaengig gemachte Aktion rueckgaengig (LIFO) und entfernt sie vom Stapel -
// ein zweiter Klick macht dann die davor ausgefuehrte Aktion rueckgaengig, usw. Wechselt der
// Patient, wird der Stapel geleert (kein Rueckgaengig ueber Patientengrenzen hinweg).
session_start();

$pc = "localhost";
include '../../phppwd.php';
$db = "quelle";
$conn = new mysqli($pc, $user, $pwt, $db);
if ($conn->connect_error) {
  echo "Datenbankverbindung zu '".$pc."' fehlgeschlagen: ".$conn->connect_error;
  exit;
}
$conn->set_charset("utf8mb4");

function eSql($conn, $s) {
  if ($s === '' || $s === null) return 'NULL';
  return "'".$conn->real_escape_string($s)."'";
}

function schreibeAudit($conn, $aktionTxt, $pat_id, $alt_email, $neu_email, $bezug, $aktpc, $person, $vorbereiter, $behandler, $bemerkung = null) {
  $sql = "INSERT INTO pat_email_adr_audit (aktion,pat_id,alt_email,neu_email,bezug,AktPC,Person,Vorbereiter,Behandler,bemerkung) VALUES (".
    eSql($conn, $aktionTxt).",".eSql($conn, $pat_id).",".eSql($conn, $alt_email).",".eSql($conn, $neu_email).",".
    eSql($conn, $bezug).",".eSql($conn, $aktpc).",".eSql($conn, $person).",".eSql($conn, $vorbereiter).",".eSql($conn, $behandler).",".
    eSql($conn, $bemerkung).")";
  $conn->query($sql);
}

function gibtsSchonAnders($conn, $email, $pat_id) {
  $r = $conn->query("SELECT pat_id FROM pat_email_adr WHERE email=".eSql($conn, $email)." AND pat_id<>".eSql($conn, $pat_id)." LIMIT 1");
  return $r && $r->num_rows > 0;
}

// aktuelle Zeile (rolle+bezug) vor einer Aendern/Loeschen-Aktion lesen, fuer den Undo-Stapel
function leseZeile($conn, $pat_id, $email) {
  $r = $conn->query("SELECT rolle,bezug FROM pat_email_adr WHERE pat_id=".eSql($conn, $pat_id)." AND email=".eSql($conn, $email)." LIMIT 1");
  if ($r && $r->num_rows > 0) return $r->fetch_assoc();
  return null;
}

function einfuegenZeile($conn, $pat_id, $email, $rolle, $bezug, $aktpc, $person, $vorbereiter, $behandler) {
  $sql = "INSERT INTO pat_email_adr (pat_id,email,rolle,quelle,bezug,AktPC,Person,Vorbereiter,Behandler,erfasst_am,committed) VALUES (".
    eSql($conn, $pat_id).",".eSql($conn, $email).",".eSql($conn, $rolle).",'m',".eSql($conn, $bezug).",".
    eSql($conn, $aktpc).",".eSql($conn, $person).",".eSql($conn, $vorbereiter).",".eSql($conn, $behandler).",NOW(),0)";
  return $conn->query($sql);
}

function zurueck($ref) {
  if ($ref === '' || $ref === null) $ref = '../plz/';
  // #emailoffen: das Email-Adr.-Editierfenster soll nach einer Aktion offen bleiben statt
  // sich beim Neuladen der Laufzettelseite wieder zu schliessen (siehe emailAdrToggle()/
  // Auto-Aufklapp-Skript in Laufzettelneu.bas:EmailAdressenPHP).
  $ref = preg_replace('/#.*$/', '', $ref)."#emailoffen";
  header("Location: ".$ref);
  exit;
}

$aktion    = isset($_POST['aktion'])    ? $_POST['aktion']            : '';
$email     = isset($_POST['email'])     ? trim($_POST['email'])       : '';
$bezug     = isset($_POST['bezug'])      ? trim($_POST['bezug'])       : '';
$alt_email = isset($_POST['alt_email']) ? trim($_POST['alt_email'])   : '';
$alt_rolle = isset($_POST['alt_rolle']) ? $_POST['alt_rolle']         : '';
$ref       = isset($_POST['ref'])       ? $_POST['ref']               :
             (isset($_SERVER['HTTP_REFERER']) ? $_SERVER['HTTP_REFERER'] : '');

// pat_id bewusst aus der Session, nicht aus dem POST-Feld - der Laufzettel setzt
// $_SESSION['pat_id'] ohnehin schon fuer die zutun-Verwaltung.
$pat_id = isset($_SESSION['pat_id']) ? intval($_SESSION['pat_id']) : 0;

$vorbereiter = isset($_SESSION['ma'])     ? $_SESSION['ma']     : '';
$behandler   = isset($_SESSION['bh'])     ? $_SESSION['bh']     : '';
$person      = isset($_SESSION['person']) ? $_SESSION['person'] : '';
$aktpc       = $_SERVER['REMOTE_ADDR'];

if ($pat_id == 0) {
  echo "Kein Patient in der Sitzung gefunden - bitte den Laufzettel neu aufrufen.";
  exit;
}

// Undo-Stapel: patientenbezogen, wird bei Patientenwechsel geleert.
if (!isset($_SESSION['eundo_pat']) || $_SESSION['eundo_pat'] != $pat_id) {
  $_SESSION['eundo_pat'] = $pat_id;
  $_SESSION['eundo_stack'] = array();
}
if (!isset($_SESSION['eundo_stack'])) $_SESSION['eundo_stack'] = array();

$bestaetigt = false;
if ($aktion === 'bestaetigt_hinzufuegen') { $aktion = 'hinzufuegen'; $bestaetigt = true; }
if ($aktion === 'bestaetigt_aendern')     { $aktion = 'aendern';     $bestaetigt = true; }

if (($aktion === 'hinzufuegen' || $aktion === 'aendern') && $email !== '' && !$bestaetigt && gibtsSchonAnders($conn, $email, $pat_id)) {
  // Warnhinweis mit Rueckfrage statt sofort zu schreiben (Geschaeftsregel 6 der Spezifikation)
  $wiederholAktion = ($aktion === 'hinzufuegen') ? 'bestaetigt_hinzufuegen' : 'bestaetigt_aendern';
  echo "<!DOCTYPE html><html><head><meta charset='utf-8'><title>E-Mail-Adresse pruefen</title></head><body>";
  echo "<p style='color:red'>Die Adresse ".htmlspecialchars($email)." ist bereits bei einem anderen Patienten hinterlegt.</p>";
  echo "<form method='post' action='emailspei.php'>";
  echo "<input type='hidden' name='aktion' value='".htmlspecialchars($wiederholAktion)."'>";
  echo "<input type='hidden' name='email' value='".htmlspecialchars($email)."'>";
  echo "<input type='hidden' name='bezug' value='".htmlspecialchars($bezug)."'>";
  echo "<input type='hidden' name='alt_email' value='".htmlspecialchars($alt_email)."'>";
  echo "<input type='hidden' name='alt_rolle' value='".htmlspecialchars($alt_rolle)."'>";
  echo "<input type='hidden' name='ref' value='".htmlspecialchars($ref)."'>";
  echo "<button type='submit'>Trotzdem speichern</button> ";
  echo "<button type='button' onclick=\"location.href='".htmlspecialchars($ref)."'\">Abbrechen</button>";
  echo "</form></body></html>";
  exit;
}

if ($aktion === 'hinzufuegen' && $email !== '') {
  if (einfuegenZeile($conn, $pat_id, $email, 'n', $bezug, $aktpc, $person, $vorbereiter, $behandler)) {
    schreibeAudit($conn, 'hinzugefuegt', $pat_id, null, $email, $bezug, $aktpc, $person, $vorbereiter, $behandler);
    $_SESSION['eundo_stack'][] = array('typ' => 'hinzugefuegt', 'email' => $email);
  }
} elseif ($aktion === 'aendern' && $email !== '' && $alt_email !== '') {
  $vorherZeile = leseZeile($conn, $pat_id, $alt_email);
  $erfolgreich = false;
  if ($alt_email === $email) {
    // nur Bezug geaendert, Adresse bleibt gleich: Rolle unangetastet lassen
    $erfolgreich = $conn->query("UPDATE pat_email_adr SET bezug=".eSql($conn, $bezug).
      " WHERE pat_id=".eSql($conn, $pat_id)." AND email=".eSql($conn, $email));
  } elseif ($alt_rolle === 'h') {
    // Korrektur der Hauptadresse: alte Zeile als Historie behalten (rolle='a'), nicht loeschen -
    // siehe Spaltenkommentar pat_email_adr.rolle ("a = fruehere Hauptadresse, durch neuere ersetzt")
    $erfolgreich = $conn->query("UPDATE pat_email_adr SET rolle='a' WHERE pat_id=".eSql($conn, $pat_id).
      " AND email=".eSql($conn, $alt_email));
    if ($erfolgreich) {
      $erfolgreich = einfuegenZeile($conn, $pat_id, $email, 'h', $bezug, $aktpc, $person, $vorbereiter, $behandler);
    }
  } else {
    // nicht die Hauptadresse: wie bisher ersetzen (keine Historienpflicht fuer rolle='n')
    $erfolgreich = $conn->query("DELETE FROM pat_email_adr WHERE pat_id=".eSql($conn, $pat_id).
      " AND email=".eSql($conn, $alt_email));
    if ($erfolgreich) {
      $neueRolle = ($alt_rolle === 'a') ? $alt_rolle : 'n';
      $erfolgreich = einfuegenZeile($conn, $pat_id, $email, $neueRolle, $bezug, $aktpc, $person, $vorbereiter, $behandler);
    }
  }
  if ($erfolgreich) {
    schreibeAudit($conn, 'geaendert', $pat_id, $alt_email, $email, $bezug, $aktpc, $person, $vorbereiter, $behandler);
    $_SESSION['eundo_stack'][] = array(
      'typ' => 'geaendert', 'alt_email' => $alt_email,
      'alt_rolle' => $vorherZeile ? $vorherZeile['rolle'] : $alt_rolle,
      'alt_bezug' => $vorherZeile ? $vorherZeile['bezug'] : $bezug,
      'neu_email' => $email,
    );
  }
} elseif ($aktion === 'loeschen' && $alt_email !== '') {
  $vorherZeile = leseZeile($conn, $pat_id, $alt_email);
  if ($vorherZeile && $vorherZeile['rolle'] === 'h') {
    // Die aktuelle Hauptadresse darf nicht ersatzlos geloescht werden: patstamm.FEmail wuerde
    // dadurch NICHT geleert (email ist Teil des Primaerschluessels und NOT NULL, "leer" laesst
    // sich darueber nicht sauber abbilden) - der Patient wuerde nur stillschweigend aus der
    // Commit-Warteliste verschwinden, ohne dass sich an medoff etwas aendert. Mit der
    // Windows-Instanz abgestimmt (Antwort auf die offene Frage 6).
    echo "<!DOCTYPE html><html><head><meta charset='utf-8'><title>Hauptadresse loeschen</title></head><body>";
    echo "<p style='color:red'>Die aktuelle Hauptadresse kann nicht ersatzlos geloescht werden ".
      "(die Email-Adresse in Medical Office wuerde dadurch NICHT geleert, sondern unveraendert ".
      "stehen bleiben). Bitte stattdessen 'Aendern' verwenden und eine bekannte Adresse eintragen.</p>";
    echo "<button type='button' onclick=\"location.href='".htmlspecialchars($ref)."'\">Zurueck</button>";
    echo "</body></html>";
    exit;
  }
  if ($conn->query("DELETE FROM pat_email_adr WHERE pat_id=".eSql($conn, $pat_id)." AND email=".eSql($conn, $alt_email))) {
    schreibeAudit($conn, 'geloescht', $pat_id, $alt_email, null, null, $aktpc, $person, $vorbereiter, $behandler);
    $_SESSION['eundo_stack'][] = array(
      'typ' => 'geloescht', 'email' => $alt_email,
      'rolle' => $vorherZeile ? $vorherZeile['rolle'] : 'n',
      'bezug' => $vorherZeile ? $vorherZeile['bezug'] : null,
    );
  }
} elseif ($aktion === 'hauptsetzen' && $email !== '') {
  // Rang vergeben: eine bereits vorhandene Zeile (rolle='a' oder 'n') wird zur neuen
  // Hauptadresse (rolle='h', die nach patstamm.FEmail soll). Die bisherige Hauptadresse wird
  // wie bei "Aendern" per UPDATE auf rolle='a' herabgestuft, nie geloescht (Historie bleibt
  // erhalten, kein PK-Konflikt moeglich, da keine der beiden Zeilen neu eingefuegt wird).
  $vorherZeile = leseZeile($conn, $pat_id, $email);
  $alteH = null;
  $r = $conn->query("SELECT email FROM pat_email_adr WHERE pat_id=".eSql($conn, $pat_id)." AND rolle='h' LIMIT 1");
  if ($r && $r->num_rows > 0) { $alteHRow = $r->fetch_assoc(); $alteH = $alteHRow['email']; }
  if ($vorherZeile && $vorherZeile['rolle'] !== 'h' && $alteH !== $email) {
    $ok = true;
    if ($alteH !== null) {
      $ok = $conn->query("UPDATE pat_email_adr SET rolle='a' WHERE pat_id=".eSql($conn, $pat_id)." AND email=".eSql($conn, $alteH));
    }
    if ($ok) {
      $ok = $conn->query("UPDATE pat_email_adr SET rolle='h', committed=0, marker=NULL WHERE pat_id=".eSql($conn, $pat_id)." AND email=".eSql($conn, $email));
    }
    if ($ok) {
      schreibeAudit($conn, 'hauptgewaehlt', $pat_id, $alteH, $email, $vorherZeile['bezug'], $aktpc, $person, $vorbereiter, $behandler);
      $_SESSION['eundo_stack'][] = array(
        'typ' => 'hauptgewaehlt', 'alt_email' => $alteH, 'neu_email' => $email,
        'neu_vorherige_rolle' => $vorherZeile['rolle'],
      );
    }
  }
} elseif ($aktion === 'rueckgaengig') {
  $eintrag = array_pop($_SESSION['eundo_stack']);
  if ($eintrag !== null) {
    if ($eintrag['typ'] === 'hinzugefuegt') {
      if ($conn->query("DELETE FROM pat_email_adr WHERE pat_id=".eSql($conn, $pat_id)." AND email=".eSql($conn, $eintrag['email']))) {
        schreibeAudit($conn, 'rueckgaengig', $pat_id, $eintrag['email'], null, null, $aktpc, $person, $vorbereiter, $behandler, 'Hinzufuegen rueckgaengig gemacht');
      }
    } elseif ($eintrag['typ'] === 'geaendert') {
      if ($eintrag['alt_email'] === $eintrag['neu_email']) {
        // war nur eine Bezug-Aenderung: Bezug zuruecksetzen, Rolle unangetastet
        if ($conn->query("UPDATE pat_email_adr SET bezug=".eSql($conn, $eintrag['alt_bezug']).
          " WHERE pat_id=".eSql($conn, $pat_id)." AND email=".eSql($conn, $eintrag['alt_email']))) {
          schreibeAudit($conn, 'rueckgaengig', $pat_id, $eintrag['neu_email'], $eintrag['alt_email'], $eintrag['alt_bezug'], $aktpc, $person, $vorbereiter, $behandler, 'Aenderung rueckgaengig gemacht');
        }
      } elseif ($eintrag['alt_rolle'] === 'h') {
        // Korrektur der Hauptadresse rueckgaengig machen: die per Aendern demotete alte Zeile
        // existiert noch (rolle='a') - per UPDATE zurueckheben statt per INSERT (Primaerschluessel
        // (pat_id,email) wuerde sonst kollidieren). committed/marker zuruecksetzen, damit der
        // naechste Commit-Lauf sie garantiert erneut nach patstamm.FEmail uebertraegt.
        //
        // Die Y-Zeile (neu_email) darf nur geloescht werden, wenn sie NIE committed war
        // (committed=0). Stand sie bereits in medoff (committed=1), muss sie stattdessen auf
        // rolle='a' zurueckgestuft werden statt geloescht zu werden - sonst fehlt dem naechsten
        // Commit-Lauf die Information, dass Y ein bekannter/erwarteter Wert war, und er haelt
        // das dortige medoff-Y faelschlich fuer eine fremde Aenderung (sync_from_medoff wuerde
        // Y wiederherstellen und X erneut zurueckstufen). Mit der Windows-Instanz abgestimmt.
        $yWarCommitted = false;
        $yr = $conn->query("SELECT committed FROM pat_email_adr WHERE pat_id=".eSql($conn, $pat_id).
          " AND email=".eSql($conn, $eintrag['neu_email']));
        if ($yr && $yr->num_rows > 0) {
          $yzeile = $yr->fetch_assoc();
          $yWarCommitted = intval($yzeile['committed']) !== 0;
        }
        if ($yWarCommitted) {
          $ok = $conn->query("UPDATE pat_email_adr SET rolle='a' WHERE pat_id=".eSql($conn, $pat_id).
            " AND email=".eSql($conn, $eintrag['neu_email']));
        } else {
          $ok = $conn->query("DELETE FROM pat_email_adr WHERE pat_id=".eSql($conn, $pat_id).
            " AND email=".eSql($conn, $eintrag['neu_email']));
        }
        if ($ok) {
          $conn->query("UPDATE pat_email_adr SET rolle='h', committed=0, marker=NULL WHERE pat_id=".eSql($conn, $pat_id).
            " AND email=".eSql($conn, $eintrag['alt_email']));
          schreibeAudit($conn, 'rueckgaengig', $pat_id, $eintrag['neu_email'], $eintrag['alt_email'], $eintrag['alt_bezug'], $aktpc, $person, $vorbereiter, $behandler, 'Aenderung rueckgaengig gemacht');
        }
      } else {
        // nicht die Hauptadresse: die alte Zeile wurde beim Aendern echt geloescht, also neu einfuegen
        if ($conn->query("DELETE FROM pat_email_adr WHERE pat_id=".eSql($conn, $pat_id)." AND email=".eSql($conn, $eintrag['neu_email']))) {
          einfuegenZeile($conn, $pat_id, $eintrag['alt_email'], $eintrag['alt_rolle'], $eintrag['alt_bezug'], $aktpc, $person, $vorbereiter, $behandler);
          schreibeAudit($conn, 'rueckgaengig', $pat_id, $eintrag['neu_email'], $eintrag['alt_email'], $eintrag['alt_bezug'], $aktpc, $person, $vorbereiter, $behandler, 'Aenderung rueckgaengig gemacht');
        }
      }
    } elseif ($eintrag['typ'] === 'geloescht') {
      if (einfuegenZeile($conn, $pat_id, $eintrag['email'], $eintrag['rolle'], $eintrag['bezug'], $aktpc, $person, $vorbereiter, $behandler)) {
        schreibeAudit($conn, 'rueckgaengig', $pat_id, null, $eintrag['email'], $eintrag['bezug'], $aktpc, $person, $vorbereiter, $behandler, 'Loeschen rueckgaengig gemacht');
      }
    } elseif ($eintrag['typ'] === 'hauptgewaehlt') {
      // Rangvergabe rueckgaengig machen: beide Zeilen existieren noch unveraendert (nur die
      // Rolle wurde umgesetzt), also reicht ein einfaches Zurueckdrehen per UPDATE - kein
      // Loeschen/Einfuegen und damit auch keine committed-Pruefung noetig.
      $conn->query("UPDATE pat_email_adr SET rolle=".eSql($conn, $eintrag['neu_vorherige_rolle']).
        " WHERE pat_id=".eSql($conn, $pat_id)." AND email=".eSql($conn, $eintrag['neu_email']));
      if ($eintrag['alt_email'] !== null) {
        $conn->query("UPDATE pat_email_adr SET rolle='h', committed=0, marker=NULL WHERE pat_id=".eSql($conn, $pat_id).
          " AND email=".eSql($conn, $eintrag['alt_email']));
      }
      schreibeAudit($conn, 'rueckgaengig', $pat_id, $eintrag['neu_email'], $eintrag['alt_email'], null, $aktpc, $person, $vorbereiter, $behandler, 'Rangaenderung rueckgaengig gemacht');
    }
  }
}

// Nach jeder Aktion linux1_commit_medoff.py direkt anstossen, statt auf den naechsten
// stuendlichen Cron-Fallback zu warten (siehe /etc/sudoers.d/mo-emailadr-commit - wwwrun
// darf per sudo NUR genau diesen einen Befehl ausfuehren, ohne selbst Zugriff auf
// /root/.modbpwd bzw. /root/.mariadbrpwd zu haben). No-op und damit harmlos, wenn nichts
// wartet; Fehler/Timeout werden bewusst ignoriert, der Cron-Fallback faengt das auf.
shell_exec("timeout 10 sudo -n /usr/bin/python3 /opt/mo-emailadr/linux1_commit_medoff.py --apply > /dev/null 2>&1");

zurueck($ref);
