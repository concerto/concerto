#!/bin/bash
# check for closure library and if not found get it via git submodule
if [ ! "$(ls -A closure-library/)" ]; then
  cd ../..
  git submodule init
  git submodule update
  cd public/frontend_js
fi

# make sure the script we need is executable before we call it
if [[ ! -x "closure-library/closure/bin/calcdeps.py" ]]
then
  chmod a+x closure-library/closure/bin/calcdeps.py
fi

closure-library/closure/bin/calcdeps.py -i screen.js  -p closure-library/ -p . -o deps > deps.js
