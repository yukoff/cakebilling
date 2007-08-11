#include "common.h"

int get_service_type(__u32 daddr,struct destination *destination) {
	int i, service_type = 1;

	for (i = 0; i < destination->count; i++) {
		if ((daddr & destination->destinations[i].netmask.s_addr) == destination->destinations[i].network.s_addr){
	    	service_type = destination->destinations[i].destination;
	    	break;
		}
	}
	return service_type;
}
