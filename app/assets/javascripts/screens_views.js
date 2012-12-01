$(document).ready(function() {
  // inset-selection gridlist: when a user clicks on an item in this
  // type of gridlist, auto-select the input that's inside of the item
  $("ul.list-grid.inset-selection li > a").click(function(e) {
    e.preventDefault();
    $(this).find(".inp input").prop("checked", true);
  });

  initTemplateSelector();
});

function initTemplateSelector() {
  $('.template-selector.dropdown-control').click(function(event) { event.preventDefault(); });
  $('.template-selector.dropdown-control').each(function() {
    $(this).qtip( {
      content: {
        text: $( $(this).attr('rel') ).html(),
        title: {
          text: 'Larger Preview',
          button: true
        }
      },

      position: {
        at: 'bottom center', // Position the tooltip above the link
        my: 'top center',
        viewport: $(window) // Keep the tooltip on-screen at all times
      },

      show: {
        delay: 500,
        event: 'hover', // Show it on click...
        solo: true // ...and hide all other tooltips...
      },

      hide: 'unfocus',
      style: 'ui-tooltip-dark ui-tooltip-bigenough ui-tooltip-shadow ui-tooltip-rounded'
    });
  });
}
