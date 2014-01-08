var screenInitTimer = null;
function initScreenSetup() {
  if ($("#screen_temp_token").length) {
    if (screenInitTimer == null) {
      screenInitTimer = setInterval(function() {
        location.reload();
      },5000);
    }
  }
}

$(document).ready(initScreenSetup);
$(document).on('page:change', initScreenSetup);
