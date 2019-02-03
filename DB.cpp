#include "kons.h"
#include "DB.h"
#define caus cout // nur zum Debuggen
#define caup cout // zum Debuggen von Postgres
#define exitp exit // zum Debuggen von Postgres

//const char *Txdbcl::TextC[T_dbMAX+1][SprachZahl]={
const char *DB_T[T_dbMAX+1][SprachZahl]={
  // T_DB_wird_initialisiert
  {"DB wird initialisiert","DB is being initialized"},
  // T_Fehler_db
  {"Fehler ","Error "},
  // T_beim_Initialisieren_von_MySQL
  {" beim Initialisieren von MySQL: "," initializing MySQL: "},
  // T_Fehler_dp
  {"Fehler: ","Error: "},
  // T_bei_Befehl
  {" bei Befehl: "," at command: "},
  // T_Versuche_mysql_zu_starten
  {": => Versuche mysql zu starten ...",": => trying to start mysql ..."},
  // T_MySQL_erfolgreich_gestartet
  {"MySQL erfolgreich gestartet.","Started MySQL successfully."},
  // ": => Versuche Datenbank `"
  {": => Versuche Datenbank `",": => Trying to install database `"},
  // T_zu_erstellen
  {"` zu erstellen ...","` ..."},
  // T_Fehler_beim_Verbinden
  {"Fehler beim Verbinden: ","Error connecting: "},
  // T_Erfolg_beim_Initialisieren_der_Verbindung_zu_mysql
  {"Erfolg beim Initialisieren der Verbindung zu MySQL, aktc: ","Success initializing the connection to MySQL, aktc: "},
	// T_MySQL_Passwort
	{"MySQL-Passwort","MySQL password"},
	// T_wird_benoetigt_fuer_Befehl
	{"' (wird benoetigt fuer Befehl: ","' (is needed for command: "},
  // T_ist_leer_Wollen_Sie_eines_festlegen
  {"' ist leer. Wollen Sie eines festlegen?", "' is empty. Do You want to give one?"},
  // T_j
  {"j","y"},
  // T_Bitte_geben_Sie_ein_MySQL_Passwort_fuer_Benutzer_root_ein
  {"Bitte geben Sie ein MySQL-Passwort fuer Benutzer 'root' ein: ","Please indicate a mysql password for user 'root': "},
  // T_Fuehre_aus_db
  {"Fuehre aus: ","Executing: "},
  // T_falsche_Fehlernr
  {"falsche Fehlernr ","wrong Errorno "},
  // T_bei_der_Abfrage_der_Spaltenlaenge_bei_Tabelle
  {" bei der Abfrage der Spaltenlaenge bei Tabelle: "," during query of the column width at table: "},
  // T_und_Feld,
  {" und Feld: "," and field: "},
  // T_mit
  {" mit: "," with: "},
  // T_bei_Abfrage
  {" bei Abfrage: "," in query: "},
  // T_Fehler_beim_Pruefen_auf_Vorhandensein_des_Datensatzes
  {"Fehler beim Pruefen auf Vorhandensein des Datensatzes: ","Error while checking the existence of entry: "},
  // T_Datenbank_nicht_zu_oeffnen
  {"Datenbank nicht zu oeffnen","could not open database"},
  // T_Erweitere_Feld
  {"Erweitere Feld: ","Enlarging field: "},
  // T_von
  {" von: "," from: "},
  // T_auf
  {" auf: "," to: "},
  // T_Aendere_Feld
  {"Aendere Feld: ","Changing field: "},
  // T_Pruefe_Tabelle
  {"Pruefe Tabelle: '","Checking table: '"},
  // T_Lesespalten
  {"lesespalten()","readcolumns()"},
	// T_Vor_restart
	{"Vor restart, ","Before restart, "},
	// T_Versuch_Nr
	{"Versuch Nr. ","try no. "},
	// T_bei_sql_Befehl
	{" bei sql-Befehl: "," at sql-command: "},
	// T_PostgreSQL_musste_neu_eingerichtet_werden
	{"PostgreSQL musste neu eingerichtet werden. ",
	 "Postgresql had to be installed newly. "},
	// T_Bitte_geben_Sie_ein_Passwort_fuer_Benutzer_postgres_ein
	{"Bitte geben Sie das Passwort fuer Benutzer `postgres` ein",
	 "Please enter the password for user `postgres`"},
	// T_Welches_Passwort_soll_der_Benutzer_postgres_haben
	{"Welches Passwort soll der Benutzer `postgres` haben",
   "Which password shall the user `postgres` have"},
	// T_Ende_Gelaende
	{"Ende Gelaende!","That's it!"},
	// T_Verbindung_zu
	{"Verbindung zu '","Connection to '"},
	// T_gelungen
	{"' gelungen, user '","' succeeded, user '"},
	// T_prueffunc
	{"prueffunc()","checkfunc()"},
	// T_Datenbankbenutzer_leer
	{"Datenbankbenutzer leer!","database user empty!"},
	// T_host_k
	{"host","host"},
	// T_host_l
	{"host","host"},
	// T_muser_k
	{"muser","muser"},
	// T_muser_l
	{"muser","muser"},
	// T_mpwd_k
	{"mpwd","mpwd"},
	// T_mpwd_l
	{"mpwd","mpwd"},
	// T_db_k
	{"db","db"},
	// T_datenbank_l
	{"datenbank","database"},
	// T_tb_k,
	{"tb","tb"},
	// T_tabelle_l,
	{"tabelle","table"},
	// T_Bildschirmausgabe_mit_SQL_Befehlen
	{"Bildschirmausgabe mit SQL-Befehlen","screen output with SQL commands"},
	// T_verwendet_die_Datenbank_auf_Host_string_anstatt_auf
	{"verwendet die Datenbank auf Host <string> anstatt auf","takes the database on host <string> instead of"},
	// T_verwendet_fuer_MySQL_MariaDB_den_Benutzer_string_anstatt
	{"verwendet fuer MySQL/MariaDB den Benutzer <string> anstatt","takes the user <string> for MySQL/MariaDB instead of"},
	// T_verwendet_fuer_MySQL_MariaDB_das_Passwort_string
	{"verwendet fuer MySQL/MariaDB das Passwort <string>","takes the password <string> for MySQL/MariaDB"},
	// T_verwendet_die_Datenbank_string_anstatt
	{"verwendet die Datenbank <string> anstatt","uses the database <string> instead of"},
	// T_verwendet_die_Tabelle_string_anstatt
	{"verwendet die Tabelle <string> anstatt","uses the table <string> instead of"},
	// T_sqlv_k
	{"sqlw","sqlv"},
	// T_sql_verbose_l
	{"sql-wortreich","sql-verbose"},
	// T_Verbindung_zur_Datenbank_nicht_herstellbar
	{"Verbindung zur Datenbank nicht herstellbar, fehnr: ","Connection to the database could not be established, errnr: "},
	// T_Breche_ab
	{". Breche ab.","Stopping."},
	// T_pruefDB
	{"pruefDB(","checkDB("},
	// T_Host_fuer_MySQL_MariaDB_Datenbank
	{"Host fuer MySQL/MariaDB-Datenbank","host for mysql/mariadb-database"},
	// T_Benutzer_fuer_MySQL_MariaDB,
	{"Benutzer fuer MySQL/MariaDB:","user for mysql/mariadb:"},
	// T_Passwort_fuer_MySQL_MariaDB,
	{"Passwort fuer MySQL/MariaDB (Achtung: nur schwach verschluesselt!)","password for mysql/mariadb (caution: only weakly encrypted!)"},
	// T_Datenbankname_fuer_MySQL_MariaDB_auf
	{"Datenbankname fuer MySQL/MariaDB auf '","database name for mysql/mariabd on '"},
	// T_Tabellenname_in
	{"Tabellenname in '","table name in '"},
	// T_Referenz
	{"Fremdschluessel `","Constraint `"},
	// T_auf_Tabelle
	{"` auf Tabelle `","` on table `"},
	// T_nicht_erstellt_da_Tabelle
	// T_nicht_erstellt_da_Referenztabelle
	{"` nicht erstellt, da Referenztabelle `","` not created, because referenced table `"},
	// T_Fehler_af,
	{"Fehler ","Errror "},
	// T_erstelle_Tabelle
	{"erstelle Tabelle ","creating table "},
	// T_Zeige
	{"Zeige: ","showing: "},
	// T_an_Position
	{"an Position: ","at position: "},
	// T_Feld
	{"Feld: '","Field: '"},
	// T_Wertma
	{"', Wert: '","', value: '"},
	// T_Tabelle
	{"Tabelle: ","Table: "},
	// T_Versuche_in_doAbfrage_mehr_als,
	{"Versuche in doAbfrage mehr als ","in doAbfrage more tries than "},
	{"",""}
};
// Txdbcl::Txdbcl() {TCp=(const char* const * const * const *)&TextC;}
// class Txdbcl Txd;
// class TxB Txd(DB_T);
class TxB Txd((const char* const* const* const*)DB_T);
const string& pwk = "4893019320jfdksalö590ßs89d0qÃ9m0943Ã09Ãax"; // fuer Antlitzaenderung

#ifdef mitpostgres 
const DBSTyp myDBS=Postgres;
#else // mitpostgre
const DBSTyp myDBS=MySQL;
#endif // mitpostgres else

// Datenbanknamen aus sql-String extrahieren
svec holdbaussql(string sql) 
{
  svec erg;
  string db;
  size_t runde=0;
  while (1) {
    runde++;
    const string SQL=boost::locale::to_upper(sql, loc);
////    transform(sql.begin(),sql.end(),std::back_inserter(SQL),::toupper);
    size_t pfrom=SQL.find("FROM ");
    size_t pjoin=SQL.find("JOIN ");
    size_t ab=pfrom<pjoin?pfrom:pjoin;
    if (ab!=string::npos) {
      ab+=5;
      size_t bis=string::npos;
      if (sql[ab]=='`' || sql[ab]=='[' || sql[ab]=='\"') ab++;
      bis=SQL.find_first_of((string(" .,;()'\"`]:{}")+(char)9+(char)10+(char)13).c_str(),ab);
      if (bis!=string::npos) 
        db=sql.substr(ab,bis-ab);
      else
        db=sql.substr(ab);
      if (!db.empty()) {
        uchar alt=0;
				for(auto const& aerg:erg) {
					if (aerg==db) {alt=1;break;}
				}
        if (!alt) erg<<db;
      } // if (!db.empty()) 
      if (bis==string::npos) break;
      sql=sql.substr(bis);
    } else break; // if (ab!=string::npos) 
  } // while (1)
  return erg;
} // holdbaussql

// hinzufuegen mit pruefen
void insv::hzp(instyp it) 
{
	for (size_t i=0;i<ivec.size();i++) {
		if (it.feld==ivec[i].feld)
			return;
	}
	ivec.push_back(it);
} // void insv::hzp

// hinzufuegen 
void insv::hz(instyp it) 
{
	ivec.push_back(it);
} // void insv::hz

Feld::Feld()
{
}

Feld::Feld(const string& name, string typ/*=string()*/, const string& lenge/*=string()*/, const string& prec/*=string()*/, 
    const string& comment/*=string()*/, bool obind/*=0*/, bool obauto/*=0*/, bool nnull/*=0*/, const string& vdefa/*=string()*/, bool unsig/*=0*/):
  name(name)
  ,typ(typ)
  ,lenge(lenge)
  ,prec(prec)
  ,comment(comment)
  ,obind(obind)
  ,obauto(obauto)
  ,nnull(nnull)
  ,defa(vdefa) // Namensdifferenz hier noetig, sonst wird im Konstruktur die falsche Variable bearbeitet
  ,unsig(unsig)
{
	if (defa.empty()) {
		if (obauto) {
			defa="0";
		} else {
			const string utyp=boost::locale::to_upper(typ, loc);
			////    transform(typ.begin(),typ.end(),typ.begin(),::toupper);
			if (utyp.find("INT")!=string::npos || utyp=="LONG"||utyp=="DOUBLE"||utyp=="FLOAT"||utyp=="DECIMAL")
				defa="0";
			else if (utyp=="DATE" || utyp=="DATETIME" || utyp=="TIME" ||utyp=="TIMESTAMP")
				defa="0000-00-00";
			else if (utyp=="YEAR")
				defa="0000";
			else
				defa=string(); // char- usw.Felder
		}
	}
} // Feld(const string& name, const string& typ, const string& lenge, const string& prec, string comment, bool vind, bool vobauto, bool vnnull, string vdefa):

// Feld::Feld(Feld const& copy) { }


Index::Index(const string& name, Feld *const vfelder, const unsigned feldzahl, const uchar unique/*=0*/):
  name(name),
  felder(vfelder),
  feldzahl(feldzahl),
	unique(unique)
{
}


Constraint::Constraint(const string& name, Feld *const felder1, const unsigned feldz1, const string& reftab, 
		                   Feld *const felder2, const unsigned feldz2, const refact onupdate/*=restrict*/, const refact ondelete/*=restrict*/):
	name(name),
	felder1(felder1),
	feldz1(feldz1),
	reftab(reftab),
	felder2(felder2),
	feldz2(feldz2),
	onupdate(onupdate),
	ondelete(ondelete)
{
}

Tabelle::Tabelle(const DB* dbp,const std::string& tbname, Feld *vfelder, const int feldzahl, Index *const vindices, const unsigned vindexzahl, 
		Constraint *const constraints, const unsigned constrzahl, const string comment/*string()*/, 
		const string& engine/*DB::defmyengine*/, const string& charset/*DB::defmycharset*/, const string& collate/*DB::defmycollat*/, const string& rowformat/*DB::defmyrowform*/) :   
	dbp(dbp),tbname(tbname),
	comment(comment),
	felder(vfelder),
	feldzahl(feldzahl),
	indices(vindices),
	indexzahl(vindexzahl),
	constraints(constraints),
	constrzahl(constrzahl),
	engine(engine),
	charset(charset),
	collate(collate),
	rowformat(rowformat)
{
}

Tabelle::Tabelle(const DB* dbp,const string& tbname, sfeld& fdr, Index *const indices/*=0*/, const unsigned vindexzahl/*=0*/, 
		Constraint *const constraints/*=0*/, const unsigned constrzahl/*=0*/,
		const string comment/*=string()*/, const string& engine/*=DB::defmyengine*/, const string& charset/*=DB::defmycharset*/, const string& collate/*=DB::defmycollat*/, 
		const string& rowformat/*=DB::defmyrowform*/):
	dbp(dbp),tbname(tbname),
	comment(comment),
	indices(indices),
	indexzahl(vindexzahl),
	constraints(constraints),
	constrzahl(constrzahl),
	engine(engine),
	charset(charset),
	collate(collate),
	rowformat(rowformat)
{
	feldzahl=fdr.size();
	felder=new Feld[feldzahl];
	copy(fdr.begin(),fdr.end(),felder);
//	for(size_t i=0;i<fdr.size();i++) {
//		felder[i]=&fdr[i];
//		memcpy(&felder[i],fdr[i],sizeof *felder);
////		caus<<"Name ("<<i<<"): "<<felder[i].name<<endl;
//	}
}

Tabelle::Tabelle(const DB* dbp,const string& vtbname,const size_t aktc,int obverb,int oblog): dbp(dbp),tbname(vtbname)
{
	lesespalten(aktc,obverb,oblog);
}

const string DB::defmyengine{"InnoDB"};
const string DB::defmycharset{"utf8"};
const string DB::defmycollat{"utf8_unicode_ci"};
const string DB::defmyrowform{"DYNAMIC"};

// statische Variable, 1= mariadb=geprueft
uchar DB::oisok=0;

// /*1*/DB::DB() { }

/*2*/DB::DB(const DBSTyp nDBS, const string& phost, const string& puser, const string& ppasswd, 
		const size_t conz/*=1*/, const string& uedb, 
       unsigned int port, const char *const unix_socket, unsigned long client_flag,
    int obverb,int oblog,const string charset, const string collate, int versuchzahl, const uchar ggferstellen):DBS(nDBS),
		host(phost),user(puser),passwd(ppasswd),dbname(uedb), conz(conz)
{
  init(charset,collate,port,unix_socket,client_flag,obverb,oblog,versuchzahl, ggferstellen);
} // DB::DB

/*3*/DB::DB(const DBSTyp nDBS, const char* const phost, const char* const puser,const char* const ppasswd, 
      const char* const prootpwd, const size_t conz/*=1*/, 
			const char* const uedb, unsigned int port, const char *const unix_socket, unsigned long client_flag,
		  int obverb,int oblog, const string charset, const string collate, int versuchzahl, const uchar ggferstellen): DBS(nDBS),
			host(phost),user(puser),passwd(ppasswd),dbname(uedb),rootpwd(prootpwd),conz(conz)
{
  init(charset,collate,port,unix_socket,client_flag,obverb,oblog,versuchzahl,ggferstellen);
}

