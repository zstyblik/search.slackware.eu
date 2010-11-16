#!/bin/bash
cd /home/search.slackware.eu/
for SVER in `perl /home/search.slackware.eu/shell/db-get-slackversions.pl`; do
	bash /home/search.slackware.eu/shell/slackversion-update.sh $SVER;
done
