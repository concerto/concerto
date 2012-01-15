!function( $ ) {
  "use strict"

    $.fn.dropdown = function( selector, options ) {
      return $(this).delegate( selector, "click", function( event ) {
        
        event.preventDefault();

        var $this = $(this),
            
            optionExtend = $.extend({
              dropdownPaneSelector: $this.attr("data-dropdown-pane"),
              anchorTo: "left",
              offsetFrom: $()
            }, options),

            dropdownSelector = $(optionExtend.dropdownPaneSelector),

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
          
          optionExtend.anchorTo == "left" ? b = {
            left: myOffset.left - a.left,
            top: myOffset.top - a.top + $this.outerHeight(!0)
          } : optionExtend.anchorTo == "right" && (b = {
            left: myOffset.left - (dropdownSelector.outerWidth(!0) + a.left - $this.outerWidth(!0)),
            top: myOffset.top - a.top + $this.outerHeight(!0)
          }), 
          
          dropdownSelector.css({
            top: b.top,
            left: b.left
          }), 
          
          $(document).bind("keydown.dropdown-button", function(event) {
            if (event.keyCode == 27) $this.click()
          }), 
          
          $("body").append('<div id="dropdown-overlay"></div>'),
          
          $('#dropdown-overlay')
            .click(hideFunction)
            .css("position", "fixed")
            .css("top", 0)
            .css("left", 0)
            .css("height", "100%")
            .css("width", "100%"),
          
          dropdownSelector.show(),

          setTimeout(function() {
            dropdownSelector.addClass("active")
          }, 50),

          dropdownSelector.trigger("activated.dropdownPane"),

          $this.addClass("selected"),

          $this.trigger("show.dropdown-button")
        
        }

        //dropdownSelector.find("a.close").live("click", hideFunction), 
        //dropdownSelector.bind("close.dropdown-button", hideFunction)
      
      })

    }

} ( window.jQuery )
