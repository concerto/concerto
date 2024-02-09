class CreateContents < ActiveRecord::Migration[7.1]
  def change
    create_table :contents do |t|
      t.string :name
      t.integer :duration
      t.datetime :start_time
      t.datetime :end_time
      t.references :subtype, polymorphic: true, null: false

      t.timestamps
    end
  end
end
