sed -nr '/^...(3000|3650|6001)/p;' roh.BDT | sed -nr 'N;/^(.*)\n\1$/!P;D;'|sed -rn '/^...3000/{x;p;x};s/^.{7}//p' > lesbar.BDT
