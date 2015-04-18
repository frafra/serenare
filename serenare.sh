#!/bin/bash
#
# Fedora 21:
#   # yum install qt5-qt{declarative-devel,quickcontrols,websockets} --enablerepo=updates-testing

#PATH=$HOME/websocketd/:$PATH # Set custom path if necessary
COMMAND="seren -n $(whoami) -N" # -N should be not removed

# --devconsole if you want an HTTP interface
websocketd --port=8100 --passenv HOME,XDG_RUNTIME_DIR sh -c "exec $COMMAND 2>&1" &

pid=$!
qmlscene serenare.qml
kill $pid

# In order to close Serenare, please don't use [CTRL]+[C]:
#   some processes will continue to run
