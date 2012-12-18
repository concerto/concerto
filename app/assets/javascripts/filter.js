/*
 *  listFilter, a jQuery plugin for filtering list-like structures based
 *  on an attribute of those elements
 *
 *  Author: bmichalski@gmail.com (Brian Michalski)
 *
 *  Usage:
 *  $('#list_filter').listFilter();
 *
 *  Settings:
 *    list: The element to filter.  Defaults to .filterable
 *    attr: The attribute to filter elements in the list on.
 *      Default: data-filter
 *    show_unknown: Should elements without the attribute be
 *      shown or not.  Default: true [show them]
 *    show_action: The function to call on elements to show.
 *    hide_action: The function to call on elements to hide.
 */
(function($) {
  $.fn.listFilter = function(options) {
    var settings = $.extend({
      'list': '.filterable',
      'attr': 'data-filter',
      'show_unknown': true,
      'show_action': function(elem) { elem.show() },
      'hide_action': function(elem) { elem.hide() }
    }, options);

    var input_box = $(this);
    var lists = $(settings['list']);

    this.bind('keyup.listFilter search.listFilter', function(event) {

      // A special case to clear the input if ESC is pushed
      if (event.keyCode == 27) {
        input_box.val('');
      }

      var text = input_box.val();
      var specials = new RegExp("[.*+?|()\\[\\]{}\\\\]", "g");
      text = text.replace(specials, "\\$&");
      var regex = new RegExp('^' + text, 'i');

      lists.each(function() {
        // Grab all the possible children.  The existance of the attr and
        // show_unkown control the behavior for unknown entities.
        var children = $(this).children();

        children.each(function() {
          var list_element = $(this);

          // Avoid filtering elements that do not have the fitlering attribute
          // iff show_unknown is true.
          if (list_element.attr(settings['attr']) !== undefined ||
              !settings['show_unknown']) {

            // If the regex passes show the element, otherwise hide it.
            if (regex.test(list_element.attr(settings['attr']))) {

              // Trigger the show_action
              settings['show_action'](list_element);

            } else {

              // Trigger the hide_action
              settings['hide_action'](list_element);

            }
          }
        });
      });
    });
  };
}) (jQuery);
