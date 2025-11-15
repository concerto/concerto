class AddUniqueIndexToGroupsName < ActiveRecord::Migration[8.1]
  def change
    add_index :groups, :name, unique: true
  end
end
