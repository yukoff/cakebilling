#include "fifo.h"

struct fifo *create_fifo() {
	struct fifo *manage_fifo = (struct fifo *)malloc(sizeof(struct fifo));
	if (manage_fifo != NULL) {
		manage_fifo->first=NULL;
		manage_fifo->curr=NULL;
		manage_fifo->last=NULL;
		manage_fifo->count=0;
	}
	return manage_fifo;
}

struct traffic_item *push_fifo(struct fifo *manage_fifo) {
	struct traffic_item *push_item;

	push_item = (struct traffic_item *)malloc(sizeof(struct traffic_item));

	if (push_item == NULL) return push_item;

	push_item->service_type=0;
	push_item->in_traffic=0;
	push_item->out_traffic=0;
	push_item->prev=NULL;
	push_item->next=NULL;

	if (manage_fifo->first == NULL) {
		manage_fifo->first=push_item;
		manage_fifo->curr=push_item;
		manage_fifo->last=push_item;
	}
	else {
		push_item->next=manage_fifo->first;
		manage_fifo->first->prev=push_item;
		manage_fifo->first=push_item;
	}
	manage_fifo->count++;
	return push_item;
}

struct traffic_item *pop_fifo(struct fifo *manage_fifo) {
	struct traffic_item *pop_item,*old;

	pop_item=(struct traffic_item *)malloc(sizeof(struct traffic_item));

	if (pop_item == NULL) return pop_item;

	if (manage_fifo->last != NULL) {
		memcpy(pop_item,manage_fifo->last,sizeof(struct traffic_item));
		old=manage_fifo->last;
 		manage_fifo->last=manage_fifo->last->prev;

		if (manage_fifo->last != NULL) {
	    	manage_fifo->last->next=NULL;
		}
		else {
			manage_fifo->first = NULL;
			manage_fifo->curr = NULL;
		}
		free(old);
		manage_fifo->count--;
	}
	else {
		free(pop_item);
		pop_item = NULL;
	}
	return pop_item;
}

struct traffic_item *search_fifo(struct fifo *manage_fifo, __u32 service_type) {

	manage_fifo->curr=manage_fifo->first;

	if (manage_fifo->curr == NULL) return manage_fifo->curr;

	do {
		if (manage_fifo->curr->service_type == service_type) {
			break;
		}
		else {
			manage_fifo->curr=manage_fifo->curr->next;
		}
	}
	while (manage_fifo->curr != NULL);

	return manage_fifo->curr;
}

void add_traffic_to_fifo_item(struct traffic_item *index, unsigned long int caddr, int service_type, __u64 traffic, int order) {

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

struct fifo *copy_fifo(struct fifo *manage_fifo) {
	struct fifo *newfifo;
	struct traffic_item *newfifo_item;

	newfifo = create_fifo();
	manage_fifo->curr = manage_fifo->first;
	while (manage_fifo->curr != NULL) {
		newfifo_item = push_fifo(newfifo);
		newfifo_item->service_type = manage_fifo->curr->service_type;
		newfifo_item->in_traffic = manage_fifo->curr->in_traffic;
		newfifo_item->out_traffic = manage_fifo->curr->out_traffic;
		manage_fifo->curr = manage_fifo->curr->next;
	}
	return newfifo;
}

void flush_fifo(struct fifo *manage_fifo) {
	struct traffic_item *pop=NULL;

	do {
		pop = pop_fifo(manage_fifo);
		if (pop != NULL) free(pop);
	}
	while ( pop != NULL);
}
