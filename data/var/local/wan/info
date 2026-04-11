#!/bin/sh
#
# Kindle 4 JailBreak Install
# Heavily based on stuff created by Yifan Lu <http://yifan.lu/>
#
# $Id: install.sh 18977 2022-10-02 00:37:38Z NiLuJe $
#
##

JAILBREAK_PAYLOAD="/var/local/payload"
JAILBREAK_KEY="${JAILBREAK_PAYLOAD}/jailbreak.pem"
JAILBREAK_IMAGE="${JAILBREAK_PAYLOAD}/jailbreak.png"
JAILBREAK_DEV_KEYSTORE="${JAILBREAK_PAYLOAD}/jailbreak.keystore"
SCRIPT="/mnt/us/runme.sh"
ROOT=""
HACKNAME="jailbreak"


### NOTE: Inlined copy of libotautils r10677...
## Logging
# Pull some helper functions for logging
_FUNCTIONS=/etc/rc.d/functions
[ -f ${_FUNCTIONS} ] && source ${_FUNCTIONS}

# Make sure HACKNAME is set (NOTE: This should be overriden in the update script)
[ -z "${HACKNAME}" ] && HACKNAME="ota_script"

# Slightly tweaked version of msg() (from ${_FUNCTIONS}, where the constants are defined)
logmsg()
{
	local _NVPAIRS
	local _FREETEXT
	local _MSG_SLLVL
	local _MSG_SLNUM

	_MSG_LEVEL="${1}"
	_MSG_COMP="${2}"

	{ [ $# -ge 4 ] && _NVPAIRS="${3}" && shift ; }

	_FREETEXT="${3}"

	eval _MSG_SLLVL=\${MSG_SLLVL_$_MSG_LEVEL}
	eval _MSG_SLNUM=\${MSG_SLNUM_$_MSG_LEVEL}

	local _CURLVL

	{ [ -f ${MSG_CUR_LVL} ] && _CURLVL=$(cat ${MSG_CUR_LVL}) ; } || _CURLVL=1

	if [ ${_MSG_SLNUM} -ge ${_CURLVL} ] ; then
		/usr/bin/logger -p local4.${_MSG_SLLVL} -t "${HACKNAME}" "${_MSG_LEVEL} def:${_MSG_COMP}:${_NVPAIRS}:${_FREETEXT}"
	fi

	[ "${_MSG_LEVEL}" != "D" ] && echo "${HACKNAME}: ${_MSG_LEVEL} def:${_MSG_COMP}:${_NVPAIRS}:${_FREETEXT}"
}
###


RW=
mount_rw() {
	if [ -z "$RW" ] ; then
		RW=yes
		mount -o rw,remount /
	fi
}

mount_ro() {
	if [ -n "$RW" ] ; then
		RW=
		mount -o ro,remount /
	fi
}

mount_root_rw()
{
	DEV="$(rdev | awk '{ print $1 }')"
	if [ "${DEV}" != "/dev/mmcblk0p1" -a -n "${DEV}" ] ; then	# K4 doesn't have rdev on rootfs but does on diags, weird
		ROOT="/var/tmp/rootfs"
		logmsg "I" "mount_root_rw" "" "We are not on rootfs, using ${ROOT}"
		[ -d "${ROOT}" ] || mkdir -p "${ROOT}"
		mount -o rw "/dev/mmcblk0p1" "${ROOT}"
	else
		logmsg "I" "mount_root_rw" "" "We are on rootfs"
		mount_rw
	fi
}

get_version()
{
	awk '/Version:/ { print $NF }' /etc/version.txt | \
		awk -F- '{ print $NF }' | \
		xargs printf "%s\n" | \
		sed -e 's#^0*##'
}

safesource()
{
	[ -f "${1}" ] && . "${1}"
}

install_touch_update_key()
{
	# Only on Kindle 4 & 5
	logmsg "I" "install_touch_update_key" "" "Copying the jailbreak updater key"
	cp -af "${JAILBREAK_KEY}" "${ROOT}/etc/uks/pubdevkey01.pem"
	return 0
}

install_kindlet_key()
{
	logmsg "I" "install_kindlet_key" "" "Copying the developer keystore"
	cp -af "${JAILBREAK_DEV_KEYSTORE}" "/var/local/java/keystore/developer.keystore"
	return 0
}

clean_up_wan()
{
	[ -n "${WAN_INFO}" ] || WAN_INFO="/var/local/wan/info"

	logmsg "I" "clean_up_wan" "" "Cleaning up waninfo file and generating new one"
	rm -f ${WAN_INFO}
	if [ -f "${WAN_INFO}" ] ; then
		logmsg "E" "clean_up_wan" "" "Cannot remove payload. Exiting to prevent boot-loop."
		return 1
	fi

	waninfo
	safesource ${WAN_INFO}
}

clean_up_mntus_params()
{
	[ -n "${MNTUS_PARAMS}" ] || MNTUS_PARAMS="/var/local/system/mntus.params"

	logmsg "I" "clean_up_mntus_params" "" "Cleaning up mntus.params file and generating new one"
	rm -f "${MNTUS_PARAMS}"
	if [ -f "${MNTUS_PARAMS}" ] ; then
		logmsg "E" "clean_up_mntus_params" "" "Cannot remove payload. Exiting to prevent boot-loop."
		return 1
	fi

	if [ -x ${ROOT}/etc/init.d/userstore ] ; then
		# Kindle 4 or below, sysinit
		${ROOT}/etc/init.d/userstore start
	fi
	safesource ${MNTUS_PARAMS}
}

clean_up()
{
	logmsg "I" "clean_up" "" "Removing payload files."
	rm -rf "${JAILBREAK_PAYLOAD}"
	clean_up_wan
	clean_up_mntus_params
	if [ -n "${ROOT}" ] ; then
		logmsg "I" "clean_up" "" "Unmounting rootfs"
		umount "${ROOT}"
	fi
}

# Step 0, log who triggered us
logmsg "I" "jailbreak" "" "Running from: ${0}"

# Step 1, we put a pretty image on screen
eips -c
eips -f -g "${JAILBREAK_IMAGE}"

# Step 2, check device version
VERSION=0
kpver="$(grep '^Kindle [12345]' /etc/prettyversion.txt 2>&1)"
if [ $? -ne 0 ] ; then
	logmsg "W" "jailbreak" "" "Couldn't detect the Kindle version!"
	VERSION=0
else
	# Weeee, the great case switch!
	khver="$(echo ${kpver} | sed -n -r 's/^(Kindle)([[:blank:]]*)([[:digit:].]*)(.*?)$/\3/p')"
	case "${khver}" in
		1* )
			VERSION=1
		;;
		2* )
			VERSION=2
		;;
		3* )
			VERSION=3
		;;
		4* )
			VERSION=4
		;;
		5* )
			VERSION=5
		;;
		* )
			VERSION=0
		;;
	esac
