#ifdef _MSC_VER
#define _CRT_SECURE_NO_WARNINGS
#endif // _MSC_VER
//#pragma once
// Visual c++:
// Project->Properties->C++->general->additional include directories
// C:\Programme\MySQL\Connector C 6.0.2\include
// mingw: 
// -I"C:\Programme\MySQL\Connector C 6.0.2\include"
#ifndef DB_H_DRIN
#define DB_H_DRIN
// #include <vector>
// #include <string>
// #include <iostream> // fuer cout ggf.
#include <sstream> // stringstream, basic_stringstream
// Project->Properties->C/C++ ->General->Additional Include Directories->"$(ProjectDir)\..\..\..\MySQL Connector C 6.0.2\include"
#include <mysql.h> 
// (sudo) dnf install postgresql-devel
//#define mitpostgres
#ifdef mitpostgres 
#include <libpq-fe.h> // PGconn
#endif // mitpostgres
// G.Schade 26.1.14: Den Rest aus der Datei braucht man scheinbar nicht; sonst Konflikt mit bitset unter -std=gnu++11
#ifndef HAVE_UCHAR
typedef unsigned char	uchar;	/* Short for unsigned char */
#endif
// #include "/usr/include/mysql/my_global.h"
// #include <my_global.h> 
using namespace std;
// #ifdef linux
// #include <string.h>
// #endif // linux
// Project->Properties->Linker->general->(mitte)->additional library directories:
// C:\Programme\MySQL\Connector C 6.0.2\lib\opt
// weiterhin: libmysql.dll ins Verzeichnis der Exe stellen
// #ifdef _MSC_VER
//#pragma comment(lib, "libmysql.lib")
// #endif // MSC_VER
extern class cuscl cus;
const char *cjj(const char * const* const* cerg, const int nr);

enum Txdb_ 
{
  T_DB_wird_initialisiert,
  T_Fehler_db,
  T_beim_Initialisieren_von_MySQL,
  T_Fehler_dp,
  T_bei_Befehl,
  T_Versuche_mysql_zu_starten,
  T_MySQL_erfolgreich_gestartet,
  T_Versuche_Datenbank,
  T_zu_erstellen,
  T_Fehler_beim_Verbinden,
  T_Erfolg_beim_Initialisieren_der_Verbindung_zu_mysql,
	T_MySQL_Passwort,
	T_wird_benoetigt_fuer_Befehl,
  T_ist_leer_Wollen_Sie_eines_festlegen,
  T_j,
  T_Bitte_geben_Sie_ein_MySQL_Passwort_fuer_Benutzer_root_ein,
  T_Fuehre_aus_db,
  T_falsche_Fehlernr,
  T_bei_der_Abfrage_der_Spaltenlaenge_bei_Tabelle,
  T_und_Feld,
  T_mit,
  T_bei_Abfrage,
  T_Fehler_beim_Pruefen_auf_Vorhandensein_des_Datensatzes,
  T_Datenbank_nicht_zu_oeffnen,
  T_Erweitere_Feld,
  T_von,
  T_auf,
  T_Aendere_Feld,
  T_Pruefe_Tabelle,
  T_Lesespalten,
	T_Vor_restart,
	T_Versuch_Nr,
	T_bei_sql_Befehl,
	T_PostgreSQL_musste_neu_eingerichtet_werden,
	T_Bitte_geben_Sie_ein_Passwort_fuer_Benutzer_postgres_ein,
	T_Welches_Passwort_soll_der_Benutzer_postgres_haben,
	T_Ende_Gelaende,
	T_Verbindung_zu,
	T_gelungen,
	T_prueffunc,
	T_Datenbankbenutzer_leer,
	T_host_k,
	T_host_l,
	T_muser_k,
	T_muser_l,
	T_mpwd_k,
	T_mpwd_l,
	T_db_k,
	T_datenbank_l,
	T_tb_k,
	T_tabelle_l,
	T_Bildschirmausgabe_mit_SQL_Befehlen,
	T_verwendet_die_Datenbank_auf_Host_string_anstatt_auf,
	T_verwendet_fuer_MySQL_MariaDB_den_Benutzer_string_anstatt,
	T_verwendet_fuer_MySQL_MariaDB_das_Passwort_string,
	T_verwendet_die_Datenbank_string_anstatt,
	T_verwendet_die_Tabelle_string_anstatt,
	T_sqlv_k,
	T_sql_verbose_l,
	T_Verbindung_zur_Datenbank_nicht_herstellbar,
	T_Breche_ab,
	T_pruefDB,
	T_Host_fuer_MySQL_MariaDB_Datenbank,
	T_Benutzer_fuer_MySQL_MariaDB,
	T_Passwort_fuer_MySQL_MariaDB,
	T_Datenbankname_fuer_MySQL_MariaDB_auf,
	T_Tabellenname_in,
	T_Referenz,
	T_auf_Tabelle,
	T_nicht_erstellt_da_Referenztabelle,
	T_Fehler_af,
	T_erstelle_Tabelle,
	T_Zeige,
	T_an_Position,
	T_Feld,
	T_Wertma,
	T_Tabelle,
	T_Versuche_in_doAbfrage_mehr_als,
	T_dbMAX,
}; // enum Txdb_ 

