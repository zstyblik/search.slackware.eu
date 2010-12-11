#!/bin/bash
# 2010/Mar/01 @ Zdenek Styblik
# desc: synchronize slackware version
set -e
set -u

CFG="/srv/httpd/search.slackware.eu/conf/config.sh"

if [ ! -e "${CFG}" ]; then
	echo "Config file '${CFG}' not found."
	exit 254;
fi

source "${CFG}"

# TODO ~ Clean up!!!
#LINK='ftp://ftp.sh.cvut.cz/storage/1/slackware'
#LINK='ftp://10.117.5.4/'
#STORDIR='/home/search.slackware.eu/'
#TMPDIR='/mnt/tmp/search.slack/'
#BATCHDIR='/tmp/search.slack/'
#SCRIPTDIR='/home/search.slackware.eu/shell/'

function dlFiles() {
	for FILE in $(cat ./$1); do
		echo "${FILE}";
		TODIR=$(echo "${FILE}" | sed 's/^\.\///' | \
		awk '{ print substr($1, 0, index($1, "/")) }')
		mkdir "${TODIR}" 2>/dev/null || true
		wget -q "${LINK}/${SVER}/${FILE}" -O "${FILE}" || \
		{
			echo "Download of ${FILE} has failed." 1>&2
			exit 2;
		}
	done
	return 0;
}

### MAIN ###
ARG1=${1:-""}

if [ -z "${ARG1}" ]; then
	echo "Parameter is the name of Slackware version eg. slackware-13.0" \
	1>&2
	exit 1;
fi

echo "${ARG1}" | \
grep -q -i -E '^slackware(64)?-(current|[0-9]+\.[0-9]+){1}$' || \
{
	echo "Parameter doesn't look like Slackware version to me." 1>&2
	exit 1;
}

# CWD to appropriate directory and do stuff
if ! [ -d "${TMPDIR}" ]; then
	mkdir "${TMPDIR}" || exit 31;
fi
cd ${TMPDIR} || exit 32
mkdir "${ARG1}" 2>/dev/null
cd "${ARG1}" || exit 33

if ! [ -d "${BATCHDIR}" ]; then
	mkdir "${BATCHDIR}" || exit 34;
fi

SVER="${ARG1}"

rm -f ./FILELIST.TXT
rm -f ./FILELIST.TXT.files
rm -f ./FILELIST.TXT.md5
rm -f ./FILELIST.TXT.pkgs
rm -f ./CHECKSUMS.md5
rm -f ./CHECKSUMS.md5.files
rm -f ./CHECKSUMS.md5.pkgs

if ! [ -d "${STORDIR}/distdata/${SVER}" ]; then
	echo "Dir '${STORDIR}/distdata/${SVER}/' doesn't exist. Come again \
	later when you fix it."
	exit 1;
fi

wget -q "${LINK}/${SVER}/CHECKSUMS.md5" || \
{
	echo "Download of CHECKSUMS.md5 has failed." 1>&2
	exit 2;
}

if ! [ -e './CHECKSUMS.md5' ]; then
	echo "CHECKSUMS.md5 doesn't exist." 1>&2
	exit 2;
fi

if [ -z './CHECKSUMS.md5' ]; then
	echo "CHECKSUMS.md5 has zero lenght." 1>&2
	exit 2;
fi


cat ./CHECKSUMS.md5 | grep '\./FILELIST.TXT' | grep -v '\./source/' \
> FILELIST.TXT.md5

cat ./CHECKSUMS.md5 \
| grep -E '(CHECKSUMS.md5|MANIFEST.bz2|PACKAGES.TXT)$' | \
grep -v '\./source/' > CHECKSUMS.md5.files

if [ -z './CHECKSUMS.md5.files' ]; then
	echo "CHECKSUMS.md5.files has zero lenght. I have nothing to do." \
	1>&2
	exit 2
fi


cat ./CHECKSUMS.md5 | grep -E '\.(tgz|txz)$' | \
grep -v '\./source/' > CHECKSUMS.md5.pkgs

if [ -z './CHECKSUMS.md5.pkgs' ]; then
	echo "CHECKSUMS.md5.pkgs has zero lenght. I have nothing to do." \
	1>&2
	exit 2
fi


### probably remove and let the script deal with it ?
### or do double check eg. CHECKSUMS.md5.files ?
diff -b -B -N -q ${STORDIR}/distdata/${SVER}/CHECKSUMS.md5.pkgs \
CHECKSUMS.md5.pkgs > /dev/null || \
{
	echo "No changes for version ${SVER} from the last update."
	exit 1;
}

# TODO 
set +e
perl ${SCRIPTDIR}/file-comparator.pl \
${STORDIR}/distdata/${SVER}/CHECKSUMS.md5.pkgs CHECKSUMS.md5.pkgs
RCPKGS=$?

