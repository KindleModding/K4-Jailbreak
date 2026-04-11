#!/bin/sh
#
# Kindle 4 JailBreak Uninstaller
# Heavily based on stuff created by Yifan Lu <http://yifan.lu/>
#
# $Id: uninstall.sh 15002 2018-06-01 23:04:07Z NiLuJe $
#
##

# Pull libOTAUtils for logging & progress handling
[ -f ./libotautils ] && source ./libotautils


KEY_DIR="/etc/uks"
HACKNAME="k4_jb"

otautils_update_progressbar

## Here we go :)

# Uninstall the JailBreak key
logmsg "I" "uninstall" "" "remove the jailbreak key"
[ -f "${KEY_DIR}/pubdevkey01.pem" ] && rm -f "${KEY_DIR}/pubdevkey01.pem"

otautils_update_progressbar

# Don't uninstall the Kindlet keys because they could have been modified legitimately

# Done
logmsg "I" "uninstall" "" "done"

otautils_update_progressbar

return 0
