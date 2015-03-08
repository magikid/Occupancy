#!/bin/bash

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


###############################################################################
# Camera functions
#
#
# pointCameraAtLight()
# moves camera to preset 'ocs2' and sets flag

pointCameraAtLight ()
{
    #set cam flag
    is_cam_pointed_at_wall=false
    #move camera to preset OCS2, wait for it to finish
    curl "http://${OCS_AXISCAMERA_IP}/axis-cgi/com/ptz.cgi?gotoserverpresetname=OCS2&camera=1"
    sleep 2
    #change light sensitivity and wait
    curl "http://${OCS_AXISCAMERA_IP}/axis-cgi/com/ptz.cgi?camera=1&irisbar=185&alignment=horisontal&barcoord=80,0"
    sleep 8
}

# getWallPicture() 
# moves camera to preset 'TheWall' and sets flag
# then takes picture and puts it at /tmp/thewall.jpg

getWallPicture () 
{
    is_cam_pointed_at_wall=true
    curl "http://${OCS_AXISCAMERA_IP}/axis-cgi/com/ptz.cgi?gotoserverpresetname=TheWall&camera=1"
    sleep 3
    curl "http://${OCS_AXISCAMERA_IP}/axis-cgi/com/ptz.cgi?camera=1&rzoom=-2500"
    sleep 1
    curl "http://${OCS_AXISCAMERA_IP}/axis-cgi/com/ptz.cgi?camera=1&rzoom=+2500"
    sleep 4
    wget "http://${OCS_AXISCAMERA_IP}/axis-cgi/jpg/image.cgi" -q -O "${OCS_TMP_WALL}"
    sleep 1
}

# getBrightness()
# Use camera to determine ceiling_light brightness level
#   * sets $level variable

getBrightness ()
{
    # copy pic to tmp
    wget "http://${OCS_AXISCAMERA_IP}/axis-cgi/jpg/image.cgi" -q -O "${OCS_TMP_LIGHT}"
    # average all the grayscale pics to determine/set light brightness level
    level=$(convert "${OCS_TMP_LIGHT}" -colorspace gray -format '%[fx:mean]' info:|cut -c3-5)
}


###############################################################################
# Website functions
#
# pushStatusToWebsite()
#   moves the /tmp/status file to the websites status file
pushStatusToWebsite ()
{
    echo "pushStatusToWebsite"
    ftp -n "${OCS_UAS_URL}" <<END_SCRIPT1
        quote USER ${OCS_UAS_USER}
        quote PASS ${OCS_UAS_PASS}
        ascii
        passive	
        put ${OCS_TMP_STATUS} ${OCS_UAS_STATUS_FILE_LOC}
        quit
END_SCRIPT1
}

# pushWallToWebsite()
#   moves the /tmp/thewall.jpg file to the websites status file
pushWallToWebsite ()
{
    stamp=$(date '+%F_%T')
    ftp -n "${OCS_UAS_URL}" <<END_SCRIPT2
        quote USER ${OCS_UAS_USER}
        quote PASS ${OCS_UAS_PASS}
	ascii
	passive
	put ${OCS_TMP_WALL} ${OCS_UAS_WALL_FILE}
	put ${OCS_TMP_WALL} ${OCS_UAS_WALL_ARCHIVE_FILEPATH}/${stamp}.jpg
        quit
END_SCRIPT2
    nc "${OCS_IRC_IP}" "${OCS_IRC_PORT}" "!JSON" "{\"Service\":${OCS_IRC_SERVICE}, \"Key\":${OCS_IRC_KEY}, \"Data\":\"New Wall Image: http://${OCS_UAS_WALL_ARCHIVE_FILEPATH}/${stamp}.jpg\"}" &>/dev/null
}



###############################################################################
# main()
# Main logic function
#   Runs in loop to constantly check occupancy

main ()
{
    # Set configurable variables
    source "/opt/uas/Occupancy/ocs.cfg"

    # Write the PID to file for the service script
    echo $BASHPID > $OCS_PID_FILE_PATH

    # Capture signals so we clean up the pid file properly.
    trap "rm $OCS_PID_FILE_PATH; exit" SIGHUP SIGINT SIGTERM

    #Inital values/flags
    is_cam_pointed_at_wall=false
    is_occupied=false
    is_overridden=false
    echo "$(date) STARTING ocs.sh >> ${OCS_LOGFILE}"

    #Loop
    while true; do
        echo "looping"
        #Make sure camera is pointed at ceiling light and get brightness 'level'
        if $is_cam_pointed_at_wall; then
            pointCameraAtLight
        fi
        getBrightness
        
        # Override check
        if lsusb | grep "${OCS_OVERRIDE_LSUSB_VALUE}" ; then
            is_overridden=true
        else
            is_overridden=false
        fi
        
        #PC: If status changes occupied to unoccupied (Turn off)
        if $is_occupied; then
            if ! $is_overridden  && [[ $level -lt $OCS_BRIGHTNESS_THRESHOLD ]]; then
                is_occupied=false
                #Play sound
                mplayer "${OCS_WAV_CLOSED_COMMAND}"
                #Update flags, IRC, website status file, checkin, logging
                echo "The space has been closed since $(date '+%T %F') > ${OCS_TMP_STATUS}"
                #website status
                pushStatusToWebsite
                #checkin
                python "${OCS_CHECKIN_SCRIPT}" "closing"
                # IRC
                curl -X POST 127.0.0.1:9999/ --data '{"Service":"Occupancy","Data":"The space is now closed"}'
                #logging
                echo "$(date) set to CLOSED >> ${OCS_LOGFILE}"
            fi
        #If status changes unoccupied to occupied (Turn on)
        else
            # Had to mod this because sometimes we get floats and doubles -- we need to be able to handle all.
            if $is_overridden || [[ "$(echo ${level} '>' ${OCS_BRIGHTNESS_THRESHOLD} | bc -l)" -eq 1 ]]; then
                is_occupied=true
                #Play sound
                mplayer "${OCS_WAV_OPEN_COMMAND}"
                #status file
                echo "The space has been open since $(date '+%T %F') > ${OCS_TMP_STATUS}"
                #website status
                pushStatusToWebsite
                #Tweet (not correct yet)
                python /opt/uas/statustweet/statustweet.py "The space has been open since `cat ${OCS_TMP_STATUS}` #Unallocated" &>/dev/null
                #IRC
                #nc "${OCS_IRC_IP}" "${OCS_IRC_PORT}" "!JSON" "{\"Service\":${OCS_IRC_SERVICE}, \"Key\":${OCS_IRC_KEY}, \"Data\":\"The space has been open since $(date '+%T %F').\"}" &>/dev/null
                curl -X POST 127.0.0.1:9999/ --data '{"Service":"Occupancy","Data":"The space is now open"}'

                #Wall image to website
                getWallPicture
                pushWallToWebsite
                #logging
                echo "$(date) set to OPEN >> ${OCS_LOGFILE}"
            fi
        fi
    done

    # We'll probably never reach here properly, but if we do, clean up the PID file.
    rm $OCS_PID_FILE_PATH
}

###############################################################################
# Script Entry
#   All functions and variables need to be set above these lines 
#   (i.e. keep this at the end)

echo "starting main"
main

exit 0

