#!/bin/sh

# Description: This script configures secure boot
#              It applies rules described in CIS Ubuntu Linux 20.04 LTS Benchmark document.
#
# Returns : 0 if successfully configure secure boot
#           1 if not successful
#
# Usage   : sh ConfigureSecureBoot.sh password check - for checking if bootloader password is set
#           sh ConfigureSecureBoot.sh password - for configuring bootloader password
#           sh ConfigureSecureBoot.sh permissions - for configuring bootloader permissions
#           sh ConfigureSecureBoot.sh auth check - for checking if authentication for single user mode is set
#           sh ConfigureSecureBoot.sh auth - for configuring authentication for single user mode
#
# Example : sh ConfigureSecureBoot.sh password check - for checking if bootloader password is set
#           sh ConfigureSecureBoot.sh password - for configuring bootloader password
#           sh ConfigureSecureBoot.sh permissions - for configuring bootloader permissions
#           sh ConfigureSecureBoot.sh auth check - for checking if authentication for single user mode is set
#           sh ConfigureSecureBoot.sh auth - for configuring authentication for single user mode
#
# Maintainer : TIVIT Labs - Dev & Delivery Team <599266b4a.TIVIT.onmicrosoft.com@amer.teams.ms>


####################
### CIS Functions
####################


# Checks if bootloader password is set
# return: 0 when bootloader password is set; 1, otherwise
checkBootloaderPasswordSet() {
  FILE=/boot/grub/grub.cfg
  if grep -q "^password" "$FILE"; then
    return 0
  fi
  return 1
}


# Ensure bootloader password is set
# return: 0 when bootloader password is set; 1, otherwise
ensureBootloaderPasswordSet() {
  return 1
}


# Ensure permissions on bootloader config are configured
# return: 0 when permissions on bootloader config are configured; 1, otherwise
ensurePermissionsBootloaderConfigured() {
  FILE=/boot/grub/grub.cfg
  GREP_OUT=$(stat "$FILE" | grep 'Access: (0400' | grep 'Uid: *( *0/ *root)' | grep 'Gid: *( *0/ *root)')
  if [ -z "$GREP_OUT" ]; then
    chown root:root $FILE
    chmod og-rwx $FILE
  fi
  return 0
}


# Check authentication for single user mode
# return: 0 when authentication for single user mode is set; 1, otherwise
checkAuthSet() {
  GREP_OUT=$(grep ^root:[*\!]: /etc/shadow)
  if [ -z "$GREP_OUT" ]; then
    return 0
  fi
  return 1
}


# Ensure authentication required for single user mode
# return: 0 when authentication required for single user mode exists; 1, otherwise
ensureAuthRequired() {
  if ! checkAuthSet; then
    passwd root
    echo $?
  fi
  return 1
}


####################
### Main
####################


OPTION="$1"
CONFIGURE_OR_CHECK="$2"
ERRORCODE=0

case $OPTION in
password)
  if [ "$CONFIGURE_OR_CHECK" = "check" ]; then
    echo "Check if bootloader password is set."
    checkBootloaderPasswordSet
  else
    echo "Ensure bootloader password is set."
    ensureBootloaderPasswordSet
  fi
  ERRORCODE="$?"
  break
  ;;
permissions)
  echo "Ensure permissions on bootloader config are configured."
  ensurePermissionsBootloaderConfigured
  ERRORCODE="$?"
  break
  ;;
auth)
  if [ "$CONFIGURE_OR_CHECK" = "check" ]; then
    echo "Check if authentication for single user mode is set."
    checkAuthSet
  else
    echo "Ensure authentication required for single user mode."
    ensureAuthRequired
  fi
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