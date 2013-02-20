function addDateTimeUi() {
  // Setup the date pickers
  $("#start_time_date").datepicker();
  $("#end_time_date").datepicker();

  // Setup the time pickers
  $('#start_time_time').timepicker();
  $("#end_time_time").timepicker();
}

function initDateTime() {
  if($('.datefield').length > 0) {
    addDateTimeUi();
  }
}

$(document).ready(initDateTime);
$(document).on('page:change', initDateTime);
// $(document).on('page:change', function() {
//   $.datepicker.initialized = false;
// });