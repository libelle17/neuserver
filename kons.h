#ifdef _MSC_VER
#define _CRT_SECURE_NO_WARNINGS
#endif // _MSC_VER

#ifndef kons_H_DRIN
#define kons_H_DRIN
#ifdef _WIN32
#include <winsock2.h> // entfaellt bei mysql
#include <io.h> // fuer isatty und _isatty
#endif // _WIN32

#include <iostream> // fuer cout, cin, cerr, clog, #include <string> // string
#ifdef _MSC_VER
#include <string>
#endif // _MSC_VER

//#define obfstream
#ifdef obfstream
// #include <fstream> // fstream
#endif  // obfstream

#ifdef linux
#define vtz '/' // Verzeichnistrennzeichen
#define vtzs "/" // Verzeichnistrennzeichenstring
#elif __MINGW32__ || _MSC_VER // linux
#define vtz '\\' // Verzeichnistrennzeichen
#define vtzs "\\" // Verzeichnistrennzeichen
#endif // linux elif __MINGW32__ || _MSC_VER

#ifndef vector_incl
#include <vector> // wird in Manjaro hier nochmal extra benötigt
#define vector_incl
#endif // vector_incl
#include <sys/wait.h> // fuer waitpid
#include <map> // fuer Optionen
#include <memory> // fuer shared_ptr

using namespace std;
extern const string& instvz; // in kons.cpp, z.B. /root/autofax
extern const string& unindt; // instvz+"uninstallinv"
extern const int sfeh[]; // T_Dienst_laeuft, T_Dienst_inexistent, ...
extern const double& versnr; // Programmversion
extern const string& spath; // PATH-Variable für root
string* loeschefarbenaus(string *zwi);
int yLog(const short screen,const short file, const bool oberr,const short klobverb, const char *format, ...);
int fLog(const string& text,const short screen=1,const short file=1,const bool oberr=0,const short klobverb=0);

#ifdef _MSC_VER
#define fileno _fileno // sonst Warnung posix deprecated
#define isatty _isatty // sonst Warnung posix deprecated
#endif // _MSC_VER

#ifdef __MINGW32__
#undef PATH_MAX
#endif // __MINGW32__

#ifdef _WIN32
#define PATH_MAX MAX_PATH
// #include <limits.h>
#include <time.h> // fuer mktime und time in kuerzelogdatei
#define lstat stat

#elif linux // _WIN32
#include <iomanip> // setprecision
#include <string.h> // strchr, strcpy, strtok_r, strerror, memcmp, strcmp, strstr, strlen
#include <errno.h> // errno, ENOENT
#include <pwd.h>   // getuid, getpwuid
#include <grp.h>   // getgrouplist
#include <sys/param.h>  // MAXHOSTNAMELEN
#include <sys/ioctl.h> // winsize, TIOCGWINST, w, ioctl
// #include <stdlib.h>
#include <dirent.h> // DIR, dirHandle, opendir, readdir, PATH_MAX
#include <unistd.h> // dup2, close, STDIN_FILENO, gethostname
#endif // _WIN32 elif linux

#ifndef _MSC_VER
#include <stdio.h> // fuer fopen, perror, fgets, sscanf, fputs, fclose, stdout, fileno, stderr
#else
#define snprintf _snprintf
#endif

#include <sys/stat.h> // stat, lstat, S_IFMT, S_IFDIR ...
// #include <boost/algorithm/string.hpp> // clock, numeric_limits, boost::iequals
#include <boost/locale.hpp> // fuer to_upper und to_lower
// #include <limits>
extern const boost::locale::generator gen; // fuer to_upper, to_lower
extern const std::locale loc;

typedef unsigned char uchar; // 1 Byte
enum binaer:uchar {falsch,wahr};
enum Sprache {deutsch,englisch,SprachZahl};
extern const char *const dir;
extern const char *const tmmoegl[];
//extern const string datei;
// extern const char *rot, *weinrot, *schwarz, *blau, *gelb; // muss spaeter kompilerunabhaengig
extern const char *const schwarz, *const dgrau, *const drot, *const rot, *const gruen, *const hgruen, *const braun, *const gelb,
			 *const blau, *const dblau, *const violett, *const hviolett, *const tuerkis, *const htuerkis, *const hgrau, *const weiss, *const umgek;
extern const string drots,rots,schwarzs,blaus,dblaus,gelbs,tuerkiss,hgraus,violetts,hvioletts,gruens;
#ifdef linux
extern const char *_rot, *_hrot, *_schwarz, *_blau, *_gelb, *_tuerkis, *_hgrau;
#endif // linux
#include <fstream> // kopiere
#include <algorithm>    // std::transform
#include <regex.h> // regex_t, regex, regcomp, regexec
#include <chrono> // fuer sleep_for 
#include <thread> // fuer sleep_for
#include <iconv.h> // fuer ic_cl (Konversion von Dos-Dateien in utf-8)
#include <utime.h>  // fuer utimbuf und utime

#define neufind
#define altfind
#if defined(neufind) || defined(altfind)
#define mitset
#ifdef mitset
#include <set>
#else // mitset
#include <map>
#endif // mitset else
#define B_Datei 1
#define B_Verzn 2
#define B_Chdev 4
#define B_Block 8
#define B_FIFO 16
#define B_Link 32
#define B_Sock 64
#define B_Alle 127 
#define Fol_Dat 1 // folge Datei: liefere Ziel eines Links anstatt der Link-Datei
#define Fol_Ver 2 // folge Verzeichnis: suche auch in Verzeichnis, auf das ein gefundener Link zeigt, egal wo es liegt
#define Fol_Mus 4 // folge Vergleiche das Muster mit Ziel eines Links anstatt der Link-Datei
enum {
  REGFEHLER=997,
  DIRFEHLER=998, 
  REALPATHFEHLER=999
};
#endif

#define caus cout // nur zum Debuggen
#define exitt exit // fuer threads
extern pthread_mutex_t getmutex, printf_mutex, timemutex;
size_t thr_strftime(const struct tm* const timeptr,string *const ziel,const char* const format="%d.%m.%Y %H.%M.%S");
extern const string devtty;

typedef unsigned long long ull;
extern uchar findv/*=3*/; // find-Version 1=system, 2=intern mit readdir, 3=intern mit nftw
class elem2;
#ifdef mitset
typedef set<elem2> el2set;
#else // mitset
typedef map<elem2,ull> el2set;
#endif // mitset else
extern el2set::iterator it2;
class elem3;
extern set<elem3>::iterator it3;

extern const string nix/*={}*/;
extern const string eins/*="1"*/;
extern const string sudc/*="sudo "*/;
extern const string sudhc/*="sudo -H "*/;
struct linst_cl;
extern linst_cl* linstp/*=0*/; // globales Objekt
// typedef const char *TCtp[][SprachZahl];
typedef const char * const * const TCtp[SprachZahl];
class TxB // Text-Basisklasse
{
 public:
  Sprache lgn; // Sprache numerisch
//  TCtp* TCp;
  const char * const * const * const *TCp;
	TxB(const char* const* const* const *TCp);
	inline const char* const operator[](long const& nr) const {
		TCtp *hilf = reinterpret_cast<TCtp*>(TCp);
		return (const char* const)hilf[nr][lgn];
	}
}; // class TxB // Text-Basisklasse

string meinpfad();

