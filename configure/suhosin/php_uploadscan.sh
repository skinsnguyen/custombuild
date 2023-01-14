#!/bin/sh

# Make the script CageFS compatible
if [ -e ~/.cagefs$1 ]; then
		   USER_HOMEDIR=`echo ~`
	FILE=${USER_HOMEDIR}/.cagefs$1
else
	FILE=$1
fi

if [ -n "`/usr/local/bin/clamdscan --infected --no-summary ${FILE}`" ]; then
	echo 0;
else
	echo 1;
fi
exit 0;