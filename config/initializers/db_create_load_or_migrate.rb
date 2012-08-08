#Implementation based on http://trevorturk.wordpress.com/2008/04/10/automatically-creating-loading-and-migrating-your-database/
require 'rake'
Concerto::Application.load_tasks

begin
  current_version = ActiveRecord::Migrator.current_version
  highest_version = Dir.glob("#{Rails.root.to_s}/db/migrate/*.rb").map { |f| f.match(/\d+/).to_s.to_i}.max
  Rake::Task["db:migrate"].invoke if current_version != highest_version
rescue
  Rake::Task["db:create"].invoke
  abort 'ERROR: Database has no schema version and is not empty' unless ActiveRecord::Base.connection.tables.blank?
  Rake::Task["db:schema:load"].invoke
  retry
end