enum Tkons_ 
{
	T_j_af,
  T_pfad,
  T_kuerze_logdatei,
  T_Logdatei,
  T_gibt_es_noch_nicht_Kuerze_sie_daher_nicht,
  T_Kann_Datei,
  T_nicht_als_fstream_zum_Schreiben_oeffnen,
  T_nicht_als_fstream_zum_Lesen_oeffnen,
  T_nicht_mit_fopen_zum_Schreiben_oeffnen,
  T_nicht_mit_fopen_zum_Lesen_oeffnen,
  T_Variable_logdatei_leer,
	T_Variable_logdatei_Verzeichnis,
  T_nicht_als_fstream_zum_Anhaengen_oeffnen,
	T_nicht_mit_open_zum_Anhaengen_oeffnen,
  T_nicht_mit_fopen_zum_Anhaengen_oeffnen,
  T_Bitte_mit,
  T_beenden,
  // T_stern_zeile,
  T_Rueckmeldung,
  T_Suchbefehl,
  T_Fuehre_aus,
  T_fehlgeschlagen_bei,
  T_Fuehrte_aus,
  T_komma_Ergebnis,
  T_kein_Verzeichnis_nochmal,
  T_nicht_gefunden_soll_ich_es_erstellen,
  T_Fehlender_Parameter_string_zu,
	T_Fehlender_Parameter_Datum_zu,
	T_oder,
  T_Fehler_Parameter,
  T_ohne_gueltigen,
  T_mit_Datei_als,
  T_mit_falschem,
  T_Pfad_angegeben,
  T_Nicht_numerischer,
  T_Fehlender,
  T_Parameter_nr_zu,
  T_Fehler,
  T_Erfolg,
  T_Weder_zypper_noch_apt_get_noch_dnf_noch_yum_als_Installationspgrogramm_gefunden,
  T_Logdateidpp,
  T_Lese_Konfiguration_aus,
  T_j_k,
  T_Fehler_bei_auswert,
  T_nicht_gefunden,
  T_Muss_Datei,
  T_fuer,
  T_zugreifbar_machen,
  T_spruef_sname,
  T_lief_schon,
  T_nicht_gefunden_versuche_ihn_einzurichten,
  T_Aktiviere_Dienst,
  T_Program,
  T_laeuft_schon_einmal_seit,
	T_sec_Breche_ab,
	T_laueft_schon_einmal_aber,
	T_wird_deshalb_abgebrochen,
	T_Wert,
  T_Dauer,
  T_Dienst,
  T_geladen,
	T_ermoeglicht,
	T_nicht_ermoeglicht,
  T_nicht_geladen,
  T_am,
  T_als_Dienst_eingerichtet_von,
  T_Versuch,
  T_machfit,
  T_Loesche_Ausrufezeichen,
  T_Fehler_beim_Loeschen,
  T_nicht_geloescht_war_eh_nicht_mehr_da,
  T_pruefpar,
  T_Konfiguration_fuer,
  T_erstellt_automatisch_durch_dieses_am,
  T_Fehler_bei_lstat,
  T_Datum_nicht_gesetzt_bei,
  T_Konnte_Datei,
  T_nicht_zum_Lesen_oeffnen,
  T_nicht_zum_Schreiben_oeffnen,
  T_Zeilen,
	T_oder_nicht,
	T_nicht_einfuegbar,
  T_erneute_Eingabe,
	T_obsfveh,
	T_laeuft_jetzt,
	T_Dienst_inexistent,
	T_Dienstdateiname_nicht_ermittelbar,
	T_Dienst_laeuft_noch_aber_Dienstdatei_inexistent,
	T_Exec_Dateiname_nicht_ermittelbar,
	T_Exec_Datei_fehlt,
	T_activating,
	T_Dienst_kann_gestartet_werden,
	T_Sonstiges,
	T_Ergebnis_Dienst,
	T_Dienst_laeuft,
	T_Dienst_disabled,
	T_stopdis_sname,
	T_enableggf,
	T_semodpruef,
	T_Exitcode,
	T_trenne,
	T_bei,
	T_Konnte_regulaeren_Ausdruck_nicht_kompilieren,
	T_doinst,
	T_Ins_Deinstallationsprogramm_wird_eingetragen,
	T_fallsnichtda,
	T_ohneabh,
	T_Tiefe,
	T_Linkverzeichnis,
	T_Suche_in,
	T_nach,
	T_Typbit,
	T_Folge,
	T_noext,
	T_Ergebnis,
	T_Fehler_beim_Deferenzieren_von,
	T_Ende,
	T_startundenable,
	T_pruefberecht,
	T_Datei,
	T_Erg,
	T_Benutzer,
	T_obunter,
	T_datei,
	T_Ergebnis_nach_make,
	T_Ergebnis_nach_make_install,
	T_Programm,
	T_Freie_Software,
	T_Verfasser,
	T_Letzte_Programmaenderung,
	T_Kompiliert,
	T_Quelle,
	T_Hilfe,
	T_Installationsverzeichnis,
	T_or,
	T_aktuelle_Einstellungen_aus,
	T_lg_k,
	T_language_l,
	T_lang_k,
	T_lingue_l,
	T_sprachstr,
	T_v_k,
	T_verbose_l,
	T_lvz_k,
	T_logvz_l,
	T_ld_k,
	T_logdname_l,
	T_l_k,
	T_log_l,
	T_ldn_k,
	T_logdateineu_l,
	T_kd_k,
	T_konfdatei_l,
	T_Bildschirmausgabe_gespraechiger,
	T_waehlt_als_Logverzeichnis_pfad_derzeit,
	T_logdatei_string_im_Pfad,
	T_sonst_knapper,
	T_wird_verwendet_anstatt,
	T_logdatei_vorher_loeschen,
	T_verwendet_Konfigurationsdatei_string_anstatt,
	T_standardhilfe,
	T_libtest,
	T_protokolliert_ausfuehrlich_in_Datei,
	T_sh,
	T_virtlieskonfein,
	T_pruefcron,
	T_cronzuplanen,
	T_Kein_cron_gesetzt_nicht_zu_setzen,
	T_wird,
	T_unveraendert,
	T_alle,
	T_Minuten,
	T_gar_nicht,
	T_aufgerufen,
	T_statt,
	T_virtschlussanzeige,
	T_Zeit_Doppelpunkt,
	T_Fertig_mit,
	T_eigene,
	T_entfernen,
	T_belassen,
	T_warte,
	T_wird_aktualisiert_bitte_ggf_neu_starten,
	T_muss_nicht_aktualisiert_werden,
	T_confdat_lies_Datei,
	T_confdat_lies_Erfolg,
	T_confdat_lies_Misserfolg,
	T_pruefsamba,
	T_Samba_muesste_installiert_werden_soll_ich,
	T_Sollen_fehlende_Sambafreigaben_fuer_die_angegebenen_Verzeichnisse_ergaenzt_werden,
	T_Passwort_fuer_samba,
	T_Firewallport,
	T_offen,
	T_zu,
	T_Soll_die_SuSEfirewall_bearbeitet_werden,
	T_Verzeichnis,
	T_nicht_als_Sambafreigabe_gefunden_wird_ergaenzt_in,
	T_fuer_Benutzer,
	T_prueftif,
	T_holsystemsprache,
	T_hcl_hcl,
	T_erfolgreich_fuer,
	T_Libtiff_Version,
	T_Fertig_mit_Parsen_der_Befehlszeile,
	T_ja,
	T_nein,
	T_Testaufruf_wegen_Programmbibliotheken,
	T_Gebrauch,
	T_Optionen_die_nicht_gespeichert_werden,
	T_Optionen_die_in_der_Konfigurationsdatei_gespeichert_werden,
	T_autokonfschreib,
	T_zu_schreiben,
	T_rueckzufragen,
	T_schreibe_Konfiguration,
	T_h_k,
	T_lh_k,
	T_hilfe_l,
	T_lhilfe_l,
	T_fgz_k,
	T_fgz_l,
	T_Erklaerung_haeufiger_Optionen,
	T_Erklaerung_aller_Optionen,
	T_cm_k,
	T_cronminuten_l,
	T_Alle_wieviel_Minuten_soll,
	T_aufgerufen_werden_0_ist_gar_nicht,
	T_vi_k,
	T_vi_l,
	T_Konfigurationsdatei,
	T_Logdatei_usw_bearbeiten_sehen,
	T_vs_k,
	T_vs_l,
	T_Quelldateien_in,
	T_bearbeiten_sehen,
	T_nicht_erkannt,
	T_autoupd_k,
	T_autoupd_l,
	T_Programm_automatisch_aktualisieren,
	T_rf_k,
	T_rueckfragen_l,
	T_krf_k,
	T_keinerueckfragen_l,
	T_keine_Rueckfragen_zB_aus_Cron,
	T_alle_Parameter_werden_abgefragt_darunter_einige_hier_nicht_gezeigte,
	T_info_k,
	T_version_l,
	T_Zeigt_die_Programmversion_an,
	T_zeigvers,
	T_Sollen_neue_Programmversionen_von,
	T_automatisch_installiert_werden,
	T_Logverzeichnis,
	T_Logdateiname,
	T_Oblog_ausf_Protok,
	T_Aufrufintervall,
	T_kein_Aufruf,
	T_Minute,
	T_Logpfad,
	T_oblog,
	T_in_main_pidv_am_Schluss,
	T_parsecl,
	T_lies,
	T_verarbeitkonf,
	T_kauswert,
	T_optausg,
	T_einzutragen,
	T_schon_eingetragen,
	T_wird_jetzt_eingetragen,
	T_lieszaehlerein,
	T_Parameter,
	T_gefunden,
	T_rueckzufragen_wegen,
	T_virtlgnzuw_langu,
	T_mit_w_werden_die_Einstellungen_noch_ausfuehrlicher_angezeigt,
	T_keine_Daten_zum_Anzeigen_Bearbeiten,
	T_Maximaldauer_ueberschritten,
	T_Fehler_in_setfaclggf,
	T_Fehler_in_find2cl,
	T_nach_sh_viall_beendet,
	T_nach__,
	T_unbek,
	T_Progvers,
	T_verwendet_wird,
	T_Ausgabezeile,
	T_pruefmehrfach,
	T_Sprachen,
	T_Intervall_Minuten,
	T_konsMAX
}; // Tkons_

