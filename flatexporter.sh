#!/bin/bash

#######################################
#  .d888888        888                                          888
# d88P" 888        888                                          888
# 888   888        888                                          888
# 888888888 8888b. 888888 .d88b. 888  88888888b.  .d88b. 888d888888888 .d88b. 888d888
# 888   888    "88b888   d8P  Y8b`Y8bd8P'888 "88bd88""88b888P"  888   d8P  Y8b888P"
# 888   888.d888888888   88888888  X88K  888  888888  888888    888   88888888888
# 888   888888  888Y88b. Y8b.    .d8""8b.888 d88PY88..88P888    Y88b. Y8b.    888
# 888   888"Y888888 "Y888 "Y8888 888  88888888P"  "Y88P" 888     "Y888 "Y8888 888
#                                        888
#                                        888
#                                        888
#
# Exports the contents of a flatex depot as csv.
#
# Requires curl and jq or gpg. If jq is not found in the path, it will be downloaded to /tmp.
# Gpg is required to verify the signature of the downloaded file. It's only needed if jq isn't already installed.
#
# Usage: ./flatexporter.sh username password
#
# Version: 1.1
#
# Author: Andreas Hartmann
# https://github.com/Yugen42/flatexporter
#######################################

# Download jq if it's not in the path.
jqpath=$(which jq)
if ! [ -x "$jqpath" ] ; then
	JQ_VERSION=1.5

	curl -Ls https://raw.githubusercontent.com/stedolan/jq/master/sig/jq-release.key --output /tmp/jq-release.key
	curl -Ls https://raw.githubusercontent.com/stedolan/jq/master/sig/v${JQ_VERSION}/jq-linux64.asc --output /tmp/jq-linux64.asc
	curl -Ls https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64 --output /tmp/jq-linux64
	gpg --import /tmp/jq-release.key
	gpg --verify /tmp/jq-linux64.asc /tmp/jq-linux64

	if ! [ $? -eq 0 ] ; then
		exit $?
	fi

	chmod +x /tmp/jq-linux64

	jq () {
		/tmp/jq-linux64 $1 $2
	}
fi

# Log in and store cookies in a temporary file.
curl -sLc /tmp/cookies --post302 \
	'https://www.flatex.de/sso'\
	--data-raw "tx_flatexaccounts_singlesignonbanking%5Buname_app%5D=$1&tx_flatexaccounts_singlesignonbanking%5Bpassword_app%5D=$2"\
	--compressed --output /dev/null
# Extract the sessionid.
jsessionid=$(cat /tmp/cookies | grep -oP '(?<=JSESSIONID).*' | xargs)

# Remove the temporary cookies file.
rm /tmp/cookies

# Ask for the CSV file download link and extract it.
# X-tokenId needs to be set to any value, X-AJAX must be true.
csvpath=$(curl -s 'https://konto.flatex.de/banking-flatex/ajaxCommandServlet'\
	-H 'X-tokenId: 0'\
	-H 'X-AJAX: true'\
	-H "Cookie: JSESSIONID=$jsessionid"\
	--data-raw "command=triggerAction&widgetId=depositStatementForm_tableActionCombobox_entriesI1I&widgetName=tableActionCombobox.entries%5B1%5D&eventType=click&delay=0"\
	--compressed | jq -r '.commands[0].script' | grep -oP '(?<=DownloadDocumentBrowserBehaviorsClick.finished\(\").*?csv')

# Download and print the file.
curl -s "https://konto.flatex.de$csvpath"\
	-H "Cookie: JSESSIONID=$jsessionid"\
	--compressed
