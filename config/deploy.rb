# to deploy using cap
#
# Make sure the appropriate servers are specified below.
# If your user account is not the one going to be used for ssh to those servers, then uncomment the following two
# lines and specify the user that will be used.
#set :user, "www-data"
#set :group, "www-data"
# Make sure the deploy_to path points to your deploy location.
# Run the following two lines at the console
#$ gem install capistrano
#$ cap deploy:setup
#$ cap deploy:check
# Make sure your database.yml file is correctly set up in your deploy_to location under the shared folder
# deploy with the following command
# cap deploy

set :application, "concerto"
set :repository,  "https://github.com/mfrederickson/ssat.git"
set :branch, "master"
set :asset_env, "#{asset_env} RAILS_RELATIVE_URL_ROOT=/#{application}"

role :web, "artemisu"                   # Your HTTP server, Apache/etc
role :app, "artemisu"                   # This may be the same as your `Web` server
role :db,  "artemisu", :primary => true # This is where Rails migrations will run

set :deploy_to, "/var/www/webapps/#{application}"

set :use_sudo, false

# set :scm, :git # You can set :scm explicitly or Capistrano will make an intelligent guess based on known version control directory names
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

task :uname do
  run "uname -a"
end

default_run_options[:pty] = true # must be true for password prompt from git or ssh to work

# if you want to clean up old releases on each deploy uncomment this:
after "deploy:restart", "deploy:cleanup"
after "deploy:update_code", "deploy:migrate"

#after "deploy:update_code", "custom:config"
# move migrate to production one since we dont want to run this when updating the kiosks
#after "deploy:update_code", "deploy:migrate"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'deploy')
require "bundler/capistrano"
require "capistrano_database"
