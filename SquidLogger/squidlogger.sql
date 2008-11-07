
drop table url;
drop table traffic;
drop table proxy_server;
drop table proxy_user_ip;
drop table proxy_user;

create table proxy_user (
	id		int not null auto_increment,
	name		varchar(255) not null,
	passwd		varchar(255),
	primary key(id)
);

create table proxy_user_ip (
	id			int not null auto_increment,
	proxy_user_id		int not null,
	ip			varchar(15) not null,
	primary key(id),
	foreign key(proxy_user_id) references proxy_user(id)
);

create table proxy_server (
	id		int not null auto_increment,
	ip		varchar(25) not null,
	name		varchar(255),
	description	varchar(255),
	primary key(id)
);

create table traffic (
	id			int not null auto_increment,
	proxy_user_ip_id	int not null,
	proxy_server_id		int not null,
	starttime		timestamp,
	period			int,
	inbytes			int(32),
	outbytes		int(32),
	cinbytes		int(32),
	coutbytes		int(32),
	primary key(id),
	foreign key(proxy_user_ip_id) references proxy_user_ip(id),
	foreign key(proxy_server_id) references proxy_server(id)
);

create table url (
	id			int not null auto_increment,
	traffic_id		int not null,
	gettime			timestamp,
	host			varchar(255),
	url			varchar(2048),
	cached			bool,
	inbytes			int(32),
	outbytes		int(32),
	primary key(id),
	foreign key(traffic_id) references traffic(id)
);
