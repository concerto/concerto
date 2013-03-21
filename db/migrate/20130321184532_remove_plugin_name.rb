class RemovePluginName < ActiveRecord::Migration
  def change
    remove_column :concerto_plugins, :name
  end
end
