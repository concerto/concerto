// preview the graphic
function initializeGraphicPreview() {
  $('#media_file').on("change", function (e) {
    //var url = $(this).data('url');
    //if (url) {
    var preview_width = $("#preview_div").width();
    var form = $(this).closest('form');
    var url = $(this).data('preview-url');

    $.ajax(url, {
      files: $('#media_file'),
      iframe: true,
      type: 'POST'
    }).complete(function(data) {
      console.log(data.responseJSON.id);
    });

      // submit the form via ajax here
      // in the ajax callback, do the following
console.log("preview_width is " + preview_width);
//$("#preview_div").load(url_for_render_for_specific_width, { width: preview_width, type: "Graphic" });
    //}
  });
  console.log('initilized GraphicPreview');
}

$(document).ready(initializeGraphicPreview);
$(document).on('page:change', initializeGraphicPreview);

console.log('initializing GraphicPreview');