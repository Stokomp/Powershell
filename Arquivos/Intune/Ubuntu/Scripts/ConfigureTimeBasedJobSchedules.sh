#!/bin/sh

# Description: This script configures time-based job schedulers.
#              It applies rules described in CIS Ubuntu Linux 20.04 LTS Benchmark document.
#
# Params  : $1 - The option. Accepts crontab, crond, cron.hourly, cron.daily, cron.weekly, cron.monthly, cron and at
#
# Returns : 0 if successfully configure time-based job schedulers
#           1 if not successful
#
# Usage   : sh ConfigureTimeBasedJobSchedules.sh OPTION - for configuring service
#
# Example : sh ConfigureTimeBasedJobSchedules.sh crontab - for configuring crontab
#           sh ConfigureTimeBasedJobSchedules.sh cron.hourly - for configuring cron.hourly
#           sh ConfigureTimeBasedJobSchedules.sh cron.daily - for configuring cron.daily
#           sh ConfigureTimeBasedJobSchedules.sh cron.weekly - for configuring cron.weekly
#           sh ConfigureTimeBasedJobSchedules.sh cron.monthly - for configuring cron.monthly
#           sh ConfigureTimeBasedJobSchedules.sh crond - for configuring crond
#           sh ConfigureTimeBasedJobSchedules.sh cron - for configuring cron for authorized users only
#           sh ConfigureTimeBasedJobSchedules.sh at - for configuring at for authorized users only
#
# Maintainer : TIVIT Labs - Dev & Delivery Team <599266b4a.TIVIT.onmicrosoft.com@amer.teams.ms>


####################
### CIS Functions
####################

# Check if permissions on file are configured
# param $1: file name
# param $2: expected access information
# return: 0 when permissions on file are configured; 1, otherwise
checkPermissionsFileConfigured() {
  FILE="$1"
  ACCESS_PERMISSION="$2"
  GREP_OUT=$(stat "$FILE" | grep "Access: ($ACCESS_PERMISSION" | grep 'Uid: *( *0/ *root)' | grep 'Gid: *( *0/ *root)')
  if [ -z "$GREP_OUT" ]; then
    return 1
  fi
  return 0
}


# Ensure permissions on file are configured
# param $1: file name
# param $2: expected access information
# return: 0 when permissions on file are configured; 1, otherwise
ensurePermissionsFileConfigured() {
  FILE="$1"
  ACCESS_PERMISSION="$2"
  if ! checkPermissionsFileConfigured $FILE $ACCESS_PERMISSION; then
    chown root:root $FILE
    chmod og-rwx $FILE
  fi
  return 0
}


# Check if deny file does not exist
# param $1: file type
# return: 0 when deny file does not exist; 1, otherwise
checkDenyNotExist() {
  FILE="/etc/$1.deny"
  STAT_OUT=$(stat "$FILE" | grep "No such file or directory")
  if [ ! -z "$STAT_OUT" ]; then
    return 0
  fi
  return 1
}

# Check if allow file exists with right permissions
# param $1: file type
# param $2: expected access information
# return: 0 when allow file exists with right permissions; 1, otherwise
checkAllowExists() {
  FILE="/etc/$1.allow"
  ACCESS_PERMISSION="$2"
  touch $FILE
  if checkPermissionsFileConfigured $FILE $ACCESS_PERMISSION; then
    return 0
  fi
  return 1
}


# Ensure cron is restricted to authorized users
# return: 0 when cron is restricted to authorized users; 1, otherwise
ensureCronRestrictedToAuthorizedUsers() {
  if ! checkDenyNotExist 'cron'; then
    rm /etc/cron.deny
  fi
  if ! checkAllowExists 'cron' '0640'; then
    chmod g-wx,o-rwx /etc/cron.allow
    chown root:root /etc/cron.allow
  fi
  return $?
}


# Ensure at is restricted to authorized users
# return: 0 when at is restricted to authorized users; 1, otherwise
ensureAtRestrictedToAuthorizedUsers() {
  if ! checkDenyNotExist 'at'; then
    rm /etc/at.deny
  fi
  if ! checkAllowExists 'at' '0640'; then
    chmod g-wx,o-rwx /etc/at.allow
    chown root:root /etc/at.allow
  fi
  return $?
}


####################
### Main
####################


OPTION="$1"
ERRORCODE=0

case $OPTION in
crontab)
  echo "Ensure permissions on /etc/crontab are configured."
  ensurePermissionsFileConfigured /etc/crontab "0600"
  ERRORCODE="$?"
  break
  ;;
crond)
  echo "Ensure permissions on /etc/cron.d are configured."
  ensurePermissionsFileConfigured /etc/cron.d/ "0700"
  ERRORCODE="$?"
  break
  ;;
cron\.hourly|cron\.daily|cron\.weekly|cron\.monthly)
  echo "Ensure permissions on /etc/$OPTION/ are configured."
  ensurePermissionsFileConfigured "/etc/$OPTION/" "0700"
  ERRORCODE="$?"
  break
  ;;
cron)
  echo "Ensure cron is restricted to authorized users."
  ensureCronRestrictedToAuthorizedUsers
  ERRORCODE="$?"
  break
  ;;
at)
  echo "Ensure at is restricted to authorized users."
  ensureAtRestrictedToAuthorizedUsers
  ERRORCODE="$?"
  break
  ;;
*)
  echo "Option $OPTION is not recognized."
  ERRORCODE=1
  ;;
esac

errorFunc() {
  return $ERRORCODE
}

errorFunc
