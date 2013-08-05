class AddConfirmableToConcertoConfig < ActiveRecord::Migration
  def change
    add_column :concerto_configs, :confirmable, :boolean, :default => true
  end
end
