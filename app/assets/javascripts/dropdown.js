/*
 *  dropdown, a jQuery plugin for generic dropdown panels that can be 
 *  triggered by any element
 *
 *  Author: brian.r.zaik@gmail.com (Brian R Zaik)
 *
 *  Usage:
 *  $(document).dropdown(".js-dropdown-button");
 *
 *  Settings:
 *    dropdownSelector: Where to find a selector for the <div> or 
 *      other container for the dropdown element.
 *    anchorTo: Specify if the dropdown is anchored to the left 
 *      (default) or the right.
 */

!function( $ ) {
  "use strict"

    $.fn.dropdown = function( selector, options ) {
      return $(this).delegate( selector, "click", function( event ) {
        
        // prevent default behavior for links:
        event.preventDefault();

        var $this = $(this),
            
            optionExtend = $.extend({
              dropdownPaneSelector: $this.attr("data-dropdown-pane"),
              anchorTo: "left",
              offsetFrom: $()
            }, options),

            dropdownSelector = $(optionExtend.dropdownPaneSelector),

            // declare a function to hide and unbind when triggered
            hideFunction = function() {
              $(document).unbind("keydown.dropdown-button"), 
              $("#dropdown-overlay").remove(),
              dropdownSelector.removeClass("active"),
              setTimeout(function() {
                dropdownSelector.hide()
              }, 200),
              $this.removeClass("selected"),
              dropdownSelector.trigger("deactivated.dropdownPane")
            };

        if (dropdownSelector.is(":visible")) hideFunction();
        else {
          var myOffset = $this.offset(),
              a = optionExtend.offsetFrom.length ? optionExtend.offsetFrom.offset() : {
                left: 0,
                top: 0
              },
              b;
          // set the position of the dropdown panel so that it doesn't get hidden
          optionExtend.anchorTo == "left" ? b = {
            left: myOffset.left - a.left,
            top: myOffset.top - a.top + $this.outerHeight(!0)
          } : optionExtend.anchorTo == "right" && (b = {
            left: myOffset.left - (dropdownSelector.outerWidth(!0) + a.left - $this.outerWidth(!0)),
            top: myOffset.top - a.top + $this.outerHeight(!0)
          }); 
          
          dropdownSelector.css({
            top: b.top,
            left: b.left
          }); 
          
          // simulate a click (which will re-run the delegate click event and 
          // hide the dropdown) upon ESC key press
          $(document).bind("keydown.dropdown-button", function(event) {
            if (event.keyCode == 27) $this.click()
          }); 
          
          // we'll append an overlay to float beneath the dropdown to act 
          // as a clickable area - when clicked, the dropdown will be hidden
          $("body").append('<div id="dropdown-overlay"></div>');
          
          // apply css styles to dropdown overlay and show it:
          $('#dropdown-overlay')
            .click(hideFunction)
            .css("position", "fixed")
            .css("top", 0)
            .css("left", 0)
            .css("height", "100%")
            .css("width", "100%");
          
          dropdownSelector.show();

          setTimeout(function() {
            dropdownSelector.addClass("active")
          }, 50);

          dropdownSelector.trigger("activated.dropdownPane");

          $this.addClass("selected");

          $this.trigger("show.dropdown-button");
        
        }

      
      })

    }

} ( window.jQuery )
