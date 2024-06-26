#!/bin/bash

# Parameters
OPTION="$1"
ACCESS_KEY=${ACCESS_KEY:-"NULL"}
GCSPATH=${GCSPATH:?"GCSPATH required"}
GCSOPTIONS=${GCSOPTIONS}
CRON_SCHEDULE=${CRON_SCHEDULE:-0 * * * *}

# Internal variables
LOCKFILE="/tmp/gcloudlock.lock"
LOG="/var/log/cron.log"

# Create logfile if does not exists
if [ ! -e $LOG ]; then
    touch $LOG
fi

# Functions definition
log_info()
{
    INPUT=$1
    echo "$INPUT" >> $LOG
}


# Welcome
echo "Welcome to Google Cloud Storage Docker"
echo "A backup utility to GCP Bucket"

if [[ $OPTION = "setup" ]]; then
  CRONFILE="/etc/crontabs/root"

  echo "Configuring access to Google Cloud..."
  echo $ACCESS_KEY | base64 -d > /tmp/key.json
  CLOUDSDK_PYTHON="python3" sh /google-cloud-sdk/bin/gcloud auth activate-service-account --key-file=/tmp/key.json

  echo "Adding CRON schedule: $CRON_SCHEDULE"

  rm -f $CRONFILE
  rm -f $LOCKFILE

  echo "$CRON_SCHEDULE sh /opt/run.sh backup" >> $CRONFILE
  echo "Starting CRON scheduler: $(date)"
  cat $CRONFILE
  crond
  exec tail -f $LOG >> /proc/1/fd/1

elif [[ $OPTION = "backup" ]]; then
  log_info "Starting sync: $(date)"

  if [ -f $LOCKFILE ]; then
    log_info "$LOCKFILE detected, exiting! Already running?"
    exit 1
  else
    touch $LOCKFILE
  fi

  export CMD="CLOUDSDK_PYTHON=\"python3\" sh /google-cloud-sdk/bin/gsutil -m rsync -r $GCSOPTIONS /data/backup $GCSPATH"
  log_info "Executing: $CMD"
  eval "$CMD" >> $LOG 2>&1
  
  rm -f $LOCKFILE
  log_info "Finished sync: $(date)"
else
  log_info "Unsupported option: $OPTION"
  log_info "See documentation on available options."
  exit 1
fi
