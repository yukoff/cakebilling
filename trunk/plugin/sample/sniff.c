#include <pcap.h>
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <errno.h>
#include <poll.h>

int count = 0;
pcap_t *handle;

void *got_packet(u_char *args, const struct pcap_pkthdr *header, const u_char *packet) {
	count +=header->len;
}


void *process_if(void *test){
	int pdr;
	struct pollfd pfd;
	printf("Run thread\n");
	for(;;) {
        pdr = pcap_dispatch(handle, 0, got_packet, NULL);

        /* Timeout */
        if(pdr == 0) {
                pfd.fd = pcap_fileno(handle);
                pfd.events = POLLIN;
                poll(&pfd, 1, -1);
                continue;
        }

	}
	
	return NULL;
}

int main() {
	char *dev = "eth0";
	char errbuf[PCAP_ERRBUF_SIZE];
//	pcap_t *handle;
	
	char filter_exp[] = "ip";		/* filter expression [3] */
	struct bpf_program fp;			/* compiled filter program (expression) */
	bpf_u_int32 mask;				/* subnet mask */
	bpf_u_int32 net;				/* ip */
	int num_packets = 10;			/* number of packets to capture */
	pthread_t pcap_thread;

	/* open capture device */
	handle = pcap_open_live(dev, 600, 1, 1000, errbuf);
	if (handle == NULL) {
		printf("Couldn't open device %s: %s\n", dev, errbuf);
		exit(EXIT_FAILURE);
	}

	/* make sure we're capturing on an Ethernet device [2] */
	if (pcap_datalink(handle) != DLT_EN10MB) {
		printf("%s is not an Ethernet\n", dev);
		exit(EXIT_FAILURE);
	}

	/* compile the filter expression */
	if (pcap_compile(handle, &fp, filter_exp, 0, net) == -1) {
		printf("Couldn't parse filter %s: %s\n",
		    filter_exp, pcap_geterr(handle));
		exit(EXIT_FAILURE);
	}

	/* apply the compiled filter */
	if (pcap_setfilter(handle, &fp) == -1) {
		printf("Couldn't install filter %s: %s\n",
		    filter_exp, pcap_geterr(handle));
		exit(EXIT_FAILURE);
	}

	/* now we can set our callback function */
	//pcap_loop(handle, 0, got_packet, NULL);
	pthread_create(&pcap_thread, NULL, process_if, NULL);
	for(;;){
		sleep(1);
		printf("Got bytes [%d]\n", count);
	}

	/* cleanup */
	pcap_freecode(&fp);
	pcap_close(handle);

	printf("\nCapture complete.\n");

}