fi
logmsg "I" "jailbreak" "" "Kindle version: ${VERSION}"
# Some diags version don't have a properly formatted prettyversion, fallback to model based detection...
kmfc="$(cut -c1 /proc/usid)"	# NOTE: If this isn't enough, we could also use $(idme --serial ?), but I'd vastly prefer to keep using a ro 'inert' file...
if [ $? -ne 0 ] ; then
	logmsg "W" "jailbreak" "" "Couldn't detect the Kindle model!"
	VERSION=0
else
	if [ "${VERSION}" -le "0" ] ; then
		if [ "${kmfc}" == "B" ] || [ "${kmfc}" == "9" ] ; then
			# Older device ID scheme
			kmodel="$(cut -c3-4 /proc/usid)"
			logmsg "I" "jailbreak" "" "Kindle model (old device ID scheme): ${kmodel}"
			case "${kmodel}" in
				"01" )
					VERSION=1
				;;
				"02" | "03" | "04" | "05" | "09" )
					VERSION=2
				;;
				"08" | "06" | "0A" )
					VERSION=3
				;;
				"0E" | "23" )
					VERSION=4
				;;
				"0F" | "11" | "10" | "12" | "24" | "1B" | "1D" | "1F" | "1C" | "20" | "D4" | "5A" | "D5" | "D6" | "D7" | "D8" | "F2" | "17" | "60" | "F4" | "F9" | "62" | "61" | "5F" | "C6" | "DD" | "13" | "54" | "2A" | "4F" | "52" | "53" )
					VERSION=5
				;;
				* )
					VERSION=0
				;;
			esac
			logmsg "I" "jailbreak" "" "Kindle version (from older model): ${VERSION}"
		else
			# Try the new device ID scheme...
			kmodel="$(cut -c4-6 /proc/usid)"
			logmsg "I" "jailbreak" "" "Kindle model (new device ID scheme): ${kmodel}"
			case "${kmodel}" in
				"0G1" | "0G2" | "0G4" | "0G5" | "0G6" | "0G7" | "0KB" | "0KC" | "0KD" | "0KE" | "0KF" | "0KG" | "0LK" | "0LL" | "0GC" | "0GD" | "0GR" | "0GS" | "0GT" | "0GU" | "0DU" | "0K9" | "0KA" | "0LM" | "0LN" | "0LP" | "0LQ" | "0P1" | "0P2" | "0P6" | "0P7" | "0P8" | "0S1" | "0S2" | "0S3" | "0S4" | "0S7" | "0SA" | "0PP" | "0T1" | "0T2" | "0T3" | "0T4" | "0T5" | "0T6" | "0T7" | "0TJ" | "0TK" | "0TL" | "0TM" | "0TN" | "102" | "103" | "16Q" | "16R" | "16S" | "16T" | "16U" | "16V" | "10L" | "0WF" | "0WG" | "0WH" | "0WJ" | "0VB" | "11L" | "0WQ" | "0WP" | "0WN" | "0WM" | "0WL" | "1LG" | "1Q0" | "1PX" | "1VD" | "219" | "21A" | "2BH" | "2BJ" | "2DK" | "22D" | "25T" | "23A" | "2AQ" | "2AP" | "1XH" | "22C" )
					VERSION=5
				;;
				* )
					VERSION=0
				;;
			esac
			logmsg "I" "jailbreak" "" "Kindle version (from model): ${VERSION}"
		fi
	fi
