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
	mkdir "${TMPDIR}";
fi

if [ ! -d "${TMPDIR}/changelogs/" ]; then
	mkdir "${TMPDIR}/changelogs"
fi

for SVER in $(perl ./shell/db-get-slackversions.pl); do
	mkdir "${TMPDIR}/${SVER}"
	cd "${TMPDIR}/${SVER}"
	wget -q "${LINK}/${SVER}/ChangeLog.txt" || \
		{
			echo "Failed to download ChangeLog.txt for '${SVER}'" 1>&2
			cd "${TMPDIR}"
			rm -f "${TMPDIR}/${SVER}/*"
			rmdir "${TMPDIR}"
		}
	sh "${SCRIPTDIR}/changelog-convert.sh" "${SVER}"
	cd "${TMPDIR}"
	rm -f "${TMPDIR}/${SVER}"
	rmdir "${TMPDIR}/${SVER}"
done

chown -R slacker "${TMPDIR}/"

