#!/bin/sh

# Description: This script ensures cron daemon is installed and running.
#              It applies rules described in CIS Ubuntu Linux 20.04 LTS Benchmark document.
#
# Returns : 0 if successfully installed cron daemon
#           1 if not successful
#
# Usage   : sh EnsureCronDaemonEnabledAndRunning.sh - for installing cron daemon
#
# Example : sh EnsureCronDaemonEnabledAndRunning.sh - for installing cron daemon
#
# Maintainer : TIVIT Labs - Dev & Delivery Team <599266b4a.TIVIT.onmicrosoft.com@amer.teams.ms>


####################
### CIS Functions
####################


# Ensure cron daemon is enabled and running
# return: 0 when cron daemon is enabled and running
ensureCronDaemonEnabledAndRunning() {
  SYSTEMCTL_OUT=$(systemctl is-enabled cron 2>/dev/null)
  GREP_OUT=$(systemctl status cron | grep 'Active: active (running) ')
  if [ "$SYSTEMCTL_OUT" = "enabled" ] && [ ! -z "$GREP_OUT" ]; then
    return 0
  else
    systemctl --now enable cron 2>/dev/null
    return $?
  fi
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


####################
### Main
####################


echo "Ensure cron daemon is enabled and running."
ensureCronDaemonEnabledAndRunning
ERRORCODE="$?"


errorFunc() {
  return $ERRORCODE
}

errorFunc
