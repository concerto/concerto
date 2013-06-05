// preview the sanitized ticker text
function initializeTickerPreview() {
  $('div.tabbable ul.nav-tabs li a').click(function (e) {
    e.preventDefault();
    $("div.ticker-preview").html("...");
    $(this).tab('show');
    var url = $(this).data('url');
    if (url) {
      var stuff = $('textarea#ticker_data').val();
      $("div.ticker-preview").load(url, { data: stuff, type: "Ticker" });
    }
  });
}

$(document).ready(initializeTickerPreview);
$(document).on('page:change', initializeTickerPreview);
