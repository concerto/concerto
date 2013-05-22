// preview the sanitized ticker text - idealy this would be a modal popup
$("a#ticker-preview").on("ajax:success", function (event, data, status, xhr) {
  $("div.ticker-preview").html(data);
});
