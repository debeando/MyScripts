#!/bin/bash
# encoding: UTF-8
#
# Title           :mysql_constraint_names.sh
# Description     :Fix constraint names malformed by pt-online-schema-change
# Author          :Nicola Strappazzon C. nicola@swapbytes.com
# Date            :2016-05-11
# Version         :0.1
# ==============================================================================

# Set default values:
LOGIN_PATH=
DATABASE=

# ==============================================================================
# CLI for this script
# ==============================================================================

# Help message of usage this script.
usage()
{
  cat << EOF
  usage: $0

  $0 --login-path=foo --database=demo

  OPTIONS:
    --login-path Login Path to connect to server
    --database   Database name to apply fix
EOF
}

log()
{
  MESSAGE=$1
  echo $(date '+%Y-%m-%d %H:%M:%S')" - ${MESSAGE}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --login-path=*)
      LOGIN_PATH="${1#*=}"
      ;;
    --database=*)
      DATABASE="${1#*=}"
      ;;
    *)
      printf "Error: Invalid argument.\n"
      usage
      exit 1
  esac
  shift
done

# Validate de minimal arguments required.
if [[ ( ! -n "$LOGIN_PATH") ||
      ( ! -n "$DATABASE")   ]]
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

CONSTRAINTS=(`mysql --login-path=${LOGIN_PATH} \
              -BNse "
SELECT CONSTRAINT_NAME, TABLE_NAME,
       COLUMN_NAME,
       REFERENCED_TABLE_NAME,
       REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE CONSTRAINT_SCHEMA = '${DATABASE}'
  AND CONSTRAINT_NAME LIKE '\_%'
ORDER BY CONSTRAINT_NAME
;"`)

for (( i=1; i<${#CONSTRAINTS[@]}+1; i++ ));
do
  if [ $(($i % 5)) -eq 0 ]
  then
    NAME=$(echo ${CONSTRAINTS[$i - 5]} | sed 's/^_*//g')
    TABLE=${CONSTRAINTS[$i - 4]}
    COLUMN=${CONSTRAINTS[$i - 3]}
    REFERENCED_TABLE=${CONSTRAINTS[$i - 2]}
    REFERENCED_COLUMN=${CONSTRAINTS[$i - 1]}

    SQL_DROP="ALTER TABLE ${TABLE} DROP FOREIGN KEY ${CONSTRAINTS[$i - 5]};"
    SQL_ADD="ALTER TABLE ${TABLE} ADD CONSTRAINT ${NAME} FOREIGN KEY ($COLUMN) REFERENCES $REFERENCED_TABLE ($REFERENCED_COLUMN);"

    log "Rename constraint: ${CONSTRAINTS[$i - 5]}"
    echo "                    - SQL: ${SQL_DROP}"
    echo "                    - SQL: ${SQL_ADD}"

    mysql --login-path=${LOGIN_PATH} ${DATABASE} -BNse "
    SET foreign_key_checks = 0;
    ${SQL_DROP}
    ${SQL_ADD}
    SET foreign_key_checks = 1;"
  fi
done
