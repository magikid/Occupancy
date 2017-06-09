#!/bin/bash

# Set configurable variables
source "ocs.cfg"

set -euo pipefail

###############################################################################
# Occupancy Service
# Unallocated Space
#   Written by Pax - 2014-11-08
#   filename = ocs.sh
#
#   Startup instructions:
#   run at startup, and restart it if it crashes
#
#   Must have access to /tmp/ to write JPEGs and TXT files
###############################################################################

# log()
# A function to make log messages consistant
log()
{
  echo "[$(date "+%Y-%m-%d %T")]: $*" >> "${OCS_LOGFILE}"
}

# getWallPicture() 
# moves camera to preset 'TheWall' and sets flag
# then takes picture and puts it at /tmp/thewall.jpg

getWallPicture () 
{
    curl -s "http://${OCS_AXISCAMERA_IP}/axis-cgi/com/ptz.cgi?gotoserverpresetname=TheWall&camera=1"
    sleep 3
    curl -s "http://${OCS_AXISCAMERA_IP}/axis-cgi/com/ptz.cgi?camera=1&rzoom=-2500"
    sleep 1
    curl -s "http://${OCS_AXISCAMERA_IP}/axis-cgi/com/ptz.cgi?camera=1&rzoom=+2500"
    sleep 4
    wget "http://${OCS_AXISCAMERA_IP}/axis-cgi/jpg/image.cgi" -q -O "${OCS_TMP_WALL}"
    sleep 1
}

# checkOverride()
# Get the current override status from the website
checkOverride()
{
  find_usb=$(lsusb | grep "${OCS_OVERRIDE_LSUSB_VALUE}")
  [ -f "${OCS_OVERRIDE_FILE}" ] || [ "$find_usb" ]
}

###############################################################################
# Website functions
#
# pushStatusToWebsite()
#   moves the /tmp/status file to the websites status file
pushStatusToWebsite ()
{
    log "Call to pushStatusToWebsite"
    ftp -n "${OCS_UAS_URL}" << END_FTP_COMMANDS
        quote USER ${OCS_UAS_USER}
        quote PASS ${OCS_UAS_PASS}
        ascii
        passive 
        put ${OCS_TMP_STATUS} ${OCS_UAS_STATUS_FILE}
        quit
END_FTP_COMMANDS
}

# pushWallToWebsite()
#   moves the /tmp/thewall.jpg file to the websites status file
pushWallToWebsite ()
{
    stamp=$(date '+%F_%T')
    ftp -n "${OCS_UAS_URL}" << END_FTP_COMMANDS
        quote USER ${OCS_UAS_USER}
        quote PASS ${OCS_UAS_PASS}
        ascii
        passive
        put ${OCS_TMP_WALL} ${OCS_UAS_WALL_FILE}
        put ${OCS_TMP_WALL} ${OCS_UAS_WALL_ARCHIVE_FILEPATH}/${stamp}.jpg
        quit
END_FTP_COMMANDS

    nc "${OCS_IRC_IP}" "${OCS_IRC_PORT}" \
      "!JSON" \
      "{\"Service\":${OCS_IRC_SERVICE}, \"Key\":${OCS_IRC_KEY}, \"Data\":\"New Wall Image: http://${OCS_UAS_WALL_ARCHIVE_FILEPATH}/${stamp}.jpg\"}" \
      &>/dev/null
}

# openTheSpace()
# Tells the world that we're open by posting to all of our various social media
# and other services
openTheSpace()
{
  # status file
  echo "The space has been open since $(date '+%T %F')" > "${OCS_TMP_STATUS}"

  # website status
  pushStatusToWebsite

  # Tweet (not correct yet)
  python /opt/uas/statustweet/statustweet.py "$(cat "${OCS_TMP_STATUS}") #Unallocated" &>/dev/null

  # IRC
  curl -X POST 127.0.0.1:9999/ --data '{"Service":"Occupancy","Data":"The space is now open"}'

  #Wall image to website
  getWallPicture
  pushWallToWebsite
}

# closeTheSpace()
# Tells the world that we're closed by posting to all of our various social
# media and other services
closeTheSpace()
{
  #Update flags, IRC, website status file, checkin, logging
  echo "The space has been closed since $(date '+%T %F')" > "${OCS_TMP_STATUS}"
  #website status
  pushStatusToWebsite
  #checkin
  python "${OCS_CHECKIN_SCRIPT}" "closing"
  # Twitter
  python /opt/uas/statustweet/statustweet.py "$(cat "${OCS_TMP_STATUS}") #Unallocated" &>/dev/null
  # IRC
  curl -X POST 127.0.0.1:9999/ --data '{"Service":"Occupancy","Data":"The space is now closed"}'
}

# cleanUp()
# Perform any necessary script clean up here like deleting the PID
cleanUp()
{
  log "Caught signal, exiting"
  rm "${OCS_PID_FILE_PATH}"
  exit
}



###############################################################################
# main()
# Main logic function
#   Runs in loop to constantly check occupancy

main ()
{

    # Write the PID to file for the service script
    echo $BASHPID > "${OCS_PID_FILE_PATH}"

    # Capture signals so we clean up the pid file properly.
    trap cleanUp SIGHUP SIGINT SIGTERM

    #Inital values/flags
    log "STARTING ocs.sh"

    #Loop
    while true; do
        if checkOverride; then
          openTheSpace
          log "Space is OPEN"
        else
          closeTheSpace
          log "Space is CLOSED"
        fi

        sleep "${OCS_DELAY}"
    done

    # We'll probably never reach here properly, but if we do, clean up the PID file.
    rm "$OCS_PID_FILE_PATH"
}

###############################################################################
# Script Entry
#   All functions and variables need to be set above these lines 
#   (i.e. keep this at the end)

log "starting main"
main

exit 0
