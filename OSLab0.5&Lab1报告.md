# 操作系统Lab0.5 & Lab1实验报告
#### By 叶潇晗（2112120）, 张振铭（2112189），林子淳（2114042）
### 一、实验练习

#### (Lab0.5) 练习1: 使用GDB验证启动流程
使用gdb调试QEMU模拟的RISC-V计算机加电开始运行到执行应用程序的第一条指令（即跳转到0x80200000）这个阶段的执行过程，说明RISC-V硬件加电后的几条指令在哪里？完成了哪些功能？

在输入指令make debug以及make gdb之后，该RISC-V计算机开始上电并使用gdb进行调试。此时立刻输入指令x/5i $pc 来显示即将执行的5条汇编指令，这一过程结果如下：
    
    (gdb) x/5i $pc
    0x1000      auipc   t0,0x0
    0x1004      addi    a1,t0,32
    0x1008      csrr    a0,mhartid
    0x100c      ld      t0,24(t0)
    0x1010      jr      t0
其中现在PC所指的地址为0x1000，该地址为复位地址。接下来将执行的指令在这里，暂时不是0x80000000. 关于0x1000这一地址，我们查看qemu源代码。

在qemu-4.1.1/target/riscv/cpu.c当中查看如下代码：

    static void set_resetvec(CPURISCVState *env, int resetvec)
    {
    #ifndef CONFIG_USER_ONLY
        env->resetvec = resetvec;
    #endif
    }

    static void riscv_any_cpu_init(Object *obj)
    {
        // ... 略去部分代码
        set_resetvec(env, DEFAULT_RSTVEC);
    }

可以看到这段代码将env的成员变量resetvec赋值为传入的参数DEFAULT_RSTVEC，而关于这一数据查看qemu-4.1.1/target/riscv/cpu_bits.h当中的如下代码：

    /* Default Reset Vector adress */
    #define DEFAULT_RSTVEC      0x1000
可见DEFAULT_RSTVEC被宏定义为0x1000.那么我们现在可以得知，为什么RISC-V计算机加电开始运行的第一条指令的地址为0x1000了。而且在RISC-V当中，复位地址是允许自主选择的。

auipc t0,0x0指令以低 12 位补 0，高 20 位是立即数0x0的方式形成 32 位偏移量，然后和 PC 的值0x1000相加，最后把结果保存在寄存器 t0。
指令addi    a1,t0,32就是简单的加法操作，不作过多赘述。
csrr指令意思是 "CSR Read" ，用于从一个特殊的CSR（控制状态寄存器，Control and Status Register）mhartid中读取当前Hart（硬件线程）的ID，并把读取到的数据存放在寄存器 a0 中，以便在程序中进一步使用或显示。因为并不能直接使用CSR中的数据，所以需要使用csrr指令。
然后逐步执行指令到0x100c，ld t0,24(t0)指令将地址为0x1018 ($t0 + 24 = 0x1000 + 0x18 = 0x1018)处所存储的数据取出，并赋值给寄存器t0。而且使用命令：x/1xw 0x1018,我们观察地址0x1018处的数据，观察到如下结果：

    (gdb) x/1xw 0x1018
    0x1018:	0x80000000
可见，此时t0的值被赋为0x80000000。那么接下来使用跳转指令jr t0，就可以跳转到0x800000000地址处执行接下来的指令。
接下来使用命令break *0x80200000来在 0x80200000 处设置断点。然后输入指令continue运行到此处，发现如下结果：

    (gdb) c
    Continuing.

    Breakpoint 1, kern_entry () at kern/init/entry.S:7
    7	    la sp, bootstacktop

而且在先前输入make debug的窗口出现了OpenSBI的图形化界面。那么接下来就执行到指令tail kern_init，进入kern_init函数,其相关代码如下：

    int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);

    const char *message = "(NKU.CST) os is loading ...\n";
    cprintf("%s\n\n", message);
    while (1)
        ;
    }
    
在kern_init函数内使用指令n，逐行执行但不进入被调的函数一步步执行。最后执行到cprintf函数后，OpenSBI的图形化界面下方输出字符串“(NKU.CST) os is loading ...”，然后进入死循环。本实验至此结束。

<!-- ![本地路径](.\\Lab_Picture\\lab0.5-1.png) -->



#### (Lab1) 练习1：理解内核启动中的程序入口操作
阅读 kern/init/entry.S内容代码，结合操作系统内核启动流程，说明指令 la sp, bootstacktop 完成了什么操作，目的是什么？ tail kern_init 完成了什么操作，目的是什么？   

