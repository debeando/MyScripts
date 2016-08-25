#!/bin/bash
# encoding: UTF-8
#
# Title           :mysql_multimaster.sh
# Description     :Multimaster replication setup between RDS and EC2.
# Author          :Nicola Strappazzon C. nicola@swapbytes.com
# Date            :2016-05-12
# Version         :0.1
# ==============================================================================

# Set default values:
RESTORE_PATH=${RESTORE_PATH:-/mnt/data/restore/}
MYSQL_REPLICA_USER=${MYSQL_REPLICA_USER:-mmmrepl}
MYSQL_REPLICA_PASSWORD=$(date +%s | sha256sum | base64 | head -c 32)
MYSQL_ADMIN_USER=${MYSQL_ADMIN_USER:-}
MYSQL_ADMIN_PASS=${MYSQL_ADMIN_PASS:-}
RESET=false

# ==============================================================================
# CLI for this script
# ==============================================================================

# Help message of usage this script.
usage()
{
  cat << EOF
  usage: $0

  $0 --host-01=master01 --host-02=master02

  OPTIONS:
    --host-01  Host to connect to RDS server (Master01)
    --host-02  Host to connect to EC2 server (Master02)
    --user     Admin user
    --password Admin user password
    --reset    Stop and Reset replication
EOF
}

log()
{
  MESSAGE=$1
  echo $(date '+%Y-%m-%d %H:%M:%S')" - ${MESSAGE}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --host-01=*)
      MYSQL_REPLICA_HOST_M01="${1#*=}"
      ;;
    --host-02=*)
      MYSQL_REPLICA_HOST_M02="${1#*=}"
      ;;
    --user=*)
      MYSQL_ADMIN_USER="${1#*=}"
      ;;
    --password=*)
      MYSQL_ADMIN_PASS="${1#*=}"
      ;;
    --reset)
      RESET=true
      ;;
    *)
      printf "Error: Invalid argument.\n"
      usage
      exit 1
  esac
  shift
done

# Validate de minimal arguments required.
if [[ ( ! -n "$MYSQL_REPLICA_HOST_M01") ||
      ( ! -n "$MYSQL_REPLICA_HOST_M02") ]]
then
  usage
  exit 1
fi

# Validate de minimal arguments required.
if [[ ( ! -n "$MYSQL_ADMIN_USER") ||
      ( ! -n "$MYSQL_ADMIN_PASS") ]]
then
  echo "Require to set admin user and password for this env variables:"
  echo "  export MYSQL_ADMIN_USER=root"
  echo "  export MYSQL_ADMIN_PASS=password"
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
if [ $RESET == true ]
then
  log "Master 01 (RDS) Stop and reset replication..."
  mysql --host=$MYSQL_REPLICA_HOST_M01 \
        --user=$MYSQL_ADMIN_USER \
        --password=$MYSQL_ADMIN_PASS \
        --execute="
  CALL mysql.rds_stop_replication;
  CALL mysql.rds_reset_external_master;
  " > /dev/null 2>&1

  log "Master 02 (EC2) Stop and reset replication..."
  mysql --execute="
  STOP SLAVE;
  RESET SLAVE;
  " 2>&1

  exit 0
fi

log "Master 01 (RDS) Setting replication user..."

USER_EXIST=$(mysql --host=$MYSQL_REPLICA_HOST_M01 --user=$MYSQL_ADMIN_USER --password=$MYSQL_ADMIN_PASS -Bse "SELECT EXISTS (SELECT DISTINCT USER FROM mysql.user WHERE USER = '${MYSQL_REPLICA_USER}');" 2>/dev/null)
if [ "$USER_EXIST" == "1" ]
then
  mysql --host=$MYSQL_REPLICA_HOST_M01 \
        --user=$MYSQL_ADMIN_USER \
        --password=$MYSQL_ADMIN_PASS \
        --execute="DROP USER ${MYSQL_REPLICA_USER};" 2>/dev/null
fi

mysql --host=$MYSQL_REPLICA_HOST_M01 \
      --user=$MYSQL_ADMIN_USER \
      --password=$MYSQL_ADMIN_PASS \
      --execute="CREATE USER '${MYSQL_REPLICA_USER}'@'%' IDENTIFIED BY '${MYSQL_REPLICA_PASSWORD}';" 2>/dev/null

