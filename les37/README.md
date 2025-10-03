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

  1. Проверяем настройку vlan-ов и сетевую связанность устройств

    * testClient1 <-> testServer1

      Проверяем настройку интерфейсов и vlan-ов:

      - testServer1

      ```
      [vagrant@testServer1 ~]$ ip a
      ...
      5: eth1.1@eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
        link/ether 08:00:27:48:43:2c brd ff:ff:ff:ff:ff:ff
        inet 10.10.10.1/24 brd 10.10.10.255 scope global noprefixroute eth1.1
           valid_lft forever preferred_lft forever
        inet6 fe80::a00:27ff:fe48:432c/64 scope link 
           valid_lft forever preferred_lft forever

      [root@testServer1 ~]# ip -d link show dev eth1.1 | grep 'vlan protocol'
          vlan protocol 802.1Q id 1 <REORDER_HDR> numtxqueues 1 numrxqueues 1 gso_max_size 65536 gso_max_segs 65535 tso_max_size 65536 tso_max_segs 65535 gro_max_size 65536 gso_ipv4_max_size 65536 gro_ipv4_max_size 65536           

      [vagrant@testServer1 ~]$ sudo cat /proc/net/vlan/config 
      VLAN Dev name	 | VLAN ID
      Name-Type: VLAN_NAME_TYPE_RAW_PLUS_VID_NO_PAD
      eth1.1         | 1  | eth1          
    
      ```

      - testClient1

      ```
      [vagrant@testClient1 ~]$ ip a
      5: eth1.1@eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
          link/ether 08:00:27:83:bb:ee brd ff:ff:ff:ff:ff:ff
          inet 10.10.10.254/24 brd 10.10.10.255 scope global noprefixroute eth1.1
             valid_lft forever preferred_lft forever
          inet6 fe80::a00:27ff:fe83:bbee/64 scope link 
             valid_lft forever preferred_lft forever

      [vagrant@testClient1 ~]$ ip -d link show dev eth1.1 | grep 'vlan protocol'
          vlan protocol 802.1Q id 1 <REORDER_HDR> numtxqueues 1 numrxqueues 1 gso_max_size 65536 gso_max_segs 65535 tso_max_size 65536 tso_max_segs 65535       gro_max_size 65536 gso_ipv4_max_size 65536 gro_ipv4_max_size 65536

      [vagrant@testClient1 ~]$ sudo cat /proc/net/vlan/config
      VLAN Dev name	 | VLAN ID
      Name-Type: VLAN_NAME_TYPE_RAW_PLUS_VID_NO_PAD
      eth1.1         | 1  | eth1

      ```

      Проверяем сетевую связанность. На testClient1 за пускаем пинг: 
      [vagrant@testClient1 ~]$ ping 10.10.10.1

      Смотрим пакеты на testServer1 и testServer2
      
      ```
      root@testServer2:~# tcpdump -ni enp0s8
      tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
      listening on enp0s8, link-type EN10MB (Ethernet), snapshot length 262144 bytes
      ^C
      0 packets captured
      0 packets received by filter
      0 packets dropped by kernel
      ```
      На testServer2 пакетов нет

      ```
      [root@testServer1 ~]# tcpdump -ni enp0s8
      dropped privs to tcpdump
      tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
      listening on enp0s8, link-type EN10MB (Ethernet), snapshot length 262144 bytes
      06:45:15.473170 IP 10.10.10.254 > 10.10.10.1: ICMP echo request, id 3, seq 1, length 64
      06:45:15.473196 IP 10.10.10.1 > 10.10.10.254: ICMP echo reply, id 3, seq 1, length 64
      06:45:16.534097 IP 10.10.10.254 > 10.10.10.1: ICMP echo request, id 3, seq 2, length 64
      06:45:16.534122 IP 10.10.10.1 > 10.10.10.254: ICMP echo reply, id 3, seq 2, length 64
      06:45:17.558003 IP 10.10.10.254 > 10.10.10.1: ICMP echo request, id 3, seq 3, length 64
      06:45:17.558025 IP 10.10.10.1 > 10.10.10.254: ICMP echo reply, id 3, seq 3, length 64
      06:45:18.582207 IP 10.10.10.254 > 10.10.10.1: ICMP echo request, id 3, seq 4, length 64

      [root@testServer1 ~]# tcpdump -ni enp0s8 -vvv ip -xX -e
      dropped privs to tcpdump
      tcpdump: listening on enp0s8, link-type EN10MB (Ethernet), snapshot length 262144 bytes
      06:43:57.497907 08:00:27:83:bb:ee > 08:00:27:48:43:2c, ethertype 802.1Q (0x8100), length 102: vlan 1, p 0, ethertype IPv4 (0x0800), (tos 0x0, ttl 64, id      53734, offset 0, flags [DF], proto ICMP (1), length 84)
          10.10.10.254 > 10.10.10.1: ICMP echo request, id 2, seq 27, length 64
      	0x0000:  4500 0054 d1e6 4000 4001 3fb0 0a0a 0afe  E..T..@.@.?.....
      	0x0010:  0a0a 0a01 0800 a89e 0002 001b ad70 df68  .............p.h
      	0x0020:  0000 0000 fc97 0700 0000 0000 1011 1213  ...............testClient2 <-> testServer2.
      	0x0030:  1415 1617 1819 1a1b 1c1d 1e1f 2021 2223  .............!"#
      	0x0040:  2425 2627 2829 2a2b 2c2d 2e2f 3031 3233  $%&'()*+,-./0123
      	0x0050:  3435 3637                                4567
      06:43:57.497929 08:00:27:48:43:2c > 08:00:27:83:bb:ee, ethertype 802.1Q (0x8100), length 102: vlan 1, p 0, ethertype IPv4 (0x0800), (tos 0x0, ttl 64, id      55756, offset 0, flags [none], proto ICMP (1), length 84)
          10.10.10.1 > 10.10.10.254: ICMP echo reply, id 2, seq 27, length 64
      	0x0000:  4500 0054 d9cc 0000 4001 77ca 0a0a 0a01  E..T....@.w.....
      	0x0010:  0a0a 0afe 0000 b09e 0002 001b ad70 df68  .............p.h
      	0x0020:  0000 0000 fc97 0700 0000 0000 1011 1213  ................
      	0x0030:  1415 1617 1819 1a1b 1c1d 1e1f 2021 2223  .............!"#
      	0x0040:  2425 2627 2829 2a2b 2c2d 2e2f 3031 3233  $%&'()*+,-./0123
      	0x0050:  3435 3637                                4567
      06:43:58.518163 08:00:27:83:bb:ee > 08:00:27:48:43:2c, ethertype 802.1Q (0x8100), length 102: vlan 1, p 0, ethertype IPv4 (0x0800), (tos 0x0, ttl 64, id      54197, offset 0, flags [DF], proto ICMP (1), length 84)
          10.10.10.254 > 10.10.10.1: ICMP echo request, id 2, seq 28, length 64
      	0x0000:  4500 0054 d3b5 4000 4001 3de1 0a0a 0afe  E..T..@.@.=.....
      	0x0010:  0a0a 0a01 0800 b04e 0002 001c ae70 df68  .......N.....p.h
      	0x0020:  0000 0000 f3e6 0700 0000 0000 1011 1213  ................
      	0x0030:  1415 1617 1819 1a1b 1c1d 1e1f 2021 2223  .............!"#
      	0x0040:  2425 2627 2829 2a2b 2c2d 2e2f 3031 3233  $%&'()*+,-./0123
      	0x0050:  3435 3637                                4567

      ```
      На testServer1 видим запросы и ответы, также видим что заголовки пакетов идут с тэгом vlan 1

      Аналогичную картину наблюдаем с testClient2 <-> testServer2

  2. Проверяем bond интрефейс между centralRouter и inetRouter

    Смотрим сетевые интрфейсы:

    ```
    [root@centralRouter ~]# ip a
    ...
    3: eth1: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc fq_codel master bond0 state UP group default qlen 1000
        link/ether 08:00:27:41:88:a1 brd ff:ff:ff:ff:ff:ff
        altname enp0s8
    4: eth2: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc fq_codel master bond0 state UP group default qlen 1000
        link/ether 08:00:27:b4:c0:55 brd ff:ff:ff:ff:ff:ff
        altname enp0s9
        ...
    7: bond0: <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
        link/ether 08:00:27:41:88:a1 brd ff:ff:ff:ff:ff:ff
        inet 192.168.255.2/30 brd 192.168.255.3 scope global noprefixroute bond0
           valid_lft forever preferred_lft forever
        inet6 fe80::a00:27ff:fe41:88a1/64 scope link 
           valid_lft forever preferred_lft forever

    [root@inetRouter ~]# ip a
    ...
    3: eth1: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc fq_codel master bond0 state UP group default qlen 1000
        link/ether 08:00:27:46:d2:4b brd ff:ff:ff:ff:ff:ff
        altname enp0s8
    4: eth2: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc fq_codel master bond0 state UP group default qlen 1000
        link/ether 08:00:27:63:67:d0 brd ff:ff:ff:ff:ff:ff
        altname enp0s9
        ...
    6: bond0: <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
        link/ether 08:00:27:46:d2:4b brd ff:ff:ff:ff:ff:ff
        inet 192.168.255.1/30 brd 192.168.255.3 scope global noprefixroute bond0
           valid_lft forever preferred_lft forever
        inet6 fe80::a00:27ff:fe46:d24b/64 scope link 
           valid_lft forever preferred_lft forever           
    ```

    Видим, что интерфейсы eth1 и eth2 включены в master bond0 и все интерфейсы в state UP. На bond0 назначен ip адрес.

    Проверяем сетевую связанность:

    ```
    [root@inetRouter ~]# ping 192.168.255.2
    PING 192.168.255.2 (192.168.255.2) 56(84) bytes of data.
    64 bytes from 192.168.255.2: icmp_seq=1 ttl=64 time=1.20 ms
    64 bytes from 192.168.255.2: icmp_seq=2 ttl=64 time=0.765 ms
    64 bytes from 192.168.255.2: icmp_seq=3 ttl=64 time=0.501 ms
    ```

    Смотрим состояние bond интерфейса

    ```
    [root@inetRouter ~]# cat /proc/net/bonding/bond0 
    Ethernet Channel Bonding Driver: v5.14.0-570.12.1.el9_6.x86_64

    Bonding Mode: fault-tolerance (active-backup) (fail_over_mac active)
    Primary Slave: None
    Currently Active Slave: eth1
    MII Status: up
    MII Polling Interval (ms): 100
    Up Delay (ms): 0
    Down Delay (ms): 0
    Peer Notification Delay (ms): 0

    Slave Interface: eth1
    MII Status: up
    Speed: 1000 Mbps
    Duplex: full
    Link Failure Count: 0
    Permanent HW addr: 08:00:27:46:d2:4b
    Slave queue ID: 0

    Slave Interface: eth2
    MII Status: up
    Speed: 1000 Mbps
    Duplex: full
    Link Failure Count: 0
    Permanent HW addr: 08:00:27:63:67:d0
    Slave queue ID: 0
    ```

    Видим, что режим работы active-backup активный интерфейс "Currently Active Slave: eth1"

    Проверяем при помощи tcpdump, что весь трафик идет по eth1:

    ```
    [root@inetRouter ~]# ping 192.168.255.2
    PING 192.168.255.2 (192.168.255.2) 56(84) bytes of data.
    64 bytes from 192.168.255.2: icmp_seq=1 ttl=64 time=0.699 ms
    64 bytes from 192.168.255.2: icmp_seq=2 ttl=64 time=0.739 ms
    64 bytes from 192.168.255.2: icmp_seq=3 ttl=64 time=0.736 ms


    [root@centralRouter ~]# tcpdump -ni eth1
    dropped privs to tcpdump
    tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
    listening on eth1, link-type EN10MB (Ethernet), snapshot length 262144 bytes
    08:40:01.443013 IP 192.168.255.1 > 192.168.255.2: ICMP echo request, id 3, seq 17, length 64
    08:40:01.443046 IP 192.168.255.2 > 192.168.255.1: ICMP echo reply, id 3, seq 17, length 64
    08:40:02.444782 IP 192.168.255.1 > 192.168.255.2: ICMP echo request, id 3, seq 18, length 64
    08:40:02.444864 IP 192.168.255.2 > 192.168.255.1: ICMP echo reply, id 3, seq 18, length 64
    ^C
    4 packets captured
    4 packets received by filter
    0 packets dropped by kernel
    [root@centralRouter ~]# tcpdump -ni eth2
    dropped privs to tcpdump
    tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
    listening on eth2, link-type EN10MB (Ethernet), snapshot length 262144 bytes
    ^C
    0 packets captured
    0 packets received by filter
    0 packets dropped by kernel

    ```



    