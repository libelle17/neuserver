# Anleitung für den Praxis-Notfall: Serverausfall linux1

**Für:** Medizinische Fachangestellte (MFA) im Notfall, wenn kein IT-Kollege sofort erreichbar ist.
**Voraussetzung, die du schon kannst:** PuTTY öffnen und dich dort als `root` einloggen. Mehr Computerkenntnisse brauchst du nicht – folge einfach den Schritten genau in der angegebenen Reihenfolge.

**Notfallkontakt Gerald Schade:**
- Erste Nummer: **+49 177 8358086**
- Falls nicht erreichbar (Reserve): **+49 151 20201740**
- Falls auch das nicht erreichbar ist (Reserve): **+49 1789429341**

---

## 0. Begriffe, die in dieser Anleitung vorkommen

- **linux1** = der normale Praxis-Server, auf dem im Alltag alles läuft (Karteikarte, Termine, Faxe, Mails, Dokumente).
- **linux0** = der "Reserve-Server" im Serverraum (dort beschriftet), der bei Bedarf für linux1 einspringen kann. Steht normalerweise still im Hintergrund.
- **linux7** = ein zweiter, seltener genutzter Reserve-Server (ebenfalls beschriftet), der im Sprechzimmer 2 auf dem Boden liegt. Wird nur verwendet, wenn linux0 selbst nicht nutzbar ist.
- **"Übernahme"** = Der Reserve-Server (erste Wahl: linux0) gibt sich vorübergehend als "linux1" aus: er bekommt denselben Namen und dieselbe Netzwerk-Adresse wie linux1 und startet die Programme, die eure Praxis-Software braucht. Für die Programme auf euren Windows-PCs sieht es danach so aus, als würde linux1 ganz normal weiterlaufen – nur dass in Wirklichkeit der Reserve-Server dahintersteckt. So könnt ihr weiterarbeiten, während linux1 repariert wird.
- **"Rückgabe"** = Nachdem linux1 repariert wurde, holt sich linux1 alle Daten zurück, die währenddessen auf dem Reserve-Server entstanden sind, und der Reserve-Server gibt seinen "geliehenen" Namen und die Adresse wieder ab. Danach läuft wieder alles wie gewohnt über das echte linux1, und der Reserve-Server geht zurück in seinen Ruhezustand.

**Wichtig zum Verständnis:** Zwischen Übernahme und Rückgabe können mehrere Stunden oder Tage liegen (solange linux1 repariert wird). In dieser Zeit läuft die Praxis ganz normal über den Reserve-Server weiter – ihr müsst nichts Besonderes tun, außer dass Faxe ggf. nicht ankommen (siehe unten).

---

## 1. Wann diese Anleitung anwenden?

Nur wenn ihr (oder Gerald am Telefon) zu der Überzeugung gekommen seid, dass **linux1 wirklich nicht mehr nutzbar ist** – z. B.:
- linux1 lässt sich nicht mehr einschalten oder startet nicht mehr richtig.
- Der Bildschirm von linux1 zeigt dauerhaft Fehler oder bleibt schwarz.
- Gerald hat euch angewiesen, die Übernahme durchzuführen.

**Bitte nicht auf eigene Faust anwenden, nur weil etwas langsam ist oder eine einzelne Anwendung hakt** – das hat meist andere Ursachen. Im Zweifel: anrufen (s. oben).

---

## 2. Sonderfall: Komischer blauer Bildschirm beim Einschalten (BIOS-Warnung)

Wenn ihr linux1 (oder einen anderen Server) einschaltet und **statt der gewohnten Anzeige ein technisch aussehendes Fenster mit englischem Text** erscheint (oft blauer oder schwarzer Hintergrund, z. B. mit dem Wort "Warning" und etwas über Temperatur), dann:

1. **Nicht erschrecken, nichts anderes drücken.** Das ist eine Meldung direkt vom Computer selbst (nicht von Windows oder der Praxis-Software).
2. **Foto mit dem Handy von dem Bildschirm machen**, falls möglich.
3. **Taste `F10` drücken**, um den Start trotzdem fortzusetzen (die Taste oben auf der Tastatur, die einfach nur "F10" beschriftet ist – nicht F1, nicht F12).
4. Der Server sollte danach normal weiterstarten.

