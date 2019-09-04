#!/bin/bash
exec /sbin/setuser app bash --login <<-EOF
cd /home/app/concerto
RAILS_ENV=production bundle exec clockwork lib/cron.rb >> log/clockwork.log 2>&1
EOF
