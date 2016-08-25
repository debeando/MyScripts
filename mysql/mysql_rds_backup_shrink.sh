#!/bin/bash
# encoding: UTF-8
#
# Title           :mysql_rds_backup_shrink.sh
# Description     :MySQL Dump by where condition on database.
# Author          :Nicola Strappazzon C. nicola@swapbytes.com
# Date            :2014-11-11
# Version         :0.1
# ==============================================================================

# Set default values:
AWS_S3_BUCKET=
BACKUP_PATH=/mnt/data/shrink
BACKUP_TIME=$(date '+%Y%m%d%H%M')
BACKUP_FILE=strike_beta.sql
DATABASE=
DEBUGLOG=/tmp/debug
LOGIN_PATH=

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
    --aws_s3_bucket Name of S3 Bucket to upload dump
    --database      Name of database
    --login-path    Login Path to connect to server
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
DUMP_PATH=$BACKUP_PATH/${DATABASE}/$BACKUP_TIME

log "Clear old dump..."

if [ -d $BACKUP_PATH ]
then
  rm -rf $BACKUP_PATH
fi

log "Start dump & compress for: ${DATABASE}"

mkdir -p $DUMP_PATH

mysqldump --login-path=${LOGIN_PATH} \
          --default-character-set=utf8 \
          --quick \
          --hex-blob \
          --single-transaction \
          --max_allowed_packet=128M \
          $DATABASE | gzip > $DUMP_PATH/$BACKUP_FILE.gz

log "Upload dump to S3://${AWS_S3_BUCKET}/"

aws s3 cp $DUMP_PATH/${BACKUP_FILE}.gz s3://$AWS_S3_BUCKET/${BACKUP_FILE}.gz

if [ $? -eq 0 ]; then
  log "Finish dump."
else
  log "Failed to upload dump."
fi
