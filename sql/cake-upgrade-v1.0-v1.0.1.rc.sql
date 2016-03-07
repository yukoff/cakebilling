SET client_encoding = 'KOI8-R';

DROP FUNCTION cake.check_iddle_sessions();
DROP FUNCTION cake.auth_check(varchar);
DROP FUNCTION cake.auth_reply(varchar);
DROP FUNCTION cake.str2sid(text);
DROP FUNCTION cake.str2uid(text);
DROP FUNCTION cake.acct_update(varchar, bigint, bigint);
DROP FUNCTION cake.u_mwb_report(boolean);
DROP FUNCTION cake.u_mwb_report_all(boolean);
DROP FUNCTION cake.u_mwb_report_user(varchar,varchar);
DROP FUNCTION cake.getparameter(varchar);
DROP FUNCTION cake.get_new_ip();
DROP FUNCTION cake.update_balance(int, numeric);
DROP TRIGGER inc_balance_on_ins_pay ON cake.pay CASCADE;
DROP TRIGGER set_ip_for_newuser ON cake.users CASCADE;
DROP TRIGGER dec_user_balanse_trigger ON cake."session" CASCADE;
DROP FUNCTION cake.set_ip_for_newuser_f();
DROP FUNCTION cake.dec_user_balanse();
DROP FUNCTION cake.inc_balance();

-- проверка висящих сессий
-- хинт: добавить изменяемый параметр к интервалу поиска

CREATE FUNCTION cake.check_idle_sessions() RETURNS void
    AS '
DECLARE 

restime timestamp := now() - (((cake.getParameter(''traffinterval'')::int)*2)::varchar || '' sec'')::interval;

BEGIN
    UPDATE cake.session SET s_end = s_last_update 
	WHERE (s_end IS NULL) AND (s_last_update<restime);
    RETURN;
END
'
LANGUAGE plpgsql VOLATILE;

CREATE FUNCTION cake.auth_check(varchar) RETURNS SETOF cake.auth_reply
    AS '
DECLARE

runame ALIAS FOR $1;
sid integer;

r cake.auth_reply%ROWTYPE;
cuser cake.users%ROWTYPE;

BEGIN
    -- проверка висящих сессий
    PERFORM  cake.check_idle_sessions();
    
    SELECT INTO cuser * FROM cake.users where runame=cake.users.login;
    
    SELECT DISTINCT cake.session.id INTO sid FROM cake.session, cake.users
	WHERE (cake.session.id_user=cake.users.id) AND 
	(cake.session.s_end is null) AND
	(cake.users.login=runame) LIMIT 1;

    -- если пользователь есть то вазвращаем пароль 
    IF ((cuser.login IS NOT NULL) AND (sid IS NULL)) AND 
    NOT ((cuser.balance<=0) AND (cuser.overtraffblock)) THEN
	r.id := cuser.id;
	r.username := cuser.login;
	r.attribute := ''User-Password'';
	r.value := cuser.pwd;
	r.op := '':='';
	RETURN NEXT r;
    END IF;
    RETURN;
END
'
LANGUAGE plpgsql STABLE;

CREATE FUNCTION cake.auth_reply(varchar) RETURNS SETOF cake.auth_reply
    AS '
DECLARE

r cake.auth_reply%ROWTYPE;
runame ALIAS FOR $1;
cuser cake.users%ROWTYPE;

mb_price numeric(9,2);

traffout bigint := cake.getParameter(''max_traffout'')::int;

