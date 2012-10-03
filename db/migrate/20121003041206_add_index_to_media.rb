class AddIndexToMedia < ActiveRecord::Migration
  def change
    add_index :media, [:attachable_id, :attachable_type]
  end
end
