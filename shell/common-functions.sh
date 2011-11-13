#!/bin/sh
# 2011/Nov/13 @ Zdenek Styblik
# desc: common shell script functions
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
download_files() {
	for FILE in $(cat "./${1}"); do
		printf "Downloading: %s\n" "${FILE}"
		TODIR=$(printf "%s" "${FILE}" | sed 's/^\.\///' | \
			awk '{ print substr($1, 0, index($1, "/")) }')
		mkdir "${TODIR}" 2>/dev/null || true
		if ! wget -q "${LINK}/${SVER}/${FILE}" -O "${FILE}" ; then
			echo "Download of '${FILE}' has failed." 1>&2
			exit 2
		fi
	done
	return 0
} # download_files()
check_files() {
	FILES=${1:-""}
	if [ -z "${FILES}" ]; then
		return 1
	fi
	for CHECKFILE in "${FILES}"; do
		if [ ! -e "${CHECKFILE}" ]; then
			echo "File '${CHECKFILE}' doesn't exist." 1>&2
			exit 2
		fi
		if [ -z "${CHECKFILE}" ]; then
			echo "'File '${CHECKFILE}' has zero lenght." 1>&2
			exit 2
		fi
	done # for CHECKFILE
	return 0
} # check_files()
### EOF
