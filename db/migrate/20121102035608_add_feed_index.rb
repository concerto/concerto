class AddFeedIndex < ActiveRecord::Migration
  def up
    add_index :feeds, :parent_id
  end

  def down
    remove_index :feeds, :parent_id
  end
end
