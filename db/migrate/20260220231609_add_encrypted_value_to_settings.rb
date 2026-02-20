class AddEncryptedValueToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :encrypted_value, :text
  end
end
