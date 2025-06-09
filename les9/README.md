## Systemd — создание unit-файла

### Домашнее задание

1. Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/default).
2. Установить spawn-fcgi и создать unit-файл (spawn-fcgi.sevice) с помощью переделки init-скрипта (https://gist.github.com/cea2k/1318020).
3. Доработать unit-файл Nginx (nginx.service) для запуска нескольких инстансов сервера с разными конфигурационными файлами одновременно

Задание выполняется на ОС Ubuntu 22.04

#### 1. Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова

* Создаю файл с параметрами конфигурации

root@liv-vm:/var/log# cat /etc/default/watchlog
WORD="ERROR"
LOG=/var/log/syslog

* Создаю скрипт 

root@liv-vm:/var/log# cat /opt/watchlog.sh 
#!/bin/bash

WORD=$1
LOG=$2
DATE=`date`

if grep $WORD $LOG &> /dev/null
then
logger "$DATE: I found word, Master!"
else
exit 0
fi

* Добавляю права на запуск файла

root@liv-vm:/var/log# chmod +x /opt/watchlog.sh

* Создаю юнит для сервиса

root@liv-vm:/var/log# cat /etc/systemd/system/watchlog.service
[Unit]
Description=My watchlog service

[Service]
Type=oneshot
EnvironmentFile=/etc/default/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG

* Создаю юнит для таймера

root@liv-vm:/var/log# cat /etc/systemd/system/watchlog.timer
[Unit]
Description=Run watchlog script every 30 second

[Timer]
# Run every 30 second
OnUnitActiveSec=30s
Unit=watchlog.service

[Install]
WantedBy=multi-user.target

* Запускаю таймер 

root@liv-vm:/var/log# systemctl start watchlog.timer
root@liv-vm:/var/log# systemctl status watchlog.timer
● watchlog.timer
     Loaded: loaded (/etc/systemd/system/watchlog.timer; disabled; vendor preset: enabled)
     Active: active (elapsed) since Mon 2025-06-09 12:28:10 +03; 17s ago
    Trigger: n/a
   Triggers: ● watchlog.service

июн 09 12:28:10 liv-vm systemd[1]: Started watchlog.timer.
июн 09 12:28:27 liv-vm systemd[1]: /etc/systemd/system/watchlog.timer:1: Assignment outside of section. Ignoring.
июн 09 12:28:27 liv-vm systemd[1]: /etc/systemd/system/watchlog.timer:2: Assignment outside of section. Ignoring.

* Проверяю работу

Стартую сервис, чтобы активировать работу таймера

root@liv-vm:/var/log# systemctl start watchlog.service

Через некоторый период времени смотрим syslog

root@liv-vm:/var/log# tail -200 /var/log/syslog | grep word
Jun  9 14:50:47 liv-vm root: Пн 09 июн 2025 14:50:47 +03: I found word, Master!
Jun  9 14:51:17 liv-vm root: Пн 09 июн 2025 14:51:17 +03: I found word, Master!
Jun  9 14:52:06 liv-vm root: Пн 09 июн 2025 14:52:06 +03: I found word, Master!
Jun  9 14:52:43 liv-vm root: Пн 09 июн 2025 14:52:43 +03: I found word, Master!
Jun  9 14:53:29 liv-vm root: Пн 09 июн 2025 14:53:29 +03: I found word, Master!
Jun  9 14:54:27 liv-vm root: Пн 09 июн 2025 14:54:27 +03: I found word, Master!
Jun  9 14:55:31 liv-vm root: Пн 09 июн 2025 14:55:30 +03: I found word, Master!


#### 2. Установить spawn-fcgi и создать unit-файл (spawn-fcgi.sevice) с помощью переделки init-скрипта (https://gist.github.com/cea2k/1318020).

* Устанавливаем spawn-fcgi и необходимые для него пакеты:

root@ubuntu1:~# apt install spawn-fcgi php php-cgi php-cli apache2 libapache2-mod-fcgid -y

* Cоздаю файл с настройками для будущего сервиса в файле /etc/spawn-fcgi/fcgi.conf

root@ubuntu1:/etc/spawn-fcgi# cat fcgi.conf
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u www-data -g www-data -s $SOCKET -S -M 0600 -C 32 -F 1 -- /usr/bin/php-cgi"

* Создаю юнит-файл

root@ubuntu1:/etc/spawn-fcgi# cat /etc/systemd/system/spawn-fcgi.service
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/spawn-fcgi/fcgi.conf
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target

* Проверяю работу

root@ubuntu1:/etc/spawn-fcgi# systemctl start spawn-fcgi
root@ubuntu1:/etc/spawn-fcgi# systemctl status spawn-fcgi
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
     Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; preset: enabled)
     Active: active (running) since Mon 2025-06-09 12:55:24 UTC; 8s ago
   Main PID: 70893 (php-cgi)
      Tasks: 33 (limit: 2136)
     Memory: 14.7M (peak: 14.8M)
        CPU: 39ms
     CGroup: /system.slice/spawn-fcgi.service
             ├─70893 /usr/bin/php-cgi
             ├─70894 /usr/bin/php-cgi
             ├─70895 /usr/bin/php-cgi
             ├─70896 /usr/bin/php-cgi
             ├─70897 /usr/bin/php-cgi
             ├─70898 /usr/bin/php-cgi
             ├─70899 /usr/bin/php-cgi
             ├─70900 /usr/bin/php-cgi
             ├─70901 /usr/bin/php-cgi
             ├─70902 /usr/bin/php-cgi
             ├─70903 /usr/bin/php-cgi
             ├─70904 /usr/bin/php-cgi
             ├─70905 /usr/bin/php-cgi
             ├─70906 /usr/bin/php-cgi
             ├─70907 /usr/bin/php-cgi
             ├─70908 /usr/bin/php-cgi
             ├─70909 /usr/bin/php-cgi
             ├─70910 /usr/bin/php-cgi
             ├─70911 /usr/bin/php-cgi
             ├─70912 /usr/bin/php-cgi
             ├─70913 /usr/bin/php-cgi
             ├─70914 /usr/bin/php-cgi
             ├─70915 /usr/bin/php-cgi
             ├─70916 /usr/bin/php-cgi
             ├─70917 /usr/bin/php-cgi
             ├─70918 /usr/bin/php-cgi
             ├─70919 /usr/bin/php-cgi
             ├─70920 /usr/bin/php-cgi
             ├─70921 /usr/bin/php-cgi
             ├─70922 /usr/bin/php-cgi
             ├─70923 /usr/bin/php-cgi
             ├─70924 /usr/bin/php-cgi
             └─70925 /usr/bin/php-cgi

