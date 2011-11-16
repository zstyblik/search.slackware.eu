#!/bin/sh
# 2011/Nov/16 @ Zdenek Styblik
# Desc: script for refreshing ChangeLog files.
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

if [ $(id -u) -eq 0 ]; then
	echo "Refusing to run as a root!"
	echo "You are going to break it!!!"
	exit 2
fi

if [ ! -e "${CFG}" ]; then
	echo "Config file '${CFG}' not found."
	exit 254
fi
### CONFIG
. "${CFG}"
### MAIN
for SVER in $(perl "${SCRIPTDIR}./db-get-slackversions.pl"); do
	# CWD to appropriate directory and do stuff
	if [ ! -d "${TMPDIR}/${SVER}" ]; then
		mkdir -p "${TMPDIR}/${SVER}" || exit 31
	fi
	cd "${TMPDIR}/${SVER}" || exit 32

	if ! wget -q "${LINK}/${SVER}/ChangeLog.txt" ; then
		printf "Download of ChangeLog.txt for %s has failed.\n" "${SVER}" 1>&2
		continue
	fi
	sh "${SCRIPTDIR}./changelog-convert.sh" "${SVER}"
	rm -f ChangeLog.txt
done
# EOF
