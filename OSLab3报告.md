# 操作系统Lab3实验报告
#### By 叶潇晗（2112120）, 张振铭（2112189），林子淳（2114042）
## 一、实验练习

### 练习1: 理解基于FIFO的页面替换算法（思考题）
描述FIFO页面置换算法下，一个页面从被换入到被换出的过程中，会经过代码里哪些函数/宏的处理（或者说，需要调用哪些函数/宏）？并用简单的一两句话描述每个函数在过程中做了什么。（至少正确指出10个不同的函数分别做了什么）

**注:接下来函数名之前的数字序号仅作为计数用,不代表函数调用顺序**
#### 1.1 有关页面换入的函数/宏：
**1._fifo_map_swappable函数：**
通过FIFO页面替换算法的设计思想可知，最新分配到内存的页被替换出去的顺序最靠后，那么我们需要将换入的页插入到链式队列的入口端，而_fifo_map_swappable函数正是实现此功能的.该函数调用list_add函数将换入的页page接入双向链表.

**2.assert宏：**
在页添加到FIFO的链式队列之前,使用```assert(entry != NULL && head != NULL);```来保证接下来进行list_add操作的指针一定不能是NULL, 防止出现类似"```NULL->next```"这种访问空指针的操作

**3.list_add函数：**
该函数实际上就是调用list_add_after函数,最终会调用__list_add来对FIFO的链式队列进行插入操作.在页的换入过程当中,会调用list_add函数将新元素插入到链式队列的head指针后面,在本实验当中该位置即为链式队列的入口端(队尾).



**4.swap_in函数:**
函数内部使用alloc_page()宏分配1个页,然后调用swapfs_read()函数(这个函数还会调用更底层的“硬盘”读取函数ide_read_secs)将磁盘中的数据加载到分配出来的页当中.最终,swap_in函数实现了将磁盘当中的页换入到内存的功能.

**5.alloc_page()宏**
该宏定义如下:

    #define alloc_page() alloc_pages(1)
而在alloc_pages里面,会通过语句```pmm_manager->alloc_pages(n)```(这里n一定等于1)来真正分配出来一个页.在页从磁盘换入内存时,通过该宏来存储从磁盘拿回来的数据.

**6.page_insert函数:**
在swap_in函数退出之后,会使用page_insert函数来为从磁盘换入到内存当中的页建立物理地址和虚拟地址的映射.在该函数当中，会设置传入的页（装有磁盘数据的换入页）的ref属性，再通过get_pte函数得到的页表项地址用来对应实际页，并创建新的页表项来与这个页进行对应。

#### 1.2 有关页面换出的函数/宏：
**7._fifo_swap_out_victim函数:**
通过FIFO页面替换算法的设计思想可知，最早分配到内存的页被替换出去的顺序最靠前，那么我们需要将换出的页在出口端弹出，而_fifo_swap_out_victim函数正是实现此功能的.该函数调用list_del函数将需要换出的页移出双向链表.

**8.list_del函数：**
该函数实际上是调用__list_del来对FIFO的链式队列进行删除操作.在页的换出过程当中,会调用list_del函数将链式队列的head指针的前驱元素删除,而根据链表特性这个地方实际上就是链表尾部,该位置即为链式队列的出口端(队首)

**9.swap_out函数:**
函数内部调用swapfs_write()函数(这个函数还会调用更底层的“硬盘”写入函数ide_write_secs)将换出的页的数据写在磁盘当中,再使用free_page(page)宏将这个页释放.最终,swap_out函数实现了将内存当中的页换入到磁盘的功能.

**10.free_page()宏**
该宏定义如下:

    #define free_page(page) free_pages(page, 1)
而在free_pages里面,会通过语句```pmm_manager->free_pages(base, n)```(这里base被传入要被换出的页page,而且n一定等于1)真正释放掉以page为首的连续的1个页的空间.在页从内存换入磁盘时,通过该宏来将页替换算法选到的页释放出内存,为后续新的页的换入腾出空间.


### 练习2: 深入理解不同分页模式的工作原理（思考题）
get_pte()函数（位于kern/mm/pmm.c）用于在页表中查找或创建页表项，从而实现对指定线性地址对应的物理页的访问和映射操作。这在操作系统中的分页机制下，是实现虚拟内存与物理内存之间映射关系非常重要的内容。