fi
# And the last-chance fallback, revision based detection...
REVISION="$(get_version)"
logmsg "I" "jailbreak" "" "Kindle revision: ${REVISION}"
# FIXME: As time passes, this becomes more and more inaccurate, which is why it's only used as a last resort fallback...
if [ "${VERSION}" -le "0" ] ; then
	if [ "${REVISION}" -lt "29133" ] ; then
		VERSION=1
	elif [ "${REVISION}" -lt "51546" ] ; then
		VERSION=2
	elif [ "${REVISION}" -lt "130856" ] ; then	# FIXME: Kindle 3.4 is > main 5.1.0...
		VERSION=3
	elif [ "${REVISION}" -lt "137022" ] ; then	# FIXME: Kindle main 4.1.0 is > main 5.1.0...
		VERSION=4
	else
		VERSION=5
	fi
	logmsg "I" "jailbreak" "" "Kindle version (from revision, inaccurate): ${VERSION}"
fi
# Recap what we've detected...
logmsg "I" "jailbreak" "" "Assume Kindle version: ${VERSION}"

# Step 2.5, go away if we're not (at least) on a Kindle 4 (We shouldn't ever hit this, but let's be on the safe side)
if [ "${VERSION}" -lt "4" ] ; then
	logmsg "E" "jailbreak" "" "We're not at least on a Kindle 4, go away!"
	# Cleanup before exiting!
	sleep 5
	clean_up
	exit 0
fi

# Step 3, install updater key
mount_root_rw
if [ "${VERSION}" -ge "4" ] ; then
	install_touch_update_key
fi
mount_ro

# Step 3, install kindlet key
install_kindlet_key

# Step 4, wait a bit while our cool splash screen is up and then clean up
# Print a nifty spinner to pass the time... We'll need a few constants...
SCREEN_X_RES=600
SCREEN_Y_RES=800
EIPS_X_RES=12
EIPS_Y_RES=20
EIPS_MAXCHARS="$((${SCREEN_X_RES} / ${EIPS_X_RES}))"
EIPS_MAXLINES="$((${SCREEN_Y_RES} / ${EIPS_Y_RES}))"
# eips can't print a backslash... -_-" Use an X in place of \
SPINNER='|/-X'
i=0

# Loop for 10s
while [ $i -lt 10 ] ; do
	SPINNER="${SPINNER#?}${SPINNER%???}"
	CUR_SPIN="** $(printf '%.1s' "${SPINNER}") **"
	# Center it...
	eips $(((${EIPS_MAXCHARS} - ${#CUR_SPIN}) / 2)) $((${EIPS_MAXLINES} - 2)) "${CUR_SPIN}"
	sleep 1
	i=$((i+1))
done
# Then clean up
clean_up

# Step 5, run any custom scripts (must do this after cleanup so we have the userstore mounted)
if [ -f "${SCRIPT}" ] ; then
	logmsg "I" "jailbreak" "" "Found script ${SCRIPT}, running it"
	[ -x "${SCRIPT}" ] || chmod +x "${SCRIPT}"
	${SCRIPT}
fi

# Step 6, leave a trace so the user knows they are jailbroken
echo "It is safe to delete this document." > "/mnt/us/documents/You are Jailbroken.txt"
# Flush FS buffers, to be on the safe side...
sync

# If we're in diags, disable it and reboot straight away, to save some time and user interaction :) (From dsmid, thanks!)
if [ "$(idme --bootmode ?)" == "diags" ] ; then
	# Kill the trigger file and extra folder
	rm -f /mnt/us/ENABLE_DIAGS
	[ -d /mnt/us/diagnostic_logs ] && rm -rf /mnt/us/diagnostic_logs

	# Switch the bootmode ourselves
	idme -d --bootmode main

	# Reboot, after an(other) FS buffer flush
	sync
	reboot
fi

exit 0	# required in case we have trailing junk data from a payload
