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
	}
	else {
		if (after_item == NULL) {
			new_network_item->next=networks_list->first;
			networks_list->first->prev = new_network_item;
			networks_list->first = new_network_item;
		}
		else {
			new_network_item->next = after_item->next;
			new_network_item->prev = after_item;
			after_item->next = new_network_item;
		}
	}
	
	networks_list->count++;
	return new_network_item;
}

int del_item_networks_list(struct networks_list *networks_list, struct network_item *item) {
	struct network_item *del_item;

	if (networks_list == NULL) return -1;
	
	if (item == NULL) {
		if (networks_list->last != NULL) {
			del_item = networks_list->last;
			networks_list->last = del_item->prev;
			networks_list->last->next = NULL;
			free(del_item);
			networks_list->count--;
		} 
		else {
			return -1;
		}
	} 
	else {
		if (item->prev != NULL) {
			item->prev->next = item->next;
		}
		else {
			networks_list->first = item->next;
		}
		if (item->next != NULL) {
			item->next->prev = item->prev;
		}
		else {
			networks_list->last = item->prev;
		}
		if (networks_list->curr == item) {
			networks_list->curr == item->prev;
		}
		free(item);
		networks_list->count--;
	}

	return networks_list->count;
}

int destroy_networks_list(struct networks_list *networks_list) {
	if (networks_list == NULL) return -1;
	
	while (networks_list->count > 0) {
		del_item_networks_list(networks_list,NULL);
	}
	free(networks_list);
	return 0;
}

struct traffic_item *search_destination(struct networks_list *networks_list, struct in_addr ip) {
	if (networks_list == NULL) return NULL;
	
	networks_list->curr = networks_list->first;
	while (networks_list->curr != NULL) {
		if ((ip.s_addr & networks_list->curr->netmask.s_addr) == networks_list->curr->network.s_addr) {
			return networks_list->curr->destination;
		}
		networks_list->curr = networks_list->curr->next;
	}
	
	return NULL;
}
