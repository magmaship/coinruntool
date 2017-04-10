#!/usr/bin/env bash
# by: goldentropy@magmaship.com
# copyrighted (C) 2017, licence: Public Domain, and 3-Clause BSD License

function describe() {
	echo "This script downloads and builds bitcoin."
	echo "Platform: Debian 8, and should work on Ubuntu related"
	echo "Result: creates binary native build of bitcoin"
	echo "Needs: nothing - installs own deps itself"
	echo "Run as: regular user, it will use sudo where it needs root"
	echo "Quality: a test script, only use if you read the code yourself"
}

# btc and bd4.8 dir
readonly BITCOIN_ROOT="$(pwd)/bitcoin"
readonly BDB_PREFIX="${BITCOIN_ROOT}/db4"
readonly BRANCH="v0.14.0"
readonly REPOSITORY="https://github.com/bitcoin/bitcoin"
readonly CXXFLAGS=""
# readonly CXXFLAGS="--param ggc-min-expand=1 --param ggc-min-heapsize=32768" # options for limited hardware e.g. rpi

set -e # abort on most errors

function set_build_options() {
	if [ -z "$THREADS" ] ; then
		echo "Defaulting to 2 threads, you set export THREADS=8 before running script"
		readonly THREADS=2
	fi
        echo "Using THREADS=$THREADS"
}

# clone source
function getbtc() {
    git clone --branch "$BRANCH" "$REPOSITORY"
}

# install dependiences
function install_dependencies() {
    echo "Will install dependencies now (tested on Debian Jessie)"
    echo "(needs sudo to access root)" 

    set -x
    sudo apt-get install build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils -y
    # libboost
    sudo apt-get install libboost-system-dev libboost-filesystem-dev libboost-chrono-dev \
                         libboost-program-options-dev libboost-test-dev libboost-thread-dev -y
    # for miniupnpc enabled
    sudo apt-get install libminiupnpc-dev -y
    # ZMQ
    sudo apt-get install libzmq3-dev -y
    # GUI - qt5
    sudo apt-get install libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler -y
    # qrcode
    sudo apt-get install libqrencode-dev -y
    set +x
}

# Install Berkeley DB 4.8
function build_db48() {
    # Pick some path to install BDB to, here we create a directory within the bitcoin directory
    mkdir -p $BDB_PREFIX

    # Fetch the source and verify that it is not tampered with
    local url="http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz"
    wget "$url" || { echo "Can not download $url" ; exit 1 ; }
    
    echo '12edc0df75bf9abd7f82f821795bcee50f42cb2e5f76a6a281b85732798364ef  db-4.8.30.NC.tar.gz' | sha256sum -c || {
        echo "The checksum was unexpected! This can be download problem, or else some hacking attempt, please verify this!"
        exit 1
    }

    # -> db-4.8.30.NC.tar.gz: OK
    tar -xzvf db-4.8.30.NC.tar.gz

    # Build the library and install to our prefix
    pushd db-4.8.30.NC/build_unix/
        #  Note: Do a static build so that it can be embedded into the executable, instead of having to find a .so at runtime
        ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=$BDB_PREFIX
        make -j "${THREADS}"
        make install
    popd
}

function entire_build() {
    getbtc

    pushd "$BITCOIN_ROOT"

        build_db48

        # main btc build
        ./autogen.sh
        ./configure --with-miniupnpc \
                    LDFLAGS="-L${BDB_PREFIX}/lib/" CPPFLAGS="-I${BDB_PREFIX}/include/" \
                    CXXFLAGS="$CXXFLAGS"
        make -j "${THREADS}"

    popd
}

function print_help() {
	echo "program [commands]"
	echo "  -i Install dependencies (will use sudo)"
        echo "  -b Build the project (and e.g. needed code dependencies)"
        echo "  -h Print this help"
        echo ""
        echo "Typical use:"
        echo "$0 -ib"
        echo ""
}

function main() {
    describe

    local matched=0 # no option matched

    while getopts "ibh" OPTION; do
        case $OPTION in
        i)
            install_dependencies && { echo ; echo "The Dependencies installation is done." ; }
            matched=1
        ;;
        b)
            entire_build && { echo ; echo "The Build is done." ; }
            matched=1
        ;;
        h)
            print_help
            matched=1
        ;;
        esac
    done

    if [[ "$matched" == "0" ]]
    then
        print_help
    fi

}

main "$@"

