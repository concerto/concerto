// preview the sanitized ticker text
function initializeTickerPreview() {
  $('#ticker_data').keypress(function (e) {
    var url = $(this).data('url');
    if (url) {
      var stuff = $('textarea#ticker_data').val();
      $("#preview_div").load(url, { data: stuff, type: "Ticker" });
    }
  });
}

$(document).ready(initializeTickerPreview);
$(document).on('page:change', initializeTickerPreview);
