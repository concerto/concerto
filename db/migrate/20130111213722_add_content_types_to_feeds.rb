class AddContentTypesToFeeds < ActiveRecord::Migration
  def change
    add_column :feeds, :content_types, :text
  end
end
