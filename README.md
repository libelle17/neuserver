<h3>Manual: 1) <a href="#english_E">english</a>, 2) <a href="#deutsch_D">deutsch (unten anschließend)</a></h3>

<h1 align="center">NEUSERVER (Version 0.47247) - english<a name="english_D"></a></h1>

<a href="#NAME_D">NAME</a><br>
<a href="#SYNOPSIS_D">SYNOPSIS</a><br>
<a href="#SHORT DESCRIPTION_D">SHORT DESCRIPTION</a><br>
<a href="#INSTALLATION_D">INSTALLATION</a><br>
<a href="#USAGE_D">USAGE</a><br>
<a href="#OPTIONS_D">OPTIONS</a><br>
<a href="#FUNCTIONALITY_D">FUNCTIONALITY</a><br>
<a href="#PRECONDITIONS_D">PRECONDITIONS</a><br>
<a href="#AUTOMATICALLY INSTALLED SOFTWARE PACKAGES_D">AUTOMATICALLY INSTALLED SOFTWARE PACKAGES</a><br>
<a href="#IMPLICATIONS_D">IMPLICATIONS</a><br>
<a href="#UNINSTALLING_D">UNINSTALLING</a><br>
<a href="#RETURN CODES_D">RETURN CODES</a><br>
<a href="#ERRORS_D">ERRORS</a><br>
<a href="#PROGRAM MODIFICATION_D">PROGRAM MODIFICATION</a><br>
<a href="#LIABILITY_D">LIABILITY</a><br>
<a href="#AUTHOR_D">AUTHOR</a><br>

<hr>


<h2>NAME
<a name="NAME_D"></a>
</h2>



<p style="margin-left:11%; margin-top: 1em"><b>&quot;neuserver&quot;
&minus; Configuration of a new linux server</b>: Allows the
configuration of a new linux server for a diabetologic
practice in Dachau, after the operation system installation
by the vendor&rsquo;s programme. <br>
(manpage-Hilfe in deutsch verf&uuml;gbar: &rsquo;man
&quot;neuserver&quot;&rsquo; oder &rsquo;man -Lde
&quot;neuserver&quot;&rsquo;)</p>

<h2>SYNOPSIS
<a name="SYNOPSIS_D"></a>
</h2>



<p style="margin-left:11%; margin-top: 1em"><b>&quot;neuserver&quot;
[-&lt;shortopt&gt;|--&lt;longopt&gt; [&lt;supplement&gt;]]
...</b></p>

<h2>SHORT DESCRIPTION
<a name="SHORT DESCRIPTION_D"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Contains the
necessary scripts for setup and operation (especially data
backup on backup server). After the scripts have been
downloaded, ./los.sh is called in the installation
directory. With &rsquo;make git install&rsquo; the scripts
are transferred to the operating directories, with
&rsquo;make&rsquo; any further developments there are
transferred back to the installation directory.</p>

<h2>INSTALLATION
<a name="INSTALLATION_D"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">First, please
read the chapters &rsquo;functionality&rsquo;,
&rsquo;preconditions&rsquo;,&rsquo;automatically installed
software packages&rsquo; and &rsquo;implications&rsquo;
below. Then, if connected to the internet, call (e.g. by
coying the line and pasting it into a terminal): <b><br>
N=&quot;neuserver&quot;;P=${N}_inst.sh;cd ~;wget
https://raw.githubusercontent.com/&quot;libelle17&quot;/$N/master/install.sh
-O$P&&sh $P</b> <br>
At last, call: <b><br>
./los.sh</b> <br>
and answer some questions of the program.</p>

<h2>USAGE
<a name="USAGE_D"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Ideally, the
program should have installed itsself after the first
call(s) (see above) and one-time answering of some questions
in a self-running way. <br>
If another fully configured Linux server is already running,
which can be named when prompted, then it is easier. <br>
With <b>sh viall</b> scripts can be edited.</p>

<h2>OPTIONS
<a name="OPTIONS_D"></a>
</h2>



<p style="margin-left:11%; margin-top: 1em">&rsquo;<b>./los.sh
-h</b>&rsquo; shows the command line options.</p>

<h2>FUNCTIONALITY
<a name="FUNCTIONALITY_D"></a>
</h2>


<h2>PRECONDITIONS
<a name="PRECONDITIONS_D"></a>
</h2>


<h2>AUTOMATICALLY INSTALLED SOFTWARE PACKAGES
<a name="AUTOMATICALLY INSTALLED SOFTWARE PACKAGES_D"></a>
</h2>


