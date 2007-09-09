#include "traffic.h"

struct traffic_list *create_traffic_list() {
	struct traffic_list *new_traffic_list;
	
	new_traffic_list = (struct traffic_list *)malloc(sizeof(struct traffic_list));

	if (new_traffic_list != NULL) {
		new_traffic_list->first=NULL;
		new_traffic_list->curr=NULL;
		new_traffic_list->last=NULL;
		new_traffic_list->count=0;
	}
	return new_traffic_list;
}

struct traffic_item *add_item_traffic_list(struct traffic_list *traffic_list) {
	struct traffic_item *add_item;

	add_item = (struct traffic_item *)malloc(sizeof(struct traffic_item));

	if (add_item == NULL) return add_item;

	add_item->service_type=0;
	add_item->in_traffic=0;
	add_item->out_traffic=0;
	add_item->prev=NULL;
	add_item->next=NULL;

	if (traffic_list->first == NULL) {
		traffic_list->first=add_item;
		traffic_list->curr=add_item;
		traffic_list->last=add_item;
	}
	else {
		add_item->next=traffic_list->first;
		traffic_list->first->prev=add_item;
		traffic_list->first=add_item;
	}
	traffic_list->count++;
	return add_item;
}

int del_item_traffic_list(struct traffic_list *traffic_list) {
	struct traffic_item *del_item;

	if ((traffic_list == NULL) || (traffic_list->last == NULL)) return -1;
	
	del_item=traffic_list->last;
 	traffic_list->last=traffic_list->last->prev;

	if (traffic_list->last != NULL) {
		traffic_list->last->next=NULL;
	}
	else {
		traffic_list->first = NULL;
		traffic_list->curr = NULL;
	}
	free(del_item);
	traffic_list->count--;
	
	return traffic_list->count;
}

struct traffic_item *search_traffic_list(struct traffic_list *traffic_list, __u32 service_type) {

	traffic_list->curr=traffic_list->first;

	if (traffic_list->curr == NULL) return traffic_list->curr;

	do {
		if (traffic_list->curr->service_type == service_type) {
			break;
		}
		else {
			traffic_list->curr=traffic_list->curr->next;
		}
	}
	while (traffic_list->curr != NULL);

	return traffic_list->curr;
}

void add_count_traffic_item(struct traffic_item *index, unsigned long int caddr, int service_type, __u64 traffic, int order) {

	if (index->service_type != service_type){
		index->service_type = service_type;
	}

    if (order == INCOMING ){
		index->in_traffic += traffic;
    }
    else {
		index->out_traffic += traffic;
    }
}

int destroy_traffic_list(struct traffic_list *traffic_list) {

	if (traffic_list == NULL) return -1;
	
	while (traffic_list->count > 0) {
		del_item_traffic_list(traffic_list);
	}
	free(traffic_list);
	return 0;
}
