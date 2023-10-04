#!/bin/bash

dir="/Library/Application Support/SecurityScoring"

if [[ ! -e "$dir" ]]; then
    mkdir "$dir"
fi
plistlocation="$dir/org_security_score.plist"

##################################################################
############### Não edite os valores abaixo. ################
##################################################################

# 2.3.2 Secure screen saver corners #####
OrgScore2_3_2="true"
# 2.3.3 
OrgScore2_3_3="true"
# 2.4.1 Disable Remote Apple Events
OrgScore2_4_1="true"
# 2.4.2 Disable Internet Sharing 
OrgScore2_4_2="true"
# 2.4.8 Disable File Sharing  
OrgScore2_4_8="true"
# 2.5.3 Enable Firewall 
OrgScore2_5_3="true"
# 2.5.5 Review Application Firewall Rules 
OrgScore2_5_5="true"
# 2.5.8 Disable sending diagnostic and usage data to Apple 
OrgScore2_5_8="true"
# 3.1 Enable security Auditing 
OrgScore3_1="true"
# 3.3 Ensure security auditing retention 
OrgScore3_3="true"
# 3.5 Retain install.log for 365 or more days 
OrgScore3_5="true"
# 3.6 Ensure Firewall is configured to log 
OrgScore3_6="true"
# 4.5 Ensure nfs server is not running 
OrgScore4_5="true"
# 5.5 Automatically lock the login keychain for inactivity 
OrgScore5_5="true"
# 5.6 Ensure login keychain is locked when the computer sleeps 
OrgScore5_6="true"
# 5.7 Do not enable the "root" account 
OrgScore5_7="true"
# 5.11 Require an administrator password to access system-wide preferences 
OrgScore5_11="true"
# 5.12 Disable ability to login to another user's active and locked session 
OrgScore5_12="true"
# 6.1.4 Disable "Allow guests to connect to shared folders" 
OrgScore6_1_4="true"
# 6.1.5 Remove Guest home folder 
OrgScore6_1_5="true"
# 6.3 Disable the automatic run of safe files in Safari 
OrgScore6_3="true"

cat << EOF > "$plistlocation"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>		
	<key>OrgScore2_3_2</key>
	<${OrgScore2_3_2}/>
	<key>OrgScore2_3_3</key>
	<${OrgScore2_3_3}/>
	<key>OrgScore2_4_1</key>
	<${OrgScore2_4_1}/>
	<key>OrgScore2_4_2</key>
	<${OrgScore2_4_2}/>
	<key>OrgScore2_4_8</key>
	<${OrgScore2_4_8}/>
	<key>OrgScore2_5_3</key>
	<${OrgScore2_5_3}/>
	<key>OrgScore2_5_5</key>
	<${OrgScore2_5_5}/>
	<key>OrgScore2_5_8</key>
	<${OrgScore2_5_8}/>
	<key>OrgScore3_1</key>
	<${OrgScore3_1}/>
	<key>OrgScore3_3</key>
	<${OrgScore3_3}/>
	<key>OrgScore3_5</key>
	<${OrgScore3_5}/>
	<key>OrgScore3_6</key>
	<${OrgScore3_6}/>
	<key>OrgScore4_5</key>
	<${OrgScore4_5}/>
	<key>OrgScore5_5</key>
	<${OrgScore5_5}/>
	<key>OrgScore5_6</key>
	<${OrgScore5_6}/>
	<key>OrgScore5_7</key>
	<${OrgScore5_7}/>
	<key>OrgScore5_11</key>
	<${OrgScore5_11}/>
	<key>OrgScore5_12</key>
	<${OrgScore5_12}/>
	<key>OrgScore6_1_4</key>
	<${OrgScore6_1_4}/>
	<key>OrgScore6_1_5</key>
	<${OrgScore6_1_5}/>
	<key>OrgScore6_3</key>
	<${OrgScore6_3}/>
</dict>
</plist>
EOF

plistlocation="/Library/Application Support/SecurityScoring/org_security_score.plist"
currentUser="$(python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')"
currentUserID="$(/usr/bin/id -u $currentUser)"
hardwareUUID="$(/usr/sbin/system_profiler SPHardwareDataType | grep "Hardware UUID" | awk -F ": " '{print $2}' | xargs)"

