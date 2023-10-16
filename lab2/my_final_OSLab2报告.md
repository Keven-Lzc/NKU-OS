# 操作系统Lab2实验报告
#### By 叶潇晗（2112120）, 张振铭（2112189），林子淳（2114042）
### 一、实验练习

#### 练习1: 理解first-fit 连续物理内存分配算法（思考题）
first-fit 连续物理内存分配算法作为物理内存分配一个很基础的方法，需要同学们理解它的实现过程。请大家仔细阅读实验手册的教程并结合```kern/mm/default_pmm.c```中的相关代码，认真分析default_init，default_init_memmap，default_alloc_pages， default_free_pages等相关函数，并描述程序在进行物理内存分配的过程以及各个函数的作用。请在实验报告中简要说明你的设计实现过程。请回答如下问题：
* 你的first fit算法是否有进一步的改进空间？

**default_init函数的作用：**
观察函数内部的代码：

    list_init(&free_list);
    nr_free = 0;


不难发现，该函数用于初始化一个管理内存分配的链表数据结构，其中nr_free表示链表包含的空闲页个数，在链表为空时其值当然为0。结合```lib/list.h```中list_init函数的代码：

    elm->prev = elm->next = elm;

其中prev 和 next 指针，它们分别指向前一个和后一个链表节点，以构建双向链表。在初始化时，prev 和 next 都被设置为指向自身，这表示一个空的链表节点。
综上所述，default_init 函数的作用是初始化内存管理系统中的链表数据结构，使内存管理系统准备好处理分配和释放内存的请求。

**default_init_memmap函数的作用：**
default_init_memmap函数的作用是根据传递过来的两个参数（分别为某个连续地址的空闲块的起始页和页的个数），来为存放内存空闲块的双向链表free_list生成新的空闲块。详细流程介绍如下：
首先通过以下代码：

    struct Page *p = base;
    for (; p != base + n; p++)
    {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
来初始化这n个页的属性，就是将该页块中的所有页的标志位flags(最低2位有效)和页属性property设为0，这两个值的具体含义如下：

    #define PG_reserved                 0       
    // if this bit=1: the Page is reserved for kernel, cannot be used in alloc/free_pages; 
    // otherwise, this bit=0 
    #define PG_property                 1       
    // if this bit=1: the Page is the head page of a free memory block(contains some continuous_addrress pages), and can be used in alloc_pages; 
    // if this bit=0: if the Page is the the head page of a free memory block, then this Page and the memory block is alloced. 
       // Or this Page isn't the head page.

其中assert(PageReserved(p))是一个assert函数，首先检查p（准确来说是p->flag）的PG_reserved位(第0位)是否设置为1，确保空闲可分配。然后是设置此页的flag等于0，其每一位都是0，自然其PG_property位(第1位)为0，以及接下来的set_page_ref(p, 0)，都是表示设置该页是没有被占用的。
之后再通过以下代码：
    
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
来对页base的参数进行设置，空闲块的第一页的property设置为块中的总页数，用这个页来集中代表这个空闲块的页数，SetPageProperty(base)将空闲块的第一页的PG_property位设置为1，表示是起始页，可以被用作分配内存，再将现在空闲页的总数目加n，就完成了对需要添加的空闲内存块的属性的配置。
接下来再将这些页插入到双向链表free_list便可完成空闲内存的添加。具体插入代码不作赘述，不过值得一提的是，这些页是按照它们的地址从低到高的顺序排列在free_list当中的，因此这部分代码是按照类似插入排序算法的思想在正确位置插入这些页的。

**default_alloc_pages函数的作用：**
default_alloc_pages函数的作用是在空闲空间足够的情况下，按照first fit算法的流程方式来返回有n个空闲页的内存。具体流程如下：

首先检查总页数nr_free的值，若其小于需要的页数n，则一定无法分配内存，直接返回。之后从链表free_list头部开始遍历各个页，循环代码如下：

    while ((le = list_next(le)) != &free_list)
    {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n)
        {
            page = p;
            break;
        }
    }
