class CreateFieldConfigs < ActiveRecord::Migration[8.1]
  def change
    create_table :field_configs do |t|
      t.references :screen, null: false, foreign_key: true
      t.references :field, null: false, foreign_key: true
      t.references :pinned_content, null: true, foreign_key: { to_table: :contents }

      t.timestamps
    end

    add_index :field_configs, [ :screen_id, :field_id ], unique: true
  end
end
