class CreateContents < ActiveRecord::Migration
  def self.up
    create_table :contents do |t|
      t.string :name
      t.string :mime_type
      t.integer :duration
      t.datetime :start_time
      t.datetime :end_time
      t.text :data
      t.references :user
      t.references :type

      t.timestamps
    end
  end

  def self.down
    drop_table :contents
  end
end
