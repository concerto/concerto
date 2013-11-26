# Load the rails application
require File.expand_path('../application', __FILE__)

#If no database configuration exists, copy the default SQLite one over...
unless FileTest.exists?("config/database.yml")
  FileUtils.cp "config/database.yml.sqlite", "config/database.yml"
end

# Initialize the rails application
Concerto::Application.initialize!
