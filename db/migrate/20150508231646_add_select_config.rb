class AddSelectConfig < ActiveRecord::Migration
  def change
    change_column :concerto_configs, :hidden, :boolean, :default => false
    add_column :concerto_configs, :select_values, :string
  end
end