extern const string sprachstr;
/*
extern class Txkonscl Txk;

class Txkonscl : public TxB
{
  public:
    static const char *TextC[T_konsMAX+1][SprachZahl];
    Txkonscl();
//    inline const char* operator[](Tkons_ const& nr) const { return TextC[nr][lgn]; }
};
*/
extern class TxB Txk;
extern char const *DPROG_T[][SprachZahl];
extern class TxB Tx;

extern uchar nrzf; // nicht rueckzufragen, fuer Aufruf aus Cron
template<typename T> size_t elemzahlT(T& v){return sizeof(v)/sizeof(*v);}
#define elemzahl(v)               (sizeof(v)/sizeof((v)[0]))

struct errmsgcl
{
		int errnr;
		string msg;
		errmsgcl(int errnr,const string& msg):errnr(errnr),msg(msg){}
};
// aktueller Benutzer
class cuscl
{
	private:
		struct passwd *passwd;
	public:
		string cusstr;
		uid_t cuid;
		gid_t cgid;
		cuscl();
};

// arg-Class
class argcl
{
 public:
 const char *argcs;  // Zeiger auf einen Commandline-Parameter
 uchar agef=0; // dieser wurde gefunden
 argcl(const int i, const char *const *const argv);
};

// Gebrauch, z.B.: ic_cl ic("UTF8","CP850");
////			caus<<ic.convert(inh)<<endl;
class ic_cl 
{
	iconv_t ict;
	static const size_t grenze=500, 
							 reserve=4*grenze;
	char ergcont[reserve],
			 *ergdyn=0;
	public:
	char *ergebnis;
	ic_cl(const char* nach, const char* von); 
	~ic_cl();
	char *convert(string& eing,size_t ab=0);
};

class perfcl
{
 public:
 string vonwo;
 clock_t zp0, zp1, zp1alt;
 time_t t0=0, t1;
 unsigned long nr=0;
 perfcl(const string& vvonwo);
 void ausgeb(const string& stelle=nix,uchar obdauer=0);
 void ausgab1000(const string& stelle=nix);
 int oberreicht(unsigned long sek);
};

string holsystemsprache(int obverb=0);
int pruefberecht(const string& datei,const string& benutzer,const mode_t mod=01,int obverb=0);
int untersuser(const string& uname,__uid_t *uidp=0, __gid_t *gidp=0, vector<gid_t> *gids=0,struct passwd* ustr=0);
double verszuzahl(const string& vers);

class mdatei: public fstream
{
  public:
  int oboffen=0;
  mdatei(const string& filename, ios_base::openmode mode=ios_base::in|ios_base::out, uchar faclbak=1, int obverb=0, int oblog=0);
}; // class mdatei: public fstream

// Zeitausgabeklasse, um time_t-Variablen formatiert in ostream-Objekte ausgeben zu koennen, z.B. <<ztacl(zt,"%F %T")<<
class ztacl {
	private:
		tm tmloc;
		const time_t zt;
		const char* const fmt;
	public:
		explicit ztacl(const time_t &pzt,const char* const pfmt="%d.%m.%Y %H.%M.%S");
		// folgendes würde die Werte fuer nachfolgenden Wertvergleich mit memcmp verfälschen:
		// explicit ztacl(tm *const tm,const char* const pfmt="%d.%m.%Y %H.%M.%S %z %Z");
		explicit ztacl(const tm *const tm,const char* const pfmt="%d.%m.%Y %H.%M.%S %z %Z");
		std::ostream &operator()(std::ostream& out) const;
}; // ztacl
ostream &operator<<(ostream &out,ztacl ztaus);

inline string zustr(int _Val) 
{
  char _Buf[2 * sizeof(long long)];
  snprintf(_Buf,2*sizeof(long long), "%d", _Val);
  return string(_Buf);
} // inline string zustr(int _Val)

inline std::string right(std::string const& source, size_t const length)
{
  if (length >= source.size()) { return source; }
  return source.substr(source.size() - length);
} // inline std::string right(std::string const& source, size_t const length)

inline std::string mitvtz(std::string const& vz)
{
  if (right(vz,1)==string(1,vtz)) {
    return vz;
  } else {
    return vz+vtz;
  }
} // inline std::string mitvtz(std::string const& vz)

inline int istelnr(const std::string& str)
{
  if	(str.find_first_not_of("+ 0123456789.,")==string::npos && str.find_first_not_of(" ")!=string::npos) 
    return 1;
  return 0;
} // inline int istelnr(const std::string& str)

inline int isnumeric(const std::string& str)
{
  if	(str.find_first_not_of(" 0123456789.,")==string::npos && str.find_first_not_of(" ")!=string::npos) 
    return 1;
  return 0;
} // inline int isnumeric(const std::string& str)

inline int isneun(const std::string& str)
{
  if	(str.find_first_not_of(" 9")==string::npos && str.find_first_not_of(" ")!=string::npos) 
    return 1;
  return 0;
} // inline int isneun(const std::string& str)


inline int isnumeric(const char* str)
{
  while (*str) {
    if(!strchr(" 0123456789.,",*str)) return 0;
    str++;
  }
  return 1;
} // inline int isnumeric(char* str)

string zuzahl(const string& q);
 
string* anfzweg(string *quel);
char ers(const char roh);

// Gesamt-Trim
inline std::string *gtrim(std::string *str) {
  str->erase(0, str->find_first_not_of("\t "));       //prefixing spaces
  str->erase(str->find_last_not_of("\t ")+1);         //surfixing spaces
  return str;
} // inline std::string *gtrim(std::string *str)

inline std::string *ltrim(std::string *str) {
  str->erase(0, str->find_first_not_of("\t "));       //prefixing spaces
  return str;
} // inline std::string *ltrim(std::string *str)

