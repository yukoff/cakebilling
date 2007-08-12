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

#endif /*NETWORKS_H_*/
