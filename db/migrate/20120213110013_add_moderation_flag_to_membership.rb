class AddModerationFlagToMembership < ActiveRecord::Migration
  def up
    add_column :memberships, :moderation_flag, :boolean
  end

  def down
    remove_column :memberships, :moderation_flag
  end
end
