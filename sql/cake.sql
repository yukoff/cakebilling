--
-- PostgreSQL database dump
--

SET client_encoding = 'WIN';
SET check_function_bodies = false;

--
-- TOC entry 3 (OID 62188)
-- Name: cake; Type: SCHEMA; Schema: -; Owner: 
--

CREATE SCHEMA cake AUTHORIZATION cake;

--
-- TOC entry 8 (OID 62193)
-- Name: users; Type: TABLE; Schema: cake; Owner: postgres
--

CREATE TABLE users (
    id serial NOT NULL,
    login character varying(20) NOT NULL,
    name character varying(50),
    pwd character varying(20) DEFAULT 1,
    balance numeric(9,2) DEFAULT 0 NOT NULL,
    userblock boolean DEFAULT false NOT NULL,
    overtraffblock boolean DEFAULT true NOT NULL,
    ip_addr integer DEFAULT 0,
    id_tariff bigint DEFAULT 1,
    grp bigint DEFAULT 0,
    CONSTRAINT users_login_not_empty CHECK (((login)::text <> ''::text)),
    CONSTRAINT users_name_not_empty CHECK (((name)::text <> ''::text))
) WITHOUT OIDS;


--
-- TOC entry 9 (OID 62207)
-- Name: pay; Type: TABLE; Schema: cake; Owner: postgres
--

CREATE TABLE pay (
    id serial NOT NULL,
    id_user integer NOT NULL,
    paydate timestamp without time zone DEFAULT ('now'::text)::timestamp(6) with time zone NOT NULL,
    volume numeric(9,2) DEFAULT 0 NOT NULL,
    id_error_pay bigint
) WITHOUT OIDS;


--
-- TOC entry 10 (OID 62214)
-- Name: session; Type: TABLE; Schema: cake; Owner: postgres
--

CREATE TABLE "session" (
    id serial NOT NULL,
    id_user integer NOT NULL,
    sid character varying(16) NOT NULL,
    s_begin timestamp without time zone DEFAULT ('now'::text)::timestamp(6) with time zone NOT NULL,
    s_end timestamp without time zone,
    svolume bigint DEFAULT 0 NOT NULL,
    svolumeout bigint DEFAULT 0 NOT NULL,
    s_last_update timestamp without time zone DEFAULT ('now'::text)::timestamp(6) with time zone
) WITHOUT OIDS;


--
-- TOC entry 11 (OID 62223)
-- Name: keepalive; Type: TABLE; Schema: cake; Owner: postgres
--

CREATE TABLE keepalive (
    id serial NOT NULL,
    id_session integer NOT NULL,
    kdatetime timestamp without time zone DEFAULT ('now'::text)::timestamp(6) with time zone NOT NULL,
    volumein bigint DEFAULT 0 NOT NULL,
    volumeout bigint DEFAULT 0 NOT NULL,
    diff_in bigint DEFAULT 0,
    diff_out bigint DEFAULT 0
) WITHOUT OIDS;


--
-- TOC entry 13 (OID 62233)
-- Name: tariff; Type: TABLE; Schema: cake; Owner: postgres
--

CREATE TABLE tariff (
    id serial NOT NULL,
    name character varying(50) DEFAULT 'Новый тариф'::character varying NOT NULL,
    price_per_mb numeric(9,2) DEFAULT 0 NOT NULL,
    ordr integer DEFAULT 0,
    speed bigint DEFAULT 0
) WITHOUT OIDS;


--
-- TOC entry 6 (OID 62241)
-- Name: auth_reply; Type: TYPE; Schema: cake; Owner: postgres
--

CREATE TYPE auth_reply AS (
	id integer,
	username character varying,
	attribute character varying,
	value character varying,
	op character varying
);


--
-- TOC entry 36 (OID 62242)
-- Name: auth_check(character varying); Type: FUNCTION; Schema: cake; Owner: postgres
--

CREATE FUNCTION auth_check(character varying) RETURNS SETOF auth_reply
    AS '
