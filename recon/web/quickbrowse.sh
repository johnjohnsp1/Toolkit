#!/bin/bash
# enumerate lists of webservers quickly

# file containing servers
list=$1

if [ $# -eq 0 ]; then
	echo "[!] You forgot to specify an input file."
	exit 2
fi

# open new browser instance, and wait for it to complete
firefox && sleep 1

# open each server in a new tab in the new browser instance
for server in `cat $1`; do 
	firefox --new-tab $server
done

