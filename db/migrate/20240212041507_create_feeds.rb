class CreateFeeds < ActiveRecord::Migration[7.1]
  def change
    create_table :feeds do |t|
      t.string :type
      t.string :name
      t.text :description
      t.json :config

      t.timestamps
    end
  end
end
