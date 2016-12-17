#!/bin/bash
# encoding: UTF-8
#

SLEEP=3
STOP=0

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
  STOP=1
  echo "Wait to stop..."
}

log()
{
  MESSAGE=$1
  echo "$(date '+%Y-%m-%d %H:%M:%S') - ${MESSAGE}"
}

log "Start load data."

for file in `find DBA199/ -name load_dba_199_* -type f | sort`
do
  log "Loading: $file"
  mysql -uroot -p$PASS -D dbchat -e "LOAD DATA LOCAL INFILE '/data/temp/$file' INTO TABLE dbchat.mutes FIELDS TERMINATED BY ',' ENCLOSED BY '\"' (muter_id, muted_id, is_enabled, last_update_at);"
  log "Remove loaded file: $file"
  rm -f $file

  if [ $STOP -eq 1 ]
  then
    log "Stop by CTRL-C"
    exit 1
  else
    log "Wait ${SLEEP}s to load next file..."
    sleep $SLEEP
  fi
done

log "End load data."
