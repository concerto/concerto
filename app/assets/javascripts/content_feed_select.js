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
      style: 'qtip-light qtip-shadow qtip-rounded qtip-nopadding'
    });
  }).click(function(e) {
    e.preventDefault();
  });

  $(document).on("click", "#marker-feed-list .marker-feed a", function(e) {
    e.preventDefault();
    $(this).parents('.marker-feed').remove();
  });
}

function generateContentFeedIdArray() {
  var feedIdArray = $("#marker-feed-list .marker-feed").map(function(){
    return $(this).attr('data-feed-id');
  }).get();
  return feedIdArray;
}

function initContentFeedSelectState(api_content) {
  var feedIdArray = generateContentFeedIdArray();
  
  // first make sure all checkboxes are unchecked:
  $(api_content).find(".filterable.selector-list input.feed-select-checkbox").prop("checked", false);
  
  $.each(feedIdArray, function(i, feed_id) {
    $(api_content).find("input[type='checkbox'][value='"+feed_id+"']")
      .prop("checked", true);
  });

  $(api_content).find(".feed_filter").each(function() {
    $(this).listFilter();
  });

  $(api_content).find(".filterable.selector-list input.feed-select-checkbox").change(function() {
    var feedIdArray = generateContentFeedIdArray();
    var feed_index = $(this).attr("data-feed-index");
    var feed_id = $(this).val();
    var feed_name = $(this).attr("data-feed-name");
    if ($.inArray(feed_id, feedIdArray) === -1) {
      $("#marker-feed-list").append("<span class='marker-feed' data-feed-id='" + feed_id + "' style='margin-right: 12px;'><input type='hidden' name='feed_id[" + feed_index + "]' value='" + feed_id + "' /><span class='label'>" + feed_name + "&nbsp;&nbsp;&nbsp;<a href='#'><i class='icon-remove'></i></a></span></span>");
    } else {
      $("#marker-feed-list").find(".marker-feed[data-feed-id='" + feed_id + "']").remove();
    }
  });
}

function initContentFeedSelect() {
  if($('.dd-select-feeds').length > 0){
    addContentFeedSelectUi();
  }
}

$(document).ready(initContentFeedSelect);
$(document).on('page:change', initContentFeedSelect);