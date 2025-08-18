## Docker

### Цель домашнего задания

Освоить базовые принципы работы с Docker, научиться создавать, настраивать и управлять контейнерами

### Этапы выполнения

1. Установка Docker

$ curl -fsSL https://get.docker.com -o get-docker.sh  
$ sudo sh ./get-docker.sh --dry-run  

```
# Executing docker install script, commit: bedc5d6b3e782a5e50d3d2a870f5e1f1b5a38d5c  
apt-get -qq update >/dev/null  
DEBIAN_FRONTEND=noninteractive apt-get -y -qq install ca-certificates curl >/dev/null  
install -m 0755 -d /etc/apt/keyrings  
curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" -o /etc/apt/keyrings/docker.asc  
chmod a+r /etc/apt/keyrings/docker.asc  
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable" > /etc/apt/sources.list.d/docker.list  
apt-get -qq update >/dev/null  
DEBIAN_FRONTEND=noninteractive apt-get -y -qq install docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-ce-rootless-extras docker-buildx-plugin docker-model-plugin >/dev/null  
```

Перехожу в root: sudo -i
Запускаю полученный набор команд

После установки запускаю сервис и проверяю версию докера:
service docker start
root@liv-HP:~# docker -v
Docker version 28.3.3, build 980b856

2. Docker compose установлен вместе с docker

root@liv-HP:~# docker compose version
Docker Compose version v2.39.1

3. Создаю кастомный образ nginx на базе alpine. 

* Создаю Dockerfile  
FROM alpine:latest  

RUN apk add --no-cache nginx  

COPY index.html /usr/share/nginx/html/index.html  
COPY nginx.conf /etc/nginx/nginx.conf  

EXPOSE 80  

CMD ["nginx", "-g", "daemon off;"]  

* Создаю свой index.html
* Создаю свой файл nginx.conf

* Создаю акаунт на Docker Hub (ilobov) и свой репозитарий otus

* Создаю docker image
sudo docker build -t ilobov/otus:1.1 .

* Проверяю image

sudo docker run -d -p 8081:80 --name nginx ilobov/otus:1.1

Подключаюся в браузере http://localhost:8081 

* Подключаюсь к Docker Hub

sudo docker login -u "ilobov" -p "********" docker.io

* Заливаю образ

sudo docker push ilobov/otus:1.1

4. Определите разницу между контейнером и образом

Образ - это шаблон для создания контейнеров. Контейнер - это динамический экземпляр образа, который запущен и работает в изолированной среде.

5. Ответьте на вопрос: Можно ли в контейнере собрать ядро?

Нельзя. Контейнеры используют ядро хостовой машины.

Ссылка на репозитарий:

docker pull ilobov/otus:1.1