BEGIN
    -- текущий пользователь                                                                                                           
    SELECT INTO cuser * FROM cake.users WHERE runame=cake.users.login;

    -- цена за мегабайт по тарифу текущего пользователя
    SELECT INTO mb_price price_per_mb FROM cake.tariff WHERE id=cuser.id_tariff;

    -- если цена не 0 и лимит пользователя меньше максимума,
    -- то считаем лимит траффика, иначе остается максимум
    IF (mb_price<>0) AND (traffout>=round((cuser.balance*1048576)/mb_price)) THEN
	traffout := round((cuser.balance*1048576)/mb_price);
    END IF;

    -- если отрицательный баланс и включена блокировка, откидываем соединение 
    IF  (traffout<=0) OR (cuser.userblock) THEN 
	traffout := 1; 
    END IF;
    
    -- выставляем и возвращаем reply атрибуты
    IF (cuser.login IS NOT NULL) THEN
	r.id := cuser.id;
	r.username := cuser.login;
	r.op := '':='';
	r.attribute := ''Framed-IP-Address'';
	r.value := cake.getparameter(''ipsubnet'')||''.''||cuser.ip_addr;
	RETURN NEXT r;
	
	r.attribute := ''Framed-IP-Netmask'';
	r.value := cake.getparameter(''ipnetmask'');
	RETURN NEXT r;
	
	r.attribute := ''Session-Timeout'';
	r.value := cake.getParameter(''max_timeout'');
	RETURN NEXT r;
	
	r.attribute := ''Idle-Timeout'';
	r.value := cake.getparameter(''idle_timeout'');
	RETURN NEXT r;

	IF (cuser.overtraffblock) OR (cuser.userblock) THEN
	    r.attribute :=''Session-Octets-Limit'';
	    r.value := traffout::varchar;
	    RETURN NEXT r;
	END IF;

	r.attribute := ''Acct-Interim-Interval'';
	r.value := cake.getparameter(''traffinterval'');
	RETURN NEXT r;
	
	r.attribute=''Octets-Direction'';
	r.value=''2'';
	RETURN NEXT r;
    END IF;
    RETURN;
	
END
'
LANGUAGE plpgsql STABLE;

CREATE FUNCTION cake.str2sid(varchar) RETURNS integer
    AS '
    SELECT id from cake.session where cake.session.sid=$1
'
LANGUAGE 'SQL' STABLE;

CREATE FUNCTION cake.str2uid(varchar) RETURNS integer
    AS '
    SELECT id from cake.users where cake.users.login=$1
'
LANGUAGE 'SQL' STABLE;

CREATE FUNCTION cake.start_session(varchar, varchar) RETURNS void
    AS '
    INSERT INTO cake.session (sid, id_user) VALUES ($1, cake.str2uid($2))
'
LANGUAGE 'SQL' VOLATILE;

CREATE FUNCTION cake.stop_session(bigint,bigint,varchar) RETURNS void
    AS '
BEGIN
    PERFORM acct_update($3,$2,$1);
    UPDATE cake.session SET svolumeout=$1, svolume=$2, s_end=now() WHERE id=cake.str2sid($3);
    PERFORM clear_keepalive();
    RETURN;
END
'
LANGUAGE plpgsql VOLATILE;

CREATE FUNCTION cake.acct_update(varchar, bigint, bigint) RETURNS void 
    AS '
DECLARE

sid ALIAS FOR $1;
vin ALIAS FOR $2;
vout ALIAS FOR $3;
ck cake.keepalive%ROWTYPE;
as_id integer;
d_in bigint := 0;
d_out bigint := 0;

BEGIN
    -- потому что 7.4.x не хавает инициализацию с $1 в блоке DECLARE
    as_id := cake.str2sid(sid);

    -- выбираем последний присланный кипалив текущей сессии
    SELECT INTO ck * FROM cake.keepalive WHERE id_session=as_id 
	ORDER BY kdatetime DESC LIMIT 1;

    IF FOUND THEN 
	d_in := vout - ck.volumein;
	d_out := vin - ck.volumeout;
    ELSE
	d_in := vout;
	d_out := vin;
    END IF;

    -- вставляем запись о моментальном расходе траффика
    INSERT INTO cake.keepalive (id_session, volumeout, volumein, diff_in, diff_out )
	VALUES ( as_id, vin, vout, d_in, d_out);
    
    -- обновляем показания траффика в сессии
    UPDATE cake.session SET svolume=vin, svolumeout=vout, s_last_update=now()
	WHERE id=as_id;
    
    RETURN;
END
'
LANGUAGE plpgsql VOLATILE;
/*---------------------------------- функции работы с FreeRADIUS сервером --------------------------*/

/*---------------------------------- функции отчетов -----------------------------------------------*/
CREATE FUNCTION cake.u_mwb_report() RETURNS SETOF cake.mwb_report
    AS '
DECLARE

cuser cake.users%ROWTYPE;
cumwb cake.mwb_report%ROWTYPE;
mb_price numeric;

