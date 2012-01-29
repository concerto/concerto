class AddModerationReasonToSubmissions < ActiveRecord::Migration
  def up
    add_column :submissions, :moderation_reason, :text
  end

  def down
    remove_column :submissions, :moderation_reason
  end
end
