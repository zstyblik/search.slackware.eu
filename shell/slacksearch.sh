#!/bin/bash
# 2010/Mar/26 @ Zdenek Styblik
SLACKVER='slackware64-current'
SEARCHSITE='http://search.slackware.eu/cgi-bin/search-cli.cgi/find'

if [ $# -lt 2 ]; then
	echo "slacksearch.sh <haystack> <needle> [slackware version]" 1>&2
	echo "supported haystacks: file, package" 1>&2
	exit 1;
fi

if [ $1 != 'file' ] && [ $1 != 'package' ]; then
	echo "Wrong haystack '$1'." 1>&2
	echo "Supported haystacks are: file, package" 1>&2
	exit 2;
fi

if [ $3 ]; then
	SLACKVER=$3;
fi

echo ${SLACKVER} | \
grep -q -i -E '^slackware(64)?-(current|[0-9]+\.[0-9]+){1}$'
if [ $? != 0 ]; then
	echo "Slackware version '${SLACKVER}' has strange format." 1>&2
	exit 3;
fi

echo $2 | grep -q -i -E '^[A-Za-z0-9\.\-\_]+$'
if [ $? != 0 ]; then
	echo "Package name '$2' is Gibberish to me." 1>&2
	exit 4;
fi

# Just to make sure, because // != /
LINK=`echo "" | \
sed -r 's/\/+/\//g'`

curl -s "${SEARCHSITE}/${1}/${SLACKVER}/${2}" | column -t -s '|'

