#!/usr/bin/python

from twisted.internet.protocol import DatagramProtocol
from twisted.internet import reactor
import MySQLdb
from time import localtime, strftime


class DbLogger:
    "Db Logger for Squid"
    
    def __init__(self, host, user, password, database):
        self.proxy_servers = {}
        self.proxy_userips = {}
        self.host = host
        self.user = user
        self.password = password
        self.database = database
        self.connection = MySQLdb.connect(host,user,password,database)
        self.cursor = self.connection.cursor()
        self.get_proxy_servers()
        self.get_proxy_user_ips()

    def get_proxy_servers(self):
        self.cursor.execute("select id,ip from proxy_server")
        rows = self.cursor.fetchall()
        for i in xrange(len(rows)):
            self.proxy_servers[rows[i][1]] = rows[i][0]

    def get_proxy_user_ips(self):
        self.cursor.execute("select id,ip from proxy_user_ip")
        rows = self.cursor.fetchall()
        for i in xrange(len(rows)):
            self.proxy_userips[rows[i][1]] = rows[i][0]

    def save(self,time,proxy,host,request,reply,server,url,status):
        savetime = localtime(float(time))
	if status in ('TCP_MEM_HIT','TCP_REFRESH_HIT','TCP_HIT'):
	    print "cached/serverid %d: time:%s hostid:%d recived:%s send:%s server:%s url:%s" % (self.proxy_servers[proxy],strftime("%Y-%m-%d %H:%M:%S",savetime),self.proxy_userips[host],request,reply,server,url)
	else:
	    print "not cached/serverid %s: time:%s hostid:%d recived:%s send:%s server:%s url:%s" % (self.proxy_servers[proxy],strftime("%Y-%m-%d %H:%M:%S",savetime),self.proxy_userips[host],request,reply,server,url)


class SquidParser(DatagramProtocol):

    def __init__(self, logger):
        self.logger = logger
        self.__init__
        
    def parseLog(self, proxy, log):
	data = log.split()
	time = data[0]
	status = data[1]
	host = data[2]
	request = data[3]
	reply = data[4]
	server = data[5]
	url = data[6]
	self.logger.save(time,proxy,host,request,reply,server,url,status)

    def datagramReceived(self, data, (host, port)):
	logs = data.splitlines()
	for log in logs:
	    self.parseLog(host,log)

dblogger = DbLogger("localhost","squid","squidpw","squid")
reactor.listenUDP(9999, SquidParser(dblogger))
reactor.run()
