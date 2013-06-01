function initUsers() {
  // automatically submit "receive email" checkbox changes
  $("input[data-autosubmit='true']").on('click', function () {
    $(this).closest('form').submit();
  });
}

$(document).ready(initUsers);
$(document).on('page:change', initUsers);
