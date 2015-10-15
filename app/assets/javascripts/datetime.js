function addDateTimeUi() {
  // Setup the date pickers
  // why dont we just look for the .datefield class and hookup that way?
  $('#start_time_date').datepicker({ autoclose: true });
  $('#end_time_date').datepicker({ autoclose: true });
}

function toggleTimeSelects() {
  $(".event-toggleTimeSelects").on("click", function(e) {
    e.preventDefault();
    $(this).parent().hide();
    $(".event-timeSelectDiv").show();
  });

  $(".event-timeSelectDiv").hide();
}

function initDateTime() {
  if($('.datefield').length > 0) {
    addDateTimeUi();
  }
  if ( $(".event-toggleTimeSelects").length > 0 ) {
    toggleTimeSelects();
  }

  // Setup the time pickers
  $('.timefield').timepicker();


  // make sure the icon-calendar's get wired up too
  // for each datepicker item (identified by having the datefield css class on it)
  // find the icon-calendar item next to it (before or after) and wire it's click to open
  // the datepicker that it's related to
  $('.datefield').each(function (index) {
      $(this).parent().find('i[class="fa fa-calendar"]').on('click', function () {
        $(this).closest('div').find('.datefield').datepicker('show');
      });
  });
}

$(document).ready(initDateTime);
$(document).on('page:change', initDateTime);
