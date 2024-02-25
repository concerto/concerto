class CreateScreens < ActiveRecord::Migration[7.1]
  def change
    create_table :screens do |t|
      t.string :name
      t.references :template, null: false, foreign_key: true

      t.timestamps
    end
  end
end
