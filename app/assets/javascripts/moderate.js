function addModerateDropdownUi(){
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
function addModerateTileUi(){
  $("a.tile-moderate-approve").click(function(event) {
    event.preventDefault();
    var myTile = $(this).parents(".tile");
    myTile.find(".tile-overlay > div").hide();
    myTile.find(".approve-content-form-overlay form").submit();
    myTile.find(".approve-content-confirm-overlay").show();
    // now select and deal with .tile-overlay (the next element)
    myTile.find(".tile-info").hide().next().show("fast").animate({
      top: "0px",
      opacity: 1
    }, "300", "swing");
  });
  $("a.tile-moderate-deny").click(function(event) {
    event.preventDefault();
    var myTile = $(this).parents(".tile");
    myTile.find(".tile-overlay > div").hide();
    myTile.find(".deny-content-form-overlay").show();
    // now select and deal with .tile-overlay (the next element)
    myTile.find(".tile-info").hide().next().show("fast").animate({
      top: "0px",
      opacity: 1
    }, "300", "swing");
  });
  $("a.moderate-cancel-btn").click(function(event) {
    event.preventDefault();
    var myTile = $(this).parents(".tile");
    myTile
      .find(".tile-overlay")
      .hide()
      .css("top", "202px")
      .prev().show();
  });
}

function initModerate() {
  if($('.dd-moderate').length > 0){
    addModerateDropdownUi();
  }
  if($('.tile-moderate').length > 0){
    addModerateTileUi();
  }
}

$(document).ready(initModerate);
$(document).on('page:change', initModerate);
