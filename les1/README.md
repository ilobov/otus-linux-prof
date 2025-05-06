Занятие 1. Обновление ядра системы

Цель домашнего задания
Научиться обновлять ядро в ОС Linux.
Описание домашнего задания
1) Запустить ВМ c Ubuntu

  Установлена ОС Ubuntu 24.04

  Установлены последние обновления из репозитариев

  sudo apt update && sudo apt -y upgrade

  Текущая версия ядра:
    uname -r

    6.8.0-52-generic

2) Обновить ядро ОС на новейшую стабильную версию из mainline-репозитория. 

   Зашел на сайт https://kernel.ubuntu.com/mainline/v6.14.4/amd64/ скачал файлы 
     linux-headers-{version}-generic_{version}.{date}_amd64.deb
     linux-headers-{version}_{version}.{date}_all.deb
     linux-image-unsigned-{version}-generic_{version}.{date}_amd64.deb
     linux-modules-{version}-generic_{version}.{date}_amd64.deb
     
   Устанавливаю скачаные файлы при помощи команды:

   sudo dpkg -i *.deb
   
   Проверяю наличие файлов в папке /boot/
   
   ls -l /boot/*6.14.4*
   
   -rw------- 1 root root  9981345 Apr 25 10:03 /boot/System.map-6.14.4-061404-generic
   -rw-r--r-- 1 root root   295497 Apr 25 10:03 /boot/config-6.14.4-061404-generic
   -rw-r--r-- 1 root root 70820173 May  6 12:19 /boot/initrd.img-6.14.4-061404-generic
   -rw------- 1 root root 15737344 Apr 25 10:03 /boot/vmlinuz-6.14.4-061404-generic

   Выполняю перезагрузку, проверяю версию ядра
   
   uname -r
   
   6.14.4-061404-generic
