function initUsers() {
  // automatically submit "receive email" checkbox changes
  $("input[data-autosubmit='true']").on('click', function () {
    $(this).closest('form').submit();
  });
}

$(document).on('turbolinks:load', initUsers);