// extern class Txdbcl Txd;
extern const char *DB_T[T_dbMAX+1][SprachZahl];
extern class TxB Txd;
/*//
class Txdbcl: public TxB
{
  public:
    static const char *TextC[][SprachZahl];
    Txdbcl();
};
*/
svec holdbaussql(string sql);

enum DBSTyp {MySQL, Postgres};
extern const DBSTyp myDBS;

class sqlft: public string 
{
  private:
    ////	char dbuf[21];
    string *ersetze(const char* const alt, const char* const neu);
    string *sersetze( string *const src, string const& target, string const& repl);
		void ersetzalles();
    void druckeein(DBSTyp eDBS, tm *const zt);
  public:
    ////	string feld;
    sqlft(DBSTyp eDBS, const string& vwert);
    sqlft(DBSTyp eDBS, const string* const vwert);
    sqlft(DBSTyp eDBS, const char* const vwert,const char* const zs);
    sqlft(DBSTyp eDBS, const char* const vwert,const bool obzahl=0);
    sqlft(DBSTyp eDBS, const time_t *zt);
    sqlft(DBSTyp eDBS, tm *const zt);
    sqlft(DBSTyp eDBS, const char c);
    sqlft(DBSTyp eDBS, const uchar c);
    sqlft(DBSTyp eDBS, const int i);
    sqlft(DBSTyp eDBS, const long int i);
    sqlft(DBSTyp eDBS, const unsigned int i);
    sqlft(DBSTyp eDBS, const unsigned long int i);
    sqlft(DBSTyp eDBS, const long long int i);
    sqlft(DBSTyp eDBS, const chrono::system_clock::time_point* const tp);
}; // class sqlft: public string 


template<typename T, size_t N> T * end(T (&ra)[N]) 
{
  return ra + N;
} // template<typename T, size_t N> T * end(T (&ra)[N]) 

class instyp 
{
 public:
    const string feld;
    string wert;
    uchar obkeinwert; // bei update wird <wert> nicht als Wert, sondern ohne Anf'z.(z.B.als Feld) verwendet (z.B. update xy set altdatum = datum)
  private:
    ////	char dbuf[21];
    inline string ersetze(const char *const u, const char* const alt, const char* const neu);
    inline string *sersetze( string *const src, string const& target, string const& repl);
  public:
    /*1*/template <typename tC> explicit instyp (DBSTyp eDBS, const char* const feld, tC vwert): feld(feld) {
      wert=sqlft(eDBS,vwert);
      obkeinwert=0;
    }
////    void init(){feld=string();wert=string();obkeinwert=0;}

    /*3*/instyp(DBSTyp eDBS, const char* const feld, const char *const vwert):feld(feld) {
      wert=sqlft(eDBS,vwert,false);
      obkeinwert=0;
    }
    /*4*/instyp(DBSTyp eDBS, const char* const feld, const char *const vwert,const char* const zs):feld(feld) {
      wert=sqlft(eDBS,vwert,zs);
      obkeinwert=0;
    }
    /*5*/instyp(DBSTyp eDBS, const char* const feld, const char *const vwert,const bool obzahl):feld(feld) {
      wert=sqlft(eDBS,vwert,obzahl);
      obkeinwert=0;
    }
    /*6*/instyp(DBSTyp eDBS, const char* const feld, const char *const vwert,const uchar vobkeinwert):feld(feld) {
      wert=vwert;
      obkeinwert=vobkeinwert;
    }
    /*7*/instyp(DBSTyp eDBS, const char* const feld,const string& vwert):feld(feld) {
      wert=sqlft(eDBS,vwert);
      obkeinwert=0;
    }
		void ausgeb();
}; // class instyp 
////string ersetze(const char *u, const char* alt, const char* neu);

