function initLogin() {
  $("#login-dropdown").each(function() {
    $(this).qtip({
      content: {
        text: "<div class='default-padding'><i class='fa fa-spinner fa-spin fa-2x'></span></div>", // use this text while loading content via AJAX
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
      events: {
        // this is used to highlight the first input in the box when it is shown...
        show: function() {
          setTimeout(function() {
            var api = $("#login-dropdown").qtip('api');
            $(api.elements.content).find(":input:not([type=hidden])").first().focus();
            }, 50);
          }
      },
      hide: 'unfocus',
      style: 'qtip-light qtip-shadow qtip-rounded qtip-nopadding qtip-autowidth'
    });
  }).click(function(e) {
    e.preventDefault();
  });
}

$(document).ready(initLogin);
$(document).on('page:change', initLogin);
