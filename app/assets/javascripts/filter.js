(function($) {
  $.fn.listFilter = function(list_class) {
    var input_box = $(this);
    var lists = $(list_class);
    this.keyup(function(event) {
      var text = input_box.val();
      var regex = new RegExp('^' + text, 'i');
      lists.each(function() {
        var children = $(this).children();
        children.each(function() {
          var list_element = $(this);
          if (regex.test(list_element.attr('data-filter'))) {
            list_element.show();
          } else {
            list_element.hide();
          }
        });
      });
    });
  };
}) (jQuery);
