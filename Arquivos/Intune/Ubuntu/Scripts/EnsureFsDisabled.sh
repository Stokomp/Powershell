#!/bin/sh

# Description: This script ensures the filesystem is disabled.
#              It applies rules described in CIS Ubuntu Linux 20.04 LTS Benchmark document.
#
# Params  : $1 - The filesystem type. Accepts cramfs, freevxfs, jffs2, hfs, hfsplus, udf e vfat
#
# Returns : 0 if successfully disable a filesystem
#           1 if not successful
#
# Usage   : sh EnsureFsDisabled.sh FILESYSTEM check - for checking if filesystem is disabled
#           sh EnsureFsDisabled.sh FILESYSTEM - for disabling the filesystem
#
# Example : sh EnsureFsDisabled.sh cramfs check - for checking if cramfs filesystem is disabled
#           sh EnsureFsDisabled.sh cramfs - for disabling cramfs filesystem
#           sh EnsureFsDisabled.sh vfat check - for checking if cramfs filesystem is disabled
#           sh EnsureFsDisabled.sh vfat - for disabling vfat filesystem (if not using UEFI boot)
#
# Maintainer : TIVIT Labs - Dev & Delivery Team <599266b4a.TIVIT.onmicrosoft.com@amer.teams.ms>


####################
### CIS Functions
####################


# Check if mounting of a filesystem is disabled
# param $1: filesystem type
# return: 0 when filesystem is disabled; 1, otherwise
checkFsDisabled() {
  FILESYSTEM="$1"
  MODPROBE_OUT=$(modprobe -n -v $FILESYSTEM | grep -E "($FILESYSTEM|install)" | grep "install /bin/true")
  LSMOD_OUT=$(lsmod | grep "$FILESYSTEM")
  if [ ! -z "$MODPROBE_OUT" ]; then
    if [ -z "$LSMOD_OUT" ]; then
      return 0
    fi
  fi
  return 1
}


# Disable mounting of a filesystem
# param $1: filesystem type
# return: 0 when filesystem is disabled; 1, otherwise
disableFs() {
  FILESYSTEM="$1"
  FILE="/etc/modprobe.d/$FILESYSTEM.conf"
  FIND_EXPR="install $FILESYSTEM /bin/true"
  if ! test -f "$FILE"; then
    touch "$FILE"
  fi
  if ! grep -q "$FIND_EXPR" "$FILE"; then
    echo "$FIND_EXPR" > "$FILE"
  fi
  rmmod $FILESYSTEM 2> /dev/null
  checkFsDisabled "$FILESYSTEM"
  return $?
}


# Ensure mounting of a filesystem is disabled
# param $1: filesystem type
# return: 0 when filesystem is disabled; 1, otherwise
ensureFsDisabled() {
  FILESYSTEM="$1"
  if checkFsDisabled "$FILESYSTEM"; then
    return 0
  fi
  disableFs "$FILESYSTEM"
  return $?
}


# Ensure mounting of vfat filesystem is disabled
# return: 0 when vfat filesystem is disabled; 1, otherwise
ensureVfatFsDisabled() {
  if [ -d "/sys/firmware/efi" ]; then
    echo "Using UEFI. Cannot disable vfat filesystem."
    return 0
  else
    ensureFsDisabled 'vfat'
  fi
  return $?
}


####################
### Main
####################

FILESYSTEM="$1"
DISABLE_OR_CHECK="$2"
ERRORCODE=0

case $FILESYSTEM in
cramfs|freevxfs|jffs2|hfs|hfsplus|udf)
  if [ "$DISABLE_OR_CHECK" = "check" ]; then
    echo "Check if filesystem $FILESYSTEM is disabled."
    checkFsDisabled "$FILESYSTEM"
  else
    echo "Ensure filesystem $FILESYSTEM is disabled."
    ensureFsDisabled "$FILESYSTEM"
  fi
  ERRORCODE="$?"
  break
  ;;
vfat)
  if [ "$DISABLE_OR_CHECK" = "check" ]; then
    echo "Check if filesystem $FILESYSTEM is disabled."
    checkFsDisabled "$FILESYSTEM"
  else
    echo "Ensure filesystem $FILESYSTEM is disabled."
    ensureVfatFsDisabled
  fi
  ERRORCODE="$?"
  break
  ;;
*)
  echo "Filesystem $FILESYSTEM is not recognized."
  ERRORCODE=1
  ;;
esac

errorFunc() {
  return $ERRORCODE
}

errorFunc
