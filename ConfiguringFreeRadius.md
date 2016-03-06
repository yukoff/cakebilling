[[InstallFreeRadiusToc <<](.md) ] [[InstallFreeRadiusInGentoo <](.md) ] [[CakeToc В начало](.md) ] [[InstallPppdPptpdToc >](.md) ] [[InstallPppdPptpdToc >>](.md) ]


Все переменные что не описаны в файлах удалите. Они не требуются для работы **FreeRADIUS** с **pppd**.

Сначала редактируем файл **etc/raddb/radiusd.conf**:
```
## some need locations variables

# Различные файловые переменные.
# Приведено для gentoo.
# Если ставите из исходников,
# скопируйте эти переменные из
# /opt/freeradius/etc/raddb/radiusd.conf

prefix = /usr
exec_prefix = ${prefix}
sysconfdir = /etc
localstatedir = /var
sbindir = ${exec_prefix}/sbin
logdir = ${localstatedir}/log/radius
raddbdir = ${sysconfdir}/raddb
radacctdir = ${logdir}/radacct

# Месторасположение конфигурационных и лог файлов.
confdir = ${raddbdir}
run_dir = ${localstatedir}/run/radiusd

# Каталог с подгружаемыми модулями.
libdir = ${exec_prefix}/lib

# Месторасположение pid-файла. Содержащего идентификатор процесса.
pidfile = ${run_dir}/radiusd.pid

# Имя пользователя и группа от которых запускается FreeRADIUS
user = radiusd
group = radiusd

# Максимальное время (в секундах) используемое для обработки запроса.
max_request_time = 30

# Удалить запросы которые обрабатываются более чем max_request_time
delete_blocked_requests = no

# Время ожидания (в секундах) перед очисткой reply запроса отправленного NAS.
cleanup_delay = 5

# Максимальное количество запросов хранимых сервером. Это число должно быть равно количеству клиентов помноженному на 256.
# К примеру для четырех клиентов оно будет 1024.
max_requests = 5120

#Использовать все доступные интерфейсы.
bind_address = *

# Закрепить за FreeRADIUS конкретный port. Если указан ноль,
# то значение берется из /etc/services
port = 0

# Запретить/разрешить ip адреса в dns имена.
# Включение этой опции может сильно снизить производительность.
hostname_lookups = no

# Создавать/несоздавать отладочные файлы при падении сервера.
allow_core_dumps = no

# Разрешить использование регулярных выражений.
regular_expressions = yes
extended_expressions = yes

# Записывать полный User-Name аттрибут если найден в запросе.
log_stripped_names = no

# Записывать в лог попытки авторизации.
log_auth = yes

# Записывать в логи пароли при авторизации.
# log_auth_badpass - не корректные пароли
# log_auth_goodpass - корректные пароли

log_auth_badpass = yes
log_auth_goodpass = no

# Включить/выключить коллизию пользователей.
usercollide = no

# конвертировать логин и/или пароль до или после авторизации.
lower_user = no
lower_pass = no

# удалить пробелы в логине и/или пароле.
nospace_user = no
nospace_pass = no

# настройки безопасности от возможных DoS аттак.
security {

        # Максимальное допустимое количество аттрибутов в RADIUS пакете.
        max_attributes = 200

        # Задержка (в секундах) перед отправкой Access-Reject пакета.
        reject_delay = 1

        # Не отвечать на запросы Status-Server
        status_server = no

}


# Конфигрурация клиентов RADIUS сервера.
# Описывается в отдельном файле.
$INCLUDE ${confdir}/clients.conf

# Отключить snmp поддержку.
snmp=no

# Настрока пула процессов.

thread pool {

        # количество первоначально запущенных процессов.
        start_servers = 5

        # Максимально возможное количество процессов.
        max_servers = 32

        # Динамическая регулировка количества процессов.
        min_spare_servers = 3
        max_spare_servers = 10

        # Количество принимаемых запросов процессом. МОжет помочь при утечках памяти в
        # RADIUS сервере. Если выставить 300, процессы будут периодически перегружаться
        # для уборки мусора.
        max_requests_per_server = 0

}

# Секция конфигурации динамических модулей.

modules {

        # Модуль PAP авторизации.
        # Необходим для обработки запросов с PAP авторизацией.
        # encryption_scheme указывает в каком виде хранятся пароли.
        # clear - подразумевает в открытом виде.
        pap {
                encryption_scheme = clear
        }

        # Модуль CHAP авторизации.
        # Необходим для обработки запросов с CHAP авторизацией.
        # authtype подразумевает обработку запросов только с аттрибутом Auth-Type=CHAP
        chap {
                authtype = CHAP
        }

        # Модуль преобработки запросов.
        # Т.е. перед авторизацией пакета.
        preprocess {
        # huntgroups - хинт группы см. файл huntgoups.
        # hints - хинты.
        
                huntgroups = ${confdir}/huntgroups
                hints = ${confdir}/hints

        # Обработка Cisco VSA.
                with_cisco_vsa_hack = no

        }

        # Модуль Microsoft CHAP авторизации.
        # Поддерживает так же еще и Microsoft CHAP v2
        # authtype подразумевает обработку запросов только с аттрибутом Auth-Type=MS-CHAP
        # use_mppe = no указывает на отсутствие шифрования VPN туннеля.
        mschap {
                authtype = MS-CHAP
                use_mppe = no
        }
        
        # Модуль записей Livingston RADIUS типа.
        # usersfile содержит авторизационные записи пользователей.
        # Рекомендуется использовать только для тестов и выставления значений по умолчанию.
        # acctusersfile содержит пользователей подлежащих учету (аккаунтингу).
        # compat - совместимость. При использовании файлов только FreeRADIUS можно отключить.
        files {
                usersfile = ${confdir}/users
                acctusersfile = ${confdir}/acct_users
                compat = no
        }

        # Запись детального лога аккаунтинговых пакетов.
        detail {
                detailfile = ${radacctdir}/%{Client-IP-Address}/detail-%Y%m%d
                detailperm = 0600
        }

        # Запись детального лога пакетов авторизации.
        detail auth_log {
                detailfile = ${radacctdir}/%{Client-IP-Address}/auth-detail-%Y%m%d
                detailperm = 0600
        }


        # Запись детального лога reply пакетов.
        #
        detail reply_log {
                detailfile = ${radacctdir}/%{Client-IP-Address}/reply-detail-%Y%m%d
                detailperm = 0600
        }

        # Создать уникальный ключ для аккаунтинг сессии.
        # Многие NAS повторно используют Acct-Session-ID.
        # key перечисление аттрибутов для генерации Acct-Session-ID
        acct_unique {
                key = "User-Name, Acct-Session-Id, NAS-IP-Address, Client-IP-Address, NAS-Port"
        }

        # Конфигурация авторизации и аккаунтинга посредством СУБД
        # содержится в отдельном файле cakesql.conf
        $INCLUDE ${confdir}/cakesql.conf

}

# Авторизация
# сначала идет пакет передается в preprocess
# где может быть модифицирован.
# Далее chap mschap обрабатывают chap и mschap авторизацию.

authorize {
        preprocess
        chap
        mschap

        # Ведем логи пакетов авторизации.
        auth_log
        files
        # отключаем авторизацию через sql
        # сначала необходимо отладить проверить на уровне файлов.
        #cake_sql
}

# Аунтификация
# Секция содержит модули доступные, для аунтификации.

authenticate {
            
       Auth-Type PAP { pap }
       Auth-Type CHAP { chap }
       Auth-Type MS-CHAP { mschap }
}

# Преобразование аккаунтинговых пакетов.

preacct {
        preprocess
}


#
# Секция ведения аккаунтинга.
#
accounting {
        # Создание Acct-Session-Id если ваш NAS генрит их вполне корректно можете
        # убрать.
        acct_unique

        # Создавать detail лог.
        detail

        # Помещать аккаунтинговые пакеты в СУБД
        # cake_sql
}

# Секция ведения логов reply-пакетов
post-auth {

        # Вести детальный лог репли пакетов.
        reply_log
}

```

