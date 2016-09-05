#
# Создание шаблона БД
# template database Makefile
#
SHELL         = /bin/bash
CONSUP_ROOT  ?= ..
SYSDIR       ?= $(CONSUP_ROOT)/consup/var/log/postgres_common/pg-skel
PG_CONTAINER ?= consup_postgres_common
FILES        ?= fts/tsearch-data init.sh setup.sql  stat.sql  translit.rules
DBT          ?= tpro-template

all: help

##
## Цели:
##

## запустить контейнер postgresql
pg-start:
	@echo "*** $@ ***"
	@echo "Consup root: $(CONSUP_ROOT)"
	@RUNNING=$$(docker inspect --format="{{ .State.Running }}" $(PG_CONTAINER) 2> /dev/null) ; \
[ "$$RUNNING" == "true" ] || { echo "Starting DB container $(PG_CONTAINER)..." ; pushd $(CONSUP_ROOT)/consup && fidm start postgres.yml mode=common && popd ; }

## остановить контейнер postgresql, если он запущен
pg-stop:
	@echo "*** $@ ***"
	@RUNNING=$$(docker inspect --format="{{ .State.Running }}" $(PG_CONTAINER) 2> /dev/null) ; \
[ "$$RUNNING" == "true" ] && { echo "Stopping DB container $(PG_CONTAINER)..." ; pushd $(CONSUP_ROOT)/consup && fidm rm postgres.yml mode=common && popd ; }

## создать шаблон БД
build: pg-start
	@echo "*** $@ ***"
	[ -d $(SYSDIR) ] || mkdir $(SYSDIR)
	@cp -rf $(FILES) $(SYSDIR)/
	@docker exec -i $(PG_CONTAINER) bash /var/log/supervisor/pg-skel/init.sh $(DBT)

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