declare

runame  alias for $1;
r cake.auth_reply;
cuser cake.users;
uid integer;
sid integer;
empt integer;
uname text;
uattr text;
uvalue text;
uop text;

begin
-- проверка висящих сессий
empt = cake.check_iddle_sessions();

select into cuser * from cake.users where runame=cake.users.login;

select distinct cake.session.id into sid
from cake.session, cake.users
where cake.session.id_user=cake.users.id
and cake.session.s_end is null
and cake.users.login=runame
limit 1;

-- если пользователь есть, то возвращаем пароль
if (cuser.login is not null and sid is null) and
   not ((cuser.balance<=0) and (cuser.overtraffblock))
  then
    r.id=cuser.id;
    r.username=cuser.login;
    r.attribute=''User-Password'';
    r.value=cuser.pwd;
    r.op='':='';
    return next r;
  end if;
return;
end
'
    LANGUAGE plpgsql;


--
-- TOC entry 38 (OID 62243)
-- Name: auth_reply(character varying); Type: FUNCTION; Schema: cake; Owner: postgres
--

CREATE FUNCTION auth_reply(character varying) RETURNS SETOF auth_reply
    AS '
declare r cake.auth_reply;
runame  alias for $1;
declare cuser cake.users;

declare traffout integer
 = to_number(cake.getParameter(''max_traffout'') ,''99999999999999999999'')::int;

declare timeout integer
 = to_number(cake.getParameter(''max_timeout'')  ,''99999999999999999999'')::int;

declare iddle_timeout integer
 = to_number(cake.getParameter(''iddle_timeout''),''99999999999999999999'')::int;

declare mb_price numeric;    --  цена за мегабайт

-- берём системные параметры
declare ipsubnet varchar = cake.getparameter(''ipsubnet'');
declare ipnetmask varchar = cake.getparameter(''ipnetmask'');
declare traffinterval varchar = cake.getparameter(''traffinterval'');

begin

-- текущий пользователь
select into cuser * from cake.users where runame=cake.users.login;

-- цена за мегабайт по тарифу текущего пользователя
select into mb_price price_per_mb from cake.tariff where id=cuser.id_tariff;

-- если цена не 0 и лимит пользователя меньше максимума,
-- то считаем лимит траффика, иначе остается максимум
if (mb_price<>0) and (traffout>=round((cuser.balance*1048576)/mb_price)) then
     traffout=round((cuser.balance*1048576)/mb_price);
end if;

-- если отрицательный баланс и включена блокировка, откидываем соединение
if (traffout<=0) or (cuser.userblock) then traffout = 1; end if;


-- выставляем и возвращаем reply атрибуты

if cuser.login is not null then
    r.id=cuser.id;
    r.username=cuser.login;
    r.op='':='';

    r.attribute=''Framed-IP-Address'';  
    r.value=ipsubnet||''.''||cuser.ip_addr;
    return next r;

    r.attribute=''Framed-IP-Netmask'';
    r.value=ipnetmask;
    return next r;

    r.attribute=''Session-Timeout'';
    r.value=timeout;
    return next r;

    r.attribute=''Idle-Timeout'';
    r.value=iddle_timeout;
    return next r;

    if cuser.overtraffblock or cuser.userblock then
        r.attribute=''Session-Octets-Limit'';
        r.value=traffout;
        return next r;
    end if;

    r.attribute=''Acct-Interim-Interval'';
    r.value=traffinterval;
    return next r;

    r.attribute=''Octets-Direction'';
    r.value=''2'';
    return next r;


  end if;
return;
end
'
    LANGUAGE plpgsql;


--
-- TOC entry 39 (OID 62244)
-- Name: str2sid(text); Type: FUNCTION; Schema: cake; Owner: postgres
--

CREATE FUNCTION str2sid(text) RETURNS integer
    AS '
declare
strsid alias for $1;
s_id integer;
begin
select into s_id id from cake.session where cake.session.sid=strsid;
return s_id;
end
'
    LANGUAGE plpgsql;


