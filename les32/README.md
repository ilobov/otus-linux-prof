## OSPF

### Задание

1. Развернуть 3 виртуальные машины  
2. Объединить их разными vlan  
- настроить OSPF между машинами на базе Quagga;  
- изобразить ассиметричный роутинг;  
- сделать один из линков "дорогим", но что бы при этом роутинг был симметричным.  

Формат сдачи ДЗ - vagrant + ansible


### Решение

* Развертывание стенда

    - Запускаем создание ВМ через Vagrant   

        vargant up


* Схема сети

  ![Nets](https://github.com/ilobov/otus-linux-prof/blob/main/les32/net.png)

2.1 Настроить OSPF между машинами на базе Quagga  

После развертывания стенда OSPF уже настроен при помощи ansible.  

Проверяем работу. Подключаемся к ВМ router1.  

- попробуем сделать ping до ip-адреса 192.168.30.1  

```
root@router1:/etc/frr# ping 192.168.30.1  
PING 192.168.30.1 (192.168.30.1) 56(84) bytes of data.  
64 bytes from 192.168.30.1: icmp_seq=1 ttl=64 time=0.795 ms  
64 bytes from 192.168.30.1: icmp_seq=2 ttl=64 time=0.854 ms  
^C  
--- 192.168.30.1 ping statistics ---  
2 packets transmitted, 2 received, 0% packet loss, time 1002ms  
rtt min/avg/max/mdev = 0.795/0.824/0.854/0.029 ms   
```
- Запустим трассировку до адреса 192.168.30.1

```
root@router1:/etc/frr# traceroute 192.168.30.1  
traceroute to 192.168.30.1 (192.168.30.1), 30 hops max, 60 byte packets  
 1  192.168.30.1 (192.168.30.1)  0.784 ms  0.723 ms  0.697 ms  
```

- Попробуем отключить интерфейс enp0s9 и немного подождем и снова запустим трассировку до ip-адреса 192.168.30.1

```
root@router1:/etc/frr# ifconfig enp0s9 down  
root@router1:/etc/frr# ip a | grep enp0s9  
4: enp0s9: <BROADCAST,MULTICAST> mtu 1500 qdisc fq_codel state DOWN group default qlen 1000  
root@router1:/etc/frr# traceroute 192.168.30.1  
traceroute to 192.168.30.1 (192.168.30.1), 30 hops max, 60 byte packets  
 1  10.0.10.2 (10.0.10.2)  0.796 ms  0.737 ms  0.715 ms  
 2  192.168.30.1 (192.168.30.1)  1.534 ms  1.508 ms  1.483 ms  
```

2.2 Настройка ассиметричного роутинга

Запускаем play для настройки ассиметричного роутинга:

ansible-playbook ansible/asym.yml -i ansible/hosts -e "host_key_checking=false" -l all

Меняем на router1 стоимость маршрута к router2 на 1000. В результате на router1 получаем по ospf маршрут до 192.168.20.1 через router3. А на router2 маршрут на 192.168.10.1 остается прежний, через router1. Получаем ассиметричный трафик

```
router1# show ip route ospf
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   10.0.10.0/30 [110/300] via 10.0.12.2, enp0s9, weight 1, 00:00:13
O>* 10.0.11.0/30 [110/200] via 10.0.12.2, enp0s9, weight 1, 00:00:13
O   10.0.12.0/30 [110/100] is directly connected, enp0s9, weight 1, 00:00:13
O   192.168.10.0/24 [110/100] is directly connected, enp0s10, weight 1, 00:00:22
O>* 192.168.20.0/24 [110/300] via 10.0.12.2, enp0s9, weight 1, 00:00:13
O>* 192.168.30.0/24 [110/200] via 10.0.12.2, enp0s9, weight 1, 00:00:13
```

```
router2# show ip route ospf 
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   10.0.10.0/30 [110/100] is directly connected, enp0s8, weight 1, 00:30:34
O   10.0.11.0/30 [110/100] is directly connected, enp0s9, weight 1, 00:30:34
O>* 10.0.12.0/30 [110/200] via 10.0.10.1, enp0s8, weight 1, 00:01:56
  *                        via 10.0.11.1, enp0s9, weight 1, 00:01:56
O>* 192.168.10.0/24 [110/200] via 10.0.10.1, enp0s8, weight 1, 00:01:56
O   192.168.20.0/24 [110/100] is directly connected, enp0s10, weight 1, 00:30:34
O>* 192.168.30.0/24 [110/200] via 10.0.11.1, enp0s9, weight 1, 00:29:58
```

Смотрим трафик на router2 при помощи tcpdump на интерфейсах enp0s8(to router1) и enp0s9(to router3) и видим что трафик от 192.168.10.1 приходит через интерфейс enp0s9, а уходит через enp0s8.
```
root@router1:~# ping -I 192.168.10.1 192.168.20.1
PING 192.168.20.1 (192.168.20.1) from 192.168.10.1 : 56(84) bytes of data.
64 bytes from 192.168.20.1: icmp_seq=1 ttl=64 time=1.28 ms
64 bytes from 192.168.20.1: icmp_seq=2 ttl=64 time=2.60 ms
64 bytes from 192.168.20.1: icmp_seq=3 ttl=64 time=3.10 ms


root@router1:~# ping -I 192.168.10.1 192.168.20.1
PING 192.168.20.1 (192.168.20.1) from 192.168.10.1 : 56(84) bytes of data.
64 bytes from 192.168.20.1: icmp_seq=1 ttl=64 time=1.28 ms
64 bytes from 192.168.20.1: icmp_seq=2 ttl=64 time=2.60 ms
64 bytes from 192.168.20.1: icmp_seq=3 ttl=64 time=3.10 ms


root@router1:~# ping -I 192.168.10.1 192.168.20.1
PING 192.168.20.1 (192.168.20.1) from 192.168.10.1 : 56(84) bytes of data.
64 bytes from 192.168.20.1: icmp_seq=1 ttl=64 time=1.28 ms
64 bytes from 192.168.20.1: icmp_seq=2 ttl=64 time=2.60 ms
64 bytes from 192.168.20.1: icmp_seq=3 ttl=64 time=3.10 ms
```

2.3 Настройка симметичного роутинга

Запускаем play для настройки симетричного роутинга:

ansible-playbook ansible/sym.yml -i ansible/hosts -e "host_key_checking=false" -l all

Чтобы трафик стал симметричным на router2 меняем стоимость маршрута в сторону router1 также на 1000 и проверяем:

```
router1# show ip route ospf
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   10.0.10.0/30 [110/1000] is directly connected, enp0s8, weight 1, 00:02:26
O>* 10.0.11.0/30 [110/200] via 10.0.12.2, enp0s9, weight 1, 00:24:49
O   10.0.12.0/30 [110/100] is directly connected, enp0s9, weight 1, 00:24:49
O   192.168.10.0/24 [110/100] is directly connected, enp0s10, weight 1, 00:24:58
O>* 192.168.20.0/24 [110/300] via 10.0.12.2, enp0s9, weight 1, 00:02:20
O>* 192.168.30.0/24 [110/200] via 10.0.12.2, enp0s9, weight 1, 00:24:49


router2# show ip route ospf
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   10.0.10.0/30 [110/1000] is directly connected, enp0s8, weight 1, 00:02:59
O   10.0.11.0/30 [110/100] is directly connected, enp0s9, weight 1, 00:02:59
O>* 10.0.12.0/30 [110/200] via 10.0.11.1, enp0s9, weight 1, 00:02:54
O>* 192.168.10.0/24 [110/300] via 10.0.11.1, enp0s9, weight 1, 00:02:54
O   192.168.20.0/24 [110/100] is directly connected, enp0s10, weight 1, 00:02:59
O>* 192.168.30.0/24 [110/200] via 10.0.11.1, enp0s9, weight 1, 00:02:54
```

Маршруты на обоих роутерах идут через router3

Снова смотрим трафик на router2 при помощи tcpdump на enp0s9 и видим что трафик в обе стороны идет через router3.

```
root@router1:~# ping -I 192.168.10.1 192.168.20.1
PING 192.168.20.1 (192.168.20.1) from 192.168.10.1 : 56(84) bytes of data.
64 bytes from 192.168.20.1: icmp_seq=1 ttl=63 time=2.36 ms
64 bytes from 192.168.20.1: icmp_seq=2 ttl=63 time=2.82 ms
64 bytes from 192.168.20.1: icmp_seq=3 ttl=63 time=3.17 ms


root@router2:~# tcpdump -i enp0s9
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on enp0s9, link-type EN10MB (Ethernet), snapshot length 262144 bytes
14:04:55.033893 IP 192.168.10.1 > 192.168.20.1: ICMP echo request, id 2, seq 110, length 64
14:04:55.033952 IP 192.168.20.1 > 192.168.10.1: ICMP echo reply, id 2, seq 110, length 64
14:04:56.060832 IP 192.168.10.1 > 192.168.20.1: ICMP echo request, id 2, seq 111, length 64
14:04:56.060895 IP 192.168.20.1 > 192.168.10.1: ICMP echo reply, id 2, seq 111, length 64
14:04:57.068494 IP 192.168.10.1 > 192.168.20.1: ICMP echo request, id 2, seq 112, length 64
14:04:57.068555 IP 192.168.20.1 > 192.168.10.1: ICMP echo reply, id 2, seq 112, length 64
14:04:58.073931 IP 192.168.10.1 > 192.168.20.1: ICMP echo request, id 2, seq 113, length 64
14:04:58.074004 IP 192.168.20.1 > 192.168.10.1: ICMP echo reply, id 2, seq 113, length 64
```