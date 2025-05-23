class AddSystemUserFlagToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :is_system_user, :boolean
  end
end
