#Checks current migration status of Concerto and migrates to any more recent migration version available
#Creates and migrates the database if it doesn't yet exist
#Implementation based on http://trevorturk.wordpress.com/2008/04/10/automatically-creating-loading-and-migrating-your-database/

unless Rails.env.test?
  require 'benchmark'

  # Plugin Migrations
  # Check all installed plugins for migrations, and install any that don't
  # exist already. Very similar to rake railties:install:migrations from
  # ActiveRecord. Benchmark comes in at around 62ms.
  # Inspired by rake railties:install:migrations from ActiveRecord.
  railties = ActiveSupport::OrderedHash.new
  Rails.application.railties.all do |railtie|
    if railtie.respond_to?(:paths) && (path = railtie.paths['db/migrate'].first)
      railties[railtie.railtie_name] = path
    end

    on_copy = Proc.new do |name, migration, old_path|
      puts "Copied migration #{migration.basename} from #{name}"
    end

    ActiveRecord::Migration.copy(
      ActiveRecord::Migrator.migrations_paths.first, 
      railties,
      :on_copy => on_copy
    )
  end

  # Database creation and migration
  # Notes:
  #  - Is the rescue really needed?
  #  - This is very fast, but does not account for the possibility of
  #    unrun migrations with an older timestamp. Rails supports detection
  #    and execution of those migrations with db:migrate, but the code 
  #    below does not.
  begin
    current_version = ActiveRecord::Migrator.current_version
    #Grab the timestamp from each migration filename, and run max() on the resulting array
    highest_version = Dir.glob("#{Rails.root.to_s}/db/migrate/*.rb").map { |f| File.basename(f).match(/\d+/).to_s.to_i}.max

    if current_version == 0
      require 'rake'
      Concerto::Application.load_tasks
      Rake::Task["db:create"].invoke
      Rake::Task["db:migrate"].invoke
      Rake::Task["db:seed"].invoke
    elsif current_version != highest_version && current_version != nil
      require 'rake'
      Concerto::Application.load_tasks
      Rake::Task["db:migrate"].invoke
    end
  rescue
    require 'rake'
    Concerto::Application.load_tasks
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
    Rake::Task["db:seed"].invoke
    retry
  end
end