Далее переходим к **clients.conf** данный файл содержит конфигурацию о клиентах (**NAS**) работающих с **RADIUS** сервером.

**clients.conf**:
```
# секция описывает клиента c ip адресом 127.0.0.1.
# secret - секретное слово указывается еще на NAS желательно выбрать что-то отличное от test
# shortname - короткое имя используемое в качестве псевдонима.
# nastype - используется radcheck.pl т.е. внешним скриптом. В нашей системе оно используется.
# Поэтому выставленно other.
# Подобным же образом добавьте других клиентов.
client 127.0.0.1 {
       secret = test
       shortname = localhost
       nastype = other
}

```

Скачиваем **dictionary.ppp**:
```
wget -c http://cakebilling.googlecode.com/files/dictionary.ppp
```

**Note:**
dictionary.ppp так же содержится [в тарболе с файлами конфигурации](http://cakebilling.googlecode.com/files/etc.tar.bz2).

Редактируем **dictionary**:
```
$INCLUDE /usr/share/freeradius/dictionary
$INCLUDE /etc/raddb/dictionary.ppp
```

Редактируем **users**:
```
# необходимо для авторизации через SQL.
# при проведении авторизации через SQL раскоментируйте.
# DEFAULT Auth-Type:=Local

# тестовый пользователь. Если будете тестировать с pppd и mschap авторизацией пропишите
# Auth-Type:=MS-CHAP вместо Auth-Type:=Local, иначе RADIUS сервер не авторизует клиента.

test Auth-Type:=Local, User-Password == "test"
#test Auth-Type:=MS-CHAP, User-Password == "test"
                Service-Type = Framed-User,
                Framed-Protocol = PPP,
                Framed-IP-Address = 192.168.0.200,
                Framed-IP-Netmask = 255.255.255.0,
                Framed-Route = "192.168.1.0/24 192.168.200.204/32 1",
                Reply-Message = "Just Test",
                Acct-Interim-Interval = 60,
# Session-Timeout = 120,
                Framed-Routing = Broadcast-Listen,
                Framed-Compression = None
               
```

После этих изменений проверяем конфигурационные файлы:
```
root@cake# check-radiusd-config
```

вы должны получить аналогичный ответ:
```
root@cake# check-radiusd-config: line 55: 19324 Killed $sbindir/radiusd -X -p 32768 >startup.log 2>&1
Radius server configuration looks OK.
```

Запустите в одной из консолей **radiusd -X**. Далее переключитесь в соседнюю консоль и выполните:

```
root@cake# radtest test test 127.0.0.1 2 test
Sending Access-Request of id 82 to 127.0.0.1:1812
        User-Name = "test"
        User-Password = "test"
        NAS-IP-Address = cake.test.ru
        NAS-Port = 2
rad_recv: Access-Accept packet from host 127.0.0.1:1812, id=82, length=108
        Service-Type = Framed-User
        Framed-Protocol = PPP
        Framed-IP-Address = 192.168.0.200
        Framed-IP-Netmask = 255.255.255.0
        Framed-Route = "192.168.1.0/24 192.168.200.204/32 1"
        Reply-Message = "Just Test"
        Acct-Interim-Interval = 60
        Framed-Routing = Broadcast-Listen
        Framed-Compression = None
```

Если вы увидели аналогичные сообщения. **RADIUS** сервер работает.

**Note:**
Вы так же можете проверить работу с **pptpd**, для этого перейдите к его [install-ppp-pptpd установке и настройке].

После этого измените в **/etc/raddb/users**:
```
# radtest
#test Auth-Type:=Local, User-Password == "test"
# Изменяем тип авторизации для pptpd
test Auth-Type:=MS-CHAP, User-Password == "test"
```

Далее подключаемся через **VPN** соединение к нашему **pptp** серверу.

Не забудьте отключить необходимость шифрования туннеля.

Теперь осталось включить работу с **SQL** сервером. Вернемся к файлу **radiusd.conf** добавьте
в ниже преведенные секции **cake\_sql**:

```
authorize {
        # включаем авторизацию через sql
        cake_sql
}


accounting {

        # включаем помещение аккаунтинговых пакетов в СУБД
        cake_sql
}

```

Создайте файл **cakesql.conf** содержащий:
```
sql cake_sql{

        # Указываем драйвер для PostgreSQL
        driver = "rlm_sql_postgresql"

        # указываем PostgreSQL сервер.
        server = "127.0.0.1"
        # указываем логин к базе.
        login = "cake"
        # пароль который вы задавали при заведении пользователя cake.
        password = "cake"

        # Указываем базу.
        radius_db = "cake"

        # Создавать файл трассировки для SQL рапросов.
        # Создается только при указании опции -x
        sqltrace = yes
        sqltracefile = /var/log/radius/sqltrace.sql

        # Количество подключений к СУБД
        num_sql_socks = 30

        # Имя пользователя запрашиваемого в СУБД.
        # Возможно применение регулярных выражений.
        sql_user_name = "%{User-Name}"

        # запрос на авторизацию. Если запрос возвращает ничего RADIUS считает, что такого пользователя нет
        # и отдает Auth-Reject
        authorize_check_query = "select * from cake.auth_check('%{SQL-User-Name}')"


        # после успешной авторизации выполняется этот запрос который возвращает reply аттрибуты для пользователя.
        # Они могут содержать лимиты для пользователя и сопутствующую информацию.
        authorize_reply_query = "select * from cake.auth_reply('%{SQL-User-Name}')"

        # запрос ведет запись alive пакетов сессии содержащих промежуточные значения использования ресурсов.
        accounting_update_query = "select cake.acct_update('%{Acct-Unique-Session-Id}', %{Acct-Output-Octets},%{Acct-Input-Octets})"

        # запрос ведет запись пакета начала сессии.
        accounting_start_query = "select start_session('%{Acct-Unique-Session-Id}','%{SQL-User-Name}')"

         # запрос ведет запись пакета конца сессии.
        accounting_stop_query = "select stop_session(%{Acct-Input-Octets},%{Acct-Output-Octets},'%{Acct-Unique-Session-Id}')"

}

```

Снова запускаем **check-radiusd-config**. Если мы получили ответ:

```
Radius server configuration looks OK.
```

Проверяем работоспособность **RADIUS** сервера, вы должны увидеть нечто подобное:

```
radiusd -X

....
rlm_sql (cake_sql): Driver rlm_sql_postgresql (module rlm_sql_postgresql) loaded and linked
rlm_sql (cake_sql): Attempting to connect to postgres@127.0.0.1:/cake
rlm_sql (cake_sql): starting 0
rlm_sql (cake_sql): Attempting to connect rlm_sql_postgresql #0
rlm_sql (cake_sql): Connected new DB handle, #0
rlm_sql (cake_sql): starting 1
....
```

Если вы это не увидели проверьте доступность СУБД и т.п.

Далее уберите в **radiusd.conf** опцию **auth\_log** в секции **authorize**, опцию **detail** в секции **accounting** и
опцию **reply\_log** в секции **post-auth** они не требуются в рабочем состоянии сервера. Поскольку будут только ухудшать призводительность сервера.

Запустите **FreeRADIUS** в рабочем режиме.

Для Gentoo Linux:

```
root@cake# cd /etc/init.d/
root@cake# ./radiusd start
```

Добавляем в автозагрузку:
```
root@cake# rc-update add radiusd default
```

Для других платформ:

При установке в **/opt/freeradius/sbin** помещается скрипт **rc.radiusd**.
Запускаем в рабочем режиме:
```
root@cake# cd /opt/freeradiusd/sbin
root@cake# ./rc.radiusd
```

Не забудьте поместить в автозагрузку этот скрипт.

[[InstallFreeRadiusToc <<](.md) ] [[InstallFreeRadiusInGentoo <](.md) ] [[CakeToc В начало](.md) ] [[InstallPppdPptpdToc >](.md) ] [[InstallPppdPptpdToc >>](.md) ]