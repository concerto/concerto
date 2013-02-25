class AddEmailNotifications < ActiveRecord::Migration
  def change
    add_column :memberships, :receive_emails, :boolean
    add_column :users, :receive_moderation_notifications, :boolean
    add_index :memberships, :receive_emails
  end
end
