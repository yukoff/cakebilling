# ���������� ��� ����������� ����� SQL
DEFAULT         Auth-Type:=Local

# �������� ������������. ���� ������ ����������� � pppd � mschap ������������ ���������
# Auth-Type:=MS-CHAP ������ Auth-Type:=Local, ����� RADIUS ������ �� ���������� �������.
# ������ ��� ������. 
#test            Auth-Type:=Local, User-Password == "test"
##test            Auth-Type:=MS-CHAP, User-Password == "test"
#                Service-Type = Framed-User,
#                Framed-Protocol = PPP,
#                Framed-IP-Address = 192.168.0.200,
#                Framed-IP-Netmask = 255.255.255.0,
#                Framed-Route = "192.168.1.0/24 192.168.200.204/32 1",
#                Reply-Message = "Just Test",
#                Acct-Interim-Interval = 60,
#                Session-Timeout = 120,
#		 Framed-Routing = Broadcast-Listen,
#                Framed-Compression = None