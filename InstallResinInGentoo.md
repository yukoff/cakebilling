[[InstallResinToc <<](.md) ] [[InstallResinFromSources <](.md) ] [[CakeToc В начало](.md) ] [[InstallWebapp >](.md) ] [[InstallWebapp >>](.md) ]

Устанавливаем **Resin**:
```
root@cake# emerge resin
```

Запускаем:
```
root@cake# /etc/init.d/resin start
```

Добавляем его в автозагрузку:
```
root@cake# rc-update add resin default
```

Для функционарования **web-app** интерфейса администрирования биллинга не обязательно использовать именно **Resin**. Это может быть любой сервер с поддержкой **JSP/Servlet**, например **Tomcat**, **Sun java server** или **Macromedia JRUN**.

**Web-app** в каждом сервере настраивается в соответствии со спецификой этого сервера.

[[InstallResinToc <<](.md) ] [[InstallResinFromSources <](.md) ] [[CakeToc В начало](.md) ] [[InstallWebapp >](.md) ] [[InstallWebapp >>](.md) ]