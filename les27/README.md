## Резервное копирование

### Задание

Настроить стенд Vagrant с двумя виртуальными машинами: backup_server и client.


Настроить удаленный бекап каталога /etc c сервера client при помощи borgbackup. Резервные копии должны соответствовать следующим критериям:

* директория для резервных копий /var/backup. Это должна быть отдельная точка монтирования. В данном случае для демонстрации размер не принципиален, достаточно будет и 2GB;
* репозиторий дле резервных копий должен быть зашифрован ключом или паролем - на ваше усмотрение;
* имя бекапа должно содержать информацию о времени снятия бекапа;
* глубина бекапа должна быть год, хранить можно по последней копии на конец месяца, кроме последних трех.
* Последние три месяца должны содержать копии на каждый день. Т.е. должна быть правильно настроена политика удаления старых бэкапов;
* резервная копия снимается каждые 5 минут. Такой частый запуск в целях демонстрации;
* написан скрипт для снятия резервных копий. Скрипт запускается из соответствующей Cron джобы, либо systemd timer-а - на ваше усмотрение;
* настроено логирование процесса бекапа. Для упрощения можно весь вывод перенаправлять в logger с соответствующим тегом. Если настроите не в syslog, то обязательна ротация логов.


### Решение

* Тестовый стенд:

    backup 192.168.56.160 Ubuntu 22.04  
    client 192.168.56.150 Ubuntu 22.04  

* Развертывание стенда

    - Запускаем создание ВМ через Vagrant   

        vargant up

    - Настраиваем ВМ при помощи Ansible

        ansible-playbook borg1.yml

* Проверка работы
    - На VM backup проверяю монтирование отдельного тома
    ```
    vagrant@backup:~$ sudo -i  
    root@backup:~# df -h  
    Filesystem      Size  Used Avail Use% Mounted on  
    ...  
    /dev/sdc1       2.0G  1.1M  1.9G   1% /var/backup  
    ```

    - На VM client проверяю работу таймера

    ```
    root@client:~# systemctl list-timers 
    NEXT                        LEFT              LAST                        PASSED       UNIT                           ACTIVATES                       
    Tue 2025-09-02 06:49:35 UTC 1min 35s left     Tue 2025-09-02 06:44:35 UTC 3min 24s ago borg-backup.timer              borg-backup.service
    ```

    - На VM client проверяю список бэкапов

    ```
    root@client:~# borg list borg@192.168.56.160:/var/backup/client
    Enter passphrase for key ssh://borg@192.168.56.160/var/backup/client: 
    Enter passphrase for key ssh://borg@192.168.56.160/var/backup/client: 
    etc-2025-09-02_06:39:18              Tue, 2025-09-02 06:39:19 [d77db24dbca908ac6363388cd13bc6f555575381d59c06ed8e0825b27f9356a9]
    etc-2025-09-02_06:44:35              Tue, 2025-09-02 06:44:36 [ee4baf4e1afc05e34448d1f8aa2524040ff6eb5f210938ac48677c793b8ebae0]
    etc-2025-09-02_06:49:45              Tue, 2025-09-02 06:49:46 [75707a24a978de4588a8716393e7da619ac01ee1dea232c409697e2eb8a711e4]
    ```

    - Проверяю запись в syslog информации о бэкапе
    
    root@client:~# journalctl -e

    ```
    Sep 02 06:54:45 client systemd[1]: Starting Borg Backup...
    Sep 02 06:54:46 client borg[3637]: ------------------------------------------------------------------------------
    Sep 02 06:54:46 client borg[3637]: Repository: ssh://borg@192.168.56.160/var/backup/client
    Sep 02 06:54:46 client borg[3637]: Archive name: etc-2025-09-02_06:54:45
    Sep 02 06:54:46 client borg[3637]: Archive fingerprint: 568cb28cdcb3c8af507b8a5b23795a7c1ecf6c8f6837833d059da5a53451a26e
    Sep 02 06:54:46 client borg[3637]: Time (start): Tue, 2025-09-02 06:54:46
    Sep 02 06:54:46 client borg[3637]: Time (end):   Tue, 2025-09-02 06:54:46
    Sep 02 06:54:46 client borg[3637]: Duration: 0.06 seconds
    Sep 02 06:54:46 client borg[3637]: Number of files: 702
    Sep 02 06:54:46 client borg[3637]: Utilization of max. archive size: 0%
    Sep 02 06:54:46 client borg[3637]: ------------------------------------------------------------------------------
    Sep 02 06:54:46 client borg[3637]:                        Original size      Compressed size    Deduplicated size
    Sep 02 06:54:46 client borg[3637]: This archive:                2.14 MB            957.10 kB                572 B
    Sep 02 06:54:46 client borg[3637]: All archives:                8.56 MB              3.83 MB            997.97 kB
    Sep 02 06:54:46 client borg[3637]:                        Unique chunks         Total chunks
    Sep 02 06:54:46 client borg[3637]: Chunk index:                     667                 2768
    Sep 02 06:54:46 client borg[3637]: ------------------------------------------------------------------------------
    Sep 02 06:54:48 client systemd[1]: borg-backup.service: Deactivated successfully.
    Sep 02 06:54:48 client systemd[1]: Finished Borg Backup.
    ```

* Выполняю тестовое восстановление файла из бэкапа

```
    root@client:~# borg extract borg@192.168.56.160:/var/backup/client::etc-2025-09-02_07:00:45 etc/passwd
    Enter passphrase for key ssh://borg@192.168.56.160/var/backup/client: 
    root@client:~# ls -l ./etc/*
    -rw-r--r-- 1 root root 1814 Sep  2 06:38 ./etc/passwd
```