inline std::string *rtrim(std::string *str) {
  str->erase(str->find_last_not_of("\t ")+1);         //surfixing spaces
  return str;
} // inline std::string *ltrim(std::string *str)

inline void rtrim(char* str,size_t size) {
  for (int nd=0,i=size-1;i;i--) {
    if (!str[i]) nd=1; 
    else if (nd && str[i]!=32 && str[i]!=9) break;
    str[i]=0;
  } //   for (int nd=0,i=size-1;i;i--)
} // inline void rtrim(char* str,size_t size)

string fersetze(const string& u, const char* alt, const char* neu);
string caseersetze(const string& u, const char* const alt, const char* const neu); 
string *loeschealleaus(string *u, const char* alt);

string ersetze(const char *const u, const char* const alt, const char* const neu);
string *sersetze(string *src, string const& target, string const& repl);
// wstring ersetze(const wstring& u, const wchar_t* alt, const wchar_t* neu); 
string nersetze(const string& quelle, string const& was, string const& durch);

string ersetzAllezu(const string& quelle, const string& alt, const string& neu);
void ersetzAlle(string& quelle, const string& alt, const string& neu);
string ersetzAllezu(string *quelle, const char* const alt, const char* const neu);
string ersetzAllezu(const char *const quelle, const char* const alt, const char* const neu);
void ersetzAlle(string *quelle, const char* const alt, const char* const neu);
void ersetzAlle(string *quelle, const string& alt, const string& neu);

char* charersetze(char *u, const char alt, const char neu);
void chersetze(const string& u, string *z, const string& alt, const char neu);
string ersetzefuerdatei(const string& u);
void fuersamba(string& roh);
size_t zahlin(const string *const str, const char* const was);
long cmpmem( char* feld, const char* search, int len_feld); // , int len_search
// fuer lies (Konfigurationsdatei lesen)
string ltoan(long value, int base=10, uchar obtz=0, uchar minstel=0); 
char* ltoa_(long value, char* result, int base=10); 
void anfgw(const string& datei, const string& udpr, const string& inhalt, const string& comment, int obverb/*=0*/, int oblog/*=0*/);
void anfgg(const string& datei, const string& inhalt, const string& comment, int obverb/*=0*/, int oblog/*=0*/);
void doanfg(const string& datei, const string& inhalt, const string& comment);

int touch(const std::string& pathname,int obverb=0,int oblog=0);
std::string string_to_hex(const std::string& input);
int dateivgl(const string& d1, const string& d2,uchar obzeit=0);
void kuerzevtz(string *vzp);

struct svec: public vector<std::string>
{
	inline svec& operator<<(const std::string& str) {
		this->push_back(str);
		return *this;
	}
}; // class svec: public vector<std::string>

//svec& operator<<(svec& v, const std::string& str);
template<typename T>
class tsvec: public vector<T>
{
  public:
    inline tsvec<T>& operator<<(const T& str) {
      this->push_back(str);
//      ((T&)str).init();
      return *this;
    } // inline tsvec
}; // template<typename T> class tsvec: public vector<T>


template <typename SCL> class schAcl;

enum par_t:uchar {pstri,pdez,ppwd,pverz,pfile,puchar,pbin,pint,plong,pdat}; // Parameterart: Sonstiges, Verzeichnis, Datei, uchar, int, long, Datum (struct tm)
////enum war_t:uchar {wlong,wbin,wstr,wdat}; // Parameterart: Sonstiges, Verzeichnis, Zahl, binär
// Wertepaargrundklasse, für WPcl und optcl
struct wpgcl 
{ 
		string pname{};
		uchar ausgewertet{0};
    const void *pptr={0}; // Zeiger auf Parameter, der hier eingestellt werden kann
    string bemerk;
    par_t part=pstri; // Parameterart
    uchar gelesen{0};
		uchar eingetragen{0}; // Hilfsvariable zur genau einmaligen Eintragung einer Option mit name=pname in Konfigurationsdatei
		wpgcl(const string& pname,const void* pptr,par_t part);
		string virtholstr() const;
    virtual const string& virtmachbemerk(const Sprache lg,const binaer obfarbe=wahr);
		void virtweisomapzu(void *schlp);
		int tusetzstr(const char* const neuw,uchar *const tuschreibp,const uchar ausDatei=0,const uchar keineprio=0);
		virtual int setzstr(const char* const neuw,uchar *const obzuschreib=0,const uchar ausDatei=0)=0;
		const uchar virteinzutragen(/*schAcl<optcl>**/void *schlp,int obverb);
    void virttusetzbemerkwoher(const string& ibemerk,const uchar vwoher);
		void virtfrisch();
		void virtoausgeb() const;
};

// fuer Wertepaare, die nur aus Datei gezogen werden und nicht zusaetzlich ueber die Befehlszeile eingegeben werden koennen
// Wertepaarklasse
struct WPcl:wpgcl 
{ 
    string wert;
		WPcl(const string& pname,const void* pptr=0,par_t part=pstri);
		int setzstr(const char* const neuw,uchar *const obzuschreib=0,const uchar ausDatei=0);
		int setzstr(const string& neus,uchar *const obzuschreib=0,const uchar ausDatei=0);
		string virtholstr() const;
		//    inline WPcl& operator=(WPcl zuzuw){pname=zuzuw.pname;wert=zuzuw.wert; return *this;} // wird nicht benoetigt
//    template <typename T> void hole(T *var) { *var=atol(wert.c_str()); }
//    template <typename T> void setze(T *var) { wert=ltoan(*var); }
//    template <typename T> void setze(T *var,string& bem) { wert=ltoan(*var); bemerk=bem;}
//		void hole(struct tm *tmp);
		void virtoausgeb() const;
		void virtfrisch();
}; // class WPcl
/*
template <> inline void WPcl::hole < char* > (char** var) {*var = (char*)wert.c_str(); }
template <> inline void WPcl::hole < const char* > (const char** var) {*var = wert.c_str(); }
template <> inline void WPcl::hole < string > (string *var) {*var = wert; }
template <> inline void WPcl::hole < binaer > (binaer *var) { *var = (binaer)atoi(wert.c_str()); }
*/
/*
template <> inline void WPcl::hole < struct tm > (struct tm *tmp) {
	if (!wert.empty()) {
		for(unsigned im=0;im<elemzahl(tmmoegl);im++) {
			if (strptime(wert.c_str(), tmmoegl[im], tmp)) break;
		}
									//		strptime(wert.c_str(), "%d.%m.%y %T", tmp);
	}
}
*/
/*
template <> inline void WPcl::setze < char* > (char** var) {wert=*var;  }
template <> inline void WPcl::setze < const char* > (const char** var) {wert=*var; }
template <> inline void WPcl::setze < string > (string *var) {wert=*var;}
template <> inline void WPcl::setze < const string > (const string *var) {wert=*var; }
template <> inline void WPcl::setze < struct tm > (struct tm *tmp) {
	char buf[30];
	strftime(buf, sizeof(buf), "%d.%m.%y %T", tmp);
	wert=buf;
}
*/
/*
template <> inline void WPcl::setze < char* > (char** var, string& bem) {wert=*var; if (!bem.empty()) bemerk=bem; }
template <> inline void WPcl::setze < const char* > (const char** var, string& bem) {wert=*var; if (!bem.empty()) bemerk=bem;}
template <> inline void WPcl::setze < string > (string *var, string& bem) {wert=*var;if (!bem.empty()) bemerk=bem;}
template <> inline void WPcl::setze < const string > (const string *var, string& bem) {wert=*var; if (!bem.empty()) bemerk=bem;}
*/

