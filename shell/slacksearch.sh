#!/bin/sh
# 2010/Nov/18 @ Zdenek Styblik
# 2010/Mar/26 @ Zdenek Styblik
#
# Copyright (c) 2011 Zdenek Styblik <zdenek.styblik@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
set -e
set -u
# default Slackware version 
SLACKVER=${SLACKVER:-'slackware64-current'}
SEARCHSITE=${SEARCHSITE:-'http://search.slackware.eu/cgi-bin/search-cli.cgi/find'}

# desc: just print some help non-sense
# @return: 0
print_help()
{
	echo "slacksearch.sh <haystack> <needle> [slackware version]" 1>&2
	echo "supported haystacks: file, package" 1>&2
	return 0
} # print_help

### MAIN ###
NOARGS=$#
ARG1=${1:-0}
ARG2=${2:-0}
ARG3=${3:-""}
# check whether we have CURL as it is not standard
CURL=$(which curl)
if [ -z "${CURL}" ]; then
	echo "CURL is required, yet not found in your PATH."
	exit 1
fi

if [ $NOARGS -lt 2 ]; then
	print_help
	exit 1
fi

if [ "${ARG1}" = "0" ] || [ "${ARG2}" = "0" ]; then
	print_help
	exit 2
fi

if [ "${ARG1}" != 'file' ] && [ "${ARG1}" != 'package' ]; then
	echo "Wrong haystack '${ARG1}'." 1>&2
	echo "Supported haystacks are: file, package" 1>&2
	exit 2
fi

if [ ! -z "${ARG3}" ]; then
	SLACKVER="${ARG3}"
fi

if ! printf "%s" "${SLACKVER}" | \
	grep -q -i -E -e '^slackware(64)?-(current|[0-9]+\.[0-9]+){1}$' ; then
	echo "Slackware version '${SLACKVER}' has strange format." 1>&2
	exit 3
fi

if ! printf "%s" "${ARG2}" | grep -q -i -E -e '^[A-Za-z0-9\.\-\_]+$' ; then
	echo "Package name '$2' is Gibberish to me." 1>&2
	exit 4
fi

curl -s "${SEARCHSITE}/${ARG1}/${SLACKVER}/${ARG2}" | column -t -s '|'

