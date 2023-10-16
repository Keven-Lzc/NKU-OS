#include <buddy.h>
#include <list.h>
#include <string.h>
#include <pmm.h>
#include <stdio.h>


free_buddy_t free_buddy;

#define free_array (free_buddy.free_array)
#define nr_free (free_buddy.nr_free)
#define max_order (free_buddy.max_order)

static unsigned int log2(size_t n)
{
    unsigned int order = 0;
    while (n > 1)
    {
        ++order;
        n >>= 1;
    }
    return order;
}

// 计算不小于n的最大的2的幂次方
static size_t floor_pow2(size_t n)
{
    size_t ret = 1;
    while (n > 1)
    {
        ret <<= 1;
        n >>= 1;
    }
    return ret;
}

// 计算不小于n的最小的2的幂次方
static size_t ceil_pow2(size_t n)
{
    size_t ret = floor_pow2(n);
    return n == ret ? ret : (ret << 1);
}

// 初始化buddy系统
static void buddy_init()
{
    max_order = 0;
    nr_free = 0;
    for (int i = 0; i < MAX_ORDER; ++i)
        list_init(free_array + i);
}

// 初始化内存映射
static void buddy_init_memmap(struct Page *base, size_t n)
{
    assert(n > 0);
    size_t pn = floor_pow2(n); // 实际上要管理的页数
    max_order = log2(pn);      // 对应阶数

    for (struct Page *p = base; p != base + pn; ++p)
    {
        assert(PageReserved(p));
        p->flags = 0;       // 状态位置零
        p->property = 0;   // buddy中的property代表当前头页管理的页数的阶数
        set_page_ref(p, 0); // 引用位置零
    }

    nr_free = pn;
    base->property = max_order;
    SetPageProperty(base);  // base设置为头页
    list_add(&(free_array[max_order]), &(base->page_link));  // 链入
}

// 从阶数为order的空闲块中挑一个分裂
static void buddy_split(size_t order)
{
    assert(order > 0 && order <= max_order);

    if (list_empty(&(free_array[order])))   // 如果当前order没有空闲块，递归调用以找到更高阶的空闲块
        buddy_split(order + 1);
    
    struct Page *page_left = le2page(list_next(&(free_array[order])), page_link);
    page_left->property -= 1; // 左侧块的阶数减一
    struct Page *page_right = page_left + (1 << (page_left->property)); // 计算右侧块的地址
    SetPageProperty(page_right);    // 将右侧块设为头页
    page_right->property = page_left->property; // 设置右侧块的阶数

    list_del(list_next(&(free_array[order]))); // 从空闲链表中删除原来的块
    list_add(&(free_array[order - 1]), &(page_left->page_link)); // 将左侧块添加到较低阶的空闲链表
    list_add(&(page_left->page_link), &(page_right->page_link)); // 将左侧块和右侧块连接在一起
}

// 分配n个页
static struct Page* buddy_alloc_pages(size_t n)
{
    assert(n > 0);
    if (n > nr_free) return NULL;

    struct Page *ret = NULL;    // 要返回的指针
    size_t pn = ceil_pow2(n);  // 实际上要分配的页数
    unsigned int order = log2(pn);  // 要分配的页数的阶数

    if (list_empty(&(free_array[order])))
        buddy_split(order + 1);

    ret = le2page(list_next(&(free_array[order])), page_link); // 从空闲链表中取出一个页
    list_del(list_next(&(free_array[order]))); // 从空闲链表中删除已分配的页

    ClearPageProperty(ret); // 清除页的属性
    nr_free -= pn; // 更新空闲页数
    return ret;
}
// 获取伙伴块
static struct Page* get_buddy(struct Page *page)
{
    unsigned int order = page->property;
    unsigned int buddy_idx = (page - pages) ^ (1 << order); // 计算buddy的索引
    return pages + buddy_idx;
}

// 释放内存页
static void buddy_free_pages(struct Page *base, size_t n)
{
    assert(n > 0); 

    unsigned int order = base->property; // 当前块的阶数
    size_t pn = (1 << order); // 当前块的页数
    assert(pn == ceil_pow2(n)); 

    struct Page* left_block = base; // 释放的块视为左侧块
    list_add(&(free_array[order]), &(left_block->page_link));   // 加入到相应阶数的空闲块链表中

    struct Page* buddy = get_buddy(left_block); 
    while (left_block->property < max_order && PageProperty(buddy)) // 当满足合并条件时
    {
        if (left_block > buddy) // 如果左侧块的地址大于右侧块的地址交换
        {
            struct Page* tmp = left_block;
            left_block = buddy;
            buddy = tmp;
        }

        list_del(&(left_block->page_link)); // 移除左侧块
        list_del(&(buddy->page_link)); // 移除伙伴块
        left_block->property += 1; // 左侧块的阶数增加
        buddy->property = 0; // 伙伴块的阶数清零
        SetPageProperty(left_block); // 设置左侧块为头页
        ClearPageProperty(buddy); // 清除伙伴块的头页标志
    }

    nr_free += pn; // 更新可用空闲页的数量
}


static size_t buddy_nr_free_pages()
{
    return nr_free;
}

// 基本检查
static void basic_check(void)
{
	
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);
    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    assert(alloc_page() == NULL);

    free_page(p0);
    free_page(p1);
    free_page(p2);
    assert(nr_free == 3);

    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(alloc_page() == NULL);

    free_page(p0);

    struct Page *p;
    assert((p = alloc_page()) == p0);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);

    nr_free = nr_free_store;

    free_page(p);
    free_page(p1);
    free_page(p2);
	printf("max_order = %u\n", max_order);
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = basic_check,
};

