#!/bin/sh
# 2010/Dec/08 @ Zdenek Styblik
# Desc: Unified? config for all scripts

# Mirror to check-out for updates etc.
LINK='ftp://ftp.sh.cvut.cz/storage/1/slackware'
# Where to store dist data etc.
STORDIR='/mnt/search.slackware.eu/'
# Temporary dir ~ tmpfs/ramfs
TMPDIR='/mnt/tmp/search.slack/'
# SQLite batches ~ these are quite large -> no tmpfs/ramfs
BATCHDIR='/tmp/search.slack/'
# Where are scripts at
SCRIPTDIR="${STORDIR}/shell/"