**Wichtig, wann ihr deswegen anrufen müsst:**
- **Kommt ihr mit `F10` weiter und der Server startet normal:** Kein Grund für einen sofortigen Anruf – einfach normal mit dieser Anleitung weitermachen. Erwähnt es Gerald einfach beim nächsten ohnehin anstehenden Gespräch (Foto nicht löschen).
- **Kommt ihr mit `F10` NICHT weiter** (der Bildschirm bleibt stehen, oder dasselbe Fenster kommt immer wieder): **Dann jetzt anrufen**, bevor ihr weitermacht.

(Diese Warnung betrifft am ehesten linux1 selbst nach der Reparatur – bei linux0/linux7 im Alltagsbetrieb dürfte sie euch kaum begegnen, da diese Server normalerweise durchlaufen.)

---

## 3. ÜBERNAHME durchführen (linux1 ist ausgefallen)

### Schritt 1: Welcher Reserve-Server wird genutzt?

**Erste Wahl ist immer linux0** (im Serverraum, beschriftet), falls der normal funktioniert. Nur wenn linux0 selbst auch nicht nutzbar ist, **zweite Wahl: linux7** (Sprechzimmer 2, auf dem Boden, ebenfalls beschriftet).

**Wichtiger Unterschied:** Nur bei linux0 könnt ihr das Faxmodem umstecken (Schritt 2) – bei linux7 geht das nicht, weil es im Sprechzimmer 2 liegt und nicht an das Faxmodem im Serverraum angeschlossen werden kann. **Das bedeutet: Wird linux7 verwendet, empfangt ihr währenddessen keine Faxe.** Das ist kein Fehler von euch, sondern eine bekannte Einschränkung – bitte Gerald trotzdem kurz Bescheid geben, damit er das im Blick hat.

### Schritt 2: Nur bei linux0 – Faxmodem umstecken

*(Dauer: ca. 1 Minute)*

Im Serverraum steht hinter linux1 ein graues/schwarzes Kästchen mit der Aufschrift **"USRobotics"** (das Faxmodem), das mit einem Kabel an linux1 angeschlossen ist.

1. **Bevor ihr irgendetwas abzieht: Foto machen**, wo das Kabel gerade steckt (an linux1, welcher Anschluss).
2. Das Kabel vom USRobotics-Modem **vorsichtig von linux1 abziehen**.
3. Das Kabel **in denselben Anschlusstyp an linux0 einstecken** (linux0 steht direkt daneben im Serverrack/-regal).
4. Wenn ihr euch nicht sicher seid, welcher Anschluss der richtige ist: Foto an Gerald schicken und kurz nachfragen, bevor ihr weitermacht (das eilt nicht, die Übernahme selbst kann in der Zwischenzeit schon laufen).

### Schritt 3: PuTTY öffnen, einloggen und Adresse kontrollieren

1. PuTTY öffnen, mit **linux0** verbinden (bzw. linux7, falls dieser verwendet wird) und als `root` einloggen, wie gewohnt.
2. **Kontrollblick, bevor ihr etwas eintippt:** Schaut in der PuTTY-Verbindung nach, mit welcher Adresse/welchem Namen ihr euch gerade wirklich verbunden habt (steht meist oben in der Titelleiste des Fensters oder in euren gespeicherten PuTTY-Einstellungen). Stellt sicher, dass das wirklich **linux0** ist (bzw. linux7, falls dieser verwendet wird) – **nicht linux1**. Im Zweifel: Gerald fragen, bevor ihr weitermacht.

### Schritt 4: Übernahme-Befehl ausführen

*(Dauer: unter 1 Minute)*

Genau so eintippen:

```
cd /root/bin
./uebernahme.sh -e
```

Danach mit Enter bestätigen. Das Programm zeigt einige Zeilen Text an, während es läuft – das ist normal. Am Ende sollte eine Zeile wie **"Fertig."** erscheinen.

**Falls eine Zeile in Rot mit "Erreichbarkeitscheck" und einer Fehlermeldung erscheint** (dass linux1 noch antwortet): Das würde bedeuten, linux1 läuft doch noch – **hier abbrechen und Gerald anrufen**, bevor ihr weitermacht. Nicht selbst mit zusätzlichen Optionen probieren.

### Schritt 5: Prüfen, ob es funktioniert hat

*(Dauer: 1–2 Minuten)*

