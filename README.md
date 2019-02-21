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
- Fax server functionality</b>: induces automatic fax
transmission of files, naming of received faxes and logging
of all of them in a database <br>
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



<p style="margin-left:11%; margin-top: 1em"><b>&quot;neuserver&quot;</b>
offers quasi the functionality of a fax server, which can be
useful for some also behind a fast data line. <b><br>
&quot;neuserver&quot;</b> is a command line program to remit
files of a certain directory automatically to <b>hylafax</b>
(in case a linux-compatible modem is installed) and/or
<b>capisuite</b> (in case a fritzcard 2.0 or 2.1 is
installed), if the fax number is integrated in the file name
as requested. Furthermore, &quot;neuserver&quot; holds the
posted faxes in a mariadb database. <br>
Additionally, received faxes from
<b>hylafax</b>/<b>capisuite</b> can be named automatically
with the sender&rsquo;s name, according to his fax number,
and stored. <br>
The usability within a network (may also be a windows
network with only one linux machine) is being accomplished
by automatic integration of all relevant directories into a
samba server. It could be complemented by a frontend for the
mariadb database.</p>

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
&quot;neuserver&quot;</b> <br>
and answer some questions of the program. <br>
The first execution and the first processing of a
sent/received fax with each of hylafax and/or capisuite may
take some time and need some additional input, respectively.
<b><br>
&quot;neuserver&quot; -again</b> for each of then. Hereby
the necessary program installations for future fax receiving
will simultaneously be completed.</p>

<h2>USAGE
<a name="USAGE_D"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Ideally, the
program should have installed itsself after the first
call(s) (see above) and one-time answering of some questions
in a self-running way. <br>
Then a directory e.g. &rsquo;<b>tobefaxed</b>&rsquo; exists,
in which e.g. users in a network (e.g. via the above
mentioned samba share) can deposit files to be faxed, e.g.
<br>
&quot;<b>Medical report on Frank Ill to Dr. Healthy and
Frank Ill to fax 099 987654321 and 088
887654321.doc</b>&quot; (it could also be e.g. an *.xls, a
*.jpg, a *.tif, a *.txt, a *pdf file; the section &rsquo; to
Dr. Healthy and Frank Ill&rsquo; is optional for the later
allocation of the fax number(s) in the database, it may also
be obmitted; on the other hand, if the program can assign
the last (1-)3 faxes to a certain addressee clearly, the
section &rsquo; to fax 099 987654321 and 088
887654321&rsquo; may be obmitted). <br>
When <b>&quot;neuserver&quot;</b> is called for the next
time (per default 2 minutes), the above mentioned example
file will initially be copied and renamed into <br>
&quot;<b>Medical report on Frank Ill to Dr. Healthy to fax
099 987654321.doc</b>&quot; and <br>
&quot;<b>Medical report on Frank Ill to Frank Ill to fax 088
887654321.doc</b>&quot; and converted into the pdf-files
<br>
&quot;<b>Medical report on Frank Ill to Dr. Healthy to fax
099 987654321.pdf</b>&quot; and <br>
&quot;<b>Medical report on Frank Ill to Frank Ill to fax 088
887654321.pdf</b>&quot;. <br>
Those are subsequently being relayed to <b>hylafax</b> or
<b>Capisuite</b> and from there sent. <br>
Simultaneously they are being moved from
&rsquo;<b>tobefaxed</b>&rsquo; to the waiting directory,
e.g. &rsquo;<b>waitingfaxes</b>&rsquo; and recorded in the
spool table <b>spooltab</b>. <br>
Faxes which are placed by a user in the directory
&rsquo;<b>tobefaxed/2200</b>&rsquo; will be handled starting
at 10 p.m., if &quot;neuserver&quot; is running. <br>
If subdirectories in &rsquo;<b>tobefaxedfR&rsquo; are found
named with a date or time (e.g. &rsquo;20180101
0800</b>&rsquo; or &rsquo;<b>2200</b>&rsquo;), the contained
faxes will be processed after that time an in the first case
the subdirectory will then be deleted if empty. <br>
At each call, &quot;neuserver&quot; checks the status of
<b>hylafax</b> and/or <b>Capisuite</b>. The Finishing of a
fax process there causes &quot;neuserver&quot; to move the
source files (here the above mentioned .doc- and .pdf-files)
from the waiting directory to one or several archive
directories or a directory for failed faxes and to move
their database record from &rsquo;<b>spooltab</b>&rsquo; to
the archive table &rsquo;<b>outa</b>&rsquo;. <br>
Further on, incoming faxes via <b>hylafax</b> or
<b>Capisuite</b> are being transmitted to an incoming
directory and if applicable named including the
sender&rsquo;s name. To this purpose, customizeable sql
commands are being used, if specified. <br>
Depending on operating system, accessability and preferences
the users thus could look up the status of their faxes in
the above mentioned directories, in the database tables or
by calling &rsquo;<b>&quot;neuserver&quot;&rsquo;,
&rsquo;&quot;neuserver&quot; -lista</b>&rsquo;,
&rsquo;<b>&quot;neuserver&quot; -listf</b>&rsquo; or
&rsquo;<b>&quot;neuserver&quot; -listi</b>&rsquo;.</p>

<h2>OPTIONS
<a name="OPTIONS_D"></a>
</h2>



<p style="margin-left:11%; margin-top: 1em">&rsquo;<b>&quot;neuserver&quot;
-?</b>&rsquo; or &rsquo;<b>&quot;neuserver&quot;
-h</b>&rsquo; shows the important command line options and
&rsquo;<b>&quot;neuserver&quot; -lh</b>&rsquo; all of them.
Some options (e.g. the sql commands for finding an addressee
from the fax number) cannot be set via the command line, but
only via the configuration file, which can be edited
directly by &rsquo;<b>&quot;neuserver&quot; -vi</b>&rsquo;
or interactively by &rsquo;<b>&quot;neuserver&quot;
-rf</b>&rsquo;.</p>

<h2>FUNCTIONALITY
<a name="FUNCTIONALITY_D"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">When called,
&rsquo;<b>&quot;neuserver&quot;</b>&rsquo; accomplishes the
following:</p>

<p style="margin-left:11%; margin-top: 1em"><b>1)</b> The
current hardware is being checked. <b><br>
a)</b> with the command &rsquo;<b>lspci | grep -i
isdn</b>&rsquo; for a fritz card. <b><br>
b)</b> with the command &rsquo;<b>stty -F</b>&rsquo; for a
fax modem.</p>

<p style="margin-left:11%; margin-top: 1em"><b>2)</b> The
fax configuration file <b>fax.conf</b> of capisuite is read,
if it exists</p>

<p style="margin-left:11%; margin-top: 1em"><b>3)</b>
Further defaults from the program code are assigned which
can be overloaded by the &quot;neuserver&quot; configuration
file (see 4), command line arguments or anwers to questions
(see 5).</p>

<p style="margin-left:11%; margin-top: 1em"><b>4)</b>
Defaults are loaded from the configuration file, if it
exists (per default <b>&quot;neuserver&quot;.conf</b> in the
same directory as <b>&quot;neuserver&quot;</b>, per default
<b>/usr/local/sbin/&quot;neuserver&quot;</b>))</p>

<p style="margin-left:11%; margin-top: 1em"><b>5)</b>
Questions are asked, if values are missing from the
configuration file (see 4) or if a command line option
demands interacitivity.</p>

<p style="margin-left:11%; margin-top: 1em"><b>6)</b> The
directory of <b>hylafax</b> is beeing determined
(<b>/var/spool/hylafax</b> or <b>/var/spool/fax</b>), if
hylafax is installed.</p>

