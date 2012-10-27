class ChangeConcertoConfigAddMetadata < ActiveRecord::Migration
  def up
    add_column :concerto_configs, :name, :string
    add_column :concerto_configs, :group, :string
    add_column :concerto_configs, :description, :text
  end

  def down
    remove_column :concerto_configs, :name
    remove_column :concerto_configs, :group
    remove_column :concerto_configs, :description
  end
end
