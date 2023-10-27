#!/bin/bash

# Parameters
OPTION="$1"
BOTO_FILE=${BOTO_FILE:-"NULL"}
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
  CRONENV=""

  echo "Configuring access to Google Cloud..."
  echo $ACCESS_KEY | base64 -d > /tmp/key.json
  gcloud auth activate-service-account --key-file=/tmp/key.json

  echo "Adding CRON schedule: $CRON_SCHEDULE"

  rm -f $CRONFILE
  rm -f $LOCKFILE

  CRONENV="$CRONENV GCSPATH=\"$GCSPATH\""
  CRONENV="$CRONENV GCSOPTIONS=\"$GCSOPTIONS\""
  echo "$CRON_SCHEDULE $CRONENV sh /opt/run.sh backup" >> $CRONFILE
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

  log_info "Executing gsutil sync /data/ $GCSPATH..."
  CLOUDSDK_PYTHON="python3" sh /google-cloud-sdk/bin/gsutil -m rsync -r $GCSOPTIONS /data/backup $GCSPATH >> $LOG 2>&1
  rm -f $LOCKFILE
  log_info "Finished sync: $(date)"
else
  log_info "Unsupported option: $OPTION"
  log_info "See documentation on available options."
  exit 1
fi
