# to deploy using cap
#
# Make sure the appropriate servers are specified below.
# Make sure the deploy_to path points to your deploy location.
# Run the following two lines at the console (actually, I couldn't get this part to work, so I added 
# them to the Gemfile and then ran bundle, and then continued with the cap commands...)
#$ gem install capistrano
#$ gem install capistrano-tags
#$ cap deploy:setup
#$ cap deploy:check
# Make sure your database.yml file is correctly set up in your deploy_to location under the shared folder
# deploy with the following command
# cap deploy

# If your user account is not the one going to be used for ssh to those servers, then uncomment the following two
# lines and specify the user that will be used.
#set :user, "deploy"
#set :group, "deploy"

set :application, "concerto"
set :repository,  "https://github.com/concerto/concerto.git"
set :asset_env, "#{asset_env} RAILS_RELATIVE_URL_ROOT=/#{application}"  # only needed if not running at root of webserver
set :deploy_via, :remote_cache

# this code will get the latest official release, unless a branch was specified in the command line
# like: cap -S branch="master" deploy
# master will deploy the most current development version
set :branch do
  default_tag = `git tag`.split("\n").last
  default_tag
end unless exists?(:branch)

role :web, "concerto.local"                   # Your HTTP server, Apache/etc
role :app, "concerto.local"                   # This may be the same as your `Web` server
role :db,  "concerto.local", :primary => true # This is where Rails migrations will run

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
after "deploy:update_code", "custom:plugins"
#before "deploy:assets:precompile", "custom:plugins"

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

# task to run the install for the plugins and recompile the frontend_js
namespace :custom do
  task :plugins, :roles => [:app, :web] do
    run "cd #{release_path} && rails generate concerto_remote_video:install install
      && rails generate concerto_iframe:install install && cd public/frontend_js && ./compile --debug"
  end
end


$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'deploy')

#set :bundle_flags, "--deployment"   # override, if you want, so --quiet is not specified
set :bundle_dir, "vendor/bundle"  # this uses separate bundles (as the application specifies, and is very slow)

require "capistrano-tags"   # required because concerto doesnt have a "branch" for each tag
require "bundler/capistrano"
require "capistrano_database"

