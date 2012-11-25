function addDateTimeUi() {
  // Setup the date pickers
  $("#start_time_date").datepicker();
  $("#end_time_date").datepicker();

  $('#date_start').click(function(event) {
    event.stopPropagation();
    var visible = $('#ui-datepicker-div').is(':hidden');
    $("#start_time_date").datepicker(visible ? 'show' : 'hide');
  });

  $('#date_end').click(function(event) {
    event.stopPropagation();
    var visible = $('#ui-datepicker-div').is(':hidden');
    $("#end_time_date").datepicker(visible ? 'show' : 'hide');
  });

  // Setup the time pickers
  $('#start_time_time').timepicker();
  $("#end_time_time").timepicker();

  $('#time_start').click(function(e) {
    e.stopPropagation();
    $('#start_time_time').timepicker('show');
  });

  $('#time_end').click(function(e) {
    e.stopPropagation();
    $('#end_time_time').timepicker('show');
  });
}

function initDateTime() {
  if($('.datetime').length > 0) {
    addDateTimeUi();
  };
}

$(document).ready(initDateTime);
