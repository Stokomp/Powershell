#!/bin/bash
# ##### SYSTEM PREFERENCE #####

# 2.1.1 Turn off Bluetooth, if no paired devices exist (Automated) - Funcionando
sudo defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0
sudo killall -HUP blued

# 2.3.1 Set an inactivity interval of 5 minutes or less for the screen saver (Automated) - 
sudo defaults -currentHost com.apple.screensaver idleTime -int 300

# 2.4.1 Disable Remote Apple Events (Automated)
sudo systemsetup -setremoteappleevents off
setremoteappleevents: Offf

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

echo "Configurações aplicadas."