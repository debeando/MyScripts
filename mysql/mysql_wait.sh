#!/bin/bash
# encoding: UTF-8
#
# Title           :mysql_wait.sh
# Description     :MySQL Wait to ready to connect.
# Author          :Nicola Strappazzon C. nicola@swapbytes.com
# Date            :2016-05-02
# Version         :0.1
# ==============================================================================

# Set default values:
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

  $0 --login-path=foo

  OPTIONS:
    --login-path Login Path to connect to server
    --host       Host name
EOF
}

log()
{
  MESSAGE=$1
  echo $(date '+%Y-%m-%d %H:%M:%S')" - ${MESSAGE}"
}

while [ $# -gt 0 ]; do
  case "$1" in
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
if [[ ( ! -n "$LOGIN_PATH") ]]
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

until $MYSQL_CMD --execute="SELECT VERSION();" > /dev/null 2>&1 ; do
  log "Can't connect to MySQL Server, retrying in 60 seconds..."
  sleep 60
done
