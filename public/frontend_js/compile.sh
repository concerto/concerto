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
    echo -e 'compiler.jar not found.\nDownload it from http://closure-compiler.googlecode.com/files/compiler-latest.zip and drop it in this directory.'; exit 1;
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
  closure-library/closure/bin/build/closurebuilder.py \
    --root=closure-library/ --root=./ --namespace="concerto.frontend.Screen" \
    --output_mode=compiled --compiler_jar=compiler.jar \
    --compiler_flags="--externs=screen_options.js" \
    --compiler_flags="--compilation_level=ADVANCED_OPTIMIZATIONS" \
     > frontend.js

elif [ $debug -eq 1 ]; then
  closure-library/closure/bin/build/closurebuilder.py \
    --root=closure-library/ --root=./ --namespace="concerto.frontend.Screen" \
    --output_mode=compiled --compiler_jar=compiler.jar \
   > frontend_debug.js

else
  closure-library/closure/bin/build/closurebuilder.py \
    --root=closure-library/ --root=./ --namespace="concerto.frontend.Screen" \
    --output_mode=script --compiler_jar=compiler.jar \
   > frontend_superdebug.js
fi
