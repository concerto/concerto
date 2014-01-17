// preview the sanitized ticker text
function initializeTickerPreview() {
  $('#ticker_data').keyup(function (e) {
    var url = $(this).data('url');
    if (url) {
      var stuff = $('textarea#ticker_data').val();
      $("#preview_div").load(url, { data: stuff, type: "Ticker" });
    }
  });

  $('#ticker_kind_id').on('change', function(e) {
    if ($('#ticker_kind_id').val() == '3') {
      // text
      $('#ticker_data').attr('rows', 9);
      $('#char_count').parent().hide();
    } else {
      // ticker
      $('#ticker_data').attr('rows', 3);
      $('#char_count').parent().show();
    }
  });
}

$(document).ready(initializeTickerPreview);
$(document).on('page:change', initializeTickerPreview);
