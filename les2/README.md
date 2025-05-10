Домашнее задание: работа с mdadm

Задание
• Добавить в виртуальную машину несколько дисков
• Собрать RAID-0/1/5/10 на выбор
• Сломать и починить RAID
• Создать GPT таблицу, пять разделов и смонтировать их в системе.

1. Добавил в виртуальную машину новый диск размером 1Гб

 sudo lshw -short | grep disk
 
/0/100/7.1/0.0.0  /dev/cdrom  disk           Virtual CD/ROM
/0/1/0.1.0        /dev/sda    disk           1073MB Virtual Disk
/0/2/0.0.0        /dev/sdb    disk           21GB Virtual Disk

Новый диск /dev/sda

Для теста создаю на диске 5 разделов по 100Мб

sudo fdisk -l /dev/sda

Disk /dev/sda: 1 GiB, 1073741824 bytes, 2097152 sectors
Disk model: Virtual Disk    
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: dos
Disk identifier: 0x40f81fab

Device     Boot  Start     End Sectors  Size Id Type
/dev/sda1         2048  206847  204800  100M 83 Linux
/dev/sda2       206848  411647  204800  100M 83 Linux
/dev/sda3       411648  616447  204800  100M 83 Linux
/dev/sda4       616448 2097151 1480704  723M  5 Extended
/dev/sda5       618496  823295  204800  100M 83 Linux
/dev/sda6       825344 1030143  204800  100M 83 Linux

2. Из 4 дисков создаю RAID-10

sudo mdadm --create /dev/md01 -l 10 -n 4 /dev/sda1 /dev/sda2 /dev/sda3 /dev/sda5

sudo cat /proc/mdstat
Personalities : [linear] [raid0] [raid1] [raid6] [raid5] [raid4] [raid10] 
md1 : active raid10 sda5[3] sda3[2] sda2[1] sda1[0]
      200704 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]
      
mdadm -D /dev/md1

dev/md1:
           Version : 1.2
     Creation Time : Sat May 10 11:35:58 2025
        Raid Level : raid10
        Array Size : 200704 (196.00 MiB 205.52 MB)
     Used Dev Size : 100352 (98.00 MiB 102.76 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Sat May 10 11:36:00 2025
             State : clean 
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : ubuntu1:01  (local to host ubuntu1)
              UUID : 9e8883ca:cc1f5af0:f3b6a90d:4d038d17
            Events : 17

    Number   Major   Minor   RaidDevice State
       0       8        1        0      active sync set-A   /dev/sda1
       1       8        2        1      active sync set-B   /dev/sda2
       2       8        3        2      active sync set-A   /dev/sda3
       3       8        5        3      active sync set-B   /dev/sda5
       
3. Сломать и починить RAID

Фэйлю один диск 
sudo mdadm /dev/md1 --fail /dev/sda3

sudo mdadm -D /dev/md1
/dev/md1:
           Version : 1.2
     Creation Time : Sat May 10 11:35:58 2025
        Raid Level : raid10
        Array Size : 200704 (196.00 MiB 205.52 MB)
     Used Dev Size : 100352 (98.00 MiB 102.76 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Sat May 10 11:46:13 2025
             State : clean, degraded 
    Active Devices : 3
   Working Devices : 3
    Failed Devices : 1
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : ubuntu1:01  (local to host ubuntu1)
              UUID : 9e8883ca:cc1f5af0:f3b6a90d:4d038d17
            Events : 19

    Number   Major   Minor   RaidDevice State
       0       8        1        0      active sync set-A   /dev/sda1
       1       8        2        1      active sync set-B   /dev/sda2
       -       0        0        2      removed
       3       8        5        3      active sync set-B   /dev/sda5

       2       8        3        -      faulty   /dev/sda3
       
  Удаляю fail диск из raid-а
  
  sudo  mdadm /dev/md1 --remove /dev/sda3
  
  Добавляю новый диск
  
  sudo  mdadm /dev/md1 --add /dev/sda6
  
  sudo mdadm -D /dev/md1
/dev/md1:
           Version : 1.2
     Creation Time : Sat May 10 11:35:58 2025
        Raid Level : raid10
        Array Size : 200704 (196.00 MiB 205.52 MB)
     Used Dev Size : 100352 (98.00 MiB 102.76 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Sat May 10 11:50:25 2025
             State : clean, degraded, recovering 
    Active Devices : 3
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 1

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

    Rebuild Status : 75% complete

              Name : ubuntu1:01  (local to host ubuntu1)
              UUID : 9e8883ca:cc1f5af0:f3b6a90d:4d038d17
            Events : 33

    Number   Major   Minor   RaidDevice State
       0       8        1        0      active sync set-A   /dev/sda1
       1       8        2        1      active sync set-B   /dev/sda2
       4       8        6        2      spare rebuilding   /dev/sda6
       3       8        5        3      active sync set-B   /dev/sda5
       
4. Создать GPT таблицу, пять разделов и смонтировать их в системе

Создаю раздел GPT на RAID

sudo parted -s /dev/md1 mklabel gpt

Создаю партиции
sudo parted /dev/md1 mkpart primary ext4 0% 20%
sudo parted /dev/md1 mkpart primary ext4 20% 40%
sudo parted /dev/md1 mkpart primary ext4 40% 60%
sudo parted /dev/md1 mkpart primary ext4 60% 80%
sudo parted /dev/md1 mkpart primary ext4 80% 100%

sudo fdisk -l /dev/md1
Disk /dev/md1: 196 MiB, 205520896 bytes, 401408 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 524288 bytes / 1048576 bytes
Disklabel type: gpt
Disk identifier: 0DFE694E-D5A4-4766-B2AF-C264E153A573

Device      Start    End Sectors  Size Type
/dev/md1p1     34  80281   80248 39.2M Linux filesystem
/dev/md1p2  81920 159743   77824   38M Linux filesystem
/dev/md1p3 159744 241663   81920   40M Linux filesystem
/dev/md1p4 241664 321535   79872   39M Linux filesystem
/dev/md1p5 321536 401374   79839   39M Linux filesystem

Создаю файловую систему ext4 на партициях 

for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md1p$i; done

Монтирую их по каталогам

sudo mkdir -p /raid/part{1,2,3,4,5}
for i in $(seq 1 5); do sudo mount /dev/md1p$i /raid/part$i; done

df | grep md1p
/dev/md1p1                            33488      24     30660   1% /raid/part1
/dev/md1p2                            32352      24     29608   1% /raid/part2
/dev/md1p3                            34272      24     31384   1% /raid/part3
/dev/md1p4                            33312      24     30496   1% /raid/part4
/dev/md1p5                            33292      24     30480   1% /raid/part5



