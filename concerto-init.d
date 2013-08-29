#! /bin/sh
### BEGIN INIT INFO
# Provides:          concerto
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: initscript for concerto background services
# Description:       This file should be placed in /etc/init.d and added to system startup with update-rc.d concerto defaults
### END INIT INFO

#CONCERTO USERS: SET THESE DEFAULTS ACCORDING TO YOUR SYSTEM CONFIGURATION
USERNAME=www-data
CONCERTODIR=/usr/share/concerto
RAILS_ENVIRONMENT=production

# PATH should only include /usr/* if it runs after the mountnfs.sh script
PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="concerto background services"
DAEMON_DESC="$DESC daemon"  # clockwork
WORKER_DESC="$DESC worker"  # jobs:work
NAME=concerto
DAEMON=$NAME
PIDDIR=/var/run/$NAME
SCRIPTNAME=/etc/init.d/$NAME


# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME

# Load the VERBOSE setting and other rcS variables
[ -r /lib/init/vars.sh ] && . /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.2-14) to ensure that this file is present
# and status_of_proc is working.
[ -r /lib/lsb/init-functions ] && . /lib/lsb/init-functions

# Exit if clockwork (concerto) is not installed (package removed)
if [ ! -x ${CONCERTODIR}/vendor/bundle/ruby/*/gems/clockwork-*/bin/clockwork ]; then
  echo "$NAME does not appear to be installed"
  exit 0
fi

#
# Function that starts the daemon/service
#
do_start()
{
  mkdir -p $PIDDIR
  mkdir -p /var/log/concerto
  chown $USERNAME: /var/log/concerto
  # START APPLICATION: concerto
  
    # START PROCESS: clock
    
      # START CONCURRENT: 1
        # Start: concerto.clock.1
        # Create $PIDDIR/clock.1.pid
        # dont start if already running
        status_of_proc -p "$PIDDIR/clock.1.pid" "$DAEMON" "$DAEMON_DESC" 2>&1 >/dev/null
        RUNNING=$?
        if [ $RUNNING -eq 0 ]; then
          log_daemon_msg "$DAEMON_DESC already running"
        else
          su - $USERNAME -c "cd $CONCERTODIR; export PORT=5000; RAILS_ENV=$RAILS_ENVIRONMENT bundle exec clockwork lib/cron.rb >> /var/log/concerto/clock-1.log 2>&1 & echo \$!" > $PIDDIR/clock.1.pid
        fi
    
  
    # START PROCESS: worker
    
      # START CONCURRENT: 1
        # Start: concerto.worker.1
        # Create $PIDDIR/worker.1.pid
        status_of_proc -p "$PIDDIR/worker.1.pid" "$DAEMON" "$WORKER_DESC" 2>&1 >/dev/null
        RUNNING=$?
        if [ $RUNNING -eq 0 ]; then
          log_daemon_msg "$WORKER_DESC already running"
        else
          su - $USERNAME -c "cd $CONCERTODIR; export PORT=5100; RAILS_ENV=$RAILS_ENVIRONMENT bundle exec rake jobs:work >> /var/log/concerto/worker-1.log 2>&1 & echo \$!" > $PIDDIR/worker.1.pid
        fi

}

#
# Function that stops the daemon/service
#
do_stop()
{
  # STOP APPLICATION: concerto
  
    # STOP PROCESS: clock
    
      # STOP CONCURRENT: 1
        # Stop: concerto.clock.1
        if [ -f $PIDDIR/clock.1.pid ]; then
          kill `cat $PIDDIR/clock.1.pid` 2>&1 >/dev/null
          rm $PIDDIR/clock.1.pid
        fi

    # STOP PROCESS: worker
    
      # STOP CONCURRENT: 1
        # Stop: concerto.worker.1
        if [ -f $PIDDIR/worker.1.pid ]; then
          kill `cat $PIDDIR/worker.1.pid` 2>&1 >/dev/null
          rm $PIDDIR/worker.1.pid
        fi

  [ -d $PIDDIR ] && rmdir $PIDDIR
}

case "$1" in
  start)
    [ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC" "$NAME"
    do_start
    case "$?" in
      0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
      2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
    esac
    ;;
  stop)
    [ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME"
    do_stop
    case "$?" in
      0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
      2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
    esac
    ;;
  status)
    status_of_proc -p "$PIDDIR/clock.1.pid" "$DAEMON" "$DAEMON_DESC"
    RET=$?
    if [ $RET -eq 0 ]; then
      status_of_proc -p "$PIDDIR/worker.1.pid" "$DAEMON" "$WORKER_DESC"
      RET=$?
    fi
    [ $RET -eq 0 ] && exit 0 || exit $?
    ;;
  #reload|force-reload)
  #
  # If do_reload() is not implemented then leave this commented out
  # and leave 'force-reload' as an alias for 'restart'.
  #
  #log_daemon_msg "Reloading $DESC" "$NAME"
  #do_reload
  #log_end_msg $?
  #;;
  restart|force-reload)
    #
    # If the "reload" option is implemented then remove the
    # 'force-reload' alias
    #
    log_daemon_msg "Restarting $DESC" "$NAME"
    do_stop
    case "$?" in
      0|1)
      do_start
      case "$?" in
        0) log_end_msg 0 ;;
        1) log_end_msg 1 ;; # Old process is still running
        *) log_end_msg 1 ;; # Failed to start
      esac
      ;;
      *)
        # Failed to stop
      log_end_msg 1
      ;;
    esac
    ;;
    *)
    #echo "Usage: $SCRIPTNAME {start|stop|restart|reload|force-reload}" >&2
    echo "Usage: $SCRIPTNAME {start|stop|status|restart|force-reload}" >&2
    exit 3
    ;;
esac

