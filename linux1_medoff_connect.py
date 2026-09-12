# -*- coding: utf-8 -*-
# Gemeinsame Verbindungs-Hilfe fuer medoff (wser) UND quelle (linux1 selbst) ueber die
# dort bereits vorhandenen MariaDB-Client-Defaults-Dateien - laut Rueckmeldung der
# PHP-Instanz (siehe [[project-missing-patient-emails]]):
#   /root/.modbpwd     -> medoff (Format wie /root/.mariadbrpwd)
#   /root/.mariadbrpwd -> quelle
# Beide im "[client]"-Format mit ssl/user/password/host/port - siehe
# `mariadb --defaults-extra-file=<Datei> -e "..."`, dort bereits verifiziert. Von beiden
# linux1-Skripten genutzt (linux1_commit_medoff.py, linux1_sync_medoff_changes.py), damit
# es nur EINE Stelle gibt, die dieses Dateiformat parst.
#
# Fuer den Betrieb auf linux1 vorgesehen, NICHT auf szn4/Windows.
# Deployment-Ziel: /opt/mo-emailadr/ (ausserhalb von /srv/www/htdocs, bewusst nicht
# web-exponiert).
#
# Zwei reale Befunde aus dem ersten Testlauf auf linux1 (2026-09-12,
# siehe [[project-missing-patient-emails]]), beide hier behoben und live
# gegen die echten Dateien verifiziert:
#   1. "ssl=false" steht als STRING in der Datei - ein blosses
#      "if cfg.get('ssl'):" waere damit faelschlich wahr (jeder nicht-leere
#      String ist truthy). Jetzt echte Bool-Interpretation.
#   2. /root/.mariadbrpwd hat "user=root" und KEINE host=-Zeile. Das
#      MariaDB-Konto root@localhost ist auf unix_socket/auth_socket-Auth
#      beschraenkt - ueber TCP (auch 127.0.0.1) schlaegt die Anmeldung fehl,
#      das Passwort wird dabei ignoriert. Fehlt host= in der Datei, wird
#      jetzt stattdessen per unix_socket verbunden.
import configparser

MODBPWD_FILE = "/root/.modbpwd"
MARIADBRPWD_FILE = "/root/.mariadbrpwd"
# Pfad per "SHOW VARIABLES LIKE 'socket'" auf linux1 bestaetigt (2026-09-12).
QUELLE_UNIX_SOCKET = "/run/mysql/mysql.sock"


def _read_client_section(path):
    parser = configparser.ConfigParser()
    with open(path, encoding="utf-8") as f:
        content = f.read()
    if not content.lstrip().startswith("["):
        content = "[client]\n" + content
    parser.read_string(content)
    return dict(parser["client"])


def _connect(path, database, autocommit):
    import pymysql
    cfg = _read_client_section(path)
    kwargs = dict(
        user=cfg["user"],
        password=cfg.get("password", ""),
        database=database,
        connect_timeout=10,
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=autocommit,
    )
    if "host" in cfg:
        kwargs["host"] = cfg["host"]
        kwargs["port"] = int(cfg.get("port", 3306))
    else:
        kwargs["unix_socket"] = QUELLE_UNIX_SOCKET
    # "ssl=false" steht als STRING in /root/.modbpwd - ein blosses
    # "if cfg.get('ssl'):" waere in Python truthy (jeder nicht-leere String
    # ist wahr) und haette SSL faelschlich aktiviert. Echte Bool-
    # Interpretation, live gegen beide Dateien verifiziert (2026-09-12).
    ssl_wert = str(cfg.get("ssl", "")).strip().lower()
    if ssl_wert not in ("", "0", "false", "no", "off"):
        kwargs["ssl"] = {"ssl": {}}
    return pymysql.connect(**kwargs)


def connect_medoff():
    # Kein autocommit - wie auf Windows (apply_patient_emails.connect_medoff)
    # muss der Aufrufer explizit .commit() aufrufen.
    return _connect(MODBPWD_FILE, "medoff", autocommit=False)


def connect_quelle():
    # autocommit=True - wie auf Windows (patient_addresses_db.connect_dokprot)
    return _connect(MARIADBRPWD_FILE, "quelle", autocommit=True)
