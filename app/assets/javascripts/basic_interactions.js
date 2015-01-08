function initBasicTooltips() {
  // intitialization of qTip for basic tooltips:
  // this means that tooltips can be used on any page for single-line messages
  $(document).delegate(".tooltip-basic", "mouseover", function(event) {
    $(this).qtip({
      content: {
        text: $(this).attr('data-tooltip-text')
      },
      position: {
        at: 'bottom center', // Position the tooltip below the link
        my: 'top center',
        viewport: $(window) // Keep the tooltip on-screen at all times
      },
      show: {
        event: 'mouseenter', // Show it on focus...
        delay: 500,
        solo: false,
        ready: true
      },
      hide: 'mouseleave',
      style: 'qtip-rounded'
    });
  });

  $('.dropdown-control.dd-jumpto').each(function() {
    $(this).qtip( {
      id: 'jump_to',
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
              api.set('content.text', $("#jump_to").html() );
            }
            
            var tooltip_content = api.elements.content;
            initFeedListState(tooltip_content);

            $('.qtip-content input:first').focus(); }, 50);
          }
      },
      show: {
        event: 'click', // Show it on click...
        solo: true // ...and hide all other tooltips...
      },
      hide: 'unfocus',
      style: 'qtip-light qtip-shadow qtip-rounded qtip-nopadding qtip-minheight'
    });
  }).click(function(e) {
    e.preventDefault();
  });
}

function initCharCount() {
  //Character count for ticker text
  $('.word_count').each(function(){
    var length = $(this).val().length;
    $("#char_count").html(length);
    
    // bind on key up event
    $(this).keyup(function(){
      var new_length = $(this).val().length;
      $("#char_count").html(new_length);
    });
  });
}

function initNoticeBannerDisplay() {
  // flash-banner display animation:
  if ( $("#flash-banner").html() !== "" ) {
    $(function () {
      var topmenuHeight = $("#top-menu").height();
      $("#flash-banner").animate({
        top: '+=' + topmenuHeight
      }, 1000, function() {
        // first animation is complete, so move it back up after 4 seconds:
        $("#flash-banner").delay(4000).animate({
          top: '0'
        }, 1000, function() {});
      });
    });
  }
}

function initFeedFilters() {
  $('.feed_filter').each(function(i){
    $(this).listFilter({anchored: false});
  });
}

function initBasicInteractions() {
  initNoticeBannerDisplay();
  initBasicTooltips();
  initFeedFilters();
  initCharCount();
}

$(document).ready(function() {
    // bootstrap confirmation modal defaults
    $.fn.twitter_bootstrap_confirmbox.defaults = {
        fade: false,
        title: I18n.t('js.confirmbox.title'), // if title equals null window.top.location.origin is used
        cancel: I18n.t('js.confirmbox.cancel'),
        cancel_class: "btn cancel",
        proceed: I18n.t('js.confirmbox.ok'),
        proceed_class: "btn proceed btn-primary"
    };
});

$(document).ready(initBasicInteractions);
$(document).on('page:change', initBasicInteractions);