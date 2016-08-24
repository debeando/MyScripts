#!/bin/bash
# encoding: UTF-8
#
# Title           :mysql_obfuscate_wuaki.sh
# Description     :Obfuscate database with wuaki rules.
# Author          :Nicola Strappazzon C. nicola@swapbytes.com
# Date            :2014-08-25
# Version         :0.1
# ==============================================================================

# Set default values:
DATABASE=
LOGIN_PATH=

# ==============================================================================
# CLI for this script
# ==============================================================================

# Help message of usage this script.
usage()
{
  cat << EOF
  usage: $0

  $0 --login-path=foo --database=bar

  OPTIONS:
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
if [[ ( ! -n "$DATABASE") ]]
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

log "Obfuscate users..."
mysql --login-path=$LOGIN_PATH -BNse "
  UPDATE IGNORE $DATABASE.users
     SET email                = CONCAT('email_', id, '@demo.info')
       , username             = CONCAT('email_', id, '@demo.info')
       , cached_slug          = CONCAT('email_', id)
       , authentication_token = NULL
  WHERE email NOT LIKE '%@wuaki.tv';
"

log "Obfuscate spam..."
mysql --login-path=$LOGIN_PATH -BNse "
  UPDATE IGNORE $DATABASE.email_marketing_users
     SET email = CONCAT('email_', user_id, '@demo.info');
"

log "Obfuscate credir cards..."
mysql --login-path=$LOGIN_PATH -BNse "
  UPDATE IGNORE $DATABASE.credit_cards
     SET holder_name      = 'WuakiTV Rakuten'
       , encrypted_number = CASE (FLOOR(1 + RAND() * 3))
                              WHEN 1 THEN \"QsqAaFsVkvcdH35PLqgsLlNlGsNMoyO6RMCK/ir2b4A=\n\"
                              WHEN 2 THEN \"gvTu2P8IAPzig8JGN2kL/ZrCVnvX4o8JNFIFwiXQWwM=\n\"
                              WHEN 3 THEN \"1vov7jI4RZTH86P6h/MxbeYyH8E2x1NSuEZL/RNebo8=\n\"
                            END
  WHERE holder_name <> 'WuakiTV Rakuten';
"

log "Obfuscate billing address..."
mysql --login-path=$LOGIN_PATH -BNse "
  UPDATE IGNORE $DATABASE.billing_addresses
     SET address1 = 'Carrer Doctor Trueta, nº 127-133'
       , address2 = NULL
       , city     = 'Barcelona'
       , state    = 'Barcelona'
       , zip      = '08005'
       , phone    = '+346000000'
       , company  = 'WuakiTV Rakuten'
  WHERE phone <> '+346000000';
"
