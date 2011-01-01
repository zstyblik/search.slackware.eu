#!/bin/bash
# 2010/Dec/22 @ Zdenek Styblik
# Desc: replace dates with <b>$DATE</b> and terminators '+-...-+' 
# with '<hr />' in Slackware's ChangeLog.txt
set -e
set -u

CFG="/srv/httpd/search.slackware.eu/conf/config.sh"

if [ ! -e "${CFG}" ]; then
	echo "Config file '${CFG}' not found."
	exit 254;
fi

source "${CFG}"

ARG1=${1:-''}

if [ -z "${ARG1}" ]; then
	echo "$0 <Slackware_version>"
	exit 1;
fi

echo "${ARG1}" | \
grep -q -i -E '^slackware(64)?-(current|[0-9]+\.[0-9]+){1}$' || \
{
	echo "Parameter doesn't look like Slackware version to me." \
	1>&2
	exit 1;
}

CHANGELOGTXT="${TMPDIR}/${ARG1}/ChangeLog.txt"
CHANGELOGDIR="${TMPDIR}/changelogs/"

if [ ! -d "${CHANGELOGDIR}" ]; then
	mkdir "${CHANGELOGDIR}";
fi

if [ ! -e "${CHANGELOGTXT}" ]; then
	echo "$0: ChangeLog '${CHANGELOGTXT}' doesn't seem to exist."
	exit 2;
fi

if [ ! -d "${CHANGELOGDIR}/${ARG1}" ]; then
	mkdir "${CHANGELOGDIR}/${ARG1}";
fi

CHANGELOGTMP="${CHANGELOGDIR}/${ARG1}/ChangeLog.tmp"

#sed -r -e \
#	's#(^[A-Za-z]{3}[\ ]+[A-Za-z]{3}[\ ]+[0-9]{1,2}[\ ]+[0-9]{2}:[0-9]{2}:[0-9]{2}[\ ]+[A-Z]{3,4}[\ ]+[0-9]{4}$)#<h5>\1</h5><pre>#' \
#	-e 's#^\+[-]+\+#<\/pre><hr \/>#' -e 's#^[-]+$#<\/pre><hr \/>#' \
#	"${CHANGELOGTXT}" > "${CHANGELOGTMP}" || exit 3

perl "/srv/httpd/search.slackware.eu/shell/changelog-preptemplate.pl" "${ARG1}"

sed -r -e "#REPLACEME#r ${CHANGELOGTMP}" -e 's/REPLACEME//g' \
"${CHANGELOGDIR}/${ARG1}/ChangeLog.htm.new" > \
"${CHANGELOGDIR}/${ARG1}/ChangeLog.htm"

rm -f "${CHANGELOGDIR}/${ARG1}/ChangeLog.tmp"

