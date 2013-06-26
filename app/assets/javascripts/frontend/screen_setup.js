function initScreenSetup() {
  if ($("#screen_temp_token").length) {
	  setInterval(function(){
		location.reload();
	  },5000);
  }
}

$(document).ready(initScreenSetup);
$(document).on('page:change', initScreenSetup);
