class AddTemplateOwner < ActiveRecord::Migration
  def change
    add_column :templates, :owner_id, :integer
    add_column :templates, :owner_type, :string
  end
end
