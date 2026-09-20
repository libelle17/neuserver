#!/bin/bash
# bupull_aktivieren.sh - traegt den Lern-Wrapper (bupull_wrapper.sh) auf linux1 vor die Schluessel der
# Reserver in /root/.ssh/authorized_keys ein bzw. nimmt ihn wieder heraus. Nur auf linux1.
#   --status   zeigt, welche Reserver-Schluessel welche Optionen haben
#   --apply    Wrapper vor root@linux0 und den Backup-Schluessel setzen (Sicherung wird angelegt)
#   --remove   Wrapper wieder entfernen
# NICHT waehrend eines laufenden Sicherungsfensters ausfuehren (linux0 21:45, linux7 00:00 und je
# 14:18/14:48) - laufende Verbindungen bleiben zwar bestehen, aber sicherheitshalber warten.
# Nach --apply pruefen: tail -f /var/log/backup_pull_wrapper.log  und  bumonitor.sh voll -n
A=${AUTHKEYS:-/root/.ssh/authorized_keys}; WR='command="/root/bin/bupull_wrapper.sh"'
h=$(hostname); [ "${h%%.*}" = linux1 ] || { echo "nur auf linux1"; exit 1; }
MODE=${1:---status}
py() { python3 - "$MODE" "$A" "$WR" <<'PY'
import sys,subprocess,tempfile,os
mode,p,wr=sys.argv[1:4]
ziel=("SHA256:eV/5kZckIF2wIIJ7KIL938dLCXJTAYkGdGnEnTMLDmY","SHA256:iP0aRwvFhnxmJYF5/95m6cfKSA5hvrkAk6DT7OE0AMg")
out=[]; n=0
for z in open(p).read().splitlines():
    if not z.strip() or z.lstrip().startswith("#"): out.append(z); continue
    with tempfile.NamedTemporaryFile("w",delete=False) as t: t.write(z+"\n")
    r=subprocess.run(["ssh-keygen","-lf",t.name],capture_output=True,text=True); os.unlink(t.name)
    fp=r.stdout.split()[1] if r.returncode==0 and len(r.stdout.split())>1 else ""
    # Optionsteil erkennen: alles vor dem Schluesseltyp
    i=z.find("ssh-ed25519"); opt=z[:i].strip(); key=z[i:]
    if fp in ziel:
        if mode=="--status": print(("mit Wrapper  " if "bupull_wrapper" in opt else "OHNE Wrapper ")+fp[7:17]+"  Optionen: "+(opt or "-")+"  "+key.split()[-1])
        elif mode=="--apply" and "bupull_wrapper" not in opt:
            opt=(opt+"," if opt else "")+wr; z=opt+" "+key; n+=1
        elif mode=="--remove" and "bupull_wrapper" in opt:
            teile=[o for o in opt.replace(wr,"").split(",") if o]; z=(",".join(teile)+" " if teile else "")+key; n+=1
    out.append(z)
if mode!="--status":
    open(p+".neu","w").write("\n".join(out)+"\n"); print("geaendert:",n)
PY
}
case "$MODE" in
  --status) py;;
  --apply|--remove)
    cp -p "$A" "$A.vor-bupull-$(date +%Y%m%d%H%M%S)" && py && chmod 600 "$A.neu" && ssh-keygen -lf "$A.neu" >/dev/null && mv "$A.neu" "$A" && echo "authorized_keys aktualisiert" && MODE=--status py;;
  *) sed -n '2,10p' "$0"; exit 1;;
esac
