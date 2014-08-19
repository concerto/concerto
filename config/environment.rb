# Load the Rails application.
require File.expand_path('../application', __FILE__)

#If no database configuration exists, copy the default SQLite one over...
unless FileTest.exists?("config/database.yml")
  FileUtils.cp "config/database.yml.sqlite", "config/database.yml"
end

# Initialize the Rails application.
Concerto::Application.initialize!