--
-- TOC entry 40 (OID 62245)
-- Name: str2uid(text); Type: FUNCTION; Schema: cake; Owner: postgres
--

CREATE FUNCTION str2uid(text) RETURNS integer
    AS '
declare
uname alias for $1;
u_id integer;
begin
select into u_id id from cake.users where login=uname;
return u_id;
end
'
    LANGUAGE plpgsql;


--
-- TOC entry 41 (OID 62246)
-- Name: dec_user_balanse(); Type: FUNCTION; Schema: cake; Owner: postgres
--

CREATE FUNCTION dec_user_balanse() RETURNS "trigger"
    AS '
declare
oldbalanse numeric;
uid integer;
mb_price numeric;
begin

-- узнаём id и баланс пользователя
select into uid, oldbalanse id, balance from cake.users where old.id_user=cake.users.id;

-- узнаём тариф текущего пользователя
select into mb_price price_per_mb from cake.users, cake.tariff
       where cake.users.id_tariff=tariff.id
       and cake.users.id=old.id_user;

-- если тариф >0, то обновляем баланс
if (mb_price>0) then
  update cake.users set balance=oldbalanse-((new.svolume-old.svolume)*mb_price)/1048576
       where cake.users.id=old.id_user;
end if;

return null;
end
'
    LANGUAGE plpgsql IMMUTABLE;


--
-- TOC entry 42 (OID 62247)
-- Name: getparameter(character varying); Type: FUNCTION; Schema: cake; Owner: postgres
--

CREATE FUNCTION getparameter(character varying) RETURNS character varying
    AS '
declare
pname alias for $1;
pvalue varchar;
begin
select into pvalue value from cake.parameters where pname=name;
return pvalue;
end
'
    LANGUAGE plpgsql;


--
-- TOC entry 14 (OID 62248)
-- Name: parameters; Type: TABLE; Schema: cake; Owner: postgres
--

CREATE TABLE parameters (
    name character varying NOT NULL,
    value character varying NOT NULL,
    "comment" character varying(100) DEFAULT ''::character varying
);


--
-- TOC entry 43 (OID 62254)
-- Name: inc_balance(); Type: FUNCTION; Schema: cake; Owner: postgres
--

CREATE FUNCTION inc_balance() RETURNS "trigger"
    AS '
declare
cuser cake.users;
begin
  select into cuser * from cake.users where new.id_user = cake.users.id;
  update cake.users set balance=cuser.balance+new.volume
         where cake.users.id=new.id_user;
  return null;
end;
'
    LANGUAGE plpgsql IMMUTABLE;


--
-- TOC entry 44 (OID 62255)
-- Name: update_balance(integer, numeric); Type: FUNCTION; Schema: cake; Owner: postgres
--

CREATE FUNCTION update_balance(integer, numeric) RETURNS integer
    AS '
declare cuser cake.users;
uid alias for $1;
bal alias for $2;
begin
select into cuser * from cake.users where id=uid;
if cuser.id is not null and  round((bal - cuser.balance)*100)<>0 then
  insert into cake.pay (id_user, volume) values (uid, (bal - cuser.balance));
end if;
return round(bal - cuser.balance);
end;
'
    LANGUAGE plpgsql;


--
-- TOC entry 45 (OID 62256)
-- Name: acct_update(character varying, bigint, bigint); Type: FUNCTION; Schema: cake; Owner: postgres
--

CREATE FUNCTION acct_update(character varying, bigint, bigint) RETURNS integer
    AS '
declare
aSID alias for $1;
vin alias for $2;
vout alias for $3;
ck cake.keepalive;
d_in bigint = 0;
d_out bigint = 0;
begin

-- выбираем последний присланный кипалив текущей сессии
select * into ck
  from cake.keepalive
  where id_session=cake.str2sid(aSID)
  order by kdatetime desc
  limit 1;
  
if ck.id is not null then
  d_in = vout - ck.volumein;
  d_out = vin - ck.volumeout;
