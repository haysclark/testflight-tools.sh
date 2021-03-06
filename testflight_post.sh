#!/bin/bash
#
# Post to TestFlight 1.1, 2013
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of 
# this software and associated documentation files (the "Software"), to deal in 
# the Software without restriction, including without limitation the rights to 
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
# of the Software, and to permit persons to whom the Software is furnished to do 
# so, subject to the following conditions:
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
# Official TestFLight API Docs - https://testflightapp.com/api/doc/#
# testflight-tools written by Hays Clark <hays@infinitedescent.com> with no offiliation with TestFlight
# 
# Latest version can be found at https://github.com/haysclark/testflight-tools
# Tested on OSX (10.9)
# 
# Copyright (c) 2013 Hays Clark
#

# Requirements of TestFlight, set via flags or hardcode 
UPLOAD_TOKEN=""
TEAM_TOKEN=""
FILE="" 
NOTES="" 

# Options of TestFlight, set via flags or hardcode 
DSYM_PATH=""
DIST_LISTS=""
NOTIFY=0
REPLACE=0

# testflight_post options
CMD_PATH="curl"
TESTFLIGHT_URL="http://testflightapp.com/api/builds.json"

# vars
NAME=`basename "$0"`
VERSION=1.1
DRY_RUN=0
AUTO_OPEN=0
MSG=""
EXPECTED_FLAGS="[-h] [-v] [-d] [-a] [-n] [-c custCurl] [-w custUrl] [-u uploadToken] [-t teamToken] [-z dSYMfile] [datafile] [notes]"

PRINT_VERSION(){
	echo ${NAME} version ${VERSION}
}

PRINT_HELP(){
	echo "Usage: ${NAME} ${EXPECTED_FLAGS}"
	echo
	echo "Options"
	echo " -v            	   show version"
	echo " -d            	   dry run, only show curl command"
	echo " -a            	   auto-open TestFlight"
	echo " -n            	   enable notify"
	echo " -c            	   override curl command"
	echo " -w            	   override TestFlight www url"
	echo " -u            	   set upload API token"
	echo " -t            	   set team API token"
	echo " -z            	   set path of dSYM zip file"
	echo "(-h)           	   show this help"
}

RUN_CMD() {
	eval ${MSG}
	if [ $? != 0 ]; then
		exit 1
	fi

	echo
	echo "Uploaded to TestFlight"

	if [ "${AUTO_OPEN}" = 1 ]; then
		open "https://testflightapp.com/dashboard/builds/"
	fi
	exit 0
}

while getopts "vdanc:w:u:t:z:h" VALUE "${@}" ; do
	if [ "${VALUE}" = "h" ] ; then
		PRINT_HELP
		exit 0
	fi
	if [ "${VALUE}" = "v" ] ; then
		PRINT_VERSION
	fi
	if [ "${VALUE}" = "d" ] ; then
		DRY_RUN=1
	fi
	if [ "${VALUE}" = "a" ] ; then
		AUTO_OPEN=1
	fi
	if [ "${VALUE}" = "n" ] ; then
		NOTIFY=1
	fi
	if [ "${VALUE}" = "c" ] ; then
		CMD_PATH="${OPTARG}"
	fi
	if [ "${VALUE}" = "w" ] ; then
		TESTFLIGHT_URL="${OPTARG}"
	fi
	if [ "${VALUE}" = "u" ] ; then
		UPLOAD_TOKEN="${OPTARG}"
	fi
	if [ "${VALUE}" = "t" ] ; then
		TEAM_TOKEN="${OPTARG}"
	fi
	if [ "${VALUE}" = "z" ] ; then
		DSYM_PATH="${OPTARG}"
	fi
	if [ "${VALUE}" = ":" ] ; then
        echo "Flag -${OPTARG} requires an argument."
        echo "Usage: $0 ${EXPECTED_FLAGS}"
        exit 1
    fi
	if [ "${VALUE}" = "?" ] ; then
		echo "Unknown flag -${OPTARG} detected."
		echo "Usage: $0 ${EXPECTED_FLAGS}"
		exit 1
	fi
done

shift `expr ${OPTIND} - 1`

if [ "$#" -gt 2 ]; then
  echo "Too many arguments."
  echo "Usage: $0 ${EXPECTED_FLAGS}"
  exit 1
fi

if [ "$#" -eq 2 ]; then
	if ! [ -f "$1" ]; then
		echo "$1 is not a path to the IPA"
		echo "Usage: $0 ${EXPECTED_FLAGS}"
		exit 1
	fi
	FILE="$1"
	NOTES="$2"
fi

if [ "$#" -eq 1 ]; then
	if [ -f "$1" ]; then
		FILE="$1"
	else
		NOTES="$1"		
	fi
fi

if [ "${FILE}" = "" ]; then
	echo "file path is required and must be supplied or set in the script"
	echo "Usage: $0 ${EXPECTED_FLAGS}"
	exit 1
fi

if ! [ -f "${FILE}" ]; then
	echo ${FILE}" is not a valid filepath."
	echo "Usage: $0 ${EXPECTED_FLAGS}"
	exit 1
fi

if [ "${NOTES}" = "" ]; then
	echo "release notes are required and must be supplied or set in the script"
	echo "Usage: $0 ${EXPECTED_FLAGS}"
	exit 1
fi

if [ "${UPLOAD_TOKEN}" = "" ]; then
	echo "api_token is not supplied and is file path is required"
	echo "Usage: $0 ${EXPECTED_FLAGS}"
	exit 1
fi

if [ "${TEAM_TOKEN}" = "" ]; then
echo "team_token is not supplied and is file path is required"
	echo "Usage: $0 ${EXPECTED_FLAGS}"
	exit 1
fi

MSG="${CMD_PATH}"
MSG+=" ${TESTFLIGHT_URL}"
MSG+=" -F file=@${FILE}"

if ! [ "${DSYM_PATH}" = "" ]; then
	if ! [ -f "${DSYM_PATH}" ]; then
		echo ${DSYM_PATH}" is not a valid filepath."
		echo "Usage: $0 ${EXPECTED_FLAGS}"
		exit 1
	fi
	MSG+=" -F dsym=@${DSYM_PATH}"
fi

MSG+=" -F api_token=${UPLOAD_TOKEN}"
MSG+=" -F team_token=${TEAM_TOKEN}"
MSG+=" -F notes='${NOTES}'"

if [ "${NOTIFY}" = 1 ]; then
	MSG+=" -F notify=True"
fi

if ! [ "${DIST_LISTS}" = "" ]; then
	MSG+=" -F distribution_lists=${DIST_LISTS}"
fi

if [ "${DRY_RUN}" = 1 ] ; then
	echo "${MSG}"
	exit 0
fi

RUN_CMD
