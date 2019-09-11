class IncreaseMediaFileDataLen < ActiveRecord::Migration
  def change
    change_column :media, :file_data, :binary, limit: 16.megabytes
  end
end
