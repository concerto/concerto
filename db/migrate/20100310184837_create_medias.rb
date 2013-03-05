class CreateMedias < ActiveRecord::Migration
  def self.up
    create_table :medias do |t|
      t.references :attachable, polymorphic: true
      t.string :key
      t.string :file_name
      t.string :file_type
      t.integer :file_size
      t.binary :file_data, limit: 10.megabytes

      t.timestamps
    end
  end

  def self.down
    drop_table :medias
  end
end
