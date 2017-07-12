#!/bin/bash
# n0vo | @n0vothedreamer
# a script which gets the IP blocks belonging to an organization

# this is required for the script to work
ASNDB=../data/GeoIPASNum2.csv
whoisrv=whois.radb.net

# make sure an argument was specified
if [ $# -eq 0 ]; then
	echo "Usage: $0 <organization_name>"
	echo "  Example: $0 twitter"
	exit 1
fi

# find the ASNs related to the argument specified
ASNS=`cat $ASNDB |grep -i $1 |sed 's/"//g' |cut -d, -f3 |sort -u`

# so you actually know which organization the IP blocks belong to
echo $ASNS |awk '{ first = $1; $1 = ""; print $0; }'
echo "----------------"

# for each ASN string...
for ASN in $ASNS; do 
	# look up the corresponding IP blocks
	for block in `echo $ASN |
		# grep the ASN number
		egrep '^AS[0-9]{1,6}'`; do
		# whois lookup the AS number's corresponding IP blocks
		whois -h $whoisrv -- "-i origin $block" |grep route: |awk '{ print $2 }'
	done
done

