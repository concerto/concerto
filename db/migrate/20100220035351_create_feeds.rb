class CreateFeeds < ActiveRecord::Migration
  def self.up
    create_table :feeds do |t|
      t.string :name
      t.text :description
      t.integer :parent_id
      t.references :group

      t.timestamps
    end
  end

  def self.down
    drop_table :feeds
  end
end
