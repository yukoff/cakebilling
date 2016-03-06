[[InstallPostgresToc <<](.md) ] [[InstallPostgresFromSources <](.md) ] [[CakeToc В начало](.md) ] [[ConfiguringPostgres >](.md) ] [[InstallFreeRadiusToc >>](.md) ]

Устанавливаем PostgreSQL:
```
root@cake$ emerge postgresql
```

Инициализируем служебные базы данных:
```
root@cake$ emerge --config =postgresql-7.4.5
```

**Note:**
Перед запуском поменяйте номер версии **PostgreSQL** на тот который установился.

Редактируем **/etc/conf.d/postgrsql**
```
#PGOPTS=""
PGOPTS="-i"
```

О параметре **-i** при запуске **~PostgreSQL** подробнее смотрите ниже в примечании.

Note:
В gentoo **$PGDATA** прописан в **/etc/conf.d/postgresql**

Запускаем и прописываем в автозагрузку PostgreSQL:
```
/etc/init.d/postgresql start
rc-update add postgresql default
```

В результате если у вас получился рабочий **PostgreSQL** сервер, переходите к [настройке](ConfiguringPostgres.md).

##### Примечание #####
По умолчанию в PostgreSQL 7.x отключена поддержка tcp/ip протокола. При включении ее PostgreSQL принимает подключения только от **localhost**. Если планируете установить FreeRADIUS на другой машине, вам необходимо добавить в **$PGDATA/pg\_hba.conf**
```
# IPv4-style local connections:
host all all 192.168.1.1 255.255.255.255 password
```

где 192.168.1.1 это ip адрес вашего RADIUS сервера.

[[InstallPostgresToc <<](.md) ] [[InstallPostgresFromSources <](.md) ] [[CakeToc В начало](.md) ] [[ConfiguringPostgres >](.md) ] [[InstallFreeRadiusToc >>](.md) ]