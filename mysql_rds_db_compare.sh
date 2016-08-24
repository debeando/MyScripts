#!/bin/bash
# encoding: UTF-8
#
# Title           :mysql_rds_db_compare.sh
# Description     :RDS MySQL compare databases, in RDS not found mysqldbcompare.
# Author          :Nicola Strappazzon C. nicola@swapbytes.com
# Date            :2016-04-24
# Version         :0.1
# ==============================================================================

# Set default values:
DATABASE=
LOGIN_PATH1=
LOGIN_PATH2=

# ==============================================================================
# CLI for this script
# ==============================================================================

# Help message of usage this script.
usage()
{
  cat << EOF
  usage: $0

  $0 --login-path-1=foo --login-path-2=bar --database=demo

  OPTIONS:
    --login-path-1 Login Path to connect to server 1
    --login-path-2 Login Path to connect to server 2
    --database     Database to compare
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --login-path-1=*)
      LOGIN_PATH1="${1#*=}"
      ;;
    --login-path-2=*)
      LOGIN_PATH2="${1#*=}"
      ;;
    --database=*)
      DATABASE="${1#*=}"
      ;;
    *)
      printf "Error: Invalid argument.\n"
      usage
      exit 1
  esac
  shift
done

# Validate de minimal arguments required.
if [[ ( ! -n "$DATABASE")    ||
      ( ! -n "$LOGIN_PATH1") ||
      ( ! -n "$LOGIN_PATH2") ]]
then
  usage
  exit 1
fi

if ( ! type -P 'mysql' > /dev/null )
then
  echo "Can't find the mysql client command, please install."
  exit 1
fi

# ==============================================================================
# The script
# ==============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

checksum()
{
  LOGIN_PATH=$1
  DATABASE=$2
  TABLE=$3

  echo `mysql --login-path=${LOGIN_PATH} \
              -NBse "CHECKSUM TABLE $DATABASE.${TABLE};" \
        | \
        awk -F " " '{print $2}'`
}

TABLES=`mysql --login-path=${LOGIN_PATH1} $DATABASE -Nse \
        "SHOW FULL TABLES IN $DATABASE WHERE table_type LIKE 'BASE TABLE';" \
        | awk -F "\t" '{if ($1) print $1}'`

for TABLE in $TABLES; do
  CHECKSUMP1=$(checksum $LOGIN_PATH1 $DATABASE $TABLE)
  CHECKSUMP2=$(checksum $LOGIN_PATH2 $DATABASE $TABLE)

  if [ "$CHECKSUMP1" == "$CHECKSUMP1" ]
  then
    printf "Compare table: ${TABLE}: [${GREEN} OK ${NC}]\n"
  else
    printf "Compare table: ${TABLE}: [${RED}FAIL${NC}]\n"
  fi
done
