Installing new ruby versions
1. make sure that rvm is installed.\
    enter "rvm" on the console. If rvm is installed, it will list several commands that can be used.\
    If it isn't recognized, an installation guide on rvm can be found here: https://rvm.io/rvm/install \
    You should install RVM stable with ruby.
3. make sure that there openssl is installed\
    to check if openssl is installed(if you have at least one ruby version installed), run:\
    ruby -ropenssl -e "puts :OK".\
   <img width="1325" height="60" alt="{FF405D7B-4777-45C4-8984-28E9D942FC9A}" src="https://github.com/user-attachments/assets/d7735526-fbfe-49de-881e-78ef3ff6da92" />

    If it throws an error, then run:\
    rvm pkg install openssl
4. Install desired version\
    rvm install <ruby version here> --with openssl-dir=$rvm_path/usr

    if this fails, try running:\
    rvm get head

Note: currently, Concerto runs on ruby 2.6.0

