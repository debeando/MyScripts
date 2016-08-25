#!/bin/bash
# encoding: UTF-8
#
# Title           :mysql_tail_logs.sh
# Description     :Implement MultiTail for MySQL Logs.
# Author          :Nicola Strappazzon C. nicola@swapbytes.com
# Date            :2016-02-29
# Version         :0.1
# ==============================================================================

if ( ! type -P 'multitail' > /dev/null )
then
  echo "Can't find the multitail, please install."
  exit 1
fi

CMD='multitail'
LOGS_FILES=('/data/error.log'
            '/data/innobackup.backup.log')

for FILE in "${LOGS_FILES[@]}"
do :
  if [ -f "$FILE" ]
  then
    CMD="$CMD $FILE"
  fi
done

eval $CMD
