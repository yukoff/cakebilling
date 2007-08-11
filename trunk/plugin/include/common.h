#ifndef COMMON_H
/*! \file
\brief заголовочный файл модуля общего назначения common.c
*/
#define COMMON_H 1

#include <stdio.h>
#include <netinet/in.h>
#include <sys/time.h>
#include <sys/types.h>
#include <asm/types.h>

//! список направлений
struct destination {
	__u32 count; //!< количество направлений в списке
	struct destination_item *destinations; //!< направления
};

//! направление
struct destination_item {
	__u32 id; //!< идентификатор
	struct in_addr network; //!< адрес сети
	struct in_addr netmask; //!< маска сети
	__u32 destination; //! идентификатор направления
};

//! возвращает идентификатор направления в зависимости от адреса направления
int get_service_type(__u32 daddr,struct destination *destination);

#endif
