[[annonce <<](.md) ] [[InstallPostgresToc <](.md) ] [[CakeToc В начало](.md) ] [[InstallPostgresInGentoo >](.md) ] [[InstallFreeRadiusToc >>](.md) ]

Скачиваем тарбол с http://www.postgresql.org

Расспаковываем, запускаем configure:
```
root@cake# ./configure --prefix=/opt/postgresql --with-perl --with-maxbackends=1024
```

После того как выполнение configure было успешно завершено, запускаем следующую команду:
```
 root@cake# make all install
```

После успешного завершения команды получим установленный **PostgreSQL** сервер с поддержкой **perl** (параметр **--with-perl** ) и с возможностью использовать до 1024 соединений (без указания опции PostgreSQL позволяет использовать только 32 соединения).

Добавим группу и пользователя от которых будет работать PostgreSQL:
```
root@cake# groupadd postgres
root@cake# useradd -g postgres -s /bash/bash postgres
```

Создадим каталог с базами данных, конфигурационными файлами и журналами и экспортируем его в переменную **PGDATA:**
```
root@cake# mkdir /opt/postgresql/var/data
root@cake# chown postgres:postgres /opt/postgresql/var/data
root@cake# export PGDATA="/opt/postgresql/var/data"
```

Далее инициализируем служебные базы данных:
```
root@cake# /opt/postgresql/bin/initdb 
```

Производим запуск PostgreSQL:
```
root@cake# su - postgres -c "/opt/postgresql/bin/pg_ctl start -D \ '/opt/postgresql/var/data' \
-l '/opt/postgresql/var/data/postgresql.log' -o '-i '"
```

О параметре **-i** при запуске PostgreSQL подробнее смотрите в примечании ниже.

Добавляем переменные окружения:
```
root@cake# export PATH="$PATH:/opt/postgresql/bin"
```

Добавляем в **/etc/ld.so.conf**
```
/opt/postgresql/lib
```

Запускаем ldconfig:
```
root@cake# ldconfig
```

Если в результате у вас все операции завершились без ошибок, то можно переходить к [настройке](ConfiguringPostgres.md) PostgreSQL сервера.

##### Примечание #####
По умолчанию в PostgreSQL 7.x отключена поддержка tcp/ip протокола. При включении ее PostgreSQL принимает подключения только от **localhost**. Если планируете установить FreeRADIUS на другой машине, вам необходимо добавить в **$PGDATA/pg\_hba.conf**
```
# IPv4-style local connections:
host all all 192.168.1.1 255.255.255.255 password
```

где 192.168.1.1 это ip адрес вашего RADIUS сервера.

[[annonce <<](.md) ] [[InstallPostgresToc <](.md) ] [[CakeToc В начало](.md) ] [[InstallPostgresInGentoo >](.md) ] [[InstallFreeRadiusToc >>](.md) ]