#!/bin/bash
# encoding: UTF-8
#
# Title           :mysql_replica_from_rds.sh
# Description     :Create MySQL Replica on EC2 from RDS.
# Author          :Nicola Strappazzon C. nicola@swapbytes.com
# Date            :2015-11-19
# Version         :0.3
# ==============================================================================

# Set default values:
LOGIN_PATH=
MASTER_HOST=

# ==============================================================================
# CLI for this script
# ==============================================================================

# Help message of usage this script.
usage()
{
  cat << EOF
  usage: $0

  $0 --login-path=foo --repl-host=127.0.0.1

  OPTIONS:
    --login-path    Login Path to connect to server
    --repl-host     Host name for master
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
    --repl-host=*)
      MASTER_HOST="${1#*=}"
      ;;
    *)
      printf "Error: Invalid argument.\n"
      usage
      exit 1
  esac
  shift
done

# Validate de minimal arguments required.
if [[ ( ! -n "$LOGIN_PATH")  ||
      ( ! -n "$MASTER_HOST") ]]
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

log "Set slave settings..."
mysql --login-path=$LOGIN_PATH \
      -e "CHANGE MASTER TO
          MASTER_HOST='${MASTER_HOST}',
          MASTER_USER='${MYSQL_REPLICA_USER}',
          MASTER_PASSWORD='${MYSQL_REPLICA_PASSWORD}';
          START SLAVE;
          SHOW SLAVE STATUS\G"
