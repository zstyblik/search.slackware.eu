#!/bin/bash
# 2010/Dec/22 @ Zdenek Styblik
# Desc: prepare directories in case they don't exist, call templater, 
# and process templates
set -e
set -u

CFG="/mnt/search.slackware.eu/conf/config.sh"

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

if [ $(id -u) -eq 0 ]; then
	echo "Refusing to run as a root!"
	echo "You are going to break it!!!"
	exit 2;
fi

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

perl "/mnt/search.slackware.eu/shell/changelog-preptemplate.pl" "${ARG1}"

sed -r -e "/REPLACEME/r ${CHANGELOGTMP}" \
	-e 's/REPLACEME//g' \
	-e '/^$/d' \
	"${CHANGELOGDIR}/${ARG1}/ChangeLog.tmpl" > \
	"${CHANGELOGDIR}/${ARG1}/ChangeLog.htm.new" || exit 4

rm -f "${CHANGELOGDIR}/${ARG1}/ChangeLog.tmp"
rm -f "${CHANGELOGDIR}/${ARG1}/ChangeLog.tmpl"
mv "${CHANGELOGDIR}/${ARG1}/ChangeLog.htm.new" \
	"${CHANGELOGDIR}/${ARG1}/ChangeLog.htm"
cp "${CHANGELOGTXT}" "${CHANGELOGDIR}/${ARG1}/"