* 1.get_pte()函数中有两段形式类似的代码， 结合sv32，sv39，sv48的异同，解释这两段代码为什么如此相像?


* 2.目前get_pte()函数将页表项的查找和页表项的分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？


1、无论sv32、sv39、sv48都使用的是多级页表的机制，需要分级读出虚拟地址并与物理地址进行对应。由于RISCV采用的是sv39，所以使用两段代码是先读出了虚拟地址（VPN）的第一段（偏移30位），之后读出第二段，在第二段之后索引最后的第三段9位地址。这两段代码执行的读取操作是相同的，所以会十分相像。

而由于sv32总共只有二级页表架构，sv48共有四级页表架构，故建立页表项这部分代码在sv32中只需要执行第一段，在sv48中则需再增加一段才可以获取到页表项位置。

同时由于在sv32、sv39、sv48形式下页表项后10位代表意义一样，所以pte创建函数可以通用，创建过程也相同。

2、这种写法是好的，拆开是没有必要的。从反向思维来说，如果拆开可能会出现很多问题。例如在执行get_pte后，不经过页表分配直接选取访问到的页表项会导致访问空页的错误操作。同时在并行情况下，会出现指定一个线程进行页表项查找操作，另一个线程进行分配操作，在查找线程完成执行分配操作线程未完成时时，其他线程（或当前查找线程）进行了页表项的读取，这样也会导致访问空页的错误。而如果合并的话，在执行当前函数后，就已经得到了一个分配好的页表项，可以确保当前返回位置非空且格式正确。


### 练习3：给未被映射的地址映射上物理页（需要编程）

补充完成do_pgfault（mm/vmm.c）函数，给未被映射的地址映射上物理页。设置访问权限 的时候需要参考页面所在 VMA 的权限，同时需要注意映射物理页时需要操作内存控制 结构所指定的页表，而不是内核的页表。请在实验报告中简要说明你的设计实现过程。请回答如下问题：

* 请描述页目录项（Page Directory Entry）和页表项（Page Table Entry）中组成部分对ucore实现页替换算法的潜在用处。
* 如果ucore的缺页服务例程在执行过程中访问内存，出现了页访问异常，请问硬件要做哪些事情？
* 数据结构Page的全局变量（其实是一个数组）的每一项与页表中的页目录项和页表项有无对应关系？如果有，其对应关系是什么？

首先我们先讲解编程部分，在正式开始之前，我们需要先了解`do_pgfault`函数（唯一需要编程的函数）是做什么的。


```C++
int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) 
```

`do_pgfault`函数用于给未被映射的地址映射上物理页。当程序访问"不对应物理内存页帧的虚拟内存地址"时，系统会抛出`Page Fault`异常，接着把Page Fault分发给`kern/mm/vmm.c`的`do_pgfault()`函数并尝试进行页面置换。其接收三个参数：内存管理结构 `mm`、错误代码 `error_code` 和引发页面错误的线性地址 `addr` 。

```C++
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
    pgfault_num++;
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
        goto failed;
    }

    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
        perm |= (PTE_R | PTE_W);
    }
    addr = ROUNDDOWN(addr, PGSIZE);
    ret = -E_NO_MEM;
    pte_t *ptep=NULL;
    ptep = get_pte(mm->pgdir, addr, 1); 
```

代码用ret表示错误的状态，代码先尝试查找 `addr` 的虚拟内存区域`vma`，并将跟踪页面错误数量的全局变量`pgfault_num` 加 1。接着判断是否能找到匹配的 `vma` 或 `addr` 是否超出了有效范围返回该类型报错。

如果前面判断没问题，接下来代码会计算 `perm` 权限，根据 `vma` 的属性判断是否允许写入，并设置相应的权限标志。然后获得页面的起始地址，并初始化ret表示内存分配失败以及ptep来获取页表项的指针。

```C++
    if (*ptep == 0) {
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
            goto failed;
        }
    } else {
        /*LAB3 EXERCISE 3: 2114042*/
        if (swap_init_ok) {
            struct Page *page = NULL;

            swap_in(mm, addr, &page);//分配一个内存页并将磁盘页的内容读入这个内存页
            page_insert(mm->pgdir,page,addr,perm);//建立Page的phy addr与线性addr la的映射
            swap_map_swappable(mm, addr, page, 1);//设置页面可交换
            
            page->pra_vaddr = addr;
        } else {
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
   }
```

