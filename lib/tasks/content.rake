namespace :content do
  desc "Purges all expired and unused content in Concerto"
  task :purge_unused_content => :environment do
    Content.all.each do |c|
      if c.is_orphan? && c.is_expired?
        c.destroy
      end
    end
  end
  
  desc "Purges all expired content in Concerto"
  task :purge_expired_content => :environment do
    Content.all.each do |c|
      if c.is_expired?
        c.destroy
      end
    end
  end  
end
