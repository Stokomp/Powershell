#!/bin/sh

# Description: This script configures services.
#              It applies rules described in CIS Ubuntu Linux 20.04 LTS Benchmark document.
#
# Params  : $1 - The service name. Accepts xwinsys, avahi, nfs, mail-transfer and others.
#
# Returns : 0 if successfully ensure service is configured
#           1 if not successful
#
# Usage   : sh ConfigureService.sh SERVICE - for configuring service
#
# Example : sh ConfigureService.sh xwinsys - for configuring X Windows System services
#           sh ConfigureService.sh avahi - for configuring Avahi Server service
#           sh ConfigureService.sh nfs - for configuring NFS service
#           sh ConfigureService.sh mail-transfer - for configuring mail transfer agent service for local-only mode
#           sh ConfigureService.sh non-essential - for ensuring non-essential services are removed or masked
#           sh ConfigureService.sh xinetd - for configuring xinetd service
#           sh ConfigureService.sh openbsd-inetd - for configuring -openbsd-inetd service
#           sh ConfigureService.sh cups - for configuring CUPS service
#           sh ConfigureService.sh isc-dhcp-server - for configuring DHCP Server service
#           sh ConfigureService.sh slapd - for configuring LDAP Server service
#           sh ConfigureService.sh ldap-utils - for configuring LDAP Client service
#           sh ConfigureService.sh bind9 - for configuring DNS server service
#           sh ConfigureService.sh vsftpd - for configuring FTP server service
#           sh ConfigureService.sh apache2 - for configuring HTTP Server service
#           sh ConfigureService.sh nginx - for configuring HTTP Server service
#           sh ConfigureService.sh dovecot-imapd - for configuring IMAP service
#           sh ConfigureService.sh dovecot-pop3d - for configuring POP3 service
#           sh ConfigureService.sh samba - for configuring Samba service
#           sh ConfigureService.sh squid - for configuring HTTP Proxy Server service
#           sh ConfigureService.sh snmpd - for configuring SNMP Server service
#           sh ConfigureService.sh rsync - for configuring rsync service
#           sh ConfigureService.sh nis - for configuring NIS Server service
#           sh ConfigureService.sh nis - for configuring NIS Client service
#           sh ConfigureService.sh rsh-client - for configuring rsh Client service
#           sh ConfigureService.sh talk - for configuring talk Client service
#           sh ConfigureService.sh telnet - for configuring telnet Client service
#           sh ConfigureService.sh rpcbind - for configuring RPC service
#
# Maintainer : TIVIT Labs - Dev & Delivery Team <599266b4a.TIVIT.onmicrosoft.com@amer.teams.ms>


####################
### CIS Functions
####################


# Ensure package is not installed
# return: 0 when package is not installed; 1, otherwise
ensurePackageNotInstalled() {
  PACKAGE="$1"
  dpkg -l | grep -qw $PACKAGE
  if [ $? -eq 0 ]; then
    apt purge -y $PACKAGE >/dev/null
    return $?
  fi
  return 0
}


# Ensure X Window System is not installed
# return: 0 when X Window System is not installed; 1, otherwise
ensureXWinSysNotInstalled() {
  dpkg -l xserver-xorg* | grep -qw "xserver-xorg"
  if [ $? -eq 0 ]; then
    apt-get purge -y xserver-xorg* >/dev/null
    return $?
  fi
  return 0
}


# Ensure Avahi Server is not installed
# return: 0 when X Avahi Server is not installed; 1, otherwise
ensureAvahiServerNotInstalled() {
  dpkg -s avahi-daemon >/dev/null 2>/dev/null
  if [ ! -z $? ]; then
    systemctl stop avahi-daemon.service
    systemctl stop avahi-daemon.socket
    apt purge -y avahi-daemon
    return $?
  fi
  return $?
}


# Ensure NFS is not installed
# return: 0 when NFS is not installed; 1, otherwise
ensureNfsNotInstalled() {
  dpkg -l | grep -qw nfs-kernel-server
  if [ $? -eq 0 ]; then
    apt purge -y rpcbind >/dev/null
    return $?
  fi
  return 0
}


# Ensure mail transfer agent is configured for local-only mode
# return: 0 when mail transfer agent is configured for local-only mode; 1, otherwise
ensureMailTransferAgentConfigured() {
  return 1
}


# Ensure nonessential services are removed or masked
# return: 0 when nonessential services are removed or masked; 1, otherwise
ensureNonEssentialNotInstalledOrMasked() {
    return 1
}


####################
### Main
####################

SERVICE="$1"
ERRORCODE=0

case $SERVICE in
xwinsys)
  echo "Ensure X Window System is not installed."
  ensureXWinSysNotInstalled
  ERRORCODE="$?"
  break
  ;;
avahi)
  echo "Ensure Avahi Server is not installed."
  ensureAvahiServerNotInstalled
  ERRORCODE="$?"
  break
  ;;
nfs)
  echo "Ensure NFS is not installed."
  ensureNfsNotInstalled
  ERRORCODE="$?"
  break
  ;;
mail-transfer)
  echo "Ensure mail transfer agent is configured for local-only mode."
  ensureMailTransferAgentConfigured
  ERRORCODE="$?"
  break
  ;;
non-essential)
  echo "Ensure nonessential services are removed or masked."
  ensureNonEssentialNotInstalledOrMasked
  ERRORCODE="$?"
  break
  ;;
*)
  echo "Ensure $SERVICE is not installed."
  ensurePackageNotInstalled "$SERVICE"
  ERRORCODE="$?"
  break
  ;;
esac

errorFunc() {
  return $ERRORCODE
}

errorFunc