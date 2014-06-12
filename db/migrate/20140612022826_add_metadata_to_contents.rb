class AddMetadataToContents < ActiveRecord::Migration
  def change
    add_column :contents, :metadata, :text
  end
end
