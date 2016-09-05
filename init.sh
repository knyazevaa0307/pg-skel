#!/bin/bash
#
# Копирование файлов в системный каталог postgresql и создание template database
#

# strict mode http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

log() {
  local d=$(date "+%F %T")
  echo  "$d $1"
}

DB=$1

SRC=/var/log/supervisor/pg-skel
D=/usr/share/postgresql/$PG_MAJOR/tsearch_data

log "Setup postgresql system files as user $(id -un)"

log "Copy tsearch_data"
pushd $SRC/fts/tsearch_data > /dev/null
for f in *.* ; do
  [ -e $D/$f ] || cp $f $D/
done
popd  > /dev/null

log "Wait for postgresql startup..." ;
while ! gosu postgres pg_isready -q ; do
  sleep 1
done

if gosu postgres psql -lqt | cut -d \| -f 1 | grep -qw $DB; then
  log "Database '$DB' already exists, exiting"
  exit 0
fi

log "Creating $DB..."
gosu postgres createdb $DB

log "Updating $DB extensions..."
gosu postgres psql -d $DB -f $SRC/setup.sql

## Created in pgm/sql/fts
#log "Updating $DB FTS..."
#gosu postgres psql -d $DB -f $SRC/fts/setup.sql

## Created in pgm/sql/utils/40_stat.sql
#log "Updating $DB stat views..."
#gosu postgres psql -d $DB -f $SRC/stat.sql

log "Done"
