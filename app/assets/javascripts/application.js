// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require html5_shiv/html5
//= require jquery.qtip.min
//= require jquery-tools/rangeinput/rangeinput
//= require timepicker/jquery.timepicker
//= require_tree .

$(document).ready(function () {
  
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

  // intitialization of qTip for basic tooltips:
  // this means that tooltips can be used on any page for single-line messages
  $("body").delegate(".tooltip-basic", "mouseover", function(event) {
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
      style: 'ui-tooltip-dark ui-tooltip-rounded'
    });
  });

});


//This is for the screens admin form - and probably belongs somewhere else
jQuery(function($) {
  // when the field changes...
  $("#screen_owner_type").change(function() {
    // make a POST call and replace the content
    $.post("/update_owners", {owner: $('select#screen_owner_type :selected').val()}, function(data) {
      $("#owner_div").html(data);
    });
  });
});


function initFeedFilters() {
  $('.feed_filter').each(function(i){
    $(this).listFilter();
  });
}

$(document).ready(initFeedFilters);
