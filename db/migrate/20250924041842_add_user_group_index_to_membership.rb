class AddUserGroupIndexToMembership < ActiveRecord::Migration[8.0]
  def change
    add_index :memberships, [ :user_id, :group_id ], unique: true
  end
end