else
  d_in = vout;
  d_out = vin;
end if;

-- вставляем запись о моментальном расходе траффика
insert into cake.keepalive
       ( id_session,          volumeout,  volumein,  diff_in,  diff_out )
values ( cake.str2sid(aSID),  vin,        vout,      d_in,     d_out    );

-- обновляем показания траффика в сессии
update cake.session set svolume=vin, svolumeout=vout,
                        s_last_update=current_timestamp
                        where sid=aSID;

-- чё нить надо вернуть..
return 1;
end;
'
    LANGUAGE plpgsql;


--
-- TOC entry 7 (OID 62258)
-- Name: mwb_report; Type: TYPE; Schema: cake; Owner: postgres
--

CREATE TYPE mwb_report AS (
	uname character varying,
	ulogin character varying,
	bal_cur numeric,
	bal_mb numeric,
	traf_week numeric,
	cur_week numeric,
	traf_month numeric,
	cur_month numeric,
	userblock boolean,
	overtraffblock boolean
);


--
-- TOC entry 47 (OID 62259)
-- Name: u_mwb_report(boolean); Type: FUNCTION; Schema: cake; Owner: postgres
--

CREATE FUNCTION u_mwb_report(boolean) RETURNS SETOF mwb_report
    AS '
declare
all alias for $1;
cuser cake.users;
cumwb cake.mwb_report;
mb_price numeric;
begin
for cuser in select * from cake.users loop
  select into mb_price price_per_mb
    from cake.users, cake.tariff
    where cake.users.id=cuser.id and
    cake.users.id_tariff=cake.tariff.id;

  if (mb_price<=0) then
    mb_price=(cuser.balance*1048576) /
    to_number(cake.getParameter(''max_traffout'') ,''99999999999999999999'')::int;
  end if;

  cumwb.ulogin=cuser.login;
  cumwb.uname=cuser.name;
  cumwb.userblock=cuser.userblock;
  cumwb.overtraffblock=cuser.overtraffblock;
  cumwb.bal_cur=cuser.balance;
  cumwb.bal_mb=cumwb.bal_cur/mb_price;


  select sum(volume) into cumwb.cur_week
  from cake.pay where
    id_user=cuser.id and
    paydate > date_trunc(''month'', current_timestamp);
  if cumwb.cur_week is null then cumwb.cur_week=0; end if;
  cumwb.traf_week=cumwb.cur_week/mb_price;

  select sum(svolume)/1048576 into cumwb.traf_month
  from cake.users, cake.session
  where
    cake.users.id=cake.session.id_user and
    cake.users.id=cuser.id and
    cake.session.s_begin >= date_trunc(''month'', current_timestamp);
  if cumwb.traf_month is null then cumwb.traf_month=0; end if;
  cumwb.cur_month=(cumwb.traf_month*mb_price);


  return next cumwb;
end loop;
return cumwb;
end;
'
    LANGUAGE plpgsql;


--
-- TOC entry 48 (OID 62260)
-- Name: u_mwb_report_all(boolean); Type: FUNCTION; Schema: cake; Owner: postgres
--

CREATE FUNCTION u_mwb_report_all(boolean) RETURNS SETOF mwb_report
    AS '
declare
all alias for $1;
cuser cake.users;
cumwb cake.mwb_report;
cumwb_result cake.mwb_report;
mb_price numeric;
begin

cumwb_result.bal_cur=0;
cumwb_result.bal_mb=0;
cumwb_result.traf_week=0;
cumwb_result.cur_week=0;
cumwb_result.traf_month=0;
cumwb_result.cur_month=0;

