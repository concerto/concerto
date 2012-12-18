class AddHiddenConfig < ActiveRecord::Migration
  def up
    add_column :concerto_configs, :hidden, :boolean
  end

  def down
    remove_column :concerto_configs, :hidden
  end
end
