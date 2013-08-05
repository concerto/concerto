function remove_template_fields (link) {
  $(link).prev("input[type=hidden]").val("1");
  $(link).closest(".template-position-fields").hide();
}
