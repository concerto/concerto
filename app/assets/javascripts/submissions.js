function addBrowseUi(){
  $('.dropdown-control').click(function(event) { event.preventDefault(); });

  $('.dropdown-control.dd-jumpto').each(function() {
    $(this).qtip( {
      content: {
        text: $( $(this).attr('rel') ).html(),
        title: {
          text: $(this).attr('title'),
          button: true
        }
      },
      position: {
          at: 'bottom center', // Position the tooltip above the link
          my: 'top left',
          viewport: $(window) // Keep the tooltip on-screen at all times
        },
        show: {
          event: 'click', // Show it on click...
          solo: true // ...and hide all other tooltips...
        },
        events: {
          // this is used to highlight the first input in the box when it is shown...
          show: function() {
            setTimeout(function() {
              $('.ui-tooltip-content input:first').focus(); }, 50);
              initFeedFilters();
            }
        },
        hide: 'unfocus',
        style: 'qtip-light qtip-shadow qtip-rounded'
      });
  });
}

function initBrowse() {
  addBrowseUi();
}

$(document).ready(initBrowse);
$(document).on('page:change', initBrowse);
