
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00007297          	auipc	t0,0x7
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0207000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00007297          	auipc	t0,0x7
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0207008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02062b7          	lui	t0,0xc0206
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0206137          	lui	sp,0xc0206

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0206337          	lui	t1,0xc0206
    addi t1, t1, %lo(bootstacktop)
ffffffffc0200044:	00030313          	mv	t1,t1
    # 2. 将精确地址一次性地、安全地传给 sp
    mv sp, t1
ffffffffc0200048:	811a                	mv	sp,t1
    # 现在栈指针已经完美设置，可以安全地调用任何C函数了
    # 然后跳转到 kern_init (不再返回)
    lui t0, %hi(kern_init)
ffffffffc020004a:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020004e:	05428293          	addi	t0,t0,84 # ffffffffc0200054 <kern_init>
    jr t0
ffffffffc0200052:	8282                	jr	t0

ffffffffc0200054 <kern_init>:
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    memset(edata, 0, end - edata);
ffffffffc0200054:	00007517          	auipc	a0,0x7
ffffffffc0200058:	fd450513          	addi	a0,a0,-44 # ffffffffc0207028 <free_area>
ffffffffc020005c:	00007617          	auipc	a2,0x7
ffffffffc0200060:	44460613          	addi	a2,a2,1092 # ffffffffc02074a0 <end>
int kern_init(void) {
ffffffffc0200064:	1141                	addi	sp,sp,-16 # ffffffffc0205ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006a:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020006c:	6cf010ef          	jal	ffffffffc0201f3a <memset>
    dtb_init();
ffffffffc0200070:	3c6000ef          	jal	ffffffffc0200436 <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	3b4000ef          	jal	ffffffffc0200428 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	ed850513          	addi	a0,a0,-296 # ffffffffc0201f50 <etext+0x4>
ffffffffc0200080:	08c000ef          	jal	ffffffffc020010c <cputs>

    print_kerninfo();
ffffffffc0200084:	0e4000ef          	jal	ffffffffc0200168 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	700000ef          	jal	ffffffffc0200788 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	744010ef          	jal	ffffffffc02017d0 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	6f8000ef          	jal	ffffffffc0200788 <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200094:	352000ef          	jal	ffffffffc02003e6 <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200098:	6e4000ef          	jal	ffffffffc020077c <intr_enable>

    /* do nothing */
    while (1)
ffffffffc020009c:	a001                	j	ffffffffc020009c <kern_init+0x48>

ffffffffc020009e <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc020009e:	1101                	addi	sp,sp,-32
ffffffffc02000a0:	ec06                	sd	ra,24(sp)
ffffffffc02000a2:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc02000a4:	386000ef          	jal	ffffffffc020042a <cons_putc>
    (*cnt) ++;
ffffffffc02000a8:	65a2                	ld	a1,8(sp)
}
ffffffffc02000aa:	60e2                	ld	ra,24(sp)
    (*cnt) ++;
ffffffffc02000ac:	419c                	lw	a5,0(a1)
ffffffffc02000ae:	2785                	addiw	a5,a5,1
ffffffffc02000b0:	c19c                	sw	a5,0(a1)
}
ffffffffc02000b2:	6105                	addi	sp,sp,32
ffffffffc02000b4:	8082                	ret

ffffffffc02000b6 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000b6:	1101                	addi	sp,sp,-32
ffffffffc02000b8:	862a                	mv	a2,a0
ffffffffc02000ba:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000bc:	00000517          	auipc	a0,0x0
ffffffffc02000c0:	fe250513          	addi	a0,a0,-30 # ffffffffc020009e <cputch>
ffffffffc02000c4:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000c6:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000c8:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000ca:	149010ef          	jal	ffffffffc0201a12 <vprintfmt>
    return cnt;
}
ffffffffc02000ce:	60e2                	ld	ra,24(sp)
ffffffffc02000d0:	4532                	lw	a0,12(sp)
ffffffffc02000d2:	6105                	addi	sp,sp,32
ffffffffc02000d4:	8082                	ret

ffffffffc02000d6 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000d6:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000d8:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc02000dc:	f42e                	sd	a1,40(sp)
ffffffffc02000de:	f832                	sd	a2,48(sp)
ffffffffc02000e0:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e2:	862a                	mv	a2,a0
ffffffffc02000e4:	004c                	addi	a1,sp,4
ffffffffc02000e6:	00000517          	auipc	a0,0x0
ffffffffc02000ea:	fb850513          	addi	a0,a0,-72 # ffffffffc020009e <cputch>
ffffffffc02000ee:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000f0:	ec06                	sd	ra,24(sp)
ffffffffc02000f2:	e0ba                	sd	a4,64(sp)
ffffffffc02000f4:	e4be                	sd	a5,72(sp)
ffffffffc02000f6:	e8c2                	sd	a6,80(sp)
ffffffffc02000f8:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc02000fa:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc02000fc:	e41a                	sd	t1,8(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000fe:	115010ef          	jal	ffffffffc0201a12 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200102:	60e2                	ld	ra,24(sp)
ffffffffc0200104:	4512                	lw	a0,4(sp)
ffffffffc0200106:	6125                	addi	sp,sp,96
ffffffffc0200108:	8082                	ret

ffffffffc020010a <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc020010a:	a605                	j	ffffffffc020042a <cons_putc>

ffffffffc020010c <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020010c:	1101                	addi	sp,sp,-32
ffffffffc020010e:	e822                	sd	s0,16(sp)
ffffffffc0200110:	ec06                	sd	ra,24(sp)
ffffffffc0200112:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200114:	00054503          	lbu	a0,0(a0)
ffffffffc0200118:	c51d                	beqz	a0,ffffffffc0200146 <cputs+0x3a>
ffffffffc020011a:	e426                	sd	s1,8(sp)
ffffffffc020011c:	0405                	addi	s0,s0,1
    int cnt = 0;
ffffffffc020011e:	4481                	li	s1,0
    cons_putc(c);
ffffffffc0200120:	30a000ef          	jal	ffffffffc020042a <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200124:	00044503          	lbu	a0,0(s0)
ffffffffc0200128:	0405                	addi	s0,s0,1
ffffffffc020012a:	87a6                	mv	a5,s1
    (*cnt) ++;
ffffffffc020012c:	2485                	addiw	s1,s1,1
    while ((c = *str ++) != '\0') {
ffffffffc020012e:	f96d                	bnez	a0,ffffffffc0200120 <cputs+0x14>
    cons_putc(c);
ffffffffc0200130:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc0200132:	0027841b          	addiw	s0,a5,2
ffffffffc0200136:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc0200138:	2f2000ef          	jal	ffffffffc020042a <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020013c:	60e2                	ld	ra,24(sp)
ffffffffc020013e:	8522                	mv	a0,s0
ffffffffc0200140:	6442                	ld	s0,16(sp)
ffffffffc0200142:	6105                	addi	sp,sp,32
ffffffffc0200144:	8082                	ret
    cons_putc(c);
ffffffffc0200146:	4529                	li	a0,10
ffffffffc0200148:	2e2000ef          	jal	ffffffffc020042a <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020014c:	4405                	li	s0,1
}
ffffffffc020014e:	60e2                	ld	ra,24(sp)
ffffffffc0200150:	8522                	mv	a0,s0
ffffffffc0200152:	6442                	ld	s0,16(sp)
ffffffffc0200154:	6105                	addi	sp,sp,32
ffffffffc0200156:	8082                	ret

ffffffffc0200158 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200158:	1141                	addi	sp,sp,-16
ffffffffc020015a:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020015c:	2d6000ef          	jal	ffffffffc0200432 <cons_getc>
ffffffffc0200160:	dd75                	beqz	a0,ffffffffc020015c <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200162:	60a2                	ld	ra,8(sp)
ffffffffc0200164:	0141                	addi	sp,sp,16
ffffffffc0200166:	8082                	ret

ffffffffc0200168 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200168:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020016a:	00002517          	auipc	a0,0x2
ffffffffc020016e:	e0650513          	addi	a0,a0,-506 # ffffffffc0201f70 <etext+0x24>
void print_kerninfo(void) {
ffffffffc0200172:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200174:	f63ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc0200178:	00000597          	auipc	a1,0x0
ffffffffc020017c:	edc58593          	addi	a1,a1,-292 # ffffffffc0200054 <kern_init>
ffffffffc0200180:	00002517          	auipc	a0,0x2
ffffffffc0200184:	e1050513          	addi	a0,a0,-496 # ffffffffc0201f90 <etext+0x44>
ffffffffc0200188:	f4fff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020018c:	00002597          	auipc	a1,0x2
ffffffffc0200190:	dc058593          	addi	a1,a1,-576 # ffffffffc0201f4c <etext>
ffffffffc0200194:	00002517          	auipc	a0,0x2
ffffffffc0200198:	e1c50513          	addi	a0,a0,-484 # ffffffffc0201fb0 <etext+0x64>
ffffffffc020019c:	f3bff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001a0:	00007597          	auipc	a1,0x7
ffffffffc02001a4:	e8858593          	addi	a1,a1,-376 # ffffffffc0207028 <free_area>
ffffffffc02001a8:	00002517          	auipc	a0,0x2
ffffffffc02001ac:	e2850513          	addi	a0,a0,-472 # ffffffffc0201fd0 <etext+0x84>
ffffffffc02001b0:	f27ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001b4:	00007597          	auipc	a1,0x7
ffffffffc02001b8:	2ec58593          	addi	a1,a1,748 # ffffffffc02074a0 <end>
ffffffffc02001bc:	00002517          	auipc	a0,0x2
ffffffffc02001c0:	e3450513          	addi	a0,a0,-460 # ffffffffc0201ff0 <etext+0xa4>
ffffffffc02001c4:	f13ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001c8:	00000717          	auipc	a4,0x0
ffffffffc02001cc:	e8c70713          	addi	a4,a4,-372 # ffffffffc0200054 <kern_init>
ffffffffc02001d0:	00007797          	auipc	a5,0x7
ffffffffc02001d4:	6cf78793          	addi	a5,a5,1743 # ffffffffc020789f <end+0x3ff>
ffffffffc02001d8:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001da:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001de:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001e0:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001e4:	95be                	add	a1,a1,a5
ffffffffc02001e6:	85a9                	srai	a1,a1,0xa
ffffffffc02001e8:	00002517          	auipc	a0,0x2
ffffffffc02001ec:	e2850513          	addi	a0,a0,-472 # ffffffffc0202010 <etext+0xc4>
}
ffffffffc02001f0:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001f2:	b5d5                	j	ffffffffc02000d6 <cprintf>

ffffffffc02001f4 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001f4:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02001f6:	00002617          	auipc	a2,0x2
ffffffffc02001fa:	e4a60613          	addi	a2,a2,-438 # ffffffffc0202040 <etext+0xf4>
ffffffffc02001fe:	04d00593          	li	a1,77
ffffffffc0200202:	00002517          	auipc	a0,0x2
ffffffffc0200206:	e5650513          	addi	a0,a0,-426 # ffffffffc0202058 <etext+0x10c>
void print_stackframe(void) {
ffffffffc020020a:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020020c:	17c000ef          	jal	ffffffffc0200388 <__panic>

ffffffffc0200210 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200210:	1101                	addi	sp,sp,-32
ffffffffc0200212:	e822                	sd	s0,16(sp)
ffffffffc0200214:	e426                	sd	s1,8(sp)
ffffffffc0200216:	ec06                	sd	ra,24(sp)
ffffffffc0200218:	00003417          	auipc	s0,0x3
ffffffffc020021c:	bb840413          	addi	s0,s0,-1096 # ffffffffc0202dd0 <commands>
ffffffffc0200220:	00003497          	auipc	s1,0x3
ffffffffc0200224:	bf848493          	addi	s1,s1,-1032 # ffffffffc0202e18 <commands+0x48>
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200228:	6410                	ld	a2,8(s0)
ffffffffc020022a:	600c                	ld	a1,0(s0)
ffffffffc020022c:	00002517          	auipc	a0,0x2
ffffffffc0200230:	e4450513          	addi	a0,a0,-444 # ffffffffc0202070 <etext+0x124>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200234:	0461                	addi	s0,s0,24
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200236:	ea1ff0ef          	jal	ffffffffc02000d6 <cprintf>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020023a:	fe9417e3          	bne	s0,s1,ffffffffc0200228 <mon_help+0x18>
    }
    return 0;
}
ffffffffc020023e:	60e2                	ld	ra,24(sp)
ffffffffc0200240:	6442                	ld	s0,16(sp)
ffffffffc0200242:	64a2                	ld	s1,8(sp)
ffffffffc0200244:	4501                	li	a0,0
ffffffffc0200246:	6105                	addi	sp,sp,32
ffffffffc0200248:	8082                	ret

ffffffffc020024a <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020024a:	1141                	addi	sp,sp,-16
ffffffffc020024c:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020024e:	f1bff0ef          	jal	ffffffffc0200168 <print_kerninfo>
    return 0;
}
ffffffffc0200252:	60a2                	ld	ra,8(sp)
ffffffffc0200254:	4501                	li	a0,0
ffffffffc0200256:	0141                	addi	sp,sp,16
ffffffffc0200258:	8082                	ret

ffffffffc020025a <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020025a:	1141                	addi	sp,sp,-16
ffffffffc020025c:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020025e:	f97ff0ef          	jal	ffffffffc02001f4 <print_stackframe>
    return 0;
}
ffffffffc0200262:	60a2                	ld	ra,8(sp)
ffffffffc0200264:	4501                	li	a0,0
ffffffffc0200266:	0141                	addi	sp,sp,16
ffffffffc0200268:	8082                	ret

