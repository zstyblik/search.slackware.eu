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

if [ ! -e "${CFG}" ]; then
	echo "Config file '${CFG}' not found."
	exit 254
fi

. "${CFG}"

ARG1=${1:-""}

if [ -z "${ARG1}" ]; then
	echo "Parameter is the name of Slackware version eg. slackware-13.0" 1>&2
	exit 1
fi

if ! echo "${ARG1}" | \
	grep -q -i -E -e '^slackware(64)?-(current|[0-9]+\.[0-9]+){1}$' ; then
	echo "Parameter doesn't look like Slackware version to me." 1>&2
	exit 1
fi

if [ $(id -u) -eq 0 ]; then
	echo "Refusing to run as a root!"
	echo "You are going to break it!!!"
	exit 2
fi

# CWD to appropriate directory and do stuff
if [ ! -d "${TMPDIR}" ]; then
	mkdir "${TMPDIR}" || exit 31
fi
cd ${TMPDIR} || exit 32
mkdir "${ARG1}" || true
cd "${ARG1}" || exit 33

if [ ! -d "${BATCHDIR}" ]; then
	mkdir "${BATCHDIR}" || exit 34
fi

SVER="${ARG1}"

rm -f ./FILELIST.TXT
rm -f ./FILELIST.TXT.files
rm -f ./FILELIST.TXT.md5
rm -f ./FILELIST.TXT.pkgs
rm -f ./CHECKSUMS.md5
rm -f ./CHECKSUMS.md5.files
rm -f ./CHECKSUMS.md5.pkgs

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

if [ ! -e './FILELIST.TXT' ]; then
	echo "FILELIST.TXT doesn't exist." 1>&2
	exit 2
fi
if [ -z './FILELIST.TXT' ]; then
	echo "FILELIST.TXT has zero lenght." 1>&2
	exit 2
fi

if [ ! -e './CHECKSUMS.md5' ]; then
	echo "CHECKSUMS.md5 doesn't exist." 1>&2
	exit 2
fi
if [ -z './CHECKSUMS.md5' ]; then
	echo "CHECKSUMS.md5 has zero lenght." 1>&2
	exit 2
fi

grep -E -e '(CHECKSUMS.md5|MANIFEST.bz2|PACKAGES.TXT)$' ./FILELIST.TXT | \
	grep -v '\./source/' > FILELIST.TXT.files

grep -E -e '\.(tgz|txz)$' ./FILELIST.TXT | \
	grep -v '\./source/' > FILELIST.TXT.pkgs

if [ -z './FILELIST.TXT.files' ]; then
	echo "FILELIST.TXT.files has zero lenght. I have nothing to do." 1>&2
	exit 2
fi
if [ -z './FILELIST.TXT.pkgs' ]; then
	echo "FILELIST.TXT.pkg has zero lenght. I have nothing to do." 1>&2
	exit 2
fi

grep -e '\./FILELIST.TXT' ./CHECKSUMS.md5 | \
	grep -v -e '\./source/' > FILELIST.TXT.md5

grep -E -e '(CHECKSUMS.md5|MANIFEST.bz2|PACKAGES.TXT)$' ./CHECKSUMS.md5 | \
	grep -v -e '\./source/' > CHECKSUMS.md5.files

grep -E -e '\.(tgz|txz)$' ./CHECKSUMS.md5 | \
	grep -v -e '\./source/' > CHECKSUMS.md5.pkgs

if [ -z './CHECKSUMS.md5.files' ]; then
	echo "CHECKSUMS.md5.files has zero lenght. I have nothing to do." 1>&2
	exit 2
fi
if [ -z './CHECKSUMS.md5.pkgs' ]; then
	echo "CHECKSUMS.md5.pkgs has zero lenght. I have nothing to do." 1>&2
	exit 2
fi

FLISTMD51=$(md5sum ./FILELIST.TXT | awk '{print $1}')
FLISTMD52=$(cat ./FILELIST.TXT.md5 | awk '{print $1}')

if [ "${FLISTMD51}" != "${FLISTMD52}" ]; then
	echo "FILELIST.TXT md5sum mismatch :: ${FLISTMD51} X ${FLISTMD52}." 1>&2
	exit 2
fi

# TODO ~ rewrite it into one % awk;
for FILE in $(awk '{ print $8 }' FILELIST.TXT.files | \
	awk '{ print substr($1, 3) }' | \
	grep -E -e '\/(PACKAGES.TXT|MANIFEST.bz2)$'); do
	TODIR=$(printf "%s" "${FILE}" | perl -p -e 's/(MANIFEST.bz2|PACKAGES.TXT)//g')
	mkdir "${TODIR}" || true
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

printf "[start---stop]: %s --- %s\n" ${PSTART} $(date)

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

