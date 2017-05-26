class MakeContentDataLarger < ActiveRecord::Migration
  def change
    change_column :contents, :data, :text, limit: 16777215
  end
end
