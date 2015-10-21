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
#
# Wish I could find a safer way...
# Allow the deploy user to run sudo commands without password prompts by adding the following file /etc/sudoers.d/01-concerto
# deploy ALL=(ALL) NOPASSWD:/usr/bin/unlink, /usr/sbin/update-rc.d, /usr/bin/whoami, /usr/bin/env, /bin/sh

# config valid only for current version of Capistrano
lock '3.4.0'

set :stage,       :production
set :application, 'concerto'
set :repo_url,    'https://github.com/concerto/concerto.git'
set :user,        'deploy'


##set :asset_env, "#{asset_env} RAILS_RELATIVE_URL_ROOT=/#{application}"  # only needed if running under sub-uri


role :web, "concerto"                   # Your HTTP server, Apache/etc
role :app, "concerto"                   # This may be the same as your `Web` server
role :db,  "concerto", primary: true    # This is where Rails migrations will run


# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# this code will get the latest official release, unless a branch was specified in the command line
# like: cap -S branch="master" deploy
# master will deploy the most current development version
set :branch, ENV['branch'] || `git tag`.split("\n").last

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/my_app_name'

set :deploy_to, "/var/webapps/#{fetch(:application)}"    # make sure this exists and is writable

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
set :pty, true
set :ssh_options, {
  forward_agent: true,
  user: fetch(:user)
#  verbose: :debug
}

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/concerto.yml')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  namespace :services do

    # start, stop, or restart the services if the service control script exists
    %w[start stop restart].each do |command|
      desc "#{command} concerto background services"
      task command.to_sym do
        on roles(:app) do 
          if test("[ -L /etc/init.d/concerto ]")
            as :root do
              execute "invoke-rc.d", "concerto", "#{command}"
            end
          end
        end
      end
    end

    desc "install concerto background services"
    task :setup do
      on roles(:app) do 
        # Must occur after code is deployed and symlink to current is created
        # If the service control script does not yet exist, but the script is in our app directory
        # then we link it (to create the service control script) and make sure it's executable
        # and not world-writable.  
        # Otherwise if the service control script already exists, then the script in the app directory
        # may have just been replaced, so make sure it's permissions are like we said.
        if !test("[ -L /etc/init.d/concerto ]") and test("[ -f #{current_path}/concerto-init.d ]")
          as :root do
            execute :ln, "-nfs", "#{current_path}/concerto-init.d", "/etc/init.d/concerto"
            execute :chmod, "+x", "#{current_path}/concerto-init.d"
            execute :chmod, "o-w", "#{current_path}/concerto-init.d" 
            execute "update-rc.d", "concerto", "defaults"
          end
        elsif test("[ -f #{current_path}/concerto-init.d ]")
          as :root do
            execute :chmod, "+x", "#{current_path}/concerto-init.d"
            execute :chmod, "o-w", "#{current_path}/concerto-init.d" 
          end
        end
      end
    end

    desc "set default directory for concerto background services"
    task :defaults do
      on roles(:app) do 
        if !test("[ -f /etc/default/concerto ]")
          as :root do
            # set the path for finding our app
            # set the user that the services will run as (vi su)
            execute :echo, "CONCERTODIR=#{current_path}", ">/etc/default/concerto"
            execute :echo, "USERNAME=#{fetch(:user)}", ">>/etc/default/concerto"
            execute :echo, "SUSHELL=/bin/bash", ">>/etc/default/concerto"
          end
        end
      end
    end

    desc "remove concerto background services"
    task :remove do
      on roles(:app) do 
        # if the service control script exists, then remove it and unschedule it
        if test("[ -L /etc/init.d/concerto ]")
          as :root do
            execute "unlink", "/etc/init.d/concerto"
            execute "update-rc.d", "concerto", "remove"
          end
        end
      end
    end
  end
end

before "deploy:services:remove", "deploy:services:stop"   # stop the service before we remove it
before "deploy:updating", "deploy:services:stop"      # stop the service before we update the code
after "deploy:restart", "deploy:services:setup"  # reinstall/reset perms on service after code changes
after "deploy:services:setup", "deploy:services:start"    # restart the service after its been set up
after "deploy:starting", "deploy:services:defaults" # set defaults for the service when we set up a new server
