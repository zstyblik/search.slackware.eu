#!/bin/bash
# 2010/Dec/22 @ Zdenek Styblik
# Desc: replace dates with <b>$DATE</b> and terminators '+-...-+' 
# with '<hr />' in Slackware's ChangeLog.txt
set -e
set -u

CHANGELOG=${1:-''}

if [ -z "${CHANGELOG}" ]; then
	echo "$0 <ChangeLog.txt>"
	exit 1;
fi

if [ ! -e "${CHANGELOG}" ]; then
	echo "$0: Changelog '${CHANGELOG}' doesn't seem to exist."
	exit 2;
fi

sed -r -e \
	's#(^[A-Za-z]{3} [A-Za-z]{3} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [A-Z]{3,4} [0-9]{4}$)#<b>\1</b>#' \
	-e 's#^\+[-]+\+#<hr \/>#' \
	"${CHANGELOG}" > "${CHANGELOG}.htm" || exit 3

