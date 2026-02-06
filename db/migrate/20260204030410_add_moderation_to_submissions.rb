class AddModerationToSubmissions < ActiveRecord::Migration[8.1]
  def change
    add_column :submissions, :moderation_status, :integer, default: 0, null: false
    add_column :submissions, :moderation_reason, :text
    add_column :submissions, :moderated_at, :datetime
    add_reference :submissions, :moderator, foreign_key: { to_table: :users }

    add_index :submissions, :moderation_status

    # Grandfather existing submissions as approved
    reversible do |dir|
      dir.up { execute "UPDATE submissions SET moderation_status = 1" }
    end
  end
end
