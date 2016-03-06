[[InstallFreeRadiusToc <<](.md) ] [[InstallFreeRadiusToc <](.md) ] [[CakeToc В начало](.md) ] [[InstallFreeRadiusInGentoo >](.md) ] [[InstallPppdPptpdToc >>](.md) ]

Скачиваем тарбол с http://freeradius.org

Распаковываем, запускаем **configure**:
```
root@cake#./configure --prefix=/opt/freeradius \
--with-rlm-sql-postgresql-lib-dir=/opt/postgresql/lib \
--with-rlm-sql-postgresql-include-dir=/opt/postgresql/include
```

**Note:**
Указанные **--with-rlm-sql-postgresql-lib-dir** и **--with-rlm-sql-postgresql-include-dir** правильны только,
если вы устанавливали **~PostgreSQL** из исходников в папку **/opt/postgresql**. Если вы ставили из портов или из пакетов, укажите другие каталоги. Или же можете не указывать вообще, если библиотеки и заголовочные файлы лежат в **/usr** или в **/usr/local**.

После того как **configure** завершил работу, выполняем:
```
root@cake# make all install
```

Далее добавляем пользователя и группу от которых будет работать **FreeRADIUS**:
```
root@cake# groupadd radiusd
root@cake# useradd -g radiusd -s /bash/bash radiusd
```

Изменяем права на **/opt/freeradius**:
```
root@cake# chown -R radiusd:radiusd /opt/freeradius
```

Если в результате у вас все операции завершились без ошибок, то можно переходить к [настройке](ConfiguringFreeRadius.md) FreeRADIUS сервера.

[[InstallFreeRadiusToc <<](.md) ] [[InstallFreeRadiusToc <](.md) ] [[CakeToc В начало](.md) ] [[InstallFreeRadiusInGentoo >](.md) ] [[InstallPppdPptpdToc >>](.md) ]