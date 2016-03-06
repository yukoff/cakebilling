[[InstallFreeRadiusToc <<](.md) ] [[InstallFreeRadiusFromSources <](.md) ] [[CakeToc В начало](.md) ] [[ConfiguringFreeRadius >](.md) ] [[InstallPppdPptpdToc >>](.md) ]

Для работы биллинга при сборке FreeRADIUS сервера необходимо выставить USE флаг **postgres**

Проверяем:
```
root@cake#USE="postgres" emerge -vp freeradius

These are the packages that I would merge, in order:

Calculating dependencies ...done!
[ebuild  N    ] net-dialup/freeradius-1.1.3-r2  USE="frxp kerberos ldap mysql pam postgres snmp ssl udpfromto -debug -edirectory -frascend -frnothreads" 2,996 kB
Total size of downloads: 0 kB
```

Устанавливаем **FreeRADIUS**:
```
root@cake# USE="postgres" emerge freeradius
```

Переходим к [настройке](ConfiguringFreeRadius.md).

[[InstallFreeRadiusToc <<](.md) ] [[InstallFreeRadiusFromSources <](.md) ] [[CakeToc В начало](.md) ] [[ConfiguringFreeRadius >](.md) ] [[InstallPppdPptpdToc >>](.md) ]