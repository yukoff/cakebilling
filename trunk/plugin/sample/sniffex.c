#include <pcap.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <pthread.h>
#include <arpa/inet.h>
#include "llheader.h"
#include "traffic.h"
#include "networks.h"

struct traffic_list *traffic;
struct networks_list *networks;
struct in_addr client_ip;
pthread_t pcap_tid;

int count = 1;                   /* packet counter */
int num_packets = 10;			/* number of packets to capture */
pcap_t *handle;				/* packet capture handle */

void got_packet(u_char *args, const struct pcap_pkthdr *header, const u_char *packet);

void collector_routine(void *arg){
	/* now we can set our callback function */
	fprintf(stdout,"Run capture thread\n");
	pcap_loop(handle, num_packets, got_packet, NULL);
	pthread_exit(NULL);
}

/*
 * dissect/print packet
 */
void got_packet(u_char *args, const struct pcap_pkthdr *header, const u_char *packet) {
	
	/* declare pointers to packet headers */
	const struct sll_header *ll_header;
	const struct sniff_ip *ip;              /* The IP header */
	int service_type = 1;
	struct traffic_item *node=NULL;
	
	int size_ip;
	
	printf("\nPacket number %d:\n", count);
	count++;
	
	printf("Packet length: %d\n",header->len - SLL_HDR_LEN);

	/* define link layer header */
	ll_header = (struct sll_header*)(packet);
	
	/* define/compute ip header offset */
	ip = (struct sniff_ip*)(packet + SLL_HDR_LEN);
	size_ip = IP_HL(ip)*4;
	if (size_ip < 20) {
		printf("   * Invalid IP header length: %u bytes\n", size_ip);
		return;
	}

	if (ip->ip_src.s_addr == client_ip.s_addr) {
		node=search_traffic_list(traffic,service_type);
		if (node == NULL) {
			node = add_item_traffic_list(traffic);
		}
		add_count_traffic_item(node,service_type,header->len - SLL_HDR_LEN,INCOMING);		
	}
	if (ip->ip_dst.s_addr == client_ip.s_addr) {
		node=search_traffic_list(traffic,service_type);
		if (node == NULL) {
			node = add_item_traffic_list(traffic);
		}
		add_count_traffic_item(node,service_type,header->len - SLL_HDR_LEN,OUTGOING);				
	}
	printf("IP Packet length: %d\n",size_ip);
	/* print source and destination IP addresses */
	printf("       From: %s\n", inet_ntoa(ip->ip_src));
	printf("         To: %s\n", inet_ntoa(ip->ip_dst));

return;
}

int main(int argc, char **argv) {

	char *dev = NULL;			/* capture device name */
	char errbuf[PCAP_ERRBUF_SIZE];		/* error buffer */

	char filter_exp[] = "ip";		/* filter expression [3] */
	struct bpf_program fp;			/* compiled filter program (expression) */
	bpf_u_int32 mask;			/* subnet mask */
	bpf_u_int32 net;			/* ip */
	int ret;

	/* check for capture device name on command-line */
	if (argc == 3) {
		dev = argv[1];
		if (inet_aton(argv[2],&client_ip) == 0) {
			fprintf(stderr,"error: ip address %s not valid\n",argv[2]);
		}
		else {
			fprintf(stdout,"Used ip address: %s\n",argv[2]);
		}
	}
	else if (argc > 3) {
		fprintf(stderr, "error: unrecognized command-line options\n\n");
		exit(EXIT_FAILURE);
	}
	else {
		/* find a capture device if not specified on command-line */
		dev = pcap_lookupdev(errbuf);
		if (dev == NULL) {
			fprintf(stderr, "Couldn't find default device: %s\n",
			    errbuf);
			exit(EXIT_FAILURE);
		}
	}
	
	/* get network number and mask associated with capture device */
	if (pcap_lookupnet(dev, &net, &mask, errbuf) == -1) {
		fprintf(stderr, "Couldn't get netmask for device %s: %s\n",
		    dev, errbuf);
		net = 0;
		mask = 0;
	}

	/* print capture info */
	printf("Device: %s\n", dev);
	printf("Number of packets: %d\n", num_packets);
	printf("Filter expression: %s\n", filter_exp);

	/* open capture device */
	handle = pcap_open_live(dev, SNAP_LEN, 0, 1000, errbuf);
	if (handle == NULL) {
		fprintf(stderr, "Couldn't open device %s: %s\n", dev, errbuf);
		exit(EXIT_FAILURE);
	}

	/* make sure we're capturing on an VPN device [2] */
	if (pcap_datalink(handle) != DLT_LINUX_SLL ) {
		fprintf(stderr, "%s is not an Linux cooked\n", dev);
		exit(EXIT_FAILURE);
	}
	
	/* compile the filter expression */
	if (pcap_compile(handle, &fp, filter_exp, 0, net) == -1) {
		fprintf(stderr, "Couldn't parse filter %s: %s\n",
		    filter_exp, pcap_geterr(handle));
		exit(EXIT_FAILURE);
	}

	/* apply the compiled filter */
	if (pcap_setfilter(handle, &fp) == -1) {
		fprintf(stderr, "Couldn't install filter %s: %s\n",
		    filter_exp, pcap_geterr(handle));
		exit(EXIT_FAILURE);
	}
	traffic = create_traffic_list();

	ret = pthread_create(&pcap_tid, NULL, collector_routine, NULL);
	
	while (count < 10) {};
	/* cleanup */
	pcap_freecode(&fp);
	pcap_close(handle);

	printf("\nCapture complete.\n");

return 0;
}

