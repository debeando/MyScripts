#!/bin/bash
# encoding: UTF-8
#

# Set default values:
DELTA=false

# ==============================================================================
# CLI for this script
# ==============================================================================

# Help message of usage this script.
usage()
{
  cat << EOF
  usage: $0

  $0 --delta

  OPTIONS:
    --delta    Delta import
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --delta)
      DELTA=true
      ;;
    *)
      printf "Error: Invalid argument.\n"
      usage
      exit 1
  esac
  shift
done

# PID Control

PIDFILE=/tmp/sphinx_update_delta.pid
if [ -f $PIDFILE ]
then
  PID=$(cat $PIDFILE)
  ps -p $PID > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    echo "Process already running"
    exit 1
  else
    ## Process not found assume not running
    echo $$ > $PIDFILE
    if [ $? -ne 0 ]
    then
      echo "Could not create PID file"
      exit 1
    fi
  fi
else
  echo $$ > $PIDFILE
  if [ $? -ne 0 ]
  then
    echo "Could not create PID file"
    exit 1
  fi
fi

# Check installed basic commands to run this script:
if ( ! type -P 'indexer' > /dev/null )
then
  echo "Can't find the sphinx indexer command, please install."
  exit 1
fi

# ==============================================================================
# The script
# ==============================================================================

if [ $DELTA == true ]
then
  sudo -u sphinx indexer --rotate users_delta
  sudo -u sphinx indexer --merge users users_delta --rotate
else
  sudo -u sphinx indexer --all --rotate
fi

rm $PIDFILE
