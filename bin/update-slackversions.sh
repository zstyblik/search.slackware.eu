#!/bin/bash
# 2011/Jan/01 @ Zdenek Styblik
# Desc: update all Slackware versions stored in DB
set -e
set -u

cd /srv/httpd/search.slackware.eu/
for SVER in $(perl ./shell/db-get-slackversions.pl); do
	sh ./shell/slackversion-update.sh "${SVER}" || true
done
