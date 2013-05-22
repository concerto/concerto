// preview the sanitized ticker text - idealy this would be a modal popup
function initializeTickerPreview() {
  // http://vombat.tumblr.com/post/6874151754/how-do-you-dynamically-set-ajax-request-data-with-rails
  $("a#ticker-preview").on("ajax:before", function () {
    var stuff = $('textarea#ticker_data').val();
    $(this).data('params', { data: stuff });
  });

  $("a#ticker-preview").on("ajax:success", function (event, data, status, xhr) {
    $("div.ticker-preview").html(data);
  });
}

$(document).ready(initializeTickerPreview);
$(document).on('page:change', initializeTickerPreview);
