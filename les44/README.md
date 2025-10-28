## Репликация mysql

### Задание

Что нужно сделать?

В материалах приложены ссылки на вагрант для репликации и дамп базы bet.dmp

Базу развернуть на мастере и настроить так, чтобы реплицировались таблицы:


| bookmaker          |  
| competition        |  
 market              |  
| odds               |  
| outcome  

Настроить GTID репликацию

варианты которые принимаются к сдаче

рабочий вагрантафайл
скрины или логи SHOW TABLES
конфиги*

пример в логе изменения строки и появления строки на реплике*

### Решение

1. Создание ВМ

    - Запускаем создание ВМ через Vagrant   

        vargant up

    В результате получаем 2 ВМ: master и slave

2. Установка mysql

        На обеих ВМ запускаю:
      
        apt update  
        apt install mysql-server  

3. Настройка конфигов

   Копирую конфиг файлы в /etc/mysql/mysql.conf.d/ из папки в репозитарии conf.d
   -  master
     ```
      [mysqld]
      server-id = 1
      log-bin = mysql-bin
      binlog_format = row
      # включаем gtid-mode
      gtid-mode=ON
      enforce-gtid-consistency
      log-replica-updates
     ``` 

   -  slave
     ```
      [mysqld]
      # server-id на реплике должен отличаться от мастера
      server-id = 2
      log-bin = mysql-bin
      relay-log = relay-log-server
      read-only = ON
      # включаем gtid-mode
      gtid-mode=ON
      enforce-gtid-consistency
      log-replica-updates
      # исключаем репликацию таблиц
      replicate-ignore-table=bet.events_on_demand
      replicate-ignore-table=bet.v_same_event
     ``` 

    Перезапускаю сервис для применения конфигов:

    root@slave:/etc# systemctl restart mysql.service

    Проверяю применение параметров:

    ```
    mysql> SELECT @@server_id;
    +-------------+
    | @@server_id |
    +-------------+
    |           2 |
    +-------------+
    1 row in set (0.00 sec)

    mysql> SHOW VARIABLES LIKE 'gtid_mode';
    +---------------+-------+
    | Variable_name | Value |
    +---------------+-------+
    | gtid_mode     | ON    |
    +---------------+-------+
    1 row in set (0.00 sec)

    ```

4. Настройка master

  Создаю новую БД bet и загружаю в нее данные из дампа:

  ```
  mysql> CREATE DATABASE bet;
  Query OK, 1 row affected (0.03 sec)

  root@master:/# mysql -uroot -p -D bet < /vagrant/bet.dmp

  mysql> use bet;
  Reading table information for completion of table and column names
  You can turn off this feature to get a quicker startup with -A

  Database changed
  mysql> show tables;
  +------------------+
  | Tables_in_bet    |
  +------------------+
  | bookmaker        |
  | competition      |
  | events_on_demand |
  | market           |
  | odds             |
  | outcome          |
  | v_same_event     |
  +------------------+
  7 rows in set (0.00 sec)
  ```

5. Создаю пользователя для репликацию и выдаю ему права

  ```
  CREATE USER repl@'%' IDENTIFIED BY 'Otus1234'; 
  GRANT REPLICATION SLAVE ON *.* TO repl@'%';
  ```

  Проверяю доступность порта:

  ```
  root@master:/etc/mysql/mysql.conf.d# ss -tulnp
  Netid         State          Recv-Q         Send-Q                    Local Address:Port                  Peer Address:Port           Process                                             
  udp           UNCONN         0              0                      10.0.2.15%enp0s3:68                         0.0.0.0:*             users: (("systemd-network",pid=1822,fd=18))         
  tcp           LISTEN         0              128                             0.0.0.0:22                         0.0.0.0:*             users:(("sshd",  pid=799,fd=3))                      
  tcp           LISTEN         0              151                             0.0.0.0:3306                       0.0.0.0:*             users:(("mysqld",  pid=26171,fd=23))                 
  tcp           LISTEN         0              128                                [::]:22                            [::]:*             users:(("sshd",  pid=799,fd=4))                      
  tcp           LISTEN         0              70                                    *:33060                            *:*             users:(("mysqld",  pid=26171,fd=21))                 

  ```

