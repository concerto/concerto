#!/bin/bash
exec /sbin/setuser app bash --login <<-EOF
cd /home/app/concerto
RAILS_ENV=production bundle exec rake jobs:work >> log/worker.log 2>&1 
EOF
