#!/bin/bash
# This script will kill process which running more than X hours
# egrep: the selected process; grep: hours

while true; do

PIDS="`ps eaxo bsdtime,pid,comm | egrep "php" | grep " 1:" | awk '{print $2}'`"

# Kill the process
for i in ${PIDS}; do { echo "Killing $i"; kill -9 $i; }; done;


PIDS="`ps eaxo bsdtime,pid,comm | egrep "php" | grep " 0:30" | awk '{print $2}'`"

# Kill the process
for i in ${PIDS}; do { echo "Killing $i"; kill -9 $i; }; done;


sleep 1;

done;
