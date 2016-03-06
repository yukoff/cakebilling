[[InstallPppdPptpdToc <<](.md) ] [[InstallPppdPptpdToc <](.md) ] [[CakeToc В начало](.md) ] [[InstallPppdPptpdInGentoo >](.md) ] [[InstallResinToc >>](.md) ]

В ppp-2.4.3 поддержка RADIUS плагина, а так же лимитирования и поддержки MPPE и MSCHAP включено по умолчанию. Дополнительно включать ничего не требуется.

Скачиваем тарбол **ppp** с [ftp://ftp.samba.org/pub/](ftp://ftp.samba.org/pub/):
```
root@cake# wget ftp://ftp.samba.org/pub/ppp/ppp-2.4.3.tar.gz
```

Распаковываем архив:
```
root@cake# tar –zxf ppp-2.4.3.tar.gz
```

Переходим в директорию ppp-2.4.3:
```
root@cake# cd ppp-2.4.3
```

Переходим к сборке pppd:
```
root@cake# ./configure
root@cake# make
root@cake# make install
root@cake# make install-etcppp
```

После успешного завершения make install
в каталог /usr/local/sbin будут размещены: pppd, chat, pppstats и pppdump.
В каталог /usr/local/man соответсвующие им man страницы.
В каталоге /etc/ppp будут размещены настройки по умолчанию.

Файлы используемые RADIUS плагином необходимо установить вручную.
Перед этим создадим каталог /etc/radiusclient:
```
mkdir /etc/radiusclient
```

Далее переходим в директорию с конфигурационными файлами и копируем их в /etc/radiusclient:
```
cd pppd/plugins/radius/etc
cp * /etc/radiusclient
```

Далее необходимо изменить пути в файле radiusclient.conf. К примеру с issue /usr/local/etc/radiusclient/issue на issue /etc/radiusclient/issue. Эту операцию необходимо проделать для всех файлов находящихся в /etc/radiusclient.

Если вам требуется поддержка MPPE/MPPC то еще требуется паложить патч на ядро http://www.polbox.com/h/hs001/.
Скачиваем патч для вашей версии ядра:

```
root@cake# cd /usr/src/linux
root@cake# wget http://www.polbox.com/h/hs001/linux-2.6.10-mppe-mppc-1.2.patch.gz
```

распакуем и установим патч:

```
root@cake# zcat linux-2.6.10-mppe-mppc-1.2.patch.gz | patch -p1
```

Если патч установился успешно то запускаем конфигурирование ядра:

```
root@cake# make menuconfig
```

Включаем все опции касающиеся PPP модулями (в противном случае могут возникать проблемы с MPPE).
Пересобираем ядро.

```
root@cake# make dep
root@cake# make modules
root@cake# make modules_install
root@cake# make install
```

Если все прошло нормально, можно попробовать загрузить модуль. Если поддержка MPPE была включена как модуль, и версия ядра не изменялась систему можно не перегружать. Достаточно выполнить

```
root@cake# depmod -a
root@cake# modprobe ppp_mppe_mppc
root@cake# lsmod|grep ppp_mppe_mppc
      ppp_mppe_mppc 20568 0 (unused)
      ppp_generic 16444 0 [ppp_mppe_mppc]
```

Далее добавьте необходимые модули в автозагрузку.

Переходим к установке pptpd.

Скачиваем тарбол pptpd с ((http://prdownloads.sourceforge.net/poptop/pptpd-1.1.4-b4.tar.gz?download)).
Распаковываем, запускаем configure
```
root@cake#./configure --prefix=/opt/pptpd --with-libwrap --with-bcrelay
```

После того как configure отработал (надеюсь без ошибок), выполняем:
```
make all install
```

Переходим к [настройке](ConfiguringPppdPptpd.md).

[[InstallPppdPptpdToc <<](.md) ] [[InstallPppdPptpdToc <](.md) ] [[CakeToc В начало](.md) ] [[InstallPppdPptpdInGentoo >](.md) ] [[InstallResinToc >>](.md) ]