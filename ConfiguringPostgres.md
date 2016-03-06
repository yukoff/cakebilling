[[InstallPostgresToc <<](.md) ] [[InstallPostgresInGentoo <](.md) ] [[CakeToc В начало](.md) ] [[InstallFreeRadiusToc >](.md) ] [[InstallFreeRadiusToc >>](.md) ]

Переключаемся на пользователя **postgres**:
```
root@cake# su postgres
```

Добавляем нового пользователя **cake** в PostgreSQL:
```
postgres@cake$ createuser -P -D -A cake
```

**Note:**
По умолчанию в веб-интерфейсе для доступа в базу используется **login: cake, password: cake**.
Незабудьте изменить настройки web-интерфейса в случае выбора другого логина и пароля.

Создаём базу данных (Обязательно в горячо любимой всеми нами кодировке **WIN1251**):
```
postgres@cake$ createdb -O cake -E WIN cake
```

Добавляем язык хранимых процедур **plpgsql**:
```
postgres@cake$ createlang plpgsql cake 
```

Загружаем и экспортируем схему базы и начальные данные:
```
postgres@cake$ wget http://cakebilling.googlecode.com/files/cake.sql
postgres@cake$ psql -Ucake -W -d cake -f cake.sql 
```

Проверяем права:
```
psql -Ucake cake -c "select * from cake.users;"
```

| id | login | name | pwd | balance | userblock | overtraffblock  | ip\_addr | id\_tariff | grp |
|:---|:------|:-----|:----|:--------|:----------|:----------------|:---------|:-----------|:----|
| 104 | admin | Admin | 1234 | 0.00    | f         | t               | 2        | 1          | 1   |


Закрываем сессию пользователя **postgres**:
```
postgres@cake$ exit
```

[[InstallPostgresToc <<](.md) ] [[InstallPostgresInGentoo <](.md) ] [[CakeToc В начало](.md) ] [[InstallFreeRadiusToc >](.md) ] [[InstallFreeRadiusToc >>](.md) ]