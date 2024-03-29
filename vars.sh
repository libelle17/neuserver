OSNR="4"
IPR="/usr/bin/zypper -n --gpg-auto-import-keys in -f "
IP_R="/usr/bin/zypper --gpg-auto-import-keys in "
UPR="/usr/bin/zypper rm -u "
UDPR="/usr/bin/rpm -e --nodeps "
SPR="/usr/bin/rpm -q "
UNROH="uninstall"
UNF="uninstallinv"
AUNF="/root/neuserver/uninstallinv"
ILOG="inst.log"
PGROFF="groff"
LT="libtiff-devel"
LT5="libtiff5"
LBOOST="boost-license1_66_0"
LBIO="libboost_iostreams1_66_0-devel"
LBLO="libboost_locale1_66_0-devel"
LACL="libacl-devel"
LCURL="libcurl-devel"
LCURS="ncurses"
LM18="libmysqlclient18"
dev="devel"
libmdb="libmariadb libmariadbclient libmysql libmysqlclient"
REPOS="/usr/bin/zypper lr|grep 'g++\|devel_gcc'\>/dev/null 2>&1||/usr/bin/zypper ar http://download.opensuse.org/repositories/devel:/gcc/`cat /etc/*-release|grep ^NAME= |cut -d'"' -f2|sed 's/ /_/'`_`cat /etc/*-release|grep ^VERSION_ID= |cut -d'"' -f2`/devel:gcc.repo;"
UREPO="/usr/bin/zypper lr|grep \"g++\\|devel_gcc\"\>/dev/null 2>&1 && /usr/bin/zypper rr devel_gcc;"
COMP="gcc gcc-c++"
GITV="libelle17"
DTN="		   			 			  man_?? Makefile configure 			 tumount.sh smbd.sh los.sh install.sh awksmb.inc vars.sh awksmbap.inc			  viall .exrc uninstallinv inst.log"
DPROG="neuserver"
