#!/usr/bin/env python
"""
BEFORE RUNNING:
---------------
1. If not already done, enable the Compute Engine API
   and check the quota for your project at
   https://console.developers.google.com/apis/api/compute
2. This sample uses Application Default Credentials for authentication.
   If not already done, install the gcloud CLI from
   https://cloud.google.com/sdk and run
   `gcloud beta auth application-default login`.
   For more information, see
   https://developers.google.com/identity/protocols/application-default-credentials
3. Install the Python client library for Google APIs by running
   `pip install --upgrade google-api-python-client`
"""

from datetime import *
import dateutil.parser
from pprint import pprint
from googleapiclient import discovery
from oauth2client.client import GoogleCredentials
import re
import time
import requests
import json
import sys


credentials = GoogleCredentials.get_application_default()

service = discovery.build('compute', 'v1', credentials=credentials)

# Project ID for this request.
project = '<enter-gcp-project-here>'  # TODO: Update placeholder value.

# The name of the zone for this request.
zone = ''  # TODO: Update placeholder value.

# retention for deleting snapshot in days.
retention_days = 30

# Enter snapshot prefix here(should be same as disk name to create snapshot from).
snap_name = "diskname"

slack_token = "xoxo-***" ## Enter your slack notification token here.

url = "" ## Enter Slack Hook URL here.
message = snap_name
title = (f"Following snapshot creation failed :zap:")

storage_loc = "asia"

slack_data = {
        "username": "abc",
        "icon_emoji": ":satellite:",
        "channel": "#random-channel",
        "attachments": [
            {
                "color": "#9733EE",
                "fields": [
                    {
                        "title": title,
                        "value": message,
                        "short": "false",
                    }
                ]
            }
        ]
    }

byte_length = str(sys.getsizeof(slack_data))
headers = {'Content-Type': "application/json", 'Content-Length': byte_length}

def delete_snapshot():
    month_time = datetime.now(timezone.utc) - timedelta(days=retention_days)
    request = service.snapshots().list(project=project)
    while request is not None:
        response = request.execute()

        for snapshot in response['items']:
            if re.search(snap_name + '-devopsinside-' + '.+', snapshot['name']):
                snapshot_time = dateutil.parser.parse(snapshot['creationTimestamp'])
                if snapshot_time < month_time:
                    print(f'Following snapshots will be deleted:')
                    print(f'{snapshot["name"]} is older than {retention_days} days')
                    time.sleep(10)
                    ## Below is the deletion of snapshot logic.
                    del_request = service.snapshots().delete(project=project, snapshot=snapshot['name'])
                    response = del_request.execute()
                    print(response)
                    return "Deleted snapshot" + snapshot['name']
                else:
                    return("No previous snapshots found...")

        request = service.snapshots().list_next(previous_request=request, previous_response=response)


def create_snapshot():
    today_date = date.today().strftime("%d-%m-%Y")
    disk_name = snap_name
    snapshot_name = disk_name + "-devopsinside-" + today_date

    snapshot_body = {
        # TODO: Add desired entries to the request body.
        'name': snapshot_name,
        'description': "Auto-created by script.",
        'storageLocations': [storage_loc]
    }

    request = service.disks().createSnapshot(project=project, zone=zone, disk=disk_name, body=snapshot_body)
    response = request.execute()

    if response:
        print("SUCCESS")
    else:
        print("Something went wrong in create_snapshot. Sending an alert")
        response = requests.post(url, data=json.dumps(slack_data), headers=headers)
        if response.status_code != 200:
            raise Exception(response.status_code, response.text)


    return f'Snapshot process for disk {disk_name} initiated.'

create = create_snapshot()
print(create)

delete_snap = delete_snapshot()
print(delete_snap)
