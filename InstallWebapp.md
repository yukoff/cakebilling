[[InstallResinToc <<](.md) ] [[InstallResinInGentoo <](.md) ] [[CakeToc В начало](.md) ] [> ](.md) [>> ](.md)

Скачиваем war архив с web-app интерфейсом
```
root@cake# wget http://cakebilling.googlecode.com/files/cake.war
```

Копируем war архив в **/opt/resin/webapps**, меняем права
```
root@cake# cp cake.war /opt/resin/webapps/cake.war
root@cake# chown resin:resin /opt/resin/webapps/cake.war
```

Конфигурируем web-app посредством правки файла **webapps/cake/WEB-INF/cake.xml**
```
<cake
        db_user="cake"
        db_password="yourpassword"
        db_charset="WIN"
        db_driver="org.postgresql.Driver"
        db_connstr="jdbc:postgresql://localhost/cake"
/>
```

Перезапускаем Resin
```
root@cake$ /etc/init.d/resin restart
```

Проверяем, вводим в браузере что то типа **`http://igate:8080/cake`**, где igate -- это наш шлюз в интернет.

**Note:**
login: admin
password: 1234

Администрируем, работаем.

[[InstallResinToc <<](.md) ] [[InstallResinInGentoo <](.md) ] [[CakeToc В начало](.md) ] [> ](.md) [>> ](.md)