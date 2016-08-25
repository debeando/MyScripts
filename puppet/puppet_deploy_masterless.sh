#!/bin/bash
# encoding: UTF-8
#
# Title       :puppet_deploy_masterless.sh
# Description :Script to deploy puppet in MasterLess mode.
# Author      :Nicola Strappazzon C. nicola@swapbytes.com
# Date        :2014-08-13
# Version     :0.3
# ==============================================================================

# Set default values:
BRANCH=master
DEBUG=false
TEST=false

# ==============================================================================
# CLI for this script
# ==============================================================================

# Help message of usage this script.
usage()
{
  cat << EOF
  Script to deploy puppet in MasterLess mode. You can deploy specific branch and
  run in test mode.

  usage: $0

  $0 --branch=IN-1234 --debug --test

  OPTIONS:
    --branch Specify name of branch in git repository to deploy
    --debug  Run puppet in debug mode
    --test   Run puppet in test mode
EOF
}


while [ $# -gt 0 ]; do
  case "$1" in
    --branch=*)
      BRANCH="${1#*=}"
      ;;
    --test)
      TEST=true
      ;;
    --debug)
      DEBUG=true
      ;;
    --help)
      usage
      ;;
    *)
      printf "Error: Invalid argument.\n"
      usage
      exit 1
  esac
  shift
done

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

# ==============================================================================
# The script
# ==============================================================================

echo "Deploy branch: ${BRANCH}"

# Set branch in env variable for puppet:
export FACTER_BRANCH=$BRANCH

# Load facter library and set puppet path:
export FACTERLIB=/etc/puppetlabs/code/modules/lib/facter
export PATH=/opt/puppetlabs/bin:$PATH

# Load AWS Credentials, necessary for facter:
. /root/.aws

# Deploy puppet:
cd /etc/puppetlabs/code/
/usr/bin/git checkout -f $BRANCH
/usr/bin/git fetch origin
/usr/bin/git reset --hard origin/$BRANCH
/usr/bin/git submodule init
/usr/bin/git submodule sync
/usr/bin/git submodule update

# Prepare cmd to run puppet:
CMD="/opt/puppetlabs/bin/puppet apply /etc/puppetlabs/code/manifests/site.pp"

if [ $DEBUG == true ]
then
  CMD+=" --debug"
fi

if [ $TEST == true ]
then
  CMD+=" --test"
  CMD+=" --noop"
fi

CMD+=" | tee -a /var/log/puppetlabs/puppet.log"

# Run Puppet locally using puppet apply:
echo "Run puppet..."
eval $CMD
