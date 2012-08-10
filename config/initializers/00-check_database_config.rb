#If not database configuration exists, copy the default SQLite one over...
unless FileTest.exists?("config/database.yml")
  FileUtils.cp "/config/database.yml.sample", "/config/database.yml"
end