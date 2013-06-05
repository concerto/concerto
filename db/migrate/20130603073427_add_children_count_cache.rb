class AddChildrenCountCache < ActiveRecord::Migration
  def change
    add_column :contents, :children_count, :integer, :default => 0
  end
end
