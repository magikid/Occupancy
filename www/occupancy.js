window.STATUS_OPEN = "open";
window.STATUS_CLOSED = "closed";

// time to wait between asking the server the current status, in seconds
window.statusPollingDelay = 10;

// update the display
window.displayStatus = function(status) {
  jQuery("#statusDisplay").removeClass("open closed unknown");
  jQuery(".button").removeClass("active");
  if(status == window.STATUS_OPEN) {
    jQuery("#closeButton").addClass("active");
    jQuery("#statusDisplay").addClass("open")
  }
  if(status == window.STATUS_CLOSED) {
    jQuery("#openButton").addClass("active");
    jQuery("#statusDisplay").addClass("closed")
  }
}

// query the server to change the status
// not giving an argument with query current status without requesting a change 
window.setStatus = function(newStatus = "status") {
  jQuery.get("/occupancy.php?action=" + newStatus, function(response) {
    window.displayStatus(response)
  });
}

window.pollStatus = function() {
  jQuery.get("/occupancy.php?action=status", function(response) {
    window.displayStatus(response)
    window.setTimeout(window.pollStatus, window.statusPollingDelay * 1000)
  });
}

window.

jQuery(document).ready(function() {
  
  jQuery("#openButton").click(function(event) {
    window.setStatus(window.STATUS_OPEN)
  });
    
  jQuery("#closeButton").click(function(event) {
    window.setStatus(window.STATUS_CLOSED)
  });
  
  window.pollStatus()
  
});