## Репликация postgres

### Задание

Что нужно сделать?

* настроить hot_standby репликацию с использованием слотов
* настроить правильное резервное копирование

### Решение

1. Настройка стенда

    - Запускаем создание ВМ через Vagrant   

        vargant up


2. Проверка работы

  * Репликация

    На ВМ node1 подключаемся к postgres создаем новую БД и в ней таблицу. После этого проверяем наличие изменений на node2.

    ```
    root@node1:~# sudo -u postgres psql
    could not change directory to "/root": Permission denied
    psql (14.19 (Ubuntu 14.19-0ubuntu0.22.04.1))
    Type "help" for help.

    postgres=# \l
                                  List of databases
       Name    |  Owner   | Encoding | Collate |  Ctype  |   Access privileges   
    -----------+----------+----------+---------+---------+-----------------------
     postgres  | postgres | UTF8     | C.UTF-8 | C.UTF-8 | 
     template0 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
               |          |          |         |         | postgres=CTc/postgres
     template1 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
               |          |          |         |         | postgres=CTc/postgres
    (3 rows)

    postgres=# create database test;
    CREATE DATABASE
    postgres=# \c test
    You are now connected to database "test" as user "postgres".
    test=# create table t1 (id integer);
    CREATE TABLE
    test=# insert into t1 values (1);
    INSERT 0 1
    test=# select * from t1;
     id 
    ----
      1
    (1 row)
    ```

    Перехожу на ВМ node2:

    ```
    root@node2:~# sudo -u postgres psql
    could not change directory to "/root": Permission denied
    psql (14.19 (Ubuntu 14.19-0ubuntu0.22.04.1))
    Type "help" for help.

    postgres=# \l
                                  List of databases
       Name    |  Owner   | Encoding | Collate |  Ctype  |   Access privileges   
    -----------+----------+----------+---------+---------+-----------------------
     postgres  | postgres | UTF8     | C.UTF-8 | C.UTF-8 | 
     template0 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
               |          |          |         |         | postgres=CTc/postgres
     template1 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
               |          |          |         |         | postgres=CTc/postgres
     test      | postgres | UTF8     | C.UTF-8 | C.UTF-8 | 
    (4 rows)

    postgres=# \c test
    You are now connected to database "test" as user "postgres".
    test=# select * from t1;
     id 
    ----
      1
    (1 row)

    test=# insert into t1 values (2);
    ERROR:  cannot execute INSERT in a read-only transaction
    ```

    Изменения на slave появились, БД нахлодиться в режиме read-only

  * Проверка работы системы бэкапов