for cuser in select * from cake.users loop
  select into mb_price price_per_mb
    from cake.users, cake.tariff
    where cake.users.id=cuser.id and
    cake.users.id_tariff=cake.tariff.id;
    
  if (mb_price<=0) then
    mb_price=(cuser.balance*1048576) /
    to_number(cake.getParameter(''max_traffout'') ,''99999999999999999999'')::int;
  end if;

  cumwb.ulogin=cuser.login;
  cumwb.bal_cur=cuser.balance;
  cumwb.bal_mb=cumwb.bal_cur/mb_price;

  cumwb_result.bal_cur=cumwb_result.bal_cur+cumwb.bal_cur;
  cumwb_result.bal_mb=cumwb_result.bal_mb+cumwb.bal_mb;

  select sum(volume) into cumwb.cur_week
  from cake.pay where
    id_user=cuser.id and
    paydate > date_trunc(''month'', current_timestamp);
  if cumwb.cur_week is null then cumwb.cur_week=0; end if;
  cumwb.traf_week=cumwb.cur_week/mb_price;

  cumwb_result.traf_week=cumwb_result.traf_week+cumwb.traf_week;
  cumwb_result.cur_week=cumwb_result.cur_week+cumwb.cur_week;

  select sum(svolume)/1048576 into cumwb.traf_month
  from cake.users, cake.session
  where
    cake.users.id=cake.session.id_user and
    cake.users.id=cuser.id and
    cake.session.s_begin >= date_trunc(''month'', current_timestamp);
  if cumwb.traf_month is null then cumwb.traf_month=0; end if;
  cumwb.cur_month=(cumwb.traf_month*mb_price);

  cumwb_result.traf_month=cumwb_result.traf_month+cumwb.traf_month;
  cumwb_result.cur_month=cumwb_result.cur_month+cumwb.cur_month;

end loop;

return next cumwb_result;
return cumwb_result;
end;
'
    LANGUAGE plpgsql;


--
-- TOC entry 49 (OID 62261)
-- Name: get_new_ip(); Type: FUNCTION; Schema: cake; Owner: postgres
--

CREATE FUNCTION get_new_ip() RETURNS integer
    AS '
declare ip integer;
declare max_use_ip integer;
declare max_pool_ip integer;
declare min_pool_ip integer;
declare new_ip integer;
declare i integer;
declare null_ip integer;

begin
  new_ip=0;
  select max(ip_addr) into max_use_ip from cake.users;
  min_pool_ip = to_number(cake.getParameter(''min_pool_ip''),''999'')::int;
  max_pool_ip = to_number(cake.getParameter(''max_pool_ip''),''999'')::int;

  if max_use_ip+1 > max_pool_ip then
    for i in min_pool_ip..max_pool_ip loop
      select into null_ip ip_addr from cake.users where ip_addr=i;
      if null_ip is null then new_ip=i; end if;
    end loop;
  else
  new_ip=max_use_ip+1;
  end if;

  return new_ip;
end;
'
    LANGUAGE plpgsql;


--
-- TOC entry 50 (OID 62262)
-- Name: u_mwb_report_user(character varying, character varying); Type: FUNCTION; Schema: cake; Owner: postgres
--

CREATE FUNCTION u_mwb_report_user(character varying, character varying) RETURNS SETOF mwb_report
    AS '
declare
cuser cake.users;
cumwb cake.mwb_report;
mb_price numeric;
begin
for cuser in select * from cake.users where login=$1 and pwd=$2 loop
  select into mb_price price_per_mb
    from cake.users, cake.tariff
    where cake.users.id=cuser.id and
    cake.users.id_tariff=cake.tariff.id;

  if (mb_price<=0) then
    mb_price=(cuser.balance*1048576) /
    to_number(cake.getParameter(''max_traffout'') ,''99999999999999999999'')::int;
  end if;

  cumwb.ulogin=cuser.login;
  cumwb.uname=cuser.name;
  cumwb.userblock=cuser.userblock;
  cumwb.overtraffblock=cuser.overtraffblock;
  cumwb.bal_cur=cuser.balance;
  cumwb.bal_mb=cumwb.bal_cur/mb_price;


  select sum(volume) into cumwb.cur_week
  from cake.pay where
    id_user=cuser.id and
    paydate > date_trunc(''month'', current_timestamp);
  if cumwb.cur_week is null then cumwb.cur_week=0; end if;
  cumwb.traf_week=cumwb.cur_week/mb_price;

  select sum(svolume)/1048576 into cumwb.traf_month
  from cake.users, cake.session
  where
    cake.users.id=cake.session.id_user and
    cake.users.id=cuser.id and
    cake.session.s_begin >= date_trunc(''month'', current_timestamp);
  if cumwb.traf_month is null then cumwb.traf_month=0; end if;
  cumwb.cur_month=(cumwb.traf_month*mb_price);


  return next cumwb;