**对于指令la sp, bootstacktop的理解：**
首先看la 指令，它的意思是 "Load Address"，即用于加载一个地址到寄存器中。sp表示“Stack Pointer”,也就是栈指针的意思，它是一个特殊的寄存器。而la可以加载的地址不仅可以是全局变量、数组、字符串、函数等的地址，还可以用于计算某个标签或符号的地址，就比如说被声明为全局符号的bootstacktop，它表示内核栈顶。
因此这段指令的目的就是让栈指针指向内核栈的顶部，跟踪内核栈，之后内核栈将要从高地址向低地址增长,方便之后执行内核初始化的操作。


**对于指令tail kern_init的理解：**
tail指令用于跳转到指定的目标地址，不过它执行的是一个尾调用，它会在跳转之前清理当前函数的栈帧，然后再跳转到目标地址，这样就只有kern_init内核入口点函数的栈帧。
这样做的目的首先当然是调用函数kern_init，不过使用tail进行调用的目的是节省栈帧空间，避免更多的分配与清理栈帧的操作。

#### (Lab1) 练习2：完善中断处理 
请编程完善trap.c中的中断处理函数trap，在对时钟中断进行处理的部分填写kern/trap/trap.c函数中处理时钟中断的部分，使操作系统每遇到100次时钟中断后，调用print_ticks子程序，向屏幕上打印一行文字”100 ticks”，在打印完10行后调用sbi.h中的shut_down()函数关机。

        case IRQ_S_TIMER:
            clock_set_next_event();
            if (++ticks % TICK_NUM == 0) 
            {
                print_ticks();
	    	    num++;
            }            
            if (num == 10) 
                sbi_shutdown();
            break;

interrupt_handler作为中断处理函数，接受一个指向中断帧（trapframe）结构的指针，其包含了tf->cause的中断原因码，在我们截断最高位后，让cause进行swich匹配，这里我们对时钟中断部分的代码进行完善。

具体代码实现上，clock_set_next_event()由clock.c中定义，其通过时钟基准sbi_timebase() / 500以及时钟周期get_cycles()相加确定；TICK_NUM预先宏定义为100，num在全局中已初始化为10，而ticks则是在clock.c中被初始化为0，print_ticks()也是预先定义的cprint语句，sbi_shutdown()是RISC-V 架构中用于提供的操作系统接口，其为关机操作。

#### (Lab1) 扩展练习 Challenge1：描述与理解中断流程
回答：描述ucore中处理中断异常的流程（从异常的产生开始），其中mov a0，sp的目的是什么？SAVE_ALL中寄存器保存在栈中的位置是什么确定的？对于任何中断，__alltraps 中都需要保存所有寄存器吗？请说明理由。

**中断处理流程描述：**
1. 中断的产生：如果在执行一条指令的过程中发生了错误，那么此时我们通过中断来处理错误，此时中断为**异常**。也包括 CPU 的执行过程被外设发来的信号打断的**外部中断**，以及我们主动通过一条指令停下来，并跳转到中断处理函数的**陷入**。以上这些情况都可能是中断产生的原因。
2. 保存上下文：在发生中断时，当前任务的上下文（包括通用寄存器、特殊寄存器和程序计数器等）均需要被保存在内存当中。这确保了在中断处理期间，不会丢失当前进程的重要状态信息，在中断处理完毕恢复之后可以正常运行该进程。
3. 获取中断信息：在保存上下文后，获取关于中断的信息，例如：  
    ```
    csrr s1, sstatus    # 获取当前程序的状态。
    csrr s2, sepc    # 获取更新PC前的PC值，即触发中断的那条指令的地址
    csrr s4, scause  # 获取中断的原因
    ```
    获得这些信息之后，它们会被保存在栈中。这些操作会对中断处理后续的流程有所指示，帮助更好地完成中断处理工作。
4. 跳转并调用中断处理程序：在保存完必要的进程状态信息与异常信息之后，kernel就会调用中断处理函数trap(位于trap.C中)并基于之前的信息，通过stvec，即”中断向量表基址”把不同种类的中断映射到对应的中断处理程序，以不同的方式来处理不同类别的中断。
5. 恢复上下文：在执行完trap程序之后，以相比于存储时相反的顺序，将之前存储的寄存器内的数据从内存中加载以进行恢复。
6. 返回中断：通过RESTORE_ALL恢复上下文之后，再通过内核态的特权指令sret从内核态返回到用户态，恢复用户程序的执行状态，从用户程序中断点处继续执行。




**mov a0, sp的目的**
mov a0, sp 的目的是将当前栈指针 sp 的值保存到寄存器 a0 中。这样做的原因是，在处理中断之前，通常需要将当前的栈指针保存下来，以便在处理中断后能够正确恢复栈指针。
在以下代码中：

    move  a0, sp
    jal trap
    # sp should be the same as before "jal trap"

在跳转到中断处理程序 trap 之前，必须保存现在的栈指针值，这样在恢复之后才能知道正常接下来应该执行的操作与地址。