// delimiter value begin
inline const char dvb(DBSTyp DBS)
{
  switch(DBS) {
    case MySQL: return '\'';
    case Postgres: return '\"';
    default: return '"';
  }
} // inline char dvb(DBSTyp DBS) 

// delimiter value end
inline const char dve(DBSTyp DBS)
{
  switch(DBS) {
    case MySQL: return '\'';
    case Postgres: return '\"';
    default: return '"';
  }
} // inline char dve(DBSTyp DBS) 


// delimiter name begin
inline const char dnb(DBSTyp DBS)
{
  switch(DBS) {
    case MySQL: return '`';
    case Postgres: return '\"';
    default: return '"';
  }
} // inline char dnb(DBSTyp DBS)

// delimiter name end
inline const char dne(DBSTyp DBS)
{
  switch(DBS) {
    case MySQL: return '`';
    case Postgres: return '\"';
    default: return '"';
  } //   switch(DBS)
} // inline char dne(DBSTyp DBS) 

struct Feld 
{
    const string name;
    const string typ;
    string lenge;
    const string prec;
    string comment;
    bool obind;
    bool obauto;
    bool nnull;
    string defa;
		bool unsig;
		Feld();
    Feld(const string& name, string typ=string(), const string& lenge=string(), const string& prec=string(), 
         const string& comment=string(), bool obind=0, bool obauto=0, bool nnull=0, const string& defa=string(), bool unsig=0);
//		Feld(Feld const& copy);
		// um im Konstruktor von Tabelle aus einem Feld-vector ein Feld-Array machen zu koennen
		Feld& operator=(const Feld *fur) {
			if (fur!=this) {
				string *np=(string*)&name; *np=fur->name;
				np=(string*)&typ;*np=fur->typ;
				lenge=fur->lenge;
				np=(string*)&prec;*np=fur->prec;
				comment=fur->comment;
				obind=fur->obind;
				obauto=fur->obauto;
				nnull=fur->nnull;
				defa=fur->defa;
				unsig=fur->unsig;
			}
			return *this;
		}
}; // struct Feld 

struct sfeld: vector<Feld*>
{
	inline void operator<<(Feld *fdp) {
		this->push_back(fdp);
//		return *this;
	}
}; // class svec: public vector<std::string>

struct Index 
{
	const string name;
    Feld *const felder;
    const unsigned feldzahl;
		uchar unique;
    Index(const string& vname, Feld *const vfelder, const unsigned vfeldzahl, const uchar unique=0);
}; // struct Index 

enum refact:uchar {cascade,set_null,restrict_,no_action,set_default};


struct Constraint
{
	const string name;
	Feld *const felder1;
	const unsigned feldz1;
	const string reftab;
	Feld *const felder2;
	const unsigned feldz2;
	const refact onupdate;
	const refact ondelete;
	Constraint(const string& name, Feld *const felder1, const unsigned feldz1, const string& reftab, 
			Feld *const felder2, const unsigned feldz2, const refact onupdate=restrict_, const refact ondelete=restrict_);
};

class RS;