// neue Klasse für map
// fuer Wertepaare, die aus Datei gezogen werden und zusaetzlich ueber die Befehlszeile eingegeben werden koennen
struct optcl:wpgcl
{
		const int kurzi{-1};
		const int langi{-1};
    TxB *TxBp{0}; // nicht const, da lgn geändert werden muß
    const long Txi{0};
		const uchar wi{0}; // Wichtigkeit: 1= wird mit -lh oder -h, 0= nur mit -lh, 255 (-1) = gar nicht angezeigt
    const long Txi2{-1};
    const string rottxt; // ggf rot zu markierender Text zwischen Txi und Txi2
//    string oerkl;
    int iwert; // Wert, der pptr zugewiesen wird, falls dieser Parameter gewaehlt wird; -1= Wert steht im nächsten Parameter, 1=pro Nennung in der Kommandozeile wert um 1 erhöhen
//    string *zptr=0; // Zeiger auf Zusatzparameter, der hier eingegeben werden kann (z.B. Zahl der Zeilen nach -n (Zeilenzahl)
//    schAcl<WPcl> *cpA=0; // Konfigurationsarray, das ggf. geschrieben werden muss
//    uchar ogefunden=0; // braucht man nicht, ist in argcl
		// ermittelte Optionen:
		uchar woher{0}; // 1= ueber Vorgaben, 2= ueber Konfigurationsdatei, 3= ueber Befehlszeile gesetzt
		const long Txrf{-1};
    const uchar obno{0}; // ob auch die Option mit vorangestelltem 'no' eingefuegt werden soll
		uchar gegenteil{0};
		uchar nichtspeichern{0};
		const uchar virteinzutragen(/*schAcl<optcl>**/void *schlp,int obverb);
		void virtweisomapzu(/*schAcl<optcl>**/void *schlp);
//		void virtloeschomaps(/*schAcl<optcl>**/void *schlp);
		void virtloeschomaps(schAcl<optcl> *schlp);
		optcl(const string& pname,const void* pptr,const par_t art, const int kurzi, const int langi, TxB* TxBp, const long Txi,
				const uchar wi, const long Txi2, const string rottxt, const int iwert, const uchar woher, const long Txrf, const uchar obno=0);
		optcl(const void* pptr,const par_t art, const int kurzi, const int langi, TxB* TxBp, const long Txi,
				const uchar wi, const long Txi2, const string rottxt, const int iwert,const uchar woher, const uchar obno=0);
		void setzwert();
		int setzstr(const char* const neuw,uchar *const obzuschreib=0,const uchar ausDatei=0);
		void virttusetzbemerkwoher(const string& ibemerk,const uchar vwoher);
		void virtoausgeb() const;
		int pzuweis(const char *const nacstr, const uchar vgegenteil=0, const uchar vnichtspeichern=0);
		virtual const string& virtmachbemerk(const Sprache lg,const binaer obfarbe=wahr);
		void hilfezeile(Sprache lg);
		void virtfrisch();
		~optcl();
}; // struct optcl

// fuer Commandline-Optionen
// enum par_t:uchar {pstri,pdez,ppwd,pverz,pfile,puchar,pbin,pint,plong,pdat}; // Parameterart: Sonstiges, Verzeichnis, Datei, uchar, int, long, Datum (struct tm)

struct aScl {
   const string name;
   const string *wertp;
   aScl(const string& name, const string *wertp):name(name),wertp(wertp) {}
}; // class aScl

struct aSvec:vector<aScl>
{
	inline aSvec& operator<<(const aScl& aS) {
		this->push_back(aS);
		return *this;
	}
}; // class aSvec: public vector<std::string>

template <typename SCL> class schAcl {
 public:
	string name;
// WPcl *schl=0; 
	//vector<SCL*> schl; // Schlüsselklasse Schlüssel
	vector<shared_ptr<SCL>> schl; // Schlüsselklasse Schlüssel
//// inline schAcl& operator<<(const SCL& sch) { sch.virtweisomapzu(this); schl.push_back(sch); return *this; }
//// schAcl& operator<<(SCL& sch);
//// inline schAcl& operator<<(SCL *schp) { schp->virtweisomapzu(this); schl.push_back(*schp); return *this; }
 schAcl& operator<<(SCL *schp);
 schAcl& operator<<(shared_ptr<SCL> schp);
 // schAcl& operator<<(shared_ptr<SCL> schp);
// inline const SCL* operator[](size_t const& nr) const { return schl[nr].get(); }
// inline SCL* operator[](size_t const& nr) { return schl[nr].get(); }
 inline const shared_ptr<const SCL> operator[](size_t const& nr) const { return schl[nr];}
 inline shared_ptr<SCL> operator[](size_t const& nr) { return schl[nr];} // fuer hilfezeile, virtmachbemerk
 inline size_t size(){return schl.size();}
 inline shared_ptr<SCL> letzter() {return schl[schl.size()-1];} 
 schAcl(const string& name);
 schAcl(const string& name, vector<aScl> *v);
#ifdef false
 schAcl(const string& name, vector<aScl> v);
#endif
// schAcl(const string& name, const char* const* sarr,size_t vzahl);
 // void neu(size_t vzahl=0);
 void sinit(size_t vzahl, ...);
 void sinit(vector<shared_ptr<SCL>> sqlvp);
 map<string,SCL*> omap; // map der Optionen
 map<const char* const,SCL const*> okmap; // map der Optionen, sortiert nach Tx[<kurzi>]
 map<const char* const,SCL const*> olmap; // map der Optionen, sortiert nach Tx[<langi>]
 typename map<string,SCL*>::iterator omit; // Optionen-Iterator
 //		void omapzuw(); // Optionen an omap zuweisen
 // void initd(const char* const* sarr,size_t vzahl);
 // void initv(vector<optcl*> optpv,vector<size_t> optsv);
 // int setze(const string& pname, const string& wert/*, const string& bem=nix*/);
 // const string& hole(const string& pname);
 void setzbemv(const string& pname,TxB *TxBp,size_t Tind,uchar obfarbe=0,svec *fertige=0);
 void setzbemerkwoher(SCL *optp,const string& ibemerk,const uchar vwoher);
 void schAschreib(mdatei *const f,int obverb); // Schluessel-Array-schreib
 int confschreib(const string& fname,ios_base::openmode modus=ios_base::out,const string& mpfad=nix,const uchar faclbak=1,int obverb=0,int oblog=0);
 void zeigschoen();
 void gibaus(const int nr=0);
 void oausgeb(const char* const farbe,int obverb=0,int oblog=0);
 void gibomapaus();
 void eintrinit();
 void frisch();
 ~schAcl();
}; // class schAcl
template <> void schAcl<WPcl>::sinit(size_t vzahl, ...);
template <> void schAcl<WPcl>::eintrinit();
template <> void schAcl<optcl>::eintrinit();

// Linux-System-Enum
enum lsysen:uchar {usys,sus,deb,fed};
class lsyscl
{
    lsysen sys=usys; 
		string usr_lib64_vz;
  public:
    lsysen getsys(int obverb=0,int oblog=0);
		string& getlib64(int obverb=0,int oblog=0);
}; // class lsyscl

// enum betrsys {keins,suse,ubuntu,fedora};
// betrsys pruefos();
int obprogda(const string& prog, int obverb=0, int oblog=0, string *pfad=0);
enum instprog {keinp,zypper,apt,dnf,yum,urp,pac};
string gethome();


#ifdef _MSC_VER
extern inline void wait();
#else // _MSC_VER
// #define wait();
#endif // _MSC_VER

