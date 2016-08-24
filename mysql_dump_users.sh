#!/bin/bash
# encoding: UTF-8
#
# Title           :mysql_dump_users.sh
# Description     :MySQL Dump only users.
# Author          :Nicola Strappazzon C. nicola@swapbytes.com
# Date            :2016-08-24
# Version         :0.1
# ==============================================================================

# Set default values:
HOST='localhost'
USER=
PASSWORD=

# ==============================================================================
# CLI for this script
# ==============================================================================

# Help message of usage this script.
usage()
{
  cat << EOF
  usage: $0

  $0 --host=localhost --user=root --password=admin

  OPTIONS:
    --host     Host name or ip address
    --user     User name
    --password Password for user name
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --host=*)
      HOST="${1#*=}"
      ;;
    --user=*)
      USER="${1#*=}"
      ;;
    --password=*)
      PASSWORD="${1#*=}"
      ;;
    *)
      printf "Error: Invalid argument.\n"
      usage
      exit 1
  esac
  shift
done

# Validate de minimal arguments required.
if [[ ( ! -n "$USER") ]]
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
SQL="SELECT DISTINCT CONCAT('SHOW GRANTS FOR ''', user, '''@''', host, ''';') AS query FROM mysql.user"

mysql -h ${HOST} -u $USER -p${PASSWORD} -BNe "${SQL}" \
  | \
  mysql -h ${HOST} -u $USER -p${PASSWORD} \
  | \
  sed 's/\(GRANT .*\)/\1;/;s/^\(Grants for .*\)/­­ \1 ­­/;/­­/{x;p;x;}'
