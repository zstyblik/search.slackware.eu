#!/bin/sh
# 2010/Mar/01 @ Zdenek Styblik
# desc: this script prepares, or pre-parses, data prior adding 
# new Slackware version into DB.
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
### FUNCTIONS
. "${SELFDIR}/common-functions.sh"
### MAIN
ARG1=${1:-""}

if [ -z "${ARG1}" ]; then
	echo "Parameter is the name of Slackware version eg. slackware-13.0" 1>&2
	exit 1
fi

if ! printf "%s" "${ARG1}" | \
	grep -q -i -E -e '^slackware(64)?-(current|[0-9]+\.[0-9]+){1}$' ; then
	echo "Parameter doesn't look like Slackware version to me." 1>&2
	exit 1
fi

# CWD to appropriate directory and do stuff
if [ ! -d "${TMPDIR}" ]; then
	mkdir -p "${TMPDIR}" || exit 31
fi
cd ${TMPDIR} || exit 32
mkdir "${ARG1}" || true
cd "${ARG1}" || exit 33

if [ ! -d "${BATCHDIR}" ]; then
	mkdir -p "${BATCHDIR}" || exit 34
fi

SVER="${ARG1}"

rm -f ./FILELIST.TXT \
	./FILELIST.TXT.files \
	./FILELIST.TXT.md5 \
	./FILELIST.TXT.pkgs \
	./CHECKSUMS.md5 \
	./CHECKSUMS.md5.files \
	./CHECKSUMS.md5.pkgs

if ! wget -q "${LINK}/${SVER}/FILELIST.TXT" ; then
	echo "Download of FILELIST.TXT has failed." 1>&2
	exit 2
fi

if ! wget -q "${LINK}/${SVER}/CHECKSUMS.md5" ; then
	echo "Download of CHECKSUMS.md5 has failed." 1>&2
	exit 2
fi

if ! wget -q "${LINK}/${SVER}/ChangeLog.txt" ; then
	echo "Download of ChangeLog.txt has failed." 1>&2
	exit 2
fi

check_files "FILELIST.TXT CHECKSUMS.md5"

grep -E -e '(CHECKSUMS.md5|MANIFEST.bz2|PACKAGES.TXT)$' ./FILELIST.TXT | \
	grep -v '\./source/' > FILELIST.TXT.files

grep -E -e '\.(tgz|txz)$' ./FILELIST.TXT | \
	grep -v '\./source/' > FILELIST.TXT.pkgs

grep -e '\./FILELIST.TXT' ./CHECKSUMS.md5 | \
	grep -v -e '\./source/' > FILELIST.TXT.md5

grep -E -e '(CHECKSUMS.md5|MANIFEST.bz2|PACKAGES.TXT)$' ./CHECKSUMS.md5 | \
	grep -v -e '\./source/' > CHECKSUMS.md5.files

grep -E -e '\.(tgz|txz)$' ./CHECKSUMS.md5 | \
	grep -v -e '\./source/' > CHECKSUMS.md5.pkgs

check_files "FILELIST.TXT.files FILELIST.TXT.pkgs CHECKSUMS.md5.files CHECKSUMS.md5.pkgs"

FLISTMD51=$(md5sum ./FILELIST.TXT | awk '{print $1}')
FLISTMD52=$(cat ./FILELIST.TXT.md5 | awk '{print $1}')

if [ "${FLISTMD51}" != "${FLISTMD52}" ]; then
	echo "FILELIST.TXT md5sum mismatch :: ${FLISTMD51} X ${FLISTMD52}." 1>&2
	exit 2
fi

# awk: Scan columns for PACKAGES.TXT or MANIFEST.bz2; if found, print-out and
# terminate for given input(line)
for FILE in $(awk '{ split($0, arr, " "); { \
	for (i = NF; i > 0; i--) { \
		if (arr[i] !~ /^.\//) { continue; } \
		if (arr[i] !~ /PACKAGES.TXT$/ && arr[i] !~ /MANIFEST.bz2$/) { continue; } \
		print substr(arr[i], 3); i = 0; break; \
	} } }' FILELIST.TXT.files | sort | uniq); do
	TODIR=$(printf "%s" "${FILE}" | perl -p -e 's/(MANIFEST.bz2|PACKAGES.TXT)//g')
	if [ -n "${TODIR}" ]; then
		mkdir "${TODIR}" 2>/dev/null || true
	fi
	if ! wget -q "${LINK}/${SVER}/${FILE}" -O "${FILE}" ; then
		echo "Download of '${FILE}' has failed." 1>&2
		exit 2
	fi
done

PSTART=$(date)

# TODO - lsof here?
# actually, this file shouldn't exist at all!
rm -f "${BATCHDIR}/SQLBATCH-${SVER}"

if ! perl "${SCRIPTDIR}./db-slackver-add.pl" "${SVER}" ; then
	echo "Adding of new Slackware version has failed." 1>&2
	exit 2
fi

printf "[start---stop]: %s --- %s\n" "${PSTART}" "$(date)"

rm -f "${STORDIR}/db/${SVER}.sq3"

DATEFAIL=$(date '+%H-%M-%S')
if sqlite3 -init "${BATCHDIR}/SQLBATCH-${SVER}" \
	"${STORDIR}/db/${SVER}.sq3" '.q' | grep -q -e 'Error' ; then

	echo "Failed to create SQLite file for ${SVER}" 1>&2
	mv "${BATCHDIR}/SQLBATCH-${SVER}" \
		"${BATCHDIR}/SQLBATCH-${SVER}.${DATEFAIL}"
else
	if perl "${SCRIPTDIR}./db-files-count.pl" "${SVER}" ; then
		rm -f "${BATCHDIR}/SQLBATCH-${SVER}"
	else
		echo "Failed to sync files count for ${SVER}"
	fi # if perl db-files-count.pl
fi # if sqlite3

if ! [ -d "${STORDIR}/distdata/" ]; then
	mkdir "${STORDIR}/distdata"
fi

if ! [ -d "${STORDIR}/distdata/${SVER}/" ]; then
	if ! mkdir "${STORDIR}/distdata/${SVER}" ; then
		echo "Failed to create '${STORDIR}/distdata/${SVER}'. Terminating."
		exit 3
	fi
fi

if ! sh "${SCRIPTDIR}./changelog-convert.sh" "${SVER}" ; then
	echo "Failed to process ChangeLog.txt"
fi

# TODO ~ do no copy files ending with number!
mv -f ./FILELIST.TXT.* "${STORDIR}/distdata/${SVER}/"
mv -f ./CHECKSUMS.md5.* "${STORDIR}/distdata/${SVER}/"
mv -f ./ChangeLog.txt "${STORDIR}/distdata/${SVER}/"
cd "${TMPDIR}"
# TODO - cmd review
rm -Rf "./${SVER}/"

