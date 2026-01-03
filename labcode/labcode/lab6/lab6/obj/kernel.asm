
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000c297          	auipc	t0,0xc
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020c000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000c297          	auipc	t0,0xc
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020c008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020b2b7          	lui	t0,0xc020b
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
ffffffffc020003c:	c020b137          	lui	sp,0xc020b

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	000b1517          	auipc	a0,0xb1
ffffffffc020004e:	5ae50513          	addi	a0,a0,1454 # ffffffffc02b15f8 <buf>
ffffffffc0200052:	000b6617          	auipc	a2,0xb6
ffffffffc0200056:	a8e60613          	addi	a2,a2,-1394 # ffffffffc02b5ae0 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16 # ffffffffc020aff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	1ad050ef          	jal	ffffffffc0205a0e <memset>
    cons_init(); // init the console
ffffffffc0200066:	4da000ef          	jal	ffffffffc0200540 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006a:	00006597          	auipc	a1,0x6
ffffffffc020006e:	9ce58593          	addi	a1,a1,-1586 # ffffffffc0205a38 <etext>
ffffffffc0200072:	00006517          	auipc	a0,0x6
ffffffffc0200076:	9e650513          	addi	a0,a0,-1562 # ffffffffc0205a58 <etext+0x20>
ffffffffc020007a:	11e000ef          	jal	ffffffffc0200198 <cprintf>

    print_kerninfo();
ffffffffc020007e:	1ac000ef          	jal	ffffffffc020022a <print_kerninfo>

    // grade_backtrace();

    dtb_init(); // init dtb
ffffffffc0200082:	530000ef          	jal	ffffffffc02005b2 <dtb_init>

    pmm_init(); // init physical memory management
ffffffffc0200086:	660020ef          	jal	ffffffffc02026e6 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	07b000ef          	jal	ffffffffc0200904 <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	079000ef          	jal	ffffffffc0200906 <idt_init>

    vmm_init(); // init virtual memory management
ffffffffc0200092:	10f030ef          	jal	ffffffffc02039a0 <vmm_init>
    sched_init();
ffffffffc0200096:	1e4050ef          	jal	ffffffffc020527a <sched_init>
    proc_init(); // init process table
ffffffffc020009a:	671040ef          	jal	ffffffffc0204f0a <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009e:	45a000ef          	jal	ffffffffc02004f8 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc02000a2:	057000ef          	jal	ffffffffc02008f8 <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a6:	004050ef          	jal	ffffffffc02050aa <cpu_idle>

ffffffffc02000aa <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000aa:	7179                	addi	sp,sp,-48
ffffffffc02000ac:	f406                	sd	ra,40(sp)
ffffffffc02000ae:	f022                	sd	s0,32(sp)
ffffffffc02000b0:	ec26                	sd	s1,24(sp)
ffffffffc02000b2:	e84a                	sd	s2,16(sp)
ffffffffc02000b4:	e44e                	sd	s3,8(sp)
    if (prompt != NULL) {
ffffffffc02000b6:	c901                	beqz	a0,ffffffffc02000c6 <readline+0x1c>
        cprintf("%s", prompt);
ffffffffc02000b8:	85aa                	mv	a1,a0
ffffffffc02000ba:	00006517          	auipc	a0,0x6
ffffffffc02000be:	9a650513          	addi	a0,a0,-1626 # ffffffffc0205a60 <etext+0x28>
ffffffffc02000c2:	0d6000ef          	jal	ffffffffc0200198 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc02000c6:	4481                	li	s1,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000c8:	497d                	li	s2,31
            buf[i ++] = c;
ffffffffc02000ca:	000b1997          	auipc	s3,0xb1
ffffffffc02000ce:	52e98993          	addi	s3,s3,1326 # ffffffffc02b15f8 <buf>
        c = getchar();
ffffffffc02000d2:	148000ef          	jal	ffffffffc020021a <getchar>
ffffffffc02000d6:	842a                	mv	s0,a0
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000d8:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000dc:	3ff4a713          	slti	a4,s1,1023
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000e0:	ff650693          	addi	a3,a0,-10
ffffffffc02000e4:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc02000e8:	02054963          	bltz	a0,ffffffffc020011a <readline+0x70>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ec:	02a95f63          	bge	s2,a0,ffffffffc020012a <readline+0x80>
ffffffffc02000f0:	cf0d                	beqz	a4,ffffffffc020012a <readline+0x80>
            cputchar(c);
ffffffffc02000f2:	0da000ef          	jal	ffffffffc02001cc <cputchar>
            buf[i ++] = c;
ffffffffc02000f6:	009987b3          	add	a5,s3,s1
ffffffffc02000fa:	00878023          	sb	s0,0(a5)
ffffffffc02000fe:	2485                	addiw	s1,s1,1
        c = getchar();
ffffffffc0200100:	11a000ef          	jal	ffffffffc020021a <getchar>
ffffffffc0200104:	842a                	mv	s0,a0
        else if (c == '\b' && i > 0) {
ffffffffc0200106:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020010a:	3ff4a713          	slti	a4,s1,1023
        else if (c == '\n' || c == '\r') {
ffffffffc020010e:	ff650693          	addi	a3,a0,-10
ffffffffc0200112:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc0200116:	fc055be3          	bgez	a0,ffffffffc02000ec <readline+0x42>
            cputchar(c);
            buf[i] = '\0';
            return buf;
        }
    }
}
ffffffffc020011a:	70a2                	ld	ra,40(sp)
ffffffffc020011c:	7402                	ld	s0,32(sp)
ffffffffc020011e:	64e2                	ld	s1,24(sp)
ffffffffc0200120:	6942                	ld	s2,16(sp)
ffffffffc0200122:	69a2                	ld	s3,8(sp)
            return NULL;
ffffffffc0200124:	4501                	li	a0,0
}
ffffffffc0200126:	6145                	addi	sp,sp,48
ffffffffc0200128:	8082                	ret
        else if (c == '\b' && i > 0) {
ffffffffc020012a:	eb81                	bnez	a5,ffffffffc020013a <readline+0x90>
            cputchar(c);
ffffffffc020012c:	4521                	li	a0,8
        else if (c == '\b' && i > 0) {
ffffffffc020012e:	00905663          	blez	s1,ffffffffc020013a <readline+0x90>
            cputchar(c);
ffffffffc0200132:	09a000ef          	jal	ffffffffc02001cc <cputchar>
            i --;
ffffffffc0200136:	34fd                	addiw	s1,s1,-1
ffffffffc0200138:	bf69                	j	ffffffffc02000d2 <readline+0x28>
        else if (c == '\n' || c == '\r') {
ffffffffc020013a:	c291                	beqz	a3,ffffffffc020013e <readline+0x94>
ffffffffc020013c:	fa59                	bnez	a2,ffffffffc02000d2 <readline+0x28>
            cputchar(c);
ffffffffc020013e:	8522                	mv	a0,s0
ffffffffc0200140:	08c000ef          	jal	ffffffffc02001cc <cputchar>
            buf[i] = '\0';
ffffffffc0200144:	000b1517          	auipc	a0,0xb1
ffffffffc0200148:	4b450513          	addi	a0,a0,1204 # ffffffffc02b15f8 <buf>
ffffffffc020014c:	94aa                	add	s1,s1,a0
ffffffffc020014e:	00048023          	sb	zero,0(s1)
}
ffffffffc0200152:	70a2                	ld	ra,40(sp)
ffffffffc0200154:	7402                	ld	s0,32(sp)
ffffffffc0200156:	64e2                	ld	s1,24(sp)
ffffffffc0200158:	6942                	ld	s2,16(sp)
ffffffffc020015a:	69a2                	ld	s3,8(sp)
ffffffffc020015c:	6145                	addi	sp,sp,48
ffffffffc020015e:	8082                	ret

ffffffffc0200160 <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc0200160:	1101                	addi	sp,sp,-32
ffffffffc0200162:	ec06                	sd	ra,24(sp)
ffffffffc0200164:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc0200166:	3dc000ef          	jal	ffffffffc0200542 <cons_putc>
    (*cnt)++;
ffffffffc020016a:	65a2                	ld	a1,8(sp)
}
ffffffffc020016c:	60e2                	ld	ra,24(sp)
    (*cnt)++;
ffffffffc020016e:	419c                	lw	a5,0(a1)
ffffffffc0200170:	2785                	addiw	a5,a5,1
ffffffffc0200172:	c19c                	sw	a5,0(a1)
}
ffffffffc0200174:	6105                	addi	sp,sp,32
ffffffffc0200176:	8082                	ret

ffffffffc0200178 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200178:	1101                	addi	sp,sp,-32
ffffffffc020017a:	862a                	mv	a2,a0
ffffffffc020017c:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017e:	00000517          	auipc	a0,0x0
ffffffffc0200182:	fe250513          	addi	a0,a0,-30 # ffffffffc0200160 <cputch>
ffffffffc0200186:	006c                	addi	a1,sp,12
{
ffffffffc0200188:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020018a:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020018c:	468050ef          	jal	ffffffffc02055f4 <vprintfmt>
    return cnt;
}
ffffffffc0200190:	60e2                	ld	ra,24(sp)
ffffffffc0200192:	4532                	lw	a0,12(sp)
ffffffffc0200194:	6105                	addi	sp,sp,32
ffffffffc0200196:	8082                	ret

ffffffffc0200198 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200198:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020019a:	02810313          	addi	t1,sp,40
{
ffffffffc020019e:	f42e                	sd	a1,40(sp)
ffffffffc02001a0:	f832                	sd	a2,48(sp)
ffffffffc02001a2:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a4:	862a                	mv	a2,a0
ffffffffc02001a6:	004c                	addi	a1,sp,4
ffffffffc02001a8:	00000517          	auipc	a0,0x0
ffffffffc02001ac:	fb850513          	addi	a0,a0,-72 # ffffffffc0200160 <cputch>
ffffffffc02001b0:	869a                	mv	a3,t1
{
ffffffffc02001b2:	ec06                	sd	ra,24(sp)
ffffffffc02001b4:	e0ba                	sd	a4,64(sp)
ffffffffc02001b6:	e4be                	sd	a5,72(sp)
ffffffffc02001b8:	e8c2                	sd	a6,80(sp)
ffffffffc02001ba:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc02001bc:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc02001be:	e41a                	sd	t1,8(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001c0:	434050ef          	jal	ffffffffc02055f4 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c4:	60e2                	ld	ra,24(sp)
ffffffffc02001c6:	4512                	lw	a0,4(sp)
ffffffffc02001c8:	6125                	addi	sp,sp,96
ffffffffc02001ca:	8082                	ret

ffffffffc02001cc <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001cc:	ae9d                	j	ffffffffc0200542 <cons_putc>

ffffffffc02001ce <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001ce:	1101                	addi	sp,sp,-32
ffffffffc02001d0:	e822                	sd	s0,16(sp)
ffffffffc02001d2:	ec06                	sd	ra,24(sp)
ffffffffc02001d4:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001d6:	00054503          	lbu	a0,0(a0)
ffffffffc02001da:	c51d                	beqz	a0,ffffffffc0200208 <cputs+0x3a>
ffffffffc02001dc:	e426                	sd	s1,8(sp)
ffffffffc02001de:	0405                	addi	s0,s0,1
    int cnt = 0;
ffffffffc02001e0:	4481                	li	s1,0
    cons_putc(c);
ffffffffc02001e2:	360000ef          	jal	ffffffffc0200542 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001e6:	00044503          	lbu	a0,0(s0)
ffffffffc02001ea:	0405                	addi	s0,s0,1
ffffffffc02001ec:	87a6                	mv	a5,s1
    (*cnt)++;
ffffffffc02001ee:	2485                	addiw	s1,s1,1
    while ((c = *str++) != '\0')
ffffffffc02001f0:	f96d                	bnez	a0,ffffffffc02001e2 <cputs+0x14>
    cons_putc(c);
ffffffffc02001f2:	4529                	li	a0,10
    (*cnt)++;
ffffffffc02001f4:	0027841b          	addiw	s0,a5,2
ffffffffc02001f8:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001fa:	348000ef          	jal	ffffffffc0200542 <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001fe:	60e2                	ld	ra,24(sp)
ffffffffc0200200:	8522                	mv	a0,s0
ffffffffc0200202:	6442                	ld	s0,16(sp)
ffffffffc0200204:	6105                	addi	sp,sp,32
ffffffffc0200206:	8082                	ret
    cons_putc(c);
ffffffffc0200208:	4529                	li	a0,10
ffffffffc020020a:	338000ef          	jal	ffffffffc0200542 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc020020e:	4405                	li	s0,1
}
ffffffffc0200210:	60e2                	ld	ra,24(sp)
ffffffffc0200212:	8522                	mv	a0,s0
ffffffffc0200214:	6442                	ld	s0,16(sp)
ffffffffc0200216:	6105                	addi	sp,sp,32
ffffffffc0200218:	8082                	ret

ffffffffc020021a <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc020021a:	1141                	addi	sp,sp,-16
ffffffffc020021c:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020021e:	358000ef          	jal	ffffffffc0200576 <cons_getc>
ffffffffc0200222:	dd75                	beqz	a0,ffffffffc020021e <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200224:	60a2                	ld	ra,8(sp)
ffffffffc0200226:	0141                	addi	sp,sp,16
ffffffffc0200228:	8082                	ret

ffffffffc020022a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020022a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020022c:	00006517          	auipc	a0,0x6
ffffffffc0200230:	83c50513          	addi	a0,a0,-1988 # ffffffffc0205a68 <etext+0x30>
void print_kerninfo(void) {
ffffffffc0200234:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200236:	f63ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020023a:	00000597          	auipc	a1,0x0
ffffffffc020023e:	e1058593          	addi	a1,a1,-496 # ffffffffc020004a <kern_init>
ffffffffc0200242:	00006517          	auipc	a0,0x6
ffffffffc0200246:	84650513          	addi	a0,a0,-1978 # ffffffffc0205a88 <etext+0x50>
ffffffffc020024a:	f4fff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020024e:	00005597          	auipc	a1,0x5
ffffffffc0200252:	7ea58593          	addi	a1,a1,2026 # ffffffffc0205a38 <etext>
ffffffffc0200256:	00006517          	auipc	a0,0x6
ffffffffc020025a:	85250513          	addi	a0,a0,-1966 # ffffffffc0205aa8 <etext+0x70>
ffffffffc020025e:	f3bff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200262:	000b1597          	auipc	a1,0xb1
ffffffffc0200266:	39658593          	addi	a1,a1,918 # ffffffffc02b15f8 <buf>
ffffffffc020026a:	00006517          	auipc	a0,0x6
ffffffffc020026e:	85e50513          	addi	a0,a0,-1954 # ffffffffc0205ac8 <etext+0x90>
ffffffffc0200272:	f27ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200276:	000b6597          	auipc	a1,0xb6
ffffffffc020027a:	86a58593          	addi	a1,a1,-1942 # ffffffffc02b5ae0 <end>
ffffffffc020027e:	00006517          	auipc	a0,0x6
ffffffffc0200282:	86a50513          	addi	a0,a0,-1942 # ffffffffc0205ae8 <etext+0xb0>
ffffffffc0200286:	f13ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020028a:	00000717          	auipc	a4,0x0
ffffffffc020028e:	dc070713          	addi	a4,a4,-576 # ffffffffc020004a <kern_init>
ffffffffc0200292:	000b6797          	auipc	a5,0xb6
ffffffffc0200296:	c4d78793          	addi	a5,a5,-947 # ffffffffc02b5edf <end+0x3ff>
ffffffffc020029a:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020029c:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02002a0:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002a2:	3ff5f593          	andi	a1,a1,1023
ffffffffc02002a6:	95be                	add	a1,a1,a5
ffffffffc02002a8:	85a9                	srai	a1,a1,0xa
ffffffffc02002aa:	00006517          	auipc	a0,0x6
ffffffffc02002ae:	85e50513          	addi	a0,a0,-1954 # ffffffffc0205b08 <etext+0xd0>
}
ffffffffc02002b2:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002b4:	b5d5                	j	ffffffffc0200198 <cprintf>

ffffffffc02002b6 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02002b6:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002b8:	00006617          	auipc	a2,0x6
ffffffffc02002bc:	88060613          	addi	a2,a2,-1920 # ffffffffc0205b38 <etext+0x100>
ffffffffc02002c0:	04d00593          	li	a1,77
ffffffffc02002c4:	00006517          	auipc	a0,0x6
ffffffffc02002c8:	88c50513          	addi	a0,a0,-1908 # ffffffffc0205b50 <etext+0x118>
void print_stackframe(void) {
ffffffffc02002cc:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002ce:	17c000ef          	jal	ffffffffc020044a <__panic>

ffffffffc02002d2 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002d2:	1101                	addi	sp,sp,-32
ffffffffc02002d4:	e822                	sd	s0,16(sp)
ffffffffc02002d6:	e426                	sd	s1,8(sp)
ffffffffc02002d8:	ec06                	sd	ra,24(sp)
ffffffffc02002da:	00007417          	auipc	s0,0x7
ffffffffc02002de:	5b640413          	addi	s0,s0,1462 # ffffffffc0207890 <commands>
ffffffffc02002e2:	00007497          	auipc	s1,0x7
ffffffffc02002e6:	5f648493          	addi	s1,s1,1526 # ffffffffc02078d8 <commands+0x48>
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002ea:	6410                	ld	a2,8(s0)
ffffffffc02002ec:	600c                	ld	a1,0(s0)
ffffffffc02002ee:	00006517          	auipc	a0,0x6
ffffffffc02002f2:	87a50513          	addi	a0,a0,-1926 # ffffffffc0205b68 <etext+0x130>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f6:	0461                	addi	s0,s0,24
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002f8:	ea1ff0ef          	jal	ffffffffc0200198 <cprintf>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002fc:	fe9417e3          	bne	s0,s1,ffffffffc02002ea <mon_help+0x18>
    }
    return 0;
}
ffffffffc0200300:	60e2                	ld	ra,24(sp)
ffffffffc0200302:	6442                	ld	s0,16(sp)
ffffffffc0200304:	64a2                	ld	s1,8(sp)
ffffffffc0200306:	4501                	li	a0,0
ffffffffc0200308:	6105                	addi	sp,sp,32
ffffffffc020030a:	8082                	ret

ffffffffc020030c <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020030c:	1141                	addi	sp,sp,-16
ffffffffc020030e:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200310:	f1bff0ef          	jal	ffffffffc020022a <print_kerninfo>
    return 0;
}
ffffffffc0200314:	60a2                	ld	ra,8(sp)
ffffffffc0200316:	4501                	li	a0,0
ffffffffc0200318:	0141                	addi	sp,sp,16
ffffffffc020031a:	8082                	ret

ffffffffc020031c <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020031c:	1141                	addi	sp,sp,-16
ffffffffc020031e:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200320:	f97ff0ef          	jal	ffffffffc02002b6 <print_stackframe>
    return 0;
}
ffffffffc0200324:	60a2                	ld	ra,8(sp)
ffffffffc0200326:	4501                	li	a0,0
ffffffffc0200328:	0141                	addi	sp,sp,16
ffffffffc020032a:	8082                	ret

ffffffffc020032c <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020032c:	7131                	addi	sp,sp,-192
ffffffffc020032e:	e952                	sd	s4,144(sp)
ffffffffc0200330:	8a2a                	mv	s4,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200332:	00006517          	auipc	a0,0x6
ffffffffc0200336:	84650513          	addi	a0,a0,-1978 # ffffffffc0205b78 <etext+0x140>
kmonitor(struct trapframe *tf) {
ffffffffc020033a:	fd06                	sd	ra,184(sp)
ffffffffc020033c:	f922                	sd	s0,176(sp)
ffffffffc020033e:	f526                	sd	s1,168(sp)
ffffffffc0200340:	ed4e                	sd	s3,152(sp)
ffffffffc0200342:	e556                	sd	s5,136(sp)
ffffffffc0200344:	e15a                	sd	s6,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200346:	e53ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020034a:	00006517          	auipc	a0,0x6
ffffffffc020034e:	85650513          	addi	a0,a0,-1962 # ffffffffc0205ba0 <etext+0x168>
ffffffffc0200352:	e47ff0ef          	jal	ffffffffc0200198 <cprintf>
    if (tf != NULL) {
ffffffffc0200356:	000a0563          	beqz	s4,ffffffffc0200360 <kmonitor+0x34>
        print_trapframe(tf);
ffffffffc020035a:	8552                	mv	a0,s4
ffffffffc020035c:	792000ef          	jal	ffffffffc0200aee <print_trapframe>
ffffffffc0200360:	00007a97          	auipc	s5,0x7
ffffffffc0200364:	530a8a93          	addi	s5,s5,1328 # ffffffffc0207890 <commands>
        if (argc == MAXARGS - 1) {
ffffffffc0200368:	49bd                	li	s3,15
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020036a:	00006517          	auipc	a0,0x6
ffffffffc020036e:	85e50513          	addi	a0,a0,-1954 # ffffffffc0205bc8 <etext+0x190>
ffffffffc0200372:	d39ff0ef          	jal	ffffffffc02000aa <readline>
ffffffffc0200376:	842a                	mv	s0,a0
ffffffffc0200378:	d96d                	beqz	a0,ffffffffc020036a <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020037a:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020037e:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200380:	e99d                	bnez	a1,ffffffffc02003b6 <kmonitor+0x8a>
    int argc = 0;
ffffffffc0200382:	8b26                	mv	s6,s1
    if (argc == 0) {
ffffffffc0200384:	fe0b03e3          	beqz	s6,ffffffffc020036a <kmonitor+0x3e>
ffffffffc0200388:	00007497          	auipc	s1,0x7
ffffffffc020038c:	50848493          	addi	s1,s1,1288 # ffffffffc0207890 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200390:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200392:	6582                	ld	a1,0(sp)
ffffffffc0200394:	6088                	ld	a0,0(s1)
ffffffffc0200396:	60a050ef          	jal	ffffffffc02059a0 <strcmp>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020039a:	478d                	li	a5,3
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020039c:	c149                	beqz	a0,ffffffffc020041e <kmonitor+0xf2>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020039e:	2405                	addiw	s0,s0,1
ffffffffc02003a0:	04e1                	addi	s1,s1,24
ffffffffc02003a2:	fef418e3          	bne	s0,a5,ffffffffc0200392 <kmonitor+0x66>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003a6:	6582                	ld	a1,0(sp)
ffffffffc02003a8:	00006517          	auipc	a0,0x6
ffffffffc02003ac:	85050513          	addi	a0,a0,-1968 # ffffffffc0205bf8 <etext+0x1c0>
ffffffffc02003b0:	de9ff0ef          	jal	ffffffffc0200198 <cprintf>
    return 0;
ffffffffc02003b4:	bf5d                	j	ffffffffc020036a <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003b6:	00006517          	auipc	a0,0x6
ffffffffc02003ba:	81a50513          	addi	a0,a0,-2022 # ffffffffc0205bd0 <etext+0x198>
ffffffffc02003be:	63e050ef          	jal	ffffffffc02059fc <strchr>
ffffffffc02003c2:	c901                	beqz	a0,ffffffffc02003d2 <kmonitor+0xa6>
ffffffffc02003c4:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003c8:	00040023          	sb	zero,0(s0)
ffffffffc02003cc:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003ce:	d9d5                	beqz	a1,ffffffffc0200382 <kmonitor+0x56>
ffffffffc02003d0:	b7dd                	j	ffffffffc02003b6 <kmonitor+0x8a>
        if (*buf == '\0') {
ffffffffc02003d2:	00044783          	lbu	a5,0(s0)
ffffffffc02003d6:	d7d5                	beqz	a5,ffffffffc0200382 <kmonitor+0x56>
        if (argc == MAXARGS - 1) {
ffffffffc02003d8:	03348b63          	beq	s1,s3,ffffffffc020040e <kmonitor+0xe2>
        argv[argc ++] = buf;
ffffffffc02003dc:	00349793          	slli	a5,s1,0x3
ffffffffc02003e0:	978a                	add	a5,a5,sp
ffffffffc02003e2:	e380                	sd	s0,0(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003e4:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003e8:	2485                	addiw	s1,s1,1
ffffffffc02003ea:	8b26                	mv	s6,s1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003ec:	e591                	bnez	a1,ffffffffc02003f8 <kmonitor+0xcc>
ffffffffc02003ee:	bf59                	j	ffffffffc0200384 <kmonitor+0x58>
ffffffffc02003f0:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003f4:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003f6:	d5d1                	beqz	a1,ffffffffc0200382 <kmonitor+0x56>
ffffffffc02003f8:	00005517          	auipc	a0,0x5
ffffffffc02003fc:	7d850513          	addi	a0,a0,2008 # ffffffffc0205bd0 <etext+0x198>
ffffffffc0200400:	5fc050ef          	jal	ffffffffc02059fc <strchr>
ffffffffc0200404:	d575                	beqz	a0,ffffffffc02003f0 <kmonitor+0xc4>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200406:	00044583          	lbu	a1,0(s0)
ffffffffc020040a:	dda5                	beqz	a1,ffffffffc0200382 <kmonitor+0x56>
ffffffffc020040c:	b76d                	j	ffffffffc02003b6 <kmonitor+0x8a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020040e:	45c1                	li	a1,16
ffffffffc0200410:	00005517          	auipc	a0,0x5
ffffffffc0200414:	7c850513          	addi	a0,a0,1992 # ffffffffc0205bd8 <etext+0x1a0>
ffffffffc0200418:	d81ff0ef          	jal	ffffffffc0200198 <cprintf>
ffffffffc020041c:	b7c1                	j	ffffffffc02003dc <kmonitor+0xb0>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020041e:	00141793          	slli	a5,s0,0x1
ffffffffc0200422:	97a2                	add	a5,a5,s0
ffffffffc0200424:	078e                	slli	a5,a5,0x3
ffffffffc0200426:	97d6                	add	a5,a5,s5
ffffffffc0200428:	6b9c                	ld	a5,16(a5)
ffffffffc020042a:	fffb051b          	addiw	a0,s6,-1
ffffffffc020042e:	8652                	mv	a2,s4
ffffffffc0200430:	002c                	addi	a1,sp,8
ffffffffc0200432:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200434:	f2055be3          	bgez	a0,ffffffffc020036a <kmonitor+0x3e>
}
ffffffffc0200438:	70ea                	ld	ra,184(sp)
ffffffffc020043a:	744a                	ld	s0,176(sp)
ffffffffc020043c:	74aa                	ld	s1,168(sp)
ffffffffc020043e:	69ea                	ld	s3,152(sp)
ffffffffc0200440:	6a4a                	ld	s4,144(sp)
ffffffffc0200442:	6aaa                	ld	s5,136(sp)
ffffffffc0200444:	6b0a                	ld	s6,128(sp)
ffffffffc0200446:	6129                	addi	sp,sp,192
ffffffffc0200448:	8082                	ret

ffffffffc020044a <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc020044a:	000b5317          	auipc	t1,0xb5
ffffffffc020044e:	60633303          	ld	t1,1542(t1) # ffffffffc02b5a50 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200452:	715d                	addi	sp,sp,-80
ffffffffc0200454:	ec06                	sd	ra,24(sp)
ffffffffc0200456:	f436                	sd	a3,40(sp)
ffffffffc0200458:	f83a                	sd	a4,48(sp)
ffffffffc020045a:	fc3e                	sd	a5,56(sp)
ffffffffc020045c:	e0c2                	sd	a6,64(sp)
ffffffffc020045e:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200460:	02031e63          	bnez	t1,ffffffffc020049c <__panic+0x52>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200464:	4705                	li	a4,1

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200466:	103c                	addi	a5,sp,40
ffffffffc0200468:	e822                	sd	s0,16(sp)
ffffffffc020046a:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020046c:	862e                	mv	a2,a1
ffffffffc020046e:	85aa                	mv	a1,a0
ffffffffc0200470:	00006517          	auipc	a0,0x6
ffffffffc0200474:	83050513          	addi	a0,a0,-2000 # ffffffffc0205ca0 <etext+0x268>
    is_panic = 1;
ffffffffc0200478:	000b5697          	auipc	a3,0xb5
ffffffffc020047c:	5ce6bc23          	sd	a4,1496(a3) # ffffffffc02b5a50 <is_panic>
    va_start(ap, fmt);
ffffffffc0200480:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200482:	d17ff0ef          	jal	ffffffffc0200198 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200486:	65a2                	ld	a1,8(sp)
ffffffffc0200488:	8522                	mv	a0,s0
ffffffffc020048a:	cefff0ef          	jal	ffffffffc0200178 <vcprintf>
    cprintf("\n");
ffffffffc020048e:	00007517          	auipc	a0,0x7
ffffffffc0200492:	8b250513          	addi	a0,a0,-1870 # ffffffffc0206d40 <etext+0x1308>
ffffffffc0200496:	d03ff0ef          	jal	ffffffffc0200198 <cprintf>
ffffffffc020049a:	6442                	ld	s0,16(sp)
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc020049c:	4501                	li	a0,0
ffffffffc020049e:	4581                	li	a1,0
ffffffffc02004a0:	4601                	li	a2,0
ffffffffc02004a2:	48a1                	li	a7,8
ffffffffc02004a4:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004a8:	456000ef          	jal	ffffffffc02008fe <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004ac:	4501                	li	a0,0
ffffffffc02004ae:	e7fff0ef          	jal	ffffffffc020032c <kmonitor>
    while (1) {
ffffffffc02004b2:	bfed                	j	ffffffffc02004ac <__panic+0x62>

ffffffffc02004b4 <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004b4:	715d                	addi	sp,sp,-80
ffffffffc02004b6:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b8:	02810313          	addi	t1,sp,40
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004bc:	8432                	mv	s0,a2
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004be:	862e                	mv	a2,a1
ffffffffc02004c0:	85aa                	mv	a1,a0
ffffffffc02004c2:	00005517          	auipc	a0,0x5
ffffffffc02004c6:	7fe50513          	addi	a0,a0,2046 # ffffffffc0205cc0 <etext+0x288>
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004ca:	ec06                	sd	ra,24(sp)
ffffffffc02004cc:	f436                	sd	a3,40(sp)
ffffffffc02004ce:	f83a                	sd	a4,48(sp)
ffffffffc02004d0:	fc3e                	sd	a5,56(sp)
ffffffffc02004d2:	e0c2                	sd	a6,64(sp)
ffffffffc02004d4:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02004d6:	e41a                	sd	t1,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004d8:	cc1ff0ef          	jal	ffffffffc0200198 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004dc:	65a2                	ld	a1,8(sp)
ffffffffc02004de:	8522                	mv	a0,s0
ffffffffc02004e0:	c99ff0ef          	jal	ffffffffc0200178 <vcprintf>
    cprintf("\n");
ffffffffc02004e4:	00007517          	auipc	a0,0x7
ffffffffc02004e8:	85c50513          	addi	a0,a0,-1956 # ffffffffc0206d40 <etext+0x1308>
ffffffffc02004ec:	cadff0ef          	jal	ffffffffc0200198 <cprintf>
    va_end(ap);
}
ffffffffc02004f0:	60e2                	ld	ra,24(sp)
ffffffffc02004f2:	6442                	ld	s0,16(sp)
ffffffffc02004f4:	6161                	addi	sp,sp,80
ffffffffc02004f6:	8082                	ret

ffffffffc02004f8 <clock_init>:
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void)
{
    set_csr(sie, MIP_STIP);
ffffffffc02004f8:	02000793          	li	a5,32
ffffffffc02004fc:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200500:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200504:	67e1                	lui	a5,0x18
ffffffffc0200506:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_matrix_out_size+0xd120>
ffffffffc020050a:	953e                	add	a0,a0,a5
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020050c:	4581                	li	a1,0
ffffffffc020050e:	4601                	li	a2,0
ffffffffc0200510:	4881                	li	a7,0
ffffffffc0200512:	00000073          	ecall
    cprintf("++ setup timer interrupts\n");
ffffffffc0200516:	00005517          	auipc	a0,0x5
ffffffffc020051a:	7ca50513          	addi	a0,a0,1994 # ffffffffc0205ce0 <etext+0x2a8>
    ticks = 0;
ffffffffc020051e:	000b5797          	auipc	a5,0xb5
ffffffffc0200522:	5207bd23          	sd	zero,1338(a5) # ffffffffc02b5a58 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200526:	b98d                	j	ffffffffc0200198 <cprintf>

ffffffffc0200528 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200528:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020052c:	67e1                	lui	a5,0x18
ffffffffc020052e:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_matrix_out_size+0xd120>
ffffffffc0200532:	953e                	add	a0,a0,a5
ffffffffc0200534:	4581                	li	a1,0
ffffffffc0200536:	4601                	li	a2,0
ffffffffc0200538:	4881                	li	a7,0
ffffffffc020053a:	00000073          	ecall
ffffffffc020053e:	8082                	ret

ffffffffc0200540 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200540:	8082                	ret

ffffffffc0200542 <cons_putc>:
#include <assert.h>
#include <atomic.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200542:	100027f3          	csrr	a5,sstatus
ffffffffc0200546:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200548:	0ff57513          	zext.b	a0,a0
ffffffffc020054c:	e799                	bnez	a5,ffffffffc020055a <cons_putc+0x18>
ffffffffc020054e:	4581                	li	a1,0
ffffffffc0200550:	4601                	li	a2,0
ffffffffc0200552:	4885                	li	a7,1
ffffffffc0200554:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc0200558:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc020055a:	1101                	addi	sp,sp,-32
ffffffffc020055c:	ec06                	sd	ra,24(sp)
ffffffffc020055e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200560:	39e000ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0200564:	6522                	ld	a0,8(sp)
ffffffffc0200566:	4581                	li	a1,0
ffffffffc0200568:	4601                	li	a2,0
ffffffffc020056a:	4885                	li	a7,1
ffffffffc020056c:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200570:	60e2                	ld	ra,24(sp)
ffffffffc0200572:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc0200574:	a651                	j	ffffffffc02008f8 <intr_enable>

ffffffffc0200576 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200576:	100027f3          	csrr	a5,sstatus
ffffffffc020057a:	8b89                	andi	a5,a5,2
ffffffffc020057c:	eb89                	bnez	a5,ffffffffc020058e <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc020057e:	4501                	li	a0,0
ffffffffc0200580:	4581                	li	a1,0
ffffffffc0200582:	4601                	li	a2,0
ffffffffc0200584:	4889                	li	a7,2
ffffffffc0200586:	00000073          	ecall
ffffffffc020058a:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc020058c:	8082                	ret
int cons_getc(void) {
ffffffffc020058e:	1101                	addi	sp,sp,-32
ffffffffc0200590:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200592:	36c000ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0200596:	4501                	li	a0,0
ffffffffc0200598:	4581                	li	a1,0
ffffffffc020059a:	4601                	li	a2,0
ffffffffc020059c:	4889                	li	a7,2
ffffffffc020059e:	00000073          	ecall
ffffffffc02005a2:	2501                	sext.w	a0,a0
ffffffffc02005a4:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005a6:	352000ef          	jal	ffffffffc02008f8 <intr_enable>
}
ffffffffc02005aa:	60e2                	ld	ra,24(sp)
ffffffffc02005ac:	6522                	ld	a0,8(sp)
ffffffffc02005ae:	6105                	addi	sp,sp,32
ffffffffc02005b0:	8082                	ret

ffffffffc02005b2 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005b2:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc02005b4:	00005517          	auipc	a0,0x5
ffffffffc02005b8:	74c50513          	addi	a0,a0,1868 # ffffffffc0205d00 <etext+0x2c8>
void dtb_init(void) {
ffffffffc02005bc:	f406                	sd	ra,40(sp)
ffffffffc02005be:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc02005c0:	bd9ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005c4:	0000c597          	auipc	a1,0xc
ffffffffc02005c8:	a3c5b583          	ld	a1,-1476(a1) # ffffffffc020c000 <boot_hartid>
ffffffffc02005cc:	00005517          	auipc	a0,0x5
ffffffffc02005d0:	74450513          	addi	a0,a0,1860 # ffffffffc0205d10 <etext+0x2d8>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005d4:	0000c417          	auipc	s0,0xc
ffffffffc02005d8:	a3440413          	addi	s0,s0,-1484 # ffffffffc020c008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005dc:	bbdff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005e0:	600c                	ld	a1,0(s0)
ffffffffc02005e2:	00005517          	auipc	a0,0x5
ffffffffc02005e6:	73e50513          	addi	a0,a0,1854 # ffffffffc0205d20 <etext+0x2e8>
ffffffffc02005ea:	bafff0ef          	jal	ffffffffc0200198 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02005ee:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02005f0:	00005517          	auipc	a0,0x5
ffffffffc02005f4:	74850513          	addi	a0,a0,1864 # ffffffffc0205d38 <etext+0x300>
    if (boot_dtb == 0) {
ffffffffc02005f8:	10070163          	beqz	a4,ffffffffc02006fa <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02005fc:	57f5                	li	a5,-3
ffffffffc02005fe:	07fa                	slli	a5,a5,0x1e
ffffffffc0200600:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200602:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc0200604:	d00e06b7          	lui	a3,0xd00e0
ffffffffc0200608:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfe2a40d>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020060c:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200610:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200614:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200618:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020061c:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200620:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200622:	8e49                	or	a2,a2,a0
ffffffffc0200624:	0ff7f793          	zext.b	a5,a5
ffffffffc0200628:	8dd1                	or	a1,a1,a2
ffffffffc020062a:	07a2                	slli	a5,a5,0x8
ffffffffc020062c:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020062e:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc0200632:	0cd59863          	bne	a1,a3,ffffffffc0200702 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc0200636:	4710                	lw	a2,8(a4)
ffffffffc0200638:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020063a:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020063c:	0086541b          	srliw	s0,a2,0x8
ffffffffc0200640:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200644:	01865e1b          	srliw	t3,a2,0x18
ffffffffc0200648:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020064c:	0186151b          	slliw	a0,a2,0x18
ffffffffc0200650:	0186959b          	slliw	a1,a3,0x18
ffffffffc0200654:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200658:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020065c:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200660:	0106d69b          	srliw	a3,a3,0x10
ffffffffc0200664:	01c56533          	or	a0,a0,t3
ffffffffc0200668:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066c:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200670:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200674:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200678:	0ff6f693          	zext.b	a3,a3
ffffffffc020067c:	8c49                	or	s0,s0,a0
ffffffffc020067e:	0622                	slli	a2,a2,0x8
ffffffffc0200680:	8fcd                	or	a5,a5,a1
ffffffffc0200682:	06a2                	slli	a3,a3,0x8
ffffffffc0200684:	8c51                	or	s0,s0,a2
ffffffffc0200686:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200688:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020068a:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020068c:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020068e:	9381                	srli	a5,a5,0x20
ffffffffc0200690:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200692:	4301                	li	t1,0
        switch (token) {
ffffffffc0200694:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200696:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200698:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc020069c:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020069e:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a0:	0087579b          	srliw	a5,a4,0x8
ffffffffc02006a4:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006a8:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ac:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b0:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b4:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b8:	8ed1                	or	a3,a3,a2
ffffffffc02006ba:	0ff77713          	zext.b	a4,a4
ffffffffc02006be:	8fd5                	or	a5,a5,a3
ffffffffc02006c0:	0722                	slli	a4,a4,0x8
ffffffffc02006c2:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc02006c4:	05178763          	beq	a5,a7,ffffffffc0200712 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006c8:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc02006ca:	00f8e963          	bltu	a7,a5,ffffffffc02006dc <dtb_init+0x12a>
ffffffffc02006ce:	07c78d63          	beq	a5,t3,ffffffffc0200748 <dtb_init+0x196>
ffffffffc02006d2:	4709                	li	a4,2
ffffffffc02006d4:	00e79763          	bne	a5,a4,ffffffffc02006e2 <dtb_init+0x130>
ffffffffc02006d8:	4301                	li	t1,0
ffffffffc02006da:	b7d1                	j	ffffffffc020069e <dtb_init+0xec>
ffffffffc02006dc:	4711                	li	a4,4
ffffffffc02006de:	fce780e3          	beq	a5,a4,ffffffffc020069e <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02006e2:	00005517          	auipc	a0,0x5
ffffffffc02006e6:	71e50513          	addi	a0,a0,1822 # ffffffffc0205e00 <etext+0x3c8>
ffffffffc02006ea:	aafff0ef          	jal	ffffffffc0200198 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02006ee:	64e2                	ld	s1,24(sp)
ffffffffc02006f0:	6942                	ld	s2,16(sp)
ffffffffc02006f2:	00005517          	auipc	a0,0x5
ffffffffc02006f6:	74650513          	addi	a0,a0,1862 # ffffffffc0205e38 <etext+0x400>
}
ffffffffc02006fa:	7402                	ld	s0,32(sp)
ffffffffc02006fc:	70a2                	ld	ra,40(sp)
ffffffffc02006fe:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc0200700:	bc61                	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200702:	7402                	ld	s0,32(sp)
ffffffffc0200704:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200706:	00005517          	auipc	a0,0x5
ffffffffc020070a:	65250513          	addi	a0,a0,1618 # ffffffffc0205d58 <etext+0x320>
}
ffffffffc020070e:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200710:	b461                	j	ffffffffc0200198 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200712:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200714:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200718:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020071c:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200720:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200724:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200728:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020072c:	8ed1                	or	a3,a3,a2
ffffffffc020072e:	0ff77713          	zext.b	a4,a4
ffffffffc0200732:	8fd5                	or	a5,a5,a3
ffffffffc0200734:	0722                	slli	a4,a4,0x8
ffffffffc0200736:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200738:	04031463          	bnez	t1,ffffffffc0200780 <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc020073c:	1782                	slli	a5,a5,0x20
ffffffffc020073e:	9381                	srli	a5,a5,0x20
ffffffffc0200740:	043d                	addi	s0,s0,15
ffffffffc0200742:	943e                	add	s0,s0,a5
ffffffffc0200744:	9871                	andi	s0,s0,-4
                break;
ffffffffc0200746:	bfa1                	j	ffffffffc020069e <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc0200748:	8522                	mv	a0,s0
ffffffffc020074a:	e01a                	sd	t1,0(sp)
ffffffffc020074c:	20e050ef          	jal	ffffffffc020595a <strlen>
ffffffffc0200750:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200752:	4619                	li	a2,6
ffffffffc0200754:	8522                	mv	a0,s0
ffffffffc0200756:	00005597          	auipc	a1,0x5
ffffffffc020075a:	62a58593          	addi	a1,a1,1578 # ffffffffc0205d80 <etext+0x348>
ffffffffc020075e:	276050ef          	jal	ffffffffc02059d4 <strncmp>
ffffffffc0200762:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200764:	0411                	addi	s0,s0,4
ffffffffc0200766:	0004879b          	sext.w	a5,s1
ffffffffc020076a:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020076c:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200770:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200772:	00a36333          	or	t1,t1,a0
                break;
ffffffffc0200776:	00ff0837          	lui	a6,0xff0
ffffffffc020077a:	488d                	li	a7,3
ffffffffc020077c:	4e05                	li	t3,1
ffffffffc020077e:	b705                	j	ffffffffc020069e <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200780:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200782:	00005597          	auipc	a1,0x5
ffffffffc0200786:	60658593          	addi	a1,a1,1542 # ffffffffc0205d88 <etext+0x350>
ffffffffc020078a:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020078c:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200790:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200794:	0187169b          	slliw	a3,a4,0x18
ffffffffc0200798:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020079c:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007a0:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007a4:	8ed1                	or	a3,a3,a2
ffffffffc02007a6:	0ff77713          	zext.b	a4,a4
ffffffffc02007aa:	0722                	slli	a4,a4,0x8
ffffffffc02007ac:	8d55                	or	a0,a0,a3
ffffffffc02007ae:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02007b0:	1502                	slli	a0,a0,0x20
ffffffffc02007b2:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007b4:	954a                	add	a0,a0,s2
ffffffffc02007b6:	e01a                	sd	t1,0(sp)
ffffffffc02007b8:	1e8050ef          	jal	ffffffffc02059a0 <strcmp>
ffffffffc02007bc:	67a2                	ld	a5,8(sp)
ffffffffc02007be:	473d                	li	a4,15
ffffffffc02007c0:	6302                	ld	t1,0(sp)
ffffffffc02007c2:	00ff0837          	lui	a6,0xff0
ffffffffc02007c6:	488d                	li	a7,3
ffffffffc02007c8:	4e05                	li	t3,1
ffffffffc02007ca:	f6f779e3          	bgeu	a4,a5,ffffffffc020073c <dtb_init+0x18a>
ffffffffc02007ce:	f53d                	bnez	a0,ffffffffc020073c <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02007d0:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02007d4:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007d8:	00005517          	auipc	a0,0x5
ffffffffc02007dc:	5b850513          	addi	a0,a0,1464 # ffffffffc0205d90 <etext+0x358>
           fdt32_to_cpu(x >> 32);
ffffffffc02007e0:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007e4:	0087d31b          	srliw	t1,a5,0x8
ffffffffc02007e8:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02007ec:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007f0:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007f4:	0187959b          	slliw	a1,a5,0x18
ffffffffc02007f8:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007fc:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200800:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200804:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200808:	01037333          	and	t1,t1,a6
ffffffffc020080c:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200810:	01e5e5b3          	or	a1,a1,t5
ffffffffc0200814:	0ff7f793          	zext.b	a5,a5
ffffffffc0200818:	01de6e33          	or	t3,t3,t4
ffffffffc020081c:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200820:	01067633          	and	a2,a2,a6
ffffffffc0200824:	0086d31b          	srliw	t1,a3,0x8
ffffffffc0200828:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020082c:	07a2                	slli	a5,a5,0x8
ffffffffc020082e:	0108d89b          	srliw	a7,a7,0x10
ffffffffc0200832:	0186df1b          	srliw	t5,a3,0x18
ffffffffc0200836:	01875e9b          	srliw	t4,a4,0x18
ffffffffc020083a:	8ddd                	or	a1,a1,a5
ffffffffc020083c:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200840:	0186979b          	slliw	a5,a3,0x18
ffffffffc0200844:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200848:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084c:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200850:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200854:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200858:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020085c:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200860:	08a2                	slli	a7,a7,0x8
ffffffffc0200862:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200866:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020086a:	0ff6f693          	zext.b	a3,a3
ffffffffc020086e:	01de6833          	or	a6,t3,t4
ffffffffc0200872:	0ff77713          	zext.b	a4,a4
ffffffffc0200876:	01166633          	or	a2,a2,a7
ffffffffc020087a:	0067e7b3          	or	a5,a5,t1
ffffffffc020087e:	06a2                	slli	a3,a3,0x8
ffffffffc0200880:	01046433          	or	s0,s0,a6
ffffffffc0200884:	0722                	slli	a4,a4,0x8
ffffffffc0200886:	8fd5                	or	a5,a5,a3
ffffffffc0200888:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc020088a:	1582                	slli	a1,a1,0x20
ffffffffc020088c:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020088e:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200890:	9201                	srli	a2,a2,0x20
ffffffffc0200892:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200894:	1402                	slli	s0,s0,0x20
ffffffffc0200896:	00b7e4b3          	or	s1,a5,a1
ffffffffc020089a:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc020089c:	8fdff0ef          	jal	ffffffffc0200198 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02008a0:	85a6                	mv	a1,s1
ffffffffc02008a2:	00005517          	auipc	a0,0x5
ffffffffc02008a6:	50e50513          	addi	a0,a0,1294 # ffffffffc0205db0 <etext+0x378>
ffffffffc02008aa:	8efff0ef          	jal	ffffffffc0200198 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02008ae:	01445613          	srli	a2,s0,0x14
ffffffffc02008b2:	85a2                	mv	a1,s0
ffffffffc02008b4:	00005517          	auipc	a0,0x5
ffffffffc02008b8:	51450513          	addi	a0,a0,1300 # ffffffffc0205dc8 <etext+0x390>
ffffffffc02008bc:	8ddff0ef          	jal	ffffffffc0200198 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02008c0:	009405b3          	add	a1,s0,s1
ffffffffc02008c4:	15fd                	addi	a1,a1,-1
ffffffffc02008c6:	00005517          	auipc	a0,0x5
ffffffffc02008ca:	52250513          	addi	a0,a0,1314 # ffffffffc0205de8 <etext+0x3b0>
ffffffffc02008ce:	8cbff0ef          	jal	ffffffffc0200198 <cprintf>
        memory_base = mem_base;
ffffffffc02008d2:	000b5797          	auipc	a5,0xb5
ffffffffc02008d6:	1897bb23          	sd	s1,406(a5) # ffffffffc02b5a68 <memory_base>
        memory_size = mem_size;
ffffffffc02008da:	000b5797          	auipc	a5,0xb5
ffffffffc02008de:	1887b323          	sd	s0,390(a5) # ffffffffc02b5a60 <memory_size>
ffffffffc02008e2:	b531                	j	ffffffffc02006ee <dtb_init+0x13c>

ffffffffc02008e4 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02008e4:	000b5517          	auipc	a0,0xb5
ffffffffc02008e8:	18453503          	ld	a0,388(a0) # ffffffffc02b5a68 <memory_base>
ffffffffc02008ec:	8082                	ret

ffffffffc02008ee <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02008ee:	000b5517          	auipc	a0,0xb5
ffffffffc02008f2:	17253503          	ld	a0,370(a0) # ffffffffc02b5a60 <memory_size>
ffffffffc02008f6:	8082                	ret

ffffffffc02008f8 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02008f8:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02008fc:	8082                	ret

ffffffffc02008fe <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02008fe:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200902:	8082                	ret

ffffffffc0200904 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc0200904:	8082                	ret

ffffffffc0200906 <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200906:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020090a:	00000797          	auipc	a5,0x0
ffffffffc020090e:	50a78793          	addi	a5,a5,1290 # ffffffffc0200e14 <__alltraps>
ffffffffc0200912:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200916:	000407b7          	lui	a5,0x40
ffffffffc020091a:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc020091e:	8082                	ret

ffffffffc0200920 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200920:	610c                	ld	a1,0(a0)
{
ffffffffc0200922:	1141                	addi	sp,sp,-16
ffffffffc0200924:	e022                	sd	s0,0(sp)
ffffffffc0200926:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200928:	00005517          	auipc	a0,0x5
ffffffffc020092c:	52850513          	addi	a0,a0,1320 # ffffffffc0205e50 <etext+0x418>
{
ffffffffc0200930:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200932:	867ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200936:	640c                	ld	a1,8(s0)
ffffffffc0200938:	00005517          	auipc	a0,0x5
ffffffffc020093c:	53050513          	addi	a0,a0,1328 # ffffffffc0205e68 <etext+0x430>
ffffffffc0200940:	859ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200944:	680c                	ld	a1,16(s0)
ffffffffc0200946:	00005517          	auipc	a0,0x5
ffffffffc020094a:	53a50513          	addi	a0,a0,1338 # ffffffffc0205e80 <etext+0x448>
ffffffffc020094e:	84bff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200952:	6c0c                	ld	a1,24(s0)
ffffffffc0200954:	00005517          	auipc	a0,0x5
ffffffffc0200958:	54450513          	addi	a0,a0,1348 # ffffffffc0205e98 <etext+0x460>
ffffffffc020095c:	83dff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200960:	700c                	ld	a1,32(s0)
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	54e50513          	addi	a0,a0,1358 # ffffffffc0205eb0 <etext+0x478>
ffffffffc020096a:	82fff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc020096e:	740c                	ld	a1,40(s0)
ffffffffc0200970:	00005517          	auipc	a0,0x5
ffffffffc0200974:	55850513          	addi	a0,a0,1368 # ffffffffc0205ec8 <etext+0x490>
ffffffffc0200978:	821ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc020097c:	780c                	ld	a1,48(s0)
ffffffffc020097e:	00005517          	auipc	a0,0x5
ffffffffc0200982:	56250513          	addi	a0,a0,1378 # ffffffffc0205ee0 <etext+0x4a8>
ffffffffc0200986:	813ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc020098a:	7c0c                	ld	a1,56(s0)
ffffffffc020098c:	00005517          	auipc	a0,0x5
ffffffffc0200990:	56c50513          	addi	a0,a0,1388 # ffffffffc0205ef8 <etext+0x4c0>
ffffffffc0200994:	805ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200998:	602c                	ld	a1,64(s0)
ffffffffc020099a:	00005517          	auipc	a0,0x5
ffffffffc020099e:	57650513          	addi	a0,a0,1398 # ffffffffc0205f10 <etext+0x4d8>
ffffffffc02009a2:	ff6ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009a6:	642c                	ld	a1,72(s0)
ffffffffc02009a8:	00005517          	auipc	a0,0x5
ffffffffc02009ac:	58050513          	addi	a0,a0,1408 # ffffffffc0205f28 <etext+0x4f0>
ffffffffc02009b0:	fe8ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009b4:	682c                	ld	a1,80(s0)
ffffffffc02009b6:	00005517          	auipc	a0,0x5
ffffffffc02009ba:	58a50513          	addi	a0,a0,1418 # ffffffffc0205f40 <etext+0x508>
ffffffffc02009be:	fdaff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009c2:	6c2c                	ld	a1,88(s0)
ffffffffc02009c4:	00005517          	auipc	a0,0x5
ffffffffc02009c8:	59450513          	addi	a0,a0,1428 # ffffffffc0205f58 <etext+0x520>
ffffffffc02009cc:	fccff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02009d0:	702c                	ld	a1,96(s0)
ffffffffc02009d2:	00005517          	auipc	a0,0x5
ffffffffc02009d6:	59e50513          	addi	a0,a0,1438 # ffffffffc0205f70 <etext+0x538>
ffffffffc02009da:	fbeff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc02009de:	742c                	ld	a1,104(s0)
ffffffffc02009e0:	00005517          	auipc	a0,0x5
ffffffffc02009e4:	5a850513          	addi	a0,a0,1448 # ffffffffc0205f88 <etext+0x550>
ffffffffc02009e8:	fb0ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc02009ec:	782c                	ld	a1,112(s0)
ffffffffc02009ee:	00005517          	auipc	a0,0x5
ffffffffc02009f2:	5b250513          	addi	a0,a0,1458 # ffffffffc0205fa0 <etext+0x568>
ffffffffc02009f6:	fa2ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc02009fa:	7c2c                	ld	a1,120(s0)
ffffffffc02009fc:	00005517          	auipc	a0,0x5
ffffffffc0200a00:	5bc50513          	addi	a0,a0,1468 # ffffffffc0205fb8 <etext+0x580>
ffffffffc0200a04:	f94ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a08:	604c                	ld	a1,128(s0)
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	5c650513          	addi	a0,a0,1478 # ffffffffc0205fd0 <etext+0x598>
ffffffffc0200a12:	f86ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a16:	644c                	ld	a1,136(s0)
ffffffffc0200a18:	00005517          	auipc	a0,0x5
ffffffffc0200a1c:	5d050513          	addi	a0,a0,1488 # ffffffffc0205fe8 <etext+0x5b0>
ffffffffc0200a20:	f78ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a24:	684c                	ld	a1,144(s0)
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	5da50513          	addi	a0,a0,1498 # ffffffffc0206000 <etext+0x5c8>
ffffffffc0200a2e:	f6aff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a32:	6c4c                	ld	a1,152(s0)
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	5e450513          	addi	a0,a0,1508 # ffffffffc0206018 <etext+0x5e0>
ffffffffc0200a3c:	f5cff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a40:	704c                	ld	a1,160(s0)
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	5ee50513          	addi	a0,a0,1518 # ffffffffc0206030 <etext+0x5f8>
ffffffffc0200a4a:	f4eff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a4e:	744c                	ld	a1,168(s0)
ffffffffc0200a50:	00005517          	auipc	a0,0x5
ffffffffc0200a54:	5f850513          	addi	a0,a0,1528 # ffffffffc0206048 <etext+0x610>
ffffffffc0200a58:	f40ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a5c:	784c                	ld	a1,176(s0)
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	60250513          	addi	a0,a0,1538 # ffffffffc0206060 <etext+0x628>
ffffffffc0200a66:	f32ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200a6a:	7c4c                	ld	a1,184(s0)
ffffffffc0200a6c:	00005517          	auipc	a0,0x5
ffffffffc0200a70:	60c50513          	addi	a0,a0,1548 # ffffffffc0206078 <etext+0x640>
ffffffffc0200a74:	f24ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200a78:	606c                	ld	a1,192(s0)
ffffffffc0200a7a:	00005517          	auipc	a0,0x5
ffffffffc0200a7e:	61650513          	addi	a0,a0,1558 # ffffffffc0206090 <etext+0x658>
ffffffffc0200a82:	f16ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200a86:	646c                	ld	a1,200(s0)
ffffffffc0200a88:	00005517          	auipc	a0,0x5
ffffffffc0200a8c:	62050513          	addi	a0,a0,1568 # ffffffffc02060a8 <etext+0x670>
ffffffffc0200a90:	f08ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200a94:	686c                	ld	a1,208(s0)
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	62a50513          	addi	a0,a0,1578 # ffffffffc02060c0 <etext+0x688>
ffffffffc0200a9e:	efaff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200aa2:	6c6c                	ld	a1,216(s0)
ffffffffc0200aa4:	00005517          	auipc	a0,0x5
ffffffffc0200aa8:	63450513          	addi	a0,a0,1588 # ffffffffc02060d8 <etext+0x6a0>
ffffffffc0200aac:	eecff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200ab0:	706c                	ld	a1,224(s0)
ffffffffc0200ab2:	00005517          	auipc	a0,0x5
ffffffffc0200ab6:	63e50513          	addi	a0,a0,1598 # ffffffffc02060f0 <etext+0x6b8>
ffffffffc0200aba:	edeff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200abe:	746c                	ld	a1,232(s0)
ffffffffc0200ac0:	00005517          	auipc	a0,0x5
ffffffffc0200ac4:	64850513          	addi	a0,a0,1608 # ffffffffc0206108 <etext+0x6d0>
ffffffffc0200ac8:	ed0ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200acc:	786c                	ld	a1,240(s0)
ffffffffc0200ace:	00005517          	auipc	a0,0x5
ffffffffc0200ad2:	65250513          	addi	a0,a0,1618 # ffffffffc0206120 <etext+0x6e8>
ffffffffc0200ad6:	ec2ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ada:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200adc:	6402                	ld	s0,0(sp)
ffffffffc0200ade:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ae0:	00005517          	auipc	a0,0x5
ffffffffc0200ae4:	65850513          	addi	a0,a0,1624 # ffffffffc0206138 <etext+0x700>
}
ffffffffc0200ae8:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200aea:	eaeff06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0200aee <print_trapframe>:
{
ffffffffc0200aee:	1141                	addi	sp,sp,-16
ffffffffc0200af0:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200af2:	85aa                	mv	a1,a0
{
ffffffffc0200af4:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200af6:	00005517          	auipc	a0,0x5
ffffffffc0200afa:	65a50513          	addi	a0,a0,1626 # ffffffffc0206150 <etext+0x718>
{
ffffffffc0200afe:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b00:	e98ff0ef          	jal	ffffffffc0200198 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200b04:	8522                	mv	a0,s0
ffffffffc0200b06:	e1bff0ef          	jal	ffffffffc0200920 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200b0a:	10043583          	ld	a1,256(s0)
ffffffffc0200b0e:	00005517          	auipc	a0,0x5
ffffffffc0200b12:	65a50513          	addi	a0,a0,1626 # ffffffffc0206168 <etext+0x730>
ffffffffc0200b16:	e82ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b1a:	10843583          	ld	a1,264(s0)
ffffffffc0200b1e:	00005517          	auipc	a0,0x5
ffffffffc0200b22:	66250513          	addi	a0,a0,1634 # ffffffffc0206180 <etext+0x748>
ffffffffc0200b26:	e72ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200b2a:	11043583          	ld	a1,272(s0)
ffffffffc0200b2e:	00005517          	auipc	a0,0x5
ffffffffc0200b32:	66a50513          	addi	a0,a0,1642 # ffffffffc0206198 <etext+0x760>
ffffffffc0200b36:	e62ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b3a:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b3e:	6402                	ld	s0,0(sp)
ffffffffc0200b40:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b42:	00005517          	auipc	a0,0x5
ffffffffc0200b46:	66650513          	addi	a0,a0,1638 # ffffffffc02061a8 <etext+0x770>
}
ffffffffc0200b4a:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b4c:	e4cff06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0200b50 <interrupt_handler>:
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause)
ffffffffc0200b50:	11853783          	ld	a5,280(a0)
ffffffffc0200b54:	472d                	li	a4,11
ffffffffc0200b56:	0786                	slli	a5,a5,0x1
ffffffffc0200b58:	8385                	srli	a5,a5,0x1
ffffffffc0200b5a:	0af76363          	bltu	a4,a5,ffffffffc0200c00 <interrupt_handler+0xb0>
ffffffffc0200b5e:	00007717          	auipc	a4,0x7
ffffffffc0200b62:	d7a70713          	addi	a4,a4,-646 # ffffffffc02078d8 <commands+0x48>
ffffffffc0200b66:	078a                	slli	a5,a5,0x2
ffffffffc0200b68:	97ba                	add	a5,a5,a4
ffffffffc0200b6a:	439c                	lw	a5,0(a5)
ffffffffc0200b6c:	97ba                	add	a5,a5,a4
ffffffffc0200b6e:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200b70:	00005517          	auipc	a0,0x5
ffffffffc0200b74:	6b050513          	addi	a0,a0,1712 # ffffffffc0206220 <etext+0x7e8>
ffffffffc0200b78:	e20ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200b7c:	00005517          	auipc	a0,0x5
ffffffffc0200b80:	68450513          	addi	a0,a0,1668 # ffffffffc0206200 <etext+0x7c8>
ffffffffc0200b84:	e14ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200b88:	00005517          	auipc	a0,0x5
ffffffffc0200b8c:	63850513          	addi	a0,a0,1592 # ffffffffc02061c0 <etext+0x788>
ffffffffc0200b90:	e08ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200b94:	00005517          	auipc	a0,0x5
ffffffffc0200b98:	64c50513          	addi	a0,a0,1612 # ffffffffc02061e0 <etext+0x7a8>
ffffffffc0200b9c:	dfcff06f          	j	ffffffffc0200198 <cprintf>
{
ffffffffc0200ba0:	1141                	addi	sp,sp,-16
ffffffffc0200ba2:	e406                	sd	ra,8(sp)
        // In fact, Call sbi_set_timer will clear STIP, or you can clear it
        // directly.
        // clear_csr(sip, SIP_STIP);

        /* LAB3: clock handling */
        clock_set_next_event();
ffffffffc0200ba4:	985ff0ef          	jal	ffffffffc0200528 <clock_set_next_event>
        ticks++;
ffffffffc0200ba8:	000b5797          	auipc	a5,0xb5
ffffffffc0200bac:	eb078793          	addi	a5,a5,-336 # ffffffffc02b5a58 <ticks>
ffffffffc0200bb0:	6394                	ld	a3,0(a5)
        if (ticks % TICK_NUM == 0)
ffffffffc0200bb2:	28f5c737          	lui	a4,0x28f5c
ffffffffc0200bb6:	28f70713          	addi	a4,a4,655 # 28f5c28f <_binary_obj___user_matrix_out_size+0x28f50d0f>
        ticks++;
ffffffffc0200bba:	0685                	addi	a3,a3,1
ffffffffc0200bbc:	e394                	sd	a3,0(a5)
        if (ticks % TICK_NUM == 0)
ffffffffc0200bbe:	6390                	ld	a2,0(a5)
ffffffffc0200bc0:	5c28f6b7          	lui	a3,0x5c28f
ffffffffc0200bc4:	1702                	slli	a4,a4,0x20
ffffffffc0200bc6:	5c368693          	addi	a3,a3,1475 # 5c28f5c3 <_binary_obj___user_matrix_out_size+0x5c284043>
ffffffffc0200bca:	00265793          	srli	a5,a2,0x2
ffffffffc0200bce:	9736                	add	a4,a4,a3
ffffffffc0200bd0:	02e7b7b3          	mulhu	a5,a5,a4
ffffffffc0200bd4:	06400593          	li	a1,100
ffffffffc0200bd8:	8389                	srli	a5,a5,0x2
ffffffffc0200bda:	02b787b3          	mul	a5,a5,a1
ffffffffc0200bde:	02f60563          	beq	a2,a5,ffffffffc0200c08 <interrupt_handler+0xb8>
            {
                sbi_shutdown();
            }
        }
        /* LAB6: trigger scheduling tick */
        if (current != NULL)
ffffffffc0200be2:	000b5517          	auipc	a0,0xb5
ffffffffc0200be6:	ed653503          	ld	a0,-298(a0) # ffffffffc02b5ab8 <current>
ffffffffc0200bea:	cd01                	beqz	a0,ffffffffc0200c02 <interrupt_handler+0xb2>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200bec:	60a2                	ld	ra,8(sp)
ffffffffc0200bee:	0141                	addi	sp,sp,16
            sched_class_proc_tick(current);
ffffffffc0200bf0:	6620406f          	j	ffffffffc0205252 <sched_class_proc_tick>
        cprintf("Supervisor external interrupt\n");
ffffffffc0200bf4:	00005517          	auipc	a0,0x5
ffffffffc0200bf8:	66c50513          	addi	a0,a0,1644 # ffffffffc0206260 <etext+0x828>
ffffffffc0200bfc:	d9cff06f          	j	ffffffffc0200198 <cprintf>
        print_trapframe(tf);
ffffffffc0200c00:	b5fd                	j	ffffffffc0200aee <print_trapframe>
}
ffffffffc0200c02:	60a2                	ld	ra,8(sp)
ffffffffc0200c04:	0141                	addi	sp,sp,16
ffffffffc0200c06:	8082                	ret
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c08:	00005517          	auipc	a0,0x5
ffffffffc0200c0c:	63850513          	addi	a0,a0,1592 # ffffffffc0206240 <etext+0x808>
ffffffffc0200c10:	d88ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("End of Test.\n");
ffffffffc0200c14:	00005517          	auipc	a0,0x5
ffffffffc0200c18:	63c50513          	addi	a0,a0,1596 # ffffffffc0206250 <etext+0x818>
ffffffffc0200c1c:	d7cff0ef          	jal	ffffffffc0200198 <cprintf>
            num++;
ffffffffc0200c20:	000b5797          	auipc	a5,0xb5
ffffffffc0200c24:	e507a783          	lw	a5,-432(a5) # ffffffffc02b5a70 <num.0>
            if (num == 10)
ffffffffc0200c28:	4729                	li	a4,10
            num++;
ffffffffc0200c2a:	2785                	addiw	a5,a5,1
ffffffffc0200c2c:	000b5697          	auipc	a3,0xb5
ffffffffc0200c30:	e4f6a223          	sw	a5,-444(a3) # ffffffffc02b5a70 <num.0>
            if (num == 10)
ffffffffc0200c34:	fae797e3          	bne	a5,a4,ffffffffc0200be2 <interrupt_handler+0x92>
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200c38:	4501                	li	a0,0
ffffffffc0200c3a:	4581                	li	a1,0
ffffffffc0200c3c:	4601                	li	a2,0
ffffffffc0200c3e:	48a1                	li	a7,8
ffffffffc0200c40:	00000073          	ecall
}
ffffffffc0200c44:	bf79                	j	ffffffffc0200be2 <interrupt_handler+0x92>

ffffffffc0200c46 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200c46:	11853783          	ld	a5,280(a0)
ffffffffc0200c4a:	473d                	li	a4,15
ffffffffc0200c4c:	14f76163          	bltu	a4,a5,ffffffffc0200d8e <exception_handler+0x148>
ffffffffc0200c50:	00007717          	auipc	a4,0x7
ffffffffc0200c54:	cb870713          	addi	a4,a4,-840 # ffffffffc0207908 <commands+0x78>
ffffffffc0200c58:	078a                	slli	a5,a5,0x2
ffffffffc0200c5a:	97ba                	add	a5,a5,a4
ffffffffc0200c5c:	439c                	lw	a5,0(a5)
{
ffffffffc0200c5e:	1101                	addi	sp,sp,-32
ffffffffc0200c60:	ec06                	sd	ra,24(sp)
    switch (tf->cause)
ffffffffc0200c62:	97ba                	add	a5,a5,a4
ffffffffc0200c64:	86aa                	mv	a3,a0
ffffffffc0200c66:	8782                	jr	a5
ffffffffc0200c68:	e42a                	sd	a0,8(sp)
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200c6a:	00005517          	auipc	a0,0x5
ffffffffc0200c6e:	6fe50513          	addi	a0,a0,1790 # ffffffffc0206368 <etext+0x930>
ffffffffc0200c72:	d26ff0ef          	jal	ffffffffc0200198 <cprintf>
        tf->epc += 4;
ffffffffc0200c76:	66a2                	ld	a3,8(sp)
ffffffffc0200c78:	1086b783          	ld	a5,264(a3)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c7c:	60e2                	ld	ra,24(sp)
        tf->epc += 4;
ffffffffc0200c7e:	0791                	addi	a5,a5,4
ffffffffc0200c80:	10f6b423          	sd	a5,264(a3)
}
ffffffffc0200c84:	6105                	addi	sp,sp,32
        syscall();
ffffffffc0200c86:	0750406f          	j	ffffffffc02054fa <syscall>
}
ffffffffc0200c8a:	60e2                	ld	ra,24(sp)
        cprintf("Environment call from H-mode\n");
ffffffffc0200c8c:	00005517          	auipc	a0,0x5
ffffffffc0200c90:	6fc50513          	addi	a0,a0,1788 # ffffffffc0206388 <etext+0x950>
}
ffffffffc0200c94:	6105                	addi	sp,sp,32
        cprintf("Environment call from H-mode\n");
ffffffffc0200c96:	d02ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200c9a:	60e2                	ld	ra,24(sp)
        cprintf("Environment call from M-mode\n");
ffffffffc0200c9c:	00005517          	auipc	a0,0x5
ffffffffc0200ca0:	70c50513          	addi	a0,a0,1804 # ffffffffc02063a8 <etext+0x970>
}
ffffffffc0200ca4:	6105                	addi	sp,sp,32
        cprintf("Environment call from M-mode\n");
ffffffffc0200ca6:	cf2ff06f          	j	ffffffffc0200198 <cprintf>
                current ? current->pid : -1, current ? current->name : "", (unsigned)tf->epc, (unsigned)tf->tval);
ffffffffc0200caa:	000b5617          	auipc	a2,0xb5
ffffffffc0200cae:	e0e63603          	ld	a2,-498(a2) # ffffffffc02b5ab8 <current>
        cprintf("Instruction page fault: pid=%d name=%s, epc=0x%08x, tval=0x%08x\n",
ffffffffc0200cb2:	0c060863          	beqz	a2,ffffffffc0200d82 <exception_handler+0x13c>
ffffffffc0200cb6:	424c                	lw	a1,4(a2)
ffffffffc0200cb8:	0b460613          	addi	a2,a2,180
ffffffffc0200cbc:	1106a703          	lw	a4,272(a3)
}
ffffffffc0200cc0:	60e2                	ld	ra,24(sp)
        cprintf("Instruction page fault: pid=%d name=%s, epc=0x%08x, tval=0x%08x\n",
ffffffffc0200cc2:	1086a683          	lw	a3,264(a3)
ffffffffc0200cc6:	00005517          	auipc	a0,0x5
ffffffffc0200cca:	70250513          	addi	a0,a0,1794 # ffffffffc02063c8 <etext+0x990>
}
ffffffffc0200cce:	6105                	addi	sp,sp,32
        cprintf("Instruction page fault: pid=%d name=%s, epc=0x%08x, tval=0x%08x\n",
ffffffffc0200cd0:	cc8ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200cd4:	60e2                	ld	ra,24(sp)
        cprintf("Load page fault\n");
ffffffffc0200cd6:	00005517          	auipc	a0,0x5
ffffffffc0200cda:	73a50513          	addi	a0,a0,1850 # ffffffffc0206410 <etext+0x9d8>
}
ffffffffc0200cde:	6105                	addi	sp,sp,32
        cprintf("Load page fault\n");
ffffffffc0200ce0:	cb8ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200ce4:	60e2                	ld	ra,24(sp)
        cprintf("Store/AMO page fault\n");
ffffffffc0200ce6:	00005517          	auipc	a0,0x5
ffffffffc0200cea:	74250513          	addi	a0,a0,1858 # ffffffffc0206428 <etext+0x9f0>
}
ffffffffc0200cee:	6105                	addi	sp,sp,32
        cprintf("Store/AMO page fault\n");
ffffffffc0200cf0:	ca8ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200cf4:	60e2                	ld	ra,24(sp)
        cprintf("Instruction address misaligned\n");
ffffffffc0200cf6:	00005517          	auipc	a0,0x5
ffffffffc0200cfa:	58a50513          	addi	a0,a0,1418 # ffffffffc0206280 <etext+0x848>
}
ffffffffc0200cfe:	6105                	addi	sp,sp,32
        cprintf("Instruction address misaligned\n");
ffffffffc0200d00:	c98ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200d04:	60e2                	ld	ra,24(sp)
        cprintf("Instruction access fault\n");
ffffffffc0200d06:	00005517          	auipc	a0,0x5
ffffffffc0200d0a:	59a50513          	addi	a0,a0,1434 # ffffffffc02062a0 <etext+0x868>
}
ffffffffc0200d0e:	6105                	addi	sp,sp,32
        cprintf("Instruction access fault\n");
ffffffffc0200d10:	c88ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200d14:	60e2                	ld	ra,24(sp)
        cprintf("Illegal instruction\n");
ffffffffc0200d16:	00005517          	auipc	a0,0x5
ffffffffc0200d1a:	5aa50513          	addi	a0,a0,1450 # ffffffffc02062c0 <etext+0x888>
}
ffffffffc0200d1e:	6105                	addi	sp,sp,32
        cprintf("Illegal instruction\n");
ffffffffc0200d20:	c78ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200d24:	60e2                	ld	ra,24(sp)
        cprintf("Breakpoint\n");
ffffffffc0200d26:	00005517          	auipc	a0,0x5
ffffffffc0200d2a:	5b250513          	addi	a0,a0,1458 # ffffffffc02062d8 <etext+0x8a0>
}
ffffffffc0200d2e:	6105                	addi	sp,sp,32
        cprintf("Breakpoint\n");
ffffffffc0200d30:	c68ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200d34:	60e2                	ld	ra,24(sp)
        cprintf("Load address misaligned\n");
ffffffffc0200d36:	00005517          	auipc	a0,0x5
ffffffffc0200d3a:	5b250513          	addi	a0,a0,1458 # ffffffffc02062e8 <etext+0x8b0>
}
ffffffffc0200d3e:	6105                	addi	sp,sp,32
        cprintf("Load address misaligned\n");
ffffffffc0200d40:	c58ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200d44:	60e2                	ld	ra,24(sp)
        cprintf("Load access fault\n");
ffffffffc0200d46:	00005517          	auipc	a0,0x5
ffffffffc0200d4a:	5c250513          	addi	a0,a0,1474 # ffffffffc0206308 <etext+0x8d0>
}
ffffffffc0200d4e:	6105                	addi	sp,sp,32
        cprintf("Load access fault\n");
ffffffffc0200d50:	c48ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200d54:	60e2                	ld	ra,24(sp)
        cprintf("Store/AMO access fault\n");
ffffffffc0200d56:	00005517          	auipc	a0,0x5
ffffffffc0200d5a:	5fa50513          	addi	a0,a0,1530 # ffffffffc0206350 <etext+0x918>
}
ffffffffc0200d5e:	6105                	addi	sp,sp,32
        cprintf("Store/AMO access fault\n");
ffffffffc0200d60:	c38ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200d64:	60e2                	ld	ra,24(sp)
ffffffffc0200d66:	6105                	addi	sp,sp,32
        print_trapframe(tf);
ffffffffc0200d68:	b359                	j	ffffffffc0200aee <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200d6a:	00005617          	auipc	a2,0x5
ffffffffc0200d6e:	5b660613          	addi	a2,a2,1462 # ffffffffc0206320 <etext+0x8e8>
ffffffffc0200d72:	0c200593          	li	a1,194
ffffffffc0200d76:	00005517          	auipc	a0,0x5
ffffffffc0200d7a:	5c250513          	addi	a0,a0,1474 # ffffffffc0206338 <etext+0x900>
ffffffffc0200d7e:	eccff0ef          	jal	ffffffffc020044a <__panic>
        cprintf("Instruction page fault: pid=%d name=%s, epc=0x%08x, tval=0x%08x\n",
ffffffffc0200d82:	55fd                	li	a1,-1
ffffffffc0200d84:	00006617          	auipc	a2,0x6
ffffffffc0200d88:	66c60613          	addi	a2,a2,1644 # ffffffffc02073f0 <etext+0x19b8>
ffffffffc0200d8c:	bf05                	j	ffffffffc0200cbc <exception_handler+0x76>
        print_trapframe(tf);
ffffffffc0200d8e:	b385                	j	ffffffffc0200aee <print_trapframe>

ffffffffc0200d90 <trap>:
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200d90:	000b5717          	auipc	a4,0xb5
ffffffffc0200d94:	d2873703          	ld	a4,-728(a4) # ffffffffc02b5ab8 <current>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d98:	11853583          	ld	a1,280(a0)
    if (current == NULL)
ffffffffc0200d9c:	cf21                	beqz	a4,ffffffffc0200df4 <trap+0x64>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d9e:	10053603          	ld	a2,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200da2:	0a073803          	ld	a6,160(a4)
{
ffffffffc0200da6:	1101                	addi	sp,sp,-32
ffffffffc0200da8:	ec06                	sd	ra,24(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200daa:	10067613          	andi	a2,a2,256
        current->tf = tf;
ffffffffc0200dae:	f348                	sd	a0,160(a4)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200db0:	e432                	sd	a2,8(sp)
ffffffffc0200db2:	e042                	sd	a6,0(sp)
ffffffffc0200db4:	0205c763          	bltz	a1,ffffffffc0200de2 <trap+0x52>
        exception_handler(tf);
ffffffffc0200db8:	e8fff0ef          	jal	ffffffffc0200c46 <exception_handler>
ffffffffc0200dbc:	6622                	ld	a2,8(sp)
ffffffffc0200dbe:	6802                	ld	a6,0(sp)
ffffffffc0200dc0:	000b5697          	auipc	a3,0xb5
ffffffffc0200dc4:	cf868693          	addi	a3,a3,-776 # ffffffffc02b5ab8 <current>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200dc8:	6298                	ld	a4,0(a3)
ffffffffc0200dca:	0b073023          	sd	a6,160(a4)
        if (!in_kernel)
ffffffffc0200dce:	e619                	bnez	a2,ffffffffc0200ddc <trap+0x4c>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200dd0:	0b072783          	lw	a5,176(a4)
ffffffffc0200dd4:	8b85                	andi	a5,a5,1
ffffffffc0200dd6:	e79d                	bnez	a5,ffffffffc0200e04 <trap+0x74>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200dd8:	6f1c                	ld	a5,24(a4)
ffffffffc0200dda:	e38d                	bnez	a5,ffffffffc0200dfc <trap+0x6c>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200ddc:	60e2                	ld	ra,24(sp)
ffffffffc0200dde:	6105                	addi	sp,sp,32
ffffffffc0200de0:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200de2:	d6fff0ef          	jal	ffffffffc0200b50 <interrupt_handler>
ffffffffc0200de6:	6802                	ld	a6,0(sp)
ffffffffc0200de8:	6622                	ld	a2,8(sp)
ffffffffc0200dea:	000b5697          	auipc	a3,0xb5
ffffffffc0200dee:	cce68693          	addi	a3,a3,-818 # ffffffffc02b5ab8 <current>
ffffffffc0200df2:	bfd9                	j	ffffffffc0200dc8 <trap+0x38>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200df4:	0005c363          	bltz	a1,ffffffffc0200dfa <trap+0x6a>
        exception_handler(tf);
ffffffffc0200df8:	b5b9                	j	ffffffffc0200c46 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200dfa:	bb99                	j	ffffffffc0200b50 <interrupt_handler>
}
ffffffffc0200dfc:	60e2                	ld	ra,24(sp)
ffffffffc0200dfe:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200e00:	5c60406f          	j	ffffffffc02053c6 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200e04:	555d                	li	a0,-9
ffffffffc0200e06:	5cc030ef          	jal	ffffffffc02043d2 <do_exit>
            if (current->need_resched)
ffffffffc0200e0a:	000b5717          	auipc	a4,0xb5
ffffffffc0200e0e:	cae73703          	ld	a4,-850(a4) # ffffffffc02b5ab8 <current>
ffffffffc0200e12:	b7d9                	j	ffffffffc0200dd8 <trap+0x48>

ffffffffc0200e14 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200e14:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200e18:	00011463          	bnez	sp,ffffffffc0200e20 <__alltraps+0xc>
ffffffffc0200e1c:	14002173          	csrr	sp,sscratch
ffffffffc0200e20:	712d                	addi	sp,sp,-288
ffffffffc0200e22:	e002                	sd	zero,0(sp)
ffffffffc0200e24:	e406                	sd	ra,8(sp)
ffffffffc0200e26:	ec0e                	sd	gp,24(sp)
ffffffffc0200e28:	f012                	sd	tp,32(sp)
ffffffffc0200e2a:	f416                	sd	t0,40(sp)
ffffffffc0200e2c:	f81a                	sd	t1,48(sp)
ffffffffc0200e2e:	fc1e                	sd	t2,56(sp)
ffffffffc0200e30:	e0a2                	sd	s0,64(sp)
ffffffffc0200e32:	e4a6                	sd	s1,72(sp)
ffffffffc0200e34:	e8aa                	sd	a0,80(sp)
ffffffffc0200e36:	ecae                	sd	a1,88(sp)
ffffffffc0200e38:	f0b2                	sd	a2,96(sp)
ffffffffc0200e3a:	f4b6                	sd	a3,104(sp)
ffffffffc0200e3c:	f8ba                	sd	a4,112(sp)
ffffffffc0200e3e:	fcbe                	sd	a5,120(sp)
ffffffffc0200e40:	e142                	sd	a6,128(sp)
ffffffffc0200e42:	e546                	sd	a7,136(sp)
ffffffffc0200e44:	e94a                	sd	s2,144(sp)
ffffffffc0200e46:	ed4e                	sd	s3,152(sp)
ffffffffc0200e48:	f152                	sd	s4,160(sp)
ffffffffc0200e4a:	f556                	sd	s5,168(sp)
ffffffffc0200e4c:	f95a                	sd	s6,176(sp)
ffffffffc0200e4e:	fd5e                	sd	s7,184(sp)
ffffffffc0200e50:	e1e2                	sd	s8,192(sp)
ffffffffc0200e52:	e5e6                	sd	s9,200(sp)
ffffffffc0200e54:	e9ea                	sd	s10,208(sp)
ffffffffc0200e56:	edee                	sd	s11,216(sp)
ffffffffc0200e58:	f1f2                	sd	t3,224(sp)
ffffffffc0200e5a:	f5f6                	sd	t4,232(sp)
ffffffffc0200e5c:	f9fa                	sd	t5,240(sp)
ffffffffc0200e5e:	fdfe                	sd	t6,248(sp)
ffffffffc0200e60:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200e64:	100024f3          	csrr	s1,sstatus
ffffffffc0200e68:	14102973          	csrr	s2,sepc
ffffffffc0200e6c:	143029f3          	csrr	s3,stval
ffffffffc0200e70:	14202a73          	csrr	s4,scause
ffffffffc0200e74:	e822                	sd	s0,16(sp)
ffffffffc0200e76:	e226                	sd	s1,256(sp)
ffffffffc0200e78:	e64a                	sd	s2,264(sp)
ffffffffc0200e7a:	ea4e                	sd	s3,272(sp)
ffffffffc0200e7c:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200e7e:	850a                	mv	a0,sp
    jal trap
ffffffffc0200e80:	f11ff0ef          	jal	ffffffffc0200d90 <trap>

ffffffffc0200e84 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200e84:	6492                	ld	s1,256(sp)
ffffffffc0200e86:	6932                	ld	s2,264(sp)
ffffffffc0200e88:	1004f413          	andi	s0,s1,256
ffffffffc0200e8c:	e401                	bnez	s0,ffffffffc0200e94 <__trapret+0x10>
ffffffffc0200e8e:	1200                	addi	s0,sp,288
ffffffffc0200e90:	14041073          	csrw	sscratch,s0
ffffffffc0200e94:	10049073          	csrw	sstatus,s1
ffffffffc0200e98:	14191073          	csrw	sepc,s2
ffffffffc0200e9c:	60a2                	ld	ra,8(sp)
ffffffffc0200e9e:	61e2                	ld	gp,24(sp)
ffffffffc0200ea0:	7202                	ld	tp,32(sp)
ffffffffc0200ea2:	72a2                	ld	t0,40(sp)
ffffffffc0200ea4:	7342                	ld	t1,48(sp)
ffffffffc0200ea6:	73e2                	ld	t2,56(sp)
ffffffffc0200ea8:	6406                	ld	s0,64(sp)
ffffffffc0200eaa:	64a6                	ld	s1,72(sp)
ffffffffc0200eac:	6546                	ld	a0,80(sp)
ffffffffc0200eae:	65e6                	ld	a1,88(sp)
ffffffffc0200eb0:	7606                	ld	a2,96(sp)
ffffffffc0200eb2:	76a6                	ld	a3,104(sp)
ffffffffc0200eb4:	7746                	ld	a4,112(sp)
ffffffffc0200eb6:	77e6                	ld	a5,120(sp)
ffffffffc0200eb8:	680a                	ld	a6,128(sp)
ffffffffc0200eba:	68aa                	ld	a7,136(sp)
ffffffffc0200ebc:	694a                	ld	s2,144(sp)
ffffffffc0200ebe:	69ea                	ld	s3,152(sp)
ffffffffc0200ec0:	7a0a                	ld	s4,160(sp)
ffffffffc0200ec2:	7aaa                	ld	s5,168(sp)
ffffffffc0200ec4:	7b4a                	ld	s6,176(sp)
ffffffffc0200ec6:	7bea                	ld	s7,184(sp)
ffffffffc0200ec8:	6c0e                	ld	s8,192(sp)
ffffffffc0200eca:	6cae                	ld	s9,200(sp)
ffffffffc0200ecc:	6d4e                	ld	s10,208(sp)
ffffffffc0200ece:	6dee                	ld	s11,216(sp)
ffffffffc0200ed0:	7e0e                	ld	t3,224(sp)
ffffffffc0200ed2:	7eae                	ld	t4,232(sp)
ffffffffc0200ed4:	7f4e                	ld	t5,240(sp)
ffffffffc0200ed6:	7fee                	ld	t6,248(sp)
ffffffffc0200ed8:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200eda:	10200073          	sret

ffffffffc0200ede <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200ede:	812a                	mv	sp,a0
ffffffffc0200ee0:	b755                	j	ffffffffc0200e84 <__trapret>

ffffffffc0200ee2 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200ee2:	000b1797          	auipc	a5,0xb1
ffffffffc0200ee6:	b1678793          	addi	a5,a5,-1258 # ffffffffc02b19f8 <free_area>
ffffffffc0200eea:	e79c                	sd	a5,8(a5)
ffffffffc0200eec:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200eee:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200ef2:	8082                	ret

ffffffffc0200ef4 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200ef4:	000b1517          	auipc	a0,0xb1
ffffffffc0200ef8:	b1456503          	lwu	a0,-1260(a0) # ffffffffc02b1a08 <free_area+0x10>
ffffffffc0200efc:	8082                	ret

ffffffffc0200efe <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200efe:	711d                	addi	sp,sp,-96
ffffffffc0200f00:	e0ca                	sd	s2,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200f02:	000b1917          	auipc	s2,0xb1
ffffffffc0200f06:	af690913          	addi	s2,s2,-1290 # ffffffffc02b19f8 <free_area>
ffffffffc0200f0a:	00893783          	ld	a5,8(s2)
ffffffffc0200f0e:	ec86                	sd	ra,88(sp)
ffffffffc0200f10:	e8a2                	sd	s0,80(sp)
ffffffffc0200f12:	e4a6                	sd	s1,72(sp)
ffffffffc0200f14:	fc4e                	sd	s3,56(sp)
ffffffffc0200f16:	f852                	sd	s4,48(sp)
ffffffffc0200f18:	f456                	sd	s5,40(sp)
ffffffffc0200f1a:	f05a                	sd	s6,32(sp)
ffffffffc0200f1c:	ec5e                	sd	s7,24(sp)
ffffffffc0200f1e:	e862                	sd	s8,16(sp)
ffffffffc0200f20:	e466                	sd	s9,8(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200f22:	2f278363          	beq	a5,s2,ffffffffc0201208 <default_check+0x30a>
    int count = 0, total = 0;
ffffffffc0200f26:	4401                	li	s0,0
ffffffffc0200f28:	4481                	li	s1,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200f2a:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200f2e:	8b09                	andi	a4,a4,2
ffffffffc0200f30:	2e070063          	beqz	a4,ffffffffc0201210 <default_check+0x312>
        count++, total += p->property;
ffffffffc0200f34:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200f38:	679c                	ld	a5,8(a5)
ffffffffc0200f3a:	2485                	addiw	s1,s1,1
ffffffffc0200f3c:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200f3e:	ff2796e3          	bne	a5,s2,ffffffffc0200f2a <default_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc0200f42:	89a2                	mv	s3,s0
ffffffffc0200f44:	741000ef          	jal	ffffffffc0201e84 <nr_free_pages>
ffffffffc0200f48:	73351463          	bne	a0,s3,ffffffffc0201670 <default_check+0x772>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f4c:	4505                	li	a0,1
ffffffffc0200f4e:	6c5000ef          	jal	ffffffffc0201e12 <alloc_pages>
ffffffffc0200f52:	8a2a                	mv	s4,a0
ffffffffc0200f54:	44050e63          	beqz	a0,ffffffffc02013b0 <default_check+0x4b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200f58:	4505                	li	a0,1
ffffffffc0200f5a:	6b9000ef          	jal	ffffffffc0201e12 <alloc_pages>
ffffffffc0200f5e:	89aa                	mv	s3,a0
ffffffffc0200f60:	72050863          	beqz	a0,ffffffffc0201690 <default_check+0x792>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f64:	4505                	li	a0,1
ffffffffc0200f66:	6ad000ef          	jal	ffffffffc0201e12 <alloc_pages>
ffffffffc0200f6a:	8aaa                	mv	s5,a0
ffffffffc0200f6c:	4c050263          	beqz	a0,ffffffffc0201430 <default_check+0x532>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200f70:	40a987b3          	sub	a5,s3,a0
ffffffffc0200f74:	40aa0733          	sub	a4,s4,a0
ffffffffc0200f78:	0017b793          	seqz	a5,a5
ffffffffc0200f7c:	00173713          	seqz	a4,a4
ffffffffc0200f80:	8fd9                	or	a5,a5,a4
ffffffffc0200f82:	30079763          	bnez	a5,ffffffffc0201290 <default_check+0x392>
ffffffffc0200f86:	313a0563          	beq	s4,s3,ffffffffc0201290 <default_check+0x392>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f8a:	000a2783          	lw	a5,0(s4)
ffffffffc0200f8e:	2a079163          	bnez	a5,ffffffffc0201230 <default_check+0x332>
ffffffffc0200f92:	0009a783          	lw	a5,0(s3)
ffffffffc0200f96:	28079d63          	bnez	a5,ffffffffc0201230 <default_check+0x332>
ffffffffc0200f9a:	411c                	lw	a5,0(a0)
ffffffffc0200f9c:	28079a63          	bnez	a5,ffffffffc0201230 <default_check+0x332>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200fa0:	000b5797          	auipc	a5,0xb5
ffffffffc0200fa4:	b087b783          	ld	a5,-1272(a5) # ffffffffc02b5aa8 <pages>
ffffffffc0200fa8:	00007617          	auipc	a2,0x7
ffffffffc0200fac:	3f863603          	ld	a2,1016(a2) # ffffffffc02083a0 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200fb0:	000b5697          	auipc	a3,0xb5
ffffffffc0200fb4:	af06b683          	ld	a3,-1296(a3) # ffffffffc02b5aa0 <npage>
ffffffffc0200fb8:	40fa0733          	sub	a4,s4,a5
ffffffffc0200fbc:	8719                	srai	a4,a4,0x6
ffffffffc0200fbe:	9732                	add	a4,a4,a2
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200fc0:	0732                	slli	a4,a4,0xc
ffffffffc0200fc2:	06b2                	slli	a3,a3,0xc
ffffffffc0200fc4:	2ad77663          	bgeu	a4,a3,ffffffffc0201270 <default_check+0x372>
    return page - pages + nbase;
ffffffffc0200fc8:	40f98733          	sub	a4,s3,a5
ffffffffc0200fcc:	8719                	srai	a4,a4,0x6
ffffffffc0200fce:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200fd0:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200fd2:	4cd77f63          	bgeu	a4,a3,ffffffffc02014b0 <default_check+0x5b2>
    return page - pages + nbase;
ffffffffc0200fd6:	40f507b3          	sub	a5,a0,a5
ffffffffc0200fda:	8799                	srai	a5,a5,0x6
ffffffffc0200fdc:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200fde:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200fe0:	32d7f863          	bgeu	a5,a3,ffffffffc0201310 <default_check+0x412>
    assert(alloc_page() == NULL);
ffffffffc0200fe4:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200fe6:	00093c03          	ld	s8,0(s2)
ffffffffc0200fea:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200fee:	000b1b17          	auipc	s6,0xb1
ffffffffc0200ff2:	a1ab2b03          	lw	s6,-1510(s6) # ffffffffc02b1a08 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc0200ff6:	01293023          	sd	s2,0(s2)
ffffffffc0200ffa:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc0200ffe:	000b1797          	auipc	a5,0xb1
ffffffffc0201002:	a007a523          	sw	zero,-1526(a5) # ffffffffc02b1a08 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0201006:	60d000ef          	jal	ffffffffc0201e12 <alloc_pages>
ffffffffc020100a:	2e051363          	bnez	a0,ffffffffc02012f0 <default_check+0x3f2>
    free_page(p0);
ffffffffc020100e:	8552                	mv	a0,s4
ffffffffc0201010:	4585                	li	a1,1
ffffffffc0201012:	63b000ef          	jal	ffffffffc0201e4c <free_pages>
    free_page(p1);
ffffffffc0201016:	854e                	mv	a0,s3
ffffffffc0201018:	4585                	li	a1,1
ffffffffc020101a:	633000ef          	jal	ffffffffc0201e4c <free_pages>
    free_page(p2);
ffffffffc020101e:	8556                	mv	a0,s5
ffffffffc0201020:	4585                	li	a1,1
ffffffffc0201022:	62b000ef          	jal	ffffffffc0201e4c <free_pages>
    assert(nr_free == 3);
ffffffffc0201026:	000b1717          	auipc	a4,0xb1
ffffffffc020102a:	9e272703          	lw	a4,-1566(a4) # ffffffffc02b1a08 <free_area+0x10>
ffffffffc020102e:	478d                	li	a5,3
ffffffffc0201030:	2af71063          	bne	a4,a5,ffffffffc02012d0 <default_check+0x3d2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201034:	4505                	li	a0,1
ffffffffc0201036:	5dd000ef          	jal	ffffffffc0201e12 <alloc_pages>
ffffffffc020103a:	89aa                	mv	s3,a0
ffffffffc020103c:	26050a63          	beqz	a0,ffffffffc02012b0 <default_check+0x3b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201040:	4505                	li	a0,1
ffffffffc0201042:	5d1000ef          	jal	ffffffffc0201e12 <alloc_pages>
ffffffffc0201046:	8aaa                	mv	s5,a0
ffffffffc0201048:	3c050463          	beqz	a0,ffffffffc0201410 <default_check+0x512>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020104c:	4505                	li	a0,1
ffffffffc020104e:	5c5000ef          	jal	ffffffffc0201e12 <alloc_pages>
ffffffffc0201052:	8a2a                	mv	s4,a0
ffffffffc0201054:	38050e63          	beqz	a0,ffffffffc02013f0 <default_check+0x4f2>
    assert(alloc_page() == NULL);
ffffffffc0201058:	4505                	li	a0,1
ffffffffc020105a:	5b9000ef          	jal	ffffffffc0201e12 <alloc_pages>
ffffffffc020105e:	36051963          	bnez	a0,ffffffffc02013d0 <default_check+0x4d2>
    free_page(p0);
ffffffffc0201062:	4585                	li	a1,1
ffffffffc0201064:	854e                	mv	a0,s3
ffffffffc0201066:	5e7000ef          	jal	ffffffffc0201e4c <free_pages>
    assert(!list_empty(&free_list));
ffffffffc020106a:	00893783          	ld	a5,8(s2)
ffffffffc020106e:	1f278163          	beq	a5,s2,ffffffffc0201250 <default_check+0x352>
    assert((p = alloc_page()) == p0);
ffffffffc0201072:	4505                	li	a0,1
ffffffffc0201074:	59f000ef          	jal	ffffffffc0201e12 <alloc_pages>
ffffffffc0201078:	8caa                	mv	s9,a0
ffffffffc020107a:	30a99b63          	bne	s3,a0,ffffffffc0201390 <default_check+0x492>
    assert(alloc_page() == NULL);
ffffffffc020107e:	4505                	li	a0,1
ffffffffc0201080:	593000ef          	jal	ffffffffc0201e12 <alloc_pages>
ffffffffc0201084:	2e051663          	bnez	a0,ffffffffc0201370 <default_check+0x472>
    assert(nr_free == 0);
ffffffffc0201088:	000b1797          	auipc	a5,0xb1
ffffffffc020108c:	9807a783          	lw	a5,-1664(a5) # ffffffffc02b1a08 <free_area+0x10>
ffffffffc0201090:	2c079063          	bnez	a5,ffffffffc0201350 <default_check+0x452>
    free_page(p);
ffffffffc0201094:	8566                	mv	a0,s9
ffffffffc0201096:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201098:	01893023          	sd	s8,0(s2)
ffffffffc020109c:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc02010a0:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc02010a4:	5a9000ef          	jal	ffffffffc0201e4c <free_pages>
    free_page(p1);
ffffffffc02010a8:	8556                	mv	a0,s5
ffffffffc02010aa:	4585                	li	a1,1
ffffffffc02010ac:	5a1000ef          	jal	ffffffffc0201e4c <free_pages>
    free_page(p2);
ffffffffc02010b0:	8552                	mv	a0,s4
ffffffffc02010b2:	4585                	li	a1,1
ffffffffc02010b4:	599000ef          	jal	ffffffffc0201e4c <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc02010b8:	4515                	li	a0,5
ffffffffc02010ba:	559000ef          	jal	ffffffffc0201e12 <alloc_pages>
ffffffffc02010be:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc02010c0:	26050863          	beqz	a0,ffffffffc0201330 <default_check+0x432>
ffffffffc02010c4:	651c                	ld	a5,8(a0)
    assert(!PageProperty(p0));
ffffffffc02010c6:	8b89                	andi	a5,a5,2
ffffffffc02010c8:	54079463          	bnez	a5,ffffffffc0201610 <default_check+0x712>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02010cc:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02010ce:	00093b83          	ld	s7,0(s2)
ffffffffc02010d2:	00893b03          	ld	s6,8(s2)
ffffffffc02010d6:	01293023          	sd	s2,0(s2)
ffffffffc02010da:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc02010de:	535000ef          	jal	ffffffffc0201e12 <alloc_pages>
ffffffffc02010e2:	50051763          	bnez	a0,ffffffffc02015f0 <default_check+0x6f2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc02010e6:	08098a13          	addi	s4,s3,128
ffffffffc02010ea:	8552                	mv	a0,s4
ffffffffc02010ec:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02010ee:	000b1c17          	auipc	s8,0xb1
ffffffffc02010f2:	91ac2c03          	lw	s8,-1766(s8) # ffffffffc02b1a08 <free_area+0x10>
    nr_free = 0;
ffffffffc02010f6:	000b1797          	auipc	a5,0xb1
ffffffffc02010fa:	9007a923          	sw	zero,-1774(a5) # ffffffffc02b1a08 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02010fe:	54f000ef          	jal	ffffffffc0201e4c <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0201102:	4511                	li	a0,4
ffffffffc0201104:	50f000ef          	jal	ffffffffc0201e12 <alloc_pages>
ffffffffc0201108:	4c051463          	bnez	a0,ffffffffc02015d0 <default_check+0x6d2>
ffffffffc020110c:	0889b783          	ld	a5,136(s3)
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201110:	8b89                	andi	a5,a5,2
ffffffffc0201112:	48078f63          	beqz	a5,ffffffffc02015b0 <default_check+0x6b2>
ffffffffc0201116:	0909a503          	lw	a0,144(s3)
ffffffffc020111a:	478d                	li	a5,3
ffffffffc020111c:	48f51a63          	bne	a0,a5,ffffffffc02015b0 <default_check+0x6b2>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201120:	4f3000ef          	jal	ffffffffc0201e12 <alloc_pages>
ffffffffc0201124:	8aaa                	mv	s5,a0
ffffffffc0201126:	46050563          	beqz	a0,ffffffffc0201590 <default_check+0x692>
    assert(alloc_page() == NULL);
ffffffffc020112a:	4505                	li	a0,1
ffffffffc020112c:	4e7000ef          	jal	ffffffffc0201e12 <alloc_pages>
ffffffffc0201130:	44051063          	bnez	a0,ffffffffc0201570 <default_check+0x672>
    assert(p0 + 2 == p1);
ffffffffc0201134:	415a1e63          	bne	s4,s5,ffffffffc0201550 <default_check+0x652>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0201138:	4585                	li	a1,1
ffffffffc020113a:	854e                	mv	a0,s3
ffffffffc020113c:	511000ef          	jal	ffffffffc0201e4c <free_pages>
    free_pages(p1, 3);
ffffffffc0201140:	8552                	mv	a0,s4
ffffffffc0201142:	458d                	li	a1,3
ffffffffc0201144:	509000ef          	jal	ffffffffc0201e4c <free_pages>
ffffffffc0201148:	0089b783          	ld	a5,8(s3)
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020114c:	8b89                	andi	a5,a5,2
ffffffffc020114e:	3e078163          	beqz	a5,ffffffffc0201530 <default_check+0x632>
ffffffffc0201152:	0109aa83          	lw	s5,16(s3)
ffffffffc0201156:	4785                	li	a5,1
ffffffffc0201158:	3cfa9c63          	bne	s5,a5,ffffffffc0201530 <default_check+0x632>
ffffffffc020115c:	008a3783          	ld	a5,8(s4)
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201160:	8b89                	andi	a5,a5,2
ffffffffc0201162:	3a078763          	beqz	a5,ffffffffc0201510 <default_check+0x612>
ffffffffc0201166:	010a2703          	lw	a4,16(s4)
ffffffffc020116a:	478d                	li	a5,3
ffffffffc020116c:	3af71263          	bne	a4,a5,ffffffffc0201510 <default_check+0x612>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201170:	8556                	mv	a0,s5
ffffffffc0201172:	4a1000ef          	jal	ffffffffc0201e12 <alloc_pages>
ffffffffc0201176:	36a99d63          	bne	s3,a0,ffffffffc02014f0 <default_check+0x5f2>
    free_page(p0);
ffffffffc020117a:	85d6                	mv	a1,s5
ffffffffc020117c:	4d1000ef          	jal	ffffffffc0201e4c <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201180:	4509                	li	a0,2
ffffffffc0201182:	491000ef          	jal	ffffffffc0201e12 <alloc_pages>
ffffffffc0201186:	34aa1563          	bne	s4,a0,ffffffffc02014d0 <default_check+0x5d2>

    free_pages(p0, 2);
ffffffffc020118a:	4589                	li	a1,2
ffffffffc020118c:	4c1000ef          	jal	ffffffffc0201e4c <free_pages>
    free_page(p2);
ffffffffc0201190:	04098513          	addi	a0,s3,64
ffffffffc0201194:	85d6                	mv	a1,s5
ffffffffc0201196:	4b7000ef          	jal	ffffffffc0201e4c <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020119a:	4515                	li	a0,5
ffffffffc020119c:	477000ef          	jal	ffffffffc0201e12 <alloc_pages>
ffffffffc02011a0:	89aa                	mv	s3,a0
ffffffffc02011a2:	48050763          	beqz	a0,ffffffffc0201630 <default_check+0x732>
    assert(alloc_page() == NULL);
ffffffffc02011a6:	8556                	mv	a0,s5
ffffffffc02011a8:	46b000ef          	jal	ffffffffc0201e12 <alloc_pages>
ffffffffc02011ac:	2e051263          	bnez	a0,ffffffffc0201490 <default_check+0x592>

    assert(nr_free == 0);
ffffffffc02011b0:	000b1797          	auipc	a5,0xb1
ffffffffc02011b4:	8587a783          	lw	a5,-1960(a5) # ffffffffc02b1a08 <free_area+0x10>
ffffffffc02011b8:	2a079c63          	bnez	a5,ffffffffc0201470 <default_check+0x572>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02011bc:	854e                	mv	a0,s3
ffffffffc02011be:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc02011c0:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc02011c4:	01793023          	sd	s7,0(s2)
ffffffffc02011c8:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc02011cc:	481000ef          	jal	ffffffffc0201e4c <free_pages>
    return listelm->next;
ffffffffc02011d0:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc02011d4:	01278963          	beq	a5,s2,ffffffffc02011e6 <default_check+0x2e8>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc02011d8:	ff87a703          	lw	a4,-8(a5)
ffffffffc02011dc:	679c                	ld	a5,8(a5)
ffffffffc02011de:	34fd                	addiw	s1,s1,-1
ffffffffc02011e0:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02011e2:	ff279be3          	bne	a5,s2,ffffffffc02011d8 <default_check+0x2da>
    }
    assert(count == 0);
ffffffffc02011e6:	26049563          	bnez	s1,ffffffffc0201450 <default_check+0x552>
    assert(total == 0);
ffffffffc02011ea:	46041363          	bnez	s0,ffffffffc0201650 <default_check+0x752>
}
ffffffffc02011ee:	60e6                	ld	ra,88(sp)
ffffffffc02011f0:	6446                	ld	s0,80(sp)
ffffffffc02011f2:	64a6                	ld	s1,72(sp)
ffffffffc02011f4:	6906                	ld	s2,64(sp)
ffffffffc02011f6:	79e2                	ld	s3,56(sp)
ffffffffc02011f8:	7a42                	ld	s4,48(sp)
ffffffffc02011fa:	7aa2                	ld	s5,40(sp)
ffffffffc02011fc:	7b02                	ld	s6,32(sp)
ffffffffc02011fe:	6be2                	ld	s7,24(sp)
ffffffffc0201200:	6c42                	ld	s8,16(sp)
ffffffffc0201202:	6ca2                	ld	s9,8(sp)
ffffffffc0201204:	6125                	addi	sp,sp,96
ffffffffc0201206:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0201208:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020120a:	4401                	li	s0,0
ffffffffc020120c:	4481                	li	s1,0
ffffffffc020120e:	bb1d                	j	ffffffffc0200f44 <default_check+0x46>
        assert(PageProperty(p));
ffffffffc0201210:	00005697          	auipc	a3,0x5
ffffffffc0201214:	23068693          	addi	a3,a3,560 # ffffffffc0206440 <etext+0xa08>
ffffffffc0201218:	00005617          	auipc	a2,0x5
ffffffffc020121c:	23860613          	addi	a2,a2,568 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201220:	11000593          	li	a1,272
ffffffffc0201224:	00005517          	auipc	a0,0x5
ffffffffc0201228:	24450513          	addi	a0,a0,580 # ffffffffc0206468 <etext+0xa30>
ffffffffc020122c:	a1eff0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201230:	00005697          	auipc	a3,0x5
ffffffffc0201234:	2f868693          	addi	a3,a3,760 # ffffffffc0206528 <etext+0xaf0>
ffffffffc0201238:	00005617          	auipc	a2,0x5
ffffffffc020123c:	21860613          	addi	a2,a2,536 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201240:	0dc00593          	li	a1,220
ffffffffc0201244:	00005517          	auipc	a0,0x5
ffffffffc0201248:	22450513          	addi	a0,a0,548 # ffffffffc0206468 <etext+0xa30>
ffffffffc020124c:	9feff0ef          	jal	ffffffffc020044a <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201250:	00005697          	auipc	a3,0x5
ffffffffc0201254:	3a068693          	addi	a3,a3,928 # ffffffffc02065f0 <etext+0xbb8>
ffffffffc0201258:	00005617          	auipc	a2,0x5
ffffffffc020125c:	1f860613          	addi	a2,a2,504 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201260:	0f700593          	li	a1,247
ffffffffc0201264:	00005517          	auipc	a0,0x5
ffffffffc0201268:	20450513          	addi	a0,a0,516 # ffffffffc0206468 <etext+0xa30>
ffffffffc020126c:	9deff0ef          	jal	ffffffffc020044a <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201270:	00005697          	auipc	a3,0x5
ffffffffc0201274:	2f868693          	addi	a3,a3,760 # ffffffffc0206568 <etext+0xb30>
ffffffffc0201278:	00005617          	auipc	a2,0x5
ffffffffc020127c:	1d860613          	addi	a2,a2,472 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201280:	0de00593          	li	a1,222
ffffffffc0201284:	00005517          	auipc	a0,0x5
ffffffffc0201288:	1e450513          	addi	a0,a0,484 # ffffffffc0206468 <etext+0xa30>
ffffffffc020128c:	9beff0ef          	jal	ffffffffc020044a <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201290:	00005697          	auipc	a3,0x5
ffffffffc0201294:	27068693          	addi	a3,a3,624 # ffffffffc0206500 <etext+0xac8>
ffffffffc0201298:	00005617          	auipc	a2,0x5
ffffffffc020129c:	1b860613          	addi	a2,a2,440 # ffffffffc0206450 <etext+0xa18>
ffffffffc02012a0:	0db00593          	li	a1,219
ffffffffc02012a4:	00005517          	auipc	a0,0x5
ffffffffc02012a8:	1c450513          	addi	a0,a0,452 # ffffffffc0206468 <etext+0xa30>
ffffffffc02012ac:	99eff0ef          	jal	ffffffffc020044a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02012b0:	00005697          	auipc	a3,0x5
ffffffffc02012b4:	1f068693          	addi	a3,a3,496 # ffffffffc02064a0 <etext+0xa68>
ffffffffc02012b8:	00005617          	auipc	a2,0x5
ffffffffc02012bc:	19860613          	addi	a2,a2,408 # ffffffffc0206450 <etext+0xa18>
ffffffffc02012c0:	0f000593          	li	a1,240
ffffffffc02012c4:	00005517          	auipc	a0,0x5
ffffffffc02012c8:	1a450513          	addi	a0,a0,420 # ffffffffc0206468 <etext+0xa30>
ffffffffc02012cc:	97eff0ef          	jal	ffffffffc020044a <__panic>
    assert(nr_free == 3);
ffffffffc02012d0:	00005697          	auipc	a3,0x5
ffffffffc02012d4:	31068693          	addi	a3,a3,784 # ffffffffc02065e0 <etext+0xba8>
ffffffffc02012d8:	00005617          	auipc	a2,0x5
ffffffffc02012dc:	17860613          	addi	a2,a2,376 # ffffffffc0206450 <etext+0xa18>
ffffffffc02012e0:	0ee00593          	li	a1,238
ffffffffc02012e4:	00005517          	auipc	a0,0x5
ffffffffc02012e8:	18450513          	addi	a0,a0,388 # ffffffffc0206468 <etext+0xa30>
ffffffffc02012ec:	95eff0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012f0:	00005697          	auipc	a3,0x5
ffffffffc02012f4:	2d868693          	addi	a3,a3,728 # ffffffffc02065c8 <etext+0xb90>
ffffffffc02012f8:	00005617          	auipc	a2,0x5
ffffffffc02012fc:	15860613          	addi	a2,a2,344 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201300:	0e900593          	li	a1,233
ffffffffc0201304:	00005517          	auipc	a0,0x5
ffffffffc0201308:	16450513          	addi	a0,a0,356 # ffffffffc0206468 <etext+0xa30>
ffffffffc020130c:	93eff0ef          	jal	ffffffffc020044a <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201310:	00005697          	auipc	a3,0x5
ffffffffc0201314:	29868693          	addi	a3,a3,664 # ffffffffc02065a8 <etext+0xb70>
ffffffffc0201318:	00005617          	auipc	a2,0x5
ffffffffc020131c:	13860613          	addi	a2,a2,312 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201320:	0e000593          	li	a1,224
ffffffffc0201324:	00005517          	auipc	a0,0x5
ffffffffc0201328:	14450513          	addi	a0,a0,324 # ffffffffc0206468 <etext+0xa30>
ffffffffc020132c:	91eff0ef          	jal	ffffffffc020044a <__panic>
    assert(p0 != NULL);
ffffffffc0201330:	00005697          	auipc	a3,0x5
ffffffffc0201334:	30868693          	addi	a3,a3,776 # ffffffffc0206638 <etext+0xc00>
ffffffffc0201338:	00005617          	auipc	a2,0x5
ffffffffc020133c:	11860613          	addi	a2,a2,280 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201340:	11800593          	li	a1,280
ffffffffc0201344:	00005517          	auipc	a0,0x5
ffffffffc0201348:	12450513          	addi	a0,a0,292 # ffffffffc0206468 <etext+0xa30>
ffffffffc020134c:	8feff0ef          	jal	ffffffffc020044a <__panic>
    assert(nr_free == 0);
ffffffffc0201350:	00005697          	auipc	a3,0x5
ffffffffc0201354:	2d868693          	addi	a3,a3,728 # ffffffffc0206628 <etext+0xbf0>
ffffffffc0201358:	00005617          	auipc	a2,0x5
ffffffffc020135c:	0f860613          	addi	a2,a2,248 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201360:	0fd00593          	li	a1,253
ffffffffc0201364:	00005517          	auipc	a0,0x5
ffffffffc0201368:	10450513          	addi	a0,a0,260 # ffffffffc0206468 <etext+0xa30>
ffffffffc020136c:	8deff0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201370:	00005697          	auipc	a3,0x5
ffffffffc0201374:	25868693          	addi	a3,a3,600 # ffffffffc02065c8 <etext+0xb90>
ffffffffc0201378:	00005617          	auipc	a2,0x5
ffffffffc020137c:	0d860613          	addi	a2,a2,216 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201380:	0fb00593          	li	a1,251
ffffffffc0201384:	00005517          	auipc	a0,0x5
ffffffffc0201388:	0e450513          	addi	a0,a0,228 # ffffffffc0206468 <etext+0xa30>
ffffffffc020138c:	8beff0ef          	jal	ffffffffc020044a <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201390:	00005697          	auipc	a3,0x5
ffffffffc0201394:	27868693          	addi	a3,a3,632 # ffffffffc0206608 <etext+0xbd0>
ffffffffc0201398:	00005617          	auipc	a2,0x5
ffffffffc020139c:	0b860613          	addi	a2,a2,184 # ffffffffc0206450 <etext+0xa18>
ffffffffc02013a0:	0fa00593          	li	a1,250
ffffffffc02013a4:	00005517          	auipc	a0,0x5
ffffffffc02013a8:	0c450513          	addi	a0,a0,196 # ffffffffc0206468 <etext+0xa30>
ffffffffc02013ac:	89eff0ef          	jal	ffffffffc020044a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02013b0:	00005697          	auipc	a3,0x5
ffffffffc02013b4:	0f068693          	addi	a3,a3,240 # ffffffffc02064a0 <etext+0xa68>
ffffffffc02013b8:	00005617          	auipc	a2,0x5
ffffffffc02013bc:	09860613          	addi	a2,a2,152 # ffffffffc0206450 <etext+0xa18>
ffffffffc02013c0:	0d700593          	li	a1,215
ffffffffc02013c4:	00005517          	auipc	a0,0x5
ffffffffc02013c8:	0a450513          	addi	a0,a0,164 # ffffffffc0206468 <etext+0xa30>
ffffffffc02013cc:	87eff0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013d0:	00005697          	auipc	a3,0x5
ffffffffc02013d4:	1f868693          	addi	a3,a3,504 # ffffffffc02065c8 <etext+0xb90>
ffffffffc02013d8:	00005617          	auipc	a2,0x5
ffffffffc02013dc:	07860613          	addi	a2,a2,120 # ffffffffc0206450 <etext+0xa18>
ffffffffc02013e0:	0f400593          	li	a1,244
ffffffffc02013e4:	00005517          	auipc	a0,0x5
ffffffffc02013e8:	08450513          	addi	a0,a0,132 # ffffffffc0206468 <etext+0xa30>
ffffffffc02013ec:	85eff0ef          	jal	ffffffffc020044a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02013f0:	00005697          	auipc	a3,0x5
ffffffffc02013f4:	0f068693          	addi	a3,a3,240 # ffffffffc02064e0 <etext+0xaa8>
ffffffffc02013f8:	00005617          	auipc	a2,0x5
ffffffffc02013fc:	05860613          	addi	a2,a2,88 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201400:	0f200593          	li	a1,242
ffffffffc0201404:	00005517          	auipc	a0,0x5
ffffffffc0201408:	06450513          	addi	a0,a0,100 # ffffffffc0206468 <etext+0xa30>
ffffffffc020140c:	83eff0ef          	jal	ffffffffc020044a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201410:	00005697          	auipc	a3,0x5
ffffffffc0201414:	0b068693          	addi	a3,a3,176 # ffffffffc02064c0 <etext+0xa88>
ffffffffc0201418:	00005617          	auipc	a2,0x5
ffffffffc020141c:	03860613          	addi	a2,a2,56 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201420:	0f100593          	li	a1,241
ffffffffc0201424:	00005517          	auipc	a0,0x5
ffffffffc0201428:	04450513          	addi	a0,a0,68 # ffffffffc0206468 <etext+0xa30>
ffffffffc020142c:	81eff0ef          	jal	ffffffffc020044a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201430:	00005697          	auipc	a3,0x5
ffffffffc0201434:	0b068693          	addi	a3,a3,176 # ffffffffc02064e0 <etext+0xaa8>
ffffffffc0201438:	00005617          	auipc	a2,0x5
ffffffffc020143c:	01860613          	addi	a2,a2,24 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201440:	0d900593          	li	a1,217
ffffffffc0201444:	00005517          	auipc	a0,0x5
ffffffffc0201448:	02450513          	addi	a0,a0,36 # ffffffffc0206468 <etext+0xa30>
ffffffffc020144c:	ffffe0ef          	jal	ffffffffc020044a <__panic>
    assert(count == 0);
ffffffffc0201450:	00005697          	auipc	a3,0x5
ffffffffc0201454:	33868693          	addi	a3,a3,824 # ffffffffc0206788 <etext+0xd50>
ffffffffc0201458:	00005617          	auipc	a2,0x5
ffffffffc020145c:	ff860613          	addi	a2,a2,-8 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201460:	14600593          	li	a1,326
ffffffffc0201464:	00005517          	auipc	a0,0x5
ffffffffc0201468:	00450513          	addi	a0,a0,4 # ffffffffc0206468 <etext+0xa30>
ffffffffc020146c:	fdffe0ef          	jal	ffffffffc020044a <__panic>
    assert(nr_free == 0);
ffffffffc0201470:	00005697          	auipc	a3,0x5
ffffffffc0201474:	1b868693          	addi	a3,a3,440 # ffffffffc0206628 <etext+0xbf0>
ffffffffc0201478:	00005617          	auipc	a2,0x5
ffffffffc020147c:	fd860613          	addi	a2,a2,-40 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201480:	13a00593          	li	a1,314
ffffffffc0201484:	00005517          	auipc	a0,0x5
ffffffffc0201488:	fe450513          	addi	a0,a0,-28 # ffffffffc0206468 <etext+0xa30>
ffffffffc020148c:	fbffe0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201490:	00005697          	auipc	a3,0x5
ffffffffc0201494:	13868693          	addi	a3,a3,312 # ffffffffc02065c8 <etext+0xb90>
ffffffffc0201498:	00005617          	auipc	a2,0x5
ffffffffc020149c:	fb860613          	addi	a2,a2,-72 # ffffffffc0206450 <etext+0xa18>
ffffffffc02014a0:	13800593          	li	a1,312
ffffffffc02014a4:	00005517          	auipc	a0,0x5
ffffffffc02014a8:	fc450513          	addi	a0,a0,-60 # ffffffffc0206468 <etext+0xa30>
ffffffffc02014ac:	f9ffe0ef          	jal	ffffffffc020044a <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02014b0:	00005697          	auipc	a3,0x5
ffffffffc02014b4:	0d868693          	addi	a3,a3,216 # ffffffffc0206588 <etext+0xb50>
ffffffffc02014b8:	00005617          	auipc	a2,0x5
ffffffffc02014bc:	f9860613          	addi	a2,a2,-104 # ffffffffc0206450 <etext+0xa18>
ffffffffc02014c0:	0df00593          	li	a1,223
ffffffffc02014c4:	00005517          	auipc	a0,0x5
ffffffffc02014c8:	fa450513          	addi	a0,a0,-92 # ffffffffc0206468 <etext+0xa30>
ffffffffc02014cc:	f7ffe0ef          	jal	ffffffffc020044a <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02014d0:	00005697          	auipc	a3,0x5
ffffffffc02014d4:	27868693          	addi	a3,a3,632 # ffffffffc0206748 <etext+0xd10>
ffffffffc02014d8:	00005617          	auipc	a2,0x5
ffffffffc02014dc:	f7860613          	addi	a2,a2,-136 # ffffffffc0206450 <etext+0xa18>
ffffffffc02014e0:	13200593          	li	a1,306
ffffffffc02014e4:	00005517          	auipc	a0,0x5
ffffffffc02014e8:	f8450513          	addi	a0,a0,-124 # ffffffffc0206468 <etext+0xa30>
ffffffffc02014ec:	f5ffe0ef          	jal	ffffffffc020044a <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02014f0:	00005697          	auipc	a3,0x5
ffffffffc02014f4:	23868693          	addi	a3,a3,568 # ffffffffc0206728 <etext+0xcf0>
ffffffffc02014f8:	00005617          	auipc	a2,0x5
ffffffffc02014fc:	f5860613          	addi	a2,a2,-168 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201500:	13000593          	li	a1,304
ffffffffc0201504:	00005517          	auipc	a0,0x5
ffffffffc0201508:	f6450513          	addi	a0,a0,-156 # ffffffffc0206468 <etext+0xa30>
ffffffffc020150c:	f3ffe0ef          	jal	ffffffffc020044a <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201510:	00005697          	auipc	a3,0x5
ffffffffc0201514:	1f068693          	addi	a3,a3,496 # ffffffffc0206700 <etext+0xcc8>
ffffffffc0201518:	00005617          	auipc	a2,0x5
ffffffffc020151c:	f3860613          	addi	a2,a2,-200 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201520:	12e00593          	li	a1,302
ffffffffc0201524:	00005517          	auipc	a0,0x5
ffffffffc0201528:	f4450513          	addi	a0,a0,-188 # ffffffffc0206468 <etext+0xa30>
ffffffffc020152c:	f1ffe0ef          	jal	ffffffffc020044a <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201530:	00005697          	auipc	a3,0x5
ffffffffc0201534:	1a868693          	addi	a3,a3,424 # ffffffffc02066d8 <etext+0xca0>
ffffffffc0201538:	00005617          	auipc	a2,0x5
ffffffffc020153c:	f1860613          	addi	a2,a2,-232 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201540:	12d00593          	li	a1,301
ffffffffc0201544:	00005517          	auipc	a0,0x5
ffffffffc0201548:	f2450513          	addi	a0,a0,-220 # ffffffffc0206468 <etext+0xa30>
ffffffffc020154c:	efffe0ef          	jal	ffffffffc020044a <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201550:	00005697          	auipc	a3,0x5
ffffffffc0201554:	17868693          	addi	a3,a3,376 # ffffffffc02066c8 <etext+0xc90>
ffffffffc0201558:	00005617          	auipc	a2,0x5
ffffffffc020155c:	ef860613          	addi	a2,a2,-264 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201560:	12800593          	li	a1,296
ffffffffc0201564:	00005517          	auipc	a0,0x5
ffffffffc0201568:	f0450513          	addi	a0,a0,-252 # ffffffffc0206468 <etext+0xa30>
ffffffffc020156c:	edffe0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201570:	00005697          	auipc	a3,0x5
ffffffffc0201574:	05868693          	addi	a3,a3,88 # ffffffffc02065c8 <etext+0xb90>
ffffffffc0201578:	00005617          	auipc	a2,0x5
ffffffffc020157c:	ed860613          	addi	a2,a2,-296 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201580:	12700593          	li	a1,295
ffffffffc0201584:	00005517          	auipc	a0,0x5
ffffffffc0201588:	ee450513          	addi	a0,a0,-284 # ffffffffc0206468 <etext+0xa30>
ffffffffc020158c:	ebffe0ef          	jal	ffffffffc020044a <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201590:	00005697          	auipc	a3,0x5
ffffffffc0201594:	11868693          	addi	a3,a3,280 # ffffffffc02066a8 <etext+0xc70>
ffffffffc0201598:	00005617          	auipc	a2,0x5
ffffffffc020159c:	eb860613          	addi	a2,a2,-328 # ffffffffc0206450 <etext+0xa18>
ffffffffc02015a0:	12600593          	li	a1,294
ffffffffc02015a4:	00005517          	auipc	a0,0x5
ffffffffc02015a8:	ec450513          	addi	a0,a0,-316 # ffffffffc0206468 <etext+0xa30>
ffffffffc02015ac:	e9ffe0ef          	jal	ffffffffc020044a <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02015b0:	00005697          	auipc	a3,0x5
ffffffffc02015b4:	0c868693          	addi	a3,a3,200 # ffffffffc0206678 <etext+0xc40>
ffffffffc02015b8:	00005617          	auipc	a2,0x5
ffffffffc02015bc:	e9860613          	addi	a2,a2,-360 # ffffffffc0206450 <etext+0xa18>
ffffffffc02015c0:	12500593          	li	a1,293
ffffffffc02015c4:	00005517          	auipc	a0,0x5
ffffffffc02015c8:	ea450513          	addi	a0,a0,-348 # ffffffffc0206468 <etext+0xa30>
ffffffffc02015cc:	e7ffe0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02015d0:	00005697          	auipc	a3,0x5
ffffffffc02015d4:	09068693          	addi	a3,a3,144 # ffffffffc0206660 <etext+0xc28>
ffffffffc02015d8:	00005617          	auipc	a2,0x5
ffffffffc02015dc:	e7860613          	addi	a2,a2,-392 # ffffffffc0206450 <etext+0xa18>
ffffffffc02015e0:	12400593          	li	a1,292
ffffffffc02015e4:	00005517          	auipc	a0,0x5
ffffffffc02015e8:	e8450513          	addi	a0,a0,-380 # ffffffffc0206468 <etext+0xa30>
ffffffffc02015ec:	e5ffe0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02015f0:	00005697          	auipc	a3,0x5
ffffffffc02015f4:	fd868693          	addi	a3,a3,-40 # ffffffffc02065c8 <etext+0xb90>
ffffffffc02015f8:	00005617          	auipc	a2,0x5
ffffffffc02015fc:	e5860613          	addi	a2,a2,-424 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201600:	11e00593          	li	a1,286
ffffffffc0201604:	00005517          	auipc	a0,0x5
ffffffffc0201608:	e6450513          	addi	a0,a0,-412 # ffffffffc0206468 <etext+0xa30>
ffffffffc020160c:	e3ffe0ef          	jal	ffffffffc020044a <__panic>
    assert(!PageProperty(p0));
ffffffffc0201610:	00005697          	auipc	a3,0x5
ffffffffc0201614:	03868693          	addi	a3,a3,56 # ffffffffc0206648 <etext+0xc10>
ffffffffc0201618:	00005617          	auipc	a2,0x5
ffffffffc020161c:	e3860613          	addi	a2,a2,-456 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201620:	11900593          	li	a1,281
ffffffffc0201624:	00005517          	auipc	a0,0x5
ffffffffc0201628:	e4450513          	addi	a0,a0,-444 # ffffffffc0206468 <etext+0xa30>
ffffffffc020162c:	e1ffe0ef          	jal	ffffffffc020044a <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201630:	00005697          	auipc	a3,0x5
ffffffffc0201634:	13868693          	addi	a3,a3,312 # ffffffffc0206768 <etext+0xd30>
ffffffffc0201638:	00005617          	auipc	a2,0x5
ffffffffc020163c:	e1860613          	addi	a2,a2,-488 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201640:	13700593          	li	a1,311
ffffffffc0201644:	00005517          	auipc	a0,0x5
ffffffffc0201648:	e2450513          	addi	a0,a0,-476 # ffffffffc0206468 <etext+0xa30>
ffffffffc020164c:	dfffe0ef          	jal	ffffffffc020044a <__panic>
    assert(total == 0);
ffffffffc0201650:	00005697          	auipc	a3,0x5
ffffffffc0201654:	14868693          	addi	a3,a3,328 # ffffffffc0206798 <etext+0xd60>
ffffffffc0201658:	00005617          	auipc	a2,0x5
ffffffffc020165c:	df860613          	addi	a2,a2,-520 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201660:	14700593          	li	a1,327
ffffffffc0201664:	00005517          	auipc	a0,0x5
ffffffffc0201668:	e0450513          	addi	a0,a0,-508 # ffffffffc0206468 <etext+0xa30>
ffffffffc020166c:	ddffe0ef          	jal	ffffffffc020044a <__panic>
    assert(total == nr_free_pages());
ffffffffc0201670:	00005697          	auipc	a3,0x5
ffffffffc0201674:	e1068693          	addi	a3,a3,-496 # ffffffffc0206480 <etext+0xa48>
ffffffffc0201678:	00005617          	auipc	a2,0x5
ffffffffc020167c:	dd860613          	addi	a2,a2,-552 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201680:	11300593          	li	a1,275
ffffffffc0201684:	00005517          	auipc	a0,0x5
ffffffffc0201688:	de450513          	addi	a0,a0,-540 # ffffffffc0206468 <etext+0xa30>
ffffffffc020168c:	dbffe0ef          	jal	ffffffffc020044a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201690:	00005697          	auipc	a3,0x5
ffffffffc0201694:	e3068693          	addi	a3,a3,-464 # ffffffffc02064c0 <etext+0xa88>
ffffffffc0201698:	00005617          	auipc	a2,0x5
ffffffffc020169c:	db860613          	addi	a2,a2,-584 # ffffffffc0206450 <etext+0xa18>
ffffffffc02016a0:	0d800593          	li	a1,216
ffffffffc02016a4:	00005517          	auipc	a0,0x5
ffffffffc02016a8:	dc450513          	addi	a0,a0,-572 # ffffffffc0206468 <etext+0xa30>
ffffffffc02016ac:	d9ffe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02016b0 <default_free_pages>:
{
ffffffffc02016b0:	1141                	addi	sp,sp,-16
ffffffffc02016b2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02016b4:	14058663          	beqz	a1,ffffffffc0201800 <default_free_pages+0x150>
    for (; p != base + n; p++)
ffffffffc02016b8:	00659713          	slli	a4,a1,0x6
ffffffffc02016bc:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc02016c0:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc02016c2:	c30d                	beqz	a4,ffffffffc02016e4 <default_free_pages+0x34>
ffffffffc02016c4:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02016c6:	8b05                	andi	a4,a4,1
ffffffffc02016c8:	10071c63          	bnez	a4,ffffffffc02017e0 <default_free_pages+0x130>
ffffffffc02016cc:	6798                	ld	a4,8(a5)
ffffffffc02016ce:	8b09                	andi	a4,a4,2
ffffffffc02016d0:	10071863          	bnez	a4,ffffffffc02017e0 <default_free_pages+0x130>
        p->flags = 0;
ffffffffc02016d4:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc02016d8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02016dc:	04078793          	addi	a5,a5,64
ffffffffc02016e0:	fed792e3          	bne	a5,a3,ffffffffc02016c4 <default_free_pages+0x14>
    base->property = n;
ffffffffc02016e4:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02016e6:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02016ea:	4789                	li	a5,2
ffffffffc02016ec:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02016f0:	000b0717          	auipc	a4,0xb0
ffffffffc02016f4:	31872703          	lw	a4,792(a4) # ffffffffc02b1a08 <free_area+0x10>
ffffffffc02016f8:	000b0697          	auipc	a3,0xb0
ffffffffc02016fc:	30068693          	addi	a3,a3,768 # ffffffffc02b19f8 <free_area>
    return list->next == list;
ffffffffc0201700:	669c                	ld	a5,8(a3)
ffffffffc0201702:	9f2d                	addw	a4,a4,a1
ffffffffc0201704:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc0201706:	0ad78163          	beq	a5,a3,ffffffffc02017a8 <default_free_pages+0xf8>
            struct Page *page = le2page(le, page_link);
ffffffffc020170a:	fe878713          	addi	a4,a5,-24
ffffffffc020170e:	4581                	li	a1,0
ffffffffc0201710:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc0201714:	00e56a63          	bltu	a0,a4,ffffffffc0201728 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201718:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc020171a:	04d70c63          	beq	a4,a3,ffffffffc0201772 <default_free_pages+0xc2>
    struct Page *p = base;
ffffffffc020171e:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201720:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201724:	fee57ae3          	bgeu	a0,a4,ffffffffc0201718 <default_free_pages+0x68>
ffffffffc0201728:	c199                	beqz	a1,ffffffffc020172e <default_free_pages+0x7e>
ffffffffc020172a:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020172e:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201730:	e390                	sd	a2,0(a5)
ffffffffc0201732:	e710                	sd	a2,8(a4)
    elm->next = next;
    elm->prev = prev;
ffffffffc0201734:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc0201736:	f11c                	sd	a5,32(a0)
    if (le != &free_list)
ffffffffc0201738:	00d70d63          	beq	a4,a3,ffffffffc0201752 <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc020173c:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201740:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc0201744:	02059813          	slli	a6,a1,0x20
ffffffffc0201748:	01a85793          	srli	a5,a6,0x1a
ffffffffc020174c:	97b2                	add	a5,a5,a2
ffffffffc020174e:	02f50c63          	beq	a0,a5,ffffffffc0201786 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc0201752:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc0201754:	00d78c63          	beq	a5,a3,ffffffffc020176c <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc0201758:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc020175a:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc020175e:	02061593          	slli	a1,a2,0x20
ffffffffc0201762:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0201766:	972a                	add	a4,a4,a0
ffffffffc0201768:	04e68c63          	beq	a3,a4,ffffffffc02017c0 <default_free_pages+0x110>
}
ffffffffc020176c:	60a2                	ld	ra,8(sp)
ffffffffc020176e:	0141                	addi	sp,sp,16
ffffffffc0201770:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201772:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201774:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201776:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201778:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc020177a:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc020177c:	02d70f63          	beq	a4,a3,ffffffffc02017ba <default_free_pages+0x10a>
ffffffffc0201780:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201782:	87ba                	mv	a5,a4
ffffffffc0201784:	bf71                	j	ffffffffc0201720 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201786:	491c                	lw	a5,16(a0)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201788:	5875                	li	a6,-3
ffffffffc020178a:	9fad                	addw	a5,a5,a1
ffffffffc020178c:	fef72c23          	sw	a5,-8(a4)
ffffffffc0201790:	6108b02f          	amoand.d	zero,a6,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201794:	01853803          	ld	a6,24(a0)
ffffffffc0201798:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc020179a:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020179c:	00b83423          	sd	a1,8(a6) # ff0008 <_binary_obj___user_matrix_out_size+0xfe4a88>
    return listelm->next;
ffffffffc02017a0:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc02017a2:	0105b023          	sd	a6,0(a1)
ffffffffc02017a6:	b77d                	j	ffffffffc0201754 <default_free_pages+0xa4>
}
ffffffffc02017a8:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02017aa:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc02017ae:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02017b0:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc02017b2:	e398                	sd	a4,0(a5)
ffffffffc02017b4:	e798                	sd	a4,8(a5)
}
ffffffffc02017b6:	0141                	addi	sp,sp,16
ffffffffc02017b8:	8082                	ret
ffffffffc02017ba:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc02017bc:	873e                	mv	a4,a5
ffffffffc02017be:	bfad                	j	ffffffffc0201738 <default_free_pages+0x88>
            base->property += p->property;
ffffffffc02017c0:	ff87a703          	lw	a4,-8(a5)
ffffffffc02017c4:	56f5                	li	a3,-3
ffffffffc02017c6:	9f31                	addw	a4,a4,a2
ffffffffc02017c8:	c918                	sw	a4,16(a0)
ffffffffc02017ca:	ff078713          	addi	a4,a5,-16
ffffffffc02017ce:	60d7302f          	amoand.d	zero,a3,(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc02017d2:	6398                	ld	a4,0(a5)
ffffffffc02017d4:	679c                	ld	a5,8(a5)
}
ffffffffc02017d6:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02017d8:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02017da:	e398                	sd	a4,0(a5)
ffffffffc02017dc:	0141                	addi	sp,sp,16
ffffffffc02017de:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02017e0:	00005697          	auipc	a3,0x5
ffffffffc02017e4:	fd068693          	addi	a3,a3,-48 # ffffffffc02067b0 <etext+0xd78>
ffffffffc02017e8:	00005617          	auipc	a2,0x5
ffffffffc02017ec:	c6860613          	addi	a2,a2,-920 # ffffffffc0206450 <etext+0xa18>
ffffffffc02017f0:	09400593          	li	a1,148
ffffffffc02017f4:	00005517          	auipc	a0,0x5
ffffffffc02017f8:	c7450513          	addi	a0,a0,-908 # ffffffffc0206468 <etext+0xa30>
ffffffffc02017fc:	c4ffe0ef          	jal	ffffffffc020044a <__panic>
    assert(n > 0);
ffffffffc0201800:	00005697          	auipc	a3,0x5
ffffffffc0201804:	fa868693          	addi	a3,a3,-88 # ffffffffc02067a8 <etext+0xd70>
ffffffffc0201808:	00005617          	auipc	a2,0x5
ffffffffc020180c:	c4860613          	addi	a2,a2,-952 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201810:	09000593          	li	a1,144
ffffffffc0201814:	00005517          	auipc	a0,0x5
ffffffffc0201818:	c5450513          	addi	a0,a0,-940 # ffffffffc0206468 <etext+0xa30>
ffffffffc020181c:	c2ffe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0201820 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201820:	c951                	beqz	a0,ffffffffc02018b4 <default_alloc_pages+0x94>
    if (n > nr_free)
ffffffffc0201822:	000b0597          	auipc	a1,0xb0
ffffffffc0201826:	1e65a583          	lw	a1,486(a1) # ffffffffc02b1a08 <free_area+0x10>
ffffffffc020182a:	86aa                	mv	a3,a0
ffffffffc020182c:	02059793          	slli	a5,a1,0x20
ffffffffc0201830:	9381                	srli	a5,a5,0x20
ffffffffc0201832:	00a7ef63          	bltu	a5,a0,ffffffffc0201850 <default_alloc_pages+0x30>
    list_entry_t *le = &free_list;
ffffffffc0201836:	000b0617          	auipc	a2,0xb0
ffffffffc020183a:	1c260613          	addi	a2,a2,450 # ffffffffc02b19f8 <free_area>
ffffffffc020183e:	87b2                	mv	a5,a2
ffffffffc0201840:	a029                	j	ffffffffc020184a <default_alloc_pages+0x2a>
        if (p->property >= n)
ffffffffc0201842:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0201846:	00d77763          	bgeu	a4,a3,ffffffffc0201854 <default_alloc_pages+0x34>
    return listelm->next;
ffffffffc020184a:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc020184c:	fec79be3          	bne	a5,a2,ffffffffc0201842 <default_alloc_pages+0x22>
        return NULL;
ffffffffc0201850:	4501                	li	a0,0
}
ffffffffc0201852:	8082                	ret
        if (page->property > n)
ffffffffc0201854:	ff87a883          	lw	a7,-8(a5)
    return listelm->prev;
ffffffffc0201858:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020185c:	6798                	ld	a4,8(a5)
ffffffffc020185e:	02089313          	slli	t1,a7,0x20
ffffffffc0201862:	02035313          	srli	t1,t1,0x20
    prev->next = next;
ffffffffc0201866:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc020186a:	01073023          	sd	a6,0(a4)
        struct Page *p = le2page(le, page_link);
ffffffffc020186e:	fe878513          	addi	a0,a5,-24
        if (page->property > n)
ffffffffc0201872:	0266fa63          	bgeu	a3,t1,ffffffffc02018a6 <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc0201876:	00669713          	slli	a4,a3,0x6
            p->property = page->property - n;
ffffffffc020187a:	40d888bb          	subw	a7,a7,a3
            struct Page *p = page + n;
ffffffffc020187e:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201880:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201884:	00870313          	addi	t1,a4,8
ffffffffc0201888:	4889                	li	a7,2
ffffffffc020188a:	4113302f          	amoor.d	zero,a7,(t1)
    __list_add(elm, listelm, listelm->next);
ffffffffc020188e:	00883883          	ld	a7,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc0201892:	01870313          	addi	t1,a4,24
    prev->next = next->prev = elm;
ffffffffc0201896:	0068b023          	sd	t1,0(a7)
ffffffffc020189a:	00683423          	sd	t1,8(a6)
    elm->next = next;
ffffffffc020189e:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc02018a2:	01073c23          	sd	a6,24(a4)
        nr_free -= n;
ffffffffc02018a6:	9d95                	subw	a1,a1,a3
ffffffffc02018a8:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02018aa:	5775                	li	a4,-3
ffffffffc02018ac:	17c1                	addi	a5,a5,-16
ffffffffc02018ae:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc02018b2:	8082                	ret
{
ffffffffc02018b4:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02018b6:	00005697          	auipc	a3,0x5
ffffffffc02018ba:	ef268693          	addi	a3,a3,-270 # ffffffffc02067a8 <etext+0xd70>
ffffffffc02018be:	00005617          	auipc	a2,0x5
ffffffffc02018c2:	b9260613          	addi	a2,a2,-1134 # ffffffffc0206450 <etext+0xa18>
ffffffffc02018c6:	06c00593          	li	a1,108
ffffffffc02018ca:	00005517          	auipc	a0,0x5
ffffffffc02018ce:	b9e50513          	addi	a0,a0,-1122 # ffffffffc0206468 <etext+0xa30>
{
ffffffffc02018d2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02018d4:	b77fe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02018d8 <default_init_memmap>:
{
ffffffffc02018d8:	1141                	addi	sp,sp,-16
ffffffffc02018da:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02018dc:	c9e1                	beqz	a1,ffffffffc02019ac <default_init_memmap+0xd4>
    for (; p != base + n; p++)
ffffffffc02018de:	00659713          	slli	a4,a1,0x6
ffffffffc02018e2:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc02018e6:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc02018e8:	cf11                	beqz	a4,ffffffffc0201904 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02018ea:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02018ec:	8b05                	andi	a4,a4,1
ffffffffc02018ee:	cf59                	beqz	a4,ffffffffc020198c <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc02018f0:	0007a823          	sw	zero,16(a5)
ffffffffc02018f4:	0007b423          	sd	zero,8(a5)
ffffffffc02018f8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02018fc:	04078793          	addi	a5,a5,64
ffffffffc0201900:	fed795e3          	bne	a5,a3,ffffffffc02018ea <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201904:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201906:	4789                	li	a5,2
ffffffffc0201908:	00850713          	addi	a4,a0,8
ffffffffc020190c:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201910:	000b0717          	auipc	a4,0xb0
ffffffffc0201914:	0f872703          	lw	a4,248(a4) # ffffffffc02b1a08 <free_area+0x10>
ffffffffc0201918:	000b0697          	auipc	a3,0xb0
ffffffffc020191c:	0e068693          	addi	a3,a3,224 # ffffffffc02b19f8 <free_area>
    return list->next == list;
ffffffffc0201920:	669c                	ld	a5,8(a3)
ffffffffc0201922:	9f2d                	addw	a4,a4,a1
ffffffffc0201924:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc0201926:	04d78663          	beq	a5,a3,ffffffffc0201972 <default_init_memmap+0x9a>
            struct Page *page = le2page(le, page_link);
ffffffffc020192a:	fe878713          	addi	a4,a5,-24
ffffffffc020192e:	4581                	li	a1,0
ffffffffc0201930:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc0201934:	00e56a63          	bltu	a0,a4,ffffffffc0201948 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201938:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc020193a:	02d70263          	beq	a4,a3,ffffffffc020195e <default_init_memmap+0x86>
    struct Page *p = base;
ffffffffc020193e:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201940:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201944:	fee57ae3          	bgeu	a0,a4,ffffffffc0201938 <default_init_memmap+0x60>
ffffffffc0201948:	c199                	beqz	a1,ffffffffc020194e <default_init_memmap+0x76>
ffffffffc020194a:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020194e:	6398                	ld	a4,0(a5)
}
ffffffffc0201950:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201952:	e390                	sd	a2,0(a5)
ffffffffc0201954:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc0201956:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc0201958:	f11c                	sd	a5,32(a0)
ffffffffc020195a:	0141                	addi	sp,sp,16
ffffffffc020195c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020195e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201960:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201962:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201964:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201966:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc0201968:	00d70e63          	beq	a4,a3,ffffffffc0201984 <default_init_memmap+0xac>
ffffffffc020196c:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc020196e:	87ba                	mv	a5,a4
ffffffffc0201970:	bfc1                	j	ffffffffc0201940 <default_init_memmap+0x68>
}
ffffffffc0201972:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201974:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0201978:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020197a:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc020197c:	e398                	sd	a4,0(a5)
ffffffffc020197e:	e798                	sd	a4,8(a5)
}
ffffffffc0201980:	0141                	addi	sp,sp,16
ffffffffc0201982:	8082                	ret
ffffffffc0201984:	60a2                	ld	ra,8(sp)
ffffffffc0201986:	e290                	sd	a2,0(a3)
ffffffffc0201988:	0141                	addi	sp,sp,16
ffffffffc020198a:	8082                	ret
        assert(PageReserved(p));
ffffffffc020198c:	00005697          	auipc	a3,0x5
ffffffffc0201990:	e4c68693          	addi	a3,a3,-436 # ffffffffc02067d8 <etext+0xda0>
ffffffffc0201994:	00005617          	auipc	a2,0x5
ffffffffc0201998:	abc60613          	addi	a2,a2,-1348 # ffffffffc0206450 <etext+0xa18>
ffffffffc020199c:	04b00593          	li	a1,75
ffffffffc02019a0:	00005517          	auipc	a0,0x5
ffffffffc02019a4:	ac850513          	addi	a0,a0,-1336 # ffffffffc0206468 <etext+0xa30>
ffffffffc02019a8:	aa3fe0ef          	jal	ffffffffc020044a <__panic>
    assert(n > 0);
ffffffffc02019ac:	00005697          	auipc	a3,0x5
ffffffffc02019b0:	dfc68693          	addi	a3,a3,-516 # ffffffffc02067a8 <etext+0xd70>
ffffffffc02019b4:	00005617          	auipc	a2,0x5
ffffffffc02019b8:	a9c60613          	addi	a2,a2,-1380 # ffffffffc0206450 <etext+0xa18>
ffffffffc02019bc:	04700593          	li	a1,71
ffffffffc02019c0:	00005517          	auipc	a0,0x5
ffffffffc02019c4:	aa850513          	addi	a0,a0,-1368 # ffffffffc0206468 <etext+0xa30>
ffffffffc02019c8:	a83fe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02019cc <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc02019cc:	c531                	beqz	a0,ffffffffc0201a18 <slob_free+0x4c>
		return;

	if (size)
ffffffffc02019ce:	e9b9                	bnez	a1,ffffffffc0201a24 <slob_free+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02019d0:	100027f3          	csrr	a5,sstatus
ffffffffc02019d4:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02019d6:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02019d8:	efb1                	bnez	a5,ffffffffc0201a34 <slob_free+0x68>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02019da:	000b0797          	auipc	a5,0xb0
ffffffffc02019de:	c0e7b783          	ld	a5,-1010(a5) # ffffffffc02b15e8 <slobfree>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019e2:	873e                	mv	a4,a5
ffffffffc02019e4:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02019e6:	02a77a63          	bgeu	a4,a0,ffffffffc0201a1a <slob_free+0x4e>
ffffffffc02019ea:	00f56463          	bltu	a0,a5,ffffffffc02019f2 <slob_free+0x26>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019ee:	fef76ae3          	bltu	a4,a5,ffffffffc02019e2 <slob_free+0x16>
			break;

	if (b + b->units == cur->next)
ffffffffc02019f2:	4110                	lw	a2,0(a0)
ffffffffc02019f4:	00461693          	slli	a3,a2,0x4
ffffffffc02019f8:	96aa                	add	a3,a3,a0
ffffffffc02019fa:	0ad78463          	beq	a5,a3,ffffffffc0201aa2 <slob_free+0xd6>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc02019fe:	4310                	lw	a2,0(a4)
ffffffffc0201a00:	e51c                	sd	a5,8(a0)
ffffffffc0201a02:	00461693          	slli	a3,a2,0x4
ffffffffc0201a06:	96ba                	add	a3,a3,a4
ffffffffc0201a08:	08d50163          	beq	a0,a3,ffffffffc0201a8a <slob_free+0xbe>
ffffffffc0201a0c:	e708                	sd	a0,8(a4)
		cur->next = b->next;
	}
	else
		cur->next = b;

	slobfree = cur;
ffffffffc0201a0e:	000b0797          	auipc	a5,0xb0
ffffffffc0201a12:	bce7bd23          	sd	a4,-1062(a5) # ffffffffc02b15e8 <slobfree>
    if (flag)
ffffffffc0201a16:	e9a5                	bnez	a1,ffffffffc0201a86 <slob_free+0xba>
ffffffffc0201a18:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a1a:	fcf574e3          	bgeu	a0,a5,ffffffffc02019e2 <slob_free+0x16>
ffffffffc0201a1e:	fcf762e3          	bltu	a4,a5,ffffffffc02019e2 <slob_free+0x16>
ffffffffc0201a22:	bfc1                	j	ffffffffc02019f2 <slob_free+0x26>
		b->units = SLOB_UNITS(size);
ffffffffc0201a24:	25bd                	addiw	a1,a1,15
ffffffffc0201a26:	8191                	srli	a1,a1,0x4
ffffffffc0201a28:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a2a:	100027f3          	csrr	a5,sstatus
ffffffffc0201a2e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201a30:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a32:	d7c5                	beqz	a5,ffffffffc02019da <slob_free+0xe>
{
ffffffffc0201a34:	1101                	addi	sp,sp,-32
ffffffffc0201a36:	e42a                	sd	a0,8(sp)
ffffffffc0201a38:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201a3a:	ec5fe0ef          	jal	ffffffffc02008fe <intr_disable>
        return 1;
ffffffffc0201a3e:	6522                	ld	a0,8(sp)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a40:	000b0797          	auipc	a5,0xb0
ffffffffc0201a44:	ba87b783          	ld	a5,-1112(a5) # ffffffffc02b15e8 <slobfree>
ffffffffc0201a48:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a4a:	873e                	mv	a4,a5
ffffffffc0201a4c:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a4e:	06a77663          	bgeu	a4,a0,ffffffffc0201aba <slob_free+0xee>
ffffffffc0201a52:	00f56463          	bltu	a0,a5,ffffffffc0201a5a <slob_free+0x8e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a56:	fef76ae3          	bltu	a4,a5,ffffffffc0201a4a <slob_free+0x7e>
	if (b + b->units == cur->next)
ffffffffc0201a5a:	4110                	lw	a2,0(a0)
ffffffffc0201a5c:	00461693          	slli	a3,a2,0x4
ffffffffc0201a60:	96aa                	add	a3,a3,a0
ffffffffc0201a62:	06d78363          	beq	a5,a3,ffffffffc0201ac8 <slob_free+0xfc>
	if (cur + cur->units == b)
ffffffffc0201a66:	4310                	lw	a2,0(a4)
ffffffffc0201a68:	e51c                	sd	a5,8(a0)
ffffffffc0201a6a:	00461693          	slli	a3,a2,0x4
ffffffffc0201a6e:	96ba                	add	a3,a3,a4
ffffffffc0201a70:	06d50163          	beq	a0,a3,ffffffffc0201ad2 <slob_free+0x106>
ffffffffc0201a74:	e708                	sd	a0,8(a4)
	slobfree = cur;
ffffffffc0201a76:	000b0797          	auipc	a5,0xb0
ffffffffc0201a7a:	b6e7b923          	sd	a4,-1166(a5) # ffffffffc02b15e8 <slobfree>
    if (flag)
ffffffffc0201a7e:	e1a9                	bnez	a1,ffffffffc0201ac0 <slob_free+0xf4>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201a80:	60e2                	ld	ra,24(sp)
ffffffffc0201a82:	6105                	addi	sp,sp,32
ffffffffc0201a84:	8082                	ret
        intr_enable();
ffffffffc0201a86:	e73fe06f          	j	ffffffffc02008f8 <intr_enable>
		cur->units += b->units;
ffffffffc0201a8a:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201a8c:	853e                	mv	a0,a5
ffffffffc0201a8e:	e708                	sd	a0,8(a4)
		cur->units += b->units;
ffffffffc0201a90:	00c687bb          	addw	a5,a3,a2
ffffffffc0201a94:	c31c                	sw	a5,0(a4)
	slobfree = cur;
ffffffffc0201a96:	000b0797          	auipc	a5,0xb0
ffffffffc0201a9a:	b4e7b923          	sd	a4,-1198(a5) # ffffffffc02b15e8 <slobfree>
    if (flag)
ffffffffc0201a9e:	ddad                	beqz	a1,ffffffffc0201a18 <slob_free+0x4c>
ffffffffc0201aa0:	b7dd                	j	ffffffffc0201a86 <slob_free+0xba>
		b->units += cur->next->units;
ffffffffc0201aa2:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201aa4:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201aa6:	9eb1                	addw	a3,a3,a2
ffffffffc0201aa8:	c114                	sw	a3,0(a0)
	if (cur + cur->units == b)
ffffffffc0201aaa:	4310                	lw	a2,0(a4)
ffffffffc0201aac:	e51c                	sd	a5,8(a0)
ffffffffc0201aae:	00461693          	slli	a3,a2,0x4
ffffffffc0201ab2:	96ba                	add	a3,a3,a4
ffffffffc0201ab4:	f4d51ce3          	bne	a0,a3,ffffffffc0201a0c <slob_free+0x40>
ffffffffc0201ab8:	bfc9                	j	ffffffffc0201a8a <slob_free+0xbe>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201aba:	f8f56ee3          	bltu	a0,a5,ffffffffc0201a56 <slob_free+0x8a>
ffffffffc0201abe:	b771                	j	ffffffffc0201a4a <slob_free+0x7e>
}
ffffffffc0201ac0:	60e2                	ld	ra,24(sp)
ffffffffc0201ac2:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201ac4:	e35fe06f          	j	ffffffffc02008f8 <intr_enable>
		b->units += cur->next->units;
ffffffffc0201ac8:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201aca:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201acc:	9eb1                	addw	a3,a3,a2
ffffffffc0201ace:	c114                	sw	a3,0(a0)
		b->next = cur->next->next;
ffffffffc0201ad0:	bf59                	j	ffffffffc0201a66 <slob_free+0x9a>
		cur->units += b->units;
ffffffffc0201ad2:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201ad4:	853e                	mv	a0,a5
		cur->units += b->units;
ffffffffc0201ad6:	00c687bb          	addw	a5,a3,a2
ffffffffc0201ada:	c31c                	sw	a5,0(a4)
		cur->next = b->next;
ffffffffc0201adc:	bf61                	j	ffffffffc0201a74 <slob_free+0xa8>

ffffffffc0201ade <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201ade:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201ae0:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201ae2:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201ae6:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201ae8:	32a000ef          	jal	ffffffffc0201e12 <alloc_pages>
	if (!page)
ffffffffc0201aec:	c91d                	beqz	a0,ffffffffc0201b22 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201aee:	000b4697          	auipc	a3,0xb4
ffffffffc0201af2:	fba6b683          	ld	a3,-70(a3) # ffffffffc02b5aa8 <pages>
ffffffffc0201af6:	00007797          	auipc	a5,0x7
ffffffffc0201afa:	8aa7b783          	ld	a5,-1878(a5) # ffffffffc02083a0 <nbase>
    return KADDR(page2pa(page));
ffffffffc0201afe:	000b4717          	auipc	a4,0xb4
ffffffffc0201b02:	fa273703          	ld	a4,-94(a4) # ffffffffc02b5aa0 <npage>
    return page - pages + nbase;
ffffffffc0201b06:	8d15                	sub	a0,a0,a3
ffffffffc0201b08:	8519                	srai	a0,a0,0x6
ffffffffc0201b0a:	953e                	add	a0,a0,a5
    return KADDR(page2pa(page));
ffffffffc0201b0c:	00c51793          	slli	a5,a0,0xc
ffffffffc0201b10:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201b12:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201b14:	00e7fa63          	bgeu	a5,a4,ffffffffc0201b28 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201b18:	000b4797          	auipc	a5,0xb4
ffffffffc0201b1c:	f807b783          	ld	a5,-128(a5) # ffffffffc02b5a98 <va_pa_offset>
ffffffffc0201b20:	953e                	add	a0,a0,a5
}
ffffffffc0201b22:	60a2                	ld	ra,8(sp)
ffffffffc0201b24:	0141                	addi	sp,sp,16
ffffffffc0201b26:	8082                	ret
ffffffffc0201b28:	86aa                	mv	a3,a0
ffffffffc0201b2a:	00005617          	auipc	a2,0x5
ffffffffc0201b2e:	cd660613          	addi	a2,a2,-810 # ffffffffc0206800 <etext+0xdc8>
ffffffffc0201b32:	07100593          	li	a1,113
ffffffffc0201b36:	00005517          	auipc	a0,0x5
ffffffffc0201b3a:	cf250513          	addi	a0,a0,-782 # ffffffffc0206828 <etext+0xdf0>
ffffffffc0201b3e:	90dfe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0201b42 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201b42:	7179                	addi	sp,sp,-48
ffffffffc0201b44:	f406                	sd	ra,40(sp)
ffffffffc0201b46:	f022                	sd	s0,32(sp)
ffffffffc0201b48:	ec26                	sd	s1,24(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201b4a:	01050713          	addi	a4,a0,16
ffffffffc0201b4e:	6785                	lui	a5,0x1
ffffffffc0201b50:	0af77e63          	bgeu	a4,a5,ffffffffc0201c0c <slob_alloc.constprop.0+0xca>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201b54:	00f50413          	addi	s0,a0,15
ffffffffc0201b58:	8011                	srli	s0,s0,0x4
ffffffffc0201b5a:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b5c:	100025f3          	csrr	a1,sstatus
ffffffffc0201b60:	8989                	andi	a1,a1,2
ffffffffc0201b62:	edd1                	bnez	a1,ffffffffc0201bfe <slob_alloc.constprop.0+0xbc>
	prev = slobfree;
ffffffffc0201b64:	000b0497          	auipc	s1,0xb0
ffffffffc0201b68:	a8448493          	addi	s1,s1,-1404 # ffffffffc02b15e8 <slobfree>
ffffffffc0201b6c:	6090                	ld	a2,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201b6e:	6618                	ld	a4,8(a2)
		if (cur->units >= units + delta)
ffffffffc0201b70:	4314                	lw	a3,0(a4)
ffffffffc0201b72:	0886da63          	bge	a3,s0,ffffffffc0201c06 <slob_alloc.constprop.0+0xc4>
		if (cur == slobfree)
ffffffffc0201b76:	00e60a63          	beq	a2,a4,ffffffffc0201b8a <slob_alloc.constprop.0+0x48>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201b7a:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201b7c:	4394                	lw	a3,0(a5)
ffffffffc0201b7e:	0286d863          	bge	a3,s0,ffffffffc0201bae <slob_alloc.constprop.0+0x6c>
		if (cur == slobfree)
ffffffffc0201b82:	6090                	ld	a2,0(s1)
ffffffffc0201b84:	873e                	mv	a4,a5
ffffffffc0201b86:	fee61ae3          	bne	a2,a4,ffffffffc0201b7a <slob_alloc.constprop.0+0x38>
    if (flag)
ffffffffc0201b8a:	e9b1                	bnez	a1,ffffffffc0201bde <slob_alloc.constprop.0+0x9c>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201b8c:	4501                	li	a0,0
ffffffffc0201b8e:	f51ff0ef          	jal	ffffffffc0201ade <__slob_get_free_pages.constprop.0>
ffffffffc0201b92:	87aa                	mv	a5,a0
			if (!cur)
ffffffffc0201b94:	c915                	beqz	a0,ffffffffc0201bc8 <slob_alloc.constprop.0+0x86>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201b96:	6585                	lui	a1,0x1
ffffffffc0201b98:	e35ff0ef          	jal	ffffffffc02019cc <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b9c:	100025f3          	csrr	a1,sstatus
ffffffffc0201ba0:	8989                	andi	a1,a1,2
ffffffffc0201ba2:	e98d                	bnez	a1,ffffffffc0201bd4 <slob_alloc.constprop.0+0x92>
			cur = slobfree;
ffffffffc0201ba4:	6098                	ld	a4,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201ba6:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201ba8:	4394                	lw	a3,0(a5)
ffffffffc0201baa:	fc86cce3          	blt	a3,s0,ffffffffc0201b82 <slob_alloc.constprop.0+0x40>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201bae:	04d40563          	beq	s0,a3,ffffffffc0201bf8 <slob_alloc.constprop.0+0xb6>
				prev->next = cur + units;
ffffffffc0201bb2:	00441613          	slli	a2,s0,0x4
ffffffffc0201bb6:	963e                	add	a2,a2,a5
ffffffffc0201bb8:	e710                	sd	a2,8(a4)
				prev->next->next = cur->next;
ffffffffc0201bba:	6788                	ld	a0,8(a5)
				prev->next->units = cur->units - units;
ffffffffc0201bbc:	9e81                	subw	a3,a3,s0
ffffffffc0201bbe:	c214                	sw	a3,0(a2)
				prev->next->next = cur->next;
ffffffffc0201bc0:	e608                	sd	a0,8(a2)
				cur->units = units;
ffffffffc0201bc2:	c380                	sw	s0,0(a5)
			slobfree = prev;
ffffffffc0201bc4:	e098                	sd	a4,0(s1)
    if (flag)
ffffffffc0201bc6:	ed99                	bnez	a1,ffffffffc0201be4 <slob_alloc.constprop.0+0xa2>
}
ffffffffc0201bc8:	70a2                	ld	ra,40(sp)
ffffffffc0201bca:	7402                	ld	s0,32(sp)
ffffffffc0201bcc:	64e2                	ld	s1,24(sp)
ffffffffc0201bce:	853e                	mv	a0,a5
ffffffffc0201bd0:	6145                	addi	sp,sp,48
ffffffffc0201bd2:	8082                	ret
        intr_disable();
ffffffffc0201bd4:	d2bfe0ef          	jal	ffffffffc02008fe <intr_disable>
			cur = slobfree;
ffffffffc0201bd8:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0201bda:	4585                	li	a1,1
ffffffffc0201bdc:	b7e9                	j	ffffffffc0201ba6 <slob_alloc.constprop.0+0x64>
        intr_enable();
ffffffffc0201bde:	d1bfe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0201be2:	b76d                	j	ffffffffc0201b8c <slob_alloc.constprop.0+0x4a>
ffffffffc0201be4:	e43e                	sd	a5,8(sp)
ffffffffc0201be6:	d13fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0201bea:	67a2                	ld	a5,8(sp)
}
ffffffffc0201bec:	70a2                	ld	ra,40(sp)
ffffffffc0201bee:	7402                	ld	s0,32(sp)
ffffffffc0201bf0:	64e2                	ld	s1,24(sp)
ffffffffc0201bf2:	853e                	mv	a0,a5
ffffffffc0201bf4:	6145                	addi	sp,sp,48
ffffffffc0201bf6:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201bf8:	6794                	ld	a3,8(a5)
ffffffffc0201bfa:	e714                	sd	a3,8(a4)
ffffffffc0201bfc:	b7e1                	j	ffffffffc0201bc4 <slob_alloc.constprop.0+0x82>
        intr_disable();
ffffffffc0201bfe:	d01fe0ef          	jal	ffffffffc02008fe <intr_disable>
        return 1;
ffffffffc0201c02:	4585                	li	a1,1
ffffffffc0201c04:	b785                	j	ffffffffc0201b64 <slob_alloc.constprop.0+0x22>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c06:	87ba                	mv	a5,a4
	prev = slobfree;
ffffffffc0201c08:	8732                	mv	a4,a2
ffffffffc0201c0a:	b755                	j	ffffffffc0201bae <slob_alloc.constprop.0+0x6c>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201c0c:	00005697          	auipc	a3,0x5
ffffffffc0201c10:	c2c68693          	addi	a3,a3,-980 # ffffffffc0206838 <etext+0xe00>
ffffffffc0201c14:	00005617          	auipc	a2,0x5
ffffffffc0201c18:	83c60613          	addi	a2,a2,-1988 # ffffffffc0206450 <etext+0xa18>
ffffffffc0201c1c:	06300593          	li	a1,99
ffffffffc0201c20:	00005517          	auipc	a0,0x5
ffffffffc0201c24:	c3850513          	addi	a0,a0,-968 # ffffffffc0206858 <etext+0xe20>
ffffffffc0201c28:	823fe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0201c2c <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201c2c:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201c2e:	00005517          	auipc	a0,0x5
ffffffffc0201c32:	c4250513          	addi	a0,a0,-958 # ffffffffc0206870 <etext+0xe38>
{
ffffffffc0201c36:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201c38:	d60fe0ef          	jal	ffffffffc0200198 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201c3c:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201c3e:	00005517          	auipc	a0,0x5
ffffffffc0201c42:	c4a50513          	addi	a0,a0,-950 # ffffffffc0206888 <etext+0xe50>
}
ffffffffc0201c46:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201c48:	d50fe06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0201c4c <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201c4c:	4501                	li	a0,0
ffffffffc0201c4e:	8082                	ret

ffffffffc0201c50 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201c50:	1101                	addi	sp,sp,-32
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201c52:	6685                	lui	a3,0x1
{
ffffffffc0201c54:	ec06                	sd	ra,24(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201c56:	16bd                	addi	a3,a3,-17 # fef <_binary_obj___user_softint_out_size-0x7f79>
ffffffffc0201c58:	04a6f963          	bgeu	a3,a0,ffffffffc0201caa <kmalloc+0x5a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201c5c:	e42a                	sd	a0,8(sp)
ffffffffc0201c5e:	4561                	li	a0,24
ffffffffc0201c60:	e822                	sd	s0,16(sp)
ffffffffc0201c62:	ee1ff0ef          	jal	ffffffffc0201b42 <slob_alloc.constprop.0>
ffffffffc0201c66:	842a                	mv	s0,a0
	if (!bb)
ffffffffc0201c68:	c541                	beqz	a0,ffffffffc0201cf0 <kmalloc+0xa0>
	bb->order = find_order(size);
ffffffffc0201c6a:	47a2                	lw	a5,8(sp)
	for (; size > 4096; size >>= 1)
ffffffffc0201c6c:	6705                	lui	a4,0x1
	int order = 0;
ffffffffc0201c6e:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201c70:	00f75763          	bge	a4,a5,ffffffffc0201c7e <kmalloc+0x2e>
ffffffffc0201c74:	4017d79b          	sraiw	a5,a5,0x1
		order++;
ffffffffc0201c78:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201c7a:	fef74de3          	blt	a4,a5,ffffffffc0201c74 <kmalloc+0x24>
	bb->order = find_order(size);
ffffffffc0201c7e:	c008                	sw	a0,0(s0)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201c80:	e5fff0ef          	jal	ffffffffc0201ade <__slob_get_free_pages.constprop.0>
ffffffffc0201c84:	e408                	sd	a0,8(s0)
	if (bb->pages)
ffffffffc0201c86:	cd31                	beqz	a0,ffffffffc0201ce2 <kmalloc+0x92>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c88:	100027f3          	csrr	a5,sstatus
ffffffffc0201c8c:	8b89                	andi	a5,a5,2
ffffffffc0201c8e:	eb85                	bnez	a5,ffffffffc0201cbe <kmalloc+0x6e>
		bb->next = bigblocks;
ffffffffc0201c90:	000b4797          	auipc	a5,0xb4
ffffffffc0201c94:	de87b783          	ld	a5,-536(a5) # ffffffffc02b5a78 <bigblocks>
		bigblocks = bb;
ffffffffc0201c98:	000b4717          	auipc	a4,0xb4
ffffffffc0201c9c:	de873023          	sd	s0,-544(a4) # ffffffffc02b5a78 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201ca0:	e81c                	sd	a5,16(s0)
    if (flag)
ffffffffc0201ca2:	6442                	ld	s0,16(sp)
	return __kmalloc(size, 0);
}
ffffffffc0201ca4:	60e2                	ld	ra,24(sp)
ffffffffc0201ca6:	6105                	addi	sp,sp,32
ffffffffc0201ca8:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201caa:	0541                	addi	a0,a0,16
ffffffffc0201cac:	e97ff0ef          	jal	ffffffffc0201b42 <slob_alloc.constprop.0>
ffffffffc0201cb0:	87aa                	mv	a5,a0
		return m ? (void *)(m + 1) : 0;
ffffffffc0201cb2:	0541                	addi	a0,a0,16
ffffffffc0201cb4:	fbe5                	bnez	a5,ffffffffc0201ca4 <kmalloc+0x54>
		return 0;
ffffffffc0201cb6:	4501                	li	a0,0
}
ffffffffc0201cb8:	60e2                	ld	ra,24(sp)
ffffffffc0201cba:	6105                	addi	sp,sp,32
ffffffffc0201cbc:	8082                	ret
        intr_disable();
ffffffffc0201cbe:	c41fe0ef          	jal	ffffffffc02008fe <intr_disable>
		bb->next = bigblocks;
ffffffffc0201cc2:	000b4797          	auipc	a5,0xb4
ffffffffc0201cc6:	db67b783          	ld	a5,-586(a5) # ffffffffc02b5a78 <bigblocks>
		bigblocks = bb;
ffffffffc0201cca:	000b4717          	auipc	a4,0xb4
ffffffffc0201cce:	da873723          	sd	s0,-594(a4) # ffffffffc02b5a78 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201cd2:	e81c                	sd	a5,16(s0)
        intr_enable();
ffffffffc0201cd4:	c25fe0ef          	jal	ffffffffc02008f8 <intr_enable>
		return bb->pages;
ffffffffc0201cd8:	6408                	ld	a0,8(s0)
}
ffffffffc0201cda:	60e2                	ld	ra,24(sp)
		return bb->pages;
ffffffffc0201cdc:	6442                	ld	s0,16(sp)
}
ffffffffc0201cde:	6105                	addi	sp,sp,32
ffffffffc0201ce0:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201ce2:	8522                	mv	a0,s0
ffffffffc0201ce4:	45e1                	li	a1,24
ffffffffc0201ce6:	ce7ff0ef          	jal	ffffffffc02019cc <slob_free>
		return 0;
ffffffffc0201cea:	4501                	li	a0,0
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201cec:	6442                	ld	s0,16(sp)
ffffffffc0201cee:	b7e9                	j	ffffffffc0201cb8 <kmalloc+0x68>
ffffffffc0201cf0:	6442                	ld	s0,16(sp)
		return 0;
ffffffffc0201cf2:	4501                	li	a0,0
ffffffffc0201cf4:	b7d1                	j	ffffffffc0201cb8 <kmalloc+0x68>

ffffffffc0201cf6 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201cf6:	c571                	beqz	a0,ffffffffc0201dc2 <kfree+0xcc>
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201cf8:	03451793          	slli	a5,a0,0x34
ffffffffc0201cfc:	e3e1                	bnez	a5,ffffffffc0201dbc <kfree+0xc6>
{
ffffffffc0201cfe:	1101                	addi	sp,sp,-32
ffffffffc0201d00:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d02:	100027f3          	csrr	a5,sstatus
ffffffffc0201d06:	8b89                	andi	a5,a5,2
ffffffffc0201d08:	e7c1                	bnez	a5,ffffffffc0201d90 <kfree+0x9a>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d0a:	000b4797          	auipc	a5,0xb4
ffffffffc0201d0e:	d6e7b783          	ld	a5,-658(a5) # ffffffffc02b5a78 <bigblocks>
    return 0;
ffffffffc0201d12:	4581                	li	a1,0
ffffffffc0201d14:	cbad                	beqz	a5,ffffffffc0201d86 <kfree+0x90>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201d16:	000b4617          	auipc	a2,0xb4
ffffffffc0201d1a:	d6260613          	addi	a2,a2,-670 # ffffffffc02b5a78 <bigblocks>
ffffffffc0201d1e:	a021                	j	ffffffffc0201d26 <kfree+0x30>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d20:	01070613          	addi	a2,a4,16
ffffffffc0201d24:	c3a5                	beqz	a5,ffffffffc0201d84 <kfree+0x8e>
		{
			if (bb->pages == block)
ffffffffc0201d26:	6794                	ld	a3,8(a5)
ffffffffc0201d28:	873e                	mv	a4,a5
			{
				*last = bb->next;
ffffffffc0201d2a:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201d2c:	fea69ae3          	bne	a3,a0,ffffffffc0201d20 <kfree+0x2a>
				*last = bb->next;
ffffffffc0201d30:	e21c                	sd	a5,0(a2)
    if (flag)
ffffffffc0201d32:	edb5                	bnez	a1,ffffffffc0201dae <kfree+0xb8>
    return pa2page(PADDR(kva));
ffffffffc0201d34:	c02007b7          	lui	a5,0xc0200
ffffffffc0201d38:	0af56263          	bltu	a0,a5,ffffffffc0201ddc <kfree+0xe6>
ffffffffc0201d3c:	000b4797          	auipc	a5,0xb4
ffffffffc0201d40:	d5c7b783          	ld	a5,-676(a5) # ffffffffc02b5a98 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0201d44:	000b4697          	auipc	a3,0xb4
ffffffffc0201d48:	d5c6b683          	ld	a3,-676(a3) # ffffffffc02b5aa0 <npage>
    return pa2page(PADDR(kva));
ffffffffc0201d4c:	8d1d                	sub	a0,a0,a5
    if (PPN(pa) >= npage)
ffffffffc0201d4e:	00c55793          	srli	a5,a0,0xc
ffffffffc0201d52:	06d7f963          	bgeu	a5,a3,ffffffffc0201dc4 <kfree+0xce>
    return &pages[PPN(pa) - nbase];
ffffffffc0201d56:	00006617          	auipc	a2,0x6
ffffffffc0201d5a:	64a63603          	ld	a2,1610(a2) # ffffffffc02083a0 <nbase>
ffffffffc0201d5e:	000b4517          	auipc	a0,0xb4
ffffffffc0201d62:	d4a53503          	ld	a0,-694(a0) # ffffffffc02b5aa8 <pages>
	free_pages(kva2page((void *)kva), 1 << order);
ffffffffc0201d66:	4314                	lw	a3,0(a4)
ffffffffc0201d68:	8f91                	sub	a5,a5,a2
ffffffffc0201d6a:	079a                	slli	a5,a5,0x6
ffffffffc0201d6c:	4585                	li	a1,1
ffffffffc0201d6e:	953e                	add	a0,a0,a5
ffffffffc0201d70:	00d595bb          	sllw	a1,a1,a3
ffffffffc0201d74:	e03a                	sd	a4,0(sp)
ffffffffc0201d76:	0d6000ef          	jal	ffffffffc0201e4c <free_pages>
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d7a:	6502                	ld	a0,0(sp)
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201d7c:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d7e:	45e1                	li	a1,24
}
ffffffffc0201d80:	6105                	addi	sp,sp,32
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d82:	b1a9                	j	ffffffffc02019cc <slob_free>
ffffffffc0201d84:	e185                	bnez	a1,ffffffffc0201da4 <kfree+0xae>
}
ffffffffc0201d86:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d88:	1541                	addi	a0,a0,-16
ffffffffc0201d8a:	4581                	li	a1,0
}
ffffffffc0201d8c:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d8e:	b93d                	j	ffffffffc02019cc <slob_free>
        intr_disable();
ffffffffc0201d90:	e02a                	sd	a0,0(sp)
ffffffffc0201d92:	b6dfe0ef          	jal	ffffffffc02008fe <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d96:	000b4797          	auipc	a5,0xb4
ffffffffc0201d9a:	ce27b783          	ld	a5,-798(a5) # ffffffffc02b5a78 <bigblocks>
ffffffffc0201d9e:	6502                	ld	a0,0(sp)
        return 1;
ffffffffc0201da0:	4585                	li	a1,1
ffffffffc0201da2:	fbb5                	bnez	a5,ffffffffc0201d16 <kfree+0x20>
ffffffffc0201da4:	e02a                	sd	a0,0(sp)
        intr_enable();
ffffffffc0201da6:	b53fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0201daa:	6502                	ld	a0,0(sp)
ffffffffc0201dac:	bfe9                	j	ffffffffc0201d86 <kfree+0x90>
ffffffffc0201dae:	e42a                	sd	a0,8(sp)
ffffffffc0201db0:	e03a                	sd	a4,0(sp)
ffffffffc0201db2:	b47fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0201db6:	6522                	ld	a0,8(sp)
ffffffffc0201db8:	6702                	ld	a4,0(sp)
ffffffffc0201dba:	bfad                	j	ffffffffc0201d34 <kfree+0x3e>
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201dbc:	1541                	addi	a0,a0,-16
ffffffffc0201dbe:	4581                	li	a1,0
ffffffffc0201dc0:	b131                	j	ffffffffc02019cc <slob_free>
ffffffffc0201dc2:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201dc4:	00005617          	auipc	a2,0x5
ffffffffc0201dc8:	b0c60613          	addi	a2,a2,-1268 # ffffffffc02068d0 <etext+0xe98>
ffffffffc0201dcc:	06900593          	li	a1,105
ffffffffc0201dd0:	00005517          	auipc	a0,0x5
ffffffffc0201dd4:	a5850513          	addi	a0,a0,-1448 # ffffffffc0206828 <etext+0xdf0>
ffffffffc0201dd8:	e72fe0ef          	jal	ffffffffc020044a <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201ddc:	86aa                	mv	a3,a0
ffffffffc0201dde:	00005617          	auipc	a2,0x5
ffffffffc0201de2:	aca60613          	addi	a2,a2,-1334 # ffffffffc02068a8 <etext+0xe70>
ffffffffc0201de6:	07700593          	li	a1,119
ffffffffc0201dea:	00005517          	auipc	a0,0x5
ffffffffc0201dee:	a3e50513          	addi	a0,a0,-1474 # ffffffffc0206828 <etext+0xdf0>
ffffffffc0201df2:	e58fe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0201df6 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201df6:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201df8:	00005617          	auipc	a2,0x5
ffffffffc0201dfc:	ad860613          	addi	a2,a2,-1320 # ffffffffc02068d0 <etext+0xe98>
ffffffffc0201e00:	06900593          	li	a1,105
ffffffffc0201e04:	00005517          	auipc	a0,0x5
ffffffffc0201e08:	a2450513          	addi	a0,a0,-1500 # ffffffffc0206828 <etext+0xdf0>
pa2page(uintptr_t pa)
ffffffffc0201e0c:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201e0e:	e3cfe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0201e12 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e12:	100027f3          	csrr	a5,sstatus
ffffffffc0201e16:	8b89                	andi	a5,a5,2
ffffffffc0201e18:	e799                	bnez	a5,ffffffffc0201e26 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e1a:	000b4797          	auipc	a5,0xb4
ffffffffc0201e1e:	c667b783          	ld	a5,-922(a5) # ffffffffc02b5a80 <pmm_manager>
ffffffffc0201e22:	6f9c                	ld	a5,24(a5)
ffffffffc0201e24:	8782                	jr	a5
{
ffffffffc0201e26:	1101                	addi	sp,sp,-32
ffffffffc0201e28:	ec06                	sd	ra,24(sp)
ffffffffc0201e2a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201e2c:	ad3fe0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e30:	000b4797          	auipc	a5,0xb4
ffffffffc0201e34:	c507b783          	ld	a5,-944(a5) # ffffffffc02b5a80 <pmm_manager>
ffffffffc0201e38:	6522                	ld	a0,8(sp)
ffffffffc0201e3a:	6f9c                	ld	a5,24(a5)
ffffffffc0201e3c:	9782                	jalr	a5
ffffffffc0201e3e:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201e40:	ab9fe0ef          	jal	ffffffffc02008f8 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201e44:	60e2                	ld	ra,24(sp)
ffffffffc0201e46:	6522                	ld	a0,8(sp)
ffffffffc0201e48:	6105                	addi	sp,sp,32
ffffffffc0201e4a:	8082                	ret

ffffffffc0201e4c <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e4c:	100027f3          	csrr	a5,sstatus
ffffffffc0201e50:	8b89                	andi	a5,a5,2
ffffffffc0201e52:	e799                	bnez	a5,ffffffffc0201e60 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201e54:	000b4797          	auipc	a5,0xb4
ffffffffc0201e58:	c2c7b783          	ld	a5,-980(a5) # ffffffffc02b5a80 <pmm_manager>
ffffffffc0201e5c:	739c                	ld	a5,32(a5)
ffffffffc0201e5e:	8782                	jr	a5
{
ffffffffc0201e60:	1101                	addi	sp,sp,-32
ffffffffc0201e62:	ec06                	sd	ra,24(sp)
ffffffffc0201e64:	e42e                	sd	a1,8(sp)
ffffffffc0201e66:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0201e68:	a97fe0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201e6c:	000b4797          	auipc	a5,0xb4
ffffffffc0201e70:	c147b783          	ld	a5,-1004(a5) # ffffffffc02b5a80 <pmm_manager>
ffffffffc0201e74:	65a2                	ld	a1,8(sp)
ffffffffc0201e76:	6502                	ld	a0,0(sp)
ffffffffc0201e78:	739c                	ld	a5,32(a5)
ffffffffc0201e7a:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201e7c:	60e2                	ld	ra,24(sp)
ffffffffc0201e7e:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201e80:	a79fe06f          	j	ffffffffc02008f8 <intr_enable>

ffffffffc0201e84 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e84:	100027f3          	csrr	a5,sstatus
ffffffffc0201e88:	8b89                	andi	a5,a5,2
ffffffffc0201e8a:	e799                	bnez	a5,ffffffffc0201e98 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201e8c:	000b4797          	auipc	a5,0xb4
ffffffffc0201e90:	bf47b783          	ld	a5,-1036(a5) # ffffffffc02b5a80 <pmm_manager>
ffffffffc0201e94:	779c                	ld	a5,40(a5)
ffffffffc0201e96:	8782                	jr	a5
{
ffffffffc0201e98:	1101                	addi	sp,sp,-32
ffffffffc0201e9a:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201e9c:	a63fe0ef          	jal	ffffffffc02008fe <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201ea0:	000b4797          	auipc	a5,0xb4
ffffffffc0201ea4:	be07b783          	ld	a5,-1056(a5) # ffffffffc02b5a80 <pmm_manager>
ffffffffc0201ea8:	779c                	ld	a5,40(a5)
ffffffffc0201eaa:	9782                	jalr	a5
ffffffffc0201eac:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201eae:	a4bfe0ef          	jal	ffffffffc02008f8 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201eb2:	60e2                	ld	ra,24(sp)
ffffffffc0201eb4:	6522                	ld	a0,8(sp)
ffffffffc0201eb6:	6105                	addi	sp,sp,32
ffffffffc0201eb8:	8082                	ret

ffffffffc0201eba <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201eba:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201ebe:	1ff7f793          	andi	a5,a5,511
ffffffffc0201ec2:	078e                	slli	a5,a5,0x3
ffffffffc0201ec4:	00f50733          	add	a4,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201ec8:	6314                	ld	a3,0(a4)
{
ffffffffc0201eca:	7139                	addi	sp,sp,-64
ffffffffc0201ecc:	f822                	sd	s0,48(sp)
ffffffffc0201ece:	f426                	sd	s1,40(sp)
ffffffffc0201ed0:	fc06                	sd	ra,56(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201ed2:	0016f793          	andi	a5,a3,1
{
ffffffffc0201ed6:	842e                	mv	s0,a1
ffffffffc0201ed8:	8832                	mv	a6,a2
ffffffffc0201eda:	000b4497          	auipc	s1,0xb4
ffffffffc0201ede:	bc648493          	addi	s1,s1,-1082 # ffffffffc02b5aa0 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201ee2:	ebd1                	bnez	a5,ffffffffc0201f76 <get_pte+0xbc>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201ee4:	16060d63          	beqz	a2,ffffffffc020205e <get_pte+0x1a4>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ee8:	100027f3          	csrr	a5,sstatus
ffffffffc0201eec:	8b89                	andi	a5,a5,2
ffffffffc0201eee:	16079e63          	bnez	a5,ffffffffc020206a <get_pte+0x1b0>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ef2:	000b4797          	auipc	a5,0xb4
ffffffffc0201ef6:	b8e7b783          	ld	a5,-1138(a5) # ffffffffc02b5a80 <pmm_manager>
ffffffffc0201efa:	4505                	li	a0,1
ffffffffc0201efc:	e43a                	sd	a4,8(sp)
ffffffffc0201efe:	6f9c                	ld	a5,24(a5)
ffffffffc0201f00:	e832                	sd	a2,16(sp)
ffffffffc0201f02:	9782                	jalr	a5
ffffffffc0201f04:	6722                	ld	a4,8(sp)
ffffffffc0201f06:	6842                	ld	a6,16(sp)
ffffffffc0201f08:	87aa                	mv	a5,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f0a:	14078a63          	beqz	a5,ffffffffc020205e <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201f0e:	000b4517          	auipc	a0,0xb4
ffffffffc0201f12:	b9a53503          	ld	a0,-1126(a0) # ffffffffc02b5aa8 <pages>
ffffffffc0201f16:	000808b7          	lui	a7,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f1a:	000b4497          	auipc	s1,0xb4
ffffffffc0201f1e:	b8648493          	addi	s1,s1,-1146 # ffffffffc02b5aa0 <npage>
ffffffffc0201f22:	40a78533          	sub	a0,a5,a0
ffffffffc0201f26:	8519                	srai	a0,a0,0x6
ffffffffc0201f28:	9546                	add	a0,a0,a7
ffffffffc0201f2a:	6090                	ld	a2,0(s1)
ffffffffc0201f2c:	00c51693          	slli	a3,a0,0xc
    page->ref = val;
ffffffffc0201f30:	4585                	li	a1,1
ffffffffc0201f32:	82b1                	srli	a3,a3,0xc
ffffffffc0201f34:	c38c                	sw	a1,0(a5)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201f36:	0532                	slli	a0,a0,0xc
ffffffffc0201f38:	1ac6f763          	bgeu	a3,a2,ffffffffc02020e6 <get_pte+0x22c>
ffffffffc0201f3c:	000b4697          	auipc	a3,0xb4
ffffffffc0201f40:	b5c6b683          	ld	a3,-1188(a3) # ffffffffc02b5a98 <va_pa_offset>
ffffffffc0201f44:	6605                	lui	a2,0x1
ffffffffc0201f46:	4581                	li	a1,0
ffffffffc0201f48:	9536                	add	a0,a0,a3
ffffffffc0201f4a:	ec42                	sd	a6,24(sp)
ffffffffc0201f4c:	e83e                	sd	a5,16(sp)
ffffffffc0201f4e:	e43a                	sd	a4,8(sp)
ffffffffc0201f50:	2bf030ef          	jal	ffffffffc0205a0e <memset>
    return page - pages + nbase;
ffffffffc0201f54:	000b4697          	auipc	a3,0xb4
ffffffffc0201f58:	b546b683          	ld	a3,-1196(a3) # ffffffffc02b5aa8 <pages>
ffffffffc0201f5c:	67c2                	ld	a5,16(sp)
ffffffffc0201f5e:	000808b7          	lui	a7,0x80
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201f62:	6722                	ld	a4,8(sp)
ffffffffc0201f64:	40d786b3          	sub	a3,a5,a3
ffffffffc0201f68:	8699                	srai	a3,a3,0x6
ffffffffc0201f6a:	96c6                	add	a3,a3,a7
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201f6c:	06aa                	slli	a3,a3,0xa
ffffffffc0201f6e:	6862                	ld	a6,24(sp)
ffffffffc0201f70:	0116e693          	ori	a3,a3,17
ffffffffc0201f74:	e314                	sd	a3,0(a4)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201f76:	c006f693          	andi	a3,a3,-1024
ffffffffc0201f7a:	6098                	ld	a4,0(s1)
ffffffffc0201f7c:	068a                	slli	a3,a3,0x2
ffffffffc0201f7e:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201f82:	14e7f663          	bgeu	a5,a4,ffffffffc02020ce <get_pte+0x214>
ffffffffc0201f86:	000b4897          	auipc	a7,0xb4
ffffffffc0201f8a:	b1288893          	addi	a7,a7,-1262 # ffffffffc02b5a98 <va_pa_offset>
ffffffffc0201f8e:	0008b603          	ld	a2,0(a7)
ffffffffc0201f92:	01545793          	srli	a5,s0,0x15
ffffffffc0201f96:	1ff7f793          	andi	a5,a5,511
ffffffffc0201f9a:	96b2                	add	a3,a3,a2
ffffffffc0201f9c:	078e                	slli	a5,a5,0x3
ffffffffc0201f9e:	97b6                	add	a5,a5,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201fa0:	6394                	ld	a3,0(a5)
ffffffffc0201fa2:	0016f613          	andi	a2,a3,1
ffffffffc0201fa6:	e659                	bnez	a2,ffffffffc0202034 <get_pte+0x17a>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201fa8:	0a080b63          	beqz	a6,ffffffffc020205e <get_pte+0x1a4>
ffffffffc0201fac:	10002773          	csrr	a4,sstatus
ffffffffc0201fb0:	8b09                	andi	a4,a4,2
ffffffffc0201fb2:	ef71                	bnez	a4,ffffffffc020208e <get_pte+0x1d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201fb4:	000b4717          	auipc	a4,0xb4
ffffffffc0201fb8:	acc73703          	ld	a4,-1332(a4) # ffffffffc02b5a80 <pmm_manager>
ffffffffc0201fbc:	4505                	li	a0,1
ffffffffc0201fbe:	e43e                	sd	a5,8(sp)
ffffffffc0201fc0:	6f18                	ld	a4,24(a4)
ffffffffc0201fc2:	9702                	jalr	a4
ffffffffc0201fc4:	67a2                	ld	a5,8(sp)
ffffffffc0201fc6:	872a                	mv	a4,a0
ffffffffc0201fc8:	000b4897          	auipc	a7,0xb4
ffffffffc0201fcc:	ad088893          	addi	a7,a7,-1328 # ffffffffc02b5a98 <va_pa_offset>
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201fd0:	c759                	beqz	a4,ffffffffc020205e <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201fd2:	000b4697          	auipc	a3,0xb4
ffffffffc0201fd6:	ad66b683          	ld	a3,-1322(a3) # ffffffffc02b5aa8 <pages>
ffffffffc0201fda:	00080837          	lui	a6,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201fde:	608c                	ld	a1,0(s1)
ffffffffc0201fe0:	40d706b3          	sub	a3,a4,a3
ffffffffc0201fe4:	8699                	srai	a3,a3,0x6
ffffffffc0201fe6:	96c2                	add	a3,a3,a6
ffffffffc0201fe8:	00c69613          	slli	a2,a3,0xc
    page->ref = val;
ffffffffc0201fec:	4505                	li	a0,1
ffffffffc0201fee:	8231                	srli	a2,a2,0xc
ffffffffc0201ff0:	c308                	sw	a0,0(a4)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201ff2:	06b2                	slli	a3,a3,0xc
ffffffffc0201ff4:	10b67663          	bgeu	a2,a1,ffffffffc0202100 <get_pte+0x246>
ffffffffc0201ff8:	0008b503          	ld	a0,0(a7)
ffffffffc0201ffc:	6605                	lui	a2,0x1
ffffffffc0201ffe:	4581                	li	a1,0
ffffffffc0202000:	9536                	add	a0,a0,a3
ffffffffc0202002:	e83a                	sd	a4,16(sp)
ffffffffc0202004:	e43e                	sd	a5,8(sp)
ffffffffc0202006:	209030ef          	jal	ffffffffc0205a0e <memset>
    return page - pages + nbase;
ffffffffc020200a:	000b4697          	auipc	a3,0xb4
ffffffffc020200e:	a9e6b683          	ld	a3,-1378(a3) # ffffffffc02b5aa8 <pages>
ffffffffc0202012:	6742                	ld	a4,16(sp)
ffffffffc0202014:	00080837          	lui	a6,0x80
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202018:	67a2                	ld	a5,8(sp)
ffffffffc020201a:	40d706b3          	sub	a3,a4,a3
ffffffffc020201e:	8699                	srai	a3,a3,0x6
ffffffffc0202020:	96c2                	add	a3,a3,a6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202022:	06aa                	slli	a3,a3,0xa
ffffffffc0202024:	0116e693          	ori	a3,a3,17
ffffffffc0202028:	e394                	sd	a3,0(a5)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020202a:	6098                	ld	a4,0(s1)
ffffffffc020202c:	000b4897          	auipc	a7,0xb4
ffffffffc0202030:	a6c88893          	addi	a7,a7,-1428 # ffffffffc02b5a98 <va_pa_offset>
ffffffffc0202034:	c006f693          	andi	a3,a3,-1024
ffffffffc0202038:	068a                	slli	a3,a3,0x2
ffffffffc020203a:	00c6d793          	srli	a5,a3,0xc
ffffffffc020203e:	06e7fc63          	bgeu	a5,a4,ffffffffc02020b6 <get_pte+0x1fc>
ffffffffc0202042:	0008b783          	ld	a5,0(a7)
ffffffffc0202046:	8031                	srli	s0,s0,0xc
ffffffffc0202048:	1ff47413          	andi	s0,s0,511
ffffffffc020204c:	040e                	slli	s0,s0,0x3
ffffffffc020204e:	96be                	add	a3,a3,a5
}
ffffffffc0202050:	70e2                	ld	ra,56(sp)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202052:	00868533          	add	a0,a3,s0
}
ffffffffc0202056:	7442                	ld	s0,48(sp)
ffffffffc0202058:	74a2                	ld	s1,40(sp)
ffffffffc020205a:	6121                	addi	sp,sp,64
ffffffffc020205c:	8082                	ret
ffffffffc020205e:	70e2                	ld	ra,56(sp)
ffffffffc0202060:	7442                	ld	s0,48(sp)
ffffffffc0202062:	74a2                	ld	s1,40(sp)
            return NULL;
ffffffffc0202064:	4501                	li	a0,0
}
ffffffffc0202066:	6121                	addi	sp,sp,64
ffffffffc0202068:	8082                	ret
        intr_disable();
ffffffffc020206a:	e83a                	sd	a4,16(sp)
ffffffffc020206c:	ec32                	sd	a2,24(sp)
ffffffffc020206e:	891fe0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202072:	000b4797          	auipc	a5,0xb4
ffffffffc0202076:	a0e7b783          	ld	a5,-1522(a5) # ffffffffc02b5a80 <pmm_manager>
ffffffffc020207a:	4505                	li	a0,1
ffffffffc020207c:	6f9c                	ld	a5,24(a5)
ffffffffc020207e:	9782                	jalr	a5
ffffffffc0202080:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0202082:	877fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202086:	6862                	ld	a6,24(sp)
ffffffffc0202088:	6742                	ld	a4,16(sp)
ffffffffc020208a:	67a2                	ld	a5,8(sp)
ffffffffc020208c:	bdbd                	j	ffffffffc0201f0a <get_pte+0x50>
        intr_disable();
ffffffffc020208e:	e83e                	sd	a5,16(sp)
ffffffffc0202090:	86ffe0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0202094:	000b4717          	auipc	a4,0xb4
ffffffffc0202098:	9ec73703          	ld	a4,-1556(a4) # ffffffffc02b5a80 <pmm_manager>
ffffffffc020209c:	4505                	li	a0,1
ffffffffc020209e:	6f18                	ld	a4,24(a4)
ffffffffc02020a0:	9702                	jalr	a4
ffffffffc02020a2:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02020a4:	855fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc02020a8:	6722                	ld	a4,8(sp)
ffffffffc02020aa:	67c2                	ld	a5,16(sp)
ffffffffc02020ac:	000b4897          	auipc	a7,0xb4
ffffffffc02020b0:	9ec88893          	addi	a7,a7,-1556 # ffffffffc02b5a98 <va_pa_offset>
ffffffffc02020b4:	bf31                	j	ffffffffc0201fd0 <get_pte+0x116>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02020b6:	00004617          	auipc	a2,0x4
ffffffffc02020ba:	74a60613          	addi	a2,a2,1866 # ffffffffc0206800 <etext+0xdc8>
ffffffffc02020be:	0fa00593          	li	a1,250
ffffffffc02020c2:	00005517          	auipc	a0,0x5
ffffffffc02020c6:	82e50513          	addi	a0,a0,-2002 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc02020ca:	b80fe0ef          	jal	ffffffffc020044a <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02020ce:	00004617          	auipc	a2,0x4
ffffffffc02020d2:	73260613          	addi	a2,a2,1842 # ffffffffc0206800 <etext+0xdc8>
ffffffffc02020d6:	0ed00593          	li	a1,237
ffffffffc02020da:	00005517          	auipc	a0,0x5
ffffffffc02020de:	81650513          	addi	a0,a0,-2026 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc02020e2:	b68fe0ef          	jal	ffffffffc020044a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02020e6:	86aa                	mv	a3,a0
ffffffffc02020e8:	00004617          	auipc	a2,0x4
ffffffffc02020ec:	71860613          	addi	a2,a2,1816 # ffffffffc0206800 <etext+0xdc8>
ffffffffc02020f0:	0e900593          	li	a1,233
ffffffffc02020f4:	00004517          	auipc	a0,0x4
ffffffffc02020f8:	7fc50513          	addi	a0,a0,2044 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc02020fc:	b4efe0ef          	jal	ffffffffc020044a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202100:	00004617          	auipc	a2,0x4
ffffffffc0202104:	70060613          	addi	a2,a2,1792 # ffffffffc0206800 <etext+0xdc8>
ffffffffc0202108:	0f700593          	li	a1,247
ffffffffc020210c:	00004517          	auipc	a0,0x4
ffffffffc0202110:	7e450513          	addi	a0,a0,2020 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0202114:	b36fe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0202118 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0202118:	1141                	addi	sp,sp,-16
ffffffffc020211a:	e022                	sd	s0,0(sp)
ffffffffc020211c:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020211e:	4601                	li	a2,0
{
ffffffffc0202120:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202122:	d99ff0ef          	jal	ffffffffc0201eba <get_pte>
    if (ptep_store != NULL)
ffffffffc0202126:	c011                	beqz	s0,ffffffffc020212a <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0202128:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020212a:	c511                	beqz	a0,ffffffffc0202136 <get_page+0x1e>
ffffffffc020212c:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc020212e:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202130:	0017f713          	andi	a4,a5,1
ffffffffc0202134:	e709                	bnez	a4,ffffffffc020213e <get_page+0x26>
}
ffffffffc0202136:	60a2                	ld	ra,8(sp)
ffffffffc0202138:	6402                	ld	s0,0(sp)
ffffffffc020213a:	0141                	addi	sp,sp,16
ffffffffc020213c:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc020213e:	000b4717          	auipc	a4,0xb4
ffffffffc0202142:	96273703          	ld	a4,-1694(a4) # ffffffffc02b5aa0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0202146:	078a                	slli	a5,a5,0x2
ffffffffc0202148:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020214a:	00e7ff63          	bgeu	a5,a4,ffffffffc0202168 <get_page+0x50>
    return &pages[PPN(pa) - nbase];
ffffffffc020214e:	000b4517          	auipc	a0,0xb4
ffffffffc0202152:	95a53503          	ld	a0,-1702(a0) # ffffffffc02b5aa8 <pages>
ffffffffc0202156:	60a2                	ld	ra,8(sp)
ffffffffc0202158:	6402                	ld	s0,0(sp)
ffffffffc020215a:	079a                	slli	a5,a5,0x6
ffffffffc020215c:	fe000737          	lui	a4,0xfe000
ffffffffc0202160:	97ba                	add	a5,a5,a4
ffffffffc0202162:	953e                	add	a0,a0,a5
ffffffffc0202164:	0141                	addi	sp,sp,16
ffffffffc0202166:	8082                	ret
ffffffffc0202168:	c8fff0ef          	jal	ffffffffc0201df6 <pa2page.part.0>

ffffffffc020216c <unmap_range>:
        tlb_invalidate(pgdir, la); //(6) flush tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc020216c:	715d                	addi	sp,sp,-80
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020216e:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202172:	e486                	sd	ra,72(sp)
ffffffffc0202174:	e0a2                	sd	s0,64(sp)
ffffffffc0202176:	fc26                	sd	s1,56(sp)
ffffffffc0202178:	f84a                	sd	s2,48(sp)
ffffffffc020217a:	f44e                	sd	s3,40(sp)
ffffffffc020217c:	f052                	sd	s4,32(sp)
ffffffffc020217e:	ec56                	sd	s5,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202180:	03479713          	slli	a4,a5,0x34
ffffffffc0202184:	ef61                	bnez	a4,ffffffffc020225c <unmap_range+0xf0>
    assert(USER_ACCESS(start, end));
ffffffffc0202186:	00200a37          	lui	s4,0x200
ffffffffc020218a:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc020218e:	0145b733          	sltu	a4,a1,s4
ffffffffc0202192:	0017b793          	seqz	a5,a5
ffffffffc0202196:	8fd9                	or	a5,a5,a4
ffffffffc0202198:	842e                	mv	s0,a1
ffffffffc020219a:	84b2                	mv	s1,a2
ffffffffc020219c:	e3e5                	bnez	a5,ffffffffc020227c <unmap_range+0x110>
ffffffffc020219e:	4785                	li	a5,1
ffffffffc02021a0:	07fe                	slli	a5,a5,0x1f
ffffffffc02021a2:	0785                	addi	a5,a5,1
ffffffffc02021a4:	892a                	mv	s2,a0
ffffffffc02021a6:	6985                	lui	s3,0x1
    do
    {
        pte_t *ptep = get_pte(pgdir, start, 0);
        if (ptep == NULL)
        {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02021a8:	ffe00ab7          	lui	s5,0xffe00
    assert(USER_ACCESS(start, end));
ffffffffc02021ac:	0cf67863          	bgeu	a2,a5,ffffffffc020227c <unmap_range+0x110>
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc02021b0:	4601                	li	a2,0
ffffffffc02021b2:	85a2                	mv	a1,s0
ffffffffc02021b4:	854a                	mv	a0,s2
ffffffffc02021b6:	d05ff0ef          	jal	ffffffffc0201eba <get_pte>
ffffffffc02021ba:	87aa                	mv	a5,a0
        if (ptep == NULL)
ffffffffc02021bc:	cd31                	beqz	a0,ffffffffc0202218 <unmap_range+0xac>
            continue;
        }
        if (*ptep != 0)
ffffffffc02021be:	6118                	ld	a4,0(a0)
ffffffffc02021c0:	ef11                	bnez	a4,ffffffffc02021dc <unmap_range+0x70>
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02021c2:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc02021c4:	c019                	beqz	s0,ffffffffc02021ca <unmap_range+0x5e>
ffffffffc02021c6:	fe9465e3          	bltu	s0,s1,ffffffffc02021b0 <unmap_range+0x44>
}
ffffffffc02021ca:	60a6                	ld	ra,72(sp)
ffffffffc02021cc:	6406                	ld	s0,64(sp)
ffffffffc02021ce:	74e2                	ld	s1,56(sp)
ffffffffc02021d0:	7942                	ld	s2,48(sp)
ffffffffc02021d2:	79a2                	ld	s3,40(sp)
ffffffffc02021d4:	7a02                	ld	s4,32(sp)
ffffffffc02021d6:	6ae2                	ld	s5,24(sp)
ffffffffc02021d8:	6161                	addi	sp,sp,80
ffffffffc02021da:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc02021dc:	00177693          	andi	a3,a4,1
ffffffffc02021e0:	d2ed                	beqz	a3,ffffffffc02021c2 <unmap_range+0x56>
    if (PPN(pa) >= npage)
ffffffffc02021e2:	000b4697          	auipc	a3,0xb4
ffffffffc02021e6:	8be6b683          	ld	a3,-1858(a3) # ffffffffc02b5aa0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02021ea:	070a                	slli	a4,a4,0x2
ffffffffc02021ec:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc02021ee:	0ad77763          	bgeu	a4,a3,ffffffffc020229c <unmap_range+0x130>
    return &pages[PPN(pa) - nbase];
ffffffffc02021f2:	000b4517          	auipc	a0,0xb4
ffffffffc02021f6:	8b653503          	ld	a0,-1866(a0) # ffffffffc02b5aa8 <pages>
ffffffffc02021fa:	071a                	slli	a4,a4,0x6
ffffffffc02021fc:	fe0006b7          	lui	a3,0xfe000
ffffffffc0202200:	9736                	add	a4,a4,a3
ffffffffc0202202:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc0202204:	4118                	lw	a4,0(a0)
ffffffffc0202206:	377d                	addiw	a4,a4,-1 # fffffffffdffffff <end+0x3dd4a51f>
ffffffffc0202208:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc020220a:	cb19                	beqz	a4,ffffffffc0202220 <unmap_range+0xb4>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc020220c:	0007b023          	sd	zero,0(a5)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202210:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202214:	944e                	add	s0,s0,s3
ffffffffc0202216:	b77d                	j	ffffffffc02021c4 <unmap_range+0x58>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202218:	9452                	add	s0,s0,s4
ffffffffc020221a:	01547433          	and	s0,s0,s5
            continue;
ffffffffc020221e:	b75d                	j	ffffffffc02021c4 <unmap_range+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202220:	10002773          	csrr	a4,sstatus
ffffffffc0202224:	8b09                	andi	a4,a4,2
ffffffffc0202226:	eb19                	bnez	a4,ffffffffc020223c <unmap_range+0xd0>
        pmm_manager->free_pages(base, n);
ffffffffc0202228:	000b4717          	auipc	a4,0xb4
ffffffffc020222c:	85873703          	ld	a4,-1960(a4) # ffffffffc02b5a80 <pmm_manager>
ffffffffc0202230:	4585                	li	a1,1
ffffffffc0202232:	e03e                	sd	a5,0(sp)
ffffffffc0202234:	7318                	ld	a4,32(a4)
ffffffffc0202236:	9702                	jalr	a4
    if (flag)
ffffffffc0202238:	6782                	ld	a5,0(sp)
ffffffffc020223a:	bfc9                	j	ffffffffc020220c <unmap_range+0xa0>
        intr_disable();
ffffffffc020223c:	e43e                	sd	a5,8(sp)
ffffffffc020223e:	e02a                	sd	a0,0(sp)
ffffffffc0202240:	ebefe0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0202244:	000b4717          	auipc	a4,0xb4
ffffffffc0202248:	83c73703          	ld	a4,-1988(a4) # ffffffffc02b5a80 <pmm_manager>
ffffffffc020224c:	6502                	ld	a0,0(sp)
ffffffffc020224e:	4585                	li	a1,1
ffffffffc0202250:	7318                	ld	a4,32(a4)
ffffffffc0202252:	9702                	jalr	a4
        intr_enable();
ffffffffc0202254:	ea4fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202258:	67a2                	ld	a5,8(sp)
ffffffffc020225a:	bf4d                	j	ffffffffc020220c <unmap_range+0xa0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020225c:	00004697          	auipc	a3,0x4
ffffffffc0202260:	6a468693          	addi	a3,a3,1700 # ffffffffc0206900 <etext+0xec8>
ffffffffc0202264:	00004617          	auipc	a2,0x4
ffffffffc0202268:	1ec60613          	addi	a2,a2,492 # ffffffffc0206450 <etext+0xa18>
ffffffffc020226c:	12200593          	li	a1,290
ffffffffc0202270:	00004517          	auipc	a0,0x4
ffffffffc0202274:	68050513          	addi	a0,a0,1664 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0202278:	9d2fe0ef          	jal	ffffffffc020044a <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020227c:	00004697          	auipc	a3,0x4
ffffffffc0202280:	6b468693          	addi	a3,a3,1716 # ffffffffc0206930 <etext+0xef8>
ffffffffc0202284:	00004617          	auipc	a2,0x4
ffffffffc0202288:	1cc60613          	addi	a2,a2,460 # ffffffffc0206450 <etext+0xa18>
ffffffffc020228c:	12300593          	li	a1,291
ffffffffc0202290:	00004517          	auipc	a0,0x4
ffffffffc0202294:	66050513          	addi	a0,a0,1632 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0202298:	9b2fe0ef          	jal	ffffffffc020044a <__panic>
ffffffffc020229c:	b5bff0ef          	jal	ffffffffc0201df6 <pa2page.part.0>

ffffffffc02022a0 <exit_range>:
{
ffffffffc02022a0:	7135                	addi	sp,sp,-160
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022a2:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02022a6:	ed06                	sd	ra,152(sp)
ffffffffc02022a8:	e922                	sd	s0,144(sp)
ffffffffc02022aa:	e526                	sd	s1,136(sp)
ffffffffc02022ac:	e14a                	sd	s2,128(sp)
ffffffffc02022ae:	fcce                	sd	s3,120(sp)
ffffffffc02022b0:	f8d2                	sd	s4,112(sp)
ffffffffc02022b2:	f4d6                	sd	s5,104(sp)
ffffffffc02022b4:	f0da                	sd	s6,96(sp)
ffffffffc02022b6:	ecde                	sd	s7,88(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022b8:	17d2                	slli	a5,a5,0x34
ffffffffc02022ba:	22079263          	bnez	a5,ffffffffc02024de <exit_range+0x23e>
    assert(USER_ACCESS(start, end));
ffffffffc02022be:	00200937          	lui	s2,0x200
ffffffffc02022c2:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc02022c6:	0125b733          	sltu	a4,a1,s2
ffffffffc02022ca:	0017b793          	seqz	a5,a5
ffffffffc02022ce:	8fd9                	or	a5,a5,a4
ffffffffc02022d0:	26079263          	bnez	a5,ffffffffc0202534 <exit_range+0x294>
ffffffffc02022d4:	4785                	li	a5,1
ffffffffc02022d6:	07fe                	slli	a5,a5,0x1f
ffffffffc02022d8:	0785                	addi	a5,a5,1
ffffffffc02022da:	24f67d63          	bgeu	a2,a5,ffffffffc0202534 <exit_range+0x294>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc02022de:	c00004b7          	lui	s1,0xc0000
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc02022e2:	ffe007b7          	lui	a5,0xffe00
ffffffffc02022e6:	8a2a                	mv	s4,a0
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc02022e8:	8ced                	and	s1,s1,a1
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc02022ea:	00f5f833          	and	a6,a1,a5
    if (PPN(pa) >= npage)
ffffffffc02022ee:	000b3a97          	auipc	s5,0xb3
ffffffffc02022f2:	7b2a8a93          	addi	s5,s5,1970 # ffffffffc02b5aa0 <npage>
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02022f6:	400009b7          	lui	s3,0x40000
ffffffffc02022fa:	a809                	j	ffffffffc020230c <exit_range+0x6c>
        d1start += PDSIZE;
ffffffffc02022fc:	013487b3          	add	a5,s1,s3
ffffffffc0202300:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc0202304:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc0202306:	c3f1                	beqz	a5,ffffffffc02023ca <exit_range+0x12a>
ffffffffc0202308:	0cc7f163          	bgeu	a5,a2,ffffffffc02023ca <exit_range+0x12a>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc020230c:	01e4d413          	srli	s0,s1,0x1e
ffffffffc0202310:	1ff47413          	andi	s0,s0,511
ffffffffc0202314:	040e                	slli	s0,s0,0x3
ffffffffc0202316:	9452                	add	s0,s0,s4
ffffffffc0202318:	00043883          	ld	a7,0(s0)
        if (pde1 & PTE_V)
ffffffffc020231c:	0018f793          	andi	a5,a7,1
ffffffffc0202320:	dff1                	beqz	a5,ffffffffc02022fc <exit_range+0x5c>
ffffffffc0202322:	000ab783          	ld	a5,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202326:	088a                	slli	a7,a7,0x2
ffffffffc0202328:	00c8d893          	srli	a7,a7,0xc
    if (PPN(pa) >= npage)
ffffffffc020232c:	20f8f263          	bgeu	a7,a5,ffffffffc0202530 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc0202330:	fff802b7          	lui	t0,0xfff80
ffffffffc0202334:	00588f33          	add	t5,a7,t0
    return page - pages + nbase;
ffffffffc0202338:	000803b7          	lui	t2,0x80
ffffffffc020233c:	007f0733          	add	a4,t5,t2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202340:	00c71e13          	slli	t3,a4,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0202344:	0f1a                	slli	t5,t5,0x6
    return KADDR(page2pa(page));
ffffffffc0202346:	1cf77863          	bgeu	a4,a5,ffffffffc0202516 <exit_range+0x276>
ffffffffc020234a:	000b3f97          	auipc	t6,0xb3
ffffffffc020234e:	74ef8f93          	addi	t6,t6,1870 # ffffffffc02b5a98 <va_pa_offset>
ffffffffc0202352:	000fb783          	ld	a5,0(t6)
            free_pd0 = 1;
ffffffffc0202356:	4e85                	li	t4,1
ffffffffc0202358:	6b05                	lui	s6,0x1
ffffffffc020235a:	9e3e                	add	t3,t3,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc020235c:	01348333          	add	t1,s1,s3
                pde0 = pd0[PDX0(d0start)];
ffffffffc0202360:	01585713          	srli	a4,a6,0x15
ffffffffc0202364:	1ff77713          	andi	a4,a4,511
ffffffffc0202368:	070e                	slli	a4,a4,0x3
ffffffffc020236a:	9772                	add	a4,a4,t3
ffffffffc020236c:	631c                	ld	a5,0(a4)
                if (pde0 & PTE_V)
ffffffffc020236e:	0017f693          	andi	a3,a5,1
ffffffffc0202372:	e6bd                	bnez	a3,ffffffffc02023e0 <exit_range+0x140>
                    free_pd0 = 0;
ffffffffc0202374:	4e81                	li	t4,0
                d0start += PTSIZE;
ffffffffc0202376:	984a                	add	a6,a6,s2
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202378:	00080863          	beqz	a6,ffffffffc0202388 <exit_range+0xe8>
ffffffffc020237c:	879a                	mv	a5,t1
ffffffffc020237e:	00667363          	bgeu	a2,t1,ffffffffc0202384 <exit_range+0xe4>
ffffffffc0202382:	87b2                	mv	a5,a2
ffffffffc0202384:	fcf86ee3          	bltu	a6,a5,ffffffffc0202360 <exit_range+0xc0>
            if (free_pd0)
ffffffffc0202388:	f60e8ae3          	beqz	t4,ffffffffc02022fc <exit_range+0x5c>
    if (PPN(pa) >= npage)
ffffffffc020238c:	000ab783          	ld	a5,0(s5)
ffffffffc0202390:	1af8f063          	bgeu	a7,a5,ffffffffc0202530 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc0202394:	000b3517          	auipc	a0,0xb3
ffffffffc0202398:	71453503          	ld	a0,1812(a0) # ffffffffc02b5aa8 <pages>
ffffffffc020239c:	957a                	add	a0,a0,t5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020239e:	100027f3          	csrr	a5,sstatus
ffffffffc02023a2:	8b89                	andi	a5,a5,2
ffffffffc02023a4:	10079b63          	bnez	a5,ffffffffc02024ba <exit_range+0x21a>
        pmm_manager->free_pages(base, n);
ffffffffc02023a8:	000b3797          	auipc	a5,0xb3
ffffffffc02023ac:	6d87b783          	ld	a5,1752(a5) # ffffffffc02b5a80 <pmm_manager>
ffffffffc02023b0:	4585                	li	a1,1
ffffffffc02023b2:	e432                	sd	a2,8(sp)
ffffffffc02023b4:	739c                	ld	a5,32(a5)
ffffffffc02023b6:	9782                	jalr	a5
ffffffffc02023b8:	6622                	ld	a2,8(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc02023ba:	00043023          	sd	zero,0(s0)
        d1start += PDSIZE;
ffffffffc02023be:	013487b3          	add	a5,s1,s3
ffffffffc02023c2:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc02023c6:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc02023c8:	f3a1                	bnez	a5,ffffffffc0202308 <exit_range+0x68>
}
ffffffffc02023ca:	60ea                	ld	ra,152(sp)
ffffffffc02023cc:	644a                	ld	s0,144(sp)
ffffffffc02023ce:	64aa                	ld	s1,136(sp)
ffffffffc02023d0:	690a                	ld	s2,128(sp)
ffffffffc02023d2:	79e6                	ld	s3,120(sp)
ffffffffc02023d4:	7a46                	ld	s4,112(sp)
ffffffffc02023d6:	7aa6                	ld	s5,104(sp)
ffffffffc02023d8:	7b06                	ld	s6,96(sp)
ffffffffc02023da:	6be6                	ld	s7,88(sp)
ffffffffc02023dc:	610d                	addi	sp,sp,160
ffffffffc02023de:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02023e0:	000ab503          	ld	a0,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc02023e4:	078a                	slli	a5,a5,0x2
ffffffffc02023e6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02023e8:	14a7f463          	bgeu	a5,a0,ffffffffc0202530 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc02023ec:	9796                	add	a5,a5,t0
    return page - pages + nbase;
ffffffffc02023ee:	00778bb3          	add	s7,a5,t2
    return &pages[PPN(pa) - nbase];
ffffffffc02023f2:	00679593          	slli	a1,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02023f6:	00cb9693          	slli	a3,s7,0xc
    return KADDR(page2pa(page));
ffffffffc02023fa:	10abf263          	bgeu	s7,a0,ffffffffc02024fe <exit_range+0x25e>
ffffffffc02023fe:	000fb783          	ld	a5,0(t6)
ffffffffc0202402:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202404:	01668533          	add	a0,a3,s6
                        if (pt[i] & PTE_V)
ffffffffc0202408:	629c                	ld	a5,0(a3)
ffffffffc020240a:	8b85                	andi	a5,a5,1
ffffffffc020240c:	f7ad                	bnez	a5,ffffffffc0202376 <exit_range+0xd6>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc020240e:	06a1                	addi	a3,a3,8
ffffffffc0202410:	fea69ce3          	bne	a3,a0,ffffffffc0202408 <exit_range+0x168>
    return &pages[PPN(pa) - nbase];
ffffffffc0202414:	000b3517          	auipc	a0,0xb3
ffffffffc0202418:	69453503          	ld	a0,1684(a0) # ffffffffc02b5aa8 <pages>
ffffffffc020241c:	952e                	add	a0,a0,a1
ffffffffc020241e:	100027f3          	csrr	a5,sstatus
ffffffffc0202422:	8b89                	andi	a5,a5,2
ffffffffc0202424:	e3b9                	bnez	a5,ffffffffc020246a <exit_range+0x1ca>
        pmm_manager->free_pages(base, n);
ffffffffc0202426:	000b3797          	auipc	a5,0xb3
ffffffffc020242a:	65a7b783          	ld	a5,1626(a5) # ffffffffc02b5a80 <pmm_manager>
ffffffffc020242e:	4585                	li	a1,1
ffffffffc0202430:	e0b2                	sd	a2,64(sp)
ffffffffc0202432:	739c                	ld	a5,32(a5)
ffffffffc0202434:	fc1a                	sd	t1,56(sp)
ffffffffc0202436:	f846                	sd	a7,48(sp)
ffffffffc0202438:	f47a                	sd	t5,40(sp)
ffffffffc020243a:	f072                	sd	t3,32(sp)
ffffffffc020243c:	ec76                	sd	t4,24(sp)
ffffffffc020243e:	e842                	sd	a6,16(sp)
ffffffffc0202440:	e43a                	sd	a4,8(sp)
ffffffffc0202442:	9782                	jalr	a5
    if (flag)
ffffffffc0202444:	6722                	ld	a4,8(sp)
ffffffffc0202446:	6842                	ld	a6,16(sp)
ffffffffc0202448:	6ee2                	ld	t4,24(sp)
ffffffffc020244a:	7e02                	ld	t3,32(sp)
ffffffffc020244c:	7f22                	ld	t5,40(sp)
ffffffffc020244e:	78c2                	ld	a7,48(sp)
ffffffffc0202450:	7362                	ld	t1,56(sp)
ffffffffc0202452:	6606                	ld	a2,64(sp)
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202454:	fff802b7          	lui	t0,0xfff80
ffffffffc0202458:	000803b7          	lui	t2,0x80
ffffffffc020245c:	000b3f97          	auipc	t6,0xb3
ffffffffc0202460:	63cf8f93          	addi	t6,t6,1596 # ffffffffc02b5a98 <va_pa_offset>
ffffffffc0202464:	00073023          	sd	zero,0(a4)
ffffffffc0202468:	b739                	j	ffffffffc0202376 <exit_range+0xd6>
        intr_disable();
ffffffffc020246a:	e4b2                	sd	a2,72(sp)
ffffffffc020246c:	e09a                	sd	t1,64(sp)
ffffffffc020246e:	fc46                	sd	a7,56(sp)
ffffffffc0202470:	f47a                	sd	t5,40(sp)
ffffffffc0202472:	f072                	sd	t3,32(sp)
ffffffffc0202474:	ec76                	sd	t4,24(sp)
ffffffffc0202476:	e842                	sd	a6,16(sp)
ffffffffc0202478:	e43a                	sd	a4,8(sp)
ffffffffc020247a:	f82a                	sd	a0,48(sp)
ffffffffc020247c:	c82fe0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202480:	000b3797          	auipc	a5,0xb3
ffffffffc0202484:	6007b783          	ld	a5,1536(a5) # ffffffffc02b5a80 <pmm_manager>
ffffffffc0202488:	7542                	ld	a0,48(sp)
ffffffffc020248a:	4585                	li	a1,1
ffffffffc020248c:	739c                	ld	a5,32(a5)
ffffffffc020248e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202490:	c68fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202494:	6722                	ld	a4,8(sp)
ffffffffc0202496:	6626                	ld	a2,72(sp)
ffffffffc0202498:	6306                	ld	t1,64(sp)
ffffffffc020249a:	78e2                	ld	a7,56(sp)
ffffffffc020249c:	7f22                	ld	t5,40(sp)
ffffffffc020249e:	7e02                	ld	t3,32(sp)
ffffffffc02024a0:	6ee2                	ld	t4,24(sp)
ffffffffc02024a2:	6842                	ld	a6,16(sp)
ffffffffc02024a4:	000b3f97          	auipc	t6,0xb3
ffffffffc02024a8:	5f4f8f93          	addi	t6,t6,1524 # ffffffffc02b5a98 <va_pa_offset>
ffffffffc02024ac:	000803b7          	lui	t2,0x80
ffffffffc02024b0:	fff802b7          	lui	t0,0xfff80
                        pd0[PDX0(d0start)] = 0;
ffffffffc02024b4:	00073023          	sd	zero,0(a4)
ffffffffc02024b8:	bd7d                	j	ffffffffc0202376 <exit_range+0xd6>
        intr_disable();
ffffffffc02024ba:	e832                	sd	a2,16(sp)
ffffffffc02024bc:	e42a                	sd	a0,8(sp)
ffffffffc02024be:	c40fe0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02024c2:	000b3797          	auipc	a5,0xb3
ffffffffc02024c6:	5be7b783          	ld	a5,1470(a5) # ffffffffc02b5a80 <pmm_manager>
ffffffffc02024ca:	6522                	ld	a0,8(sp)
ffffffffc02024cc:	4585                	li	a1,1
ffffffffc02024ce:	739c                	ld	a5,32(a5)
ffffffffc02024d0:	9782                	jalr	a5
        intr_enable();
ffffffffc02024d2:	c26fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc02024d6:	6642                	ld	a2,16(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc02024d8:	00043023          	sd	zero,0(s0)
ffffffffc02024dc:	b5cd                	j	ffffffffc02023be <exit_range+0x11e>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02024de:	00004697          	auipc	a3,0x4
ffffffffc02024e2:	42268693          	addi	a3,a3,1058 # ffffffffc0206900 <etext+0xec8>
ffffffffc02024e6:	00004617          	auipc	a2,0x4
ffffffffc02024ea:	f6a60613          	addi	a2,a2,-150 # ffffffffc0206450 <etext+0xa18>
ffffffffc02024ee:	13700593          	li	a1,311
ffffffffc02024f2:	00004517          	auipc	a0,0x4
ffffffffc02024f6:	3fe50513          	addi	a0,a0,1022 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc02024fa:	f51fd0ef          	jal	ffffffffc020044a <__panic>
    return KADDR(page2pa(page));
ffffffffc02024fe:	00004617          	auipc	a2,0x4
ffffffffc0202502:	30260613          	addi	a2,a2,770 # ffffffffc0206800 <etext+0xdc8>
ffffffffc0202506:	07100593          	li	a1,113
ffffffffc020250a:	00004517          	auipc	a0,0x4
ffffffffc020250e:	31e50513          	addi	a0,a0,798 # ffffffffc0206828 <etext+0xdf0>
ffffffffc0202512:	f39fd0ef          	jal	ffffffffc020044a <__panic>
ffffffffc0202516:	86f2                	mv	a3,t3
ffffffffc0202518:	00004617          	auipc	a2,0x4
ffffffffc020251c:	2e860613          	addi	a2,a2,744 # ffffffffc0206800 <etext+0xdc8>
ffffffffc0202520:	07100593          	li	a1,113
ffffffffc0202524:	00004517          	auipc	a0,0x4
ffffffffc0202528:	30450513          	addi	a0,a0,772 # ffffffffc0206828 <etext+0xdf0>
ffffffffc020252c:	f1ffd0ef          	jal	ffffffffc020044a <__panic>
ffffffffc0202530:	8c7ff0ef          	jal	ffffffffc0201df6 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0202534:	00004697          	auipc	a3,0x4
ffffffffc0202538:	3fc68693          	addi	a3,a3,1020 # ffffffffc0206930 <etext+0xef8>
ffffffffc020253c:	00004617          	auipc	a2,0x4
ffffffffc0202540:	f1460613          	addi	a2,a2,-236 # ffffffffc0206450 <etext+0xa18>
ffffffffc0202544:	13800593          	li	a1,312
ffffffffc0202548:	00004517          	auipc	a0,0x4
ffffffffc020254c:	3a850513          	addi	a0,a0,936 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0202550:	efbfd0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0202554 <page_remove>:
{
ffffffffc0202554:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202556:	4601                	li	a2,0
{
ffffffffc0202558:	e822                	sd	s0,16(sp)
ffffffffc020255a:	ec06                	sd	ra,24(sp)
ffffffffc020255c:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020255e:	95dff0ef          	jal	ffffffffc0201eba <get_pte>
    if (ptep != NULL)
ffffffffc0202562:	c511                	beqz	a0,ffffffffc020256e <page_remove+0x1a>
    if (*ptep & PTE_V)
ffffffffc0202564:	6118                	ld	a4,0(a0)
ffffffffc0202566:	87aa                	mv	a5,a0
ffffffffc0202568:	00177693          	andi	a3,a4,1
ffffffffc020256c:	e689                	bnez	a3,ffffffffc0202576 <page_remove+0x22>
}
ffffffffc020256e:	60e2                	ld	ra,24(sp)
ffffffffc0202570:	6442                	ld	s0,16(sp)
ffffffffc0202572:	6105                	addi	sp,sp,32
ffffffffc0202574:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0202576:	000b3697          	auipc	a3,0xb3
ffffffffc020257a:	52a6b683          	ld	a3,1322(a3) # ffffffffc02b5aa0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc020257e:	070a                	slli	a4,a4,0x2
ffffffffc0202580:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202582:	06d77563          	bgeu	a4,a3,ffffffffc02025ec <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0202586:	000b3517          	auipc	a0,0xb3
ffffffffc020258a:	52253503          	ld	a0,1314(a0) # ffffffffc02b5aa8 <pages>
ffffffffc020258e:	071a                	slli	a4,a4,0x6
ffffffffc0202590:	fe0006b7          	lui	a3,0xfe000
ffffffffc0202594:	9736                	add	a4,a4,a3
ffffffffc0202596:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc0202598:	4118                	lw	a4,0(a0)
ffffffffc020259a:	377d                	addiw	a4,a4,-1
ffffffffc020259c:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc020259e:	cb09                	beqz	a4,ffffffffc02025b0 <page_remove+0x5c>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc02025a0:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02025a4:	12040073          	sfence.vma	s0
}
ffffffffc02025a8:	60e2                	ld	ra,24(sp)
ffffffffc02025aa:	6442                	ld	s0,16(sp)
ffffffffc02025ac:	6105                	addi	sp,sp,32
ffffffffc02025ae:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02025b0:	10002773          	csrr	a4,sstatus
ffffffffc02025b4:	8b09                	andi	a4,a4,2
ffffffffc02025b6:	eb19                	bnez	a4,ffffffffc02025cc <page_remove+0x78>
        pmm_manager->free_pages(base, n);
ffffffffc02025b8:	000b3717          	auipc	a4,0xb3
ffffffffc02025bc:	4c873703          	ld	a4,1224(a4) # ffffffffc02b5a80 <pmm_manager>
ffffffffc02025c0:	4585                	li	a1,1
ffffffffc02025c2:	e03e                	sd	a5,0(sp)
ffffffffc02025c4:	7318                	ld	a4,32(a4)
ffffffffc02025c6:	9702                	jalr	a4
    if (flag)
ffffffffc02025c8:	6782                	ld	a5,0(sp)
ffffffffc02025ca:	bfd9                	j	ffffffffc02025a0 <page_remove+0x4c>
        intr_disable();
ffffffffc02025cc:	e43e                	sd	a5,8(sp)
ffffffffc02025ce:	e02a                	sd	a0,0(sp)
ffffffffc02025d0:	b2efe0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc02025d4:	000b3717          	auipc	a4,0xb3
ffffffffc02025d8:	4ac73703          	ld	a4,1196(a4) # ffffffffc02b5a80 <pmm_manager>
ffffffffc02025dc:	6502                	ld	a0,0(sp)
ffffffffc02025de:	4585                	li	a1,1
ffffffffc02025e0:	7318                	ld	a4,32(a4)
ffffffffc02025e2:	9702                	jalr	a4
        intr_enable();
ffffffffc02025e4:	b14fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc02025e8:	67a2                	ld	a5,8(sp)
ffffffffc02025ea:	bf5d                	j	ffffffffc02025a0 <page_remove+0x4c>
ffffffffc02025ec:	80bff0ef          	jal	ffffffffc0201df6 <pa2page.part.0>

ffffffffc02025f0 <page_insert>:
{
ffffffffc02025f0:	7139                	addi	sp,sp,-64
ffffffffc02025f2:	f426                	sd	s1,40(sp)
ffffffffc02025f4:	84b2                	mv	s1,a2
ffffffffc02025f6:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02025f8:	4605                	li	a2,1
{
ffffffffc02025fa:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02025fc:	85a6                	mv	a1,s1
{
ffffffffc02025fe:	fc06                	sd	ra,56(sp)
ffffffffc0202600:	e436                	sd	a3,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202602:	8b9ff0ef          	jal	ffffffffc0201eba <get_pte>
    if (ptep == NULL)
ffffffffc0202606:	cd61                	beqz	a0,ffffffffc02026de <page_insert+0xee>
    page->ref += 1;
ffffffffc0202608:	400c                	lw	a1,0(s0)
    if (*ptep & PTE_V)
ffffffffc020260a:	611c                	ld	a5,0(a0)
ffffffffc020260c:	66a2                	ld	a3,8(sp)
ffffffffc020260e:	0015861b          	addiw	a2,a1,1 # 1001 <_binary_obj___user_softint_out_size-0x7f67>
ffffffffc0202612:	c010                	sw	a2,0(s0)
ffffffffc0202614:	0017f613          	andi	a2,a5,1
ffffffffc0202618:	872a                	mv	a4,a0
ffffffffc020261a:	e61d                	bnez	a2,ffffffffc0202648 <page_insert+0x58>
    return &pages[PPN(pa) - nbase];
ffffffffc020261c:	000b3617          	auipc	a2,0xb3
ffffffffc0202620:	48c63603          	ld	a2,1164(a2) # ffffffffc02b5aa8 <pages>
    return page - pages + nbase;
ffffffffc0202624:	8c11                	sub	s0,s0,a2
ffffffffc0202626:	8419                	srai	s0,s0,0x6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202628:	200007b7          	lui	a5,0x20000
ffffffffc020262c:	042a                	slli	s0,s0,0xa
ffffffffc020262e:	943e                	add	s0,s0,a5
ffffffffc0202630:	8ec1                	or	a3,a3,s0
ffffffffc0202632:	0016e693          	ori	a3,a3,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0202636:	e314                	sd	a3,0(a4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202638:	12048073          	sfence.vma	s1
    return 0;
ffffffffc020263c:	4501                	li	a0,0
}
ffffffffc020263e:	70e2                	ld	ra,56(sp)
ffffffffc0202640:	7442                	ld	s0,48(sp)
ffffffffc0202642:	74a2                	ld	s1,40(sp)
ffffffffc0202644:	6121                	addi	sp,sp,64
ffffffffc0202646:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0202648:	000b3617          	auipc	a2,0xb3
ffffffffc020264c:	45863603          	ld	a2,1112(a2) # ffffffffc02b5aa0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0202650:	078a                	slli	a5,a5,0x2
ffffffffc0202652:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202654:	08c7f763          	bgeu	a5,a2,ffffffffc02026e2 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0202658:	000b3617          	auipc	a2,0xb3
ffffffffc020265c:	45063603          	ld	a2,1104(a2) # ffffffffc02b5aa8 <pages>
ffffffffc0202660:	fe000537          	lui	a0,0xfe000
ffffffffc0202664:	079a                	slli	a5,a5,0x6
ffffffffc0202666:	97aa                	add	a5,a5,a0
ffffffffc0202668:	00f60533          	add	a0,a2,a5
        if (p == page)
ffffffffc020266c:	00a40963          	beq	s0,a0,ffffffffc020267e <page_insert+0x8e>
    page->ref -= 1;
ffffffffc0202670:	411c                	lw	a5,0(a0)
ffffffffc0202672:	37fd                	addiw	a5,a5,-1 # 1fffffff <_binary_obj___user_matrix_out_size+0x1fff4a7f>
ffffffffc0202674:	c11c                	sw	a5,0(a0)
        if (page_ref(page) ==
ffffffffc0202676:	c791                	beqz	a5,ffffffffc0202682 <page_insert+0x92>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202678:	12048073          	sfence.vma	s1
}
ffffffffc020267c:	b765                	j	ffffffffc0202624 <page_insert+0x34>
ffffffffc020267e:	c00c                	sw	a1,0(s0)
    return page->ref;
ffffffffc0202680:	b755                	j	ffffffffc0202624 <page_insert+0x34>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202682:	100027f3          	csrr	a5,sstatus
ffffffffc0202686:	8b89                	andi	a5,a5,2
ffffffffc0202688:	e39d                	bnez	a5,ffffffffc02026ae <page_insert+0xbe>
        pmm_manager->free_pages(base, n);
ffffffffc020268a:	000b3797          	auipc	a5,0xb3
ffffffffc020268e:	3f67b783          	ld	a5,1014(a5) # ffffffffc02b5a80 <pmm_manager>
ffffffffc0202692:	4585                	li	a1,1
ffffffffc0202694:	e83a                	sd	a4,16(sp)
ffffffffc0202696:	739c                	ld	a5,32(a5)
ffffffffc0202698:	e436                	sd	a3,8(sp)
ffffffffc020269a:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc020269c:	000b3617          	auipc	a2,0xb3
ffffffffc02026a0:	40c63603          	ld	a2,1036(a2) # ffffffffc02b5aa8 <pages>
ffffffffc02026a4:	66a2                	ld	a3,8(sp)
ffffffffc02026a6:	6742                	ld	a4,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026a8:	12048073          	sfence.vma	s1
ffffffffc02026ac:	bfa5                	j	ffffffffc0202624 <page_insert+0x34>
        intr_disable();
ffffffffc02026ae:	ec3a                	sd	a4,24(sp)
ffffffffc02026b0:	e836                	sd	a3,16(sp)
ffffffffc02026b2:	e42a                	sd	a0,8(sp)
ffffffffc02026b4:	a4afe0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02026b8:	000b3797          	auipc	a5,0xb3
ffffffffc02026bc:	3c87b783          	ld	a5,968(a5) # ffffffffc02b5a80 <pmm_manager>
ffffffffc02026c0:	6522                	ld	a0,8(sp)
ffffffffc02026c2:	4585                	li	a1,1
ffffffffc02026c4:	739c                	ld	a5,32(a5)
ffffffffc02026c6:	9782                	jalr	a5
        intr_enable();
ffffffffc02026c8:	a30fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc02026cc:	000b3617          	auipc	a2,0xb3
ffffffffc02026d0:	3dc63603          	ld	a2,988(a2) # ffffffffc02b5aa8 <pages>
ffffffffc02026d4:	6762                	ld	a4,24(sp)
ffffffffc02026d6:	66c2                	ld	a3,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026d8:	12048073          	sfence.vma	s1
ffffffffc02026dc:	b7a1                	j	ffffffffc0202624 <page_insert+0x34>
        return -E_NO_MEM;
ffffffffc02026de:	5571                	li	a0,-4
ffffffffc02026e0:	bfb9                	j	ffffffffc020263e <page_insert+0x4e>
ffffffffc02026e2:	f14ff0ef          	jal	ffffffffc0201df6 <pa2page.part.0>

ffffffffc02026e6 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02026e6:	00005797          	auipc	a5,0x5
ffffffffc02026ea:	26278793          	addi	a5,a5,610 # ffffffffc0207948 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02026ee:	638c                	ld	a1,0(a5)
{
ffffffffc02026f0:	7159                	addi	sp,sp,-112
ffffffffc02026f2:	f486                	sd	ra,104(sp)
ffffffffc02026f4:	e8ca                	sd	s2,80(sp)
ffffffffc02026f6:	e4ce                	sd	s3,72(sp)
ffffffffc02026f8:	f85a                	sd	s6,48(sp)
ffffffffc02026fa:	f0a2                	sd	s0,96(sp)
ffffffffc02026fc:	eca6                	sd	s1,88(sp)
ffffffffc02026fe:	e0d2                	sd	s4,64(sp)
ffffffffc0202700:	fc56                	sd	s5,56(sp)
ffffffffc0202702:	f45e                	sd	s7,40(sp)
ffffffffc0202704:	f062                	sd	s8,32(sp)
ffffffffc0202706:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202708:	000b3b17          	auipc	s6,0xb3
ffffffffc020270c:	378b0b13          	addi	s6,s6,888 # ffffffffc02b5a80 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202710:	00004517          	auipc	a0,0x4
ffffffffc0202714:	23850513          	addi	a0,a0,568 # ffffffffc0206948 <etext+0xf10>
    pmm_manager = &default_pmm_manager;
ffffffffc0202718:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020271c:	a7dfd0ef          	jal	ffffffffc0200198 <cprintf>
    pmm_manager->init();
ffffffffc0202720:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202724:	000b3997          	auipc	s3,0xb3
ffffffffc0202728:	37498993          	addi	s3,s3,884 # ffffffffc02b5a98 <va_pa_offset>
    pmm_manager->init();
ffffffffc020272c:	679c                	ld	a5,8(a5)
ffffffffc020272e:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202730:	57f5                	li	a5,-3
ffffffffc0202732:	07fa                	slli	a5,a5,0x1e
ffffffffc0202734:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc0202738:	9acfe0ef          	jal	ffffffffc02008e4 <get_memory_base>
ffffffffc020273c:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc020273e:	9b0fe0ef          	jal	ffffffffc02008ee <get_memory_size>
    if (mem_size == 0)
ffffffffc0202742:	70050e63          	beqz	a0,ffffffffc0202e5e <pmm_init+0x778>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202746:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc0202748:	00004517          	auipc	a0,0x4
ffffffffc020274c:	23850513          	addi	a0,a0,568 # ffffffffc0206980 <etext+0xf48>
ffffffffc0202750:	a49fd0ef          	jal	ffffffffc0200198 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202754:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0202758:	864a                	mv	a2,s2
ffffffffc020275a:	85a6                	mv	a1,s1
ffffffffc020275c:	fff40693          	addi	a3,s0,-1
ffffffffc0202760:	00004517          	auipc	a0,0x4
ffffffffc0202764:	23850513          	addi	a0,a0,568 # ffffffffc0206998 <etext+0xf60>
ffffffffc0202768:	a31fd0ef          	jal	ffffffffc0200198 <cprintf>
    if (maxpa > KERNTOP)
ffffffffc020276c:	c80007b7          	lui	a5,0xc8000
ffffffffc0202770:	8522                	mv	a0,s0
ffffffffc0202772:	5287ed63          	bltu	a5,s0,ffffffffc0202cac <pmm_init+0x5c6>
ffffffffc0202776:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202778:	000b4617          	auipc	a2,0xb4
ffffffffc020277c:	36760613          	addi	a2,a2,871 # ffffffffc02b6adf <end+0xfff>
ffffffffc0202780:	8e7d                	and	a2,a2,a5
    npage = maxpa / PGSIZE;
ffffffffc0202782:	8131                	srli	a0,a0,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202784:	000b3b97          	auipc	s7,0xb3
ffffffffc0202788:	324b8b93          	addi	s7,s7,804 # ffffffffc02b5aa8 <pages>
    npage = maxpa / PGSIZE;
ffffffffc020278c:	000b3497          	auipc	s1,0xb3
ffffffffc0202790:	31448493          	addi	s1,s1,788 # ffffffffc02b5aa0 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202794:	00cbb023          	sd	a2,0(s7)
    npage = maxpa / PGSIZE;
ffffffffc0202798:	e088                	sd	a0,0(s1)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020279a:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020279e:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02027a0:	02f50763          	beq	a0,a5,ffffffffc02027ce <pmm_init+0xe8>
ffffffffc02027a4:	4701                	li	a4,0
ffffffffc02027a6:	4585                	li	a1,1
ffffffffc02027a8:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc02027ac:	00671793          	slli	a5,a4,0x6
ffffffffc02027b0:	97b2                	add	a5,a5,a2
ffffffffc02027b2:	07a1                	addi	a5,a5,8 # 80008 <_binary_obj___user_matrix_out_size+0x74a88>
ffffffffc02027b4:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02027b8:	6088                	ld	a0,0(s1)
ffffffffc02027ba:	0705                	addi	a4,a4,1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02027bc:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02027c0:	00d507b3          	add	a5,a0,a3
ffffffffc02027c4:	fef764e3          	bltu	a4,a5,ffffffffc02027ac <pmm_init+0xc6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02027c8:	079a                	slli	a5,a5,0x6
ffffffffc02027ca:	00f606b3          	add	a3,a2,a5
ffffffffc02027ce:	c02007b7          	lui	a5,0xc0200
ffffffffc02027d2:	16f6eee3          	bltu	a3,a5,ffffffffc020314e <pmm_init+0xa68>
ffffffffc02027d6:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02027da:	77fd                	lui	a5,0xfffff
ffffffffc02027dc:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02027de:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc02027e0:	4e86ed63          	bltu	a3,s0,ffffffffc0202cda <pmm_init+0x5f4>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc02027e4:	00004517          	auipc	a0,0x4
ffffffffc02027e8:	1dc50513          	addi	a0,a0,476 # ffffffffc02069c0 <etext+0xf88>
ffffffffc02027ec:	9adfd0ef          	jal	ffffffffc0200198 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc02027f0:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02027f4:	000b3917          	auipc	s2,0xb3
ffffffffc02027f8:	29c90913          	addi	s2,s2,668 # ffffffffc02b5a90 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc02027fc:	7b9c                	ld	a5,48(a5)
ffffffffc02027fe:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202800:	00004517          	auipc	a0,0x4
ffffffffc0202804:	1d850513          	addi	a0,a0,472 # ffffffffc02069d8 <etext+0xfa0>
ffffffffc0202808:	991fd0ef          	jal	ffffffffc0200198 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020280c:	00008697          	auipc	a3,0x8
ffffffffc0202810:	7f468693          	addi	a3,a3,2036 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc0202814:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202818:	c02007b7          	lui	a5,0xc0200
ffffffffc020281c:	2af6eee3          	bltu	a3,a5,ffffffffc02032d8 <pmm_init+0xbf2>
ffffffffc0202820:	0009b783          	ld	a5,0(s3)
ffffffffc0202824:	8e9d                	sub	a3,a3,a5
ffffffffc0202826:	000b3797          	auipc	a5,0xb3
ffffffffc020282a:	26d7b123          	sd	a3,610(a5) # ffffffffc02b5a88 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020282e:	100027f3          	csrr	a5,sstatus
ffffffffc0202832:	8b89                	andi	a5,a5,2
ffffffffc0202834:	48079963          	bnez	a5,ffffffffc0202cc6 <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202838:	000b3783          	ld	a5,0(s6)
ffffffffc020283c:	779c                	ld	a5,40(a5)
ffffffffc020283e:	9782                	jalr	a5
ffffffffc0202840:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202842:	6098                	ld	a4,0(s1)
ffffffffc0202844:	c80007b7          	lui	a5,0xc8000
ffffffffc0202848:	83b1                	srli	a5,a5,0xc
ffffffffc020284a:	66e7e663          	bltu	a5,a4,ffffffffc0202eb6 <pmm_init+0x7d0>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc020284e:	00093503          	ld	a0,0(s2)
ffffffffc0202852:	64050263          	beqz	a0,ffffffffc0202e96 <pmm_init+0x7b0>
ffffffffc0202856:	03451793          	slli	a5,a0,0x34
ffffffffc020285a:	62079e63          	bnez	a5,ffffffffc0202e96 <pmm_init+0x7b0>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc020285e:	4601                	li	a2,0
ffffffffc0202860:	4581                	li	a1,0
ffffffffc0202862:	8b7ff0ef          	jal	ffffffffc0202118 <get_page>
ffffffffc0202866:	240519e3          	bnez	a0,ffffffffc02032b8 <pmm_init+0xbd2>
ffffffffc020286a:	100027f3          	csrr	a5,sstatus
ffffffffc020286e:	8b89                	andi	a5,a5,2
ffffffffc0202870:	44079063          	bnez	a5,ffffffffc0202cb0 <pmm_init+0x5ca>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202874:	000b3783          	ld	a5,0(s6)
ffffffffc0202878:	4505                	li	a0,1
ffffffffc020287a:	6f9c                	ld	a5,24(a5)
ffffffffc020287c:	9782                	jalr	a5
ffffffffc020287e:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202880:	00093503          	ld	a0,0(s2)
ffffffffc0202884:	4681                	li	a3,0
ffffffffc0202886:	4601                	li	a2,0
ffffffffc0202888:	85d2                	mv	a1,s4
ffffffffc020288a:	d67ff0ef          	jal	ffffffffc02025f0 <page_insert>
ffffffffc020288e:	280511e3          	bnez	a0,ffffffffc0203310 <pmm_init+0xc2a>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202892:	00093503          	ld	a0,0(s2)
ffffffffc0202896:	4601                	li	a2,0
ffffffffc0202898:	4581                	li	a1,0
ffffffffc020289a:	e20ff0ef          	jal	ffffffffc0201eba <get_pte>
ffffffffc020289e:	240509e3          	beqz	a0,ffffffffc02032f0 <pmm_init+0xc0a>
    assert(pte2page(*ptep) == p1);
ffffffffc02028a2:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc02028a4:	0017f713          	andi	a4,a5,1
ffffffffc02028a8:	58070f63          	beqz	a4,ffffffffc0202e46 <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc02028ac:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02028ae:	078a                	slli	a5,a5,0x2
ffffffffc02028b0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02028b2:	58e7f863          	bgeu	a5,a4,ffffffffc0202e42 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc02028b6:	000bb683          	ld	a3,0(s7)
ffffffffc02028ba:	079a                	slli	a5,a5,0x6
ffffffffc02028bc:	fe000637          	lui	a2,0xfe000
ffffffffc02028c0:	97b2                	add	a5,a5,a2
ffffffffc02028c2:	97b6                	add	a5,a5,a3
ffffffffc02028c4:	14fa1ae3          	bne	s4,a5,ffffffffc0203218 <pmm_init+0xb32>
    assert(page_ref(p1) == 1);
ffffffffc02028c8:	000a2683          	lw	a3,0(s4) # 200000 <_binary_obj___user_matrix_out_size+0x1f4a80>
ffffffffc02028cc:	4785                	li	a5,1
ffffffffc02028ce:	12f695e3          	bne	a3,a5,ffffffffc02031f8 <pmm_init+0xb12>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02028d2:	00093503          	ld	a0,0(s2)
ffffffffc02028d6:	77fd                	lui	a5,0xfffff
ffffffffc02028d8:	6114                	ld	a3,0(a0)
ffffffffc02028da:	068a                	slli	a3,a3,0x2
ffffffffc02028dc:	8efd                	and	a3,a3,a5
ffffffffc02028de:	00c6d613          	srli	a2,a3,0xc
ffffffffc02028e2:	0ee67fe3          	bgeu	a2,a4,ffffffffc02031e0 <pmm_init+0xafa>
ffffffffc02028e6:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02028ea:	96e2                	add	a3,a3,s8
ffffffffc02028ec:	0006ba83          	ld	s5,0(a3)
ffffffffc02028f0:	0a8a                	slli	s5,s5,0x2
ffffffffc02028f2:	00fafab3          	and	s5,s5,a5
ffffffffc02028f6:	00cad793          	srli	a5,s5,0xc
ffffffffc02028fa:	0ce7f6e3          	bgeu	a5,a4,ffffffffc02031c6 <pmm_init+0xae0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02028fe:	4601                	li	a2,0
ffffffffc0202900:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202902:	9c56                	add	s8,s8,s5
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202904:	db6ff0ef          	jal	ffffffffc0201eba <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202908:	0c21                	addi	s8,s8,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020290a:	05851ee3          	bne	a0,s8,ffffffffc0203166 <pmm_init+0xa80>
ffffffffc020290e:	100027f3          	csrr	a5,sstatus
ffffffffc0202912:	8b89                	andi	a5,a5,2
ffffffffc0202914:	3e079b63          	bnez	a5,ffffffffc0202d0a <pmm_init+0x624>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202918:	000b3783          	ld	a5,0(s6)
ffffffffc020291c:	4505                	li	a0,1
ffffffffc020291e:	6f9c                	ld	a5,24(a5)
ffffffffc0202920:	9782                	jalr	a5
ffffffffc0202922:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202924:	00093503          	ld	a0,0(s2)
ffffffffc0202928:	46d1                	li	a3,20
ffffffffc020292a:	6605                	lui	a2,0x1
ffffffffc020292c:	85e2                	mv	a1,s8
ffffffffc020292e:	cc3ff0ef          	jal	ffffffffc02025f0 <page_insert>
ffffffffc0202932:	06051ae3          	bnez	a0,ffffffffc02031a6 <pmm_init+0xac0>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202936:	00093503          	ld	a0,0(s2)
ffffffffc020293a:	4601                	li	a2,0
ffffffffc020293c:	6585                	lui	a1,0x1
ffffffffc020293e:	d7cff0ef          	jal	ffffffffc0201eba <get_pte>
ffffffffc0202942:	040502e3          	beqz	a0,ffffffffc0203186 <pmm_init+0xaa0>
    assert(*ptep & PTE_U);
ffffffffc0202946:	611c                	ld	a5,0(a0)
ffffffffc0202948:	0107f713          	andi	a4,a5,16
ffffffffc020294c:	7e070163          	beqz	a4,ffffffffc020312e <pmm_init+0xa48>
    assert(*ptep & PTE_W);
ffffffffc0202950:	8b91                	andi	a5,a5,4
ffffffffc0202952:	7a078e63          	beqz	a5,ffffffffc020310e <pmm_init+0xa28>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202956:	00093503          	ld	a0,0(s2)
ffffffffc020295a:	611c                	ld	a5,0(a0)
ffffffffc020295c:	8bc1                	andi	a5,a5,16
ffffffffc020295e:	78078863          	beqz	a5,ffffffffc02030ee <pmm_init+0xa08>
    assert(page_ref(p2) == 1);
ffffffffc0202962:	000c2703          	lw	a4,0(s8)
ffffffffc0202966:	4785                	li	a5,1
ffffffffc0202968:	76f71363          	bne	a4,a5,ffffffffc02030ce <pmm_init+0x9e8>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc020296c:	4681                	li	a3,0
ffffffffc020296e:	6605                	lui	a2,0x1
ffffffffc0202970:	85d2                	mv	a1,s4
ffffffffc0202972:	c7fff0ef          	jal	ffffffffc02025f0 <page_insert>
ffffffffc0202976:	72051c63          	bnez	a0,ffffffffc02030ae <pmm_init+0x9c8>
    assert(page_ref(p1) == 2);
ffffffffc020297a:	000a2703          	lw	a4,0(s4)
ffffffffc020297e:	4789                	li	a5,2
ffffffffc0202980:	70f71763          	bne	a4,a5,ffffffffc020308e <pmm_init+0x9a8>
    assert(page_ref(p2) == 0);
ffffffffc0202984:	000c2783          	lw	a5,0(s8)
ffffffffc0202988:	6e079363          	bnez	a5,ffffffffc020306e <pmm_init+0x988>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020298c:	00093503          	ld	a0,0(s2)
ffffffffc0202990:	4601                	li	a2,0
ffffffffc0202992:	6585                	lui	a1,0x1
ffffffffc0202994:	d26ff0ef          	jal	ffffffffc0201eba <get_pte>
ffffffffc0202998:	6a050b63          	beqz	a0,ffffffffc020304e <pmm_init+0x968>
    assert(pte2page(*ptep) == p1);
ffffffffc020299c:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc020299e:	00177793          	andi	a5,a4,1
ffffffffc02029a2:	4a078263          	beqz	a5,ffffffffc0202e46 <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc02029a6:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02029a8:	00271793          	slli	a5,a4,0x2
ffffffffc02029ac:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02029ae:	48d7fa63          	bgeu	a5,a3,ffffffffc0202e42 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc02029b2:	000bb683          	ld	a3,0(s7)
ffffffffc02029b6:	fff80ab7          	lui	s5,0xfff80
ffffffffc02029ba:	97d6                	add	a5,a5,s5
ffffffffc02029bc:	079a                	slli	a5,a5,0x6
ffffffffc02029be:	97b6                	add	a5,a5,a3
ffffffffc02029c0:	66fa1763          	bne	s4,a5,ffffffffc020302e <pmm_init+0x948>
    assert((*ptep & PTE_U) == 0);
ffffffffc02029c4:	8b41                	andi	a4,a4,16
ffffffffc02029c6:	64071463          	bnez	a4,ffffffffc020300e <pmm_init+0x928>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc02029ca:	00093503          	ld	a0,0(s2)
ffffffffc02029ce:	4581                	li	a1,0
ffffffffc02029d0:	b85ff0ef          	jal	ffffffffc0202554 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc02029d4:	000a2c83          	lw	s9,0(s4)
ffffffffc02029d8:	4785                	li	a5,1
ffffffffc02029da:	60fc9a63          	bne	s9,a5,ffffffffc0202fee <pmm_init+0x908>
    assert(page_ref(p2) == 0);
ffffffffc02029de:	000c2783          	lw	a5,0(s8)
ffffffffc02029e2:	5e079663          	bnez	a5,ffffffffc0202fce <pmm_init+0x8e8>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc02029e6:	00093503          	ld	a0,0(s2)
ffffffffc02029ea:	6585                	lui	a1,0x1
ffffffffc02029ec:	b69ff0ef          	jal	ffffffffc0202554 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc02029f0:	000a2783          	lw	a5,0(s4)
ffffffffc02029f4:	52079d63          	bnez	a5,ffffffffc0202f2e <pmm_init+0x848>
    assert(page_ref(p2) == 0);
ffffffffc02029f8:	000c2783          	lw	a5,0(s8)
ffffffffc02029fc:	50079963          	bnez	a5,ffffffffc0202f0e <pmm_init+0x828>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202a00:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202a04:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a06:	000a3783          	ld	a5,0(s4)
ffffffffc0202a0a:	078a                	slli	a5,a5,0x2
ffffffffc0202a0c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a0e:	42e7fa63          	bgeu	a5,a4,ffffffffc0202e42 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a12:	000bb503          	ld	a0,0(s7)
ffffffffc0202a16:	97d6                	add	a5,a5,s5
ffffffffc0202a18:	079a                	slli	a5,a5,0x6
    return page->ref;
ffffffffc0202a1a:	00f506b3          	add	a3,a0,a5
ffffffffc0202a1e:	4294                	lw	a3,0(a3)
ffffffffc0202a20:	4d969763          	bne	a3,s9,ffffffffc0202eee <pmm_init+0x808>
    return page - pages + nbase;
ffffffffc0202a24:	8799                	srai	a5,a5,0x6
ffffffffc0202a26:	00080637          	lui	a2,0x80
ffffffffc0202a2a:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202a2c:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202a30:	4ae7f363          	bgeu	a5,a4,ffffffffc0202ed6 <pmm_init+0x7f0>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202a34:	0009b783          	ld	a5,0(s3)
ffffffffc0202a38:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a3a:	639c                	ld	a5,0(a5)
ffffffffc0202a3c:	078a                	slli	a5,a5,0x2
ffffffffc0202a3e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a40:	40e7f163          	bgeu	a5,a4,ffffffffc0202e42 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a44:	8f91                	sub	a5,a5,a2
ffffffffc0202a46:	079a                	slli	a5,a5,0x6
ffffffffc0202a48:	953e                	add	a0,a0,a5
ffffffffc0202a4a:	100027f3          	csrr	a5,sstatus
ffffffffc0202a4e:	8b89                	andi	a5,a5,2
ffffffffc0202a50:	30079863          	bnez	a5,ffffffffc0202d60 <pmm_init+0x67a>
        pmm_manager->free_pages(base, n);
ffffffffc0202a54:	000b3783          	ld	a5,0(s6)
ffffffffc0202a58:	4585                	li	a1,1
ffffffffc0202a5a:	739c                	ld	a5,32(a5)
ffffffffc0202a5c:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a5e:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202a62:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a64:	078a                	slli	a5,a5,0x2
ffffffffc0202a66:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a68:	3ce7fd63          	bgeu	a5,a4,ffffffffc0202e42 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a6c:	000bb503          	ld	a0,0(s7)
ffffffffc0202a70:	fe000737          	lui	a4,0xfe000
ffffffffc0202a74:	079a                	slli	a5,a5,0x6
ffffffffc0202a76:	97ba                	add	a5,a5,a4
ffffffffc0202a78:	953e                	add	a0,a0,a5
ffffffffc0202a7a:	100027f3          	csrr	a5,sstatus
ffffffffc0202a7e:	8b89                	andi	a5,a5,2
ffffffffc0202a80:	2c079463          	bnez	a5,ffffffffc0202d48 <pmm_init+0x662>
ffffffffc0202a84:	000b3783          	ld	a5,0(s6)
ffffffffc0202a88:	4585                	li	a1,1
ffffffffc0202a8a:	739c                	ld	a5,32(a5)
ffffffffc0202a8c:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202a8e:	00093783          	ld	a5,0(s2)
ffffffffc0202a92:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd49520>
    asm volatile("sfence.vma");
ffffffffc0202a96:	12000073          	sfence.vma
ffffffffc0202a9a:	100027f3          	csrr	a5,sstatus
ffffffffc0202a9e:	8b89                	andi	a5,a5,2
ffffffffc0202aa0:	28079a63          	bnez	a5,ffffffffc0202d34 <pmm_init+0x64e>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202aa4:	000b3783          	ld	a5,0(s6)
ffffffffc0202aa8:	779c                	ld	a5,40(a5)
ffffffffc0202aaa:	9782                	jalr	a5
ffffffffc0202aac:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202aae:	4d441063          	bne	s0,s4,ffffffffc0202f6e <pmm_init+0x888>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202ab2:	00004517          	auipc	a0,0x4
ffffffffc0202ab6:	27650513          	addi	a0,a0,630 # ffffffffc0206d28 <etext+0x12f0>
ffffffffc0202aba:	edefd0ef          	jal	ffffffffc0200198 <cprintf>
ffffffffc0202abe:	100027f3          	csrr	a5,sstatus
ffffffffc0202ac2:	8b89                	andi	a5,a5,2
ffffffffc0202ac4:	24079e63          	bnez	a5,ffffffffc0202d20 <pmm_init+0x63a>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202ac8:	000b3783          	ld	a5,0(s6)
ffffffffc0202acc:	779c                	ld	a5,40(a5)
ffffffffc0202ace:	9782                	jalr	a5
ffffffffc0202ad0:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202ad2:	609c                	ld	a5,0(s1)
ffffffffc0202ad4:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202ad8:	7a7d                	lui	s4,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202ada:	00c79713          	slli	a4,a5,0xc
ffffffffc0202ade:	6a85                	lui	s5,0x1
ffffffffc0202ae0:	02e47c63          	bgeu	s0,a4,ffffffffc0202b18 <pmm_init+0x432>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202ae4:	00c45713          	srli	a4,s0,0xc
ffffffffc0202ae8:	30f77063          	bgeu	a4,a5,ffffffffc0202de8 <pmm_init+0x702>
ffffffffc0202aec:	0009b583          	ld	a1,0(s3)
ffffffffc0202af0:	00093503          	ld	a0,0(s2)
ffffffffc0202af4:	4601                	li	a2,0
ffffffffc0202af6:	95a2                	add	a1,a1,s0
ffffffffc0202af8:	bc2ff0ef          	jal	ffffffffc0201eba <get_pte>
ffffffffc0202afc:	32050363          	beqz	a0,ffffffffc0202e22 <pmm_init+0x73c>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b00:	611c                	ld	a5,0(a0)
ffffffffc0202b02:	078a                	slli	a5,a5,0x2
ffffffffc0202b04:	0147f7b3          	and	a5,a5,s4
ffffffffc0202b08:	2e879d63          	bne	a5,s0,ffffffffc0202e02 <pmm_init+0x71c>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b0c:	609c                	ld	a5,0(s1)
ffffffffc0202b0e:	9456                	add	s0,s0,s5
ffffffffc0202b10:	00c79713          	slli	a4,a5,0xc
ffffffffc0202b14:	fce468e3          	bltu	s0,a4,ffffffffc0202ae4 <pmm_init+0x3fe>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202b18:	00093783          	ld	a5,0(s2)
ffffffffc0202b1c:	639c                	ld	a5,0(a5)
ffffffffc0202b1e:	42079863          	bnez	a5,ffffffffc0202f4e <pmm_init+0x868>
ffffffffc0202b22:	100027f3          	csrr	a5,sstatus
ffffffffc0202b26:	8b89                	andi	a5,a5,2
ffffffffc0202b28:	24079863          	bnez	a5,ffffffffc0202d78 <pmm_init+0x692>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202b2c:	000b3783          	ld	a5,0(s6)
ffffffffc0202b30:	4505                	li	a0,1
ffffffffc0202b32:	6f9c                	ld	a5,24(a5)
ffffffffc0202b34:	9782                	jalr	a5
ffffffffc0202b36:	842a                	mv	s0,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202b38:	00093503          	ld	a0,0(s2)
ffffffffc0202b3c:	4699                	li	a3,6
ffffffffc0202b3e:	10000613          	li	a2,256
ffffffffc0202b42:	85a2                	mv	a1,s0
ffffffffc0202b44:	aadff0ef          	jal	ffffffffc02025f0 <page_insert>
ffffffffc0202b48:	46051363          	bnez	a0,ffffffffc0202fae <pmm_init+0x8c8>
    assert(page_ref(p) == 1);
ffffffffc0202b4c:	4018                	lw	a4,0(s0)
ffffffffc0202b4e:	4785                	li	a5,1
ffffffffc0202b50:	42f71f63          	bne	a4,a5,ffffffffc0202f8e <pmm_init+0x8a8>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202b54:	00093503          	ld	a0,0(s2)
ffffffffc0202b58:	6605                	lui	a2,0x1
ffffffffc0202b5a:	10060613          	addi	a2,a2,256 # 1100 <_binary_obj___user_softint_out_size-0x7e68>
ffffffffc0202b5e:	4699                	li	a3,6
ffffffffc0202b60:	85a2                	mv	a1,s0
ffffffffc0202b62:	a8fff0ef          	jal	ffffffffc02025f0 <page_insert>
ffffffffc0202b66:	72051963          	bnez	a0,ffffffffc0203298 <pmm_init+0xbb2>
    assert(page_ref(p) == 2);
ffffffffc0202b6a:	4018                	lw	a4,0(s0)
ffffffffc0202b6c:	4789                	li	a5,2
ffffffffc0202b6e:	70f71563          	bne	a4,a5,ffffffffc0203278 <pmm_init+0xb92>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202b72:	00004597          	auipc	a1,0x4
ffffffffc0202b76:	2fe58593          	addi	a1,a1,766 # ffffffffc0206e70 <etext+0x1438>
ffffffffc0202b7a:	10000513          	li	a0,256
ffffffffc0202b7e:	611020ef          	jal	ffffffffc020598e <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202b82:	6585                	lui	a1,0x1
ffffffffc0202b84:	10058593          	addi	a1,a1,256 # 1100 <_binary_obj___user_softint_out_size-0x7e68>
ffffffffc0202b88:	10000513          	li	a0,256
ffffffffc0202b8c:	615020ef          	jal	ffffffffc02059a0 <strcmp>
ffffffffc0202b90:	6c051463          	bnez	a0,ffffffffc0203258 <pmm_init+0xb72>
    return page - pages + nbase;
ffffffffc0202b94:	000bb683          	ld	a3,0(s7)
ffffffffc0202b98:	000807b7          	lui	a5,0x80
    return KADDR(page2pa(page));
ffffffffc0202b9c:	6098                	ld	a4,0(s1)
    return page - pages + nbase;
ffffffffc0202b9e:	40d406b3          	sub	a3,s0,a3
ffffffffc0202ba2:	8699                	srai	a3,a3,0x6
ffffffffc0202ba4:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0202ba6:	00c69793          	slli	a5,a3,0xc
ffffffffc0202baa:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202bac:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202bae:	32e7f463          	bgeu	a5,a4,ffffffffc0202ed6 <pmm_init+0x7f0>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202bb2:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202bb6:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202bba:	97b6                	add	a5,a5,a3
ffffffffc0202bbc:	10078023          	sb	zero,256(a5) # 80100 <_binary_obj___user_matrix_out_size+0x74b80>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202bc0:	59b020ef          	jal	ffffffffc020595a <strlen>
ffffffffc0202bc4:	66051a63          	bnez	a0,ffffffffc0203238 <pmm_init+0xb52>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202bc8:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202bcc:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202bce:	000a3783          	ld	a5,0(s4) # fffffffffffff000 <end+0x3fd49520>
ffffffffc0202bd2:	078a                	slli	a5,a5,0x2
ffffffffc0202bd4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202bd6:	26e7f663          	bgeu	a5,a4,ffffffffc0202e42 <pmm_init+0x75c>
    return page2ppn(page) << PGSHIFT;
ffffffffc0202bda:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202bde:	2ee7fc63          	bgeu	a5,a4,ffffffffc0202ed6 <pmm_init+0x7f0>
ffffffffc0202be2:	0009b783          	ld	a5,0(s3)
ffffffffc0202be6:	00f689b3          	add	s3,a3,a5
ffffffffc0202bea:	100027f3          	csrr	a5,sstatus
ffffffffc0202bee:	8b89                	andi	a5,a5,2
ffffffffc0202bf0:	1e079163          	bnez	a5,ffffffffc0202dd2 <pmm_init+0x6ec>
        pmm_manager->free_pages(base, n);
ffffffffc0202bf4:	000b3783          	ld	a5,0(s6)
ffffffffc0202bf8:	8522                	mv	a0,s0
ffffffffc0202bfa:	4585                	li	a1,1
ffffffffc0202bfc:	739c                	ld	a5,32(a5)
ffffffffc0202bfe:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c00:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage)
ffffffffc0202c04:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c06:	078a                	slli	a5,a5,0x2
ffffffffc0202c08:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c0a:	22e7fc63          	bgeu	a5,a4,ffffffffc0202e42 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c0e:	000bb503          	ld	a0,0(s7)
ffffffffc0202c12:	fe000737          	lui	a4,0xfe000
ffffffffc0202c16:	079a                	slli	a5,a5,0x6
ffffffffc0202c18:	97ba                	add	a5,a5,a4
ffffffffc0202c1a:	953e                	add	a0,a0,a5
ffffffffc0202c1c:	100027f3          	csrr	a5,sstatus
ffffffffc0202c20:	8b89                	andi	a5,a5,2
ffffffffc0202c22:	18079c63          	bnez	a5,ffffffffc0202dba <pmm_init+0x6d4>
ffffffffc0202c26:	000b3783          	ld	a5,0(s6)
ffffffffc0202c2a:	4585                	li	a1,1
ffffffffc0202c2c:	739c                	ld	a5,32(a5)
ffffffffc0202c2e:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c30:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202c34:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c36:	078a                	slli	a5,a5,0x2
ffffffffc0202c38:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c3a:	20e7f463          	bgeu	a5,a4,ffffffffc0202e42 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c3e:	000bb503          	ld	a0,0(s7)
ffffffffc0202c42:	fe000737          	lui	a4,0xfe000
ffffffffc0202c46:	079a                	slli	a5,a5,0x6
ffffffffc0202c48:	97ba                	add	a5,a5,a4
ffffffffc0202c4a:	953e                	add	a0,a0,a5
ffffffffc0202c4c:	100027f3          	csrr	a5,sstatus
ffffffffc0202c50:	8b89                	andi	a5,a5,2
ffffffffc0202c52:	14079863          	bnez	a5,ffffffffc0202da2 <pmm_init+0x6bc>
ffffffffc0202c56:	000b3783          	ld	a5,0(s6)
ffffffffc0202c5a:	4585                	li	a1,1
ffffffffc0202c5c:	739c                	ld	a5,32(a5)
ffffffffc0202c5e:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202c60:	00093783          	ld	a5,0(s2)
ffffffffc0202c64:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202c68:	12000073          	sfence.vma
ffffffffc0202c6c:	100027f3          	csrr	a5,sstatus
ffffffffc0202c70:	8b89                	andi	a5,a5,2
ffffffffc0202c72:	10079e63          	bnez	a5,ffffffffc0202d8e <pmm_init+0x6a8>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202c76:	000b3783          	ld	a5,0(s6)
ffffffffc0202c7a:	779c                	ld	a5,40(a5)
ffffffffc0202c7c:	9782                	jalr	a5
ffffffffc0202c7e:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202c80:	1e8c1b63          	bne	s8,s0,ffffffffc0202e76 <pmm_init+0x790>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202c84:	00004517          	auipc	a0,0x4
ffffffffc0202c88:	26450513          	addi	a0,a0,612 # ffffffffc0206ee8 <etext+0x14b0>
ffffffffc0202c8c:	d0cfd0ef          	jal	ffffffffc0200198 <cprintf>
}
ffffffffc0202c90:	7406                	ld	s0,96(sp)
ffffffffc0202c92:	70a6                	ld	ra,104(sp)
ffffffffc0202c94:	64e6                	ld	s1,88(sp)
ffffffffc0202c96:	6946                	ld	s2,80(sp)
ffffffffc0202c98:	69a6                	ld	s3,72(sp)
ffffffffc0202c9a:	6a06                	ld	s4,64(sp)
ffffffffc0202c9c:	7ae2                	ld	s5,56(sp)
ffffffffc0202c9e:	7b42                	ld	s6,48(sp)
ffffffffc0202ca0:	7ba2                	ld	s7,40(sp)
ffffffffc0202ca2:	7c02                	ld	s8,32(sp)
ffffffffc0202ca4:	6ce2                	ld	s9,24(sp)
ffffffffc0202ca6:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202ca8:	f85fe06f          	j	ffffffffc0201c2c <kmalloc_init>
    if (maxpa > KERNTOP)
ffffffffc0202cac:	853e                	mv	a0,a5
ffffffffc0202cae:	b4e1                	j	ffffffffc0202776 <pmm_init+0x90>
        intr_disable();
ffffffffc0202cb0:	c4ffd0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202cb4:	000b3783          	ld	a5,0(s6)
ffffffffc0202cb8:	4505                	li	a0,1
ffffffffc0202cba:	6f9c                	ld	a5,24(a5)
ffffffffc0202cbc:	9782                	jalr	a5
ffffffffc0202cbe:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202cc0:	c39fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202cc4:	be75                	j	ffffffffc0202880 <pmm_init+0x19a>
        intr_disable();
ffffffffc0202cc6:	c39fd0ef          	jal	ffffffffc02008fe <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202cca:	000b3783          	ld	a5,0(s6)
ffffffffc0202cce:	779c                	ld	a5,40(a5)
ffffffffc0202cd0:	9782                	jalr	a5
ffffffffc0202cd2:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202cd4:	c25fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202cd8:	b6ad                	j	ffffffffc0202842 <pmm_init+0x15c>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202cda:	6705                	lui	a4,0x1
ffffffffc0202cdc:	177d                	addi	a4,a4,-1 # fff <_binary_obj___user_softint_out_size-0x7f69>
ffffffffc0202cde:	96ba                	add	a3,a3,a4
ffffffffc0202ce0:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202ce2:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202ce6:	14a77e63          	bgeu	a4,a0,ffffffffc0202e42 <pmm_init+0x75c>
    pmm_manager->init_memmap(base, n);
ffffffffc0202cea:	000b3683          	ld	a3,0(s6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202cee:	8c1d                	sub	s0,s0,a5
    return &pages[PPN(pa) - nbase];
ffffffffc0202cf0:	071a                	slli	a4,a4,0x6
ffffffffc0202cf2:	fe0007b7          	lui	a5,0xfe000
ffffffffc0202cf6:	973e                	add	a4,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc0202cf8:	6a9c                	ld	a5,16(a3)
ffffffffc0202cfa:	00c45593          	srli	a1,s0,0xc
ffffffffc0202cfe:	00e60533          	add	a0,a2,a4
ffffffffc0202d02:	9782                	jalr	a5
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202d04:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202d08:	bcf1                	j	ffffffffc02027e4 <pmm_init+0xfe>
        intr_disable();
ffffffffc0202d0a:	bf5fd0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d0e:	000b3783          	ld	a5,0(s6)
ffffffffc0202d12:	4505                	li	a0,1
ffffffffc0202d14:	6f9c                	ld	a5,24(a5)
ffffffffc0202d16:	9782                	jalr	a5
ffffffffc0202d18:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202d1a:	bdffd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202d1e:	b119                	j	ffffffffc0202924 <pmm_init+0x23e>
        intr_disable();
ffffffffc0202d20:	bdffd0ef          	jal	ffffffffc02008fe <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d24:	000b3783          	ld	a5,0(s6)
ffffffffc0202d28:	779c                	ld	a5,40(a5)
ffffffffc0202d2a:	9782                	jalr	a5
ffffffffc0202d2c:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202d2e:	bcbfd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202d32:	b345                	j	ffffffffc0202ad2 <pmm_init+0x3ec>
        intr_disable();
ffffffffc0202d34:	bcbfd0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0202d38:	000b3783          	ld	a5,0(s6)
ffffffffc0202d3c:	779c                	ld	a5,40(a5)
ffffffffc0202d3e:	9782                	jalr	a5
ffffffffc0202d40:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d42:	bb7fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202d46:	b3a5                	j	ffffffffc0202aae <pmm_init+0x3c8>
ffffffffc0202d48:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d4a:	bb5fd0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202d4e:	000b3783          	ld	a5,0(s6)
ffffffffc0202d52:	6522                	ld	a0,8(sp)
ffffffffc0202d54:	4585                	li	a1,1
ffffffffc0202d56:	739c                	ld	a5,32(a5)
ffffffffc0202d58:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d5a:	b9ffd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202d5e:	bb05                	j	ffffffffc0202a8e <pmm_init+0x3a8>
ffffffffc0202d60:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d62:	b9dfd0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0202d66:	000b3783          	ld	a5,0(s6)
ffffffffc0202d6a:	6522                	ld	a0,8(sp)
ffffffffc0202d6c:	4585                	li	a1,1
ffffffffc0202d6e:	739c                	ld	a5,32(a5)
ffffffffc0202d70:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d72:	b87fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202d76:	b1e5                	j	ffffffffc0202a5e <pmm_init+0x378>
        intr_disable();
ffffffffc0202d78:	b87fd0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d7c:	000b3783          	ld	a5,0(s6)
ffffffffc0202d80:	4505                	li	a0,1
ffffffffc0202d82:	6f9c                	ld	a5,24(a5)
ffffffffc0202d84:	9782                	jalr	a5
ffffffffc0202d86:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202d88:	b71fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202d8c:	b375                	j	ffffffffc0202b38 <pmm_init+0x452>
        intr_disable();
ffffffffc0202d8e:	b71fd0ef          	jal	ffffffffc02008fe <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d92:	000b3783          	ld	a5,0(s6)
ffffffffc0202d96:	779c                	ld	a5,40(a5)
ffffffffc0202d98:	9782                	jalr	a5
ffffffffc0202d9a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202d9c:	b5dfd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202da0:	b5c5                	j	ffffffffc0202c80 <pmm_init+0x59a>
ffffffffc0202da2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202da4:	b5bfd0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202da8:	000b3783          	ld	a5,0(s6)
ffffffffc0202dac:	6522                	ld	a0,8(sp)
ffffffffc0202dae:	4585                	li	a1,1
ffffffffc0202db0:	739c                	ld	a5,32(a5)
ffffffffc0202db2:	9782                	jalr	a5
        intr_enable();
ffffffffc0202db4:	b45fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202db8:	b565                	j	ffffffffc0202c60 <pmm_init+0x57a>
ffffffffc0202dba:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202dbc:	b43fd0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0202dc0:	000b3783          	ld	a5,0(s6)
ffffffffc0202dc4:	6522                	ld	a0,8(sp)
ffffffffc0202dc6:	4585                	li	a1,1
ffffffffc0202dc8:	739c                	ld	a5,32(a5)
ffffffffc0202dca:	9782                	jalr	a5
        intr_enable();
ffffffffc0202dcc:	b2dfd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202dd0:	b585                	j	ffffffffc0202c30 <pmm_init+0x54a>
        intr_disable();
ffffffffc0202dd2:	b2dfd0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0202dd6:	000b3783          	ld	a5,0(s6)
ffffffffc0202dda:	8522                	mv	a0,s0
ffffffffc0202ddc:	4585                	li	a1,1
ffffffffc0202dde:	739c                	ld	a5,32(a5)
ffffffffc0202de0:	9782                	jalr	a5
        intr_enable();
ffffffffc0202de2:	b17fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202de6:	bd29                	j	ffffffffc0202c00 <pmm_init+0x51a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202de8:	86a2                	mv	a3,s0
ffffffffc0202dea:	00004617          	auipc	a2,0x4
ffffffffc0202dee:	a1660613          	addi	a2,a2,-1514 # ffffffffc0206800 <etext+0xdc8>
ffffffffc0202df2:	23f00593          	li	a1,575
ffffffffc0202df6:	00004517          	auipc	a0,0x4
ffffffffc0202dfa:	afa50513          	addi	a0,a0,-1286 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0202dfe:	e4cfd0ef          	jal	ffffffffc020044a <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202e02:	00004697          	auipc	a3,0x4
ffffffffc0202e06:	f8668693          	addi	a3,a3,-122 # ffffffffc0206d88 <etext+0x1350>
ffffffffc0202e0a:	00003617          	auipc	a2,0x3
ffffffffc0202e0e:	64660613          	addi	a2,a2,1606 # ffffffffc0206450 <etext+0xa18>
ffffffffc0202e12:	24000593          	li	a1,576
ffffffffc0202e16:	00004517          	auipc	a0,0x4
ffffffffc0202e1a:	ada50513          	addi	a0,a0,-1318 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0202e1e:	e2cfd0ef          	jal	ffffffffc020044a <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202e22:	00004697          	auipc	a3,0x4
ffffffffc0202e26:	f2668693          	addi	a3,a3,-218 # ffffffffc0206d48 <etext+0x1310>
ffffffffc0202e2a:	00003617          	auipc	a2,0x3
ffffffffc0202e2e:	62660613          	addi	a2,a2,1574 # ffffffffc0206450 <etext+0xa18>
ffffffffc0202e32:	23f00593          	li	a1,575
ffffffffc0202e36:	00004517          	auipc	a0,0x4
ffffffffc0202e3a:	aba50513          	addi	a0,a0,-1350 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0202e3e:	e0cfd0ef          	jal	ffffffffc020044a <__panic>
ffffffffc0202e42:	fb5fe0ef          	jal	ffffffffc0201df6 <pa2page.part.0>
        panic("pte2page called with invalid pte");
ffffffffc0202e46:	00004617          	auipc	a2,0x4
ffffffffc0202e4a:	ca260613          	addi	a2,a2,-862 # ffffffffc0206ae8 <etext+0x10b0>
ffffffffc0202e4e:	07f00593          	li	a1,127
ffffffffc0202e52:	00004517          	auipc	a0,0x4
ffffffffc0202e56:	9d650513          	addi	a0,a0,-1578 # ffffffffc0206828 <etext+0xdf0>
ffffffffc0202e5a:	df0fd0ef          	jal	ffffffffc020044a <__panic>
        panic("DTB memory info not available");
ffffffffc0202e5e:	00004617          	auipc	a2,0x4
ffffffffc0202e62:	b0260613          	addi	a2,a2,-1278 # ffffffffc0206960 <etext+0xf28>
ffffffffc0202e66:	06500593          	li	a1,101
ffffffffc0202e6a:	00004517          	auipc	a0,0x4
ffffffffc0202e6e:	a8650513          	addi	a0,a0,-1402 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0202e72:	dd8fd0ef          	jal	ffffffffc020044a <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202e76:	00004697          	auipc	a3,0x4
ffffffffc0202e7a:	e8a68693          	addi	a3,a3,-374 # ffffffffc0206d00 <etext+0x12c8>
ffffffffc0202e7e:	00003617          	auipc	a2,0x3
ffffffffc0202e82:	5d260613          	addi	a2,a2,1490 # ffffffffc0206450 <etext+0xa18>
ffffffffc0202e86:	25a00593          	li	a1,602
ffffffffc0202e8a:	00004517          	auipc	a0,0x4
ffffffffc0202e8e:	a6650513          	addi	a0,a0,-1434 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0202e92:	db8fd0ef          	jal	ffffffffc020044a <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202e96:	00004697          	auipc	a3,0x4
ffffffffc0202e9a:	b8268693          	addi	a3,a3,-1150 # ffffffffc0206a18 <etext+0xfe0>
ffffffffc0202e9e:	00003617          	auipc	a2,0x3
ffffffffc0202ea2:	5b260613          	addi	a2,a2,1458 # ffffffffc0206450 <etext+0xa18>
ffffffffc0202ea6:	20100593          	li	a1,513
ffffffffc0202eaa:	00004517          	auipc	a0,0x4
ffffffffc0202eae:	a4650513          	addi	a0,a0,-1466 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0202eb2:	d98fd0ef          	jal	ffffffffc020044a <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202eb6:	00004697          	auipc	a3,0x4
ffffffffc0202eba:	b4268693          	addi	a3,a3,-1214 # ffffffffc02069f8 <etext+0xfc0>
ffffffffc0202ebe:	00003617          	auipc	a2,0x3
ffffffffc0202ec2:	59260613          	addi	a2,a2,1426 # ffffffffc0206450 <etext+0xa18>
ffffffffc0202ec6:	20000593          	li	a1,512
ffffffffc0202eca:	00004517          	auipc	a0,0x4
ffffffffc0202ece:	a2650513          	addi	a0,a0,-1498 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0202ed2:	d78fd0ef          	jal	ffffffffc020044a <__panic>
    return KADDR(page2pa(page));
ffffffffc0202ed6:	00004617          	auipc	a2,0x4
ffffffffc0202eda:	92a60613          	addi	a2,a2,-1750 # ffffffffc0206800 <etext+0xdc8>
ffffffffc0202ede:	07100593          	li	a1,113
ffffffffc0202ee2:	00004517          	auipc	a0,0x4
ffffffffc0202ee6:	94650513          	addi	a0,a0,-1722 # ffffffffc0206828 <etext+0xdf0>
ffffffffc0202eea:	d60fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202eee:	00004697          	auipc	a3,0x4
ffffffffc0202ef2:	de268693          	addi	a3,a3,-542 # ffffffffc0206cd0 <etext+0x1298>
ffffffffc0202ef6:	00003617          	auipc	a2,0x3
ffffffffc0202efa:	55a60613          	addi	a2,a2,1370 # ffffffffc0206450 <etext+0xa18>
ffffffffc0202efe:	22800593          	li	a1,552
ffffffffc0202f02:	00004517          	auipc	a0,0x4
ffffffffc0202f06:	9ee50513          	addi	a0,a0,-1554 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0202f0a:	d40fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f0e:	00004697          	auipc	a3,0x4
ffffffffc0202f12:	d7a68693          	addi	a3,a3,-646 # ffffffffc0206c88 <etext+0x1250>
ffffffffc0202f16:	00003617          	auipc	a2,0x3
ffffffffc0202f1a:	53a60613          	addi	a2,a2,1338 # ffffffffc0206450 <etext+0xa18>
ffffffffc0202f1e:	22600593          	li	a1,550
ffffffffc0202f22:	00004517          	auipc	a0,0x4
ffffffffc0202f26:	9ce50513          	addi	a0,a0,-1586 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0202f2a:	d20fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202f2e:	00004697          	auipc	a3,0x4
ffffffffc0202f32:	d8a68693          	addi	a3,a3,-630 # ffffffffc0206cb8 <etext+0x1280>
ffffffffc0202f36:	00003617          	auipc	a2,0x3
ffffffffc0202f3a:	51a60613          	addi	a2,a2,1306 # ffffffffc0206450 <etext+0xa18>
ffffffffc0202f3e:	22500593          	li	a1,549
ffffffffc0202f42:	00004517          	auipc	a0,0x4
ffffffffc0202f46:	9ae50513          	addi	a0,a0,-1618 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0202f4a:	d00fd0ef          	jal	ffffffffc020044a <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202f4e:	00004697          	auipc	a3,0x4
ffffffffc0202f52:	e5268693          	addi	a3,a3,-430 # ffffffffc0206da0 <etext+0x1368>
ffffffffc0202f56:	00003617          	auipc	a2,0x3
ffffffffc0202f5a:	4fa60613          	addi	a2,a2,1274 # ffffffffc0206450 <etext+0xa18>
ffffffffc0202f5e:	24300593          	li	a1,579
ffffffffc0202f62:	00004517          	auipc	a0,0x4
ffffffffc0202f66:	98e50513          	addi	a0,a0,-1650 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0202f6a:	ce0fd0ef          	jal	ffffffffc020044a <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202f6e:	00004697          	auipc	a3,0x4
ffffffffc0202f72:	d9268693          	addi	a3,a3,-622 # ffffffffc0206d00 <etext+0x12c8>
ffffffffc0202f76:	00003617          	auipc	a2,0x3
ffffffffc0202f7a:	4da60613          	addi	a2,a2,1242 # ffffffffc0206450 <etext+0xa18>
ffffffffc0202f7e:	23000593          	li	a1,560
ffffffffc0202f82:	00004517          	auipc	a0,0x4
ffffffffc0202f86:	96e50513          	addi	a0,a0,-1682 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0202f8a:	cc0fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202f8e:	00004697          	auipc	a3,0x4
ffffffffc0202f92:	e6a68693          	addi	a3,a3,-406 # ffffffffc0206df8 <etext+0x13c0>
ffffffffc0202f96:	00003617          	auipc	a2,0x3
ffffffffc0202f9a:	4ba60613          	addi	a2,a2,1210 # ffffffffc0206450 <etext+0xa18>
ffffffffc0202f9e:	24800593          	li	a1,584
ffffffffc0202fa2:	00004517          	auipc	a0,0x4
ffffffffc0202fa6:	94e50513          	addi	a0,a0,-1714 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0202faa:	ca0fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202fae:	00004697          	auipc	a3,0x4
ffffffffc0202fb2:	e0a68693          	addi	a3,a3,-502 # ffffffffc0206db8 <etext+0x1380>
ffffffffc0202fb6:	00003617          	auipc	a2,0x3
ffffffffc0202fba:	49a60613          	addi	a2,a2,1178 # ffffffffc0206450 <etext+0xa18>
ffffffffc0202fbe:	24700593          	li	a1,583
ffffffffc0202fc2:	00004517          	auipc	a0,0x4
ffffffffc0202fc6:	92e50513          	addi	a0,a0,-1746 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0202fca:	c80fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202fce:	00004697          	auipc	a3,0x4
ffffffffc0202fd2:	cba68693          	addi	a3,a3,-838 # ffffffffc0206c88 <etext+0x1250>
ffffffffc0202fd6:	00003617          	auipc	a2,0x3
ffffffffc0202fda:	47a60613          	addi	a2,a2,1146 # ffffffffc0206450 <etext+0xa18>
ffffffffc0202fde:	22200593          	li	a1,546
ffffffffc0202fe2:	00004517          	auipc	a0,0x4
ffffffffc0202fe6:	90e50513          	addi	a0,a0,-1778 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0202fea:	c60fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202fee:	00004697          	auipc	a3,0x4
ffffffffc0202ff2:	b3a68693          	addi	a3,a3,-1222 # ffffffffc0206b28 <etext+0x10f0>
ffffffffc0202ff6:	00003617          	auipc	a2,0x3
ffffffffc0202ffa:	45a60613          	addi	a2,a2,1114 # ffffffffc0206450 <etext+0xa18>
ffffffffc0202ffe:	22100593          	li	a1,545
ffffffffc0203002:	00004517          	auipc	a0,0x4
ffffffffc0203006:	8ee50513          	addi	a0,a0,-1810 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc020300a:	c40fd0ef          	jal	ffffffffc020044a <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc020300e:	00004697          	auipc	a3,0x4
ffffffffc0203012:	c9268693          	addi	a3,a3,-878 # ffffffffc0206ca0 <etext+0x1268>
ffffffffc0203016:	00003617          	auipc	a2,0x3
ffffffffc020301a:	43a60613          	addi	a2,a2,1082 # ffffffffc0206450 <etext+0xa18>
ffffffffc020301e:	21e00593          	li	a1,542
ffffffffc0203022:	00004517          	auipc	a0,0x4
ffffffffc0203026:	8ce50513          	addi	a0,a0,-1842 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc020302a:	c20fd0ef          	jal	ffffffffc020044a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020302e:	00004697          	auipc	a3,0x4
ffffffffc0203032:	ae268693          	addi	a3,a3,-1310 # ffffffffc0206b10 <etext+0x10d8>
ffffffffc0203036:	00003617          	auipc	a2,0x3
ffffffffc020303a:	41a60613          	addi	a2,a2,1050 # ffffffffc0206450 <etext+0xa18>
ffffffffc020303e:	21d00593          	li	a1,541
ffffffffc0203042:	00004517          	auipc	a0,0x4
ffffffffc0203046:	8ae50513          	addi	a0,a0,-1874 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc020304a:	c00fd0ef          	jal	ffffffffc020044a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020304e:	00004697          	auipc	a3,0x4
ffffffffc0203052:	b6268693          	addi	a3,a3,-1182 # ffffffffc0206bb0 <etext+0x1178>
ffffffffc0203056:	00003617          	auipc	a2,0x3
ffffffffc020305a:	3fa60613          	addi	a2,a2,1018 # ffffffffc0206450 <etext+0xa18>
ffffffffc020305e:	21c00593          	li	a1,540
ffffffffc0203062:	00004517          	auipc	a0,0x4
ffffffffc0203066:	88e50513          	addi	a0,a0,-1906 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc020306a:	be0fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020306e:	00004697          	auipc	a3,0x4
ffffffffc0203072:	c1a68693          	addi	a3,a3,-998 # ffffffffc0206c88 <etext+0x1250>
ffffffffc0203076:	00003617          	auipc	a2,0x3
ffffffffc020307a:	3da60613          	addi	a2,a2,986 # ffffffffc0206450 <etext+0xa18>
ffffffffc020307e:	21b00593          	li	a1,539
ffffffffc0203082:	00004517          	auipc	a0,0x4
ffffffffc0203086:	86e50513          	addi	a0,a0,-1938 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc020308a:	bc0fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p1) == 2);
ffffffffc020308e:	00004697          	auipc	a3,0x4
ffffffffc0203092:	be268693          	addi	a3,a3,-1054 # ffffffffc0206c70 <etext+0x1238>
ffffffffc0203096:	00003617          	auipc	a2,0x3
ffffffffc020309a:	3ba60613          	addi	a2,a2,954 # ffffffffc0206450 <etext+0xa18>
ffffffffc020309e:	21a00593          	li	a1,538
ffffffffc02030a2:	00004517          	auipc	a0,0x4
ffffffffc02030a6:	84e50513          	addi	a0,a0,-1970 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc02030aa:	ba0fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02030ae:	00004697          	auipc	a3,0x4
ffffffffc02030b2:	b9268693          	addi	a3,a3,-1134 # ffffffffc0206c40 <etext+0x1208>
ffffffffc02030b6:	00003617          	auipc	a2,0x3
ffffffffc02030ba:	39a60613          	addi	a2,a2,922 # ffffffffc0206450 <etext+0xa18>
ffffffffc02030be:	21900593          	li	a1,537
ffffffffc02030c2:	00004517          	auipc	a0,0x4
ffffffffc02030c6:	82e50513          	addi	a0,a0,-2002 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc02030ca:	b80fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p2) == 1);
ffffffffc02030ce:	00004697          	auipc	a3,0x4
ffffffffc02030d2:	b5a68693          	addi	a3,a3,-1190 # ffffffffc0206c28 <etext+0x11f0>
ffffffffc02030d6:	00003617          	auipc	a2,0x3
ffffffffc02030da:	37a60613          	addi	a2,a2,890 # ffffffffc0206450 <etext+0xa18>
ffffffffc02030de:	21700593          	li	a1,535
ffffffffc02030e2:	00004517          	auipc	a0,0x4
ffffffffc02030e6:	80e50513          	addi	a0,a0,-2034 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc02030ea:	b60fd0ef          	jal	ffffffffc020044a <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02030ee:	00004697          	auipc	a3,0x4
ffffffffc02030f2:	b1a68693          	addi	a3,a3,-1254 # ffffffffc0206c08 <etext+0x11d0>
ffffffffc02030f6:	00003617          	auipc	a2,0x3
ffffffffc02030fa:	35a60613          	addi	a2,a2,858 # ffffffffc0206450 <etext+0xa18>
ffffffffc02030fe:	21600593          	li	a1,534
ffffffffc0203102:	00003517          	auipc	a0,0x3
ffffffffc0203106:	7ee50513          	addi	a0,a0,2030 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc020310a:	b40fd0ef          	jal	ffffffffc020044a <__panic>
    assert(*ptep & PTE_W);
ffffffffc020310e:	00004697          	auipc	a3,0x4
ffffffffc0203112:	aea68693          	addi	a3,a3,-1302 # ffffffffc0206bf8 <etext+0x11c0>
ffffffffc0203116:	00003617          	auipc	a2,0x3
ffffffffc020311a:	33a60613          	addi	a2,a2,826 # ffffffffc0206450 <etext+0xa18>
ffffffffc020311e:	21500593          	li	a1,533
ffffffffc0203122:	00003517          	auipc	a0,0x3
ffffffffc0203126:	7ce50513          	addi	a0,a0,1998 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc020312a:	b20fd0ef          	jal	ffffffffc020044a <__panic>
    assert(*ptep & PTE_U);
ffffffffc020312e:	00004697          	auipc	a3,0x4
ffffffffc0203132:	aba68693          	addi	a3,a3,-1350 # ffffffffc0206be8 <etext+0x11b0>
ffffffffc0203136:	00003617          	auipc	a2,0x3
ffffffffc020313a:	31a60613          	addi	a2,a2,794 # ffffffffc0206450 <etext+0xa18>
ffffffffc020313e:	21400593          	li	a1,532
ffffffffc0203142:	00003517          	auipc	a0,0x3
ffffffffc0203146:	7ae50513          	addi	a0,a0,1966 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc020314a:	b00fd0ef          	jal	ffffffffc020044a <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020314e:	00003617          	auipc	a2,0x3
ffffffffc0203152:	75a60613          	addi	a2,a2,1882 # ffffffffc02068a8 <etext+0xe70>
ffffffffc0203156:	08100593          	li	a1,129
ffffffffc020315a:	00003517          	auipc	a0,0x3
ffffffffc020315e:	79650513          	addi	a0,a0,1942 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0203162:	ae8fd0ef          	jal	ffffffffc020044a <__panic>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0203166:	00004697          	auipc	a3,0x4
ffffffffc020316a:	9da68693          	addi	a3,a3,-1574 # ffffffffc0206b40 <etext+0x1108>
ffffffffc020316e:	00003617          	auipc	a2,0x3
ffffffffc0203172:	2e260613          	addi	a2,a2,738 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203176:	20f00593          	li	a1,527
ffffffffc020317a:	00003517          	auipc	a0,0x3
ffffffffc020317e:	77650513          	addi	a0,a0,1910 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0203182:	ac8fd0ef          	jal	ffffffffc020044a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203186:	00004697          	auipc	a3,0x4
ffffffffc020318a:	a2a68693          	addi	a3,a3,-1494 # ffffffffc0206bb0 <etext+0x1178>
ffffffffc020318e:	00003617          	auipc	a2,0x3
ffffffffc0203192:	2c260613          	addi	a2,a2,706 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203196:	21300593          	li	a1,531
ffffffffc020319a:	00003517          	auipc	a0,0x3
ffffffffc020319e:	75650513          	addi	a0,a0,1878 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc02031a2:	aa8fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02031a6:	00004697          	auipc	a3,0x4
ffffffffc02031aa:	9ca68693          	addi	a3,a3,-1590 # ffffffffc0206b70 <etext+0x1138>
ffffffffc02031ae:	00003617          	auipc	a2,0x3
ffffffffc02031b2:	2a260613          	addi	a2,a2,674 # ffffffffc0206450 <etext+0xa18>
ffffffffc02031b6:	21200593          	li	a1,530
ffffffffc02031ba:	00003517          	auipc	a0,0x3
ffffffffc02031be:	73650513          	addi	a0,a0,1846 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc02031c2:	a88fd0ef          	jal	ffffffffc020044a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02031c6:	86d6                	mv	a3,s5
ffffffffc02031c8:	00003617          	auipc	a2,0x3
ffffffffc02031cc:	63860613          	addi	a2,a2,1592 # ffffffffc0206800 <etext+0xdc8>
ffffffffc02031d0:	20e00593          	li	a1,526
ffffffffc02031d4:	00003517          	auipc	a0,0x3
ffffffffc02031d8:	71c50513          	addi	a0,a0,1820 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc02031dc:	a6efd0ef          	jal	ffffffffc020044a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02031e0:	00003617          	auipc	a2,0x3
ffffffffc02031e4:	62060613          	addi	a2,a2,1568 # ffffffffc0206800 <etext+0xdc8>
ffffffffc02031e8:	20d00593          	li	a1,525
ffffffffc02031ec:	00003517          	auipc	a0,0x3
ffffffffc02031f0:	70450513          	addi	a0,a0,1796 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc02031f4:	a56fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02031f8:	00004697          	auipc	a3,0x4
ffffffffc02031fc:	93068693          	addi	a3,a3,-1744 # ffffffffc0206b28 <etext+0x10f0>
ffffffffc0203200:	00003617          	auipc	a2,0x3
ffffffffc0203204:	25060613          	addi	a2,a2,592 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203208:	20b00593          	li	a1,523
ffffffffc020320c:	00003517          	auipc	a0,0x3
ffffffffc0203210:	6e450513          	addi	a0,a0,1764 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0203214:	a36fd0ef          	jal	ffffffffc020044a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203218:	00004697          	auipc	a3,0x4
ffffffffc020321c:	8f868693          	addi	a3,a3,-1800 # ffffffffc0206b10 <etext+0x10d8>
ffffffffc0203220:	00003617          	auipc	a2,0x3
ffffffffc0203224:	23060613          	addi	a2,a2,560 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203228:	20a00593          	li	a1,522
ffffffffc020322c:	00003517          	auipc	a0,0x3
ffffffffc0203230:	6c450513          	addi	a0,a0,1732 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0203234:	a16fd0ef          	jal	ffffffffc020044a <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0203238:	00004697          	auipc	a3,0x4
ffffffffc020323c:	c8868693          	addi	a3,a3,-888 # ffffffffc0206ec0 <etext+0x1488>
ffffffffc0203240:	00003617          	auipc	a2,0x3
ffffffffc0203244:	21060613          	addi	a2,a2,528 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203248:	25100593          	li	a1,593
ffffffffc020324c:	00003517          	auipc	a0,0x3
ffffffffc0203250:	6a450513          	addi	a0,a0,1700 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0203254:	9f6fd0ef          	jal	ffffffffc020044a <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0203258:	00004697          	auipc	a3,0x4
ffffffffc020325c:	c3068693          	addi	a3,a3,-976 # ffffffffc0206e88 <etext+0x1450>
ffffffffc0203260:	00003617          	auipc	a2,0x3
ffffffffc0203264:	1f060613          	addi	a2,a2,496 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203268:	24e00593          	li	a1,590
ffffffffc020326c:	00003517          	auipc	a0,0x3
ffffffffc0203270:	68450513          	addi	a0,a0,1668 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0203274:	9d6fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p) == 2);
ffffffffc0203278:	00004697          	auipc	a3,0x4
ffffffffc020327c:	be068693          	addi	a3,a3,-1056 # ffffffffc0206e58 <etext+0x1420>
ffffffffc0203280:	00003617          	auipc	a2,0x3
ffffffffc0203284:	1d060613          	addi	a2,a2,464 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203288:	24a00593          	li	a1,586
ffffffffc020328c:	00003517          	auipc	a0,0x3
ffffffffc0203290:	66450513          	addi	a0,a0,1636 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0203294:	9b6fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0203298:	00004697          	auipc	a3,0x4
ffffffffc020329c:	b7868693          	addi	a3,a3,-1160 # ffffffffc0206e10 <etext+0x13d8>
ffffffffc02032a0:	00003617          	auipc	a2,0x3
ffffffffc02032a4:	1b060613          	addi	a2,a2,432 # ffffffffc0206450 <etext+0xa18>
ffffffffc02032a8:	24900593          	li	a1,585
ffffffffc02032ac:	00003517          	auipc	a0,0x3
ffffffffc02032b0:	64450513          	addi	a0,a0,1604 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc02032b4:	996fd0ef          	jal	ffffffffc020044a <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02032b8:	00003697          	auipc	a3,0x3
ffffffffc02032bc:	7a068693          	addi	a3,a3,1952 # ffffffffc0206a58 <etext+0x1020>
ffffffffc02032c0:	00003617          	auipc	a2,0x3
ffffffffc02032c4:	19060613          	addi	a2,a2,400 # ffffffffc0206450 <etext+0xa18>
ffffffffc02032c8:	20200593          	li	a1,514
ffffffffc02032cc:	00003517          	auipc	a0,0x3
ffffffffc02032d0:	62450513          	addi	a0,a0,1572 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc02032d4:	976fd0ef          	jal	ffffffffc020044a <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02032d8:	00003617          	auipc	a2,0x3
ffffffffc02032dc:	5d060613          	addi	a2,a2,1488 # ffffffffc02068a8 <etext+0xe70>
ffffffffc02032e0:	0c900593          	li	a1,201
ffffffffc02032e4:	00003517          	auipc	a0,0x3
ffffffffc02032e8:	60c50513          	addi	a0,a0,1548 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc02032ec:	95efd0ef          	jal	ffffffffc020044a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02032f0:	00003697          	auipc	a3,0x3
ffffffffc02032f4:	7c868693          	addi	a3,a3,1992 # ffffffffc0206ab8 <etext+0x1080>
ffffffffc02032f8:	00003617          	auipc	a2,0x3
ffffffffc02032fc:	15860613          	addi	a2,a2,344 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203300:	20900593          	li	a1,521
ffffffffc0203304:	00003517          	auipc	a0,0x3
ffffffffc0203308:	5ec50513          	addi	a0,a0,1516 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc020330c:	93efd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0203310:	00003697          	auipc	a3,0x3
ffffffffc0203314:	77868693          	addi	a3,a3,1912 # ffffffffc0206a88 <etext+0x1050>
ffffffffc0203318:	00003617          	auipc	a2,0x3
ffffffffc020331c:	13860613          	addi	a2,a2,312 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203320:	20600593          	li	a1,518
ffffffffc0203324:	00003517          	auipc	a0,0x3
ffffffffc0203328:	5cc50513          	addi	a0,a0,1484 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc020332c:	91efd0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0203330 <copy_range>:
{
ffffffffc0203330:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203332:	00d667b3          	or	a5,a2,a3
{
ffffffffc0203336:	f486                	sd	ra,104(sp)
ffffffffc0203338:	f0a2                	sd	s0,96(sp)
ffffffffc020333a:	eca6                	sd	s1,88(sp)
ffffffffc020333c:	e8ca                	sd	s2,80(sp)
ffffffffc020333e:	e4ce                	sd	s3,72(sp)
ffffffffc0203340:	e0d2                	sd	s4,64(sp)
ffffffffc0203342:	fc56                	sd	s5,56(sp)
ffffffffc0203344:	f85a                	sd	s6,48(sp)
ffffffffc0203346:	f45e                	sd	s7,40(sp)
ffffffffc0203348:	f062                	sd	s8,32(sp)
ffffffffc020334a:	ec66                	sd	s9,24(sp)
ffffffffc020334c:	e86a                	sd	s10,16(sp)
ffffffffc020334e:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203350:	03479713          	slli	a4,a5,0x34
ffffffffc0203354:	1e071063          	bnez	a4,ffffffffc0203534 <copy_range+0x204>
    assert(USER_ACCESS(start, end));
ffffffffc0203358:	002007b7          	lui	a5,0x200
ffffffffc020335c:	00d63733          	sltu	a4,a2,a3
ffffffffc0203360:	00f637b3          	sltu	a5,a2,a5
ffffffffc0203364:	00173713          	seqz	a4,a4
ffffffffc0203368:	8fd9                	or	a5,a5,a4
ffffffffc020336a:	8432                	mv	s0,a2
ffffffffc020336c:	8936                	mv	s2,a3
ffffffffc020336e:	1a079363          	bnez	a5,ffffffffc0203514 <copy_range+0x1e4>
ffffffffc0203372:	4785                	li	a5,1
ffffffffc0203374:	07fe                	slli	a5,a5,0x1f
ffffffffc0203376:	0785                	addi	a5,a5,1 # 200001 <_binary_obj___user_matrix_out_size+0x1f4a81>
ffffffffc0203378:	18f6fe63          	bgeu	a3,a5,ffffffffc0203514 <copy_range+0x1e4>
ffffffffc020337c:	5b7d                	li	s6,-1
ffffffffc020337e:	8baa                	mv	s7,a0
ffffffffc0203380:	8a2e                	mv	s4,a1
ffffffffc0203382:	6a85                	lui	s5,0x1
ffffffffc0203384:	00cb5b13          	srli	s6,s6,0xc
    if (PPN(pa) >= npage)
ffffffffc0203388:	000b2c97          	auipc	s9,0xb2
ffffffffc020338c:	718c8c93          	addi	s9,s9,1816 # ffffffffc02b5aa0 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203390:	000b2c17          	auipc	s8,0xb2
ffffffffc0203394:	718c0c13          	addi	s8,s8,1816 # ffffffffc02b5aa8 <pages>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc0203398:	4601                	li	a2,0
ffffffffc020339a:	85a2                	mv	a1,s0
ffffffffc020339c:	8552                	mv	a0,s4
ffffffffc020339e:	b1dfe0ef          	jal	ffffffffc0201eba <get_pte>
ffffffffc02033a2:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02033a4:	0e050c63          	beqz	a0,ffffffffc020349c <copy_range+0x16c>
        if (*ptep & PTE_V)
ffffffffc02033a8:	611c                	ld	a5,0(a0)
ffffffffc02033aa:	8b85                	andi	a5,a5,1
ffffffffc02033ac:	e78d                	bnez	a5,ffffffffc02033d6 <copy_range+0xa6>
        start += PGSIZE;
ffffffffc02033ae:	9456                	add	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc02033b0:	c019                	beqz	s0,ffffffffc02033b6 <copy_range+0x86>
ffffffffc02033b2:	ff2463e3          	bltu	s0,s2,ffffffffc0203398 <copy_range+0x68>
    return 0;
ffffffffc02033b6:	4501                	li	a0,0
}
ffffffffc02033b8:	70a6                	ld	ra,104(sp)
ffffffffc02033ba:	7406                	ld	s0,96(sp)
ffffffffc02033bc:	64e6                	ld	s1,88(sp)
ffffffffc02033be:	6946                	ld	s2,80(sp)
ffffffffc02033c0:	69a6                	ld	s3,72(sp)
ffffffffc02033c2:	6a06                	ld	s4,64(sp)
ffffffffc02033c4:	7ae2                	ld	s5,56(sp)
ffffffffc02033c6:	7b42                	ld	s6,48(sp)
ffffffffc02033c8:	7ba2                	ld	s7,40(sp)
ffffffffc02033ca:	7c02                	ld	s8,32(sp)
ffffffffc02033cc:	6ce2                	ld	s9,24(sp)
ffffffffc02033ce:	6d42                	ld	s10,16(sp)
ffffffffc02033d0:	6da2                	ld	s11,8(sp)
ffffffffc02033d2:	6165                	addi	sp,sp,112
ffffffffc02033d4:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc02033d6:	4605                	li	a2,1
ffffffffc02033d8:	85a2                	mv	a1,s0
ffffffffc02033da:	855e                	mv	a0,s7
ffffffffc02033dc:	adffe0ef          	jal	ffffffffc0201eba <get_pte>
ffffffffc02033e0:	c17d                	beqz	a0,ffffffffc02034c6 <copy_range+0x196>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02033e2:	0004b983          	ld	s3,0(s1)
    if (!(pte & PTE_V))
ffffffffc02033e6:	0019f793          	andi	a5,s3,1
ffffffffc02033ea:	10078963          	beqz	a5,ffffffffc02034fc <copy_range+0x1cc>
    if (PPN(pa) >= npage)
ffffffffc02033ee:	000cb783          	ld	a5,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc02033f2:	00299d93          	slli	s11,s3,0x2
ffffffffc02033f6:	00cddd93          	srli	s11,s11,0xc
    if (PPN(pa) >= npage)
ffffffffc02033fa:	0efdf563          	bgeu	s11,a5,ffffffffc02034e4 <copy_range+0x1b4>
    return &pages[PPN(pa) - nbase];
ffffffffc02033fe:	000c3483          	ld	s1,0(s8)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203402:	100027f3          	csrr	a5,sstatus
ffffffffc0203406:	8b89                	andi	a5,a5,2
ffffffffc0203408:	e3cd                	bnez	a5,ffffffffc02034aa <copy_range+0x17a>
        page = pmm_manager->alloc_pages(n);
ffffffffc020340a:	000b2797          	auipc	a5,0xb2
ffffffffc020340e:	6767b783          	ld	a5,1654(a5) # ffffffffc02b5a80 <pmm_manager>
ffffffffc0203412:	4505                	li	a0,1
ffffffffc0203414:	6f9c                	ld	a5,24(a5)
ffffffffc0203416:	9782                	jalr	a5
ffffffffc0203418:	8d2a                	mv	s10,a0
            if (npage == NULL)
ffffffffc020341a:	0a0d0663          	beqz	s10,ffffffffc02034c6 <copy_range+0x196>
ffffffffc020341e:	fff807b7          	lui	a5,0xfff80
ffffffffc0203422:	9dbe                	add	s11,s11,a5
    return page - pages + nbase;
ffffffffc0203424:	000c3783          	ld	a5,0(s8)
    return &pages[PPN(pa) - nbase];
ffffffffc0203428:	0d9a                	slli	s11,s11,0x6
ffffffffc020342a:	01b486b3          	add	a3,s1,s11
    return page - pages + nbase;
ffffffffc020342e:	8e9d                	sub	a3,a3,a5
ffffffffc0203430:	8699                	srai	a3,a3,0x6
ffffffffc0203432:	000805b7          	lui	a1,0x80
    return KADDR(page2pa(page));
ffffffffc0203436:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc020343a:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc020343c:	0166f533          	and	a0,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0203440:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203442:	08c57563          	bgeu	a0,a2,ffffffffc02034cc <copy_range+0x19c>
    return page - pages + nbase;
ffffffffc0203446:	40fd07b3          	sub	a5,s10,a5
ffffffffc020344a:	8799                	srai	a5,a5,0x6
ffffffffc020344c:	97ae                	add	a5,a5,a1
    return KADDR(page2pa(page));
ffffffffc020344e:	0167f5b3          	and	a1,a5,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0203452:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0203454:	06c5fb63          	bgeu	a1,a2,ffffffffc02034ca <copy_range+0x19a>
ffffffffc0203458:	000b2517          	auipc	a0,0xb2
ffffffffc020345c:	64053503          	ld	a0,1600(a0) # ffffffffc02b5a98 <va_pa_offset>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc0203460:	6605                	lui	a2,0x1
ffffffffc0203462:	00a685b3          	add	a1,a3,a0
ffffffffc0203466:	953e                	add	a0,a0,a5
ffffffffc0203468:	5b8020ef          	jal	ffffffffc0205a20 <memcpy>
            ret = page_insert(to, npage, start, perm);
ffffffffc020346c:	01f9f693          	andi	a3,s3,31
ffffffffc0203470:	85ea                	mv	a1,s10
ffffffffc0203472:	8622                	mv	a2,s0
ffffffffc0203474:	855e                	mv	a0,s7
ffffffffc0203476:	97aff0ef          	jal	ffffffffc02025f0 <page_insert>
            assert(ret == 0);
ffffffffc020347a:	d915                	beqz	a0,ffffffffc02033ae <copy_range+0x7e>
ffffffffc020347c:	00004697          	auipc	a3,0x4
ffffffffc0203480:	a8c68693          	addi	a3,a3,-1396 # ffffffffc0206f08 <etext+0x14d0>
ffffffffc0203484:	00003617          	auipc	a2,0x3
ffffffffc0203488:	fcc60613          	addi	a2,a2,-52 # ffffffffc0206450 <etext+0xa18>
ffffffffc020348c:	19e00593          	li	a1,414
ffffffffc0203490:	00003517          	auipc	a0,0x3
ffffffffc0203494:	46050513          	addi	a0,a0,1120 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0203498:	fb3fc0ef          	jal	ffffffffc020044a <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020349c:	002007b7          	lui	a5,0x200
ffffffffc02034a0:	97a2                	add	a5,a5,s0
ffffffffc02034a2:	ffe00437          	lui	s0,0xffe00
ffffffffc02034a6:	8c7d                	and	s0,s0,a5
            continue;
ffffffffc02034a8:	b721                	j	ffffffffc02033b0 <copy_range+0x80>
        intr_disable();
ffffffffc02034aa:	c54fd0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02034ae:	000b2797          	auipc	a5,0xb2
ffffffffc02034b2:	5d27b783          	ld	a5,1490(a5) # ffffffffc02b5a80 <pmm_manager>
ffffffffc02034b6:	4505                	li	a0,1
ffffffffc02034b8:	6f9c                	ld	a5,24(a5)
ffffffffc02034ba:	9782                	jalr	a5
ffffffffc02034bc:	8d2a                	mv	s10,a0
        intr_enable();
ffffffffc02034be:	c3afd0ef          	jal	ffffffffc02008f8 <intr_enable>
            if (npage == NULL)
ffffffffc02034c2:	f40d1ee3          	bnez	s10,ffffffffc020341e <copy_range+0xee>
                return -E_NO_MEM;
ffffffffc02034c6:	5571                	li	a0,-4
ffffffffc02034c8:	bdc5                	j	ffffffffc02033b8 <copy_range+0x88>
ffffffffc02034ca:	86be                	mv	a3,a5
ffffffffc02034cc:	00003617          	auipc	a2,0x3
ffffffffc02034d0:	33460613          	addi	a2,a2,820 # ffffffffc0206800 <etext+0xdc8>
ffffffffc02034d4:	07100593          	li	a1,113
ffffffffc02034d8:	00003517          	auipc	a0,0x3
ffffffffc02034dc:	35050513          	addi	a0,a0,848 # ffffffffc0206828 <etext+0xdf0>
ffffffffc02034e0:	f6bfc0ef          	jal	ffffffffc020044a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02034e4:	00003617          	auipc	a2,0x3
ffffffffc02034e8:	3ec60613          	addi	a2,a2,1004 # ffffffffc02068d0 <etext+0xe98>
ffffffffc02034ec:	06900593          	li	a1,105
ffffffffc02034f0:	00003517          	auipc	a0,0x3
ffffffffc02034f4:	33850513          	addi	a0,a0,824 # ffffffffc0206828 <etext+0xdf0>
ffffffffc02034f8:	f53fc0ef          	jal	ffffffffc020044a <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02034fc:	00003617          	auipc	a2,0x3
ffffffffc0203500:	5ec60613          	addi	a2,a2,1516 # ffffffffc0206ae8 <etext+0x10b0>
ffffffffc0203504:	07f00593          	li	a1,127
ffffffffc0203508:	00003517          	auipc	a0,0x3
ffffffffc020350c:	32050513          	addi	a0,a0,800 # ffffffffc0206828 <etext+0xdf0>
ffffffffc0203510:	f3bfc0ef          	jal	ffffffffc020044a <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0203514:	00003697          	auipc	a3,0x3
ffffffffc0203518:	41c68693          	addi	a3,a3,1052 # ffffffffc0206930 <etext+0xef8>
ffffffffc020351c:	00003617          	auipc	a2,0x3
ffffffffc0203520:	f3460613          	addi	a2,a2,-204 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203524:	17e00593          	li	a1,382
ffffffffc0203528:	00003517          	auipc	a0,0x3
ffffffffc020352c:	3c850513          	addi	a0,a0,968 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0203530:	f1bfc0ef          	jal	ffffffffc020044a <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203534:	00003697          	auipc	a3,0x3
ffffffffc0203538:	3cc68693          	addi	a3,a3,972 # ffffffffc0206900 <etext+0xec8>
ffffffffc020353c:	00003617          	auipc	a2,0x3
ffffffffc0203540:	f1460613          	addi	a2,a2,-236 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203544:	17d00593          	li	a1,381
ffffffffc0203548:	00003517          	auipc	a0,0x3
ffffffffc020354c:	3a850513          	addi	a0,a0,936 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc0203550:	efbfc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0203554 <pgdir_alloc_page>:
{
ffffffffc0203554:	7139                	addi	sp,sp,-64
ffffffffc0203556:	f426                	sd	s1,40(sp)
ffffffffc0203558:	f04a                	sd	s2,32(sp)
ffffffffc020355a:	ec4e                	sd	s3,24(sp)
ffffffffc020355c:	fc06                	sd	ra,56(sp)
ffffffffc020355e:	f822                	sd	s0,48(sp)
ffffffffc0203560:	892a                	mv	s2,a0
ffffffffc0203562:	84ae                	mv	s1,a1
ffffffffc0203564:	89b2                	mv	s3,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203566:	100027f3          	csrr	a5,sstatus
ffffffffc020356a:	8b89                	andi	a5,a5,2
ffffffffc020356c:	ebb5                	bnez	a5,ffffffffc02035e0 <pgdir_alloc_page+0x8c>
        page = pmm_manager->alloc_pages(n);
ffffffffc020356e:	000b2417          	auipc	s0,0xb2
ffffffffc0203572:	51240413          	addi	s0,s0,1298 # ffffffffc02b5a80 <pmm_manager>
ffffffffc0203576:	601c                	ld	a5,0(s0)
ffffffffc0203578:	4505                	li	a0,1
ffffffffc020357a:	6f9c                	ld	a5,24(a5)
ffffffffc020357c:	9782                	jalr	a5
ffffffffc020357e:	85aa                	mv	a1,a0
    if (page != NULL)
ffffffffc0203580:	c5b9                	beqz	a1,ffffffffc02035ce <pgdir_alloc_page+0x7a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc0203582:	86ce                	mv	a3,s3
ffffffffc0203584:	854a                	mv	a0,s2
ffffffffc0203586:	8626                	mv	a2,s1
ffffffffc0203588:	e42e                	sd	a1,8(sp)
ffffffffc020358a:	866ff0ef          	jal	ffffffffc02025f0 <page_insert>
ffffffffc020358e:	65a2                	ld	a1,8(sp)
ffffffffc0203590:	e515                	bnez	a0,ffffffffc02035bc <pgdir_alloc_page+0x68>
        assert(page_ref(page) == 1);
ffffffffc0203592:	4198                	lw	a4,0(a1)
        page->pra_vaddr = la;
ffffffffc0203594:	fd84                	sd	s1,56(a1)
        assert(page_ref(page) == 1);
ffffffffc0203596:	4785                	li	a5,1
ffffffffc0203598:	02f70c63          	beq	a4,a5,ffffffffc02035d0 <pgdir_alloc_page+0x7c>
ffffffffc020359c:	00004697          	auipc	a3,0x4
ffffffffc02035a0:	97c68693          	addi	a3,a3,-1668 # ffffffffc0206f18 <etext+0x14e0>
ffffffffc02035a4:	00003617          	auipc	a2,0x3
ffffffffc02035a8:	eac60613          	addi	a2,a2,-340 # ffffffffc0206450 <etext+0xa18>
ffffffffc02035ac:	1e700593          	li	a1,487
ffffffffc02035b0:	00003517          	auipc	a0,0x3
ffffffffc02035b4:	34050513          	addi	a0,a0,832 # ffffffffc02068f0 <etext+0xeb8>
ffffffffc02035b8:	e93fc0ef          	jal	ffffffffc020044a <__panic>
ffffffffc02035bc:	100027f3          	csrr	a5,sstatus
ffffffffc02035c0:	8b89                	andi	a5,a5,2
ffffffffc02035c2:	ef95                	bnez	a5,ffffffffc02035fe <pgdir_alloc_page+0xaa>
        pmm_manager->free_pages(base, n);
ffffffffc02035c4:	601c                	ld	a5,0(s0)
ffffffffc02035c6:	852e                	mv	a0,a1
ffffffffc02035c8:	4585                	li	a1,1
ffffffffc02035ca:	739c                	ld	a5,32(a5)
ffffffffc02035cc:	9782                	jalr	a5
            return NULL;
ffffffffc02035ce:	4581                	li	a1,0
}
ffffffffc02035d0:	70e2                	ld	ra,56(sp)
ffffffffc02035d2:	7442                	ld	s0,48(sp)
ffffffffc02035d4:	74a2                	ld	s1,40(sp)
ffffffffc02035d6:	7902                	ld	s2,32(sp)
ffffffffc02035d8:	69e2                	ld	s3,24(sp)
ffffffffc02035da:	852e                	mv	a0,a1
ffffffffc02035dc:	6121                	addi	sp,sp,64
ffffffffc02035de:	8082                	ret
        intr_disable();
ffffffffc02035e0:	b1efd0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02035e4:	000b2417          	auipc	s0,0xb2
ffffffffc02035e8:	49c40413          	addi	s0,s0,1180 # ffffffffc02b5a80 <pmm_manager>
ffffffffc02035ec:	601c                	ld	a5,0(s0)
ffffffffc02035ee:	4505                	li	a0,1
ffffffffc02035f0:	6f9c                	ld	a5,24(a5)
ffffffffc02035f2:	9782                	jalr	a5
ffffffffc02035f4:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02035f6:	b02fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc02035fa:	65a2                	ld	a1,8(sp)
ffffffffc02035fc:	b751                	j	ffffffffc0203580 <pgdir_alloc_page+0x2c>
        intr_disable();
ffffffffc02035fe:	b00fd0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0203602:	601c                	ld	a5,0(s0)
ffffffffc0203604:	6522                	ld	a0,8(sp)
ffffffffc0203606:	4585                	li	a1,1
ffffffffc0203608:	739c                	ld	a5,32(a5)
ffffffffc020360a:	9782                	jalr	a5
        intr_enable();
ffffffffc020360c:	aecfd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0203610:	bf7d                	j	ffffffffc02035ce <pgdir_alloc_page+0x7a>

ffffffffc0203612 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203612:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0203614:	00004697          	auipc	a3,0x4
ffffffffc0203618:	91c68693          	addi	a3,a3,-1764 # ffffffffc0206f30 <etext+0x14f8>
ffffffffc020361c:	00003617          	auipc	a2,0x3
ffffffffc0203620:	e3460613          	addi	a2,a2,-460 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203624:	07400593          	li	a1,116
ffffffffc0203628:	00004517          	auipc	a0,0x4
ffffffffc020362c:	92850513          	addi	a0,a0,-1752 # ffffffffc0206f50 <etext+0x1518>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203630:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0203632:	e19fc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0203636 <mm_create>:
{
ffffffffc0203636:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203638:	04000513          	li	a0,64
{
ffffffffc020363c:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020363e:	e12fe0ef          	jal	ffffffffc0201c50 <kmalloc>
    if (mm != NULL)
ffffffffc0203642:	cd19                	beqz	a0,ffffffffc0203660 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc0203644:	e508                	sd	a0,8(a0)
ffffffffc0203646:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203648:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc020364c:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203650:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203654:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc0203658:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc020365c:	02053c23          	sd	zero,56(a0)
}
ffffffffc0203660:	60a2                	ld	ra,8(sp)
ffffffffc0203662:	0141                	addi	sp,sp,16
ffffffffc0203664:	8082                	ret

ffffffffc0203666 <find_vma>:
    if (mm != NULL)
ffffffffc0203666:	c505                	beqz	a0,ffffffffc020368e <find_vma+0x28>
        vma = mm->mmap_cache;
ffffffffc0203668:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc020366a:	c781                	beqz	a5,ffffffffc0203672 <find_vma+0xc>
ffffffffc020366c:	6798                	ld	a4,8(a5)
ffffffffc020366e:	02e5f363          	bgeu	a1,a4,ffffffffc0203694 <find_vma+0x2e>
    return listelm->next;
ffffffffc0203672:	651c                	ld	a5,8(a0)
            while ((le = list_next(le)) != list)
ffffffffc0203674:	00f50d63          	beq	a0,a5,ffffffffc020368e <find_vma+0x28>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0203678:	fe87b703          	ld	a4,-24(a5)
ffffffffc020367c:	00e5e663          	bltu	a1,a4,ffffffffc0203688 <find_vma+0x22>
ffffffffc0203680:	ff07b703          	ld	a4,-16(a5)
ffffffffc0203684:	00e5ee63          	bltu	a1,a4,ffffffffc02036a0 <find_vma+0x3a>
ffffffffc0203688:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc020368a:	fef517e3          	bne	a0,a5,ffffffffc0203678 <find_vma+0x12>
    struct vma_struct *vma = NULL;
ffffffffc020368e:	4781                	li	a5,0
}
ffffffffc0203690:	853e                	mv	a0,a5
ffffffffc0203692:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203694:	6b98                	ld	a4,16(a5)
ffffffffc0203696:	fce5fee3          	bgeu	a1,a4,ffffffffc0203672 <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc020369a:	e91c                	sd	a5,16(a0)
}
ffffffffc020369c:	853e                	mv	a0,a5
ffffffffc020369e:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc02036a0:	1781                	addi	a5,a5,-32
            mm->mmap_cache = vma;
ffffffffc02036a2:	e91c                	sd	a5,16(a0)
ffffffffc02036a4:	bfe5                	j	ffffffffc020369c <find_vma+0x36>

ffffffffc02036a6 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc02036a6:	6590                	ld	a2,8(a1)
ffffffffc02036a8:	0105b803          	ld	a6,16(a1) # 80010 <_binary_obj___user_matrix_out_size+0x74a90>
{
ffffffffc02036ac:	1141                	addi	sp,sp,-16
ffffffffc02036ae:	e406                	sd	ra,8(sp)
ffffffffc02036b0:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc02036b2:	01066763          	bltu	a2,a6,ffffffffc02036c0 <insert_vma_struct+0x1a>
ffffffffc02036b6:	a8b9                	j	ffffffffc0203714 <insert_vma_struct+0x6e>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc02036b8:	fe87b703          	ld	a4,-24(a5)
ffffffffc02036bc:	04e66763          	bltu	a2,a4,ffffffffc020370a <insert_vma_struct+0x64>
ffffffffc02036c0:	86be                	mv	a3,a5
ffffffffc02036c2:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc02036c4:	fef51ae3          	bne	a0,a5,ffffffffc02036b8 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc02036c8:	02a68463          	beq	a3,a0,ffffffffc02036f0 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc02036cc:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc02036d0:	fe86b883          	ld	a7,-24(a3)
ffffffffc02036d4:	08e8f063          	bgeu	a7,a4,ffffffffc0203754 <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02036d8:	04e66e63          	bltu	a2,a4,ffffffffc0203734 <insert_vma_struct+0x8e>
    }
    if (le_next != list)
ffffffffc02036dc:	00f50a63          	beq	a0,a5,ffffffffc02036f0 <insert_vma_struct+0x4a>
ffffffffc02036e0:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc02036e4:	05076863          	bltu	a4,a6,ffffffffc0203734 <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc02036e8:	ff07b603          	ld	a2,-16(a5)
ffffffffc02036ec:	02c77263          	bgeu	a4,a2,ffffffffc0203710 <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc02036f0:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc02036f2:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc02036f4:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc02036f8:	e390                	sd	a2,0(a5)
ffffffffc02036fa:	e690                	sd	a2,8(a3)
}
ffffffffc02036fc:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc02036fe:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203700:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0203702:	2705                	addiw	a4,a4,1
ffffffffc0203704:	d118                	sw	a4,32(a0)
}
ffffffffc0203706:	0141                	addi	sp,sp,16
ffffffffc0203708:	8082                	ret
    if (le_prev != list)
ffffffffc020370a:	fca691e3          	bne	a3,a0,ffffffffc02036cc <insert_vma_struct+0x26>
ffffffffc020370e:	bfd9                	j	ffffffffc02036e4 <insert_vma_struct+0x3e>
ffffffffc0203710:	f03ff0ef          	jal	ffffffffc0203612 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203714:	00004697          	auipc	a3,0x4
ffffffffc0203718:	84c68693          	addi	a3,a3,-1972 # ffffffffc0206f60 <etext+0x1528>
ffffffffc020371c:	00003617          	auipc	a2,0x3
ffffffffc0203720:	d3460613          	addi	a2,a2,-716 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203724:	07a00593          	li	a1,122
ffffffffc0203728:	00004517          	auipc	a0,0x4
ffffffffc020372c:	82850513          	addi	a0,a0,-2008 # ffffffffc0206f50 <etext+0x1518>
ffffffffc0203730:	d1bfc0ef          	jal	ffffffffc020044a <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203734:	00004697          	auipc	a3,0x4
ffffffffc0203738:	86c68693          	addi	a3,a3,-1940 # ffffffffc0206fa0 <etext+0x1568>
ffffffffc020373c:	00003617          	auipc	a2,0x3
ffffffffc0203740:	d1460613          	addi	a2,a2,-748 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203744:	07300593          	li	a1,115
ffffffffc0203748:	00004517          	auipc	a0,0x4
ffffffffc020374c:	80850513          	addi	a0,a0,-2040 # ffffffffc0206f50 <etext+0x1518>
ffffffffc0203750:	cfbfc0ef          	jal	ffffffffc020044a <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203754:	00004697          	auipc	a3,0x4
ffffffffc0203758:	82c68693          	addi	a3,a3,-2004 # ffffffffc0206f80 <etext+0x1548>
ffffffffc020375c:	00003617          	auipc	a2,0x3
ffffffffc0203760:	cf460613          	addi	a2,a2,-780 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203764:	07200593          	li	a1,114
ffffffffc0203768:	00003517          	auipc	a0,0x3
ffffffffc020376c:	7e850513          	addi	a0,a0,2024 # ffffffffc0206f50 <etext+0x1518>
ffffffffc0203770:	cdbfc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0203774 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc0203774:	591c                	lw	a5,48(a0)
{
ffffffffc0203776:	1141                	addi	sp,sp,-16
ffffffffc0203778:	e406                	sd	ra,8(sp)
ffffffffc020377a:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc020377c:	e78d                	bnez	a5,ffffffffc02037a6 <mm_destroy+0x32>
ffffffffc020377e:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0203780:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc0203782:	00a40c63          	beq	s0,a0,ffffffffc020379a <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203786:	6118                	ld	a4,0(a0)
ffffffffc0203788:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc020378a:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc020378c:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020378e:	e398                	sd	a4,0(a5)
ffffffffc0203790:	d66fe0ef          	jal	ffffffffc0201cf6 <kfree>
    return listelm->next;
ffffffffc0203794:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc0203796:	fea418e3          	bne	s0,a0,ffffffffc0203786 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc020379a:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc020379c:	6402                	ld	s0,0(sp)
ffffffffc020379e:	60a2                	ld	ra,8(sp)
ffffffffc02037a0:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc02037a2:	d54fe06f          	j	ffffffffc0201cf6 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc02037a6:	00004697          	auipc	a3,0x4
ffffffffc02037aa:	81a68693          	addi	a3,a3,-2022 # ffffffffc0206fc0 <etext+0x1588>
ffffffffc02037ae:	00003617          	auipc	a2,0x3
ffffffffc02037b2:	ca260613          	addi	a2,a2,-862 # ffffffffc0206450 <etext+0xa18>
ffffffffc02037b6:	09e00593          	li	a1,158
ffffffffc02037ba:	00003517          	auipc	a0,0x3
ffffffffc02037be:	79650513          	addi	a0,a0,1942 # ffffffffc0206f50 <etext+0x1518>
ffffffffc02037c2:	c89fc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02037c6 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02037c6:	6785                	lui	a5,0x1
ffffffffc02037c8:	17fd                	addi	a5,a5,-1 # fff <_binary_obj___user_softint_out_size-0x7f69>
ffffffffc02037ca:	963e                	add	a2,a2,a5
    if (!USER_ACCESS(start, end))
ffffffffc02037cc:	4785                	li	a5,1
{
ffffffffc02037ce:	7139                	addi	sp,sp,-64
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02037d0:	962e                	add	a2,a2,a1
ffffffffc02037d2:	787d                	lui	a6,0xfffff
    if (!USER_ACCESS(start, end))
ffffffffc02037d4:	07fe                	slli	a5,a5,0x1f
{
ffffffffc02037d6:	f822                	sd	s0,48(sp)
ffffffffc02037d8:	f426                	sd	s1,40(sp)
ffffffffc02037da:	01067433          	and	s0,a2,a6
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02037de:	0105f4b3          	and	s1,a1,a6
    if (!USER_ACCESS(start, end))
ffffffffc02037e2:	0785                	addi	a5,a5,1
ffffffffc02037e4:	0084b633          	sltu	a2,s1,s0
ffffffffc02037e8:	00f437b3          	sltu	a5,s0,a5
ffffffffc02037ec:	00163613          	seqz	a2,a2
ffffffffc02037f0:	0017b793          	seqz	a5,a5
{
ffffffffc02037f4:	fc06                	sd	ra,56(sp)
    if (!USER_ACCESS(start, end))
ffffffffc02037f6:	8fd1                	or	a5,a5,a2
ffffffffc02037f8:	ebbd                	bnez	a5,ffffffffc020386e <mm_map+0xa8>
ffffffffc02037fa:	002007b7          	lui	a5,0x200
ffffffffc02037fe:	06f4e863          	bltu	s1,a5,ffffffffc020386e <mm_map+0xa8>
ffffffffc0203802:	f04a                	sd	s2,32(sp)
ffffffffc0203804:	ec4e                	sd	s3,24(sp)
ffffffffc0203806:	e852                	sd	s4,16(sp)
ffffffffc0203808:	892a                	mv	s2,a0
ffffffffc020380a:	89ba                	mv	s3,a4
ffffffffc020380c:	8a36                	mv	s4,a3
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc020380e:	c135                	beqz	a0,ffffffffc0203872 <mm_map+0xac>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203810:	85a6                	mv	a1,s1
ffffffffc0203812:	e55ff0ef          	jal	ffffffffc0203666 <find_vma>
ffffffffc0203816:	c501                	beqz	a0,ffffffffc020381e <mm_map+0x58>
ffffffffc0203818:	651c                	ld	a5,8(a0)
ffffffffc020381a:	0487e763          	bltu	a5,s0,ffffffffc0203868 <mm_map+0xa2>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020381e:	03000513          	li	a0,48
ffffffffc0203822:	c2efe0ef          	jal	ffffffffc0201c50 <kmalloc>
ffffffffc0203826:	85aa                	mv	a1,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203828:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc020382a:	c59d                	beqz	a1,ffffffffc0203858 <mm_map+0x92>
        vma->vm_start = vm_start;
ffffffffc020382c:	e584                	sd	s1,8(a1)
        vma->vm_end = vm_end;
ffffffffc020382e:	e980                	sd	s0,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0203830:	0145ac23          	sw	s4,24(a1)

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0203834:	854a                	mv	a0,s2
ffffffffc0203836:	e42e                	sd	a1,8(sp)
ffffffffc0203838:	e6fff0ef          	jal	ffffffffc02036a6 <insert_vma_struct>
    if (vma_store != NULL)
ffffffffc020383c:	65a2                	ld	a1,8(sp)
ffffffffc020383e:	00098463          	beqz	s3,ffffffffc0203846 <mm_map+0x80>
    {
        *vma_store = vma;
ffffffffc0203842:	00b9b023          	sd	a1,0(s3)
ffffffffc0203846:	7902                	ld	s2,32(sp)
ffffffffc0203848:	69e2                	ld	s3,24(sp)
ffffffffc020384a:	6a42                	ld	s4,16(sp)
    }
    ret = 0;
ffffffffc020384c:	4501                	li	a0,0

out:
    return ret;
}
ffffffffc020384e:	70e2                	ld	ra,56(sp)
ffffffffc0203850:	7442                	ld	s0,48(sp)
ffffffffc0203852:	74a2                	ld	s1,40(sp)
ffffffffc0203854:	6121                	addi	sp,sp,64
ffffffffc0203856:	8082                	ret
ffffffffc0203858:	70e2                	ld	ra,56(sp)
ffffffffc020385a:	7442                	ld	s0,48(sp)
ffffffffc020385c:	7902                	ld	s2,32(sp)
ffffffffc020385e:	69e2                	ld	s3,24(sp)
ffffffffc0203860:	6a42                	ld	s4,16(sp)
ffffffffc0203862:	74a2                	ld	s1,40(sp)
ffffffffc0203864:	6121                	addi	sp,sp,64
ffffffffc0203866:	8082                	ret
ffffffffc0203868:	7902                	ld	s2,32(sp)
ffffffffc020386a:	69e2                	ld	s3,24(sp)
ffffffffc020386c:	6a42                	ld	s4,16(sp)
        return -E_INVAL;
ffffffffc020386e:	5575                	li	a0,-3
ffffffffc0203870:	bff9                	j	ffffffffc020384e <mm_map+0x88>
    assert(mm != NULL);
ffffffffc0203872:	00003697          	auipc	a3,0x3
ffffffffc0203876:	76668693          	addi	a3,a3,1894 # ffffffffc0206fd8 <etext+0x15a0>
ffffffffc020387a:	00003617          	auipc	a2,0x3
ffffffffc020387e:	bd660613          	addi	a2,a2,-1066 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203882:	0b300593          	li	a1,179
ffffffffc0203886:	00003517          	auipc	a0,0x3
ffffffffc020388a:	6ca50513          	addi	a0,a0,1738 # ffffffffc0206f50 <etext+0x1518>
ffffffffc020388e:	bbdfc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0203892 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc0203892:	7139                	addi	sp,sp,-64
ffffffffc0203894:	fc06                	sd	ra,56(sp)
ffffffffc0203896:	f822                	sd	s0,48(sp)
ffffffffc0203898:	f426                	sd	s1,40(sp)
ffffffffc020389a:	f04a                	sd	s2,32(sp)
ffffffffc020389c:	ec4e                	sd	s3,24(sp)
ffffffffc020389e:	e852                	sd	s4,16(sp)
ffffffffc02038a0:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc02038a2:	c525                	beqz	a0,ffffffffc020390a <dup_mmap+0x78>
ffffffffc02038a4:	892a                	mv	s2,a0
ffffffffc02038a6:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc02038a8:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc02038aa:	c1a5                	beqz	a1,ffffffffc020390a <dup_mmap+0x78>
    return listelm->prev;
ffffffffc02038ac:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc02038ae:	04848c63          	beq	s1,s0,ffffffffc0203906 <dup_mmap+0x74>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02038b2:	03000513          	li	a0,48
    {
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc02038b6:	fe843a83          	ld	s5,-24(s0)
ffffffffc02038ba:	ff043a03          	ld	s4,-16(s0)
ffffffffc02038be:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02038c2:	b8efe0ef          	jal	ffffffffc0201c50 <kmalloc>
    if (vma != NULL)
ffffffffc02038c6:	c515                	beqz	a0,ffffffffc02038f2 <dup_mmap+0x60>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc02038c8:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc02038ca:	01553423          	sd	s5,8(a0)
ffffffffc02038ce:	01453823          	sd	s4,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02038d2:	01352c23          	sw	s3,24(a0)
        insert_vma_struct(to, nvma);
ffffffffc02038d6:	854a                	mv	a0,s2
ffffffffc02038d8:	dcfff0ef          	jal	ffffffffc02036a6 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc02038dc:	ff043683          	ld	a3,-16(s0)
ffffffffc02038e0:	fe843603          	ld	a2,-24(s0)
ffffffffc02038e4:	6c8c                	ld	a1,24(s1)
ffffffffc02038e6:	01893503          	ld	a0,24(s2)
ffffffffc02038ea:	4701                	li	a4,0
ffffffffc02038ec:	a45ff0ef          	jal	ffffffffc0203330 <copy_range>
ffffffffc02038f0:	dd55                	beqz	a0,ffffffffc02038ac <dup_mmap+0x1a>
            return -E_NO_MEM;
ffffffffc02038f2:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc02038f4:	70e2                	ld	ra,56(sp)
ffffffffc02038f6:	7442                	ld	s0,48(sp)
ffffffffc02038f8:	74a2                	ld	s1,40(sp)
ffffffffc02038fa:	7902                	ld	s2,32(sp)
ffffffffc02038fc:	69e2                	ld	s3,24(sp)
ffffffffc02038fe:	6a42                	ld	s4,16(sp)
ffffffffc0203900:	6aa2                	ld	s5,8(sp)
ffffffffc0203902:	6121                	addi	sp,sp,64
ffffffffc0203904:	8082                	ret
    return 0;
ffffffffc0203906:	4501                	li	a0,0
ffffffffc0203908:	b7f5                	j	ffffffffc02038f4 <dup_mmap+0x62>
    assert(to != NULL && from != NULL);
ffffffffc020390a:	00003697          	auipc	a3,0x3
ffffffffc020390e:	6de68693          	addi	a3,a3,1758 # ffffffffc0206fe8 <etext+0x15b0>
ffffffffc0203912:	00003617          	auipc	a2,0x3
ffffffffc0203916:	b3e60613          	addi	a2,a2,-1218 # ffffffffc0206450 <etext+0xa18>
ffffffffc020391a:	0cf00593          	li	a1,207
ffffffffc020391e:	00003517          	auipc	a0,0x3
ffffffffc0203922:	63250513          	addi	a0,a0,1586 # ffffffffc0206f50 <etext+0x1518>
ffffffffc0203926:	b25fc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc020392a <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc020392a:	1101                	addi	sp,sp,-32
ffffffffc020392c:	ec06                	sd	ra,24(sp)
ffffffffc020392e:	e822                	sd	s0,16(sp)
ffffffffc0203930:	e426                	sd	s1,8(sp)
ffffffffc0203932:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203934:	c531                	beqz	a0,ffffffffc0203980 <exit_mmap+0x56>
ffffffffc0203936:	591c                	lw	a5,48(a0)
ffffffffc0203938:	84aa                	mv	s1,a0
ffffffffc020393a:	e3b9                	bnez	a5,ffffffffc0203980 <exit_mmap+0x56>
    return listelm->next;
ffffffffc020393c:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc020393e:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203942:	02850663          	beq	a0,s0,ffffffffc020396e <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203946:	ff043603          	ld	a2,-16(s0)
ffffffffc020394a:	fe843583          	ld	a1,-24(s0)
ffffffffc020394e:	854a                	mv	a0,s2
ffffffffc0203950:	81dfe0ef          	jal	ffffffffc020216c <unmap_range>
ffffffffc0203954:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203956:	fe8498e3          	bne	s1,s0,ffffffffc0203946 <exit_mmap+0x1c>
ffffffffc020395a:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc020395c:	00848c63          	beq	s1,s0,ffffffffc0203974 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203960:	ff043603          	ld	a2,-16(s0)
ffffffffc0203964:	fe843583          	ld	a1,-24(s0)
ffffffffc0203968:	854a                	mv	a0,s2
ffffffffc020396a:	937fe0ef          	jal	ffffffffc02022a0 <exit_range>
ffffffffc020396e:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203970:	fe8498e3          	bne	s1,s0,ffffffffc0203960 <exit_mmap+0x36>
    }
}
ffffffffc0203974:	60e2                	ld	ra,24(sp)
ffffffffc0203976:	6442                	ld	s0,16(sp)
ffffffffc0203978:	64a2                	ld	s1,8(sp)
ffffffffc020397a:	6902                	ld	s2,0(sp)
ffffffffc020397c:	6105                	addi	sp,sp,32
ffffffffc020397e:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203980:	00003697          	auipc	a3,0x3
ffffffffc0203984:	68868693          	addi	a3,a3,1672 # ffffffffc0207008 <etext+0x15d0>
ffffffffc0203988:	00003617          	auipc	a2,0x3
ffffffffc020398c:	ac860613          	addi	a2,a2,-1336 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203990:	0e800593          	li	a1,232
ffffffffc0203994:	00003517          	auipc	a0,0x3
ffffffffc0203998:	5bc50513          	addi	a0,a0,1468 # ffffffffc0206f50 <etext+0x1518>
ffffffffc020399c:	aaffc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02039a0 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc02039a0:	7179                	addi	sp,sp,-48
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02039a2:	04000513          	li	a0,64
{
ffffffffc02039a6:	f406                	sd	ra,40(sp)
ffffffffc02039a8:	f022                	sd	s0,32(sp)
ffffffffc02039aa:	ec26                	sd	s1,24(sp)
ffffffffc02039ac:	e84a                	sd	s2,16(sp)
ffffffffc02039ae:	e44e                	sd	s3,8(sp)
ffffffffc02039b0:	e052                	sd	s4,0(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02039b2:	a9efe0ef          	jal	ffffffffc0201c50 <kmalloc>
    if (mm != NULL)
ffffffffc02039b6:	16050c63          	beqz	a0,ffffffffc0203b2e <vmm_init+0x18e>
ffffffffc02039ba:	842a                	mv	s0,a0
    elm->prev = elm->next = elm;
ffffffffc02039bc:	e508                	sd	a0,8(a0)
ffffffffc02039be:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc02039c0:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02039c4:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02039c8:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02039cc:	02053423          	sd	zero,40(a0)
ffffffffc02039d0:	02052823          	sw	zero,48(a0)
ffffffffc02039d4:	02053c23          	sd	zero,56(a0)
ffffffffc02039d8:	03200493          	li	s1,50
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02039dc:	03000513          	li	a0,48
ffffffffc02039e0:	a70fe0ef          	jal	ffffffffc0201c50 <kmalloc>
    if (vma != NULL)
ffffffffc02039e4:	12050563          	beqz	a0,ffffffffc0203b0e <vmm_init+0x16e>
        vma->vm_end = vm_end;
ffffffffc02039e8:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc02039ec:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc02039ee:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc02039f2:	e91c                	sd	a5,16(a0)
    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02039f4:	85aa                	mv	a1,a0
    for (i = step1; i >= 1; i--)
ffffffffc02039f6:	14ed                	addi	s1,s1,-5
        insert_vma_struct(mm, vma);
ffffffffc02039f8:	8522                	mv	a0,s0
ffffffffc02039fa:	cadff0ef          	jal	ffffffffc02036a6 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc02039fe:	fcf9                	bnez	s1,ffffffffc02039dc <vmm_init+0x3c>
ffffffffc0203a00:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203a04:	1f900913          	li	s2,505
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a08:	03000513          	li	a0,48
ffffffffc0203a0c:	a44fe0ef          	jal	ffffffffc0201c50 <kmalloc>
    if (vma != NULL)
ffffffffc0203a10:	12050f63          	beqz	a0,ffffffffc0203b4e <vmm_init+0x1ae>
        vma->vm_end = vm_end;
ffffffffc0203a14:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203a18:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203a1a:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0203a1e:	e91c                	sd	a5,16(a0)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203a20:	85aa                	mv	a1,a0
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203a22:	0495                	addi	s1,s1,5
        insert_vma_struct(mm, vma);
ffffffffc0203a24:	8522                	mv	a0,s0
ffffffffc0203a26:	c81ff0ef          	jal	ffffffffc02036a6 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203a2a:	fd249fe3          	bne	s1,s2,ffffffffc0203a08 <vmm_init+0x68>
    return listelm->next;
ffffffffc0203a2e:	641c                	ld	a5,8(s0)
ffffffffc0203a30:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203a32:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203a36:	1ef40c63          	beq	s0,a5,ffffffffc0203c2e <vmm_init+0x28e>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203a3a:	fe87b603          	ld	a2,-24(a5) # 1fffe8 <_binary_obj___user_matrix_out_size+0x1f4a68>
ffffffffc0203a3e:	ffe70693          	addi	a3,a4,-2
ffffffffc0203a42:	12d61663          	bne	a2,a3,ffffffffc0203b6e <vmm_init+0x1ce>
ffffffffc0203a46:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203a4a:	12e69263          	bne	a3,a4,ffffffffc0203b6e <vmm_init+0x1ce>
    for (i = 1; i <= step2; i++)
ffffffffc0203a4e:	0715                	addi	a4,a4,5
ffffffffc0203a50:	679c                	ld	a5,8(a5)
ffffffffc0203a52:	feb712e3          	bne	a4,a1,ffffffffc0203a36 <vmm_init+0x96>
ffffffffc0203a56:	491d                	li	s2,7
ffffffffc0203a58:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203a5a:	85a6                	mv	a1,s1
ffffffffc0203a5c:	8522                	mv	a0,s0
ffffffffc0203a5e:	c09ff0ef          	jal	ffffffffc0203666 <find_vma>
ffffffffc0203a62:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc0203a64:	20050563          	beqz	a0,ffffffffc0203c6e <vmm_init+0x2ce>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203a68:	00148593          	addi	a1,s1,1
ffffffffc0203a6c:	8522                	mv	a0,s0
ffffffffc0203a6e:	bf9ff0ef          	jal	ffffffffc0203666 <find_vma>
ffffffffc0203a72:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203a74:	1c050d63          	beqz	a0,ffffffffc0203c4e <vmm_init+0x2ae>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203a78:	85ca                	mv	a1,s2
ffffffffc0203a7a:	8522                	mv	a0,s0
ffffffffc0203a7c:	bebff0ef          	jal	ffffffffc0203666 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203a80:	18051763          	bnez	a0,ffffffffc0203c0e <vmm_init+0x26e>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203a84:	00348593          	addi	a1,s1,3
ffffffffc0203a88:	8522                	mv	a0,s0
ffffffffc0203a8a:	bddff0ef          	jal	ffffffffc0203666 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203a8e:	16051063          	bnez	a0,ffffffffc0203bee <vmm_init+0x24e>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203a92:	00448593          	addi	a1,s1,4
ffffffffc0203a96:	8522                	mv	a0,s0
ffffffffc0203a98:	bcfff0ef          	jal	ffffffffc0203666 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203a9c:	12051963          	bnez	a0,ffffffffc0203bce <vmm_init+0x22e>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203aa0:	008a3783          	ld	a5,8(s4)
ffffffffc0203aa4:	10979563          	bne	a5,s1,ffffffffc0203bae <vmm_init+0x20e>
ffffffffc0203aa8:	010a3783          	ld	a5,16(s4)
ffffffffc0203aac:	11279163          	bne	a5,s2,ffffffffc0203bae <vmm_init+0x20e>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203ab0:	0089b783          	ld	a5,8(s3)
ffffffffc0203ab4:	0c979d63          	bne	a5,s1,ffffffffc0203b8e <vmm_init+0x1ee>
ffffffffc0203ab8:	0109b783          	ld	a5,16(s3)
ffffffffc0203abc:	0d279963          	bne	a5,s2,ffffffffc0203b8e <vmm_init+0x1ee>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203ac0:	0495                	addi	s1,s1,5
ffffffffc0203ac2:	1f900793          	li	a5,505
ffffffffc0203ac6:	0915                	addi	s2,s2,5
ffffffffc0203ac8:	f8f499e3          	bne	s1,a5,ffffffffc0203a5a <vmm_init+0xba>
ffffffffc0203acc:	4491                	li	s1,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203ace:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203ad0:	85a6                	mv	a1,s1
ffffffffc0203ad2:	8522                	mv	a0,s0
ffffffffc0203ad4:	b93ff0ef          	jal	ffffffffc0203666 <find_vma>
        if (vma_below_5 != NULL)
ffffffffc0203ad8:	1a051b63          	bnez	a0,ffffffffc0203c8e <vmm_init+0x2ee>
    for (i = 4; i >= 0; i--)
ffffffffc0203adc:	14fd                	addi	s1,s1,-1
ffffffffc0203ade:	ff2499e3          	bne	s1,s2,ffffffffc0203ad0 <vmm_init+0x130>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
        }
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);
ffffffffc0203ae2:	8522                	mv	a0,s0
ffffffffc0203ae4:	c91ff0ef          	jal	ffffffffc0203774 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203ae8:	00003517          	auipc	a0,0x3
ffffffffc0203aec:	69050513          	addi	a0,a0,1680 # ffffffffc0207178 <etext+0x1740>
ffffffffc0203af0:	ea8fc0ef          	jal	ffffffffc0200198 <cprintf>
}
ffffffffc0203af4:	7402                	ld	s0,32(sp)
ffffffffc0203af6:	70a2                	ld	ra,40(sp)
ffffffffc0203af8:	64e2                	ld	s1,24(sp)
ffffffffc0203afa:	6942                	ld	s2,16(sp)
ffffffffc0203afc:	69a2                	ld	s3,8(sp)
ffffffffc0203afe:	6a02                	ld	s4,0(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203b00:	00003517          	auipc	a0,0x3
ffffffffc0203b04:	69850513          	addi	a0,a0,1688 # ffffffffc0207198 <etext+0x1760>
}
ffffffffc0203b08:	6145                	addi	sp,sp,48
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203b0a:	e8efc06f          	j	ffffffffc0200198 <cprintf>
        assert(vma != NULL);
ffffffffc0203b0e:	00003697          	auipc	a3,0x3
ffffffffc0203b12:	51a68693          	addi	a3,a3,1306 # ffffffffc0207028 <etext+0x15f0>
ffffffffc0203b16:	00003617          	auipc	a2,0x3
ffffffffc0203b1a:	93a60613          	addi	a2,a2,-1734 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203b1e:	12c00593          	li	a1,300
ffffffffc0203b22:	00003517          	auipc	a0,0x3
ffffffffc0203b26:	42e50513          	addi	a0,a0,1070 # ffffffffc0206f50 <etext+0x1518>
ffffffffc0203b2a:	921fc0ef          	jal	ffffffffc020044a <__panic>
    assert(mm != NULL);
ffffffffc0203b2e:	00003697          	auipc	a3,0x3
ffffffffc0203b32:	4aa68693          	addi	a3,a3,1194 # ffffffffc0206fd8 <etext+0x15a0>
ffffffffc0203b36:	00003617          	auipc	a2,0x3
ffffffffc0203b3a:	91a60613          	addi	a2,a2,-1766 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203b3e:	12400593          	li	a1,292
ffffffffc0203b42:	00003517          	auipc	a0,0x3
ffffffffc0203b46:	40e50513          	addi	a0,a0,1038 # ffffffffc0206f50 <etext+0x1518>
ffffffffc0203b4a:	901fc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma != NULL);
ffffffffc0203b4e:	00003697          	auipc	a3,0x3
ffffffffc0203b52:	4da68693          	addi	a3,a3,1242 # ffffffffc0207028 <etext+0x15f0>
ffffffffc0203b56:	00003617          	auipc	a2,0x3
ffffffffc0203b5a:	8fa60613          	addi	a2,a2,-1798 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203b5e:	13300593          	li	a1,307
ffffffffc0203b62:	00003517          	auipc	a0,0x3
ffffffffc0203b66:	3ee50513          	addi	a0,a0,1006 # ffffffffc0206f50 <etext+0x1518>
ffffffffc0203b6a:	8e1fc0ef          	jal	ffffffffc020044a <__panic>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203b6e:	00003697          	auipc	a3,0x3
ffffffffc0203b72:	4e268693          	addi	a3,a3,1250 # ffffffffc0207050 <etext+0x1618>
ffffffffc0203b76:	00003617          	auipc	a2,0x3
ffffffffc0203b7a:	8da60613          	addi	a2,a2,-1830 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203b7e:	13d00593          	li	a1,317
ffffffffc0203b82:	00003517          	auipc	a0,0x3
ffffffffc0203b86:	3ce50513          	addi	a0,a0,974 # ffffffffc0206f50 <etext+0x1518>
ffffffffc0203b8a:	8c1fc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203b8e:	00003697          	auipc	a3,0x3
ffffffffc0203b92:	57a68693          	addi	a3,a3,1402 # ffffffffc0207108 <etext+0x16d0>
ffffffffc0203b96:	00003617          	auipc	a2,0x3
ffffffffc0203b9a:	8ba60613          	addi	a2,a2,-1862 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203b9e:	14f00593          	li	a1,335
ffffffffc0203ba2:	00003517          	auipc	a0,0x3
ffffffffc0203ba6:	3ae50513          	addi	a0,a0,942 # ffffffffc0206f50 <etext+0x1518>
ffffffffc0203baa:	8a1fc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203bae:	00003697          	auipc	a3,0x3
ffffffffc0203bb2:	52a68693          	addi	a3,a3,1322 # ffffffffc02070d8 <etext+0x16a0>
ffffffffc0203bb6:	00003617          	auipc	a2,0x3
ffffffffc0203bba:	89a60613          	addi	a2,a2,-1894 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203bbe:	14e00593          	li	a1,334
ffffffffc0203bc2:	00003517          	auipc	a0,0x3
ffffffffc0203bc6:	38e50513          	addi	a0,a0,910 # ffffffffc0206f50 <etext+0x1518>
ffffffffc0203bca:	881fc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma5 == NULL);
ffffffffc0203bce:	00003697          	auipc	a3,0x3
ffffffffc0203bd2:	4fa68693          	addi	a3,a3,1274 # ffffffffc02070c8 <etext+0x1690>
ffffffffc0203bd6:	00003617          	auipc	a2,0x3
ffffffffc0203bda:	87a60613          	addi	a2,a2,-1926 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203bde:	14c00593          	li	a1,332
ffffffffc0203be2:	00003517          	auipc	a0,0x3
ffffffffc0203be6:	36e50513          	addi	a0,a0,878 # ffffffffc0206f50 <etext+0x1518>
ffffffffc0203bea:	861fc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma4 == NULL);
ffffffffc0203bee:	00003697          	auipc	a3,0x3
ffffffffc0203bf2:	4ca68693          	addi	a3,a3,1226 # ffffffffc02070b8 <etext+0x1680>
ffffffffc0203bf6:	00003617          	auipc	a2,0x3
ffffffffc0203bfa:	85a60613          	addi	a2,a2,-1958 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203bfe:	14a00593          	li	a1,330
ffffffffc0203c02:	00003517          	auipc	a0,0x3
ffffffffc0203c06:	34e50513          	addi	a0,a0,846 # ffffffffc0206f50 <etext+0x1518>
ffffffffc0203c0a:	841fc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma3 == NULL);
ffffffffc0203c0e:	00003697          	auipc	a3,0x3
ffffffffc0203c12:	49a68693          	addi	a3,a3,1178 # ffffffffc02070a8 <etext+0x1670>
ffffffffc0203c16:	00003617          	auipc	a2,0x3
ffffffffc0203c1a:	83a60613          	addi	a2,a2,-1990 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203c1e:	14800593          	li	a1,328
ffffffffc0203c22:	00003517          	auipc	a0,0x3
ffffffffc0203c26:	32e50513          	addi	a0,a0,814 # ffffffffc0206f50 <etext+0x1518>
ffffffffc0203c2a:	821fc0ef          	jal	ffffffffc020044a <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203c2e:	00003697          	auipc	a3,0x3
ffffffffc0203c32:	40a68693          	addi	a3,a3,1034 # ffffffffc0207038 <etext+0x1600>
ffffffffc0203c36:	00003617          	auipc	a2,0x3
ffffffffc0203c3a:	81a60613          	addi	a2,a2,-2022 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203c3e:	13b00593          	li	a1,315
ffffffffc0203c42:	00003517          	auipc	a0,0x3
ffffffffc0203c46:	30e50513          	addi	a0,a0,782 # ffffffffc0206f50 <etext+0x1518>
ffffffffc0203c4a:	801fc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma2 != NULL);
ffffffffc0203c4e:	00003697          	auipc	a3,0x3
ffffffffc0203c52:	44a68693          	addi	a3,a3,1098 # ffffffffc0207098 <etext+0x1660>
ffffffffc0203c56:	00002617          	auipc	a2,0x2
ffffffffc0203c5a:	7fa60613          	addi	a2,a2,2042 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203c5e:	14600593          	li	a1,326
ffffffffc0203c62:	00003517          	auipc	a0,0x3
ffffffffc0203c66:	2ee50513          	addi	a0,a0,750 # ffffffffc0206f50 <etext+0x1518>
ffffffffc0203c6a:	fe0fc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma1 != NULL);
ffffffffc0203c6e:	00003697          	auipc	a3,0x3
ffffffffc0203c72:	41a68693          	addi	a3,a3,1050 # ffffffffc0207088 <etext+0x1650>
ffffffffc0203c76:	00002617          	auipc	a2,0x2
ffffffffc0203c7a:	7da60613          	addi	a2,a2,2010 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203c7e:	14400593          	li	a1,324
ffffffffc0203c82:	00003517          	auipc	a0,0x3
ffffffffc0203c86:	2ce50513          	addi	a0,a0,718 # ffffffffc0206f50 <etext+0x1518>
ffffffffc0203c8a:	fc0fc0ef          	jal	ffffffffc020044a <__panic>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203c8e:	6914                	ld	a3,16(a0)
ffffffffc0203c90:	6510                	ld	a2,8(a0)
ffffffffc0203c92:	0004859b          	sext.w	a1,s1
ffffffffc0203c96:	00003517          	auipc	a0,0x3
ffffffffc0203c9a:	4a250513          	addi	a0,a0,1186 # ffffffffc0207138 <etext+0x1700>
ffffffffc0203c9e:	cfafc0ef          	jal	ffffffffc0200198 <cprintf>
        assert(vma_below_5 == NULL);
ffffffffc0203ca2:	00003697          	auipc	a3,0x3
ffffffffc0203ca6:	4be68693          	addi	a3,a3,1214 # ffffffffc0207160 <etext+0x1728>
ffffffffc0203caa:	00002617          	auipc	a2,0x2
ffffffffc0203cae:	7a660613          	addi	a2,a2,1958 # ffffffffc0206450 <etext+0xa18>
ffffffffc0203cb2:	15900593          	li	a1,345
ffffffffc0203cb6:	00003517          	auipc	a0,0x3
ffffffffc0203cba:	29a50513          	addi	a0,a0,666 # ffffffffc0206f50 <etext+0x1518>
ffffffffc0203cbe:	f8cfc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0203cc2 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203cc2:	7179                	addi	sp,sp,-48
ffffffffc0203cc4:	f022                	sd	s0,32(sp)
ffffffffc0203cc6:	f406                	sd	ra,40(sp)
ffffffffc0203cc8:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203cca:	c52d                	beqz	a0,ffffffffc0203d34 <user_mem_check+0x72>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203ccc:	002007b7          	lui	a5,0x200
ffffffffc0203cd0:	04f5ed63          	bltu	a1,a5,ffffffffc0203d2a <user_mem_check+0x68>
ffffffffc0203cd4:	ec26                	sd	s1,24(sp)
ffffffffc0203cd6:	00c584b3          	add	s1,a1,a2
ffffffffc0203cda:	0695ff63          	bgeu	a1,s1,ffffffffc0203d58 <user_mem_check+0x96>
ffffffffc0203cde:	4785                	li	a5,1
ffffffffc0203ce0:	07fe                	slli	a5,a5,0x1f
ffffffffc0203ce2:	0785                	addi	a5,a5,1 # 200001 <_binary_obj___user_matrix_out_size+0x1f4a81>
ffffffffc0203ce4:	06f4fa63          	bgeu	s1,a5,ffffffffc0203d58 <user_mem_check+0x96>
ffffffffc0203ce8:	e84a                	sd	s2,16(sp)
ffffffffc0203cea:	e44e                	sd	s3,8(sp)
ffffffffc0203cec:	8936                	mv	s2,a3
ffffffffc0203cee:	89aa                	mv	s3,a0
ffffffffc0203cf0:	a829                	j	ffffffffc0203d0a <user_mem_check+0x48>
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203cf2:	6685                	lui	a3,0x1
ffffffffc0203cf4:	9736                	add	a4,a4,a3
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203cf6:	0027f693          	andi	a3,a5,2
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203cfa:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203cfc:	c685                	beqz	a3,ffffffffc0203d24 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203cfe:	c399                	beqz	a5,ffffffffc0203d04 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203d00:	02e46263          	bltu	s0,a4,ffffffffc0203d24 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203d04:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203d06:	04947b63          	bgeu	s0,s1,ffffffffc0203d5c <user_mem_check+0x9a>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203d0a:	85a2                	mv	a1,s0
ffffffffc0203d0c:	854e                	mv	a0,s3
ffffffffc0203d0e:	959ff0ef          	jal	ffffffffc0203666 <find_vma>
ffffffffc0203d12:	c909                	beqz	a0,ffffffffc0203d24 <user_mem_check+0x62>
ffffffffc0203d14:	6518                	ld	a4,8(a0)
ffffffffc0203d16:	00e46763          	bltu	s0,a4,ffffffffc0203d24 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203d1a:	4d1c                	lw	a5,24(a0)
ffffffffc0203d1c:	fc091be3          	bnez	s2,ffffffffc0203cf2 <user_mem_check+0x30>
ffffffffc0203d20:	8b85                	andi	a5,a5,1
ffffffffc0203d22:	f3ed                	bnez	a5,ffffffffc0203d04 <user_mem_check+0x42>
ffffffffc0203d24:	64e2                	ld	s1,24(sp)
ffffffffc0203d26:	6942                	ld	s2,16(sp)
ffffffffc0203d28:	69a2                	ld	s3,8(sp)
            return 0;
ffffffffc0203d2a:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0203d2c:	70a2                	ld	ra,40(sp)
ffffffffc0203d2e:	7402                	ld	s0,32(sp)
ffffffffc0203d30:	6145                	addi	sp,sp,48
ffffffffc0203d32:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203d34:	c02007b7          	lui	a5,0xc0200
ffffffffc0203d38:	fef5eae3          	bltu	a1,a5,ffffffffc0203d2c <user_mem_check+0x6a>
ffffffffc0203d3c:	c80007b7          	lui	a5,0xc8000
ffffffffc0203d40:	962e                	add	a2,a2,a1
ffffffffc0203d42:	0785                	addi	a5,a5,1 # ffffffffc8000001 <end+0x7d4a521>
ffffffffc0203d44:	00c5b433          	sltu	s0,a1,a2
ffffffffc0203d48:	00f63633          	sltu	a2,a2,a5
}
ffffffffc0203d4c:	70a2                	ld	ra,40(sp)
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203d4e:	00867533          	and	a0,a2,s0
}
ffffffffc0203d52:	7402                	ld	s0,32(sp)
ffffffffc0203d54:	6145                	addi	sp,sp,48
ffffffffc0203d56:	8082                	ret
ffffffffc0203d58:	64e2                	ld	s1,24(sp)
ffffffffc0203d5a:	bfc1                	j	ffffffffc0203d2a <user_mem_check+0x68>
ffffffffc0203d5c:	64e2                	ld	s1,24(sp)
ffffffffc0203d5e:	6942                	ld	s2,16(sp)
ffffffffc0203d60:	69a2                	ld	s3,8(sp)
        return 1;
ffffffffc0203d62:	4505                	li	a0,1
ffffffffc0203d64:	b7e1                	j	ffffffffc0203d2c <user_mem_check+0x6a>

ffffffffc0203d66 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203d66:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203d68:	9402                	jalr	s0

	jal do_exit
ffffffffc0203d6a:	668000ef          	jal	ffffffffc02043d2 <do_exit>

ffffffffc0203d6e <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203d6e:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203d70:	14800513          	li	a0,328
{
ffffffffc0203d74:	e022                	sd	s0,0(sp)
ffffffffc0203d76:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203d78:	ed9fd0ef          	jal	ffffffffc0201c50 <kmalloc>
ffffffffc0203d7c:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203d7e:	c551                	beqz	a0,ffffffffc0203e0a <alloc_proc+0x9c>
    {
        /* LAB4: initialize basic fields */
        proc->state = PROC_UNINIT;
ffffffffc0203d80:	57fd                	li	a5,-1
ffffffffc0203d82:	1782                	slli	a5,a5,0x20
ffffffffc0203d84:	e11c                	sd	a5,0(a0)
        proc->pid = -1;
        proc->runs = 0;
ffffffffc0203d86:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;
ffffffffc0203d8a:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc0203d8e:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;
ffffffffc0203d92:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc0203d96:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0203d9a:	07000613          	li	a2,112
ffffffffc0203d9e:	4581                	li	a1,0
ffffffffc0203da0:	03050513          	addi	a0,a0,48
ffffffffc0203da4:	46b010ef          	jal	ffffffffc0205a0e <memset>
        proc->tf = NULL;
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203da8:	000b2797          	auipc	a5,0xb2
ffffffffc0203dac:	ce07b783          	ld	a5,-800(a5) # ffffffffc02b5a88 <boot_pgdir_pa>
        proc->tf = NULL;
ffffffffc0203db0:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;
ffffffffc0203db4:	0a042823          	sw	zero,176(s0)
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203db8:	f45c                	sd	a5,168(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);
ffffffffc0203dba:	0b440513          	addi	a0,s0,180
ffffffffc0203dbe:	4641                	li	a2,16
ffffffffc0203dc0:	4581                	li	a1,0
ffffffffc0203dc2:	44d010ef          	jal	ffffffffc0205a0e <memset>
        list_init(&proc->list_link);
ffffffffc0203dc6:	0c840693          	addi	a3,s0,200
        list_init(&proc->hash_link);
ffffffffc0203dca:	0d840713          	addi	a4,s0,216
        proc->wait_state = 0;
        proc->cptr = proc->yptr = proc->optr = NULL;

        /* LAB6: scheduling related fields */
        proc->rq = NULL;
        list_init(&proc->run_link);
ffffffffc0203dce:	11040793          	addi	a5,s0,272
        proc->exit_code = 0;
ffffffffc0203dd2:	0e043423          	sd	zero,232(s0)
        proc->cptr = proc->yptr = proc->optr = NULL;
ffffffffc0203dd6:	0e043823          	sd	zero,240(s0)
ffffffffc0203dda:	0e043c23          	sd	zero,248(s0)
ffffffffc0203dde:	10043023          	sd	zero,256(s0)
        proc->rq = NULL;
ffffffffc0203de2:	10043423          	sd	zero,264(s0)
        proc->time_slice = 0;
ffffffffc0203de6:	12042023          	sw	zero,288(s0)
     compare_f comp) __attribute__((always_inline));

static inline void
skew_heap_init(skew_heap_entry_t *a)
{
     a->left = a->right = a->parent = NULL;
ffffffffc0203dea:	12043423          	sd	zero,296(s0)
ffffffffc0203dee:	12043c23          	sd	zero,312(s0)
ffffffffc0203df2:	12043823          	sd	zero,304(s0)
        skew_heap_init(&proc->lab6_run_pool);
        proc->lab6_stride = 0;
ffffffffc0203df6:	14043023          	sd	zero,320(s0)
    elm->prev = elm->next = elm;
ffffffffc0203dfa:	e874                	sd	a3,208(s0)
ffffffffc0203dfc:	e474                	sd	a3,200(s0)
ffffffffc0203dfe:	f078                	sd	a4,224(s0)
ffffffffc0203e00:	ec78                	sd	a4,216(s0)
ffffffffc0203e02:	10f43c23          	sd	a5,280(s0)
ffffffffc0203e06:	10f43823          	sd	a5,272(s0)
        proc->lab6_priority = 0;
    }
    return proc;
}
ffffffffc0203e0a:	60a2                	ld	ra,8(sp)
ffffffffc0203e0c:	8522                	mv	a0,s0
ffffffffc0203e0e:	6402                	ld	s0,0(sp)
ffffffffc0203e10:	0141                	addi	sp,sp,16
ffffffffc0203e12:	8082                	ret

ffffffffc0203e14 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203e14:	000b2797          	auipc	a5,0xb2
ffffffffc0203e18:	ca47b783          	ld	a5,-860(a5) # ffffffffc02b5ab8 <current>
ffffffffc0203e1c:	73c8                	ld	a0,160(a5)
ffffffffc0203e1e:	8c0fd06f          	j	ffffffffc0200ede <forkrets>

ffffffffc0203e22 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203e22:	6d14                	ld	a3,24(a0)
}

// put_pgdir - free the memory space of PDT
static void
put_pgdir(struct mm_struct *mm)
{
ffffffffc0203e24:	1141                	addi	sp,sp,-16
ffffffffc0203e26:	e406                	sd	ra,8(sp)
ffffffffc0203e28:	c02007b7          	lui	a5,0xc0200
ffffffffc0203e2c:	02f6ee63          	bltu	a3,a5,ffffffffc0203e68 <put_pgdir+0x46>
ffffffffc0203e30:	000b2717          	auipc	a4,0xb2
ffffffffc0203e34:	c6873703          	ld	a4,-920(a4) # ffffffffc02b5a98 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0203e38:	000b2797          	auipc	a5,0xb2
ffffffffc0203e3c:	c687b783          	ld	a5,-920(a5) # ffffffffc02b5aa0 <npage>
    return pa2page(PADDR(kva));
ffffffffc0203e40:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc0203e42:	82b1                	srli	a3,a3,0xc
ffffffffc0203e44:	02f6fe63          	bgeu	a3,a5,ffffffffc0203e80 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203e48:	00004797          	auipc	a5,0x4
ffffffffc0203e4c:	5587b783          	ld	a5,1368(a5) # ffffffffc02083a0 <nbase>
ffffffffc0203e50:	000b2517          	auipc	a0,0xb2
ffffffffc0203e54:	c5853503          	ld	a0,-936(a0) # ffffffffc02b5aa8 <pages>
    free_page(kva2page(mm->pgdir));
}
ffffffffc0203e58:	60a2                	ld	ra,8(sp)
ffffffffc0203e5a:	8e9d                	sub	a3,a3,a5
ffffffffc0203e5c:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203e5e:	4585                	li	a1,1
ffffffffc0203e60:	9536                	add	a0,a0,a3
}
ffffffffc0203e62:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203e64:	fe9fd06f          	j	ffffffffc0201e4c <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203e68:	00003617          	auipc	a2,0x3
ffffffffc0203e6c:	a4060613          	addi	a2,a2,-1472 # ffffffffc02068a8 <etext+0xe70>
ffffffffc0203e70:	07700593          	li	a1,119
ffffffffc0203e74:	00003517          	auipc	a0,0x3
ffffffffc0203e78:	9b450513          	addi	a0,a0,-1612 # ffffffffc0206828 <etext+0xdf0>
ffffffffc0203e7c:	dcefc0ef          	jal	ffffffffc020044a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203e80:	00003617          	auipc	a2,0x3
ffffffffc0203e84:	a5060613          	addi	a2,a2,-1456 # ffffffffc02068d0 <etext+0xe98>
ffffffffc0203e88:	06900593          	li	a1,105
ffffffffc0203e8c:	00003517          	auipc	a0,0x3
ffffffffc0203e90:	99c50513          	addi	a0,a0,-1636 # ffffffffc0206828 <etext+0xdf0>
ffffffffc0203e94:	db6fc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0203e98 <proc_run>:
{
ffffffffc0203e98:	1101                	addi	sp,sp,-32
ffffffffc0203e9a:	e822                	sd	s0,16(sp)
    if (proc != current)
ffffffffc0203e9c:	000b2417          	auipc	s0,0xb2
ffffffffc0203ea0:	c1c40413          	addi	s0,s0,-996 # ffffffffc02b5ab8 <current>
ffffffffc0203ea4:	00043803          	ld	a6,0(s0)
{
ffffffffc0203ea8:	ec06                	sd	ra,24(sp)
    if (proc != current)
ffffffffc0203eaa:	06a80d63          	beq	a6,a0,ffffffffc0203f24 <proc_run+0x8c>
        cprintf("proc_run: switch from pid=%d to pid=%d, next.pgdir=0x%08x\n", prev ? prev->pid : -1, next->pid, (unsigned)next->pgdir);
ffffffffc0203eae:	55fd                	li	a1,-1
ffffffffc0203eb0:	00080463          	beqz	a6,ffffffffc0203eb8 <proc_run+0x20>
ffffffffc0203eb4:	00482583          	lw	a1,4(a6) # fffffffffffff004 <end+0x3fd49524>
ffffffffc0203eb8:	0a852683          	lw	a3,168(a0)
ffffffffc0203ebc:	4150                	lw	a2,4(a0)
ffffffffc0203ebe:	e02a                	sd	a0,0(sp)
ffffffffc0203ec0:	00003517          	auipc	a0,0x3
ffffffffc0203ec4:	2f050513          	addi	a0,a0,752 # ffffffffc02071b0 <etext+0x1778>
ffffffffc0203ec8:	e442                	sd	a6,8(sp)
ffffffffc0203eca:	acefc0ef          	jal	ffffffffc0200198 <cprintf>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203ece:	10002773          	csrr	a4,sstatus
ffffffffc0203ed2:	8b09                	andi	a4,a4,2
ffffffffc0203ed4:	6782                	ld	a5,0(sp)
ffffffffc0203ed6:	6822                	ld	a6,8(sp)
    return 0;
ffffffffc0203ed8:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203eda:	eb29                	bnez	a4,ffffffffc0203f2c <proc_run+0x94>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203edc:	77d8                	ld	a4,168(a5)
ffffffffc0203ede:	56fd                	li	a3,-1
ffffffffc0203ee0:	16fe                	slli	a3,a3,0x3f
ffffffffc0203ee2:	8331                	srli	a4,a4,0xc
ffffffffc0203ee4:	e032                	sd	a2,0(sp)
            current = proc;
ffffffffc0203ee6:	e01c                	sd	a5,0(s0)
ffffffffc0203ee8:	8f55                	or	a4,a4,a3
ffffffffc0203eea:	18071073          	csrw	satp,a4
            switch_to(&(prev->context), &(next->context));
ffffffffc0203eee:	03078593          	addi	a1,a5,48
ffffffffc0203ef2:	03080513          	addi	a0,a6,48
ffffffffc0203ef6:	1fc010ef          	jal	ffffffffc02050f2 <switch_to>
    if (flag)
ffffffffc0203efa:	6602                	ld	a2,0(sp)
ffffffffc0203efc:	ee11                	bnez	a2,ffffffffc0203f18 <proc_run+0x80>
        cprintf("proc_run: returned to pid=%d\n", current ? current->pid : -1);
ffffffffc0203efe:	601c                	ld	a5,0(s0)
ffffffffc0203f00:	55fd                	li	a1,-1
ffffffffc0203f02:	c391                	beqz	a5,ffffffffc0203f06 <proc_run+0x6e>
ffffffffc0203f04:	43cc                	lw	a1,4(a5)
} 
ffffffffc0203f06:	6442                	ld	s0,16(sp)
ffffffffc0203f08:	60e2                	ld	ra,24(sp)
        cprintf("proc_run: returned to pid=%d\n", current ? current->pid : -1);
ffffffffc0203f0a:	00003517          	auipc	a0,0x3
ffffffffc0203f0e:	2e650513          	addi	a0,a0,742 # ffffffffc02071f0 <etext+0x17b8>
} 
ffffffffc0203f12:	6105                	addi	sp,sp,32
        cprintf("proc_run: returned to pid=%d\n", current ? current->pid : -1);
ffffffffc0203f14:	a84fc06f          	j	ffffffffc0200198 <cprintf>
        intr_enable();
ffffffffc0203f18:	9e1fc0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0203f1c:	601c                	ld	a5,0(s0)
ffffffffc0203f1e:	55fd                	li	a1,-1
ffffffffc0203f20:	f3f5                	bnez	a5,ffffffffc0203f04 <proc_run+0x6c>
ffffffffc0203f22:	b7d5                	j	ffffffffc0203f06 <proc_run+0x6e>
} 
ffffffffc0203f24:	60e2                	ld	ra,24(sp)
ffffffffc0203f26:	6442                	ld	s0,16(sp)
ffffffffc0203f28:	6105                	addi	sp,sp,32
ffffffffc0203f2a:	8082                	ret
ffffffffc0203f2c:	e43e                	sd	a5,8(sp)
ffffffffc0203f2e:	e042                	sd	a6,0(sp)
        intr_disable();
ffffffffc0203f30:	9cffc0ef          	jal	ffffffffc02008fe <intr_disable>
        return 1;
ffffffffc0203f34:	67a2                	ld	a5,8(sp)
ffffffffc0203f36:	6802                	ld	a6,0(sp)
ffffffffc0203f38:	4605                	li	a2,1
ffffffffc0203f3a:	b74d                	j	ffffffffc0203edc <proc_run+0x44>

ffffffffc0203f3c <do_fork>:
 */
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf)
{
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS)
ffffffffc0203f3c:	000b2717          	auipc	a4,0xb2
ffffffffc0203f40:	b7472703          	lw	a4,-1164(a4) # ffffffffc02b5ab0 <nr_process>
ffffffffc0203f44:	6785                	lui	a5,0x1
ffffffffc0203f46:	36f75d63          	bge	a4,a5,ffffffffc02042c0 <do_fork+0x384>
{
ffffffffc0203f4a:	711d                	addi	sp,sp,-96
ffffffffc0203f4c:	e8a2                	sd	s0,80(sp)
ffffffffc0203f4e:	e4a6                	sd	s1,72(sp)
ffffffffc0203f50:	e0ca                	sd	s2,64(sp)
ffffffffc0203f52:	e06a                	sd	s10,0(sp)
ffffffffc0203f54:	ec86                	sd	ra,88(sp)
ffffffffc0203f56:	892e                	mv	s2,a1
ffffffffc0203f58:	84b2                	mv	s1,a2
ffffffffc0203f5a:	8d2a                	mv	s10,a0
    {
        goto fork_out;
    }
    ret = -E_NO_MEM;
    if ((proc = alloc_proc()) == NULL)
ffffffffc0203f5c:	e13ff0ef          	jal	ffffffffc0203d6e <alloc_proc>
ffffffffc0203f60:	842a                	mv	s0,a0
ffffffffc0203f62:	30050063          	beqz	a0,ffffffffc0204262 <do_fork+0x326>
    {
        goto fork_out;
    }
    proc->parent = current;
ffffffffc0203f66:	f05a                	sd	s6,32(sp)
ffffffffc0203f68:	000b2b17          	auipc	s6,0xb2
ffffffffc0203f6c:	b50b0b13          	addi	s6,s6,-1200 # ffffffffc02b5ab8 <current>
ffffffffc0203f70:	000b3783          	ld	a5,0(s6)
    assert(current->wait_state == 0);
ffffffffc0203f74:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_softint_out_size-0x7e7c>
    proc->parent = current;
ffffffffc0203f78:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0);
ffffffffc0203f7a:	3c071263          	bnez	a4,ffffffffc020433e <do_fork+0x402>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203f7e:	4509                	li	a0,2
ffffffffc0203f80:	e93fd0ef          	jal	ffffffffc0201e12 <alloc_pages>
    if (page != NULL)
ffffffffc0203f84:	2c050b63          	beqz	a0,ffffffffc020425a <do_fork+0x31e>
ffffffffc0203f88:	fc4e                	sd	s3,56(sp)
    return page - pages + nbase;
ffffffffc0203f8a:	000b2997          	auipc	s3,0xb2
ffffffffc0203f8e:	b1e98993          	addi	s3,s3,-1250 # ffffffffc02b5aa8 <pages>
ffffffffc0203f92:	0009b783          	ld	a5,0(s3)
ffffffffc0203f96:	f852                	sd	s4,48(sp)
ffffffffc0203f98:	00004a17          	auipc	s4,0x4
ffffffffc0203f9c:	408a0a13          	addi	s4,s4,1032 # ffffffffc02083a0 <nbase>
ffffffffc0203fa0:	e466                	sd	s9,8(sp)
ffffffffc0203fa2:	000a3c83          	ld	s9,0(s4)
ffffffffc0203fa6:	40f506b3          	sub	a3,a0,a5
ffffffffc0203faa:	f456                	sd	s5,40(sp)
    return KADDR(page2pa(page));
ffffffffc0203fac:	000b2a97          	auipc	s5,0xb2
ffffffffc0203fb0:	af4a8a93          	addi	s5,s5,-1292 # ffffffffc02b5aa0 <npage>
ffffffffc0203fb4:	e862                	sd	s8,16(sp)
    return page - pages + nbase;
ffffffffc0203fb6:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0203fb8:	5c7d                	li	s8,-1
ffffffffc0203fba:	000ab783          	ld	a5,0(s5)
    return page - pages + nbase;
ffffffffc0203fbe:	96e6                	add	a3,a3,s9
    return KADDR(page2pa(page));
ffffffffc0203fc0:	00cc5c13          	srli	s8,s8,0xc
ffffffffc0203fc4:	0186f733          	and	a4,a3,s8
ffffffffc0203fc8:	ec5e                	sd	s7,24(sp)
    return page2ppn(page) << PGSHIFT;
ffffffffc0203fca:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203fcc:	30f77863          	bgeu	a4,a5,ffffffffc02042dc <do_fork+0x3a0>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0203fd0:	000b3703          	ld	a4,0(s6)
ffffffffc0203fd4:	000b2b17          	auipc	s6,0xb2
ffffffffc0203fd8:	ac4b0b13          	addi	s6,s6,-1340 # ffffffffc02b5a98 <va_pa_offset>
ffffffffc0203fdc:	000b3783          	ld	a5,0(s6)
ffffffffc0203fe0:	02873b83          	ld	s7,40(a4)
ffffffffc0203fe4:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0203fe6:	e814                	sd	a3,16(s0)
    if (oldmm == NULL)
ffffffffc0203fe8:	020b8863          	beqz	s7,ffffffffc0204018 <do_fork+0xdc>
    if (clone_flags & CLONE_VM)
ffffffffc0203fec:	100d7793          	andi	a5,s10,256
ffffffffc0203ff0:	18078b63          	beqz	a5,ffffffffc0204186 <do_fork+0x24a>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc0203ff4:	030ba703          	lw	a4,48(s7)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203ff8:	018bb783          	ld	a5,24(s7)
ffffffffc0203ffc:	c02006b7          	lui	a3,0xc0200
ffffffffc0204000:	2705                	addiw	a4,a4,1
ffffffffc0204002:	02eba823          	sw	a4,48(s7)
    proc->mm = mm;
ffffffffc0204006:	03743423          	sd	s7,40(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020400a:	2ed7e563          	bltu	a5,a3,ffffffffc02042f4 <do_fork+0x3b8>
ffffffffc020400e:	000b3703          	ld	a4,0(s6)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204012:	6814                	ld	a3,16(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204014:	8f99                	sub	a5,a5,a4
ffffffffc0204016:	f45c                	sd	a5,168(s0)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204018:	6789                	lui	a5,0x2
ffffffffc020401a:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_softint_out_size-0x7088>
ffffffffc020401e:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0204020:	8626                	mv	a2,s1
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204022:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc0204024:	87b6                	mv	a5,a3
ffffffffc0204026:	12048713          	addi	a4,s1,288
ffffffffc020402a:	6a0c                	ld	a1,16(a2)
ffffffffc020402c:	00063803          	ld	a6,0(a2)
ffffffffc0204030:	6608                	ld	a0,8(a2)
ffffffffc0204032:	eb8c                	sd	a1,16(a5)
ffffffffc0204034:	0107b023          	sd	a6,0(a5)
ffffffffc0204038:	e788                	sd	a0,8(a5)
ffffffffc020403a:	6e0c                	ld	a1,24(a2)
ffffffffc020403c:	02060613          	addi	a2,a2,32
ffffffffc0204040:	02078793          	addi	a5,a5,32
ffffffffc0204044:	feb7bc23          	sd	a1,-8(a5)
ffffffffc0204048:	fee611e3          	bne	a2,a4,ffffffffc020402a <do_fork+0xee>
    proc->tf->gpr.a0 = 0;
ffffffffc020404c:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204050:	20090b63          	beqz	s2,ffffffffc0204266 <do_fork+0x32a>
ffffffffc0204054:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204058:	00000797          	auipc	a5,0x0
ffffffffc020405c:	dbc78793          	addi	a5,a5,-580 # ffffffffc0203e14 <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204060:	fc14                	sd	a3,56(s0)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204062:	f81c                	sd	a5,48(s0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204064:	100027f3          	csrr	a5,sstatus
ffffffffc0204068:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020406a:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020406c:	20079c63          	bnez	a5,ffffffffc0204284 <do_fork+0x348>
    if (++last_pid >= MAX_PID)
ffffffffc0204070:	000ad517          	auipc	a0,0xad
ffffffffc0204074:	58452503          	lw	a0,1412(a0) # ffffffffc02b15f4 <last_pid.1>
ffffffffc0204078:	6789                	lui	a5,0x2
ffffffffc020407a:	2505                	addiw	a0,a0,1
ffffffffc020407c:	000ad717          	auipc	a4,0xad
ffffffffc0204080:	56a72c23          	sw	a0,1400(a4) # ffffffffc02b15f4 <last_pid.1>
ffffffffc0204084:	20f55f63          	bge	a0,a5,ffffffffc02042a2 <do_fork+0x366>
    if (last_pid >= next_safe)
ffffffffc0204088:	000ad797          	auipc	a5,0xad
ffffffffc020408c:	5687a783          	lw	a5,1384(a5) # ffffffffc02b15f0 <next_safe.0>
ffffffffc0204090:	000b2497          	auipc	s1,0xb2
ffffffffc0204094:	98048493          	addi	s1,s1,-1664 # ffffffffc02b5a10 <proc_list>
ffffffffc0204098:	06f54563          	blt	a0,a5,ffffffffc0204102 <do_fork+0x1c6>
    return listelm->next;
ffffffffc020409c:	000b2497          	auipc	s1,0xb2
ffffffffc02040a0:	97448493          	addi	s1,s1,-1676 # ffffffffc02b5a10 <proc_list>
ffffffffc02040a4:	0084b883          	ld	a7,8(s1)
        next_safe = MAX_PID;
ffffffffc02040a8:	6789                	lui	a5,0x2
ffffffffc02040aa:	000ad717          	auipc	a4,0xad
ffffffffc02040ae:	54f72323          	sw	a5,1350(a4) # ffffffffc02b15f0 <next_safe.0>
ffffffffc02040b2:	86aa                	mv	a3,a0
ffffffffc02040b4:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc02040b6:	04988063          	beq	a7,s1,ffffffffc02040f6 <do_fork+0x1ba>
ffffffffc02040ba:	882e                	mv	a6,a1
ffffffffc02040bc:	87c6                	mv	a5,a7
ffffffffc02040be:	6609                	lui	a2,0x2
ffffffffc02040c0:	a811                	j	ffffffffc02040d4 <do_fork+0x198>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02040c2:	00e6d663          	bge	a3,a4,ffffffffc02040ce <do_fork+0x192>
ffffffffc02040c6:	00c75463          	bge	a4,a2,ffffffffc02040ce <do_fork+0x192>
                next_safe = proc->pid;
ffffffffc02040ca:	863a                	mv	a2,a4
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02040cc:	4805                	li	a6,1
ffffffffc02040ce:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02040d0:	00978d63          	beq	a5,s1,ffffffffc02040ea <do_fork+0x1ae>
            if (proc->pid == last_pid)
ffffffffc02040d4:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_softint_out_size-0x702c>
ffffffffc02040d8:	fed715e3          	bne	a4,a3,ffffffffc02040c2 <do_fork+0x186>
                if (++last_pid >= next_safe)
ffffffffc02040dc:	2685                	addiw	a3,a3,1
ffffffffc02040de:	1cc6db63          	bge	a3,a2,ffffffffc02042b4 <do_fork+0x378>
ffffffffc02040e2:	679c                	ld	a5,8(a5)
ffffffffc02040e4:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02040e6:	fe9797e3          	bne	a5,s1,ffffffffc02040d4 <do_fork+0x198>
ffffffffc02040ea:	00080663          	beqz	a6,ffffffffc02040f6 <do_fork+0x1ba>
ffffffffc02040ee:	000ad797          	auipc	a5,0xad
ffffffffc02040f2:	50c7a123          	sw	a2,1282(a5) # ffffffffc02b15f0 <next_safe.0>
ffffffffc02040f6:	c591                	beqz	a1,ffffffffc0204102 <do_fork+0x1c6>
ffffffffc02040f8:	000ad797          	auipc	a5,0xad
ffffffffc02040fc:	4ed7ae23          	sw	a3,1276(a5) # ffffffffc02b15f4 <last_pid.1>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204100:	8536                	mv	a0,a3
    }
    copy_thread(proc, stack, tf);
    bool intr_flag = 0;
    local_intr_save(intr_flag);
    {
        proc->pid = get_pid();
ffffffffc0204102:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204104:	45a9                	li	a1,10
ffffffffc0204106:	472010ef          	jal	ffffffffc0205578 <hash32>
ffffffffc020410a:	02051793          	slli	a5,a0,0x20
ffffffffc020410e:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204112:	000ae797          	auipc	a5,0xae
ffffffffc0204116:	8fe78793          	addi	a5,a5,-1794 # ffffffffc02b1a10 <hash_list>
ffffffffc020411a:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc020411c:	6518                	ld	a4,8(a0)
ffffffffc020411e:	0d840793          	addi	a5,s0,216
ffffffffc0204122:	6490                	ld	a2,8(s1)
    prev->next = next->prev = elm;
ffffffffc0204124:	e31c                	sd	a5,0(a4)
ffffffffc0204126:	e51c                	sd	a5,8(a0)
    elm->next = next;
ffffffffc0204128:	f078                	sd	a4,224(s0)
    list_add(&proc_list, &(proc->list_link));
ffffffffc020412a:	0c840793          	addi	a5,s0,200
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc020412e:	7018                	ld	a4,32(s0)
    elm->prev = prev;
ffffffffc0204130:	ec68                	sd	a0,216(s0)
    prev->next = next->prev = elm;
ffffffffc0204132:	e21c                	sd	a5,0(a2)
    proc->yptr = NULL;
ffffffffc0204134:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204138:	7b74                	ld	a3,240(a4)
ffffffffc020413a:	e49c                	sd	a5,8(s1)
    elm->next = next;
ffffffffc020413c:	e870                	sd	a2,208(s0)
    elm->prev = prev;
ffffffffc020413e:	e464                	sd	s1,200(s0)
ffffffffc0204140:	10d43023          	sd	a3,256(s0)
ffffffffc0204144:	c299                	beqz	a3,ffffffffc020414a <do_fork+0x20e>
        proc->optr->yptr = proc;
ffffffffc0204146:	fee0                	sd	s0,248(a3)
    proc->parent->cptr = proc;
ffffffffc0204148:	7018                	ld	a4,32(s0)
    nr_process++;
ffffffffc020414a:	000b2797          	auipc	a5,0xb2
ffffffffc020414e:	9667a783          	lw	a5,-1690(a5) # ffffffffc02b5ab0 <nr_process>
    proc->parent->cptr = proc;
ffffffffc0204152:	fb60                	sd	s0,240(a4)
    nr_process++;
ffffffffc0204154:	2785                	addiw	a5,a5,1
ffffffffc0204156:	000b2717          	auipc	a4,0xb2
ffffffffc020415a:	94f72d23          	sw	a5,-1702(a4) # ffffffffc02b5ab0 <nr_process>
    if (flag)
ffffffffc020415e:	14091863          	bnez	s2,ffffffffc02042ae <do_fork+0x372>
        hash_proc(proc);
        set_links(proc);
    }
    local_intr_restore(intr_flag);
    wakeup_proc(proc);
ffffffffc0204162:	8522                	mv	a0,s0
ffffffffc0204164:	16a010ef          	jal	ffffffffc02052ce <wakeup_proc>
    ret = proc->pid;
ffffffffc0204168:	4048                	lw	a0,4(s0)
ffffffffc020416a:	79e2                	ld	s3,56(sp)
ffffffffc020416c:	7a42                	ld	s4,48(sp)
ffffffffc020416e:	7aa2                	ld	s5,40(sp)
ffffffffc0204170:	7b02                	ld	s6,32(sp)
ffffffffc0204172:	6be2                	ld	s7,24(sp)
ffffffffc0204174:	6c42                	ld	s8,16(sp)
ffffffffc0204176:	6ca2                	ld	s9,8(sp)
bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out; 
}
ffffffffc0204178:	60e6                	ld	ra,88(sp)
ffffffffc020417a:	6446                	ld	s0,80(sp)
ffffffffc020417c:	64a6                	ld	s1,72(sp)
ffffffffc020417e:	6906                	ld	s2,64(sp)
ffffffffc0204180:	6d02                	ld	s10,0(sp)
ffffffffc0204182:	6125                	addi	sp,sp,96
ffffffffc0204184:	8082                	ret
    if ((mm = mm_create()) == NULL)
ffffffffc0204186:	cb0ff0ef          	jal	ffffffffc0203636 <mm_create>
ffffffffc020418a:	8d2a                	mv	s10,a0
ffffffffc020418c:	c949                	beqz	a0,ffffffffc020421e <do_fork+0x2e2>
    if ((page = alloc_page()) == NULL)
ffffffffc020418e:	4505                	li	a0,1
ffffffffc0204190:	c83fd0ef          	jal	ffffffffc0201e12 <alloc_pages>
ffffffffc0204194:	c151                	beqz	a0,ffffffffc0204218 <do_fork+0x2dc>
    return page - pages + nbase;
ffffffffc0204196:	0009b703          	ld	a4,0(s3)
    return KADDR(page2pa(page));
ffffffffc020419a:	000ab783          	ld	a5,0(s5)
    return page - pages + nbase;
ffffffffc020419e:	40e506b3          	sub	a3,a0,a4
ffffffffc02041a2:	8699                	srai	a3,a3,0x6
ffffffffc02041a4:	96e6                	add	a3,a3,s9
    return KADDR(page2pa(page));
ffffffffc02041a6:	0186fc33          	and	s8,a3,s8
    return page2ppn(page) << PGSHIFT;
ffffffffc02041aa:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02041ac:	1afc7f63          	bgeu	s8,a5,ffffffffc020436a <do_fork+0x42e>
ffffffffc02041b0:	000b3783          	ld	a5,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02041b4:	000b2597          	auipc	a1,0xb2
ffffffffc02041b8:	8dc5b583          	ld	a1,-1828(a1) # ffffffffc02b5a90 <boot_pgdir_va>
ffffffffc02041bc:	6605                	lui	a2,0x1
ffffffffc02041be:	00f68c33          	add	s8,a3,a5
ffffffffc02041c2:	8562                	mv	a0,s8
ffffffffc02041c4:	05d010ef          	jal	ffffffffc0205a20 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc02041c8:	038b8c93          	addi	s9,s7,56
    mm->pgdir = pgdir;
ffffffffc02041cc:	018d3c23          	sd	s8,24(s10)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02041d0:	4c05                	li	s8,1
ffffffffc02041d2:	418cb7af          	amoor.d	a5,s8,(s9)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc02041d6:	03f79713          	slli	a4,a5,0x3f
ffffffffc02041da:	03f75793          	srli	a5,a4,0x3f
ffffffffc02041de:	cb91                	beqz	a5,ffffffffc02041f2 <do_fork+0x2b6>
    {
        schedule();
ffffffffc02041e0:	1e6010ef          	jal	ffffffffc02053c6 <schedule>
ffffffffc02041e4:	418cb7af          	amoor.d	a5,s8,(s9)
    while (!try_lock(lock))
ffffffffc02041e8:	03f79713          	slli	a4,a5,0x3f
ffffffffc02041ec:	03f75793          	srli	a5,a4,0x3f
ffffffffc02041f0:	fbe5                	bnez	a5,ffffffffc02041e0 <do_fork+0x2a4>
        ret = dup_mmap(mm, oldmm);
ffffffffc02041f2:	85de                	mv	a1,s7
ffffffffc02041f4:	856a                	mv	a0,s10
ffffffffc02041f6:	e9cff0ef          	jal	ffffffffc0203892 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02041fa:	57f9                	li	a5,-2
ffffffffc02041fc:	60fcb7af          	amoand.d	a5,a5,(s9)
ffffffffc0204200:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc0204202:	12078263          	beqz	a5,ffffffffc0204326 <do_fork+0x3ea>
    if ((mm = mm_create()) == NULL)
ffffffffc0204206:	8bea                	mv	s7,s10
    if (ret != 0)
ffffffffc0204208:	de0506e3          	beqz	a0,ffffffffc0203ff4 <do_fork+0xb8>
    exit_mmap(mm);
ffffffffc020420c:	856a                	mv	a0,s10
ffffffffc020420e:	f1cff0ef          	jal	ffffffffc020392a <exit_mmap>
    put_pgdir(mm);
ffffffffc0204212:	856a                	mv	a0,s10
ffffffffc0204214:	c0fff0ef          	jal	ffffffffc0203e22 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204218:	856a                	mv	a0,s10
ffffffffc020421a:	d5aff0ef          	jal	ffffffffc0203774 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020421e:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc0204220:	c02007b7          	lui	a5,0xc0200
ffffffffc0204224:	0ef6e563          	bltu	a3,a5,ffffffffc020430e <do_fork+0x3d2>
ffffffffc0204228:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage)
ffffffffc020422c:	000ab703          	ld	a4,0(s5)
    return pa2page(PADDR(kva));
ffffffffc0204230:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204234:	83b1                	srli	a5,a5,0xc
ffffffffc0204236:	08e7f763          	bgeu	a5,a4,ffffffffc02042c4 <do_fork+0x388>
    return &pages[PPN(pa) - nbase];
ffffffffc020423a:	000a3703          	ld	a4,0(s4)
ffffffffc020423e:	0009b503          	ld	a0,0(s3)
ffffffffc0204242:	4589                	li	a1,2
ffffffffc0204244:	8f99                	sub	a5,a5,a4
ffffffffc0204246:	079a                	slli	a5,a5,0x6
ffffffffc0204248:	953e                	add	a0,a0,a5
ffffffffc020424a:	c03fd0ef          	jal	ffffffffc0201e4c <free_pages>
}
ffffffffc020424e:	79e2                	ld	s3,56(sp)
ffffffffc0204250:	7a42                	ld	s4,48(sp)
ffffffffc0204252:	7aa2                	ld	s5,40(sp)
ffffffffc0204254:	6be2                	ld	s7,24(sp)
ffffffffc0204256:	6c42                	ld	s8,16(sp)
ffffffffc0204258:	6ca2                	ld	s9,8(sp)
    kfree(proc);
ffffffffc020425a:	8522                	mv	a0,s0
ffffffffc020425c:	a9bfd0ef          	jal	ffffffffc0201cf6 <kfree>
ffffffffc0204260:	7b02                	ld	s6,32(sp)
    ret = -E_NO_MEM;
ffffffffc0204262:	5571                	li	a0,-4
    return ret;
ffffffffc0204264:	bf11                	j	ffffffffc0204178 <do_fork+0x23c>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204266:	8936                	mv	s2,a3
ffffffffc0204268:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020426c:	00000797          	auipc	a5,0x0
ffffffffc0204270:	ba878793          	addi	a5,a5,-1112 # ffffffffc0203e14 <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204274:	fc14                	sd	a3,56(s0)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204276:	f81c                	sd	a5,48(s0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204278:	100027f3          	csrr	a5,sstatus
ffffffffc020427c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020427e:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204280:	de0788e3          	beqz	a5,ffffffffc0204070 <do_fork+0x134>
        intr_disable();
ffffffffc0204284:	e7afc0ef          	jal	ffffffffc02008fe <intr_disable>
    if (++last_pid >= MAX_PID)
ffffffffc0204288:	000ad517          	auipc	a0,0xad
ffffffffc020428c:	36c52503          	lw	a0,876(a0) # ffffffffc02b15f4 <last_pid.1>
ffffffffc0204290:	6789                	lui	a5,0x2
        return 1;
ffffffffc0204292:	4905                	li	s2,1
ffffffffc0204294:	2505                	addiw	a0,a0,1
ffffffffc0204296:	000ad717          	auipc	a4,0xad
ffffffffc020429a:	34a72f23          	sw	a0,862(a4) # ffffffffc02b15f4 <last_pid.1>
ffffffffc020429e:	def545e3          	blt	a0,a5,ffffffffc0204088 <do_fork+0x14c>
        last_pid = 1;
ffffffffc02042a2:	4505                	li	a0,1
ffffffffc02042a4:	000ad797          	auipc	a5,0xad
ffffffffc02042a8:	34a7a823          	sw	a0,848(a5) # ffffffffc02b15f4 <last_pid.1>
        goto inside;
ffffffffc02042ac:	bbc5                	j	ffffffffc020409c <do_fork+0x160>
        intr_enable();
ffffffffc02042ae:	e4afc0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc02042b2:	bd45                	j	ffffffffc0204162 <do_fork+0x226>
                    if (last_pid >= MAX_PID)
ffffffffc02042b4:	6789                	lui	a5,0x2
ffffffffc02042b6:	00f6c363          	blt	a3,a5,ffffffffc02042bc <do_fork+0x380>
                        last_pid = 1;
ffffffffc02042ba:	4685                	li	a3,1
                    goto repeat;
ffffffffc02042bc:	4585                	li	a1,1
ffffffffc02042be:	bbe5                	j	ffffffffc02040b6 <do_fork+0x17a>
    int ret = -E_NO_FREE_PROC;
ffffffffc02042c0:	556d                	li	a0,-5
}
ffffffffc02042c2:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc02042c4:	00002617          	auipc	a2,0x2
ffffffffc02042c8:	60c60613          	addi	a2,a2,1548 # ffffffffc02068d0 <etext+0xe98>
ffffffffc02042cc:	06900593          	li	a1,105
ffffffffc02042d0:	00002517          	auipc	a0,0x2
ffffffffc02042d4:	55850513          	addi	a0,a0,1368 # ffffffffc0206828 <etext+0xdf0>
ffffffffc02042d8:	972fc0ef          	jal	ffffffffc020044a <__panic>
    return KADDR(page2pa(page));
ffffffffc02042dc:	00002617          	auipc	a2,0x2
ffffffffc02042e0:	52460613          	addi	a2,a2,1316 # ffffffffc0206800 <etext+0xdc8>
ffffffffc02042e4:	07100593          	li	a1,113
ffffffffc02042e8:	00002517          	auipc	a0,0x2
ffffffffc02042ec:	54050513          	addi	a0,a0,1344 # ffffffffc0206828 <etext+0xdf0>
ffffffffc02042f0:	95afc0ef          	jal	ffffffffc020044a <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02042f4:	86be                	mv	a3,a5
ffffffffc02042f6:	00002617          	auipc	a2,0x2
ffffffffc02042fa:	5b260613          	addi	a2,a2,1458 # ffffffffc02068a8 <etext+0xe70>
ffffffffc02042fe:	17b00593          	li	a1,379
ffffffffc0204302:	00003517          	auipc	a0,0x3
ffffffffc0204306:	f2e50513          	addi	a0,a0,-210 # ffffffffc0207230 <etext+0x17f8>
ffffffffc020430a:	940fc0ef          	jal	ffffffffc020044a <__panic>
    return pa2page(PADDR(kva));
ffffffffc020430e:	00002617          	auipc	a2,0x2
ffffffffc0204312:	59a60613          	addi	a2,a2,1434 # ffffffffc02068a8 <etext+0xe70>
ffffffffc0204316:	07700593          	li	a1,119
ffffffffc020431a:	00002517          	auipc	a0,0x2
ffffffffc020431e:	50e50513          	addi	a0,a0,1294 # ffffffffc0206828 <etext+0xdf0>
ffffffffc0204322:	928fc0ef          	jal	ffffffffc020044a <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc0204326:	00003617          	auipc	a2,0x3
ffffffffc020432a:	f2260613          	addi	a2,a2,-222 # ffffffffc0207248 <etext+0x1810>
ffffffffc020432e:	04000593          	li	a1,64
ffffffffc0204332:	00003517          	auipc	a0,0x3
ffffffffc0204336:	f2650513          	addi	a0,a0,-218 # ffffffffc0207258 <etext+0x1820>
ffffffffc020433a:	910fc0ef          	jal	ffffffffc020044a <__panic>
    assert(current->wait_state == 0);
ffffffffc020433e:	00003697          	auipc	a3,0x3
ffffffffc0204342:	ed268693          	addi	a3,a3,-302 # ffffffffc0207210 <etext+0x17d8>
ffffffffc0204346:	00002617          	auipc	a2,0x2
ffffffffc020434a:	10a60613          	addi	a2,a2,266 # ffffffffc0206450 <etext+0xa18>
ffffffffc020434e:	1a900593          	li	a1,425
ffffffffc0204352:	00003517          	auipc	a0,0x3
ffffffffc0204356:	ede50513          	addi	a0,a0,-290 # ffffffffc0207230 <etext+0x17f8>
ffffffffc020435a:	fc4e                	sd	s3,56(sp)
ffffffffc020435c:	f852                	sd	s4,48(sp)
ffffffffc020435e:	f456                	sd	s5,40(sp)
ffffffffc0204360:	ec5e                	sd	s7,24(sp)
ffffffffc0204362:	e862                	sd	s8,16(sp)
ffffffffc0204364:	e466                	sd	s9,8(sp)
ffffffffc0204366:	8e4fc0ef          	jal	ffffffffc020044a <__panic>
    return KADDR(page2pa(page));
ffffffffc020436a:	00002617          	auipc	a2,0x2
ffffffffc020436e:	49660613          	addi	a2,a2,1174 # ffffffffc0206800 <etext+0xdc8>
ffffffffc0204372:	07100593          	li	a1,113
ffffffffc0204376:	00002517          	auipc	a0,0x2
ffffffffc020437a:	4b250513          	addi	a0,a0,1202 # ffffffffc0206828 <etext+0xdf0>
ffffffffc020437e:	8ccfc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0204382 <kernel_thread>:
{
ffffffffc0204382:	7129                	addi	sp,sp,-320
ffffffffc0204384:	fa22                	sd	s0,304(sp)
ffffffffc0204386:	f626                	sd	s1,296(sp)
ffffffffc0204388:	f24a                	sd	s2,288(sp)
ffffffffc020438a:	842a                	mv	s0,a0
ffffffffc020438c:	84ae                	mv	s1,a1
ffffffffc020438e:	8932                	mv	s2,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204390:	850a                	mv	a0,sp
ffffffffc0204392:	12000613          	li	a2,288
ffffffffc0204396:	4581                	li	a1,0
{
ffffffffc0204398:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020439a:	674010ef          	jal	ffffffffc0205a0e <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc020439e:	e0a2                	sd	s0,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02043a0:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02043a2:	100027f3          	csrr	a5,sstatus
ffffffffc02043a6:	edd7f793          	andi	a5,a5,-291
ffffffffc02043aa:	1207e793          	ori	a5,a5,288
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02043ae:	860a                	mv	a2,sp
ffffffffc02043b0:	10096513          	ori	a0,s2,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02043b4:	00000717          	auipc	a4,0x0
ffffffffc02043b8:	9b270713          	addi	a4,a4,-1614 # ffffffffc0203d66 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02043bc:	4581                	li	a1,0
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02043be:	e23e                	sd	a5,256(sp)
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02043c0:	e63a                	sd	a4,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02043c2:	b7bff0ef          	jal	ffffffffc0203f3c <do_fork>
}
ffffffffc02043c6:	70f2                	ld	ra,312(sp)
ffffffffc02043c8:	7452                	ld	s0,304(sp)
ffffffffc02043ca:	74b2                	ld	s1,296(sp)
ffffffffc02043cc:	7912                	ld	s2,288(sp)
ffffffffc02043ce:	6131                	addi	sp,sp,320
ffffffffc02043d0:	8082                	ret

ffffffffc02043d2 <do_exit>:
// do_exit - called by sys_exit
//   1. call exit_mmap & put_pgdir & mm_destroy to free the almost all memory space of process
//   2. set process' state as PROC_ZOMBIE, then call wakeup_proc(parent) to ask parent reclaim itself.
//   3. call scheduler to switch to other process
int do_exit(int error_code)
{
ffffffffc02043d2:	7179                	addi	sp,sp,-48
ffffffffc02043d4:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc02043d6:	000b1417          	auipc	s0,0xb1
ffffffffc02043da:	6e240413          	addi	s0,s0,1762 # ffffffffc02b5ab8 <current>
ffffffffc02043de:	601c                	ld	a5,0(s0)
ffffffffc02043e0:	000b1717          	auipc	a4,0xb1
ffffffffc02043e4:	6e873703          	ld	a4,1768(a4) # ffffffffc02b5ac8 <idleproc>
{
ffffffffc02043e8:	f406                	sd	ra,40(sp)
ffffffffc02043ea:	ec26                	sd	s1,24(sp)
    if (current == idleproc)
ffffffffc02043ec:	0ce78b63          	beq	a5,a4,ffffffffc02044c2 <do_exit+0xf0>
    {
        panic("idleproc exit.\n");
    }
    if (current == initproc)
ffffffffc02043f0:	000b1497          	auipc	s1,0xb1
ffffffffc02043f4:	6d048493          	addi	s1,s1,1744 # ffffffffc02b5ac0 <initproc>
ffffffffc02043f8:	6098                	ld	a4,0(s1)
ffffffffc02043fa:	e84a                	sd	s2,16(sp)
ffffffffc02043fc:	0ee78a63          	beq	a5,a4,ffffffffc02044f0 <do_exit+0x11e>
ffffffffc0204400:	892a                	mv	s2,a0
    {
        panic("initproc exit.\n");
    }
    struct mm_struct *mm = current->mm;
ffffffffc0204402:	7788                	ld	a0,40(a5)
    if (mm != NULL)
ffffffffc0204404:	c115                	beqz	a0,ffffffffc0204428 <do_exit+0x56>
ffffffffc0204406:	000b1797          	auipc	a5,0xb1
ffffffffc020440a:	6827b783          	ld	a5,1666(a5) # ffffffffc02b5a88 <boot_pgdir_pa>
ffffffffc020440e:	577d                	li	a4,-1
ffffffffc0204410:	177e                	slli	a4,a4,0x3f
ffffffffc0204412:	83b1                	srli	a5,a5,0xc
ffffffffc0204414:	8fd9                	or	a5,a5,a4
ffffffffc0204416:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc020441a:	591c                	lw	a5,48(a0)
ffffffffc020441c:	37fd                	addiw	a5,a5,-1
ffffffffc020441e:	d91c                	sw	a5,48(a0)
    {
        lsatp(boot_pgdir_pa);
        if (mm_count_dec(mm) == 0)
ffffffffc0204420:	cfd5                	beqz	a5,ffffffffc02044dc <do_exit+0x10a>
        {
            exit_mmap(mm);
            put_pgdir(mm);
            mm_destroy(mm);
        }
        current->mm = NULL;
ffffffffc0204422:	601c                	ld	a5,0(s0)
ffffffffc0204424:	0207b423          	sd	zero,40(a5)
    }
    current->state = PROC_ZOMBIE;
ffffffffc0204428:	470d                	li	a4,3
    current->exit_code = error_code;
ffffffffc020442a:	0f27a423          	sw	s2,232(a5)
    current->state = PROC_ZOMBIE;
ffffffffc020442e:	c398                	sw	a4,0(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204430:	100027f3          	csrr	a5,sstatus
ffffffffc0204434:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204436:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204438:	ebe1                	bnez	a5,ffffffffc0204508 <do_exit+0x136>
    bool intr_flag;
    struct proc_struct *proc;
    local_intr_save(intr_flag);
    {
        proc = current->parent;
ffffffffc020443a:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc020443c:	800007b7          	lui	a5,0x80000
ffffffffc0204440:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_matrix_out_size+0xffffffff7fff4a81>
        proc = current->parent;
ffffffffc0204442:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204444:	0ec52703          	lw	a4,236(a0)
ffffffffc0204448:	0cf70463          	beq	a4,a5,ffffffffc0204510 <do_exit+0x13e>
        {
            wakeup_proc(proc);
        }
        while (current->cptr != NULL)
ffffffffc020444c:	6018                	ld	a4,0(s0)
            }
            proc->parent = initproc;
            initproc->cptr = proc;
            if (proc->state == PROC_ZOMBIE)
            {
                if (initproc->wait_state == WT_CHILD)
ffffffffc020444e:	800005b7          	lui	a1,0x80000
ffffffffc0204452:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_matrix_out_size+0xffffffff7fff4a81>
        while (current->cptr != NULL)
ffffffffc0204454:	7b7c                	ld	a5,240(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204456:	460d                	li	a2,3
        while (current->cptr != NULL)
ffffffffc0204458:	e789                	bnez	a5,ffffffffc0204462 <do_exit+0x90>
ffffffffc020445a:	a83d                	j	ffffffffc0204498 <do_exit+0xc6>
ffffffffc020445c:	6018                	ld	a4,0(s0)
ffffffffc020445e:	7b7c                	ld	a5,240(a4)
ffffffffc0204460:	cf85                	beqz	a5,ffffffffc0204498 <do_exit+0xc6>
            current->cptr = proc->optr;
ffffffffc0204462:	1007b683          	ld	a3,256(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204466:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204468:	fb74                	sd	a3,240(a4)
            proc->yptr = NULL;
ffffffffc020446a:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020446e:	7978                	ld	a4,240(a0)
ffffffffc0204470:	10e7b023          	sd	a4,256(a5)
ffffffffc0204474:	c311                	beqz	a4,ffffffffc0204478 <do_exit+0xa6>
                initproc->cptr->yptr = proc;
ffffffffc0204476:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204478:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc020447a:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc020447c:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc020447e:	fcc71fe3          	bne	a4,a2,ffffffffc020445c <do_exit+0x8a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204482:	0ec52783          	lw	a5,236(a0)
ffffffffc0204486:	fcb79be3          	bne	a5,a1,ffffffffc020445c <do_exit+0x8a>
                {
                    wakeup_proc(initproc);
ffffffffc020448a:	645000ef          	jal	ffffffffc02052ce <wakeup_proc>
ffffffffc020448e:	800005b7          	lui	a1,0x80000
ffffffffc0204492:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_matrix_out_size+0xffffffff7fff4a81>
ffffffffc0204494:	460d                	li	a2,3
ffffffffc0204496:	b7d9                	j	ffffffffc020445c <do_exit+0x8a>
    if (flag)
ffffffffc0204498:	02091263          	bnez	s2,ffffffffc02044bc <do_exit+0xea>
                }
            }
        }
    }
    local_intr_restore(intr_flag);
    schedule();
ffffffffc020449c:	72b000ef          	jal	ffffffffc02053c6 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc02044a0:	601c                	ld	a5,0(s0)
ffffffffc02044a2:	00003617          	auipc	a2,0x3
ffffffffc02044a6:	dee60613          	addi	a2,a2,-530 # ffffffffc0207290 <etext+0x1858>
ffffffffc02044aa:	20400593          	li	a1,516
ffffffffc02044ae:	43d4                	lw	a3,4(a5)
ffffffffc02044b0:	00003517          	auipc	a0,0x3
ffffffffc02044b4:	d8050513          	addi	a0,a0,-640 # ffffffffc0207230 <etext+0x17f8>
ffffffffc02044b8:	f93fb0ef          	jal	ffffffffc020044a <__panic>
        intr_enable();
ffffffffc02044bc:	c3cfc0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc02044c0:	bff1                	j	ffffffffc020449c <do_exit+0xca>
        panic("idleproc exit.\n");
ffffffffc02044c2:	00003617          	auipc	a2,0x3
ffffffffc02044c6:	dae60613          	addi	a2,a2,-594 # ffffffffc0207270 <etext+0x1838>
ffffffffc02044ca:	1d000593          	li	a1,464
ffffffffc02044ce:	00003517          	auipc	a0,0x3
ffffffffc02044d2:	d6250513          	addi	a0,a0,-670 # ffffffffc0207230 <etext+0x17f8>
ffffffffc02044d6:	e84a                	sd	s2,16(sp)
ffffffffc02044d8:	f73fb0ef          	jal	ffffffffc020044a <__panic>
            exit_mmap(mm);
ffffffffc02044dc:	e42a                	sd	a0,8(sp)
ffffffffc02044de:	c4cff0ef          	jal	ffffffffc020392a <exit_mmap>
            put_pgdir(mm);
ffffffffc02044e2:	6522                	ld	a0,8(sp)
ffffffffc02044e4:	93fff0ef          	jal	ffffffffc0203e22 <put_pgdir>
            mm_destroy(mm);
ffffffffc02044e8:	6522                	ld	a0,8(sp)
ffffffffc02044ea:	a8aff0ef          	jal	ffffffffc0203774 <mm_destroy>
ffffffffc02044ee:	bf15                	j	ffffffffc0204422 <do_exit+0x50>
        panic("initproc exit.\n");
ffffffffc02044f0:	00003617          	auipc	a2,0x3
ffffffffc02044f4:	d9060613          	addi	a2,a2,-624 # ffffffffc0207280 <etext+0x1848>
ffffffffc02044f8:	1d400593          	li	a1,468
ffffffffc02044fc:	00003517          	auipc	a0,0x3
ffffffffc0204500:	d3450513          	addi	a0,a0,-716 # ffffffffc0207230 <etext+0x17f8>
ffffffffc0204504:	f47fb0ef          	jal	ffffffffc020044a <__panic>
        intr_disable();
ffffffffc0204508:	bf6fc0ef          	jal	ffffffffc02008fe <intr_disable>
        return 1;
ffffffffc020450c:	4905                	li	s2,1
ffffffffc020450e:	b735                	j	ffffffffc020443a <do_exit+0x68>
            wakeup_proc(proc);
ffffffffc0204510:	5bf000ef          	jal	ffffffffc02052ce <wakeup_proc>
ffffffffc0204514:	bf25                	j	ffffffffc020444c <do_exit+0x7a>

ffffffffc0204516 <do_wait.part.0>:
}

// do_wait - wait one OR any children with PROC_ZOMBIE state, and free memory space of kernel stack
//         - proc struct of this child.
// NOTE: only after do_wait function, all resources of the child proces are free.
int do_wait(int pid, int *code_store)
ffffffffc0204516:	7179                	addi	sp,sp,-48
ffffffffc0204518:	ec26                	sd	s1,24(sp)
ffffffffc020451a:	e84a                	sd	s2,16(sp)
ffffffffc020451c:	e44e                	sd	s3,8(sp)
ffffffffc020451e:	f406                	sd	ra,40(sp)
ffffffffc0204520:	f022                	sd	s0,32(sp)
ffffffffc0204522:	84aa                	mv	s1,a0
ffffffffc0204524:	892e                	mv	s2,a1
ffffffffc0204526:	000b1997          	auipc	s3,0xb1
ffffffffc020452a:	59298993          	addi	s3,s3,1426 # ffffffffc02b5ab8 <current>

    struct proc_struct *proc;
    bool intr_flag, haskid;
repeat:
    haskid = 0;
    if (pid != 0)
ffffffffc020452e:	cd19                	beqz	a0,ffffffffc020454c <do_wait.part.0+0x36>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204530:	6789                	lui	a5,0x2
ffffffffc0204532:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6f6a>
ffffffffc0204534:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204538:	12e7f563          	bgeu	a5,a4,ffffffffc0204662 <do_wait.part.0+0x14c>
    }
    local_intr_restore(intr_flag);
    put_kstack(proc);
    kfree(proc);
    return 0;
}
ffffffffc020453c:	70a2                	ld	ra,40(sp)
ffffffffc020453e:	7402                	ld	s0,32(sp)
ffffffffc0204540:	64e2                	ld	s1,24(sp)
ffffffffc0204542:	6942                	ld	s2,16(sp)
ffffffffc0204544:	69a2                	ld	s3,8(sp)
    return -E_BAD_PROC;
ffffffffc0204546:	5579                	li	a0,-2
}
ffffffffc0204548:	6145                	addi	sp,sp,48
ffffffffc020454a:	8082                	ret
        proc = current->cptr;
ffffffffc020454c:	0009b703          	ld	a4,0(s3)
ffffffffc0204550:	7b60                	ld	s0,240(a4)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204552:	d46d                	beqz	s0,ffffffffc020453c <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204554:	468d                	li	a3,3
ffffffffc0204556:	a021                	j	ffffffffc020455e <do_wait.part.0+0x48>
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204558:	10043403          	ld	s0,256(s0)
ffffffffc020455c:	c075                	beqz	s0,ffffffffc0204640 <do_wait.part.0+0x12a>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020455e:	401c                	lw	a5,0(s0)
ffffffffc0204560:	fed79ce3          	bne	a5,a3,ffffffffc0204558 <do_wait.part.0+0x42>
    if (proc == idleproc || proc == initproc)
ffffffffc0204564:	000b1797          	auipc	a5,0xb1
ffffffffc0204568:	5647b783          	ld	a5,1380(a5) # ffffffffc02b5ac8 <idleproc>
ffffffffc020456c:	14878263          	beq	a5,s0,ffffffffc02046b0 <do_wait.part.0+0x19a>
ffffffffc0204570:	000b1797          	auipc	a5,0xb1
ffffffffc0204574:	5507b783          	ld	a5,1360(a5) # ffffffffc02b5ac0 <initproc>
ffffffffc0204578:	12f40c63          	beq	s0,a5,ffffffffc02046b0 <do_wait.part.0+0x19a>
    if (code_store != NULL)
ffffffffc020457c:	00090663          	beqz	s2,ffffffffc0204588 <do_wait.part.0+0x72>
        *code_store = proc->exit_code;
ffffffffc0204580:	0e842783          	lw	a5,232(s0)
ffffffffc0204584:	00f92023          	sw	a5,0(s2)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204588:	100027f3          	csrr	a5,sstatus
ffffffffc020458c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020458e:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204590:	10079963          	bnez	a5,ffffffffc02046a2 <do_wait.part.0+0x18c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204594:	6c74                	ld	a3,216(s0)
ffffffffc0204596:	7078                	ld	a4,224(s0)
    if (proc->optr != NULL)
ffffffffc0204598:	10043783          	ld	a5,256(s0)
    prev->next = next;
ffffffffc020459c:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc020459e:	e314                	sd	a3,0(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc02045a0:	6474                	ld	a3,200(s0)
ffffffffc02045a2:	6878                	ld	a4,208(s0)
    prev->next = next;
ffffffffc02045a4:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc02045a6:	e314                	sd	a3,0(a4)
ffffffffc02045a8:	c789                	beqz	a5,ffffffffc02045b2 <do_wait.part.0+0x9c>
        proc->optr->yptr = proc->yptr;
ffffffffc02045aa:	7c78                	ld	a4,248(s0)
ffffffffc02045ac:	fff8                	sd	a4,248(a5)
        proc->yptr->optr = proc->optr;
ffffffffc02045ae:	10043783          	ld	a5,256(s0)
    if (proc->yptr != NULL)
ffffffffc02045b2:	7c78                	ld	a4,248(s0)
ffffffffc02045b4:	c36d                	beqz	a4,ffffffffc0204696 <do_wait.part.0+0x180>
        proc->yptr->optr = proc->optr;
ffffffffc02045b6:	10f73023          	sd	a5,256(a4)
    nr_process--;
ffffffffc02045ba:	000b1797          	auipc	a5,0xb1
ffffffffc02045be:	4f67a783          	lw	a5,1270(a5) # ffffffffc02b5ab0 <nr_process>
ffffffffc02045c2:	37fd                	addiw	a5,a5,-1
ffffffffc02045c4:	000b1717          	auipc	a4,0xb1
ffffffffc02045c8:	4ef72623          	sw	a5,1260(a4) # ffffffffc02b5ab0 <nr_process>
    if (flag)
ffffffffc02045cc:	e271                	bnez	a2,ffffffffc0204690 <do_wait.part.0+0x17a>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02045ce:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc02045d0:	c02007b7          	lui	a5,0xc0200
ffffffffc02045d4:	10f6e663          	bltu	a3,a5,ffffffffc02046e0 <do_wait.part.0+0x1ca>
ffffffffc02045d8:	000b1717          	auipc	a4,0xb1
ffffffffc02045dc:	4c073703          	ld	a4,1216(a4) # ffffffffc02b5a98 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc02045e0:	000b1797          	auipc	a5,0xb1
ffffffffc02045e4:	4c07b783          	ld	a5,1216(a5) # ffffffffc02b5aa0 <npage>
    return pa2page(PADDR(kva));
ffffffffc02045e8:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc02045ea:	82b1                	srli	a3,a3,0xc
ffffffffc02045ec:	0cf6fe63          	bgeu	a3,a5,ffffffffc02046c8 <do_wait.part.0+0x1b2>
    return &pages[PPN(pa) - nbase];
ffffffffc02045f0:	00004797          	auipc	a5,0x4
ffffffffc02045f4:	db07b783          	ld	a5,-592(a5) # ffffffffc02083a0 <nbase>
ffffffffc02045f8:	000b1517          	auipc	a0,0xb1
ffffffffc02045fc:	4b053503          	ld	a0,1200(a0) # ffffffffc02b5aa8 <pages>
ffffffffc0204600:	4589                	li	a1,2
ffffffffc0204602:	8e9d                	sub	a3,a3,a5
ffffffffc0204604:	069a                	slli	a3,a3,0x6
ffffffffc0204606:	9536                	add	a0,a0,a3
ffffffffc0204608:	845fd0ef          	jal	ffffffffc0201e4c <free_pages>
    kfree(proc);
ffffffffc020460c:	8522                	mv	a0,s0
ffffffffc020460e:	ee8fd0ef          	jal	ffffffffc0201cf6 <kfree>
}
ffffffffc0204612:	70a2                	ld	ra,40(sp)
ffffffffc0204614:	7402                	ld	s0,32(sp)
ffffffffc0204616:	64e2                	ld	s1,24(sp)
ffffffffc0204618:	6942                	ld	s2,16(sp)
ffffffffc020461a:	69a2                	ld	s3,8(sp)
    return 0;
ffffffffc020461c:	4501                	li	a0,0
}
ffffffffc020461e:	6145                	addi	sp,sp,48
ffffffffc0204620:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc0204622:	000b1997          	auipc	s3,0xb1
ffffffffc0204626:	49698993          	addi	s3,s3,1174 # ffffffffc02b5ab8 <current>
ffffffffc020462a:	0009b703          	ld	a4,0(s3)
ffffffffc020462e:	f487b683          	ld	a3,-184(a5)
ffffffffc0204632:	f0e695e3          	bne	a3,a4,ffffffffc020453c <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204636:	f287a603          	lw	a2,-216(a5)
ffffffffc020463a:	468d                	li	a3,3
ffffffffc020463c:	06d60063          	beq	a2,a3,ffffffffc020469c <do_wait.part.0+0x186>
        current->wait_state = WT_CHILD;
ffffffffc0204640:	800007b7          	lui	a5,0x80000
ffffffffc0204644:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_matrix_out_size+0xffffffff7fff4a81>
        current->state = PROC_SLEEPING;
ffffffffc0204646:	4685                	li	a3,1
        current->wait_state = WT_CHILD;
ffffffffc0204648:	0ef72623          	sw	a5,236(a4)
        current->state = PROC_SLEEPING;
ffffffffc020464c:	c314                	sw	a3,0(a4)
        schedule();
ffffffffc020464e:	579000ef          	jal	ffffffffc02053c6 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc0204652:	0009b783          	ld	a5,0(s3)
ffffffffc0204656:	0b07a783          	lw	a5,176(a5)
ffffffffc020465a:	8b85                	andi	a5,a5,1
ffffffffc020465c:	e7b9                	bnez	a5,ffffffffc02046aa <do_wait.part.0+0x194>
    if (pid != 0)
ffffffffc020465e:	ee0487e3          	beqz	s1,ffffffffc020454c <do_wait.part.0+0x36>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204662:	45a9                	li	a1,10
ffffffffc0204664:	8526                	mv	a0,s1
ffffffffc0204666:	713000ef          	jal	ffffffffc0205578 <hash32>
ffffffffc020466a:	02051793          	slli	a5,a0,0x20
ffffffffc020466e:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204672:	000ad797          	auipc	a5,0xad
ffffffffc0204676:	39e78793          	addi	a5,a5,926 # ffffffffc02b1a10 <hash_list>
ffffffffc020467a:	953e                	add	a0,a0,a5
ffffffffc020467c:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc020467e:	a029                	j	ffffffffc0204688 <do_wait.part.0+0x172>
            if (proc->pid == pid)
ffffffffc0204680:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204684:	f8970fe3          	beq	a4,s1,ffffffffc0204622 <do_wait.part.0+0x10c>
    return listelm->next;
ffffffffc0204688:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc020468a:	fef51be3          	bne	a0,a5,ffffffffc0204680 <do_wait.part.0+0x16a>
ffffffffc020468e:	b57d                	j	ffffffffc020453c <do_wait.part.0+0x26>
        intr_enable();
ffffffffc0204690:	a68fc0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0204694:	bf2d                	j	ffffffffc02045ce <do_wait.part.0+0xb8>
        proc->parent->cptr = proc->optr;
ffffffffc0204696:	7018                	ld	a4,32(s0)
ffffffffc0204698:	fb7c                	sd	a5,240(a4)
ffffffffc020469a:	b705                	j	ffffffffc02045ba <do_wait.part.0+0xa4>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020469c:	f2878413          	addi	s0,a5,-216
ffffffffc02046a0:	b5d1                	j	ffffffffc0204564 <do_wait.part.0+0x4e>
        intr_disable();
ffffffffc02046a2:	a5cfc0ef          	jal	ffffffffc02008fe <intr_disable>
        return 1;
ffffffffc02046a6:	4605                	li	a2,1
ffffffffc02046a8:	b5f5                	j	ffffffffc0204594 <do_wait.part.0+0x7e>
            do_exit(-E_KILLED);
ffffffffc02046aa:	555d                	li	a0,-9
ffffffffc02046ac:	d27ff0ef          	jal	ffffffffc02043d2 <do_exit>
        panic("wait idleproc or initproc.\n");
ffffffffc02046b0:	00003617          	auipc	a2,0x3
ffffffffc02046b4:	c0060613          	addi	a2,a2,-1024 # ffffffffc02072b0 <etext+0x1878>
ffffffffc02046b8:	31f00593          	li	a1,799
ffffffffc02046bc:	00003517          	auipc	a0,0x3
ffffffffc02046c0:	b7450513          	addi	a0,a0,-1164 # ffffffffc0207230 <etext+0x17f8>
ffffffffc02046c4:	d87fb0ef          	jal	ffffffffc020044a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02046c8:	00002617          	auipc	a2,0x2
ffffffffc02046cc:	20860613          	addi	a2,a2,520 # ffffffffc02068d0 <etext+0xe98>
ffffffffc02046d0:	06900593          	li	a1,105
ffffffffc02046d4:	00002517          	auipc	a0,0x2
ffffffffc02046d8:	15450513          	addi	a0,a0,340 # ffffffffc0206828 <etext+0xdf0>
ffffffffc02046dc:	d6ffb0ef          	jal	ffffffffc020044a <__panic>
    return pa2page(PADDR(kva));
ffffffffc02046e0:	00002617          	auipc	a2,0x2
ffffffffc02046e4:	1c860613          	addi	a2,a2,456 # ffffffffc02068a8 <etext+0xe70>
ffffffffc02046e8:	07700593          	li	a1,119
ffffffffc02046ec:	00002517          	auipc	a0,0x2
ffffffffc02046f0:	13c50513          	addi	a0,a0,316 # ffffffffc0206828 <etext+0xdf0>
ffffffffc02046f4:	d57fb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02046f8 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02046f8:	1141                	addi	sp,sp,-16
ffffffffc02046fa:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02046fc:	f88fd0ef          	jal	ffffffffc0201e84 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc0204700:	d4cfd0ef          	jal	ffffffffc0201c4c <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc0204704:	4601                	li	a2,0
ffffffffc0204706:	4581                	li	a1,0
ffffffffc0204708:	00000517          	auipc	a0,0x0
ffffffffc020470c:	6b050513          	addi	a0,a0,1712 # ffffffffc0204db8 <user_main>
ffffffffc0204710:	c73ff0ef          	jal	ffffffffc0204382 <kernel_thread>
    if (pid <= 0)
ffffffffc0204714:	00a04563          	bgtz	a0,ffffffffc020471e <init_main+0x26>
ffffffffc0204718:	a071                	j	ffffffffc02047a4 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc020471a:	4ad000ef          	jal	ffffffffc02053c6 <schedule>
    if (code_store != NULL)
ffffffffc020471e:	4581                	li	a1,0
ffffffffc0204720:	4501                	li	a0,0
ffffffffc0204722:	df5ff0ef          	jal	ffffffffc0204516 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc0204726:	d975                	beqz	a0,ffffffffc020471a <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0204728:	00003517          	auipc	a0,0x3
ffffffffc020472c:	bc850513          	addi	a0,a0,-1080 # ffffffffc02072f0 <etext+0x18b8>
ffffffffc0204730:	a69fb0ef          	jal	ffffffffc0200198 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204734:	000b1797          	auipc	a5,0xb1
ffffffffc0204738:	38c7b783          	ld	a5,908(a5) # ffffffffc02b5ac0 <initproc>
ffffffffc020473c:	7bf8                	ld	a4,240(a5)
ffffffffc020473e:	e339                	bnez	a4,ffffffffc0204784 <init_main+0x8c>
ffffffffc0204740:	7ff8                	ld	a4,248(a5)
ffffffffc0204742:	e329                	bnez	a4,ffffffffc0204784 <init_main+0x8c>
ffffffffc0204744:	1007b703          	ld	a4,256(a5)
ffffffffc0204748:	ef15                	bnez	a4,ffffffffc0204784 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc020474a:	000b1697          	auipc	a3,0xb1
ffffffffc020474e:	3666a683          	lw	a3,870(a3) # ffffffffc02b5ab0 <nr_process>
ffffffffc0204752:	4709                	li	a4,2
ffffffffc0204754:	0ae69463          	bne	a3,a4,ffffffffc02047fc <init_main+0x104>
ffffffffc0204758:	000b1697          	auipc	a3,0xb1
ffffffffc020475c:	2b868693          	addi	a3,a3,696 # ffffffffc02b5a10 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204760:	6698                	ld	a4,8(a3)
ffffffffc0204762:	0c878793          	addi	a5,a5,200
ffffffffc0204766:	06f71b63          	bne	a4,a5,ffffffffc02047dc <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020476a:	629c                	ld	a5,0(a3)
ffffffffc020476c:	04f71863          	bne	a4,a5,ffffffffc02047bc <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204770:	00003517          	auipc	a0,0x3
ffffffffc0204774:	c6850513          	addi	a0,a0,-920 # ffffffffc02073d8 <etext+0x19a0>
ffffffffc0204778:	a21fb0ef          	jal	ffffffffc0200198 <cprintf>
    return 0;
}
ffffffffc020477c:	60a2                	ld	ra,8(sp)
ffffffffc020477e:	4501                	li	a0,0
ffffffffc0204780:	0141                	addi	sp,sp,16
ffffffffc0204782:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204784:	00003697          	auipc	a3,0x3
ffffffffc0204788:	b9468693          	addi	a3,a3,-1132 # ffffffffc0207318 <etext+0x18e0>
ffffffffc020478c:	00002617          	auipc	a2,0x2
ffffffffc0204790:	cc460613          	addi	a2,a2,-828 # ffffffffc0206450 <etext+0xa18>
ffffffffc0204794:	38b00593          	li	a1,907
ffffffffc0204798:	00003517          	auipc	a0,0x3
ffffffffc020479c:	a9850513          	addi	a0,a0,-1384 # ffffffffc0207230 <etext+0x17f8>
ffffffffc02047a0:	cabfb0ef          	jal	ffffffffc020044a <__panic>
        panic("create user_main failed.\n");
ffffffffc02047a4:	00003617          	auipc	a2,0x3
ffffffffc02047a8:	b2c60613          	addi	a2,a2,-1236 # ffffffffc02072d0 <etext+0x1898>
ffffffffc02047ac:	38200593          	li	a1,898
ffffffffc02047b0:	00003517          	auipc	a0,0x3
ffffffffc02047b4:	a8050513          	addi	a0,a0,-1408 # ffffffffc0207230 <etext+0x17f8>
ffffffffc02047b8:	c93fb0ef          	jal	ffffffffc020044a <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02047bc:	00003697          	auipc	a3,0x3
ffffffffc02047c0:	bec68693          	addi	a3,a3,-1044 # ffffffffc02073a8 <etext+0x1970>
ffffffffc02047c4:	00002617          	auipc	a2,0x2
ffffffffc02047c8:	c8c60613          	addi	a2,a2,-884 # ffffffffc0206450 <etext+0xa18>
ffffffffc02047cc:	38e00593          	li	a1,910
ffffffffc02047d0:	00003517          	auipc	a0,0x3
ffffffffc02047d4:	a6050513          	addi	a0,a0,-1440 # ffffffffc0207230 <etext+0x17f8>
ffffffffc02047d8:	c73fb0ef          	jal	ffffffffc020044a <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02047dc:	00003697          	auipc	a3,0x3
ffffffffc02047e0:	b9c68693          	addi	a3,a3,-1124 # ffffffffc0207378 <etext+0x1940>
ffffffffc02047e4:	00002617          	auipc	a2,0x2
ffffffffc02047e8:	c6c60613          	addi	a2,a2,-916 # ffffffffc0206450 <etext+0xa18>
ffffffffc02047ec:	38d00593          	li	a1,909
ffffffffc02047f0:	00003517          	auipc	a0,0x3
ffffffffc02047f4:	a4050513          	addi	a0,a0,-1472 # ffffffffc0207230 <etext+0x17f8>
ffffffffc02047f8:	c53fb0ef          	jal	ffffffffc020044a <__panic>
    assert(nr_process == 2);
ffffffffc02047fc:	00003697          	auipc	a3,0x3
ffffffffc0204800:	b6c68693          	addi	a3,a3,-1172 # ffffffffc0207368 <etext+0x1930>
ffffffffc0204804:	00002617          	auipc	a2,0x2
ffffffffc0204808:	c4c60613          	addi	a2,a2,-948 # ffffffffc0206450 <etext+0xa18>
ffffffffc020480c:	38c00593          	li	a1,908
ffffffffc0204810:	00003517          	auipc	a0,0x3
ffffffffc0204814:	a2050513          	addi	a0,a0,-1504 # ffffffffc0207230 <etext+0x17f8>
ffffffffc0204818:	c33fb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc020481c <do_execve>:
{
ffffffffc020481c:	7171                	addi	sp,sp,-176
ffffffffc020481e:	e8ea                	sd	s10,80(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204820:	000b1d17          	auipc	s10,0xb1
ffffffffc0204824:	298d0d13          	addi	s10,s10,664 # ffffffffc02b5ab8 <current>
ffffffffc0204828:	000d3783          	ld	a5,0(s10)
{
ffffffffc020482c:	e94a                	sd	s2,144(sp)
ffffffffc020482e:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204830:	0287b903          	ld	s2,40(a5)
{
ffffffffc0204834:	84ae                	mv	s1,a1
ffffffffc0204836:	e54e                	sd	s3,136(sp)
ffffffffc0204838:	ec32                	sd	a2,24(sp)
ffffffffc020483a:	89aa                	mv	s3,a0
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc020483c:	85aa                	mv	a1,a0
ffffffffc020483e:	8626                	mv	a2,s1
ffffffffc0204840:	854a                	mv	a0,s2
ffffffffc0204842:	4681                	li	a3,0
{
ffffffffc0204844:	f506                	sd	ra,168(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204846:	c7cff0ef          	jal	ffffffffc0203cc2 <user_mem_check>
ffffffffc020484a:	46050f63          	beqz	a0,ffffffffc0204cc8 <do_execve+0x4ac>
    memset(local_name, 0, sizeof(local_name));
ffffffffc020484e:	4641                	li	a2,16
ffffffffc0204850:	1808                	addi	a0,sp,48
ffffffffc0204852:	4581                	li	a1,0
ffffffffc0204854:	1ba010ef          	jal	ffffffffc0205a0e <memset>
    if (len > PROC_NAME_LEN)
ffffffffc0204858:	47bd                	li	a5,15
ffffffffc020485a:	8626                	mv	a2,s1
ffffffffc020485c:	0e97ef63          	bltu	a5,s1,ffffffffc020495a <do_execve+0x13e>
    memcpy(local_name, name, len);
ffffffffc0204860:	85ce                	mv	a1,s3
ffffffffc0204862:	1808                	addi	a0,sp,48
ffffffffc0204864:	1bc010ef          	jal	ffffffffc0205a20 <memcpy>
    if (mm != NULL)
ffffffffc0204868:	10090063          	beqz	s2,ffffffffc0204968 <do_execve+0x14c>
        cputs("mm != NULL");
ffffffffc020486c:	00002517          	auipc	a0,0x2
ffffffffc0204870:	76c50513          	addi	a0,a0,1900 # ffffffffc0206fd8 <etext+0x15a0>
ffffffffc0204874:	95bfb0ef          	jal	ffffffffc02001ce <cputs>
ffffffffc0204878:	000b1797          	auipc	a5,0xb1
ffffffffc020487c:	2107b783          	ld	a5,528(a5) # ffffffffc02b5a88 <boot_pgdir_pa>
ffffffffc0204880:	577d                	li	a4,-1
ffffffffc0204882:	177e                	slli	a4,a4,0x3f
ffffffffc0204884:	83b1                	srli	a5,a5,0xc
ffffffffc0204886:	8fd9                	or	a5,a5,a4
ffffffffc0204888:	18079073          	csrw	satp,a5
ffffffffc020488c:	03092783          	lw	a5,48(s2)
ffffffffc0204890:	37fd                	addiw	a5,a5,-1
ffffffffc0204892:	02f92823          	sw	a5,48(s2)
        if (mm_count_dec(mm) == 0)
ffffffffc0204896:	30078563          	beqz	a5,ffffffffc0204ba0 <do_execve+0x384>
        current->mm = NULL;
ffffffffc020489a:	000d3783          	ld	a5,0(s10)
ffffffffc020489e:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc02048a2:	d95fe0ef          	jal	ffffffffc0203636 <mm_create>
ffffffffc02048a6:	892a                	mv	s2,a0
ffffffffc02048a8:	22050063          	beqz	a0,ffffffffc0204ac8 <do_execve+0x2ac>
    if ((page = alloc_page()) == NULL)
ffffffffc02048ac:	4505                	li	a0,1
ffffffffc02048ae:	d64fd0ef          	jal	ffffffffc0201e12 <alloc_pages>
ffffffffc02048b2:	42050063          	beqz	a0,ffffffffc0204cd2 <do_execve+0x4b6>
    return page - pages + nbase;
ffffffffc02048b6:	f0e2                	sd	s8,96(sp)
ffffffffc02048b8:	000b1c17          	auipc	s8,0xb1
ffffffffc02048bc:	1f0c0c13          	addi	s8,s8,496 # ffffffffc02b5aa8 <pages>
ffffffffc02048c0:	000c3783          	ld	a5,0(s8)
ffffffffc02048c4:	f4de                	sd	s7,104(sp)
ffffffffc02048c6:	00004b97          	auipc	s7,0x4
ffffffffc02048ca:	adabbb83          	ld	s7,-1318(s7) # ffffffffc02083a0 <nbase>
ffffffffc02048ce:	40f506b3          	sub	a3,a0,a5
ffffffffc02048d2:	ece6                	sd	s9,88(sp)
    return KADDR(page2pa(page));
ffffffffc02048d4:	000b1c97          	auipc	s9,0xb1
ffffffffc02048d8:	1ccc8c93          	addi	s9,s9,460 # ffffffffc02b5aa0 <npage>
ffffffffc02048dc:	f8da                	sd	s6,112(sp)
    return page - pages + nbase;
ffffffffc02048de:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02048e0:	5b7d                	li	s6,-1
ffffffffc02048e2:	000cb783          	ld	a5,0(s9)
    return page - pages + nbase;
ffffffffc02048e6:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc02048e8:	00cb5713          	srli	a4,s6,0xc
ffffffffc02048ec:	e83a                	sd	a4,16(sp)
ffffffffc02048ee:	fcd6                	sd	s5,120(sp)
ffffffffc02048f0:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02048f2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02048f4:	40f77263          	bgeu	a4,a5,ffffffffc0204cf8 <do_execve+0x4dc>
ffffffffc02048f8:	000b1a97          	auipc	s5,0xb1
ffffffffc02048fc:	1a0a8a93          	addi	s5,s5,416 # ffffffffc02b5a98 <va_pa_offset>
ffffffffc0204900:	000ab783          	ld	a5,0(s5)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204904:	000b1597          	auipc	a1,0xb1
ffffffffc0204908:	18c5b583          	ld	a1,396(a1) # ffffffffc02b5a90 <boot_pgdir_va>
ffffffffc020490c:	6605                	lui	a2,0x1
ffffffffc020490e:	00f684b3          	add	s1,a3,a5
ffffffffc0204912:	8526                	mv	a0,s1
ffffffffc0204914:	10c010ef          	jal	ffffffffc0205a20 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204918:	66e2                	ld	a3,24(sp)
ffffffffc020491a:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc020491e:	00993c23          	sd	s1,24(s2)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204922:	4298                	lw	a4,0(a3)
ffffffffc0204924:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_matrix_out_size+0x464b8fff>
ffffffffc0204928:	06f70863          	beq	a4,a5,ffffffffc0204998 <do_execve+0x17c>
        ret = -E_INVAL_ELF;
ffffffffc020492c:	54e1                	li	s1,-8
    put_pgdir(mm);
ffffffffc020492e:	854a                	mv	a0,s2
ffffffffc0204930:	cf2ff0ef          	jal	ffffffffc0203e22 <put_pgdir>
ffffffffc0204934:	7ae6                	ld	s5,120(sp)
ffffffffc0204936:	7b46                	ld	s6,112(sp)
ffffffffc0204938:	7ba6                	ld	s7,104(sp)
ffffffffc020493a:	7c06                	ld	s8,96(sp)
ffffffffc020493c:	6ce6                	ld	s9,88(sp)
    mm_destroy(mm);
ffffffffc020493e:	854a                	mv	a0,s2
ffffffffc0204940:	e35fe0ef          	jal	ffffffffc0203774 <mm_destroy>
    do_exit(ret);
ffffffffc0204944:	8526                	mv	a0,s1
ffffffffc0204946:	f122                	sd	s0,160(sp)
ffffffffc0204948:	e152                	sd	s4,128(sp)
ffffffffc020494a:	fcd6                	sd	s5,120(sp)
ffffffffc020494c:	f8da                	sd	s6,112(sp)
ffffffffc020494e:	f4de                	sd	s7,104(sp)
ffffffffc0204950:	f0e2                	sd	s8,96(sp)
ffffffffc0204952:	ece6                	sd	s9,88(sp)
ffffffffc0204954:	e4ee                	sd	s11,72(sp)
ffffffffc0204956:	a7dff0ef          	jal	ffffffffc02043d2 <do_exit>
    if (len > PROC_NAME_LEN)
ffffffffc020495a:	863e                	mv	a2,a5
    memcpy(local_name, name, len);
ffffffffc020495c:	85ce                	mv	a1,s3
ffffffffc020495e:	1808                	addi	a0,sp,48
ffffffffc0204960:	0c0010ef          	jal	ffffffffc0205a20 <memcpy>
    if (mm != NULL)
ffffffffc0204964:	f00914e3          	bnez	s2,ffffffffc020486c <do_execve+0x50>
    if (current->mm != NULL)
ffffffffc0204968:	000d3783          	ld	a5,0(s10)
ffffffffc020496c:	779c                	ld	a5,40(a5)
ffffffffc020496e:	db95                	beqz	a5,ffffffffc02048a2 <do_execve+0x86>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204970:	00003617          	auipc	a2,0x3
ffffffffc0204974:	a8860613          	addi	a2,a2,-1400 # ffffffffc02073f8 <etext+0x19c0>
ffffffffc0204978:	21000593          	li	a1,528
ffffffffc020497c:	00003517          	auipc	a0,0x3
ffffffffc0204980:	8b450513          	addi	a0,a0,-1868 # ffffffffc0207230 <etext+0x17f8>
ffffffffc0204984:	f122                	sd	s0,160(sp)
ffffffffc0204986:	e152                	sd	s4,128(sp)
ffffffffc0204988:	fcd6                	sd	s5,120(sp)
ffffffffc020498a:	f8da                	sd	s6,112(sp)
ffffffffc020498c:	f4de                	sd	s7,104(sp)
ffffffffc020498e:	f0e2                	sd	s8,96(sp)
ffffffffc0204990:	ece6                	sd	s9,88(sp)
ffffffffc0204992:	e4ee                	sd	s11,72(sp)
ffffffffc0204994:	ab7fb0ef          	jal	ffffffffc020044a <__panic>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204998:	0386d703          	lhu	a4,56(a3)
ffffffffc020499c:	e152                	sd	s4,128(sp)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc020499e:	0206ba03          	ld	s4,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02049a2:	00371793          	slli	a5,a4,0x3
ffffffffc02049a6:	8f99                	sub	a5,a5,a4
ffffffffc02049a8:	078e                	slli	a5,a5,0x3
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02049aa:	9a36                	add	s4,s4,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02049ac:	97d2                	add	a5,a5,s4
ffffffffc02049ae:	f122                	sd	s0,160(sp)
ffffffffc02049b0:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc02049b2:	00fa7e63          	bgeu	s4,a5,ffffffffc02049ce <do_execve+0x1b2>
ffffffffc02049b6:	e4ee                	sd	s11,72(sp)
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc02049b8:	000a2783          	lw	a5,0(s4)
ffffffffc02049bc:	4705                	li	a4,1
ffffffffc02049be:	10e78763          	beq	a5,a4,ffffffffc0204acc <do_execve+0x2b0>
    for (; ph < ph_end; ph++)
ffffffffc02049c2:	77a2                	ld	a5,40(sp)
ffffffffc02049c4:	038a0a13          	addi	s4,s4,56
ffffffffc02049c8:	fefa68e3          	bltu	s4,a5,ffffffffc02049b8 <do_execve+0x19c>
ffffffffc02049cc:	6da6                	ld	s11,72(sp)
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc02049ce:	4701                	li	a4,0
ffffffffc02049d0:	46ad                	li	a3,11
ffffffffc02049d2:	00100637          	lui	a2,0x100
ffffffffc02049d6:	7ff005b7          	lui	a1,0x7ff00
ffffffffc02049da:	854a                	mv	a0,s2
ffffffffc02049dc:	debfe0ef          	jal	ffffffffc02037c6 <mm_map>
ffffffffc02049e0:	84aa                	mv	s1,a0
ffffffffc02049e2:	1a051963          	bnez	a0,ffffffffc0204b94 <do_execve+0x378>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc02049e6:	01893503          	ld	a0,24(s2)
ffffffffc02049ea:	467d                	li	a2,31
ffffffffc02049ec:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc02049f0:	b65fe0ef          	jal	ffffffffc0203554 <pgdir_alloc_page>
ffffffffc02049f4:	3a050163          	beqz	a0,ffffffffc0204d96 <do_execve+0x57a>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc02049f8:	01893503          	ld	a0,24(s2)
ffffffffc02049fc:	467d                	li	a2,31
ffffffffc02049fe:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204a02:	b53fe0ef          	jal	ffffffffc0203554 <pgdir_alloc_page>
ffffffffc0204a06:	36050763          	beqz	a0,ffffffffc0204d74 <do_execve+0x558>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204a0a:	01893503          	ld	a0,24(s2)
ffffffffc0204a0e:	467d                	li	a2,31
ffffffffc0204a10:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204a14:	b41fe0ef          	jal	ffffffffc0203554 <pgdir_alloc_page>
ffffffffc0204a18:	32050d63          	beqz	a0,ffffffffc0204d52 <do_execve+0x536>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204a1c:	01893503          	ld	a0,24(s2)
ffffffffc0204a20:	467d                	li	a2,31
ffffffffc0204a22:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204a26:	b2ffe0ef          	jal	ffffffffc0203554 <pgdir_alloc_page>
ffffffffc0204a2a:	30050363          	beqz	a0,ffffffffc0204d30 <do_execve+0x514>
    mm->mm_count += 1;
ffffffffc0204a2e:	03092783          	lw	a5,48(s2)
    current->mm = mm;
ffffffffc0204a32:	000d3603          	ld	a2,0(s10)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204a36:	01893683          	ld	a3,24(s2)
ffffffffc0204a3a:	2785                	addiw	a5,a5,1
ffffffffc0204a3c:	02f92823          	sw	a5,48(s2)
    current->mm = mm;
ffffffffc0204a40:	03263423          	sd	s2,40(a2) # 100028 <_binary_obj___user_matrix_out_size+0xf4aa8>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204a44:	c02007b7          	lui	a5,0xc0200
ffffffffc0204a48:	2cf6e763          	bltu	a3,a5,ffffffffc0204d16 <do_execve+0x4fa>
ffffffffc0204a4c:	000ab783          	ld	a5,0(s5)
ffffffffc0204a50:	577d                	li	a4,-1
ffffffffc0204a52:	177e                	slli	a4,a4,0x3f
ffffffffc0204a54:	8e9d                	sub	a3,a3,a5
ffffffffc0204a56:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204a5a:	f654                	sd	a3,168(a2)
ffffffffc0204a5c:	8fd9                	or	a5,a5,a4
ffffffffc0204a5e:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204a62:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204a64:	4581                	li	a1,0
ffffffffc0204a66:	12000613          	li	a2,288
ffffffffc0204a6a:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0204a6c:	10043903          	ld	s2,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204a70:	79f000ef          	jal	ffffffffc0205a0e <memset>
    tf->epc = elf->e_entry;
ffffffffc0204a74:	67e2                	ld	a5,24(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204a76:	000d3983          	ld	s3,0(s10)
    tf->status = sstatus & ~SSTATUS_SPP;
ffffffffc0204a7a:	eff97913          	andi	s2,s2,-257
    tf->epc = elf->e_entry;
ffffffffc0204a7e:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204a80:	4785                	li	a5,1
ffffffffc0204a82:	07fe                	slli	a5,a5,0x1f
    tf->status |= SSTATUS_SPIE; 
ffffffffc0204a84:	02096913          	ori	s2,s2,32
    tf->epc = elf->e_entry;
ffffffffc0204a88:	10e43423          	sd	a4,264(s0)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204a8c:	e81c                	sd	a5,16(s0)
    tf->status |= SSTATUS_SPIE; 
ffffffffc0204a8e:	11243023          	sd	s2,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204a92:	4641                	li	a2,16
ffffffffc0204a94:	4581                	li	a1,0
ffffffffc0204a96:	0b498513          	addi	a0,s3,180
ffffffffc0204a9a:	775000ef          	jal	ffffffffc0205a0e <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204a9e:	180c                	addi	a1,sp,48
ffffffffc0204aa0:	0b498513          	addi	a0,s3,180
ffffffffc0204aa4:	463d                	li	a2,15
ffffffffc0204aa6:	77b000ef          	jal	ffffffffc0205a20 <memcpy>
ffffffffc0204aaa:	740a                	ld	s0,160(sp)
ffffffffc0204aac:	6a0a                	ld	s4,128(sp)
ffffffffc0204aae:	7ae6                	ld	s5,120(sp)
ffffffffc0204ab0:	7b46                	ld	s6,112(sp)
ffffffffc0204ab2:	7ba6                	ld	s7,104(sp)
ffffffffc0204ab4:	7c06                	ld	s8,96(sp)
ffffffffc0204ab6:	6ce6                	ld	s9,88(sp)
}
ffffffffc0204ab8:	70aa                	ld	ra,168(sp)
ffffffffc0204aba:	694a                	ld	s2,144(sp)
ffffffffc0204abc:	69aa                	ld	s3,136(sp)
ffffffffc0204abe:	6d46                	ld	s10,80(sp)
ffffffffc0204ac0:	8526                	mv	a0,s1
ffffffffc0204ac2:	64ea                	ld	s1,152(sp)
ffffffffc0204ac4:	614d                	addi	sp,sp,176
ffffffffc0204ac6:	8082                	ret
    int ret = -E_NO_MEM;
ffffffffc0204ac8:	54f1                	li	s1,-4
ffffffffc0204aca:	bdad                	j	ffffffffc0204944 <do_execve+0x128>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204acc:	028a3603          	ld	a2,40(s4)
ffffffffc0204ad0:	020a3783          	ld	a5,32(s4)
ffffffffc0204ad4:	20f66363          	bltu	a2,a5,ffffffffc0204cda <do_execve+0x4be>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204ad8:	004a2783          	lw	a5,4(s4)
ffffffffc0204adc:	0027971b          	slliw	a4,a5,0x2
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204ae0:	0027f693          	andi	a3,a5,2
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204ae4:	8b11                	andi	a4,a4,4
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204ae6:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204ae8:	c6f1                	beqz	a3,ffffffffc0204bb4 <do_execve+0x398>
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204aea:	1c079763          	bnez	a5,ffffffffc0204cb8 <do_execve+0x49c>
            perm |= (PTE_W | PTE_R);
ffffffffc0204aee:	47dd                	li	a5,23
            vm_flags |= VM_WRITE;
ffffffffc0204af0:	00276693          	ori	a3,a4,2
            perm |= (PTE_W | PTE_R);
ffffffffc0204af4:	e43e                	sd	a5,8(sp)
        if (vm_flags & VM_EXEC)
ffffffffc0204af6:	c709                	beqz	a4,ffffffffc0204b00 <do_execve+0x2e4>
            perm |= PTE_X;
ffffffffc0204af8:	67a2                	ld	a5,8(sp)
ffffffffc0204afa:	0087e793          	ori	a5,a5,8
ffffffffc0204afe:	e43e                	sd	a5,8(sp)
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204b00:	010a3583          	ld	a1,16(s4)
ffffffffc0204b04:	4701                	li	a4,0
ffffffffc0204b06:	854a                	mv	a0,s2
ffffffffc0204b08:	cbffe0ef          	jal	ffffffffc02037c6 <mm_map>
ffffffffc0204b0c:	84aa                	mv	s1,a0
ffffffffc0204b0e:	1c051463          	bnez	a0,ffffffffc0204cd6 <do_execve+0x4ba>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204b12:	010a3b03          	ld	s6,16(s4)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204b16:	020a3483          	ld	s1,32(s4)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204b1a:	77fd                	lui	a5,0xfffff
ffffffffc0204b1c:	00fb75b3          	and	a1,s6,a5
        end = ph->p_va + ph->p_filesz;
ffffffffc0204b20:	94da                	add	s1,s1,s6
        while (start < end)
ffffffffc0204b22:	1a9b7563          	bgeu	s6,s1,ffffffffc0204ccc <do_execve+0x4b0>
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204b26:	008a3983          	ld	s3,8(s4)
ffffffffc0204b2a:	67e2                	ld	a5,24(sp)
ffffffffc0204b2c:	99be                	add	s3,s3,a5
ffffffffc0204b2e:	a881                	j	ffffffffc0204b7e <do_execve+0x362>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204b30:	6785                	lui	a5,0x1
ffffffffc0204b32:	00f58db3          	add	s11,a1,a5
                size -= la - end;
ffffffffc0204b36:	41648633          	sub	a2,s1,s6
            if (end < la)
ffffffffc0204b3a:	01b4e463          	bltu	s1,s11,ffffffffc0204b42 <do_execve+0x326>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204b3e:	416d8633          	sub	a2,s11,s6
    return page - pages + nbase;
ffffffffc0204b42:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204b46:	67c2                	ld	a5,16(sp)
ffffffffc0204b48:	000cb503          	ld	a0,0(s9)
    return page - pages + nbase;
ffffffffc0204b4c:	40d406b3          	sub	a3,s0,a3
ffffffffc0204b50:	8699                	srai	a3,a3,0x6
ffffffffc0204b52:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204b54:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b58:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204b5a:	18a87363          	bgeu	a6,a0,ffffffffc0204ce0 <do_execve+0x4c4>
ffffffffc0204b5e:	000ab503          	ld	a0,0(s5)
ffffffffc0204b62:	40bb05b3          	sub	a1,s6,a1
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204b66:	e032                	sd	a2,0(sp)
ffffffffc0204b68:	9536                	add	a0,a0,a3
ffffffffc0204b6a:	952e                	add	a0,a0,a1
ffffffffc0204b6c:	85ce                	mv	a1,s3
ffffffffc0204b6e:	6b3000ef          	jal	ffffffffc0205a20 <memcpy>
            start += size, from += size;
ffffffffc0204b72:	6602                	ld	a2,0(sp)
ffffffffc0204b74:	9b32                	add	s6,s6,a2
ffffffffc0204b76:	99b2                	add	s3,s3,a2
        while (start < end)
ffffffffc0204b78:	049b7563          	bgeu	s6,s1,ffffffffc0204bc2 <do_execve+0x3a6>
ffffffffc0204b7c:	85ee                	mv	a1,s11
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204b7e:	01893503          	ld	a0,24(s2)
ffffffffc0204b82:	6622                	ld	a2,8(sp)
ffffffffc0204b84:	e02e                	sd	a1,0(sp)
ffffffffc0204b86:	9cffe0ef          	jal	ffffffffc0203554 <pgdir_alloc_page>
ffffffffc0204b8a:	6582                	ld	a1,0(sp)
ffffffffc0204b8c:	842a                	mv	s0,a0
ffffffffc0204b8e:	f14d                	bnez	a0,ffffffffc0204b30 <do_execve+0x314>
ffffffffc0204b90:	6da6                	ld	s11,72(sp)
        ret = -E_NO_MEM;
ffffffffc0204b92:	54f1                	li	s1,-4
    exit_mmap(mm);
ffffffffc0204b94:	854a                	mv	a0,s2
ffffffffc0204b96:	d95fe0ef          	jal	ffffffffc020392a <exit_mmap>
ffffffffc0204b9a:	740a                	ld	s0,160(sp)
ffffffffc0204b9c:	6a0a                	ld	s4,128(sp)
ffffffffc0204b9e:	bb41                	j	ffffffffc020492e <do_execve+0x112>
            exit_mmap(mm);
ffffffffc0204ba0:	854a                	mv	a0,s2
ffffffffc0204ba2:	d89fe0ef          	jal	ffffffffc020392a <exit_mmap>
            put_pgdir(mm);
ffffffffc0204ba6:	854a                	mv	a0,s2
ffffffffc0204ba8:	a7aff0ef          	jal	ffffffffc0203e22 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204bac:	854a                	mv	a0,s2
ffffffffc0204bae:	bc7fe0ef          	jal	ffffffffc0203774 <mm_destroy>
ffffffffc0204bb2:	b1e5                	j	ffffffffc020489a <do_execve+0x7e>
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204bb4:	0e078e63          	beqz	a5,ffffffffc0204cb0 <do_execve+0x494>
            perm |= PTE_R;
ffffffffc0204bb8:	47cd                	li	a5,19
            vm_flags |= VM_READ;
ffffffffc0204bba:	00176693          	ori	a3,a4,1
            perm |= PTE_R;
ffffffffc0204bbe:	e43e                	sd	a5,8(sp)
ffffffffc0204bc0:	bf1d                	j	ffffffffc0204af6 <do_execve+0x2da>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204bc2:	010a3483          	ld	s1,16(s4)
ffffffffc0204bc6:	028a3683          	ld	a3,40(s4)
ffffffffc0204bca:	94b6                	add	s1,s1,a3
        if (start < la)
ffffffffc0204bcc:	07bb7c63          	bgeu	s6,s11,ffffffffc0204c44 <do_execve+0x428>
            if (start == end)
ffffffffc0204bd0:	df6489e3          	beq	s1,s6,ffffffffc02049c2 <do_execve+0x1a6>
                size -= la - end;
ffffffffc0204bd4:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204bd8:	0fb4f563          	bgeu	s1,s11,ffffffffc0204cc2 <do_execve+0x4a6>
    return page - pages + nbase;
ffffffffc0204bdc:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204be0:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0204be4:	40d406b3          	sub	a3,s0,a3
ffffffffc0204be8:	8699                	srai	a3,a3,0x6
ffffffffc0204bea:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204bec:	00c69593          	slli	a1,a3,0xc
ffffffffc0204bf0:	81b1                	srli	a1,a1,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0204bf2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204bf4:	0ec5f663          	bgeu	a1,a2,ffffffffc0204ce0 <do_execve+0x4c4>
ffffffffc0204bf8:	000ab603          	ld	a2,0(s5)
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204bfc:	6505                	lui	a0,0x1
ffffffffc0204bfe:	955a                	add	a0,a0,s6
ffffffffc0204c00:	96b2                	add	a3,a3,a2
ffffffffc0204c02:	41b50533          	sub	a0,a0,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204c06:	9536                	add	a0,a0,a3
ffffffffc0204c08:	864e                	mv	a2,s3
ffffffffc0204c0a:	4581                	li	a1,0
ffffffffc0204c0c:	603000ef          	jal	ffffffffc0205a0e <memset>
            start += size;
ffffffffc0204c10:	9b4e                	add	s6,s6,s3
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204c12:	01b4b6b3          	sltu	a3,s1,s11
ffffffffc0204c16:	01b4f463          	bgeu	s1,s11,ffffffffc0204c1e <do_execve+0x402>
ffffffffc0204c1a:	db6484e3          	beq	s1,s6,ffffffffc02049c2 <do_execve+0x1a6>
ffffffffc0204c1e:	e299                	bnez	a3,ffffffffc0204c24 <do_execve+0x408>
ffffffffc0204c20:	03bb0263          	beq	s6,s11,ffffffffc0204c44 <do_execve+0x428>
ffffffffc0204c24:	00002697          	auipc	a3,0x2
ffffffffc0204c28:	7fc68693          	addi	a3,a3,2044 # ffffffffc0207420 <etext+0x19e8>
ffffffffc0204c2c:	00002617          	auipc	a2,0x2
ffffffffc0204c30:	82460613          	addi	a2,a2,-2012 # ffffffffc0206450 <etext+0xa18>
ffffffffc0204c34:	27900593          	li	a1,633
ffffffffc0204c38:	00002517          	auipc	a0,0x2
ffffffffc0204c3c:	5f850513          	addi	a0,a0,1528 # ffffffffc0207230 <etext+0x17f8>
ffffffffc0204c40:	80bfb0ef          	jal	ffffffffc020044a <__panic>
        while (start < end)
ffffffffc0204c44:	d69b7fe3          	bgeu	s6,s1,ffffffffc02049c2 <do_execve+0x1a6>
ffffffffc0204c48:	56fd                	li	a3,-1
ffffffffc0204c4a:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204c4e:	f03e                	sd	a5,32(sp)
ffffffffc0204c50:	a0b9                	j	ffffffffc0204c9e <do_execve+0x482>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204c52:	6785                	lui	a5,0x1
ffffffffc0204c54:	00fd8833          	add	a6,s11,a5
                size -= la - end;
ffffffffc0204c58:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204c5c:	0104e463          	bltu	s1,a6,ffffffffc0204c64 <do_execve+0x448>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204c60:	416809b3          	sub	s3,a6,s6
    return page - pages + nbase;
ffffffffc0204c64:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204c68:	7782                	ld	a5,32(sp)
ffffffffc0204c6a:	000cb583          	ld	a1,0(s9)
    return page - pages + nbase;
ffffffffc0204c6e:	40d406b3          	sub	a3,s0,a3
ffffffffc0204c72:	8699                	srai	a3,a3,0x6
ffffffffc0204c74:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204c76:	00f6f533          	and	a0,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c7a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204c7c:	06b57263          	bgeu	a0,a1,ffffffffc0204ce0 <do_execve+0x4c4>
ffffffffc0204c80:	000ab583          	ld	a1,0(s5)
ffffffffc0204c84:	41bb0533          	sub	a0,s6,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204c88:	864e                	mv	a2,s3
ffffffffc0204c8a:	96ae                	add	a3,a3,a1
ffffffffc0204c8c:	9536                	add	a0,a0,a3
ffffffffc0204c8e:	4581                	li	a1,0
            start += size;
ffffffffc0204c90:	9b4e                	add	s6,s6,s3
ffffffffc0204c92:	e042                	sd	a6,0(sp)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204c94:	57b000ef          	jal	ffffffffc0205a0e <memset>
        while (start < end)
ffffffffc0204c98:	d29b75e3          	bgeu	s6,s1,ffffffffc02049c2 <do_execve+0x1a6>
ffffffffc0204c9c:	6d82                	ld	s11,0(sp)
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204c9e:	01893503          	ld	a0,24(s2)
ffffffffc0204ca2:	6622                	ld	a2,8(sp)
ffffffffc0204ca4:	85ee                	mv	a1,s11
ffffffffc0204ca6:	8affe0ef          	jal	ffffffffc0203554 <pgdir_alloc_page>
ffffffffc0204caa:	842a                	mv	s0,a0
ffffffffc0204cac:	f15d                	bnez	a0,ffffffffc0204c52 <do_execve+0x436>
ffffffffc0204cae:	b5cd                	j	ffffffffc0204b90 <do_execve+0x374>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204cb0:	47c5                	li	a5,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204cb2:	86ba                	mv	a3,a4
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204cb4:	e43e                	sd	a5,8(sp)
ffffffffc0204cb6:	b581                	j	ffffffffc0204af6 <do_execve+0x2da>
            perm |= (PTE_W | PTE_R);
ffffffffc0204cb8:	47dd                	li	a5,23
            vm_flags |= VM_READ;
ffffffffc0204cba:	00376693          	ori	a3,a4,3
            perm |= (PTE_W | PTE_R);
ffffffffc0204cbe:	e43e                	sd	a5,8(sp)
ffffffffc0204cc0:	bd1d                	j	ffffffffc0204af6 <do_execve+0x2da>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204cc2:	416d89b3          	sub	s3,s11,s6
ffffffffc0204cc6:	bf19                	j	ffffffffc0204bdc <do_execve+0x3c0>
        return -E_INVAL;
ffffffffc0204cc8:	54f5                	li	s1,-3
ffffffffc0204cca:	b3fd                	j	ffffffffc0204ab8 <do_execve+0x29c>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204ccc:	8dae                	mv	s11,a1
        while (start < end)
ffffffffc0204cce:	84da                	mv	s1,s6
ffffffffc0204cd0:	bddd                	j	ffffffffc0204bc6 <do_execve+0x3aa>
    int ret = -E_NO_MEM;
ffffffffc0204cd2:	54f1                	li	s1,-4
ffffffffc0204cd4:	b1ad                	j	ffffffffc020493e <do_execve+0x122>
ffffffffc0204cd6:	6da6                	ld	s11,72(sp)
ffffffffc0204cd8:	bd75                	j	ffffffffc0204b94 <do_execve+0x378>
            ret = -E_INVAL_ELF;
ffffffffc0204cda:	6da6                	ld	s11,72(sp)
ffffffffc0204cdc:	54e1                	li	s1,-8
ffffffffc0204cde:	bd5d                	j	ffffffffc0204b94 <do_execve+0x378>
ffffffffc0204ce0:	00002617          	auipc	a2,0x2
ffffffffc0204ce4:	b2060613          	addi	a2,a2,-1248 # ffffffffc0206800 <etext+0xdc8>
ffffffffc0204ce8:	07100593          	li	a1,113
ffffffffc0204cec:	00002517          	auipc	a0,0x2
ffffffffc0204cf0:	b3c50513          	addi	a0,a0,-1220 # ffffffffc0206828 <etext+0xdf0>
ffffffffc0204cf4:	f56fb0ef          	jal	ffffffffc020044a <__panic>
ffffffffc0204cf8:	00002617          	auipc	a2,0x2
ffffffffc0204cfc:	b0860613          	addi	a2,a2,-1272 # ffffffffc0206800 <etext+0xdc8>
ffffffffc0204d00:	07100593          	li	a1,113
ffffffffc0204d04:	00002517          	auipc	a0,0x2
ffffffffc0204d08:	b2450513          	addi	a0,a0,-1244 # ffffffffc0206828 <etext+0xdf0>
ffffffffc0204d0c:	f122                	sd	s0,160(sp)
ffffffffc0204d0e:	e152                	sd	s4,128(sp)
ffffffffc0204d10:	e4ee                	sd	s11,72(sp)
ffffffffc0204d12:	f38fb0ef          	jal	ffffffffc020044a <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204d16:	00002617          	auipc	a2,0x2
ffffffffc0204d1a:	b9260613          	addi	a2,a2,-1134 # ffffffffc02068a8 <etext+0xe70>
ffffffffc0204d1e:	29800593          	li	a1,664
ffffffffc0204d22:	00002517          	auipc	a0,0x2
ffffffffc0204d26:	50e50513          	addi	a0,a0,1294 # ffffffffc0207230 <etext+0x17f8>
ffffffffc0204d2a:	e4ee                	sd	s11,72(sp)
ffffffffc0204d2c:	f1efb0ef          	jal	ffffffffc020044a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204d30:	00003697          	auipc	a3,0x3
ffffffffc0204d34:	80868693          	addi	a3,a3,-2040 # ffffffffc0207538 <etext+0x1b00>
ffffffffc0204d38:	00001617          	auipc	a2,0x1
ffffffffc0204d3c:	71860613          	addi	a2,a2,1816 # ffffffffc0206450 <etext+0xa18>
ffffffffc0204d40:	29300593          	li	a1,659
ffffffffc0204d44:	00002517          	auipc	a0,0x2
ffffffffc0204d48:	4ec50513          	addi	a0,a0,1260 # ffffffffc0207230 <etext+0x17f8>
ffffffffc0204d4c:	e4ee                	sd	s11,72(sp)
ffffffffc0204d4e:	efcfb0ef          	jal	ffffffffc020044a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204d52:	00002697          	auipc	a3,0x2
ffffffffc0204d56:	79e68693          	addi	a3,a3,1950 # ffffffffc02074f0 <etext+0x1ab8>
ffffffffc0204d5a:	00001617          	auipc	a2,0x1
ffffffffc0204d5e:	6f660613          	addi	a2,a2,1782 # ffffffffc0206450 <etext+0xa18>
ffffffffc0204d62:	29200593          	li	a1,658
ffffffffc0204d66:	00002517          	auipc	a0,0x2
ffffffffc0204d6a:	4ca50513          	addi	a0,a0,1226 # ffffffffc0207230 <etext+0x17f8>
ffffffffc0204d6e:	e4ee                	sd	s11,72(sp)
ffffffffc0204d70:	edafb0ef          	jal	ffffffffc020044a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204d74:	00002697          	auipc	a3,0x2
ffffffffc0204d78:	73468693          	addi	a3,a3,1844 # ffffffffc02074a8 <etext+0x1a70>
ffffffffc0204d7c:	00001617          	auipc	a2,0x1
ffffffffc0204d80:	6d460613          	addi	a2,a2,1748 # ffffffffc0206450 <etext+0xa18>
ffffffffc0204d84:	29100593          	li	a1,657
ffffffffc0204d88:	00002517          	auipc	a0,0x2
ffffffffc0204d8c:	4a850513          	addi	a0,a0,1192 # ffffffffc0207230 <etext+0x17f8>
ffffffffc0204d90:	e4ee                	sd	s11,72(sp)
ffffffffc0204d92:	eb8fb0ef          	jal	ffffffffc020044a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204d96:	00002697          	auipc	a3,0x2
ffffffffc0204d9a:	6ca68693          	addi	a3,a3,1738 # ffffffffc0207460 <etext+0x1a28>
ffffffffc0204d9e:	00001617          	auipc	a2,0x1
ffffffffc0204da2:	6b260613          	addi	a2,a2,1714 # ffffffffc0206450 <etext+0xa18>
ffffffffc0204da6:	29000593          	li	a1,656
ffffffffc0204daa:	00002517          	auipc	a0,0x2
ffffffffc0204dae:	48650513          	addi	a0,a0,1158 # ffffffffc0207230 <etext+0x17f8>
ffffffffc0204db2:	e4ee                	sd	s11,72(sp)
ffffffffc0204db4:	e96fb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0204db8 <user_main>:
{
ffffffffc0204db8:	1101                	addi	sp,sp,-32
ffffffffc0204dba:	e426                	sd	s1,8(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204dbc:	000b1497          	auipc	s1,0xb1
ffffffffc0204dc0:	cfc48493          	addi	s1,s1,-772 # ffffffffc02b5ab8 <current>
ffffffffc0204dc4:	609c                	ld	a5,0(s1)
ffffffffc0204dc6:	00002617          	auipc	a2,0x2
ffffffffc0204dca:	7ba60613          	addi	a2,a2,1978 # ffffffffc0207580 <etext+0x1b48>
ffffffffc0204dce:	00002517          	auipc	a0,0x2
ffffffffc0204dd2:	7c250513          	addi	a0,a0,1986 # ffffffffc0207590 <etext+0x1b58>
ffffffffc0204dd6:	43cc                	lw	a1,4(a5)
{
ffffffffc0204dd8:	ec06                	sd	ra,24(sp)
ffffffffc0204dda:	e822                	sd	s0,16(sp)
ffffffffc0204ddc:	e04a                	sd	s2,0(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204dde:	bbafb0ef          	jal	ffffffffc0200198 <cprintf>
    size_t len = strlen(name);
ffffffffc0204de2:	00002517          	auipc	a0,0x2
ffffffffc0204de6:	79e50513          	addi	a0,a0,1950 # ffffffffc0207580 <etext+0x1b48>
ffffffffc0204dea:	371000ef          	jal	ffffffffc020595a <strlen>
    struct trapframe *old_tf = current->tf;
ffffffffc0204dee:	6098                	ld	a4,0(s1)
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204df0:	6789                	lui	a5,0x2
ffffffffc0204df2:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_softint_out_size-0x7088>
ffffffffc0204df6:	6b00                	ld	s0,16(a4)
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204df8:	734c                	ld	a1,160(a4)
    size_t len = strlen(name);
ffffffffc0204dfa:	892a                	mv	s2,a0
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204dfc:	943e                	add	s0,s0,a5
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204dfe:	12000613          	li	a2,288
ffffffffc0204e02:	8522                	mv	a0,s0
ffffffffc0204e04:	41d000ef          	jal	ffffffffc0205a20 <memcpy>
    current->tf = new_tf;
ffffffffc0204e08:	609c                	ld	a5,0(s1)
    ret = do_execve(name, len, binary, size);
ffffffffc0204e0a:	85ca                	mv	a1,s2
ffffffffc0204e0c:	3fe06697          	auipc	a3,0x3fe06
ffffffffc0204e10:	94c68693          	addi	a3,a3,-1716 # a758 <_binary_obj___user_priority_out_size>
    current->tf = new_tf;
ffffffffc0204e14:	f3c0                	sd	s0,160(a5)
    ret = do_execve(name, len, binary, size);
ffffffffc0204e16:	00072617          	auipc	a2,0x72
ffffffffc0204e1a:	e1260613          	addi	a2,a2,-494 # ffffffffc0276c28 <_binary_obj___user_priority_out_start>
ffffffffc0204e1e:	00002517          	auipc	a0,0x2
ffffffffc0204e22:	76250513          	addi	a0,a0,1890 # ffffffffc0207580 <etext+0x1b48>
ffffffffc0204e26:	9f7ff0ef          	jal	ffffffffc020481c <do_execve>
    asm volatile(
ffffffffc0204e2a:	8122                	mv	sp,s0
ffffffffc0204e2c:	858fc06f          	j	ffffffffc0200e84 <__trapret>
    panic("user_main execve failed.\n");
ffffffffc0204e30:	00002617          	auipc	a2,0x2
ffffffffc0204e34:	78860613          	addi	a2,a2,1928 # ffffffffc02075b8 <etext+0x1b80>
ffffffffc0204e38:	37500593          	li	a1,885
ffffffffc0204e3c:	00002517          	auipc	a0,0x2
ffffffffc0204e40:	3f450513          	addi	a0,a0,1012 # ffffffffc0207230 <etext+0x17f8>
ffffffffc0204e44:	e06fb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0204e48 <do_yield>:
    current->need_resched = 1;
ffffffffc0204e48:	000b1797          	auipc	a5,0xb1
ffffffffc0204e4c:	c707b783          	ld	a5,-912(a5) # ffffffffc02b5ab8 <current>
ffffffffc0204e50:	4705                	li	a4,1
}
ffffffffc0204e52:	4501                	li	a0,0
    current->need_resched = 1;
ffffffffc0204e54:	ef98                	sd	a4,24(a5)
}
ffffffffc0204e56:	8082                	ret

ffffffffc0204e58 <do_wait>:
    if (code_store != NULL)
ffffffffc0204e58:	c59d                	beqz	a1,ffffffffc0204e86 <do_wait+0x2e>
{
ffffffffc0204e5a:	1101                	addi	sp,sp,-32
ffffffffc0204e5c:	e02a                	sd	a0,0(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204e5e:	000b1517          	auipc	a0,0xb1
ffffffffc0204e62:	c5a53503          	ld	a0,-934(a0) # ffffffffc02b5ab8 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204e66:	4685                	li	a3,1
ffffffffc0204e68:	4611                	li	a2,4
ffffffffc0204e6a:	7508                	ld	a0,40(a0)
{
ffffffffc0204e6c:	ec06                	sd	ra,24(sp)
ffffffffc0204e6e:	e42e                	sd	a1,8(sp)
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204e70:	e53fe0ef          	jal	ffffffffc0203cc2 <user_mem_check>
ffffffffc0204e74:	6702                	ld	a4,0(sp)
ffffffffc0204e76:	67a2                	ld	a5,8(sp)
ffffffffc0204e78:	c909                	beqz	a0,ffffffffc0204e8a <do_wait+0x32>
}
ffffffffc0204e7a:	60e2                	ld	ra,24(sp)
ffffffffc0204e7c:	85be                	mv	a1,a5
ffffffffc0204e7e:	853a                	mv	a0,a4
ffffffffc0204e80:	6105                	addi	sp,sp,32
ffffffffc0204e82:	e94ff06f          	j	ffffffffc0204516 <do_wait.part.0>
ffffffffc0204e86:	e90ff06f          	j	ffffffffc0204516 <do_wait.part.0>
ffffffffc0204e8a:	60e2                	ld	ra,24(sp)
ffffffffc0204e8c:	5575                	li	a0,-3
ffffffffc0204e8e:	6105                	addi	sp,sp,32
ffffffffc0204e90:	8082                	ret

ffffffffc0204e92 <do_kill>:
    if (0 < pid && pid < MAX_PID)
ffffffffc0204e92:	6789                	lui	a5,0x2
ffffffffc0204e94:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204e98:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6f6a>
ffffffffc0204e9a:	06e7e463          	bltu	a5,a4,ffffffffc0204f02 <do_kill+0x70>
{
ffffffffc0204e9e:	1101                	addi	sp,sp,-32
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204ea0:	45a9                	li	a1,10
{
ffffffffc0204ea2:	ec06                	sd	ra,24(sp)
ffffffffc0204ea4:	e42a                	sd	a0,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204ea6:	6d2000ef          	jal	ffffffffc0205578 <hash32>
ffffffffc0204eaa:	02051793          	slli	a5,a0,0x20
ffffffffc0204eae:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204eb2:	000ad797          	auipc	a5,0xad
ffffffffc0204eb6:	b5e78793          	addi	a5,a5,-1186 # ffffffffc02b1a10 <hash_list>
ffffffffc0204eba:	96be                	add	a3,a3,a5
        while ((le = list_next(le)) != list)
ffffffffc0204ebc:	6622                	ld	a2,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204ebe:	8536                	mv	a0,a3
        while ((le = list_next(le)) != list)
ffffffffc0204ec0:	a029                	j	ffffffffc0204eca <do_kill+0x38>
            if (proc->pid == pid)
ffffffffc0204ec2:	f2c52703          	lw	a4,-212(a0)
ffffffffc0204ec6:	00c70963          	beq	a4,a2,ffffffffc0204ed8 <do_kill+0x46>
ffffffffc0204eca:	6508                	ld	a0,8(a0)
        while ((le = list_next(le)) != list)
ffffffffc0204ecc:	fea69be3          	bne	a3,a0,ffffffffc0204ec2 <do_kill+0x30>
}
ffffffffc0204ed0:	60e2                	ld	ra,24(sp)
    return -E_INVAL;
ffffffffc0204ed2:	5575                	li	a0,-3
}
ffffffffc0204ed4:	6105                	addi	sp,sp,32
ffffffffc0204ed6:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204ed8:	fd852703          	lw	a4,-40(a0)
ffffffffc0204edc:	00177693          	andi	a3,a4,1
ffffffffc0204ee0:	e29d                	bnez	a3,ffffffffc0204f06 <do_kill+0x74>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204ee2:	4954                	lw	a3,20(a0)
            proc->flags |= PF_EXITING;
ffffffffc0204ee4:	00176713          	ori	a4,a4,1
ffffffffc0204ee8:	fce52c23          	sw	a4,-40(a0)
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204eec:	0006c663          	bltz	a3,ffffffffc0204ef8 <do_kill+0x66>
            return 0;
ffffffffc0204ef0:	4501                	li	a0,0
}
ffffffffc0204ef2:	60e2                	ld	ra,24(sp)
ffffffffc0204ef4:	6105                	addi	sp,sp,32
ffffffffc0204ef6:	8082                	ret
                wakeup_proc(proc);
ffffffffc0204ef8:	f2850513          	addi	a0,a0,-216
ffffffffc0204efc:	3d2000ef          	jal	ffffffffc02052ce <wakeup_proc>
ffffffffc0204f00:	bfc5                	j	ffffffffc0204ef0 <do_kill+0x5e>
    return -E_INVAL;
ffffffffc0204f02:	5575                	li	a0,-3
}
ffffffffc0204f04:	8082                	ret
        return -E_KILLED;
ffffffffc0204f06:	555d                	li	a0,-9
ffffffffc0204f08:	b7ed                	j	ffffffffc0204ef2 <do_kill+0x60>

ffffffffc0204f0a <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204f0a:	1101                	addi	sp,sp,-32
ffffffffc0204f0c:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204f0e:	000b1797          	auipc	a5,0xb1
ffffffffc0204f12:	b0278793          	addi	a5,a5,-1278 # ffffffffc02b5a10 <proc_list>
ffffffffc0204f16:	ec06                	sd	ra,24(sp)
ffffffffc0204f18:	e822                	sd	s0,16(sp)
ffffffffc0204f1a:	e04a                	sd	s2,0(sp)
ffffffffc0204f1c:	000ad497          	auipc	s1,0xad
ffffffffc0204f20:	af448493          	addi	s1,s1,-1292 # ffffffffc02b1a10 <hash_list>
ffffffffc0204f24:	e79c                	sd	a5,8(a5)
ffffffffc0204f26:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204f28:	000b1717          	auipc	a4,0xb1
ffffffffc0204f2c:	ae870713          	addi	a4,a4,-1304 # ffffffffc02b5a10 <proc_list>
ffffffffc0204f30:	87a6                	mv	a5,s1
ffffffffc0204f32:	e79c                	sd	a5,8(a5)
ffffffffc0204f34:	e39c                	sd	a5,0(a5)
ffffffffc0204f36:	07c1                	addi	a5,a5,16
ffffffffc0204f38:	fee79de3          	bne	a5,a4,ffffffffc0204f32 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204f3c:	e33fe0ef          	jal	ffffffffc0203d6e <alloc_proc>
ffffffffc0204f40:	000b1917          	auipc	s2,0xb1
ffffffffc0204f44:	b8890913          	addi	s2,s2,-1144 # ffffffffc02b5ac8 <idleproc>
ffffffffc0204f48:	00a93023          	sd	a0,0(s2)
ffffffffc0204f4c:	10050363          	beqz	a0,ffffffffc0205052 <proc_init+0x148>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204f50:	4789                	li	a5,2
ffffffffc0204f52:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204f54:	00004797          	auipc	a5,0x4
ffffffffc0204f58:	0ac78793          	addi	a5,a5,172 # ffffffffc0209000 <bootstack>
ffffffffc0204f5c:	e91c                	sd	a5,16(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f5e:	0b450413          	addi	s0,a0,180
    idleproc->need_resched = 1;
ffffffffc0204f62:	4785                	li	a5,1
ffffffffc0204f64:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f66:	4641                	li	a2,16
ffffffffc0204f68:	8522                	mv	a0,s0
ffffffffc0204f6a:	4581                	li	a1,0
ffffffffc0204f6c:	2a3000ef          	jal	ffffffffc0205a0e <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204f70:	8522                	mv	a0,s0
ffffffffc0204f72:	463d                	li	a2,15
ffffffffc0204f74:	00002597          	auipc	a1,0x2
ffffffffc0204f78:	67c58593          	addi	a1,a1,1660 # ffffffffc02075f0 <etext+0x1bb8>
ffffffffc0204f7c:	2a5000ef          	jal	ffffffffc0205a20 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204f80:	000b1797          	auipc	a5,0xb1
ffffffffc0204f84:	b307a783          	lw	a5,-1232(a5) # ffffffffc02b5ab0 <nr_process>

    current = idleproc;
ffffffffc0204f88:	00093703          	ld	a4,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204f8c:	4601                	li	a2,0
    nr_process++;
ffffffffc0204f8e:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204f90:	4581                	li	a1,0
ffffffffc0204f92:	fffff517          	auipc	a0,0xfffff
ffffffffc0204f96:	76650513          	addi	a0,a0,1894 # ffffffffc02046f8 <init_main>
    current = idleproc;
ffffffffc0204f9a:	000b1697          	auipc	a3,0xb1
ffffffffc0204f9e:	b0e6bf23          	sd	a4,-1250(a3) # ffffffffc02b5ab8 <current>
    nr_process++;
ffffffffc0204fa2:	000b1717          	auipc	a4,0xb1
ffffffffc0204fa6:	b0f72723          	sw	a5,-1266(a4) # ffffffffc02b5ab0 <nr_process>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204faa:	bd8ff0ef          	jal	ffffffffc0204382 <kernel_thread>
ffffffffc0204fae:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0204fb0:	08a05563          	blez	a0,ffffffffc020503a <proc_init+0x130>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204fb4:	6789                	lui	a5,0x2
ffffffffc0204fb6:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6f6a>
ffffffffc0204fb8:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204fbc:	02e7e463          	bltu	a5,a4,ffffffffc0204fe4 <proc_init+0xda>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204fc0:	45a9                	li	a1,10
ffffffffc0204fc2:	5b6000ef          	jal	ffffffffc0205578 <hash32>
ffffffffc0204fc6:	02051713          	slli	a4,a0,0x20
ffffffffc0204fca:	01c75793          	srli	a5,a4,0x1c
ffffffffc0204fce:	00f486b3          	add	a3,s1,a5
ffffffffc0204fd2:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0204fd4:	a029                	j	ffffffffc0204fde <proc_init+0xd4>
            if (proc->pid == pid)
ffffffffc0204fd6:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204fda:	04870d63          	beq	a4,s0,ffffffffc0205034 <proc_init+0x12a>
    return listelm->next;
ffffffffc0204fde:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204fe0:	fef69be3          	bne	a3,a5,ffffffffc0204fd6 <proc_init+0xcc>
    return NULL;
ffffffffc0204fe4:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204fe6:	0b478413          	addi	s0,a5,180
ffffffffc0204fea:	4641                	li	a2,16
ffffffffc0204fec:	4581                	li	a1,0
ffffffffc0204fee:	8522                	mv	a0,s0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204ff0:	000b1717          	auipc	a4,0xb1
ffffffffc0204ff4:	acf73823          	sd	a5,-1328(a4) # ffffffffc02b5ac0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ff8:	217000ef          	jal	ffffffffc0205a0e <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204ffc:	8522                	mv	a0,s0
ffffffffc0204ffe:	463d                	li	a2,15
ffffffffc0205000:	00002597          	auipc	a1,0x2
ffffffffc0205004:	61858593          	addi	a1,a1,1560 # ffffffffc0207618 <etext+0x1be0>
ffffffffc0205008:	219000ef          	jal	ffffffffc0205a20 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc020500c:	00093783          	ld	a5,0(s2)
ffffffffc0205010:	cfad                	beqz	a5,ffffffffc020508a <proc_init+0x180>
ffffffffc0205012:	43dc                	lw	a5,4(a5)
ffffffffc0205014:	ebbd                	bnez	a5,ffffffffc020508a <proc_init+0x180>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205016:	000b1797          	auipc	a5,0xb1
ffffffffc020501a:	aaa7b783          	ld	a5,-1366(a5) # ffffffffc02b5ac0 <initproc>
ffffffffc020501e:	c7b1                	beqz	a5,ffffffffc020506a <proc_init+0x160>
ffffffffc0205020:	43d8                	lw	a4,4(a5)
ffffffffc0205022:	4785                	li	a5,1
ffffffffc0205024:	04f71363          	bne	a4,a5,ffffffffc020506a <proc_init+0x160>
}
ffffffffc0205028:	60e2                	ld	ra,24(sp)
ffffffffc020502a:	6442                	ld	s0,16(sp)
ffffffffc020502c:	64a2                	ld	s1,8(sp)
ffffffffc020502e:	6902                	ld	s2,0(sp)
ffffffffc0205030:	6105                	addi	sp,sp,32
ffffffffc0205032:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0205034:	f2878793          	addi	a5,a5,-216
ffffffffc0205038:	b77d                	j	ffffffffc0204fe6 <proc_init+0xdc>
        panic("create init_main failed.\n");
ffffffffc020503a:	00002617          	auipc	a2,0x2
ffffffffc020503e:	5be60613          	addi	a2,a2,1470 # ffffffffc02075f8 <etext+0x1bc0>
ffffffffc0205042:	3b100593          	li	a1,945
ffffffffc0205046:	00002517          	auipc	a0,0x2
ffffffffc020504a:	1ea50513          	addi	a0,a0,490 # ffffffffc0207230 <etext+0x17f8>
ffffffffc020504e:	bfcfb0ef          	jal	ffffffffc020044a <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0205052:	00002617          	auipc	a2,0x2
ffffffffc0205056:	58660613          	addi	a2,a2,1414 # ffffffffc02075d8 <etext+0x1ba0>
ffffffffc020505a:	3a200593          	li	a1,930
ffffffffc020505e:	00002517          	auipc	a0,0x2
ffffffffc0205062:	1d250513          	addi	a0,a0,466 # ffffffffc0207230 <etext+0x17f8>
ffffffffc0205066:	be4fb0ef          	jal	ffffffffc020044a <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020506a:	00002697          	auipc	a3,0x2
ffffffffc020506e:	5de68693          	addi	a3,a3,1502 # ffffffffc0207648 <etext+0x1c10>
ffffffffc0205072:	00001617          	auipc	a2,0x1
ffffffffc0205076:	3de60613          	addi	a2,a2,990 # ffffffffc0206450 <etext+0xa18>
ffffffffc020507a:	3b800593          	li	a1,952
ffffffffc020507e:	00002517          	auipc	a0,0x2
ffffffffc0205082:	1b250513          	addi	a0,a0,434 # ffffffffc0207230 <etext+0x17f8>
ffffffffc0205086:	bc4fb0ef          	jal	ffffffffc020044a <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc020508a:	00002697          	auipc	a3,0x2
ffffffffc020508e:	59668693          	addi	a3,a3,1430 # ffffffffc0207620 <etext+0x1be8>
ffffffffc0205092:	00001617          	auipc	a2,0x1
ffffffffc0205096:	3be60613          	addi	a2,a2,958 # ffffffffc0206450 <etext+0xa18>
ffffffffc020509a:	3b700593          	li	a1,951
ffffffffc020509e:	00002517          	auipc	a0,0x2
ffffffffc02050a2:	19250513          	addi	a0,a0,402 # ffffffffc0207230 <etext+0x17f8>
ffffffffc02050a6:	ba4fb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02050aa <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc02050aa:	1141                	addi	sp,sp,-16
ffffffffc02050ac:	e022                	sd	s0,0(sp)
ffffffffc02050ae:	e406                	sd	ra,8(sp)
ffffffffc02050b0:	000b1417          	auipc	s0,0xb1
ffffffffc02050b4:	a0840413          	addi	s0,s0,-1528 # ffffffffc02b5ab8 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc02050b8:	6018                	ld	a4,0(s0)
ffffffffc02050ba:	6f1c                	ld	a5,24(a4)
ffffffffc02050bc:	dffd                	beqz	a5,ffffffffc02050ba <cpu_idle+0x10>
        {
            schedule();
ffffffffc02050be:	308000ef          	jal	ffffffffc02053c6 <schedule>
ffffffffc02050c2:	bfdd                	j	ffffffffc02050b8 <cpu_idle+0xe>

ffffffffc02050c4 <lab6_set_priority>:
        }
    }
}
// FOR LAB6, set the process's priority (bigger value will get more CPU time)
void lab6_set_priority(uint32_t priority)
{
ffffffffc02050c4:	1101                	addi	sp,sp,-32
ffffffffc02050c6:	85aa                	mv	a1,a0
    cprintf("set priority to %d\n", priority);
ffffffffc02050c8:	e42a                	sd	a0,8(sp)
ffffffffc02050ca:	00002517          	auipc	a0,0x2
ffffffffc02050ce:	5a650513          	addi	a0,a0,1446 # ffffffffc0207670 <etext+0x1c38>
{
ffffffffc02050d2:	ec06                	sd	ra,24(sp)
    cprintf("set priority to %d\n", priority);
ffffffffc02050d4:	8c4fb0ef          	jal	ffffffffc0200198 <cprintf>
    if (priority == 0)
ffffffffc02050d8:	65a2                	ld	a1,8(sp)
        current->lab6_priority = 1;
ffffffffc02050da:	000b1717          	auipc	a4,0xb1
ffffffffc02050de:	9de73703          	ld	a4,-1570(a4) # ffffffffc02b5ab8 <current>
    if (priority == 0)
ffffffffc02050e2:	4785                	li	a5,1
ffffffffc02050e4:	c191                	beqz	a1,ffffffffc02050e8 <lab6_set_priority+0x24>
ffffffffc02050e6:	87ae                	mv	a5,a1
    else
        current->lab6_priority = priority;
}
ffffffffc02050e8:	60e2                	ld	ra,24(sp)
        current->lab6_priority = 1;
ffffffffc02050ea:	14f72223          	sw	a5,324(a4)
}
ffffffffc02050ee:	6105                	addi	sp,sp,32
ffffffffc02050f0:	8082                	ret

ffffffffc02050f2 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc02050f2:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc02050f6:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc02050fa:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc02050fc:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc02050fe:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0205102:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0205106:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc020510a:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc020510e:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0205112:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0205116:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc020511a:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc020511e:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0205122:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0205126:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc020512a:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc020512e:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0205130:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0205132:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0205136:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc020513a:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc020513e:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0205142:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0205146:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc020514a:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc020514e:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0205152:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0205156:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc020515a:	8082                	ret

ffffffffc020515c <RR_init>:
    elm->prev = elm->next = elm;
ffffffffc020515c:	e508                	sd	a0,8(a0)
ffffffffc020515e:	e108                	sd	a0,0(a0)
 */
static void
RR_init(struct run_queue *rq)
{
    list_init(&rq->run_list);
    rq->proc_num = 0;
ffffffffc0205160:	00052823          	sw	zero,16(a0)
    rq->lab6_run_pool = NULL;
ffffffffc0205164:	00053c23          	sd	zero,24(a0)
}
ffffffffc0205168:	8082                	ret

ffffffffc020516a <RR_pick_next>:
    return list->next == list;
ffffffffc020516a:	651c                	ld	a5,8(a0)
 * hint: see libs/list.h for routines of the list structures.
 */
static struct proc_struct *
RR_pick_next(struct run_queue *rq)
{
    if (list_empty(&rq->run_list))
ffffffffc020516c:	00f50563          	beq	a0,a5,ffffffffc0205176 <RR_pick_next+0xc>
        return NULL;
    list_entry_t *le = list_next(&rq->run_list);
    return le2proc(le, run_link);
ffffffffc0205170:	ef078513          	addi	a0,a5,-272
ffffffffc0205174:	8082                	ret
        return NULL;
ffffffffc0205176:	4501                	li	a0,0
}
ffffffffc0205178:	8082                	ret

ffffffffc020517a <RR_proc_tick>:
 * is the flag variable for process switching.
 */
static void
RR_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    assert(proc != NULL);
ffffffffc020517a:	cd81                	beqz	a1,ffffffffc0205192 <RR_proc_tick+0x18>
    proc->time_slice--;
ffffffffc020517c:	1205a783          	lw	a5,288(a1)
ffffffffc0205180:	37fd                	addiw	a5,a5,-1
ffffffffc0205182:	12f5a023          	sw	a5,288(a1)
    if (proc->time_slice <= 0)
ffffffffc0205186:	00f05363          	blez	a5,ffffffffc020518c <RR_proc_tick+0x12>
ffffffffc020518a:	8082                	ret
    {
        proc->need_resched = 1;
ffffffffc020518c:	4785                	li	a5,1
ffffffffc020518e:	ed9c                	sd	a5,24(a1)
ffffffffc0205190:	8082                	ret
{
ffffffffc0205192:	1141                	addi	sp,sp,-16
    assert(proc != NULL);
ffffffffc0205194:	00002697          	auipc	a3,0x2
ffffffffc0205198:	4f468693          	addi	a3,a3,1268 # ffffffffc0207688 <etext+0x1c50>
ffffffffc020519c:	00001617          	auipc	a2,0x1
ffffffffc02051a0:	2b460613          	addi	a2,a2,692 # ffffffffc0206450 <etext+0xa18>
ffffffffc02051a4:	05a00593          	li	a1,90
ffffffffc02051a8:	00002517          	auipc	a0,0x2
ffffffffc02051ac:	4f050513          	addi	a0,a0,1264 # ffffffffc0207698 <etext+0x1c60>
{
ffffffffc02051b0:	e406                	sd	ra,8(sp)
    assert(proc != NULL);
ffffffffc02051b2:	a98fb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02051b6 <RR_dequeue>:
    assert(proc != NULL && proc->rq == rq);
ffffffffc02051b6:	c59d                	beqz	a1,ffffffffc02051e4 <RR_dequeue+0x2e>
ffffffffc02051b8:	1085b783          	ld	a5,264(a1)
ffffffffc02051bc:	02a79463          	bne	a5,a0,ffffffffc02051e4 <RR_dequeue+0x2e>
    __list_del(listelm->prev, listelm->next);
ffffffffc02051c0:	1105b503          	ld	a0,272(a1)
ffffffffc02051c4:	1185b603          	ld	a2,280(a1)
    rq->proc_num--;
ffffffffc02051c8:	4b98                	lw	a4,16(a5)
    list_del_init(&proc->run_link);
ffffffffc02051ca:	11058693          	addi	a3,a1,272
    prev->next = next;
ffffffffc02051ce:	e510                	sd	a2,8(a0)
    next->prev = prev;
ffffffffc02051d0:	e208                	sd	a0,0(a2)
    proc->rq = NULL;
ffffffffc02051d2:	1005b423          	sd	zero,264(a1)
    rq->proc_num--;
ffffffffc02051d6:	377d                	addiw	a4,a4,-1
    elm->prev = elm->next = elm;
ffffffffc02051d8:	10d5bc23          	sd	a3,280(a1)
ffffffffc02051dc:	10d5b823          	sd	a3,272(a1)
ffffffffc02051e0:	cb98                	sw	a4,16(a5)
ffffffffc02051e2:	8082                	ret
{
ffffffffc02051e4:	1141                	addi	sp,sp,-16
    assert(proc != NULL && proc->rq == rq);
ffffffffc02051e6:	00002697          	auipc	a3,0x2
ffffffffc02051ea:	4d268693          	addi	a3,a3,1234 # ffffffffc02076b8 <etext+0x1c80>
ffffffffc02051ee:	00001617          	auipc	a2,0x1
ffffffffc02051f2:	26260613          	addi	a2,a2,610 # ffffffffc0206450 <etext+0xa18>
ffffffffc02051f6:	03900593          	li	a1,57
ffffffffc02051fa:	00002517          	auipc	a0,0x2
ffffffffc02051fe:	49e50513          	addi	a0,a0,1182 # ffffffffc0207698 <etext+0x1c60>
{
ffffffffc0205202:	e406                	sd	ra,8(sp)
    assert(proc != NULL && proc->rq == rq);
ffffffffc0205204:	a46fb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0205208 <RR_enqueue>:
    assert(proc != NULL);
ffffffffc0205208:	c19d                	beqz	a1,ffffffffc020522e <RR_enqueue+0x26>
    proc->time_slice = rq->max_time_slice;
ffffffffc020520a:	495c                	lw	a5,20(a0)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020520c:	6118                	ld	a4,0(a0)
    list_add_before(&rq->run_list, &proc->run_link);
ffffffffc020520e:	11058693          	addi	a3,a1,272
    proc->time_slice = rq->max_time_slice;
ffffffffc0205212:	12f5a023          	sw	a5,288(a1)
    rq->proc_num++;
ffffffffc0205216:	491c                	lw	a5,16(a0)
    proc->rq = rq;
ffffffffc0205218:	10a5b423          	sd	a0,264(a1)
    prev->next = next->prev = elm;
ffffffffc020521c:	e114                	sd	a3,0(a0)
ffffffffc020521e:	e714                	sd	a3,8(a4)
    rq->proc_num++;
ffffffffc0205220:	2785                	addiw	a5,a5,1
    elm->prev = prev;
ffffffffc0205222:	10e5b823          	sd	a4,272(a1)
    elm->next = next;
ffffffffc0205226:	10a5bc23          	sd	a0,280(a1)
ffffffffc020522a:	c91c                	sw	a5,16(a0)
ffffffffc020522c:	8082                	ret
{
ffffffffc020522e:	1141                	addi	sp,sp,-16
    assert(proc != NULL);
ffffffffc0205230:	00002697          	auipc	a3,0x2
ffffffffc0205234:	45868693          	addi	a3,a3,1112 # ffffffffc0207688 <etext+0x1c50>
ffffffffc0205238:	00001617          	auipc	a2,0x1
ffffffffc020523c:	21860613          	addi	a2,a2,536 # ffffffffc0206450 <etext+0xa18>
ffffffffc0205240:	02700593          	li	a1,39
ffffffffc0205244:	00002517          	auipc	a0,0x2
ffffffffc0205248:	45450513          	addi	a0,a0,1108 # ffffffffc0207698 <etext+0x1c60>
{
ffffffffc020524c:	e406                	sd	ra,8(sp)
    assert(proc != NULL);
ffffffffc020524e:	9fcfb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0205252 <sched_class_proc_tick>:
    return sched_class->pick_next(rq);
}

void sched_class_proc_tick(struct proc_struct *proc)
{
    if (proc != idleproc)
ffffffffc0205252:	000b1797          	auipc	a5,0xb1
ffffffffc0205256:	8767b783          	ld	a5,-1930(a5) # ffffffffc02b5ac8 <idleproc>
{
ffffffffc020525a:	85aa                	mv	a1,a0
    if (proc != idleproc)
ffffffffc020525c:	00a78c63          	beq	a5,a0,ffffffffc0205274 <sched_class_proc_tick+0x22>
    {
        sched_class->proc_tick(rq, proc);
ffffffffc0205260:	000b1797          	auipc	a5,0xb1
ffffffffc0205264:	8787b783          	ld	a5,-1928(a5) # ffffffffc02b5ad8 <sched_class>
ffffffffc0205268:	000b1517          	auipc	a0,0xb1
ffffffffc020526c:	86853503          	ld	a0,-1944(a0) # ffffffffc02b5ad0 <rq>
ffffffffc0205270:	779c                	ld	a5,40(a5)
ffffffffc0205272:	8782                	jr	a5
    }
    else
    {
        proc->need_resched = 1;
ffffffffc0205274:	4705                	li	a4,1
ffffffffc0205276:	ef98                	sd	a4,24(a5)
    }
}
ffffffffc0205278:	8082                	ret

ffffffffc020527a <sched_init>:

void sched_init(void)
{
    list_init(&timer_list);

    sched_class = &default_sched_class;
ffffffffc020527a:	000ac797          	auipc	a5,0xac
ffffffffc020527e:	33e78793          	addi	a5,a5,830 # ffffffffc02b15b8 <default_sched_class>
{
ffffffffc0205282:	1141                	addi	sp,sp,-16

    rq = &__rq;
    rq->max_time_slice = MAX_TIME_SLICE;
    sched_class->init(rq);
ffffffffc0205284:	6794                	ld	a3,8(a5)
    sched_class = &default_sched_class;
ffffffffc0205286:	000b1717          	auipc	a4,0xb1
ffffffffc020528a:	84f73923          	sd	a5,-1966(a4) # ffffffffc02b5ad8 <sched_class>
{
ffffffffc020528e:	e406                	sd	ra,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0205290:	000b0797          	auipc	a5,0xb0
ffffffffc0205294:	7b078793          	addi	a5,a5,1968 # ffffffffc02b5a40 <timer_list>
    rq = &__rq;
ffffffffc0205298:	000b0717          	auipc	a4,0xb0
ffffffffc020529c:	78870713          	addi	a4,a4,1928 # ffffffffc02b5a20 <__rq>
    rq->max_time_slice = MAX_TIME_SLICE;
ffffffffc02052a0:	4615                	li	a2,5
ffffffffc02052a2:	e79c                	sd	a5,8(a5)
ffffffffc02052a4:	e39c                	sd	a5,0(a5)
    sched_class->init(rq);
ffffffffc02052a6:	853a                	mv	a0,a4
    rq->max_time_slice = MAX_TIME_SLICE;
ffffffffc02052a8:	cb50                	sw	a2,20(a4)
    rq = &__rq;
ffffffffc02052aa:	000b1797          	auipc	a5,0xb1
ffffffffc02052ae:	82e7b323          	sd	a4,-2010(a5) # ffffffffc02b5ad0 <rq>
    sched_class->init(rq);
ffffffffc02052b2:	9682                	jalr	a3

    cprintf("sched class: %s\n", sched_class->name);
ffffffffc02052b4:	000b1797          	auipc	a5,0xb1
ffffffffc02052b8:	8247b783          	ld	a5,-2012(a5) # ffffffffc02b5ad8 <sched_class>
}
ffffffffc02052bc:	60a2                	ld	ra,8(sp)
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc02052be:	00002517          	auipc	a0,0x2
ffffffffc02052c2:	42a50513          	addi	a0,a0,1066 # ffffffffc02076e8 <etext+0x1cb0>
ffffffffc02052c6:	638c                	ld	a1,0(a5)
}
ffffffffc02052c8:	0141                	addi	sp,sp,16
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc02052ca:	ecffa06f          	j	ffffffffc0200198 <cprintf>

ffffffffc02052ce <wakeup_proc>:

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02052ce:	4118                	lw	a4,0(a0)
{
ffffffffc02052d0:	1101                	addi	sp,sp,-32
ffffffffc02052d2:	ec06                	sd	ra,24(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02052d4:	478d                	li	a5,3
ffffffffc02052d6:	0cf70863          	beq	a4,a5,ffffffffc02053a6 <wakeup_proc+0xd8>
ffffffffc02052da:	85aa                	mv	a1,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02052dc:	100027f3          	csrr	a5,sstatus
ffffffffc02052e0:	8b89                	andi	a5,a5,2
ffffffffc02052e2:	e3b1                	bnez	a5,ffffffffc0205326 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc02052e4:	4789                	li	a5,2
ffffffffc02052e6:	08f70563          	beq	a4,a5,ffffffffc0205370 <wakeup_proc+0xa2>
        {
            proc->state = PROC_RUNNABLE;
            proc->wait_state = 0;
            if (proc != current)
ffffffffc02052ea:	000b0717          	auipc	a4,0xb0
ffffffffc02052ee:	7ce73703          	ld	a4,1998(a4) # ffffffffc02b5ab8 <current>
            proc->wait_state = 0;
ffffffffc02052f2:	0e052623          	sw	zero,236(a0)
            proc->state = PROC_RUNNABLE;
ffffffffc02052f6:	c11c                	sw	a5,0(a0)
            if (proc != current)
ffffffffc02052f8:	02e50463          	beq	a0,a4,ffffffffc0205320 <wakeup_proc+0x52>
    if (proc != idleproc)
ffffffffc02052fc:	000b0797          	auipc	a5,0xb0
ffffffffc0205300:	7cc7b783          	ld	a5,1996(a5) # ffffffffc02b5ac8 <idleproc>
ffffffffc0205304:	00f50e63          	beq	a0,a5,ffffffffc0205320 <wakeup_proc+0x52>
        sched_class->enqueue(rq, proc);
ffffffffc0205308:	000b0797          	auipc	a5,0xb0
ffffffffc020530c:	7d07b783          	ld	a5,2000(a5) # ffffffffc02b5ad8 <sched_class>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205310:	60e2                	ld	ra,24(sp)
        sched_class->enqueue(rq, proc);
ffffffffc0205312:	000b0517          	auipc	a0,0xb0
ffffffffc0205316:	7be53503          	ld	a0,1982(a0) # ffffffffc02b5ad0 <rq>
ffffffffc020531a:	6b9c                	ld	a5,16(a5)
}
ffffffffc020531c:	6105                	addi	sp,sp,32
        sched_class->enqueue(rq, proc);
ffffffffc020531e:	8782                	jr	a5
}
ffffffffc0205320:	60e2                	ld	ra,24(sp)
ffffffffc0205322:	6105                	addi	sp,sp,32
ffffffffc0205324:	8082                	ret
        intr_disable();
ffffffffc0205326:	e42a                	sd	a0,8(sp)
ffffffffc0205328:	dd6fb0ef          	jal	ffffffffc02008fe <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc020532c:	65a2                	ld	a1,8(sp)
ffffffffc020532e:	4789                	li	a5,2
ffffffffc0205330:	4198                	lw	a4,0(a1)
ffffffffc0205332:	04f70d63          	beq	a4,a5,ffffffffc020538c <wakeup_proc+0xbe>
            if (proc != current)
ffffffffc0205336:	000b0717          	auipc	a4,0xb0
ffffffffc020533a:	78273703          	ld	a4,1922(a4) # ffffffffc02b5ab8 <current>
            proc->wait_state = 0;
ffffffffc020533e:	0e05a623          	sw	zero,236(a1)
            proc->state = PROC_RUNNABLE;
ffffffffc0205342:	c19c                	sw	a5,0(a1)
            if (proc != current)
ffffffffc0205344:	02e58263          	beq	a1,a4,ffffffffc0205368 <wakeup_proc+0x9a>
    if (proc != idleproc)
ffffffffc0205348:	000b0797          	auipc	a5,0xb0
ffffffffc020534c:	7807b783          	ld	a5,1920(a5) # ffffffffc02b5ac8 <idleproc>
ffffffffc0205350:	00f58c63          	beq	a1,a5,ffffffffc0205368 <wakeup_proc+0x9a>
        sched_class->enqueue(rq, proc);
ffffffffc0205354:	000b0797          	auipc	a5,0xb0
ffffffffc0205358:	7847b783          	ld	a5,1924(a5) # ffffffffc02b5ad8 <sched_class>
ffffffffc020535c:	000b0517          	auipc	a0,0xb0
ffffffffc0205360:	77453503          	ld	a0,1908(a0) # ffffffffc02b5ad0 <rq>
ffffffffc0205364:	6b9c                	ld	a5,16(a5)
ffffffffc0205366:	9782                	jalr	a5
}
ffffffffc0205368:	60e2                	ld	ra,24(sp)
ffffffffc020536a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020536c:	d8cfb06f          	j	ffffffffc02008f8 <intr_enable>
ffffffffc0205370:	60e2                	ld	ra,24(sp)
            warn("wakeup runnable process.\n");
ffffffffc0205372:	00002617          	auipc	a2,0x2
ffffffffc0205376:	3c660613          	addi	a2,a2,966 # ffffffffc0207738 <etext+0x1d00>
ffffffffc020537a:	05100593          	li	a1,81
ffffffffc020537e:	00002517          	auipc	a0,0x2
ffffffffc0205382:	3a250513          	addi	a0,a0,930 # ffffffffc0207720 <etext+0x1ce8>
}
ffffffffc0205386:	6105                	addi	sp,sp,32
            warn("wakeup runnable process.\n");
ffffffffc0205388:	92cfb06f          	j	ffffffffc02004b4 <__warn>
ffffffffc020538c:	00002617          	auipc	a2,0x2
ffffffffc0205390:	3ac60613          	addi	a2,a2,940 # ffffffffc0207738 <etext+0x1d00>
ffffffffc0205394:	05100593          	li	a1,81
ffffffffc0205398:	00002517          	auipc	a0,0x2
ffffffffc020539c:	38850513          	addi	a0,a0,904 # ffffffffc0207720 <etext+0x1ce8>
ffffffffc02053a0:	914fb0ef          	jal	ffffffffc02004b4 <__warn>
    if (flag)
ffffffffc02053a4:	b7d1                	j	ffffffffc0205368 <wakeup_proc+0x9a>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02053a6:	00002697          	auipc	a3,0x2
ffffffffc02053aa:	35a68693          	addi	a3,a3,858 # ffffffffc0207700 <etext+0x1cc8>
ffffffffc02053ae:	00001617          	auipc	a2,0x1
ffffffffc02053b2:	0a260613          	addi	a2,a2,162 # ffffffffc0206450 <etext+0xa18>
ffffffffc02053b6:	04200593          	li	a1,66
ffffffffc02053ba:	00002517          	auipc	a0,0x2
ffffffffc02053be:	36650513          	addi	a0,a0,870 # ffffffffc0207720 <etext+0x1ce8>
ffffffffc02053c2:	888fb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02053c6 <schedule>:

void schedule(void)
{
ffffffffc02053c6:	7139                	addi	sp,sp,-64
ffffffffc02053c8:	fc06                	sd	ra,56(sp)
ffffffffc02053ca:	f822                	sd	s0,48(sp)
ffffffffc02053cc:	f426                	sd	s1,40(sp)
ffffffffc02053ce:	f04a                	sd	s2,32(sp)
ffffffffc02053d0:	ec4e                	sd	s3,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02053d2:	100027f3          	csrr	a5,sstatus
ffffffffc02053d6:	8b89                	andi	a5,a5,2
ffffffffc02053d8:	4981                	li	s3,0
ffffffffc02053da:	efc9                	bnez	a5,ffffffffc0205474 <schedule+0xae>
    bool intr_flag;
    struct proc_struct *next;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc02053dc:	000b0417          	auipc	s0,0xb0
ffffffffc02053e0:	6dc40413          	addi	s0,s0,1756 # ffffffffc02b5ab8 <current>
ffffffffc02053e4:	600c                	ld	a1,0(s0)
        if (current->state == PROC_RUNNABLE)
ffffffffc02053e6:	4789                	li	a5,2
ffffffffc02053e8:	000b0497          	auipc	s1,0xb0
ffffffffc02053ec:	6e848493          	addi	s1,s1,1768 # ffffffffc02b5ad0 <rq>
ffffffffc02053f0:	4198                	lw	a4,0(a1)
        current->need_resched = 0;
ffffffffc02053f2:	0005bc23          	sd	zero,24(a1)
        if (current->state == PROC_RUNNABLE)
ffffffffc02053f6:	000b0917          	auipc	s2,0xb0
ffffffffc02053fa:	6e290913          	addi	s2,s2,1762 # ffffffffc02b5ad8 <sched_class>
ffffffffc02053fe:	04f70f63          	beq	a4,a5,ffffffffc020545c <schedule+0x96>
    return sched_class->pick_next(rq);
ffffffffc0205402:	00093783          	ld	a5,0(s2)
ffffffffc0205406:	6088                	ld	a0,0(s1)
ffffffffc0205408:	739c                	ld	a5,32(a5)
ffffffffc020540a:	9782                	jalr	a5
ffffffffc020540c:	85aa                	mv	a1,a0
        {
            sched_class_enqueue(current);
        }
        if ((next = sched_class_pick_next()) != NULL)
ffffffffc020540e:	c131                	beqz	a0,ffffffffc0205452 <schedule+0x8c>
    sched_class->dequeue(rq, proc);
ffffffffc0205410:	00093783          	ld	a5,0(s2)
ffffffffc0205414:	6088                	ld	a0,0(s1)
ffffffffc0205416:	e42e                	sd	a1,8(sp)
ffffffffc0205418:	6f9c                	ld	a5,24(a5)
ffffffffc020541a:	9782                	jalr	a5
ffffffffc020541c:	65a2                	ld	a1,8(sp)
        }
        if (next == NULL)
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc020541e:	459c                	lw	a5,8(a1)
        if (next != current)
ffffffffc0205420:	6018                	ld	a4,0(s0)
        next->runs++;
ffffffffc0205422:	2785                	addiw	a5,a5,1
ffffffffc0205424:	c59c                	sw	a5,8(a1)
        if (next != current)
ffffffffc0205426:	00b70563          	beq	a4,a1,ffffffffc0205430 <schedule+0x6a>
        {
            proc_run(next);
ffffffffc020542a:	852e                	mv	a0,a1
ffffffffc020542c:	a6dfe0ef          	jal	ffffffffc0203e98 <proc_run>
    if (flag)
ffffffffc0205430:	00099963          	bnez	s3,ffffffffc0205442 <schedule+0x7c>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205434:	70e2                	ld	ra,56(sp)
ffffffffc0205436:	7442                	ld	s0,48(sp)
ffffffffc0205438:	74a2                	ld	s1,40(sp)
ffffffffc020543a:	7902                	ld	s2,32(sp)
ffffffffc020543c:	69e2                	ld	s3,24(sp)
ffffffffc020543e:	6121                	addi	sp,sp,64
ffffffffc0205440:	8082                	ret
ffffffffc0205442:	7442                	ld	s0,48(sp)
ffffffffc0205444:	70e2                	ld	ra,56(sp)
ffffffffc0205446:	74a2                	ld	s1,40(sp)
ffffffffc0205448:	7902                	ld	s2,32(sp)
ffffffffc020544a:	69e2                	ld	s3,24(sp)
ffffffffc020544c:	6121                	addi	sp,sp,64
        intr_enable();
ffffffffc020544e:	caafb06f          	j	ffffffffc02008f8 <intr_enable>
            next = idleproc;
ffffffffc0205452:	000b0597          	auipc	a1,0xb0
ffffffffc0205456:	6765b583          	ld	a1,1654(a1) # ffffffffc02b5ac8 <idleproc>
ffffffffc020545a:	b7d1                	j	ffffffffc020541e <schedule+0x58>
    if (proc != idleproc)
ffffffffc020545c:	000b0797          	auipc	a5,0xb0
ffffffffc0205460:	66c7b783          	ld	a5,1644(a5) # ffffffffc02b5ac8 <idleproc>
ffffffffc0205464:	f8f58fe3          	beq	a1,a5,ffffffffc0205402 <schedule+0x3c>
        sched_class->enqueue(rq, proc);
ffffffffc0205468:	00093783          	ld	a5,0(s2)
ffffffffc020546c:	6088                	ld	a0,0(s1)
ffffffffc020546e:	6b9c                	ld	a5,16(a5)
ffffffffc0205470:	9782                	jalr	a5
ffffffffc0205472:	bf41                	j	ffffffffc0205402 <schedule+0x3c>
        intr_disable();
ffffffffc0205474:	c8afb0ef          	jal	ffffffffc02008fe <intr_disable>
        return 1;
ffffffffc0205478:	4985                	li	s3,1
ffffffffc020547a:	b78d                	j	ffffffffc02053dc <schedule+0x16>

ffffffffc020547c <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc020547c:	000b0797          	auipc	a5,0xb0
ffffffffc0205480:	63c7b783          	ld	a5,1596(a5) # ffffffffc02b5ab8 <current>
}
ffffffffc0205484:	43c8                	lw	a0,4(a5)
ffffffffc0205486:	8082                	ret

ffffffffc0205488 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0205488:	4501                	li	a0,0
ffffffffc020548a:	8082                	ret

ffffffffc020548c <sys_gettime>:
static int sys_gettime(uint64_t arg[]){
    return (int)ticks*10;
ffffffffc020548c:	000b0797          	auipc	a5,0xb0
ffffffffc0205490:	5cc7b783          	ld	a5,1484(a5) # ffffffffc02b5a58 <ticks>
ffffffffc0205494:	0027951b          	slliw	a0,a5,0x2
ffffffffc0205498:	9d3d                	addw	a0,a0,a5
ffffffffc020549a:	0015151b          	slliw	a0,a0,0x1
}
ffffffffc020549e:	8082                	ret

ffffffffc02054a0 <sys_lab6_set_priority>:
static int sys_lab6_set_priority(uint64_t arg[]){
    uint64_t priority = (uint64_t)arg[0];
    lab6_set_priority(priority);
ffffffffc02054a0:	4108                	lw	a0,0(a0)
static int sys_lab6_set_priority(uint64_t arg[]){
ffffffffc02054a2:	1141                	addi	sp,sp,-16
ffffffffc02054a4:	e406                	sd	ra,8(sp)
    lab6_set_priority(priority);
ffffffffc02054a6:	c1fff0ef          	jal	ffffffffc02050c4 <lab6_set_priority>
    return 0;
}
ffffffffc02054aa:	60a2                	ld	ra,8(sp)
ffffffffc02054ac:	4501                	li	a0,0
ffffffffc02054ae:	0141                	addi	sp,sp,16
ffffffffc02054b0:	8082                	ret

ffffffffc02054b2 <sys_putc>:
    cputchar(c);
ffffffffc02054b2:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc02054b4:	1141                	addi	sp,sp,-16
ffffffffc02054b6:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc02054b8:	d15fa0ef          	jal	ffffffffc02001cc <cputchar>
}
ffffffffc02054bc:	60a2                	ld	ra,8(sp)
ffffffffc02054be:	4501                	li	a0,0
ffffffffc02054c0:	0141                	addi	sp,sp,16
ffffffffc02054c2:	8082                	ret

ffffffffc02054c4 <sys_kill>:
    return do_kill(pid);
ffffffffc02054c4:	4108                	lw	a0,0(a0)
ffffffffc02054c6:	9cdff06f          	j	ffffffffc0204e92 <do_kill>

ffffffffc02054ca <sys_yield>:
    return do_yield();
ffffffffc02054ca:	97fff06f          	j	ffffffffc0204e48 <do_yield>

ffffffffc02054ce <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc02054ce:	6d14                	ld	a3,24(a0)
ffffffffc02054d0:	6910                	ld	a2,16(a0)
ffffffffc02054d2:	650c                	ld	a1,8(a0)
ffffffffc02054d4:	6108                	ld	a0,0(a0)
ffffffffc02054d6:	b46ff06f          	j	ffffffffc020481c <do_execve>

ffffffffc02054da <sys_wait>:
    return do_wait(pid, store);
ffffffffc02054da:	650c                	ld	a1,8(a0)
ffffffffc02054dc:	4108                	lw	a0,0(a0)
ffffffffc02054de:	97bff06f          	j	ffffffffc0204e58 <do_wait>

ffffffffc02054e2 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc02054e2:	000b0797          	auipc	a5,0xb0
ffffffffc02054e6:	5d67b783          	ld	a5,1494(a5) # ffffffffc02b5ab8 <current>
    return do_fork(0, stack, tf);
ffffffffc02054ea:	4501                	li	a0,0
    struct trapframe *tf = current->tf;
ffffffffc02054ec:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc02054ee:	6a0c                	ld	a1,16(a2)
ffffffffc02054f0:	a4dfe06f          	j	ffffffffc0203f3c <do_fork>

ffffffffc02054f4 <sys_exit>:
    return do_exit(error_code);
ffffffffc02054f4:	4108                	lw	a0,0(a0)
ffffffffc02054f6:	eddfe06f          	j	ffffffffc02043d2 <do_exit>

ffffffffc02054fa <syscall>:

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
    struct trapframe *tf = current->tf;
ffffffffc02054fa:	000b0697          	auipc	a3,0xb0
ffffffffc02054fe:	5be6b683          	ld	a3,1470(a3) # ffffffffc02b5ab8 <current>
syscall(void) {
ffffffffc0205502:	715d                	addi	sp,sp,-80
ffffffffc0205504:	e0a2                	sd	s0,64(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205506:	72c0                	ld	s0,160(a3)
syscall(void) {
ffffffffc0205508:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020550a:	0ff00793          	li	a5,255
    int num = tf->gpr.a0;
ffffffffc020550e:	4834                	lw	a3,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205510:	02d7ec63          	bltu	a5,a3,ffffffffc0205548 <syscall+0x4e>
        if (syscalls[num] != NULL) {
ffffffffc0205514:	00002797          	auipc	a5,0x2
ffffffffc0205518:	46c78793          	addi	a5,a5,1132 # ffffffffc0207980 <syscalls>
ffffffffc020551c:	00369613          	slli	a2,a3,0x3
ffffffffc0205520:	97b2                	add	a5,a5,a2
ffffffffc0205522:	639c                	ld	a5,0(a5)
ffffffffc0205524:	c395                	beqz	a5,ffffffffc0205548 <syscall+0x4e>
            arg[0] = tf->gpr.a1;
ffffffffc0205526:	7028                	ld	a0,96(s0)
ffffffffc0205528:	742c                	ld	a1,104(s0)
ffffffffc020552a:	7830                	ld	a2,112(s0)
ffffffffc020552c:	7c34                	ld	a3,120(s0)
ffffffffc020552e:	6c38                	ld	a4,88(s0)
ffffffffc0205530:	f02a                	sd	a0,32(sp)
ffffffffc0205532:	f42e                	sd	a1,40(sp)
ffffffffc0205534:	f832                	sd	a2,48(sp)
ffffffffc0205536:	fc36                	sd	a3,56(sp)
ffffffffc0205538:	ec3a                	sd	a4,24(sp)
            arg[1] = tf->gpr.a2;
            arg[2] = tf->gpr.a3;
            arg[3] = tf->gpr.a4;
            arg[4] = tf->gpr.a5;
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc020553a:	0828                	addi	a0,sp,24
ffffffffc020553c:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc020553e:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205540:	e828                	sd	a0,80(s0)
}
ffffffffc0205542:	6406                	ld	s0,64(sp)
ffffffffc0205544:	6161                	addi	sp,sp,80
ffffffffc0205546:	8082                	ret
    print_trapframe(tf);
ffffffffc0205548:	8522                	mv	a0,s0
ffffffffc020554a:	e436                	sd	a3,8(sp)
ffffffffc020554c:	da2fb0ef          	jal	ffffffffc0200aee <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc0205550:	000b0797          	auipc	a5,0xb0
ffffffffc0205554:	5687b783          	ld	a5,1384(a5) # ffffffffc02b5ab8 <current>
ffffffffc0205558:	66a2                	ld	a3,8(sp)
ffffffffc020555a:	00002617          	auipc	a2,0x2
ffffffffc020555e:	1fe60613          	addi	a2,a2,510 # ffffffffc0207758 <etext+0x1d20>
ffffffffc0205562:	43d8                	lw	a4,4(a5)
ffffffffc0205564:	06c00593          	li	a1,108
ffffffffc0205568:	0b478793          	addi	a5,a5,180
ffffffffc020556c:	00002517          	auipc	a0,0x2
ffffffffc0205570:	21c50513          	addi	a0,a0,540 # ffffffffc0207788 <etext+0x1d50>
ffffffffc0205574:	ed7fa0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0205578 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0205578:	9e3707b7          	lui	a5,0x9e370
ffffffffc020557c:	2785                	addiw	a5,a5,1 # ffffffff9e370001 <_binary_obj___user_matrix_out_size+0xffffffff9e364a81>
ffffffffc020557e:	02a787bb          	mulw	a5,a5,a0
    return (hash >> (32 - bits));
ffffffffc0205582:	02000513          	li	a0,32
ffffffffc0205586:	9d0d                	subw	a0,a0,a1
}
ffffffffc0205588:	00a7d53b          	srlw	a0,a5,a0
ffffffffc020558c:	8082                	ret

ffffffffc020558e <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020558e:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0205590:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205594:	f022                	sd	s0,32(sp)
ffffffffc0205596:	ec26                	sd	s1,24(sp)
ffffffffc0205598:	e84a                	sd	s2,16(sp)
ffffffffc020559a:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020559c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02055a0:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc02055a2:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02055a6:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02055aa:	84aa                	mv	s1,a0
ffffffffc02055ac:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc02055ae:	03067d63          	bgeu	a2,a6,ffffffffc02055e8 <printnum+0x5a>
ffffffffc02055b2:	e44e                	sd	s3,8(sp)
ffffffffc02055b4:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02055b6:	4785                	li	a5,1
ffffffffc02055b8:	00e7d763          	bge	a5,a4,ffffffffc02055c6 <printnum+0x38>
            putch(padc, putdat);
ffffffffc02055bc:	85ca                	mv	a1,s2
ffffffffc02055be:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc02055c0:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02055c2:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02055c4:	fc65                	bnez	s0,ffffffffc02055bc <printnum+0x2e>
ffffffffc02055c6:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02055c8:	00002797          	auipc	a5,0x2
ffffffffc02055cc:	1d878793          	addi	a5,a5,472 # ffffffffc02077a0 <etext+0x1d68>
ffffffffc02055d0:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc02055d2:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02055d4:	0007c503          	lbu	a0,0(a5)
}
ffffffffc02055d8:	70a2                	ld	ra,40(sp)
ffffffffc02055da:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02055dc:	85ca                	mv	a1,s2
ffffffffc02055de:	87a6                	mv	a5,s1
}
ffffffffc02055e0:	6942                	ld	s2,16(sp)
ffffffffc02055e2:	64e2                	ld	s1,24(sp)
ffffffffc02055e4:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02055e6:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02055e8:	03065633          	divu	a2,a2,a6
ffffffffc02055ec:	8722                	mv	a4,s0
ffffffffc02055ee:	fa1ff0ef          	jal	ffffffffc020558e <printnum>
ffffffffc02055f2:	bfd9                	j	ffffffffc02055c8 <printnum+0x3a>

ffffffffc02055f4 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02055f4:	7119                	addi	sp,sp,-128
ffffffffc02055f6:	f4a6                	sd	s1,104(sp)
ffffffffc02055f8:	f0ca                	sd	s2,96(sp)
ffffffffc02055fa:	ecce                	sd	s3,88(sp)
ffffffffc02055fc:	e8d2                	sd	s4,80(sp)
ffffffffc02055fe:	e4d6                	sd	s5,72(sp)
ffffffffc0205600:	e0da                	sd	s6,64(sp)
ffffffffc0205602:	f862                	sd	s8,48(sp)
ffffffffc0205604:	fc86                	sd	ra,120(sp)
ffffffffc0205606:	f8a2                	sd	s0,112(sp)
ffffffffc0205608:	fc5e                	sd	s7,56(sp)
ffffffffc020560a:	f466                	sd	s9,40(sp)
ffffffffc020560c:	f06a                	sd	s10,32(sp)
ffffffffc020560e:	ec6e                	sd	s11,24(sp)
ffffffffc0205610:	84aa                	mv	s1,a0
ffffffffc0205612:	8c32                	mv	s8,a2
ffffffffc0205614:	8a36                	mv	s4,a3
ffffffffc0205616:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205618:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020561c:	05500b13          	li	s6,85
ffffffffc0205620:	00003a97          	auipc	s5,0x3
ffffffffc0205624:	b60a8a93          	addi	s5,s5,-1184 # ffffffffc0208180 <syscalls+0x800>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205628:	000c4503          	lbu	a0,0(s8)
ffffffffc020562c:	001c0413          	addi	s0,s8,1
ffffffffc0205630:	01350a63          	beq	a0,s3,ffffffffc0205644 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0205634:	cd0d                	beqz	a0,ffffffffc020566e <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0205636:	85ca                	mv	a1,s2
ffffffffc0205638:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020563a:	00044503          	lbu	a0,0(s0)
ffffffffc020563e:	0405                	addi	s0,s0,1
ffffffffc0205640:	ff351ae3          	bne	a0,s3,ffffffffc0205634 <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0205644:	5cfd                	li	s9,-1
ffffffffc0205646:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc0205648:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc020564c:	4b81                	li	s7,0
ffffffffc020564e:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205650:	00044683          	lbu	a3,0(s0)
ffffffffc0205654:	00140c13          	addi	s8,s0,1
ffffffffc0205658:	fdd6859b          	addiw	a1,a3,-35
ffffffffc020565c:	0ff5f593          	zext.b	a1,a1
ffffffffc0205660:	02bb6663          	bltu	s6,a1,ffffffffc020568c <vprintfmt+0x98>
ffffffffc0205664:	058a                	slli	a1,a1,0x2
ffffffffc0205666:	95d6                	add	a1,a1,s5
ffffffffc0205668:	4198                	lw	a4,0(a1)
ffffffffc020566a:	9756                	add	a4,a4,s5
ffffffffc020566c:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020566e:	70e6                	ld	ra,120(sp)
ffffffffc0205670:	7446                	ld	s0,112(sp)
ffffffffc0205672:	74a6                	ld	s1,104(sp)
ffffffffc0205674:	7906                	ld	s2,96(sp)
ffffffffc0205676:	69e6                	ld	s3,88(sp)
ffffffffc0205678:	6a46                	ld	s4,80(sp)
ffffffffc020567a:	6aa6                	ld	s5,72(sp)
ffffffffc020567c:	6b06                	ld	s6,64(sp)
ffffffffc020567e:	7be2                	ld	s7,56(sp)
ffffffffc0205680:	7c42                	ld	s8,48(sp)
ffffffffc0205682:	7ca2                	ld	s9,40(sp)
ffffffffc0205684:	7d02                	ld	s10,32(sp)
ffffffffc0205686:	6de2                	ld	s11,24(sp)
ffffffffc0205688:	6109                	addi	sp,sp,128
ffffffffc020568a:	8082                	ret
            putch('%', putdat);
ffffffffc020568c:	85ca                	mv	a1,s2
ffffffffc020568e:	02500513          	li	a0,37
ffffffffc0205692:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0205694:	fff44783          	lbu	a5,-1(s0)
ffffffffc0205698:	02500713          	li	a4,37
ffffffffc020569c:	8c22                	mv	s8,s0
ffffffffc020569e:	f8e785e3          	beq	a5,a4,ffffffffc0205628 <vprintfmt+0x34>
ffffffffc02056a2:	ffec4783          	lbu	a5,-2(s8)
ffffffffc02056a6:	1c7d                	addi	s8,s8,-1
ffffffffc02056a8:	fee79de3          	bne	a5,a4,ffffffffc02056a2 <vprintfmt+0xae>
ffffffffc02056ac:	bfb5                	j	ffffffffc0205628 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc02056ae:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc02056b2:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc02056b4:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc02056b8:	fd06071b          	addiw	a4,a2,-48
ffffffffc02056bc:	24e56a63          	bltu	a0,a4,ffffffffc0205910 <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc02056c0:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02056c2:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc02056c4:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc02056c8:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02056cc:	0197073b          	addw	a4,a4,s9
ffffffffc02056d0:	0017171b          	slliw	a4,a4,0x1
ffffffffc02056d4:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc02056d6:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02056da:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02056dc:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc02056e0:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc02056e4:	feb570e3          	bgeu	a0,a1,ffffffffc02056c4 <vprintfmt+0xd0>
            if (width < 0)
ffffffffc02056e8:	f60d54e3          	bgez	s10,ffffffffc0205650 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc02056ec:	8d66                	mv	s10,s9
ffffffffc02056ee:	5cfd                	li	s9,-1
ffffffffc02056f0:	b785                	j	ffffffffc0205650 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02056f2:	8db6                	mv	s11,a3
ffffffffc02056f4:	8462                	mv	s0,s8
ffffffffc02056f6:	bfa9                	j	ffffffffc0205650 <vprintfmt+0x5c>
ffffffffc02056f8:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc02056fa:	4b85                	li	s7,1
            goto reswitch;
ffffffffc02056fc:	bf91                	j	ffffffffc0205650 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc02056fe:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205700:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205704:	00f74463          	blt	a4,a5,ffffffffc020570c <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0205708:	1a078763          	beqz	a5,ffffffffc02058b6 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc020570c:	000a3603          	ld	a2,0(s4)
ffffffffc0205710:	46c1                	li	a3,16
ffffffffc0205712:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0205714:	000d879b          	sext.w	a5,s11
ffffffffc0205718:	876a                	mv	a4,s10
ffffffffc020571a:	85ca                	mv	a1,s2
ffffffffc020571c:	8526                	mv	a0,s1
ffffffffc020571e:	e71ff0ef          	jal	ffffffffc020558e <printnum>
            break;
ffffffffc0205722:	b719                	j	ffffffffc0205628 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0205724:	000a2503          	lw	a0,0(s4)
ffffffffc0205728:	85ca                	mv	a1,s2
ffffffffc020572a:	0a21                	addi	s4,s4,8
ffffffffc020572c:	9482                	jalr	s1
            break;
ffffffffc020572e:	bded                	j	ffffffffc0205628 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0205730:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205732:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205736:	00f74463          	blt	a4,a5,ffffffffc020573e <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc020573a:	16078963          	beqz	a5,ffffffffc02058ac <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc020573e:	000a3603          	ld	a2,0(s4)
ffffffffc0205742:	46a9                	li	a3,10
ffffffffc0205744:	8a2e                	mv	s4,a1
ffffffffc0205746:	b7f9                	j	ffffffffc0205714 <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc0205748:	85ca                	mv	a1,s2
ffffffffc020574a:	03000513          	li	a0,48
ffffffffc020574e:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc0205750:	85ca                	mv	a1,s2
ffffffffc0205752:	07800513          	li	a0,120
ffffffffc0205756:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205758:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc020575c:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020575e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0205760:	bf55                	j	ffffffffc0205714 <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc0205762:	85ca                	mv	a1,s2
ffffffffc0205764:	02500513          	li	a0,37
ffffffffc0205768:	9482                	jalr	s1
            break;
ffffffffc020576a:	bd7d                	j	ffffffffc0205628 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc020576c:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205770:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0205772:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0205774:	bf95                	j	ffffffffc02056e8 <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc0205776:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205778:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020577c:	00f74463          	blt	a4,a5,ffffffffc0205784 <vprintfmt+0x190>
    else if (lflag) {
ffffffffc0205780:	12078163          	beqz	a5,ffffffffc02058a2 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc0205784:	000a3603          	ld	a2,0(s4)
ffffffffc0205788:	46a1                	li	a3,8
ffffffffc020578a:	8a2e                	mv	s4,a1
ffffffffc020578c:	b761                	j	ffffffffc0205714 <vprintfmt+0x120>
            if (width < 0)
ffffffffc020578e:	876a                	mv	a4,s10
ffffffffc0205790:	000d5363          	bgez	s10,ffffffffc0205796 <vprintfmt+0x1a2>
ffffffffc0205794:	4701                	li	a4,0
ffffffffc0205796:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020579a:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc020579c:	bd55                	j	ffffffffc0205650 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc020579e:	000d841b          	sext.w	s0,s11
ffffffffc02057a2:	fd340793          	addi	a5,s0,-45
ffffffffc02057a6:	00f037b3          	snez	a5,a5
ffffffffc02057aa:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02057ae:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc02057b2:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02057b4:	008a0793          	addi	a5,s4,8
ffffffffc02057b8:	e43e                	sd	a5,8(sp)
ffffffffc02057ba:	100d8c63          	beqz	s11,ffffffffc02058d2 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc02057be:	12071363          	bnez	a4,ffffffffc02058e4 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02057c2:	000dc783          	lbu	a5,0(s11)
ffffffffc02057c6:	0007851b          	sext.w	a0,a5
ffffffffc02057ca:	c78d                	beqz	a5,ffffffffc02057f4 <vprintfmt+0x200>
ffffffffc02057cc:	0d85                	addi	s11,s11,1
ffffffffc02057ce:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02057d0:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02057d4:	000cc563          	bltz	s9,ffffffffc02057de <vprintfmt+0x1ea>
ffffffffc02057d8:	3cfd                	addiw	s9,s9,-1
ffffffffc02057da:	008c8d63          	beq	s9,s0,ffffffffc02057f4 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02057de:	020b9663          	bnez	s7,ffffffffc020580a <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc02057e2:	85ca                	mv	a1,s2
ffffffffc02057e4:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02057e6:	000dc783          	lbu	a5,0(s11)
ffffffffc02057ea:	0d85                	addi	s11,s11,1
ffffffffc02057ec:	3d7d                	addiw	s10,s10,-1
ffffffffc02057ee:	0007851b          	sext.w	a0,a5
ffffffffc02057f2:	f3ed                	bnez	a5,ffffffffc02057d4 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc02057f4:	01a05963          	blez	s10,ffffffffc0205806 <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc02057f8:	85ca                	mv	a1,s2
ffffffffc02057fa:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc02057fe:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0205800:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc0205802:	fe0d1be3          	bnez	s10,ffffffffc02057f8 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205806:	6a22                	ld	s4,8(sp)
ffffffffc0205808:	b505                	j	ffffffffc0205628 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020580a:	3781                	addiw	a5,a5,-32
ffffffffc020580c:	fcfa7be3          	bgeu	s4,a5,ffffffffc02057e2 <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0205810:	03f00513          	li	a0,63
ffffffffc0205814:	85ca                	mv	a1,s2
ffffffffc0205816:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205818:	000dc783          	lbu	a5,0(s11)
ffffffffc020581c:	0d85                	addi	s11,s11,1
ffffffffc020581e:	3d7d                	addiw	s10,s10,-1
ffffffffc0205820:	0007851b          	sext.w	a0,a5
ffffffffc0205824:	dbe1                	beqz	a5,ffffffffc02057f4 <vprintfmt+0x200>
ffffffffc0205826:	fa0cd9e3          	bgez	s9,ffffffffc02057d8 <vprintfmt+0x1e4>
ffffffffc020582a:	b7c5                	j	ffffffffc020580a <vprintfmt+0x216>
            if (err < 0) {
ffffffffc020582c:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205830:	4661                	li	a2,24
            err = va_arg(ap, int);
ffffffffc0205832:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0205834:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0205838:	8fb9                	xor	a5,a5,a4
ffffffffc020583a:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020583e:	02d64563          	blt	a2,a3,ffffffffc0205868 <vprintfmt+0x274>
ffffffffc0205842:	00003797          	auipc	a5,0x3
ffffffffc0205846:	a9678793          	addi	a5,a5,-1386 # ffffffffc02082d8 <error_string>
ffffffffc020584a:	00369713          	slli	a4,a3,0x3
ffffffffc020584e:	97ba                	add	a5,a5,a4
ffffffffc0205850:	639c                	ld	a5,0(a5)
ffffffffc0205852:	cb99                	beqz	a5,ffffffffc0205868 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc0205854:	86be                	mv	a3,a5
ffffffffc0205856:	00000617          	auipc	a2,0x0
ffffffffc020585a:	20a60613          	addi	a2,a2,522 # ffffffffc0205a60 <etext+0x28>
ffffffffc020585e:	85ca                	mv	a1,s2
ffffffffc0205860:	8526                	mv	a0,s1
ffffffffc0205862:	0d8000ef          	jal	ffffffffc020593a <printfmt>
ffffffffc0205866:	b3c9                	j	ffffffffc0205628 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0205868:	00002617          	auipc	a2,0x2
ffffffffc020586c:	f5860613          	addi	a2,a2,-168 # ffffffffc02077c0 <etext+0x1d88>
ffffffffc0205870:	85ca                	mv	a1,s2
ffffffffc0205872:	8526                	mv	a0,s1
ffffffffc0205874:	0c6000ef          	jal	ffffffffc020593a <printfmt>
ffffffffc0205878:	bb45                	j	ffffffffc0205628 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc020587a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020587c:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0205880:	00f74363          	blt	a4,a5,ffffffffc0205886 <vprintfmt+0x292>
    else if (lflag) {
ffffffffc0205884:	cf81                	beqz	a5,ffffffffc020589c <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc0205886:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020588a:	02044b63          	bltz	s0,ffffffffc02058c0 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc020588e:	8622                	mv	a2,s0
ffffffffc0205890:	8a5e                	mv	s4,s7
ffffffffc0205892:	46a9                	li	a3,10
ffffffffc0205894:	b541                	j	ffffffffc0205714 <vprintfmt+0x120>
            lflag ++;
ffffffffc0205896:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205898:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc020589a:	bb5d                	j	ffffffffc0205650 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc020589c:	000a2403          	lw	s0,0(s4)
ffffffffc02058a0:	b7ed                	j	ffffffffc020588a <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc02058a2:	000a6603          	lwu	a2,0(s4)
ffffffffc02058a6:	46a1                	li	a3,8
ffffffffc02058a8:	8a2e                	mv	s4,a1
ffffffffc02058aa:	b5ad                	j	ffffffffc0205714 <vprintfmt+0x120>
ffffffffc02058ac:	000a6603          	lwu	a2,0(s4)
ffffffffc02058b0:	46a9                	li	a3,10
ffffffffc02058b2:	8a2e                	mv	s4,a1
ffffffffc02058b4:	b585                	j	ffffffffc0205714 <vprintfmt+0x120>
ffffffffc02058b6:	000a6603          	lwu	a2,0(s4)
ffffffffc02058ba:	46c1                	li	a3,16
ffffffffc02058bc:	8a2e                	mv	s4,a1
ffffffffc02058be:	bd99                	j	ffffffffc0205714 <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc02058c0:	85ca                	mv	a1,s2
ffffffffc02058c2:	02d00513          	li	a0,45
ffffffffc02058c6:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc02058c8:	40800633          	neg	a2,s0
ffffffffc02058cc:	8a5e                	mv	s4,s7
ffffffffc02058ce:	46a9                	li	a3,10
ffffffffc02058d0:	b591                	j	ffffffffc0205714 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc02058d2:	e329                	bnez	a4,ffffffffc0205914 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02058d4:	02800793          	li	a5,40
ffffffffc02058d8:	853e                	mv	a0,a5
ffffffffc02058da:	00002d97          	auipc	s11,0x2
ffffffffc02058de:	edfd8d93          	addi	s11,s11,-289 # ffffffffc02077b9 <etext+0x1d81>
ffffffffc02058e2:	b5f5                	j	ffffffffc02057ce <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02058e4:	85e6                	mv	a1,s9
ffffffffc02058e6:	856e                	mv	a0,s11
ffffffffc02058e8:	08a000ef          	jal	ffffffffc0205972 <strnlen>
ffffffffc02058ec:	40ad0d3b          	subw	s10,s10,a0
ffffffffc02058f0:	01a05863          	blez	s10,ffffffffc0205900 <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc02058f4:	85ca                	mv	a1,s2
ffffffffc02058f6:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02058f8:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc02058fa:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02058fc:	fe0d1ce3          	bnez	s10,ffffffffc02058f4 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205900:	000dc783          	lbu	a5,0(s11)
ffffffffc0205904:	0007851b          	sext.w	a0,a5
ffffffffc0205908:	ec0792e3          	bnez	a5,ffffffffc02057cc <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020590c:	6a22                	ld	s4,8(sp)
ffffffffc020590e:	bb29                	j	ffffffffc0205628 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205910:	8462                	mv	s0,s8
ffffffffc0205912:	bbd9                	j	ffffffffc02056e8 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205914:	85e6                	mv	a1,s9
ffffffffc0205916:	00002517          	auipc	a0,0x2
ffffffffc020591a:	ea250513          	addi	a0,a0,-350 # ffffffffc02077b8 <etext+0x1d80>
ffffffffc020591e:	054000ef          	jal	ffffffffc0205972 <strnlen>
ffffffffc0205922:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205926:	02800793          	li	a5,40
                p = "(null)";
ffffffffc020592a:	00002d97          	auipc	s11,0x2
ffffffffc020592e:	e8ed8d93          	addi	s11,s11,-370 # ffffffffc02077b8 <etext+0x1d80>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205932:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205934:	fda040e3          	bgtz	s10,ffffffffc02058f4 <vprintfmt+0x300>
ffffffffc0205938:	bd51                	j	ffffffffc02057cc <vprintfmt+0x1d8>

ffffffffc020593a <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020593a:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020593c:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205940:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205942:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205944:	ec06                	sd	ra,24(sp)
ffffffffc0205946:	f83a                	sd	a4,48(sp)
ffffffffc0205948:	fc3e                	sd	a5,56(sp)
ffffffffc020594a:	e0c2                	sd	a6,64(sp)
ffffffffc020594c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020594e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205950:	ca5ff0ef          	jal	ffffffffc02055f4 <vprintfmt>
}
ffffffffc0205954:	60e2                	ld	ra,24(sp)
ffffffffc0205956:	6161                	addi	sp,sp,80
ffffffffc0205958:	8082                	ret

ffffffffc020595a <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc020595a:	00054783          	lbu	a5,0(a0)
ffffffffc020595e:	cb81                	beqz	a5,ffffffffc020596e <strlen+0x14>
    size_t cnt = 0;
ffffffffc0205960:	4781                	li	a5,0
        cnt ++;
ffffffffc0205962:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0205964:	00f50733          	add	a4,a0,a5
ffffffffc0205968:	00074703          	lbu	a4,0(a4)
ffffffffc020596c:	fb7d                	bnez	a4,ffffffffc0205962 <strlen+0x8>
    }
    return cnt;
}
ffffffffc020596e:	853e                	mv	a0,a5
ffffffffc0205970:	8082                	ret

ffffffffc0205972 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0205972:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205974:	e589                	bnez	a1,ffffffffc020597e <strnlen+0xc>
ffffffffc0205976:	a811                	j	ffffffffc020598a <strnlen+0x18>
        cnt ++;
ffffffffc0205978:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020597a:	00f58863          	beq	a1,a5,ffffffffc020598a <strnlen+0x18>
ffffffffc020597e:	00f50733          	add	a4,a0,a5
ffffffffc0205982:	00074703          	lbu	a4,0(a4)
ffffffffc0205986:	fb6d                	bnez	a4,ffffffffc0205978 <strnlen+0x6>
ffffffffc0205988:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020598a:	852e                	mv	a0,a1
ffffffffc020598c:	8082                	ret

ffffffffc020598e <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc020598e:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0205990:	0005c703          	lbu	a4,0(a1)
ffffffffc0205994:	0585                	addi	a1,a1,1
ffffffffc0205996:	0785                	addi	a5,a5,1
ffffffffc0205998:	fee78fa3          	sb	a4,-1(a5)
ffffffffc020599c:	fb75                	bnez	a4,ffffffffc0205990 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc020599e:	8082                	ret

ffffffffc02059a0 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02059a0:	00054783          	lbu	a5,0(a0)
ffffffffc02059a4:	e791                	bnez	a5,ffffffffc02059b0 <strcmp+0x10>
ffffffffc02059a6:	a01d                	j	ffffffffc02059cc <strcmp+0x2c>
ffffffffc02059a8:	00054783          	lbu	a5,0(a0)
ffffffffc02059ac:	cb99                	beqz	a5,ffffffffc02059c2 <strcmp+0x22>
ffffffffc02059ae:	0585                	addi	a1,a1,1
ffffffffc02059b0:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc02059b4:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02059b6:	fef709e3          	beq	a4,a5,ffffffffc02059a8 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02059ba:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02059be:	9d19                	subw	a0,a0,a4
ffffffffc02059c0:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02059c2:	0015c703          	lbu	a4,1(a1)
ffffffffc02059c6:	4501                	li	a0,0
}
ffffffffc02059c8:	9d19                	subw	a0,a0,a4
ffffffffc02059ca:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02059cc:	0005c703          	lbu	a4,0(a1)
ffffffffc02059d0:	4501                	li	a0,0
ffffffffc02059d2:	b7f5                	j	ffffffffc02059be <strcmp+0x1e>

ffffffffc02059d4 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02059d4:	ce01                	beqz	a2,ffffffffc02059ec <strncmp+0x18>
ffffffffc02059d6:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02059da:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02059dc:	cb91                	beqz	a5,ffffffffc02059f0 <strncmp+0x1c>
ffffffffc02059de:	0005c703          	lbu	a4,0(a1)
ffffffffc02059e2:	00f71763          	bne	a4,a5,ffffffffc02059f0 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc02059e6:	0505                	addi	a0,a0,1
ffffffffc02059e8:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02059ea:	f675                	bnez	a2,ffffffffc02059d6 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02059ec:	4501                	li	a0,0
ffffffffc02059ee:	8082                	ret
ffffffffc02059f0:	00054503          	lbu	a0,0(a0)
ffffffffc02059f4:	0005c783          	lbu	a5,0(a1)
ffffffffc02059f8:	9d1d                	subw	a0,a0,a5
}
ffffffffc02059fa:	8082                	ret

ffffffffc02059fc <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02059fc:	a021                	j	ffffffffc0205a04 <strchr+0x8>
        if (*s == c) {
ffffffffc02059fe:	00f58763          	beq	a1,a5,ffffffffc0205a0c <strchr+0x10>
            return (char *)s;
        }
        s ++;
ffffffffc0205a02:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0205a04:	00054783          	lbu	a5,0(a0)
ffffffffc0205a08:	fbfd                	bnez	a5,ffffffffc02059fe <strchr+0x2>
    }
    return NULL;
ffffffffc0205a0a:	4501                	li	a0,0
}
ffffffffc0205a0c:	8082                	ret

ffffffffc0205a0e <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205a0e:	ca01                	beqz	a2,ffffffffc0205a1e <memset+0x10>
ffffffffc0205a10:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0205a12:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205a14:	0785                	addi	a5,a5,1
ffffffffc0205a16:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205a1a:	fef61de3          	bne	a2,a5,ffffffffc0205a14 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205a1e:	8082                	ret

ffffffffc0205a20 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0205a20:	ca19                	beqz	a2,ffffffffc0205a36 <memcpy+0x16>
ffffffffc0205a22:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205a24:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205a26:	0005c703          	lbu	a4,0(a1)
ffffffffc0205a2a:	0585                	addi	a1,a1,1
ffffffffc0205a2c:	0785                	addi	a5,a5,1
ffffffffc0205a2e:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0205a32:	feb61ae3          	bne	a2,a1,ffffffffc0205a26 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0205a36:	8082                	ret