<p style="margin-left:11%; margin-top: 1em"><b>7)</b>
Directories used by the users for fax files to be sent, for
waiting faxes, for fax files already sent, for failed faxes
and for received faxes are being checked and created if
needed. Thereby user defined file name patterns can be
respected to store successfully sent faxes in different
directories.</p>

<p style="margin-left:11%; margin-top: 1em"><b>8)</b> The
program inserts itsself if wanted and necessary in
root&rsquo;s <b>crontab</b> in order to be called in
adjustable intervals. To avoid this, either
&rsquo;<b>cronminut</b>&rsquo; can be set to <b>0</b>, or
the already generated &quot;neuserver&quot; entries can be
commented out with a leading &rsquo;<b>#</b>&rsquo;.</p>

<p style="margin-left:11%; margin-top: 1em"><b>9)</b> The
program checks if all user-relevant directories (see 7) are
being included in samba shares in
<b>/etc/samba/smb.conf</b>; such are being added if
needed.</p>

<p style="margin-left:11%; margin-top: 1em"><b>10)</b>
Working of MariaDB is being checked, if necessary it is
being (installed and) started, the database tables
<b>spooltab</b> (for faxes just in spool), <b>outa</b> (for
sent and failed faxes) and <b>inca</b> (for received faxes)
are being checked and if necessary created or amended.</p>

<p style="margin-left:11%; margin-top: 1em"><b>11)</b> In
case of the respective command line options corrections in
the contents of the waiting directory or of the database
tables are being commited or their contents is being listed
and then the program is being finished.</p>

<p style="margin-left:11%; margin-top: 1em"><b>12)</b>
Otherwise, file in the outgoing directory are being
analysed. Each file with some identifiable fax number(s)
within its file name which is or can be converted in/into
pdf format will be moved to to waiting directory and
recorded in <b>spooltab</b>. <br>
If a file contains more than one recepients and/or a
conversion to pdf is necessary, additional files are
generated and the original file may be renamed. If
necessary, additional numbers near the end of the file
name(s) may be added in order not to conflict with any other
file name in one of the directories mentioned in 7). <br>
If more files have been generated, the successive movements
and recordings are being carried out with all of them.</p>

<p style="margin-left:11%; margin-top: 1em"><b>13)</b>
Depending on the configuration the functionaliy of
<b>hylafax</b> and/or <b>capisuite</b> is being checked and
if necessary and possible restored (including by
installation of those programs; in case of a fritzcard 2.0
or a fax modem USR5637 an additional automatic configuration
can/will be done). Kernel modules for hylafax and/or
capisuite are automatically generated, also in case of a
kernel update.</p>

<p style="margin-left:11%; margin-top: 1em"><b>14)</b> In
case of respective command line options faxes are being
deleted and the program is finished.</p>

<p style="margin-left:11%; margin-top: 1em"><b>15)</b>
Otherwise the files which have been recorded under 12) in
<b>spooltab</b> are being forwarded to <b>hylafax</b> or
<b>capisuite</b> and this is being protocolled in
<b>spooltab</b>.</p>

<p style="margin-left:11%; margin-top: 1em"><b>16)</b> All
faxes which are recorded in <b>spooltab</b> as waiting are
being checked in <b>hylafax</b>/<b>capisuite</b> as to their
status which is being updated in <b>spooltab</b> (number of
tries hitherto). <br>
If hylafax and capisuite are working simultaneously and a
prespecified number of send tries has been reached without
success in the programs of the first preference of those
two, the fax is additionally forwarded to the second of the
two programs. <br>
If the fax transmission is finished (with/without success),
the file is being moved from the waiting directory to the
respective directory for sent faxes or for failed faxes,
optionally modified by ocr via ocrmypdf (if a young enough
python3 &gt; 3.5 is installed), and the database entry is
being transferred from <b>spooltab</b> to <b>outa</b>. <br>
The status of the mentioned faxes is being displayed.</p>

<p style="margin-left:11%; margin-top: 1em"><b>17)</b> If
additional faxes in the spool of hylafax/capisuite are
detected which are not created via &quot;neuserver&quot;,
they are displayed. In intervals they will be integrated
into the &quot;neuserver&quot; database (without the not
available information on the original file name).</p>

<p style="margin-left:11%; margin-top: 1em"><b>18)</b> Via
<b>hylafax</b>/<b>capisuite</b> received faxes are copied to
a receiving directory and there named with the name of the
sender, if possible, by means of their fax number which is
being looked up using a predefineable number of
predefineable sql commands, which are applied one after
another until the fax number is found. <br>
Such sql commands shall deliver (at least) 2 fields (with a
user defined sense), whose contents, separated by a comma,
will be used by &quot;neuserver&quot; to name the received
faxes. Before applied, within the sql commands the string
&rsquo;&&faxnr&&&rsquo; will be replaced by
the current fax number. Example: <i><br>
select concat(haname,&rsquo;, &rsquo;,ort,&rsquo;,
&rsquo;,kvnu) name, zulg from kvaerzte.hae where
concat(if(mid(fax1k,1,1)=&rsquo;0&rsquo;,&rsquo;&rsquo;,&rsquo;08131&rsquo;),
replace(replace(replace(replace(fax1k,&rsquo;
&rsquo;,&rsquo;&rsquo;),&rsquo;-&rsquo;,&rsquo;&rsquo;),&rsquo;/&rsquo;,&rsquo;&rsquo;),&rsquo;&acute;&rsquo;,&rsquo;&rsquo;))
= &rsquo;&&faxnr&&&rsquo;</i> <br>
If more sql commands are specified and one of them does not
give a result, the next one will be tried. <br>
Optionally, the received faxes are subjected to ocr via a
call of ocrmypdf.</p>

<p style="margin-left:11%; margin-top: 1em"><b>19)</b> The
configuration file is being written, if necessary.</p>

<p style="margin-left:11%; margin-top: 1em"><b>20)</b> If
the option <b>-autoupd</b> (<b>--autoupdate</b>) is acitve,
at last after the second call of every day the version
number of <b>&quot;neuserver&quot;</b> will be compared with
that of the installation source und if necessary a new
version will be installed.</p>

<p style="margin-left:11%; margin-top: 1em">Some program
parts are executed simultaneously, which may loosen up the
display of the result. <br>
Sending and receiving are started every minute, until the
respective other part has finished for the first time. <br>
Check and possibly correction of possibly falsely stored fax
files (e.g. by a cancelling the program deliberately) will
be done in intervals.</p>

<h2>PRECONDITIONS
<a name="PRECONDITIONS_D"></a>
</h2>



<p style="margin-left:11%; margin-top: 1em"><b>Hardware</b>:
Computer with a fritzcard 2.0 or 2.1 or/and a linux
compatible fax modem; in the current version, a US Robotics
modem USR5637 and one of the below mentioned linux
distributions are needed for an automatic installation (by
answering some questions). In case of a concurrent use of a
fritzcard and a modem, the program can optimize the security
of transmission of a fax. <b><br>
Software</b>: The program was adjusted to an installation of
Opensuse &gt;= 42.1, Debian &gt;= 9.10, Ubuntu &gt;= 16.04,
Mint &gt;= 18 or Fedora &gt;= 24 with standard options.
System D has to be installed, i.e., &quot;systemctl&quot;
has to run, which is the case in the mentioned program
versions. One of the packet managers rpm or dpkg and apt,
dnf, yum or zypper has to be installed, respectively, as is
the case per default in the mentioned linux distributions.
The program &rsquo;<b>wget</b>&rsquo; must be installed.
Uninstalling of the programs added by &quot;neuserver&quot;
by <b>make uninstall</b> works currently only with the
english and the german versions of the packet manager.</p>