BEGIN
    FOR cuser IN SELECT * FROM cake.users LOOP
	SELECT INTO mb_price price_per_mb FROM cake.tariff 
	    WHERE cuser.id_tariff=cake.tariff.id;
    
	cumwb.ulogin := cuser.login;
	cumwb.uname := cuser.name;
	cumwb.userblock := cuser.userblock;
	cumwb.overtraffblock := cuser.overtraffblock;
	cumwb.bal_cur := cuser.balance;

	IF (mb_price >0) THEN
	    cumwb.bal_mb := cuser.balance/mb_price;
	ELSE 
	    SELECT INTO cumwb.bal_mb sum(svolume)/1048576 FROM cake.session
		WHERE ( cuser.id=cake.session.id_user);
	    IF cumwb.bal_mb IS NULL THEN
		cumwb.bal_mb := 0;
	    END IF;
	END IF;
	
	SELECT INTO cumwb.cur_week sum(volume) FROM cake.pay 
	    WHERE (id_user=cuser.id) AND ( paydate > date_trunc(''month'', now()));

	IF cumwb.cur_week IS NULL THEN 
	    cumwb.cur_week := 0;
	END IF;
	
	IF (mb_price >0) THEN
	    cumwb.traf_week := cumwb.cur_week/mb_price;
	ELSE 
	    cumwb.traf_week := 0;
	END IF;
	
	SELECT INTO cumwb.traf_month sum(svolume)/1048576 FROM cake.session
	    WHERE ( cuser.id=cake.session.id_user) AND 
	    ( cake.session.s_begin >= date_trunc(''month'', now()));
	
	IF cumwb.traf_month IS NULL THEN 
	    cumwb.traf_month := 0;
	END IF;

	cumwb.cur_month := (cumwb.traf_month*mb_price);

	RETURN NEXT cumwb; 	

    END LOOP;
    
    RETURN;
END
'
LANGUAGE plpgsql STABLE;

CREATE FUNCTION cake.u_mwb_report_all() RETURNS SETOF cake.mwb_report
    AS '
DECLARE

cuser cake.users%ROWTYPE;
cumwb cake.mwb_report%ROWTYPE;
cumwb_result cake.mwb_report%ROWTYPE;
mb_price numeric;

BEGIN
    cumwb_result.bal_cur := 0;
    cumwb_result.bal_mb := 0;
    cumwb_result.traf_week := 0;
    cumwb_result.cur_week := 0;		
    cumwb_result.traf_month := 0;
    cumwb_result.cur_month := 0;
		

    FOR cuser IN SELECT * FROM cake.users LOOP
	SELECT INTO mb_price price_per_mb FROM cake.tariff 
	    WHERE cuser.id_tariff=cake.tariff.id;
	
	cumwb.ulogin := cuser.login;
	cumwb.bal_cur := cuser.balance;
	
	IF (mb_price>0) THEN
	    cumwb.bal_mb := cuser.balance/mb_price;
	ELSE
	    SELECT INTO cumwb.bal_mb sum(svolume)/1048576 FROM cake.session
		WHERE ( cuser.id=cake.session.id_user);
	    IF cumwb.bal_mb IS NULL THEN
		cumwb.bal_mb := 0;
	    END IF;
	END IF;
	
	cumwb_result.bal_cur := cumwb_result.bal_cur + cumwb.bal_cur;
	cumwb_result.bal_mb := cumwb_result.bal_mb + cumwb.bal_mb;
	RAISE NOTICE ''mb_bal: %'',cumwb.bal_mb;
	
	SELECT INTO cumwb.cur_week sum(volume) FROM cake.pay 
	    WHERE (id_user=cuser.id) AND (paydate > date_trunc(''month'', now()));
    
	IF cumwb.cur_week IS NULL THEN 
	    cumwb.cur_week := 0;
	END IF;

	IF (mb_price>0) THEN
	    cumwb.traf_week := cumwb.cur_week/mb_price;
	ELSE
	    cumwb.traf_week := 0;
	END IF;

	cumwb_result.traf_week := cumwb_result.traf_week+cumwb.traf_week;
	cumwb_result.cur_week := cumwb_result.cur_week+cumwb.cur_week;
	
	SELECT INTO cumwb.traf_month sum(svolume)/1048576 FROM cake.session
	    WHERE (cuser.id=cake.session.id_user) AND (cake.session.s_begin >= date_trunc(''month'', now()));
	
	IF cumwb.traf_month IS NULL THEN 
	    cumwb.traf_month := 0;
	END IF;
	
	cumwb.cur_month := cumwb.traf_month*mb_price;
	
	cumwb_result.traf_month := cumwb_result.traf_month+cumwb.traf_month;
	cumwb_result.cur_month := cumwb_result.cur_month+cumwb.cur_month;
    END LOOP;
    
    RETURN NEXT cumwb_result;
    RETURN;
