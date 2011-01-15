#!/bin/bash
# 2011/Jan/01 @ Zdenek Styblik
# Desc: start-up script for search.slackware.eu
# Desc: create directory structure in $TMPDIR
# Desc: download and re-create all ChangeLogs
set -e
set -u

CFG="/srv/httpd/search.slackware.eu/conf/config.sh"

if [ ! -e "${CFG}" ]; then
	echo "Config file '${CFG}' not found."
	exit 254;
fi

source "${CFG}"

cd /srv/httpd/search.slackware.eu/

if [ ! -d "${TMPDIR}" ]; then
	mkdir "${TMPDIR}" || true
fi

chown -R slacker "${TMPDIR}/"

if [ ! -d "${TMPDIR}/changelogs/" ]; then
	mkdir "${TMPDIR}/changelogs" || true
fi

NEWSDIR="${TMPDIR}/news/"
if [ ! -d "${NEWSDIR}" ]; then
	mkdir "${NEWSDIR}" || true
fi
touch "${NEWSDIR}/linuxsec-news.htm"
touch "${NEWSDIR}/slack-news.htm"
touch "${NEWSDIR}/slack-torrents.htm"

perl ./bin/linuxsec-get-news.pl || true
perl ./bin/slackware-get-security.pl || true
perl ./bin/slackware-get-torrents.pl || true

if [ ! -d "${BATCHDIR}" ]; then
	mkdir "${BATCHDIR}" || true
fi

for SVER in $(perl ./shell/db-get-slackversions.pl); do
	mkdir "${TMPDIR}/${SVER}" || true
	cd "${TMPDIR}/${SVER}"
	wget -q "${LINK}/${SVER}/ChangeLog.txt" || \
		{
			echo "Failed to download ChangeLog.txt for '${SVER}'" 1>&2
			cd "${TMPDIR}"
			rm -f "${TMPDIR}/${SVER}/*"
			rmdir "${TMPDIR}" || true
		}
	chown slacker:slacker -R "${TMPDIR}/${SVER}/ChangeLog.txt"
	su slacker -c "sh \"${SCRIPTDIR}/changelog-convert.sh\" \"${SVER}\""
	cd "${TMPDIR}"
	rm -Rf "${TMPDIR}/${SVER}"
done

chown -R slacker:slacker "${BATCHDIR}/"
