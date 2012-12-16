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

function getNewSubscriptionIndex() {
  var indexArray = [];
  $("form .frequency").each(function() {
    indexArray.push( $(this).attr("data-sub-index") );
  });

  return Math.max.apply(Math, indexArray);
}


function initSubscriptions() {
  //if($('form .frequency').length > 0){
    addSubscriptionsUi();
  //}

  $("#new_subscription").formSavior();
  //console.log($('.dd-addSub').length);
}


$(document).ready(initSubscriptions);
