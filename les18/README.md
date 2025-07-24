## Обновить ядро в базовой системе

Цель:
* Получить навыки работы с Git, Vagrant;
* Обновлять ядро в ОС Linux.

### Домашнее задание

1) Запустить ВМ с помощью Vagrant.
2) Обновить ядро ОС из репозитория ELRepo.
3) Оформить отчет в README-файле в GitHub-репозитории.


Тестовый стенд:
Хостовая машина Ubuntu 22.04, Vagrant 2.4.7, Virtualbox 7.1.10 

#### 1. Запустить ВМ с помощью Vagrant

* Добавляю в vagrant локальный образ для CentOS 8 Stream

root@Home:~/otus/my# curl -l -O https://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-Vagrant-8-20230822.0.x86_64.vagrant-virtualbox.box  
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current  
                                 Dload  Upload   Total   Spent    Left  Speed  
100 1266M  100 1266M    0     0  10.5M      0  0:02:00  0:02:00 --:--:-- 9991k  

root@Home:~/otus/my# vagrant box add --name generic/centos8s ./CentOS-Stream-Vagrant-8-20230822.0.x86_64.vagrant-virtualbox.box   
==> box: Box file was not detected as metadata. Adding it directly...  
==> box: Adding box 'generic/centos8s' (v0) for provider:   
    box: Unpacking necessary files from: file:///root/otus/my/CentOS-Stream-Vagrant-8-20230822.0.x86_64.vagrant-virtualbox.box  
==> box: Successfully added box 'generic/centos8s' (v0) for ''!  

* Проверяю наличие образа

root@Home:~/otus/my# vagrant box list  
centos/7         (virtualbox, 2004.01)  
generic/centos8s (virtualbox, 0)  

* Создаю Vagrantfile
root@Home:~/otus/my/les18# cat Vagrantfile  
\# -*- mode: ruby -*-
\# vi: set ft=ruby :

\# Описываем Виртуальные машины  

MACHINES = {  
  \# Указываем имя ВМ "kernel update"  
  :"kernel-update" => {  
              #Какой vm box будем использовать  
              :box_name => "generic/centos8s",  
              #Указываем box_version  
              #:box_version => "4.3.4",  
              #Указываем количество ядер ВМ  
              :cpus => 2,  
              #Указываем количество ОЗУ в мегабайтах  
              :memory => 1024,  
            }  
}  

Vagrant.configure("2") do |config|  
  MACHINES.each do |boxname, boxconfig|  
    # Отключаем проброс общей папки в ВМ  
    config.vm.synced_folder ".", "/vagrant"  
    # Применяем конфигурацию ВМ  
    config.vm.define boxname do |box|  
      box.vm.box = boxconfig[:box_name]  
     # box.vm.box_version = boxconfig[:box_version]  
      box.vm.host_name = boxname.to_s  
      box.vm.provider "virtualbox" do |v|  
        v.memory = boxconfig[:memory]  
        v.cpus = boxconfig[:cpus]  
      end  
    end  
  end  
end  

* Запускаю ВМ

root@Home:~/otus/my/les18# vagrant up  
Bringing machine 'kernel-update' up with 'virtualbox' provider...  
==> kernel-update: Importing base box 'generic/centos8s'...  
==> kernel-update: Matching MAC address for NAT networking...  
==> kernel-update: Setting the name of the VM: les18_kernel-update_1753380365262_96647  
==> kernel-update: Clearing any previously set network interfaces...  
==> kernel-update: Preparing network interfaces based on configuration...  
    kernel-update: Adapter 1: nat  
==> kernel-update: Forwarding ports...  
    kernel-update: 22 (guest) => 2222 (host) (adapter 1)  
==> kernel-update: Running 'pre-boot' VM customizations...  
==> kernel-update: Booting VM...  
==> kernel-update: Waiting for machine to boot. This may take a few minutes...  
    kernel-update: SSH address: 127.0.0.1:2222  
    kernel-update: SSH username: vagrant  
    kernel-update: SSH auth method: private key  
    kernel-update:   
    kernel-update: Vagrant insecure key detected. Vagrant will automatically replace  
    kernel-update: this with a newly generated keypair for better security.  
    kernel-update:   
    kernel-update: Inserting generated public key within guest...  
    kernel-update: Removing insecure key from the guest if it's present...  
    kernel-update: Key inserted! Disconnecting and reconnecting using new SSH key...  
==> kernel-update: Machine booted and ready!  
==> kernel-update: Checking for guest additions in VM...  
    kernel-update: No guest additions were detected on the base box for this VM! Guest  
    kernel-update: additions are required for forwarded ports, shared folders, host only  
    kernel-update: networking, and more. If SSH fails on this machine, please install  
    kernel-update: the guest additions and repackage the box to continue.  
    kernel-update:   
    kernel-update: This is not an error message; everything may continue to work properly,  
    kernel-update: in which case you may ignore this message.  
==> kernel-update: Setting hostname...  
==> kernel-update: Rsyncing folder: /root/otus/my/les18/ => /vagrant  

* Подключаюсь к ВМ по ssh

root@Home:~/otus/my/les18# vagrant ssh kernel-update  
[vagrant@kernel-update ~]$ cat /etc/redhat-release  
CentOS Stream release 8  

* Проверяю подключение VirtualBox Shared Folders

[root@kernel-update ~]# ls /vagrant/  
Vagrantfile  Vagrantfile.init  

* Проверяю версию ядра

[root@kernel-update ~]# uname -r  
4.18.0-511.el8.x86_64  

* Фиксим пути в yum репозитарии 


[root@kernel-update ~]# sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo  
[root@kernel-update ~]# sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo  
[root@kernel-update ~]# sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo  
[root@kernel-update ~]#   
[root@kernel-update ~]# sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*  
[root@kernel-update ~]# sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*  
[root@kernel-update ~]#   
[root@kernel-update ~]# yum clean all       

* Подключаю elrepo репозитарий
\[root@kernel-update ~]# yum install -y https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
 
* Установливаю последнее ядро из репозитория elrepo-kernel:
sudo yum --enablerepo elrepo-kernel install kernel-ml -y

Installed:
  kernel-ml-6.15.7-1.el8.elrepo.x86_64 kernel-ml-core-6.15.7-1.el8.elrepo.x86_64 kernel-ml-modules-6.15.7-1.el8.elrepo.x86_64

Complete!

* Обновляю конфигурацию загрузчика

[root@kernel-update ~]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
done

* Выбираю загрузку нового ядра по-умолчанию

[root@kernel-update ~]# grub2-set-default 0
   	
*  Перезагружаю ВМ

[root@kernel-update ~]# reboot

* Проверяю версию ядра

root@Home:~/otus/my/les18# vagrant ssh kernel-update  
Last login: Thu Jul 24 18:17:19 2025 from 10.0.2.2  
[vagrant@kernel-update ~]$ uname -a  
Linux kernel-update 6.15.7-1.el8.elrepo.x86_64 #1 SMP PREEMPT_DYNAMIC Thu Jul 17 14:41:53 EDT 2025 x86_64 x86_64 x86_64 GNU/Linux  