logFile="/Library/Application Support/SecurityScoring/remediation.log"
# Append to existing logFile
echo "$(date -u)" "Beginning remediation" >> "$logFile"
# Create new logFile
# echo "$(date -u)" "Beginning remediation" > "$logFile"	

if [[ ! -e $plistlocation ]]; then
	echo "No scoring file present"
	exit 0
fi

# 2.3.2 Secure screen saver corners 
# Configuration Profile - Custom payload > com.apple.dock > wvous-tl-corner=0, wvous-br-corner=5, wvous-bl-corner=0, wvous-tr-corner=0
# Verify organizational score
Audit2_3_2="$($Defaults read "$plistlocation" OrgScore2_3_2)"
# If organizational score is 1 or true, check status of client
if [[ "$Audit2_3_2" = "1" ]]; then
	CP_corner="$(/usr/sbin/system_profiler SPConfigurationProfileDataType | /usr/bin/grep -E '(\"wvous-bl-corner\" =|\"wvous-tl-corner\" =|\"wvous-tr-corner\" =|\"wvous-br-corner\" =)')"
	# If client fails, then note category in audit file
	if [[ "$CP_corner" != *"6"* ]] && [[ "$CP_corner" != "" ]]; then
		echo "$(date -u)" "2.3.2 passed cp" | tee -a "$logFile"
		$Defaults write "$plistlocation" OrgScore2_3_2 -bool false; else
		bl_corner="$($Defaults read /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-bl-corner)"
		tl_corner="$($Defaults read /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-tl-corner)"
		tr_corner="$($Defaults read /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-tr-corner)"
		br_corner="$($Defaults read /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-br-corner)"
		if [[ "$bl_corner" != "6" ]] && [[ "$tl_corner" != "6" ]] && [[ "$tr_corner" != "6" ]] && [[ "$br_corner" != "6" ]]; then
			echo "$(date -u)" "2.3.2 passed" | tee -a "$logFile"
			$Defaults write "$plistlocation" OrgScore2_3_2 -bool false; else
			echo "* 2.3.2 Secure screen saver corners" >> "$auditfilelocation"
			echo "$(date -u)" "2.3.2 fix" | tee -a "$logFile"
		fi
	fi
fi

# 2.3.2 Secure screen saver corners 
Audit2_3_2="$(defaults read "$plistlocation" OrgScore2_3_2)"
if [[ "$Audit2_3_2" = "1" ]]; then
	killDock=false
	bl_corner="$(defaults read /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-bl-corner)"
	tl_corner="$(defaults read /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-tl-corner)"
	tr_corner="$(defaults read /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-tr-corner)"
	br_corner="$(defaults read /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-br-corner)"
	if [[ "$bl_corner" = "6" ]]; then
		echo "Disabling bottom left hot corner"
		/usr/bin/defaults write /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-bl-corner -int 1
		/usr/bin/defaults write /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-bl-modifier -int 0
		killDock=true
	fi
	if [[ "$tl_corner" = "6" ]]; then
		echo "Disabling top left hot corner"
		/usr/bin/defaults write /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-tl-corner -int 1
		/usr/bin/defaults write /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-tl-modifier -int 0
		killDock=true
	fi
	if [[ "$tr_corner" = "6" ]]; then
		echo "Disabling top right hot corner"
		/usr/bin/defaults write /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-tr-corner -int 1
		/usr/bin/defaults write /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-tr-modifier -int 0
		killDock=true
	fi
	if [[ "$br_corner" = "6" ]]; then
		echo "Disabling bottom right hot corner"
		/usr/bin/defaults write /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-br-corner -int 1
		/usr/bin/defaults write /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-br-modifier -int 0
		killDock=true
	fi
	## ensure proper ownership of plist
	/usr/sbin/chown "$currentUser" /Users/"$currentUser"/Library/Preferences/com.apple.dock.plist

	if $killDock;then
		/usr/bin/killall Dock
		echo "$(date -u)" "2.3.2 remediated" | tee -a "$logFile"
	fi
fi