<h2>AUTOMATICALLY INSTALLED SOFTWARE PACKAGES
<a name="AUTOMATICALLY INSTALLED SOFTWARE PACKAGES_D"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">(for this
purpose, depending on the distribution, zypper, apt(-get),
dnf or yum are used).</p>


<p style="margin-left:11%; margin-top: 1em"><b>makefile:</b>
<br>
gcc V.6, g++ V.6, groff, libmysqlclient-dev(el),
libtiff-dev(el) (in case of version 4.0.7 with a slight
modification, see Makefile)</p>


<p style="margin-left:11%; margin-top: 1em"><b>&quot;neuserver&quot;:</b>
<br>
acl, boost, boost-devel, boost-iostreams-devel,
boost-local-devel, cron, ghostscript, imagemagick,
libreoffice-common, libreoffice-base, mariadb-server,
policycoreutils, policycoreutils-python-utils,
poppler-tools, samba, sfftobmp, (in debian-derivates, for
mariadb, additionally: apt-transport-https)</p>

<p style="margin-left:11%; margin-top: 1em"><i>in case</i>
<b>capisuite</b> <i>shall be used</i>: <br>
capisuite, capiutils, capi4linux, fcpci-3.10.0, gcc-4.8,
g++-4.8, kernel-source (linux-source), libcapi20-2,
libcapi20-3, libxslt-tools, linux-headers-$(uname -r),
python-devel, (in fedora, additionally:
kernel-modules-extra),</p>

<p style="margin-left:11%; margin-top: 1em"><i>in case</i>
<b>hylafax</b> <i>shall be used</i>: <br>
hylafax+, hylafax+-client, sendmail, tiff (in case of
version 4.0.7 with a slight modification, see Makefile)</p>

<p style="margin-left:11%; margin-top: 1em"><i>in case</i>
<b>ocr</b> <i>shall be used</i>: <br>
ffmpeg, ffmpeg-devel, ffmpeg-compat, gcc, libavformat-devel,
libffi-devel, ocrmypdf, python3-devel, python3-pip,
python3-setuptools, rpmfusion, qpdf, redhat-rpm-config,
tesseract-ocr, unpaper, and via &rsquo;python3 pip&rsquo;:
cryptography, cffi, image, M2Crypto, ocrmypdf, PyPDF2,
reportlab, ruffus.</p>

<p style="margin-left:11%; margin-top: 1em"><i>in case You
want to work on the source files with &rsquo;sh
viall&rsquo;</i>: <br>
vim</p>

<p style="margin-left:11%; margin-top: 1em">All those
installations may include dependent programs. <br>
If You don&rsquo;t want one of those programs or want to
keep an older version of one, You may not install
&quot;neuserver&quot; or use the respective program
parts.</p>

<h2>IMPLICATIONS
<a name="IMPLICATIONS_D"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">The program has
to take the following measures for its neat function:</p>

<p style="margin-left:11%; margin-top: 1em"><b>1)</b> In
debian, in the file /etc/apt/sources.list a dvd-entry can be
moved behind the standard online repositories. <b><br>
2)</b> Sudo (is missing per default in debian) will be
installed if needed. <br>
The current linux user, if not already contained, will be
entered into an administrator group mentioned in
/etc/sudoers, because he has to call &quot;sudo&quot;.
<b><br>
3)</b> &rsquo;GNU make&rsquo; will be installed if not
present, automatically by calling &rsquo;sh
install.sh&rsquo; or &rsquo;configure&rsquo;. <b><br>
4)</b> Installation of <b>hylafax+</b>, in case a modem is
connected and hylafax+ is not installed. If necessary
configuration of hylafax+ by calling &rsquo;<b>faxsetup
-nointeracitve</b>&rsquo;, by editing the configuration
files <b>config</b> and <b>config.*</b> (e.g.
<b>config.ttyACM0</b>) in the hylafax configuration
directory (default e.g. <b>/var/spool/hylafax/etc</b>).</p>

<p style="margin-left:11%; margin-top: 1em"><b>5)</b>
Installation of <b>capisuite</b>, in case a fritzcard is
inserted and capisuite is not installed. If necessary
configuration of <b>/etc/capisuite/capisuite.conf</b> and
<b>/etc/capisuite/fax.conf</b>. If necessary edition of the
python-script for received faxes (default e.g.
<b>/usr/lib64/capisuite/incoming.py</b>) in order to
determine the rings before answer, creation and edition of
the files
&rsquo;<b>/etc/udev/rules.d/46-FKN_isdn_capi.rules</b>&rsquo;,
&rsquo;<b>/etc/modprobe.d/50-blacklist.conf</b>&rsquo;.</p>

<p style="margin-left:11%; margin-top: 1em"><b>6)</b>
Installation of services: <b><br>
a)</b> in systemd (in the directory /usr/lib/systemd/system
or /lib/systemd/system), especially: <b><br>
hylafax-faxq.service</b>, <b>hylafax-hfaxd.service</b>,
<b>hylafax-faxgetty-....service</b> (e.g.
<b>hylafax-faxgetty-ttyACM0</b>), <b><br>
capisuite.service</b>, <b><br>
b)</b> Moving of existing service files from the directory
/etc/init.d to a newly created directory /etc/ausrangiert
(&quot;discarded&quot;): <b>hylafax</b>, <b>capisuite <br>
c)</b> In case <b>selinux</b> is active (as per default in
fedora), it impedes per default hylafax; in this case, a
module for selinux is silently arranged in order to allow
running hylafax-hfaxd. Furtheron, up to the possible
construction of a better fitting solution, the domain
&rsquo;getty&rsquo; has to be deactivated with the command
&rsquo;<b>semanage permissive -a getty_t</b>&rsquo; in order
to be able to receive faxes.</p>

<p style="margin-left:11%; margin-top: 1em"><b>7)</b>
Creation of a logfile, per default
<b>/var/log/&quot;neuserver&quot;.log</b>.</p>

<p style="margin-left:11%; margin-top: 1em"><b>8)</b> if
necessary creation and making accessible of the configurable
<b>directories</b> for faxes to be sent, waiting, finished
and failed.</p>

<p style="margin-left:11%; margin-top: 1em"><b>9)</b> if
necessary creation and making accessible of the
configuration file <b>&quot;neuserver&quot;.conf</b> in the
same directory where the program is located by itsself
(default: <b>/usr/local/sbin/&quot;neuserver&quot;</b>).</p>

<p style="margin-left:11%; margin-top: 1em"><b>10)</b>
Insertion of a line for the periodic automatic program call
in root&rsquo;s crontab</p>

<p style="margin-left:11%; margin-top: 1em"><b>11)</b> if
necessary insertion of sections for the directories
mentioned under 8) in /etc/samba/smb.conf, if necessary
insertion of the program user or (if root) the user chosen
for the capisuite as samba user. In case a Suse firewall is
present, allow samba-server for &quot;external zone&quot;.
After calling &quot;neuserver&quot;, the directories
mentioned in 8) should be readable via samba within a local
network and the directory for faxes to be sent should also
be writable.</p>

<p style="margin-left:11%; margin-top: 1em"><b>12)</b> if
necessary insertion of a database in mariadb with a
configurable name, creation and modification of several
tables and a procedure in this database, if necessary
insertion of a user with a configurable name in mariadb for
the management of those tables.</p>