如果页表项为0，表示在当前页表中没有相应的映射，此时调用 pgdir_alloc_page 分配一个物理页面。如果分配失败会输出对应错误信息。

如果页表项已经存在，说明物理页不存在于内存中，而在磁盘中。这里我们先检查交换机制是否初始化成功，然后将磁盘中的数据加载到一个内存页中，这里的 page 将保存指向该内存页的指针，然后将内存页与指定的线性地址建立映射关系，将页面标记为可交换，以便在需要时进行页面置换，最后将页面标记为可交换，以便在需要时进行页面置换。如果上述过程失败了，返回对应报错信息。

* 请描述页目录项（Page Directory Entry）和页表项（Page Table Entry）中组成部分对ucore实现页替换算法的潜在用处。

用处在于这两者中的标志位，如 PTE_A（表示内存页是否被访问过）和 PTE_D（表示内存页是否被修改过），为实现增强型时钟算法（Enhanced Clock Algorithm）提供了基础。

在传统的时钟置换算法中，只考虑了页面是否被访问过。然而，在实际应用中，还需要考虑页面是否被修改过。因为修改过的页面需要写回硬盘，其置换代价比未修改过的页面高。因此，优先淘汰未修改过的页面，可以减少磁盘操作次数。

增强型时钟算法除了考虑页面的访问情况外，还需考虑页面的修改情况。它希望淘汰的页面是最近未使用且在主存驻留期间其内容未被修改过的。为实现这一目标，需要为每一页的对应页表项增加一个引用位和一个修改位。当页面被访问时，CPU 中的 MMU 硬件将把引用位置为“1”；当页面被“写”时，将把修改位置为“1”。这样，就有四种可能的组合情况：（0，0）表示最近未被引用且未被修改，首选淘汰；（0，1）最近未被使用但被修改，其次选择；（1，0）最近使用但未修改，再次选择；（1，1）最近使用且修改，最后选择。

这种算法相较于传统的时钟算法，可以进一步减少磁盘 I/O 操作次数。然而，为了找到一个尽可能适合淘汰的页面，可能需要多次扫描，从而增加了算法的执行开销。

* 如果ucore的缺页服务例程在执行过程中访问内存，出现了页访问异常，请问硬件要做哪些事情？

如果出现了页访问异常，CPU将把引起页访问异常的线性地址装到寄存器CR2中，并设置错误代码errorCode说明页访问异常的类型，然后触发 `Page Fault` 异常，进入do_pgdefault函数处理。

* 数据结构Page的全局变量（其实是一个数组）的每一项与页表中的页目录项和页表项有无对应关系？如果有，其对应关系是什么？


```c
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
}

```
物理页面管理中使用了 default init memmap 向内存里分配了一堆连续的 Page 结构体，来管理物理页面可以把它们看作一个结构体数组，extern struct Page *pages 指针是这个数组的起始地址，上面代码表明了它们间的转化方式。更具体来说，本实验中缺页机制所处理和分配的所有页目录项、页表项，都对应于 pages 的一页，但是 pages 中的页并不一定全部被使用。

### 练习4：补充完成Clock页替换算法（需要编程）
通过之前的练习，相信大家对FIFO的页面替换算法有了更深入的了解，现在请在我们给出的框架上，填写代码，实现 Clock页替换算法（mm/swap_clock.c）。(提示:要输出curr_ptr的值才能通过make grade)请在实验报告中简要说明你的设计实现过程。请回答如下问题：
* 比较Clock页替换算法和FIFO算法的不同。

我们先看代码设计部分。

```c
static int
_clock_init_mm(struct mm_struct *mm)
{     
     /*LAB3 EXERCISE 4: 2114042*/ 

     // 初始化pra_list_head为空链表
     list_init(&pra_list_head);
     // 初始化当前指针curr_ptr指向pra_list_head，表示当前页面替换位置为链表头
     curr_ptr = &pra_list_head;
     // 将mm的私有成员指针指向pra_list_head，用于后续的页面替换算法操作
     mm->sm_priv = &pra_list_head;

     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}n 0;
}
```

