#!/bin/sh

# Description: This script configures uncommon network protocols
#              It applies rules described in CIS Ubuntu Linux 20.04 LTS Benchmark document.
#
# Params  : $1 - The network protocol name. Accepts dccp, sctp, rds and tipc.
#
# Returns : 0 if successfully configure uncommon network protocol
#           1 if not successful
#
# Usage   : sh ConfigureUncommonNetworkProtocol PROTOCOL check - for checking if protocol is disabled
#           sh ConfigureUncommonNetworkProtocol PROTOCOL - for disabling protocol
#
# Example : sh ConfigureUncommonNetworkProtocol dccp check - for checking if DCCP is disabled
#           sh ConfigureUncommonNetworkProtocol dccp - for disabling DCCP
#           sh ConfigureUncommonNetworkProtocol sctp check - for checking if SCTP is disabled
#           sh ConfigureUncommonNetworkProtocol sctp - for disabling SCTP
#           sh ConfigureUncommonNetworkProtocol rds - for disabling RDS
#           sh ConfigureUncommonNetworkProtocol tipc - for disabling TIPC
#
# Maintainer : TIVIT Labs - Dev & Delivery Team <599266b4a.TIVIT.onmicrosoft.com@amer.teams.ms>


####################
### CIS Functions
####################


# Check if network protocol is disabled
# param $1: network protocol name
# return: 0 when network protocol is disabled; 1, otherwise
checkProtocolDisabled() {
  PROTOCOL="$1"
  MODPROBE_OUT=$(modprobe -n -v $PROTOCOL | grep -E "($PROTOCOL|install)" | grep "install /bin/true")
  LSMOD_OUT=$(lsmod | grep "$PROTOCOL")
  if [ ! -z "$MODPROBE_OUT" ]; then
    if [ -z "$LSMOD_OUT" ]; then
      return 0
    fi
  fi
  return 1
}


# Disable network protocol
# param $1: network protocol name
# return: 0 when network protocol is disabled; 1, otherwise
disableProtocol() {
  PROTOCOL="$1"
  FILE="/etc/modprobe.d/$PROTOCOL.conf"
  FIND_EXPR="install $PROTOCOL /bin/true"
  if ! test -f "$FILE"; then
    touch "$FILE"
  fi
  if ! grep -q "$FIND_EXPR" "$FILE"; then
    echo "$FIND_EXPR" > "$FILE"
  fi
  checkProtocolDisabled "$PROTOCOL"
  return $?
}


# Ensure network protocol is disabled
# param $1: network protocol name
# return: 0 when network protocol is disabled; 1, otherwise
ensureProtocolDisabled() {
  PROTOCOL="$1"
  if checkProtocolDisabled "$PROTOCOL"; then
    return 0
  fi
  disableProtocol "$PROTOCOL"
  return $?
}


####################
### Main
####################

PROTOCOL="$1"
DISABLE_OR_CHECK="$2"
ERRORCODE=0

case $PROTOCOL in
dccp|sctp|rds|tipc)
  if [ "$DISABLE_OR_CHECK" = "check" ]; then
    echo "Check if network protocol $PROTOCOL is disabled."
    checkProtocolDisabled "$PROTOCOL"
  else
    echo "Ensure network protocol $PROTOCOL is disabled."
    ensureProtocolDisabled "$PROTOCOL"
  fi
  ERRORCODE="$?"
  break
  ;;
*)
  echo "Network protocol $PROTOCOL is not recognized."
  ERRORCODE=1
  ;;
esac

errorFunc() {
  return $ERRORCODE
}

errorFunc