/*4*/DB::DB(const DBSTyp nDBS, const char* const phost, const char* const puser,const char* const ppasswd, 
		const size_t conz/*=1*/, const char* const uedb, unsigned int port, const char *const unix_socket, unsigned long client_flag, 
		int obverb,int oblog,const string charset, const string collate, int versuchzahl, const uchar ggferstellen)
			 :DBS(nDBS),host(phost),user(puser),passwd(ppasswd),dbname(uedb),conz(conz)
{
  init(charset,collate,port,unix_socket,client_flag,obverb,oblog,versuchzahl,ggferstellen);
}

// 2 x in DB::init
void DB::instmaria(int obverb, int oblog)
{
	if (linstp->ipr==apt) {
		systemrueck("apt-get -y install apt-transport-https;"
		"apt-get update && DEBIAN_FRONTEND=noninteractive apt-get --reinstall install -y mariadb-server",1,1,/*rueck=*/0,/*obsudc=*/1);
	} else {
		linstp->doinst("mariadb",obverb,oblog);
		if (linstp->ipr==pac)
		 systemrueck("mysql_install_db --user="+mysqlben+" --basedir=/usr/ --ldata=/var/lib/mysql",obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
	} // 					if (ipr==apt) else
} // void DB::instmaria()

void DB::init(
		const string charset, const string collate, 
		unsigned int port/*=0*/, const char *const unix_socket/*=NULL*/, 
		unsigned long client_flag/*=0*/,int obverb/*=0*/,int oblog/*=0*/,unsigned versuchzahl/*=3*/, const uchar ggferstellen/*=1*/)
{
	fehnr=0;
	fLog(violetts+Txd[T_DB_wird_initialisiert]+schwarz,obverb>0?obverb-1:0,oblog);
	uchar installiert=0;
	uchar datadirda=0;
	const string mysqld="mysqld";
	switch (DBS) {
		case MySQL:
#ifdef linux
			switch (linstp->ipr) {
				case zypper: case apt:
					db_systemctl_name="mysql";
					break;
				case dnf: case yum:
					db_systemctl_name="mariadb";
					break;
				default: break;
			} //       switch (ipr)
			if (!dbsv) dbsv=new servc(db_systemctl_name,mysqld,obverb,oblog);
			if (!oisok) {
				// schauen, ob die Exe-Datei da ist 
				for (int iru=0;iru<2;iru++) {
					installiert=1;
					// wenn nicht gefunden ...
					if (!obprogda(mysqld,obverb,oblog)) {
						svec frueck;
						// .. und auch hier nicht gefunden ...
						systemrueck("find /usr/sbin /usr/bin /usr/libexec -executable -size +1M -name "+mysqld,obverb,oblog, &frueck,/*obsudc=*/0);
						if (!frueck.size()) 
							// .. dann wohl nicht installiert
							installiert=0;
					} //           if (!obprogda("mysqld",obverb,oblog))
					if (installiert) {
						if (!obprogda(mysqlbef,obverb,oblog))
							installiert=0;
						else if (systemrueck("grep \"^"+mysqlben+":\" /etc/passwd",obverb,oblog,/*rueck=*/0,/*obsudc=*/0))
							installiert=0;
						else if (systemrueck(mysqlbef+" -V",obverb,oblog,/*rueck=*/0,/*obsudc=*/0))
							installiert=0;
					} //           if (installiert)
					if (installiert) break;
					////        systemrueck("which zypper && zypper -n in mariadb || KLA which apt-get && apt-get -y install mariadb-server; KLZ",1,1);
					instmaria(obverb, oblog);
				} //         for (int iru=0;iru<2;iru++)
				// Datenverzeichnis suchen und pruefen
				if (installiert) {
					svec zrueck;
					if (!systemrueck("sed 's/#.*$//g' `"+mysqlbef+" --help | sed -n '/Default options/{n;p}'` 2>/dev/null "
								"| grep datadir | cut -d'=' -f2",obverb,oblog,&zrueck,/*obsudc=*/0)) {
						if (zrueck.size()) {
							datadir=zrueck[zrueck.size()-1];  
						} else {
							svec zzruck, zincldir;
							systemrueck("find /etc /etc/mysql ${MYSQL_HOME} -name my.cnf -printf '%p\\n' -quit", obverb,oblog,&zzruck,/*obsudc=*/0);
							if (!zzruck.size())
								systemrueck("find "+gethome()+" -name .my.cnf -printf '%p\\n' -quit",obverb,oblog,&zzruck,/*obsudc=*/0);
							if (zzruck.size()) {
								systemrueck("cat "+zzruck[0]+" | sed 's/#.*$//g' | grep '!includedir' | sed 's/^[ \t]//g' | cut -d' ' -f2-", 
										obverb,oblog,&zincldir,/*obsudc=*/1); 
								for(auto const& aktdir:zincldir) {
									svec zzruck2;
									systemrueck("find "+aktdir+" -not -type d",obverb,oblog,&zzruck2,/*obsudc=*/1); // auch links
									for(auto const& aktzz2:zzruck2) {
										zzruck<<aktzz2;
									}
								} //                 for(size_t i=0;i<zincldir.size();i++)
							} //               if (zzruck.size())
							if(zzruck.size()) {
								for(auto const& aktzz:zzruck) {
									svec zrueck;
									if (!systemrueck(("sed 's/#.*$//g' '")+aktzz+"' | grep datadir | cut -d'=' -f2",obverb,oblog,&zrueck,/*obsudc=*/1)) {
										if (zrueck.size()) {
											datadir=zrueck[zrueck.size()-1];  
											break;
										} // if (zrueck.size()) 
									} // if (!systemrueck(("cat ")+zzruck[i]+" | sed 's/#.*$//g' | grep datadir | cut -d'=' -f2",obverb>0?obverb-1:0,oblog,&zrueck)) 
								} // for(size_t i=0;i<zzruck.size();i++) 
							} // if(zzruck.size()) 
						} // if (zrueck.size()) else
					} // if (!systemrueck("sed 's/#.*$//g' `"+mysqlbef+"--help | sed -n '/Default options/KLAn;pKLZ'` 2>/dev/null " ...
					gtrim(&datadir);
					//// <<rot<<datadir<<schwarz<<endl;
					if (datadir.empty()) {
						datadir="/var/lib/mysql";
					}
					if (obverb) fLog("datadir: "+blaus+datadir+schwarz,obverb,oblog);
					struct stat datadst={0};
					if (!lstat(datadir.c_str(), &datadst)) {
						if(S_ISDIR(datadst.st_mode)) {
							datadirda=1;
						} else {
							systemrueck("rm -f '"+datadir+"'",1,1,/*rueck=*/0,/*obsudc=*/1);
						} // 						if(S_ISDIR(datadst.st_mode)) else
					} //           if (!lstat(datadir.c_str(), &datadst))
					if (!datadirda) {
						systemrueck("`find /usr/local /usr/bin /usr/sbin -name mysql_install_db"+string(obverb?"":" 2>/dev/null")+"`",1,1,/*rueck=*/0,/*obsudc=*/1);
						dbsv->start(obverb,oblog);
					} // 					if (!datadirda)
					oisok=1;
				} // if (installiert)
			} // if (!oisok)
#endif // linux
			conn=new MYSQL*[conz];
			this->ConnError=NULL;
			for(size_t aktc=0;aktc<conz;aktc++) {
				conn[aktc] = mysql_init(NULL);
				if (!conn[aktc]) {
					this->ConnError=mysql_error(conn[aktc]);
					////			printf("Fehler %u beim Erstellen einer MySQL-Verbindung: %s\n", mysql_errno(conn[aktc]), *erg=mysql_error(conn[aktc]));
					cerr<<Txd[T_Fehler_db]<<mysql_errno(conn[aktc])<<Txd[T_beim_Initialisieren_von_MySQL]<<this->ConnError<<endl;
					////			throw "Fehler beim Erstellen einer MySQL-Verbindung";
				} else {
					if (user.empty()) {
						exit(schluss(13,Txd[T_Datenbankbenutzer_leer]));
          }
					RS *rs;
					for(unsigned versuch=0;versuch<versuchzahl;versuch++) {
						////   <<"versuch: "<<versuch<<", conn[aktc]: "<<conn[aktc]<<", host: "<<host<<", user: "<<user<<", passwd "<<passwd<<", uedb: "<<uedb<<", port: "<<port<<", client_flag: "<<client_flag<<", obverb: "<<obverb<<", oblog: "<<(int)oblog<<endl;
						fehnr=0;
						if (mysql_real_connect(conn[aktc], host.c_str(), user.c_str(), passwd.c_str(), dbname.c_str(), port, unix_socket, client_flag)) {
							// mysql_set_character_set(conn[aktc],"utf8");
							cmd="SET NAMES 'utf8' COLLATE 'utf8_unicode_ci'";
							if (mysql_real_query(conn[aktc],cmd.c_str(),cmd.length())) {
								if (MYSQL_RES *dbres=mysql_use_result(conn[aktc])) {
									mysql_free_result(dbres);
								}
							}
							break;
						} else {
							switch ((fehnr=mysql_errno(conn[aktc]))) {
								case 1044: // Access denied for user '<user>'@'<host>' to database '...' (Ubuntu)
								case 1045: // Access denied for user '<user>'@'<host>' (using password: YES)
								case 1698: // dasselbe auf Ubuntu
									for(unsigned aru=0;aru<1;aru++) {
										for(unsigned iru=0;iru<2;iru++) {
											cmd=mysqlbef+" -uroot -h'"+host+"' "+(rootpwd.empty()?"":"-p"+rootpwd)+" -e \"GRANT ALL ON "+dbname+".* TO '"+
												user+"'@'"+myloghost+"' IDENTIFIED BY '"+ersetze(passwd.c_str(),"\"","\\\"")+"' WITH GRANT OPTION\" 2>&1";
											if (iru) break;
											pruefrpw(cmd, versuchzahl);
										} //                   for(unsigned iru=0;iru<2;iru++) 
										myr.clear();
										systemrueck(cmd,1,1,&myr,/*obsudc=*/1);
										miterror=1;
										if (!myr.size()) miterror=0; else if (!strcasestr(myr[0].c_str(),"error")) miterror=0;
										else {
											fLog(Txd[T_Fehler_dp]+rots+myr[0]+schwarz+Txd[T_bei_Befehl]+blau+cmd+schwarz,1,1);
										}
										if (!miterror) break;
									} // while (1)
									break;
								case 2006: // Server has gone away
								case 2002: // Can't connect to local MySQL server through socket '/var/lib/mysql/mysql.sock' (2 "No such file or directory"):
									if (!strcasecmp(host.c_str(),"localhost")) {
										fLog(Txd[T_Fehler_db]+drots+mysql_error(conn[aktc])+schwarz+Txd[T_Versuche_mysql_zu_starten],1,1);
#ifdef linux
										dbsv->enableggf(1,1);
										setfaclggf(datadir,obverb,oblog,wahr,7,0,0,mysqlben);
										fLog(blaus+Txd[T_Vor_restart]+Txd[T_Versuch_Nr]+schwarz+ltoan(versuch),1,oblog);
										for(int iiru=0;iiru<2;iiru++) {
											if (dbsv->restart(1,1)) {
												fLog(Txd[T_MySQL_erfolgreich_gestartet],1,1);
												break;
											} // 									 if (dbsv-restart(1,1))
											instmaria(obverb,oblog);
										} // 									for(int iiru=0;iiru<2;iiru++)
										continue;
#endif // linux
									} //                 if (!strcasecmp(host.c_str(),"localhost")) 
									break;
								case 1049:
									if (ggferstellen) {
										fLog(Txd[T_Fehler_db]+drots+mysql_error(conn[aktc])+schwarz+Txd[T_Versuche_Datenbank]+drot+dbname+schwarz+Txd[T_zu_erstellen],1,1);
										mysql_real_connect(conn[aktc], host.c_str(), user.c_str(), passwd.c_str(), 0, port, unix_socket, client_flag);
										fehnr=mysql_errno(conn[aktc]);
										if (!fehnr) {
											rs=new RS(this,string("CREATE DATABASE IF NOT EXISTS `")+dbname+"`"+
											         (charset.empty()?"":" CHARSET '"+charset+"'")+
															 (collate.empty()?"":" COLLATE '"+collate+"'"),
											       aktc,obverb);
											fehnr=mysql_errno(conn[aktc]);
											if (!fehnr) {
												////                    rs->Abfrage(string("USE `")+uedb+"`");
												usedb(dbname,aktc);
												fehnr=mysql_errno(conn[aktc]);
												if (!fehnr) {
													delete(rs);
												}
											}
										} else {
											fLog(string(Txd[T_Fehler_beim_Verbinden])+ltoan(fehnr),1,1);
										} //                   if (!fehnr) 
										//// if (ggferstellen)
									} else {
										fLog(Txd[T_Fehler_db]+drots+mysql_error(conn[aktc])+schwarz,obverb,oblog);
									} // if (ggferstellen)
									break;
								case 0:
									break;
								default:
									fLog(Txd[T_Fehler_db]+drots+ltoan(mysql_errno(conn[aktc]))+schwarz+" "+blau+mysql_error(conn[aktc])+schwarz,1,1);
							} //             switch ((fehnr=mysql_errno(conn[aktc]))) 
							if (!fehnr) break;
						} //           if (mysql_real_connect(conn[aktc], host.c_str(), user.c_str(), passwd.c_str(), uedb, port, unix_socket, client_flag))  else 
					} //         for(unsigned versuch=0;versuch<versuchzahl;versuch++) 
					if (!fehnr && conn[aktc]) {
						fLog(Txd[T_Erfolg_beim_Initialisieren_der_Verbindung_zu_mysql]+blaus+ltoan(aktc)+schwarz,obverb>0?obverb-1:0,oblog);
					} else {
						////			printf("Fehler %u beim Verbinden mit MySQL: %s\n", mysql_errno(conn[aktc]), *erg= mysql_error(conn[aktc]));
						this->ConnError=mysql_error(conn[aktc]);
						////          cerr<<"Fehler "<<rot<<mysql_errno(conn[aktc])<<schwarz<<" beim Verbinden mit MySQL: "<<rot<<this->ConnError<<schwarz<<endl;
						mysql_close(conn[aktc]);
						conn[aktc]=0;
						//			throw "Fehler beim Verbinden mit MySQL";
					} // if (mysql_real_connect(conn[aktc], host, user, passwd.c_str(), uedb, port, unix_socket, client_flag))
				} // if (!conn[aktc]) 
			} // 			for(size_t aktc=0;aktc<conz;aktc++)
			dnb = '`'; dne = '`'; dvb = '\''; dve = '\'';
			break;
		case Postgres:
#ifdef mitpostgres 
			uchar neu=0;
			if (!dbsv) { 
				if (!obprogda("postgres",obverb,oblog)) {
				  caup<<"Programm postgres nicht da"<<endl;
					systemrueck("V0=/usr/bin/postgres; V1=${V0}_alt; V2=${V0}_uralt; test -d $V0 &&{ test -d $V1 && "
					            "mv $V1 $V2; mv $V0 $V1;};:",
					            obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
					linstp->doinst("postgresql-server",obverb,oblog);// postgresql-contrib
					neu=1;
				} // 				if (!obprogda("postgres",obverb,oblog))
				dbsv=new servc("postgresql","postgres",obverb,oblog);
				datadir.clear();
				for(int iru=0;iru<2;iru++) {
					if (!dbsv->machfit(obverb,oblog)||neu) {
						if (!iru) setzrpw(obverb,oblog);
						neu=0;
					}
				}
				if (!dbsv->obslaeuft(obverb,oblog)) {
				  systemrueck("journalctl -xe --no-pager -n 9",2,2,/*rueck=*/0,/*obsudc=*/0);
					//// (sudo) systemctl start postgresql
					//// oisok=1;
					fLog(Txd[T_Ende_Gelaende],obverb,oblog);
					exitp(21);
				} // 				if (!dbsv->obslaeuft(obverb,oblog))
			} // 			if (!dbsv)
			const string ip_a="127.0.0.1";
			port=5432;
			const string constr ="user='"+puser+"' password='"+ppasswd+"' dbname='" + uedb + "' hostaddr='"+ip_a+"' port='"+ltoan(port)+"'";
			caup<<constr<<endl;
			do {
				pconn = PQconnectdb(constr.c_str()); ////192.168.178.21 port=5432
				if ((fehnr=PQstatus(pconn)) != CONNECTION_OK) {
					while (rootpwd.empty()) {
						rootpwd=Tippstr({}+Txd[T_Bitte_geben_Sie_ein_Passwort_fuer_Benutzer_postgres_ein]/*,&rootpwd*/);
					}
					const string mconstr ="user='postgres' password='"+rootpwd+/*"' dbname='" + uedb */+ "' hostaddr='"+ip_a+"' port='"+ltoan(port)+"'";
					pmconn = PQconnectdb(mconstr.c_str()); 
					if (PQstatus(pmconn) != CONNECTION_OK) {
						caup<<"Connection-String: "<<rot<<mconstr<<schwarz<<endl;
						fLog("\aVerbindung zur Standarddatenbank '"+rots+uedb+schwarz+"' gescheitert!",1,1);
						pconn=NULL;
						break;
					}
					caup<<"jetzt Benutzererstellung"<<endl<<endl;
		      PGconn *zwi=pconn;
					pconn=pmconn;
			    RS p1(this,"CREATE USER "+puser+" CREATEDB CREATEUSER INHERIT REPLICATION PASSWORD '"+ppasswd+"'",obverb);
////					PQexec(pmconn, ("CREATE USER "+puser+" CREATEDB CREATEUSER INHERIT REPLICATION PASSWORD '"+ppasswd+"'").c_str());
			    RS p2(this,string("CREATE DATABASE \"")+uedb+"\" ENCODING 'LATIN1' TEMPLATE template0 LC_CTYPE 'de_DE.ISO88591' LC_COLLATE 'de_DE.ISO88591'",obverb);
////					PQexec(pmconn, (string("CREATE DATABASE \"")+uedb+"\" ENCODING 'LATIN1' TEMPLATE template0 LC_CTYPE 'de_DE.ISO88591' LC_COLLATE 'de_DE.ISO88591'").c_str());
          pconn=zwi;
				} else {
					fLog(Txd[T_Verbindung_zu]+blaus+uedb+schwarz+Txd[T_gelungen]+blau+user+schwarz+"', host: '"+blau+ip_a+schwarz+"', port: '"+blau+ltoan(port)+schwarz+"'",obverb,oblog);
					caup<<"is gangen"<<endl;
					break;
				} // 				if ((fehnr=PQstatus(pconn)) != CONNECTION_OK) else
			} while (1);
#endif // mitpostgres
			break;
	} // switch (DBS) 
} // DB::DB(DBSTyp nDBS, const char* host, const char* user,const char* passwd, const char* db, unsigned int port, const char *unix_socket, unsigned long client_flag,const char** erg)

int DB::usedb(const string& db,const size_t aktc/*=0*/)
{
  int fehler=0; 
  switch (DBS) {
    case MySQL:
      fehler = mysql_select_db(conn[aktc],db.c_str());    
      break;
    case Postgres:
		  caup<<"hier usedb"<<endl;
			exitp(22);
      RS cdb(this,"\\c "+db,aktc,/*obverb=*/1);		   
      break;
  } //   switch (DBS)
  return fehler;
} // usedb

// in: DB::init
void DB::pruefrpw(const string& wofuer, unsigned versuchzahl)
{
  myloghost=!strcasecmp(host.c_str(),"localhost")||!strcmp(host.c_str(),"127.0.0.1")||!strcmp(host.c_str(),"::1")?"localhost":"%";
  for(unsigned versuch=0;versuch<versuchzahl;versuch++) {
		cmd=mysqlbef+" -uroot -h'"+host+"' "+(rootpwd.empty()?"":"-p"+rootpwd)+" -e \"show variables like 'gibts wirklich nicht'\" 2>&1";
    myr.clear();
    systemrueck(cmd,-1,0,&myr,/*obsudc=*/1);
    miterror=1;
    if (!myr.size()) miterror=0; else if (!strcasestr(myr[0].c_str(),"error")) miterror=0;
    else {
      ////      fLog(Txd[T_Fehler_dp]+rots+myr[0]+schwarz+Txd[T_bei_Befehl]+blau+cmd+schwarz,1,1);
    }
    if (miterror) {
      if (!nrzf) {
				rootpwd=Tippstr(string(Txd[T_MySQL_Passwort])+Txk[T_fuer_Benutzer]+dblau+"root"+schwarz+
				                          Txd[T_wird_benoetigt_fuer_Befehl]+"\n"+tuerkis+wofuer+schwarz+")",0);
        ////                    if (rootpwd.empty()) return; // while (1)
        if (user=="root") passwd=rootpwd;
      }
    } else {
      break; // naechster Versuch
    } // if (miterror) KLA KLZ else KLA
  } //   for(unsigned versuch=0;versuch<versuchzahl;versuch++)
  if (rootpwd.empty()) setzrpw();
} // pruefrpw

// in: DB::init
void DB::setzrpw(int obverb/*=0*/,int oblog/*=0*/) // Setze root-password
{
	if (!nrzf) {
		string rootpw2;
		switch (DBS) {
			case MySQL:
				if (Tippob(Txd[T_MySQL_Passwort]+(Txk[T_fuer_Benutzer]+dblaus)+"root"+schwarz+Txd[T_ist_leer_Wollen_Sie_eines_festlegen])) {
					while (1) {
						do {
							rootpwd=Tippstr(Txd[T_Bitte_geben_Sie_ein_MySQL_Passwort_fuer_Benutzer_root_ein]/*,&rootpwd*/);
						} while (rootpwd.empty());	
						rootpw2=Tippstr(string(Txd[T_Bitte_geben_Sie_ein_MySQL_Passwort_fuer_Benutzer_root_ein])+" ("+Txk[T_erneute_Eingabe]+")"/*,&rootpw2*/);
						if (rootpw2==rootpwd) break;
					} //         while (1)
					// 7.7.17: neuer Fehler "ERROR 1819 (HY000) at line 1: Your password does not satisfy the current policy requirements" auf fedora
					const string verbot="/etc/my.cnf.d/cracklib_password_check.cnf",
					             plugin="plugin-load-add=cracklib_password_check.so";
					struct stat st={0};
					uchar gef=0;
					if (!lstat(verbot.c_str(),&st)) {
						mdatei f(verbot,ios::in,0);
						if (f.is_open()) {
							string zeile;
							while(getline(f,zeile)) {
							 if (!zeile.find(plugin)) {
							  gef=1;
								break;
							 } // 							 if (!zeile.find(plugin))
							} // 							while(getline(f,zeile))
							f.close();
						} // 						if (f.is_open())
						if (gef) {
						 cmd="sed -i 's/^\\("+plugin+"\\)/;\\1/g' "+verbot+";";
						 systemrueck(cmd,obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
						 dbsv->restart(obverb,oblog);
						 const string rcmd=sudc+"sed -i 's/^;\\("+plugin+"\\)/\\1/g' "+verbot+";";
						 anfgg(unindt,rcmd,cmd,obverb,oblog);
						} // 						if (gef)
					} // 					if (!lstat(verbot.c_str(),&st))
					const string cmd=sudc+mysqlbef+" -uroot -h'"+host+"' -e \"GRANT ALL ON *.* TO 'root'@'"+myloghost+
						"' IDENTIFIED BY '"+ersetzAllezu(rootpwd,"\"","\\\"")+"' WITH GRANT OPTION\"";
					fLog(Txd[T_Fuehre_aus_db]+blaus+cmd+schwarz,1,1);
					int erg __attribute__((unused))=system(cmd.c_str());
				} // if (Tippob(Txd[T_Das_MySQL_Passwort_fuer_Benutzer_root_ist_leer_Wollen_Sie_eines_festlegen])) 
				break;
			case Postgres:
				while (1) {
					do {
						rootpwd=Tippstr(string(Txd[T_PostgreSQL_musste_neu_eingerichtet_werden])+
								Txd[T_Welches_Passwort_soll_der_Benutzer_postgres_haben]+": "/*,&rootpwd*/);
					} while (rootpwd.empty());
					rootpw2=Tippstr(string(Txd[T_Welches_Passwort_soll_der_Benutzer_postgres_haben])+" ("+Txk[T_erneute_Eingabe]+"): "/*,&rootpw2*/);
					if (rootpw2==rootpwd) break;
				} // while (1)
				uchar geht=0;
				for(int iru=0;iru<2;iru++) {
					svec irueck;
					systemrueck("echo "+rootpwd+"|su - postgres -c \"psql -c 'select datname from pg_database order by datname'\"",
							        obverb,oblog,&irueck,/*obsudc=*/0);
					for(unsigned zeile=0;zeile<irueck.size();zeile++) {
						if (irueck[zeile].find("template0")!=string::npos) {
							geht=1;
							break;
						} // 					 if (irueck[zeile].find("template0")!=string::npos)
					} // 					for(unsigned zeile=0;zeile<irueck.size();zeile++)
					if (geht) break;
					linstp->doinst("passwd",obverb,oblog,"chpasswd"); 
					systemrueck("echo \"postgres:"+rootpwd+"\"|chpasswd",obverb,oblog,/*rueck=*/0,/*obsudc=*/1);
					svec rueck;
					systemrueck("ps aux|grep postgres|grep -- -D|rev|cut -d' ' -f1|rev",obverb,oblog,&rueck,/*obsudc=*/0);
					if (rueck.size()) {
						datadir=rueck[0];
						caup<<"Datadir: "<<datadir<<endl;
					} else
						datadir="/var/lib/pgsql/data";
					systemrueck("V="+dir_name(datadir)+";mkdir -p $V;chown postgres:postgres -R $V",obverb,oblog,/*rueck=*/0,/*obsudc=*/0);
					rueck.clear();	
					if (systemrueck("echo \""+rootpwd+"\"|su - postgres -c \"initdb -D "+datadir+"\" 2>&1",obverb,oblog,&rueck,/*obsudc=*/1,0,2)) {
						// dann laeuft es wahrscheinlich schon
						fLog(Txd[T_Ende_Gelaende],obverb,oblog);
						exitp(23);
					}
				} // 				for(int iru=0;iru<2;iru++) 
		} // 		switch (DBS) 
	} // if (!nrzf)
} // setzrpw

DB::~DB(void)
{
if (0) {
	switch (DBS) {
		case MySQL:
			if (!this->ConnError) {
				if (!lassoffen) {
					for(size_t aktc=0;aktc<conz;aktc++) {
						mysql_close(conn[aktc]);
					}
				} // 				if (!lassoffen)
			} // 			if (!this->ConnError)
			for(size_t aktc=0;aktc<conz;aktc++) {
				conn[aktc]=0;
			}
			break;
		case Postgres:
			caup<<"hier ~DB"<<endl;
			exitp(24);
			break;
	} // 	switch (DBS)
	if (dbsv) {delete dbsv; dbsv=0;}
 }
} // DB::~DB(void)
/*//
	int DB::Abfrage(string sql,const char** erg,int obverb) 
	return Abfrage(sql.c_str(),erg,obverb);
	}
	int DB::Abfrage(const char* sql,const char** erg,int obverb) 
	switch (DBS) 
	case MySQL:
	if (mysql_query(conn,sql)) 
 *erg=mysql_error(conn);
 if (obverb)
 printf("Fehler %u: %s\n", mysql_errno(conn), *erg);
 return 1;

 result=mysql_store_result(conn);
 resultused=1;
//			row = mysql_fetch_row(result);

return 0;
// int DB::Abfrage(const char* sql,const char** erg) 

int DB::AbfragemE(string sql,const char** erg,int obverb) 
return AbfragemE(sql.c_str(),erg,obverb);

int DB::AbfragemE(const char* sql,const char** erg,int obverb) 
int ergi = Abfrage(sql,erg,obverb);
AbfrageEnde();
return ergi;
} // int DB::AbfragemE(const char* sql,const char** erg) 
 */

// wird aufgerufen in: prueftab
void Tabelle::lesespalten(size_t aktc,int obverb/*=0*/,int oblog/*=0*/)
{
  fLog(violetts+Txd[T_Lesespalten]+blau+": "+tbname+"'"+schwarz,obverb,oblog);
	////          RS spalt(this,string("SHOW COLUMNS FROM `")+name+"`");
  ////  spalt=new RS(this,string("SELECT column_name,character_maximum_length FROM information_schema.columns WHERE table_name = '")+name
  ////      +"' and table_schema = '"+db+"' order by ordinal_position"); // geht nicht fuer Zahlen
	RS spalt(dbp,"SELECT column_name p0,"
        "MID(column_type,INSTR(column_type,'(')+1,INSTR(column_type,')')-INSTR(column_type,'(')-1) p1, column_type p2 "
        "FROM information_schema.columns WHERE table_name = '"+tbname+"' AND table_schema = '"+dbp->dbname+"' ORDER BY ordinal_position",
				  aktc,obverb>0?obverb-1:0);
	spaltfehler=spalt.obqueryfehler;
	if (!spaltfehler) {
		spzahl=spalt.num_rows;
		spnamen.clear();
		splenge.clear();
		sptyp.clear();
    size_t spnr=0;
    ////    <<violett<<"Schema: "<<schwarz<<db<<endl;
    ////    <<violett<<"Tabelle: "<<schwarz<<name<<endl;
		char ***cerg;
		while (cerg=spalt.HolZeile(),cerg?*cerg:0) {
			spnamen<<cjj(cerg,0);
			splenge<<cjj(cerg,1);
			sptyp<<cjj(cerg,2);
			tuzeigspalte(spnr,obverb,oblog);
      /*//
         MYSQL_RES *dbres;
         dbres = mysql_list_fields(conn,name.c_str(),ltab->felder[spnr].name.c_str());
         <<violett<<"spnamen["<<spnr<<"]: "<<schwarz<<spnamen[spnr]<<endl;
         <<violett<<" splenge["<<spnr<<"]: "<<schwarz<<(splenge[spnr]?splenge[spnr]:"NULL")<<endl;
         if (dbres) if (dbres->fields->name) 
           <<" dbres->fields->name: "<<dbres->fields->name<<endl;
         if (dbres) if (dbres->fields->length) 
           <<" dbres->fields->length: "<<dbres->fields->length<<endl;
				 mysql_free_result(dbres);
       */
      spnr++;
    }
    if (obverb) {
      zeigspalten(1);
    } //     if (obverb)
		if (spalt.result) {
			mysql_free_result(spalt.result);
			spalt.result=0;
		}
	} else if (obverb||oblog) {
    fLog(blaus+"spaltfehler: "+ltoan(int(spaltfehler)),obverb,oblog);
  }
  fLog(violetts+Txk[T_Ende]+Txd[T_Lesespalten]+blau+": "+tbname+"'"+schwarz,obverb,oblog);
} // lesespalten

void Tabelle::zeigspalten(int obverb/*=0*/,int oblog/*=0*/)
{
	fLog(blaus+"tbname: "+schwarz+tbname+blaus+", spzahl: "+schwarz+ltoan(spzahl),obverb,oblog);
	for(size_t j=0;j<spzahl;j++) {
		tuzeigspalte(j,obverb,oblog);
	}
} // void Tabelle::zeigspalten

void Tabelle::tuzeigspalte(size_t spnr,int obverb/*=0*/,int oblog/*=0*/)
{
	stringstream ausg;
	ausg<<violett<<"spnamen["<<spnr<<"]: "<<schwarz<<setw(30)<<spnamen[spnr]<<" ";
	ausg<<blau<<"splenge["<<spnr<<"]: "<<schwarz<<setw(5)<<splenge[spnr]<<" ";
	ausg<<blau<<"sptyp["<<spnr<<"]: "<<schwarz<<setw(15)<<sptyp[spnr];
	string ausgstr{ausg.str()};
	fLog(ausgstr,obverb,oblog);
} // void Tabelle::zeigspalten

// enum refact:uchar {cascade,set_null,restrict,no_action,set_default};
const string refacts[]={"CASCADE","SET NULL","RESTRICT","NO ACTION","SET DEFAULT"};

int Tabelle::machconstr(const size_t aktc, int obverb/*=0*/, int oblog/*=0*/)
{
	for(unsigned i=0;i<constrzahl;i++) {
		const Constraint* const cons=&constraints[i];
		uchar obneu{0};
		RS rcon(dbp,"SELECT 0 FROM information_schema.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA='"+dbp->dbname+"' AND TABLE_NAME='"+tbname+"' AND REFERENCED_TABLE_NAME='"+cons->reftab+"' AND REFERENCED_COLUMN_NAME IS NOT NULL AND COLUMN_NAME='"+cons->felder1->name+"' AND REFERENCED_COLUMN_NAME='"+cons->felder2->name+"'",aktc,obverb);
		if (rcon.obqueryfehler) {
			obneu=1;
		} else {
			 if (!rcon.result->row_count) {
				 obneu=1;
			 }
		}
		if (obneu) {
			// Wenn Referenztabelle auf dem aktuellen Server fehlt, dann darueber hinweggehen
			MYSQL_RES *dbres=mysql_list_tables(dbp->conn[aktc],cons->reftab.c_str());
			if (dbres && dbres->row_count) {
				for(int iru=0;iru<2;iru++) {
					string machcon{"ALTER TABLE `"+tbname+"` ADD CONSTRAINT "+(iru?"":"`"+cons->name+"`")+" FOREIGN KEY ("};
					for(unsigned j=0;j<cons->feldz1;j++) {
						machcon+="`"+cons->felder1[j].name+"`";
						if (j<cons->feldz1-1) machcon+=",";
					}
					machcon+=") REFERENCES `"+cons->reftab+"` (";
					for(unsigned j=0;j<cons->feldz2;j++) {
						machcon+="`"+cons->felder2[j].name+"`";
						if (j<cons->feldz2-1) machcon+=",";
					}
					machcon+=") ON UPDATE "+refacts[cons->onupdate]+" ON DELETE "+refacts[cons->ondelete];
					RS rconsins(dbp,tbname);
					rconsins.Abfrage(machcon,aktc,obverb+iru);
					if (!rconsins.obqueryfehler) break; // wenn nicht Constraint-Name schon vergeben
				}
			} else {
				fLog(Txd[T_Referenz]+blaus+cons->name+schwarz+Txd[T_auf_Tabelle]+blau+tbname+schwarz+Txd[T_nicht_erstellt_da_Referenztabelle]+blau+cons->reftab+schwarz+"`"+Txk[T_nicht_gefunden],1,oblog);
			} // if (dbres && dbres->row_count)
			mysql_free_result(dbres);
		}
	} // 	for(unsigned i=0;i<constrzahl;i++)
	return 0;
} // int Tabelle::machconstr

// aufgerufen in prueftab
int Tabelle::machind(const size_t aktc, int obverb/*=0*/, int oblog/*=0*/)
{
	lesespalten(aktc,obverb>0?obverb-1:0,oblog);
	for(unsigned i=0;i<indexzahl;i++) {
		const Index* const indx=&indices[i];
		// steht aus: Namen nicht beruecksichtigen, nur Feldreihenfolge und ggf. -laenge
		uchar obneu=0;
		RS rind(dbp,"SHOW INDEX FROM `"+tbname+"` WHERE KEY_NAME = '"+indx->name+"'",aktc,obverb);
		if (rind.obqueryfehler) {
			obneu=1;
		} else {
			if (!rind.result->row_count){
				obneu=1;
			} else {
				for(unsigned j=0;j<indx->feldzahl;j++) {
					char*** erg= rind.HolZeile();
					if (!*erg) {
						obneu=1;break;
					} else if (strcasecmp(indx->felder[j].name.c_str(),*(*erg+4))) { 
						// 0 = Tabelle, 1 = non_unique (0,1), 2 = Key_name, 3 = seq_in_index, 4 = column_name, 5 = Collation ('A','D'), 6=Cardinality(0,1), 
						// 7= sub_part(NULL,<ziffer>), 8=packed(null), 9=NULL("Yes"),10=index_type("BTREE"),11=comment(""),12=index_comment("")
						obneu=1;break;
					} else if (!indx->felder[j].lenge.empty() && *(*erg+7)) {
						if (indx->felder[j].lenge!=*(*erg+7)) { 
							obneu=1;break;
						}
					} //                 if (!*erg) else ...
				} //               for(int j=0;j<indx->feldzahl;j++)
				if (!obneu) {    // Wenn zu viele Zeilen da sind, auch loeschen
					char*** erg= rind.HolZeile();
					if (*erg) {
						obneu=1;
					}
				} //               if (!obneu)    // Wenn zu viele Zeilen da sind, auch loeschen
//#define abMariaDB1014				
#ifndef abMariaDB1014				
				if (obneu) {
					RS rloesch(dbp,"DROP INDEX `"+indx->name +"` ON `"+tbname+"`",aktc,obverb);
				}
#endif				
			} //             if (!rind.result->row_count) else
		} // if (obneu) 
		if (obneu) {
			RS rindins(dbp,tbname);
			//sql.str(std::string()); sql.clear();
			std::stringstream sql;
			sql<<"CREATE ";
#ifdef abMariaDB1014				
			sql<<"OR REPLACE ";
#endif				
			sql<<(indx->unique?"UNIQUE ":"")<<"INDEX `"<<indx->name<<"` ON `"<<tbname<<"`(";
			for(unsigned j=0;j<indx->feldzahl;j++) {
				sql<<"`"<<indx->felder[j].name<<"`";
				//// caus<<"`"<<indx->felder[j].name<<"`"<<endl;
				//// caus<<"spzahl: "<<spzahl<<endl;
				for(unsigned spnr=0;spnr<spzahl;spnr++) { // reale Spalten
					//// caus<<"spnr: "<<spnr<<", spnamen: "<<spnamen[spnr]<<endl;
					if (!strcasecmp(indx->felder[j].name.c_str(),spnamen[spnr].c_str())) { // Feldnamen identisch
						//// caus<<rot<<indx->felder[j].name<<schwarz<<", spnamen: "<<spnamen[spnr]<<", spnr: "<<spnr<<schwarz<<endl;
						//						if (indx->felder[j].lenge.empty()) indx->felder[j].lenge=splenge[spnr];
						const long numsplen=atol(splenge[spnr].c_str());
						const long numinlen=indx->felder[j].lenge.empty()?0:atol(indx->felder[j].lenge.c_str());
						if (strcasecmp(sptyp[spnr].c_str(),"DATE") && strcasecmp(sptyp[spnr].c_str(),"DATETIME")) {
							//// caus<<rot<<indx->felder[j].name<<violett<<", numinlen: "<<rot<<numinlen<<violett<<", numsplen: "<<rot<<numsplen<<schwarz<<endl;
							if (!numinlen || !numsplen) { // numsplen ist 0 z.B. bei varbinary
								// das sollte reichen
								if (indx->felder[j].typ=="LONGTEXT") {
									if (numsplen>50 || !numsplen) {
										indx->felder[j].lenge="767"; 
									}
								} else if (numsplen>50 || !numsplen) {
									indx->felder[j].lenge="50"; 
								}
							} else if (numinlen>numsplen) {
								// laenger darf ein MariadB-Index z.Zt. nicht sein
								if (numsplen>767) indx->felder[j].lenge="767";
								else indx->felder[j].lenge=splenge[spnr];
							}
						}
					}
				}
				//// <<gruen<<"ptab->indices["<<i<<"].name["<<j<<"].name: "<<schwarz<<indx->felder[j].name<<endl;
				//// <<gruen<<"ptab->indices["<<i<<"].felder["<<j<<"].lenge: "<<schwarz<<indx->felder[j].lenge<<endl;
				if (indx->felder[j].lenge!="0" && !indx->felder[j].lenge.empty()) {
	
					sql<<"("<<indx->felder[j].lenge<<")";
				}
				if (j<indx->feldzahl-1) {
					sql<<",";
				}
			} // for(int j=0;j<indx->feldzahl;j++) 
			sql<<")";
			rindins.Abfrage(sql.str(),aktc,obverb);
		} // if (!rind.obqueryfehler) 
	} // 	for(unsigned i=0;i<indexzahl;i++)
	return 0;
} // int DB::machind(const string& tbname, Index* indx,int obverb/*=0*/, int oblog/*=0*/)

// ob Tabellenspalte da
uchar DB::obtabspda(const char* const tab,const char* const sp)
{
	uchar obda=0;
	Tabelle namen(this,tab);
	for(size_t i=0;i<namen.spzahl;i++) {
    if (!strcasecmp(namen.spnamen[i].c_str(),sp)) {
			obda=1;
			break;
		}
	}
	// <<"obda: "<<(int)obda<<endl;
	return obda;
}

int Tabelle::prueftab(const size_t aktc,int obverb/*=0*/,int oblog/*=0*/) 
{
  fLog(violetts+Txd[T_Pruefe_Tabelle]+blau+tbname+"'"+schwarz,obverb,oblog);
  int gesfehlr=0;
  RS rs(dbp,tbname);
  std::stringstream sql;
  // eine Indexfeldlaenge groesser als die Feldlaenge fuehrt zu Fehler (zumindest bei MariaDB)
  for(unsigned i=0;i<indexzahl;i++){
    for(unsigned j=0;j<indices[i].feldzahl;j++){
      for(unsigned k=0;k<feldzahl;k++){
        if (!felder[k].lenge.empty()) if (!indices[i].felder[j].lenge.empty())
          if (!strcasecmp(felder[k].name.c_str(),indices[i].felder[j].name.c_str())) 
            if (atol(felder[k].lenge.c_str())<atol(indices[i].felder[j].lenge.c_str())){
              felder[k].lenge=indices[i].felder[j].lenge;
            }
      } //       for(int k=0;k<feldzahl;k++)
    } //     for(int j=0;j<indices[i].feldzahl;j++)
  } //   for(int i=0;i<indexzahl;i++)
  vector<string> fstr;
  vector<string> istr;
	string utyp;
  switch (dbp->DBS){
    case MySQL:
      {
        if (dbp->conn[aktc]==0) dbp->conn[aktc] = mysql_init(NULL);
        lesespalten(aktc,obverb>0?obverb-1:0,oblog);
        for(unsigned i=0;i<feldzahl;i++) {
					if (!spaltfehler)
            for(unsigned j=0;j<spzahl;j++) {
              if (!strcasecmp(felder[i].name.c_str(),spnamen[j].c_str())) {
                if (!splenge[j].empty()) 
                  if (atol(splenge[j].c_str()) > atol(felder[i].lenge.c_str())) 
                    felder[i].lenge=splenge[j];
                break;
              } //               if (!strcasecmp(felder[i].name.c_str(),spnamen[j]))
            } //             for(unsigned j=0;j<spzahl;j++)

          fstr.resize(fstr.size()+1);
          istr.resize(istr.size()+1);
          ersetzAlle(felder[i].comment,"'","´"); // 13.8.17: \\' geht auf Fedora nicht mehr, \' auch nicht
          ////<<"felder[i].comment: "<<felder[i].comment<<endl;
					utyp=boost::locale::to_upper(felder[i].typ, loc);
          fstr[i]= "`" + felder[i].name + "` "+
            utyp+
            ((utyp=="DATE"||felder[i].lenge.empty()||felder[i].lenge=="0")?"":
             ("("+felder[i].lenge+
              ((utyp.find("INT")!=string::npos||
								utyp.find("CHAR")!=string::npos||
								utyp.find("TEXT")!=string::npos||
								felder[i].prec.empty())?"":
               (","+felder[i].prec))
              +")"))
						+(felder[i].unsig  ?  " UNSIGNED":"")
            +(felder[i].nnull  ?  " NOT NULL":"")
            +(felder[i].defa=="NULL"||felder[i].defa=="null"||((felder[i].defa.empty()&&!felder[i].nnull)||(felder[i].obind && felder[i].obauto)||utyp.find("LONGTEXT")!=string::npos)?"":" DEFAULT '"+felder[i].defa+"'")
            +(felder[i].obauto?" AUTO_INCREMENT":" ")
            +(felder[i].obind && felder[i].obauto?" PRIMARY KEY":" ")
            +((felder[i].comment.empty())?"":
                (" COMMENT '"+felder[i].comment+"'"));
          if (felder[i].obind && !felder[i].obauto) {
            istr[i]=", ADD INDEX `"+felder[i].name+"`(`"+felder[i].name+"`)";
          }
        } // for(int i=0;i<feldzahl;i++)
        MYSQL_RES *dbres=mysql_list_tables(dbp->conn[aktc],tbname.c_str());
        if (dbres && !dbres->row_count) {
					fLog(Txd[T_erstelle_Tabelle]+blaus+tbname+schwarz,1,oblog);
					tbneu=1;
          /*comment=**/sersetze(&comment,string("'"),string("\\'"));
          sql<<"CREATE TABLE `"<<tbname.c_str();
          sql<<"` ("<<fstr[0]<<istr[0]<<") COMMENT='"<<comment<<"'";
					if (!engine.empty()) {
					 sql<<" ENGINE='"<<engine<<"'";
					}
					if (!charset.empty()) {
					 sql<<" CHARSET='"<<charset<<"'";
					}
					if (!collate.empty()) {
					 sql<<" COLLATE='"<<collate<<"'";
					}
					if (!rowformat.empty()) {
						sql<<" ROW_FORMAT="<<rowformat;
					}
          rs.Abfrage(sql.str(),aktc,obverb); // falls obverb, dann sql-String ausgeben
          gesfehlr+=rs.obqueryfehler;
          if (gesfehlr) fLog(string("gesfehlr 1: ")+ltoan(gesfehlr),1,1);
          lesespalten(aktc,obverb>0?obverb-1:0,oblog);
        } // if (!dbres->row_count) 
        mysql_free_result(dbres);

        // Pruefung, ob Spalten hinzugefuegt werden muessen
        for(unsigned gspn=0;gspn<feldzahl;gspn++) { // geplante Spalten
          binaer gefunden=falsch;
          for(unsigned j=0;j<spzahl;j++) { // reale Spalten
            if (!strcasecmp(felder[gspn].name.c_str(),spnamen[j].c_str())) {
              gefunden=wahr;
              break;
            } //             if (!strcasecmp(felder[gspn].name.c_str(),spnamen[j]))
          } //           for(unsigned j=0;j<spzahl;j++)
          if (!gefunden) {
            sql.str(std::string()); sql.clear();
            sql<<"ALTER TABLE `"<<tbname<<"` ADD "<<fstr[gspn];
            if (gspn) sql<<" AFTER `"<<felder[gspn-1].name<<"`";
            else sql<<" FIRST";
            sql<<istr[gspn];
            /*int erg=*/rs.Abfrage(sql.str(),aktc,obverb);
            gesfehlr+=rs.obqueryfehler;
            if (gesfehlr) fLog(string("gesfehlr 2: ")+ltoan(gesfehlr),1,1);
          } //           if (!gefunden)
        } //         for(int gspn=0;gspn<feldzahl;gspn++)

        // Pruefung, ob Spalten geaendert oder verschoben werden muessen
        for(unsigned gspn=0;gspn<feldzahl;gspn++) { // geplante Spalten
          binaer verschieb=falsch, aendere=falsch;
          for(unsigned spnr=0;spnr<spzahl;spnr++) { // reale Spalten
            if (!strcasecmp(felder[gspn].name.c_str(),spnamen[spnr].c_str())) { // Feldnamen identisch
              if (strcasecmp(sptyp[spnr].c_str(),"mediumtext") 
							 && strcasecmp(sptyp[spnr].c_str(),"blob") 
							 && strcasecmp(sptyp[spnr].c_str(),"longblob") 
							 && strcasecmp(sptyp[spnr].c_str(),"longtext") 
							 && strcasecmp(sptyp[spnr].c_str(),"text")) {
                if ((felder[gspn].lenge!="0" && !felder[gspn].lenge.empty()) &&
                    atol(felder[gspn].lenge.c_str()) > (long)atol(splenge[spnr].c_str())) {
                  aendere=wahr;
                } //                     atol(felder[gspn].lenge.c_str()) > (long)atol(splenge[spnr]))
              } //                   strcasecmp(sptyp[spnr].c_str(),"longtext") && strcasecmp(sptyp[spnr].c_str(),"text"))
              //// <<"felder[gspn].lenge: "<<rot<<felder[gspn].lenge<<schwarz<<endl;
              //// <<"splenge[spnr]: "<<rot<<splenge[spnr]<<schwarz<<endl;
              if (gspn) { // Verschiebung erst ab der zweiten geplanten Spalte reicht auch und vermeidet Speicherunterlaeufe
                verschieb=wahr; 
                if (spnr) if (!strcasecmp(felder[gspn-1].name.c_str(),spnamen[spnr-1].c_str())) verschieb=falsch;
                if (verschieb) spnr--;
              } //               if (gspn)
              if (verschieb || aendere) break;
            } //             if (!strcasecmp(felder[gspn].name.c_str(),spnamen[spnr].c_str()))
          } //           for(unsigned spnr=0;spnr<spzahl;spnr++)
          if (verschieb || aendere) {
            //// <<"verschieb: "<<rot<<verschieb<<schwarz<<endl;
            //// <<"aendere: "<<rot<<aendere<<schwarz<<endl;
            sql.str(std::string()); sql.clear();
            sql<<"ALTER TABLE `"<<tbname<<"` MODIFY "<<fstr[gspn];
            if (gspn) sql<<" AFTER `"<<felder[gspn-1].name<<"`";
            else sql<<" FIRST";
            /*int erg=*/rs.Abfrage(sql.str(),aktc,obverb);
            gesfehlr+=rs.obqueryfehler;
            if (gesfehlr) fLog(string("gesfehlr 3: ")+ltoan(gesfehlr),1,1);
            if (verschieb)  {
              lesespalten(aktc,obverb>0?obverb-1:0,oblog);
						}
            if (aendere) {
              if (!istr[gspn].empty()) {
                RS rloesch(dbp,string("DROP INDEX `")+felder[gspn].name +"` ON `"+tbname+"`",aktc,obverb);
                sql.str(std::string()); sql.clear();
                sql<<"ALTER TABLE `"<<tbname<<"`"<<istr[gspn].substr(1);
                rs.Abfrage(sql.str(),aktc,obverb);
              } // if (!istr[gspn].empty()) 
            } // if (aendere) 
          } // if (verschieb || aendere)
        } // for(int gspn=0;gspn<feldzahl;gspn++) 
				//RS commit(dbp,"COMMIT",aktc,obverb);
				machind(aktc,obverb,oblog);
				machconstr(aktc,obverb,oblog);
			} // case Mysql
      break;
    case Postgres:
		  caup<<"hier prueftab "<<tbname<<endl;
			exitp(25);
      break;
  } // switch (DBS)
  return gesfehlr;
} // int Tabelle::prueftab(const size_t aktc,int obverb/*=0*/,int oblog/*=0*/)

// erweitert die Spaltenbreite einer Spalte auf mindenstens wlength, falls sie geringer ist
uchar DB::tuerweitern(const string& tabs, const string& feld,long wlength,const size_t aktc,int obverb) const
{
  stringstream korr;
  string lenge;
  korr<<"SELECT character_maximum_length, data_type,is_nullable,column_default,column_comment FROM information_schema.columns WHERE table_schema='"<<
    dbname<<"' AND table_name='"<<tabs<<"' AND column_name='"<<feld<<"'";
  RS spaltlen(this,korr.str(),aktc,obverb>1?obverb-1:0);
  if (!spaltlen.obqueryfehler) {
    char*** cerg;
    while(cerg= spaltlen.HolZeile(),cerg?*cerg:0) {
      if (*(*cerg+0)) {
        lenge=*(*cerg+0);
        if (atol(lenge.c_str())<wlength) {
          fLog(Txd[T_Erweitere_Feld]+tabs+"."+feld+Txd[T_von]+lenge.c_str()+Txd[T_auf]+ltoan(wlength),1,1);
          korr.str(std::string()); korr.clear();
          if (*(*cerg+1) && *(*cerg+2)) {
            korr<<"ALTER TABLE `"<<tabs<<"` MODIFY COLUMN `"<<feld<<"` "<<*(*cerg+1)/*data_type*/<<"("<<wlength<<") "<<
              (!strcasecmp(*(*cerg+2),"yes")?"NULL":"NOT NULL")<<" "<<(cjj(cerg,3)?string("DEFAULT '")+cjj(cerg,3)+"'":"")<<
              " COMMENT '"<<ersetzAllezu(cjj(cerg,4),"'","\\'")<<"'";
            RS spaltaend(this,korr.str(),aktc,obverb);
            if (spaltaend.fnr==1074) {
              korr.str(std::string()); korr.clear();
              string neufeld;
              if (!strcasecmp(*(*cerg+1),"binary")) neufeld="mediumblob";
              else if (!strcasecmp(*(*cerg+1),"varbinary")) neufeld="mediumblob";
              else if (!strcasecmp(*(*cerg+1),"tinyblob")) neufeld="mediumblob";
              else if (!strcasecmp(*(*cerg+1),"blob")) neufeld="mediumblob";
              else if (!strcasecmp(*(*cerg+1),"char")) neufeld="mediumtext";
              else if (!strcasecmp(*(*cerg+1),"varchar")) neufeld="mediumtext";
              else if (!strcasecmp(*(*cerg+1),"text")) neufeld="mediumtext";
              else if (!strcasecmp(*(*cerg+1),"tinytext")) neufeld="mediumtext";
              else if (!strcasecmp(*(*cerg+1),"mediumtext")) neufeld="longtext";
              else if (!strcasecmp(*(*cerg+1),"mediumblob")) neufeld="longblob";
              if (!neufeld.empty()) {
                fLog(Txd[T_Aendere_Feld]+tabs+"."+feld+" von: "+*(*cerg+1)+" auf: "+neufeld,1,1);
                korr<<"ALTER TABLE `"<<tabs<<"` MODIFY COLUMN `"<<feld<<"` "<<neufeld/*data_type*/<<" "<<
                  (!strcasecmp(*(*cerg+2),"yes")?"NULL":"NOT NULL")<<" "<<(cjj(cerg,3)?string("DEFAULT '")+cjj(cerg,3)+"'":"")<<
                  " COMMENT '"<<ersetzAllezu(cjj(cerg,4),"'","\\'")<<"'";
                RS spaltaend2(this,korr.str(),aktc,obverb);
              }
            } // if (fnr==1074) 
          }
          return -1; // Aenderung durchgefuehrt
        } // if (atol(lenge.c_str())<wlength) 
        return 0; // kein Fehler, keine Aenderung noetig
      } else {
        ////        hier z.B. numerische Felder G.Schade 1.1.16
        ////        cerr<<"Fehler bei der Abfrage der Tabellenlaenge bei Tabelle: "<<tabs<<" und Feld: "<<feld<<endl<<" mit: "<<korr.str()<<endl;
        ////        return 2; // Fehler bei der Abfrage der Spaltenlaenge
      } // if (**cerg) else
    } // while(cerg= HolZeile(),cerg?*cerg:0) 
  } else {
    cerr<<Txd[T_falsche_Fehlernr]<<spaltlen.fnr<<Txd[T_bei_der_Abfrage_der_Spaltenlaenge_bei_Tabelle]<<tabs<<
      Txd[T_und_Feld]<<feld<<endl<<Txd[T_mit]<<korr.str()<<endl;
    return 1;
  } // if (!obqueryfehler) else 
  return 5;  // wird nie erreicht, verhindert aber Compilerfehlermeldung
} // tuerweitern

// in: RS::insert() und RS::update
void DB::erweitern(const string& tabs, vector<instyp> einf,const size_t aktc,int obverb,uchar obsammeln, const unsigned long *maxl) const
{
  for(unsigned i=0;i<einf.size();i++) {
    long wlength;
    if (obsammeln) {
      wlength = maxl[i];
    } else {
      wlength = einf[i].wert.length();
    } //     if (obsammeln)
    tuerweitern(tabs,einf[i].feld,wlength,aktc,obverb);
  } //   for(unsigned i=0;i<einf.size();i++)
} // RS::erweitern

// in: RS::insert() und RS::update
int DB::machbinaer(const string& tabs, const size_t aktc,const string& fmeld,int obverb) const
{
  fLog(violetts+__FUNCTION__+"()"+schwarz+" tabs. "+blau+tabs+schwarz+" fmeld: "+blau+fmeld+schwarz+" obverb: "+ltoan(obverb),obverb,0);
  size_t p1,p2,p3,p4;
  if (!(p1=fmeld.find("'")+1)) return 1;
  if (!(p2=fmeld.find("'",p1)+1)) return 2;
  //                string inc=fmeld.substr(p1,p2-p1-1);
  if (!(p3=fmeld.find("'",p2)+1)) return 3;
  if (!(p4=fmeld.find("'",p3)+1)) return 4;
  const string feld=fmeld.substr(p3,p4-p3-1);
  stringstream korr;
  string lenge;
  string neufeld;
  korr<<"SELECT character_maximum_length p0, data_type p1,is_nullable p2,column_default p3,column_comment p4"
    " FROM information_schema.columns WHERE table_schema='"<<
    dbname<<"' AND table_name='"<<tabs<<"' AND column_name='"<<feld<<"'";
  RS spaltlen(this,korr.str(),aktc,obverb);
  if (!spaltlen.obqueryfehler) {
    char*** cerg;
    while(cerg=spaltlen.HolZeile(),cerg?*cerg:0) {
      if (*(*cerg+0)) {
        lenge=*(*cerg+0);
        if (!strcasecmp(cjj(cerg,1),"CHAR")) neufeld="BINARY";
        else if (!strcasecmp(cjj(cerg,1),"VARCHAR")) neufeld="VARBINARY";
        else continue;
        while(1) { 
          korr.str(std::string()); korr.clear();
          korr<<"ALTER TABLE `"<<tabs<<"` MODIFY COLUMN `"<<feld<<"` "<<neufeld/*data_type*/<<"("<<lenge<<") "<<
            (!strcasecmp(cjj(cerg,2),"yes")?"NULL":"NOT NULL")<<" "<<(cjj(cerg,3)?string("DEFAULT '")+cjj(cerg,3)+"'":"")<<
            " COMMENT '"<<ersetzAllezu(cjj(cerg,4),"'","\\'")<<"'";
          RS spaltaend(this,korr.str(),aktc,-1/*obverb*/);
          if (mysql_errno(this->conn[aktc])!=1406) break;
          lenge=ltoan(atol(lenge.c_str())+10); 
        } //         while(1)
        return -1; // Aenderung durchgefuehrt
      } //       if (*(*cerg+0))
      return 0; // kein Fehler, keine Aenderung noetig
    } //     while(cerg= spaltlen.HolZeile(),cerg?*cerg:0)
    return 6;
  } //   if (!spaltlen.obqueryfehler)
  return 7;
} // RS::machbinaer

inline string instyp::ersetze(const char *const u, const char* const alt, const char* const neu) 
{
  string erg;
  if (alt[0]==0 || !strcmp(alt,neu)) {
    erg.append(u);
  } else {
    for(char* p=(char*)u;*p;p++)  {
      char *pi = (char*)alt;
      int i=0,gleich=1;
      for(;*(pi+i);i++)
        if (*(pi+i)!=*(p+i))
        {gleich=0;break;}
      if (gleich) {erg+=neu;p+=i-1;} else erg+=(*p);
    } //     for(char* p=(char*)u;*p;p++)
  } //   if (alt[0]==0 || !strcmp(alt,neu)) else
  return erg;
} // ersetze(char *u, const char* alt, const char* neu)

inline string *instyp::sersetze( string *const src, string const& target, string const& repl) 
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
  } //   if (target.length())
  return src;
} // sersetze( string src, string const& target, string const& repl)


/*//
   instyp::instyp(DBSTyp eDBS, char* vfeld,char* vwert) KLA
   feld=vfeld;
//	wert=ersetze(ersetze(vwert,"\\","\\\\").c_str(),"\'","\\\'");
wert=sqlft(eDBS,vwert);
KLZ // instyp::instyp(char* vfeld,char* vwert) 

instyp::instyp(DBSTyp eDBS, char* vfeld,time_t zt) KLA
feld=vfeld;
		//pthread_mutex_lock(&printf_mutex);
//	sprintf(dbuf,"%d-%d-%d %d:%d:%d",zt.tm_year+1900,zt.tm_mon+1,zt.tm_mday,zt.tm_hour,zt.tm_min,zt.tm_sec);
		//pthread_mutex_unlock(&printf_mutex);
//	wert=dbuf;
wert=sqlft(eDBS,&zt);
KLZ // instyp::instyp(char* vfeld,struct tm zt) KLA
 */

void sqlft::ersetzalles()
{
////	if (this->find("Amato")!=string::npos) { //// <<"vor ersetzen: "<<blau<<c_str()<<schwarz; }
  ersetze("\\","\\\\");
  ersetze("\'","\\\'");
////	if (this->find("Amato")!=string::npos) { //// <<", nach ersetzen: "<<blau<<c_str()<<schwarz<<endl; }
} // void sqlft::ersetzalles

sqlft::sqlft(DBSTyp eDBS, const string& vwert):
  string(vwert) 
{
	ersetzalles();
  insert(0,1,dvb(eDBS));
  append(1,dve(eDBS));
} // sqlft::sqlft(DBSTyp eDBS, const string& vwert)

sqlft::sqlft(DBSTyp eDBS, const string *const vwert):
  string(*vwert) 
{
	ersetzalles();
  insert(0,1,dvb(eDBS));
  append(1,dve(eDBS));
} // sqlft::sqlft(DBSTyp eDBS, const string *vwert)

sqlft::sqlft(DBSTyp eDBS, const char* const vwert,const bool obzahl):
  string(vwert) 
{
  if (!obzahl) {
		ersetzalles();
		insert(0,1,dvb(eDBS));
    append(1,dve(eDBS));
  }
} // sqlft::sqlft(DBSTyp eDBS, char* vwert,bool obzahl)

sqlft::sqlft(DBSTyp eDBS, const char* const vwert,const char* const zs):
  string(vwert) 
{
	ersetzalles();
	insert(0,1,dvb(eDBS));
  insert(0,zs);
  append(1,dve(eDBS));
} // sqlft::sqlft(DBSTyp eDBS, char* vwert,char* zs)

string *sqlft::ersetze(const char* const alt, const char* const neu) 
{
  if (size()){
    string erg;
    ////	 erg.assign(1,c_str()[0]); // delimiter
    if (alt[0]==0 || !strcmp(alt,neu)) {
      erg=c_str();
    } else {
      erg.clear();
      for(char* p=(char*)c_str();*p;p++)  {
        char *pi = (char*)alt;
        int i=0,gleich=1;
        for(;*(pi+i);i++)
          if (*(pi+i)!=*(p+i))
          {gleich=0;break;}
        if (gleich) {erg+=neu;p+=i-1;} else erg+=(*p);
      }
    }
    this->assign(erg);
  } //   if (size())
  return this;
} // ersetze(char *u, const char* alt, const char* neu)

string *sqlft::sersetze( string *const src, string const& target, string const& repl) 
{
  if (target.length()) {
    if (src->length()) {
      size_t idx = 0;
      for (;;) {
        idx = src->find( target, idx);
        if (idx == string::npos)  break;
        src->replace( idx, target.length(), repl);
        idx += repl.length();
      }
    }
  }
  this->assign(*src);
  return this;
} // sersetze( string src, string const& target, string const& repl)

/*// 
   sqlft::sqlft(DBSTyp eDBS, time_t *tm):
   string(21,0) {
	 struct tm zt={0};
	 pthread_mutex_lock(&timemutex);
	 memcpy(&zt,localtime(tm),sizeof zt);
	 pthread_mutex_unlock(&timemutex);
	 pthread_mutex_lock(&printf_mutex);
	 sprintf((char*)c_str(),"%c%.4d-%.2d-%.2d %.2d:%.2d:%.2d%c",dvb(eDBS),zt.tm_year+1900,zt.tm_mon+1,zt.tm_mday,zt.tm_hour,zt.tm_min,zt.tm_sec,dve(eDBS));
		pthread_mutex_unlock(&printf_mutex);
   }
 */

sqlft::sqlft(DBSTyp eDBS, const time_t *tm): string(21,0)
{
  struct tm zt={0};
	pthread_mutex_lock(&timemutex);
	memcpy(&zt,localtime(tm),sizeof zt);
	pthread_mutex_unlock(&timemutex);
	druckeein(eDBS,&zt);
} // sqlft::sqlft(DBSTyp eDBS, time_t *tm): string(21,0)

sqlft::sqlft(DBSTyp eDBS, const chrono::system_clock::time_point* const tp): string(21,0)
{
	const time_t tpt = chrono::system_clock::to_time_t(*tp);
	pthread_mutex_lock(&timemutex);
//#define altzeit
#if not defined altzeit
//#define schoen
#if defined schoen
	strftime((char*)c_str(),length(),"%Y-%m-%d %X",localtime(&tpt));
	resize(19);
#else // schoen
	strftime((char*)c_str(),length(),"%Y%m%d%H%M%S",localtime(&tpt));
	resize(14);
#endif // schoen
	insert(0,1,dvb(eDBS));
	append(1,dve(eDBS));
	pthread_mutex_unlock(&timemutex);
#else // altzeit
  struct tm zt={0};
	memcpy(&zt,localtime(&tpt),sizeof zt);
	pthread_mutex_unlock(&timemutex);
	druckeein(eDBS,&zt);
#endif // altzeit
//// caus<<rot<<c_str()<<schwarz<<" "<<string_to_hex(c_str())<<" "<<length()<<" "<<size()<<endl;
}

void stmax(int *zahl,int stellen=2)
{
 int grenze=1;
 for(int ui=0;ui<stellen;ui++) grenze*=10;
 grenze-=1;
 while (*zahl>grenze) (*zahl)/=10;
} // void stmax(int *zahl,int stellen=2)

void sqlft::druckeein(DBSTyp eDBS, tm* const zt) 
{
	stmax(&zt->tm_year,4);
	stmax(&zt->tm_mon);
	stmax(&zt->tm_mday);
	stmax(&zt->tm_hour);
	stmax(&zt->tm_min);
	stmax(&zt->tm_sec);
		pthread_mutex_lock(&printf_mutex);
  sprintf((char*)c_str(),"%c%.4d-%.2d-%.2d %.2d:%.2d:%.2d%c",
	        dvb(eDBS),zt->tm_year+1900,zt->tm_mon+1,zt->tm_mday,zt->tm_hour,zt->tm_min,zt->tm_sec,dve(eDBS));
		pthread_mutex_unlock(&printf_mutex);
} // void sqlft::druckeein(DBSTyp eDBS, tm *zt)

sqlft::sqlft(DBSTyp eDBS, tm* const zt):
  string(21,0) 
{
  druckeein(eDBS,zt);
} // sqlft::sqlft(DBSTyp eDBS, tm *zt):

sqlft::sqlft(DBSTyp eDBS, const uchar c):
  string(1,0) 
{
		pthread_mutex_lock(&printf_mutex);
  sprintf((char*)c_str(),"%d",c);
		pthread_mutex_unlock(&printf_mutex);
}

sqlft::sqlft(DBSTyp eDBS, const char c):
	string(1,0) 
{
	pthread_mutex_lock(&printf_mutex);
	sprintf((char*)c_str(),"%d",c);
	pthread_mutex_unlock(&printf_mutex);
}

sqlft::sqlft(DBSTyp eDBS, const int i):
	string(21,0) 
{
		pthread_mutex_lock(&printf_mutex);
  sprintf((char*)c_str(),"%i",i);
		pthread_mutex_unlock(&printf_mutex);
  resize(strlen(c_str()));
}

sqlft::sqlft(DBSTyp eDBS, const long int i):
  string(21,0) 
{
		pthread_mutex_lock(&printf_mutex);
  sprintf((char*)c_str(),"%li",i);
		pthread_mutex_unlock(&printf_mutex);
  resize(strlen(c_str()));
}

sqlft::sqlft(DBSTyp eDBS, const unsigned int i):
  string(21,0) 
{
		pthread_mutex_lock(&printf_mutex);
  sprintf((char*)c_str(),"%u",i);
		pthread_mutex_unlock(&printf_mutex);
  resize(strlen(c_str()));
}

sqlft::sqlft(DBSTyp eDBS, const unsigned long int i):
  string(21,0) 
{
		pthread_mutex_lock(&printf_mutex);
  sprintf((char*)c_str(),"%lu",i);
		pthread_mutex_unlock(&printf_mutex);
  resize(strlen(c_str()));
}

sqlft::sqlft(DBSTyp eDBS, const long long int i):
  string(21,0) 
{
		pthread_mutex_lock(&printf_mutex);
  sprintf((char*)c_str(),"%llu",i);
		pthread_mutex_unlock(&printf_mutex);
  resize(strlen(c_str()));
} // sqlft::sqlft(DBSTyp eDBS, long long int i)

void DB::LetzteID(string *erg,const size_t aktc) 
{
  if (erg) {
    switch (DBS) {
      case MySQL:
        {
          RS rs(this,"select LAST_INSERT_ID()",aktc,/*obverb=*/1);
          *erg= *rs.HolZeile()[0];
        }
        break;
      case Postgres:
		  caup<<"hier letzteid"<<endl;
			exitp(26);
        break;
    } //     switch (DBS)
  } //   if (erg)
} // void DB::LetzteID(string *erg)

char* DB::tmtosql(tm *tmh,char* buf) 
{
  switch (DBS) {
    case MySQL:
			stmax(&tmh->tm_year,4);
			stmax(&tmh->tm_mon);
			stmax(&tmh->tm_mday);
		pthread_mutex_lock(&printf_mutex);
      sprintf(buf,"%.4d%.2d%.2d",tmh->tm_year+1900,tmh->tm_mon+1,tmh->tm_mday);
		pthread_mutex_unlock(&printf_mutex);
      break;
    case Postgres:
		  caup<<"hier tmtosql"<<endl;
			exitp(27);
      break;
  } //   switch (DBS)
  return buf;
} // char* DB::tmtosql(tm *tmh,char* buf)

//
char* DB::tmtosqlmZ(tm *tmh,char* buf) 
{
  switch (DBS) {
    case MySQL:
			stmax(&tmh->tm_year,4);
			stmax(&tmh->tm_mon);
			stmax(&tmh->tm_mday);
			stmax(&tmh->tm_hour);
			stmax(&tmh->tm_min);
			stmax(&tmh->tm_sec);
		pthread_mutex_lock(&printf_mutex);
      sprintf(buf,"%.4d%.2d%.2d%.2d%.2d%.2d",tmh->tm_year+1900,tmh->tm_mon+1,tmh->tm_mday,tmh->tm_hour,tmh->tm_min,tmh->tm_sec);
		pthread_mutex_unlock(&printf_mutex);
      break;
    case Postgres:
		  caup<<"hier tmtosql"<<endl;
			exitp(28);
      break;
  } //   switch (DBS)
  return buf;
} // char* DB::tmtosqlmZ(tm *tmh,char* buf) 

my_ulonglong DB::affrows(const size_t aktc) const
{ // affected rows
	my_ulonglong arows=0;
  switch (DBS) {
    case MySQL:
      arows = mysql_affected_rows(conn[aktc]);
      ////      if (arows==(my_ulonglong)-1) if (errno==1065) arows=0;
      return arows;
      break;
    case Postgres:
		  caup<<"hier affrows"<<endl;
			exitp(29);
      break;
  } //   switch (DBS)
  return arows=0;
} // my_ulonglong DB::affrows() { // affected rows
/*//
   char** DB::HolZeile() {
   switch (DBS) {
   case MySQL:
   row = mysql_fetch_row(result);
   return row;
   }
   return (char**)0;
   } // char** DB::HolZeile() {
 */

const char *cjj(const char * const* const* cerg, const int nr)
{
	if (*(*cerg+nr)) return *(*cerg+nr);
	return "";
}

// das Ergebnis ist z.B. folgendermaßen zu prüfen:
// char ***cerg=rs.HolZeile();
// if (cerg) // 0, wenn Fehler im SQL-Befehl
// if (*cerg) // 0, wenn keine Ergebniszeile
// if (*(*cerg+4)) // 0, wenn 5.Spalte in Ergebniszeile NULL
// if (*(*(*cerg+4))) // 0, wenn 5.Spalte in Ergebniszeile ""
// zuvor muss der Programmierer pruefen, ob 5 Spalten ausgewaehlt wurden (andernfalls kein Fehler)
// auch bei 0 Ergebniszeilen ist (cerg) wahr.
char*** RS::HolZeile() 
{
  switch (dbp->DBS) {
    case MySQL:
      if (!obqueryfehler)// Anfrage erfolgreich, Rückgabedaten werden verarbeitet
        if (result) {  // Es liegen Zeilen vor
					row = mysql_fetch_row(result);
          ////          lengths = mysql_fetch_lengths(result);
          return &row;
        }
      break;
    case Postgres:
		  caup<<"hier HolZeile"<<endl;
			exitp(30);
      break;
  }
  return (char***)0;
} // char** DB::HolZeile() {


RS::RS(const DB* const pdb,const string& table):dbp(pdb),aktc(0),table(table)
{
  setzzruck();
}

void RS::setzzruck() 
{
	if (0) {
		this->result=0;
#ifdef mitpostgres 
		this->pres=0;
#endif // mitpostgres
		// um bei wiederholten Abfragen vorher mysql_free_result aufrufen zu koennen
	}
	obqueryfehler=-1;
}

// wird aufgerufen im template RS::Abfrage
// fuer obverb gibt es die Stufen: -2 (zeige auch bei Fehlern nichts an), -1 (zeige SQL an), 0, 1
int RS::doAbfrage(const size_t aktc/*=0*/,int obverb/*=0*/,uchar asy/*=0*/,int oblog/*=0*/,string *idp/*=0*/,my_ulonglong *arowsp/*=0*/)
{
	int altobverb=obverb;
	const unsigned vlz=10; // Verlängerungszahl
	const unsigned maxversuche=3;
//	obverb=1;
	yLog(obverb>0?obverb-1:0,oblog,0,0,"%s%s()%s, aktc: %s%zu%s, obverb: %s%d%s, asy: %s%d%s, oblog: %s%d%s,\nsql: %s%s%s",blau,__FUNCTION__,schwarz,blau,aktc,schwarz,blau, obverb,schwarz,blau,asy,schwarz,blau,oblog,schwarz,blau,sql.c_str(),schwarz);
	fnr=0;
	int obfalsch{0};
	geaendert=0;
	// fuer wiederholten Abfragen
	//// <<"in doAbfrage: "<<blau<<sql<<schwarz<<endl;
	switch (dbp->DBS) {
		case MySQL:
			if (!obqueryfehler)  {
				abfragefertig();
				obqueryfehler=-1;
			}
			num_rows=0;
			num_fields=0;
			////      if (sql=="select column_name from information_schema.columns where table_schema='emails' and table_name = 'lmailbody' and extra = 'auto_increment'") {mysql_commit(dbp->conn[aktc]);} // sql="select 'ID'";
			//// <<"sql.c_str(): "<<sql.c_str()<<endl;
			if ((obverb>0)|oblog)
				fLog("SQL: '"+blaus+sql+schwarz+"'",obverb,oblog);
			if (!dbp->conn[aktc]) {
				fnr=9999;
				fehler=Txd[T_Datenbank_nicht_zu_oeffnen];
			} else {
				int hoerauf=0;
				string altsqlm;
				machstrikt(altsqlm,aktc);
				string usql;
				string* sqlp=&sql;
				for (unsigned versuche=0;versuche<maxversuche;versuche++) {
					if (versuche==maxversuche-1)
						exit(schluss(99,Txd[T_Versuche_in_doAbfrage_mehr_als]+ltoan(maxversuche),oblog));
					if (asy) {
						obfalsch=mysql_send_query(dbp->conn[aktc],sqlp->c_str(),sqlp->length());
					} else {
//						MYSQL_RES *res0=mysql_use_result(dbp->conn[aktc]);
//						mysql_free_result(res0);
						obfalsch=mysql_real_query(dbp->conn[aktc],sqlp->c_str(),sqlp->length());
					}
					resultused=0;
					//// <<"aktc: "<<blau<<aktc<<schwarz<<" in doAbfrage, sql: "<<blau<<sql<<schwarz<<endl;
					fnr=mysql_errno(dbp->conn[aktc]);
					fehler=mysql_error(dbp->conn[aktc]);
					if (obfalsch) {
						if (obverb>-2) {
							fLog("fnr: "+blaus+ltoan(fnr)+schwarz+", "+Txk[T_Fehler]+": "+blau+fehler+schwarz,1,1);
						}
						// Invalid use of NULL value; bei Spaltenverschiebungen kann oft NOT NULL nicht mehr geaendert werden
						if (idp) *idp="null";
						if (fnr==1138 && sqlp!=&usql) {
						  usql=boost::locale::to_upper(*sqlp, loc);
////							transform(sqlp->begin(),sqlp->end(),std::back_inserter(usql),::toupper);
							if ((!usql.find("ALTER TABLE") || !usql.find("CREATE TABLE")) && usql.find("NOT NULL")!=string::npos) {
								usql=caseersetze(*sqlp,"NOT NULL","");
								sqlp=&usql;
								continue;
							}
							break;
						} else if (fnr==1406) {
							// z.B. Fehler 1406 ("Data too long for column 'submid' at row 1") in doAbfrage, sql: INSERT INTO `outa` (erfolg,submt,transe,submid,fsize,    retries,rcfax,docname,idudoc,pages,adressat) SELECT t.erfolg,t.zp,t.zp,t.submid,t.size,t.tries,t.teln,IF(ISNULL(asp.original),'',asp.original),IF(ISNULL(asp.idudoc),0,asp.idudoc),IF(ISNULL(asp.pages),0,asp.pages),IF(ISNULL(asp.adressat) OR asp.adressat=t.teln,'',asp.adressat) FROM tmpcapi t LEFT JOIN `outa` a ON a.submid=t.submid LEFT JOIN `altspool` asp ON asp.capispooldatei=t.submid LEFT JOIN `outa` av ON av.erfolg<>0 AND av.idudoc=asp.idudoc AND av.idudoc<>0      WHERE ISNULL(a.submid) AND (t.erfolg<>0 OR ISNULL(av.idudoc)) GROUP BY t.submid
							// => Tabelle ermitteln, die die Spalte enthaelt, um 5 vergroessern oder in text umwandeln, dann continue
							size_t p1,p2;
							if ((p1=fehler.find("'")+1)) {
								if ((p2=fehler.find("'",p1)+1)) {
									const string col=fehler.substr(p1,p2-p1-1);
									string SQL=boost::locale::to_upper(sql, loc);
////									transform(sql.begin(),sql.end(),std::back_inserter(SQL),::toupper);
									string suchstr[2]={"INSERT INTO ","UPDATE "}; // Problem: "ON DUPLICATE KEY UPDATE"
									uchar neuerversuch=0;
									for(unsigned uru=0;uru<elemzahl(suchstr);uru++) {
										if ((p1=SQL.find(suchstr[uru]))!=string::npos) {
											p1+=suchstr[uru].length();
											if ((p2=SQL.find_first_of(" (",p1)+1)) {
												string tbl{sql.substr(p1,p2-p1-1)}; // wegen Groß- und Kleinschreibung
												anfzweg(&tbl);
												if (tbl.find_first_of(",='`")!=string::npos) continue;
												Tabelle aktt(dbp,tbl,aktc,obverb>0?obverb-1:0,oblog);
												for(unsigned spnr=0;spnr<aktt.spzahl;spnr++) { // reale Spalten
													if (aktt.spnamen[spnr]==col) {
														dbp->tuerweitern(tbl,col,atol(aktt.splenge[spnr].c_str())+vlz,aktc,obverb>0?obverb-1:0);
														versuche=0;
														neuerversuch=1;
														break;
													} // 													if (aktt.spnamen[spnr]==col)
													//                          if (db->spnamen
												} // 												for(unsigned spnr=0;spnr<aktt.spzahl;spnr++)
											} // 											if ((p2=SQL.find_first_of(" (",p1)+1))
										} // 										if ((p1=SQL.find(suchstr[uru]))!=string::npos)
									} // 									for(unsigned uru=0;uru<elemzahl(suchstr);uru++)
									if (neuerversuch)
										continue;
								} // 								if ((p2=fehler.find("'",p1)+1))
							} // 							if ((p1=fehler.find("'")+1))
						} else {
							break;
						} // 						else if (fnr==1406)
						// if (obfalsch)
					} else {
						obqueryfehler=0;
						result=mysql_store_result(dbp->conn[aktc]);
						resultused=1;
						if (result) {
							num_fields = mysql_num_fields(result);
							num_rows = mysql_num_rows(result);
						} // 						if (result)
						geaendert=mysql_affected_rows(dbp->conn[aktc]);
						if (arowsp) *arowsp=geaendert;
						if (idp) {
							*idp=ltoan(mysql_insert_id(dbp->conn[aktc]));
							fLog(" => mysql_insert_id: "+blaus+*idp+schwarz,obverb,oblog);
						}
						////			row = mysql_fetch_row(result);
						break;
					} // 					if (obfalsch) else
				} // 				while (1)
				if (obfalsch) {
					obqueryfehler=1;
					if (obverb>-2) {
						string aktcs=ltoan(aktc);
						fLog("aktc: "+drots+aktcs+": "+schwarz+Txd[T_Fehler_db]+drots+ltoan(fnr)+schwarz+" (\""+fehler+"\") in doAbfrage, sql: "+
								tuerkis+sql+schwarz,1,1);
					}
					if (!fehler.find("Disk full"))
						hoerauf=115;
				} // if (obfalsch)
        const unsigned altfnr=fnr;
				striktzurueck(altsqlm,aktc);
				fnr=altfnr;
				if (hoerauf) 
					exit(schluss(hoerauf,fehler,oblog));
			} // if (!db->conn[aktc]) else
			if (obqueryfehler) {
				//// pthread_mutex_lock(&printf_mutex);
				////	printf("Fehler %u: %s\n", fnr, fehler);
				//// pthread_mutex_unlock(&printf_mutex);
				if (obverb>-2)
					cerr<<Txd[T_Fehler_db]<<drot<<fnr<<schwarz<<Txd[T_bei_Abfrage]<<blau<<sql<<schwarz<<": "<<endl<<drot<<fehler<<schwarz<<endl;
			}
			break;
		case Postgres:
#ifdef mitpostgres 
			const string ausfstr= "Ausfuehr: "+sql;
			fLog(ausfstr+" ...",obverb?1:0,0);
			pres = PQexec(db->pconn, sql.c_str());
			fnr=PQresultStatus(pres);
			if (fnr == PGRES_COMMAND_OK){
				fLog(ausfstr+" ok",obverb==-2?0:obverb,0);
			} else {
				if ((obverb&&obverb!=-2)||oblog) {
					fehler=PQresultErrorMessage(pres);
					if (fehler.find("existiert bereits")!=string::npos) {
						fLog(ausfstr+" existierte bereits",obverb,oblog);
					} else {
						uchar zeiggenau=1;
						////						if (zeigexn) KLA
						if (fehler.find("existiert nicht")!=string::npos) {
							fLog(ausfstr+" existierte nicht",obverb,oblog);
							zeiggenau=0;
						}
						////						KLZ
						if (zeiggenau) {
							//	 fLog("\b\b\b",logscreen?-1:0,0);
							fLog(ausfstr+"mit \""+rot+PQresStatus(PQresultStatus(pres))+schwarz+"\" gescheitert, \nFehlermeldung: '"+rot+fehler+schwarz,1,1);
						} // (errmsg.find("existiert bereits")!=-1)
					}  
				} // (logscreen||oblog)) KLAA
			} // (pres != PGRES_COMMAND_OK && (logscreen||oblog)) KLAA
			if (betroffen) *betroffen=PQcmdTuples(pres);
			PQclear(pres);
#endif // mitpostgres
			break;
	} // 	switch (db->DBS)
	obverb=altobverb;
	return (int)obqueryfehler;
} // RS::doAbfrage

/*//
	int RS::Abfrage(string psql,int obverb) KLA
	this->sql=psql;
	return doAbfrage(obverb);
	KLZ
 */

RS::RS(const DB* const pdb,const char* const psql,const size_t aktc,int obverb,uchar asy/*=0*/,int oblog/*=0*/,string* idp/*=0*/,my_ulonglong *arowsp/*=0*/):dbp(pdb),aktc(aktc)
{
	setzzruck();
	Abfrage(psql,aktc,obverb,asy,oblog,idp,arowsp);
} // RS::RS(const DB* pdb,const char* const psql,const size_t aktc,int obverb) 

RS::RS(const DB* const pdb,stringstream psqls,const size_t aktc,int obverb,uchar asy/*=0*/,int oblog/*=0*/,string* idp/*=0*/,my_ulonglong *arowsp/*=0*/):dbp(pdb),aktc(aktc)
{
	const string ueber=psqls.str();
	setzzruck();
	Abfrage(ueber,aktc,obverb,asy,oblog,idp,arowsp);
} // RS::RS(const DB* pdb,stringstream psqls,const size_t aktc,int obverb) 

RS::RS(const DB* const pdb,const string& psql,const size_t aktc,int obverb,uchar asy/*=0*/,int oblog/*=0*/,string* idp/*=0*/,my_ulonglong *arowsp/*=0*/):dbp(pdb),aktc(aktc)
{
	setzzruck();
	Abfrage(psql,aktc,obverb,asy,oblog,idp,arowsp);
} // RS::RS(const DB* pdb,const string& psql,const size_t aktc,int obverb) 

void RS::abfragefertig()
{
	if (!resultused) {
		result=mysql_use_result(dbp->conn[aktc]);
		resultused=1;
	}
	if (result) {
		mysql_free_result(result);
		result=0;
	}
	// das Folgende half bei wiederholten View-Erstellungen ( mit drop view ...; create ...)
	for(;!mysql_next_result(dbp->conn[aktc]);) { // https://stackoverflow.com/questions/614671/commands-out-of-sync-you-cant-run-this-command-now
		if ((result=mysql_use_result(dbp->conn[aktc]))) {
			mysql_free_result(result);
		}
	}
	resultused=0;
}

RS::~RS() 
{
	if (dbp)
		switch (dbp->DBS) {
			case MySQL:
				abfragefertig();
				break;
			case Postgres:
				caup<<"hier ~RS"<<endl;
				exitp(30);
				break;
		}
} // RS::~RS() 

void RS::machstrikt(string& altsqlm,const size_t aktc/*=0*/)
{
	//		MYSQL_ROW row;
	char **cer;
	fnr=0;
	const string showv="SHOW VARIABLES LIKE 'sql_mode'",
				setzv="SET sql_mode = 'STRICT_ALL_TABLES'";
	if (!mysql_real_query(dbp->conn[aktc],showv.c_str(),showv.length())) {
		if (MYSQL_RES *dbres=mysql_store_result(dbp->conn[aktc])) {
			cer=mysql_fetch_row(dbres); 
			if (cer && *(cer+1)) {
				altsqlm=*(cer+1);
			}
			mysql_free_result(dbres);
			mysql_real_query(dbp->conn[aktc],setzv.c_str(),setzv.length());
		} // 	  if ((result=mysql_store_result(dbp->conn[aktc])))
	} // 	if (!mysql_real_query
} // void RS::machstrikt(string& altsqlm,const size_t aktc/*=0*/)

void RS::striktzurueck(string& altsqlm,const size_t aktc/*=0*/)
{
	fnr=0;
	if (!altsqlm.empty()) {
		const string ruecksetz="SET sql_mode = '"+altsqlm+"'";
		if (!mysql_real_query(dbp->conn[aktc],ruecksetz.c_str(),ruecksetz.length())) {
			if (MYSQL_RES *dbres=mysql_store_result(dbp->conn[aktc]))
			mysql_free_result(dbres);
		}
	}
}

// in tbins
uchar RS::holautofeld(const size_t aktc, int obverb)
{
	if (autofeld.empty()) {
		stringstream aut;
		aut/*idp*/<<"SELECT column_name FROM information_schema.columns WHERE table_schema='"<<dbp->dbname<<
			"' AND table_name = '"<<table<<"' AND extra = 'auto_increment'";
		Abfrage(aut.str().c_str(),aktc,obverb>0?obverb-1:0);
		if (!obqueryfehler) {
			char*** erg= HolZeile();
			if (*erg) {
				//				autofeld=*HolZeile()[0];
				autofeld=*erg[0];
			} else {
				return 1; // z.B. Datenbank oder Tabelle nicht vorhanden, kein auto_increment-Feld
			}
		}
		return obqueryfehler;
	}
	return 0;
} // uchar RS::holautofeld(const size_t aktc, int obverb)

// fuer obverb gibt es die Stufen: -2 (zeige auch bei Fehlern nichts an), -1 (zeige SQL an), 0, 1
my_ulonglong RS::tbupd(const vector<instyp>& einf,int obverb, const string& bedingung,const size_t aktc/*=0*/,uchar asy/*=0*/) 
{
	ulong locks=0;
	fnr=0;
	my_ulonglong zl=0;
	switch (dbp->DBS) {
		case MySQL:
      isql=string("UPDATE ")+dbp->dnb+table+dbp->dne+" SET ";// string( hier nicht streichen!
      for(unsigned i=0;i<einf.size();i++) {
        isql+=dbp->dnb+einf[i].feld+dbp->dne;
        isql+=" = ";
        if (einf[i].obkeinwert)
          if (einf[i].wert.find(' ')==string::npos)
            isql+=(einf[i].wert); // z.B. `althyla` = null
          else
            isql+=dbp->dnb+(einf[i].wert)+dbp->dne; // z.B. `althyla`=`hyla`
        else
          isql+=(einf[i].wert);
        if (i<einf.size()-1)
          isql+=", ";
      } //       for(unsigned i=0;i<einf.size();i++)
      isql+=" WHERE ";
      isql+=bedingung;
      //// <<blau<<isql<<schwarz<<endl;
      break;
    case Postgres:
		  caup<<"hier update 1"<<endl;
			exitp(31);
      break;
  } // switch (dbp->DBS) 

  switch (dbp->DBS) {
    case MySQL:
      {
        string altsqlm;
				machstrikt(altsqlm,aktc);
        for (int iru=0;iru<2;iru++) { // interne Runde
          Abfrage(isql,aktc,obverb,asy,/*oblog*/0,/*idp*/0,&zl);
          if (!obqueryfehler) {
						// nach Gebrauch loeschen
						isql.clear();
						break;
          }  else {
            fLog(tuerkiss+"SQL: "+schwarz+isql,iru||(fnr!=1213&&fnr!=1366),1);
            const string fmeld=mysql_error(dbp->conn[aktc]);
            fLog(mysql_error(dbp->conn[aktc]),iru||(fnr!=1213&&fnr!=1366),1);
            if (fnr==1213) { // Deadlock found
              locks++;
              ////              "locks: "<<drot<<locks<<endl;
              mysql_commit(dbp->conn[aktc]);
              continue;
            } else if (fnr==1366) { // Incorrect string value
              dbp->machbinaer(table,aktc,fmeld,0);
            } else {
              cout<<rot<<Txk[T_Fehler]<<schwarz<<fnr<<Txd[T_bei_sql_Befehl]<<isql<<endl;
              break; 
            } //             if (fnr==1213) else else
          } //   if (!obqueryfehler) else
        } //  for (int iru=0;iru<2;iru++) 
				striktzurueck(altsqlm,aktc);
      } // case
      break;
    case Postgres:
		  caup<<"hier update 2"<<endl;
			exitp(32);
      break;
  } //   switch (dbp->DBS)
	return zl;
} // void RS::update(const string& table, vector<instyp> einf,int obverb, const string& bedingung,uchar asy) 

/*
	 sammeln=1 mit Puffer (isql) anfangen
	 sammeln=0 ohne Puffer/Puffer auf Datenbank schreiben
 */
// fuer obverb gibt es die Stufen: -2 (zeige auch bei Fehlern nichts an), -1 (zeige SQL an), 0, 1
my_ulonglong RS::tbins(vector<instyp>* einfp,const size_t aktc/*=0*/,uchar sammeln/*=0*/,
		int obverb/*=0*/,string *const idp/*=0*/,const uchar eindeutig/*=0*/,const svec& eindfeld/*=nix*/,const uchar asy/*=0*/,svec *csets/*=0*/,uchar mitupd/*=0*/) 
{
	if (obverb!=-2) 
		fLog(violetts+"tbins: "+blau+table+" "+schwarz+", obverb: "+ltoan(obverb),obverb,0);
	my_ulonglong zl=0;
	ulong locks=0;
	uchar obhauptfehl=0;
	fnr=0;
	//1. falls 0, dann auch Kopfzeile nicht behandeln, 2. falls Maxzaehler erreicht, dann Zwischeneinfuegen
	const int maxzaehler=100; // wg. Performance: Maximalzahl fuer Sammelinsert
	// <<"insert in "<<drot<<table<<schwarz<<" anfangen: "<<(int)anfangen<<" sammeln: "<<(int)sammeln<<endl;
	uchar obeinfuegen{1}; // Datensatz einfuegen, da noch nicht vorhanden
	uchar anfangen{isql.empty()};
	/*//
		if (einfp->empty()) if (sammeln || anfangen)
		exit(33); // notwendiger Parameter fehlt
	// <<"nach exit(34)"<<endl;
	 */
	if (idp) idp->clear();
	if (dochanfangen) {
		anfangen=1;
		dochanfangen=0;
	} //   if (dochanfangen)
	if (anfangen)
		zaehler=0;
	////  if (sammeln || (!sammeln && !anfangen)) 
	////<<"in insert, anfangen: "<<(int)(anfangen||dochanfangen)<<", sammeln: "<<(int)sammeln<<"\n";
	if (anfangen) {
		if (maxl) {
			delete[] maxl; maxl=0;
		}
	} //   if (anfangen)
	if (einfp) if (einfp->size()) {
		if (!maxl) {
			maxl= new unsigned long[einfp->size()];
			for (unsigned long k=0;k<einfp->size();k++){
				maxl[k]=0;
			}
		} //   if (!maxl)
		for (unsigned long k=0;k<einfp->size();k++){
			if (einfp->at(k).wert.length()>maxl[k]) {
				maxl[k]=einfp->at(k).wert.length();
			}
		} //   for (unsigned long k=0;k<einfp->size();k++)
		if (eindeutig) {
			stringstream aut; // , autid;
			////    RS autrs(dbp);
			switch (dbp->DBS) {
				case MySQL:
					obhauptfehl=holautofeld(aktc,obverb);
					if (!autofeld.empty()) {
						// Datensatz schon vorhanden?
						aut.str(std::string()); aut.clear();
						aut<<"SELECT `"<<autofeld<<"` FROM `"<<table<<"` WHERE ";
						for(unsigned i=0;i<einfp->size();i++){
							if (i) aut<<" AND ";
							aut<<dbp->dnb<<einfp->at(i).feld<<dbp->dne<<"="<<einfp->at(i).wert;
						}
						Abfrage(aut.str(),aktc,obverb>0?obverb-1:0);
						if (!obqueryfehler) {
							char*** erg= HolZeile();
							if (*erg) {
								if (idp) {
									//// <<"1 idp: "<<*idp<<", aut.str(): "<<aut.str()<<endl;
									*idp=*erg[0];
									//// <<"2 idp: "<<*idp<<", aut.str(): "<<aut.str()<<endl;
								}
								obeinfuegen=0;
							} //             if (*erg)
							break;
							// Feld zu kurz
						} else {
							fLog(string(Txd[T_Fehler_beim_Pruefen_auf_Vorhandensein_des_Datensatzes])+mysql_error(dbp->conn[aktc]),1,1);
						} // (!obqueryfehler)
					} // (!obqueryfehler)
					break;
				case Postgres:
					caup<<"hier insert 1"<<endl;
					exitp(35);
					break;
			} // switch (dbp->DBS)
		} // eindeutig
		if (eindfeld.size()) {
			string abfr;
			for(unsigned i=0;i<einfp->size();i++){
				if (!strcasecmp(einfp->at(i).feld.c_str(),eindfeld[0].c_str())) {
					abfr="SELECT 1 FROM `"+table+"` WHERE `"+einfp->at(i).feld+"`="+einfp->at(i).wert;
					break;
				} // 			if (!strcasecmp(einfp->at(i).feld.c_str(),eindfeld[0].c_str()))
			} // 		for(unsigned i=0;i<einfp->size();i++)
			for(unsigned j=1;j<eindfeld.size();j++) {
				for(unsigned i=0;i<einfp->size();i++){
					if (!strcasecmp(einfp->at(i).feld.c_str(),eindfeld[j].c_str())) {
						abfr+=" AND `"+einfp->at(i).feld+"`="+einfp->at(i).wert;
						break;
					} // 				if (!strcasecmp(einfp->at(i).feld.c_str(),eindfeld[j].c_str()))
				} // 			for(unsigned i=0;i<einfp->size();i++)
			} // 		for(unsigned j=1;j<eindfeld.size();j++)
			if (!abfr.empty()) {
				Abfrage(abfr,aktc,obverb>0?obverb-1:0);
				if (!obqueryfehler) {
					char*** erg=HolZeile();
					if (*erg) {
						obeinfuegen=0;
					}
				} // 				if (!obqueryfehler)
			} // 		if (!abfr.empty())
		} // 	if (eindfeld.size())
		if (obeinfuegen) {
			if (einfp->size()) zaehler+=1;
			if (!anfangen && zaehler==maxzaehler) {
				sammeln=0;
				dochanfangen=1;
			} //     if (!anfangen && zaehler==maxzaehler)
		} //   if (obeinfuegen)

		if (anfangen) {
			switch (dbp->DBS) {
				case MySQL:
					isql=string("INSERT INTO ")+dbp->dnb+table+dbp->dne+'('; // string( hier nicht streichen!
					for(unsigned i=0;i<einfp->size();i++) {
						if (i) isql+=',';
						isql+=dbp->dnb+einfp->at(i).feld+dbp->dne;
					}
					isql+=")VALUES(";
					break;
				case Postgres:
					caup<<"hier insert 2"<<endl;
					exitp(36);
					break;
			} // switch (dbp->DBS) 
		} // if (obeinfuegen)

		if (obeinfuegen) {
			switch (dbp->DBS) {
				case MySQL:
					////				isql.reserve(isql.length()+2);
					if (einfp->size()) {
						if (zaehler>1) isql+=",(";
						for(unsigned i=0;i<einfp->size();i++) {
							if (i) {
								////						isql.reserve(isql.length()+1);
								isql+=',';
							} //           if (i)
							////					isql.reserve(isql.length()+2+strlen(einfp->at(i).wert.c_str()));
							////          if (einfp->at(i).feld=="EML") KLA isql+="_utf8"; KLZ
							isql+=(einfp->at(i).wert);
						} //         for(unsigned i=0;i<einfp->size();i++)
						////				isql.reserve(isql.length()+2);
						isql+=")";
					} // 				if (einfp->size())
					if (mitupd) {
						isql+=" ON DUPLICATE KEY UPDATE ";
						for(unsigned i=0;i<einfp->size();i++) {
							if (i) isql+=',';
							isql+=dbp->dnb+einfp->at(i).feld+dbp->dne+'='+einfp->at(i).wert;
						}
					} // 					if (mitupd)
					break;
				case Postgres:
					caup<<"hier insert 3"<<endl;
					exitp(37);
					break;
			} // switch (dbp->DBS) 
		} // if (obeinfuegen)
	} // 	if (einfp)

	if (!sammeln)if (zaehler) {
		switch (dbp->DBS) {
			case MySQL:
				{
					string altsqlm;
					machstrikt(altsqlm,aktc);
					// interne Runde
					for (int iru=0;iru<2;iru++) {
						for(size_t iiru=0;iiru<(csets?csets->size():1);iiru++) {
							if (csets)
								RS zs(dbp,"SET NAMES '"+csets->at(iiru)+"'",aktc,obverb>0?obverb-1:0);
							Abfrage(isql,aktc,obverb,asy,/*oblog*/0,idp,&zl);
							if (csets) if (iiru)
								RS zs(dbp,"SET NAMES '"+csets->at(0)+"'",aktc,obverb>0?obverb-1:0);
							if (!fnr) break;
						} // 						for(size_t iiru=0;iiru<(csets?csets->size():1);iiru++)
						/*
						//<<violett<<"vor idp"<<schwarz<<endl;
						if (idp) {
						//<<violett<<"in idp"<<schwarz<<", aktc: "<<aktc<<endl;
						if (obqueryfehler) *idp="null";
						else *idp=ltoan(mysql_insert_id(dbp->conn[aktc]));
						//<<"idp: "<<*idp<<endl;
						} // if (idp)
						 */
						//// <<gruen<<"zaehler: "<<(int)zaehler<<", obqueryfehler: "<<(int)obqueryfehler<<schwarz<<endl;
						if (!obqueryfehler) {
							break;
						}  else {
							fLog(tuerkiss+"SQL: "+schwarz+"\n"+isql+"\n",iru||(fnr!=1213&&fnr!=1366),0);
							const string fmeld{mysql_error(dbp->conn[aktc])};
							fLog(fmeld,iru||(fnr!=1213&&fnr!=1366),0);
							if (fnr==1213){ // Deadlock found
								locks++;
								////              "locks: "<<drot<<locks<<endl;
								mysql_commit(dbp->conn[aktc]);
								continue;
							} else if (fnr==1366) { // Incorrect string value
								dbp->machbinaer(table,aktc,fmeld,0);
							} else {
								exit(schluss(113,rots+Txk[T_Fehler]+schwarz+ltoan(fnr)+Txd[T_bei_sql_Befehl]+isql));
								break; 
							} // if (fnr==1213) else else
						} //             if (idp) else else else
					} //  for (int iru=0;iru<2;iru++) 
					striktzurueck(altsqlm,aktc);
				} // case MySQL
				break;
			case Postgres:
				caup<<"hier insert 4"<<endl;
				exitp(38);
				break;
		} // 		switch (dbp->DBS)
	}  // if (!sammeln)if (zaehler)
	if (!sammeln) {
		// nach Gebrauch loeschen
		isql.clear();
		if (!obhauptfehl){
			if (maxl) {
				delete[] maxl; maxl=0;
			}
		} //   if (!obhauptfehl)
	} // if (!sammeln)
	return zl;
} // my_ulonglong DB::tbins(vector<instyp>* einfp,const char** erg,int anfangen=1,int sammeln=0) 

void DB::prueffunc(const string& pname, const string& body, const string& para, const size_t aktc, int obverb, int oblog)
{
  fLog(violetts+Txd[T_prueffunc]+schwarz+" "+pname,obverb,oblog);
  const string mhost = host=="localhost"?host:"%";
  const string owner="`"+user+"`@`"+mhost+"`";
  for(uchar runde=0;runde<2;runde++) {
    uchar fehlt=1;
		RS rs0(this,"SHOW FUNCTION STATUS WHERE db='"+dbname+"' AND name='"+pname+"';",aktc,obverb);
		if (!rs0.obqueryfehler) {
			if (rs0.result->row_count){
				RS rs(this,"SHOW CREATE FUNCTION `"+pname+"`",aktc,obverb);
				char ***cerg;
				while (cerg=rs.HolZeile(),cerg?*cerg:0) {
					for(unsigned i=1;i<=2;i++) {
						if (*(*cerg+i)) if (strstr(*(*cerg+i),body.c_str())) if (strstr(*(*cerg+i),owner.c_str())) {
							fehlt=0;
							break; // for(unsigned
						} // 						if (*(*cerg+i)) if (strstr(*(*cerg+i),body.c_str())) if (strstr(*(*cerg+i),owner.c_str()))
					} // 					for(unsigned i=1;i<=2;i++)
					break; // while(cerg=
				} // 				while (cerg=rs.HolZeile(),cerg?*cerg:0)
			} // 			if (rs0.result->row_count)
		} // 		if (!rs0.obqueryfehler)
    ////   RS rs(this,"select definer from mysql.proc where definer like '`"+user+"`@`"+mhost+"`'",ZDB);
    if (fehlt) {
      DB *aktMyp;
      if (!runde) aktMyp=this; else {
        /*2*/DB MySup(DBS,this->host.c_str(),"root",this->rootpwd.c_str(),/*conz*/1,this->dbname.c_str(),0,0,0,obverb,oblog);
        aktMyp=&MySup;
      }
      string proc= "DROP FUNCTION IF EXISTS `"+pname+"`";
      RS rs0(aktMyp, proc,aktc,obverb);
      proc = "CREATE DEFINER="+owner+" FUNCTION `"+pname+"`\n"+para+body;
      RS rs1(aktMyp, proc,aktc,obverb);
    } else 
      break; // for(uchar runde=0
  } //   for(uchar runde=0;runde<2;runde++)
} // void DB::prueffunc(const string& pname, const string& body, const string& para, int obverb, int oblog)

void RS::dsclear()
{
  sql.clear();
  obqueryfehler=-1;
  fehler.clear();
  fnr=0;
	if (result) mysql_free_result(result);
  result=0;
  row=NULL;
  num_fields=0;
  // table.clear();
  feld.clear();
  typ.clear(); 
  lenge.clear();
  prec.clear();
  kommentar.clear();
	isql.clear();
} // clear

void dhcl::virtinitopt()
{
	opn<<new optcl(/*pname*/"host",/*pptr*/&host,/*part*/pstri,T_host_k,T_host_l,/*TxBp*/&Txd,/*Txi*/T_verwendet_die_Datenbank_auf_Host_string_anstatt_auf,/*wi*/1,/*Txi2*/-1,/*rottxt*/nix,/*wert*/-1,/*woher*/!host.empty(),T_Host_fuer_MySQL_MariaDB_Datenbank);
	opn<<new optcl(/*pname*/"muser",/*pptr*/&muser,/*part*/pstri,T_muser_k,T_muser_l,/*TxBp*/&Txd,/*Txi*/T_verwendet_fuer_MySQL_MariaDB_den_Benutzer_string_anstatt,/*wi*/1,/*Txi2*/-1,/*rottxt*/nix,/*wert*/-1,/*woher*/!muser.empty(),T_Benutzer_fuer_MySQL_MariaDB);
	opn<<new optcl(/*pname*/"mpwd",/*pptr*/&mpwd,/*part*/ppwd,T_mpwd_k,T_mpwd_l,/*TxBp*/&Txd,/*Txi*/T_verwendet_fuer_MySQL_MariaDB_das_Passwort_string,/*wi*/1,/*Txi2*/-1,/*rottxt*/nix,/*wert*/-1,/*woher*/!mpwd.empty(),T_Passwort_fuer_MySQL_MariaDB);
	opn<<new optcl(/*pname*/"datenbank",/*pptr*/&dbq,/*part*/pstri,T_db_k,T_datenbank_l,/*TxBp*/&Txd,/*Txi*/T_verwendet_die_Datenbank_string_anstatt,/*wi*/1,/*Txi2*/-1,/*rottxt*/nix,/*wert*/-1,/*woher*/!dbq.empty(),T_Datenbankname_fuer_MySQL_MariaDB_auf);
//	opn<<optcl(/*pname*/"tabl",/*pptr*/&tabl,/*art*/pstri,T_tb_k,T_tabelle_l,/*TxBp*/&Txd,/*Txi*/T_verwendet_die_Tabelle_string_anstatt,/*wi*/1,/*Txi2*/-1,/*rottxt*/nix,/*wert*/-1);
	opn<<new optcl(/*pptr*/&ZDB,/*art*/puchar,T_sqlv_k,T_sql_verbose_l,/*TxBp*/&Txd,/*Txi*/T_Bildschirmausgabe_mit_SQL_Befehlen,/*wi*/1,/*Txi2*/-1,/*rottxt*/nix,/*wert*/-1,/*woher*/1);
	hcl::virtinitopt();
} // void hhcl::virtinitopt

dhcl::dhcl(const int argc, const char *const *const argv,const char* const DPROG,const uchar mitcron):hcl(argc,argv,DPROG,mitcron)
{
}

// wird aufgerufen in: virtrueckfragen, parsecl, virtlieskonfein, hcl::hcl nach holsystemsprache
void dhcl::virtlgnzuw()
{
	hcl::virtlgnzuw();
	Txd.lgn=Txk.lgn;
} // void hhcl::virtlgnzuw

// wird aufgerufen in: main 
int dhcl::initDB()
{
	hLog(violetts+"initDB(), db: "+blau+dbq+schwarz);
	unsigned int fehler=0;
	if (dbq.empty()) {
		fehler=1046;
	} else {
		if (!My) {
			My=new DB(myDBS,host,muser,mpwd,maxconz,dbq,/*port=*/0,/*unix_socket=*/0,/*client_flag=*/CLIENT_MULTI_STATEMENTS,obverb,oblog);
			if (My->ConnError) {
				delete My;
				My=0;
			} else {
				My->lassoffen=1;
			} // 			if (My->ConnError) else
		} // 		if (!My)
		fehler=My->fehnr;
	} // 	if (dbq.empty())
	if (fehler) {
		hLog(rots+Txd[T_Verbindung_zur_Datenbank_nicht_herstellbar]+schwarz+ltoan(fehler)+rot+Txd[T_Breche_ab]+schwarz);
		return 1;
	} //   if (My->fehnr)
	return 0;
} // initDB

// wird aufgerufen in virtrueckfragen
int dhcl::pruefDB(const string& db)
{
	hLog(violetts+Txk[T_pruefDB]+db+")"+schwarz);
	unsigned fehnr{0};
	if (!My) {
		My=new DB(myDBS,host,muser,mpwd,maxconz,db,0,0,0,obverb,oblog,DB::defmycharset,DB::defmycollat,3,0);
		fehnr=My->fehnr;
		if (My->ConnError) {
			delete My;
			My=0;
		}else {
			My->lassoffen=1;
		}
	} // 	if (!My)
	return (fehnr); 
} // pruefDB

dhcl::~dhcl()
{
} // dhcl::~dhcl

// wird aufgerufen in: main
void dhcl::virtrueckfragen()
{
	if (rzf) {
		host=Tippstr(Txd[T_Host_fuer_MySQL_MariaDB_Datenbank],&host);
		const string Frage{Txd[T_Benutzer_fuer_MySQL_MariaDB]};
		muser=Tippstr(Frage.c_str(),&muser);
		string mpw2;
		mpwd.clear();
		do {
			mpwd=Tippstr(string(Txd[T_Passwort_fuer_MySQL_MariaDB])+Txk[T_fuer_Benutzer]+dblau+muser+schwarz+"'"/*,&mpwd*/);
			mpw2=Tippstr(string(Txd[T_Passwort_fuer_MySQL_MariaDB])+Txk[T_fuer_Benutzer]+dblau+muser+schwarz+"'"+" ("+Txk[T_erneute_Eingabe]+")"/*,&mpw2*/);
		} while (mpwd!=mpw2);
		dbq=Tippstr(string(Txd[T_Datenbankname_fuer_MySQL_MariaDB_auf])+dblau+host+schwarz+"'",&dbq);
		//		tabl=Tippstr(string(Txd[T_Tabellenname_in])+dblau+dbq+schwarz+"'",&tabl);
	} // if (rzf)
	// hcl::virtrueckfragen(); // wegen der Abfragereihenfolge lieber vorne reinschreiben
} // void hhcl::virtrueckfragen()

// wird aufgerufen in lauf
void dhcl::virtVorgbAllg()
{
	host="localhost";
	hcl::virtVorgbAllg();
} // void hhcl::virtVorgbAllg

// wird aufgerufen in lauf
void dhcl::pvirtVorgbSpeziell()
{
} // void hhcl::pvirtVorgbSpeziell

// wird aufgerufen in lauf
void dhcl::virtMusterVorgb()
{
	hcl::virtMusterVorgb();
} // void hhcl::virtMusterVorgb

// wird aufgerufen in lauf
void dhcl::virtzeigversion(const string& ltiffv/*=nix*/)
{
	hcl::virtzeigversion(ltiffv);
} // void virtzeigversion

// wird aufgerufen in lauf
void dhcl::virtschlussanzeige()
{
	hcl::virtschlussanzeige();
}

void instyp::ausgeb()
{
	cout<<Txd[T_Feld]<<blau<<feld<<schwarz<<Txd[T_Wertma]<<blau<<wert<<"'"<<schwarz<<endl;
}

void insv::ausgeb()
{
	cout<<Txd[T_Tabelle]<<blau<<*itabp<<schwarz<<endl;
	for(instyp i:ivec) {
		i.ausgeb();
	}
} // void insv::ausgeb()

insv::insv(DB *My,const string& itab,const size_t aktc,const uchar eindeutig,const svec& eindfeld,const uchar asy,svec *csets):My(My),itabp(&itab),aktc(aktc),eindeutig(eindeutig),eindfeld(eindfeld),asy(asy),csets(csets)
{
	rsp=new RS(My,itab);
}

my_ulonglong insv::schreib(const uchar sammeln/*=0*/,int obverb/*=0*/,string* const idp/*=0*/,uchar mitupd/*=0*/)
{
	my_ulonglong erg=0;
	if (ivec.size()) {
		erg=rsp->tbins(&ivec,aktc,sammeln,obverb,idp,eindeutig,eindfeld,asy,csets,mitupd);
		if (rsp->fnr) {
			fLog(Txd[T_Fehler_af]+drots+ltoan(rsp->fnr)+schwarz+Txk[T_bei]+tuerkis+rsp->sql+schwarz+": "+blau+rsp->fehler+schwarz,1,1);
		} //         if (runde==1)
		ivec.clear();
	}
	return erg;
}

my_ulonglong insv::ergaenz(const string& bedingung,const uchar sammeln/*=0*/,int obverb/*=0*/,string* const idp/*=0*/)
{
	my_ulonglong erg=0;
	// <<"Bedingung: "<<bedingung<<endl;
	if (ivec.size()) {
		rsp->holautofeld(aktc,obverb);
		const string gesbed=rsp->autofeld+"='"+bedingung+"'";
		// <<"Gesbed: "<<gesbed<<endl;
		erg=rsp->tbupd(ivec,obverb,gesbed,aktc,asy);
		if (rsp->fnr) {
			fLog(Txd[T_Fehler_af]+drots+ltoan(rsp->fnr)+schwarz+Txk[T_bei]+tuerkis+rsp->sql+schwarz+": "+blau+rsp->fehler+schwarz,1,1);
		} //         if (runde==1)
		ivec.clear();
	}
	return erg;
}

void insv::clear() {
	ivec.clear();
}

void insv::zeig(const char* const wo) {
	fLog(Txd[T_Zeige]+blaus+*itabp+schwarz+Txd[T_an_Position]+blau+wo+schwarz,1,0);
	for(size_t i=0;i<ivec.size();i++) {
		fLog(violetts+"i: "+gruen+ltoan(i)+": "+schwarz+ivec[i].feld+": '"+blau+ivec[i].wert+"'"+schwarz,1,0);
	}
}