在初始化部分，我们使用list_init初始化pra_list_head为空链表，然后将curr_ptr指向表头，并将mm的私有成员指针指向pra_list_head。


```c
static int
_clock_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *entry=&(page->pra_page_link);
 
    assert(entry != NULL && curr_ptr != NULL);
    //record the page access situlation
    /*LAB3 EXERCISE 4: 2114042*/ 
    // link the most recent arrival page at the back of the pra_list_head qeueue.
    // 将页面page插入到页面链表pra_list_head的末尾
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    list_add(head->prev, entry);
    // 将页面的visited标志置为1，表示该页面已被访问
    page->visited  = 1;
    return 0;
}
```
函数将 page 对应的链表项 pra_page_link 取出，并将其插入到页面链表pra_list_head 的末尾。这样做的目的是将最近访问的页面放到链表的末尾，以便进行页面的淘汰。接着，将页面的访问标志 visited 置为 1，表示该页面已经被访问过了。

- **_clock_swap_out_victim**

```c
static int
_clock_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
         assert(head != NULL);
     assert(in_tick==0);
    struct Page *curr_page;
    while (1) {
        /*LAB3 EXERCISE 4: 2114042*/ 
        // 编写代码
        // 遍历页面链表pra_list_head，查找最早未被访问的页面
        if (curr_ptr == head){  // 由于是将页面page插入到页面链表pra_list_head的末尾，所以pra_list_head制起标识头部的作用，跳过
            curr_ptr = list_next(curr_ptr);
        }
        // 获取当前页面对应的Page结构指针    

        curr_page = le2page(curr_ptr, pra_page_link);
        // 如果当前页面未被访问，则将该页面从页面链表中删除，并将该页面指针赋值给ptr_page作为换出页面
        if (curr_page->visited != 1){
            *ptr_page = curr_page;
            cprintf("curr_ptr %p\n",curr_ptr);
            list_del(curr_ptr);
            break;
        }
        // 如果当前页面已被访问，则将visited标志置为0，表示该页面已被重新访问
        if (curr_page->visited == 1){
            curr_page->visited = 0;
        }
        curr_ptr = list_next(curr_ptr);
    }
    return 0;
}
```

代码实现了时钟置换算法中选择受害者页面的逻辑。在确保头指针不为空后，代码首先遍历页面链表，找到最早未被访问的页面，并将其作为受害者页面。如果页面未被访问，就将其从链表中移除，并将该页面的指针赋给 ptr_page 以便后续处理。如果页面已被访问，则重置其访问标志，并继续遍历，最终返回0表示操作成功完成。



* 比较 Clock 页替换算法和 FIFO 算法的不同

先进先出 (FIFO) 页替换算法是一种简单的替换策略，它总是淘汰在内存中驻留时间最久的页。这是通过将应用程序调入内存的页按顺序连接成一个队列实现的，队列头指向驻留时间最长的页，队尾指向最近被调入内存的页。当需要淘汰页时，只需从队列头部找到需要淘汰的页。然而，FIFO算法只在应用程序按线性顺序访问地址空间时效果好，对于随机访问的情况效率不高。因为那些经常被访问的页通常在内存中停留时间最长，结果它们因为“老化”而被淘汰出去。此外，FIFO算法可能会出现Belady现象，即在增加物理页帧的情况下，反而导致页访问异常次数增多。

时钟 (Clock) 页替换算法是近似实现LRU算法的一种方法。它将各个页面组织成一个环形链表，类似于钟表的表面。然后使用一个指针（称为当前指针）指向最早调入内存的页面。此外，时钟算法在页表项中设置了一个访问位，用于表示此页是否被访问过。当页面被访问时，CPU的MMU硬件会将访问位置为“1”。当操作系统需要淘汰页面时，它会查询当前指针指向的页面对应的页表项。如果访问位为“0”，则淘汰该页。如果该页被写入过，则还需要将其换出到硬盘上。如果访问位为“1”，则将该页表项的访问位置为“0”，然后继续访问下一个页面。时钟算法近似地体现了LRU的思想，容易实现，开销较小，但需要硬件支持来设置访问位。与FIFO算法相比，时钟算法考虑了页表项表示的页是否被访问过。

#### 练习5：阅读代码和实现手册，理解页表映射方式相关知识（思考题）
如果我们采用“一个大页”的页表映射方式，相比分级页表，有什么好处、优势，有什么坏处、风险？

