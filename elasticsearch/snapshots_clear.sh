#!/bin/bash
#
# Clean up script for old elasticsearch snapshots.
#
# You need the jq binary:
# - yum install jq
# - apt-get install jq
# - brew install jq

# The amount of snapshots we want to keep.
LIMIT=3

# Name of our snapshot repository
REPO=backups

HOST="prod-elasticsearch-data02.heygo.private"

# Get a list of snapshots that we want to delete
SNAPSHOTS=$(curl --silent -XGET "${HOST}:9200/_snapshot/${REPO}/_all?pretty" | jq -r ".snapshots[:-${LIMIT}][].snapshot")

# Loop over the results and delete each snapshot
for SNAPSHOT in $SNAPSHOTS
do
  echo "Deleting snapshot: $SNAPSHOT"
  curl -s -XDELETE "${HOST}:9200/_snapshot/$REPO/$SNAPSHOT?pretty"
done
echo "Done!"
