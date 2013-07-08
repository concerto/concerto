class AddCanCacheToConcertoConfig < ActiveRecord::Migration
  def change
    add_column :concerto_configs, :can_cache, :boolean, :default => true
  end
end
