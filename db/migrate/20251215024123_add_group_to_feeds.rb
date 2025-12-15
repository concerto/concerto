class AddGroupToFeeds < ActiveRecord::Migration[8.1]
  def change
    add_reference :feeds, :group, null: false, foreign_key: true
  end
end
