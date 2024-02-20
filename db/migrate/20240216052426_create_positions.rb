class CreatePositions < ActiveRecord::Migration[7.1]
  def change
    create_table :positions do |t|
      t.decimal :top
      t.decimal :left
      t.decimal :bottom
      t.decimal :right
      t.text :style
      t.references :template, null: false, foreign_key: true
      t.references :field, null: false, foreign_key: true

      t.timestamps
    end
  end
end
