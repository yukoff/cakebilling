#ifndef FIFO_H
/*! \file
\brief заголовочный файл модуля управления очередями трафика fifo.c

*/
#define FIFO_H

#include <stdio.h>
#include <string.h>
#include <syslog.h>
#include <netinet/in.h>
#include <asm/types.h>

//! значения используемые для определения направления трафика
#define OUTGOING 0
#define INCOMING 1
//! структура элемента трафик направления
struct traffic_item {
	__u32 service_type; //!< тип направления
	__u64 in_traffic; //!< входящий трафик
	__u64 out_traffic; //!< исходящий трафик
	struct traffic_item *prev; //!< предыдущий элемент
	struct traffic_item *next; //!< следующий элемент
};

//! список с трафиком направлений
struct fifo {
    unsigned long long count; //!< количество направлений в списке
	struct traffic_item *first; //!< начало списка
	struct traffic_item *curr; //!< текущий элемент списка
	struct traffic_item *last; //!< конец списка
};

/*! \brief инициализация очереди трафика

Выделяет область памяти размером struct fifo, далее инициализрует все указатели значением NULL
и выставляет счетчик элементов очереди в 0.\n
При удачном завершении возвращает указатель на созданную очередь трафика.\n
При неудачном завершении возвращает NULL.
*/
struct fifo *init_fifo();

/*! \brief добавляет элемент в хвост очереди

Выделяет область памяти под новый элемент, инициализрует его и размещает его в хвост очереди manage_fifo,
затем увеличивает счетчик очереди.\n
При удачном завершении возвращает указатель на новый элемент очереди.\n
При неудачном завершении возвращает NULL.
*/
struct traffic_item *push_fifo(struct fifo *manage_fifo);

/*! \brief удаляет элемент из начала очереди

Выделяет память под копию удаляемого элемента, копирует элемент затем удаляет элемент из очереди
и уменьшает счетчик очереди.
При удачном завершении и не пустой очереди возвращает указатель на копию удаленного элемента очереди.\n
При неудачном завершении или пустой очереди возвращает NULL
*/
struct traffic_item *pop_fifo(struct fifo *manage_fifo);

//! создает копию очереди
struct fifo *copy_fifo(struct fifo *manage_fifo);

/*! \brief поиск элемента по адресу клиента и типу сервиса

Осуществляет поиск элемента по адресу клиента и типу сервиса в очереди manage_fifo.\n
При удачном завершении устанавливает указатель очереди manage_fifo->curr и возвращает его.
При неудачном завершении возвращает NULL.
*/
struct traffic_item *search_fifo(struct fifo *manage_fifo, __u32 service_type);

/*! \brief очищает очередь.

Осуществляет очистку очереди manage_fifo от элементов.
*/
void flush_fifo(struct fifo *manage_fifo);

#endif
