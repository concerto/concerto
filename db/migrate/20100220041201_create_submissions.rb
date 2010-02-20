class CreateSubmissions < ActiveRecord::Migration
  def self.up
    create_table :submissions do |t|
      t.references :content
      t.references :feed
      t.boolean :moderation_flag
      t.references :user
      t.integer :duration

      t.timestamps
    end
  end

  def self.down
    drop_table :submissions
  end
end
