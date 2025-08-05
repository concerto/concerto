Installing new ruby versions
1. make sure that rvm is installed.
    enter "rvm" on the console. If this isn't recognized, rvm needs to be reinstalled.
    An installation guide on rvm can be found here: https://rvm.io/rvm/install
    You should install RVM stable with ruby.
2. make sure that there is an openssl 
    to check if openssl is currently installed(if you have at least one ruby version currently installed), run:
    ruby -ropenssl -e "puts :OK".
    If it throws an error, then run:
    rvm pkg install openssl
3. Install desired version
    rvm install <ruby version here> --with openssl-dir=$rvm_path/usr
    if this fails, try running:
    rvm get head.
Note: currently, Concerto runs on ruby 2.6.0