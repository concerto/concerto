class V1User < ActiveRecord::Base
  self.table_name = 'user'
  establish_connection :legacy
end

class V1Group < ActiveRecord::Base
  self.table_name = 'group'
  has_and_belongs_to_many :users, :class_name => 'V1User', :join_table => 'user_group',
                          :foreign_key => 'group_id', :association_foreign_key => 'user_id'
  establish_connection :legacy
end

class V1Feed < ActiveRecord::Base
  self.table_name = 'feed'
  self.inheritance_column = ''
  belongs_to :group, :class_name => 'V1Group', :foreign_key => 'group_id'
  establish_connection :legacy
end

class V1Type < ActiveRecord::Base
  self.table_name = 'type'
  establish_connection :legacy
end

class V1Content < ActiveRecord::Base
  self.table_name = 'content'
  self.inheritance_column = ''
  belongs_to :user, :class_name => 'V1User', :foreign_key => 'user_id'
  belongs_to :type, :class_name => 'V1Type', :foreign_key => 'type_id'
  establish_connection :legacy
end

class V1Submission < ActiveRecord::Base
  self.table_name = 'feed_content'
  establish_connection :legacy  
end
