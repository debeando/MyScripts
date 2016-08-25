#!/bin/bash
# encoding: UTF-8
#
# Title           :mysql_restore.sh
# Description     :Restore in parallel dump on MySQL.
# Author          :Nicola Strappazzon C. nicola@swapbytes.com
# Date            :2014-08-10
# Version         :0.2
# ==============================================================================

# Set default values:
AWS_EC2_CORES=4
BACKUP_TIME=
DATABASE=
LOCK_FILE=/tmp/mysql_restore.lock
RESTORE_PATH=/mnt/data/restore/

# ==============================================================================
# CLI for this script
# ==============================================================================

# Help message of usage this script.
usage()
{
  cat << EOF
  This scripts are used to restores in parallel dump in MySQL, with one job per
  table. This brings significant performance increases in most dumps and
  restores. This script only run on MySQL Server, and require the specific dump
  taken with "mysql_rds_backup.sh". For debug any jobs and time to completed,
  please see joblog.txt file.

  usage: $0

  $0 --aws_s3_bucket=bar --database=demo --backup-time=201501010000 --threads=8

  OPTIONS:
    --aws_s3_bucket Name of S3 Bucket to upload dump
    --database      Name of database
    --backup-time   Backup timestamp, ej: YYYYMMDDHHMM
    --threads       Number of CPU core, by default is 4.
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
    --backup-time=*)
      BACKUP_TIME="${1#*=}"
      ;;
    --threads=*)
      AWS_EC2_CORES="${1#*=}"
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
      ( ! -n "$DATABASE")      ]]
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

if ( ! type -P 'aws' > /dev/null )
then
  echo "Can't find the aws cli command, please install."
  exit 1
fi

if ( ! type -P 'zcat' > /dev/null )
then
  echo "Can't find the zcat command, please install."
  exit 1
fi

if ( ! type -P 'parallel' > /dev/null )
then
  echo "Can't find the parallel command, please install."
  exit 1
fi

# ==============================================================================
# The script
# ==============================================================================
if [[ ( ! -n "$BACKUP_TIME") ]]
then
  BACKUP_TIME=`aws s3 ls s3://$AWS_S3_BUCKET/$DATABASE/ | \
               awk -F ' ' '{print substr($0,32,12)}' | sort -n -r | head -n 1`
  log "Last available backup ${BACKUP_TIME}."
fi

log "Clear and prepare dump directory..."

if [ -d $RESTORE_PATH ]
then
  rm -rf $RESTORE_PATH
fi

mkdir -p $RESTORE_PATH
cd $RESTORE_PATH

log "Restore path ${RESTORE_PATH}"
log "Download dump at ${BACKUP_TIME}"

aws s3 sync s3://${AWS_S3_BUCKET}/${DATABASE}/$BACKUP_TIME/ .

log "Create database at ${DATABASE}"

mysql -e "DROP DATABASE IF EXISTS ${DATABASE};"
mysql -e "CREATE DATABASE IF NOT EXISTS ${DATABASE};"
mysql -e "SET GLOBAL unique_checks=0;SET GLOBAL foreign_key_checks=OFF;"

zcat schema.dump.gz | mysql ${DATABASE}

log "Start restore for at ${DATABASE}"

ls -S table_*.dump.gz | parallel -j${AWS_EC2_CORES} \
                                 --joblog joblog.txt \
                                 "zcat {.} | mysql -i ${DATABASE}"

log "End restore for at ${DATABASE}"

# Get LOG File and LOG Position for create replica:
MASTER_LOG_FILE=`cat $RESTORE_PATH/bin_log_position.txt \
                 | grep MASTER_LOG_FILE \
                 | awk {'print $2'}`

MASTER_LOG_POS=`cat $RESTORE_PATH/bin_log_position.txt \
                 | grep MASTER_LOG_POS \
                 | awk {'print $2'}`

log "MASTER_LOG_FILE: ${MASTER_LOG_FILE}"
log "MASTER_LOG_POS: ${MASTER_LOG_POS}"
log "Set bin log position..."

echo "Please run this command in MySQL Server:"
echo "RESET SLAVE;
      CHANGE MASTER TO
      MASTER_LOG_FILE='${MASTER_LOG_FILE}',
      MASTER_LOG_POS=${MASTER_LOG_POS};"
