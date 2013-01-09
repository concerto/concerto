namespace :dynamic_content do
  desc 'Refresh Dynamic Content'
  task :refresh => :environment do
    DynamicContent.refresh
  end
end
