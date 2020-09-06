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
      [ -f $D ]&&AG=$(git log -1 --format="%at" -- $D)||AG=0;
      [ -f $Z/$D ]&&AH=$(stat $Z/$D -c%Y)||AH=0;
      echo AG: $AG;
      echo AH: $AH;
      [ 0$AH -eq 0 ]&&{
        [ 0$AG -eq 0 ]||{
         echo " "$D fehlt hier: cp -a $D $Z/;:;
        }&&{
         echo " "$D fehlt hier und auf Git;
        };:;
      }||{
        [ 0$AG -eq 0 ]&&{
         echo " "$D fehlt auf Git: cp -a $Z/$D .;:;
        }||{
          ls -l $Z/$D
          ls -l $D
          diff $Z/$D .;
          [ $? -eq 0 ]||printf "${rot}Dateien verschieden${reset}\n";
          [ 0$AG -lt 0$AH ]&&echo " "$D auf Git aelter: cp -a $Z/$D .;
          [ 0$AG -gt 0$AH ]&&echo " "$D hier aelter: cp -a $D $Z/;
          [ 0$AG -eq 0$AH ]&&echo " "$D auf beiden gleich alt: lasse sie aus;
        }
      }
      ;;
  esac;
done
