#ifndef DESTINATIONS_H_
#define DESTINATIONS_H_

#include <netinet/in.h>
#include <asm/types.h>

//! значения используемые для определения направления трафика
#define OUTGOING 0
#define INCOMING 1

//! Список направлений
struct destinations_list {
	struct destination *destinations; //!< список направлений
	__u32 count; //!< количество направлений в списке
};

//! Направление
struct destination {
	__u32 id; //!< идентификатор
	struct network *networks; //!< список сетей
	__u32 count; //!< количество сетей в списке
};

//! Сеть
struct network {
	struct in_addr network; //!< адрес сети
	struct in_addr netmask; //!< маска сети
};

//! Создает новое направление с идентификаторм id и списоком сетей длиной count, если count равен нулю, то список сетей не создается. В случае ошибки возвращает NULL
struct destination *create_destination(__u32 id, __u32 count);

//! Создает новый список сетей длиной count для существующего направления 
struct network *create_destination_network_list(struct destination *destination, __u32 count);

//! Изменяет сеть под индексом index в списке сетей направления destination, в случае неудачи возвращает -1
int set_destination_network(struct destination *destination, __u32 index, struct in_addr network, struct in_addr netmask);

//! Освобождает память занятую направлением destination, возвращает NULL для терминации указателя после освобожения памяти 
struct destination *delete_destination(struct destination *destination);

//! Создает новый список направлений длинной count, если же count равен нулю то список сетей не создается. В случае ошибки возвращает NULL
struct destinations_list *create_destinations_list(__u32 count);

//! Освобождает память занятую списком направлении, возвращает NULL для терминации указателя после освобождения памяти.
struct destination_list *delete_destinations_list(struct destinations_list *destinations_list);
#endif /*DESTINATIONS_H_*/