# Remediation
# 2.3.3 Familiarize users with screen lock tools or corner to Start Screen Saver  
# Verify organizational score
Audit2_3_3="$(defaults read "$plistlocation" OrgScore2_3_3)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
# Sets bottom left corner to start screen saver
if [ "$Audit2_3_3" = "1" ]; then
	bl_corner="$(defaults read /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-bl-corner)"
	if [ "$bl_corner" != "5" ]; then
		echo "Setting bottom left to start screen saver" | tee -a "$logFile"
		/usr/bin/defaults write /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-bl-corner -int 5
		/usr/bin/defaults write /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-bl-modifier -int 0
		## ensure proper ownership of plist
		/usr/sbin/chown "$currentUser" /Users/"$currentUser"/Library/Preferences/com.apple.dock.plist
		/usr/bin/killall Dock
		echo "$(date -u)" "2.3.3 remediated" | tee -a "$logFile"
	fi
fi

# 2.4.1 Disable Remote Apple Events 
Audit2_4_1="$(defaults read "$plistlocation" OrgScore2_4_1)"

if [[ "$Audit2_4_1" = "1" ]]; then
		/usr/sbin/systemsetup -setremoteappleevents off
		echo "$(date -u)" "2.4.1 remediated" | tee -a "$logFile"
fi

# 2.4.2 Disable Internet Sharing 
Audit2_4_2="$(defaults read "$plistlocation" OrgScore2_4_2)"
if [[ "$Audit2_4_2" = "1" ]]; then
	/usr/libexec/PlistBuddy -c "Delete :NAT:AirPort:Enabled"  /Library/Preferences/SystemConfiguration/com.apple.nat.plist
	/usr/libexec/PlistBuddy -c "Add :NAT:AirPort:Enabled bool false" /Library/Preferences/SystemConfiguration/com.apple.nat.plist
	/usr/libexec/PlistBuddy -c "Delete :NAT:Enabled"  /Library/Preferences/SystemConfiguration/com.apple.nat.plist
	/usr/libexec/PlistBuddy -c "Add :NAT:Enabled bool false" /Library/Preferences/SystemConfiguration/com.apple.nat.plist
	/usr/libexec/PlistBuddy -c "Delete :NAT:PrimaryInterface:Enabled"  /Library/Preferences/SystemConfiguration/com.apple.nat.plist
	/usr/libexec/PlistBuddy -c "Add :NAT:PrimaryInterface:Enabled bool false" /Library/Preferences/SystemConfiguration/com.apple.nat.plist
	
	## breaks internet connection sharing
	cat > /Library/LaunchDaemons/sysctl.plist << EOF
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
	<dict>
		<key>Label</key>
		<string>sysctl</string>
		<key>ProgramArguments</key>
		<array>
			<string>/usr/sbin/sysctl</string>
			<string>net.inet.ip.forwarding=0</string>
		</array>
		<key>WatchPaths</key>
		<array>
			<string>/Library/Preferences/SystemConfiguration</string>
		</array>
		<key>RunAtLoad</key>
		<true/>
	</dict>
</plist>
EOF
	if [[ $(/bin/launchctl list | grep sysctl | awk '{ print $NF }') = "sysctl" ]];then
		/bin/launchctl unload /Library/LaunchDaemons/sysctl.plist
	fi
	/bin/launchctl load /Library/LaunchDaemons/sysctl.plist
    
	echo "$(date -u)" "2.4.2 enforced" | tee -a "$logFile"
fi


# 2.4.8 Disable File Sharing
Audit2_4_8="$(defaults read "$plistlocation" OrgScore2_4_8)"
if [[ "$Audit2_4_8" = "1" ]]; then
	/bin/launchctl unload -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist
	/bin/launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist
	echo "$(date -u)" "2.4.8 remediated" | tee -a "$logFile"
fi

# 2.5.3 Enable Firewall 
Audit2_5_3="$(defaults read "$plistlocation" OrgScore2_5_3)"
if [[ "$Audit2_5_3" = "1" ]]; then
	defaults write /Library/Preferences/com.apple.alf globalstate -int 2
	echo "$(date -u)" "2.5.3 remediated" | tee -a "$logFile"
fi

# 2.5.5 Review Application Firewall Rules
Audit2_5_5="$(defaults read "$plistlocation" OrgScore2_5_5)"
if [[ "$Audit2_5_5" = "1" ]]; then
	echo "$(date -u)" "2.5.5 not remediated" | tee -a "$logFile"