**“一个大页”方式的好处与优势：**
**1.简化内存管理：** 
单一大页表的映射方式可以极大地简化内存管理，因为它不需要像分级页表那样维护多个级别的页表结构，这可以降低操作系统的复杂性，减少维护多级页表这部分的开销。

**2.快速地址转换：** 
由于只有一个页表级别，地址转换通常更快速，而不像多级页表那样层层转换。这减少了查找页表所需的操作次数，从而访问页的速度也会更快，会提高了访问内存的性能

**3.减少TLB冲突：**  
在采用分散多级页表时，不同的虚拟地址可能映射到不同的TLB项中，这可能导致需要不断替换TLB中的映射，从而增加了TLB失效的可能性。采用单一大页表，虚拟地址范围更大，就会有更多的地址映射到相同的TLB项，减少了TLB冲突的概率，提高了TLB的性能。

**4.更好的内存局部性：**  大页表可以提高内存局部性，因为它们映射了更多连续的物理内存。这意味着如果程序访问了一个页面中的一个地址，很可能会在不久之后访问同一页面内的其他地址，从而减少了内存访问的跳跃，提高了内存访问效率。

**“一个大页”方式的坏处与风险：**
**1.大页表需要的内存过大：** 一个单一大页表需要足够大的内存空间来存储所有的页表项，这意味着在具有大量物理内存和大虚拟地址空间的系统中，大页表会占用大量内存资源。而且，当虚拟地址空间的范围非常大时，大页表也需要相应变大，甚至建立和维护一个单一的大页表可能变得不切实际。

**2.不适用于稀疏地址空间：** 
如果虚拟地址空间中的页分布非常稀疏，使用一个单一大页表可能会导致内存浪费，因为页表项需要分配给未使用的虚拟地址。这会浪费大量内存资源，而多级页表结构可以更好地处理这种稀疏性，只分配页表项给实际使用的虚拟地址。

**3.缺乏分级保护：** 
多级页表结构提供了更细粒度的内存保护和隔离，因为每个级别的页表可以具有不同的权限和保护机制。相比之下，一个单一大页表可能难以提供相同细粒度的控制。这可能增加了系统的安全风险，因为恶意软件或程序的编写错误可能更容易访问或破坏内存区域。在需要更严格的内存隔离和访问控制的系统中，“一个大页”的页表映射方式的安全性更低。
#### 扩展练习Challenge：实现不考虑实现开销和效率的LRU页替换算法（需要编程）

```c
#ifndef __KERN_MM_SWAP_LRU_H__
#define __KERN_MM_SWAP_LRU_H__

#include <swap.h>
extern struct swap_manager swap_manager_lru;

#endif
```
和之前实验类似，我们仿照swap_fifo.c和swap_fifo.h建立新的文件swap_lru.c和swap_lru.h，并将管理器重新命名成swap_manager_lru。（swap_lru.c中同理）

```c
static int
_lru_tick_event(struct mm_struct *mm)
{ 
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    assert(head != NULL);
    list_entry_t *entry = list_next(head);
    while(entry != head) {
        struct Page *page = le2page(entry, pra_page_link);
        pte_t *ptep = get_pte(mm->pgdir, page->pra_vaddr, 0);
        if(*ptep & PTE_A) {
            list_del(entry);
            list_add(head, entry);
            *ptep &= ~PTE_A;
            tlb_invalidate(mm->pgdir, page->pra_vaddr);
        }
        entry = list_prev(head);
    }
    return 0;
}
```

这段代码实现了改进后的LRU页面置换算法的时钟中断处理过程。在时钟中断发生时，它遍历页面链表，检查每个页面的访问位。如果发现某页面最近被访问过，就将其移到链表末尾以保持最新访问的页面在末尾位置，并更新页表项以标记该页面已被访问。最后，使TLB缓存失效以保证下次访问时获取最新的页表项信息，函数返回0表示处理成功。

接下来，我们只需要在每一个时钟周期内都调用一次_lru_tick_event函数，在一个时钟周期内，当一个链表中的页表被访问过时，就会被重新提到链表头（表示最近访问），避免被选中。尽管实验不要求性能，还是要强调一下这么做的开销十分的巨大（每次时钟周期都遍历一次），不推荐使用。