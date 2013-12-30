class AddFieldsKinds < ActiveRecord::Migration
  def up
  	create_table :fields_kinds, :id => false do |t|
  	  t.references :field, :kind
  	end
  	add_index :fields_kinds, [:field_id, :kind_id]

    if Field.column_names.include? 'kind_id'
      # run sql to populate from field's kind_id
      Field.all.each do |f|
        execute "insert into Fields_Kinds (field_id, kind_id) values (#{f.id}, #{f.kind_id})"
      end
      remove_column :fields, :kind_id 
      #Field.connection.schema_cache.clear!
      #Field.reset_column_information
    end
  end

  def down
  	add_column :fields, :kind_id, :integer
  	# populate column in fields from first entry in fields_kinds
  	drop_table :fields_kinds
  end
end
