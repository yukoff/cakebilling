#ifndef NETWORKS_H_
#define NETWORKS_H_

#include <netinet/in.h>
#include <asm/types.h>

//! Список сетей
struct networks_list {
	struct network_item *first; //!< начало списка
	struct network_item *last; //!< конец списка
	struct network_item *curr; //!< текущий элемент списка
	__u32 count; //!< количество направлений в списке
};

//! структура элемента списка направления
struct network_item {
	struct in_addr network; //!< адрес сети
	struct in_addr netmask; //!< маска сети
	struct traffic_item *destination; //!< указатель на направление
	struct network_item *prev; //!< указатель на предыдущий элемент
	struct network_item *next; //!< указатель на следующий элемент
};

//! Создает новый список сетей. В случае неудачи возвращает NULL
struct networks_list *create_networks_list();

//! Добавляет новый элемент в список сетей, Если after_item равен NULL, то элемент добавляется в начало. В противном случае элемент добавляется после after_item. При ошибке возвращает NULL.  
struct network_item *add_item_networks_list(struct networks_list *networks_list, struct network_item *after_item);

//! Удаляет элемент item из списка сетей. В случае если элемент равен NULL удаляется последний элемент. Возвращает количество оставшихся элементов или -1 в случае ошибки.
int del_item_networks_list(struct networks_list *networks_list, struct network_item *item);

//! Удаляет список сетей. Возвращает -1 в случае ошибки, в случае удачного завершения возвращает 0;
int destroy_networks_list(struct networks_list *networks_list);

//! Осуществляет поиск направления совпадающего с указаным ip. В случае удачного поиска возвращает направление, в портивоположном случае возвращает NULL.
struct traffic_item *search_destination(struct networks_list *networks_list, struct in_addr ip);

#endif /*NETWORKS_H_*/
