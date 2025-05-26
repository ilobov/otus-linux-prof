Работа с NFS

- запустить 2 виртуальных машины (сервер NFS и клиента);
- на сервере NFS должна быть подготовлена и экспортирована директория; 
- в экспортированной директории должна быть поддиректория с именем upload с правами на запись в неё; 
- экспортированная директория должна автоматически монтироваться на клиенте при старте виртуальной машины (systemd, autofs или fstab — любым способом);
- монтирование и работа NFS на клиенте должна быть организована с использованием NFSv3;

1 На сервере учтанавливаю пакет nfs-kernel-server:

  sudo apt install nfs-kernel-server
  
2 Создаю папку для экспорта:

  sudo -i 
  mkdir -p /srv/share/upload
  chown -R nobody:nogroup /srv/share
  chmod 0777 /srv/share/upload
  
  Проверяю
  
  ls -l /srv/share
  
  drwxrwxrwx 2 nobody nogroup 4096 May 26 08:44 upload
  
3 В файле /etc/exports добавляем доступ к папке:

  /srv/share/upload 10.128.0.16/32(rw,sync)
  
  Проверяю:
  
  exportfs -r
  
exportfs: /etc/exports [2]: Neither 'subtree_check' or 'no_subtree_check' specified for export "10.128.0.16/32:/srv/share/upload".
  Assuming default behaviour ('no_subtree_check').
  NOTE: this default has changed since nfs-utils version 1.0.x
  
  exportfs -s
  
  /srv/share/upload  10.128.0.16/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
  
4 На клиенте устанавливаю пакет nfs-common

  sudo apt install nfs-common
  
  Проверяю монтирование 
  
  mount 10.128.0.7:/srv/share/upload /mnt
  unmount /mnt
  
  Добавляем в /etc/fstab строку
  
  echo "10.128.0.7:/srv/share/upload /mnt nfs vers=3,noauto,x-systemd.automount 0 0" >> /etc/fstab
  
  Перестартум сервис с новой конфигурацией:
  
  systemctl daemon-reload
  systemctl restart remote-fs.target
  
  Проверяю:
  
  mount | grep mnt
  
  systemd-1 on /mnt type autofs (rw,relatime,fd=65,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=8884)
10.128.0.7:/srv/share/upload on /mnt type nfs (rw,relatime,vers=3,rsize=262144,wsize=262144,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=10.128.0.7,mountvers=3,mountport=57240,mountproto=udp,local_lock=none,addr=10.128.0.7)

  В выводе команды видно, что версия 3 (vers=3)
  
5 Проверяем работу NFS

  На клиенте переходим в папку /mnt и создаем файл
  cd /mnt
  touch test.txt
  
  На сервере проверяем наличие созданого файла:
  
  cd /srv/share/upload/
  ls -l
  
  -rw-r--r-- 1 nobody nogroup 0 May 26 09:09 test.txt
  
    
  
  
  
    
