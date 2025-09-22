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



