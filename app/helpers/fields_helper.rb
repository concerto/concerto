module FieldsHelper
  def field_templates(field)
    names = Array.new
    field.positions.each do |p| 
      names << p.template.name 
    end
    return names.uniq
  end
end