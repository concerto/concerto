class AddOrderingStrategyToFieldConfigs < ActiveRecord::Migration[8.1]
  def change
    add_column :field_configs, :ordering_strategy, :string, default: "random"
  end
end
