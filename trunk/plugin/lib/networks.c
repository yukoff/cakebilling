#include "networks.h"

struct networks_list *create_networks_list() {
	struct networks_list *new_network_list;
	
	new_network_list = malloc(sizeof(struct networks_list));

	if (new_network_list != NULL) {
		new_network_list->first=NULL;
		new_network_list->curr=NULL;
		new_network_list->last=NULL;
		new_network_list->count=0;
	}
	
	return new_network_list;
}

struct network_item *add_item_networks_list(struct networks_list *networks_list, struct network_item *after_item) {
	struct network_item *new_network_item;
	
	if (networks_list == NULL) return NULL;
	
	new_network_item = malloc(sizeof(struct network_item));

	if ( new_network_item == NULL) return NULL;
	
	new_network_item->destination = NULL;
	new_network_item->next = NULL;
	new_network_item->prev = NULL;
	new_network_item->netmask.s_addr = 0;
	new_network_item->network.s_addr = 0;

	if (networks_list->first == NULL) {
		networks_list->first = new_network_item;
		networks_list->last = new_network_item;
		networks_list->curr = new_network_item;
		networks_list->count++;
	}
	else {
		if (after_item == NULL) {
			new_network_item->next=networks_list->first;
			networks_list->first->prev = new_network_item;
			networks_list->first = new_network_item;
			networks_list->count++;
		}
		else {
			new_network_item->next = after_item->next;
			new_network_item->prev = after_item;
			after_item->next = new_network_item;
			networks_list->count++;
		}
	}
	
	return new_network_item;
}

struct network_item *del_item_networks_list(struct networks_list *networks_list, struct network_item *item) {
	
}