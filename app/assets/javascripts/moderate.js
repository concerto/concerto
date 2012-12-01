function addModerateUi(){
  $(".moderate-true").hide();
  $(".moderate-false").hide();

  $(document).on("click", ".moderate-select button.approve", function(event) {
    event.preventDefault();
    $(".moderate-false").hide();
    $(".moderate-true").show();
  });

  $(document).on("click", ".moderate-select button.deny", function(event) {
    event.preventDefault();
    $(".moderate-true").hide()
    $(".moderate-false").show();
  });

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
        hide: 'unfocus',
        style: 'ui-tooltip-light ui-tooltip-shadow ui-tooltip-rounded'
      });
  });

  $('.dropdown-control.dd-moderate').each(function() {
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
        hide: 'unfocus',
        style: 'ui-tooltip-dark ui-tooltip-shadow ui-tooltip-rounded'
      });
  });
}

function initModerate() {
  if($('.dd-moderate').length > 0){
    addModerateUi();
  };
  console.log($('.dd-moderate').length);
};

$(document).ready(initModerate);
