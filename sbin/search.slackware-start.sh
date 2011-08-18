#!/bin/bash
# 2011/Jan/01 @ Zdenek Styblik
# Desc: start-up script for search.slackware.eu
# Desc: create directory structure in $TMPDIR
# Desc: download and re-create all ChangeLogs
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

CFG="/mnt/search.slackware.eu/conf/config.sh"

if [ ! -e "${CFG}" ]; then
	echo "Config file '${CFG}' not found."
	exit 254;
fi

source "${CFG}"

cd /mnt/search.slackware.eu/

rm -rf "${TMPDIR}"
mkdir "${TMPDIR}" || true
mkdir "${TMPDIR}/changelogs/" "${TMPDIR}/news/"
chown -R slacker "${TMPDIR}/"

touch "${TMPDIR}/news/linuxsec-news.htm"
touch "${TMPDIR}/news/slack-news.htm"
touch "${TMPDIR}/news/slack-torrents.htm"

perl ./bin/linuxsec-get-news.pl || true
perl ./bin/slackware-get-security.pl || true
perl ./bin/slackware-get-torrents.pl || true

if [ ! -d "${BATCHDIR}" ]; then
	mkdir "${BATCHDIR}" || true
fi
chown -R slacker:slacker "${BATCHDIR}"

for SVER in $(perl ./shell/db-get-slackversions.pl); do
	mkdir "${TMPDIR}/${SVER}" || true
	cd "${TMPDIR}/${SVER}"
	if wget -q "${LINK}/${SVER}/ChangeLog.txt" ; then
		chown slacker:slacker -R "${TMPDIR}/${SVER}/ChangeLog.txt"
		su slacker -c "sh \"${SCRIPTDIR}/changelog-convert.sh\" \"${SVER}\""
	else 
		echo "Failed to download ChangeLog.txt for '${SVER}'" 1>&2
	fi
	cd "${TMPDIR}"
	rm -Rf "${TMPDIR}/${SVER}"
done

