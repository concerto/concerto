class AddPendingNotificationSentToSubmission < ActiveRecord::Migration
  def change
    add_column :submissions, :pending_notification_sent, :datetime
  end
end
