<?php 
define("STATUS_OPEN", "open");
define("STATUS_CLOSED", "closed");
define("OCCUPANCY_RESTART_COMMAND", "/opt/ocs/Occupancy restart");
define("STATUS_FLAG_FILE", "/opt/uas/Occupancy/www/status.txt");

function readStatus() {
	$fileExists = file_exists(STATUS_FLAG_FILE);
	if($fileExists) {
		return STATUS_OPEN;
	}
	return STATUS_CLOSED;
}

function writeStatus($status) {
	if($status == STATUS_OPEN) {
		$writeResult = file_put_contents(STATUS_FLAG_FILE, STATUS_OPEN);
		if($writeResult == FALSE) {
			print "Failed to write to status file!"; exit;
		}
	} else {
		$deleteResult = unlink(STATUS_FLAG_FILE);
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

if($action == STATUS_OPEN) {
	writeStatus(STATUS_OPEN);
	print readStatus(); exit;
}

if($action == STATUS_CLOSED) {
	writeStatus(STATUS_CLOSED);
	print readStatus(); exit;
}

print "action '" . htmlentities($action) . "' is invalid"; exit;