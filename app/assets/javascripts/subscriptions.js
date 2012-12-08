function addSubscriptionsUi(){
  
  $('.dropdown-control').click(function(event) { event.preventDefault(); });

  $('.dropdown-control.dd-addSub').each(function() {
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

}

function initSubscriptions() {
  if($('.dd-addSub').length > 0){
    addSubscriptionsUi();
  }
  console.log($('.dd-addSub').length);
}

$(document).ready(initSubscriptions);
