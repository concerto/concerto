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
      hide: 'unfocus',
      style: 'qtip-light qtip-shadow qtip-fixedwidth-medium qtip-rounded qtip-nopadding'
    });
  }).click(function(e) {
    e.preventDefault();
  });
}

function initContentResubmitUi() {
  if ($('.dd-content-resubmit').length > 0) {
    addContentResubmitUi();
  }
}

$(document).on('page:change', initContentResubmitUi);
$(document).ready(initContentResubmitUi);