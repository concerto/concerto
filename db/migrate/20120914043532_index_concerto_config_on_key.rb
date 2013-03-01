class IndexConcertoConfigOnKey < ActiveRecord::Migration
  def up
    add_index :concerto_configs, :key, unique: true
  end

  def down
    remove_index :concerto_configs, :key
  end
end
