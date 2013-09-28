function addContentFeedSelectUi(){
  $('.dropdown-control.dd-select-feeds').each(function() {
    $(this).qtip( {
      id: 'select-feeds',
      content: {
        title: {
          text: $(this).attr('title'),
          button: true
        }
      },
      position: {
        my: 'top left',         // Position my top left...
        at: 'bottom right',     // at the bottom right of...
        viewport: $(window)     // Keep the tooltip on-screen at all times
      },
      events: {
        // this is used to highlight the first input in the box when it is shown...
        show: function(event, api) {
          setTimeout(function() {
            
            // Update the content of the tooltip on each show
            var target = $(event.originalEvent.target);
            
            if(target.length) {
              api.set('content.text', $("#select-feeds").html() );
            }
            
            var tooltip_content = api.elements.content;
            initContentFeedSelectState(tooltip_content);

            $('.qtip-content input:first').focus(); }, 50);
          }
      },
      show: {
        event: 'click', // Show it on click...
        solo: true // ...and hide all other tooltips...
      },
      hide: 'unfocus',
      style: 'qtip-light qtip-shadow qtip-fixedwidth-medium qtip-rounded qtip-nopadding'
    });
  }).click(function(e) {
    e.preventDefault();
  });

  $(document).on("click", "#event-selectedFeedList a.remove-feed", function(e) {
    e.preventDefault();
    $(this).parents('.selected-feed-row').remove();
    if ( $("#event-selectedFeedList .selected-feed-row").size() <= 0 ) {
      $("#event-zeroFeedsMsg").show();
    }
  });
}

function initContentFeedSelectState(api_content) {
  // first make sure all checkboxes are unchecked:
  $(api_content).find(".filterable.selector-list input.feed-select-checkbox").prop("checked", false);

  $(api_content).find(".feed_filter").each(function() {
    $(this).listFilter();
  });
}

function initContentFeedSelect() {
  if($('.dd-select-feeds').length > 0){
    addContentFeedSelectUi();
  }
}

$(document).ready(initContentFeedSelect);
$(document).on('page:change', initContentFeedSelect);