class CreateSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :settings do |t|
      t.string :key, null: false, index: { unique: true }
      t.text :value
      t.string :value_type

      t.timestamps
    end
  end
end
