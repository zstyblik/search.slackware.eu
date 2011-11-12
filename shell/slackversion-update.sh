#!/bin/sh
# 2010/Mar/01 @ Zdenek Styblik
# desc: synchronize slackware version
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

dlFiles() {
	for FILE in $(cat "./${1}"); do
		printf "%s\n" "${FILE}"
		TODIR=$(printf "%s" "${FILE}" | sed 's/^\.\///' | \
			awk '{ print substr($1, 0, index($1, "/")) }')
		mkdir "${TODIR}" 2>/dev/null || true
		if ! wget -q "${LINK}/${SVER}/${FILE}" -O "${FILE}" ; then
			echo "Download of ${FILE} has failed." 1>&2
			exit 2
		fi
	done
	return 0
} # dlFiles()

### MAIN ###
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
cd "${TMPDIR}" || exit 32
rm -rf "${TMPDIR}/${ARG1}"
mkdir "${ARG1}" 2>/dev/null || true
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

if [ ! -d "${STORDIR}/distdata/${SVER}" ]; then
	echo "Dir '${STORDIR}/distdata/${SVER}/' doesn't exist."
	echo "Come again later when you fix it."
	exit 1
fi

if ! wget -q "${LINK}/${SVER}/CHECKSUMS.md5" ; then
	echo "Download of CHECKSUMS.md5 has failed." 1>&2
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


grep -e '\./FILELIST.TXT' ./CHECKSUMS.md5 | \
	grep -v -e '\./source/' > FILELIST.TXT.md5

grep -E -e '(CHECKSUMS.md5|MANIFEST.bz2|PACKAGES.TXT)$' ./CHECKSUMS.md5 | \
	grep -v -e '\./source/' > CHECKSUMS.md5.files

if [ -z './CHECKSUMS.md5.files' ]; then
	echo "CHECKSUMS.md5.files has zero lenght. I have nothing to do." 1>&2
	exit 2
fi


grep -E -e '\.(tgz|txz)$' ./CHECKSUMS.md5 | \
	grep -v -e '\./source/' > CHECKSUMS.md5.pkgs

if [ -z './CHECKSUMS.md5.pkgs' ]; then
	echo "CHECKSUMS.md5.pkgs has zero lenght. I have nothing to do." 1>&2
	exit 2
fi


### probably remove and let the script deal with it ?
### or do double check eg. CHECKSUMS.md5.files ?
if diff -b -B -N -q "${STORDIR}/distdata/${SVER}/CHECKSUMS.md5.pkgs" \
	CHECKSUMS.md5.pkgs > /dev/null ; then
	echo "No changes for version ${SVER} from the last update."
	exit 1
fi

if ! wget -q "${LINK}/${SVER}/ChangeLog.txt" ; then
	echo "Download of ChangeLog.txt has failed." 1>&2
	exit 2
fi

# TODO 
set +e
perl "${SCRIPTDIR}/file-comparator.pl" \
	"${STORDIR}/distdata/${SVER}/CHECKSUMS.md5.pkgs" CHECKSUMS.md5.pkgs
RCPKGS=$?

perl "${SCRIPTDIR}/file-comparator.pl" \
	"${STORDIR}/distdata/${SVER}/CHECKSUMS.md5.files" CHECKSUMS.md5.files
RCFILES=$?
set -e

if [ $RCPKGS -ne 0 ] || [ $RCFILES -ne 0 ]; then
	echo "Diff for PKGS or FILES failed. Unwilling to continue."
	exit 2
fi

### FILELIST.TXT
if ! wget -q "${LINK}/${SVER}/FILELIST.TXT" ; then
	echo "Download of FILELIST.TXT has failed." 1>&2
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


FLISTMD51=$(md5sum ./FILELIST.TXT | awk '{print $1}')
FLISTMD52=$(cat ./FILELIST.TXT.md5 | awk '{print $1}')

if [ "${FLISTMD51}" != "${FLISTMD52}" ]; then
	echo "FILELIST.TXT md5sum mismatch :: ${FLISTMD51} X ${FLISTMD52}." 1>&2
	exit 2
fi


grep -E -e '(CHECKSUMS.md5|MANIFEST.bz2|PACKAGES.TXT)$' ./FILELIST.TXT | \
	grep -v -e '\./source/' > FILELIST.TXT.files

if [ -z './FILELIST.TXT.files' ]; then
	echo "FILELIST.TXT.files has zero lenght. I have nothing to do." 1>&2
	exit 2
fi


grep -E -e '\.(tgz|txz)$' ./FILELIST.TXT | \
	grep -v -e '\./source/' > FILELIST.TXT.pkgs

if [ -z './FILELIST.TXT.pkgs' ]; then
	echo "FILELIST.TXT.pkg has zero lenght. I have nothing to do." 1>&2
	exit 2
fi