#ifdef _WIN32
extern const char *drot, *rot, *schwarz, *blau, *gelb, *tuerkis, *hgrau;
extern const string drots, rots, schwarzs, blaus, gelbs, tuerkis, hgrau;
inline std::ostream& _drot(std::ostream &s){
  //    HANDLE hStdout = GetStdHandle(STD_OUTPUT_HANDLE); 
  SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), FOREGROUND_RED|FOREGROUND_INTENSITY);
  return s;
}
inline std::ostream& _blau(std::ostream &s){
  SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), FOREGROUND_BLUE|FOREGROUND_INTENSITY);
  return s;
}
inline std::ostream& _rot(std::ostream &s){
  //    HANDLE hStdout = GetStdHandle(STD_OUTPUT_HANDLE); 
  SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), FOREGROUND_RED|FOREGROUND_GREEN|FOREGROUND_INTENSITY);
  return s;
}
inline std::ostream& _schwarz(std::ostream &s){
  SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), FOREGROUND_RED|FOREGROUND_GREEN|FOREGROUND_BLUE);
  return s;
}
inline std::ostream& _gelb(std::ostream &s){
  SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), FOREGROUND_RED|FOREGROUND_GREEN);
  return s;
}
struct color {
  color(WORD attribute):m_color(attribute){};
  WORD m_color;
};

#endif // _WIN32

// Abschnitt einer Konfigurationsdatei
struct absch
{
 string aname;
 vector<aScl> av;
 const string *const suche(const char* const sname);
 const string *const suche(const string& sname);
 void clear();
}; // class absch

struct paarcl
{
	string name;
	string wert;
	string bemerk;
	paarcl(const string& name, const string *const wertp, const string& bemerk);
}; // kpaar

// Konfigurationsdatei-Klasse, Nachfolger von confdat
struct confdcl 
{
	string fname; // Dateiname
	svec zn;
	vector<paarcl> paare;
	uchar obgelesen;
	uchar obzuschreib;
	uchar mitabsch{0};
	size_t richtige;
	vector<absch> abschv;
	confdcl(const string& fname, int obverb, const char tz='=');
	confdcl();
	int lies(const string& vfname, int obverb, const char tz='=');
	template <typename SCL> void kauswert(schAcl<SCL> *sA, int obverb=0,const uchar mitclear=1);
	void Abschn_auswert(int obverb=0, const char tz='=');
};

extern const char *logdt;

int kuerzelogdatei(const char* logdatei,int obverb);

// #define notwendig
#ifdef notwendig
void kopierm(const string *quelle, const string *ziel);
#endif // notwendig
void aufSplit(vector<string> *tokens, const char* const text, const char sep=' ',bool auchleer=1);
void aufSplit(vector<string> *tokens, const string& text, const char sep=' ',bool auchleer=1);
void aufiSplit(vector<string> *tokens, const string& text, const string& sep,bool nichtmehrfach=1,int obverb=0,int oblog=0,int ohneanfz=0);
void aufSplit(vector<string> *tokens, const string& text, const char* const sep, bool auchleer=1);
size_t irfind(const string& wo, const string& was); // suche von hinten und ignoriere Gross- und Kleinschreibung
void getstammext(const string *const ganz, string *stamm, string *exten);
// int cpplies(string fname,WPcl *conf,size_t csize,vector<string> *rest=0,char tz='=',short obverb=0);
string XOR(const string& value, const string& key);
int cppschreib(const string& fname, WPcl *conf, size_t csize);
// int multicppschreib(const string& fname, WPcl **conf, size_t *csizes, size_t cszahl);
template <typename SCL> int multischlschreib(const string& fname, schAcl<SCL> *const *const confs, const size_t cszahl,const string& mpfad=nix);
std::string base_name(const std::string& path); // Dateiname ohne Pfad
std::string dir_name(const std::string& path);  // Pfadname einer Datei
int systemrueck(const string& cmd, int obverb=0, int oblog=0, vector<string> *rueck=0, const uchar obsudc=0,
                const int verbergen=0, int obergebnisanzeig=wahr, const string& ueberschr=nix,vector<errmsgcl> *errm=0,uchar obincron=0,
								stringstream *ausgp=0,uchar obdirekt=0);
void pruefplatte();
void pruefmehrfach(const string& wen=nix,int obverb=0,uchar obstumm=0);
int setfaclggf(const string& datei,int obverb=0,int oblog=0,const binaer obunter=falsch,int mod=4,uchar obimmer=0,
                uchar faclbak=0,const string& user={},uchar fake=0,stringstream *ausgp=0,const uchar obprot=1);
int pruefverz(const string& verz,int obverb=0,int oblog=0, uchar obmitfacl=0, uchar obmitcon=0,
              const string& besitzer={}, const string& benutzer={}, const uchar obmachen=1,const uchar obprot=1);
string aktprogverz();
char Tippbuchst(const string& frage, const string& moegl,const char *berkl[], const char* erlaubt=0, const char *vorgabe=0);
// vorgabe fur vorgabe = T_j_k; alternativ='n'
uchar Tippob(const string& frage,const char *vorgabe=Txk[T_j_k]);
//string Tippstrs(const char *frage, char* moegl[], char *vorgabe=0); // das letzte Element von moegl muss 0 sein
string Tippstrs(const char *const frage, const char* const moegl[], const char *const vorgabe=0);// das letzte Element von moegl muss 0 sein
string Tippstrs(const char *frage, const vector<string> *const moegl, const string *const vorgabe=0);
string Tippzahl(const char *const frage, const char *const vorgabe=0);
string Tippzahl(const char *const frage, const string *const vorgabe);
string Tippzahl(const string& frage, const string *const vorgabe);
long Tippzahl(const string& frage,const long& vorgabe);
string Tippstr(const char *const frage, const string *const vorgabe=0,const uchar obnichtleer=1);
// char* Tippcstr(const char *frage, char* buf, unsigned long buflen, const char* vorgabe=nix);
string Tippstr(const string& frage, const string *const vorgabe=0,const uchar obnichtleer=1);
string Tippverz(const string& frage,const string *const vorgabe=0);
string Tippverz(const char *const frage,const string *const vorgabe=0);
uchar VerzeichnisGibts(const char* vname);
int tuloeschen(const string& zuloe,const string& cuser=nix,int obverb=0, int oblog=0,stringstream *ausgp=0);
int attrangleich(const string& zu, const string& gemaess,const string* const zeitvondtp=0, int obverb=0, int oblog=0);
int kopier(const string& quel, const string& ziel, int obverb=0, int oblog=0);
#ifdef falsch
#define obfstream
#ifdef obfstream
fstream*
#else // obfstream
FILE*
#endif // obfstream else
oeffne(const string& datei, uchar art, uchar* erfolg,uchar faclbak=1,int obverb=0, int oblog=0);
#endif // falsch

enum distroenum{unbek=-1,Mint,Ubuntu,Debian,Suse,Fedora,Fedoraalt,Mageia,Manjaro};
struct linst_cl
{
 instprog ipr=keinp; // installiertes Program
 string schau; // Befehl zum Pruefen auf Vorhandensein ueber das Installationssystem
 string instp; // Befehl zum Installieren ueber das Installationnssystem
 string instyp; // Befehl zum Installieren ueber das Installationnssystem mit automatischem yes auf Rueckfragen
 string upr;   // Befehl zum Deinstallieren ueber das Installationssystem
 string udpr;   // Befehl zum direkten Deinstallieren
 string uypr;   // Befehl zum Deinstallieren ueber das Installationssystem ohne Rueckfrage
 string upd;    // Befehl zum Systemupdate
 string repos; // Befehl zum Hinzufuegen des Repositories fuer den Compiler
 string compil; // Paketnamen fuer den Compiler
 string dev; // Anhaengsel fuer die development-Versionen ("-dev" oder "-devel")
 string libs; // alle lib-Verzeichnisse, fuer find ..
 string shpf; // Pfad zu sh
 string xargspf; // Pfad zu xargs
 string ionicepf; // Pfad zu ionice
 string nicepf; // Pfad zu nice
 string p3cpf; // Pfad zu python3-config

