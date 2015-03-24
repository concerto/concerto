module TemplatesHelper
  def link_to_add_position_fields (name, f, association)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, child_index: "new_#{association}") do |builder|
      render("position_fields", p: builder)
    end
    link_to_function(name, "add_position_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")", class: "btn")
  end
end
