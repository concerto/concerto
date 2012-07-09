class Plugin < ActiveRecord::Base
  attr_accessible :enabled, :gem_name, :gem_version, :installed, :module_name, :name, :source, :source_url
end
