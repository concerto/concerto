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
##set :asset_env, "#{asset_env} RAILS_RELATIVE_URL_ROOT=/#{application}"  # only needed if running under sub-uri

# this code will get the latest official release, unless a branch was specified in the command line
# like: cap -S branch="master" deploy
# master will deploy the most current development version
set :branch do
  default_tag = `git tag`.split("\n").last
  default_tag
end unless exists?(:branch)

role :web, "concerto"                   # Your HTTP server, Apache/etc
role :app, "concerto"                   # This may be the same as your `Web` server
role :db,  "concerto", primary: true # This is where Rails migrations will run

set :deploy_to, "/var/webapps/#{application}"    # make sure this exists and is writable
##set :deploy_to, "/media/blue2/webapps/#{application}"    # make sure this exists and is writable

set :use_sudo, false
ssh_options[:forward_agent] = true
default_run_options[:pty] = true # must be true for password prompt from git or ssh to work

after "deploy:restart", "deploy:cleanup"      # remove deploys more than 5 versions old
after "deploy:update_code", "deploy:migrate"  # make sure the database is migrated if needed

namespace :deploy do
  %w[start stop restart].each do |command|
    task command, roles: :app, except: { no_release: true } do
      desc "#{command} concerto background services"
      # start, stop, or restart the services if the service control script exists
      run "if [ -L /etc/init.d/concerto ]; then #{sudo} invoke-rc.d concerto #{command}; fi"
    end
  end
  
  # If you are using Passenger mod_rails uncomment this so it restarts your webserver
  task :restart, roles: :app, except: { no_release: true } do
    desc "restart the application server"
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  task :setup_service, roles: :app do
    desc "install concerto background services"
    # Must occur after code is deployed and symlink to current is created
    # If the service control script does not yet exist, but the script is in our app directory
    # then we link it (to create the service control script) and make sure it's executable
    # and not world-writable.  
    # Otherwise if the service control script already exists, then the script in the app directory
    # may have just been replaced, so make sure it's permissions are like we said.
    run "if [ ! -L /etc/init.d/concerto -a -f #{current_path}/concerto-init.d ]; then 
      #{sudo} ln -nfs #{current_path}/concerto-init.d /etc/init.d/concerto && 
      #{sudo} chmod +x #{current_path}/concerto-init.d && 
      #{sudo} chmod o-w #{current_path}/concerto-init.d && 
      #{sudo} update-rc.d concerto defaults ; 
      elif [ -f #{current_path}/concerto-init.d ]; then 
      #{sudo} chmod +x #{current_path}/concerto-init.d && 
      #{sudo} chmod o-w #{current_path}/concerto-init.d ;
      fi"
  end

  task :service_defaults, roles: :app do
    desc "set default directory for concerto background services"
    # set the path for finding our app
    # set the user that the services will run as (vi su)
    run "#{sudo} sh -c 'echo \"CONCERTODIR=#{current_path}\" >/etc/default/concerto'"
    run "#{sudo} sh -c 'echo \"USERNAME=#{user}\" >>/etc/default/concerto'"
  end

  task :remove_service, roles: :app do
    desc "remove concerto background services"
    # if the service control script exists, then remove it and unschedule it
    run "if [ -L /etc/init.d/concerto ]; then 
      #{sudo} unlink /etc/init.d/concerto &&
      #{sudo} update-rc.d concerto remove ;
      fi"
  end
end
before "deploy:remove_service", "deploy:stop"   # stop the service before we remove it
before "deploy:update_code", "deploy:stop"      # stop the service before we update the code
after "deploy:restart", "deploy:setup_service"  # reinstall/reset perms on service after code changes
after "deploy:setup_service", "deploy:start"    # restart the service after its been set up
after "deploy:setup", "deploy:service_defaults" # set defaults for the service when we set up a new server

# make sure our vendor/bundle is linked to our shared bundle path
# which is shared among deploys of only our application 
namespace :bundler do
  task :create_symlink, roles: :app do
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