END
'
LANGUAGE plpgsql STABLE;

CREATE FUNCTION cake.u_mwb_report_user(varchar,varchar) RETURNS SETOF cake.mwb_report
    AS '
DECLARE
    
ulogin ALIAS FOR $1;
upwd ALIAS FOR $2;
cuser cake.users%ROWTYPE;
cumwb cake.mwb_report%ROWTYPE;
mb_price numeric;

BEGIN
    FOR cuser IN SELECT * FROM cake.users 
	WHERE (cake.users.login=ulogin) AND (cake.users.pwd=upwd) LOOP

	SELECT INTO mb_price price_per_mb FROM cake.tariff
	    WHERE (cuser.id_tariff=cake.tariff.id);

	cumwb.ulogin := cuser.login;
	cumwb.uname := cuser.name;
	cumwb.userblock := cuser.userblock;
	cumwb.overtraffblock := cuser.overtraffblock;
	cumwb.bal_cur := cuser.balance;
	
	IF (mb_price>0) THEN
	    cumwb.bal_mb := cuser.balance/mb_price;
	ELSE 
	    SELECT INTO cumwb.bal_mb sum(svolume)/1048576 FROM cake.session
		WHERE ( cuser.id=cake.session.id_user);
	    IF cumwb.bal_mb IS NULL THEN
		cumwb.bal_mb := 0;
	    END IF;
	END IF;
	
	SELECT INTO cumwb.cur_week sum(volume) FROM cake.pay 
	    WHERE (id_user=cuser.id) AND (paydate > date_trunc(''month'', now()));

	IF cumwb.cur_week IS NULL THEN 
	    cumwb.cur_week := 0; 
	END IF;

	IF (mb_price>0) THEN
	    cumwb.traf_week := cumwb.cur_week/mb_price;
	ELSE 
	    cumwb.traf_week := 0;
	END IF;
	
	SELECT INTO cumwb.traf_month sum(svolume)/1048576 FROM cake.session
	    WHERE (cuser.id=cake.session.id_user) AND (cake.session.s_begin >=date_trunc(''month'', now()));
	
	IF cumwb.traf_month IS NULL THEN 
	    cumwb.traf_month := 0; 
	END IF;

	cumwb.cur_month := cumwb.traf_month*mb_price;

	RETURN NEXT cumwb;
    END LOOP;
    RETURN;
END
'
LANGUAGE plpgsql STABLE;

/*---------------------------------- функции отчетов -----------------------------------------------*/

/* функция возвращающая значение параметра */
CREATE FUNCTION cake.getparameter(varchar) RETURNS text
    AS '
    SELECT value FROM cake.parameters WHERE name=$1
'
LANGUAGE 'SQL' STABLE;

/* функция ротации статистики */
CREATE FUNCTION cake.clear_keepalive() RETURNS void
    AS '
    DELETE FROM cake.keepalive
	WHERE kdatetime <= date_trunc(''day'',now() - (cake.getparameter(''clear_keepalive'') ||'' Days'')::interval)
'
LANGUAGE 'SQL' VOLATILE;
	
/* функция получения нового ip адреса из заданного пула */
CREATE FUNCTION cake.get_new_ip() RETURNS integer
    AS'
DECLARE 

new_ip integer;
min_pool_ip integer := cake.getParameter(''min_pool_ip'')::int;
max_pool_ip integer := cake.getParameter(''max_pool_ip'')::int;

