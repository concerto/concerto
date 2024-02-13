class CreateSubmissions < ActiveRecord::Migration[7.1]
  def change
    create_table :submissions do |t|
      t.references :content, null: false, foreign_key: true
      t.references :feed, null: false, foreign_key: true

      t.timestamps
    end
  end
end
