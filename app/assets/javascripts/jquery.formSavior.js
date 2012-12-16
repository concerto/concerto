/*
 *  formSavior, a jQuery plugin for observing form inputs
 *  and alerting the user if there are unsaved changes.
 *
 *  Author: Anand Gorantala
 *  (https://github.com/ianand2/Form-Savior)
 *
 *  Usage:
 *  $('#form1').formSavior();
 */

(function( $ ){
  $.fn.formSavior = function(options) {
    return this.each(function() {

      var cfg = {
        'msg'   : 'There are unsaved changes on this form',
        'noprompt' : 'fs_noprompt'
          };
      
      if ( options ) {
            $.extend( cfg, options );
        }
      var originals = '';
      var showalert = true;
      
      var $form = $(this);
      $win = $(window);
      $doc = $(document);
      
      // Adding a click listener for noprompt links, onclick adds a noprompt class to the form
      $('.'+cfg.noprompt).live('click', function() {
        $(this).closest("form").addClass(cfg.noprompt);
      });
      
      function saveOriginals() {
        originals = extractFormData();
      }
      
      function extractFormData() {
        var formdata = $form.serialize();
        $('input[type=file]').each(function(index){
          formdata = formdata + $(this).val();
        });
        return formdata;
      }
      
      function allowSave() {
        showalert = false;
      }
      
      function savePrompt() {
        current = extractFormData();
        if(current != originals && showalert === true && !$form.hasClass(cfg.noprompt)) {
          return cfg.msg;         // The beforeunload event takes only a string as argument and displays the prompt.
        }
      }
      $doc.ready(saveOriginals);        // Saving original state of the form once the document is loaded
      $form.submit(allowSave);        // Allowing form to save when it is submitted
      $win.bind('beforeunload', savePrompt);  // Function call here to check if the form has changed
    });

  };
})( jQuery );