class DB 
{
  public:
    // muss außerhalb der Klasse und einer Funktion noch mal definiert werden
    static uchar oisok; // 1=Installation von MariaDB wurde ueberprueft
    string db_systemctl_name; // mysql, mariadb je nach System
    servc *dbsv=0;
    MYSQL **conn;
		static const string defmyengine;
		static const string defmycharset;
		static const string defmycollat;
		static const string defmyrowform;
#ifdef mitpostgres 
		PGconn *pconn,*pmconn;
#endif // mitpostgres
    const DBSTyp DBS;
    char dnb; // delimiter name begin
    char dne; // delimiter name end
    char dvb; // delimiter value begin
    char dve; // delimiter value end
    ////	char* ConStr;
    ////  const char* db;
    const string mysqlbef="mysql", mysqlben="mysql"; // mysql-Befehl, mysql-Benutzer
    ////  const char* host;
    const string host;
    ////  const char* user;
		const string charset;
		const string collate;
    const string user;
    string passwd; // kann in pruefrpw dem eingegebenen rootpw gleichgesetz werden, deshalb nicht const
    const string dbname;
    string myloghost; // einheitliche Benennung von 'localhost' bzw. '%', zu kompliziert, um in jedem DB::DB aufzufuehren, deshalb nicht const
    string rootpwd; // root-Passwort // wird in pruefrpw geaendert, deshalb nicht const
		size_t conz; // Zahl der Verbindungen (s.o., conn)
    unsigned int fehnr;
    const char* ConnError;
    uchar miterror;
    vector<string> myr;
    string cmd;
    string datadir;
		uchar lassoffen=0;
	private:
		void instmaria(int obverb, int oblog);
	public:
		int usedb(const string& db,const size_t aktc/*=0*/);
		void pruefrpw(const string& wofuer, unsigned versuchzahl);
		void setzrpw(int obverb=0, int oblog=0);
		void prueffunc(const string& pname, const string& body, const string& para, const size_t aktc, int obverb, int oblog);
		vector< vector<instyp> > ins;
		void erweitern(const string& tab, vector<instyp> einf,const size_t aktc,int obverb,uchar obsammeln=0, const unsigned long *maxl=0) const;
		uchar tuerweitern(const string& tab, const string& feld,long wlength,const size_t aktc,int obverb) const;
    int machbinaer(const string& tabs, const size_t aktc, const string& fmeld,int obverb) const;
    ////	DB(DBSTyp DBS, const char* host, const char* user,const char* passwd, const char* db, unsigned int port, const char *unix_socket, unsigned long client_flag);
		///*1*/DB();
		/*2*/DB(const DBSTyp nDBS,const char* const phost, const char* const user,const char* const ppasswd, 
				const size_t conz/*=1*/, const char* const uedb="", unsigned int port=0, const char *const unix_socket=NULL, unsigned long client_flag=0,
			 int obverb=0,int oblog=0,const string charset=defmycharset, const string collate=defmycollat, int versuchzahl=3,const uchar ggferstellen=1);
    /*3*/DB(const DBSTyp nDBS, const char* const phost, const char* const user, const char* const ppasswd,
		   const char* const prootpwd, const size_t conz/*=1*/, const char* const uedb="", unsigned int port=0, const char *const unix_socket=NULL, 
			 unsigned long client_flag=0, int obverb=0,int oblog=0,const string charset=defmycharset, const string collate=defmycollat, int versuchzahl=3, 
			 const uchar ggferstellen=1);
    /*4*/DB(const DBSTyp nDBS,const string& phost, const string& puser, const string& ppasswd, 
		const size_t conz/*=1*/, 
		   const string& uedb=string(), unsigned int port=0, const char* const unix_socket=NULL, unsigned long client_flag=0,
       int obverb=0,int oblog=0,const string charset=defmycharset, const string collate=defmycollat, int versuchzahl=3,const uchar ggferstellen=1);
    void init(const string charset, const string collate,
				unsigned int port=0, const char *const unix_socket=NULL, unsigned long client_flag=0,int obverb=0,int oblog=0,unsigned versuchzahl=3,
				const uchar ggferstellen=1);
    ~DB(void);
    /*//
       int Abfrage(const char* sql,const char** erg=(const char**)&"", int obverb=1);
       int Abfrage(string sql,const char** erg=(const char**)&"", int obverb=1);
       int AbfragemE(const char* sql,const char** erg=(const char**)&"", int obverb=1); // mit Ende
       int AbfragemE(string sql,const char** erg=(const char**)&"", int obverb=1);      // mit Ende
     */
    ////	int insert(const char* tab, vector<instyp> einf, const char** erg=(const char**)&"",uchar sammeln=0);
    ////	void AbfrageEnde();
    void LetzteID(string* erg,const size_t aktc);
    char* tmtosql(tm *tmh,char* buf);
    char* tmtosqlmZ(tm *tmh,char* buf);
    ////	char** HolZeile();
    my_ulonglong affrows(const size_t aktc) const; // unsigned __int64
		uchar obtabspda(const char* const tab,const char* const sp);
}; // class DB 

