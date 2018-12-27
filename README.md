pg-skel
=======

Создание postgresql template database.

Описание
--------

Решение применяется в случаях, когда проекту необходима БД, в которой некоторые операции выполнены под ролью суперпользователя, т.е. роли владельца БД тут недостаточно.

Примеры таких операций:

* CREATE EXTENSION
* копирование файлов в /usr/share/postgresql/$PG_MAJOR/tsearch_data

Для того, чтобы убрать потребность в суперпользователе при каждом деплое, принимается следующий алгоритм работы

1. В кластере создается шаблонная БД (template database)
2. Пользовательские БД создаются из этого шаблона

Текущий проект предназначен для выполнения шага 1.

Зависимости
-----------

* linux 64bit (git, make, wget)
* [Docker](http://docker.io)
* [dcape](https://github.com/dopos/dcape)

Быстрый старт
-------------

На локальной системе должен быть развернут [dcape](https://github.com/dopos/dcape), в настройках которого задан `PG_IMAGE=dopos/postgresql`.
```
git clone https://github.com/TenderPro/pg-skel.git
cd pg-skel
make start
```

Установка на хост dcape
-----------------------

Данный репозиторий является стандартным приложением [dcape](https://github.com/dopos/dcape) и его установка производится через webhook.

см [Интеграция приложения в dcape](https://github.com/dopos/dcape/blob/master/DEPLOY.md)

License
-------

This project is under the MIT License. See the [LICENSE](LICENSE) file for the full license text.

Copyright (c) 2016 [Tender.Pro](http://www.tender.pro)
