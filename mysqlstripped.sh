#!/bin/bash

usage()
{
  cat << EOF
  usage: $0 dump table1 table2 table3 ...

  $0 -f database.dump -t foo bar

  OPTIONS:
     -f      Dump file
     -t      Tables to ignore
EOF
}

while getopts “f:t:” OPTION
do
  case $OPTION in
    f)
      FILE=$OPTARG
      ;;
    t)
      shift 3
      TABLES=$*
      ;;
    ?)
      usage
      exit
      ;;
    esac
done

if [[ -z $FILE ]] || [[ -z $TABLES ]]
then
  usage
  exit 1
fi

# Join tables.
STRIP=""
for TABLE in $TABLES
do
  STRIP+="|${TABLE}"
done
STRIP=${STRIP:1}

# Stripped dump.
grep -v -E "INSERT INTO \`(${STRIP})\`" $FILE > ${FILE}.stripped