 linst_cl(int obverb=0, int oblog=0);
 uchar obnmr=1;
 string eprog; // ersetztes Programm
 const string ersetzeprog(const string& prog) const;
 void ziehraus(svec srueck, string* ustringp);
 int doinst(const string& prog,int obverb=0,int oblog=0,const string& fallsnichtda=nix,uchar ohneabh=0);// ,uchar obyes=1);
 int doggfinst(const string& prog,int obverb=0,int oblog=0,uchar ohneabh=0);
 int douninst(const string& prog,int obverb=0,int oblog=0,uchar obyes=1);
 int obfehlt(const string& prog,int obverb=0,int oblog=0);
}; // class linst_cl

// Service aus SystemD
class servc {
  public:
		string systemd; // Dienst-Datei
    int svfeh=-1; // Ausgangseinstellung
		int svf0=-1; // Einstellung nach erstem Ablauf von obsvfeh
		int obenabled=0;
	// svfeh=1: Dienst inexistent, 2: Dienst 'disabled' 3: Dienstdatei nicht ermittelbar, 4: Dienst laeuft noch, aber Dienstdatei inexistent
	// svfeh=5: Exe-Datei nicht ermittelbar, 6: Exe-Datei fehlt, 7: activating 8: Dienst kann gestartet werden, 9: Sonstiges
    int fehler=0; // Exit-Code der Exe-Datei
    string sname,ename; // Dienstname, Exename
    servc(const string& vsname,const string& vename): sname((vsname.empty()?vename:vsname)),ename(vename) {}
    servc(const string& vsname,const string& vename,int obverb, int oblog);
    // int obda(int obverb,int oblog);
		int startbar();
		int laeuft();
		int lief();
		int obsvfeh(int obverb=0,int oblog=0); // ob service einrichtungs fehler
		uchar spruef(const string& sbez,uchar obfork,const string& parent, const string& sexec, const string& CondPath, const string& After, 
                 int obverb=0,int oblog=0, uchar mitstarten=1);
    int restart(int obverb=0, int oblog=0);
    void start(int obverb=0, int oblog=0);
    int startundenable(int obverb=0, int oblog=0);
    void stop(int obverb=0,int oblog=0,uchar mitpkill=0);
		void stopggf(int obverb=0,int oblog=0,uchar mitpkill=0);
		void stopdis(int obverb=0,int oblog=0,uchar mitpkill=0);
    void pkill(int obverb=0,int oblog=0);
    int enableggf(int obverb=0,int oblog=0);
    int machfit(int obverb=0, int oblog=0, binaer nureinmal=falsch);
		void semodpruef(int obverb=0,int oblog=0);
		void semanpruef(int obverb=0,int oblog=0,const string& mod="getty_t");
		static void daemon_reload(int obverb=0, int oblog=0);
};

void printBits(size_t const size, void const * const ptr); // Binaerausgabe, fuer Debugging

#ifdef altfind
struct elem2
{
    string pfad;
    struct stat dst={0};
    int sterg;
    elem2(){};
    elem2(const string& mutter,const string& name);
    void init(const string& vmutter, const string& name);
    const bool operator<(const elem2& el) const;
}; // class elem2

class find2cl: elem2
{
  string typ;
  vector<string> stack;
  DIR *dir;
  struct dirent *dent;
  public:
  el2set *ergp=0;
  set<string> *vznp=0; 
  ull *nrp=0;
  int zuloeschen=1;
  int eingefuegt, verzneu;
	int obverb,oblog;
	find2cl(int _obverb=0, int _oblog=0, find2cl *stamm=0);
  ~find2cl();
  void weiszu();
  void init(const string& mutter, const string& name, regex_t *reg, const int folge,const long maxdepth, const int& typbit,
      vector<string> stack,time_t ab, time_t bis,int nurexec);
  void ausgeb();
  int finde(svec *wovp, const string& muster=nix,const long tiefe=-1,int typbit=B_Alle,int folge=Fol_Dat,
	          time_t ab=0, time_t bis=0,int obicase=0,int nurexec=0,int obnoext=0);
	void zuvec(svec *zu,uchar anteil=0);
};
#endif // altfind

#ifdef neufind
#include <ftw.h>
// Fundelement
struct elem3
{
    string pfad;
    const struct stat sb={0};
    int tflag;
    const struct FTW ftw={0};
    const string lnk;
    const struct stat lst={0};
    elem3(string pfad, const struct stat *sbp, int& tflag, const struct FTW *ftwp, string lnk,const struct stat& lst):
          pfad(pfad),sb(*sbp),tflag(tflag),ftw(*ftwp),lnk(lnk),lst(lst){}
    const bool operator<(const elem3& el) const;
};

// Wurzelelement
struct wele
{
    const string pfad;
    const long maxd;
    wele(const string& pfad=nix, const long& maxd=-1):pfad(pfad),maxd(maxd){}
    const bool operator<(const wele& el) const;
//    bool operator()(const wele& el3) const {return (this->pfad<el3.pf);}
}; // class wele

// nur eine Instanz der Klasse kann gleichzeitig gefuellt werden wegen der statischen Elemente
struct find3cl
{
    int flags = 0;
    long maxdepth=-1;
    static long *maxdepthp;
    int folge=0;
    static int *folgep;
    set<wele> wurz,fertige;
    set<elem3> erg;
    static set<wele>::iterator it;
    static set<wele> *wurzp;
    static set<elem3> *ergp;
    regex_t regs;
    static regex_t *regp;
    int typbit;
    static int *typbitp;
    time_t mab,mbis;
    static time_t *mabp,*mbisp;
		int obverb=0, oblog=0;
		static int *obverbp, *oblogp;
		int nurexec;
		static int *nurexecp;
		find3cl(int obverb=0,int oblog=0);
    static int verarbeit(const char *fpath, const struct stat *sb, int tflag, struct FTW *ftwbuf);
    int dofind();
    int ausgeb();
    int finde(svec *wovp,const string& muster=nix,long tiefe=-1,int _typbit=B_Alle,int _folge=Fol_Dat,
		           time_t _mab=0,time_t _mbis=0,int obicase=0,int nurexec=0,int obnoext=0);
		void zuvec(svec *zu,uchar anteil=0);
}; // class find3cl
#endif // neufind
#if defined(altfind) && defined(neufind)
void findfile(svec *qrueck,uchar findv,int obverb=0,int oblog=0,uchar anteil=0,
		const string& wo=".",const string& muster=nix,long tiefe=-1,int _typbit=B_Alle,int _folge=Fol_Dat, 
		time_t _mab=0,time_t _mbis=0,int obicase=0,int nurexec=0,int obnoext=0,uchar nureins=0);
#endif

struct pidcl
{
 pid_t pid;
 string name;
 pidcl(const pid_t pid,const string& name):pid(pid),name(name){}
}; // pidcl

//Vector von pid- und string-Pärchen
struct pidvec: public vector<pidcl>
{
 inline pidvec& operator<<(const pidcl& pd) {
	 this->push_back(pd);
	 return *this;
 } //  inline pidvec& operator<<(const pidcl& pd)
}; // pidvec

int wartaufpids(pidvec *pidv,const ulong runden=0,const int obverb=0,const int oblog=0,const string& wo=nix);

extern const string s_true; // ="true";
extern const string s_dampand; // =" && ";
extern const string s_gz; // ="gz";
extern const string& defvors; // ="https://github.com/"+gitv+"/";
extern const string& defnachs; // ="/archive/master.tar.gz";
void viadd(string *const cmdp,string* const zeigp,const string& datei,const uchar ro=0,const uchar hinten=0, const uchar unten=0);
int schluss(const int fnr,const string text={},int oblog=0);

extern class lsyscl lsys;

