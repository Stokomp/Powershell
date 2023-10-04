#!/bin/sh

# Description: This script ensures the partition is configured.
#              It applies rules described in CIS Ubuntu Linux 20.04 LTS Benchmark document.
#
# Params  : $1 - The partition. Accepts /tmp /dev/shm /var /var/tmp /var/log /var/log/audit /home
#           $2 - The options. If require multiple options, separate each option by whitespaces. Example: "nodev nosuid"
#
# Returns : 0 if successfully configure the partition
#           1 if not successful
#
# Usage   : sh EnsurePartitionConfigured.sh PARTITION OPTIONS check - for checking if partition is configured and has the specified options
#           sh EnsurePartitionConfigured.sh PARTITION OPTIONS - for applying the specified options to partition
#
# Example : sh EnsurePartitionConfigured.sh "/tmp" "nodev nosuid" check - for checking if /tmp partition has the "nodev" and "nosuid" options
#           sh EnsurePartitionConfigured.sh "/tmp" "nodev nosuid" - for applying "nodev" and "nosuid" options to /tmp partition
#
# Maintainer : TIVIT Labs - Dev & Delivery Team <599266b4a.TIVIT.onmicrosoft.com@amer.teams.ms>


####################
### Helper Functions
####################


# Join elements of a given array
# param $1: the multi-character delimiter
# param $2: the array
joinBy() {
  D=$1
  shift
  F=$1
  shift
  printf %s "$F" "${@/#/$D}"
}


####################
### CIS Functions
####################


# Check if tmpfs partition is configured
# param $1: partition
# return: 0 when partition is configured; 1, otherwise
checkTmpfsPartitionConfigured() {
  PARTITION="$1"
  FILE=/etc/fstab
  MOUNT_OUT=$(mount | grep -E "\s$PARTITION\s" | grep "tmpfs on $PARTITION type tmpfs")
  GREP_OUT=$(grep -E "\s$PARTITION\s" "$FILE" | grep -E -v '^\s*#' | grep "tmpfs")
  if [ ! -z "$MOUNT_OUT" ]; then
    if [ ! -z "$GREP_OUT" ]; then
      return 0
    fi
  fi
  return 1
}


# Configure tmpfs partition with mounting options
# param $1: partition
# param $2: mounting options array
# return: 0 when partition is configured; 1, otherwise
configureTmpfsPartition() {
  PARTITION="$1"
  OPTIONS="$2"
  FILE=/etc/fstab
  OPTS=$(joinBy , $OPTIONS)
  ENTRY="\ntmpfs\t$PARTITION\ttmpfs\tdefaults,$OPTS,seclabel\t0\t0"
  GREP_OUT=$(grep -E "\s$PARTITION\s" "$FILE" | grep -E -v '^\s*#')
  if [ -z "$GREP_OUT" ]; then
    echo -e "$ENTRY" >> "$FILE"
  fi
  mount -o remount,$OPTS $PARTITION 2>/dev/null
  if [ ! -z $? ]; then
    mount -o $OPTS $PARTITION
  fi
  checkTmpfsPartitionConfigured $PARTITION
  return $?
}


# Check if ext4 partition is configured
# param $1: partition
# return: 0 when partition is configured; 1, otherwise
checkExt4PartitionConfigured() {
  PARTITION="$1"
  MOUNT_OUT=$(mount | grep -E "\s$PARTITION\s" | grep "on $PARTITION type ext4")
  if [ ! -z "$MOUNT_OUT" ]; then
    return 0
  fi
  return 1
}


# Check if mounting option is set on partition
# param $1: partition
# param $2: mounting option
# return: 0 when mounting option is set on partition; 1, otherwise
checkPartitionMountingOptionSet() {
  PARTITION="$1"
  OPTION="$2"
  FILE=/etc/fstab
  MOUNT_OUT=$(mount | grep -E "\s$PARTITION\s" | grep "$OPTION")
  GREP_OUT=$(grep -E "\s$PARTITION\s" "$FILE" | grep -E -v '^\s*#' | grep "$OPTION")
  if [ ! -z "$MOUNT_OUT" ] && [ ! -z "$GREP_OUT" ]; then
    return 0
  fi
  return 1
}


