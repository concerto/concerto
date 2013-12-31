#!/bin/bash

# check for closure library and if not found get it via git submodule
if [ ! "$(ls -A closure-library/)" ]; then
  cd ../..
  git submodule init
  git submodule update
  cd public/frontend_js
fi

# check for closure compiler and if not found try to download it
if [ ! -f compiler.jar ];  then
  # try to download it automatically
  curl -O http://dl.google.com/closure-compiler/compiler-latest.zip && unzip -qq compiler-latest.zip compiler.jar && rm compiler-latest.zip
  if [ ! -f compiler.jar ];  then
    echo -e 'compiler.jar not found.\nDownload it from http://dl.google.com/closure-compiler/compiler-latest.zip and drop it in this directory.'; exit 1;
  fi
fi

debug=0
while [ $# -gt 0 ]
do
  case "$1" in
    --debug ) 
      debug=1 ;;
    --superdebug )
      debug=2 ;;
  esac
  shift
done

echo $debug

if [[ ! -x "closure-library/closure/bin/build/closurebuilder.py" ]]
then
  chmod a+x closure-library/closure/bin/build/closurebuilder.py
fi

if [ $debug -eq 0 ]; then
  if [ -f frontend.js ]; then
    rm frontend.js
  fi
  closure-library/closure/bin/build/closurebuilder.py \
    --root=closure-library/ --root=./ --namespace="concerto.frontend.Screen" \
    --output_mode=compiled --compiler_jar=compiler.jar \
    --compiler_flags="--externs=screen_options.js" \
    --compiler_flags="--compilation_level=ADVANCED_OPTIMIZATIONS" \
   > frontend.js
  if [ ! -s frontend.js ]; then
    echo -e '\nfrontend.js was NOT produced!\n'
  fi

elif [ $debug -eq 1 ]; then
  if [ -f frontend_debug.js ]; then
    rm frontend_debug.js
  fi
  closure-library/closure/bin/build/closurebuilder.py \
    --root=closure-library/ --root=./ --namespace="concerto.frontend.Screen" \
    --output_mode=compiled --compiler_jar=compiler.jar \
   > frontend_debug.js
  if [ ! -s frontend_debug.js ]; then
    echo -e '\nfrontend_debug.js was NOT produced!\n'
  fi

else
  if [ -f frontend_superdebug.js ]; then
    rm frontend_superdebug.js
  fi
  closure-library/closure/bin/build/closurebuilder.py \
    --root=closure-library/ --root=./ --namespace="concerto.frontend.Screen" \
    --output_mode=script --compiler_jar=compiler.jar \
   > frontend_superdebug.js
  if [ ! -s frontend_superdebug.js ]; then
    echo -e '\nfrontend_superdebug.js was NOT produced!\n'
  fi
fi
