class AddScreenIdToFieldConfig < ActiveRecord::Migration
  def change
    add_column :field_configs, :screen_id, :integer
  end
end