BEGIN
    SELECT INTO new_ip max(ip_addr)  FROM cake.users;    

    IF (new_ip IS NULL) OR (new_ip+1 <= min_pool_ip) THEN
	new_ip := min_pool_ip;
    ELSE 
	IF new_ip+1 > max_pool_ip THEN
	    FOR i IN min_pool_ip..max_pool_ip LOOP
		SELECT INTO new_ip ip_addr FROM cake.users WHERE ip_addr=i;
		IF NOT FOUND THEN 
		    RETURN i;
		ELSE
		    new_ip := NULL;
		END IF;
	    END LOOP;
	ELSE
	    new_ip := new_ip+1;
	END IF;
    END IF;
	
    RETURN new_ip;
END
'
LANGUAGE plpgsql STABLE;

/* функция выдачи ip адреса из пула при добавлении нового пользователя */
CREATE FUNCTION cake.set_ip_for_newuser_f() RETURNS "trigger"
    AS '
BEGIN
    IF (new.ip_addr IS NULL) THEN 
	new.ip_addr :=  cake.get_new_ip();
    END IF;
    
    RETURN new;
END
'
LANGUAGE plpgsql VOLATILE;

/* функция увеличения баланса */
CREATE FUNCTION cake.inc_balance() RETURNS "trigger"
    AS '
DECLARE 

cuser cake.users%ROWTYPE;

BEGIN
    SELECT INTO cuser * FROM cake.users where new.id_user = cake.users.id;
    UPDATE cake.users SET balance=cuser.balance+new.volume
	WHERE cake.users.id=new.id_user;
    RETURN NULL;
END;    
'
LANGUAGE plpgsql VOLATILE;

/* функция изменения баланса */
CREATE FUNCTION cake.update_balance(int, numeric) RETURNS integer
    AS '
DECLARE

cuser cake.users%ROWTYPE;
uid ALIAS FOR $1;
new_balance ALIAS FOR $2;

BEGIN
    SELECT INTO cuser * FROM cake.users WHERE cake.users.id=uid;
    IF FOUND AND round((new_balance - cuser.balance)*100)<>0 THEN 
	INSERT INTO cake.pay (id_user,volume) VALUES (uid, (new_balance - cuser.balance));
        RETURN round(new_balance - cuser.balance);
    ELSE 
	RETURN NULL;
    END IF;
END;
'
LANGUAGE plpgsql VOLATILE;

/* функция декримента баланса пользователя */
CREATE FUNCTION cake.dec_user_balance_f() RETURNS "trigger"
    AS '
DECLARE

oldbalance numeric;
uid integer;
mb_price numeric;

BEGIN
    -- узнаем id и баланс пользователя
    SELECT INTO uid, oldbalance id, balance FROM cake.users WHERE old.id_user=cake.users.id;
    
    -- узнаем тариф текущего пользователя 
    SELECT INTO mb_price price_per_mb from cake.users, cake.tariff
	WHERE (cake.users.id_tariff=tariff.id) AND (cake.users.id=old.id_user);

    -- если тариф больше нуля, то обновляем баланс
    IF (mb_price>0) THEN
	UPDATE cake.users SET balance=oldbalance-((new.svolume-old.svolume)*mb_price)/1048576
	    WHERE cake.users.id=old.id_user;
    END IF;
    RETURN NULL;
END
'
LANGUAGE plpgsql VOLATILE;

/* триггер для внесения платежей */
CREATE TRIGGER inc_balance_on_ins_pay
    AFTER INSERT ON pay 
    FOR EACH ROW
    EXECUTE PROCEDURE inc_balance();


/* триггер для получения нового ip адреса */
CREATE TRIGGER set_ip_for_newuser
    BEFORE INSERT ON users
    FOR EACH ROW
    EXECUTE PROCEDURE set_ip_for_newuser_f();

/* триггер декримента баланса пользователя */
CREATE TRIGGER dec_user_balance
    AFTER UPDATE ON "session"
    FOR EACH ROW
    EXECUTE PROCEDURE dec_user_balance_f();

UPDATE cake.parameters SET name='idle_timeout' WHERE name='iddle_timeout';
INSERT INTO cake.parameters (name,value,"comment") VALUES ('clear_keepalive', '30', 'Время ротации статистики (в днях)');
ALTER TABLE cake.users ALTER COLUMN ip_addr DROP DEFAULT;
