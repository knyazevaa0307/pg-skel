#!/usr/bin/env bash
set -Eeo pipefail

# copy tsearch_data/* to PG shared dir

SRC=${SRC:-/initdb.d/tsearch_data}
DEST=${DEST:-/usr/share/postgresql/$PG_MAJOR/tsearch_data}

if [ -e $SRC ] ; then
  echo "Sync $SRC.."
  cp -rf $SRC/* $DEST
fi
