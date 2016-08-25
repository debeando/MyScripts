#!/bin/bash
# encoding: UTF-8
#
# Title           :mysql_check_increment.sh
# Description     :Check mysql increment settings, for implement MultiMaster.
# Author          :Nicola Strappazzon C. nicola@swapbytes.com
# Date            :2016-03-07
# Version         :0.1
# ==============================================================================

# Set default values:
HOST=
INCREMENT=
OFFSET=

# ==============================================================================
# CLI for this script
# ==============================================================================

# Help message of usage this script.
usage()
{
  cat << EOF
  usage: $0

  $0 --login-path=foo --host=localhost --increment=1 --offset=1

  OPTIONS:
    --login-path  Login Path to connect to server
    --host        Host to check open ports
    --increment
    --offset
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --login-path=*)
      LOGIN_PATH="${1#*=}"
      ;;
    --host=*)
      HOST="${1#*=}"
      ;;
    --increment=*)
      INCREMENT="${1#*=}"
      ;;
    --offset=*)
      OFFSET="${1#*=}"
      ;;
    *)
      printf "Error: Invalid argument.\n"
      usage
      exit 1
  esac
  shift
done

# Validate de minimal arguments required.
if [[ ( ! -n "$HOST")       ||
      ( ! -n "$LOGIN_PATH") ||
      ( ! -n "$INCREMENT")  ||
      ( ! -n "$OFFSET")     ]]
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
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

VALUES=`mysql --login-path=${LOGIN_PATH} \
              -h ${HOST} \
              -Bse "SHOW VARIABLES LIKE 'auto_increment%';"`

INCREMENT_TEMP=`echo $VALUES | awk -F " " '{ print $2 }'`
OFFSET_TEMP=`echo $VALUES | awk -F " " '{ print $4 }'`

if [[ ("$INCREMENT" -eq "$INCREMENT_TEMP") && ("$OFFSET" -eq "$OFFSET_TEMP") ]]
then
  printf "${HOST}: Increment(${INCREMENT_TEMP}) & Offset(${OFFSET_TEMP}) [${GREEN}OK${NC}]\n"
  exit 0
else
  printf "${HOST}: Increment(${INCREMENT_TEMP}) & Offset(${OFFSET_TEMP}) [${RED}ERROR${NC}]\n"
  exit 1
fi
