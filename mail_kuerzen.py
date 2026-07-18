#!/usr/bin/env python3
# Kuerzt /var/mail/root auf Mails der letzten N Tage (Default: 14)
import mailbox
import email.utils
import datetime
import os
import sys

path = sys.argv[1] if len(sys.argv) > 1 else "/var/mail/root"
days = int(sys.argv[2]) if len(sys.argv) > 2 else 14

size_before = os.path.getsize(path)
cutoff = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=days)

mbox = mailbox.mbox(path)
mbox.lock()

to_delete = []
for key, msg in mbox.items():
    date_hdr = msg.get('Date')
    dt = None
    if date_hdr:
        try:
            dt = email.utils.parsedate_to_datetime(date_hdr)
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=datetime.timezone.utc)
        except Exception:
            pass
    if dt is not None and dt < cutoff:
        to_delete.append(key)

for key in to_delete:
    mbox.remove(key)

mbox.flush()
mbox.unlock()
mbox.close()

size_after = os.path.getsize(path)
saved = size_before - size_after
print(f"{len(to_delete)} Mails gelöscht")
print(f"Vorher: {size_before/1024/1024:.2f} MB, Nachher: {size_after/1024/1024:.2f} MB, gespart: {saved/1024/1024:.2f} MB")
