class CreateTextBlobs < ActiveRecord::Migration[7.1]
  def change
    create_table :text_blobs do |t|
      t.text :body
      t.integer :render_as

      t.timestamps
    end
  end
end
