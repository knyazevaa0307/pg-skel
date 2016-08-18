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

SRC=/var/log/supervisor/pg_system
D=/usr/share/postgresql/$PG_MAJOR/tsearch_data

log "Setup postgresql system files as user $(id -un)"

log "Copy translit"
F=translit.rules
[ -e $D/$F ] || cp $SRC/$F $D/

log "Copy fts"
pushd $SRC/fts-pg/tsearch_data > /dev/null
for f in *.* ; do
  [ -e $D/$f ] || cp $f $D/
done
popd  > /dev/null

if gosu postgres psql -lqt | cut -d \| -f 1 | grep -qw $DB; then
  log "Database '$DB' already exists, exiting"
  exit 0
fi

log "Creating $DB..."
gosu postgres createdb $DB

log "Updating $DB extensions..."
gosu postgres psql -d $DB -f $SRC/setup.sql

log "Updating $DB FTS..."
gosu postgres psql -d $DB -f $SRC/fts-pg/setup.sql

log "Updating $DB stat views..."
gosu postgres psql -d $DB -f $SRC/stat.sql

log "Done"
