/*
 *  dropdown, a jQuery plugin for generic dropdown panels that can be
 *  triggered by any element
 *
 *  Author: brian.r.zaik@gmail.com (Brian R Zaik)
 *          bmichalski@gmail.com (Brian Michalski)
 *
 *  Usage:
 *  <div class='dropdown'>
 *    <a class='dropdown-control'>Click Me</a>
 *    <div class='dropdown-contents' style='display: none;'>
 *      Stuff here to show
 *     </div>
 *  </div>
 *
 *  $(".dropdown").dropdown();
 *
 *  Settings:
 *    open_button: A selector for something within the dropdown element
 *      which should display / hide the content.
 *    content: A selector for the content to be shown (i.e whats in the menu).
 *    close_button: A selector to close the dropdown, perhaps an "X".
 *    underlay: The ID of a div that will be created under everything.
 */

(function($) {
  $.fn.dropdown = function(options) {
    var settings = $.extend({
      'open_button': '.dropdown-control',
      'close_button': '.dropdown-close',
      'underlay': 'dropdown-underlay',
      'content': '.dropdown-contents'
    });

    var dropdown_containers = $(this);

    // For each dropdown that matches the selector...
    dropdown_containers.each(function() {
      var container = $(this);
      // Find all the buttons inside it.
      var open_button = container.children(settings['open_button']);
      open_button.on('click', function() {
        var content = container.children(settings['content']);
        content.toggle();

        // If the content is now being displayed,
        // create a div under it to prevent all other interactions
        if (content.is(':visible')) {
          var underlay = $('<div id="' + settings['underlay'] + '"></div>');
          underlay.css({
            'position': 'fixed',
            'top': '0',
            'left': '0',
            'height': '100%',
            'width': '100%',
            'z-index': content.css('z-index') - 1
          });

          // Remove the overlay when there's a click event in the drop down menu
          content.on('click', function() {
            underlay.remove();
          });

          // When users click in that div, just simulate a click
          // on the button that opened it.
          underlay.on('click', function() {
            open_button.trigger('click');
          });

          underlay.appendTo('body');

        } else {
          // If the content is no longer being displayed,
          // remove the underlay div.
          $('#' + settings['underlay']).remove();
        }
        return false;
      });

      // The container can have a close button, which when clicked
      // it simulates the on the button that opened it.
      var close_button = container.find(settings['close_button']);
      close_button.on('click', function() {
        open_button.trigger('click');
        return false;
      });
    });
  }
}) (jQuery);
