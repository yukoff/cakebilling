SET client_encoding = 'KOI8-R';
SET check_function_bodies = true;

CREATE SCHEMA cake AUTHORIZATION cake;

/* ������� ������� */
CREATE TABLE tariff (
    id serial NOT NULL,
    name varchar(50) DEFAULT 'New tariff' NOT NULL,
    price_per_mb numeric(9,2) DEFAULT 0 NOT NULL,
    ordr integer DEFAULT 0,
    speed integer DEFAULT 0,
    
    CONSTRAINT pk_tariff PRIMARY KEY (id),
    
    CONSTRAINT tariff_name_key UNIQUE (name)
    
);

/* ������� � �������������� */
CREATE TABLE users (
    id serial NOT NULL,
    login varchar(20) NOT NULL,
    name varchar(50) NOT NULL,
    pwd varchar(20) DEFAULT 'pwd',
    balance numeric(9,2) DEFAULT 0 NOT NULL,
    userblock boolean DEFAULT false NOT NULL,
    overtraffblock boolean DEFAULT true NOT NULL,
    ip_addr int,
    id_tariff int NOT NULL,
    grp bigint DEFAULT 0,

    CONSTRAINT pk_users PRIMARY KEY (id),
    CONSTRAINT unilogin UNIQUE (login),
    CONSTRAINT users_ip_addr_key UNIQUE (ip_addr),

    CONSTRAINT fk_users_tariff FOREIGN KEY (id_tariff) REFERENCES tariff(id) ON UPDATE CASCADE,
    
    CONSTRAINT users_login_not_empty CHECK (((login)::text <> ''::text)),
    CONSTRAINT users_name_not_empty CHECK (((name)::text <> ''::text))

);

CREATE INDEX index_login ON users USING hash (login);

/* ������� ������� �������� �������� */
CREATE TABLE pay (
    id serial NOT NULL,
    id_user int NOT NULL,
    paydate timestamp DEFAULT now() NOT NULL,
    volume numeric (9,2) DEFAULT 0 NOT NULL,
    id_error_pay bigint,
    
    CONSTRAINT pk_pay PRIMARY KEY (id),

    CONSTRAINT fk_pay_users FOREIGN KEY (id_user) REFERENCES users(id) ON UPDATE RESTRICT ON DELETE CASCADE

);

/* ������� ������ */
CREATE TABLE "session" (
    id serial NOT NULL,
    id_user int NOT NULL,
    sid varchar(16) NOT NULL,
    s_begin timestamp DEFAULT now() NOT NULL,
    s_end timestamp,
    svolume bigint DEFAULT 0 NOT NULL,
    svolumeout bigint DEFAULT 0 NOT NULL,
    s_last_update timestamp DEFAULT now(),
    
    CONSTRAINT pk_session PRIMARY KEY (id),
    
    CONSTRAINT fk_session_user FOREIGN KEY (id_user) REFERENCES users(id) ON UPDATE RESTRICT ON DELETE CASCADE

);

CREATE UNIQUE INDEX indx_sid ON "session" USING btree (sid);

CREATE INDEX idx_session_begin ON "session" USING btree (s_begin);
CREATE INDEX idx_session_end ON "session" USING btree (s_end);

/* ������� ������������� ��������� ������ */
CREATE TABLE keepalive (
    id serial NOT NULL,
    id_session int NOT NULL,
    kdatetime timestamp DEFAULT now() NOT NULL,
    volumein bigint DEFAULT 0 NOT NULL,
    volumeout bigint DEFAULT 0 NOT NULL,
    diff_in bigint DEFAULT 0 NOT NULL,
    diff_out bigint DEFAULT 0 NOT NULL,
    
    CONSTRAINT pk_keepalive PRIMARY KEY (id),

    CONSTRAINT fk_keepalive_session FOREIGN KEY (id_session) REFERENCES "session"(id) ON UPDATE RESTRICT ON DELETE CASCADE
        
);

CREATE INDEX idx_keepalive_datetime ON keepalive USING btree (kdatetime);

/* ������� ���������� */
CREATE TABLE parameters (
    id serial NOT NULL,
    name varchar(60) NOT NULL,
    value varchar(60) NOT NULL,
    "comment" varchar(100),
    
    CONSTRAINT pk_parameters PRIMARY KEY (id),
    
    CONSTRAINT uniname UNIQUE (name)
);

CREATE INDEX index_name ON parameters USING hash (name);

/*---------------------------------- ������� ������ � FreeRADIUS �������� --------------------------*/
CREATE TYPE auth_reply AS (
	id integer,
	username varchar,
	attribute varchar,
	value varchar,
	op varchar
);


-- �������� ������� ������
-- ����: �������� ���������� �������� � ��������� ������

CREATE FUNCTION check_idle_sessions() RETURNS void
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

CREATE FUNCTION auth_check(varchar) RETURNS SETOF auth_reply
    AS '
