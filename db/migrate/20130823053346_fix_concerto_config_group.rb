class FixConcertoConfigGroup < ActiveRecord::Migration
  def change
    rename_column :concerto_configs, :group, :category
  end
end
