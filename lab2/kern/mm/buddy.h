#ifndef __KERN_MM_BUDDYSYSTEM_H__
#define __KERN_MM_BUDDYSYSTEM_H__

#include <pmm.h>


#define MAX_ORDER 20

extern const struct pmm_manager buddy_pmm_manager;


typedef struct
{
    unsigned int max_order;             //最高阶
    list_entry_t free_array[MAX_ORDER + 1]; //空闲块链表
    unsigned int nr_free;               //空闲页的数量
} free_buddy_t;





#endif /* ! __KERN_MM_BUDDYSYSTEM_H__ */
