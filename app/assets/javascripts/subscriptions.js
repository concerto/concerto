function addSubscriptionsUi(){
  
  $('.dropdown-control.dd-add-sub').click(function(event) {
    event.preventDefault();
  });

  $('.dropdown-control.dd-add-sub').each(function() {
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
      events: {
        // this is used to highlight the first input in the box when it is shown...
        show: function() {
          setTimeout(function() {
            $('.ui-tooltip-content input:first').focus(); }, 50);
            initFeedFilters();
          }
      },
      show: {
        event: 'click', // Show it on click...
        solo: true // ...and hide all other tooltips...
      },
      hide: 'unfocus',
      style: 'ui-tooltip-light ui-tooltip-shadow ui-tooltip-rounded ui-tooltip-minheight'
    });
  }).click(function(e) {
    e.preventDefault();
  });

  initializeFrequencySliders();

}

function initializeFrequencySliders() {
  $("form .frequency").each(function() {
    var frequency_elem = $(this).find(".frequency_range");
    
    $(frequency_elem).rangeinput({
      css: {
        handle: 'handle thin'
      }
    }).hide();
    var range_elem = $(this).find(":range");
    var handle_elem = $(this).find(".handle");
    var api = $(range_elem).data("rangeinput");

    $(handle_elem).html('&nbsp;');
    
  });
}


function initSubscriptions() {
  //if($('form .frequency').length > 0){
    addSubscriptionsUi();
  //}

  $("#new_subscription").formSavior();
  //console.log($('.dd-addSub').length);
}


$(document).ready(initSubscriptions);