- Öffnet an einem eurer normalen Arbeitsplätze die Praxis-Software bzw. versucht auf die Netzlaufwerke zuzugreifen, wie ihr das sonst auch tut. Es sollte wie gewohnt funktionieren.
- Falls etwas nicht geht: Gerald anrufen, mit Hinweis "Übernahme durchgeführt, aber Zugriff funktioniert nicht".

**Gesamtdauer Übernahme: in der Regel unter 5 Minuten.**

**Das war's – ab jetzt läuft die Praxis normal über den Reserve-Server weiter, bis linux1 repariert ist.** Ihr müsst nichts weiter tun, bis Gerald oder der Techniker euch sagt, dass linux1 wieder da ist und die Rückgabe ansteht.

---

## 4. RÜCKGABE durchführen (linux1 ist repariert)

Diesen Teil erst durchführen, wenn euch **ausdrücklich gesagt wurde**, dass linux1 repariert ist und wieder verwendet werden soll (von Gerald oder dem Techniker).

### Schritt 1: PuTTY öffnen, einloggen und Adresse kontrollieren

Verbindet euch wieder mit dem Reserve-Server, den ihr bei der Übernahme benutzt habt (also linux0 oder linux7 – **derselbe wie damals**), und loggt euch als `root` ein.

**Kontrollblick wie bei der Übernahme:** Prüft, dass ihr wirklich mit dem richtigen Reserve-Server verbunden seid (linux0 bzw. linux7), nicht versehentlich mit dem jeweils anderen.

### Schritt 2: Rückgabe-Befehl ausführen

```
cd /root/bin
./rueckgabe.sh -e
```

Dieser eine Befehl macht automatisch **alles** nacheinander – ihr müsst nur warten und beobachten:

| Teilschritt (läuft automatisch) | ungefähre Dauer |
|---|---|
| Geliehene Adresse freigeben | wenige Sekunden |
| linux1 aufwecken und warten, bis es erreichbar ist | meist 1–5 Minuten, im ungünstigsten Fall bis zu 10 Minuten |
| Automatischer Start der Datenübernahme auf linux1 | sofort im Anschluss |
| Sicherungskopie des bisherigen Datenstands auf linux1 | ca. 2–5 Minuten |
| Eigentliche Datenrückholung von linux0/linux7 | meist 10–20 Minuten, in Ausnahmefällen (technische Rückfallmethode) bis zu 60 Minuten |
| Reserve-Server geht zurück in den Ruhezustand | unter 1 Minute |

**Insgesamt also üblicherweise 20–40 Minuten, in Ausnahmefällen auch mal deutlich länger (bis zu ca. 1,5 Stunden).** Das Fenster läuft die ganze Zeit weiter – auch wenn länger nichts Neues erscheint, ist das normal. Einfach warten und das Fenster nicht schließen.

**Während der Rückgabe kann es eine kurze Unterbrechung der Praxis-Software geben** (üblicherweise wenige Minuten, während "Sicherungskopie" und "Datenrückholung" laufen) – am besten also nicht mitten im Praxisbetrieb starten, sondern in einer ruhigeren Phase, falls ihr das beeinflussen könnt.

Am Ende sollte wieder eine Zeile **"Fertig."** erscheinen, und weiter oben eine Zeile **"Datenrueckholung abgeschlossen."**.

**Falls stattdessen etwas in Rot mit "fehlgeschlagen" oder "Fehler" erscheint:** Fenster nicht schließen, sondern **Gerald anrufen** und ihm sagen, was in der Anleitung als letztes ausgeführt wurde und was die letzten paar Zeilen im PuTTY-Fenster zeigen (am besten ein Foto vom Bildschirm machen).

### Schritt 3: Nur bei linux0 – Faxmodem zurückstecken

*(Dauer: ca. 1 Minute)*

Genau umgekehrt wie bei der Übernahme:

1. Das USRobotics-Kabel von linux0 abziehen.
2. Wieder in denselben Anschluss an linux1 einstecken (dort, wo es laut eurem Foto von der Übernahme vorher war).

### Schritt 4: Prüfen, ob es funktioniert hat

*(Dauer: 1–2 Minuten)*

- Praxis-Software / Netzlaufwerke wie gewohnt testen.
- Falls Faxmodem umgesteckt wurde: kurz testen, ob ein Testfax ankommt, falls ihr wisst, wie das geht – sonst Gerald fragen.

**Damit ist die Rückgabe abgeschlossen.** linux1 läuft wieder normal, der Reserve-Server geht zurück in seinen stillen Ruhezustand.
