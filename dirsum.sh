hdir () {
  ls -AGl "${@}" | LC_ALL="de_DE" awk '{ total += $4; print }; END { printf("insgesamt: %'"'"'d Bytes\n", total) }'
}

hdir "$@"
