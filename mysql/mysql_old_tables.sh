#!/bin/bash
# encoding: UTF-8
#
# Title           :mysql_old_tables.sh
# Description     :Move all _old created by pt-online-schema-change to backups
#                  database. And move temporary tables when start with this
#                  names: _tmp_
# Author          :Nicola Strappazzon C. nicola@swapbytes.com
# Date            :2015-11-10
# Version         :0.1
# ==============================================================================

# Set default values:
DATABASE=
LOGIN_PATH=

# ==============================================================================
# CLI for this script
# ==============================================================================

# Help message of usage this script.
usage()
{
  cat << EOF
  usage: $0

  $0 --login-path=foo --database=demo

  OPTIONS:
    --database      Name of database
    --login-path    Login Path to connect to server
EOF
}

log()
{
  MESSAGE=$1
  echo $(date '+%Y-%m-%d %H:%M:%S')" - ${MESSAGE}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --database=*)
      DATABASE="${1#*=}"
      ;;
    --login-path=*)
      LOGIN_PATH="${1#*=}"
      ;;
    *)
      printf "Error: Invalid argument.\n"
      usage
      exit 1
  esac
  shift
done

# Validate de minimal arguments required.
if [[ ( ! -n "$DATABASE")      ||
      ( ! -n "$LOGIN_PATH")    ]]
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

DB_EXISTS=`mysql --login-path=${LOGIN_PATH} -BNse "
  SHOW DATABASES LIKE '${DATABASE}'
"`
if [ -z "${DB_EXISTS}" ]; then
  log "ERROR: Database not exists ${DATABASE}"
  exit 1
fi

log "Create percona backups database."
mysql --login-path=${LOGIN_PATH} \
      -e "CREATE DATABASE IF NOT EXISTS backups;"

log "Get list of tables..."

TABLES=`mysql --login-path=${LOGIN_PATH} ${DATABASE} -N -e \
        "SELECT table_name
         FROM information_schema.tables
         WHERE table_schema = '${DATABASE}'
           AND (table_name LIKE '\_%\_old'
            OR  table_name LIKE '\_%\_backup'
            OR  table_name LIKE '\_tmp\_%');" \
        | awk -F "\t" '{if ($1) print $1}'`

for TABLE in $TABLES; do
  log "Move old table to backups database: "${DATABASE}.${TABLE}

  mysql --login-path=${LOGIN_PATH} -e \
        "RENAME TABLE ${DATABASE}.${TABLE} TO backups.${TABLE}_${RANDOM}_$(date +%s);"
done
