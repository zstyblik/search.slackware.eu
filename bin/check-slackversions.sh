#!/bin/sh
# 2011/Jan/01 @ Zdenek Styblik
# Desc: check for new version of Slackware and add it
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

. "${CFG}"

SVERSLIST=$(mktemp -p "${TMPDIR}")

if ! wget -q "${LINK}/" -O "${SVERSLIST}"; then
	echo "Unable to download list of Slackware versions."
	rm -f "${SVERSLIST}"
	exit 1
fi

for SVER in $(grep -e '<a href=' "${SVERSLIST}" | tr -s ' ' | \
	cut -d '>' -f 2- | cut -d '<' -f 1 | sed -e 's#\/##' | \
	grep -v -E -e '(-iso|unsupported|_source)'); do
	if [ "${SVER}"="slackware-3.3" ] || \
		[ "${SVER}"="slackware-7.1" ] || \
		[ "${SVER}"="slackware" ]; then
		continue
	fi
	perl "${SCRIPTDIR}/db-check-slackversion.pl" "${SVER}" && \
		sh "${SCRIPTDIR}/slackversion-add.sh" "${SVER}" || continue
done

rm -f "${SVERSLIST}"