ffffffffc020026a <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020026a:	7131                	addi	sp,sp,-192
ffffffffc020026c:	e952                	sd	s4,144(sp)
ffffffffc020026e:	8a2a                	mv	s4,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200270:	00002517          	auipc	a0,0x2
ffffffffc0200274:	e1050513          	addi	a0,a0,-496 # ffffffffc0202080 <etext+0x134>
kmonitor(struct trapframe *tf) {
ffffffffc0200278:	fd06                	sd	ra,184(sp)
ffffffffc020027a:	f922                	sd	s0,176(sp)
ffffffffc020027c:	f526                	sd	s1,168(sp)
ffffffffc020027e:	ed4e                	sd	s3,152(sp)
ffffffffc0200280:	e556                	sd	s5,136(sp)
ffffffffc0200282:	e15a                	sd	s6,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200284:	e53ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200288:	00002517          	auipc	a0,0x2
ffffffffc020028c:	e2050513          	addi	a0,a0,-480 # ffffffffc02020a8 <etext+0x15c>
ffffffffc0200290:	e47ff0ef          	jal	ffffffffc02000d6 <cprintf>
    if (tf != NULL) {
ffffffffc0200294:	000a0563          	beqz	s4,ffffffffc020029e <kmonitor+0x34>
        print_trapframe(tf);
ffffffffc0200298:	8552                	mv	a0,s4
ffffffffc020029a:	6ce000ef          	jal	ffffffffc0200968 <print_trapframe>
ffffffffc020029e:	00003a97          	auipc	s5,0x3
ffffffffc02002a2:	b32a8a93          	addi	s5,s5,-1230 # ffffffffc0202dd0 <commands>
        if (argc == MAXARGS - 1) {
ffffffffc02002a6:	49bd                	li	s3,15
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002a8:	00002517          	auipc	a0,0x2
ffffffffc02002ac:	e2850513          	addi	a0,a0,-472 # ffffffffc02020d0 <etext+0x184>
ffffffffc02002b0:	2c9010ef          	jal	ffffffffc0201d78 <readline>
ffffffffc02002b4:	842a                	mv	s0,a0
ffffffffc02002b6:	d96d                	beqz	a0,ffffffffc02002a8 <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002b8:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002bc:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002be:	e99d                	bnez	a1,ffffffffc02002f4 <kmonitor+0x8a>
    int argc = 0;
ffffffffc02002c0:	8b26                	mv	s6,s1
    if (argc == 0) {
ffffffffc02002c2:	fe0b03e3          	beqz	s6,ffffffffc02002a8 <kmonitor+0x3e>
ffffffffc02002c6:	00003497          	auipc	s1,0x3
ffffffffc02002ca:	b0a48493          	addi	s1,s1,-1270 # ffffffffc0202dd0 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002ce:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002d0:	6582                	ld	a1,0(sp)
ffffffffc02002d2:	6088                	ld	a0,0(s1)
ffffffffc02002d4:	3f9010ef          	jal	ffffffffc0201ecc <strcmp>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002d8:	478d                	li	a5,3
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002da:	c149                	beqz	a0,ffffffffc020035c <kmonitor+0xf2>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002dc:	2405                	addiw	s0,s0,1
ffffffffc02002de:	04e1                	addi	s1,s1,24
ffffffffc02002e0:	fef418e3          	bne	s0,a5,ffffffffc02002d0 <kmonitor+0x66>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02002e4:	6582                	ld	a1,0(sp)
ffffffffc02002e6:	00002517          	auipc	a0,0x2
ffffffffc02002ea:	e1a50513          	addi	a0,a0,-486 # ffffffffc0202100 <etext+0x1b4>
ffffffffc02002ee:	de9ff0ef          	jal	ffffffffc02000d6 <cprintf>
    return 0;
ffffffffc02002f2:	bf5d                	j	ffffffffc02002a8 <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002f4:	00002517          	auipc	a0,0x2
ffffffffc02002f8:	de450513          	addi	a0,a0,-540 # ffffffffc02020d8 <etext+0x18c>
ffffffffc02002fc:	42d010ef          	jal	ffffffffc0201f28 <strchr>
ffffffffc0200300:	c901                	beqz	a0,ffffffffc0200310 <kmonitor+0xa6>
ffffffffc0200302:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200306:	00040023          	sb	zero,0(s0)
ffffffffc020030a:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020030c:	d9d5                	beqz	a1,ffffffffc02002c0 <kmonitor+0x56>
ffffffffc020030e:	b7dd                	j	ffffffffc02002f4 <kmonitor+0x8a>
        if (*buf == '\0') {
ffffffffc0200310:	00044783          	lbu	a5,0(s0)
ffffffffc0200314:	d7d5                	beqz	a5,ffffffffc02002c0 <kmonitor+0x56>
        if (argc == MAXARGS - 1) {
ffffffffc0200316:	03348b63          	beq	s1,s3,ffffffffc020034c <kmonitor+0xe2>
        argv[argc ++] = buf;
ffffffffc020031a:	00349793          	slli	a5,s1,0x3
ffffffffc020031e:	978a                	add	a5,a5,sp
ffffffffc0200320:	e380                	sd	s0,0(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200322:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200326:	2485                	addiw	s1,s1,1
ffffffffc0200328:	8b26                	mv	s6,s1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020032a:	e591                	bnez	a1,ffffffffc0200336 <kmonitor+0xcc>
ffffffffc020032c:	bf59                	j	ffffffffc02002c2 <kmonitor+0x58>
ffffffffc020032e:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200332:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200334:	d5d1                	beqz	a1,ffffffffc02002c0 <kmonitor+0x56>
ffffffffc0200336:	00002517          	auipc	a0,0x2
ffffffffc020033a:	da250513          	addi	a0,a0,-606 # ffffffffc02020d8 <etext+0x18c>
ffffffffc020033e:	3eb010ef          	jal	ffffffffc0201f28 <strchr>
ffffffffc0200342:	d575                	beqz	a0,ffffffffc020032e <kmonitor+0xc4>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200344:	00044583          	lbu	a1,0(s0)
ffffffffc0200348:	dda5                	beqz	a1,ffffffffc02002c0 <kmonitor+0x56>
ffffffffc020034a:	b76d                	j	ffffffffc02002f4 <kmonitor+0x8a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020034c:	45c1                	li	a1,16
ffffffffc020034e:	00002517          	auipc	a0,0x2
ffffffffc0200352:	d9250513          	addi	a0,a0,-622 # ffffffffc02020e0 <etext+0x194>
ffffffffc0200356:	d81ff0ef          	jal	ffffffffc02000d6 <cprintf>
ffffffffc020035a:	b7c1                	j	ffffffffc020031a <kmonitor+0xb0>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020035c:	00141793          	slli	a5,s0,0x1
ffffffffc0200360:	97a2                	add	a5,a5,s0
ffffffffc0200362:	078e                	slli	a5,a5,0x3
ffffffffc0200364:	97d6                	add	a5,a5,s5
ffffffffc0200366:	6b9c                	ld	a5,16(a5)
ffffffffc0200368:	fffb051b          	addiw	a0,s6,-1
ffffffffc020036c:	8652                	mv	a2,s4
ffffffffc020036e:	002c                	addi	a1,sp,8
ffffffffc0200370:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200372:	f2055be3          	bgez	a0,ffffffffc02002a8 <kmonitor+0x3e>
}
ffffffffc0200376:	70ea                	ld	ra,184(sp)
ffffffffc0200378:	744a                	ld	s0,176(sp)
ffffffffc020037a:	74aa                	ld	s1,168(sp)
ffffffffc020037c:	69ea                	ld	s3,152(sp)
ffffffffc020037e:	6a4a                	ld	s4,144(sp)
ffffffffc0200380:	6aaa                	ld	s5,136(sp)
ffffffffc0200382:	6b0a                	ld	s6,128(sp)
ffffffffc0200384:	6129                	addi	sp,sp,192
ffffffffc0200386:	8082                	ret

ffffffffc0200388 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200388:	00007317          	auipc	t1,0x7
ffffffffc020038c:	0b832303          	lw	t1,184(t1) # ffffffffc0207440 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200390:	715d                	addi	sp,sp,-80
ffffffffc0200392:	ec06                	sd	ra,24(sp)
ffffffffc0200394:	f436                	sd	a3,40(sp)
ffffffffc0200396:	f83a                	sd	a4,48(sp)
ffffffffc0200398:	fc3e                	sd	a5,56(sp)
ffffffffc020039a:	e0c2                	sd	a6,64(sp)
ffffffffc020039c:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc020039e:	02031e63          	bnez	t1,ffffffffc02003da <__panic+0x52>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003a2:	4705                	li	a4,1

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003a4:	103c                	addi	a5,sp,40
ffffffffc02003a6:	e822                	sd	s0,16(sp)
ffffffffc02003a8:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003aa:	862e                	mv	a2,a1
ffffffffc02003ac:	85aa                	mv	a1,a0
ffffffffc02003ae:	00002517          	auipc	a0,0x2
ffffffffc02003b2:	dfa50513          	addi	a0,a0,-518 # ffffffffc02021a8 <etext+0x25c>
    is_panic = 1;
ffffffffc02003b6:	00007697          	auipc	a3,0x7
ffffffffc02003ba:	08e6a523          	sw	a4,138(a3) # ffffffffc0207440 <is_panic>
    va_start(ap, fmt);
ffffffffc02003be:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003c0:	d17ff0ef          	jal	ffffffffc02000d6 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003c4:	65a2                	ld	a1,8(sp)
ffffffffc02003c6:	8522                	mv	a0,s0
ffffffffc02003c8:	cefff0ef          	jal	ffffffffc02000b6 <vcprintf>
    cprintf("\n");
ffffffffc02003cc:	00002517          	auipc	a0,0x2
ffffffffc02003d0:	dfc50513          	addi	a0,a0,-516 # ffffffffc02021c8 <etext+0x27c>
ffffffffc02003d4:	d03ff0ef          	jal	ffffffffc02000d6 <cprintf>
ffffffffc02003d8:	6442                	ld	s0,16(sp)
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02003da:	3a8000ef          	jal	ffffffffc0200782 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02003de:	4501                	li	a0,0
ffffffffc02003e0:	e8bff0ef          	jal	ffffffffc020026a <kmonitor>
    while (1) {
ffffffffc02003e4:	bfed                	j	ffffffffc02003de <__panic+0x56>

ffffffffc02003e6 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc02003e6:	1141                	addi	sp,sp,-16
ffffffffc02003e8:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc02003ea:	02000793          	li	a5,32
ffffffffc02003ee:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02003f2:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02003f6:	67e1                	lui	a5,0x18
ffffffffc02003f8:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02003fc:	953e                	add	a0,a0,a5
ffffffffc02003fe:	24b010ef          	jal	ffffffffc0201e48 <sbi_set_timer>
}
ffffffffc0200402:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200404:	00007797          	auipc	a5,0x7
ffffffffc0200408:	0407b223          	sd	zero,68(a5) # ffffffffc0207448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020040c:	00002517          	auipc	a0,0x2
ffffffffc0200410:	dc450513          	addi	a0,a0,-572 # ffffffffc02021d0 <etext+0x284>
}
ffffffffc0200414:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200416:	b1c1                	j	ffffffffc02000d6 <cprintf>

ffffffffc0200418 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200418:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020041c:	67e1                	lui	a5,0x18
ffffffffc020041e:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200422:	953e                	add	a0,a0,a5
ffffffffc0200424:	2250106f          	j	ffffffffc0201e48 <sbi_set_timer>

ffffffffc0200428 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200428:	8082                	ret

ffffffffc020042a <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc020042a:	0ff57513          	zext.b	a0,a0
ffffffffc020042e:	2010106f          	j	ffffffffc0201e2e <sbi_console_putchar>

ffffffffc0200432 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200432:	2310106f          	j	ffffffffc0201e62 <sbi_console_getchar>

ffffffffc0200436 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200436:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc0200438:	00002517          	auipc	a0,0x2
ffffffffc020043c:	db850513          	addi	a0,a0,-584 # ffffffffc02021f0 <etext+0x2a4>
void dtb_init(void) {
ffffffffc0200440:	f406                	sd	ra,40(sp)
ffffffffc0200442:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc0200444:	c93ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200448:	00007597          	auipc	a1,0x7
ffffffffc020044c:	bb85b583          	ld	a1,-1096(a1) # ffffffffc0207000 <boot_hartid>
ffffffffc0200450:	00002517          	auipc	a0,0x2
ffffffffc0200454:	db050513          	addi	a0,a0,-592 # ffffffffc0202200 <etext+0x2b4>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200458:	00007417          	auipc	s0,0x7
ffffffffc020045c:	bb040413          	addi	s0,s0,-1104 # ffffffffc0207008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200460:	c77ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200464:	600c                	ld	a1,0(s0)
ffffffffc0200466:	00002517          	auipc	a0,0x2
ffffffffc020046a:	daa50513          	addi	a0,a0,-598 # ffffffffc0202210 <etext+0x2c4>
ffffffffc020046e:	c69ff0ef          	jal	ffffffffc02000d6 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200472:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200474:	00002517          	auipc	a0,0x2
ffffffffc0200478:	db450513          	addi	a0,a0,-588 # ffffffffc0202228 <etext+0x2dc>
    if (boot_dtb == 0) {
ffffffffc020047c:	10070163          	beqz	a4,ffffffffc020057e <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200480:	57f5                	li	a5,-3
ffffffffc0200482:	07fa                	slli	a5,a5,0x1e
ffffffffc0200484:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200486:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc0200488:	d00e06b7          	lui	a3,0xd00e0
ffffffffc020048c:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfed8a4d>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200490:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200494:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200498:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020049c:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004a0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004a4:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004a6:	8e49                	or	a2,a2,a0
ffffffffc02004a8:	0ff7f793          	zext.b	a5,a5
ffffffffc02004ac:	8dd1                	or	a1,a1,a2
ffffffffc02004ae:	07a2                	slli	a5,a5,0x8
ffffffffc02004b0:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b2:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc02004b6:	0cd59863          	bne	a1,a3,ffffffffc0200586 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02004ba:	4710                	lw	a2,8(a4)
ffffffffc02004bc:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02004be:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c0:	0086541b          	srliw	s0,a2,0x8
ffffffffc02004c4:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c8:	01865e1b          	srliw	t3,a2,0x18
ffffffffc02004cc:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d0:	0186151b          	slliw	a0,a2,0x18
ffffffffc02004d4:	0186959b          	slliw	a1,a3,0x18
ffffffffc02004d8:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004dc:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e0:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e4:	0106d69b          	srliw	a3,a3,0x10
ffffffffc02004e8:	01c56533          	or	a0,a0,t3
ffffffffc02004ec:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f4:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f8:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fc:	0ff6f693          	zext.b	a3,a3
ffffffffc0200500:	8c49                	or	s0,s0,a0
ffffffffc0200502:	0622                	slli	a2,a2,0x8
ffffffffc0200504:	8fcd                	or	a5,a5,a1
ffffffffc0200506:	06a2                	slli	a3,a3,0x8
ffffffffc0200508:	8c51                	or	s0,s0,a2
ffffffffc020050a:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020050c:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020050e:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200510:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200512:	9381                	srli	a5,a5,0x20
ffffffffc0200514:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200516:	4301                	li	t1,0
        switch (token) {
ffffffffc0200518:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020051a:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020051c:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc0200520:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200522:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200524:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200528:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052c:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200530:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200534:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200538:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020053c:	8ed1                	or	a3,a3,a2
ffffffffc020053e:	0ff77713          	zext.b	a4,a4
ffffffffc0200542:	8fd5                	or	a5,a5,a3
ffffffffc0200544:	0722                	slli	a4,a4,0x8
ffffffffc0200546:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc0200548:	05178763          	beq	a5,a7,ffffffffc0200596 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020054c:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc020054e:	00f8e963          	bltu	a7,a5,ffffffffc0200560 <dtb_init+0x12a>
ffffffffc0200552:	07c78d63          	beq	a5,t3,ffffffffc02005cc <dtb_init+0x196>
ffffffffc0200556:	4709                	li	a4,2
ffffffffc0200558:	00e79763          	bne	a5,a4,ffffffffc0200566 <dtb_init+0x130>
ffffffffc020055c:	4301                	li	t1,0
ffffffffc020055e:	b7d1                	j	ffffffffc0200522 <dtb_init+0xec>
ffffffffc0200560:	4711                	li	a4,4
ffffffffc0200562:	fce780e3          	beq	a5,a4,ffffffffc0200522 <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200566:	00002517          	auipc	a0,0x2
ffffffffc020056a:	d8a50513          	addi	a0,a0,-630 # ffffffffc02022f0 <etext+0x3a4>
ffffffffc020056e:	b69ff0ef          	jal	ffffffffc02000d6 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200572:	64e2                	ld	s1,24(sp)
ffffffffc0200574:	6942                	ld	s2,16(sp)
ffffffffc0200576:	00002517          	auipc	a0,0x2
ffffffffc020057a:	db250513          	addi	a0,a0,-590 # ffffffffc0202328 <etext+0x3dc>
}
ffffffffc020057e:	7402                	ld	s0,32(sp)
ffffffffc0200580:	70a2                	ld	ra,40(sp)
ffffffffc0200582:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc0200584:	be89                	j	ffffffffc02000d6 <cprintf>
}
ffffffffc0200586:	7402                	ld	s0,32(sp)
ffffffffc0200588:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020058a:	00002517          	auipc	a0,0x2
ffffffffc020058e:	cbe50513          	addi	a0,a0,-834 # ffffffffc0202248 <etext+0x2fc>
}
ffffffffc0200592:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200594:	b689                	j	ffffffffc02000d6 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200596:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200598:	0087579b          	srliw	a5,a4,0x8
ffffffffc020059c:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005a0:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005a4:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005a8:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ac:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005b0:	8ed1                	or	a3,a3,a2
ffffffffc02005b2:	0ff77713          	zext.b	a4,a4
ffffffffc02005b6:	8fd5                	or	a5,a5,a3
ffffffffc02005b8:	0722                	slli	a4,a4,0x8
ffffffffc02005ba:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02005bc:	04031463          	bnez	t1,ffffffffc0200604 <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02005c0:	1782                	slli	a5,a5,0x20
ffffffffc02005c2:	9381                	srli	a5,a5,0x20
ffffffffc02005c4:	043d                	addi	s0,s0,15
ffffffffc02005c6:	943e                	add	s0,s0,a5
ffffffffc02005c8:	9871                	andi	s0,s0,-4
                break;
ffffffffc02005ca:	bfa1                	j	ffffffffc0200522 <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc02005cc:	8522                	mv	a0,s0
ffffffffc02005ce:	e01a                	sd	t1,0(sp)
ffffffffc02005d0:	0c9010ef          	jal	ffffffffc0201e98 <strlen>
ffffffffc02005d4:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02005d6:	4619                	li	a2,6
ffffffffc02005d8:	8522                	mv	a0,s0
ffffffffc02005da:	00002597          	auipc	a1,0x2
ffffffffc02005de:	c9658593          	addi	a1,a1,-874 # ffffffffc0202270 <etext+0x324>
ffffffffc02005e2:	11f010ef          	jal	ffffffffc0201f00 <strncmp>
ffffffffc02005e6:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02005e8:	0411                	addi	s0,s0,4
ffffffffc02005ea:	0004879b          	sext.w	a5,s1
ffffffffc02005ee:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02005f0:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02005f4:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02005f6:	00a36333          	or	t1,t1,a0
                break;
ffffffffc02005fa:	00ff0837          	lui	a6,0xff0
ffffffffc02005fe:	488d                	li	a7,3
ffffffffc0200600:	4e05                	li	t3,1
ffffffffc0200602:	b705                	j	ffffffffc0200522 <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200604:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200606:	00002597          	auipc	a1,0x2
ffffffffc020060a:	c7258593          	addi	a1,a1,-910 # ffffffffc0202278 <etext+0x32c>
ffffffffc020060e:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200610:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200614:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200618:	0187169b          	slliw	a3,a4,0x18
ffffffffc020061c:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200620:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200624:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200628:	8ed1                	or	a3,a3,a2
ffffffffc020062a:	0ff77713          	zext.b	a4,a4
ffffffffc020062e:	0722                	slli	a4,a4,0x8
ffffffffc0200630:	8d55                	or	a0,a0,a3
ffffffffc0200632:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200634:	1502                	slli	a0,a0,0x20
ffffffffc0200636:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200638:	954a                	add	a0,a0,s2
ffffffffc020063a:	e01a                	sd	t1,0(sp)
ffffffffc020063c:	091010ef          	jal	ffffffffc0201ecc <strcmp>
ffffffffc0200640:	67a2                	ld	a5,8(sp)
ffffffffc0200642:	473d                	li	a4,15
ffffffffc0200644:	6302                	ld	t1,0(sp)
ffffffffc0200646:	00ff0837          	lui	a6,0xff0
ffffffffc020064a:	488d                	li	a7,3
ffffffffc020064c:	4e05                	li	t3,1
ffffffffc020064e:	f6f779e3          	bgeu	a4,a5,ffffffffc02005c0 <dtb_init+0x18a>
ffffffffc0200652:	f53d                	bnez	a0,ffffffffc02005c0 <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200654:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200658:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020065c:	00002517          	auipc	a0,0x2
ffffffffc0200660:	c2450513          	addi	a0,a0,-988 # ffffffffc0202280 <etext+0x334>
           fdt32_to_cpu(x >> 32);
ffffffffc0200664:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200668:	0087d31b          	srliw	t1,a5,0x8
ffffffffc020066c:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200670:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200674:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200678:	0187959b          	slliw	a1,a5,0x18
ffffffffc020067c:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200680:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200684:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200688:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020068c:	01037333          	and	t1,t1,a6
ffffffffc0200690:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200694:	01e5e5b3          	or	a1,a1,t5
ffffffffc0200698:	0ff7f793          	zext.b	a5,a5
ffffffffc020069c:	01de6e33          	or	t3,t3,t4
ffffffffc02006a0:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a4:	01067633          	and	a2,a2,a6
ffffffffc02006a8:	0086d31b          	srliw	t1,a3,0x8
ffffffffc02006ac:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b0:	07a2                	slli	a5,a5,0x8
ffffffffc02006b2:	0108d89b          	srliw	a7,a7,0x10
ffffffffc02006b6:	0186df1b          	srliw	t5,a3,0x18
ffffffffc02006ba:	01875e9b          	srliw	t4,a4,0x18
ffffffffc02006be:	8ddd                	or	a1,a1,a5
ffffffffc02006c0:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c4:	0186979b          	slliw	a5,a3,0x18
ffffffffc02006c8:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006cc:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d0:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d4:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d8:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006dc:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006e0:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e4:	08a2                	slli	a7,a7,0x8
ffffffffc02006e6:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ea:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ee:	0ff6f693          	zext.b	a3,a3
ffffffffc02006f2:	01de6833          	or	a6,t3,t4
ffffffffc02006f6:	0ff77713          	zext.b	a4,a4
ffffffffc02006fa:	01166633          	or	a2,a2,a7
ffffffffc02006fe:	0067e7b3          	or	a5,a5,t1
ffffffffc0200702:	06a2                	slli	a3,a3,0x8
ffffffffc0200704:	01046433          	or	s0,s0,a6
ffffffffc0200708:	0722                	slli	a4,a4,0x8
ffffffffc020070a:	8fd5                	or	a5,a5,a3
ffffffffc020070c:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc020070e:	1582                	slli	a1,a1,0x20
ffffffffc0200710:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200712:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200714:	9201                	srli	a2,a2,0x20
ffffffffc0200716:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200718:	1402                	slli	s0,s0,0x20
ffffffffc020071a:	00b7e4b3          	or	s1,a5,a1
ffffffffc020071e:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200720:	9b7ff0ef          	jal	ffffffffc02000d6 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200724:	85a6                	mv	a1,s1
ffffffffc0200726:	00002517          	auipc	a0,0x2
ffffffffc020072a:	b7a50513          	addi	a0,a0,-1158 # ffffffffc02022a0 <etext+0x354>
ffffffffc020072e:	9a9ff0ef          	jal	ffffffffc02000d6 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200732:	01445613          	srli	a2,s0,0x14
ffffffffc0200736:	85a2                	mv	a1,s0
ffffffffc0200738:	00002517          	auipc	a0,0x2
ffffffffc020073c:	b8050513          	addi	a0,a0,-1152 # ffffffffc02022b8 <etext+0x36c>
ffffffffc0200740:	997ff0ef          	jal	ffffffffc02000d6 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200744:	009405b3          	add	a1,s0,s1
ffffffffc0200748:	15fd                	addi	a1,a1,-1
ffffffffc020074a:	00002517          	auipc	a0,0x2
ffffffffc020074e:	b8e50513          	addi	a0,a0,-1138 # ffffffffc02022d8 <etext+0x38c>
ffffffffc0200752:	985ff0ef          	jal	ffffffffc02000d6 <cprintf>
        memory_base = mem_base;
ffffffffc0200756:	00007797          	auipc	a5,0x7
ffffffffc020075a:	d097b123          	sd	s1,-766(a5) # ffffffffc0207458 <memory_base>
        memory_size = mem_size;
ffffffffc020075e:	00007797          	auipc	a5,0x7
ffffffffc0200762:	ce87b923          	sd	s0,-782(a5) # ffffffffc0207450 <memory_size>
ffffffffc0200766:	b531                	j	ffffffffc0200572 <dtb_init+0x13c>

ffffffffc0200768 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200768:	00007517          	auipc	a0,0x7
ffffffffc020076c:	cf053503          	ld	a0,-784(a0) # ffffffffc0207458 <memory_base>
ffffffffc0200770:	8082                	ret

ffffffffc0200772 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc0200772:	00007517          	auipc	a0,0x7
ffffffffc0200776:	cde53503          	ld	a0,-802(a0) # ffffffffc0207450 <memory_size>
ffffffffc020077a:	8082                	ret

ffffffffc020077c <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020077c:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200780:	8082                	ret

ffffffffc0200782 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200782:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200786:	8082                	ret

ffffffffc0200788 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200788:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020078c:	00000797          	auipc	a5,0x0
ffffffffc0200790:	3b878793          	addi	a5,a5,952 # ffffffffc0200b44 <__alltraps>
ffffffffc0200794:	10579073          	csrw	stvec,a5
}
ffffffffc0200798:	8082                	ret

ffffffffc020079a <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020079a:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc020079c:	1141                	addi	sp,sp,-16
ffffffffc020079e:	e022                	sd	s0,0(sp)
ffffffffc02007a0:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02007a2:	00002517          	auipc	a0,0x2
ffffffffc02007a6:	b9e50513          	addi	a0,a0,-1122 # ffffffffc0202340 <etext+0x3f4>
void print_regs(struct pushregs *gpr) {
ffffffffc02007aa:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02007ac:	92bff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02007b0:	640c                	ld	a1,8(s0)
ffffffffc02007b2:	00002517          	auipc	a0,0x2
ffffffffc02007b6:	ba650513          	addi	a0,a0,-1114 # ffffffffc0202358 <etext+0x40c>
ffffffffc02007ba:	91dff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02007be:	680c                	ld	a1,16(s0)
ffffffffc02007c0:	00002517          	auipc	a0,0x2
ffffffffc02007c4:	bb050513          	addi	a0,a0,-1104 # ffffffffc0202370 <etext+0x424>
ffffffffc02007c8:	90fff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02007cc:	6c0c                	ld	a1,24(s0)
ffffffffc02007ce:	00002517          	auipc	a0,0x2
ffffffffc02007d2:	bba50513          	addi	a0,a0,-1094 # ffffffffc0202388 <etext+0x43c>
ffffffffc02007d6:	901ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02007da:	700c                	ld	a1,32(s0)
ffffffffc02007dc:	00002517          	auipc	a0,0x2
ffffffffc02007e0:	bc450513          	addi	a0,a0,-1084 # ffffffffc02023a0 <etext+0x454>
ffffffffc02007e4:	8f3ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02007e8:	740c                	ld	a1,40(s0)
ffffffffc02007ea:	00002517          	auipc	a0,0x2
ffffffffc02007ee:	bce50513          	addi	a0,a0,-1074 # ffffffffc02023b8 <etext+0x46c>
ffffffffc02007f2:	8e5ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02007f6:	780c                	ld	a1,48(s0)
ffffffffc02007f8:	00002517          	auipc	a0,0x2
ffffffffc02007fc:	bd850513          	addi	a0,a0,-1064 # ffffffffc02023d0 <etext+0x484>
ffffffffc0200800:	8d7ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200804:	7c0c                	ld	a1,56(s0)
ffffffffc0200806:	00002517          	auipc	a0,0x2
ffffffffc020080a:	be250513          	addi	a0,a0,-1054 # ffffffffc02023e8 <etext+0x49c>
ffffffffc020080e:	8c9ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200812:	602c                	ld	a1,64(s0)
ffffffffc0200814:	00002517          	auipc	a0,0x2
ffffffffc0200818:	bec50513          	addi	a0,a0,-1044 # ffffffffc0202400 <etext+0x4b4>
ffffffffc020081c:	8bbff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200820:	642c                	ld	a1,72(s0)
ffffffffc0200822:	00002517          	auipc	a0,0x2
ffffffffc0200826:	bf650513          	addi	a0,a0,-1034 # ffffffffc0202418 <etext+0x4cc>
ffffffffc020082a:	8adff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020082e:	682c                	ld	a1,80(s0)
ffffffffc0200830:	00002517          	auipc	a0,0x2
ffffffffc0200834:	c0050513          	addi	a0,a0,-1024 # ffffffffc0202430 <etext+0x4e4>
ffffffffc0200838:	89fff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020083c:	6c2c                	ld	a1,88(s0)
ffffffffc020083e:	00002517          	auipc	a0,0x2
ffffffffc0200842:	c0a50513          	addi	a0,a0,-1014 # ffffffffc0202448 <etext+0x4fc>
ffffffffc0200846:	891ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020084a:	702c                	ld	a1,96(s0)
ffffffffc020084c:	00002517          	auipc	a0,0x2
ffffffffc0200850:	c1450513          	addi	a0,a0,-1004 # ffffffffc0202460 <etext+0x514>
ffffffffc0200854:	883ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200858:	742c                	ld	a1,104(s0)
ffffffffc020085a:	00002517          	auipc	a0,0x2
ffffffffc020085e:	c1e50513          	addi	a0,a0,-994 # ffffffffc0202478 <etext+0x52c>
ffffffffc0200862:	875ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200866:	782c                	ld	a1,112(s0)
ffffffffc0200868:	00002517          	auipc	a0,0x2
ffffffffc020086c:	c2850513          	addi	a0,a0,-984 # ffffffffc0202490 <etext+0x544>
ffffffffc0200870:	867ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200874:	7c2c                	ld	a1,120(s0)
ffffffffc0200876:	00002517          	auipc	a0,0x2
ffffffffc020087a:	c3250513          	addi	a0,a0,-974 # ffffffffc02024a8 <etext+0x55c>
ffffffffc020087e:	859ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200882:	604c                	ld	a1,128(s0)
ffffffffc0200884:	00002517          	auipc	a0,0x2
ffffffffc0200888:	c3c50513          	addi	a0,a0,-964 # ffffffffc02024c0 <etext+0x574>
ffffffffc020088c:	84bff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200890:	644c                	ld	a1,136(s0)
ffffffffc0200892:	00002517          	auipc	a0,0x2
ffffffffc0200896:	c4650513          	addi	a0,a0,-954 # ffffffffc02024d8 <etext+0x58c>
ffffffffc020089a:	83dff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020089e:	684c                	ld	a1,144(s0)
ffffffffc02008a0:	00002517          	auipc	a0,0x2
ffffffffc02008a4:	c5050513          	addi	a0,a0,-944 # ffffffffc02024f0 <etext+0x5a4>
ffffffffc02008a8:	82fff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc02008ac:	6c4c                	ld	a1,152(s0)
ffffffffc02008ae:	00002517          	auipc	a0,0x2
ffffffffc02008b2:	c5a50513          	addi	a0,a0,-934 # ffffffffc0202508 <etext+0x5bc>
ffffffffc02008b6:	821ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc02008ba:	704c                	ld	a1,160(s0)
ffffffffc02008bc:	00002517          	auipc	a0,0x2
ffffffffc02008c0:	c6450513          	addi	a0,a0,-924 # ffffffffc0202520 <etext+0x5d4>
ffffffffc02008c4:	813ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02008c8:	744c                	ld	a1,168(s0)
ffffffffc02008ca:	00002517          	auipc	a0,0x2
ffffffffc02008ce:	c6e50513          	addi	a0,a0,-914 # ffffffffc0202538 <etext+0x5ec>
ffffffffc02008d2:	805ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02008d6:	784c                	ld	a1,176(s0)
ffffffffc02008d8:	00002517          	auipc	a0,0x2
ffffffffc02008dc:	c7850513          	addi	a0,a0,-904 # ffffffffc0202550 <etext+0x604>
ffffffffc02008e0:	ff6ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02008e4:	7c4c                	ld	a1,184(s0)
ffffffffc02008e6:	00002517          	auipc	a0,0x2
ffffffffc02008ea:	c8250513          	addi	a0,a0,-894 # ffffffffc0202568 <etext+0x61c>
ffffffffc02008ee:	fe8ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02008f2:	606c                	ld	a1,192(s0)
ffffffffc02008f4:	00002517          	auipc	a0,0x2
ffffffffc02008f8:	c8c50513          	addi	a0,a0,-884 # ffffffffc0202580 <etext+0x634>
ffffffffc02008fc:	fdaff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200900:	646c                	ld	a1,200(s0)
ffffffffc0200902:	00002517          	auipc	a0,0x2
ffffffffc0200906:	c9650513          	addi	a0,a0,-874 # ffffffffc0202598 <etext+0x64c>
ffffffffc020090a:	fccff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc020090e:	686c                	ld	a1,208(s0)
ffffffffc0200910:	00002517          	auipc	a0,0x2
ffffffffc0200914:	ca050513          	addi	a0,a0,-864 # ffffffffc02025b0 <etext+0x664>
ffffffffc0200918:	fbeff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc020091c:	6c6c                	ld	a1,216(s0)
ffffffffc020091e:	00002517          	auipc	a0,0x2
ffffffffc0200922:	caa50513          	addi	a0,a0,-854 # ffffffffc02025c8 <etext+0x67c>
ffffffffc0200926:	fb0ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc020092a:	706c                	ld	a1,224(s0)
ffffffffc020092c:	00002517          	auipc	a0,0x2
ffffffffc0200930:	cb450513          	addi	a0,a0,-844 # ffffffffc02025e0 <etext+0x694>
ffffffffc0200934:	fa2ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200938:	746c                	ld	a1,232(s0)
ffffffffc020093a:	00002517          	auipc	a0,0x2
ffffffffc020093e:	cbe50513          	addi	a0,a0,-834 # ffffffffc02025f8 <etext+0x6ac>
ffffffffc0200942:	f94ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200946:	786c                	ld	a1,240(s0)
ffffffffc0200948:	00002517          	auipc	a0,0x2
ffffffffc020094c:	cc850513          	addi	a0,a0,-824 # ffffffffc0202610 <etext+0x6c4>
ffffffffc0200950:	f86ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200954:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200956:	6402                	ld	s0,0(sp)
ffffffffc0200958:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020095a:	00002517          	auipc	a0,0x2
ffffffffc020095e:	cce50513          	addi	a0,a0,-818 # ffffffffc0202628 <etext+0x6dc>
}
ffffffffc0200962:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200964:	f72ff06f          	j	ffffffffc02000d6 <cprintf>

ffffffffc0200968 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200968:	1141                	addi	sp,sp,-16
ffffffffc020096a:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020096c:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc020096e:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200970:	00002517          	auipc	a0,0x2
ffffffffc0200974:	cd050513          	addi	a0,a0,-816 # ffffffffc0202640 <etext+0x6f4>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200978:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020097a:	f5cff0ef          	jal	ffffffffc02000d6 <cprintf>
    print_regs(&tf->gpr);
ffffffffc020097e:	8522                	mv	a0,s0
ffffffffc0200980:	e1bff0ef          	jal	ffffffffc020079a <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200984:	10043583          	ld	a1,256(s0)
ffffffffc0200988:	00002517          	auipc	a0,0x2
ffffffffc020098c:	cd050513          	addi	a0,a0,-816 # ffffffffc0202658 <etext+0x70c>
ffffffffc0200990:	f46ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200994:	10843583          	ld	a1,264(s0)
ffffffffc0200998:	00002517          	auipc	a0,0x2
ffffffffc020099c:	cd850513          	addi	a0,a0,-808 # ffffffffc0202670 <etext+0x724>
ffffffffc02009a0:	f36ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc02009a4:	11043583          	ld	a1,272(s0)
ffffffffc02009a8:	00002517          	auipc	a0,0x2
ffffffffc02009ac:	ce050513          	addi	a0,a0,-800 # ffffffffc0202688 <etext+0x73c>
ffffffffc02009b0:	f26ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02009b4:	11843583          	ld	a1,280(s0)
}
ffffffffc02009b8:	6402                	ld	s0,0(sp)
ffffffffc02009ba:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02009bc:	00002517          	auipc	a0,0x2
ffffffffc02009c0:	ce450513          	addi	a0,a0,-796 # ffffffffc02026a0 <etext+0x754>
}
ffffffffc02009c4:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02009c6:	f10ff06f          	j	ffffffffc02000d6 <cprintf>

ffffffffc02009ca <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
ffffffffc02009ca:	11853783          	ld	a5,280(a0)
ffffffffc02009ce:	472d                	li	a4,11
ffffffffc02009d0:	0786                	slli	a5,a5,0x1
ffffffffc02009d2:	8385                	srli	a5,a5,0x1
ffffffffc02009d4:	0af76563          	bltu	a4,a5,ffffffffc0200a7e <interrupt_handler+0xb4>
ffffffffc02009d8:	00002717          	auipc	a4,0x2
ffffffffc02009dc:	44070713          	addi	a4,a4,1088 # ffffffffc0202e18 <commands+0x48>
ffffffffc02009e0:	078a                	slli	a5,a5,0x2
ffffffffc02009e2:	97ba                	add	a5,a5,a4
ffffffffc02009e4:	439c                	lw	a5,0(a5)
ffffffffc02009e6:	97ba                	add	a5,a5,a4
ffffffffc02009e8:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02009ea:	00002517          	auipc	a0,0x2
ffffffffc02009ee:	d2e50513          	addi	a0,a0,-722 # ffffffffc0202718 <etext+0x7cc>
ffffffffc02009f2:	ee4ff06f          	j	ffffffffc02000d6 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02009f6:	00002517          	auipc	a0,0x2
ffffffffc02009fa:	d0250513          	addi	a0,a0,-766 # ffffffffc02026f8 <etext+0x7ac>
ffffffffc02009fe:	ed8ff06f          	j	ffffffffc02000d6 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200a02:	00002517          	auipc	a0,0x2
ffffffffc0200a06:	cb650513          	addi	a0,a0,-842 # ffffffffc02026b8 <etext+0x76c>
ffffffffc0200a0a:	eccff06f          	j	ffffffffc02000d6 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200a0e:	00002517          	auipc	a0,0x2
ffffffffc0200a12:	d2a50513          	addi	a0,a0,-726 # ffffffffc0202738 <etext+0x7ec>
ffffffffc0200a16:	ec0ff06f          	j	ffffffffc02000d6 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200a1a:	1141                	addi	sp,sp,-16
ffffffffc0200a1c:	e406                	sd	ra,8(sp)
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event();
ffffffffc0200a1e:	9fbff0ef          	jal	ffffffffc0200418 <clock_set_next_event>
            
            static int ticks = 0;
            ticks++;
ffffffffc0200a22:	00007697          	auipc	a3,0x7
ffffffffc0200a26:	a426a683          	lw	a3,-1470(a3) # ffffffffc0207464 <ticks.1>
ffffffffc0200a2a:	c28f6737          	lui	a4,0xc28f6
ffffffffc0200a2e:	c297071b          	addiw	a4,a4,-983 # ffffffffc28f5c29 <end+0x26ee789>
ffffffffc0200a32:	2685                	addiw	a3,a3,1
ffffffffc0200a34:	02d7073b          	mulw	a4,a4,a3
ffffffffc0200a38:	051ec7b7          	lui	a5,0x51ec
ffffffffc0200a3c:	8507879b          	addiw	a5,a5,-1968 # 51eb850 <kern_entry-0xffffffffbb0147b0>
ffffffffc0200a40:	00007597          	auipc	a1,0x7
ffffffffc0200a44:	a2d5a223          	sw	a3,-1500(a1) # ffffffffc0207464 <ticks.1>
            
            if (ticks % TICK_NUM == 0) {
ffffffffc0200a48:	028f66b7          	lui	a3,0x28f6
ffffffffc0200a4c:	c2868693          	addi	a3,a3,-984 # 28f5c28 <kern_entry-0xffffffffbd90a3d8>
            ticks++;
ffffffffc0200a50:	9fb9                	addw	a5,a5,a4
ffffffffc0200a52:	0027d71b          	srliw	a4,a5,0x2
ffffffffc0200a56:	01e7979b          	slliw	a5,a5,0x1e
ffffffffc0200a5a:	9fb9                	addw	a5,a5,a4
            if (ticks % TICK_NUM == 0) {
ffffffffc0200a5c:	02f6f263          	bgeu	a3,a5,ffffffffc0200a80 <interrupt_handler+0xb6>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200a60:	60a2                	ld	ra,8(sp)
ffffffffc0200a62:	0141                	addi	sp,sp,16
ffffffffc0200a64:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200a66:	00002517          	auipc	a0,0x2
ffffffffc0200a6a:	cfa50513          	addi	a0,a0,-774 # ffffffffc0202760 <etext+0x814>
ffffffffc0200a6e:	e68ff06f          	j	ffffffffc02000d6 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200a72:	00002517          	auipc	a0,0x2
ffffffffc0200a76:	c6650513          	addi	a0,a0,-922 # ffffffffc02026d8 <etext+0x78c>
ffffffffc0200a7a:	e5cff06f          	j	ffffffffc02000d6 <cprintf>
            print_trapframe(tf);
ffffffffc0200a7e:	b5ed                	j	ffffffffc0200968 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200a80:	06400593          	li	a1,100
ffffffffc0200a84:	00002517          	auipc	a0,0x2
ffffffffc0200a88:	ccc50513          	addi	a0,a0,-820 # ffffffffc0202750 <etext+0x804>
ffffffffc0200a8c:	e4aff0ef          	jal	ffffffffc02000d6 <cprintf>
                num++;
ffffffffc0200a90:	00007797          	auipc	a5,0x7
ffffffffc0200a94:	9d07a783          	lw	a5,-1584(a5) # ffffffffc0207460 <num.0>
                if (num == 10) {
ffffffffc0200a98:	4729                	li	a4,10
                num++;
ffffffffc0200a9a:	2785                	addiw	a5,a5,1
ffffffffc0200a9c:	00007697          	auipc	a3,0x7
ffffffffc0200aa0:	9cf6a223          	sw	a5,-1596(a3) # ffffffffc0207460 <num.0>
                if (num == 10) {
ffffffffc0200aa4:	fae79ee3          	bne	a5,a4,ffffffffc0200a60 <interrupt_handler+0x96>
}
ffffffffc0200aa8:	60a2                	ld	ra,8(sp)
ffffffffc0200aaa:	0141                	addi	sp,sp,16
                    sbi_shutdown();
ffffffffc0200aac:	3d20106f          	j	ffffffffc0201e7e <sbi_shutdown>

ffffffffc0200ab0 <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
ffffffffc0200ab0:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200ab4:	1141                	addi	sp,sp,-16
ffffffffc0200ab6:	e022                	sd	s0,0(sp)
ffffffffc0200ab8:	e406                	sd	ra,8(sp)
    switch (tf->cause) {
ffffffffc0200aba:	470d                	li	a4,3
void exception_handler(struct trapframe *tf) {
ffffffffc0200abc:	842a                	mv	s0,a0
    switch (tf->cause) {
ffffffffc0200abe:	04e78663          	beq	a5,a4,ffffffffc0200b0a <exception_handler+0x5a>
ffffffffc0200ac2:	02f76c63          	bltu	a4,a5,ffffffffc0200afa <exception_handler+0x4a>
ffffffffc0200ac6:	4709                	li	a4,2
ffffffffc0200ac8:	02e79563          	bne	a5,a4,ffffffffc0200af2 <exception_handler+0x42>
             /* LAB3 CHALLENGE3   2314007 :  */
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Exception type: Illegal instruction\n");
ffffffffc0200acc:	00002517          	auipc	a0,0x2
ffffffffc0200ad0:	cb450513          	addi	a0,a0,-844 # ffffffffc0202780 <etext+0x834>
ffffffffc0200ad4:	e02ff0ef          	jal	ffffffffc02000d6 <cprintf>
            cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
ffffffffc0200ad8:	10843583          	ld	a1,264(s0)
ffffffffc0200adc:	00002517          	auipc	a0,0x2
ffffffffc0200ae0:	ccc50513          	addi	a0,a0,-820 # ffffffffc02027a8 <etext+0x85c>
ffffffffc0200ae4:	df2ff0ef          	jal	ffffffffc02000d6 <cprintf>
            tf->epc += 4;
ffffffffc0200ae8:	10843783          	ld	a5,264(s0)
ffffffffc0200aec:	0791                	addi	a5,a5,4
ffffffffc0200aee:	10f43423          	sd	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200af2:	60a2                	ld	ra,8(sp)
ffffffffc0200af4:	6402                	ld	s0,0(sp)
ffffffffc0200af6:	0141                	addi	sp,sp,16
ffffffffc0200af8:	8082                	ret
    switch (tf->cause) {
ffffffffc0200afa:	17f1                	addi	a5,a5,-4
ffffffffc0200afc:	471d                	li	a4,7
ffffffffc0200afe:	fef77ae3          	bgeu	a4,a5,ffffffffc0200af2 <exception_handler+0x42>
}
ffffffffc0200b02:	6402                	ld	s0,0(sp)
ffffffffc0200b04:	60a2                	ld	ra,8(sp)
ffffffffc0200b06:	0141                	addi	sp,sp,16
            print_trapframe(tf);
ffffffffc0200b08:	b585                	j	ffffffffc0200968 <print_trapframe>
            cprintf("Exception type: Breakpoint\n");
ffffffffc0200b0a:	00002517          	auipc	a0,0x2
ffffffffc0200b0e:	cc650513          	addi	a0,a0,-826 # ffffffffc02027d0 <etext+0x884>
ffffffffc0200b12:	dc4ff0ef          	jal	ffffffffc02000d6 <cprintf>
            cprintf("ebreak caught at 0x%08x\n", tf->epc);
ffffffffc0200b16:	10843583          	ld	a1,264(s0)
ffffffffc0200b1a:	00002517          	auipc	a0,0x2
ffffffffc0200b1e:	cd650513          	addi	a0,a0,-810 # ffffffffc02027f0 <etext+0x8a4>
ffffffffc0200b22:	db4ff0ef          	jal	ffffffffc02000d6 <cprintf>
            tf->epc += 2;  // ebreak是压缩指令，长度为2字节
ffffffffc0200b26:	10843783          	ld	a5,264(s0)
}
ffffffffc0200b2a:	60a2                	ld	ra,8(sp)
            tf->epc += 2;  // ebreak是压缩指令，长度为2字节
ffffffffc0200b2c:	0789                	addi	a5,a5,2
ffffffffc0200b2e:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200b32:	6402                	ld	s0,0(sp)
ffffffffc0200b34:	0141                	addi	sp,sp,16
ffffffffc0200b36:	8082                	ret

ffffffffc0200b38 <trap>:

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200b38:	11853783          	ld	a5,280(a0)
ffffffffc0200b3c:	0007c363          	bltz	a5,ffffffffc0200b42 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200b40:	bf85                	j	ffffffffc0200ab0 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200b42:	b561                	j	ffffffffc02009ca <interrupt_handler>

ffffffffc0200b44 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200b44:	14011073          	csrw	sscratch,sp
ffffffffc0200b48:	712d                	addi	sp,sp,-288
ffffffffc0200b4a:	e002                	sd	zero,0(sp)
ffffffffc0200b4c:	e406                	sd	ra,8(sp)
ffffffffc0200b4e:	ec0e                	sd	gp,24(sp)
ffffffffc0200b50:	f012                	sd	tp,32(sp)
ffffffffc0200b52:	f416                	sd	t0,40(sp)
ffffffffc0200b54:	f81a                	sd	t1,48(sp)
ffffffffc0200b56:	fc1e                	sd	t2,56(sp)
ffffffffc0200b58:	e0a2                	sd	s0,64(sp)
ffffffffc0200b5a:	e4a6                	sd	s1,72(sp)
ffffffffc0200b5c:	e8aa                	sd	a0,80(sp)
ffffffffc0200b5e:	ecae                	sd	a1,88(sp)
ffffffffc0200b60:	f0b2                	sd	a2,96(sp)
ffffffffc0200b62:	f4b6                	sd	a3,104(sp)
ffffffffc0200b64:	f8ba                	sd	a4,112(sp)
ffffffffc0200b66:	fcbe                	sd	a5,120(sp)
ffffffffc0200b68:	e142                	sd	a6,128(sp)
ffffffffc0200b6a:	e546                	sd	a7,136(sp)
ffffffffc0200b6c:	e94a                	sd	s2,144(sp)
ffffffffc0200b6e:	ed4e                	sd	s3,152(sp)
ffffffffc0200b70:	f152                	sd	s4,160(sp)
ffffffffc0200b72:	f556                	sd	s5,168(sp)
ffffffffc0200b74:	f95a                	sd	s6,176(sp)
ffffffffc0200b76:	fd5e                	sd	s7,184(sp)
ffffffffc0200b78:	e1e2                	sd	s8,192(sp)
ffffffffc0200b7a:	e5e6                	sd	s9,200(sp)
ffffffffc0200b7c:	e9ea                	sd	s10,208(sp)
ffffffffc0200b7e:	edee                	sd	s11,216(sp)
ffffffffc0200b80:	f1f2                	sd	t3,224(sp)
ffffffffc0200b82:	f5f6                	sd	t4,232(sp)
ffffffffc0200b84:	f9fa                	sd	t5,240(sp)
ffffffffc0200b86:	fdfe                	sd	t6,248(sp)
ffffffffc0200b88:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200b8c:	100024f3          	csrr	s1,sstatus
ffffffffc0200b90:	14102973          	csrr	s2,sepc
ffffffffc0200b94:	143029f3          	csrr	s3,stval
ffffffffc0200b98:	14202a73          	csrr	s4,scause
ffffffffc0200b9c:	e822                	sd	s0,16(sp)
ffffffffc0200b9e:	e226                	sd	s1,256(sp)
ffffffffc0200ba0:	e64a                	sd	s2,264(sp)
ffffffffc0200ba2:	ea4e                	sd	s3,272(sp)
ffffffffc0200ba4:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200ba6:	850a                	mv	a0,sp
    jal trap
ffffffffc0200ba8:	f91ff0ef          	jal	ffffffffc0200b38 <trap>

ffffffffc0200bac <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200bac:	6492                	ld	s1,256(sp)
ffffffffc0200bae:	6932                	ld	s2,264(sp)
ffffffffc0200bb0:	10049073          	csrw	sstatus,s1
ffffffffc0200bb4:	14191073          	csrw	sepc,s2
ffffffffc0200bb8:	60a2                	ld	ra,8(sp)
ffffffffc0200bba:	61e2                	ld	gp,24(sp)
ffffffffc0200bbc:	7202                	ld	tp,32(sp)
ffffffffc0200bbe:	72a2                	ld	t0,40(sp)
ffffffffc0200bc0:	7342                	ld	t1,48(sp)
ffffffffc0200bc2:	73e2                	ld	t2,56(sp)
ffffffffc0200bc4:	6406                	ld	s0,64(sp)
ffffffffc0200bc6:	64a6                	ld	s1,72(sp)
ffffffffc0200bc8:	6546                	ld	a0,80(sp)
ffffffffc0200bca:	65e6                	ld	a1,88(sp)
ffffffffc0200bcc:	7606                	ld	a2,96(sp)
ffffffffc0200bce:	76a6                	ld	a3,104(sp)
ffffffffc0200bd0:	7746                	ld	a4,112(sp)
ffffffffc0200bd2:	77e6                	ld	a5,120(sp)
ffffffffc0200bd4:	680a                	ld	a6,128(sp)
ffffffffc0200bd6:	68aa                	ld	a7,136(sp)
ffffffffc0200bd8:	694a                	ld	s2,144(sp)
ffffffffc0200bda:	69ea                	ld	s3,152(sp)
ffffffffc0200bdc:	7a0a                	ld	s4,160(sp)
ffffffffc0200bde:	7aaa                	ld	s5,168(sp)
ffffffffc0200be0:	7b4a                	ld	s6,176(sp)
ffffffffc0200be2:	7bea                	ld	s7,184(sp)
ffffffffc0200be4:	6c0e                	ld	s8,192(sp)
ffffffffc0200be6:	6cae                	ld	s9,200(sp)
ffffffffc0200be8:	6d4e                	ld	s10,208(sp)
ffffffffc0200bea:	6dee                	ld	s11,216(sp)
ffffffffc0200bec:	7e0e                	ld	t3,224(sp)
ffffffffc0200bee:	7eae                	ld	t4,232(sp)
ffffffffc0200bf0:	7f4e                	ld	t5,240(sp)
ffffffffc0200bf2:	7fee                	ld	t6,248(sp)
ffffffffc0200bf4:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200bf6:	10200073          	sret

ffffffffc0200bfa <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200bfa:	00006797          	auipc	a5,0x6
ffffffffc0200bfe:	42e78793          	addi	a5,a5,1070 # ffffffffc0207028 <free_area>
ffffffffc0200c02:	e79c                	sd	a5,8(a5)
ffffffffc0200c04:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200c06:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200c0a:	8082                	ret

ffffffffc0200c0c <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200c0c:	00006517          	auipc	a0,0x6
ffffffffc0200c10:	42c56503          	lwu	a0,1068(a0) # ffffffffc0207038 <free_area+0x10>
ffffffffc0200c14:	8082                	ret

ffffffffc0200c16 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200c16:	711d                	addi	sp,sp,-96
ffffffffc0200c18:	e0ca                	sd	s2,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200c1a:	00006917          	auipc	s2,0x6
ffffffffc0200c1e:	40e90913          	addi	s2,s2,1038 # ffffffffc0207028 <free_area>
ffffffffc0200c22:	00893783          	ld	a5,8(s2)
ffffffffc0200c26:	ec86                	sd	ra,88(sp)
ffffffffc0200c28:	e8a2                	sd	s0,80(sp)
ffffffffc0200c2a:	e4a6                	sd	s1,72(sp)
ffffffffc0200c2c:	fc4e                	sd	s3,56(sp)
ffffffffc0200c2e:	f852                	sd	s4,48(sp)
ffffffffc0200c30:	f456                	sd	s5,40(sp)
ffffffffc0200c32:	f05a                	sd	s6,32(sp)
ffffffffc0200c34:	ec5e                	sd	s7,24(sp)
ffffffffc0200c36:	e862                	sd	s8,16(sp)
ffffffffc0200c38:	e466                	sd	s9,8(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c3a:	31278b63          	beq	a5,s2,ffffffffc0200f50 <default_check+0x33a>
    int count = 0, total = 0;
ffffffffc0200c3e:	4401                	li	s0,0
ffffffffc0200c40:	4481                	li	s1,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200c42:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200c46:	8b09                	andi	a4,a4,2
ffffffffc0200c48:	30070863          	beqz	a4,ffffffffc0200f58 <default_check+0x342>
        count ++, total += p->property;
ffffffffc0200c4c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200c50:	679c                	ld	a5,8(a5)
ffffffffc0200c52:	2485                	addiw	s1,s1,1
ffffffffc0200c54:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c56:	ff2796e3          	bne	a5,s2,ffffffffc0200c42 <default_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc0200c5a:	89a2                	mv	s3,s0
ffffffffc0200c5c:	33f000ef          	jal	ffffffffc020179a <nr_free_pages>
ffffffffc0200c60:	75351c63          	bne	a0,s3,ffffffffc02013b8 <default_check+0x7a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200c64:	4505                	li	a0,1
ffffffffc0200c66:	2c3000ef          	jal	ffffffffc0201728 <alloc_pages>
ffffffffc0200c6a:	8aaa                	mv	s5,a0
ffffffffc0200c6c:	48050663          	beqz	a0,ffffffffc02010f8 <default_check+0x4e2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c70:	4505                	li	a0,1
ffffffffc0200c72:	2b7000ef          	jal	ffffffffc0201728 <alloc_pages>
ffffffffc0200c76:	89aa                	mv	s3,a0
ffffffffc0200c78:	76050063          	beqz	a0,ffffffffc02013d8 <default_check+0x7c2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200c7c:	4505                	li	a0,1
ffffffffc0200c7e:	2ab000ef          	jal	ffffffffc0201728 <alloc_pages>
ffffffffc0200c82:	8a2a                	mv	s4,a0
ffffffffc0200c84:	4e050a63          	beqz	a0,ffffffffc0201178 <default_check+0x562>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200c88:	40aa87b3          	sub	a5,s5,a0
ffffffffc0200c8c:	40a98733          	sub	a4,s3,a0
ffffffffc0200c90:	0017b793          	seqz	a5,a5
ffffffffc0200c94:	00173713          	seqz	a4,a4
ffffffffc0200c98:	8fd9                	or	a5,a5,a4
ffffffffc0200c9a:	32079f63          	bnez	a5,ffffffffc0200fd8 <default_check+0x3c2>
ffffffffc0200c9e:	333a8d63          	beq	s5,s3,ffffffffc0200fd8 <default_check+0x3c2>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200ca2:	000aa783          	lw	a5,0(s5)
ffffffffc0200ca6:	2c079963          	bnez	a5,ffffffffc0200f78 <default_check+0x362>
ffffffffc0200caa:	0009a783          	lw	a5,0(s3)
ffffffffc0200cae:	2c079563          	bnez	a5,ffffffffc0200f78 <default_check+0x362>
ffffffffc0200cb2:	411c                	lw	a5,0(a0)
ffffffffc0200cb4:	2c079263          	bnez	a5,ffffffffc0200f78 <default_check+0x362>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200cb8:	00006797          	auipc	a5,0x6
ffffffffc0200cbc:	7d87b783          	ld	a5,2008(a5) # ffffffffc0207490 <pages>
ffffffffc0200cc0:	ccccd737          	lui	a4,0xccccd
ffffffffc0200cc4:	ccd70713          	addi	a4,a4,-819 # ffffffffcccccccd <end+0xcac582d>
ffffffffc0200cc8:	02071693          	slli	a3,a4,0x20
ffffffffc0200ccc:	96ba                	add	a3,a3,a4
ffffffffc0200cce:	40fa8733          	sub	a4,s5,a5
ffffffffc0200cd2:	870d                	srai	a4,a4,0x3
ffffffffc0200cd4:	02d70733          	mul	a4,a4,a3
ffffffffc0200cd8:	00002517          	auipc	a0,0x2
ffffffffc0200cdc:	33853503          	ld	a0,824(a0) # ffffffffc0203010 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200ce0:	00006697          	auipc	a3,0x6
ffffffffc0200ce4:	7a86b683          	ld	a3,1960(a3) # ffffffffc0207488 <npage>
ffffffffc0200ce8:	06b2                	slli	a3,a3,0xc
ffffffffc0200cea:	972a                	add	a4,a4,a0

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200cec:	0732                	slli	a4,a4,0xc
ffffffffc0200cee:	2cd77563          	bgeu	a4,a3,ffffffffc0200fb8 <default_check+0x3a2>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200cf2:	ccccd5b7          	lui	a1,0xccccd
ffffffffc0200cf6:	ccd58593          	addi	a1,a1,-819 # ffffffffcccccccd <end+0xcac582d>
ffffffffc0200cfa:	02059613          	slli	a2,a1,0x20
ffffffffc0200cfe:	40f98733          	sub	a4,s3,a5
ffffffffc0200d02:	962e                	add	a2,a2,a1
ffffffffc0200d04:	870d                	srai	a4,a4,0x3
ffffffffc0200d06:	02c70733          	mul	a4,a4,a2
ffffffffc0200d0a:	972a                	add	a4,a4,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d0c:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200d0e:	4ed77563          	bgeu	a4,a3,ffffffffc02011f8 <default_check+0x5e2>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d12:	40fa07b3          	sub	a5,s4,a5
ffffffffc0200d16:	878d                	srai	a5,a5,0x3
ffffffffc0200d18:	02c787b3          	mul	a5,a5,a2
ffffffffc0200d1c:	97aa                	add	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d1e:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200d20:	32d7fc63          	bgeu	a5,a3,ffffffffc0201058 <default_check+0x442>
    assert(alloc_page() == NULL);
ffffffffc0200d24:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200d26:	00093c03          	ld	s8,0(s2)
ffffffffc0200d2a:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200d2e:	00006b17          	auipc	s6,0x6
ffffffffc0200d32:	30ab2b03          	lw	s6,778(s6) # ffffffffc0207038 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc0200d36:	01293023          	sd	s2,0(s2)
ffffffffc0200d3a:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc0200d3e:	00006797          	auipc	a5,0x6
ffffffffc0200d42:	2e07ad23          	sw	zero,762(a5) # ffffffffc0207038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200d46:	1e3000ef          	jal	ffffffffc0201728 <alloc_pages>
ffffffffc0200d4a:	2e051763          	bnez	a0,ffffffffc0201038 <default_check+0x422>
    free_page(p0);
ffffffffc0200d4e:	8556                	mv	a0,s5
ffffffffc0200d50:	4585                	li	a1,1
ffffffffc0200d52:	211000ef          	jal	ffffffffc0201762 <free_pages>
    free_page(p1);
ffffffffc0200d56:	854e                	mv	a0,s3
ffffffffc0200d58:	4585                	li	a1,1
ffffffffc0200d5a:	209000ef          	jal	ffffffffc0201762 <free_pages>
    free_page(p2);
ffffffffc0200d5e:	8552                	mv	a0,s4
ffffffffc0200d60:	4585                	li	a1,1
ffffffffc0200d62:	201000ef          	jal	ffffffffc0201762 <free_pages>
    assert(nr_free == 3);
ffffffffc0200d66:	00006717          	auipc	a4,0x6
ffffffffc0200d6a:	2d272703          	lw	a4,722(a4) # ffffffffc0207038 <free_area+0x10>
ffffffffc0200d6e:	478d                	li	a5,3
ffffffffc0200d70:	2af71463          	bne	a4,a5,ffffffffc0201018 <default_check+0x402>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d74:	4505                	li	a0,1
ffffffffc0200d76:	1b3000ef          	jal	ffffffffc0201728 <alloc_pages>
ffffffffc0200d7a:	89aa                	mv	s3,a0
ffffffffc0200d7c:	26050e63          	beqz	a0,ffffffffc0200ff8 <default_check+0x3e2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d80:	4505                	li	a0,1
ffffffffc0200d82:	1a7000ef          	jal	ffffffffc0201728 <alloc_pages>
ffffffffc0200d86:	8aaa                	mv	s5,a0
ffffffffc0200d88:	3c050863          	beqz	a0,ffffffffc0201158 <default_check+0x542>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d8c:	4505                	li	a0,1
ffffffffc0200d8e:	19b000ef          	jal	ffffffffc0201728 <alloc_pages>
ffffffffc0200d92:	8a2a                	mv	s4,a0
ffffffffc0200d94:	3a050263          	beqz	a0,ffffffffc0201138 <default_check+0x522>
    assert(alloc_page() == NULL);
ffffffffc0200d98:	4505                	li	a0,1
ffffffffc0200d9a:	18f000ef          	jal	ffffffffc0201728 <alloc_pages>
ffffffffc0200d9e:	36051d63          	bnez	a0,ffffffffc0201118 <default_check+0x502>
    free_page(p0);
ffffffffc0200da2:	4585                	li	a1,1
ffffffffc0200da4:	854e                	mv	a0,s3
ffffffffc0200da6:	1bd000ef          	jal	ffffffffc0201762 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200daa:	00893783          	ld	a5,8(s2)
ffffffffc0200dae:	1f278563          	beq	a5,s2,ffffffffc0200f98 <default_check+0x382>
    assert((p = alloc_page()) == p0);
ffffffffc0200db2:	4505                	li	a0,1
ffffffffc0200db4:	175000ef          	jal	ffffffffc0201728 <alloc_pages>
ffffffffc0200db8:	8caa                	mv	s9,a0
ffffffffc0200dba:	30a99f63          	bne	s3,a0,ffffffffc02010d8 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0200dbe:	4505                	li	a0,1
ffffffffc0200dc0:	169000ef          	jal	ffffffffc0201728 <alloc_pages>
ffffffffc0200dc4:	2e051a63          	bnez	a0,ffffffffc02010b8 <default_check+0x4a2>
    assert(nr_free == 0);
ffffffffc0200dc8:	00006797          	auipc	a5,0x6
ffffffffc0200dcc:	2707a783          	lw	a5,624(a5) # ffffffffc0207038 <free_area+0x10>
ffffffffc0200dd0:	2c079463          	bnez	a5,ffffffffc0201098 <default_check+0x482>
    free_page(p);
ffffffffc0200dd4:	8566                	mv	a0,s9
ffffffffc0200dd6:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200dd8:	01893023          	sd	s8,0(s2)
ffffffffc0200ddc:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc0200de0:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc0200de4:	17f000ef          	jal	ffffffffc0201762 <free_pages>
    free_page(p1);
ffffffffc0200de8:	8556                	mv	a0,s5
ffffffffc0200dea:	4585                	li	a1,1
ffffffffc0200dec:	177000ef          	jal	ffffffffc0201762 <free_pages>
    free_page(p2);
ffffffffc0200df0:	8552                	mv	a0,s4
ffffffffc0200df2:	4585                	li	a1,1
ffffffffc0200df4:	16f000ef          	jal	ffffffffc0201762 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200df8:	4515                	li	a0,5
ffffffffc0200dfa:	12f000ef          	jal	ffffffffc0201728 <alloc_pages>
ffffffffc0200dfe:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200e00:	26050c63          	beqz	a0,ffffffffc0201078 <default_check+0x462>
ffffffffc0200e04:	651c                	ld	a5,8(a0)
ffffffffc0200e06:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200e08:	8b85                	andi	a5,a5,1
ffffffffc0200e0a:	54079763          	bnez	a5,ffffffffc0201358 <default_check+0x742>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200e0e:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200e10:	00093b83          	ld	s7,0(s2)
ffffffffc0200e14:	00893b03          	ld	s6,8(s2)
ffffffffc0200e18:	01293023          	sd	s2,0(s2)
ffffffffc0200e1c:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc0200e20:	109000ef          	jal	ffffffffc0201728 <alloc_pages>
ffffffffc0200e24:	50051a63          	bnez	a0,ffffffffc0201338 <default_check+0x722>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200e28:	05098a13          	addi	s4,s3,80
ffffffffc0200e2c:	8552                	mv	a0,s4
ffffffffc0200e2e:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200e30:	00006c17          	auipc	s8,0x6
ffffffffc0200e34:	208c2c03          	lw	s8,520(s8) # ffffffffc0207038 <free_area+0x10>
    nr_free = 0;
ffffffffc0200e38:	00006797          	auipc	a5,0x6
ffffffffc0200e3c:	2007a023          	sw	zero,512(a5) # ffffffffc0207038 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200e40:	123000ef          	jal	ffffffffc0201762 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200e44:	4511                	li	a0,4
ffffffffc0200e46:	0e3000ef          	jal	ffffffffc0201728 <alloc_pages>
ffffffffc0200e4a:	4c051763          	bnez	a0,ffffffffc0201318 <default_check+0x702>
ffffffffc0200e4e:	0589b783          	ld	a5,88(s3)
ffffffffc0200e52:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200e54:	8b85                	andi	a5,a5,1
ffffffffc0200e56:	4a078163          	beqz	a5,ffffffffc02012f8 <default_check+0x6e2>
ffffffffc0200e5a:	0609a503          	lw	a0,96(s3)
ffffffffc0200e5e:	478d                	li	a5,3
ffffffffc0200e60:	48f51c63          	bne	a0,a5,ffffffffc02012f8 <default_check+0x6e2>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200e64:	0c5000ef          	jal	ffffffffc0201728 <alloc_pages>
ffffffffc0200e68:	8aaa                	mv	s5,a0
ffffffffc0200e6a:	46050763          	beqz	a0,ffffffffc02012d8 <default_check+0x6c2>
    assert(alloc_page() == NULL);
ffffffffc0200e6e:	4505                	li	a0,1
ffffffffc0200e70:	0b9000ef          	jal	ffffffffc0201728 <alloc_pages>
ffffffffc0200e74:	44051263          	bnez	a0,ffffffffc02012b8 <default_check+0x6a2>
    assert(p0 + 2 == p1);
ffffffffc0200e78:	435a1063          	bne	s4,s5,ffffffffc0201298 <default_check+0x682>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200e7c:	4585                	li	a1,1
ffffffffc0200e7e:	854e                	mv	a0,s3
ffffffffc0200e80:	0e3000ef          	jal	ffffffffc0201762 <free_pages>
    free_pages(p1, 3);
ffffffffc0200e84:	8552                	mv	a0,s4
ffffffffc0200e86:	458d                	li	a1,3
ffffffffc0200e88:	0db000ef          	jal	ffffffffc0201762 <free_pages>
ffffffffc0200e8c:	0089b783          	ld	a5,8(s3)
ffffffffc0200e90:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200e92:	8b85                	andi	a5,a5,1
ffffffffc0200e94:	3e078263          	beqz	a5,ffffffffc0201278 <default_check+0x662>
ffffffffc0200e98:	0109aa83          	lw	s5,16(s3)
ffffffffc0200e9c:	4785                	li	a5,1
ffffffffc0200e9e:	3cfa9d63          	bne	s5,a5,ffffffffc0201278 <default_check+0x662>
ffffffffc0200ea2:	008a3783          	ld	a5,8(s4)
ffffffffc0200ea6:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200ea8:	8b85                	andi	a5,a5,1
ffffffffc0200eaa:	3a078763          	beqz	a5,ffffffffc0201258 <default_check+0x642>
ffffffffc0200eae:	010a2703          	lw	a4,16(s4)
ffffffffc0200eb2:	478d                	li	a5,3
ffffffffc0200eb4:	3af71263          	bne	a4,a5,ffffffffc0201258 <default_check+0x642>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200eb8:	8556                	mv	a0,s5
ffffffffc0200eba:	06f000ef          	jal	ffffffffc0201728 <alloc_pages>
ffffffffc0200ebe:	36a99d63          	bne	s3,a0,ffffffffc0201238 <default_check+0x622>
    free_page(p0);
ffffffffc0200ec2:	85d6                	mv	a1,s5
ffffffffc0200ec4:	09f000ef          	jal	ffffffffc0201762 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200ec8:	4509                	li	a0,2
ffffffffc0200eca:	05f000ef          	jal	ffffffffc0201728 <alloc_pages>
ffffffffc0200ece:	34aa1563          	bne	s4,a0,ffffffffc0201218 <default_check+0x602>

    free_pages(p0, 2);
ffffffffc0200ed2:	4589                	li	a1,2
ffffffffc0200ed4:	08f000ef          	jal	ffffffffc0201762 <free_pages>
    free_page(p2);
ffffffffc0200ed8:	02898513          	addi	a0,s3,40
ffffffffc0200edc:	85d6                	mv	a1,s5
ffffffffc0200ede:	085000ef          	jal	ffffffffc0201762 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200ee2:	4515                	li	a0,5
ffffffffc0200ee4:	045000ef          	jal	ffffffffc0201728 <alloc_pages>
ffffffffc0200ee8:	89aa                	mv	s3,a0
ffffffffc0200eea:	48050763          	beqz	a0,ffffffffc0201378 <default_check+0x762>
    assert(alloc_page() == NULL);
ffffffffc0200eee:	8556                	mv	a0,s5
ffffffffc0200ef0:	039000ef          	jal	ffffffffc0201728 <alloc_pages>
ffffffffc0200ef4:	2e051263          	bnez	a0,ffffffffc02011d8 <default_check+0x5c2>

    assert(nr_free == 0);
ffffffffc0200ef8:	00006797          	auipc	a5,0x6
ffffffffc0200efc:	1407a783          	lw	a5,320(a5) # ffffffffc0207038 <free_area+0x10>
ffffffffc0200f00:	2a079c63          	bnez	a5,ffffffffc02011b8 <default_check+0x5a2>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200f04:	854e                	mv	a0,s3
ffffffffc0200f06:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc0200f08:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc0200f0c:	01793023          	sd	s7,0(s2)
ffffffffc0200f10:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc0200f14:	04f000ef          	jal	ffffffffc0201762 <free_pages>
    return listelm->next;
ffffffffc0200f18:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f1c:	01278963          	beq	a5,s2,ffffffffc0200f2e <default_check+0x318>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200f20:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200f24:	679c                	ld	a5,8(a5)
ffffffffc0200f26:	34fd                	addiw	s1,s1,-1
ffffffffc0200f28:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f2a:	ff279be3          	bne	a5,s2,ffffffffc0200f20 <default_check+0x30a>
    }
    assert(count == 0);
ffffffffc0200f2e:	26049563          	bnez	s1,ffffffffc0201198 <default_check+0x582>
    assert(total == 0);
ffffffffc0200f32:	46041363          	bnez	s0,ffffffffc0201398 <default_check+0x782>
}
ffffffffc0200f36:	60e6                	ld	ra,88(sp)
ffffffffc0200f38:	6446                	ld	s0,80(sp)
ffffffffc0200f3a:	64a6                	ld	s1,72(sp)
ffffffffc0200f3c:	6906                	ld	s2,64(sp)
ffffffffc0200f3e:	79e2                	ld	s3,56(sp)
ffffffffc0200f40:	7a42                	ld	s4,48(sp)
ffffffffc0200f42:	7aa2                	ld	s5,40(sp)
ffffffffc0200f44:	7b02                	ld	s6,32(sp)
ffffffffc0200f46:	6be2                	ld	s7,24(sp)
ffffffffc0200f48:	6c42                	ld	s8,16(sp)
ffffffffc0200f4a:	6ca2                	ld	s9,8(sp)
ffffffffc0200f4c:	6125                	addi	sp,sp,96
ffffffffc0200f4e:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f50:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200f52:	4401                	li	s0,0
ffffffffc0200f54:	4481                	li	s1,0
ffffffffc0200f56:	b319                	j	ffffffffc0200c5c <default_check+0x46>
        assert(PageProperty(p));
ffffffffc0200f58:	00002697          	auipc	a3,0x2
ffffffffc0200f5c:	8b868693          	addi	a3,a3,-1864 # ffffffffc0202810 <etext+0x8c4>
ffffffffc0200f60:	00002617          	auipc	a2,0x2
ffffffffc0200f64:	8c060613          	addi	a2,a2,-1856 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0200f68:	0f000593          	li	a1,240
ffffffffc0200f6c:	00002517          	auipc	a0,0x2
ffffffffc0200f70:	8cc50513          	addi	a0,a0,-1844 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0200f74:	c14ff0ef          	jal	ffffffffc0200388 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f78:	00002697          	auipc	a3,0x2
ffffffffc0200f7c:	98068693          	addi	a3,a3,-1664 # ffffffffc02028f8 <etext+0x9ac>
ffffffffc0200f80:	00002617          	auipc	a2,0x2
ffffffffc0200f84:	8a060613          	addi	a2,a2,-1888 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0200f88:	0be00593          	li	a1,190
ffffffffc0200f8c:	00002517          	auipc	a0,0x2
ffffffffc0200f90:	8ac50513          	addi	a0,a0,-1876 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0200f94:	bf4ff0ef          	jal	ffffffffc0200388 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200f98:	00002697          	auipc	a3,0x2
ffffffffc0200f9c:	a2868693          	addi	a3,a3,-1496 # ffffffffc02029c0 <etext+0xa74>
ffffffffc0200fa0:	00002617          	auipc	a2,0x2
ffffffffc0200fa4:	88060613          	addi	a2,a2,-1920 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0200fa8:	0d900593          	li	a1,217
ffffffffc0200fac:	00002517          	auipc	a0,0x2
ffffffffc0200fb0:	88c50513          	addi	a0,a0,-1908 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0200fb4:	bd4ff0ef          	jal	ffffffffc0200388 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200fb8:	00002697          	auipc	a3,0x2
ffffffffc0200fbc:	98068693          	addi	a3,a3,-1664 # ffffffffc0202938 <etext+0x9ec>
ffffffffc0200fc0:	00002617          	auipc	a2,0x2
ffffffffc0200fc4:	86060613          	addi	a2,a2,-1952 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0200fc8:	0c000593          	li	a1,192
ffffffffc0200fcc:	00002517          	auipc	a0,0x2
ffffffffc0200fd0:	86c50513          	addi	a0,a0,-1940 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0200fd4:	bb4ff0ef          	jal	ffffffffc0200388 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200fd8:	00002697          	auipc	a3,0x2
ffffffffc0200fdc:	8f868693          	addi	a3,a3,-1800 # ffffffffc02028d0 <etext+0x984>
ffffffffc0200fe0:	00002617          	auipc	a2,0x2
ffffffffc0200fe4:	84060613          	addi	a2,a2,-1984 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0200fe8:	0bd00593          	li	a1,189
ffffffffc0200fec:	00002517          	auipc	a0,0x2
ffffffffc0200ff0:	84c50513          	addi	a0,a0,-1972 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0200ff4:	b94ff0ef          	jal	ffffffffc0200388 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ff8:	00002697          	auipc	a3,0x2
ffffffffc0200ffc:	87868693          	addi	a3,a3,-1928 # ffffffffc0202870 <etext+0x924>
ffffffffc0201000:	00002617          	auipc	a2,0x2
ffffffffc0201004:	82060613          	addi	a2,a2,-2016 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0201008:	0d200593          	li	a1,210
ffffffffc020100c:	00002517          	auipc	a0,0x2
ffffffffc0201010:	82c50513          	addi	a0,a0,-2004 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0201014:	b74ff0ef          	jal	ffffffffc0200388 <__panic>
    assert(nr_free == 3);
ffffffffc0201018:	00002697          	auipc	a3,0x2
ffffffffc020101c:	99868693          	addi	a3,a3,-1640 # ffffffffc02029b0 <etext+0xa64>
ffffffffc0201020:	00002617          	auipc	a2,0x2
ffffffffc0201024:	80060613          	addi	a2,a2,-2048 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0201028:	0d000593          	li	a1,208
ffffffffc020102c:	00002517          	auipc	a0,0x2
ffffffffc0201030:	80c50513          	addi	a0,a0,-2036 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0201034:	b54ff0ef          	jal	ffffffffc0200388 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201038:	00002697          	auipc	a3,0x2
ffffffffc020103c:	96068693          	addi	a3,a3,-1696 # ffffffffc0202998 <etext+0xa4c>
ffffffffc0201040:	00001617          	auipc	a2,0x1
ffffffffc0201044:	7e060613          	addi	a2,a2,2016 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0201048:	0cb00593          	li	a1,203
ffffffffc020104c:	00001517          	auipc	a0,0x1
ffffffffc0201050:	7ec50513          	addi	a0,a0,2028 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0201054:	b34ff0ef          	jal	ffffffffc0200388 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201058:	00002697          	auipc	a3,0x2
ffffffffc020105c:	92068693          	addi	a3,a3,-1760 # ffffffffc0202978 <etext+0xa2c>
ffffffffc0201060:	00001617          	auipc	a2,0x1
ffffffffc0201064:	7c060613          	addi	a2,a2,1984 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0201068:	0c200593          	li	a1,194
ffffffffc020106c:	00001517          	auipc	a0,0x1
ffffffffc0201070:	7cc50513          	addi	a0,a0,1996 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0201074:	b14ff0ef          	jal	ffffffffc0200388 <__panic>
    assert(p0 != NULL);
ffffffffc0201078:	00002697          	auipc	a3,0x2
ffffffffc020107c:	99068693          	addi	a3,a3,-1648 # ffffffffc0202a08 <etext+0xabc>
ffffffffc0201080:	00001617          	auipc	a2,0x1
ffffffffc0201084:	7a060613          	addi	a2,a2,1952 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0201088:	0f800593          	li	a1,248
ffffffffc020108c:	00001517          	auipc	a0,0x1
ffffffffc0201090:	7ac50513          	addi	a0,a0,1964 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0201094:	af4ff0ef          	jal	ffffffffc0200388 <__panic>
    assert(nr_free == 0);
ffffffffc0201098:	00002697          	auipc	a3,0x2
ffffffffc020109c:	96068693          	addi	a3,a3,-1696 # ffffffffc02029f8 <etext+0xaac>
ffffffffc02010a0:	00001617          	auipc	a2,0x1
ffffffffc02010a4:	78060613          	addi	a2,a2,1920 # ffffffffc0202820 <etext+0x8d4>
ffffffffc02010a8:	0df00593          	li	a1,223
ffffffffc02010ac:	00001517          	auipc	a0,0x1
ffffffffc02010b0:	78c50513          	addi	a0,a0,1932 # ffffffffc0202838 <etext+0x8ec>
ffffffffc02010b4:	ad4ff0ef          	jal	ffffffffc0200388 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02010b8:	00002697          	auipc	a3,0x2
ffffffffc02010bc:	8e068693          	addi	a3,a3,-1824 # ffffffffc0202998 <etext+0xa4c>
ffffffffc02010c0:	00001617          	auipc	a2,0x1
ffffffffc02010c4:	76060613          	addi	a2,a2,1888 # ffffffffc0202820 <etext+0x8d4>
ffffffffc02010c8:	0dd00593          	li	a1,221
ffffffffc02010cc:	00001517          	auipc	a0,0x1
ffffffffc02010d0:	76c50513          	addi	a0,a0,1900 # ffffffffc0202838 <etext+0x8ec>
ffffffffc02010d4:	ab4ff0ef          	jal	ffffffffc0200388 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02010d8:	00002697          	auipc	a3,0x2
ffffffffc02010dc:	90068693          	addi	a3,a3,-1792 # ffffffffc02029d8 <etext+0xa8c>
ffffffffc02010e0:	00001617          	auipc	a2,0x1
ffffffffc02010e4:	74060613          	addi	a2,a2,1856 # ffffffffc0202820 <etext+0x8d4>
ffffffffc02010e8:	0dc00593          	li	a1,220
ffffffffc02010ec:	00001517          	auipc	a0,0x1
ffffffffc02010f0:	74c50513          	addi	a0,a0,1868 # ffffffffc0202838 <etext+0x8ec>
ffffffffc02010f4:	a94ff0ef          	jal	ffffffffc0200388 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02010f8:	00001697          	auipc	a3,0x1
ffffffffc02010fc:	77868693          	addi	a3,a3,1912 # ffffffffc0202870 <etext+0x924>
ffffffffc0201100:	00001617          	auipc	a2,0x1
ffffffffc0201104:	72060613          	addi	a2,a2,1824 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0201108:	0b900593          	li	a1,185
ffffffffc020110c:	00001517          	auipc	a0,0x1
ffffffffc0201110:	72c50513          	addi	a0,a0,1836 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0201114:	a74ff0ef          	jal	ffffffffc0200388 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201118:	00002697          	auipc	a3,0x2
ffffffffc020111c:	88068693          	addi	a3,a3,-1920 # ffffffffc0202998 <etext+0xa4c>
ffffffffc0201120:	00001617          	auipc	a2,0x1
ffffffffc0201124:	70060613          	addi	a2,a2,1792 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0201128:	0d600593          	li	a1,214
ffffffffc020112c:	00001517          	auipc	a0,0x1
ffffffffc0201130:	70c50513          	addi	a0,a0,1804 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0201134:	a54ff0ef          	jal	ffffffffc0200388 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201138:	00001697          	auipc	a3,0x1
ffffffffc020113c:	77868693          	addi	a3,a3,1912 # ffffffffc02028b0 <etext+0x964>
ffffffffc0201140:	00001617          	auipc	a2,0x1
ffffffffc0201144:	6e060613          	addi	a2,a2,1760 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0201148:	0d400593          	li	a1,212
ffffffffc020114c:	00001517          	auipc	a0,0x1
ffffffffc0201150:	6ec50513          	addi	a0,a0,1772 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0201154:	a34ff0ef          	jal	ffffffffc0200388 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201158:	00001697          	auipc	a3,0x1
ffffffffc020115c:	73868693          	addi	a3,a3,1848 # ffffffffc0202890 <etext+0x944>
ffffffffc0201160:	00001617          	auipc	a2,0x1
ffffffffc0201164:	6c060613          	addi	a2,a2,1728 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0201168:	0d300593          	li	a1,211
ffffffffc020116c:	00001517          	auipc	a0,0x1
ffffffffc0201170:	6cc50513          	addi	a0,a0,1740 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0201174:	a14ff0ef          	jal	ffffffffc0200388 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201178:	00001697          	auipc	a3,0x1
ffffffffc020117c:	73868693          	addi	a3,a3,1848 # ffffffffc02028b0 <etext+0x964>
ffffffffc0201180:	00001617          	auipc	a2,0x1
ffffffffc0201184:	6a060613          	addi	a2,a2,1696 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0201188:	0bb00593          	li	a1,187
ffffffffc020118c:	00001517          	auipc	a0,0x1
ffffffffc0201190:	6ac50513          	addi	a0,a0,1708 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0201194:	9f4ff0ef          	jal	ffffffffc0200388 <__panic>
    assert(count == 0);
ffffffffc0201198:	00002697          	auipc	a3,0x2
ffffffffc020119c:	9c068693          	addi	a3,a3,-1600 # ffffffffc0202b58 <etext+0xc0c>
ffffffffc02011a0:	00001617          	auipc	a2,0x1
ffffffffc02011a4:	68060613          	addi	a2,a2,1664 # ffffffffc0202820 <etext+0x8d4>
ffffffffc02011a8:	12500593          	li	a1,293
ffffffffc02011ac:	00001517          	auipc	a0,0x1
ffffffffc02011b0:	68c50513          	addi	a0,a0,1676 # ffffffffc0202838 <etext+0x8ec>
ffffffffc02011b4:	9d4ff0ef          	jal	ffffffffc0200388 <__panic>
    assert(nr_free == 0);
ffffffffc02011b8:	00002697          	auipc	a3,0x2
ffffffffc02011bc:	84068693          	addi	a3,a3,-1984 # ffffffffc02029f8 <etext+0xaac>
ffffffffc02011c0:	00001617          	auipc	a2,0x1
ffffffffc02011c4:	66060613          	addi	a2,a2,1632 # ffffffffc0202820 <etext+0x8d4>
ffffffffc02011c8:	11a00593          	li	a1,282
ffffffffc02011cc:	00001517          	auipc	a0,0x1
ffffffffc02011d0:	66c50513          	addi	a0,a0,1644 # ffffffffc0202838 <etext+0x8ec>
ffffffffc02011d4:	9b4ff0ef          	jal	ffffffffc0200388 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011d8:	00001697          	auipc	a3,0x1
ffffffffc02011dc:	7c068693          	addi	a3,a3,1984 # ffffffffc0202998 <etext+0xa4c>
ffffffffc02011e0:	00001617          	auipc	a2,0x1
ffffffffc02011e4:	64060613          	addi	a2,a2,1600 # ffffffffc0202820 <etext+0x8d4>
ffffffffc02011e8:	11800593          	li	a1,280
ffffffffc02011ec:	00001517          	auipc	a0,0x1
ffffffffc02011f0:	64c50513          	addi	a0,a0,1612 # ffffffffc0202838 <etext+0x8ec>
ffffffffc02011f4:	994ff0ef          	jal	ffffffffc0200388 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02011f8:	00001697          	auipc	a3,0x1
ffffffffc02011fc:	76068693          	addi	a3,a3,1888 # ffffffffc0202958 <etext+0xa0c>
ffffffffc0201200:	00001617          	auipc	a2,0x1
ffffffffc0201204:	62060613          	addi	a2,a2,1568 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0201208:	0c100593          	li	a1,193
ffffffffc020120c:	00001517          	auipc	a0,0x1
ffffffffc0201210:	62c50513          	addi	a0,a0,1580 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0201214:	974ff0ef          	jal	ffffffffc0200388 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201218:	00002697          	auipc	a3,0x2
ffffffffc020121c:	90068693          	addi	a3,a3,-1792 # ffffffffc0202b18 <etext+0xbcc>
ffffffffc0201220:	00001617          	auipc	a2,0x1
ffffffffc0201224:	60060613          	addi	a2,a2,1536 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0201228:	11200593          	li	a1,274
ffffffffc020122c:	00001517          	auipc	a0,0x1
ffffffffc0201230:	60c50513          	addi	a0,a0,1548 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0201234:	954ff0ef          	jal	ffffffffc0200388 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201238:	00002697          	auipc	a3,0x2
ffffffffc020123c:	8c068693          	addi	a3,a3,-1856 # ffffffffc0202af8 <etext+0xbac>
ffffffffc0201240:	00001617          	auipc	a2,0x1
ffffffffc0201244:	5e060613          	addi	a2,a2,1504 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0201248:	11000593          	li	a1,272
ffffffffc020124c:	00001517          	auipc	a0,0x1
ffffffffc0201250:	5ec50513          	addi	a0,a0,1516 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0201254:	934ff0ef          	jal	ffffffffc0200388 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201258:	00002697          	auipc	a3,0x2
ffffffffc020125c:	87868693          	addi	a3,a3,-1928 # ffffffffc0202ad0 <etext+0xb84>
ffffffffc0201260:	00001617          	auipc	a2,0x1
ffffffffc0201264:	5c060613          	addi	a2,a2,1472 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0201268:	10e00593          	li	a1,270
ffffffffc020126c:	00001517          	auipc	a0,0x1
ffffffffc0201270:	5cc50513          	addi	a0,a0,1484 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0201274:	914ff0ef          	jal	ffffffffc0200388 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201278:	00002697          	auipc	a3,0x2
ffffffffc020127c:	83068693          	addi	a3,a3,-2000 # ffffffffc0202aa8 <etext+0xb5c>
ffffffffc0201280:	00001617          	auipc	a2,0x1
ffffffffc0201284:	5a060613          	addi	a2,a2,1440 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0201288:	10d00593          	li	a1,269
ffffffffc020128c:	00001517          	auipc	a0,0x1
ffffffffc0201290:	5ac50513          	addi	a0,a0,1452 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0201294:	8f4ff0ef          	jal	ffffffffc0200388 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201298:	00002697          	auipc	a3,0x2
ffffffffc020129c:	80068693          	addi	a3,a3,-2048 # ffffffffc0202a98 <etext+0xb4c>
ffffffffc02012a0:	00001617          	auipc	a2,0x1
ffffffffc02012a4:	58060613          	addi	a2,a2,1408 # ffffffffc0202820 <etext+0x8d4>
ffffffffc02012a8:	10800593          	li	a1,264
ffffffffc02012ac:	00001517          	auipc	a0,0x1
ffffffffc02012b0:	58c50513          	addi	a0,a0,1420 # ffffffffc0202838 <etext+0x8ec>
ffffffffc02012b4:	8d4ff0ef          	jal	ffffffffc0200388 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012b8:	00001697          	auipc	a3,0x1
ffffffffc02012bc:	6e068693          	addi	a3,a3,1760 # ffffffffc0202998 <etext+0xa4c>
ffffffffc02012c0:	00001617          	auipc	a2,0x1
ffffffffc02012c4:	56060613          	addi	a2,a2,1376 # ffffffffc0202820 <etext+0x8d4>
ffffffffc02012c8:	10700593          	li	a1,263
ffffffffc02012cc:	00001517          	auipc	a0,0x1
ffffffffc02012d0:	56c50513          	addi	a0,a0,1388 # ffffffffc0202838 <etext+0x8ec>
ffffffffc02012d4:	8b4ff0ef          	jal	ffffffffc0200388 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02012d8:	00001697          	auipc	a3,0x1
ffffffffc02012dc:	7a068693          	addi	a3,a3,1952 # ffffffffc0202a78 <etext+0xb2c>
ffffffffc02012e0:	00001617          	auipc	a2,0x1
ffffffffc02012e4:	54060613          	addi	a2,a2,1344 # ffffffffc0202820 <etext+0x8d4>
ffffffffc02012e8:	10600593          	li	a1,262
ffffffffc02012ec:	00001517          	auipc	a0,0x1
ffffffffc02012f0:	54c50513          	addi	a0,a0,1356 # ffffffffc0202838 <etext+0x8ec>
ffffffffc02012f4:	894ff0ef          	jal	ffffffffc0200388 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02012f8:	00001697          	auipc	a3,0x1
ffffffffc02012fc:	75068693          	addi	a3,a3,1872 # ffffffffc0202a48 <etext+0xafc>
ffffffffc0201300:	00001617          	auipc	a2,0x1
ffffffffc0201304:	52060613          	addi	a2,a2,1312 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0201308:	10500593          	li	a1,261
ffffffffc020130c:	00001517          	auipc	a0,0x1
ffffffffc0201310:	52c50513          	addi	a0,a0,1324 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0201314:	874ff0ef          	jal	ffffffffc0200388 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201318:	00001697          	auipc	a3,0x1
ffffffffc020131c:	71868693          	addi	a3,a3,1816 # ffffffffc0202a30 <etext+0xae4>
ffffffffc0201320:	00001617          	auipc	a2,0x1
ffffffffc0201324:	50060613          	addi	a2,a2,1280 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0201328:	10400593          	li	a1,260
ffffffffc020132c:	00001517          	auipc	a0,0x1
ffffffffc0201330:	50c50513          	addi	a0,a0,1292 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0201334:	854ff0ef          	jal	ffffffffc0200388 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201338:	00001697          	auipc	a3,0x1
ffffffffc020133c:	66068693          	addi	a3,a3,1632 # ffffffffc0202998 <etext+0xa4c>
ffffffffc0201340:	00001617          	auipc	a2,0x1
ffffffffc0201344:	4e060613          	addi	a2,a2,1248 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0201348:	0fe00593          	li	a1,254
ffffffffc020134c:	00001517          	auipc	a0,0x1
ffffffffc0201350:	4ec50513          	addi	a0,a0,1260 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0201354:	834ff0ef          	jal	ffffffffc0200388 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201358:	00001697          	auipc	a3,0x1
ffffffffc020135c:	6c068693          	addi	a3,a3,1728 # ffffffffc0202a18 <etext+0xacc>
ffffffffc0201360:	00001617          	auipc	a2,0x1
ffffffffc0201364:	4c060613          	addi	a2,a2,1216 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0201368:	0f900593          	li	a1,249
ffffffffc020136c:	00001517          	auipc	a0,0x1
ffffffffc0201370:	4cc50513          	addi	a0,a0,1228 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0201374:	814ff0ef          	jal	ffffffffc0200388 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201378:	00001697          	auipc	a3,0x1
ffffffffc020137c:	7c068693          	addi	a3,a3,1984 # ffffffffc0202b38 <etext+0xbec>
ffffffffc0201380:	00001617          	auipc	a2,0x1
ffffffffc0201384:	4a060613          	addi	a2,a2,1184 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0201388:	11700593          	li	a1,279
ffffffffc020138c:	00001517          	auipc	a0,0x1
ffffffffc0201390:	4ac50513          	addi	a0,a0,1196 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0201394:	ff5fe0ef          	jal	ffffffffc0200388 <__panic>
    assert(total == 0);
ffffffffc0201398:	00001697          	auipc	a3,0x1
ffffffffc020139c:	7d068693          	addi	a3,a3,2000 # ffffffffc0202b68 <etext+0xc1c>
ffffffffc02013a0:	00001617          	auipc	a2,0x1
ffffffffc02013a4:	48060613          	addi	a2,a2,1152 # ffffffffc0202820 <etext+0x8d4>
ffffffffc02013a8:	12600593          	li	a1,294
ffffffffc02013ac:	00001517          	auipc	a0,0x1
ffffffffc02013b0:	48c50513          	addi	a0,a0,1164 # ffffffffc0202838 <etext+0x8ec>
ffffffffc02013b4:	fd5fe0ef          	jal	ffffffffc0200388 <__panic>
    assert(total == nr_free_pages());
ffffffffc02013b8:	00001697          	auipc	a3,0x1
ffffffffc02013bc:	49868693          	addi	a3,a3,1176 # ffffffffc0202850 <etext+0x904>
ffffffffc02013c0:	00001617          	auipc	a2,0x1
ffffffffc02013c4:	46060613          	addi	a2,a2,1120 # ffffffffc0202820 <etext+0x8d4>
ffffffffc02013c8:	0f300593          	li	a1,243
ffffffffc02013cc:	00001517          	auipc	a0,0x1
ffffffffc02013d0:	46c50513          	addi	a0,a0,1132 # ffffffffc0202838 <etext+0x8ec>
ffffffffc02013d4:	fb5fe0ef          	jal	ffffffffc0200388 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02013d8:	00001697          	auipc	a3,0x1
ffffffffc02013dc:	4b868693          	addi	a3,a3,1208 # ffffffffc0202890 <etext+0x944>
ffffffffc02013e0:	00001617          	auipc	a2,0x1
ffffffffc02013e4:	44060613          	addi	a2,a2,1088 # ffffffffc0202820 <etext+0x8d4>
ffffffffc02013e8:	0ba00593          	li	a1,186
ffffffffc02013ec:	00001517          	auipc	a0,0x1
ffffffffc02013f0:	44c50513          	addi	a0,a0,1100 # ffffffffc0202838 <etext+0x8ec>
ffffffffc02013f4:	f95fe0ef          	jal	ffffffffc0200388 <__panic>

ffffffffc02013f8 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc02013f8:	1141                	addi	sp,sp,-16
ffffffffc02013fa:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02013fc:	14058c63          	beqz	a1,ffffffffc0201554 <default_free_pages+0x15c>
    for (; p != base + n; p ++) {
ffffffffc0201400:	00259713          	slli	a4,a1,0x2
ffffffffc0201404:	972e                	add	a4,a4,a1
ffffffffc0201406:	070e                	slli	a4,a4,0x3
ffffffffc0201408:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc020140c:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc020140e:	c30d                	beqz	a4,ffffffffc0201430 <default_free_pages+0x38>
ffffffffc0201410:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201412:	8b05                	andi	a4,a4,1
ffffffffc0201414:	12071063          	bnez	a4,ffffffffc0201534 <default_free_pages+0x13c>
ffffffffc0201418:	6798                	ld	a4,8(a5)
ffffffffc020141a:	8b09                	andi	a4,a4,2
ffffffffc020141c:	10071c63          	bnez	a4,ffffffffc0201534 <default_free_pages+0x13c>
        p->flags = 0;
ffffffffc0201420:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201424:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201428:	02878793          	addi	a5,a5,40
ffffffffc020142c:	fed792e3          	bne	a5,a3,ffffffffc0201410 <default_free_pages+0x18>
    base->property = n;
ffffffffc0201430:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201432:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201436:	4789                	li	a5,2
ffffffffc0201438:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020143c:	00006717          	auipc	a4,0x6
ffffffffc0201440:	bfc72703          	lw	a4,-1028(a4) # ffffffffc0207038 <free_area+0x10>
ffffffffc0201444:	00006697          	auipc	a3,0x6
ffffffffc0201448:	be468693          	addi	a3,a3,-1052 # ffffffffc0207028 <free_area>
    return list->next == list;
ffffffffc020144c:	669c                	ld	a5,8(a3)
ffffffffc020144e:	9f2d                	addw	a4,a4,a1
ffffffffc0201450:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201452:	0ad78563          	beq	a5,a3,ffffffffc02014fc <default_free_pages+0x104>
            struct Page* page = le2page(le, page_link);
ffffffffc0201456:	fe878713          	addi	a4,a5,-24
ffffffffc020145a:	4581                	li	a1,0
ffffffffc020145c:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201460:	00e56a63          	bltu	a0,a4,ffffffffc0201474 <default_free_pages+0x7c>
    return listelm->next;
ffffffffc0201464:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201466:	06d70263          	beq	a4,a3,ffffffffc02014ca <default_free_pages+0xd2>
    struct Page *p = base;
ffffffffc020146a:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020146c:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201470:	fee57ae3          	bgeu	a0,a4,ffffffffc0201464 <default_free_pages+0x6c>
ffffffffc0201474:	c199                	beqz	a1,ffffffffc020147a <default_free_pages+0x82>
ffffffffc0201476:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020147a:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc020147c:	e390                	sd	a2,0(a5)
ffffffffc020147e:	e710                	sd	a2,8(a4)
    elm->next = next;
    elm->prev = prev;
ffffffffc0201480:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc0201482:	f11c                	sd	a5,32(a0)
    if (le != &free_list) {
ffffffffc0201484:	02d70063          	beq	a4,a3,ffffffffc02014a4 <default_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc0201488:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc020148c:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc0201490:	02081613          	slli	a2,a6,0x20
ffffffffc0201494:	9201                	srli	a2,a2,0x20
ffffffffc0201496:	00261793          	slli	a5,a2,0x2
ffffffffc020149a:	97b2                	add	a5,a5,a2
ffffffffc020149c:	078e                	slli	a5,a5,0x3
ffffffffc020149e:	97ae                	add	a5,a5,a1
ffffffffc02014a0:	02f50f63          	beq	a0,a5,ffffffffc02014de <default_free_pages+0xe6>
    return listelm->next;
ffffffffc02014a4:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc02014a6:	00d70f63          	beq	a4,a3,ffffffffc02014c4 <default_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc02014aa:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc02014ac:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc02014b0:	02059613          	slli	a2,a1,0x20
ffffffffc02014b4:	9201                	srli	a2,a2,0x20
ffffffffc02014b6:	00261793          	slli	a5,a2,0x2
ffffffffc02014ba:	97b2                	add	a5,a5,a2
ffffffffc02014bc:	078e                	slli	a5,a5,0x3
ffffffffc02014be:	97aa                	add	a5,a5,a0
ffffffffc02014c0:	04f68a63          	beq	a3,a5,ffffffffc0201514 <default_free_pages+0x11c>
}
ffffffffc02014c4:	60a2                	ld	ra,8(sp)
ffffffffc02014c6:	0141                	addi	sp,sp,16
ffffffffc02014c8:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02014ca:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02014cc:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02014ce:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02014d0:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02014d2:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02014d4:	02d70d63          	beq	a4,a3,ffffffffc020150e <default_free_pages+0x116>
ffffffffc02014d8:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02014da:	87ba                	mv	a5,a4
ffffffffc02014dc:	bf41                	j	ffffffffc020146c <default_free_pages+0x74>
            p->property += base->property;
ffffffffc02014de:	491c                	lw	a5,16(a0)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02014e0:	5675                	li	a2,-3
ffffffffc02014e2:	010787bb          	addw	a5,a5,a6
ffffffffc02014e6:	fef72c23          	sw	a5,-8(a4)
ffffffffc02014ea:	60c8b02f          	amoand.d	zero,a2,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02014ee:	6d10                	ld	a2,24(a0)
ffffffffc02014f0:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc02014f2:	852e                	mv	a0,a1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02014f4:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc02014f6:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc02014f8:	e390                	sd	a2,0(a5)
ffffffffc02014fa:	b775                	j	ffffffffc02014a6 <default_free_pages+0xae>
}
ffffffffc02014fc:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02014fe:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0201502:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201504:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0201506:	e398                	sd	a4,0(a5)
ffffffffc0201508:	e798                	sd	a4,8(a5)
}
ffffffffc020150a:	0141                	addi	sp,sp,16
ffffffffc020150c:	8082                	ret
ffffffffc020150e:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc0201510:	873e                	mv	a4,a5
ffffffffc0201512:	bf8d                	j	ffffffffc0201484 <default_free_pages+0x8c>
            base->property += p->property;
ffffffffc0201514:	ff872783          	lw	a5,-8(a4)
ffffffffc0201518:	56f5                	li	a3,-3
ffffffffc020151a:	9fad                	addw	a5,a5,a1
ffffffffc020151c:	c91c                	sw	a5,16(a0)
ffffffffc020151e:	ff070793          	addi	a5,a4,-16
ffffffffc0201522:	60d7b02f          	amoand.d	zero,a3,(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201526:	6314                	ld	a3,0(a4)
ffffffffc0201528:	671c                	ld	a5,8(a4)
}
ffffffffc020152a:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020152c:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc020152e:	e394                	sd	a3,0(a5)
ffffffffc0201530:	0141                	addi	sp,sp,16
ffffffffc0201532:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201534:	00001697          	auipc	a3,0x1
ffffffffc0201538:	64c68693          	addi	a3,a3,1612 # ffffffffc0202b80 <etext+0xc34>
ffffffffc020153c:	00001617          	auipc	a2,0x1
ffffffffc0201540:	2e460613          	addi	a2,a2,740 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0201544:	08300593          	li	a1,131
ffffffffc0201548:	00001517          	auipc	a0,0x1
ffffffffc020154c:	2f050513          	addi	a0,a0,752 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0201550:	e39fe0ef          	jal	ffffffffc0200388 <__panic>
    assert(n > 0);
ffffffffc0201554:	00001697          	auipc	a3,0x1
ffffffffc0201558:	62468693          	addi	a3,a3,1572 # ffffffffc0202b78 <etext+0xc2c>
ffffffffc020155c:	00001617          	auipc	a2,0x1
ffffffffc0201560:	2c460613          	addi	a2,a2,708 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0201564:	08000593          	li	a1,128
ffffffffc0201568:	00001517          	auipc	a0,0x1
ffffffffc020156c:	2d050513          	addi	a0,a0,720 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0201570:	e19fe0ef          	jal	ffffffffc0200388 <__panic>

ffffffffc0201574 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201574:	cd41                	beqz	a0,ffffffffc020160c <default_alloc_pages+0x98>
    if (n > nr_free) {
ffffffffc0201576:	00006597          	auipc	a1,0x6
ffffffffc020157a:	ac25a583          	lw	a1,-1342(a1) # ffffffffc0207038 <free_area+0x10>
ffffffffc020157e:	86aa                	mv	a3,a0
ffffffffc0201580:	02059793          	slli	a5,a1,0x20
ffffffffc0201584:	9381                	srli	a5,a5,0x20
ffffffffc0201586:	00a7ef63          	bltu	a5,a0,ffffffffc02015a4 <default_alloc_pages+0x30>
    list_entry_t *le = &free_list;
ffffffffc020158a:	00006617          	auipc	a2,0x6
ffffffffc020158e:	a9e60613          	addi	a2,a2,-1378 # ffffffffc0207028 <free_area>
ffffffffc0201592:	87b2                	mv	a5,a2
ffffffffc0201594:	a029                	j	ffffffffc020159e <default_alloc_pages+0x2a>
        if (p->property >= n) {
ffffffffc0201596:	ff87e703          	lwu	a4,-8(a5)
ffffffffc020159a:	00d77763          	bgeu	a4,a3,ffffffffc02015a8 <default_alloc_pages+0x34>
    return listelm->next;
ffffffffc020159e:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02015a0:	fec79be3          	bne	a5,a2,ffffffffc0201596 <default_alloc_pages+0x22>
        return NULL;
ffffffffc02015a4:	4501                	li	a0,0
}
ffffffffc02015a6:	8082                	ret
        if (page->property > n) {
ffffffffc02015a8:	ff87a883          	lw	a7,-8(a5)
    return listelm->prev;
ffffffffc02015ac:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02015b0:	6798                	ld	a4,8(a5)
ffffffffc02015b2:	02089313          	slli	t1,a7,0x20
ffffffffc02015b6:	02035313          	srli	t1,t1,0x20
    prev->next = next;
ffffffffc02015ba:	00e83423          	sd	a4,8(a6) # ff0008 <kern_entry-0xffffffffbf20fff8>
    next->prev = prev;
ffffffffc02015be:	01073023          	sd	a6,0(a4)
        struct Page *p = le2page(le, page_link);
ffffffffc02015c2:	fe878513          	addi	a0,a5,-24
        if (page->property > n) {
ffffffffc02015c6:	0266fc63          	bgeu	a3,t1,ffffffffc02015fe <default_alloc_pages+0x8a>
            struct Page *p = page + n;
ffffffffc02015ca:	00269713          	slli	a4,a3,0x2
ffffffffc02015ce:	9736                	add	a4,a4,a3
ffffffffc02015d0:	070e                	slli	a4,a4,0x3
            p->property = page->property - n;
ffffffffc02015d2:	40d888bb          	subw	a7,a7,a3
            struct Page *p = page + n;
ffffffffc02015d6:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02015d8:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02015dc:	00870313          	addi	t1,a4,8
ffffffffc02015e0:	4889                	li	a7,2
ffffffffc02015e2:	4113302f          	amoor.d	zero,a7,(t1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02015e6:	00883883          	ld	a7,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc02015ea:	01870313          	addi	t1,a4,24
    prev->next = next->prev = elm;
ffffffffc02015ee:	0068b023          	sd	t1,0(a7)
ffffffffc02015f2:	00683423          	sd	t1,8(a6)
    elm->next = next;
ffffffffc02015f6:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc02015fa:	01073c23          	sd	a6,24(a4)
        nr_free -= n;
ffffffffc02015fe:	9d95                	subw	a1,a1,a3
ffffffffc0201600:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201602:	5775                	li	a4,-3
ffffffffc0201604:	17c1                	addi	a5,a5,-16
ffffffffc0201606:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc020160a:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc020160c:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020160e:	00001697          	auipc	a3,0x1
ffffffffc0201612:	56a68693          	addi	a3,a3,1386 # ffffffffc0202b78 <etext+0xc2c>
ffffffffc0201616:	00001617          	auipc	a2,0x1
ffffffffc020161a:	20a60613          	addi	a2,a2,522 # ffffffffc0202820 <etext+0x8d4>
ffffffffc020161e:	06200593          	li	a1,98
ffffffffc0201622:	00001517          	auipc	a0,0x1
ffffffffc0201626:	21650513          	addi	a0,a0,534 # ffffffffc0202838 <etext+0x8ec>
default_alloc_pages(size_t n) {
ffffffffc020162a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020162c:	d5dfe0ef          	jal	ffffffffc0200388 <__panic>

ffffffffc0201630 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0201630:	1141                	addi	sp,sp,-16
ffffffffc0201632:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201634:	c9f1                	beqz	a1,ffffffffc0201708 <default_init_memmap+0xd8>
    for (; p != base + n; p ++) {
ffffffffc0201636:	00259713          	slli	a4,a1,0x2
ffffffffc020163a:	972e                	add	a4,a4,a1
ffffffffc020163c:	070e                	slli	a4,a4,0x3
ffffffffc020163e:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201642:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0201644:	cf11                	beqz	a4,ffffffffc0201660 <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201646:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201648:	8b05                	andi	a4,a4,1
ffffffffc020164a:	cf59                	beqz	a4,ffffffffc02016e8 <default_init_memmap+0xb8>
        p->flags = p->property = 0;
ffffffffc020164c:	0007a823          	sw	zero,16(a5)
ffffffffc0201650:	0007b423          	sd	zero,8(a5)
ffffffffc0201654:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201658:	02878793          	addi	a5,a5,40
ffffffffc020165c:	fed795e3          	bne	a5,a3,ffffffffc0201646 <default_init_memmap+0x16>
    base->property = n;
ffffffffc0201660:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201662:	4789                	li	a5,2
ffffffffc0201664:	00850713          	addi	a4,a0,8
ffffffffc0201668:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc020166c:	00006717          	auipc	a4,0x6
ffffffffc0201670:	9cc72703          	lw	a4,-1588(a4) # ffffffffc0207038 <free_area+0x10>
ffffffffc0201674:	00006697          	auipc	a3,0x6
ffffffffc0201678:	9b468693          	addi	a3,a3,-1612 # ffffffffc0207028 <free_area>
    return list->next == list;
ffffffffc020167c:	669c                	ld	a5,8(a3)
ffffffffc020167e:	9f2d                	addw	a4,a4,a1
ffffffffc0201680:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201682:	04d78663          	beq	a5,a3,ffffffffc02016ce <default_init_memmap+0x9e>
            struct Page* page = le2page(le, page_link);
ffffffffc0201686:	fe878713          	addi	a4,a5,-24
ffffffffc020168a:	4581                	li	a1,0
ffffffffc020168c:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201690:	00e56a63          	bltu	a0,a4,ffffffffc02016a4 <default_init_memmap+0x74>
    return listelm->next;
ffffffffc0201694:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201696:	02d70263          	beq	a4,a3,ffffffffc02016ba <default_init_memmap+0x8a>
    struct Page *p = base;
ffffffffc020169a:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020169c:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02016a0:	fee57ae3          	bgeu	a0,a4,ffffffffc0201694 <default_init_memmap+0x64>
ffffffffc02016a4:	c199                	beqz	a1,ffffffffc02016aa <default_init_memmap+0x7a>
ffffffffc02016a6:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02016aa:	6398                	ld	a4,0(a5)
}
ffffffffc02016ac:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02016ae:	e390                	sd	a2,0(a5)
ffffffffc02016b0:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc02016b2:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc02016b4:	f11c                	sd	a5,32(a0)
ffffffffc02016b6:	0141                	addi	sp,sp,16
ffffffffc02016b8:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02016ba:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02016bc:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02016be:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02016c0:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02016c2:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02016c4:	00d70e63          	beq	a4,a3,ffffffffc02016e0 <default_init_memmap+0xb0>
ffffffffc02016c8:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02016ca:	87ba                	mv	a5,a4
ffffffffc02016cc:	bfc1                	j	ffffffffc020169c <default_init_memmap+0x6c>
}
ffffffffc02016ce:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02016d0:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc02016d4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016d6:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc02016d8:	e398                	sd	a4,0(a5)
ffffffffc02016da:	e798                	sd	a4,8(a5)
}
ffffffffc02016dc:	0141                	addi	sp,sp,16
ffffffffc02016de:	8082                	ret
ffffffffc02016e0:	60a2                	ld	ra,8(sp)
ffffffffc02016e2:	e290                	sd	a2,0(a3)
ffffffffc02016e4:	0141                	addi	sp,sp,16
ffffffffc02016e6:	8082                	ret
        assert(PageReserved(p));
ffffffffc02016e8:	00001697          	auipc	a3,0x1
ffffffffc02016ec:	4c068693          	addi	a3,a3,1216 # ffffffffc0202ba8 <etext+0xc5c>
ffffffffc02016f0:	00001617          	auipc	a2,0x1
ffffffffc02016f4:	13060613          	addi	a2,a2,304 # ffffffffc0202820 <etext+0x8d4>
ffffffffc02016f8:	04900593          	li	a1,73
ffffffffc02016fc:	00001517          	auipc	a0,0x1
ffffffffc0201700:	13c50513          	addi	a0,a0,316 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0201704:	c85fe0ef          	jal	ffffffffc0200388 <__panic>
    assert(n > 0);
ffffffffc0201708:	00001697          	auipc	a3,0x1
ffffffffc020170c:	47068693          	addi	a3,a3,1136 # ffffffffc0202b78 <etext+0xc2c>
ffffffffc0201710:	00001617          	auipc	a2,0x1
ffffffffc0201714:	11060613          	addi	a2,a2,272 # ffffffffc0202820 <etext+0x8d4>
ffffffffc0201718:	04600593          	li	a1,70
ffffffffc020171c:	00001517          	auipc	a0,0x1
ffffffffc0201720:	11c50513          	addi	a0,a0,284 # ffffffffc0202838 <etext+0x8ec>
ffffffffc0201724:	c65fe0ef          	jal	ffffffffc0200388 <__panic>

ffffffffc0201728 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201728:	100027f3          	csrr	a5,sstatus
ffffffffc020172c:	8b89                	andi	a5,a5,2
ffffffffc020172e:	e799                	bnez	a5,ffffffffc020173c <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201730:	00006797          	auipc	a5,0x6
ffffffffc0201734:	d387b783          	ld	a5,-712(a5) # ffffffffc0207468 <pmm_manager>
ffffffffc0201738:	6f9c                	ld	a5,24(a5)
ffffffffc020173a:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc020173c:	1101                	addi	sp,sp,-32
ffffffffc020173e:	ec06                	sd	ra,24(sp)
ffffffffc0201740:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201742:	840ff0ef          	jal	ffffffffc0200782 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201746:	00006797          	auipc	a5,0x6
ffffffffc020174a:	d227b783          	ld	a5,-734(a5) # ffffffffc0207468 <pmm_manager>
ffffffffc020174e:	6522                	ld	a0,8(sp)
ffffffffc0201750:	6f9c                	ld	a5,24(a5)
ffffffffc0201752:	9782                	jalr	a5
ffffffffc0201754:	e42a                	sd	a0,8(sp)
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0201756:	826ff0ef          	jal	ffffffffc020077c <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc020175a:	60e2                	ld	ra,24(sp)
ffffffffc020175c:	6522                	ld	a0,8(sp)
ffffffffc020175e:	6105                	addi	sp,sp,32
ffffffffc0201760:	8082                	ret

ffffffffc0201762 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201762:	100027f3          	csrr	a5,sstatus
ffffffffc0201766:	8b89                	andi	a5,a5,2
ffffffffc0201768:	e799                	bnez	a5,ffffffffc0201776 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc020176a:	00006797          	auipc	a5,0x6
ffffffffc020176e:	cfe7b783          	ld	a5,-770(a5) # ffffffffc0207468 <pmm_manager>
ffffffffc0201772:	739c                	ld	a5,32(a5)
ffffffffc0201774:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0201776:	1101                	addi	sp,sp,-32
ffffffffc0201778:	ec06                	sd	ra,24(sp)
ffffffffc020177a:	e42e                	sd	a1,8(sp)
ffffffffc020177c:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc020177e:	804ff0ef          	jal	ffffffffc0200782 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201782:	00006797          	auipc	a5,0x6
ffffffffc0201786:	ce67b783          	ld	a5,-794(a5) # ffffffffc0207468 <pmm_manager>
ffffffffc020178a:	65a2                	ld	a1,8(sp)
ffffffffc020178c:	6502                	ld	a0,0(sp)
ffffffffc020178e:	739c                	ld	a5,32(a5)
ffffffffc0201790:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201792:	60e2                	ld	ra,24(sp)
ffffffffc0201794:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201796:	fe7fe06f          	j	ffffffffc020077c <intr_enable>

ffffffffc020179a <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020179a:	100027f3          	csrr	a5,sstatus
ffffffffc020179e:	8b89                	andi	a5,a5,2
ffffffffc02017a0:	e799                	bnez	a5,ffffffffc02017ae <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc02017a2:	00006797          	auipc	a5,0x6
ffffffffc02017a6:	cc67b783          	ld	a5,-826(a5) # ffffffffc0207468 <pmm_manager>
ffffffffc02017aa:	779c                	ld	a5,40(a5)
ffffffffc02017ac:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc02017ae:	1101                	addi	sp,sp,-32
ffffffffc02017b0:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02017b2:	fd1fe0ef          	jal	ffffffffc0200782 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02017b6:	00006797          	auipc	a5,0x6
ffffffffc02017ba:	cb27b783          	ld	a5,-846(a5) # ffffffffc0207468 <pmm_manager>
ffffffffc02017be:	779c                	ld	a5,40(a5)
ffffffffc02017c0:	9782                	jalr	a5
ffffffffc02017c2:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02017c4:	fb9fe0ef          	jal	ffffffffc020077c <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc02017c8:	60e2                	ld	ra,24(sp)
ffffffffc02017ca:	6522                	ld	a0,8(sp)
ffffffffc02017cc:	6105                	addi	sp,sp,32
ffffffffc02017ce:	8082                	ret

ffffffffc02017d0 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02017d0:	00001797          	auipc	a5,0x1
ffffffffc02017d4:	67878793          	addi	a5,a5,1656 # ffffffffc0202e48 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02017d8:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02017da:	7139                	addi	sp,sp,-64
ffffffffc02017dc:	fc06                	sd	ra,56(sp)
ffffffffc02017de:	f822                	sd	s0,48(sp)
ffffffffc02017e0:	f426                	sd	s1,40(sp)
ffffffffc02017e2:	ec4e                	sd	s3,24(sp)
ffffffffc02017e4:	f04a                	sd	s2,32(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02017e6:	00006417          	auipc	s0,0x6
ffffffffc02017ea:	c8240413          	addi	s0,s0,-894 # ffffffffc0207468 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02017ee:	00001517          	auipc	a0,0x1
ffffffffc02017f2:	3e250513          	addi	a0,a0,994 # ffffffffc0202bd0 <etext+0xc84>
    pmm_manager = &default_pmm_manager;
ffffffffc02017f6:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02017f8:	8dffe0ef          	jal	ffffffffc02000d6 <cprintf>
    pmm_manager->init();
ffffffffc02017fc:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02017fe:	00006497          	auipc	s1,0x6
ffffffffc0201802:	c8248493          	addi	s1,s1,-894 # ffffffffc0207480 <va_pa_offset>
    pmm_manager->init();
ffffffffc0201806:	679c                	ld	a5,8(a5)
ffffffffc0201808:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020180a:	57f5                	li	a5,-3
ffffffffc020180c:	07fa                	slli	a5,a5,0x1e
ffffffffc020180e:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0201810:	f59fe0ef          	jal	ffffffffc0200768 <get_memory_base>
ffffffffc0201814:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0201816:	f5dfe0ef          	jal	ffffffffc0200772 <get_memory_size>
    if (mem_size == 0) {
ffffffffc020181a:	16050063          	beqz	a0,ffffffffc020197a <pmm_init+0x1aa>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc020181e:	00a98933          	add	s2,s3,a0
ffffffffc0201822:	e42a                	sd	a0,8(sp)
    cprintf("physcial memory map:\n");
ffffffffc0201824:	00001517          	auipc	a0,0x1
ffffffffc0201828:	3f450513          	addi	a0,a0,1012 # ffffffffc0202c18 <etext+0xccc>
ffffffffc020182c:	8abfe0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201830:	65a2                	ld	a1,8(sp)
ffffffffc0201832:	864e                	mv	a2,s3
ffffffffc0201834:	fff90693          	addi	a3,s2,-1
ffffffffc0201838:	00001517          	auipc	a0,0x1
ffffffffc020183c:	3f850513          	addi	a0,a0,1016 # ffffffffc0202c30 <etext+0xce4>
ffffffffc0201840:	897fe0ef          	jal	ffffffffc02000d6 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc0201844:	c80007b7          	lui	a5,0xc8000
ffffffffc0201848:	864a                	mv	a2,s2
ffffffffc020184a:	0d27e563          	bltu	a5,s2,ffffffffc0201914 <pmm_init+0x144>
ffffffffc020184e:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201850:	00007697          	auipc	a3,0x7
ffffffffc0201854:	c4f68693          	addi	a3,a3,-945 # ffffffffc020849f <end+0xfff>
ffffffffc0201858:	8efd                	and	a3,a3,a5
    npage = maxpa / PGSIZE;
ffffffffc020185a:	8231                	srli	a2,a2,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020185c:	00006817          	auipc	a6,0x6
ffffffffc0201860:	c3480813          	addi	a6,a6,-972 # ffffffffc0207490 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0201864:	00006517          	auipc	a0,0x6
ffffffffc0201868:	c2450513          	addi	a0,a0,-988 # ffffffffc0207488 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020186c:	00d83023          	sd	a3,0(a6)
    npage = maxpa / PGSIZE;
ffffffffc0201870:	e110                	sd	a2,0(a0)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201872:	00080737          	lui	a4,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201876:	87b6                	mv	a5,a3
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201878:	02e60a63          	beq	a2,a4,ffffffffc02018ac <pmm_init+0xdc>
ffffffffc020187c:	4701                	li	a4,0
ffffffffc020187e:	4781                	li	a5,0
ffffffffc0201880:	4305                	li	t1,1
ffffffffc0201882:	fff808b7          	lui	a7,0xfff80
        SetPageReserved(pages + i);
ffffffffc0201886:	96ba                	add	a3,a3,a4
ffffffffc0201888:	06a1                	addi	a3,a3,8
ffffffffc020188a:	4066b02f          	amoor.d	zero,t1,(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020188e:	6110                	ld	a2,0(a0)
ffffffffc0201890:	0785                	addi	a5,a5,1 # fffffffffffff001 <end+0x3fdf7b61>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201892:	00083683          	ld	a3,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201896:	011605b3          	add	a1,a2,a7
ffffffffc020189a:	02870713          	addi	a4,a4,40 # 80028 <kern_entry-0xffffffffc017ffd8>
ffffffffc020189e:	feb7e4e3          	bltu	a5,a1,ffffffffc0201886 <pmm_init+0xb6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02018a2:	00259793          	slli	a5,a1,0x2
ffffffffc02018a6:	97ae                	add	a5,a5,a1
ffffffffc02018a8:	078e                	slli	a5,a5,0x3
ffffffffc02018aa:	97b6                	add	a5,a5,a3
ffffffffc02018ac:	c0200737          	lui	a4,0xc0200
ffffffffc02018b0:	0ae7e863          	bltu	a5,a4,ffffffffc0201960 <pmm_init+0x190>
ffffffffc02018b4:	608c                	ld	a1,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02018b6:	777d                	lui	a4,0xfffff
ffffffffc02018b8:	00e97933          	and	s2,s2,a4
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02018bc:	8f8d                	sub	a5,a5,a1
    if (freemem < mem_end) {
ffffffffc02018be:	0527ed63          	bltu	a5,s2,ffffffffc0201918 <pmm_init+0x148>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02018c2:	601c                	ld	a5,0(s0)
ffffffffc02018c4:	7b9c                	ld	a5,48(a5)
ffffffffc02018c6:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02018c8:	00001517          	auipc	a0,0x1
ffffffffc02018cc:	3f050513          	addi	a0,a0,1008 # ffffffffc0202cb8 <etext+0xd6c>
ffffffffc02018d0:	807fe0ef          	jal	ffffffffc02000d6 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02018d4:	00004597          	auipc	a1,0x4
ffffffffc02018d8:	72c58593          	addi	a1,a1,1836 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc02018dc:	00006797          	auipc	a5,0x6
ffffffffc02018e0:	b8b7be23          	sd	a1,-1124(a5) # ffffffffc0207478 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02018e4:	c02007b7          	lui	a5,0xc0200
ffffffffc02018e8:	0af5e563          	bltu	a1,a5,ffffffffc0201992 <pmm_init+0x1c2>
ffffffffc02018ec:	609c                	ld	a5,0(s1)
}
ffffffffc02018ee:	7442                	ld	s0,48(sp)
ffffffffc02018f0:	70e2                	ld	ra,56(sp)
ffffffffc02018f2:	74a2                	ld	s1,40(sp)
ffffffffc02018f4:	7902                	ld	s2,32(sp)
ffffffffc02018f6:	69e2                	ld	s3,24(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02018f8:	40f586b3          	sub	a3,a1,a5
ffffffffc02018fc:	00006797          	auipc	a5,0x6
ffffffffc0201900:	b6d7ba23          	sd	a3,-1164(a5) # ffffffffc0207470 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201904:	00001517          	auipc	a0,0x1
ffffffffc0201908:	3d450513          	addi	a0,a0,980 # ffffffffc0202cd8 <etext+0xd8c>
ffffffffc020190c:	8636                	mv	a2,a3
}
ffffffffc020190e:	6121                	addi	sp,sp,64
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201910:	fc6fe06f          	j	ffffffffc02000d6 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc0201914:	863e                	mv	a2,a5
ffffffffc0201916:	bf25                	j	ffffffffc020184e <pmm_init+0x7e>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201918:	6585                	lui	a1,0x1
ffffffffc020191a:	15fd                	addi	a1,a1,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc020191c:	97ae                	add	a5,a5,a1
ffffffffc020191e:	8ff9                	and	a5,a5,a4
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201920:	00c7d713          	srli	a4,a5,0xc
ffffffffc0201924:	02c77263          	bgeu	a4,a2,ffffffffc0201948 <pmm_init+0x178>
    pmm_manager->init_memmap(base, n);
ffffffffc0201928:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020192a:	fff805b7          	lui	a1,0xfff80
ffffffffc020192e:	972e                	add	a4,a4,a1
ffffffffc0201930:	00271513          	slli	a0,a4,0x2
ffffffffc0201934:	953a                	add	a0,a0,a4
ffffffffc0201936:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201938:	40f90933          	sub	s2,s2,a5
ffffffffc020193c:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020193e:	00c95593          	srli	a1,s2,0xc
ffffffffc0201942:	9536                	add	a0,a0,a3
ffffffffc0201944:	9702                	jalr	a4
}
ffffffffc0201946:	bfb5                	j	ffffffffc02018c2 <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc0201948:	00001617          	auipc	a2,0x1
ffffffffc020194c:	34060613          	addi	a2,a2,832 # ffffffffc0202c88 <etext+0xd3c>
ffffffffc0201950:	06b00593          	li	a1,107
ffffffffc0201954:	00001517          	auipc	a0,0x1
ffffffffc0201958:	35450513          	addi	a0,a0,852 # ffffffffc0202ca8 <etext+0xd5c>
ffffffffc020195c:	a2dfe0ef          	jal	ffffffffc0200388 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201960:	86be                	mv	a3,a5
ffffffffc0201962:	00001617          	auipc	a2,0x1
ffffffffc0201966:	2fe60613          	addi	a2,a2,766 # ffffffffc0202c60 <etext+0xd14>
ffffffffc020196a:	07100593          	li	a1,113
ffffffffc020196e:	00001517          	auipc	a0,0x1
ffffffffc0201972:	29a50513          	addi	a0,a0,666 # ffffffffc0202c08 <etext+0xcbc>
ffffffffc0201976:	a13fe0ef          	jal	ffffffffc0200388 <__panic>
        panic("DTB memory info not available");
ffffffffc020197a:	00001617          	auipc	a2,0x1
ffffffffc020197e:	26e60613          	addi	a2,a2,622 # ffffffffc0202be8 <etext+0xc9c>
ffffffffc0201982:	05a00593          	li	a1,90
ffffffffc0201986:	00001517          	auipc	a0,0x1
ffffffffc020198a:	28250513          	addi	a0,a0,642 # ffffffffc0202c08 <etext+0xcbc>
ffffffffc020198e:	9fbfe0ef          	jal	ffffffffc0200388 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201992:	86ae                	mv	a3,a1
ffffffffc0201994:	00001617          	auipc	a2,0x1
ffffffffc0201998:	2cc60613          	addi	a2,a2,716 # ffffffffc0202c60 <etext+0xd14>
ffffffffc020199c:	08c00593          	li	a1,140
ffffffffc02019a0:	00001517          	auipc	a0,0x1
ffffffffc02019a4:	26850513          	addi	a0,a0,616 # ffffffffc0202c08 <etext+0xcbc>
ffffffffc02019a8:	9e1fe0ef          	jal	ffffffffc0200388 <__panic>

ffffffffc02019ac <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019ac:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02019ae:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019b2:	f022                	sd	s0,32(sp)
ffffffffc02019b4:	ec26                	sd	s1,24(sp)
ffffffffc02019b6:	e84a                	sd	s2,16(sp)
ffffffffc02019b8:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02019ba:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019be:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc02019c0:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02019c4:	fff7041b          	addiw	s0,a4,-1 # ffffffffffffefff <end+0x3fdf7b5f>
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019c8:	84aa                	mv	s1,a0
ffffffffc02019ca:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc02019cc:	03067d63          	bgeu	a2,a6,ffffffffc0201a06 <printnum+0x5a>
ffffffffc02019d0:	e44e                	sd	s3,8(sp)
ffffffffc02019d2:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02019d4:	4785                	li	a5,1
ffffffffc02019d6:	00e7d763          	bge	a5,a4,ffffffffc02019e4 <printnum+0x38>
            putch(padc, putdat);
ffffffffc02019da:	85ca                	mv	a1,s2
ffffffffc02019dc:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc02019de:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02019e0:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02019e2:	fc65                	bnez	s0,ffffffffc02019da <printnum+0x2e>
ffffffffc02019e4:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019e6:	00001797          	auipc	a5,0x1
ffffffffc02019ea:	33278793          	addi	a5,a5,818 # ffffffffc0202d18 <etext+0xdcc>
ffffffffc02019ee:	97d2                	add	a5,a5,s4
}
ffffffffc02019f0:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019f2:	0007c503          	lbu	a0,0(a5)
}
ffffffffc02019f6:	70a2                	ld	ra,40(sp)
ffffffffc02019f8:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019fa:	85ca                	mv	a1,s2
ffffffffc02019fc:	87a6                	mv	a5,s1
}
ffffffffc02019fe:	6942                	ld	s2,16(sp)
ffffffffc0201a00:	64e2                	ld	s1,24(sp)
ffffffffc0201a02:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a04:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201a06:	03065633          	divu	a2,a2,a6
ffffffffc0201a0a:	8722                	mv	a4,s0
ffffffffc0201a0c:	fa1ff0ef          	jal	ffffffffc02019ac <printnum>
ffffffffc0201a10:	bfd9                	j	ffffffffc02019e6 <printnum+0x3a>

ffffffffc0201a12 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201a12:	7119                	addi	sp,sp,-128
ffffffffc0201a14:	f4a6                	sd	s1,104(sp)
ffffffffc0201a16:	f0ca                	sd	s2,96(sp)
ffffffffc0201a18:	ecce                	sd	s3,88(sp)
ffffffffc0201a1a:	e8d2                	sd	s4,80(sp)
ffffffffc0201a1c:	e4d6                	sd	s5,72(sp)
ffffffffc0201a1e:	e0da                	sd	s6,64(sp)
ffffffffc0201a20:	f862                	sd	s8,48(sp)
ffffffffc0201a22:	fc86                	sd	ra,120(sp)
ffffffffc0201a24:	f8a2                	sd	s0,112(sp)
ffffffffc0201a26:	fc5e                	sd	s7,56(sp)
ffffffffc0201a28:	f466                	sd	s9,40(sp)
ffffffffc0201a2a:	f06a                	sd	s10,32(sp)
ffffffffc0201a2c:	ec6e                	sd	s11,24(sp)
ffffffffc0201a2e:	84aa                	mv	s1,a0
ffffffffc0201a30:	8c32                	mv	s8,a2
ffffffffc0201a32:	8a36                	mv	s4,a3
ffffffffc0201a34:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a36:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a3a:	05500b13          	li	s6,85
ffffffffc0201a3e:	00001a97          	auipc	s5,0x1
ffffffffc0201a42:	442a8a93          	addi	s5,s5,1090 # ffffffffc0202e80 <default_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a46:	000c4503          	lbu	a0,0(s8)
ffffffffc0201a4a:	001c0413          	addi	s0,s8,1
ffffffffc0201a4e:	01350a63          	beq	a0,s3,ffffffffc0201a62 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0201a52:	cd0d                	beqz	a0,ffffffffc0201a8c <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0201a54:	85ca                	mv	a1,s2
ffffffffc0201a56:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a58:	00044503          	lbu	a0,0(s0)
ffffffffc0201a5c:	0405                	addi	s0,s0,1
ffffffffc0201a5e:	ff351ae3          	bne	a0,s3,ffffffffc0201a52 <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0201a62:	5cfd                	li	s9,-1
ffffffffc0201a64:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc0201a66:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0201a6a:	4b81                	li	s7,0
ffffffffc0201a6c:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a6e:	00044683          	lbu	a3,0(s0)
ffffffffc0201a72:	00140c13          	addi	s8,s0,1
ffffffffc0201a76:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0201a7a:	0ff5f593          	zext.b	a1,a1
ffffffffc0201a7e:	02bb6663          	bltu	s6,a1,ffffffffc0201aaa <vprintfmt+0x98>
ffffffffc0201a82:	058a                	slli	a1,a1,0x2
ffffffffc0201a84:	95d6                	add	a1,a1,s5
ffffffffc0201a86:	4198                	lw	a4,0(a1)
ffffffffc0201a88:	9756                	add	a4,a4,s5
ffffffffc0201a8a:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201a8c:	70e6                	ld	ra,120(sp)
ffffffffc0201a8e:	7446                	ld	s0,112(sp)
ffffffffc0201a90:	74a6                	ld	s1,104(sp)
ffffffffc0201a92:	7906                	ld	s2,96(sp)
ffffffffc0201a94:	69e6                	ld	s3,88(sp)
ffffffffc0201a96:	6a46                	ld	s4,80(sp)
ffffffffc0201a98:	6aa6                	ld	s5,72(sp)
ffffffffc0201a9a:	6b06                	ld	s6,64(sp)
ffffffffc0201a9c:	7be2                	ld	s7,56(sp)
ffffffffc0201a9e:	7c42                	ld	s8,48(sp)
ffffffffc0201aa0:	7ca2                	ld	s9,40(sp)
ffffffffc0201aa2:	7d02                	ld	s10,32(sp)
ffffffffc0201aa4:	6de2                	ld	s11,24(sp)
ffffffffc0201aa6:	6109                	addi	sp,sp,128
ffffffffc0201aa8:	8082                	ret
            putch('%', putdat);
ffffffffc0201aaa:	85ca                	mv	a1,s2
ffffffffc0201aac:	02500513          	li	a0,37
ffffffffc0201ab0:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201ab2:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201ab6:	02500713          	li	a4,37
ffffffffc0201aba:	8c22                	mv	s8,s0
ffffffffc0201abc:	f8e785e3          	beq	a5,a4,ffffffffc0201a46 <vprintfmt+0x34>
ffffffffc0201ac0:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0201ac4:	1c7d                	addi	s8,s8,-1
ffffffffc0201ac6:	fee79de3          	bne	a5,a4,ffffffffc0201ac0 <vprintfmt+0xae>
ffffffffc0201aca:	bfb5                	j	ffffffffc0201a46 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0201acc:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0201ad0:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc0201ad2:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0201ad6:	fd06071b          	addiw	a4,a2,-48
ffffffffc0201ada:	24e56a63          	bltu	a0,a4,ffffffffc0201d2e <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc0201ade:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ae0:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc0201ae2:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0201ae6:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201aea:	0197073b          	addw	a4,a4,s9
ffffffffc0201aee:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201af2:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201af4:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201af8:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201afa:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0201afe:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc0201b02:	feb570e3          	bgeu	a0,a1,ffffffffc0201ae2 <vprintfmt+0xd0>
            if (width < 0)
ffffffffc0201b06:	f60d54e3          	bgez	s10,ffffffffc0201a6e <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0201b0a:	8d66                	mv	s10,s9
ffffffffc0201b0c:	5cfd                	li	s9,-1
ffffffffc0201b0e:	b785                	j	ffffffffc0201a6e <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b10:	8db6                	mv	s11,a3
ffffffffc0201b12:	8462                	mv	s0,s8
ffffffffc0201b14:	bfa9                	j	ffffffffc0201a6e <vprintfmt+0x5c>
ffffffffc0201b16:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0201b18:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0201b1a:	bf91                	j	ffffffffc0201a6e <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0201b1c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b1e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b22:	00f74463          	blt	a4,a5,ffffffffc0201b2a <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0201b26:	1a078763          	beqz	a5,ffffffffc0201cd4 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc0201b2a:	000a3603          	ld	a2,0(s4)
ffffffffc0201b2e:	46c1                	li	a3,16
ffffffffc0201b30:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201b32:	000d879b          	sext.w	a5,s11
ffffffffc0201b36:	876a                	mv	a4,s10
ffffffffc0201b38:	85ca                	mv	a1,s2
ffffffffc0201b3a:	8526                	mv	a0,s1
ffffffffc0201b3c:	e71ff0ef          	jal	ffffffffc02019ac <printnum>
            break;
ffffffffc0201b40:	b719                	j	ffffffffc0201a46 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0201b42:	000a2503          	lw	a0,0(s4)
ffffffffc0201b46:	85ca                	mv	a1,s2
ffffffffc0201b48:	0a21                	addi	s4,s4,8
ffffffffc0201b4a:	9482                	jalr	s1
            break;
ffffffffc0201b4c:	bded                	j	ffffffffc0201a46 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201b4e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b50:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b54:	00f74463          	blt	a4,a5,ffffffffc0201b5c <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0201b58:	16078963          	beqz	a5,ffffffffc0201cca <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc0201b5c:	000a3603          	ld	a2,0(s4)
ffffffffc0201b60:	46a9                	li	a3,10
ffffffffc0201b62:	8a2e                	mv	s4,a1
ffffffffc0201b64:	b7f9                	j	ffffffffc0201b32 <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc0201b66:	85ca                	mv	a1,s2
ffffffffc0201b68:	03000513          	li	a0,48
ffffffffc0201b6c:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc0201b6e:	85ca                	mv	a1,s2
ffffffffc0201b70:	07800513          	li	a0,120
ffffffffc0201b74:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201b76:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0201b7a:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201b7c:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201b7e:	bf55                	j	ffffffffc0201b32 <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc0201b80:	85ca                	mv	a1,s2
ffffffffc0201b82:	02500513          	li	a0,37
ffffffffc0201b86:	9482                	jalr	s1
            break;
ffffffffc0201b88:	bd7d                	j	ffffffffc0201a46 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0201b8a:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b8e:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0201b90:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0201b92:	bf95                	j	ffffffffc0201b06 <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc0201b94:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b96:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b9a:	00f74463          	blt	a4,a5,ffffffffc0201ba2 <vprintfmt+0x190>
    else if (lflag) {
ffffffffc0201b9e:	12078163          	beqz	a5,ffffffffc0201cc0 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc0201ba2:	000a3603          	ld	a2,0(s4)
ffffffffc0201ba6:	46a1                	li	a3,8
ffffffffc0201ba8:	8a2e                	mv	s4,a1
ffffffffc0201baa:	b761                	j	ffffffffc0201b32 <vprintfmt+0x120>
            if (width < 0)
ffffffffc0201bac:	876a                	mv	a4,s10
ffffffffc0201bae:	000d5363          	bgez	s10,ffffffffc0201bb4 <vprintfmt+0x1a2>
ffffffffc0201bb2:	4701                	li	a4,0
ffffffffc0201bb4:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bb8:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201bba:	bd55                	j	ffffffffc0201a6e <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc0201bbc:	000d841b          	sext.w	s0,s11
ffffffffc0201bc0:	fd340793          	addi	a5,s0,-45
ffffffffc0201bc4:	00f037b3          	snez	a5,a5
ffffffffc0201bc8:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201bcc:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc0201bd0:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201bd2:	008a0793          	addi	a5,s4,8
ffffffffc0201bd6:	e43e                	sd	a5,8(sp)
ffffffffc0201bd8:	100d8c63          	beqz	s11,ffffffffc0201cf0 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0201bdc:	12071363          	bnez	a4,ffffffffc0201d02 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201be0:	000dc783          	lbu	a5,0(s11)
ffffffffc0201be4:	0007851b          	sext.w	a0,a5
ffffffffc0201be8:	c78d                	beqz	a5,ffffffffc0201c12 <vprintfmt+0x200>
ffffffffc0201bea:	0d85                	addi	s11,s11,1
ffffffffc0201bec:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201bee:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201bf2:	000cc563          	bltz	s9,ffffffffc0201bfc <vprintfmt+0x1ea>
ffffffffc0201bf6:	3cfd                	addiw	s9,s9,-1
ffffffffc0201bf8:	008c8d63          	beq	s9,s0,ffffffffc0201c12 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201bfc:	020b9663          	bnez	s7,ffffffffc0201c28 <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc0201c00:	85ca                	mv	a1,s2
ffffffffc0201c02:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c04:	000dc783          	lbu	a5,0(s11)
ffffffffc0201c08:	0d85                	addi	s11,s11,1
ffffffffc0201c0a:	3d7d                	addiw	s10,s10,-1
ffffffffc0201c0c:	0007851b          	sext.w	a0,a5
ffffffffc0201c10:	f3ed                	bnez	a5,ffffffffc0201bf2 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc0201c12:	01a05963          	blez	s10,ffffffffc0201c24 <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc0201c16:	85ca                	mv	a1,s2
ffffffffc0201c18:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0201c1c:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0201c1e:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc0201c20:	fe0d1be3          	bnez	s10,ffffffffc0201c16 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c24:	6a22                	ld	s4,8(sp)
ffffffffc0201c26:	b505                	j	ffffffffc0201a46 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c28:	3781                	addiw	a5,a5,-32
ffffffffc0201c2a:	fcfa7be3          	bgeu	s4,a5,ffffffffc0201c00 <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0201c2e:	03f00513          	li	a0,63
ffffffffc0201c32:	85ca                	mv	a1,s2
ffffffffc0201c34:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c36:	000dc783          	lbu	a5,0(s11)
ffffffffc0201c3a:	0d85                	addi	s11,s11,1
ffffffffc0201c3c:	3d7d                	addiw	s10,s10,-1
ffffffffc0201c3e:	0007851b          	sext.w	a0,a5
ffffffffc0201c42:	dbe1                	beqz	a5,ffffffffc0201c12 <vprintfmt+0x200>
ffffffffc0201c44:	fa0cd9e3          	bgez	s9,ffffffffc0201bf6 <vprintfmt+0x1e4>
ffffffffc0201c48:	b7c5                	j	ffffffffc0201c28 <vprintfmt+0x216>
            if (err < 0) {
ffffffffc0201c4a:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c4e:	4619                	li	a2,6
            err = va_arg(ap, int);
ffffffffc0201c50:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201c52:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0201c56:	8fb9                	xor	a5,a5,a4
ffffffffc0201c58:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c5c:	02d64563          	blt	a2,a3,ffffffffc0201c86 <vprintfmt+0x274>
ffffffffc0201c60:	00001797          	auipc	a5,0x1
ffffffffc0201c64:	37878793          	addi	a5,a5,888 # ffffffffc0202fd8 <error_string>
ffffffffc0201c68:	00369713          	slli	a4,a3,0x3
ffffffffc0201c6c:	97ba                	add	a5,a5,a4
ffffffffc0201c6e:	639c                	ld	a5,0(a5)
ffffffffc0201c70:	cb99                	beqz	a5,ffffffffc0201c86 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201c72:	86be                	mv	a3,a5
ffffffffc0201c74:	00001617          	auipc	a2,0x1
ffffffffc0201c78:	0d460613          	addi	a2,a2,212 # ffffffffc0202d48 <etext+0xdfc>
ffffffffc0201c7c:	85ca                	mv	a1,s2
ffffffffc0201c7e:	8526                	mv	a0,s1
ffffffffc0201c80:	0d8000ef          	jal	ffffffffc0201d58 <printfmt>
ffffffffc0201c84:	b3c9                	j	ffffffffc0201a46 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201c86:	00001617          	auipc	a2,0x1
ffffffffc0201c8a:	0b260613          	addi	a2,a2,178 # ffffffffc0202d38 <etext+0xdec>
ffffffffc0201c8e:	85ca                	mv	a1,s2
ffffffffc0201c90:	8526                	mv	a0,s1
ffffffffc0201c92:	0c6000ef          	jal	ffffffffc0201d58 <printfmt>
ffffffffc0201c96:	bb45                	j	ffffffffc0201a46 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201c98:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c9a:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0201c9e:	00f74363          	blt	a4,a5,ffffffffc0201ca4 <vprintfmt+0x292>
    else if (lflag) {
ffffffffc0201ca2:	cf81                	beqz	a5,ffffffffc0201cba <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc0201ca4:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201ca8:	02044b63          	bltz	s0,ffffffffc0201cde <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0201cac:	8622                	mv	a2,s0
ffffffffc0201cae:	8a5e                	mv	s4,s7
ffffffffc0201cb0:	46a9                	li	a3,10
ffffffffc0201cb2:	b541                	j	ffffffffc0201b32 <vprintfmt+0x120>
            lflag ++;
ffffffffc0201cb4:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201cb6:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201cb8:	bb5d                	j	ffffffffc0201a6e <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc0201cba:	000a2403          	lw	s0,0(s4)
ffffffffc0201cbe:	b7ed                	j	ffffffffc0201ca8 <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc0201cc0:	000a6603          	lwu	a2,0(s4)
ffffffffc0201cc4:	46a1                	li	a3,8
ffffffffc0201cc6:	8a2e                	mv	s4,a1
ffffffffc0201cc8:	b5ad                	j	ffffffffc0201b32 <vprintfmt+0x120>
ffffffffc0201cca:	000a6603          	lwu	a2,0(s4)
ffffffffc0201cce:	46a9                	li	a3,10
ffffffffc0201cd0:	8a2e                	mv	s4,a1
ffffffffc0201cd2:	b585                	j	ffffffffc0201b32 <vprintfmt+0x120>
ffffffffc0201cd4:	000a6603          	lwu	a2,0(s4)
ffffffffc0201cd8:	46c1                	li	a3,16
ffffffffc0201cda:	8a2e                	mv	s4,a1
ffffffffc0201cdc:	bd99                	j	ffffffffc0201b32 <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc0201cde:	85ca                	mv	a1,s2
ffffffffc0201ce0:	02d00513          	li	a0,45
ffffffffc0201ce4:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc0201ce6:	40800633          	neg	a2,s0
ffffffffc0201cea:	8a5e                	mv	s4,s7
ffffffffc0201cec:	46a9                	li	a3,10
ffffffffc0201cee:	b591                	j	ffffffffc0201b32 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc0201cf0:	e329                	bnez	a4,ffffffffc0201d32 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cf2:	02800793          	li	a5,40
ffffffffc0201cf6:	853e                	mv	a0,a5
ffffffffc0201cf8:	00001d97          	auipc	s11,0x1
ffffffffc0201cfc:	039d8d93          	addi	s11,s11,57 # ffffffffc0202d31 <etext+0xde5>
ffffffffc0201d00:	b5f5                	j	ffffffffc0201bec <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d02:	85e6                	mv	a1,s9
ffffffffc0201d04:	856e                	mv	a0,s11
ffffffffc0201d06:	1aa000ef          	jal	ffffffffc0201eb0 <strnlen>
ffffffffc0201d0a:	40ad0d3b          	subw	s10,s10,a0
ffffffffc0201d0e:	01a05863          	blez	s10,ffffffffc0201d1e <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc0201d12:	85ca                	mv	a1,s2
ffffffffc0201d14:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d16:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc0201d18:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d1a:	fe0d1ce3          	bnez	s10,ffffffffc0201d12 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d1e:	000dc783          	lbu	a5,0(s11)
ffffffffc0201d22:	0007851b          	sext.w	a0,a5
ffffffffc0201d26:	ec0792e3          	bnez	a5,ffffffffc0201bea <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201d2a:	6a22                	ld	s4,8(sp)
ffffffffc0201d2c:	bb29                	j	ffffffffc0201a46 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d2e:	8462                	mv	s0,s8
ffffffffc0201d30:	bbd9                	j	ffffffffc0201b06 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d32:	85e6                	mv	a1,s9
ffffffffc0201d34:	00001517          	auipc	a0,0x1
ffffffffc0201d38:	ffc50513          	addi	a0,a0,-4 # ffffffffc0202d30 <etext+0xde4>
ffffffffc0201d3c:	174000ef          	jal	ffffffffc0201eb0 <strnlen>
ffffffffc0201d40:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d44:	02800793          	li	a5,40
                p = "(null)";
ffffffffc0201d48:	00001d97          	auipc	s11,0x1
ffffffffc0201d4c:	fe8d8d93          	addi	s11,s11,-24 # ffffffffc0202d30 <etext+0xde4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d50:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d52:	fda040e3          	bgtz	s10,ffffffffc0201d12 <vprintfmt+0x300>
ffffffffc0201d56:	bd51                	j	ffffffffc0201bea <vprintfmt+0x1d8>

ffffffffc0201d58 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d58:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201d5a:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d5e:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d60:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d62:	ec06                	sd	ra,24(sp)
ffffffffc0201d64:	f83a                	sd	a4,48(sp)
ffffffffc0201d66:	fc3e                	sd	a5,56(sp)
ffffffffc0201d68:	e0c2                	sd	a6,64(sp)
ffffffffc0201d6a:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201d6c:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d6e:	ca5ff0ef          	jal	ffffffffc0201a12 <vprintfmt>
}
ffffffffc0201d72:	60e2                	ld	ra,24(sp)
ffffffffc0201d74:	6161                	addi	sp,sp,80
ffffffffc0201d76:	8082                	ret

ffffffffc0201d78 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201d78:	7179                	addi	sp,sp,-48
ffffffffc0201d7a:	f406                	sd	ra,40(sp)
ffffffffc0201d7c:	f022                	sd	s0,32(sp)
ffffffffc0201d7e:	ec26                	sd	s1,24(sp)
ffffffffc0201d80:	e84a                	sd	s2,16(sp)
ffffffffc0201d82:	e44e                	sd	s3,8(sp)
    if (prompt != NULL) {
ffffffffc0201d84:	c901                	beqz	a0,ffffffffc0201d94 <readline+0x1c>
        cprintf("%s", prompt);
ffffffffc0201d86:	85aa                	mv	a1,a0
ffffffffc0201d88:	00001517          	auipc	a0,0x1
ffffffffc0201d8c:	fc050513          	addi	a0,a0,-64 # ffffffffc0202d48 <etext+0xdfc>
ffffffffc0201d90:	b46fe0ef          	jal	ffffffffc02000d6 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc0201d94:	4481                	li	s1,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d96:	497d                	li	s2,31
            buf[i ++] = c;
ffffffffc0201d98:	00005997          	auipc	s3,0x5
ffffffffc0201d9c:	2a898993          	addi	s3,s3,680 # ffffffffc0207040 <buf>
        c = getchar();
ffffffffc0201da0:	bb8fe0ef          	jal	ffffffffc0200158 <getchar>
ffffffffc0201da4:	842a                	mv	s0,a0
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201da6:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201daa:	3ff4a713          	slti	a4,s1,1023
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201dae:	ff650693          	addi	a3,a0,-10
ffffffffc0201db2:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc0201db6:	02054963          	bltz	a0,ffffffffc0201de8 <readline+0x70>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201dba:	02a95f63          	bge	s2,a0,ffffffffc0201df8 <readline+0x80>
ffffffffc0201dbe:	cf0d                	beqz	a4,ffffffffc0201df8 <readline+0x80>
            cputchar(c);
ffffffffc0201dc0:	b4afe0ef          	jal	ffffffffc020010a <cputchar>
            buf[i ++] = c;
ffffffffc0201dc4:	009987b3          	add	a5,s3,s1
ffffffffc0201dc8:	00878023          	sb	s0,0(a5)
ffffffffc0201dcc:	2485                	addiw	s1,s1,1
        c = getchar();
ffffffffc0201dce:	b8afe0ef          	jal	ffffffffc0200158 <getchar>
ffffffffc0201dd2:	842a                	mv	s0,a0
        else if (c == '\b' && i > 0) {
ffffffffc0201dd4:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201dd8:	3ff4a713          	slti	a4,s1,1023
        else if (c == '\n' || c == '\r') {
ffffffffc0201ddc:	ff650693          	addi	a3,a0,-10
ffffffffc0201de0:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc0201de4:	fc055be3          	bgez	a0,ffffffffc0201dba <readline+0x42>
            cputchar(c);
            buf[i] = '\0';
            return buf;
        }
    }
}
ffffffffc0201de8:	70a2                	ld	ra,40(sp)
ffffffffc0201dea:	7402                	ld	s0,32(sp)
ffffffffc0201dec:	64e2                	ld	s1,24(sp)
ffffffffc0201dee:	6942                	ld	s2,16(sp)
ffffffffc0201df0:	69a2                	ld	s3,8(sp)
            return NULL;
ffffffffc0201df2:	4501                	li	a0,0
}
ffffffffc0201df4:	6145                	addi	sp,sp,48
ffffffffc0201df6:	8082                	ret
        else if (c == '\b' && i > 0) {
ffffffffc0201df8:	eb81                	bnez	a5,ffffffffc0201e08 <readline+0x90>
            cputchar(c);
ffffffffc0201dfa:	4521                	li	a0,8
        else if (c == '\b' && i > 0) {
ffffffffc0201dfc:	00905663          	blez	s1,ffffffffc0201e08 <readline+0x90>
            cputchar(c);
ffffffffc0201e00:	b0afe0ef          	jal	ffffffffc020010a <cputchar>
            i --;
ffffffffc0201e04:	34fd                	addiw	s1,s1,-1
ffffffffc0201e06:	bf69                	j	ffffffffc0201da0 <readline+0x28>
        else if (c == '\n' || c == '\r') {
ffffffffc0201e08:	c291                	beqz	a3,ffffffffc0201e0c <readline+0x94>
ffffffffc0201e0a:	fa59                	bnez	a2,ffffffffc0201da0 <readline+0x28>
            cputchar(c);
ffffffffc0201e0c:	8522                	mv	a0,s0
ffffffffc0201e0e:	afcfe0ef          	jal	ffffffffc020010a <cputchar>
            buf[i] = '\0';
ffffffffc0201e12:	00005517          	auipc	a0,0x5
ffffffffc0201e16:	22e50513          	addi	a0,a0,558 # ffffffffc0207040 <buf>
ffffffffc0201e1a:	94aa                	add	s1,s1,a0
ffffffffc0201e1c:	00048023          	sb	zero,0(s1)
}
ffffffffc0201e20:	70a2                	ld	ra,40(sp)
ffffffffc0201e22:	7402                	ld	s0,32(sp)
ffffffffc0201e24:	64e2                	ld	s1,24(sp)
ffffffffc0201e26:	6942                	ld	s2,16(sp)
ffffffffc0201e28:	69a2                	ld	s3,8(sp)
ffffffffc0201e2a:	6145                	addi	sp,sp,48
ffffffffc0201e2c:	8082                	ret

ffffffffc0201e2e <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201e2e:	00005717          	auipc	a4,0x5
ffffffffc0201e32:	1f273703          	ld	a4,498(a4) # ffffffffc0207020 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201e36:	4781                	li	a5,0
ffffffffc0201e38:	88ba                	mv	a7,a4
ffffffffc0201e3a:	852a                	mv	a0,a0
ffffffffc0201e3c:	85be                	mv	a1,a5
ffffffffc0201e3e:	863e                	mv	a2,a5
ffffffffc0201e40:	00000073          	ecall
ffffffffc0201e44:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201e46:	8082                	ret

ffffffffc0201e48 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201e48:	00005717          	auipc	a4,0x5
ffffffffc0201e4c:	65073703          	ld	a4,1616(a4) # ffffffffc0207498 <SBI_SET_TIMER>
ffffffffc0201e50:	4781                	li	a5,0
ffffffffc0201e52:	88ba                	mv	a7,a4
ffffffffc0201e54:	852a                	mv	a0,a0
ffffffffc0201e56:	85be                	mv	a1,a5
ffffffffc0201e58:	863e                	mv	a2,a5
ffffffffc0201e5a:	00000073          	ecall
ffffffffc0201e5e:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201e60:	8082                	ret

ffffffffc0201e62 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201e62:	00005797          	auipc	a5,0x5
ffffffffc0201e66:	1b67b783          	ld	a5,438(a5) # ffffffffc0207018 <SBI_CONSOLE_GETCHAR>
ffffffffc0201e6a:	4501                	li	a0,0
ffffffffc0201e6c:	88be                	mv	a7,a5
ffffffffc0201e6e:	852a                	mv	a0,a0
ffffffffc0201e70:	85aa                	mv	a1,a0
ffffffffc0201e72:	862a                	mv	a2,a0
ffffffffc0201e74:	00000073          	ecall
ffffffffc0201e78:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201e7a:	2501                	sext.w	a0,a0
ffffffffc0201e7c:	8082                	ret

ffffffffc0201e7e <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201e7e:	00005717          	auipc	a4,0x5
ffffffffc0201e82:	19273703          	ld	a4,402(a4) # ffffffffc0207010 <SBI_SHUTDOWN>
ffffffffc0201e86:	4781                	li	a5,0
ffffffffc0201e88:	88ba                	mv	a7,a4
ffffffffc0201e8a:	853e                	mv	a0,a5
ffffffffc0201e8c:	85be                	mv	a1,a5
ffffffffc0201e8e:	863e                	mv	a2,a5
ffffffffc0201e90:	00000073          	ecall
ffffffffc0201e94:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201e96:	8082                	ret

ffffffffc0201e98 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201e98:	00054783          	lbu	a5,0(a0)
ffffffffc0201e9c:	cb81                	beqz	a5,ffffffffc0201eac <strlen+0x14>
    size_t cnt = 0;
ffffffffc0201e9e:	4781                	li	a5,0
        cnt ++;
ffffffffc0201ea0:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0201ea2:	00f50733          	add	a4,a0,a5
ffffffffc0201ea6:	00074703          	lbu	a4,0(a4)
ffffffffc0201eaa:	fb7d                	bnez	a4,ffffffffc0201ea0 <strlen+0x8>
    }
    return cnt;
}
ffffffffc0201eac:	853e                	mv	a0,a5
ffffffffc0201eae:	8082                	ret

ffffffffc0201eb0 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201eb0:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201eb2:	e589                	bnez	a1,ffffffffc0201ebc <strnlen+0xc>
ffffffffc0201eb4:	a811                	j	ffffffffc0201ec8 <strnlen+0x18>
        cnt ++;
ffffffffc0201eb6:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201eb8:	00f58863          	beq	a1,a5,ffffffffc0201ec8 <strnlen+0x18>
ffffffffc0201ebc:	00f50733          	add	a4,a0,a5
ffffffffc0201ec0:	00074703          	lbu	a4,0(a4)
ffffffffc0201ec4:	fb6d                	bnez	a4,ffffffffc0201eb6 <strnlen+0x6>
ffffffffc0201ec6:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201ec8:	852e                	mv	a0,a1
ffffffffc0201eca:	8082                	ret

ffffffffc0201ecc <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201ecc:	00054783          	lbu	a5,0(a0)
ffffffffc0201ed0:	e791                	bnez	a5,ffffffffc0201edc <strcmp+0x10>
ffffffffc0201ed2:	a01d                	j	ffffffffc0201ef8 <strcmp+0x2c>
ffffffffc0201ed4:	00054783          	lbu	a5,0(a0)
ffffffffc0201ed8:	cb99                	beqz	a5,ffffffffc0201eee <strcmp+0x22>
ffffffffc0201eda:	0585                	addi	a1,a1,1 # fffffffffff80001 <end+0x3fd78b61>
ffffffffc0201edc:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0201ee0:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201ee2:	fef709e3          	beq	a4,a5,ffffffffc0201ed4 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ee6:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201eea:	9d19                	subw	a0,a0,a4
ffffffffc0201eec:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201eee:	0015c703          	lbu	a4,1(a1)
ffffffffc0201ef2:	4501                	li	a0,0
}
ffffffffc0201ef4:	9d19                	subw	a0,a0,a4
ffffffffc0201ef6:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ef8:	0005c703          	lbu	a4,0(a1)
ffffffffc0201efc:	4501                	li	a0,0
ffffffffc0201efe:	b7f5                	j	ffffffffc0201eea <strcmp+0x1e>

ffffffffc0201f00 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f00:	ce01                	beqz	a2,ffffffffc0201f18 <strncmp+0x18>
ffffffffc0201f02:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201f06:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f08:	cb91                	beqz	a5,ffffffffc0201f1c <strncmp+0x1c>
ffffffffc0201f0a:	0005c703          	lbu	a4,0(a1)
ffffffffc0201f0e:	00f71763          	bne	a4,a5,ffffffffc0201f1c <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0201f12:	0505                	addi	a0,a0,1
ffffffffc0201f14:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f16:	f675                	bnez	a2,ffffffffc0201f02 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f18:	4501                	li	a0,0
ffffffffc0201f1a:	8082                	ret
ffffffffc0201f1c:	00054503          	lbu	a0,0(a0)
ffffffffc0201f20:	0005c783          	lbu	a5,0(a1)
ffffffffc0201f24:	9d1d                	subw	a0,a0,a5
}
ffffffffc0201f26:	8082                	ret

ffffffffc0201f28 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201f28:	a021                	j	ffffffffc0201f30 <strchr+0x8>
        if (*s == c) {
ffffffffc0201f2a:	00f58763          	beq	a1,a5,ffffffffc0201f38 <strchr+0x10>
            return (char *)s;
        }
        s ++;
ffffffffc0201f2e:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201f30:	00054783          	lbu	a5,0(a0)
ffffffffc0201f34:	fbfd                	bnez	a5,ffffffffc0201f2a <strchr+0x2>
    }
    return NULL;
ffffffffc0201f36:	4501                	li	a0,0
}
ffffffffc0201f38:	8082                	ret

ffffffffc0201f3a <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201f3a:	ca01                	beqz	a2,ffffffffc0201f4a <memset+0x10>
ffffffffc0201f3c:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201f3e:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201f40:	0785                	addi	a5,a5,1
ffffffffc0201f42:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201f46:	fef61de3          	bne	a2,a5,ffffffffc0201f40 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201f4a:	8082                	ret
