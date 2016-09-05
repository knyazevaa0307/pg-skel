pg-skel
=======

Создание postgresql template database.

Описание
--------

Решение применяется в случаях, когда проекту необходима БД, в которой некоторые операции выполнены под ролью суперпользователя, т.е. роли владельца БД тут недостаточно.

Примеры таких операций:

* CREATE EXTENSION
* копирование файлов в /usr/share/postgresql/tsearch_data

Для того, чтобы убрать потребность в суперпользователе при каждом деплое, принимается следующий алгоритм работы

1. В кластере создается шаблонная БД (template database)
2. Пользовательские БД создаются из этого шаблона

Текущий проект предназначен для выполнения шага 1.

При использовании проекта [ConSup](https://github.com/LeKovr/consup), шаг 2 выполняется автоматически при старте контейнера приложения

Зависимости
-----------

* linux 64bit (git, make, wget)
* [Docker](http://docker.io)
* [fidm](https://github.com/LeKovr/fidm)
* [ConSup](https://github.com/LeKovr/consup) (установка по инструкции ниже)

Установка производится на хост с 64bit linux (64bit - это требование docker).
Git будет установлен вместе с docker, единственная зависимость, которую надо поставить вручную - make.

### Установка make

```
which make > /dev/null || sudo apt-get install make
```

### Установка **docker**, **fidm**, **consup**

При установке **docker** и **fidm** потребуется пароль для sudo.

Все зависимости установятси при выполнении этой команды, при этом docker будет установлен согласно [инструкции](http://docs.docker.com/linux/step_one/). Если такой вариант не подходит, надо предварительно поставить docker вручную.
```
make deps
```

Для того, чтобы текущий пользователь мог работать с docker, его надо добавить в группу docker:
```
sudo usermod -a -G docker $USER
```

Если на хосте уже установлен consup и настраивается дополнительная копия, надо изменить в consup/postgres.yml значение bind_ip на другой адрес (например, 127.0.0.2).
Кроме того, надо будет изменить суффикс имени контейнера Postgresql:
```
PGC_MODE=common1 make build
```

Использование
-------------

*Создание БД tpro-template*
```
git clone http://git.it.tender.pro/iac/pg-skel.git
cd pg-skel
make deps
make build
```

Если нужно создать БД с другим именем, надо его задать при вызове `make build`:
```
DBT=my-template make build
```

Для создания БД необходим контейнер consup_postgres, будет запущен при необходимости.
Для того, чобы потом остановить этот контейнер, надо выполнить
```
make pg-stop
```

Актуальный список целей можно посмотреть командой `make`.

License
-------

This project is under the MIT License. See the [LICENSE](LICENSE) file for the full license text.

Copyright (c) [Tender.Pro](http://www.tender.pro)
