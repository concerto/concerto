class AddTimestampToFieldConfig < ActiveRecord::Migration
  def change
    add_timestamps(:field_configs)
  end
end
