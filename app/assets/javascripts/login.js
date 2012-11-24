function initLogin() {
  $("#login-dropdown").each(function() {
    $(this).qtip({
      content: {
        text: 'Loading...', // use this text while loading content via AJAX
        ajax: {
          url: $(this).attr('href') + '?no_content_cell=1',
          type: 'GET'
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
      hide: 'unfocus',
      style: 'ui-tooltip-light ui-tooltip-shadow ui-tooltip-rounded ui-tooltip-nopadding ui-tooltip-autowidth'
    })
  }).click(function(e) { e.preventDefault(); });
}

$(document).ready(initLogin);


