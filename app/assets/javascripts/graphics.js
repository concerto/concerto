// preview the graphic once a file is chosen
// Make sure it only gets initialized once since it uses delegation and we dont
// want the change event on the file input wired up more than once.
var initializeGraphicPreview = {
  initialized: false,

  initialize: function() {
    if (!this.initialized) {
      $(document).delegate('#media_file', "change", function (e) {
        var preview = $("#preview_div");
        var media_id = $("#graphic_media_attributes_0_id");
        var form = $(this).closest('form');
        var media_url = $(this).data('media-url');
        var preview_url = $(this).data('url');

        preview.html("<i class='icon-refresh icon-spin'></i> Loading... ");
        media_id.val("");

        $.ajax(media_url, {
          files: $('#media_file'),
          iframe: true,
          type: 'POST',
        }).complete(function(data) {
          media_id.val(data.responseJSON.id);
          preview.load(preview_url, { data: { media_id: data.responseJSON.id, 
            width: preview.width() }, type: "Graphic" } );
        }).error(function() {
          preview.html("Unable to preview at this time.");
        });
      });
      // console.log('initialized GraphicPreview');
      this.initialized = true;

      // Fire off the preview if we already have a media_id, which is the
      // case when validation errors in the form occur.
      var media_id = $("#graphic_media_attributes_0_id");
      if (media_id.val() != "") {
        var preview = $('#preview_div');
        var file_input = $('#media_file');
        var preview_url = file_input.data('url');

        preview.load(preview_url, { data: { media_id: media_id.val(), 
          width: preview.width() }, type: "Graphic" } );
      }
    } else {
      // console.log('already initialized');
    }
  }
};

$(document).ready(initializeGraphicPreview.initialize);
$(document).on('page:change', initializeGraphicPreview.initialize);
