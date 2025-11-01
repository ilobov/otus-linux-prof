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

    1. Создаю новую БД на сервере node1

    ```
    postgres=# create database test;
    CREATE DATABASE
    postgres=# \c test
    You are now connected to database "test" as user "postgres".
    test=# create table t1 (id integer);
    CREATE TABLE
    test=# insert into t1 values (21);
    INSERT 0 1
    test=# select * from t1;
     id 
    ----
     21
    (1 row)
    ```

    2. На сервере barman проверяю работу системы бэкапов и выполняю бэкап БД

    ```
    barman@barman:~$ barman switch-wal node1
    2025-11-01 05:43:44,421 [6213] barman.utils WARNING: Failed opening the requested log file. Using standard error instead.
    The WAL file 000000010000000000000003 has been closed on server 'node1'
    2025-11-01 05:43:44,470 [6213] barman.server INFO: The WAL file 000000010000000000000003 has been closed on server 'node1'

    barman@barman:~$ barman cron 
    2025-11-01 05:44:02,656 [6220] barman.utils WARNING: Failed opening the requested log file. Using standard error instead.
    Starting WAL archiving for server node1

    barman@barman:~$ barman check node1
    2025-11-01 05:44:14,575 [6222] barman.utils WARNING: Failed opening the requested log file. Using standard error instead.
    Server node1:
    	PostgreSQL: OK
    	superuser or standard user with backup privileges: OK
    	PostgreSQL streaming: OK
    	wal_level: OK
    	replication slot: OK
    	directories: OK
    	retention policy settings: OK
    2025-11-01 05:44:14,662 [6222] barman.server ERROR: Check 'backup maximum age' failed for server 'node1'
    	backup maximum age: FAILED (interval provided: 4 days, latest backup age: No available backups)
    	backup minimum size: OK (0 B)
    	wal maximum age: OK (no last_wal_maximum_age provided)
    	wal size: OK (0 B)
    	compression settings: OK
    	failed backups: OK (there are 0 failed backups)
    2025-11-01 05:44:14,663 [6222] barman.server ERROR: Check 'minimum redundancy requirements' failed for server 'node1'
    	minimum redundancy requirements: FAILED (have 0 backups, expected at least 1)
    	pg_basebackup: OK
    	pg_basebackup compatible: OK
    	pg_basebackup supports tablespaces mapping: OK
    	systemid coherence: OK (no system Id stored on disk)
    	pg_receivexlog: OK
    	pg_receivexlog compatible: OK
    	receive-wal running: OK
    	archiver errors: OK

    barman@barman:~$ barman backup node1
    2025-11-01 05:47:30,573 [6255] barman.utils WARNING: Failed opening the requested log file. Using standard error instead.
    2025-11-01 05:47:30,669 [6255] barman.server INFO: Ignoring failed check 'backup maximum age' for server 'node1'
    2025-11-01 05:47:30,669 [6255] barman.server INFO: Ignoring failed check 'minimum redundancy requirements' for server 'node1'
    Starting backup using postgres method for server node1 in /var/lib/barman/node1/base/20251101T054730
    2025-11-01 05:47:30,675 [6255] barman.backup INFO: Starting backup using postgres method for server node1 in /var/lib/barman/node1/base/20251101T054730
    Backup start at LSN: 0/5000060 (000000010000000000000005, 00000060)
    2025-11-01 05:47:30,680 [6255] barman.backup_executor INFO: Backup start at LSN: 0/5000060 (000000010000000000000005, 00000060)
    Starting backup copy via pg_basebackup for 20251101T054730
    2025-11-01 05:47:30,680 [6255] barman.backup_executor INFO: Starting backup copy via pg_basebackup for 20251101T054730
    WARNING: pg_basebackup does not copy the PostgreSQL configuration files that reside outside PGDATA. Please manually backup the following files:
    	/etc/postgresql/14/main/postgresql.conf
    	/etc/postgresql/14/main/pg_hba.conf
    	/etc/postgresql/14/main/pg_ident.conf

    2025-11-01 05:47:31,110 [6255] barman.backup_executor WARNING: pg_basebackup does not copy the PostgreSQL configuration files that reside outside PGDATA.     Please manually backup the following files:
    	/etc/postgresql/14/main/postgresql.conf
    	/etc/postgresql/14/main/pg_hba.conf
    	/etc/postgresql/14/main/pg_ident.conf

    Copy done (time: less than one second)
    2025-11-01 05:47:31,112 [6255] barman.backup_executor INFO: Copy done (time: less than one second)
    Finalising the backup.
    2025-11-01 05:47:31,113 [6255] barman.backup_executor INFO: Finalising the backup.
    This is the first backup for server node1
    2025-11-01 05:47:31,133 [6255] barman.backup_executor INFO: This is the first backup for server node1
    WAL segments preceding the current backup have been found:
    	000000010000000000000003 from server node1 has been removed
    2025-11-01 05:47:31,134 [6255] barman.backup_executor INFO: 	000000010000000000000003 from server node1 has been removed
    	000000010000000000000004 from server node1 has been removed
    2025-11-01 05:47:31,136 [6255] barman.backup_executor INFO: 	000000010000000000000004 from server node1 has been removed
    2025-11-01 05:47:31,139 [6255] barman.postgres INFO: Restore point 'barman_20251101T054730' successfully created
    Backup size: 33.6 MiB
    2025-11-01 05:47:31,289 [6255] barman.backup INFO: Backup size: 33.6 MiB
    Backup end at LSN: 0/7000000 (000000010000000000000006, 00000000)
    2025-11-01 05:47:31,290 [6255] barman.backup INFO: Backup end at LSN: 0/7000000 (000000010000000000000006, 00000000)
    Backup completed (start time: 2025-11-01 05:47:30.681389, elapsed time: less than one second)
    2025-11-01 05:47:31,290 [6255] barman.backup INFO: Backup completed (start time: 2025-11-01 05:47:30.681389, elapsed time: less than one second)
    2025-11-01 05:47:31,293 [6255] barman.wal_archiver INFO: Found 2 xlog segments from streaming for node1. Archive all segments in one run.
    Processing xlog segments from streaming for node1
    	000000010000000000000005
    2025-11-01 05:47:31,293 [6255] barman.wal_archiver INFO: Archiving segment 1 of 2 from streaming: node1/000000010000000000000005
    	000000010000000000000006
    2025-11-01 05:47:31,368 [6255] barman.wal_archiver INFO: Archiving segment 2 of 2 from streaming: node1/000000010000000000000006
    ```

    3. На сервере node1 удаляю БД test

    ```
    est=# \c postgres
    You are now connected to database "postgres" as user "postgres".
    postgres=# drop database test;
    DROP DATABASE
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
    ```

    4. Выполняю восстановление из бэкапа

    ```
    barman@barman:~$ barman list-backup node1
    2025-11-01 05:47:46,493 [6263] barman.utils WARNING: Failed opening the requested log file. Using standard error instead.
    node1 20251101T054730 - Sat Nov  1 05:47:31 2025 - Size: 33.6 MiB - WAL Size: 0 B
    barman@barman:~$ barman recover node1 20251101T054730 /var/lib/postgresql/14/main/ --remote-ssh-comman "ssh postgres@192.168.57.11"
    2025-11-01 05:48:51,886 [6269] barman.utils WARNING: Failed opening the requested log file. Using standard error instead.
    2025-11-01 05:48:51,894 [6269] barman.wal_archiver INFO: No xlog segments found from streaming for node1.
    The authenticity of host '192.168.57.11 (192.168.57.11)' can't be established.
    ED25519 key fingerprint is SHA256:d+UmAbo+mq34b6BqE5RZvmMbGbcVIok+2MfyxGihZbo.
    This key is not known by any other names
    Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
    Starting remote restore for server node1 using backup 20251101T054730
    2025-11-01 05:48:54,727 [6269] barman.recovery_executor INFO: Starting remote restore for server node1 using backup 20251101T054730
    Destination directory: /var/lib/postgresql/14/main/
    2025-11-01 05:48:54,728 [6269] barman.recovery_executor INFO: Destination directory: /var/lib/postgresql/14/main/
    Remote command: ssh postgres@192.168.57.11
    2025-11-01 05:48:54,728 [6269] barman.recovery_executor INFO: Remote command: ssh postgres@192.168.57.11
    2025-11-01 05:48:54,914 [6269] barman.recovery_executor WARNING: Unable to retrieve safe horizon time for smart rsync copy: The /var/lib/postgresql/14/   main/.barman-recover.info file does not exist
    Copying the base backup.
    2025-11-01 05:48:55,299 [6269] barman.recovery_executor INFO: Copying the base backup.
    2025-11-01 05:48:55,305 [6269] barman.copy_controller INFO: Copy started (safe before None)
    2025-11-01 05:48:55,306 [6269] barman.copy_controller INFO: Copy step 1 of 4: [global] analyze PGDATA directory: /var/lib/barman/node1/base/    20251101T054730/data/
    2025-11-01 05:48:55,634 [6269] barman.copy_controller INFO: Copy step 2 of 4: [global] create destination directories and delete unknown files for PGDATA     directory: /var/lib/barman/node1/base/20251101T054730/data/
    2025-11-01 05:48:55,902 [6286] barman.copy_controller INFO: Copy step 3 of 4: [bucket 0] starting copy safe files from PGDATA directory: /var/lib/barman/   node1/base/20251101T054730/data/
    2025-11-01 05:48:56,273 [6286] barman.copy_controller INFO: Copy step 3 of 4: [bucket 0] finished (duration: less than one second) copy safe files from     PGDATA directory: /var/lib/barman/node1/base/20251101T054730/data/
    2025-11-01 05:48:56,284 [6286] barman.copy_controller INFO: Copy step 4 of 4: [bucket 0] starting copy files with checksum from PGDATA directory: /var/   lib/barman/node1/base/20251101T054730/data/
    2025-11-01 05:48:56,519 [6286] barman.copy_controller INFO: Copy step 4 of 4: [bucket 0] finished (duration: less than one second) copy files with    checksum from PGDATA directory: /var/lib/barman/node1/base/20251101T054730/data/
    2025-11-01 05:48:56,522 [6269] barman.copy_controller INFO: Copy finished (safe before None)
    Copying required WAL segments.
    2025-11-01 05:48:56,765 [6269] barman.recovery_executor INFO: Copying required WAL segments.
    2025-11-01 05:48:56,767 [6269] barman.recovery_executor INFO: Starting copy of 1 WAL files 1/1 from WalFileInfo(compression='gzip',     name='000000010000000000000006', size=16461, time=1761976050.9931967) to WalFileInfo(compression='gzip', name='000000010000000000000006', size=16461,     time=1761976050.9931967)
    2025-11-01 05:48:57,209 [6269] barman.recovery_executor INFO: Finished copying 1 WAL files.
    Generating archive status files
    2025-11-01 05:48:57,212 [6269] barman.recovery_executor INFO: Generating archive status files
    Identify dangerous settings in destination directory.
    2025-11-01 05:48:57,863 [6269] barman.recovery_executor INFO: Identify dangerous settings in destination directory.

    WARNING
    The following configuration files have not been saved during backup, hence they have not been restored.
    You need to manually restore them in order to start the recovered PostgreSQL instance:

        postgresql.conf
        pg_hba.conf
        pg_ident.conf

    Recovery completed (start time: 2025-11-01 05:48:51.895651, elapsed time: 6 seconds)

    Your PostgreSQL server has been successfully prepared for recovery!
    ```

    5. Проверяю, что БД восстановлена

    ```
    root@node1:~# systemctl stop postgresql.service 
    root@node1:~# systemctl start postgresql.service 
    root@node1:~# su - postgres
    postgres@node1:~$ psql
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
    
    postgres=# \c
    You are now connected to database "postgres" as user "postgres".
    postgres=# \c test
    You are now connected to database "test" as user "postgres".
    test=# select * from t1;
     id 
    ----
     21
    (1 row)
    ```
