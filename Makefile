#
# Создание шаблона БД
# template database Makefile
#
SHELL               = /bin/bash
CFG                 = .env

# on alpine use su-exec
GOSU               ?= gosu

DB_NAME            ?= tpro-template
DB_LOCALE          ?= ru_RU.UTF-8

# dcape container name prefix
DCAPE_PROJECT_NAME ?= dcape
# dcape postgresql container name
DCAPE_DB           ?= $(DCAPE_PROJECT_NAME)_db_1

define CONFIG_DEF
# ------------------------------------------------------------------------------
# pg-skel settings

# Template database name
DB_NAME=$(DB_NAME)

# Template database locale
DB_LOCALE=$(DB_LOCALE)

# dcape postgresql container name
DCAPE_DB=$(DCAPE_DB)

endef
export CONFIG_DEF

# ------------------------------------------------------------------------------
# Create script

define EXP_SCRIPT
DB_NAME=$$1 ; \
[[ "$$DB_NAME" ]] || { echo "DB_NAME not set. Exiting" ; exit 1 ; } ; \
DB_LOC=$$2 ; \
[[ "$$DB_LOC" ]] && DB_LOC="-l $$DB_LOC" ; \
SRC=/opt/share/$$DB_NAME ; \
D=/usr/local/share/postgresql ; \
echo "Copy data files to $$D..." ; \
cp -prf $$SRC/tsearch_data/ $$D/ ; \
if psql -U postgres -lqt | cut -d \| -f 1 | grep -qw $$DB_NAME; then \
  echo "Database '$$DB_NAME' already exists, exiting" ; exit 0 ; \
fi ; \
echo "Creating $$DB_NAME..." && su -c "createdb -T template0 $$DB_LOC $$DB_NAME" postgres && \
echo "Updating $$DB_NAME extensions..." && psql -d $$DB_NAME -U postgres -f $$SRC/setup.sql ; \
echo "Done"
endef
export EXP_SCRIPT

# ------------------------------------------------------------------------------

-include $(CFG)
export

.PHONY: all $(CFG) start start-hook stop update docker-wait db-create db-drop help

##
## Цели:
##

all: help

# ------------------------------------------------------------------------------
# webhook commands

start: db-create

start-hook: db-create

stop: db-drop

update: db-create

# ------------------------------------------------------------------------------
# docker

# Wait for postgresql container start
docker-wait:
	@echo -n "Checking PG is ready..."
	@until [[ `docker inspect -f "{{.State.Health.Status}}" $$DCAPE_DB` == healthy ]] ; do sleep 1 ; echo -n "." ; done
	@echo "Ok"

# ------------------------------------------------------------------------------
# DB operations

## create db and load sql
db-create: docker-wait
	@echo "*** $@ ***" ; \
	DEST=$$(docker exec $$DCAPE_DB printenv INITDB_DIR) ; \
	if [ ! $$DEST ]; then echo "Unsupported db container, exiting" ; exit 1; fi ; \
	docker cp ./fts/tsearch_data $$DCAPE_DB:$$DEST ; \
	docker cp ./tsearch_data.sh $$DCAPE_DB:$$DEST ; \
	docker exec -i $$DCAPE_DB $$DEST/tsearch_data.sh ; \
	[[ "$$DB_LOCALE" ]] && DB_LOCALE="-l $$DB_LOCALE" ; \
	db_exists=$$(docker exec $$DCAPE_DB psql -U postgres -lqt | grep -o -E "^ ($$DB_NAME) ") ; \
	if [[ ! "$$db_exists" ]] ; then \
	  echo "Creating $$DB_NAME..." && \
	  docker exec -i $$DCAPE_DB $(GOSU) postgres createdb -T template0 $$DB_LOCALE $$DB_NAME ; \
	  cat setup.sql | docker exec -i $$DCAPE_DB psql -U postgres -d $$DB_NAME -f - ; \
	fi

## drop database
db-drop: docker-wait
	@echo "*** $@ ***"
	@docker exec -i $$DCAPE_DB psql -U postgres -c "UPDATE pg_database SET datistemplate = FALSE WHERE datname = '$$DB_NAME';"
	@docker exec -i $$DCAPE_DB psql -U postgres -c "DROP DATABASE \"$$DB_NAME\";" || true

# ------------------------------------------------------------------------------

## create initial config
$(CFG):
	@echo "$$CONFIG_DEF" > $@

# ------------------------------------------------------------------------------

## List Makefile targets
help:
	@grep -A 1 "^##" Makefile | less

##
## Press 'q' for exit
##
