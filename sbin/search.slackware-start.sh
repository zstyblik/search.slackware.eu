#!/bin/bash
# 2011/Jan/01 @ Zdenek Styblik
# Desc: start-up script for search.slackware.eu
# Desc: create directory structure in $TMPDIR
# Desc: download and re-create all ChangeLogs
set -e
set -u

CFG="/mnt/search.slackware.eu/conf/config.sh"

if [ ! -e "${CFG}" ]; then
	echo "Config file '${CFG}' not found."
	exit 254;
fi

source "${CFG}"

cd /mnt/search.slackware.eu/

if [ ! -d "${TMPDIR}" ]; then
	mkdir "${TMPDIR}" || true
fi

rm -rf "${TMPDIR}"
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