DECLARE

runame ALIAS FOR $1;
sid integer;

r cake.auth_reply%ROWTYPE;
cuser cake.users%ROWTYPE;

BEGIN
    -- �������� ������� ������
    PERFORM  cake.check_idle_sessions();
    
    SELECT INTO cuser * FROM cake.users where runame=cake.users.login;
    
    SELECT DISTINCT cake.session.id INTO sid FROM cake.session, cake.users
	WHERE (cake.session.id_user=cake.users.id) AND 
	(cake.session.s_end is null) AND
	(cake.users.login=runame) LIMIT 1;

    -- ���� ������������ ���� �� ���������� ������ 
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

CREATE FUNCTION auth_reply(varchar) RETURNS SETOF auth_reply
    AS '
DECLARE

r cake.auth_reply%ROWTYPE;
runame ALIAS FOR $1;
cuser cake.users%ROWTYPE;

mb_price numeric(9,2);

traffout bigint := cake.getParameter(''max_traffout'')::bigint;

BEGIN
    -- ������� ������������                                                                                                           
    SELECT INTO cuser * FROM cake.users WHERE runame=cake.users.login;

    -- ���� �� �������� �� ������ �������� ������������
    SELECT INTO mb_price price_per_mb FROM cake.tariff WHERE id=cuser.id_tariff;

    -- ���� ���� �� 0 � ����� ������������ ������ ���������,
    -- �� ������� ����� ��������, ����� �������� ��������
    IF (mb_price<>0) AND (traffout>=round((cuser.balance*1048576)/mb_price)) THEN
	traffout := round((cuser.balance*1048576)/mb_price);
    END IF;

    -- ���� ������������� ������ � �������� ����������, ���������� ���������� 
    IF  (traffout<=0) OR (cuser.userblock) THEN 
	traffout := 1; 
    END IF;
    
    -- ���������� � ���������� reply ��������
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

CREATE FUNCTION str2sid(varchar) RETURNS integer
    AS '
    SELECT id from cake.session where cake.session.sid=$1
'
LANGUAGE 'SQL' STABLE;

CREATE FUNCTION str2uid(varchar) RETURNS integer
    AS '
    SELECT id from cake.users where cake.users.login=$1
'
LANGUAGE 'SQL' STABLE;

CREATE FUNCTION acct_update(varchar, bigint, bigint) RETURNS void 
    AS '
DECLARE

as_id integer;
sid ALIAS FOR $1;
vin ALIAS FOR $2;
vout ALIAS FOR $3;
ck cake.keepalive%ROWTYPE;
d_in bigint := 0;
d_out bigint := 0;

BEGIN
    -- ������ ��� 7.4.x �� ������ ������������� � $1 � ����� DECLARE
    as_id := cake.str2sid(sid);

    -- �������� ��������� ���������� ������� ������� ������
    SELECT INTO ck * FROM cake.keepalive WHERE id_session=as_id 
	ORDER BY kdatetime DESC LIMIT 1;

    IF FOUND THEN 
	d_in := vout - ck.volumein;
	d_out := vin - ck.volumeout;
    ELSE
	d_in := vout;
	d_out := vin;
    END IF;

    -- ��������� ������ � ������������ ������� ��������
    INSERT INTO cake.keepalive (id_session, volumeout, volumein, diff_in, diff_out )
	VALUES ( as_id, vin, vout, d_in, d_out);
    
    -- ��������� ��������� �������� � ������
    UPDATE cake.session SET svolume=vin, svolumeout=vout, s_last_update=now()
	WHERE id=as_id;
    
    RETURN;
END
'
LANGUAGE plpgsql VOLATILE;

CREATE FUNCTION start_session(varchar, varchar) RETURNS void
    AS '
    INSERT INTO cake.session (sid, id_user) VALUES ($1, cake.str2uid($2))
'
LANGUAGE 'SQL' VOLATILE;

CREATE FUNCTION stop_session(bigint,bigint,varchar) RETURNS void
    AS '
BEGIN
    PERFORM acct_update($3,$2,$1);
    UPDATE cake.session SET svolumeout=$1, svolume=$2, s_end=now() WHERE id=cake.str2sid($3);
    PERFORM clear_keepalive();
    RETURN;
END
'
LANGUAGE plpgsql VOLATILE;
/*---------------------------------- ������� ������ � FreeRADIUS �������� --------------------------*/

/*---------------------------------- ������� ������� -----------------------------------------------*/
CREATE TYPE mwb_report AS (
    uname varchar,
    ulogin varchar,
    bal_cur numeric,
    bal_mb numeric,
    traf_week numeric,
    cur_week numeric,
    traf_month numeric,
    cur_month numeric,
    userblock boolean,
    overtraffblock boolean
);

CREATE FUNCTION u_mwb_report() RETURNS SETOF mwb_report
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