<p style="margin-left:11%; margin-top: 1em"><b>13)</b> With
specific command line options for &quot;neuserver&quot;,
faxes can be deleted, especially: <b><br>
a)</b> in hylafax by callinng &rsquo;faxrm&rsquo; <b><br>
b)</b> in capisuite: by deleting files like
/var/spool/capisuite/users/&lt;user&gt;/sendq/*.txt und
~/*.sff. In capisuite, an orphaned lock file
(/var/spool/capisuite/users/&lt;user&gt;/sendq/*.lock) can
be deleted, too.</p>

<p style="margin-left:11%; margin-top: 1em"><b>14)</b> With
a specific command line option for &quot;neuserver&quot;, an
old received fax can be converted to a pdf-File again.</p>

<h2>UNINSTALLING
<a name="UNINSTALLING_D"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Change in a
terminal to the installation directory (for the same
installed user, it&rsquo;s <b>cd
~/&quot;neuserver&quot;</b>, otherwise it will be displayed
by <b>&quot;neuserver&quot; -info</b>). <br>
Call <b>make uninstall</b>. <br>
Then the installed <b>&quot;neuserver&quot;</b> will be
deleted and the script <b>uninstallinv</b> will be executed
in reverse order which has been generated during the
installation and execution of &quot;neuserver&quot;. <br>
Thereby additionally installed program packets, permissions,
samba shares and firewall exceptions are deleted. <br>
Configuration files, data, and system relevant programs like
libgcc and selinux will not be deleted. <br>
Error messages originate mostly in efforts to delete a
program already missing and can then be ignored.</p>

<h2>RETURN CODES
<a name="RETURN CODES_D"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em"><b>0</b>:
Normal return code <b><br>
7</b>: The info screen (<b>&quot;neuserver&quot; -info</b>)
has been displayed <b><br>
8</b>: The help has been displayed <b><br>
9</b>: To start the just installed capi module the computer
has to be restarted <b><br>
10</b>: Initializing of the database failed and the program
was stopped therefore <b><br>
11</b>: Checking of a database table failed and the program
was stopped therefore <b><br>
17</b>: Fork to another thread failed <b><br>
98</b>: Program stopped because it is already running once
<b><br>
99</b>: A search command at a link failed while using
<b>&quot;neuserver&quot; -fd 2 <br>
113</b>: An sql command for the mariadb database failed with
a miscellaneous error <b><br>
115</b>: A database entry failed because of a full disk <br>
After calling <b>&quot;neuserver&quot; -vi</b> or
<b>&quot;neuserver&quot; -vs</b> the return code of
<b>vi</b>/<b>vim</b> will be passed</p>

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
- FaxServer-Funktionalit&auml;t</b>: veranlasst
automatischen Faxversand von Dateien, Benennung empfangener
Faxe und Protokollierung aller Faxe in einer Datenbank <br>
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
bietet quasi die Funktionalit&auml;t eines Faxservers,
welcher f&uuml;r manche auch hinter einer schnellen
Datenleitung sinnvoll sein kann. <b><br>
&quot;neuserver&quot;</b> ist ein Befehlszeilenprogramm, mit
dem Dateien in einem bestimmten Verzeichnis automatisch an
<b>hylafax</b> (falls ein linux-kompatibles Fax-Modem
angeschlossen ist) und/oder <b>capisuite</b> (falls eine
Fritzcard 2.0 oder 2.1 angeschlossen ist) weiterleitet
werden, wenn die Faxnummer im Dateinamen wie vorgesehen
eingetragen ist, und das weiterhin die versandten Faxe in
einer MariaDB-Datenbank abspeichert. <br>
Au&szlig;erdem k&ouml;nnen von
<b>hylafax</b>/<b>capisuite</b> empfangene Faxe automatisch
nach dem Sender anhand dessen Faxnummer benannt und
abgespeichert werden. <br>
Die Netzwerkintegration (z.B. auch in ein Windows-Netzwerk
mit nur einem Linuxrechner) geschieht durch automatischen
Eintrag der f&uuml;r &quot;neuserver&quot; relevanten
Verzeichnisse in einen Samba-Server. Sie k&ouml;nnte
erg&auml;nzt werden durch eine Maske f&uuml;r die
mariadb-Datenbank.</p>

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
&quot;neuserver&quot;</b> <br>
und beantworten einige Rueckfragen des Programms. <br>
Der erste Programmaufruf und die erste Faxverarbeitung eines
gesandten/empfangenen Faxes mit Hylafax/Capsiuite
k&ouml;nnen jeweils etwas dauern und ein paar
zus&auml;tzliche Eingaben erfordern. <br>
&quot;neuserver&quot; -erneut f&uuml;r jedes von Ihnen.
Hierdurch wird gleichzeitig die notwendige
Programminstallation f&uuml;r k&uuml;nftige Faxe
vervollst&auml;ndigt.</p>

<h2>GEBRAUCH
<a name="GEBRAUCH_D"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Im Idealfall
sollte sich das Programm nach dem/n erstem/n Aufruf/en
(s.o.) und Beantworten einmaliger R&uuml;ckfragen so
eingerichtet haben, dass es von selbst weiter
l&auml;uft. <br>
Es existiert dann ein Verzeichnis z.B.
&rsquo;<b>zufaxen</b>&rsquo;, in das z.B. Benutzer im
Netzwerk (z.B. &uuml;ber die o.g. Samba-Freigabe) zu
faxende Dateien stellen k&ouml;nnen wie z.B. <br>
&quot;<b>Arztbericht zu Franz Krank an Dr. Gesund und Franz
Krank an Fax 099 987654321 und 088 887654321.doc</b>&quot;
(es k&ouml;nnte auch z.B. eine *.xls, eine *.jpg, eine
*.tif, eine *.txt oder eine *.pdf-Datei sein; die Passage
&rsquo;an Dr. Gesund und Franz Krank &rsquo; ist optional
f&uuml;r die sp&auml;tere Zordnung der Faxnummer(n)
in der Datenbank, sie darf auch fehlen; auf der anderen
Seite darf f&uuml;r den Fall, dass das Programm die
letzten (1-)3 Faxe zu einem Adressaten eindeutig einer
Faxnummer zuordnen kann, die Passage &rsquo; an Fax 099
987654321 und 088 887654321&rsquo; auch fehlen). <br>
Wenn <b>&quot;neuserver&quot;</b> beim n&auml;chsten Mal
automatisch aufgerufen wird
(standardm&auml;&szlig;ig alle 2 Minuten), wird die
o.g. Beispieldatei zun&auml;chst kopiert und umbenannt
in <br>
&quot;<b>Arztbericht zu Franz Krank an Dr. Gesund an Fax 099
987654321.doc</b>&quot; und <br>
&quot;<b>Arztbericht zu Franz Krank an Franz Krank an Fax
088 887654321.doc</b>&quot; und in die PDF-Dateien <br>
&quot;<b>Arztbericht zu Franz Krank an Dr. Gesund an Fax 099
987654321.pdf</b>&quot; und <br>
&quot;<b>Arztbericht zu Franz Krank an Franz Krank an Fax
088 887654321.pdf</b>&quot; umgewandelt. <br>
Diese werden dann automatisch an <b>hylafax</b> oder
<b>Capisuite</b> weitergeleitet und von dort aus verschickt.
<br>
Gleichzeitig werden sie aus &rsquo;<b>zufaxen</b>&rsquo; in
das Warteverzeichnis, z.B. &rsquo;<b>warteauffax</b>&rsquo;
verschoben und in die Spooltabelle <b>spooltab</b>
eingetragen. <br>
Gibt es in &rsquo;<b>zufaxenfR&rsquo; Unterverzeichnisse,
deren Namen aus einem Datum oder Uhrzeit bestehen (z.B.
&rsquo;20180101 0800</b>&rsquo; oder
&rsquo;<b>2200</b>&rsquo;), so werden darin enthaltene Faxe
erst nach diesem Zeitpunkt verarbeitet und im ersteren Fall
das Unterverzeichnis nach Leerung geloescht. <br>
Bei jedem Aufruf &uuml;berpr&uuml;ft
&quot;neuserver&quot; den Status von <b>hylafax</b> und/oder
<b>Capisuite</b>. Der Abschluss eines Faxvorgangs dort hat
zur Folge, dass &quot;neuserver&quot; die Quelldateien (also
hier die o.g. .doc- und .pdf-Dateien) aus dem
Warteverzeichnis in ein oder mehrere alternative
Archivverzeichnisse oder ein Verzeichnis f&uuml;r
gescheiteterte Faxe ablegt und den Datenbankeintrag von
&rsquo;<b>spooltab</b>&rsquo; in die Archivtabelle
&rsquo;<b>outa</b>&rsquo; verschiebt. <br>
Weiterhin werden &uuml;ber <b>hylafax</b> oder
<b>Capisuite</b> angekommene Faxe in ein Empfangsverzeichnis
kopiert und ggf. nach dem Sender benannt. Hierzu werden,
falls angegeben, konfigurierbare SQL-Befehle verwendet, die
in frei festlegbarer Zahl der Reihe nach so lange aufgerufen
werden, bis einer einen Datensatz zu der Faxnummer findet.
<br>
Der Benutzer k&ouml;nnte also je nach Betriebssystem,
Zugriffsm&ouml;glichkeit und Pr&auml;ferenz in den
genannten Verzeichnissen, in den Datenbanktabellen oder
durch Aufruf von z.B.
&rsquo;<b>&quot;neuserver&quot;&rsquo;,
&rsquo;&quot;neuserver&quot; -lista</b>&rsquo;,
&rsquo;<b>&quot;neuserver&quot; -listf</b>&rsquo; oder
&rsquo;<b>&quot;neuserver&quot; -listi</b>&rsquo; den Stand
des Faxens &uuml;berpr&uuml;fen.</p>

<h2>OPTIONEN
<a name="OPTIONEN_D"></a>
</h2>



<p style="margin-left:11%; margin-top: 1em">&rsquo;<b>&quot;neuserver&quot;
-?</b>&rsquo; oder &rsquo;<b>&quot;neuserver&quot;
-h</b>&rsquo; zeigt die wichtigen Befehlszeilenoptionen und
&rsquo;<b>&quot;neuserver&quot; -lh</b>&rsquo; alle. Einige
Optionen (z.B. die SQL-Befehle zur Suche eines Adressaten
aus der Faxnummer) k&ouml;nnen nicht &uuml;ber die
Befehlszeile, sondern nur &uuml;ber die
Konfigurationsdatei eingegeben werden, die wiederum
&uuml;ber &rsquo;<b>&quot;neuserver&quot; -vi</b>&rsquo;
direkt editiert oder auch &uuml;ber
&rsquo;<b>&quot;neuserver&quot; -rf</b>&rsquo; interaktiv
gepflegt werden kann.</p>

<h2>FUNKTIONSWEISE
<a name="FUNKTIONSWEISE_D"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Beim Aufruf von
&rsquo;<b>&quot;neuserver&quot;</b>&rsquo; geschieht
folgendes:</p>

<p style="margin-left:11%; margin-top: 1em"><b>1)</b> Die
aktuelle Hardware wird &uuml;berpr&uuml;ft: <b><br>
a)</b> mit dem Befehl &rsquo;<b>lspci | grep -i
isdn</b>&rsquo; bez&uuml;glich einer ISDN-Karte <b><br>
b)</b> mit dem Befehl &rsquo;<b>stty -F</b>&rsquo;
bez&uuml;glich eines Fax-Modems.</p>

<p style="margin-left:11%; margin-top: 1em"><b>2)</b> Die
Fax-Konfigurationsdatei <b>fax.conf</b> der Capisuite wird
eingelesen, falls es sie gibt</p>

<p style="margin-left:11%; margin-top: 1em"><b>3)</b>
Weitere Vorgaben aus dem Programmcode werden zugewiesen, die
durch die &quot;neuserver&quot;-Konfigurationsdatei (siehe
4), Kommandozeilenargumente oder Antworten auf
R&uuml;ckfragen (siehe 5) &uuml;berdeckt werden
k&ouml;nnen.</p>

<p style="margin-left:11%; margin-top: 1em"><b>4)</b>
Vorgaben werden geladen aus der Konfigurationsdatei, falls
existent (standardm&auml;&szlig;ig
<b>&quot;neuserver&quot;.conf</b> im selben Verzeichnis wie
<b>&quot;neuserver&quot;</b>,
standardm&auml;&szlig;ig
<b>/usr/local/sbin/&quot;neuserver&quot;</b>))</p>

<p style="margin-left:11%; margin-top: 1em"><b>5)</b>
R&uuml;ckfragen werden gestellt, falls in der
Konfigurationsdatei Werte fehlen oder falls eine
Kommandozeilenoption Interaktivit&auml;t verlangt.</p>

<p style="margin-left:11%; margin-top: 1em"><b>6)</b> Das
Verzeichnis von <b>hylafax</b> wird ermittelt
(<b>/var/spool/hylafax</b> oder <b>/var/spool/fax</b>),
falls hylafax installiert ist.</p>

<p style="margin-left:11%; margin-top: 1em"><b>7)</b> Von
Benutzern verwendete Verzeichnisse f&uuml;r zu
verschickende, wartende, versandte und gescheiterte und
empfangene Fax-Dateien werden &uuml;berpr&uuml;ft
und ggf. erstellt. Dabei k&ouml;nnen in der
Konfiguration angegebene Dateinamensmuster
ber&uuml;cksichtigt werden, um erfolgreich versandte
Faxe je nach Dateinamen in verschiedenen Verzeichnissen zu
speichern.</p>

<p style="margin-left:11%; margin-top: 1em"><b>8)</b> Das
Programm tr&auml;gt sich ggf. in <b>crontab</b> (des
Benutzers root) ein, um auf Wunsch in (einstellbaren)
Abst&auml;nden aufgerufen zu werden. Um dies zu
verhindern, kann entweder &rsquo;<b>cronminut</b>&rsquo; auf
<b>0</b> eingestellt werden oder die bereits erstellten
&quot;neuserver&quot;-Eintr&auml;ge mit <b>crontab
-e</b> mit einem vorangestellten &rsquo;<b>#</b>&rsquo;
auskommentiert werden.</p>

<p style="margin-left:11%; margin-top: 1em"><b>9)</b> Das
Programm &uuml;berpr&uuml;ft, ob alle
benutzerreleventen Verzeichnisse (s. 7) von Sambafreigaben
in <b>/etc/samba/smb.conf</b> erfasst werden, solche werden
n&ouml;tigenfalls erg&auml;nzt.</p>

<p style="margin-left:11%; margin-top: 1em"><b>10)</b> Der
Betrieb von MariaDB wird &uuml;berpr&uuml;ft, ggf.
wird es (installiert und) in Betrieb gesetzt, die
Datenbanktabellen <b>spooltab</b> (f&uuml;r gerade
laufende Faxe), <b>outa</b> (f&uuml;r gesandte und
gescheiterte Faxe) und <b>inca</b> (f&uuml;r angekommene
Faxe) werden &uuml;berpr&uuml;ft und ggf. erstellt
oder erweitert.</p>

<p style="margin-left:11%; margin-top: 1em"><b>11)</b> Im
Fall der entsprechenden Kommandozeilenoptionen werden
Korrekturen bei Dateien im Warteverzeichnis oder den
Protokolltabellen durchgef&uuml;hrt oder deren Inhalt
aufgelistet und das Programm dann beendet.</p>

<p style="margin-left:11%; margin-top: 1em"><b>12)</b>
Andernfalls werden Dateien im <b>Zufaxenverzeichnis</b>
analysiert. Jede Datei, deren im Dateinamen enthaltene
Faxnummer(n) ermittelbar ist/sind und die in eine PDF-Datei
umwandelbar ist (oder schon so vorliegt), wird ins
Warteverzeichnis verschoben und in <b>spooltab</b>
eingetragen. <br>
Falls eine Datei mehrere Faxnummern enth&auml;lt
und/oder eine PDF-Umwandlung n&ouml;tig ist, werden
zus&auml;tzliche Dateien erstellt und die
urspr&uuml;ngliche Datei ggf. umbenannt. Falls
n&ouml;tig, k&ouml;nnen die Dateien
zus&auml;tzliche Zifferm nahe ihrem Namensende bekommen,
so dass die Namen mit keinem anderen der unter 7) genannten
Verzeichnisse in Konflikt steht. <br>
Falls neue Dateien erstellt wurden, werden die nachfolgenden
Verschiebungen und Protokollierungen mit allen
durchgef&uuml;hrt.</p>

<p style="margin-left:11%; margin-top: 1em"><b>13)</b> Je
nach Konfiguration wird die Funktionsf&auml;higkeit von
<b>hylafax</b> und/oder <b>capisuite</b>
&uuml;berpr&uuml;ft und ggf. nach
M&ouml;glichkeit hergestellt (falls n&ouml;tig und
m&ouml;glich auch mit Installation dieser Programme;
f&uuml;r eine Fritzcard 2.0 sowie f&uuml;r ein
Faxmodem USR5637 kann/wird auch eine automatische
Konfiguration erfolgen). Kernelmodule f&uuml;r hylafax
bzw. capisuite werden f&uuml;r die aktuelle
Kernelversion erstellt, auch bei etwaigen Kernelupdates.</p>

<p style="margin-left:11%; margin-top: 1em"><b>14)</b> Im
Fall entsprechender Kommandozeilenoptionen werden Faxe
gel&ouml;scht und das Programm dann beendet.</p>

<p style="margin-left:11%; margin-top: 1em"><b>15)</b>
Andernfalls werden die unter 12) in <b>spooltab</b>
eingetragenen Dateien an <b>hylafax</b> oder
<b>capisuite</b> weitergeleitet und dies in <b>spooltab</b>
protokolliert.</p>

<p style="margin-left:11%; margin-top: 1em"><b>16)</b> Alle
in <b>spooltab</b> als wartend stehenden Faxe werden in
<b>hylafax</b>/<b>capisuite</b> auf ihren Status
&uuml;berpr&uuml;ft, dieser wird in <b>spooltab</b>
aktualisiert (Zahl der bisherigen Faxversuche). <br>
Falls sowohl hylafax als auch capisuite aktiv sind und eine
voreingestellte Zahl an Anwahlversuchen im Programm der
ersten Pr&auml;ferenz dieser beiden erfolglos erreicht
ist, wird das Fax auch noch an das jeweils andere Programm
weitergeleiet. <br>
Falls der Faxvorgang (erfolgreich oder erfolglos) beendet
ist, wird die Datei aus dem Warteverzeichnis in die
Verzeichnisse f&uuml;r fertige bzw. gescheiterte Faxe
verschoben, optional mit ocrmypdf einer Texterkennung
unterzogen (falls ein ausreichend junges Python3 &gt; 3.5
installiert ist), und der Datenbankeintrag aus
<b>spooltab</b> in die Tabelle <b>outa</b> verschoben. <br>
Der Status der genannten Faxe wird angezeigt.</p>

<p style="margin-left:11%; margin-top: 1em"><b>17)</b>
Weitere in der Warteschleife von hylafax/capisuite
befindliche, nicht &uuml;ber &quot;neuserver&quot;
erstellte Faxe werden ggf. angezeigt. In Intervallen werden
sie in die &quot;neuserver&quot;-Datenbank integriert (ohne
die fehlende Information &uuml;ber den
urspr&uuml;nglichen Dateinamen)</p>

<p style="margin-left:11%; margin-top: 1em"><b>18)</b>
&Uuml;ber <b>hylafax</b>/<b>capisuite</b> empfangene
Faxe werden ggf. mit Hilfe der Faxnummer anhand
voreingestellter SQL-Befehle nach dem Namen des Absenders
benannt und in ein Empfangsverzeichnis gestellt. <br>
Solche SQL-Befehle sollen (mindestens) zwei Ergebnisfelder
(mit benutzerdefinierter Bedeutung) liefern, deren Inhalt
dann, durch ein Komma getrennt, von &quot;neuserver&quot;
zur Benennung eines empfangenen Faxes verwendet werden. Vor
der Anwendung des SQL-Befehls wird die Zeichenfolge
&rsquo;&&faxnr&&&rsquo; zur aktuellen
Faxnummer erweitert. Beispiel fuer einen solchen SQL-Befehl:
<i><br>
select concat(haname,&rsquo;, &rsquo;,ort,&rsquo;,
&rsquo;,kvnu) name, zulg from kvaerzte.hae where
concat(if(mid(fax1k,1,1)=&rsquo;0&rsquo;,&rsquo;&rsquo;,&rsquo;08131&rsquo;),
replace(replace(replace(replace(fax1k,&rsquo;
&rsquo;,&rsquo;&rsquo;),&rsquo;-&rsquo;,&rsquo;&rsquo;),&rsquo;/&rsquo;,&rsquo;&rsquo;),&rsquo;&acute;&rsquo;,&rsquo;&rsquo;))
= &rsquo;&&faxnr&&&rsquo;</i> <br>
Wenn mehrere SQL-Befehle angegeben werden, so wird der
jeweils naechste angewandt, wenn einer kein Ergebnis
liefert. <br>
Optional werden die empfangenen Dateien mit Hilfe von
<b>ocrmypdf</b> einer Texterkennung unterzogen.</p>

<p style="margin-left:11%; margin-top: 1em"><b>19)</b> Die
Konfigurationsdatei <b>&quot;neuserver&quot;.conf</b> wird
ggf. geschrieben.</p>

<p style="margin-left:11%; margin-top: 1em"><b>20)</b> Wenn
die Option <b>-autoakt</b> bzw. <b>--autoaktual</b> aktiv
ist, wird zuletzt bei jedem zweiten Aufruf jedes Tages die
Versionsummer von <b>&quot;neuserver&quot;</b> mit der der
Installationsquelle verglichen und im Fall eines
R&uuml;ckstands eine Aktualisierung
durchgef&uuml;hrt</p>

<p style="margin-left:11%; margin-top: 1em">Einige
Programmteile laufen parallel, dies kann sich die
Reihenfolge der Ergebnisanzeige auflockern. <br>
Senden und Empfangen wiederholen sich ggf.
min&uuml;tlich, bis der jeweils andere Teil zum ersten
Mal fertig ist. <br>
&Uuml;berpr&uuml;fung und ggf. Korrektur evtl.
falsch abgelegter Fax-Dateien (z.B. infolge eines
willk&uuml;rlichen Programmabbruchs von au&szlig;en)
werden in Abst&auml;nden durchgef&uuml;hrt.</p>

<h2>VORAUSSETZUNGEN
<a name="VORAUSSETZUNGEN_D"></a>
</h2>



<p style="margin-left:11%; margin-top: 1em"><b>Hardware</b>:
Computer mit einer Fritzcard 2.0 oder 2.1 und/oder einem
linux-kompatiblen Modem; in der vorliegenden Fassung wird
f&uuml;r eine automatische Installation des Programms
(unter Beantwortung einiger R&uuml;ckfragen) ein US
Robotics Modem USR5637 und eine der untenstehenden
Linuxversionen ben&ouml;tigt. Im Fall der Verwendung von
Fritzcard plus einem Modem kann das Programm beide Faxwege
alternativ nutzen, um die &Uuml;bertragungssicherheit zu
erh&ouml;hen. <b><br>
Software</b>: Das Programm wurde auf eine Installation von
Opensuse &gt;= 42.1, Debian &gt;= 9.10, Ubuntu &gt;= 16.04,
Mint &gt;= 18 oder Fedora &gt;= 24 mit jeweils
Standardoptionen abgestimmt. System D muss installiert sein
bzw. systemctl muss laufen, was in den genannten
Programmversionen der Fall ist. Jeweils einer der
Paketmanager rpm oder dpkg sowie apt, dnf, yum oder zypper
muss installiert sein, wie in den genannten
Linuxdistributionen standardm&auml;&szlig;ig der
Fall. Das Programm &rsquo;<b>wget</b>&rsquo; wird
vorausgesetzt. Die Deinstallation der durch
&quot;neuserver&quot; hinzugef&uuml;gten Programme mit
<b>make uninstall</b> ist gegenw&auml;rtig nur
f&uuml;r englische und deutsche Versionen der
Paketmanager eingerichtet.</p>

<h2>AUTOMATISCH INSTALLIERTE PROGRAMMPAKETE
<a name="AUTOMATISCH INSTALLIERTE PROGRAMMPAKETE_D"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">(hierzu wird je
nach Distribution zypper, apt(-get), dnf oder yum
verwendet).</p>


<p style="margin-left:11%; margin-top: 1em"><b>makefile:</b>
<br>
gcc V.6, g++ V.6, groff, libmysqlclient-dev(el),
libtiff-dev(el) (im Fall von Vers. 4.0.7 mit leichter
Modifikation, s. Makefile)</p>


<p style="margin-left:11%; margin-top: 1em"><b>&quot;neuserver&quot;:</b>
<br>
acl, boost, boost-devel, boost-iostreams-devel,
boost-local-devel, cron, ghostscript, imagemagick,
libreoffice-common, libreoffice-base, mariadb-server,
policycoreutils, policycoreutils-python-utils,
poppler-tools, samba, sfftobmp, (in debian-derivates,
f&uuml;r mariadb, zus&auml;tzlich:
apt-transport-https)</p>

<p style="margin-left:11%; margin-top: 1em"><i>falls</i>
<b>capisuite</b> <i>benutzt werden soll</i>: <br>
capisuite, capiutils, capi4linux, fcpci-3.10.0, gcc-4.8,
g++-4.8, kernel-source (linux-source), libcapi20-2,
libcapi20-3, libxslt-tools, linux-headers-$(uname -r),
python-devel, (in fedora, zus&auml;tzlich:
kernel-modules-extra),</p>

<p style="margin-left:11%; margin-top: 1em"><i>falls</i>
<b>hylafax</b> <i>benutzt werden soll</i>: <br>
hylafax+, hylafax+-client, sendmail, tiff (im Fall von Vers.
4.0.7 mit kleiner Modifikation, s. Makefile)</p>

<p style="margin-left:11%; margin-top: 1em"><i>falls</i>
<b>ocr</b> <i>benutzt werden soll</i>: <br>
ffmpeg, ffmpeg-devel, ffmpeg-compat, gcc, libavformat-devel,
libffi-devel, ocrmypdf, python3-devel, python3-pip,
python3-setuptools, rpmfusion, qpdf, redhat-rpm-config,
tesseract-ocr, unpaper, and via &rsquo;python3 pip&rsquo;:
cryptography, cffi, image, M2Crypto, ocrmypdf, PyPDF2,
reportlab, ruffus.</p>

<p style="margin-left:11%; margin-top: 1em"><i>falls Sie
die Quelldateien mit &rsquo;sh viall&rsquo; bearbeiten
wollen</i>: <br>
vim</p>

<p style="margin-left:11%; margin-top: 1em">All diese
Installationen k&ouml;nnen abh&auml;ngige Programme
einschlie&szlig;en. <br>
Falls Sie eines dieser Programme nicht wollen bzw. nicht
aktualisieren wollen, dann d&uuml;rfen Sie
&quot;neuserver&quot; oder die entsprechenden Programmteile
nicht auf diesem Computer verwenden.</p>

<h2>AUSWIRKUNGEN DES PROGRAMMABLAUFS
<a name="AUSWIRKUNGEN DES PROGRAMMABLAUFS_D"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Das Programm
muss zum ordentlichen Funktionieren folgende
Ma&szlig;nahmen ergreifen:</p>

<p style="margin-left:11%; margin-top: 1em"><b>1)</b> In
Debian kann in der Datei /etc/apt/sources.list ein
DVD-Eintrag hinter die Standard-Online-Repositories
verschoben werden. <b><br>
2)</b> Sudo (fehlt anfangs bei Standardinstallation in
Debian) wird ggf. installiert. <br>
Der Benutzer beim Installationsvorgang wird, falls nicht
schon enthalten, in eine Administrator-Gruppe eingetragen,
die in /etc/sudoers genannt wird, da er &quot;sudo&quot;
ausf&uuml;hren mu&szlig;.</p>

<p style="margin-left:11%; margin-top: 1em"><b>3)</b>
&rsquo;GNU make&rsquo; wird, falls nicht vorhanden, durch
Aufruf von &rsquo;sh ./install.sh&rsquo; bzw.
&rsquo;configure&rsquo; automatisch installiert.</p>

<p style="margin-left:11%; margin-top: 1em"><b>4)</b>
Installieren von <b>Hylafax+</b>, falls ein Modem
angeschlossen ist und Hylafax+ nicht installiert ist. Ggf.
Konfiguration von Hylafax+ durch Aufruf von
&rsquo;<b>faxsetup -nointeracitve</b>&rsquo;, durch
Editieren der Konfigurationsdateien <b>config</b> und
<b>config.*</b> (z.B. <b>config.ttyACM0</b>) im
hylafax-Konfigurationsverzeichnis (Vorgabe z.B.:
<b>/var/spool/hylafax/etc/</b>)</p>

<p style="margin-left:11%; margin-top: 1em"><b>5)</b>
Installieren von <b>capisuite</b>, falls eine Fritzkarte
eingebaut ist und capisuite nicht installiert ist. Ggf.
Bearbeitung der Konfigurationsdateien
<b>/etc/capisuite/capisuite.conf</b> und
<b>/etc/capisuite/fax.conf</b>. Ggf. Bearbeitung des
Python-Scripts f&uuml;r ankommende Faxe (Vorgabe z.B.:
<b>/usr/lib64/capisuite/incoming.py</b>) zur Bestimmung der
Zahl der Klingelt&ouml;ne bis zur Faxannahme, Erstellung
bzw. Bearbeitung der Dateien</p>

<p style="margin-left:11%; margin-top: 1em"><b>6)</b>
Einrichten von Diensten: <b><br>
a)</b> in systemd (im Verzeichnis /usr/lib/systemd/system
oder /lib/systemd/system), insbesondere: <b><br>
hylafax-faxq.service</b>, <b>hylafax-hfaxd.service</b>,
<b>hylafax-faxgetty-....service</b> (z.B.
<b>hylafax-faxgetty-ttyACM0</b>), <br>
capisuite.service, <b><br>
b)</b> Verschieben von Diensten aus dem Verzeichnis
/etc/init.d in ein neu eingerichtes Verzeichnis
/etc/ausrangiert: <b>hylafax</b>, <b>capisuite <br>
c)</b> falls <b>selinux</b> aktiv ist (wie
standardm&auml;&szlig;ig in fedora), dann behindert
es standardm&auml;&szlig;ig <b>hylafax</b>; in
diesem Fall wird im Hintergrund ein Modul f&uuml;r
selinux eingerichtet, um den Betrieb von hylafax-hfaxd
wieder zu erlauben. Ferner muss (bis zur eventuellen
Erstellung einer ma&szlig;geschneiderteren
L&ouml;sung) die Dom&auml;ne &rsquo;getty&rsquo; mit
dem Befehl &rsquo;<b>semanage permissive -a
getty_t</b>&rsquo; in selinux entsch&auml;rft werden, um
faxe &uuml;ber hylafax empfangen zu k&ouml;nnen.</p>

<p style="margin-left:11%; margin-top: 1em"><b>7)</b>
Erstellen einer Protokolldatei,
standardm&auml;&szlig;ig
<b>/var/log/&quot;neuserver&quot;.log</b>.</p>

<p style="margin-left:11%; margin-top: 1em"><b>8)</b> ggf.
Erstellen und Zugreifbarmachen der bestimmbaren
<b>Verzeichnisse</b> f&uuml;r zu sendende, wartende,
abgearbeitete und empfangene Faxe.</p>

<p style="margin-left:11%; margin-top: 1em"><b>9)</b> ggf.
Erstellen und Ver&auml;ndern der Konfigurationsdatei
&quot;neuserver&quot;.conf in dem Verzeichnis, in dem auch
es selbst steht (Vorgabe:
/usr/local/sbin/&quot;neuserver&quot;).</p>

<p style="margin-left:11%; margin-top: 1em"><b>10)</b> ggf.
Einf&uuml;gen einer Zeile zum automatischen periodischen
Aufruf des Programms in das crontab (von root)</p>

<p style="margin-left:11%; margin-top: 1em"><b>11)</b> ggf.
Einf&uuml;gen von Abschnitten f&uuml;r die unter 8)
genannten Verzeichnisse in /etc/samba/smb.conf, ggf.
Einf&uuml;gen/Passwortzuteilen des Programmbenutzers
bzw. (falls root) des f&uuml;r die Capisuite
gew&auml;hlten Benutzers als Samba-Benutzer. Falls
Suse-Firewall vorhanden, samba-Server fuer &quot;externe
Zone&quot; eintragen. Nach Programmaufruf sollten die unter
8) genannten Verzeichnisse im Samba-Netzwerk sichtbar sein
und Dateien im Verzeichnis f&uuml;r zu sendende Faxe
erstellt werden k&ouml;nnen.</p>

<p style="margin-left:11%; margin-top: 1em"><b>12)</b> ggf.
Einf&uuml;gen einer Datenbank f&uuml;r die Faxe in
mariadb unter einem bestimmbaren Namen, Anlage und
Ver&auml;nderung mehrerer Tabellen und einer Prozedur in
dieser Datenbank, ggf. Einf&uuml;gen eines Benutzers mit
bestimmbarem Namen in mariadb zur Datenpflege in diesen
Tabellen</p>

<p style="margin-left:11%; margin-top: 1em"><b>13)</b>
durch entsprechende Befehlszeilenoptionen von
&quot;neuserver&quot; k&ouml;nnen innerhalb von hylafax
und capisuite Faxe gel&ouml;scht werden, insbesondere:
<b><br>
a)</b> in hylafax: durch Aufruf von &rsquo;faxrm&rsquo;
<b><br>
b)</b> in capisuite: durch L&ouml;schen der Dateien wie
/var/spool/capisuite/users/&lt;user&gt;/sendq/*.txt und
~/*.sff. In capisuite kann auch eine verwaiste Lock-Datei
(/var/spool/capisuite/users/&lt;user&gt;/sendq/*.lock)
gel&ouml;scht werden.</p>

<p style="margin-left:11%; margin-top: 1em"><b>14)</b> mit
einer Befehlszeilenoption kann ein fr&uuml;her
empfangenes Fax erneut in eine pdf-Datei umgewandelt
werden.</p>

<h2>DEINSTALLATION
<a name="DEINSTALLATION_D"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Wechseln Sie in
einem Terminal in das Installationsverzeichnis (beim selben
eingeloggten Benutzer: <b>cd ~/&quot;neuserver&quot;</b>,
ansonsten wird es &uuml;ber <b>&quot;neuserver&quot;
-info</b> angezeigt). <br>
Rufen Sie dort <b>make uninstall</b> auf. <br>
Dadurch wird das installierte <b>&quot;neuserver&quot;</b>
gel&ouml;scht und das Script <b>uninstallinv</b> in
umgekehrter Reihenfolge abgearbeitet, das bei der
Installation und beim Aufruf von &quot;neuserver&quot;
erstellt wurde. <br>
Dadurch werden zus&auml;tzlich installierte
Programmpakete, zus&auml;tzlich erteilte Berechtigungen,
f&uuml;r &quot;neuserver&quot; eingerichtete
Sambafreigaben und Firewallausnahmen wieder
gel&ouml;scht. <br>
Auf die Deinstallation der Konfigurationsdateien, der
angesammelten Daten und systemrelevanter Programme wie
libgcc und selinux wird dabei verzichtet. <br>
Etwaige Fehlermeldungen beziehen sich meist auf einen
Deinstallationsversuch bereits entfernter Programme und
k&ouml;nnen ignoriert werden.</p>

<h2>RUECKGABEWERTE
<a name="RUECKGABEWERTE_D"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em"><b>0</b>:
Normaler R&uuml;ckgabewert <b><br>
7</b>: Der Infobildschirm (<b>&quot;neuserver&quot;
-info</b>) wurde angezeigt <b><br>
8</b>: Die Hilfe wurde angezeigt <b><br>
9</b>: Zur Inbetriebnahme des gerade eingerichteten
Capi-Moduls muss der Rechner neu gestartet werden <b><br>
10</b>: Die Initialisierung der Datenbank scheiterte und das
Programm wurde deshalb beendet <b><br>
11</b>: Die &Uuml;berpr&uuml;fung einer
Datenbanktabelle scheiterte und das Programm wurde deshalb
beendet <b><br>
17</b>: Gabelung zu weiterem thread misslungen <b><br>
98</b>: Programmaufruf abgebrochen, da es bereits einmal
l&auml;uft <b><br>
99</b>: Suchbefehl mit <b>&quot;neuserver&quot; -fd 2</b>
bei Dateilink misslungen <b><br>
113</b>: Ein SQL-Befehl f&uuml;r die Mariadb-Datenbank
scheiterte an sonstigem Fehler <b><br>
115</b>: Eine Datenbankeintragung scheiterte an voller
Festplatte <br>
Nach Aufruf von <b>&quot;neuserver&quot; -vi</b> oder
<b>&quot;neuserver&quot; -vs</b> wird ggf. der
R&uuml;ckgabewert von <b>vi</b>/<b>vim</b>
weitergeleitet</p>

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
