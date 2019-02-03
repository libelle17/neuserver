#include "kons.h"
#include <unistd.h>
#include <fcntl.h>
#include <stdarg.h>
#include <sys/statvfs.h> // fuer statfs
#include <sys/stat.h>
#include <sys/sendfile.h> // fuer sendfile64
#include <boost/iostreams/device/mapped_file.hpp> // fuer dateivgl
//#include <typeinfo>
#include <acl/libacl.h> // fuer acl_t, acl_entry_t, acl_get_... in pruefberech()
// #include <sys/acl.h>
#define caus cout // nur zum Debuggen
extern const string& pwk; // fuer Antlitzaenderung


#ifdef _WIN32
const char *const dir = "dir ";
#elif linux
const char *const dir = "ls -l ";
#endif
const char *const tmmoegl[]={
	"%d.%m.%y %H.%M.%S","%d.%m.%Y %H.%M.%S","%d.%m.%y %H:%M:%S","%d.%m.%Y %H:%M:%S",
	"%d.%m.%y %H.%M","%d.%m.%Y %H.%M","%d.%m.%y %H:%M","%d.%m.%Y %H:%M",
	"%d.%m.%y","%d.%m.%Y","%d.%m.%y","%d.%m.%Y",
	"%m.%y","%m.%Y","%m/%y","%m/%Y",
	"%y-%m-%d %H%M%S","%Y-%m-%d %H%M%S","%y-%m-%d %H%M","%Y-%m-%d %H%M",
	"%y-%m-%d %H.%M.%S","%Y-%m-%d %H.%M.%S","%y-%m-%d %H.%M","%Y-%m-%d %H.%M",
	"%y-%m-%d %H:%M:%S","%Y-%m-%d %H:%M:%S","%y-%m-%d %H:%M","%Y-%m-%d %H:%M",
	"%y%m%d %H%M%S","%Y%m%d %H%M%S","%y%m%d %H%M","%Y%m%d %H%M",
	"%Y%m%d%H%M%S",
	"%y-%m-%d","%Y-%m-%d",
	"%y","%Y",
	"%c"
	}; // Moeglichkeiten fuer strptime
string _DPROG;
// zum Schutz statischer Speicherbereiche vor gleichzeitigem Zugriff durch mehrere Programmfaeden
pthread_mutex_t printf_mutex, getmutex, timemutex;

#ifdef linux
#include <iomanip> // setprecision, put_time
//// const char *rot="\e[1;31m", *weinrot="\e[31m", *schwarz="\e[0m", *blau="\e[34m", *gelb="\e[33m"; // muss spaeter kompilerunabhaengig 
const char *const schwarz="\e[0m", *const dgrau="\e[1;30m", *const drot="\e[0;31m", *const rot="\e[1;31m",
			*const gruen="\e[0;32m", *const hgruen="\e[1;32m", *const braun="\e[0;33m", *const gelb="\e[1;33m",
			*const dblau="\e[0;34;1;47m", *const blau="\e[1;34m", *const violett="\e[0;35m", *const hviolett="\e[1;35m",
      *const tuerkis="\e[0;36m", *const htuerkis="\e[1;36m", *const hgrau="\e[0;37m", *const weiss="\e[1;37m", *const umgek="\e[7m";
const char *_drot=drot, *_rot=rot, *_schwarz=schwarz, *_blau=blau, *_gelb=gelb, *_tuerkis=tuerkis, *_hgrau=hgrau;
//// char logdatei[PATH_MAX+1]="/DATA/down/log_termine.txt";
#define _access access
#include <sys/time.h>  // fuer gettimeofday()
#elif defined _WIN32 // linux
const char *const drot="", *const rot="", *const schwarz="", *const blau="", *const gelb="", *const tuerkis="", *const hgrau="";
////ffen: bei den Farben muss unterschieden werden zwischen cout (-> _drot) und 
printf(drot, unter windows escape-Sequenzen rausfieselen und durch SetConsoleTextAttribute-Aufrufe ersetzen)
  ////char logdatei[PATH_MAX+1]="v:\log_termine.txt";
  template <typename _Elem, typename _Traits>
  std::basic_ostream<_Elem,_Traits>& operator<<(std::basic_ostream<_Elem,_Traits>& i, color& c){
    HANDLE hStdout=GetStdHandle(STD_OUTPUT_HANDLE); 
    SetConsoleTextAttribute(hStdout,c.m_color);
    return i;
  }
////har logdatei[PATH_MAX+1]="v:\\log_termine.txt";
#endif // linux elif defined _WIN32
const boost::locale::generator gen;
const std::locale loc = gen("en_US.UTF-8");

// z.B. "/root/autofax"
const string& instvz{
#include "instvz" // wird in Makefile erstellt
};
uchar findv{3}; // find-Version 1=system, 2=intern mit readdir, 3=intern mit nftw
const string& unindt{instvz+"/uninstallinv"}; // # Name muss identisch sein mit Variabler UNF in install.sh
const string nix;
string _mpfad;
const string eins{"1"};
el2set::iterator it2;
set<elem3>::iterator it3;
const string devtty{" >/dev/tty"};
const string hcl::edit{"$(which vim 2>/dev/null || which vi) "};
			//	             view="$(which view 2>/dev/null || which vi) + ",
linst_cl* linstp{0}; // globales Objekt

TxB::TxB(const char* const* const* const *TCp):TCp(TCp)
{
}

cuscl::cuscl()
{
 cuid=getuid();
 passwd=getpwuid(cuid);
 cgid=passwd->pw_gid;
 cusstr=passwd->pw_name;
} // cuscl::cuscl()

cuscl cus; // globales Objekt
const string sudc{cus.cuid?"sudo ":string()}; // globales Objekt
// const string sudhc=(cus.cuid?"sudo -H ":string());

const string sprachstr{string("Language/Sprache/Lingue/Lingua [")+blau+'d'+schwarz+"eutsch,"+blau+'e'+schwarz+"nglisch]"+""};
const char* sprachcstr{&sprachstr.front()};

////const char *Txkonscl::TextC[T_konsMAX+1][SprachZahl]=
const char *kons_T[T_konsMAX+1][SprachZahl]=
{
  ////Ctp Txkonscl::TextC=KLA
	// T_j_af,
	{"j","y"},
  // T_pfad,
  {"pfad","path"},
  // T_kuerze_logdatei,
  {", kuerze logdatei: ",", shorten log file: "},
  // T_Logdatei,
  {"Logdatei ","Log file "},
  // T_gibt_es_noch_nicht_Kuerze_sie_daher_nicht,
  {" gibt es noch nicht. Kuerze sie daher nicht."," does not exist yet. Not shortening it therefore."},
  // T_Kann_Datei
  {"Kann Datei '","Cannot open file '"},
  //T_nicht_als_fstream_zum_Schreiben_oeffnen
  {"' nicht als fstream zum Schreiben oeffnen.","' as fstream for writing."},
  // T_nicht_als_fstream_zum_Lesen_oeffnen
  {"' nicht als fstream zum Lesen oeffnen.","' as fstream for reading."},
  // T_nicht_mit_fopen_zum_Schreiben_oeffnen 
  {"' nicht mit fopen zum Schreiben oeffnen.","' with fopen for writing."},
  // T_nicht_mit_fopen_zum_Lesen_oeffnen 
  {"' nicht mit fopen zum Lesen oeffnen.","' with fopen for reading."},
  // T_Variable_logdatei_leer
  {"Variable 'logdatei' leer!","Variable 'logdatei' empty!"},
	// T_Variable_logdatei_Verzeichnis
	{"'logdatei' ist Verzeichnis!","'logdatei' is a directory!"},
  // T_nicht_als_fstream_zum_Anhaengen_oeffnen
  {"' nicht als fstream zum Anhaengen oeffnen.","' as fstream for appending."},
	// T_nicht_mit_open_zum_Anhaengen_oeffnen
  {"' nicht mit open() zum Anhaengen oeffnen.","' with open() for appending."},
  // T_nicht_mit_fopen_zum_Anhaengen_oeffnen
  {"' nicht mit fopen zum Anhaengen oeffnen: ","' with fopen for appending."},
  // T_Bitte_mit
  {"Bitte mit '","Please exit with '"},
  // T_beenden
  {"' beenden ...","'"},
  // T_stern_zeile
//  {"*zeile: ","*line: "},
  // T_Rueckmeldung
  {"Rueckmeldung: ","Feedback: "},
  // T_Suchbefehl
  {"Suchbefehl","Search command"},
  // T_Fuehre_aus
  {"Fuehre aus","Executing"},
  // T_fehlgeschlagen_bei
  {"fehlgeschlagen bei: ","failed at: "},
  // T_Fuehrte_aus
  {"Fuehrte aus","Executed "},
  // T_komma_Ergebnis
  {", Ergebnis: ",", result: "},
  // T_kein_Verzeichnis_nochmal
  {"' kein Verzeichnis, nochmal: ","' not a directory, once again: "},
  // T_nicht_gefunden_soll_ich_es_erstellen
  {"' nicht gefunden, soll ich es erstellen (","' not found, shall I create it ("},
  // T_Fehlender_Parameter_string_zu
  {"Fehlender Parameter <string> zu -","Missing Parameter <string> after -"},
	// T_Fehlender_Parameter_Datum_zu
  {"Fehlender Parameter <datum> zu -","Missing Parameter <date> after -"},
  // T_oder
  {" oder --"," or --"},
  // T_Fehler_Parameter
  {"Fehler: Parameter -","Error: Stated Parameter -"},
  // T_ohne_gueltigen
  {"ohne gueltigen","without valid"},
  // T_mit_Datei_als
  {"mit Datei als","with file as"},
  // T_mit_falschem
  {"mit falschem","with wrong"},
  // T_Pfad_angegeben
  {" Pfad angegeben!"," path!"},
  // T_Nicht_numerischer
  {"Nicht-numerischer","Not-numeric"},
  // T_Fehlender
  {"Fehlender","Missing"},
  // T_Parameter_nr_zu
  {" Parameter <nr> zu -"," Parameter <no> after -"},
  // T_Fehler
  {"Fehler ","Error "},
  // T_Erfolg
  {"Erfolg","Success"},
  // T_Weder_zypper_noch_apt_get_noch_dnf_noch_yum_als_Installationspgrogramm_gefunden
  {"Weder zypper noch apt-get noch dnf noch yum als Installationspgramm gefunden!",
   "Neither zypper nor apt-get nor dnf nor yum found as installation programme!"},
  // T_Logdateidpp
  {"Logdatei:","Log file:"},
  // T_Lese_Konfiguration_aus
  {"Lese Konfiguration aus '","Reading configuration from '"},
  // T_j_k,
  {"j","y"},
  // T_Fehler_bei_auswert
  {"Fehler bei auwert(): ","Error at evaluate(): "},
  // T_nicht_gefunden
  {" nicht gefunden"," not found"},
  // T_Muss_Datei
  {"Muss Datei '","File '"},
  // T_fuer
  {"' fuer '","' must be made accessible for '"},
  // T_zugreifbar_machen
  {"' zugreifbar machen.","'"},
  // T_spruef_sname
  {"spruef(), sname: ","sprove(), sname: "},
  // T_lief_schon
  {" lief schon."," ran already."},
  // T_nicht_gefunden_versuche_ihn_einzurichten
  {" nicht gefunden, versuche ihn einzurichten"," not found, trying to install it"},
  // T_Aktiviere_Dienst
  {"Aktiviere Dienst: ","Activating service: "},
  // T_Program
  {"Programm '","Program '"},
  // T_laeuft_schon_einmal_seit
  {"' laeuft schon einmal seit ","' is running already once since "},
	// T_sec_Breche_ab
  {"sec. Breche ab.","sec. Aborting."},
	// T_laueft_schon_einmal_aber
	{"' laeuft schon einmal, aber","' is running already once, but"},
	// T_wird_deshalb_abgebrochen
	{"wird deshalb abgebrochen.","will be killed therefore."},
  // T_Wert
  {" Wert: "," Value: "},
  // T_Dauer
  {" Dauer: "," Duration: "},
  // T_Dienst
  {"Dienst ","Service "},
  // T_geladen
  {" geladen"," loaded"},
	// 	T_ermoeglicht
	{" ermoeglicht"," enabled"},
	// T_nicht_ermoeglicht
	{" nicht ermoeglicht"," not enabled"},
  // T_nicht_geladen
  {" nicht geladen"," not loaded"},
  // T_am
  {"' am ","' on "},
  // T_als_Dienst_eingerichtet_von
  {", als Dienst eingerichtet von '",", installed as service by '"},
  // T_Versuch
  {", Nr: ",", no.: "},
  // T_machfit
  {"machfit()","makefit()"},
  //   T_Loesche_Ausrufezeichen
  {"Loesche: ","Deleting: "},
  // T_Fehler_beim_Loeschen
  {"Fehler beim Loeschen","error deleting"},
  // T_nicht_geloescht_war_eh_nicht_mehr_da
  {" nicht geloescht, war eh nicht mehr da."," not deleted, was no more there."},
  // T_pruefpar
  {"pruefpar()","checkpar()"},
  // T_Konfiguration_fuer
  {"# Konfiguration fuer '","# Configuration for '"},
  // T_erstellt_automatisch_durch_dieses_am
  {"', erstellt automatisch durch dieses am: ","', generated automatically by itself at: "},
  // T_Fehler_bei_lstat
  {"Fehler_bei_lstat ","Error at lstat "},
  // T_Datum_nicht_gesetzt_bei
  {"Datum nicht gesetzt bei '","Date not set for '"},
  // T_Konnte_Datei
  {"Konnte Datei '","Could not open file '"},
  // T_nicht_zum_Lesen_oeffnen
  {"' nicht zum Lesen oeffen!","' for reading!"},
  // T_nicht_zum_Schreiben_oeffnen
  {"' nicht zum Schreiben oeffnen!","' for writing!"},
  // T_Zeilen
  {" Zeilen"," lines"},
	// T_oder_nicht
	{" oder nicht"," or not"},
	// T_nicht_einfuegbar
	{"nicht einfuegbar","not insertable"},
  // T_erneute_Eingabe
  {"erneute Eingabe","once more"},
	// T_obsvfeh
	{"obsvfeh()","ifsverr()"},
	// T_laeuft_jetzt
	{"laeuft jetzt","is running now"},
	// T_Dienst_inexistent
	{"Dienst inexistent","service not existant"},
	// T_Dienstdateiname_nicht_ermittelbar
	{"Dienstdateiname nicht ermittelbar","service file name not given"},
	// T_Dienst_laeuft_noch_aber_Dienstdatei_inexistent
	{"Dienst laeuft noch, aber Dienstdatei inexistent","service still runs, but service file missing"},
	// T_Exec_Dateiname_nicht_ermittelbar
	{"Exec-Dateiname nicht ermittelbar","exec-file name not given"},
	// T_Exec_Datei_fehlt
	{"Exec-Datei fehlt","exec-file missing"},
	// T_activating
	{"'activating'","'activating'"},
	// T_Dienst_kann_gestartet_werden
	{"Dienst kann gestartet werden","service can be started"},
	// T_Sonstiges
	{"Sonstiges","other"},
	// T_Ergebnis_Dienst
	{"Ergebnis Dienst ","result service "},
	// T_Dienst_laeuft
	{"Dienst laeuft","service is running"},
	// T_Dienst_disabled
	{"Dienst 'disabled'","service disabled"},
	// T_stopdis_sname
	{"stopdis(), sname: ","stopdis(), sname: "},
	// T_enableggf
	{"enableggf()","enableifnecessary()"},
	// T_semodpruef
	{"semodpruef()","checksemod()"},
	// T_Exitcode
	{"Exitcode ","Exitcode "},
	// T_trenne
	{" trenne "," splitting "},
	// T_bei
	{" bei: "," at: "},
	// T_Konnte_regulaeren_Ausdruck_nicht_kompilieren
	{"Konnte regulaeren Ausdruck nicht kompilieren: ","Could not compile regular expression: "},
	// T_doinst
	{"doinst()","doinst()"},
	// T_Ins_Deinstallationsprogramm_wird_eingetragen
	{"Ins Deinstallationsprogramm wird eingetragen: ","Entered into the uninstall program: "},
	// T_fallsnichtda
	{", fallsnichtda: ",", ifnotthere: "},
	// T_ohneabh
	{" ohneabh: "," withoutdep: "},
	// T_Tiefe
	{", Tiefe: ",", depth: "},
	// T_Linkverzeichnis
	{"Linkverzeichnis: ","link directory: "},
  // T_Suche_in
	{"Suche in '","Seeking in '"},
  // T_nach
	{"' nach '","' for '"},
	// T_Typbit
	{"', Typbit: '","', typebit: '"},
	// T_Folge
	{"', Folge: '","', follow: '"},
	// T_noext
	{"', regnoext: '","', regnoext: '"},
	// T_Ergebnis
	{"', Ergebnis: ","', result: "},
	// T_Fehler_beim_Deferenzieren_von
	{"Fehler beim Dereferenzieren von: ","Error dereferencing: "},
	// T_Ende
	{" -Ende- "," -End- "},
	// T_startundenable
	{"startundenable()","startandenable()"},
	// T_pruefberecht
	{"pruefberecht()","checkperm()"},
	// T_Datei
	{", Datei: "," file: "},
	// T_Erg
	{", erg: ",", res: "},
	// T_Benutzer
  {", Benutzer: ",", user: "},	
	// T_obunter
	{", obunter: ",", ifsub: "},
	// T_datei
	{"Datei: ","File: "},
	// T_Ergebnis_nach_make
	{"Ergebnis nach make","Result of make"},
	// T_Ergebnis_nach_make_install
	{"Ergebnis nach make install","result after make install"},
	// T_Programm,
	{"Programm: ","Program: "},
	// T_Freie_Software,
	{"Freie Software","Free Software"},
	// T_Verfasser
	{", Verfasser: ",", author: "},
	// T_Letzte_Programmaenderung
	{"Letzte Programmaenderung: ","Last modification: "},
	// T_Kompiliert
	{"Kompiliert: ","Compiled: "},
	// T_Quelle
	{"Quelle: ","Source: "},
	// T_Hilfe
	{"Hilfe: ","Help: "},
	// T_Installationsverzeichnis
	{"Installationsverzeichnis: ","Installation directory: "},
	// T_or
	{"' oder '","' or '"},
	// T_aktuelle_Einstellungen_aus
	{"Aktuelle Einstellungen aus '","Current settings from '"},
	// T_lg_k
	{"sp","lg"},
	// T_language_l
	{"sprache","language"},
	// T_lang_k
	{"lang","ling"},
	// T_lingue_l
	{"lingue","lingua"},
	// T_sprachstr
	{sprachcstr,sprachcstr},
	// T_v_k
	{"w","v"},
	// T_verbose_l,
	{"wortreich","verbose"},
	// T_lvz_k
	{"lvz","ldr"},
	// T_logvz_l
	{"logvz","logdir"},
	// T_ld_k
	{"ld","lf"},
	// T_logdname_l
	{"logdname","logfilename"},
	// T_l_k
	{"l","l"},
	// T_log_l
	{"log","log"},
	// T_ldn_k
	{"ldn","lfn"},
	// T_logdateineu_l
	{"logdateineu","logfilenew"},
	// T_kd_k
	{"kd","cf"},
	// T_konfdatei_l
	{"konfdatei","conffile"},
	// T_Bildschirmausgabe_gespraechiger
	{"Bildschirmausgabe gespraechiger","screen output more verbose"},
	// T_waehlt_als_Logverzeichnis_pfad_derzeit
	{"waehlt als Logverzeichnis <pfad>, derzeit","choses <path> as log directory, currently"},
	// T_logdatei_string_im_Pfad
	{"logdatei <string> (im Pfad '","log file <string> (in path '"},
	// T_sonst_knapper
	{"' (sonst knapper)","' (otherwise shorter)"},
	// T_wird_verwendet_anstatt
	{"') wird verwendet anstatt","') will be used instead of"},
	// T_logdatei_vorher_loeschen
	{"logdatei vorher loeschen","delete log file afore"},
	// T_verwendet_Konfigurationsdatei_string_anstatt
	{"verwendet Konfigurationsdatei <string> anstatt","uses configuration file <string> instead of"},
	// T_standardhilfe
	{"standardhilfe","standardhelp"},
	// T_libtest
	{"libtest","libtest"},
	// T_protokolliert_ausfuehrlich_in_Datei
	{"protokolliert ausfuehrlich in Datei '","put detailed logs in file '"},
	// T_sh
	{"sh","sh"},
	// T_virtlieskonfein
	{"virtlieskonfein()","virtreadconf()"},
	// T_pruefcron
	{"pruefcron()","checkcron()"},
	// T_cronzuplanen
	{", cronzuplanen: ",", crontoscedule: "},
	// T_Kein_cron_gesetzt_nicht_zu_setzen
	{"Kein cron gesetzt, nicht zu setzen","No cron set, not to set"},
	// T_wird
	{" wird "," will be called "},
	// T_unveraendert
	{"unveraendert ","as it was "},
	// T_alle
	{"alle ","every "},
	// T_Minuten
	{" Minuten"," minutes"},
	// T_gar_nicht
	{"gar nicht","not at all"},
	// T_aufgerufen
	{" aufgerufen.","."},
	// T_statt
	{" statt "," instead of "},
	// T_virtschlussanzeige
	{"virtschlussanzeige()","virtfinaldisplay()"},
	// T_Zeit_Doppelpunkt
	{"Zeit: ","Time: "},
	// T_Fertig_mit
	{"Fertig mit ","Ready with "},
	// T_eigene
	{"eigene","own"},
	// T_entfernen
	{"entfernen","remove"},
	// T_belassen
	{"belassen","keep"},
	// T_warte
	{"warte","waiting"},
	// T_wird_aktualisiert_bitte_ggf_neu_starten
	{" wird aktualisiert, bitte ggf. neu starten."," will be updated, please start it again if needed."},
	// T_muss_nicht_aktualisiert_werden
	{" muss nicht aktualisiert werden."," needs not to be updated."},
	// T_confdat_lies_Datei
	{"confdat::lies(), Datei: ","confdat::read(), file: "},
	// T_confdat_lies_Erfolg
	{"confdat::lies() Erfolg","confdat::read(), success"},
	// T_confdat_lies_Misserfolg
	{"confdat::lies() Misserfolg","confdat::read(), failure"},
	// T_pruefsamba
	{"pruefsamba()","checksamba()"},
	// T_Samba_muesste_installiert_werden_soll_ich
	{"Samba muesste installiert werden, soll ich?","samba needs to be installed, shall I?"},
	// T_Sollen_fehlende_Sambafreigaben_fuer_die_angegebenen_Verzeichnisse_ergaenzt_werden
	{"Sollen fehlende Sambafreigaben fuer die angegebenen Verzeichnisse ergaenzt werden?",
		"Shall missing samba shares for the specified directories be added?"},
	// T_Passwort_fuer_samba
	{"Passwort fuer samba ","Password for samba "},
	// T_Firewallport
	{"Firewallport ","Firewall port "},
	// T_offen
	{" offen"," open"},
	// T_zu
	{" zu"," shut"},
	// T_Soll_die_SuSEfirewall_bearbeitet_werden
	{"Soll die SuSEfirewall2 bearbeitet werden?","Shall the SuSEfirewall2 be edited?"},
	// T_Verzeichnis
	{"Verzeichnis '","Directory '"},
	// T_nicht_als_Sambafreigabe_gefunden_wird_ergaenzt_in
	{"' nicht als Sambafreigabe gefunden, wird ergaenzt in '","' not found as or under a samba share, amending it in '"},
	// T_fuer_Benutzer
	{" fuer Benutzer '"," for user '"},
	// T_prueftif
	{"prueftif()","checktif()"},
	// T_holsystemsprache
	{"holsystemsprache()","fetchingsystemlanguage()"},
	// T_hcl_hcl
	{"hcl::hcl()","hcl::hcl()"},
	// T_erfolgreich_fuer
	{": erfolgreich fuer \"",": successful for \""},
	// T_Libtiff_Version
	{"Libtiff-Version: ","libtiff version: "},
	// T_Fertig_mit_Parsen_der_Befehlszeile
	{"Fertig mit Parsen der Befehlszeile, Konfiguration zu schreiben: ","Parsing the command line finished, about to write configuration: "},
	// T_ja
	{"ja","yes"},
	// T_nein
	{"nein","no"},
	// T_Testaufruf_wegen_Programmbibliotheken
	{"Testauruf wegen Programmbibliotheken","test call for program libraries"},
	// T_Gebrauch
	{"Gebrauch: ","Usage: "},
	// T_Optionen_die_nicht_gespeichert_werden
	{"Optionen, die nicht gespeichert werden (aktueller Wert in Klammern): ","Options which are not saved (current value in parentheses): "},
	// T_Optionen_die_in_der_Konfigurationsdatei_gespeichert_werden,
	{"Optionen z.Speich. i.Konfigur'datei (vorausg. '1'=doch nicht speichern, 'no'=Gegenteil, z.B. '-noocra','-1noocri'):",
		"Options to be saved in the configuration file: (preced. '1'=don't save, 'no'=contrary, e.g. '-noocra','-1noocri'):"},
	// T_virtautokonfschreib
	{"virtautokonfschreib()","virtautoconfwrite()"},
	// T_zu_schreiben
	{"zu schreiben: ","must write: "},
	// T_rueckzufragen
	{"rueckzufragen: ","ask for options: "},
	// T_schreibe_Konfiguration
	{"schreibe Konfiguration!","writing configuration!"},
	// T_h_k
	{"h","h"},
	// T_lh_k
	{"lh","lh"},
	// T_hilfe_l
	{"hilfe","help"},
	// T_lhilfe_l
	{"langhilfe","longhelp"},
	// T_fgz_k
	{"?","?"},
	// T_fgz_l,
	{"??","??"},
	// 	T_Erklaerung_haeufiger_Optionen
	{"Erklaerung haeufiger Optionen","Explanation of frequent options"},
	// T_Erklaerung_aller_Optionen
	{"Erklaerung aller Optionen","Explanation of all options"}, 
	// T_cm_k
	{"cm","cm"},
	// T_cronminuten_l
	{"cronminuten","cronminutes"},
	// T_Alle_wieviel_Minuten_soll
	{"alle wieviel Minuten soll ","every how many minutes shall "},
	// T_aufgerufen_werden_0_ist_gar_nicht]
	{" ueber crontab aufgerufen werden (0=gar nicht), anstatt ", " be called in crontab (0=not at all), instead of "},
	// T_vi_k
	{"vi","vi"},
	// T_vi_l
	{"vi","vi"},
	// T_Konfigurationsdatei
	{"Konfigurationsdatei ","edit/view configuration file "},
	// T_Logdatei_usw_bearbeiten_sehen
	{", Logdatei usw. bearbeiten/sehen (beenden mit ':qa')",", log file etc. (finish with ':qa')"},
	// T_vs_k
	{"vs","vs"},
	// T_vs_l
	{"vs","vs"},
	// T_Quelldateien_in
	{"Quelldateien in ","edit/view source files in "},
	// T_bearbeiten_sehen
	{" bearbeiten/sehen (beenden mit ':qa')","(finish with ':qa')"},
	// T_nicht_erkannt
	{" nicht erkannt!"," not identified!"},
	// 	T_autoupd_k,
	{"autoakt","autoupd"},
	// 	T_autoupd_l,
	{"autoaktual","autoupdate"},
	// T_Programm_automatisch_aktualisieren
	{"Programm automatisch aktualisieren","Update program automatically"},
	// T_rf_k
	{"rf","ia"},
	// T_rueckfragen_l
	{"rueckfragen","interactive"},
	// T_krf_k
	{"krf","noia"},
	// T_keinerueckfragen_l
	{"keinerueckfragen","nointeraction"},
	// T_keine_Rueckfragen_zB_aus_Cron
	{"keine Rueckfragen, z.B. fuer Aufruf aus cron","no questions, e.g. for a call from within cron"},
	// T_alle_Parameter_werden_abgefragt_darunter_einige_hier_nicht_gezeigte
	{"alle Parameter werden abgefragt (darunter einige hier nicht gezeigte)","all parameters will be prompted (some of them not shown here)"},
	// T_info_k
	{"info","info"},
	// T_version_l
	{"version","version"},
	// T_Zeigt_die_Programmversion_an
	{"Zeigt die Programmversion an","shows the program version"},
	// T_zeigvers
	{"zeigvers","showvers"},
	// T_Sollen_neue_Programmversionen_von
	{"Sollen neue Programmversionen von ","Shall new versions of "},
	// T_automatisch_installiert_werden
	{" automatisch installiert werden?"," be automatically installed?"},
	// T_Logverzeichnis
	{"Logverzeichnis","log directory"},
	// T_Logdateiname
	{"Logdateiname","log file name"},
	// T_Oblog_ausf_Protok,
	{"Oblog (ausfuehrliche Protokollierung): ","Log (detailled logging): "},
	// T_Aufrufintervall
	{"; Aufrufintervall: ","; (cron) call interval: "},
	// T_kein_Aufruf
	{"kein cron-Aufruf","no cron call"},
	// T_Minute
	{" Minute"," minute"},
	// T_Logpfad,
	{"Logpfad: '","Log path: '"},
	// T_oblog,
	{"' (oblog: ","' (with logging: "},
	// T_in_main_pidv_am_Schluss
	{"in main, pidv, am Schluss","in main, pidv, at the end"},
	// T_parsecl,
	{"parsecl()","parasecl()"},
	// T_lies,
	{"lies()","read()"},
	// T_verarbeitkonf,
	{"verarbeitkonf()","processconf()"},
	// T_kauswert,
	{"kauswert()","cexploit()"},
	// T_optausg,
	{".oausgeb()",".oprintout()"},
	// T_einzutragen
	{"einzutragen: ","to enter: "},
	// T_schon_eingetragen
	{"schon eingetragen: '","already entered: '"},
	// T_wird_jetzt_eingetragen
	{"wird jetzt eingetragen: '","will now be entered: '"},
	// T_lieszaehlerein
	{"lieszaehlerein()","readingcounter()"},
	// T_Parameter
	{"Parameter: ","Parameter: "},
	// T_gefunden
	{" gefunden, "," found, "},
	// T_rueckzufragen_wegen
	{"rueckzufragen wegen ","interaction because of "},
	// T_virtlgnzuw_langu
	{"virtlgnzuw, langu: ","virtlgnassign, langu: "},
	// T_mit_w_werden_die_Einstellungen_noch_ausfuehrlicher_angezeigt
	{" (mit -w werden die Einstellungen noch ausfuehrlicher angezeigt)"," (with -v the preferences will be shown more detailled)"},
	// T_keine_Daten_zum_Anzeigen_Bearbeiten
	{"keine Dateien zum Anzeigen/Bearbeiten","no files to show/edit"},
	// T_Maximaldauer_ueberschritten,
	{"Maximaldauer ueberschritten","timeout"},
	// 	T_Fehler_in_setfaclggf,
	{"Fehler in setfaclggf: ","error in setfaclggf: "},
	// 	T_Fehler_in_find2cl
	{"Fehler in find2cl: ","error in find2cl: "},
	// T_nach_sh_viall_beendet,
	{"nach 'sh viall' beendet","exited after 'sh viall'"},
	// 	T_nach__,
	{"nach: ","after: "},
	// T_unbek,
	{"unbekannt","unkonwn"},
	// T_Progvers,
	{"Progvers von ","progvers of "},
	// T_verwendet_wird
	{", verwendet wird: '",", using: '"},
	// T_Ausgabezeile
	{", Ausgabezeile: ",", output line: "},
	// 	T_pruefmehrfach
	{"pruefmehrfach()","checkmultiple()"},
	// T_Sprachen,
	{"Sprache/Language/lingue/lingua","Sprache/Language/lingue/lingua"},
	// T_Intervall_Minuten,
	{"Intervall in Minuten fuer automatischen Programmaufruf (0=kein Aufruf)", "interval in minutes for automatic program call (0=no call)"},
	{"",""}
}; // const char *Txkonscl::TextC[T_konsMAX+1][SprachZahl]=

const int sfeh[]{ T_Dienst_laeuft,T_Dienst_inexistent, T_Dienst_disabled, T_Dienstdateiname_nicht_ermittelbar, T_Dienst_laeuft_noch_aber_Dienstdatei_inexistent, T_Exec_Dateiname_nicht_ermittelbar, T_Exec_Datei_fehlt, T_activating, T_Dienst_kann_gestartet_werden, T_Sonstiges};


/*//
Txkonscl::Txkonscl() 
{
  TCp=(const char* const * const * const *)&TextC;
}
*/
class TxB Txk((const char* const* const* const*)kons_T);
extern class TxB Tx;

////class Txkonscl Txk;

uchar nrzf{0}; // nicht rueckzufragen, fuer Aufruf aus Cron, wird auch in DB verwendet 

string zuzahl(const string& q)
{
	string z;
	uchar pz{0};
	uchar kommazupunkt{q.find(',')!=string::npos && q.find('.'==string::npos)};
	for(const char& c:q) {
		if (((c==',')&&kommazupunkt)||c=='.') {
			if (pz++) break;
			if (z.empty())
				z="0.";
			else
				z+='.';
		} else if (strchr("0123456789",c)) {
			z+=c;
	  }
	}
	if (z.empty())
		z="0";
	if (z[z.length()-1]=='.')
		z.resize(z.length()-1);
	return z;
}

argcl::argcl(const int i,const char *const *const argv):argcs(argv[i])
{
  argcs=argv[i];
}

const string drots{drot}, rots{rot}, schwarzs{schwarz}, blaus{blau}, dblaus{dblau}, gelbs{gelb}, 
			tuerkiss{tuerkis}, violetts{violett}, hvioletts{violett},gruens{gruen};

perfcl::perfcl(const string& vvonwo): vonwo(vvonwo)
{
  zp0=zp1=clock(); 
  t0=time(NULL);
} // perfcl::perfcl(const string& vvonwo): vonwo(vvonwo)

ic_cl::ic_cl(const char* nach, const char* von) 
	: ict(iconv_open((string(nach)+"//TRANSLIT").c_str(),von))
		//		: ict(iconv_open(nach,von))
{
}

ic_cl::~ic_cl() { 
	iconv_close(ict); 
}

char *ic_cl::convert(string& eing,size_t ab/*=0*/) {
	size_t eingpufgroe = eing.length()-ab;
	char* inp=(char*)eing.c_str()+ab;
	char *ergebnis=ergcont;
	if (eingpufgroe) {
		char* ergp;
		size_t erggroe,urspg;
		if (eingpufgroe<grenze) {
			erggroe=urspg=reserve;
			ergp=ergebnis=ergcont;
		} else {
			if (ergdyn) 
				delete ergdyn;
			erggroe=urspg=4*eingpufgroe;
			ergp=ergebnis=ergdyn=new char[erggroe];
		}
		if (iconv(ict, &inp, &eingpufgroe, &ergp, &erggroe)>=0) {
			ergebnis[urspg - erggroe] = 0;
		} else {
			*ergebnis=0;
		}
	} else {
		*ergebnis=0;
	}
	return ergebnis;
} // char *ic_cl::convert

ztacl::ztacl(const time_t &pzt,const char* const pfmt/*="%d.%m.%Y %H.%M.%S"*/):zt(pzt),fmt(pfmt)
{ 
}
// ztacl::ztacl(tm *const tm,const char* const pfmt/*="%d.%m.%Y %H.%M.%S %z %Z"*/):zt(mktime(tm)),fmt(pfmt) { }
ztacl::ztacl(const tm *const tm,const char* const pfmt/*="%d.%m.%Y %H.%M.%S %z %Z"*/):tmloc(*tm),zt(mktime(&tmloc)),fmt(pfmt)
{
}
ostream &ztacl::operator()(std::ostream& out) const {
	pthread_mutex_lock(&timemutex);
	out<<put_time(localtime(&zt),fmt);
	pthread_mutex_unlock(&timemutex);
	return out;
}

ostream &operator<<(ostream &out,ztacl ztaus) {
	return ztaus(out);
}

void perfcl::ausgeb(const string& stelle,uchar obdauer)
{
  zp1alt=zp1;
  zp1=clock();
  t1=time(NULL);
  cout<<gruen;
  if (!vonwo.empty())
   cout<<vonwo<<Txk[T_Versuch]<<setw(4)<<++nr<<", "<<setw(22)<<stelle<<": ";
  cout<<Txk[T_Dauer]<<setprecision(7)<<setw(9)<<(long)(zp1-zp0)<<" clocks = "
    <<fixed<<(t1-t0)<<setprecision(0)<<" s, "
    "delta= "<<setprecision(7)<<setw(9)<<(long)(zp1-zp1alt)<<" clocks"<<fixed<<schwarz<<(obdauer?"\n":"\r");cout.flush();
} // void perfcl::ausgeb(const string& stelle)


void perfcl::ausgab1000(const string& stelle)
{
  zp1=clock();
  nr++;
  if (zp1-zp0>10000) {
    cout<<gruen<<vonwo<<" "<<stelle<<" "<<nr<<Txk[T_Dauer]<<setprecision(7)<<setw(9)<<(long)(zp1-zp0)<<" = "
      <<fixed<<((zp1-zp0)/CLOCKS_PER_SEC)<<schwarz<<setprecision(0)<<" s"<<endl;
    exit(schluss(102,Txk[T_Maximaldauer_ueberschritten]));
  } //   if (zp1-zp0>10000)
} // void perfcl::ausgab1000(const string& stelle)

int perfcl::oberreicht(unsigned long sek)
{
 zp1=clock();
////<<"zp1-zp0: "<<(zp1-zp0)<<", sek: "<<(long)(sek*CLOCKS_PER_SEC)*0.1<<endl;
 return ((zp1-zp0)>(long)sek*CLOCKS_PER_SEC*0.1);
} // int perfcl::oberreicht(unsigned long sek)


string ersetzefuerdatei(const string& u) 
{
  string ziel{u};
  ersetzAlle(&ziel,"*","");
  ersetzAlle(&ziel,":",".");
  return ziel;
} // string ersetzefuerdatei(const string& u) 

char* charersetze(char *u, const char alt, const char neu) 
{
  for(size_t i=0;i<strlen(u);i++)
    if (u[i]==alt) 
      u[i]=neu;
  return u;
} // charersetze(char *u, const char* alt, const char* neu)

/*//
// macht Speicherfehler
wstring ersetze(const wstring& u, const wchar_t* alt, const wchar_t* neu) 
{
wstring erg=L"";
if (alt[0]==0 || !wcscmp(alt,neu)) {
erg=u;
} else {
for(wchar_t* p=(wchar_t*)u.c_str();*p;p++)  {
wchar_t *pi = (wchar_t*)alt;
int i=0,gleich=1;
for(;*(pi+i);i++)
if (*(pi+i)!=*(p+i))
{gleich=0;break;}
if (gleich) {erg+=neu;p+=i-1;} else erg+=(*p);
}
}
return erg;
} // ersetze(char *u, const char* alt, const char* neu)

string fersetze(const string& u, const char* alt, const char* neu) 
{
string erg;
if (alt[0]==0 || !strcmp(alt,neu)) {
erg=u;
} else {
for(char* p=(char*)u.c_str();p<(char*)u.c_str()+u.length();p++)  {
if (logdatei[0]=='1') xit(0);
char *pi = (char*)alt;
int i=0,gleich=1;
for(;*(pi+i);i++)
if (*(pi+i)!=*(p+i))
{gleich=0;break;}
if (gleich) {erg+=neu;p+=i-1;} else {
erg+=(*p);
}
}
}
return erg;
} // ersetze(char *u, const char* alt, const char* neu)
 */

// geht nicht fuer Umlaute
string caseersetze(const string& u, const char* const alt, const char* const neu) 
{
  string erg;
  if (alt[0]==0 || !strcmp(alt,neu)) {
    erg=u;
  } else {
    ////   for(char* p=(char*)u.c_str();*p;p++)  KLA
    for(char* p=(char*)u.c_str();p<(char*)u.c_str()+u.length();p++)  {
      char *pi = (char*)alt;
      int i=0,gleich=1;
      for(;*(pi+i);i++)
        if (tolower(*(pi+i))!=tolower(*(p+i)))
        {gleich=0;break;}
      if (gleich) {erg+=neu;p+=i-1;} else erg+=(*p);
    }
  } //   if (alt[0]==0 || !strcmp(alt,neu)) else
  return erg;
} // ersetze(char *u, const char* alt, const char* neu)

string *loeschealleaus(string *u, const char* const alt) 
{
  const size_t len=strlen(alt);
  size_t pos;
  while ((pos=u->find(alt))!=string::npos) {
    u->erase(pos,len);
  }
  return u;
} // loeschealleaus(char *u, const char* alt, const char* neu)

string ersetzAllezu(const string& quelle, const string& alt, const string& neu) 
{
  if(!alt.empty()) {
    string zwi;
    zwi.reserve(quelle.length());
    size_t p0 = 0, pakt;
    while((pakt = quelle.find(alt, p0)) != string::npos) {
      zwi += quelle.substr(p0, pakt - p0);
      zwi += neu;
      pakt += alt.length();
      p0 = pakt;
    } //     while((pakt = quelle.find(alt, p0)) != string::npos)
    zwi += quelle.substr(p0);
    return zwi;
  } //   if(!alt.empty())
  return quelle;
} // string ersetzAllezu(string& quelle, const string& alt, const string& neu) 


void ersetzAlle(string& quelle, const string& alt, const string& neu) 
{
  if(!quelle.empty() && !alt.empty()) {
    string zwi;
    zwi.reserve(quelle.length());
    size_t p0 = 0, pakt;
    while((pakt = quelle.find(alt, p0)) != string::npos) {
      zwi += quelle.substr(p0, pakt - p0);
      zwi += neu;
      pakt += alt.length();
      p0 = pakt;
    }
    zwi += quelle.substr(p0);
//    quelle.swap(zwi); // 24.4.18 Absturz
		quelle=zwi;
  }
} // void ersetzAlle(string& quelle, const string& alt, const string& neu) 


string ersetzAllezu(string *quelle, const char* const alt, const char* const neu) 
{
  if(!quelle->empty() && *alt) {
    string zwi;
    zwi.reserve(quelle->length());
    size_t altlen{strlen(alt)};
    size_t p0{0}, pakt;
    while((pakt = quelle->find(alt, p0)) != string::npos) {
      zwi += quelle->substr(p0, pakt - p0);
      zwi += neu;
      pakt += altlen;
      p0 = pakt;
    } //     while((pakt = quelle->find(alt, p0)) != string::npos)
    zwi += quelle->substr(p0);
    return zwi;
  } //   if(*alt)
  return *quelle;
} // string ersetzAllezu(string *quelle, const char* alt, const char* neu) 


string ersetzAllezu(const char *const quelle, const char* const alt, const char* const neu) 
{
  string erg;
  if (alt[0]==0 || !strcmp(alt,neu)) {
    erg=quelle;
  } else {
    for(char* p=(char*)quelle;p<quelle+strlen(quelle);p++)  {
      char *pi = (char*)alt;
      int i{0},gleich{1};
      for(;*(pi+i);i++)
        if (*(pi+i)!=*(p+i))
        {gleich=0;break;}
      if (gleich) {
			  erg+=neu;p+=i-1;
			} else {
        erg+=(*p);
      } // if (gleich) else
    } //     for(char* p=(char*)quelle;p<quelle+strlen(quelle);p++)
  } //   if (alt[0]==0 || !strcmp(alt,neu)) else
  return erg;
} // string ersetzAllezu(const char *quelle, const char* alt, const char* neu) 


void ersetzAlle(string *quelle, const char* const alt, const char* const neu) 
{
  if(!quelle->empty() && *alt) {
    string zwi;
    zwi.reserve(quelle->length());
    size_t altlen = strlen(alt);
    size_t p0 = 0, pakt;
    while((pakt = quelle->find(alt, p0)) != string::npos) {
      zwi += quelle->substr(p0, pakt - p0);
      zwi += neu;
      pakt += altlen;
      p0 = pakt;
    } //     while((pakt = quelle->find(alt, p0)) != string::npos)
    zwi += quelle->substr(p0);
    quelle->swap(zwi); 
  } //   if(*alt)
} // void ersetzAlle(string *quelle, const char* alt, const char* neu) 


void ersetzAlle(string *quelle, const string& alt, const string& neu) 
{
  if(!quelle->empty() && !alt.empty()) {
    string zwi;
    zwi.reserve(quelle->length());
    size_t p0 = 0, pakt;
    while((pakt = quelle->find(alt, p0)) != string::npos) {
      zwi += quelle->substr(p0, pakt - p0);
      zwi += neu;
      pakt += alt.length();
      p0 = pakt;
    } //     while((pakt = quelle->find(alt, p0)) != string::npos)
    zwi += quelle->substr(p0);
    quelle->swap(zwi); 
  } //   if(!alt.empty())
} // void ersetzAlle(string *quelle, const string& alt, const string& neu) 


// ergibt die Zahl der Vorkommen von *was in *str
size_t zahlin(const string *const str, const char* const was) 
{
  size_t erg=0,pos=0;
  if (*was) {
    while ((pos=str->find(was,pos)+1)) {
      erg++;
    }
  } //   if (*was)
  return erg;
} // size_t zahlin(string *str, const char* was) 


void chersetze(string str, string *wsRet, const string& from, const char to) 
{
  //// wsRet->reserve(str.length());
  wsRet->clear();
  size_t start_pos = 0, pos;
  while((pos = str.find_first_of(from, start_pos)) != string::npos) {
    *wsRet += str.substr(start_pos, pos - start_pos);
    *wsRet += to;
    pos ++;
    start_pos = pos;
  }
  *wsRet += str.substr(start_pos);
} // void chersetze(string str, string *wsRet, const string& from, const char to) 


string ersetze(const char *const u, const char *const alt, const char *const neu) 
{
  string erg;
  if (alt[0]==0 || !strcmp(alt,neu)) {
    erg.append(u);
  } else {
    for(char* p=(char*)u;*p;p++) {
      char *pi = (char*)alt;
      int i{0},gleich{1};
      for(;*(pi+i);i++)
        if (*(pi+i)!=*(p+i))
        {gleich=0;break;}
      if (gleich) {erg+=neu;p+=i-1;} else erg+=(*p);
    } //     for(char* p=(char*)u;*p;p++)
  } //   if (alt[0]==0 || !strcmp(alt,neu)) else
  return erg;
} // ersetze(char *u, const char* alt, const char* neu)

string *sersetze(string* src, string const& target, string const& repl) 
{
  if (target.length()) {
    if (src->length()) {
      size_t idx = 0;
      for (;;) {
        idx = src->find( target, idx);
        if (idx == string::npos)  break;
        src->replace( idx, target.length(), repl);
        idx += repl.length();
      } //       for (;;)
    } //     if (src->length())
  } // if (target.length())
  return src;
} // sersetze( string src, string const& target, string const& repl)

string nersetze(const string& quelle, string const& was, string const& durch)
{
	string erg,*ep{(string*)&quelle};
	size_t n=0;
	while((n=ep->find(was,n))!=string::npos) {
		if (ep==&quelle) {
			erg=quelle;
			ep=&erg;
		} // 		if (ep==&quelle)
		ep->replace(n,was.size(),durch);
		n+=durch.size();
	}
	return *ep;
} // string nersetze(const string& quelle,string was, string durch)

void getstammext(const string *const ganz, string *stamm, string *exten) 
{
  size_t posp = ganz->rfind('.');
  if (posp!=std::string::npos) {
    *exten=ganz->substr(posp+1);
    *stamm=ganz->substr(0,posp);
  } else {
    *exten=string();
    *stamm=string(*ganz);
  } //   if (posp!=std::string::npos) else
} // void getstammext(string *ganz, string *stamm, string *exten) 

#if defined(__MINGW32__) || defined(_MSC_VER)
int getcols() 
{
  CONSOLE_SCREEN_BUFFER_INFO info; ////Schrecklicher Name ;)
  GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE),&info);
  return info.dwSize.X;
} // int getcols() 
#elif linux
int getcols() 
{
  winsize w;
  ioctl(STDOUT_FILENO, TIOCGWINSZ, &w);
  return w.ws_col;
} // int getcols() 
#endif

// Achtung: Wegen der Notwendigkeit der Existenz der Datei zum Aufruf von setfacl kann die Datei erstellt werden!
mdatei::mdatei(const string& name, ios_base::openmode modus/*=ios_base::in|ios_base::out*/,uchar faclbak/*=1*/,int obverb/*=0*/, int oblog/*=0*/)
{
	if (obverb||oblog) fLog(violetts+"mdatei("+blau+name+schwarz+","+blau+ltoan(modus)+schwarz+","+blau+(faclbak?"1":"0")+schwarz+")",oblog,obverb);
  const uchar mehralslesen{(modus&ios_base::out||modus&ios_base::app||modus&ios_base::trunc||modus&ios_base::app)};
  for(int iru=0;iru<3;iru++) {
    open(name,modus);
    if (is_open()) {
      oboffen=1;
      break;
    } //     if (is_open())
    ////    int erg __attribute__((unused));
		////    if (name!=unindt)  // sonst vielleicht Endlosschleife
		if (mehralslesen) {
			pruefverz(dir_name(name),obverb,oblog,/*obmitfacl=*/1,/*obmitcon=*/0,/*besitzer*/string(),/*benutzer*/string(),/*obmachen*/1,/*obprot*/name!=unindt);
			////    if (!systemrueck(sudc+"test -f '"+name+"' || "+sudc+"touch '"+name+"'",obverb,oblog)) KLA
			if (!touch(name,obverb,oblog)) {
				setfaclggf(name,obverb>1?obverb-1:0,oblog,/*obunter=*/falsch,/*mod=*/modus&ios::out||modus&ios::app?6:4,/*obimmer=*/falsch,faclbak);
			} // if (!systemrueck(sudc+"test -f '"+name+"' || "+sudc+"touch '"+name+"'",obverb,oblog)) 
		} // 		if (mehralslesen)
	} // for(int iru=0;iru<3;iru++) 
	if (obverb||oblog) fLog(violetts+Txk[T_Ende]+"mdatei("+blau+name+schwarz+","+blau+ltoan(modus)+schwarz+","+blau+(faclbak?"1":"0")+schwarz+")",oblog,obverb);
} // mdatei::mdatei (const string& name, ios_base::openmode modus)

#ifdef oeffalsch
#ifdef obfstream
fstream*
#else // obfstream
FILE*
#endif // obfstream 
oeffne(const string& datei, uchar oart, uchar* erfolg,int obverb/*=0*/, int oblog/*=0*/,uchar faclbak/*=1*/)
{
#ifdef obfstream
	ios_base::openmode mode;
	switch (oart) {
		case 0: mode=ios_base::in; break;
		case 1: mode=ios_base::out; break;
		case 2: mode=ios_base::out | ios_base::app; break;
		case 3: mode=ios_base::out; break; // text mode, default
	} // 	switch (oart)
	fstream *sdat;
#else // obfstream
	const char *mode;
	switch (oart) {
		case 0: mode="r"; break;
		case 1: mode="w"; break;
		case 2: mode="a"; break;
		case 3: mode="wt"; break; // text mode, default
	} // 			switch (art)
	FILE *sdat;
#endif // obfstream else
	for(int iru=0;iru<2;iru++) {
#ifdef obfstream
		sdat = new fstream(datei,mode);
		if (sdat) if (!sdat->is_open()) sdat=0;
#else // obfstream
		sdat= fopen(datei.c_str(),mode);
#endif // obfstream else
		if (sdat) {
			*erfolg=1;
			setfaclggf(datei,obverb>1?obverb-1:0,oblog,/*obunter=*/falsch,/*mod=*/oart?6:4,/*obimmer=*/0,faclbak);
			break;
		}  // 				if ((sdat= fopen(datei.c_str(),mode)))
		if (!*erfolg) {
			int erg __attribute__((unused)){
				////                                        systemrueck(sudc+"touch '"+datei+"'",obverb,oblog);
				touch(datei,obverb,oblog)};
		} // 				if (!*erfolg)
	} // oeffne
	return sdat;
} // 		if (sdat)
#endif	 // oefalsch


int kuerzelogdatei(const char* logdatei,int obverb)
{
#ifdef kfalsch
	uchar erfolg{0};
#endif // kfalsch
	//// zutun: nicht erst in Vektor einlesen, sondern gleich in die tmp-Datei schreiben 10.6.12

	////	vector<string> Zeilen;   //Der Vektor Zeilen enthaelt String-Elemente
	char Zeile[256]; //Die maximale Zeilenlaenge betraegt 255 Zeichen, weil ein String mit einer Null endet
	if (obverb>1) {
		cout<<"obverb: "<<(int)obverb<<Txk[T_kuerze_logdatei]<<drot<<logdatei<<schwarz<<endl;
	}
	////  fLog(string("kuerzelogdatei: ") + drot + logdatei + schwarz,obverb,0);
	//// ersetze(logdatei,"\\","\\\\")
	struct stat stat={0};
	if (lstat(logdatei,&stat)){
		if (obverb>1) {
			cout<<Txk[T_Logdatei]<<drot<<logdatei<<schwarz<<Txk[T_gibt_es_noch_nicht_Kuerze_sie_daher_nicht]<<endl;
		}
		return 1;
	} // 	if (lstat(logdatei,&stat))
	if (obverb>1) {
		cout<<rot<<Txk[T_Logdateidpp]<<endl<<schwarz; 
		int erg __attribute__((unused)){system((string(dir) + "\"" + logdatei + "\"").c_str())};
	}
	const string ofil{string(logdatei)+"tmp"};
	int abhier{0};
	mdatei outfile(ofil,ios::out,0);
	if (!outfile.is_open()) {
		perror((string("\nkuerzelogdatei: ")+Txk[T_Kann_Datei]+ofil+Txk[T_nicht_als_fstream_zum_Schreiben_oeffnen]).c_str());
		return 1;
	}
	mdatei logf(logdatei,ios::in,0);
	if (!logf.is_open()) {
		perror((string("\nkuerzelogdatei: ")+Txk[T_Kann_Datei]+logdatei+Txk[T_nicht_als_fstream_zum_Lesen_oeffnen]).c_str());
		return 1;
	}
	while (logf.getline (Zeile, sizeof(Zeile))) {
		////		Zeilen.push_back(Zeile); //haengt einfach den Inhalt der Zeile als Vektorelement an das Ende des Vektors
		if (!abhier) {
			tm *atm = new tm; // int aktz;
			////	for(aktz=Zeilen.size()-1;aktz>=0;aktz--) KLA
			////         fLog(string("aktz=") + ltoa_(aktz,buffer,10),obverb,0);
			int verwertbar{0}, index;
			for(unsigned j=0;j<2;j++) {
				if (verwertbar) {
					index = verwertbar-1;
					j=2;
				} else {
					index = j;
				}
				switch (index) {
					case 0: 
						if (sscanf(Zeile,"%2d.%2d.%2d %2d:%2d:%2d%*s",&atm->tm_mday,&atm->tm_mon,&atm->tm_year,&atm->tm_hour,&atm->tm_min,&atm->tm_sec)==6) {
							if (!verwertbar) {
								verwertbar=1;
								j=2;
							}
							atm->tm_mon--;
							atm->tm_year+=100; // 2000-1900
							////	  <<atm->tm_mday<<"."<<atm->tm_mon+1<<"."<<atm->tm_year<<"."<<atm->tm_hour<<"."<<atm->tm_min<<"."<<atm->tm_sec<<endl;
							atm->tm_isdst=-1; // sonst wird ab und zu eine Stunde abgezogen
						} else if (verwertbar) verwertbar=0;
						break;
					case 1:
						if (strptime(Zeile,"%a %b %d %T %Y", atm)) {
							if (!verwertbar) {
								verwertbar=2;
								j=2;
							} //                   if (!verwertbar)
						} else if (verwertbar) verwertbar=0;
				} //             switch (index)
			} //           for(unsigned j=0;j<2;j++)
			if (verwertbar) {
				time_t gesz=mktime(atm);
				////          	  char tbuf[20];
				////              strftime(tbuf, 18,"%d.%m.%y %X",localtime(&gesz));
				////              <<"Datum: "<<tbuf<<endl;
				time_t jetzt=time(0);
				long sekunden=(long)(jetzt-gesz);
				if (sekunden<1209600) {// juenger als zwei Wochen => behalten
					abhier=1;
				}
				////	  <<jetzt<<"- "<<gesz<<"="<<sekunden<<endl;
			} // if (sscanf(Zeile
			delete[] atm;
		} // (!abhier)
		if (abhier) {
			outfile<<Zeile<<endl;
		} //         if (abhier)
	} //         	while (logf.getline (Zeile, sizeof(Zeile)))
	outfile.close();
	if (abhier) {
		remove(logdatei);
		rename(ofil.c_str(),logdatei);
	}else{
		remove(ofil.c_str());
	} // if (abhier) else
	return 0;
	/*//
		<< "Alle Zeilen:" << endl;
		unsigned int ii; //unsigned, weil ansonsten Vergleich von signed- und unsigned-Werten.
		for(ii=0; ii < Zeilen.size(); ii++) KLA
		<< Zeilen[ii] << endl;
		KLZ
		<< endl;
	 */
}	 // int kuerzelogdatei(const char* logdatei,int obverb)

// aufgerufen in Log, setzbemv, schAschreib
string* loeschefarbenaus(string *zwi)
{
	loeschealleaus(zwi,schwarz);
	loeschealleaus(zwi,dgrau); 
	loeschealleaus(zwi,drot); 
	loeschealleaus(zwi,rot); 
	loeschealleaus(zwi,gruen); 
	loeschealleaus(zwi,hgruen); 
	loeschealleaus(zwi,braun); 
	loeschealleaus(zwi,gelb); 
	loeschealleaus(zwi,blau); 
	loeschealleaus(zwi,dblau); 
	loeschealleaus(zwi,violett); 
	loeschealleaus(zwi,hviolett); 
	loeschealleaus(zwi,tuerkis); 
	loeschealleaus(zwi,htuerkis); 
	loeschealleaus(zwi,hgrau); 
	loeschealleaus(zwi,weiss); 
	return zwi;
} // void loeschefarbenaus(string *zwi)

// Elypsen-Log-Funktion
int yLog(const short screen,const short file, const bool oberr,const short klobverb, const char *format, ...)
{
	int erg{0};
	if (screen||file) {
		va_list args;
		va_start(args,format);
#define vagenau
#ifdef vagenau		
		va_list a2;
		va_copy(a2,args);
		auto groe=vsnprintf(0,0,format,a2)+1;
		//<<"groe: "<<groe<<endl;
		char *buf=new char[groe];
#else // vagenau
		const int groe{512}; 
		char buf[groe];
#endif // vagenau	else
		vsnprintf(buf,groe,format,args);
		erg=fLog(buf,screen,file,oberr,klobverb);
#ifdef vagenau
		delete buf;
		buf=0;
#endif // vagenau
		va_end(args);
	} // 	if (screen||file)
	return erg;
} // int yLog(const short screen,const short file, const bool oberr,const short klobverb, const char *format, ...)

// freie Log-Funktion
int fLog(const string& text, const short screen/*=1*/, const short file/*=1*/, const bool oberr/*=0*/, const short klobverb/*=0*/)
{
	static unsigned int cols{0};
	static bool letztesmaloZ;
	const bool naechstezeile{0};
#ifdef false
	uchar erfolg{0};
#endif   // false
	// screen=0 = schreibt nicht auf den Bildschirm, 1 = schreibt, -1 = schreibt ohne Zeilenwechsel, -2 = schreibt bleibend ohne Zeilenwechsel
	//// <<"Log: "<<text<<", screen: "<<screen<<", file: "<<file<<endl;
	if (file || screen) {
		if (screen) {
			if (!cols) cols=getcols();
			cout<<text;
			if (letztesmaloZ && (cols>=text.length())) {
				cout<<string(cols-text.length(),' ');
			}	
			if (screen==-2); else if (screen==-1 && !naechstezeile) 
			{cout<<"\r";cout.flush();} 
			////      <<"\n\n"<<text<<"\nHier kein Zeilenumbruch\n\n";
			else cout<<endl; 
			letztesmaloZ = (screen==-1);
		} // if (screen) 
		if (file) {
			if (!logdt || !*logdt|| !strcmp(logdt,"/")) {
				cerr<<rot<<Txk[T_Variable_logdatei_leer]<<schwarz<<endl;
			}
			struct stat logst={0};
			if (!lstat(logdt,&logst) && S_ISDIR(logst.st_mode)) {
				cerr<<rot<<Txk[T_Variable_logdatei_Verzeichnis]<<schwarz<<endl;
			} else {
				static bool erstaufruf=1;
				//// char tbuf[20];
				time_t jetzt=time(0);
				stringstream strs;
				strs<<ztacl(jetzt,"%d.%m.%y %X: ")<<text;
				//// pthread_mutex_lock(&timemutex);
				//// strftime(tbuf,sizeof tbuf,"%d.%m.%y %X: ",localtime(&jetzt));
				//// pthread_mutex_unlock(&timemutex);
				//// string zwi=tbuf+text; 
				string zwi{strs.str()};
				loeschefarbenaus(&zwi);

				if (erstaufruf) {
					kuerzelogdatei(logdt,klobverb); // screen
					////         fLog("nach kuerzelogdatei",screen,0);
					erstaufruf=0;
				}	  
				mdatei logf(logdt,ios::out|ios::app,0);
				if (!logf.is_open()) {
					perror((string("\nLog: ")+Txk[T_Kann_Datei]+logdt+Txk[T_nicht_mit_open_zum_Anhaengen_oeffnen]).c_str());
					return 1;
				} else {
					logf<<zwi<<endl; 
					logf.close();
				} //         if (!logf.is_open()) else
#ifdef false        
#ifdef obfstream
				fstream *logf=oeffne(logdt,2,&erfolg);
				if (!erfolg) {
					perror((string("\nLog: ")+Txk[T_Kann_Datei]+logdt+Txk[T_nicht_als_fstream_zum_Anhaengen_oeffnen]).c_str());
					return 1;
				} else {
					*logf<<zwi<<endl; 
					logf->close();
				}
#else	 // obfstream
				FILE *logf=oeffne(logdt,2,&erfolg);
				if (!erfolg) {
					////perror((string("\nLog: Kann Datei '")+logdt+"' nicht mit fopen zum Anhaengen oeffnen.").c_str()); // ergebnisgleich wie:
					cerr<<"\nLog: "<<Txk[T_Kann_Datei]<<logdt<<Txk[T_nicht_mit_fopen_zum_Anhaengen_oeffnen]<<strerror(errno)<<endl;
					return 1;
				} else {
					fputs((string(tbuf)+zwi).c_str(),logf);
					fputs("\n",logf);
					fclose(logf);
				} // if (!erolg) else
#endif // obfstream else
#endif // false

			} // if (!logdt || !*logdt) _gKLA_ _gKLZ_ else _gKLA_
			if (oberr) {
				////      string hstrerror=strerror(errno); // da errno trotz richtiger Fallunterscheidung bei isatty(fileno(stdout)) gesetzt wird
				// wenn cerr woanders hingeht als cout oder die Meldung gar nicht an screen gerichtet ist, hier ohne Beruecks.v.screen==-1
				if (isatty(fileno(stdout))!=isatty(fileno(stderr)) || !screen) {
					cerr<<text<<endl; //// <<": "<<hstrerror<<endl;
				}
				errno=0;
			} //       if (oberr)
		} // (file)
	} // if (file || screen) 
	//// <<"Screen: "<<screen<<"letztesmaloZ: "<<letztesmaloZ;
	//// <<"und dann: "<<letztesmaloZ<<endl;
	return 0;
} // fLog(string text)


#ifdef _MSC_VER
inline void wait () 
{
	pthread_mutex_lock(&getmutex);
	cout<<Txk[T_Bitte_mit]<<_drot<<"return"<<_schwarz<<Txk[T_beenden];
	// Loescht etwaige Fehlerzustaende, die das Einlesen verhindern koennten
	cin.clear();
	// (= ignoriert alle Zeichen die derzeit im Puffer sind)
	cin.ignore(cin.rdbuf()->in_avail());
	// Fuege alle eingelesenen Zeichen in den Puffer bis ein Enter gedrueckt wird
	// cin.get() liefert dann das erste Zeichen aus dem Puffer zurueck, welches wir aber ignorieren (interessiert uns ja nicht)
	cin.get();
	pthread_mutex_unlock(&getmutex);
}  // inline void wait () 
#endif // _MSC_VER


// braucht nur 1/300 von FindStringInBuffer
long cmpmem( char* feld, const char* search, int len_feld) //// , int len_search
{
	/*//#ifdef _DEBUG
		gettimeofday(&perfStart, 0); 
#endif
	 */
  size_t i{0};
  int j{-1};
  size_t len_search{strlen(search)};
  for(; i<len_feld-len_search; feld++,i++){
    j=memcmp(feld, search, len_search);
    if (!j) 
      break;
  }
/*//
#ifdef _DEBUG
gettimeofday(&perfEnd, 0); 
#endif
#ifdef _DEBUG
#ifdef _WIN32
perf2= (((double)(perfEnd-perfStart))/((double)freq)); 
#else
perf2= static_cast<double> (perfEnd.tv_sec * 1000000 + perfEnd.tv_usec- perfStart.tv_sec * 1000000 - perfStart.tv_usec) / 1000000;
#endif
#endif
*/
  return !j?i:-1;
////    return (i == len_feld-len_search)?0:feld;  
}    // long cmpmem( char* feld, const char* search, int len_feld) // , int len_search


string ltoan(long value, int base/*=10*/, uchar obtz/*=0*/, uchar minstel/*=0*/) 
{
  /**
   * C++ version 0.4 char* style "itoa":
   * Written by Lukás Chmela
   * Released under GPLv3.
   */
  const uchar resultlenge{30};
  char result[resultlenge];
  // check that the base is valid
	if (base < 2 || base > 36) { 
		*result = '\0'; 
	} else {
		char* ptr = result, *ptr1 = result, tmp_char;
		long tmp_value;
		uchar stelle{0},stellen{0};
		do {
			tmp_value = value;
			value /= base;
			*ptr++ = "zyxwvutsrqponmlkjihgfedcba9876543210123456789abcdefghijklmnopqrstuvwxyz" [35 + (tmp_value - value * base)];
			stellen++;
			if (obtz) if (value) if (++stelle==3) {*ptr++ ='.';stelle=0;stellen++;}
		} while ( value );
		while (stellen++<minstel && stellen<resultlenge) *ptr++ = ' ';

		// Apply negative sign
		if (tmp_value < 0) *ptr++ = '-';
		*ptr-- = '\0';
		while(ptr1 < ptr) {
			tmp_char = *ptr;
			*ptr--= *ptr1;
			*ptr1++ = tmp_char;
		} //   while(ptr1 < ptr)
	} //   if (base < 2 || base > 36)
  return string(result);
} // ltoan(long value, char* result, int base)

char* ltoa_(long value, char* result, int base/*=10*/) 
{
  /**
   * C++ version 0.4 char* style "itoa":
   * Written by Lukás Chmela
   * Released under GPLv3.
   */
  // check that the base if valid
  if (base < 2 || base > 36) { *result = '\0'; return result; }

  char* ptr = result, *ptr1 = result, tmp_char;
  long tmp_value;

  do {
    tmp_value = value;
    value /= base;
    *ptr++ = "zyxwvutsrqponmlkjihgfedcba9876543210123456789abcdefghijklmnopqrstuvwxyz" [35 + (tmp_value - value * base)];
  } while ( value );

  // Apply negative sign
  if (tmp_value < 0) *ptr++ = '-';
  *ptr-- = '\0';
  while(ptr1 < ptr) {
    tmp_char = *ptr;
    *ptr--= *ptr1;
    *ptr1++ = tmp_char;
  }
  return result;
} // ltoa_(long value, char* result, int base)

double verszuzahl(const string& vers)
{
 string vneu;
 uchar obkomma{0};
 for(size_t i=0;i<vers.size();i++) {
  if (strchr("0123456789",vers[i])) {
	 vneu+=vers[i];
	} else if (vers[i]=='.'||vers[i]==',') {
	 if (!obkomma) {
	  vneu+='.';
		obkomma=1;
	 } // 	 if (!obkomma)
	} //   if (strchr("0123456789",vers[i]))  else if ..
 } //  for(size_t i=0;i<vers.size();i++)
 if (vneu.empty()) return 0; else return strtold(vneu.c_str(),0);
} // double verstozahl(string vers)

// Programmversion, falls diese beim Programm mit " --version" abrufbar ist
double hcl::progvers(const string& prog,string *ergptr/*0*/)
{
	double vers{0};
	string pfad;
	if (obprogda(prog,obverb,oblog,&pfad)) {
		svec urueck;
		systemrueck(pfad+" --version 2>&1",obverb,oblog,&urueck,/*obsudc=*/0);
		if (urueck.size()) {
			const string bas{base_name(pfad)};
			size_t pos{urueck[0].find(bas)};
			if (pos!=string::npos) {
				pos+=bas.length();
			} else {
				// python3 => Python 3.4.6 
				pos=urueck[0].find_last_of(" ");
				if (pos==string::npos) {
					if (isnumeric(urueck[0]))
						pos=0; 
				}
			} // 			if (pos!=string::npos) else
			const string ergs{urueck[0].substr(pos)};
			if (ergptr) *ergptr=ergs;
			if (pos!=string::npos) vers=verszuzahl(ergs);
			if (obverb) { 
				stringstream ausg;
				ausg<<Txk[T_Progvers]<<blau<<prog<<schwarz<<Txk[T_Ausgabezeile]<<blau<<urueck[0]<<schwarz<<
					Txk[T_verwendet_wird]<<blau<<ergs<<schwarz<<Txk[T_Ergebnis]<<blau<<vers<<schwarz;
				hLog(ausg.str());
			} // 			if (obverb)
		} // 			if (urueck.size())
	} // 	if (obprogda(prog,obverb,oblog,&pfad))
	return vers;
} // double progvers(string prog,int obverb, int oblog)

#ifdef notwendig
void kopierm(const string *quelle, const string *ziel)
{
	mdatei fileIn(quelle->c_str(),ios::in|ios::binary,0);
	mdatei fileOut(ziel->c_str(),ios::out | ios::trunc | ios::binary,0);
	fileOut<<fileIn.rdbuf();
} // void kopierm(const string *quelle, const string *ziel)
#endif // notwendig

// von http://chris-sharpe.blogspot.de/2013/05/better-than-systemtouch.html
int touch(const string& pfad,int obverb/*=0*/,int oblog/*=0*/)
{
	struct stat tstat={0};
  int fehler{lstat(pfad.c_str(),&tstat)};
	if (fehler) {
		const int fd{open(pfad.c_str(), O_WRONLY|O_CREAT|O_NOCTTY|O_NONBLOCK, 0666)};
		if (fd<0) { // Couldn't open that path.
			if (obverb) std::cerr<<__PRETTY_FUNCTION__<<": Couldn't open() path \""<<pfad<<"\"\n";
		} else {
			const int rc{utimensat(AT_FDCWD, pfad.c_str(), nullptr, 0)};
			if (rc) {
				if (obverb) std::cerr<<__PRETTY_FUNCTION__<<": Couldn't utimensat() path \""<<pfad<<"\"\n";
			} else {
			if (obverb||oblog) 
			  std::clog<<violett<<__PRETTY_FUNCTION__<<schwarz<<Txk[T_erfolgreich_fuer]<<blau<<pfad<<schwarz<<"\"\n";
			 fehler=0;
			} // 			if (rc) else
		} // 		if (fd<0) else
		if (fehler)
			for(int iru=0;iru<2;iru++) {
				if (!fehler) break;
				fehler=systemrueck("touch '"+pfad+"'"+(iru?"":" 2>/dev/null"),obverb,oblog,/*rueck=*/0,/*obsudc=*/iru);
			}
	} // 	if (fehler)
	return fehler;
} // int touch(const std::string& pfad,int obverb/*=0*/,int oblog/*=*/)


void aufSplit(vector<string> *tokens, const char* const text, const char sep/*=' '*/,bool auchleer/*=1*/)
{
  aufSplit(tokens,string(text),sep,auchleer);
} // void aufSplit(vector<string> *tokens, const char *text, const char sep/*=' '*/, bool auchler/*=1*/)

void aufSplit(vector<string> *tokens, const string& text, const char sep/*=' '*/,bool auchleer/*=1*/)
{
	size_t start{0}, end{0};
	tokens->clear();
	while ((end = text.find(sep, start)) != string::npos) {
		if (end!=start || auchleer) {
			tokens->push_back(text.substr(start,end-start));
		} // 		if (!akttok.empty() || auchleer)
		start = end + 1;
	} //   while ((end = text.find(sep, start)) != (int)string::npos)
	if (text.length() !=start || auchleer)
		tokens->push_back(text.substr(start));
} // void aufSplit(vector<string> *tokens, const string& text, const char sep,bool auchleer/*=1*/)

void aufSplit(vector<string> *tokens, const string& text, const char* const sep, bool auchleer/*=1*/)
{
  const size_t len{strlen(sep)};
  size_t start{0}, end{0};
  tokens->clear();
  while ((end = text.find(sep, start)) != string::npos) {
		if (end!=start || auchleer) {
				tokens->push_back(text.substr(start,end-start));
		} // 		if (!akttok.empty() || auchleer)
    start=end+len;
  } //   while ((end = text.find(sep, start)) != (int)string::npos)
	if (text.length()!=start || auchleer)
		tokens->push_back(text.substr(start));
} // void aufSplit(vector<string> *tokens, const string& text, char* sep,bool auchleer/*=1*/)

void aufiSplit(vector<string> *tokens, const string& text, const string& sep,bool nichtmehrfach/*=1*/,int obverb/*=0*/,int oblog/*=0*/,int ohneanfz/*=0*/) 
{
	size_t start{0},end{0},k{0},l2;
	if (obverb)
		fLog(string(Txk[T_trenne])+"'"+blaus+text+schwarz+"'"+Txk[T_bei]+"'"+blau+sep+schwarz+"':",obverb,oblog);
	//	for (char *p=(char*)sep.c_str() ; *p; ++p) *p = toupper(*p);
	////	string utext,usep;
	////	transform(text.begin(),text.end(),std::back_inserter(utext),::toupper);
	////	transform(sep.begin(),sep.end(),std::back_inserter(usep),::toupper);
	const string utext{boost::locale::to_upper(text, loc)},
				usep{boost::locale::to_upper(sep, loc)};

	if (ohneanfz) {
		const string anfn{"\"\'`"};
		for(size_t i=start;i<utext.length();i++) {
			if (anfn.find(utext[i])!=string::npos) {
				const size_t zweitpos{utext.find(utext[i],i+1)};
				if (zweitpos!=string::npos) {
					i=start=zweitpos;
				}
			}
		}
		/*
			 char anfn[]{"\"\'`"};
			 for(char anfz:anfn) {
			 while (1) {
			 size_t panfz{utext.find(anfz,start)};
			 if (panfz==string::npos) break;
			 size_t pendz{utext.find(anfz,panfz+1)};
			 if (pendz==string::npos) break;
			 start=pendz+1;
			 }
			 }
		 */
	}
	tokens->clear();
	while (1) {
		end=utext.find(usep,start);
		if (end!=string::npos) l2=end-start; else l2=string::npos;
		if (end==string::npos || nichtmehrfach || l2) {
			tokens->push_back(text.substr(start,l2));
			if (obverb)	
				fLog(tuerkiss+" tok["+ltoan(k)+"]: "+tokens->at(k)+schwarz,obverb,oblog);
			k++;
			if (end==string::npos) {
				break;
			} // 		 if (end==string::npos)
		} // 	 if (l2==string::npos || nichtmehrfach || l2)
		start=end+usep.length();
	} // 	while (1)
} // void aufiSplit(vector<string> *tokens, const string& text, const string sep,bool nichtmehrfach/*=1*/,int obverb/*=0*/,int oblog/*=0*/) 

// suche in einem String von hinten ohne Gross- und Klein-Unterscheidung
size_t irfind(const string& wo, const string& was)
{
	string uwo, uwas;
////	transform(wo.begin(),wo.end(),std::back_inserter(wou),::toupper);
////	transform(was.begin(),was.end(),std::back_inserter(wasu),::toupper);
	uwo=boost::locale::to_upper(wo, loc);
	uwas=boost::locale::to_upper(was, loc);
	return uwo.rfind(uwas);
} // size_t irfind(const string& wo, const string& was)

// Anfuehrungszeichen weg
string* anfzweg(string *quelp) {
	if (quelp->length()>1) {
		if (quelp->at(0)==quelp->at(quelp->length()-1) && strchr("\"'`",quelp->at(0))) {
			quelp->erase(quelp->length()-1,1);
			quelp->erase(0,1);
		}
	} // 	if (quelp.length()>1)
	return quelp;
} // string* anfzweg(

char ers(const char roh)
{
 switch(roh) {
  case '|': return 'u';
  case '<': return '(';
  case '>': return ')';
  case ':': return ';';
  case '"': return '\'';
  case '\\': return '`';
  case '/': return '´';
  case '*': return '°';
  case '?': return '~';
	default: return roh;
 } //  switch(roh)
} // char ers(char roh)

void fuersamba(string& roh)
{
  transform(roh.begin(),roh.end(),roh.begin(),ers);
} // void fuersamba(string& roh)

lsysen lsyscl::getsys(int obverb/*=0*/,int oblog/*=0*/)
{
      if (sys==usys) {
        if (!systemrueck("cat /proc/version | grep SUSE",obverb-2,oblog,/*rueck=*/0,/*obsudc=*/0)) return sus;
        if (!systemrueck("cat /proc/version | grep 'Ubuntu\\|ebian'",obverb-2,oblog,/*rueck=*/0,/*obsudc=*/0)) return deb;
        if (!systemrueck("cat /proc/version | grep edora",obverb-2,oblog,/*rueck=*/0,/*obsudc=*/0)) return fed;
      } //       if (sys==usys)
      return usys;
} // lsysen lsyscl::getsys(int obverb/*=0*/,int oblog/*=0*/)

string& lsyscl::getlib64(int obverb/*=0*/,int oblog/*=0*/)
{
	if (usr_lib64_vz.empty()){
		if (getsys()==deb) {
			usr_lib64_vz="/usr/lib/x86_64-linux-gnu";
		} else {
			usr_lib64_vz="/usr/lib64";
		} // 		if (getsys()==deb) else
	} // 	if (usr_lib64_vz.empty())
	return usr_lib64_vz;
} // string& lsyscl::getlib64(int obverb/*=0*/,int oblog/*=0*/)

class lsyscl lsys;

/*//
betrsys pruefos()
{
 static betrsys aktbs=keins;
 if (aktbs==keins) {
  svec rueck;
  systemrueck("which lsb_release >/dev/null 2>&1 && lsb_release -i || { test -f /etc/fedora-release && cat /etc/fedora-release;}",0,0,&rueck);
  if (rueck.size()) {
   if (rueck[0].find("SUSE LINUX")!=string::npos) aktbs=suse;
   else if (rueck[0].find("Ubuntu")!=string::npos) aktbs=ubuntu;
   else if (rueck[0].find("Fedora")!=string::npos) aktbs=fedora;
  }
 }
 return aktbs;
} // betrsys pruefos()
*/

// erg=1: gibt es fuer den aktuellen Benutzer; erg=2: gibt es fuer root; erg=0: nicht gefunden
int obprogda(const string& prog, int obverb/*=0*/, int oblog/*=0*/, string *pfad/*=0*/)
{
  if (prog.empty())
	  return 0;
	const int maxz{8};
  for(int iru=0;iru<maxz;iru++) {
    struct stat fstat={0};
    string verz;
		if (prog[0]=='/') iru=maxz; // z.B. <instvz>/ocrv/bin/ocrmypdf
    switch (iru) {
      case 0: verz="/usr/local/bin/"; break;
      case 1: verz="/usr/bin/"; break;
      case 2: verz="/usr/local/sbin/"; break;
      case 3: verz="/usr/sbin/"; break;
      case 4: verz="/sbin/"; break;
      case 5: verz="/bin/"; break;
			case 6: verz="/usr/libexec/"; break;
			case 7: verz="/run/"; break;
      default: break;
    } //     switch (iru)
    verz+=prog;
    if (!lstat(verz.c_str(),&fstat)) {
      if (pfad) *pfad=verz;
      return 1;
    }
  } // for(int iru=0;iru<3;iru++) 
  svec rueck;
  if (!systemrueck("which "+prog+" 2>/dev/null",obverb,oblog,&rueck,/*obsudc=*/0)) {
    if (pfad) *pfad=rueck[0];
    return 2;
  } // if (!systemrueck("which "+prog+" 2>/dev/null",obverb,oblog,&rueck))
	// wenn nicht root
  if (cus.cuid) {
    if (!systemrueck("which \""+prog+"\" 2>/dev/null ||env \"PATH=$PATH\" which \""+prog+"\" 2>/dev/null",obverb,oblog,&rueck,/*obsudc=*/1)) {
      if (pfad) *pfad=rueck[0];
      return 3;
    }
	} // if (!cus.cuid)
  if (pfad) pfad->clear();
  return 0; 
} // string obprogda(string prog,int obverb, int oblog,string *pfad)

template<> schAcl<WPcl>::schAcl(const string& name, vector<aScl> *v):name(name)
{
	for(size_t i=0;i<v->size();i++) {
		WPcl *wp=new WPcl((*v)[i].name,(*v)[i].wertp);
		schl.push_back((shared_ptr<WPcl>)wp);
	}
}
#ifdef false
template<> schAcl<WPcl>::schAcl(const string& name, vector<aScl> v):name(name)
{
	for(size_t i=0;i<v.size();i++) {
		WPcl *wp=new WPcl(v[i].name,v[i].wertp);
		schl.push_back((shared_ptr<WPcl>)wp);
	}
}
#endif

linst_cl::linst_cl(int obverb,int oblog)
{
	struct stat osvers{0};
	const string osvdt[]{"/etc/os-release","/etc/lsb-release"};
	const string feld[]{"NAME","DISTRIB_ID"};
	string osname;
	for(size_t i{0};i<elemzahl(osvdt);i++) {
		if (!lstat(osvdt[i].c_str(),&osvers)) {
			osname.clear();
			/*
			schAcl<WPcl> *osvCp{new schAcl<WPcl>("osvC", new vector<aScl>{
					{feld[i],&osname},
					})
			};
			*/
			vector<aScl> vecta{
					{feld[i],&osname},
					};
			schAcl<WPcl> osvCp("osvC", &vecta);
			confdcl osvd(osvdt[i],obverb);
			osvd.kauswert(&osvCp);
			if (!osname.empty()) {
				break;
			}
		}
	}
// enum distroenum{unbek=-1,Mint,Ubuntu,Debian,Suse,Fedora,Fedoraalt,Mageia,Manjaro};
	distroenum distro{osname.empty()?(
			obprogda("apt-get",obverb>0?obverb-1:0,oblog)?Ubuntu:
			obprogda("rpm",obverb>0?obverb-1:0,oblog)?(
				obprogda("zypper",obverb>0?obverb-1:0,oblog)?Suse:
				obprogda("dnf",obverb>0?obverb-1:0,oblog)?Fedora:
				obprogda("yum",obverb>0?obverb-1:0,oblog)?Fedoraalt:
				obprogda("urpmi.update",obverb>0?obverb-1:0,oblog)?Mageia:unbek
				):
			obprogda("pacman",obverb>0?obverb-1:0,oblog)?Manjaro:unbek
			):
		osname.find("Mint")!=string::npos?Mint:
		osname.find("Ubuntu")!=string::npos?Ubuntu:
		osname.find("Debian")!=string::npos?Debian:
		osname.find("SUSE")!=string::npos?Suse:
		osname.find("Fedora")!=string::npos?Fedora:
		osname.find("Mageia")!=string::npos?Mageia:
		osname.find("Manjaro")!=string::npos?Manjaro:unbek
	};
	fLog(blaus+"Distro: "+(distro==Mint?"Mint":distro==Ubuntu?"Ubuntu":distro==Debian?"Debian":distro==Suse?"Suse":distro==Fedora?"Fedora":distro==Fedoraalt?"Fedoraalt":distro==Mageia?"Mageia":distro==Manjaro?"Manjaro":Txk[T_unbek])+schwarz,obverb,oblog);
	// inhaltlich parallel getIPR() in install.sh
	switch (distro) {
		case unbek:
			cerr<<Txk[T_Weder_zypper_noch_apt_get_noch_dnf_noch_yum_als_Installationspgrogramm_gefunden]<<endl;
		case Mint: case Ubuntu: case Debian:
			// Repositories: Frage nach cdrom ausschalten
			// genauso in: configure
			// wenn cdrom-Zeile vorkommt, vor ftp.-debian-Zeile steht und www.debian.org erreichbar ist, dann alle cdrom-Zeilen hinten anhaengen
			// gleichlautend in configure: einricht()
			systemrueck("S=/etc/apt/sources.list;F='^[^#]*cdrom:';grep -qm1 $F $S && "
					"test 0$(sed -n '/^[^#]*ftp.*debian/{=;q}' $S) -gt 0$(sed -n '/'$F'/{=;q}' $S) && "
					"ping -qc 1 www.debian.org >/dev/null 2>&1 && sed -i.bak '/'$F'/{H;d};${p;x}' $S;:",obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
			// hier werden die Dateien vorgabemaessig behalten
			ipr=apt;
			schau="dpkg -s";
			instp=sudc+"apt-get install "; 
			instyp=sudc+"apt-get -y --force-yes --reinstall install "; 
			upr="apt-get -f install; apt-get --auto-remove purge ";
			udpr=sudc+"apt-get -f install;"+sudc+"dpkg -r --force-depends ";
			uypr="apt-get -f install; apt-get -y --auto-remove purge ";
			upd=sudc+"apt update;"+sudc+"apt upgrade;";
			compil="install build-essential linux-headers-`uname -r`";
			dev="dev";
			break;
		case Suse: case Fedora: case Fedoraalt: case Mageia:
			dev="devel";
			schau="rpm -q";
			udpr=sudc+"rpm -e --nodeps ";
			switch (distro) {
				case Suse:
					// heruntergeladene Dateien behalten
					ipr=zypper;
					instp=sudc+"zypper -n --gpg-auto-import-keys in ";
					instyp=instp+"-y -f ";
					upr="zypper -n rm -u ";
					uypr=upr+"-y ";
					upd=sudc+"zypper patch";
					repos=sudc+"zypper lr | grep 'g++\\|devel_gcc'>/dev/null 2>&1 || "+
						sudc+"zypper ar http://download.opensuse.org/repositories/devel:/gcc/`cat /etc/*-release |"
						"grep ^NAME= | cut -d'\"' -f2 | sed 's/ /_/'`_`cat /etc/*-release | grep ^VERSION_ID= | cut -d'\"' -f2`/devel:gcc.repo;";
					compil="gcc gcc-c++ gcc6-c++";
					break;
				case Fedora:
					ipr=dnf;
					instp=sudc+"dnf install ";
					instyp=sudc+"dnf -y install ";
					upr="dnf remove ";
					uypr="dnf -y remove ";
					upd=sudc+"dnf update";
					break;
				case Fedoraalt:
					ipr=yum;
					instp=sudc+"yum install ";
					instyp=sudc+"yum -y install ";
					upr="yum remove ";
					uypr="yum -y remove ";
					upd=sudc+"yum update";
					break;
				case Mageia:
					ipr=urp;
					instp="urpmi --auto ";
					instyp="urpmi --auto --force ";
					upr="urpme ";
					uypr="urpme --auto --force ";
					upd=sudc+"urpmi.update -a";
					break;
				default:
					break;
			} // 				if (obprogda("dnf",obverb>0?obverb-1:0,oblog))
			compil="make automake gcc-c++ kernel-devel";
			break;
		case Manjaro:
			ipr=pac;
			schau="pacman -Qi";
			instp=sudc+"pacman -S ";
			instyp=sudc+"pacman -S --noconfirm ";
			upr="pacman -R -s ";
			udpr=sudc+"pacman -R -d -d ";
			uypr="pacman -R -s --noconfirm "; 
			upd=sudc+"pacman -Syu";
			compil="gcc linux-headers-`uname -r`";
			break;
	}
	svec qrueck;
	// in findfile wird ueber setfacl evtl. Installation aufgerufen, was (aus Kontruktor) zum Absturz fuehrt
//	if (findv==1) {
		systemrueck("find /usr -maxdepth 1 -type d -name 'lib*'",obverb,oblog,&qrueck,/*obsudc=*/0);
//	} else findfile(&qrueck,findv,obverb,oblog,0,"/usr",/*muster=*/"lib[^/]*$",1,34,1);
	for(size_t iru=0;iru<qrueck.size();iru++) libs+=qrueck[iru]+" ";
	obprogda("sh",obverb,oblog,&shpf);// Pfad zu sh
	obprogda("xargs",obverb,oblog,&xargspf);// Pfad zu xargs
	obprogda("ionice",obverb,oblog,&ionicepf);// Pfad zu ionice
	obprogda("nice",obverb,oblog,&nicepf);// Pfad zu nice
	fLog(violetts+Txk[T_Ende]+"linst_cl::linst_cl"+schwarz,obverb,oblog);
} // linst_cl::linst_cl(int obverb,int oblog)

const string *const absch::suche(const char* const sname)
{
	static const string nix;
	for (size_t i=0;i<av.size();i++) {
		if (av[i].name==sname) {
			if (av[i].wertp) {
				return av[i].wertp;
			} else {
				break;
			}
		}
	} //   for (size_t i=0;i<av.size();i++)
	return &nix;
} // const string& absch::suche(const char* const sname)

const string *const absch::suche(const string& sname)
{
	return suche(sname.c_str());
} // const string& absch::suche(const string& sname)

void absch::clear()
{
 aname.clear();
 av.clear();
} // void absch::clear()

// sollte in lies eingebaut und daher unnoetig sein
void confdcl::Abschn_auswert(int obverb/*=0*/, const char tz/*='='*/)
{
  absch abp;
  for(size_t i=0;i<zn.size();i++) {
    string *const zeile{&zn[i]};
    size_t pos{zeile->find('#')};
    if (pos!=string::npos) zeile->erase(pos);
    gtrim(zeile);
    if (zeile->length()) {
      if (zeile->at(0)=='[' && zeile->at(zeile->length()-1)==']') {
        zeile->erase(zeile->length()-1);
        zeile->erase(0,1);
        if (/*!abp.aname.empty() && */abp.av.size()) {
           abschv.push_back(abp);
           abp.clear();
        }
        abp.aname=*zeile;
      } else {
        pos=zeile->find(tz);
        if (pos!=string::npos && pos>0) { 
          string name{zeile->substr(0,pos)};
          gtrim(&name);
          string *const wertp{new string(zeile->substr(pos+1))};
          gtrim(wertp);
          anfzweg(wertp);
          abp.av.push_back(aScl(name,wertp));
        } //         if (pos!=string::npos && pos>0) 
      } //       if (zeile->at(0)=='[' && zeile->at(zeile->length()-1)==']') 
    } //     if (zeile->length()) 
  } //   for(size_t i=0;i<zn.size();i++) 
  if (!abp.aname.empty() && abp.av.size()) {
    abschv.push_back(abp);
  }
/*//
  for(size_t i=0;i<abschv.size();i++) KLA
   <<violett<<"aname: '"<<abschv[i].aname<<"'"<<endl;
   for(size_t j=0;j<abschv[i].av.size();j++) 
    <<j<<": "<<abschv[i].av[j].name<<": "<<abschv[i].av[j].wert<<endl;
  KLZ
*/
} // void confdcl::Abschn_auswert(int obverb, char tz)

// setzt die Werte aus der Datei in der Optionenschar *sA
template <typename SCL> void confdcl::kauswert(schAcl<SCL> *sA, int obverb,const uchar mitclear/*=1*/)
{
	fLog(violetts+Txk[T_kauswert]+schwarz+": "+fname,obverb,0);
	richtige=0;
	if (mitclear) {
		sA->frisch();
	}
	if (obgelesen) {
		if (sA) {
			size_t ii=sA->schl.size();
			while(ii--) {
				sA->schl[ii]->ausgewertet=0;
			}
			for(size_t nr=0;nr<paare.size();nr++) {
						size_t ii=sA->schl.size();
						//// <<"auswert() "<<pname<<" vor while, wert: "<<wert<<endl;
////						if (obverb) caus<<"Stell 9, sA->name: "<<sA->name<<endl;
						while(ii--) {
							if (sA->schl[ii]) if (!sA->schl[ii]->ausgewertet) { 
								// conf[ii]->pname muss am Zeilenanfang anfangen, sonst Fehler z.B.: number, faxnumber
								if (paare[nr].name==sA->schl[ii]->pname) {
									//// if (obverb) caus<<"werte aus ..."<<endl;
									sA->schl[ii]->ausgewertet=1;
									//// <<"sA->schl[ii]->pname: "<<sA->schl[ii]->pname<<endl;
									//// <<blau<<"setze!"<<schwarz<<endl;
									// if (obverb) caus<<"Stell 11, sA->schl["<<ii<<"]->pname: "<<sA->schl[ii]->pname<<", wert: "; sA->schl[ii]->virtoausgeb(); caus<<endl;
									const int wiefalsch{sA->schl[ii]->setzstr(paare[nr].wert.c_str(),&obzuschreib,/*ausDatei=*/1)};
									if (!wiefalsch) {
										sA->setzbemerkwoher(sA->schl[ii].get(),/*bemerk=*/paare[nr].bemerk,/*woher*/2);
										++richtige;
									}
									break;
								} // if( !strcmp(sA[i]->pname.c_str(),zeile->c_str()) ) 
							} // 	if (sA->schl[ii]) if (!sA->schl[ii]->ausgewertet)
						} // 	while(ii--)
			} // 			for(size_t nr=0;nr<paare.size();nr++)
		} // 		if (sA)
		//// <<violett<<"obzuschreib: "<<rot<<(int)obzuschreib<<schwarz<<endl;
	} // if (obgelesen) 
	/*//	
		if (pname.find("config.tty")!=string::npos) KLA
		for(size_t ii=0;ii<sA->zahl;ii++) KLA
		<<" pname: "<<schwarz<<(*sA)[ii]->pname<<violett<<" wert: '"<<schwarz<<(*sA)[ii].wert<<"'"<<violett<<" bemerk: '"<<(*sA)[ii].bemerk<<"'"<<schwarz<<endl;
		KLZ
		KLZ
	 */
	fLog(violetts+Txk[T_Ende]+Txk[T_kauswert]+schwarz,obverb,0);
} // template <typename SCL> void confdcl::kauswert

void wpgcl::virtfrisch()
{
	bemerk.clear();
	switch (part) {
		case pbin: case puchar: case pint: case plong:
			setzstr("0",0); break;
		default: setzstr("",0);
	}
}

void WPcl::virtfrisch()
{
////	caus<<violett<<"WPcl::virtfrisch "<<blau<<pname<<schwarz<<endl;
	wpgcl::virtfrisch();
	gelesen=0;
	wert.clear();
////	caus<<violett<<"Ende WPcl::virtfrisch "<<blau<<pname<<schwarz<<endl;
}

optcl::~optcl()
{
////	caus<<"Loesche optcl, pname: "<<blau<<pname<<schwarz<<endl;
}

void optcl::virtfrisch()
{
////	caus<<violett<<"optcl::virtfrisch "<<blau<<pname<<schwarz<<endl;
	wpgcl::virtfrisch();
	woher=0;
	gegenteil=0;
  nichtspeichern=0;	
////	caus<<violett<<"Ende optcl::virtfrisch "<<blau<<pname<<schwarz<<endl;
} // void optcl::virtfrisch()

template<typename SCL> void schAcl<SCL>::frisch()
{
	////	caus<<violett<<"frisch schAcl: "<<blau<<name<<schwarz<<endl;
	for(size_t i=0;i<schl.size();i++) {
		schl[i]->virtfrisch();
  }
////	caus<<violett<<"Ende frisch schAcl: "<<blau<<name<<schwarz<<endl;
} // void schAcl::frisch()


template<typename SCL> schAcl<SCL>::schAcl(const string& name):name(name)
{
 //schl=0;
} // schAcl::schAcl()

template<typename SCL> schAcl<SCL>::~schAcl()
{
//// caus<<violett<<"Loesche schAcl: "<<blau<<name<<schwarz<<" size(): "<<size()<<endl;
	for(size_t i=0;i<schl.size();i++) {
		//delete schl[i];
////		caus<<"i: "<<i<<", schl[i]: "<<schl[i]<<", pname: ";
////		caus<<blau<<schl[i]->pname<<schwarz<<endl;
		schl[i].reset();
////		schl[i]=0; // falls selbes Element in mehreren Vektoren
	}
	////schl.clear();
//// caus<<violett<<"Ende loesche schAcl: "<<blau<<name<<schwarz<<endl;
	////schl.clear();
}// template<typename SCL> schAcl<SCL>::~schAcl()

/*
void schAcl::neu(size_t vzahl)
{
// if (schl) delete[] schl;
 schl.clear();
 zahl=vzahl;
 schl=new WPcl[zahl];
} // void schAcl::neu(size_t vzahl)
*/

/*// wird vielleicht nicht gebraucht
schAcl::schAcl(size_t zahl): zahl(zahl)
{
 schl = new WPcl[zahl];
}
*/
template<typename SCL> void schAcl<SCL>::sinit(vector<shared_ptr<SCL>> sqlvp)
{
// if (schl) delete[] schl;
	schl.clear();
  // schl = new WPcl[zahl];
  for(size_t sqli=0;sqli<sqlvp.size();sqli++) {
//    schl[sqli].name=sqlvp->at(sqli)->name;
//    schl[sqli].wert=sqlvp->at(sqli)->wert;
//		SCL* kl=sqlvp->at(sqli);
//		shared_ptr<SCL> kopie(kl);
//		schl.push_back(kopie);
		schl.push_back(sqlvp.at(sqli));

  }
} // void schAcl::sinit

/*
void schAcl::initd(const char* const* sarr,size_t vzahl)
{
	zahl=vzahl;
	if (schl) delete[] schl;
	schl = new WPcl[zahl];
	for(size_t i=0;i<zahl;i++) {
		schl[i]->name=sarr[i];
	}
} // schAcl::initd(const char* const* sarr,size_t vzahl)
*/

/*
	 schAcl::schAcl(const char* const* sarr,size_t vzahl)
	 {
	 initd(sarr,vzahl);
	 } // void schAcl:sinit
 */

template <> void schAcl<optcl>::sinit(size_t vzahl, ...)
{
} // void schAcl::sinit(size_t vzahl, ...)

// wird benoetigt in: holsystemsprache, lieszaehlerein
template <> void schAcl<WPcl>::sinit(size_t vzahl, ...)
{
	va_list list;
	va_start(list,vzahl);
	schl.clear();
	for(size_t i=0;i<vzahl;i++) {
		//schl.push_back(new WPcl(va_arg(list,const char*)));
		*this<<new WPcl(va_arg(list,const char*));
		//// <<rot<<"schl["<<i<<"].pname: "<<schwarz<<schl[i]->pname<<endl;
	}
 va_end(list);
} // void schAcl::sinit(size_t vzahl, ...)

/*
// das Setzen auch der Bemerkung wird bisher nicht benoetigt
template<typename SCL> int schAcl<SCL>::setze(const string& pname, const string& wert*//*, const string& bem*//*)
{
	for(size_t ind=0;ind<schl.size();ind++) {
    if (schl[ind].pname==pname) {
      schl[ind].wert=wert;
////      if (!bem.empty()) schl[ind].bemerk=bem;
      return 0;
    } //     if (schl[ind].pname==pname)
  } //   for(size_t ind=0;ind<zahl;ind++)
  return 1;
} // int schAcl::setze(const string& pname, const string& wert)
 
template<typename SCL> const string& schAcl<SCL>::hole(const string& pname)
{
  static const string nix;
  for(size_t ind=0;ind<schl.size();ind++) {
    if (schl[ind].pname==pname) {
      return schl[ind].wert;
    }
  } //   for(size_t ind=0;ind<zahl;ind++)
  return nix;
} // const string* schAcl::hole(const string& pname)

void WPcl::hole (struct tm *tmp) {
	if (!wert.empty()) {
		for(unsigned im=0;im<elemzahl(tmmoegl);im++) {
			if (strptime(wert.c_str(), tmmoegl[im], tmp)) break;
		}
		////		strptime(wert.c_str(), "%d.%m.%y %T", tmp);
	} // 	if (!wert.empty())
} // void WPcl::hole (struct tm *tmp)
*/

// wenn die bisherige Bemerkung in einer Sprache mit der zu setzenden identisch, also nicht zwischenzeitlich manuell geaendert, 
// dann in aktueller Sprache uebernehmen
// 5.2.18: unsicher, ob benoetigt
template<typename SCL> void schAcl<SCL>::setzbemv(const string& pname,TxB *TxBp,size_t Tind,uchar obfarbe,svec *fertige)
{
  string bemst; 
  svec bemv, *vp;
  if (fertige) {
    vp=fertige;
	} else {
	  Sprache altSpr=TxBp->lgn;
		for(int akts=0;akts<SprachZahl;akts++) {
			TxBp->lgn=(Sprache)akts;
			bemst=(*TxBp)[Tind];
			if (obfarbe) loeschefarbenaus(&bemst);
			bemv<<bemst;
		} //         for(int akts=0;akts<SprachZahl;akts++)
		TxBp->lgn=altSpr;
		vp=&bemv;
	} // if fertige else
  for(size_t ind=0;ind<schl.size();ind++) {
    if (schl[ind]->pname==pname) {
     uchar gefunden{0};
     if (schl[ind]->bemerk.empty())
       gefunden=1;
     else {
       const string bv{schl[ind]->bemerk.substr(2)};
       for(int aktsp=0;aktsp<SprachZahl;aktsp++) {
         if (bv==(*vp)[aktsp]) {
           gefunden=(aktsp!=TxBp->lgn); // wenn aktuelle Sprache, nichts tun
           break;
         } // if (bv==bemv[aktsp]) 
       } // for(int aktsp=0;aktsp<SprachZahl;aktsp++) 
     } // (schl[ind].bemerk.empty) else
     if (gefunden) {
      schl[ind]->bemerk="# "+(*vp)[TxBp->lgn];
     }
    } //     if (schl[ind].pname==pname)
  } //   for(size_t ind=0;ind<zahl;ind++)
} // void schAcl::setzbemv(const string& pname,const string& bem)

// ruft die jeweilige Options-Routine zum Setzen des Woher-Flags mit dem Wert vwoher auf, ggf. fuer alle gleichnamigen Optionen
template<typename SCL> void schAcl<SCL>::setzbemerkwoher(SCL *optp,const string& ibemerk,const uchar vwoher)
{
 if (optp->pname.empty()) {
	 optp->virttusetzbemerkwoher(ibemerk,vwoher);
 } else {
	for (size_t i=0;i<schl.size();i++) {
		if (schl[i]->pname==optp->pname) {
			schl[i]->virttusetzbemerkwoher(ibemerk,vwoher);
		}
	} // 	for (size_t i=0;i<schl.size();i++)
 } //  if (optp->pname.empty())
} // template<typename SCL> void schAcl<SCL>::setzbemerkwoher

void optcl::virttusetzbemerkwoher(const string& ibemerk,const uchar vwoher)
{
	bemerk=ibemerk;
	// wenn gar nicht (0) oder ueber Vorgaben (1) festgelegt
	if (woher<2) woher=vwoher;
} // void optcl::virttusetzbemerkwoher

// woher-Flag gibts nicht
void wpgcl::virttusetzbemerkwoher(const string& ibemerk, const uchar vwoher)
{
}

string XOR(const string& value, const string& key)
{
  string retval{value};
  const size_t klen{key.length()}, vlen{value.length()};
	size_t k=0, v;
	for(v=0;v<vlen;v++) {
    retval[v]=value[v]^key[k];
    k=(++k<klen?k:0);
  } //   for(v=0;v<vlen;v++)
  return retval;
} // string XOR(const string& value, const string& key)

int cppschreib(const string& fname, WPcl *conf, size_t csize)
{
  mdatei f(fname,ios::out);
  if (f.is_open()) {
    for (size_t i=0;i<csize;i++) {
      f<<conf[i].pname<<" = \""<<conf[i].wert<<"\""<<endl;
    } //     for (size_t i=0;i<csize;i++)
    return 0;
  } //   if (f.is_open())
  return 1;
} // int cppschreib(const string& fname, WPcl *conf, size_t csize)

/*//
int multicppschreib(const string& fname, WPcl **conf, size_t *csizes, size_t cszahl)
{
  mdatei f(fname,ios::out);
  if (f.is_open()) {
    for (size_t j=0;j<cszahl;j++) {
      for (size_t i=0;i<csizes[j];i++) {
        f<<conf[j][i].pname<<" = \""<<conf[j][i].wert<<"\""<<endl;
      }
    }
    return 0;
  }
  return 1;
} // int multicppschreib(const string& fname, WPcl **conf, size_t *csizes, size_t cszahl)
*/

#ifdef notcpp
int Schschreib(const char *fname, Schluessel *conf, size_t csize)
{
#ifdef false
  uchar erfolg{0};
#endif // false
  mdatei f(fname,ios::out);
  if (!f.is_open()) { return 1; }
  for(size_t i=0;i<csize;i++) {
    f<<conf[i].key<<" = \""<<conf[i].val<<"\""<<endl;
  }
#ifdef false
#ifdef obfstream 
  fstream *f=oeffne(fname,3,&erfolg);
  if (!erfolg) return 1;
  for(size_t i=0;i<csize;i++) {
    *f<<conf[i].key<<" = \""<<conf[i].val<<"\""<<endl;
  } //   for(size_t i=0;i<csize;i++)
#else // obfstream 
  FILE *f=oeffne(fname,3,&erfolg);
  if (!erfolg) return 1;
  for (size_t i=0;i<csize;i++) {
    fprintf(f,"%s = \"%s\"\n",conf[i].key,conf[i].val);
  } // 	for (size_t i=0;i<csize;i++)
  fclose(f);
#endif // obfstream else
#endif	 // false
  return 0;
} //// int Schschreib(const char *fname, Schluessel *conf, size_t csize)
#endif // notcpp

// Dateiname ohne Pfad
string base_name(const string& path)
{
  return path.substr(path.find_last_of("/\\",path.find_first_of("><")) + 1);
} // string base_name(string const & path)

// Pfadname einer Datei
string dir_name(const string& path)
{
  const size_t letzt{path.find_last_of("/\\")};
	if (letzt==string::npos) return {};
  return path.substr(0,letzt);
} // string dir_name(string const & path)

// soll fuer den Fall eines uebergebenen 'rueck'-Zeigers den Rueckgabewert der aufgerufenen Funktion zuruckliefern,
// ausser bei 'find', da die Zahl der Funde
// bei rueck==0 liefert es das Ergebnis der system(..)-Funktion zurueck
// obverb: 1 = Befehl anzeigen, 2 = auch Rueckgabezeilen anzeigen, -1 = nur cmd ohne env mit Rueckgabezeilen anzeigen
// obergebnisanzeig: 1=falls Fehler und obverb>1, >1=falls Fehler
// cmd soll kein "sudo " am Anfang enthalten, falls noetig soll obsudc gesetzt werden. Innenliegende sudo-Befehle duerfen fuer den Cron-Aufruf 
//  nur den Pfad /usr/bin:/bin (fedora und ubuntu) bzw. /usr/bin:/usr/sbin:/sbin:/bin:/usr/lib/news/bin:/root/bin (opensuse) erwarten
int systemrueck(const string& cmd, int obverb/*=0*/, int oblog/*=0*/, vector<string> *rueck/*=0*/, const uchar obsudc/*=0*/,
    const int verbergen/*=0*/, int obergebnisanzeig/*wahr*/, const string& ueberschr/*=string()*/,vector<errmsgcl> *errm/*=0*/,uchar obincron/*=0*/,
		stringstream *ausgp/*=0*/,uchar obdirekt/*=0*/)
{
////	caus<<rot<<"cmd: "<<violett<<cmd<<schwarz<<endl;
// verbergen: 0 = nichts, 1= '2>/dev/null' anhaengen + true zurueckliefern, 2='>/dev/null 2>&1' anhaengen + Ergebnis zurueckliefern
	// die 'if (obverb||oblog)' sind zur Vermeidung von Rekursionen mit Endlosschleifen
  binaer ob0heissterfolg{wahr};
  uchar neurueck{0};
  uchar weiter{0};
  int erg{-111};
  string hcmd{cmd};
  const uchar obfind{cmd.substr(0,4)=="find"};
  if (verbergen==1 || (obfind && (obverb<1 || cus.cuid))) {
    if (obverb<=1) 
      hcmd+=" 2>/dev/null;:";
  } else if (verbergen==2) {
    if (obverb<=1)
      hcmd+=" >/dev/null 2>&1";
  } //   if (verbergen==1 || (obfind && (obverb<1 || strcmp(curruser(),"root")))) else iff
	if (obincron) {
    vector<string> tok;
    aufSplit(&tok,hcmd);
		if (tok.size()>0) {
		 if (obprogda(tok[0],obverb,oblog,&hcmd)) {
			for(unsigned j=1;j<tok.size();j++) {
			 hcmd+=' ';
			 hcmd+=tok[j];
			} // 			for(unsigned j=1;j<tok.size();j++)
		 } // 		 if (obprogda(tok[0],obverb,oblog,&hcmd))
		} // 		if (tok.size()>0)
	} // 	if (obincron)
  //// "obfind: "<<(int)obfind<<", obverb: "<<(int)obverb<<", curruser(): "<<curruser()<<", '"<<violett<<hcmd<<schwarz<<"'"<<endl;
  string smeld(Txk[T_Rueckmeldung]);
  string aktues;
  if (ueberschr.empty()) { 
    if (obfind) {
      aktues=Txk[T_Suchbefehl];
    } else {
      aktues=Txk[T_Fuehre_aus];
      weiter=1;
    } //     if (obfind)
  } else {
    aktues=ueberschr;
  } //   if (ueberschr.empty())
	const string tmpd0{P_tmpdir "/err_"+_DPROG+"_XXXXXX"};
	char tmpd[tmpd0.size()+1];
	strcpy(tmpd,tmpd0.c_str());
	const int mksterg{mkstemp(tmpd)};
	// '... 2>/dev/null' nicht unbedingt aufheben
	const string bef{(obsudc?sudc+(obsudc==2&&!sudc.empty()?"-H ":""):"")+
		(obdirekt?hcmd:"env PATH='"+spath+"' "+"sh -c '"+ersetzAllezu(hcmd,"'","'\\''")+"'"+
		 (mksterg!=-1&&(hcmd.find(" 2>")==string::npos||obverb>0)?string(" 2>")+tmpd:string()))};
	const string befanz{ersetze(bef.c_str(),spath.c_str(),"...")};
	const string hsubs{befanz.substr(0,getcols()-7-aktues.length())};
	string meld{aktues+": "+blau+hsubs+schwarz+" ..."};
	if (ausgp&&obverb>0) {
		*ausgp<<meld<<endl; 
		cout<<"ausgp: "<<violett<<ausgp->str()<<schwarz<<endl;
	} else { 
		if (obverb||oblog) fLog(meld,obverb>0?-1:0,oblog); 
	}
	if (!rueck) if (obergebnisanzeig) {neurueck=1;rueck=new vector<string>;}
	// #define systemrueckprofiler
#ifdef systemrueckprofiler
	perfcl prf("systemrueck");
#endif // systemrueckprofiler
	// obsudc==0 nichts, obsudc==1: "sudo ", obsudc==2: "sudo -H "
////	caus<<violett<<"bef: "<<blau<<bef<<schwarz<<endl;
	if (rueck) {
		//// <<gruen<<bef<<schwarz<<endl;
    if (FILE* pipe{popen(bef.c_str(),"r")}) {
		/*//
		int fd=fileno(pipe);
		int flags=fcntl(fd, F_GETFL, 0);
		flags|=O_NONBLOCK;
		fcntl(fd, F_SETFL, flags);
		*/
#ifdef systemrueckprofiler
      prf.ausgeb();
#endif
      ////    setvbuf ( pipe, NULL, _IOFBF, 2048);
      /*//
         int fd = fileno(pipe);
         int flags;
         flags = fcntl(fd, F_GETFL, 0);
         flags |= O_NONBLOCK;
         fcntl(fd, F_SETFL, flags);
       */
      ////      unsigned int zeile=0;
      while(1) {
#ifdef systemrueckprofiler
        prf.ausgab1000("in while");
#endif
        if (feof(pipe)) break;
        ////        zeile++;
        char buffer[1280];
        //// in der folgenden Zeile werden auch ggf. sterr-Meldungen ausgegeben/weitergeleitet
				// hier braucht er lang, wenn das System langsam ist
        if (fgets(buffer, sizeof buffer, pipe)) { 
          size_t posi;
          if (buffer[posi=strlen(buffer)-1]==10) buffer[posi]=0;
          rueck->push_back(string(buffer));
        } // if(fgets(buffer, sizeof buffer, pipe) != NULL)
        if (feof(pipe)) break;
      } // while(1) 
#ifdef systemrueckprofiler
      prf.ausgab1000("nach while");
#endif
      if (obverb>1 || oblog || obergebnisanzeig) if (rueck->size()) {
        for(unsigned i=0;i<rueck->size();i++) {
#ifdef systemrueckprofiler
#endif
          smeld=smeld+"\n"+tuerkis+rueck->at(i)+schwarz;
        } //         for(unsigned i=0;i<rueck->size();i++)
      } //       if (obverb>1 || oblog || obergebnisanzeig) if (rueck->size())
#ifdef systemrueckprofiler
      if (obverb||oblog) fLog(rots+"Rueck.size: "+ltoan(rueck->size())+", obergebnisanzeig: "+(obergebnisanzeig?"ja":"nein"),1,oblog);
			if (ausgp) *ausp<<bef<<endl; else { if (obverb||oblog) fLog(bef,1,oblog); }
			prf.ausgab1000("vor pclose");
#endif
			erg = pclose(pipe);
			if (obfind) {
        erg=rueck->size();
      } else 
			  erg/=256;
#ifdef systemrueckprofiler
      prf.ausgab1000("nach pclose");
#endif
    } else {
      perror((string("popen() ")+Txk[T_fehlgeschlagen_bei]+hcmd).c_str());
      erg=1;
    } //     if (FILE* pipe = popen(hcmd.c_str(), "r"))  else 
  } else {
    erg=system(bef.c_str());
  } // if (rueck) else
	// temporäre Datei loeschen, falls leer
	struct stat tmpdst{0};
	if (!lstat(tmpd,&tmpdst)) if (!tmpdst.st_size) tuloeschen(tmpd,string(),0,0);
  int erg2 __attribute__((unused)){system(string("printf ' %.0s' {1.."+ltoan(getcols()-2)+"};printf '\r';").c_str())};
#ifdef systemrueckprofiler
  prf.ausgab1000("vor weiter");
#endif
	if (weiter) aktues=Txk[T_Fuehrte_aus];
	if (obverb>0 || oblog) {
		string ergebnis;
		if (errm) {
			for(size_t i=0;i<errm->size();i++) {
				if (erg==errm->at(i).errnr) {
					ergebnis=(erg?rots:gruens)+ltoan(erg)+": "+gruen+errm->at(i).msg;
					break;
				} // 				if (erg==errm->at(i).errnr)
			} // for(size_t i=0;i<errm->size();i++) 
		}  // if (errm)
		if (ergebnis.empty()) {
			if (obfind) {
				ergebnis=gruens+ltoan(erg)+blau+Txk[T_Zeilen];
			} else {
				if (ob0heissterfolg) {
					if (erg) {
						if (cmd.substr(0,6)=="rpm -q" || cmd.substr(0,7)=="dpkg -s" || 
						    cmd.substr(0,5)=="which" || cmd.substr(0,11)=="iptables -L" ||
								(cmd.find("grep")!=string::npos && cmd.find(" -q <("+sudc+"crontab -l")!=string::npos) ||
							  cmd.substr(0,7)=="test -f" ||
								cmd.substr(0,20)=="systemctl list-units" || cmd.substr(0,10)=="pdbedit -L" ||
                cmd.find("faxstat|grep")!=string::npos
								) {
							ergebnis=gruens+Txk[T_nicht_gefunden];
						} else if (cmd.substr(0,9)=="modprobe ") {
						  ergebnis=gruens+Txk[T_nicht_einfuegbar];
							// das Ende einer awk-Berechnung reeller Zahlen und Pruefung auf Negativitaet:
						} else if (cmd.find("|grep -q ^-")!=string::npos) {
						  ergebnis=blaus+ltoan(erg);
						} else {
							ergebnis=rots+Txk[T_Exitcode]+ltoan(erg);
						}
						if (obverb>=0) obergebnisanzeig=wahr;
						if (obverb>0) obverb++;
					} else {
						ergebnis=Txk[T_Erfolg];
					} // ob0heissterfolg else
				} else {
					ergebnis=ltoan(erg);
				} // 				if (ob0heissterfolg) else
			} // 			if (obfind) else
		} //     if (ergebnis.empty()
#ifdef systemrueckprofiler
    prf.ausgab1000("vor log");
#endif
		meld=aktues+": "+blau+befanz+schwarz+Txk[T_komma_Ergebnis]+blau+ergebnis+schwarz;
		if (ausgp&&obverb>0) { 
			*ausgp<<meld<<endl; 
		} else { 
			if (obverb||oblog) {
				fLog(meld,obverb>0?obverb:0,oblog); 
			}
		}
		int erg3 __attribute__((unused)){system((string("FLR=")+tmpd+";[ -s $FLR ]&&{ printf '\r"+rot+"';cat $FLR;printf '"+schwarz+"';}").c_str())};
	} // if (obverb>0 || oblog)
	if (rueck) {
		if (obergebnisanzeig && rueck->size()) {
			if (ausgp&&obverb>0) {
				*ausgp<<smeld<<endl; 
			} else { 
				if (obverb||oblog) {
					fLog(smeld,obverb>1||(ob0heissterfolg && erg && obergebnisanzeig>1),oblog); 
				}
			}
		} // 	if (obergebnisanzeig && rueck->size())
		if (obverb==-1) {
			cout<<blau<<cmd<<schwarz<<":"<<endl;
			for(auto rzl:*rueck) {
				cout<<rzl<<endl;
			}
		}
		if (neurueck) {delete rueck;rueck=0;}
	} // 	if (rueck)
	return erg; 
} // int systemrueck(const string& cmd, char obverb, int oblog, vector<string> *rueck, binaer ...

// ob das aktuelle Programm mehrfach laeuft; bei obstumm Exit-Code 0
void pruefmehrfach(const string& wen,int obverb/*=0*/,uchar obstumm/*=0*/)
{
	fLog(violetts+Txk[T_pruefmehrfach]+schwarz,obverb,0);
	const long smax{3600}; // maximal tolerierte Sekundenzahl, bevor statt dem eigenen Prozess der andere abgebrochen wird
	svec rueck;
	const string iwen{wen.empty()?base_name(meinpfad()):wen};
	// bei valgrind steht z.B. 'memecheck-amd64-' am Anfang
	// gdb macht einen zusaetzlichen Prozess
	systemrueck("ps -eo comm,args,etimes,pid|grep -P 'valgrind.*"+iwen+"|^"+iwen+"'| grep -P '"+iwen+"([[:space:]]|\\z)'",obverb,0,&rueck,/*obsudc=*/0);
	long sek{0};
	for(int aru=0;aru<3;aru++) {
		if (rueck.size()==1) // ich
			break;
		if (aru<2) {
			for(unsigned iru=0;iru<rueck.size();iru++) {
				// z.B. 'autofax      57  2939'
				svec pvec;
				aufSplit(&pvec,rueck[iru],' ',/*auchleer=*/0); 
				if (pvec.size()>2 && pvec[2]!=ltoan(getpid())) { // und wenn nicht ich
					sek=atol(pvec[1].c_str());
					if (sek>smax) {    // wenn es mindestens eine Stunde laeuft
						cout<<Txk[T_Program]<<blau<<iwen<<schwarz<<Txk[T_laueft_schon_einmal_aber]<<" "<<rot<<sek<<schwarz<<" s (> "<<blau<<smax<<schwarz<<" s), "<<Txk[T_wird_deshalb_abgebrochen]<<endl;
						if (!systemrueck(string("kill ")+(aru?"-9 ":"")+pvec[2]+" 2>/dev/null",obverb,0,0,/*obsudc=*/1)) {
							rueck.erase(rueck.begin()+iru);
							continue;
						}
					} // 				if (sek>15)
				} // 			if (pvec.size()>2)
			} // 		for(int iru=0;iru<rueck.size();iru++)
			// if (aru<2)
		} else {
			if (obstumm)
				exit(schluss(0));
			exit(schluss(98,Txk[T_Program]+blaus+wen+schwarz+Txk[T_laeuft_schon_einmal_seit]+blau+ltoan(sek)+" "+schwarz+Txk[T_sec_Breche_ab],/*oblog*/0));
		} // if (aru<2) else
	} // 	for(int aru=0;aru<3;aru++) 
	/*//
		for(size_t j=0;j<rueck.size();j++) KLA
	// <<violett<<"rueck["<<j<<"]: "<<rot<<rueck[j]<<schwarz<<endl;
	KLZ
	 */
	/*
		 int fd;
		 char buff[128];
		 char *p;
		 unsigned long uptime;
		 struct timeval tv;
		 static time_t boottime;


		 if ((fd = open("/proc/uptime", 0)) != -1)
		 {
		 if (read(fd, buff, sizeof(buff)) > 0)
		 {
		 uptime = strtoul(buff, &p, 10);
		 gettimeofday(&tv, 0);
		 boottime = tv.tv_sec - uptime;

		 }
		 close(fd);
		 }


		 ifstream procFile;
		 procFile.open("/proc/[INSERT PID HERE]/stat");

		 char str[255];
		 procFile.getline(str, 255);  // delim defaults to '\n'


		 vector<string> tmp;
		 istringstream iss(str);
		 copy(istream_iterator<string>(iss),
		 istream_iterator<string>(),
		 back_inserter<vector<string> >(tmp));

		 process_time = (now - boottime) - (atof(tmp.at(21).c_str()))/HZ;
	 */
	fLog(violetts+Txk[T_Ende]+Txk[T_pruefmehrfach]+schwarz,obverb,0);
} // void pruefmehrfach

// aufgerufen in: setfaclggf, pruefberecht, pruefverz
int untersuser(const string& uname,__uid_t *uidp/*=0*/, __gid_t *gidp/*=0*/,vector<gid_t> *gids/*=0*/,struct passwd* ustr/*=0*/)
{
	struct passwd pwd{0};
	struct passwd *result;
	char *buf;
	ssize_t bufsize;
	int erg{1};
	if (gids) gids->clear();
	if ((bufsize = sysconf(_SC_GETPW_R_SIZE_MAX))==-1) bufsize=16384;
	if ((buf = (char*)malloc(bufsize))) {
		/*//int s = */getpwnam_r(uname.c_str(), &pwd, buf, bufsize, &result);
		if (result) {
			if (ustr) memcpy(ustr,&pwd,sizeof *ustr);
			if (uidp) *uidp=pwd.pw_uid;
			//if (gidp) *gidp=pwd.pw_gid;
			if (gidp) {
				*gidp=pwd.pw_gid;
				int ngroups{20};
				gid_t *groups{0};
				for(uchar iru=0;iru<2;iru++) {
					groups=(gid_t*)malloc(ngroups*sizeof *groups);
					if (getgrouplist(uname.c_str(), pwd.pw_gid, groups, &ngroups)!=-1) break;
					free(groups);
				}
				// die Gruppe mit der groessten Nummer verwenden	
				for(int iru=0;iru<ngroups;iru++) {
					if (gids) gids->push_back(groups[iru]);
					if (groups[iru]>*gidp) *gidp=groups[iru];
				}
				free(groups);
			}
			////	KLZ else KLA if (!s) printf("Not found\n"); else KLA errno = s; perror("getpwnam_r"); KLZ
		}	
		free(buf);
	} else {
		erg=1;
		perror("malloc");
	} // 	if ((buf = (char*)malloc(bufsize))) else 
	return erg;
} // int untersuser(string uname,__uid_t *uid/*=0*/, __gid_t *gid/*=0*/)


// <datei> kann auch Verzeichnis sein
// obunter = mit allen Unterverzeichnissen
// obimmer = immer setzen, sonst nur, falls mit getfacl fuer datei Berechtigung fehlt (wichtig fuer Unterverzeichnisse)
// return: 0=setfacl-Programm nicht da, 1=da
int setfaclggf(const string& datei,int obverb/*=0*/,int oblog/*=0*/,const binaer obunter/*=falsch*/,int mod/*=4*/,uchar obimmer/*=0*/,
		uchar faclbak/*=1*/,const string& user/*=string()*/,uchar fake/*=0*/,stringstream *ausgp/*=0*/,const uchar obprot/*=1*/)
{
	static int obsetfacl{-1};
	if (obverb && !ausgp) {
		fLog(violetts+"setfaclggf()"+blau+Txk[T_Datei]+blau+datei+schwarz+Txk[T_obunter]+blau+(obunter?"1":"0")+schwarz+", mod: "+
				blau+ltoan(mod)+schwarz+", obimmer: "+blau+(obimmer?"1":"0")+schwarz+", faclbak: "+blau+(faclbak?"1":"0")+schwarz+
				Txk[T_Benutzer]+blau+user+schwarz+", fake: "+blau+(fake?"1":"0")+schwarz,obverb,oblog);
	}
	////	int altobv=obverb;
	////	if (fake) obverb=2;
	if (obunter) mod|=1; // Verzeichnisberechtigung noetig
	uid_t cuid;
	gid_t cgid;
	string cuser;
	if (user.empty()) {
		cuser=cus.cusstr;
		cuid=cus.cuid;
		cgid=cus.cgid;
	} else {
		cuser=user;
		untersuser(cuser,&cuid,&cgid);
	} // 	if (user.empty())
	// fuer root braucht's es ned
	if (cuid) {
    if (obsetfacl==-1) {
			for(int i{0};i<2;i++) {
				obsetfacl=obprogda("setfacl",obverb>0?obverb-1:0,/*obprog=*/0);
				if (obsetfacl||i) break;
				linstp->doinst("acl",obverb,oblog);
			}
		}
		if (obsetfacl) {
			string aktdat{datei};
			svec pfade;
			do {
				pfade<<aktdat;
				aktdat=dir_name(aktdat);
			} while (!aktdat.empty());
			for(size_t i=pfade.size();i;) {
				i--;
				struct stat st{0};
				int ergmod{0};
				uchar obhier{obimmer};
				if (lstat(pfade[i].c_str(),&st)) 
					break;
				if (i) {
					if (!((st.st_mode&S_IXOTH)||((st.st_gid==cgid)&&(st.st_mode&S_IXGRP))||((st.st_uid==cuid)&&(st.st_mode&S_IXUSR)))) {
						// erteile Ausfuehr-Rechte fuer Verzeichnis, sonst geht darunter nichts
						ergmod=1;
					} // if (!((st.st_mode ...
				} else {
					if (((mod&1) &&
								(!((st.st_mode&S_IXOTH)||((st.st_gid==cgid)&&(st.st_mode&S_IXGRP))||((st.st_uid==cuid)&&(st.st_mode&S_IXUSR))))
							) || ((mod&2) &&
								(!((st.st_mode&S_IWOTH)||((st.st_gid==cgid)&&(st.st_mode&S_IWGRP))||((st.st_uid==cuid)&&(st.st_mode&S_IWUSR))))
								) || ((mod&4) &&
									(!((st.st_mode&S_IROTH)||((st.st_gid==cgid)&&(st.st_mode&S_IRGRP))||((st.st_uid==cuid)&&(st.st_mode&S_IRUSR))))
									) ) {
						ergmod=mod;
					} // if (((mod&1 ...
				} // if (i) else
				if (ergmod) {
					string modbuch;
					if (ergmod&4) modbuch+="r"; else modbuch+=" ";
					if (ergmod&2) modbuch+="w"; else modbuch+=" ";
					if (ergmod&1) modbuch+="x"; else modbuch+=" ";
					// bei hinfuehrenden Verzeichnissen fehlende Rechte immer ueberpruefen
					if (i||!obhier) {
						////						svec gstat;
						////						systemrueck("getfacl -e -t '"+pfade[i]+"' 2>/dev/null | grep 'user[ \t]*"+cuser+"[ \t]*"+modbuch+"'||:",obverb,oblog,&gstat);
						////						obhier = !gstat.size();// wenn keine Berechtigung gefunden => erstellen
						obhier=pruefberecht(pfade[i],cuser,ergmod);
					} //        if (i||!obhier)
					if (obhier) {
						if (obverb) systemrueck("ls -ld \""+pfade[i]+"\"",2,0,/*rueck=*/0,/*obsudc=*/1);
						if (faclbak) {
							const string sich{base_name(pfade[i])+"."+base_name(meinpfad())+".perm"},
										bef{"cd \""+dir_name(pfade[i])+"\";test -f \""+sich+"\"||getfacl -R \""+base_name(pfade[i])+"\">\""+sich+"\""};
							systemrueck(bef,obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
							struct stat st{0};
							string para{"setfacl --restore=\""+sich+"\""};
							if (lstat(sich.c_str(),&st) || !st.st_size) {
								para=string(sudc+"setfacl -")+(!i && obunter?"R":"")+"b \""+pfade[i]+"\"";
							}
							if (obprot) anfgg(unindt,sudc+"sh -c 'cd \""+dir_name(pfade[i])+"\";"+para+"'",bef,obverb,oblog);
						} // 					if (faclbak)
						if (obverb>1) systemrueck("ls -ld \""+pfade[i]+"\"",2,0,/*rueck=*/0,/*obsudc=*/1);
						if (pfade[i]=="uvz/uuvz/uuuvz") 
							exit(schluss(20,Txk[T_Fehler_in_setfaclggf]+blaus+pfade[i]+"=="+"uvz/uuvz/uuuvz"+schwarz));
						const string cmd{string("setfacl --mask -")+(!i && obunter?"R":"")+"m 'u:"+cuser+":"+ltoan(ergmod)+"' '"+pfade[i]+"'"};
						if (fake) { 
							if (obverb||oblog) 
								fLog(rots+cmd+schwarz,obverb,oblog); 
						} else {
							systemrueck(cmd,obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
						}
						if (obverb) systemrueck("ls -ld \""+pfade[i]+"\"",2,0,/*rueck=*/0,/*obsudc=*/1);
					} //        if (obhier)
				} // 				if (ergmod)
			} // 			for(size_t i=pfade.size()-1;i>-1;--i)
		} // 			if (obsetfacl)
	} // 	if (cuid)
	////	if (fake) obverb=altobv;
	if (obverb>1 && !ausgp) {
		fLog(violetts+Txk[T_Ende]+" setfaclggf()"+blau+Txk[T_Datei]+blau+datei+schwarz+Txk[T_obunter]+blau+(obunter?"1":"0")+schwarz+", mod: "+
				blau+ltoan(mod)+schwarz+", obimmer: "+blau+(obimmer?"1":"0")+schwarz+", faclbak: "+blau+(faclbak?"1":"0")+schwarz+
				Txk[T_Benutzer]+blau+user+schwarz+", fake: "+blau+(fake?"1":"0")+schwarz,obverb,oblog);
	}
	return obsetfacl;
} // int setfaclggf(const string& datei, const binaer obunter, const int mod, binaer obimmer,int obverb, int oblog)


// 0=Berechtigung vorhanden, 1= benutzer=Besitzer, 2= benutzer gehoert zur Besitzergruppe, 3=Benutzer gibt's nicht, 4= nichts davon
int pruefberecht(const string& datei,const string& benutzer,const mode_t mod/*=01*/,int obverb/*=0*/)
{
	int bererg{0};
	const auto pwnamzg{getpwnam(benutzer.c_str())};
	if (pwnamzg) {
		const uid_t uid{pwnamzg->pw_uid};
		gid_t gid;
		vector<gid_t> gids;
		struct stat sdat{0};
		if (!benutzer.empty() && uid) {
			bererg=4;
			if (!lstat(datei.c_str(),&sdat)) {
				if ((~mod&4||sdat.st_mode & S_IROTH)&&
						(~mod&2||sdat.st_mode & S_IWOTH)&&
						(~mod&1||sdat.st_mode & S_IXOTH)) {
					bererg=0;
				} // 		if ((~mod&4||sdat.st_mode & S_IROTH)&&
				if (uid==sdat.st_uid) {
					bererg=1;
					if ((~mod&4||sdat.st_mode & S_IRUSR)&&
							(~mod&2||sdat.st_mode & S_IWUSR)&&
							(~mod&1||sdat.st_mode & S_IXUSR)) {
						bererg=0;
					} // 			if ((~mod&4||sdat.st_mode & S_IRUSR)&&
				} // 		if ((uid=getpwnam(benutzer.c_str())->pw_uid)==sdat.st_uid)
				untersuser(benutzer,0,&gid,&gids);
				for(unsigned i{0};i<gids.size();i++) {
					if (gids[i]==sdat.st_gid) {
						bererg=2;
						if ((~mod&4||sdat.st_mode & S_IRGRP)&&
								(~mod&2||sdat.st_mode & S_IWGRP)&&
								(~mod&1||sdat.st_mode & S_IXGRP)) {
							bererg=0;
						} // 				if ((~mod&4||sdat.st_mode & S_IRGRP)&&
					} // 			if (gids[i]==sdat.st_gid) 
				} // 		for(unsigned i=0;i<gids.size();i++)
				if (bererg) {
					if (acl_t acl = acl_get_file(datei.c_str(), ACL_TYPE_ACCESS)) {
						for (int entryId = ACL_FIRST_ENTRY; ; entryId = ACL_NEXT_ENTRY) {
							acl_entry_t entry;
							if (acl_get_entry(acl, entryId, &entry) != 1)
								break;                      /* Exit on error or no more entries */
							acl_tag_t tag;
							if (acl_get_tag_type(entry, &tag) != -1) {
								int aclpruef{0};
								if (tag == ACL_USER) {
									if (uid_t *uidp = (uid_t*)acl_get_qualifier(entry)) {
										if (*uidp==uid) aclpruef=1;
										acl_free(uidp);
									} // 						if (uid_t *uidp = (uid_t*)acl_get_qualifier(entry))
								} else if (tag == ACL_GROUP) {
									if (gid_t *gidp = (gid_t*)acl_get_qualifier(entry)) {
										for(unsigned i=0;i<gids.size();i++) {
											if (gids[i]==*gidp) {
												aclpruef=1;
												break;
											} // 								if (gids[i]==*gidp)
										} // 							for(unsigned i=0;i<gids.size();i++)
										acl_free(gidp);
									} // 						if (gid_t *gidp = (gid_t*)acl_get_qualifier(entry))
								} else {
									continue;
								} // 					if (tag == ACL_USER) else
								if (aclpruef) {
									acl_permset_t permset;
									if (acl_get_permset(entry, &permset) != -1) {
										if ((~mod&4||acl_get_perm(permset, ACL_READ)==1)&&
												(~mod&2||acl_get_perm(permset, ACL_WRITE)==1)&&
												(~mod&1||acl_get_perm(permset, ACL_EXECUTE)==1)) {
											bererg=0;
											break;
										} // 							if ((~mod&4||acl_get_perm(permset, ACL_READ)==1)&&
									} // 			if (acl_get_permset(entry, &permset) != -1)
								} // 					if (aclpruef)
							} // 		if (acl_get_tag_type(entry, &tag) != -1)
						} // 	for (int entryId = ACL_FIRST_ENTRY; ; entryId = ACL_NEXT_ENTRY)
						acl_free(acl);
					} // 		if (acl_t acl = acl_get_file(datei.c_str(), ACL_TYPE_ACCESS))
				} // 			if (bererg) 
			} // 	if (!lstat(datei.c_str(),&sdat))
		} // benutzer.empty()
	} else {
		bererg=3; // Benutzer gibt es nicht
	}
	if (obverb) {
		fLog(violetts+Txk[T_pruefberecht]+schwarz+Txk[T_Datei]+blau+datei+schwarz+Txk[T_Benutzer]+blau+benutzer+schwarz+", mode: "+blau+ltoan(mod,8)+
				schwarz+Txk[T_Erg]+blau+(bererg==3?"3":bererg==2?"2":bererg==1?"1":"0")+schwarz,obverb,0);
	}
	return bererg;
} // int pruefberecht(const string& datei,const string& benutzer,const mode_t mod/*=01*/)

// obmitfacl: 1= setzen, falls noetig, >1= immer setzen
// falls Benutzer root
// wenn !besitzer.empty(), dann wird das letzte und alle neu zu erstellenden Verzeichnisse diesem zugeordnet 
int pruefverz(const string& verz,int obverb/*=0*/,int oblog/*=0*/, uchar obmitfacl/*=0*/,uchar obmitcon/*=0*/, 
		const string& besitzer/*=string()*/, const string& benutzer/*=string()*/,const uchar obmachen/*=1*/,const uchar obprot/*=1*/)
{
	if (obverb||oblog) fLog(violetts+"pruefverz("+blau+verz+schwarz+")",obverb,oblog);
	static int obselinux{-1}; // -1=ununtersucht, 0=kein Selinux da, 1=Selinux da
	int fehlt{1};
	// wenn nicht root, dann alten Modus merken
	string modstr{"700"};
	mode_t altmod=022,mod=S_IRWXU;
	string aktben{(benutzer.empty()?(getpwuid(getuid())->pw_name):benutzer)};
	if (!verz.empty()) {
		uid_t uid;
		gid_t gid;
		if(!besitzer.empty()){
			untersuser(besitzer,&uid,&gid);
			altmod=umask(0); // => neue Dateien ohne Berechtigungseinschraenkung
		} // 	if(!besitzer.empty())
		string aktv{verz};
		svec stack;
		do {
			stack<<aktv;
			aktv=dir_name(aktv);
		} while (!aktv.empty());
		for(int i=stack.size()-1;i>=0;i--) {
			fehlt=1;
			struct stat sverz={0};
			if (!lstat(stack[i].c_str(),&sverz)) {
				if(S_ISDIR(sverz.st_mode)) {
					fehlt=0;
				} else {
					if (obmachen) {
						// falls Datei mit Namen eines benoetigten Verzeichnisses und obmachen, dann loeschen
						tuloeschen(stack[i],{},obverb,oblog);
					} // 					if (obmachen)
				} // 				if(S_ISDIR(sverz.st_mode)) else
			} // 				if (!lstat(stack[i].c_str(),&sverz))
			if (obmachen) {
				if (fehlt) {
					if (!besitzer.empty()) {
						mod=(i?0100:0700);
						modstr=(i?"0100":"0700");
					}
					string bef{"mkdir -m "+modstr+" '"+stack[i]+"'"};
					if (!besitzer.empty()) bef+=";chown -R "+besitzer+":"+ltoan(gid)+" '"+stack[i]+"' 2>/dev/null";
					if (obverb||oblog) fLog(blaus+"mkdir("+stack[i]+","+ltoan(mod,8)+")"+schwarz,obverb,oblog);
					fehlt=mkdir(stack[i].c_str(),mod);
					if (!fehlt && !besitzer.empty()) {
						fehlt=chown(stack[i].c_str(),uid,gid);
					}
					if (fehlt) {
						fehlt=systemrueck(bef,obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
					}
					if (!fehlt) {
						if (unindt.find(stack[i])) { // wenn der Anfang nicht identisch ist, also nicht das Verzeichnis von unindt geprueft werden soll
							anfgg(unindt,sudc+"rmdir '"+stack[i]+"'",bef,obverb,oblog);
						}
					}
				} // 					if (fehlt)
				// folgendes mindestens notwendig fuer sverz.st_mode
				fehlt=lstat(stack[i].c_str(),&sverz);
				// wenn notwendige Rechte fehlen ...
				if (int prueferg{pruefberecht(/*datei=*/stack[i],aktben,/*mod=*/i?1:7,obverb)}) {
					// .. und korrigiert werden sollen
					if (obmitfacl) {
						setfaclggf(stack[i],obverb>1?obverb-1:0,oblog, /*obunter=*/wahr, /*mod=*/i?1:7, /*obimmer=*/1,/*faclbak=*/1,/*user=*/aktben,/*fake*/0,/*ausgp*/0,obprot);
					} else {
						// dann Rechte in der notwendigen Spezifitaet erweitern
						// 0=Berechtigung vorhanden, 1= benutzer=Besitzer, 2= benutzer gehoert zur Besitzergruppe, 3= nichts davon
						const string altmod{ltoan(sverz.st_mode,8)};
						switch (prueferg) {
							case 1:
								sverz.st_mode|=(i?S_IXUSR:S_IRUSR+S_IWUSR+S_IXUSR);
								modstr=i?"u+x":"u+rwx";
								break;
							case 2:
								sverz.st_mode|=(i?S_IXGRP:S_IRGRP+S_IWGRP+S_IXGRP);
								modstr=i?"g+x":"g+rwx";
								break;
							case 3:
							case 4:
								sverz.st_mode|=(i?S_IXOTH:S_IROTH+S_IWOTH+S_IXOTH);
								modstr=i?"o+x":"o+rwx";
								break;
						}
						if (obverb||oblog) fLog(Txk[T_datei]+blaus+stack[i].c_str()+schwarz+", mode: "+blau+altmod+schwarz+" -> "+blau+
								ltoan(sverz.st_mode,8)+schwarz,obverb,oblog);
						if (chmod(stack[i].c_str(),sverz.st_mode)) {
							//             if (1) 
							string bef{"chmod "+modstr+" '"+stack[i]+"'"};
							fehlt=systemrueck(bef,obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
						}
					}
					if (obverb) systemrueck("ls -ld \""+stack[i]+"\"",2,0,/*rueck=*/0,/*obsudc=*/1);
				} // 					if (int prueferg=pruefberecht(/*datei=*/stack[i],aktben,/*mod=*/i?1:7))
			} // 				if (obmachen)
			if (fehlt) {
				// sonst Ende
				break;
			}
		} // 		for(int i=stack.size()-1;i>=0;i--) 
		if (!besitzer.empty()) {
			umask(altmod);
		}
		if (obmitcon) {
			if (obselinux==-1) 
				obselinux=obprogda("sestatus",obverb,oblog);
			if (obselinux) {
				systemrueck("chcon -R -t samba_share_t '"+verz+"'",obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
			}
		} // 		if (obmitcon)
	} // 	if (!verz.empty())
	if (obverb||oblog) fLog(violetts+Txk[T_Ende]+"pruefverz("+blau+verz+schwarz+")",obverb,oblog);
	return fehlt;
} // void pruefverz(const string& verz,int obverb,int oblog)


// verwendet in: virtlieskonfein
string aktprogverz()
{
	char pBuf[300];
#if defined(__MINGW32__) || defined(_MSC_VER)
	const int bytes{GetModuleFileName(NULL, pBuf, sizeof pBuf)};
	if(bytes == 0) pBuf[0]=0;
#elif linux
	char szTmp[32];
	sprintf(szTmp, "/proc/%d/exe", getpid());
	const ssize_t bytes{MIN(readlink(szTmp, pBuf, sizeof pBuf), sizeof pBuf - 1)};
	if(bytes >= 0) pBuf[bytes] = 0;
#endif
	return pBuf;
} // string aktprogverz()

char Tippbuchst(const string& frage, const string& moegl,const char *berkl[], const char* erlaubt, const char *vorgabe) 
{
	string input;
	if (!erlaubt) erlaubt=moegl.c_str();
	pthread_mutex_lock(&getmutex);
	while(1) {
		cout<<blau<<frage<<schwarz<<" (";
		for(unsigned i=0;i<moegl.length();i++) {
			cout<<"'"<<drot<<moegl[i]<<schwarz<<"'";
			if (berkl) cout<<" = "<<blau<<berkl[i]<<schwarz;
			if (i<moegl.length()-1) cout<<", ";
		} //     for(unsigned i=0;i<moegl.length();i++)
		cout<<")"<<(!vorgabe?"":"['"+tuerkiss+vorgabe+schwarz+"']")<<"?: ";
		input.clear();
		getline(cin,input);
		if (cin.fail()) { cin.clear(); cin.ignore(numeric_limits<streamsize>::max(), '\n'); }
		if (input.empty() && vorgabe) {input=vorgabe;break;}
		if (input[0]) if (strchr(erlaubt,(int)input[0])) break;
	} //   while(1)
	pthread_mutex_unlock(&getmutex);
	return input[0];
	////  return Tippbuchst(frage.c_str(), moegl.c_str(), berkl, erlaubt, vorgabe);
} // char Tippbuchst(const string& frage, const string& moegl,const char *berkl[], const char* erlaubt, const char *vorgabe) 


// vorgabe fur vorgabe = T_j_k; alternativ='n'
uchar Tippob(const string& frage,const char *vorgabe) 
{
	char erg=Tippbuchst(frage, string(Txk[T_j_k])+"n",0,"jJyYoOsSnN",vorgabe);
	return (!!strchr("jyJYoOsS",(int)erg));
} // uchar Tippob(const string& frage,const char *vorgabe) 

// bisher nicht verwendet, 15.12.15
string Tippstrs(const char *const frage, const char* const moegl[], const char *const vorgabe/*=0*/)
	// das letzte Element von moegl muss 0 sein
{
	string input;
	pthread_mutex_lock(&getmutex);
	while(1) {
		char passt=0;
		cout<<blau<<frage<<schwarz<<" (";
		for(unsigned i=0;moegl[i];i++) {
			if (i) cout<<", ";
			cout<<"'"<<drot<<moegl[i]<<schwarz<<"'";
		}
		cout<<")"<<(vorgabe?"":"['"+tuerkiss+vorgabe+schwarz+"']")<<"?: ";
		input.clear();
		getline(cin,input);
		if (cin.fail()) { cin.clear(); cin.ignore(numeric_limits<streamsize>::max(), '\n'); }
		//// <<rot<<"input: '"<<input<<"', vorgabe: '"<<vorgabe<<"'"<<endl<<schwarz;
		if (input.empty() && vorgabe) {input=vorgabe;break;}
		if (input[0]) {
			for(unsigned i=0;moegl[i];i++) {
				if (!strcmp(moegl[i],input.c_str())) {passt=1;break;}
			}
		} //     if (input[0])
		if (passt) break; 
	} //   while(1)
	pthread_mutex_unlock(&getmutex);
	return input;
} // Tippstrs

string Tippstrs(const char *frage, const vector<string> *const moegl, const string *const vorgabe/*=0*/)
{
	string input;
	pthread_mutex_lock(&getmutex);
	while(1) {
		char passt=0;
		cout<<blau<<frage<<schwarz<<" (";
		for(unsigned i=0;i<moegl->size();i++) {
			if (i) cout<<",";
			////      cout<<"'"<<drot<<moegl->at(i)<<schwarz<<"'";
			cout<<drot<<moegl->at(i)<<schwarz;
		} //     for(unsigned i=0;i<moegl->size();i++)
		cout<<")"<<(vorgabe->empty()?"":"['"+tuerkiss+*vorgabe+schwarz+"']")<<"?: ";
		input.clear();
		getline(cin,input);
		if (cin.fail()) { cin.clear(); cin.ignore(numeric_limits<streamsize>::max(), '\n'); }
		//// <<rot<<"input: '"<<input<<"', vorgabe: '"<<*vorgabe<<"'"<<endl<<schwarz;
		if (input.empty() && !vorgabe->empty()) {input=*vorgabe;break;}
		if (input[0]) {
			for(unsigned i=0;i<moegl->size();i++) {
				if (moegl->at(i)==input) {passt=1;break;}
			}
		} //     if (input[0])
		if (passt) break; 
	} //   while(1)
	pthread_mutex_unlock(&getmutex);
	return input;
} // Tippstrs


string Tippzahl(const char *const frage, const char *const vorgabe/*=0*/) 
{
	string input;
	pthread_mutex_lock(&getmutex);
	while(1) {
		cout<<blau<<frage<<schwarz<<(!vorgabe?"":" ["+tuerkiss+vorgabe+schwarz+"]")<<"? ";
		input.clear();
		getline(cin,input);
		if (cin.fail()) { cin.clear(); cin.ignore(numeric_limits<streamsize>::max(), '\n'); }
		if (input.empty() && vorgabe && *vorgabe) {input=vorgabe;break;}
		if (isnumeric(input)) break;
	} //   while(1)
	pthread_mutex_unlock(&getmutex);
	return input;
} // Tippzahl

string Tippzahl(const char *const frage, const string *const vorgabe) 
{
	return Tippzahl(frage,(vorgabe?vorgabe->c_str():0)); 
}
string Tippzahl(const string& frage, const string *const vorgabe)
{
	return Tippzahl(frage.c_str(),(vorgabe?vorgabe->c_str():0));
}
long Tippzahl(const string& frage,const long& vorgabe)
{
	string vgb=ltoan(vorgabe);
	return atol(Tippzahl(frage.c_str(),&vgb).c_str());
}
/*//
	char* Tippcstr(const char *frage, char* buf, unsigned long buflen, const char* vorgabe) 
	{
	const string vstr=vorgabe;
	strncpy(buf,Tippstr(frage,&vstr).c_str(),buflen-1);
	buf[buflen-1]=0;
	return buf;
	} // Tippcstr
 */
string Tippstr(const char *const frage, const string *const vorgabe,const uchar obnichtleer/*=1*/) 
{
	return Tippstr(string(frage), vorgabe,obnichtleer);
} // Tippstr

string Tippstr(const string& frage, const string *const vorgabe,const uchar obnichtleer/*=1*/) 
{
	string input;
	pthread_mutex_lock(&getmutex);
	while(1) {
		cout<<blau<<frage<<schwarz<<(!vorgabe || vorgabe->empty()?"":" [\""+tuerkiss+*vorgabe+schwarz+"\"]")<<"? ";
		input.clear();
		getline(cin,input);
		if (cin.fail()) { cin.clear(); cin.ignore(numeric_limits<streamsize>::max(), '\n'); }
		if (input.empty()) if (vorgabe) input=*vorgabe;
		if (input.empty()) {
			if (!obnichtleer) break;
		} else { 
			break;
		} // 		if (input.empty())
	} //   while(1)
	pthread_mutex_unlock(&getmutex);
	return input;
} // Tippstr

string Tippverz(const string& frage,const string *const vorgabe) 
{
	return Tippverz(frage.c_str(),vorgabe);
}

string Tippverz(const char *const frage,const string *const vorgabe) 
{
	string input;
	uchar fertig{0};
	const string vg2{"n"};
	while(1) {
		pthread_mutex_lock(&getmutex);
		cout<<blau<<frage<<schwarz<<(!vorgabe || vorgabe->empty()?"":" [\""+tuerkiss+*vorgabe+schwarz+"\"]")<<"? ";
		input.clear();
		getline(cin,input);
		if (cin.fail()) { cin.clear(); cin.ignore(numeric_limits<streamsize>::max(), '\n'); }
		if (input.empty() && vorgabe) {input=*vorgabe;}
		pthread_mutex_unlock(&getmutex);
		struct stat st={0};
		////    <<"input: '"<<rot<<input<<schwarz<<"'"<<endl;
		pthread_mutex_lock(&getmutex);
		while (1) {
			if (!lstat(input.c_str(), &st)) {
				if(S_ISDIR(st.st_mode)) {
					fertig=1;
					break;
				} else {
					cout<<"'"<<rot<<input<<schwarz<<Txk[T_kein_Verzeichnis_nochmal];
					break;
				} //         if(S_ISDIR(st.st_mode)) else
			} else {
				string inpi;
				cout<<" '"<<rot<<input<<schwarz<<Txk[T_nicht_gefunden_soll_ich_es_erstellen]<<drot<<Txk[T_j_k]<<schwarz;
				cout<<"/"<<drot<<"n"<<schwarz<<")(\""<<tuerkis<<vg2<<schwarz<<"\")?";
				getline(cin,inpi);
				if (cin.fail()) { cin.clear(); cin.ignore(numeric_limits<streamsize>::max(), '\n'); }
				if (inpi.empty()) {inpi=vg2;break;}
				if (strchr("jyJY",inpi[0])) {
					pruefverz(input,/*obverb=*/0,/*oblog=*/0,/*obmitfacl=*/1,/*obmitcon=*/1);
					/*//
						int erg __attribute__((unused));
						erg=system((string(sudc+"mkdir -p ")+input).c_str());
					 */
				} else {
					break;
				} //         if (strchr("jyJY",inpi[0])) else
			} //       if (!lstat(input.c_str(), &st)) else
		} //     while (1)
		pthread_mutex_unlock(&getmutex);
		if (fertig) break;
	} //   while(1)
	return input;
} // Tippverz

uchar VerzeichnisGibts(const char* vname)
{
	DIR *verz;
	if ((verz=opendir(vname))){
		closedir(verz);
		return 1;
	} //   if ((verz=opendir(vname)))
	return 0;
} // VerzeichnisGibts

void wpgcl::virtoausgeb() const
{
	cout<<"pname:"<<blau<<setw(13)<<pname<<schwarz;
	cout<<",pptr:"<<gruen<<setw(45);
	if (pptr) {
		if (part==puchar||part==pbin) {
			cout<<(int)*(uchar*)pptr;
		} else if (part==pint) {
			cout<<*(int*)pptr;
		} else if (part==plong) {
			cout<<*(long*)pptr;
		} else if (part==pdat) {
			cout<<ztacl((struct tm*)pptr,"%F %T");
		} else {
			cout<<*(string*)pptr;
		}
	} else {
		cout<<"0";
	} // 	if (pptr)
	cout<<schwarz;
}

void WPcl::virtoausgeb() const
{
	wpgcl::virtoausgeb();
	cout<<",wa:"<<blau<<part<<schwarz;
	cout<<",we:"<<blau<<wert<<schwarz;
	cout<<",gel:"<<blau<<setw(1)<<(int)gelesen<<schwarz;
	cout<<",eing:"<<blau<<(int)eingetragen<<schwarz;
	cout<<endl;
} // void WPcl::virtoausgeb

void optcl::virtoausgeb() const
{
	wpgcl::virtoausgeb();
	cout<<",ku:"<<blau<<setw(10)<<(kurzi<0?ltoan(kurzi):(*TxBp)[kurzi])<<schwarz;
	cout<<",la:"<<blau<<setw(18)<<(langi<0?ltoan(langi):(*TxBp)[langi])<<schwarz;
	cout<<",wi:"<<blau<<setw(3)<<(int)wi<<schwarz;
	cout<<",Tx:"<<blau<<setw(3)<<Txi<<schwarz;
	cout<<",rt:"<<blau<<setw(22)<<rottxt<<schwarz;
	cout<<",Tx2:"<<blau<<setw(3)<<Txi2<<schwarz;
	cout<<",iw:"<<blau<<setw(2)<<iwert<<schwarz;
	cout<<",pa:"<<blau<<part<<schwarz;
	cout<<",obno:"<<blau<<(int)obno<<schwarz;
	cout<</*endl<<setw(22)<<*/",bemkg:"<<blau<<bemerk<<schwarz;
	cout<<",woh:"<<blau<<(int)woher<<schwarz;
	cout<<",geg:"<<blau<<(int)gegenteil<<schwarz;
	cout<<",nsp:"<<blau<<(int)nichtspeichern<<schwarz;
	cout<<",eing:"<<blau<<(int)eingetragen<<schwarz;
	cout<<endl;
} // void optcl::virtoausgeb()


void optcl::hilfezeile(Sprache lg)
{
	if (TxBp) {
		if (Txi!=-1) {
			if (TxBp->TCp[Txi][lg]) {
				(*TxBp).lgn=lg;
				cout<<drot<<" -"<<(kurzi<0?ltoan(kurzi):(*TxBp)[kurzi])<<", --"<<(langi<0?ltoan(langi):(*TxBp)[langi]);
				if (pptr) {if (part==pstri||part==pdez||part==ppwd||part==pfile) cout<<" <string>"; else if (part==pverz) cout<<" <"<<Txk[T_pfad]<<">"; else if (part!=puchar) cout<<" <zahl>";}
				cout<<schwarz<<": "<< virtmachbemerk(lg)<<endl;
			} // if (TxBp->TCp[Txi][lg])
		} // if (Txi!=-1)
	} // if (TxBp)
} // hilfezeile

/*//
	linsten linstcl::checkinst(int obverb, int oblog) 
	{
	if (inst==uinst) {
	if (!systemrueck("which zypper 2>/dev/null",obverb,oblog)) {
// heruntergeladene Dateien behalten
inst=zyp;
} else if (!systemrueck("which apt-get 2>/dev/null",obverb,oblog)) {
// hier werden die Dateien vorgabemaessig behalten
inst=apt;
} else {
inst=unent;
cerr<<Txk[T_Weder_zypper_noch_apt_get_noch_dnf_noch_yum_als_Installationspgrogramm_gefunden]<<endl;
}
}
return inst;
} // linsten linstcl::checkinst(int obverb, int oblog) 
 */

const string linst_cl::ersetzeprog(const string& prog) const
{
	switch(ipr) {
		case apt:
			if (prog=="mariadb") return "mariadb-server";
			else if (prog=="hylafax") return "hylafax-server";
			else if (prog=="hylafax+") return "hylafax+-server";
			else if (prog=="hylafax hylafax-client") return "hylafax-server hylafax-client";
			else if (prog=="hylafax+ hylafax+-client") return "hylafax+-server hylafax+-client";
			else if (prog=="kernel-source") return "linux-source-$(uname -r|cut -d. -f1,2)";
			else if (prog=="tiff") return "libtiff-tools";
			else if (prog=="libxslt-tools") return "xsltproc";
			else if (prog=="imagemagick") return "imagemagick imagemagick-doc";
			else if (prog=="libreoffice-base") return "libreoffice-common libreoffice-base";
			else if (prog=="libcapi20-2") return "libcapi20-dev";
			//      else if (prog=="python-devel") return "python-dev";
			//      else if (prog=="python3-devel") return "python3-dev";
			else if (prog=="tesseract-ocr-traineddata-english") return "tesseract-ocr-eng";
			else if (prog=="tesseract-ocr-traineddata-german") return "tesseract-ocr-deu";
			else if (prog=="tesseract-ocr-traineddata-orientation_and_script_detection") return "tesseract-ocr-osd";
			//      else if (prog=="libavformat-devel") return "libavformat-dev";
			else if (prog=="poppler-tools") return "poppler-utils";
			//			else if (prog=="libffi-devel") return "libffi-dev";
			else if (prog=="boost-devel") return "libboost-dev libboost-system-dev libboost-filesystem-dev";
			//      else if (prog=="libtiff-devel") return "libtiff-dev";
			else if (prog.find("-devel")!=string::npos) return nersetze(prog,"-devel","-dev");
			break;
		case dnf: case yum:
			if (prog=="mariadb") return "mariadb-server";
			else if (prog=="kernel-source") return "kernel-devel-$(uname -r)";
			else if (prog=="tiff") return "libtiff-tools";
			else if (prog=="libcapi20-2") return "isdn4k-utils";
			else if (prog=="libcapi20-3") return {};
			////      else if (prog=="python-devel") return "python3-devel"; // bei capisuite_copy falsch; dann bei ocrmypdf fuer apt noch zu pruefen
			else if (prog=="capiutils") return {};
			else if (prog=="imagemagick") return "ImageMagick ImageMagick-doc";
			else if (prog=="libxslt-tools") return "libxslt";
			else if (prog=="libreoffice-base") return "libreoffice-filters libreoffice-langpack-de";
			else if (prog=="tesseract-ocr") return "tesseract";
			else if (prog=="tesseract-ocr-traineddata-english") return {};
			else if (prog=="tesseract-ocr-traineddata-german") return "tesseract-langpack-deu tesseract-langpack-deu_frak";
			else if (prog=="tesseract-ocr-traineddata-orientation_and_script_detection") return "tesseract-osd";
			else if (prog=="poppler-tools") return "poppler-utils";
			else if (prog=="libwbclient0") return "libwbclient";
			else if (prog=="libtiff5") return "libtiff";
			break;
		case zypper:
			if (prog=="redhat-rpm-config") return {};
			else if (prog=="libffi-devel") return "libffi$(gcc --version|head -n1|sed \"s/.*) \\(.\\).\\(.\\).*/\\1\\2/\")-devel";
			else if (prog=="kernel-source") return "kernel-devel";
			break;
		case pac:
			if (prog=="libwbclient0") return "libwbclient";
			break;
		default: break;
	} //   switch(linst.pruefipr())
	return prog;
} // string linst_cl::ersetzeprog(const string& prog) 

// wird aufgerufen in int linst_cl::doinst
std::string string_to_hex(const std::string& input)
{
	static const char* const lut = "0123456789ABCDEF";
	size_t len = input.length();
	string output;
	output.reserve(2 * len);
	for (size_t i=0;i<len;++i) {
		const unsigned char c = input[i];
		output.push_back(lut[c >> 4]);
		output.push_back(lut[c & 15]);
	} // 	for (size_t i=0; i < len; ++i)
	return output;
} // std::string string_to_hex(const std::string& input)

// wird aufgerufen in: linst_cl::doinst
//// kann getestet werden in main mit:
/*//
	linst_cl linst(0,0);
	svec inh;string ustring;
	mdatei uni0(instvz+"/inst.log",ios::in,0);
	if (uni0.is_open()) {
	string zeile;
	while (getline(uni0,zeile)) {
	inh<<zeile;
	}
	}
	linst.ziehraus(inh,&ustring);
//<<blau<<"ustring: "<<gruen<<ustring<<schwarz<<endl;
 */
void linst_cl::ziehraus(svec srueck, string *ustringp)
{
	uchar obanf{0};
	// siehe ausricht in configure
	switch (ipr) {
		case dnf: case yum:
			// Folgendes sollte u.a. fuer Fedora gehen
			for(unsigned i=0;i<srueck.size();++i) {
				if (obanf==1) obanf=2;
				if (!srueck[i].find("Installed:")||!srueck[i].find("Installiert:")) obanf=1;
				if (!srueck[i].length()) obanf=0;
				if (obanf==2) {
					const string source{srueck[i]};
					const size_t maxGroups{2};
					regex_t rCmp;
					regmatch_t groupArray[maxGroups];
					while(1) {
						// jeden zweiten String verwerfen = (das letzte [^ ]+ ohne die runden Klammern)
						// rm_eo = Ende des Fundes, rm_es = Beginn
						const string regex{string(".{")+ltoan(groupArray[0].rm_eo)+"}([^ ]+)[ ][^ ]+"};
						groupArray[0].rm_eo=0;
						if (regcomp(&rCmp, regex.c_str(), REG_EXTENDED)) {
							fLog(Txk[T_Konnte_regulaeren_Ausdruck_nicht_kompilieren]+blaus+regex+schwarz,1,1);
						} else if (!regexec(&rCmp, source.c_str(), maxGroups, groupArray, groupArray[0].rm_eo)) {
							string zudeinst;
							for (unsigned g=1;g<maxGroups;g++) {
								if (groupArray[g].rm_so == (signed)(size_t)-1)
									break;  // No more groups
								if (!zudeinst.empty()) zudeinst+=" ";
								zudeinst+=source.substr(groupArray[g].rm_so,groupArray[g].rm_eo-groupArray[g].rm_so);
							} // 									for (unsigned g=1;g<maxGroups;g++)
							*ustringp=" "+zudeinst+*ustringp;
						} else {
							break; // while(1)
						} //            if (regcomp(&rCmp, regex.c_str(), REG_EXTENDED)) else else
					} // while(1)
					regfree(&rCmp);
				} //            if (obanf==2)
			} //          for(unsigned i=0;i<srueck.size();++i;)
			break;
		case zypper:
			for(unsigned i=0;i<srueck.size();++i) {
				if (obanf==1) obanf=2;
				if (srueck[i].find("NEW package")!=string::npos ||
						srueck[i].find("NEUEN Pakete")!=string::npos ||
						srueck[i].find("reinstalled:")!=string::npos) obanf=1;
				if (!srueck[i].length()) obanf=0;
				if (obanf==2) {
					gtrim(&srueck[i]);
					*ustringp=" "+srueck[i]+*ustringp;
				} // 						if (obanf==2)
			} // 					for(unsigned i=0;i<srueck.size();++i)
			break;
			// Folgende Zeile fuer Debian gut
		case apt:
			for(unsigned i=0;i<srueck.size();++i) {
				if (obanf==1) obanf=2;
				if (srueck[i].find("NEW package")!=string::npos ||
						srueck[i].find("NEUEN Pakete")!=string::npos) obanf=1;
				if (obanf==2) {
					if (srueck[i][0]!=' ') obanf=0;
					else {
						gtrim(&srueck[i]);
						*ustringp=" "+srueck[i]+*ustringp;
					} // 					if (srueck[i][0]!=' ') obanf=0; else
				} // 						if (obanf==2)
			} // 					for(unsigned i=0;i<srueck.size();++i)
			/*//
			// im der letzten eingerueckten Block der Bildschirmausgabe stehen die tatsaechlich installierten Programme
			for(unsigned i=srueck.size();i;) KLA
			--i;
			if (srueck[i][0]==' ')KLA if (!obanf) obanf++;KLZ else if (obanf==1) obanf++;
			if (obanf==1) KLA
			gtrim(&srueck[i]);
			// Folgende Zeile fuer Debian und OpenSuse gut
			ustring=" "+srueck[i]+ustring;
			KLZ //        if (obanf==1)
			KLZ //          for(unsigned i=srueck.size();i;)
			 */
			break;
		default: break;
	} //      switch (linst.pruefipr())
} // void linst_cl::ziehraus(svec srueck, string *ustringp)

// Problem: bei obyes erscheint die Rueckfrage dem Benutzer nicht, statt dessen wartet das Programm
int linst_cl::doinst(const string& prog,int obverb/*=0*/,int oblog/*=0*/,const string& fallsnichtda/*=string()*/,uchar ohneabh/*=0*/)
	////,uchar obyes/*=1*/)
{
	//// <<rot<<"doinst 1: "<<violett<<prog<<schwarz<<" obverb: "<<(int)obverb<<endl;
	fLog(violetts+Txk[T_doinst]+schwarz+" prog: "+violett+prog+schwarz+Txk[T_fallsnichtda]+violett+"'"+fallsnichtda+"'"+schwarz+Txk[T_ohneabh]+
			violett+(ohneabh?"1":"0")+schwarz,obverb,oblog);
	int ret{2};
	// eprog kann auch von aussen vor Programmaufruf gesetzt werden
	if (eprog.empty()) eprog=ersetzeprog(prog);
	if (!fallsnichtda.empty()) {
		////    if (!systemrueck((alsroot?string("root "):string(""))+"which '"+fallsnichtda+"' >/dev/null 2>&1",obverb,oblog)) 
		if (obprogda(fallsnichtda,obverb,oblog)) {
			eprog.clear();
			return 0;
		} //     if (obprogda(fallsnichtda,obverb,oblog))
	} // if (!fallsnichtda.empty()) 
	////	int iru;
	if (!eprog.empty()) {
		switch (ipr) {
			case zypper:
				if (obnmr) {
					obnmr=0;
					systemrueck("zypper mr -k --all",obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
				} //         if (obnmr)
			default: break;
		} // switch (linst.pruefipr()) 
		const uchar obyes{1};
		svec srueck;
		const string bef{(obyes?instyp:instp)+eprog};
		if (!(ret=systemrueck(bef,obverb+1,oblog,&srueck,/*obsudc=*/0))) {
			/*//svec*/ string ustring; 
			ziehraus(srueck,&ustring);

			// s. ausricht() in configure
			if (!pruefverz(instvz,obverb,oblog,/*obmitfacl=*/1,/*obmitcon=*/0)) {
				mdatei uniff(instvz+"/inst.log",ios::app,0);
				if (uniff.is_open()) {
					uniff<<endl<<"Rueckmeldung zu: '"<<bef<<"':"<<endl;
					for(unsigned i=0;i<srueck.size();i++) {
						uniff<<srueck[i]<<endl;
					}
					uniff<<"ustring: '"<<ustring<<"'"<<endl;
					uniff<<"ustring: '"<<string_to_hex(ustring)<<"'"<<endl;
				} // 			if (uniff.is_open())
			} // 		  if (!pruefverz(instvz,obverb,oblog))
			//// <<violett<<"ustring vor Pruefung: "<<rot<<ustring<<schwarz<<endl;
			//// <<violett<<"ustring vor Pruefung: "<<rot<<string_to_hex(ustring)<<schwarz<<endl;
			const char* const weg[]{"libgcc","libselinux.","libselinux-utils","libselinux-python3","libsepol","libsemanage","libstdc++"};
			for(size_t wnr=0;wnr<elemzahl(weg);wnr++) {
				size_t p1;
				while ((p1=ustring.find(weg[wnr]))!=string::npos && (!p1||ustring[p1-1]==' ')) {
					const size_t p2=ustring.find_first_of(" \n",p1+1); //  auch string::npos
					ustring.erase(p1,p2-p1);
				} // 				while ((p1=ustring.find(weg[wnr]))!=string::npos && (!p1||ustring[p1-1]==' '))
			} // 			for(size_t wnr=0;wnr<elemzahl(weg);wnr++)
			//// <<violett<<"ustring nach Pruefung: "<<rot<<ustring<<schwarz<<endl;
			if (!ustring.empty()) {
				fLog(Txk[T_Ins_Deinstallationsprogramm_wird_eingetragen]+violetts+udpr+ustring+schwarz,obverb,oblog);
				anfgw(unindt,udpr,ustring,bef,obverb,oblog);
			} // 			if (!ustring.empty())

			/*//
				if (0) {
				exit(92);
			// Testcode
			svec srueck;
			string zudeinst;
			if (!(systemrueck("cat /DATA/down/inst_vim_orig",2,0,&srueck))) {
			string ustring; uchar obanf=0;
			// im der letzten eingerueckten Block der Bildschirmausgabe stehen die tatsaechlich installierten Programme
			// s. ausricht in configure
			for(unsigned i=srueck.size();i;) {
			--i;
			if (srueck[i][0]==' '){ if (!obanf) obanf++;} else if (obanf==1) obanf++;
			if (obanf==1) {
			gtrim(&srueck[i]);
			const string source=srueck[i].c_str();
			size_t maxGroups=2;
			regex_t rCmp;
			regmatch_t groupArray[maxGroups];
			while(1) {
			string regex=string(".{")+ltoan(groupArray[0].rm_eo)+"}([^ ]+)[ ][^ ]+";
			groupArray[0].rm_eo=0;
			if (regcomp(&rCmp, regex.c_str(), REG_EXTENDED)) {
			fLog(Txk[T_Konnte_regulaeren_Ausdruck_nicht_kompilieren]+blaus+regex+schwarz,1,1);
			} else if (regexec(&rCmp, source.c_str(), maxGroups, groupArray, groupArray[0].rm_eo) == 0) {
			for (unsigned g=1;g<maxGroups;g++) {
			if (groupArray[g].rm_so == (signed)(size_t)-1)
			break;  // No more groups
			zudeinst+=" ";
			zudeinst+=source.substr(groupArray[g].rm_so,groupArray[g].rm_eo-groupArray[g].rm_so);
			}
			} else {
			break;
			}
			}
			regfree(&rCmp);
			} // 				if (obanf==1)
			} // 			for(unsigned i=srueck.size();i;)
			cout<<violett<<zudeinst<<schwarz<<endl;
			//      anfgggf(unindt,udpr+ustring);
			exit(91);
			}
			exit(90);
			}
			 */


			/*//
				for(unsigned i=0;i<ustring.size();i++) {
				anfgggf(unindt,udpr+ustring[i]);
				}
			 */
			/*//
				if (ohneabh) {
				anfgggf(unindt,udpr+eprog);
				} else {
				anfgggf(unindt,upr+eprog);
				} // 			if (ohneabh) else
			 */
		} // 		if (!(ret=systemrueck((obyes?instyp:instp)+eprog,obverb+1,oblog)))
		/*//
			for(iru=0;iru<2;iru++) KLA
			if ((ret=systemrueck(sudc+"apt-get -y install "+eprog,obverb+1,oblog))!=100) break;
			systemrueck(sudc+"dpkg --configure -a",obverb+1,oblog);
			KLZ
		 */
		eprog.clear();
	} // if (!eprog.empty()) 
	return ret;
} // uchar linst_cl::doinst(const string& prog,int obverb,int oblog) 

// fuege an, wenn noch nicht enthalten
// anfuegen nach wortweiser Pruefung, ob schon enthalten
void anfgw(const string& datei, const string& udpr, const string& inhalt, const string& comment, int obverb/*=0*/, int oblog/*=0*/)
{
	fLog(violetts+"anfgw: '"+udpr+blau+inhalt+"'",obverb,oblog);
	svec wvec;
	uchar obda{0};
	aufSplit(&wvec,inhalt); 
	for(size_t wind=wvec.size();wind;) {
		wind--;
		if (wvec[wind].length()) {
			wvec[wind]=" "+wvec[wind];
		} else {
			wvec.erase(wvec.begin()+wind);
		}
		//// <<violett<<"wvec["<<rot<<wind<<violett<<"]: "<<rot<<wvec[wind]<<schwarz<<endl;
	} // 	for(size_t wind=0;wind<wvec.size();wind++)
	mdatei uni0(datei,ios::in,0);
	if (uni0.is_open()) {
		string zeile;
		while (getline(uni0,zeile)) {
			obda=1;
			for(size_t wind=0;wind<wvec.size();wind++) {
				if (zeile.find(wvec[wind])==string::npos) {
					obda=0;
					break;
				} else {
					//// <<wvec[wind]<<blau<<" gefunden in "<<blau<<zeile<<schwarz<<endl;
				}
			} // 			for(size_t wind=0;wind<wvec.size();wind++)
			if (obda) break;
		} // 					while (getline(uni0,zeile))
	} // 				if (uni0.is_open())
	if (!obda) {
		doanfg(datei,udpr+inhalt,comment);
	} // 			if (!obda)
} // void anfgggf(string datei, string inhalt)

// anfuegen nach gemeinsamer Pruefung, ob schon enthalten
void anfgg(const string& datei, const string& inhalt, const string& comment, int obverb/*=0*/, int oblog/*=0*/)
{
	// 'if (obverb||oblog)' zur Vermeidung von Redundanzen mit Endlosschleife
	if (obverb||oblog) fLog(violetts+"anfgg: '"+inhalt+"'"+schwarz,obverb,oblog);
	uchar obda{0};
	mdatei uni0(datei,ios::in,0);
	if (uni0.is_open()) {
		string zeile;
		while (getline(uni0,zeile)) {
			if (zeile.find(inhalt)!=string::npos) {
				obda=1;
				break;
			} // if (zeile.find(inhalt)!=string::npos)
		} // 					while (getline(uni0,zeile))
	} // 				if (uni0.is_open())
	if (!obda) {
		doanfg(datei,inhalt,comment);
	} // 			if (!obda)
	if (obverb||oblog) fLog(violetts+Txk[T_Ende]+"anfgg: '"+inhalt+"'"+schwarz,obverb,oblog);
} // void anfgggf(string datei, string inhalt)

void doanfg(const string& datei, const string& inhalt, const string& comment)
{
	mdatei uniff(datei,ios::app,0);
	if (uniff.is_open()) {
		////			uniff<<inhalt<<"\n"<<"printf \"%b"<<ersetzAllezu(inhalt,"\"","\\\"")<<"%b\\n\" \"\\033[1;34m\" \"\\033[0m\""<<endl;
		// s. ausricht() in configure
		time_t rohz=time(0);
		uniff<<inhalt<<"\n# "<<comment<<"\nprintf \"(Inst: "<<ztacl(rohz,"%F %T")<<"): $blau%s$reset\\n\" \""<<ersetzAllezu(inhalt,"\"","\\\"")<<"\""<<endl;
		//// pthread_mutex_lock(&timemutex);
		//// struct tm *zeiti=localtime(&rohz);
		//// char buf[80];
		//// strftime(buf,sizeof buf,"%F %T",zeiti);
		//// uniff<<put_time(localtime(&rohz),"%F %T");
		//// pthread_mutex_unlock(&timemutex);
	} else {
		perror((string("\n")+Txk[T_Kann_Datei]+datei+Txk[T_nicht_mit_open_zum_Anhaengen_oeffnen]).c_str());
	} // 			if (uniff.is_open())
} // void doanfg(const string& datei, const string& inhalt, const string& comment)

int linst_cl::doggfinst(const string& prog,int obverb,int oblog,uchar ohneabh/*=0*/)
{
	if (!(eprog=ersetzeprog(prog)).empty()) {
		if (obfehlt(eprog,obverb,oblog)) {
			return doinst(prog,obverb,oblog,string(),ohneabh);
		}
		eprog.clear();
	} // if (!(eprog=ersetzeprog(prog)).empty()) 
	return 0;
} // uchar linst_cl::doggfinst(const string& prog,int obverb,int oblog)

int linst_cl::douninst(const string& prog,int obverb/*=0*/,int oblog/*=0*/,uchar obyes/*=1*/) 
{
	int ret{2};
	if (eprog.empty()) eprog=ersetzeprog(prog);
	if (!eprog.empty()) {
		ret=systemrueck((obyes?uypr:upr)+prog,obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
		eprog.clear();
	} // 	if (!eprog.empty())
	return ret;
} // uchar linst_cl::douninst(const string& prog,int obverb,int oblog) 


int linst_cl::obfehlt(const string& prog,int obverb,int oblog)
{
	//// <<violett<<"linst::obfehlt: "<<schwarz<<prog<<endl;
	string ep;
	switch (ipr) {
		case zypper: case dnf: case yum: 
			return systemrueck("rpm -q "+prog+" 2>/dev/null",obverb,oblog,/*rueck=*/0,/*obsudc=*/0);
		case apt:
			ep=ersetzeprog(prog);
			////      return systemrueck("dpkg -s "+ersetzeprog(prog)+" 2>/dev/null",obverb,oblog);
			return systemrueck("[ $(dpkg -l '"+ep+"' 2>/dev/null|grep '"+ep+"[ :]'|cut -f1 -d' ')_ = 'ii_' ]",obverb,oblog,/*rueck=*/0,/*obsudc=*/0);
		default: break;
	} // 	switch (ipr)
	return 2;
} // uchar linst_cl::obfehlt(const string& prog,int obverb,int oblog)


// wird aufgerufen in: hcl::hcl, pruefmehrfach, setfaclggf
string meinpfad() 
{
	char buff[PATH_MAX];
	buff[0]=0;
	const ssize_t len{readlink("/proc/self/exe", buff, sizeof(buff)-1)};
	if (len != -1) {
		buff[len] = '\0';
	}
	return string(buff);
} // meinpfad

// home-Verzeichnis ohne '/' am Ende
string gethome()
{
	static string erg;
	if (erg.empty()) {
		//   erg=getenv("HOME");
		//   svec rue;
		//	 systemrueck("getent passwd $(logname)|cut -d: -f6",0,0,&rue);
		size_t pos{instvz.rfind('/')};
		if (pos>1&&pos!=string::npos) {
			erg=instvz.substr(0,pos);
		} else {
			erg=instvz; // sollte nicht vorkommen
		}
		/*//
			svec srueck;
			systemrueck("echo $HOME",0,0,&srueck);
			if (srueck.size()) {
			erg=srueck[0];
			}
		 */
	} //  if (erg.empty())
	return erg;
} // string gethome()

servc::servc(const string& vsname,const string& vename,int obverb, int oblog): sname((vsname.empty()?vename:vsname)),ename(vename) 
{
	machfit(obverb,oblog);
} // servc::servc(const string& vsname,const string& vename,int obverb, int oblog): sname((vsname.empty()?vename:vsname)),ename(vename)

void servc::semodpruef(int obverb/*=0*/,int oblog/*=0*/)
{
	static uchar obse{2};
	fLog(violetts+Txk[T_semodpruef]+schwarz+sname,obverb,oblog);
	string sepfad;
	if (obprogda("sestatus",obverb,oblog,&sepfad)) {
		if (obse==2) {
			obse=0;
			svec sr2;
			systemrueck("sestatus",obverb,oblog,&sr2,/*obsudc=*/0);
			for(size_t j=0;j<sr2.size();j++) {
				if (!sr2[j].find("Current mode:"))
					if (sr2[j].find("enforcing")!=string::npos) {
						obse=1; 
						break;
					} // 				if (sr2[j].find("enforcing")!=string::npos)
			} //       for(size_t j=0;j<sr2.size();j++)
		} // 		if (obse==2)
		if (obse) {
			if (linstp) linstp->doinst("policycoreutils-python-utils",obverb+1,oblog,"audit2allow");
			// falls "Nothing to do" zurueckgemeldet wird, muesste (sudo) dnf -y reinstall p... aufgerufen werden fuer das Deinstallationsprogramm
			// => wird der perfekten Version vorbehalten
			systemrueck("setenforce 0",obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
			restart(obverb,oblog);
			const string selocal{sname+"_selocal"};
			systemrueck("grep \""+ename+"\" /var/log/audit/audit.log | audit2allow -M "+selocal,obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
			systemrueck("setenforce 1",obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
			struct stat sstat{0};
			const string mod{instvz+vtz+selocal+".pp"};
			if (!lstat(mod.c_str(),&sstat)) {
				if (linstp) linstp->doinst("policycoreutils",obverb+1,oblog,"semodule");
				const string bef{"semodule -i \""+mod+"\""};
				systemrueck(bef,obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
				anfgg(unindt,sudc+"semodule -r \""+mod+"\"",bef,obverb,oblog);
			} // 					if (!lstat((instvz+vtz+selocal+".pp").c_str(),&sstat)
		}  // if (obse)
	} // 			if (obprogda("sestatus",obverb,oblog,&sepfad))
} // int servc::sepruef(int obverb,int oblog)


void servc::semanpruef(int obverb/*=0*/,int oblog/*=0*/,const string& mod/*="getty_t*/)
{
	string sepfad;
	if (ename.find("faxgetty")!=string::npos) {
		if (obprogda("sestatus",obverb,oblog,&sepfad)) {
			const string bef{"semodule -l|grep permissive_"+mod+" >/dev/null|| semanage permissive -a "+mod};
			systemrueck(bef,obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
			anfgg(unindt,sudc+"semanage permissive -d "+mod,bef,obverb,oblog);
		} // 	if (obprogda("sestatus",obverb,oblog,&sepfad))
	} // 		if (ename.find("faxgetty")!=string::npos)
} // int servc::semanpruef(const string& mod/*="getty_t*/, int obverb/*=0*/,int oblog/*=0*/)

int servc::machfit(int obverb/*=0*/,int oblog/*=0*/, binaer nureinmal/*=falsch*/)
{
	fLog(violetts+Txk[T_machfit]+schwarz+" sname: "+violett+sname+schwarz+" svfeh: "+blau+ltoan(svfeh)+schwarz, obverb,oblog);
	// ueberpruefen, ob in systemctl status service Datei nach ExecStart existiert
	for(int iru{0};iru<2;iru++) {
		//// <<violett<<"machfit "<<blau<<sname<<violett<<", iru: "<<gruen<<iru<<schwarz<<endl;
		obsvfeh(obverb,oblog);
		// wenn restart nicht gebraucht wird oder nichts bringt, also alles ausser activating und nicht gestartet ...
		if (!svfeh||svfeh==1||svfeh==3||svfeh==4||svfeh==5||svfeh==6) {
			break;
		} else {
			restart(obverb,oblog);
			if (!svfeh) break;
		}
		/*//
			if (!iru && svfeh>5) KLA
			<<"machfit, svfeh: "<<gruen<<svfeh<<schwarz<<endl;
			exit(108);
			svec sr1;
			systemrueck("journalctl -xen 1 \"$(systemctl show '"+sname+"' | awk -F'={ path=| ;' '/ExecStart=/{print $2}')\" | tail -n 1",2,0,&sr1);
			if (sr1.size()) KLA
			if (sr1[0].find("permission")!=string::npos) KLA
			semodpruef(obverb,oblog);
			KLZ // 		if (!iru && svfeh>5)
		 */
	} // for(int iru=0;iru<2;iru++) 
	////  if (servicelaeuft)
	if (!svfeh&&!obenabled)
		enableggf(obverb,oblog);
	fLog(violetts+"Ende "+Txk[T_machfit]+schwarz+" sname: "+violett+sname+schwarz+" svfeh: "+blau+ltoan(svfeh)+schwarz, obverb,oblog);
	return !svfeh;
} // int servc::machfit(int obverb,int oblog)

// wird aufgerufen in: hservice_faxq_hfaxd, hservice_faxgetty, cservice
uchar servc::spruef(const string& sbez, uchar obfork, const string& parent, const string& sexec, const string& CondPath, const string& After, 
		int obverb/*=0*/,int oblog/*=0*/, uchar mitstarten/*=1*/)
{
	fLog(violetts+Txk[T_spruef_sname]+schwarz+sname,obverb,oblog);
	if (!obsvfeh(obverb>0?obverb-1:0,oblog)) {
		fLog(("Service ")+blaus+sname+schwarz+Txk[T_lief_schon],obverb,oblog);
	} else {
		/*//
			char pBuf[300];
			int bytes = MIN(readlink("/bin/systemd", pBuf, sizeof pBuf), sizeof pBuf - 1);
			if(bytes >= 1) pBuf[bytes-1] = 0; // ../system statt /systemd
			systemd=string(pBuf)+"/"+sname+".service";
		 */
		systemd="/etc/systemd/system/"+sname+".service";
		for(uchar iru=0;iru<2;iru++) {
			if (mitstarten && svfeh>5)
				restart(obverb,oblog); // svfeh wird hier auch gesetzt
			if (!svfeh) {
				fLog(("Service ")+blaus+sname+schwarz+" "+Txk[T_laeuft_jetzt],obverb,oblog);
				break;
			} // 			if (!svfeh)
			////          <<dblau<<"svfeh else: "<<schwarz<<sname<<endl;
			////  if (systemrueck("systemctl list-units faxq.service --no-legend | grep 'active running'",obverb>0?obverb-1:0,oblog)) KLA
			//// string systemd="/usr/lib/systemd/system/"+sname+".service"; // ausserhalb Opensuse: /lib/systemd/system/ ...
			fLog(blaus+systemd+Txk[T_nicht_gefunden_versuche_ihn_einzurichten]+schwarz,1,0);
			mdatei syst(systemd,ios::out);
			if (syst.is_open()) {
				syst<<"[Unit]"<<endl;
				time_t jetzt = time(0);
				syst<<"Description="<<sbez<<Txk[T_als_Dienst_eingerichtet_von]<<parent<<Txk[T_am]<<ztacl(jetzt,"%d.%m.%y %H:%M:%S")<<endl;
				//// char buf[80];
				//// pthread_mutex_lock(&timemutex);
				//// struct tm *tmp = localtime(&jetzt);
				//// strftime(buf, sizeof(buf), "%d.%m.%y %H:%M:%S", tmp);
				//// syst<<put_time(localtime(&jetzt),"%d.%m.%y %H:%M:%S")<<endl;
				//// pthread_mutex_unlock(&timemutex);
				if (!CondPath.empty()) 
					syst<<"ConditionPathExists="<<CondPath<<endl;
				if (!After.empty())
					syst<<"After="<<After<<endl;
				syst<<endl;
				syst<<"[Service]"<<endl;
				if (obfork) 
					syst<<"Type=forking"<<endl;
				syst<<"User=root"<<endl;
				syst<<"Group=root"<<endl;
				syst<<"Restart=always"<<endl;
				syst<<"RestartSec=30"<<endl;
				//// if (!spre.empty()) syst<<"ExecStartPre=source "<<spre<<endl;
				syst<<"ExecStart="<<sexec<<endl;
				syst<<endl;
				syst<<"[Install]"<<endl;
				syst<<"WantedBy=multi-user.target "<<endl;
				syst.close();
				daemon_reload(obverb>0?obverb-1:0,oblog);
				anfgg(unindt,"N="+sname+";C=\""+sudc+"systemctl\";$C stop $N;$C disable $N;rm -r '"+systemd+"';$C daemon-reload;$C reset-failed;",systemd,
						obverb,oblog);
				syst.close();
				restart(obverb>0?obverb-1:0,oblog);
				obsvfeh(obverb>0?obverb-1:0,oblog);
				semodpruef(obverb,oblog);
				semanpruef(obverb,oblog);
			} // if (syst.is_open()) 
		} // if (!svgibts || !obslaeuft(obverb,oblog)) 
	} // if (servicelaeuft) else
	if (!svfeh&&!obenabled) { 
		enableggf(obverb,oblog);
	} // 	if (!svfeh&&!obenabled)
	return !svfeh;
} // void servc::spruef() 

int servc::startbar()
{
	return !svfeh||svfeh==7||svfeh==8;
}

int servc::laeuft()
{
	return !svfeh||svfeh==4;
}

int servc::lief()
{
	return !svf0||svf0==4;
}

int servc::obsvfeh(int obverb/*=0*/,int oblog/*=0*/) // ob service einrichtungs fehler
	// svfeh=1: Dienst inexistent, 2: Dienst 'disabled' 3: Dienstdatei nicht ermittelbar, 4: Dienst laeuft noch, aber Dienstdatei inexistent
	// svfeh=5: Exe-Datei nicht ermittelbar, 6: Exe-Datei fehlt, 7: activating 8: Dienst kann gestartet werden, 9: Sonstiges
{
	fLog(violetts+Txk[T_obsfveh]+schwarz+" sname: "+violett+sname+schwarz+", obverb: "+ltoan(obverb),obverb>0?obverb:0,oblog); // nicht die Loeschanzeige
	string sdatei;
	fehler=0;
	svfeh=-1;
	obenabled=1;
	for(int iru=0;iru<2;iru++) {
		svec statrueck;
		systemrueck("systemctl -n 0 status '"+sname+"' 2>/dev/null",obverb,oblog,&statrueck,1);
		for(size_t j=0;j<statrueck.size();j++) {
			const string *const sp{&statrueck[j]};
			if (sp->find("Loaded:")!=string::npos) {
				size_t p2=string::npos,p1=sp->find("("); if (p1!=string::npos) p2=sp->find(";",p1);
				if (p2==string::npos) if (sp->find("loaded")!=string::npos) p2=sp->find(")",p1);
				if (p2!=string::npos) {
					sdatei=sp->substr(p1+1,p2-p1-1);
					if (systemd.empty()) systemd=sdatei;
				}
				if (sp->find("disabled")!=string::npos) {
					//// svfeh=2; // stoert bei if (!svfeh) enableggf(
					obenabled=0;
				} else if (sp->find("not-found")!=string::npos) {
					svfeh=1;
				}
			} else if (sp->find("active (running)")!=string::npos) {
				svfeh=0;
				break;
			} else if (sp->find("activating")!=string::npos) {
				svfeh=7;
				// z.B.: Process: 10126 ExecStartPre=/usr/share/samba/update-apparmor-samba-profile (code=exited, status=0/SUCCESS)
			} else if (svfeh && (sp->find("code=exited")!=string::npos||sp->find("(exited)")!=string::npos)) {
				// z.B. Exe-Datei bricht ab
				// z.B.: 'Main PID: 17031 (code=exited, status=255)'
				// oder:
				//   Loaded: loaded (/etc/systemd/system/aout.service; disabled; vendor preset: disabled)
				//   Active: activating (auto-restart) (Result: exit-code) since Thu 2017-02-16 15:08:33 CET; 1s ago
				//  Process: 24594 ExecStart=/root/a.aout (code=exited, status=203/EXEC)
				// Main PID: 24594 (code=exited, status=203/EXEC)
				// 11.9.16: dann muss evtl. selinux angepasst werden
				size_t gpos=sp->rfind('=');
				if (gpos<sp->length()-1)
					fehler=atol(sp->substr(gpos+1).c_str());
				else 
					fehler=1;
			} // if (sp->find("exited")!=string::npos) 
		} //  									for(size_t j=0;j<statrueck.size();j++)
		if (svfeh==7&&!fehler) { // 16.2.17: nur noch bei activating ohne exited
			// Dienst existent, Dienstdatei bekannt und existent, Exe-Datei bekannt und existent, Dienst laeuft aber nicht
			perfcl prf(Txk[T_Aktiviere_Dienst]+sname);
			while (!prf.oberreicht(3)) {}
			if (obverb) prf.ausgeb();
		} else {
			break;
		} // 									if (!fehler)
	} // 	for(int iru=0;iru<2;iru++)
	if (svfeh) {
		if (sdatei.empty()) {
			svfeh=3; // Dienstdatei nicht ermittelbar
		} else {
			// Dienst existent, Dienstdatei bekannt
			struct stat svst={0};
			if ((svfeh=lstat(systemd.c_str(),&svst))) { 
				svfeh=4; // Dienst laeuft evtl. noch, aber Dienstdatei inexistent
			} else {
				string execf;
				svec srueExe;
				if (systemd.find("init.d")!=string::npos) {
					systemrueck("cat '"+systemd+"'",obverb,oblog,&srueExe,/*obsudc=*/1);
					if (srueExe.size()) {
						// z.B.:  if ! start-stop-daemon --start --quiet --oknodo --exec /usr/sbin/smbd -- -D; then
						for(size_t z=0;z<srueExe.size();z++) {
							size_t p1=srueExe[z].find(" --exec ");
							if (p1!=string::npos) {
								size_t p2=srueExe[z].find(" ",p1+8);
								if (p2!=string::npos) {
									execf=srueExe[z].substr(p1+8,p2-p1-8);
									break;
								} // 						 if (p2!=string::npos)
							} // 						if (p1!=string::npos)
						} // 					 for(size_t z=0;z<srueExe.size();z++)
					} else {
						svfeh=4;// Dienst laeuft evtl. noch, aber Dienstdatei leer
					} // 					if (srueExe.size()) else
				} else {
					// Dienst existent, Dienstdatei bekannt und existent
					systemrueck("cat '"+systemd+"'|grep ExecStart=|cut -d= -f2|cut -d' ' -f1",obverb,oblog,&srueExe,/*obsudc=*/1);
					if (srueExe.size()) {
						execf=srueExe[0];
					} // 			if (!srueExe.size()) else
				} // 			  if (systemd.find("init.d")!=string::npos)
				if (execf.empty()) {
					svfeh=5; // Exec-Datei nicht ermittelbar
				} else {
					if (ename.empty()) ename=base_name(execf); // stimmt z.B. nicht bei /usr/lib/mysql/mysql-systemd-helper
					// Dienst existent, Dienstdatei bekannt und existent, Exe-Datei bekannt
					struct stat lst={0};
					if (lstat(execf.c_str(),&lst)) {
						svfeh=6; // Exec-Datei fehlt, hier auch: activating
					} else {// 				if (lstat(srueExe.c_str(),&lst))
						svfeh=8; // Sonstiges
					} // 						if (lstat(srueExe[0].c_str(),&lst)) else
				} // 				if (execf.empty())
			} // 			if ((svfeh=lstat(systemd.c_str(),&svst))) 
		} // if (sdatei.empty()) else
	} // if (svfeh)
	/*//
		svec srueck;
		systemrueck("systemctl list-unit-files|grep "+sname+".service",obverb,oblog,&srueck);  // 
		if (!srueck.size()) KLA
		svfeh=1; // Dienst inexistent
		KLZ else KLA
		if (!(obenabled=(srueck[0].find("enabled")!=string::npos))) KLA
		svfeh=2; // Dienst 'disabled'
		KLZ
		if (systemd.empty()) KLA
		svec srue3;
		systemrueck("systemctl -n 0 status '"+sname+"' 2>/dev/null|grep Loaded:|cut -d'(' -f2|cut -d';' -f1",obverb,oblog,&srue3);
		if (srue3.size()) systemd=srue3[0]; // z.B. /etc/systemd/system/abc.service
		KLZ // 					if (systemd.empty())
		if (systemd.empty()) KLA
		svfeh=3; // Dienstdatei systemd nicht ermittelbar
		KLZ else KLA
	// Dienst existent, Dienstdatei bekannt
	struct stat svst=KLA0KLZ;
	if ((svfeh=lstat(systemd.c_str(),&svst))) KLA 
	svfeh=4; // // Dienst laeuft noch, aber Dienstdatei inexistent
	KLZ else KLA
	// Dienst existent, Dienstdatei bekannt und existent
	svec srueExe;
	systemrueck("systemctl -n 0 status '"+sname+"'|grep ExecStart=|cut -d= -f2|cut -d' ' -f1",obverb,oblog,&srueExe);
	if (!srueExe.size())
	systemrueck(sudc+"cat '"+systemd+"'|grep ExecStart=|cut -d= -f2|cut -d' ' -f1",obverb,oblog,&srueExe);
	if (!srueExe.size()) KLA
	svfeh=5; // Exec-Datei nicht ermittelbar
	KLZ else KLA
	if (ename.empty()) ename=base_name(srueExe[0]); // stimmt z.B. nicht bei /usr/lib/mysql/mysql-systemd-helper
	// Dienst existent, Dienstdatei bekannt und existent, Exe-Datei bekannt
	struct stat lst=KLA0KLZ;
	if (lstat(srueExe[0].c_str(),&lst)) KLA
	svfeh=6; // Exec-Datei fehlt, hier auch: activating
	KLZ else KLA// 				if (lstat(srueExe.c_str(),&lst))
	KLZ // 						if (lstat(srueExe[0].c_str(),&lst)) else
	KLZ // 			if (!srueExe.size()) else
	KLZ // if ((svfeh=lstat(systemd.c_str(),&svst)))  else
	KLZ // 			if (systemd.empty()) else
	 */

	/*// Folgendes wird vielleicht nicht benoetigt, da es bei disabled eh nicht angezeigt wird
		srueck.clear;
		systemrueck("systemctl -a --no-legend list-units '"+sname+".service'",obverb,oblog,&srueck);  // bei list-units return value immer 0
		if (!srueck.empty()) KLA // svfeh=1 => Dienst inexistent
	// Dienst existent
	if (srueck[0].find(sname+".service loaded active running")==string::npos) KLA // sonst: svfeh=0
	// Dienst existent, Dienst laeuft aber nicht
	if (srueck[0].find(sname+".service loaded inactive")==string::npos) KLA
	if (srueck[0].find(sname+".service loaded activating")==string::npos) KLA
	svfeh=8; // loaded failed = Dienst kann evtl. gestartet werden
	KLZ else KLA
	KLZ // 								if (srueck[0].find(sname+".service loaded activating")==string::npos) else
	KLZ // 							if (srueck[0].find(sname+".service loaded inactive")==string::npos)
	KLZ // 	if (!(svfeh=srueck.empty())) 
	KLZ // 		if (!(obenabled=(srueck[0].find("enabled")!=string::npos))) else
	 */
	//	const int sfeh[]={ T_Dienst_laeuft,T_Dienst_inexistent, T_Dienst_disabled, T_Dienstdateiname_nicht_ermittelbar, T_Dienst_laeuft_noch_aber_Dienstdatei_inexistent, T_Exec_Dateiname_nicht_ermittelbar, T_Exec_Datei_fehlt, T_activating, T_Dienst_kann_gestartet_werden, T_Sonstiges};
	////	int aktobverb=(obverb>-1 && (obverb>0|| (svfeh && svfeh!=8))); // 26.2.17: beim Stoppen eines nicht vorhandenen Dienstes ueberfl. Meldung
	fLog(Txk[T_Ergebnis_Dienst]+blaus+sname+schwarz+": "+gruen+Txk[sfeh[svfeh]]+schwarz,/*akt*/obverb>0?obverb:0,oblog);
	//	fLog(violetts+"Ende "+Txk[T_obsfveh]+schwarz+" sname: "+violett+sname+schwarz,obverb,oblog);
	if (svf0==-1) svf0=svfeh; // Einstellung nach der ersten Untersuchung
	return svfeh;
} // int servc::obsvfeh(int obverb,int oblog)

void servc::pkill(int obverb/*=0*/,int oblog/*=0*/)
{
	systemrueck("pkill '"+ename+"'",obverb>0?obverb-1:0,oblog,0,/*obsudc=*/1,1);
} // void servc::pkill(int obverb/*=0*/,int oblog/*=0*/)

int servc::restart(int obverb/*=0*/,int oblog/*=0*/)
{
	for(int i=0;i<2;i++) {
		uchar obbreak{0};
		daemon_reload(obverb,oblog);
		systemrueck("systemctl restart '"+sname+"'",obverb,oblog,0,/*obsudc=*/1,2);
		//// <<violett<<"restart, i: "<<gruen<<i<<schwarz<<" sname: "<<sname<<endl;
		obsvfeh(obverb,oblog);
		switch (sfeh[svfeh]) {
			case T_Dienst_laeuft: 
			case T_Dienst_inexistent: 
			case T_Dienstdateiname_nicht_ermittelbar:
			case T_Exec_Dateiname_nicht_ermittelbar: 
			case T_Exec_Datei_fehlt:
				obbreak=1; break;
			case T_Dienst_disabled: 
			case T_Dienst_laeuft_noch_aber_Dienstdatei_inexistent: 
			case T_activating:
			case T_Dienst_kann_gestartet_werden:
			case T_Sonstiges:
			default: break;
		}
		if (obbreak) break;
		if (i) break;
		pkill(obverb,oblog);
	} //   for(int i=0;i<2;i++)
	return !svfeh;
} // int servc::restart(int obverb,int oblog)

void servc::start(int obverb/*=0*/,int oblog/*=0*/)
{
	systemrueck("systemctl start '"+sname+"'",obverb,oblog,0,/*obsudc=*/1,2);
} // int servc::start(int obverb,int oblog)

int servc::startundenable(int obverb/*=0*/,int oblog/*=0*/)
{
	fLog(violetts+Txk[T_startundenable]+schwarzs+sname,obverb,oblog);
	start(obverb,oblog);
	enableggf(obverb,oblog);
	//// <<violett<<"startundeable, sname: "<<schwarz<<sname<<endl;
	return !obsvfeh(obverb,oblog);
} // int servc::start(int obverb,int oblog)

void servc::stop(int obverb/*=0*/,int oblog/*=0*/,uchar mitpkill/*=0*/)
{
	systemrueck("systemctl stop '"+sname+"'",obverb,oblog,0,/*obsudc=*/1,2);
	if (mitpkill) {
		pkill(obverb,oblog);
	} //   if (mitpkill)
} // int servc::stop(int obverb,int oblog)

void servc::stopggf(int obverb/*=0*/,int oblog/*=0*/,uchar mitpkill/*=0*/)
{
	obsvfeh(obverb,oblog);
	if (!svfeh||svfeh==7) {
		stop(obverb,oblog,mitpkill);
	} //  if (!svfeh||svfeh==7)
} // void servc::stopggf(int obverb/*=0*/,int oblog/*=0*/,uchar mitpkill/*=0*/)

void servc::stopdis(int obverb/*=0*/,int oblog/*=0*/,uchar mitpkill)
{
	fLog(violetts+Txk[T_stopdis_sname]+schwarzs+sname,obverb,oblog);
	if (!obsvfeh(obverb,oblog)) {
		stop(obverb,oblog);
	} // 	if (!obsvfeh(obverb,oblog))
	if (svfeh!=1&&obenabled)
		systemrueck("systemctl disable '"+sname+"'",obverb,oblog,0,/*obsudc=*/1,2);
} // int servc::stop(int obverb,int oblog)

int servc::enableggf(int obverb/*=0*/,int oblog/*=0*/)
{
	fLog(violetts+Txk[T_enableggf]+schwarzs+": "+sname,obverb,oblog);
	vector<errmsgcl> errv;
	const string froh{schwarzs+Txk[T_Dienst]+blau+sname+schwarz},
				f0{froh+Txk[T_ermoeglicht]},
				f1{froh+Txk[T_nicht_ermoeglicht]};
	errv.push_back(errmsgcl(0,f0));
	errv.push_back(errmsgcl(1,f1));
	errv.push_back(errmsgcl(6,f1));
	return systemrueck("systemctl is-enabled '"+sname+"' >/dev/null 2>&1 ||systemctl enable '"+sname+"'",obverb,oblog,0,/*obsudc=*/1,2,wahr,"",&errv);
} // int servc::enableggf(int obverb,int oblog)


void servc::daemon_reload(int obverb/*=0*/, int oblog/*=0*/)
{
	systemrueck("systemctl daemon-reload",obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
} // void servc::daemon_reload(int obverb/*=0*/, int oblog/*=0*/)

// Rueckgabe: Zahl der nicht Geloeschten
// wird aufgerufen in: loeschecapi, untersuchespool, lauf
int tuloeschen(const string& zuloe,const string& cuser/*=string()*/, int obverb/*=0*/, int oblog/*=0*/,stringstream *ausgp/*=0*/)
{
	////  fLog(violetts+Txk[T_tuloeschen]+schwarz,obverb,oblog);
	string meld;
	struct stat entryzuloe={0};
	if (!lstat(zuloe.c_str(),&entryzuloe)) {
		meld=Txk[T_Loesche_Ausrufezeichen]+gruens+zuloe+schwarz;
		if (ausgp&&obverb) *ausgp<<meld<<endl; else fLog(meld,obverb,oblog);
		int erg{-1};
		for(uchar iru=1;iru<3;iru++) {
			if ((erg=remove(zuloe.c_str()))) {
				if(cuser.empty()) iru++;
				if(iru==1) {
					setfaclggf(zuloe,obverb>1?obverb-1:0,oblog,/*obunter=*/falsch,/*mod=*/6,/*obimmer=*/falsch,
							/*faclbak=*/0,/*user=*/string()/*cuser*/,/*fake=*/0,ausgp);
				} else {
					if (errno) if (errno!=13) perror((string(Txk[T_Fehler_beim_Loeschen])+" "+ltoan(errno)).c_str()); // Permission denied
					const string cmd{"rm -rf \""+zuloe+"\""};
					erg=systemrueck(cmd,obverb+1,1,/*rueck=*/0,/*obsudc=*/1);
				} // if(iru) else
			} else {
				erg=0;
				break;
			} //       if ((erg=remove(zuloe.c_str())))
		} // for(uchar iru=1;iru>-1;iru--)
		return erg;
	} // if (!lstat(zuloe.c_str(),&entryzuloe)) 
	meld=rot+zuloe+schwarz+Txk[T_nicht_geloescht_war_eh_nicht_mehr_da];
	if (ausgp&&obverb) *ausgp<<meld<<endl; else fLog(meld,obverb,oblog);
	return 0;
} // int tuloeschen(string zuloe,int obverb, int oblog)

// gleicht das Datum von <zu> an <gemaess> an, aehnlich touch
int attrangleich(const string& zu, const string& gemaess,const string* const zeitvondtp/*=0*/, int obverb/*=0*/, int oblog/*=0*/)
{
	struct stat statgm={0};
	if (lstat(gemaess.c_str(),&statgm)) {
		fLog(rots+Txk[T_Fehler_bei_lstat]+schwarz+gemaess,obverb,oblog);
		return 1;
	} //   if (lstat(gemaess.c_str(),&statgm))
	struct stat statzu={0};
	if (lstat(zu.c_str(),&statzu)) {
		fLog(rots+Txk[T_Fehler_bei_lstat]+schwarz+zu,obverb,oblog);
		return 1;
	} //   if (lstat(zu.c_str(),&statzu))
	if (chmod(zu.c_str(),statgm.st_mode)) {
		systemrueck("chmod --reference=\""+gemaess+"\" \""+zu+"\"",obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
	} //   if (chmod(zu.c_str(),statgm.st_mode))
	if (chown(zu.c_str(),statgm.st_uid,statgm.st_gid)) {
		systemrueck("chown --reference=\""+gemaess+"\" \""+zu+"\"",obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
	} //   if (chown(zu.c_str(),statgm.st_uid,statgm.st_gid))
	systemrueck("sh -c 'getfacl \""+gemaess+"\" 2>/dev/null|setfacl --set-file=- \""+zu+"\"'",obverb,oblog,/*rueck=*/0,/*obsudc=*/1);

	const string* const zvdtp{(zeitvondtp?zeitvondtp:&gemaess)};
	struct stat stzvd{0};
	if (!lstat(zvdtp->c_str(),&stzvd)) {
		struct utimbuf ubuf{0};
		ubuf.actime=ubuf.modtime=stzvd.st_mtime;
		if (utime(zu.c_str(),&ubuf)) {
			systemrueck("touch -r \""+*zvdtp+"\" \""+zu+"\"",obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
		} //   if (utime(zu.c_str(),&ubuf))
	} // 	if (!lstat(zvdtp->c_str(),&stzvd))
	lstat(zu.c_str(),&statzu);
	if (memcmp(&stzvd.st_mtime, &statzu.st_mtime,sizeof statzu.st_mtime)) {
		fLog(rots+Txk[T_Datum_nicht_gesetzt_bei]+schwarz+zu+rot+"'"+schwarz,1,1);
		////          exit(0);
	} //   if (memcmp(&statgm.st_mtime, &statzu.st_mtime,sizeof statzu.st_mtime))
	return 0;
} // int attrangleich(const string& zu, const string& gemaess,int obverb, int oblog)

// liefert 0, wenn Erfolg
int kopier(const string& quel, const string& ziel, int obverb, int oblog)
{
	int erg{-1};
	int fehler{1};
	const int source{open(quel.c_str(),O_RDONLY,0)};
	if (source==-1) {
		////    fLog(Txk[T_Konnte_Datei]+rots+quel+schwarz+Txk[T_nicht_zum_Lesen_oeffnen],obverb,oblog);
	} else {
		struct stat statq={0};
		if (!fstat(source,&statq)) {
			int dest{open(ziel.c_str(),O_WRONLY|O_CREAT,statq.st_mode)};
			if (dest==-1) {
				fehler=2;
				////        fLog(Txk[T_Konnte_Datei]+rots+ziel+schwarz+Txk[T_nicht_zum_Schreiben_oeffnen],obverb,oblog);
			} else {
				erg=sendfile64(dest,source,0,statq.st_size);
				close(dest);
				if (erg==-1) {
					fehler=3;
				} else {
					fehler=0;
					bool chmerg __attribute__((unused))=chmod(ziel.c_str(),statq.st_mode);
					bool choerg __attribute__((unused))=chown(ziel.c_str(),statq.st_uid,statq.st_gid);
					struct utimbuf ubuf={0};
					ubuf.actime=ubuf.modtime=statq.st_mtime;
					utime(ziel.c_str(),&ubuf);
				} // if (erg==-1)
			} // if (dest==-1) else 
			close(source);
		} // if (!fstat(source,&statq)) 
	} // if (source==-1) else 
	if (fehler)
		return systemrueck("test -f \""+quel+"\" && sh -c 'cp -a \""+quel+"\" \""+ziel+"\"'",obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
	return 0;
} // int kopier(const string& quel, const string& ziel, int obverb, int oblog)

#ifdef altfind
// Binaerausgabe, fuer Debugging
void printBits(size_t const size, void const * const ptr)
{
	const uchar *b{(uchar*) ptr};
	puts("\r");
	for (int i=size-1;i>=0;i--) {
		for (int j=7;j>=0;j--) {
			const uchar byte{(uchar)((b[i] >> j) & 1)};
			printf("%u", byte);
		} //     for (j=7;j>=0;j--)
	} //   for (i=size-1;i>=0;i--)
} // void printBits(size_t const size, void const * const ptr)


const bool elem2::operator<(const elem2& el) const {return (this->pfad<el.pfad);}

elem2::elem2(const string& mutter,const string& name) 
{
	init(mutter,name);
}

void elem2::init(const string& vmutter, const string& name) {
	pfad=(name[0]=='/'||vmutter.empty()?"":vmutter+(vmutter[vmutter.length()-1]=='/'?"":"/"))+name;
	sterg=0;
	if (name[0]=='.') {
		if (char* actp=realpath(pfad.c_str(),NULL)) {
			pfad=actp;
			free(actp);
		} else {
			sterg=REALPATHFEHLER;
		} //     if (char* actp=realpath(pfad.c_str(),NULL)) else
	} //   if (name[0]=='.')
	if (!sterg) sterg=lstat(pfad.c_str(), &dst);
} // void elem2::init(const string& vmutter, const string& name)

find2cl::find2cl(int _obverb/*=0*/,int _oblog/*=0*/,find2cl *stamm/*=0*/):obverb(_obverb),oblog(_oblog)
{
	if (stamm) {
		ergp=stamm->ergp;
		vznp=stamm->vznp;
		nrp=stamm->nrp;
		zuloeschen=0;
	} else {
		weiszu();
	} // if (stamm) else
} // find2cl::find2cl(find2cl *stamm/*=0*/)

find2cl::~find2cl()
{
	if (zuloeschen && 0) {
		if (ergp){ delete ergp;ergp=0;}
		if (vznp) {delete vznp;vznp=0;}
		if (nrp) {delete nrp;nrp=0;}
	}
} // find2cl::~find2cl()

void find2cl::weiszu()
{
	if (!ergp) ergp=new el2set;
	if (!vznp) vznp=new set<string>;
	if (!nrp) nrp=new ull;
} // void find2cl::weiszu()

void find2cl::init(const string& mutter, const string& name, regex_t *reg, const int folge,const long maxdepth, const int& typbit,
		vector<string> stack,time_t ab, time_t bis,int nurexec)
{
	dir=0;
	eingefuegt=0;
	verzneu=0;
	weiszu();
	elem2::init(mutter,name);
	elem2* letztel=(elem2*)this, *aktel=(elem2*)this;
	elem2 neuel;
	//  cout<<"hier init,mutter: '"<<blau<<mutter<<schwarz<<"', name: '"<<blau<<name<<schwarz<<"', letztel->sterg: "<<letztel->sterg<<endl;
	while (!letztel->sterg && S_ISLNK(letztel->dst.st_mode)) {
		//    cout <<pfad<<" "<<sterg<<" "<<dst.st_size<<endl;
		char linkname[letztel->dst.st_size?letztel->dst.st_size:FILENAME_MAX+1];
		ssize_t r=readlink(letztel->pfad.c_str(),linkname,sizeof linkname);
		if (r>0) {
			if ((size_t)r<=sizeof linkname)
				linkname[r]='\0';
			//      cout<<rot<<letztel->pfad<<schwarz<<","<<linkname<<" ("<<letztel->dst.st_size<<")"<<schwarz<<endl;
		} else {
			fLog(rots+Txk[T_Fehler_beim_Deferenzieren_von]+schwarz+pfad,1,1);
			break;
		}
		//    cout<<"letztel->pfad: "<<letztel->pfad<<" linkname: "<<linkname<<endl;
		const string link{linkname};
		if (link==letztel->pfad) 
			exit(schluss(97,Txk[T_Fehler_in_find2cl]+link+"=="+letztel->pfad));
		neuel.init(dir_name(letztel->pfad),linkname);
		//if (0)
		for(size_t j=0;j<stack.size();j++) {
			// <<"j: "<<j<<" "<<stack[j]<<endl;
			if (neuel.pfad==stack[j]) {
				return;
			} //       if (neuel.pfad==stack[j])
		} //     for(size_t j=0;j<stack.size();j++)
		if (neuel.pfad==letztel->pfad) break;
		letztel=&neuel;
	}
	//  cout<<" -> "<<blau<<letztel->pfad<<schwarz<<" sterg: "<<sterg<<" "<<endl;
	if (!letztel->sterg && S_ISDIR(letztel->dst.st_mode)) {
		if (!(dir = opendir(letztel->pfad.c_str()))) {
			letztel->sterg=DIRFEHLER;
		}
	}

	if (!sterg) {
		if (
				(typbit&B_Datei && S_ISREG(dst.st_mode)) ||
				(typbit&B_Verzn && S_ISDIR(dst.st_mode)) ||
				(typbit&B_Chdev && S_ISCHR(dst.st_mode)) ||
				(typbit&B_Block && S_ISBLK(dst.st_mode)) ||
				(typbit&B_FIFO && S_ISFIFO(dst.st_mode)) ||
				(typbit&B_Link && S_ISLNK(dst.st_mode)) ||
				(typbit&B_Sock && S_ISSOCK(dst.st_mode))) {
			/*
				 cout<<" tb1 ";
				 printf("%i ",ltypbit);
				 printBits(2,&ltypbit);
				 printBits(2,&letztel->dst.st_mode);
				 printf(" letztel->sterg: %i",letztel->sterg);
				 cout<<"S_ISREG: "<<S_ISREG(letztel->dst.st_mode)<<endl;
				 cout<<"S_ISDIR: "<<S_ISDIR(letztel->dst.st_mode)<<endl;
				 cout<<"S_ISCHR: "<<S_ISCHR(letztel->dst.st_mode)<<endl;
				 cout<<"S_ISBLK: "<<S_ISBLK(letztel->dst.st_mode)<<endl;
				 cout<<"S_ISFIFO: "<<S_ISFIFO(letztel->dst.st_mode)<<endl;
				 cout<<"S_ISLNK: "<<S_ISLNK(letztel->dst.st_mode)<<endl;
				 cout<<"S_ISSOCK: "<<S_ISSOCK(letztel->dst.st_mode)<<endl;
			 */
			if (letztel==(elem2*)this ||(!letztel->sterg &&(
							(typbit&B_Datei && S_ISREG(letztel->dst.st_mode)) ||
							(typbit&B_Verzn && S_ISDIR(letztel->dst.st_mode)) ||
							(typbit&B_Chdev && S_ISCHR(letztel->dst.st_mode)) ||
							(typbit&B_Block && S_ISBLK(letztel->dst.st_mode)) ||
							(typbit&B_FIFO && S_ISFIFO(letztel->dst.st_mode)) ||
							(typbit&B_Link && S_ISLNK(letztel->dst.st_mode)) ||
							(typbit&B_Sock && S_ISSOCK(letztel->dst.st_mode))))) {

				if (folge & Fol_Mus) aktel=letztel; else aktel=(elem2*)this;
				if ((!ab||aktel->dst.st_mtime>=ab)&&(!bis||aktel->dst.st_mtime<=bis))
					//        cout<<"Pruefe Muster: "<<blau<<aktel->pfad<<schwarz<<endl;
					if (!nurexec || (aktel->dst.st_mode & S_IXUSR || aktel->dst.st_mode & S_IXGRP || aktel->dst.st_mode & S_IXOTH))
						if (!regexec(reg, aktel->pfad.c_str(), 0, 0, 0)) {
							if (folge & Fol_Dat) aktel=letztel; else aktel=(elem2*)this;
							//          cout<<"gefunden: "<<rot<<aktel->pfad<<schwarz<<endl;
#ifdef mitset
							eingefuegt=(ergp->insert(*aktel).second==true);
#else
							eingefuegt=(ergp->insert(make_pair(*aktel,nr)).second==true);
#endif
						} // 					if (!regexec(reg, aktel->pfad.c_str(), 0, 0, 0))
			} //       if (letztel==(elem2*)this ||(!letztel->sterg &&( ...
		} // if (      (typbit&B_Datei && S_ISREG(dst.st_mode)) || ..
	} //   if (!sterg) 
	//    cout<<endl;
	if (0) {
		(*nrp)++;
		cout<<"Tiefe: "<<stack.size()<<" Zahl: "<<*nrp<<", Pfad: "<<blau<<pfad<<schwarz;
		if (letztel->pfad!=pfad) {
			cout<<" -> "<<rot<<letztel->pfad<<schwarz;
		}
		cout<<endl;
		//        cout<<"letztel->pfad: "<<blau<<letztel->pfad<<schwarz<<endl;
		//        cout<<"aktel->pfad: "<<blau<<aktel->pfad<<schwarz<<endl;
	}
	if (dir&&maxdepth) {
		if ((folge & Fol_Ver) || !S_ISLNK(dst.st_mode)) {
			// Extra-Vergleichsliste der bisher eingelesenen Verzeichnisse
			if ((verzneu=(vznp->insert(letztel->pfad).second)==true)) {
				stack.push_back(letztel->pfad);
				while ((dent = readdir(dir))) {
					if (strcmp(dent->d_name, ".") && strcmp(dent->d_name, "..")) {
						find2cl tochter(obverb,oblog,this);
						tochter.init(letztel->pfad,dent->d_name,reg,folge,maxdepth-1,typbit,stack,ab,bis,nurexec);
						//            cout<<"nach tochter.init"<<endl;
					} // 					if (strcmp(dent->d_name, ".") && strcmp(dent->d_name, ".."))
				} // 				while ((dent = readdir(dir)))
			} // 			if ((verzneu=(vznp->insert(letztel->pfad).second)==true))
		} // 		if ((folge & Fol_Ver) || !S_ISLNK(dst.st_mode))
		closedir(dir);
	}
} // void find2cl::init(const string& mutter, const string& name, regex_t *reg, const int folge,const long maxdepth, const int& typbit, ...

void find2cl::ausgeb()
{
	if (ergp) {
		el2set::iterator it=ergp->begin();
		ull nr=0;
		while (it!=ergp->end()) {
#ifdef mitset
			//string tue="bash -c \"test -z \\\"$(sed -n '\\$"+it->pfad+"\\$${p;q;}' /root/alle)\\\"&&echo '"+it->pfad+"'\"";cout<<tue<<endl;system(tue.c_str());
			cout<<blau<<++nr<<": "<<rot<<setprecision(9)<<setw(11)<<it->sterg<<schwarz<<" "<<it->pfad<<endl;
#else
			cout<<blau<<it->second<<": "<<rot<<setprecision(9)<<setw(11)<<(int)it->first.sterg<<schwarz<<" "<<(string)it->first.pfad<<endl;
#endif
			it++;
		} // 		while (it!=ergp->end())
	} // 	if (ergp)
} // void find2cl::ausgeb()

int find2cl::finde(svec *wovp,const string& muster/*=string()*/,const long tiefe/*=-1*/,int typbit/*=B_Alle*/,int folge/*=Fol_Dat*/,
		time_t ab/*=0*/, time_t bis/*=0*/,int obicase/*=0*/,int nurexec/*=0*/,int obnoext/*=0*/)
{
	regex_t reg;
	if (regcomp(&reg, muster.c_str(),(obnoext?0:REG_EXTENDED)|REG_NOSUB|(obicase?REG_ICASE:0))) { 
		regfree(&reg);
		return REGFEHLER;
	}
	vector<string> stack;
	string wo;
	for(size_t iv=0;iv<wovp->size();iv++) {
		wo+=(*wovp)[iv];wo+=" ";
		init({},(*wovp)[iv], &reg, folge, tiefe, typbit,stack,ab,bis,nurexec);
		//    cout<<"nach finde.init, wo: "<<blau<<wo<<schwarz<<endl;
	} //   for(size_t iv=0;iv<*wovp.size();iv++)
	regfree(&reg);
	if (obverb|oblog) {
		yLog(obverb,oblog,0,0,"%s%s%s%s%s%s%s%s'%s%s'%s%lu%s%s%s%d%s%s%s%d%s%s%s%d%s%s%s%zu%s",
				Txk[T_Suche_in],blau,wo.c_str(),schwarz,Txk[T_nach],blau,muster.c_str(),schwarz,obicase?"(ic)":"",Txk[T_Tiefe],blau,tiefe,schwarz,
				Txk[T_Typbit],blau,typbit,schwarz,Txk[T_Folge],blau,folge,schwarz,Txk[T_noext],blau,obnoext,schwarz,Txk[T_Ergebnis],
				gruen,ergp->size(),schwarz);
	} // 	if (obverb|oblog)
	if (obverb>1) ausgeb();
	return 0;
} // int find2cl::finde(svec *wovp,string& muster/*=string()*/,const long tiefe/*=-1*/,int typbit/*=B_Alle*/,int folge/*=Fol_Dat*/,

void find2cl::zuvec(svec *zu,uchar anteil/*=0*/)
{
	for(set<elem2>::iterator jt=ergp->begin();jt!=ergp->end();jt++) {
		if (anteil)
			zu->push_back(base_name(jt->pfad));
		else
			zu->push_back(jt->pfad);
	} // 	for(set<elem2>::iterator jt=ergp->begin();jt!=ergp->end();jt++)
} // void find2cl::zuvec(svec *zu,uchar anteil/*=0*/)
#endif // altfind

#ifdef neufind
const bool elem3::operator<(const elem3& el) const {return (this->pfad<el.pfad);}
const bool wele::operator<(const wele& el) const {return (this->pfad<el.pfad);}

set<wele>::iterator find3cl::it;
set<wele> *find3cl::wurzp;
set<elem3> *find3cl::ergp;
long *find3cl::maxdepthp;
int *find3cl::folgep;
regex_t *find3cl::regp;
int *find3cl::typbitp;
time_t *find3cl::mabp,*find3cl::mbisp;
int *find3cl::obverbp, *find3cl::oblogp;
int *find3cl::nurexecp;

int find3cl::verarbeit(const char *fpath, const struct stat *sb, int tflag, struct FTW *ftwbuf)
{
	if (
			(*typbitp&B_Datei && S_ISREG(sb->st_mode)) ||
			(*typbitp&B_Verzn && S_ISDIR(sb->st_mode)) ||
			(*typbitp&B_Chdev && S_ISCHR(sb->st_mode)) ||
			(*typbitp&B_Block && S_ISBLK(sb->st_mode)) ||
			(*typbitp&B_FIFO && S_ISFIFO(sb->st_mode)) ||
			(*typbitp&B_Link && S_ISLNK(sb->st_mode)) ||
			(*typbitp&B_Sock && S_ISSOCK(sb->st_mode))) {
		string pfad;
		char buff[FILENAME_MAX];
		buff[0]=0;
		struct stat lst={0};
		if (tflag==FTW_SL) {
			ssize_t len = readlink(fpath, buff, sizeof(buff)-1);
			if (len==-1) {
				//          pfad=fpath;
			} else {
				buff[len] = '\0';
				if (char* actp=realpath(((buff[0]=='/'?"":dir_name(fpath)+'/')+buff).c_str(),NULL)) {
					pfad=actp;
					free(actp);
					if (!lstat(pfad.c_str(),&lst)) {
						if (S_ISDIR(lst.st_mode)) {
							if (*folgep&Fol_Ver) {
								if (*obverbp>2) fLog(blaus+Txk[T_Linkverzeichnis]+schwarz+pfad,*obverbp,*oblogp);
								wurzp->insert(wele(pfad,it->maxd-ftwbuf->level));
							} //               if (*folgep&Fol_Ver)
						} //             if (S_ISDIR(lst.st_mode))
					} //           if (!lstat(pfad.c_str(),&lst))
				} //         if (char* actp=realpath(((buff[0]=='/'?"":dir_name(fpath)+'/')+buff).c_str(),NULL))
			} //       if (len==-1)
			if (pfad.empty()) pfad="?????";
		} //     if (tflag==FTW_SL)
		const char *vgl=(tflag==FTW_SL&&*folgep&Fol_Mus)?pfad.c_str():fpath;
		if (!regexec(regp, vgl, 0, 0, 0)) {
			if ( tflag!=FTW_SL ||
					(*typbitp&B_Datei && S_ISREG(lst.st_mode)) ||
					(*typbitp&B_Verzn && S_ISDIR(lst.st_mode)) ||
					(*typbitp&B_Chdev && S_ISCHR(lst.st_mode)) ||
					(*typbitp&B_Block && S_ISBLK(lst.st_mode)) ||
					(*typbitp&B_FIFO && S_ISFIFO(lst.st_mode)) ||
					(*typbitp&B_Link && S_ISLNK(lst.st_mode)) ||
					(*typbitp&B_Sock && S_ISSOCK(lst.st_mode))) {
				const int obt{*folgep&Fol_Dat&&!pfad.empty()?1:0};
				const struct stat *sp{obt?&lst:sb};
				if ((!*mabp||sp->st_mtime>=*mabp)&&(!*mbisp||sp->st_mtime<=*mbisp))
					if (!*nurexecp || (sp->st_mode & S_IXUSR || sp->st_mode & S_IXGRP || sp->st_mode & S_IXOTH))
						ergp->insert(elem3(obt?pfad:fpath,sp,tflag,ftwbuf,obt?fpath:pfad,obt?*sb:lst));
			} //       if ( tflag!=FTW_SL || ...
		} //     if (!regexec(regp, vgl, 0, 0, 0))
	} //   if ( .. ||.. (*typbitp&B_Datei && S_ISREG(sb->st_mode)) ||
	if (*maxdepthp>=0 && ftwbuf->level>=it->maxd) {
		return FTW_SKIP_SUBTREE;
	}
	if (*obverbp>2||*oblogp>2) fLog("fpath: "+blaus+fpath+schwarz,*obverbp,*oblogp);
	return FTW_CONTINUE;
} //     static int verarbeit(const char *fpath, const struct stat *sb, int tflag, struct FTW *ftwbuf)

find3cl::find3cl(int _obverb/*=0*/,int _oblog/*=0*/):obverb(_obverb),oblog(_oblog)
{
	obverbp=&obverb;
	oblogp=&oblog;
}

int find3cl::dofind()
{
	// aeussere Schleife so lange durchlaufen, bis in der inneren Schleife nichts mehr zu tun ist; dort wird ggf. wurz erweitert
	while (1) {
		int gearbeitet{0};
		for(it=wurz.begin();it!=wurz.end();it++) {
			if (fertige.find(*it)!=fertige.end()) continue;
			if (it->pfad.empty()) continue;
			struct stat st={0};
			if (lstat(it->pfad.c_str(),&st)) continue;
			gearbeitet=1;
			if (obverb>2||oblog>1) fLog("Iterator: "+blaus+it->pfad+schwarz+Txk[T_Tiefe]+blau+ltoan(it->maxd)+schwarz,obverb,oblog);
			if (nftw(it->pfad.c_str(), this->verarbeit, 20, flags) == -1) {
				perror((rots+Txk[T_Fehler]+"nftw ('"+it->pfad+"')"+schwarz).c_str());
				//				exit(EXIT_FAILURE);
			} //       if (nftw(it->pfad.c_str(), this->verarbeit, 20, flags) == -1)
			fertige.insert(*it);
		} //     for(it=wurz.begin();it!=wurz.end();it++)
		if (!gearbeitet) break;
	} //   while (1)
	return 0;
} //     int dofind()

int find3cl::ausgeb()
{
	size_t j{0};
	// zum Schutz vor gemischten Ausgaben
	pthread_mutex_lock(&printf_mutex);
	for(set<elem3>::iterator jt=erg.begin();jt!=erg.end();jt++) {
		j++;
		printf("%7ld) %-3s %2d ",j,
				(jt->tflag == FTW_D) ?   "d"   : (jt->tflag == FTW_DNR) ? "dnr" :
				(jt->tflag == FTW_DP) ?  "dp"  : (jt->tflag == FTW_F) ?   "f" :
				(jt->tflag == FTW_NS) ?  "ns"  : (jt->tflag == FTW_SL) ?  "sl" :
				(jt->tflag == FTW_SLN) ? "sln" : "???", jt->ftw.level);

		if (jt->tflag == FTW_NS)
			printf("-------");
		else
			printf(" %7jd",(intmax_t) jt->sb.st_size);
		struct tm *tp=localtime(&jt->sb.st_mtime);
		string zeit;
		thr_strftime(tp,&zeit,"%F %X");
		//        printf(" %s %-40s %5d %s",buf, jt->pfad.c_str(), jt->ftw.base, jt->pfad.c_str()+jt->ftw.base);
		printf(" %s %-40s",zeit.c_str(), jt->pfad.c_str());
		if (jt->tflag==FTW_SL) {
			tp=localtime(&jt->lst.st_mtime);
			thr_strftime(tp,&zeit,"%F %X");
			printf(" %s %s %s",folge&Fol_Dat?"<-":"->",zeit.c_str(),jt->lnk.c_str());
		}
		printf("\n");
	} //       for(set<elem3>::iterator jt=erg.begin();jt!=erg.end();jt++)
	pthread_mutex_unlock(&printf_mutex);
	return 0;
} //     int ausgeb()

int find3cl::finde(svec *wovp,const string& muster/*=string()*/,long tiefe/*=-1*/,
		int _typbit/*=B_Alle*/,int _folge/*=Fol_Dat*/,time_t _mab/*=0*/,time_t _mbis/*=0*/,int obicase/*=0*/,int _nurexec/*=0*/,int obnoext/*=0*/)
{
	int ret{0};
	maxdepthp=&maxdepth;
	*maxdepthp=tiefe;
	string wo;
	for(size_t iv{0};iv<wovp->size();iv++) {
		wo+=(*wovp)[iv];wo+=" ";
		if (char* actp=realpath((*wovp)[iv].c_str(),NULL)) {
			const string pfad{actp};
			free(actp);
			wurz.insert(wele(pfad,maxdepth));
		} else {
			wurz.insert(wele((*wovp)[iv],maxdepth));
		} //     if (char* actp=realpath(*wovp[iv].c_str(),NULL)) else
	} //   for(size_t iv=0;iv<*wovp.size();iv++)
	wurzp=&wurz;
	ergp=&erg;
	regp=&regs;
	folgep=&folge;
	*folgep=_folge;
	typbitp=&typbit;
	*typbitp=_typbit;
	mabp=&mab;
	*mabp=_mab;
	mbisp=&mbis;
	*mbisp=_mbis;
	nurexec=_nurexec;
	nurexecp=&nurexec;
	// if (argc > 2 && strchr(argv[2], 'd') != NULL) f.flags |= FTW_DEPTH; // erst Unterverzeichnisse, dann aktuelles Verzeichnis
	// if (argc > 2 && strchr(argv[2], 'p') != NULL)
	flags |= FTW_ACTIONRETVAL;
	flags |= FTW_PHYS;
	if (regcomp(&regs, muster.c_str(),(obnoext?0:REG_EXTENDED)|REG_NOSUB|(obicase?REG_ICASE:0))) { 
		return REGFEHLER;
	}
	ret=dofind();
	regfree(&regs);
	if (obverb|oblog) {
		yLog(obverb,oblog,0,0,"%s%s%s%s%s%s%s%s'%s%s'%s%lu%s%s%s%d%s%s%s%d%s%s%s%d%s%s%s%zu%s",
				Txk[T_Suche_in],blau,wo.c_str(),schwarz,Txk[T_nach],blau,muster.c_str(),schwarz,obicase?"(ic)":"",Txk[T_Tiefe],blau,tiefe,schwarz,
				Txk[T_Typbit],blau,typbit,schwarz,Txk[T_Folge],blau,folge,schwarz,Txk[T_noext],blau,obnoext,schwarz,Txk[T_Ergebnis],
				gruen,ergp->size(),schwarz);
	} // 	if (obverb|oblog)
	if (obverb>1) ausgeb();
	return ret;
} // int find3cl::finde(

void find3cl::zuvec(svec *zu,uchar anteil/*=0*/)
{
	for(set<elem3>::iterator jt=erg.begin();jt!=erg.end();jt++) {
		if (anteil)
			zu->push_back(base_name(jt->pfad));
		else
			zu->push_back(jt->pfad);
	} // 	for(set<elem3>::iterator jt=erg.begin();jt!=erg.end();jt++)
} // void find3cl::zuvec(svec *zu,uchar anteil/*=0*/)
#endif // neufind

#if defined(altfind) && defined(neufind)
void findfile(svec *qrueckp,uchar findv,int obverb/*=0*/,int oblog/*=0*/,uchar anteil/*=0*/,
		const string& wo/*="."*/,const string& muster/*=string()*/,long tiefe/*=-1*/,int _typbit/*=B_Alle*/,
		int _folge/*=Fol_Dat*/, time_t _mab/*=0*/,time_t _mbis/*=0*/,int obicase/*=0*/,int nurexec/*=0*/,int obnoext/*=0*/,uchar nureins/*=0*/)
{
	svec wov;
	switch (findv) {
		case 2: case 3:
			// wenn nur ein Verzeichnis, dann darf das auch Leerstellen enthalten
			if (nureins) {
				wov<<wo;
			} else {
				aufSplit(&wov, wo);
			}
			setfaclggf(wov[wov.size()-1],obverb>1?obverb-1:0,oblog,/*obunter=*/wahr,/*mod=*/4);
			break;
	} // 	switch (findv)
	if (findv==2) {
		find2cl f(obverb,oblog);
		f.finde(&wov,muster,tiefe,_typbit,_folge,_mab,_mbis,obicase,nurexec,obnoext);
		f.zuvec(qrueckp,anteil);
	} else if (findv==3) {
		find3cl f(obverb,oblog);
		f.finde(&wov,muster,tiefe,_typbit,_folge,_mab,_mbis,obicase,nurexec,obnoext);
		f.zuvec(qrueckp,anteil);
	} // 	if (findv==2) else if (findv==3)
} // void findfile(svec *qrueckp,uchar findv,int obverb/*=0*/,int oblog/*=0*/,uchar anteil/*=0* ...
#endif // #if defined(altfind) && defined(neufind)

// 1= Dateien unterschiedlich, 0 = gleich; obzeit => vergleiche auch die letzte Aenderungszeit
int dateivgl(const string& d1, const string& d2,uchar obzeit/*=0*/)
{
	int erg{0};
	// wenn ein Unterschied am Anfang der Dateien war oder die Groesse < 300 kB lag, war boost schneller; 'cmp' war nie schneller als 'diff'.
	////	perfcl prf("vgl");
	struct stat st1{0},st2{0};
	const int lst1{lstat(d1.c_str(),&st1)},
				lst2{lstat(d2.c_str(),&st2)};
	if (lst1 || lst2) {
		erg=1;
	} else if (obzeit) {
		if (st1.st_mtime!=st2.st_mtime && st1.st_mtime+3600!=st2.st_mtime && st1.st_mtime-3600!=st2.st_mtime)
			erg=1;
	} // 	if (lst1 || lst2)
	if (!erg) {
		if (lst1||st1.st_size>1000000) {
			erg=systemrueck("diff -q '"/*"cmp --silent "*/+d1+"' '"+d2+"'",0,0,/*rueck=*/0,/*obsudc=*/0);
		} else {
			// http://www.cplusplus.com/forum/general/94032/
			boost::iostreams::mapped_file_source f1(d1);
			boost::iostreams::mapped_file_source f2(d2);
			if(f1.size()==f2.size() && equal(f1.data(),f1.data()+f1.size(),f2.data())) ;
			else erg=1;
		} // 		if (lst1||st1.st_size>1000000) else
	} // 	if (!erg)
	////	prf.ausgeb();
	return erg;
} // int dateivgl(const string& d1, const string& d2)

// wird aufgerufen in: paramcl::setzhylavz, pruefcvz, virtrueckfragen
void kuerzevtz(string *vzp)
{
	if (!vzp->empty()) {
		if (vzp->at(vzp->length()-1)==vtz)
			vzp->resize(vzp->length()-1);
	} //   if (!vzp->empty())
} // kuerzevtz

// Verzeichnis auf Github
const string& gitv{
#include "gitvdt"
};
// Pfad fuer Aufruf aus crontab
// Datei wird erstellt in configure
const string& spath=
#include "spath"
;
const string s_true{"true"};
const string s_dampand{"&&"};
const string s_gz{"gz"};
const string& defvors{"https://github.com/"+gitv+"/"};
const string& defnachs{"/archive/master.tar.gz"};

// wird aufgerufen in main
hcl::hcl(const int argc, const char *const *const argv,const char* const DPROG,const uchar mitcron):DPROG(DPROG),mitcron(mitcron)
{
	tstart=clock();
	_DPROG=DPROG;
	holbefz0(argc,argv);
	tmmoelen=elemzahl(tmmoegl);
	langu=holsystemsprache(obverb);
	virtlgnzuw();
	pthread_mutex_init(&printf_mutex, NULL);
	pthread_mutex_init(&getmutex, NULL);
	pthread_mutex_init(&timemutex, NULL);
	_mpfad=mpfad=meinpfad();
	meinname=base_name(mpfad); // argv[0];
	uebers<<schwarz<<Txk[T_Programm]<<blau<<mpfad<<schwarz<<", V: "<<blau<<fixed<<setprecision(5)<<versnr<<defaultfloat<<" "<<schwarz; // fuer virtzeigueberschrift
	pruefinstv();
#ifdef _WIN32
	logvz = "C:\\Dokumente und Einstellungen\\All Users\\Anwendungsdaten";
#elif linux
	logvz = "/var/log";
#endif
	logdname = meinname+".log";
	setzlog();
	pruefplatte(); // geht ohne Logaufruf, falls nicht #define systemrueckprofiler
	linstp=new linst_cl(obverb,oblog);
} // hcl::hcl

int schluss(const int fnr,const string text,int oblog)
{
	if (!text.empty()) {
		fLog(blaus+_mpfad+schwarz+": "+text,1,oblog);
	}
	exit(fnr);
} // int schluss

// zum Aufruf virtueller Funktionen aus dem Konstruktur verschoben
void hcl::lauf()
{
	virtzeigueberschrift();
	virtVorgbAllg();
	pvirtVorgbSpeziell(); // die Vorgaben, die in einer zusaetzlichen Datei mit einer weiteren Funktion "void hhcl::pvirtVorgbSpeziell()" ueberladbar sind
	virtinitopt();
	parsecl();
	if (obhilfe==3) { // Standardausgabe gewaehrleisten
		virtMusterVorgb();
	} else {
		virtlieskonfein();
		verarbeitkonf();
//		opn.gibomapaus();
//		if (obverb) opn.oausgeb(gruen);
	} // if (obhilfe==3)
//	opn.omapzuw();
	pvirtmacherkl();
	if (zeighilfe(&erkl)) {
		virttesterg();
		exit(schluss(1));
	}
	pvirtvorzaehler();
	lieszaehlerein();
	if (obvi) dovi(); 
	else if (obvs) {
		svec rueck;
		systemrueck("cd \""+instvz+"\";ls -l $(grep 'DTN' vars|sed 's/DTN::=//g')",-1,oblog,&rueck);
		exit(schluss(systemrueck("cd \""+instvz+"\"; sh viall"+devtty,/*obverb=*/0,/*oblog=*/0,/*rueck=*/0,/*obsudc=*/1),
					Txk[T_nach_sh_viall_beendet],oblog));
	}
	else if (zeigvers) {
		virtzeigversion();
		exit(schluss(7,violetts+Txk[T_Ende]+Txk[T_zeigvers]+schwarz,oblog));
	} // if (zeigvers)
	else if (!keineverarbeitung) {
		pvirtvorrueckfragen();
		virtrueckfragen();
		pvirtvorpruefggfmehrfach();
		pruefggfmehrfach();
		if (logdateineu) tuloeschen(logdt,string(),obverb,oblog);
		hLog(Txk[T_Logpfad]+drots+loggespfad+schwarz+Txk[T_oblog]+drot+ltoan((int)oblog)+schwarz+")");
		virtpruefweiteres();
	} // 	if (!keineverarbeitung)
	if (mitcron) pruefcron(string()); // soll vor Log(Txk[T_Verwende ... stehen
	if (!keineverarbeitung) {
		pvirtfuehraus();
	} //  if (!keineverarbeitung)
	virtautokonfschreib();
	gitpull(DPROG);
	if (mitpids) 
		wartaufpids(&pidv,0,obverb,oblog,Txk[T_in_main_pidv_am_Schluss]);
	if (obsetz) {
		setzzaehler();
		schreibzaehler();
	} // 	if (obsetz)
	virtschlussanzeige();
	hLog(violetts+Txk[T_Ende]+schwarz);
} // hcl::lauf()

// wird aufgerufen in: hcl::hcl
void hcl::holbefz0(const int argc, const char *const *const argv)
{
	cl=argv[0];
	for(int i=1;i<argc;i++)
		if (argv[i][0]) {
			if (!obverb && argv[i][1]) {
				Sprache altSpr=Txk.lgn;
				for(int akts=0;akts<SprachZahl;akts++) {
					Txk.lgn=(Sprache)akts;
					if ((strchr("-/",argv[i][0])&&!strcmp(argv[i]+1,Txk[T_v_k])) || 
							(!strncmp(argv[i],"--",2)&&!strcmp(argv[i]+2,Txk[T_verbose_l]))) { // -v, -w, -verbose, -wortreich
						cout<<violett<<Txk[T_hcl_hcl]<<schwarz<<endl;
						obverb=1;
					} // if ((strchr...
				} //         for(int akts=0;akts<SprachZahl;akts++)
				Txk.lgn=altSpr;
			} // 			if (!obverb && argv[i][1])
			argcmv.push_back(argcl(i,argv)); 
			cl+=" ";
			cl+=argv[i];
		} //     if (argv[i][0])
} // void hcl::holbefz0

// wird aufgerufen in: hcl::hcl
string holsystemsprache(int obverb/*=0*/)
{
	if (obverb)
		cout<<violett<<Txk[T_holsystemsprache]<<schwarz<<endl;
	schAcl<WPcl> cglangA("cglangA"); // Systemsprach-Konfiguration
	string ret;
	// OpenSuse, Fedora, Debian
	const char* const langdt[]{"/etc/sysconfig/language","/etc/locale.conf","/etc/default/locale","/etc/sysconfig/i18n"};
	const char* const langvr[]{"RC_LANG","LANG","LANG","LANG"};
	for (size_t lind=0;lind<elemzahl(langdt);lind++) {
		struct stat langstat{0};
		if (!lstat(langdt[lind],&langstat)) {
			cglangA.sinit(1, langvr[lind]);
			confdcl langcd(langdt[lind],obverb);
			langcd.kauswert(&cglangA,obverb);

			if (cglangA[0]) if (!cglangA[0]->wert.empty()) {
				ret= cglangA[0]->wert[0];
				//// <<"Sprache gefunden in "<<blau<<langdt[lind]<<schwarz<<": "<<rot<<ret<<schwarz<<endl;
				break;
			} // 			if (!cglangA[0].wert.empty())

		} //     if (!lstat(hylacdt.c_str(),&hstat))
	} // 	for(size_t lind=0;lind<langdt.size())
	if (obverb)
		cout<<violett<<Txk[T_Ende]<<Txk[T_holsystemsprache]<<schwarz<<endl;
	return ret;
} // string holsystemsprache

// wird aufgerufen in: virtrueckfragen, parsecl, virtlieskonfein, hcl::hcl nach holsystemsprache
void hcl::virtlgnzuw()
{
	//// int altobverb=obverb;
	//// obverb=1;
	fLog(violetts+Txk[T_virtlgnzuw_langu]+schwarzs+": "+langu,obverb,oblog);
	//// obverb=altobverb;
	if (langu=="d" || langu=="D" || langu=="deutsch" || langu=="Deutsch") {
		Txk.lgn=deutsch;
	} else if (langu=="e" || langu=="E" || langu=="english" || langu=="english" || langu=="English" || langu=="Englisch") {
		Txk.lgn=englisch;
	} else {
		Txk.lgn=deutsch;
	} // 	if (langu=="d" || langu=="D" || langu=="deutsch" || langu=="Deutsch") else else
	Tx.lgn=Txk.lgn;
} // void hcl::virtlgnzuw

// wird aufgerufen in paramcl::paramcl, pruefunpaper, holvomnetz, kompilbase, kompilfort
int hcl::pruefinstv()
{
	int erg{0};
	////	if (instvz.empty()) KLA
	////		instvz=gethome()+vtz+meinname;
	erg=pruefverz(instvz,obverb,oblog);
	////	KLZ // 	if (instvz.empty()) 
	return erg;
} // int hcl::pruefinstv()

// wird aufgerufen in hcl::hcl, von der von hcl abgeleiteten Klasse, dort virtlieskonfein()
void hcl::setzlog()
{
	loggespfad=logvz+vtz+logdname;
	logdt=&loggespfad.front();
} // void hcl::setzlog()

// wird aufgerufen in hcl::hcl
void pruefplatte()
{
  struct statvfs fp{0};
  const string platte{"/"};
  statvfs(platte.c_str(),&fp);   
  if (fp.f_bsize * fp.f_bfree < 100000) { // wenn weniger als 100 MB frei sind ...
    systemrueck("pkill postdrop",0,0,/*rueck=*/0,/*obsudc=*/1);
  }
} // pruefplatte


// wird aufgerufen in lauf
void hcl::virtVorgbAllg()
{
	cronminut="0";
	autoupd=1;
	// um z.B. spezielle Vorgaben (s. VorgbSpeziell) vom Server abhaengig machen zu koennen
#ifdef _WIN32
	//// char lpszUsername[255]; DWORD dUsername = sizeof(lpszUsername); GetUserName(lpszUsername, &dUsername);
	dcpt = sizeof(cpt);
	GetComputerName(cpt,&dcpt);
#elif linux // WIN32
	//// uid_t userId = getuid(); passwd* pw = getpwuid(userId); pw->pw_name<<endl;
	cptlen = MAXHOSTNAMELEN;
	gethostname(cpt, cptlen);
#endif // WIN32 else
} // void hhcl::virtVorgbAllg


// wird aufgerufen in lauf
void hcl::virtinitopt()
{
	opn<<new optcl(/*pname*/"language",/*pptr*/&langu,/*art*/pstri,T_lg_k,T_language_l,/*TxBp*/&Txk,/*Txi*/T_sprachstr,/*wi*/1,/*Txi2*/-1,/*rottxt*/string(),/*wert*/-1,/*woher*/1,T_Sprachen);
	opn<<new optcl(/*pname*/"language",/*pptr*/&langu,/*art*/pstri,T_lang_k,T_lingue_l,/*TxBp*/&Txk,/*Txi*/-1,/*wi*/1,/*Txi2*/-1,/*rottxt*/string(),/*wert*/-1,/*woher*/1,-1);
	opn<<new optcl(/*pptr*/&obverb,/*art*/puchar,T_v_k,T_verbose_l,/*TxBp*/&Txk,/*Txi*/T_Bildschirmausgabe_gespraechiger,/*wi*/1,/*Txi2*/-1,/*rottxt*/string(),/*wert*/1,/*woher*/1);
	opn<<new optcl(/*pname*/"logvz",/*pptr*/&logvz,/*art*/pverz,T_lvz_k,T_logvz_l,/*TxBp*/&Txk,/*Txi*/T_waehlt_als_Logverzeichnis_pfad_derzeit,/*wi*/0,/*Txi2*/-1,/*rottxt*/string(),/*wert*/-1,/*woher*/!logvz.empty(),T_Logverzeichnis);
	opn<<new optcl(/*pname*/"logdname",/*pptr*/&logdname,/*art*/pstri,T_ld_k,T_logdname_l,/*TxBp*/&Txk,/*Txi*/T_logdatei_string_im_Pfad,/*wi*/0,/*Txi2*/T_wird_verwendet_anstatt,/*rottxt*/logvz,/*wert*/-1,/*woher*/!logdname.empty(),T_Logdateiname);
	opn<<new optcl(/*pname*/"oblog",/*pptr*/&oblog,/*art*/pint,T_l_k,T_log_l,/*TxBp*/&Txk,/*Txi*/T_protokolliert_ausfuehrlich_in_Datei,/*wi*/1,/*Txi2*/T_sonst_knapper,/*rottxt*/loggespfad,/*wert*/1,/*woher*/1,T_Oblog_ausf_Protok);
	opn<<new optcl(/*pptr*/&logdateineu,/*art*/puchar,T_ldn_k,T_logdateineu_l,/*TxBp*/&Txk,/*Txi*/T_logdatei_vorher_loeschen,/*wi*/0,/*Txi2*/-1,/*rottxt*/string(),/*wert*/1,/*woher*/1);
	opn<<new optcl(/*pptr*/&akonfdt,/*art*/pfile,T_kd_k,T_konfdatei_l,/*TxBp*/&Txk,/*Txi*/T_verwendet_Konfigurationsdatei_string_anstatt,/*wi*/0,/*Txi2*/-1,/*rottxt*/string(),/*wert*/-1,/*woher*/1);
	opn<<new optcl(/*pptr*/&obhilfe,/*art*/puchar,T_h_k,T_hilfe_l,/*TxBp*/&Txk,/*Txi*/T_Erklaerung_haeufiger_Optionen,/*wi*/255,/*Txi2*/-1,/*rottxt*/string(),/*wert*/1,/*woher*/1);
	opn<<new optcl(/*pptr*/&obhilfe,/*art*/puchar,T_lh_k,T_lhilfe_l,/*TxBp*/&Txk,/*Txi*/T_Erklaerung_aller_Optionen,/*wi*/255,/*Txi2*/-1,/*rottxt*/string(),/*wert*/2,/*woher*/1);
	opn<<new optcl(/*pptr*/&obhilfe,/*art*/puchar,T_fgz_k,T_fgz_l,/*TxBp*/&Txk,/*Txi*/-1,/*wi*/255,/*Txi2*/-1,/*rottxt*/string(),/*wert*/1,/*woher*/1);
	opn<<new optcl(/*pptr*/&obhilfe,/*art*/puchar,T_sh,T_standardhilfe,/*TxBp*/&Txk,/*Txi*/-1,/*wi*/255,/*Txi2*/-1,/*rottxt*/string(),/*wert*/3,/*woher*/1);
	opn<<new optcl(/*pptr*/&obhilfe,/*art*/puchar,T_libtest,T_libtest,/*TxBp*/&Txk,/*Txi*/-1,/*wi*/255,/*Txi2*/-1,/*rottxt*/string(),/*wert*/4,/*woher*/1);
	opn<<new optcl(/*pname*/"cronminut",/*pptr*/&cronminut,/*art*/pdez,T_cm_k,T_cronminuten_l,/*TxBp*/&Txk,/*Txi*/T_Alle_wieviel_Minuten_soll,/*wi*/1,/*Txi2*/T_aufgerufen_werden_0_ist_gar_nicht,/*rottxt*/meinname,/*wert*/-1,/*woher*/1,T_Intervall_Minuten);
	opn<<new optcl(/*pptr*/&obvi,/*art*/puchar,T_vi_k,T_vi_l,/*TxBp*/&Txk,/*Txi*/T_Konfigurationsdatei,/*wi*/0,/*Txi2*/T_Logdatei_usw_bearbeiten_sehen,/*rottxt*/akonfdt,/*wert*/1,/*woher*/1);
	opn<<new optcl(/*pptr*/&obvs,/*art*/puchar,T_vs_k,T_vs_l,/*TxBp*/&Txk,/*Txi*/T_Quelldateien_in,/*wi*/0,/*Txi2*/T_bearbeiten_sehen,/*rottxt*/instvz,/*wert*/1,/*woher*/1);
	opn<<new optcl(/*pptr*/&autoupd,/*art*/pint,T_autoupd_k,T_autoupd_l,/*TxBp*/&Txk,/*Txi*/T_Programm_automatisch_aktualisieren,/*wi*/1,/*Txi2*/-1,/*rottxt*/string(),/*wert*/1,/*woher*/1);
	opn<<new optcl(/*pptr*/&rzf,/*art*/puchar,T_rf_k,T_rueckfragen_l,/*TxBp*/&Txk,/*Txi*/T_alle_Parameter_werden_abgefragt_darunter_einige_hier_nicht_gezeigte,/*wi*/1,/*Txi2*/-1,/*rottxt*/string(),/*wert*/1,/*woher*/1);
	opn<<new optcl(/*pptr*/&nrzf,/*art*/puchar,T_krf_k,T_keinerueckfragen_l,/*TxBp*/&Txk,/*Txi*/T_keine_Rueckfragen_zB_aus_Cron,/*wi*/1,/*Txi2*/-1,/*rottxt*/string(),/*wert*/1,/*woher*/1);
	opn<<new optcl(/*pptr*/&zeigvers,/*art*/puchar,T_info_k,T_version_l,/*TxBp*/&Txk,/*Txi*/T_Zeigt_die_Programmversion_an,/*wi*/1,/*Txi2*/-1,/*rottxt*/string(),/*wert*/1,/*woher*/1);

	//  for(int i=argc-1;i>0;i--) KLA if (argv[i][0]==0) argc--; KLZ // damit fuer das Compilermakro auch im bash-script argc stimmt
	//// <<"Ende virtinitopt"<<endl;
} // hcl::virtinitopt

// wird aufgerufen in lauf
void hcl::parsecl()
{
	hLog(violetts+Txk[T_parsecl]+schwarz);
	// (opts[optslsz].pruefpar(&argcmv,&i,&obhilfe))
	if (obverb) obverb=0; // damit nicht aus -v obverb=2 wird
	vector<argcl>::iterator ap,apn;
	for(ap=argcmv.begin();ap!=argcmv.end();ap++) {
		uchar nichtspeichern{0}, gegenteil{0}, kurzp{0}, langp{0};
		const char *acstr=ap->argcs;
		//// <<rot<<"acstr: "<<schwarz<<acstr<<endl;
		unsigned aclen=strlen(acstr);
		if (aclen>1) {
			if (aclen>2 && acstr[0]=='-'&&acstr[1]=='-') {
				langp=1;
				acstr+=2;
				aclen-=2;
			} else if (strchr("-/",acstr[0])) {
				kurzp=1;
				acstr+=1;
				aclen-=1;
			} // 			if (aclen>2 && acstr[0]=='-'&&acstr[1]=='-') else if
			if (kurzp||langp) {
				if (aclen>1 && *acstr=='1') {
					nichtspeichern=1; 
					acstr++;
					aclen--;
				} // 				if (aclen>1 && *acstr=='1')
				if (aclen>2 && acstr[0]=='n'&&acstr[1]=='o') {
					gegenteil=1;
					acstr+=2;
					aclen-=2;
				} // 				if (aclen>2 && acstr[0]=='n'&&acstr[1]=='o')
				map<const char* const,optcl const*> *omp=0;
				map<const char* const,optcl const*>::iterator omit;
				if (langp) omp=&opn.olmap;
				else if (kurzp) omp=&opn.okmap;
				if (omp) {
////					caus<<"acstr: '"<<acstr<<"', omp->size(): "<<omp->size()<<endl;
					for(omit=omp->begin();omit!=omp->end();omit++) {
						//// <<"omit: "<<omit->second->pname<<", "<<omit->first<<endl;
						// omit ist also jetzt iterator fuer die relevante map auf die aktuelle Option (kurz oder lang)
						if (omit->first) if (!strcmp(omit->first,acstr)) {
							ap->agef++; // Parameter gefunden
							hLog(Txk[T_Parameter]+blaus+acstr+schwarz+Txk[T_gefunden]+(omit->second->pptr?"1":"0"));
							if (omit->second->pptr) {
								hLog("pptr gefunden");
								// pzuweis liefert -1, wenn der naechste Parameter als Inhalt verwendet wurde, sonst wiefalsch
								apn=ap; apn++;
								const char *nacstr=apn==argcmv.end()?"":apn->argcs;
								optcl* trick=(optcl*)omit->second;
								int wiefalsch{trick->pzuweis(nacstr,gegenteil,nichtspeichern)};
								//int wiefalsch=omit->second->pzuweis(nacstr,gegenteil,nichtspeichern);
								if (wiefalsch==-1) { // String-Parameter erfolgreich zugewiesen
									ap++;
									ap->agef++; // Zusatzparameter gefunden
									if (ap==argcmv.end()) break;
								}
								if (wiefalsch<=0) { // erfolgreich zugewiesen
									if (omit->second->pptr==&langu) {
										virtlgnzuw();
									} else if (omit->second->pptr==&logvz || omit->second->pptr==&logdname) {
										setzlog();
									} else if (omit->second->pptr==&cronminut) {
										keineverarbeitung=1;
										cmeingegeben=1;
									}
									opn.setzbemerkwoher(trick,/*ibemerk=*/string(),/*vwoher=*/3);
									//opn.setzbemerkwoher(omit->second,/*ibemerk=*/string(),/*vwoher=*/3);
								} else {
									if (!obhilfe) obhilfe=1;
								} // 								if (wiefalsch<=0) else
							} // 								if (omit->second->pptr)
							break; // Parameter schon gefunden, die anderen nicht mehr suchen
						} // 							if (!omit->first.find(acstr))
					} // 						for(omit=omp->begin();omit!=omp->end();omit++)
					if (ap==argcmv.end()) break;
				} // 					if (omp)
			} // 			if (kurzp||langp)
		} // if (aclen>1)
	} // 	for(ap=argcmv.begin();ap!=argcmv.end();ap++)
//	if (obverb) opn.oausgeb(gelb);
	for(size_t i=0;i<argcmv.size();i++) {
		if (!argcmv[i].agef) {
			exit(schluss(17,rots+"Parameter: "+gruen+argcmv[i].argcs+rot+Txk[T_nicht_erkannt]+schwarz));
			if (!obhilfe) obhilfe=1;
		} //     if (!argcmv[i].agef)
	} //   for(size_t i=0;i<argcmv.size();i++)
	hLog(violetts+Txk[T_Ende]+Txk[T_parsecl]+schwarz);
	return;
} // void hcl::parsecl()

// wird aufgerufen in lauf
void hcl::virtMusterVorgb()
{
} // void hhcl::MusterVorgb

// wird aufgerufen in lauf; liest die Konfiguration ein
void hcl::virtlieskonfein()
{
	hLog(violetts+Txk[T_virtlieskonfein]+schwarz);
//	if (akonfdt.empty()) akonfdt=aktprogverz()+".conf";
	if (akonfdt.empty()) {
		svec rue;
		// aus Datenschutzgruenden sollte das Home-Verzeichnis zuverlaessig ermittelt werden
		systemrueck("getent passwd $(logname)|cut -d: -f6",0,0,&rue);
		if (rue.size()) {
			akonfdt=rue[0]+vtz+"."+DPROG+".conf";
		}
	} // 	if (akonfdt.empty()) 
	// agcnfA.init muss spaetetens am Anfang von getcommandl0 kommen
	// sodann werden die Daten aus gconf den einzelenen Klassenmitgliedsvariablen zugewiesen 
	// die Reihenfolge muss der in agcnfA.init (in getcommandl0) sowie der in virtrueckfragen entsprechen
// afcd.cinit(akonfdt,&agcnfA,obverb,'=',/*mitclear=*/0); // hier werden die Daten aus der Datei eingelesen
	hccd.lies(akonfdt,obverb);
	hccd.kauswert(&opn,obverb,0);
	virtlgnzuw();
	setzlog();
	if (!hccd.obzuschreib) {
		for (map<string,optcl*>::iterator omit=opn.omap.begin();omit!=opn.omap.end();omit++) {
			if (omit->second->woher<2) {
				hccd.obzuschreib=1;
				break;
			} // 			if (omit->second->woher<2)
		} // 		for (map<string,optcl*>::iterator omit=opn.omap.begin();omit!=opn.omap.end();omit++)
	} // 	if (!hccd.obzuschreib)
	hLog(violetts+Txk[T_Ende]+Txk[T_virtlieskonfein]+schwarz);
	// <<violett<<"Ende virtlieskonfein, obzuschreib: "<<rot<<(int)hccd.obzuschreib<<schwarz<<endl;
} // void hcl::virtlieskonfein

// wird aufgerufen in lauf
void hcl::verarbeitkonf()
{
	hLog(violetts+Txk[T_verarbeitkonf]+schwarz);
	if (!nrzf&&obhilfe<=2) {
		for (size_t i=0;i<opn.size();i++) {
			if (!opn[i]->pname.empty() && !opn[i]->woher) {
				fLog(Txk[T_rueckzufragen_wegen]+rots+opn[i]->pname+schwarz,1,0);
				rzf=1;
			}
		} // 		for (size_t i=0;i<opn.size();i++)
	} // 	if (!nrzf&&obhilfe<=2)
	hLog(violetts+Txk[T_Ende]+Txk[T_verarbeitkonf]+schwarz);
} // void hcl::verarbeitkonf()

// wird aufgerufen in lauf
int hcl::zeighilfe(const stringstream *const erkl)
{
	hLog(string(Txk[T_Fertig_mit_Parsen_der_Befehlszeile])+(hccd.obzuschreib?Txk[T_ja]:Txk[T_nein]));
	// Ausgabe der Hilfe
	if (obhilfe) {
		// libtest
		if (obhilfe==4) { 
			cout<<meinname<<": "<<blau<<Txk[T_Testaufruf_wegen_Programmbibliotheken]<<schwarz<<endl;
		} else {
			// nicht standardhilfe
			if (obhilfe<3) {
				cout<<blau<<Txk[T_Gebrauch]<<drot<<meinname<<" [-<opt>|--<longopt> [<content>]] ..."<<schwarz<<endl; 
				cout<<erkl->str()<<endl;
			}
			cout<<blau<<Txk[T_Optionen_die_nicht_gespeichert_werden]<<schwarz<<endl;
			for(size_t j=0;j<opn.size();j++) {
				if (opn[j]->pname.empty() && (obhilfe>1 || opn[j]->wi)) {
					opn[j]->hilfezeile(Txk.lgn);
				}
			} //     for(size_t j=0;j<opn.size();j++)
			cout<<blau<<Txk[T_Optionen_die_in_der_Konfigurationsdatei_gespeichert_werden]<<schwarz<<endl;
			for(size_t j=0;j<opn.size();j++) {
				if (!opn[j]->pname.empty() && (obhilfe>1 || opn[j]->wi) &&(opn[j]->kurzi!=-1 || opn[j]->langi!=-1))
					opn[j]->hilfezeile(Txk.lgn);
			} //     for(size_t j=0;j<opn.size();j++)
////			opn.oausgeb(violett);
		} // if (obhilfe==4) else
		return 1;
	} // if (obhilfe)
	return 0;
} // int hcl::zeighilfe(const stringstream *const erkl)

// wird aufgerufen in lauf
void hcl::lieszaehlerein()
{
	hLog(violetts+Txk[T_lieszaehlerein]+schwarz);
	azaehlerdt=aktprogverz()+".zaehl";
	////<<"0 zcnfA.zahl: "<<zcnfA.size()<<endl;
	zcnfA<<new WPcl("aufrufe",&aufrufe,plong);
	zcnfA<<new WPcl("lDatum",&laufrtag,pdat);
	zcnfA<<new WPcl("tagesaufr",&tagesaufr,plong);
	zcnfA<<new WPcl("monatsaufr",&monatsaufr,plong);
	////<<"1 zcnfA.zahl: "<<zcnfA.size()<<endl;
	confdcl zlzn;
	zlzn.lies(azaehlerdt,obverb);
	////<<"azaehlerdt: "<<blau<<azaehlerdt<<schwarz<<endl;
	zlzn.kauswert(&zcnfA);
	//// if (&aufrufe) <<blau<<"aufrufe: "<<schwarz<<aufrufe<<endl;
	if (&laufrtag) {
		string ldat;
		thr_strftime(&laufrtag,&ldat);
		////<<blau<<"letztes Datum: "<<schwarz<<ldat<<endl;
	}
	//// if (&tagesaufr) <<blau<<"tagesaufr: "<<schwarz<<tagesaufr<<endl;
	//// if (&monatsaufr) <<blau<<"monatsaufr: "<<schwarz<<monatsaufr<<endl;
	hLog(violetts+Txk[T_Ende]+Txk[T_lieszaehlerein]+schwarz);
} // void hcl::lieszaehlerein

// wird aufgerufen in lauf
void hcl::dovi()
{
	svec d1, d2;
	d1<<smbdt;
	d2<<passwddt;
	d2<<groupdt;
	d2<<sudoersdt;
	dodovi(d1,d2);
} // void hcl::dovi()

// wird aufgerufen in lauf
void hcl::virtzeigversion(const string& ltiffv/*=string()*/)
{
	struct tm tm={0};
	//// char buf[100];
	cout<<endl<<Txk[T_Programm]<<violett<<mpfad<<schwarz<<endl;
	cout<<"Copyright: "<<blau<<Txk[T_Freie_Software]<<schwarz<<Txk[T_Verfasser]<<blau<<"Gerald Schade"<<schwarz<<endl;
	cout<<"Version: "<<blau<<versnr<<schwarz<<endl;
	strptime(__TIMESTAMP__,"%c", &tm);
	//// // <<tm.tm_sec<<" "<<tm.tm_min<<" "<<tm.tm_hour<<" "<<tm.tm_mday<<" "<<tm.tm_mon<<" "<<tm.tm_year<<" "<<tm.tm_wday<<" "<<tm.tm_yday<<" "<<tm.tm_isdst<<endl;
	//// strftime(buf, sizeof(buf), "%d.%m.%Y %T", &tm);
	//// cout<<Txk[T_Letzte_Programmaenderung]<<blau<<buf<<schwarz<<endl;
	cout<<Txk[T_Letzte_Programmaenderung]<<blau<<put_time(&tm,"%d.%m.%Y %T")<<schwarz<<endl;
	memset(&tm, 0, sizeof(struct tm));
	strptime((string(__DATE__)+" "+__TIME__).c_str(),"%b %d %Y %T", &tm);
	//// strftime(buf, sizeof(buf), "%d.%m.%Y %T", &tm);
	//// cout<<"              "<<Txk[T_Kompiliert]<<blau<<buf<<schwarz<<endl;
	cout<<"              "<<Txk[T_Kompiliert]<<blau<<put_time(&tm,"%d.%m.%Y %T")<<schwarz<<endl;
	cout<<Txk[T_Quelle]<<blau<<defvors/*//"https://github.com/libelle17/"*/<<meinname<<schwarz<<endl;
	cout<<Txk[T_Installationsverzeichnis]<<blau<<instvz<<schwarz<<endl;
	if (!ltiffv.empty())
		cout<<Txk[T_Libtiff_Version]<<blau<<ltiffv.substr(0,ltiffv.find("\n"))<<schwarz<<endl;
	cout<<Txk[T_Hilfe]<<braun<<"man "<<base_name(mpfad)<<schwarz<<Txk[T_or]<<braun<<"man -Lde "<<base_name(mpfad)<<schwarz<<"'"<<endl;
} // void hcl::virtzeigversion

// wird aufgerufen in lauf void hcl::virtvorrueckfragen() { } // void hcl::virtvorrueckfragen

// wird aufgerufen in lauf
void hcl::virtrueckfragen()
{
	if (rzf) {
		const char *const locale = setlocale(LC_CTYPE,"");
		if (langu.empty()) if (locale) if (strchr("defi",locale[0])) langu=locale[0];
		vector<string> sprachen={"e","d"/*,"f","i"*/};
		langu=Tippstrs(sprachstr.c_str()/*"Language/Sprache/Lingue/Lingua"*/,&sprachen,&langu);
		virtlgnzuw();
		cronminut=Tippzahl(Txk[T_Alle_wieviel_Minuten_soll]+meinname+Txk[T_aufgerufen_werden_0_ist_gar_nicht],&cronminut);
		autoupd=Tippob(Txk[T_Sollen_neue_Programmversionen_von]+meinname+Txk[T_automatisch_installiert_werden],autoupd?Txk[T_j_af]:"n");
		logvz=Tippverz(Txk[T_Logverzeichnis],&logvz);
		logdname=Tippstr(Txk[T_Logdateiname],&logdname);
		setzlog();
		oblog=Tippzahl(Txk[T_Oblog_ausf_Protok],oblog);
		findv=3;
	} // 	if (rzf)
} // 		void hcl::virtrueckfragen

// wird aufgerufen in lauf
void hcl::pruefggfmehrfach()
{
	if (!obhilfe &&!obvi &&!obvs &&!zeigvers &&!rzf) {
		pruefmehrfach(meinname,obverb,nrzf);
	}
} // void hhcl::pruefggfmehrfach

// wird aufgerufen in lauf
void hcl::virtpruefweiteres()
{
}

// wird aufgerufen in lauf
uchar hcl::pruefcron(const string& cm)
{
	uchar obschreib{0};
	// damit nicht nur deshalb das root-Passwort abgefragt werden muss => cronminuten nur ueberpruefen/aendern, wenn etweder ohnehin root oder ueber Befehlszeile neue Minutenzahl gewuenscht
////	<<"opn.olmap[Txk[T_cronminuten_l]]->woher: "<<(int)opn.olmap[Txk[T_cronminuten_l]]->woher<<", cus.cuid: "<<cus.cuid<<endl;
	if (opn.olmap[Txk[T_cronminuten_l]]->woher==3 ||!cus.cuid) {
		const string& cmhier{cm.empty()?cronminut:cm};
		crongeprueft=1;
		//  svec rueck;
		int cronda{0};
		//  svec rueck;
		cronzuplanen=(cmhier!="0");
		hLog(violetts+Txk[T_pruefcron]+schwarz+Txk[T_cronzuplanen]+violetts+(cronzuplanen?"1":"0")+schwarz);
		for (uchar runde{0};runde<2;runde++) {
			cronda=obprogda("crontab",obverb>0?obverb-1:0,0);
			if (cronda) break;
			//// systemrueck("which zypper 2>/dev/null && zypper -n in cron || 
			////              KLA which apt-get 2>/dev/null && apt-get -y install cron; KLZ",1,1);
			linstp->doinst("cron",1,1);
			////  int obionice=!systemrueck("which ionice > /dev/null 2>&1",0,0);
		} //   for (uchar runde=0;runde<2;runde++) 
		if (cronda) {
			////		string vorcm; // Vor-Cron-Minuten
			nochkeincron = systemrueck("crontab -l",obverb>0?obverb-1:0,0,0,/*obsudc=*/1,2);
			setztmpcron();
			const string vaufr{mpfad+" -noia"}, // /usr/bin/<DPROG> -noia // (vollaufruf) z.B. '/usr/bin/<DPROG> -noia >/dev/null 2>&1'
						zsaufr{base_name(vaufr)}, // ersetzAllezu(cbef,"/","\\/"); // Suchstring zum Loeschen
						vorsaetze{" "+linstp->ionicepf+" -c2 -n7 "+linstp->nicepf+" -n19 "},
						cabfr{vorsaetze+".*"+zsaufr},// <DPROG> -noia // Suchstring in Crontab // Befehl zum Abfragen der Cronminuten aus aktuellem Cron-Script
						cbef{string("*/")+cmhier+" * * * *"+vorsaetze+vaufr+" -cf "+akonfdt+" >/dev/null 2>&1"}, // "-"-Zeichen nur als cron
						czt{" \\* \\* \\* \\*"};
			////		string vorcm; // Vor-Cron-Minuten
			if (!nochkeincron) {
				cmd="bash -c 'grep \"\\*/.*"+czt+cabfr+"\" <(crontab -l 2>/dev/null)| sed \"s_\\*/\\([^ ]*\\) .*_\\1_\"'"; // fuer debian usw.: dash geht hier nicht
				svec cmrueck;
				systemrueck(cmd,obverb,oblog,&cmrueck,/*obsudc=*/1);
				if (cmrueck.size()) vorcm=cmrueck[0];
			} // 		if (!nochkeincron) 
			if (vorcm.empty() && !cronzuplanen) {
				if (obverb||cmeingegeben) 
					fLog(Txk[T_Kein_cron_gesetzt_nicht_zu_setzen],1,oblog);
			} else {
				if (cmhier==vorcm) {
					if (cmeingegeben) fLog(blaus+"'"+zsaufr+"'"+schwarz+Txk[T_wird]+Txk[T_unveraendert]+
							+blau+(vorcm.empty()?Txk[T_gar_nicht]:Txk[T_alle]+vorcm+Txk[T_Minuten])+schwarz+Txk[T_aufgerufen],1,oblog);
				} else {
					obschreib=1;
					tucronschreib(zsaufr,cronzuplanen,cbef);
					if (cmeingegeben)
						fLog(blaus+"'"+zsaufr+"'"+schwarz+Txk[T_wird]+blau+(cronzuplanen?Txk[T_alle]+cmhier+Txk[T_Minuten]:Txk[T_gar_nicht])+schwarz+
								Txk[T_statt]+blau+(vorcm.empty()?Txk[T_gar_nicht]:Txk[T_alle]+vorcm+Txk[T_Minuten])+schwarz+Txk[T_aufgerufen],1,oblog);
				} // 				if (cmhier==vorcm) else
			} // 		if (vorcm.empty() && cmhier=="0")
#ifdef anders
#define uebersichtlich
#ifdef uebersichtlich
			string befehl;
			if (!cronzuplanen) {
				if (nochkeincron) {
				} else {
					befehl="bash -c 'grep \""+saufr[0]+"\" -q <(crontab -l)&&{ crontab -l|sed \"/"+zsaufr[0]+"/d\">"+tmpcron+";"
						"crontab "+tmpcron+";}||:'";
				}
			} else {
				if (nochkeincron) {
					befehl="rm -f "+tmpcron+";";
				} else {
					befehl="bash -c 'grep \"\\*/"+cmhier+czt+cabfr+"\" -q <(crontab -l)||{ crontab -l|sed \"/"+zsaufr[0]+"/d\">"+tmpcron+";";
				}
				befehl+="echo \""+cbef+"\">>"+tmpcron+"; crontab "+tmpcron+"";
				if (!nochkeincron)
					befehl+=";}'";
			} // 			if (!cronzuplanen)
#else // uebersichtlich
			const string befehl{cronzuplanen?
				(nochkeincron?"rm -f "+tmpcron+";":
				 "bash -c 'grep \"\\*/"+cmhier+czt+cabfr+"\" -q <(crontab -l)||{ crontab -l | sed \"/"+zsaufr[0]+"/d\">"+tmpcron+"; ")+
					"echo \""+cbef+"\">>"+tmpcron+"; crontab "+tmpcron+(nochkeincron?"":";}'")
					:
					(nochkeincron?"":"bash -c 'grep \""+saufr[0]+"\" -q <(crontab -l)&&{ crontab -l | sed \"/"+zsaufr[0]+"/d\">"+tmpcron+";"
					 +"crontab "+tmpcron+";}||:'")
			};
#endif   // uebersichtlich else
			systemrueck(befehl,obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
#endif // anders
		} //   if (cronda) 
	}
	return obschreib;
	//  systemrueck(string("mv -i '")+mpfad+"' /root/bin",1,0);
} // hcl::pruefcron

// wird aufgerufen in lauf
void hcl::virtzeigueberschrift()
{
////	char buf[20]; snprintf(buf,sizeof buf,"%.5f",versnr);
/*//	fLog(schwarzs+Txk[T_Programm]+blau+mpfad+schwarz+", V: "+blau+buf+schwarz
			+(crongeprueft?
				Txk[T_Aufrufintervall]+blaus
				+(vorcm!=cronminut&&!(vorcm.empty()&&cronminut=="0")?((vorcm.empty()?Txk[T_gar_nicht]:vorcm)+" -> "):"")
				+(cronminut=="0"?Txk[T_kein_Aufruf]+schwarzs:cronminut+schwarz+(cronminut=="1"?Txk[T_Minute]:Txk[T_Minuten])):
				"")
			,1,oblog);
 */
	if (mitcron) uebers<<(crongeprueft?
				Txk[T_Aufrufintervall]+blaus
				+(vorcm!=cronminut&&!(vorcm.empty()&&cronminut=="0")?((vorcm.empty()?Txk[T_gar_nicht]:vorcm)+" -> "):string())
				+(cronminut=="0"?Txk[T_kein_Aufruf]+schwarzs:cronminut+schwarz+(cronminut=="1"?Txk[T_Minute]:Txk[T_Minuten])):
				string());
	fLog(uebers.str(),1,oblog);
} // void hcl::virtzeigueberschrift


// wird aufgerufen in lauf
void hcl::virtautokonfschreib()
{
	hLog(violetts+Txk[T_autokonfschreib]+schwarz+", "+Txk[T_rueckzufragen]+blau+(rzf?Txk[T_ja]:Txk[T_nein])+schwarz+", "+Txk[T_zu_schreiben]+blau+(hccd.obzuschreib?Txk[T_ja]:Txk[T_nein])+schwarz);
	if (rzf||hccd.obzuschreib) {
		hLog(gruens+Txk[T_schreibe_Konfiguration]+schwarz);
		opn.confschreib(akonfdt,ios::out,mpfad,0,obverb,oblog);
	} // if (rzf||obzuschreib)
	return;
	/*
	schAcl<WPcl> *ggcnfAp[1]={&agcnfA};
	multischlschreib(akonfdt, ggcnfAp, elemzahl(ggcnfAp), mpfad);
	chmod(akonfdt.c_str(),S_IRWXU);
	*/
} // void hhcl::virtautokonfschreib

// wird aufgerufen in lauf
void hcl::gitpull(const string& DPROG)
{
	if (autoupd && tagesaufr == 2) {
////		perfcl perf("main");
		if (systemrueck("wget https://raw.githubusercontent.com/"+gitv+"/"+DPROG+"/master/versdt -qO"+instvz+"/versdtakt&&"
					/*//				"[ $(echo $(cat "+instvz+"/versdtakt)'>'$(cat "+instvz+"/versdt)|bc -l) -eq 0 ]",2,oblog))*/
			// Berechnung mit |bc -l schlecht, da z.B. auf Ubuntu bc nicht unbedingt standardmaessig installiert
			"awk \"BEGIN{print $(cat "+instvz+"/versdt)-$(cat "+instvz+"/versdtakt)}\"|grep -q ^-",obverb,oblog,/*rueck=*/0,/*obsudc=*/0)) {

				fLog(violetts+DPROG+blau+Txk[T_muss_nicht_aktualisiert_werden]+schwarz,1,oblog);
			} else {
				////  struct stat entwst={0};
				//// entwickeln muss genauso definiert sein wie in Makefile
				////  const string ziel=instvz+(lstat((instvz+"/entwickeln").c_str(),&entwst)?string():"/nvers");
				const string ziel{instvz};
				pruefverz(ziel,obverb,oblog);
				fLog(violett+DPROG+blau+Txk[T_wird_aktualisiert_bitte_ggf_neu_starten]+schwarz,1,oblog);
				systemrueck("M="+DPROG+"-master;wget "+defvors+DPROG+defnachs+" -O"+ziel+"/"+DPROG+".tar.gz >/dev/null 2>&1;"
						"cd "+ziel+";rm -rf $M;tar xpvf "+DPROG+".tar.gz;cd $M;mv * ..;mv .* .. 2>/dev/null;cd ..;rmdir $M;./install.sh 2>/dev/null;",
						1,oblog,/*rueck=*/0,/*obsudc=*/0);
			} // if (systemrueck ... else
	} else if (!(tagesaufr % 5)) { // 	if (pm.autoupd && pm.tagesaufr == 2)
		svec srueck;
		systemrueck(mpfad+" -libtest 2>&1",obverb,oblog,&srueck);
		if (srueck.size()) {
			// wenn durch Systemupdate z.B. neue libtiff-Version eingespielt, dann wg.d.Fehlermeldung das aktuelle Programm nochmal dafuer kompilieren
			if (srueck[0].find("no version information")!=string::npos) {
				// falls mehrere libtiff installiert sind, die eigene bevorzugen
					 if (srueck[0].find("libtiff")!=string::npos) {
						 reduzierlibtiff();
					 } // 					 if (srueck[0].find("libtiff")!=string::npos)
				systemrueck("cd '"+instvz+"';make neu;"+sudc+" make install;",obverb,oblog);
			}
		} // 		if (srueck.size())
	} // 	else if (tagesaufr % 5)  // 	if (pm.autoupd && pm.tagesaufr == 2)
	//// <<"Tagesaufr: "<<tagesaufr<<endl;
} // void hcl::gitpull

// wird aufgerufen in lauf
int wartaufpids(pidvec *pidv,const ulong runden/*=0*/,const int obverb/*=0*/,const int oblog/*=0*/,const string& wo/*=string()*/)
{
	////	int* ovp=(int*)&obverb; *ovp=0;
	ulong aktru=0; 
	yLog(obverb>1,oblog>1,0,0,"%s%s()%s, %s, %s%s pid: %s%lu%s, pidv->size(): %s%zu%s",
			violett,__FUNCTION__,blau,wo.c_str(),schwarz,Txk[T_eigene],blau,getpid(),schwarz,blau,pidv->size(),schwarz);
	for(size_t i=0;i<pidv->size();i++) {
		yLog(obverb>1,oblog>1,0,0," i: %s%zu%s, pid: %s%lu%s, name: %s%s%s",
				blau,i,schwarz,blau,pidv->at(i).pid,schwarz,blau,pidv->at(i).name.c_str(),schwarz);
	} // 	for(size_t i=0;i<pidv->size();i++)
	while (1) {
		yLog(obverb>1,0,0,0," %s%s%s, while (1), pidv->size(): %s%zu%s",blau,wo.c_str(),schwarz,blau,pidv->size(),schwarz);
		for(size_t i=pidv->size();i;) {
			i--;
			const int res{kill(pidv->at(i).pid,0)};
			uchar zuloeschen{0};
			if (res==-1 && errno==ESRCH) zuloeschen=1;
			else {
				int status; 
				pid_t erg=waitpid(pidv->at(i).pid,&status,WNOHANG); 
				if (erg>0) zuloeschen=1;
			} // 			if (res==-1 && errno==ESRCH)
			yLog(obverb>1,0,0,0," %s%s%s, i: %s%zu%s, pidv->at(i).pid: %s%lu%s, name: %s%s%s, %s%s%s",blau,wo.c_str(),schwarz,blau,i,schwarz,blau,
					pidv->at(i).pid,schwarz,blau,pidv->at(i).name.c_str(),schwarz,(zuloeschen?blau:""),(zuloeschen?Txk[T_entfernen]:Txk[T_belassen]),schwarz);
			if (zuloeschen) {
				//      if (getpgid(pidv->at(i).pid)<0)
				pidv->erase(pidv->begin()+i);
			}
		} // 		for(size_t i=0;i<pidv->size();i++)
		if (!pidv->size()) {
			fLog(violetts+__FUNCTION__+", "+blau+wo+", return 0 (1)",obverb>1,0);
			return 0;
		} // 		if (!pidv->size())
		const int wz3{50};
		this_thread::sleep_for(chrono::milliseconds(wz3));
		yLog(obverb>1,0,0,0,"in %s(): %s%s: %s%d%s ms",__FUNCTION__,rot,Txk[T_warte],blau,wz3,schwarz);
		if (++aktru==runden) {
			fLog(violetts+__FUNCTION__+", "+blau+wo+", return 1",obverb>1,0);
			return 1;
		} // 		if (++aktru==runden)
	} // 	while (1)
	fLog(violetts+__FUNCTION__+", "+blau+wo+", return 0 (2)",obverb>1,0);
	return 0;
} // void wartaufpids

// wird aufgerufen in lauf
void hcl::setzzaehler()
{
	aufrufe++;
	//// <<"aufrufe: "<<aufrufe<<endl;
	// zcnfA[0].setze(&aufrufe);
	time_t jetzt=time(0);
	pthread_mutex_lock(&timemutex);
	struct tm heute=*localtime(&jetzt);
	if (heute.tm_year!=laufrtag.tm_year || heute.tm_yday!=laufrtag.tm_yday) {
		tagesaufr=0;
	}
	if (heute.tm_year!=laufrtag.tm_year || heute.tm_mon!=laufrtag.tm_mon) {
		monatsaufr=0;
	}
	// zcnfA[1].setze(&heute);
	pthread_mutex_unlock(&timemutex);
  memcpy(&laufrtag,&heute,sizeof laufrtag);
	tagesaufr++;
	// zcnfA[2].setze(&tagesaufr);
	monatsaufr++;
	// zcnfA[3].setze(&monatsaufr);
} // void hcl::setzzaehler

// wird aufgerufen in lauf
void hcl::schreibzaehler()
{
	zcnfA.confschreib(azaehlerdt,ios::out,mpfad,/*faclbak=*/0);
} // void hcl::schreibzaehler

// wird aufgerufen in lauf
void hcl::virtschlussanzeige()
{
	hLog(violetts+Txk[T_virtschlussanzeige]+schwarz);
	tende = clock();
	////  ausg.str(std::string()); ausg.clear();
	////  ausg<<schwarz<<"Pfad: "<<tuerkis<<zufaxenvz<<schwarz<<"; Dateien: "<<tuerkis<<geszahl<<schwarz<<"; Zeit: "<<drot<<setprecision(7)<<fixed<<((tende-tstart)/CLOCKS_PER_SEC)<<schwarz<<setprecision(0)<<" s";
	if (obverb>0) {
		stringstream ausg;
		ausg<<Txk[T_Zeit_Doppelpunkt]<<drot<<setprecision(7)<<fixed<<((tende-tstart)/CLOCKS_PER_SEC)<<schwarz<<setprecision(0)<<" s";
		fLog(ausg.str(),1,oblog); 
	} //   if (obverb>0)
	hLog(Txk[T_Fertig_mit]+blaus+meinname+schwarz+" !");
}// augerufen in: dovi und in abgeleiteten Programmen z.B. dovc, dovh

// wird aufgerufen in prueftif
int hcl::holvomnetz(const string& datei,const string& vors/*=defvors*/,const string& nachs/*=defnachs*/)
{
	int erg{1};
	if (!pruefinstv()) {
		erg=0;
		svec qrueck;
		if (findv==1) {
			systemrueck("find \""+instvz+"\" -mtime -1 -name "+datei+".tar.gz",obverb,oblog,&qrueck,/*obsudc=*/0);
		} else {
			time_t ab=0;
			ab=time(0)-(24*60*60);
			findfile(&qrueck,findv,obverb,oblog,0,instvz,/*muster=*/datei+"\\.tar\\.gz$",1,1,Fol_Dat,ab,0);
		}
		if (!qrueck.size()) {
			////systemrueck("sh -c 'cd "+instvz+"; wget https://github.com/larsimmisch/capisuite/archive/master.tar.gz -O capisuite.tar.gz'",
			erg=systemrueck("cd \""+instvz+"\";T="+datei+".tar.gz; wget "+vors+datei+nachs+" -O $T", obverb,oblog,/*rueck=*/0,/*obsudc=*/0);
		} //     if (!qrueck.size())
	} // if (!pruefinstv())
	return erg;
} // int hcl::holvomnetz(const string& datei,const string& vors/*=defvors*/,const string& nachs/*=defnachs*/)

// wird aufgerufen in hcl::kompiliere
int hcl::kompilbase(const string& was, const string& endg)
{
	if (!pruefinstv()) {
		int kerg{0};
		if (systemrueck("P="+was+";T=$P.tar."+endg+";cd \""+instvz+"\"&&tar xpvf $T&& rm -rf $P 2>/dev/null", obverb,oblog,/*rueck=*/0,/*obsudc=*/0))
			kerg=systemrueck("P="+was+";cd \""+instvz+"\"&&rm -rf $P",obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
		if (!kerg) kerg=systemrueck("P="+was+";M=$P-master;cd \""+instvz+"\"&&mv $M $P",obverb,oblog,/*rueck=*/0,/*obsudc=*/0);
		return kerg;
	} //   if (!pruefinstv())
	return 1;
} // int hcl::kompilbase(const string& was,const string& endg)

int hcl::kompilfort(const string& was,const string& vorcfg/*=string()*/, const string& cfgbismake/*==s_dampand*/,uchar ohneconf/*=0*/)
{
	int ret{1};
	if (!pruefinstv()) {
		const string ivw{instvz+vtz+was};
		/*//
			const string bef="sh -c 'cd \""+ivw+"\"&&"+
			(vorcfg.empty()?s_true:vorcfg)+(ohneconf?"":"&& ./configure ")+cfgbismake+" make"
			"&& echo $? = "+Txk[T_Ergebnis_nach_make]+" &&"+sudc+"make install "
		// bei capi20_copy ging das mit distclean am 10.7.17 auf fedora 24
		"||{ make distclean; ./configure; make &&"+sudc+"make install;}"
		"&& echo $? = "+Txk[T_Ergebnis_nach_make_install]+
		////				"&&{ grep -q \"P="+was+"\" \""+unindt+"\""
		////						"||printf \"H="+gethome()+";A=\\$H/"+meinname+";P="+was+";cd \\\"\\$A/\\$P\\\" 2>/dev/null"
		////						"||cd \\$(find \\\"\\$H\\\" -name \\$P -printf \\\"%%T@ %%p\\\\\\\\n\\\" 2>/dev/null|sort -rn|head -n1|cut -d\\\" \\\" -f2) "
		////						"&&"+sudc+"make uninstall; cd \\\"\\$H\\\"\\n\" >> \""+unindt+"\";KLZ "
		";"+sudc+"ldconfig "+lsys.getlib64()+";'";
		 */
		const string b1{"cd \""+ivw+"\"&&"+(vorcfg.empty()?s_true:vorcfg)+(ohneconf?"":"&& [ -f configure ]&&./configure ")+cfgbismake+" make"};
		const string b2{"cd \""+ivw+"\"&& make install"};
		const string b3{"cd \""+ivw+"\"&&{ M=Makefile;[ -f $M ]&&{ grep -q 'distclean:' $M&&make distclean||{ grep -q 'clean:' $M&&make clean;};};};"
			"[ -f configure ]&&./configure; make"};
		////		const string b4="ldconfig "+lsys.getlib64();
		const string b4{"ldconfig /usr"};
		int erg1;
		// bei linux-source muss unter Ubuntu 4.15.0-22-generic evtl. libelf-dev installiert werden, ferner /usr/src/linux-headers-4.15.0-22/arch/x86/include/asm/uaccess.h um die beiden Zeilen:
		// #include <linux/thread_info.h> und
		// #include <linux/sched.h> ergaenzt werden
		if (!(erg1=systemrueck(b1,obverb,oblog,/*rueck=*/0,/*obsudc=*/0))) {
			////if (!(erg1=systemrueck(b1,obverb,oblog,/*rueck=*/0,/*obsudc=*/0,/*verbergen=*/0,/*obergebnisanzeig=*/wahr,/*ueberschr=*/string(),
			////				/*errm=*/0,/*obincron=*/0,/*ausgp=*/0,/*obdirekt=*/0))) KLZ
			ret=systemrueck(b2,obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
		} else {
			if (!systemrueck(b3,obverb,oblog,/*rueck=*/0,/*obsudc=*/0)) {
				ret=systemrueck(b2,obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
			}
		} // 		if (!(erg1=systemrueck(b1,obverb,oblog,/*rueck=*/0,/*obsudc=*/0))) else 
		systemrueck(b4,obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
		hLog(string(Txk[T_Ergebnis_nach_make])+" "+ltoan(erg1));
		hLog(string(Txk[T_Ergebnis_nach_make_install])+" "+ltoan(ret));
		////		ret=systemrueck(bef,obverb,oblog);
		anfgg(unindt,"H="+gethome()+";A=$H/"+meinname+";P="+was+";cd \"$A/$P\" 2>/dev/null"
				"|| cd $(find \"$H\" -name $P -printf \"%T@ %p\\n\" 2>/dev/null|sort -rn|head -n1|cut -d\" \" -f2)"
				"&&"+sudc+"make uninstall; cd \"$H\"",b1+" && "+b2+" || "+b3,obverb,oblog);
	} // 		if (!pruefinstv())
	return ret;
} // int hcl::kompilfort(const string& was,const string& vorcfg/*=string()*/, const string& cfgbismake/*==s_dampand*/,uchar ohneconf/*=0*/)

const string tiffmark{"/usr/local/sclibtiff"};

// aufgerufen bei autofax in: pruefhyla, empfcapi, virtrueckfragen
void hcl::prueftif(string aktvers)
{
	hLog(violetts+Txk[T_prueftif]+schwarz+" "+aktvers);
	//	const string vstr="4.0.8"; //// "4.08001";
const int altobverb{obverb};
	size_t p1;
	if ((p1=aktvers.find('\n'))!=string::npos) aktvers.erase(p1);
	if ((p1=aktvers.rfind(' '))!=string::npos) aktvers.erase(0,p1+1);
	const double tv=verszuzahl(aktvers);
	//// <<gruen<<tv<<schwarz<<endl;
	// 4.07 = fehlerhafte Version
	if (tv==4.07) {
		obsotiff=1; // ob source-tiff
	}
	const uchar incfehlt{!systemrueck("find /usr/include /usr/local/include -name tiff.h -print -quit 2>/dev/null",obverb,oblog,0,1)};
	if (obsotiff) {
		// Die Datei /usr/local/sclibtiff wird als Nachweis verwendet, dass die Installationskorrektur durchgefuert wurde
		struct stat lnw={0};
		if ((/*(tv==4.07||tv==4.08)&&*/lstat(tiffmark.c_str(),&lnw))||incfehlt) {
			obverb=1;
			////		linstp->doggfinst("cmake",obverb,oblog); 
			const string proj{"tiff_copy"};
			holvomnetz(proj);
			if (!kompiliere(proj,s_gz,"sed -i.bak s'/(thandle_t) client_data.fd);/(thandle_t) \\&client_data.fd);/' tools/fax2tiff.c "
						////                  			 "&& sed -i.bak s'/Version 4.0.8\\\\n/Version "+vstr+"\\\\n/' libtiff/tiffvers.h"
						)) {
				if (!touch(tiffmark,obverb,oblog)) {
					anfgg(unindt,sudc+"rm -f \""+tiffmark+"\"","",obverb,oblog);
				}
			} // if (!kompiliere(
			obverb=altobverb;
		} // 	if (dcmv<3.62)
	} else {
		if (incfehlt|| !systemrueck("find /usr/lib64 /usr/lib -maxdepth 2 -type l -xtype f -name libtiff.so -print -quit 2>/dev/null",obverb,oblog)) {
			linstp->doggfinst("libtiff5",obverb,oblog);
			linstp->doggfinst("libtiff-devel",obverb,oblog);
		}
	} // 	if (obsotiff)
	reduzierlibtiff();
} // void paramcl::prueftif

/*//
	void hcl::prueftif()
	{
	hLog(violetts+Txk[T_prueftif]+schwarz);
	linstp->doggfinst("cmake",obverb,oblog); 
	const string proj="tiff_copy";
	holvomnetz(proj);
	kompilbase(proj,s_gz);
	string ivp=instvz+vtz+proj;
	const string bef="cd \""+ivp+"\""
	"&& rm -f CMakeCache.txt"
	"&& sed -i.bak s\"/uint16 Param;/uint32 Param;/\" libtiff/tif_fax3.h"
	"&& cmake -DCMAKE_INSTALL_PREFIX=/usr -DLIBTIFF_ALPHA_VERSION=1 . "
	"&& make";
	if (!(systemrueck(bef,obverb,oblog,0,0)))
	systemrueck("cd \""+ivp+"\" && make install",obverb,oblog,0,1);
	anfgg(unindt,"cd \""+ivp+"\" && cat install_manifest.txt|"+sudc+linstp->xargspf+" rm; cd \""+instvz+"\"",bef,obverb,oblog);
	} // void paramcl::prueftif()
 */

int hcl::kompiliere(const string& was,const string& endg, const string& vorcfg/*=string()*/, const string& cfgbismake/*==s_dampand*/)
{
	if (!kompilbase(was,endg)) {
		return kompilfort(was,vorcfg,cfgbismake);
	} //    if (!kompilbase(was,endg))
	return 1;
} // int hcl::kompiliere(const string was,const string endg,const string nachtar, const string vorcfg,const string cfgbismake)

// aufgerufen in: main
void hcl::zeigkonf()
{
	struct stat kstat={0};
	cout<<Txk[T_aktuelle_Einstellungen_aus]<<blau<<akonfdt<<schwarz<<"' (";
	//// char buf[100]={0};
	if (!lstat(akonfdt.c_str(),&kstat)) {
		//// struct tm tm={0};
		//// pthread_mutex_lock(&timemutex);
		//// memcpy(&tm, localtime(&kstat.st_mtime),sizeof(tm));
		cout<<ztacl(kstat.st_mtime,"%d.%m.%Y %H.%M.%S");
		//// pthread_mutex_unlock(&timemutex);
		//// strftime(buf, sizeof(buf), "%d.%m.%Y %H.%M.%S", &tm);
	} //   if (!lstat(akonfdt.c_str(),&kstat))
	cout<<")";
	if (obverb) {
		cout<<":"<<endl;
		opn.oausgeb(dblau);
	} else {
		cout<<Txk[T_mit_w_werden_die_Einstellungen_noch_ausfuehrlicher_angezeigt]<<endl;
		opn.zeigschoen();
	}
} // void hcl::zeigkonf()
// augerufen in: anhalten(), zeigkonf()

wpgcl::wpgcl(const string& pname,const void* pptr,par_t part):pname(pname),pptr(pptr),part(part),eingetragen(0)
{
}

// weist einer Option eine Zahl zu
void optcl::setzwert()
{
 long zahl=gegenteil?!iwert:iwert;
 if (zahl==1) zahl=*(long*)pptr+1;
 switch (part) {
	 case puchar: *(uchar*)pptr=zahl; break;
	 case pint:   *(int*)  pptr=zahl; break;
	 default: /*case plong:*/ *(long*)pptr=zahl;
 }
} // void optcl::setzwert()

size_t thr_strftime(const struct tm* const timeptr,string *const ziel,const char* const format/*="%d.%m.%Y %H.%M.%S"*/)
{
	size_t erg{0};
	char buf[30];
	pthread_mutex_lock(&timemutex);
	erg=strftime(buf, sizeof(buf), "%d.%m.%Y %H.%M.%S", timeptr);
	*ziel=string(buf);
	pthread_mutex_unlock(&timemutex);
  return erg;
} // size_t thr_strftime(const char* format,const stuct tm* timeptr)


string wpgcl::virtholstr() const
{
	string rstr;
	if (pptr) {
		switch (part) {
			case plong:
				rstr=ltoan(*(long*)pptr);
				break;
			case pint:
				rstr=ltoan(*(int*)pptr);
				break;
			case pbin:
				rstr=ltoan(*(binaer*)pptr);
				break;
			case puchar:
				rstr=ltoan(*(uchar*)pptr);
				break;
			case pstri: case pdez: case pverz: case pfile:
				rstr=*(string*)pptr;
				break;
			case ppwd:
				rstr=XOR(*(string*)pptr,pwk);
				break;
			case pdat:
				thr_strftime((struct tm*)pptr,&rstr);
			// stringstream strstr;
			// strstr<<ztacl((struct tm*)pptr,"%F %T");
			// rstr= strstr.str();
		} // 	 switch (part)
	} //  if (pptr)
	return rstr;
} // string WPcl::virtholstr()


string WPcl::virtholstr() const
{
	if (pptr) {
		return wpgcl::virtholstr();
	} else {
		return wert;
	}
}

const string& wpgcl::virtmachbemerk(const Sprache lg,const binaer obfarbe/*=wahr*/)
{
	return bemerk;
}

const string& optcl::virtmachbemerk(const Sprache lg,const binaer obfarbe/*=wahr*/)
{
	const uchar obnum{(part==plong||part==pint||part==puchar)},
				geheim{(part==ppwd)};
	bemerk.clear();
	if (TxBp) {
		if (Txi!=-1) {
			if (TxBp->TCp[Txi][lg]) {
				TCtp *hilf = reinterpret_cast<TCtp*>(TxBp->TCp);
				bemerk= (const char*)hilf[Txi][lg];
				if (!rottxt.empty()) bemerk+=(obfarbe?blaus:string())+rottxt+(obfarbe?schwarz:string());
				if (Txi2!=-1) bemerk+=(const char*)hilf[Txi2][lg]; 
				////        if (zptr && !strstr(pname,"pwd")) bemerk+=" '"+(obfarbe?blaus:string())+*zptr+(obfarbe?schwarz:string())+"'"; // pname==0
				if (obno) bemerk+=(obfarbe?violetts:string())+Txk[T_oder_nicht]+(obfarbe?schwarz:string());
				if (!geheim && pptr/*&&bemerk.find("assw")==string::npos*/) 
					bemerk+=string(" (")+(obnum?"":"'")+(obfarbe?blaus:string())+(obnum?ltoan(part==plong?*(long*)pptr:part==pint?*(int*)pptr:*(uchar*)pptr):*(string*)pptr)+(obfarbe?schwarz:string())+(obnum?"":"'")+")";
			} // if (TxBp->TCp[Txi][lg])
		} // if (Txi!=-1)
	} // if (TxBp)
	return bemerk;
} // string& optcl::virtmachbemerk(const Sprache lg,const binaer obfarbe/*=wahr*/)

int optcl::setzstr(const char* const neuw,uchar *const obzuschreib/*=0*/,const uchar ausDatei/*=0*/)
{
	uchar tuschreib{0};
	// nicht mit Vorgaben (woher 2) Befehlszeilenoption (woher 3) ueberschreiben
	int wiefalsch{wpgcl::tusetzstr(neuw,/*obzuschreib*/&tuschreib,ausDatei,/*keineprio*/woher>2)};
	if (tuschreib) if (obzuschreib) if (!*obzuschreib) if (!nichtspeichern) {
		*obzuschreib=1;
	}
	return wiefalsch;
} // setzstr

int WPcl::setzstr(const char* const neuw,uchar *const obzuschreib/*=0*/,const uchar ausDatei/*=0*/)
{
	uchar tuschreib{0};
	return wpgcl::tusetzstr(neuw,/*obzuschreib*/&tuschreib,ausDatei);
}
int WPcl::setzstr(const string& neus,uchar *const obzuschreib/*=0*/,const uchar ausDatei/*=0*/)
{
	return setzstr(neus.c_str(),obzuschreib,ausDatei);
}


// weist einer Option einen c-String zu
//  aufgerufen in: pzuweis (Befehlszeile) und auswert (Datei)
int wpgcl::tusetzstr(const char* const neuw,uchar *const tuschreibp,const uchar ausDatei/*=0*/,const uchar keineprio/*=0*/)
{
	int wiefalsch{0};
	struct tm tmp{0},tmmax{0},neu{0};
	char *emax{0},*eakt;
	if (pptr) {
		struct stat entryarg{0};
		long neul;
		binaer neub;
		uchar neuu;
		string neuws;
		int neui;
		switch (part) {
			// und das ein "sonstiger Parameter" ist, ...
			case pstri: case pdez:
				//// <<"*(string*)pptr: "<<*(string*)pptr<<", neuw: "<<neuw<<endl;
				// ... dann zuweisen
				if (*(string*)pptr!=neuw) {
					//// <<blau<<"vor weise zu 1 "<<schwarz<<endl;
					// Befehlszeilenoptionen nicht durch Konfigurationsdateioptionen ueberschreiben lassen
					if (keineprio) {
						*tuschreibp=1; 
					} else {
						//// <<blau<<"vor weise zu 2 "<<schwarz<<endl;
						if (part==pdez && !isnumeric(neuw)) {
							wiefalsch=1;
						} else {
							//// <<blau<<"weise zu"<<schwarz<<endl;
							*(string*)pptr=neuw;
						}
					}
				}
				break;
			case ppwd:
				neuws=neuw;
				// ... dann zuweisen
				if (*(string*)pptr!=XOR(neuws,pwk)) {
					// Befehlszeilenoptionen nicht durch Konfigurationsdateioptionen ueberschreiben lassen
					if (keineprio) {
						*tuschreibp=1; 
					} else {
						if (ausDatei) {
							*(string*)pptr=XOR(neuws,pwk);
						} else {
							*(string*)pptr=neuw;
						}
					}
				}
				break;
				// wenn es ein Verzeichnis oder eine Datei sein soll ...
			case pverz: case pfile:
				// ... die also nicht mit '-' anfaengt
				// ... und sie bestimmte existentielle Bedingungen erfuellt ...
				if (stat(neuw,&entryarg)) wiefalsch=1;  // wenn inexistent
				else if ((part==pverz)^(S_ISDIR(entryarg.st_mode))) wiefalsch=2; // Datei fuer Verzeichnis o.u.
				// ... dann zuweisen
				else {
					if (*(string*)pptr!=neuw) {
						if (keineprio) {
							*tuschreibp=1; 
						} else {
							*(string*)pptr=neuw;
						}
					}
				}
				break;
			case pbin:
				neub=(binaer)atoi(neuw);
				if (*(binaer*)pptr!=neub) {
					if (keineprio) {
						*tuschreibp=1; 
					} else {
						*(binaer*)pptr=neub; 
					}
				}
				break;
				// oder wenn es eine Zahl sein soll ...
			case puchar: case pint: case plong:
				// und tatsaechlich numerisch ist ...
				if (!isnumeric(neuw)) wiefalsch=1;
				// dann zuweisen
				else {
					switch (part) {
						case puchar:
							neuu=atol(neuw);
							if (*(uchar*)pptr!=neuu) {
								if (keineprio) {
									*tuschreibp=1; 
								} else {
									*(uchar*)pptr=neuu; 
								}
							}
							break;
						case pint:
							neui=atol(neuw);
							if (*(int*)pptr!=neui) {
								if (keineprio) {
									*tuschreibp=1; 
								} else {
									*(int*)pptr=neui;
								}
							}
							break;
						default: /* case plong: */
							neul=atol(neuw);
							if (*(long*)pptr!=neul) {
								if (keineprio) {
									*tuschreibp=1; 
								} else {
									*(long*)pptr=neul;
								}
							}
							break;
					}
				}
				break;
			case pdat:
				//// <<"neuw: '"<<neuw<<"' ";
				for(unsigned im=0;im<elemzahl(tmmoegl);im++) {
					memcpy(&tmp,&neu,sizeof tmp);
					eakt=strptime(neuw, tmmoegl[im], &tmp);
					//// if (eakt>emax) <<blau<<endl;
					//// <<ztacl(&tmp)<<", im: "<<im<<", tmmoegl[im]: "<<tmmoegl[im]<<", eakt: "<<(void*)eakt<<", emax: "<<(void*)emax<<endl<<schwarz;
					if (eakt>emax) { memcpy(&tmmax,&tmp,sizeof tmp); emax=eakt; }
				}
				if (emax) {
					//// <<blau<<"Sieger: "<<ztacl(&tmmax)<<schwarz<<endl;
					if (!memcmp((struct tm*)pptr,&tmmax,sizeof tmmax)) {
						if (keineprio) {
							*tuschreibp=1; 
						} else {
							memcpy((struct tm*)pptr,&tmmax,sizeof tmmax);
						}
					}
				}
				break;
		} // switch (part) 
	} // 	if (pptr)
	return wiefalsch;
} // void optcl::setzstr

// Rueckgabe: -1: String-Parameter erfolgreich zugewiesen, 0: Zahl erfolgreich zugewiesen
// Parameter ueber Befehlszeile zuweisen
int optcl::pzuweis(const char *const nacstr, const uchar vgegenteil/*=0*/, const uchar vnichtspeichern/*=0*/)
{
	int wiefalsch{0};
	gegenteil=vgegenteil;
	nichtspeichern=vnichtspeichern;
  if (iwert!=-1) {
		setzwert();
	} else {
		//// <<rot<<"nacstr: "<<nacstr<<schwarz<<endl;
		// er also nicht mit '-' anfaengt ...
		if (*nacstr && *nacstr!='-') {
			wiefalsch=setzstr(nacstr);
		} else {
			wiefalsch=3; // kein geeigneter Parameter gefunden
		}
		if (wiefalsch) {
			// wenn kein Zusatzparameter erkennbar, dann melden
			switch (part) {
				case pdat:
					fLog(drots+Txk[T_Fehlender_Parameter_Datum_zu]+(kurzi<0?ltoan(kurzi):(*TxBp)[kurzi])+Txk[T_oder]+(langi<0?ltoan(langi):(*TxBp)[langi])+"!"+schwarz,1,1);
					break;
				case pstri:
				case pdez:
				case ppwd:
					fLog(drots+Txk[T_Fehlender_Parameter_string_zu]+(kurzi<0?ltoan(kurzi):(*TxBp)[kurzi])+Txk[T_oder]+(langi<0?ltoan(langi):(*TxBp)[langi])+"!"+schwarz,1,1);
					break;
				case pverz:
				case pfile:
					fLog(drots+Txk[T_Fehler_Parameter]+(kurzi<0?ltoan(kurzi):(*TxBp)[kurzi])+Txk[T_oder]+(langi<0?ltoan(langi):(*TxBp)[langi])+" "+
							(wiefalsch==1?Txk[T_ohne_gueltigen]:wiefalsch==2?Txk[T_mit_Datei_als]:Txk[T_mit_falschem])+Txk[T_Pfad_angegeben]+schwarz,1,1);
					break;
				case puchar: case pint: case plong: case pbin:
					fLog(drots+(wiefalsch==1?Txk[T_Nicht_numerischer]:Txk[T_Fehlender])+Txk[T_Parameter_nr_zu]
							+(kurzi<0?ltoan(kurzi):(*TxBp)[kurzi])+Txk[T_oder]+(langi<0?ltoan(langi):(*TxBp)[langi])+"!"+schwarz,1,1);
					break;
			} // switch (part)
		} // 										if (wiefalsch)
		if (!wiefalsch) {
			return -1;
		}
	} // 									if (wert) else
	return wiefalsch;
} // int optcl::pzuweis

optcl::optcl(const string& pname,const void* pptr,const par_t part, const int kurzi, const int langi, TxB* TxBp, const long Txi,
		const uchar wi, const long Txi2, const string rottxt, const int iwert,const uchar woher, const long Txrf,const uchar obno/*=0*/):wpgcl(pname,pptr,part),
	kurzi(kurzi),langi(langi),TxBp(TxBp),Txi(Txi),wi(wi),Txi2(Txi2),rottxt(rottxt),iwert(iwert),
	woher(woher),Txrf(Txrf),obno(obno)/*=0*///,eingetragen(0)
{
////	caus<<gruen<<"Erstelle optcl, pname: "<<schwarz<<violett<<pname<<endl;
}

optcl::optcl(const void* pptr,const par_t part, const int kurzi, const int langi, TxB* TxBp, const long Txi,
		const uchar wi, const long Txi2, const string rottxt, const int iwert,const uchar woher,const uchar obno/*=0*/):wpgcl({},pptr,part),
	kurzi(kurzi),langi(langi),TxBp(TxBp),Txi(Txi),wi(wi),Txi2(Txi2),rottxt(rottxt),iwert(iwert),
	woher(woher),obno(obno)/*=0*///,eingetragen(0)
{
////	caus<<gruen<<"Erstelle optcl, pname: "<<schwarz<<violett<<pname<<endl;
}

int hcl::hLog(const string& text,const bool oberr/*=0*/,const short klobverb/*=0*/) const
{
////	const bool oberr{0};
////	const short klobverb{0};
	return fLog(text,obverb,oblog,oberr,klobverb);
} // int hcl::hLog(const string& text,bool oberr/*=0*/,short klobverb/*=0*/)

const char* const hcl::smbdt{"/etc/samba/smb.conf"};
// wird aufgerufen in: main
void hcl::pruefsamba(const vector<const string*>& vzn,const svec& abschni,const svec& suchs, const char* DPROG,const string& cuser)
{
	hLog(violetts+Txk[T_pruefsamba]);
	int sgest{0}, ngest{0};
	uchar conffehlt{1};
	const string smbquelle{"/usr/share/samba/smb.conf"};
	uchar obinst{0}; // ob Samba installiert werden soll bzw. die smb.conf bearbeitet
	uchar obfw{0}; // ob SuSEfirewall bearbeitet werden soll
	//// <<violett<<"Stelle 0"<<endl;systemrueck("systemctl -n 0 status 'nmbd'",obverb,oblog,/*rueck=*/0,/*obsudc=*/0);
	linstp->doggfinst("libwbclient0",obverb,oblog);
	// bei dieser Initialisierung werden nur die Namen zugewiesen
	servc smb("smb","smbd");
	servc smbd("smbd","smbd");
	servc nmb("nmb","nmbd");
	servc nmbd("nmbd","nmbd");
	int dienstzahl{2};
	int obsfehlt{linstp->obfehlt("samba",obverb,oblog)};
	for(int iru=0;iru<2;iru++) {
		if (obsfehlt) {
			if (!nrzf) {
				obinst=Tippob(Txk[T_Samba_muesste_installiert_werden_soll_ich],Txk[T_j_af]);
				if (obinst) {
					linstp->doinst("samba",obverb,oblog);
				}
				////        smbrestart=0;
			} // if (!nrzf) 
		} // 	if (obsfehlt)
		for(uchar iru=0;iru<2;iru++) {
			struct stat sstat={0};
			if (!(conffehlt=lstat(smbdt,&sstat))) break;
			if (iru) break;
			pruefverz("/etc/samba",obverb,oblog,/*obmitfacl=*/1,/*obmitcon=*/0,/*besitzer=*/string(),/*benutzer=*/string(),/*obmachen=*/0);
			kopier(smbquelle,smbdt,obverb,oblog);
		} //   for(uchar iru=0;iru<2;iru++)
		if (smb.obsvfeh(obverb>0?obverb-1:0,oblog)) if (smbd.obsvfeh(obverb>0?obverb-1:0,oblog)) dienstzahl--;
		if (nmb.obsvfeh(obverb>0?obverb-1:0,oblog)) if (nmbd.obsvfeh(obverb>0?obverb-1:0,oblog)) dienstzahl--;
		if (dienstzahl==2 ||(smb.svfeh!=6 && smbd.svfeh!=6 && nmb.svfeh!=6 && nmbd.svfeh!=6)) { // wenn keine exec-Datei fehlt
			break;
		} else {
			obsfehlt=1;
		} // if (dienstzahl==2 || ...
		////  <<rot<<"Dienstzahl: "<<dienstzahl<<endl;
	} // 	for(int iru=0;iru<2;iru++)
	if (dienstzahl<2||conffehlt) {
		for(int aru=0;aru<2;aru++) {
			if (!smb.svfeh||!smbd.svfeh) {
				sgest=1;
			} else {
				if (smb.svfeh!=1) {
					sgest=smb.machfit(obverb,oblog);
				}
				if (!sgest && smbd.svfeh!=1) {
					sgest=smbd.machfit(obverb,oblog);
				} //       if (!smb.svfeh)
			} // 			if (!smb.svfeh||!smbd.svfeh)
			if (!nmb.svfeh||!nmbd.svfeh) {
				ngest=1;
			} else {
				if (nmb.svfeh!=1) {
					ngest=nmb.machfit(obverb,oblog);
				}
				if (!ngest && nmbd.svfeh!=1) {
					ngest=nmbd.machfit(obverb,oblog);
				} //       if (!nmb.nvfeh)
			} // 			if (!nmb.svfeh||!nmbd.svfeh)
			if (sgest&&ngest) break;
			//// if (!smb.svfeh) if (!smb.obsvfeh(obverb,oblog)) if (!nmb.svfeh) if (!nmb.obsvfeh(obverb,oblog)) break;
			//// if (!smbd.svfeh) if (!smbd.obsvfeh(obverb,oblog)) if (!nmbd.svfeh) if (!nmbd.obsvfeh(obverb,oblog)) break;
		} // for(int aru=0;aru<2;aru++) 
		////    if (gestartet==2) smbrestart=0;
	} // if (dienstzahl<2 || conffehlt) 
	struct stat sstat={0};
	if (!(conffehlt=lstat(smbdt,&sstat))) {
		confdcl smbcd(smbdt,obverb);
//		smbcd.Abschn_auswert(obverb);
		uchar gef[vzn.size()]; memset(gef,0,vzn.size()*sizeof(uchar));
		for(size_t i=0;i<smbcd.abschv.size();i++) {
			if (smbcd.abschv[i].aname!="global") {
				const string pfad{*smbcd.abschv[i].suche("path")};
				if (!pfad.empty()) {
					for(unsigned k=0;k<vzn.size();k++) {
						if (!gef[k]) if (!vzn[k]->empty()) {
							if (!vzn[k]->find(pfad)) {
								gef[k]=1;
							}
						} // if (!gef[k]) if (!vzn[k]->empty()) 
					} // for(unsigned k=0;k<elemzahl(vzn);k++) 
				} // if (!pfad.empty()) 
			} // if (smbcd.abschv.aname!="global") 
		} // for(size_t i=0;i<smbcd.abschv.size();i++) 
		uchar smbrestart{0};
		mdatei sapp(smbdt,ios::out|ios::app);
		if (sapp.is_open()) {
			string suchstr;
			for(unsigned k=0;k<vzn.size();k++) {
				if (!gef[k]) {
					smbrestart=1;
					if (!obinst) {
						obinst=Tippob(Txk[T_Sollen_fehlende_Sambafreigaben_fuer_die_angegebenen_Verzeichnisse_ergaenzt_werden],Txk[T_j_af]);
						if (!obinst) break;
					} // 					if (!obinst)
					fLog(gruens+Txk[T_Verzeichnis]+blau+*vzn[k]+gruen+Txk[T_nicht_als_Sambafreigabe_gefunden_wird_ergaenzt_in]+
							blau+smbdt+"'."+schwarz,1,oblog);
					suchstr+=suchs[k];
					sapp<<"["<<abschni[k]<<"]"<<endl;
					sapp<<"  comment = "<<meinname<<" "<<abschni[k]<<endl;
					sapp<<"  path = "<<*vzn[k]<<endl;
					sapp<<"  directory mask = 0660"<<endl;
					sapp<<"  browseable = Yes"<<endl;
					if (!k)
						sapp<<"  read only = no"<<endl; // zufaxenvz soll beschreibbar sein
					sapp<<"  vfs objects = recycle"<<endl;
					sapp<<"  recycle:versions = Yes"<<endl;
					sapp<<"  recycle:keeptree = Yes"<<endl;
					sapp<<"  recycle:repository = Papierkorb"<<endl;
				} // if (!gef[k]) 
			} // for(unsigned k=0;k<elemzahl(vzn);k++) 
			if (!suchstr.empty()) {
				if (suchstr.length()>1) suchstr.resize(suchstr.size()-2); // das letzte \\| abschneiden
				// Abschnitt wieder loeschen
				anfgg(unindt,sudc+"sed -i.vor"+DPROG+" '/^[ \\t]/{H;$!d;};x;/"+suchstr+"/d;1d' "+smbdt,"smb.conf: ["+suchstr+"]",obverb,oblog);
			} // 			if (!suchstr.empty())
		} // if (sapp.is_open()) 
		if (!nrzf) {
			const uchar suserda{!systemrueck("pdbedit -L | grep "+cuser+":",obverb,oblog,/*rueck=*/0,/*obsudc=*/1)};
			if (!suserda) {
				string pw1, pw2;
				while (1) {
					do {
						pw1=Tippstr(string(Txk[T_Passwort_fuer_samba])+Txk[T_fuer_Benutzer]+dblau+cuser+schwarz+"'"/*,&pw1*/);
					} while (pw1.empty());
					pw2=Tippstr(string(Txk[T_Passwort_fuer_samba])+Txk[T_fuer_Benutzer]+dblau+cuser+schwarz+"' ("+Txk[T_erneute_Eingabe]+")"/*,&pw2*/);
					if (pw1==pw2) break;
				} //         while (1)
				systemrueck("smbpasswd -n -a "+cuser,obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
				// smbpasswd in /usr/bin, somit wohl aus crontab aufrufbar
				systemrueck("(echo "+pw1+";echo "+pw2+")|"+sudc+"smbpasswd -s "+cuser,obverb,oblog,/*rueck=*/0,/*obsudc=*/0);
			} // if (!suserda)
		} // if (!nrzf)
		if (smbrestart) {
			////		<<"smb.svfeh: "<<(int)smb.svfeh<<endl;
			if (smb.startbar()) smb.restart(obverb>0?obverb-1:0,oblog);
			else if (smbd.startbar()) smbd.restart(obverb>0?obverb-1:0,oblog);
			if (nmb.startbar()) nmb.restart(obverb>0?obverb-1:0,oblog);
			else if (nmbd.startbar()) nmbd.restart(obverb>0?obverb-1:0,oblog);
		} // if (smbrestart) 
		// VFS
		if (linstp->ipr==apt) linstp->doggfinst("samba-vfs-modules",obverb,oblog);
		// Firewall(s)
		uchar obslaeuft{0};
		svec rueckr;
		systemrueck("systemctl list-units|grep firewall|grep -v init",obverb,oblog,&rueckr,/*obsudc=*/0);
		if (rueckr.size()) if (rueckr[0].find("active running")!=string::npos ||rueckr[0].find("active exited")!=string::npos) obslaeuft=1;
		if (obslaeuft) {
			// firewall-ports, geht in SUSE und Fedora
			uchar obzu{0};
			// udp, udp, tcp, tcp
			svec ports; ports<<"137"<<"138"<<"139"<<"445";
			for(size_t i=0;i<ports.size();i++) {
				svec rueck;
				systemrueck("iptables -L -n|grep "+ports[i],obverb,oblog,&rueck,/*obsudc=*/1);
				if (rueck.size()) {
					if (obverb>1) fLog(rueck[0],obverb>0?obverb-1:0,oblog);
					if (rueck[0].substr(0,6)=="ACCEPT" || rueck[0].substr(0,3)=="LOG") {
						if (obverb) hLog(Txk[T_Firewallport]+blaus+ports[i]+schwarz+Txk[T_offen]);
						continue;
					}
				} // 			if (rueck.size())
				if (obverb) hLog(Txk[T_Firewallport]+blaus+ports[i]+schwarz+Txk[T_zu]);
				obzu=1;
				break;
			} // 		for(size_t i=0;i<ports.size();i++) 
			if (obzu) {
				lsysen system=lsys.getsys(obverb,oblog);
				if (system==fed) {
					// fedora:
					// firewall-cmd --state
					const string bef{"firewall-cmd --permanent --add-service=samba&&"+sudc+"firewall-cmd --reload"};
					systemrueck(bef,obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
					anfgg(unindt,sudc+"firewall-cmd --permanent --remove-service=samba&&"+sudc+"firewall-cmd --reload",
							bef,obverb,oblog);
					// selinux: // offenbar unnoetig
				} else {
					// Suse-Firewall
					const string susefw{"/etc/sysconfig/SuSEfirewall2"};
					struct stat fstat{0};
					if (!lstat(susefw.c_str(),&fstat)) {
						string prart{"server"};
						for(int i=1;i<3;i++) {
							const int nichtfrei{
								systemrueck("grep '^FW_CONFIGURATIONS_EXT=\\\".*samba-"+prart+"' "+susefw,obverb,oblog,0,/*obsudc=*/0,/*verbergen=*/2)};
							if (nichtfrei && !nrzf && !obfw) {
								obfw=Tippob(Txk[T_Soll_die_SuSEfirewall_bearbeitet_werden],Txk[T_j_af]);
								if (!obfw) break;
							} // 					if (nichtfrei && !nrzf && !obfw)
							if (nichtfrei && obfw) {
								const string bak{"bak_"+meinname+ltoan(i)};
								struct stat lbak{0};
								const int fehlt{lstat((susefw+"."+bak).c_str(),&lbak)};
								const string bef{"sed -i"+(fehlt?"."+bak:"")+
									" 's/\\(FW_CONFIGURATIONS_EXT=\\\".*\\)\\(\\\".*$\\)/\\1 samba-"+prart+"\\2/g' "+susefw+
									"&&"+sudc+"systemctl restart SuSEfirewall2 smb nmb"};
								systemrueck(bef,obverb,oblog,/*rueck=*/0,/*obsudc=*/1); 
								anfgg(unindt,sudc+"sh -c 'cp -a \""+susefw+"."+bak+"\" \""+susefw+"\"'&&systemctl restart SuSEfirewall2 smb nmb",bef,obverb,oblog);
							} // 					if (nichtfrei && obfw)
							prart="client";
						} // for(int i=1;i<3;i++) 
					} // if (!lstat(susefw,&fstat)) 
				} // 			  if (system==fed) else 
			} // obzu
		} // obslaeuft
	} //   if (!(conffehlt=lstat(smbdt,&sstat)))
	hLog(violetts+Txk[T_Ende]+Txk[T_pruefsamba]);
} // pruefsamba

WPcl::WPcl(const string& pname,const void* pptr,par_t part):wpgcl(pname,pptr,part)
{
}

// aufgerufen in pruefcron, pruefmodcron und anhalten
void hcl::setztmpcron()
{
	if (tmpcron.empty()) {
		// Einbau von '~' ergaebe bei Aufruf mit und ohne sudo unterschiedliche Erweiterungen
		tmpcron=gethome()+"/rootscrontab";
	} //   if (tmpcron.empty())
} // void setztmpcron()

// wird aufgerufen in pruefcron (2x)
void hcl::tucronschreib(const string& zsauf,const uchar cronzuplanen,const string& cbef)
{
	string unicmd{"rm -f "+tmpcron+";"};
	string cmd{unicmd};
	string dazu{"crontab -l|sed '/"+zsauf+"/d'>"+tmpcron+";"};
	unicmd+=dazu;	
	if (!nochkeincron) {
		// cmd=dazu; // 26.2.17: Debian: nach Deinstallation rootscrontab mit root-Berechtigungen, die Programm hier aufhielten
		cmd=unicmd;
	}
	if (cronzuplanen) {
		cmd+=" echo \""+cbef+"\">>"+tmpcron+";";
	}
	dazu=" crontab "+tmpcron+";";
	unicmd+=dazu;
	cmd+=dazu;
	systemrueck(cmd,obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
	//// ersetzAlle(unicmd,"'\\''","'");
	const string bef{sudc+"sh -c '"+cmd+"'"};
	anfgg(unindt,unicmd,bef,obverb,oblog);
} // void hcl::tucronschreib(const string& zsauf,const uchar cronzuplanen,const string& cbef)

// wird aufgerufen in dodovi
void viadd(string* const cmdp,string* const zeigp, const string& datei,const uchar ro/*=0*/,const uchar hinten/*=0*/, const uchar unten/*=0*/)
{
	// if (!stat(sudoers.c_str(),&sstat)) KLA // if (sstat.st_mode & S_IRUSR) // lieferte falsch wahr
	ifstream is(datei);
	if (is.good()) {
		*zeigp+=" ";
		*zeigp+=datei;
		if (ro) {
			if (hinten) *cmdp+="tablast|";
			*cmdp=*cmdp+"tab sview "+datei+"|";
			if (unten) *cmdp+="silent $|";
		} else {
			*cmdp=*cmdp+datei+" "; 
		} //   if (ro) else
	} //  if (is.good())
} // void viadd(string *cmdp,string datei)

// wird aufgerufen in dodovi
void hcl::vischluss(string& erg,string& zeig)
{
	if (cmd==edit) {
		exit(schluss(0,rots+Txk[T_keine_Daten_zum_Anzeigen_Bearbeiten]+schwarz));
	} else {
		erg+="tabfirst' -p";
		string exdt{instvz+"/.exrc"};
		{ifstream is(exdt);if (is.good()) erg+="Nu "+exdt;}
		//// <<violett<<cmd+" +'"+erg+" "+devtty<<schwarz<<endl;
		if (!zeig.empty()) systemrueck("ls -l "+zeig,2);
		string befehl{cmd+" +'"+erg+" "+devtty};
		exit(schluss(systemrueck(befehl,obverb,0,/*rueck=*/0,/*obsudc=*/0),Txk[T_nach__]+blaus+befehl+schwarz));
	}
} // void vischluss

// aufgerufen in: dovi
void hcl::dodovi(const svec d1,const svec d2)
{
	string zeig;
	cmd=edit;
	viadd(&cmd,&zeig,akonfdt);
	for(unsigned i=0;i<d1.size();i++) {
		viadd(&cmd,&zeig,d1[i]);
	}
	string erg;
	viadd(&erg,&zeig,logdt,1,0,1);
	viadd(&erg,&zeig,azaehlerdt,1,0,0);
	for(unsigned i=0;i<d2.size();i++) {
		viadd(&erg,&zeig,d2[i],1,1,0);
	}
	vischluss(erg,zeig);
} // void hcl::dodovi

// in pruefhyla, pruefocr, prueftif und gitpull
void hcl::reduzierlibtiff()
{
	svec qrueck;
	const string lcrep{"/usr/lib64 /usr/lib "},
				lcsou{"/usr/local/lib64 /usr/local/lib "},
				tykr{"\\( -type f -o -type l \\) "},
				namkr{"-name 'libtiff*' "};
	if (systemrueck("find "+lcrep+" -maxdepth 2 "+tykr+namkr+"-print -quit",obverb,oblog,&qrueck,/*obsudc=*/0) &&
			systemrueck("find "+lcsou+" -maxdepth 2 "+tykr+namkr+"-print -quit",obverb,oblog,&qrueck, /*obsudc=*/0)) {
		if (obsotiff) {
			systemrueck("find "+lcrep+tykr+namkr+"-delete",obverb,oblog,&qrueck,/*obsudc=*/1);
		} else {
			systemrueck("find "+lcsou+tykr+namkr+"-delete",obverb,oblog,&qrueck, /*obsudc=*/1);
			tuloeschen(tiffmark,"",obverb,oblog);
		} // 		if (obsotiff) else
		systemrueck("ldconfig /usr",obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
	}
} // void hcl::reduzierlibtiff()

const string	hcl::passwddt{"/etc/passwd"},
			hcl::groupdt{"/etc/group"},
			hcl::sudoersdt{"/etc/sudoers"};

void hcl::setzbenutzer(string *const user)
{
	cmd="cat "+passwddt+" | grep /home/ | cut -d':' -f 1";
	systemrueck(cmd,obverb,oblog,&benutzer,/*obsudc=*/0);
	if (benutzer.size()>1) for(size_t i=benutzer.size();i;) {
		--i;
		if (benutzer[i]=="syslog"||benutzer[i]=="ntp") {
			benutzer.erase(benutzer.begin()+i);
		}
	} // for(size_t i=benutzer.size();i;)
	for(size_t i=0;i<benutzer.size();i++) {
		////          bliste+=benutzer[i];
		////          if (i<benutzer.size()-1) bliste+=",";
		if (user->empty()) *user=benutzer[i]; // Vorgabe
	} // 			for(size_t i=0;i<benutzer.size();i++) 
	/*//
		const string Frage=string("Linux-Benutzer fuer Capisuite (")+bliste+"):";
		do KLA
		tmpcuser=Tippstr(Frage.c_str(),user);
		KLZ while (benutzer.size() && bliste.find(tmpcuser)==string::npos && 
		tmpcuser.find(',')==string::npos); // nur vorhandene User akzeptieren
	 *user=tmpcuser;
	 */
}

/*
	for(size_t i=0;i<opn.size();i++) {
	} // 	for(size_t i=0;i<optz;i++)
	*/

void optcl::virtweisomapzu(void *schlp)
{
	// interne Berechnungen durchfuehren
	// Bemerkung erst beim Schreiben setzen
	// Indices (maps) belegen
	//// caus<<"weise omap zu, pname: "<<blau<<pname<<schwarz<<endl;
//	((schAcl<optcl>*)schlp)->gibomapaus();
	if (!pname.empty()) {
		((schAcl<optcl>*)schlp)->omap[pname]=this;
	}
////	schlp->gibomapaus();
	Sprache altlgn=TxBp->lgn;
	for(unsigned akts=0;akts<SprachZahl;akts++) {
		TxBp->lgn=(Sprache)akts;
		if (kurzi>-1) ((schAcl<optcl>*)schlp)->okmap[(*TxBp)[kurzi]]=this;
		if (langi>-1) ((schAcl<optcl>*)schlp)->olmap[(*TxBp)[langi]]=this;
	} // 		for(unsigned akts=0;akts<SprachZahl;akts++)
	TxBp->lgn=altlgn;
} // void optcl::virtweisomapzu

void optcl::virtloeschomaps(schAcl<optcl> *schlp)
{
	// Indices (maps) loeschen
	//// caus<<"loesche omap, pname: "<<blau<<pname<<schwarz<<endl;
//	((schAcl<optcl>*)schlp)->gibomapaus();
	if (!pname.empty()) {
		((schAcl<optcl>*)schlp)->omap.erase(pname);
	}
////	schlp->gibomapaus();
	Sprache altlgn=TxBp->lgn;
	for(unsigned akts=0;akts<SprachZahl;akts++) {
		TxBp->lgn=(Sprache)akts;
		if (kurzi>-1) ((schAcl<optcl>*)schlp)->okmap.erase((*TxBp)[kurzi]);
		if (langi>-1) ((schAcl<optcl>*)schlp)->olmap.erase((*TxBp)[langi]);
	} // 		for(unsigned akts=0;akts<SprachZahl;akts++)
	TxBp->lgn=altlgn;
} // void optcl::virtloeschomaps

void wpgcl::virtweisomapzu(void *optp)
{
}

/*
// sollte unnoetig werden
template<typename SCL> void schAcl<SCL>::omapzuw()
{
	for(size_t i=0;i<size();i++) {
		schl[i]->virtweisomapzu(this);
	}
} // void hcl::omapzuw(optcl *optp,size_t optz)
*/

confdcl::confdcl():obgelesen(0),obzuschreib(0)
{
}

confdcl::confdcl(const string& fname, int obverb, const char tz/*='='*/):obgelesen(0),obzuschreib(0)
{
 if (!fname.empty())
	 lies(fname,obverb,tz);
} // confdcl::confdcl

paarcl::paarcl(const string& name, const string *const wertp, const string& bemerk):name(name),wert(*wertp),bemerk(bemerk)
{
}

// Achtung: Wegen der Notwendigkeit zur Existenz der Datei zum Aufruf von setfacl kann die Datei erstellt werden!
int confdcl::lies(const string& vfname, int obverb, const char tz/*='='*/)
{
	fLog(violetts+Txk[T_lies]+blau+": "+vfname+schwarz,obverb,/*oblog*/0);
  fname=vfname;
	int erg{0};
	if (fname.empty()) {
		erg=2;
	} else {
		mdatei f(fname,ios::in);
		if (f.is_open()) {
			if (obverb>0) cout<<Txk[T_confdat_lies_Datei]<<blau<<fname<<schwarz<<endl;
			string zeile;
			string ibemerk;
			absch abp;
			while (getline(f,zeile)) {
				size_t pos=zeile.find('#');
				if (!pos||zeile.empty()) {
					continue;
				} else if (pos!=string::npos) {
					// wir nehmen an, die Kommentarzeile gehoert zum naechsten Parameter, wenn sie vorne beginnt
					if (!pos) {
						// Ueberschrift am Anfang  weglassen
						if (paare.empty() && zeile.find("onfigura")!=string::npos && zeile.find("automati")!=string::npos) {
						} else {
							if (!ibemerk.empty()) ibemerk+='\n';
							ibemerk+=zeile.substr(pos);
						} // if (!richtige ... else
					} // if (!pos)
					zeile.erase(pos);
				} // if (pos!=string::npos)
				ltrim(&zeile);
				zn<<zeile;
				////			if (obverb) caus<<zni<<". "<<blau<<"Zeile: "<<schwarz<<*zeile<<endl;
				if (!zeile.empty()) {
					if (obverb>1) fLog(/*Txk[T_stern_zeile]*/"["+ltoan(zn.size(),10,0,4)+"]: "+(zeile[0]=='['?blau:nix)+zeile+schwarz,obverb,0);
					if (zeile[0]=='[' && zeile[zeile.length()-1]==']') {
						mitabsch=1;
						zeile.erase(zeile.length()-1);
						zeile.erase(0,1);
						if (/*!abp.aname.empty() && */abp.av.size()) {
							abschv.push_back(abp);
							abp.clear();
						}
						abp.aname=zeile;
					} else {
						pos=zeile.find(tz);
						if (pos!=string::npos && pos>0) { 
							string pname{zeile.substr(0,pos)};
							rtrim(&pname);
//							shared_ptr<string> wertp{new string(zeile.substr(pos+1))};
//							shared_ptr<string> wertp=make_shared<string>(zeile.substr(pos+1));
							string *const wertp{new string(zeile.substr(pos+1))};
							gtrim(wertp);
							anfzweg(wertp);
							paare.push_back(paarcl(pname,wertp,ibemerk));
							ibemerk.clear();
							if (mitabsch) 
								abp.av.push_back(aScl(pname,wertp));
							else
								delete wertp;
						} // if (pos!=string::npos && 1==sscanf(zeile->c_str(),scs.c_str(),zeile->c_str())) 
					} // if (zeile[0]
				} // if (!zeile->empty()) 
			} // 			while (getline(f,zeile))
			if (!abp.aname.empty() && abp.av.size()) {
				abschv.push_back(abp);
			}
			obgelesen=1;
		} else {
			erg=1;
		} //   if (f.is_open())
	} // 	if (fname.empty())
	if (obverb>0) {
		if (erg)
			cout<<Txk[T_confdat_lies_Misserfolg]<<endl;
		else
			cout<<Txk[T_confdat_lies_Erfolg]<<endl;
	} // 	if (obverb>0)
	fLog(violetts+Txk[T_Ende]+Txk[T_lies]+schwarz,obverb,/*oblog*/0);
	return erg;
} // confdcl::lies



// wird aufgerufen in template<typename SCL> void schAcl<SCL>::schAschreib
template <> void schAcl<WPcl>::eintrinit()
{
}
// wird aufgerufen in template<typename SCL> void schAcl<SCL>::schAschreib
template <> void schAcl<optcl>::eintrinit()
{
	for (size_t i=0;i<schl.size();i++) {
		schl[i]->eingetragen=0;
	}
}

const uchar wpgcl::virteinzutragen(void *schlp,int obverb)
{
	return 1;
}

const uchar optcl::virteinzutragen(/*schAcl<optcl>**/void* schlp,int obverb)
{
	////	const int altobverb=obverb;
	static size_t nr{0};
	nr++;
	////	obverb=1;
	// fLog(violetts+Txk[T_einzutragen]+blaus+pname+schwarz+"'",obverb,0);
	map<string,optcl*>::iterator omit{((schAcl<optcl>*)schlp)->omap.find(pname)};
	////	caus<<violett<<">)"; caus<<omit->first<<endl;caus<<omit->second->pname<<endl;omit->second->virtoausgeb(); caus<<schwarz;
	if (omit!=((schAcl<optcl>*)schlp)->omap.end()) {
		if (omit->second->eingetragen) {
			fLog(ltoan(nr)+" "+violetts+Txk[T_einzutragen]+Txk[T_schon_eingetragen]+blaus+omit->first+schwarz+"' = '"+omit->second->virtholstr()+schwarz+"'",obverb,0);
			////			obverb=altobverb;
			return 0;
		}
		//		optcl* trick=(optcl*)omit->second;
		//		trick->eingetragen=1;
		fLog(ltoan(nr)+" "+violetts+Txk[T_einzutragen]+blaus+Txk[T_wird_jetzt_eingetragen]+blaus+omit->first+schwarz+"' = '"+blau+omit->second->virtholstr()+schwarz+"'",obverb,0);
		omit->second->eingetragen=1;
		////		obverb=altobverb;
		return 1;
	}
	fLog(ltoan(nr)+" "+violetts+Txk[T_einzutragen]+blaus+Txk[T_nicht_gefunden]+": "+blaus+omit->second->virtholstr()+schwarz+"'",obverb,0);
	////	obverb=altobverb;
	return 0;
} // const uchar optcl::virteinzutragen

// wird aufgerufen in template<typename SCL> int schAcl<SCL>::confschreib und multischreib
template<typename SCL> void schAcl<SCL>::schAschreib(mdatei *const f,int obverb)
{
	//	eintrinit();
	////	caus<<"schl.size(): "<<schl.size()<<", omap.size(): "<<omap.size()<<endl;
	for (size_t i=0;i<schl.size();i++) {
		//// <<"i: "<<blau<<i<<schwarz<<", pname: "<<blau<<schl[i]->pname<<schwarz<<", pptr: "<<blau<<schl[i]->virtholstr()<<schwarz<<endl;
		if (!schl[i]->pname.empty()) {
			//		schl[i]->virtoausgeb();
			const uchar einzt{/*1;*/schl[i]->virteinzutragen(this,obverb)};
			//		schl[i]->virtoausgeb();
			if (einzt) {
				schl[i]->virtmachbemerk(Txk.lgn);
				if (!schl[i]->bemerk.empty()) *f<<(schl[i]->bemerk[0]=='#'?"":"# ")<<*loeschefarbenaus(&schl[i]->bemerk)<<endl;
				*f<<schl[i]->pname<<" = \""<<schl[i]->virtholstr()<<"\""<<endl;
			} // 		if (!schl[i]->pname.empty() && schl[i]->virteinzutragen(this))
		}
	} //   for (size_t i=0;i<zahl;i++)
} // void schAcl::schAschreib

// kann aufgerufen werden
template<typename SCL> void schAcl<SCL>::zeigschoen()
{
	for(size_t i=0;i<schl.size();i++) {
		if (!schl[i]->pname.empty())
		cout<<blau<<setw(20)<<schl[i]->pname<<schwarz<<":"<<schl[i]->virtholstr()<<endl;
  }
} // template<typename SCL> void schAcl

// kann aufgerufen werden
template<typename SCL> void schAcl<SCL>::gibaus(const int nr/*=0*/)
{
	cout<<"gibaus(Nr."<<nr<<",name:"<<name<<")"<<endl;
	for(size_t i=0;i<schl.size();i++) {
   cout<<"i: "<<gruen<<i<<schwarz<<",schl:"<<schl[i]<<",pname: "<<blau<<schl[i]->pname<<schwarz<<Txk[T_Wert]<<blau<<schl[i]->virtholstr()<<schwarz<<endl;
  }
} // template<typename SCL> void schAcl

// wird aufgerufen in parsecl, lauf
template<typename SCL> void schAcl<SCL>::oausgeb(const char* const farbe,int obverb/*=0*/,int oblog/*=0*/)
{
	fLog(violetts+name+Txk[T_optausg]+schwarz,obverb,oblog);
	for(size_t iru=0;iru<size();iru++) {
			cout<<farbe<<setw(3)<<iru<<schwarz<<" ";
			schl[iru]->virtoausgeb();
	}
	fLog(violetts+Txk[T_Ende]+name+Txk[T_optausg]+schwarz,obverb,oblog);
} // void schAcl::frisch()

template<typename SCL> void schAcl<SCL>::gibomapaus()
{
	cout<<violett<<"gibomapaus("<<blau<<name<<schwarz<<", size: ";
	cout<<blau<<omap.size()<<violett<<")"<<schwarz<<endl;
	typename map<string,SCL*>::iterator omit;
	for (omit=omap.begin();omit!=omap.end();omit++) {
		omit->second->virtoausgeb();
  }	
	cout<<violett<<"Ende gibomapaus("<<blau<<name<<schwarz<<", size: ";
	cout<<blau<<omap.size()<<violett<<")"<<schwarz<<endl;
}

// wird augerufen in virtautokonfschreib und schreibzaehler
template<typename SCL> int schAcl<SCL>::confschreib(const string& fname,ios_base::openmode modus/*=ios_base::out*/,const string& mpfad,
		uchar faclbak/*=1*/, int obverb/*=0*/,int oblog/*=0*/)
{
  mdatei f(fname,modus);
  if (f.is_open()) {
		time_t jetzt=time(0);
		f<<Txk[T_Konfiguration_fuer]<<mpfad<<Txk[T_erstellt_automatisch_durch_dieses_am]<<ztacl(jetzt,"%d.%m.%Y %H.%M.%S")<<endl;
    schAschreib(&f,obverb);
    return 0;
  } //   if (f.is_open())
  return 1;
} // int schAcl::confschreib

// schreibt ein Array von Schluessel-Arrays der Klasse WPcl in die Datei fname
template<typename SCL> int multischlschreib(const string& fname, schAcl<SCL> *const *const mcnfApp, const size_t cszahl,const string& mpfad)
{
  mdatei f(fname,ios::out);
  if (f.is_open()) {
    if (!mpfad.empty()) {
      //// char buf[30];
      time_t jetzt=time(0);
			f<<Txk[T_Konfiguration_fuer]<<mpfad<<Txk[T_erstellt_automatisch_durch_dieses_am]<<ztacl(jetzt,"%d.%m.%Y %H.%M.%S")<<endl;
			//// pthread_mutex_lock(&timemutex);
			//// tm *ltm = localtime(&jetzt);
			//// strftime(buf, sizeof(buf), "%d.%m.%Y %H.%M.%S", ltm);
			//// f<<put_time(localtime(&jetzt),"%d.%m.%Y %H.%M.%S")<<endl;
			//// pthread_mutex_unlock(&timemutex);
			//// const string ueberschr=Txk[T_Konfiguration_fuer]+mpfad+Txk[T_erstellt_automatisch_durch_dieses_am]+buf;
			//// if (!ueberschr.empty()) f<<ueberschr<<endl;
    } //     if (!mpfad.empty())
    for (size_t j=0;j<cszahl;j++) {
     mcnfApp[j]->schAschreib(&f,1);
    }
    return 0;
  } //   if (f.is_open())
  return 1;
} // int multischlschreib


/*
template<typename SCL> schAcl<SCL>& schAcl<SCL>::operator<<(SCL& sch) 
{ 
	schl.push_back(sch); 
	schl[schl.size()-1].virtweisomapzu(this); 
	return *this; 
}
*/

template<typename SCL> schAcl<SCL>& schAcl<SCL>::operator<<(shared_ptr<SCL> schp)
{
////	shared_ptr<SCL> kopie{schp};
////	schl.push_back(kopie); 
////	caus<<rot<<"Uebertrage nach "<<blau<<name<<rot<<" smart_ptr "<<blau<<schp->pname<<schwarz;
	schl.push_back(schp);
////	caus<<", Adresse: "<<blau<<schl[schl.size()-1]<<schwarz<<endl;
	schl[schl.size()-1]->virtweisomapzu(this); 
	return *this; 
}

template<typename SCL> schAcl<SCL>& schAcl<SCL>::operator<<(SCL *schp) 
// template<typename SCL> schAcl<SCL>& schAcl<SCL>::operator<<(shared_ptr<SCL> schp) 
{ 
	/*//
	caus<<"neuer Ueberladeoperator, pname: "<<schp->pname<<endl;
	SCL *sch= (SCL*)::operator new(sizeof *schp);
	memcpy(sch,schp,sizeof *sch);
	schl.push_back(*schp); 
//	schl[schl.size()-1].virtweisomapzu(this); 
	return *this; 
	*/
	//return operator<<(*schp); 
////	caus<<rot<<name<<rot<<"<<"<<violett<<schp->pname<<endl;
////	caus<<rot<<"Uebertrage nach "<<blau<<name<<rot<<" Zeiger "<<blau<<schp->pname<<schwarz;
	
	shared_ptr<SCL> kopie{schp};
//	shared_ptr<SCL> *kopie = new shared_ptr<SCL>(schp);
	schl.push_back(kopie); 

////	caus<<", Adresse: "<<blau<<schl[schl.size()-1]<<schwarz<<endl;

	schl[schl.size()-1]->virtweisomapzu(this); 
	return *this; 
}

hcl::~hcl()
{
	delete linstp;
	linstp=0;
	////	caus<<"hcl-Destruktor"<<endl;
}

// damit nicht Template-Klassen-Funktionen in Header-Dateien geschrieben werden muessen
template class schAcl<WPcl>;
template class schAcl<optcl>;