perl ${SCRIPTDIR}/file-comparator.pl \
${STORDIR}/distdata/${SVER}/CHECKSUMS.md5.files CHECKSUMS.md5.files
RCFILES=$?
set -e

if [ $RCPKGS -ne 0 ] || [ $RCFILES -ne 0 ]; then
	echo "Diff for PKGS or FILES failed. Unwilling to continue."
	exit 2;
fi

### FILELIST.TXT
wget -q "${LINK}/${SVER}/FILELIST.TXT" || \
{
	echo "Download of FILELIST.TXT has failed." 1>&2
	exit 2;
}

if [ ! -e './FILELIST.TXT' ]; then
	echo "FILELIST.TXT doesn't exist." 1>&2
	exit 2;
fi

if [ -z './FILELIST.TXT' ]; then
	echo "FILELIST.TXT has zero lenght." 1>&2
	exit 2;
fi


FLISTMD51=$(md5sum ./FILELIST.TXT | awk '{print $1}')
FLISTMD52=$(cat ./FILELIST.TXT.md5 | awk '{print $1}')

if [ "${FLISTMD51}" != "${FLISTMD52}" ]; then
	echo "FILELIST.TXT md5sum mismatch :: ${FLISTMD51} X ${FLISTMD52}." \
	1>&2
	exit 2;
fi


cat ./FILELIST.TXT \
| grep -E '(CHECKSUMS.md5|MANIFEST.bz2|PACKAGES.TXT)$' | \
grep -v '\./source/' > FILELIST.TXT.files

if [ -z './FILELIST.TXT.files' ]; then
	echo "FILELIST.TXT.files has zero lenght. I have nothing to do." \
	1>&2
	exit 2
fi


cat ./FILELIST.TXT | grep -E '\.(tgz|txz)$' | grep -v '\./source/' \
> FILELIST.TXT.pkgs

if [ -z './FILELIST.TXT.pkgs' ]; then
	echo "FILELIST.TXT.pkg has zero lenght. I have nothing to do." \
	1>&2
	exit 2;
fi


grep '^M' CHECKSUMS.md5.files.diff | grep -i -q 'MANIFEST\.bz2'

rm -f FILELIST.TXT.files.manifests
rm -f DOWNLOAD.files.manifests

# TODO - does it ($?) makes sense? NO! :-D
#if [ $? == 0 ]; then

for MANFILE in $(grep -e 'MANIFEST\.bz2' \
	./CHECKSUMS.md5.files.diff | awk '{ print $2 }'); do
	grep -e ${MANFILE} FILELIST.TXT.files >> \
	FILELIST.TXT.files.manifests

	echo "${MANFILE}" >> DOWNLOAD.files.manifests;
done

dlFiles 'DOWNLOAD.files.manifests'
#fi

cat CHECKSUMS.md5.files.diff | grep -i 'PACKAGES.TXT' | \
awk '{ print $2 }' > DOWNLOAD.files.desc

dlFiles 'DOWNLOAD.files.desc'

cat FILELIST.TXT.files | \
grep -i 'PACKAGES.TXT'  > FILELIST.TXT.files.desc

# TODO - lsof here?
rm -f "${BATCHDIR}/SQLBATCH-${SVER}"

perl ${SCRIPTDIR}./db-slackver-update.pl "${ARG1}"

TVAR=$(lsof ${STORDIR}/db/${SVER}.sq3 | wc -l)
while [ ${TVAR} -ne 0 ]; do
	echo "going to sleep"
	sleep 5
	TVAR=$(lsof ${STORDIR}/db/${SVER}.sq3 | wc -l);
done

DATEFAIL=$(date '+%H-%M-%S')
sqlite3 -init "${BATCHDIR}/SQLBATCH-${SVER}" \
"${STORDIR}/db/${SVER}.sq3" '.q' | grep -q 'Error' && \
{
	echo "Updating SQLite files DB has failed for ${SVER}." 1>&2
	mv "${BATCHDIR}/SQLBATCH-${SVER}" \
	"${BATCHDIR}/SQLBATCH-${SVER}.${DATEFAIL}"
} || \
{
	perl ${SCRIPTDIR}./db-files-count.pl "${SVER}" && \
	rm -f "${BATCHDIR}/SQLBATCH-${SVER}" || \
	{
		echo "Updating files count has failed for ${SVER}" 1>&2
		mv "${BATCHDIR}/SQLBATCH-${SVER}" \
		"${BATCHDIR}/SQLBATCH-${SVER}.${DATEFAIL}"
	}
}

# TODO - don't move files ending with number
mv ./FILELIST.TXT.* "${STORDIR}/distdata/${SVER}/"
mv ./CHECKSUMS.md5.* "${STORDIR}/distdata/${SVER}/"
cd ${TMPDIR}
# TODO - cmd review
rm -Rf ./${SVER}/

exit 0

