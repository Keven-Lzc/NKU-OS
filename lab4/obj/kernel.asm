
bin/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02092b7          	lui	t0,0xc0209
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	01e31313          	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000c:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200010:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200014:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200018:	03f31313          	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc020001c:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200020:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200024:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200028:	c0209137          	lui	sp,0xc0209

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc020002c:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200030:	03628293          	addi	t0,t0,54 # ffffffffc0200036 <kern_init>
    jr t0
ffffffffc0200034:	8282                	jr	t0

ffffffffc0200036 <kern_init>:
void grade_backtrace(void);

int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200036:	0000a517          	auipc	a0,0xa
ffffffffc020003a:	02a50513          	addi	a0,a0,42 # ffffffffc020a060 <edata>
ffffffffc020003e:	00015617          	auipc	a2,0x15
ffffffffc0200042:	5c260613          	addi	a2,a2,1474 # ffffffffc0215600 <end>
kern_init(void) {
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
kern_init(void) {
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	6b7040ef          	jal	ra,ffffffffc0204f04 <memset>

    cons_init();                // init the console
ffffffffc0200052:	4b4000ef          	jal	ra,ffffffffc0200506 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200056:	00005597          	auipc	a1,0x5
ffffffffc020005a:	f0a58593          	addi	a1,a1,-246 # ffffffffc0204f60 <etext+0x2>
ffffffffc020005e:	00005517          	auipc	a0,0x5
ffffffffc0200062:	f2250513          	addi	a0,a0,-222 # ffffffffc0204f80 <etext+0x22>
ffffffffc0200066:	128000ef          	jal	ra,ffffffffc020018e <cprintf>

    print_kerninfo();
ffffffffc020006a:	16c000ef          	jal	ra,ffffffffc02001d6 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc020006e:	026020ef          	jal	ra,ffffffffc0202094 <pmm_init>

    pic_init();                 // init interrupt controller
ffffffffc0200072:	56c000ef          	jal	ra,ffffffffc02005de <pic_init>
    idt_init();                 // init interrupt descriptor table
ffffffffc0200076:	5dc000ef          	jal	ra,ffffffffc0200652 <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc020007a:	22f030ef          	jal	ra,ffffffffc0203aa8 <vmm_init>
    proc_init();                // init process table
ffffffffc020007e:	692040ef          	jal	ra,ffffffffc0204710 <proc_init>
    
    ide_init();                 // init ide devices
ffffffffc0200082:	4f8000ef          	jal	ra,ffffffffc020057a <ide_init>
    swap_init();                // init swap
ffffffffc0200086:	385020ef          	jal	ra,ffffffffc0202c0a <swap_init>

    clock_init();               // init clock interrupt
ffffffffc020008a:	426000ef          	jal	ra,ffffffffc02004b0 <clock_init>
    intr_enable();              // enable irq interrupt
ffffffffc020008e:	544000ef          	jal	ra,ffffffffc02005d2 <intr_enable>

    cpu_idle();                 // run idle process
ffffffffc0200092:	073040ef          	jal	ra,ffffffffc0204904 <cpu_idle>

ffffffffc0200096 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0200096:	715d                	addi	sp,sp,-80
ffffffffc0200098:	e486                	sd	ra,72(sp)
ffffffffc020009a:	e0a2                	sd	s0,64(sp)
ffffffffc020009c:	fc26                	sd	s1,56(sp)
ffffffffc020009e:	f84a                	sd	s2,48(sp)
ffffffffc02000a0:	f44e                	sd	s3,40(sp)
ffffffffc02000a2:	f052                	sd	s4,32(sp)
ffffffffc02000a4:	ec56                	sd	s5,24(sp)
ffffffffc02000a6:	e85a                	sd	s6,16(sp)
ffffffffc02000a8:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc02000aa:	c901                	beqz	a0,ffffffffc02000ba <readline+0x24>
        cprintf("%s", prompt);
ffffffffc02000ac:	85aa                	mv	a1,a0
ffffffffc02000ae:	00005517          	auipc	a0,0x5
ffffffffc02000b2:	eda50513          	addi	a0,a0,-294 # ffffffffc0204f88 <etext+0x2a>
ffffffffc02000b6:	0d8000ef          	jal	ra,ffffffffc020018e <cprintf>
readline(const char *prompt) {
ffffffffc02000ba:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000bc:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000be:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000c0:	4aa9                	li	s5,10
ffffffffc02000c2:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000c4:	0000ab97          	auipc	s7,0xa
ffffffffc02000c8:	f9cb8b93          	addi	s7,s7,-100 # ffffffffc020a060 <edata>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000cc:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000d0:	0f6000ef          	jal	ra,ffffffffc02001c6 <getchar>
ffffffffc02000d4:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02000d6:	00054b63          	bltz	a0,ffffffffc02000ec <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	00a95b63          	ble	a0,s2,ffffffffc02000f0 <readline+0x5a>
ffffffffc02000de:	029a5463          	ble	s1,s4,ffffffffc0200106 <readline+0x70>
        c = getchar();
ffffffffc02000e2:	0e4000ef          	jal	ra,ffffffffc02001c6 <getchar>
ffffffffc02000e6:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02000e8:	fe0559e3          	bgez	a0,ffffffffc02000da <readline+0x44>
            return NULL;
ffffffffc02000ec:	4501                	li	a0,0
ffffffffc02000ee:	a099                	j	ffffffffc0200134 <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc02000f0:	03341463          	bne	s0,s3,ffffffffc0200118 <readline+0x82>
ffffffffc02000f4:	e8b9                	bnez	s1,ffffffffc020014a <readline+0xb4>
        c = getchar();
ffffffffc02000f6:	0d0000ef          	jal	ra,ffffffffc02001c6 <getchar>
ffffffffc02000fa:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02000fc:	fe0548e3          	bltz	a0,ffffffffc02000ec <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200100:	fea958e3          	ble	a0,s2,ffffffffc02000f0 <readline+0x5a>
ffffffffc0200104:	4481                	li	s1,0
            cputchar(c);
ffffffffc0200106:	8522                	mv	a0,s0
ffffffffc0200108:	0ba000ef          	jal	ra,ffffffffc02001c2 <cputchar>
            buf[i ++] = c;
ffffffffc020010c:	009b87b3          	add	a5,s7,s1
ffffffffc0200110:	00878023          	sb	s0,0(a5)
ffffffffc0200114:	2485                	addiw	s1,s1,1
ffffffffc0200116:	bf6d                	j	ffffffffc02000d0 <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc0200118:	01540463          	beq	s0,s5,ffffffffc0200120 <readline+0x8a>
ffffffffc020011c:	fb641ae3          	bne	s0,s6,ffffffffc02000d0 <readline+0x3a>
            cputchar(c);
ffffffffc0200120:	8522                	mv	a0,s0
ffffffffc0200122:	0a0000ef          	jal	ra,ffffffffc02001c2 <cputchar>
            buf[i] = '\0';
ffffffffc0200126:	0000a517          	auipc	a0,0xa
ffffffffc020012a:	f3a50513          	addi	a0,a0,-198 # ffffffffc020a060 <edata>
ffffffffc020012e:	94aa                	add	s1,s1,a0
ffffffffc0200130:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0200134:	60a6                	ld	ra,72(sp)
ffffffffc0200136:	6406                	ld	s0,64(sp)
ffffffffc0200138:	74e2                	ld	s1,56(sp)
ffffffffc020013a:	7942                	ld	s2,48(sp)
ffffffffc020013c:	79a2                	ld	s3,40(sp)
ffffffffc020013e:	7a02                	ld	s4,32(sp)
ffffffffc0200140:	6ae2                	ld	s5,24(sp)
ffffffffc0200142:	6b42                	ld	s6,16(sp)
ffffffffc0200144:	6ba2                	ld	s7,8(sp)
ffffffffc0200146:	6161                	addi	sp,sp,80
ffffffffc0200148:	8082                	ret
            cputchar(c);
ffffffffc020014a:	4521                	li	a0,8
ffffffffc020014c:	076000ef          	jal	ra,ffffffffc02001c2 <cputchar>
            i --;
ffffffffc0200150:	34fd                	addiw	s1,s1,-1
ffffffffc0200152:	bfbd                	j	ffffffffc02000d0 <readline+0x3a>

ffffffffc0200154 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200154:	1141                	addi	sp,sp,-16
ffffffffc0200156:	e022                	sd	s0,0(sp)
ffffffffc0200158:	e406                	sd	ra,8(sp)
ffffffffc020015a:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020015c:	3ac000ef          	jal	ra,ffffffffc0200508 <cons_putc>
    (*cnt) ++;
ffffffffc0200160:	401c                	lw	a5,0(s0)
}
ffffffffc0200162:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200164:	2785                	addiw	a5,a5,1
ffffffffc0200166:	c01c                	sw	a5,0(s0)
}
ffffffffc0200168:	6402                	ld	s0,0(sp)
ffffffffc020016a:	0141                	addi	sp,sp,16
ffffffffc020016c:	8082                	ret

ffffffffc020016e <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020016e:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200170:	86ae                	mv	a3,a1
ffffffffc0200172:	862a                	mv	a2,a0
ffffffffc0200174:	006c                	addi	a1,sp,12
ffffffffc0200176:	00000517          	auipc	a0,0x0
ffffffffc020017a:	fde50513          	addi	a0,a0,-34 # ffffffffc0200154 <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc020017e:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200180:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200182:	159040ef          	jal	ra,ffffffffc0204ada <vprintfmt>
    return cnt;
}
ffffffffc0200186:	60e2                	ld	ra,24(sp)
ffffffffc0200188:	4532                	lw	a0,12(sp)
ffffffffc020018a:	6105                	addi	sp,sp,32
ffffffffc020018c:	8082                	ret

ffffffffc020018e <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020018e:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200190:	02810313          	addi	t1,sp,40 # ffffffffc0209028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200194:	f42e                	sd	a1,40(sp)
ffffffffc0200196:	f832                	sd	a2,48(sp)
ffffffffc0200198:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020019a:	862a                	mv	a2,a0
ffffffffc020019c:	004c                	addi	a1,sp,4
ffffffffc020019e:	00000517          	auipc	a0,0x0
ffffffffc02001a2:	fb650513          	addi	a0,a0,-74 # ffffffffc0200154 <cputch>
ffffffffc02001a6:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02001a8:	ec06                	sd	ra,24(sp)
ffffffffc02001aa:	e0ba                	sd	a4,64(sp)
ffffffffc02001ac:	e4be                	sd	a5,72(sp)
ffffffffc02001ae:	e8c2                	sd	a6,80(sp)
ffffffffc02001b0:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001b2:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001b4:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02001b6:	125040ef          	jal	ra,ffffffffc0204ada <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001ba:	60e2                	ld	ra,24(sp)
ffffffffc02001bc:	4512                	lw	a0,4(sp)
ffffffffc02001be:	6125                	addi	sp,sp,96
ffffffffc02001c0:	8082                	ret

ffffffffc02001c2 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02001c2:	3460006f          	j	ffffffffc0200508 <cons_putc>

ffffffffc02001c6 <getchar>:
    return cnt;
}

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc02001c6:	1141                	addi	sp,sp,-16
ffffffffc02001c8:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02001ca:	374000ef          	jal	ra,ffffffffc020053e <cons_getc>
ffffffffc02001ce:	dd75                	beqz	a0,ffffffffc02001ca <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc02001d0:	60a2                	ld	ra,8(sp)
ffffffffc02001d2:	0141                	addi	sp,sp,16
ffffffffc02001d4:	8082                	ret

ffffffffc02001d6 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc02001d6:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001d8:	00005517          	auipc	a0,0x5
ffffffffc02001dc:	de850513          	addi	a0,a0,-536 # ffffffffc0204fc0 <etext+0x62>
void print_kerninfo(void) {
ffffffffc02001e0:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001e2:	fadff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc02001e6:	00000597          	auipc	a1,0x0
ffffffffc02001ea:	e5058593          	addi	a1,a1,-432 # ffffffffc0200036 <kern_init>
ffffffffc02001ee:	00005517          	auipc	a0,0x5
ffffffffc02001f2:	df250513          	addi	a0,a0,-526 # ffffffffc0204fe0 <etext+0x82>
ffffffffc02001f6:	f99ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc02001fa:	00005597          	auipc	a1,0x5
ffffffffc02001fe:	d6458593          	addi	a1,a1,-668 # ffffffffc0204f5e <etext>
ffffffffc0200202:	00005517          	auipc	a0,0x5
ffffffffc0200206:	dfe50513          	addi	a0,a0,-514 # ffffffffc0205000 <etext+0xa2>
ffffffffc020020a:	f85ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020020e:	0000a597          	auipc	a1,0xa
ffffffffc0200212:	e5258593          	addi	a1,a1,-430 # ffffffffc020a060 <edata>
ffffffffc0200216:	00005517          	auipc	a0,0x5
ffffffffc020021a:	e0a50513          	addi	a0,a0,-502 # ffffffffc0205020 <etext+0xc2>
ffffffffc020021e:	f71ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200222:	00015597          	auipc	a1,0x15
ffffffffc0200226:	3de58593          	addi	a1,a1,990 # ffffffffc0215600 <end>
ffffffffc020022a:	00005517          	auipc	a0,0x5
ffffffffc020022e:	e1650513          	addi	a0,a0,-490 # ffffffffc0205040 <etext+0xe2>
ffffffffc0200232:	f5dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200236:	00015597          	auipc	a1,0x15
ffffffffc020023a:	7c958593          	addi	a1,a1,1993 # ffffffffc02159ff <end+0x3ff>
ffffffffc020023e:	00000797          	auipc	a5,0x0
ffffffffc0200242:	df878793          	addi	a5,a5,-520 # ffffffffc0200036 <kern_init>
ffffffffc0200246:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020024a:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020024e:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200250:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200254:	95be                	add	a1,a1,a5
ffffffffc0200256:	85a9                	srai	a1,a1,0xa
ffffffffc0200258:	00005517          	auipc	a0,0x5
ffffffffc020025c:	e0850513          	addi	a0,a0,-504 # ffffffffc0205060 <etext+0x102>
}
ffffffffc0200260:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200262:	f2dff06f          	j	ffffffffc020018e <cprintf>

ffffffffc0200266 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc0200266:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc0200268:	00005617          	auipc	a2,0x5
ffffffffc020026c:	d2860613          	addi	a2,a2,-728 # ffffffffc0204f90 <etext+0x32>
ffffffffc0200270:	04d00593          	li	a1,77
ffffffffc0200274:	00005517          	auipc	a0,0x5
ffffffffc0200278:	d3450513          	addi	a0,a0,-716 # ffffffffc0204fa8 <etext+0x4a>
void print_stackframe(void) {
ffffffffc020027c:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020027e:	1d2000ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc0200282 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200282:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200284:	00005617          	auipc	a2,0x5
ffffffffc0200288:	eec60613          	addi	a2,a2,-276 # ffffffffc0205170 <commands+0xe0>
ffffffffc020028c:	00005597          	auipc	a1,0x5
ffffffffc0200290:	f0458593          	addi	a1,a1,-252 # ffffffffc0205190 <commands+0x100>
ffffffffc0200294:	00005517          	auipc	a0,0x5
ffffffffc0200298:	f0450513          	addi	a0,a0,-252 # ffffffffc0205198 <commands+0x108>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020029c:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020029e:	ef1ff0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc02002a2:	00005617          	auipc	a2,0x5
ffffffffc02002a6:	f0660613          	addi	a2,a2,-250 # ffffffffc02051a8 <commands+0x118>
ffffffffc02002aa:	00005597          	auipc	a1,0x5
ffffffffc02002ae:	f2658593          	addi	a1,a1,-218 # ffffffffc02051d0 <commands+0x140>
ffffffffc02002b2:	00005517          	auipc	a0,0x5
ffffffffc02002b6:	ee650513          	addi	a0,a0,-282 # ffffffffc0205198 <commands+0x108>
ffffffffc02002ba:	ed5ff0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc02002be:	00005617          	auipc	a2,0x5
ffffffffc02002c2:	f2260613          	addi	a2,a2,-222 # ffffffffc02051e0 <commands+0x150>
ffffffffc02002c6:	00005597          	auipc	a1,0x5
ffffffffc02002ca:	f3a58593          	addi	a1,a1,-198 # ffffffffc0205200 <commands+0x170>
ffffffffc02002ce:	00005517          	auipc	a0,0x5
ffffffffc02002d2:	eca50513          	addi	a0,a0,-310 # ffffffffc0205198 <commands+0x108>
ffffffffc02002d6:	eb9ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    }
    return 0;
}
ffffffffc02002da:	60a2                	ld	ra,8(sp)
ffffffffc02002dc:	4501                	li	a0,0
ffffffffc02002de:	0141                	addi	sp,sp,16
ffffffffc02002e0:	8082                	ret

ffffffffc02002e2 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e2:	1141                	addi	sp,sp,-16
ffffffffc02002e4:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002e6:	ef1ff0ef          	jal	ra,ffffffffc02001d6 <print_kerninfo>
    return 0;
}
ffffffffc02002ea:	60a2                	ld	ra,8(sp)
ffffffffc02002ec:	4501                	li	a0,0
ffffffffc02002ee:	0141                	addi	sp,sp,16
ffffffffc02002f0:	8082                	ret

ffffffffc02002f2 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002f2:	1141                	addi	sp,sp,-16
ffffffffc02002f4:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002f6:	f71ff0ef          	jal	ra,ffffffffc0200266 <print_stackframe>
    return 0;
}
ffffffffc02002fa:	60a2                	ld	ra,8(sp)
ffffffffc02002fc:	4501                	li	a0,0
ffffffffc02002fe:	0141                	addi	sp,sp,16
ffffffffc0200300:	8082                	ret

ffffffffc0200302 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200302:	7115                	addi	sp,sp,-224
ffffffffc0200304:	e962                	sd	s8,144(sp)
ffffffffc0200306:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200308:	00005517          	auipc	a0,0x5
ffffffffc020030c:	dd050513          	addi	a0,a0,-560 # ffffffffc02050d8 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc0200310:	ed86                	sd	ra,216(sp)
ffffffffc0200312:	e9a2                	sd	s0,208(sp)
ffffffffc0200314:	e5a6                	sd	s1,200(sp)
ffffffffc0200316:	e1ca                	sd	s2,192(sp)
ffffffffc0200318:	fd4e                	sd	s3,184(sp)
ffffffffc020031a:	f952                	sd	s4,176(sp)
ffffffffc020031c:	f556                	sd	s5,168(sp)
ffffffffc020031e:	f15a                	sd	s6,160(sp)
ffffffffc0200320:	ed5e                	sd	s7,152(sp)
ffffffffc0200322:	e566                	sd	s9,136(sp)
ffffffffc0200324:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200326:	e69ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020032a:	00005517          	auipc	a0,0x5
ffffffffc020032e:	dd650513          	addi	a0,a0,-554 # ffffffffc0205100 <commands+0x70>
ffffffffc0200332:	e5dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    if (tf != NULL) {
ffffffffc0200336:	000c0563          	beqz	s8,ffffffffc0200340 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020033a:	8562                	mv	a0,s8
ffffffffc020033c:	4fe000ef          	jal	ra,ffffffffc020083a <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200340:	4501                	li	a0,0
ffffffffc0200342:	4581                	li	a1,0
ffffffffc0200344:	4601                	li	a2,0
ffffffffc0200346:	48a1                	li	a7,8
ffffffffc0200348:	00000073          	ecall
ffffffffc020034c:	00005c97          	auipc	s9,0x5
ffffffffc0200350:	d44c8c93          	addi	s9,s9,-700 # ffffffffc0205090 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200354:	00005997          	auipc	s3,0x5
ffffffffc0200358:	dd498993          	addi	s3,s3,-556 # ffffffffc0205128 <commands+0x98>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020035c:	00005917          	auipc	s2,0x5
ffffffffc0200360:	dd490913          	addi	s2,s2,-556 # ffffffffc0205130 <commands+0xa0>
        if (argc == MAXARGS - 1) {
ffffffffc0200364:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200366:	00005b17          	auipc	s6,0x5
ffffffffc020036a:	dd2b0b13          	addi	s6,s6,-558 # ffffffffc0205138 <commands+0xa8>
    if (argc == 0) {
ffffffffc020036e:	00005a97          	auipc	s5,0x5
ffffffffc0200372:	e22a8a93          	addi	s5,s5,-478 # ffffffffc0205190 <commands+0x100>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200376:	4b8d                	li	s7,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200378:	854e                	mv	a0,s3
ffffffffc020037a:	d1dff0ef          	jal	ra,ffffffffc0200096 <readline>
ffffffffc020037e:	842a                	mv	s0,a0
ffffffffc0200380:	dd65                	beqz	a0,ffffffffc0200378 <kmonitor+0x76>
ffffffffc0200382:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200386:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200388:	c999                	beqz	a1,ffffffffc020039e <kmonitor+0x9c>
ffffffffc020038a:	854a                	mv	a0,s2
ffffffffc020038c:	35b040ef          	jal	ra,ffffffffc0204ee6 <strchr>
ffffffffc0200390:	c925                	beqz	a0,ffffffffc0200400 <kmonitor+0xfe>
            *buf ++ = '\0';
ffffffffc0200392:	00144583          	lbu	a1,1(s0)
ffffffffc0200396:	00040023          	sb	zero,0(s0)
ffffffffc020039a:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020039c:	f5fd                	bnez	a1,ffffffffc020038a <kmonitor+0x88>
    if (argc == 0) {
ffffffffc020039e:	dce9                	beqz	s1,ffffffffc0200378 <kmonitor+0x76>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003a0:	6582                	ld	a1,0(sp)
ffffffffc02003a2:	00005d17          	auipc	s10,0x5
ffffffffc02003a6:	ceed0d13          	addi	s10,s10,-786 # ffffffffc0205090 <commands>
    if (argc == 0) {
ffffffffc02003aa:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003ac:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ae:	0d61                	addi	s10,s10,24
ffffffffc02003b0:	30d040ef          	jal	ra,ffffffffc0204ebc <strcmp>
ffffffffc02003b4:	c919                	beqz	a0,ffffffffc02003ca <kmonitor+0xc8>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003b6:	2405                	addiw	s0,s0,1
ffffffffc02003b8:	09740463          	beq	s0,s7,ffffffffc0200440 <kmonitor+0x13e>
ffffffffc02003bc:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003c0:	6582                	ld	a1,0(sp)
ffffffffc02003c2:	0d61                	addi	s10,s10,24
ffffffffc02003c4:	2f9040ef          	jal	ra,ffffffffc0204ebc <strcmp>
ffffffffc02003c8:	f57d                	bnez	a0,ffffffffc02003b6 <kmonitor+0xb4>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003ca:	00141793          	slli	a5,s0,0x1
ffffffffc02003ce:	97a2                	add	a5,a5,s0
ffffffffc02003d0:	078e                	slli	a5,a5,0x3
ffffffffc02003d2:	97e6                	add	a5,a5,s9
ffffffffc02003d4:	6b9c                	ld	a5,16(a5)
ffffffffc02003d6:	8662                	mv	a2,s8
ffffffffc02003d8:	002c                	addi	a1,sp,8
ffffffffc02003da:	fff4851b          	addiw	a0,s1,-1
ffffffffc02003de:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003e0:	f8055ce3          	bgez	a0,ffffffffc0200378 <kmonitor+0x76>
}
ffffffffc02003e4:	60ee                	ld	ra,216(sp)
ffffffffc02003e6:	644e                	ld	s0,208(sp)
ffffffffc02003e8:	64ae                	ld	s1,200(sp)
ffffffffc02003ea:	690e                	ld	s2,192(sp)
ffffffffc02003ec:	79ea                	ld	s3,184(sp)
ffffffffc02003ee:	7a4a                	ld	s4,176(sp)
ffffffffc02003f0:	7aaa                	ld	s5,168(sp)
ffffffffc02003f2:	7b0a                	ld	s6,160(sp)
ffffffffc02003f4:	6bea                	ld	s7,152(sp)
ffffffffc02003f6:	6c4a                	ld	s8,144(sp)
ffffffffc02003f8:	6caa                	ld	s9,136(sp)
ffffffffc02003fa:	6d0a                	ld	s10,128(sp)
ffffffffc02003fc:	612d                	addi	sp,sp,224
ffffffffc02003fe:	8082                	ret
        if (*buf == '\0') {
ffffffffc0200400:	00044783          	lbu	a5,0(s0)
ffffffffc0200404:	dfc9                	beqz	a5,ffffffffc020039e <kmonitor+0x9c>
        if (argc == MAXARGS - 1) {
ffffffffc0200406:	03448863          	beq	s1,s4,ffffffffc0200436 <kmonitor+0x134>
        argv[argc ++] = buf;
ffffffffc020040a:	00349793          	slli	a5,s1,0x3
ffffffffc020040e:	0118                	addi	a4,sp,128
ffffffffc0200410:	97ba                	add	a5,a5,a4
ffffffffc0200412:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200416:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020041a:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020041c:	e591                	bnez	a1,ffffffffc0200428 <kmonitor+0x126>
ffffffffc020041e:	b749                	j	ffffffffc02003a0 <kmonitor+0x9e>
            buf ++;
ffffffffc0200420:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200422:	00044583          	lbu	a1,0(s0)
ffffffffc0200426:	ddad                	beqz	a1,ffffffffc02003a0 <kmonitor+0x9e>
ffffffffc0200428:	854a                	mv	a0,s2
ffffffffc020042a:	2bd040ef          	jal	ra,ffffffffc0204ee6 <strchr>
ffffffffc020042e:	d96d                	beqz	a0,ffffffffc0200420 <kmonitor+0x11e>
ffffffffc0200430:	00044583          	lbu	a1,0(s0)
ffffffffc0200434:	bf91                	j	ffffffffc0200388 <kmonitor+0x86>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200436:	45c1                	li	a1,16
ffffffffc0200438:	855a                	mv	a0,s6
ffffffffc020043a:	d55ff0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc020043e:	b7f1                	j	ffffffffc020040a <kmonitor+0x108>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200440:	6582                	ld	a1,0(sp)
ffffffffc0200442:	00005517          	auipc	a0,0x5
ffffffffc0200446:	d1650513          	addi	a0,a0,-746 # ffffffffc0205158 <commands+0xc8>
ffffffffc020044a:	d45ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    return 0;
ffffffffc020044e:	b72d                	j	ffffffffc0200378 <kmonitor+0x76>

ffffffffc0200450 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200450:	00015317          	auipc	t1,0x15
ffffffffc0200454:	02030313          	addi	t1,t1,32 # ffffffffc0215470 <is_panic>
ffffffffc0200458:	00032303          	lw	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020045c:	715d                	addi	sp,sp,-80
ffffffffc020045e:	ec06                	sd	ra,24(sp)
ffffffffc0200460:	e822                	sd	s0,16(sp)
ffffffffc0200462:	f436                	sd	a3,40(sp)
ffffffffc0200464:	f83a                	sd	a4,48(sp)
ffffffffc0200466:	fc3e                	sd	a5,56(sp)
ffffffffc0200468:	e0c2                	sd	a6,64(sp)
ffffffffc020046a:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc020046c:	02031c63          	bnez	t1,ffffffffc02004a4 <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200470:	4785                	li	a5,1
ffffffffc0200472:	8432                	mv	s0,a2
ffffffffc0200474:	00015717          	auipc	a4,0x15
ffffffffc0200478:	fef72e23          	sw	a5,-4(a4) # ffffffffc0215470 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020047c:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc020047e:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200480:	85aa                	mv	a1,a0
ffffffffc0200482:	00005517          	auipc	a0,0x5
ffffffffc0200486:	d8e50513          	addi	a0,a0,-626 # ffffffffc0205210 <commands+0x180>
    va_start(ap, fmt);
ffffffffc020048a:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020048c:	d03ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200490:	65a2                	ld	a1,8(sp)
ffffffffc0200492:	8522                	mv	a0,s0
ffffffffc0200494:	cdbff0ef          	jal	ra,ffffffffc020016e <vcprintf>
    cprintf("\n");
ffffffffc0200498:	00006517          	auipc	a0,0x6
ffffffffc020049c:	d0850513          	addi	a0,a0,-760 # ffffffffc02061a0 <default_pmm_manager+0x500>
ffffffffc02004a0:	cefff0ef          	jal	ra,ffffffffc020018e <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02004a4:	134000ef          	jal	ra,ffffffffc02005d8 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004a8:	4501                	li	a0,0
ffffffffc02004aa:	e59ff0ef          	jal	ra,ffffffffc0200302 <kmonitor>
ffffffffc02004ae:	bfed                	j	ffffffffc02004a8 <__panic+0x58>

ffffffffc02004b0 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02004b0:	67e1                	lui	a5,0x18
ffffffffc02004b2:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc02004b6:	00015717          	auipc	a4,0x15
ffffffffc02004ba:	fcf73123          	sd	a5,-62(a4) # ffffffffc0215478 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02004be:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc02004c2:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004c4:	953e                	add	a0,a0,a5
ffffffffc02004c6:	4601                	li	a2,0
ffffffffc02004c8:	4881                	li	a7,0
ffffffffc02004ca:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc02004ce:	02000793          	li	a5,32
ffffffffc02004d2:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc02004d6:	00005517          	auipc	a0,0x5
ffffffffc02004da:	d5a50513          	addi	a0,a0,-678 # ffffffffc0205230 <commands+0x1a0>
    ticks = 0;
ffffffffc02004de:	00015797          	auipc	a5,0x15
ffffffffc02004e2:	fe07b523          	sd	zero,-22(a5) # ffffffffc02154c8 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc02004e6:	ca9ff06f          	j	ffffffffc020018e <cprintf>

ffffffffc02004ea <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02004ea:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004ee:	00015797          	auipc	a5,0x15
ffffffffc02004f2:	f8a78793          	addi	a5,a5,-118 # ffffffffc0215478 <timebase>
ffffffffc02004f6:	639c                	ld	a5,0(a5)
ffffffffc02004f8:	4581                	li	a1,0
ffffffffc02004fa:	4601                	li	a2,0
ffffffffc02004fc:	953e                	add	a0,a0,a5
ffffffffc02004fe:	4881                	li	a7,0
ffffffffc0200500:	00000073          	ecall
ffffffffc0200504:	8082                	ret

ffffffffc0200506 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200506:	8082                	ret

ffffffffc0200508 <cons_putc>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200508:	100027f3          	csrr	a5,sstatus
ffffffffc020050c:	8b89                	andi	a5,a5,2
ffffffffc020050e:	0ff57513          	andi	a0,a0,255
ffffffffc0200512:	e799                	bnez	a5,ffffffffc0200520 <cons_putc+0x18>
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200514:	4581                	li	a1,0
ffffffffc0200516:	4601                	li	a2,0
ffffffffc0200518:	4885                	li	a7,1
ffffffffc020051a:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc020051e:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200520:	1101                	addi	sp,sp,-32
ffffffffc0200522:	ec06                	sd	ra,24(sp)
ffffffffc0200524:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200526:	0b2000ef          	jal	ra,ffffffffc02005d8 <intr_disable>
ffffffffc020052a:	6522                	ld	a0,8(sp)
ffffffffc020052c:	4581                	li	a1,0
ffffffffc020052e:	4601                	li	a2,0
ffffffffc0200530:	4885                	li	a7,1
ffffffffc0200532:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200536:	60e2                	ld	ra,24(sp)
ffffffffc0200538:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020053a:	0980006f          	j	ffffffffc02005d2 <intr_enable>

ffffffffc020053e <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020053e:	100027f3          	csrr	a5,sstatus
ffffffffc0200542:	8b89                	andi	a5,a5,2
ffffffffc0200544:	eb89                	bnez	a5,ffffffffc0200556 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200546:	4501                	li	a0,0
ffffffffc0200548:	4581                	li	a1,0
ffffffffc020054a:	4601                	li	a2,0
ffffffffc020054c:	4889                	li	a7,2
ffffffffc020054e:	00000073          	ecall
ffffffffc0200552:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200554:	8082                	ret
int cons_getc(void) {
ffffffffc0200556:	1101                	addi	sp,sp,-32
ffffffffc0200558:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc020055a:	07e000ef          	jal	ra,ffffffffc02005d8 <intr_disable>
ffffffffc020055e:	4501                	li	a0,0
ffffffffc0200560:	4581                	li	a1,0
ffffffffc0200562:	4601                	li	a2,0
ffffffffc0200564:	4889                	li	a7,2
ffffffffc0200566:	00000073          	ecall
ffffffffc020056a:	2501                	sext.w	a0,a0
ffffffffc020056c:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020056e:	064000ef          	jal	ra,ffffffffc02005d2 <intr_enable>
}
ffffffffc0200572:	60e2                	ld	ra,24(sp)
ffffffffc0200574:	6522                	ld	a0,8(sp)
ffffffffc0200576:	6105                	addi	sp,sp,32
ffffffffc0200578:	8082                	ret

ffffffffc020057a <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc020057a:	8082                	ret

ffffffffc020057c <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc020057c:	00253513          	sltiu	a0,a0,2
ffffffffc0200580:	8082                	ret

ffffffffc0200582 <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc0200582:	03800513          	li	a0,56
ffffffffc0200586:	8082                	ret

ffffffffc0200588 <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200588:	0000a797          	auipc	a5,0xa
ffffffffc020058c:	ed878793          	addi	a5,a5,-296 # ffffffffc020a460 <ide>
ffffffffc0200590:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc0200594:	1141                	addi	sp,sp,-16
ffffffffc0200596:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200598:	95be                	add	a1,a1,a5
ffffffffc020059a:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc020059e:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02005a0:	177040ef          	jal	ra,ffffffffc0204f16 <memcpy>
    return 0;
}
ffffffffc02005a4:	60a2                	ld	ra,8(sp)
ffffffffc02005a6:	4501                	li	a0,0
ffffffffc02005a8:	0141                	addi	sp,sp,16
ffffffffc02005aa:	8082                	ret

ffffffffc02005ac <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
ffffffffc02005ac:	8732                	mv	a4,a2
    int iobase = secno * SECTSIZE;
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02005ae:	0095979b          	slliw	a5,a1,0x9
ffffffffc02005b2:	0000a517          	auipc	a0,0xa
ffffffffc02005b6:	eae50513          	addi	a0,a0,-338 # ffffffffc020a460 <ide>
                   size_t nsecs) {
ffffffffc02005ba:	1141                	addi	sp,sp,-16
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02005bc:	00969613          	slli	a2,a3,0x9
ffffffffc02005c0:	85ba                	mv	a1,a4
ffffffffc02005c2:	953e                	add	a0,a0,a5
                   size_t nsecs) {
ffffffffc02005c4:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02005c6:	151040ef          	jal	ra,ffffffffc0204f16 <memcpy>
    return 0;
}
ffffffffc02005ca:	60a2                	ld	ra,8(sp)
ffffffffc02005cc:	4501                	li	a0,0
ffffffffc02005ce:	0141                	addi	sp,sp,16
ffffffffc02005d0:	8082                	ret

ffffffffc02005d2 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02005d2:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02005d6:	8082                	ret

ffffffffc02005d8 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02005d8:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02005dc:	8082                	ret

ffffffffc02005de <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02005de:	8082                	ret

ffffffffc02005e0 <pgfault_handler>:
    set_csr(sstatus, SSTATUS_SUM);
}

/* trap_in_kernel - test if trap happened in kernel */
bool trap_in_kernel(struct trapframe *tf) {
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02005e0:	10053783          	ld	a5,256(a0)
    cprintf("page falut at 0x%08x: %c/%c\n", tf->badvaddr,
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int pgfault_handler(struct trapframe *tf) {
ffffffffc02005e4:	1141                	addi	sp,sp,-16
ffffffffc02005e6:	e022                	sd	s0,0(sp)
ffffffffc02005e8:	e406                	sd	ra,8(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02005ea:	1007f793          	andi	a5,a5,256
static int pgfault_handler(struct trapframe *tf) {
ffffffffc02005ee:	842a                	mv	s0,a0
    cprintf("page falut at 0x%08x: %c/%c\n", tf->badvaddr,
ffffffffc02005f0:	11053583          	ld	a1,272(a0)
ffffffffc02005f4:	05500613          	li	a2,85
ffffffffc02005f8:	c399                	beqz	a5,ffffffffc02005fe <pgfault_handler+0x1e>
ffffffffc02005fa:	04b00613          	li	a2,75
ffffffffc02005fe:	11843703          	ld	a4,280(s0)
ffffffffc0200602:	47bd                	li	a5,15
ffffffffc0200604:	05700693          	li	a3,87
ffffffffc0200608:	00f70463          	beq	a4,a5,ffffffffc0200610 <pgfault_handler+0x30>
ffffffffc020060c:	05200693          	li	a3,82
ffffffffc0200610:	00005517          	auipc	a0,0x5
ffffffffc0200614:	f1850513          	addi	a0,a0,-232 # ffffffffc0205528 <commands+0x498>
ffffffffc0200618:	b77ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    extern struct mm_struct *check_mm_struct;
    print_pgfault(tf);
    if (check_mm_struct != NULL) {
ffffffffc020061c:	00015797          	auipc	a5,0x15
ffffffffc0200620:	fcc78793          	addi	a5,a5,-52 # ffffffffc02155e8 <check_mm_struct>
ffffffffc0200624:	6388                	ld	a0,0(a5)
ffffffffc0200626:	c911                	beqz	a0,ffffffffc020063a <pgfault_handler+0x5a>
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc0200628:	11043603          	ld	a2,272(s0)
ffffffffc020062c:	11842583          	lw	a1,280(s0)
    }
    panic("unhandled page fault.\n");
}
ffffffffc0200630:	6402                	ld	s0,0(sp)
ffffffffc0200632:	60a2                	ld	ra,8(sp)
ffffffffc0200634:	0141                	addi	sp,sp,16
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc0200636:	1d90306f          	j	ffffffffc020400e <do_pgfault>
    panic("unhandled page fault.\n");
ffffffffc020063a:	00005617          	auipc	a2,0x5
ffffffffc020063e:	f0e60613          	addi	a2,a2,-242 # ffffffffc0205548 <commands+0x4b8>
ffffffffc0200642:	06200593          	li	a1,98
ffffffffc0200646:	00005517          	auipc	a0,0x5
ffffffffc020064a:	f1a50513          	addi	a0,a0,-230 # ffffffffc0205560 <commands+0x4d0>
ffffffffc020064e:	e03ff0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc0200652 <idt_init>:
    write_csr(sscratch, 0);
ffffffffc0200652:	14005073          	csrwi	sscratch,0
    write_csr(stvec, &__alltraps);
ffffffffc0200656:	00000797          	auipc	a5,0x0
ffffffffc020065a:	48e78793          	addi	a5,a5,1166 # ffffffffc0200ae4 <__alltraps>
ffffffffc020065e:	10579073          	csrw	stvec,a5
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200662:	000407b7          	lui	a5,0x40
ffffffffc0200666:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc020066a:	8082                	ret

ffffffffc020066c <print_regs>:
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020066c:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc020066e:	1141                	addi	sp,sp,-16
ffffffffc0200670:	e022                	sd	s0,0(sp)
ffffffffc0200672:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200674:	00005517          	auipc	a0,0x5
ffffffffc0200678:	f0450513          	addi	a0,a0,-252 # ffffffffc0205578 <commands+0x4e8>
void print_regs(struct pushregs *gpr) {
ffffffffc020067c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020067e:	b11ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200682:	640c                	ld	a1,8(s0)
ffffffffc0200684:	00005517          	auipc	a0,0x5
ffffffffc0200688:	f0c50513          	addi	a0,a0,-244 # ffffffffc0205590 <commands+0x500>
ffffffffc020068c:	b03ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200690:	680c                	ld	a1,16(s0)
ffffffffc0200692:	00005517          	auipc	a0,0x5
ffffffffc0200696:	f1650513          	addi	a0,a0,-234 # ffffffffc02055a8 <commands+0x518>
ffffffffc020069a:	af5ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc020069e:	6c0c                	ld	a1,24(s0)
ffffffffc02006a0:	00005517          	auipc	a0,0x5
ffffffffc02006a4:	f2050513          	addi	a0,a0,-224 # ffffffffc02055c0 <commands+0x530>
ffffffffc02006a8:	ae7ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02006ac:	700c                	ld	a1,32(s0)
ffffffffc02006ae:	00005517          	auipc	a0,0x5
ffffffffc02006b2:	f2a50513          	addi	a0,a0,-214 # ffffffffc02055d8 <commands+0x548>
ffffffffc02006b6:	ad9ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02006ba:	740c                	ld	a1,40(s0)
ffffffffc02006bc:	00005517          	auipc	a0,0x5
ffffffffc02006c0:	f3450513          	addi	a0,a0,-204 # ffffffffc02055f0 <commands+0x560>
ffffffffc02006c4:	acbff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02006c8:	780c                	ld	a1,48(s0)
ffffffffc02006ca:	00005517          	auipc	a0,0x5
ffffffffc02006ce:	f3e50513          	addi	a0,a0,-194 # ffffffffc0205608 <commands+0x578>
ffffffffc02006d2:	abdff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02006d6:	7c0c                	ld	a1,56(s0)
ffffffffc02006d8:	00005517          	auipc	a0,0x5
ffffffffc02006dc:	f4850513          	addi	a0,a0,-184 # ffffffffc0205620 <commands+0x590>
ffffffffc02006e0:	aafff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02006e4:	602c                	ld	a1,64(s0)
ffffffffc02006e6:	00005517          	auipc	a0,0x5
ffffffffc02006ea:	f5250513          	addi	a0,a0,-174 # ffffffffc0205638 <commands+0x5a8>
ffffffffc02006ee:	aa1ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02006f2:	642c                	ld	a1,72(s0)
ffffffffc02006f4:	00005517          	auipc	a0,0x5
ffffffffc02006f8:	f5c50513          	addi	a0,a0,-164 # ffffffffc0205650 <commands+0x5c0>
ffffffffc02006fc:	a93ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200700:	682c                	ld	a1,80(s0)
ffffffffc0200702:	00005517          	auipc	a0,0x5
ffffffffc0200706:	f6650513          	addi	a0,a0,-154 # ffffffffc0205668 <commands+0x5d8>
ffffffffc020070a:	a85ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020070e:	6c2c                	ld	a1,88(s0)
ffffffffc0200710:	00005517          	auipc	a0,0x5
ffffffffc0200714:	f7050513          	addi	a0,a0,-144 # ffffffffc0205680 <commands+0x5f0>
ffffffffc0200718:	a77ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020071c:	702c                	ld	a1,96(s0)
ffffffffc020071e:	00005517          	auipc	a0,0x5
ffffffffc0200722:	f7a50513          	addi	a0,a0,-134 # ffffffffc0205698 <commands+0x608>
ffffffffc0200726:	a69ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020072a:	742c                	ld	a1,104(s0)
ffffffffc020072c:	00005517          	auipc	a0,0x5
ffffffffc0200730:	f8450513          	addi	a0,a0,-124 # ffffffffc02056b0 <commands+0x620>
ffffffffc0200734:	a5bff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200738:	782c                	ld	a1,112(s0)
ffffffffc020073a:	00005517          	auipc	a0,0x5
ffffffffc020073e:	f8e50513          	addi	a0,a0,-114 # ffffffffc02056c8 <commands+0x638>
ffffffffc0200742:	a4dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200746:	7c2c                	ld	a1,120(s0)
ffffffffc0200748:	00005517          	auipc	a0,0x5
ffffffffc020074c:	f9850513          	addi	a0,a0,-104 # ffffffffc02056e0 <commands+0x650>
ffffffffc0200750:	a3fff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200754:	604c                	ld	a1,128(s0)
ffffffffc0200756:	00005517          	auipc	a0,0x5
ffffffffc020075a:	fa250513          	addi	a0,a0,-94 # ffffffffc02056f8 <commands+0x668>
ffffffffc020075e:	a31ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200762:	644c                	ld	a1,136(s0)
ffffffffc0200764:	00005517          	auipc	a0,0x5
ffffffffc0200768:	fac50513          	addi	a0,a0,-84 # ffffffffc0205710 <commands+0x680>
ffffffffc020076c:	a23ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200770:	684c                	ld	a1,144(s0)
ffffffffc0200772:	00005517          	auipc	a0,0x5
ffffffffc0200776:	fb650513          	addi	a0,a0,-74 # ffffffffc0205728 <commands+0x698>
ffffffffc020077a:	a15ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020077e:	6c4c                	ld	a1,152(s0)
ffffffffc0200780:	00005517          	auipc	a0,0x5
ffffffffc0200784:	fc050513          	addi	a0,a0,-64 # ffffffffc0205740 <commands+0x6b0>
ffffffffc0200788:	a07ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020078c:	704c                	ld	a1,160(s0)
ffffffffc020078e:	00005517          	auipc	a0,0x5
ffffffffc0200792:	fca50513          	addi	a0,a0,-54 # ffffffffc0205758 <commands+0x6c8>
ffffffffc0200796:	9f9ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc020079a:	744c                	ld	a1,168(s0)
ffffffffc020079c:	00005517          	auipc	a0,0x5
ffffffffc02007a0:	fd450513          	addi	a0,a0,-44 # ffffffffc0205770 <commands+0x6e0>
ffffffffc02007a4:	9ebff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02007a8:	784c                	ld	a1,176(s0)
ffffffffc02007aa:	00005517          	auipc	a0,0x5
ffffffffc02007ae:	fde50513          	addi	a0,a0,-34 # ffffffffc0205788 <commands+0x6f8>
ffffffffc02007b2:	9ddff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02007b6:	7c4c                	ld	a1,184(s0)
ffffffffc02007b8:	00005517          	auipc	a0,0x5
ffffffffc02007bc:	fe850513          	addi	a0,a0,-24 # ffffffffc02057a0 <commands+0x710>
ffffffffc02007c0:	9cfff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02007c4:	606c                	ld	a1,192(s0)
ffffffffc02007c6:	00005517          	auipc	a0,0x5
ffffffffc02007ca:	ff250513          	addi	a0,a0,-14 # ffffffffc02057b8 <commands+0x728>
ffffffffc02007ce:	9c1ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02007d2:	646c                	ld	a1,200(s0)
ffffffffc02007d4:	00005517          	auipc	a0,0x5
ffffffffc02007d8:	ffc50513          	addi	a0,a0,-4 # ffffffffc02057d0 <commands+0x740>
ffffffffc02007dc:	9b3ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02007e0:	686c                	ld	a1,208(s0)
ffffffffc02007e2:	00005517          	auipc	a0,0x5
ffffffffc02007e6:	00650513          	addi	a0,a0,6 # ffffffffc02057e8 <commands+0x758>
ffffffffc02007ea:	9a5ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02007ee:	6c6c                	ld	a1,216(s0)
ffffffffc02007f0:	00005517          	auipc	a0,0x5
ffffffffc02007f4:	01050513          	addi	a0,a0,16 # ffffffffc0205800 <commands+0x770>
ffffffffc02007f8:	997ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02007fc:	706c                	ld	a1,224(s0)
ffffffffc02007fe:	00005517          	auipc	a0,0x5
ffffffffc0200802:	01a50513          	addi	a0,a0,26 # ffffffffc0205818 <commands+0x788>
ffffffffc0200806:	989ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020080a:	746c                	ld	a1,232(s0)
ffffffffc020080c:	00005517          	auipc	a0,0x5
ffffffffc0200810:	02450513          	addi	a0,a0,36 # ffffffffc0205830 <commands+0x7a0>
ffffffffc0200814:	97bff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200818:	786c                	ld	a1,240(s0)
ffffffffc020081a:	00005517          	auipc	a0,0x5
ffffffffc020081e:	02e50513          	addi	a0,a0,46 # ffffffffc0205848 <commands+0x7b8>
ffffffffc0200822:	96dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200826:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200828:	6402                	ld	s0,0(sp)
ffffffffc020082a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020082c:	00005517          	auipc	a0,0x5
ffffffffc0200830:	03450513          	addi	a0,a0,52 # ffffffffc0205860 <commands+0x7d0>
}
ffffffffc0200834:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200836:	959ff06f          	j	ffffffffc020018e <cprintf>

ffffffffc020083a <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc020083a:	1141                	addi	sp,sp,-16
ffffffffc020083c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020083e:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200840:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200842:	00005517          	auipc	a0,0x5
ffffffffc0200846:	03650513          	addi	a0,a0,54 # ffffffffc0205878 <commands+0x7e8>
void print_trapframe(struct trapframe *tf) {
ffffffffc020084a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020084c:	943ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200850:	8522                	mv	a0,s0
ffffffffc0200852:	e1bff0ef          	jal	ra,ffffffffc020066c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200856:	10043583          	ld	a1,256(s0)
ffffffffc020085a:	00005517          	auipc	a0,0x5
ffffffffc020085e:	03650513          	addi	a0,a0,54 # ffffffffc0205890 <commands+0x800>
ffffffffc0200862:	92dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200866:	10843583          	ld	a1,264(s0)
ffffffffc020086a:	00005517          	auipc	a0,0x5
ffffffffc020086e:	03e50513          	addi	a0,a0,62 # ffffffffc02058a8 <commands+0x818>
ffffffffc0200872:	91dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200876:	11043583          	ld	a1,272(s0)
ffffffffc020087a:	00005517          	auipc	a0,0x5
ffffffffc020087e:	04650513          	addi	a0,a0,70 # ffffffffc02058c0 <commands+0x830>
ffffffffc0200882:	90dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200886:	11843583          	ld	a1,280(s0)
}
ffffffffc020088a:	6402                	ld	s0,0(sp)
ffffffffc020088c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020088e:	00005517          	auipc	a0,0x5
ffffffffc0200892:	04a50513          	addi	a0,a0,74 # ffffffffc02058d8 <commands+0x848>
}
ffffffffc0200896:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200898:	8f7ff06f          	j	ffffffffc020018e <cprintf>

ffffffffc020089c <interrupt_handler>:

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc020089c:	11853783          	ld	a5,280(a0)
ffffffffc02008a0:	577d                	li	a4,-1
ffffffffc02008a2:	8305                	srli	a4,a4,0x1
ffffffffc02008a4:	8ff9                	and	a5,a5,a4
    switch (cause) {
ffffffffc02008a6:	472d                	li	a4,11
ffffffffc02008a8:	06f76f63          	bltu	a4,a5,ffffffffc0200926 <interrupt_handler+0x8a>
ffffffffc02008ac:	00005717          	auipc	a4,0x5
ffffffffc02008b0:	9a070713          	addi	a4,a4,-1632 # ffffffffc020524c <commands+0x1bc>
ffffffffc02008b4:	078a                	slli	a5,a5,0x2
ffffffffc02008b6:	97ba                	add	a5,a5,a4
ffffffffc02008b8:	439c                	lw	a5,0(a5)
ffffffffc02008ba:	97ba                	add	a5,a5,a4
ffffffffc02008bc:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02008be:	00005517          	auipc	a0,0x5
ffffffffc02008c2:	c1a50513          	addi	a0,a0,-998 # ffffffffc02054d8 <commands+0x448>
ffffffffc02008c6:	8c9ff06f          	j	ffffffffc020018e <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02008ca:	00005517          	auipc	a0,0x5
ffffffffc02008ce:	bee50513          	addi	a0,a0,-1042 # ffffffffc02054b8 <commands+0x428>
ffffffffc02008d2:	8bdff06f          	j	ffffffffc020018e <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02008d6:	00005517          	auipc	a0,0x5
ffffffffc02008da:	ba250513          	addi	a0,a0,-1118 # ffffffffc0205478 <commands+0x3e8>
ffffffffc02008de:	8b1ff06f          	j	ffffffffc020018e <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc02008e2:	00005517          	auipc	a0,0x5
ffffffffc02008e6:	bb650513          	addi	a0,a0,-1098 # ffffffffc0205498 <commands+0x408>
ffffffffc02008ea:	8a5ff06f          	j	ffffffffc020018e <cprintf>
            break;
        case IRQ_U_EXT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_EXT:
            cprintf("Supervisor external interrupt\n");
ffffffffc02008ee:	00005517          	auipc	a0,0x5
ffffffffc02008f2:	c1a50513          	addi	a0,a0,-998 # ffffffffc0205508 <commands+0x478>
ffffffffc02008f6:	899ff06f          	j	ffffffffc020018e <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02008fa:	1141                	addi	sp,sp,-16
ffffffffc02008fc:	e406                	sd	ra,8(sp)
            clock_set_next_event();
ffffffffc02008fe:	bedff0ef          	jal	ra,ffffffffc02004ea <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc0200902:	00015797          	auipc	a5,0x15
ffffffffc0200906:	bc678793          	addi	a5,a5,-1082 # ffffffffc02154c8 <ticks>
ffffffffc020090a:	639c                	ld	a5,0(a5)
ffffffffc020090c:	06400713          	li	a4,100
ffffffffc0200910:	0785                	addi	a5,a5,1
ffffffffc0200912:	02e7f733          	remu	a4,a5,a4
ffffffffc0200916:	00015697          	auipc	a3,0x15
ffffffffc020091a:	baf6b923          	sd	a5,-1102(a3) # ffffffffc02154c8 <ticks>
ffffffffc020091e:	c711                	beqz	a4,ffffffffc020092a <interrupt_handler+0x8e>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200920:	60a2                	ld	ra,8(sp)
ffffffffc0200922:	0141                	addi	sp,sp,16
ffffffffc0200924:	8082                	ret
            print_trapframe(tf);
ffffffffc0200926:	f15ff06f          	j	ffffffffc020083a <print_trapframe>
}
ffffffffc020092a:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020092c:	06400593          	li	a1,100
ffffffffc0200930:	00005517          	auipc	a0,0x5
ffffffffc0200934:	bc850513          	addi	a0,a0,-1080 # ffffffffc02054f8 <commands+0x468>
}
ffffffffc0200938:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020093a:	855ff06f          	j	ffffffffc020018e <cprintf>

ffffffffc020093e <exception_handler>:

void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc020093e:	11853783          	ld	a5,280(a0)
ffffffffc0200942:	473d                	li	a4,15
ffffffffc0200944:	16f76563          	bltu	a4,a5,ffffffffc0200aae <exception_handler+0x170>
ffffffffc0200948:	00005717          	auipc	a4,0x5
ffffffffc020094c:	93470713          	addi	a4,a4,-1740 # ffffffffc020527c <commands+0x1ec>
ffffffffc0200950:	078a                	slli	a5,a5,0x2
ffffffffc0200952:	97ba                	add	a5,a5,a4
ffffffffc0200954:	439c                	lw	a5,0(a5)
void exception_handler(struct trapframe *tf) {
ffffffffc0200956:	1101                	addi	sp,sp,-32
ffffffffc0200958:	e822                	sd	s0,16(sp)
ffffffffc020095a:	ec06                	sd	ra,24(sp)
ffffffffc020095c:	e426                	sd	s1,8(sp)
    switch (tf->cause) {
ffffffffc020095e:	97ba                	add	a5,a5,a4
ffffffffc0200960:	842a                	mv	s0,a0
ffffffffc0200962:	8782                	jr	a5
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        case CAUSE_STORE_PAGE_FAULT:
            cprintf("Store/AMO page fault\n");
ffffffffc0200964:	00005517          	auipc	a0,0x5
ffffffffc0200968:	afc50513          	addi	a0,a0,-1284 # ffffffffc0205460 <commands+0x3d0>
ffffffffc020096c:	823ff0ef          	jal	ra,ffffffffc020018e <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200970:	8522                	mv	a0,s0
ffffffffc0200972:	c6fff0ef          	jal	ra,ffffffffc02005e0 <pgfault_handler>
ffffffffc0200976:	84aa                	mv	s1,a0
ffffffffc0200978:	12051d63          	bnez	a0,ffffffffc0200ab2 <exception_handler+0x174>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc020097c:	60e2                	ld	ra,24(sp)
ffffffffc020097e:	6442                	ld	s0,16(sp)
ffffffffc0200980:	64a2                	ld	s1,8(sp)
ffffffffc0200982:	6105                	addi	sp,sp,32
ffffffffc0200984:	8082                	ret
            cprintf("Instruction address misaligned\n");
ffffffffc0200986:	00005517          	auipc	a0,0x5
ffffffffc020098a:	93a50513          	addi	a0,a0,-1734 # ffffffffc02052c0 <commands+0x230>
}
ffffffffc020098e:	6442                	ld	s0,16(sp)
ffffffffc0200990:	60e2                	ld	ra,24(sp)
ffffffffc0200992:	64a2                	ld	s1,8(sp)
ffffffffc0200994:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc0200996:	ff8ff06f          	j	ffffffffc020018e <cprintf>
ffffffffc020099a:	00005517          	auipc	a0,0x5
ffffffffc020099e:	94650513          	addi	a0,a0,-1722 # ffffffffc02052e0 <commands+0x250>
ffffffffc02009a2:	b7f5                	j	ffffffffc020098e <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc02009a4:	00005517          	auipc	a0,0x5
ffffffffc02009a8:	95c50513          	addi	a0,a0,-1700 # ffffffffc0205300 <commands+0x270>
ffffffffc02009ac:	b7cd                	j	ffffffffc020098e <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc02009ae:	00005517          	auipc	a0,0x5
ffffffffc02009b2:	96a50513          	addi	a0,a0,-1686 # ffffffffc0205318 <commands+0x288>
ffffffffc02009b6:	bfe1                	j	ffffffffc020098e <exception_handler+0x50>
            cprintf("Load address misaligned\n");
ffffffffc02009b8:	00005517          	auipc	a0,0x5
ffffffffc02009bc:	97050513          	addi	a0,a0,-1680 # ffffffffc0205328 <commands+0x298>
ffffffffc02009c0:	b7f9                	j	ffffffffc020098e <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc02009c2:	00005517          	auipc	a0,0x5
ffffffffc02009c6:	98650513          	addi	a0,a0,-1658 # ffffffffc0205348 <commands+0x2b8>
ffffffffc02009ca:	fc4ff0ef          	jal	ra,ffffffffc020018e <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc02009ce:	8522                	mv	a0,s0
ffffffffc02009d0:	c11ff0ef          	jal	ra,ffffffffc02005e0 <pgfault_handler>
ffffffffc02009d4:	84aa                	mv	s1,a0
ffffffffc02009d6:	d15d                	beqz	a0,ffffffffc020097c <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc02009d8:	8522                	mv	a0,s0
ffffffffc02009da:	e61ff0ef          	jal	ra,ffffffffc020083a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02009de:	86a6                	mv	a3,s1
ffffffffc02009e0:	00005617          	auipc	a2,0x5
ffffffffc02009e4:	98060613          	addi	a2,a2,-1664 # ffffffffc0205360 <commands+0x2d0>
ffffffffc02009e8:	0b300593          	li	a1,179
ffffffffc02009ec:	00005517          	auipc	a0,0x5
ffffffffc02009f0:	b7450513          	addi	a0,a0,-1164 # ffffffffc0205560 <commands+0x4d0>
ffffffffc02009f4:	a5dff0ef          	jal	ra,ffffffffc0200450 <__panic>
            cprintf("AMO address misaligned\n");
ffffffffc02009f8:	00005517          	auipc	a0,0x5
ffffffffc02009fc:	98850513          	addi	a0,a0,-1656 # ffffffffc0205380 <commands+0x2f0>
ffffffffc0200a00:	b779                	j	ffffffffc020098e <exception_handler+0x50>
            cprintf("Store/AMO access fault\n");
ffffffffc0200a02:	00005517          	auipc	a0,0x5
ffffffffc0200a06:	99650513          	addi	a0,a0,-1642 # ffffffffc0205398 <commands+0x308>
ffffffffc0200a0a:	f84ff0ef          	jal	ra,ffffffffc020018e <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200a0e:	8522                	mv	a0,s0
ffffffffc0200a10:	bd1ff0ef          	jal	ra,ffffffffc02005e0 <pgfault_handler>
ffffffffc0200a14:	84aa                	mv	s1,a0
ffffffffc0200a16:	d13d                	beqz	a0,ffffffffc020097c <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc0200a18:	8522                	mv	a0,s0
ffffffffc0200a1a:	e21ff0ef          	jal	ra,ffffffffc020083a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200a1e:	86a6                	mv	a3,s1
ffffffffc0200a20:	00005617          	auipc	a2,0x5
ffffffffc0200a24:	94060613          	addi	a2,a2,-1728 # ffffffffc0205360 <commands+0x2d0>
ffffffffc0200a28:	0bd00593          	li	a1,189
ffffffffc0200a2c:	00005517          	auipc	a0,0x5
ffffffffc0200a30:	b3450513          	addi	a0,a0,-1228 # ffffffffc0205560 <commands+0x4d0>
ffffffffc0200a34:	a1dff0ef          	jal	ra,ffffffffc0200450 <__panic>
            cprintf("Environment call from U-mode\n");
ffffffffc0200a38:	00005517          	auipc	a0,0x5
ffffffffc0200a3c:	97850513          	addi	a0,a0,-1672 # ffffffffc02053b0 <commands+0x320>
ffffffffc0200a40:	b7b9                	j	ffffffffc020098e <exception_handler+0x50>
            cprintf("Environment call from S-mode\n");
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	98e50513          	addi	a0,a0,-1650 # ffffffffc02053d0 <commands+0x340>
ffffffffc0200a4a:	b791                	j	ffffffffc020098e <exception_handler+0x50>
            cprintf("Environment call from H-mode\n");
ffffffffc0200a4c:	00005517          	auipc	a0,0x5
ffffffffc0200a50:	9a450513          	addi	a0,a0,-1628 # ffffffffc02053f0 <commands+0x360>
ffffffffc0200a54:	bf2d                	j	ffffffffc020098e <exception_handler+0x50>
            cprintf("Environment call from M-mode\n");
ffffffffc0200a56:	00005517          	auipc	a0,0x5
ffffffffc0200a5a:	9ba50513          	addi	a0,a0,-1606 # ffffffffc0205410 <commands+0x380>
ffffffffc0200a5e:	bf05                	j	ffffffffc020098e <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc0200a60:	00005517          	auipc	a0,0x5
ffffffffc0200a64:	9d050513          	addi	a0,a0,-1584 # ffffffffc0205430 <commands+0x3a0>
ffffffffc0200a68:	b71d                	j	ffffffffc020098e <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc0200a6a:	00005517          	auipc	a0,0x5
ffffffffc0200a6e:	9de50513          	addi	a0,a0,-1570 # ffffffffc0205448 <commands+0x3b8>
ffffffffc0200a72:	f1cff0ef          	jal	ra,ffffffffc020018e <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200a76:	8522                	mv	a0,s0
ffffffffc0200a78:	b69ff0ef          	jal	ra,ffffffffc02005e0 <pgfault_handler>
ffffffffc0200a7c:	84aa                	mv	s1,a0
ffffffffc0200a7e:	ee050fe3          	beqz	a0,ffffffffc020097c <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc0200a82:	8522                	mv	a0,s0
ffffffffc0200a84:	db7ff0ef          	jal	ra,ffffffffc020083a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200a88:	86a6                	mv	a3,s1
ffffffffc0200a8a:	00005617          	auipc	a2,0x5
ffffffffc0200a8e:	8d660613          	addi	a2,a2,-1834 # ffffffffc0205360 <commands+0x2d0>
ffffffffc0200a92:	0d300593          	li	a1,211
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	aca50513          	addi	a0,a0,-1334 # ffffffffc0205560 <commands+0x4d0>
ffffffffc0200a9e:	9b3ff0ef          	jal	ra,ffffffffc0200450 <__panic>
}
ffffffffc0200aa2:	6442                	ld	s0,16(sp)
ffffffffc0200aa4:	60e2                	ld	ra,24(sp)
ffffffffc0200aa6:	64a2                	ld	s1,8(sp)
ffffffffc0200aa8:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc0200aaa:	d91ff06f          	j	ffffffffc020083a <print_trapframe>
ffffffffc0200aae:	d8dff06f          	j	ffffffffc020083a <print_trapframe>
                print_trapframe(tf);
ffffffffc0200ab2:	8522                	mv	a0,s0
ffffffffc0200ab4:	d87ff0ef          	jal	ra,ffffffffc020083a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200ab8:	86a6                	mv	a3,s1
ffffffffc0200aba:	00005617          	auipc	a2,0x5
ffffffffc0200abe:	8a660613          	addi	a2,a2,-1882 # ffffffffc0205360 <commands+0x2d0>
ffffffffc0200ac2:	0da00593          	li	a1,218
ffffffffc0200ac6:	00005517          	auipc	a0,0x5
ffffffffc0200aca:	a9a50513          	addi	a0,a0,-1382 # ffffffffc0205560 <commands+0x4d0>
ffffffffc0200ace:	983ff0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc0200ad2 <trap>:
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200ad2:	11853783          	ld	a5,280(a0)
ffffffffc0200ad6:	0007c463          	bltz	a5,ffffffffc0200ade <trap+0xc>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200ada:	e65ff06f          	j	ffffffffc020093e <exception_handler>
        interrupt_handler(tf);
ffffffffc0200ade:	dbfff06f          	j	ffffffffc020089c <interrupt_handler>
	...

ffffffffc0200ae4 <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200ae4:	14011073          	csrw	sscratch,sp
ffffffffc0200ae8:	712d                	addi	sp,sp,-288
ffffffffc0200aea:	e406                	sd	ra,8(sp)
ffffffffc0200aec:	ec0e                	sd	gp,24(sp)
ffffffffc0200aee:	f012                	sd	tp,32(sp)
ffffffffc0200af0:	f416                	sd	t0,40(sp)
ffffffffc0200af2:	f81a                	sd	t1,48(sp)
ffffffffc0200af4:	fc1e                	sd	t2,56(sp)
ffffffffc0200af6:	e0a2                	sd	s0,64(sp)
ffffffffc0200af8:	e4a6                	sd	s1,72(sp)
ffffffffc0200afa:	e8aa                	sd	a0,80(sp)
ffffffffc0200afc:	ecae                	sd	a1,88(sp)
ffffffffc0200afe:	f0b2                	sd	a2,96(sp)
ffffffffc0200b00:	f4b6                	sd	a3,104(sp)
ffffffffc0200b02:	f8ba                	sd	a4,112(sp)
ffffffffc0200b04:	fcbe                	sd	a5,120(sp)
ffffffffc0200b06:	e142                	sd	a6,128(sp)
ffffffffc0200b08:	e546                	sd	a7,136(sp)
ffffffffc0200b0a:	e94a                	sd	s2,144(sp)
ffffffffc0200b0c:	ed4e                	sd	s3,152(sp)
ffffffffc0200b0e:	f152                	sd	s4,160(sp)
ffffffffc0200b10:	f556                	sd	s5,168(sp)
ffffffffc0200b12:	f95a                	sd	s6,176(sp)
ffffffffc0200b14:	fd5e                	sd	s7,184(sp)
ffffffffc0200b16:	e1e2                	sd	s8,192(sp)
ffffffffc0200b18:	e5e6                	sd	s9,200(sp)
ffffffffc0200b1a:	e9ea                	sd	s10,208(sp)
ffffffffc0200b1c:	edee                	sd	s11,216(sp)
ffffffffc0200b1e:	f1f2                	sd	t3,224(sp)
ffffffffc0200b20:	f5f6                	sd	t4,232(sp)
ffffffffc0200b22:	f9fa                	sd	t5,240(sp)
ffffffffc0200b24:	fdfe                	sd	t6,248(sp)
ffffffffc0200b26:	14002473          	csrr	s0,sscratch
ffffffffc0200b2a:	100024f3          	csrr	s1,sstatus
ffffffffc0200b2e:	14102973          	csrr	s2,sepc
ffffffffc0200b32:	143029f3          	csrr	s3,stval
ffffffffc0200b36:	14202a73          	csrr	s4,scause
ffffffffc0200b3a:	e822                	sd	s0,16(sp)
ffffffffc0200b3c:	e226                	sd	s1,256(sp)
ffffffffc0200b3e:	e64a                	sd	s2,264(sp)
ffffffffc0200b40:	ea4e                	sd	s3,272(sp)
ffffffffc0200b42:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200b44:	850a                	mv	a0,sp
    jal trap
ffffffffc0200b46:	f8dff0ef          	jal	ra,ffffffffc0200ad2 <trap>

ffffffffc0200b4a <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200b4a:	6492                	ld	s1,256(sp)
ffffffffc0200b4c:	6932                	ld	s2,264(sp)
ffffffffc0200b4e:	10049073          	csrw	sstatus,s1
ffffffffc0200b52:	14191073          	csrw	sepc,s2
ffffffffc0200b56:	60a2                	ld	ra,8(sp)
ffffffffc0200b58:	61e2                	ld	gp,24(sp)
ffffffffc0200b5a:	7202                	ld	tp,32(sp)
ffffffffc0200b5c:	72a2                	ld	t0,40(sp)
ffffffffc0200b5e:	7342                	ld	t1,48(sp)
ffffffffc0200b60:	73e2                	ld	t2,56(sp)
ffffffffc0200b62:	6406                	ld	s0,64(sp)
ffffffffc0200b64:	64a6                	ld	s1,72(sp)
ffffffffc0200b66:	6546                	ld	a0,80(sp)
ffffffffc0200b68:	65e6                	ld	a1,88(sp)
ffffffffc0200b6a:	7606                	ld	a2,96(sp)
ffffffffc0200b6c:	76a6                	ld	a3,104(sp)
ffffffffc0200b6e:	7746                	ld	a4,112(sp)
ffffffffc0200b70:	77e6                	ld	a5,120(sp)
ffffffffc0200b72:	680a                	ld	a6,128(sp)
ffffffffc0200b74:	68aa                	ld	a7,136(sp)
ffffffffc0200b76:	694a                	ld	s2,144(sp)
ffffffffc0200b78:	69ea                	ld	s3,152(sp)
ffffffffc0200b7a:	7a0a                	ld	s4,160(sp)
ffffffffc0200b7c:	7aaa                	ld	s5,168(sp)
ffffffffc0200b7e:	7b4a                	ld	s6,176(sp)
ffffffffc0200b80:	7bea                	ld	s7,184(sp)
ffffffffc0200b82:	6c0e                	ld	s8,192(sp)
ffffffffc0200b84:	6cae                	ld	s9,200(sp)
ffffffffc0200b86:	6d4e                	ld	s10,208(sp)
ffffffffc0200b88:	6dee                	ld	s11,216(sp)
ffffffffc0200b8a:	7e0e                	ld	t3,224(sp)
ffffffffc0200b8c:	7eae                	ld	t4,232(sp)
ffffffffc0200b8e:	7f4e                	ld	t5,240(sp)
ffffffffc0200b90:	7fee                	ld	t6,248(sp)
ffffffffc0200b92:	6142                	ld	sp,16(sp)
    # go back from supervisor call
    sret
ffffffffc0200b94:	10200073          	sret

ffffffffc0200b98 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200b98:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200b9a:	bf45                	j	ffffffffc0200b4a <__trapret>
	...

ffffffffc0200b9e <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200b9e:	00015797          	auipc	a5,0x15
ffffffffc0200ba2:	93278793          	addi	a5,a5,-1742 # ffffffffc02154d0 <free_area>
ffffffffc0200ba6:	e79c                	sd	a5,8(a5)
ffffffffc0200ba8:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200baa:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200bae:	8082                	ret

ffffffffc0200bb0 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200bb0:	00015517          	auipc	a0,0x15
ffffffffc0200bb4:	93056503          	lwu	a0,-1744(a0) # ffffffffc02154e0 <free_area+0x10>
ffffffffc0200bb8:	8082                	ret

ffffffffc0200bba <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200bba:	715d                	addi	sp,sp,-80
ffffffffc0200bbc:	f84a                	sd	s2,48(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200bbe:	00015917          	auipc	s2,0x15
ffffffffc0200bc2:	91290913          	addi	s2,s2,-1774 # ffffffffc02154d0 <free_area>
ffffffffc0200bc6:	00893783          	ld	a5,8(s2)
ffffffffc0200bca:	e486                	sd	ra,72(sp)
ffffffffc0200bcc:	e0a2                	sd	s0,64(sp)
ffffffffc0200bce:	fc26                	sd	s1,56(sp)
ffffffffc0200bd0:	f44e                	sd	s3,40(sp)
ffffffffc0200bd2:	f052                	sd	s4,32(sp)
ffffffffc0200bd4:	ec56                	sd	s5,24(sp)
ffffffffc0200bd6:	e85a                	sd	s6,16(sp)
ffffffffc0200bd8:	e45e                	sd	s7,8(sp)
ffffffffc0200bda:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200bdc:	31278f63          	beq	a5,s2,ffffffffc0200efa <default_check+0x340>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200be0:	fe87b703          	ld	a4,-24(a5)
ffffffffc0200be4:	8305                	srli	a4,a4,0x1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200be6:	8b05                	andi	a4,a4,1
ffffffffc0200be8:	30070d63          	beqz	a4,ffffffffc0200f02 <default_check+0x348>
    int count = 0, total = 0;
ffffffffc0200bec:	4401                	li	s0,0
ffffffffc0200bee:	4481                	li	s1,0
ffffffffc0200bf0:	a031                	j	ffffffffc0200bfc <default_check+0x42>
ffffffffc0200bf2:	fe87b703          	ld	a4,-24(a5)
        assert(PageProperty(p));
ffffffffc0200bf6:	8b09                	andi	a4,a4,2
ffffffffc0200bf8:	30070563          	beqz	a4,ffffffffc0200f02 <default_check+0x348>
        count ++, total += p->property;
ffffffffc0200bfc:	ff07a703          	lw	a4,-16(a5)
ffffffffc0200c00:	679c                	ld	a5,8(a5)
ffffffffc0200c02:	2485                	addiw	s1,s1,1
ffffffffc0200c04:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c06:	ff2796e3          	bne	a5,s2,ffffffffc0200bf2 <default_check+0x38>
ffffffffc0200c0a:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc0200c0c:	092010ef          	jal	ra,ffffffffc0201c9e <nr_free_pages>
ffffffffc0200c10:	75351963          	bne	a0,s3,ffffffffc0201362 <default_check+0x7a8>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200c14:	4505                	li	a0,1
ffffffffc0200c16:	7bb000ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc0200c1a:	8a2a                	mv	s4,a0
ffffffffc0200c1c:	48050363          	beqz	a0,ffffffffc02010a2 <default_check+0x4e8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c20:	4505                	li	a0,1
ffffffffc0200c22:	7af000ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc0200c26:	89aa                	mv	s3,a0
ffffffffc0200c28:	74050d63          	beqz	a0,ffffffffc0201382 <default_check+0x7c8>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200c2c:	4505                	li	a0,1
ffffffffc0200c2e:	7a3000ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc0200c32:	8aaa                	mv	s5,a0
ffffffffc0200c34:	4e050763          	beqz	a0,ffffffffc0201122 <default_check+0x568>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200c38:	2f3a0563          	beq	s4,s3,ffffffffc0200f22 <default_check+0x368>
ffffffffc0200c3c:	2eaa0363          	beq	s4,a0,ffffffffc0200f22 <default_check+0x368>
ffffffffc0200c40:	2ea98163          	beq	s3,a0,ffffffffc0200f22 <default_check+0x368>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200c44:	000a2783          	lw	a5,0(s4)
ffffffffc0200c48:	2e079d63          	bnez	a5,ffffffffc0200f42 <default_check+0x388>
ffffffffc0200c4c:	0009a783          	lw	a5,0(s3)
ffffffffc0200c50:	2e079963          	bnez	a5,ffffffffc0200f42 <default_check+0x388>
ffffffffc0200c54:	411c                	lw	a5,0(a0)
ffffffffc0200c56:	2e079663          	bnez	a5,ffffffffc0200f42 <default_check+0x388>
extern size_t npage;
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page) {
    return page - pages + nbase;
ffffffffc0200c5a:	00015797          	auipc	a5,0x15
ffffffffc0200c5e:	8a678793          	addi	a5,a5,-1882 # ffffffffc0215500 <pages>
ffffffffc0200c62:	639c                	ld	a5,0(a5)
ffffffffc0200c64:	00005717          	auipc	a4,0x5
ffffffffc0200c68:	c8c70713          	addi	a4,a4,-884 # ffffffffc02058f0 <commands+0x860>
ffffffffc0200c6c:	630c                	ld	a1,0(a4)
ffffffffc0200c6e:	40fa0733          	sub	a4,s4,a5
ffffffffc0200c72:	870d                	srai	a4,a4,0x3
ffffffffc0200c74:	02b70733          	mul	a4,a4,a1
ffffffffc0200c78:	00006697          	auipc	a3,0x6
ffffffffc0200c7c:	2d068693          	addi	a3,a3,720 # ffffffffc0206f48 <nbase>
ffffffffc0200c80:	6290                	ld	a2,0(a3)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200c82:	00015697          	auipc	a3,0x15
ffffffffc0200c86:	80e68693          	addi	a3,a3,-2034 # ffffffffc0215490 <npage>
ffffffffc0200c8a:	6294                	ld	a3,0(a3)
ffffffffc0200c8c:	06b2                	slli	a3,a3,0xc
ffffffffc0200c8e:	9732                	add	a4,a4,a2
}

static inline uintptr_t
page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200c90:	0732                	slli	a4,a4,0xc
ffffffffc0200c92:	2cd77863          	bleu	a3,a4,ffffffffc0200f62 <default_check+0x3a8>
    return page - pages + nbase;
ffffffffc0200c96:	40f98733          	sub	a4,s3,a5
ffffffffc0200c9a:	870d                	srai	a4,a4,0x3
ffffffffc0200c9c:	02b70733          	mul	a4,a4,a1
ffffffffc0200ca0:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ca2:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200ca4:	4ed77f63          	bleu	a3,a4,ffffffffc02011a2 <default_check+0x5e8>
    return page - pages + nbase;
ffffffffc0200ca8:	40f507b3          	sub	a5,a0,a5
ffffffffc0200cac:	878d                	srai	a5,a5,0x3
ffffffffc0200cae:	02b787b3          	mul	a5,a5,a1
ffffffffc0200cb2:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200cb4:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200cb6:	34d7f663          	bleu	a3,a5,ffffffffc0201002 <default_check+0x448>
    assert(alloc_page() == NULL);
ffffffffc0200cba:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200cbc:	00093c03          	ld	s8,0(s2)
ffffffffc0200cc0:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200cc4:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc0200cc8:	00015797          	auipc	a5,0x15
ffffffffc0200ccc:	8127b823          	sd	s2,-2032(a5) # ffffffffc02154d8 <free_area+0x8>
ffffffffc0200cd0:	00015797          	auipc	a5,0x15
ffffffffc0200cd4:	8127b023          	sd	s2,-2048(a5) # ffffffffc02154d0 <free_area>
    nr_free = 0;
ffffffffc0200cd8:	00015797          	auipc	a5,0x15
ffffffffc0200cdc:	8007a423          	sw	zero,-2040(a5) # ffffffffc02154e0 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200ce0:	6f1000ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc0200ce4:	2e051f63          	bnez	a0,ffffffffc0200fe2 <default_check+0x428>
    free_page(p0);
ffffffffc0200ce8:	4585                	li	a1,1
ffffffffc0200cea:	8552                	mv	a0,s4
ffffffffc0200cec:	76d000ef          	jal	ra,ffffffffc0201c58 <free_pages>
    free_page(p1);
ffffffffc0200cf0:	4585                	li	a1,1
ffffffffc0200cf2:	854e                	mv	a0,s3
ffffffffc0200cf4:	765000ef          	jal	ra,ffffffffc0201c58 <free_pages>
    free_page(p2);
ffffffffc0200cf8:	4585                	li	a1,1
ffffffffc0200cfa:	8556                	mv	a0,s5
ffffffffc0200cfc:	75d000ef          	jal	ra,ffffffffc0201c58 <free_pages>
    assert(nr_free == 3);
ffffffffc0200d00:	01092703          	lw	a4,16(s2)
ffffffffc0200d04:	478d                	li	a5,3
ffffffffc0200d06:	2af71e63          	bne	a4,a5,ffffffffc0200fc2 <default_check+0x408>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d0a:	4505                	li	a0,1
ffffffffc0200d0c:	6c5000ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc0200d10:	89aa                	mv	s3,a0
ffffffffc0200d12:	28050863          	beqz	a0,ffffffffc0200fa2 <default_check+0x3e8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d16:	4505                	li	a0,1
ffffffffc0200d18:	6b9000ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc0200d1c:	8aaa                	mv	s5,a0
ffffffffc0200d1e:	3e050263          	beqz	a0,ffffffffc0201102 <default_check+0x548>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d22:	4505                	li	a0,1
ffffffffc0200d24:	6ad000ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc0200d28:	8a2a                	mv	s4,a0
ffffffffc0200d2a:	3a050c63          	beqz	a0,ffffffffc02010e2 <default_check+0x528>
    assert(alloc_page() == NULL);
ffffffffc0200d2e:	4505                	li	a0,1
ffffffffc0200d30:	6a1000ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc0200d34:	38051763          	bnez	a0,ffffffffc02010c2 <default_check+0x508>
    free_page(p0);
ffffffffc0200d38:	4585                	li	a1,1
ffffffffc0200d3a:	854e                	mv	a0,s3
ffffffffc0200d3c:	71d000ef          	jal	ra,ffffffffc0201c58 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200d40:	00893783          	ld	a5,8(s2)
ffffffffc0200d44:	23278f63          	beq	a5,s2,ffffffffc0200f82 <default_check+0x3c8>
    assert((p = alloc_page()) == p0);
ffffffffc0200d48:	4505                	li	a0,1
ffffffffc0200d4a:	687000ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc0200d4e:	32a99a63          	bne	s3,a0,ffffffffc0201082 <default_check+0x4c8>
    assert(alloc_page() == NULL);
ffffffffc0200d52:	4505                	li	a0,1
ffffffffc0200d54:	67d000ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc0200d58:	30051563          	bnez	a0,ffffffffc0201062 <default_check+0x4a8>
    assert(nr_free == 0);
ffffffffc0200d5c:	01092783          	lw	a5,16(s2)
ffffffffc0200d60:	2e079163          	bnez	a5,ffffffffc0201042 <default_check+0x488>
    free_page(p);
ffffffffc0200d64:	854e                	mv	a0,s3
ffffffffc0200d66:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200d68:	00014797          	auipc	a5,0x14
ffffffffc0200d6c:	7787b423          	sd	s8,1896(a5) # ffffffffc02154d0 <free_area>
ffffffffc0200d70:	00014797          	auipc	a5,0x14
ffffffffc0200d74:	7777b423          	sd	s7,1896(a5) # ffffffffc02154d8 <free_area+0x8>
    nr_free = nr_free_store;
ffffffffc0200d78:	00014797          	auipc	a5,0x14
ffffffffc0200d7c:	7767a423          	sw	s6,1896(a5) # ffffffffc02154e0 <free_area+0x10>
    free_page(p);
ffffffffc0200d80:	6d9000ef          	jal	ra,ffffffffc0201c58 <free_pages>
    free_page(p1);
ffffffffc0200d84:	4585                	li	a1,1
ffffffffc0200d86:	8556                	mv	a0,s5
ffffffffc0200d88:	6d1000ef          	jal	ra,ffffffffc0201c58 <free_pages>
    free_page(p2);
ffffffffc0200d8c:	4585                	li	a1,1
ffffffffc0200d8e:	8552                	mv	a0,s4
ffffffffc0200d90:	6c9000ef          	jal	ra,ffffffffc0201c58 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200d94:	4515                	li	a0,5
ffffffffc0200d96:	63b000ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc0200d9a:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200d9c:	28050363          	beqz	a0,ffffffffc0201022 <default_check+0x468>
ffffffffc0200da0:	651c                	ld	a5,8(a0)
ffffffffc0200da2:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200da4:	8b85                	andi	a5,a5,1
ffffffffc0200da6:	54079e63          	bnez	a5,ffffffffc0201302 <default_check+0x748>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200daa:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200dac:	00093b03          	ld	s6,0(s2)
ffffffffc0200db0:	00893a83          	ld	s5,8(s2)
ffffffffc0200db4:	00014797          	auipc	a5,0x14
ffffffffc0200db8:	7127be23          	sd	s2,1820(a5) # ffffffffc02154d0 <free_area>
ffffffffc0200dbc:	00014797          	auipc	a5,0x14
ffffffffc0200dc0:	7127be23          	sd	s2,1820(a5) # ffffffffc02154d8 <free_area+0x8>
    assert(alloc_page() == NULL);
ffffffffc0200dc4:	60d000ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc0200dc8:	50051d63          	bnez	a0,ffffffffc02012e2 <default_check+0x728>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200dcc:	09098a13          	addi	s4,s3,144
ffffffffc0200dd0:	8552                	mv	a0,s4
ffffffffc0200dd2:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200dd4:	01092b83          	lw	s7,16(s2)
    nr_free = 0;
ffffffffc0200dd8:	00014797          	auipc	a5,0x14
ffffffffc0200ddc:	7007a423          	sw	zero,1800(a5) # ffffffffc02154e0 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200de0:	679000ef          	jal	ra,ffffffffc0201c58 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200de4:	4511                	li	a0,4
ffffffffc0200de6:	5eb000ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc0200dea:	4c051c63          	bnez	a0,ffffffffc02012c2 <default_check+0x708>
ffffffffc0200dee:	0989b783          	ld	a5,152(s3)
ffffffffc0200df2:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200df4:	8b85                	andi	a5,a5,1
ffffffffc0200df6:	4a078663          	beqz	a5,ffffffffc02012a2 <default_check+0x6e8>
ffffffffc0200dfa:	0a09a703          	lw	a4,160(s3)
ffffffffc0200dfe:	478d                	li	a5,3
ffffffffc0200e00:	4af71163          	bne	a4,a5,ffffffffc02012a2 <default_check+0x6e8>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200e04:	450d                	li	a0,3
ffffffffc0200e06:	5cb000ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc0200e0a:	8c2a                	mv	s8,a0
ffffffffc0200e0c:	46050b63          	beqz	a0,ffffffffc0201282 <default_check+0x6c8>
    assert(alloc_page() == NULL);
ffffffffc0200e10:	4505                	li	a0,1
ffffffffc0200e12:	5bf000ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc0200e16:	44051663          	bnez	a0,ffffffffc0201262 <default_check+0x6a8>
    assert(p0 + 2 == p1);
ffffffffc0200e1a:	438a1463          	bne	s4,s8,ffffffffc0201242 <default_check+0x688>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200e1e:	4585                	li	a1,1
ffffffffc0200e20:	854e                	mv	a0,s3
ffffffffc0200e22:	637000ef          	jal	ra,ffffffffc0201c58 <free_pages>
    free_pages(p1, 3);
ffffffffc0200e26:	458d                	li	a1,3
ffffffffc0200e28:	8552                	mv	a0,s4
ffffffffc0200e2a:	62f000ef          	jal	ra,ffffffffc0201c58 <free_pages>
ffffffffc0200e2e:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200e32:	04898c13          	addi	s8,s3,72
ffffffffc0200e36:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200e38:	8b85                	andi	a5,a5,1
ffffffffc0200e3a:	3e078463          	beqz	a5,ffffffffc0201222 <default_check+0x668>
ffffffffc0200e3e:	0109a703          	lw	a4,16(s3)
ffffffffc0200e42:	4785                	li	a5,1
ffffffffc0200e44:	3cf71f63          	bne	a4,a5,ffffffffc0201222 <default_check+0x668>
ffffffffc0200e48:	008a3783          	ld	a5,8(s4)
ffffffffc0200e4c:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200e4e:	8b85                	andi	a5,a5,1
ffffffffc0200e50:	3a078963          	beqz	a5,ffffffffc0201202 <default_check+0x648>
ffffffffc0200e54:	010a2703          	lw	a4,16(s4)
ffffffffc0200e58:	478d                	li	a5,3
ffffffffc0200e5a:	3af71463          	bne	a4,a5,ffffffffc0201202 <default_check+0x648>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200e5e:	4505                	li	a0,1
ffffffffc0200e60:	571000ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc0200e64:	36a99f63          	bne	s3,a0,ffffffffc02011e2 <default_check+0x628>
    free_page(p0);
ffffffffc0200e68:	4585                	li	a1,1
ffffffffc0200e6a:	5ef000ef          	jal	ra,ffffffffc0201c58 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200e6e:	4509                	li	a0,2
ffffffffc0200e70:	561000ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc0200e74:	34aa1763          	bne	s4,a0,ffffffffc02011c2 <default_check+0x608>

    free_pages(p0, 2);
ffffffffc0200e78:	4589                	li	a1,2
ffffffffc0200e7a:	5df000ef          	jal	ra,ffffffffc0201c58 <free_pages>
    free_page(p2);
ffffffffc0200e7e:	4585                	li	a1,1
ffffffffc0200e80:	8562                	mv	a0,s8
ffffffffc0200e82:	5d7000ef          	jal	ra,ffffffffc0201c58 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200e86:	4515                	li	a0,5
ffffffffc0200e88:	549000ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc0200e8c:	89aa                	mv	s3,a0
ffffffffc0200e8e:	48050a63          	beqz	a0,ffffffffc0201322 <default_check+0x768>
    assert(alloc_page() == NULL);
ffffffffc0200e92:	4505                	li	a0,1
ffffffffc0200e94:	53d000ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc0200e98:	2e051563          	bnez	a0,ffffffffc0201182 <default_check+0x5c8>

    assert(nr_free == 0);
ffffffffc0200e9c:	01092783          	lw	a5,16(s2)
ffffffffc0200ea0:	2c079163          	bnez	a5,ffffffffc0201162 <default_check+0x5a8>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200ea4:	4595                	li	a1,5
ffffffffc0200ea6:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200ea8:	00014797          	auipc	a5,0x14
ffffffffc0200eac:	6377ac23          	sw	s7,1592(a5) # ffffffffc02154e0 <free_area+0x10>
    free_list = free_list_store;
ffffffffc0200eb0:	00014797          	auipc	a5,0x14
ffffffffc0200eb4:	6367b023          	sd	s6,1568(a5) # ffffffffc02154d0 <free_area>
ffffffffc0200eb8:	00014797          	auipc	a5,0x14
ffffffffc0200ebc:	6357b023          	sd	s5,1568(a5) # ffffffffc02154d8 <free_area+0x8>
    free_pages(p0, 5);
ffffffffc0200ec0:	599000ef          	jal	ra,ffffffffc0201c58 <free_pages>
    return listelm->next;
ffffffffc0200ec4:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ec8:	01278963          	beq	a5,s2,ffffffffc0200eda <default_check+0x320>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200ecc:	ff07a703          	lw	a4,-16(a5)
ffffffffc0200ed0:	679c                	ld	a5,8(a5)
ffffffffc0200ed2:	34fd                	addiw	s1,s1,-1
ffffffffc0200ed4:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ed6:	ff279be3          	bne	a5,s2,ffffffffc0200ecc <default_check+0x312>
    }
    assert(count == 0);
ffffffffc0200eda:	26049463          	bnez	s1,ffffffffc0201142 <default_check+0x588>
    assert(total == 0);
ffffffffc0200ede:	46041263          	bnez	s0,ffffffffc0201342 <default_check+0x788>
}
ffffffffc0200ee2:	60a6                	ld	ra,72(sp)
ffffffffc0200ee4:	6406                	ld	s0,64(sp)
ffffffffc0200ee6:	74e2                	ld	s1,56(sp)
ffffffffc0200ee8:	7942                	ld	s2,48(sp)
ffffffffc0200eea:	79a2                	ld	s3,40(sp)
ffffffffc0200eec:	7a02                	ld	s4,32(sp)
ffffffffc0200eee:	6ae2                	ld	s5,24(sp)
ffffffffc0200ef0:	6b42                	ld	s6,16(sp)
ffffffffc0200ef2:	6ba2                	ld	s7,8(sp)
ffffffffc0200ef4:	6c02                	ld	s8,0(sp)
ffffffffc0200ef6:	6161                	addi	sp,sp,80
ffffffffc0200ef8:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200efa:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200efc:	4401                	li	s0,0
ffffffffc0200efe:	4481                	li	s1,0
ffffffffc0200f00:	b331                	j	ffffffffc0200c0c <default_check+0x52>
        assert(PageProperty(p));
ffffffffc0200f02:	00005697          	auipc	a3,0x5
ffffffffc0200f06:	9f668693          	addi	a3,a3,-1546 # ffffffffc02058f8 <commands+0x868>
ffffffffc0200f0a:	00005617          	auipc	a2,0x5
ffffffffc0200f0e:	9fe60613          	addi	a2,a2,-1538 # ffffffffc0205908 <commands+0x878>
ffffffffc0200f12:	0f000593          	li	a1,240
ffffffffc0200f16:	00005517          	auipc	a0,0x5
ffffffffc0200f1a:	a0a50513          	addi	a0,a0,-1526 # ffffffffc0205920 <commands+0x890>
ffffffffc0200f1e:	d32ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200f22:	00005697          	auipc	a3,0x5
ffffffffc0200f26:	a9668693          	addi	a3,a3,-1386 # ffffffffc02059b8 <commands+0x928>
ffffffffc0200f2a:	00005617          	auipc	a2,0x5
ffffffffc0200f2e:	9de60613          	addi	a2,a2,-1570 # ffffffffc0205908 <commands+0x878>
ffffffffc0200f32:	0bd00593          	li	a1,189
ffffffffc0200f36:	00005517          	auipc	a0,0x5
ffffffffc0200f3a:	9ea50513          	addi	a0,a0,-1558 # ffffffffc0205920 <commands+0x890>
ffffffffc0200f3e:	d12ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f42:	00005697          	auipc	a3,0x5
ffffffffc0200f46:	a9e68693          	addi	a3,a3,-1378 # ffffffffc02059e0 <commands+0x950>
ffffffffc0200f4a:	00005617          	auipc	a2,0x5
ffffffffc0200f4e:	9be60613          	addi	a2,a2,-1602 # ffffffffc0205908 <commands+0x878>
ffffffffc0200f52:	0be00593          	li	a1,190
ffffffffc0200f56:	00005517          	auipc	a0,0x5
ffffffffc0200f5a:	9ca50513          	addi	a0,a0,-1590 # ffffffffc0205920 <commands+0x890>
ffffffffc0200f5e:	cf2ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f62:	00005697          	auipc	a3,0x5
ffffffffc0200f66:	abe68693          	addi	a3,a3,-1346 # ffffffffc0205a20 <commands+0x990>
ffffffffc0200f6a:	00005617          	auipc	a2,0x5
ffffffffc0200f6e:	99e60613          	addi	a2,a2,-1634 # ffffffffc0205908 <commands+0x878>
ffffffffc0200f72:	0c000593          	li	a1,192
ffffffffc0200f76:	00005517          	auipc	a0,0x5
ffffffffc0200f7a:	9aa50513          	addi	a0,a0,-1622 # ffffffffc0205920 <commands+0x890>
ffffffffc0200f7e:	cd2ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200f82:	00005697          	auipc	a3,0x5
ffffffffc0200f86:	b2668693          	addi	a3,a3,-1242 # ffffffffc0205aa8 <commands+0xa18>
ffffffffc0200f8a:	00005617          	auipc	a2,0x5
ffffffffc0200f8e:	97e60613          	addi	a2,a2,-1666 # ffffffffc0205908 <commands+0x878>
ffffffffc0200f92:	0d900593          	li	a1,217
ffffffffc0200f96:	00005517          	auipc	a0,0x5
ffffffffc0200f9a:	98a50513          	addi	a0,a0,-1654 # ffffffffc0205920 <commands+0x890>
ffffffffc0200f9e:	cb2ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fa2:	00005697          	auipc	a3,0x5
ffffffffc0200fa6:	9b668693          	addi	a3,a3,-1610 # ffffffffc0205958 <commands+0x8c8>
ffffffffc0200faa:	00005617          	auipc	a2,0x5
ffffffffc0200fae:	95e60613          	addi	a2,a2,-1698 # ffffffffc0205908 <commands+0x878>
ffffffffc0200fb2:	0d200593          	li	a1,210
ffffffffc0200fb6:	00005517          	auipc	a0,0x5
ffffffffc0200fba:	96a50513          	addi	a0,a0,-1686 # ffffffffc0205920 <commands+0x890>
ffffffffc0200fbe:	c92ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(nr_free == 3);
ffffffffc0200fc2:	00005697          	auipc	a3,0x5
ffffffffc0200fc6:	ad668693          	addi	a3,a3,-1322 # ffffffffc0205a98 <commands+0xa08>
ffffffffc0200fca:	00005617          	auipc	a2,0x5
ffffffffc0200fce:	93e60613          	addi	a2,a2,-1730 # ffffffffc0205908 <commands+0x878>
ffffffffc0200fd2:	0d000593          	li	a1,208
ffffffffc0200fd6:	00005517          	auipc	a0,0x5
ffffffffc0200fda:	94a50513          	addi	a0,a0,-1718 # ffffffffc0205920 <commands+0x890>
ffffffffc0200fde:	c72ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200fe2:	00005697          	auipc	a3,0x5
ffffffffc0200fe6:	a9e68693          	addi	a3,a3,-1378 # ffffffffc0205a80 <commands+0x9f0>
ffffffffc0200fea:	00005617          	auipc	a2,0x5
ffffffffc0200fee:	91e60613          	addi	a2,a2,-1762 # ffffffffc0205908 <commands+0x878>
ffffffffc0200ff2:	0cb00593          	li	a1,203
ffffffffc0200ff6:	00005517          	auipc	a0,0x5
ffffffffc0200ffa:	92a50513          	addi	a0,a0,-1750 # ffffffffc0205920 <commands+0x890>
ffffffffc0200ffe:	c52ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201002:	00005697          	auipc	a3,0x5
ffffffffc0201006:	a5e68693          	addi	a3,a3,-1442 # ffffffffc0205a60 <commands+0x9d0>
ffffffffc020100a:	00005617          	auipc	a2,0x5
ffffffffc020100e:	8fe60613          	addi	a2,a2,-1794 # ffffffffc0205908 <commands+0x878>
ffffffffc0201012:	0c200593          	li	a1,194
ffffffffc0201016:	00005517          	auipc	a0,0x5
ffffffffc020101a:	90a50513          	addi	a0,a0,-1782 # ffffffffc0205920 <commands+0x890>
ffffffffc020101e:	c32ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(p0 != NULL);
ffffffffc0201022:	00005697          	auipc	a3,0x5
ffffffffc0201026:	ace68693          	addi	a3,a3,-1330 # ffffffffc0205af0 <commands+0xa60>
ffffffffc020102a:	00005617          	auipc	a2,0x5
ffffffffc020102e:	8de60613          	addi	a2,a2,-1826 # ffffffffc0205908 <commands+0x878>
ffffffffc0201032:	0f800593          	li	a1,248
ffffffffc0201036:	00005517          	auipc	a0,0x5
ffffffffc020103a:	8ea50513          	addi	a0,a0,-1814 # ffffffffc0205920 <commands+0x890>
ffffffffc020103e:	c12ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(nr_free == 0);
ffffffffc0201042:	00005697          	auipc	a3,0x5
ffffffffc0201046:	a9e68693          	addi	a3,a3,-1378 # ffffffffc0205ae0 <commands+0xa50>
ffffffffc020104a:	00005617          	auipc	a2,0x5
ffffffffc020104e:	8be60613          	addi	a2,a2,-1858 # ffffffffc0205908 <commands+0x878>
ffffffffc0201052:	0df00593          	li	a1,223
ffffffffc0201056:	00005517          	auipc	a0,0x5
ffffffffc020105a:	8ca50513          	addi	a0,a0,-1846 # ffffffffc0205920 <commands+0x890>
ffffffffc020105e:	bf2ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201062:	00005697          	auipc	a3,0x5
ffffffffc0201066:	a1e68693          	addi	a3,a3,-1506 # ffffffffc0205a80 <commands+0x9f0>
ffffffffc020106a:	00005617          	auipc	a2,0x5
ffffffffc020106e:	89e60613          	addi	a2,a2,-1890 # ffffffffc0205908 <commands+0x878>
ffffffffc0201072:	0dd00593          	li	a1,221
ffffffffc0201076:	00005517          	auipc	a0,0x5
ffffffffc020107a:	8aa50513          	addi	a0,a0,-1878 # ffffffffc0205920 <commands+0x890>
ffffffffc020107e:	bd2ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201082:	00005697          	auipc	a3,0x5
ffffffffc0201086:	a3e68693          	addi	a3,a3,-1474 # ffffffffc0205ac0 <commands+0xa30>
ffffffffc020108a:	00005617          	auipc	a2,0x5
ffffffffc020108e:	87e60613          	addi	a2,a2,-1922 # ffffffffc0205908 <commands+0x878>
ffffffffc0201092:	0dc00593          	li	a1,220
ffffffffc0201096:	00005517          	auipc	a0,0x5
ffffffffc020109a:	88a50513          	addi	a0,a0,-1910 # ffffffffc0205920 <commands+0x890>
ffffffffc020109e:	bb2ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02010a2:	00005697          	auipc	a3,0x5
ffffffffc02010a6:	8b668693          	addi	a3,a3,-1866 # ffffffffc0205958 <commands+0x8c8>
ffffffffc02010aa:	00005617          	auipc	a2,0x5
ffffffffc02010ae:	85e60613          	addi	a2,a2,-1954 # ffffffffc0205908 <commands+0x878>
ffffffffc02010b2:	0b900593          	li	a1,185
ffffffffc02010b6:	00005517          	auipc	a0,0x5
ffffffffc02010ba:	86a50513          	addi	a0,a0,-1942 # ffffffffc0205920 <commands+0x890>
ffffffffc02010be:	b92ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02010c2:	00005697          	auipc	a3,0x5
ffffffffc02010c6:	9be68693          	addi	a3,a3,-1602 # ffffffffc0205a80 <commands+0x9f0>
ffffffffc02010ca:	00005617          	auipc	a2,0x5
ffffffffc02010ce:	83e60613          	addi	a2,a2,-1986 # ffffffffc0205908 <commands+0x878>
ffffffffc02010d2:	0d600593          	li	a1,214
ffffffffc02010d6:	00005517          	auipc	a0,0x5
ffffffffc02010da:	84a50513          	addi	a0,a0,-1974 # ffffffffc0205920 <commands+0x890>
ffffffffc02010de:	b72ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02010e2:	00005697          	auipc	a3,0x5
ffffffffc02010e6:	8b668693          	addi	a3,a3,-1866 # ffffffffc0205998 <commands+0x908>
ffffffffc02010ea:	00005617          	auipc	a2,0x5
ffffffffc02010ee:	81e60613          	addi	a2,a2,-2018 # ffffffffc0205908 <commands+0x878>
ffffffffc02010f2:	0d400593          	li	a1,212
ffffffffc02010f6:	00005517          	auipc	a0,0x5
ffffffffc02010fa:	82a50513          	addi	a0,a0,-2006 # ffffffffc0205920 <commands+0x890>
ffffffffc02010fe:	b52ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201102:	00005697          	auipc	a3,0x5
ffffffffc0201106:	87668693          	addi	a3,a3,-1930 # ffffffffc0205978 <commands+0x8e8>
ffffffffc020110a:	00004617          	auipc	a2,0x4
ffffffffc020110e:	7fe60613          	addi	a2,a2,2046 # ffffffffc0205908 <commands+0x878>
ffffffffc0201112:	0d300593          	li	a1,211
ffffffffc0201116:	00005517          	auipc	a0,0x5
ffffffffc020111a:	80a50513          	addi	a0,a0,-2038 # ffffffffc0205920 <commands+0x890>
ffffffffc020111e:	b32ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201122:	00005697          	auipc	a3,0x5
ffffffffc0201126:	87668693          	addi	a3,a3,-1930 # ffffffffc0205998 <commands+0x908>
ffffffffc020112a:	00004617          	auipc	a2,0x4
ffffffffc020112e:	7de60613          	addi	a2,a2,2014 # ffffffffc0205908 <commands+0x878>
ffffffffc0201132:	0bb00593          	li	a1,187
ffffffffc0201136:	00004517          	auipc	a0,0x4
ffffffffc020113a:	7ea50513          	addi	a0,a0,2026 # ffffffffc0205920 <commands+0x890>
ffffffffc020113e:	b12ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(count == 0);
ffffffffc0201142:	00005697          	auipc	a3,0x5
ffffffffc0201146:	afe68693          	addi	a3,a3,-1282 # ffffffffc0205c40 <commands+0xbb0>
ffffffffc020114a:	00004617          	auipc	a2,0x4
ffffffffc020114e:	7be60613          	addi	a2,a2,1982 # ffffffffc0205908 <commands+0x878>
ffffffffc0201152:	12500593          	li	a1,293
ffffffffc0201156:	00004517          	auipc	a0,0x4
ffffffffc020115a:	7ca50513          	addi	a0,a0,1994 # ffffffffc0205920 <commands+0x890>
ffffffffc020115e:	af2ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(nr_free == 0);
ffffffffc0201162:	00005697          	auipc	a3,0x5
ffffffffc0201166:	97e68693          	addi	a3,a3,-1666 # ffffffffc0205ae0 <commands+0xa50>
ffffffffc020116a:	00004617          	auipc	a2,0x4
ffffffffc020116e:	79e60613          	addi	a2,a2,1950 # ffffffffc0205908 <commands+0x878>
ffffffffc0201172:	11a00593          	li	a1,282
ffffffffc0201176:	00004517          	auipc	a0,0x4
ffffffffc020117a:	7aa50513          	addi	a0,a0,1962 # ffffffffc0205920 <commands+0x890>
ffffffffc020117e:	ad2ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201182:	00005697          	auipc	a3,0x5
ffffffffc0201186:	8fe68693          	addi	a3,a3,-1794 # ffffffffc0205a80 <commands+0x9f0>
ffffffffc020118a:	00004617          	auipc	a2,0x4
ffffffffc020118e:	77e60613          	addi	a2,a2,1918 # ffffffffc0205908 <commands+0x878>
ffffffffc0201192:	11800593          	li	a1,280
ffffffffc0201196:	00004517          	auipc	a0,0x4
ffffffffc020119a:	78a50513          	addi	a0,a0,1930 # ffffffffc0205920 <commands+0x890>
ffffffffc020119e:	ab2ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02011a2:	00005697          	auipc	a3,0x5
ffffffffc02011a6:	89e68693          	addi	a3,a3,-1890 # ffffffffc0205a40 <commands+0x9b0>
ffffffffc02011aa:	00004617          	auipc	a2,0x4
ffffffffc02011ae:	75e60613          	addi	a2,a2,1886 # ffffffffc0205908 <commands+0x878>
ffffffffc02011b2:	0c100593          	li	a1,193
ffffffffc02011b6:	00004517          	auipc	a0,0x4
ffffffffc02011ba:	76a50513          	addi	a0,a0,1898 # ffffffffc0205920 <commands+0x890>
ffffffffc02011be:	a92ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02011c2:	00005697          	auipc	a3,0x5
ffffffffc02011c6:	a3e68693          	addi	a3,a3,-1474 # ffffffffc0205c00 <commands+0xb70>
ffffffffc02011ca:	00004617          	auipc	a2,0x4
ffffffffc02011ce:	73e60613          	addi	a2,a2,1854 # ffffffffc0205908 <commands+0x878>
ffffffffc02011d2:	11200593          	li	a1,274
ffffffffc02011d6:	00004517          	auipc	a0,0x4
ffffffffc02011da:	74a50513          	addi	a0,a0,1866 # ffffffffc0205920 <commands+0x890>
ffffffffc02011de:	a72ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02011e2:	00005697          	auipc	a3,0x5
ffffffffc02011e6:	9fe68693          	addi	a3,a3,-1538 # ffffffffc0205be0 <commands+0xb50>
ffffffffc02011ea:	00004617          	auipc	a2,0x4
ffffffffc02011ee:	71e60613          	addi	a2,a2,1822 # ffffffffc0205908 <commands+0x878>
ffffffffc02011f2:	11000593          	li	a1,272
ffffffffc02011f6:	00004517          	auipc	a0,0x4
ffffffffc02011fa:	72a50513          	addi	a0,a0,1834 # ffffffffc0205920 <commands+0x890>
ffffffffc02011fe:	a52ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201202:	00005697          	auipc	a3,0x5
ffffffffc0201206:	9b668693          	addi	a3,a3,-1610 # ffffffffc0205bb8 <commands+0xb28>
ffffffffc020120a:	00004617          	auipc	a2,0x4
ffffffffc020120e:	6fe60613          	addi	a2,a2,1790 # ffffffffc0205908 <commands+0x878>
ffffffffc0201212:	10e00593          	li	a1,270
ffffffffc0201216:	00004517          	auipc	a0,0x4
ffffffffc020121a:	70a50513          	addi	a0,a0,1802 # ffffffffc0205920 <commands+0x890>
ffffffffc020121e:	a32ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201222:	00005697          	auipc	a3,0x5
ffffffffc0201226:	96e68693          	addi	a3,a3,-1682 # ffffffffc0205b90 <commands+0xb00>
ffffffffc020122a:	00004617          	auipc	a2,0x4
ffffffffc020122e:	6de60613          	addi	a2,a2,1758 # ffffffffc0205908 <commands+0x878>
ffffffffc0201232:	10d00593          	li	a1,269
ffffffffc0201236:	00004517          	auipc	a0,0x4
ffffffffc020123a:	6ea50513          	addi	a0,a0,1770 # ffffffffc0205920 <commands+0x890>
ffffffffc020123e:	a12ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201242:	00005697          	auipc	a3,0x5
ffffffffc0201246:	93e68693          	addi	a3,a3,-1730 # ffffffffc0205b80 <commands+0xaf0>
ffffffffc020124a:	00004617          	auipc	a2,0x4
ffffffffc020124e:	6be60613          	addi	a2,a2,1726 # ffffffffc0205908 <commands+0x878>
ffffffffc0201252:	10800593          	li	a1,264
ffffffffc0201256:	00004517          	auipc	a0,0x4
ffffffffc020125a:	6ca50513          	addi	a0,a0,1738 # ffffffffc0205920 <commands+0x890>
ffffffffc020125e:	9f2ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201262:	00005697          	auipc	a3,0x5
ffffffffc0201266:	81e68693          	addi	a3,a3,-2018 # ffffffffc0205a80 <commands+0x9f0>
ffffffffc020126a:	00004617          	auipc	a2,0x4
ffffffffc020126e:	69e60613          	addi	a2,a2,1694 # ffffffffc0205908 <commands+0x878>
ffffffffc0201272:	10700593          	li	a1,263
ffffffffc0201276:	00004517          	auipc	a0,0x4
ffffffffc020127a:	6aa50513          	addi	a0,a0,1706 # ffffffffc0205920 <commands+0x890>
ffffffffc020127e:	9d2ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201282:	00005697          	auipc	a3,0x5
ffffffffc0201286:	8de68693          	addi	a3,a3,-1826 # ffffffffc0205b60 <commands+0xad0>
ffffffffc020128a:	00004617          	auipc	a2,0x4
ffffffffc020128e:	67e60613          	addi	a2,a2,1662 # ffffffffc0205908 <commands+0x878>
ffffffffc0201292:	10600593          	li	a1,262
ffffffffc0201296:	00004517          	auipc	a0,0x4
ffffffffc020129a:	68a50513          	addi	a0,a0,1674 # ffffffffc0205920 <commands+0x890>
ffffffffc020129e:	9b2ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02012a2:	00005697          	auipc	a3,0x5
ffffffffc02012a6:	88e68693          	addi	a3,a3,-1906 # ffffffffc0205b30 <commands+0xaa0>
ffffffffc02012aa:	00004617          	auipc	a2,0x4
ffffffffc02012ae:	65e60613          	addi	a2,a2,1630 # ffffffffc0205908 <commands+0x878>
ffffffffc02012b2:	10500593          	li	a1,261
ffffffffc02012b6:	00004517          	auipc	a0,0x4
ffffffffc02012ba:	66a50513          	addi	a0,a0,1642 # ffffffffc0205920 <commands+0x890>
ffffffffc02012be:	992ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02012c2:	00005697          	auipc	a3,0x5
ffffffffc02012c6:	85668693          	addi	a3,a3,-1962 # ffffffffc0205b18 <commands+0xa88>
ffffffffc02012ca:	00004617          	auipc	a2,0x4
ffffffffc02012ce:	63e60613          	addi	a2,a2,1598 # ffffffffc0205908 <commands+0x878>
ffffffffc02012d2:	10400593          	li	a1,260
ffffffffc02012d6:	00004517          	auipc	a0,0x4
ffffffffc02012da:	64a50513          	addi	a0,a0,1610 # ffffffffc0205920 <commands+0x890>
ffffffffc02012de:	972ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012e2:	00004697          	auipc	a3,0x4
ffffffffc02012e6:	79e68693          	addi	a3,a3,1950 # ffffffffc0205a80 <commands+0x9f0>
ffffffffc02012ea:	00004617          	auipc	a2,0x4
ffffffffc02012ee:	61e60613          	addi	a2,a2,1566 # ffffffffc0205908 <commands+0x878>
ffffffffc02012f2:	0fe00593          	li	a1,254
ffffffffc02012f6:	00004517          	auipc	a0,0x4
ffffffffc02012fa:	62a50513          	addi	a0,a0,1578 # ffffffffc0205920 <commands+0x890>
ffffffffc02012fe:	952ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201302:	00004697          	auipc	a3,0x4
ffffffffc0201306:	7fe68693          	addi	a3,a3,2046 # ffffffffc0205b00 <commands+0xa70>
ffffffffc020130a:	00004617          	auipc	a2,0x4
ffffffffc020130e:	5fe60613          	addi	a2,a2,1534 # ffffffffc0205908 <commands+0x878>
ffffffffc0201312:	0f900593          	li	a1,249
ffffffffc0201316:	00004517          	auipc	a0,0x4
ffffffffc020131a:	60a50513          	addi	a0,a0,1546 # ffffffffc0205920 <commands+0x890>
ffffffffc020131e:	932ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201322:	00005697          	auipc	a3,0x5
ffffffffc0201326:	8fe68693          	addi	a3,a3,-1794 # ffffffffc0205c20 <commands+0xb90>
ffffffffc020132a:	00004617          	auipc	a2,0x4
ffffffffc020132e:	5de60613          	addi	a2,a2,1502 # ffffffffc0205908 <commands+0x878>
ffffffffc0201332:	11700593          	li	a1,279
ffffffffc0201336:	00004517          	auipc	a0,0x4
ffffffffc020133a:	5ea50513          	addi	a0,a0,1514 # ffffffffc0205920 <commands+0x890>
ffffffffc020133e:	912ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(total == 0);
ffffffffc0201342:	00005697          	auipc	a3,0x5
ffffffffc0201346:	90e68693          	addi	a3,a3,-1778 # ffffffffc0205c50 <commands+0xbc0>
ffffffffc020134a:	00004617          	auipc	a2,0x4
ffffffffc020134e:	5be60613          	addi	a2,a2,1470 # ffffffffc0205908 <commands+0x878>
ffffffffc0201352:	12600593          	li	a1,294
ffffffffc0201356:	00004517          	auipc	a0,0x4
ffffffffc020135a:	5ca50513          	addi	a0,a0,1482 # ffffffffc0205920 <commands+0x890>
ffffffffc020135e:	8f2ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(total == nr_free_pages());
ffffffffc0201362:	00004697          	auipc	a3,0x4
ffffffffc0201366:	5d668693          	addi	a3,a3,1494 # ffffffffc0205938 <commands+0x8a8>
ffffffffc020136a:	00004617          	auipc	a2,0x4
ffffffffc020136e:	59e60613          	addi	a2,a2,1438 # ffffffffc0205908 <commands+0x878>
ffffffffc0201372:	0f300593          	li	a1,243
ffffffffc0201376:	00004517          	auipc	a0,0x4
ffffffffc020137a:	5aa50513          	addi	a0,a0,1450 # ffffffffc0205920 <commands+0x890>
ffffffffc020137e:	8d2ff0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201382:	00004697          	auipc	a3,0x4
ffffffffc0201386:	5f668693          	addi	a3,a3,1526 # ffffffffc0205978 <commands+0x8e8>
ffffffffc020138a:	00004617          	auipc	a2,0x4
ffffffffc020138e:	57e60613          	addi	a2,a2,1406 # ffffffffc0205908 <commands+0x878>
ffffffffc0201392:	0ba00593          	li	a1,186
ffffffffc0201396:	00004517          	auipc	a0,0x4
ffffffffc020139a:	58a50513          	addi	a0,a0,1418 # ffffffffc0205920 <commands+0x890>
ffffffffc020139e:	8b2ff0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc02013a2 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc02013a2:	1141                	addi	sp,sp,-16
ffffffffc02013a4:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02013a6:	18058063          	beqz	a1,ffffffffc0201526 <default_free_pages+0x184>
    for (; p != base + n; p ++) {
ffffffffc02013aa:	00359693          	slli	a3,a1,0x3
ffffffffc02013ae:	96ae                	add	a3,a3,a1
ffffffffc02013b0:	068e                	slli	a3,a3,0x3
ffffffffc02013b2:	96aa                	add	a3,a3,a0
ffffffffc02013b4:	02d50d63          	beq	a0,a3,ffffffffc02013ee <default_free_pages+0x4c>
ffffffffc02013b8:	651c                	ld	a5,8(a0)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02013ba:	8b85                	andi	a5,a5,1
ffffffffc02013bc:	14079563          	bnez	a5,ffffffffc0201506 <default_free_pages+0x164>
ffffffffc02013c0:	651c                	ld	a5,8(a0)
ffffffffc02013c2:	8385                	srli	a5,a5,0x1
ffffffffc02013c4:	8b85                	andi	a5,a5,1
ffffffffc02013c6:	14079063          	bnez	a5,ffffffffc0201506 <default_free_pages+0x164>
ffffffffc02013ca:	87aa                	mv	a5,a0
ffffffffc02013cc:	a809                	j	ffffffffc02013de <default_free_pages+0x3c>
ffffffffc02013ce:	6798                	ld	a4,8(a5)
ffffffffc02013d0:	8b05                	andi	a4,a4,1
ffffffffc02013d2:	12071a63          	bnez	a4,ffffffffc0201506 <default_free_pages+0x164>
ffffffffc02013d6:	6798                	ld	a4,8(a5)
ffffffffc02013d8:	8b09                	andi	a4,a4,2
ffffffffc02013da:	12071663          	bnez	a4,ffffffffc0201506 <default_free_pages+0x164>
        p->flags = 0;
ffffffffc02013de:	0007b423          	sd	zero,8(a5)
    return page->ref;
}

static inline void
set_page_ref(struct Page *page, int val) {
    page->ref = val;
ffffffffc02013e2:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02013e6:	04878793          	addi	a5,a5,72
ffffffffc02013ea:	fed792e3          	bne	a5,a3,ffffffffc02013ce <default_free_pages+0x2c>
    base->property = n;
ffffffffc02013ee:	2581                	sext.w	a1,a1
ffffffffc02013f0:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02013f2:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02013f6:	4789                	li	a5,2
ffffffffc02013f8:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02013fc:	00014697          	auipc	a3,0x14
ffffffffc0201400:	0d468693          	addi	a3,a3,212 # ffffffffc02154d0 <free_area>
ffffffffc0201404:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201406:	669c                	ld	a5,8(a3)
ffffffffc0201408:	9db9                	addw	a1,a1,a4
ffffffffc020140a:	00014717          	auipc	a4,0x14
ffffffffc020140e:	0cb72b23          	sw	a1,214(a4) # ffffffffc02154e0 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc0201412:	08d78f63          	beq	a5,a3,ffffffffc02014b0 <default_free_pages+0x10e>
            struct Page* page = le2page(le, page_link);
ffffffffc0201416:	fe078713          	addi	a4,a5,-32
ffffffffc020141a:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020141c:	4801                	li	a6,0
ffffffffc020141e:	02050613          	addi	a2,a0,32
            if (base < page) {
ffffffffc0201422:	00e56a63          	bltu	a0,a4,ffffffffc0201436 <default_free_pages+0x94>
    return listelm->next;
ffffffffc0201426:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201428:	02d70563          	beq	a4,a3,ffffffffc0201452 <default_free_pages+0xb0>
        while ((le = list_next(le)) != &free_list) {
ffffffffc020142c:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020142e:	fe078713          	addi	a4,a5,-32
            if (base < page) {
ffffffffc0201432:	fee57ae3          	bleu	a4,a0,ffffffffc0201426 <default_free_pages+0x84>
ffffffffc0201436:	00080663          	beqz	a6,ffffffffc0201442 <default_free_pages+0xa0>
ffffffffc020143a:	00014817          	auipc	a6,0x14
ffffffffc020143e:	08b83b23          	sd	a1,150(a6) # ffffffffc02154d0 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201442:	638c                	ld	a1,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201444:	e390                	sd	a2,0(a5)
ffffffffc0201446:	e590                	sd	a2,8(a1)
    elm->next = next;
ffffffffc0201448:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc020144a:	f10c                	sd	a1,32(a0)
    if (le != &free_list) {
ffffffffc020144c:	02d59163          	bne	a1,a3,ffffffffc020146e <default_free_pages+0xcc>
ffffffffc0201450:	a091                	j	ffffffffc0201494 <default_free_pages+0xf2>
    prev->next = next->prev = elm;
ffffffffc0201452:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201454:	f514                	sd	a3,40(a0)
ffffffffc0201456:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201458:	f11c                	sd	a5,32(a0)
                list_add(le, &(base->page_link));
ffffffffc020145a:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc020145c:	00d70563          	beq	a4,a3,ffffffffc0201466 <default_free_pages+0xc4>
ffffffffc0201460:	4805                	li	a6,1
ffffffffc0201462:	87ba                	mv	a5,a4
ffffffffc0201464:	b7e9                	j	ffffffffc020142e <default_free_pages+0x8c>
ffffffffc0201466:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc0201468:	85be                	mv	a1,a5
    if (le != &free_list) {
ffffffffc020146a:	02d78163          	beq	a5,a3,ffffffffc020148c <default_free_pages+0xea>
        if (p + p->property == base) {
ffffffffc020146e:	ff05a803          	lw	a6,-16(a1)
        p = le2page(le, page_link);
ffffffffc0201472:	fe058613          	addi	a2,a1,-32
        if (p + p->property == base) {
ffffffffc0201476:	02081713          	slli	a4,a6,0x20
ffffffffc020147a:	9301                	srli	a4,a4,0x20
ffffffffc020147c:	00371793          	slli	a5,a4,0x3
ffffffffc0201480:	97ba                	add	a5,a5,a4
ffffffffc0201482:	078e                	slli	a5,a5,0x3
ffffffffc0201484:	97b2                	add	a5,a5,a2
ffffffffc0201486:	02f50e63          	beq	a0,a5,ffffffffc02014c2 <default_free_pages+0x120>
ffffffffc020148a:	751c                	ld	a5,40(a0)
    if (le != &free_list) {
ffffffffc020148c:	fe078713          	addi	a4,a5,-32
ffffffffc0201490:	00d78d63          	beq	a5,a3,ffffffffc02014aa <default_free_pages+0x108>
        if (base + base->property == p) {
ffffffffc0201494:	490c                	lw	a1,16(a0)
ffffffffc0201496:	02059613          	slli	a2,a1,0x20
ffffffffc020149a:	9201                	srli	a2,a2,0x20
ffffffffc020149c:	00361693          	slli	a3,a2,0x3
ffffffffc02014a0:	96b2                	add	a3,a3,a2
ffffffffc02014a2:	068e                	slli	a3,a3,0x3
ffffffffc02014a4:	96aa                	add	a3,a3,a0
ffffffffc02014a6:	04d70063          	beq	a4,a3,ffffffffc02014e6 <default_free_pages+0x144>
}
ffffffffc02014aa:	60a2                	ld	ra,8(sp)
ffffffffc02014ac:	0141                	addi	sp,sp,16
ffffffffc02014ae:	8082                	ret
ffffffffc02014b0:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02014b2:	02050713          	addi	a4,a0,32
    prev->next = next->prev = elm;
ffffffffc02014b6:	e398                	sd	a4,0(a5)
ffffffffc02014b8:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc02014ba:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc02014bc:	f11c                	sd	a5,32(a0)
}
ffffffffc02014be:	0141                	addi	sp,sp,16
ffffffffc02014c0:	8082                	ret
            p->property += base->property;
ffffffffc02014c2:	491c                	lw	a5,16(a0)
ffffffffc02014c4:	0107883b          	addw	a6,a5,a6
ffffffffc02014c8:	ff05a823          	sw	a6,-16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02014cc:	57f5                	li	a5,-3
ffffffffc02014ce:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02014d2:	02053803          	ld	a6,32(a0)
ffffffffc02014d6:	7518                	ld	a4,40(a0)
            base = p;
ffffffffc02014d8:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02014da:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc02014de:	659c                	ld	a5,8(a1)
ffffffffc02014e0:	01073023          	sd	a6,0(a4)
ffffffffc02014e4:	b765                	j	ffffffffc020148c <default_free_pages+0xea>
            base->property += p->property;
ffffffffc02014e6:	ff07a703          	lw	a4,-16(a5)
ffffffffc02014ea:	fe878693          	addi	a3,a5,-24
ffffffffc02014ee:	9db9                	addw	a1,a1,a4
ffffffffc02014f0:	c90c                	sw	a1,16(a0)
ffffffffc02014f2:	5775                	li	a4,-3
ffffffffc02014f4:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02014f8:	6398                	ld	a4,0(a5)
ffffffffc02014fa:	679c                	ld	a5,8(a5)
}
ffffffffc02014fc:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02014fe:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201500:	e398                	sd	a4,0(a5)
ffffffffc0201502:	0141                	addi	sp,sp,16
ffffffffc0201504:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201506:	00004697          	auipc	a3,0x4
ffffffffc020150a:	75a68693          	addi	a3,a3,1882 # ffffffffc0205c60 <commands+0xbd0>
ffffffffc020150e:	00004617          	auipc	a2,0x4
ffffffffc0201512:	3fa60613          	addi	a2,a2,1018 # ffffffffc0205908 <commands+0x878>
ffffffffc0201516:	08300593          	li	a1,131
ffffffffc020151a:	00004517          	auipc	a0,0x4
ffffffffc020151e:	40650513          	addi	a0,a0,1030 # ffffffffc0205920 <commands+0x890>
ffffffffc0201522:	f2ffe0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(n > 0);
ffffffffc0201526:	00004697          	auipc	a3,0x4
ffffffffc020152a:	76268693          	addi	a3,a3,1890 # ffffffffc0205c88 <commands+0xbf8>
ffffffffc020152e:	00004617          	auipc	a2,0x4
ffffffffc0201532:	3da60613          	addi	a2,a2,986 # ffffffffc0205908 <commands+0x878>
ffffffffc0201536:	08000593          	li	a1,128
ffffffffc020153a:	00004517          	auipc	a0,0x4
ffffffffc020153e:	3e650513          	addi	a0,a0,998 # ffffffffc0205920 <commands+0x890>
ffffffffc0201542:	f0ffe0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc0201546 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201546:	cd51                	beqz	a0,ffffffffc02015e2 <default_alloc_pages+0x9c>
    if (n > nr_free) {
ffffffffc0201548:	00014597          	auipc	a1,0x14
ffffffffc020154c:	f8858593          	addi	a1,a1,-120 # ffffffffc02154d0 <free_area>
ffffffffc0201550:	0105a803          	lw	a6,16(a1)
ffffffffc0201554:	862a                	mv	a2,a0
ffffffffc0201556:	02081793          	slli	a5,a6,0x20
ffffffffc020155a:	9381                	srli	a5,a5,0x20
ffffffffc020155c:	00a7ee63          	bltu	a5,a0,ffffffffc0201578 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201560:	87ae                	mv	a5,a1
ffffffffc0201562:	a801                	j	ffffffffc0201572 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0201564:	ff07a703          	lw	a4,-16(a5)
ffffffffc0201568:	02071693          	slli	a3,a4,0x20
ffffffffc020156c:	9281                	srli	a3,a3,0x20
ffffffffc020156e:	00c6f763          	bleu	a2,a3,ffffffffc020157c <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201572:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201574:	feb798e3          	bne	a5,a1,ffffffffc0201564 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201578:	4501                	li	a0,0
}
ffffffffc020157a:	8082                	ret
        struct Page *p = le2page(le, page_link);
ffffffffc020157c:	fe078513          	addi	a0,a5,-32
    if (page != NULL) {
ffffffffc0201580:	dd6d                	beqz	a0,ffffffffc020157a <default_alloc_pages+0x34>
    return listelm->prev;
ffffffffc0201582:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201586:	0087b303          	ld	t1,8(a5)
    prev->next = next;
ffffffffc020158a:	00060e1b          	sext.w	t3,a2
ffffffffc020158e:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201592:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc0201596:	02d67b63          	bleu	a3,a2,ffffffffc02015cc <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc020159a:	00361693          	slli	a3,a2,0x3
ffffffffc020159e:	96b2                	add	a3,a3,a2
ffffffffc02015a0:	068e                	slli	a3,a3,0x3
ffffffffc02015a2:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc02015a4:	41c7073b          	subw	a4,a4,t3
ffffffffc02015a8:	ca98                	sw	a4,16(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02015aa:	00868613          	addi	a2,a3,8
ffffffffc02015ae:	4709                	li	a4,2
ffffffffc02015b0:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02015b4:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02015b8:	02068613          	addi	a2,a3,32
    prev->next = next->prev = elm;
ffffffffc02015bc:	0105a803          	lw	a6,16(a1)
ffffffffc02015c0:	e310                	sd	a2,0(a4)
ffffffffc02015c2:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc02015c6:	f698                	sd	a4,40(a3)
    elm->prev = prev;
ffffffffc02015c8:	0316b023          	sd	a7,32(a3)
        nr_free -= n;
ffffffffc02015cc:	41c8083b          	subw	a6,a6,t3
ffffffffc02015d0:	00014717          	auipc	a4,0x14
ffffffffc02015d4:	f1072823          	sw	a6,-240(a4) # ffffffffc02154e0 <free_area+0x10>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02015d8:	5775                	li	a4,-3
ffffffffc02015da:	17a1                	addi	a5,a5,-24
ffffffffc02015dc:	60e7b02f          	amoand.d	zero,a4,(a5)
ffffffffc02015e0:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc02015e2:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02015e4:	00004697          	auipc	a3,0x4
ffffffffc02015e8:	6a468693          	addi	a3,a3,1700 # ffffffffc0205c88 <commands+0xbf8>
ffffffffc02015ec:	00004617          	auipc	a2,0x4
ffffffffc02015f0:	31c60613          	addi	a2,a2,796 # ffffffffc0205908 <commands+0x878>
ffffffffc02015f4:	06200593          	li	a1,98
ffffffffc02015f8:	00004517          	auipc	a0,0x4
ffffffffc02015fc:	32850513          	addi	a0,a0,808 # ffffffffc0205920 <commands+0x890>
default_alloc_pages(size_t n) {
ffffffffc0201600:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201602:	e4ffe0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc0201606 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0201606:	1141                	addi	sp,sp,-16
ffffffffc0201608:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020160a:	c1fd                	beqz	a1,ffffffffc02016f0 <default_init_memmap+0xea>
    for (; p != base + n; p ++) {
ffffffffc020160c:	00359693          	slli	a3,a1,0x3
ffffffffc0201610:	96ae                	add	a3,a3,a1
ffffffffc0201612:	068e                	slli	a3,a3,0x3
ffffffffc0201614:	96aa                	add	a3,a3,a0
ffffffffc0201616:	02d50463          	beq	a0,a3,ffffffffc020163e <default_init_memmap+0x38>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020161a:	6518                	ld	a4,8(a0)
        assert(PageReserved(p));
ffffffffc020161c:	87aa                	mv	a5,a0
ffffffffc020161e:	8b05                	andi	a4,a4,1
ffffffffc0201620:	e709                	bnez	a4,ffffffffc020162a <default_init_memmap+0x24>
ffffffffc0201622:	a07d                	j	ffffffffc02016d0 <default_init_memmap+0xca>
ffffffffc0201624:	6798                	ld	a4,8(a5)
ffffffffc0201626:	8b05                	andi	a4,a4,1
ffffffffc0201628:	c745                	beqz	a4,ffffffffc02016d0 <default_init_memmap+0xca>
        p->flags = p->property = 0;
ffffffffc020162a:	0007a823          	sw	zero,16(a5)
ffffffffc020162e:	0007b423          	sd	zero,8(a5)
ffffffffc0201632:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201636:	04878793          	addi	a5,a5,72
ffffffffc020163a:	fed795e3          	bne	a5,a3,ffffffffc0201624 <default_init_memmap+0x1e>
    base->property = n;
ffffffffc020163e:	2581                	sext.w	a1,a1
ffffffffc0201640:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201642:	4789                	li	a5,2
ffffffffc0201644:	00850713          	addi	a4,a0,8
ffffffffc0201648:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc020164c:	00014697          	auipc	a3,0x14
ffffffffc0201650:	e8468693          	addi	a3,a3,-380 # ffffffffc02154d0 <free_area>
ffffffffc0201654:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201656:	669c                	ld	a5,8(a3)
ffffffffc0201658:	9db9                	addw	a1,a1,a4
ffffffffc020165a:	00014717          	auipc	a4,0x14
ffffffffc020165e:	e8b72323          	sw	a1,-378(a4) # ffffffffc02154e0 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc0201662:	04d78a63          	beq	a5,a3,ffffffffc02016b6 <default_init_memmap+0xb0>
            struct Page* page = le2page(le, page_link);
ffffffffc0201666:	fe078713          	addi	a4,a5,-32
ffffffffc020166a:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020166c:	4801                	li	a6,0
ffffffffc020166e:	02050613          	addi	a2,a0,32
            if (base < page) {
ffffffffc0201672:	00e56a63          	bltu	a0,a4,ffffffffc0201686 <default_init_memmap+0x80>
    return listelm->next;
ffffffffc0201676:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201678:	02d70563          	beq	a4,a3,ffffffffc02016a2 <default_init_memmap+0x9c>
        while ((le = list_next(le)) != &free_list) {
ffffffffc020167c:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020167e:	fe078713          	addi	a4,a5,-32
            if (base < page) {
ffffffffc0201682:	fee57ae3          	bleu	a4,a0,ffffffffc0201676 <default_init_memmap+0x70>
ffffffffc0201686:	00080663          	beqz	a6,ffffffffc0201692 <default_init_memmap+0x8c>
ffffffffc020168a:	00014717          	auipc	a4,0x14
ffffffffc020168e:	e4b73323          	sd	a1,-442(a4) # ffffffffc02154d0 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201692:	6398                	ld	a4,0(a5)
}
ffffffffc0201694:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201696:	e390                	sd	a2,0(a5)
ffffffffc0201698:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020169a:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc020169c:	f118                	sd	a4,32(a0)
ffffffffc020169e:	0141                	addi	sp,sp,16
ffffffffc02016a0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02016a2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02016a4:	f514                	sd	a3,40(a0)
ffffffffc02016a6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02016a8:	f11c                	sd	a5,32(a0)
                list_add(le, &(base->page_link));
ffffffffc02016aa:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02016ac:	00d70e63          	beq	a4,a3,ffffffffc02016c8 <default_init_memmap+0xc2>
ffffffffc02016b0:	4805                	li	a6,1
ffffffffc02016b2:	87ba                	mv	a5,a4
ffffffffc02016b4:	b7e9                	j	ffffffffc020167e <default_init_memmap+0x78>
}
ffffffffc02016b6:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02016b8:	02050713          	addi	a4,a0,32
    prev->next = next->prev = elm;
ffffffffc02016bc:	e398                	sd	a4,0(a5)
ffffffffc02016be:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc02016c0:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc02016c2:	f11c                	sd	a5,32(a0)
}
ffffffffc02016c4:	0141                	addi	sp,sp,16
ffffffffc02016c6:	8082                	ret
ffffffffc02016c8:	60a2                	ld	ra,8(sp)
ffffffffc02016ca:	e290                	sd	a2,0(a3)
ffffffffc02016cc:	0141                	addi	sp,sp,16
ffffffffc02016ce:	8082                	ret
        assert(PageReserved(p));
ffffffffc02016d0:	00004697          	auipc	a3,0x4
ffffffffc02016d4:	5c068693          	addi	a3,a3,1472 # ffffffffc0205c90 <commands+0xc00>
ffffffffc02016d8:	00004617          	auipc	a2,0x4
ffffffffc02016dc:	23060613          	addi	a2,a2,560 # ffffffffc0205908 <commands+0x878>
ffffffffc02016e0:	04900593          	li	a1,73
ffffffffc02016e4:	00004517          	auipc	a0,0x4
ffffffffc02016e8:	23c50513          	addi	a0,a0,572 # ffffffffc0205920 <commands+0x890>
ffffffffc02016ec:	d65fe0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(n > 0);
ffffffffc02016f0:	00004697          	auipc	a3,0x4
ffffffffc02016f4:	59868693          	addi	a3,a3,1432 # ffffffffc0205c88 <commands+0xbf8>
ffffffffc02016f8:	00004617          	auipc	a2,0x4
ffffffffc02016fc:	21060613          	addi	a2,a2,528 # ffffffffc0205908 <commands+0x878>
ffffffffc0201700:	04600593          	li	a1,70
ffffffffc0201704:	00004517          	auipc	a0,0x4
ffffffffc0201708:	21c50513          	addi	a0,a0,540 # ffffffffc0205920 <commands+0x890>
ffffffffc020170c:	d45fe0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc0201710 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201710:	c125                	beqz	a0,ffffffffc0201770 <slob_free+0x60>
		return;

	if (size)
ffffffffc0201712:	e1a5                	bnez	a1,ffffffffc0201772 <slob_free+0x62>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201714:	100027f3          	csrr	a5,sstatus
ffffffffc0201718:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020171a:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020171c:	e3bd                	bnez	a5,ffffffffc0201782 <slob_free+0x72>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020171e:	00009797          	auipc	a5,0x9
ffffffffc0201722:	93278793          	addi	a5,a5,-1742 # ffffffffc020a050 <slobfree>
ffffffffc0201726:	639c                	ld	a5,0(a5)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201728:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020172a:	00a7fa63          	bleu	a0,a5,ffffffffc020173e <slob_free+0x2e>
ffffffffc020172e:	00e56c63          	bltu	a0,a4,ffffffffc0201746 <slob_free+0x36>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201732:	00e7fa63          	bleu	a4,a5,ffffffffc0201746 <slob_free+0x36>
    return 0;
ffffffffc0201736:	87ba                	mv	a5,a4
ffffffffc0201738:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020173a:	fea7eae3          	bltu	a5,a0,ffffffffc020172e <slob_free+0x1e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020173e:	fee7ece3          	bltu	a5,a4,ffffffffc0201736 <slob_free+0x26>
ffffffffc0201742:	fee57ae3          	bleu	a4,a0,ffffffffc0201736 <slob_free+0x26>
			break;

	if (b + b->units == cur->next) {
ffffffffc0201746:	4110                	lw	a2,0(a0)
ffffffffc0201748:	00461693          	slli	a3,a2,0x4
ffffffffc020174c:	96aa                	add	a3,a3,a0
ffffffffc020174e:	08d70b63          	beq	a4,a3,ffffffffc02017e4 <slob_free+0xd4>
		b->units += cur->next->units;
		b->next = cur->next->next;
	} else
		b->next = cur->next;

	if (cur + cur->units == b) {
ffffffffc0201752:	4394                	lw	a3,0(a5)
		b->next = cur->next;
ffffffffc0201754:	e518                	sd	a4,8(a0)
	if (cur + cur->units == b) {
ffffffffc0201756:	00469713          	slli	a4,a3,0x4
ffffffffc020175a:	973e                	add	a4,a4,a5
ffffffffc020175c:	08e50f63          	beq	a0,a4,ffffffffc02017fa <slob_free+0xea>
		cur->units += b->units;
		cur->next = b->next;
	} else
		cur->next = b;
ffffffffc0201760:	e788                	sd	a0,8(a5)

	slobfree = cur;
ffffffffc0201762:	00009717          	auipc	a4,0x9
ffffffffc0201766:	8ef73723          	sd	a5,-1810(a4) # ffffffffc020a050 <slobfree>
    if (flag) {
ffffffffc020176a:	c199                	beqz	a1,ffffffffc0201770 <slob_free+0x60>
        intr_enable();
ffffffffc020176c:	e67fe06f          	j	ffffffffc02005d2 <intr_enable>
ffffffffc0201770:	8082                	ret
		b->units = SLOB_UNITS(size);
ffffffffc0201772:	05bd                	addi	a1,a1,15
ffffffffc0201774:	8191                	srli	a1,a1,0x4
ffffffffc0201776:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201778:	100027f3          	csrr	a5,sstatus
ffffffffc020177c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020177e:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201780:	dfd9                	beqz	a5,ffffffffc020171e <slob_free+0xe>
{
ffffffffc0201782:	1101                	addi	sp,sp,-32
ffffffffc0201784:	e42a                	sd	a0,8(sp)
ffffffffc0201786:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201788:	e51fe0ef          	jal	ra,ffffffffc02005d8 <intr_disable>
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020178c:	00009797          	auipc	a5,0x9
ffffffffc0201790:	8c478793          	addi	a5,a5,-1852 # ffffffffc020a050 <slobfree>
ffffffffc0201794:	639c                	ld	a5,0(a5)
        return 1;
ffffffffc0201796:	6522                	ld	a0,8(sp)
ffffffffc0201798:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020179a:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020179c:	00a7fa63          	bleu	a0,a5,ffffffffc02017b0 <slob_free+0xa0>
ffffffffc02017a0:	00e56c63          	bltu	a0,a4,ffffffffc02017b8 <slob_free+0xa8>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02017a4:	00e7fa63          	bleu	a4,a5,ffffffffc02017b8 <slob_free+0xa8>
    return 0;
ffffffffc02017a8:	87ba                	mv	a5,a4
ffffffffc02017aa:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02017ac:	fea7eae3          	bltu	a5,a0,ffffffffc02017a0 <slob_free+0x90>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02017b0:	fee7ece3          	bltu	a5,a4,ffffffffc02017a8 <slob_free+0x98>
ffffffffc02017b4:	fee57ae3          	bleu	a4,a0,ffffffffc02017a8 <slob_free+0x98>
	if (b + b->units == cur->next) {
ffffffffc02017b8:	4110                	lw	a2,0(a0)
ffffffffc02017ba:	00461693          	slli	a3,a2,0x4
ffffffffc02017be:	96aa                	add	a3,a3,a0
ffffffffc02017c0:	04d70763          	beq	a4,a3,ffffffffc020180e <slob_free+0xfe>
		b->next = cur->next;
ffffffffc02017c4:	e518                	sd	a4,8(a0)
	if (cur + cur->units == b) {
ffffffffc02017c6:	4394                	lw	a3,0(a5)
ffffffffc02017c8:	00469713          	slli	a4,a3,0x4
ffffffffc02017cc:	973e                	add	a4,a4,a5
ffffffffc02017ce:	04e50663          	beq	a0,a4,ffffffffc020181a <slob_free+0x10a>
		cur->next = b;
ffffffffc02017d2:	e788                	sd	a0,8(a5)
	slobfree = cur;
ffffffffc02017d4:	00009717          	auipc	a4,0x9
ffffffffc02017d8:	86f73e23          	sd	a5,-1924(a4) # ffffffffc020a050 <slobfree>
    if (flag) {
ffffffffc02017dc:	e58d                	bnez	a1,ffffffffc0201806 <slob_free+0xf6>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc02017de:	60e2                	ld	ra,24(sp)
ffffffffc02017e0:	6105                	addi	sp,sp,32
ffffffffc02017e2:	8082                	ret
		b->units += cur->next->units;
ffffffffc02017e4:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc02017e6:	6718                	ld	a4,8(a4)
		b->units += cur->next->units;
ffffffffc02017e8:	9e35                	addw	a2,a2,a3
ffffffffc02017ea:	c110                	sw	a2,0(a0)
	if (cur + cur->units == b) {
ffffffffc02017ec:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc02017ee:	e518                	sd	a4,8(a0)
	if (cur + cur->units == b) {
ffffffffc02017f0:	00469713          	slli	a4,a3,0x4
ffffffffc02017f4:	973e                	add	a4,a4,a5
ffffffffc02017f6:	f6e515e3          	bne	a0,a4,ffffffffc0201760 <slob_free+0x50>
		cur->units += b->units;
ffffffffc02017fa:	4118                	lw	a4,0(a0)
		cur->next = b->next;
ffffffffc02017fc:	6510                	ld	a2,8(a0)
		cur->units += b->units;
ffffffffc02017fe:	9eb9                	addw	a3,a3,a4
ffffffffc0201800:	c394                	sw	a3,0(a5)
		cur->next = b->next;
ffffffffc0201802:	e790                	sd	a2,8(a5)
ffffffffc0201804:	bfb9                	j	ffffffffc0201762 <slob_free+0x52>
}
ffffffffc0201806:	60e2                	ld	ra,24(sp)
ffffffffc0201808:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020180a:	dc9fe06f          	j	ffffffffc02005d2 <intr_enable>
		b->units += cur->next->units;
ffffffffc020180e:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201810:	6718                	ld	a4,8(a4)
		b->units += cur->next->units;
ffffffffc0201812:	9e35                	addw	a2,a2,a3
ffffffffc0201814:	c110                	sw	a2,0(a0)
		b->next = cur->next->next;
ffffffffc0201816:	e518                	sd	a4,8(a0)
ffffffffc0201818:	b77d                	j	ffffffffc02017c6 <slob_free+0xb6>
		cur->units += b->units;
ffffffffc020181a:	4118                	lw	a4,0(a0)
		cur->next = b->next;
ffffffffc020181c:	6510                	ld	a2,8(a0)
		cur->units += b->units;
ffffffffc020181e:	9eb9                	addw	a3,a3,a4
ffffffffc0201820:	c394                	sw	a3,0(a5)
		cur->next = b->next;
ffffffffc0201822:	e790                	sd	a2,8(a5)
ffffffffc0201824:	bf45                	j	ffffffffc02017d4 <slob_free+0xc4>

ffffffffc0201826 <__slob_get_free_pages.isra.0>:
  struct Page * page = alloc_pages(1 << order);
ffffffffc0201826:	4785                	li	a5,1
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201828:	1141                	addi	sp,sp,-16
  struct Page * page = alloc_pages(1 << order);
ffffffffc020182a:	00a7953b          	sllw	a0,a5,a0
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc020182e:	e406                	sd	ra,8(sp)
  struct Page * page = alloc_pages(1 << order);
ffffffffc0201830:	3a0000ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
  if(!page)
ffffffffc0201834:	c931                	beqz	a0,ffffffffc0201888 <__slob_get_free_pages.isra.0+0x62>
    return page - pages + nbase;
ffffffffc0201836:	00014797          	auipc	a5,0x14
ffffffffc020183a:	cca78793          	addi	a5,a5,-822 # ffffffffc0215500 <pages>
ffffffffc020183e:	6394                	ld	a3,0(a5)
ffffffffc0201840:	00004797          	auipc	a5,0x4
ffffffffc0201844:	0b078793          	addi	a5,a5,176 # ffffffffc02058f0 <commands+0x860>
    return KADDR(page2pa(page));
ffffffffc0201848:	00014717          	auipc	a4,0x14
ffffffffc020184c:	c4870713          	addi	a4,a4,-952 # ffffffffc0215490 <npage>
    return page - pages + nbase;
ffffffffc0201850:	40d506b3          	sub	a3,a0,a3
ffffffffc0201854:	6388                	ld	a0,0(a5)
ffffffffc0201856:	868d                	srai	a3,a3,0x3
ffffffffc0201858:	00005797          	auipc	a5,0x5
ffffffffc020185c:	6f078793          	addi	a5,a5,1776 # ffffffffc0206f48 <nbase>
ffffffffc0201860:	02a686b3          	mul	a3,a3,a0
ffffffffc0201864:	6388                	ld	a0,0(a5)
    return KADDR(page2pa(page));
ffffffffc0201866:	6318                	ld	a4,0(a4)
ffffffffc0201868:	57fd                	li	a5,-1
ffffffffc020186a:	83b1                	srli	a5,a5,0xc
    return page - pages + nbase;
ffffffffc020186c:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc020186e:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0201870:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201872:	00e7ff63          	bleu	a4,a5,ffffffffc0201890 <__slob_get_free_pages.isra.0+0x6a>
ffffffffc0201876:	00014797          	auipc	a5,0x14
ffffffffc020187a:	c7a78793          	addi	a5,a5,-902 # ffffffffc02154f0 <va_pa_offset>
ffffffffc020187e:	6388                	ld	a0,0(a5)
}
ffffffffc0201880:	60a2                	ld	ra,8(sp)
ffffffffc0201882:	9536                	add	a0,a0,a3
ffffffffc0201884:	0141                	addi	sp,sp,16
ffffffffc0201886:	8082                	ret
ffffffffc0201888:	60a2                	ld	ra,8(sp)
    return NULL;
ffffffffc020188a:	4501                	li	a0,0
}
ffffffffc020188c:	0141                	addi	sp,sp,16
ffffffffc020188e:	8082                	ret
ffffffffc0201890:	00004617          	auipc	a2,0x4
ffffffffc0201894:	46060613          	addi	a2,a2,1120 # ffffffffc0205cf0 <default_pmm_manager+0x50>
ffffffffc0201898:	06900593          	li	a1,105
ffffffffc020189c:	00004517          	auipc	a0,0x4
ffffffffc02018a0:	47c50513          	addi	a0,a0,1148 # ffffffffc0205d18 <default_pmm_manager+0x78>
ffffffffc02018a4:	badfe0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc02018a8 <slob_alloc.isra.1.constprop.3>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc02018a8:	7179                	addi	sp,sp,-48
ffffffffc02018aa:	f406                	sd	ra,40(sp)
ffffffffc02018ac:	f022                	sd	s0,32(sp)
ffffffffc02018ae:	ec26                	sd	s1,24(sp)
	assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc02018b0:	01050713          	addi	a4,a0,16
ffffffffc02018b4:	6785                	lui	a5,0x1
ffffffffc02018b6:	0cf77b63          	bleu	a5,a4,ffffffffc020198c <slob_alloc.isra.1.constprop.3+0xe4>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc02018ba:	00f50413          	addi	s0,a0,15
ffffffffc02018be:	8011                	srli	s0,s0,0x4
ffffffffc02018c0:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02018c2:	10002673          	csrr	a2,sstatus
ffffffffc02018c6:	8a09                	andi	a2,a2,2
ffffffffc02018c8:	ea5d                	bnez	a2,ffffffffc020197e <slob_alloc.isra.1.constprop.3+0xd6>
	prev = slobfree;
ffffffffc02018ca:	00008497          	auipc	s1,0x8
ffffffffc02018ce:	78648493          	addi	s1,s1,1926 # ffffffffc020a050 <slobfree>
ffffffffc02018d2:	6094                	ld	a3,0(s1)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc02018d4:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc02018d6:	4398                	lw	a4,0(a5)
ffffffffc02018d8:	0a875763          	ble	s0,a4,ffffffffc0201986 <slob_alloc.isra.1.constprop.3+0xde>
		if (cur == slobfree) {
ffffffffc02018dc:	00f68a63          	beq	a3,a5,ffffffffc02018f0 <slob_alloc.isra.1.constprop.3+0x48>
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc02018e0:	6788                	ld	a0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc02018e2:	4118                	lw	a4,0(a0)
ffffffffc02018e4:	02875763          	ble	s0,a4,ffffffffc0201912 <slob_alloc.isra.1.constprop.3+0x6a>
ffffffffc02018e8:	6094                	ld	a3,0(s1)
ffffffffc02018ea:	87aa                	mv	a5,a0
		if (cur == slobfree) {
ffffffffc02018ec:	fef69ae3          	bne	a3,a5,ffffffffc02018e0 <slob_alloc.isra.1.constprop.3+0x38>
    if (flag) {
ffffffffc02018f0:	ea39                	bnez	a2,ffffffffc0201946 <slob_alloc.isra.1.constprop.3+0x9e>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc02018f2:	4501                	li	a0,0
ffffffffc02018f4:	f33ff0ef          	jal	ra,ffffffffc0201826 <__slob_get_free_pages.isra.0>
			if (!cur)
ffffffffc02018f8:	cd29                	beqz	a0,ffffffffc0201952 <slob_alloc.isra.1.constprop.3+0xaa>
			slob_free(cur, PAGE_SIZE);
ffffffffc02018fa:	6585                	lui	a1,0x1
ffffffffc02018fc:	e15ff0ef          	jal	ra,ffffffffc0201710 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201900:	10002673          	csrr	a2,sstatus
ffffffffc0201904:	8a09                	andi	a2,a2,2
ffffffffc0201906:	ea1d                	bnez	a2,ffffffffc020193c <slob_alloc.isra.1.constprop.3+0x94>
			cur = slobfree;
ffffffffc0201908:	609c                	ld	a5,0(s1)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc020190a:	6788                	ld	a0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc020190c:	4118                	lw	a4,0(a0)
ffffffffc020190e:	fc874de3          	blt	a4,s0,ffffffffc02018e8 <slob_alloc.isra.1.constprop.3+0x40>
			if (cur->units == units) /* exact fit? */
ffffffffc0201912:	04e40663          	beq	s0,a4,ffffffffc020195e <slob_alloc.isra.1.constprop.3+0xb6>
				prev->next = cur + units;
ffffffffc0201916:	00441693          	slli	a3,s0,0x4
ffffffffc020191a:	96aa                	add	a3,a3,a0
ffffffffc020191c:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc020191e:	650c                	ld	a1,8(a0)
				prev->next->units = cur->units - units;
ffffffffc0201920:	9f01                	subw	a4,a4,s0
ffffffffc0201922:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201924:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201926:	c100                	sw	s0,0(a0)
			slobfree = prev;
ffffffffc0201928:	00008717          	auipc	a4,0x8
ffffffffc020192c:	72f73423          	sd	a5,1832(a4) # ffffffffc020a050 <slobfree>
    if (flag) {
ffffffffc0201930:	ee15                	bnez	a2,ffffffffc020196c <slob_alloc.isra.1.constprop.3+0xc4>
}
ffffffffc0201932:	70a2                	ld	ra,40(sp)
ffffffffc0201934:	7402                	ld	s0,32(sp)
ffffffffc0201936:	64e2                	ld	s1,24(sp)
ffffffffc0201938:	6145                	addi	sp,sp,48
ffffffffc020193a:	8082                	ret
        intr_disable();
ffffffffc020193c:	c9dfe0ef          	jal	ra,ffffffffc02005d8 <intr_disable>
ffffffffc0201940:	4605                	li	a2,1
			cur = slobfree;
ffffffffc0201942:	609c                	ld	a5,0(s1)
ffffffffc0201944:	b7d9                	j	ffffffffc020190a <slob_alloc.isra.1.constprop.3+0x62>
        intr_enable();
ffffffffc0201946:	c8dfe0ef          	jal	ra,ffffffffc02005d2 <intr_enable>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc020194a:	4501                	li	a0,0
ffffffffc020194c:	edbff0ef          	jal	ra,ffffffffc0201826 <__slob_get_free_pages.isra.0>
			if (!cur)
ffffffffc0201950:	f54d                	bnez	a0,ffffffffc02018fa <slob_alloc.isra.1.constprop.3+0x52>
}
ffffffffc0201952:	70a2                	ld	ra,40(sp)
ffffffffc0201954:	7402                	ld	s0,32(sp)
ffffffffc0201956:	64e2                	ld	s1,24(sp)
				return 0;
ffffffffc0201958:	4501                	li	a0,0
}
ffffffffc020195a:	6145                	addi	sp,sp,48
ffffffffc020195c:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc020195e:	6518                	ld	a4,8(a0)
ffffffffc0201960:	e798                	sd	a4,8(a5)
			slobfree = prev;
ffffffffc0201962:	00008717          	auipc	a4,0x8
ffffffffc0201966:	6ef73723          	sd	a5,1774(a4) # ffffffffc020a050 <slobfree>
    if (flag) {
ffffffffc020196a:	d661                	beqz	a2,ffffffffc0201932 <slob_alloc.isra.1.constprop.3+0x8a>
ffffffffc020196c:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020196e:	c65fe0ef          	jal	ra,ffffffffc02005d2 <intr_enable>
}
ffffffffc0201972:	70a2                	ld	ra,40(sp)
ffffffffc0201974:	7402                	ld	s0,32(sp)
ffffffffc0201976:	6522                	ld	a0,8(sp)
ffffffffc0201978:	64e2                	ld	s1,24(sp)
ffffffffc020197a:	6145                	addi	sp,sp,48
ffffffffc020197c:	8082                	ret
        intr_disable();
ffffffffc020197e:	c5bfe0ef          	jal	ra,ffffffffc02005d8 <intr_disable>
ffffffffc0201982:	4605                	li	a2,1
ffffffffc0201984:	b799                	j	ffffffffc02018ca <slob_alloc.isra.1.constprop.3+0x22>
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201986:	853e                	mv	a0,a5
ffffffffc0201988:	87b6                	mv	a5,a3
ffffffffc020198a:	b761                	j	ffffffffc0201912 <slob_alloc.isra.1.constprop.3+0x6a>
	assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc020198c:	00004697          	auipc	a3,0x4
ffffffffc0201990:	40468693          	addi	a3,a3,1028 # ffffffffc0205d90 <default_pmm_manager+0xf0>
ffffffffc0201994:	00004617          	auipc	a2,0x4
ffffffffc0201998:	f7460613          	addi	a2,a2,-140 # ffffffffc0205908 <commands+0x878>
ffffffffc020199c:	06300593          	li	a1,99
ffffffffc02019a0:	00004517          	auipc	a0,0x4
ffffffffc02019a4:	41050513          	addi	a0,a0,1040 # ffffffffc0205db0 <default_pmm_manager+0x110>
ffffffffc02019a8:	aa9fe0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc02019ac <kmalloc_init>:
slob_init(void) {
  cprintf("use SLOB allocator\n");
}

inline void 
kmalloc_init(void) {
ffffffffc02019ac:	1141                	addi	sp,sp,-16
  cprintf("use SLOB allocator\n");
ffffffffc02019ae:	00004517          	auipc	a0,0x4
ffffffffc02019b2:	41a50513          	addi	a0,a0,1050 # ffffffffc0205dc8 <default_pmm_manager+0x128>
kmalloc_init(void) {
ffffffffc02019b6:	e406                	sd	ra,8(sp)
  cprintf("use SLOB allocator\n");
ffffffffc02019b8:	fd6fe0ef          	jal	ra,ffffffffc020018e <cprintf>
    slob_init();
    cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc02019bc:	60a2                	ld	ra,8(sp)
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc02019be:	00004517          	auipc	a0,0x4
ffffffffc02019c2:	3b250513          	addi	a0,a0,946 # ffffffffc0205d70 <default_pmm_manager+0xd0>
}
ffffffffc02019c6:	0141                	addi	sp,sp,16
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc02019c8:	fc6fe06f          	j	ffffffffc020018e <cprintf>

ffffffffc02019cc <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc02019cc:	1101                	addi	sp,sp,-32
ffffffffc02019ce:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc02019d0:	6905                	lui	s2,0x1
{
ffffffffc02019d2:	e822                	sd	s0,16(sp)
ffffffffc02019d4:	ec06                	sd	ra,24(sp)
ffffffffc02019d6:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc02019d8:	fef90793          	addi	a5,s2,-17 # fef <BASE_ADDRESS-0xffffffffc01ff011>
{
ffffffffc02019dc:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc02019de:	04a7fc63          	bleu	a0,a5,ffffffffc0201a36 <kmalloc+0x6a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc02019e2:	4561                	li	a0,24
ffffffffc02019e4:	ec5ff0ef          	jal	ra,ffffffffc02018a8 <slob_alloc.isra.1.constprop.3>
ffffffffc02019e8:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc02019ea:	cd21                	beqz	a0,ffffffffc0201a42 <kmalloc+0x76>
	bb->order = find_order(size);
ffffffffc02019ec:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc02019f0:	4501                	li	a0,0
	for ( ; size > 4096 ; size >>=1)
ffffffffc02019f2:	00f95763          	ble	a5,s2,ffffffffc0201a00 <kmalloc+0x34>
ffffffffc02019f6:	6705                	lui	a4,0x1
ffffffffc02019f8:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc02019fa:	2505                	addiw	a0,a0,1
	for ( ; size > 4096 ; size >>=1)
ffffffffc02019fc:	fef74ee3          	blt	a4,a5,ffffffffc02019f8 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201a00:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201a02:	e25ff0ef          	jal	ra,ffffffffc0201826 <__slob_get_free_pages.isra.0>
ffffffffc0201a06:	e488                	sd	a0,8(s1)
ffffffffc0201a08:	842a                	mv	s0,a0
	if (bb->pages) {
ffffffffc0201a0a:	c935                	beqz	a0,ffffffffc0201a7e <kmalloc+0xb2>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a0c:	100027f3          	csrr	a5,sstatus
ffffffffc0201a10:	8b89                	andi	a5,a5,2
ffffffffc0201a12:	e3a1                	bnez	a5,ffffffffc0201a52 <kmalloc+0x86>
		bb->next = bigblocks;
ffffffffc0201a14:	00014797          	auipc	a5,0x14
ffffffffc0201a18:	a6c78793          	addi	a5,a5,-1428 # ffffffffc0215480 <bigblocks>
ffffffffc0201a1c:	639c                	ld	a5,0(a5)
		bigblocks = bb;
ffffffffc0201a1e:	00014717          	auipc	a4,0x14
ffffffffc0201a22:	a6973123          	sd	s1,-1438(a4) # ffffffffc0215480 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201a26:	e89c                	sd	a5,16(s1)
  return __kmalloc(size, 0);
}
ffffffffc0201a28:	8522                	mv	a0,s0
ffffffffc0201a2a:	60e2                	ld	ra,24(sp)
ffffffffc0201a2c:	6442                	ld	s0,16(sp)
ffffffffc0201a2e:	64a2                	ld	s1,8(sp)
ffffffffc0201a30:	6902                	ld	s2,0(sp)
ffffffffc0201a32:	6105                	addi	sp,sp,32
ffffffffc0201a34:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201a36:	0541                	addi	a0,a0,16
ffffffffc0201a38:	e71ff0ef          	jal	ra,ffffffffc02018a8 <slob_alloc.isra.1.constprop.3>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201a3c:	01050413          	addi	s0,a0,16
ffffffffc0201a40:	f565                	bnez	a0,ffffffffc0201a28 <kmalloc+0x5c>
ffffffffc0201a42:	4401                	li	s0,0
}
ffffffffc0201a44:	8522                	mv	a0,s0
ffffffffc0201a46:	60e2                	ld	ra,24(sp)
ffffffffc0201a48:	6442                	ld	s0,16(sp)
ffffffffc0201a4a:	64a2                	ld	s1,8(sp)
ffffffffc0201a4c:	6902                	ld	s2,0(sp)
ffffffffc0201a4e:	6105                	addi	sp,sp,32
ffffffffc0201a50:	8082                	ret
        intr_disable();
ffffffffc0201a52:	b87fe0ef          	jal	ra,ffffffffc02005d8 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201a56:	00014797          	auipc	a5,0x14
ffffffffc0201a5a:	a2a78793          	addi	a5,a5,-1494 # ffffffffc0215480 <bigblocks>
ffffffffc0201a5e:	639c                	ld	a5,0(a5)
		bigblocks = bb;
ffffffffc0201a60:	00014717          	auipc	a4,0x14
ffffffffc0201a64:	a2973023          	sd	s1,-1504(a4) # ffffffffc0215480 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201a68:	e89c                	sd	a5,16(s1)
        intr_enable();
ffffffffc0201a6a:	b69fe0ef          	jal	ra,ffffffffc02005d2 <intr_enable>
ffffffffc0201a6e:	6480                	ld	s0,8(s1)
}
ffffffffc0201a70:	60e2                	ld	ra,24(sp)
ffffffffc0201a72:	64a2                	ld	s1,8(sp)
ffffffffc0201a74:	8522                	mv	a0,s0
ffffffffc0201a76:	6442                	ld	s0,16(sp)
ffffffffc0201a78:	6902                	ld	s2,0(sp)
ffffffffc0201a7a:	6105                	addi	sp,sp,32
ffffffffc0201a7c:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201a7e:	45e1                	li	a1,24
ffffffffc0201a80:	8526                	mv	a0,s1
ffffffffc0201a82:	c8fff0ef          	jal	ra,ffffffffc0201710 <slob_free>
  return __kmalloc(size, 0);
ffffffffc0201a86:	b74d                	j	ffffffffc0201a28 <kmalloc+0x5c>

ffffffffc0201a88 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201a88:	0e050663          	beqz	a0,ffffffffc0201b74 <kfree+0xec>
{
ffffffffc0201a8c:	1101                	addi	sp,sp,-32
ffffffffc0201a8e:	e426                	sd	s1,8(sp)
ffffffffc0201a90:	ec06                	sd	ra,24(sp)
ffffffffc0201a92:	e822                	sd	s0,16(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE-1))) {
ffffffffc0201a94:	03451793          	slli	a5,a0,0x34
ffffffffc0201a98:	84aa                	mv	s1,a0
ffffffffc0201a9a:	eb8d                	bnez	a5,ffffffffc0201acc <kfree+0x44>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a9c:	100027f3          	csrr	a5,sstatus
ffffffffc0201aa0:	8b89                	andi	a5,a5,2
ffffffffc0201aa2:	e3c5                	bnez	a5,ffffffffc0201b42 <kfree+0xba>
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201aa4:	00014797          	auipc	a5,0x14
ffffffffc0201aa8:	9dc78793          	addi	a5,a5,-1572 # ffffffffc0215480 <bigblocks>
ffffffffc0201aac:	6394                	ld	a3,0(a5)
ffffffffc0201aae:	ce99                	beqz	a3,ffffffffc0201acc <kfree+0x44>
			if (bb->pages == block) {
ffffffffc0201ab0:	669c                	ld	a5,8(a3)
ffffffffc0201ab2:	6a80                	ld	s0,16(a3)
ffffffffc0201ab4:	0cf50163          	beq	a0,a5,ffffffffc0201b76 <kfree+0xee>
    return 0;
ffffffffc0201ab8:	4601                	li	a2,0
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201aba:	c801                	beqz	s0,ffffffffc0201aca <kfree+0x42>
			if (bb->pages == block) {
ffffffffc0201abc:	6418                	ld	a4,8(s0)
ffffffffc0201abe:	681c                	ld	a5,16(s0)
ffffffffc0201ac0:	00970f63          	beq	a4,s1,ffffffffc0201ade <kfree+0x56>
ffffffffc0201ac4:	86a2                	mv	a3,s0
ffffffffc0201ac6:	843e                	mv	s0,a5
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201ac8:	f875                	bnez	s0,ffffffffc0201abc <kfree+0x34>
    if (flag) {
ffffffffc0201aca:	ea51                	bnez	a2,ffffffffc0201b5e <kfree+0xd6>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201acc:	6442                	ld	s0,16(sp)
ffffffffc0201ace:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201ad0:	ff048513          	addi	a0,s1,-16
}
ffffffffc0201ad4:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201ad6:	4581                	li	a1,0
}
ffffffffc0201ad8:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201ada:	c37ff06f          	j	ffffffffc0201710 <slob_free>
				*last = bb->next;
ffffffffc0201ade:	ea9c                	sd	a5,16(a3)
ffffffffc0201ae0:	e659                	bnez	a2,ffffffffc0201b6e <kfree+0xe6>
    return pa2page(PADDR(kva));
ffffffffc0201ae2:	c02007b7          	lui	a5,0xc0200
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201ae6:	4018                	lw	a4,0(s0)
ffffffffc0201ae8:	08f4ed63          	bltu	s1,a5,ffffffffc0201b82 <kfree+0xfa>
ffffffffc0201aec:	00014797          	auipc	a5,0x14
ffffffffc0201af0:	a0478793          	addi	a5,a5,-1532 # ffffffffc02154f0 <va_pa_offset>
ffffffffc0201af4:	6394                	ld	a3,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0201af6:	00014797          	auipc	a5,0x14
ffffffffc0201afa:	99a78793          	addi	a5,a5,-1638 # ffffffffc0215490 <npage>
ffffffffc0201afe:	639c                	ld	a5,0(a5)
    return pa2page(PADDR(kva));
ffffffffc0201b00:	8c95                	sub	s1,s1,a3
    if (PPN(pa) >= npage) {
ffffffffc0201b02:	80b1                	srli	s1,s1,0xc
ffffffffc0201b04:	08f4fc63          	bleu	a5,s1,ffffffffc0201b9c <kfree+0x114>
    return &pages[PPN(pa) - nbase];
ffffffffc0201b08:	00005797          	auipc	a5,0x5
ffffffffc0201b0c:	44078793          	addi	a5,a5,1088 # ffffffffc0206f48 <nbase>
ffffffffc0201b10:	639c                	ld	a5,0(a5)
ffffffffc0201b12:	00014697          	auipc	a3,0x14
ffffffffc0201b16:	9ee68693          	addi	a3,a3,-1554 # ffffffffc0215500 <pages>
ffffffffc0201b1a:	6288                	ld	a0,0(a3)
ffffffffc0201b1c:	8c9d                	sub	s1,s1,a5
ffffffffc0201b1e:	00349793          	slli	a5,s1,0x3
ffffffffc0201b22:	94be                	add	s1,s1,a5
ffffffffc0201b24:	048e                	slli	s1,s1,0x3
  free_pages(kva2page(kva), 1 << order);
ffffffffc0201b26:	4585                	li	a1,1
ffffffffc0201b28:	9526                	add	a0,a0,s1
ffffffffc0201b2a:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201b2e:	12a000ef          	jal	ra,ffffffffc0201c58 <free_pages>
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b32:	8522                	mv	a0,s0
}
ffffffffc0201b34:	6442                	ld	s0,16(sp)
ffffffffc0201b36:	60e2                	ld	ra,24(sp)
ffffffffc0201b38:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b3a:	45e1                	li	a1,24
}
ffffffffc0201b3c:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201b3e:	bd3ff06f          	j	ffffffffc0201710 <slob_free>
        intr_disable();
ffffffffc0201b42:	a97fe0ef          	jal	ra,ffffffffc02005d8 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201b46:	00014797          	auipc	a5,0x14
ffffffffc0201b4a:	93a78793          	addi	a5,a5,-1734 # ffffffffc0215480 <bigblocks>
ffffffffc0201b4e:	6394                	ld	a3,0(a5)
ffffffffc0201b50:	c699                	beqz	a3,ffffffffc0201b5e <kfree+0xd6>
			if (bb->pages == block) {
ffffffffc0201b52:	669c                	ld	a5,8(a3)
ffffffffc0201b54:	6a80                	ld	s0,16(a3)
ffffffffc0201b56:	00f48763          	beq	s1,a5,ffffffffc0201b64 <kfree+0xdc>
        return 1;
ffffffffc0201b5a:	4605                	li	a2,1
ffffffffc0201b5c:	bfb9                	j	ffffffffc0201aba <kfree+0x32>
        intr_enable();
ffffffffc0201b5e:	a75fe0ef          	jal	ra,ffffffffc02005d2 <intr_enable>
ffffffffc0201b62:	b7ad                	j	ffffffffc0201acc <kfree+0x44>
				*last = bb->next;
ffffffffc0201b64:	00014797          	auipc	a5,0x14
ffffffffc0201b68:	9087be23          	sd	s0,-1764(a5) # ffffffffc0215480 <bigblocks>
ffffffffc0201b6c:	8436                	mv	s0,a3
ffffffffc0201b6e:	a65fe0ef          	jal	ra,ffffffffc02005d2 <intr_enable>
ffffffffc0201b72:	bf85                	j	ffffffffc0201ae2 <kfree+0x5a>
ffffffffc0201b74:	8082                	ret
ffffffffc0201b76:	00014797          	auipc	a5,0x14
ffffffffc0201b7a:	9087b523          	sd	s0,-1782(a5) # ffffffffc0215480 <bigblocks>
ffffffffc0201b7e:	8436                	mv	s0,a3
ffffffffc0201b80:	b78d                	j	ffffffffc0201ae2 <kfree+0x5a>
    return pa2page(PADDR(kva));
ffffffffc0201b82:	86a6                	mv	a3,s1
ffffffffc0201b84:	00004617          	auipc	a2,0x4
ffffffffc0201b88:	1a460613          	addi	a2,a2,420 # ffffffffc0205d28 <default_pmm_manager+0x88>
ffffffffc0201b8c:	06e00593          	li	a1,110
ffffffffc0201b90:	00004517          	auipc	a0,0x4
ffffffffc0201b94:	18850513          	addi	a0,a0,392 # ffffffffc0205d18 <default_pmm_manager+0x78>
ffffffffc0201b98:	8b9fe0ef          	jal	ra,ffffffffc0200450 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0201b9c:	00004617          	auipc	a2,0x4
ffffffffc0201ba0:	1b460613          	addi	a2,a2,436 # ffffffffc0205d50 <default_pmm_manager+0xb0>
ffffffffc0201ba4:	06200593          	li	a1,98
ffffffffc0201ba8:	00004517          	auipc	a0,0x4
ffffffffc0201bac:	17050513          	addi	a0,a0,368 # ffffffffc0205d18 <default_pmm_manager+0x78>
ffffffffc0201bb0:	8a1fe0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc0201bb4 <pa2page.part.4>:
pa2page(uintptr_t pa) {
ffffffffc0201bb4:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201bb6:	00004617          	auipc	a2,0x4
ffffffffc0201bba:	19a60613          	addi	a2,a2,410 # ffffffffc0205d50 <default_pmm_manager+0xb0>
ffffffffc0201bbe:	06200593          	li	a1,98
ffffffffc0201bc2:	00004517          	auipc	a0,0x4
ffffffffc0201bc6:	15650513          	addi	a0,a0,342 # ffffffffc0205d18 <default_pmm_manager+0x78>
pa2page(uintptr_t pa) {
ffffffffc0201bca:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201bcc:	885fe0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc0201bd0 <alloc_pages>:
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
ffffffffc0201bd0:	715d                	addi	sp,sp,-80
ffffffffc0201bd2:	e0a2                	sd	s0,64(sp)
ffffffffc0201bd4:	fc26                	sd	s1,56(sp)
ffffffffc0201bd6:	f84a                	sd	s2,48(sp)
ffffffffc0201bd8:	f44e                	sd	s3,40(sp)
ffffffffc0201bda:	f052                	sd	s4,32(sp)
ffffffffc0201bdc:	ec56                	sd	s5,24(sp)
ffffffffc0201bde:	e486                	sd	ra,72(sp)
ffffffffc0201be0:	842a                	mv	s0,a0
ffffffffc0201be2:	00014497          	auipc	s1,0x14
ffffffffc0201be6:	90648493          	addi	s1,s1,-1786 # ffffffffc02154e8 <pmm_manager>
        {
            page = pmm_manager->alloc_pages(n);
        }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201bea:	4985                	li	s3,1
ffffffffc0201bec:	00014a17          	auipc	s4,0x14
ffffffffc0201bf0:	8b4a0a13          	addi	s4,s4,-1868 # ffffffffc02154a0 <swap_init_ok>

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
ffffffffc0201bf4:	0005091b          	sext.w	s2,a0
ffffffffc0201bf8:	00014a97          	auipc	s5,0x14
ffffffffc0201bfc:	9f0a8a93          	addi	s5,s5,-1552 # ffffffffc02155e8 <check_mm_struct>
ffffffffc0201c00:	a00d                	j	ffffffffc0201c22 <alloc_pages+0x52>
            page = pmm_manager->alloc_pages(n);
ffffffffc0201c02:	609c                	ld	a5,0(s1)
ffffffffc0201c04:	6f9c                	ld	a5,24(a5)
ffffffffc0201c06:	9782                	jalr	a5
        swap_out(check_mm_struct, n, 0);
ffffffffc0201c08:	4601                	li	a2,0
ffffffffc0201c0a:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201c0c:	ed0d                	bnez	a0,ffffffffc0201c46 <alloc_pages+0x76>
ffffffffc0201c0e:	0289ec63          	bltu	s3,s0,ffffffffc0201c46 <alloc_pages+0x76>
ffffffffc0201c12:	000a2783          	lw	a5,0(s4)
ffffffffc0201c16:	2781                	sext.w	a5,a5
ffffffffc0201c18:	c79d                	beqz	a5,ffffffffc0201c46 <alloc_pages+0x76>
        swap_out(check_mm_struct, n, 0);
ffffffffc0201c1a:	000ab503          	ld	a0,0(s5)
ffffffffc0201c1e:	7aa010ef          	jal	ra,ffffffffc02033c8 <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c22:	100027f3          	csrr	a5,sstatus
ffffffffc0201c26:	8b89                	andi	a5,a5,2
            page = pmm_manager->alloc_pages(n);
ffffffffc0201c28:	8522                	mv	a0,s0
ffffffffc0201c2a:	dfe1                	beqz	a5,ffffffffc0201c02 <alloc_pages+0x32>
        intr_disable();
ffffffffc0201c2c:	9adfe0ef          	jal	ra,ffffffffc02005d8 <intr_disable>
ffffffffc0201c30:	609c                	ld	a5,0(s1)
ffffffffc0201c32:	8522                	mv	a0,s0
ffffffffc0201c34:	6f9c                	ld	a5,24(a5)
ffffffffc0201c36:	9782                	jalr	a5
ffffffffc0201c38:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201c3a:	999fe0ef          	jal	ra,ffffffffc02005d2 <intr_enable>
ffffffffc0201c3e:	6522                	ld	a0,8(sp)
        swap_out(check_mm_struct, n, 0);
ffffffffc0201c40:	4601                	li	a2,0
ffffffffc0201c42:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201c44:	d569                	beqz	a0,ffffffffc0201c0e <alloc_pages+0x3e>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc0201c46:	60a6                	ld	ra,72(sp)
ffffffffc0201c48:	6406                	ld	s0,64(sp)
ffffffffc0201c4a:	74e2                	ld	s1,56(sp)
ffffffffc0201c4c:	7942                	ld	s2,48(sp)
ffffffffc0201c4e:	79a2                	ld	s3,40(sp)
ffffffffc0201c50:	7a02                	ld	s4,32(sp)
ffffffffc0201c52:	6ae2                	ld	s5,24(sp)
ffffffffc0201c54:	6161                	addi	sp,sp,80
ffffffffc0201c56:	8082                	ret

ffffffffc0201c58 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c58:	100027f3          	csrr	a5,sstatus
ffffffffc0201c5c:	8b89                	andi	a5,a5,2
ffffffffc0201c5e:	eb89                	bnez	a5,ffffffffc0201c70 <free_pages+0x18>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201c60:	00014797          	auipc	a5,0x14
ffffffffc0201c64:	88878793          	addi	a5,a5,-1912 # ffffffffc02154e8 <pmm_manager>
ffffffffc0201c68:	639c                	ld	a5,0(a5)
ffffffffc0201c6a:	0207b303          	ld	t1,32(a5)
ffffffffc0201c6e:	8302                	jr	t1
void free_pages(struct Page *base, size_t n) {
ffffffffc0201c70:	1101                	addi	sp,sp,-32
ffffffffc0201c72:	ec06                	sd	ra,24(sp)
ffffffffc0201c74:	e822                	sd	s0,16(sp)
ffffffffc0201c76:	e426                	sd	s1,8(sp)
ffffffffc0201c78:	842a                	mv	s0,a0
ffffffffc0201c7a:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201c7c:	95dfe0ef          	jal	ra,ffffffffc02005d8 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201c80:	00014797          	auipc	a5,0x14
ffffffffc0201c84:	86878793          	addi	a5,a5,-1944 # ffffffffc02154e8 <pmm_manager>
ffffffffc0201c88:	639c                	ld	a5,0(a5)
ffffffffc0201c8a:	85a6                	mv	a1,s1
ffffffffc0201c8c:	8522                	mv	a0,s0
ffffffffc0201c8e:	739c                	ld	a5,32(a5)
ffffffffc0201c90:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201c92:	6442                	ld	s0,16(sp)
ffffffffc0201c94:	60e2                	ld	ra,24(sp)
ffffffffc0201c96:	64a2                	ld	s1,8(sp)
ffffffffc0201c98:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201c9a:	939fe06f          	j	ffffffffc02005d2 <intr_enable>

ffffffffc0201c9e <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c9e:	100027f3          	csrr	a5,sstatus
ffffffffc0201ca2:	8b89                	andi	a5,a5,2
ffffffffc0201ca4:	eb89                	bnez	a5,ffffffffc0201cb6 <nr_free_pages+0x18>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201ca6:	00014797          	auipc	a5,0x14
ffffffffc0201caa:	84278793          	addi	a5,a5,-1982 # ffffffffc02154e8 <pmm_manager>
ffffffffc0201cae:	639c                	ld	a5,0(a5)
ffffffffc0201cb0:	0287b303          	ld	t1,40(a5)
ffffffffc0201cb4:	8302                	jr	t1
size_t nr_free_pages(void) {
ffffffffc0201cb6:	1141                	addi	sp,sp,-16
ffffffffc0201cb8:	e406                	sd	ra,8(sp)
ffffffffc0201cba:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201cbc:	91dfe0ef          	jal	ra,ffffffffc02005d8 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201cc0:	00014797          	auipc	a5,0x14
ffffffffc0201cc4:	82878793          	addi	a5,a5,-2008 # ffffffffc02154e8 <pmm_manager>
ffffffffc0201cc8:	639c                	ld	a5,0(a5)
ffffffffc0201cca:	779c                	ld	a5,40(a5)
ffffffffc0201ccc:	9782                	jalr	a5
ffffffffc0201cce:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201cd0:	903fe0ef          	jal	ra,ffffffffc02005d2 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201cd4:	8522                	mv	a0,s0
ffffffffc0201cd6:	60a2                	ld	ra,8(sp)
ffffffffc0201cd8:	6402                	ld	s0,0(sp)
ffffffffc0201cda:	0141                	addi	sp,sp,16
ffffffffc0201cdc:	8082                	ret

ffffffffc0201cde <get_pte>:
// parameter:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201cde:	715d                	addi	sp,sp,-80
ffffffffc0201ce0:	fc26                	sd	s1,56(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201ce2:	01e5d493          	srli	s1,a1,0x1e
ffffffffc0201ce6:	1ff4f493          	andi	s1,s1,511
ffffffffc0201cea:	048e                	slli	s1,s1,0x3
ffffffffc0201cec:	94aa                	add	s1,s1,a0
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201cee:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201cf0:	f84a                	sd	s2,48(sp)
ffffffffc0201cf2:	f44e                	sd	s3,40(sp)
ffffffffc0201cf4:	f052                	sd	s4,32(sp)
ffffffffc0201cf6:	e486                	sd	ra,72(sp)
ffffffffc0201cf8:	e0a2                	sd	s0,64(sp)
ffffffffc0201cfa:	ec56                	sd	s5,24(sp)
ffffffffc0201cfc:	e85a                	sd	s6,16(sp)
ffffffffc0201cfe:	e45e                	sd	s7,8(sp)
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201d00:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201d04:	892e                	mv	s2,a1
ffffffffc0201d06:	8a32                	mv	s4,a2
ffffffffc0201d08:	00013997          	auipc	s3,0x13
ffffffffc0201d0c:	78898993          	addi	s3,s3,1928 # ffffffffc0215490 <npage>
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201d10:	e3c9                	bnez	a5,ffffffffc0201d92 <get_pte+0xb4>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0201d12:	16060163          	beqz	a2,ffffffffc0201e74 <get_pte+0x196>
ffffffffc0201d16:	4505                	li	a0,1
ffffffffc0201d18:	eb9ff0ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc0201d1c:	842a                	mv	s0,a0
ffffffffc0201d1e:	14050b63          	beqz	a0,ffffffffc0201e74 <get_pte+0x196>
    return page - pages + nbase;
ffffffffc0201d22:	00013b97          	auipc	s7,0x13
ffffffffc0201d26:	7deb8b93          	addi	s7,s7,2014 # ffffffffc0215500 <pages>
ffffffffc0201d2a:	000bb503          	ld	a0,0(s7)
ffffffffc0201d2e:	00004797          	auipc	a5,0x4
ffffffffc0201d32:	bc278793          	addi	a5,a5,-1086 # ffffffffc02058f0 <commands+0x860>
ffffffffc0201d36:	0007bb03          	ld	s6,0(a5)
ffffffffc0201d3a:	40a40533          	sub	a0,s0,a0
ffffffffc0201d3e:	850d                	srai	a0,a0,0x3
ffffffffc0201d40:	03650533          	mul	a0,a0,s6
    page->ref = val;
ffffffffc0201d44:	4785                	li	a5,1
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201d46:	00013997          	auipc	s3,0x13
ffffffffc0201d4a:	74a98993          	addi	s3,s3,1866 # ffffffffc0215490 <npage>
    return page - pages + nbase;
ffffffffc0201d4e:	00080ab7          	lui	s5,0x80
ffffffffc0201d52:	0009b703          	ld	a4,0(s3)
    page->ref = val;
ffffffffc0201d56:	c01c                	sw	a5,0(s0)
ffffffffc0201d58:	57fd                	li	a5,-1
ffffffffc0201d5a:	83b1                	srli	a5,a5,0xc
    return page - pages + nbase;
ffffffffc0201d5c:	9556                	add	a0,a0,s5
ffffffffc0201d5e:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0201d60:	0532                	slli	a0,a0,0xc
ffffffffc0201d62:	16e7f063          	bleu	a4,a5,ffffffffc0201ec2 <get_pte+0x1e4>
ffffffffc0201d66:	00013797          	auipc	a5,0x13
ffffffffc0201d6a:	78a78793          	addi	a5,a5,1930 # ffffffffc02154f0 <va_pa_offset>
ffffffffc0201d6e:	639c                	ld	a5,0(a5)
ffffffffc0201d70:	6605                	lui	a2,0x1
ffffffffc0201d72:	4581                	li	a1,0
ffffffffc0201d74:	953e                	add	a0,a0,a5
ffffffffc0201d76:	18e030ef          	jal	ra,ffffffffc0204f04 <memset>
    return page - pages + nbase;
ffffffffc0201d7a:	000bb683          	ld	a3,0(s7)
ffffffffc0201d7e:	40d406b3          	sub	a3,s0,a3
ffffffffc0201d82:	868d                	srai	a3,a3,0x3
ffffffffc0201d84:	036686b3          	mul	a3,a3,s6
ffffffffc0201d88:	96d6                	add	a3,a3,s5
  asm volatile("sfence.vma");
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201d8a:	06aa                	slli	a3,a3,0xa
ffffffffc0201d8c:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201d90:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201d92:	77fd                	lui	a5,0xfffff
ffffffffc0201d94:	068a                	slli	a3,a3,0x2
ffffffffc0201d96:	0009b703          	ld	a4,0(s3)
ffffffffc0201d9a:	8efd                	and	a3,a3,a5
ffffffffc0201d9c:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201da0:	0ce7fc63          	bleu	a4,a5,ffffffffc0201e78 <get_pte+0x19a>
ffffffffc0201da4:	00013a97          	auipc	s5,0x13
ffffffffc0201da8:	74ca8a93          	addi	s5,s5,1868 # ffffffffc02154f0 <va_pa_offset>
ffffffffc0201dac:	000ab403          	ld	s0,0(s5)
ffffffffc0201db0:	01595793          	srli	a5,s2,0x15
ffffffffc0201db4:	1ff7f793          	andi	a5,a5,511
ffffffffc0201db8:	96a2                	add	a3,a3,s0
ffffffffc0201dba:	00379413          	slli	s0,a5,0x3
ffffffffc0201dbe:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V)) {
ffffffffc0201dc0:	6014                	ld	a3,0(s0)
ffffffffc0201dc2:	0016f793          	andi	a5,a3,1
ffffffffc0201dc6:	ebbd                	bnez	a5,ffffffffc0201e3c <get_pte+0x15e>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0201dc8:	0a0a0663          	beqz	s4,ffffffffc0201e74 <get_pte+0x196>
ffffffffc0201dcc:	4505                	li	a0,1
ffffffffc0201dce:	e03ff0ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc0201dd2:	84aa                	mv	s1,a0
ffffffffc0201dd4:	c145                	beqz	a0,ffffffffc0201e74 <get_pte+0x196>
    return page - pages + nbase;
ffffffffc0201dd6:	00013b97          	auipc	s7,0x13
ffffffffc0201dda:	72ab8b93          	addi	s7,s7,1834 # ffffffffc0215500 <pages>
ffffffffc0201dde:	000bb503          	ld	a0,0(s7)
ffffffffc0201de2:	00004797          	auipc	a5,0x4
ffffffffc0201de6:	b0e78793          	addi	a5,a5,-1266 # ffffffffc02058f0 <commands+0x860>
ffffffffc0201dea:	0007bb03          	ld	s6,0(a5)
ffffffffc0201dee:	40a48533          	sub	a0,s1,a0
ffffffffc0201df2:	850d                	srai	a0,a0,0x3
ffffffffc0201df4:	03650533          	mul	a0,a0,s6
    page->ref = val;
ffffffffc0201df8:	4785                	li	a5,1
    return page - pages + nbase;
ffffffffc0201dfa:	00080a37          	lui	s4,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201dfe:	0009b703          	ld	a4,0(s3)
    page->ref = val;
ffffffffc0201e02:	c09c                	sw	a5,0(s1)
ffffffffc0201e04:	57fd                	li	a5,-1
ffffffffc0201e06:	83b1                	srli	a5,a5,0xc
    return page - pages + nbase;
ffffffffc0201e08:	9552                	add	a0,a0,s4
ffffffffc0201e0a:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0201e0c:	0532                	slli	a0,a0,0xc
ffffffffc0201e0e:	08e7fd63          	bleu	a4,a5,ffffffffc0201ea8 <get_pte+0x1ca>
ffffffffc0201e12:	000ab783          	ld	a5,0(s5)
ffffffffc0201e16:	6605                	lui	a2,0x1
ffffffffc0201e18:	4581                	li	a1,0
ffffffffc0201e1a:	953e                	add	a0,a0,a5
ffffffffc0201e1c:	0e8030ef          	jal	ra,ffffffffc0204f04 <memset>
    return page - pages + nbase;
ffffffffc0201e20:	000bb683          	ld	a3,0(s7)
ffffffffc0201e24:	40d486b3          	sub	a3,s1,a3
ffffffffc0201e28:	868d                	srai	a3,a3,0x3
ffffffffc0201e2a:	036686b3          	mul	a3,a3,s6
ffffffffc0201e2e:	96d2                	add	a3,a3,s4
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201e30:	06aa                	slli	a3,a3,0xa
ffffffffc0201e32:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201e36:	e014                	sd	a3,0(s0)
ffffffffc0201e38:	0009b703          	ld	a4,0(s3)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201e3c:	068a                	slli	a3,a3,0x2
ffffffffc0201e3e:	757d                	lui	a0,0xfffff
ffffffffc0201e40:	8ee9                	and	a3,a3,a0
ffffffffc0201e42:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201e46:	04e7f563          	bleu	a4,a5,ffffffffc0201e90 <get_pte+0x1b2>
ffffffffc0201e4a:	000ab503          	ld	a0,0(s5)
ffffffffc0201e4e:	00c95793          	srli	a5,s2,0xc
ffffffffc0201e52:	1ff7f793          	andi	a5,a5,511
ffffffffc0201e56:	96aa                	add	a3,a3,a0
ffffffffc0201e58:	00379513          	slli	a0,a5,0x3
ffffffffc0201e5c:	9536                	add	a0,a0,a3
}
ffffffffc0201e5e:	60a6                	ld	ra,72(sp)
ffffffffc0201e60:	6406                	ld	s0,64(sp)
ffffffffc0201e62:	74e2                	ld	s1,56(sp)
ffffffffc0201e64:	7942                	ld	s2,48(sp)
ffffffffc0201e66:	79a2                	ld	s3,40(sp)
ffffffffc0201e68:	7a02                	ld	s4,32(sp)
ffffffffc0201e6a:	6ae2                	ld	s5,24(sp)
ffffffffc0201e6c:	6b42                	ld	s6,16(sp)
ffffffffc0201e6e:	6ba2                	ld	s7,8(sp)
ffffffffc0201e70:	6161                	addi	sp,sp,80
ffffffffc0201e72:	8082                	ret
            return NULL;
ffffffffc0201e74:	4501                	li	a0,0
ffffffffc0201e76:	b7e5                	j	ffffffffc0201e5e <get_pte+0x180>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201e78:	00004617          	auipc	a2,0x4
ffffffffc0201e7c:	e7860613          	addi	a2,a2,-392 # ffffffffc0205cf0 <default_pmm_manager+0x50>
ffffffffc0201e80:	0e400593          	li	a1,228
ffffffffc0201e84:	00004517          	auipc	a0,0x4
ffffffffc0201e88:	f5c50513          	addi	a0,a0,-164 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc0201e8c:	dc4fe0ef          	jal	ra,ffffffffc0200450 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201e90:	00004617          	auipc	a2,0x4
ffffffffc0201e94:	e6060613          	addi	a2,a2,-416 # ffffffffc0205cf0 <default_pmm_manager+0x50>
ffffffffc0201e98:	0ef00593          	li	a1,239
ffffffffc0201e9c:	00004517          	auipc	a0,0x4
ffffffffc0201ea0:	f4450513          	addi	a0,a0,-188 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc0201ea4:	dacfe0ef          	jal	ra,ffffffffc0200450 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201ea8:	86aa                	mv	a3,a0
ffffffffc0201eaa:	00004617          	auipc	a2,0x4
ffffffffc0201eae:	e4660613          	addi	a2,a2,-442 # ffffffffc0205cf0 <default_pmm_manager+0x50>
ffffffffc0201eb2:	0ec00593          	li	a1,236
ffffffffc0201eb6:	00004517          	auipc	a0,0x4
ffffffffc0201eba:	f2a50513          	addi	a0,a0,-214 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc0201ebe:	d92fe0ef          	jal	ra,ffffffffc0200450 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201ec2:	86aa                	mv	a3,a0
ffffffffc0201ec4:	00004617          	auipc	a2,0x4
ffffffffc0201ec8:	e2c60613          	addi	a2,a2,-468 # ffffffffc0205cf0 <default_pmm_manager+0x50>
ffffffffc0201ecc:	0e100593          	li	a1,225
ffffffffc0201ed0:	00004517          	auipc	a0,0x4
ffffffffc0201ed4:	f1050513          	addi	a0,a0,-240 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc0201ed8:	d78fe0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc0201edc <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0201edc:	1141                	addi	sp,sp,-16
ffffffffc0201ede:	e022                	sd	s0,0(sp)
ffffffffc0201ee0:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201ee2:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0201ee4:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201ee6:	df9ff0ef          	jal	ra,ffffffffc0201cde <get_pte>
    if (ptep_store != NULL) {
ffffffffc0201eea:	c011                	beqz	s0,ffffffffc0201eee <get_page+0x12>
        *ptep_store = ptep;
ffffffffc0201eec:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0201eee:	c521                	beqz	a0,ffffffffc0201f36 <get_page+0x5a>
ffffffffc0201ef0:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201ef2:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0201ef4:	0017f713          	andi	a4,a5,1
ffffffffc0201ef8:	e709                	bnez	a4,ffffffffc0201f02 <get_page+0x26>
}
ffffffffc0201efa:	60a2                	ld	ra,8(sp)
ffffffffc0201efc:	6402                	ld	s0,0(sp)
ffffffffc0201efe:	0141                	addi	sp,sp,16
ffffffffc0201f00:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0201f02:	00013717          	auipc	a4,0x13
ffffffffc0201f06:	58e70713          	addi	a4,a4,1422 # ffffffffc0215490 <npage>
ffffffffc0201f0a:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201f0c:	078a                	slli	a5,a5,0x2
ffffffffc0201f0e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201f10:	02e7f863          	bleu	a4,a5,ffffffffc0201f40 <get_page+0x64>
    return &pages[PPN(pa) - nbase];
ffffffffc0201f14:	fff80537          	lui	a0,0xfff80
ffffffffc0201f18:	97aa                	add	a5,a5,a0
ffffffffc0201f1a:	00013697          	auipc	a3,0x13
ffffffffc0201f1e:	5e668693          	addi	a3,a3,1510 # ffffffffc0215500 <pages>
ffffffffc0201f22:	6288                	ld	a0,0(a3)
ffffffffc0201f24:	60a2                	ld	ra,8(sp)
ffffffffc0201f26:	6402                	ld	s0,0(sp)
ffffffffc0201f28:	00379713          	slli	a4,a5,0x3
ffffffffc0201f2c:	97ba                	add	a5,a5,a4
ffffffffc0201f2e:	078e                	slli	a5,a5,0x3
ffffffffc0201f30:	953e                	add	a0,a0,a5
ffffffffc0201f32:	0141                	addi	sp,sp,16
ffffffffc0201f34:	8082                	ret
ffffffffc0201f36:	60a2                	ld	ra,8(sp)
ffffffffc0201f38:	6402                	ld	s0,0(sp)
    return NULL;
ffffffffc0201f3a:	4501                	li	a0,0
}
ffffffffc0201f3c:	0141                	addi	sp,sp,16
ffffffffc0201f3e:	8082                	ret
ffffffffc0201f40:	c75ff0ef          	jal	ra,ffffffffc0201bb4 <pa2page.part.4>

ffffffffc0201f44 <page_remove>:
    }
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0201f44:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f46:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0201f48:	e426                	sd	s1,8(sp)
ffffffffc0201f4a:	ec06                	sd	ra,24(sp)
ffffffffc0201f4c:	e822                	sd	s0,16(sp)
ffffffffc0201f4e:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f50:	d8fff0ef          	jal	ra,ffffffffc0201cde <get_pte>
    if (ptep != NULL) {
ffffffffc0201f54:	c511                	beqz	a0,ffffffffc0201f60 <page_remove+0x1c>
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0201f56:	611c                	ld	a5,0(a0)
ffffffffc0201f58:	842a                	mv	s0,a0
ffffffffc0201f5a:	0017f713          	andi	a4,a5,1
ffffffffc0201f5e:	e711                	bnez	a4,ffffffffc0201f6a <page_remove+0x26>
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0201f60:	60e2                	ld	ra,24(sp)
ffffffffc0201f62:	6442                	ld	s0,16(sp)
ffffffffc0201f64:	64a2                	ld	s1,8(sp)
ffffffffc0201f66:	6105                	addi	sp,sp,32
ffffffffc0201f68:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0201f6a:	00013717          	auipc	a4,0x13
ffffffffc0201f6e:	52670713          	addi	a4,a4,1318 # ffffffffc0215490 <npage>
ffffffffc0201f72:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201f74:	078a                	slli	a5,a5,0x2
ffffffffc0201f76:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201f78:	04e7f163          	bleu	a4,a5,ffffffffc0201fba <page_remove+0x76>
    return &pages[PPN(pa) - nbase];
ffffffffc0201f7c:	fff80737          	lui	a4,0xfff80
ffffffffc0201f80:	97ba                	add	a5,a5,a4
ffffffffc0201f82:	00013717          	auipc	a4,0x13
ffffffffc0201f86:	57e70713          	addi	a4,a4,1406 # ffffffffc0215500 <pages>
ffffffffc0201f8a:	6308                	ld	a0,0(a4)
ffffffffc0201f8c:	00379713          	slli	a4,a5,0x3
ffffffffc0201f90:	97ba                	add	a5,a5,a4
ffffffffc0201f92:	078e                	slli	a5,a5,0x3
ffffffffc0201f94:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0201f96:	411c                	lw	a5,0(a0)
ffffffffc0201f98:	fff7871b          	addiw	a4,a5,-1
ffffffffc0201f9c:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0201f9e:	cb11                	beqz	a4,ffffffffc0201fb2 <page_remove+0x6e>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0201fa0:	00043023          	sd	zero,0(s0)
// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la) {
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201fa4:	12048073          	sfence.vma	s1
}
ffffffffc0201fa8:	60e2                	ld	ra,24(sp)
ffffffffc0201faa:	6442                	ld	s0,16(sp)
ffffffffc0201fac:	64a2                	ld	s1,8(sp)
ffffffffc0201fae:	6105                	addi	sp,sp,32
ffffffffc0201fb0:	8082                	ret
            free_page(page);
ffffffffc0201fb2:	4585                	li	a1,1
ffffffffc0201fb4:	ca5ff0ef          	jal	ra,ffffffffc0201c58 <free_pages>
ffffffffc0201fb8:	b7e5                	j	ffffffffc0201fa0 <page_remove+0x5c>
ffffffffc0201fba:	bfbff0ef          	jal	ra,ffffffffc0201bb4 <pa2page.part.4>

ffffffffc0201fbe <page_insert>:
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0201fbe:	7179                	addi	sp,sp,-48
ffffffffc0201fc0:	e44e                	sd	s3,8(sp)
ffffffffc0201fc2:	89b2                	mv	s3,a2
ffffffffc0201fc4:	f022                	sd	s0,32(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201fc6:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0201fc8:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201fca:	85ce                	mv	a1,s3
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0201fcc:	ec26                	sd	s1,24(sp)
ffffffffc0201fce:	f406                	sd	ra,40(sp)
ffffffffc0201fd0:	e84a                	sd	s2,16(sp)
ffffffffc0201fd2:	e052                	sd	s4,0(sp)
ffffffffc0201fd4:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201fd6:	d09ff0ef          	jal	ra,ffffffffc0201cde <get_pte>
    if (ptep == NULL) {
ffffffffc0201fda:	c94d                	beqz	a0,ffffffffc020208c <page_insert+0xce>
    page->ref += 1;
ffffffffc0201fdc:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V) {
ffffffffc0201fde:	611c                	ld	a5,0(a0)
ffffffffc0201fe0:	892a                	mv	s2,a0
ffffffffc0201fe2:	0016871b          	addiw	a4,a3,1
ffffffffc0201fe6:	c018                	sw	a4,0(s0)
ffffffffc0201fe8:	0017f713          	andi	a4,a5,1
ffffffffc0201fec:	e721                	bnez	a4,ffffffffc0202034 <page_insert+0x76>
ffffffffc0201fee:	00013797          	auipc	a5,0x13
ffffffffc0201ff2:	51278793          	addi	a5,a5,1298 # ffffffffc0215500 <pages>
ffffffffc0201ff6:	639c                	ld	a5,0(a5)
    return page - pages + nbase;
ffffffffc0201ff8:	00004717          	auipc	a4,0x4
ffffffffc0201ffc:	8f870713          	addi	a4,a4,-1800 # ffffffffc02058f0 <commands+0x860>
ffffffffc0202000:	40f407b3          	sub	a5,s0,a5
ffffffffc0202004:	6300                	ld	s0,0(a4)
ffffffffc0202006:	878d                	srai	a5,a5,0x3
ffffffffc0202008:	000806b7          	lui	a3,0x80
ffffffffc020200c:	028787b3          	mul	a5,a5,s0
ffffffffc0202010:	97b6                	add	a5,a5,a3
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202012:	07aa                	slli	a5,a5,0xa
ffffffffc0202014:	8fc5                	or	a5,a5,s1
ffffffffc0202016:	0017e793          	ori	a5,a5,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc020201a:	00f93023          	sd	a5,0(s2)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020201e:	12098073          	sfence.vma	s3
    return 0;
ffffffffc0202022:	4501                	li	a0,0
}
ffffffffc0202024:	70a2                	ld	ra,40(sp)
ffffffffc0202026:	7402                	ld	s0,32(sp)
ffffffffc0202028:	64e2                	ld	s1,24(sp)
ffffffffc020202a:	6942                	ld	s2,16(sp)
ffffffffc020202c:	69a2                	ld	s3,8(sp)
ffffffffc020202e:	6a02                	ld	s4,0(sp)
ffffffffc0202030:	6145                	addi	sp,sp,48
ffffffffc0202032:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0202034:	00013717          	auipc	a4,0x13
ffffffffc0202038:	45c70713          	addi	a4,a4,1116 # ffffffffc0215490 <npage>
ffffffffc020203c:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc020203e:	00279513          	slli	a0,a5,0x2
ffffffffc0202042:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202044:	04e57663          	bleu	a4,a0,ffffffffc0202090 <page_insert+0xd2>
    return &pages[PPN(pa) - nbase];
ffffffffc0202048:	fff807b7          	lui	a5,0xfff80
ffffffffc020204c:	953e                	add	a0,a0,a5
ffffffffc020204e:	00013a17          	auipc	s4,0x13
ffffffffc0202052:	4b2a0a13          	addi	s4,s4,1202 # ffffffffc0215500 <pages>
ffffffffc0202056:	000a3783          	ld	a5,0(s4)
ffffffffc020205a:	00351713          	slli	a4,a0,0x3
ffffffffc020205e:	953a                	add	a0,a0,a4
ffffffffc0202060:	050e                	slli	a0,a0,0x3
ffffffffc0202062:	953e                	add	a0,a0,a5
        if (p == page) {
ffffffffc0202064:	00a40a63          	beq	s0,a0,ffffffffc0202078 <page_insert+0xba>
    page->ref -= 1;
ffffffffc0202068:	4118                	lw	a4,0(a0)
ffffffffc020206a:	fff7069b          	addiw	a3,a4,-1
ffffffffc020206e:	c114                	sw	a3,0(a0)
        if (page_ref(page) ==
ffffffffc0202070:	c691                	beqz	a3,ffffffffc020207c <page_insert+0xbe>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202072:	12098073          	sfence.vma	s3
ffffffffc0202076:	b749                	j	ffffffffc0201ff8 <page_insert+0x3a>
ffffffffc0202078:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc020207a:	bfbd                	j	ffffffffc0201ff8 <page_insert+0x3a>
            free_page(page);
ffffffffc020207c:	4585                	li	a1,1
ffffffffc020207e:	bdbff0ef          	jal	ra,ffffffffc0201c58 <free_pages>
ffffffffc0202082:	000a3783          	ld	a5,0(s4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202086:	12098073          	sfence.vma	s3
ffffffffc020208a:	b7bd                	j	ffffffffc0201ff8 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc020208c:	5571                	li	a0,-4
ffffffffc020208e:	bf59                	j	ffffffffc0202024 <page_insert+0x66>
ffffffffc0202090:	b25ff0ef          	jal	ra,ffffffffc0201bb4 <pa2page.part.4>

ffffffffc0202094 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202094:	00004797          	auipc	a5,0x4
ffffffffc0202098:	c0c78793          	addi	a5,a5,-1012 # ffffffffc0205ca0 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020209c:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc020209e:	711d                	addi	sp,sp,-96
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02020a0:	00004517          	auipc	a0,0x4
ffffffffc02020a4:	d6850513          	addi	a0,a0,-664 # ffffffffc0205e08 <default_pmm_manager+0x168>
void pmm_init(void) {
ffffffffc02020a8:	ec86                	sd	ra,88(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02020aa:	00013717          	auipc	a4,0x13
ffffffffc02020ae:	42f73f23          	sd	a5,1086(a4) # ffffffffc02154e8 <pmm_manager>
void pmm_init(void) {
ffffffffc02020b2:	e8a2                	sd	s0,80(sp)
ffffffffc02020b4:	e4a6                	sd	s1,72(sp)
ffffffffc02020b6:	e0ca                	sd	s2,64(sp)
ffffffffc02020b8:	fc4e                	sd	s3,56(sp)
ffffffffc02020ba:	f852                	sd	s4,48(sp)
ffffffffc02020bc:	f456                	sd	s5,40(sp)
ffffffffc02020be:	f05a                	sd	s6,32(sp)
ffffffffc02020c0:	ec5e                	sd	s7,24(sp)
ffffffffc02020c2:	e862                	sd	s8,16(sp)
ffffffffc02020c4:	e466                	sd	s9,8(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02020c6:	00013417          	auipc	s0,0x13
ffffffffc02020ca:	42240413          	addi	s0,s0,1058 # ffffffffc02154e8 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02020ce:	8c0fe0ef          	jal	ra,ffffffffc020018e <cprintf>
    pmm_manager->init();
ffffffffc02020d2:	601c                	ld	a5,0(s0)
ffffffffc02020d4:	00013497          	auipc	s1,0x13
ffffffffc02020d8:	3bc48493          	addi	s1,s1,956 # ffffffffc0215490 <npage>
ffffffffc02020dc:	00013917          	auipc	s2,0x13
ffffffffc02020e0:	42490913          	addi	s2,s2,1060 # ffffffffc0215500 <pages>
ffffffffc02020e4:	679c                	ld	a5,8(a5)
ffffffffc02020e6:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc02020e8:	57f5                	li	a5,-3
ffffffffc02020ea:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc02020ec:	00004517          	auipc	a0,0x4
ffffffffc02020f0:	d3450513          	addi	a0,a0,-716 # ffffffffc0205e20 <default_pmm_manager+0x180>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc02020f4:	00013717          	auipc	a4,0x13
ffffffffc02020f8:	3ef73e23          	sd	a5,1020(a4) # ffffffffc02154f0 <va_pa_offset>
    cprintf("physcial memory map:\n");
ffffffffc02020fc:	892fe0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0202100:	46c5                	li	a3,17
ffffffffc0202102:	06ee                	slli	a3,a3,0x1b
ffffffffc0202104:	40100613          	li	a2,1025
ffffffffc0202108:	16fd                	addi	a3,a3,-1
ffffffffc020210a:	0656                	slli	a2,a2,0x15
ffffffffc020210c:	07e005b7          	lui	a1,0x7e00
ffffffffc0202110:	00004517          	auipc	a0,0x4
ffffffffc0202114:	d2850513          	addi	a0,a0,-728 # ffffffffc0205e38 <default_pmm_manager+0x198>
ffffffffc0202118:	876fe0ef          	jal	ra,ffffffffc020018e <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020211c:	777d                	lui	a4,0xfffff
ffffffffc020211e:	00014797          	auipc	a5,0x14
ffffffffc0202122:	4e178793          	addi	a5,a5,1249 # ffffffffc02165ff <end+0xfff>
ffffffffc0202126:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0202128:	00088737          	lui	a4,0x88
ffffffffc020212c:	00013697          	auipc	a3,0x13
ffffffffc0202130:	36e6b223          	sd	a4,868(a3) # ffffffffc0215490 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202134:	4581                	li	a1,0
ffffffffc0202136:	00013717          	auipc	a4,0x13
ffffffffc020213a:	3cf73523          	sd	a5,970(a4) # ffffffffc0215500 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020213e:	4681                	li	a3,0
ffffffffc0202140:	4605                	li	a2,1
ffffffffc0202142:	fff80837          	lui	a6,0xfff80
ffffffffc0202146:	a019                	j	ffffffffc020214c <pmm_init+0xb8>
ffffffffc0202148:	00093783          	ld	a5,0(s2)
        SetPageReserved(pages + i);
ffffffffc020214c:	97ae                	add	a5,a5,a1
ffffffffc020214e:	07a1                	addi	a5,a5,8
ffffffffc0202150:	40c7b02f          	amoor.d	zero,a2,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0202154:	6098                	ld	a4,0(s1)
ffffffffc0202156:	0685                	addi	a3,a3,1
ffffffffc0202158:	04858593          	addi	a1,a1,72 # 7e00048 <BASE_ADDRESS-0xffffffffb83fffb8>
ffffffffc020215c:	010707b3          	add	a5,a4,a6
ffffffffc0202160:	fef6e4e3          	bltu	a3,a5,ffffffffc0202148 <pmm_init+0xb4>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202164:	00093503          	ld	a0,0(s2)
ffffffffc0202168:	00371693          	slli	a3,a4,0x3
ffffffffc020216c:	96ba                	add	a3,a3,a4
ffffffffc020216e:	fdc005b7          	lui	a1,0xfdc00
ffffffffc0202172:	068e                	slli	a3,a3,0x3
ffffffffc0202174:	95aa                	add	a1,a1,a0
ffffffffc0202176:	96ae                	add	a3,a3,a1
ffffffffc0202178:	c02007b7          	lui	a5,0xc0200
ffffffffc020217c:	16f6efe3          	bltu	a3,a5,ffffffffc0202afa <pmm_init+0xa66>
ffffffffc0202180:	00013997          	auipc	s3,0x13
ffffffffc0202184:	37098993          	addi	s3,s3,880 # ffffffffc02154f0 <va_pa_offset>
ffffffffc0202188:	0009b583          	ld	a1,0(s3)
    if (freemem < mem_end) {
ffffffffc020218c:	47c5                	li	a5,17
ffffffffc020218e:	07ee                	slli	a5,a5,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202190:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end) {
ffffffffc0202192:	02f6fc63          	bleu	a5,a3,ffffffffc02021ca <pmm_init+0x136>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202196:	6585                	lui	a1,0x1
ffffffffc0202198:	15fd                	addi	a1,a1,-1
ffffffffc020219a:	96ae                	add	a3,a3,a1
    if (PPN(pa) >= npage) {
ffffffffc020219c:	00c6d613          	srli	a2,a3,0xc
ffffffffc02021a0:	4ee67d63          	bleu	a4,a2,ffffffffc020269a <pmm_init+0x606>
    pmm_manager->init_memmap(base, n);
ffffffffc02021a4:	00043883          	ld	a7,0(s0)
    return &pages[PPN(pa) - nbase];
ffffffffc02021a8:	9642                	add	a2,a2,a6
ffffffffc02021aa:	00361713          	slli	a4,a2,0x3
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02021ae:	75fd                	lui	a1,0xfffff
ffffffffc02021b0:	8eed                	and	a3,a3,a1
ffffffffc02021b2:	9732                	add	a4,a4,a2
    pmm_manager->init_memmap(base, n);
ffffffffc02021b4:	0108b603          	ld	a2,16(a7)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02021b8:	40d786b3          	sub	a3,a5,a3
ffffffffc02021bc:	070e                	slli	a4,a4,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02021be:	00c6d593          	srli	a1,a3,0xc
ffffffffc02021c2:	953a                	add	a0,a0,a4
ffffffffc02021c4:	9602                	jalr	a2
ffffffffc02021c6:	0009b583          	ld	a1,0(s3)
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc02021ca:	00004517          	auipc	a0,0x4
ffffffffc02021ce:	c9650513          	addi	a0,a0,-874 # ffffffffc0205e60 <default_pmm_manager+0x1c0>
ffffffffc02021d2:	fbdfd0ef          	jal	ra,ffffffffc020018e <cprintf>

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02021d6:	601c                	ld	a5,0(s0)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc02021d8:	00013417          	auipc	s0,0x13
ffffffffc02021dc:	2b040413          	addi	s0,s0,688 # ffffffffc0215488 <boot_pgdir>
    pmm_manager->check();
ffffffffc02021e0:	7b9c                	ld	a5,48(a5)
ffffffffc02021e2:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02021e4:	00004517          	auipc	a0,0x4
ffffffffc02021e8:	c9450513          	addi	a0,a0,-876 # ffffffffc0205e78 <default_pmm_manager+0x1d8>
ffffffffc02021ec:	fa3fd0ef          	jal	ra,ffffffffc020018e <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc02021f0:	00007697          	auipc	a3,0x7
ffffffffc02021f4:	e1068693          	addi	a3,a3,-496 # ffffffffc0209000 <boot_page_table_sv39>
ffffffffc02021f8:	00013797          	auipc	a5,0x13
ffffffffc02021fc:	28d7b823          	sd	a3,656(a5) # ffffffffc0215488 <boot_pgdir>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0202200:	c02007b7          	lui	a5,0xc0200
ffffffffc0202204:	7cf6ef63          	bltu	a3,a5,ffffffffc02029e2 <pmm_init+0x94e>
ffffffffc0202208:	0009b783          	ld	a5,0(s3)
ffffffffc020220c:	8e9d                	sub	a3,a3,a5
ffffffffc020220e:	00013797          	auipc	a5,0x13
ffffffffc0202212:	2ed7b523          	sd	a3,746(a5) # ffffffffc02154f8 <boot_cr3>
    // assert(npage <= KMEMSIZE / PGSIZE);
    // The memory starts at 2GB in RISC-V
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();
ffffffffc0202216:	a89ff0ef          	jal	ra,ffffffffc0201c9e <nr_free_pages>

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020221a:	6098                	ld	a4,0(s1)
ffffffffc020221c:	c80007b7          	lui	a5,0xc8000
ffffffffc0202220:	83b1                	srli	a5,a5,0xc
    nr_free_store=nr_free_pages();
ffffffffc0202222:	8a2a                	mv	s4,a0
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202224:	76e7ef63          	bltu	a5,a4,ffffffffc02029a2 <pmm_init+0x90e>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0202228:	6008                	ld	a0,0(s0)
ffffffffc020222a:	48050663          	beqz	a0,ffffffffc02026b6 <pmm_init+0x622>
ffffffffc020222e:	6785                	lui	a5,0x1
ffffffffc0202230:	17fd                	addi	a5,a5,-1
ffffffffc0202232:	8fe9                	and	a5,a5,a0
ffffffffc0202234:	2781                	sext.w	a5,a5
ffffffffc0202236:	48079063          	bnez	a5,ffffffffc02026b6 <pmm_init+0x622>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc020223a:	4601                	li	a2,0
ffffffffc020223c:	4581                	li	a1,0
ffffffffc020223e:	c9fff0ef          	jal	ra,ffffffffc0201edc <get_page>
ffffffffc0202242:	08051ce3          	bnez	a0,ffffffffc0202ada <pmm_init+0xa46>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc0202246:	4505                	li	a0,1
ffffffffc0202248:	989ff0ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc020224c:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc020224e:	6008                	ld	a0,0(s0)
ffffffffc0202250:	4681                	li	a3,0
ffffffffc0202252:	4601                	li	a2,0
ffffffffc0202254:	85d6                	mv	a1,s5
ffffffffc0202256:	d69ff0ef          	jal	ra,ffffffffc0201fbe <page_insert>
ffffffffc020225a:	060510e3          	bnez	a0,ffffffffc0202aba <pmm_init+0xa26>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc020225e:	6008                	ld	a0,0(s0)
ffffffffc0202260:	4601                	li	a2,0
ffffffffc0202262:	4581                	li	a1,0
ffffffffc0202264:	a7bff0ef          	jal	ra,ffffffffc0201cde <get_pte>
ffffffffc0202268:	48050363          	beqz	a0,ffffffffc02026ee <pmm_init+0x65a>
    assert(pte2page(*ptep) == p1);
ffffffffc020226c:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc020226e:	0017f713          	andi	a4,a5,1
ffffffffc0202272:	46070263          	beqz	a4,ffffffffc02026d6 <pmm_init+0x642>
    if (PPN(pa) >= npage) {
ffffffffc0202276:	6090                	ld	a2,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202278:	078a                	slli	a5,a5,0x2
ffffffffc020227a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020227c:	40c7ff63          	bleu	a2,a5,ffffffffc020269a <pmm_init+0x606>
    return &pages[PPN(pa) - nbase];
ffffffffc0202280:	fff80737          	lui	a4,0xfff80
ffffffffc0202284:	97ba                	add	a5,a5,a4
ffffffffc0202286:	00379713          	slli	a4,a5,0x3
ffffffffc020228a:	00093683          	ld	a3,0(s2)
ffffffffc020228e:	97ba                	add	a5,a5,a4
ffffffffc0202290:	078e                	slli	a5,a5,0x3
ffffffffc0202292:	97b6                	add	a5,a5,a3
ffffffffc0202294:	4cfa9763          	bne	s5,a5,ffffffffc0202762 <pmm_init+0x6ce>
    assert(page_ref(p1) == 1);
ffffffffc0202298:	000aab83          	lw	s7,0(s5)
ffffffffc020229c:	4785                	li	a5,1
ffffffffc020229e:	4afb9263          	bne	s7,a5,ffffffffc0202742 <pmm_init+0x6ae>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc02022a2:	6008                	ld	a0,0(s0)
ffffffffc02022a4:	76fd                	lui	a3,0xfffff
ffffffffc02022a6:	611c                	ld	a5,0(a0)
ffffffffc02022a8:	078a                	slli	a5,a5,0x2
ffffffffc02022aa:	8ff5                	and	a5,a5,a3
ffffffffc02022ac:	00c7d713          	srli	a4,a5,0xc
ffffffffc02022b0:	46c77c63          	bleu	a2,a4,ffffffffc0202728 <pmm_init+0x694>
ffffffffc02022b4:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02022b8:	97e2                	add	a5,a5,s8
ffffffffc02022ba:	0007bb03          	ld	s6,0(a5) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
ffffffffc02022be:	0b0a                	slli	s6,s6,0x2
ffffffffc02022c0:	00db7b33          	and	s6,s6,a3
ffffffffc02022c4:	00cb5793          	srli	a5,s6,0xc
ffffffffc02022c8:	44c7f363          	bleu	a2,a5,ffffffffc020270e <pmm_init+0x67a>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02022cc:	4601                	li	a2,0
ffffffffc02022ce:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02022d0:	9b62                	add	s6,s6,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02022d2:	a0dff0ef          	jal	ra,ffffffffc0201cde <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02022d6:	0b21                	addi	s6,s6,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02022d8:	59651563          	bne	a0,s6,ffffffffc0202862 <pmm_init+0x7ce>

    p2 = alloc_page();
ffffffffc02022dc:	4505                	li	a0,1
ffffffffc02022de:	8f3ff0ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc02022e2:	8b2a                	mv	s6,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02022e4:	6008                	ld	a0,0(s0)
ffffffffc02022e6:	46d1                	li	a3,20
ffffffffc02022e8:	6605                	lui	a2,0x1
ffffffffc02022ea:	85da                	mv	a1,s6
ffffffffc02022ec:	cd3ff0ef          	jal	ra,ffffffffc0201fbe <page_insert>
ffffffffc02022f0:	54051963          	bnez	a0,ffffffffc0202842 <pmm_init+0x7ae>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02022f4:	6008                	ld	a0,0(s0)
ffffffffc02022f6:	4601                	li	a2,0
ffffffffc02022f8:	6585                	lui	a1,0x1
ffffffffc02022fa:	9e5ff0ef          	jal	ra,ffffffffc0201cde <get_pte>
ffffffffc02022fe:	52050263          	beqz	a0,ffffffffc0202822 <pmm_init+0x78e>
    assert(*ptep & PTE_U);
ffffffffc0202302:	611c                	ld	a5,0(a0)
ffffffffc0202304:	0107f713          	andi	a4,a5,16
ffffffffc0202308:	4e070d63          	beqz	a4,ffffffffc0202802 <pmm_init+0x76e>
    assert(*ptep & PTE_W);
ffffffffc020230c:	8b91                	andi	a5,a5,4
ffffffffc020230e:	4c078a63          	beqz	a5,ffffffffc02027e2 <pmm_init+0x74e>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0202312:	6008                	ld	a0,0(s0)
ffffffffc0202314:	611c                	ld	a5,0(a0)
ffffffffc0202316:	8bc1                	andi	a5,a5,16
ffffffffc0202318:	4a078563          	beqz	a5,ffffffffc02027c2 <pmm_init+0x72e>
    assert(page_ref(p2) == 1);
ffffffffc020231c:	000b2783          	lw	a5,0(s6)
ffffffffc0202320:	49779163          	bne	a5,s7,ffffffffc02027a2 <pmm_init+0x70e>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0202324:	4681                	li	a3,0
ffffffffc0202326:	6605                	lui	a2,0x1
ffffffffc0202328:	85d6                	mv	a1,s5
ffffffffc020232a:	c95ff0ef          	jal	ra,ffffffffc0201fbe <page_insert>
ffffffffc020232e:	44051a63          	bnez	a0,ffffffffc0202782 <pmm_init+0x6ee>
    assert(page_ref(p1) == 2);
ffffffffc0202332:	000aa703          	lw	a4,0(s5)
ffffffffc0202336:	4789                	li	a5,2
ffffffffc0202338:	62f71563          	bne	a4,a5,ffffffffc0202962 <pmm_init+0x8ce>
    assert(page_ref(p2) == 0);
ffffffffc020233c:	000b2783          	lw	a5,0(s6)
ffffffffc0202340:	60079163          	bnez	a5,ffffffffc0202942 <pmm_init+0x8ae>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202344:	6008                	ld	a0,0(s0)
ffffffffc0202346:	4601                	li	a2,0
ffffffffc0202348:	6585                	lui	a1,0x1
ffffffffc020234a:	995ff0ef          	jal	ra,ffffffffc0201cde <get_pte>
ffffffffc020234e:	5c050a63          	beqz	a0,ffffffffc0202922 <pmm_init+0x88e>
    assert(pte2page(*ptep) == p1);
ffffffffc0202352:	6114                	ld	a3,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0202354:	0016f793          	andi	a5,a3,1
ffffffffc0202358:	36078f63          	beqz	a5,ffffffffc02026d6 <pmm_init+0x642>
    if (PPN(pa) >= npage) {
ffffffffc020235c:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020235e:	00269793          	slli	a5,a3,0x2
ffffffffc0202362:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202364:	32e7fb63          	bleu	a4,a5,ffffffffc020269a <pmm_init+0x606>
    return &pages[PPN(pa) - nbase];
ffffffffc0202368:	fff80737          	lui	a4,0xfff80
ffffffffc020236c:	97ba                	add	a5,a5,a4
ffffffffc020236e:	00379713          	slli	a4,a5,0x3
ffffffffc0202372:	00093603          	ld	a2,0(s2)
ffffffffc0202376:	97ba                	add	a5,a5,a4
ffffffffc0202378:	078e                	slli	a5,a5,0x3
ffffffffc020237a:	97b2                	add	a5,a5,a2
ffffffffc020237c:	58fa9363          	bne	s5,a5,ffffffffc0202902 <pmm_init+0x86e>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202380:	8ac1                	andi	a3,a3,16
ffffffffc0202382:	56069063          	bnez	a3,ffffffffc02028e2 <pmm_init+0x84e>

    page_remove(boot_pgdir, 0x0);
ffffffffc0202386:	6008                	ld	a0,0(s0)
ffffffffc0202388:	4581                	li	a1,0
ffffffffc020238a:	bbbff0ef          	jal	ra,ffffffffc0201f44 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc020238e:	000aa703          	lw	a4,0(s5)
ffffffffc0202392:	4785                	li	a5,1
ffffffffc0202394:	52f71763          	bne	a4,a5,ffffffffc02028c2 <pmm_init+0x82e>
    assert(page_ref(p2) == 0);
ffffffffc0202398:	000b2783          	lw	a5,0(s6)
ffffffffc020239c:	50079363          	bnez	a5,ffffffffc02028a2 <pmm_init+0x80e>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc02023a0:	6008                	ld	a0,0(s0)
ffffffffc02023a2:	6585                	lui	a1,0x1
ffffffffc02023a4:	ba1ff0ef          	jal	ra,ffffffffc0201f44 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc02023a8:	000aa783          	lw	a5,0(s5)
ffffffffc02023ac:	4c079b63          	bnez	a5,ffffffffc0202882 <pmm_init+0x7ee>
    assert(page_ref(p2) == 0);
ffffffffc02023b0:	000b2783          	lw	a5,0(s6)
ffffffffc02023b4:	6e079363          	bnez	a5,ffffffffc0202a9a <pmm_init+0xa06>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc02023b8:	00043b03          	ld	s6,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc02023bc:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02023be:	000b3783          	ld	a5,0(s6)
ffffffffc02023c2:	078a                	slli	a5,a5,0x2
ffffffffc02023c4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02023c6:	2cb7fa63          	bleu	a1,a5,ffffffffc020269a <pmm_init+0x606>
    return &pages[PPN(pa) - nbase];
ffffffffc02023ca:	fff80737          	lui	a4,0xfff80
ffffffffc02023ce:	973e                	add	a4,a4,a5
ffffffffc02023d0:	00371793          	slli	a5,a4,0x3
ffffffffc02023d4:	00093603          	ld	a2,0(s2)
ffffffffc02023d8:	97ba                	add	a5,a5,a4
ffffffffc02023da:	078e                	slli	a5,a5,0x3
ffffffffc02023dc:	00f60733          	add	a4,a2,a5
ffffffffc02023e0:	4314                	lw	a3,0(a4)
ffffffffc02023e2:	4705                	li	a4,1
ffffffffc02023e4:	68e69b63          	bne	a3,a4,ffffffffc0202a7a <pmm_init+0x9e6>
    return page - pages + nbase;
ffffffffc02023e8:	00003a97          	auipc	s5,0x3
ffffffffc02023ec:	508a8a93          	addi	s5,s5,1288 # ffffffffc02058f0 <commands+0x860>
ffffffffc02023f0:	000ab703          	ld	a4,0(s5)
ffffffffc02023f4:	4037d693          	srai	a3,a5,0x3
ffffffffc02023f8:	00080bb7          	lui	s7,0x80
ffffffffc02023fc:	02e686b3          	mul	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202400:	577d                	li	a4,-1
ffffffffc0202402:	8331                	srli	a4,a4,0xc
    return page - pages + nbase;
ffffffffc0202404:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0202406:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202408:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020240a:	28b77a63          	bleu	a1,a4,ffffffffc020269e <pmm_init+0x60a>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc020240e:	0009b783          	ld	a5,0(s3)
ffffffffc0202412:	96be                	add	a3,a3,a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202414:	629c                	ld	a5,0(a3)
ffffffffc0202416:	078a                	slli	a5,a5,0x2
ffffffffc0202418:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020241a:	28b7f063          	bleu	a1,a5,ffffffffc020269a <pmm_init+0x606>
    return &pages[PPN(pa) - nbase];
ffffffffc020241e:	417787b3          	sub	a5,a5,s7
ffffffffc0202422:	00379513          	slli	a0,a5,0x3
ffffffffc0202426:	97aa                	add	a5,a5,a0
ffffffffc0202428:	00379513          	slli	a0,a5,0x3
ffffffffc020242c:	9532                	add	a0,a0,a2
ffffffffc020242e:	4585                	li	a1,1
ffffffffc0202430:	829ff0ef          	jal	ra,ffffffffc0201c58 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202434:	000b3503          	ld	a0,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc0202438:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020243a:	050a                	slli	a0,a0,0x2
ffffffffc020243c:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc020243e:	24f57e63          	bleu	a5,a0,ffffffffc020269a <pmm_init+0x606>
    return &pages[PPN(pa) - nbase];
ffffffffc0202442:	417507b3          	sub	a5,a0,s7
ffffffffc0202446:	00379513          	slli	a0,a5,0x3
ffffffffc020244a:	00093703          	ld	a4,0(s2)
ffffffffc020244e:	953e                	add	a0,a0,a5
ffffffffc0202450:	050e                	slli	a0,a0,0x3
    free_page(pde2page(pd1[0]));
ffffffffc0202452:	4585                	li	a1,1
ffffffffc0202454:	953a                	add	a0,a0,a4
ffffffffc0202456:	803ff0ef          	jal	ra,ffffffffc0201c58 <free_pages>
    boot_pgdir[0] = 0;
ffffffffc020245a:	601c                	ld	a5,0(s0)
ffffffffc020245c:	0007b023          	sd	zero,0(a5)
  asm volatile("sfence.vma");
ffffffffc0202460:	12000073          	sfence.vma
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0202464:	83bff0ef          	jal	ra,ffffffffc0201c9e <nr_free_pages>
ffffffffc0202468:	50aa1d63          	bne	s4,a0,ffffffffc0202982 <pmm_init+0x8ee>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc020246c:	00004517          	auipc	a0,0x4
ffffffffc0202470:	d1c50513          	addi	a0,a0,-740 # ffffffffc0206188 <default_pmm_manager+0x4e8>
ffffffffc0202474:	d1bfd0ef          	jal	ra,ffffffffc020018e <cprintf>
static void check_boot_pgdir(void) {
    size_t nr_free_store;
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();
ffffffffc0202478:	827ff0ef          	jal	ra,ffffffffc0201c9e <nr_free_pages>

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc020247c:	6098                	ld	a4,0(s1)
ffffffffc020247e:	c02007b7          	lui	a5,0xc0200
    nr_free_store=nr_free_pages();
ffffffffc0202482:	8b2a                	mv	s6,a0
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0202484:	00c71693          	slli	a3,a4,0xc
ffffffffc0202488:	1ad7fa63          	bleu	a3,a5,ffffffffc020263c <pmm_init+0x5a8>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020248c:	83b1                	srli	a5,a5,0xc
ffffffffc020248e:	6008                	ld	a0,0(s0)
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0202490:	c0200a37          	lui	s4,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202494:	1ce7f663          	bleu	a4,a5,ffffffffc0202660 <pmm_init+0x5cc>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202498:	7c7d                	lui	s8,0xfffff
ffffffffc020249a:	6b85                	lui	s7,0x1
ffffffffc020249c:	a029                	j	ffffffffc02024a6 <pmm_init+0x412>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020249e:	00ca5713          	srli	a4,s4,0xc
ffffffffc02024a2:	1af77f63          	bleu	a5,a4,ffffffffc0202660 <pmm_init+0x5cc>
ffffffffc02024a6:	0009b583          	ld	a1,0(s3)
ffffffffc02024aa:	4601                	li	a2,0
ffffffffc02024ac:	95d2                	add	a1,a1,s4
ffffffffc02024ae:	831ff0ef          	jal	ra,ffffffffc0201cde <get_pte>
ffffffffc02024b2:	18050763          	beqz	a0,ffffffffc0202640 <pmm_init+0x5ac>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02024b6:	611c                	ld	a5,0(a0)
ffffffffc02024b8:	078a                	slli	a5,a5,0x2
ffffffffc02024ba:	0187f7b3          	and	a5,a5,s8
ffffffffc02024be:	1b479e63          	bne	a5,s4,ffffffffc020267a <pmm_init+0x5e6>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02024c2:	609c                	ld	a5,0(s1)
ffffffffc02024c4:	9a5e                	add	s4,s4,s7
ffffffffc02024c6:	6008                	ld	a0,0(s0)
ffffffffc02024c8:	00c79713          	slli	a4,a5,0xc
ffffffffc02024cc:	fcea69e3          	bltu	s4,a4,ffffffffc020249e <pmm_init+0x40a>
    }

    assert(boot_pgdir[0] == 0);
ffffffffc02024d0:	611c                	ld	a5,0(a0)
ffffffffc02024d2:	4e079863          	bnez	a5,ffffffffc02029c2 <pmm_init+0x92e>

    struct Page *p;
    p = alloc_page();
ffffffffc02024d6:	4505                	li	a0,1
ffffffffc02024d8:	ef8ff0ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc02024dc:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02024de:	6008                	ld	a0,0(s0)
ffffffffc02024e0:	4699                	li	a3,6
ffffffffc02024e2:	10000613          	li	a2,256
ffffffffc02024e6:	85d2                	mv	a1,s4
ffffffffc02024e8:	ad7ff0ef          	jal	ra,ffffffffc0201fbe <page_insert>
ffffffffc02024ec:	56051763          	bnez	a0,ffffffffc0202a5a <pmm_init+0x9c6>
    assert(page_ref(p) == 1);
ffffffffc02024f0:	000a2703          	lw	a4,0(s4) # ffffffffc0200000 <kern_entry>
ffffffffc02024f4:	4785                	li	a5,1
ffffffffc02024f6:	54f71263          	bne	a4,a5,ffffffffc0202a3a <pmm_init+0x9a6>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02024fa:	6008                	ld	a0,0(s0)
ffffffffc02024fc:	6b85                	lui	s7,0x1
ffffffffc02024fe:	4699                	li	a3,6
ffffffffc0202500:	100b8613          	addi	a2,s7,256 # 1100 <BASE_ADDRESS-0xffffffffc01fef00>
ffffffffc0202504:	85d2                	mv	a1,s4
ffffffffc0202506:	ab9ff0ef          	jal	ra,ffffffffc0201fbe <page_insert>
ffffffffc020250a:	50051863          	bnez	a0,ffffffffc0202a1a <pmm_init+0x986>
    assert(page_ref(p) == 2);
ffffffffc020250e:	000a2703          	lw	a4,0(s4)
ffffffffc0202512:	4789                	li	a5,2
ffffffffc0202514:	4ef71363          	bne	a4,a5,ffffffffc02029fa <pmm_init+0x966>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202518:	00004597          	auipc	a1,0x4
ffffffffc020251c:	da858593          	addi	a1,a1,-600 # ffffffffc02062c0 <default_pmm_manager+0x620>
ffffffffc0202520:	10000513          	li	a0,256
ffffffffc0202524:	187020ef          	jal	ra,ffffffffc0204eaa <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202528:	100b8593          	addi	a1,s7,256
ffffffffc020252c:	10000513          	li	a0,256
ffffffffc0202530:	18d020ef          	jal	ra,ffffffffc0204ebc <strcmp>
ffffffffc0202534:	60051f63          	bnez	a0,ffffffffc0202b52 <pmm_init+0xabe>
    return page - pages + nbase;
ffffffffc0202538:	00093683          	ld	a3,0(s2)
ffffffffc020253c:	000abc83          	ld	s9,0(s5)
ffffffffc0202540:	00080c37          	lui	s8,0x80
ffffffffc0202544:	40da06b3          	sub	a3,s4,a3
ffffffffc0202548:	868d                	srai	a3,a3,0x3
ffffffffc020254a:	039686b3          	mul	a3,a3,s9
    return KADDR(page2pa(page));
ffffffffc020254e:	5afd                	li	s5,-1
ffffffffc0202550:	609c                	ld	a5,0(s1)
ffffffffc0202552:	00cada93          	srli	s5,s5,0xc
    return page - pages + nbase;
ffffffffc0202556:	96e2                	add	a3,a3,s8
    return KADDR(page2pa(page));
ffffffffc0202558:	0156f733          	and	a4,a3,s5
    return page2ppn(page) << PGSHIFT;
ffffffffc020255c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020255e:	14f77063          	bleu	a5,a4,ffffffffc020269e <pmm_init+0x60a>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202562:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202566:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020256a:	96be                	add	a3,a3,a5
ffffffffc020256c:	10068023          	sb	zero,256(a3) # fffffffffffff100 <end+0x3fde9b00>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202570:	0f7020ef          	jal	ra,ffffffffc0204e66 <strlen>
ffffffffc0202574:	5a051f63          	bnez	a0,ffffffffc0202b32 <pmm_init+0xa9e>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0202578:	00043b83          	ld	s7,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc020257c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020257e:	000bb783          	ld	a5,0(s7)
ffffffffc0202582:	078a                	slli	a5,a5,0x2
ffffffffc0202584:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202586:	10e7fa63          	bleu	a4,a5,ffffffffc020269a <pmm_init+0x606>
    return &pages[PPN(pa) - nbase];
ffffffffc020258a:	418787b3          	sub	a5,a5,s8
ffffffffc020258e:	00379693          	slli	a3,a5,0x3
    return page - pages + nbase;
ffffffffc0202592:	96be                	add	a3,a3,a5
ffffffffc0202594:	039686b3          	mul	a3,a3,s9
ffffffffc0202598:	96e2                	add	a3,a3,s8
    return KADDR(page2pa(page));
ffffffffc020259a:	0156fab3          	and	s5,a3,s5
    return page2ppn(page) << PGSHIFT;
ffffffffc020259e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02025a0:	0eeaff63          	bleu	a4,s5,ffffffffc020269e <pmm_init+0x60a>
ffffffffc02025a4:	0009b983          	ld	s3,0(s3)
    free_page(p);
ffffffffc02025a8:	4585                	li	a1,1
ffffffffc02025aa:	8552                	mv	a0,s4
ffffffffc02025ac:	99b6                	add	s3,s3,a3
ffffffffc02025ae:	eaaff0ef          	jal	ra,ffffffffc0201c58 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc02025b2:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc02025b6:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02025b8:	078a                	slli	a5,a5,0x2
ffffffffc02025ba:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02025bc:	0ce7ff63          	bleu	a4,a5,ffffffffc020269a <pmm_init+0x606>
    return &pages[PPN(pa) - nbase];
ffffffffc02025c0:	fff809b7          	lui	s3,0xfff80
ffffffffc02025c4:	97ce                	add	a5,a5,s3
ffffffffc02025c6:	00379513          	slli	a0,a5,0x3
ffffffffc02025ca:	00093703          	ld	a4,0(s2)
ffffffffc02025ce:	97aa                	add	a5,a5,a0
ffffffffc02025d0:	00379513          	slli	a0,a5,0x3
    free_page(pde2page(pd0[0]));
ffffffffc02025d4:	953a                	add	a0,a0,a4
ffffffffc02025d6:	4585                	li	a1,1
ffffffffc02025d8:	e80ff0ef          	jal	ra,ffffffffc0201c58 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc02025dc:	000bb503          	ld	a0,0(s7)
    if (PPN(pa) >= npage) {
ffffffffc02025e0:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02025e2:	050a                	slli	a0,a0,0x2
ffffffffc02025e4:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc02025e6:	0af57a63          	bleu	a5,a0,ffffffffc020269a <pmm_init+0x606>
    return &pages[PPN(pa) - nbase];
ffffffffc02025ea:	013507b3          	add	a5,a0,s3
ffffffffc02025ee:	00379513          	slli	a0,a5,0x3
ffffffffc02025f2:	00093703          	ld	a4,0(s2)
ffffffffc02025f6:	953e                	add	a0,a0,a5
ffffffffc02025f8:	050e                	slli	a0,a0,0x3
    free_page(pde2page(pd1[0]));
ffffffffc02025fa:	4585                	li	a1,1
ffffffffc02025fc:	953a                	add	a0,a0,a4
ffffffffc02025fe:	e5aff0ef          	jal	ra,ffffffffc0201c58 <free_pages>
    boot_pgdir[0] = 0;
ffffffffc0202602:	601c                	ld	a5,0(s0)
ffffffffc0202604:	0007b023          	sd	zero,0(a5) # ffffffffc0200000 <kern_entry>
  asm volatile("sfence.vma");
ffffffffc0202608:	12000073          	sfence.vma
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc020260c:	e92ff0ef          	jal	ra,ffffffffc0201c9e <nr_free_pages>
ffffffffc0202610:	50ab1163          	bne	s6,a0,ffffffffc0202b12 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202614:	00004517          	auipc	a0,0x4
ffffffffc0202618:	d2450513          	addi	a0,a0,-732 # ffffffffc0206338 <default_pmm_manager+0x698>
ffffffffc020261c:	b73fd0ef          	jal	ra,ffffffffc020018e <cprintf>
}
ffffffffc0202620:	6446                	ld	s0,80(sp)
ffffffffc0202622:	60e6                	ld	ra,88(sp)
ffffffffc0202624:	64a6                	ld	s1,72(sp)
ffffffffc0202626:	6906                	ld	s2,64(sp)
ffffffffc0202628:	79e2                	ld	s3,56(sp)
ffffffffc020262a:	7a42                	ld	s4,48(sp)
ffffffffc020262c:	7aa2                	ld	s5,40(sp)
ffffffffc020262e:	7b02                	ld	s6,32(sp)
ffffffffc0202630:	6be2                	ld	s7,24(sp)
ffffffffc0202632:	6c42                	ld	s8,16(sp)
ffffffffc0202634:	6ca2                	ld	s9,8(sp)
ffffffffc0202636:	6125                	addi	sp,sp,96
    kmalloc_init();
ffffffffc0202638:	b74ff06f          	j	ffffffffc02019ac <kmalloc_init>
ffffffffc020263c:	6008                	ld	a0,0(s0)
ffffffffc020263e:	bd49                	j	ffffffffc02024d0 <pmm_init+0x43c>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202640:	00004697          	auipc	a3,0x4
ffffffffc0202644:	b6868693          	addi	a3,a3,-1176 # ffffffffc02061a8 <default_pmm_manager+0x508>
ffffffffc0202648:	00003617          	auipc	a2,0x3
ffffffffc020264c:	2c060613          	addi	a2,a2,704 # ffffffffc0205908 <commands+0x878>
ffffffffc0202650:	19d00593          	li	a1,413
ffffffffc0202654:	00003517          	auipc	a0,0x3
ffffffffc0202658:	78c50513          	addi	a0,a0,1932 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc020265c:	df5fd0ef          	jal	ra,ffffffffc0200450 <__panic>
ffffffffc0202660:	86d2                	mv	a3,s4
ffffffffc0202662:	00003617          	auipc	a2,0x3
ffffffffc0202666:	68e60613          	addi	a2,a2,1678 # ffffffffc0205cf0 <default_pmm_manager+0x50>
ffffffffc020266a:	19d00593          	li	a1,413
ffffffffc020266e:	00003517          	auipc	a0,0x3
ffffffffc0202672:	77250513          	addi	a0,a0,1906 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc0202676:	ddbfd0ef          	jal	ra,ffffffffc0200450 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020267a:	00004697          	auipc	a3,0x4
ffffffffc020267e:	b6e68693          	addi	a3,a3,-1170 # ffffffffc02061e8 <default_pmm_manager+0x548>
ffffffffc0202682:	00003617          	auipc	a2,0x3
ffffffffc0202686:	28660613          	addi	a2,a2,646 # ffffffffc0205908 <commands+0x878>
ffffffffc020268a:	19e00593          	li	a1,414
ffffffffc020268e:	00003517          	auipc	a0,0x3
ffffffffc0202692:	75250513          	addi	a0,a0,1874 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc0202696:	dbbfd0ef          	jal	ra,ffffffffc0200450 <__panic>
ffffffffc020269a:	d1aff0ef          	jal	ra,ffffffffc0201bb4 <pa2page.part.4>
    return KADDR(page2pa(page));
ffffffffc020269e:	00003617          	auipc	a2,0x3
ffffffffc02026a2:	65260613          	addi	a2,a2,1618 # ffffffffc0205cf0 <default_pmm_manager+0x50>
ffffffffc02026a6:	06900593          	li	a1,105
ffffffffc02026aa:	00003517          	auipc	a0,0x3
ffffffffc02026ae:	66e50513          	addi	a0,a0,1646 # ffffffffc0205d18 <default_pmm_manager+0x78>
ffffffffc02026b2:	d9ffd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc02026b6:	00004697          	auipc	a3,0x4
ffffffffc02026ba:	80268693          	addi	a3,a3,-2046 # ffffffffc0205eb8 <default_pmm_manager+0x218>
ffffffffc02026be:	00003617          	auipc	a2,0x3
ffffffffc02026c2:	24a60613          	addi	a2,a2,586 # ffffffffc0205908 <commands+0x878>
ffffffffc02026c6:	16100593          	li	a1,353
ffffffffc02026ca:	00003517          	auipc	a0,0x3
ffffffffc02026ce:	71650513          	addi	a0,a0,1814 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc02026d2:	d7ffd0ef          	jal	ra,ffffffffc0200450 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02026d6:	00004617          	auipc	a2,0x4
ffffffffc02026da:	8a260613          	addi	a2,a2,-1886 # ffffffffc0205f78 <default_pmm_manager+0x2d8>
ffffffffc02026de:	07400593          	li	a1,116
ffffffffc02026e2:	00003517          	auipc	a0,0x3
ffffffffc02026e6:	63650513          	addi	a0,a0,1590 # ffffffffc0205d18 <default_pmm_manager+0x78>
ffffffffc02026ea:	d67fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc02026ee:	00004697          	auipc	a3,0x4
ffffffffc02026f2:	85a68693          	addi	a3,a3,-1958 # ffffffffc0205f48 <default_pmm_manager+0x2a8>
ffffffffc02026f6:	00003617          	auipc	a2,0x3
ffffffffc02026fa:	21260613          	addi	a2,a2,530 # ffffffffc0205908 <commands+0x878>
ffffffffc02026fe:	16900593          	li	a1,361
ffffffffc0202702:	00003517          	auipc	a0,0x3
ffffffffc0202706:	6de50513          	addi	a0,a0,1758 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc020270a:	d47fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020270e:	86da                	mv	a3,s6
ffffffffc0202710:	00003617          	auipc	a2,0x3
ffffffffc0202714:	5e060613          	addi	a2,a2,1504 # ffffffffc0205cf0 <default_pmm_manager+0x50>
ffffffffc0202718:	16e00593          	li	a1,366
ffffffffc020271c:	00003517          	auipc	a0,0x3
ffffffffc0202720:	6c450513          	addi	a0,a0,1732 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc0202724:	d2dfd0ef          	jal	ra,ffffffffc0200450 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0202728:	86be                	mv	a3,a5
ffffffffc020272a:	00003617          	auipc	a2,0x3
ffffffffc020272e:	5c660613          	addi	a2,a2,1478 # ffffffffc0205cf0 <default_pmm_manager+0x50>
ffffffffc0202732:	16d00593          	li	a1,365
ffffffffc0202736:	00003517          	auipc	a0,0x3
ffffffffc020273a:	6aa50513          	addi	a0,a0,1706 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc020273e:	d13fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202742:	00004697          	auipc	a3,0x4
ffffffffc0202746:	87668693          	addi	a3,a3,-1930 # ffffffffc0205fb8 <default_pmm_manager+0x318>
ffffffffc020274a:	00003617          	auipc	a2,0x3
ffffffffc020274e:	1be60613          	addi	a2,a2,446 # ffffffffc0205908 <commands+0x878>
ffffffffc0202752:	16b00593          	li	a1,363
ffffffffc0202756:	00003517          	auipc	a0,0x3
ffffffffc020275a:	68a50513          	addi	a0,a0,1674 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc020275e:	cf3fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202762:	00004697          	auipc	a3,0x4
ffffffffc0202766:	83e68693          	addi	a3,a3,-1986 # ffffffffc0205fa0 <default_pmm_manager+0x300>
ffffffffc020276a:	00003617          	auipc	a2,0x3
ffffffffc020276e:	19e60613          	addi	a2,a2,414 # ffffffffc0205908 <commands+0x878>
ffffffffc0202772:	16a00593          	li	a1,362
ffffffffc0202776:	00003517          	auipc	a0,0x3
ffffffffc020277a:	66a50513          	addi	a0,a0,1642 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc020277e:	cd3fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0202782:	00004697          	auipc	a3,0x4
ffffffffc0202786:	92e68693          	addi	a3,a3,-1746 # ffffffffc02060b0 <default_pmm_manager+0x410>
ffffffffc020278a:	00003617          	auipc	a2,0x3
ffffffffc020278e:	17e60613          	addi	a2,a2,382 # ffffffffc0205908 <commands+0x878>
ffffffffc0202792:	17900593          	li	a1,377
ffffffffc0202796:	00003517          	auipc	a0,0x3
ffffffffc020279a:	64a50513          	addi	a0,a0,1610 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc020279e:	cb3fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc02027a2:	00004697          	auipc	a3,0x4
ffffffffc02027a6:	8f668693          	addi	a3,a3,-1802 # ffffffffc0206098 <default_pmm_manager+0x3f8>
ffffffffc02027aa:	00003617          	auipc	a2,0x3
ffffffffc02027ae:	15e60613          	addi	a2,a2,350 # ffffffffc0205908 <commands+0x878>
ffffffffc02027b2:	17700593          	li	a1,375
ffffffffc02027b6:	00003517          	auipc	a0,0x3
ffffffffc02027ba:	62a50513          	addi	a0,a0,1578 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc02027be:	c93fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc02027c2:	00004697          	auipc	a3,0x4
ffffffffc02027c6:	8be68693          	addi	a3,a3,-1858 # ffffffffc0206080 <default_pmm_manager+0x3e0>
ffffffffc02027ca:	00003617          	auipc	a2,0x3
ffffffffc02027ce:	13e60613          	addi	a2,a2,318 # ffffffffc0205908 <commands+0x878>
ffffffffc02027d2:	17600593          	li	a1,374
ffffffffc02027d6:	00003517          	auipc	a0,0x3
ffffffffc02027da:	60a50513          	addi	a0,a0,1546 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc02027de:	c73fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(*ptep & PTE_W);
ffffffffc02027e2:	00004697          	auipc	a3,0x4
ffffffffc02027e6:	88e68693          	addi	a3,a3,-1906 # ffffffffc0206070 <default_pmm_manager+0x3d0>
ffffffffc02027ea:	00003617          	auipc	a2,0x3
ffffffffc02027ee:	11e60613          	addi	a2,a2,286 # ffffffffc0205908 <commands+0x878>
ffffffffc02027f2:	17500593          	li	a1,373
ffffffffc02027f6:	00003517          	auipc	a0,0x3
ffffffffc02027fa:	5ea50513          	addi	a0,a0,1514 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc02027fe:	c53fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202802:	00004697          	auipc	a3,0x4
ffffffffc0202806:	85e68693          	addi	a3,a3,-1954 # ffffffffc0206060 <default_pmm_manager+0x3c0>
ffffffffc020280a:	00003617          	auipc	a2,0x3
ffffffffc020280e:	0fe60613          	addi	a2,a2,254 # ffffffffc0205908 <commands+0x878>
ffffffffc0202812:	17400593          	li	a1,372
ffffffffc0202816:	00003517          	auipc	a0,0x3
ffffffffc020281a:	5ca50513          	addi	a0,a0,1482 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc020281e:	c33fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202822:	00004697          	auipc	a3,0x4
ffffffffc0202826:	80e68693          	addi	a3,a3,-2034 # ffffffffc0206030 <default_pmm_manager+0x390>
ffffffffc020282a:	00003617          	auipc	a2,0x3
ffffffffc020282e:	0de60613          	addi	a2,a2,222 # ffffffffc0205908 <commands+0x878>
ffffffffc0202832:	17300593          	li	a1,371
ffffffffc0202836:	00003517          	auipc	a0,0x3
ffffffffc020283a:	5aa50513          	addi	a0,a0,1450 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc020283e:	c13fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202842:	00003697          	auipc	a3,0x3
ffffffffc0202846:	7b668693          	addi	a3,a3,1974 # ffffffffc0205ff8 <default_pmm_manager+0x358>
ffffffffc020284a:	00003617          	auipc	a2,0x3
ffffffffc020284e:	0be60613          	addi	a2,a2,190 # ffffffffc0205908 <commands+0x878>
ffffffffc0202852:	17200593          	li	a1,370
ffffffffc0202856:	00003517          	auipc	a0,0x3
ffffffffc020285a:	58a50513          	addi	a0,a0,1418 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc020285e:	bf3fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202862:	00003697          	auipc	a3,0x3
ffffffffc0202866:	76e68693          	addi	a3,a3,1902 # ffffffffc0205fd0 <default_pmm_manager+0x330>
ffffffffc020286a:	00003617          	auipc	a2,0x3
ffffffffc020286e:	09e60613          	addi	a2,a2,158 # ffffffffc0205908 <commands+0x878>
ffffffffc0202872:	16f00593          	li	a1,367
ffffffffc0202876:	00003517          	auipc	a0,0x3
ffffffffc020287a:	56a50513          	addi	a0,a0,1386 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc020287e:	bd3fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202882:	00004697          	auipc	a3,0x4
ffffffffc0202886:	8a668693          	addi	a3,a3,-1882 # ffffffffc0206128 <default_pmm_manager+0x488>
ffffffffc020288a:	00003617          	auipc	a2,0x3
ffffffffc020288e:	07e60613          	addi	a2,a2,126 # ffffffffc0205908 <commands+0x878>
ffffffffc0202892:	18500593          	li	a1,389
ffffffffc0202896:	00003517          	auipc	a0,0x3
ffffffffc020289a:	54a50513          	addi	a0,a0,1354 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc020289e:	bb3fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02028a2:	00004697          	auipc	a3,0x4
ffffffffc02028a6:	85668693          	addi	a3,a3,-1962 # ffffffffc02060f8 <default_pmm_manager+0x458>
ffffffffc02028aa:	00003617          	auipc	a2,0x3
ffffffffc02028ae:	05e60613          	addi	a2,a2,94 # ffffffffc0205908 <commands+0x878>
ffffffffc02028b2:	18200593          	li	a1,386
ffffffffc02028b6:	00003517          	auipc	a0,0x3
ffffffffc02028ba:	52a50513          	addi	a0,a0,1322 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc02028be:	b93fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02028c2:	00003697          	auipc	a3,0x3
ffffffffc02028c6:	6f668693          	addi	a3,a3,1782 # ffffffffc0205fb8 <default_pmm_manager+0x318>
ffffffffc02028ca:	00003617          	auipc	a2,0x3
ffffffffc02028ce:	03e60613          	addi	a2,a2,62 # ffffffffc0205908 <commands+0x878>
ffffffffc02028d2:	18100593          	li	a1,385
ffffffffc02028d6:	00003517          	auipc	a0,0x3
ffffffffc02028da:	50a50513          	addi	a0,a0,1290 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc02028de:	b73fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc02028e2:	00004697          	auipc	a3,0x4
ffffffffc02028e6:	82e68693          	addi	a3,a3,-2002 # ffffffffc0206110 <default_pmm_manager+0x470>
ffffffffc02028ea:	00003617          	auipc	a2,0x3
ffffffffc02028ee:	01e60613          	addi	a2,a2,30 # ffffffffc0205908 <commands+0x878>
ffffffffc02028f2:	17e00593          	li	a1,382
ffffffffc02028f6:	00003517          	auipc	a0,0x3
ffffffffc02028fa:	4ea50513          	addi	a0,a0,1258 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc02028fe:	b53fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202902:	00003697          	auipc	a3,0x3
ffffffffc0202906:	69e68693          	addi	a3,a3,1694 # ffffffffc0205fa0 <default_pmm_manager+0x300>
ffffffffc020290a:	00003617          	auipc	a2,0x3
ffffffffc020290e:	ffe60613          	addi	a2,a2,-2 # ffffffffc0205908 <commands+0x878>
ffffffffc0202912:	17d00593          	li	a1,381
ffffffffc0202916:	00003517          	auipc	a0,0x3
ffffffffc020291a:	4ca50513          	addi	a0,a0,1226 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc020291e:	b33fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202922:	00003697          	auipc	a3,0x3
ffffffffc0202926:	70e68693          	addi	a3,a3,1806 # ffffffffc0206030 <default_pmm_manager+0x390>
ffffffffc020292a:	00003617          	auipc	a2,0x3
ffffffffc020292e:	fde60613          	addi	a2,a2,-34 # ffffffffc0205908 <commands+0x878>
ffffffffc0202932:	17c00593          	li	a1,380
ffffffffc0202936:	00003517          	auipc	a0,0x3
ffffffffc020293a:	4aa50513          	addi	a0,a0,1194 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc020293e:	b13fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202942:	00003697          	auipc	a3,0x3
ffffffffc0202946:	7b668693          	addi	a3,a3,1974 # ffffffffc02060f8 <default_pmm_manager+0x458>
ffffffffc020294a:	00003617          	auipc	a2,0x3
ffffffffc020294e:	fbe60613          	addi	a2,a2,-66 # ffffffffc0205908 <commands+0x878>
ffffffffc0202952:	17b00593          	li	a1,379
ffffffffc0202956:	00003517          	auipc	a0,0x3
ffffffffc020295a:	48a50513          	addi	a0,a0,1162 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc020295e:	af3fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202962:	00003697          	auipc	a3,0x3
ffffffffc0202966:	77e68693          	addi	a3,a3,1918 # ffffffffc02060e0 <default_pmm_manager+0x440>
ffffffffc020296a:	00003617          	auipc	a2,0x3
ffffffffc020296e:	f9e60613          	addi	a2,a2,-98 # ffffffffc0205908 <commands+0x878>
ffffffffc0202972:	17a00593          	li	a1,378
ffffffffc0202976:	00003517          	auipc	a0,0x3
ffffffffc020297a:	46a50513          	addi	a0,a0,1130 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc020297e:	ad3fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0202982:	00003697          	auipc	a3,0x3
ffffffffc0202986:	7e668693          	addi	a3,a3,2022 # ffffffffc0206168 <default_pmm_manager+0x4c8>
ffffffffc020298a:	00003617          	auipc	a2,0x3
ffffffffc020298e:	f7e60613          	addi	a2,a2,-130 # ffffffffc0205908 <commands+0x878>
ffffffffc0202992:	19000593          	li	a1,400
ffffffffc0202996:	00003517          	auipc	a0,0x3
ffffffffc020299a:	44a50513          	addi	a0,a0,1098 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc020299e:	ab3fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02029a2:	00003697          	auipc	a3,0x3
ffffffffc02029a6:	4f668693          	addi	a3,a3,1270 # ffffffffc0205e98 <default_pmm_manager+0x1f8>
ffffffffc02029aa:	00003617          	auipc	a2,0x3
ffffffffc02029ae:	f5e60613          	addi	a2,a2,-162 # ffffffffc0205908 <commands+0x878>
ffffffffc02029b2:	16000593          	li	a1,352
ffffffffc02029b6:	00003517          	auipc	a0,0x3
ffffffffc02029ba:	42a50513          	addi	a0,a0,1066 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc02029be:	a93fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc02029c2:	00004697          	auipc	a3,0x4
ffffffffc02029c6:	83e68693          	addi	a3,a3,-1986 # ffffffffc0206200 <default_pmm_manager+0x560>
ffffffffc02029ca:	00003617          	auipc	a2,0x3
ffffffffc02029ce:	f3e60613          	addi	a2,a2,-194 # ffffffffc0205908 <commands+0x878>
ffffffffc02029d2:	1a100593          	li	a1,417
ffffffffc02029d6:	00003517          	auipc	a0,0x3
ffffffffc02029da:	40a50513          	addi	a0,a0,1034 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc02029de:	a73fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc02029e2:	00003617          	auipc	a2,0x3
ffffffffc02029e6:	34660613          	addi	a2,a2,838 # ffffffffc0205d28 <default_pmm_manager+0x88>
ffffffffc02029ea:	0c300593          	li	a1,195
ffffffffc02029ee:	00003517          	auipc	a0,0x3
ffffffffc02029f2:	3f250513          	addi	a0,a0,1010 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc02029f6:	a5bfd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(page_ref(p) == 2);
ffffffffc02029fa:	00004697          	auipc	a3,0x4
ffffffffc02029fe:	8ae68693          	addi	a3,a3,-1874 # ffffffffc02062a8 <default_pmm_manager+0x608>
ffffffffc0202a02:	00003617          	auipc	a2,0x3
ffffffffc0202a06:	f0660613          	addi	a2,a2,-250 # ffffffffc0205908 <commands+0x878>
ffffffffc0202a0a:	1a800593          	li	a1,424
ffffffffc0202a0e:	00003517          	auipc	a0,0x3
ffffffffc0202a12:	3d250513          	addi	a0,a0,978 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc0202a16:	a3bfd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202a1a:	00004697          	auipc	a3,0x4
ffffffffc0202a1e:	84e68693          	addi	a3,a3,-1970 # ffffffffc0206268 <default_pmm_manager+0x5c8>
ffffffffc0202a22:	00003617          	auipc	a2,0x3
ffffffffc0202a26:	ee660613          	addi	a2,a2,-282 # ffffffffc0205908 <commands+0x878>
ffffffffc0202a2a:	1a700593          	li	a1,423
ffffffffc0202a2e:	00003517          	auipc	a0,0x3
ffffffffc0202a32:	3b250513          	addi	a0,a0,946 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc0202a36:	a1bfd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202a3a:	00004697          	auipc	a3,0x4
ffffffffc0202a3e:	81668693          	addi	a3,a3,-2026 # ffffffffc0206250 <default_pmm_manager+0x5b0>
ffffffffc0202a42:	00003617          	auipc	a2,0x3
ffffffffc0202a46:	ec660613          	addi	a2,a2,-314 # ffffffffc0205908 <commands+0x878>
ffffffffc0202a4a:	1a600593          	li	a1,422
ffffffffc0202a4e:	00003517          	auipc	a0,0x3
ffffffffc0202a52:	39250513          	addi	a0,a0,914 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc0202a56:	9fbfd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202a5a:	00003697          	auipc	a3,0x3
ffffffffc0202a5e:	7be68693          	addi	a3,a3,1982 # ffffffffc0206218 <default_pmm_manager+0x578>
ffffffffc0202a62:	00003617          	auipc	a2,0x3
ffffffffc0202a66:	ea660613          	addi	a2,a2,-346 # ffffffffc0205908 <commands+0x878>
ffffffffc0202a6a:	1a500593          	li	a1,421
ffffffffc0202a6e:	00003517          	auipc	a0,0x3
ffffffffc0202a72:	37250513          	addi	a0,a0,882 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc0202a76:	9dbfd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0202a7a:	00003697          	auipc	a3,0x3
ffffffffc0202a7e:	6c668693          	addi	a3,a3,1734 # ffffffffc0206140 <default_pmm_manager+0x4a0>
ffffffffc0202a82:	00003617          	auipc	a2,0x3
ffffffffc0202a86:	e8660613          	addi	a2,a2,-378 # ffffffffc0205908 <commands+0x878>
ffffffffc0202a8a:	18800593          	li	a1,392
ffffffffc0202a8e:	00003517          	auipc	a0,0x3
ffffffffc0202a92:	35250513          	addi	a0,a0,850 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc0202a96:	9bbfd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202a9a:	00003697          	auipc	a3,0x3
ffffffffc0202a9e:	65e68693          	addi	a3,a3,1630 # ffffffffc02060f8 <default_pmm_manager+0x458>
ffffffffc0202aa2:	00003617          	auipc	a2,0x3
ffffffffc0202aa6:	e6660613          	addi	a2,a2,-410 # ffffffffc0205908 <commands+0x878>
ffffffffc0202aaa:	18600593          	li	a1,390
ffffffffc0202aae:	00003517          	auipc	a0,0x3
ffffffffc0202ab2:	33250513          	addi	a0,a0,818 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc0202ab6:	99bfd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0202aba:	00003697          	auipc	a3,0x3
ffffffffc0202abe:	45e68693          	addi	a3,a3,1118 # ffffffffc0205f18 <default_pmm_manager+0x278>
ffffffffc0202ac2:	00003617          	auipc	a2,0x3
ffffffffc0202ac6:	e4660613          	addi	a2,a2,-442 # ffffffffc0205908 <commands+0x878>
ffffffffc0202aca:	16600593          	li	a1,358
ffffffffc0202ace:	00003517          	auipc	a0,0x3
ffffffffc0202ad2:	31250513          	addi	a0,a0,786 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc0202ad6:	97bfd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0202ada:	00003697          	auipc	a3,0x3
ffffffffc0202ade:	41668693          	addi	a3,a3,1046 # ffffffffc0205ef0 <default_pmm_manager+0x250>
ffffffffc0202ae2:	00003617          	auipc	a2,0x3
ffffffffc0202ae6:	e2660613          	addi	a2,a2,-474 # ffffffffc0205908 <commands+0x878>
ffffffffc0202aea:	16200593          	li	a1,354
ffffffffc0202aee:	00003517          	auipc	a0,0x3
ffffffffc0202af2:	2f250513          	addi	a0,a0,754 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc0202af6:	95bfd0ef          	jal	ra,ffffffffc0200450 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202afa:	00003617          	auipc	a2,0x3
ffffffffc0202afe:	22e60613          	addi	a2,a2,558 # ffffffffc0205d28 <default_pmm_manager+0x88>
ffffffffc0202b02:	07f00593          	li	a1,127
ffffffffc0202b06:	00003517          	auipc	a0,0x3
ffffffffc0202b0a:	2da50513          	addi	a0,a0,730 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc0202b0e:	943fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0202b12:	00003697          	auipc	a3,0x3
ffffffffc0202b16:	65668693          	addi	a3,a3,1622 # ffffffffc0206168 <default_pmm_manager+0x4c8>
ffffffffc0202b1a:	00003617          	auipc	a2,0x3
ffffffffc0202b1e:	dee60613          	addi	a2,a2,-530 # ffffffffc0205908 <commands+0x878>
ffffffffc0202b22:	1b800593          	li	a1,440
ffffffffc0202b26:	00003517          	auipc	a0,0x3
ffffffffc0202b2a:	2ba50513          	addi	a0,a0,698 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc0202b2e:	923fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202b32:	00003697          	auipc	a3,0x3
ffffffffc0202b36:	7de68693          	addi	a3,a3,2014 # ffffffffc0206310 <default_pmm_manager+0x670>
ffffffffc0202b3a:	00003617          	auipc	a2,0x3
ffffffffc0202b3e:	dce60613          	addi	a2,a2,-562 # ffffffffc0205908 <commands+0x878>
ffffffffc0202b42:	1af00593          	li	a1,431
ffffffffc0202b46:	00003517          	auipc	a0,0x3
ffffffffc0202b4a:	29a50513          	addi	a0,a0,666 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc0202b4e:	903fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202b52:	00003697          	auipc	a3,0x3
ffffffffc0202b56:	78668693          	addi	a3,a3,1926 # ffffffffc02062d8 <default_pmm_manager+0x638>
ffffffffc0202b5a:	00003617          	auipc	a2,0x3
ffffffffc0202b5e:	dae60613          	addi	a2,a2,-594 # ffffffffc0205908 <commands+0x878>
ffffffffc0202b62:	1ac00593          	li	a1,428
ffffffffc0202b66:	00003517          	auipc	a0,0x3
ffffffffc0202b6a:	27a50513          	addi	a0,a0,634 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc0202b6e:	8e3fd0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc0202b72 <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202b72:	12058073          	sfence.vma	a1
}
ffffffffc0202b76:	8082                	ret

ffffffffc0202b78 <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0202b78:	7179                	addi	sp,sp,-48
ffffffffc0202b7a:	e84a                	sd	s2,16(sp)
ffffffffc0202b7c:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc0202b7e:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0202b80:	f022                	sd	s0,32(sp)
ffffffffc0202b82:	ec26                	sd	s1,24(sp)
ffffffffc0202b84:	e44e                	sd	s3,8(sp)
ffffffffc0202b86:	f406                	sd	ra,40(sp)
ffffffffc0202b88:	84ae                	mv	s1,a1
ffffffffc0202b8a:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc0202b8c:	844ff0ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc0202b90:	842a                	mv	s0,a0
    if (page != NULL) {
ffffffffc0202b92:	cd19                	beqz	a0,ffffffffc0202bb0 <pgdir_alloc_page+0x38>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc0202b94:	85aa                	mv	a1,a0
ffffffffc0202b96:	86ce                	mv	a3,s3
ffffffffc0202b98:	8626                	mv	a2,s1
ffffffffc0202b9a:	854a                	mv	a0,s2
ffffffffc0202b9c:	c22ff0ef          	jal	ra,ffffffffc0201fbe <page_insert>
ffffffffc0202ba0:	ed39                	bnez	a0,ffffffffc0202bfe <pgdir_alloc_page+0x86>
        if (swap_init_ok) {
ffffffffc0202ba2:	00013797          	auipc	a5,0x13
ffffffffc0202ba6:	8fe78793          	addi	a5,a5,-1794 # ffffffffc02154a0 <swap_init_ok>
ffffffffc0202baa:	439c                	lw	a5,0(a5)
ffffffffc0202bac:	2781                	sext.w	a5,a5
ffffffffc0202bae:	eb89                	bnez	a5,ffffffffc0202bc0 <pgdir_alloc_page+0x48>
}
ffffffffc0202bb0:	8522                	mv	a0,s0
ffffffffc0202bb2:	70a2                	ld	ra,40(sp)
ffffffffc0202bb4:	7402                	ld	s0,32(sp)
ffffffffc0202bb6:	64e2                	ld	s1,24(sp)
ffffffffc0202bb8:	6942                	ld	s2,16(sp)
ffffffffc0202bba:	69a2                	ld	s3,8(sp)
ffffffffc0202bbc:	6145                	addi	sp,sp,48
ffffffffc0202bbe:	8082                	ret
            swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc0202bc0:	00013797          	auipc	a5,0x13
ffffffffc0202bc4:	a2878793          	addi	a5,a5,-1496 # ffffffffc02155e8 <check_mm_struct>
ffffffffc0202bc8:	6388                	ld	a0,0(a5)
ffffffffc0202bca:	4681                	li	a3,0
ffffffffc0202bcc:	8622                	mv	a2,s0
ffffffffc0202bce:	85a6                	mv	a1,s1
ffffffffc0202bd0:	7e8000ef          	jal	ra,ffffffffc02033b8 <swap_map_swappable>
            assert(page_ref(page) == 1);
ffffffffc0202bd4:	4018                	lw	a4,0(s0)
            page->pra_vaddr = la;
ffffffffc0202bd6:	e024                	sd	s1,64(s0)
            assert(page_ref(page) == 1);
ffffffffc0202bd8:	4785                	li	a5,1
ffffffffc0202bda:	fcf70be3          	beq	a4,a5,ffffffffc0202bb0 <pgdir_alloc_page+0x38>
ffffffffc0202bde:	00003697          	auipc	a3,0x3
ffffffffc0202be2:	21268693          	addi	a3,a3,530 # ffffffffc0205df0 <default_pmm_manager+0x150>
ffffffffc0202be6:	00003617          	auipc	a2,0x3
ffffffffc0202bea:	d2260613          	addi	a2,a2,-734 # ffffffffc0205908 <commands+0x878>
ffffffffc0202bee:	14800593          	li	a1,328
ffffffffc0202bf2:	00003517          	auipc	a0,0x3
ffffffffc0202bf6:	1ee50513          	addi	a0,a0,494 # ffffffffc0205de0 <default_pmm_manager+0x140>
ffffffffc0202bfa:	857fd0ef          	jal	ra,ffffffffc0200450 <__panic>
            free_page(page);
ffffffffc0202bfe:	8522                	mv	a0,s0
ffffffffc0202c00:	4585                	li	a1,1
ffffffffc0202c02:	856ff0ef          	jal	ra,ffffffffc0201c58 <free_pages>
            return NULL;
ffffffffc0202c06:	4401                	li	s0,0
ffffffffc0202c08:	b765                	j	ffffffffc0202bb0 <pgdir_alloc_page+0x38>

ffffffffc0202c0a <swap_init>:

static void check_swap(void);

int
swap_init(void)
{
ffffffffc0202c0a:	7135                	addi	sp,sp,-160
ffffffffc0202c0c:	ed06                	sd	ra,152(sp)
ffffffffc0202c0e:	e922                	sd	s0,144(sp)
ffffffffc0202c10:	e526                	sd	s1,136(sp)
ffffffffc0202c12:	e14a                	sd	s2,128(sp)
ffffffffc0202c14:	fcce                	sd	s3,120(sp)
ffffffffc0202c16:	f8d2                	sd	s4,112(sp)
ffffffffc0202c18:	f4d6                	sd	s5,104(sp)
ffffffffc0202c1a:	f0da                	sd	s6,96(sp)
ffffffffc0202c1c:	ecde                	sd	s7,88(sp)
ffffffffc0202c1e:	e8e2                	sd	s8,80(sp)
ffffffffc0202c20:	e4e6                	sd	s9,72(sp)
ffffffffc0202c22:	e0ea                	sd	s10,64(sp)
ffffffffc0202c24:	fc6e                	sd	s11,56(sp)
     swapfs_init();
ffffffffc0202c26:	4ce010ef          	jal	ra,ffffffffc02040f4 <swapfs_init>
     // if (!(1024 <= max_swap_offset && max_swap_offset < MAX_SWAP_OFFSET_LIMIT))
     // {
     //      panic("bad max_swap_offset %08x.\n", max_swap_offset);
     // }
     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc0202c2a:	00013797          	auipc	a5,0x13
ffffffffc0202c2e:	96678793          	addi	a5,a5,-1690 # ffffffffc0215590 <max_swap_offset>
ffffffffc0202c32:	6394                	ld	a3,0(a5)
ffffffffc0202c34:	010007b7          	lui	a5,0x1000
ffffffffc0202c38:	17e1                	addi	a5,a5,-8
ffffffffc0202c3a:	ff968713          	addi	a4,a3,-7
ffffffffc0202c3e:	4ce7ed63          	bltu	a5,a4,ffffffffc0203118 <swap_init+0x50e>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }

     sm = &swap_manager_clock;
ffffffffc0202c42:	00007797          	auipc	a5,0x7
ffffffffc0202c46:	3ce78793          	addi	a5,a5,974 # ffffffffc020a010 <swap_manager_clock>
     int r = sm->init();
ffffffffc0202c4a:	6798                	ld	a4,8(a5)
     sm = &swap_manager_clock;
ffffffffc0202c4c:	00013697          	auipc	a3,0x13
ffffffffc0202c50:	84f6b623          	sd	a5,-1972(a3) # ffffffffc0215498 <sm>
     int r = sm->init();
ffffffffc0202c54:	9702                	jalr	a4
ffffffffc0202c56:	8aaa                	mv	s5,a0
     
     if (r == 0)
ffffffffc0202c58:	c10d                	beqz	a0,ffffffffc0202c7a <swap_init+0x70>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc0202c5a:	60ea                	ld	ra,152(sp)
ffffffffc0202c5c:	644a                	ld	s0,144(sp)
ffffffffc0202c5e:	8556                	mv	a0,s5
ffffffffc0202c60:	64aa                	ld	s1,136(sp)
ffffffffc0202c62:	690a                	ld	s2,128(sp)
ffffffffc0202c64:	79e6                	ld	s3,120(sp)
ffffffffc0202c66:	7a46                	ld	s4,112(sp)
ffffffffc0202c68:	7aa6                	ld	s5,104(sp)
ffffffffc0202c6a:	7b06                	ld	s6,96(sp)
ffffffffc0202c6c:	6be6                	ld	s7,88(sp)
ffffffffc0202c6e:	6c46                	ld	s8,80(sp)
ffffffffc0202c70:	6ca6                	ld	s9,72(sp)
ffffffffc0202c72:	6d06                	ld	s10,64(sp)
ffffffffc0202c74:	7de2                	ld	s11,56(sp)
ffffffffc0202c76:	610d                	addi	sp,sp,160
ffffffffc0202c78:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0202c7a:	00013797          	auipc	a5,0x13
ffffffffc0202c7e:	81e78793          	addi	a5,a5,-2018 # ffffffffc0215498 <sm>
ffffffffc0202c82:	639c                	ld	a5,0(a5)
ffffffffc0202c84:	00003517          	auipc	a0,0x3
ffffffffc0202c88:	75450513          	addi	a0,a0,1876 # ffffffffc02063d8 <default_pmm_manager+0x738>
    return listelm->next;
ffffffffc0202c8c:	00013417          	auipc	s0,0x13
ffffffffc0202c90:	84440413          	addi	s0,s0,-1980 # ffffffffc02154d0 <free_area>
ffffffffc0202c94:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc0202c96:	4785                	li	a5,1
ffffffffc0202c98:	00013717          	auipc	a4,0x13
ffffffffc0202c9c:	80f72423          	sw	a5,-2040(a4) # ffffffffc02154a0 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0202ca0:	ceefd0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc0202ca4:	641c                	ld	a5,8(s0)
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202ca6:	38878d63          	beq	a5,s0,ffffffffc0203040 <swap_init+0x436>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0202caa:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202cae:	8305                	srli	a4,a4,0x1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0202cb0:	8b05                	andi	a4,a4,1
ffffffffc0202cb2:	38070b63          	beqz	a4,ffffffffc0203048 <swap_init+0x43e>
     int ret, count = 0, total = 0, i;
ffffffffc0202cb6:	4481                	li	s1,0
ffffffffc0202cb8:	4901                	li	s2,0
ffffffffc0202cba:	a031                	j	ffffffffc0202cc6 <swap_init+0xbc>
ffffffffc0202cbc:	fe87b703          	ld	a4,-24(a5)
        assert(PageProperty(p));
ffffffffc0202cc0:	8b09                	andi	a4,a4,2
ffffffffc0202cc2:	38070363          	beqz	a4,ffffffffc0203048 <swap_init+0x43e>
        count ++, total += p->property;
ffffffffc0202cc6:	ff07a703          	lw	a4,-16(a5)
ffffffffc0202cca:	679c                	ld	a5,8(a5)
ffffffffc0202ccc:	2905                	addiw	s2,s2,1
ffffffffc0202cce:	9cb9                	addw	s1,s1,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202cd0:	fe8796e3          	bne	a5,s0,ffffffffc0202cbc <swap_init+0xb2>
ffffffffc0202cd4:	89a6                	mv	s3,s1
     }
     assert(total == nr_free_pages());
ffffffffc0202cd6:	fc9fe0ef          	jal	ra,ffffffffc0201c9e <nr_free_pages>
ffffffffc0202cda:	6b351763          	bne	a0,s3,ffffffffc0203388 <swap_init+0x77e>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc0202cde:	8626                	mv	a2,s1
ffffffffc0202ce0:	85ca                	mv	a1,s2
ffffffffc0202ce2:	00003517          	auipc	a0,0x3
ffffffffc0202ce6:	70e50513          	addi	a0,a0,1806 # ffffffffc02063f0 <default_pmm_manager+0x750>
ffffffffc0202cea:	ca4fd0ef          	jal	ra,ffffffffc020018e <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc0202cee:	407000ef          	jal	ra,ffffffffc02038f4 <mm_create>
ffffffffc0202cf2:	8baa                	mv	s7,a0
     assert(mm != NULL);
ffffffffc0202cf4:	62050a63          	beqz	a0,ffffffffc0203328 <swap_init+0x71e>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc0202cf8:	00013797          	auipc	a5,0x13
ffffffffc0202cfc:	8f078793          	addi	a5,a5,-1808 # ffffffffc02155e8 <check_mm_struct>
ffffffffc0202d00:	639c                	ld	a5,0(a5)
ffffffffc0202d02:	64079363          	bnez	a5,ffffffffc0203348 <swap_init+0x73e>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202d06:	00012797          	auipc	a5,0x12
ffffffffc0202d0a:	78278793          	addi	a5,a5,1922 # ffffffffc0215488 <boot_pgdir>
ffffffffc0202d0e:	0007bb03          	ld	s6,0(a5)
     check_mm_struct = mm;
ffffffffc0202d12:	00013797          	auipc	a5,0x13
ffffffffc0202d16:	8ca7bb23          	sd	a0,-1834(a5) # ffffffffc02155e8 <check_mm_struct>
     assert(pgdir[0] == 0);
ffffffffc0202d1a:	000b3783          	ld	a5,0(s6)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202d1e:	01653c23          	sd	s6,24(a0)
     assert(pgdir[0] == 0);
ffffffffc0202d22:	50079763          	bnez	a5,ffffffffc0203230 <swap_init+0x626>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc0202d26:	6599                	lui	a1,0x6
ffffffffc0202d28:	460d                	li	a2,3
ffffffffc0202d2a:	6505                	lui	a0,0x1
ffffffffc0202d2c:	415000ef          	jal	ra,ffffffffc0203940 <vma_create>
ffffffffc0202d30:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc0202d32:	50050f63          	beqz	a0,ffffffffc0203250 <swap_init+0x646>

     insert_vma_struct(mm, vma);
ffffffffc0202d36:	855e                	mv	a0,s7
ffffffffc0202d38:	475000ef          	jal	ra,ffffffffc02039ac <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc0202d3c:	00003517          	auipc	a0,0x3
ffffffffc0202d40:	72450513          	addi	a0,a0,1828 # ffffffffc0206460 <default_pmm_manager+0x7c0>
ffffffffc0202d44:	c4afd0ef          	jal	ra,ffffffffc020018e <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc0202d48:	018bb503          	ld	a0,24(s7)
ffffffffc0202d4c:	4605                	li	a2,1
ffffffffc0202d4e:	6585                	lui	a1,0x1
ffffffffc0202d50:	f8ffe0ef          	jal	ra,ffffffffc0201cde <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc0202d54:	50050e63          	beqz	a0,ffffffffc0203270 <swap_init+0x666>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0202d58:	00003517          	auipc	a0,0x3
ffffffffc0202d5c:	75850513          	addi	a0,a0,1880 # ffffffffc02064b0 <default_pmm_manager+0x810>
ffffffffc0202d60:	00012997          	auipc	s3,0x12
ffffffffc0202d64:	7a898993          	addi	s3,s3,1960 # ffffffffc0215508 <check_rp>
ffffffffc0202d68:	c26fd0ef          	jal	ra,ffffffffc020018e <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202d6c:	00012a17          	auipc	s4,0x12
ffffffffc0202d70:	7bca0a13          	addi	s4,s4,1980 # ffffffffc0215528 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0202d74:	8c4e                	mv	s8,s3
          check_rp[i] = alloc_page();
ffffffffc0202d76:	4505                	li	a0,1
ffffffffc0202d78:	e59fe0ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
ffffffffc0202d7c:	00ac3023          	sd	a0,0(s8) # 80000 <BASE_ADDRESS-0xffffffffc0180000>
          assert(check_rp[i] != NULL );
ffffffffc0202d80:	34050c63          	beqz	a0,ffffffffc02030d8 <swap_init+0x4ce>
ffffffffc0202d84:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc0202d86:	8b89                	andi	a5,a5,2
ffffffffc0202d88:	32079863          	bnez	a5,ffffffffc02030b8 <swap_init+0x4ae>
ffffffffc0202d8c:	0c21                	addi	s8,s8,8
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202d8e:	ff4c14e3          	bne	s8,s4,ffffffffc0202d76 <swap_init+0x16c>
     }
     list_entry_t free_list_store = free_list;
ffffffffc0202d92:	601c                	ld	a5,0(s0)
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc0202d94:	00012c17          	auipc	s8,0x12
ffffffffc0202d98:	774c0c13          	addi	s8,s8,1908 # ffffffffc0215508 <check_rp>
     list_entry_t free_list_store = free_list;
ffffffffc0202d9c:	ec3e                	sd	a5,24(sp)
ffffffffc0202d9e:	641c                	ld	a5,8(s0)
ffffffffc0202da0:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc0202da2:	481c                	lw	a5,16(s0)
ffffffffc0202da4:	f43e                	sd	a5,40(sp)
    elm->prev = elm->next = elm;
ffffffffc0202da6:	00012797          	auipc	a5,0x12
ffffffffc0202daa:	7287b923          	sd	s0,1842(a5) # ffffffffc02154d8 <free_area+0x8>
ffffffffc0202dae:	00012797          	auipc	a5,0x12
ffffffffc0202db2:	7287b123          	sd	s0,1826(a5) # ffffffffc02154d0 <free_area>
     nr_free = 0;
ffffffffc0202db6:	00012797          	auipc	a5,0x12
ffffffffc0202dba:	7207a523          	sw	zero,1834(a5) # ffffffffc02154e0 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc0202dbe:	000c3503          	ld	a0,0(s8)
ffffffffc0202dc2:	4585                	li	a1,1
ffffffffc0202dc4:	0c21                	addi	s8,s8,8
ffffffffc0202dc6:	e93fe0ef          	jal	ra,ffffffffc0201c58 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202dca:	ff4c1ae3          	bne	s8,s4,ffffffffc0202dbe <swap_init+0x1b4>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0202dce:	01042c03          	lw	s8,16(s0)
ffffffffc0202dd2:	4791                	li	a5,4
ffffffffc0202dd4:	52fc1a63          	bne	s8,a5,ffffffffc0203308 <swap_init+0x6fe>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc0202dd8:	00003517          	auipc	a0,0x3
ffffffffc0202ddc:	76050513          	addi	a0,a0,1888 # ffffffffc0206538 <default_pmm_manager+0x898>
ffffffffc0202de0:	baefd0ef          	jal	ra,ffffffffc020018e <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202de4:	6685                	lui	a3,0x1
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc0202de6:	00012797          	auipc	a5,0x12
ffffffffc0202dea:	6a07af23          	sw	zero,1726(a5) # ffffffffc02154a4 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202dee:	4629                	li	a2,10
     pgfault_num=0;
ffffffffc0202df0:	00012797          	auipc	a5,0x12
ffffffffc0202df4:	6b478793          	addi	a5,a5,1716 # ffffffffc02154a4 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202df8:	00c68023          	sb	a2,0(a3) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
     assert(pgfault_num==1);
ffffffffc0202dfc:	4398                	lw	a4,0(a5)
ffffffffc0202dfe:	4585                	li	a1,1
ffffffffc0202e00:	2701                	sext.w	a4,a4
ffffffffc0202e02:	3ab71763          	bne	a4,a1,ffffffffc02031b0 <swap_init+0x5a6>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc0202e06:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==1);
ffffffffc0202e0a:	4394                	lw	a3,0(a5)
ffffffffc0202e0c:	2681                	sext.w	a3,a3
ffffffffc0202e0e:	3ce69163          	bne	a3,a4,ffffffffc02031d0 <swap_init+0x5c6>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc0202e12:	6689                	lui	a3,0x2
ffffffffc0202e14:	462d                	li	a2,11
ffffffffc0202e16:	00c68023          	sb	a2,0(a3) # 2000 <BASE_ADDRESS-0xffffffffc01fe000>
     assert(pgfault_num==2);
ffffffffc0202e1a:	4398                	lw	a4,0(a5)
ffffffffc0202e1c:	4589                	li	a1,2
ffffffffc0202e1e:	2701                	sext.w	a4,a4
ffffffffc0202e20:	30b71863          	bne	a4,a1,ffffffffc0203130 <swap_init+0x526>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc0202e24:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==2);
ffffffffc0202e28:	4394                	lw	a3,0(a5)
ffffffffc0202e2a:	2681                	sext.w	a3,a3
ffffffffc0202e2c:	32e69263          	bne	a3,a4,ffffffffc0203150 <swap_init+0x546>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc0202e30:	668d                	lui	a3,0x3
ffffffffc0202e32:	4631                	li	a2,12
ffffffffc0202e34:	00c68023          	sb	a2,0(a3) # 3000 <BASE_ADDRESS-0xffffffffc01fd000>
     assert(pgfault_num==3);
ffffffffc0202e38:	4398                	lw	a4,0(a5)
ffffffffc0202e3a:	458d                	li	a1,3
ffffffffc0202e3c:	2701                	sext.w	a4,a4
ffffffffc0202e3e:	32b71963          	bne	a4,a1,ffffffffc0203170 <swap_init+0x566>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc0202e42:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==3);
ffffffffc0202e46:	4394                	lw	a3,0(a5)
ffffffffc0202e48:	2681                	sext.w	a3,a3
ffffffffc0202e4a:	34e69363          	bne	a3,a4,ffffffffc0203190 <swap_init+0x586>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc0202e4e:	6691                	lui	a3,0x4
ffffffffc0202e50:	4635                	li	a2,13
ffffffffc0202e52:	00c68023          	sb	a2,0(a3) # 4000 <BASE_ADDRESS-0xffffffffc01fc000>
     assert(pgfault_num==4);
ffffffffc0202e56:	4398                	lw	a4,0(a5)
ffffffffc0202e58:	2701                	sext.w	a4,a4
ffffffffc0202e5a:	39871b63          	bne	a4,s8,ffffffffc02031f0 <swap_init+0x5e6>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc0202e5e:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==4);
ffffffffc0202e62:	439c                	lw	a5,0(a5)
ffffffffc0202e64:	2781                	sext.w	a5,a5
ffffffffc0202e66:	3ae79563          	bne	a5,a4,ffffffffc0203210 <swap_init+0x606>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc0202e6a:	481c                	lw	a5,16(s0)
ffffffffc0202e6c:	42079263          	bnez	a5,ffffffffc0203290 <swap_init+0x686>
ffffffffc0202e70:	00012797          	auipc	a5,0x12
ffffffffc0202e74:	6b878793          	addi	a5,a5,1720 # ffffffffc0215528 <swap_in_seq_no>
ffffffffc0202e78:	00012717          	auipc	a4,0x12
ffffffffc0202e7c:	6d870713          	addi	a4,a4,1752 # ffffffffc0215550 <swap_out_seq_no>
ffffffffc0202e80:	00012617          	auipc	a2,0x12
ffffffffc0202e84:	6d060613          	addi	a2,a2,1744 # ffffffffc0215550 <swap_out_seq_no>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc0202e88:	56fd                	li	a3,-1
ffffffffc0202e8a:	c394                	sw	a3,0(a5)
ffffffffc0202e8c:	c314                	sw	a3,0(a4)
ffffffffc0202e8e:	0791                	addi	a5,a5,4
ffffffffc0202e90:	0711                	addi	a4,a4,4
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc0202e92:	fef61ce3          	bne	a2,a5,ffffffffc0202e8a <swap_init+0x280>
ffffffffc0202e96:	00012817          	auipc	a6,0x12
ffffffffc0202e9a:	71a80813          	addi	a6,a6,1818 # ffffffffc02155b0 <check_ptep>
ffffffffc0202e9e:	00012897          	auipc	a7,0x12
ffffffffc0202ea2:	66a88893          	addi	a7,a7,1642 # ffffffffc0215508 <check_rp>
ffffffffc0202ea6:	6d05                	lui	s10,0x1
    if (PPN(pa) >= npage) {
ffffffffc0202ea8:	00012c97          	auipc	s9,0x12
ffffffffc0202eac:	5e8c8c93          	addi	s9,s9,1512 # ffffffffc0215490 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202eb0:	00004d97          	auipc	s11,0x4
ffffffffc0202eb4:	098d8d93          	addi	s11,s11,152 # ffffffffc0206f48 <nbase>
ffffffffc0202eb8:	00012c17          	auipc	s8,0x12
ffffffffc0202ebc:	648c0c13          	addi	s8,s8,1608 # ffffffffc0215500 <pages>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
ffffffffc0202ec0:	00083023          	sd	zero,0(a6)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202ec4:	4601                	li	a2,0
ffffffffc0202ec6:	85ea                	mv	a1,s10
ffffffffc0202ec8:	855a                	mv	a0,s6
ffffffffc0202eca:	e846                	sd	a7,16(sp)
         check_ptep[i]=0;
ffffffffc0202ecc:	e442                	sd	a6,8(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202ece:	e11fe0ef          	jal	ra,ffffffffc0201cde <get_pte>
ffffffffc0202ed2:	6822                	ld	a6,8(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc0202ed4:	68c2                	ld	a7,16(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202ed6:	00a83023          	sd	a0,0(a6)
         assert(check_ptep[i] != NULL);
ffffffffc0202eda:	20050f63          	beqz	a0,ffffffffc02030f8 <swap_init+0x4ee>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202ede:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0202ee0:	0017f713          	andi	a4,a5,1
ffffffffc0202ee4:	1a070e63          	beqz	a4,ffffffffc02030a0 <swap_init+0x496>
    if (PPN(pa) >= npage) {
ffffffffc0202ee8:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202eec:	078a                	slli	a5,a5,0x2
ffffffffc0202eee:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202ef0:	16e7fc63          	bleu	a4,a5,ffffffffc0203068 <swap_init+0x45e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ef4:	000db703          	ld	a4,0(s11)
ffffffffc0202ef8:	000c3603          	ld	a2,0(s8)
ffffffffc0202efc:	0008b583          	ld	a1,0(a7)
ffffffffc0202f00:	8f99                	sub	a5,a5,a4
ffffffffc0202f02:	e43a                	sd	a4,8(sp)
ffffffffc0202f04:	00379713          	slli	a4,a5,0x3
ffffffffc0202f08:	97ba                	add	a5,a5,a4
ffffffffc0202f0a:	078e                	slli	a5,a5,0x3
ffffffffc0202f0c:	97b2                	add	a5,a5,a2
ffffffffc0202f0e:	16f59963          	bne	a1,a5,ffffffffc0203080 <swap_init+0x476>
ffffffffc0202f12:	6785                	lui	a5,0x1
ffffffffc0202f14:	9d3e                	add	s10,s10,a5
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202f16:	6795                	lui	a5,0x5
ffffffffc0202f18:	0821                	addi	a6,a6,8
ffffffffc0202f1a:	08a1                	addi	a7,a7,8
ffffffffc0202f1c:	fafd12e3          	bne	s10,a5,ffffffffc0202ec0 <swap_init+0x2b6>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc0202f20:	00003517          	auipc	a0,0x3
ffffffffc0202f24:	6c050513          	addi	a0,a0,1728 # ffffffffc02065e0 <default_pmm_manager+0x940>
ffffffffc0202f28:	a66fd0ef          	jal	ra,ffffffffc020018e <cprintf>
    int ret = sm->check_swap();
ffffffffc0202f2c:	00012797          	auipc	a5,0x12
ffffffffc0202f30:	56c78793          	addi	a5,a5,1388 # ffffffffc0215498 <sm>
ffffffffc0202f34:	639c                	ld	a5,0(a5)
ffffffffc0202f36:	7f9c                	ld	a5,56(a5)
ffffffffc0202f38:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();
     assert(ret==0);
ffffffffc0202f3a:	42051763          	bnez	a0,ffffffffc0203368 <swap_init+0x75e>

     nr_free = nr_free_store;
ffffffffc0202f3e:	77a2                	ld	a5,40(sp)
ffffffffc0202f40:	00012717          	auipc	a4,0x12
ffffffffc0202f44:	5af72023          	sw	a5,1440(a4) # ffffffffc02154e0 <free_area+0x10>
     free_list = free_list_store;
ffffffffc0202f48:	67e2                	ld	a5,24(sp)
ffffffffc0202f4a:	00012717          	auipc	a4,0x12
ffffffffc0202f4e:	58f73323          	sd	a5,1414(a4) # ffffffffc02154d0 <free_area>
ffffffffc0202f52:	7782                	ld	a5,32(sp)
ffffffffc0202f54:	00012717          	auipc	a4,0x12
ffffffffc0202f58:	58f73223          	sd	a5,1412(a4) # ffffffffc02154d8 <free_area+0x8>

     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc0202f5c:	0009b503          	ld	a0,0(s3)
ffffffffc0202f60:	4585                	li	a1,1
ffffffffc0202f62:	09a1                	addi	s3,s3,8
ffffffffc0202f64:	cf5fe0ef          	jal	ra,ffffffffc0201c58 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202f68:	ff499ae3          	bne	s3,s4,ffffffffc0202f5c <swap_init+0x352>
     } 

     //free_page(pte2page(*temp_ptep));
     
     mm_destroy(mm);
ffffffffc0202f6c:	855e                	mv	a0,s7
ffffffffc0202f6e:	30d000ef          	jal	ra,ffffffffc0203a7a <mm_destroy>

     pde_t *pd1=pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0202f72:	00012797          	auipc	a5,0x12
ffffffffc0202f76:	51678793          	addi	a5,a5,1302 # ffffffffc0215488 <boot_pgdir>
ffffffffc0202f7a:	639c                	ld	a5,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0202f7c:	000cb703          	ld	a4,0(s9)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202f80:	6394                	ld	a3,0(a5)
ffffffffc0202f82:	068a                	slli	a3,a3,0x2
ffffffffc0202f84:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202f86:	0ee6f163          	bleu	a4,a3,ffffffffc0203068 <swap_init+0x45e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202f8a:	6622                	ld	a2,8(sp)
ffffffffc0202f8c:	000c3503          	ld	a0,0(s8)
ffffffffc0202f90:	40c687b3          	sub	a5,a3,a2
ffffffffc0202f94:	00379693          	slli	a3,a5,0x3
ffffffffc0202f98:	96be                	add	a3,a3,a5
    return page - pages + nbase;
ffffffffc0202f9a:	00003797          	auipc	a5,0x3
ffffffffc0202f9e:	95678793          	addi	a5,a5,-1706 # ffffffffc02058f0 <commands+0x860>
ffffffffc0202fa2:	639c                	ld	a5,0(a5)
    return &pages[PPN(pa) - nbase];
ffffffffc0202fa4:	068e                	slli	a3,a3,0x3
    return page - pages + nbase;
ffffffffc0202fa6:	868d                	srai	a3,a3,0x3
ffffffffc0202fa8:	02f686b3          	mul	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0202fac:	57fd                	li	a5,-1
ffffffffc0202fae:	83b1                	srli	a5,a5,0xc
    return page - pages + nbase;
ffffffffc0202fb0:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202fb2:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202fb4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202fb6:	2ee7fd63          	bleu	a4,a5,ffffffffc02032b0 <swap_init+0x6a6>
     free_page(pde2page(pd0[0]));
ffffffffc0202fba:	00012797          	auipc	a5,0x12
ffffffffc0202fbe:	53678793          	addi	a5,a5,1334 # ffffffffc02154f0 <va_pa_offset>
ffffffffc0202fc2:	639c                	ld	a5,0(a5)
ffffffffc0202fc4:	96be                	add	a3,a3,a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202fc6:	629c                	ld	a5,0(a3)
ffffffffc0202fc8:	078a                	slli	a5,a5,0x2
ffffffffc0202fca:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202fcc:	08e7fe63          	bleu	a4,a5,ffffffffc0203068 <swap_init+0x45e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202fd0:	69a2                	ld	s3,8(sp)
ffffffffc0202fd2:	4585                	li	a1,1
ffffffffc0202fd4:	413787b3          	sub	a5,a5,s3
ffffffffc0202fd8:	00379713          	slli	a4,a5,0x3
ffffffffc0202fdc:	97ba                	add	a5,a5,a4
ffffffffc0202fde:	078e                	slli	a5,a5,0x3
ffffffffc0202fe0:	953e                	add	a0,a0,a5
ffffffffc0202fe2:	c77fe0ef          	jal	ra,ffffffffc0201c58 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202fe6:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc0202fea:	000cb703          	ld	a4,0(s9)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202fee:	078a                	slli	a5,a5,0x2
ffffffffc0202ff0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202ff2:	06e7fb63          	bleu	a4,a5,ffffffffc0203068 <swap_init+0x45e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ff6:	413787b3          	sub	a5,a5,s3
ffffffffc0202ffa:	00379713          	slli	a4,a5,0x3
ffffffffc0202ffe:	000c3503          	ld	a0,0(s8)
ffffffffc0203002:	97ba                	add	a5,a5,a4
ffffffffc0203004:	078e                	slli	a5,a5,0x3
     free_page(pde2page(pd1[0]));
ffffffffc0203006:	4585                	li	a1,1
ffffffffc0203008:	953e                	add	a0,a0,a5
ffffffffc020300a:	c4ffe0ef          	jal	ra,ffffffffc0201c58 <free_pages>
     pgdir[0] = 0;
ffffffffc020300e:	000b3023          	sd	zero,0(s6)
  asm volatile("sfence.vma");
ffffffffc0203012:	12000073          	sfence.vma
    return listelm->next;
ffffffffc0203016:	641c                	ld	a5,8(s0)
     flush_tlb();

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203018:	00878963          	beq	a5,s0,ffffffffc020302a <swap_init+0x420>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc020301c:	ff07a703          	lw	a4,-16(a5)
ffffffffc0203020:	679c                	ld	a5,8(a5)
ffffffffc0203022:	397d                	addiw	s2,s2,-1
ffffffffc0203024:	9c99                	subw	s1,s1,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203026:	fe879be3          	bne	a5,s0,ffffffffc020301c <swap_init+0x412>
     }
     assert(count==0);
ffffffffc020302a:	28091f63          	bnez	s2,ffffffffc02032c8 <swap_init+0x6be>
     assert(total==0);
ffffffffc020302e:	2a049d63          	bnez	s1,ffffffffc02032e8 <swap_init+0x6de>

     cprintf("check_swap() succeeded!\n");
ffffffffc0203032:	00003517          	auipc	a0,0x3
ffffffffc0203036:	5fe50513          	addi	a0,a0,1534 # ffffffffc0206630 <default_pmm_manager+0x990>
ffffffffc020303a:	954fd0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc020303e:	b931                	j	ffffffffc0202c5a <swap_init+0x50>
     int ret, count = 0, total = 0, i;
ffffffffc0203040:	4481                	li	s1,0
ffffffffc0203042:	4901                	li	s2,0
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203044:	4981                	li	s3,0
ffffffffc0203046:	b941                	j	ffffffffc0202cd6 <swap_init+0xcc>
        assert(PageProperty(p));
ffffffffc0203048:	00003697          	auipc	a3,0x3
ffffffffc020304c:	8b068693          	addi	a3,a3,-1872 # ffffffffc02058f8 <commands+0x868>
ffffffffc0203050:	00003617          	auipc	a2,0x3
ffffffffc0203054:	8b860613          	addi	a2,a2,-1864 # ffffffffc0205908 <commands+0x878>
ffffffffc0203058:	0be00593          	li	a1,190
ffffffffc020305c:	00003517          	auipc	a0,0x3
ffffffffc0203060:	36c50513          	addi	a0,a0,876 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc0203064:	becfd0ef          	jal	ra,ffffffffc0200450 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203068:	00003617          	auipc	a2,0x3
ffffffffc020306c:	ce860613          	addi	a2,a2,-792 # ffffffffc0205d50 <default_pmm_manager+0xb0>
ffffffffc0203070:	06200593          	li	a1,98
ffffffffc0203074:	00003517          	auipc	a0,0x3
ffffffffc0203078:	ca450513          	addi	a0,a0,-860 # ffffffffc0205d18 <default_pmm_manager+0x78>
ffffffffc020307c:	bd4fd0ef          	jal	ra,ffffffffc0200450 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0203080:	00003697          	auipc	a3,0x3
ffffffffc0203084:	53868693          	addi	a3,a3,1336 # ffffffffc02065b8 <default_pmm_manager+0x918>
ffffffffc0203088:	00003617          	auipc	a2,0x3
ffffffffc020308c:	88060613          	addi	a2,a2,-1920 # ffffffffc0205908 <commands+0x878>
ffffffffc0203090:	0fe00593          	li	a1,254
ffffffffc0203094:	00003517          	auipc	a0,0x3
ffffffffc0203098:	33450513          	addi	a0,a0,820 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc020309c:	bb4fd0ef          	jal	ra,ffffffffc0200450 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02030a0:	00003617          	auipc	a2,0x3
ffffffffc02030a4:	ed860613          	addi	a2,a2,-296 # ffffffffc0205f78 <default_pmm_manager+0x2d8>
ffffffffc02030a8:	07400593          	li	a1,116
ffffffffc02030ac:	00003517          	auipc	a0,0x3
ffffffffc02030b0:	c6c50513          	addi	a0,a0,-916 # ffffffffc0205d18 <default_pmm_manager+0x78>
ffffffffc02030b4:	b9cfd0ef          	jal	ra,ffffffffc0200450 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc02030b8:	00003697          	auipc	a3,0x3
ffffffffc02030bc:	43868693          	addi	a3,a3,1080 # ffffffffc02064f0 <default_pmm_manager+0x850>
ffffffffc02030c0:	00003617          	auipc	a2,0x3
ffffffffc02030c4:	84860613          	addi	a2,a2,-1976 # ffffffffc0205908 <commands+0x878>
ffffffffc02030c8:	0df00593          	li	a1,223
ffffffffc02030cc:	00003517          	auipc	a0,0x3
ffffffffc02030d0:	2fc50513          	addi	a0,a0,764 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc02030d4:	b7cfd0ef          	jal	ra,ffffffffc0200450 <__panic>
          assert(check_rp[i] != NULL );
ffffffffc02030d8:	00003697          	auipc	a3,0x3
ffffffffc02030dc:	40068693          	addi	a3,a3,1024 # ffffffffc02064d8 <default_pmm_manager+0x838>
ffffffffc02030e0:	00003617          	auipc	a2,0x3
ffffffffc02030e4:	82860613          	addi	a2,a2,-2008 # ffffffffc0205908 <commands+0x878>
ffffffffc02030e8:	0de00593          	li	a1,222
ffffffffc02030ec:	00003517          	auipc	a0,0x3
ffffffffc02030f0:	2dc50513          	addi	a0,a0,732 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc02030f4:	b5cfd0ef          	jal	ra,ffffffffc0200450 <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc02030f8:	00003697          	auipc	a3,0x3
ffffffffc02030fc:	4a868693          	addi	a3,a3,1192 # ffffffffc02065a0 <default_pmm_manager+0x900>
ffffffffc0203100:	00003617          	auipc	a2,0x3
ffffffffc0203104:	80860613          	addi	a2,a2,-2040 # ffffffffc0205908 <commands+0x878>
ffffffffc0203108:	0fd00593          	li	a1,253
ffffffffc020310c:	00003517          	auipc	a0,0x3
ffffffffc0203110:	2bc50513          	addi	a0,a0,700 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc0203114:	b3cfd0ef          	jal	ra,ffffffffc0200450 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc0203118:	00003617          	auipc	a2,0x3
ffffffffc020311c:	29060613          	addi	a2,a2,656 # ffffffffc02063a8 <default_pmm_manager+0x708>
ffffffffc0203120:	02b00593          	li	a1,43
ffffffffc0203124:	00003517          	auipc	a0,0x3
ffffffffc0203128:	2a450513          	addi	a0,a0,676 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc020312c:	b24fd0ef          	jal	ra,ffffffffc0200450 <__panic>
     assert(pgfault_num==2);
ffffffffc0203130:	00003697          	auipc	a3,0x3
ffffffffc0203134:	44068693          	addi	a3,a3,1088 # ffffffffc0206570 <default_pmm_manager+0x8d0>
ffffffffc0203138:	00002617          	auipc	a2,0x2
ffffffffc020313c:	7d060613          	addi	a2,a2,2000 # ffffffffc0205908 <commands+0x878>
ffffffffc0203140:	09900593          	li	a1,153
ffffffffc0203144:	00003517          	auipc	a0,0x3
ffffffffc0203148:	28450513          	addi	a0,a0,644 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc020314c:	b04fd0ef          	jal	ra,ffffffffc0200450 <__panic>
     assert(pgfault_num==2);
ffffffffc0203150:	00003697          	auipc	a3,0x3
ffffffffc0203154:	42068693          	addi	a3,a3,1056 # ffffffffc0206570 <default_pmm_manager+0x8d0>
ffffffffc0203158:	00002617          	auipc	a2,0x2
ffffffffc020315c:	7b060613          	addi	a2,a2,1968 # ffffffffc0205908 <commands+0x878>
ffffffffc0203160:	09b00593          	li	a1,155
ffffffffc0203164:	00003517          	auipc	a0,0x3
ffffffffc0203168:	26450513          	addi	a0,a0,612 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc020316c:	ae4fd0ef          	jal	ra,ffffffffc0200450 <__panic>
     assert(pgfault_num==3);
ffffffffc0203170:	00003697          	auipc	a3,0x3
ffffffffc0203174:	41068693          	addi	a3,a3,1040 # ffffffffc0206580 <default_pmm_manager+0x8e0>
ffffffffc0203178:	00002617          	auipc	a2,0x2
ffffffffc020317c:	79060613          	addi	a2,a2,1936 # ffffffffc0205908 <commands+0x878>
ffffffffc0203180:	09d00593          	li	a1,157
ffffffffc0203184:	00003517          	auipc	a0,0x3
ffffffffc0203188:	24450513          	addi	a0,a0,580 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc020318c:	ac4fd0ef          	jal	ra,ffffffffc0200450 <__panic>
     assert(pgfault_num==3);
ffffffffc0203190:	00003697          	auipc	a3,0x3
ffffffffc0203194:	3f068693          	addi	a3,a3,1008 # ffffffffc0206580 <default_pmm_manager+0x8e0>
ffffffffc0203198:	00002617          	auipc	a2,0x2
ffffffffc020319c:	77060613          	addi	a2,a2,1904 # ffffffffc0205908 <commands+0x878>
ffffffffc02031a0:	09f00593          	li	a1,159
ffffffffc02031a4:	00003517          	auipc	a0,0x3
ffffffffc02031a8:	22450513          	addi	a0,a0,548 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc02031ac:	aa4fd0ef          	jal	ra,ffffffffc0200450 <__panic>
     assert(pgfault_num==1);
ffffffffc02031b0:	00003697          	auipc	a3,0x3
ffffffffc02031b4:	3b068693          	addi	a3,a3,944 # ffffffffc0206560 <default_pmm_manager+0x8c0>
ffffffffc02031b8:	00002617          	auipc	a2,0x2
ffffffffc02031bc:	75060613          	addi	a2,a2,1872 # ffffffffc0205908 <commands+0x878>
ffffffffc02031c0:	09500593          	li	a1,149
ffffffffc02031c4:	00003517          	auipc	a0,0x3
ffffffffc02031c8:	20450513          	addi	a0,a0,516 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc02031cc:	a84fd0ef          	jal	ra,ffffffffc0200450 <__panic>
     assert(pgfault_num==1);
ffffffffc02031d0:	00003697          	auipc	a3,0x3
ffffffffc02031d4:	39068693          	addi	a3,a3,912 # ffffffffc0206560 <default_pmm_manager+0x8c0>
ffffffffc02031d8:	00002617          	auipc	a2,0x2
ffffffffc02031dc:	73060613          	addi	a2,a2,1840 # ffffffffc0205908 <commands+0x878>
ffffffffc02031e0:	09700593          	li	a1,151
ffffffffc02031e4:	00003517          	auipc	a0,0x3
ffffffffc02031e8:	1e450513          	addi	a0,a0,484 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc02031ec:	a64fd0ef          	jal	ra,ffffffffc0200450 <__panic>
     assert(pgfault_num==4);
ffffffffc02031f0:	00003697          	auipc	a3,0x3
ffffffffc02031f4:	3a068693          	addi	a3,a3,928 # ffffffffc0206590 <default_pmm_manager+0x8f0>
ffffffffc02031f8:	00002617          	auipc	a2,0x2
ffffffffc02031fc:	71060613          	addi	a2,a2,1808 # ffffffffc0205908 <commands+0x878>
ffffffffc0203200:	0a100593          	li	a1,161
ffffffffc0203204:	00003517          	auipc	a0,0x3
ffffffffc0203208:	1c450513          	addi	a0,a0,452 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc020320c:	a44fd0ef          	jal	ra,ffffffffc0200450 <__panic>
     assert(pgfault_num==4);
ffffffffc0203210:	00003697          	auipc	a3,0x3
ffffffffc0203214:	38068693          	addi	a3,a3,896 # ffffffffc0206590 <default_pmm_manager+0x8f0>
ffffffffc0203218:	00002617          	auipc	a2,0x2
ffffffffc020321c:	6f060613          	addi	a2,a2,1776 # ffffffffc0205908 <commands+0x878>
ffffffffc0203220:	0a300593          	li	a1,163
ffffffffc0203224:	00003517          	auipc	a0,0x3
ffffffffc0203228:	1a450513          	addi	a0,a0,420 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc020322c:	a24fd0ef          	jal	ra,ffffffffc0200450 <__panic>
     assert(pgdir[0] == 0);
ffffffffc0203230:	00003697          	auipc	a3,0x3
ffffffffc0203234:	21068693          	addi	a3,a3,528 # ffffffffc0206440 <default_pmm_manager+0x7a0>
ffffffffc0203238:	00002617          	auipc	a2,0x2
ffffffffc020323c:	6d060613          	addi	a2,a2,1744 # ffffffffc0205908 <commands+0x878>
ffffffffc0203240:	0ce00593          	li	a1,206
ffffffffc0203244:	00003517          	auipc	a0,0x3
ffffffffc0203248:	18450513          	addi	a0,a0,388 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc020324c:	a04fd0ef          	jal	ra,ffffffffc0200450 <__panic>
     assert(vma != NULL);
ffffffffc0203250:	00003697          	auipc	a3,0x3
ffffffffc0203254:	20068693          	addi	a3,a3,512 # ffffffffc0206450 <default_pmm_manager+0x7b0>
ffffffffc0203258:	00002617          	auipc	a2,0x2
ffffffffc020325c:	6b060613          	addi	a2,a2,1712 # ffffffffc0205908 <commands+0x878>
ffffffffc0203260:	0d100593          	li	a1,209
ffffffffc0203264:	00003517          	auipc	a0,0x3
ffffffffc0203268:	16450513          	addi	a0,a0,356 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc020326c:	9e4fd0ef          	jal	ra,ffffffffc0200450 <__panic>
     assert(temp_ptep!= NULL);
ffffffffc0203270:	00003697          	auipc	a3,0x3
ffffffffc0203274:	22868693          	addi	a3,a3,552 # ffffffffc0206498 <default_pmm_manager+0x7f8>
ffffffffc0203278:	00002617          	auipc	a2,0x2
ffffffffc020327c:	69060613          	addi	a2,a2,1680 # ffffffffc0205908 <commands+0x878>
ffffffffc0203280:	0d900593          	li	a1,217
ffffffffc0203284:	00003517          	auipc	a0,0x3
ffffffffc0203288:	14450513          	addi	a0,a0,324 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc020328c:	9c4fd0ef          	jal	ra,ffffffffc0200450 <__panic>
     assert( nr_free == 0);         
ffffffffc0203290:	00003697          	auipc	a3,0x3
ffffffffc0203294:	85068693          	addi	a3,a3,-1968 # ffffffffc0205ae0 <commands+0xa50>
ffffffffc0203298:	00002617          	auipc	a2,0x2
ffffffffc020329c:	67060613          	addi	a2,a2,1648 # ffffffffc0205908 <commands+0x878>
ffffffffc02032a0:	0f500593          	li	a1,245
ffffffffc02032a4:	00003517          	auipc	a0,0x3
ffffffffc02032a8:	12450513          	addi	a0,a0,292 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc02032ac:	9a4fd0ef          	jal	ra,ffffffffc0200450 <__panic>
    return KADDR(page2pa(page));
ffffffffc02032b0:	00003617          	auipc	a2,0x3
ffffffffc02032b4:	a4060613          	addi	a2,a2,-1472 # ffffffffc0205cf0 <default_pmm_manager+0x50>
ffffffffc02032b8:	06900593          	li	a1,105
ffffffffc02032bc:	00003517          	auipc	a0,0x3
ffffffffc02032c0:	a5c50513          	addi	a0,a0,-1444 # ffffffffc0205d18 <default_pmm_manager+0x78>
ffffffffc02032c4:	98cfd0ef          	jal	ra,ffffffffc0200450 <__panic>
     assert(count==0);
ffffffffc02032c8:	00003697          	auipc	a3,0x3
ffffffffc02032cc:	34868693          	addi	a3,a3,840 # ffffffffc0206610 <default_pmm_manager+0x970>
ffffffffc02032d0:	00002617          	auipc	a2,0x2
ffffffffc02032d4:	63860613          	addi	a2,a2,1592 # ffffffffc0205908 <commands+0x878>
ffffffffc02032d8:	11d00593          	li	a1,285
ffffffffc02032dc:	00003517          	auipc	a0,0x3
ffffffffc02032e0:	0ec50513          	addi	a0,a0,236 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc02032e4:	96cfd0ef          	jal	ra,ffffffffc0200450 <__panic>
     assert(total==0);
ffffffffc02032e8:	00003697          	auipc	a3,0x3
ffffffffc02032ec:	33868693          	addi	a3,a3,824 # ffffffffc0206620 <default_pmm_manager+0x980>
ffffffffc02032f0:	00002617          	auipc	a2,0x2
ffffffffc02032f4:	61860613          	addi	a2,a2,1560 # ffffffffc0205908 <commands+0x878>
ffffffffc02032f8:	11e00593          	li	a1,286
ffffffffc02032fc:	00003517          	auipc	a0,0x3
ffffffffc0203300:	0cc50513          	addi	a0,a0,204 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc0203304:	94cfd0ef          	jal	ra,ffffffffc0200450 <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0203308:	00003697          	auipc	a3,0x3
ffffffffc020330c:	20868693          	addi	a3,a3,520 # ffffffffc0206510 <default_pmm_manager+0x870>
ffffffffc0203310:	00002617          	auipc	a2,0x2
ffffffffc0203314:	5f860613          	addi	a2,a2,1528 # ffffffffc0205908 <commands+0x878>
ffffffffc0203318:	0ec00593          	li	a1,236
ffffffffc020331c:	00003517          	auipc	a0,0x3
ffffffffc0203320:	0ac50513          	addi	a0,a0,172 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc0203324:	92cfd0ef          	jal	ra,ffffffffc0200450 <__panic>
     assert(mm != NULL);
ffffffffc0203328:	00003697          	auipc	a3,0x3
ffffffffc020332c:	0f068693          	addi	a3,a3,240 # ffffffffc0206418 <default_pmm_manager+0x778>
ffffffffc0203330:	00002617          	auipc	a2,0x2
ffffffffc0203334:	5d860613          	addi	a2,a2,1496 # ffffffffc0205908 <commands+0x878>
ffffffffc0203338:	0c600593          	li	a1,198
ffffffffc020333c:	00003517          	auipc	a0,0x3
ffffffffc0203340:	08c50513          	addi	a0,a0,140 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc0203344:	90cfd0ef          	jal	ra,ffffffffc0200450 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc0203348:	00003697          	auipc	a3,0x3
ffffffffc020334c:	0e068693          	addi	a3,a3,224 # ffffffffc0206428 <default_pmm_manager+0x788>
ffffffffc0203350:	00002617          	auipc	a2,0x2
ffffffffc0203354:	5b860613          	addi	a2,a2,1464 # ffffffffc0205908 <commands+0x878>
ffffffffc0203358:	0c900593          	li	a1,201
ffffffffc020335c:	00003517          	auipc	a0,0x3
ffffffffc0203360:	06c50513          	addi	a0,a0,108 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc0203364:	8ecfd0ef          	jal	ra,ffffffffc0200450 <__panic>
     assert(ret==0);
ffffffffc0203368:	00003697          	auipc	a3,0x3
ffffffffc020336c:	2a068693          	addi	a3,a3,672 # ffffffffc0206608 <default_pmm_manager+0x968>
ffffffffc0203370:	00002617          	auipc	a2,0x2
ffffffffc0203374:	59860613          	addi	a2,a2,1432 # ffffffffc0205908 <commands+0x878>
ffffffffc0203378:	10400593          	li	a1,260
ffffffffc020337c:	00003517          	auipc	a0,0x3
ffffffffc0203380:	04c50513          	addi	a0,a0,76 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc0203384:	8ccfd0ef          	jal	ra,ffffffffc0200450 <__panic>
     assert(total == nr_free_pages());
ffffffffc0203388:	00002697          	auipc	a3,0x2
ffffffffc020338c:	5b068693          	addi	a3,a3,1456 # ffffffffc0205938 <commands+0x8a8>
ffffffffc0203390:	00002617          	auipc	a2,0x2
ffffffffc0203394:	57860613          	addi	a2,a2,1400 # ffffffffc0205908 <commands+0x878>
ffffffffc0203398:	0c100593          	li	a1,193
ffffffffc020339c:	00003517          	auipc	a0,0x3
ffffffffc02033a0:	02c50513          	addi	a0,a0,44 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc02033a4:	8acfd0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc02033a8 <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc02033a8:	00012797          	auipc	a5,0x12
ffffffffc02033ac:	0f078793          	addi	a5,a5,240 # ffffffffc0215498 <sm>
ffffffffc02033b0:	639c                	ld	a5,0(a5)
ffffffffc02033b2:	0107b303          	ld	t1,16(a5)
ffffffffc02033b6:	8302                	jr	t1

ffffffffc02033b8 <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc02033b8:	00012797          	auipc	a5,0x12
ffffffffc02033bc:	0e078793          	addi	a5,a5,224 # ffffffffc0215498 <sm>
ffffffffc02033c0:	639c                	ld	a5,0(a5)
ffffffffc02033c2:	0207b303          	ld	t1,32(a5)
ffffffffc02033c6:	8302                	jr	t1

ffffffffc02033c8 <swap_out>:
{
ffffffffc02033c8:	711d                	addi	sp,sp,-96
ffffffffc02033ca:	ec86                	sd	ra,88(sp)
ffffffffc02033cc:	e8a2                	sd	s0,80(sp)
ffffffffc02033ce:	e4a6                	sd	s1,72(sp)
ffffffffc02033d0:	e0ca                	sd	s2,64(sp)
ffffffffc02033d2:	fc4e                	sd	s3,56(sp)
ffffffffc02033d4:	f852                	sd	s4,48(sp)
ffffffffc02033d6:	f456                	sd	s5,40(sp)
ffffffffc02033d8:	f05a                	sd	s6,32(sp)
ffffffffc02033da:	ec5e                	sd	s7,24(sp)
ffffffffc02033dc:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++ i)
ffffffffc02033de:	cde9                	beqz	a1,ffffffffc02034b8 <swap_out+0xf0>
ffffffffc02033e0:	8ab2                	mv	s5,a2
ffffffffc02033e2:	892a                	mv	s2,a0
ffffffffc02033e4:	8a2e                	mv	s4,a1
ffffffffc02033e6:	4401                	li	s0,0
ffffffffc02033e8:	00012997          	auipc	s3,0x12
ffffffffc02033ec:	0b098993          	addi	s3,s3,176 # ffffffffc0215498 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc02033f0:	00003b17          	auipc	s6,0x3
ffffffffc02033f4:	2c0b0b13          	addi	s6,s6,704 # ffffffffc02066b0 <default_pmm_manager+0xa10>
                    cprintf("SWAP: failed to save\n");
ffffffffc02033f8:	00003b97          	auipc	s7,0x3
ffffffffc02033fc:	2a0b8b93          	addi	s7,s7,672 # ffffffffc0206698 <default_pmm_manager+0x9f8>
ffffffffc0203400:	a825                	j	ffffffffc0203438 <swap_out+0x70>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203402:	67a2                	ld	a5,8(sp)
ffffffffc0203404:	8626                	mv	a2,s1
ffffffffc0203406:	85a2                	mv	a1,s0
ffffffffc0203408:	63b4                	ld	a3,64(a5)
ffffffffc020340a:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc020340c:	2405                	addiw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc020340e:	82b1                	srli	a3,a3,0xc
ffffffffc0203410:	0685                	addi	a3,a3,1
ffffffffc0203412:	d7dfc0ef          	jal	ra,ffffffffc020018e <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203416:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc0203418:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc020341a:	613c                	ld	a5,64(a0)
ffffffffc020341c:	83b1                	srli	a5,a5,0xc
ffffffffc020341e:	0785                	addi	a5,a5,1
ffffffffc0203420:	07a2                	slli	a5,a5,0x8
ffffffffc0203422:	00fc3023          	sd	a5,0(s8)
                    free_page(page);
ffffffffc0203426:	833fe0ef          	jal	ra,ffffffffc0201c58 <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc020342a:	01893503          	ld	a0,24(s2)
ffffffffc020342e:	85a6                	mv	a1,s1
ffffffffc0203430:	f42ff0ef          	jal	ra,ffffffffc0202b72 <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc0203434:	048a0d63          	beq	s4,s0,ffffffffc020348e <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc0203438:	0009b783          	ld	a5,0(s3)
ffffffffc020343c:	8656                	mv	a2,s5
ffffffffc020343e:	002c                	addi	a1,sp,8
ffffffffc0203440:	7b9c                	ld	a5,48(a5)
ffffffffc0203442:	854a                	mv	a0,s2
ffffffffc0203444:	9782                	jalr	a5
          if (r != 0) {
ffffffffc0203446:	e12d                	bnez	a0,ffffffffc02034a8 <swap_out+0xe0>
          v=page->pra_vaddr; 
ffffffffc0203448:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc020344a:	01893503          	ld	a0,24(s2)
ffffffffc020344e:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc0203450:	63a4                	ld	s1,64(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203452:	85a6                	mv	a1,s1
ffffffffc0203454:	88bfe0ef          	jal	ra,ffffffffc0201cde <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc0203458:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc020345a:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc020345c:	8b85                	andi	a5,a5,1
ffffffffc020345e:	cfb9                	beqz	a5,ffffffffc02034bc <swap_out+0xf4>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
ffffffffc0203460:	65a2                	ld	a1,8(sp)
ffffffffc0203462:	61bc                	ld	a5,64(a1)
ffffffffc0203464:	83b1                	srli	a5,a5,0xc
ffffffffc0203466:	00178513          	addi	a0,a5,1
ffffffffc020346a:	0522                	slli	a0,a0,0x8
ffffffffc020346c:	567000ef          	jal	ra,ffffffffc02041d2 <swapfs_write>
ffffffffc0203470:	d949                	beqz	a0,ffffffffc0203402 <swap_out+0x3a>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203472:	855e                	mv	a0,s7
ffffffffc0203474:	d1bfc0ef          	jal	ra,ffffffffc020018e <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203478:	0009b783          	ld	a5,0(s3)
ffffffffc020347c:	6622                	ld	a2,8(sp)
ffffffffc020347e:	4681                	li	a3,0
ffffffffc0203480:	739c                	ld	a5,32(a5)
ffffffffc0203482:	85a6                	mv	a1,s1
ffffffffc0203484:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc0203486:	2405                	addiw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203488:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc020348a:	fa8a17e3          	bne	s4,s0,ffffffffc0203438 <swap_out+0x70>
}
ffffffffc020348e:	8522                	mv	a0,s0
ffffffffc0203490:	60e6                	ld	ra,88(sp)
ffffffffc0203492:	6446                	ld	s0,80(sp)
ffffffffc0203494:	64a6                	ld	s1,72(sp)
ffffffffc0203496:	6906                	ld	s2,64(sp)
ffffffffc0203498:	79e2                	ld	s3,56(sp)
ffffffffc020349a:	7a42                	ld	s4,48(sp)
ffffffffc020349c:	7aa2                	ld	s5,40(sp)
ffffffffc020349e:	7b02                	ld	s6,32(sp)
ffffffffc02034a0:	6be2                	ld	s7,24(sp)
ffffffffc02034a2:	6c42                	ld	s8,16(sp)
ffffffffc02034a4:	6125                	addi	sp,sp,96
ffffffffc02034a6:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc02034a8:	85a2                	mv	a1,s0
ffffffffc02034aa:	00003517          	auipc	a0,0x3
ffffffffc02034ae:	1a650513          	addi	a0,a0,422 # ffffffffc0206650 <default_pmm_manager+0x9b0>
ffffffffc02034b2:	cddfc0ef          	jal	ra,ffffffffc020018e <cprintf>
                  break;
ffffffffc02034b6:	bfe1                	j	ffffffffc020348e <swap_out+0xc6>
     for (i = 0; i != n; ++ i)
ffffffffc02034b8:	4401                	li	s0,0
ffffffffc02034ba:	bfd1                	j	ffffffffc020348e <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc02034bc:	00003697          	auipc	a3,0x3
ffffffffc02034c0:	1c468693          	addi	a3,a3,452 # ffffffffc0206680 <default_pmm_manager+0x9e0>
ffffffffc02034c4:	00002617          	auipc	a2,0x2
ffffffffc02034c8:	44460613          	addi	a2,a2,1092 # ffffffffc0205908 <commands+0x878>
ffffffffc02034cc:	06a00593          	li	a1,106
ffffffffc02034d0:	00003517          	auipc	a0,0x3
ffffffffc02034d4:	ef850513          	addi	a0,a0,-264 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc02034d8:	f79fc0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc02034dc <swap_in>:
{
ffffffffc02034dc:	7179                	addi	sp,sp,-48
ffffffffc02034de:	e84a                	sd	s2,16(sp)
ffffffffc02034e0:	892a                	mv	s2,a0
     struct Page *result = alloc_page();
ffffffffc02034e2:	4505                	li	a0,1
{
ffffffffc02034e4:	ec26                	sd	s1,24(sp)
ffffffffc02034e6:	e44e                	sd	s3,8(sp)
ffffffffc02034e8:	f406                	sd	ra,40(sp)
ffffffffc02034ea:	f022                	sd	s0,32(sp)
ffffffffc02034ec:	84ae                	mv	s1,a1
ffffffffc02034ee:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc02034f0:	ee0fe0ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
     assert(result!=NULL);
ffffffffc02034f4:	c129                	beqz	a0,ffffffffc0203536 <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc02034f6:	842a                	mv	s0,a0
ffffffffc02034f8:	01893503          	ld	a0,24(s2)
ffffffffc02034fc:	4601                	li	a2,0
ffffffffc02034fe:	85a6                	mv	a1,s1
ffffffffc0203500:	fdefe0ef          	jal	ra,ffffffffc0201cde <get_pte>
ffffffffc0203504:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0)
ffffffffc0203506:	6108                	ld	a0,0(a0)
ffffffffc0203508:	85a2                	mv	a1,s0
ffffffffc020350a:	423000ef          	jal	ra,ffffffffc020412c <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
ffffffffc020350e:	00093583          	ld	a1,0(s2)
ffffffffc0203512:	8626                	mv	a2,s1
ffffffffc0203514:	00003517          	auipc	a0,0x3
ffffffffc0203518:	e5450513          	addi	a0,a0,-428 # ffffffffc0206368 <default_pmm_manager+0x6c8>
ffffffffc020351c:	81a1                	srli	a1,a1,0x8
ffffffffc020351e:	c71fc0ef          	jal	ra,ffffffffc020018e <cprintf>
}
ffffffffc0203522:	70a2                	ld	ra,40(sp)
     *ptr_result=result;
ffffffffc0203524:	0089b023          	sd	s0,0(s3)
}
ffffffffc0203528:	7402                	ld	s0,32(sp)
ffffffffc020352a:	64e2                	ld	s1,24(sp)
ffffffffc020352c:	6942                	ld	s2,16(sp)
ffffffffc020352e:	69a2                	ld	s3,8(sp)
ffffffffc0203530:	4501                	li	a0,0
ffffffffc0203532:	6145                	addi	sp,sp,48
ffffffffc0203534:	8082                	ret
     assert(result!=NULL);
ffffffffc0203536:	00003697          	auipc	a3,0x3
ffffffffc020353a:	e2268693          	addi	a3,a3,-478 # ffffffffc0206358 <default_pmm_manager+0x6b8>
ffffffffc020353e:	00002617          	auipc	a2,0x2
ffffffffc0203542:	3ca60613          	addi	a2,a2,970 # ffffffffc0205908 <commands+0x878>
ffffffffc0203546:	08000593          	li	a1,128
ffffffffc020354a:	00003517          	auipc	a0,0x3
ffffffffc020354e:	e7e50513          	addi	a0,a0,-386 # ffffffffc02063c8 <default_pmm_manager+0x728>
ffffffffc0203552:	efffc0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc0203556 <_clock_init_mm>:
    elm->prev = elm->next = elm;
ffffffffc0203556:	00012797          	auipc	a5,0x12
ffffffffc020355a:	07a78793          	addi	a5,a5,122 # ffffffffc02155d0 <pra_list_head>
     // 初始化pra_list_head为空链表
     list_init(&pra_list_head);
     // 初始化当前指针curr_ptr指向pra_list_head，表示当前页面替换位置为链表头
     curr_ptr = &pra_list_head;
     // 将mm的私有成员指针指向pra_list_head，用于后续的页面替换算法操作
     mm->sm_priv = &pra_list_head;
ffffffffc020355e:	f51c                	sd	a5,40(a0)
ffffffffc0203560:	e79c                	sd	a5,8(a5)
ffffffffc0203562:	e39c                	sd	a5,0(a5)
     curr_ptr = &pra_list_head;
ffffffffc0203564:	00012717          	auipc	a4,0x12
ffffffffc0203568:	06f73e23          	sd	a5,124(a4) # ffffffffc02155e0 <curr_ptr>

     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
ffffffffc020356c:	4501                	li	a0,0
ffffffffc020356e:	8082                	ret

ffffffffc0203570 <_clock_init>:

static int
_clock_init(void)
{
    return 0;
}
ffffffffc0203570:	4501                	li	a0,0
ffffffffc0203572:	8082                	ret

ffffffffc0203574 <_clock_set_unswappable>:

static int
_clock_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc0203574:	4501                	li	a0,0
ffffffffc0203576:	8082                	ret

ffffffffc0203578 <_clock_tick_event>:

static int
_clock_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc0203578:	4501                	li	a0,0
ffffffffc020357a:	8082                	ret

ffffffffc020357c <_clock_check_swap>:
_clock_check_swap(void) {
ffffffffc020357c:	1141                	addi	sp,sp,-16
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc020357e:	678d                	lui	a5,0x3
ffffffffc0203580:	4731                	li	a4,12
_clock_check_swap(void) {
ffffffffc0203582:	e406                	sd	ra,8(sp)
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203584:	00e78023          	sb	a4,0(a5) # 3000 <BASE_ADDRESS-0xffffffffc01fd000>
    assert(pgfault_num==4);
ffffffffc0203588:	00012797          	auipc	a5,0x12
ffffffffc020358c:	f1c78793          	addi	a5,a5,-228 # ffffffffc02154a4 <pgfault_num>
ffffffffc0203590:	4398                	lw	a4,0(a5)
ffffffffc0203592:	4691                	li	a3,4
ffffffffc0203594:	2701                	sext.w	a4,a4
ffffffffc0203596:	08d71f63          	bne	a4,a3,ffffffffc0203634 <_clock_check_swap+0xb8>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc020359a:	6685                	lui	a3,0x1
ffffffffc020359c:	4629                	li	a2,10
ffffffffc020359e:	00c68023          	sb	a2,0(a3) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
    assert(pgfault_num==4);
ffffffffc02035a2:	4394                	lw	a3,0(a5)
ffffffffc02035a4:	2681                	sext.w	a3,a3
ffffffffc02035a6:	20e69763          	bne	a3,a4,ffffffffc02037b4 <_clock_check_swap+0x238>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc02035aa:	6711                	lui	a4,0x4
ffffffffc02035ac:	4635                	li	a2,13
ffffffffc02035ae:	00c70023          	sb	a2,0(a4) # 4000 <BASE_ADDRESS-0xffffffffc01fc000>
    assert(pgfault_num==4);
ffffffffc02035b2:	4398                	lw	a4,0(a5)
ffffffffc02035b4:	2701                	sext.w	a4,a4
ffffffffc02035b6:	1cd71f63          	bne	a4,a3,ffffffffc0203794 <_clock_check_swap+0x218>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc02035ba:	6689                	lui	a3,0x2
ffffffffc02035bc:	462d                	li	a2,11
ffffffffc02035be:	00c68023          	sb	a2,0(a3) # 2000 <BASE_ADDRESS-0xffffffffc01fe000>
    assert(pgfault_num==4);
ffffffffc02035c2:	4394                	lw	a3,0(a5)
ffffffffc02035c4:	2681                	sext.w	a3,a3
ffffffffc02035c6:	1ae69763          	bne	a3,a4,ffffffffc0203774 <_clock_check_swap+0x1f8>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc02035ca:	6715                	lui	a4,0x5
ffffffffc02035cc:	46b9                	li	a3,14
ffffffffc02035ce:	00d70023          	sb	a3,0(a4) # 5000 <BASE_ADDRESS-0xffffffffc01fb000>
    assert(pgfault_num==5);
ffffffffc02035d2:	4398                	lw	a4,0(a5)
ffffffffc02035d4:	4695                	li	a3,5
ffffffffc02035d6:	2701                	sext.w	a4,a4
ffffffffc02035d8:	16d71e63          	bne	a4,a3,ffffffffc0203754 <_clock_check_swap+0x1d8>
    assert(pgfault_num==5);
ffffffffc02035dc:	4394                	lw	a3,0(a5)
ffffffffc02035de:	2681                	sext.w	a3,a3
ffffffffc02035e0:	14e69a63          	bne	a3,a4,ffffffffc0203734 <_clock_check_swap+0x1b8>
    assert(pgfault_num==5);
ffffffffc02035e4:	4398                	lw	a4,0(a5)
ffffffffc02035e6:	2701                	sext.w	a4,a4
ffffffffc02035e8:	12d71663          	bne	a4,a3,ffffffffc0203714 <_clock_check_swap+0x198>
    assert(pgfault_num==5);
ffffffffc02035ec:	4394                	lw	a3,0(a5)
ffffffffc02035ee:	2681                	sext.w	a3,a3
ffffffffc02035f0:	10e69263          	bne	a3,a4,ffffffffc02036f4 <_clock_check_swap+0x178>
    assert(pgfault_num==5);
ffffffffc02035f4:	4398                	lw	a4,0(a5)
ffffffffc02035f6:	2701                	sext.w	a4,a4
ffffffffc02035f8:	0cd71e63          	bne	a4,a3,ffffffffc02036d4 <_clock_check_swap+0x158>
    assert(pgfault_num==5);
ffffffffc02035fc:	4394                	lw	a3,0(a5)
ffffffffc02035fe:	2681                	sext.w	a3,a3
ffffffffc0203600:	0ae69a63          	bne	a3,a4,ffffffffc02036b4 <_clock_check_swap+0x138>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203604:	6715                	lui	a4,0x5
ffffffffc0203606:	46b9                	li	a3,14
ffffffffc0203608:	00d70023          	sb	a3,0(a4) # 5000 <BASE_ADDRESS-0xffffffffc01fb000>
    assert(pgfault_num==5);
ffffffffc020360c:	4398                	lw	a4,0(a5)
ffffffffc020360e:	4695                	li	a3,5
ffffffffc0203610:	2701                	sext.w	a4,a4
ffffffffc0203612:	08d71163          	bne	a4,a3,ffffffffc0203694 <_clock_check_swap+0x118>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0203616:	6705                	lui	a4,0x1
ffffffffc0203618:	00074683          	lbu	a3,0(a4) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
ffffffffc020361c:	4729                	li	a4,10
ffffffffc020361e:	04e69b63          	bne	a3,a4,ffffffffc0203674 <_clock_check_swap+0xf8>
    assert(pgfault_num==6);
ffffffffc0203622:	439c                	lw	a5,0(a5)
ffffffffc0203624:	4719                	li	a4,6
ffffffffc0203626:	2781                	sext.w	a5,a5
ffffffffc0203628:	02e79663          	bne	a5,a4,ffffffffc0203654 <_clock_check_swap+0xd8>
}
ffffffffc020362c:	60a2                	ld	ra,8(sp)
ffffffffc020362e:	4501                	li	a0,0
ffffffffc0203630:	0141                	addi	sp,sp,16
ffffffffc0203632:	8082                	ret
    assert(pgfault_num==4);
ffffffffc0203634:	00003697          	auipc	a3,0x3
ffffffffc0203638:	f5c68693          	addi	a3,a3,-164 # ffffffffc0206590 <default_pmm_manager+0x8f0>
ffffffffc020363c:	00002617          	auipc	a2,0x2
ffffffffc0203640:	2cc60613          	addi	a2,a2,716 # ffffffffc0205908 <commands+0x878>
ffffffffc0203644:	08f00593          	li	a1,143
ffffffffc0203648:	00003517          	auipc	a0,0x3
ffffffffc020364c:	0a850513          	addi	a0,a0,168 # ffffffffc02066f0 <default_pmm_manager+0xa50>
ffffffffc0203650:	e01fc0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(pgfault_num==6);
ffffffffc0203654:	00003697          	auipc	a3,0x3
ffffffffc0203658:	0ec68693          	addi	a3,a3,236 # ffffffffc0206740 <default_pmm_manager+0xaa0>
ffffffffc020365c:	00002617          	auipc	a2,0x2
ffffffffc0203660:	2ac60613          	addi	a2,a2,684 # ffffffffc0205908 <commands+0x878>
ffffffffc0203664:	0a600593          	li	a1,166
ffffffffc0203668:	00003517          	auipc	a0,0x3
ffffffffc020366c:	08850513          	addi	a0,a0,136 # ffffffffc02066f0 <default_pmm_manager+0xa50>
ffffffffc0203670:	de1fc0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0203674:	00003697          	auipc	a3,0x3
ffffffffc0203678:	0a468693          	addi	a3,a3,164 # ffffffffc0206718 <default_pmm_manager+0xa78>
ffffffffc020367c:	00002617          	auipc	a2,0x2
ffffffffc0203680:	28c60613          	addi	a2,a2,652 # ffffffffc0205908 <commands+0x878>
ffffffffc0203684:	0a400593          	li	a1,164
ffffffffc0203688:	00003517          	auipc	a0,0x3
ffffffffc020368c:	06850513          	addi	a0,a0,104 # ffffffffc02066f0 <default_pmm_manager+0xa50>
ffffffffc0203690:	dc1fc0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(pgfault_num==5);
ffffffffc0203694:	00003697          	auipc	a3,0x3
ffffffffc0203698:	07468693          	addi	a3,a3,116 # ffffffffc0206708 <default_pmm_manager+0xa68>
ffffffffc020369c:	00002617          	auipc	a2,0x2
ffffffffc02036a0:	26c60613          	addi	a2,a2,620 # ffffffffc0205908 <commands+0x878>
ffffffffc02036a4:	0a300593          	li	a1,163
ffffffffc02036a8:	00003517          	auipc	a0,0x3
ffffffffc02036ac:	04850513          	addi	a0,a0,72 # ffffffffc02066f0 <default_pmm_manager+0xa50>
ffffffffc02036b0:	da1fc0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(pgfault_num==5);
ffffffffc02036b4:	00003697          	auipc	a3,0x3
ffffffffc02036b8:	05468693          	addi	a3,a3,84 # ffffffffc0206708 <default_pmm_manager+0xa68>
ffffffffc02036bc:	00002617          	auipc	a2,0x2
ffffffffc02036c0:	24c60613          	addi	a2,a2,588 # ffffffffc0205908 <commands+0x878>
ffffffffc02036c4:	0a100593          	li	a1,161
ffffffffc02036c8:	00003517          	auipc	a0,0x3
ffffffffc02036cc:	02850513          	addi	a0,a0,40 # ffffffffc02066f0 <default_pmm_manager+0xa50>
ffffffffc02036d0:	d81fc0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(pgfault_num==5);
ffffffffc02036d4:	00003697          	auipc	a3,0x3
ffffffffc02036d8:	03468693          	addi	a3,a3,52 # ffffffffc0206708 <default_pmm_manager+0xa68>
ffffffffc02036dc:	00002617          	auipc	a2,0x2
ffffffffc02036e0:	22c60613          	addi	a2,a2,556 # ffffffffc0205908 <commands+0x878>
ffffffffc02036e4:	09f00593          	li	a1,159
ffffffffc02036e8:	00003517          	auipc	a0,0x3
ffffffffc02036ec:	00850513          	addi	a0,a0,8 # ffffffffc02066f0 <default_pmm_manager+0xa50>
ffffffffc02036f0:	d61fc0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(pgfault_num==5);
ffffffffc02036f4:	00003697          	auipc	a3,0x3
ffffffffc02036f8:	01468693          	addi	a3,a3,20 # ffffffffc0206708 <default_pmm_manager+0xa68>
ffffffffc02036fc:	00002617          	auipc	a2,0x2
ffffffffc0203700:	20c60613          	addi	a2,a2,524 # ffffffffc0205908 <commands+0x878>
ffffffffc0203704:	09d00593          	li	a1,157
ffffffffc0203708:	00003517          	auipc	a0,0x3
ffffffffc020370c:	fe850513          	addi	a0,a0,-24 # ffffffffc02066f0 <default_pmm_manager+0xa50>
ffffffffc0203710:	d41fc0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(pgfault_num==5);
ffffffffc0203714:	00003697          	auipc	a3,0x3
ffffffffc0203718:	ff468693          	addi	a3,a3,-12 # ffffffffc0206708 <default_pmm_manager+0xa68>
ffffffffc020371c:	00002617          	auipc	a2,0x2
ffffffffc0203720:	1ec60613          	addi	a2,a2,492 # ffffffffc0205908 <commands+0x878>
ffffffffc0203724:	09b00593          	li	a1,155
ffffffffc0203728:	00003517          	auipc	a0,0x3
ffffffffc020372c:	fc850513          	addi	a0,a0,-56 # ffffffffc02066f0 <default_pmm_manager+0xa50>
ffffffffc0203730:	d21fc0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(pgfault_num==5);
ffffffffc0203734:	00003697          	auipc	a3,0x3
ffffffffc0203738:	fd468693          	addi	a3,a3,-44 # ffffffffc0206708 <default_pmm_manager+0xa68>
ffffffffc020373c:	00002617          	auipc	a2,0x2
ffffffffc0203740:	1cc60613          	addi	a2,a2,460 # ffffffffc0205908 <commands+0x878>
ffffffffc0203744:	09900593          	li	a1,153
ffffffffc0203748:	00003517          	auipc	a0,0x3
ffffffffc020374c:	fa850513          	addi	a0,a0,-88 # ffffffffc02066f0 <default_pmm_manager+0xa50>
ffffffffc0203750:	d01fc0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(pgfault_num==5);
ffffffffc0203754:	00003697          	auipc	a3,0x3
ffffffffc0203758:	fb468693          	addi	a3,a3,-76 # ffffffffc0206708 <default_pmm_manager+0xa68>
ffffffffc020375c:	00002617          	auipc	a2,0x2
ffffffffc0203760:	1ac60613          	addi	a2,a2,428 # ffffffffc0205908 <commands+0x878>
ffffffffc0203764:	09700593          	li	a1,151
ffffffffc0203768:	00003517          	auipc	a0,0x3
ffffffffc020376c:	f8850513          	addi	a0,a0,-120 # ffffffffc02066f0 <default_pmm_manager+0xa50>
ffffffffc0203770:	ce1fc0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(pgfault_num==4);
ffffffffc0203774:	00003697          	auipc	a3,0x3
ffffffffc0203778:	e1c68693          	addi	a3,a3,-484 # ffffffffc0206590 <default_pmm_manager+0x8f0>
ffffffffc020377c:	00002617          	auipc	a2,0x2
ffffffffc0203780:	18c60613          	addi	a2,a2,396 # ffffffffc0205908 <commands+0x878>
ffffffffc0203784:	09500593          	li	a1,149
ffffffffc0203788:	00003517          	auipc	a0,0x3
ffffffffc020378c:	f6850513          	addi	a0,a0,-152 # ffffffffc02066f0 <default_pmm_manager+0xa50>
ffffffffc0203790:	cc1fc0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(pgfault_num==4);
ffffffffc0203794:	00003697          	auipc	a3,0x3
ffffffffc0203798:	dfc68693          	addi	a3,a3,-516 # ffffffffc0206590 <default_pmm_manager+0x8f0>
ffffffffc020379c:	00002617          	auipc	a2,0x2
ffffffffc02037a0:	16c60613          	addi	a2,a2,364 # ffffffffc0205908 <commands+0x878>
ffffffffc02037a4:	09300593          	li	a1,147
ffffffffc02037a8:	00003517          	auipc	a0,0x3
ffffffffc02037ac:	f4850513          	addi	a0,a0,-184 # ffffffffc02066f0 <default_pmm_manager+0xa50>
ffffffffc02037b0:	ca1fc0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(pgfault_num==4);
ffffffffc02037b4:	00003697          	auipc	a3,0x3
ffffffffc02037b8:	ddc68693          	addi	a3,a3,-548 # ffffffffc0206590 <default_pmm_manager+0x8f0>
ffffffffc02037bc:	00002617          	auipc	a2,0x2
ffffffffc02037c0:	14c60613          	addi	a2,a2,332 # ffffffffc0205908 <commands+0x878>
ffffffffc02037c4:	09100593          	li	a1,145
ffffffffc02037c8:	00003517          	auipc	a0,0x3
ffffffffc02037cc:	f2850513          	addi	a0,a0,-216 # ffffffffc02066f0 <default_pmm_manager+0xa50>
ffffffffc02037d0:	c81fc0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc02037d4 <_clock_map_swappable>:
    list_entry_t *entry=&(page->pra_page_link);
ffffffffc02037d4:	03060793          	addi	a5,a2,48
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc02037d8:	c395                	beqz	a5,ffffffffc02037fc <_clock_map_swappable+0x28>
ffffffffc02037da:	00012717          	auipc	a4,0x12
ffffffffc02037de:	e0670713          	addi	a4,a4,-506 # ffffffffc02155e0 <curr_ptr>
ffffffffc02037e2:	6318                	ld	a4,0(a4)
ffffffffc02037e4:	cf01                	beqz	a4,ffffffffc02037fc <_clock_map_swappable+0x28>
    list_add(head->prev, entry);
ffffffffc02037e6:	7518                	ld	a4,40(a0)
}
ffffffffc02037e8:	4501                	li	a0,0
    list_add(head->prev, entry);
ffffffffc02037ea:	6318                	ld	a4,0(a4)
    __list_add(elm, listelm, listelm->next);
ffffffffc02037ec:	6714                	ld	a3,8(a4)
    prev->next = next->prev = elm;
ffffffffc02037ee:	e29c                	sd	a5,0(a3)
ffffffffc02037f0:	e71c                	sd	a5,8(a4)
    page->visited  = 1;
ffffffffc02037f2:	4785                	li	a5,1
    elm->next = next;
ffffffffc02037f4:	fe14                	sd	a3,56(a2)
    elm->prev = prev;
ffffffffc02037f6:	fa18                	sd	a4,48(a2)
ffffffffc02037f8:	ee1c                	sd	a5,24(a2)
}
ffffffffc02037fa:	8082                	ret
{
ffffffffc02037fc:	1141                	addi	sp,sp,-16
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc02037fe:	00003697          	auipc	a3,0x3
ffffffffc0203802:	f5268693          	addi	a3,a3,-174 # ffffffffc0206750 <default_pmm_manager+0xab0>
ffffffffc0203806:	00002617          	auipc	a2,0x2
ffffffffc020380a:	10260613          	addi	a2,a2,258 # ffffffffc0205908 <commands+0x878>
ffffffffc020380e:	03800593          	li	a1,56
ffffffffc0203812:	00003517          	auipc	a0,0x3
ffffffffc0203816:	ede50513          	addi	a0,a0,-290 # ffffffffc02066f0 <default_pmm_manager+0xa50>
{
ffffffffc020381a:	e406                	sd	ra,8(sp)
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc020381c:	c35fc0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc0203820 <_clock_swap_out_victim>:
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc0203820:	7508                	ld	a0,40(a0)
{
ffffffffc0203822:	1141                	addi	sp,sp,-16
ffffffffc0203824:	e406                	sd	ra,8(sp)
ffffffffc0203826:	e022                	sd	s0,0(sp)
         assert(head != NULL);
ffffffffc0203828:	c525                	beqz	a0,ffffffffc0203890 <_clock_swap_out_victim+0x70>
     assert(in_tick==0);
ffffffffc020382a:	e259                	bnez	a2,ffffffffc02038b0 <_clock_swap_out_victim+0x90>
ffffffffc020382c:	00012417          	auipc	s0,0x12
ffffffffc0203830:	db440413          	addi	s0,s0,-588 # ffffffffc02155e0 <curr_ptr>
ffffffffc0203834:	601c                	ld	a5,0(s0)
ffffffffc0203836:	4681                	li	a3,0
    return listelm->next;
ffffffffc0203838:	4605                	li	a2,1
        if (curr_ptr == head){  // 由于是将页面page插入到页面链表pra_list_head的末尾，所以pra_list_head制起标识头部的作用，跳过
ffffffffc020383a:	00a78c63          	beq	a5,a0,ffffffffc0203852 <_clock_swap_out_victim+0x32>
        if (curr_page->visited != 1){
ffffffffc020383e:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203842:	00c71e63          	bne	a4,a2,ffffffffc020385e <_clock_swap_out_victim+0x3e>
            curr_page->visited = 0;
ffffffffc0203846:	fe07b423          	sd	zero,-24(a5)
ffffffffc020384a:	679c                	ld	a5,8(a5)
        if (curr_ptr == head){  // 由于是将页面page插入到页面链表pra_list_head的末尾，所以pra_list_head制起标识头部的作用，跳过
ffffffffc020384c:	4685                	li	a3,1
ffffffffc020384e:	fea798e3          	bne	a5,a0,ffffffffc020383e <_clock_swap_out_victim+0x1e>
ffffffffc0203852:	679c                	ld	a5,8(a5)
ffffffffc0203854:	4685                	li	a3,1
        if (curr_page->visited != 1){
ffffffffc0203856:	fe87b703          	ld	a4,-24(a5)
ffffffffc020385a:	fec706e3          	beq	a4,a2,ffffffffc0203846 <_clock_swap_out_victim+0x26>
ffffffffc020385e:	c689                	beqz	a3,ffffffffc0203868 <_clock_swap_out_victim+0x48>
ffffffffc0203860:	00012717          	auipc	a4,0x12
ffffffffc0203864:	d8f73023          	sd	a5,-640(a4) # ffffffffc02155e0 <curr_ptr>
        curr_page = le2page(curr_ptr, pra_page_link);
ffffffffc0203868:	fd078713          	addi	a4,a5,-48
            *ptr_page = curr_page;
ffffffffc020386c:	e198                	sd	a4,0(a1)
            cprintf("curr_ptr %p\n",curr_ptr);
ffffffffc020386e:	00003517          	auipc	a0,0x3
ffffffffc0203872:	f2a50513          	addi	a0,a0,-214 # ffffffffc0206798 <default_pmm_manager+0xaf8>
ffffffffc0203876:	85be                	mv	a1,a5
ffffffffc0203878:	917fc0ef          	jal	ra,ffffffffc020018e <cprintf>
            list_del(curr_ptr);
ffffffffc020387c:	601c                	ld	a5,0(s0)
}
ffffffffc020387e:	60a2                	ld	ra,8(sp)
ffffffffc0203880:	6402                	ld	s0,0(sp)
    __list_del(listelm->prev, listelm->next);
ffffffffc0203882:	6398                	ld	a4,0(a5)
ffffffffc0203884:	679c                	ld	a5,8(a5)
ffffffffc0203886:	4501                	li	a0,0
    prev->next = next;
ffffffffc0203888:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020388a:	e398                	sd	a4,0(a5)
ffffffffc020388c:	0141                	addi	sp,sp,16
ffffffffc020388e:	8082                	ret
         assert(head != NULL);
ffffffffc0203890:	00003697          	auipc	a3,0x3
ffffffffc0203894:	ee868693          	addi	a3,a3,-280 # ffffffffc0206778 <default_pmm_manager+0xad8>
ffffffffc0203898:	00002617          	auipc	a2,0x2
ffffffffc020389c:	07060613          	addi	a2,a2,112 # ffffffffc0205908 <commands+0x878>
ffffffffc02038a0:	04b00593          	li	a1,75
ffffffffc02038a4:	00003517          	auipc	a0,0x3
ffffffffc02038a8:	e4c50513          	addi	a0,a0,-436 # ffffffffc02066f0 <default_pmm_manager+0xa50>
ffffffffc02038ac:	ba5fc0ef          	jal	ra,ffffffffc0200450 <__panic>
     assert(in_tick==0);
ffffffffc02038b0:	00003697          	auipc	a3,0x3
ffffffffc02038b4:	ed868693          	addi	a3,a3,-296 # ffffffffc0206788 <default_pmm_manager+0xae8>
ffffffffc02038b8:	00002617          	auipc	a2,0x2
ffffffffc02038bc:	05060613          	addi	a2,a2,80 # ffffffffc0205908 <commands+0x878>
ffffffffc02038c0:	04c00593          	li	a1,76
ffffffffc02038c4:	00003517          	auipc	a0,0x3
ffffffffc02038c8:	e2c50513          	addi	a0,a0,-468 # ffffffffc02066f0 <default_pmm_manager+0xa50>
ffffffffc02038cc:	b85fc0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc02038d0 <check_vma_overlap.isra.0.part.1>:
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc02038d0:	1141                	addi	sp,sp,-16
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc02038d2:	00003697          	auipc	a3,0x3
ffffffffc02038d6:	eee68693          	addi	a3,a3,-274 # ffffffffc02067c0 <default_pmm_manager+0xb20>
ffffffffc02038da:	00002617          	auipc	a2,0x2
ffffffffc02038de:	02e60613          	addi	a2,a2,46 # ffffffffc0205908 <commands+0x878>
ffffffffc02038e2:	07e00593          	li	a1,126
ffffffffc02038e6:	00003517          	auipc	a0,0x3
ffffffffc02038ea:	efa50513          	addi	a0,a0,-262 # ffffffffc02067e0 <default_pmm_manager+0xb40>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc02038ee:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02038f0:	b61fc0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc02038f4 <mm_create>:
mm_create(void) {
ffffffffc02038f4:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02038f6:	03000513          	li	a0,48
mm_create(void) {
ffffffffc02038fa:	e022                	sd	s0,0(sp)
ffffffffc02038fc:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02038fe:	8cefe0ef          	jal	ra,ffffffffc02019cc <kmalloc>
ffffffffc0203902:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc0203904:	c115                	beqz	a0,ffffffffc0203928 <mm_create+0x34>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203906:	00012797          	auipc	a5,0x12
ffffffffc020390a:	b9a78793          	addi	a5,a5,-1126 # ffffffffc02154a0 <swap_init_ok>
ffffffffc020390e:	439c                	lw	a5,0(a5)
    elm->prev = elm->next = elm;
ffffffffc0203910:	e408                	sd	a0,8(s0)
ffffffffc0203912:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc0203914:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203918:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc020391c:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203920:	2781                	sext.w	a5,a5
ffffffffc0203922:	eb81                	bnez	a5,ffffffffc0203932 <mm_create+0x3e>
        else mm->sm_priv = NULL;
ffffffffc0203924:	02053423          	sd	zero,40(a0)
}
ffffffffc0203928:	8522                	mv	a0,s0
ffffffffc020392a:	60a2                	ld	ra,8(sp)
ffffffffc020392c:	6402                	ld	s0,0(sp)
ffffffffc020392e:	0141                	addi	sp,sp,16
ffffffffc0203930:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203932:	a77ff0ef          	jal	ra,ffffffffc02033a8 <swap_init_mm>
}
ffffffffc0203936:	8522                	mv	a0,s0
ffffffffc0203938:	60a2                	ld	ra,8(sp)
ffffffffc020393a:	6402                	ld	s0,0(sp)
ffffffffc020393c:	0141                	addi	sp,sp,16
ffffffffc020393e:	8082                	ret

ffffffffc0203940 <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc0203940:	1101                	addi	sp,sp,-32
ffffffffc0203942:	e04a                	sd	s2,0(sp)
ffffffffc0203944:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203946:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc020394a:	e822                	sd	s0,16(sp)
ffffffffc020394c:	e426                	sd	s1,8(sp)
ffffffffc020394e:	ec06                	sd	ra,24(sp)
ffffffffc0203950:	84ae                	mv	s1,a1
ffffffffc0203952:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203954:	878fe0ef          	jal	ra,ffffffffc02019cc <kmalloc>
    if (vma != NULL) {
ffffffffc0203958:	c509                	beqz	a0,ffffffffc0203962 <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc020395a:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc020395e:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203960:	cd00                	sw	s0,24(a0)
}
ffffffffc0203962:	60e2                	ld	ra,24(sp)
ffffffffc0203964:	6442                	ld	s0,16(sp)
ffffffffc0203966:	64a2                	ld	s1,8(sp)
ffffffffc0203968:	6902                	ld	s2,0(sp)
ffffffffc020396a:	6105                	addi	sp,sp,32
ffffffffc020396c:	8082                	ret

ffffffffc020396e <find_vma>:
    if (mm != NULL) {
ffffffffc020396e:	c51d                	beqz	a0,ffffffffc020399c <find_vma+0x2e>
        vma = mm->mmap_cache;
ffffffffc0203970:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0203972:	c781                	beqz	a5,ffffffffc020397a <find_vma+0xc>
ffffffffc0203974:	6798                	ld	a4,8(a5)
ffffffffc0203976:	02e5f663          	bleu	a4,a1,ffffffffc02039a2 <find_vma+0x34>
                list_entry_t *list = &(mm->mmap_list), *le = list;
ffffffffc020397a:	87aa                	mv	a5,a0
    return listelm->next;
ffffffffc020397c:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc020397e:	00f50f63          	beq	a0,a5,ffffffffc020399c <find_vma+0x2e>
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc0203982:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203986:	fee5ebe3          	bltu	a1,a4,ffffffffc020397c <find_vma+0xe>
ffffffffc020398a:	ff07b703          	ld	a4,-16(a5)
ffffffffc020398e:	fee5f7e3          	bleu	a4,a1,ffffffffc020397c <find_vma+0xe>
                    vma = le2vma(le, list_link);
ffffffffc0203992:	1781                	addi	a5,a5,-32
        if (vma != NULL) {
ffffffffc0203994:	c781                	beqz	a5,ffffffffc020399c <find_vma+0x2e>
            mm->mmap_cache = vma;
ffffffffc0203996:	e91c                	sd	a5,16(a0)
}
ffffffffc0203998:	853e                	mv	a0,a5
ffffffffc020399a:	8082                	ret
    struct vma_struct *vma = NULL;
ffffffffc020399c:	4781                	li	a5,0
}
ffffffffc020399e:	853e                	mv	a0,a5
ffffffffc02039a0:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc02039a2:	6b98                	ld	a4,16(a5)
ffffffffc02039a4:	fce5fbe3          	bleu	a4,a1,ffffffffc020397a <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc02039a8:	e91c                	sd	a5,16(a0)
    return vma;
ffffffffc02039aa:	b7fd                	j	ffffffffc0203998 <find_vma+0x2a>

ffffffffc02039ac <insert_vma_struct>:


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
ffffffffc02039ac:	6590                	ld	a2,8(a1)
ffffffffc02039ae:	0105b803          	ld	a6,16(a1) # 1010 <BASE_ADDRESS-0xffffffffc01feff0>
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc02039b2:	1141                	addi	sp,sp,-16
ffffffffc02039b4:	e406                	sd	ra,8(sp)
ffffffffc02039b6:	872a                	mv	a4,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc02039b8:	01066863          	bltu	a2,a6,ffffffffc02039c8 <insert_vma_struct+0x1c>
ffffffffc02039bc:	a8b9                	j	ffffffffc0203a1a <insert_vma_struct+0x6e>
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc02039be:	fe87b683          	ld	a3,-24(a5)
ffffffffc02039c2:	04d66763          	bltu	a2,a3,ffffffffc0203a10 <insert_vma_struct+0x64>
ffffffffc02039c6:	873e                	mv	a4,a5
ffffffffc02039c8:	671c                	ld	a5,8(a4)
        while ((le = list_next(le)) != list) {
ffffffffc02039ca:	fef51ae3          	bne	a0,a5,ffffffffc02039be <insert_vma_struct+0x12>
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
ffffffffc02039ce:	02a70463          	beq	a4,a0,ffffffffc02039f6 <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc02039d2:	ff073683          	ld	a3,-16(a4)
    assert(prev->vm_start < prev->vm_end);
ffffffffc02039d6:	fe873883          	ld	a7,-24(a4)
ffffffffc02039da:	08d8f063          	bleu	a3,a7,ffffffffc0203a5a <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02039de:	04d66e63          	bltu	a2,a3,ffffffffc0203a3a <insert_vma_struct+0x8e>
    }
    if (le_next != list) {
ffffffffc02039e2:	00f50a63          	beq	a0,a5,ffffffffc02039f6 <insert_vma_struct+0x4a>
ffffffffc02039e6:	fe87b683          	ld	a3,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc02039ea:	0506e863          	bltu	a3,a6,ffffffffc0203a3a <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc02039ee:	ff07b603          	ld	a2,-16(a5)
ffffffffc02039f2:	02c6f263          	bleu	a2,a3,ffffffffc0203a16 <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
ffffffffc02039f6:	5114                	lw	a3,32(a0)
    vma->vm_mm = mm;
ffffffffc02039f8:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc02039fa:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc02039fe:	e390                	sd	a2,0(a5)
ffffffffc0203a00:	e710                	sd	a2,8(a4)
}
ffffffffc0203a02:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0203a04:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203a06:	f198                	sd	a4,32(a1)
    mm->map_count ++;
ffffffffc0203a08:	2685                	addiw	a3,a3,1
ffffffffc0203a0a:	d114                	sw	a3,32(a0)
}
ffffffffc0203a0c:	0141                	addi	sp,sp,16
ffffffffc0203a0e:	8082                	ret
    if (le_prev != list) {
ffffffffc0203a10:	fca711e3          	bne	a4,a0,ffffffffc02039d2 <insert_vma_struct+0x26>
ffffffffc0203a14:	bfd9                	j	ffffffffc02039ea <insert_vma_struct+0x3e>
ffffffffc0203a16:	ebbff0ef          	jal	ra,ffffffffc02038d0 <check_vma_overlap.isra.0.part.1>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203a1a:	00003697          	auipc	a3,0x3
ffffffffc0203a1e:	e7668693          	addi	a3,a3,-394 # ffffffffc0206890 <default_pmm_manager+0xbf0>
ffffffffc0203a22:	00002617          	auipc	a2,0x2
ffffffffc0203a26:	ee660613          	addi	a2,a2,-282 # ffffffffc0205908 <commands+0x878>
ffffffffc0203a2a:	08500593          	li	a1,133
ffffffffc0203a2e:	00003517          	auipc	a0,0x3
ffffffffc0203a32:	db250513          	addi	a0,a0,-590 # ffffffffc02067e0 <default_pmm_manager+0xb40>
ffffffffc0203a36:	a1bfc0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203a3a:	00003697          	auipc	a3,0x3
ffffffffc0203a3e:	e9668693          	addi	a3,a3,-362 # ffffffffc02068d0 <default_pmm_manager+0xc30>
ffffffffc0203a42:	00002617          	auipc	a2,0x2
ffffffffc0203a46:	ec660613          	addi	a2,a2,-314 # ffffffffc0205908 <commands+0x878>
ffffffffc0203a4a:	07d00593          	li	a1,125
ffffffffc0203a4e:	00003517          	auipc	a0,0x3
ffffffffc0203a52:	d9250513          	addi	a0,a0,-622 # ffffffffc02067e0 <default_pmm_manager+0xb40>
ffffffffc0203a56:	9fbfc0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203a5a:	00003697          	auipc	a3,0x3
ffffffffc0203a5e:	e5668693          	addi	a3,a3,-426 # ffffffffc02068b0 <default_pmm_manager+0xc10>
ffffffffc0203a62:	00002617          	auipc	a2,0x2
ffffffffc0203a66:	ea660613          	addi	a2,a2,-346 # ffffffffc0205908 <commands+0x878>
ffffffffc0203a6a:	07c00593          	li	a1,124
ffffffffc0203a6e:	00003517          	auipc	a0,0x3
ffffffffc0203a72:	d7250513          	addi	a0,a0,-654 # ffffffffc02067e0 <default_pmm_manager+0xb40>
ffffffffc0203a76:	9dbfc0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc0203a7a <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
ffffffffc0203a7a:	1141                	addi	sp,sp,-16
ffffffffc0203a7c:	e022                	sd	s0,0(sp)
ffffffffc0203a7e:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0203a80:	6508                	ld	a0,8(a0)
ffffffffc0203a82:	e406                	sd	ra,8(sp)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
ffffffffc0203a84:	00a40c63          	beq	s0,a0,ffffffffc0203a9c <mm_destroy+0x22>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203a88:	6118                	ld	a4,0(a0)
ffffffffc0203a8a:	651c                	ld	a5,8(a0)
        list_del(le);
        kfree(le2vma(le, list_link));  //kfree vma        
ffffffffc0203a8c:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203a8e:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203a90:	e398                	sd	a4,0(a5)
ffffffffc0203a92:	ff7fd0ef          	jal	ra,ffffffffc0201a88 <kfree>
    return listelm->next;
ffffffffc0203a96:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0203a98:	fea418e3          	bne	s0,a0,ffffffffc0203a88 <mm_destroy+0xe>
    }
    kfree(mm); //kfree mm
ffffffffc0203a9c:	8522                	mv	a0,s0
    mm=NULL;
}
ffffffffc0203a9e:	6402                	ld	s0,0(sp)
ffffffffc0203aa0:	60a2                	ld	ra,8(sp)
ffffffffc0203aa2:	0141                	addi	sp,sp,16
    kfree(mm); //kfree mm
ffffffffc0203aa4:	fe5fd06f          	j	ffffffffc0201a88 <kfree>

ffffffffc0203aa8 <vmm_init>:

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
ffffffffc0203aa8:	7139                	addi	sp,sp,-64
ffffffffc0203aaa:	f822                	sd	s0,48(sp)
ffffffffc0203aac:	f426                	sd	s1,40(sp)
ffffffffc0203aae:	fc06                	sd	ra,56(sp)
ffffffffc0203ab0:	f04a                	sd	s2,32(sp)
ffffffffc0203ab2:	ec4e                	sd	s3,24(sp)
ffffffffc0203ab4:	e852                	sd	s4,16(sp)
ffffffffc0203ab6:	e456                	sd	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
}

static void
check_vma_struct(void) {
    struct mm_struct *mm = mm_create();
ffffffffc0203ab8:	e3dff0ef          	jal	ra,ffffffffc02038f4 <mm_create>
    assert(mm != NULL);
ffffffffc0203abc:	842a                	mv	s0,a0
ffffffffc0203abe:	03200493          	li	s1,50
ffffffffc0203ac2:	e919                	bnez	a0,ffffffffc0203ad8 <vmm_init+0x30>
ffffffffc0203ac4:	a98d                	j	ffffffffc0203f36 <vmm_init+0x48e>
        vma->vm_start = vm_start;
ffffffffc0203ac6:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203ac8:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203aca:	00052c23          	sw	zero,24(a0)

    int i;
    for (i = step1; i >= 1; i --) {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203ace:	14ed                	addi	s1,s1,-5
ffffffffc0203ad0:	8522                	mv	a0,s0
ffffffffc0203ad2:	edbff0ef          	jal	ra,ffffffffc02039ac <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc0203ad6:	c88d                	beqz	s1,ffffffffc0203b08 <vmm_init+0x60>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203ad8:	03000513          	li	a0,48
ffffffffc0203adc:	ef1fd0ef          	jal	ra,ffffffffc02019cc <kmalloc>
ffffffffc0203ae0:	85aa                	mv	a1,a0
ffffffffc0203ae2:	00248793          	addi	a5,s1,2
    if (vma != NULL) {
ffffffffc0203ae6:	f165                	bnez	a0,ffffffffc0203ac6 <vmm_init+0x1e>
        assert(vma != NULL);
ffffffffc0203ae8:	00003697          	auipc	a3,0x3
ffffffffc0203aec:	96868693          	addi	a3,a3,-1688 # ffffffffc0206450 <default_pmm_manager+0x7b0>
ffffffffc0203af0:	00002617          	auipc	a2,0x2
ffffffffc0203af4:	e1860613          	addi	a2,a2,-488 # ffffffffc0205908 <commands+0x878>
ffffffffc0203af8:	0c900593          	li	a1,201
ffffffffc0203afc:	00003517          	auipc	a0,0x3
ffffffffc0203b00:	ce450513          	addi	a0,a0,-796 # ffffffffc02067e0 <default_pmm_manager+0xb40>
ffffffffc0203b04:	94dfc0ef          	jal	ra,ffffffffc0200450 <__panic>
    for (i = step1; i >= 1; i --) {
ffffffffc0203b08:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0203b0c:	1f900913          	li	s2,505
ffffffffc0203b10:	a819                	j	ffffffffc0203b26 <vmm_init+0x7e>
        vma->vm_start = vm_start;
ffffffffc0203b12:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203b14:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203b16:	00052c23          	sw	zero,24(a0)
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203b1a:	0495                	addi	s1,s1,5
ffffffffc0203b1c:	8522                	mv	a0,s0
ffffffffc0203b1e:	e8fff0ef          	jal	ra,ffffffffc02039ac <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0203b22:	03248a63          	beq	s1,s2,ffffffffc0203b56 <vmm_init+0xae>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203b26:	03000513          	li	a0,48
ffffffffc0203b2a:	ea3fd0ef          	jal	ra,ffffffffc02019cc <kmalloc>
ffffffffc0203b2e:	85aa                	mv	a1,a0
ffffffffc0203b30:	00248793          	addi	a5,s1,2
    if (vma != NULL) {
ffffffffc0203b34:	fd79                	bnez	a0,ffffffffc0203b12 <vmm_init+0x6a>
        assert(vma != NULL);
ffffffffc0203b36:	00003697          	auipc	a3,0x3
ffffffffc0203b3a:	91a68693          	addi	a3,a3,-1766 # ffffffffc0206450 <default_pmm_manager+0x7b0>
ffffffffc0203b3e:	00002617          	auipc	a2,0x2
ffffffffc0203b42:	dca60613          	addi	a2,a2,-566 # ffffffffc0205908 <commands+0x878>
ffffffffc0203b46:	0cf00593          	li	a1,207
ffffffffc0203b4a:	00003517          	auipc	a0,0x3
ffffffffc0203b4e:	c9650513          	addi	a0,a0,-874 # ffffffffc02067e0 <default_pmm_manager+0xb40>
ffffffffc0203b52:	8fffc0ef          	jal	ra,ffffffffc0200450 <__panic>
ffffffffc0203b56:	6418                	ld	a4,8(s0)
ffffffffc0203b58:	479d                	li	a5,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
ffffffffc0203b5a:	1fb00593          	li	a1,507
        assert(le != &(mm->mmap_list));
ffffffffc0203b5e:	30e40063          	beq	s0,a4,ffffffffc0203e5e <vmm_init+0x3b6>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203b62:	fe873603          	ld	a2,-24(a4)
ffffffffc0203b66:	ffe78693          	addi	a3,a5,-2
ffffffffc0203b6a:	26d61a63          	bne	a2,a3,ffffffffc0203dde <vmm_init+0x336>
ffffffffc0203b6e:	ff073683          	ld	a3,-16(a4)
ffffffffc0203b72:	26f69663          	bne	a3,a5,ffffffffc0203dde <vmm_init+0x336>
ffffffffc0203b76:	0795                	addi	a5,a5,5
ffffffffc0203b78:	6718                	ld	a4,8(a4)
    for (i = 1; i <= step2; i ++) {
ffffffffc0203b7a:	feb792e3          	bne	a5,a1,ffffffffc0203b5e <vmm_init+0xb6>
ffffffffc0203b7e:	491d                	li	s2,7
ffffffffc0203b80:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0203b82:	1f900a93          	li	s5,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203b86:	85a6                	mv	a1,s1
ffffffffc0203b88:	8522                	mv	a0,s0
ffffffffc0203b8a:	de5ff0ef          	jal	ra,ffffffffc020396e <find_vma>
ffffffffc0203b8e:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc0203b90:	32050763          	beqz	a0,ffffffffc0203ebe <vmm_init+0x416>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc0203b94:	00148593          	addi	a1,s1,1
ffffffffc0203b98:	8522                	mv	a0,s0
ffffffffc0203b9a:	dd5ff0ef          	jal	ra,ffffffffc020396e <find_vma>
ffffffffc0203b9e:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203ba0:	2e050f63          	beqz	a0,ffffffffc0203e9e <vmm_init+0x3f6>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc0203ba4:	85ca                	mv	a1,s2
ffffffffc0203ba6:	8522                	mv	a0,s0
ffffffffc0203ba8:	dc7ff0ef          	jal	ra,ffffffffc020396e <find_vma>
        assert(vma3 == NULL);
ffffffffc0203bac:	2c051963          	bnez	a0,ffffffffc0203e7e <vmm_init+0x3d6>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc0203bb0:	00348593          	addi	a1,s1,3
ffffffffc0203bb4:	8522                	mv	a0,s0
ffffffffc0203bb6:	db9ff0ef          	jal	ra,ffffffffc020396e <find_vma>
        assert(vma4 == NULL);
ffffffffc0203bba:	34051263          	bnez	a0,ffffffffc0203efe <vmm_init+0x456>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc0203bbe:	00448593          	addi	a1,s1,4
ffffffffc0203bc2:	8522                	mv	a0,s0
ffffffffc0203bc4:	dabff0ef          	jal	ra,ffffffffc020396e <find_vma>
        assert(vma5 == NULL);
ffffffffc0203bc8:	30051b63          	bnez	a0,ffffffffc0203ede <vmm_init+0x436>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0203bcc:	008a3783          	ld	a5,8(s4)
ffffffffc0203bd0:	22979763          	bne	a5,s1,ffffffffc0203dfe <vmm_init+0x356>
ffffffffc0203bd4:	010a3783          	ld	a5,16(s4)
ffffffffc0203bd8:	23279363          	bne	a5,s2,ffffffffc0203dfe <vmm_init+0x356>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0203bdc:	0089b783          	ld	a5,8(s3)
ffffffffc0203be0:	22979f63          	bne	a5,s1,ffffffffc0203e1e <vmm_init+0x376>
ffffffffc0203be4:	0109b783          	ld	a5,16(s3)
ffffffffc0203be8:	23279b63          	bne	a5,s2,ffffffffc0203e1e <vmm_init+0x376>
ffffffffc0203bec:	0495                	addi	s1,s1,5
ffffffffc0203bee:	0915                	addi	s2,s2,5
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0203bf0:	f9549be3          	bne	s1,s5,ffffffffc0203b86 <vmm_init+0xde>
ffffffffc0203bf4:	4491                	li	s1,4
    }

    for (i =4; i>=0; i--) {
ffffffffc0203bf6:	597d                	li	s2,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc0203bf8:	85a6                	mv	a1,s1
ffffffffc0203bfa:	8522                	mv	a0,s0
ffffffffc0203bfc:	d73ff0ef          	jal	ra,ffffffffc020396e <find_vma>
ffffffffc0203c00:	0004859b          	sext.w	a1,s1
        if (vma_below_5 != NULL ) {
ffffffffc0203c04:	c90d                	beqz	a0,ffffffffc0203c36 <vmm_init+0x18e>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc0203c06:	6914                	ld	a3,16(a0)
ffffffffc0203c08:	6510                	ld	a2,8(a0)
ffffffffc0203c0a:	00003517          	auipc	a0,0x3
ffffffffc0203c0e:	de650513          	addi	a0,a0,-538 # ffffffffc02069f0 <default_pmm_manager+0xd50>
ffffffffc0203c12:	d7cfc0ef          	jal	ra,ffffffffc020018e <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203c16:	00003697          	auipc	a3,0x3
ffffffffc0203c1a:	e0268693          	addi	a3,a3,-510 # ffffffffc0206a18 <default_pmm_manager+0xd78>
ffffffffc0203c1e:	00002617          	auipc	a2,0x2
ffffffffc0203c22:	cea60613          	addi	a2,a2,-790 # ffffffffc0205908 <commands+0x878>
ffffffffc0203c26:	0f100593          	li	a1,241
ffffffffc0203c2a:	00003517          	auipc	a0,0x3
ffffffffc0203c2e:	bb650513          	addi	a0,a0,-1098 # ffffffffc02067e0 <default_pmm_manager+0xb40>
ffffffffc0203c32:	81ffc0ef          	jal	ra,ffffffffc0200450 <__panic>
ffffffffc0203c36:	14fd                	addi	s1,s1,-1
    for (i =4; i>=0; i--) {
ffffffffc0203c38:	fd2490e3          	bne	s1,s2,ffffffffc0203bf8 <vmm_init+0x150>
    }

    mm_destroy(mm);
ffffffffc0203c3c:	8522                	mv	a0,s0
ffffffffc0203c3e:	e3dff0ef          	jal	ra,ffffffffc0203a7a <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203c42:	00003517          	auipc	a0,0x3
ffffffffc0203c46:	dee50513          	addi	a0,a0,-530 # ffffffffc0206a30 <default_pmm_manager+0xd90>
ffffffffc0203c4a:	d44fc0ef          	jal	ra,ffffffffc020018e <cprintf>
struct mm_struct *check_mm_struct;

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0203c4e:	850fe0ef          	jal	ra,ffffffffc0201c9e <nr_free_pages>
ffffffffc0203c52:	8a2a                	mv	s4,a0

    check_mm_struct = mm_create();
ffffffffc0203c54:	ca1ff0ef          	jal	ra,ffffffffc02038f4 <mm_create>
ffffffffc0203c58:	00012797          	auipc	a5,0x12
ffffffffc0203c5c:	98a7b823          	sd	a0,-1648(a5) # ffffffffc02155e8 <check_mm_struct>
ffffffffc0203c60:	84aa                	mv	s1,a0
    assert(check_mm_struct != NULL);
ffffffffc0203c62:	38050663          	beqz	a0,ffffffffc0203fee <vmm_init+0x546>

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0203c66:	00012797          	auipc	a5,0x12
ffffffffc0203c6a:	82278793          	addi	a5,a5,-2014 # ffffffffc0215488 <boot_pgdir>
ffffffffc0203c6e:	0007b903          	ld	s2,0(a5)
    assert(pgdir[0] == 0);
ffffffffc0203c72:	00093783          	ld	a5,0(s2)
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0203c76:	01253c23          	sd	s2,24(a0)
    assert(pgdir[0] == 0);
ffffffffc0203c7a:	2e079e63          	bnez	a5,ffffffffc0203f76 <vmm_init+0x4ce>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203c7e:	03000513          	li	a0,48
ffffffffc0203c82:	d4bfd0ef          	jal	ra,ffffffffc02019cc <kmalloc>
ffffffffc0203c86:	842a                	mv	s0,a0
    if (vma != NULL) {
ffffffffc0203c88:	1a050b63          	beqz	a0,ffffffffc0203e3e <vmm_init+0x396>
        vma->vm_end = vm_end;
ffffffffc0203c8c:	002007b7          	lui	a5,0x200
ffffffffc0203c90:	e81c                	sd	a5,16(s0)
        vma->vm_flags = vm_flags;
ffffffffc0203c92:	4789                	li	a5,2

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc0203c94:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags;
ffffffffc0203c96:	cc1c                	sw	a5,24(s0)
    insert_vma_struct(mm, vma);
ffffffffc0203c98:	8526                	mv	a0,s1
        vma->vm_start = vm_start;
ffffffffc0203c9a:	00043423          	sd	zero,8(s0)
    insert_vma_struct(mm, vma);
ffffffffc0203c9e:	d0fff0ef          	jal	ra,ffffffffc02039ac <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc0203ca2:	10000593          	li	a1,256
ffffffffc0203ca6:	8526                	mv	a0,s1
ffffffffc0203ca8:	cc7ff0ef          	jal	ra,ffffffffc020396e <find_vma>
ffffffffc0203cac:	10000793          	li	a5,256

    int i, sum = 0;
    for (i = 0; i < 100; i ++) {
ffffffffc0203cb0:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc0203cb4:	2ea41163          	bne	s0,a0,ffffffffc0203f96 <vmm_init+0x4ee>
        *(char *)(addr + i) = i;
ffffffffc0203cb8:	00f78023          	sb	a5,0(a5) # 200000 <BASE_ADDRESS-0xffffffffc0000000>
        sum += i;
ffffffffc0203cbc:	0785                	addi	a5,a5,1
    for (i = 0; i < 100; i ++) {
ffffffffc0203cbe:	fee79de3          	bne	a5,a4,ffffffffc0203cb8 <vmm_init+0x210>
        sum += i;
ffffffffc0203cc2:	6705                	lui	a4,0x1
    for (i = 0; i < 100; i ++) {
ffffffffc0203cc4:	10000793          	li	a5,256
        sum += i;
ffffffffc0203cc8:	35670713          	addi	a4,a4,854 # 1356 <BASE_ADDRESS-0xffffffffc01fecaa>
    }
    for (i = 0; i < 100; i ++) {
ffffffffc0203ccc:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc0203cd0:	0007c683          	lbu	a3,0(a5)
ffffffffc0203cd4:	0785                	addi	a5,a5,1
ffffffffc0203cd6:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc0203cd8:	fec79ce3          	bne	a5,a2,ffffffffc0203cd0 <vmm_init+0x228>
    }
    assert(sum == 0);
ffffffffc0203cdc:	2e071963          	bnez	a4,ffffffffc0203fce <vmm_init+0x526>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203ce0:	00093683          	ld	a3,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0203ce4:	00011a97          	auipc	s5,0x11
ffffffffc0203ce8:	7aca8a93          	addi	s5,s5,1964 # ffffffffc0215490 <npage>
ffffffffc0203cec:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203cf0:	068a                	slli	a3,a3,0x2
ffffffffc0203cf2:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203cf4:	22e6f563          	bleu	a4,a3,ffffffffc0203f1e <vmm_init+0x476>
    return &pages[PPN(pa) - nbase];
ffffffffc0203cf8:	00003797          	auipc	a5,0x3
ffffffffc0203cfc:	25078793          	addi	a5,a5,592 # ffffffffc0206f48 <nbase>
ffffffffc0203d00:	0007b983          	ld	s3,0(a5)
ffffffffc0203d04:	413687b3          	sub	a5,a3,s3
ffffffffc0203d08:	00379693          	slli	a3,a5,0x3
ffffffffc0203d0c:	96be                	add	a3,a3,a5
    return page - pages + nbase;
ffffffffc0203d0e:	00002797          	auipc	a5,0x2
ffffffffc0203d12:	be278793          	addi	a5,a5,-1054 # ffffffffc02058f0 <commands+0x860>
ffffffffc0203d16:	639c                	ld	a5,0(a5)
    return &pages[PPN(pa) - nbase];
ffffffffc0203d18:	068e                	slli	a3,a3,0x3
    return page - pages + nbase;
ffffffffc0203d1a:	868d                	srai	a3,a3,0x3
ffffffffc0203d1c:	02f686b3          	mul	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0203d20:	57fd                	li	a5,-1
ffffffffc0203d22:	83b1                	srli	a5,a5,0xc
    return page - pages + nbase;
ffffffffc0203d24:	96ce                	add	a3,a3,s3
    return KADDR(page2pa(page));
ffffffffc0203d26:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0203d28:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203d2a:	28e7f663          	bleu	a4,a5,ffffffffc0203fb6 <vmm_init+0x50e>
ffffffffc0203d2e:	00011797          	auipc	a5,0x11
ffffffffc0203d32:	7c278793          	addi	a5,a5,1986 # ffffffffc02154f0 <va_pa_offset>
ffffffffc0203d36:	6380                	ld	s0,0(a5)

    pde_t *pd1=pgdir,*pd0=page2kva(pde2page(pgdir[0]));
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc0203d38:	4581                	li	a1,0
ffffffffc0203d3a:	854a                	mv	a0,s2
ffffffffc0203d3c:	9436                	add	s0,s0,a3
ffffffffc0203d3e:	a06fe0ef          	jal	ra,ffffffffc0201f44 <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203d42:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0203d44:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203d48:	078a                	slli	a5,a5,0x2
ffffffffc0203d4a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203d4c:	1ce7f963          	bleu	a4,a5,ffffffffc0203f1e <vmm_init+0x476>
    return &pages[PPN(pa) - nbase];
ffffffffc0203d50:	413787b3          	sub	a5,a5,s3
ffffffffc0203d54:	00011417          	auipc	s0,0x11
ffffffffc0203d58:	7ac40413          	addi	s0,s0,1964 # ffffffffc0215500 <pages>
ffffffffc0203d5c:	00379713          	slli	a4,a5,0x3
ffffffffc0203d60:	6008                	ld	a0,0(s0)
ffffffffc0203d62:	97ba                	add	a5,a5,a4
ffffffffc0203d64:	078e                	slli	a5,a5,0x3
    free_page(pde2page(pd0[0]));
ffffffffc0203d66:	953e                	add	a0,a0,a5
ffffffffc0203d68:	4585                	li	a1,1
ffffffffc0203d6a:	eeffd0ef          	jal	ra,ffffffffc0201c58 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203d6e:	00093503          	ld	a0,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0203d72:	000ab783          	ld	a5,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203d76:	050a                	slli	a0,a0,0x2
ffffffffc0203d78:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203d7a:	1af57263          	bleu	a5,a0,ffffffffc0203f1e <vmm_init+0x476>
    return &pages[PPN(pa) - nbase];
ffffffffc0203d7e:	413509b3          	sub	s3,a0,s3
ffffffffc0203d82:	00399793          	slli	a5,s3,0x3
ffffffffc0203d86:	6008                	ld	a0,0(s0)
ffffffffc0203d88:	99be                	add	s3,s3,a5
ffffffffc0203d8a:	098e                	slli	s3,s3,0x3
    free_page(pde2page(pd1[0]));
ffffffffc0203d8c:	4585                	li	a1,1
ffffffffc0203d8e:	954e                	add	a0,a0,s3
ffffffffc0203d90:	ec9fd0ef          	jal	ra,ffffffffc0201c58 <free_pages>
    pgdir[0] = 0;
ffffffffc0203d94:	00093023          	sd	zero,0(s2)
  asm volatile("sfence.vma");
ffffffffc0203d98:	12000073          	sfence.vma
    flush_tlb();

    mm->pgdir = NULL;
ffffffffc0203d9c:	0004bc23          	sd	zero,24(s1)
    mm_destroy(mm);
ffffffffc0203da0:	8526                	mv	a0,s1
ffffffffc0203da2:	cd9ff0ef          	jal	ra,ffffffffc0203a7a <mm_destroy>
    check_mm_struct = NULL;
ffffffffc0203da6:	00012797          	auipc	a5,0x12
ffffffffc0203daa:	8407b123          	sd	zero,-1982(a5) # ffffffffc02155e8 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203dae:	ef1fd0ef          	jal	ra,ffffffffc0201c9e <nr_free_pages>
ffffffffc0203db2:	1aaa1263          	bne	s4,a0,ffffffffc0203f56 <vmm_init+0x4ae>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc0203db6:	00003517          	auipc	a0,0x3
ffffffffc0203dba:	d0a50513          	addi	a0,a0,-758 # ffffffffc0206ac0 <default_pmm_manager+0xe20>
ffffffffc0203dbe:	bd0fc0ef          	jal	ra,ffffffffc020018e <cprintf>
}
ffffffffc0203dc2:	7442                	ld	s0,48(sp)
ffffffffc0203dc4:	70e2                	ld	ra,56(sp)
ffffffffc0203dc6:	74a2                	ld	s1,40(sp)
ffffffffc0203dc8:	7902                	ld	s2,32(sp)
ffffffffc0203dca:	69e2                	ld	s3,24(sp)
ffffffffc0203dcc:	6a42                	ld	s4,16(sp)
ffffffffc0203dce:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203dd0:	00003517          	auipc	a0,0x3
ffffffffc0203dd4:	d1050513          	addi	a0,a0,-752 # ffffffffc0206ae0 <default_pmm_manager+0xe40>
}
ffffffffc0203dd8:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203dda:	bb4fc06f          	j	ffffffffc020018e <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203dde:	00003697          	auipc	a3,0x3
ffffffffc0203de2:	b2a68693          	addi	a3,a3,-1238 # ffffffffc0206908 <default_pmm_manager+0xc68>
ffffffffc0203de6:	00002617          	auipc	a2,0x2
ffffffffc0203dea:	b2260613          	addi	a2,a2,-1246 # ffffffffc0205908 <commands+0x878>
ffffffffc0203dee:	0d800593          	li	a1,216
ffffffffc0203df2:	00003517          	auipc	a0,0x3
ffffffffc0203df6:	9ee50513          	addi	a0,a0,-1554 # ffffffffc02067e0 <default_pmm_manager+0xb40>
ffffffffc0203dfa:	e56fc0ef          	jal	ra,ffffffffc0200450 <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0203dfe:	00003697          	auipc	a3,0x3
ffffffffc0203e02:	b9268693          	addi	a3,a3,-1134 # ffffffffc0206990 <default_pmm_manager+0xcf0>
ffffffffc0203e06:	00002617          	auipc	a2,0x2
ffffffffc0203e0a:	b0260613          	addi	a2,a2,-1278 # ffffffffc0205908 <commands+0x878>
ffffffffc0203e0e:	0e800593          	li	a1,232
ffffffffc0203e12:	00003517          	auipc	a0,0x3
ffffffffc0203e16:	9ce50513          	addi	a0,a0,-1586 # ffffffffc02067e0 <default_pmm_manager+0xb40>
ffffffffc0203e1a:	e36fc0ef          	jal	ra,ffffffffc0200450 <__panic>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0203e1e:	00003697          	auipc	a3,0x3
ffffffffc0203e22:	ba268693          	addi	a3,a3,-1118 # ffffffffc02069c0 <default_pmm_manager+0xd20>
ffffffffc0203e26:	00002617          	auipc	a2,0x2
ffffffffc0203e2a:	ae260613          	addi	a2,a2,-1310 # ffffffffc0205908 <commands+0x878>
ffffffffc0203e2e:	0e900593          	li	a1,233
ffffffffc0203e32:	00003517          	auipc	a0,0x3
ffffffffc0203e36:	9ae50513          	addi	a0,a0,-1618 # ffffffffc02067e0 <default_pmm_manager+0xb40>
ffffffffc0203e3a:	e16fc0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(vma != NULL);
ffffffffc0203e3e:	00002697          	auipc	a3,0x2
ffffffffc0203e42:	61268693          	addi	a3,a3,1554 # ffffffffc0206450 <default_pmm_manager+0x7b0>
ffffffffc0203e46:	00002617          	auipc	a2,0x2
ffffffffc0203e4a:	ac260613          	addi	a2,a2,-1342 # ffffffffc0205908 <commands+0x878>
ffffffffc0203e4e:	10800593          	li	a1,264
ffffffffc0203e52:	00003517          	auipc	a0,0x3
ffffffffc0203e56:	98e50513          	addi	a0,a0,-1650 # ffffffffc02067e0 <default_pmm_manager+0xb40>
ffffffffc0203e5a:	df6fc0ef          	jal	ra,ffffffffc0200450 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203e5e:	00003697          	auipc	a3,0x3
ffffffffc0203e62:	a9268693          	addi	a3,a3,-1390 # ffffffffc02068f0 <default_pmm_manager+0xc50>
ffffffffc0203e66:	00002617          	auipc	a2,0x2
ffffffffc0203e6a:	aa260613          	addi	a2,a2,-1374 # ffffffffc0205908 <commands+0x878>
ffffffffc0203e6e:	0d600593          	li	a1,214
ffffffffc0203e72:	00003517          	auipc	a0,0x3
ffffffffc0203e76:	96e50513          	addi	a0,a0,-1682 # ffffffffc02067e0 <default_pmm_manager+0xb40>
ffffffffc0203e7a:	dd6fc0ef          	jal	ra,ffffffffc0200450 <__panic>
        assert(vma3 == NULL);
ffffffffc0203e7e:	00003697          	auipc	a3,0x3
ffffffffc0203e82:	ae268693          	addi	a3,a3,-1310 # ffffffffc0206960 <default_pmm_manager+0xcc0>
ffffffffc0203e86:	00002617          	auipc	a2,0x2
ffffffffc0203e8a:	a8260613          	addi	a2,a2,-1406 # ffffffffc0205908 <commands+0x878>
ffffffffc0203e8e:	0e200593          	li	a1,226
ffffffffc0203e92:	00003517          	auipc	a0,0x3
ffffffffc0203e96:	94e50513          	addi	a0,a0,-1714 # ffffffffc02067e0 <default_pmm_manager+0xb40>
ffffffffc0203e9a:	db6fc0ef          	jal	ra,ffffffffc0200450 <__panic>
        assert(vma2 != NULL);
ffffffffc0203e9e:	00003697          	auipc	a3,0x3
ffffffffc0203ea2:	ab268693          	addi	a3,a3,-1358 # ffffffffc0206950 <default_pmm_manager+0xcb0>
ffffffffc0203ea6:	00002617          	auipc	a2,0x2
ffffffffc0203eaa:	a6260613          	addi	a2,a2,-1438 # ffffffffc0205908 <commands+0x878>
ffffffffc0203eae:	0e000593          	li	a1,224
ffffffffc0203eb2:	00003517          	auipc	a0,0x3
ffffffffc0203eb6:	92e50513          	addi	a0,a0,-1746 # ffffffffc02067e0 <default_pmm_manager+0xb40>
ffffffffc0203eba:	d96fc0ef          	jal	ra,ffffffffc0200450 <__panic>
        assert(vma1 != NULL);
ffffffffc0203ebe:	00003697          	auipc	a3,0x3
ffffffffc0203ec2:	a8268693          	addi	a3,a3,-1406 # ffffffffc0206940 <default_pmm_manager+0xca0>
ffffffffc0203ec6:	00002617          	auipc	a2,0x2
ffffffffc0203eca:	a4260613          	addi	a2,a2,-1470 # ffffffffc0205908 <commands+0x878>
ffffffffc0203ece:	0de00593          	li	a1,222
ffffffffc0203ed2:	00003517          	auipc	a0,0x3
ffffffffc0203ed6:	90e50513          	addi	a0,a0,-1778 # ffffffffc02067e0 <default_pmm_manager+0xb40>
ffffffffc0203eda:	d76fc0ef          	jal	ra,ffffffffc0200450 <__panic>
        assert(vma5 == NULL);
ffffffffc0203ede:	00003697          	auipc	a3,0x3
ffffffffc0203ee2:	aa268693          	addi	a3,a3,-1374 # ffffffffc0206980 <default_pmm_manager+0xce0>
ffffffffc0203ee6:	00002617          	auipc	a2,0x2
ffffffffc0203eea:	a2260613          	addi	a2,a2,-1502 # ffffffffc0205908 <commands+0x878>
ffffffffc0203eee:	0e600593          	li	a1,230
ffffffffc0203ef2:	00003517          	auipc	a0,0x3
ffffffffc0203ef6:	8ee50513          	addi	a0,a0,-1810 # ffffffffc02067e0 <default_pmm_manager+0xb40>
ffffffffc0203efa:	d56fc0ef          	jal	ra,ffffffffc0200450 <__panic>
        assert(vma4 == NULL);
ffffffffc0203efe:	00003697          	auipc	a3,0x3
ffffffffc0203f02:	a7268693          	addi	a3,a3,-1422 # ffffffffc0206970 <default_pmm_manager+0xcd0>
ffffffffc0203f06:	00002617          	auipc	a2,0x2
ffffffffc0203f0a:	a0260613          	addi	a2,a2,-1534 # ffffffffc0205908 <commands+0x878>
ffffffffc0203f0e:	0e400593          	li	a1,228
ffffffffc0203f12:	00003517          	auipc	a0,0x3
ffffffffc0203f16:	8ce50513          	addi	a0,a0,-1842 # ffffffffc02067e0 <default_pmm_manager+0xb40>
ffffffffc0203f1a:	d36fc0ef          	jal	ra,ffffffffc0200450 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203f1e:	00002617          	auipc	a2,0x2
ffffffffc0203f22:	e3260613          	addi	a2,a2,-462 # ffffffffc0205d50 <default_pmm_manager+0xb0>
ffffffffc0203f26:	06200593          	li	a1,98
ffffffffc0203f2a:	00002517          	auipc	a0,0x2
ffffffffc0203f2e:	dee50513          	addi	a0,a0,-530 # ffffffffc0205d18 <default_pmm_manager+0x78>
ffffffffc0203f32:	d1efc0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(mm != NULL);
ffffffffc0203f36:	00002697          	auipc	a3,0x2
ffffffffc0203f3a:	4e268693          	addi	a3,a3,1250 # ffffffffc0206418 <default_pmm_manager+0x778>
ffffffffc0203f3e:	00002617          	auipc	a2,0x2
ffffffffc0203f42:	9ca60613          	addi	a2,a2,-1590 # ffffffffc0205908 <commands+0x878>
ffffffffc0203f46:	0c200593          	li	a1,194
ffffffffc0203f4a:	00003517          	auipc	a0,0x3
ffffffffc0203f4e:	89650513          	addi	a0,a0,-1898 # ffffffffc02067e0 <default_pmm_manager+0xb40>
ffffffffc0203f52:	cfefc0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203f56:	00003697          	auipc	a3,0x3
ffffffffc0203f5a:	b4268693          	addi	a3,a3,-1214 # ffffffffc0206a98 <default_pmm_manager+0xdf8>
ffffffffc0203f5e:	00002617          	auipc	a2,0x2
ffffffffc0203f62:	9aa60613          	addi	a2,a2,-1622 # ffffffffc0205908 <commands+0x878>
ffffffffc0203f66:	12400593          	li	a1,292
ffffffffc0203f6a:	00003517          	auipc	a0,0x3
ffffffffc0203f6e:	87650513          	addi	a0,a0,-1930 # ffffffffc02067e0 <default_pmm_manager+0xb40>
ffffffffc0203f72:	cdefc0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(pgdir[0] == 0);
ffffffffc0203f76:	00002697          	auipc	a3,0x2
ffffffffc0203f7a:	4ca68693          	addi	a3,a3,1226 # ffffffffc0206440 <default_pmm_manager+0x7a0>
ffffffffc0203f7e:	00002617          	auipc	a2,0x2
ffffffffc0203f82:	98a60613          	addi	a2,a2,-1654 # ffffffffc0205908 <commands+0x878>
ffffffffc0203f86:	10500593          	li	a1,261
ffffffffc0203f8a:	00003517          	auipc	a0,0x3
ffffffffc0203f8e:	85650513          	addi	a0,a0,-1962 # ffffffffc02067e0 <default_pmm_manager+0xb40>
ffffffffc0203f92:	cbefc0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc0203f96:	00003697          	auipc	a3,0x3
ffffffffc0203f9a:	ad268693          	addi	a3,a3,-1326 # ffffffffc0206a68 <default_pmm_manager+0xdc8>
ffffffffc0203f9e:	00002617          	auipc	a2,0x2
ffffffffc0203fa2:	96a60613          	addi	a2,a2,-1686 # ffffffffc0205908 <commands+0x878>
ffffffffc0203fa6:	10d00593          	li	a1,269
ffffffffc0203faa:	00003517          	auipc	a0,0x3
ffffffffc0203fae:	83650513          	addi	a0,a0,-1994 # ffffffffc02067e0 <default_pmm_manager+0xb40>
ffffffffc0203fb2:	c9efc0ef          	jal	ra,ffffffffc0200450 <__panic>
    return KADDR(page2pa(page));
ffffffffc0203fb6:	00002617          	auipc	a2,0x2
ffffffffc0203fba:	d3a60613          	addi	a2,a2,-710 # ffffffffc0205cf0 <default_pmm_manager+0x50>
ffffffffc0203fbe:	06900593          	li	a1,105
ffffffffc0203fc2:	00002517          	auipc	a0,0x2
ffffffffc0203fc6:	d5650513          	addi	a0,a0,-682 # ffffffffc0205d18 <default_pmm_manager+0x78>
ffffffffc0203fca:	c86fc0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(sum == 0);
ffffffffc0203fce:	00003697          	auipc	a3,0x3
ffffffffc0203fd2:	aba68693          	addi	a3,a3,-1350 # ffffffffc0206a88 <default_pmm_manager+0xde8>
ffffffffc0203fd6:	00002617          	auipc	a2,0x2
ffffffffc0203fda:	93260613          	addi	a2,a2,-1742 # ffffffffc0205908 <commands+0x878>
ffffffffc0203fde:	11700593          	li	a1,279
ffffffffc0203fe2:	00002517          	auipc	a0,0x2
ffffffffc0203fe6:	7fe50513          	addi	a0,a0,2046 # ffffffffc02067e0 <default_pmm_manager+0xb40>
ffffffffc0203fea:	c66fc0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc0203fee:	00003697          	auipc	a3,0x3
ffffffffc0203ff2:	a6268693          	addi	a3,a3,-1438 # ffffffffc0206a50 <default_pmm_manager+0xdb0>
ffffffffc0203ff6:	00002617          	auipc	a2,0x2
ffffffffc0203ffa:	91260613          	addi	a2,a2,-1774 # ffffffffc0205908 <commands+0x878>
ffffffffc0203ffe:	10100593          	li	a1,257
ffffffffc0204002:	00002517          	auipc	a0,0x2
ffffffffc0204006:	7de50513          	addi	a0,a0,2014 # ffffffffc02067e0 <default_pmm_manager+0xb40>
ffffffffc020400a:	c46fc0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc020400e <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr) {
ffffffffc020400e:	7179                	addi	sp,sp,-48
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0204010:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr) {
ffffffffc0204012:	f022                	sd	s0,32(sp)
ffffffffc0204014:	ec26                	sd	s1,24(sp)
ffffffffc0204016:	f406                	sd	ra,40(sp)
ffffffffc0204018:	e84a                	sd	s2,16(sp)
ffffffffc020401a:	8432                	mv	s0,a2
ffffffffc020401c:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc020401e:	951ff0ef          	jal	ra,ffffffffc020396e <find_vma>

    pgfault_num++;
ffffffffc0204022:	00011797          	auipc	a5,0x11
ffffffffc0204026:	48278793          	addi	a5,a5,1154 # ffffffffc02154a4 <pgfault_num>
ffffffffc020402a:	439c                	lw	a5,0(a5)
ffffffffc020402c:	2785                	addiw	a5,a5,1
ffffffffc020402e:	00011717          	auipc	a4,0x11
ffffffffc0204032:	46f72b23          	sw	a5,1142(a4) # ffffffffc02154a4 <pgfault_num>
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc0204036:	c551                	beqz	a0,ffffffffc02040c2 <do_pgfault+0xb4>
ffffffffc0204038:	651c                	ld	a5,8(a0)
ffffffffc020403a:	08f46463          	bltu	s0,a5,ffffffffc02040c2 <do_pgfault+0xb4>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc020403e:	4d1c                	lw	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc0204040:	4941                	li	s2,16
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0204042:	8b89                	andi	a5,a5,2
ffffffffc0204044:	efb1                	bnez	a5,ffffffffc02040a0 <do_pgfault+0x92>
        perm |= READ_WRITE;
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0204046:	767d                	lui	a2,0xfffff

    pte_t *ptep=NULL;
  
    // try to find a pte, if pte's PT(Page Table) isn't existed, then create a PT.
    // (notice the 3th parameter '1')
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc0204048:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc020404a:	8c71                	and	s0,s0,a2
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc020404c:	85a2                	mv	a1,s0
ffffffffc020404e:	4605                	li	a2,1
ffffffffc0204050:	c8ffd0ef          	jal	ra,ffffffffc0201cde <get_pte>
ffffffffc0204054:	c941                	beqz	a0,ffffffffc02040e4 <do_pgfault+0xd6>
        cprintf("get_pte in do_pgfault failed\n");
        goto failed;
    }
    if (*ptep == 0) { // if the phy addr isn't exist, then alloc a page & map the phy addr with logical addr
ffffffffc0204056:	610c                	ld	a1,0(a0)
ffffffffc0204058:	c5b1                	beqz	a1,ffffffffc02040a4 <do_pgfault+0x96>
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
ffffffffc020405a:	00011797          	auipc	a5,0x11
ffffffffc020405e:	44678793          	addi	a5,a5,1094 # ffffffffc02154a0 <swap_init_ok>
ffffffffc0204062:	439c                	lw	a5,0(a5)
ffffffffc0204064:	2781                	sext.w	a5,a5
ffffffffc0204066:	c7bd                	beqz	a5,ffffffffc02040d4 <do_pgfault+0xc6>
            //(2) According to the mm,
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            //(3) make the page swappable.
            swap_in(mm, addr, &page);//分配一个内存页并将磁盘页的内容读入这个内存页
ffffffffc0204068:	85a2                	mv	a1,s0
ffffffffc020406a:	0030                	addi	a2,sp,8
ffffffffc020406c:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc020406e:	e402                	sd	zero,8(sp)
            swap_in(mm, addr, &page);//分配一个内存页并将磁盘页的内容读入这个内存页
ffffffffc0204070:	c6cff0ef          	jal	ra,ffffffffc02034dc <swap_in>
            page_insert(mm->pgdir,page,addr,perm);//建立Page的phy addr与线性addr la的映射
ffffffffc0204074:	65a2                	ld	a1,8(sp)
ffffffffc0204076:	6c88                	ld	a0,24(s1)
ffffffffc0204078:	86ca                	mv	a3,s2
ffffffffc020407a:	8622                	mv	a2,s0
ffffffffc020407c:	f43fd0ef          	jal	ra,ffffffffc0201fbe <page_insert>
            swap_map_swappable(mm, addr, page, 1);//设置页面可交换
ffffffffc0204080:	6622                	ld	a2,8(sp)
ffffffffc0204082:	4685                	li	a3,1
ffffffffc0204084:	85a2                	mv	a1,s0
ffffffffc0204086:	8526                	mv	a0,s1
ffffffffc0204088:	b30ff0ef          	jal	ra,ffffffffc02033b8 <swap_map_swappable>

            page->pra_vaddr = addr;
ffffffffc020408c:	6722                	ld	a4,8(sp)
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
   }

   ret = 0;
ffffffffc020408e:	4781                	li	a5,0
            page->pra_vaddr = addr;
ffffffffc0204090:	e320                	sd	s0,64(a4)
failed:
    return ret;
}
ffffffffc0204092:	70a2                	ld	ra,40(sp)
ffffffffc0204094:	7402                	ld	s0,32(sp)
ffffffffc0204096:	64e2                	ld	s1,24(sp)
ffffffffc0204098:	6942                	ld	s2,16(sp)
ffffffffc020409a:	853e                	mv	a0,a5
ffffffffc020409c:	6145                	addi	sp,sp,48
ffffffffc020409e:	8082                	ret
        perm |= READ_WRITE;
ffffffffc02040a0:	495d                	li	s2,23
ffffffffc02040a2:	b755                	j	ffffffffc0204046 <do_pgfault+0x38>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc02040a4:	6c88                	ld	a0,24(s1)
ffffffffc02040a6:	864a                	mv	a2,s2
ffffffffc02040a8:	85a2                	mv	a1,s0
ffffffffc02040aa:	acffe0ef          	jal	ra,ffffffffc0202b78 <pgdir_alloc_page>
   ret = 0;
ffffffffc02040ae:	4781                	li	a5,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc02040b0:	f16d                	bnez	a0,ffffffffc0204092 <do_pgfault+0x84>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc02040b2:	00002517          	auipc	a0,0x2
ffffffffc02040b6:	78e50513          	addi	a0,a0,1934 # ffffffffc0206840 <default_pmm_manager+0xba0>
ffffffffc02040ba:	8d4fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    ret = -E_NO_MEM;
ffffffffc02040be:	57f1                	li	a5,-4
            goto failed;
ffffffffc02040c0:	bfc9                	j	ffffffffc0204092 <do_pgfault+0x84>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc02040c2:	85a2                	mv	a1,s0
ffffffffc02040c4:	00002517          	auipc	a0,0x2
ffffffffc02040c8:	72c50513          	addi	a0,a0,1836 # ffffffffc02067f0 <default_pmm_manager+0xb50>
ffffffffc02040cc:	8c2fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    int ret = -E_INVAL;
ffffffffc02040d0:	57f5                	li	a5,-3
        goto failed;
ffffffffc02040d2:	b7c1                	j	ffffffffc0204092 <do_pgfault+0x84>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc02040d4:	00002517          	auipc	a0,0x2
ffffffffc02040d8:	79450513          	addi	a0,a0,1940 # ffffffffc0206868 <default_pmm_manager+0xbc8>
ffffffffc02040dc:	8b2fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    ret = -E_NO_MEM;
ffffffffc02040e0:	57f1                	li	a5,-4
            goto failed;
ffffffffc02040e2:	bf45                	j	ffffffffc0204092 <do_pgfault+0x84>
        cprintf("get_pte in do_pgfault failed\n");
ffffffffc02040e4:	00002517          	auipc	a0,0x2
ffffffffc02040e8:	73c50513          	addi	a0,a0,1852 # ffffffffc0206820 <default_pmm_manager+0xb80>
ffffffffc02040ec:	8a2fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    ret = -E_NO_MEM;
ffffffffc02040f0:	57f1                	li	a5,-4
        goto failed;
ffffffffc02040f2:	b745                	j	ffffffffc0204092 <do_pgfault+0x84>

ffffffffc02040f4 <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc02040f4:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc02040f6:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc02040f8:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc02040fa:	c82fc0ef          	jal	ra,ffffffffc020057c <ide_device_valid>
ffffffffc02040fe:	cd01                	beqz	a0,ffffffffc0204116 <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204100:	4505                	li	a0,1
ffffffffc0204102:	c80fc0ef          	jal	ra,ffffffffc0200582 <ide_device_size>
}
ffffffffc0204106:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204108:	810d                	srli	a0,a0,0x3
ffffffffc020410a:	00011797          	auipc	a5,0x11
ffffffffc020410e:	48a7b323          	sd	a0,1158(a5) # ffffffffc0215590 <max_swap_offset>
}
ffffffffc0204112:	0141                	addi	sp,sp,16
ffffffffc0204114:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0204116:	00003617          	auipc	a2,0x3
ffffffffc020411a:	9e260613          	addi	a2,a2,-1566 # ffffffffc0206af8 <default_pmm_manager+0xe58>
ffffffffc020411e:	45b5                	li	a1,13
ffffffffc0204120:	00003517          	auipc	a0,0x3
ffffffffc0204124:	9f850513          	addi	a0,a0,-1544 # ffffffffc0206b18 <default_pmm_manager+0xe78>
ffffffffc0204128:	b28fc0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc020412c <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc020412c:	1141                	addi	sp,sp,-16
ffffffffc020412e:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204130:	00855793          	srli	a5,a0,0x8
ffffffffc0204134:	c7b5                	beqz	a5,ffffffffc02041a0 <swapfs_read+0x74>
ffffffffc0204136:	00011717          	auipc	a4,0x11
ffffffffc020413a:	45a70713          	addi	a4,a4,1114 # ffffffffc0215590 <max_swap_offset>
ffffffffc020413e:	6318                	ld	a4,0(a4)
ffffffffc0204140:	06e7f063          	bleu	a4,a5,ffffffffc02041a0 <swapfs_read+0x74>
    return page - pages + nbase;
ffffffffc0204144:	00011717          	auipc	a4,0x11
ffffffffc0204148:	3bc70713          	addi	a4,a4,956 # ffffffffc0215500 <pages>
ffffffffc020414c:	6310                	ld	a2,0(a4)
ffffffffc020414e:	00001717          	auipc	a4,0x1
ffffffffc0204152:	7a270713          	addi	a4,a4,1954 # ffffffffc02058f0 <commands+0x860>
ffffffffc0204156:	00003697          	auipc	a3,0x3
ffffffffc020415a:	df268693          	addi	a3,a3,-526 # ffffffffc0206f48 <nbase>
ffffffffc020415e:	40c58633          	sub	a2,a1,a2
ffffffffc0204162:	630c                	ld	a1,0(a4)
ffffffffc0204164:	860d                	srai	a2,a2,0x3
    return KADDR(page2pa(page));
ffffffffc0204166:	00011717          	auipc	a4,0x11
ffffffffc020416a:	32a70713          	addi	a4,a4,810 # ffffffffc0215490 <npage>
    return page - pages + nbase;
ffffffffc020416e:	02b60633          	mul	a2,a2,a1
ffffffffc0204172:	0037959b          	slliw	a1,a5,0x3
ffffffffc0204176:	629c                	ld	a5,0(a3)
    return KADDR(page2pa(page));
ffffffffc0204178:	6318                	ld	a4,0(a4)
    return page - pages + nbase;
ffffffffc020417a:	963e                	add	a2,a2,a5
    return KADDR(page2pa(page));
ffffffffc020417c:	57fd                	li	a5,-1
ffffffffc020417e:	83b1                	srli	a5,a5,0xc
ffffffffc0204180:	8ff1                	and	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0204182:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204184:	02e7fa63          	bleu	a4,a5,ffffffffc02041b8 <swapfs_read+0x8c>
ffffffffc0204188:	00011797          	auipc	a5,0x11
ffffffffc020418c:	36878793          	addi	a5,a5,872 # ffffffffc02154f0 <va_pa_offset>
ffffffffc0204190:	639c                	ld	a5,0(a5)
}
ffffffffc0204192:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204194:	46a1                	li	a3,8
ffffffffc0204196:	963e                	add	a2,a2,a5
ffffffffc0204198:	4505                	li	a0,1
}
ffffffffc020419a:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc020419c:	becfc06f          	j	ffffffffc0200588 <ide_read_secs>
ffffffffc02041a0:	86aa                	mv	a3,a0
ffffffffc02041a2:	00003617          	auipc	a2,0x3
ffffffffc02041a6:	98e60613          	addi	a2,a2,-1650 # ffffffffc0206b30 <default_pmm_manager+0xe90>
ffffffffc02041aa:	45d1                	li	a1,20
ffffffffc02041ac:	00003517          	auipc	a0,0x3
ffffffffc02041b0:	96c50513          	addi	a0,a0,-1684 # ffffffffc0206b18 <default_pmm_manager+0xe78>
ffffffffc02041b4:	a9cfc0ef          	jal	ra,ffffffffc0200450 <__panic>
ffffffffc02041b8:	86b2                	mv	a3,a2
ffffffffc02041ba:	06900593          	li	a1,105
ffffffffc02041be:	00002617          	auipc	a2,0x2
ffffffffc02041c2:	b3260613          	addi	a2,a2,-1230 # ffffffffc0205cf0 <default_pmm_manager+0x50>
ffffffffc02041c6:	00002517          	auipc	a0,0x2
ffffffffc02041ca:	b5250513          	addi	a0,a0,-1198 # ffffffffc0205d18 <default_pmm_manager+0x78>
ffffffffc02041ce:	a82fc0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc02041d2 <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc02041d2:	1141                	addi	sp,sp,-16
ffffffffc02041d4:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc02041d6:	00855793          	srli	a5,a0,0x8
ffffffffc02041da:	c7b5                	beqz	a5,ffffffffc0204246 <swapfs_write+0x74>
ffffffffc02041dc:	00011717          	auipc	a4,0x11
ffffffffc02041e0:	3b470713          	addi	a4,a4,948 # ffffffffc0215590 <max_swap_offset>
ffffffffc02041e4:	6318                	ld	a4,0(a4)
ffffffffc02041e6:	06e7f063          	bleu	a4,a5,ffffffffc0204246 <swapfs_write+0x74>
    return page - pages + nbase;
ffffffffc02041ea:	00011717          	auipc	a4,0x11
ffffffffc02041ee:	31670713          	addi	a4,a4,790 # ffffffffc0215500 <pages>
ffffffffc02041f2:	6310                	ld	a2,0(a4)
ffffffffc02041f4:	00001717          	auipc	a4,0x1
ffffffffc02041f8:	6fc70713          	addi	a4,a4,1788 # ffffffffc02058f0 <commands+0x860>
ffffffffc02041fc:	00003697          	auipc	a3,0x3
ffffffffc0204200:	d4c68693          	addi	a3,a3,-692 # ffffffffc0206f48 <nbase>
ffffffffc0204204:	40c58633          	sub	a2,a1,a2
ffffffffc0204208:	630c                	ld	a1,0(a4)
ffffffffc020420a:	860d                	srai	a2,a2,0x3
    return KADDR(page2pa(page));
ffffffffc020420c:	00011717          	auipc	a4,0x11
ffffffffc0204210:	28470713          	addi	a4,a4,644 # ffffffffc0215490 <npage>
    return page - pages + nbase;
ffffffffc0204214:	02b60633          	mul	a2,a2,a1
ffffffffc0204218:	0037959b          	slliw	a1,a5,0x3
ffffffffc020421c:	629c                	ld	a5,0(a3)
    return KADDR(page2pa(page));
ffffffffc020421e:	6318                	ld	a4,0(a4)
    return page - pages + nbase;
ffffffffc0204220:	963e                	add	a2,a2,a5
    return KADDR(page2pa(page));
ffffffffc0204222:	57fd                	li	a5,-1
ffffffffc0204224:	83b1                	srli	a5,a5,0xc
ffffffffc0204226:	8ff1                	and	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0204228:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc020422a:	02e7fa63          	bleu	a4,a5,ffffffffc020425e <swapfs_write+0x8c>
ffffffffc020422e:	00011797          	auipc	a5,0x11
ffffffffc0204232:	2c278793          	addi	a5,a5,706 # ffffffffc02154f0 <va_pa_offset>
ffffffffc0204236:	639c                	ld	a5,0(a5)
}
ffffffffc0204238:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc020423a:	46a1                	li	a3,8
ffffffffc020423c:	963e                	add	a2,a2,a5
ffffffffc020423e:	4505                	li	a0,1
}
ffffffffc0204240:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204242:	b6afc06f          	j	ffffffffc02005ac <ide_write_secs>
ffffffffc0204246:	86aa                	mv	a3,a0
ffffffffc0204248:	00003617          	auipc	a2,0x3
ffffffffc020424c:	8e860613          	addi	a2,a2,-1816 # ffffffffc0206b30 <default_pmm_manager+0xe90>
ffffffffc0204250:	45e5                	li	a1,25
ffffffffc0204252:	00003517          	auipc	a0,0x3
ffffffffc0204256:	8c650513          	addi	a0,a0,-1850 # ffffffffc0206b18 <default_pmm_manager+0xe78>
ffffffffc020425a:	9f6fc0ef          	jal	ra,ffffffffc0200450 <__panic>
ffffffffc020425e:	86b2                	mv	a3,a2
ffffffffc0204260:	06900593          	li	a1,105
ffffffffc0204264:	00002617          	auipc	a2,0x2
ffffffffc0204268:	a8c60613          	addi	a2,a2,-1396 # ffffffffc0205cf0 <default_pmm_manager+0x50>
ffffffffc020426c:	00002517          	auipc	a0,0x2
ffffffffc0204270:	aac50513          	addi	a0,a0,-1364 # ffffffffc0205d18 <default_pmm_manager+0x78>
ffffffffc0204274:	9dcfc0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc0204278 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0204278:	8526                	mv	a0,s1
	jalr s0
ffffffffc020427a:	9402                	jalr	s0

	jal do_exit
ffffffffc020427c:	478000ef          	jal	ra,ffffffffc02046f4 <do_exit>

ffffffffc0204280 <alloc_proc>:
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void) {
ffffffffc0204280:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204282:	0e800513          	li	a0,232
alloc_proc(void) {
ffffffffc0204286:	e022                	sd	s0,0(sp)
ffffffffc0204288:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc020428a:	f42fd0ef          	jal	ra,ffffffffc02019cc <kmalloc>
ffffffffc020428e:	842a                	mv	s0,a0
    if (proc != NULL) {
ffffffffc0204290:	c529                	beqz	a0,ffffffffc02042da <alloc_proc+0x5a>

    *uint32_t flags；//进程标志

    *char name[PROC_name_LEN+1]；//进程名称
     */
        proc->state = PROC_UNINIT;
ffffffffc0204292:	57fd                	li	a5,-1
ffffffffc0204294:	1782                	slli	a5,a5,0x20
ffffffffc0204296:	e11c                	sd	a5,0(a0)
        proc->runs = 0;
        proc->kstack = NULL;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0204298:	07000613          	li	a2,112
ffffffffc020429c:	4581                	li	a1,0
        proc->runs = 0;
ffffffffc020429e:	00052423          	sw	zero,8(a0)
        proc->kstack = NULL;
ffffffffc02042a2:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc02042a6:	00052c23          	sw	zero,24(a0)
        proc->parent = NULL;
ffffffffc02042aa:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc02042ae:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc02042b2:	03050513          	addi	a0,a0,48
ffffffffc02042b6:	44f000ef          	jal	ra,ffffffffc0204f04 <memset>
        proc->tf = NULL;
        proc->cr3 = boot_cr3;
ffffffffc02042ba:	00011797          	auipc	a5,0x11
ffffffffc02042be:	23e78793          	addi	a5,a5,574 # ffffffffc02154f8 <boot_cr3>
ffffffffc02042c2:	639c                	ld	a5,0(a5)
        proc->tf = NULL;
ffffffffc02042c4:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;
ffffffffc02042c8:	0a042823          	sw	zero,176(s0)
        proc->cr3 = boot_cr3;
ffffffffc02042cc:	f45c                	sd	a5,168(s0)
        memset(proc->name, 0, PROC_NAME_LEN+1);
ffffffffc02042ce:	4641                	li	a2,16
ffffffffc02042d0:	4581                	li	a1,0
ffffffffc02042d2:	0b440513          	addi	a0,s0,180
ffffffffc02042d6:	42f000ef          	jal	ra,ffffffffc0204f04 <memset>
    }
    return proc;
}
ffffffffc02042da:	8522                	mv	a0,s0
ffffffffc02042dc:	60a2                	ld	ra,8(sp)
ffffffffc02042de:	6402                	ld	s0,0(sp)
ffffffffc02042e0:	0141                	addi	sp,sp,16
ffffffffc02042e2:	8082                	ret

ffffffffc02042e4 <forkret>:
// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void) {
    forkrets(current->tf);
ffffffffc02042e4:	00011797          	auipc	a5,0x11
ffffffffc02042e8:	1c478793          	addi	a5,a5,452 # ffffffffc02154a8 <current>
ffffffffc02042ec:	639c                	ld	a5,0(a5)
ffffffffc02042ee:	73c8                	ld	a0,160(a5)
ffffffffc02042f0:	8a9fc06f          	j	ffffffffc0200b98 <forkrets>

ffffffffc02042f4 <set_proc_name>:
set_proc_name(struct proc_struct *proc, const char *name) {
ffffffffc02042f4:	1101                	addi	sp,sp,-32
ffffffffc02042f6:	e822                	sd	s0,16(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02042f8:	0b450413          	addi	s0,a0,180
set_proc_name(struct proc_struct *proc, const char *name) {
ffffffffc02042fc:	e426                	sd	s1,8(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02042fe:	4641                	li	a2,16
set_proc_name(struct proc_struct *proc, const char *name) {
ffffffffc0204300:	84ae                	mv	s1,a1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204302:	8522                	mv	a0,s0
ffffffffc0204304:	4581                	li	a1,0
set_proc_name(struct proc_struct *proc, const char *name) {
ffffffffc0204306:	ec06                	sd	ra,24(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204308:	3fd000ef          	jal	ra,ffffffffc0204f04 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc020430c:	8522                	mv	a0,s0
}
ffffffffc020430e:	6442                	ld	s0,16(sp)
ffffffffc0204310:	60e2                	ld	ra,24(sp)
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204312:	85a6                	mv	a1,s1
}
ffffffffc0204314:	64a2                	ld	s1,8(sp)
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204316:	463d                	li	a2,15
}
ffffffffc0204318:	6105                	addi	sp,sp,32
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc020431a:	3fd0006f          	j	ffffffffc0204f16 <memcpy>

ffffffffc020431e <get_proc_name>:
get_proc_name(struct proc_struct *proc) {
ffffffffc020431e:	1101                	addi	sp,sp,-32
ffffffffc0204320:	e822                	sd	s0,16(sp)
    memset(name, 0, sizeof(name));
ffffffffc0204322:	00011417          	auipc	s0,0x11
ffffffffc0204326:	13e40413          	addi	s0,s0,318 # ffffffffc0215460 <name.1566>
get_proc_name(struct proc_struct *proc) {
ffffffffc020432a:	e426                	sd	s1,8(sp)
    memset(name, 0, sizeof(name));
ffffffffc020432c:	4641                	li	a2,16
get_proc_name(struct proc_struct *proc) {
ffffffffc020432e:	84aa                	mv	s1,a0
    memset(name, 0, sizeof(name));
ffffffffc0204330:	4581                	li	a1,0
ffffffffc0204332:	8522                	mv	a0,s0
get_proc_name(struct proc_struct *proc) {
ffffffffc0204334:	ec06                	sd	ra,24(sp)
    memset(name, 0, sizeof(name));
ffffffffc0204336:	3cf000ef          	jal	ra,ffffffffc0204f04 <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc020433a:	8522                	mv	a0,s0
}
ffffffffc020433c:	6442                	ld	s0,16(sp)
ffffffffc020433e:	60e2                	ld	ra,24(sp)
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc0204340:	0b448593          	addi	a1,s1,180
}
ffffffffc0204344:	64a2                	ld	s1,8(sp)
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc0204346:	463d                	li	a2,15
}
ffffffffc0204348:	6105                	addi	sp,sp,32
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc020434a:	3cd0006f          	j	ffffffffc0204f16 <memcpy>

ffffffffc020434e <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg) {
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc020434e:	00011797          	auipc	a5,0x11
ffffffffc0204352:	15a78793          	addi	a5,a5,346 # ffffffffc02154a8 <current>
ffffffffc0204356:	639c                	ld	a5,0(a5)
init_main(void *arg) {
ffffffffc0204358:	1101                	addi	sp,sp,-32
ffffffffc020435a:	e426                	sd	s1,8(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc020435c:	43c4                	lw	s1,4(a5)
init_main(void *arg) {
ffffffffc020435e:	e822                	sd	s0,16(sp)
ffffffffc0204360:	842a                	mv	s0,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc0204362:	853e                	mv	a0,a5
init_main(void *arg) {
ffffffffc0204364:	ec06                	sd	ra,24(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc0204366:	fb9ff0ef          	jal	ra,ffffffffc020431e <get_proc_name>
ffffffffc020436a:	862a                	mv	a2,a0
ffffffffc020436c:	85a6                	mv	a1,s1
ffffffffc020436e:	00003517          	auipc	a0,0x3
ffffffffc0204372:	82a50513          	addi	a0,a0,-2006 # ffffffffc0206b98 <default_pmm_manager+0xef8>
ffffffffc0204376:	e19fb0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg);
ffffffffc020437a:	85a2                	mv	a1,s0
ffffffffc020437c:	00003517          	auipc	a0,0x3
ffffffffc0204380:	84450513          	addi	a0,a0,-1980 # ffffffffc0206bc0 <default_pmm_manager+0xf20>
ffffffffc0204384:	e0bfb0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
ffffffffc0204388:	00003517          	auipc	a0,0x3
ffffffffc020438c:	84850513          	addi	a0,a0,-1976 # ffffffffc0206bd0 <default_pmm_manager+0xf30>
ffffffffc0204390:	dfffb0ef          	jal	ra,ffffffffc020018e <cprintf>
    return 0;
}
ffffffffc0204394:	60e2                	ld	ra,24(sp)
ffffffffc0204396:	6442                	ld	s0,16(sp)
ffffffffc0204398:	64a2                	ld	s1,8(sp)
ffffffffc020439a:	4501                	li	a0,0
ffffffffc020439c:	6105                	addi	sp,sp,32
ffffffffc020439e:	8082                	ret

ffffffffc02043a0 <proc_run>:
proc_run(struct proc_struct *proc) {
ffffffffc02043a0:	1101                	addi	sp,sp,-32
    if (proc != current) {
ffffffffc02043a2:	00011797          	auipc	a5,0x11
ffffffffc02043a6:	10678793          	addi	a5,a5,262 # ffffffffc02154a8 <current>
proc_run(struct proc_struct *proc) {
ffffffffc02043aa:	e426                	sd	s1,8(sp)
    if (proc != current) {
ffffffffc02043ac:	6384                	ld	s1,0(a5)
proc_run(struct proc_struct *proc) {
ffffffffc02043ae:	ec06                	sd	ra,24(sp)
ffffffffc02043b0:	e822                	sd	s0,16(sp)
ffffffffc02043b2:	e04a                	sd	s2,0(sp)
    if (proc != current) {
ffffffffc02043b4:	02a48c63          	beq	s1,a0,ffffffffc02043ec <proc_run+0x4c>
ffffffffc02043b8:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02043ba:	100027f3          	csrr	a5,sstatus
ffffffffc02043be:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02043c0:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02043c2:	e3b1                	bnez	a5,ffffffffc0204406 <proc_run+0x66>
            lcr3(next->cr3);//进程间的页表切换
ffffffffc02043c4:	745c                	ld	a5,168(s0)
            current = proc;//当前进程为切换新进程
ffffffffc02043c6:	00011717          	auipc	a4,0x11
ffffffffc02043ca:	0e873123          	sd	s0,226(a4) # ffffffffc02154a8 <current>

#define barrier() __asm__ __volatile__ ("fence" ::: "memory")

static inline void
lcr3(unsigned int cr3) {
    write_csr(sptbr, SATP32_MODE | (cr3 >> RISCV_PGSHIFT));
ffffffffc02043ce:	80000737          	lui	a4,0x80000
ffffffffc02043d2:	00c7d79b          	srliw	a5,a5,0xc
ffffffffc02043d6:	8fd9                	or	a5,a5,a4
ffffffffc02043d8:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context));//上下文切换
ffffffffc02043dc:	03040593          	addi	a1,s0,48
ffffffffc02043e0:	03048513          	addi	a0,s1,48
ffffffffc02043e4:	53c000ef          	jal	ra,ffffffffc0204920 <switch_to>
    if (flag) {
ffffffffc02043e8:	00091863          	bnez	s2,ffffffffc02043f8 <proc_run+0x58>
}
ffffffffc02043ec:	60e2                	ld	ra,24(sp)
ffffffffc02043ee:	6442                	ld	s0,16(sp)
ffffffffc02043f0:	64a2                	ld	s1,8(sp)
ffffffffc02043f2:	6902                	ld	s2,0(sp)
ffffffffc02043f4:	6105                	addi	sp,sp,32
ffffffffc02043f6:	8082                	ret
ffffffffc02043f8:	6442                	ld	s0,16(sp)
ffffffffc02043fa:	60e2                	ld	ra,24(sp)
ffffffffc02043fc:	64a2                	ld	s1,8(sp)
ffffffffc02043fe:	6902                	ld	s2,0(sp)
ffffffffc0204400:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0204402:	9d0fc06f          	j	ffffffffc02005d2 <intr_enable>
        intr_disable();
ffffffffc0204406:	9d2fc0ef          	jal	ra,ffffffffc02005d8 <intr_disable>
        return 1;
ffffffffc020440a:	4905                	li	s2,1
ffffffffc020440c:	bf65                	j	ffffffffc02043c4 <proc_run+0x24>

ffffffffc020440e <find_proc>:
    if (0 < pid && pid < MAX_PID) {
ffffffffc020440e:	0005071b          	sext.w	a4,a0
ffffffffc0204412:	6789                	lui	a5,0x2
ffffffffc0204414:	fff7069b          	addiw	a3,a4,-1
ffffffffc0204418:	17f9                	addi	a5,a5,-2
ffffffffc020441a:	04d7e063          	bltu	a5,a3,ffffffffc020445a <find_proc+0x4c>
find_proc(int pid) {
ffffffffc020441e:	1141                	addi	sp,sp,-16
ffffffffc0204420:	e022                	sd	s0,0(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204422:	45a9                	li	a1,10
ffffffffc0204424:	842a                	mv	s0,a0
ffffffffc0204426:	853a                	mv	a0,a4
find_proc(int pid) {
ffffffffc0204428:	e406                	sd	ra,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc020442a:	62c000ef          	jal	ra,ffffffffc0204a56 <hash32>
ffffffffc020442e:	02051693          	slli	a3,a0,0x20
ffffffffc0204432:	82f1                	srli	a3,a3,0x1c
ffffffffc0204434:	0000d517          	auipc	a0,0xd
ffffffffc0204438:	02c50513          	addi	a0,a0,44 # ffffffffc0211460 <hash_list>
ffffffffc020443c:	96aa                	add	a3,a3,a0
ffffffffc020443e:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list) {
ffffffffc0204440:	a029                	j	ffffffffc020444a <find_proc+0x3c>
            if (proc->pid == pid) {
ffffffffc0204442:	f2c7a703          	lw	a4,-212(a5) # 1f2c <BASE_ADDRESS-0xffffffffc01fe0d4>
ffffffffc0204446:	00870c63          	beq	a4,s0,ffffffffc020445e <find_proc+0x50>
ffffffffc020444a:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc020444c:	fef69be3          	bne	a3,a5,ffffffffc0204442 <find_proc+0x34>
}
ffffffffc0204450:	60a2                	ld	ra,8(sp)
ffffffffc0204452:	6402                	ld	s0,0(sp)
    return NULL;
ffffffffc0204454:	4501                	li	a0,0
}
ffffffffc0204456:	0141                	addi	sp,sp,16
ffffffffc0204458:	8082                	ret
    return NULL;
ffffffffc020445a:	4501                	li	a0,0
}
ffffffffc020445c:	8082                	ret
ffffffffc020445e:	60a2                	ld	ra,8(sp)
ffffffffc0204460:	6402                	ld	s0,0(sp)
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204462:	f2878513          	addi	a0,a5,-216
}
ffffffffc0204466:	0141                	addi	sp,sp,16
ffffffffc0204468:	8082                	ret

ffffffffc020446a <do_fork>:
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc020446a:	7179                	addi	sp,sp,-48
ffffffffc020446c:	e84a                	sd	s2,16(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc020446e:	00011917          	auipc	s2,0x11
ffffffffc0204472:	05290913          	addi	s2,s2,82 # ffffffffc02154c0 <nr_process>
ffffffffc0204476:	00092703          	lw	a4,0(s2)
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc020447a:	f406                	sd	ra,40(sp)
ffffffffc020447c:	f022                	sd	s0,32(sp)
ffffffffc020447e:	ec26                	sd	s1,24(sp)
ffffffffc0204480:	e44e                	sd	s3,8(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc0204482:	6785                	lui	a5,0x1
ffffffffc0204484:	1ef75063          	ble	a5,a4,ffffffffc0204664 <do_fork+0x1fa>
ffffffffc0204488:	89ae                	mv	s3,a1
ffffffffc020448a:	84b2                	mv	s1,a2
    if((proc = alloc_proc()) == NULL){
ffffffffc020448c:	df5ff0ef          	jal	ra,ffffffffc0204280 <alloc_proc>
ffffffffc0204490:	842a                	mv	s0,a0
ffffffffc0204492:	1c050b63          	beqz	a0,ffffffffc0204668 <do_fork+0x1fe>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204496:	4509                	li	a0,2
ffffffffc0204498:	f38fd0ef          	jal	ra,ffffffffc0201bd0 <alloc_pages>
    if (page != NULL) {
ffffffffc020449c:	1a050f63          	beqz	a0,ffffffffc020465a <do_fork+0x1f0>
    return page - pages + nbase;
ffffffffc02044a0:	00011797          	auipc	a5,0x11
ffffffffc02044a4:	06078793          	addi	a5,a5,96 # ffffffffc0215500 <pages>
ffffffffc02044a8:	6394                	ld	a3,0(a5)
ffffffffc02044aa:	00001797          	auipc	a5,0x1
ffffffffc02044ae:	44678793          	addi	a5,a5,1094 # ffffffffc02058f0 <commands+0x860>
    return KADDR(page2pa(page));
ffffffffc02044b2:	00011717          	auipc	a4,0x11
ffffffffc02044b6:	fde70713          	addi	a4,a4,-34 # ffffffffc0215490 <npage>
    return page - pages + nbase;
ffffffffc02044ba:	40d506b3          	sub	a3,a0,a3
ffffffffc02044be:	6388                	ld	a0,0(a5)
ffffffffc02044c0:	868d                	srai	a3,a3,0x3
ffffffffc02044c2:	00003797          	auipc	a5,0x3
ffffffffc02044c6:	a8678793          	addi	a5,a5,-1402 # ffffffffc0206f48 <nbase>
ffffffffc02044ca:	02a686b3          	mul	a3,a3,a0
ffffffffc02044ce:	6388                	ld	a0,0(a5)
    return KADDR(page2pa(page));
ffffffffc02044d0:	6318                	ld	a4,0(a4)
ffffffffc02044d2:	57fd                	li	a5,-1
ffffffffc02044d4:	83b1                	srli	a5,a5,0xc
    return page - pages + nbase;
ffffffffc02044d6:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc02044d8:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02044da:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02044dc:	1ae7f863          	bleu	a4,a5,ffffffffc020468c <do_fork+0x222>
    assert(current->mm == NULL);
ffffffffc02044e0:	00011797          	auipc	a5,0x11
ffffffffc02044e4:	fc878793          	addi	a5,a5,-56 # ffffffffc02154a8 <current>
ffffffffc02044e8:	639c                	ld	a5,0(a5)
ffffffffc02044ea:	00011717          	auipc	a4,0x11
ffffffffc02044ee:	00670713          	addi	a4,a4,6 # ffffffffc02154f0 <va_pa_offset>
ffffffffc02044f2:	6318                	ld	a4,0(a4)
ffffffffc02044f4:	779c                	ld	a5,40(a5)
ffffffffc02044f6:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02044f8:	e814                	sd	a3,16(s0)
    assert(current->mm == NULL);
ffffffffc02044fa:	16079963          	bnez	a5,ffffffffc020466c <do_fork+0x202>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc02044fe:	6789                	lui	a5,0x2
ffffffffc0204500:	ee078793          	addi	a5,a5,-288 # 1ee0 <BASE_ADDRESS-0xffffffffc01fe120>
ffffffffc0204504:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0204506:	8626                	mv	a2,s1
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204508:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc020450a:	87b6                	mv	a5,a3
ffffffffc020450c:	12048893          	addi	a7,s1,288
ffffffffc0204510:	00063803          	ld	a6,0(a2)
ffffffffc0204514:	6608                	ld	a0,8(a2)
ffffffffc0204516:	6a0c                	ld	a1,16(a2)
ffffffffc0204518:	6e18                	ld	a4,24(a2)
ffffffffc020451a:	0107b023          	sd	a6,0(a5)
ffffffffc020451e:	e788                	sd	a0,8(a5)
ffffffffc0204520:	eb8c                	sd	a1,16(a5)
ffffffffc0204522:	ef98                	sd	a4,24(a5)
ffffffffc0204524:	02060613          	addi	a2,a2,32
ffffffffc0204528:	02078793          	addi	a5,a5,32
ffffffffc020452c:	ff1612e3          	bne	a2,a7,ffffffffc0204510 <do_fork+0xa6>
    proc->tf->gpr.a0 = 0;
ffffffffc0204530:	0406b823          	sd	zero,80(a3)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204534:	10098563          	beqz	s3,ffffffffc020463e <do_fork+0x1d4>
    if (++ last_pid >= MAX_PID) {
ffffffffc0204538:	00006797          	auipc	a5,0x6
ffffffffc020453c:	b2078793          	addi	a5,a5,-1248 # ffffffffc020a058 <last_pid.1576>
ffffffffc0204540:	439c                	lw	a5,0(a5)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204542:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204546:	00000717          	auipc	a4,0x0
ffffffffc020454a:	d9e70713          	addi	a4,a4,-610 # ffffffffc02042e4 <forkret>
    if (++ last_pid >= MAX_PID) {
ffffffffc020454e:	0017851b          	addiw	a0,a5,1
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204552:	f818                	sd	a4,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204554:	fc14                	sd	a3,56(s0)
    if (++ last_pid >= MAX_PID) {
ffffffffc0204556:	00006717          	auipc	a4,0x6
ffffffffc020455a:	b0a72123          	sw	a0,-1278(a4) # ffffffffc020a058 <last_pid.1576>
ffffffffc020455e:	6789                	lui	a5,0x2
ffffffffc0204560:	0ef55163          	ble	a5,a0,ffffffffc0204642 <do_fork+0x1d8>
    if (last_pid >= next_safe) {
ffffffffc0204564:	00006797          	auipc	a5,0x6
ffffffffc0204568:	af878793          	addi	a5,a5,-1288 # ffffffffc020a05c <next_safe.1575>
ffffffffc020456c:	439c                	lw	a5,0(a5)
ffffffffc020456e:	00011497          	auipc	s1,0x11
ffffffffc0204572:	08248493          	addi	s1,s1,130 # ffffffffc02155f0 <proc_list>
ffffffffc0204576:	06f54063          	blt	a0,a5,ffffffffc02045d6 <do_fork+0x16c>
        next_safe = MAX_PID;
ffffffffc020457a:	6789                	lui	a5,0x2
ffffffffc020457c:	00006717          	auipc	a4,0x6
ffffffffc0204580:	aef72023          	sw	a5,-1312(a4) # ffffffffc020a05c <next_safe.1575>
ffffffffc0204584:	4581                	li	a1,0
ffffffffc0204586:	87aa                	mv	a5,a0
ffffffffc0204588:	00011497          	auipc	s1,0x11
ffffffffc020458c:	06848493          	addi	s1,s1,104 # ffffffffc02155f0 <proc_list>
    repeat:
ffffffffc0204590:	6889                	lui	a7,0x2
ffffffffc0204592:	882e                	mv	a6,a1
ffffffffc0204594:	6609                	lui	a2,0x2
        le = list;
ffffffffc0204596:	00011697          	auipc	a3,0x11
ffffffffc020459a:	05a68693          	addi	a3,a3,90 # ffffffffc02155f0 <proc_list>
ffffffffc020459e:	6694                	ld	a3,8(a3)
        while ((le = list_next(le)) != list) {
ffffffffc02045a0:	00968f63          	beq	a3,s1,ffffffffc02045be <do_fork+0x154>
            if (proc->pid == last_pid) {
ffffffffc02045a4:	f3c6a703          	lw	a4,-196(a3)
ffffffffc02045a8:	08e78663          	beq	a5,a4,ffffffffc0204634 <do_fork+0x1ca>
            else if (proc->pid > last_pid && next_safe > proc->pid) {
ffffffffc02045ac:	fee7d9e3          	ble	a4,a5,ffffffffc020459e <do_fork+0x134>
ffffffffc02045b0:	fec757e3          	ble	a2,a4,ffffffffc020459e <do_fork+0x134>
ffffffffc02045b4:	6694                	ld	a3,8(a3)
ffffffffc02045b6:	863a                	mv	a2,a4
ffffffffc02045b8:	4805                	li	a6,1
        while ((le = list_next(le)) != list) {
ffffffffc02045ba:	fe9695e3          	bne	a3,s1,ffffffffc02045a4 <do_fork+0x13a>
ffffffffc02045be:	c591                	beqz	a1,ffffffffc02045ca <do_fork+0x160>
ffffffffc02045c0:	00006717          	auipc	a4,0x6
ffffffffc02045c4:	a8f72c23          	sw	a5,-1384(a4) # ffffffffc020a058 <last_pid.1576>
ffffffffc02045c8:	853e                	mv	a0,a5
ffffffffc02045ca:	00080663          	beqz	a6,ffffffffc02045d6 <do_fork+0x16c>
ffffffffc02045ce:	00006797          	auipc	a5,0x6
ffffffffc02045d2:	a8c7a723          	sw	a2,-1394(a5) # ffffffffc020a05c <next_safe.1575>
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02045d6:	45a9                	li	a1,10
    proc->pid = get_pid();
ffffffffc02045d8:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02045da:	2501                	sext.w	a0,a0
ffffffffc02045dc:	47a000ef          	jal	ra,ffffffffc0204a56 <hash32>
ffffffffc02045e0:	1502                	slli	a0,a0,0x20
ffffffffc02045e2:	0000d797          	auipc	a5,0xd
ffffffffc02045e6:	e7e78793          	addi	a5,a5,-386 # ffffffffc0211460 <hash_list>
ffffffffc02045ea:	8171                	srli	a0,a0,0x1c
ffffffffc02045ec:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02045ee:	6518                	ld	a4,8(a0)
ffffffffc02045f0:	0d840793          	addi	a5,s0,216
ffffffffc02045f4:	6494                	ld	a3,8(s1)
    prev->next = next->prev = elm;
ffffffffc02045f6:	e31c                	sd	a5,0(a4)
ffffffffc02045f8:	e51c                	sd	a5,8(a0)
    nr_process ++;
ffffffffc02045fa:	00092783          	lw	a5,0(s2)
    elm->next = next;
ffffffffc02045fe:	f078                	sd	a4,224(s0)
    elm->prev = prev;
ffffffffc0204600:	ec68                	sd	a0,216(s0)
    list_add(&proc_list, &(proc->list_link));  // 插入proc_list
ffffffffc0204602:	0c840713          	addi	a4,s0,200
    prev->next = next->prev = elm;
ffffffffc0204606:	e298                	sd	a4,0(a3)
    nr_process ++;
ffffffffc0204608:	2785                	addiw	a5,a5,1
    elm->next = next;
ffffffffc020460a:	e874                	sd	a3,208(s0)
    wakeup_proc(proc);  // 设置为RUNNABLE
ffffffffc020460c:	8522                	mv	a0,s0
    elm->prev = prev;
ffffffffc020460e:	e464                	sd	s1,200(s0)
    prev->next = next->prev = elm;
ffffffffc0204610:	00011697          	auipc	a3,0x11
ffffffffc0204614:	fee6b423          	sd	a4,-24(a3) # ffffffffc02155f8 <proc_list+0x8>
    nr_process ++;
ffffffffc0204618:	00011717          	auipc	a4,0x11
ffffffffc020461c:	eaf72423          	sw	a5,-344(a4) # ffffffffc02154c0 <nr_process>
    wakeup_proc(proc);  // 设置为RUNNABLE
ffffffffc0204620:	36a000ef          	jal	ra,ffffffffc020498a <wakeup_proc>
    ret=proc->pid;
ffffffffc0204624:	4048                	lw	a0,4(s0)
}
ffffffffc0204626:	70a2                	ld	ra,40(sp)
ffffffffc0204628:	7402                	ld	s0,32(sp)
ffffffffc020462a:	64e2                	ld	s1,24(sp)
ffffffffc020462c:	6942                	ld	s2,16(sp)
ffffffffc020462e:	69a2                	ld	s3,8(sp)
ffffffffc0204630:	6145                	addi	sp,sp,48
ffffffffc0204632:	8082                	ret
                if (++ last_pid >= next_safe) {
ffffffffc0204634:	2785                	addiw	a5,a5,1
ffffffffc0204636:	00c7dd63          	ble	a2,a5,ffffffffc0204650 <do_fork+0x1e6>
ffffffffc020463a:	4585                	li	a1,1
ffffffffc020463c:	b78d                	j	ffffffffc020459e <do_fork+0x134>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020463e:	89b6                	mv	s3,a3
ffffffffc0204640:	bde5                	j	ffffffffc0204538 <do_fork+0xce>
        last_pid = 1;
ffffffffc0204642:	4785                	li	a5,1
ffffffffc0204644:	00006717          	auipc	a4,0x6
ffffffffc0204648:	a0f72a23          	sw	a5,-1516(a4) # ffffffffc020a058 <last_pid.1576>
ffffffffc020464c:	4505                	li	a0,1
ffffffffc020464e:	b735                	j	ffffffffc020457a <do_fork+0x110>
                    if (last_pid >= MAX_PID) {
ffffffffc0204650:	0117c363          	blt	a5,a7,ffffffffc0204656 <do_fork+0x1ec>
                        last_pid = 1;
ffffffffc0204654:	4785                	li	a5,1
                    goto repeat;
ffffffffc0204656:	4585                	li	a1,1
ffffffffc0204658:	bf2d                	j	ffffffffc0204592 <do_fork+0x128>
    kfree(proc);
ffffffffc020465a:	8522                	mv	a0,s0
ffffffffc020465c:	c2cfd0ef          	jal	ra,ffffffffc0201a88 <kfree>
    ret = -E_NO_MEM;
ffffffffc0204660:	5571                	li	a0,-4
    goto fork_out;
ffffffffc0204662:	b7d1                	j	ffffffffc0204626 <do_fork+0x1bc>
    int ret = -E_NO_FREE_PROC;
ffffffffc0204664:	556d                	li	a0,-5
ffffffffc0204666:	b7c1                	j	ffffffffc0204626 <do_fork+0x1bc>
    ret = -E_NO_MEM;
ffffffffc0204668:	5571                	li	a0,-4
ffffffffc020466a:	bf75                	j	ffffffffc0204626 <do_fork+0x1bc>
    assert(current->mm == NULL);
ffffffffc020466c:	00002697          	auipc	a3,0x2
ffffffffc0204670:	4fc68693          	addi	a3,a3,1276 # ffffffffc0206b68 <default_pmm_manager+0xec8>
ffffffffc0204674:	00001617          	auipc	a2,0x1
ffffffffc0204678:	29460613          	addi	a2,a2,660 # ffffffffc0205908 <commands+0x878>
ffffffffc020467c:	11e00593          	li	a1,286
ffffffffc0204680:	00002517          	auipc	a0,0x2
ffffffffc0204684:	50050513          	addi	a0,a0,1280 # ffffffffc0206b80 <default_pmm_manager+0xee0>
ffffffffc0204688:	dc9fb0ef          	jal	ra,ffffffffc0200450 <__panic>
ffffffffc020468c:	00001617          	auipc	a2,0x1
ffffffffc0204690:	66460613          	addi	a2,a2,1636 # ffffffffc0205cf0 <default_pmm_manager+0x50>
ffffffffc0204694:	06900593          	li	a1,105
ffffffffc0204698:	00001517          	auipc	a0,0x1
ffffffffc020469c:	68050513          	addi	a0,a0,1664 # ffffffffc0205d18 <default_pmm_manager+0x78>
ffffffffc02046a0:	db1fb0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc02046a4 <kernel_thread>:
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc02046a4:	7129                	addi	sp,sp,-320
ffffffffc02046a6:	fa22                	sd	s0,304(sp)
ffffffffc02046a8:	f626                	sd	s1,296(sp)
ffffffffc02046aa:	f24a                	sd	s2,288(sp)
ffffffffc02046ac:	84ae                	mv	s1,a1
ffffffffc02046ae:	892a                	mv	s2,a0
ffffffffc02046b0:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02046b2:	4581                	li	a1,0
ffffffffc02046b4:	12000613          	li	a2,288
ffffffffc02046b8:	850a                	mv	a0,sp
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc02046ba:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02046bc:	049000ef          	jal	ra,ffffffffc0204f04 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02046c0:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02046c2:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02046c4:	100027f3          	csrr	a5,sstatus
ffffffffc02046c8:	edd7f793          	andi	a5,a5,-291
ffffffffc02046cc:	1207e793          	ori	a5,a5,288
ffffffffc02046d0:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02046d2:	860a                	mv	a2,sp
ffffffffc02046d4:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02046d8:	00000797          	auipc	a5,0x0
ffffffffc02046dc:	ba078793          	addi	a5,a5,-1120 # ffffffffc0204278 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02046e0:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02046e2:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02046e4:	d87ff0ef          	jal	ra,ffffffffc020446a <do_fork>
}
ffffffffc02046e8:	70f2                	ld	ra,312(sp)
ffffffffc02046ea:	7452                	ld	s0,304(sp)
ffffffffc02046ec:	74b2                	ld	s1,296(sp)
ffffffffc02046ee:	7912                	ld	s2,288(sp)
ffffffffc02046f0:	6131                	addi	sp,sp,320
ffffffffc02046f2:	8082                	ret

ffffffffc02046f4 <do_exit>:
do_exit(int error_code) {
ffffffffc02046f4:	1141                	addi	sp,sp,-16
    panic("process exit!!.\n");
ffffffffc02046f6:	00002617          	auipc	a2,0x2
ffffffffc02046fa:	45a60613          	addi	a2,a2,1114 # ffffffffc0206b50 <default_pmm_manager+0xeb0>
ffffffffc02046fe:	18b00593          	li	a1,395
ffffffffc0204702:	00002517          	auipc	a0,0x2
ffffffffc0204706:	47e50513          	addi	a0,a0,1150 # ffffffffc0206b80 <default_pmm_manager+0xee0>
do_exit(int error_code) {
ffffffffc020470a:	e406                	sd	ra,8(sp)
    panic("process exit!!.\n");
ffffffffc020470c:	d45fb0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc0204710 <proc_init>:
    elm->prev = elm->next = elm;
ffffffffc0204710:	00011797          	auipc	a5,0x11
ffffffffc0204714:	ee078793          	addi	a5,a5,-288 # ffffffffc02155f0 <proc_list>

// proc_init - set up the first kernel thread idleproc "idle" by itself and 
//           - create the second kernel thread init_main
void
proc_init(void) {
ffffffffc0204718:	1101                	addi	sp,sp,-32
ffffffffc020471a:	00011717          	auipc	a4,0x11
ffffffffc020471e:	ecf73f23          	sd	a5,-290(a4) # ffffffffc02155f8 <proc_list+0x8>
ffffffffc0204722:	00011717          	auipc	a4,0x11
ffffffffc0204726:	ecf73723          	sd	a5,-306(a4) # ffffffffc02155f0 <proc_list>
ffffffffc020472a:	ec06                	sd	ra,24(sp)
ffffffffc020472c:	e822                	sd	s0,16(sp)
ffffffffc020472e:	e426                	sd	s1,8(sp)
ffffffffc0204730:	e04a                	sd	s2,0(sp)
ffffffffc0204732:	0000d797          	auipc	a5,0xd
ffffffffc0204736:	d2e78793          	addi	a5,a5,-722 # ffffffffc0211460 <hash_list>
ffffffffc020473a:	00011717          	auipc	a4,0x11
ffffffffc020473e:	d2670713          	addi	a4,a4,-730 # ffffffffc0215460 <name.1566>
ffffffffc0204742:	e79c                	sd	a5,8(a5)
ffffffffc0204744:	e39c                	sd	a5,0(a5)
ffffffffc0204746:	07c1                	addi	a5,a5,16
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
ffffffffc0204748:	fee79de3          	bne	a5,a4,ffffffffc0204742 <proc_init+0x32>
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL) {
ffffffffc020474c:	b35ff0ef          	jal	ra,ffffffffc0204280 <alloc_proc>
ffffffffc0204750:	00011797          	auipc	a5,0x11
ffffffffc0204754:	d6a7b023          	sd	a0,-672(a5) # ffffffffc02154b0 <idleproc>
ffffffffc0204758:	00011417          	auipc	s0,0x11
ffffffffc020475c:	d5840413          	addi	s0,s0,-680 # ffffffffc02154b0 <idleproc>
ffffffffc0204760:	12050a63          	beqz	a0,ffffffffc0204894 <proc_init+0x184>
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    int *context_mem = (int*) kmalloc(sizeof(struct context));
ffffffffc0204764:	07000513          	li	a0,112
ffffffffc0204768:	a64fd0ef          	jal	ra,ffffffffc02019cc <kmalloc>
    memset(context_mem, 0, sizeof(struct context));
ffffffffc020476c:	07000613          	li	a2,112
ffffffffc0204770:	4581                	li	a1,0
    int *context_mem = (int*) kmalloc(sizeof(struct context));
ffffffffc0204772:	84aa                	mv	s1,a0
    memset(context_mem, 0, sizeof(struct context));
ffffffffc0204774:	790000ef          	jal	ra,ffffffffc0204f04 <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
ffffffffc0204778:	6008                	ld	a0,0(s0)
ffffffffc020477a:	85a6                	mv	a1,s1
ffffffffc020477c:	07000613          	li	a2,112
ffffffffc0204780:	03050513          	addi	a0,a0,48
ffffffffc0204784:	7aa000ef          	jal	ra,ffffffffc0204f2e <memcmp>
ffffffffc0204788:	892a                	mv	s2,a0

    int *proc_name_mem = (int*) kmalloc(PROC_NAME_LEN);
ffffffffc020478a:	453d                	li	a0,15
ffffffffc020478c:	a40fd0ef          	jal	ra,ffffffffc02019cc <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc0204790:	463d                	li	a2,15
ffffffffc0204792:	4581                	li	a1,0
    int *proc_name_mem = (int*) kmalloc(PROC_NAME_LEN);
ffffffffc0204794:	84aa                	mv	s1,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc0204796:	76e000ef          	jal	ra,ffffffffc0204f04 <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
ffffffffc020479a:	6008                	ld	a0,0(s0)
ffffffffc020479c:	463d                	li	a2,15
ffffffffc020479e:	85a6                	mv	a1,s1
ffffffffc02047a0:	0b450513          	addi	a0,a0,180
ffffffffc02047a4:	78a000ef          	jal	ra,ffffffffc0204f2e <memcmp>

    if(idleproc->cr3 == boot_cr3 && idleproc->tf == NULL && !context_init_flag
ffffffffc02047a8:	601c                	ld	a5,0(s0)
ffffffffc02047aa:	00011717          	auipc	a4,0x11
ffffffffc02047ae:	d4e70713          	addi	a4,a4,-690 # ffffffffc02154f8 <boot_cr3>
ffffffffc02047b2:	6318                	ld	a4,0(a4)
ffffffffc02047b4:	77d4                	ld	a3,168(a5)
ffffffffc02047b6:	08e68e63          	beq	a3,a4,ffffffffc0204852 <proc_init+0x142>
        cprintf("alloc_proc() correct!\n");

    }
    
    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc02047ba:	4709                	li	a4,2
ffffffffc02047bc:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02047be:	00003717          	auipc	a4,0x3
ffffffffc02047c2:	84270713          	addi	a4,a4,-1982 # ffffffffc0207000 <bootstack>
ffffffffc02047c6:	eb98                	sd	a4,16(a5)
    idleproc->need_resched = 1;
ffffffffc02047c8:	4705                	li	a4,1
ffffffffc02047ca:	cf98                	sw	a4,24(a5)
    set_proc_name(idleproc, "idle");
ffffffffc02047cc:	00002597          	auipc	a1,0x2
ffffffffc02047d0:	45458593          	addi	a1,a1,1108 # ffffffffc0206c20 <default_pmm_manager+0xf80>
ffffffffc02047d4:	853e                	mv	a0,a5
ffffffffc02047d6:	b1fff0ef          	jal	ra,ffffffffc02042f4 <set_proc_name>
    nr_process ++;
ffffffffc02047da:	00011797          	auipc	a5,0x11
ffffffffc02047de:	ce678793          	addi	a5,a5,-794 # ffffffffc02154c0 <nr_process>
ffffffffc02047e2:	439c                	lw	a5,0(a5)

    current = idleproc;
ffffffffc02047e4:	6018                	ld	a4,0(s0)

    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02047e6:	4601                	li	a2,0
    nr_process ++;
ffffffffc02047e8:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02047ea:	00002597          	auipc	a1,0x2
ffffffffc02047ee:	43e58593          	addi	a1,a1,1086 # ffffffffc0206c28 <default_pmm_manager+0xf88>
ffffffffc02047f2:	00000517          	auipc	a0,0x0
ffffffffc02047f6:	b5c50513          	addi	a0,a0,-1188 # ffffffffc020434e <init_main>
    nr_process ++;
ffffffffc02047fa:	00011697          	auipc	a3,0x11
ffffffffc02047fe:	ccf6a323          	sw	a5,-826(a3) # ffffffffc02154c0 <nr_process>
    current = idleproc;
ffffffffc0204802:	00011797          	auipc	a5,0x11
ffffffffc0204806:	cae7b323          	sd	a4,-858(a5) # ffffffffc02154a8 <current>
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc020480a:	e9bff0ef          	jal	ra,ffffffffc02046a4 <kernel_thread>
    if (pid <= 0) {
ffffffffc020480e:	0ca05f63          	blez	a0,ffffffffc02048ec <proc_init+0x1dc>
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204812:	bfdff0ef          	jal	ra,ffffffffc020440e <find_proc>
    set_proc_name(initproc, "init");
ffffffffc0204816:	00002597          	auipc	a1,0x2
ffffffffc020481a:	44258593          	addi	a1,a1,1090 # ffffffffc0206c58 <default_pmm_manager+0xfb8>
    initproc = find_proc(pid);
ffffffffc020481e:	00011797          	auipc	a5,0x11
ffffffffc0204822:	c8a7bd23          	sd	a0,-870(a5) # ffffffffc02154b8 <initproc>
    set_proc_name(initproc, "init");
ffffffffc0204826:	acfff0ef          	jal	ra,ffffffffc02042f4 <set_proc_name>

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc020482a:	601c                	ld	a5,0(s0)
ffffffffc020482c:	c3c5                	beqz	a5,ffffffffc02048cc <proc_init+0x1bc>
ffffffffc020482e:	43dc                	lw	a5,4(a5)
ffffffffc0204830:	efd1                	bnez	a5,ffffffffc02048cc <proc_init+0x1bc>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204832:	00011797          	auipc	a5,0x11
ffffffffc0204836:	c8678793          	addi	a5,a5,-890 # ffffffffc02154b8 <initproc>
ffffffffc020483a:	639c                	ld	a5,0(a5)
ffffffffc020483c:	cba5                	beqz	a5,ffffffffc02048ac <proc_init+0x19c>
ffffffffc020483e:	43d8                	lw	a4,4(a5)
ffffffffc0204840:	4785                	li	a5,1
ffffffffc0204842:	06f71563          	bne	a4,a5,ffffffffc02048ac <proc_init+0x19c>
}
ffffffffc0204846:	60e2                	ld	ra,24(sp)
ffffffffc0204848:	6442                	ld	s0,16(sp)
ffffffffc020484a:	64a2                	ld	s1,8(sp)
ffffffffc020484c:	6902                	ld	s2,0(sp)
ffffffffc020484e:	6105                	addi	sp,sp,32
ffffffffc0204850:	8082                	ret
    if(idleproc->cr3 == boot_cr3 && idleproc->tf == NULL && !context_init_flag
ffffffffc0204852:	73d8                	ld	a4,160(a5)
ffffffffc0204854:	f33d                	bnez	a4,ffffffffc02047ba <proc_init+0xaa>
ffffffffc0204856:	f60912e3          	bnez	s2,ffffffffc02047ba <proc_init+0xaa>
        && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0
ffffffffc020485a:	6394                	ld	a3,0(a5)
ffffffffc020485c:	577d                	li	a4,-1
ffffffffc020485e:	1702                	slli	a4,a4,0x20
ffffffffc0204860:	f4e69de3          	bne	a3,a4,ffffffffc02047ba <proc_init+0xaa>
ffffffffc0204864:	4798                	lw	a4,8(a5)
ffffffffc0204866:	fb31                	bnez	a4,ffffffffc02047ba <proc_init+0xaa>
        && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL
ffffffffc0204868:	6b98                	ld	a4,16(a5)
ffffffffc020486a:	fb21                	bnez	a4,ffffffffc02047ba <proc_init+0xaa>
ffffffffc020486c:	4f98                	lw	a4,24(a5)
ffffffffc020486e:	2701                	sext.w	a4,a4
ffffffffc0204870:	f729                	bnez	a4,ffffffffc02047ba <proc_init+0xaa>
ffffffffc0204872:	7398                	ld	a4,32(a5)
ffffffffc0204874:	f339                	bnez	a4,ffffffffc02047ba <proc_init+0xaa>
        && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag
ffffffffc0204876:	7798                	ld	a4,40(a5)
ffffffffc0204878:	f329                	bnez	a4,ffffffffc02047ba <proc_init+0xaa>
ffffffffc020487a:	0b07a703          	lw	a4,176(a5)
ffffffffc020487e:	8f49                	or	a4,a4,a0
ffffffffc0204880:	2701                	sext.w	a4,a4
ffffffffc0204882:	ff05                	bnez	a4,ffffffffc02047ba <proc_init+0xaa>
        cprintf("alloc_proc() correct!\n");
ffffffffc0204884:	00002517          	auipc	a0,0x2
ffffffffc0204888:	38450513          	addi	a0,a0,900 # ffffffffc0206c08 <default_pmm_manager+0xf68>
ffffffffc020488c:	903fb0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc0204890:	601c                	ld	a5,0(s0)
ffffffffc0204892:	b725                	j	ffffffffc02047ba <proc_init+0xaa>
        panic("cannot alloc idleproc.\n");
ffffffffc0204894:	00002617          	auipc	a2,0x2
ffffffffc0204898:	35c60613          	addi	a2,a2,860 # ffffffffc0206bf0 <default_pmm_manager+0xf50>
ffffffffc020489c:	1a300593          	li	a1,419
ffffffffc02048a0:	00002517          	auipc	a0,0x2
ffffffffc02048a4:	2e050513          	addi	a0,a0,736 # ffffffffc0206b80 <default_pmm_manager+0xee0>
ffffffffc02048a8:	ba9fb0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02048ac:	00002697          	auipc	a3,0x2
ffffffffc02048b0:	3dc68693          	addi	a3,a3,988 # ffffffffc0206c88 <default_pmm_manager+0xfe8>
ffffffffc02048b4:	00001617          	auipc	a2,0x1
ffffffffc02048b8:	05460613          	addi	a2,a2,84 # ffffffffc0205908 <commands+0x878>
ffffffffc02048bc:	1ca00593          	li	a1,458
ffffffffc02048c0:	00002517          	auipc	a0,0x2
ffffffffc02048c4:	2c050513          	addi	a0,a0,704 # ffffffffc0206b80 <default_pmm_manager+0xee0>
ffffffffc02048c8:	b89fb0ef          	jal	ra,ffffffffc0200450 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02048cc:	00002697          	auipc	a3,0x2
ffffffffc02048d0:	39468693          	addi	a3,a3,916 # ffffffffc0206c60 <default_pmm_manager+0xfc0>
ffffffffc02048d4:	00001617          	auipc	a2,0x1
ffffffffc02048d8:	03460613          	addi	a2,a2,52 # ffffffffc0205908 <commands+0x878>
ffffffffc02048dc:	1c900593          	li	a1,457
ffffffffc02048e0:	00002517          	auipc	a0,0x2
ffffffffc02048e4:	2a050513          	addi	a0,a0,672 # ffffffffc0206b80 <default_pmm_manager+0xee0>
ffffffffc02048e8:	b69fb0ef          	jal	ra,ffffffffc0200450 <__panic>
        panic("create init_main failed.\n");
ffffffffc02048ec:	00002617          	auipc	a2,0x2
ffffffffc02048f0:	34c60613          	addi	a2,a2,844 # ffffffffc0206c38 <default_pmm_manager+0xf98>
ffffffffc02048f4:	1c300593          	li	a1,451
ffffffffc02048f8:	00002517          	auipc	a0,0x2
ffffffffc02048fc:	28850513          	addi	a0,a0,648 # ffffffffc0206b80 <default_pmm_manager+0xee0>
ffffffffc0204900:	b51fb0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc0204904 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void
cpu_idle(void) {
ffffffffc0204904:	1141                	addi	sp,sp,-16
ffffffffc0204906:	e022                	sd	s0,0(sp)
ffffffffc0204908:	e406                	sd	ra,8(sp)
ffffffffc020490a:	00011417          	auipc	s0,0x11
ffffffffc020490e:	b9e40413          	addi	s0,s0,-1122 # ffffffffc02154a8 <current>
    while (1) {
        if (current->need_resched) {
ffffffffc0204912:	6018                	ld	a4,0(s0)
ffffffffc0204914:	4f1c                	lw	a5,24(a4)
ffffffffc0204916:	2781                	sext.w	a5,a5
ffffffffc0204918:	dff5                	beqz	a5,ffffffffc0204914 <cpu_idle+0x10>
            schedule();
ffffffffc020491a:	0a2000ef          	jal	ra,ffffffffc02049bc <schedule>
ffffffffc020491e:	bfd5                	j	ffffffffc0204912 <cpu_idle+0xe>

ffffffffc0204920 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0204920:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0204924:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0204928:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc020492a:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc020492c:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0204930:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0204934:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0204938:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc020493c:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0204940:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0204944:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0204948:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc020494c:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0204950:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0204954:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0204958:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc020495c:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc020495e:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0204960:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0204964:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0204968:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc020496c:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0204970:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0204974:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0204978:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc020497c:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0204980:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0204984:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0204988:	8082                	ret

ffffffffc020498a <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc020498a:	411c                	lw	a5,0(a0)
ffffffffc020498c:	4705                	li	a4,1
ffffffffc020498e:	37f9                	addiw	a5,a5,-2
ffffffffc0204990:	00f77563          	bleu	a5,a4,ffffffffc020499a <wakeup_proc+0x10>
    proc->state = PROC_RUNNABLE;
ffffffffc0204994:	4789                	li	a5,2
ffffffffc0204996:	c11c                	sw	a5,0(a0)
ffffffffc0204998:	8082                	ret
wakeup_proc(struct proc_struct *proc) {
ffffffffc020499a:	1141                	addi	sp,sp,-16
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc020499c:	00002697          	auipc	a3,0x2
ffffffffc02049a0:	31468693          	addi	a3,a3,788 # ffffffffc0206cb0 <default_pmm_manager+0x1010>
ffffffffc02049a4:	00001617          	auipc	a2,0x1
ffffffffc02049a8:	f6460613          	addi	a2,a2,-156 # ffffffffc0205908 <commands+0x878>
ffffffffc02049ac:	45a5                	li	a1,9
ffffffffc02049ae:	00002517          	auipc	a0,0x2
ffffffffc02049b2:	34250513          	addi	a0,a0,834 # ffffffffc0206cf0 <default_pmm_manager+0x1050>
wakeup_proc(struct proc_struct *proc) {
ffffffffc02049b6:	e406                	sd	ra,8(sp)
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02049b8:	a99fb0ef          	jal	ra,ffffffffc0200450 <__panic>

ffffffffc02049bc <schedule>:
}

void
schedule(void) {
ffffffffc02049bc:	1141                	addi	sp,sp,-16
ffffffffc02049be:	e406                	sd	ra,8(sp)
ffffffffc02049c0:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02049c2:	100027f3          	csrr	a5,sstatus
ffffffffc02049c6:	8b89                	andi	a5,a5,2
ffffffffc02049c8:	4401                	li	s0,0
ffffffffc02049ca:	e3d1                	bnez	a5,ffffffffc0204a4e <schedule+0x92>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc02049cc:	00011797          	auipc	a5,0x11
ffffffffc02049d0:	adc78793          	addi	a5,a5,-1316 # ffffffffc02154a8 <current>
ffffffffc02049d4:	0007b883          	ld	a7,0(a5)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02049d8:	00011797          	auipc	a5,0x11
ffffffffc02049dc:	ad878793          	addi	a5,a5,-1320 # ffffffffc02154b0 <idleproc>
ffffffffc02049e0:	6388                	ld	a0,0(a5)
        current->need_resched = 0;
ffffffffc02049e2:	0008ac23          	sw	zero,24(a7) # 2018 <BASE_ADDRESS-0xffffffffc01fdfe8>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02049e6:	04a88e63          	beq	a7,a0,ffffffffc0204a42 <schedule+0x86>
ffffffffc02049ea:	0c888693          	addi	a3,a7,200
ffffffffc02049ee:	00011617          	auipc	a2,0x11
ffffffffc02049f2:	c0260613          	addi	a2,a2,-1022 # ffffffffc02155f0 <proc_list>
        le = last;
ffffffffc02049f6:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02049f8:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc02049fa:	4809                	li	a6,2
    return listelm->next;
ffffffffc02049fc:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc02049fe:	00c78863          	beq	a5,a2,ffffffffc0204a0e <schedule+0x52>
                if (next->state == PROC_RUNNABLE) {
ffffffffc0204a02:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0204a06:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc0204a0a:	01070463          	beq	a4,a6,ffffffffc0204a12 <schedule+0x56>
                    break;
                }
            }
        } while (le != last);
ffffffffc0204a0e:	fef697e3          	bne	a3,a5,ffffffffc02049fc <schedule+0x40>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0204a12:	c589                	beqz	a1,ffffffffc0204a1c <schedule+0x60>
ffffffffc0204a14:	4198                	lw	a4,0(a1)
ffffffffc0204a16:	4789                	li	a5,2
ffffffffc0204a18:	00f70e63          	beq	a4,a5,ffffffffc0204a34 <schedule+0x78>
            next = idleproc;
        }
        next->runs ++;
ffffffffc0204a1c:	451c                	lw	a5,8(a0)
ffffffffc0204a1e:	2785                	addiw	a5,a5,1
ffffffffc0204a20:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc0204a22:	00a88463          	beq	a7,a0,ffffffffc0204a2a <schedule+0x6e>
            proc_run(next);
ffffffffc0204a26:	97bff0ef          	jal	ra,ffffffffc02043a0 <proc_run>
    if (flag) {
ffffffffc0204a2a:	e419                	bnez	s0,ffffffffc0204a38 <schedule+0x7c>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0204a2c:	60a2                	ld	ra,8(sp)
ffffffffc0204a2e:	6402                	ld	s0,0(sp)
ffffffffc0204a30:	0141                	addi	sp,sp,16
ffffffffc0204a32:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0204a34:	852e                	mv	a0,a1
ffffffffc0204a36:	b7dd                	j	ffffffffc0204a1c <schedule+0x60>
}
ffffffffc0204a38:	6402                	ld	s0,0(sp)
ffffffffc0204a3a:	60a2                	ld	ra,8(sp)
ffffffffc0204a3c:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0204a3e:	b95fb06f          	j	ffffffffc02005d2 <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0204a42:	00011617          	auipc	a2,0x11
ffffffffc0204a46:	bae60613          	addi	a2,a2,-1106 # ffffffffc02155f0 <proc_list>
ffffffffc0204a4a:	86b2                	mv	a3,a2
ffffffffc0204a4c:	b76d                	j	ffffffffc02049f6 <schedule+0x3a>
        intr_disable();
ffffffffc0204a4e:	b8bfb0ef          	jal	ra,ffffffffc02005d8 <intr_disable>
        return 1;
ffffffffc0204a52:	4405                	li	s0,1
ffffffffc0204a54:	bfa5                	j	ffffffffc02049cc <schedule+0x10>

ffffffffc0204a56 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0204a56:	9e3707b7          	lui	a5,0x9e370
ffffffffc0204a5a:	2785                	addiw	a5,a5,1
ffffffffc0204a5c:	02f5053b          	mulw	a0,a0,a5
    return (hash >> (32 - bits));
ffffffffc0204a60:	02000793          	li	a5,32
ffffffffc0204a64:	40b785bb          	subw	a1,a5,a1
}
ffffffffc0204a68:	00b5553b          	srlw	a0,a0,a1
ffffffffc0204a6c:	8082                	ret

ffffffffc0204a6e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0204a6e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0204a72:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0204a74:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0204a78:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0204a7a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0204a7e:	f022                	sd	s0,32(sp)
ffffffffc0204a80:	ec26                	sd	s1,24(sp)
ffffffffc0204a82:	e84a                	sd	s2,16(sp)
ffffffffc0204a84:	f406                	sd	ra,40(sp)
ffffffffc0204a86:	e44e                	sd	s3,8(sp)
ffffffffc0204a88:	84aa                	mv	s1,a0
ffffffffc0204a8a:	892e                	mv	s2,a1
ffffffffc0204a8c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0204a90:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc0204a92:	03067e63          	bleu	a6,a2,ffffffffc0204ace <printnum+0x60>
ffffffffc0204a96:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0204a98:	00805763          	blez	s0,ffffffffc0204aa6 <printnum+0x38>
ffffffffc0204a9c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0204a9e:	85ca                	mv	a1,s2
ffffffffc0204aa0:	854e                	mv	a0,s3
ffffffffc0204aa2:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0204aa4:	fc65                	bnez	s0,ffffffffc0204a9c <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204aa6:	1a02                	slli	s4,s4,0x20
ffffffffc0204aa8:	020a5a13          	srli	s4,s4,0x20
ffffffffc0204aac:	00002797          	auipc	a5,0x2
ffffffffc0204ab0:	3ec78793          	addi	a5,a5,1004 # ffffffffc0206e98 <error_string+0x38>
ffffffffc0204ab4:	9a3e                	add	s4,s4,a5
}
ffffffffc0204ab6:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204ab8:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0204abc:	70a2                	ld	ra,40(sp)
ffffffffc0204abe:	69a2                	ld	s3,8(sp)
ffffffffc0204ac0:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204ac2:	85ca                	mv	a1,s2
ffffffffc0204ac4:	8326                	mv	t1,s1
}
ffffffffc0204ac6:	6942                	ld	s2,16(sp)
ffffffffc0204ac8:	64e2                	ld	s1,24(sp)
ffffffffc0204aca:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204acc:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0204ace:	03065633          	divu	a2,a2,a6
ffffffffc0204ad2:	8722                	mv	a4,s0
ffffffffc0204ad4:	f9bff0ef          	jal	ra,ffffffffc0204a6e <printnum>
ffffffffc0204ad8:	b7f9                	j	ffffffffc0204aa6 <printnum+0x38>

ffffffffc0204ada <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0204ada:	7119                	addi	sp,sp,-128
ffffffffc0204adc:	f4a6                	sd	s1,104(sp)
ffffffffc0204ade:	f0ca                	sd	s2,96(sp)
ffffffffc0204ae0:	e8d2                	sd	s4,80(sp)
ffffffffc0204ae2:	e4d6                	sd	s5,72(sp)
ffffffffc0204ae4:	e0da                	sd	s6,64(sp)
ffffffffc0204ae6:	fc5e                	sd	s7,56(sp)
ffffffffc0204ae8:	f862                	sd	s8,48(sp)
ffffffffc0204aea:	f06a                	sd	s10,32(sp)
ffffffffc0204aec:	fc86                	sd	ra,120(sp)
ffffffffc0204aee:	f8a2                	sd	s0,112(sp)
ffffffffc0204af0:	ecce                	sd	s3,88(sp)
ffffffffc0204af2:	f466                	sd	s9,40(sp)
ffffffffc0204af4:	ec6e                	sd	s11,24(sp)
ffffffffc0204af6:	892a                	mv	s2,a0
ffffffffc0204af8:	84ae                	mv	s1,a1
ffffffffc0204afa:	8d32                	mv	s10,a2
ffffffffc0204afc:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0204afe:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204b00:	00002a17          	auipc	s4,0x2
ffffffffc0204b04:	208a0a13          	addi	s4,s4,520 # ffffffffc0206d08 <default_pmm_manager+0x1068>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204b08:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204b0c:	00002c17          	auipc	s8,0x2
ffffffffc0204b10:	354c0c13          	addi	s8,s8,852 # ffffffffc0206e60 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204b14:	000d4503          	lbu	a0,0(s10) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
ffffffffc0204b18:	02500793          	li	a5,37
ffffffffc0204b1c:	001d0413          	addi	s0,s10,1
ffffffffc0204b20:	00f50e63          	beq	a0,a5,ffffffffc0204b3c <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc0204b24:	c521                	beqz	a0,ffffffffc0204b6c <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204b26:	02500993          	li	s3,37
ffffffffc0204b2a:	a011                	j	ffffffffc0204b2e <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc0204b2c:	c121                	beqz	a0,ffffffffc0204b6c <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc0204b2e:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204b30:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0204b32:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204b34:	fff44503          	lbu	a0,-1(s0)
ffffffffc0204b38:	ff351ae3          	bne	a0,s3,ffffffffc0204b2c <vprintfmt+0x52>
ffffffffc0204b3c:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0204b40:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0204b44:	4981                	li	s3,0
ffffffffc0204b46:	4801                	li	a6,0
        width = precision = -1;
ffffffffc0204b48:	5cfd                	li	s9,-1
ffffffffc0204b4a:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204b4c:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc0204b50:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204b52:	fdd6069b          	addiw	a3,a2,-35
ffffffffc0204b56:	0ff6f693          	andi	a3,a3,255
ffffffffc0204b5a:	00140d13          	addi	s10,s0,1
ffffffffc0204b5e:	20d5e563          	bltu	a1,a3,ffffffffc0204d68 <vprintfmt+0x28e>
ffffffffc0204b62:	068a                	slli	a3,a3,0x2
ffffffffc0204b64:	96d2                	add	a3,a3,s4
ffffffffc0204b66:	4294                	lw	a3,0(a3)
ffffffffc0204b68:	96d2                	add	a3,a3,s4
ffffffffc0204b6a:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0204b6c:	70e6                	ld	ra,120(sp)
ffffffffc0204b6e:	7446                	ld	s0,112(sp)
ffffffffc0204b70:	74a6                	ld	s1,104(sp)
ffffffffc0204b72:	7906                	ld	s2,96(sp)
ffffffffc0204b74:	69e6                	ld	s3,88(sp)
ffffffffc0204b76:	6a46                	ld	s4,80(sp)
ffffffffc0204b78:	6aa6                	ld	s5,72(sp)
ffffffffc0204b7a:	6b06                	ld	s6,64(sp)
ffffffffc0204b7c:	7be2                	ld	s7,56(sp)
ffffffffc0204b7e:	7c42                	ld	s8,48(sp)
ffffffffc0204b80:	7ca2                	ld	s9,40(sp)
ffffffffc0204b82:	7d02                	ld	s10,32(sp)
ffffffffc0204b84:	6de2                	ld	s11,24(sp)
ffffffffc0204b86:	6109                	addi	sp,sp,128
ffffffffc0204b88:	8082                	ret
    if (lflag >= 2) {
ffffffffc0204b8a:	4705                	li	a4,1
ffffffffc0204b8c:	008a8593          	addi	a1,s5,8
ffffffffc0204b90:	01074463          	blt	a4,a6,ffffffffc0204b98 <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc0204b94:	26080363          	beqz	a6,ffffffffc0204dfa <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc0204b98:	000ab603          	ld	a2,0(s5)
ffffffffc0204b9c:	46c1                	li	a3,16
ffffffffc0204b9e:	8aae                	mv	s5,a1
ffffffffc0204ba0:	a06d                	j	ffffffffc0204c4a <vprintfmt+0x170>
            goto reswitch;
ffffffffc0204ba2:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0204ba6:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204ba8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204baa:	b765                	j	ffffffffc0204b52 <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc0204bac:	000aa503          	lw	a0,0(s5)
ffffffffc0204bb0:	85a6                	mv	a1,s1
ffffffffc0204bb2:	0aa1                	addi	s5,s5,8
ffffffffc0204bb4:	9902                	jalr	s2
            break;
ffffffffc0204bb6:	bfb9                	j	ffffffffc0204b14 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0204bb8:	4705                	li	a4,1
ffffffffc0204bba:	008a8993          	addi	s3,s5,8
ffffffffc0204bbe:	01074463          	blt	a4,a6,ffffffffc0204bc6 <vprintfmt+0xec>
    else if (lflag) {
ffffffffc0204bc2:	22080463          	beqz	a6,ffffffffc0204dea <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc0204bc6:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc0204bca:	24044463          	bltz	s0,ffffffffc0204e12 <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc0204bce:	8622                	mv	a2,s0
ffffffffc0204bd0:	8ace                	mv	s5,s3
ffffffffc0204bd2:	46a9                	li	a3,10
ffffffffc0204bd4:	a89d                	j	ffffffffc0204c4a <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc0204bd6:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204bda:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0204bdc:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc0204bde:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0204be2:	8fb5                	xor	a5,a5,a3
ffffffffc0204be4:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204be8:	1ad74363          	blt	a4,a3,ffffffffc0204d8e <vprintfmt+0x2b4>
ffffffffc0204bec:	00369793          	slli	a5,a3,0x3
ffffffffc0204bf0:	97e2                	add	a5,a5,s8
ffffffffc0204bf2:	639c                	ld	a5,0(a5)
ffffffffc0204bf4:	18078d63          	beqz	a5,ffffffffc0204d8e <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc0204bf8:	86be                	mv	a3,a5
ffffffffc0204bfa:	00000617          	auipc	a2,0x0
ffffffffc0204bfe:	38e60613          	addi	a2,a2,910 # ffffffffc0204f88 <etext+0x2a>
ffffffffc0204c02:	85a6                	mv	a1,s1
ffffffffc0204c04:	854a                	mv	a0,s2
ffffffffc0204c06:	240000ef          	jal	ra,ffffffffc0204e46 <printfmt>
ffffffffc0204c0a:	b729                	j	ffffffffc0204b14 <vprintfmt+0x3a>
            lflag ++;
ffffffffc0204c0c:	00144603          	lbu	a2,1(s0)
ffffffffc0204c10:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204c12:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204c14:	bf3d                	j	ffffffffc0204b52 <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc0204c16:	4705                	li	a4,1
ffffffffc0204c18:	008a8593          	addi	a1,s5,8
ffffffffc0204c1c:	01074463          	blt	a4,a6,ffffffffc0204c24 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0204c20:	1e080263          	beqz	a6,ffffffffc0204e04 <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc0204c24:	000ab603          	ld	a2,0(s5)
ffffffffc0204c28:	46a1                	li	a3,8
ffffffffc0204c2a:	8aae                	mv	s5,a1
ffffffffc0204c2c:	a839                	j	ffffffffc0204c4a <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc0204c2e:	03000513          	li	a0,48
ffffffffc0204c32:	85a6                	mv	a1,s1
ffffffffc0204c34:	e03e                	sd	a5,0(sp)
ffffffffc0204c36:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0204c38:	85a6                	mv	a1,s1
ffffffffc0204c3a:	07800513          	li	a0,120
ffffffffc0204c3e:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0204c40:	0aa1                	addi	s5,s5,8
ffffffffc0204c42:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc0204c46:	6782                	ld	a5,0(sp)
ffffffffc0204c48:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0204c4a:	876e                	mv	a4,s11
ffffffffc0204c4c:	85a6                	mv	a1,s1
ffffffffc0204c4e:	854a                	mv	a0,s2
ffffffffc0204c50:	e1fff0ef          	jal	ra,ffffffffc0204a6e <printnum>
            break;
ffffffffc0204c54:	b5c1                	j	ffffffffc0204b14 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0204c56:	000ab603          	ld	a2,0(s5)
ffffffffc0204c5a:	0aa1                	addi	s5,s5,8
ffffffffc0204c5c:	1c060663          	beqz	a2,ffffffffc0204e28 <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc0204c60:	00160413          	addi	s0,a2,1
ffffffffc0204c64:	17b05c63          	blez	s11,ffffffffc0204ddc <vprintfmt+0x302>
ffffffffc0204c68:	02d00593          	li	a1,45
ffffffffc0204c6c:	14b79263          	bne	a5,a1,ffffffffc0204db0 <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204c70:	00064783          	lbu	a5,0(a2)
ffffffffc0204c74:	0007851b          	sext.w	a0,a5
ffffffffc0204c78:	c905                	beqz	a0,ffffffffc0204ca8 <vprintfmt+0x1ce>
ffffffffc0204c7a:	000cc563          	bltz	s9,ffffffffc0204c84 <vprintfmt+0x1aa>
ffffffffc0204c7e:	3cfd                	addiw	s9,s9,-1
ffffffffc0204c80:	036c8263          	beq	s9,s6,ffffffffc0204ca4 <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc0204c84:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204c86:	18098463          	beqz	s3,ffffffffc0204e0e <vprintfmt+0x334>
ffffffffc0204c8a:	3781                	addiw	a5,a5,-32
ffffffffc0204c8c:	18fbf163          	bleu	a5,s7,ffffffffc0204e0e <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc0204c90:	03f00513          	li	a0,63
ffffffffc0204c94:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204c96:	0405                	addi	s0,s0,1
ffffffffc0204c98:	fff44783          	lbu	a5,-1(s0)
ffffffffc0204c9c:	3dfd                	addiw	s11,s11,-1
ffffffffc0204c9e:	0007851b          	sext.w	a0,a5
ffffffffc0204ca2:	fd61                	bnez	a0,ffffffffc0204c7a <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc0204ca4:	e7b058e3          	blez	s11,ffffffffc0204b14 <vprintfmt+0x3a>
ffffffffc0204ca8:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0204caa:	85a6                	mv	a1,s1
ffffffffc0204cac:	02000513          	li	a0,32
ffffffffc0204cb0:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0204cb2:	e60d81e3          	beqz	s11,ffffffffc0204b14 <vprintfmt+0x3a>
ffffffffc0204cb6:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0204cb8:	85a6                	mv	a1,s1
ffffffffc0204cba:	02000513          	li	a0,32
ffffffffc0204cbe:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0204cc0:	fe0d94e3          	bnez	s11,ffffffffc0204ca8 <vprintfmt+0x1ce>
ffffffffc0204cc4:	bd81                	j	ffffffffc0204b14 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0204cc6:	4705                	li	a4,1
ffffffffc0204cc8:	008a8593          	addi	a1,s5,8
ffffffffc0204ccc:	01074463          	blt	a4,a6,ffffffffc0204cd4 <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc0204cd0:	12080063          	beqz	a6,ffffffffc0204df0 <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc0204cd4:	000ab603          	ld	a2,0(s5)
ffffffffc0204cd8:	46a9                	li	a3,10
ffffffffc0204cda:	8aae                	mv	s5,a1
ffffffffc0204cdc:	b7bd                	j	ffffffffc0204c4a <vprintfmt+0x170>
ffffffffc0204cde:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc0204ce2:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204ce6:	846a                	mv	s0,s10
ffffffffc0204ce8:	b5ad                	j	ffffffffc0204b52 <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc0204cea:	85a6                	mv	a1,s1
ffffffffc0204cec:	02500513          	li	a0,37
ffffffffc0204cf0:	9902                	jalr	s2
            break;
ffffffffc0204cf2:	b50d                	j	ffffffffc0204b14 <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc0204cf4:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc0204cf8:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0204cfc:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204cfe:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc0204d00:	e40dd9e3          	bgez	s11,ffffffffc0204b52 <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc0204d04:	8de6                	mv	s11,s9
ffffffffc0204d06:	5cfd                	li	s9,-1
ffffffffc0204d08:	b5a9                	j	ffffffffc0204b52 <vprintfmt+0x78>
            goto reswitch;
ffffffffc0204d0a:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc0204d0e:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204d12:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204d14:	bd3d                	j	ffffffffc0204b52 <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc0204d16:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc0204d1a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204d1e:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0204d20:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0204d24:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0204d28:	fcd56ce3          	bltu	a0,a3,ffffffffc0204d00 <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc0204d2c:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0204d2e:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc0204d32:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0204d36:	0196873b          	addw	a4,a3,s9
ffffffffc0204d3a:	0017171b          	slliw	a4,a4,0x1
ffffffffc0204d3e:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc0204d42:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc0204d46:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0204d4a:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0204d4e:	fcd57fe3          	bleu	a3,a0,ffffffffc0204d2c <vprintfmt+0x252>
ffffffffc0204d52:	b77d                	j	ffffffffc0204d00 <vprintfmt+0x226>
            if (width < 0)
ffffffffc0204d54:	fffdc693          	not	a3,s11
ffffffffc0204d58:	96fd                	srai	a3,a3,0x3f
ffffffffc0204d5a:	00ddfdb3          	and	s11,s11,a3
ffffffffc0204d5e:	00144603          	lbu	a2,1(s0)
ffffffffc0204d62:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204d64:	846a                	mv	s0,s10
ffffffffc0204d66:	b3f5                	j	ffffffffc0204b52 <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc0204d68:	85a6                	mv	a1,s1
ffffffffc0204d6a:	02500513          	li	a0,37
ffffffffc0204d6e:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0204d70:	fff44703          	lbu	a4,-1(s0)
ffffffffc0204d74:	02500793          	li	a5,37
ffffffffc0204d78:	8d22                	mv	s10,s0
ffffffffc0204d7a:	d8f70de3          	beq	a4,a5,ffffffffc0204b14 <vprintfmt+0x3a>
ffffffffc0204d7e:	02500713          	li	a4,37
ffffffffc0204d82:	1d7d                	addi	s10,s10,-1
ffffffffc0204d84:	fffd4783          	lbu	a5,-1(s10)
ffffffffc0204d88:	fee79de3          	bne	a5,a4,ffffffffc0204d82 <vprintfmt+0x2a8>
ffffffffc0204d8c:	b361                	j	ffffffffc0204b14 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0204d8e:	00002617          	auipc	a2,0x2
ffffffffc0204d92:	1aa60613          	addi	a2,a2,426 # ffffffffc0206f38 <error_string+0xd8>
ffffffffc0204d96:	85a6                	mv	a1,s1
ffffffffc0204d98:	854a                	mv	a0,s2
ffffffffc0204d9a:	0ac000ef          	jal	ra,ffffffffc0204e46 <printfmt>
ffffffffc0204d9e:	bb9d                	j	ffffffffc0204b14 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0204da0:	00002617          	auipc	a2,0x2
ffffffffc0204da4:	19060613          	addi	a2,a2,400 # ffffffffc0206f30 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc0204da8:	00002417          	auipc	s0,0x2
ffffffffc0204dac:	18940413          	addi	s0,s0,393 # ffffffffc0206f31 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204db0:	8532                	mv	a0,a2
ffffffffc0204db2:	85e6                	mv	a1,s9
ffffffffc0204db4:	e032                	sd	a2,0(sp)
ffffffffc0204db6:	e43e                	sd	a5,8(sp)
ffffffffc0204db8:	0cc000ef          	jal	ra,ffffffffc0204e84 <strnlen>
ffffffffc0204dbc:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0204dc0:	6602                	ld	a2,0(sp)
ffffffffc0204dc2:	01b05d63          	blez	s11,ffffffffc0204ddc <vprintfmt+0x302>
ffffffffc0204dc6:	67a2                	ld	a5,8(sp)
ffffffffc0204dc8:	2781                	sext.w	a5,a5
ffffffffc0204dca:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc0204dcc:	6522                	ld	a0,8(sp)
ffffffffc0204dce:	85a6                	mv	a1,s1
ffffffffc0204dd0:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204dd2:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0204dd4:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204dd6:	6602                	ld	a2,0(sp)
ffffffffc0204dd8:	fe0d9ae3          	bnez	s11,ffffffffc0204dcc <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204ddc:	00064783          	lbu	a5,0(a2)
ffffffffc0204de0:	0007851b          	sext.w	a0,a5
ffffffffc0204de4:	e8051be3          	bnez	a0,ffffffffc0204c7a <vprintfmt+0x1a0>
ffffffffc0204de8:	b335                	j	ffffffffc0204b14 <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc0204dea:	000aa403          	lw	s0,0(s5)
ffffffffc0204dee:	bbf1                	j	ffffffffc0204bca <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc0204df0:	000ae603          	lwu	a2,0(s5)
ffffffffc0204df4:	46a9                	li	a3,10
ffffffffc0204df6:	8aae                	mv	s5,a1
ffffffffc0204df8:	bd89                	j	ffffffffc0204c4a <vprintfmt+0x170>
ffffffffc0204dfa:	000ae603          	lwu	a2,0(s5)
ffffffffc0204dfe:	46c1                	li	a3,16
ffffffffc0204e00:	8aae                	mv	s5,a1
ffffffffc0204e02:	b5a1                	j	ffffffffc0204c4a <vprintfmt+0x170>
ffffffffc0204e04:	000ae603          	lwu	a2,0(s5)
ffffffffc0204e08:	46a1                	li	a3,8
ffffffffc0204e0a:	8aae                	mv	s5,a1
ffffffffc0204e0c:	bd3d                	j	ffffffffc0204c4a <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc0204e0e:	9902                	jalr	s2
ffffffffc0204e10:	b559                	j	ffffffffc0204c96 <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc0204e12:	85a6                	mv	a1,s1
ffffffffc0204e14:	02d00513          	li	a0,45
ffffffffc0204e18:	e03e                	sd	a5,0(sp)
ffffffffc0204e1a:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0204e1c:	8ace                	mv	s5,s3
ffffffffc0204e1e:	40800633          	neg	a2,s0
ffffffffc0204e22:	46a9                	li	a3,10
ffffffffc0204e24:	6782                	ld	a5,0(sp)
ffffffffc0204e26:	b515                	j	ffffffffc0204c4a <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc0204e28:	01b05663          	blez	s11,ffffffffc0204e34 <vprintfmt+0x35a>
ffffffffc0204e2c:	02d00693          	li	a3,45
ffffffffc0204e30:	f6d798e3          	bne	a5,a3,ffffffffc0204da0 <vprintfmt+0x2c6>
ffffffffc0204e34:	00002417          	auipc	s0,0x2
ffffffffc0204e38:	0fd40413          	addi	s0,s0,253 # ffffffffc0206f31 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204e3c:	02800513          	li	a0,40
ffffffffc0204e40:	02800793          	li	a5,40
ffffffffc0204e44:	bd1d                	j	ffffffffc0204c7a <vprintfmt+0x1a0>

ffffffffc0204e46 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204e46:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0204e48:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204e4c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204e4e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204e50:	ec06                	sd	ra,24(sp)
ffffffffc0204e52:	f83a                	sd	a4,48(sp)
ffffffffc0204e54:	fc3e                	sd	a5,56(sp)
ffffffffc0204e56:	e0c2                	sd	a6,64(sp)
ffffffffc0204e58:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0204e5a:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204e5c:	c7fff0ef          	jal	ra,ffffffffc0204ada <vprintfmt>
}
ffffffffc0204e60:	60e2                	ld	ra,24(sp)
ffffffffc0204e62:	6161                	addi	sp,sp,80
ffffffffc0204e64:	8082                	ret

ffffffffc0204e66 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0204e66:	00054783          	lbu	a5,0(a0)
ffffffffc0204e6a:	cb91                	beqz	a5,ffffffffc0204e7e <strlen+0x18>
    size_t cnt = 0;
ffffffffc0204e6c:	4781                	li	a5,0
        cnt ++;
ffffffffc0204e6e:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0204e70:	00f50733          	add	a4,a0,a5
ffffffffc0204e74:	00074703          	lbu	a4,0(a4)
ffffffffc0204e78:	fb7d                	bnez	a4,ffffffffc0204e6e <strlen+0x8>
    }
    return cnt;
}
ffffffffc0204e7a:	853e                	mv	a0,a5
ffffffffc0204e7c:	8082                	ret
    size_t cnt = 0;
ffffffffc0204e7e:	4781                	li	a5,0
}
ffffffffc0204e80:	853e                	mv	a0,a5
ffffffffc0204e82:	8082                	ret

ffffffffc0204e84 <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc0204e84:	c185                	beqz	a1,ffffffffc0204ea4 <strnlen+0x20>
ffffffffc0204e86:	00054783          	lbu	a5,0(a0)
ffffffffc0204e8a:	cf89                	beqz	a5,ffffffffc0204ea4 <strnlen+0x20>
    size_t cnt = 0;
ffffffffc0204e8c:	4781                	li	a5,0
ffffffffc0204e8e:	a021                	j	ffffffffc0204e96 <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc0204e90:	00074703          	lbu	a4,0(a4)
ffffffffc0204e94:	c711                	beqz	a4,ffffffffc0204ea0 <strnlen+0x1c>
        cnt ++;
ffffffffc0204e96:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0204e98:	00f50733          	add	a4,a0,a5
ffffffffc0204e9c:	fef59ae3          	bne	a1,a5,ffffffffc0204e90 <strnlen+0xc>
    }
    return cnt;
}
ffffffffc0204ea0:	853e                	mv	a0,a5
ffffffffc0204ea2:	8082                	ret
    size_t cnt = 0;
ffffffffc0204ea4:	4781                	li	a5,0
}
ffffffffc0204ea6:	853e                	mv	a0,a5
ffffffffc0204ea8:	8082                	ret

ffffffffc0204eaa <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0204eaa:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0204eac:	0585                	addi	a1,a1,1
ffffffffc0204eae:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0204eb2:	0785                	addi	a5,a5,1
ffffffffc0204eb4:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0204eb8:	fb75                	bnez	a4,ffffffffc0204eac <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0204eba:	8082                	ret

ffffffffc0204ebc <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204ebc:	00054783          	lbu	a5,0(a0)
ffffffffc0204ec0:	0005c703          	lbu	a4,0(a1)
ffffffffc0204ec4:	cb91                	beqz	a5,ffffffffc0204ed8 <strcmp+0x1c>
ffffffffc0204ec6:	00e79c63          	bne	a5,a4,ffffffffc0204ede <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc0204eca:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204ecc:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc0204ed0:	0585                	addi	a1,a1,1
ffffffffc0204ed2:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204ed6:	fbe5                	bnez	a5,ffffffffc0204ec6 <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204ed8:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0204eda:	9d19                	subw	a0,a0,a4
ffffffffc0204edc:	8082                	ret
ffffffffc0204ede:	0007851b          	sext.w	a0,a5
ffffffffc0204ee2:	9d19                	subw	a0,a0,a4
ffffffffc0204ee4:	8082                	ret

ffffffffc0204ee6 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0204ee6:	00054783          	lbu	a5,0(a0)
ffffffffc0204eea:	cb91                	beqz	a5,ffffffffc0204efe <strchr+0x18>
        if (*s == c) {
ffffffffc0204eec:	00b79563          	bne	a5,a1,ffffffffc0204ef6 <strchr+0x10>
ffffffffc0204ef0:	a809                	j	ffffffffc0204f02 <strchr+0x1c>
ffffffffc0204ef2:	00b78763          	beq	a5,a1,ffffffffc0204f00 <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc0204ef6:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0204ef8:	00054783          	lbu	a5,0(a0)
ffffffffc0204efc:	fbfd                	bnez	a5,ffffffffc0204ef2 <strchr+0xc>
    }
    return NULL;
ffffffffc0204efe:	4501                	li	a0,0
}
ffffffffc0204f00:	8082                	ret
ffffffffc0204f02:	8082                	ret

ffffffffc0204f04 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0204f04:	ca01                	beqz	a2,ffffffffc0204f14 <memset+0x10>
ffffffffc0204f06:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0204f08:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0204f0a:	0785                	addi	a5,a5,1
ffffffffc0204f0c:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0204f10:	fec79de3          	bne	a5,a2,ffffffffc0204f0a <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0204f14:	8082                	ret

ffffffffc0204f16 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0204f16:	ca19                	beqz	a2,ffffffffc0204f2c <memcpy+0x16>
ffffffffc0204f18:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0204f1a:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0204f1c:	0585                	addi	a1,a1,1
ffffffffc0204f1e:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0204f22:	0785                	addi	a5,a5,1
ffffffffc0204f24:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0204f28:	fec59ae3          	bne	a1,a2,ffffffffc0204f1c <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0204f2c:	8082                	ret

ffffffffc0204f2e <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0204f2e:	c21d                	beqz	a2,ffffffffc0204f54 <memcmp+0x26>
        if (*s1 != *s2) {
ffffffffc0204f30:	00054783          	lbu	a5,0(a0)
ffffffffc0204f34:	0005c703          	lbu	a4,0(a1)
ffffffffc0204f38:	962a                	add	a2,a2,a0
ffffffffc0204f3a:	00f70963          	beq	a4,a5,ffffffffc0204f4c <memcmp+0x1e>
ffffffffc0204f3e:	a829                	j	ffffffffc0204f58 <memcmp+0x2a>
ffffffffc0204f40:	00054783          	lbu	a5,0(a0)
ffffffffc0204f44:	0005c703          	lbu	a4,0(a1)
ffffffffc0204f48:	00e79863          	bne	a5,a4,ffffffffc0204f58 <memcmp+0x2a>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0204f4c:	0505                	addi	a0,a0,1
ffffffffc0204f4e:	0585                	addi	a1,a1,1
    while (n -- > 0) {
ffffffffc0204f50:	fea618e3          	bne	a2,a0,ffffffffc0204f40 <memcmp+0x12>
    }
    return 0;
ffffffffc0204f54:	4501                	li	a0,0
}
ffffffffc0204f56:	8082                	ret
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204f58:	40e7853b          	subw	a0,a5,a4
ffffffffc0204f5c:	8082                	ret
