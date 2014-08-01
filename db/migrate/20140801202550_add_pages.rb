class AddPages < ActiveRecord::Migration
  def change
    create_table :pages do |t|
      t.string :category
      t.string :title
      t.string :language
      t.text :body
      t.timestamps
    end    
  end
end
