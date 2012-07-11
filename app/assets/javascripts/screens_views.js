$(document).ready(function() {
  // inset-selection gridlist: when a user clicks on an item in this
  // type of gridlist, auto-select the input that's inside of the item
  $("ul.list-grid.inset-selection li > a").click(function(e) {
    e.preventDefault();
    $(this).find(".inp input").prop("checked", true);
  });
});
