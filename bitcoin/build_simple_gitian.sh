#!/usr/bin/env bash
# by: goldentropy@magmaship.com
# by: bincap@magmaship.com ( 755F73E1BFF9A977076E5857D708974B12C4434F )
# http://github.com:magmaship/coinruntool
# copyrighted (C) 2017, licence: Public Domain, and 3-Clause BSD License

# this builds the Gitian builds of bitcoin
# it can take over 8 hours to complete

# tested on clean debian jessie, ubuntu willy
# and btc version v14.0.0, older version may not have gitian-build.sh script

readonly THREADS=2
readonly MEMORY=3072

readonly REPOSITORY="https://github.com/magmaship/bitcoin"
readonly VERSION="knotsbip148"
readonly SIGNER=$1

readonly PROJECT_NAME=$(echo "${REPOSITORY}" | awk -F'/' '{print $NF}')

set -o errexit
set -o nounset

function make_checks() {

	if [ -z ${SIGNER} ]; then
		echo "Signer name is unset - you should provide gpg signer name as first argument - exiting"
		echo "(Generate own gpg key for this)"
		exit 1
	fi

	echo
	echo "Checking for Mac OS X SDK (filtered)"
	echo "You can download from Apple the full SDK, and then prepare a smaller subset of this"
	echo "One example of such SDK, is the one, that after unpacking has:"
	echo "find | wc -l"
	echo "29581"
	echo ""
	echo ""


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

