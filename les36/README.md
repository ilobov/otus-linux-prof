## Настраиваем split-dns

### Задание

Что нужно сделать?

- взять стенд https://github.com/erlong15/vagrant-bind

- добавить еще один сервер client2

- завести в зоне dns.lab имена

  - web1 - смотрит на клиент1

  - web2 смотрит на клиент2

- завести еще одну зону newdns.lab

- завести в ней запись

- www - смотрит на обоих клиентов

- настроить split-dns

- клиент1 - видит обе зоны, но в зоне dns.lab только web1

- клиент2 видит только dns.lab

настроить все без выключения selinux*


Формат сдачи ДЗ - vagrant + ansible


### Решение

* Развертывание стенда

    - Запускаем создание ВМ через Vagrant   

        vargant up


#### 1.1 После запуска ВМ между узлами server, client поднят OpenVPN в режиме tap (на канальном уровне). 

  Замеряем скорость канал при помощи iperf3.
   - На хосте 1 запускаем iperf3 в режиме сервера: iperf3 -s & 
   - На хосте 2 запускаем iperf3 в режиме клиента и замеряем  скорость в туннеле: iperf3 -c 10.10.10.1 -t 40 -i 5

   ```
   root@client:/etc/openvpn# iperf3 -c 10.10.10.1 -t 40 -i 5
   Connecting to host 10.10.10.1, port 5201
   [  5] local 10.10.10.2 port 55766 connected to 10.10.10.1 port 5201
   [ ID] Interval           Transfer     Bitrate         Retr  Cwnd
   [  5]   0.00-5.00   sec   255 MBytes   428 Mbits/sec  890    236 KBytes       
   [  5]   5.00-10.00  sec   254 MBytes   426 Mbits/sec  277    187 KBytes       
   [  5]  10.00-15.00  sec   151 MBytes   254 Mbits/sec    1    435 KBytes       
   [  5]  15.00-20.00  sec   160 MBytes   268 Mbits/sec    0    642 KBytes       
   [  5]  20.00-25.00  sec   169 MBytes   283 Mbits/sec   41    600 KBytes       
   [  5]  25.00-30.00  sec   170 MBytes   285 Mbits/sec    0    786 KBytes       
   [  5]  30.00-35.00  sec   170 MBytes   285 Mbits/sec    0    886 KBytes       
   [  5]  35.00-40.00  sec   168 MBytes   281 Mbits/sec   56    724 KBytes       
   - - - - - - - - - - - - - - - - - - - - - - - - -
   [ ID] Interval           Transfer     Bitrate         Retr
   [  5]   0.00-40.00  sec  1.46 GBytes   314 Mbits/sec  1265             sender
   [  5]   0.00-40.04  sec  1.46 GBytes   313 Mbits/sec                  receiver
   ```

#### 1.2 Меняем режим работы OpenVPN на tun. Для этого запускаем:

ansible-playbook ansible/tun.yml -i ansible/hosts -e "host_key_checking=false" -l all

Повторяем замер скорости канала:

```
root@client:/etc/openvpn# iperf3 -c 10.10.10.1 -t 40 -i 5
Connecting to host 10.10.10.1, port 5201
[  5] local 10.10.10.2 port 39346 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-5.00   sec   269 MBytes   452 Mbits/sec  172    292 KBytes       
[  5]   5.00-10.00  sec   283 MBytes   475 Mbits/sec    1    526 KBytes       
[  5]  10.00-15.00  sec   282 MBytes   474 Mbits/sec   53    355 KBytes       
[  5]  15.00-20.00  sec   283 MBytes   475 Mbits/sec   28    569 KBytes       
[  5]  20.00-25.00  sec   280 MBytes   470 Mbits/sec    2    543 KBytes       
[  5]  25.00-30.00  sec   242 MBytes   406 Mbits/sec  237    384 KBytes       
[  5]  30.00-35.00  sec   171 MBytes   288 Mbits/sec    0    629 KBytes       
[  5]  35.00-40.00  sec   173 MBytes   291 Mbits/sec    3    455 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-40.00  sec  1.94 GBytes   416 Mbits/sec  496             sender
[  5]   0.00-40.05  sec  1.94 GBytes   415 Mbits/sec                  receiver
```

Вывод:

- Скорость работы в режиме TUN выше, так идет передача только IP-пакетов. Но так как идет работа на 3-м уровне, то можно использовать для маршрутизации пакетов между узлами.

- Режим TAP нужно использовать, когда необходимо создание виртуального моста, что дает возможность устройствам работать в одной и той же локальной сети. 


#### 2. Поднять RAS на базе OpenVPN с клиентскими сертификатами, подключиться с локальной машины на ВМ

Запускаем play для настройки OpenVPN:

ansible-playbook ansible/ras.yml -i ansible/hosts -e "host_key_checking=false" -l all

После выполнения в текущий каталог хостовой машины будут скопированы ключ и сертификаты для клиента. 

Устанавливаем OpenVPN на хостовой машине и проверяем работу конфигурации:

sudo apt install openvpn
sudo openvpn --config client.conf

Проверяем пинг по внутреннему IP адресу  сервера в туннеле

```
root@PC:/etc/openvpn# ping 10.10.10.1
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=0.958 ms
64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=0.978 ms
^C
--- 10.10.10.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.958/0.968/0.978/0.010 ms
```

Также проверяем командой ip r (netstat -rn) на хостовой машине что сеть туннеля импортирована в таблицу маршрутизации.

```
root@PC:/etc/openvpn# ip r
default via 192.168.151.1 dev eno2 proto dhcp src 192.168.151.60 metric 100 
10.10.10.0/24 via 10.10.10.5 dev tun0 
10.10.10.5 dev tun0 proto kernel scope link src 10.10.10.6 
192.168.50.0/24 dev vboxnet2 proto kernel scope link src 192.168.50.1 linkdown 
192.168.56.0/24 dev vboxnet0 proto kernel scope link src 192.168.56.1
```