其中struct Page *p = le2page(le, page_link)是根据当前链表的指针结构体还原分到一个页结构， 然后判断一旦出现一个页面的property大于等于n，即该空闲块的连续空页数大于等于n，那么表示可以分配，并使用指针page指向这个头页（Head Page）来记录这个块.
在成功寻找到第一个符合条件的空闲块之后，需要对该块进行划分，即返回需要的内存之后保留剩下的内存。划分空间的代码如下：

    if (page != NULL)
    {
        list_entry_t *prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n)
        {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;

首先指针prev获取目标块的前驱来记录其位置，防止delete之后丢失位置信息，然后创建页指针p指向目标向后n个页的位置，该位置作为后来剩余空闲内存的起始位置，并将p对应的Head Page的属性property设置为原数目减n，表示其包含页的数目减少n。
在通过SetPageProperty(p)将p设置为空闲之后，再插入到free_list当中，最后通过ClearPageProperty(page)清除page的PG_propert位并将这份内存返回。

至此就完成了default_alloc_pages空闲内存的分配与划分过程。

**default_free_pages函数的作用：**
default_free_pages函数的作用是根据传递过来的某个被占用块的起始页、页的个数这两个参数，将这段内存释放并重新添加到空闲链表free_list当中。而且，如果释放回来的内存块和它附近已有的空闲块地址相邻的话，还要将它们合并成一个更大的空闲块。详细流程介绍如下：

default_free_pages当中释放内存的代码和default_init_memmap的代码几乎完全一致，都是将目标块插入到free_list当中。而它们的区别在于default_free_pages在此之后还需要合并相邻的空闲块。以与地址相邻的前驱空闲块合并为例，代码如下：

    list_entry_t *le = list_prev(&(base->page_link));
    if (le != &free_list)
    {
        p = le2page(le, page_link);
        if (p + p->property == base)
        {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }
首先使用le保存前驱，如果释放回来的块的起始页在上一个空闲块的后面，那么进行合并，将前驱空闲块的连续空页数加上释放块起始页base的连续空页数，然后再清除base的PG_property位，表示base不再是起始页。将原来的空闲块删除之后,p即表示为合并后的新空闲块。
向后合并的方法与上述方法类似，不作赘述。

**first fit算法的改进：**
在进行初始化以及释放内存的时候，需要遍历双向链表并进行指针修改等操作，其总体时间复杂度为O(n)。基于此，可提出以下改进方案：

**建立平衡搜索树**
考虑到free_list当中各个块是根据地址从低到高按顺序排列的，可以考虑将使用平衡二叉搜索树（AVL）数据结构取代简单的链表结构来维护空闲块，这样按照中序遍历得到的空闲块序列的地址恰好按照从小到大排序。而在每次进行查询的时候，从根节点开始，查询左子树的最大空闲块是否符合要求，如果是的话进入左子树进行进一步查询，否则进入右子树。这样就可以在查找页块时将时间复杂度降到O(logn)。


#### 练习2: 实现 Best-Fit 连续物理内存分配算法（需要编程）
在完成练习一后，参考kern/mm/default_pmm.c对First Fit算法的实现，编程实现Best Fit页面分配算法，算法的时空复杂度不做要求，能通过测试即可。 请在实验报告中简要说明你的设计实现过程，阐述代码是如何对物理内存进行分配和释放，并回答如下问题：
* 你的 Best-Fit 算法是否有进一步的改进空间？

在完成练习一后，参考kern/mm/default_pmm.c对First Fit算法的实现，编程实现Best Fit页面分配算法，算法的时空复杂度不做要求，能通过测试即可。 请在实验报告中简要说明你的设计实现过程，阐述代码是如何对物理内存进行分配和释放，并回答如下问题：

在Best-Fit代码中，我们基于First Fit的内存分配管理器结构，修改如下几个函数内容（函数作用和其中未改动的代码与练习1一致，重复部分不再赘述）：

```c
static void
best_fit_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));

        /*LAB2 EXERCISE 2: 2114042*/ 
        // 清空当前页框的标志和属性信息，并将页框的引用计数设置为0
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
             /*LAB2 EXERCISE 2: 2114042*/ 
            // 编写代码
            // 1、当base < page时，找到第一个大于base的页，将base插入到它前面，并退出循环
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } 
            // 2、当list_next(le) == &free_list时，若已经到达链表结尾，将base插入到链表尾部
            else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
                }
        }
    }
}
```

和First Fit相同，Best Fit同样需要初始化一块连续的内存页，并将它们加入到空闲页链表中。在初始化部分，在确保其被保留的前提下（assert(PageReserved(p))），将清空当前页框的标志和属性信息，并将页框的引用计数设置为0。在构建空闲页链表的时候，同样按照从小到大的顺序，将页面插到第一个大于它的页，或者插入到队尾。该部分函数和First Fit是一致的。


```c
static struct Page *
best_fit_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    size_t min_size = nr_free + 1;
     /*LAB2 EXERCISE 2: 2114042*/ 
    // 下面的代码是first-fit的部分代码，请修改下面的代码改为best-fit
    // 遍历空闲链表，查找满足需求的空闲页框
    // 如果找到满足需求的页面，记录该页面以及当前找到的最小连续空闲页框数量
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n && p->property < min_size) {
            // 更新找到的最小连续空闲页框数量
            page = p;
            min_size = p->property;
        }
    }

    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}
```
First Fit只需要找到满足所需大小的**第一个**空闲块，而Best Fit需要遍历整个空闲链表，找到满足所需大小的**最小的**空闲块，这里我们需要初始化一个变量 min_size，表示当前找到的最小连续空闲页框数量。将其初始化为 nr_free + 1，以确保第一个找到的满足需求的页面会成为当前最小值。

接下来遍历检查当前页面是否满足需求，并且其连续的空闲页框数量是否小于当前最小值 min_size。如果满足条件，更新 page 为当前找到的页面，并更新 min_size 为当前页面的连续空闲页框数量。通过这个方式，我们成功找到了“Best Fit”，即满足所需大小的最小空闲块。



```c
static void
best_fit_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    /*LAB2 EXERCISE 2: 2114042*/ 

    /* 设置当前页块的属性为释放的页块数，
       将当前页块标记为已分配状态，最后增加nr_free的值 */
    base->property = n;
    SetPageProperty(base);
    nr_free += n;

    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }

    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        /*LAB2 EXERCISE 2: 2114042*/ 
         // 编写代码
        // 1、判断前面的空闲页块是否与当前页块是连续的，如果是连续的，则将当前页块合并到前面的空闲页块中
        // 2、首先更新前一个空闲页块的大小，加上当前页块的大小
        // 3、清除当前页块的属性标记，表示不再是空闲页块
        // 4、从链表中删除当前页块
        // 5、将指针指向前一个空闲页块，以便继续检查合并后的连续空闲页块
        if (p + p->property == base) {
            /* 合并当前页块到前面的空闲页块中 */
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p; // 指向合并后的空闲页块
        }        
    }

    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}

```
这段代码的主要作用是释放一组内存页，将它们加入到空闲页链表中，并尝试将相邻的空闲页块合并，以最大程度地减少碎片化的内存。在释放一组内存页后，我们不仅要重新设置标记和引用计数，同时需要设置当前页块的属性为释放的页块数，将当前页块标记为已分配状态，最后增加 nr_free 的值（编写代码部分）。

接下来，依据空链表是否存在，按情况插入或创建空链表。然后我们需要尝试将相邻的空闲页块合并，插入后如果前一个空闲页块与当前页块相邻，将它们按下面步骤合并：更新前一个空闲页块的大小，加上当前页块的大小；清除当前页块的属性标记；从链表中删除当前页块；将指针指向前一个空闲页块，以便继续检查合并后的连续空闲页块。我们可以用同样的方式对后一个空闲页块进行相同操作。

* 你的 Best-Fit 算法是否有进一步的改进空间？

### 1. 内存搜索

在内存管理中，通过选择高效的数据结构如平衡树或十字链表来维护空闲页块的列表，可以显著降低查找合适页块的时间复杂度。这样的优化方式能够使系统在大规模内存管理时保持高效性，尤其在频繁的内存分配和释放操作中表现出色。

### 2. 延迟合并

参考数据库中bufferpool机制，考虑引入延迟合并，可以减少频繁释放内存时的性能开销。定时任务或统计阈值机制可用于在适当时机才执行合并操作，而不是每次释放时立即合并。这种优化方式适用于高负载场景下，能有效提高内存管理的整体性能。

### 3. 内存分块管理

将内存的占用划分为更加合适块，减少碎片空间浪费的同时可以提高内存分配效率，可以参考下面伙伴系统的实现。

### 4. 缓存机制

通过实现对象池或使用SLAB分配器等方式，可以有效地提高频繁分配和释放小块内存的性能。这种优化方式能够针对特定的内存分配模式，将分配的内存缓存起来，以避免频繁的内存分配和释放操作，从而提升系统的整体性能。



#### 扩展练习Challenge：buddy system（伙伴系统）分配算法（需要编程）
Buddy System算法把系统中的可用存储空间划分为存储块(Block)来进行管理, 每个存储块的大小必须是2的n次幂(Pow(2, n)), 即1, 2, 4, 8, 16, 32, 64, 128...

基本设计：
1. **数据结构**（参考直接来源于 [伙伴分配器的一个极简实现 by 我的上铺叫路遥酷壳 – CoolShell.cn](http://coolshell.cn/articles/10427.html) ）
   - 为了实现二分操作，使用完全二叉树的思想进行数据块大小组织。按照基本的参考使用一个数组形式的完全二叉树来监控管理内存。二叉树的节点用于标记相应内存块的使用状态，高层节点对应大的块，低层节点对应小的块，在分配和释放中我们就通过这些节点的标记属性来进行块的分离合并。对于2的n次方大小的数据块，使用深度为n+1的完全二叉树管理每一阶的内存。  
   - 结构体中，size代表可分配的总内存大小。longest数组记录了节点所对应的的内存块大小。

2. **分配操作**
   - alloc函数首先将size调整到2的幂大小，并检查是否超过最大限度。然后进行适配搜索，深度优先遍历，当找到对应节点后，将其longest标记为0，即分离适配的块出来，并转换为内存块索引offset返回。
   - 需要在对找到节点设0后，对父节点及以上的所有结点进行更新。如果左右两结点均为0则父节点也设为0，即全部被占用。
3. **释放和检测分配情况的函数**
   - 释放是分配函数的反向操作，需要传入之前已经分配的内存索引。
   - 检测分配情况的函数使我们可以看到当前已分配的内存情况，并用*和_分别代表占用和未占用状态，在命令行中打印出来。



```c
#define MAX_ORDER 20

extern const struct pmm_manager buddy_pmm_manager;

typedef struct
{
    unsigned int max_order;             //最高阶
    list_entry_t free_array[MAX_ORDER + 1]; //空闲块链表
    unsigned int nr_free;               //空闲页的数量
} free_buddy_t;

```
仿照先前代码，将新的pmm_manager管理器定义为buddy_pmm_manager，按照c++中设计类的思维方式，定义一个结构体free_buddy_t，其用来管理伙伴系统的内存分配。

```c
#include <buddy.h>
#include <list.h>
#include <string.h>
#include <pmm.h>

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
```
设定辅助函数，用于计算有关2的次方，对free_array（buddy.h中结构体的实例）进行初始化操作。

```c

// 初始化内存映射
static void buddy_init_memmap(struct Page *base, size_t n)
{
    assert(n > 0);
    size_t pn = ceil_pow2(n); // 实际管理的页数，向上取最近的2的幂次方
    max_order = log2(pn);      // 对应阶数

    for (struct Page *p = base; p != base + pn; ++p)
    {
        assert(PageReserved(p));
        p->flags = 0;       // 重置状态标志
        p->property = 0;   // 当前头页管理的页数的阶数
        set_page_ref(p, 0); // 重置引用计数
    }

    nr_free = pn;
    base->property = max_order;
    SetPageProperty(base);  // base 设置为头页
    list_add(&(free_array[max_order]), &(base->page_link));  // 加入链表
}
```
初始化内存映射，根据传入的页数 n，初始化从 base 开始的 pn 个页的内存映射信息，包括重置状态、属性和引用计数，并将它们加入相应阶数的空闲块链表中。这里指的注意的是我们使用了Page中的property来代表当前页数的阶数。

```c
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
```

buddy_split 函数用于从阶数为 order 的空闲块中分裂出一个页。函数首先确保order的合法性，然后检查当前阶的空闲块链表是否为空。如果为空，就递归调用buddy_split以尝试在更高阶找到可分裂的块，分裂时会从空闲块链表中取出一个块，将其一分为二，并将右侧块设为头页，然后将左侧块添加到较低阶的空闲块链表中，最终连接左右两块。

buddy_alloc_pages 函数用于分配 n 个页。它会尝试找到合适的空闲块，如果找不到就会进行分裂以获得足够的页，然后将分配的页返回。具体上来说，首先，程序确保n是一个正整数，并检查是否有足够的空闲页可以分配。然后，它计算实际需要分配的页数并确定所需的阶数，如果对应阶的空闲块链表为空，就调用buddy_split函数尝试从更高阶找到可分裂的块。接着，它从当前order的空闲块链表中取出下一个块，将其视为要分配的页并将这个页从空闲块链表中移除，清除该页的属性，更新空闲页的数量。最后，返回已分配的页。如果无法分配足够的页，就返回NULL。

```c
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
```
get_buddy() 函数函数用于找到一个内存页的伙伴页，通过对当前页的索引进行异或运算，计算出伙伴页的索引。

buddy_free_pages() 函数用于释放一组内存页，首先确保释放的页数大于 0，然后将基准页添加到相应阶数的空闲块链表中。伙伴合并循环。这个循环中，如果相邻的块可以合并，则将它们合并成一个更大的块，以减少内存碎片，同时更新可用内存页数量。
在验证部分，我们可以将

```c
static void init_pmm_manager(void) {
    pmm_manager = &best_fit_pmm_manager;
    cprintf("memory management: %s\n", pmm_manager->name);
    pmm_manager->init();
}
```
我们在 pmm.c 中将 pmm_manager 改为 buddy_pmm_manager，并 make grade 进行测试，试验验证成功。

#### 扩展练习Challenge：硬件的可用物理内存范围的获取方法（思考题）
* 如果 OS 无法提前知道当前硬件的可用物理内存范围，请问你有何办法让 OS 获取可用物理内存范围？

可以使用BIOS/UEFI 接口来获取可用物理内存范围。其中，BIOS（Basic Input/Output System）和 UEFI（Unified Extensible Firmware Interface）是计算机引导过程的关键组件，它们提供了访问硬件信息的接口。在这两个接口中，获取可用物理内存范围的方法通常如下：
* 传统的 BIOS 接口提供了调用BIOS中断的0x15，它允许操作系统获取有关系统硬件配置的信息，包括内存范围，通常用于基于传统 BIOS 的计算机。操作系统可以使用中断ox15的子功能,如0xe820、0xe801和0xe88来查询内存信息，然后 BIOS 会返回一个内存映射表，其中包含有关内存块的详细信息。

* 在 UEFI 系统中，可以使用 UEFI 变量来存储和检索有关系统硬件配置的信息。特定的 UEFI 变量可能包含了有关可用物理内存范围的数据。操作系统可以通过调用 UEFI Boot Services 或 UEFI Runtime Services 来读取这些变量。

### 二、实验中OS相关的知识点
#### 1.最先匹配(First Fit)算法：
该算法原理为：若想分配n个Page，则按分区的先后次序，从头查找，分配遇到的第一个可用并且页数目比n大的空闲块。 
First Fit分配和释放的时间性能较好，较大的空闲分区可以被保留在内存高端。但随着低端分区不断划分而产生较多小分区，每次分配时查找时间开销会增大

#### 2.最佳匹配(Best Fit)算法：
该算法原理为：当需要分配一个大小为n的内存块时，最佳匹配算法会在所有可用的空闲块中查找并选择一个最小但足够大以容纳n个页面的空闲块。
Best Fit算法会更精确地选择块，因此该算法通常能够更好地维护大型连续内存块，而且Best Fit有助于减少内存碎片，从而减少未被利用的内存空间。

#### 3.页、页表和多级页表机制：

1. **页 (Page)**
页是一种用于管理物理内存和虚拟内存的关键数据单元。它们通常是固定大小的块，例如4KB、8KB等，具体大小取决于操作系统和硬件架构的设定。这些页的引入旨在满足使物理内存管理更高效、支持虚拟内存技术等多个重要需求，同时提高系统性能和灵活性。

2. **页表 (Page Table)**
页表是一个数据结构，用于存储虚拟页和物理页之间的映射关系。当程序访问一个虚拟地址时，操作系统和硬件会使用页表来查找对应的物理地址。页表通常存储在物理内存中，并由特定的硬件机制（如MMU，Memory Management Unit）进行管理和查找。

3. **多级页表 (Multi-level Page Table)**
由于现代计算机的内存容量非常大，单一的页表可能会非常庞大，从而占用大量的物理内存。为了解决这个问题，引入了多级页表机制。
多级页表是一种用于虚拟内存管理的数据结构，在多级页表中，虚拟地址通常被分为多个级别，它包含指向其他页表的指针，而这些子页表再指向更多的页表。
通过这样的层次结构可以有效减小整个页表的大小，减少内存开销，并使操作系统能够管理大型虚拟地址空间。当一个虚拟地址被访问时，操作系统会按需加载相应的页表级别，直到找到物理页的映射。

当涉及到虚拟内存管理，页、页表和多级页表是现代计算机系统中的关键组件。这些机制允许应用程序以一种虚拟的方式访问比实际物理内存更大的内存空间，同时协助操作系统更高效地管理物理内存资源。