6. Создаю дамп БД, исключая ненужные таблицы, и копирую на slave.

  ```
  root@master:/etc/mysql/mysql.conf.d# mysqldump --all-databases --triggers --routines --master-data --ignore-table=bet.events_on_demand --ignore-table=bet.v_same_event -uroot -p > /tmp/master.sql
  WARNING: --master-data is deprecated and will be removed in a future version. Use --source-data instead.
  Enter password: 
  Warning: A partial dump from a server that has GTIDs will by default include the GTIDs of all transactions, even those that changed suppressed parts of the database. If you don't want to restore GTIDs, pass --set-gtid-purged=OFF. To make a complete dump, pass --all-databases --triggers --routines --events.
  ```

7. Заливаю дамп в mysql на slave:

  ```
  root@slave:/vagrant# mysql -u root -p < ./master.sql
  Enter password: 
  root@slave:/vagrant# mysql -u root -p
  Enter password: 
  Welcome to the MySQL monitor.  Commands end with ; or \g.
  Your MySQL connection id is 9
  Server version: 8.0.43-0ubuntu0.22.04.2 (Ubuntu)

  Copyright (c) 2000, 2025, Oracle and/or its affiliates.

  Oracle is a registered trademark of Oracle Corporation and/or its
  affiliates. Other names may be trademarks of their respective
  owners.

  Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

  mysql> show databases;
  +--------------------+
  | Database           |
  +--------------------+
  | bet                |
  | information_schema |
  | mysql              |
  | performance_schema |
  | sys                |
  +--------------------+
  5 rows in set (0.00 sec)

  mysql> use bet;
  Reading table information for completion of table and column names
  You can turn off this feature to get a quicker startup with -A

  Database changed
  mysql> show tables;
  +---------------+
  | Tables_in_bet |
  +---------------+
  | bookmaker     |
  | competition   |
  | market        |
  | odds          |
  | outcome       |
  +---------------+
  5 rows in set (0.00 sec)
  ```

8. Включаю репликаци и проверяю статус.

  ```
  mysql> CHANGE REPLICATION SOURCE TO SOURCE_HOST='192.168.57.10', SOURCE_USER='repl', SOURCE_PASSWORD='Otus1234', SOURCE_AUTO_POSITION = 1, GET_SOURCE_PUBLIC_KEY = 1;
  Query OK, 0 rows affected, 2 warnings (0.02 sec)

  mysql> start replica;
  Query OK, 0 rows affected (0.02 sec)

  mysql> show replica status\G;
  *************************** 1. row ***************************
               Replica_IO_State: Waiting for source to send event
                    Source_Host: 192.168.57.10
                    Source_User: repl
                    Source_Port: 3306
                  Connect_Retry: 60
                Source_Log_File: mysql-bin.000259
            Read_Source_Log_Pos: 157
                 Relay_Log_File: relay-log-server.000002
                  Relay_Log_Pos: 373
          Relay_Source_Log_File: mysql-bin.000259
             Replica_IO_Running: Yes
            Replica_SQL_Running: Yes
                Replicate_Do_DB: 
            Replicate_Ignore_DB: 
             Replicate_Do_Table: 
         Replicate_Ignore_Table: bet.events_on_demand,bet.v_same_event
        Replicate_Wild_Do_Table: 
    Replicate_Wild_Ignore_Table: 
                     Last_Errno: 0
                     Last_Error: 
                   Skip_Counter: 0
            Exec_Source_Log_Pos: 157
                Relay_Log_Space: 584
                Until_Condition: None
                 Until_Log_File: 
                  Until_Log_Pos: 0
             Source_SSL_Allowed: No
             Source_SSL_CA_File: 
             Source_SSL_CA_Path: 
                Source_SSL_Cert: 
              Source_SSL_Cipher: 
                 Source_SSL_Key: 
          Seconds_Behind_Source: 0
  Source_SSL_Verify_Server_Cert: No
                  Last_IO_Errno: 0
                  Last_IO_Error: 
                 Last_SQL_Errno: 0
                 Last_SQL_Error: 
    Replicate_Ignore_Server_Ids: 
               Source_Server_Id: 1
                    Source_UUID: ca0c9edb-b33f-11f0-9098-02291e731fd5
               Source_Info_File: mysql.slave_master_info
                      SQL_Delay: 0
            SQL_Remaining_Delay: NULL
      Replica_SQL_Running_State: Replica has read all relay log; waiting for more updates
             Source_Retry_Count: 86400
                    Source_Bind: 
        Last_IO_Error_Timestamp: 
       Last_SQL_Error_Timestamp: 
                 Source_SSL_Crl: 
             Source_SSL_Crlpath: 
             Retrieved_Gtid_Set: 
              Executed_Gtid_Set: ca0c9edb-b33f-11f0-9098-02291e731fd5:1-144
                  Auto_Position: 1
           Replicate_Rewrite_DB: 
                   Channel_Name: 
             Source_TLS_Version: 
         Source_public_key_path: 
          Get_Source_public_key: 1
              Network_Namespace: 
  1 row in set (0.00 sec)
  ```

