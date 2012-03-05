class AddWidthAndHeightToTemplates < ActiveRecord::Migration
  def change
    add_column :templates, :original_width, :integer
    add_column :templates, :original_height, :integer
  end
end
