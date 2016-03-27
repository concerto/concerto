function addContentResubmitUi(){
  $('.dropdown-control.dd-content-resubmit').each(function() {
    $(this).qtip( {
      id: 'content-resubmit',
      content: {
        title: {
          text: $(this).attr('title'),
          button: true
        },
        text: $("#resubmit-dates")
      },
      position: {
        my: 'top left',         // Position my top left...
        at: 'bottom right',     // at the bottom right of...
        viewport: $(window)     // Keep the tooltip on-screen at all times
      },
      show: {
        event: 'click', // Show it on click...
        solo: true // ...and hide all other tooltips...
      },
      hide: false,
      style: 'qtip-light qtip-shadow qtip-fixedwidth-medium qtip-rounded qtip-nopadding'
    });
  }).click(function(e) {
    e.preventDefault();
  });

  // Only hide the tooltip if the user clicks somewhere outside the qtip div 
  $(document).on('click', function(event) {
    var target = $(event.target)[0];
    var qtip = $('#qtip-1');
    var timepicker = $('.ui-timepicker-wrapper')[0];

    // hide qtip when click target is not the qtip div or a descendant
    // hide qtip when click target is not the timepicker container
    if (!qtip.is(target) && qtip.has(target).length == 0 && !$.contains(event.target, timepicker)) {
      qtip.hide();
    } 
  });

  $('#start_time_time').on('click', bringTimepickerForward);
  $('#end_time_time').on('click', bringTimepickerForward);
}

function bringTimepickerForward(event) {
  var zindex = $('#qtip-1').css('z-index') + 1;
  $('.ui-timepicker-wrapper').css('z-index', zindex);
}

function initContentResubmitUi() {
  if ($('.dd-content-resubmit').length > 0) {
    addContentResubmitUi();
  }
}

$(document).on('page:change', initContentResubmitUi);
$(document).ready(initContentResubmitUi);