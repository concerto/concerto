# To update or deploy using capistrano:
#
# To deploy from/to the concerto vm image:
# 1. First, you have to run the prepvm_for_capistrano.sh script on the concerto server.  This is a one-time install
#    that makes sure the environment is setup to deploy using capistrano and to receive deploys via capistrano.  More
#    information is provided when you run the script.
# 2. Anytime you want to update, log into the concerto server as the concerto user and run:
#      cd ~/projects/concerto
#      cap deploy
#    You are now up and running on the latest (official) version.  If you want the bleeding edge development
#    version, run cap -S branch="master" deploy
#
# To deploy to another server:
# 1. Make sure the role :web, :app, and :db servers are set to your actual servers (below).
# 2. Make sure the :deploy_to path points to your actual deploy location.
# 3. If you need to, make sure the :user (used for ssh) is set appropriately or comment it out.
# 4. If you are running the site under a subdirectory instead of at the root of the web server then
#    uncomment the :asset_env line and make sure the RAILS_RELATIVE_URL_ROOT is set appropriately.
# 5. Run: cap deploy:setup && cap deploy:check
# 6. Run: cap deploy                <=== this is all you need for subsequent deploys

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
ssh_options[:forward_agent] = true
default_run_options[:pty] = true # must be true for password prompt from git or ssh to work

# if you want to clean up old releases on each deploy uncomment this:
after "deploy:restart", "deploy:cleanup"
after "deploy:update_code", "deploy:migrate"

# If you are using Passenger mod_rails uncomment this so it restarts your webserver
namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} concerto background services"
    task command, roles: :app, except: { :no_release => true } do
      sudo "invoke-rc.d concerto #{command}"
    end
  end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  task :setup_service, :roles => :app do
    sudo "ln -nfs #{current_path}/concerto-init.d /etc/init.d/concerto"
    sudo "chmod +x /etc/init.d/concerto"
    sudo "update-rc.d concerto defaults"
  end
end
#after "deploy:setup", "deploy:setup_service"  # this wont work will it?  no code yet?

# make sure our vendor/bundle is linked to our shared bundle path
# which is shared among deploys of only our application 
namespace :bundler do
  task :create_symlink, :roles => :app do
    shared_dir = File.join(shared_path, 'bundle')
    release_dir = File.join(current_release, 'vendor/bundle')
    run("ln -s #{shared_dir} #{release_dir}")
  end
end
before 'deploy:assets:precompile', 'bundler:create_symlink'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'deploy')
require "capistrano-tags"       # needed to deploy tags that are not also branches
require "bundler/capistrano"    # needed to be able to bundle stuff
require "capistrano_database"   # needed to create and link database.yml
