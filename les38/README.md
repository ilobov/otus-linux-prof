## LDAP на базе FreeIPA

### Задание

1) Установить FreeIPA
2) Написать Ansible-playbook для конфигурации клиента

Дополнительное задание
3)* Настроить аутентификацию по SSH-ключам
4)** Firewall должен быть включен на сервере и на клиенте


Формат сдачи ДЗ - vagrant + ansible


### Решение

* Развертывание стенда

    - Запускаем создание ВМ через Vagrant   

        vargant up


#### Проверка работы 

  1. Проверяем IPA server

    Проверяем статус сервера
  
    ```
    [root@ipa ~]# ipactl status
    Directory Service: RUNNING
    krb5kdc Service: RUNNING
    kadmin Service: RUNNING
    httpd Service: RUNNING
    ipa-custodia Service: RUNNING
    pki-tomcatd Service: RUNNING
    ipa-otpd Service: RUNNING
    ipa: INFO: The ipactl command was successful
    [root@ipa ~]# kinit admin
    Password for admin@OTUS.LAN: 
    [root@ipa ~]# klist
    Ticket cache: KCM:0
    Default principal: admin@OTUS.LAN
    ```

    Проверяем возможность получения Kerberos ticket

    ```
    [root@ipa ~]# kinit admin
    Password for admin@OTUS.LAN: 
    [root@ipa ~]# klist
    Ticket cache: KCM:0
    Default principal: admin@OTUS.LAN

    Valid starting       Expires              Service principal
    10/08/2025 08:22:03  10/09/2025 07:37:31  krbtgt/OTUS.LAN@OTUS.LAN
    ```

    Проверяем web-интерфейс

    На хостовой машине в /etc/hosts добавляем строку:

    192.168.57.10 ipa.otus.lan

    Подключаемся в браузере по адресу https://ipa.otus.lan. Вводим пользователя admin и пароль. 

    ![Web ipa server](https://github.com/ilobov/otus-linux-prof/blob/main/les38/ipa.png)

  2. Проверяем IPA клиента

    Авторизируемся на сервере: kinit admin
    ```
    [root@client2 ~]# kinit admin
    Password for admin@OTUS.LAN: 
    [root@client2 ~]# klist
    Ticket cache: KCM:0
    Default principal: admin@OTUS.LAN

    Valid starting       Expires              Service principal
    10/08/2025 10:46:06  10/09/2025 10:26:25  krbtgt/OTUS.LAN@OTUS.LAN
    ```

    Добавляем пользователя otus-user

    ```
    root@client2 ~]# ipa user-add otus-user --first=Otus --last=User --password
    Password: 
    Enter Password again to verify: 
    ----------------------
    Added user "otus-user"
    ----------------------
      User login: otus-user
      First name: Otus
      Last name: User
      Full name: Otus User
      Display name: Otus User
      Initials: OU
      Home directory: /home/otus-user
      GECOS: Otus User
      Login shell: /bin/sh
      Principal name: otus-user@OTUS.LAN
      Principal alias: otus-user@OTUS.LAN
      User password expiration: 20251008074636Z
      Email address: otus-user@otus.lan
      UID: 304000003
      GID: 304000003
      Password: True
      Member of groups: ipausers
      Kerberos keys available: True
    ```

    Проверяем подключение по пользователем otus-user

    ```
    [root@client2 ~]# kinit otus-user
    Password for otus-user@OTUS.LAN: 
    Password expired.  You must change it now.
    Enter new password: 
    Enter it again: 
    [root@client2 ~]# su - otus-user
    Creating home directory for otus-user.
    [otus-user@client2 ~]$ pwd
    /home/otus-user
    [otus-user@client2 ~]$ id
    uid=304000003(otus-user) gid=304000003(otus-user) groups=304000003  (otus-user) context=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.  c1023
    ```