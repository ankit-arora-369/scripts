#!/bin/bash

set -e
set -u

# Set variables
SOURCE_PROJECT_ID="<enter source project id here>"
SOURCE_INSTANCE_ID="<enter source db instance id here>"
BACKUP_FILE_NAME="backup_ids.txt"
DEST_PROJECT_ID="<enter destination project id here>"
DEST_INSTANCE_ID="<enter destination db instance id here>"

# Obtain the backupId and put it into a file
curl -X GET -H "Authorization: Bearer $(gcloud auth print-access-token)" "https://sqladmin.googleapis.com/v1/projects/$SOURCE_PROJECT_ID/instances/$SOURCE_INSTANCE_ID/backupRuns" > "$BACKUP_FILE_NAME"
echo ""

head -18 "$BACKUP_FILE_NAME"

echo ""
echo ""
echo ""

# Get the latest backup id from file
LATEST_BKP_ID=$(grep -A 2 "SUCCESSFUL" "$BACKUP_FILE_NAME" | grep id | sed 's/ //g' | tr -d '"' | tr -d "," | cut -d ":" -f 2 | head -1)

echo "Latest Backup ID is: $LATEST_BKP_ID"

echo "Waiting for 30 seconds, so that we can cross verify the Backup ID in the console."
sleep 30

# Create request.json
cat << EOF > request.json
{
  "restoreBackupContext":
  {
    "backupRunId": "$LATEST_BKP_ID",
    "project": "$SOURCE_PROJECT_ID",
    "instanceId": "$SOURCE_INSTANCE_ID"
  }
}
EOF

echo ""
echo "Created request.json"
cat request.json
echo ""

echo "Waiting for 30 seconds to verify the content of request.json presented on the screen."
sleep 30

# Restore backup to the new instance
curl -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json; charset=utf-8" -d @request.json "https://sqladmin.googleapis.com/v1/projects/$DEST_PROJECT_ID/instances/$DEST_INSTANCE_ID/restoreBackup"

echo "Restoration started."
