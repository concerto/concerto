// preview the sanitized ticker text
function initializeTickerPreview() {
  $('#ticker_data').keyup(function (e) {
    var url = $(this).data('url');
    if (url) {
      var stuff = $('textarea#ticker_data').val();
      $("#preview_div").load(url, { data: stuff, type: "Ticker" });
    }
  });

  $('#html_text_data').keyup(function (e) {
    var url = $(this).data('url');
    if (url) {
      var stuff = $('textarea#html_text_data').val();
      $("#preview_div").load(url, { data: stuff, type: "HtmlText" });
    }
  });

  $('#ticker_kind_id').on('change', TickerSettings);
  $('#html_text_kind_id').on('change', HtmlTextSettings);

  function HtmlTextSettings() {
    TextSettings('html_text');
  }

  function TickerSettings() {
    TextSettings('ticker');
  }

  function TextSettings(id) {
    if ($('#' + id + '_kind_id').val() == '3') {
      // text
      $('#' + id + '_data').attr('rows', 9);
      $('#char_count').parent().hide();
    } else {
      // ticker
      $('#' + id + '_data').attr('rows', 3);
      $('#char_count').parent().show();
    }
  }

  if ($('#ticker_kind_id').length != 0) {
    TickerSettings();
  }
  if ($('#html_text_kind_id').length != 0) {
    HtmlTextSettings();
  }
}

$(document).on('turbolinks:load', initializeTickerPreview);
