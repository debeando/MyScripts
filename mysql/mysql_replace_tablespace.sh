#!/bin/bash
# encoding: UTF-8
#
# Title           :mysql_replace_tablespace.sh
# Description     :Replace all tablespece from backed.
# Author          :Nicola Strappazzon C. nicola@swapbytes.com
# Date            :2016-10-20
# Version         :0.1
# ==============================================================================
#
# Todo:
# - Validar que las tablas a importar sean InnoDB.
# - Puede que dependiendo del tamaño del disco se requiera hacer un CP o un MV
# - Desactivar los FK
# - Verificar que no haya replicación activa.

MYSQL_HOST='127.0.0.1'
MYSQL_USER='root'
MYSQL_PASSWORD=''
MYSQL_SCHEMA='api_prod'
BACKUP_DIR="/var/lib/mysql/xtrabackup/${MYSQL_SCHEMA}/${MYSQL_SCHEMA}"
DATA_DIR='/var/lib/mysql'

TABLES=`mysql --user=${MYSQL_HOST} \
              --user=${MYSQL_USER} \
              --password=${MYSQL_PASSWORD} \
              ${MYSQL_SCHEMA} -N -e \
        "SELECT table_name
         FROM information_schema.tables
         WHERE table_schema = '${MYSQL_SCHEMA}';" \
        | awk -F "\t" '{if ($1) print $1}'`

for TABLE in $TABLES; do
  echo "-- Import table: ${TABLE}"

#  mysql --host="${MYSQL_HOST}" \
#        --user="${MYSQL_USER}" \
#        --password="${MYSQL_PASSWORD}" \
#        ${MYSQL_SCHEMA} -e \
echo "
ALTER TABLE ${MYSQL_SCHEMA}.${TABLE} DISCARD TABLESPACE;
FLUSH TABLE ${MYSQL_SCHEMA}.${TABLE} FOR EXPORT;
SYSTEM ls -lah ${BACKUP_DIR}/${TABLE}.*
SYSTEM ls -lah ${DATA_DIR}/${MYSQL_SCHEMA}/${TABLE}.*
SYSTEM rm ${DATA_DIR}/${MYSQL_SCHEMA}/${TABLE}.*
SYSTEM cp ${BACKUP_DIR}/${TABLE}.* ${DATA_DIR}/${MYSQL_SCHEMA}/
SYSTEM chown mysql. ${DATA_DIR}/${MYSQL_SCHEMA}/${TABLE}.*
UNLOCK TABLES;
ALTER TABLE ${MYSQL_SCHEMA}.${TABLE} IMPORT TABLESPACE;
SELECT COUNT(*) FROM ${MYSQL_SCHEMA}.${TABLE};
"

  STATUS=$?

  if [ "${STATUS}" != 0 ] || [ -z "${TABLES}" ]; then
    echo "Error to import table: ${MYSQL_SCHEMA}.${TABLE}"
    exit 1
  fi

done