if [ -z './CHECKSUMS.md5.files.diff' ] \
	&& [ -z 'CHECKSUMS.md5.pkgs.diff']; then
	echo "There seem to be no differences for '${SVER}'" 1>&2
	echo "How the hell did we get here in the first place?!" 1>&2
	exit
fi

# clean-up in case these do exist
rm -f FILELIST.TXT.files.manifests
rm -f DOWNLOAD.files.manifests

for MANFILE in $(grep -e 'MANIFEST\.bz2' \
	./CHECKSUMS.md5.files.diff | awk '{ print $2 }'); do
	grep -e "${MANFILE}" FILELIST.TXT.files >> FILELIST.TXT.files.manifests && \
		echo "${MANFILE}" >> DOWNLOAD.files.manifests
done

dlFiles 'DOWNLOAD.files.manifests'

# TODO ~ more awk ?
grep -v -e '^D' CHECKSUMS.md5.files.diff | \
	grep -i -e 'PACKAGES.TXT' | \
	awk '{ print $2 }' > DOWNLOAD.files.desc

dlFiles 'DOWNLOAD.files.desc'

grep -i -e 'PACKAGES.TXT' FILELIST.TXT.files > FILELIST.TXT.files.desc

SLACKDIR=$(echo "${SVER}" | cut -d '-' -f 1)

# BUGFIX ~ ./${SLACKDIR}/PACKAGES.TXT do not exists, yet ...
for FIXIT in $(echo "./CHECKSUMS.md5.files.diff ./FILELIST.TXT.files \
	./FILELIST.TXT.files.desc ./CHECKSUMS.md5.files"); do
	sed -i -r -e "s# ./PACKAGES.TXT# ./${SLACKDIR}/PACKAGES.TXT#" "${FIXIT}"
done
cp -f PACKAGES.TXT "${SLACKDIR}/" 2>/dev/null || true
# BUGFIX

# TODO - lsof here?
rm -f "${BATCHDIR}/SQLBATCH-${SVER}"

perl "${SCRIPTDIR}./db-slackver-update.pl" "${ARG1}"

TVAR=$(lsof "${STORDIR}/db/${SVER}.sq3" | wc -l)
while [ ${TVAR} -ne 0 ]; do
	echo "going to sleep"
	sleep 5
	TVAR=$(lsof "${STORDIR}/db/${SVER}.sq3" | wc -l)
done

DATEFAIL=$(date '+%H-%M-%S')
if sqlite3 -init "${BATCHDIR}/SQLBATCH-${SVER}" \
	"${STORDIR}/db/${SVER}.sq3" '.q' | grep -q -e 'Error' ; then

	echo "Updating SQLite files DB has failed for ${SVER}." 1>&2
	mv "${BATCHDIR}/SQLBATCH-${SVER}" \
	"${BATCHDIR}/SQLBATCH-${SVER}.${DATEFAIL}"
else
	if perl "${SCRIPTDIR}./db-files-count.pl" "${SVER}" ; then
		rm -f "${BATCHDIR}/SQLBATCH-${SVER}"
	else
		echo "Updating files count has failed for ${SVER}" 1>&2
		mv "${BATCHDIR}/SQLBATCH-${SVER}" \
			"${BATCHDIR}/SQLBATCH-${SVER}.${DATEFAIL}"
	fi # if perl db-files-count.pl
fi # if sqlite3

sh "${SCRIPTDIR}./changelog-convert.sh" "${SVER}"

# check for inconsistencies
## package's descriptions
perl "${SCRIPTDIR}./db-slackver-check-integrity.pl" "${SVER}" 'desc' || \
	perl "${SCRIPTDIR}./db-fix-pkgs-desc.pl" "${SVER}"
## packages' MD5s
perl "${SCRIPTDIR}./db-slackver-check-integrity.pl" "${SVER}" 'md5' || \
	perl "${SCRIPTDIR}./db-fix-pkgs-md5.pl" "${SVER}"
## package's files
#perl "${SCRIPTDIR}./db-slackver-check-integrity.pl "${SVER} files" || \
#	perl "${SCRIPTDIR}./db-fix-pkgs-files.pl "${SVER}"

cp ./CHECKSUMS.md5.pkgs.diff \
	"${STORDIR}/distdata/${SVER}/CHECKSUMS.md5.pkgs.diff.$(date '+%Y-%m-%d_%H-%M-%S')"
cp ./CHECKSUMS.md5.files.diff \
	"${STORDIR}/distdata/${SVER}/CHECKSUMS.md5.files.diff.$(date '+%Y-%m-%d_%H-%M-%S')"
# TODO - don't move files ending with number
mv -f ./FILELIST.TXT.* "${STORDIR}/distdata/${SVER}/"
mv -f ./CHECKSUMS.md5.* "${STORDIR}/distdata/${SVER}/"
mv -f ./ChangeLog.txt "${STORDIR}/distdata/${SVER}/"
cd ${TMPDIR}
# TODO - cmd review
rm -Rf "./${SVER}/"

