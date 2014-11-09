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

pointCameraAtLight()
{
    #set cam flag
    is_cam_pointed_at_wall=false
    #move camera to preset ocs2, wait for it to finish
    curl "http://10.0.0.4/axis-cgi/com/ptz.cgi?gotoserverpresetname=ocs2&camera=1"
	sleep 2
    #change light sensitivity and wait
    curl "http://10.0.0.4/axis-cgi/com/ptz.cgi?camera=1&irisbar=185&alignment=horisontal&barcoord=80,0"
    sleep 8
    
}

# getWallPicture() 
# moves camera to preset 'TheWall' and sets flag
# then takes picture and puts it at /tmp/thewall.jpg

getWallPicture() 
{
    is_cam_pointed_at_wall=true
    curl "http://10.0.0.4/axis-cgi/com/ptz.cgi?gotoserverpresetname=TheWall&camera=1"
    sleep 3
    curl "http://10.0.0.4/axis-cgi/com/ptz.cgi?camera=1&rzoom=-2500"
    sleep 1
    curl "http://10.0.0.4/axis-cgi/com/ptz.cgi?camera=1&rzoom=+2500"
    sleep 4
    wget http://10.0.0.4/axis-cgi/jpg/image.cgi -q -O $OCS_TMP_WALL
    sleep 1
}

# getBrightness()
# Use camera to determine ceiling_light brightness level
#   * sets $level variable

getBrightness()
{
    # copy pic to tmp
    wget http://10.0.0.4/axis-cgi/jpg/image.cgi -q -O $OCS_TMP_LIGHT
    # average all the grayscale pics to determine/set light brightness level
    level=`convert $OCS_TMP_LIGHT -colorspace gray -format "%[fx:mean]" info:|cut -c3-5`
}


###############################################################################
# Website functions
#
# pushStatusToWebsite()
#   moves the /tmp/status file to the websites status file
pushStatusToWebsite()
{
    echo "pushStatusToWebsite"
ftp -n $OCS_UAS_URL <<END_SCRIPT
    quote USER $OCS_UAS_USER
    quote PASS $OCS_UAS_PASS
    ascii
    passive	
    put $OCS_TMP_STATUS $OCS_UAS_STATUS_FILE_LOC
    quit
END_SCRIPT
}

# pushWallToWebsite()
#   moves the /tmp/thewall.jpg file to the websites status file
pushWallToWebsite()
{
    stamp=`date +"%F%T"`
ftp -n $OCS_UAS_URL <<END_SCRIPT
    quote USER $OCS_UAS_USER
    quote PASS $OCS_UAS_PASS
	ascii
	passive
	put $OCS_TMP_WALL $OCS_UAS_WALL_FILE
	put $OCS_TMP_WALL $OCS_UAS_WALL_ARCHIVE_FILEPATH/$stamp.jpg
   quit
END_SCRIPT
    nc $OCS_IRC_IP $OCS_IRC_PORT !JSON \
        {"Service":$OCS_IRC_SERVICE, \
        "Key":$OCS_IRC_KEY, \
        "Data":"New Wall Image: http://$$OCS_UAS_WALL_ARCHIVE_FILEPATH/$stamp.jpg"} &>/dev/null
}



###############################################################################
# main()
# Main logic function
#   Runs in loop to constantly check occupancy

main()
{

    # Set configurable variables
    source /opt/ocs/ocs_config.cfg
    
    #Inital values/flags
    is_cam_pointed_at_wall=false
    is_occupied=false
    is_overridden=false
    echo "date STARTING ocs.sh" >> $OCS_LOGFILE

    #Loop
    while true; do
        #Make sure camera is pointed at ceiling light and get brightness 'level'
        if $is_cam_pointed_at_wall; then
            pointCameraAtLight
        fi
        getBrightness
        
        # Override check
        if lsusb | grep $OCS_OVERRIDE_LSUSB_VALUE; then
            is_overridden=true
        else
            is_overridden=false
        fi
        
        #PC: If status changes occupied to unoccupied (Turn off)
        if $is_occupied; then
            if ! $is_overridden  && [[ $level -lt $OCS_BRIGHTNESS_THRESHOLD ]]; then
                is_occupied=false
                #Play sound
                mplayer $OCS_WAV_CLOSED_COMMAND
                #Update flags, IRC, website status file, checkin, logging
                echo -n "The space has been closed since " date +"%T %F" > $OCS_TMP_STATUS
                #website status
                pushStatusToWebsite
                #checkin
                python $OCS_CHECKIN_SCRIPT closing
                #logging
                echo "`date` set to CLOSED" >> $OCS_LOGFILE
            fi
        #If status changes unoccupied to occupied (Turn on)
        else
            if $is_overridden || [[ $level -gt $OCS_BRIGHTNESS_THRESHOLD ]]; then
                is_occupied=true
                #Play sound
                mplayer $OCS_WAV_OPEN_COMMAND
                #status file
                echo -n "The space has been open since " date +"%T %F" > $OCS_TMP_STATUS
                #website status
                pushStatusToWebsite
                #Tweet
                #python /opt/uas/statustweet/statustweet.py "The space has been open since ` date `. #unallocated" &>/dev/null
                #IRC
                nc $OCS_IRC_IP $OCS_IRC_PORT !JSON \
                    {"Service":$OCS_IRC_SERVICE, \
                    "Key":$OCS_IRC_KEY, \
                    "Data":"The space has been open since ` date `."}
                #Wall image to website
                getWallPicture
                pushWallToWebsite
                #logging
                echo "`date` set to OPEN" >> $OCS_LOGFILE
                
            fi
        fi
    done


}

###############################################################################
# Script Entry
#   All functions and variables need to be set above these lines 
#   (i.e. keep this at the end)

echo "starting main"
main

exit 0

