#!/bin/bash

Defaults="/usr/bin/defaults"

####################################################################################################

plistlocation="/Library/Application Support/SecurityScoring/org_security_score.plist"
auditfilelocation="/Library/Application Support/SecurityScoring/org_audit"
currentUser="$(python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')"
hardwareUUID="$(/usr/sbin/system_profiler SPHardwareDataType | grep "Hardware UUID" | awk -F ": " '{print $2}' | xargs)"

mkdir /Library/Application Support/SecurityScorin
touch /Library/Application Support/SecurityScorin/remediation.log

logFile="/Library/Application Support/SecurityScoring/remediation.log"

# ##### INSTALL UPDATES #####

# 1.1 Verify all Apple-provided software is current (Automated) 
 sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool true 

# 1.2 Enable Auto Update (Automated)
 sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true 

# 1.3 Enable Download new updates when available (Automated)
 sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool true 

# 1.4 Enable app update installs (Automated)
 sudo defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool TRUE 

# 1.5 Enable system data files and security updates install (Automated)
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool true && defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true

# 1.6 Enable macOS update installs (Automated)
 sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false 

# ##### SYSTEM PREFERENCE #####

# 2.1.1 Turn off Bluetooth, if no paired devices exist (Automated)
Sudo defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0 && killall -HUP blued 

# 2.3.1 Set an inactivity interval of 20 minutes or less for the screen saver (Automated)
sudo defaults -currentHost write com.apple.screensaver idleTime -int 1200 

# 2.4.1 Disable Remote Apple Events (Automated)
sudo systemsetup -setremoteappleevents off && setremoteappleevents: Offf

# 2.4.2 Disable Internet Sharing (Automated)
 sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict Enabled -int 0 

# 2.4.3 Disable Screen Sharing (Automated)
 sudo launchctl disable system/com.apple.screensharing 

# 2.4.4 Disable Printer Sharing (Automated)
 sudo cupsctl --no-share-printers 

# 2.4.5 Disable Remote Login (Automated)
 sudo systemsetup -setremotelogin off 

# 2.4.6 Disable DVD or CD Sharing (Automated)
sudo launchctl disable system/com.apple.ODSAgent 

# 2.4.8 Disable File Sharing (Automated)
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist 

# 2.4.10 Disable Content Caching (Automated)
 sudo AssetCacheManagerUtil deactivate 


# #### Time Machine ####

# 2.9 Disable Power Nap (Automated)
 sudo pmset -a powernap 0 

# #### Logging and Auditing ####

# 3.5 Control access to audit records (Automated)
 sudo chown -R root:wheel /etc/security/audit_contr && chown -R root:wheel /var/audit/ && chmod -R -o-rw /var/audit/ 

# #### Network Configurations ####

# 4.4 Ensure http server is not running (Automated)
 sudo launchctl disable system/org.apache.httpd 


# 5.16 Disable Fast User Switching (Manual)
 sudo defaults write /Library/Preferences/.GlobalPreferences MultipleSessionEnabled -bool false 




# #### Outros

# 2.5.3 Enable Firewall 
sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1 

# 6.1.5 Remove Guest home folder
sudo /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool NO && /usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server AllowGuestAccess -bool NO && /usr/bin/defaults write /Library/Preferences/com.apple.AppleFileServer guestAccess -bool NO 


# 2.5.8 Disable Analytics & Improvements sharing with Apple
 sudo defaults write /Library/Application/ Support/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmit -int 0 

# 3.3 Ensure security auditing retention
launchctl load -w /System/Library/LaunchDaemons/com.apple.auditd.plist 

# 6.1.4 Disable "Allow guests to connect to shared folders"
 sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server AllowGuestAccess -int 0 

# 4.5 Ensure nfs server is not running
 sudo nfsd disable 

# Disable the automatic run of safe files in Safari
 sudo defaults write com.apple.Safari AutoOpenSafeDownloads -boolean NO





# 5.11 Require an administrator password to access system-wide
#security authorizationdb read system.preferences > /tmp/system.preferences.plist
#/usr/libexec/PlistBuddy -c "Set :shared false" /tmp/system.preferences.plist
#security authorizationdb write system.preferences < /tmp/system.preferences.plist









