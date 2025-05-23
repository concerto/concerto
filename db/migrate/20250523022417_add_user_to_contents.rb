class AddUserToContents < ActiveRecord::Migration[8.0]
  def change
    add_reference :contents, :user, null: false, foreign_key: true
  end
end
