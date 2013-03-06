function addModerateUi(){
  $('.dropdown-control').click(function(event) { event.preventDefault(); });

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
          my: 'top center',
          viewport: $(window) // Keep the tooltip on-screen at all times
        },
        show: {
          event: 'click', // Show it on click...
          solo: true // ...and hide all other tooltips...
        },
        hide: 'unfocus',
        style: 'qtip-dark qtip-shadow qtip-rounded'
      });
  });
}

function initModerate() {
  if($('.dd-moderate').length > 0){
    addModerateUi();
  }
}

$(document).ready(initModerate);
$(document).on('page:change', initModerate);
