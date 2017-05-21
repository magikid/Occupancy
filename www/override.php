<?php 
define("OVERRIDE_ON", "override_on");
define("OVERRIDE_OFF", "override_disabled");
define("OCCUPANCY_RESTART_COMMAND", "/opt/ocs/Occupancy restart");
define("OVERRIDE_FLAG_FILE", "/opt/uas/Occupancy/www/override.txt");

function readStatus() {
	$fileExists = file_exists(OVERRIDE_FLAG_FILE);
	if($fileExists) {
		return OVERRIDE_ON;
	}
	return OVERRIDE_OFF;
}

function writeStatus($status) {
	if($status == OVERRIDE_ON) {
		$writeResult = file_put_contents(OVERRIDE_FLAG_FILE, OVERRIDE_ON);
		if($writeResult == FALSE) {
			print "Failed to write to status file!"; exit;
		}
	} else {
		$deleteResult = unlink(OVERRIDE_FLAG_FILE);
		if($deleteResult == FALSE) {
			print "Failed to delete status file!"; exit;
		}
	}
	
	shell_exec(OCCUPANCY_RESTART_COMMAND);
}


if(!isset($_GET["action"])) {
	print "GET variable 'action' required."; exit;
}

$action = $_GET['action'];

if($action == "status") {
	print readStatus(); exit;
}

if($action == OVERRIDE_ON) {
	writeStatus(OVERRIDE_ON);
	print readStatus(); exit;
}

if($action == OVERRIDE_OFF) {
	writeStatus(OVERRIDE_OFF);
	print readStatus(); exit;
}

print "action '" . htmlentities($action) . "' is invalid"; exit;