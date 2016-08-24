#!/bin/bash
# encoding: UTF-8
#
# Title           :mysql_rename_db.sh
# Description     :MySQL rename database.
# Author          :Nicola Strappazzon C. nicola@swapbytes.com
# Date            :2014-08-25
# Version         :0.3
# ==============================================================================

# Set default values:
NEW_DATABASE=
OLD_DATABASE=
LOGIN_PATH=
HOST=

# ==============================================================================
# CLI for this script
# ==============================================================================

# Help message of usage this script.
usage()
{
  cat << EOF
  usage: $0

  $0 --login-path=foo --old-database=old --new-database=new

  OPTIONS:
    --login-path    Login Path to connect to server
    --host          Host name
    --new-database  New name of database
    --old-database  Actual name of database
EOF
}

log()
{
  MESSAGE=$1
  echo $(date '+%Y-%m-%d %H:%M:%S')" - ${MESSAGE}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --new-database=*)
      NEW_DATABASE="${1#*=}"
      ;;
    --old-database=*)
      OLD_DATABASE="${1#*=}"
      ;;
    --login-path=*)
      LOGIN_PATH="${1#*=}"
      ;;
    --host=*)
      HOST="${1#*=}"
      ;;
    *)
      printf "Error: Invalid argument.\n"
      usage
      exit 1
  esac
  shift
done

# Validate de minimal arguments required.
if [[ ( ! -n "$NEW_DATABASE") ||
      ( ! -n "$OLD_DATABASE") ]]
then
  usage
  exit 1
fi

# Check installed basic commands to run this script:
if ( ! type -P 'mysql' > /dev/null )
then
  echo "Can't find the mysql client command, please install."
  exit 1
fi

# ==============================================================================
# The script
# ==============================================================================

MYSQL_CMD="mysql --login-path=${LOGIN_PATH}"
if [[ ( -n "$HOST") ]]
then
  MYSQL_CMD="${MYSQL_CMD} --host=${HOST}"
fi

DB_EXISTS=`${MYSQL_CMD} -BNse "
  SHOW DATABASES LIKE '${NEW_DATABASE}'
"`
if [ -n "${DB_EXISTS}" ]; then
  log "ERROR: New database already exists ${NEW_DATABASE}"
  exit 1
fi

TIMESTAMP=`date +%s`
CHARACTER_SET=`${MYSQL_CMD} -BNse "
  SELECT default_character_set_name
  FROM information_schema.schemata
  WHERE schema_name = '${OLD_DATABASE}';
"`
TABLES=`${MYSQL_CMD} -BNse "
  SELECT table_name
  FROM information_schema.tables
  WHERE table_schema = '${OLD_DATABASE}'
    AND table_type   = 'BASE TABLE'
"`
STATUS=$?

if [ "${STATUS}" != 0 ] || [ -z "${TABLES}" ]; then
  log "Error retrieving tables from ${OLD_DATABASE}"
  exit 1
fi

log "Create new database ${NEW_DATABASE} with default character set ${CHARACTER_SET}..."

${MYSQL_CMD} -e "
  CREATE DATABASE $NEW_DATABASE DEFAULT CHARACTER SET ${CHARACTER_SET};
"

TRIGGERS=`${MYSQL_CMD} ${OLD_DATABASE} \
                -e "SHOW TRIGGERS\G" | \
          grep Trigger: | \
          awk '{print $OLD_DATABASE}'`

VIEWS=`${MYSQL_CMD} -BNse "
  SELECT table_name
  FROM information_schema.tables
  WHERE table_schema = '$OLD_DATABASE'
    AND table_type   = 'VIEW'
"`

if [ -n "$VIEWS" ]; then
  mysqldump --login-path=${LOGIN_PATH} \
            $OLD_DATABASE \
            $VIEWS > /tmp/${OLD_DATABASE}_views${TIMESTAMP}.dump
fi

mysqldump --login-path=${LOGIN_PATH} \
          $OLD_DATABASE \
          -d -t -R -E > /tmp/${OLD_DATABASE}_triggers${TIMESTAMP}.dump

for TRIGGER in $TRIGGERS; do
  log "Drop trigger $TRIGGER..."
  ${MYSQL_CMD} $OLD_DATABASE -e "DROP TRIGGER $TRIGGER"
done

for TABLE in $TABLES; do
  log "Rename table $OLD_DATABASE.$TABLE to $NEW_DATABASE.$TABLE"
  ${MYSQL_CMD} $OLD_DATABASE -e "
    SET FOREIGN_KEY_CHECKS=0;
    RENAME TABLE ${OLD_DATABASE}.${TABLE} TO ${NEW_DATABASE}.${TABLE};
  "
done

if [ -n "$VIEWS" ]; then
  log "Loading views..."
  ${MYSQL_CMD} $NEW_DATABASE < /tmp/${OLD_DATABASE}_views${TIMESTAMP}.dump
fi

log "Loading triggers, routines and events..."

${MYSQL_CMD} $NEW_DATABASE < /tmp/${OLD_DATABASE}_triggers${TIMESTAMP}.dump

TABLES=`${MYSQL_CMD} -BNse "
  SELECT table_name
  FROM information_schema.tables
  WHERE table_schema = '${OLD_DATABASE}'
    AND table_type   = 'BASE TABLE'"`

if [ -z "$TABLES" ]; then
  log "Dropping database $OLD_DATABASE"
  ${MYSQL_CMD} $OLD_DATABASE -e "DROP DATABASE $OLD_DATABASE;"
fi

log "Update user privileges..."

PRIVILEGES=`${MYSQL_CMD} -BNse "
  SELECT COUNT(*)
  FROM mysql.columns_priv
  WHERE db = '${OLD_DATABASE}'
"`

if [ $PRIVILEGES -gt 0 ]; then
  COLUMNS_PRIV="
    UPDATE mysql.columns_priv
       SET db = '${NEW_DATABASE}'
    WHERE db  = '${OLD_DATABASE}';
  "
fi

PRIVILEGES=`${MYSQL_CMD} -BNse "
  SELECT COUNT(*)
  FROM mysql.procs_priv
  WHERE db = '${OLD_DATABASE}'
"`

if [ $PRIVILEGES -gt 0 ]; then
  PROCS_PRIV="
    UPDATE mysql.procs_priv
       SET db = '${NEW_DATABASE}'
    WHERE db  = '${OLD_DATABASE}';
  "
fi

PRIVILEGES=`${MYSQL_CMD} -BNse "
  SELECT COUNT(*)
  FROM mysql.tables_priv
  WHERE db = '${OLD_DATABASE}'
"`

if [ $PRIVILEGES -gt 0 ]; then
  TABLES_PRIV="
    UPDATE mysql.tables_priv
       SET db = '${NEW_DATABASE}'
    WHERE  db = '${OLD_DATABASE}';
  "
fi

PRIVILEGES=`${MYSQL_CMD} -BNse "
  SELECT COUNT(*)
  FROM mysql.db
  WHERE db = '${OLD_DATABASE}'
"`

if [ $PRIVILEGES -gt 0 ]; then
  DB_PRIV="
    UPDATE mysql.db
       SET db = '${NEW_DATABASE}'
    WHERE db  = '${OLD_DATABASE}';
  "
fi

${MYSQL_CMD} -e "
  ${COLUMNS_PRIV};
  ${PROCS_PRIV};
  ${TABLES_PRIV};
  ${DB_PRIV};
  FLUSH PRIVILEGES;
"