end loop;
return cumwb;
end;
'
    LANGUAGE plpgsql;


--
-- TOC entry 51 (OID 62263)
-- Name: set_ip_for_newuser_f(); Type: FUNCTION; Schema: cake; Owner: postgres
--

CREATE FUNCTION set_ip_for_newuser_f() RETURNS "trigger"
    AS '
declare newip integer;
begin
  update cake.users set ip_addr = cake.get_new_ip() where id=new.id;
  return null;
end;
'
    LANGUAGE plpgsql IMMUTABLE;


--
-- TOC entry 52 (OID 62264)
-- Name: check_iddle_sessions(); Type: FUNCTION; Schema: cake; Owner: postgres
--

CREATE FUNCTION check_iddle_sessions() RETURNS integer
    AS '
declare
ctsmp timestamp = current_timestamp;
declare traffinterval integer
 = to_number(cake.getParameter(''traffinterval'') ,''99999999999999999999'')::int;
itvr interval;
restime timestamp;
begin
itvr = (traffinterval*2)||'' sec'';
restime = current_timestamp - itvr;
update cake.session set s_end = s_last_update where
       (s_end is null)and(s_last_update<restime);
return 1;
end;
'
    LANGUAGE plpgsql;


--
-- Data for TOC entry 53 (OID 62193)
-- Name: users; Type: TABLE DATA; Schema: cake; Owner: postgres
--

COPY users (id, login, name, pwd, balance, userblock, overtraffblock, ip_addr, id_tariff, grp) FROM stdin;
104	admin	Admin	1234	0.00	f	t	1	1	1
\.


--
-- Data for TOC entry 54 (OID 62207)
-- Name: pay; Type: TABLE DATA; Schema: cake; Owner: postgres
--

COPY pay (id, id_user, paydate, volume, id_error_pay) FROM stdin;
\.


--
-- Data for TOC entry 55 (OID 62214)
-- Name: session; Type: TABLE DATA; Schema: cake; Owner: postgres
--

COPY "session" (id, id_user, sid, s_begin, s_end, svolume, svolumeout, s_last_update) FROM stdin;
\.


--
-- Data for TOC entry 56 (OID 62223)
-- Name: keepalive; Type: TABLE DATA; Schema: cake; Owner: postgres
--

COPY keepalive (id, id_session, kdatetime, volumein, volumeout, diff_in, diff_out) FROM stdin;
\.


--
-- Data for TOC entry 57 (OID 62233)
-- Name: tariff; Type: TABLE DATA; Schema: cake; Owner: postgres
--

COPY tariff (id, name, price_per_mb, ordr, speed) FROM stdin;
1	Основной	2.20	0	\N
\.


--
-- Data for TOC entry 58 (OID 62248)
-- Name: parameters; Type: TABLE DATA; Schema: cake; Owner: postgres
--

COPY parameters (name, value, "comment") FROM stdin;
traffinterval	60	Период обновления данных о расходе траффика (в секундах)
ipnetmask	255.255.255.0	Маска виртуальной подсети
max_traffout	1073741824	Максимальный траффик сессии (в байтах)
min_pool_ip	20	Минимальный ip адрес клиента
max_pool_ip	200	Максимальный ip адрес клиента
iddle_timeout	7200	«Сонный&raquo; таймаут (в секундах)
ipsubnet	192.168.2	Виртуальная подсеть (в формате &laquo;x.x.x&raquo;)
max_timeout	43200	Максимальное время сессии (в секундах)
\.


