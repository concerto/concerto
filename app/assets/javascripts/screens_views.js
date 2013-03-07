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
        at: 'top center', // Position the tooltip above the link
        my: 'bottom center',
        viewport: $(window) // Keep the tooltip on-screen at all times
      },

      show: {
        delay: 1000,
        event: 'hover', // Show it on click...
        solo: true // ...and hide all other tooltips...
      },

      hide: 'unfocus',
      style: 'ui-tooltip-dark ui-tooltip-bigenough ui-tooltip-shadow ui-tooltip-rounded'
    });
  });
}

function initScreensViews() {
  // inset-selection gridlist: when a user clicks on an item in this
  // type of gridlist, auto-select the input that's inside of the item
  $("ul.list-grid.inset-selection li img").click(function(e) {
    e.preventDefault();
    $(this).parents('li').find(".inp input").prop("checked", true);
  });

  $("#screen_owner_type").change(function() {
    // make a POST call and replace the content
    $.post("/update_owners", {owner: $('select#screen_owner_type :selected').val()}, function(data) {
      $("#owner_div").html(data);
    });
  });

  initTemplateSelector();
}

$(document).ready(initScreensViews);
$(document).on('page:change', initScreensViews);
