class AddGroupToScreen < ActiveRecord::Migration[8.0]
  def change
    add_reference :screens, :group, null: false, foreign_key: true
  end
end
