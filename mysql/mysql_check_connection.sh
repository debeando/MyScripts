#!/bin/bash
# encoding: UTF-8
#
# Title           :mysql_check_connections.sh
# Description     :Check mysql connections.
# Author          :Nicola Strappazzon C. nicola@wuaki.tv
# Date            :2016-03-03
# Version         :0.1
# ==============================================================================

# Set default values:
HOST=
PORTS=
REPEAT=9

# ==============================================================================
# CLI for this script
# ==============================================================================

# Help message of usage this script.
usage()
{
  cat << EOF
  usage: $0

  $0 --login-path=foo --host=haproxy01.private --ports="3306,3307,3308" --repeat=9

  OPTIONS:
    --login-path Login Path to connect to server
    --host       Host to check open ports
    --ports      Array ports to check open ports
    --repeat     Repeat every check N times
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
    --ports=*)
      PORTS="${1#*=}"
      PORTS=(${PORTS//,/ })
      ;;
    --repeat=*)
      REPEAT="${1#*=}"
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
      ( ! -n "$PORTS")      ||
      ( ! -n "$LOGIN_PATH") ]]
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
IP_ADDRESS=""

for ((i=1;i<=$REPEAT;i++))
do
  for PORT in "${PORTS[@]}"
  do
    VARIABLE=`mysql --login-path=${LOGIN_PATH} \
                    -h ${HOST} \
                    -P ${PORT} \
                    -BNse "SHOW VARIABLES LIKE 'wsrep_node_address'" \
              2>/dev/null`

    if [ $? -eq 0 ]
    then
      STATUS="${GREEN}OPEN${NC}"
      IP_ADDRESS=`echo $VARIABLE | awk -F ' ' '{ print $2 }'`
      IP_ADDRESS="${IP_ADDRESS}:"
    else
      STATUS="${RED}CLOSED${NC}"
    fi

    printf "${HOST}: Check port is open ${IP_ADDRESS}${PORT} [${STATUS}]\n"
  done
done