mysql --host=$MYSQL_REPLICA_HOST_M01 \
      --user=$MYSQL_ADMIN_USER \
      --password=$MYSQL_ADMIN_PASS \
      --execute="GRANT REPLICATION SLAVE ON *.* TO ${MYSQL_REPLICA_USER}@'%'IDENTIFIED BY '${MYSQL_REPLICA_PASSWORD}';" 2>/dev/null

log "Master 02 (EC2) Setting replication user..."

USER_EXIST=$(mysql -Bse "SELECT EXISTS (SELECT DISTINCT USER FROM mysql.user WHERE USER = '${MYSQL_REPLICA_USER}');" 2>/dev/null)
if [ "$USER_EXIST" == "1" ]
then
  mysql --execute="DROP USER ${MYSQL_REPLICA_USER}" 2>/dev/null
fi

mysql --execute="CREATE USER '${MYSQL_REPLICA_USER}'@'%' IDENTIFIED BY '${MYSQL_REPLICA_PASSWORD}';" 2>/dev/null

mysql --execute="GRANT REPLICATION SLAVE ON *.* TO ${MYSQL_REPLICA_USER}@'%' IDENTIFIED BY '${MYSQL_REPLICA_PASSWORD}';" 2>/dev/null

# ------------------------------------------------------------------------------
# Set Master01 (RDS to EC2):
# ------------------------------------------------------------------------------
MASTER_LOG_FILE=`mysql -Bse "SHOW MASTER STATUS\G" 2>&1 \
                 | grep File \
                 | tail -n 1 \
                 | awk {'print $2'}`
MASTER_LOG_POS=`mysql -Bse "SHOW MASTER STATUS\G" 2>&1 \
                | grep Position \
                | tail -n 1 \
                | awk {'print $2'}`

log "Master 01 (RDS) Gettig variable value MASTER_LOG_FILE=${MASTER_LOG_FILE} from Master 02"
log "Master 01 (RDS) Gettig variable value MASTER_LOG_POS=${MASTER_LOG_POS} from Master 02"
log "Master 01 (RDS) Setting bin log position..."

mysql --host=$MYSQL_REPLICA_HOST_M01 \
      --user=$MYSQL_ADMIN_USER \
      --password=$MYSQL_ADMIN_PASS \
      --execute="
CALL mysql.rds_stop_replication;
CALL mysql.rds_reset_external_master;
CALL mysql.rds_set_external_master (
  '${MYSQL_REPLICA_HOST_M02}'
  , 3306
  , '${MYSQL_REPLICA_USER}'
  , '${MYSQL_REPLICA_PASSWORD}'
  , '${MASTER_LOG_FILE}'
  , '${MASTER_LOG_POS}',
  0
);
CALL mysql.rds_start_replication;
" > /dev/null 2>&1

# ------------------------------------------------------------------------------
# Set Master02 (EC2 to RDS):
# ------------------------------------------------------------------------------
MASTER_LOG_FILE=`cat $RESTORE_PATH/bin_log_position.txt \
                 | grep MASTER_LOG_FILE \
                 | awk {'print $2'}`

MASTER_LOG_POS=`cat $RESTORE_PATH/bin_log_position.txt \
                 | grep MASTER_LOG_POS \
                 | awk {'print $2'}`

log "Master 02 (EC2) Gettig variable value MASTER_LOG_FILE=${MASTER_LOG_FILE} from Master 01"
log "Master 02 (EC2) Gettig variable value MASTER_LOG_POS=${MASTER_LOG_POS} from Master 01"
log "Master 02 (EC2) Setting bin log position..."

mysql --execute="
STOP SLAVE;
RESET SLAVE;
CHANGE MASTER TO
MASTER_HOST='${MYSQL_REPLICA_HOST_M01}',
MASTER_USER='${MYSQL_REPLICA_USER}',
MASTER_PASSWORD='${MYSQL_REPLICA_PASSWORD}',
MASTER_LOG_FILE='${MASTER_LOG_FILE}',
MASTER_LOG_POS=${MASTER_LOG_POS};
START SLAVE;
" 2>&1