<h2>IMPLICATIONS
<a name="IMPLICATIONS_D"></a>
</h2>


<h2>UNINSTALLING
<a name="UNINSTALLING_D"></a>
</h2>


<h2>RETURN CODES
<a name="RETURN CODES_D"></a>
</h2>


<h2>ERRORS
<a name="ERRORS_D"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Please report
any errors with the word &rsquo;&quot;neuserver&quot;&rsquo;
included in the email headline. <br>
Please report as well, if different hard- or software yields
a requirement for a program modification.</p>

<h2>PROGRAM MODIFICATION
<a name="PROGRAM MODIFICATION_D"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">By calling
&rsquo;<b>sh viall</b>&rsquo; and application of the usual
&rsquo;<b>vim</b>&rsquo;-commands, followed by
&rsquo;<b>make</b>&rsquo; and &rsquo;<b>make
install</b>&rsquo; from the installation directory
(&rsquo;<b>~/&quot;neuserver&quot;</b>), You may alter the
program.</p>

<h2>LIABILITY
<a name="LIABILITY_D"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">The program has
been written with the best aim and has been tested by the
author. <br>
Nevertheless the author cannot be liable for any damage
caused by the program.</p>

<h2>AUTHOR
<a name="AUTHOR_D"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Gerald Schade
(geraldschade@gmx.de; www.diabdachau.de)</p>
<hr>
</body>
</html>

<h1 align="center">NEUSERVER (Version 0.47247) - deutsch<a name="deutsch_D"></a></h1>

<a href="#NAME_D">NAME</a><br>
<a href="#SYNOPSIS_D">SYNOPSIS</a><br>
<a href="#KURZBESCHREIBUNG_D">KURZBESCHREIBUNG</a><br>
<a href="#INSTALLATION_D">INSTALLATION</a><br>
<a href="#GEBRAUCH_D">GEBRAUCH</a><br>
<a href="#OPTIONEN_D">OPTIONEN</a><br>
<a href="#FUNKTIONSWEISE_D">FUNKTIONSWEISE</a><br>
<a href="#VORAUSSETZUNGEN_D">VORAUSSETZUNGEN</a><br>
<a href="#AUTOMATISCH INSTALLIERTE PROGRAMMPAKETE_D">AUTOMATISCH INSTALLIERTE PROGRAMMPAKETE</a><br>
<a href="#AUSWIRKUNGEN DES PROGRAMMABLAUFS_D">AUSWIRKUNGEN DES PROGRAMMABLAUFS</a><br>
<a href="#DEINSTALLATION_D">DEINSTALLATION</a><br>
<a href="#RUECKGABEWERTE_D">RUECKGABEWERTE</a><br>
<a href="#FEHLER_D">FEHLER</a><br>
<a href="#PROGRAMM&Auml;NDERUNG_D">PROGRAMM&Auml;NDERUNG</a><br>
<a href="#HAFTUNG_D">HAFTUNG</a><br>
<a href="#AUTOR_D">AUTOR</a><br>

<hr>


<h2>NAME
<a name="NAME_D"></a>
</h2>



<p style="margin-left:11%; margin-top: 1em"><b>&quot;neuserver&quot;
&minus; Einrichtung eines neuen Linuxservers</b>:
enth&auml;lt die notwendigen Programme zur Einrichtung
eines neuen Linuxservers f&uuml;r eine diabetologische
Schwerpunktpraxis in Dachau, nach Installation des
Betriebssystems <br>
(manpage available in english: &rsquo;man
&quot;neuserver&quot;&rsquo; or &rsquo;man -Len
&quot;neuserver&quot;&rsquo;)</p>

<h2>SYNOPSIS
<a name="SYNOPSIS_D"></a>
</h2>



<p style="margin-left:11%; margin-top: 1em"><b>&quot;neuserver&quot;
[-&lt;kurzopt&gt;|--&lt;langopt&gt;
[&lt;erg&auml;nzung&gt;]] ...</b></p>

<h2>KURZBESCHREIBUNG
<a name="KURZBESCHREIBUNG_D"></a>
</h2>



<p style="margin-left:11%; margin-top: 1em"><b>&quot;neuserver&quot;</b>
Enth&auml;lt die notwendigen Scripte f&uuml;r
Einrichtung und Betrieb (insbesondere Datensicherung auf
Sicherungsserver). Nach dem Herunterladen der Scripte wird
im Installationsverzeichnis ./los.sh aufgerufen. Mit
&rsquo;make git install&rsquo; werden die Scripte in die
Betriebsverzeichnisse &uuml;bertragen, mit
&rsquo;make&rsquo; werden evtuelle dortige
Weiterentwicklungen wieder in das Installationsverzeichnis
zur&uuml;ck&uuml;bertragen.</p>