fi

# 2.5.8 Disable sending diagnostic and usage data to Apple
Audit2_5_8="$(defaults read "$plistlocation" OrgScore2_5_8)"
if [[ "$Audit2_5_8" = "1" ]]; then
	AppleDiagn=$(defaults read /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmit)
	if [[ $AppleDiagn == 1 ]]; then 
		defaults write /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmit -int 0
		echo "$(date -u)" "2.5.8 remediated" | tee -a "$logFile"
	fi
fi

# 3.1 Enable security auditing
Audit3_1="$(defaults read "$plistlocation" OrgScore3_1)"
if [[ "$Audit3_1" = "1" ]]; then
	/bin/launchctl load -w /System/Library/LaunchDaemons/com.apple.auditd.plist
	echo "$(date -u)" "3.1 remediated" | tee -a "$logFile"
fi

# 3.3 Ensure security auditing retention
Audit3_3="$(defaults read "$plistlocation" OrgScore3_3)"
if [[ "$Audit3_3" = "1" ]]; then
	cp /etc/security/audit_control /etc/security/audit_control_old
	oldExpireAfter=$(cat /etc/security/audit_control | egrep expire-after)
	sed "s/${oldExpireAfter}/expire-after:60d OR 1G/g" /etc/security/audit_control_old > /etc/security/audit_control
	chmod 644 /etc/security/audit_control
	chown root:wheel /etc/security/audit_control
	echo "$(date -u)" "3.3 remediated" | tee -a "$logfile"	
fi

# 3.5 Retain install.log for 365 or more days 
Audit3_5="$(defaults read "$plistlocation" OrgScore3_5)"
if [[ "$Audit3_5" = "1" ]]; then
	installRetention="$(grep -i ttl /etc/asl/com.apple.install | awk -F'ttl=' '{print $2}')"
	if [[ "$installRetention" = "" ]]; then
		mv /etc/asl/com.apple.install /etc/asl/com.apple.install.old
		sed '$s/$/ ttl=365/' /etc/asl/com.apple.install.old > /etc/asl/com.apple.install
		chmod 644 /etc/asl/com.apple.install
		chown root:wheel /etc/asl/com.apple.install
		echo "$(date -u)" "3.5 remediated" | tee -a "$logfile"	
	else
	if [[ "$installRetention" -lt "365" ]]; then
		mv /etc/asl/com.apple.install /etc/asl/com.apple.install.old
		sed "s/"ttl=$installRetention"/"ttl=365"/g" /etc/asl/com.apple.install.old > /etc/asl/com.apple.install
		chmod 644 /etc/asl/com.apple.install
		chown root:wheel /etc/asl/com.apple.install
		echo "$(date -u)" "3.5 remediated" | tee -a "$logfile"	
	fi
	fi
fi

# 3.6 Ensure firewall is configured to log
Audit3_6="$(defaults read "$plistlocation" OrgScore3_6)"
if [[ "$Audit3_6" = "1" ]]; then
	/usr/libexec/ApplicationFirewall/socketfilterfw --setloggingmode on
	echo "$(date -u)" "3.6 remediated" | tee -a "$logFile"
fi

# 4.5 Ensure nfs server is not running
Audit4_5="$(defaults read "$plistlocation" OrgScore4_5)"
if [[ "$Audit4_5" = "1" ]]; then
	nfsd disable
	rm -rf /etc/exports
	echo "$(date -u)" "4.5 remediated" | tee -a "$logFile"
fi

