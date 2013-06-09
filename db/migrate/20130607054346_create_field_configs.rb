class CreateFieldConfigs < ActiveRecord::Migration
  def change
    create_table :field_configs do |t|
      t.references :field
      t.string :key
      t.string :value
      t.string :value_type
      t.string :value_default
    end
  end
end
