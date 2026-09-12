# -*- coding: utf-8 -*-
# Fuer den Betrieb auf linux1 vorgesehen, NICHT auf szn4/Windows.
# Deployment-Ziel: /opt/mo-emailadr/ (ausserhalb von /srv/www/htdocs,
# bewusst nicht web-exponiert). Gemeinsame Verbindungs-Hilfe fuer medoff
# (wser) UND quelle (linux1 selbst) ueber die
# dort bereits vorhandenen MariaDB-Client-Defaults-Dateien - laut
# Rueckmeldung der PHP-Instanz (siehe [[project-missing-patient-emails]]):
#   /root/.modbpwd     -> medoff (Format wie /root/.mariadbrpwd)
#   /root/.mariadbrpwd -> quelle
# Beide im "[client]"-Format mit ssl/user/password/host/port - siehe
# `mariadb --defaults-extra-file=<Datei> -e "..."`, dort bereits verifiziert.
#
# Von beiden linux1-Skripten genutzt (linux1_commit_medoff.py,
# linux1_sync_medoff_changes.py), damit es nur EINE Stelle gibt, die dieses
# Dateiformat parst.
#
# WICHTIG fuer die andere Instanz: die exakte SSL-Parameteruebergabe an
# PyMySQL (ssl=...) haengt von der genauen PyMySQL-Version und dem
# tatsaechlichen Inhalt von "ssl=" in der Datei ab - hier nur ein
# plausibler Default, bitte gegen die echten Dateien verifizieren/anpassen.
import configparser

MODBPWD_FILE = "/root/.modbpwd"
MARIADBRPWD_FILE = "/root/.mariadbrpwd"

# /root/.mariadbrpwd (quelle) enthaelt "user=root", ohne host=-Zeile. Das
# MariaDB-Konto root@localhost ist auf unix_socket/auth_socket-Auth
# beschraenkt (Passwort wird ignoriert) - ueber TCP, auch 127.0.0.1, schlaegt
# die Anmeldung fehl (verifiziert 2026-09-12: "Access denied for user
# 'root'@'localhost'"). Genau das nutzt die mariadb-CLI ohne "-h" die ganze
# Zeit schon; Pfad per "SHOW VARIABLES LIKE 'socket'" bestaetigt.
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
    # linux1 (2026-09-12): /root/.modbpwd enthaelt "ssl=false" (String!), das
    # ist in Python truthy - ein blosses "if cfg.get('ssl'):" wuerde SSL hier
    # faelschlich aktivieren. Verifiziert per
    # "mariadb --defaults-extra-file=/root/.modbpwd -e ...": funktioniert
    # ohne SSL, also muss der Wert als Bool interpretiert werden.
    # /root/.mariadbrpwd hat gar keine ssl=-Zeile (cfg.get liefert None, bleibt
    # falsy - unveraendert kein SSL).
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
