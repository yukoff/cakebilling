[[InstallResinToc <<](.md) ] [[InstallResinToc <](.md) ] [[CakeToc В начало](.md) ] [[InstallResinInGentoo >](.md) ] [[InstallWebapp >>](.md) ]

Скачиваем тарбол **resin** с [caucho.com](http://caucho.com/):

```
root@cake# wget http://caucho.com/download/resin-3.0.14.tar.gz
```

Распаковываем архив:
```
root@cake# tar –zxf resin-3.0.14.tar.gz
```

Переходим в директорию resin-3.0.14:
```
root@cake# cd resin-3.0.14
```

Запускаем **configure** со следующими параметрами:
```
root@cake# ./configure --prefix=/opt/resin --disable-ssl --enable-jni
```

Если запуск **configure** завершился не удачно проверьте правильность установки параметра **JAVA\_HOME**.
Параметр должен присутствовать. Проверить можно следующим образом:
```
root@cake# export | grep JAVA_HOME
declare -x JAVA_HOME="/opt/jrockit-jdk-bin-1.5.0.03"
```

После успешного завершения запуска **configure** запустите:
```
make all install
```

В результате вы должны получить установленный сервер **resin** в директории **/opt/resin**. Запустить сервер можно следующей командой:
```
/opt/resin/bin/httpd.sh
```

В этом случае сервер запустится в режиме отладки и не уйдет в фон. Для того чтобы запустить сервер в фоне выполните команду:
```
/opt/resin/bin/httpd.sh start
```

Остановить сервер можно командой:
```
/opt/resin/bin/httpd.sh stop
```

После запуска сервера зайдите по адресу **`http://ваш-ip:8080/`**.
Если вы все правильно сделали вы должны будете увидеть страничку документации сервера **resin**.

[[InstallResinToc <<](.md) ] [[InstallResinToc <](.md) ] [[CakeToc В начало](.md) ] [[InstallResinInGentoo >](.md) ] [[InstallWebapp >>](.md) ]