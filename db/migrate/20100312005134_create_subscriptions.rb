class CreateSubscriptions < ActiveRecord::Migration
  def self.up
    create_table :subscriptions do |t|
      t.references :feed
      t.references :field
      t.references :screen
      t.integer :weight

      t.timestamps
    end
  end

  def self.down
    drop_table :subscriptions
  end
end
