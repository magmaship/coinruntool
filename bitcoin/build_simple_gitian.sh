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

readonly REPOSITORY="https://github.com/uasf/bitcoin"
readonly VERSION="v0.14.2-uasfsegwit1.0"
readonly SIGNER="$1"

readonly PROJECT_NAME=$(echo "${REPOSITORY}" | awk -F'/' '{print $NF}')

set -o errexit
set -o nounset

function cleanup() {
	set -x
	sudo rm -rf bitcoin-detached-sigs/ bitcoin/ gitian-builder/ gitian.sigs/
	set +x
}

function make_checks() {

	if [ -z ${SIGNER} ]; then
		echo "Signer name is unset - you should provide gpg signer name as first argument - exiting"
		echo "(Generate own gpg key for this)"
		exit 1
	fi

	echo
	echo "Checking for Mac OS X SDK (filtered)"
	echo "You can download from Apple the full SDK, and then prepare a smaller subset of this"
	echo "One example of such SDK, is the one, that after unpacking will show:"
	echo "  find | wc -l"
	echo "  29581"
	echo "(sdk files other then that also might work)"
	echo "Information how to obtain this - is available online in Bitcoin Gitian docs."
	echo "sha256 of one version of correct sdk files could be for example:"
	echo "d0f296a76bf53c9c63a1ec704e17e97388351381edb3080fd3cb4661957a6680"

	sdkfile="MacOSX10.11.sdk.tar.gz"

	if [[ -e "$HOME/$sdkfile" ]]
	then
		echo "Copying MacOSX SDK from home (PWD=$PWD)"
		mkdir "./gitian-builder/inputs/"
		if [[ -e "./gitian-builder/inputs/$sdkfile" ]] ; then
			rm "./gitian-builder/inputs/$sdkfile"
		fi
		cp "$HOME/$sdkfile" "./gitian-builder/inputs/"
	fi

	if [[ ! -e "./gitian-builder/inputs/$sdkfile" ]]
	then
		echo "Cannot build for OSX, SDK does not exist"
		echo "in PWD=$PWD"
		echo "You should provide MacOSX10.11.sdk.tar.gz"
		echo "Place it in top of your home ($HOME) directory"
		echo "(script will copy it to gitian-builder/inputs) - exiting"
		exit 1
	fi
}

function setup_gitian() {

	# install if not installed
	[[ "$(dpkg-query -l git | grep '^ii')" != "" ]] \
		|| sudo apt-get install git

	local base_location="$(pwd)"

	git clone "${REPOSITORY}" || true
	pushd $PROJECT_NAME
		git checkout "${VERSION}"

		if [[ ! -e "contrib/gitian-build.sh" ]]
		then
			echo "Can not find contrib/gitian-build.sh, you are probably trying to build a wrong version"
			exit 1
		fi
		pushd "contrib"
			patch < "${base_location}/gitian-build.patch"
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
	cleanup
	setup_gitian
	make_checks
	build_gitian
}
main

