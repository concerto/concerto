class RemoveTypesFromFieldConfig < ActiveRecord::Migration
  def change
    remove_column :field_configs, :value_type
    remove_column :field_configs, :value_default
  end
end
