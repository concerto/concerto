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
    $(this).listFilter();
  });
}

function initBasicInteractions() {
  initNoticeBannerDisplay();
  initBasicTooltips();
  initFeedFilters();
}

$(document).ready(initBasicInteractions);
$(document).on('page:change', initBasicInteractions);