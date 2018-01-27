#!/bin/bash -e

# This if matchs the following:
# if $1 (argv[0]) is unset (ie it's null)
# or anything begining with a - (etc -hello or -test)
if [[ -z $1 ]] || [[ ${1:0:1} == '-' ]] ; then
  exec  /app/hello "$@"
else

# If we have been called with a variable that doesn't start with a - then assume it's a progrom and run it
# This is handy for container debugging
  exec "$@"
fi