// Haupt-Klasse
class hcl
{
	private:
		uchar obsetz=1; // setzzaehler
		uchar mitpids=0; // mehrere pids
	protected:
		pidvec pidv;
		const char* const DPROG;
    double tstart, tende;
    size_t optslsz=0; // last opts.size()
		confdcl hccd;
		string tmpcron; // fuer crontab
    string cronminut; // Minuten fuer crontab; 0 = kein Crontab-Eintrag
		uchar nochkeincron;
		uchar cronzuplanen;
		uchar cmeingegeben=0; // cron-Minuten eingegeben
		uchar crongeprueft=0;
		static const string edit;
		static const string passwddt, groupdt, sudoersdt;
		static const char* const smbdt;// "/etc/samba/smb.conf"
		int autoupd=-1;  // 1=Programm automatisch updadaten
//		string tabl  //ω
//			;  //α
		string muser; // Benutzer fuer Mysql/MariaDB
		string mpwd;  // Passwort fuer Mysql/MariaDB //ω
		stringstream uebers; // Ueberschrift fuer Verarbeitungslauf
		const uchar mitcron; // ob Programm auch in Cron eingetragen werden kann; kann im Konstruktor angegeben werden
		unsigned tmmoelen;
#ifdef _WIN32
    char cpt[255];
    DWORD dcpt;
#elif linux // _WIN32
    char cpt[MAXHOSTNAMELEN]; 
    size_t cptlen;
#endif // _WIN32 else
	public:
		int retu{0}; // Return-Value
		int obverb=0; // verbose
		int oblog=0;  // mehr Protokollieren
    uchar rzf=0; // rueckzufragen
		uchar obvi=0; // ob Konfigurationsdatei editiert werden soll
		uchar obvs=0;   // ob Quelldateien bearbeitet werden sollen
		uchar keineverarbeitung=0; // wenn cronminuten geaendert werden sollen, vorher abkuerzen
    string langu; // Sprache (Anfangsbuchstabe)
    string logdname; // Logdatei-Name ohne Pfad <DPROG>.log
    string logvz; // nur das Verzeichnis /var/log
    string loggespfad; // Gesamtpfad, auf den dann die in kons.h verwiesene und oben definierte Variable logdt zeigt
                       // bei jeder Aenderung muss auch logdt neu gesetzt werden!
    string cmd; // string fuer command fuer Betriebssystembefehle
		schAcl<optcl> opn{schAcl<optcl>("opn")}; // Optionen
#ifdef alt
    vector<optioncl> opts;
#endif
		vector<argcl> argcmv; // class member vector
		ulong aufrufe=0; // Zahl der bisherigen Programmaufrufe
		struct tm laufrtag={0}; // Tag des letztes Aufrufs
		ulong tagesaufr=0; // Zahl der bisherigen Programmaufrufe heute
		ulong monatsaufr=0; // Zahl der bisherigen Programmaufrufe heute
    uchar oblgschreib=0; // Konfigurationsdatei seitens der Sprache voraussichtlich schreiben
    uchar logdneu=0;    // Logdatei geaendert
    uchar logvneu=0;    // Logverzeichnis geaendert
    uchar logdateineu=0; // logdt vorher loeschen
    uchar obhilfe=0;      // Hilfe anzeigen: 1=kurze Hilfe, 2=lange Hilfe, 3=Standardhilfe
    uchar zeigvers=0;  // Version anzeigen
		string cl; // comandline
    string mpfad;  // meinpfad()
    string meinname; // base_name(meinpfad()) // argv[0] // <DPROG>
    string akonfdt; // name der Konfigurationsdatei
//    schAcl<WPcl> agcnfA; // Gesamtkonfiguration
		string azaehlerdt; // akonfdt+".zaehl"
		schAcl<WPcl> zcnfA=schAcl<WPcl>("zcnfA"); // Zaehlkonfiguration
		string vorcm; // Vor-Cron-Minuten
		vector<string> benutzer; // Benutzer aus /etc/passwd, bearbeitet durch setzbenutzer(&user)
		uchar obsotiff=0; // 1 = tiff wird von der source verwendet
		stringstream erkl; // Erklärung für die Hilfe
		/*
		map<string,optcl*> omap; // map der Optionen
		map<string,optcl*> okmap; // map der Optionen, sortiert nach Tx[<kurzi>]
		map<string,optcl*> olmap; // map der Optionen, sortiert nach Tx[<langi>]
		map<string,optcl*>::iterator omit; // Optionen-Iterator
		*/
	private:
		void tucronschreib(const string& zsauf,const uchar cronzuplanen,const string& cbef);
		void dodovi(const svec d1,const svec d2);
	protected:
		void vischluss(string& erg,string& zeig);
		void holbefz0(const int argc, const char *const *const argv);
    virtual void virtlgnzuw(); // wird aufgerufen in: virtrueckfragen, parsecl, virtlieskonfein, hcl::hcl nach holsystemsprache
    int pruefinstv();
		void setzlog();

		void setztmpcron();

		virtual void virtVorgbAllg();
		virtual void pvirtVorgbSpeziell()=0;
		virtual void virtinitopt();
		void parsecl();
		virtual void pvirtmacherkl()=0;
    virtual void virtMusterVorgb();
    virtual void virtlieskonfein();
    void verarbeitkonf();
		int zeighilfe(const stringstream *const erkl);
		virtual void virttesterg()=0;
		virtual void pvirtvorzaehler()=0;
		void lieszaehlerein();
		void setzzaehler();
		void schreibzaehler();
		void dovi();
		virtual void virtzeigversion(const string& ltiffv=nix);
		virtual void pvirtvorrueckfragen()=0;
		virtual void virtrueckfragen();
		virtual void pvirtvorpruefggfmehrfach()=0;
		void pruefggfmehrfach();
		virtual void virtpruefweiteres();
		uchar pruefcron(const string& cm);
		virtual void virtzeigueberschrift();
    virtual void pvirtfuehraus()=0;
		virtual void virtautokonfschreib(); 
		void gitpull(const string& DPROG);
		virtual void virtschlussanzeige();
	public:
		void pruefcl(); // commandline mit omap und mit argcmv parsen
		hcl(const int argc, const char *const *const argv,const char* const DPROG,const uchar mitcron);
		~hcl();
		void lauf();
		int hLog(const string& text,const bool oberr=0,const short klobverb=0) const; 
		void pruefsamba(const vector<const string*>& vzn,const svec& abschni,const svec& suchs,const char* DPROG,const string& cuser);
		int holvomnetz(const string& datei,const string& vors=defvors,const string& nachs=defnachs);
		int kompilbase(const string& was,const string& endg);
		int kompiliere(const string& was,const string& endg,const string& vorcfg=nix,const string& cfgbismake=s_dampand);
		int kompilfort(const string& was,const string& vorcfg=nix,const string& cfgbismake=s_dampand,uchar ohneconf=0);
		double progvers(const string& prog,string* ergptr=0);
		void prueftif(string aktvers);
		void zeigkonf();
		void reduzierlibtiff();
		void setzbenutzer(string *const user);
}; // class hcl
/*
// sollte dann unnötig werden
template<typename SCL> void schAcl<SCL>::initv(vector<optcl*> optpv,vector<size_t> optsv)
{
	schl.clear();
	vector<optcl*>::iterator opp=optpv.begin();
	vector<size_t>::iterator ops=optsv.begin();
	for(;opp!=optpv.end();opp++,ops++) {
		for(size_t iru=0;iru<*ops;iru++) {
			optcl *op=&((optcl*)(*opp))[iru];
			if (!op->pname.empty()) {
				uchar gefunden=0;
				for(vector<WPcl>::iterator sit=schl.begin();sit!=schl.end();sit++) {
					if (sit->pname==op->pname) {
						gefunden=1;
						break;
					}
				}
				if (!gefunden) {
					const string wert=op->art==plong?ltoan(*(long*)op->pptr):
						                op->art==pint?ltoan(*(int*)op->pptr):
													  op->art==puchar?ltoan(*(uchar*)op->pptr):
														                       *(string*)op->pptr;
					schl.push_back(WPcl(op->pname,wert));
				}
			}
		}
	}
} // void schAcl::initv(vector<optcl*> optpv,vector<size_t> optsv)
*/

#endif // kons_H_DRIN
