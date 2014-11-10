Notes about Occupany Script - 2014-11-08

Get running notes:
* Files are written as Bash scripts
* Place all 3 files in /opt/ocs/ because this location is hard-coded.
* Add a line to cron to run the ocs_start.sh at box restart.
* Add the UAS website login credentials to the ocs_config.cfg file.
* make the scripts executable using 'chmod +x osc.sh' and 'chmod +x osc_start.sh'
* add file permissions to source the config file using 'chmod 744 ocs.cfg'
* add file permissions to play the WAV files

Dependencies: (commands that need to be run)
wget
python
curl
convert
cut
ftp
nc
grep
mplayer

2014-11-08 Update
Currently not working: 
    * Tweet command for open not working. Didn't have correct syntax when I stopped coding.
    * WAV files for nowopen and nowclosed are not packaged with these files. They need to be added, and a path in the config file updated.
Things that need to change:
    * Posting status file onto the website is inefficient. Should change based on web admin recommendations.
    * /opt/ocs may be a bad directory to use. Change the hardcoded values in all 3 files to whatever you see fit (ex. /etc/ocs/) 
