#!/bin/bash

if [ ! -f compiler.jar ];  then
  echo -e 'compiler.jar not found.\nDownload it from http://closure-compiler.googlecode.com/files/compiler-latest.zip and drop it in this directory.'; exit 1;
fi

closure-library/closure/bin/build/closurebuilder.py --root=closure-library/ --root=./ --namespace="concerto.frontend.Screen" --output_mode=compiled --compiler_jar=compiler.jar --compiler_flags="--compilation_level=ADVANCED_OPTIMIZATIONS" > compiled.js
