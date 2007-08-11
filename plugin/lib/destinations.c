#include "destinations.h"

struct destination *create_destination(__u32 id, __u32 count) {
	struct destination *new_destination;
	
	if ((count < 0) || (id <= 0)) return NULL;
	
	new_destination = malloc(sizeof(struct destination));
	new_destination->id = id;

	if (count != 0) {
		new_destination->networks = malloc(sizeof(struct network)*count);
	}
	else { 
		new_destination->networks = NULL;
	}
	new_destination->count = count;
	
	return new_destination;
}

struct network *create_destination_network_list(struct destination *destination, __u32 count) {
	struct network *new_network;

	if ((destination == NULL) || (count <=0)) return NULL;
	
	new_network = malloc(sizeof(struct network)*count);
	
	destination->networks = new_network;
	destination->count = count;
	
	return new_network;
}

int set_destination_network(struct destination *destination, __u32 index, struct in_addr network, struct in_addr netmask) {
	if ((destination == NULL) || (destination->count <= 0) || (index > destination->count)) return -1;
	
	destination->networks[index].network = network;
	destination->networks[index].netmask = netmask;
	return 0;
}

struct destination *delete_destination(struct destination *destination) {
	if (destination == NULL) return NULL;
	
	if (destination->networks != NULL) free(destination->networks);
	free(destination);
	
	return NULL;
}

struct destinations_list *create_destinations_list(__u32 count) {
	struct destinations_list *new_destinations_list;
	int i;
	
	if (count < 0) return NULL;
	
	new_destinations_list = malloc(sizeof(struct destinations_list));
	if (count != 0) {
		new_destinations_list->destinations = malloc(sizeof(struct destination)*count);
		for (i = 0; i < new_destinations_list->count; i++) {
			new_destinations_list->destinations[i].networks = NULL;
			new_destinations_list->destinations[i].count = 0;
		}
	} 
	else {
		new_destinations_list->destinations = NULL;
	}
	new_destinations_list->count = count;
	
	return new_destinations_list;
}

struct destination_list *delete_destinations_list(struct destinations_list *destinations_list) {
	int i;
	
	if (destinations_list == NULL) return NULL;
	
	if (destinations_list->destinations != NULL) {
		for (i = 0; i < destinations_list->count; i++) {
			if (destinations_list->destinations[i].networks != NULL) {
				free(destinations_list->destinations[i].networks);
				destinations_list->destinations[i].count = 0;
			}
		}
		free(destinations_list->destinations);
	}
	free(destinations_list);
	
	return NULL;
}
