class AddFrontendUpdatedAt < ActiveRecord::Migration
  def change
    add_column :screens, :frontend_updated_at, :datetime
  end
end
