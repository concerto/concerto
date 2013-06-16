class AddSeqNoToConcertoConfigs < ActiveRecord::Migration
  def change
    add_column :concerto_configs, :seq_no, :integer, :default => 0
  end
end