--
-- TOC entry 27 (OID 62273)
-- Name: indx_sid; Type: INDEX; Schema: cake; Owner: postgres
--

CREATE UNIQUE INDEX indx_sid ON "session" USING btree (sid);


--
-- TOC entry 25 (OID 62274)
-- Name: idx_session_begin; Type: INDEX; Schema: cake; Owner: postgres
--

CREATE INDEX idx_session_begin ON "session" USING btree (s_begin);


--
-- TOC entry 26 (OID 62275)
-- Name: idx_session_end; Type: INDEX; Schema: cake; Owner: postgres
--

CREATE INDEX idx_session_end ON "session" USING btree (s_end);


--
-- TOC entry 29 (OID 62276)
-- Name: idx_keepalive_datetime; Type: INDEX; Schema: cake; Owner: postgres
--

CREATE INDEX idx_keepalive_datetime ON keepalive USING btree (kdatetime);


--
-- TOC entry 20 (OID 62277)
-- Name: index_login; Type: INDEX; Schema: cake; Owner: postgres
--

CREATE INDEX index_login ON users USING hash (login);


--
-- TOC entry 21 (OID 62278)
-- Name: pk_users; Type: CONSTRAINT; Schema: cake; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT pk_users PRIMARY KEY (id);


--
-- TOC entry 24 (OID 62280)
-- Name: pk_pay; Type: CONSTRAINT; Schema: cake; Owner: postgres
--

ALTER TABLE ONLY pay
    ADD CONSTRAINT pk_pay PRIMARY KEY (id);


--
-- TOC entry 28 (OID 62282)
-- Name: pk_session; Type: CONSTRAINT; Schema: cake; Owner: postgres
--

ALTER TABLE ONLY "session"
    ADD CONSTRAINT pk_session PRIMARY KEY (id);


--
-- TOC entry 30 (OID 62284)
-- Name: pk_keepalive; Type: CONSTRAINT; Schema: cake; Owner: postgres
--

ALTER TABLE ONLY keepalive
    ADD CONSTRAINT pk_keepalive PRIMARY KEY (id);


--
-- TOC entry 31 (OID 62286)
-- Name: pk_tariff; Type: CONSTRAINT; Schema: cake; Owner: postgres
--

ALTER TABLE ONLY tariff
    ADD CONSTRAINT pk_tariff PRIMARY KEY (id);


--
-- TOC entry 22 (OID 62288)
-- Name: unilogin; Type: CONSTRAINT; Schema: cake; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT unilogin UNIQUE (login);


--
-- TOC entry 33 (OID 62290)
-- Name: parameters_pkey; Type: CONSTRAINT; Schema: cake; Owner: postgres
--

ALTER TABLE ONLY parameters
    ADD CONSTRAINT parameters_pkey PRIMARY KEY (name);


--
-- TOC entry 23 (OID 62292)
-- Name: users_ip_addr_key; Type: CONSTRAINT; Schema: cake; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_ip_addr_key UNIQUE (ip_addr);


--
-- TOC entry 32 (OID 62294)
-- Name: tariff_name_key; Type: CONSTRAINT; Schema: cake; Owner: postgres
--

ALTER TABLE ONLY tariff
    ADD CONSTRAINT tariff_name_key UNIQUE (name);


--
-- TOC entry 60 (OID 62296)
-- Name: fk_pay_users; Type: FK CONSTRAINT; Schema: cake; Owner: postgres
--

