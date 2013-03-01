class AddPermissionToFeeds < ActiveRecord::Migration
  def change
    add_column :feeds, :is_viewable, :boolean, default: true
    add_column :feeds, :is_submittable, :boolean, default: true
  end
end
