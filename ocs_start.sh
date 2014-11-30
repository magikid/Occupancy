#!/bin/bash

###############################################################################
# Occupancy Service - Start script
# Unallocated Space
#   Written by Pax - 2014-11-08
#   filename = ocs_start.sh
#
#   Startup instructions:
#   run from cron to start the service
#       add `@restart /opt/ocs/ocs_start.sh` to cron file
#
#   Must have access to /opt/ocs/ to run ocs.sh
###############################################################################

while /opt/uas/Occupancy/ocs.sh ; do
    echo "Occupancy Service has crashed. Restarting in 10 seconds."
    sleep 10
done
echo "Occupancy Service has exited cleanly. This shouldn't happen."