ALTER TABLE ONLY pay
    ADD CONSTRAINT fk_pay_users FOREIGN KEY (id_user) REFERENCES users(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 62 (OID 62300)
-- Name: fk_session_user; Type: FK CONSTRAINT; Schema: cake; Owner: postgres
--

ALTER TABLE ONLY "session"
    ADD CONSTRAINT fk_session_user FOREIGN KEY (id_user) REFERENCES users(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 63 (OID 62304)
-- Name: fk_keepalive_session; Type: FK CONSTRAINT; Schema: cake; Owner: postgres
--

ALTER TABLE ONLY keepalive
    ADD CONSTRAINT fk_keepalive_session FOREIGN KEY (id_session) REFERENCES "session"(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 61 (OID 62308)
-- Name: $1; Type: FK CONSTRAINT; Schema: cake; Owner: postgres
--

ALTER TABLE ONLY pay
    ADD CONSTRAINT "$1" FOREIGN KEY (id_error_pay) REFERENCES pay(id) ON DELETE CASCADE;


--
-- TOC entry 59 (OID 62312)
-- Name: fk_users_tariff; Type: FK CONSTRAINT; Schema: cake; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk_users_tariff FOREIGN KEY (id_tariff) REFERENCES tariff(id) ON UPDATE CASCADE;


--
-- TOC entry 65 (OID 62316)
-- Name: inc_balance_on_ins_pay; Type: TRIGGER; Schema: cake; Owner: postgres
--

CREATE TRIGGER inc_balance_on_ins_pay
    AFTER INSERT ON pay
    FOR EACH ROW
    EXECUTE PROCEDURE inc_balance();


--
-- TOC entry 64 (OID 62317)
-- Name: set_ip_for_newuser; Type: TRIGGER; Schema: cake; Owner: postgres
--

CREATE TRIGGER set_ip_for_newuser
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE PROCEDURE set_ip_for_newuser_f();


--
-- TOC entry 66 (OID 62318)
-- Name: dec_user_balanse_trigger; Type: TRIGGER; Schema: cake; Owner: postgres
--

CREATE TRIGGER dec_user_balanse_trigger
    AFTER UPDATE ON "session"
    FOR EACH ROW
    EXECUTE PROCEDURE dec_user_balanse();


--
-- TOC entry 15 (OID 62191)
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: cake; Owner: postgres
--

SELECT pg_catalog.setval('users_id_seq', 104, true);


--
-- TOC entry 16 (OID 62205)
-- Name: pay_id_seq; Type: SEQUENCE SET; Schema: cake; Owner: postgres
--

SELECT pg_catalog.setval('pay_id_seq', 4582, true);


--
-- TOC entry 17 (OID 62212)
-- Name: session_id_seq; Type: SEQUENCE SET; Schema: cake; Owner: postgres
--

SELECT pg_catalog.setval('session_id_seq', 1948, true);


--
-- TOC entry 18 (OID 62221)
-- Name: keepalive_id_seq; Type: SEQUENCE SET; Schema: cake; Owner: postgres
--

SELECT pg_catalog.setval('keepalive_id_seq', 196423, true);


--
-- TOC entry 19 (OID 62231)
-- Name: tariff_id_seq; Type: SEQUENCE SET; Schema: cake; Owner: postgres
--

SELECT pg_catalog.setval('tariff_id_seq', 11, true);



--
-- TOC entry 12 (OID 62223)
-- Name: TABLE keepalive; Type: COMMENT; Schema: cake; Owner: postgres
--

COMMENT ON TABLE keepalive IS 'таблица алив-пакетов
потенциально в будущем будет использоваться для построения графиков интенсивности расхода';


--
-- TOC entry 37 (OID 62242)
-- Name: FUNCTION auth_check(character varying); Type: COMMENT; Schema: cake; Owner: postgres
--

COMMENT ON FUNCTION auth_check(character varying) IS 'запрос на авторизацию атрибуты
select * from cake.auth_check(''%{SQL-User-Name}'');';


--
-- TOC entry 46 (OID 62256)
-- Name: FUNCTION acct_update(character varying, bigint, bigint); Type: COMMENT; Schema: cake; Owner: postgres
--

COMMENT ON FUNCTION acct_update(character varying, bigint, bigint) IS 'запрос от радиус на keepalive
select cake.acct_update(''%{Acct-Unique-Session-Id}'', %{Acct-Output-Octets}, %{Acct-Input-Octets});';


