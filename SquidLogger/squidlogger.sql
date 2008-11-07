create table proxy_user (
	id		int not null auto_increment,
	name		varchar(255) not null,
	passwd		varchar(255),
	primary key(id)
);

insert into proxy_user (id,name) values(1,'test');

create table proxy_user_ip (
	id			int not null auto_increment,
	proxy_user_id		int not null,
	ip			varchar(15) not null,
	primary key(id),
	foreign key(proxy_user_id) references proxy_user(id)
);

insert into proxy_user_ip (id,proxy_user_id,ip) values(1,1,'127.0.0.1');

create table proxy_server (
	id		int not null auto_increment,
	ip		varchar(25) not null,
	name		varchar(255),
	description	varchar(255),
	primary key(id)
);

insert into proxy_server (id,ip,name) values(1,'127.0.0.1','test proxy');

create table traffic (
	id			int not null auto_increment,
	proxy_user_ip_id	int not null,
	proxy_server_id		int not null,
	starttime		timestamp DEFAULT 0,
	period			int,
	inbytes			int(32) DEFAULT 0,
	outbytes		int(32) DEFAULT 0,
	cinbytes		int(32) DEFAULT 0,
	coutbytes		int(32) DEFAULT 0,
	primary key(id),
	foreign key(proxy_user_ip_id) references proxy_user_ip(id),
	foreign key(proxy_server_id) references proxy_server(id)
);

create table url (
	id			int not null auto_increment,
	traffic_id		int not null,
	gettime			timestamp DEFAULT 0,
	host			varchar(255),
	url			varchar(2048),
	cached			bool,
	inbytes			int(32) DEFAULT 0,
	outbytes		int(32) DEFAULT 0,
	primary key(id),
	foreign key(traffic_id) references traffic(id)
);
