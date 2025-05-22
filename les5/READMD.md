1 Определить алгоритм с наилучшим сжатием:
- Определить какие алгоритмы сжатия поддерживает zfs (gzip, zle, lzjb, lz4);
- создать 4 файловых системы на каждой применить свой алгоритм сжатия;
- для сжатия использовать либо текстовый файл, либо группу файлов.

Создаю пул из 2 блочных устройств в зеркале:

zpool create mypool mirror /dev/sdb /dev/sdc

Создаю 4 файловые системы:

zfs create mypool/test1
zfs create mypool/test2
zfs create mypool/test3
zfs create mypool/test4

Для каждой фаловой системы устанавливаю свой алгоритм сжатия:

zfs set compression=lzjb /mypool/test1
zfs set compression=lz4 mypool/test2
zfs set compression=gzip-9 mypool/test3
zfs set compression=zle mypool/test4

Проверяем применение параметров:

zfs get all | grep compression

mypool        compression           on                     default
mypool/test1  compression           lzjb                   local
mypool/test2  compression           lz4                    local
mypool/test3  compression           gzip-9                 local
mypool/test4  compression           zle                    local


Копирую содержимое каталога /var/log в каждую ФС
cp -r /var/log/* /mypool/test1
cp -r /var/log/* /mypool/test2
cp -r /var/log/* /mypool/test3
cp -r /var/log/* /mypool/test4

Смотрю размер данных на ФС

zfs list

NAME           USED  AVAIL  REFER  MOUNTPOINT
mypool        88.3M   744M    96K  /mypool
mypool/test1  24.7M   744M  24.7M  /mypool/test1
mypool/test2  17.2M   744M  17.2M  /mypool/test2
mypool/test3  12.7M   744M  12.7M  /mypool/test3
mypool/test4  33.1M   744M  33.1M  /mypool/test4

Степень сжатия файлов

zfs get all | grep compressratio | grep -v ref

mypool        compressratio         6.52x                  -
mypool/test1  compressratio         5.78x                  -
mypool/test2  compressratio         8.38x                  -
mypool/test3  compressratio         11.41x                 -
mypool/test4  compressratio         4.31x                  -

Вывод: На наших данных лучший показатель сжатия у gzip-9

2 Определить настройки пула.
  С помощью команды zfs import собрать pool ZFS.
  Командами zfs определить настройки:
   - размер хранилища;
   - тип pool;
   - значение recordsize;
   - какое сжатие используется;
   - какая контрольная сумма используется.

  Скачиваю архив:
   wget -O archive.tar.gz --no-check-certificate 'https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download'
   
  Разархивирую:
  tar -xzvf archive.tar.gz
  
  Проверим, возможно ли импортировать данный каталог в пул:
  zpool import -d zpoolexport

   pool: otus
     id: 6554193320433390805
  state: ONLINE
status: Some supported features are not enabled on the pool.
	(Note that they may be intentionally disabled if the
	'compatibility' property is set.)
 action: The pool can be imported using its name or numeric identifier, though
	some features will not be available without an explicit 'zpool upgrade'.
 config:

	otus                         ONLINE
	  mirror-0                   ONLINE
	    /root/zpoolexport/filea  ONLINE
	    /root/zpoolexport/fileb  ONLINE

  Импортирую пул:
  
    zpool import -d zpoolexport otus
  
  Проверяю: 
    zpool list
    
NAME      SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
mypool    960M  88.3M   872M        -         -     0%     9%  1.00x    ONLINE  -
mypool2  2.81G   372K  2.81G        -         -     0%     0%  1.00x    ONLINE  -
otus      480M  2.18M   478M        -         -     0%     0%  1.00x    ONLINE  -

zpool status
  pool: mypool
 state: ONLINE
config:

	NAME        STATE     READ WRITE CKSUM
	mypool      ONLINE       0     0     0
	  mirror-0  ONLINE       0     0     0
	    sdb     ONLINE       0     0     0
	    sdc     ONLINE       0     0     0

errors: No known data errors

  pool: mypool2
 state: ONLINE
config:

	NAME        STATE     READ WRITE CKSUM
	mypool2     ONLINE       0     0     0
	  sdd       ONLINE       0     0     0
	  sde       ONLINE       0     0     0
	  sdf       ONLINE       0     0     0

errors: No known data errors

  pool: otus
 state: ONLINE
status: Some supported and requested features are not enabled on the pool.
	The pool can still be used, but some features are unavailable.
action: Enable all features using 'zpool upgrade'. Once this is done,
	the pool may no longer be accessible by software that does not support
	the features. See zpool-features(7) for details.
config:

	NAME                         STATE     READ WRITE CKSUM
	otus                         ONLINE       0     0     0
	  mirror-0                   ONLINE       0     0     0
	    /root/zpoolexport/filea  ONLINE       0     0     0
	    /root/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors

  Просмотр параметров пула:
   zfs get all otus
   
NAME  PROPERTY              VALUE                  SOURCE
otus  type                  filesystem             -
otus  creation              Fri May 15  4:00 2020  -
otus  used                  2.04M                  -
otus  available             350M                   -
otus  referenced            24K                    -
otus  compressratio         1.00x                  -
otus  mounted               yes                    -
otus  quota                 none                   default
otus  reservation           none                   default
otus  recordsize            128K                   local
otus  mountpoint            /otus                  default
otus  sharenfs              off                    default
otus  checksum              sha256                 local
otus  compression           zle                    local
otus  atime                 on                     default
otus  devices               on                     default
otus  exec                  on                     default
otus  setuid                on                     default
otus  readonly              off                    default
otus  zoned                 off                    default
otus  snapdir               hidden                 default
otus  aclmode               discard                default
otus  aclinherit            restricted             default
otus  createtxg             1                      -
otus  canmount              on                     default
otus  xattr                 on                     default
otus  copies                1                      default
otus  version               5                      -
otus  utf8only              off                    -
otus  normalization         none                   -
otus  casesensitivity       sensitive              -
otus  vscan                 off                    default
otus  nbmand                off                    default
otus  sharesmb              off                    default
otus  refquota              none                   default
otus  refreservation        none                   default
otus  guid                  14592242904030363272   -
otus  primarycache          all                    default
otus  secondarycache        all                    default
otus  usedbysnapshots       0B                     -
otus  usedbydataset         24K                    -
otus  usedbychildren        2.01M                  -
otus  usedbyrefreservation  0B                     -
otus  logbias               latency                default
otus  objsetid              54                     -
otus  dedup                 off                    default
otus  mlslabel              none                   default
otus  sync                  standard               default
otus  dnodesize             legacy                 default
otus  refcompressratio      1.00x                  -
otus  written               24K                    -
otus  logicalused           1020K                  -
otus  logicalreferenced     12K                    -
otus  volmode               default                default
otus  filesystem_limit      none                   default
otus  snapshot_limit        none                   default
otus  filesystem_count      none                   default
otus  snapshot_count        none                   default
otus  snapdev               hidden                 default
otus  acltype               off                    default
otus  context               none                   default
otus  fscontext             none                   default
otus  defcontext            none                   default
otus  rootcontext           none                   default
otus  relatime              on                     default
otus  redundant_metadata    all                    default
otus  overlay               on                     default
otus  encryption            off                    default
otus  keylocation           none                   default
otus  keyformat             none                   default
otus  pbkdf2iters           0                      default
otus  special_small_blocks  0                      default 

3 Работа со снапшотами:
- скопировать файл из удаленной директории;
- восстановить файл локально. zfs receive;
- найти зашифрованное сообщение в файле secret_message.

Копирую файл снапшота
wget -O otus_task2.file --no-check-certificate https://drive.usercontent.google.com/download?id=1wgxjih8YZ-cqLqaZVa0lA3h3Y029c3oI&export=download

Восстанавливаю локально:
zfs receive otus/test@today < otus_task2.file

Смотрю список снапшотов:
zfs list -t snapshot

NAME              USED  AVAIL  REFER  MOUNTPOINT
otus/test@today    18K      -  2.83M  -

Смотрим содержимое найденного файла:
cat /otus/test/task1/file_mess/secret_message
https://otus.ru/lessons/linux-hl/


