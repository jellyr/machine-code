#!/bin/bash
# -*- coding: utf-8 -*-
# Copyright © 2017 Göran Weinholt <goran@weinholt.se>

# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

# This installs Schemes for use by the continuous integration system
# (see .travis.yml).

set -ex

export SCHEME=${1:-ChezScheme}
if [ -z "$SCHEME_LIBRARY_PATH" ]; then
    export SCHEME_LIBRARY_PATH=$PWD/..
else
    export SCHEME_LIBRARY_PATH=$PWD/..:$SCHEME_LIBRARY_PATH
fi
export INSTALL_TARGET=${INSTALL_TARGET:-$PWD/opt}
export BUILD_PREFIX=${BUILD_PREFIX:-build-}
export BUILD_DIR=${BUILD_DIR-$BUILD_PREFIX$SCHEME}

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Build and install the selected Scheme implementation.

case "$SCHEME" in
    ChezScheme)
        (
            curl -L https://api.github.com/repos/cisco/ChezScheme/tarball > ChezScheme-master.tar.gz
            mkdir chezscheme-master && tar -C chezscheme-master --strip-components 1 -xaf ChezScheme-master.tar.gz
            pushd chezscheme-master && ./configure --installprefix="$INSTALL_TARGET" && make && make install && popd
        ) > /dev/stderr
        cat <<EOF
export CHEZSCHEMELIBDIRS=$SCHEME_LIBRARY_PATH
export -n RUNSCHEME=
EOF
        ;;
    Guile)
        # GNU Guile is assumed to be installed via apt.
        (
            mkdir -p "$INSTALL_TARGET/share"
            cat > "$INSTALL_TARGET/share/r6rs.guile.scm" <<EOF
;; Sets R6RS options for GNU Guile.
(set! %load-extensions (append '(".guile.sls" ".sls") %load-extensions))
(read-enable 'r6rs-hex-escapes)
(read-enable 'hungry-eol-escapes)
EOF
        ) > /dev/stderr
        cat <<EOF
export GUILE_LOAD_PATH=$SCHEME_LIBRARY_PATH
export RUNSCHEME="guile -l $INSTALL_TARGET/share/r6rs.guile.scm -ds"
EOF
        ;;
    Sagittarius)
        (
            curl -L https://bitbucket.org/ktakashi/sagittarius-scheme/downloads/sagittarius-0.7.11.tar.gz > sagittarius.tar.gz
            mkdir sagittarius-scheme && tar -C sagittarius-scheme --strip-components 1 -xaf sagittarius.tar.gz
            pushd sagittarius-scheme && cmake . -DCMAKE_INSTALL_PREFIX="$INSTALL_TARGET" && make && make install && popd
        ) > /dev/stderr
        cat <<EOF
export SAGITTARIUS_LOADPATH=$SCHEME_LIBRARY_PATH
export RUNSCHEME="sagittarius -r6"
EOF
        ;;
esac

# Finally set the paths.

cat <<EOF
export PATH=$INSTALL_TARGET/bin:$PATH
export LD_LIBRARY_PATH=$INSTALL_TARGET/lib:$LD_LIBRARY_PATH
EOF