struct Tabelle 
{
	const DB* dbp;
	const string tbname;
	string comment; // wird geaendert
	const string dbname;
	uchar spaltfehler=0;
	unsigned long long  spzahl=0; // spalt->num_rows
//	const char **spnamen=nullptr, **splenge=nullptr, **sptyp=nullptr;
	svec spnamen,splenge,sptyp;
	Feld *felder;
	unsigned feldzahl;
	Index *indices;
	unsigned indexzahl;
	Constraint *constraints;
	unsigned constrzahl;
	const string engine;
	const string charset;
	const string collate;
	const string rowformat;
	uchar tbneu=0; // Tabelle wurde auf der Datenbank neu erstellt
	Tabelle(const DB* dbp,const string& tbname, Feld *felder, const int feldzahl, Index *const indices=0, const unsigned vindexzahl=0, 
			Constraint *const constraints=0, const unsigned constrzahl=0,
			const string comment=string(), const string& engine=DB::defmyengine, const string& charset=DB::defmycharset, const string& collate=DB::defmycollat, 
			const string& rowformat=DB::defmyrowform);
	Tabelle(const DB* dbp,const string& tbname, sfeld& fdr, Index *const indices=0, const unsigned vindexzahl=0, 
			Constraint *const constraints=0, const unsigned constrzahl=0,
			const string comment=string(), const string& engine=DB::defmyengine, const string& charset=DB::defmycharset, const string& collate=DB::defmycollat, 
			const string& rowformat=DB::defmyrowform);
	Tabelle(const DB* dbp,const string& name,const size_t aktc=0,int obverb=0,int oblog=0);
	void lesespalten(const size_t aktc=0,int obverb=0,int oblog=0);
	void zeigspalten(int obverb=0, int oblog=0);
	void tuzeigspalte(size_t spnr,int obverb=0, int oblog=0);
	int machind(const size_t aktc,int obverb=0, int oblog=0);
	int machconstr(const size_t aktc,int obverb=0, int oblog=0);
	int prueftab(const size_t aktc,int obverb=0,int oblog=0);
}; // class Tabelle 



class RS 
{
	private:
		unsigned long zaehler{0}; // Zahl der ueber tbins tatsaechlich einzufuegenden Datensaetze 
		uchar dochanfangen{0}; // => bei Erreichen von maxzaehler in der naechsten Runde neu anfangen
		unsigned long *maxl{0}; // fuer Feldlaengenkorrekturen 
	public:
		const DB* const dbp;
		const size_t aktc;
    string sql;
    string isql; // insert-sql
    uchar obqueryfehler; // -1=initial, 1= mysql_send_query oder mysql_real_query ergab Fehler, 0=keinen
    string fehler;
		string autofeld;
		char **betroffen=0; // fuer Abfrage in postgres
    unsigned int fnr;
    MYSQL_RES *result=0; // fuer RS::~RS am 4.9.18 noetig
		uchar resultused{0};
#ifdef mitpostgres 
		PGresult *pres;
#endif // mitpostgres
		unsigned long *lengths;
    MYSQL_ROW row;
    unsigned int num_fields;
    unsigned long long  num_rows;
    unsigned long long  geaendert; // fuer INSERT, UPDATE und DELETE ueber doAbfrage
    const string table;
    vector<string> feld;
    vector<string> typ;
    vector<long> lenge;
    vector<long> prec;
    vector<string> kommentar;
    char*** HolZeile();
    void setzzruck();
    void dsclear();
    template<typename sT> 
      int Abfrage(sT psql,const size_t aktc/*=0*/,int obverb=0,uchar asy=0,int oblog=0,string *idp=0,my_ulonglong *arowsp=0){
        int erg=-1;
        this->sql=psql;
        if (!sql.empty()) {
          erg = doAbfrage(aktc,obverb,asy,oblog,idp,arowsp);
        } //         if (!sql.empty())
        return erg;
      } //       int Abfrage(sT psql,int obverb=1,uchar asy=0)

