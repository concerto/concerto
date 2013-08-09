namespace :content do
  desc "Purges all expired and unused content in Concerto"
  task :purge_old_content => :environment do
    Content.all.each do |c|
      if c.is_orphan? && c.is_expired?
        c.destroy
      end
    end
  end
end
