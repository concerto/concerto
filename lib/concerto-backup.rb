def concerto_backup
  require 'rake'
  Dir["#{Gem.loaded_specs['rails-backup-migrate'].full_gem_path}/lib/tasks/*.rake"].each { |ext| load ext }
  Concerto::Application.load_tasks
  Rake::Task["site:backup"].invoke
end