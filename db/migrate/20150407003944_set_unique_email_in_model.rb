class SetUniqueEmailInModel < ActiveRecord::Migration
  def change
    #this removes the hard DB constraint on unique emails - relevant for concerto_identity modules
    remove_index :users, :email
    add_index :users, :email
  end
end
