#!/bin/sh

# Description: This script ensures permissions on all logfiles are configured
#              It applies rules described in CIS Ubuntu Linux 20.04 LTS Benchmark document.
#
# Returns : 0 if successfully configures permissions on all logfiles
#           1 if not successful
#
# Usage   : sh EnsurePermissionsOnAllLogfilesConfigured.sh - for configuring permissions on all logfiles
#
# Example : sh EnsurePermissionsOnAllLogfilesConfigured.sh - for configuring permissions on all logfiles
#
# Maintainer : TIVIT Labs - Dev & Delivery Team <599266b4a.TIVIT.onmicrosoft.com@amer.teams.ms>


####################
### CIS Functions
####################


# Ensure permissions on all logfiles are configured
# return: 0 when permissions on all logfiles are configured; 1, otherwise
ensurePermissionsOnAllLogfilesConfigured() {
  find /var/log -type f -exec chmod g-wx,o-rwx "{}" + -o -type d -exec chmod g-w,o-rwx "{}" +
}


####################
### Main
####################

ensurePermissionsOnAllLogfilesConfigured
ERRORCODE="$?"


errorFunc() {
  return $ERRORCODE
}

errorFunc
