#!/bin/bash
while [ $(nmap db -p 3306 --open | grep "tcp open" | wc -l) != "1" ]; do
  echo "waiting for db..."
  sleep 5
done

setuser app bash --login <<-EOF
cd /home/app/concerto
RAILS_ENV=production bundle install
RAILS_ENV=production bundle exec rake db:migrate
# only load the seeds if no user exist in the database yet
RAILS_ENV=production bundle exec rails console <<-EOC
if User.count == 0
  load 'db/seeds.rb'
end
exit
EOC
RAILS_ENV=production bundle exec rake assets:precompile
EOF
