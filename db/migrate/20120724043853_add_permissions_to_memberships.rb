class AddPermissionsToMemberships < ActiveRecord::Migration
  def change
    add_column :memberships, :permissions, :integer
  end
end
