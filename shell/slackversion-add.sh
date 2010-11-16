#!/bin/bash
# 2010/Mar/01 @ Zdenek Styblik
# desc: this script prepares, or pre-parses, data prior adding 
# new Slackware version into DB.

LINK='ftp://ftp.sh.cvut.cz/storage/1/slackware'
#LINK='ftp://10.117.5.4/'
STORDIR='/home/search.slackware.eu/'
TMPDIR='/mnt/tmp/search.slack/'
BATCHDIR='/tmp/search.slack/'
SCRIPTDIR='/home/search.slackware.eu/shell/'

if [ -z $1 ]; then
	echo "Parameter is the name of Slackware version eg. slackware-13.0" \
	1>&2
	exit 1
fi

echo "${1}" | \
grep -q -i -E '^slackware(64)?-(current|[0-9]+\.[0-9]+){1}$'
if [ $? != 0 ]; then
	echo "Parameter doesn't look like Slackware version to me." \
	1>&2
	exit 1;
fi

# CWD to appropriate directory and do stuff
cd ${TMPDIR} || exit 32
mkdir ${1}
cd ${1} || exit 33

if ! [ -d $BATCHDIR ]; then
	mkdir $BATCHDIR || exit 34;
fi

SVER=${1}

rm -f ./FILELIST.TXT
rm -f ./FILELIST.TXT.files
rm -f ./FILELIST.TXT.md5
rm -f ./FILELIST.TXT.pkgs
rm -f ./CHECKSUMS.md5
rm -f ./CHECKSUMS.md5.files
rm -f ./CHECKSUMS.md5.pkgs

wget -q ${LINK}/${SVER}/FILELIST.TXT
if [ $? != 0 ]; then
	echo "Download of FILELIST.TXT has failed." \
	1>&2
	exit 2
fi
wget -q ${LINK}/${SVER}/CHECKSUMS.md5
if [ $? != 0 ]; then
	echo "Download of CHECKSUMS.md5 has failed." \
	1>&2
	exit 2
fi

if [ ! -e './FILELIST.TXT' ]; then
	echo "FILELIST.TXT doesn't exist." \
	1>&2
	exit 2
fi
if [ -z './FILELIST.TXT' ]; then
	echo "FILELIST.TXT has zero lenght." \
	1>&2
	exit 2
fi

if [ ! -e './CHECKSUMS.md5' ]; then
	echo "CHECKSUMS.md5 doesn't exist." \
	1>&2
	exit 2
fi
if [ -z './CHECKSUMS.md5' ]; then
	echo "CHECKSUMS.md5 has zero lenght." \
	1>&2
	exit 2
fi

cat ./FILELIST.TXT \
| grep -E '(CHECKSUMS.md5|MANIFEST.bz2|PACKAGES.TXT)$' | \
 grep -v '\./source/' > FILELIST.TXT.files
cat ./FILELIST.TXT | grep -E '\.(tgz|txz)$' | grep -v '\./source/' \
> FILELIST.TXT.pkgs

if [ -z './FILELIST.TXT.files' ]; then
	echo "FILELIST.TXT.files has zero lenght. I have nothing to do." \
	1>&2
	exit 2
fi
if [ -z './FILELIST.TXT.pkgs' ]; then
	echo "FILELIST.TXT.pkg has zero lenght. I have nothing to do." \
	1>&2
	exit 2
fi

cat ./CHECKSUMS.md5 | grep '\./FILELIST.TXT' | grep -v '\./source/' \
> FILELIST.TXT.md5

cat ./CHECKSUMS.md5 \
| grep -E '(CHECKSUMS.md5|MANIFEST.bz2|PACKAGES.TXT)$' | \
grep -v '\./source/' > CHECKSUMS.md5.files

cat ./CHECKSUMS.md5 | grep -E '\.(tgz|txz)$' | \
grep -v '\./source/' > CHECKSUMS.md5.pkgs

if [ -z './CHECKSUMS.md5.files' ]; then
	echo "CHECKSUMS.md5.files has zero lenght. I have nothing to do." \
	1>&2
	exit 2
fi
if [ -z './CHECKSUMS.md5.pkgs' ]; then
	echo "CHECKSUMS.md5.pkgs has zero lenght. I have nothing to do." \
	1>&2
	exit 2
fi

FLISTMD51=`md5sum ./FILELIST.TXT | awk '{print $1}'`
FLISTMD52=`cat ./FILELIST.TXT.md5 | awk '{print $1}'`

if [ $FLISTMD51 != $FLISTMD52 ]; then
	echo "FILELIST.TXT md5sum mismatch :: $FLISTMD51 X $FLISTMD52." \
	1>&2
	exit 2;
fi

for FILE in `cat FILELIST.TXT.files | awk '{ print $8 '} | \
	awk '{ print substr($1, 3) }' | \
	grep -E '\/(PACKAGES.TXT|MANIFEST.bz2)$'`; do
	TODIR=`echo "${FILE}" | \
	perl -p -e 's/(MANIFEST.bz2|PACKAGES.TXT)//g'`;
	mkdir ${TODIR}
	wget -q ${LINK}/${SVER}/${FILE} -O ${FILE}
	if [ $? != 0 ]; then
		echo "Download of ${FILE} has failed." 1>&2
		exit 2
	fi
done

PSTART=`date`

# ToDo - lsof here?
# actually, this file shouldn't exist at all!
rm -f "${BATCHDIR}/SQLBATCH-${SVER}"

perl ${SCRIPTDIR}./db-slackver-add.pl ${SVER}

if [ $? != 0 ]; then
	echo "Adding of new Slackware version has failed." 1>&2
	exit 2;
fi

echo "[start---stop]: ${PSTART} ---`date`"

rm -f ${STORDIR}/db/${SVER}.sq3

sqlite3 -init "${BATCHDIR}/SQLBATCH-${SVER}" \
${STORDIR}/db/${SVER}.sq3 '.q' | grep -q 'Error'

# ToDo - add $? check here
if [ $? -eq 0 ]; then
	echo "Failed to create SQLite file for ${SVER}" 1>&2
	mv ${BATCHDIR}/SQLBATCH-${SVER} \
	${BATCHDIR}/SQLBATCH-${SVER}.`date '+%H-%M-%S'`
else 
	perl ${SCRIPTDIR}./db-files-count.pl ${SVER}
	if [ $? == 0 ]; then
		rm -f "${BATCHDIR}/SQLBATCH-${SVER}"
	else
		echo "Failed to sync files count for ${SVER}"
	fi
fi

if ! [ -d ${STORDIR}/distdata/ ]; then
	mkdir ${STORDIR}/distdata
fi

mkdir ${STORDIR}/distdata/${SVER}

if [ $? -ne 0 ]; then
	echo "Failed to create '${STORDIR}/distdata/${SVER}'. Terminating."
	exit 3;
fi

mv ./FILELIST.TXT* ${STORDIR}/distdata/${SVER}/
mv ./CHECKSUMS.md5* ${STORDIR}/distdata/${SVER}/
cd ${TMPDIR}
rm -Rf ./${SVER}/

exit 0

