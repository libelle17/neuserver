#/bin/bash
rot="\e[1;31m";
blau="\033[1;34m";
reset="\033[0m";
[ $1/ = -v/ ]&&obverb=1;
for D in $(cat ziele);do 
  case $D in 
    [*\])
      Z=$(printf $D|sed 's/^[[]//;s/[]]$//;');;
    *)
      printf "$blau$D $Z/$D$reset\n";
      [ -f $D ]&&AGit=$(git log -1 --format="%at" -- $D)||AGit=0;
      [ -f $Z/$D ]&&AHier=$(stat $Z/$D -c%Y)||AHier=0;
      echo AGit : $AGit;
      echo AHier: $AHier;
      [ 0$AHier -eq 0 ]&&{
        [ 0$AGit -eq 0 ]&&{
         echo " "$D fehlt hier und auf Git;:;
        }&&{
         echo " "$D fehlt hier: cp -a $D $Z/;
        };:;
      }||{
        [ 0$AGit -eq 0 ]&&{
         echo " "$D fehlt auf Git: cp -a $Z/$D .;:;
        }||{
          ls -l $Z/$D
          ls -l $D
          diff $Z/$D .;
          [ $? -eq 0 ]||printf "${rot}Dateien verschieden${reset}\n";
          [ 0$AGit -lt 0$AHier ]&&echo " "$D auf Git aelter: cp -a $Z/$D .;
          [ 0$AGit -gt 0$AHier ]&&echo " "$D hier aelter: cp -a $D $Z/;
          [ 0$AGit -eq 0$AHier ]&&echo " "$D auf beiden gleich alt: lasse sie aus;
        }
      }
      ;;
  esac;
done
