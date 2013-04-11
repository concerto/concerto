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

(function ($, window, document) {
    "use strict";
    $.fn.formSavior = function (options) {
        return this.each(function () {

            var cfg = {
                'msg'   : 'There are unsaved changes on this form',
                'noprompt' : 'fs_noprompt'
            };

            if (options) {
                $.extend(cfg, options);
            }
            var originals = '',
                showalert = true,
                $form = $(this),
                $win = $(window),
                $doc = $(document);

            // Adding a click listener for noprompt links, onclick adds a noprompt class to the form
            $doc.on('click', '.' + cfg.noprompt, function () {
                $(this).closest("form").addClass(cfg.noprompt);
            });

            // When multiple forms are on the page, and one of the forms triggers the beforeunload 
            // alert, reset showalert back to true 
            $win.bind('fs_beforeUnloadTriggered', function () {
                showalert = true;
            });

            function extractFormData() {
                var formdata = $form.serialize();
                $form.find('input[type=file]').each(function () {
                    formdata = formdata + $(this).val();
                });
                return formdata;
            }

            function saveOriginals() {
                originals = extractFormData();
            }

            function allowSave() {
                showalert = false;
            }

            function savePrompt() {
                var current = extractFormData();
                if (current !== originals &&
                        showalert === true &&
                        !$form.hasClass(cfg.noprompt)) {
                    $win.trigger('fs_beforeUnloadTriggered');
                    return cfg.msg;                 // The beforeunload event takes 
                                                        // only a string as argument and displays the prompt.
                }
            }
            $doc.ready(saveOriginals);              // Saving original state of the form once the document is loaded
            $form.submit(allowSave);                // Allowing form to save when it is submitted
            $win.bind('beforeunload', savePrompt);  // Function call here to check if the form has changed
        });

    };

})(jQuery, window, document);
