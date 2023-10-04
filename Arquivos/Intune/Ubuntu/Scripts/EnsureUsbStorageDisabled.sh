#!/bin/sh

# Description: This script ensures the USB storage is disabled.
#              It applies rules described in CIS Ubuntu Linux 20.04 LTS Benchmark document.
#
# Returns : 0 if successfully disable the USB storage
#           1 if not successful
#
# Usage   : sh EnsureUsbStorageDisabled.sh check - for checking if USB storage is disabled
#           sh EnsureUsbStorageDisabled.sh - for disabling the USB storage
#
# Example : sh EnsureUsbStorageDisabled.sh check - for checking if USB storage is disabled
#           sh EnsureUsbStorageDisabled.sh - for disabling the USB storage
#
# Maintainer : TIVIT Labs - Dev & Delivery Team <599266b4a.TIVIT.onmicrosoft.com@amer.teams.ms>


####################
### CIS Functions
####################


# Check if usb storage is disabled
# return: 0 when usb storage is disabled; 1, otherwise
checkUsbStorageDisabled() {
  MODPROBE_OUT=$(modprobe -n -v usb-storage | grep "install /bin/true")
  LSMOD_OUT=$(lsmod | grep usb-storage)
  if [ ! -z "$MODPROBE_OUT" ]; then
    if [ -z "$LSMOD_OUT" ]; then
      return 0
    fi
  fi
  return 1
}


# Disable usb storage
# return: 0 when usb storage is disabled; 1, otherwise
disableUsbStorage() {
  FILESYSTEM="usb-storage"
  FILE="/etc/modprobe.d/$FILESYSTEM.conf"
  FIND_EXPR="install $FILESYSTEM /bin/true"
  if ! test -f "$FILE"; then
    touch "$FILE"
  fi
  if ! grep -q "$FIND_EXPR" "$FILE"; then
    echo "$FIND_EXPR" > "$FILE"
  fi
  rmmod $FILESYSTEM 2> /dev/null
  checkUsbStorageDisabled
  return $?
}


# Ensure usb storage is disabled
# return: 0 when usb storage is disabled; 1, otherwise
ensureUsbStorageDisabled() {
  if checkUsbStorageDisabled; then
    return 0
  fi
  disableUsbStorage
  checkUsbStorageDisabled
  return $?
}


####################
### Main
####################


DISABLE_OR_CHECK="$1"
ERRORCODE=0

if [ "$DISABLE_OR_CHECK" = "check" ]; then
  echo "Check if usb storage is disabled."
  checkUsbStorageDisabled
else
  echo "Ensure usb storage is disabled."
  ensureUsbStorageDisabled
fi
ERRORCODE="$?"

errorFunc() {
  return $ERRORCODE
}

errorFunc
