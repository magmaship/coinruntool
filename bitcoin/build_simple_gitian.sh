#!/usr/bin/env bash

# this builds the Gitian builds of bitcoin
# it can take over 8 hours to complete

# tested on clean debian jessie, ubuntu willy
# and btc version v14.0.0, older version may not have gitian-build.sh script

readonly THREADS=2
readonly MEMORY=3072

readonly REPOSITORY="https://github.com/da2ce7/bitcoin"
readonly VERSION="knotsbip148"
readonly SIGNER=$1

readonly PROJECT_NAME=$(echo "${REPOSITORY}" | awk -F'/' '{print $NF}')

set -o errexit
set -o nounset

function make_checks() {

	if [ -z ${SIGNER} ]; then
		echo "Signer name is unset - you should provide gpg signer name as first argument - exiting"
		exit 1
	fi

	if [[ ! -e "./gitian-builder/inputs/MacOSX10.11.sdk.tar.gz" ]]
	then
		echo "Cannot build for OSX, SDK does not exist"
		echo "You should provide MacOSX10.11.sdk.tar.gz in gitian-builder/inputs to build all - exiting"
		exit 1
	fi
}

function setup_gitian() {

	# install if not installed
	[[ "$(dpkg-query -l git | grep '^ii')" != "" ]] \
		|| sudo apt-get install git

	git clone "${REPOSITORY}" || true
	pushd $PROJECT_NAME
		git checkout "${VERSION}"

		if [[ ! -e "contrib/gitian-build.sh" ]]
		then
			echo "Can not find contrib/gitian-build.sh, you are probably trying to build a wrong version"
			exit 1
		fi
		pushd "contrib"
			patch < gitian-build.patch
		popd
	popd

	# signer and version are not used in --setup in gitian-build script
	"./$PROJECT_NAME/contrib/gitian-build.sh" --setup fake_signer fake_version
}

function build_gitian() {

	if [[ ! -e "./bitcoin/contrib/gitian-build.sh" ]]
	then
		echo "Can not find bitcoin/contrib/gitian-build.sh. Did you setup_gitian? - exiting"
		exit 1
	fi

	"./bitcoin/contrib/gitian-build.sh" -j "${THREADS}" -m "${MEMORY}" -c --url "${REPOSITORY}" --build --detach-sign "${SIGNER}" "${VERSION}"
}

function main() {
	setup_gitian
	make_checks
	build_gitian
}
main

