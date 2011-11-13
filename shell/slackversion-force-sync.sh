#!/bin/sh
# 2010/Mar/01 @ Zdenek Styblik
# desc: enforce synchronization of slackversion
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

# OVERRIDE TMPDIR not to colide with regular sync
TMPDIR='/tmp/slacktest/'

# CWD to appropriate directory and do stuff
if ! [ -d "${TMPDIR}" ]; then
	mkdir -p "${TMPDIR}" || exit 31
fi
cd "${TMPDIR}" || exit 32
rm -rf "${TMPDIR}/${ARG1}"
mkdir "${ARG1}" 2>/dev/null || true
cd "${ARG1}" || exit 33

if ! [ -d "${BATCHDIR}" ]; then
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

if ! [ -d "${STORDIR}/distdata/${SVER}" ]; then
	echo "Dir '${STORDIR}/distdata/${SVER}/' doesn't exist."
	echo "Come again later when you fix it."
	exit 1
fi

if ! wget -q "${LINK}/${SVER}/CHECKSUMS.md5" ; then
	echo "Download of CHECKSUMS.md5 has failed." 1>&2
	exit 2
fi

check_files "./CHECKSUMS.md5"

grep -e '\./FILELIST.TXT' ./CHECKSUMS.md5 | \
	grep -v -e '\./source/' > FILELIST.TXT.md5

grep -E -e '(CHECKSUMS.md5|MANIFEST.bz2|PACKAGES.TXT)$' ./CHECKSUMS.md5 | \
	grep -v -e '\./source/' > CHECKSUMS.md5.files

grep -E -e '\.(tgz|txz)$' ./CHECKSUMS.md5 | \
	grep -v -e '\./source/' > CHECKSUMS.md5.pkgs

check_files "./CHECKSUMS.md5.files ./CHECKSUMS.md5.pkgs"

### FILELIST.TXT
if ! wget -q "${LINK}/${SVER}/FILELIST.TXT" ; then
	echo "Download of FILELIST.TXT has failed." 1>&2
	exit 2
fi

check_files "./FILELIST.TXT"

FLISTMD51=$(md5sum ./FILELIST.TXT | awk '{print $1}')
FLISTMD52=$(cat ./FILELIST.TXT.md5 | awk '{print $1}')

if [ "${FLISTMD51}" != "${FLISTMD52}" ]; then
	echo "FILELIST.TXT md5sum mismatch :: ${FLISTMD51} X ${FLISTMD52}." 1>&2
	exit 2
fi

grep -E -e '(CHECKSUMS.md5|MANIFEST.bz2|PACKAGES.TXT)$' ./FILELIST.TXT | \
	grep -v -e '\./source/' > FILELIST.TXT.files

grep -E -e '\.(tgz|txz)$' ./FILELIST.TXT | \
	grep -v -e '\./source/' > FILELIST.TXT.pkgs

check_files "./FILELIST.TXT.files ./FILELIST.TXT.pkgs"

# clean-up in case these do exist
rm -f FILELIST.TXT.files.manifests DOWNLOAD.files.manifests

for MANFILE in $(awk '{ if ( $0 ~ /MANIFEST.bz2/ ) { print $2; } }' \
	./CHECKSUMS.md5.files); do
	grep -e "${MANFILE}" FILELIST.TXT.files >> FILELIST.TXT.files.manifests
	printf "%s\n" "${MANFILE}" >> DOWNLOAD.files.manifests
done

download_files 'DOWNLOAD.files.manifests'

awk '{ if ( $0 ~ /PACKAGES.TXT/ { print $2; } }' \
	CHECKSUMS.md5.files > DOWNLOAD.files.desc

download_files 'DOWNLOAD.files.desc'

mv PACKAGES.TXT $(printf "%s" "${SVER}" | cut -d '-' -f 1)

grep -i -e 'PACKAGES.TXT' FILELIST.TXT.files > FILELIST.TXT.files.desc

# FIX Pkgs description
perl "${SCRIPTDIR}/db-fix-pkgs-desc.pl" "${SVER}"
# FIX Pkgs MD5 sums
perl "${SCRIPTDIR}/db-fix-pkgs-md5.pl" "${SVER}"
# FIX Pkgs files
#perl "${SCRIPTDIR}/db-fix-pkgs-files.pl" "${SVER}"

#diff -b -B -N -q "${STORDIR}/distdata/${SVER}/ChangeLog.txt" \
#	./ChangeLog.txt && sh "${SCRIPTDIR}./changelog-convert.sh" "${SVER}"

mv -f ./FILELIST.TXT.* "${STORDIR}/distdata/${SVER}/"
mv -f ./CHECKSUMS.md5.* "${STORDIR}/distdata/${SVER}/"
mv -f ./ChangeLog.txt "${STORDIR}/distdata/${SVER}/"

cd ${TMPDIR}
rm -Rf "./${SVER}/"

