#!/bin/bash
# 2010/Nov/18 @ Zdenek Styblik
# 2010/Mar/26 @ Zdenek Styblik
# 
set -e
set -u
# default Slackware version 
SLACKVER=${SLACKVER:-'slackware64-current'}
SEARCHSITE=${SEARCHSITE:-'http://search.slackware.eu/cgi-bin/search-cli.cgi/find'}

# desc: just print some help non-sense
# @return: 0
function help()
{
	echo "slacksearch.sh <haystack> <needle> [slackware version]" 1>&2
	echo "supported haystacks: file, package" 1>&2
	return 0;
}

NOARGS=$#
ARG1=${1:-0}
ARG2=${2:-0}
ARG3=${3:-""}

if [ $NOARGS -lt 2 ]; then
	help
	exit 1;
fi

if [ "${ARG1}" == "0" ] || [ "${ARG2}" == "0" ]; then
	help
	exit 2;
fi

if [ "${ARG1}" != 'file' ] && [ "${ARG1}" != 'package' ]; then
	echo "Wrong haystack '${ARG1}'." 1>&2
	echo "Supported haystacks are: file, package" 1>&2
	exit 2;
fi

if [ ! -z "${ARG3}" ]; then
	SLACKVER="${ARG3}";
fi

echo "${SLACKVER}" | \
grep -q -i -E '^slackware(64)?-(current|[0-9]+\.[0-9]+){1}$' || \
{
	echo "Slackware version '${SLACKVER}' has strange format." 1>&2
	exit 3;
}

echo "${ARG2}" | grep -q -i -E '^[A-Za-z0-9\.\-\_]+$' || \
{
	echo "Package name '$2' is Gibberish to me." 1>&2
	exit 4;
}

# Just to make sure, because // != /
LINK=$(echo "" | sed -r 's/\/+/\//g')

curl -s "${SEARCHSITE}/${ARG1}/${SLACKVER}/${ARG2}" | column -t -s '|'

