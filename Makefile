#
# Создание шаблона БД
# template database Makefile
#
SHELL        = /bin/bash
CONSUP_ROOT ?= ..
FILES       ?= fts/tsearch_data setup.sql
DBT         ?= tpro-template

PGC_PROJECT ?= consup
PGC_NAME    ?= postgres
PGC_MODE    ?= common
PGC         ?= $(PGC_PROJECT)_$(PGC_NAME)_$(PGC_MODE)
SYSDIR      ?= $(CONSUP_ROOT)/consup/var/log/$(PGC_NAME)_$(PGC_MODE)/pg-skel

all: help

##
## Цели:
##

## запустить контейнер postgresql
pg-start:
	@echo "*** $@ ***"
	@echo "Consup root: $(CONSUP_ROOT)"
	@RUNNING=$$(docker inspect --format="{{ .State.Running }}" $(PGC) 2> /dev/null) ; \
[ "$$RUNNING" == "true" ] || { \
  echo "Starting DB container $(PGC)..." ; pushd $(CONSUP_ROOT)/consup && fidm start postgres.yml mode=$(PGC_MODE) && popd ; }

## остановить контейнер postgresql, если он запущен
pg-stop:
	@echo "*** $@ ***"
	@RUNNING=$$(docker inspect --format="{{ .State.Running }}" $(PGC) 2> /dev/null) ; \
[ "$$RUNNING" == "true" ] && { \
  echo "Stopping DB container $(PGC)..." ; pushd $(CONSUP_ROOT)/consup && fidm rm postgres.yml mode=$(PGC_MODE) && popd ; }

define EXP_SCRIPT
DB_NAME=$$1 ; \
[[ "$$DB_NAME" ]] || { echo "DB_NAME not set. Exiting" ; exit 1 ; } ; \
SRC=/var/log/supervisor/pg-skel ; \
D=/usr/share/postgresql/$$PG_MAJOR ; \
cp -prf $$SRC/tsearch_data/ $$D/ ; \
echo "Wait for postgresql startup..." ; \
while ! gosu postgres pg_isready -q ; do sleep 1 ; done ; \
if psql -lqt | cut -d \| -f 1 | grep -qw $$DB_NAME; then \
  echo "Database '$$DB_NAME' already exists, exiting" ; exit 0 ; \
fi ; \
echo "Creating $$DB_NAME..." && gosu postgres createdb $$DB_NAME && \
echo "Updating $$DB_NAME extensions..." && psql -d $$DB_NAME -f $$SRC/setup.sql ; \
echo "Done"
endef
export EXP_SCRIPT

# алиасы для ci
stop:

setup:

start-hook: build

## создать шаблон БД
build: pg-start
	@echo "*** $@ ***"
	@[ -d $(SYSDIR) ] || mkdir $(SYSDIR)
	@cp -rf $(FILES) $(SYSDIR)/
	@echo "$$EXP_SCRIPT" | docker exec -i $(PGC) bash -s - $(DBT)

## установка зависимостей
deps:
	@echo "*** $@ ***"
	@echo "Consup root: $(CONSUP_ROOT)"
	# code from http://docs.docker.com/linux/step_one/
	which docker > /dev/null || wget -qO- https://get.docker.com/ | sh
	# code from https://github.com/LeKovr/fidm
	which fidm > /dev/null || wget -qO- https://raw.githubusercontent.com/LeKovr/fidm/master/install.sh | sh
	# Каталог **consup** должен быть доступен из каталога **iac** как `../consup` или `../../consup`.
	[[ -d $(CONSUP_ROOT)/consup ]] || cd $(CONSUP_ROOT) && wget -qO- https://raw.githubusercontent.com/LeKovr/consup/master/install.sh | sh
	# контейнеры Docker
	for n in consul nginx postgres pgrest ; do docker pull lekovr/consup_$$n ; done
	@echo Done

## cписок доступных целей
help:
	@grep -A 1 "^##" Makefile
