Notes about Occupany Script - 2014-11-08

Get running notes:
* Files are written as Bash scripts
* Place all 3 files in /opt/ocs/ because this location is hard-coded.
* Add a line to cron to run the ocs_start.sh at box restart.
* Add the UAS website login credentials to the ocs_config.cfg file.

Dependencies: (commands that need to be run)
wget
python
curl
convert
cut
ftp
nc
grep

2014-11-08 Update
Currently not working: 
    * Tweet command for opening. Didn't have correct syntax when I stopped coding.
    * WAV files for nowopen and nowclosed are not packaged with these files. They need to be added, and a path in the config file updated.
Things that need to change:
    * Posting status file onto the website is inefficient. Should change based on web admin recommendations.
