### Версия 1.0.1 ###
#### Схема данных ####
  * таблица **users**
    * Изменено поле **name**, добавлен **NOT NULL**.
    * Изменено поле **ip\_addr**, убран **DEFAULT 0**;
  * Процедура **check\_iddle** переименована в **check\_idle**.
  * Процедуры **str2sid**, **str2uid** переписаны на SQL.
  * Добавлены процедуры
    * **clear\_keepalive** - удаление устаревшей статистики ,
    * **start\_session** - отвечает за установку метки о начале сессии,
    * **stop\_session** - отвечает за установку метки о конце сессии.
  * Исправлена процедура **get\_new\_ip**, теперь учитывает левую границу пула.
  * Исправлены процедуры **u\_mwb\_report**, **u\_mwb\_report\_all**, **u\_mwb\_report\_user**, теперь работают так же с нулевыми тарифами.
  * Изменена имя переменной **iddle\_timeout** на **idle\_timeout**.
  * Добавлена переменная **clear\_keepalive** указывает на время хранения статистики в **keepalive** таблице.
  * Произведена оптимизация и чистка кода процедур.
  * Добавлена поддержка **PostreSQL 8.x**
  * При нулевом тарифе отчеты в балансе пользователя показывают количество потребленнных мегабайт.
  * Добавлен вызов процедуры **acct\_update** из **stop\_session** для коррекции данных подробной статистики.
#### Веб-интерфейс ####
  * Оптимизирована работа с БД (теперь открывается одно соединение на весь сеанс работы пользователя)
  * Добавлена возможность конфигурации соединения с БД посредством файла WEB-INF/cake.xml
#### FreeRADIUS ####
  * Изменен **cakesql.conf**, старые запросы помечены коментариями :
```
#accounting_start_query = "insert into cake.session (sid, id_user) \
#values ('%{Acct-Unique-Session-Id}', cake.str2uid('%{SQL-User-Name}'))"
accounting_start_query = "select cake.start_session('%{Acct-Unique-Session-Id}','%{SQL-User-Name}')"

#accounting_stop_query = "update cake.session set svolumeout=%{Acct-Input-Octets}, svolume=%{Acct-Output-Octets}, \
#s_end=current_timestamp where id=cake.str2sid('%{Acct-Unique-Session-Id}')"
accounting_stop_query = "select cake.stop_session(%{Acct-Input-Octets},%{Acct-Output-Octets},'%{Acct-Unique-Session-Id}')"

```