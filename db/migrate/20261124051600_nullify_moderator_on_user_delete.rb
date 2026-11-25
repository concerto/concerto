class NullifyModeratorOnUserDelete < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :submissions, :users, column: :moderator_id
    add_foreign_key :submissions, :users, column: :moderator_id, on_delete: :nullify
  end
end
