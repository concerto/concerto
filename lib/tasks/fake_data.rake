namespace :db do 
  desc "populate fake data for interactive user testing"
  task :fake_data => :environment do
    require 'populator'  # gem 'populator', :group => [:development]
    require 'ffaker'     # gem 'ffaker', :group => [:development]

    # clear out these tables
    #puts "removing payments"
    #Transaction.delete_all
    puts "removing users"
    # except for admin
    User.all.each do |u|
      u.delete unless u.id == 1
    end

    # load the sample stuff
    puts "loading sample users"
    fn = Faker::Name
    fe = Faker::Internet
    i = 0
    User.populate 160 do |u|
      i += 1
      u.first_name = fn::first_name
      u.last_name = fn::last_name
      u.email = fe.disposable_email(u.first_name[1] + u.last_name + i.to_s)
      u.encrypted_password = 'sample'
    end

  end
end
