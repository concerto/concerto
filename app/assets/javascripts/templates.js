function remove_position_fields (link) {
  $(link).prev("input[type=hidden]").val("1");
  $(link).closest(".template-position-fields").hide();
}

function add_position_fields (link, association, content) {
  var new_id = new Date().getTime();
  var regexp = new RegExp("new_" + association, "g");
  $(link).parent().find('.template-positions').first().append(content.replace(regexp, new_id));
}
