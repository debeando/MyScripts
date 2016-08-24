#!/bin/bash
# encoding: UTF-8
#
# Title           :mysql_rds_backup.sh
# Description     :RDS MySQL Dump by each table on database.
# Author          :Nicola Strappazzon C. nicola@swapbytes.com
# Date            :2014-08-14
# Version         :0.2
# ==============================================================================

# Set default values:
AWS_S3_BUCKET=
BACKUP_PATH=/mnt/data/backups
BACKUP_TIME=$(date '+%Y%m%d%H%M')
DATABASE=
ERRORS=0
LOGIN_PATH=
START_SLAVE=true

# ==============================================================================
# CLI for this script
# ==============================================================================

# Help message of usage this script.
usage()
{
  cat << EOF
  usage: $0

  $0 --login-path=foo --database=demo --aws_s3_bucket=bar

  OPTIONS:
    --aws_s3_bucket    Name of S3 Bucket to upload dump
    --database         Name of database
    --login-path       Login Path to connect to server
    --skip-start-slave Skip start slave when finish dump
EOF
}

log()
{
  MESSAGE=$1
  echo $(date '+%Y-%m-%d %H:%M:%S')" - ${MESSAGE}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --aws_s3_bucket=*)
      AWS_S3_BUCKET="${1#*=}"
      ;;
    --database=*)
      DATABASE="${1#*=}"
      ;;
    --login-path=*)
      LOGIN_PATH="${1#*=}"
      ;;
    --skip-start-slave)
      START_SLAVE=false
      ;;
    *)
      printf "Error: Invalid argument.\n"
      usage
      exit 1
  esac
  shift
done

# Validate de minimal arguments required.
if [[ ( ! -n "$AWS_S3_BUCKET") ||
      ( ! -n "$DATABASE")      ||
      ( ! -n "$LOGIN_PATH")    ]]
then
  usage
  exit 1
fi

# Check installed basic commands to run this script:
if ( ! type -P 'mysqldump' > /dev/null )
then
  echo "Can't find the mysql client command, please install."
  exit 1
fi

if ( ! type -P 'mysql' > /dev/null )
then
  echo "Can't find the mysql client command, please install."
  exit 1
fi

if ( ! type -P 'aws' > /dev/null )
then
  echo "Can't find the aws cli command, please install."
  exit 1
fi

if ( ! type -P 'gzip' > /dev/null )
then
  echo "Can't find the gzip command, please install."
  exit 1
fi

# ==============================================================================
# The script
# ==============================================================================

# Clear and prepare dump directory:
DUMP_PATH=$BACKUP_PATH/${DATABASE}/$BACKUP_TIME
BUCKET_PATH=$AWS_S3_BUCKET/$DATABASE/$BACKUP_TIME

log "Clear and prepare dump directory..."

if [ -d $BACKUP_PATH ]
then
  rm -rf $BACKUP_PATH
fi

mkdir -p $DUMP_PATH

# Detect is host a slave?
SLAVE=`mysql --login-path=${LOGIN_PATH} \
             -Bse "SHOW SLAVE STATUS\G" \
            | wc -l`

# Get LOG File and LOG Position for create replica:
if [ $SLAVE != 0 ]
then
  # The RDS "super user" not have a special privileges, this problem affect the
  # specific parameters on mysqldump: --master-data=1 & --dump-slave.

  log "Stop replica..."

  MESSAGE=`mysql --login-path=${LOGIN_PATH} \
                 -Nbse "CALL mysql.rds_stop_replication;"`

  log "Get LOG File and LOG Position..."

  MASTER_LOG_FILE=`mysql --login-path=${LOGIN_PATH} \
                         -Bse "SHOW SLAVE STATUS\G" \
                   | grep Master_Log_File \
                   | tail -n 1 \
                   | awk {'print $2'}`

  MASTER_LOG_POS=`mysql --login-path=${LOGIN_PATH} \
                        -Bse "SHOW SLAVE STATUS\G" \
                  | grep Read_Master_Log_Pos \
                  | tail -n 1 \
                  | awk {'print $2'}`

  log "MASTER_LOG_FILE: ${MASTER_LOG_FILE}"
  log "MASTER_LOG_POS: ${MASTER_LOG_POS}"

  echo "MASTER_LOG_FILE: ${MASTER_LOG_FILE}" > ${DUMP_PATH}/bin_log_position.txt
  echo "MASTER_LOG_POS: ${MASTER_LOG_POS}" >> ${DUMP_PATH}/bin_log_position.txt
fi

# Dump database:
log "Start dump for: "$DATABASE
log "Dump schema, routines, triggers and events..."

mysqldump --login-path=${LOGIN_PATH} \
          --default-character-set=utf8 \
          --no-data \
          $DATABASE | gzip > $DUMP_PATH/schema.dump.gz

if [ $PIPESTATUS != 0 ]; then
  log "Failed to dump schema: $DATABASE."
  exit 1
fi

log "Get list of tables..."

TABLES=`mysql --login-path=${LOGIN_PATH} $DATABASE -Nse \
        "SHOW FULL TABLES IN $DATABASE WHERE table_type LIKE 'BASE TABLE';" \
        | awk -F "\t" '{if ($1) print $1}'`

for TABLE in $TABLES; do
  log "Dump table: "$TABLE
  mysqldump --login-path=${LOGIN_PATH} \
            --default-character-set=utf8 \
            --no-create-info \
            --compact \
            --hex-blob \
            --net_buffer_length=5m \
            --single-transaction \
            --max_allowed_packet=1G \
            $DATABASE \
            $TABLE | gzip > $DUMP_PATH/table_${TABLE}.dump.gz

  if [ $PIPESTATUS != 0 ]; then
    log "Failed to dump table: $TABLE."
    exit 1
  fi
done

if [[ ( $SLAVE != 0 ) && ( $START_SLAVE = true ) ]]
then
  log "Start replica..."

  MESSAGE=`mysql --login-path=${LOGIN_PATH} \
                 -NBse "CALL mysql.rds_start_replication;"`
else
  log "Skip start replica."
fi

log "Upload dump to S3://${BUCKET_PATH}/"

aws s3 sync $DUMP_PATH/ s3://$BUCKET_PATH

if [ $? -eq 0 ]; then
  log "End dump for: ${DATABASE}"
else
  log "Failed to upload dump."
  exit 1
fi
