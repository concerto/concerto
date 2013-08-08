module SubscriptionsHelper
  def link_to_add_field_config_fields (name, f)
    new_object = FieldConfig.new
    fields = f.fields_for('field_config[]', new_object, :index => "new_record") do |builder|
      render("field_config_fields", :p => builder)
    end
    link_to_function(name, "add_field_config_fields(this, \"record\", \"#{escape_javascript(fields)}\")", :class => "btn")
  end
end
