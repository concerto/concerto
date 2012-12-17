function addSubscriptionsUi(){
  
  $('.dropdown-control.dd-add-sub').click(function(event) {
    event.preventDefault();
  });

  $('.dropdown-control.dd-add-sub').each(function() {
    $(this).qtip( {
      id: 'add-sub',
      content: {
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
        show: function(event, api) {
          setTimeout(function() {
            
            // Update the content of the tooltip on each show
            var target = $(event.originalEvent.target);
            
            if(target.length) {
              api.set('content.text', $("#add-sub").html() );
            }
            
            var tooltip_content = api.elements.content;
            initFeedListState(tooltip_content);

            $('.ui-tooltip-content input:first').focus(); }, 50);

            
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

  // bind click handler to all remove buttons, now and in the future, on subscription UI
  $("body").on("click", "a.btnRemoveSubscription", function(e) {
    $(this).parents("tbody").append("<tr><td></td></tr>");
    $(this).parents("tr").remove();
    showSaveSubsAlert();
    return false;
  });

  $("body").on("click", "form .frequency_range").change(function(e) {
    showSaveSubsAlert();
  });

  $("#save-subscriptions-alert").find("input").attr("disabled", true);

  initializeFrequencySliders();

}

function showSaveSubsAlert() {
  $("#save-subscriptions-alert")
    .removeClass("alert-zero")
    .addClass("alert-info")
    .find("input")
      .addClass("primary")
      .attr("disabled", false)
      .end()
    .find(".save-msg")
      .html("<b>You have made changes to the subscriptions for this field.</b><br />Please click this button to commit your changes, or exit this page to cancel.");
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

function generateFeedIdArray() {
  var feedIdArray = $("#new_subscription .marker-sub-feed").map(function(){
    return $(this).val();
  }).get();

  return feedIdArray;
}

function initFeedListState(api_content) {
  var feedIdArray = generateFeedIdArray();
  $(api_content).find("a").parents("li").removeClass("checked");
  
  $.each(feedIdArray, function(i, feed_id) {
    $(api_content).find("a[data-feed-id='"+feed_id+"']")
      .parents("li").addClass("checked")
      .end()
      .contents().unwrap();
  });

  $(api_content).find(".feed_filter").each(function() {
    $(this).listFilter();
  });
}


function initSubscriptions() {
  if($('#new_subscription').length > 0){
    addSubscriptionsUi();
    $("#new_subscription").formSavior();
  }
}


$(document).ready(initSubscriptions);
