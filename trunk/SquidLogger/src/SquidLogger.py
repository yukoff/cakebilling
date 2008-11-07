#!/usr/bin/python

from twisted.internet.protocol import DatagramProtocol
from twisted.internet import reactor
import MySQLdb



db = MySQLdb.connect("localhost","squid","squidpw","squid")
cu = db.cursor()

class SquidLogger(DatagramProtocol):

    def parseLog(self, log):
        data = log.split()
        time = data[0]
        status = data[1]
        host = data[2]
        request = data[3]
        reply = data[4]
        server = data[5]
        url = data[6]
        if status in ('TCP_MEM_HIT','TCP_REFRESH_HIT','TCP_HIT'):
            print "cached request: time:%s host:%s recived:%s send:%s server:%s url:%s" % (time,host,request,reply,server,url)
        else:
            cu.execute("""update aggregate set inbytes=inbytes+%s,outbytes=outbytes+%s where ip=%s""", (request,reply,host))
            print "not cached request: time:%s host:%s recived:%s send:%s server:%s url:%s" % (time,host,request,reply,server,
url)

    def datagramReceived(self, data, (host, port)):
        logs = data.splitlines()
        for log in logs:
            self.parseLog(log)

reactor.listenUDP(9999, SquidLogger())
reactor.run()

