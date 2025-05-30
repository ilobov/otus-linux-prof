## Размещаем свой RPM в своем репозитории

### Домашнее задание

1. Создать свой RPM пакет.
2. Создать свой репозиторий и разместить там ранее собранный RPM.

Задание выполняется на ОС Fedora 37

#### 1. Создать свой RPM пакет

* Устанавливаю неоходимые пакеты
[user@fedora37 ~]$ yum install -y wget rpmdevtools rpm-build createrepo \
 yum-utils cmake gcc git nano
 
* Для примера возьмем пакет Nginx и соберем его с дополнительным модулем ngx_broli
* Загрузим SRPM пакет Nginx для дальнейшей работы над ним: 

[root@fedora37 ~]# mkdir rpm && cd rpm
[root@fedora37 rpm]# yumdownloader --source nginx

* Установим source пакет и все зависимости

[root@fedora37 rpm]# rpm -Uvh nginx*.src.rpm
[root@fedora37 rpm]# yum-builddep nginx

* Скачаваем исходный код модуля ngx_brotli 

[root@fedora37 rpm]# cd /root
[root@fedora37 ~]# git clone --recurse-submodules -j8 \
[root@fedora37 ~]# cd ngx_brotli/deps/brotli
[root@fedora37 brotli]# mkdir out && cd out

* Собираем модуль ngx_brotli:

[root@fedora37 out]# cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_CXX_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_INSTALL_PREFIX=./installed ..
[root@fedora37 out]# cmake --build . --config Release -j 2 --target brotlienc

* В spec файл добавляем использование модуля "--add-module=/root/ngx_brotli"

[root@fedora37 ~]# cd ~/rpmbuild/SPECS/
[root@fedora37 ~]# vi nginx.spec

if ! ./configure \
    --prefix=%{_datadir}/nginx \
    --sbin-path=%{_sbindir}/nginx \
    --modules-path=%{nginx_moduledir} \
    --conf-path=%{_sysconfdir}/nginx/nginx.conf \
    --error-log-path=%{_localstatedir}/log/nginx/error.log \
    --http-log-path=%{_localstatedir}/log/nginx/access.log \
    --http-client-body-temp-path=%{_localstatedir}/lib/nginx/tmp/client_body \
    --http-proxy-temp-path=%{_localstatedir}/lib/nginx/tmp/proxy \
    --http-fastcgi-temp-path=%{_localstatedir}/lib/nginx/tmp/fastcgi \
    --http-uwsgi-temp-path=%{_localstatedir}/lib/nginx/tmp/uwsgi \
    --http-scgi-temp-path=%{_localstatedir}/lib/nginx/tmp/scgi \
    --pid-path=/run/nginx.pid \
    --lock-path=/run/lock/subsys/nginx \
    --user=%{nginx_user} \
    --group=%{nginx_user} \
    --with-compat \
    --with-debug \
    --add-module=/root/ngx_brotli \

* Собираем RPM пакет

[root@fedora37 SPECS]# rpmbuild -ba nginx.spec -D 'debug_package %{nil}'

* Проверяем, что пакты созданы:

[root@fedora37 SPECS]# ll /root/rpmbuild/RPMS/x86_64/
total 2076
-rw-r--r--. 1 root root   34299 May 30 06:49 nginx-1.24.0-1.fc37.x86_64.rpm
-rw-r--r--. 1 root root 1053722 May 30 06:49 nginx-core-1.24.0-1.fc37.x86_64.rpm
-rw-r--r--. 1 root root  799964 May 30 06:49 nginx-mod-devel-1.24.0-1.fc37.x86_64.rpm
-rw-r--r--. 1 root root   21969 May 30 06:49 nginx-mod-http-image-filter-1.24.0-1.fc37.x86_64.rpm
-rw-r--r--. 1 root root   32851 May 30 06:49 nginx-mod-http-perl-1.24.0-1.fc37.x86_64.rpm
-rw-r--r--. 1 root root   20720 May 30 06:49 nginx-mod-http-xslt-filter-1.24.0-1.fc37.x86_64.rpm
-rw-r--r--. 1 root root   56328 May 30 06:49 nginx-mod-mail-1.24.0-1.fc37.x86_64.rpm
-rw-r--r--. 1 root root   85543 May 30 06:49 nginx-mod-stream-1.24.0-1.fc37.x86_64.rpm

[root@fedora37 SPECS]# ll /root/rpmbuild/RPMS/noarch
total 24
-rw-r--r--. 1 root root  9857 May 30 06:49 nginx-all-modules-1.24.0-1.fc37.noarch.rpm
-rw-r--r--. 1 root root 10973 May 30 06:49 nginx-filesystem-1.24.0-1.fc37.noarch.rpm 

* Устанавливаем и запускаем nginx

[root@fedora37 SPECS]# cp ~/rpmbuild/RPMS/noarch/* ~/rpmbuild/RPMS/x86_64/
[root@fedora37 SPECS]# cd ~/rpmbuild/RPMS/x86_64
[root@fedora37 x86_64]# yum localinstall *.rpm
[root@fedora37 x86_64]# systemctl start nginx
[root@fedora37 x86_64]# systemctl status nginx

#### 2. Создать свой репозиторий и разместить там ранее собранный RPM

* Создаю папку

[root@fedora37 /]# mkdir /usr/share/nginx/html/repo

* Копирую созданные RPM пакеты и и скачиваю доп пакет percona-release

[root@fedora37 /]# cd /usr/share/nginx/html/repo
[root@fedora37 repo]# cp ~/rpmbuild/RPMS/x86_64/*.rpm ./
[root@fedora37 repo]# wget https://repo.percona.com/yum/percona-release-latest.noarch.rpm

* Инициализируем репозиторий

[root@fedora37 ~]# createrepo /usr/share/nginx/html/repo/

* Для прозрачности настроим в NGINX доступ к листингу каталога. В файле /etc/nginx/nginx.conf в блоке server добавим следующие директивы:

	index index.html index.htm;
	autoindex on;

* Проверяем синтаксис и перезапускаем NGINX:

[root@fedora37 ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@fedora37 ~]# nginx -s reload

* Добавляем репозитарий

cat >> /etc/yum.repos.d/myrepo.repo << EOF
[myrepo]
name=myrepo
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF

[root@fedora37 yum.repos.d]# yum repolist enabled | grep my
myrepo                        myrepo

* Установим пакет percona-release из нашего репозитария

[root@fedora37 yum.repos.d]# yum install -y percona-release.noarch

[root@fedora37 yum.repos.d]# rpm -qi percona-release
Name        : percona-release
Version     : 1.0
Release     : 30
Architecture: noarch
Install Date: Fri 30 May 2025 11:30:26 AM UTC
Group       : System Environment/Base
Size        : 50440
License     : GPL-3.0+
Signature   : RSA/SHA512, Fri 07 Feb 2025 07:59:26 AM UTC, Key ID 9334a25f8507efa5
Source RPM  : percona-release-1.0-30.src.rpm
Build Date  : Fri 07 Feb 2025 07:57:17 AM UTC
Build Host  : 2d3027fecd24
Summary     : Package to install Percona GPG key and YUM repo
Description :
percona-release package contains Percona GPG public keys and Percona repository configuration for YUM

* Задания выполнены успешно

