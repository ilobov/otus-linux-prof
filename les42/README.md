## Развертывание веб приложения

### Задание

Варианты стенда:

nginx + php-fpm (laravel/wordpress) + python (flask/django) + js(react/angular);
nginx + java (tomcat/jetty/netty) + go + ruby;
можно свои комбинации.

Реализации на выбор:

на хостовой системе через конфиги в /etc;
деплой через docker-compose.

Для усложнения можно попросить проекты у коллег с курсов по разработке


К сдаче принимается:

vagrant стэнд с проброшенными на локалхост портами
каждый порт на свой сайт
через нжинкс

Формат сдачи ДЗ - vagrant + ansible


### Решение

Будем настраивать стенд в следующей конфигурации:

nginx + php-fpm (wordpress) + python (flask) + node js;

* Развертывание стенда

   Запускаем создание ВМ через Vagrant   

    vargant up


#### Проверка работы 

На локальном компьютере проверяет работу приложений по портам 8081(Flask), 8082(Node js), 8083(wordpress) 

  1. Flask

![Flask](https://github.com/ilobov/otus-linux-prof/blob/main/les42/png/flask.png)

  2. Node js

![Node](https://github.com/ilobov/otus-linux-prof/blob/main/les42/png/nodejs.png)

  3. Wordpress

![Wordpress](https://github.com/ilobov/otus-linux-prof/blob/main/les42/png/wordpress.png)

