#
# Создание БД и системных объектов
# db.tender.pro backend Makefile
#
SHELL         = /bin/bash
CONSUP_ROOT  ?= $$([ -d ../consup ] && echo ".." || { [ -d ../../consup ] && echo "../.." ; } || { [ -d ../../../consup ] && echo "../../.." ; })
PG_CONTAINER ?= consup_postgres_common
DBT          ?= tpro-template
DB           ?= tpro
DB_USER         ?= $(DB)
DB_PASSWORD     ?= $(DB)

all: help

## запустить контейнер postgresql
start_pg:
	@RUNNING=$$(docker inspect --format="{{ .State.Running }}" $(PG_CONTAINER) 2> /dev/null) ; \
[ "$$RUNNING" == "true" ] || { echo "Starting DB container $(PG_CONTAINER)..." ; pushd $(CONSUP_ROOT) && fidm start postgres.yml mode=common && popd ; }

## остановить контейнер postgresql, если он запущен
stop_pg:
	@RUNNING=$$(docker inspect --format="{{ .State.Running }}" $(PG_CONTAINER) 2> /dev/null) ; \
[ "$$RUNNING" == "true" ] && { echo "Stopping DB container $(PG_CONTAINER)..." ; pushd $(CONSUP_ROOT) && fidm rm postgres.yml mode=common && popd ; }

## создать шаблон БД
tmpl: start_pg
	@echo "Consup root: $(CONSUP_ROOT)"
	@cp -rf pg_system $(CONSUP_ROOT)/consup/var/log/postgres_common
	@docker exec -i $(PG_CONTAINER) bash /var/log/supervisor/pg_system/init.sh $(DBT)

define CREATE_DEF
create user $(DB_USER) password '$(DB_PASSWORD)';
create database $(DB) owner $(DB_USER) template '$(DBT)';
endef
export CREATE_DEF

## создать БД
db: start_pg
	@echo "$$CREATE_DEF"
	@echo "$$CREATE_DEF" | docker exec -i $(PG_CONTAINER) gosu postgres  psql

## установка зависимостей
deps:
	@echo "*** $@ ***"
	# code from http://docs.docker.com/linux/step_one/
	which docker > /dev/null || wget -qO- https://get.docker.com/ | sh
	# code from https://github.com/LeKovr/fidm
	which fidm > /dev/null || wget -qO- https://raw.githubusercontent.com/LeKovr/fidm/master/install.sh | sh
	# Каталог **consup** должен быть доступен из каталога **iac** как `../consup` или `../../consup`.
	[[ "$CONSUP_ROOT" ]] || cd .. && wget -qO- https://raw.githubusercontent.com/LeKovr/consup/master/install.sh | sh
	# контейнеры Docker
	for n in consul nginx postgres pgrest ; do docker pull lekovr/consup_$$n ; done
	@echo Done

help:
	@grep -A 1 "^##" Makefile

