namespace :import do
  desc 'Import V1 Concerto database.'
  task :legacy => :environment do
  ActiveRecord::Base.transaction do
    class V1User < ActiveRecord::Base
      self.table_name = 'user'
      establish_connection :legacy
    end

    V1User.all.each do |u|
      first, last = u.name.split(' ', 2)

      new_user = User.new(
        :email => u.email,
        :is_admin => u.admin_privileges,
        :first_name => first,
        :last_name => last,
        :password => u.email,
        :password_confirmation => u.email
      )
      if new_user.save
        puts "Created User - #{new_user.name} (#{new_user.id})"
      else
        puts "Error with User #{new_user.name}\n #{new_user.errors.to_yaml}"
      end
    end

    class V1Group < ActiveRecord::Base
      self.table_name = 'group'
      has_and_belongs_to_many :users, :class_name => 'V1User', :join_table => 'user_group',
                              :foreign_key => 'group_id', :association_foreign_key => 'user_id'
      establish_connection :legacy
    end

    V1Group.all.each do |g|
      new_group = Group.new(
        :name => g.name
      )
      if new_group.save
        puts "Greated Group - #{new_group.name} (#{new_group.id})"
      else
        puts "Error with Group #{new_group.name}\n #{new_group.errors.to_yaml}"
      end

      g.users.each do |u|
        user = User.where(:email => u.email).first
        unless user.nil?
          new_membership = Membership.new(
            :user_id => user.id,
            :group_id => new_group.id,
            :level => Membership::LEVELS[:leader]
          )
          if new_membership.save
            puts "Linked #{user.name} with #{new_group.name}"
          else
            puts "Error with Membership #{new_membership.errors.to_yaml}"
          end
        end
      end
    end
    raise 'Force a rollback'
  end
  end
end
