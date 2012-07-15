class AddPluginConfigs < ActiveRecord::Migration
  def up
    add_column :concerto_configs, :plugin_config, :boolean
    add_column :concerto_configs, :plugin_id, :integer
  end

  def down
    remove_column :concerto_configs, :plugin_config
    remove_column :concerto_configs, :plugin_id
  end
end
