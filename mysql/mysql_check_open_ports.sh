#!/bin/bash
# encoding: UTF-8
#
# Title           :mysql_check_open_ports.sh
# Description     :Check Percona XtraDB Cluster ports is open between instances
# Author          :Nicola Strappazzon C. nicola@swapbytes.com
# Date            :2016-02-29
# Version         :0.1
# ==============================================================================

# Set default values:
HOSTS=
SERVER='false'

# ==============================================================================
# CLI for this script
# ==============================================================================

# Help message of usage this script.
usage()
{
  cat << EOF
  usage: $0

  $0 [ --check=192.168.0.10 | --open ]

  OPTIONS:
    --check Host to check open ports.
    --open  Start nc server to open this ports: 3306, 4444, 4567, 4568.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --check=*)
      HOST="${1#*=}"
      ;;
    --open)
      SERVER=true
      ;;
    *)
      printf "Error: Invalid argument.\n"
      usage
      exit 1
  esac
  shift
done

# Validate de minimal arguments required.
if [ ! -n "$HOST" ] && [ ! $SERVER = 'true' ]
then
  usage
  exit 1
fi

# Check installed basic commands to run this script:
if ( ! type -P 'nc' > /dev/null )
then
  echo "Can't find the nc command, please install."
  exit 1
fi

# ==============================================================================
# The script
# ==============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

open_port()
{
  PORT=${1}

  nc -lp $PORT | while read line
  do
    if [ "$line" == "$PORT" ]
    then
      printf "Port ${PORT}: [${GREEN}OPEN${NC}]\n"
      break
    else
      printf "Port ${PORT}: [${RED}CLOSED${NC}]\n"
      break
    fi
  done
}

check_port()
{
  HOST=${1}
  PORT=${2}
  if (echo -n "$PORT" | nc -w1 ${HOST} ${PORT} 2>/dev/null)
  then
    printf "${HOST}:${PORT} [${GREEN}OPEN${NC}]\n"
  else
    printf "${HOST}:${PORT} [${RED}CLOSED${NC}]\n"
  fi
}

if [ $SERVER = 'true' ]
then
  # Check the mysqld service is not running.
  mysqladmin ping &>/dev/null
  if [ $? -eq 0 ]
  then
    echo "MySQL is running, please stop the service first."
    exit 1
  fi

  open_port 3306
  open_port 4444
  open_port 4567
  open_port 4568
fi

if [ -n "$HOST" ]
then
  check_port $HOST 3306
  check_port $HOST 4444
  check_port $HOST 4567
  check_port $HOST 4568
fi
