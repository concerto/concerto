function addBrowseUi(){
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
      events: {
        // this is used to highlight the first input in the box when it is shown...
        show: function() {
          setTimeout(function() {
            $('.ui-tooltip-content input:first').focus(); }, 50);
            initFeedFilters();
          }
      },
      hide: 'unfocus',
      style: 'qtip-light qtip-shadow qtip-rounded qtip-nopadding'
    });
  });
  $(document).delegate(".dd-feedinfo", "mouseover", function(event) {
    $(this).qtip({
      content: {
        text: $("#feedinfo")
      },
      position: {
        at: 'bottom center', // Position the tooltip above the link
        my: 'top left',
        viewport: $(window) // Keep the tooltip on-screen at all times
      },
      show: {
        event: 'mouseenter', // Show it on focus...
        delay: 500,
        solo: false,
        ready: true
      },
      events: {
        // this is used to highlight the first input in the box when it is shown...
        show: function() {
          setTimeout(function() {
            $('.ui-tooltip-content input:first').focus(); }, 50);
            initFeedFilters();
          }
      },
      hide: 'unfocus',
      style: 'qtip-light qtip-shadow qtip-rounded'
    });
  });

}

function initBrowse() {
  addBrowseUi();
  $('.content-frame').mouseover(function() {
    $('.edit-content').css("visibility","visible");
  })
  $('.content-frame').mouseout(function() {
    $('.edit-content').css("visibility","hidden");
  });
}

$(document).ready(initBrowse);
$(document).on('page:change', initBrowse);


function initReorderSubmissions() {
  var feedId = $('.submissions-active').data('feed-id');
  $('.submissions-active .tile').on('dragstart', function(ev) {
    var submissionId = ev.target.closest('.tile').dataset.submissionId;
    ev.originalEvent.dataTransfer.setData('text/plain/id', submissionId);
    ev.originalEvent.dataTransfer.dropEffect = 'move';
  }).on('dragover', function (ev) {
    ev.originalEvent.preventDefault();
    ev.originalEvent.dataTransfer.dropEffect = 'move';
  }).on('drop', function (ev) {
    ev.originalEvent.preventDefault();
    var fromId = ev.originalEvent.dataTransfer.getData('text/plain/id');
    if (fromId) {
      var beforeId = ev.target.closest('.tile').dataset.submissionId;
      if (fromId !== beforeId) {
        $.get('/feeds/' + feedId + '/submissions/' + fromId + '/reorder?before=' + beforeId)
          .done(function(data) {
            $('.tile[data-submission-id=' + beforeId + ']').before($('.tile[data-submission-id=' + fromId + ']'));
          });
      }
    }
  });
}

//$(document).ready(initReorderSubmissions);
$(document).on('page:change', initReorderSubmissions);