# Set mounting option on partition
# param $1: partition
# param $2: mounting option
# return: 0 when mounting option is set on partition; 1, otherwise
setPartitionMountingOption() {
  PARTITION="$1"
  OPTION="$2"
  FILE=/etc/fstab
  FIND_EXPR=$(grep -E "\s$PARTITION\s" "$FILE" | grep -E -v '^\s*#')
  REPLACEMENT=$(echo $FIND_EXPR | awk -v OPT=$OPTION '{print $1 "\t" $2 "\t" $3 "\t" $4 "," OPT "\t" $5 "\t" $6}')
  sed -i "s@$FIND_EXPR@$REPLACEMENT@g" "$FILE"
  mount -o remount,$OPTION $PARTITION
  checkPartitionMountingOptionSet $PARTITION $OPTION
  return $?
}


# Ensure partition is configured with correct mounting options
# param $1: partition
# param $2: mounting options array
# return: 0 when mounting option is set on partition; 1, otherwise
ensurePartitionMountingOptions() {
  PARTITION="$1"
  OPTIONS="$2"
  for OPTION in $OPTIONS; do
    if ! checkPartitionMountingOptionSet $PARTITION $OPTION; then
      setPartitionMountingOption $PARTITION $OPTION
    fi
  done
  return $?
}


# Ensure tmpfs partition is configured with correct mounting options
# param $1: partition
# param $2: mounting options array
# return: 0 when mounting option is set on partition; 1, otherwise
ensureTmpfsPartitionConfigured() {
  PARTITION="$1"
  OPTIONS="$2"
  if checkTmpfsPartitionConfigured "$PARTITION"; then
    ensurePartitionMountingOptions "$PARTITION" "$OPTIONS"
    return $?
  fi
  configureTmpfsPartition "$PARTITION" "$OPTIONS"
  return $?
}


# Ensure ext4 partition is configured with correct mounting options
# param $1: partition
# param $2: mounting options array
# return: 0 when partition is configured; 1, otherwise
ensureExt4PartitionConfigured() {
  PARTITION="$1"
  OPTIONS="$2"
  if checkExt4PartitionConfigured "$PARTITION"; then
    ensurePartitionMountingOptions "$PARTITION" "$OPTIONS"
    return $?
  fi
  return 1
}


####################
### Main
####################


PARTITION="$1"
OPTIONS="$2"
CONFIGURE_OR_CHECK="$3"
ERRORCODE=0

if [ "$OPTIONS" = "check" ]; then
  OPTIONS=""
  CONFIGURE_OR_CHECK="check"
fi

case $PARTITION in
/tmp|/dev/shm)
  if [ "$CONFIGURE_OR_CHECK" = "check" ]; then
    echo "Check if partition $PARTITION is configured."
    checkTmpfsPartitionConfigured "$PARTITION"
  else
    echo "Ensure partition $PARTITION is configured."
    ensureTmpfsPartitionConfigured "$PARTITION" "$OPTIONS"
  fi
  ERRORCODE="$?"
  break
  ;;
/var|/var/tmp|/var/log|/var/log/audit|/home)
  if [ "$DISABLE_OR_CHECK" = "check" ]; then
    echo "Check if partition $PARTITION is configured."
    checkExt4PartitionConfigured "$PARTITION"
  else
    echo "Ensure partition $PARTITION is configured."
    ensureExt4PartitionConfigured "$PARTITION" "$OPTIONS"
  fi
  ERRORCODE="$?"
  break
  ;;
*)
  echo "Partition $PARTITION is not recognized."
  ERRORCODE=1
  ;;
esac

errorFunc() {
  return $ERRORCODE
}

errorFunc