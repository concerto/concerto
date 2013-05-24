#!/bin/bash

if [ ! -f compiler.jar ];  then
  echo -e 'compiler.jar not found.\nDownload it from http://closure-compiler.googlecode.com/files/compiler-latest.zip and drop it in this directory.'; exit 1;
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
