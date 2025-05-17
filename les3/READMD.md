1 часть ДЗ по LVM 
1.1 Настроить LVM в Ubuntu 24.04 Server
1.2 Создать Physical Volume, Volume Group и Logical Volume
1.3 Отформатировать и смонтировать файловую систему
1.4 Расширить файловую систему за счёт нового диска
1.5 Выполнить resize
1.6 Проверить корректность работы

1.1 Настроить LVM в Ubuntu 24.04 Server

Добавляю в виртуалку 4 новых блочных устройства

Перехожу в root: sudo -i

lsblk

NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
fd0                         2:0    1    4K  0 disk 
sda                         8:0    0   20G  0 disk 
├─sda1                      8:1    0    1M  0 part 
├─sda2                      8:2    0  1.8G  0 part /boot
└─sda3                      8:3    0 18.2G  0 part 
  └─ubuntu--vg-ubuntu--lv 252:0    0   10G  0 lvm  /
sdb                         8:16   0   10G  0 disk 
sdc                         8:32   0    2G  0 disk 
sdd                         8:48   0    1G  0 disk 
sde                         8:64   0    1G  0 disk 
sr0                        11:0    1 1024M  0 rom  

1.2 Создать Physical Volume, Volume Group и Logical Volume

Создаю Physical Volume

pvcreate /dev/sdb

Проверю что создался

vgs
  VG        #PV #LV #SN Attr   VSize  VFree
  ubuntu-vg   1   1   0 wz--n- 18.22g 8.22g

Создаю новую Volume Group

vgcreate test-vg /dev/sdb

vgs
  VG        #PV #LV #SN Attr   VSize   VFree  
  test-vg     1   0   0 wz--n- <10.00g <10.00g
  ubuntu-vg   1   1   0 wz--n-  18.22g   8.22g
  
Создаю Logical Volume

lvcreate -l+10%FREE -n test-lv test-vg

lvs
  LV        VG        Attr       LSize    Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  test-lv   test-vg   -wi-a----- 1020.00m                                                    
  ubuntu-lv ubuntu-vg -wi-ao----   10.00g
  
1.3 Отформатировать и смонтировать файловую систему

Создаю файловую систему

mkfs.ext4 /dev/test-vg/test-lv  

Создаю папку для монтирования

mkdir -p /mnt/test-lv

Прописываю монтирование в /etc/fstab

/dev/test-vg/test-lv /mnt/test-lv ext4 defaults 0 1

 df -h
Filesystem                         Size  Used Avail Use% Mounted on
tmpfs                              186M  1.1M  185M   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv  9.8G  6.2G  3.1G  67% /
tmpfs                              927M     0  927M   0% /dev/shm
tmpfs                              5.0M     0  5.0M   0% /run/lock
/dev/sda2                          1.8G  278M  1.4G  17% /boot
tmpfs                              186M   12K  186M   1% /run/user/1000
/dev/mapper/test--vg-test--lv      986M   24K  919M   1% /mnt/test-lv

1.4 Расширить файловую систему за счёт нового диска

Расширяю том и обновляю файловую систему

 vgs
  VG        #PV #LV #SN Attr   VSize   VFree
  test-vg     1   1   0 wz--n- <10.00g 9.00g
  ubuntu-vg   1   1   0 wz--n-  18.22g 8.22g
  
# lvextend -L+1G -r /dev/test-vg/test-lv

1.6 Проверить корректность работы

 df -h
Filesystem                         Size  Used Avail Use% Mounted on
tmpfs                              186M  1.1M  185M   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv  9.8G  6.2G  3.1G  67% /
tmpfs                              927M     0  927M   0% /dev/shm
tmpfs                              5.0M     0  5.0M   0% /run/lock
/dev/sda2                          1.8G  278M  1.4G  17% /boot
tmpfs                              186M   12K  186M   1% /run/user/1000
/dev/mapper/test--vg-test--lv      2.0G   24K  1.9G   1% /mnt/test-lv

 vgs
  VG        #PV #LV #SN Attr   VSize   VFree
  test-vg     1   1   0 wz--n- <10.00g 8.00g
  ubuntu-vg   1   1   0 wz--n-  18.22g 8.22g
  
Том увеличился, свободное место в VG уменьшилось на 1Gb  





