## Настраиваем центральный сервер для сбора логов

### Задание

1. В Vagrant разворачиваем 2 виртуальные машины web и log
2. на web настраиваем nginx
3. на log настраиваем центральный лог сервер на любой системе на выбор
journald;
rsyslog;
elk.
4. настраиваем аудит, следящий за изменением конфигов nginx 

Все критичные логи с web должны собираться и локально и удаленно.
Все логи с nginx должны уходить на удаленный сервер (локально только критичные).
Логи аудита должны также уходить на удаленную систему.


### Решение

* Тестовый стенд:

    web 192.168.56.10 Ubuntu 22.04  
    log 192.168.56.15 Ubuntu 22.04  

* Развертывание стенда

    - Запускаем создание ВМ через Vagrant   

        vargant up

* Проверка работы
    - Access log  
        Попробуем несколько раз зайти по адресу http://192.168.56.10
        Подключаемся на VM log. Проверяем наличие файла /var/log/rsyslog/web/nginx_access.log  и его содержимое  

        ```
        root@log:/var/log/rsyslog/web# ls  
        audispd.log  nginx_access.log  
        root@log:/var/log/rsyslog/web# tail -5 ./nginx_access.log   
        Sep  7 16:58:11 web nginx_access: 192.168.56.1 - - [07/Sep/2025:16:58:11 +0000] "GET / HTTP/1.1" 200 396 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36"  
        Sep  7 16:58:11 web nginx_access: 192.168.56.1 - - [07/Sep/2025:16:58:11 +0000] "GET /favicon.ico HTTP/1.1" 404 197 "http://192.168.56.10/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36"  
        Sep  7 16:58:11 web nginx_access: 192.168.56.1 - - [07/Sep/2025:16:58:11 +0000] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36"  
        Sep  7 16:58:12 web nginx_access: 192.168.56.1 - - [07/Sep/2025:16:58:12 +0000] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36"  
        Sep  7 16:58:13 web nginx_access: 192.168.56.1 - - [07/Sep/2025:16:58:13 +0000] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36"  
        ```
    - Error log  
        Подключаемся на VM web. Переименуем файл веб-страницы 
        mv /var/www/html/index.nginx-debian.html /var/www/html/index.nginx-debian.html.orig
        Попробуем зайти по адресу http://192.168.56.10. Получаем ошибку 403.
        Подключаемся на VM log. Проверяем наличие файла /var/log/rsyslog/web/nginx_error.log  и его содержимое  

        ```
        root@log:/var/log/rsyslog/web# ls  
        audispd.log  nginx_access.log  nginx_error.log  
        root@log:/var/log/rsyslog/web# tail nginx_error.log  
        Sep  7 17:06:49 web nginx_error: 2025/09/07 17:06:49 [error] 4601#4601: *3 directory index of "/var/www/html/" is forbidden, client: 192.168.56.1, server: _, request: "GET / HTTP/1.1", host: "192.168.56.10"  
        ```
    
    - Audit log  
        Подключаемся на VM web. Добавляем несколько пустых строк в файл /etc/nginx/nginx.conf и сохраняем его.   
        Подключаемся на VM log. Проверяем наличие файла /var/log/rsyslog/web/audispd.log и его содержимое

        ```
        root@log:/var/log/rsyslog/web# ls  
        audispd.log  nginx_access.log  nginx_error.log  
        root@log:/var/log/rsyslog/web# tail -5 audispd.log  
        Sep  7 17:09:48 web audispd: type=SYSCALL msg=audit(1757264988.958:179): arch=c000003e syscall=188 success=yes exit=0 a0=558bf8303740 a1=7f65d2259000 a2=558bf8637d30 a3=1c items=1 ppid=4776 pid=4817 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts1 ses=5 comm="vi" exe="/usr/bin/vim.basic" subj=unconfined key=(null) ARCH=x86_64 SYSCALL=setxattr AUID="vagrant" UID="root" GID="root" EUID="root" SUID="root" FSUID="root" EGID="root" SGID="root" FSGID="root"  
        Sep  7 17:09:48 web audispd: type=CWD msg=audit(1757264988.958:179): cwd="/root"  
        Sep  7 17:09:48 web audispd: type=PATH msg=audit(1757264988.958:179): item=0 name="/etc/nginx/nginx.conf" inode=256060 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 nametype=NORMAL cap_fp=0 cap_fi=0 cap_fe=0 cap_fver=0 cap_frootid=0 OUID="root" OGID="root"  
        Sep  7 17:09:48 web audispd: type=PROCTITLE msg=audit(1757264988.958:179): proctitle=7669002F6574632F6E67696E782F6E67696E782E636F6E66  
        Sep  7 17:09:48 web audispd: type=EOE msg=audit(1757264988.958:179):  
        ```