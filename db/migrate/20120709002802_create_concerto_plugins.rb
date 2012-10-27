class CreateConcertoPlugins < ActiveRecord::Migration
  def change
    create_table :concerto_plugins do |t|
      t.string :name
      t.string :module_name
      t.boolean :enabled
      t.string :gem_name
      t.string :gem_version
      t.string :source
      t.string :source_url
      t.boolean :installed

      t.timestamps
    end
  end
end