**SAVE_ALL中寄存器保存在栈中位置的确定：**
这些位置是通过 REGBYTES 的偏移量相乘来计算的。每个寄存器占据 REGBYTES 字节的空间。例如，x1 寄存器的值存储在地址值为1*REGBYTES + $sp 的地方，这可以看作是将数据存储到栈中向高地址方向的第2个位置。那么只要知晓为寄存器分配栈空间之前栈指针的值就可以借此确定每个寄存器数据所存储的位置。


**对于__alltraps 在中断时保存寄存器的理解：**
__alltraps并不是对于任何中断均保存全部寄存器的。

例如在该__alltraps中就没有保存stval这一个CSR，原因在于stval存储内容较多且冗余了，如指令获取(instruction fetch)、访存、缺页异常等内容。它会把发生问题的目标地址或者出错的指令记录下来，而目标地址只需要通过sepc存储的中断地址即可得到，中断的指令值通过访存指令就可以得到。只有在缺页异常时需要更详细的内容。所以在没有缺页异常等情况下不会存储stval。

对于stvec寄存器，它的作用就是把不同种类的中断映射到对应的中断处理程序。而观察__alltraps代码可以发现，在SAVE_ALL之后跳转到trap.c当中的trap函数来处理中断，而trap函数当中调用的两个函数interrupt_handler(tf)和exception_handler(tf)，它们当中均有switch case语句来对中断类型做出判断，然后执行相应的操作。因此不需要再额外存储用于映射到对应的中断处理程序的寄存器了。

#### (Lab1) 扩展练习 Challenge2：理解上下文切换机制
回答：在trapentry.S中汇编代码 csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么？save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那这样store的意义何在呢？

**对于汇编语句csrw sscratch, sp；csrrw s0, sscratch, x0的理解**

csrw sscratch, sp是将当前的栈指针（sp 寄存器的值）保存到CSR寄存器sscratch中。而csrrw s0, sscratch, x0是将 sscratch 寄存器的当前值读取到 s0 寄存器中，并将 sscratch 寄存器的值设置为寄存器x0的值，又因为 x0 寄存器通常用于存储零值，故此操作将sscratch置0。

这样的目的是是为了应对一种特殊情况下的处理。由于sscratch置0表明系统处于内核态，那么如果在内核执行的过程中发生了另一个异常或中断，也就是嵌套的异常或中断时，处理器会使用 sscratch 寄存器中的0值来标识这个异常或中断是从内核代码内部触发的，而不是来自用户程序或其他源，对于操作系统和内核开发中的异常处理有重要作用。


**对于SAVE_ALL保存了某些CSR，而RESTORE_ALL不还原它们的理解：**

观察经过整理的汇编代码：

    # SAVE_ALL的部分操作
    csrrw s0, sscratch, x0
    STORE s0, 2*REGBYTES(sp)
    csrr s1, sstatus
    csrr s2, sepc
    csrr s3, sbadaddr
    csrr s4, scause

    # RESTORE_ALL的部分操作
    csrw sstatus, s1
    csrw sepc, s2
    LOAD x2, 2*REGBYTES(sp)

不难发现sbadaddr 和 scause 寄存器的值并没有被还原。sbadaddr 寄存器用于存储发生访存异常时的访问地址，而 scause 寄存器用于存储中断或异常的原因码。这些CSR记录了当前任务的一些重要信息，通常在中断处理程序内用于诊断异常，以确定异常的性质。

由于这些寄存器的值通常用于异常处理和错误处理，而且它们的值通常是由硬件自动设置，在正常情况下不需要手动修改或恢复。所以在RESTORE_ALL中不需要恢复它们。

#### (Lab1) 扩展练习 Challenge3：完善异常中断

        case CAUSE_ILLEGAL_INSTRUCTION:
            cprintf("Exception type: Illegal instruction\n");
            cprintf("Illegal instruction caught at 0x%x\n", tf->epc);
            tf->epc += 4; // 跳过引起异常的指令       
            break;
        case CAUSE_BREAKPOINT:    
            cprintf("Exception type: breakpoint\n");
            cprintf("ebreak caught at 0x%x\n", tf->epc);
            tf->epc += 2;
            break;

与练习2相似，该部分位于exception_handler处理异常的函数内，接受一个指向中断帧（trapframe）结构的指针，同样通过tf->cause找到原因。tf->epc表示异常的程序计数器，程序计数器保存了下一条将要执行的指令的地址。这里我们根据原因输出报错信息和地址，最后跳过该条指令，注意在 RISC-V 中，触发断点异常的ebreak 指令长度是 2 字节，而导致非法指令异常的指令长度是 4 字节。

    __asm__ volatile("ebreak"); // 触发断点异常
    
    __asm__ volatile("mret"); // 触发非法指令异常
    
    while (1)
        ;
    
最后，我们在init.c中插入内联汇编指令，以触发异常加以验证。