Jun 09 12:55:24 ubuntu1 systemd[1]: Started spawn-fcgi.service - Spawn-fcgi startup service by Otus.


#### 3. Доработать unit-файл Nginx (nginx.service) для запуска нескольких инстансов сервера с разными конфигурационными файлами одновременно.

* Установим Nginx из стандартного репозитория

root@ubuntu1:/etc/spawn-fcgi# apt install nginx -y

* Для запуска нескольких экземпляров сервиса модифицируем исходный service для использования различной конфигурации, а также PID-файлов. Для этого создадим новый Unit для работы с шаблонами (/etc/systemd/system/nginx@.service):

root@ubuntu1:/etc/spawn-fcgi# cat /etc/systemd/system/nginx@.service
[Unit]
Description=A high performance web server and a reverse proxy server
Documentation=man:nginx(8)
After=network.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx-%I.pid
ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx-%I.conf -q -g 'daemon on; master_process on;'
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx-%I.conf -g 'daemon on; master_process on;'
ExecReload=/usr/sbin/nginx -c /etc/nginx/nginx-%I.conf -g 'daemon on; master_process on;' -s reload
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx-%I.pid
TimeoutStopSec=5
KillMode=mixed

[Install]
WantedBy=multi-user.target

* создаю два файла конфигурации (/etc/nginx/nginx-first.conf, /etc/nginx/nginx-second.conf). Формирую из стандартного конфига /etc/nginx/nginx.conf, с модификацией путей до PID-файлов и разделением по портам:

pid /run/nginx-first.pid;

http {
…
	server {
		listen 9001;
	}

* Проверяем работу сервисов

root@ubuntu1:/etc/spawn-fcgi# systemctl start nginx@first.service
root@ubuntu1:/etc/spawn-fcgi# systemctl start nginx@second.service

root@ubuntu1:/etc/spawn-fcgi# systemctl status nginx@second.service
● nginx@second.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/etc/systemd/system/nginx@.service; disabled; preset: enabled)
     Active: active (running) since Mon 2025-06-09 13:40:43 UTC; 4s ago
       Docs: man:nginx(8)
    Process: 71642 ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx-second.conf -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
    Process: 71644 ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx-second.conf -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
   Main PID: 71645 (nginx)
      Tasks: 2 (limit: 2136)
     Memory: 1.7M (peak: 1.9M)
        CPU: 17ms
     CGroup: /system.slice/system-nginx.slice/nginx@second.service
             ├─71645 "nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx-second.conf -g daemon on; master_process on;"
             └─71646 "nginx: worker process"

Jun 09 13:40:43 ubuntu1 systemd[1]: Starting nginx@second.service - A high performance web server and a reverse proxy server...
Jun 09 13:40:43 ubuntu1 systemd[1]: Started nginx@second.service - A high performance web server and a reverse proxy server.
root@ubuntu1:/etc/spawn-fcgi# ss -tnulp | grep nginx
tcp   LISTEN 0      511              0.0.0.0:9002      0.0.0.0:*    users:(("nginx",pid=71646,fd=5),("nginx",pid=71645,fd=5))                                                                                                                                           
tcp   LISTEN 0      511              0.0.0.0:9001      0.0.0.0:*    users:(("nginx",pid=71543,fd=5),("nginx",pid=71542,fd=5))                                                                                                                                           
root@ubuntu1:/etc/spawn-fcgi# ps afx | grep nginx
  71653 pts/1    S+     0:00                          \_ grep --color=auto nginx
  71542 ?        Ss     0:00 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx-first.conf -g daemon on; master_process on;
  71543 ?        S      0:00  \_ nginx: worker process
  71645 ?        Ss     0:00 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx-second.conf -g daemon on; master_process on;
  71646 ?        S      0:00  \_ nginx: worker process
  
  


