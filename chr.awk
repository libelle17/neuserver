BEGIN {
  cmd="find /etc/auto.master.d -type f";
  while ((cmd|getline d1)>0) {
#    printf "b: %s\n",d1;
    while ((getline d2 < d1)>0) {
      if (d2 !~ /^#.*/){
#        printf "c: %s\n",d2;
        if (split(d2,arr," ")>1) {
#        printf " %s\n",arr[1];
         vors=arr[1];
         gsub(".*/","",vors);
         gsub("^amnt","",vors);
#        printf "vors: %s\n",vors;
#        printf " %s\n",arr[2];
        while ((getline d3 < arr[2])>0) {
          if (d3 !~ /^#.*/) {
#            printf "d: %s\n",d3;
            gsub("\\s.*","",d3);
            printf "%s %s %i\n",vors d3,arr[1]"/"d3,0;
#            awk '/^[^#]/{w1=$2;w2=$2;gsub(",.*","",w1);gsub("-fstype=","",w1);gsub("^[^,]*,","",w2);print substr($3,2)" "v1"/"$1" "w1" "w2}' v1="$VS" ${Z##*€} 
          }
        }
      }
      }
    }
    close(d1);
  }
  close(cmd);
#  printf "%s\n","Ende1";
};
