[[InstallPppdPptpdToc <<](.md) ] [[InstallPppdPptpdInGentoo <](.md) ] [[CakeToc В начало](.md) ] [[InstallResinToc >](.md) ] [[InstallResinToc >>](.md) ]


Первым насторим **radiusclient** для работы с нашим **FreeRADIUS** сервером.

Добавляем в **/etc/radiusclient/servers** наш **RADIUS** сервер.

```
localhost test
```

Изменяем в **/etc/radiusclient/radiusclient.conf** сервер для авторизации и аккаунтинга.

```
authserver localhost:1812
acctserver localhost:1813
```

Далее переходим к настройке **ppp** для **pptp** туннелизации.

Изменяем файл **/etc/ppp/options.pptpd**:

```
lock

name pptpd

nodeflate
nobsdcomp

auth
+chap
+mschap-v2
+mschap
-pap
nomppe
silent

#добавьте эту опцию если у ваших клиентов реальные ip адреса
proxyarp

ms-dns 192.168.1.1
plugin /usr/lib/pppd/2.4.2/radius.so

```

**ms-dns** - ваш **DNS** сервер или **DNS** сервер провайдера.

**ppp** будет принимать запросы только с типом авторизации **chap mschap mschap-v2**,

**pap** отключен в связи с тем что передает пароль в открытом виде.

**nomppe nomppc** - отключаем компрессию и шифрование.

**silent** - работать пассивно. Ожидаем запросы от клиента. В противном случае сервер начинает запрашивать параметры у клиента. В результате чего windows VPN работает не стабильно.

**nodeflate nobsdcomp** - отключаем компрессию.

**plugin /usr/lib/pppd/2.4.2/radius.so** - подключаем плагин radius.so. Если у вас не 2.4.2 версия измените путь так чтоб он соответствовал вашей версии. Такой путь специфичен для Gentoo дистрибутива, в других дистрибутивах плагин может располагаться в другом месте.


На этом настройка **ppp** для **pptpd** закончена.

Переходим к **pptpd**.

Редактируем файл **/etc/pptpd.conf**:

```
option /etc/ppp/options.pptpd
localip 192.168.0.1
remoteip 192.168.0.2-254
```

**option /etc/ppp/options.pptpd** - указываем файл с опциями для **ppp** при поднятии инкапсуляции.
**localip 192.168.0.1** - **ip** адрес сервера **VPN** сети.
**remoteip 192.168.0.2-254** - **ip** адреса клиентов **VPN** сети.

Далее необходимо будет запустить pptpd. В Gentoo Linux:
```
/etc/init.d/pptpd start
```

На других платформах может быть аналогично.

Добавляем в автозагрузку. В Gentoo Linux:
```
rc-update add pptpd default
```

На других платформах посмотрите в документации.

Если вы все настроили правильно, то осталось только добавить пользователей в базу данных и начинать работать.
Так же можно протестировать систему без СУБД, как было описано в предыдущем документе.

[[InstallPppdPptpdToc <<](.md) ] [[InstallPppdPptpdInGentoo <](.md) ] [[CakeToc В начало](.md) ] [[InstallResinToc >](.md) ] [[InstallResinToc >>](.md) ]