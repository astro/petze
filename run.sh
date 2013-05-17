#!/bin/sh

COFFEE=`dirname $0`/node_modules/.bin/coffee
if [ ! -x "$COFFEE" ]
then
    npm i coffee-script || exit 1
fi

$COFFEE main.coffee

EXIT=$?
sleep 1
exit $EXIT
