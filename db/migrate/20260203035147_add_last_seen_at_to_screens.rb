class AddLastSeenAtToScreens < ActiveRecord::Migration[8.1]
  def change
    add_column :screens, :last_seen_at, :datetime
  end
end
