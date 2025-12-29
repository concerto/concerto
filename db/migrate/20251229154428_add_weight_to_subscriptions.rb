class AddWeightToSubscriptions < ActiveRecord::Migration[8.1]
  def change
    add_column :subscriptions, :weight, :integer, default: 5, null: false
  end
end
