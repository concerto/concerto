class RenameTypeToKind < ActiveRecord::Migration
  def self.up
    rename_table :types, :kinds
    rename_column :contents, :type_id, :kind_id
    rename_column :fields, :type_id, :kind_id
  end

  def self.down
    rename_table :kinds, :types
    rename_column :contents, :kind_id, :type_id
    rename_column :fields, :kind_id, :type_id
  end
end
