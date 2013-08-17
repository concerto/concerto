class AddSeqNoToConcertoConfig < ActiveRecord::Migration
  def change
    add_column :concerto_configs, :seq_no, :integer
  end
end
