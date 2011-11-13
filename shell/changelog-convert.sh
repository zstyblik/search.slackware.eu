#!/bin/sh
# 2010/Dec/22 @ Zdenek Styblik
# Desc: prepare directories in case they don't exist, call templater, 
# and process templates
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

SELFDIR=$(dirname "${0}")

CFG=${CFG:-"${SELFDIR}/../conf/config.sh"}

if [ ! -e "${CFG}" ]; then
	echo "Config file '${CFG}' not found."
	exit 254
fi

if [ $(id -u) -eq 0 ]; then
	echo "Refusing to run as a root!"
	echo "You are going to break it!!!"
	exit 2
fi

. "${CFG}"

### MAIN
ARG1=${1:-''}

if [ -z "${ARG1}" ]; then
	echo "$0 <Slackware_version>"
	exit 1
fi

if ! printf "%s" "${ARG1}" | \
	grep -q -i -E -e '^slackware(64)?-(current|[0-9]+\.[0-9]+){1}$'; then
	echo "Parameter doesn't look like Slackware version to me." 1>&2
	exit 1
fi

CHANGELOGTXT="${TMPDIR}/${ARG1}/ChangeLog.txt"
CHANGELOGDIR="${TMPDIR}/changelogs/"

if [ ! -d "${CHANGELOGDIR}" ]; then
	mkdir "${CHANGELOGDIR}"
fi

if [ ! -e "${CHANGELOGTXT}" ]; then
	printf "%s: ChangeLog '%s' doesn't seem to exist." ${0} ${CHANGELOGTXT}
	exit 2
fi

if [ ! -d "${CHANGELOGDIR}/${ARG1}" ]; then
	mkdir "${CHANGELOGDIR}/${ARG1}"
fi

CHANGELOGTMP="${CHANGELOGDIR}/${ARG1}/ChangeLog.tmp"

perl "${SCRIPTDIR}/changelog-preptemplate.pl" "${ARG1}"

sed -r -e "/REPLACEME/r ${CHANGELOGTMP}" \
	-e 's/REPLACEME//g' \
	-e '/^$/d' \
	"${CHANGELOGDIR}/${ARG1}/ChangeLog.tmpl" > \
	"${CHANGELOGDIR}/${ARG1}/ChangeLog.htm.new" || exit 4

rm -f "${CHANGELOGDIR}/${ARG1}/ChangeLog.tmp" \
	"${CHANGELOGDIR}/${ARG1}/ChangeLog.tmpl"
mv "${CHANGELOGDIR}/${ARG1}/ChangeLog.htm.new" \
	"${CHANGELOGDIR}/${ARG1}/ChangeLog.htm"
cp "${CHANGELOGTXT}" "${CHANGELOGDIR}/${ARG1}/"