9. Проверяю работу репликации.

  На master добавляю строку в таблицу bookmaker

  ```
  mysql> SELECT * FROM bookmaker;
  +----+----------------+
  | id | bookmaker_name |
  +----+----------------+
  |  4 | betway         |
  |  5 | bwin           |
  |  6 | ladbrokes      |
  |  3 | unibet         |
  +----+----------------+
  4 rows in set (0.00 sec)

  mysql> INSERT INTO bookmaker (id,bookmaker_name) VALUES(1,'1xbet');
  Query OK, 1 row affected (0.03 sec)

  mysql> SELECT * FROM bookmaker;
  +----+----------------+
  | id | bookmaker_name |
  +----+----------------+
  |  1 | 1xbet          |
  |  4 | betway         |
  |  5 | bwin           |
  |  6 | ladbrokes      |
  |  3 | unibet         |
  +----+----------------+
  5 rows in set (0.00 sec)
  ```

  На slave проверяю, что строка появилась и изменился Retrieved_Gtid_Set в статусе репликации:

  ```
  mysql> SELECT * FROM bookmaker;
  +----+----------------+
  | id | bookmaker_name |
  +----+----------------+
  |  1 | 1xbet          |
  |  4 | betway         |
  |  5 | bwin           |
  |  6 | ladbrokes      |
  |  3 | unibet         |
  +----+----------------+
  5 rows in set (0.00 sec)

  mysql> show replica status\G;
  *************************** 1. row ***************************
      ...
             Retrieved_Gtid_Set: ca0c9edb-b33f-11f0-9098-02291e731fd5:145
              Executed_Gtid_Set: ca0c9edb-b33f-11f0-9098-02291e731fd5:1-145
      ...              

  ```

  Проверяю добавление строки в таблицу, которая игнорируется:

  На master:
  ```
  mysql> insert into events_on_demand (id,sortname) values('59','Test');
  Query OK, 1 row affected (0.02 sec)
  ```  

  На slave таблица не появилась, но Retrieved_Gtid_Set изменился:

  ```
  mysql> show tables;
  +---------------+
  | Tables_in_bet |
  +---------------+
  | bookmaker     |
  | competition   |
  | market        |
  | odds          |
  | outcome       |
  +---------------+
  5 rows in set (0.01 sec)

  mysql> show replica status\G;
  *************************** 1. row ***************************

             Retrieved_Gtid_Set: ca0c9edb-b33f-11f0-9098-02291e731fd5:145-146
              Executed_Gtid_Set: ca0c9edb-b33f-11f0-9098-02291e731fd5:1-146
  ```