CREATE FUNCTION u_mwb_report_all() RETURNS SETOF mwb_report
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

CREATE FUNCTION u_mwb_report_user(varchar,varchar) RETURNS SETOF mwb_report
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
/*---------------------------------- ������� ������� -----------------------------------------------*/

/* ������� ������������ �������� ��������� */
CREATE FUNCTION getparameter(varchar) RETURNS text
    AS '
    SELECT value FROM cake.parameters WHERE name=$1
'
LANGUAGE 'SQL' STABLE;

/* ������� ������� ���������� */
CREATE OR REPLACE FUNCTION clear_keepalive() RETURNS void
    AS '
    DELETE FROM cake.keepalive
	WHERE kdatetime <= date_trunc(''day'',now() - (cake.getparameter(''clear_keepalive'') ||'' Days'')::interval)
'
LANGUAGE 'SQL' VOLATILE;
	
/* ������� ��������� ������ ip ������ �� ��������� ���� */
CREATE FUNCTION get_new_ip() RETURNS integer
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

/* ������� ������ ip ������ �� ���� ��� ���������� ������ ������������ */
CREATE FUNCTION set_ip_for_newuser_f() RETURNS "trigger"
    AS '
BEGIN
    IF (new.ip_addr IS NULL) THEN 
	new.ip_addr :=  cake.get_new_ip();
    END IF;
    
    RETURN new;
END
'
LANGUAGE plpgsql VOLATILE;

/* ������� ���������� ������� */
CREATE FUNCTION inc_balance() RETURNS "trigger"
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

/* ������� ��������� ������� */
CREATE FUNCTION update_balance(int, numeric) RETURNS integer
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

/* ������� ���������� ������� ������������ */
CREATE FUNCTION dec_user_balance_f() RETURNS "trigger"
    AS '
DECLARE

oldbalance numeric;
uid integer;
mb_price numeric;

BEGIN
    -- ������ id � ������ ������������
    SELECT INTO uid, oldbalance id, balance FROM cake.users WHERE old.id_user=cake.users.id;
    
    -- ������ ����� �������� ������������ 
    SELECT INTO mb_price price_per_mb from cake.users, cake.tariff
	WHERE (cake.users.id_tariff=tariff.id) AND (cake.users.id=old.id_user);

    -- ���� ����� ������ ����, �� ��������� ������
    IF (mb_price>0) THEN
	UPDATE cake.users SET balance=oldbalance-((new.svolume-old.svolume)*mb_price)/1048576
	    WHERE cake.users.id=old.id_user;
    END IF;
    RETURN NULL;
END
'
LANGUAGE plpgsql VOLATILE;

/* ������� ��� �������� �������� */
CREATE TRIGGER inc_balance_on_ins_pay
    AFTER INSERT ON pay 
    FOR EACH ROW
    EXECUTE PROCEDURE inc_balance();


/* ������� ��� ��������� ������ ip ������ */
CREATE TRIGGER set_ip_for_newuser
    BEFORE INSERT ON users
    FOR EACH ROW
    EXECUTE PROCEDURE set_ip_for_newuser_f();

/* ������� ���������� ������� ������������ */
CREATE TRIGGER dec_user_balance
    AFTER UPDATE ON "session"
    FOR EACH ROW
    EXECUTE PROCEDURE dec_user_balance_f();

INSERT INTO parameters (name,value,"comment") VALUES ('traffinterval', '60', '������ ���������� ������ � ������� �������� (� ��������)');
INSERT INTO parameters (name,value,"comment") VALUES ('ipnetmask', '255.255.255.0', '����� ����������� ����');
INSERT INTO parameters (name,value,"comment") VALUES ('max_traffout', '1073741824', '������������ ������� ������ (� ������)');
INSERT INTO parameters (name,value,"comment") VALUES ('min_pool_ip', '2', '����������� ip ����� �������');
INSERT INTO parameters (name,value,"comment") VALUES ('max_pool_ip', '254', '������������ ip ����� �������');
INSERT INTO parameters (name,value,"comment") VALUES ('idle_timeout','7200', '&laquo;������&raquo; ������� (� ��������)');
INSERT INTO parameters (name,value,"comment") VALUES ('ipsubnet','192.168.2', '����������� ������� (� ������� &laquo;x.x.x&raquo;)');
INSERT INTO parameters (name,value,"comment") VALUES ('max_timeout', '43200', '������������ ����� ������ (� ��������)');
INSERT INTO parameters (name,value,"comment") VALUES ('clear_keepalive', '30', '����� ������� ���������� (� ����)');


INSERT INTO tariff (name,price_per_mb) VALUES ('��������',1.00);

INSERT INTO users (login, name, pwd, balance, userblock, overtraffblock, ip_addr, id_tariff ,grp) VALUES('admin', 'Admin', '1234', 0.00, 'f', 't', 2, 1, 1);