    RS(const DB* const pdb,const string& table);
    RS(const DB* const pdb,const char* const psql, const size_t aktc, int obverb/*=1*/,uchar asy=0,int oblog=0,string* idp=0,my_ulonglong *arowsp=0);
    RS(const DB* const pdb,const string& psql, const size_t aktc, int obverb/*=1*/,uchar asy=0,int oblog=0,string* idp=0,my_ulonglong *arowsp=0);
    RS(const DB* const pdb,stringstream psqls, const size_t aktc, int obverb/*=1*/,uchar asy=0,int oblog=0,string* idp=0,my_ulonglong *arowsp=0);
    ~RS();
		uchar holautofeld(const size_t aktc, int obverb);
    my_ulonglong tbupd(const vector<instyp>& einf,int obverb, const string& bedingung, const size_t aktc/*=0*/, uchar asy=0);
    my_ulonglong tbins(vector<instyp>* einfp,const size_t aktc=0,uchar sammeln=0,int obverb=0,string *const id=0,
		     const uchar eindeutig=0,const svec& eindfeld=svec(),const uchar asy=0, svec *csets=0, uchar mitupd=0);
		void machstrikt(string& altmode,const size_t aktc=0);
		void striktzurueck(string& altmode,const size_t aktc=0);
  private:
    int doAbfrage(const size_t aktc/*=0*/,int obverb/*=0*/,uchar asy/*=0*/,int oblog/*=0*/,string *idp/*=0*/,my_ulonglong *arowsp/*=0*/);
		void abfragefertig();
}; // class RS

struct insv
{
	vector<instyp> ivec; // fuer alle Datenbankeinfuegungen
	RS *rsp;
	DB* My=0;
	const string* const itabp;
	const size_t aktc;
	const uchar eindeutig;
	const svec& eindfeld;
	const uchar asy;
	svec *csets;
	inline size_t size(){return ivec.size();}
	//	my_ulonglong RS::tbins(vector<instyp>* einfp,const size_t aktc/*=0*/,uchar sammeln/*=0*/, int obverb/*=0*/,string *idp/*=0*/,const uchar eindeutig/*=0*/,const svec& eindfeld/*=nix*/,const uchar asy/*=0*/,svec *csets/*=0*/) 
	insv(DB *My,const string& itab,const size_t aktc,const uchar eindeutig,const svec& eindfeld,const uchar asy,svec *csets);
	my_ulonglong schreib(const uchar sammeln=0,int obverb=0,string* const idp=0,uchar mitupd=0);
	my_ulonglong ergaenz(const string& bedingung,const uchar sammeln=0,int obverb=0,string* const idp=0);
	void hzp(const instyp it);
	void hz(const instyp it);
	void clear();
	template<typename sT> void hzp(const char* const feld, sT vwert)
	{
		instyp it(My->DBS,feld,vwert);
		hzp(it);
	}
	template<typename sT> void hz(const char* const feld, sT vwert)
	{
		instyp inst(My->DBS,feld,vwert);
		hz(inst);
	}
	inline insv& operator<<(const instyp it) {
		this->hz(it);
		return *this;
	}
	void zeig(const char* const wo);
	void ausgeb();
};

#endif // DB_H_DRIN

class dhcl:public hcl
{
	private:
	protected:
		string host;  // fuer MySQL/MariaDB
		string dbq; // Datenbank
	public:
		uchar ZDB{0}; // fuer Zusatz-Debugging (SQL): ZDB 1, sonst: 0
		DB* My{0};
		const size_t maxconz{12};//aktc: 0=... //α
	private:
	protected:
		void virtlgnzuw(); // wird aufgerufen in: virtrueckfragen, parsecl, virtlieskonfein, hcl::hcl nach holsystemsprache
		void virtVorgbAllg();
		void pvirtVorgbSpeziell();
		void virtinitopt(); // (programm-)spezifische Optionen
		//		void pvirtmacherkl();
		void virtMusterVorgb();
		void virtzeigversion(const string& ltiffv=nix);
		//	void pvirtvorrueckfragen();
		void virtrueckfragen();
		//	void virtpruefweiteres();
		//	void virtzeigueberschrift();
		//  void pvirtfuehraus();
		void virtschlussanzeige();
	public:
		dhcl(const int argc, const char *const *const argv,const char* const DPROG,const uchar mitcron);
		~dhcl();
		int  initDB();
		int  pruefDB(const string& db);
#ifdef VOMHAUPTCODE
		__attribute__((weak)) // implementationsspezifische Vorgaben, Modul vgb.cpp)
#endif
			;

}; // class hhcl //ω
