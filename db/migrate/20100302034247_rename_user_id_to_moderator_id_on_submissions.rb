class RenameUserIdToModeratorIdOnSubmissions < ActiveRecord::Migration
  def self.up
    rename_column :submissions, :user_id, :moderator_id
  end

  def self.down
    rename_column :submissions, :moderator_id, :user_id
  end
end
