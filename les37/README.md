## Строим бонды и вланы

### Задание

Что нужно сделать?
в Office1 в тестовой подсети появляется сервера с доп интерфейсами и адресами
в internal сети testLAN:

testClient1 - 10.10.10.254
testClient2 - 10.10.10.254
testServer1- 10.10.10.1
testServer2- 10.10.10.1
Равести вланами:
testClient1 <-> testServer1
testClient2 <-> testServer2

Между centralRouter и inetRouter "пробросить" 2 линка (общая inernal сеть) и объединить их в бонд, проверить работу c отключением интерфейсов


Формат сдачи ДЗ - vagrant + ansible


### Решение

* Развертывание стенда

    - Запускаем создание ВМ через Vagrant   

        vargant up

* Схема сети

  ![Nets](https://github.com/ilobov/otus-linux-prof/blob/main/les37/net.png)

#### Проверка работы 

  1. Подключаюсь к client.

    * Проверка web1.dns.lab через master и slave zone
    ```
    [vagrant@client ~]$ nslookup web1.dns.lab 192.168.50.10
    Server:		192.168.50.10
    Address:	192.168.50.10#53

    Name:	web1.dns.lab
    Address: 192.168.50.15

    [vagrant@client ~]$ nslookup web1.dns.lab 192.168.50.11
    Server:		192.168.50.11
    Address:	192.168.50.11#53
    
    Name:	web1.dns.lab
    Address: 192.168.50.15
    ```

    * Проверка web2.dns.lab через master и slave zone

    ```
    [vagrant@client ~]$ nslookup web2.dns.lab 192.168.50.11
    Server:		192.168.50.11
    Address:	192.168.50.11#53

    ** server can't find web2.dns.lab: NXDOMAIN

    [vagrant@client ~]$ nslookup web2.dns.lab 192.168.50.10
    Server:		192.168.50.10
    Address:	192.168.50.10#53

    ** server can't find web2.dns.lab: NXDOMAIN
    ```

    * Проверка www.newdns.lab через master и slave zone

    ```
    [vagrant@client ~]$ nslookup www.newdns.lab 192.168.50.10
    Server:		192.168.50.10
    Address:	192.168.50.10#53

    Name:	www.newdns.lab
    Address: 192.168.50.16
    Name:	www.newdns.lab
    Address: 192.168.50.15

    [vagrant@client ~]$ nslookup www.newdns.lab 192.168.50.11
    Server:		192.168.50.11
    Address:	192.168.50.11#53

    Name:	www.newdns.lab
    Address: 192.168.50.16
    Name:	www.newdns.lab
    Address: 192.168.50.15
    ```

  Для client в домене dns.lab виден web1 и не виден web2. В домене newdns.lab www ссылается на 2 адреса.

  2. Подключаюсь к client2.

    * Проверка web1.dns.lab через master и slave zone
    ```
    [vagrant@client2 ~]$ nslookup web1.dns.lab 192.168.50.10
    Server:		192.168.50.10
    Address:	192.168.50.10#53

    Name:	web1.dns.lab
    Address: 192.168.50.15

    [vagrant@client2 ~]$ nslookup web1.dns.lab 192.168.50.11
    Server:		192.168.50.11
    Address:	192.168.50.11#53

    Name:	web1.dns.lab
    Address: 192.168.50.15
    ```

    * Проверка web2.dns.lab через master и slave zone

    ```
    [vagrant@client2 ~]$ nslookup web2.dns.lab 192.168.50.11
    Server:		192.168.50.11
    Address:	192.168.50.11#53

    Name:	web2.dns.lab
    Address: 192.168.50.16

    [vagrant@client2 ~]$ nslookup web2.dns.lab 192.168.50.10
    Server:		192.168.50.10
    Address:	192.168.50.10#53

    Name:	web2.dns.lab
    Address: 192.168.50.16
    ```

    * Проверка www.newdns.lab через master и slave zone

    ```
    [vagrant@client2 ~]$ dig @192.168.50.10 newdns.lab

    ; <<>> DiG 9.16.23-RH <<>> @192.168.50.10 newdns.lab
    ; (1 server found)
    ;; global options: +cmd
    ;; Got answer:
    ;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 50019
    ;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

    ;; OPT PSEUDOSECTION:
    ; EDNS: version: 0, flags:; udp: 1232
    ; COOKIE: fdcf93418222117a0100000068de3d253d0c4934fd017765 (good)
    ;; QUESTION SECTION:
    ;newdns.lab.			IN	A

    ;; AUTHORITY SECTION:
    .			10770	IN	SOA	a.root-servers.net. nstld.verisign-grs.com. 2025100200 1800 900 604800 86400

    ;; Query time: 12 msec
    ;; SERVER: 192.168.50.10#53(192.168.50.10)
    ;; WHEN: Thu Oct 02 08:51:49 UTC 2025
    ;; MSG SIZE  rcvd: 142

    [vagrant@client2 ~]$ dig @192.168.50.11 newdns.lab

    ; <<>> DiG 9.16.23-RH <<>> @192.168.50.11 newdns.lab
    ; (1 server found)
    ;; global options: +cmd
    ;; Got answer:
    ;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 11083
    ;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

    ;; OPT PSEUDOSECTION:
    ; EDNS: version: 0, flags:; udp: 1232
    ; COOKIE: a03afa289302a4a80100000068de3d6657ce7c509b0b624a (good)
    ;; QUESTION SECTION:
    ;newdns.lab.			IN	A

    ;; AUTHORITY SECTION:
    .			10800	IN	SOA	a.root-servers.net. nstld.verisign-grs.com. 2025100200 1800 900 604800 86400

    ;; Query time: 460 msec
    ;; SERVER: 192.168.50.11#53(192.168.50.11)
    ;; WHEN: Thu Oct 02 08:52:54 UTC 2025
    ;; MSG SIZE  rcvd: 142
    ```

  Для client2 в домене dns.lab виден web1 и web2. Домен newdns.lab не виден совсем.