<h2>INSTALLATION
<a name="INSTALLATION_D"></a>
</h2>



<p style="margin-left:11%; margin-top: 1em">Zun&auml;chst
lesen Sie bitte die untenstehenden Kapitel
&rsquo;Funktionsweise&rsquo;,&rsquo;Voraussetzungen&rsquo;,&rsquo;Automatisch
installierte Programmpakete&rsquo; und &rsquo;Auswirkungen
des Programmablaufs&rsquo;. <br>
Anschlie&szlig;end verbinden Sie den Rechner falls
n&ouml;tig mit dem Internet und rufen Sie auf (z.B.
durch Kopieren der Zeile in die Zwischenablage und
Einf&uuml;gen in einem Terminal): <b><br>
N=&quot;neuserver&quot;;P=${N}_inst.sh;cd ~;wget
https://raw.githubusercontent.com/&quot;libelle17&quot;/$N/master/install.sh
-O$P&&sh $P</b> <br>
Zuletzt rufen Sie auf: <b><br>
./los.sh</b> <br>
und beantworten einige Rueckfragen des Programms.</p>

<h2>GEBRAUCH
<a name="GEBRAUCH_D"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Im Idealfall
sollte sich das Programm nach dem/n erstem/n Aufruf/en
(s.o.) und Beantworten einmaliger R&uuml;ckfragen so
eingerichtet haben, dass es von selbst weiter
l&auml;uft. <br>
Mit <b>sh viall</b> lassen sich Skripte editieren. <br>
Wenn schon ein anderer fertig eingerichteter Linuxserver
l&auml;uft, der bei einer R&uuml;ckfrage benannt
werden kann, dann geht es einfacher.</p>

<h2>OPTIONEN
<a name="OPTIONEN_D"></a>
</h2>



<p style="margin-left:11%; margin-top: 1em">&rsquo;<b>./los.sh
-h</b>&rsquo; zeigt die Befehlszeilenoptionen.</p>

<h2>FUNKTIONSWEISE
<a name="FUNKTIONSWEISE_D"></a>
</h2>


<h2>VORAUSSETZUNGEN
<a name="VORAUSSETZUNGEN_D"></a>
</h2>


<h2>AUTOMATISCH INSTALLIERTE PROGRAMMPAKETE
<a name="AUTOMATISCH INSTALLIERTE PROGRAMMPAKETE_D"></a>
</h2>


<h2>AUSWIRKUNGEN DES PROGRAMMABLAUFS
<a name="AUSWIRKUNGEN DES PROGRAMMABLAUFS_D"></a>
</h2>


<h2>DEINSTALLATION
<a name="DEINSTALLATION_D"></a>
</h2>


<h2>RUECKGABEWERTE
<a name="RUECKGABEWERTE_D"></a>
</h2>


<h2>FEHLER
<a name="FEHLER_D"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Fehler bitte
mit u.a. dem Wort &rsquo;&quot;neuserver&quot;&rsquo; in der
Email-Ueberschrift melden. <br>
Bitte auch melden, wenn sich &Auml;nderungsbedarf durch
andere Hard- bzw. Software ergeben.</p>

<h2>PROGRAMM&Auml;NDERUNG
<a name="PROGRAMM&Auml;NDERUNG_D"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Durch Aufruf
von &rsquo;<b>sh viall</b>&rsquo; mit den &uuml;blichen
&rsquo;<b>vim</b>&rsquo;-Befehlen, gefolgt von
&rsquo;<b>make</b>&rsquo; und &rsquo;<b>make
install</b>&rsquo; vom Installationsverzeichnis
(&rsquo;<b>~/&quot;neuserver&quot;</b>) aus k&ouml;nnen
Sie das Programm &auml;ndern.</p>

<h2>HAFTUNG
<a name="HAFTUNG_D"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Das Programm
wurde mit bester Absicht entwickelt und durch den Autor
getestet. <br>
Trotzdem kann der Autor f&uuml;r keine Sch&auml;den
haften, die durch das Programm entstehen
k&ouml;nnten</p>

<h2>AUTOR
<a name="AUTOR_D"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Gerald Schade
(geraldschade@gmx.de; www.diabdachau.de)</p>
<hr>
</body>
</html>
