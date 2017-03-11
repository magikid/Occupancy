window.OVERRIDE_ON = "override_on";
window.OVERRIDE_OFF = "override_disabled";

window.setCurrently = function(newCurrently) {
  jQuery(".overrideButton").removeClass("currentStatus");
  if(newCurrently == window.OVERRIDE_ON) {
    jQuery("#overrideOpen").addClass("currentStatus");
  }
  if(newCurrently == window.OVERRIDE_OFF) {
    jQuery("#disableOverride").addClass("currentStatus");
  }
}

jQuery(document).ready(function() {
  
  jQuery.get("/override.php?action=status", function(response) {
    window.setCurrently(response);
  });
  
  jQuery("#overrideOpen").click(function(event) {
    jQuery(".overrideButton").removeClass("currentStatus");
    jQuery.get("/override.php?action=" + window.OVERRIDE_ON, function(response) {
      window.setCurrently(response)
    });
  });
    
  jQuery("#disableOverride").click(function(event) {
    jQuery(".overrideButton").removeClass("currentStatus");
    jQuery.get("/override.php?action=" + window.OVERRIDE_OFF, function(response) {
      window.setCurrently(response)
    });
  });
});