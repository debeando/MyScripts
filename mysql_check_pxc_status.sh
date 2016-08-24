#!/bin/bash
# encoding: UTF-8
#
# Title           :mysql_check_pxc_status.sh
# Description     :Check Percona XtraDB Cluster SST User and WSREP variables.
# Author          :Nicola Strappazzon C. nicola@swapbytes.com
# Date            :2016-02-29
# Version         :0.1
# ==============================================================================
HOST=127.0.0.1

# ==============================================================================
# CLI for this script
# ==============================================================================

# Help message of usage this script.
usage()
{
  cat << EOF
  usage: $0

  $0 --login-path=foo --host=node01.private

  OPTIONS:
    --login-path Login Path to connect to server
    --host       Host to check status ports
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
    *)
      printf "Error: Invalid argument.\n"
      usage
      exit 1
  esac
  shift
done

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
ORANGE='\033[0;33m'
NC='\033[0m'

get_status()
{
  VARIABLE=$1
  echo `mysql --login-path=${LOGIN_PATH} \
              -h ${HOST} \
              -Bse "SHOW STATUS LIKE '${VARIABLE}'" \
        | awk -F '\t' '{print $2}'`
}

get_variables()
{
  VARIABLE=$1
  echo `mysql --login-path=${LOGIN_PATH} \
              -h ${HOST} \
              -Bse "SHOW VARIABLES LIKE '${VARIABLE}'" \
        | awk -F '\t' '{print $2}'`
}

get_xinetd()
{
  echo `curl --write-out %{http_code} \
             --silent \
             --output /dev/null \
             http://${HOST}:9200`
}

SST_USER=`mysql --login-path=${LOGIN_PATH} \
                -h ${HOST} \
                -Bse "SHOW GRANTS FOR sst@localhost"`
SST_USER="${SST_USER:6:39}"
WSREP_UUID=$(get_status 'wsrep_cluster_state_uuid')
WSREP_CONF=$(get_status 'wsrep_cluster_conf_id')
WSREP_NAME=$(get_variables 'wsrep_cluster_name')
WSREP_SIZE=$(get_status 'wsrep_cluster_size')
WSREP_STATUS=$(get_status 'wsrep_cluster_status')
WSREP_STATE=$(get_status 'wsrep_local_state_comment')
WSREP_FLOW=$(get_status 'wsrep_flow_control_paused')
WSREP_SEND=$(get_status 'wsrep_local_send_queue_avg')
WSREP_CONNECTED=$(get_status 'wsrep_connected')
WSREP_READY=$(get_status 'wsrep_ready')
XINETD=$(get_xinetd)

if [ "$SST_USER" == "RELOAD, LOCK TABLES, REPLICATION CLIENT" ]
then
  SST_PRIVILEGES="${GREEN}OK${NC}\n"
else
  SST_PRIVILEGES="${RED}ERROR${NC}\n"
fi

if [ -z "$WSREP_STATE" ]
then
  WSREP_STATE="${RED}None${NC}\n"
elif [ "$WSREP_STATE" == "Synced" ]
then
  WSREP_STATE="${GREEN}${WSREP_STATE}${NC}\n"
elif [ "$WSREP_STATE" == "Donor/Desynced" ]
then
  WSREP_STATE="${ORANGE}${WSREP_STATE}${NC}\n"
fi

if [ "$WSREP_CONNECTED" == "ON" ]
then
  WSREP_CONNECTED="${GREEN}${WSREP_CONNECTED}${NC}\n"
else
  WSREP_CONNECTED="${RED}${WSREP_CONNECTED}${NC}\n"
fi

if [ "$WSREP_READY" == "ON" ]
then
  WSREP_READY="${GREEN}${WSREP_READY}${NC}\n"
else
  WSREP_READY="${RED}${WSREP_READY}${NC}\n"
fi

if [ "$WSREP_SIZE" == 2 ]
then
  WSREP_SIZE="${ORANGE}${WSREP_SIZE}${NC}\n"
elif [ "$WSREP_SIZE" > 2 ]
then
  WSREP_SIZE="${GREEN}${WSREP_SIZE}${NC}\n"
else
  WSREP_SIZE="${RED}${WSREP_SIZE}${NC}\n"
fi

if [ "$WSREP_STATUS" == "Primary" ]
then
  WSREP_STATUS="${GREEN}${WSREP_STATUS}${NC}\n"
else
  WSREP_STATUS="${RED}${WSREP_STATUS}${NC}\n"
fi

if [ "$XINETD" == "200" ]
then
  XINETD="${GREEN}${XINETD}${NC}\n"
else
  XINETD="${RED}${XINETD}${NC}\n"
fi

printf "SST Privileges: $SST_PRIVILEGES"
printf "Cluster Name: $WSREP_NAME\n"
printf "Cluster UUID: $WSREP_UUID\n"
printf "Cluster Config ID: $WSREP_CONF\n"
printf "Cluster Size: $WSREP_SIZE"
printf "Cluster Status: $WSREP_STATUS"
printf "Node State: $WSREP_STATE"
printf "Node Connected: $WSREP_CONNECTED"
printf "Node Ready: $WSREP_READY"
printf "Node average for sended queue: $WSREP_SEND\n"
printf "Node fraction of the time: $WSREP_FLOW\n"
printf "eXtended InterNET Daemon: $XINETD"
