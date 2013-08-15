# To deploy using capistrano:
#
# This script was tested on the concerto virtual image and should run as is (after the prepare_for_capistrano.sh
# script is run) under the concerto user.  If you need help, post to the group or read up on capistrano.
#
# 1. Make sure you have the capistrano and capistrano-tags gems installed.  On the ubuntu virtual machine image
#    I ran: `sudo apt-get install capistrano`  and: `sudo gem install capistrano-tags`
#    a) Make sure the role :web, :app, and :db servers are set to your actual servers (below).
#    b) Make sure the :deploy_to path points to your actual deploy location.
#    c) If you need to, make sure the :user is set appropriately or comment it out.
#    d) If you are running the site under a subdirectory instead of at the root of the web server then
#       uncomment the :asset_env line and make sure the RAILS_RELATIVE_URL_ROOT is set appropriately.
# 2. Do an initial setup on the production server(s) for the deploy by running: 
#    a) Depending upon your environment, you may not need this-- however, if you are running on the vm image
#       then you do:
#         sudo mkdir /var/webapps && chown concerto:concerto /var/webapps && chmod g+w /var/webapps 
#    b) cap deploy:setup 
#       This will create directories and prompt you for the database password for the concerto user
#       and set up the database.yml file.
#    c) cap deploy:check
# 3. Run: cap deploy
# 4. If you're running on the vm image, and you haven't already done so, change the site configuration
#    to point to the new location where capistrano pushed the files.  Edit your /etc/apache2/sites-enabled/concerto
#    file to include these two changed lines, replacing their counterparts:
#      DocumentRoot /var/webapps/concerto/current/public
#      <Directory /var/webapps/concerto/current/public>
#    And then reload apache to make the changes take effect: sudo service apache2 reload
#
# To update your site with future releases, simply come back here and run: 
#   cap -S branch="releasename" deploy
# and you're done! For example, to push out the 1.2.3.foobar release:
#   cap -S branch="1.2.3.foobar" deploy

set :user, "concerto"

set :application, "concerto"
set :repository,  "https://github.com/concerto/concerto.git"
#set :asset_env, "#{asset_env} RAILS_RELATIVE_URL_ROOT=/#{application}"  # only needed if running under sub-uri

# this code will get the latest official release, unless a branch was specified in the command line
# like: cap -S branch="master" deploy
# master will deploy the most current development version
set :branch do
  default_tag = `git tag`.split("\n").last
  default_tag
end unless exists?(:branch)

role :web, "concerto"                   # Your HTTP server, Apache/etc
role :app, "concerto"                   # This may be the same as your `Web` server
role :db,  "concerto", :primary => true # This is where Rails migrations will run

set :deploy_to, "/var/webapps/#{application}"    # make sure this exists and is writable

set :use_sudo, false

default_run_options[:pty] = true # must be true for password prompt from git or ssh to work

# if you want to clean up old releases on each deploy uncomment this:
after "deploy:restart", "deploy:cleanup"
after "deploy:update_code", "deploy:migrate"

# If you are using Passenger mod_rails uncomment this so it restarts your webserver
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'deploy')

set :bundle_dir, "vendor/bundle"  # this uses separate bundles per release (and is very slow)

require "capistrano-tags"       # needed to deploy tags that are not also branches
require "bundler/capistrano"    # needed to be able to bundle stuff
require "capistrano_database"   # needed to create and link database.yml

