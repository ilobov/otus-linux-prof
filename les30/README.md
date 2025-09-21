## Сценарии iptables

### Задание

1. Реализовать knocking port
  - centralRouter может попасть на ssh inetrRouter через knock скрипт(пример в материалах)
2. Добавить inetRouter2, который виден(маршрутизируется (host-only тип сети для виртуалки)) с хоста или форвардится порт через локалхост.
3. Запустить nginx на centralServer.
4. Пробросить 80й порт на inetRouter2 8080.
5. Дефолт в инет оставить через inetRouter.


### Решение

Для решиния задания используем схему сети из задаич "Разворачиваем сетевую лабораторию". Так как в задании не используются office1Router, office2Router, office1Server, office2Server исключаю их из схемы и добавляю ВМ inetRouter2.

Использую подсеть 192.168.255.12/30 для связи (centralRouter - inetRouter2)


* Развертывание стенда

    - Запускаем создание ВМ через Vagrant   

        vargant up

    - Настраиваем ВМ при помощи Ansible

        ansible-playbook nets.yml

* Проверка работа

Для открытия порта  ssh использую последовательность портов 11111 - 22222 - 33333 - 44444

С сервера centralRouter выполняю проверку:

```
root@centralRouter:~# telnet 192.168.255.1 22
Trying 192.168.255.1...

Порт 22 не доступен.

root@centralRouter:~# for p in 11111 22222 33333 44444 ; do netcat -w1 192.168.255.1 "$p" ; done

root@centralRouter:~# telnet 192.168.255.1 22
Trying 192.168.255.1...
Connected to 192.168.255.1.
Escape character is '^]'.
SSH-2.0-OpenSSH_8.9p1 Ubuntu-3ubuntu0.13

После обращения к последовательности портов появился доступ к порту 22 на 30 секунд

```

Проверка проброса порта. 

С хостовой машины обращаюсь к inetRouter2 порт 8080

```
liv@liv-HP:~/otus/work/les30$ curl http://192.168.50.13:8080
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

Получаю ответ от сервера centralServer, который работает на порту 80
```
vagrant@centralServer:~$ ss -tulnp
Netid             State              Recv-Q             Send-Q                            Local Address:Port                          Peer Address:Port             Process             
udp               UNCONN             0                  0                                 127.0.0.53%lo:53                                 0.0.0.0:*                                    
udp               UNCONN             0                  0                              10.0.2.15%enp0s3:68                                 0.0.0.0:*                                    
tcp               LISTEN             0                  4096                              127.0.0.53%lo:53                                 0.0.0.0:*                                    
tcp               LISTEN             0                  511                                     0.0.0.0:80                                 0.0.0.0:*                                    
tcp               LISTEN             0                  128                                     0.0.0.0:22                                 0.0.0.0:*                                    
tcp               LISTEN             0                  511                                        [::]:80                                    [::]:*                                    
tcp               LISTEN             0                  128                                        [::]:22                                    [::]:* 
```
