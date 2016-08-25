#!/bin/bash
# encoding: UTF-8
#
# Title           :mysql_restore_devel.sh
# Description     :Restore obfuscate database for developers in local pc.
# Author          :Nicola Strappazzon C. nicola@swapbytes.com
# Date            :2014-09-03
# Version         :0.4
# ==============================================================================
# Set default values:
MYSQL_HOST=${MYSQL_HOST:-'127.0.0.1'}
MYSQL_USER=${MYSQL_USER:-'root'}
MYSQL_PASS=${MYSQL_PASS:-''}
MYSQL_SCHEMA=${MYSQL_SCHEMA:-''}
MYSQL_STRIPPED=${MYSQL_STRIPPED:-'users|redeems|coupons|credit_cards|orders'}
DUMP_FILE=${DUMP_FILE:-''}
DUMP_BUCKET=${DUMP_BUCKET:-''}

# ==============================================================================
# CLI for this script
# ==============================================================================

# Help message of usage this script.
usage()
{
  cat << EOF
  usage: $0

  $0 --host=127.0.0.1 --user=root --password=black --schema=test --ignore-tables='foo|bar'

  OPTIONS:
    --host          MySQL Hostname
    --user          MySQL Username
    --password      MySQL Password
    --schema        MySQL Schema
    --bucket        S3 Bucket Name to download dump
    --backup        Backup file name to download from S3 Bucket
    --ignore-tables List of tables ignored to restore dump
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --host=*)
      MYSQL_HOST="${1#*=}"
      ;;
    --user=*)
      MYSQL_USER="${1#*=}"
      ;;
    --password=*)
      MYSQL_PASS="${1#*=}"
      ;;
    --schema=*)
      MYSQL_SCHEMA="${1#*=}"
      ;;
    --ignore-tables=*)
      MYSQL_STRIPPED="${1#*=}"
      ;;
    --bucket=*)
      DUMP_BUCKET="${1#*=}"
      ;;
    --backup=*)
      DUMP_FILE="${1#*=}"
      ;;
    *)
      printf "Error: Invalid argument.\n"
      usage
      exit 1
  esac
  shift
done

# Validate de minimal arguments required.
if [[ ( ! -n "$MYSQL_HOST")   ||
      ( ! -n "$MYSQL_USER")   ||
      ( ! -n "$MYSQL_SCHEMA") ||
      ( ! -n "$DUMP_FILE")    ||
      ( ! -n "$DUMP_BUCKET")  ]]
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
  echo "Can't find the aws command, please install."
  exit 1
fi

if ( ! type -P 'pv' > /dev/null )
then
  echo "Can't find the pv command, please install."
  exit 1
fi

if [ ! -f ~/.aws/credentials ]
then
  echo 'AWS does not seem to be configured, please run "$> aws configure".'
  exit 1
fi

# ==============================================================================
# The script
# ==============================================================================

# Check mysql version
MYSQL_VERSION=`mysql --host=${MYSQL_HOST} \
                     --user=${MYSQL_USER} \
                     --password=${MYSQL_PASS} \
                     -ssse "SELECT SUBSTRING(VERSION(), 1, 3) AS version\G" \
               | grep version \
               | tail -n 1 \
               | awk {'print $2'}
               `

if [ $MYSQL_VERSION != '5.6' ]
then
  echo "Invalid MySQL ${MYSQL_VERSION} version, please install MySQL 5.6."
  exit 1
fi

# Check time zone
MYSQL_TIMEZONE=`mysql --host=${MYSQL_HOST} \
                      --user=${MYSQL_USER} \
                      --password=${MYSQL_PASS} \
                      -ssse "SELECT @@session.time_zone;"`

if [ $MYSQL_TIMEZONE != 'UTC' ]
then
  if [ ! -d /usr/share/zoneinfo ]
  then
    echo "Can't find time zone info in your local machine."
    exit 1
  fi

  echo "Install time zones into MySQL Server..."
  mysql_tzinfo_to_sql /usr/share/zoneinfo | \
  mysql --host=${MYSQL_HOST} \
        --user=${MYSQL_USER} \
        --password=${MYSQL_PASS} \
        --force \
        mysql

  echo "Set time zones into MySQL Server."
  mysql --host=${MYSQL_HOST} \
        --user=${MYSQL_USER} \
        --password=${MYSQL_PASS} \
        -e "SET GLOBAL time_zone = 'UTC';"
fi

# Download dump
if [ ! -f ~/Downloads/$DUMP_FILE ]
then
  echo "Downloading and stripping dump..."
  aws s3 cp s3://$DUMP_BUCKET/$DUMP_FILE ~/Downloads/
fi

if [[ ( -n "$MYSQL_STRIPPED") ]]
then
  echo "Uncompress & Stripping dump..."
  echo "Ignore this tables: ${MYSQL_STRIPPED//|/, }."

  zgrep -v -E "INSERT INTO \`(${MYSQL_STRIPPED})\`" ~/Downloads/$DUMP_FILE \
  > ~/Downloads/$DUMP_FILE
else
  echo "Uncompress dump..."
  gunzip ~/Downloads/$DUMP_FILE
fi

# Restore dump
echo "Restoring dump..."
mysql --host=${MYSQL_HOST} \
      --user=${MYSQL_USER} \
      --password=${MYSQL_PASS} \
      -e "DROP DATABASE IF EXISTS ${MYSQL_SCHEMA};"

mysql --host=${MYSQL_HOST} \
      --user=${MYSQL_USER} \
      --password=${MYSQL_PASS} \
      -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_SCHEMA} CHARACTER SET utf8;
          SET NAMES utf8;
          SET TIME_ZONE='+00:00';
          SET GLOBAL UNIQUE_CHECKS=0;
          SET GLOBAL FOREIGN_KEY_CHECKS=0;"

pv ~/Downloads/$DUMP_FILE |
mysql --host=${MYSQL_HOST} \
      --user=${MYSQL_USER} \
      --password=${MYSQL_PASS} \
      --force \
      $MYSQL_SCHEMA

mysql --host=${MYSQL_HOST} \
      --user=${MYSQL_USER} \
      --password=${MYSQL_PASS} \
      -e "SET GLOBAL UNIQUE_CHECKS=1;
          SET GLOBAL FOREIGN_KEY_CHECKS=1;"

echo "Remove dump..."
rm -fv ~/Downloads/$DUMP_FILE

echo "Finish :)"
