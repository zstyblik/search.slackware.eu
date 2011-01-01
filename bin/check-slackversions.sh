#!/bin/bash
# 2011/Jan/01 @ Zdenek Styblik
# Desc: check for new version of Slackware and add it
set -e
set -u

CFG="/srv/httpd/search.slackware.eu/conf/config.sh"

if [ ! -e "${CFG}" ]; then
	echo "Config file '${CFG}' not found."
	exit 254;
fi

source "${CFG}"

SVERSLIST=$(mktemp -p "${TMPDIR}")

wget -q "${LINK}/" -O "${SVERSLIST}" || \
	{
		echo "Unable to download list of Slackware versions.";
		rm -f "${SVERSLIST}";
		exit 1;
	}

for SVER in $(grep -e '<a href=' "${SVERSLIST}" | tr -s ' ' | \
	cut -d '>' -f 2- | cut -d '<' -f 1 | sed -e 's#\/##' | \
	grep -v -E -e '(-iso|unsupported|_source)'); do
	perl "${SCRIPTDIR}/db-check-slackversion.pl" "${SVER}" && \
		sh "${SCRIPTDIR}/slackversion-add.sh" "${SVER}" || continue;
done

rm -f "${SVERSLIST}"

