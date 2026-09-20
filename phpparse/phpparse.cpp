#include <sys/stat.h> // stat, lstat, S_IFMT, S_IFDIR ...
#include <string.h> // strcpy, strtok_r, strerror, memcmp, strcmp, strstr, 
#include <sys/time.h> // für gettimeofday()
#include <iostream> // cerr, cout
#include <errno.h> // errno, ENOENT
#include <fstream> // fstream
#include <vector> // vector
#include <stdio.h> // rename, perror, sprintf
#include <unistd.h> // link, unlink, chown
using namespace std;

// traegt Inhalt von datalist.txt formatiert in anzeig.php ein, falls ersteres neuer
// Aufruf: phpparse [Verzeichnis]   (Vorgabe: /srv/www/htdocs/php/)
int main(int argc, char** argv)
{
  // q=Quelle, v=Vorlage, z=Ziel
  char tbuf[45], obnoetig;
//  const string verzq="/DATA/down/";
  string verz="/srv/www/htdocs/php/";
  if (argc>1) {
    verz=argv[1];
    if (verz.empty() || verz[verz.size()-1]!='/') verz+="/";
  }
  const string verzq=verz;
  const string verzz=verz;
  string dq=verzq+"datalist.html";
  string dv=verzz+"anzeig.php";
  string dz=verzz+"anzeigneu.php";
  struct stat sq, sv;
  vector<string> vec[3];
  int wov; // wo im Vector
  if (lstat(dq.c_str(),&sq)) {
    perror(("Datei '"+dq+"' nicht mit lstat pruefbar.").c_str());
    return 1;
  }
  if (lstat(dv.c_str(),&sv)) {
    perror(("Datei '"+dv+"' nicht mit lstat pruefbar.").c_str());
    return 1;
  }
  obnoetig=0;
  if (sq.st_mtime > sv.st_mtime) {
    cout<<"Aktualisierung nötig\n";
    obnoetig=1;
  } else {
    cout<<"Aktualisierung nicht nötig\n";
  }
  strftime(tbuf, 44,"Quelle: %d.%m.%y %X",localtime(&sq.st_mtime));
  cout<<tbuf<<" ("<<dq<<")"<<endl;
  strftime(tbuf, 44,"Ziel  : %d.%m.%y %X",localtime(&sv.st_mtime));
  cout<<tbuf<<" ("<<dv<<")"<<endl;
  if (obnoetig) {
    fstream eing(dq.c_str(),ios::in); 
    if (!eing.good()) { 
      perror((string("\nKann Datei '")+dq+"' nicht als fstream zum Lesen öffnen.").c_str());
      return 1;
    }
    string zeil;
    wov=0;
    while (getline(eing,zeil)) {
      if      (strstr(zeil.c_str(),"DL1a")) wov=1;
      else if (strstr(zeil.c_str(),"DL2a")) wov=2;
      else if (strstr(zeil.c_str(),"DL3a")) wov=3;
      else if (wov>=1 && wov<=3) vec[wov-1].push_back(zeil);
    }
    eing.close();
    /*
       for(unsigned i=0;i<3;i++) {
       for(unsigned j=0;j<vec[i].size();j++) {
       cout<<"i: "<<i<<" j: "<<j<<" "<<vec[i][j]<<endl;
       }
       }
     */    
    fstream vorl(dv.c_str(),ios::in); 
    if (!vorl.good()) { 
      perror((string("\nKann Datei '")+dv+"' nicht als fstream zum Lesen öffnen.").c_str());
      return 1;
    }
    fstream ausg(dz.c_str(),ios::out); 
    if (!ausg.good()) { 
      perror((string("\nKann Datei '")+dz+"' nicht als fstream zum Lesen öffnen.").c_str());
      return 1;
    }
    wov=0;
    while (getline(vorl,zeil)) {
      if (strstr(zeil.c_str(),"DL_e")) wov=0;
      if (!wov) {
        ausg<<zeil<<endl;
      }
      for(unsigned i=1;i<=3;i++) {
        sprintf(tbuf,"DL%da",i);
        if (strstr(zeil.c_str(),tbuf)) {
          for(unsigned j=0;j<vec[i-1].size();j++) {
            ausg<<"  <option value=\""<<vec[i-1][j]<<"\">"<<endl;
          }
          wov=-1;
        }
      }
    }
    ausg.close();
    if (ausg.fail()) {
      perror((string("\nFehler beim Schreiben von '")+dz+"'.").c_str());
      unlink(dz.c_str());
      return 1;
    }
    // anzeig.php wird sehr haeufig aufgerufen (Patientenlaufzettel), darf also nie fehlen:
    // Sicherung anzeig.php_res als harter Link auf die alte Datei, dann die neue mit
    // einem einzigen rename() (atomar) an ihre Stelle setzen, mit Rechten/Besitzer der alten
    const string dres=dv+"_res";
    chmod(dz.c_str(),sv.st_mode&07777);
    if (chown(dz.c_str(),sv.st_uid,sv.st_gid)) {} // nur als root moeglich, sonst egal
    unlink(dres.c_str());
    if (link(dv.c_str(),dres.c_str())) {
      perror(("Sicherung '"+dres+"' nicht anlegbar").c_str());
      unlink(dz.c_str());
      return 1;
    }
    cout<<"link \""<<dv<<"\" \""<<dres<<"\" -> erfolgreich"<<endl;
    if (rename(dz.c_str(),dv.c_str())) {
      perror(("rename '"+dz+"' -> '"+dv+"' fehlgeschlagen").c_str());
      unlink(dz.c_str());
      return 1;
    }
    cout<<"rename \""<<dz<<"\" \""<<dv<<"\" -> erfolgreich"<<endl;
  }
  return 0;
}

