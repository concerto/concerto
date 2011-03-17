class RenameMediasToMedia < ActiveRecord::Migration
  def self.up
    rename_table :medias, :media
  end

  def self.down
    rename_table :media, :medias
  end
end
