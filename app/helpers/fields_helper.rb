module FieldsHelper
  def field_templates(field)
    templates = Array.new
    field.positions.each do |p| 
      templates << p.template unless templates.include?(p.template)
    end
    templates.sort{|a, b| a.name <=> b.name}
  end
end