#!/bin/bash
# Duenner Cron-Wrapper fuer poll_diabetologie_inbox.py auf linux1 - setzt alle
# noetigen Umgebungsvariablen (linux1-Pfade statt der Windows-Defaults) und
# ruft das Skript ueber die isolierte venv auf (dort liegen xhtml2pdf/
# pdfplumber/reportlab - bewusst NICHT systemweit installiert, das haette
# certbot/pyOpenSSL kaputt gemacht, siehe Commit-Historie und
# /DATA/down/linux1_testlauf_befunde.txt).
export DOKPROT_PWD_SHARE=/root/dbverbfreigabe/dbverb.cfg
export DOK_ROOT=/DATA/Patientendokumente/dok
export AUDIT_DIR=/opt/mo-emailadr/protokolle
export SEEN_CACHE_PATH=/opt/mo-emailadr/archive_seen_cache.sqlite
export UIDL_CHECKPOINT_FILE=/opt/mo-emailadr/diabetologie_pop_uidl.txt
exec /opt/mo-emailadr/venv/bin/python3 /opt/mo-emailadr/poll_diabetologie_inbox.py "$@"
