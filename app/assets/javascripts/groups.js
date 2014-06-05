function toggle_prev_denied() {
  if ($("#prev_denied").attr("value") != "hidden") {
    // Hide previously denied users 
    $("#prev_denied").css("display", "none");
    $("#prev_denied").attr("value", "hidden");
    $("#icon_prev_denied").attr("class", "icon-circle-arrow-up");
  } else {
    // Show previously denied users
    $("#prev_denied").css("display", "block");
    $("#prev_denied").attr("value", "shown");
    $("#icon_prev_denied").attr("class", "icon-circle-arrow-down");
  }
}