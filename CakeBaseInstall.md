[[annonce <<](.md) ] [[annonce <](.md) ] [[CakeToc В начало](.md) ] [[CakeIntro >](.md) ] [[InstallPostgresToc >>](.md) ]

#### Необходимые компоненты ####
  * Машина с `*`nix
  * [FreeRADIUS](http://freeradius.org/) _версия 0.9.3 и выше_
  * [Pptpd](http://www.poptop.org) _версия 1.1.3 и выше_
  * [PPP](http://ppp.samba.org/) _версия 2.4.2.b3 и выше_
  * [PostgreSQL](http://www.postgresql.org/) _версия 7.4.x (для 8.x используйте версию 1.0.1rc)_
  * JDK 1.3 и выше. [Sun JDK](http://java.sun.com/javase/downloads/index.jsp) [Blackdown JDK](http://www.blackdown.org/java-linux/java-linux-d2.html) [BEA Jrockit JDK](http://commerce.bea.com/products/weblogicjrockit/jrockit_prod_fam.jsp)
  * Servlet/JSP контейнер ( http://caucho.com/ или http://jakarta.apache.org/tomcat/ )
  * [PostgreSQL JDBC Driver](http://jdbc.postgresql.org/download.html) _используется версия 3x_
  * Желание установить

#### Как и где ставить ####

  * Теоретически возможна инсталляция не только Linux, но и любой `*`nix, где соберётся вышеуказанный софт.
  * Сборка производилась на **Gentoo Linux**. Был выбран из-за простоты инсталляции вышеперечисленного софта. Какая ситуация с пакетными дистрибутивами -- не знаю.
  * Вообще то ничего сложного.

#### Предупреждение ####
  * Если есть возможность ставьте из родных пакетов. Особенно это касается **rpm-based** дистрибутивов. В них сборка из исходников сложна.
  * Применять сборку из исходников рекомендуется на **source-based** дистрибутивах, а также в **slackware** и **debian**. В них не должно возникать проблем.

##### Примечание #####

  * Для jdk менее 1.4.x необходим [JAXP](http://www.jcp.org/en/jsr/detail?id=206), в jdk 1.4.x и выше JAXP включен по умолчанию.

[[annonce <<](.md) ] [[annonce <](.md) ] [[CakeToc В начало](.md) ] [[CakeIntro >](.md) ] [[InstallPostgresToc >>](.md) ]