#!/bin/bash

type -P gjslint &>/dev/null || { echo -e 'gjslint not found.\nSee https://developers.google.com/closure/utilities/docs/linter_howto.'; exit 1; }

gjslint --strict -r .
