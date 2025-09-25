#!/bin/sh
# Переходим в директорию /etc/openvpn и инициализируем PKI
cd /etc/openvpn
/usr/share/easy-rsa/easyrsa init-pki
echo 'My Common Name' | /usr/share/easy-rsa/easyrsa build-ca nopass
# Генерируем необходимые ключи и сертификаты для сервера 
echo 'server' | /usr/share/easy-rsa/easyrsa gen-req server nopass
echo 'yes' | /usr/share/easy-rsa/easyrsa sign-req server server 
/usr/share/easy-rsa/easyrsa gen-dh
#openvpn --genkey secret ca.key

# Генерируем необходимые ключи и сертификаты для клиента
echo 'client' | /usr/share/easy-rsa/easyrsa gen-req client nopass
echo 'yes' | /usr/share/easy-rsa/easyrsa sign-req client client

# Зададим параметр iroute для клиента
echo 'iroute 10.10.10.0 255.255.255.0' > /etc/openvpn/client/client

# Копируем файлы сертификатов на хостовую машину
cp /etc/openvpn/pki/ca.crt /vagrant/
cp /etc/openvpn/pki/issued/client.crt /vagrant/
cp /etc/openvpn/pki/private/client.key /vagrant/
