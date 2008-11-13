#!/usr/bin/python

from twisted.internet.protocol import DatagramProtocol
from twisted.internet import reactor
import MySQLdb
from time import localtime, strftime, time, mktime


class DbLogger:
    "Db Logger for Squid"
    proxy_server = {}
    proxy_userip = {}
    traffic = {}
            
    def __init__(self, host, user, password, database, interval):
        self.host = host
        self.user = user
        self.password = password
        self.database = database
        self.interval = interval
        self.connection = MySQLdb.connect(host,user,password,database)
        self.connection.autocommit(1)
        self.cursor = self.connection.cursor()
        self.get_proxy_servers()
        self.get_proxy_user_ips()
        tmptime = time()
        tmptime = localtime(stime-stime%interval)
        self.get_traffic(strftime("%Y-%m-%d %H:%M:%S",tmptime))
                         
    def get_proxy_servers(self):
        self.proxy_server.clear()
        self.cursor.execute("select id,ip from proxy_server")
        rows = self.cursor.fetchall()
        for i in xrange(len(rows)):
            self.proxy_server[rows[i][1]] = rows[i][0]

    def get_proxy_server_id(self, proxy_server_ip):
        try:
            proxy_server_id = self.proxy_server[proxy_server_ip]
        except StandardError:
            proxy_server_id = 0
        return proxy_server_id

    def get_traffic(self, starttime):
        self.traffic.clear()
        self.cursor.execute("select proxy_user_ip_id,proxy_user_id,proxy_server_id,starttime,period,id from traffic where starttime = %s", starttime)
        rows = self.cursor.fetchall()
        for i in xrange(len(rows)):
            self.traffic[(rows[i][0],rows[i][1],rows[i][2],mktime(rows[i][3].timetuple()),rows[i][4])] = rows[i][5]

    def get_traffic_id(self, proxy_user_id, proxy_user_ip_id, proxy_server_id, starttime, interval):
        try:
            traffic_id = self.traffic[(proxy_user_ip_id,proxy_user_id,proxy_server_id,starttime-starttime%interval,interval)]
        except StandardError:
            self.cursor.execute("insert into traffic (proxy_user_ip_id,proxy_user_id,proxy_server_id,starttime,period) values(%s,%s,%s,%s)", 
                            (proxy_user_ip_id, proxy_user_id, proxy_server_id, tmptime, interval))
            traffic_id = self.connection.insert_id()
            self.traffic[(proxy_user_ip_id,proxy_user_id, proxy_server_id, starttime-starttime%interval, interval)] = traffic_id 
        return traffic_id
 
    def get_proxy_user_ips(self):
        self.proxy_userip.clear()
        self.cursor.execute("select id, ip from proxy_user_ip")
        rows = self.cursor.fetchall()
        for i in xrange(len(rows)):
            self.proxy_userip[rows[i][1]] = rows[i][0]

    def get_proxy_user_ip_id(self,proxy_userip):
        try:
            proxy_user_ip_id = self.proxy_userip[proxy_user_ip]
        except StandardError:
            self.cursor.execute("insert into proxy_user_ip (proxy_user_id,ip) values (1,%s)", (proxy_user_ip))
            proxy_user_ip_id = self.connection.insert_id()
            self.proxy_userip[proxy_user_ip] = proxy_user_ip_id
        return proxy_user_ip_id

    def update_trafic(self, proxy_user_ip, proxy_server, starttime, interval, host, url, inbytes, outbytes, cached):
        tmptime = strftime("%Y-%m-%d %H:%M:%S",localtime(starttime-starttime%interval))
        proxy_user_ip_id = self.get_proxy_user_ip_id(proxy_userip)
        proxy_server_id = self.get_proxy_server_id(proxy_server_ip)
        if proxy_server_id == 0:
            return
        traffic_id = self.get_traffic_id(proxy_user_ip_id, proxy_server_id, starttime, interval)
        if cached:
            self.cursor.execute("update traffic set cinbytes=cinbytes+%s,coutbytes=coutbytes+%s where id=%s",(inbytes,outbytes,traffic_id))
        else:
            self.cursor.execute("update traffic set inbytes=inbytes+%s,outbytes=outbytes+%s where id=%s",(inbytes,outbytes,traffic_id))
        self.cursor.execute("insert into url (traffic_id,gettime,host,url,cached,inbytes,outbytes) values(%s,%s,%s,%s,%s,%s,%s)",
                                (traffic_id,strftime("%Y-%m-%d %H:%M:%S",localtime(starttime)),host,url,cached,inbytes,outbytes))
            
    def save(self,time,proxy,host,request,reply,server,url,status):
        savetime = float(time)
        if status in ('TCP_MEM_HIT','TCP_REFRESH_HIT','TCP_HIT'):
            print "cached/server %s: time:%s host:%s recived:%s send:%s server:%s url:%s" % (proxy,strftime("%Y-%m-%d %H:%M:%S",localtime(savetime)),host,request,reply,server,url)
            self.update_trafic(host, proxy, savetime, self.interval, host, url, request, reply, 1)
        else:
            print "not cached/serverid %s: time:%s host:%s recived:%s send:%s server:%s url:%s" % (proxy,strftime("%Y-%m-%d %H:%M:%S",localtime(savetime)),host,request,reply,server,url)
            self.update_trafic(host, proxy, savetime, self.interval, host, url, request, reply, 0)
 

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

dblogger = DbLogger("localhost","squid","squidpw","squidlogger",3600)
reactor.listenUDP(9999, SquidParser(dblogger))
reactor.run()
