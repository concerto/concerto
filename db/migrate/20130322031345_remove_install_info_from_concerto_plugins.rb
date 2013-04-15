class RemoveInstallInfoFromConcertoPlugins < ActiveRecord::Migration
  def up
    remove_column :concerto_plugins, :installed
    remove_column :concerto_plugins, :module_name
  end

  def down
    add_column :concerto_plugins, :module_name, :string
    add_column :concerto_plugins, :installed, :boolean
  end
end