# 5.5 Automatically lock the login keychain for inactivity
# 5.6 Ensure login keychain is locked when the computer sleeps
Audit5_5="$(defaults read "$plistlocation" OrgScore5_5)"
Audit5_6="$(defaults read "$plistlocation" OrgScore5_6)"
if [[ "$Audit5_5" = "1" ]] && [[ "$Audit5_6" = 1 ]]; then
echo "$(date -u)" "Checking 5.5 and 5.6" | tee -a "$logFile"
	security set-keychain-settings -l -u -t 21600s /Users/"$currentUser"/Library/Keychains/login.keychain
	echo "$(date -u)" "5.5 and 5.6 remediated" | tee -a "$logFile"
	elif [[ "$Audit5_5" = "1" ]] && [[ "$Audit5_6" = 0 ]]; then
		echo "$(date -u)" "Checking 5.5" | tee -a "$logFile"
		security set-keychain-settings -u -t 21600s /Users/"$currentUser"/Library/Keychains/login.keychain
		echo "$(date -u)" "5.5 remediated" | tee -a "$logFile"
		elif [[ "$Audit5_5" = "0" ]] && [[ "$Audit5_6" = 1 ]]; then
			echo "$(date -u)" "Checking 5.6" | tee -a "$logFile"
			security set-keychain-settings -l /Users/"$currentUser"/Library/Keychains/login.keychain
			echo "$(date -u)" "5.6 remediated" | tee -a "$logFile"
fi

# 5.7 Do not enable the "root" account
Audit5_7="$(defaults read "$plistlocation" OrgScore5_7)"
if [[ "$Audit5_7" = "1" ]]; then
	dscl . -create /Users/root UserShell /usr/bin/false
	echo "$(date -u)" "5.7 remediated" | tee -a "$logFile"
fi

# 5.11 Require an administrator password to access system-wide preferences
Audit5_11="$(defaults read "$plistlocation" OrgScore5_11)"
if [[ "$Audit5_11" = "1" ]]; then
	security authorizationdb read system.preferences > /tmp/system.preferences.plist
	/usr/libexec/PlistBuddy -c "Set :shared false" /tmp/system.preferences.plist
	security authorizationdb write system.preferences < /tmp/system.preferences.plist
	echo "$(date -u)" "5.11 remediated" | tee -a "$logFile"
fi

# 5.12 Disable ability to login to another user's active and locked session
Audit5_12="$(defaults read "$plistlocation" OrgScore5_12)"
if [[ "$Audit5_12" = "1" ]]; then
	/usr/bin/security authorizationdb write system.login.screensaver "use-login-window-ui"
	echo "$(date -u)" "5.12 remediated" | tee -a "$logFile"
fi

# 6.1.4 Disable "Allow guests to connect to shared folders"
Audit6_1_4="$(defaults read "$plistlocation" OrgScore6_1_4)"

if [[ "$Audit6_1_4" = "1" ]]; then
echo "$(date -u)" "Checking 6.1.4" | tee -a "$logFile"
	afpGuestEnabled="$(defaults read /Library/Preferences/com.apple.AppleFileServer guestAccess)"
	smbGuestEnabled="$(defaults read /Library/Preferences/SystemConfiguration/com.apple.smb.server AllowGuestAccess)"
	if [[ "$afpGuestEnabled" = "1" ]]; then
		defaults write /Library/Preferences/com.apple.AppleFileServer guestAccess -bool false
		echo "$(date -u)" "6.1.4 remediated" | tee -a "$logFile";
	fi
	if [[ "$smbGuestEnabled" = "1" ]]; then
		defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server AllowGuestAccess -bool false
		echo "$(date -u)" "6.1.4 remediated" | tee -a "$logFile";
	fi
fi

# 6.1.5 Remove Guest home folder
Audit6_1_5="$(defaults read "$plistlocation" OrgScore6_1_5)"
if [[ "$Audit6_1_5" = "1" ]]; then
	rm -rf /Users/Guest
	echo "$(date -u)" "6.1.5 remediated" | tee -a "$logFile"
fi

# 6.3 Disable the automatic run of safe files in Safari
Audit6_3="$(defaults read "$plistlocation" OrgScore6_3)"
if [[ "$Audit6_3" = "1" ]]; then
	/usr/libexec/PlistBuddy -c "Set :AutoOpenSafeDownloads bool false" /Users/"$currentUser"/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari.plist
	echo "$(date -u)" "6.3 remediated" | tee -a "$logFile"
fi


# Change the logs size and retention
sed -i '' -E 's/expire-after\:.*/expire-after:360d OR 1G/g' /etc/security/audit_control
# flags:lo,aa,ad,fd,-all
sed -i '' -E 's/flags:lo,aa/flags:lo,ad,fd,fm,-all/g' /etc/security/audit_control

echo "$(date -u)" "Remediation complete" | tee -a "$logFile"
echo "Finalizado"
exit 0