
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000b297          	auipc	t0,0xb
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020b000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000b297          	auipc	t0,0xb
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020b008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020a2b7          	lui	t0,0xc020a
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
ffffffffc020003c:	c020a137          	lui	sp,0xc020a

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
ffffffffc020004a:	000a2517          	auipc	a0,0xa2
ffffffffc020004e:	9c650513          	addi	a0,a0,-1594 # ffffffffc02a1a10 <buf>
ffffffffc0200052:	000a6617          	auipc	a2,0xa6
ffffffffc0200056:	e7660613          	addi	a2,a2,-394 # ffffffffc02a5ec8 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16 # ffffffffc0209ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	22f050ef          	jal	ffffffffc0205a90 <memset>
    dtb_init();
ffffffffc0200066:	552000ef          	jal	ffffffffc02005b8 <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	4dc000ef          	jal	ffffffffc0200546 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00006597          	auipc	a1,0x6
ffffffffc0200072:	a5258593          	addi	a1,a1,-1454 # ffffffffc0205ac0 <etext+0x6>
ffffffffc0200076:	00006517          	auipc	a0,0x6
ffffffffc020007a:	a6a50513          	addi	a0,a0,-1430 # ffffffffc0205ae0 <etext+0x26>
ffffffffc020007e:	116000ef          	jal	ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	1a4000ef          	jal	ffffffffc0200226 <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	744020ef          	jal	ffffffffc02027ca <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	081000ef          	jal	ffffffffc020090a <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	07f000ef          	jal	ffffffffc020090c <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	451030ef          	jal	ffffffffc0203ce2 <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	144050ef          	jal	ffffffffc02051da <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	45a000ef          	jal	ffffffffc02004f4 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	061000ef          	jal	ffffffffc02008fe <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	2d8050ef          	jal	ffffffffc020537a <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	7179                	addi	sp,sp,-48
ffffffffc02000a8:	f406                	sd	ra,40(sp)
ffffffffc02000aa:	f022                	sd	s0,32(sp)
ffffffffc02000ac:	ec26                	sd	s1,24(sp)
ffffffffc02000ae:	e84a                	sd	s2,16(sp)
ffffffffc02000b0:	e44e                	sd	s3,8(sp)
    if (prompt != NULL) {
ffffffffc02000b2:	c901                	beqz	a0,ffffffffc02000c2 <readline+0x1c>
        cprintf("%s", prompt);
ffffffffc02000b4:	85aa                	mv	a1,a0
ffffffffc02000b6:	00006517          	auipc	a0,0x6
ffffffffc02000ba:	a3250513          	addi	a0,a0,-1486 # ffffffffc0205ae8 <etext+0x2e>
ffffffffc02000be:	0d6000ef          	jal	ffffffffc0200194 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc02000c2:	4481                	li	s1,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000c4:	497d                	li	s2,31
            buf[i ++] = c;
ffffffffc02000c6:	000a2997          	auipc	s3,0xa2
ffffffffc02000ca:	94a98993          	addi	s3,s3,-1718 # ffffffffc02a1a10 <buf>
        c = getchar();
ffffffffc02000ce:	148000ef          	jal	ffffffffc0200216 <getchar>
ffffffffc02000d2:	842a                	mv	s0,a0
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000d4:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000d8:	3ff4a713          	slti	a4,s1,1023
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000dc:	ff650693          	addi	a3,a0,-10
ffffffffc02000e0:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc02000e4:	02054963          	bltz	a0,ffffffffc0200116 <readline+0x70>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e8:	02a95f63          	bge	s2,a0,ffffffffc0200126 <readline+0x80>
ffffffffc02000ec:	cf0d                	beqz	a4,ffffffffc0200126 <readline+0x80>
            cputchar(c);
ffffffffc02000ee:	0da000ef          	jal	ffffffffc02001c8 <cputchar>
            buf[i ++] = c;
ffffffffc02000f2:	009987b3          	add	a5,s3,s1
ffffffffc02000f6:	00878023          	sb	s0,0(a5)
ffffffffc02000fa:	2485                	addiw	s1,s1,1
        c = getchar();
ffffffffc02000fc:	11a000ef          	jal	ffffffffc0200216 <getchar>
ffffffffc0200100:	842a                	mv	s0,a0
        else if (c == '\b' && i > 0) {
ffffffffc0200102:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200106:	3ff4a713          	slti	a4,s1,1023
        else if (c == '\n' || c == '\r') {
ffffffffc020010a:	ff650693          	addi	a3,a0,-10
ffffffffc020010e:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc0200112:	fc055be3          	bgez	a0,ffffffffc02000e8 <readline+0x42>
            cputchar(c);
            buf[i] = '\0';
            return buf;
        }
    }
}
ffffffffc0200116:	70a2                	ld	ra,40(sp)
ffffffffc0200118:	7402                	ld	s0,32(sp)
ffffffffc020011a:	64e2                	ld	s1,24(sp)
ffffffffc020011c:	6942                	ld	s2,16(sp)
ffffffffc020011e:	69a2                	ld	s3,8(sp)
            return NULL;
ffffffffc0200120:	4501                	li	a0,0
}
ffffffffc0200122:	6145                	addi	sp,sp,48
ffffffffc0200124:	8082                	ret
        else if (c == '\b' && i > 0) {
ffffffffc0200126:	eb81                	bnez	a5,ffffffffc0200136 <readline+0x90>
            cputchar(c);
ffffffffc0200128:	4521                	li	a0,8
        else if (c == '\b' && i > 0) {
ffffffffc020012a:	00905663          	blez	s1,ffffffffc0200136 <readline+0x90>
            cputchar(c);
ffffffffc020012e:	09a000ef          	jal	ffffffffc02001c8 <cputchar>
            i --;
ffffffffc0200132:	34fd                	addiw	s1,s1,-1
ffffffffc0200134:	bf69                	j	ffffffffc02000ce <readline+0x28>
        else if (c == '\n' || c == '\r') {
ffffffffc0200136:	c291                	beqz	a3,ffffffffc020013a <readline+0x94>
ffffffffc0200138:	fa59                	bnez	a2,ffffffffc02000ce <readline+0x28>
            cputchar(c);
ffffffffc020013a:	8522                	mv	a0,s0
ffffffffc020013c:	08c000ef          	jal	ffffffffc02001c8 <cputchar>
            buf[i] = '\0';
ffffffffc0200140:	000a2517          	auipc	a0,0xa2
ffffffffc0200144:	8d050513          	addi	a0,a0,-1840 # ffffffffc02a1a10 <buf>
ffffffffc0200148:	94aa                	add	s1,s1,a0
ffffffffc020014a:	00048023          	sb	zero,0(s1)
}
ffffffffc020014e:	70a2                	ld	ra,40(sp)
ffffffffc0200150:	7402                	ld	s0,32(sp)
ffffffffc0200152:	64e2                	ld	s1,24(sp)
ffffffffc0200154:	6942                	ld	s2,16(sp)
ffffffffc0200156:	69a2                	ld	s3,8(sp)
ffffffffc0200158:	6145                	addi	sp,sp,48
ffffffffc020015a:	8082                	ret

ffffffffc020015c <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015c:	1101                	addi	sp,sp,-32
ffffffffc020015e:	ec06                	sd	ra,24(sp)
ffffffffc0200160:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc0200162:	3e6000ef          	jal	ffffffffc0200548 <cons_putc>
    (*cnt)++;
ffffffffc0200166:	65a2                	ld	a1,8(sp)
}
ffffffffc0200168:	60e2                	ld	ra,24(sp)
    (*cnt)++;
ffffffffc020016a:	419c                	lw	a5,0(a1)
ffffffffc020016c:	2785                	addiw	a5,a5,1
ffffffffc020016e:	c19c                	sw	a5,0(a1)
}
ffffffffc0200170:	6105                	addi	sp,sp,32
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe250513          	addi	a0,a0,-30 # ffffffffc020015c <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	4ee050ef          	jal	ffffffffc0205676 <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40
{
ffffffffc020019a:	f42e                	sd	a1,40(sp)
ffffffffc020019c:	f832                	sd	a2,48(sp)
ffffffffc020019e:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a0:	862a                	mv	a2,a0
ffffffffc02001a2:	004c                	addi	a1,sp,4
ffffffffc02001a4:	00000517          	auipc	a0,0x0
ffffffffc02001a8:	fb850513          	addi	a0,a0,-72 # ffffffffc020015c <cputch>
ffffffffc02001ac:	869a                	mv	a3,t1
{
ffffffffc02001ae:	ec06                	sd	ra,24(sp)
ffffffffc02001b0:	e0ba                	sd	a4,64(sp)
ffffffffc02001b2:	e4be                	sd	a5,72(sp)
ffffffffc02001b4:	e8c2                	sd	a6,80(sp)
ffffffffc02001b6:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc02001b8:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001bc:	4ba050ef          	jal	ffffffffc0205676 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c0:	60e2                	ld	ra,24(sp)
ffffffffc02001c2:	4512                	lw	a0,4(sp)
ffffffffc02001c4:	6125                	addi	sp,sp,96
ffffffffc02001c6:	8082                	ret

ffffffffc02001c8 <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001c8:	a641                	j	ffffffffc0200548 <cons_putc>

ffffffffc02001ca <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001ca:	1101                	addi	sp,sp,-32
ffffffffc02001cc:	e822                	sd	s0,16(sp)
ffffffffc02001ce:	ec06                	sd	ra,24(sp)
ffffffffc02001d0:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001d2:	00054503          	lbu	a0,0(a0)
ffffffffc02001d6:	c51d                	beqz	a0,ffffffffc0200204 <cputs+0x3a>
ffffffffc02001d8:	e426                	sd	s1,8(sp)
ffffffffc02001da:	0405                	addi	s0,s0,1
    int cnt = 0;
ffffffffc02001dc:	4481                	li	s1,0
    cons_putc(c);
ffffffffc02001de:	36a000ef          	jal	ffffffffc0200548 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001e2:	00044503          	lbu	a0,0(s0)
ffffffffc02001e6:	0405                	addi	s0,s0,1
ffffffffc02001e8:	87a6                	mv	a5,s1
    (*cnt)++;
ffffffffc02001ea:	2485                	addiw	s1,s1,1
    while ((c = *str++) != '\0')
ffffffffc02001ec:	f96d                	bnez	a0,ffffffffc02001de <cputs+0x14>
    cons_putc(c);
ffffffffc02001ee:	4529                	li	a0,10
    (*cnt)++;
ffffffffc02001f0:	0027841b          	addiw	s0,a5,2
ffffffffc02001f4:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001f6:	352000ef          	jal	ffffffffc0200548 <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001fa:	60e2                	ld	ra,24(sp)
ffffffffc02001fc:	8522                	mv	a0,s0
ffffffffc02001fe:	6442                	ld	s0,16(sp)
ffffffffc0200200:	6105                	addi	sp,sp,32
ffffffffc0200202:	8082                	ret
    cons_putc(c);
ffffffffc0200204:	4529                	li	a0,10
ffffffffc0200206:	342000ef          	jal	ffffffffc0200548 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc020020a:	4405                	li	s0,1
}
ffffffffc020020c:	60e2                	ld	ra,24(sp)
ffffffffc020020e:	8522                	mv	a0,s0
ffffffffc0200210:	6442                	ld	s0,16(sp)
ffffffffc0200212:	6105                	addi	sp,sp,32
ffffffffc0200214:	8082                	ret

ffffffffc0200216 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc0200216:	1141                	addi	sp,sp,-16
ffffffffc0200218:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020021a:	362000ef          	jal	ffffffffc020057c <cons_getc>
ffffffffc020021e:	dd75                	beqz	a0,ffffffffc020021a <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200220:	60a2                	ld	ra,8(sp)
ffffffffc0200222:	0141                	addi	sp,sp,16
ffffffffc0200224:	8082                	ret

ffffffffc0200226 <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc0200226:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	00006517          	auipc	a0,0x6
ffffffffc020022c:	8c850513          	addi	a0,a0,-1848 # ffffffffc0205af0 <etext+0x36>
{
ffffffffc0200230:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200232:	f63ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200236:	00000597          	auipc	a1,0x0
ffffffffc020023a:	e1458593          	addi	a1,a1,-492 # ffffffffc020004a <kern_init>
ffffffffc020023e:	00006517          	auipc	a0,0x6
ffffffffc0200242:	8d250513          	addi	a0,a0,-1838 # ffffffffc0205b10 <etext+0x56>
ffffffffc0200246:	f4fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020024a:	00006597          	auipc	a1,0x6
ffffffffc020024e:	87058593          	addi	a1,a1,-1936 # ffffffffc0205aba <etext>
ffffffffc0200252:	00006517          	auipc	a0,0x6
ffffffffc0200256:	8de50513          	addi	a0,a0,-1826 # ffffffffc0205b30 <etext+0x76>
ffffffffc020025a:	f3bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020025e:	000a1597          	auipc	a1,0xa1
ffffffffc0200262:	7b258593          	addi	a1,a1,1970 # ffffffffc02a1a10 <buf>
ffffffffc0200266:	00006517          	auipc	a0,0x6
ffffffffc020026a:	8ea50513          	addi	a0,a0,-1814 # ffffffffc0205b50 <etext+0x96>
ffffffffc020026e:	f27ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200272:	000a6597          	auipc	a1,0xa6
ffffffffc0200276:	c5658593          	addi	a1,a1,-938 # ffffffffc02a5ec8 <end>
ffffffffc020027a:	00006517          	auipc	a0,0x6
ffffffffc020027e:	8f650513          	addi	a0,a0,-1802 # ffffffffc0205b70 <etext+0xb6>
ffffffffc0200282:	f13ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200286:	00000717          	auipc	a4,0x0
ffffffffc020028a:	dc470713          	addi	a4,a4,-572 # ffffffffc020004a <kern_init>
ffffffffc020028e:	000a6797          	auipc	a5,0xa6
ffffffffc0200292:	03978793          	addi	a5,a5,57 # ffffffffc02a62c7 <end+0x3ff>
ffffffffc0200296:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200298:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020029c:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020029e:	3ff5f593          	andi	a1,a1,1023
ffffffffc02002a2:	95be                	add	a1,a1,a5
ffffffffc02002a4:	85a9                	srai	a1,a1,0xa
ffffffffc02002a6:	00006517          	auipc	a0,0x6
ffffffffc02002aa:	8ea50513          	addi	a0,a0,-1814 # ffffffffc0205b90 <etext+0xd6>
}
ffffffffc02002ae:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002b0:	b5d5                	j	ffffffffc0200194 <cprintf>

ffffffffc02002b2 <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc02002b2:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002b4:	00006617          	auipc	a2,0x6
ffffffffc02002b8:	90c60613          	addi	a2,a2,-1780 # ffffffffc0205bc0 <etext+0x106>
ffffffffc02002bc:	04f00593          	li	a1,79
ffffffffc02002c0:	00006517          	auipc	a0,0x6
ffffffffc02002c4:	91850513          	addi	a0,a0,-1768 # ffffffffc0205bd8 <etext+0x11e>
{
ffffffffc02002c8:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002ca:	17c000ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02002ce <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int mon_help(int argc, char **argv, struct trapframe *tf)
{
ffffffffc02002ce:	1101                	addi	sp,sp,-32
ffffffffc02002d0:	e822                	sd	s0,16(sp)
ffffffffc02002d2:	e426                	sd	s1,8(sp)
ffffffffc02002d4:	ec06                	sd	ra,24(sp)
ffffffffc02002d6:	00007417          	auipc	s0,0x7
ffffffffc02002da:	63240413          	addi	s0,s0,1586 # ffffffffc0207908 <commands>
ffffffffc02002de:	00007497          	auipc	s1,0x7
ffffffffc02002e2:	67248493          	addi	s1,s1,1650 # ffffffffc0207950 <commands+0x48>
    int i;
    for (i = 0; i < NCOMMANDS; i++)
    {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e6:	6410                	ld	a2,8(s0)
ffffffffc02002e8:	600c                	ld	a1,0(s0)
ffffffffc02002ea:	00006517          	auipc	a0,0x6
ffffffffc02002ee:	90650513          	addi	a0,a0,-1786 # ffffffffc0205bf0 <etext+0x136>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02002f2:	0461                	addi	s0,s0,24
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002f4:	ea1ff0ef          	jal	ffffffffc0200194 <cprintf>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02002f8:	fe9417e3          	bne	s0,s1,ffffffffc02002e6 <mon_help+0x18>
    }
    return 0;
}
ffffffffc02002fc:	60e2                	ld	ra,24(sp)
ffffffffc02002fe:	6442                	ld	s0,16(sp)
ffffffffc0200300:	64a2                	ld	s1,8(sp)
ffffffffc0200302:	4501                	li	a0,0
ffffffffc0200304:	6105                	addi	sp,sp,32
ffffffffc0200306:	8082                	ret

ffffffffc0200308 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int mon_kerninfo(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200308:	1141                	addi	sp,sp,-16
ffffffffc020030a:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020030c:	f1bff0ef          	jal	ffffffffc0200226 <print_kerninfo>
    return 0;
}
ffffffffc0200310:	60a2                	ld	ra,8(sp)
ffffffffc0200312:	4501                	li	a0,0
ffffffffc0200314:	0141                	addi	sp,sp,16
ffffffffc0200316:	8082                	ret

ffffffffc0200318 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int mon_backtrace(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200318:	1141                	addi	sp,sp,-16
ffffffffc020031a:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020031c:	f97ff0ef          	jal	ffffffffc02002b2 <print_stackframe>
    return 0;
}
ffffffffc0200320:	60a2                	ld	ra,8(sp)
ffffffffc0200322:	4501                	li	a0,0
ffffffffc0200324:	0141                	addi	sp,sp,16
ffffffffc0200326:	8082                	ret

ffffffffc0200328 <kmonitor>:
{
ffffffffc0200328:	7131                	addi	sp,sp,-192
ffffffffc020032a:	e952                	sd	s4,144(sp)
ffffffffc020032c:	8a2a                	mv	s4,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020032e:	00006517          	auipc	a0,0x6
ffffffffc0200332:	8d250513          	addi	a0,a0,-1838 # ffffffffc0205c00 <etext+0x146>
{
ffffffffc0200336:	fd06                	sd	ra,184(sp)
ffffffffc0200338:	f922                	sd	s0,176(sp)
ffffffffc020033a:	f526                	sd	s1,168(sp)
ffffffffc020033c:	ed4e                	sd	s3,152(sp)
ffffffffc020033e:	e556                	sd	s5,136(sp)
ffffffffc0200340:	e15a                	sd	s6,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200342:	e53ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200346:	00006517          	auipc	a0,0x6
ffffffffc020034a:	8e250513          	addi	a0,a0,-1822 # ffffffffc0205c28 <etext+0x16e>
ffffffffc020034e:	e47ff0ef          	jal	ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc0200352:	000a0563          	beqz	s4,ffffffffc020035c <kmonitor+0x34>
        print_trapframe(tf);
ffffffffc0200356:	8552                	mv	a0,s4
ffffffffc0200358:	79c000ef          	jal	ffffffffc0200af4 <print_trapframe>
ffffffffc020035c:	00007a97          	auipc	s5,0x7
ffffffffc0200360:	5aca8a93          	addi	s5,s5,1452 # ffffffffc0207908 <commands>
        if (argc == MAXARGS - 1)
ffffffffc0200364:	49bd                	li	s3,15
        if ((buf = readline("K> ")) != NULL)
ffffffffc0200366:	00006517          	auipc	a0,0x6
ffffffffc020036a:	8ea50513          	addi	a0,a0,-1814 # ffffffffc0205c50 <etext+0x196>
ffffffffc020036e:	d39ff0ef          	jal	ffffffffc02000a6 <readline>
ffffffffc0200372:	842a                	mv	s0,a0
ffffffffc0200374:	d96d                	beqz	a0,ffffffffc0200366 <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200376:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020037a:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc020037c:	e99d                	bnez	a1,ffffffffc02003b2 <kmonitor+0x8a>
    int argc = 0;
ffffffffc020037e:	8b26                	mv	s6,s1
    if (argc == 0)
ffffffffc0200380:	fe0b03e3          	beqz	s6,ffffffffc0200366 <kmonitor+0x3e>
ffffffffc0200384:	00007497          	auipc	s1,0x7
ffffffffc0200388:	58448493          	addi	s1,s1,1412 # ffffffffc0207908 <commands>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc020038c:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc020038e:	6582                	ld	a1,0(sp)
ffffffffc0200390:	6088                	ld	a0,0(s1)
ffffffffc0200392:	690050ef          	jal	ffffffffc0205a22 <strcmp>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc0200396:	478d                	li	a5,3
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc0200398:	c149                	beqz	a0,ffffffffc020041a <kmonitor+0xf2>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc020039a:	2405                	addiw	s0,s0,1
ffffffffc020039c:	04e1                	addi	s1,s1,24
ffffffffc020039e:	fef418e3          	bne	s0,a5,ffffffffc020038e <kmonitor+0x66>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003a2:	6582                	ld	a1,0(sp)
ffffffffc02003a4:	00006517          	auipc	a0,0x6
ffffffffc02003a8:	8dc50513          	addi	a0,a0,-1828 # ffffffffc0205c80 <etext+0x1c6>
ffffffffc02003ac:	de9ff0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
ffffffffc02003b0:	bf5d                	j	ffffffffc0200366 <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003b2:	00006517          	auipc	a0,0x6
ffffffffc02003b6:	8a650513          	addi	a0,a0,-1882 # ffffffffc0205c58 <etext+0x19e>
ffffffffc02003ba:	6c4050ef          	jal	ffffffffc0205a7e <strchr>
ffffffffc02003be:	c901                	beqz	a0,ffffffffc02003ce <kmonitor+0xa6>
ffffffffc02003c0:	00144583          	lbu	a1,1(s0)
            *buf++ = '\0';
ffffffffc02003c4:	00040023          	sb	zero,0(s0)
ffffffffc02003c8:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003ca:	d9d5                	beqz	a1,ffffffffc020037e <kmonitor+0x56>
ffffffffc02003cc:	b7dd                	j	ffffffffc02003b2 <kmonitor+0x8a>
        if (*buf == '\0')
ffffffffc02003ce:	00044783          	lbu	a5,0(s0)
ffffffffc02003d2:	d7d5                	beqz	a5,ffffffffc020037e <kmonitor+0x56>
        if (argc == MAXARGS - 1)
ffffffffc02003d4:	03348b63          	beq	s1,s3,ffffffffc020040a <kmonitor+0xe2>
        argv[argc++] = buf;
ffffffffc02003d8:	00349793          	slli	a5,s1,0x3
ffffffffc02003dc:	978a                	add	a5,a5,sp
ffffffffc02003de:	e380                	sd	s0,0(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc02003e0:	00044583          	lbu	a1,0(s0)
        argv[argc++] = buf;
ffffffffc02003e4:	2485                	addiw	s1,s1,1
ffffffffc02003e6:	8b26                	mv	s6,s1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc02003e8:	e591                	bnez	a1,ffffffffc02003f4 <kmonitor+0xcc>
ffffffffc02003ea:	bf59                	j	ffffffffc0200380 <kmonitor+0x58>
ffffffffc02003ec:	00144583          	lbu	a1,1(s0)
            buf++;
ffffffffc02003f0:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc02003f2:	d5d1                	beqz	a1,ffffffffc020037e <kmonitor+0x56>
ffffffffc02003f4:	00006517          	auipc	a0,0x6
ffffffffc02003f8:	86450513          	addi	a0,a0,-1948 # ffffffffc0205c58 <etext+0x19e>
ffffffffc02003fc:	682050ef          	jal	ffffffffc0205a7e <strchr>
ffffffffc0200400:	d575                	beqz	a0,ffffffffc02003ec <kmonitor+0xc4>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200402:	00044583          	lbu	a1,0(s0)
ffffffffc0200406:	dda5                	beqz	a1,ffffffffc020037e <kmonitor+0x56>
ffffffffc0200408:	b76d                	j	ffffffffc02003b2 <kmonitor+0x8a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020040a:	45c1                	li	a1,16
ffffffffc020040c:	00006517          	auipc	a0,0x6
ffffffffc0200410:	85450513          	addi	a0,a0,-1964 # ffffffffc0205c60 <etext+0x1a6>
ffffffffc0200414:	d81ff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0200418:	b7c1                	j	ffffffffc02003d8 <kmonitor+0xb0>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020041a:	00141793          	slli	a5,s0,0x1
ffffffffc020041e:	97a2                	add	a5,a5,s0
ffffffffc0200420:	078e                	slli	a5,a5,0x3
ffffffffc0200422:	97d6                	add	a5,a5,s5
ffffffffc0200424:	6b9c                	ld	a5,16(a5)
ffffffffc0200426:	fffb051b          	addiw	a0,s6,-1
ffffffffc020042a:	8652                	mv	a2,s4
ffffffffc020042c:	002c                	addi	a1,sp,8
ffffffffc020042e:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0)
ffffffffc0200430:	f2055be3          	bgez	a0,ffffffffc0200366 <kmonitor+0x3e>
}
ffffffffc0200434:	70ea                	ld	ra,184(sp)
ffffffffc0200436:	744a                	ld	s0,176(sp)
ffffffffc0200438:	74aa                	ld	s1,168(sp)
ffffffffc020043a:	69ea                	ld	s3,152(sp)
ffffffffc020043c:	6a4a                	ld	s4,144(sp)
ffffffffc020043e:	6aaa                	ld	s5,136(sp)
ffffffffc0200440:	6b0a                	ld	s6,128(sp)
ffffffffc0200442:	6129                	addi	sp,sp,192
ffffffffc0200444:	8082                	ret

ffffffffc0200446 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void __panic(const char *file, int line, const char *fmt, ...)
{
    if (is_panic)
ffffffffc0200446:	000a6317          	auipc	t1,0xa6
ffffffffc020044a:	9f233303          	ld	t1,-1550(t1) # ffffffffc02a5e38 <is_panic>
{
ffffffffc020044e:	715d                	addi	sp,sp,-80
ffffffffc0200450:	ec06                	sd	ra,24(sp)
ffffffffc0200452:	f436                	sd	a3,40(sp)
ffffffffc0200454:	f83a                	sd	a4,48(sp)
ffffffffc0200456:	fc3e                	sd	a5,56(sp)
ffffffffc0200458:	e0c2                	sd	a6,64(sp)
ffffffffc020045a:	e4c6                	sd	a7,72(sp)
    if (is_panic)
ffffffffc020045c:	02031e63          	bnez	t1,ffffffffc0200498 <__panic+0x52>
    {
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200460:	4705                	li	a4,1

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200462:	103c                	addi	a5,sp,40
ffffffffc0200464:	e822                	sd	s0,16(sp)
ffffffffc0200466:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200468:	862e                	mv	a2,a1
ffffffffc020046a:	85aa                	mv	a1,a0
ffffffffc020046c:	00006517          	auipc	a0,0x6
ffffffffc0200470:	8bc50513          	addi	a0,a0,-1860 # ffffffffc0205d28 <etext+0x26e>
    is_panic = 1;
ffffffffc0200474:	000a6697          	auipc	a3,0xa6
ffffffffc0200478:	9ce6b223          	sd	a4,-1596(a3) # ffffffffc02a5e38 <is_panic>
    va_start(ap, fmt);
ffffffffc020047c:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020047e:	d17ff0ef          	jal	ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200482:	65a2                	ld	a1,8(sp)
ffffffffc0200484:	8522                	mv	a0,s0
ffffffffc0200486:	cefff0ef          	jal	ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc020048a:	00006517          	auipc	a0,0x6
ffffffffc020048e:	8be50513          	addi	a0,a0,-1858 # ffffffffc0205d48 <etext+0x28e>
ffffffffc0200492:	d03ff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0200496:	6442                	ld	s0,16(sp)
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200498:	4501                	li	a0,0
ffffffffc020049a:	4581                	li	a1,0
ffffffffc020049c:	4601                	li	a2,0
ffffffffc020049e:	48a1                	li	a7,8
ffffffffc02004a0:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004a4:	460000ef          	jal	ffffffffc0200904 <intr_disable>
    while (1)
    {
        kmonitor(NULL);
ffffffffc02004a8:	4501                	li	a0,0
ffffffffc02004aa:	e7fff0ef          	jal	ffffffffc0200328 <kmonitor>
    while (1)
ffffffffc02004ae:	bfed                	j	ffffffffc02004a8 <__panic+0x62>

ffffffffc02004b0 <__warn>:
    }
}

/* __warn - like panic, but don't */
void __warn(const char *file, int line, const char *fmt, ...)
{
ffffffffc02004b0:	715d                	addi	sp,sp,-80
ffffffffc02004b2:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b4:	02810313          	addi	t1,sp,40
{
ffffffffc02004b8:	8432                	mv	s0,a2
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004ba:	862e                	mv	a2,a1
ffffffffc02004bc:	85aa                	mv	a1,a0
ffffffffc02004be:	00006517          	auipc	a0,0x6
ffffffffc02004c2:	89250513          	addi	a0,a0,-1902 # ffffffffc0205d50 <etext+0x296>
{
ffffffffc02004c6:	ec06                	sd	ra,24(sp)
ffffffffc02004c8:	f436                	sd	a3,40(sp)
ffffffffc02004ca:	f83a                	sd	a4,48(sp)
ffffffffc02004cc:	fc3e                	sd	a5,56(sp)
ffffffffc02004ce:	e0c2                	sd	a6,64(sp)
ffffffffc02004d0:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02004d2:	e41a                	sd	t1,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004d4:	cc1ff0ef          	jal	ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004d8:	65a2                	ld	a1,8(sp)
ffffffffc02004da:	8522                	mv	a0,s0
ffffffffc02004dc:	c99ff0ef          	jal	ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc02004e0:	00006517          	auipc	a0,0x6
ffffffffc02004e4:	86850513          	addi	a0,a0,-1944 # ffffffffc0205d48 <etext+0x28e>
ffffffffc02004e8:	cadff0ef          	jal	ffffffffc0200194 <cprintf>
    va_end(ap);
}
ffffffffc02004ec:	60e2                	ld	ra,24(sp)
ffffffffc02004ee:	6442                	ld	s0,16(sp)
ffffffffc02004f0:	6161                	addi	sp,sp,80
ffffffffc02004f2:	8082                	ret

ffffffffc02004f4 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02004f4:	67e1                	lui	a5,0x18
ffffffffc02004f6:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_COW_out_size+0xe280>
ffffffffc02004fa:	000a6717          	auipc	a4,0xa6
ffffffffc02004fe:	94f73323          	sd	a5,-1722(a4) # ffffffffc02a5e40 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200502:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200506:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200508:	953e                	add	a0,a0,a5
ffffffffc020050a:	4601                	li	a2,0
ffffffffc020050c:	4881                	li	a7,0
ffffffffc020050e:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200512:	02000793          	li	a5,32
ffffffffc0200516:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020051a:	00006517          	auipc	a0,0x6
ffffffffc020051e:	85650513          	addi	a0,a0,-1962 # ffffffffc0205d70 <etext+0x2b6>
    ticks = 0;
ffffffffc0200522:	000a6797          	auipc	a5,0xa6
ffffffffc0200526:	9207b323          	sd	zero,-1754(a5) # ffffffffc02a5e48 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020052a:	b1ad                	j	ffffffffc0200194 <cprintf>

ffffffffc020052c <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020052c:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200530:	000a6797          	auipc	a5,0xa6
ffffffffc0200534:	9107b783          	ld	a5,-1776(a5) # ffffffffc02a5e40 <timebase>
ffffffffc0200538:	4581                	li	a1,0
ffffffffc020053a:	4601                	li	a2,0
ffffffffc020053c:	953e                	add	a0,a0,a5
ffffffffc020053e:	4881                	li	a7,0
ffffffffc0200540:	00000073          	ecall
ffffffffc0200544:	8082                	ret

ffffffffc0200546 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200546:	8082                	ret

ffffffffc0200548 <cons_putc>:
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200548:	100027f3          	csrr	a5,sstatus
ffffffffc020054c:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc020054e:	0ff57513          	zext.b	a0,a0
ffffffffc0200552:	e799                	bnez	a5,ffffffffc0200560 <cons_putc+0x18>
ffffffffc0200554:	4581                	li	a1,0
ffffffffc0200556:	4601                	li	a2,0
ffffffffc0200558:	4885                	li	a7,1
ffffffffc020055a:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc020055e:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200560:	1101                	addi	sp,sp,-32
ffffffffc0200562:	ec06                	sd	ra,24(sp)
ffffffffc0200564:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200566:	39e000ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc020056a:	6522                	ld	a0,8(sp)
ffffffffc020056c:	4581                	li	a1,0
ffffffffc020056e:	4601                	li	a2,0
ffffffffc0200570:	4885                	li	a7,1
ffffffffc0200572:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200576:	60e2                	ld	ra,24(sp)
ffffffffc0200578:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc020057a:	a651                	j	ffffffffc02008fe <intr_enable>

ffffffffc020057c <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020057c:	100027f3          	csrr	a5,sstatus
ffffffffc0200580:	8b89                	andi	a5,a5,2
ffffffffc0200582:	eb89                	bnez	a5,ffffffffc0200594 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200584:	4501                	li	a0,0
ffffffffc0200586:	4581                	li	a1,0
ffffffffc0200588:	4601                	li	a2,0
ffffffffc020058a:	4889                	li	a7,2
ffffffffc020058c:	00000073          	ecall
ffffffffc0200590:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200592:	8082                	ret
int cons_getc(void) {
ffffffffc0200594:	1101                	addi	sp,sp,-32
ffffffffc0200596:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200598:	36c000ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc020059c:	4501                	li	a0,0
ffffffffc020059e:	4581                	li	a1,0
ffffffffc02005a0:	4601                	li	a2,0
ffffffffc02005a2:	4889                	li	a7,2
ffffffffc02005a4:	00000073          	ecall
ffffffffc02005a8:	2501                	sext.w	a0,a0
ffffffffc02005aa:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005ac:	352000ef          	jal	ffffffffc02008fe <intr_enable>
}
ffffffffc02005b0:	60e2                	ld	ra,24(sp)
ffffffffc02005b2:	6522                	ld	a0,8(sp)
ffffffffc02005b4:	6105                	addi	sp,sp,32
ffffffffc02005b6:	8082                	ret

ffffffffc02005b8 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005b8:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc02005ba:	00005517          	auipc	a0,0x5
ffffffffc02005be:	7d650513          	addi	a0,a0,2006 # ffffffffc0205d90 <etext+0x2d6>
void dtb_init(void) {
ffffffffc02005c2:	f406                	sd	ra,40(sp)
ffffffffc02005c4:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc02005c6:	bcfff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005ca:	0000b597          	auipc	a1,0xb
ffffffffc02005ce:	a365b583          	ld	a1,-1482(a1) # ffffffffc020b000 <boot_hartid>
ffffffffc02005d2:	00005517          	auipc	a0,0x5
ffffffffc02005d6:	7ce50513          	addi	a0,a0,1998 # ffffffffc0205da0 <etext+0x2e6>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005da:	0000b417          	auipc	s0,0xb
ffffffffc02005de:	a2e40413          	addi	s0,s0,-1490 # ffffffffc020b008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005e2:	bb3ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005e6:	600c                	ld	a1,0(s0)
ffffffffc02005e8:	00005517          	auipc	a0,0x5
ffffffffc02005ec:	7c850513          	addi	a0,a0,1992 # ffffffffc0205db0 <etext+0x2f6>
ffffffffc02005f0:	ba5ff0ef          	jal	ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02005f4:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02005f6:	00005517          	auipc	a0,0x5
ffffffffc02005fa:	7d250513          	addi	a0,a0,2002 # ffffffffc0205dc8 <etext+0x30e>
    if (boot_dtb == 0) {
ffffffffc02005fe:	10070163          	beqz	a4,ffffffffc0200700 <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200602:	57f5                	li	a5,-3
ffffffffc0200604:	07fa                	slli	a5,a5,0x1e
ffffffffc0200606:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200608:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc020060a:	d00e06b7          	lui	a3,0xd00e0
ffffffffc020060e:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfe3a025>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200612:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200616:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020061a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020061e:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200622:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200626:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200628:	8e49                	or	a2,a2,a0
ffffffffc020062a:	0ff7f793          	zext.b	a5,a5
ffffffffc020062e:	8dd1                	or	a1,a1,a2
ffffffffc0200630:	07a2                	slli	a5,a5,0x8
ffffffffc0200632:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200634:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc0200638:	0cd59863          	bne	a1,a3,ffffffffc0200708 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020063c:	4710                	lw	a2,8(a4)
ffffffffc020063e:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200640:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200642:	0086541b          	srliw	s0,a2,0x8
ffffffffc0200646:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020064a:	01865e1b          	srliw	t3,a2,0x18
ffffffffc020064e:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200652:	0186151b          	slliw	a0,a2,0x18
ffffffffc0200656:	0186959b          	slliw	a1,a3,0x18
ffffffffc020065a:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020065e:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200662:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200666:	0106d69b          	srliw	a3,a3,0x10
ffffffffc020066a:	01c56533          	or	a0,a0,t3
ffffffffc020066e:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200672:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200676:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067a:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020067e:	0ff6f693          	zext.b	a3,a3
ffffffffc0200682:	8c49                	or	s0,s0,a0
ffffffffc0200684:	0622                	slli	a2,a2,0x8
ffffffffc0200686:	8fcd                	or	a5,a5,a1
ffffffffc0200688:	06a2                	slli	a3,a3,0x8
ffffffffc020068a:	8c51                	or	s0,s0,a2
ffffffffc020068c:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020068e:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200690:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200692:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200694:	9381                	srli	a5,a5,0x20
ffffffffc0200696:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200698:	4301                	li	t1,0
        switch (token) {
ffffffffc020069a:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020069c:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020069e:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc02006a2:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006a4:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a6:	0087579b          	srliw	a5,a4,0x8
ffffffffc02006aa:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ae:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b2:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006be:	8ed1                	or	a3,a3,a2
ffffffffc02006c0:	0ff77713          	zext.b	a4,a4
ffffffffc02006c4:	8fd5                	or	a5,a5,a3
ffffffffc02006c6:	0722                	slli	a4,a4,0x8
ffffffffc02006c8:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc02006ca:	05178763          	beq	a5,a7,ffffffffc0200718 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006ce:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc02006d0:	00f8e963          	bltu	a7,a5,ffffffffc02006e2 <dtb_init+0x12a>
ffffffffc02006d4:	07c78d63          	beq	a5,t3,ffffffffc020074e <dtb_init+0x196>
ffffffffc02006d8:	4709                	li	a4,2
ffffffffc02006da:	00e79763          	bne	a5,a4,ffffffffc02006e8 <dtb_init+0x130>
ffffffffc02006de:	4301                	li	t1,0
ffffffffc02006e0:	b7d1                	j	ffffffffc02006a4 <dtb_init+0xec>
ffffffffc02006e2:	4711                	li	a4,4
ffffffffc02006e4:	fce780e3          	beq	a5,a4,ffffffffc02006a4 <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02006e8:	00005517          	auipc	a0,0x5
ffffffffc02006ec:	7a850513          	addi	a0,a0,1960 # ffffffffc0205e90 <etext+0x3d6>
ffffffffc02006f0:	aa5ff0ef          	jal	ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02006f4:	64e2                	ld	s1,24(sp)
ffffffffc02006f6:	6942                	ld	s2,16(sp)
ffffffffc02006f8:	00005517          	auipc	a0,0x5
ffffffffc02006fc:	7d050513          	addi	a0,a0,2000 # ffffffffc0205ec8 <etext+0x40e>
}
ffffffffc0200700:	7402                	ld	s0,32(sp)
ffffffffc0200702:	70a2                	ld	ra,40(sp)
ffffffffc0200704:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc0200706:	b479                	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200708:	7402                	ld	s0,32(sp)
ffffffffc020070a:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020070c:	00005517          	auipc	a0,0x5
ffffffffc0200710:	6dc50513          	addi	a0,a0,1756 # ffffffffc0205de8 <etext+0x32e>
}
ffffffffc0200714:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200716:	bcbd                	j	ffffffffc0200194 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200718:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020071a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020071e:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200722:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200726:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020072a:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072e:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200732:	8ed1                	or	a3,a3,a2
ffffffffc0200734:	0ff77713          	zext.b	a4,a4
ffffffffc0200738:	8fd5                	or	a5,a5,a3
ffffffffc020073a:	0722                	slli	a4,a4,0x8
ffffffffc020073c:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020073e:	04031463          	bnez	t1,ffffffffc0200786 <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200742:	1782                	slli	a5,a5,0x20
ffffffffc0200744:	9381                	srli	a5,a5,0x20
ffffffffc0200746:	043d                	addi	s0,s0,15
ffffffffc0200748:	943e                	add	s0,s0,a5
ffffffffc020074a:	9871                	andi	s0,s0,-4
                break;
ffffffffc020074c:	bfa1                	j	ffffffffc02006a4 <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc020074e:	8522                	mv	a0,s0
ffffffffc0200750:	e01a                	sd	t1,0(sp)
ffffffffc0200752:	28a050ef          	jal	ffffffffc02059dc <strlen>
ffffffffc0200756:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200758:	4619                	li	a2,6
ffffffffc020075a:	8522                	mv	a0,s0
ffffffffc020075c:	00005597          	auipc	a1,0x5
ffffffffc0200760:	6b458593          	addi	a1,a1,1716 # ffffffffc0205e10 <etext+0x356>
ffffffffc0200764:	2f2050ef          	jal	ffffffffc0205a56 <strncmp>
ffffffffc0200768:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020076a:	0411                	addi	s0,s0,4
ffffffffc020076c:	0004879b          	sext.w	a5,s1
ffffffffc0200770:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200772:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200776:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200778:	00a36333          	or	t1,t1,a0
                break;
ffffffffc020077c:	00ff0837          	lui	a6,0xff0
ffffffffc0200780:	488d                	li	a7,3
ffffffffc0200782:	4e05                	li	t3,1
ffffffffc0200784:	b705                	j	ffffffffc02006a4 <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200786:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200788:	00005597          	auipc	a1,0x5
ffffffffc020078c:	69058593          	addi	a1,a1,1680 # ffffffffc0205e18 <etext+0x35e>
ffffffffc0200790:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200792:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200796:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020079a:	0187169b          	slliw	a3,a4,0x18
ffffffffc020079e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007a2:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007a6:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007aa:	8ed1                	or	a3,a3,a2
ffffffffc02007ac:	0ff77713          	zext.b	a4,a4
ffffffffc02007b0:	0722                	slli	a4,a4,0x8
ffffffffc02007b2:	8d55                	or	a0,a0,a3
ffffffffc02007b4:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02007b6:	1502                	slli	a0,a0,0x20
ffffffffc02007b8:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007ba:	954a                	add	a0,a0,s2
ffffffffc02007bc:	e01a                	sd	t1,0(sp)
ffffffffc02007be:	264050ef          	jal	ffffffffc0205a22 <strcmp>
ffffffffc02007c2:	67a2                	ld	a5,8(sp)
ffffffffc02007c4:	473d                	li	a4,15
ffffffffc02007c6:	6302                	ld	t1,0(sp)
ffffffffc02007c8:	00ff0837          	lui	a6,0xff0
ffffffffc02007cc:	488d                	li	a7,3
ffffffffc02007ce:	4e05                	li	t3,1
ffffffffc02007d0:	f6f779e3          	bgeu	a4,a5,ffffffffc0200742 <dtb_init+0x18a>
ffffffffc02007d4:	f53d                	bnez	a0,ffffffffc0200742 <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02007d6:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02007da:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007de:	00005517          	auipc	a0,0x5
ffffffffc02007e2:	64250513          	addi	a0,a0,1602 # ffffffffc0205e20 <etext+0x366>
           fdt32_to_cpu(x >> 32);
ffffffffc02007e6:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ea:	0087d31b          	srliw	t1,a5,0x8
ffffffffc02007ee:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02007f2:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007f6:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007fa:	0187959b          	slliw	a1,a5,0x18
ffffffffc02007fe:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200802:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200806:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020080a:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080e:	01037333          	and	t1,t1,a6
ffffffffc0200812:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200816:	01e5e5b3          	or	a1,a1,t5
ffffffffc020081a:	0ff7f793          	zext.b	a5,a5
ffffffffc020081e:	01de6e33          	or	t3,t3,t4
ffffffffc0200822:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200826:	01067633          	and	a2,a2,a6
ffffffffc020082a:	0086d31b          	srliw	t1,a3,0x8
ffffffffc020082e:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200832:	07a2                	slli	a5,a5,0x8
ffffffffc0200834:	0108d89b          	srliw	a7,a7,0x10
ffffffffc0200838:	0186df1b          	srliw	t5,a3,0x18
ffffffffc020083c:	01875e9b          	srliw	t4,a4,0x18
ffffffffc0200840:	8ddd                	or	a1,a1,a5
ffffffffc0200842:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200846:	0186979b          	slliw	a5,a3,0x18
ffffffffc020084a:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020084e:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200852:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200856:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020085a:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020085e:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200862:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200866:	08a2                	slli	a7,a7,0x8
ffffffffc0200868:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020086c:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200870:	0ff6f693          	zext.b	a3,a3
ffffffffc0200874:	01de6833          	or	a6,t3,t4
ffffffffc0200878:	0ff77713          	zext.b	a4,a4
ffffffffc020087c:	01166633          	or	a2,a2,a7
ffffffffc0200880:	0067e7b3          	or	a5,a5,t1
ffffffffc0200884:	06a2                	slli	a3,a3,0x8
ffffffffc0200886:	01046433          	or	s0,s0,a6
ffffffffc020088a:	0722                	slli	a4,a4,0x8
ffffffffc020088c:	8fd5                	or	a5,a5,a3
ffffffffc020088e:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc0200890:	1582                	slli	a1,a1,0x20
ffffffffc0200892:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200894:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200896:	9201                	srli	a2,a2,0x20
ffffffffc0200898:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020089a:	1402                	slli	s0,s0,0x20
ffffffffc020089c:	00b7e4b3          	or	s1,a5,a1
ffffffffc02008a0:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc02008a2:	8f3ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02008a6:	85a6                	mv	a1,s1
ffffffffc02008a8:	00005517          	auipc	a0,0x5
ffffffffc02008ac:	59850513          	addi	a0,a0,1432 # ffffffffc0205e40 <etext+0x386>
ffffffffc02008b0:	8e5ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02008b4:	01445613          	srli	a2,s0,0x14
ffffffffc02008b8:	85a2                	mv	a1,s0
ffffffffc02008ba:	00005517          	auipc	a0,0x5
ffffffffc02008be:	59e50513          	addi	a0,a0,1438 # ffffffffc0205e58 <etext+0x39e>
ffffffffc02008c2:	8d3ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02008c6:	009405b3          	add	a1,s0,s1
ffffffffc02008ca:	15fd                	addi	a1,a1,-1
ffffffffc02008cc:	00005517          	auipc	a0,0x5
ffffffffc02008d0:	5ac50513          	addi	a0,a0,1452 # ffffffffc0205e78 <etext+0x3be>
ffffffffc02008d4:	8c1ff0ef          	jal	ffffffffc0200194 <cprintf>
        memory_base = mem_base;
ffffffffc02008d8:	000a5797          	auipc	a5,0xa5
ffffffffc02008dc:	5897b023          	sd	s1,1408(a5) # ffffffffc02a5e58 <memory_base>
        memory_size = mem_size;
ffffffffc02008e0:	000a5797          	auipc	a5,0xa5
ffffffffc02008e4:	5687b823          	sd	s0,1392(a5) # ffffffffc02a5e50 <memory_size>
ffffffffc02008e8:	b531                	j	ffffffffc02006f4 <dtb_init+0x13c>

ffffffffc02008ea <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02008ea:	000a5517          	auipc	a0,0xa5
ffffffffc02008ee:	56e53503          	ld	a0,1390(a0) # ffffffffc02a5e58 <memory_base>
ffffffffc02008f2:	8082                	ret

ffffffffc02008f4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02008f4:	000a5517          	auipc	a0,0xa5
ffffffffc02008f8:	55c53503          	ld	a0,1372(a0) # ffffffffc02a5e50 <memory_size>
ffffffffc02008fc:	8082                	ret

ffffffffc02008fe <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02008fe:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200902:	8082                	ret

ffffffffc0200904 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200904:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200908:	8082                	ret

ffffffffc020090a <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc020090a:	8082                	ret

ffffffffc020090c <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020090c:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200910:	00000797          	auipc	a5,0x0
ffffffffc0200914:	54078793          	addi	a5,a5,1344 # ffffffffc0200e50 <__alltraps>
ffffffffc0200918:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020091c:	000407b7          	lui	a5,0x40
ffffffffc0200920:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200924:	8082                	ret

ffffffffc0200926 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200926:	610c                	ld	a1,0(a0)
{
ffffffffc0200928:	1141                	addi	sp,sp,-16
ffffffffc020092a:	e022                	sd	s0,0(sp)
ffffffffc020092c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020092e:	00005517          	auipc	a0,0x5
ffffffffc0200932:	5b250513          	addi	a0,a0,1458 # ffffffffc0205ee0 <etext+0x426>
{
ffffffffc0200936:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200938:	85dff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020093c:	640c                	ld	a1,8(s0)
ffffffffc020093e:	00005517          	auipc	a0,0x5
ffffffffc0200942:	5ba50513          	addi	a0,a0,1466 # ffffffffc0205ef8 <etext+0x43e>
ffffffffc0200946:	84fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020094a:	680c                	ld	a1,16(s0)
ffffffffc020094c:	00005517          	auipc	a0,0x5
ffffffffc0200950:	5c450513          	addi	a0,a0,1476 # ffffffffc0205f10 <etext+0x456>
ffffffffc0200954:	841ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200958:	6c0c                	ld	a1,24(s0)
ffffffffc020095a:	00005517          	auipc	a0,0x5
ffffffffc020095e:	5ce50513          	addi	a0,a0,1486 # ffffffffc0205f28 <etext+0x46e>
ffffffffc0200962:	833ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200966:	700c                	ld	a1,32(s0)
ffffffffc0200968:	00005517          	auipc	a0,0x5
ffffffffc020096c:	5d850513          	addi	a0,a0,1496 # ffffffffc0205f40 <etext+0x486>
ffffffffc0200970:	825ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200974:	740c                	ld	a1,40(s0)
ffffffffc0200976:	00005517          	auipc	a0,0x5
ffffffffc020097a:	5e250513          	addi	a0,a0,1506 # ffffffffc0205f58 <etext+0x49e>
ffffffffc020097e:	817ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200982:	780c                	ld	a1,48(s0)
ffffffffc0200984:	00005517          	auipc	a0,0x5
ffffffffc0200988:	5ec50513          	addi	a0,a0,1516 # ffffffffc0205f70 <etext+0x4b6>
ffffffffc020098c:	809ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200990:	7c0c                	ld	a1,56(s0)
ffffffffc0200992:	00005517          	auipc	a0,0x5
ffffffffc0200996:	5f650513          	addi	a0,a0,1526 # ffffffffc0205f88 <etext+0x4ce>
ffffffffc020099a:	ffaff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc020099e:	602c                	ld	a1,64(s0)
ffffffffc02009a0:	00005517          	auipc	a0,0x5
ffffffffc02009a4:	60050513          	addi	a0,a0,1536 # ffffffffc0205fa0 <etext+0x4e6>
ffffffffc02009a8:	fecff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009ac:	642c                	ld	a1,72(s0)
ffffffffc02009ae:	00005517          	auipc	a0,0x5
ffffffffc02009b2:	60a50513          	addi	a0,a0,1546 # ffffffffc0205fb8 <etext+0x4fe>
ffffffffc02009b6:	fdeff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009ba:	682c                	ld	a1,80(s0)
ffffffffc02009bc:	00005517          	auipc	a0,0x5
ffffffffc02009c0:	61450513          	addi	a0,a0,1556 # ffffffffc0205fd0 <etext+0x516>
ffffffffc02009c4:	fd0ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009c8:	6c2c                	ld	a1,88(s0)
ffffffffc02009ca:	00005517          	auipc	a0,0x5
ffffffffc02009ce:	61e50513          	addi	a0,a0,1566 # ffffffffc0205fe8 <etext+0x52e>
ffffffffc02009d2:	fc2ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02009d6:	702c                	ld	a1,96(s0)
ffffffffc02009d8:	00005517          	auipc	a0,0x5
ffffffffc02009dc:	62850513          	addi	a0,a0,1576 # ffffffffc0206000 <etext+0x546>
ffffffffc02009e0:	fb4ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc02009e4:	742c                	ld	a1,104(s0)
ffffffffc02009e6:	00005517          	auipc	a0,0x5
ffffffffc02009ea:	63250513          	addi	a0,a0,1586 # ffffffffc0206018 <etext+0x55e>
ffffffffc02009ee:	fa6ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc02009f2:	782c                	ld	a1,112(s0)
ffffffffc02009f4:	00005517          	auipc	a0,0x5
ffffffffc02009f8:	63c50513          	addi	a0,a0,1596 # ffffffffc0206030 <etext+0x576>
ffffffffc02009fc:	f98ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200a00:	7c2c                	ld	a1,120(s0)
ffffffffc0200a02:	00005517          	auipc	a0,0x5
ffffffffc0200a06:	64650513          	addi	a0,a0,1606 # ffffffffc0206048 <etext+0x58e>
ffffffffc0200a0a:	f8aff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a0e:	604c                	ld	a1,128(s0)
ffffffffc0200a10:	00005517          	auipc	a0,0x5
ffffffffc0200a14:	65050513          	addi	a0,a0,1616 # ffffffffc0206060 <etext+0x5a6>
ffffffffc0200a18:	f7cff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a1c:	644c                	ld	a1,136(s0)
ffffffffc0200a1e:	00005517          	auipc	a0,0x5
ffffffffc0200a22:	65a50513          	addi	a0,a0,1626 # ffffffffc0206078 <etext+0x5be>
ffffffffc0200a26:	f6eff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a2a:	684c                	ld	a1,144(s0)
ffffffffc0200a2c:	00005517          	auipc	a0,0x5
ffffffffc0200a30:	66450513          	addi	a0,a0,1636 # ffffffffc0206090 <etext+0x5d6>
ffffffffc0200a34:	f60ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a38:	6c4c                	ld	a1,152(s0)
ffffffffc0200a3a:	00005517          	auipc	a0,0x5
ffffffffc0200a3e:	66e50513          	addi	a0,a0,1646 # ffffffffc02060a8 <etext+0x5ee>
ffffffffc0200a42:	f52ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a46:	704c                	ld	a1,160(s0)
ffffffffc0200a48:	00005517          	auipc	a0,0x5
ffffffffc0200a4c:	67850513          	addi	a0,a0,1656 # ffffffffc02060c0 <etext+0x606>
ffffffffc0200a50:	f44ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a54:	744c                	ld	a1,168(s0)
ffffffffc0200a56:	00005517          	auipc	a0,0x5
ffffffffc0200a5a:	68250513          	addi	a0,a0,1666 # ffffffffc02060d8 <etext+0x61e>
ffffffffc0200a5e:	f36ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a62:	784c                	ld	a1,176(s0)
ffffffffc0200a64:	00005517          	auipc	a0,0x5
ffffffffc0200a68:	68c50513          	addi	a0,a0,1676 # ffffffffc02060f0 <etext+0x636>
ffffffffc0200a6c:	f28ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200a70:	7c4c                	ld	a1,184(s0)
ffffffffc0200a72:	00005517          	auipc	a0,0x5
ffffffffc0200a76:	69650513          	addi	a0,a0,1686 # ffffffffc0206108 <etext+0x64e>
ffffffffc0200a7a:	f1aff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200a7e:	606c                	ld	a1,192(s0)
ffffffffc0200a80:	00005517          	auipc	a0,0x5
ffffffffc0200a84:	6a050513          	addi	a0,a0,1696 # ffffffffc0206120 <etext+0x666>
ffffffffc0200a88:	f0cff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200a8c:	646c                	ld	a1,200(s0)
ffffffffc0200a8e:	00005517          	auipc	a0,0x5
ffffffffc0200a92:	6aa50513          	addi	a0,a0,1706 # ffffffffc0206138 <etext+0x67e>
ffffffffc0200a96:	efeff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200a9a:	686c                	ld	a1,208(s0)
ffffffffc0200a9c:	00005517          	auipc	a0,0x5
ffffffffc0200aa0:	6b450513          	addi	a0,a0,1716 # ffffffffc0206150 <etext+0x696>
ffffffffc0200aa4:	ef0ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200aa8:	6c6c                	ld	a1,216(s0)
ffffffffc0200aaa:	00005517          	auipc	a0,0x5
ffffffffc0200aae:	6be50513          	addi	a0,a0,1726 # ffffffffc0206168 <etext+0x6ae>
ffffffffc0200ab2:	ee2ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200ab6:	706c                	ld	a1,224(s0)
ffffffffc0200ab8:	00005517          	auipc	a0,0x5
ffffffffc0200abc:	6c850513          	addi	a0,a0,1736 # ffffffffc0206180 <etext+0x6c6>
ffffffffc0200ac0:	ed4ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200ac4:	746c                	ld	a1,232(s0)
ffffffffc0200ac6:	00005517          	auipc	a0,0x5
ffffffffc0200aca:	6d250513          	addi	a0,a0,1746 # ffffffffc0206198 <etext+0x6de>
ffffffffc0200ace:	ec6ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200ad2:	786c                	ld	a1,240(s0)
ffffffffc0200ad4:	00005517          	auipc	a0,0x5
ffffffffc0200ad8:	6dc50513          	addi	a0,a0,1756 # ffffffffc02061b0 <etext+0x6f6>
ffffffffc0200adc:	eb8ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ae0:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200ae2:	6402                	ld	s0,0(sp)
ffffffffc0200ae4:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ae6:	00005517          	auipc	a0,0x5
ffffffffc0200aea:	6e250513          	addi	a0,a0,1762 # ffffffffc02061c8 <etext+0x70e>
}
ffffffffc0200aee:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200af0:	ea4ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200af4 <print_trapframe>:
{
ffffffffc0200af4:	1141                	addi	sp,sp,-16
ffffffffc0200af6:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200af8:	85aa                	mv	a1,a0
{
ffffffffc0200afa:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200afc:	00005517          	auipc	a0,0x5
ffffffffc0200b00:	6e450513          	addi	a0,a0,1764 # ffffffffc02061e0 <etext+0x726>
{
ffffffffc0200b04:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b06:	e8eff0ef          	jal	ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200b0a:	8522                	mv	a0,s0
ffffffffc0200b0c:	e1bff0ef          	jal	ffffffffc0200926 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200b10:	10043583          	ld	a1,256(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	6e450513          	addi	a0,a0,1764 # ffffffffc02061f8 <etext+0x73e>
ffffffffc0200b1c:	e78ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b20:	10843583          	ld	a1,264(s0)
ffffffffc0200b24:	00005517          	auipc	a0,0x5
ffffffffc0200b28:	6ec50513          	addi	a0,a0,1772 # ffffffffc0206210 <etext+0x756>
ffffffffc0200b2c:	e68ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200b30:	11043583          	ld	a1,272(s0)
ffffffffc0200b34:	00005517          	auipc	a0,0x5
ffffffffc0200b38:	6f450513          	addi	a0,a0,1780 # ffffffffc0206228 <etext+0x76e>
ffffffffc0200b3c:	e58ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b40:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b44:	6402                	ld	s0,0(sp)
ffffffffc0200b46:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b48:	00005517          	auipc	a0,0x5
ffffffffc0200b4c:	6f050513          	addi	a0,a0,1776 # ffffffffc0206238 <etext+0x77e>
}
ffffffffc0200b50:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b52:	e42ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200b56 <pgfault_handler>:
    if (check_mm_struct != NULL) {
ffffffffc0200b56:	000a5797          	auipc	a5,0xa5
ffffffffc0200b5a:	34a7b783          	ld	a5,842(a5) # ffffffffc02a5ea0 <check_mm_struct>
static void pgfault_handler(struct trapframe *tf) {
ffffffffc0200b5e:	1101                	addi	sp,sp,-32
ffffffffc0200b60:	e822                	sd	s0,16(sp)
ffffffffc0200b62:	e426                	sd	s1,8(sp)
ffffffffc0200b64:	ec06                	sd	ra,24(sp)
        assert(current == idleproc);
ffffffffc0200b66:	000a5497          	auipc	s1,0xa5
ffffffffc0200b6a:	34a48493          	addi	s1,s1,842 # ffffffffc02a5eb0 <current>
ffffffffc0200b6e:	6098                	ld	a4,0(s1)
static void pgfault_handler(struct trapframe *tf) {
ffffffffc0200b70:	842a                	mv	s0,a0
    if (check_mm_struct != NULL) {
ffffffffc0200b72:	c785                	beqz	a5,ffffffffc0200b9a <pgfault_handler+0x44>
        assert(current == idleproc);
ffffffffc0200b74:	000a5697          	auipc	a3,0xa5
ffffffffc0200b78:	34c6b683          	ld	a3,844(a3) # ffffffffc02a5ec0 <idleproc>
ffffffffc0200b7c:	04e69663          	bne	a3,a4,ffffffffc0200bc8 <pgfault_handler+0x72>
    if (do_pgfault(mm, tf->cause, tf->tval) != 0) {
ffffffffc0200b80:	11043603          	ld	a2,272(s0)
ffffffffc0200b84:	11842583          	lw	a1,280(s0)
ffffffffc0200b88:	853e                	mv	a0,a5
ffffffffc0200b8a:	445020ef          	jal	ffffffffc02037ce <do_pgfault>
ffffffffc0200b8e:	e909                	bnez	a0,ffffffffc0200ba0 <pgfault_handler+0x4a>
}
ffffffffc0200b90:	60e2                	ld	ra,24(sp)
ffffffffc0200b92:	6442                	ld	s0,16(sp)
ffffffffc0200b94:	64a2                	ld	s1,8(sp)
ffffffffc0200b96:	6105                	addi	sp,sp,32
ffffffffc0200b98:	8082                	ret
        if (current == NULL) {
ffffffffc0200b9a:	c739                	beqz	a4,ffffffffc0200be8 <pgfault_handler+0x92>
        mm = current->mm;
ffffffffc0200b9c:	771c                	ld	a5,40(a4)
ffffffffc0200b9e:	b7cd                	j	ffffffffc0200b80 <pgfault_handler+0x2a>
        print_trapframe(tf);
ffffffffc0200ba0:	8522                	mv	a0,s0
ffffffffc0200ba2:	f53ff0ef          	jal	ffffffffc0200af4 <print_trapframe>
        if (current != NULL) {
ffffffffc0200ba6:	609c                	ld	a5,0(s1)
ffffffffc0200ba8:	c781                	beqz	a5,ffffffffc0200bb0 <pgfault_handler+0x5a>
            do_exit(-E_KILLED);
ffffffffc0200baa:	555d                	li	a0,-9
ffffffffc0200bac:	371030ef          	jal	ffffffffc020471c <do_exit>
        panic("unhandled page fault.\n");
ffffffffc0200bb0:	00005617          	auipc	a2,0x5
ffffffffc0200bb4:	6e860613          	addi	a2,a2,1768 # ffffffffc0206298 <etext+0x7de>
ffffffffc0200bb8:	03600593          	li	a1,54
ffffffffc0200bbc:	00005517          	auipc	a0,0x5
ffffffffc0200bc0:	6c450513          	addi	a0,a0,1732 # ffffffffc0206280 <etext+0x7c6>
ffffffffc0200bc4:	883ff0ef          	jal	ffffffffc0200446 <__panic>
        assert(current == idleproc);
ffffffffc0200bc8:	00005697          	auipc	a3,0x5
ffffffffc0200bcc:	68868693          	addi	a3,a3,1672 # ffffffffc0206250 <etext+0x796>
ffffffffc0200bd0:	00005617          	auipc	a2,0x5
ffffffffc0200bd4:	69860613          	addi	a2,a2,1688 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0200bd8:	02300593          	li	a1,35
ffffffffc0200bdc:	00005517          	auipc	a0,0x5
ffffffffc0200be0:	6a450513          	addi	a0,a0,1700 # ffffffffc0206280 <etext+0x7c6>
ffffffffc0200be4:	863ff0ef          	jal	ffffffffc0200446 <__panic>
            print_trapframe(tf);
ffffffffc0200be8:	f0dff0ef          	jal	ffffffffc0200af4 <print_trapframe>
            panic("unhandled page fault.\n");
ffffffffc0200bec:	00005617          	auipc	a2,0x5
ffffffffc0200bf0:	6ac60613          	addi	a2,a2,1708 # ffffffffc0206298 <etext+0x7de>
ffffffffc0200bf4:	02900593          	li	a1,41
ffffffffc0200bf8:	00005517          	auipc	a0,0x5
ffffffffc0200bfc:	68850513          	addi	a0,a0,1672 # ffffffffc0206280 <etext+0x7c6>
ffffffffc0200c00:	847ff0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0200c04 <interrupt_handler>:
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause)
ffffffffc0200c04:	11853783          	ld	a5,280(a0)
ffffffffc0200c08:	472d                	li	a4,11
ffffffffc0200c0a:	0786                	slli	a5,a5,0x1
ffffffffc0200c0c:	8385                	srli	a5,a5,0x1
ffffffffc0200c0e:	08f76063          	bltu	a4,a5,ffffffffc0200c8e <interrupt_handler+0x8a>
ffffffffc0200c12:	00007717          	auipc	a4,0x7
ffffffffc0200c16:	d3e70713          	addi	a4,a4,-706 # ffffffffc0207950 <commands+0x48>
ffffffffc0200c1a:	078a                	slli	a5,a5,0x2
ffffffffc0200c1c:	97ba                	add	a5,a5,a4
ffffffffc0200c1e:	439c                	lw	a5,0(a5)
ffffffffc0200c20:	97ba                	add	a5,a5,a4
ffffffffc0200c22:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200c24:	00005517          	auipc	a0,0x5
ffffffffc0200c28:	6ec50513          	addi	a0,a0,1772 # ffffffffc0206310 <etext+0x856>
ffffffffc0200c2c:	d68ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c30:	00005517          	auipc	a0,0x5
ffffffffc0200c34:	6c050513          	addi	a0,a0,1728 # ffffffffc02062f0 <etext+0x836>
ffffffffc0200c38:	d5cff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c3c:	00005517          	auipc	a0,0x5
ffffffffc0200c40:	67450513          	addi	a0,a0,1652 # ffffffffc02062b0 <etext+0x7f6>
ffffffffc0200c44:	d50ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c48:	00005517          	auipc	a0,0x5
ffffffffc0200c4c:	68850513          	addi	a0,a0,1672 # ffffffffc02062d0 <etext+0x816>
ffffffffc0200c50:	d44ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200c54:	1141                	addi	sp,sp,-16
ffffffffc0200c56:	e406                	sd	ra,8(sp)
        /*(1)设置下次时钟中断- clock_set_next_event()
         *(2)计数器（ticks）加一
         *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
         * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
         */
        clock_set_next_event();
ffffffffc0200c58:	8d5ff0ef          	jal	ffffffffc020052c <clock_set_next_event>
        
        static int ticks = 0;
        ticks++;
ffffffffc0200c5c:	000a5797          	auipc	a5,0xa5
ffffffffc0200c60:	2047a783          	lw	a5,516(a5) # ffffffffc02a5e60 <ticks.0>
        if (current != NULL) {
ffffffffc0200c64:	000a5717          	auipc	a4,0xa5
ffffffffc0200c68:	24c73703          	ld	a4,588(a4) # ffffffffc02a5eb0 <current>
        ticks++;
ffffffffc0200c6c:	2785                	addiw	a5,a5,1
ffffffffc0200c6e:	000a5697          	auipc	a3,0xa5
ffffffffc0200c72:	1ef6a923          	sw	a5,498(a3) # ffffffffc02a5e60 <ticks.0>
        if (current != NULL) {
ffffffffc0200c76:	c319                	beqz	a4,ffffffffc0200c7c <interrupt_handler+0x78>
            current->need_resched = 1;
ffffffffc0200c78:	4785                	li	a5,1
ffffffffc0200c7a:	ef1c                	sd	a5,24(a4)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c7c:	60a2                	ld	ra,8(sp)
ffffffffc0200c7e:	0141                	addi	sp,sp,16
ffffffffc0200c80:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c82:	00005517          	auipc	a0,0x5
ffffffffc0200c86:	6ae50513          	addi	a0,a0,1710 # ffffffffc0206330 <etext+0x876>
ffffffffc0200c8a:	d0aff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200c8e:	b59d                	j	ffffffffc0200af4 <print_trapframe>

ffffffffc0200c90 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200c90:	11853783          	ld	a5,280(a0)
ffffffffc0200c94:	473d                	li	a4,15
ffffffffc0200c96:	12f76a63          	bltu	a4,a5,ffffffffc0200dca <exception_handler+0x13a>
ffffffffc0200c9a:	00007717          	auipc	a4,0x7
ffffffffc0200c9e:	ce670713          	addi	a4,a4,-794 # ffffffffc0207980 <commands+0x78>
ffffffffc0200ca2:	078a                	slli	a5,a5,0x2
ffffffffc0200ca4:	97ba                	add	a5,a5,a4
ffffffffc0200ca6:	439c                	lw	a5,0(a5)
{
ffffffffc0200ca8:	1101                	addi	sp,sp,-32
ffffffffc0200caa:	ec06                	sd	ra,24(sp)
    switch (tf->cause)
ffffffffc0200cac:	97ba                	add	a5,a5,a4
ffffffffc0200cae:	86aa                	mv	a3,a0
ffffffffc0200cb0:	8782                	jr	a5
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200cb2:	60e2                	ld	ra,24(sp)
ffffffffc0200cb4:	6105                	addi	sp,sp,32
        pgfault_handler(tf);
ffffffffc0200cb6:	b545                	j	ffffffffc0200b56 <pgfault_handler>
ffffffffc0200cb8:	e42a                	sd	a0,8(sp)
        cprintf("Environment call from S-mode\n");
ffffffffc0200cba:	00005517          	auipc	a0,0x5
ffffffffc0200cbe:	76650513          	addi	a0,a0,1894 # ffffffffc0206420 <etext+0x966>
ffffffffc0200cc2:	cd2ff0ef          	jal	ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200cc6:	66a2                	ld	a3,8(sp)
ffffffffc0200cc8:	1086b783          	ld	a5,264(a3)
}
ffffffffc0200ccc:	60e2                	ld	ra,24(sp)
        tf->epc += 4;
ffffffffc0200cce:	0791                	addi	a5,a5,4
ffffffffc0200cd0:	10f6b423          	sd	a5,264(a3)
}
ffffffffc0200cd4:	6105                	addi	sp,sp,32
        syscall();
ffffffffc0200cd6:	0a90406f          	j	ffffffffc020557e <syscall>
}
ffffffffc0200cda:	60e2                	ld	ra,24(sp)
        cprintf("Instruction address misaligned\n");
ffffffffc0200cdc:	00005517          	auipc	a0,0x5
ffffffffc0200ce0:	67450513          	addi	a0,a0,1652 # ffffffffc0206350 <etext+0x896>
}
ffffffffc0200ce4:	6105                	addi	sp,sp,32
        cprintf("Instruction address misaligned\n");
ffffffffc0200ce6:	caeff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200cea:	60e2                	ld	ra,24(sp)
        cprintf("Instruction access fault\n");
ffffffffc0200cec:	00005517          	auipc	a0,0x5
ffffffffc0200cf0:	68450513          	addi	a0,a0,1668 # ffffffffc0206370 <etext+0x8b6>
}
ffffffffc0200cf4:	6105                	addi	sp,sp,32
        cprintf("Instruction access fault\n");
ffffffffc0200cf6:	c9eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Illegal instruction\n");
ffffffffc0200cfa:	00005517          	auipc	a0,0x5
ffffffffc0200cfe:	69650513          	addi	a0,a0,1686 # ffffffffc0206390 <etext+0x8d6>
ffffffffc0200d02:	c92ff0ef          	jal	ffffffffc0200194 <cprintf>
        if (current != NULL) {
ffffffffc0200d06:	000a5797          	auipc	a5,0xa5
ffffffffc0200d0a:	1aa7b783          	ld	a5,426(a5) # ffffffffc02a5eb0 <current>
ffffffffc0200d0e:	cb95                	beqz	a5,ffffffffc0200d42 <exception_handler+0xb2>
}
ffffffffc0200d10:	60e2                	ld	ra,24(sp)
            do_exit(-E_KILLED);
ffffffffc0200d12:	555d                	li	a0,-9
}
ffffffffc0200d14:	6105                	addi	sp,sp,32
            do_exit(-E_KILLED);
ffffffffc0200d16:	2070306f          	j	ffffffffc020471c <do_exit>
}
ffffffffc0200d1a:	60e2                	ld	ra,24(sp)
        cprintf("Environment call from H-mode\n");
ffffffffc0200d1c:	00005517          	auipc	a0,0x5
ffffffffc0200d20:	72450513          	addi	a0,a0,1828 # ffffffffc0206440 <etext+0x986>
}
ffffffffc0200d24:	6105                	addi	sp,sp,32
        cprintf("Environment call from H-mode\n");
ffffffffc0200d26:	c6eff06f          	j	ffffffffc0200194 <cprintf>
ffffffffc0200d2a:	e42a                	sd	a0,8(sp)
        cprintf("Breakpoint\n");
ffffffffc0200d2c:	00005517          	auipc	a0,0x5
ffffffffc0200d30:	67c50513          	addi	a0,a0,1660 # ffffffffc02063a8 <etext+0x8ee>
ffffffffc0200d34:	c60ff0ef          	jal	ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200d38:	66a2                	ld	a3,8(sp)
ffffffffc0200d3a:	47a9                	li	a5,10
ffffffffc0200d3c:	66d8                	ld	a4,136(a3)
ffffffffc0200d3e:	06f70463          	beq	a4,a5,ffffffffc0200da6 <exception_handler+0x116>
}
ffffffffc0200d42:	60e2                	ld	ra,24(sp)
ffffffffc0200d44:	6105                	addi	sp,sp,32
ffffffffc0200d46:	8082                	ret
ffffffffc0200d48:	60e2                	ld	ra,24(sp)
        cprintf("Load address misaligned\n");
ffffffffc0200d4a:	00005517          	auipc	a0,0x5
ffffffffc0200d4e:	66e50513          	addi	a0,a0,1646 # ffffffffc02063b8 <etext+0x8fe>
}
ffffffffc0200d52:	6105                	addi	sp,sp,32
        cprintf("Load address misaligned\n");
ffffffffc0200d54:	c40ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200d58:	60e2                	ld	ra,24(sp)
        cprintf("Environment call from M-mode\n");
ffffffffc0200d5a:	00005517          	auipc	a0,0x5
ffffffffc0200d5e:	70650513          	addi	a0,a0,1798 # ffffffffc0206460 <etext+0x9a6>
}
ffffffffc0200d62:	6105                	addi	sp,sp,32
        cprintf("Environment call from M-mode\n");
ffffffffc0200d64:	c30ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200d68:	60e2                	ld	ra,24(sp)
        cprintf("Load access fault\n");
ffffffffc0200d6a:	00005517          	auipc	a0,0x5
ffffffffc0200d6e:	66e50513          	addi	a0,a0,1646 # ffffffffc02063d8 <etext+0x91e>
}
ffffffffc0200d72:	6105                	addi	sp,sp,32
        cprintf("Load access fault\n");
ffffffffc0200d74:	c20ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200d78:	60e2                	ld	ra,24(sp)
        cprintf("Store/AMO access fault\n");
ffffffffc0200d7a:	00005517          	auipc	a0,0x5
ffffffffc0200d7e:	68e50513          	addi	a0,a0,1678 # ffffffffc0206408 <etext+0x94e>
}
ffffffffc0200d82:	6105                	addi	sp,sp,32
        cprintf("Store/AMO access fault\n");
ffffffffc0200d84:	c10ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200d88:	60e2                	ld	ra,24(sp)
ffffffffc0200d8a:	6105                	addi	sp,sp,32
        print_trapframe(tf);
ffffffffc0200d8c:	b3a5                	j	ffffffffc0200af4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200d8e:	00005617          	auipc	a2,0x5
ffffffffc0200d92:	66260613          	addi	a2,a2,1634 # ffffffffc02063f0 <etext+0x936>
ffffffffc0200d96:	0e100593          	li	a1,225
ffffffffc0200d9a:	00005517          	auipc	a0,0x5
ffffffffc0200d9e:	4e650513          	addi	a0,a0,1254 # ffffffffc0206280 <etext+0x7c6>
ffffffffc0200da2:	ea4ff0ef          	jal	ffffffffc0200446 <__panic>
            tf->epc += 4;
ffffffffc0200da6:	1086b783          	ld	a5,264(a3)
ffffffffc0200daa:	0791                	addi	a5,a5,4
ffffffffc0200dac:	10f6b423          	sd	a5,264(a3)
            syscall();
ffffffffc0200db0:	7ce040ef          	jal	ffffffffc020557e <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200db4:	000a5717          	auipc	a4,0xa5
ffffffffc0200db8:	0fc73703          	ld	a4,252(a4) # ffffffffc02a5eb0 <current>
ffffffffc0200dbc:	6522                	ld	a0,8(sp)
}
ffffffffc0200dbe:	60e2                	ld	ra,24(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200dc0:	6b0c                	ld	a1,16(a4)
ffffffffc0200dc2:	6789                	lui	a5,0x2
ffffffffc0200dc4:	95be                	add	a1,a1,a5
}
ffffffffc0200dc6:	6105                	addi	sp,sp,32
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200dc8:	aa99                	j	ffffffffc0200f1e <kernel_execve_ret>
        print_trapframe(tf);
ffffffffc0200dca:	b32d                	j	ffffffffc0200af4 <print_trapframe>

ffffffffc0200dcc <trap>:
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200dcc:	000a5717          	auipc	a4,0xa5
ffffffffc0200dd0:	0e473703          	ld	a4,228(a4) # ffffffffc02a5eb0 <current>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200dd4:	11853583          	ld	a1,280(a0)
    if (current == NULL)
ffffffffc0200dd8:	cf21                	beqz	a4,ffffffffc0200e30 <trap+0x64>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200dda:	10053603          	ld	a2,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200dde:	0a073803          	ld	a6,160(a4)
{
ffffffffc0200de2:	1101                	addi	sp,sp,-32
ffffffffc0200de4:	ec06                	sd	ra,24(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200de6:	10067613          	andi	a2,a2,256
        current->tf = tf;
ffffffffc0200dea:	f348                	sd	a0,160(a4)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200dec:	e432                	sd	a2,8(sp)
ffffffffc0200dee:	e042                	sd	a6,0(sp)
ffffffffc0200df0:	0205c763          	bltz	a1,ffffffffc0200e1e <trap+0x52>
        exception_handler(tf);
ffffffffc0200df4:	e9dff0ef          	jal	ffffffffc0200c90 <exception_handler>
ffffffffc0200df8:	6622                	ld	a2,8(sp)
ffffffffc0200dfa:	6802                	ld	a6,0(sp)
ffffffffc0200dfc:	000a5697          	auipc	a3,0xa5
ffffffffc0200e00:	0b468693          	addi	a3,a3,180 # ffffffffc02a5eb0 <current>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200e04:	6298                	ld	a4,0(a3)
ffffffffc0200e06:	0b073023          	sd	a6,160(a4)
        if (!in_kernel)
ffffffffc0200e0a:	e619                	bnez	a2,ffffffffc0200e18 <trap+0x4c>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200e0c:	0b072783          	lw	a5,176(a4)
ffffffffc0200e10:	8b85                	andi	a5,a5,1
ffffffffc0200e12:	e79d                	bnez	a5,ffffffffc0200e40 <trap+0x74>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200e14:	6f1c                	ld	a5,24(a4)
ffffffffc0200e16:	e38d                	bnez	a5,ffffffffc0200e38 <trap+0x6c>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200e18:	60e2                	ld	ra,24(sp)
ffffffffc0200e1a:	6105                	addi	sp,sp,32
ffffffffc0200e1c:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200e1e:	de7ff0ef          	jal	ffffffffc0200c04 <interrupt_handler>
ffffffffc0200e22:	6802                	ld	a6,0(sp)
ffffffffc0200e24:	6622                	ld	a2,8(sp)
ffffffffc0200e26:	000a5697          	auipc	a3,0xa5
ffffffffc0200e2a:	08a68693          	addi	a3,a3,138 # ffffffffc02a5eb0 <current>
ffffffffc0200e2e:	bfd9                	j	ffffffffc0200e04 <trap+0x38>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e30:	0005c363          	bltz	a1,ffffffffc0200e36 <trap+0x6a>
        exception_handler(tf);
ffffffffc0200e34:	bdb1                	j	ffffffffc0200c90 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200e36:	b3f9                	j	ffffffffc0200c04 <interrupt_handler>
}
ffffffffc0200e38:	60e2                	ld	ra,24(sp)
ffffffffc0200e3a:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200e3c:	6560406f          	j	ffffffffc0205492 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200e40:	555d                	li	a0,-9
ffffffffc0200e42:	0db030ef          	jal	ffffffffc020471c <do_exit>
            if (current->need_resched)
ffffffffc0200e46:	000a5717          	auipc	a4,0xa5
ffffffffc0200e4a:	06a73703          	ld	a4,106(a4) # ffffffffc02a5eb0 <current>
ffffffffc0200e4e:	b7d9                	j	ffffffffc0200e14 <trap+0x48>

ffffffffc0200e50 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200e50:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200e54:	00011463          	bnez	sp,ffffffffc0200e5c <__alltraps+0xc>
ffffffffc0200e58:	14002173          	csrr	sp,sscratch
ffffffffc0200e5c:	712d                	addi	sp,sp,-288
ffffffffc0200e5e:	e002                	sd	zero,0(sp)
ffffffffc0200e60:	e406                	sd	ra,8(sp)
ffffffffc0200e62:	ec0e                	sd	gp,24(sp)
ffffffffc0200e64:	f012                	sd	tp,32(sp)
ffffffffc0200e66:	f416                	sd	t0,40(sp)
ffffffffc0200e68:	f81a                	sd	t1,48(sp)
ffffffffc0200e6a:	fc1e                	sd	t2,56(sp)
ffffffffc0200e6c:	e0a2                	sd	s0,64(sp)
ffffffffc0200e6e:	e4a6                	sd	s1,72(sp)
ffffffffc0200e70:	e8aa                	sd	a0,80(sp)
ffffffffc0200e72:	ecae                	sd	a1,88(sp)
ffffffffc0200e74:	f0b2                	sd	a2,96(sp)
ffffffffc0200e76:	f4b6                	sd	a3,104(sp)
ffffffffc0200e78:	f8ba                	sd	a4,112(sp)
ffffffffc0200e7a:	fcbe                	sd	a5,120(sp)
ffffffffc0200e7c:	e142                	sd	a6,128(sp)
ffffffffc0200e7e:	e546                	sd	a7,136(sp)
ffffffffc0200e80:	e94a                	sd	s2,144(sp)
ffffffffc0200e82:	ed4e                	sd	s3,152(sp)
ffffffffc0200e84:	f152                	sd	s4,160(sp)
ffffffffc0200e86:	f556                	sd	s5,168(sp)
ffffffffc0200e88:	f95a                	sd	s6,176(sp)
ffffffffc0200e8a:	fd5e                	sd	s7,184(sp)
ffffffffc0200e8c:	e1e2                	sd	s8,192(sp)
ffffffffc0200e8e:	e5e6                	sd	s9,200(sp)
ffffffffc0200e90:	e9ea                	sd	s10,208(sp)
ffffffffc0200e92:	edee                	sd	s11,216(sp)
ffffffffc0200e94:	f1f2                	sd	t3,224(sp)
ffffffffc0200e96:	f5f6                	sd	t4,232(sp)
ffffffffc0200e98:	f9fa                	sd	t5,240(sp)
ffffffffc0200e9a:	fdfe                	sd	t6,248(sp)
ffffffffc0200e9c:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200ea0:	100024f3          	csrr	s1,sstatus
ffffffffc0200ea4:	14102973          	csrr	s2,sepc
ffffffffc0200ea8:	143029f3          	csrr	s3,stval
ffffffffc0200eac:	14202a73          	csrr	s4,scause
ffffffffc0200eb0:	e822                	sd	s0,16(sp)
ffffffffc0200eb2:	e226                	sd	s1,256(sp)
ffffffffc0200eb4:	e64a                	sd	s2,264(sp)
ffffffffc0200eb6:	ea4e                	sd	s3,272(sp)
ffffffffc0200eb8:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200eba:	850a                	mv	a0,sp
    jal trap
ffffffffc0200ebc:	f11ff0ef          	jal	ffffffffc0200dcc <trap>

ffffffffc0200ec0 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200ec0:	6492                	ld	s1,256(sp)
ffffffffc0200ec2:	6932                	ld	s2,264(sp)
ffffffffc0200ec4:	1004f413          	andi	s0,s1,256
ffffffffc0200ec8:	e401                	bnez	s0,ffffffffc0200ed0 <__trapret+0x10>
ffffffffc0200eca:	1200                	addi	s0,sp,288
ffffffffc0200ecc:	14041073          	csrw	sscratch,s0
ffffffffc0200ed0:	10049073          	csrw	sstatus,s1
ffffffffc0200ed4:	14191073          	csrw	sepc,s2
ffffffffc0200ed8:	60a2                	ld	ra,8(sp)
ffffffffc0200eda:	61e2                	ld	gp,24(sp)
ffffffffc0200edc:	7202                	ld	tp,32(sp)
ffffffffc0200ede:	72a2                	ld	t0,40(sp)
ffffffffc0200ee0:	7342                	ld	t1,48(sp)
ffffffffc0200ee2:	73e2                	ld	t2,56(sp)
ffffffffc0200ee4:	6406                	ld	s0,64(sp)
ffffffffc0200ee6:	64a6                	ld	s1,72(sp)
ffffffffc0200ee8:	6546                	ld	a0,80(sp)
ffffffffc0200eea:	65e6                	ld	a1,88(sp)
ffffffffc0200eec:	7606                	ld	a2,96(sp)
ffffffffc0200eee:	76a6                	ld	a3,104(sp)
ffffffffc0200ef0:	7746                	ld	a4,112(sp)
ffffffffc0200ef2:	77e6                	ld	a5,120(sp)
ffffffffc0200ef4:	680a                	ld	a6,128(sp)
ffffffffc0200ef6:	68aa                	ld	a7,136(sp)
ffffffffc0200ef8:	694a                	ld	s2,144(sp)
ffffffffc0200efa:	69ea                	ld	s3,152(sp)
ffffffffc0200efc:	7a0a                	ld	s4,160(sp)
ffffffffc0200efe:	7aaa                	ld	s5,168(sp)
ffffffffc0200f00:	7b4a                	ld	s6,176(sp)
ffffffffc0200f02:	7bea                	ld	s7,184(sp)
ffffffffc0200f04:	6c0e                	ld	s8,192(sp)
ffffffffc0200f06:	6cae                	ld	s9,200(sp)
ffffffffc0200f08:	6d4e                	ld	s10,208(sp)
ffffffffc0200f0a:	6dee                	ld	s11,216(sp)
ffffffffc0200f0c:	7e0e                	ld	t3,224(sp)
ffffffffc0200f0e:	7eae                	ld	t4,232(sp)
ffffffffc0200f10:	7f4e                	ld	t5,240(sp)
ffffffffc0200f12:	7fee                	ld	t6,248(sp)
ffffffffc0200f14:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200f16:	10200073          	sret

ffffffffc0200f1a <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200f1a:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200f1c:	b755                	j	ffffffffc0200ec0 <__trapret>

ffffffffc0200f1e <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200f1e:	ee058593          	addi	a1,a1,-288

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200f22:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200f26:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200f2a:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200f2e:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200f32:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200f36:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200f3a:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200f3e:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200f42:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200f44:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200f46:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200f48:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200f4a:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200f4c:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200f4e:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200f50:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200f52:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200f54:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200f56:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200f58:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200f5a:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200f5c:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200f5e:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200f60:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200f62:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200f64:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200f66:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200f68:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200f6a:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200f6c:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200f6e:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200f70:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200f72:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200f74:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200f76:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200f78:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200f7a:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200f7c:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200f7e:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200f80:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200f82:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200f84:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200f86:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200f88:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200f8a:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200f8c:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200f8e:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200f90:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200f92:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200f94:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200f96:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200f98:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200f9a:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200f9c:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200f9e:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200fa0:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200fa2:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200fa4:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200fa6:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200fa8:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200faa:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200fac:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200fae:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200fb0:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200fb2:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200fb4:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200fb6:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200fb8:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200fba:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200fbc:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200fbe:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200fc0:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0200fc2:	812e                	mv	sp,a1
ffffffffc0200fc4:	bdf5                	j	ffffffffc0200ec0 <__trapret>

ffffffffc0200fc6 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200fc6:	000a1797          	auipc	a5,0xa1
ffffffffc0200fca:	e4a78793          	addi	a5,a5,-438 # ffffffffc02a1e10 <free_area>
ffffffffc0200fce:	e79c                	sd	a5,8(a5)
ffffffffc0200fd0:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200fd2:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200fd6:	8082                	ret

ffffffffc0200fd8 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200fd8:	000a1517          	auipc	a0,0xa1
ffffffffc0200fdc:	e4856503          	lwu	a0,-440(a0) # ffffffffc02a1e20 <free_area+0x10>
ffffffffc0200fe0:	8082                	ret

ffffffffc0200fe2 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200fe2:	711d                	addi	sp,sp,-96
ffffffffc0200fe4:	e0ca                	sd	s2,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200fe6:	000a1917          	auipc	s2,0xa1
ffffffffc0200fea:	e2a90913          	addi	s2,s2,-470 # ffffffffc02a1e10 <free_area>
ffffffffc0200fee:	00893783          	ld	a5,8(s2)
ffffffffc0200ff2:	ec86                	sd	ra,88(sp)
ffffffffc0200ff4:	e8a2                	sd	s0,80(sp)
ffffffffc0200ff6:	e4a6                	sd	s1,72(sp)
ffffffffc0200ff8:	fc4e                	sd	s3,56(sp)
ffffffffc0200ffa:	f852                	sd	s4,48(sp)
ffffffffc0200ffc:	f456                	sd	s5,40(sp)
ffffffffc0200ffe:	f05a                	sd	s6,32(sp)
ffffffffc0201000:	ec5e                	sd	s7,24(sp)
ffffffffc0201002:	e862                	sd	s8,16(sp)
ffffffffc0201004:	e466                	sd	s9,8(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201006:	2f278363          	beq	a5,s2,ffffffffc02012ec <default_check+0x30a>
    int count = 0, total = 0;
ffffffffc020100a:	4401                	li	s0,0
ffffffffc020100c:	4481                	li	s1,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020100e:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0201012:	8b09                	andi	a4,a4,2
ffffffffc0201014:	2e070063          	beqz	a4,ffffffffc02012f4 <default_check+0x312>
        count++, total += p->property;
ffffffffc0201018:	ff87a703          	lw	a4,-8(a5)
ffffffffc020101c:	679c                	ld	a5,8(a5)
ffffffffc020101e:	2485                	addiw	s1,s1,1
ffffffffc0201020:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201022:	ff2796e3          	bne	a5,s2,ffffffffc020100e <default_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc0201026:	89a2                	mv	s3,s0
ffffffffc0201028:	741000ef          	jal	ffffffffc0201f68 <nr_free_pages>
ffffffffc020102c:	73351463          	bne	a0,s3,ffffffffc0201754 <default_check+0x772>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201030:	4505                	li	a0,1
ffffffffc0201032:	6c5000ef          	jal	ffffffffc0201ef6 <alloc_pages>
ffffffffc0201036:	8a2a                	mv	s4,a0
ffffffffc0201038:	44050e63          	beqz	a0,ffffffffc0201494 <default_check+0x4b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020103c:	4505                	li	a0,1
ffffffffc020103e:	6b9000ef          	jal	ffffffffc0201ef6 <alloc_pages>
ffffffffc0201042:	89aa                	mv	s3,a0
ffffffffc0201044:	72050863          	beqz	a0,ffffffffc0201774 <default_check+0x792>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201048:	4505                	li	a0,1
ffffffffc020104a:	6ad000ef          	jal	ffffffffc0201ef6 <alloc_pages>
ffffffffc020104e:	8aaa                	mv	s5,a0
ffffffffc0201050:	4c050263          	beqz	a0,ffffffffc0201514 <default_check+0x532>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201054:	40a987b3          	sub	a5,s3,a0
ffffffffc0201058:	40aa0733          	sub	a4,s4,a0
ffffffffc020105c:	0017b793          	seqz	a5,a5
ffffffffc0201060:	00173713          	seqz	a4,a4
ffffffffc0201064:	8fd9                	or	a5,a5,a4
ffffffffc0201066:	30079763          	bnez	a5,ffffffffc0201374 <default_check+0x392>
ffffffffc020106a:	313a0563          	beq	s4,s3,ffffffffc0201374 <default_check+0x392>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020106e:	000a2783          	lw	a5,0(s4)
ffffffffc0201072:	2a079163          	bnez	a5,ffffffffc0201314 <default_check+0x332>
ffffffffc0201076:	0009a783          	lw	a5,0(s3)
ffffffffc020107a:	28079d63          	bnez	a5,ffffffffc0201314 <default_check+0x332>
ffffffffc020107e:	411c                	lw	a5,0(a0)
ffffffffc0201080:	28079a63          	bnez	a5,ffffffffc0201314 <default_check+0x332>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0201084:	000a5797          	auipc	a5,0xa5
ffffffffc0201088:	e147b783          	ld	a5,-492(a5) # ffffffffc02a5e98 <pages>
ffffffffc020108c:	00007617          	auipc	a2,0x7
ffffffffc0201090:	c8c63603          	ld	a2,-884(a2) # ffffffffc0207d18 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201094:	000a5697          	auipc	a3,0xa5
ffffffffc0201098:	dfc6b683          	ld	a3,-516(a3) # ffffffffc02a5e90 <npage>
ffffffffc020109c:	40fa0733          	sub	a4,s4,a5
ffffffffc02010a0:	8719                	srai	a4,a4,0x6
ffffffffc02010a2:	9732                	add	a4,a4,a2
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc02010a4:	0732                	slli	a4,a4,0xc
ffffffffc02010a6:	06b2                	slli	a3,a3,0xc
ffffffffc02010a8:	2ad77663          	bgeu	a4,a3,ffffffffc0201354 <default_check+0x372>
    return page - pages + nbase;
ffffffffc02010ac:	40f98733          	sub	a4,s3,a5
ffffffffc02010b0:	8719                	srai	a4,a4,0x6
ffffffffc02010b2:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02010b4:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02010b6:	4cd77f63          	bgeu	a4,a3,ffffffffc0201594 <default_check+0x5b2>
    return page - pages + nbase;
ffffffffc02010ba:	40f507b3          	sub	a5,a0,a5
ffffffffc02010be:	8799                	srai	a5,a5,0x6
ffffffffc02010c0:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02010c2:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02010c4:	32d7f863          	bgeu	a5,a3,ffffffffc02013f4 <default_check+0x412>
    assert(alloc_page() == NULL);
ffffffffc02010c8:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02010ca:	00093c03          	ld	s8,0(s2)
ffffffffc02010ce:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc02010d2:	000a1b17          	auipc	s6,0xa1
ffffffffc02010d6:	d4eb2b03          	lw	s6,-690(s6) # ffffffffc02a1e20 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc02010da:	01293023          	sd	s2,0(s2)
ffffffffc02010de:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc02010e2:	000a1797          	auipc	a5,0xa1
ffffffffc02010e6:	d207af23          	sw	zero,-706(a5) # ffffffffc02a1e20 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02010ea:	60d000ef          	jal	ffffffffc0201ef6 <alloc_pages>
ffffffffc02010ee:	2e051363          	bnez	a0,ffffffffc02013d4 <default_check+0x3f2>
    free_page(p0);
ffffffffc02010f2:	8552                	mv	a0,s4
ffffffffc02010f4:	4585                	li	a1,1
ffffffffc02010f6:	63b000ef          	jal	ffffffffc0201f30 <free_pages>
    free_page(p1);
ffffffffc02010fa:	854e                	mv	a0,s3
ffffffffc02010fc:	4585                	li	a1,1
ffffffffc02010fe:	633000ef          	jal	ffffffffc0201f30 <free_pages>
    free_page(p2);
ffffffffc0201102:	8556                	mv	a0,s5
ffffffffc0201104:	4585                	li	a1,1
ffffffffc0201106:	62b000ef          	jal	ffffffffc0201f30 <free_pages>
    assert(nr_free == 3);
ffffffffc020110a:	000a1717          	auipc	a4,0xa1
ffffffffc020110e:	d1672703          	lw	a4,-746(a4) # ffffffffc02a1e20 <free_area+0x10>
ffffffffc0201112:	478d                	li	a5,3
ffffffffc0201114:	2af71063          	bne	a4,a5,ffffffffc02013b4 <default_check+0x3d2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201118:	4505                	li	a0,1
ffffffffc020111a:	5dd000ef          	jal	ffffffffc0201ef6 <alloc_pages>
ffffffffc020111e:	89aa                	mv	s3,a0
ffffffffc0201120:	26050a63          	beqz	a0,ffffffffc0201394 <default_check+0x3b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201124:	4505                	li	a0,1
ffffffffc0201126:	5d1000ef          	jal	ffffffffc0201ef6 <alloc_pages>
ffffffffc020112a:	8aaa                	mv	s5,a0
ffffffffc020112c:	3c050463          	beqz	a0,ffffffffc02014f4 <default_check+0x512>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201130:	4505                	li	a0,1
ffffffffc0201132:	5c5000ef          	jal	ffffffffc0201ef6 <alloc_pages>
ffffffffc0201136:	8a2a                	mv	s4,a0
ffffffffc0201138:	38050e63          	beqz	a0,ffffffffc02014d4 <default_check+0x4f2>
    assert(alloc_page() == NULL);
ffffffffc020113c:	4505                	li	a0,1
ffffffffc020113e:	5b9000ef          	jal	ffffffffc0201ef6 <alloc_pages>
ffffffffc0201142:	36051963          	bnez	a0,ffffffffc02014b4 <default_check+0x4d2>
    free_page(p0);
ffffffffc0201146:	4585                	li	a1,1
ffffffffc0201148:	854e                	mv	a0,s3
ffffffffc020114a:	5e7000ef          	jal	ffffffffc0201f30 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc020114e:	00893783          	ld	a5,8(s2)
ffffffffc0201152:	1f278163          	beq	a5,s2,ffffffffc0201334 <default_check+0x352>
    assert((p = alloc_page()) == p0);
ffffffffc0201156:	4505                	li	a0,1
ffffffffc0201158:	59f000ef          	jal	ffffffffc0201ef6 <alloc_pages>
ffffffffc020115c:	8caa                	mv	s9,a0
ffffffffc020115e:	30a99b63          	bne	s3,a0,ffffffffc0201474 <default_check+0x492>
    assert(alloc_page() == NULL);
ffffffffc0201162:	4505                	li	a0,1
ffffffffc0201164:	593000ef          	jal	ffffffffc0201ef6 <alloc_pages>
ffffffffc0201168:	2e051663          	bnez	a0,ffffffffc0201454 <default_check+0x472>
    assert(nr_free == 0);
ffffffffc020116c:	000a1797          	auipc	a5,0xa1
ffffffffc0201170:	cb47a783          	lw	a5,-844(a5) # ffffffffc02a1e20 <free_area+0x10>
ffffffffc0201174:	2c079063          	bnez	a5,ffffffffc0201434 <default_check+0x452>
    free_page(p);
ffffffffc0201178:	8566                	mv	a0,s9
ffffffffc020117a:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020117c:	01893023          	sd	s8,0(s2)
ffffffffc0201180:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc0201184:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc0201188:	5a9000ef          	jal	ffffffffc0201f30 <free_pages>
    free_page(p1);
ffffffffc020118c:	8556                	mv	a0,s5
ffffffffc020118e:	4585                	li	a1,1
ffffffffc0201190:	5a1000ef          	jal	ffffffffc0201f30 <free_pages>
    free_page(p2);
ffffffffc0201194:	8552                	mv	a0,s4
ffffffffc0201196:	4585                	li	a1,1
ffffffffc0201198:	599000ef          	jal	ffffffffc0201f30 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020119c:	4515                	li	a0,5
ffffffffc020119e:	559000ef          	jal	ffffffffc0201ef6 <alloc_pages>
ffffffffc02011a2:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc02011a4:	26050863          	beqz	a0,ffffffffc0201414 <default_check+0x432>
ffffffffc02011a8:	651c                	ld	a5,8(a0)
    assert(!PageProperty(p0));
ffffffffc02011aa:	8b89                	andi	a5,a5,2
ffffffffc02011ac:	54079463          	bnez	a5,ffffffffc02016f4 <default_check+0x712>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02011b0:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02011b2:	00093b83          	ld	s7,0(s2)
ffffffffc02011b6:	00893b03          	ld	s6,8(s2)
ffffffffc02011ba:	01293023          	sd	s2,0(s2)
ffffffffc02011be:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc02011c2:	535000ef          	jal	ffffffffc0201ef6 <alloc_pages>
ffffffffc02011c6:	50051763          	bnez	a0,ffffffffc02016d4 <default_check+0x6f2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc02011ca:	08098a13          	addi	s4,s3,128
ffffffffc02011ce:	8552                	mv	a0,s4
ffffffffc02011d0:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02011d2:	000a1c17          	auipc	s8,0xa1
ffffffffc02011d6:	c4ec2c03          	lw	s8,-946(s8) # ffffffffc02a1e20 <free_area+0x10>
    nr_free = 0;
ffffffffc02011da:	000a1797          	auipc	a5,0xa1
ffffffffc02011de:	c407a323          	sw	zero,-954(a5) # ffffffffc02a1e20 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02011e2:	54f000ef          	jal	ffffffffc0201f30 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02011e6:	4511                	li	a0,4
ffffffffc02011e8:	50f000ef          	jal	ffffffffc0201ef6 <alloc_pages>
ffffffffc02011ec:	4c051463          	bnez	a0,ffffffffc02016b4 <default_check+0x6d2>
ffffffffc02011f0:	0889b783          	ld	a5,136(s3)
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02011f4:	8b89                	andi	a5,a5,2
ffffffffc02011f6:	48078f63          	beqz	a5,ffffffffc0201694 <default_check+0x6b2>
ffffffffc02011fa:	0909a503          	lw	a0,144(s3)
ffffffffc02011fe:	478d                	li	a5,3
ffffffffc0201200:	48f51a63          	bne	a0,a5,ffffffffc0201694 <default_check+0x6b2>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201204:	4f3000ef          	jal	ffffffffc0201ef6 <alloc_pages>
ffffffffc0201208:	8aaa                	mv	s5,a0
ffffffffc020120a:	46050563          	beqz	a0,ffffffffc0201674 <default_check+0x692>
    assert(alloc_page() == NULL);
ffffffffc020120e:	4505                	li	a0,1
ffffffffc0201210:	4e7000ef          	jal	ffffffffc0201ef6 <alloc_pages>
ffffffffc0201214:	44051063          	bnez	a0,ffffffffc0201654 <default_check+0x672>
    assert(p0 + 2 == p1);
ffffffffc0201218:	415a1e63          	bne	s4,s5,ffffffffc0201634 <default_check+0x652>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc020121c:	4585                	li	a1,1
ffffffffc020121e:	854e                	mv	a0,s3
ffffffffc0201220:	511000ef          	jal	ffffffffc0201f30 <free_pages>
    free_pages(p1, 3);
ffffffffc0201224:	8552                	mv	a0,s4
ffffffffc0201226:	458d                	li	a1,3
ffffffffc0201228:	509000ef          	jal	ffffffffc0201f30 <free_pages>
ffffffffc020122c:	0089b783          	ld	a5,8(s3)
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201230:	8b89                	andi	a5,a5,2
ffffffffc0201232:	3e078163          	beqz	a5,ffffffffc0201614 <default_check+0x632>
ffffffffc0201236:	0109aa83          	lw	s5,16(s3)
ffffffffc020123a:	4785                	li	a5,1
ffffffffc020123c:	3cfa9c63          	bne	s5,a5,ffffffffc0201614 <default_check+0x632>
ffffffffc0201240:	008a3783          	ld	a5,8(s4)
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201244:	8b89                	andi	a5,a5,2
ffffffffc0201246:	3a078763          	beqz	a5,ffffffffc02015f4 <default_check+0x612>
ffffffffc020124a:	010a2703          	lw	a4,16(s4)
ffffffffc020124e:	478d                	li	a5,3
ffffffffc0201250:	3af71263          	bne	a4,a5,ffffffffc02015f4 <default_check+0x612>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201254:	8556                	mv	a0,s5
ffffffffc0201256:	4a1000ef          	jal	ffffffffc0201ef6 <alloc_pages>
ffffffffc020125a:	36a99d63          	bne	s3,a0,ffffffffc02015d4 <default_check+0x5f2>
    free_page(p0);
ffffffffc020125e:	85d6                	mv	a1,s5
ffffffffc0201260:	4d1000ef          	jal	ffffffffc0201f30 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201264:	4509                	li	a0,2
ffffffffc0201266:	491000ef          	jal	ffffffffc0201ef6 <alloc_pages>
ffffffffc020126a:	34aa1563          	bne	s4,a0,ffffffffc02015b4 <default_check+0x5d2>

    free_pages(p0, 2);
ffffffffc020126e:	4589                	li	a1,2
ffffffffc0201270:	4c1000ef          	jal	ffffffffc0201f30 <free_pages>
    free_page(p2);
ffffffffc0201274:	04098513          	addi	a0,s3,64
ffffffffc0201278:	85d6                	mv	a1,s5
ffffffffc020127a:	4b7000ef          	jal	ffffffffc0201f30 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020127e:	4515                	li	a0,5
ffffffffc0201280:	477000ef          	jal	ffffffffc0201ef6 <alloc_pages>
ffffffffc0201284:	89aa                	mv	s3,a0
ffffffffc0201286:	48050763          	beqz	a0,ffffffffc0201714 <default_check+0x732>
    assert(alloc_page() == NULL);
ffffffffc020128a:	8556                	mv	a0,s5
ffffffffc020128c:	46b000ef          	jal	ffffffffc0201ef6 <alloc_pages>
ffffffffc0201290:	2e051263          	bnez	a0,ffffffffc0201574 <default_check+0x592>

    assert(nr_free == 0);
ffffffffc0201294:	000a1797          	auipc	a5,0xa1
ffffffffc0201298:	b8c7a783          	lw	a5,-1140(a5) # ffffffffc02a1e20 <free_area+0x10>
ffffffffc020129c:	2a079c63          	bnez	a5,ffffffffc0201554 <default_check+0x572>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02012a0:	854e                	mv	a0,s3
ffffffffc02012a2:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc02012a4:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc02012a8:	01793023          	sd	s7,0(s2)
ffffffffc02012ac:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc02012b0:	481000ef          	jal	ffffffffc0201f30 <free_pages>
    return listelm->next;
ffffffffc02012b4:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc02012b8:	01278963          	beq	a5,s2,ffffffffc02012ca <default_check+0x2e8>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc02012bc:	ff87a703          	lw	a4,-8(a5)
ffffffffc02012c0:	679c                	ld	a5,8(a5)
ffffffffc02012c2:	34fd                	addiw	s1,s1,-1
ffffffffc02012c4:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02012c6:	ff279be3          	bne	a5,s2,ffffffffc02012bc <default_check+0x2da>
    }
    assert(count == 0);
ffffffffc02012ca:	26049563          	bnez	s1,ffffffffc0201534 <default_check+0x552>
    assert(total == 0);
ffffffffc02012ce:	46041363          	bnez	s0,ffffffffc0201734 <default_check+0x752>
}
ffffffffc02012d2:	60e6                	ld	ra,88(sp)
ffffffffc02012d4:	6446                	ld	s0,80(sp)
ffffffffc02012d6:	64a6                	ld	s1,72(sp)
ffffffffc02012d8:	6906                	ld	s2,64(sp)
ffffffffc02012da:	79e2                	ld	s3,56(sp)
ffffffffc02012dc:	7a42                	ld	s4,48(sp)
ffffffffc02012de:	7aa2                	ld	s5,40(sp)
ffffffffc02012e0:	7b02                	ld	s6,32(sp)
ffffffffc02012e2:	6be2                	ld	s7,24(sp)
ffffffffc02012e4:	6c42                	ld	s8,16(sp)
ffffffffc02012e6:	6ca2                	ld	s9,8(sp)
ffffffffc02012e8:	6125                	addi	sp,sp,96
ffffffffc02012ea:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc02012ec:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02012ee:	4401                	li	s0,0
ffffffffc02012f0:	4481                	li	s1,0
ffffffffc02012f2:	bb1d                	j	ffffffffc0201028 <default_check+0x46>
        assert(PageProperty(p));
ffffffffc02012f4:	00005697          	auipc	a3,0x5
ffffffffc02012f8:	18c68693          	addi	a3,a3,396 # ffffffffc0206480 <etext+0x9c6>
ffffffffc02012fc:	00005617          	auipc	a2,0x5
ffffffffc0201300:	f6c60613          	addi	a2,a2,-148 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201304:	11000593          	li	a1,272
ffffffffc0201308:	00005517          	auipc	a0,0x5
ffffffffc020130c:	18850513          	addi	a0,a0,392 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201310:	936ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201314:	00005697          	auipc	a3,0x5
ffffffffc0201318:	23c68693          	addi	a3,a3,572 # ffffffffc0206550 <etext+0xa96>
ffffffffc020131c:	00005617          	auipc	a2,0x5
ffffffffc0201320:	f4c60613          	addi	a2,a2,-180 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201324:	0dc00593          	li	a1,220
ffffffffc0201328:	00005517          	auipc	a0,0x5
ffffffffc020132c:	16850513          	addi	a0,a0,360 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201330:	916ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201334:	00005697          	auipc	a3,0x5
ffffffffc0201338:	2e468693          	addi	a3,a3,740 # ffffffffc0206618 <etext+0xb5e>
ffffffffc020133c:	00005617          	auipc	a2,0x5
ffffffffc0201340:	f2c60613          	addi	a2,a2,-212 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201344:	0f700593          	li	a1,247
ffffffffc0201348:	00005517          	auipc	a0,0x5
ffffffffc020134c:	14850513          	addi	a0,a0,328 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201350:	8f6ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201354:	00005697          	auipc	a3,0x5
ffffffffc0201358:	23c68693          	addi	a3,a3,572 # ffffffffc0206590 <etext+0xad6>
ffffffffc020135c:	00005617          	auipc	a2,0x5
ffffffffc0201360:	f0c60613          	addi	a2,a2,-244 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201364:	0de00593          	li	a1,222
ffffffffc0201368:	00005517          	auipc	a0,0x5
ffffffffc020136c:	12850513          	addi	a0,a0,296 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201370:	8d6ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201374:	00005697          	auipc	a3,0x5
ffffffffc0201378:	1b468693          	addi	a3,a3,436 # ffffffffc0206528 <etext+0xa6e>
ffffffffc020137c:	00005617          	auipc	a2,0x5
ffffffffc0201380:	eec60613          	addi	a2,a2,-276 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201384:	0db00593          	li	a1,219
ffffffffc0201388:	00005517          	auipc	a0,0x5
ffffffffc020138c:	10850513          	addi	a0,a0,264 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201390:	8b6ff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201394:	00005697          	auipc	a3,0x5
ffffffffc0201398:	13468693          	addi	a3,a3,308 # ffffffffc02064c8 <etext+0xa0e>
ffffffffc020139c:	00005617          	auipc	a2,0x5
ffffffffc02013a0:	ecc60613          	addi	a2,a2,-308 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02013a4:	0f000593          	li	a1,240
ffffffffc02013a8:	00005517          	auipc	a0,0x5
ffffffffc02013ac:	0e850513          	addi	a0,a0,232 # ffffffffc0206490 <etext+0x9d6>
ffffffffc02013b0:	896ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 3);
ffffffffc02013b4:	00005697          	auipc	a3,0x5
ffffffffc02013b8:	25468693          	addi	a3,a3,596 # ffffffffc0206608 <etext+0xb4e>
ffffffffc02013bc:	00005617          	auipc	a2,0x5
ffffffffc02013c0:	eac60613          	addi	a2,a2,-340 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02013c4:	0ee00593          	li	a1,238
ffffffffc02013c8:	00005517          	auipc	a0,0x5
ffffffffc02013cc:	0c850513          	addi	a0,a0,200 # ffffffffc0206490 <etext+0x9d6>
ffffffffc02013d0:	876ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013d4:	00005697          	auipc	a3,0x5
ffffffffc02013d8:	21c68693          	addi	a3,a3,540 # ffffffffc02065f0 <etext+0xb36>
ffffffffc02013dc:	00005617          	auipc	a2,0x5
ffffffffc02013e0:	e8c60613          	addi	a2,a2,-372 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02013e4:	0e900593          	li	a1,233
ffffffffc02013e8:	00005517          	auipc	a0,0x5
ffffffffc02013ec:	0a850513          	addi	a0,a0,168 # ffffffffc0206490 <etext+0x9d6>
ffffffffc02013f0:	856ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02013f4:	00005697          	auipc	a3,0x5
ffffffffc02013f8:	1dc68693          	addi	a3,a3,476 # ffffffffc02065d0 <etext+0xb16>
ffffffffc02013fc:	00005617          	auipc	a2,0x5
ffffffffc0201400:	e6c60613          	addi	a2,a2,-404 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201404:	0e000593          	li	a1,224
ffffffffc0201408:	00005517          	auipc	a0,0x5
ffffffffc020140c:	08850513          	addi	a0,a0,136 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201410:	836ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 != NULL);
ffffffffc0201414:	00005697          	auipc	a3,0x5
ffffffffc0201418:	24c68693          	addi	a3,a3,588 # ffffffffc0206660 <etext+0xba6>
ffffffffc020141c:	00005617          	auipc	a2,0x5
ffffffffc0201420:	e4c60613          	addi	a2,a2,-436 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201424:	11800593          	li	a1,280
ffffffffc0201428:	00005517          	auipc	a0,0x5
ffffffffc020142c:	06850513          	addi	a0,a0,104 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201430:	816ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 0);
ffffffffc0201434:	00005697          	auipc	a3,0x5
ffffffffc0201438:	21c68693          	addi	a3,a3,540 # ffffffffc0206650 <etext+0xb96>
ffffffffc020143c:	00005617          	auipc	a2,0x5
ffffffffc0201440:	e2c60613          	addi	a2,a2,-468 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201444:	0fd00593          	li	a1,253
ffffffffc0201448:	00005517          	auipc	a0,0x5
ffffffffc020144c:	04850513          	addi	a0,a0,72 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201450:	ff7fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201454:	00005697          	auipc	a3,0x5
ffffffffc0201458:	19c68693          	addi	a3,a3,412 # ffffffffc02065f0 <etext+0xb36>
ffffffffc020145c:	00005617          	auipc	a2,0x5
ffffffffc0201460:	e0c60613          	addi	a2,a2,-500 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201464:	0fb00593          	li	a1,251
ffffffffc0201468:	00005517          	auipc	a0,0x5
ffffffffc020146c:	02850513          	addi	a0,a0,40 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201470:	fd7fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201474:	00005697          	auipc	a3,0x5
ffffffffc0201478:	1bc68693          	addi	a3,a3,444 # ffffffffc0206630 <etext+0xb76>
ffffffffc020147c:	00005617          	auipc	a2,0x5
ffffffffc0201480:	dec60613          	addi	a2,a2,-532 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201484:	0fa00593          	li	a1,250
ffffffffc0201488:	00005517          	auipc	a0,0x5
ffffffffc020148c:	00850513          	addi	a0,a0,8 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201490:	fb7fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201494:	00005697          	auipc	a3,0x5
ffffffffc0201498:	03468693          	addi	a3,a3,52 # ffffffffc02064c8 <etext+0xa0e>
ffffffffc020149c:	00005617          	auipc	a2,0x5
ffffffffc02014a0:	dcc60613          	addi	a2,a2,-564 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02014a4:	0d700593          	li	a1,215
ffffffffc02014a8:	00005517          	auipc	a0,0x5
ffffffffc02014ac:	fe850513          	addi	a0,a0,-24 # ffffffffc0206490 <etext+0x9d6>
ffffffffc02014b0:	f97fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014b4:	00005697          	auipc	a3,0x5
ffffffffc02014b8:	13c68693          	addi	a3,a3,316 # ffffffffc02065f0 <etext+0xb36>
ffffffffc02014bc:	00005617          	auipc	a2,0x5
ffffffffc02014c0:	dac60613          	addi	a2,a2,-596 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02014c4:	0f400593          	li	a1,244
ffffffffc02014c8:	00005517          	auipc	a0,0x5
ffffffffc02014cc:	fc850513          	addi	a0,a0,-56 # ffffffffc0206490 <etext+0x9d6>
ffffffffc02014d0:	f77fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02014d4:	00005697          	auipc	a3,0x5
ffffffffc02014d8:	03468693          	addi	a3,a3,52 # ffffffffc0206508 <etext+0xa4e>
ffffffffc02014dc:	00005617          	auipc	a2,0x5
ffffffffc02014e0:	d8c60613          	addi	a2,a2,-628 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02014e4:	0f200593          	li	a1,242
ffffffffc02014e8:	00005517          	auipc	a0,0x5
ffffffffc02014ec:	fa850513          	addi	a0,a0,-88 # ffffffffc0206490 <etext+0x9d6>
ffffffffc02014f0:	f57fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02014f4:	00005697          	auipc	a3,0x5
ffffffffc02014f8:	ff468693          	addi	a3,a3,-12 # ffffffffc02064e8 <etext+0xa2e>
ffffffffc02014fc:	00005617          	auipc	a2,0x5
ffffffffc0201500:	d6c60613          	addi	a2,a2,-660 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201504:	0f100593          	li	a1,241
ffffffffc0201508:	00005517          	auipc	a0,0x5
ffffffffc020150c:	f8850513          	addi	a0,a0,-120 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201510:	f37fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201514:	00005697          	auipc	a3,0x5
ffffffffc0201518:	ff468693          	addi	a3,a3,-12 # ffffffffc0206508 <etext+0xa4e>
ffffffffc020151c:	00005617          	auipc	a2,0x5
ffffffffc0201520:	d4c60613          	addi	a2,a2,-692 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201524:	0d900593          	li	a1,217
ffffffffc0201528:	00005517          	auipc	a0,0x5
ffffffffc020152c:	f6850513          	addi	a0,a0,-152 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201530:	f17fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(count == 0);
ffffffffc0201534:	00005697          	auipc	a3,0x5
ffffffffc0201538:	27c68693          	addi	a3,a3,636 # ffffffffc02067b0 <etext+0xcf6>
ffffffffc020153c:	00005617          	auipc	a2,0x5
ffffffffc0201540:	d2c60613          	addi	a2,a2,-724 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201544:	14600593          	li	a1,326
ffffffffc0201548:	00005517          	auipc	a0,0x5
ffffffffc020154c:	f4850513          	addi	a0,a0,-184 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201550:	ef7fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 0);
ffffffffc0201554:	00005697          	auipc	a3,0x5
ffffffffc0201558:	0fc68693          	addi	a3,a3,252 # ffffffffc0206650 <etext+0xb96>
ffffffffc020155c:	00005617          	auipc	a2,0x5
ffffffffc0201560:	d0c60613          	addi	a2,a2,-756 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201564:	13a00593          	li	a1,314
ffffffffc0201568:	00005517          	auipc	a0,0x5
ffffffffc020156c:	f2850513          	addi	a0,a0,-216 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201570:	ed7fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201574:	00005697          	auipc	a3,0x5
ffffffffc0201578:	07c68693          	addi	a3,a3,124 # ffffffffc02065f0 <etext+0xb36>
ffffffffc020157c:	00005617          	auipc	a2,0x5
ffffffffc0201580:	cec60613          	addi	a2,a2,-788 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201584:	13800593          	li	a1,312
ffffffffc0201588:	00005517          	auipc	a0,0x5
ffffffffc020158c:	f0850513          	addi	a0,a0,-248 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201590:	eb7fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201594:	00005697          	auipc	a3,0x5
ffffffffc0201598:	01c68693          	addi	a3,a3,28 # ffffffffc02065b0 <etext+0xaf6>
ffffffffc020159c:	00005617          	auipc	a2,0x5
ffffffffc02015a0:	ccc60613          	addi	a2,a2,-820 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02015a4:	0df00593          	li	a1,223
ffffffffc02015a8:	00005517          	auipc	a0,0x5
ffffffffc02015ac:	ee850513          	addi	a0,a0,-280 # ffffffffc0206490 <etext+0x9d6>
ffffffffc02015b0:	e97fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02015b4:	00005697          	auipc	a3,0x5
ffffffffc02015b8:	1bc68693          	addi	a3,a3,444 # ffffffffc0206770 <etext+0xcb6>
ffffffffc02015bc:	00005617          	auipc	a2,0x5
ffffffffc02015c0:	cac60613          	addi	a2,a2,-852 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02015c4:	13200593          	li	a1,306
ffffffffc02015c8:	00005517          	auipc	a0,0x5
ffffffffc02015cc:	ec850513          	addi	a0,a0,-312 # ffffffffc0206490 <etext+0x9d6>
ffffffffc02015d0:	e77fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02015d4:	00005697          	auipc	a3,0x5
ffffffffc02015d8:	17c68693          	addi	a3,a3,380 # ffffffffc0206750 <etext+0xc96>
ffffffffc02015dc:	00005617          	auipc	a2,0x5
ffffffffc02015e0:	c8c60613          	addi	a2,a2,-884 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02015e4:	13000593          	li	a1,304
ffffffffc02015e8:	00005517          	auipc	a0,0x5
ffffffffc02015ec:	ea850513          	addi	a0,a0,-344 # ffffffffc0206490 <etext+0x9d6>
ffffffffc02015f0:	e57fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02015f4:	00005697          	auipc	a3,0x5
ffffffffc02015f8:	13468693          	addi	a3,a3,308 # ffffffffc0206728 <etext+0xc6e>
ffffffffc02015fc:	00005617          	auipc	a2,0x5
ffffffffc0201600:	c6c60613          	addi	a2,a2,-916 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201604:	12e00593          	li	a1,302
ffffffffc0201608:	00005517          	auipc	a0,0x5
ffffffffc020160c:	e8850513          	addi	a0,a0,-376 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201610:	e37fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201614:	00005697          	auipc	a3,0x5
ffffffffc0201618:	0ec68693          	addi	a3,a3,236 # ffffffffc0206700 <etext+0xc46>
ffffffffc020161c:	00005617          	auipc	a2,0x5
ffffffffc0201620:	c4c60613          	addi	a2,a2,-948 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201624:	12d00593          	li	a1,301
ffffffffc0201628:	00005517          	auipc	a0,0x5
ffffffffc020162c:	e6850513          	addi	a0,a0,-408 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201630:	e17fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201634:	00005697          	auipc	a3,0x5
ffffffffc0201638:	0bc68693          	addi	a3,a3,188 # ffffffffc02066f0 <etext+0xc36>
ffffffffc020163c:	00005617          	auipc	a2,0x5
ffffffffc0201640:	c2c60613          	addi	a2,a2,-980 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201644:	12800593          	li	a1,296
ffffffffc0201648:	00005517          	auipc	a0,0x5
ffffffffc020164c:	e4850513          	addi	a0,a0,-440 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201650:	df7fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201654:	00005697          	auipc	a3,0x5
ffffffffc0201658:	f9c68693          	addi	a3,a3,-100 # ffffffffc02065f0 <etext+0xb36>
ffffffffc020165c:	00005617          	auipc	a2,0x5
ffffffffc0201660:	c0c60613          	addi	a2,a2,-1012 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201664:	12700593          	li	a1,295
ffffffffc0201668:	00005517          	auipc	a0,0x5
ffffffffc020166c:	e2850513          	addi	a0,a0,-472 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201670:	dd7fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201674:	00005697          	auipc	a3,0x5
ffffffffc0201678:	05c68693          	addi	a3,a3,92 # ffffffffc02066d0 <etext+0xc16>
ffffffffc020167c:	00005617          	auipc	a2,0x5
ffffffffc0201680:	bec60613          	addi	a2,a2,-1044 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201684:	12600593          	li	a1,294
ffffffffc0201688:	00005517          	auipc	a0,0x5
ffffffffc020168c:	e0850513          	addi	a0,a0,-504 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201690:	db7fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201694:	00005697          	auipc	a3,0x5
ffffffffc0201698:	00c68693          	addi	a3,a3,12 # ffffffffc02066a0 <etext+0xbe6>
ffffffffc020169c:	00005617          	auipc	a2,0x5
ffffffffc02016a0:	bcc60613          	addi	a2,a2,-1076 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02016a4:	12500593          	li	a1,293
ffffffffc02016a8:	00005517          	auipc	a0,0x5
ffffffffc02016ac:	de850513          	addi	a0,a0,-536 # ffffffffc0206490 <etext+0x9d6>
ffffffffc02016b0:	d97fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02016b4:	00005697          	auipc	a3,0x5
ffffffffc02016b8:	fd468693          	addi	a3,a3,-44 # ffffffffc0206688 <etext+0xbce>
ffffffffc02016bc:	00005617          	auipc	a2,0x5
ffffffffc02016c0:	bac60613          	addi	a2,a2,-1108 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02016c4:	12400593          	li	a1,292
ffffffffc02016c8:	00005517          	auipc	a0,0x5
ffffffffc02016cc:	dc850513          	addi	a0,a0,-568 # ffffffffc0206490 <etext+0x9d6>
ffffffffc02016d0:	d77fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02016d4:	00005697          	auipc	a3,0x5
ffffffffc02016d8:	f1c68693          	addi	a3,a3,-228 # ffffffffc02065f0 <etext+0xb36>
ffffffffc02016dc:	00005617          	auipc	a2,0x5
ffffffffc02016e0:	b8c60613          	addi	a2,a2,-1140 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02016e4:	11e00593          	li	a1,286
ffffffffc02016e8:	00005517          	auipc	a0,0x5
ffffffffc02016ec:	da850513          	addi	a0,a0,-600 # ffffffffc0206490 <etext+0x9d6>
ffffffffc02016f0:	d57fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(!PageProperty(p0));
ffffffffc02016f4:	00005697          	auipc	a3,0x5
ffffffffc02016f8:	f7c68693          	addi	a3,a3,-132 # ffffffffc0206670 <etext+0xbb6>
ffffffffc02016fc:	00005617          	auipc	a2,0x5
ffffffffc0201700:	b6c60613          	addi	a2,a2,-1172 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201704:	11900593          	li	a1,281
ffffffffc0201708:	00005517          	auipc	a0,0x5
ffffffffc020170c:	d8850513          	addi	a0,a0,-632 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201710:	d37fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201714:	00005697          	auipc	a3,0x5
ffffffffc0201718:	07c68693          	addi	a3,a3,124 # ffffffffc0206790 <etext+0xcd6>
ffffffffc020171c:	00005617          	auipc	a2,0x5
ffffffffc0201720:	b4c60613          	addi	a2,a2,-1204 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201724:	13700593          	li	a1,311
ffffffffc0201728:	00005517          	auipc	a0,0x5
ffffffffc020172c:	d6850513          	addi	a0,a0,-664 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201730:	d17fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(total == 0);
ffffffffc0201734:	00005697          	auipc	a3,0x5
ffffffffc0201738:	08c68693          	addi	a3,a3,140 # ffffffffc02067c0 <etext+0xd06>
ffffffffc020173c:	00005617          	auipc	a2,0x5
ffffffffc0201740:	b2c60613          	addi	a2,a2,-1236 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201744:	14700593          	li	a1,327
ffffffffc0201748:	00005517          	auipc	a0,0x5
ffffffffc020174c:	d4850513          	addi	a0,a0,-696 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201750:	cf7fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(total == nr_free_pages());
ffffffffc0201754:	00005697          	auipc	a3,0x5
ffffffffc0201758:	d5468693          	addi	a3,a3,-684 # ffffffffc02064a8 <etext+0x9ee>
ffffffffc020175c:	00005617          	auipc	a2,0x5
ffffffffc0201760:	b0c60613          	addi	a2,a2,-1268 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201764:	11300593          	li	a1,275
ffffffffc0201768:	00005517          	auipc	a0,0x5
ffffffffc020176c:	d2850513          	addi	a0,a0,-728 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201770:	cd7fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201774:	00005697          	auipc	a3,0x5
ffffffffc0201778:	d7468693          	addi	a3,a3,-652 # ffffffffc02064e8 <etext+0xa2e>
ffffffffc020177c:	00005617          	auipc	a2,0x5
ffffffffc0201780:	aec60613          	addi	a2,a2,-1300 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201784:	0d800593          	li	a1,216
ffffffffc0201788:	00005517          	auipc	a0,0x5
ffffffffc020178c:	d0850513          	addi	a0,a0,-760 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201790:	cb7fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201794 <default_free_pages>:
{
ffffffffc0201794:	1141                	addi	sp,sp,-16
ffffffffc0201796:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201798:	14058663          	beqz	a1,ffffffffc02018e4 <default_free_pages+0x150>
    for (; p != base + n; p++)
ffffffffc020179c:	00659713          	slli	a4,a1,0x6
ffffffffc02017a0:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc02017a4:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc02017a6:	c30d                	beqz	a4,ffffffffc02017c8 <default_free_pages+0x34>
ffffffffc02017a8:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02017aa:	8b05                	andi	a4,a4,1
ffffffffc02017ac:	10071c63          	bnez	a4,ffffffffc02018c4 <default_free_pages+0x130>
ffffffffc02017b0:	6798                	ld	a4,8(a5)
ffffffffc02017b2:	8b09                	andi	a4,a4,2
ffffffffc02017b4:	10071863          	bnez	a4,ffffffffc02018c4 <default_free_pages+0x130>
        p->flags = 0;
ffffffffc02017b8:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc02017bc:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02017c0:	04078793          	addi	a5,a5,64
ffffffffc02017c4:	fed792e3          	bne	a5,a3,ffffffffc02017a8 <default_free_pages+0x14>
    base->property = n;
ffffffffc02017c8:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02017ca:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02017ce:	4789                	li	a5,2
ffffffffc02017d0:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02017d4:	000a0717          	auipc	a4,0xa0
ffffffffc02017d8:	64c72703          	lw	a4,1612(a4) # ffffffffc02a1e20 <free_area+0x10>
ffffffffc02017dc:	000a0697          	auipc	a3,0xa0
ffffffffc02017e0:	63468693          	addi	a3,a3,1588 # ffffffffc02a1e10 <free_area>
    return list->next == list;
ffffffffc02017e4:	669c                	ld	a5,8(a3)
ffffffffc02017e6:	9f2d                	addw	a4,a4,a1
ffffffffc02017e8:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc02017ea:	0ad78163          	beq	a5,a3,ffffffffc020188c <default_free_pages+0xf8>
            struct Page *page = le2page(le, page_link);
ffffffffc02017ee:	fe878713          	addi	a4,a5,-24
ffffffffc02017f2:	4581                	li	a1,0
ffffffffc02017f4:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc02017f8:	00e56a63          	bltu	a0,a4,ffffffffc020180c <default_free_pages+0x78>
    return listelm->next;
ffffffffc02017fc:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02017fe:	04d70c63          	beq	a4,a3,ffffffffc0201856 <default_free_pages+0xc2>
    struct Page *p = base;
ffffffffc0201802:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201804:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201808:	fee57ae3          	bgeu	a0,a4,ffffffffc02017fc <default_free_pages+0x68>
ffffffffc020180c:	c199                	beqz	a1,ffffffffc0201812 <default_free_pages+0x7e>
ffffffffc020180e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201812:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201814:	e390                	sd	a2,0(a5)
ffffffffc0201816:	e710                	sd	a2,8(a4)
    elm->next = next;
    elm->prev = prev;
ffffffffc0201818:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc020181a:	f11c                	sd	a5,32(a0)
    if (le != &free_list)
ffffffffc020181c:	00d70d63          	beq	a4,a3,ffffffffc0201836 <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc0201820:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201824:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc0201828:	02059813          	slli	a6,a1,0x20
ffffffffc020182c:	01a85793          	srli	a5,a6,0x1a
ffffffffc0201830:	97b2                	add	a5,a5,a2
ffffffffc0201832:	02f50c63          	beq	a0,a5,ffffffffc020186a <default_free_pages+0xd6>
    return listelm->next;
ffffffffc0201836:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc0201838:	00d78c63          	beq	a5,a3,ffffffffc0201850 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc020183c:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc020183e:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc0201842:	02061593          	slli	a1,a2,0x20
ffffffffc0201846:	01a5d713          	srli	a4,a1,0x1a
ffffffffc020184a:	972a                	add	a4,a4,a0
ffffffffc020184c:	04e68c63          	beq	a3,a4,ffffffffc02018a4 <default_free_pages+0x110>
}
ffffffffc0201850:	60a2                	ld	ra,8(sp)
ffffffffc0201852:	0141                	addi	sp,sp,16
ffffffffc0201854:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201856:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201858:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020185a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020185c:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc020185e:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc0201860:	02d70f63          	beq	a4,a3,ffffffffc020189e <default_free_pages+0x10a>
ffffffffc0201864:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201866:	87ba                	mv	a5,a4
ffffffffc0201868:	bf71                	j	ffffffffc0201804 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc020186a:	491c                	lw	a5,16(a0)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020186c:	5875                	li	a6,-3
ffffffffc020186e:	9fad                	addw	a5,a5,a1
ffffffffc0201870:	fef72c23          	sw	a5,-8(a4)
ffffffffc0201874:	6108b02f          	amoand.d	zero,a6,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201878:	01853803          	ld	a6,24(a0)
ffffffffc020187c:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc020187e:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201880:	00b83423          	sd	a1,8(a6) # ff0008 <_binary_obj___user_COW_out_size+0xfe5be8>
    return listelm->next;
ffffffffc0201884:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0201886:	0105b023          	sd	a6,0(a1)
ffffffffc020188a:	b77d                	j	ffffffffc0201838 <default_free_pages+0xa4>
}
ffffffffc020188c:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc020188e:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0201892:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201894:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0201896:	e398                	sd	a4,0(a5)
ffffffffc0201898:	e798                	sd	a4,8(a5)
}
ffffffffc020189a:	0141                	addi	sp,sp,16
ffffffffc020189c:	8082                	ret
ffffffffc020189e:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc02018a0:	873e                	mv	a4,a5
ffffffffc02018a2:	bfad                	j	ffffffffc020181c <default_free_pages+0x88>
            base->property += p->property;
ffffffffc02018a4:	ff87a703          	lw	a4,-8(a5)
ffffffffc02018a8:	56f5                	li	a3,-3
ffffffffc02018aa:	9f31                	addw	a4,a4,a2
ffffffffc02018ac:	c918                	sw	a4,16(a0)
ffffffffc02018ae:	ff078713          	addi	a4,a5,-16
ffffffffc02018b2:	60d7302f          	amoand.d	zero,a3,(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc02018b6:	6398                	ld	a4,0(a5)
ffffffffc02018b8:	679c                	ld	a5,8(a5)
}
ffffffffc02018ba:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02018bc:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02018be:	e398                	sd	a4,0(a5)
ffffffffc02018c0:	0141                	addi	sp,sp,16
ffffffffc02018c2:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02018c4:	00005697          	auipc	a3,0x5
ffffffffc02018c8:	f1468693          	addi	a3,a3,-236 # ffffffffc02067d8 <etext+0xd1e>
ffffffffc02018cc:	00005617          	auipc	a2,0x5
ffffffffc02018d0:	99c60613          	addi	a2,a2,-1636 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02018d4:	09400593          	li	a1,148
ffffffffc02018d8:	00005517          	auipc	a0,0x5
ffffffffc02018dc:	bb850513          	addi	a0,a0,-1096 # ffffffffc0206490 <etext+0x9d6>
ffffffffc02018e0:	b67fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(n > 0);
ffffffffc02018e4:	00005697          	auipc	a3,0x5
ffffffffc02018e8:	eec68693          	addi	a3,a3,-276 # ffffffffc02067d0 <etext+0xd16>
ffffffffc02018ec:	00005617          	auipc	a2,0x5
ffffffffc02018f0:	97c60613          	addi	a2,a2,-1668 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02018f4:	09000593          	li	a1,144
ffffffffc02018f8:	00005517          	auipc	a0,0x5
ffffffffc02018fc:	b9850513          	addi	a0,a0,-1128 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201900:	b47fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201904 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201904:	c951                	beqz	a0,ffffffffc0201998 <default_alloc_pages+0x94>
    if (n > nr_free)
ffffffffc0201906:	000a0597          	auipc	a1,0xa0
ffffffffc020190a:	51a5a583          	lw	a1,1306(a1) # ffffffffc02a1e20 <free_area+0x10>
ffffffffc020190e:	86aa                	mv	a3,a0
ffffffffc0201910:	02059793          	slli	a5,a1,0x20
ffffffffc0201914:	9381                	srli	a5,a5,0x20
ffffffffc0201916:	00a7ef63          	bltu	a5,a0,ffffffffc0201934 <default_alloc_pages+0x30>
    list_entry_t *le = &free_list;
ffffffffc020191a:	000a0617          	auipc	a2,0xa0
ffffffffc020191e:	4f660613          	addi	a2,a2,1270 # ffffffffc02a1e10 <free_area>
ffffffffc0201922:	87b2                	mv	a5,a2
ffffffffc0201924:	a029                	j	ffffffffc020192e <default_alloc_pages+0x2a>
        if (p->property >= n)
ffffffffc0201926:	ff87e703          	lwu	a4,-8(a5)
ffffffffc020192a:	00d77763          	bgeu	a4,a3,ffffffffc0201938 <default_alloc_pages+0x34>
    return listelm->next;
ffffffffc020192e:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc0201930:	fec79be3          	bne	a5,a2,ffffffffc0201926 <default_alloc_pages+0x22>
        return NULL;
ffffffffc0201934:	4501                	li	a0,0
}
ffffffffc0201936:	8082                	ret
        if (page->property > n)
ffffffffc0201938:	ff87a883          	lw	a7,-8(a5)
    return listelm->prev;
ffffffffc020193c:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201940:	6798                	ld	a4,8(a5)
ffffffffc0201942:	02089313          	slli	t1,a7,0x20
ffffffffc0201946:	02035313          	srli	t1,t1,0x20
    prev->next = next;
ffffffffc020194a:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc020194e:	01073023          	sd	a6,0(a4)
        struct Page *p = le2page(le, page_link);
ffffffffc0201952:	fe878513          	addi	a0,a5,-24
        if (page->property > n)
ffffffffc0201956:	0266fa63          	bgeu	a3,t1,ffffffffc020198a <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc020195a:	00669713          	slli	a4,a3,0x6
            p->property = page->property - n;
ffffffffc020195e:	40d888bb          	subw	a7,a7,a3
            struct Page *p = page + n;
ffffffffc0201962:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201964:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201968:	00870313          	addi	t1,a4,8
ffffffffc020196c:	4889                	li	a7,2
ffffffffc020196e:	4113302f          	amoor.d	zero,a7,(t1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201972:	00883883          	ld	a7,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc0201976:	01870313          	addi	t1,a4,24
    prev->next = next->prev = elm;
ffffffffc020197a:	0068b023          	sd	t1,0(a7)
ffffffffc020197e:	00683423          	sd	t1,8(a6)
    elm->next = next;
ffffffffc0201982:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc0201986:	01073c23          	sd	a6,24(a4)
        nr_free -= n;
ffffffffc020198a:	9d95                	subw	a1,a1,a3
ffffffffc020198c:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020198e:	5775                	li	a4,-3
ffffffffc0201990:	17c1                	addi	a5,a5,-16
ffffffffc0201992:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201996:	8082                	ret
{
ffffffffc0201998:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020199a:	00005697          	auipc	a3,0x5
ffffffffc020199e:	e3668693          	addi	a3,a3,-458 # ffffffffc02067d0 <etext+0xd16>
ffffffffc02019a2:	00005617          	auipc	a2,0x5
ffffffffc02019a6:	8c660613          	addi	a2,a2,-1850 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02019aa:	06c00593          	li	a1,108
ffffffffc02019ae:	00005517          	auipc	a0,0x5
ffffffffc02019b2:	ae250513          	addi	a0,a0,-1310 # ffffffffc0206490 <etext+0x9d6>
{
ffffffffc02019b6:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02019b8:	a8ffe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02019bc <default_init_memmap>:
{
ffffffffc02019bc:	1141                	addi	sp,sp,-16
ffffffffc02019be:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02019c0:	c9e1                	beqz	a1,ffffffffc0201a90 <default_init_memmap+0xd4>
    for (; p != base + n; p++)
ffffffffc02019c2:	00659713          	slli	a4,a1,0x6
ffffffffc02019c6:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc02019ca:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc02019cc:	cf11                	beqz	a4,ffffffffc02019e8 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02019ce:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02019d0:	8b05                	andi	a4,a4,1
ffffffffc02019d2:	cf59                	beqz	a4,ffffffffc0201a70 <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc02019d4:	0007a823          	sw	zero,16(a5)
ffffffffc02019d8:	0007b423          	sd	zero,8(a5)
ffffffffc02019dc:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02019e0:	04078793          	addi	a5,a5,64
ffffffffc02019e4:	fed795e3          	bne	a5,a3,ffffffffc02019ce <default_init_memmap+0x12>
    base->property = n;
ffffffffc02019e8:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02019ea:	4789                	li	a5,2
ffffffffc02019ec:	00850713          	addi	a4,a0,8
ffffffffc02019f0:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02019f4:	000a0717          	auipc	a4,0xa0
ffffffffc02019f8:	42c72703          	lw	a4,1068(a4) # ffffffffc02a1e20 <free_area+0x10>
ffffffffc02019fc:	000a0697          	auipc	a3,0xa0
ffffffffc0201a00:	41468693          	addi	a3,a3,1044 # ffffffffc02a1e10 <free_area>
    return list->next == list;
ffffffffc0201a04:	669c                	ld	a5,8(a3)
ffffffffc0201a06:	9f2d                	addw	a4,a4,a1
ffffffffc0201a08:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc0201a0a:	04d78663          	beq	a5,a3,ffffffffc0201a56 <default_init_memmap+0x9a>
            struct Page *page = le2page(le, page_link);
ffffffffc0201a0e:	fe878713          	addi	a4,a5,-24
ffffffffc0201a12:	4581                	li	a1,0
ffffffffc0201a14:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc0201a18:	00e56a63          	bltu	a0,a4,ffffffffc0201a2c <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201a1c:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201a1e:	02d70263          	beq	a4,a3,ffffffffc0201a42 <default_init_memmap+0x86>
    struct Page *p = base;
ffffffffc0201a22:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201a24:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201a28:	fee57ae3          	bgeu	a0,a4,ffffffffc0201a1c <default_init_memmap+0x60>
ffffffffc0201a2c:	c199                	beqz	a1,ffffffffc0201a32 <default_init_memmap+0x76>
ffffffffc0201a2e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201a32:	6398                	ld	a4,0(a5)
}
ffffffffc0201a34:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201a36:	e390                	sd	a2,0(a5)
ffffffffc0201a38:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc0201a3a:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc0201a3c:	f11c                	sd	a5,32(a0)
ffffffffc0201a3e:	0141                	addi	sp,sp,16
ffffffffc0201a40:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201a42:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a44:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201a46:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201a48:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201a4a:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc0201a4c:	00d70e63          	beq	a4,a3,ffffffffc0201a68 <default_init_memmap+0xac>
ffffffffc0201a50:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201a52:	87ba                	mv	a5,a4
ffffffffc0201a54:	bfc1                	j	ffffffffc0201a24 <default_init_memmap+0x68>
}
ffffffffc0201a56:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201a58:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0201a5c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a5e:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0201a60:	e398                	sd	a4,0(a5)
ffffffffc0201a62:	e798                	sd	a4,8(a5)
}
ffffffffc0201a64:	0141                	addi	sp,sp,16
ffffffffc0201a66:	8082                	ret
ffffffffc0201a68:	60a2                	ld	ra,8(sp)
ffffffffc0201a6a:	e290                	sd	a2,0(a3)
ffffffffc0201a6c:	0141                	addi	sp,sp,16
ffffffffc0201a6e:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201a70:	00005697          	auipc	a3,0x5
ffffffffc0201a74:	d9068693          	addi	a3,a3,-624 # ffffffffc0206800 <etext+0xd46>
ffffffffc0201a78:	00004617          	auipc	a2,0x4
ffffffffc0201a7c:	7f060613          	addi	a2,a2,2032 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201a80:	04b00593          	li	a1,75
ffffffffc0201a84:	00005517          	auipc	a0,0x5
ffffffffc0201a88:	a0c50513          	addi	a0,a0,-1524 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201a8c:	9bbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(n > 0);
ffffffffc0201a90:	00005697          	auipc	a3,0x5
ffffffffc0201a94:	d4068693          	addi	a3,a3,-704 # ffffffffc02067d0 <etext+0xd16>
ffffffffc0201a98:	00004617          	auipc	a2,0x4
ffffffffc0201a9c:	7d060613          	addi	a2,a2,2000 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201aa0:	04700593          	li	a1,71
ffffffffc0201aa4:	00005517          	auipc	a0,0x5
ffffffffc0201aa8:	9ec50513          	addi	a0,a0,-1556 # ffffffffc0206490 <etext+0x9d6>
ffffffffc0201aac:	99bfe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201ab0 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201ab0:	c531                	beqz	a0,ffffffffc0201afc <slob_free+0x4c>
		return;

	if (size)
ffffffffc0201ab2:	e9b9                	bnez	a1,ffffffffc0201b08 <slob_free+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ab4:	100027f3          	csrr	a5,sstatus
ffffffffc0201ab8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201aba:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201abc:	efb1                	bnez	a5,ffffffffc0201b18 <slob_free+0x68>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201abe:	000a0797          	auipc	a5,0xa0
ffffffffc0201ac2:	f427b783          	ld	a5,-190(a5) # ffffffffc02a1a00 <slobfree>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201ac6:	873e                	mv	a4,a5
ffffffffc0201ac8:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201aca:	02a77a63          	bgeu	a4,a0,ffffffffc0201afe <slob_free+0x4e>
ffffffffc0201ace:	00f56463          	bltu	a0,a5,ffffffffc0201ad6 <slob_free+0x26>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201ad2:	fef76ae3          	bltu	a4,a5,ffffffffc0201ac6 <slob_free+0x16>
			break;

	if (b + b->units == cur->next)
ffffffffc0201ad6:	4110                	lw	a2,0(a0)
ffffffffc0201ad8:	00461693          	slli	a3,a2,0x4
ffffffffc0201adc:	96aa                	add	a3,a3,a0
ffffffffc0201ade:	0ad78463          	beq	a5,a3,ffffffffc0201b86 <slob_free+0xd6>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201ae2:	4310                	lw	a2,0(a4)
ffffffffc0201ae4:	e51c                	sd	a5,8(a0)
ffffffffc0201ae6:	00461693          	slli	a3,a2,0x4
ffffffffc0201aea:	96ba                	add	a3,a3,a4
ffffffffc0201aec:	08d50163          	beq	a0,a3,ffffffffc0201b6e <slob_free+0xbe>
ffffffffc0201af0:	e708                	sd	a0,8(a4)
		cur->next = b->next;
	}
	else
		cur->next = b;

	slobfree = cur;
ffffffffc0201af2:	000a0797          	auipc	a5,0xa0
ffffffffc0201af6:	f0e7b723          	sd	a4,-242(a5) # ffffffffc02a1a00 <slobfree>
    if (flag)
ffffffffc0201afa:	e9a5                	bnez	a1,ffffffffc0201b6a <slob_free+0xba>
ffffffffc0201afc:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201afe:	fcf574e3          	bgeu	a0,a5,ffffffffc0201ac6 <slob_free+0x16>
ffffffffc0201b02:	fcf762e3          	bltu	a4,a5,ffffffffc0201ac6 <slob_free+0x16>
ffffffffc0201b06:	bfc1                	j	ffffffffc0201ad6 <slob_free+0x26>
		b->units = SLOB_UNITS(size);
ffffffffc0201b08:	25bd                	addiw	a1,a1,15
ffffffffc0201b0a:	8191                	srli	a1,a1,0x4
ffffffffc0201b0c:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b0e:	100027f3          	csrr	a5,sstatus
ffffffffc0201b12:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201b14:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b16:	d7c5                	beqz	a5,ffffffffc0201abe <slob_free+0xe>
{
ffffffffc0201b18:	1101                	addi	sp,sp,-32
ffffffffc0201b1a:	e42a                	sd	a0,8(sp)
ffffffffc0201b1c:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201b1e:	de7fe0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0201b22:	6522                	ld	a0,8(sp)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201b24:	000a0797          	auipc	a5,0xa0
ffffffffc0201b28:	edc7b783          	ld	a5,-292(a5) # ffffffffc02a1a00 <slobfree>
ffffffffc0201b2c:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b2e:	873e                	mv	a4,a5
ffffffffc0201b30:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201b32:	06a77663          	bgeu	a4,a0,ffffffffc0201b9e <slob_free+0xee>
ffffffffc0201b36:	00f56463          	bltu	a0,a5,ffffffffc0201b3e <slob_free+0x8e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b3a:	fef76ae3          	bltu	a4,a5,ffffffffc0201b2e <slob_free+0x7e>
	if (b + b->units == cur->next)
ffffffffc0201b3e:	4110                	lw	a2,0(a0)
ffffffffc0201b40:	00461693          	slli	a3,a2,0x4
ffffffffc0201b44:	96aa                	add	a3,a3,a0
ffffffffc0201b46:	06d78363          	beq	a5,a3,ffffffffc0201bac <slob_free+0xfc>
	if (cur + cur->units == b)
ffffffffc0201b4a:	4310                	lw	a2,0(a4)
ffffffffc0201b4c:	e51c                	sd	a5,8(a0)
ffffffffc0201b4e:	00461693          	slli	a3,a2,0x4
ffffffffc0201b52:	96ba                	add	a3,a3,a4
ffffffffc0201b54:	06d50163          	beq	a0,a3,ffffffffc0201bb6 <slob_free+0x106>
ffffffffc0201b58:	e708                	sd	a0,8(a4)
	slobfree = cur;
ffffffffc0201b5a:	000a0797          	auipc	a5,0xa0
ffffffffc0201b5e:	eae7b323          	sd	a4,-346(a5) # ffffffffc02a1a00 <slobfree>
    if (flag)
ffffffffc0201b62:	e1a9                	bnez	a1,ffffffffc0201ba4 <slob_free+0xf4>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201b64:	60e2                	ld	ra,24(sp)
ffffffffc0201b66:	6105                	addi	sp,sp,32
ffffffffc0201b68:	8082                	ret
        intr_enable();
ffffffffc0201b6a:	d95fe06f          	j	ffffffffc02008fe <intr_enable>
		cur->units += b->units;
ffffffffc0201b6e:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201b70:	853e                	mv	a0,a5
ffffffffc0201b72:	e708                	sd	a0,8(a4)
		cur->units += b->units;
ffffffffc0201b74:	00c687bb          	addw	a5,a3,a2
ffffffffc0201b78:	c31c                	sw	a5,0(a4)
	slobfree = cur;
ffffffffc0201b7a:	000a0797          	auipc	a5,0xa0
ffffffffc0201b7e:	e8e7b323          	sd	a4,-378(a5) # ffffffffc02a1a00 <slobfree>
    if (flag)
ffffffffc0201b82:	ddad                	beqz	a1,ffffffffc0201afc <slob_free+0x4c>
ffffffffc0201b84:	b7dd                	j	ffffffffc0201b6a <slob_free+0xba>
		b->units += cur->next->units;
ffffffffc0201b86:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201b88:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201b8a:	9eb1                	addw	a3,a3,a2
ffffffffc0201b8c:	c114                	sw	a3,0(a0)
	if (cur + cur->units == b)
ffffffffc0201b8e:	4310                	lw	a2,0(a4)
ffffffffc0201b90:	e51c                	sd	a5,8(a0)
ffffffffc0201b92:	00461693          	slli	a3,a2,0x4
ffffffffc0201b96:	96ba                	add	a3,a3,a4
ffffffffc0201b98:	f4d51ce3          	bne	a0,a3,ffffffffc0201af0 <slob_free+0x40>
ffffffffc0201b9c:	bfc9                	j	ffffffffc0201b6e <slob_free+0xbe>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b9e:	f8f56ee3          	bltu	a0,a5,ffffffffc0201b3a <slob_free+0x8a>
ffffffffc0201ba2:	b771                	j	ffffffffc0201b2e <slob_free+0x7e>
}
ffffffffc0201ba4:	60e2                	ld	ra,24(sp)
ffffffffc0201ba6:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201ba8:	d57fe06f          	j	ffffffffc02008fe <intr_enable>
		b->units += cur->next->units;
ffffffffc0201bac:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201bae:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201bb0:	9eb1                	addw	a3,a3,a2
ffffffffc0201bb2:	c114                	sw	a3,0(a0)
		b->next = cur->next->next;
ffffffffc0201bb4:	bf59                	j	ffffffffc0201b4a <slob_free+0x9a>
		cur->units += b->units;
ffffffffc0201bb6:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201bb8:	853e                	mv	a0,a5
		cur->units += b->units;
ffffffffc0201bba:	00c687bb          	addw	a5,a3,a2
ffffffffc0201bbe:	c31c                	sw	a5,0(a4)
		cur->next = b->next;
ffffffffc0201bc0:	bf61                	j	ffffffffc0201b58 <slob_free+0xa8>

ffffffffc0201bc2 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201bc2:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201bc4:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201bc6:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201bca:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201bcc:	32a000ef          	jal	ffffffffc0201ef6 <alloc_pages>
	if (!page)
ffffffffc0201bd0:	c91d                	beqz	a0,ffffffffc0201c06 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201bd2:	000a4697          	auipc	a3,0xa4
ffffffffc0201bd6:	2c66b683          	ld	a3,710(a3) # ffffffffc02a5e98 <pages>
ffffffffc0201bda:	00006797          	auipc	a5,0x6
ffffffffc0201bde:	13e7b783          	ld	a5,318(a5) # ffffffffc0207d18 <nbase>
    return KADDR(page2pa(page));
ffffffffc0201be2:	000a4717          	auipc	a4,0xa4
ffffffffc0201be6:	2ae73703          	ld	a4,686(a4) # ffffffffc02a5e90 <npage>
    return page - pages + nbase;
ffffffffc0201bea:	8d15                	sub	a0,a0,a3
ffffffffc0201bec:	8519                	srai	a0,a0,0x6
ffffffffc0201bee:	953e                	add	a0,a0,a5
    return KADDR(page2pa(page));
ffffffffc0201bf0:	00c51793          	slli	a5,a0,0xc
ffffffffc0201bf4:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201bf6:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201bf8:	00e7fa63          	bgeu	a5,a4,ffffffffc0201c0c <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201bfc:	000a4797          	auipc	a5,0xa4
ffffffffc0201c00:	28c7b783          	ld	a5,652(a5) # ffffffffc02a5e88 <va_pa_offset>
ffffffffc0201c04:	953e                	add	a0,a0,a5
}
ffffffffc0201c06:	60a2                	ld	ra,8(sp)
ffffffffc0201c08:	0141                	addi	sp,sp,16
ffffffffc0201c0a:	8082                	ret
ffffffffc0201c0c:	86aa                	mv	a3,a0
ffffffffc0201c0e:	00005617          	auipc	a2,0x5
ffffffffc0201c12:	c1a60613          	addi	a2,a2,-998 # ffffffffc0206828 <etext+0xd6e>
ffffffffc0201c16:	07100593          	li	a1,113
ffffffffc0201c1a:	00005517          	auipc	a0,0x5
ffffffffc0201c1e:	c3650513          	addi	a0,a0,-970 # ffffffffc0206850 <etext+0xd96>
ffffffffc0201c22:	825fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201c26 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201c26:	7179                	addi	sp,sp,-48
ffffffffc0201c28:	f406                	sd	ra,40(sp)
ffffffffc0201c2a:	f022                	sd	s0,32(sp)
ffffffffc0201c2c:	ec26                	sd	s1,24(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201c2e:	01050713          	addi	a4,a0,16
ffffffffc0201c32:	6785                	lui	a5,0x1
ffffffffc0201c34:	0af77e63          	bgeu	a4,a5,ffffffffc0201cf0 <slob_alloc.constprop.0+0xca>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201c38:	00f50413          	addi	s0,a0,15
ffffffffc0201c3c:	8011                	srli	s0,s0,0x4
ffffffffc0201c3e:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c40:	100025f3          	csrr	a1,sstatus
ffffffffc0201c44:	8989                	andi	a1,a1,2
ffffffffc0201c46:	edd1                	bnez	a1,ffffffffc0201ce2 <slob_alloc.constprop.0+0xbc>
	prev = slobfree;
ffffffffc0201c48:	000a0497          	auipc	s1,0xa0
ffffffffc0201c4c:	db848493          	addi	s1,s1,-584 # ffffffffc02a1a00 <slobfree>
ffffffffc0201c50:	6090                	ld	a2,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c52:	6618                	ld	a4,8(a2)
		if (cur->units >= units + delta)
ffffffffc0201c54:	4314                	lw	a3,0(a4)
ffffffffc0201c56:	0886da63          	bge	a3,s0,ffffffffc0201cea <slob_alloc.constprop.0+0xc4>
		if (cur == slobfree)
ffffffffc0201c5a:	00e60a63          	beq	a2,a4,ffffffffc0201c6e <slob_alloc.constprop.0+0x48>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c5e:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201c60:	4394                	lw	a3,0(a5)
ffffffffc0201c62:	0286d863          	bge	a3,s0,ffffffffc0201c92 <slob_alloc.constprop.0+0x6c>
		if (cur == slobfree)
ffffffffc0201c66:	6090                	ld	a2,0(s1)
ffffffffc0201c68:	873e                	mv	a4,a5
ffffffffc0201c6a:	fee61ae3          	bne	a2,a4,ffffffffc0201c5e <slob_alloc.constprop.0+0x38>
    if (flag)
ffffffffc0201c6e:	e9b1                	bnez	a1,ffffffffc0201cc2 <slob_alloc.constprop.0+0x9c>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201c70:	4501                	li	a0,0
ffffffffc0201c72:	f51ff0ef          	jal	ffffffffc0201bc2 <__slob_get_free_pages.constprop.0>
ffffffffc0201c76:	87aa                	mv	a5,a0
			if (!cur)
ffffffffc0201c78:	c915                	beqz	a0,ffffffffc0201cac <slob_alloc.constprop.0+0x86>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201c7a:	6585                	lui	a1,0x1
ffffffffc0201c7c:	e35ff0ef          	jal	ffffffffc0201ab0 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c80:	100025f3          	csrr	a1,sstatus
ffffffffc0201c84:	8989                	andi	a1,a1,2
ffffffffc0201c86:	e98d                	bnez	a1,ffffffffc0201cb8 <slob_alloc.constprop.0+0x92>
			cur = slobfree;
ffffffffc0201c88:	6098                	ld	a4,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c8a:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201c8c:	4394                	lw	a3,0(a5)
ffffffffc0201c8e:	fc86cce3          	blt	a3,s0,ffffffffc0201c66 <slob_alloc.constprop.0+0x40>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201c92:	04d40563          	beq	s0,a3,ffffffffc0201cdc <slob_alloc.constprop.0+0xb6>
				prev->next = cur + units;
ffffffffc0201c96:	00441613          	slli	a2,s0,0x4
ffffffffc0201c9a:	963e                	add	a2,a2,a5
ffffffffc0201c9c:	e710                	sd	a2,8(a4)
				prev->next->next = cur->next;
ffffffffc0201c9e:	6788                	ld	a0,8(a5)
				prev->next->units = cur->units - units;
ffffffffc0201ca0:	9e81                	subw	a3,a3,s0
ffffffffc0201ca2:	c214                	sw	a3,0(a2)
				prev->next->next = cur->next;
ffffffffc0201ca4:	e608                	sd	a0,8(a2)
				cur->units = units;
ffffffffc0201ca6:	c380                	sw	s0,0(a5)
			slobfree = prev;
ffffffffc0201ca8:	e098                	sd	a4,0(s1)
    if (flag)
ffffffffc0201caa:	ed99                	bnez	a1,ffffffffc0201cc8 <slob_alloc.constprop.0+0xa2>
}
ffffffffc0201cac:	70a2                	ld	ra,40(sp)
ffffffffc0201cae:	7402                	ld	s0,32(sp)
ffffffffc0201cb0:	64e2                	ld	s1,24(sp)
ffffffffc0201cb2:	853e                	mv	a0,a5
ffffffffc0201cb4:	6145                	addi	sp,sp,48
ffffffffc0201cb6:	8082                	ret
        intr_disable();
ffffffffc0201cb8:	c4dfe0ef          	jal	ffffffffc0200904 <intr_disable>
			cur = slobfree;
ffffffffc0201cbc:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0201cbe:	4585                	li	a1,1
ffffffffc0201cc0:	b7e9                	j	ffffffffc0201c8a <slob_alloc.constprop.0+0x64>
        intr_enable();
ffffffffc0201cc2:	c3dfe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201cc6:	b76d                	j	ffffffffc0201c70 <slob_alloc.constprop.0+0x4a>
ffffffffc0201cc8:	e43e                	sd	a5,8(sp)
ffffffffc0201cca:	c35fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201cce:	67a2                	ld	a5,8(sp)
}
ffffffffc0201cd0:	70a2                	ld	ra,40(sp)
ffffffffc0201cd2:	7402                	ld	s0,32(sp)
ffffffffc0201cd4:	64e2                	ld	s1,24(sp)
ffffffffc0201cd6:	853e                	mv	a0,a5
ffffffffc0201cd8:	6145                	addi	sp,sp,48
ffffffffc0201cda:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201cdc:	6794                	ld	a3,8(a5)
ffffffffc0201cde:	e714                	sd	a3,8(a4)
ffffffffc0201ce0:	b7e1                	j	ffffffffc0201ca8 <slob_alloc.constprop.0+0x82>
        intr_disable();
ffffffffc0201ce2:	c23fe0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0201ce6:	4585                	li	a1,1
ffffffffc0201ce8:	b785                	j	ffffffffc0201c48 <slob_alloc.constprop.0+0x22>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201cea:	87ba                	mv	a5,a4
	prev = slobfree;
ffffffffc0201cec:	8732                	mv	a4,a2
ffffffffc0201cee:	b755                	j	ffffffffc0201c92 <slob_alloc.constprop.0+0x6c>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201cf0:	00005697          	auipc	a3,0x5
ffffffffc0201cf4:	b7068693          	addi	a3,a3,-1168 # ffffffffc0206860 <etext+0xda6>
ffffffffc0201cf8:	00004617          	auipc	a2,0x4
ffffffffc0201cfc:	57060613          	addi	a2,a2,1392 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0201d00:	06300593          	li	a1,99
ffffffffc0201d04:	00005517          	auipc	a0,0x5
ffffffffc0201d08:	b7c50513          	addi	a0,a0,-1156 # ffffffffc0206880 <etext+0xdc6>
ffffffffc0201d0c:	f3afe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201d10 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201d10:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201d12:	00005517          	auipc	a0,0x5
ffffffffc0201d16:	b8650513          	addi	a0,a0,-1146 # ffffffffc0206898 <etext+0xdde>
{
ffffffffc0201d1a:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201d1c:	c78fe0ef          	jal	ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201d20:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201d22:	00005517          	auipc	a0,0x5
ffffffffc0201d26:	b8e50513          	addi	a0,a0,-1138 # ffffffffc02068b0 <etext+0xdf6>
}
ffffffffc0201d2a:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201d2c:	c68fe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201d30 <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201d30:	4501                	li	a0,0
ffffffffc0201d32:	8082                	ret

ffffffffc0201d34 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201d34:	1101                	addi	sp,sp,-32
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d36:	6685                	lui	a3,0x1
{
ffffffffc0201d38:	ec06                	sd	ra,24(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d3a:	16bd                	addi	a3,a3,-17 # fef <_binary_obj___user_softint_out_size-0x7c19>
ffffffffc0201d3c:	04a6f963          	bgeu	a3,a0,ffffffffc0201d8e <kmalloc+0x5a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201d40:	e42a                	sd	a0,8(sp)
ffffffffc0201d42:	4561                	li	a0,24
ffffffffc0201d44:	e822                	sd	s0,16(sp)
ffffffffc0201d46:	ee1ff0ef          	jal	ffffffffc0201c26 <slob_alloc.constprop.0>
ffffffffc0201d4a:	842a                	mv	s0,a0
	if (!bb)
ffffffffc0201d4c:	c541                	beqz	a0,ffffffffc0201dd4 <kmalloc+0xa0>
	bb->order = find_order(size);
ffffffffc0201d4e:	47a2                	lw	a5,8(sp)
	for (; size > 4096; size >>= 1)
ffffffffc0201d50:	6705                	lui	a4,0x1
	int order = 0;
ffffffffc0201d52:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201d54:	00f75763          	bge	a4,a5,ffffffffc0201d62 <kmalloc+0x2e>
ffffffffc0201d58:	4017d79b          	sraiw	a5,a5,0x1
		order++;
ffffffffc0201d5c:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201d5e:	fef74de3          	blt	a4,a5,ffffffffc0201d58 <kmalloc+0x24>
	bb->order = find_order(size);
ffffffffc0201d62:	c008                	sw	a0,0(s0)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201d64:	e5fff0ef          	jal	ffffffffc0201bc2 <__slob_get_free_pages.constprop.0>
ffffffffc0201d68:	e408                	sd	a0,8(s0)
	if (bb->pages)
ffffffffc0201d6a:	cd31                	beqz	a0,ffffffffc0201dc6 <kmalloc+0x92>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d6c:	100027f3          	csrr	a5,sstatus
ffffffffc0201d70:	8b89                	andi	a5,a5,2
ffffffffc0201d72:	eb85                	bnez	a5,ffffffffc0201da2 <kmalloc+0x6e>
		bb->next = bigblocks;
ffffffffc0201d74:	000a4797          	auipc	a5,0xa4
ffffffffc0201d78:	0f47b783          	ld	a5,244(a5) # ffffffffc02a5e68 <bigblocks>
		bigblocks = bb;
ffffffffc0201d7c:	000a4717          	auipc	a4,0xa4
ffffffffc0201d80:	0e873623          	sd	s0,236(a4) # ffffffffc02a5e68 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201d84:	e81c                	sd	a5,16(s0)
    if (flag)
ffffffffc0201d86:	6442                	ld	s0,16(sp)
	return __kmalloc(size, 0);
}
ffffffffc0201d88:	60e2                	ld	ra,24(sp)
ffffffffc0201d8a:	6105                	addi	sp,sp,32
ffffffffc0201d8c:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201d8e:	0541                	addi	a0,a0,16
ffffffffc0201d90:	e97ff0ef          	jal	ffffffffc0201c26 <slob_alloc.constprop.0>
ffffffffc0201d94:	87aa                	mv	a5,a0
		return m ? (void *)(m + 1) : 0;
ffffffffc0201d96:	0541                	addi	a0,a0,16
ffffffffc0201d98:	fbe5                	bnez	a5,ffffffffc0201d88 <kmalloc+0x54>
		return 0;
ffffffffc0201d9a:	4501                	li	a0,0
}
ffffffffc0201d9c:	60e2                	ld	ra,24(sp)
ffffffffc0201d9e:	6105                	addi	sp,sp,32
ffffffffc0201da0:	8082                	ret
        intr_disable();
ffffffffc0201da2:	b63fe0ef          	jal	ffffffffc0200904 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201da6:	000a4797          	auipc	a5,0xa4
ffffffffc0201daa:	0c27b783          	ld	a5,194(a5) # ffffffffc02a5e68 <bigblocks>
		bigblocks = bb;
ffffffffc0201dae:	000a4717          	auipc	a4,0xa4
ffffffffc0201db2:	0a873d23          	sd	s0,186(a4) # ffffffffc02a5e68 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201db6:	e81c                	sd	a5,16(s0)
        intr_enable();
ffffffffc0201db8:	b47fe0ef          	jal	ffffffffc02008fe <intr_enable>
		return bb->pages;
ffffffffc0201dbc:	6408                	ld	a0,8(s0)
}
ffffffffc0201dbe:	60e2                	ld	ra,24(sp)
		return bb->pages;
ffffffffc0201dc0:	6442                	ld	s0,16(sp)
}
ffffffffc0201dc2:	6105                	addi	sp,sp,32
ffffffffc0201dc4:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201dc6:	8522                	mv	a0,s0
ffffffffc0201dc8:	45e1                	li	a1,24
ffffffffc0201dca:	ce7ff0ef          	jal	ffffffffc0201ab0 <slob_free>
		return 0;
ffffffffc0201dce:	4501                	li	a0,0
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201dd0:	6442                	ld	s0,16(sp)
ffffffffc0201dd2:	b7e9                	j	ffffffffc0201d9c <kmalloc+0x68>
ffffffffc0201dd4:	6442                	ld	s0,16(sp)
		return 0;
ffffffffc0201dd6:	4501                	li	a0,0
ffffffffc0201dd8:	b7d1                	j	ffffffffc0201d9c <kmalloc+0x68>

ffffffffc0201dda <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201dda:	c571                	beqz	a0,ffffffffc0201ea6 <kfree+0xcc>
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201ddc:	03451793          	slli	a5,a0,0x34
ffffffffc0201de0:	e3e1                	bnez	a5,ffffffffc0201ea0 <kfree+0xc6>
{
ffffffffc0201de2:	1101                	addi	sp,sp,-32
ffffffffc0201de4:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201de6:	100027f3          	csrr	a5,sstatus
ffffffffc0201dea:	8b89                	andi	a5,a5,2
ffffffffc0201dec:	e7c1                	bnez	a5,ffffffffc0201e74 <kfree+0x9a>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201dee:	000a4797          	auipc	a5,0xa4
ffffffffc0201df2:	07a7b783          	ld	a5,122(a5) # ffffffffc02a5e68 <bigblocks>
    return 0;
ffffffffc0201df6:	4581                	li	a1,0
ffffffffc0201df8:	cbad                	beqz	a5,ffffffffc0201e6a <kfree+0x90>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201dfa:	000a4617          	auipc	a2,0xa4
ffffffffc0201dfe:	06e60613          	addi	a2,a2,110 # ffffffffc02a5e68 <bigblocks>
ffffffffc0201e02:	a021                	j	ffffffffc0201e0a <kfree+0x30>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e04:	01070613          	addi	a2,a4,16
ffffffffc0201e08:	c3a5                	beqz	a5,ffffffffc0201e68 <kfree+0x8e>
		{
			if (bb->pages == block)
ffffffffc0201e0a:	6794                	ld	a3,8(a5)
ffffffffc0201e0c:	873e                	mv	a4,a5
			{
				*last = bb->next;
ffffffffc0201e0e:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201e10:	fea69ae3          	bne	a3,a0,ffffffffc0201e04 <kfree+0x2a>
				*last = bb->next;
ffffffffc0201e14:	e21c                	sd	a5,0(a2)
    if (flag)
ffffffffc0201e16:	edb5                	bnez	a1,ffffffffc0201e92 <kfree+0xb8>
    return pa2page(PADDR(kva));
ffffffffc0201e18:	c02007b7          	lui	a5,0xc0200
ffffffffc0201e1c:	0af56263          	bltu	a0,a5,ffffffffc0201ec0 <kfree+0xe6>
ffffffffc0201e20:	000a4797          	auipc	a5,0xa4
ffffffffc0201e24:	0687b783          	ld	a5,104(a5) # ffffffffc02a5e88 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0201e28:	000a4697          	auipc	a3,0xa4
ffffffffc0201e2c:	0686b683          	ld	a3,104(a3) # ffffffffc02a5e90 <npage>
    return pa2page(PADDR(kva));
ffffffffc0201e30:	8d1d                	sub	a0,a0,a5
    if (PPN(pa) >= npage)
ffffffffc0201e32:	00c55793          	srli	a5,a0,0xc
ffffffffc0201e36:	06d7f963          	bgeu	a5,a3,ffffffffc0201ea8 <kfree+0xce>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e3a:	00006617          	auipc	a2,0x6
ffffffffc0201e3e:	ede63603          	ld	a2,-290(a2) # ffffffffc0207d18 <nbase>
ffffffffc0201e42:	000a4517          	auipc	a0,0xa4
ffffffffc0201e46:	05653503          	ld	a0,86(a0) # ffffffffc02a5e98 <pages>
	free_pages(kva2page((void *)kva), 1 << order);
ffffffffc0201e4a:	4314                	lw	a3,0(a4)
ffffffffc0201e4c:	8f91                	sub	a5,a5,a2
ffffffffc0201e4e:	079a                	slli	a5,a5,0x6
ffffffffc0201e50:	4585                	li	a1,1
ffffffffc0201e52:	953e                	add	a0,a0,a5
ffffffffc0201e54:	00d595bb          	sllw	a1,a1,a3
ffffffffc0201e58:	e03a                	sd	a4,0(sp)
ffffffffc0201e5a:	0d6000ef          	jal	ffffffffc0201f30 <free_pages>
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e5e:	6502                	ld	a0,0(sp)
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201e60:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e62:	45e1                	li	a1,24
}
ffffffffc0201e64:	6105                	addi	sp,sp,32
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e66:	b1a9                	j	ffffffffc0201ab0 <slob_free>
ffffffffc0201e68:	e185                	bnez	a1,ffffffffc0201e88 <kfree+0xae>
}
ffffffffc0201e6a:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e6c:	1541                	addi	a0,a0,-16
ffffffffc0201e6e:	4581                	li	a1,0
}
ffffffffc0201e70:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e72:	b93d                	j	ffffffffc0201ab0 <slob_free>
        intr_disable();
ffffffffc0201e74:	e02a                	sd	a0,0(sp)
ffffffffc0201e76:	a8ffe0ef          	jal	ffffffffc0200904 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e7a:	000a4797          	auipc	a5,0xa4
ffffffffc0201e7e:	fee7b783          	ld	a5,-18(a5) # ffffffffc02a5e68 <bigblocks>
ffffffffc0201e82:	6502                	ld	a0,0(sp)
        return 1;
ffffffffc0201e84:	4585                	li	a1,1
ffffffffc0201e86:	fbb5                	bnez	a5,ffffffffc0201dfa <kfree+0x20>
ffffffffc0201e88:	e02a                	sd	a0,0(sp)
        intr_enable();
ffffffffc0201e8a:	a75fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201e8e:	6502                	ld	a0,0(sp)
ffffffffc0201e90:	bfe9                	j	ffffffffc0201e6a <kfree+0x90>
ffffffffc0201e92:	e42a                	sd	a0,8(sp)
ffffffffc0201e94:	e03a                	sd	a4,0(sp)
ffffffffc0201e96:	a69fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201e9a:	6522                	ld	a0,8(sp)
ffffffffc0201e9c:	6702                	ld	a4,0(sp)
ffffffffc0201e9e:	bfad                	j	ffffffffc0201e18 <kfree+0x3e>
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201ea0:	1541                	addi	a0,a0,-16
ffffffffc0201ea2:	4581                	li	a1,0
ffffffffc0201ea4:	b131                	j	ffffffffc0201ab0 <slob_free>
ffffffffc0201ea6:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201ea8:	00005617          	auipc	a2,0x5
ffffffffc0201eac:	a5060613          	addi	a2,a2,-1456 # ffffffffc02068f8 <etext+0xe3e>
ffffffffc0201eb0:	06900593          	li	a1,105
ffffffffc0201eb4:	00005517          	auipc	a0,0x5
ffffffffc0201eb8:	99c50513          	addi	a0,a0,-1636 # ffffffffc0206850 <etext+0xd96>
ffffffffc0201ebc:	d8afe0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201ec0:	86aa                	mv	a3,a0
ffffffffc0201ec2:	00005617          	auipc	a2,0x5
ffffffffc0201ec6:	a0e60613          	addi	a2,a2,-1522 # ffffffffc02068d0 <etext+0xe16>
ffffffffc0201eca:	07700593          	li	a1,119
ffffffffc0201ece:	00005517          	auipc	a0,0x5
ffffffffc0201ed2:	98250513          	addi	a0,a0,-1662 # ffffffffc0206850 <etext+0xd96>
ffffffffc0201ed6:	d70fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201eda <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201eda:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201edc:	00005617          	auipc	a2,0x5
ffffffffc0201ee0:	a1c60613          	addi	a2,a2,-1508 # ffffffffc02068f8 <etext+0xe3e>
ffffffffc0201ee4:	06900593          	li	a1,105
ffffffffc0201ee8:	00005517          	auipc	a0,0x5
ffffffffc0201eec:	96850513          	addi	a0,a0,-1688 # ffffffffc0206850 <etext+0xd96>
pa2page(uintptr_t pa)
ffffffffc0201ef0:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201ef2:	d54fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201ef6 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ef6:	100027f3          	csrr	a5,sstatus
ffffffffc0201efa:	8b89                	andi	a5,a5,2
ffffffffc0201efc:	e799                	bnez	a5,ffffffffc0201f0a <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201efe:	000a4797          	auipc	a5,0xa4
ffffffffc0201f02:	f727b783          	ld	a5,-142(a5) # ffffffffc02a5e70 <pmm_manager>
ffffffffc0201f06:	6f9c                	ld	a5,24(a5)
ffffffffc0201f08:	8782                	jr	a5
{
ffffffffc0201f0a:	1101                	addi	sp,sp,-32
ffffffffc0201f0c:	ec06                	sd	ra,24(sp)
ffffffffc0201f0e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201f10:	9f5fe0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f14:	000a4797          	auipc	a5,0xa4
ffffffffc0201f18:	f5c7b783          	ld	a5,-164(a5) # ffffffffc02a5e70 <pmm_manager>
ffffffffc0201f1c:	6522                	ld	a0,8(sp)
ffffffffc0201f1e:	6f9c                	ld	a5,24(a5)
ffffffffc0201f20:	9782                	jalr	a5
ffffffffc0201f22:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201f24:	9dbfe0ef          	jal	ffffffffc02008fe <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201f28:	60e2                	ld	ra,24(sp)
ffffffffc0201f2a:	6522                	ld	a0,8(sp)
ffffffffc0201f2c:	6105                	addi	sp,sp,32
ffffffffc0201f2e:	8082                	ret

ffffffffc0201f30 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f30:	100027f3          	csrr	a5,sstatus
ffffffffc0201f34:	8b89                	andi	a5,a5,2
ffffffffc0201f36:	e799                	bnez	a5,ffffffffc0201f44 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201f38:	000a4797          	auipc	a5,0xa4
ffffffffc0201f3c:	f387b783          	ld	a5,-200(a5) # ffffffffc02a5e70 <pmm_manager>
ffffffffc0201f40:	739c                	ld	a5,32(a5)
ffffffffc0201f42:	8782                	jr	a5
{
ffffffffc0201f44:	1101                	addi	sp,sp,-32
ffffffffc0201f46:	ec06                	sd	ra,24(sp)
ffffffffc0201f48:	e42e                	sd	a1,8(sp)
ffffffffc0201f4a:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0201f4c:	9b9fe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201f50:	000a4797          	auipc	a5,0xa4
ffffffffc0201f54:	f207b783          	ld	a5,-224(a5) # ffffffffc02a5e70 <pmm_manager>
ffffffffc0201f58:	65a2                	ld	a1,8(sp)
ffffffffc0201f5a:	6502                	ld	a0,0(sp)
ffffffffc0201f5c:	739c                	ld	a5,32(a5)
ffffffffc0201f5e:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201f60:	60e2                	ld	ra,24(sp)
ffffffffc0201f62:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201f64:	99bfe06f          	j	ffffffffc02008fe <intr_enable>

ffffffffc0201f68 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f68:	100027f3          	csrr	a5,sstatus
ffffffffc0201f6c:	8b89                	andi	a5,a5,2
ffffffffc0201f6e:	e799                	bnez	a5,ffffffffc0201f7c <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f70:	000a4797          	auipc	a5,0xa4
ffffffffc0201f74:	f007b783          	ld	a5,-256(a5) # ffffffffc02a5e70 <pmm_manager>
ffffffffc0201f78:	779c                	ld	a5,40(a5)
ffffffffc0201f7a:	8782                	jr	a5
{
ffffffffc0201f7c:	1101                	addi	sp,sp,-32
ffffffffc0201f7e:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201f80:	985fe0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f84:	000a4797          	auipc	a5,0xa4
ffffffffc0201f88:	eec7b783          	ld	a5,-276(a5) # ffffffffc02a5e70 <pmm_manager>
ffffffffc0201f8c:	779c                	ld	a5,40(a5)
ffffffffc0201f8e:	9782                	jalr	a5
ffffffffc0201f90:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201f92:	96dfe0ef          	jal	ffffffffc02008fe <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201f96:	60e2                	ld	ra,24(sp)
ffffffffc0201f98:	6522                	ld	a0,8(sp)
ffffffffc0201f9a:	6105                	addi	sp,sp,32
ffffffffc0201f9c:	8082                	ret

ffffffffc0201f9e <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f9e:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201fa2:	1ff7f793          	andi	a5,a5,511
ffffffffc0201fa6:	078e                	slli	a5,a5,0x3
ffffffffc0201fa8:	00f50733          	add	a4,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201fac:	6314                	ld	a3,0(a4)
{
ffffffffc0201fae:	7139                	addi	sp,sp,-64
ffffffffc0201fb0:	f822                	sd	s0,48(sp)
ffffffffc0201fb2:	f426                	sd	s1,40(sp)
ffffffffc0201fb4:	fc06                	sd	ra,56(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201fb6:	0016f793          	andi	a5,a3,1
{
ffffffffc0201fba:	842e                	mv	s0,a1
ffffffffc0201fbc:	8832                	mv	a6,a2
ffffffffc0201fbe:	000a4497          	auipc	s1,0xa4
ffffffffc0201fc2:	ed248493          	addi	s1,s1,-302 # ffffffffc02a5e90 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201fc6:	ebd1                	bnez	a5,ffffffffc020205a <get_pte+0xbc>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201fc8:	16060d63          	beqz	a2,ffffffffc0202142 <get_pte+0x1a4>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201fcc:	100027f3          	csrr	a5,sstatus
ffffffffc0201fd0:	8b89                	andi	a5,a5,2
ffffffffc0201fd2:	16079e63          	bnez	a5,ffffffffc020214e <get_pte+0x1b0>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201fd6:	000a4797          	auipc	a5,0xa4
ffffffffc0201fda:	e9a7b783          	ld	a5,-358(a5) # ffffffffc02a5e70 <pmm_manager>
ffffffffc0201fde:	4505                	li	a0,1
ffffffffc0201fe0:	e43a                	sd	a4,8(sp)
ffffffffc0201fe2:	6f9c                	ld	a5,24(a5)
ffffffffc0201fe4:	e832                	sd	a2,16(sp)
ffffffffc0201fe6:	9782                	jalr	a5
ffffffffc0201fe8:	6722                	ld	a4,8(sp)
ffffffffc0201fea:	6842                	ld	a6,16(sp)
ffffffffc0201fec:	87aa                	mv	a5,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201fee:	14078a63          	beqz	a5,ffffffffc0202142 <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201ff2:	000a4517          	auipc	a0,0xa4
ffffffffc0201ff6:	ea653503          	ld	a0,-346(a0) # ffffffffc02a5e98 <pages>
ffffffffc0201ffa:	000808b7          	lui	a7,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201ffe:	000a4497          	auipc	s1,0xa4
ffffffffc0202002:	e9248493          	addi	s1,s1,-366 # ffffffffc02a5e90 <npage>
ffffffffc0202006:	40a78533          	sub	a0,a5,a0
ffffffffc020200a:	8519                	srai	a0,a0,0x6
ffffffffc020200c:	9546                	add	a0,a0,a7
ffffffffc020200e:	6090                	ld	a2,0(s1)
ffffffffc0202010:	00c51693          	slli	a3,a0,0xc
    page->ref = val;
ffffffffc0202014:	4585                	li	a1,1
ffffffffc0202016:	82b1                	srli	a3,a3,0xc
ffffffffc0202018:	c38c                	sw	a1,0(a5)
    return page2ppn(page) << PGSHIFT;
ffffffffc020201a:	0532                	slli	a0,a0,0xc
ffffffffc020201c:	1ac6f763          	bgeu	a3,a2,ffffffffc02021ca <get_pte+0x22c>
ffffffffc0202020:	000a4697          	auipc	a3,0xa4
ffffffffc0202024:	e686b683          	ld	a3,-408(a3) # ffffffffc02a5e88 <va_pa_offset>
ffffffffc0202028:	6605                	lui	a2,0x1
ffffffffc020202a:	4581                	li	a1,0
ffffffffc020202c:	9536                	add	a0,a0,a3
ffffffffc020202e:	ec42                	sd	a6,24(sp)
ffffffffc0202030:	e83e                	sd	a5,16(sp)
ffffffffc0202032:	e43a                	sd	a4,8(sp)
ffffffffc0202034:	25d030ef          	jal	ffffffffc0205a90 <memset>
    return page - pages + nbase;
ffffffffc0202038:	000a4697          	auipc	a3,0xa4
ffffffffc020203c:	e606b683          	ld	a3,-416(a3) # ffffffffc02a5e98 <pages>
ffffffffc0202040:	67c2                	ld	a5,16(sp)
ffffffffc0202042:	000808b7          	lui	a7,0x80
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202046:	6722                	ld	a4,8(sp)
ffffffffc0202048:	40d786b3          	sub	a3,a5,a3
ffffffffc020204c:	8699                	srai	a3,a3,0x6
ffffffffc020204e:	96c6                	add	a3,a3,a7
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202050:	06aa                	slli	a3,a3,0xa
ffffffffc0202052:	6862                	ld	a6,24(sp)
ffffffffc0202054:	0116e693          	ori	a3,a3,17
ffffffffc0202058:	e314                	sd	a3,0(a4)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc020205a:	c006f693          	andi	a3,a3,-1024
ffffffffc020205e:	6098                	ld	a4,0(s1)
ffffffffc0202060:	068a                	slli	a3,a3,0x2
ffffffffc0202062:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202066:	14e7f663          	bgeu	a5,a4,ffffffffc02021b2 <get_pte+0x214>
ffffffffc020206a:	000a4897          	auipc	a7,0xa4
ffffffffc020206e:	e1e88893          	addi	a7,a7,-482 # ffffffffc02a5e88 <va_pa_offset>
ffffffffc0202072:	0008b603          	ld	a2,0(a7)
ffffffffc0202076:	01545793          	srli	a5,s0,0x15
ffffffffc020207a:	1ff7f793          	andi	a5,a5,511
ffffffffc020207e:	96b2                	add	a3,a3,a2
ffffffffc0202080:	078e                	slli	a5,a5,0x3
ffffffffc0202082:	97b6                	add	a5,a5,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0202084:	6394                	ld	a3,0(a5)
ffffffffc0202086:	0016f613          	andi	a2,a3,1
ffffffffc020208a:	e659                	bnez	a2,ffffffffc0202118 <get_pte+0x17a>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc020208c:	0a080b63          	beqz	a6,ffffffffc0202142 <get_pte+0x1a4>
ffffffffc0202090:	10002773          	csrr	a4,sstatus
ffffffffc0202094:	8b09                	andi	a4,a4,2
ffffffffc0202096:	ef71                	bnez	a4,ffffffffc0202172 <get_pte+0x1d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202098:	000a4717          	auipc	a4,0xa4
ffffffffc020209c:	dd873703          	ld	a4,-552(a4) # ffffffffc02a5e70 <pmm_manager>
ffffffffc02020a0:	4505                	li	a0,1
ffffffffc02020a2:	e43e                	sd	a5,8(sp)
ffffffffc02020a4:	6f18                	ld	a4,24(a4)
ffffffffc02020a6:	9702                	jalr	a4
ffffffffc02020a8:	67a2                	ld	a5,8(sp)
ffffffffc02020aa:	872a                	mv	a4,a0
ffffffffc02020ac:	000a4897          	auipc	a7,0xa4
ffffffffc02020b0:	ddc88893          	addi	a7,a7,-548 # ffffffffc02a5e88 <va_pa_offset>
        if (!create || (page = alloc_page()) == NULL)
ffffffffc02020b4:	c759                	beqz	a4,ffffffffc0202142 <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc02020b6:	000a4697          	auipc	a3,0xa4
ffffffffc02020ba:	de26b683          	ld	a3,-542(a3) # ffffffffc02a5e98 <pages>
ffffffffc02020be:	00080837          	lui	a6,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02020c2:	608c                	ld	a1,0(s1)
ffffffffc02020c4:	40d706b3          	sub	a3,a4,a3
ffffffffc02020c8:	8699                	srai	a3,a3,0x6
ffffffffc02020ca:	96c2                	add	a3,a3,a6
ffffffffc02020cc:	00c69613          	slli	a2,a3,0xc
    page->ref = val;
ffffffffc02020d0:	4505                	li	a0,1
ffffffffc02020d2:	8231                	srli	a2,a2,0xc
ffffffffc02020d4:	c308                	sw	a0,0(a4)
    return page2ppn(page) << PGSHIFT;
ffffffffc02020d6:	06b2                	slli	a3,a3,0xc
ffffffffc02020d8:	10b67663          	bgeu	a2,a1,ffffffffc02021e4 <get_pte+0x246>
ffffffffc02020dc:	0008b503          	ld	a0,0(a7)
ffffffffc02020e0:	6605                	lui	a2,0x1
ffffffffc02020e2:	4581                	li	a1,0
ffffffffc02020e4:	9536                	add	a0,a0,a3
ffffffffc02020e6:	e83a                	sd	a4,16(sp)
ffffffffc02020e8:	e43e                	sd	a5,8(sp)
ffffffffc02020ea:	1a7030ef          	jal	ffffffffc0205a90 <memset>
    return page - pages + nbase;
ffffffffc02020ee:	000a4697          	auipc	a3,0xa4
ffffffffc02020f2:	daa6b683          	ld	a3,-598(a3) # ffffffffc02a5e98 <pages>
ffffffffc02020f6:	6742                	ld	a4,16(sp)
ffffffffc02020f8:	00080837          	lui	a6,0x80
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc02020fc:	67a2                	ld	a5,8(sp)
ffffffffc02020fe:	40d706b3          	sub	a3,a4,a3
ffffffffc0202102:	8699                	srai	a3,a3,0x6
ffffffffc0202104:	96c2                	add	a3,a3,a6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202106:	06aa                	slli	a3,a3,0xa
ffffffffc0202108:	0116e693          	ori	a3,a3,17
ffffffffc020210c:	e394                	sd	a3,0(a5)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020210e:	6098                	ld	a4,0(s1)
ffffffffc0202110:	000a4897          	auipc	a7,0xa4
ffffffffc0202114:	d7888893          	addi	a7,a7,-648 # ffffffffc02a5e88 <va_pa_offset>
ffffffffc0202118:	c006f693          	andi	a3,a3,-1024
ffffffffc020211c:	068a                	slli	a3,a3,0x2
ffffffffc020211e:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202122:	06e7fc63          	bgeu	a5,a4,ffffffffc020219a <get_pte+0x1fc>
ffffffffc0202126:	0008b783          	ld	a5,0(a7)
ffffffffc020212a:	8031                	srli	s0,s0,0xc
ffffffffc020212c:	1ff47413          	andi	s0,s0,511
ffffffffc0202130:	040e                	slli	s0,s0,0x3
ffffffffc0202132:	96be                	add	a3,a3,a5
}
ffffffffc0202134:	70e2                	ld	ra,56(sp)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202136:	00868533          	add	a0,a3,s0
}
ffffffffc020213a:	7442                	ld	s0,48(sp)
ffffffffc020213c:	74a2                	ld	s1,40(sp)
ffffffffc020213e:	6121                	addi	sp,sp,64
ffffffffc0202140:	8082                	ret
ffffffffc0202142:	70e2                	ld	ra,56(sp)
ffffffffc0202144:	7442                	ld	s0,48(sp)
ffffffffc0202146:	74a2                	ld	s1,40(sp)
            return NULL;
ffffffffc0202148:	4501                	li	a0,0
}
ffffffffc020214a:	6121                	addi	sp,sp,64
ffffffffc020214c:	8082                	ret
        intr_disable();
ffffffffc020214e:	e83a                	sd	a4,16(sp)
ffffffffc0202150:	ec32                	sd	a2,24(sp)
ffffffffc0202152:	fb2fe0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202156:	000a4797          	auipc	a5,0xa4
ffffffffc020215a:	d1a7b783          	ld	a5,-742(a5) # ffffffffc02a5e70 <pmm_manager>
ffffffffc020215e:	4505                	li	a0,1
ffffffffc0202160:	6f9c                	ld	a5,24(a5)
ffffffffc0202162:	9782                	jalr	a5
ffffffffc0202164:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0202166:	f98fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc020216a:	6862                	ld	a6,24(sp)
ffffffffc020216c:	6742                	ld	a4,16(sp)
ffffffffc020216e:	67a2                	ld	a5,8(sp)
ffffffffc0202170:	bdbd                	j	ffffffffc0201fee <get_pte+0x50>
        intr_disable();
ffffffffc0202172:	e83e                	sd	a5,16(sp)
ffffffffc0202174:	f90fe0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202178:	000a4717          	auipc	a4,0xa4
ffffffffc020217c:	cf873703          	ld	a4,-776(a4) # ffffffffc02a5e70 <pmm_manager>
ffffffffc0202180:	4505                	li	a0,1
ffffffffc0202182:	6f18                	ld	a4,24(a4)
ffffffffc0202184:	9702                	jalr	a4
ffffffffc0202186:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0202188:	f76fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc020218c:	6722                	ld	a4,8(sp)
ffffffffc020218e:	67c2                	ld	a5,16(sp)
ffffffffc0202190:	000a4897          	auipc	a7,0xa4
ffffffffc0202194:	cf888893          	addi	a7,a7,-776 # ffffffffc02a5e88 <va_pa_offset>
ffffffffc0202198:	bf31                	j	ffffffffc02020b4 <get_pte+0x116>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020219a:	00004617          	auipc	a2,0x4
ffffffffc020219e:	68e60613          	addi	a2,a2,1678 # ffffffffc0206828 <etext+0xd6e>
ffffffffc02021a2:	0fa00593          	li	a1,250
ffffffffc02021a6:	00004517          	auipc	a0,0x4
ffffffffc02021aa:	77250513          	addi	a0,a0,1906 # ffffffffc0206918 <etext+0xe5e>
ffffffffc02021ae:	a98fe0ef          	jal	ffffffffc0200446 <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02021b2:	00004617          	auipc	a2,0x4
ffffffffc02021b6:	67660613          	addi	a2,a2,1654 # ffffffffc0206828 <etext+0xd6e>
ffffffffc02021ba:	0ed00593          	li	a1,237
ffffffffc02021be:	00004517          	auipc	a0,0x4
ffffffffc02021c2:	75a50513          	addi	a0,a0,1882 # ffffffffc0206918 <etext+0xe5e>
ffffffffc02021c6:	a80fe0ef          	jal	ffffffffc0200446 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02021ca:	86aa                	mv	a3,a0
ffffffffc02021cc:	00004617          	auipc	a2,0x4
ffffffffc02021d0:	65c60613          	addi	a2,a2,1628 # ffffffffc0206828 <etext+0xd6e>
ffffffffc02021d4:	0e900593          	li	a1,233
ffffffffc02021d8:	00004517          	auipc	a0,0x4
ffffffffc02021dc:	74050513          	addi	a0,a0,1856 # ffffffffc0206918 <etext+0xe5e>
ffffffffc02021e0:	a66fe0ef          	jal	ffffffffc0200446 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02021e4:	00004617          	auipc	a2,0x4
ffffffffc02021e8:	64460613          	addi	a2,a2,1604 # ffffffffc0206828 <etext+0xd6e>
ffffffffc02021ec:	0f700593          	li	a1,247
ffffffffc02021f0:	00004517          	auipc	a0,0x4
ffffffffc02021f4:	72850513          	addi	a0,a0,1832 # ffffffffc0206918 <etext+0xe5e>
ffffffffc02021f8:	a4efe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02021fc <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc02021fc:	1141                	addi	sp,sp,-16
ffffffffc02021fe:	e022                	sd	s0,0(sp)
ffffffffc0202200:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202202:	4601                	li	a2,0
{
ffffffffc0202204:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202206:	d99ff0ef          	jal	ffffffffc0201f9e <get_pte>
    if (ptep_store != NULL)
ffffffffc020220a:	c011                	beqz	s0,ffffffffc020220e <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc020220c:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020220e:	c511                	beqz	a0,ffffffffc020221a <get_page+0x1e>
ffffffffc0202210:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0202212:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202214:	0017f713          	andi	a4,a5,1
ffffffffc0202218:	e709                	bnez	a4,ffffffffc0202222 <get_page+0x26>
}
ffffffffc020221a:	60a2                	ld	ra,8(sp)
ffffffffc020221c:	6402                	ld	s0,0(sp)
ffffffffc020221e:	0141                	addi	sp,sp,16
ffffffffc0202220:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0202222:	000a4717          	auipc	a4,0xa4
ffffffffc0202226:	c6e73703          	ld	a4,-914(a4) # ffffffffc02a5e90 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc020222a:	078a                	slli	a5,a5,0x2
ffffffffc020222c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020222e:	00e7ff63          	bgeu	a5,a4,ffffffffc020224c <get_page+0x50>
    return &pages[PPN(pa) - nbase];
ffffffffc0202232:	000a4517          	auipc	a0,0xa4
ffffffffc0202236:	c6653503          	ld	a0,-922(a0) # ffffffffc02a5e98 <pages>
ffffffffc020223a:	60a2                	ld	ra,8(sp)
ffffffffc020223c:	6402                	ld	s0,0(sp)
ffffffffc020223e:	079a                	slli	a5,a5,0x6
ffffffffc0202240:	fe000737          	lui	a4,0xfe000
ffffffffc0202244:	97ba                	add	a5,a5,a4
ffffffffc0202246:	953e                	add	a0,a0,a5
ffffffffc0202248:	0141                	addi	sp,sp,16
ffffffffc020224a:	8082                	ret
ffffffffc020224c:	c8fff0ef          	jal	ffffffffc0201eda <pa2page.part.0>

ffffffffc0202250 <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc0202250:	715d                	addi	sp,sp,-80
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202252:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202256:	e486                	sd	ra,72(sp)
ffffffffc0202258:	e0a2                	sd	s0,64(sp)
ffffffffc020225a:	fc26                	sd	s1,56(sp)
ffffffffc020225c:	f84a                	sd	s2,48(sp)
ffffffffc020225e:	f44e                	sd	s3,40(sp)
ffffffffc0202260:	f052                	sd	s4,32(sp)
ffffffffc0202262:	ec56                	sd	s5,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202264:	03479713          	slli	a4,a5,0x34
ffffffffc0202268:	ef61                	bnez	a4,ffffffffc0202340 <unmap_range+0xf0>
    assert(USER_ACCESS(start, end));
ffffffffc020226a:	00200a37          	lui	s4,0x200
ffffffffc020226e:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc0202272:	0145b733          	sltu	a4,a1,s4
ffffffffc0202276:	0017b793          	seqz	a5,a5
ffffffffc020227a:	8fd9                	or	a5,a5,a4
ffffffffc020227c:	842e                	mv	s0,a1
ffffffffc020227e:	84b2                	mv	s1,a2
ffffffffc0202280:	e3e5                	bnez	a5,ffffffffc0202360 <unmap_range+0x110>
ffffffffc0202282:	4785                	li	a5,1
ffffffffc0202284:	07fe                	slli	a5,a5,0x1f
ffffffffc0202286:	0785                	addi	a5,a5,1
ffffffffc0202288:	892a                	mv	s2,a0
ffffffffc020228a:	6985                	lui	s3,0x1
    do
    {
        pte_t *ptep = get_pte(pgdir, start, 0);
        if (ptep == NULL)
        {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020228c:	ffe00ab7          	lui	s5,0xffe00
    assert(USER_ACCESS(start, end));
ffffffffc0202290:	0cf67863          	bgeu	a2,a5,ffffffffc0202360 <unmap_range+0x110>
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc0202294:	4601                	li	a2,0
ffffffffc0202296:	85a2                	mv	a1,s0
ffffffffc0202298:	854a                	mv	a0,s2
ffffffffc020229a:	d05ff0ef          	jal	ffffffffc0201f9e <get_pte>
ffffffffc020229e:	87aa                	mv	a5,a0
        if (ptep == NULL)
ffffffffc02022a0:	cd31                	beqz	a0,ffffffffc02022fc <unmap_range+0xac>
            continue;
        }
        if (*ptep != 0)
ffffffffc02022a2:	6118                	ld	a4,0(a0)
ffffffffc02022a4:	ef11                	bnez	a4,ffffffffc02022c0 <unmap_range+0x70>
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02022a6:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc02022a8:	c019                	beqz	s0,ffffffffc02022ae <unmap_range+0x5e>
ffffffffc02022aa:	fe9465e3          	bltu	s0,s1,ffffffffc0202294 <unmap_range+0x44>
}
ffffffffc02022ae:	60a6                	ld	ra,72(sp)
ffffffffc02022b0:	6406                	ld	s0,64(sp)
ffffffffc02022b2:	74e2                	ld	s1,56(sp)
ffffffffc02022b4:	7942                	ld	s2,48(sp)
ffffffffc02022b6:	79a2                	ld	s3,40(sp)
ffffffffc02022b8:	7a02                	ld	s4,32(sp)
ffffffffc02022ba:	6ae2                	ld	s5,24(sp)
ffffffffc02022bc:	6161                	addi	sp,sp,80
ffffffffc02022be:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc02022c0:	00177693          	andi	a3,a4,1
ffffffffc02022c4:	d2ed                	beqz	a3,ffffffffc02022a6 <unmap_range+0x56>
    if (PPN(pa) >= npage)
ffffffffc02022c6:	000a4697          	auipc	a3,0xa4
ffffffffc02022ca:	bca6b683          	ld	a3,-1078(a3) # ffffffffc02a5e90 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02022ce:	070a                	slli	a4,a4,0x2
ffffffffc02022d0:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc02022d2:	0ad77763          	bgeu	a4,a3,ffffffffc0202380 <unmap_range+0x130>
    return &pages[PPN(pa) - nbase];
ffffffffc02022d6:	000a4517          	auipc	a0,0xa4
ffffffffc02022da:	bc253503          	ld	a0,-1086(a0) # ffffffffc02a5e98 <pages>
ffffffffc02022de:	071a                	slli	a4,a4,0x6
ffffffffc02022e0:	fe0006b7          	lui	a3,0xfe000
ffffffffc02022e4:	9736                	add	a4,a4,a3
ffffffffc02022e6:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc02022e8:	4118                	lw	a4,0(a0)
ffffffffc02022ea:	377d                	addiw	a4,a4,-1 # fffffffffdffffff <end+0x3dd5a137>
ffffffffc02022ec:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc02022ee:	cb19                	beqz	a4,ffffffffc0202304 <unmap_range+0xb4>
        *ptep = 0;
ffffffffc02022f0:	0007b023          	sd	zero,0(a5)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02022f4:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc02022f8:	944e                	add	s0,s0,s3
ffffffffc02022fa:	b77d                	j	ffffffffc02022a8 <unmap_range+0x58>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02022fc:	9452                	add	s0,s0,s4
ffffffffc02022fe:	01547433          	and	s0,s0,s5
            continue;
ffffffffc0202302:	b75d                	j	ffffffffc02022a8 <unmap_range+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202304:	10002773          	csrr	a4,sstatus
ffffffffc0202308:	8b09                	andi	a4,a4,2
ffffffffc020230a:	eb19                	bnez	a4,ffffffffc0202320 <unmap_range+0xd0>
        pmm_manager->free_pages(base, n);
ffffffffc020230c:	000a4717          	auipc	a4,0xa4
ffffffffc0202310:	b6473703          	ld	a4,-1180(a4) # ffffffffc02a5e70 <pmm_manager>
ffffffffc0202314:	4585                	li	a1,1
ffffffffc0202316:	e03e                	sd	a5,0(sp)
ffffffffc0202318:	7318                	ld	a4,32(a4)
ffffffffc020231a:	9702                	jalr	a4
    if (flag)
ffffffffc020231c:	6782                	ld	a5,0(sp)
ffffffffc020231e:	bfc9                	j	ffffffffc02022f0 <unmap_range+0xa0>
        intr_disable();
ffffffffc0202320:	e43e                	sd	a5,8(sp)
ffffffffc0202322:	e02a                	sd	a0,0(sp)
ffffffffc0202324:	de0fe0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202328:	000a4717          	auipc	a4,0xa4
ffffffffc020232c:	b4873703          	ld	a4,-1208(a4) # ffffffffc02a5e70 <pmm_manager>
ffffffffc0202330:	6502                	ld	a0,0(sp)
ffffffffc0202332:	4585                	li	a1,1
ffffffffc0202334:	7318                	ld	a4,32(a4)
ffffffffc0202336:	9702                	jalr	a4
        intr_enable();
ffffffffc0202338:	dc6fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc020233c:	67a2                	ld	a5,8(sp)
ffffffffc020233e:	bf4d                	j	ffffffffc02022f0 <unmap_range+0xa0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202340:	00004697          	auipc	a3,0x4
ffffffffc0202344:	5e868693          	addi	a3,a3,1512 # ffffffffc0206928 <etext+0xe6e>
ffffffffc0202348:	00004617          	auipc	a2,0x4
ffffffffc020234c:	f2060613          	addi	a2,a2,-224 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0202350:	12000593          	li	a1,288
ffffffffc0202354:	00004517          	auipc	a0,0x4
ffffffffc0202358:	5c450513          	addi	a0,a0,1476 # ffffffffc0206918 <etext+0xe5e>
ffffffffc020235c:	8eafe0ef          	jal	ffffffffc0200446 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202360:	00004697          	auipc	a3,0x4
ffffffffc0202364:	5f868693          	addi	a3,a3,1528 # ffffffffc0206958 <etext+0xe9e>
ffffffffc0202368:	00004617          	auipc	a2,0x4
ffffffffc020236c:	f0060613          	addi	a2,a2,-256 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0202370:	12100593          	li	a1,289
ffffffffc0202374:	00004517          	auipc	a0,0x4
ffffffffc0202378:	5a450513          	addi	a0,a0,1444 # ffffffffc0206918 <etext+0xe5e>
ffffffffc020237c:	8cafe0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0202380:	b5bff0ef          	jal	ffffffffc0201eda <pa2page.part.0>

ffffffffc0202384 <exit_range>:
{
ffffffffc0202384:	7135                	addi	sp,sp,-160
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202386:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc020238a:	ed06                	sd	ra,152(sp)
ffffffffc020238c:	e922                	sd	s0,144(sp)
ffffffffc020238e:	e526                	sd	s1,136(sp)
ffffffffc0202390:	e14a                	sd	s2,128(sp)
ffffffffc0202392:	fcce                	sd	s3,120(sp)
ffffffffc0202394:	f8d2                	sd	s4,112(sp)
ffffffffc0202396:	f4d6                	sd	s5,104(sp)
ffffffffc0202398:	f0da                	sd	s6,96(sp)
ffffffffc020239a:	ecde                	sd	s7,88(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020239c:	17d2                	slli	a5,a5,0x34
ffffffffc020239e:	22079263          	bnez	a5,ffffffffc02025c2 <exit_range+0x23e>
    assert(USER_ACCESS(start, end));
ffffffffc02023a2:	00200937          	lui	s2,0x200
ffffffffc02023a6:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc02023aa:	0125b733          	sltu	a4,a1,s2
ffffffffc02023ae:	0017b793          	seqz	a5,a5
ffffffffc02023b2:	8fd9                	or	a5,a5,a4
ffffffffc02023b4:	26079263          	bnez	a5,ffffffffc0202618 <exit_range+0x294>
ffffffffc02023b8:	4785                	li	a5,1
ffffffffc02023ba:	07fe                	slli	a5,a5,0x1f
ffffffffc02023bc:	0785                	addi	a5,a5,1
ffffffffc02023be:	24f67d63          	bgeu	a2,a5,ffffffffc0202618 <exit_range+0x294>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc02023c2:	c00004b7          	lui	s1,0xc0000
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc02023c6:	ffe007b7          	lui	a5,0xffe00
ffffffffc02023ca:	8a2a                	mv	s4,a0
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc02023cc:	8ced                	and	s1,s1,a1
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc02023ce:	00f5f833          	and	a6,a1,a5
    if (PPN(pa) >= npage)
ffffffffc02023d2:	000a4a97          	auipc	s5,0xa4
ffffffffc02023d6:	abea8a93          	addi	s5,s5,-1346 # ffffffffc02a5e90 <npage>
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02023da:	400009b7          	lui	s3,0x40000
ffffffffc02023de:	a809                	j	ffffffffc02023f0 <exit_range+0x6c>
        d1start += PDSIZE;
ffffffffc02023e0:	013487b3          	add	a5,s1,s3
ffffffffc02023e4:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc02023e8:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc02023ea:	c3f1                	beqz	a5,ffffffffc02024ae <exit_range+0x12a>
ffffffffc02023ec:	0cc7f163          	bgeu	a5,a2,ffffffffc02024ae <exit_range+0x12a>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc02023f0:	01e4d413          	srli	s0,s1,0x1e
ffffffffc02023f4:	1ff47413          	andi	s0,s0,511
ffffffffc02023f8:	040e                	slli	s0,s0,0x3
ffffffffc02023fa:	9452                	add	s0,s0,s4
ffffffffc02023fc:	00043883          	ld	a7,0(s0)
        if (pde1 & PTE_V)
ffffffffc0202400:	0018f793          	andi	a5,a7,1
ffffffffc0202404:	dff1                	beqz	a5,ffffffffc02023e0 <exit_range+0x5c>
ffffffffc0202406:	000ab783          	ld	a5,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc020240a:	088a                	slli	a7,a7,0x2
ffffffffc020240c:	00c8d893          	srli	a7,a7,0xc
    if (PPN(pa) >= npage)
ffffffffc0202410:	20f8f263          	bgeu	a7,a5,ffffffffc0202614 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc0202414:	fff802b7          	lui	t0,0xfff80
ffffffffc0202418:	00588f33          	add	t5,a7,t0
    return page - pages + nbase;
ffffffffc020241c:	000803b7          	lui	t2,0x80
ffffffffc0202420:	007f0733          	add	a4,t5,t2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202424:	00c71e13          	slli	t3,a4,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0202428:	0f1a                	slli	t5,t5,0x6
    return KADDR(page2pa(page));
ffffffffc020242a:	1cf77863          	bgeu	a4,a5,ffffffffc02025fa <exit_range+0x276>
ffffffffc020242e:	000a4f97          	auipc	t6,0xa4
ffffffffc0202432:	a5af8f93          	addi	t6,t6,-1446 # ffffffffc02a5e88 <va_pa_offset>
ffffffffc0202436:	000fb783          	ld	a5,0(t6)
            free_pd0 = 1;
ffffffffc020243a:	4e85                	li	t4,1
ffffffffc020243c:	6b05                	lui	s6,0x1
ffffffffc020243e:	9e3e                	add	t3,t3,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202440:	01348333          	add	t1,s1,s3
                pde0 = pd0[PDX0(d0start)];
ffffffffc0202444:	01585713          	srli	a4,a6,0x15
ffffffffc0202448:	1ff77713          	andi	a4,a4,511
ffffffffc020244c:	070e                	slli	a4,a4,0x3
ffffffffc020244e:	9772                	add	a4,a4,t3
ffffffffc0202450:	631c                	ld	a5,0(a4)
                if (pde0 & PTE_V)
ffffffffc0202452:	0017f693          	andi	a3,a5,1
ffffffffc0202456:	e6bd                	bnez	a3,ffffffffc02024c4 <exit_range+0x140>
                    free_pd0 = 0;
ffffffffc0202458:	4e81                	li	t4,0
                d0start += PTSIZE;
ffffffffc020245a:	984a                	add	a6,a6,s2
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc020245c:	00080863          	beqz	a6,ffffffffc020246c <exit_range+0xe8>
ffffffffc0202460:	879a                	mv	a5,t1
ffffffffc0202462:	00667363          	bgeu	a2,t1,ffffffffc0202468 <exit_range+0xe4>
ffffffffc0202466:	87b2                	mv	a5,a2
ffffffffc0202468:	fcf86ee3          	bltu	a6,a5,ffffffffc0202444 <exit_range+0xc0>
            if (free_pd0)
ffffffffc020246c:	f60e8ae3          	beqz	t4,ffffffffc02023e0 <exit_range+0x5c>
    if (PPN(pa) >= npage)
ffffffffc0202470:	000ab783          	ld	a5,0(s5)
ffffffffc0202474:	1af8f063          	bgeu	a7,a5,ffffffffc0202614 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc0202478:	000a4517          	auipc	a0,0xa4
ffffffffc020247c:	a2053503          	ld	a0,-1504(a0) # ffffffffc02a5e98 <pages>
ffffffffc0202480:	957a                	add	a0,a0,t5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202482:	100027f3          	csrr	a5,sstatus
ffffffffc0202486:	8b89                	andi	a5,a5,2
ffffffffc0202488:	10079b63          	bnez	a5,ffffffffc020259e <exit_range+0x21a>
        pmm_manager->free_pages(base, n);
ffffffffc020248c:	000a4797          	auipc	a5,0xa4
ffffffffc0202490:	9e47b783          	ld	a5,-1564(a5) # ffffffffc02a5e70 <pmm_manager>
ffffffffc0202494:	4585                	li	a1,1
ffffffffc0202496:	e432                	sd	a2,8(sp)
ffffffffc0202498:	739c                	ld	a5,32(a5)
ffffffffc020249a:	9782                	jalr	a5
ffffffffc020249c:	6622                	ld	a2,8(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc020249e:	00043023          	sd	zero,0(s0)
        d1start += PDSIZE;
ffffffffc02024a2:	013487b3          	add	a5,s1,s3
ffffffffc02024a6:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc02024aa:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc02024ac:	f3a1                	bnez	a5,ffffffffc02023ec <exit_range+0x68>
}
ffffffffc02024ae:	60ea                	ld	ra,152(sp)
ffffffffc02024b0:	644a                	ld	s0,144(sp)
ffffffffc02024b2:	64aa                	ld	s1,136(sp)
ffffffffc02024b4:	690a                	ld	s2,128(sp)
ffffffffc02024b6:	79e6                	ld	s3,120(sp)
ffffffffc02024b8:	7a46                	ld	s4,112(sp)
ffffffffc02024ba:	7aa6                	ld	s5,104(sp)
ffffffffc02024bc:	7b06                	ld	s6,96(sp)
ffffffffc02024be:	6be6                	ld	s7,88(sp)
ffffffffc02024c0:	610d                	addi	sp,sp,160
ffffffffc02024c2:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02024c4:	000ab503          	ld	a0,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc02024c8:	078a                	slli	a5,a5,0x2
ffffffffc02024ca:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024cc:	14a7f463          	bgeu	a5,a0,ffffffffc0202614 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc02024d0:	9796                	add	a5,a5,t0
    return page - pages + nbase;
ffffffffc02024d2:	00778bb3          	add	s7,a5,t2
    return &pages[PPN(pa) - nbase];
ffffffffc02024d6:	00679593          	slli	a1,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02024da:	00cb9693          	slli	a3,s7,0xc
    return KADDR(page2pa(page));
ffffffffc02024de:	10abf263          	bgeu	s7,a0,ffffffffc02025e2 <exit_range+0x25e>
ffffffffc02024e2:	000fb783          	ld	a5,0(t6)
ffffffffc02024e6:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02024e8:	01668533          	add	a0,a3,s6
                        if (pt[i] & PTE_V)
ffffffffc02024ec:	629c                	ld	a5,0(a3)
ffffffffc02024ee:	8b85                	andi	a5,a5,1
ffffffffc02024f0:	f7ad                	bnez	a5,ffffffffc020245a <exit_range+0xd6>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02024f2:	06a1                	addi	a3,a3,8
ffffffffc02024f4:	fea69ce3          	bne	a3,a0,ffffffffc02024ec <exit_range+0x168>
    return &pages[PPN(pa) - nbase];
ffffffffc02024f8:	000a4517          	auipc	a0,0xa4
ffffffffc02024fc:	9a053503          	ld	a0,-1632(a0) # ffffffffc02a5e98 <pages>
ffffffffc0202500:	952e                	add	a0,a0,a1
ffffffffc0202502:	100027f3          	csrr	a5,sstatus
ffffffffc0202506:	8b89                	andi	a5,a5,2
ffffffffc0202508:	e3b9                	bnez	a5,ffffffffc020254e <exit_range+0x1ca>
        pmm_manager->free_pages(base, n);
ffffffffc020250a:	000a4797          	auipc	a5,0xa4
ffffffffc020250e:	9667b783          	ld	a5,-1690(a5) # ffffffffc02a5e70 <pmm_manager>
ffffffffc0202512:	4585                	li	a1,1
ffffffffc0202514:	e0b2                	sd	a2,64(sp)
ffffffffc0202516:	739c                	ld	a5,32(a5)
ffffffffc0202518:	fc1a                	sd	t1,56(sp)
ffffffffc020251a:	f846                	sd	a7,48(sp)
ffffffffc020251c:	f47a                	sd	t5,40(sp)
ffffffffc020251e:	f072                	sd	t3,32(sp)
ffffffffc0202520:	ec76                	sd	t4,24(sp)
ffffffffc0202522:	e842                	sd	a6,16(sp)
ffffffffc0202524:	e43a                	sd	a4,8(sp)
ffffffffc0202526:	9782                	jalr	a5
    if (flag)
ffffffffc0202528:	6722                	ld	a4,8(sp)
ffffffffc020252a:	6842                	ld	a6,16(sp)
ffffffffc020252c:	6ee2                	ld	t4,24(sp)
ffffffffc020252e:	7e02                	ld	t3,32(sp)
ffffffffc0202530:	7f22                	ld	t5,40(sp)
ffffffffc0202532:	78c2                	ld	a7,48(sp)
ffffffffc0202534:	7362                	ld	t1,56(sp)
ffffffffc0202536:	6606                	ld	a2,64(sp)
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202538:	fff802b7          	lui	t0,0xfff80
ffffffffc020253c:	000803b7          	lui	t2,0x80
ffffffffc0202540:	000a4f97          	auipc	t6,0xa4
ffffffffc0202544:	948f8f93          	addi	t6,t6,-1720 # ffffffffc02a5e88 <va_pa_offset>
ffffffffc0202548:	00073023          	sd	zero,0(a4)
ffffffffc020254c:	b739                	j	ffffffffc020245a <exit_range+0xd6>
        intr_disable();
ffffffffc020254e:	e4b2                	sd	a2,72(sp)
ffffffffc0202550:	e09a                	sd	t1,64(sp)
ffffffffc0202552:	fc46                	sd	a7,56(sp)
ffffffffc0202554:	f47a                	sd	t5,40(sp)
ffffffffc0202556:	f072                	sd	t3,32(sp)
ffffffffc0202558:	ec76                	sd	t4,24(sp)
ffffffffc020255a:	e842                	sd	a6,16(sp)
ffffffffc020255c:	e43a                	sd	a4,8(sp)
ffffffffc020255e:	f82a                	sd	a0,48(sp)
ffffffffc0202560:	ba4fe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202564:	000a4797          	auipc	a5,0xa4
ffffffffc0202568:	90c7b783          	ld	a5,-1780(a5) # ffffffffc02a5e70 <pmm_manager>
ffffffffc020256c:	7542                	ld	a0,48(sp)
ffffffffc020256e:	4585                	li	a1,1
ffffffffc0202570:	739c                	ld	a5,32(a5)
ffffffffc0202572:	9782                	jalr	a5
        intr_enable();
ffffffffc0202574:	b8afe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202578:	6722                	ld	a4,8(sp)
ffffffffc020257a:	6626                	ld	a2,72(sp)
ffffffffc020257c:	6306                	ld	t1,64(sp)
ffffffffc020257e:	78e2                	ld	a7,56(sp)
ffffffffc0202580:	7f22                	ld	t5,40(sp)
ffffffffc0202582:	7e02                	ld	t3,32(sp)
ffffffffc0202584:	6ee2                	ld	t4,24(sp)
ffffffffc0202586:	6842                	ld	a6,16(sp)
ffffffffc0202588:	000a4f97          	auipc	t6,0xa4
ffffffffc020258c:	900f8f93          	addi	t6,t6,-1792 # ffffffffc02a5e88 <va_pa_offset>
ffffffffc0202590:	000803b7          	lui	t2,0x80
ffffffffc0202594:	fff802b7          	lui	t0,0xfff80
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202598:	00073023          	sd	zero,0(a4)
ffffffffc020259c:	bd7d                	j	ffffffffc020245a <exit_range+0xd6>
        intr_disable();
ffffffffc020259e:	e832                	sd	a2,16(sp)
ffffffffc02025a0:	e42a                	sd	a0,8(sp)
ffffffffc02025a2:	b62fe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02025a6:	000a4797          	auipc	a5,0xa4
ffffffffc02025aa:	8ca7b783          	ld	a5,-1846(a5) # ffffffffc02a5e70 <pmm_manager>
ffffffffc02025ae:	6522                	ld	a0,8(sp)
ffffffffc02025b0:	4585                	li	a1,1
ffffffffc02025b2:	739c                	ld	a5,32(a5)
ffffffffc02025b4:	9782                	jalr	a5
        intr_enable();
ffffffffc02025b6:	b48fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02025ba:	6642                	ld	a2,16(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc02025bc:	00043023          	sd	zero,0(s0)
ffffffffc02025c0:	b5cd                	j	ffffffffc02024a2 <exit_range+0x11e>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02025c2:	00004697          	auipc	a3,0x4
ffffffffc02025c6:	36668693          	addi	a3,a3,870 # ffffffffc0206928 <etext+0xe6e>
ffffffffc02025ca:	00004617          	auipc	a2,0x4
ffffffffc02025ce:	c9e60613          	addi	a2,a2,-866 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02025d2:	13500593          	li	a1,309
ffffffffc02025d6:	00004517          	auipc	a0,0x4
ffffffffc02025da:	34250513          	addi	a0,a0,834 # ffffffffc0206918 <etext+0xe5e>
ffffffffc02025de:	e69fd0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc02025e2:	00004617          	auipc	a2,0x4
ffffffffc02025e6:	24660613          	addi	a2,a2,582 # ffffffffc0206828 <etext+0xd6e>
ffffffffc02025ea:	07100593          	li	a1,113
ffffffffc02025ee:	00004517          	auipc	a0,0x4
ffffffffc02025f2:	26250513          	addi	a0,a0,610 # ffffffffc0206850 <etext+0xd96>
ffffffffc02025f6:	e51fd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc02025fa:	86f2                	mv	a3,t3
ffffffffc02025fc:	00004617          	auipc	a2,0x4
ffffffffc0202600:	22c60613          	addi	a2,a2,556 # ffffffffc0206828 <etext+0xd6e>
ffffffffc0202604:	07100593          	li	a1,113
ffffffffc0202608:	00004517          	auipc	a0,0x4
ffffffffc020260c:	24850513          	addi	a0,a0,584 # ffffffffc0206850 <etext+0xd96>
ffffffffc0202610:	e37fd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0202614:	8c7ff0ef          	jal	ffffffffc0201eda <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0202618:	00004697          	auipc	a3,0x4
ffffffffc020261c:	34068693          	addi	a3,a3,832 # ffffffffc0206958 <etext+0xe9e>
ffffffffc0202620:	00004617          	auipc	a2,0x4
ffffffffc0202624:	c4860613          	addi	a2,a2,-952 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0202628:	13600593          	li	a1,310
ffffffffc020262c:	00004517          	auipc	a0,0x4
ffffffffc0202630:	2ec50513          	addi	a0,a0,748 # ffffffffc0206918 <etext+0xe5e>
ffffffffc0202634:	e13fd0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0202638 <page_remove>:
{
ffffffffc0202638:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020263a:	4601                	li	a2,0
{
ffffffffc020263c:	e822                	sd	s0,16(sp)
ffffffffc020263e:	ec06                	sd	ra,24(sp)
ffffffffc0202640:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202642:	95dff0ef          	jal	ffffffffc0201f9e <get_pte>
    if (ptep != NULL)
ffffffffc0202646:	c511                	beqz	a0,ffffffffc0202652 <page_remove+0x1a>
    if (*ptep & PTE_V)
ffffffffc0202648:	6118                	ld	a4,0(a0)
ffffffffc020264a:	87aa                	mv	a5,a0
ffffffffc020264c:	00177693          	andi	a3,a4,1
ffffffffc0202650:	e689                	bnez	a3,ffffffffc020265a <page_remove+0x22>
}
ffffffffc0202652:	60e2                	ld	ra,24(sp)
ffffffffc0202654:	6442                	ld	s0,16(sp)
ffffffffc0202656:	6105                	addi	sp,sp,32
ffffffffc0202658:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc020265a:	000a4697          	auipc	a3,0xa4
ffffffffc020265e:	8366b683          	ld	a3,-1994(a3) # ffffffffc02a5e90 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0202662:	070a                	slli	a4,a4,0x2
ffffffffc0202664:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202666:	06d77563          	bgeu	a4,a3,ffffffffc02026d0 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc020266a:	000a4517          	auipc	a0,0xa4
ffffffffc020266e:	82e53503          	ld	a0,-2002(a0) # ffffffffc02a5e98 <pages>
ffffffffc0202672:	071a                	slli	a4,a4,0x6
ffffffffc0202674:	fe0006b7          	lui	a3,0xfe000
ffffffffc0202678:	9736                	add	a4,a4,a3
ffffffffc020267a:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc020267c:	4118                	lw	a4,0(a0)
ffffffffc020267e:	377d                	addiw	a4,a4,-1
ffffffffc0202680:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc0202682:	cb09                	beqz	a4,ffffffffc0202694 <page_remove+0x5c>
        *ptep = 0;
ffffffffc0202684:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202688:	12040073          	sfence.vma	s0
}
ffffffffc020268c:	60e2                	ld	ra,24(sp)
ffffffffc020268e:	6442                	ld	s0,16(sp)
ffffffffc0202690:	6105                	addi	sp,sp,32
ffffffffc0202692:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202694:	10002773          	csrr	a4,sstatus
ffffffffc0202698:	8b09                	andi	a4,a4,2
ffffffffc020269a:	eb19                	bnez	a4,ffffffffc02026b0 <page_remove+0x78>
        pmm_manager->free_pages(base, n);
ffffffffc020269c:	000a3717          	auipc	a4,0xa3
ffffffffc02026a0:	7d473703          	ld	a4,2004(a4) # ffffffffc02a5e70 <pmm_manager>
ffffffffc02026a4:	4585                	li	a1,1
ffffffffc02026a6:	e03e                	sd	a5,0(sp)
ffffffffc02026a8:	7318                	ld	a4,32(a4)
ffffffffc02026aa:	9702                	jalr	a4
    if (flag)
ffffffffc02026ac:	6782                	ld	a5,0(sp)
ffffffffc02026ae:	bfd9                	j	ffffffffc0202684 <page_remove+0x4c>
        intr_disable();
ffffffffc02026b0:	e43e                	sd	a5,8(sp)
ffffffffc02026b2:	e02a                	sd	a0,0(sp)
ffffffffc02026b4:	a50fe0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc02026b8:	000a3717          	auipc	a4,0xa3
ffffffffc02026bc:	7b873703          	ld	a4,1976(a4) # ffffffffc02a5e70 <pmm_manager>
ffffffffc02026c0:	6502                	ld	a0,0(sp)
ffffffffc02026c2:	4585                	li	a1,1
ffffffffc02026c4:	7318                	ld	a4,32(a4)
ffffffffc02026c6:	9702                	jalr	a4
        intr_enable();
ffffffffc02026c8:	a36fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02026cc:	67a2                	ld	a5,8(sp)
ffffffffc02026ce:	bf5d                	j	ffffffffc0202684 <page_remove+0x4c>
ffffffffc02026d0:	80bff0ef          	jal	ffffffffc0201eda <pa2page.part.0>

ffffffffc02026d4 <page_insert>:
{
ffffffffc02026d4:	7139                	addi	sp,sp,-64
ffffffffc02026d6:	f426                	sd	s1,40(sp)
ffffffffc02026d8:	84b2                	mv	s1,a2
ffffffffc02026da:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026dc:	4605                	li	a2,1
{
ffffffffc02026de:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026e0:	85a6                	mv	a1,s1
{
ffffffffc02026e2:	fc06                	sd	ra,56(sp)
ffffffffc02026e4:	e436                	sd	a3,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026e6:	8b9ff0ef          	jal	ffffffffc0201f9e <get_pte>
    if (ptep == NULL)
ffffffffc02026ea:	cd61                	beqz	a0,ffffffffc02027c2 <page_insert+0xee>
    page->ref += 1;
ffffffffc02026ec:	400c                	lw	a1,0(s0)
    if (*ptep & PTE_V)
ffffffffc02026ee:	611c                	ld	a5,0(a0)
ffffffffc02026f0:	66a2                	ld	a3,8(sp)
ffffffffc02026f2:	0015861b          	addiw	a2,a1,1 # 1001 <_binary_obj___user_softint_out_size-0x7c07>
ffffffffc02026f6:	c010                	sw	a2,0(s0)
ffffffffc02026f8:	0017f613          	andi	a2,a5,1
ffffffffc02026fc:	872a                	mv	a4,a0
ffffffffc02026fe:	e61d                	bnez	a2,ffffffffc020272c <page_insert+0x58>
    return &pages[PPN(pa) - nbase];
ffffffffc0202700:	000a3617          	auipc	a2,0xa3
ffffffffc0202704:	79863603          	ld	a2,1944(a2) # ffffffffc02a5e98 <pages>
    return page - pages + nbase;
ffffffffc0202708:	8c11                	sub	s0,s0,a2
ffffffffc020270a:	8419                	srai	s0,s0,0x6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020270c:	200007b7          	lui	a5,0x20000
ffffffffc0202710:	042a                	slli	s0,s0,0xa
ffffffffc0202712:	943e                	add	s0,s0,a5
ffffffffc0202714:	8ec1                	or	a3,a3,s0
ffffffffc0202716:	0016e693          	ori	a3,a3,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc020271a:	e314                	sd	a3,0(a4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020271c:	12048073          	sfence.vma	s1
    return 0;
ffffffffc0202720:	4501                	li	a0,0
}
ffffffffc0202722:	70e2                	ld	ra,56(sp)
ffffffffc0202724:	7442                	ld	s0,48(sp)
ffffffffc0202726:	74a2                	ld	s1,40(sp)
ffffffffc0202728:	6121                	addi	sp,sp,64
ffffffffc020272a:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc020272c:	000a3617          	auipc	a2,0xa3
ffffffffc0202730:	76463603          	ld	a2,1892(a2) # ffffffffc02a5e90 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0202734:	078a                	slli	a5,a5,0x2
ffffffffc0202736:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202738:	08c7f763          	bgeu	a5,a2,ffffffffc02027c6 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc020273c:	000a3617          	auipc	a2,0xa3
ffffffffc0202740:	75c63603          	ld	a2,1884(a2) # ffffffffc02a5e98 <pages>
ffffffffc0202744:	fe000537          	lui	a0,0xfe000
ffffffffc0202748:	079a                	slli	a5,a5,0x6
ffffffffc020274a:	97aa                	add	a5,a5,a0
ffffffffc020274c:	00f60533          	add	a0,a2,a5
        if (p == page)
ffffffffc0202750:	00a40963          	beq	s0,a0,ffffffffc0202762 <page_insert+0x8e>
    page->ref -= 1;
ffffffffc0202754:	411c                	lw	a5,0(a0)
ffffffffc0202756:	37fd                	addiw	a5,a5,-1 # 1fffffff <_binary_obj___user_COW_out_size+0x1fff5bdf>
ffffffffc0202758:	c11c                	sw	a5,0(a0)
        if (page_ref(page) == 0)
ffffffffc020275a:	c791                	beqz	a5,ffffffffc0202766 <page_insert+0x92>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020275c:	12048073          	sfence.vma	s1
}
ffffffffc0202760:	b765                	j	ffffffffc0202708 <page_insert+0x34>
ffffffffc0202762:	c00c                	sw	a1,0(s0)
    return page->ref;
ffffffffc0202764:	b755                	j	ffffffffc0202708 <page_insert+0x34>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202766:	100027f3          	csrr	a5,sstatus
ffffffffc020276a:	8b89                	andi	a5,a5,2
ffffffffc020276c:	e39d                	bnez	a5,ffffffffc0202792 <page_insert+0xbe>
        pmm_manager->free_pages(base, n);
ffffffffc020276e:	000a3797          	auipc	a5,0xa3
ffffffffc0202772:	7027b783          	ld	a5,1794(a5) # ffffffffc02a5e70 <pmm_manager>
ffffffffc0202776:	4585                	li	a1,1
ffffffffc0202778:	e83a                	sd	a4,16(sp)
ffffffffc020277a:	739c                	ld	a5,32(a5)
ffffffffc020277c:	e436                	sd	a3,8(sp)
ffffffffc020277e:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202780:	000a3617          	auipc	a2,0xa3
ffffffffc0202784:	71863603          	ld	a2,1816(a2) # ffffffffc02a5e98 <pages>
ffffffffc0202788:	66a2                	ld	a3,8(sp)
ffffffffc020278a:	6742                	ld	a4,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020278c:	12048073          	sfence.vma	s1
ffffffffc0202790:	bfa5                	j	ffffffffc0202708 <page_insert+0x34>
        intr_disable();
ffffffffc0202792:	ec3a                	sd	a4,24(sp)
ffffffffc0202794:	e836                	sd	a3,16(sp)
ffffffffc0202796:	e42a                	sd	a0,8(sp)
ffffffffc0202798:	96cfe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020279c:	000a3797          	auipc	a5,0xa3
ffffffffc02027a0:	6d47b783          	ld	a5,1748(a5) # ffffffffc02a5e70 <pmm_manager>
ffffffffc02027a4:	6522                	ld	a0,8(sp)
ffffffffc02027a6:	4585                	li	a1,1
ffffffffc02027a8:	739c                	ld	a5,32(a5)
ffffffffc02027aa:	9782                	jalr	a5
        intr_enable();
ffffffffc02027ac:	952fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02027b0:	000a3617          	auipc	a2,0xa3
ffffffffc02027b4:	6e863603          	ld	a2,1768(a2) # ffffffffc02a5e98 <pages>
ffffffffc02027b8:	6762                	ld	a4,24(sp)
ffffffffc02027ba:	66c2                	ld	a3,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02027bc:	12048073          	sfence.vma	s1
ffffffffc02027c0:	b7a1                	j	ffffffffc0202708 <page_insert+0x34>
        return -E_NO_MEM;
ffffffffc02027c2:	5571                	li	a0,-4
ffffffffc02027c4:	bfb9                	j	ffffffffc0202722 <page_insert+0x4e>
ffffffffc02027c6:	f14ff0ef          	jal	ffffffffc0201eda <pa2page.part.0>

ffffffffc02027ca <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02027ca:	00005797          	auipc	a5,0x5
ffffffffc02027ce:	1f678793          	addi	a5,a5,502 # ffffffffc02079c0 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027d2:	638c                	ld	a1,0(a5)
{
ffffffffc02027d4:	7159                	addi	sp,sp,-112
ffffffffc02027d6:	f486                	sd	ra,104(sp)
ffffffffc02027d8:	e8ca                	sd	s2,80(sp)
ffffffffc02027da:	e4ce                	sd	s3,72(sp)
ffffffffc02027dc:	f85a                	sd	s6,48(sp)
ffffffffc02027de:	f0a2                	sd	s0,96(sp)
ffffffffc02027e0:	eca6                	sd	s1,88(sp)
ffffffffc02027e2:	e0d2                	sd	s4,64(sp)
ffffffffc02027e4:	fc56                	sd	s5,56(sp)
ffffffffc02027e6:	f45e                	sd	s7,40(sp)
ffffffffc02027e8:	f062                	sd	s8,32(sp)
ffffffffc02027ea:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02027ec:	000a3b17          	auipc	s6,0xa3
ffffffffc02027f0:	684b0b13          	addi	s6,s6,1668 # ffffffffc02a5e70 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027f4:	00004517          	auipc	a0,0x4
ffffffffc02027f8:	17c50513          	addi	a0,a0,380 # ffffffffc0206970 <etext+0xeb6>
    pmm_manager = &default_pmm_manager;
ffffffffc02027fc:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202800:	995fd0ef          	jal	ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc0202804:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202808:	000a3997          	auipc	s3,0xa3
ffffffffc020280c:	68098993          	addi	s3,s3,1664 # ffffffffc02a5e88 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202810:	679c                	ld	a5,8(a5)
ffffffffc0202812:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202814:	57f5                	li	a5,-3
ffffffffc0202816:	07fa                	slli	a5,a5,0x1e
ffffffffc0202818:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc020281c:	8cefe0ef          	jal	ffffffffc02008ea <get_memory_base>
ffffffffc0202820:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0202822:	8d2fe0ef          	jal	ffffffffc02008f4 <get_memory_size>
    if (mem_size == 0)
ffffffffc0202826:	70050e63          	beqz	a0,ffffffffc0202f42 <pmm_init+0x778>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc020282a:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc020282c:	00004517          	auipc	a0,0x4
ffffffffc0202830:	17c50513          	addi	a0,a0,380 # ffffffffc02069a8 <etext+0xeee>
ffffffffc0202834:	961fd0ef          	jal	ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202838:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc020283c:	864a                	mv	a2,s2
ffffffffc020283e:	85a6                	mv	a1,s1
ffffffffc0202840:	fff40693          	addi	a3,s0,-1
ffffffffc0202844:	00004517          	auipc	a0,0x4
ffffffffc0202848:	17c50513          	addi	a0,a0,380 # ffffffffc02069c0 <etext+0xf06>
ffffffffc020284c:	949fd0ef          	jal	ffffffffc0200194 <cprintf>
    if (maxpa > KERNTOP)
ffffffffc0202850:	c80007b7          	lui	a5,0xc8000
ffffffffc0202854:	8522                	mv	a0,s0
ffffffffc0202856:	5287ed63          	bltu	a5,s0,ffffffffc0202d90 <pmm_init+0x5c6>
ffffffffc020285a:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020285c:	000a4617          	auipc	a2,0xa4
ffffffffc0202860:	66b60613          	addi	a2,a2,1643 # ffffffffc02a6ec7 <end+0xfff>
ffffffffc0202864:	8e7d                	and	a2,a2,a5
    npage = maxpa / PGSIZE;
ffffffffc0202866:	8131                	srli	a0,a0,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202868:	000a3b97          	auipc	s7,0xa3
ffffffffc020286c:	630b8b93          	addi	s7,s7,1584 # ffffffffc02a5e98 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0202870:	000a3497          	auipc	s1,0xa3
ffffffffc0202874:	62048493          	addi	s1,s1,1568 # ffffffffc02a5e90 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202878:	00cbb023          	sd	a2,0(s7)
    npage = maxpa / PGSIZE;
ffffffffc020287c:	e088                	sd	a0,0(s1)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020287e:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202882:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202884:	02f50763          	beq	a0,a5,ffffffffc02028b2 <pmm_init+0xe8>
ffffffffc0202888:	4701                	li	a4,0
ffffffffc020288a:	4585                	li	a1,1
ffffffffc020288c:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc0202890:	00671793          	slli	a5,a4,0x6
ffffffffc0202894:	97b2                	add	a5,a5,a2
ffffffffc0202896:	07a1                	addi	a5,a5,8 # 80008 <_binary_obj___user_COW_out_size+0x75be8>
ffffffffc0202898:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020289c:	6088                	ld	a0,0(s1)
ffffffffc020289e:	0705                	addi	a4,a4,1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02028a0:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02028a4:	00d507b3          	add	a5,a0,a3
ffffffffc02028a8:	fef764e3          	bltu	a4,a5,ffffffffc0202890 <pmm_init+0xc6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02028ac:	079a                	slli	a5,a5,0x6
ffffffffc02028ae:	00f606b3          	add	a3,a2,a5
ffffffffc02028b2:	c02007b7          	lui	a5,0xc0200
ffffffffc02028b6:	16f6eee3          	bltu	a3,a5,ffffffffc0203232 <pmm_init+0xa68>
ffffffffc02028ba:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02028be:	77fd                	lui	a5,0xfffff
ffffffffc02028c0:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02028c2:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc02028c4:	4e86ed63          	bltu	a3,s0,ffffffffc0202dbe <pmm_init+0x5f4>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc02028c8:	00004517          	auipc	a0,0x4
ffffffffc02028cc:	12050513          	addi	a0,a0,288 # ffffffffc02069e8 <etext+0xf2e>
ffffffffc02028d0:	8c5fd0ef          	jal	ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc02028d4:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02028d8:	000a3917          	auipc	s2,0xa3
ffffffffc02028dc:	5a890913          	addi	s2,s2,1448 # ffffffffc02a5e80 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc02028e0:	7b9c                	ld	a5,48(a5)
ffffffffc02028e2:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02028e4:	00004517          	auipc	a0,0x4
ffffffffc02028e8:	11c50513          	addi	a0,a0,284 # ffffffffc0206a00 <etext+0xf46>
ffffffffc02028ec:	8a9fd0ef          	jal	ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02028f0:	00007697          	auipc	a3,0x7
ffffffffc02028f4:	71068693          	addi	a3,a3,1808 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc02028f8:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02028fc:	c02007b7          	lui	a5,0xc0200
ffffffffc0202900:	2af6eee3          	bltu	a3,a5,ffffffffc02033bc <pmm_init+0xbf2>
ffffffffc0202904:	0009b783          	ld	a5,0(s3)
ffffffffc0202908:	8e9d                	sub	a3,a3,a5
ffffffffc020290a:	000a3797          	auipc	a5,0xa3
ffffffffc020290e:	56d7b723          	sd	a3,1390(a5) # ffffffffc02a5e78 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202912:	100027f3          	csrr	a5,sstatus
ffffffffc0202916:	8b89                	andi	a5,a5,2
ffffffffc0202918:	48079963          	bnez	a5,ffffffffc0202daa <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc020291c:	000b3783          	ld	a5,0(s6)
ffffffffc0202920:	779c                	ld	a5,40(a5)
ffffffffc0202922:	9782                	jalr	a5
ffffffffc0202924:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202926:	6098                	ld	a4,0(s1)
ffffffffc0202928:	c80007b7          	lui	a5,0xc8000
ffffffffc020292c:	83b1                	srli	a5,a5,0xc
ffffffffc020292e:	66e7e663          	bltu	a5,a4,ffffffffc0202f9a <pmm_init+0x7d0>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202932:	00093503          	ld	a0,0(s2)
ffffffffc0202936:	64050263          	beqz	a0,ffffffffc0202f7a <pmm_init+0x7b0>
ffffffffc020293a:	03451793          	slli	a5,a0,0x34
ffffffffc020293e:	62079e63          	bnez	a5,ffffffffc0202f7a <pmm_init+0x7b0>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202942:	4601                	li	a2,0
ffffffffc0202944:	4581                	li	a1,0
ffffffffc0202946:	8b7ff0ef          	jal	ffffffffc02021fc <get_page>
ffffffffc020294a:	240519e3          	bnez	a0,ffffffffc020339c <pmm_init+0xbd2>
ffffffffc020294e:	100027f3          	csrr	a5,sstatus
ffffffffc0202952:	8b89                	andi	a5,a5,2
ffffffffc0202954:	44079063          	bnez	a5,ffffffffc0202d94 <pmm_init+0x5ca>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202958:	000b3783          	ld	a5,0(s6)
ffffffffc020295c:	4505                	li	a0,1
ffffffffc020295e:	6f9c                	ld	a5,24(a5)
ffffffffc0202960:	9782                	jalr	a5
ffffffffc0202962:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202964:	00093503          	ld	a0,0(s2)
ffffffffc0202968:	4681                	li	a3,0
ffffffffc020296a:	4601                	li	a2,0
ffffffffc020296c:	85d2                	mv	a1,s4
ffffffffc020296e:	d67ff0ef          	jal	ffffffffc02026d4 <page_insert>
ffffffffc0202972:	280511e3          	bnez	a0,ffffffffc02033f4 <pmm_init+0xc2a>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202976:	00093503          	ld	a0,0(s2)
ffffffffc020297a:	4601                	li	a2,0
ffffffffc020297c:	4581                	li	a1,0
ffffffffc020297e:	e20ff0ef          	jal	ffffffffc0201f9e <get_pte>
ffffffffc0202982:	240509e3          	beqz	a0,ffffffffc02033d4 <pmm_init+0xc0a>
    assert(pte2page(*ptep) == p1);
ffffffffc0202986:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202988:	0017f713          	andi	a4,a5,1
ffffffffc020298c:	58070f63          	beqz	a4,ffffffffc0202f2a <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc0202990:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202992:	078a                	slli	a5,a5,0x2
ffffffffc0202994:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202996:	58e7f863          	bgeu	a5,a4,ffffffffc0202f26 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc020299a:	000bb683          	ld	a3,0(s7)
ffffffffc020299e:	079a                	slli	a5,a5,0x6
ffffffffc02029a0:	fe000637          	lui	a2,0xfe000
ffffffffc02029a4:	97b2                	add	a5,a5,a2
ffffffffc02029a6:	97b6                	add	a5,a5,a3
ffffffffc02029a8:	14fa1ae3          	bne	s4,a5,ffffffffc02032fc <pmm_init+0xb32>
    assert(page_ref(p1) == 1);
ffffffffc02029ac:	000a2683          	lw	a3,0(s4) # 200000 <_binary_obj___user_COW_out_size+0x1f5be0>
ffffffffc02029b0:	4785                	li	a5,1
ffffffffc02029b2:	12f695e3          	bne	a3,a5,ffffffffc02032dc <pmm_init+0xb12>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02029b6:	00093503          	ld	a0,0(s2)
ffffffffc02029ba:	77fd                	lui	a5,0xfffff
ffffffffc02029bc:	6114                	ld	a3,0(a0)
ffffffffc02029be:	068a                	slli	a3,a3,0x2
ffffffffc02029c0:	8efd                	and	a3,a3,a5
ffffffffc02029c2:	00c6d613          	srli	a2,a3,0xc
ffffffffc02029c6:	0ee67fe3          	bgeu	a2,a4,ffffffffc02032c4 <pmm_init+0xafa>
ffffffffc02029ca:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029ce:	96e2                	add	a3,a3,s8
ffffffffc02029d0:	0006ba83          	ld	s5,0(a3)
ffffffffc02029d4:	0a8a                	slli	s5,s5,0x2
ffffffffc02029d6:	00fafab3          	and	s5,s5,a5
ffffffffc02029da:	00cad793          	srli	a5,s5,0xc
ffffffffc02029de:	0ce7f6e3          	bgeu	a5,a4,ffffffffc02032aa <pmm_init+0xae0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02029e2:	4601                	li	a2,0
ffffffffc02029e4:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029e6:	9c56                	add	s8,s8,s5
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02029e8:	db6ff0ef          	jal	ffffffffc0201f9e <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029ec:	0c21                	addi	s8,s8,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02029ee:	05851ee3          	bne	a0,s8,ffffffffc020324a <pmm_init+0xa80>
ffffffffc02029f2:	100027f3          	csrr	a5,sstatus
ffffffffc02029f6:	8b89                	andi	a5,a5,2
ffffffffc02029f8:	3e079b63          	bnez	a5,ffffffffc0202dee <pmm_init+0x624>
        page = pmm_manager->alloc_pages(n);
ffffffffc02029fc:	000b3783          	ld	a5,0(s6)
ffffffffc0202a00:	4505                	li	a0,1
ffffffffc0202a02:	6f9c                	ld	a5,24(a5)
ffffffffc0202a04:	9782                	jalr	a5
ffffffffc0202a06:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202a08:	00093503          	ld	a0,0(s2)
ffffffffc0202a0c:	46d1                	li	a3,20
ffffffffc0202a0e:	6605                	lui	a2,0x1
ffffffffc0202a10:	85e2                	mv	a1,s8
ffffffffc0202a12:	cc3ff0ef          	jal	ffffffffc02026d4 <page_insert>
ffffffffc0202a16:	06051ae3          	bnez	a0,ffffffffc020328a <pmm_init+0xac0>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a1a:	00093503          	ld	a0,0(s2)
ffffffffc0202a1e:	4601                	li	a2,0
ffffffffc0202a20:	6585                	lui	a1,0x1
ffffffffc0202a22:	d7cff0ef          	jal	ffffffffc0201f9e <get_pte>
ffffffffc0202a26:	040502e3          	beqz	a0,ffffffffc020326a <pmm_init+0xaa0>
    assert(*ptep & PTE_U);
ffffffffc0202a2a:	611c                	ld	a5,0(a0)
ffffffffc0202a2c:	0107f713          	andi	a4,a5,16
ffffffffc0202a30:	7e070163          	beqz	a4,ffffffffc0203212 <pmm_init+0xa48>
    assert(*ptep & PTE_W);
ffffffffc0202a34:	8b91                	andi	a5,a5,4
ffffffffc0202a36:	7a078e63          	beqz	a5,ffffffffc02031f2 <pmm_init+0xa28>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202a3a:	00093503          	ld	a0,0(s2)
ffffffffc0202a3e:	611c                	ld	a5,0(a0)
ffffffffc0202a40:	8bc1                	andi	a5,a5,16
ffffffffc0202a42:	78078863          	beqz	a5,ffffffffc02031d2 <pmm_init+0xa08>
    assert(page_ref(p2) == 1);
ffffffffc0202a46:	000c2703          	lw	a4,0(s8)
ffffffffc0202a4a:	4785                	li	a5,1
ffffffffc0202a4c:	76f71363          	bne	a4,a5,ffffffffc02031b2 <pmm_init+0x9e8>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202a50:	4681                	li	a3,0
ffffffffc0202a52:	6605                	lui	a2,0x1
ffffffffc0202a54:	85d2                	mv	a1,s4
ffffffffc0202a56:	c7fff0ef          	jal	ffffffffc02026d4 <page_insert>
ffffffffc0202a5a:	72051c63          	bnez	a0,ffffffffc0203192 <pmm_init+0x9c8>
    assert(page_ref(p1) == 2);
ffffffffc0202a5e:	000a2703          	lw	a4,0(s4)
ffffffffc0202a62:	4789                	li	a5,2
ffffffffc0202a64:	70f71763          	bne	a4,a5,ffffffffc0203172 <pmm_init+0x9a8>
    assert(page_ref(p2) == 0);
ffffffffc0202a68:	000c2783          	lw	a5,0(s8)
ffffffffc0202a6c:	6e079363          	bnez	a5,ffffffffc0203152 <pmm_init+0x988>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a70:	00093503          	ld	a0,0(s2)
ffffffffc0202a74:	4601                	li	a2,0
ffffffffc0202a76:	6585                	lui	a1,0x1
ffffffffc0202a78:	d26ff0ef          	jal	ffffffffc0201f9e <get_pte>
ffffffffc0202a7c:	6a050b63          	beqz	a0,ffffffffc0203132 <pmm_init+0x968>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a80:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202a82:	00177793          	andi	a5,a4,1
ffffffffc0202a86:	4a078263          	beqz	a5,ffffffffc0202f2a <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc0202a8a:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202a8c:	00271793          	slli	a5,a4,0x2
ffffffffc0202a90:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a92:	48d7fa63          	bgeu	a5,a3,ffffffffc0202f26 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a96:	000bb683          	ld	a3,0(s7)
ffffffffc0202a9a:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202a9e:	97d6                	add	a5,a5,s5
ffffffffc0202aa0:	079a                	slli	a5,a5,0x6
ffffffffc0202aa2:	97b6                	add	a5,a5,a3
ffffffffc0202aa4:	66fa1763          	bne	s4,a5,ffffffffc0203112 <pmm_init+0x948>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202aa8:	8b41                	andi	a4,a4,16
ffffffffc0202aaa:	64071463          	bnez	a4,ffffffffc02030f2 <pmm_init+0x928>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202aae:	00093503          	ld	a0,0(s2)
ffffffffc0202ab2:	4581                	li	a1,0
ffffffffc0202ab4:	b85ff0ef          	jal	ffffffffc0202638 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202ab8:	000a2c83          	lw	s9,0(s4)
ffffffffc0202abc:	4785                	li	a5,1
ffffffffc0202abe:	60fc9a63          	bne	s9,a5,ffffffffc02030d2 <pmm_init+0x908>
    assert(page_ref(p2) == 0);
ffffffffc0202ac2:	000c2783          	lw	a5,0(s8)
ffffffffc0202ac6:	5e079663          	bnez	a5,ffffffffc02030b2 <pmm_init+0x8e8>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202aca:	00093503          	ld	a0,0(s2)
ffffffffc0202ace:	6585                	lui	a1,0x1
ffffffffc0202ad0:	b69ff0ef          	jal	ffffffffc0202638 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202ad4:	000a2783          	lw	a5,0(s4)
ffffffffc0202ad8:	52079d63          	bnez	a5,ffffffffc0203012 <pmm_init+0x848>
    assert(page_ref(p2) == 0);
ffffffffc0202adc:	000c2783          	lw	a5,0(s8)
ffffffffc0202ae0:	50079963          	bnez	a5,ffffffffc0202ff2 <pmm_init+0x828>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202ae4:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202ae8:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202aea:	000a3783          	ld	a5,0(s4)
ffffffffc0202aee:	078a                	slli	a5,a5,0x2
ffffffffc0202af0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202af2:	42e7fa63          	bgeu	a5,a4,ffffffffc0202f26 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202af6:	000bb503          	ld	a0,0(s7)
ffffffffc0202afa:	97d6                	add	a5,a5,s5
ffffffffc0202afc:	079a                	slli	a5,a5,0x6
    return page->ref;
ffffffffc0202afe:	00f506b3          	add	a3,a0,a5
ffffffffc0202b02:	4294                	lw	a3,0(a3)
ffffffffc0202b04:	4d969763          	bne	a3,s9,ffffffffc0202fd2 <pmm_init+0x808>
    return page - pages + nbase;
ffffffffc0202b08:	8799                	srai	a5,a5,0x6
ffffffffc0202b0a:	00080637          	lui	a2,0x80
ffffffffc0202b0e:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202b10:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202b14:	4ae7f363          	bgeu	a5,a4,ffffffffc0202fba <pmm_init+0x7f0>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202b18:	0009b783          	ld	a5,0(s3)
ffffffffc0202b1c:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b1e:	639c                	ld	a5,0(a5)
ffffffffc0202b20:	078a                	slli	a5,a5,0x2
ffffffffc0202b22:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b24:	40e7f163          	bgeu	a5,a4,ffffffffc0202f26 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b28:	8f91                	sub	a5,a5,a2
ffffffffc0202b2a:	079a                	slli	a5,a5,0x6
ffffffffc0202b2c:	953e                	add	a0,a0,a5
ffffffffc0202b2e:	100027f3          	csrr	a5,sstatus
ffffffffc0202b32:	8b89                	andi	a5,a5,2
ffffffffc0202b34:	30079863          	bnez	a5,ffffffffc0202e44 <pmm_init+0x67a>
        pmm_manager->free_pages(base, n);
ffffffffc0202b38:	000b3783          	ld	a5,0(s6)
ffffffffc0202b3c:	4585                	li	a1,1
ffffffffc0202b3e:	739c                	ld	a5,32(a5)
ffffffffc0202b40:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b42:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202b46:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b48:	078a                	slli	a5,a5,0x2
ffffffffc0202b4a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b4c:	3ce7fd63          	bgeu	a5,a4,ffffffffc0202f26 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b50:	000bb503          	ld	a0,0(s7)
ffffffffc0202b54:	fe000737          	lui	a4,0xfe000
ffffffffc0202b58:	079a                	slli	a5,a5,0x6
ffffffffc0202b5a:	97ba                	add	a5,a5,a4
ffffffffc0202b5c:	953e                	add	a0,a0,a5
ffffffffc0202b5e:	100027f3          	csrr	a5,sstatus
ffffffffc0202b62:	8b89                	andi	a5,a5,2
ffffffffc0202b64:	2c079463          	bnez	a5,ffffffffc0202e2c <pmm_init+0x662>
ffffffffc0202b68:	000b3783          	ld	a5,0(s6)
ffffffffc0202b6c:	4585                	li	a1,1
ffffffffc0202b6e:	739c                	ld	a5,32(a5)
ffffffffc0202b70:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202b72:	00093783          	ld	a5,0(s2)
ffffffffc0202b76:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd59138>
    asm volatile("sfence.vma");
ffffffffc0202b7a:	12000073          	sfence.vma
ffffffffc0202b7e:	100027f3          	csrr	a5,sstatus
ffffffffc0202b82:	8b89                	andi	a5,a5,2
ffffffffc0202b84:	28079a63          	bnez	a5,ffffffffc0202e18 <pmm_init+0x64e>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b88:	000b3783          	ld	a5,0(s6)
ffffffffc0202b8c:	779c                	ld	a5,40(a5)
ffffffffc0202b8e:	9782                	jalr	a5
ffffffffc0202b90:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202b92:	4d441063          	bne	s0,s4,ffffffffc0203052 <pmm_init+0x888>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202b96:	00004517          	auipc	a0,0x4
ffffffffc0202b9a:	1ba50513          	addi	a0,a0,442 # ffffffffc0206d50 <etext+0x1296>
ffffffffc0202b9e:	df6fd0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0202ba2:	100027f3          	csrr	a5,sstatus
ffffffffc0202ba6:	8b89                	andi	a5,a5,2
ffffffffc0202ba8:	24079e63          	bnez	a5,ffffffffc0202e04 <pmm_init+0x63a>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202bac:	000b3783          	ld	a5,0(s6)
ffffffffc0202bb0:	779c                	ld	a5,40(a5)
ffffffffc0202bb2:	9782                	jalr	a5
ffffffffc0202bb4:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202bb6:	609c                	ld	a5,0(s1)
ffffffffc0202bb8:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202bbc:	7a7d                	lui	s4,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202bbe:	00c79713          	slli	a4,a5,0xc
ffffffffc0202bc2:	6a85                	lui	s5,0x1
ffffffffc0202bc4:	02e47c63          	bgeu	s0,a4,ffffffffc0202bfc <pmm_init+0x432>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202bc8:	00c45713          	srli	a4,s0,0xc
ffffffffc0202bcc:	30f77063          	bgeu	a4,a5,ffffffffc0202ecc <pmm_init+0x702>
ffffffffc0202bd0:	0009b583          	ld	a1,0(s3)
ffffffffc0202bd4:	00093503          	ld	a0,0(s2)
ffffffffc0202bd8:	4601                	li	a2,0
ffffffffc0202bda:	95a2                	add	a1,a1,s0
ffffffffc0202bdc:	bc2ff0ef          	jal	ffffffffc0201f9e <get_pte>
ffffffffc0202be0:	32050363          	beqz	a0,ffffffffc0202f06 <pmm_init+0x73c>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202be4:	611c                	ld	a5,0(a0)
ffffffffc0202be6:	078a                	slli	a5,a5,0x2
ffffffffc0202be8:	0147f7b3          	and	a5,a5,s4
ffffffffc0202bec:	2e879d63          	bne	a5,s0,ffffffffc0202ee6 <pmm_init+0x71c>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202bf0:	609c                	ld	a5,0(s1)
ffffffffc0202bf2:	9456                	add	s0,s0,s5
ffffffffc0202bf4:	00c79713          	slli	a4,a5,0xc
ffffffffc0202bf8:	fce468e3          	bltu	s0,a4,ffffffffc0202bc8 <pmm_init+0x3fe>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202bfc:	00093783          	ld	a5,0(s2)
ffffffffc0202c00:	639c                	ld	a5,0(a5)
ffffffffc0202c02:	42079863          	bnez	a5,ffffffffc0203032 <pmm_init+0x868>
ffffffffc0202c06:	100027f3          	csrr	a5,sstatus
ffffffffc0202c0a:	8b89                	andi	a5,a5,2
ffffffffc0202c0c:	24079863          	bnez	a5,ffffffffc0202e5c <pmm_init+0x692>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202c10:	000b3783          	ld	a5,0(s6)
ffffffffc0202c14:	4505                	li	a0,1
ffffffffc0202c16:	6f9c                	ld	a5,24(a5)
ffffffffc0202c18:	9782                	jalr	a5
ffffffffc0202c1a:	842a                	mv	s0,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202c1c:	00093503          	ld	a0,0(s2)
ffffffffc0202c20:	4699                	li	a3,6
ffffffffc0202c22:	10000613          	li	a2,256
ffffffffc0202c26:	85a2                	mv	a1,s0
ffffffffc0202c28:	aadff0ef          	jal	ffffffffc02026d4 <page_insert>
ffffffffc0202c2c:	46051363          	bnez	a0,ffffffffc0203092 <pmm_init+0x8c8>
    assert(page_ref(p) == 1);
ffffffffc0202c30:	4018                	lw	a4,0(s0)
ffffffffc0202c32:	4785                	li	a5,1
ffffffffc0202c34:	42f71f63          	bne	a4,a5,ffffffffc0203072 <pmm_init+0x8a8>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202c38:	00093503          	ld	a0,0(s2)
ffffffffc0202c3c:	6605                	lui	a2,0x1
ffffffffc0202c3e:	10060613          	addi	a2,a2,256 # 1100 <_binary_obj___user_softint_out_size-0x7b08>
ffffffffc0202c42:	4699                	li	a3,6
ffffffffc0202c44:	85a2                	mv	a1,s0
ffffffffc0202c46:	a8fff0ef          	jal	ffffffffc02026d4 <page_insert>
ffffffffc0202c4a:	72051963          	bnez	a0,ffffffffc020337c <pmm_init+0xbb2>
    assert(page_ref(p) == 2);
ffffffffc0202c4e:	4018                	lw	a4,0(s0)
ffffffffc0202c50:	4789                	li	a5,2
ffffffffc0202c52:	70f71563          	bne	a4,a5,ffffffffc020335c <pmm_init+0xb92>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202c56:	00004597          	auipc	a1,0x4
ffffffffc0202c5a:	24258593          	addi	a1,a1,578 # ffffffffc0206e98 <etext+0x13de>
ffffffffc0202c5e:	10000513          	li	a0,256
ffffffffc0202c62:	5af020ef          	jal	ffffffffc0205a10 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202c66:	6585                	lui	a1,0x1
ffffffffc0202c68:	10058593          	addi	a1,a1,256 # 1100 <_binary_obj___user_softint_out_size-0x7b08>
ffffffffc0202c6c:	10000513          	li	a0,256
ffffffffc0202c70:	5b3020ef          	jal	ffffffffc0205a22 <strcmp>
ffffffffc0202c74:	6c051463          	bnez	a0,ffffffffc020333c <pmm_init+0xb72>
    return page - pages + nbase;
ffffffffc0202c78:	000bb683          	ld	a3,0(s7)
ffffffffc0202c7c:	000807b7          	lui	a5,0x80
    return KADDR(page2pa(page));
ffffffffc0202c80:	6098                	ld	a4,0(s1)
    return page - pages + nbase;
ffffffffc0202c82:	40d406b3          	sub	a3,s0,a3
ffffffffc0202c86:	8699                	srai	a3,a3,0x6
ffffffffc0202c88:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0202c8a:	00c69793          	slli	a5,a3,0xc
ffffffffc0202c8e:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c90:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202c92:	32e7f463          	bgeu	a5,a4,ffffffffc0202fba <pmm_init+0x7f0>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c96:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c9a:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c9e:	97b6                	add	a5,a5,a3
ffffffffc0202ca0:	10078023          	sb	zero,256(a5) # 80100 <_binary_obj___user_COW_out_size+0x75ce0>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202ca4:	539020ef          	jal	ffffffffc02059dc <strlen>
ffffffffc0202ca8:	66051a63          	bnez	a0,ffffffffc020331c <pmm_init+0xb52>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202cac:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202cb0:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cb2:	000a3783          	ld	a5,0(s4) # fffffffffffff000 <end+0x3fd59138>
ffffffffc0202cb6:	078a                	slli	a5,a5,0x2
ffffffffc0202cb8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202cba:	26e7f663          	bgeu	a5,a4,ffffffffc0202f26 <pmm_init+0x75c>
    return page2ppn(page) << PGSHIFT;
ffffffffc0202cbe:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202cc2:	2ee7fc63          	bgeu	a5,a4,ffffffffc0202fba <pmm_init+0x7f0>
ffffffffc0202cc6:	0009b783          	ld	a5,0(s3)
ffffffffc0202cca:	00f689b3          	add	s3,a3,a5
ffffffffc0202cce:	100027f3          	csrr	a5,sstatus
ffffffffc0202cd2:	8b89                	andi	a5,a5,2
ffffffffc0202cd4:	1e079163          	bnez	a5,ffffffffc0202eb6 <pmm_init+0x6ec>
        pmm_manager->free_pages(base, n);
ffffffffc0202cd8:	000b3783          	ld	a5,0(s6)
ffffffffc0202cdc:	8522                	mv	a0,s0
ffffffffc0202cde:	4585                	li	a1,1
ffffffffc0202ce0:	739c                	ld	a5,32(a5)
ffffffffc0202ce2:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ce4:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage)
ffffffffc0202ce8:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cea:	078a                	slli	a5,a5,0x2
ffffffffc0202cec:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202cee:	22e7fc63          	bgeu	a5,a4,ffffffffc0202f26 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202cf2:	000bb503          	ld	a0,0(s7)
ffffffffc0202cf6:	fe000737          	lui	a4,0xfe000
ffffffffc0202cfa:	079a                	slli	a5,a5,0x6
ffffffffc0202cfc:	97ba                	add	a5,a5,a4
ffffffffc0202cfe:	953e                	add	a0,a0,a5
ffffffffc0202d00:	100027f3          	csrr	a5,sstatus
ffffffffc0202d04:	8b89                	andi	a5,a5,2
ffffffffc0202d06:	18079c63          	bnez	a5,ffffffffc0202e9e <pmm_init+0x6d4>
ffffffffc0202d0a:	000b3783          	ld	a5,0(s6)
ffffffffc0202d0e:	4585                	li	a1,1
ffffffffc0202d10:	739c                	ld	a5,32(a5)
ffffffffc0202d12:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d14:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202d18:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d1a:	078a                	slli	a5,a5,0x2
ffffffffc0202d1c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202d1e:	20e7f463          	bgeu	a5,a4,ffffffffc0202f26 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202d22:	000bb503          	ld	a0,0(s7)
ffffffffc0202d26:	fe000737          	lui	a4,0xfe000
ffffffffc0202d2a:	079a                	slli	a5,a5,0x6
ffffffffc0202d2c:	97ba                	add	a5,a5,a4
ffffffffc0202d2e:	953e                	add	a0,a0,a5
ffffffffc0202d30:	100027f3          	csrr	a5,sstatus
ffffffffc0202d34:	8b89                	andi	a5,a5,2
ffffffffc0202d36:	14079863          	bnez	a5,ffffffffc0202e86 <pmm_init+0x6bc>
ffffffffc0202d3a:	000b3783          	ld	a5,0(s6)
ffffffffc0202d3e:	4585                	li	a1,1
ffffffffc0202d40:	739c                	ld	a5,32(a5)
ffffffffc0202d42:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202d44:	00093783          	ld	a5,0(s2)
ffffffffc0202d48:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202d4c:	12000073          	sfence.vma
ffffffffc0202d50:	100027f3          	csrr	a5,sstatus
ffffffffc0202d54:	8b89                	andi	a5,a5,2
ffffffffc0202d56:	10079e63          	bnez	a5,ffffffffc0202e72 <pmm_init+0x6a8>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d5a:	000b3783          	ld	a5,0(s6)
ffffffffc0202d5e:	779c                	ld	a5,40(a5)
ffffffffc0202d60:	9782                	jalr	a5
ffffffffc0202d62:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202d64:	1e8c1b63          	bne	s8,s0,ffffffffc0202f5a <pmm_init+0x790>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202d68:	00004517          	auipc	a0,0x4
ffffffffc0202d6c:	1a850513          	addi	a0,a0,424 # ffffffffc0206f10 <etext+0x1456>
ffffffffc0202d70:	c24fd0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc0202d74:	7406                	ld	s0,96(sp)
ffffffffc0202d76:	70a6                	ld	ra,104(sp)
ffffffffc0202d78:	64e6                	ld	s1,88(sp)
ffffffffc0202d7a:	6946                	ld	s2,80(sp)
ffffffffc0202d7c:	69a6                	ld	s3,72(sp)
ffffffffc0202d7e:	6a06                	ld	s4,64(sp)
ffffffffc0202d80:	7ae2                	ld	s5,56(sp)
ffffffffc0202d82:	7b42                	ld	s6,48(sp)
ffffffffc0202d84:	7ba2                	ld	s7,40(sp)
ffffffffc0202d86:	7c02                	ld	s8,32(sp)
ffffffffc0202d88:	6ce2                	ld	s9,24(sp)
ffffffffc0202d8a:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202d8c:	f85fe06f          	j	ffffffffc0201d10 <kmalloc_init>
    if (maxpa > KERNTOP)
ffffffffc0202d90:	853e                	mv	a0,a5
ffffffffc0202d92:	b4e1                	j	ffffffffc020285a <pmm_init+0x90>
        intr_disable();
ffffffffc0202d94:	b71fd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d98:	000b3783          	ld	a5,0(s6)
ffffffffc0202d9c:	4505                	li	a0,1
ffffffffc0202d9e:	6f9c                	ld	a5,24(a5)
ffffffffc0202da0:	9782                	jalr	a5
ffffffffc0202da2:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202da4:	b5bfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202da8:	be75                	j	ffffffffc0202964 <pmm_init+0x19a>
        intr_disable();
ffffffffc0202daa:	b5bfd0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202dae:	000b3783          	ld	a5,0(s6)
ffffffffc0202db2:	779c                	ld	a5,40(a5)
ffffffffc0202db4:	9782                	jalr	a5
ffffffffc0202db6:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202db8:	b47fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202dbc:	b6ad                	j	ffffffffc0202926 <pmm_init+0x15c>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202dbe:	6705                	lui	a4,0x1
ffffffffc0202dc0:	177d                	addi	a4,a4,-1 # fff <_binary_obj___user_softint_out_size-0x7c09>
ffffffffc0202dc2:	96ba                	add	a3,a3,a4
ffffffffc0202dc4:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202dc6:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202dca:	14a77e63          	bgeu	a4,a0,ffffffffc0202f26 <pmm_init+0x75c>
    pmm_manager->init_memmap(base, n);
ffffffffc0202dce:	000b3683          	ld	a3,0(s6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202dd2:	8c1d                	sub	s0,s0,a5
    return &pages[PPN(pa) - nbase];
ffffffffc0202dd4:	071a                	slli	a4,a4,0x6
ffffffffc0202dd6:	fe0007b7          	lui	a5,0xfe000
ffffffffc0202dda:	973e                	add	a4,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc0202ddc:	6a9c                	ld	a5,16(a3)
ffffffffc0202dde:	00c45593          	srli	a1,s0,0xc
ffffffffc0202de2:	00e60533          	add	a0,a2,a4
ffffffffc0202de6:	9782                	jalr	a5
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202de8:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202dec:	bcf1                	j	ffffffffc02028c8 <pmm_init+0xfe>
        intr_disable();
ffffffffc0202dee:	b17fd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202df2:	000b3783          	ld	a5,0(s6)
ffffffffc0202df6:	4505                	li	a0,1
ffffffffc0202df8:	6f9c                	ld	a5,24(a5)
ffffffffc0202dfa:	9782                	jalr	a5
ffffffffc0202dfc:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202dfe:	b01fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e02:	b119                	j	ffffffffc0202a08 <pmm_init+0x23e>
        intr_disable();
ffffffffc0202e04:	b01fd0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e08:	000b3783          	ld	a5,0(s6)
ffffffffc0202e0c:	779c                	ld	a5,40(a5)
ffffffffc0202e0e:	9782                	jalr	a5
ffffffffc0202e10:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202e12:	aedfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e16:	b345                	j	ffffffffc0202bb6 <pmm_init+0x3ec>
        intr_disable();
ffffffffc0202e18:	aedfd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202e1c:	000b3783          	ld	a5,0(s6)
ffffffffc0202e20:	779c                	ld	a5,40(a5)
ffffffffc0202e22:	9782                	jalr	a5
ffffffffc0202e24:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202e26:	ad9fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e2a:	b3a5                	j	ffffffffc0202b92 <pmm_init+0x3c8>
ffffffffc0202e2c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e2e:	ad7fd0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202e32:	000b3783          	ld	a5,0(s6)
ffffffffc0202e36:	6522                	ld	a0,8(sp)
ffffffffc0202e38:	4585                	li	a1,1
ffffffffc0202e3a:	739c                	ld	a5,32(a5)
ffffffffc0202e3c:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e3e:	ac1fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e42:	bb05                	j	ffffffffc0202b72 <pmm_init+0x3a8>
ffffffffc0202e44:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e46:	abffd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202e4a:	000b3783          	ld	a5,0(s6)
ffffffffc0202e4e:	6522                	ld	a0,8(sp)
ffffffffc0202e50:	4585                	li	a1,1
ffffffffc0202e52:	739c                	ld	a5,32(a5)
ffffffffc0202e54:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e56:	aa9fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e5a:	b1e5                	j	ffffffffc0202b42 <pmm_init+0x378>
        intr_disable();
ffffffffc0202e5c:	aa9fd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202e60:	000b3783          	ld	a5,0(s6)
ffffffffc0202e64:	4505                	li	a0,1
ffffffffc0202e66:	6f9c                	ld	a5,24(a5)
ffffffffc0202e68:	9782                	jalr	a5
ffffffffc0202e6a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e6c:	a93fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e70:	b375                	j	ffffffffc0202c1c <pmm_init+0x452>
        intr_disable();
ffffffffc0202e72:	a93fd0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e76:	000b3783          	ld	a5,0(s6)
ffffffffc0202e7a:	779c                	ld	a5,40(a5)
ffffffffc0202e7c:	9782                	jalr	a5
ffffffffc0202e7e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e80:	a7ffd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e84:	b5c5                	j	ffffffffc0202d64 <pmm_init+0x59a>
ffffffffc0202e86:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e88:	a7dfd0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202e8c:	000b3783          	ld	a5,0(s6)
ffffffffc0202e90:	6522                	ld	a0,8(sp)
ffffffffc0202e92:	4585                	li	a1,1
ffffffffc0202e94:	739c                	ld	a5,32(a5)
ffffffffc0202e96:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e98:	a67fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e9c:	b565                	j	ffffffffc0202d44 <pmm_init+0x57a>
ffffffffc0202e9e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202ea0:	a65fd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202ea4:	000b3783          	ld	a5,0(s6)
ffffffffc0202ea8:	6522                	ld	a0,8(sp)
ffffffffc0202eaa:	4585                	li	a1,1
ffffffffc0202eac:	739c                	ld	a5,32(a5)
ffffffffc0202eae:	9782                	jalr	a5
        intr_enable();
ffffffffc0202eb0:	a4ffd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202eb4:	b585                	j	ffffffffc0202d14 <pmm_init+0x54a>
        intr_disable();
ffffffffc0202eb6:	a4ffd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202eba:	000b3783          	ld	a5,0(s6)
ffffffffc0202ebe:	8522                	mv	a0,s0
ffffffffc0202ec0:	4585                	li	a1,1
ffffffffc0202ec2:	739c                	ld	a5,32(a5)
ffffffffc0202ec4:	9782                	jalr	a5
        intr_enable();
ffffffffc0202ec6:	a39fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202eca:	bd29                	j	ffffffffc0202ce4 <pmm_init+0x51a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202ecc:	86a2                	mv	a3,s0
ffffffffc0202ece:	00004617          	auipc	a2,0x4
ffffffffc0202ed2:	95a60613          	addi	a2,a2,-1702 # ffffffffc0206828 <etext+0xd6e>
ffffffffc0202ed6:	24000593          	li	a1,576
ffffffffc0202eda:	00004517          	auipc	a0,0x4
ffffffffc0202ede:	a3e50513          	addi	a0,a0,-1474 # ffffffffc0206918 <etext+0xe5e>
ffffffffc0202ee2:	d64fd0ef          	jal	ffffffffc0200446 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202ee6:	00004697          	auipc	a3,0x4
ffffffffc0202eea:	eca68693          	addi	a3,a3,-310 # ffffffffc0206db0 <etext+0x12f6>
ffffffffc0202eee:	00003617          	auipc	a2,0x3
ffffffffc0202ef2:	37a60613          	addi	a2,a2,890 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0202ef6:	24100593          	li	a1,577
ffffffffc0202efa:	00004517          	auipc	a0,0x4
ffffffffc0202efe:	a1e50513          	addi	a0,a0,-1506 # ffffffffc0206918 <etext+0xe5e>
ffffffffc0202f02:	d44fd0ef          	jal	ffffffffc0200446 <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202f06:	00004697          	auipc	a3,0x4
ffffffffc0202f0a:	e6a68693          	addi	a3,a3,-406 # ffffffffc0206d70 <etext+0x12b6>
ffffffffc0202f0e:	00003617          	auipc	a2,0x3
ffffffffc0202f12:	35a60613          	addi	a2,a2,858 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0202f16:	24000593          	li	a1,576
ffffffffc0202f1a:	00004517          	auipc	a0,0x4
ffffffffc0202f1e:	9fe50513          	addi	a0,a0,-1538 # ffffffffc0206918 <etext+0xe5e>
ffffffffc0202f22:	d24fd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0202f26:	fb5fe0ef          	jal	ffffffffc0201eda <pa2page.part.0>
        panic("pte2page called with invalid pte");
ffffffffc0202f2a:	00004617          	auipc	a2,0x4
ffffffffc0202f2e:	be660613          	addi	a2,a2,-1050 # ffffffffc0206b10 <etext+0x1056>
ffffffffc0202f32:	07f00593          	li	a1,127
ffffffffc0202f36:	00004517          	auipc	a0,0x4
ffffffffc0202f3a:	91a50513          	addi	a0,a0,-1766 # ffffffffc0206850 <etext+0xd96>
ffffffffc0202f3e:	d08fd0ef          	jal	ffffffffc0200446 <__panic>
        panic("DTB memory info not available");
ffffffffc0202f42:	00004617          	auipc	a2,0x4
ffffffffc0202f46:	a4660613          	addi	a2,a2,-1466 # ffffffffc0206988 <etext+0xece>
ffffffffc0202f4a:	06500593          	li	a1,101
ffffffffc0202f4e:	00004517          	auipc	a0,0x4
ffffffffc0202f52:	9ca50513          	addi	a0,a0,-1590 # ffffffffc0206918 <etext+0xe5e>
ffffffffc0202f56:	cf0fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202f5a:	00004697          	auipc	a3,0x4
ffffffffc0202f5e:	dce68693          	addi	a3,a3,-562 # ffffffffc0206d28 <etext+0x126e>
ffffffffc0202f62:	00003617          	auipc	a2,0x3
ffffffffc0202f66:	30660613          	addi	a2,a2,774 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0202f6a:	25b00593          	li	a1,603
ffffffffc0202f6e:	00004517          	auipc	a0,0x4
ffffffffc0202f72:	9aa50513          	addi	a0,a0,-1622 # ffffffffc0206918 <etext+0xe5e>
ffffffffc0202f76:	cd0fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202f7a:	00004697          	auipc	a3,0x4
ffffffffc0202f7e:	ac668693          	addi	a3,a3,-1338 # ffffffffc0206a40 <etext+0xf86>
ffffffffc0202f82:	00003617          	auipc	a2,0x3
ffffffffc0202f86:	2e660613          	addi	a2,a2,742 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0202f8a:	20200593          	li	a1,514
ffffffffc0202f8e:	00004517          	auipc	a0,0x4
ffffffffc0202f92:	98a50513          	addi	a0,a0,-1654 # ffffffffc0206918 <etext+0xe5e>
ffffffffc0202f96:	cb0fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202f9a:	00004697          	auipc	a3,0x4
ffffffffc0202f9e:	a8668693          	addi	a3,a3,-1402 # ffffffffc0206a20 <etext+0xf66>
ffffffffc0202fa2:	00003617          	auipc	a2,0x3
ffffffffc0202fa6:	2c660613          	addi	a2,a2,710 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0202faa:	20100593          	li	a1,513
ffffffffc0202fae:	00004517          	auipc	a0,0x4
ffffffffc0202fb2:	96a50513          	addi	a0,a0,-1686 # ffffffffc0206918 <etext+0xe5e>
ffffffffc0202fb6:	c90fd0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202fba:	00004617          	auipc	a2,0x4
ffffffffc0202fbe:	86e60613          	addi	a2,a2,-1938 # ffffffffc0206828 <etext+0xd6e>
ffffffffc0202fc2:	07100593          	li	a1,113
ffffffffc0202fc6:	00004517          	auipc	a0,0x4
ffffffffc0202fca:	88a50513          	addi	a0,a0,-1910 # ffffffffc0206850 <etext+0xd96>
ffffffffc0202fce:	c78fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202fd2:	00004697          	auipc	a3,0x4
ffffffffc0202fd6:	d2668693          	addi	a3,a3,-730 # ffffffffc0206cf8 <etext+0x123e>
ffffffffc0202fda:	00003617          	auipc	a2,0x3
ffffffffc0202fde:	28e60613          	addi	a2,a2,654 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0202fe2:	22900593          	li	a1,553
ffffffffc0202fe6:	00004517          	auipc	a0,0x4
ffffffffc0202fea:	93250513          	addi	a0,a0,-1742 # ffffffffc0206918 <etext+0xe5e>
ffffffffc0202fee:	c58fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202ff2:	00004697          	auipc	a3,0x4
ffffffffc0202ff6:	cbe68693          	addi	a3,a3,-834 # ffffffffc0206cb0 <etext+0x11f6>
ffffffffc0202ffa:	00003617          	auipc	a2,0x3
ffffffffc0202ffe:	26e60613          	addi	a2,a2,622 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203002:	22700593          	li	a1,551
ffffffffc0203006:	00004517          	auipc	a0,0x4
ffffffffc020300a:	91250513          	addi	a0,a0,-1774 # ffffffffc0206918 <etext+0xe5e>
ffffffffc020300e:	c38fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0203012:	00004697          	auipc	a3,0x4
ffffffffc0203016:	cce68693          	addi	a3,a3,-818 # ffffffffc0206ce0 <etext+0x1226>
ffffffffc020301a:	00003617          	auipc	a2,0x3
ffffffffc020301e:	24e60613          	addi	a2,a2,590 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203022:	22600593          	li	a1,550
ffffffffc0203026:	00004517          	auipc	a0,0x4
ffffffffc020302a:	8f250513          	addi	a0,a0,-1806 # ffffffffc0206918 <etext+0xe5e>
ffffffffc020302e:	c18fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0203032:	00004697          	auipc	a3,0x4
ffffffffc0203036:	d9668693          	addi	a3,a3,-618 # ffffffffc0206dc8 <etext+0x130e>
ffffffffc020303a:	00003617          	auipc	a2,0x3
ffffffffc020303e:	22e60613          	addi	a2,a2,558 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203042:	24400593          	li	a1,580
ffffffffc0203046:	00004517          	auipc	a0,0x4
ffffffffc020304a:	8d250513          	addi	a0,a0,-1838 # ffffffffc0206918 <etext+0xe5e>
ffffffffc020304e:	bf8fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0203052:	00004697          	auipc	a3,0x4
ffffffffc0203056:	cd668693          	addi	a3,a3,-810 # ffffffffc0206d28 <etext+0x126e>
ffffffffc020305a:	00003617          	auipc	a2,0x3
ffffffffc020305e:	20e60613          	addi	a2,a2,526 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203062:	23100593          	li	a1,561
ffffffffc0203066:	00004517          	auipc	a0,0x4
ffffffffc020306a:	8b250513          	addi	a0,a0,-1870 # ffffffffc0206918 <etext+0xe5e>
ffffffffc020306e:	bd8fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0203072:	00004697          	auipc	a3,0x4
ffffffffc0203076:	dae68693          	addi	a3,a3,-594 # ffffffffc0206e20 <etext+0x1366>
ffffffffc020307a:	00003617          	auipc	a2,0x3
ffffffffc020307e:	1ee60613          	addi	a2,a2,494 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203082:	24900593          	li	a1,585
ffffffffc0203086:	00004517          	auipc	a0,0x4
ffffffffc020308a:	89250513          	addi	a0,a0,-1902 # ffffffffc0206918 <etext+0xe5e>
ffffffffc020308e:	bb8fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0203092:	00004697          	auipc	a3,0x4
ffffffffc0203096:	d4e68693          	addi	a3,a3,-690 # ffffffffc0206de0 <etext+0x1326>
ffffffffc020309a:	00003617          	auipc	a2,0x3
ffffffffc020309e:	1ce60613          	addi	a2,a2,462 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02030a2:	24800593          	li	a1,584
ffffffffc02030a6:	00004517          	auipc	a0,0x4
ffffffffc02030aa:	87250513          	addi	a0,a0,-1934 # ffffffffc0206918 <etext+0xe5e>
ffffffffc02030ae:	b98fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02030b2:	00004697          	auipc	a3,0x4
ffffffffc02030b6:	bfe68693          	addi	a3,a3,-1026 # ffffffffc0206cb0 <etext+0x11f6>
ffffffffc02030ba:	00003617          	auipc	a2,0x3
ffffffffc02030be:	1ae60613          	addi	a2,a2,430 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02030c2:	22300593          	li	a1,547
ffffffffc02030c6:	00004517          	auipc	a0,0x4
ffffffffc02030ca:	85250513          	addi	a0,a0,-1966 # ffffffffc0206918 <etext+0xe5e>
ffffffffc02030ce:	b78fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02030d2:	00004697          	auipc	a3,0x4
ffffffffc02030d6:	a7e68693          	addi	a3,a3,-1410 # ffffffffc0206b50 <etext+0x1096>
ffffffffc02030da:	00003617          	auipc	a2,0x3
ffffffffc02030de:	18e60613          	addi	a2,a2,398 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02030e2:	22200593          	li	a1,546
ffffffffc02030e6:	00004517          	auipc	a0,0x4
ffffffffc02030ea:	83250513          	addi	a0,a0,-1998 # ffffffffc0206918 <etext+0xe5e>
ffffffffc02030ee:	b58fd0ef          	jal	ffffffffc0200446 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc02030f2:	00004697          	auipc	a3,0x4
ffffffffc02030f6:	bd668693          	addi	a3,a3,-1066 # ffffffffc0206cc8 <etext+0x120e>
ffffffffc02030fa:	00003617          	auipc	a2,0x3
ffffffffc02030fe:	16e60613          	addi	a2,a2,366 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203102:	21f00593          	li	a1,543
ffffffffc0203106:	00004517          	auipc	a0,0x4
ffffffffc020310a:	81250513          	addi	a0,a0,-2030 # ffffffffc0206918 <etext+0xe5e>
ffffffffc020310e:	b38fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203112:	00004697          	auipc	a3,0x4
ffffffffc0203116:	a2668693          	addi	a3,a3,-1498 # ffffffffc0206b38 <etext+0x107e>
ffffffffc020311a:	00003617          	auipc	a2,0x3
ffffffffc020311e:	14e60613          	addi	a2,a2,334 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203122:	21e00593          	li	a1,542
ffffffffc0203126:	00003517          	auipc	a0,0x3
ffffffffc020312a:	7f250513          	addi	a0,a0,2034 # ffffffffc0206918 <etext+0xe5e>
ffffffffc020312e:	b18fd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203132:	00004697          	auipc	a3,0x4
ffffffffc0203136:	aa668693          	addi	a3,a3,-1370 # ffffffffc0206bd8 <etext+0x111e>
ffffffffc020313a:	00003617          	auipc	a2,0x3
ffffffffc020313e:	12e60613          	addi	a2,a2,302 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203142:	21d00593          	li	a1,541
ffffffffc0203146:	00003517          	auipc	a0,0x3
ffffffffc020314a:	7d250513          	addi	a0,a0,2002 # ffffffffc0206918 <etext+0xe5e>
ffffffffc020314e:	af8fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203152:	00004697          	auipc	a3,0x4
ffffffffc0203156:	b5e68693          	addi	a3,a3,-1186 # ffffffffc0206cb0 <etext+0x11f6>
ffffffffc020315a:	00003617          	auipc	a2,0x3
ffffffffc020315e:	10e60613          	addi	a2,a2,270 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203162:	21c00593          	li	a1,540
ffffffffc0203166:	00003517          	auipc	a0,0x3
ffffffffc020316a:	7b250513          	addi	a0,a0,1970 # ffffffffc0206918 <etext+0xe5e>
ffffffffc020316e:	ad8fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0203172:	00004697          	auipc	a3,0x4
ffffffffc0203176:	b2668693          	addi	a3,a3,-1242 # ffffffffc0206c98 <etext+0x11de>
ffffffffc020317a:	00003617          	auipc	a2,0x3
ffffffffc020317e:	0ee60613          	addi	a2,a2,238 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203182:	21b00593          	li	a1,539
ffffffffc0203186:	00003517          	auipc	a0,0x3
ffffffffc020318a:	79250513          	addi	a0,a0,1938 # ffffffffc0206918 <etext+0xe5e>
ffffffffc020318e:	ab8fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0203192:	00004697          	auipc	a3,0x4
ffffffffc0203196:	ad668693          	addi	a3,a3,-1322 # ffffffffc0206c68 <etext+0x11ae>
ffffffffc020319a:	00003617          	auipc	a2,0x3
ffffffffc020319e:	0ce60613          	addi	a2,a2,206 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02031a2:	21a00593          	li	a1,538
ffffffffc02031a6:	00003517          	auipc	a0,0x3
ffffffffc02031aa:	77250513          	addi	a0,a0,1906 # ffffffffc0206918 <etext+0xe5e>
ffffffffc02031ae:	a98fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc02031b2:	00004697          	auipc	a3,0x4
ffffffffc02031b6:	a9e68693          	addi	a3,a3,-1378 # ffffffffc0206c50 <etext+0x1196>
ffffffffc02031ba:	00003617          	auipc	a2,0x3
ffffffffc02031be:	0ae60613          	addi	a2,a2,174 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02031c2:	21800593          	li	a1,536
ffffffffc02031c6:	00003517          	auipc	a0,0x3
ffffffffc02031ca:	75250513          	addi	a0,a0,1874 # ffffffffc0206918 <etext+0xe5e>
ffffffffc02031ce:	a78fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02031d2:	00004697          	auipc	a3,0x4
ffffffffc02031d6:	a5e68693          	addi	a3,a3,-1442 # ffffffffc0206c30 <etext+0x1176>
ffffffffc02031da:	00003617          	auipc	a2,0x3
ffffffffc02031de:	08e60613          	addi	a2,a2,142 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02031e2:	21700593          	li	a1,535
ffffffffc02031e6:	00003517          	auipc	a0,0x3
ffffffffc02031ea:	73250513          	addi	a0,a0,1842 # ffffffffc0206918 <etext+0xe5e>
ffffffffc02031ee:	a58fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(*ptep & PTE_W);
ffffffffc02031f2:	00004697          	auipc	a3,0x4
ffffffffc02031f6:	a2e68693          	addi	a3,a3,-1490 # ffffffffc0206c20 <etext+0x1166>
ffffffffc02031fa:	00003617          	auipc	a2,0x3
ffffffffc02031fe:	06e60613          	addi	a2,a2,110 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203202:	21600593          	li	a1,534
ffffffffc0203206:	00003517          	auipc	a0,0x3
ffffffffc020320a:	71250513          	addi	a0,a0,1810 # ffffffffc0206918 <etext+0xe5e>
ffffffffc020320e:	a38fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0203212:	00004697          	auipc	a3,0x4
ffffffffc0203216:	9fe68693          	addi	a3,a3,-1538 # ffffffffc0206c10 <etext+0x1156>
ffffffffc020321a:	00003617          	auipc	a2,0x3
ffffffffc020321e:	04e60613          	addi	a2,a2,78 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203222:	21500593          	li	a1,533
ffffffffc0203226:	00003517          	auipc	a0,0x3
ffffffffc020322a:	6f250513          	addi	a0,a0,1778 # ffffffffc0206918 <etext+0xe5e>
ffffffffc020322e:	a18fd0ef          	jal	ffffffffc0200446 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0203232:	00003617          	auipc	a2,0x3
ffffffffc0203236:	69e60613          	addi	a2,a2,1694 # ffffffffc02068d0 <etext+0xe16>
ffffffffc020323a:	08100593          	li	a1,129
ffffffffc020323e:	00003517          	auipc	a0,0x3
ffffffffc0203242:	6da50513          	addi	a0,a0,1754 # ffffffffc0206918 <etext+0xe5e>
ffffffffc0203246:	a00fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020324a:	00004697          	auipc	a3,0x4
ffffffffc020324e:	91e68693          	addi	a3,a3,-1762 # ffffffffc0206b68 <etext+0x10ae>
ffffffffc0203252:	00003617          	auipc	a2,0x3
ffffffffc0203256:	01660613          	addi	a2,a2,22 # ffffffffc0206268 <etext+0x7ae>
ffffffffc020325a:	21000593          	li	a1,528
ffffffffc020325e:	00003517          	auipc	a0,0x3
ffffffffc0203262:	6ba50513          	addi	a0,a0,1722 # ffffffffc0206918 <etext+0xe5e>
ffffffffc0203266:	9e0fd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020326a:	00004697          	auipc	a3,0x4
ffffffffc020326e:	96e68693          	addi	a3,a3,-1682 # ffffffffc0206bd8 <etext+0x111e>
ffffffffc0203272:	00003617          	auipc	a2,0x3
ffffffffc0203276:	ff660613          	addi	a2,a2,-10 # ffffffffc0206268 <etext+0x7ae>
ffffffffc020327a:	21400593          	li	a1,532
ffffffffc020327e:	00003517          	auipc	a0,0x3
ffffffffc0203282:	69a50513          	addi	a0,a0,1690 # ffffffffc0206918 <etext+0xe5e>
ffffffffc0203286:	9c0fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc020328a:	00004697          	auipc	a3,0x4
ffffffffc020328e:	90e68693          	addi	a3,a3,-1778 # ffffffffc0206b98 <etext+0x10de>
ffffffffc0203292:	00003617          	auipc	a2,0x3
ffffffffc0203296:	fd660613          	addi	a2,a2,-42 # ffffffffc0206268 <etext+0x7ae>
ffffffffc020329a:	21300593          	li	a1,531
ffffffffc020329e:	00003517          	auipc	a0,0x3
ffffffffc02032a2:	67a50513          	addi	a0,a0,1658 # ffffffffc0206918 <etext+0xe5e>
ffffffffc02032a6:	9a0fd0ef          	jal	ffffffffc0200446 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02032aa:	86d6                	mv	a3,s5
ffffffffc02032ac:	00003617          	auipc	a2,0x3
ffffffffc02032b0:	57c60613          	addi	a2,a2,1404 # ffffffffc0206828 <etext+0xd6e>
ffffffffc02032b4:	20f00593          	li	a1,527
ffffffffc02032b8:	00003517          	auipc	a0,0x3
ffffffffc02032bc:	66050513          	addi	a0,a0,1632 # ffffffffc0206918 <etext+0xe5e>
ffffffffc02032c0:	986fd0ef          	jal	ffffffffc0200446 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02032c4:	00003617          	auipc	a2,0x3
ffffffffc02032c8:	56460613          	addi	a2,a2,1380 # ffffffffc0206828 <etext+0xd6e>
ffffffffc02032cc:	20e00593          	li	a1,526
ffffffffc02032d0:	00003517          	auipc	a0,0x3
ffffffffc02032d4:	64850513          	addi	a0,a0,1608 # ffffffffc0206918 <etext+0xe5e>
ffffffffc02032d8:	96efd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02032dc:	00004697          	auipc	a3,0x4
ffffffffc02032e0:	87468693          	addi	a3,a3,-1932 # ffffffffc0206b50 <etext+0x1096>
ffffffffc02032e4:	00003617          	auipc	a2,0x3
ffffffffc02032e8:	f8460613          	addi	a2,a2,-124 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02032ec:	20c00593          	li	a1,524
ffffffffc02032f0:	00003517          	auipc	a0,0x3
ffffffffc02032f4:	62850513          	addi	a0,a0,1576 # ffffffffc0206918 <etext+0xe5e>
ffffffffc02032f8:	94efd0ef          	jal	ffffffffc0200446 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02032fc:	00004697          	auipc	a3,0x4
ffffffffc0203300:	83c68693          	addi	a3,a3,-1988 # ffffffffc0206b38 <etext+0x107e>
ffffffffc0203304:	00003617          	auipc	a2,0x3
ffffffffc0203308:	f6460613          	addi	a2,a2,-156 # ffffffffc0206268 <etext+0x7ae>
ffffffffc020330c:	20b00593          	li	a1,523
ffffffffc0203310:	00003517          	auipc	a0,0x3
ffffffffc0203314:	60850513          	addi	a0,a0,1544 # ffffffffc0206918 <etext+0xe5e>
ffffffffc0203318:	92efd0ef          	jal	ffffffffc0200446 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020331c:	00004697          	auipc	a3,0x4
ffffffffc0203320:	bcc68693          	addi	a3,a3,-1076 # ffffffffc0206ee8 <etext+0x142e>
ffffffffc0203324:	00003617          	auipc	a2,0x3
ffffffffc0203328:	f4460613          	addi	a2,a2,-188 # ffffffffc0206268 <etext+0x7ae>
ffffffffc020332c:	25200593          	li	a1,594
ffffffffc0203330:	00003517          	auipc	a0,0x3
ffffffffc0203334:	5e850513          	addi	a0,a0,1512 # ffffffffc0206918 <etext+0xe5e>
ffffffffc0203338:	90efd0ef          	jal	ffffffffc0200446 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020333c:	00004697          	auipc	a3,0x4
ffffffffc0203340:	b7468693          	addi	a3,a3,-1164 # ffffffffc0206eb0 <etext+0x13f6>
ffffffffc0203344:	00003617          	auipc	a2,0x3
ffffffffc0203348:	f2460613          	addi	a2,a2,-220 # ffffffffc0206268 <etext+0x7ae>
ffffffffc020334c:	24f00593          	li	a1,591
ffffffffc0203350:	00003517          	auipc	a0,0x3
ffffffffc0203354:	5c850513          	addi	a0,a0,1480 # ffffffffc0206918 <etext+0xe5e>
ffffffffc0203358:	8eefd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p) == 2);
ffffffffc020335c:	00004697          	auipc	a3,0x4
ffffffffc0203360:	b2468693          	addi	a3,a3,-1244 # ffffffffc0206e80 <etext+0x13c6>
ffffffffc0203364:	00003617          	auipc	a2,0x3
ffffffffc0203368:	f0460613          	addi	a2,a2,-252 # ffffffffc0206268 <etext+0x7ae>
ffffffffc020336c:	24b00593          	li	a1,587
ffffffffc0203370:	00003517          	auipc	a0,0x3
ffffffffc0203374:	5a850513          	addi	a0,a0,1448 # ffffffffc0206918 <etext+0xe5e>
ffffffffc0203378:	8cefd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020337c:	00004697          	auipc	a3,0x4
ffffffffc0203380:	abc68693          	addi	a3,a3,-1348 # ffffffffc0206e38 <etext+0x137e>
ffffffffc0203384:	00003617          	auipc	a2,0x3
ffffffffc0203388:	ee460613          	addi	a2,a2,-284 # ffffffffc0206268 <etext+0x7ae>
ffffffffc020338c:	24a00593          	li	a1,586
ffffffffc0203390:	00003517          	auipc	a0,0x3
ffffffffc0203394:	58850513          	addi	a0,a0,1416 # ffffffffc0206918 <etext+0xe5e>
ffffffffc0203398:	8aefd0ef          	jal	ffffffffc0200446 <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc020339c:	00003697          	auipc	a3,0x3
ffffffffc02033a0:	6e468693          	addi	a3,a3,1764 # ffffffffc0206a80 <etext+0xfc6>
ffffffffc02033a4:	00003617          	auipc	a2,0x3
ffffffffc02033a8:	ec460613          	addi	a2,a2,-316 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02033ac:	20300593          	li	a1,515
ffffffffc02033b0:	00003517          	auipc	a0,0x3
ffffffffc02033b4:	56850513          	addi	a0,a0,1384 # ffffffffc0206918 <etext+0xe5e>
ffffffffc02033b8:	88efd0ef          	jal	ffffffffc0200446 <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02033bc:	00003617          	auipc	a2,0x3
ffffffffc02033c0:	51460613          	addi	a2,a2,1300 # ffffffffc02068d0 <etext+0xe16>
ffffffffc02033c4:	0c900593          	li	a1,201
ffffffffc02033c8:	00003517          	auipc	a0,0x3
ffffffffc02033cc:	55050513          	addi	a0,a0,1360 # ffffffffc0206918 <etext+0xe5e>
ffffffffc02033d0:	876fd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02033d4:	00003697          	auipc	a3,0x3
ffffffffc02033d8:	70c68693          	addi	a3,a3,1804 # ffffffffc0206ae0 <etext+0x1026>
ffffffffc02033dc:	00003617          	auipc	a2,0x3
ffffffffc02033e0:	e8c60613          	addi	a2,a2,-372 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02033e4:	20a00593          	li	a1,522
ffffffffc02033e8:	00003517          	auipc	a0,0x3
ffffffffc02033ec:	53050513          	addi	a0,a0,1328 # ffffffffc0206918 <etext+0xe5e>
ffffffffc02033f0:	856fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02033f4:	00003697          	auipc	a3,0x3
ffffffffc02033f8:	6bc68693          	addi	a3,a3,1724 # ffffffffc0206ab0 <etext+0xff6>
ffffffffc02033fc:	00003617          	auipc	a2,0x3
ffffffffc0203400:	e6c60613          	addi	a2,a2,-404 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203404:	20700593          	li	a1,519
ffffffffc0203408:	00003517          	auipc	a0,0x3
ffffffffc020340c:	51050513          	addi	a0,a0,1296 # ffffffffc0206918 <etext+0xe5e>
ffffffffc0203410:	836fd0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203414 <copy_range>:
int copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end, bool share) {
ffffffffc0203414:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203416:	00d667b3          	or	a5,a2,a3
int copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end, bool share) {
ffffffffc020341a:	f862                	sd	s8,48(sp)
ffffffffc020341c:	fc86                	sd	ra,120(sp)
ffffffffc020341e:	8c3a                	mv	s8,a4
ffffffffc0203420:	f8a2                	sd	s0,112(sp)
ffffffffc0203422:	f4a6                	sd	s1,104(sp)
ffffffffc0203424:	f0ca                	sd	s2,96(sp)
ffffffffc0203426:	ecce                	sd	s3,88(sp)
ffffffffc0203428:	e8d2                	sd	s4,80(sp)
ffffffffc020342a:	e4d6                	sd	s5,72(sp)
ffffffffc020342c:	e0da                	sd	s6,64(sp)
ffffffffc020342e:	fc5e                	sd	s7,56(sp)
ffffffffc0203430:	f466                	sd	s9,40(sp)
ffffffffc0203432:	f06a                	sd	s10,32(sp)
ffffffffc0203434:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203436:	03479713          	slli	a4,a5,0x34
ffffffffc020343a:	1e071863          	bnez	a4,ffffffffc020362a <copy_range+0x216>
    assert(USER_ACCESS(start, end));
ffffffffc020343e:	002007b7          	lui	a5,0x200
ffffffffc0203442:	00d63733          	sltu	a4,a2,a3
ffffffffc0203446:	00f637b3          	sltu	a5,a2,a5
ffffffffc020344a:	00173713          	seqz	a4,a4
ffffffffc020344e:	8fd9                	or	a5,a5,a4
ffffffffc0203450:	8432                	mv	s0,a2
ffffffffc0203452:	84b6                	mv	s1,a3
ffffffffc0203454:	1a079b63          	bnez	a5,ffffffffc020360a <copy_range+0x1f6>
ffffffffc0203458:	4785                	li	a5,1
ffffffffc020345a:	07fe                	slli	a5,a5,0x1f
ffffffffc020345c:	0785                	addi	a5,a5,1 # 200001 <_binary_obj___user_COW_out_size+0x1f5be1>
ffffffffc020345e:	1af6f663          	bgeu	a3,a5,ffffffffc020360a <copy_range+0x1f6>
ffffffffc0203462:	5cfd                	li	s9,-1
ffffffffc0203464:	8a2a                	mv	s4,a0
ffffffffc0203466:	892e                	mv	s2,a1
ffffffffc0203468:	6985                	lui	s3,0x1
ffffffffc020346a:	00ccdc93          	srli	s9,s9,0xc
    if (PPN(pa) >= npage)
ffffffffc020346e:	000a3b17          	auipc	s6,0xa3
ffffffffc0203472:	a22b0b13          	addi	s6,s6,-1502 # ffffffffc02a5e90 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203476:	000a3a97          	auipc	s5,0xa3
ffffffffc020347a:	a22a8a93          	addi	s5,s5,-1502 # ffffffffc02a5e98 <pages>
ffffffffc020347e:	fff80bb7          	lui	s7,0xfff80
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc0203482:	4601                	li	a2,0
ffffffffc0203484:	85a2                	mv	a1,s0
ffffffffc0203486:	854a                	mv	a0,s2
ffffffffc0203488:	b17fe0ef          	jal	ffffffffc0201f9e <get_pte>
ffffffffc020348c:	8d2a                	mv	s10,a0
        if (ptep == NULL) {
ffffffffc020348e:	c15d                	beqz	a0,ffffffffc0203534 <copy_range+0x120>
        if (*ptep & PTE_V) {
ffffffffc0203490:	611c                	ld	a5,0(a0)
ffffffffc0203492:	8b85                	andi	a5,a5,1
ffffffffc0203494:	e78d                	bnez	a5,ffffffffc02034be <copy_range+0xaa>
        start += PGSIZE;
ffffffffc0203496:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc0203498:	c019                	beqz	s0,ffffffffc020349e <copy_range+0x8a>
ffffffffc020349a:	fe9464e3          	bltu	s0,s1,ffffffffc0203482 <copy_range+0x6e>
    return 0;
ffffffffc020349e:	4501                	li	a0,0
}
ffffffffc02034a0:	70e6                	ld	ra,120(sp)
ffffffffc02034a2:	7446                	ld	s0,112(sp)
ffffffffc02034a4:	74a6                	ld	s1,104(sp)
ffffffffc02034a6:	7906                	ld	s2,96(sp)
ffffffffc02034a8:	69e6                	ld	s3,88(sp)
ffffffffc02034aa:	6a46                	ld	s4,80(sp)
ffffffffc02034ac:	6aa6                	ld	s5,72(sp)
ffffffffc02034ae:	6b06                	ld	s6,64(sp)
ffffffffc02034b0:	7be2                	ld	s7,56(sp)
ffffffffc02034b2:	7c42                	ld	s8,48(sp)
ffffffffc02034b4:	7ca2                	ld	s9,40(sp)
ffffffffc02034b6:	7d02                	ld	s10,32(sp)
ffffffffc02034b8:	6de2                	ld	s11,24(sp)
ffffffffc02034ba:	6109                	addi	sp,sp,128
ffffffffc02034bc:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL) {
ffffffffc02034be:	4605                	li	a2,1
ffffffffc02034c0:	85a2                	mv	a1,s0
ffffffffc02034c2:	8552                	mv	a0,s4
ffffffffc02034c4:	adbfe0ef          	jal	ffffffffc0201f9e <get_pte>
ffffffffc02034c8:	10050763          	beqz	a0,ffffffffc02035d6 <copy_range+0x1c2>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02034cc:	000d3d83          	ld	s11,0(s10)
    if (!(pte & PTE_V))
ffffffffc02034d0:	001df793          	andi	a5,s11,1
ffffffffc02034d4:	10078f63          	beqz	a5,ffffffffc02035f2 <copy_range+0x1de>
    if (PPN(pa) >= npage)
ffffffffc02034d8:	000b3703          	ld	a4,0(s6)
    return pa2page(PTE_ADDR(pte));
ffffffffc02034dc:	002d9793          	slli	a5,s11,0x2
ffffffffc02034e0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02034e2:	0ee7fc63          	bgeu	a5,a4,ffffffffc02035da <copy_range+0x1c6>
    return &pages[PPN(pa) - nbase];
ffffffffc02034e6:	000ab583          	ld	a1,0(s5)
ffffffffc02034ea:	97de                	add	a5,a5,s7
ffffffffc02034ec:	079a                	slli	a5,a5,0x6
ffffffffc02034ee:	95be                	add	a1,a1,a5
            if (share) {
ffffffffc02034f0:	040c0963          	beqz	s8,ffffffffc0203542 <copy_range+0x12e>
                if (*ptep & PTE_W) {
ffffffffc02034f4:	004df793          	andi	a5,s11,4
ffffffffc02034f8:	c799                	beqz	a5,ffffffffc0203506 <copy_range+0xf2>
                    *ptep = (*ptep) & (~PTE_W);
ffffffffc02034fa:	ffbdf793          	andi	a5,s11,-5
ffffffffc02034fe:	00fd3023          	sd	a5,0(s10)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0203502:	12040073          	sfence.vma	s0
                ret = page_insert(to, npage, start, perm & (~PTE_W));
ffffffffc0203506:	01bdf693          	andi	a3,s11,27
ffffffffc020350a:	8622                	mv	a2,s0
ffffffffc020350c:	8552                	mv	a0,s4
ffffffffc020350e:	9c6ff0ef          	jal	ffffffffc02026d4 <page_insert>
            assert(ret == 0);
ffffffffc0203512:	d151                	beqz	a0,ffffffffc0203496 <copy_range+0x82>
ffffffffc0203514:	00004697          	auipc	a3,0x4
ffffffffc0203518:	a1c68693          	addi	a3,a3,-1508 # ffffffffc0206f30 <etext+0x1476>
ffffffffc020351c:	00003617          	auipc	a2,0x3
ffffffffc0203520:	d4c60613          	addi	a2,a2,-692 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203524:	19f00593          	li	a1,415
ffffffffc0203528:	00003517          	auipc	a0,0x3
ffffffffc020352c:	3f050513          	addi	a0,a0,1008 # ffffffffc0206918 <etext+0xe5e>
ffffffffc0203530:	f17fc0ef          	jal	ffffffffc0200446 <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203534:	002007b7          	lui	a5,0x200
ffffffffc0203538:	97a2                	add	a5,a5,s0
ffffffffc020353a:	ffe00437          	lui	s0,0xffe00
ffffffffc020353e:	8c7d                	and	s0,s0,a5
            continue;
ffffffffc0203540:	bfa1                	j	ffffffffc0203498 <copy_range+0x84>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203542:	100027f3          	csrr	a5,sstatus
ffffffffc0203546:	8b89                	andi	a5,a5,2
ffffffffc0203548:	e42e                	sd	a1,8(sp)
ffffffffc020354a:	eba5                	bnez	a5,ffffffffc02035ba <copy_range+0x1a6>
        page = pmm_manager->alloc_pages(n);
ffffffffc020354c:	000a3797          	auipc	a5,0xa3
ffffffffc0203550:	9247b783          	ld	a5,-1756(a5) # ffffffffc02a5e70 <pmm_manager>
ffffffffc0203554:	4505                	li	a0,1
ffffffffc0203556:	6f9c                	ld	a5,24(a5)
ffffffffc0203558:	9782                	jalr	a5
ffffffffc020355a:	65a2                	ld	a1,8(sp)
ffffffffc020355c:	8d2a                	mv	s10,a0
                if (npage == NULL) return -E_NO_MEM;
ffffffffc020355e:	060d0c63          	beqz	s10,ffffffffc02035d6 <copy_range+0x1c2>
    return page - pages + nbase;
ffffffffc0203562:	000ab703          	ld	a4,0(s5)
ffffffffc0203566:	00080537          	lui	a0,0x80
    return KADDR(page2pa(page));
ffffffffc020356a:	000b3603          	ld	a2,0(s6)
    return page - pages + nbase;
ffffffffc020356e:	40e587b3          	sub	a5,a1,a4
ffffffffc0203572:	8799                	srai	a5,a5,0x6
ffffffffc0203574:	97aa                	add	a5,a5,a0
    return KADDR(page2pa(page));
ffffffffc0203576:	0197f6b3          	and	a3,a5,s9
    return page2ppn(page) << PGSHIFT;
ffffffffc020357a:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc020357c:	0ec6f363          	bgeu	a3,a2,ffffffffc0203662 <copy_range+0x24e>
    return page - pages + nbase;
ffffffffc0203580:	40ed06b3          	sub	a3,s10,a4
ffffffffc0203584:	8699                	srai	a3,a3,0x6
ffffffffc0203586:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc0203588:	0196f733          	and	a4,a3,s9
    return page2ppn(page) << PGSHIFT;
ffffffffc020358c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020358e:	0ac77e63          	bgeu	a4,a2,ffffffffc020364a <copy_range+0x236>
ffffffffc0203592:	000a3517          	auipc	a0,0xa3
ffffffffc0203596:	8f653503          	ld	a0,-1802(a0) # ffffffffc02a5e88 <va_pa_offset>
                memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc020359a:	6605                	lui	a2,0x1
ffffffffc020359c:	00a785b3          	add	a1,a5,a0
ffffffffc02035a0:	9536                	add	a0,a0,a3
ffffffffc02035a2:	500020ef          	jal	ffffffffc0205aa2 <memcpy>
                ret = page_insert(to, npage, start, perm);
ffffffffc02035a6:	01fdf693          	andi	a3,s11,31
ffffffffc02035aa:	85ea                	mv	a1,s10
ffffffffc02035ac:	8622                	mv	a2,s0
ffffffffc02035ae:	8552                	mv	a0,s4
ffffffffc02035b0:	924ff0ef          	jal	ffffffffc02026d4 <page_insert>
            assert(ret == 0);
ffffffffc02035b4:	ee0501e3          	beqz	a0,ffffffffc0203496 <copy_range+0x82>
ffffffffc02035b8:	bfb1                	j	ffffffffc0203514 <copy_range+0x100>
        intr_disable();
ffffffffc02035ba:	b4afd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02035be:	000a3797          	auipc	a5,0xa3
ffffffffc02035c2:	8b27b783          	ld	a5,-1870(a5) # ffffffffc02a5e70 <pmm_manager>
ffffffffc02035c6:	4505                	li	a0,1
ffffffffc02035c8:	6f9c                	ld	a5,24(a5)
ffffffffc02035ca:	9782                	jalr	a5
ffffffffc02035cc:	8d2a                	mv	s10,a0
        intr_enable();
ffffffffc02035ce:	b30fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02035d2:	65a2                	ld	a1,8(sp)
ffffffffc02035d4:	b769                	j	ffffffffc020355e <copy_range+0x14a>
                return -E_NO_MEM;
ffffffffc02035d6:	5571                	li	a0,-4
ffffffffc02035d8:	b5e1                	j	ffffffffc02034a0 <copy_range+0x8c>
        panic("pa2page called with invalid pa");
ffffffffc02035da:	00003617          	auipc	a2,0x3
ffffffffc02035de:	31e60613          	addi	a2,a2,798 # ffffffffc02068f8 <etext+0xe3e>
ffffffffc02035e2:	06900593          	li	a1,105
ffffffffc02035e6:	00003517          	auipc	a0,0x3
ffffffffc02035ea:	26a50513          	addi	a0,a0,618 # ffffffffc0206850 <etext+0xd96>
ffffffffc02035ee:	e59fc0ef          	jal	ffffffffc0200446 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02035f2:	00003617          	auipc	a2,0x3
ffffffffc02035f6:	51e60613          	addi	a2,a2,1310 # ffffffffc0206b10 <etext+0x1056>
ffffffffc02035fa:	07f00593          	li	a1,127
ffffffffc02035fe:	00003517          	auipc	a0,0x3
ffffffffc0203602:	25250513          	addi	a0,a0,594 # ffffffffc0206850 <etext+0xd96>
ffffffffc0203606:	e41fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020360a:	00003697          	auipc	a3,0x3
ffffffffc020360e:	34e68693          	addi	a3,a3,846 # ffffffffc0206958 <etext+0xe9e>
ffffffffc0203612:	00003617          	auipc	a2,0x3
ffffffffc0203616:	c5660613          	addi	a2,a2,-938 # ffffffffc0206268 <etext+0x7ae>
ffffffffc020361a:	17a00593          	li	a1,378
ffffffffc020361e:	00003517          	auipc	a0,0x3
ffffffffc0203622:	2fa50513          	addi	a0,a0,762 # ffffffffc0206918 <etext+0xe5e>
ffffffffc0203626:	e21fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020362a:	00003697          	auipc	a3,0x3
ffffffffc020362e:	2fe68693          	addi	a3,a3,766 # ffffffffc0206928 <etext+0xe6e>
ffffffffc0203632:	00003617          	auipc	a2,0x3
ffffffffc0203636:	c3660613          	addi	a2,a2,-970 # ffffffffc0206268 <etext+0x7ae>
ffffffffc020363a:	17900593          	li	a1,377
ffffffffc020363e:	00003517          	auipc	a0,0x3
ffffffffc0203642:	2da50513          	addi	a0,a0,730 # ffffffffc0206918 <etext+0xe5e>
ffffffffc0203646:	e01fc0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc020364a:	00003617          	auipc	a2,0x3
ffffffffc020364e:	1de60613          	addi	a2,a2,478 # ffffffffc0206828 <etext+0xd6e>
ffffffffc0203652:	07100593          	li	a1,113
ffffffffc0203656:	00003517          	auipc	a0,0x3
ffffffffc020365a:	1fa50513          	addi	a0,a0,506 # ffffffffc0206850 <etext+0xd96>
ffffffffc020365e:	de9fc0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0203662:	86be                	mv	a3,a5
ffffffffc0203664:	00003617          	auipc	a2,0x3
ffffffffc0203668:	1c460613          	addi	a2,a2,452 # ffffffffc0206828 <etext+0xd6e>
ffffffffc020366c:	07100593          	li	a1,113
ffffffffc0203670:	00003517          	auipc	a0,0x3
ffffffffc0203674:	1e050513          	addi	a0,a0,480 # ffffffffc0206850 <etext+0xd96>
ffffffffc0203678:	dcffc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc020367c <pgdir_alloc_page>:
{
ffffffffc020367c:	7139                	addi	sp,sp,-64
ffffffffc020367e:	f426                	sd	s1,40(sp)
ffffffffc0203680:	f04a                	sd	s2,32(sp)
ffffffffc0203682:	ec4e                	sd	s3,24(sp)
ffffffffc0203684:	fc06                	sd	ra,56(sp)
ffffffffc0203686:	f822                	sd	s0,48(sp)
ffffffffc0203688:	892a                	mv	s2,a0
ffffffffc020368a:	84ae                	mv	s1,a1
ffffffffc020368c:	89b2                	mv	s3,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020368e:	100027f3          	csrr	a5,sstatus
ffffffffc0203692:	8b89                	andi	a5,a5,2
ffffffffc0203694:	ebb5                	bnez	a5,ffffffffc0203708 <pgdir_alloc_page+0x8c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203696:	000a2417          	auipc	s0,0xa2
ffffffffc020369a:	7da40413          	addi	s0,s0,2010 # ffffffffc02a5e70 <pmm_manager>
ffffffffc020369e:	601c                	ld	a5,0(s0)
ffffffffc02036a0:	4505                	li	a0,1
ffffffffc02036a2:	6f9c                	ld	a5,24(a5)
ffffffffc02036a4:	9782                	jalr	a5
ffffffffc02036a6:	85aa                	mv	a1,a0
    if (page != NULL)
ffffffffc02036a8:	c5b9                	beqz	a1,ffffffffc02036f6 <pgdir_alloc_page+0x7a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc02036aa:	86ce                	mv	a3,s3
ffffffffc02036ac:	854a                	mv	a0,s2
ffffffffc02036ae:	8626                	mv	a2,s1
ffffffffc02036b0:	e42e                	sd	a1,8(sp)
ffffffffc02036b2:	822ff0ef          	jal	ffffffffc02026d4 <page_insert>
ffffffffc02036b6:	65a2                	ld	a1,8(sp)
ffffffffc02036b8:	e515                	bnez	a0,ffffffffc02036e4 <pgdir_alloc_page+0x68>
        assert(page_ref(page) == 1);
ffffffffc02036ba:	4198                	lw	a4,0(a1)
        page->pra_vaddr = la;
ffffffffc02036bc:	fd84                	sd	s1,56(a1)
        assert(page_ref(page) == 1);
ffffffffc02036be:	4785                	li	a5,1
ffffffffc02036c0:	02f70c63          	beq	a4,a5,ffffffffc02036f8 <pgdir_alloc_page+0x7c>
ffffffffc02036c4:	00004697          	auipc	a3,0x4
ffffffffc02036c8:	87c68693          	addi	a3,a3,-1924 # ffffffffc0206f40 <etext+0x1486>
ffffffffc02036cc:	00003617          	auipc	a2,0x3
ffffffffc02036d0:	b9c60613          	addi	a2,a2,-1124 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02036d4:	1e800593          	li	a1,488
ffffffffc02036d8:	00003517          	auipc	a0,0x3
ffffffffc02036dc:	24050513          	addi	a0,a0,576 # ffffffffc0206918 <etext+0xe5e>
ffffffffc02036e0:	d67fc0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc02036e4:	100027f3          	csrr	a5,sstatus
ffffffffc02036e8:	8b89                	andi	a5,a5,2
ffffffffc02036ea:	ef95                	bnez	a5,ffffffffc0203726 <pgdir_alloc_page+0xaa>
        pmm_manager->free_pages(base, n);
ffffffffc02036ec:	601c                	ld	a5,0(s0)
ffffffffc02036ee:	852e                	mv	a0,a1
ffffffffc02036f0:	4585                	li	a1,1
ffffffffc02036f2:	739c                	ld	a5,32(a5)
ffffffffc02036f4:	9782                	jalr	a5
            return NULL;
ffffffffc02036f6:	4581                	li	a1,0
}
ffffffffc02036f8:	70e2                	ld	ra,56(sp)
ffffffffc02036fa:	7442                	ld	s0,48(sp)
ffffffffc02036fc:	74a2                	ld	s1,40(sp)
ffffffffc02036fe:	7902                	ld	s2,32(sp)
ffffffffc0203700:	69e2                	ld	s3,24(sp)
ffffffffc0203702:	852e                	mv	a0,a1
ffffffffc0203704:	6121                	addi	sp,sp,64
ffffffffc0203706:	8082                	ret
        intr_disable();
ffffffffc0203708:	9fcfd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020370c:	000a2417          	auipc	s0,0xa2
ffffffffc0203710:	76440413          	addi	s0,s0,1892 # ffffffffc02a5e70 <pmm_manager>
ffffffffc0203714:	601c                	ld	a5,0(s0)
ffffffffc0203716:	4505                	li	a0,1
ffffffffc0203718:	6f9c                	ld	a5,24(a5)
ffffffffc020371a:	9782                	jalr	a5
ffffffffc020371c:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020371e:	9e0fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0203722:	65a2                	ld	a1,8(sp)
ffffffffc0203724:	b751                	j	ffffffffc02036a8 <pgdir_alloc_page+0x2c>
        intr_disable();
ffffffffc0203726:	9defd0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020372a:	601c                	ld	a5,0(s0)
ffffffffc020372c:	6522                	ld	a0,8(sp)
ffffffffc020372e:	4585                	li	a1,1
ffffffffc0203730:	739c                	ld	a5,32(a5)
ffffffffc0203732:	9782                	jalr	a5
        intr_enable();
ffffffffc0203734:	9cafd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0203738:	bf7d                	j	ffffffffc02036f6 <pgdir_alloc_page+0x7a>

ffffffffc020373a <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc020373a:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc020373c:	00004697          	auipc	a3,0x4
ffffffffc0203740:	81c68693          	addi	a3,a3,-2020 # ffffffffc0206f58 <etext+0x149e>
ffffffffc0203744:	00003617          	auipc	a2,0x3
ffffffffc0203748:	b2460613          	addi	a2,a2,-1244 # ffffffffc0206268 <etext+0x7ae>
ffffffffc020374c:	0c800593          	li	a1,200
ffffffffc0203750:	00004517          	auipc	a0,0x4
ffffffffc0203754:	82850513          	addi	a0,a0,-2008 # ffffffffc0206f78 <etext+0x14be>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203758:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc020375a:	cedfc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc020375e <mm_create>:
{
ffffffffc020375e:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203760:	04000513          	li	a0,64
{
ffffffffc0203764:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203766:	dcefe0ef          	jal	ffffffffc0201d34 <kmalloc>
    if (mm != NULL)
ffffffffc020376a:	cd19                	beqz	a0,ffffffffc0203788 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc020376c:	e508                	sd	a0,8(a0)
ffffffffc020376e:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203770:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203774:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203778:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc020377c:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc0203780:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc0203784:	02053c23          	sd	zero,56(a0)
}
ffffffffc0203788:	60a2                	ld	ra,8(sp)
ffffffffc020378a:	0141                	addi	sp,sp,16
ffffffffc020378c:	8082                	ret

ffffffffc020378e <find_vma>:
    if (mm != NULL)
ffffffffc020378e:	c505                	beqz	a0,ffffffffc02037b6 <find_vma+0x28>
        vma = mm->mmap_cache;
ffffffffc0203790:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203792:	c781                	beqz	a5,ffffffffc020379a <find_vma+0xc>
ffffffffc0203794:	6798                	ld	a4,8(a5)
ffffffffc0203796:	02e5f363          	bgeu	a1,a4,ffffffffc02037bc <find_vma+0x2e>
    return listelm->next;
ffffffffc020379a:	651c                	ld	a5,8(a0)
            while ((le = list_next(le)) != list)
ffffffffc020379c:	00f50d63          	beq	a0,a5,ffffffffc02037b6 <find_vma+0x28>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc02037a0:	fe87b703          	ld	a4,-24(a5)
ffffffffc02037a4:	00e5e663          	bltu	a1,a4,ffffffffc02037b0 <find_vma+0x22>
ffffffffc02037a8:	ff07b703          	ld	a4,-16(a5)
ffffffffc02037ac:	00e5ee63          	bltu	a1,a4,ffffffffc02037c8 <find_vma+0x3a>
ffffffffc02037b0:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc02037b2:	fef517e3          	bne	a0,a5,ffffffffc02037a0 <find_vma+0x12>
    struct vma_struct *vma = NULL;
ffffffffc02037b6:	4781                	li	a5,0
}
ffffffffc02037b8:	853e                	mv	a0,a5
ffffffffc02037ba:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02037bc:	6b98                	ld	a4,16(a5)
ffffffffc02037be:	fce5fee3          	bgeu	a1,a4,ffffffffc020379a <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc02037c2:	e91c                	sd	a5,16(a0)
}
ffffffffc02037c4:	853e                	mv	a0,a5
ffffffffc02037c6:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc02037c8:	1781                	addi	a5,a5,-32
            mm->mmap_cache = vma;
ffffffffc02037ca:	e91c                	sd	a5,16(a0)
ffffffffc02037cc:	bfe5                	j	ffffffffc02037c4 <find_vma+0x36>

ffffffffc02037ce <do_pgfault>:
int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr) {
ffffffffc02037ce:	7139                	addi	sp,sp,-64
ffffffffc02037d0:	f426                	sd	s1,40(sp)
ffffffffc02037d2:	84ae                	mv	s1,a1
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc02037d4:	85b2                	mv	a1,a2
int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr) {
ffffffffc02037d6:	f822                	sd	s0,48(sp)
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc02037d8:	e432                	sd	a2,8(sp)
int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr) {
ffffffffc02037da:	fc06                	sd	ra,56(sp)
ffffffffc02037dc:	842a                	mv	s0,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc02037de:	fb1ff0ef          	jal	ffffffffc020378e <find_vma>
    pgfault_num++;
ffffffffc02037e2:	000a2797          	auipc	a5,0xa2
ffffffffc02037e6:	6c67a783          	lw	a5,1734(a5) # ffffffffc02a5ea8 <pgfault_num>
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc02037ea:	6622                	ld	a2,8(sp)
    pgfault_num++;
ffffffffc02037ec:	2785                	addiw	a5,a5,1
ffffffffc02037ee:	000a2697          	auipc	a3,0xa2
ffffffffc02037f2:	6af6ad23          	sw	a5,1722(a3) # ffffffffc02a5ea8 <pgfault_num>
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc02037f6:	16050c63          	beqz	a0,ffffffffc020396e <do_pgfault+0x1a0>
ffffffffc02037fa:	651c                	ld	a5,8(a0)
ffffffffc02037fc:	872a                	mv	a4,a0
ffffffffc02037fe:	16f66863          	bltu	a2,a5,ffffffffc020396e <do_pgfault+0x1a0>
    switch (error_code & 3) {
ffffffffc0203802:	0034f793          	andi	a5,s1,3
ffffffffc0203806:	4685                	li	a3,1
ffffffffc0203808:	10d78563          	beq	a5,a3,ffffffffc0203912 <do_pgfault+0x144>
ffffffffc020380c:	4689                	li	a3,2
ffffffffc020380e:	0ed79963          	bne	a5,a3,ffffffffc0203900 <do_pgfault+0x132>
            if (!(vma->vm_flags & VM_WRITE)) {
ffffffffc0203812:	4d1c                	lw	a5,24(a0)
ffffffffc0203814:	8b89                	andi	a5,a5,2
ffffffffc0203816:	16078563          	beqz	a5,ffffffffc0203980 <do_pgfault+0x1b2>
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc020381a:	6c08                	ld	a0,24(s0)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc020381c:	77fd                	lui	a5,0xfffff
ffffffffc020381e:	f04a                	sd	s2,32(sp)
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc0203820:	00f675b3          	and	a1,a2,a5
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203824:	00f67933          	and	s2,a2,a5
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc0203828:	4605                	li	a2,1
ffffffffc020382a:	e43a                	sd	a4,8(sp)
ffffffffc020382c:	f72fe0ef          	jal	ffffffffc0201f9e <get_pte>
ffffffffc0203830:	6722                	ld	a4,8(sp)
ffffffffc0203832:	882a                	mv	a6,a0
ffffffffc0203834:	14050e63          	beqz	a0,ffffffffc0203990 <do_pgfault+0x1c2>
    if (*ptep & PTE_V) {
ffffffffc0203838:	6114                	ld	a3,0(a0)
ffffffffc020383a:	0016f793          	andi	a5,a3,1
ffffffffc020383e:	c3f5                	beqz	a5,ffffffffc0203922 <do_pgfault+0x154>
        if ((error_code & 2) && !(*ptep & PTE_W)) {
ffffffffc0203840:	8889                	andi	s1,s1,2
ffffffffc0203842:	12048363          	beqz	s1,ffffffffc0203968 <do_pgfault+0x19a>
ffffffffc0203846:	0046f793          	andi	a5,a3,4
ffffffffc020384a:	10079f63          	bnez	a5,ffffffffc0203968 <do_pgfault+0x19a>
    if (PPN(pa) >= npage)
ffffffffc020384e:	000a2617          	auipc	a2,0xa2
ffffffffc0203852:	64263603          	ld	a2,1602(a2) # ffffffffc02a5e90 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0203856:	00269793          	slli	a5,a3,0x2
ffffffffc020385a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020385c:	14c7fd63          	bgeu	a5,a2,ffffffffc02039b6 <do_pgfault+0x1e8>
    return &pages[PPN(pa) - nbase];
ffffffffc0203860:	00004617          	auipc	a2,0x4
ffffffffc0203864:	4b863603          	ld	a2,1208(a2) # ffffffffc0207d18 <nbase>
ffffffffc0203868:	000a2597          	auipc	a1,0xa2
ffffffffc020386c:	6305b583          	ld	a1,1584(a1) # ffffffffc02a5e98 <pages>
            if (page_ref(page) == 1) {
ffffffffc0203870:	4505                	li	a0,1
ffffffffc0203872:	8f91                	sub	a5,a5,a2
ffffffffc0203874:	079a                	slli	a5,a5,0x6
ffffffffc0203876:	95be                	add	a1,a1,a5
ffffffffc0203878:	419c                	lw	a5,0(a1)
ffffffffc020387a:	0ca78b63          	beq	a5,a0,ffffffffc0203950 <do_pgfault+0x182>
ffffffffc020387e:	ec42                	sd	a6,24(sp)
ffffffffc0203880:	e82e                	sd	a1,16(sp)
ffffffffc0203882:	e432                	sd	a2,8(sp)
                struct Page *npage = alloc_page();
ffffffffc0203884:	e72fe0ef          	jal	ffffffffc0201ef6 <alloc_pages>
ffffffffc0203888:	84aa                	mv	s1,a0
                if (npage == NULL) {
ffffffffc020388a:	cd79                	beqz	a0,ffffffffc0203968 <do_pgfault+0x19a>
    return page - pages + nbase;
ffffffffc020388c:	000a2797          	auipc	a5,0xa2
ffffffffc0203890:	60c7b783          	ld	a5,1548(a5) # ffffffffc02a5e98 <pages>
ffffffffc0203894:	65c2                	ld	a1,16(sp)
ffffffffc0203896:	6622                	ld	a2,8(sp)
    return KADDR(page2pa(page));
ffffffffc0203898:	577d                	li	a4,-1
    return page - pages + nbase;
ffffffffc020389a:	8d9d                	sub	a1,a1,a5
ffffffffc020389c:	8599                	srai	a1,a1,0x6
    return KADDR(page2pa(page));
ffffffffc020389e:	000a2517          	auipc	a0,0xa2
ffffffffc02038a2:	5f253503          	ld	a0,1522(a0) # ffffffffc02a5e90 <npage>
    return page - pages + nbase;
ffffffffc02038a6:	95b2                	add	a1,a1,a2
    return KADDR(page2pa(page));
ffffffffc02038a8:	8331                	srli	a4,a4,0xc
ffffffffc02038aa:	00e5f6b3          	and	a3,a1,a4
ffffffffc02038ae:	6862                	ld	a6,24(sp)
    return page2ppn(page) << PGSHIFT;
ffffffffc02038b0:	05b2                	slli	a1,a1,0xc
    return KADDR(page2pa(page));
ffffffffc02038b2:	10a6fe63          	bgeu	a3,a0,ffffffffc02039ce <do_pgfault+0x200>
    return page - pages + nbase;
ffffffffc02038b6:	40f486b3          	sub	a3,s1,a5
ffffffffc02038ba:	8699                	srai	a3,a3,0x6
ffffffffc02038bc:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02038be:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02038c0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02038c2:	0ca77e63          	bgeu	a4,a0,ffffffffc020399e <do_pgfault+0x1d0>
ffffffffc02038c6:	000a2517          	auipc	a0,0xa2
ffffffffc02038ca:	5c253503          	ld	a0,1474(a0) # ffffffffc02a5e88 <va_pa_offset>
                memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc02038ce:	6605                	lui	a2,0x1
ffffffffc02038d0:	e442                	sd	a6,8(sp)
ffffffffc02038d2:	95aa                	add	a1,a1,a0
ffffffffc02038d4:	9536                	add	a0,a0,a3
ffffffffc02038d6:	1cc020ef          	jal	ffffffffc0205aa2 <memcpy>
                uint32_t perm = (*ptep & PTE_USER) | PTE_W;
ffffffffc02038da:	6822                	ld	a6,8(sp)
                if (page_insert(mm->pgdir, npage, addr, perm) != 0) {
ffffffffc02038dc:	6c08                	ld	a0,24(s0)
ffffffffc02038de:	864a                	mv	a2,s2
                uint32_t perm = (*ptep & PTE_USER) | PTE_W;
ffffffffc02038e0:	00083683          	ld	a3,0(a6) # 80000 <_binary_obj___user_COW_out_size+0x75be0>
                if (page_insert(mm->pgdir, npage, addr, perm) != 0) {
ffffffffc02038e4:	85a6                	mv	a1,s1
                uint32_t perm = (*ptep & PTE_USER) | PTE_W;
ffffffffc02038e6:	8aed                	andi	a3,a3,27
                if (page_insert(mm->pgdir, npage, addr, perm) != 0) {
ffffffffc02038e8:	0046e693          	ori	a3,a3,4
ffffffffc02038ec:	de9fe0ef          	jal	ffffffffc02026d4 <page_insert>
ffffffffc02038f0:	e925                	bnez	a0,ffffffffc0203960 <do_pgfault+0x192>
ffffffffc02038f2:	7902                	ld	s2,32(sp)
        ret = 0;
ffffffffc02038f4:	4501                	li	a0,0
}
ffffffffc02038f6:	70e2                	ld	ra,56(sp)
ffffffffc02038f8:	7442                	ld	s0,48(sp)
ffffffffc02038fa:	74a2                	ld	s1,40(sp)
ffffffffc02038fc:	6121                	addi	sp,sp,64
ffffffffc02038fe:	8082                	ret
            if (!(vma->vm_flags & VM_READ)) {
ffffffffc0203900:	4d1c                	lw	a5,24(a0)
ffffffffc0203902:	8b85                	andi	a5,a5,1
ffffffffc0203904:	fb99                	bnez	a5,ffffffffc020381a <do_pgfault+0x4c>
    int ret = -E_INVAL;
ffffffffc0203906:	5575                	li	a0,-3
}
ffffffffc0203908:	70e2                	ld	ra,56(sp)
ffffffffc020390a:	7442                	ld	s0,48(sp)
ffffffffc020390c:	74a2                	ld	s1,40(sp)
ffffffffc020390e:	6121                	addi	sp,sp,64
ffffffffc0203910:	8082                	ret
            cprintf("do_pgfault failed: error code flag = write AND not present\n");
ffffffffc0203912:	00003517          	auipc	a0,0x3
ffffffffc0203916:	6a650513          	addi	a0,a0,1702 # ffffffffc0206fb8 <etext+0x14fe>
ffffffffc020391a:	87bfc0ef          	jal	ffffffffc0200194 <cprintf>
    int ret = -E_INVAL;
ffffffffc020391e:	5575                	li	a0,-3
ffffffffc0203920:	b7e5                	j	ffffffffc0203908 <do_pgfault+0x13a>
        if (vma->vm_flags & VM_WRITE) {
ffffffffc0203922:	4f1c                	lw	a5,24(a4)
            perm |= PTE_W;
ffffffffc0203924:	4651                	li	a2,20
        if (vma->vm_flags & VM_WRITE) {
ffffffffc0203926:	8b89                	andi	a5,a5,2
ffffffffc0203928:	cf89                	beqz	a5,ffffffffc0203942 <do_pgfault+0x174>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc020392a:	6c08                	ld	a0,24(s0)
ffffffffc020392c:	85ca                	mv	a1,s2
ffffffffc020392e:	d4fff0ef          	jal	ffffffffc020367c <pgdir_alloc_page>
ffffffffc0203932:	f161                	bnez	a0,ffffffffc02038f2 <do_pgfault+0x124>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc0203934:	00003517          	auipc	a0,0x3
ffffffffc0203938:	71450513          	addi	a0,a0,1812 # ffffffffc0207048 <etext+0x158e>
ffffffffc020393c:	859fc0ef          	jal	ffffffffc0200194 <cprintf>
            goto failed;
ffffffffc0203940:	a025                	j	ffffffffc0203968 <do_pgfault+0x19a>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0203942:	6c08                	ld	a0,24(s0)
        uint32_t perm = PTE_U;
ffffffffc0203944:	4641                	li	a2,16
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0203946:	85ca                	mv	a1,s2
ffffffffc0203948:	d35ff0ef          	jal	ffffffffc020367c <pgdir_alloc_page>
ffffffffc020394c:	f15d                	bnez	a0,ffffffffc02038f2 <do_pgfault+0x124>
ffffffffc020394e:	b7dd                	j	ffffffffc0203934 <do_pgfault+0x166>
                page_insert(mm->pgdir, page, addr, (*ptep & PTE_USER) | PTE_W);
ffffffffc0203950:	6c08                	ld	a0,24(s0)
ffffffffc0203952:	8aed                	andi	a3,a3,27
ffffffffc0203954:	0046e693          	ori	a3,a3,4
ffffffffc0203958:	864a                	mv	a2,s2
ffffffffc020395a:	d7bfe0ef          	jal	ffffffffc02026d4 <page_insert>
                ret = 0;
ffffffffc020395e:	bf51                	j	ffffffffc02038f2 <do_pgfault+0x124>
                    free_page(npage);
ffffffffc0203960:	8526                	mv	a0,s1
ffffffffc0203962:	4585                	li	a1,1
ffffffffc0203964:	dccfe0ef          	jal	ffffffffc0201f30 <free_pages>
                    goto failed;
ffffffffc0203968:	7902                	ld	s2,32(sp)
    ret = -E_NO_MEM;
ffffffffc020396a:	5571                	li	a0,-4
ffffffffc020396c:	b769                	j	ffffffffc02038f6 <do_pgfault+0x128>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc020396e:	85b2                	mv	a1,a2
ffffffffc0203970:	00003517          	auipc	a0,0x3
ffffffffc0203974:	61850513          	addi	a0,a0,1560 # ffffffffc0206f88 <etext+0x14ce>
ffffffffc0203978:	81dfc0ef          	jal	ffffffffc0200194 <cprintf>
    int ret = -E_INVAL;
ffffffffc020397c:	5575                	li	a0,-3
ffffffffc020397e:	b769                	j	ffffffffc0203908 <do_pgfault+0x13a>
                cprintf("do_pgfault failed: write to non-writable vma\n");
ffffffffc0203980:	00003517          	auipc	a0,0x3
ffffffffc0203984:	67850513          	addi	a0,a0,1656 # ffffffffc0206ff8 <etext+0x153e>
ffffffffc0203988:	80dfc0ef          	jal	ffffffffc0200194 <cprintf>
    int ret = -E_INVAL;
ffffffffc020398c:	5575                	li	a0,-3
ffffffffc020398e:	bfad                	j	ffffffffc0203908 <do_pgfault+0x13a>
        cprintf("get_pte in do_pgfault failed\n");
ffffffffc0203990:	00003517          	auipc	a0,0x3
ffffffffc0203994:	69850513          	addi	a0,a0,1688 # ffffffffc0207028 <etext+0x156e>
ffffffffc0203998:	ffcfc0ef          	jal	ffffffffc0200194 <cprintf>
        goto failed;
ffffffffc020399c:	b7f1                	j	ffffffffc0203968 <do_pgfault+0x19a>
ffffffffc020399e:	00003617          	auipc	a2,0x3
ffffffffc02039a2:	e8a60613          	addi	a2,a2,-374 # ffffffffc0206828 <etext+0xd6e>
ffffffffc02039a6:	07100593          	li	a1,113
ffffffffc02039aa:	00003517          	auipc	a0,0x3
ffffffffc02039ae:	ea650513          	addi	a0,a0,-346 # ffffffffc0206850 <etext+0xd96>
ffffffffc02039b2:	a95fc0ef          	jal	ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02039b6:	00003617          	auipc	a2,0x3
ffffffffc02039ba:	f4260613          	addi	a2,a2,-190 # ffffffffc02068f8 <etext+0xe3e>
ffffffffc02039be:	06900593          	li	a1,105
ffffffffc02039c2:	00003517          	auipc	a0,0x3
ffffffffc02039c6:	e8e50513          	addi	a0,a0,-370 # ffffffffc0206850 <etext+0xd96>
ffffffffc02039ca:	a7dfc0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc02039ce:	86ae                	mv	a3,a1
ffffffffc02039d0:	00003617          	auipc	a2,0x3
ffffffffc02039d4:	e5860613          	addi	a2,a2,-424 # ffffffffc0206828 <etext+0xd6e>
ffffffffc02039d8:	07100593          	li	a1,113
ffffffffc02039dc:	00003517          	auipc	a0,0x3
ffffffffc02039e0:	e7450513          	addi	a0,a0,-396 # ffffffffc0206850 <etext+0xd96>
ffffffffc02039e4:	a63fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02039e8 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc02039e8:	6590                	ld	a2,8(a1)
ffffffffc02039ea:	0105b803          	ld	a6,16(a1)
{
ffffffffc02039ee:	1141                	addi	sp,sp,-16
ffffffffc02039f0:	e406                	sd	ra,8(sp)
ffffffffc02039f2:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc02039f4:	01066763          	bltu	a2,a6,ffffffffc0203a02 <insert_vma_struct+0x1a>
ffffffffc02039f8:	a8b9                	j	ffffffffc0203a56 <insert_vma_struct+0x6e>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc02039fa:	fe87b703          	ld	a4,-24(a5)
ffffffffc02039fe:	04e66763          	bltu	a2,a4,ffffffffc0203a4c <insert_vma_struct+0x64>
ffffffffc0203a02:	86be                	mv	a3,a5
ffffffffc0203a04:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0203a06:	fef51ae3          	bne	a0,a5,ffffffffc02039fa <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0203a0a:	02a68463          	beq	a3,a0,ffffffffc0203a32 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203a0e:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203a12:	fe86b883          	ld	a7,-24(a3)
ffffffffc0203a16:	08e8f063          	bgeu	a7,a4,ffffffffc0203a96 <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203a1a:	04e66e63          	bltu	a2,a4,ffffffffc0203a76 <insert_vma_struct+0x8e>
    }
    if (le_next != list)
ffffffffc0203a1e:	00f50a63          	beq	a0,a5,ffffffffc0203a32 <insert_vma_struct+0x4a>
ffffffffc0203a22:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203a26:	05076863          	bltu	a4,a6,ffffffffc0203a76 <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc0203a2a:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203a2e:	02c77263          	bgeu	a4,a2,ffffffffc0203a52 <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203a32:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203a34:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0203a36:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0203a3a:	e390                	sd	a2,0(a5)
ffffffffc0203a3c:	e690                	sd	a2,8(a3)
}
ffffffffc0203a3e:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0203a40:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203a42:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0203a44:	2705                	addiw	a4,a4,1
ffffffffc0203a46:	d118                	sw	a4,32(a0)
}
ffffffffc0203a48:	0141                	addi	sp,sp,16
ffffffffc0203a4a:	8082                	ret
    if (le_prev != list)
ffffffffc0203a4c:	fca691e3          	bne	a3,a0,ffffffffc0203a0e <insert_vma_struct+0x26>
ffffffffc0203a50:	bfd9                	j	ffffffffc0203a26 <insert_vma_struct+0x3e>
ffffffffc0203a52:	ce9ff0ef          	jal	ffffffffc020373a <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203a56:	00003697          	auipc	a3,0x3
ffffffffc0203a5a:	61a68693          	addi	a3,a3,1562 # ffffffffc0207070 <etext+0x15b6>
ffffffffc0203a5e:	00003617          	auipc	a2,0x3
ffffffffc0203a62:	80a60613          	addi	a2,a2,-2038 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203a66:	0ce00593          	li	a1,206
ffffffffc0203a6a:	00003517          	auipc	a0,0x3
ffffffffc0203a6e:	50e50513          	addi	a0,a0,1294 # ffffffffc0206f78 <etext+0x14be>
ffffffffc0203a72:	9d5fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203a76:	00003697          	auipc	a3,0x3
ffffffffc0203a7a:	63a68693          	addi	a3,a3,1594 # ffffffffc02070b0 <etext+0x15f6>
ffffffffc0203a7e:	00002617          	auipc	a2,0x2
ffffffffc0203a82:	7ea60613          	addi	a2,a2,2026 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203a86:	0c700593          	li	a1,199
ffffffffc0203a8a:	00003517          	auipc	a0,0x3
ffffffffc0203a8e:	4ee50513          	addi	a0,a0,1262 # ffffffffc0206f78 <etext+0x14be>
ffffffffc0203a92:	9b5fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203a96:	00003697          	auipc	a3,0x3
ffffffffc0203a9a:	5fa68693          	addi	a3,a3,1530 # ffffffffc0207090 <etext+0x15d6>
ffffffffc0203a9e:	00002617          	auipc	a2,0x2
ffffffffc0203aa2:	7ca60613          	addi	a2,a2,1994 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203aa6:	0c600593          	li	a1,198
ffffffffc0203aaa:	00003517          	auipc	a0,0x3
ffffffffc0203aae:	4ce50513          	addi	a0,a0,1230 # ffffffffc0206f78 <etext+0x14be>
ffffffffc0203ab2:	995fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203ab6 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc0203ab6:	591c                	lw	a5,48(a0)
{
ffffffffc0203ab8:	1141                	addi	sp,sp,-16
ffffffffc0203aba:	e406                	sd	ra,8(sp)
ffffffffc0203abc:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc0203abe:	e78d                	bnez	a5,ffffffffc0203ae8 <mm_destroy+0x32>
ffffffffc0203ac0:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0203ac2:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc0203ac4:	00a40c63          	beq	s0,a0,ffffffffc0203adc <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203ac8:	6118                	ld	a4,0(a0)
ffffffffc0203aca:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0203acc:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203ace:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203ad0:	e398                	sd	a4,0(a5)
ffffffffc0203ad2:	b08fe0ef          	jal	ffffffffc0201dda <kfree>
    return listelm->next;
ffffffffc0203ad6:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc0203ad8:	fea418e3          	bne	s0,a0,ffffffffc0203ac8 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc0203adc:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc0203ade:	6402                	ld	s0,0(sp)
ffffffffc0203ae0:	60a2                	ld	ra,8(sp)
ffffffffc0203ae2:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc0203ae4:	af6fe06f          	j	ffffffffc0201dda <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0203ae8:	00003697          	auipc	a3,0x3
ffffffffc0203aec:	5e868693          	addi	a3,a3,1512 # ffffffffc02070d0 <etext+0x1616>
ffffffffc0203af0:	00002617          	auipc	a2,0x2
ffffffffc0203af4:	77860613          	addi	a2,a2,1912 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203af8:	0f200593          	li	a1,242
ffffffffc0203afc:	00003517          	auipc	a0,0x3
ffffffffc0203b00:	47c50513          	addi	a0,a0,1148 # ffffffffc0206f78 <etext+0x14be>
ffffffffc0203b04:	943fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203b08 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203b08:	6785                	lui	a5,0x1
ffffffffc0203b0a:	17fd                	addi	a5,a5,-1 # fff <_binary_obj___user_softint_out_size-0x7c09>
ffffffffc0203b0c:	963e                	add	a2,a2,a5
    if (!USER_ACCESS(start, end))
ffffffffc0203b0e:	4785                	li	a5,1
{
ffffffffc0203b10:	7139                	addi	sp,sp,-64
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203b12:	962e                	add	a2,a2,a1
ffffffffc0203b14:	787d                	lui	a6,0xfffff
    if (!USER_ACCESS(start, end))
ffffffffc0203b16:	07fe                	slli	a5,a5,0x1f
{
ffffffffc0203b18:	f822                	sd	s0,48(sp)
ffffffffc0203b1a:	f426                	sd	s1,40(sp)
ffffffffc0203b1c:	01067433          	and	s0,a2,a6
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203b20:	0105f4b3          	and	s1,a1,a6
    if (!USER_ACCESS(start, end))
ffffffffc0203b24:	0785                	addi	a5,a5,1
ffffffffc0203b26:	0084b633          	sltu	a2,s1,s0
ffffffffc0203b2a:	00f437b3          	sltu	a5,s0,a5
ffffffffc0203b2e:	00163613          	seqz	a2,a2
ffffffffc0203b32:	0017b793          	seqz	a5,a5
{
ffffffffc0203b36:	fc06                	sd	ra,56(sp)
    if (!USER_ACCESS(start, end))
ffffffffc0203b38:	8fd1                	or	a5,a5,a2
ffffffffc0203b3a:	ebbd                	bnez	a5,ffffffffc0203bb0 <mm_map+0xa8>
ffffffffc0203b3c:	002007b7          	lui	a5,0x200
ffffffffc0203b40:	06f4e863          	bltu	s1,a5,ffffffffc0203bb0 <mm_map+0xa8>
ffffffffc0203b44:	f04a                	sd	s2,32(sp)
ffffffffc0203b46:	ec4e                	sd	s3,24(sp)
ffffffffc0203b48:	e852                	sd	s4,16(sp)
ffffffffc0203b4a:	892a                	mv	s2,a0
ffffffffc0203b4c:	89ba                	mv	s3,a4
ffffffffc0203b4e:	8a36                	mv	s4,a3
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203b50:	c135                	beqz	a0,ffffffffc0203bb4 <mm_map+0xac>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203b52:	85a6                	mv	a1,s1
ffffffffc0203b54:	c3bff0ef          	jal	ffffffffc020378e <find_vma>
ffffffffc0203b58:	c501                	beqz	a0,ffffffffc0203b60 <mm_map+0x58>
ffffffffc0203b5a:	651c                	ld	a5,8(a0)
ffffffffc0203b5c:	0487e763          	bltu	a5,s0,ffffffffc0203baa <mm_map+0xa2>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203b60:	03000513          	li	a0,48
ffffffffc0203b64:	9d0fe0ef          	jal	ffffffffc0201d34 <kmalloc>
ffffffffc0203b68:	85aa                	mv	a1,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203b6a:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc0203b6c:	c59d                	beqz	a1,ffffffffc0203b9a <mm_map+0x92>
        vma->vm_start = vm_start;
ffffffffc0203b6e:	e584                	sd	s1,8(a1)
        vma->vm_end = vm_end;
ffffffffc0203b70:	e980                	sd	s0,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0203b72:	0145ac23          	sw	s4,24(a1)

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0203b76:	854a                	mv	a0,s2
ffffffffc0203b78:	e42e                	sd	a1,8(sp)
ffffffffc0203b7a:	e6fff0ef          	jal	ffffffffc02039e8 <insert_vma_struct>
    if (vma_store != NULL)
ffffffffc0203b7e:	65a2                	ld	a1,8(sp)
ffffffffc0203b80:	00098463          	beqz	s3,ffffffffc0203b88 <mm_map+0x80>
    {
        *vma_store = vma;
ffffffffc0203b84:	00b9b023          	sd	a1,0(s3) # 1000 <_binary_obj___user_softint_out_size-0x7c08>
ffffffffc0203b88:	7902                	ld	s2,32(sp)
ffffffffc0203b8a:	69e2                	ld	s3,24(sp)
ffffffffc0203b8c:	6a42                	ld	s4,16(sp)
    }
    ret = 0;
ffffffffc0203b8e:	4501                	li	a0,0

out:
    return ret;
}
ffffffffc0203b90:	70e2                	ld	ra,56(sp)
ffffffffc0203b92:	7442                	ld	s0,48(sp)
ffffffffc0203b94:	74a2                	ld	s1,40(sp)
ffffffffc0203b96:	6121                	addi	sp,sp,64
ffffffffc0203b98:	8082                	ret
ffffffffc0203b9a:	70e2                	ld	ra,56(sp)
ffffffffc0203b9c:	7442                	ld	s0,48(sp)
ffffffffc0203b9e:	7902                	ld	s2,32(sp)
ffffffffc0203ba0:	69e2                	ld	s3,24(sp)
ffffffffc0203ba2:	6a42                	ld	s4,16(sp)
ffffffffc0203ba4:	74a2                	ld	s1,40(sp)
ffffffffc0203ba6:	6121                	addi	sp,sp,64
ffffffffc0203ba8:	8082                	ret
ffffffffc0203baa:	7902                	ld	s2,32(sp)
ffffffffc0203bac:	69e2                	ld	s3,24(sp)
ffffffffc0203bae:	6a42                	ld	s4,16(sp)
        return -E_INVAL;
ffffffffc0203bb0:	5575                	li	a0,-3
ffffffffc0203bb2:	bff9                	j	ffffffffc0203b90 <mm_map+0x88>
    assert(mm != NULL);
ffffffffc0203bb4:	00003697          	auipc	a3,0x3
ffffffffc0203bb8:	53468693          	addi	a3,a3,1332 # ffffffffc02070e8 <etext+0x162e>
ffffffffc0203bbc:	00002617          	auipc	a2,0x2
ffffffffc0203bc0:	6ac60613          	addi	a2,a2,1708 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203bc4:	10700593          	li	a1,263
ffffffffc0203bc8:	00003517          	auipc	a0,0x3
ffffffffc0203bcc:	3b050513          	addi	a0,a0,944 # ffffffffc0206f78 <etext+0x14be>
ffffffffc0203bd0:	877fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203bd4 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc0203bd4:	7139                	addi	sp,sp,-64
ffffffffc0203bd6:	fc06                	sd	ra,56(sp)
ffffffffc0203bd8:	f822                	sd	s0,48(sp)
ffffffffc0203bda:	f426                	sd	s1,40(sp)
ffffffffc0203bdc:	f04a                	sd	s2,32(sp)
ffffffffc0203bde:	ec4e                	sd	s3,24(sp)
ffffffffc0203be0:	e852                	sd	s4,16(sp)
ffffffffc0203be2:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0203be4:	c525                	beqz	a0,ffffffffc0203c4c <dup_mmap+0x78>
ffffffffc0203be6:	892a                	mv	s2,a0
ffffffffc0203be8:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0203bea:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0203bec:	c1a5                	beqz	a1,ffffffffc0203c4c <dup_mmap+0x78>
    return listelm->prev;
ffffffffc0203bee:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203bf0:	04848c63          	beq	s1,s0,ffffffffc0203c48 <dup_mmap+0x74>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203bf4:	03000513          	li	a0,48
    {
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203bf8:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203bfc:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203c00:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203c04:	930fe0ef          	jal	ffffffffc0201d34 <kmalloc>
    if (vma != NULL)
ffffffffc0203c08:	c515                	beqz	a0,ffffffffc0203c34 <dup_mmap+0x60>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0203c0a:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc0203c0c:	01553423          	sd	s5,8(a0)
ffffffffc0203c10:	01453823          	sd	s4,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203c14:	01352c23          	sw	s3,24(a0)
        insert_vma_struct(to, nvma);
ffffffffc0203c18:	854a                	mv	a0,s2
ffffffffc0203c1a:	dcfff0ef          	jal	ffffffffc02039e8 <insert_vma_struct>

        bool share = 1;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc0203c1e:	ff043683          	ld	a3,-16(s0)
ffffffffc0203c22:	fe843603          	ld	a2,-24(s0)
ffffffffc0203c26:	6c8c                	ld	a1,24(s1)
ffffffffc0203c28:	01893503          	ld	a0,24(s2)
ffffffffc0203c2c:	4705                	li	a4,1
ffffffffc0203c2e:	fe6ff0ef          	jal	ffffffffc0203414 <copy_range>
ffffffffc0203c32:	dd55                	beqz	a0,ffffffffc0203bee <dup_mmap+0x1a>
            return -E_NO_MEM;
ffffffffc0203c34:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203c36:	70e2                	ld	ra,56(sp)
ffffffffc0203c38:	7442                	ld	s0,48(sp)
ffffffffc0203c3a:	74a2                	ld	s1,40(sp)
ffffffffc0203c3c:	7902                	ld	s2,32(sp)
ffffffffc0203c3e:	69e2                	ld	s3,24(sp)
ffffffffc0203c40:	6a42                	ld	s4,16(sp)
ffffffffc0203c42:	6aa2                	ld	s5,8(sp)
ffffffffc0203c44:	6121                	addi	sp,sp,64
ffffffffc0203c46:	8082                	ret
    return 0;
ffffffffc0203c48:	4501                	li	a0,0
ffffffffc0203c4a:	b7f5                	j	ffffffffc0203c36 <dup_mmap+0x62>
    assert(to != NULL && from != NULL);
ffffffffc0203c4c:	00003697          	auipc	a3,0x3
ffffffffc0203c50:	4ac68693          	addi	a3,a3,1196 # ffffffffc02070f8 <etext+0x163e>
ffffffffc0203c54:	00002617          	auipc	a2,0x2
ffffffffc0203c58:	61460613          	addi	a2,a2,1556 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203c5c:	12300593          	li	a1,291
ffffffffc0203c60:	00003517          	auipc	a0,0x3
ffffffffc0203c64:	31850513          	addi	a0,a0,792 # ffffffffc0206f78 <etext+0x14be>
ffffffffc0203c68:	fdefc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203c6c <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203c6c:	1101                	addi	sp,sp,-32
ffffffffc0203c6e:	ec06                	sd	ra,24(sp)
ffffffffc0203c70:	e822                	sd	s0,16(sp)
ffffffffc0203c72:	e426                	sd	s1,8(sp)
ffffffffc0203c74:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203c76:	c531                	beqz	a0,ffffffffc0203cc2 <exit_mmap+0x56>
ffffffffc0203c78:	591c                	lw	a5,48(a0)
ffffffffc0203c7a:	84aa                	mv	s1,a0
ffffffffc0203c7c:	e3b9                	bnez	a5,ffffffffc0203cc2 <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203c7e:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203c80:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203c84:	02850663          	beq	a0,s0,ffffffffc0203cb0 <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203c88:	ff043603          	ld	a2,-16(s0)
ffffffffc0203c8c:	fe843583          	ld	a1,-24(s0)
ffffffffc0203c90:	854a                	mv	a0,s2
ffffffffc0203c92:	dbefe0ef          	jal	ffffffffc0202250 <unmap_range>
ffffffffc0203c96:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203c98:	fe8498e3          	bne	s1,s0,ffffffffc0203c88 <exit_mmap+0x1c>
ffffffffc0203c9c:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc0203c9e:	00848c63          	beq	s1,s0,ffffffffc0203cb6 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203ca2:	ff043603          	ld	a2,-16(s0)
ffffffffc0203ca6:	fe843583          	ld	a1,-24(s0)
ffffffffc0203caa:	854a                	mv	a0,s2
ffffffffc0203cac:	ed8fe0ef          	jal	ffffffffc0202384 <exit_range>
ffffffffc0203cb0:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203cb2:	fe8498e3          	bne	s1,s0,ffffffffc0203ca2 <exit_mmap+0x36>
    }
}
ffffffffc0203cb6:	60e2                	ld	ra,24(sp)
ffffffffc0203cb8:	6442                	ld	s0,16(sp)
ffffffffc0203cba:	64a2                	ld	s1,8(sp)
ffffffffc0203cbc:	6902                	ld	s2,0(sp)
ffffffffc0203cbe:	6105                	addi	sp,sp,32
ffffffffc0203cc0:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203cc2:	00003697          	auipc	a3,0x3
ffffffffc0203cc6:	45668693          	addi	a3,a3,1110 # ffffffffc0207118 <etext+0x165e>
ffffffffc0203cca:	00002617          	auipc	a2,0x2
ffffffffc0203cce:	59e60613          	addi	a2,a2,1438 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203cd2:	13c00593          	li	a1,316
ffffffffc0203cd6:	00003517          	auipc	a0,0x3
ffffffffc0203cda:	2a250513          	addi	a0,a0,674 # ffffffffc0206f78 <etext+0x14be>
ffffffffc0203cde:	f68fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203ce2 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203ce2:	7179                	addi	sp,sp,-48
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203ce4:	04000513          	li	a0,64
{
ffffffffc0203ce8:	f406                	sd	ra,40(sp)
ffffffffc0203cea:	f022                	sd	s0,32(sp)
ffffffffc0203cec:	ec26                	sd	s1,24(sp)
ffffffffc0203cee:	e84a                	sd	s2,16(sp)
ffffffffc0203cf0:	e44e                	sd	s3,8(sp)
ffffffffc0203cf2:	e052                	sd	s4,0(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203cf4:	840fe0ef          	jal	ffffffffc0201d34 <kmalloc>
    if (mm != NULL)
ffffffffc0203cf8:	16050c63          	beqz	a0,ffffffffc0203e70 <vmm_init+0x18e>
ffffffffc0203cfc:	842a                	mv	s0,a0
    elm->prev = elm->next = elm;
ffffffffc0203cfe:	e508                	sd	a0,8(a0)
ffffffffc0203d00:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203d02:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203d06:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203d0a:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203d0e:	02053423          	sd	zero,40(a0)
ffffffffc0203d12:	02052823          	sw	zero,48(a0)
ffffffffc0203d16:	02053c23          	sd	zero,56(a0)
ffffffffc0203d1a:	03200493          	li	s1,50
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203d1e:	03000513          	li	a0,48
ffffffffc0203d22:	812fe0ef          	jal	ffffffffc0201d34 <kmalloc>
    if (vma != NULL)
ffffffffc0203d26:	12050563          	beqz	a0,ffffffffc0203e50 <vmm_init+0x16e>
        vma->vm_end = vm_end;
ffffffffc0203d2a:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203d2e:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203d30:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0203d34:	e91c                	sd	a5,16(a0)
    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203d36:	85aa                	mv	a1,a0
    for (i = step1; i >= 1; i--)
ffffffffc0203d38:	14ed                	addi	s1,s1,-5
        insert_vma_struct(mm, vma);
ffffffffc0203d3a:	8522                	mv	a0,s0
ffffffffc0203d3c:	cadff0ef          	jal	ffffffffc02039e8 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203d40:	fcf9                	bnez	s1,ffffffffc0203d1e <vmm_init+0x3c>
ffffffffc0203d42:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203d46:	1f900913          	li	s2,505
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203d4a:	03000513          	li	a0,48
ffffffffc0203d4e:	fe7fd0ef          	jal	ffffffffc0201d34 <kmalloc>
    if (vma != NULL)
ffffffffc0203d52:	12050f63          	beqz	a0,ffffffffc0203e90 <vmm_init+0x1ae>
        vma->vm_end = vm_end;
ffffffffc0203d56:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203d5a:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203d5c:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0203d60:	e91c                	sd	a5,16(a0)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203d62:	85aa                	mv	a1,a0
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203d64:	0495                	addi	s1,s1,5
        insert_vma_struct(mm, vma);
ffffffffc0203d66:	8522                	mv	a0,s0
ffffffffc0203d68:	c81ff0ef          	jal	ffffffffc02039e8 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203d6c:	fd249fe3          	bne	s1,s2,ffffffffc0203d4a <vmm_init+0x68>
    return listelm->next;
ffffffffc0203d70:	641c                	ld	a5,8(s0)
ffffffffc0203d72:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203d74:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203d78:	1ef40c63          	beq	s0,a5,ffffffffc0203f70 <vmm_init+0x28e>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203d7c:	fe87b603          	ld	a2,-24(a5) # 1fffe8 <_binary_obj___user_COW_out_size+0x1f5bc8>
ffffffffc0203d80:	ffe70693          	addi	a3,a4,-2
ffffffffc0203d84:	12d61663          	bne	a2,a3,ffffffffc0203eb0 <vmm_init+0x1ce>
ffffffffc0203d88:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203d8c:	12e69263          	bne	a3,a4,ffffffffc0203eb0 <vmm_init+0x1ce>
    for (i = 1; i <= step2; i++)
ffffffffc0203d90:	0715                	addi	a4,a4,5
ffffffffc0203d92:	679c                	ld	a5,8(a5)
ffffffffc0203d94:	feb712e3          	bne	a4,a1,ffffffffc0203d78 <vmm_init+0x96>
ffffffffc0203d98:	491d                	li	s2,7
ffffffffc0203d9a:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203d9c:	85a6                	mv	a1,s1
ffffffffc0203d9e:	8522                	mv	a0,s0
ffffffffc0203da0:	9efff0ef          	jal	ffffffffc020378e <find_vma>
ffffffffc0203da4:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc0203da6:	20050563          	beqz	a0,ffffffffc0203fb0 <vmm_init+0x2ce>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203daa:	00148593          	addi	a1,s1,1
ffffffffc0203dae:	8522                	mv	a0,s0
ffffffffc0203db0:	9dfff0ef          	jal	ffffffffc020378e <find_vma>
ffffffffc0203db4:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203db6:	1c050d63          	beqz	a0,ffffffffc0203f90 <vmm_init+0x2ae>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203dba:	85ca                	mv	a1,s2
ffffffffc0203dbc:	8522                	mv	a0,s0
ffffffffc0203dbe:	9d1ff0ef          	jal	ffffffffc020378e <find_vma>
        assert(vma3 == NULL);
ffffffffc0203dc2:	18051763          	bnez	a0,ffffffffc0203f50 <vmm_init+0x26e>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203dc6:	00348593          	addi	a1,s1,3
ffffffffc0203dca:	8522                	mv	a0,s0
ffffffffc0203dcc:	9c3ff0ef          	jal	ffffffffc020378e <find_vma>
        assert(vma4 == NULL);
ffffffffc0203dd0:	16051063          	bnez	a0,ffffffffc0203f30 <vmm_init+0x24e>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203dd4:	00448593          	addi	a1,s1,4
ffffffffc0203dd8:	8522                	mv	a0,s0
ffffffffc0203dda:	9b5ff0ef          	jal	ffffffffc020378e <find_vma>
        assert(vma5 == NULL);
ffffffffc0203dde:	12051963          	bnez	a0,ffffffffc0203f10 <vmm_init+0x22e>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203de2:	008a3783          	ld	a5,8(s4)
ffffffffc0203de6:	10979563          	bne	a5,s1,ffffffffc0203ef0 <vmm_init+0x20e>
ffffffffc0203dea:	010a3783          	ld	a5,16(s4)
ffffffffc0203dee:	11279163          	bne	a5,s2,ffffffffc0203ef0 <vmm_init+0x20e>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203df2:	0089b783          	ld	a5,8(s3)
ffffffffc0203df6:	0c979d63          	bne	a5,s1,ffffffffc0203ed0 <vmm_init+0x1ee>
ffffffffc0203dfa:	0109b783          	ld	a5,16(s3)
ffffffffc0203dfe:	0d279963          	bne	a5,s2,ffffffffc0203ed0 <vmm_init+0x1ee>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203e02:	0495                	addi	s1,s1,5
ffffffffc0203e04:	1f900793          	li	a5,505
ffffffffc0203e08:	0915                	addi	s2,s2,5
ffffffffc0203e0a:	f8f499e3          	bne	s1,a5,ffffffffc0203d9c <vmm_init+0xba>
ffffffffc0203e0e:	4491                	li	s1,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203e10:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203e12:	85a6                	mv	a1,s1
ffffffffc0203e14:	8522                	mv	a0,s0
ffffffffc0203e16:	979ff0ef          	jal	ffffffffc020378e <find_vma>
        if (vma_below_5 != NULL)
ffffffffc0203e1a:	1a051b63          	bnez	a0,ffffffffc0203fd0 <vmm_init+0x2ee>
    for (i = 4; i >= 0; i--)
ffffffffc0203e1e:	14fd                	addi	s1,s1,-1
ffffffffc0203e20:	ff2499e3          	bne	s1,s2,ffffffffc0203e12 <vmm_init+0x130>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
        }
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);
ffffffffc0203e24:	8522                	mv	a0,s0
ffffffffc0203e26:	c91ff0ef          	jal	ffffffffc0203ab6 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203e2a:	00003517          	auipc	a0,0x3
ffffffffc0203e2e:	45e50513          	addi	a0,a0,1118 # ffffffffc0207288 <etext+0x17ce>
ffffffffc0203e32:	b62fc0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc0203e36:	7402                	ld	s0,32(sp)
ffffffffc0203e38:	70a2                	ld	ra,40(sp)
ffffffffc0203e3a:	64e2                	ld	s1,24(sp)
ffffffffc0203e3c:	6942                	ld	s2,16(sp)
ffffffffc0203e3e:	69a2                	ld	s3,8(sp)
ffffffffc0203e40:	6a02                	ld	s4,0(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203e42:	00003517          	auipc	a0,0x3
ffffffffc0203e46:	46650513          	addi	a0,a0,1126 # ffffffffc02072a8 <etext+0x17ee>
}
ffffffffc0203e4a:	6145                	addi	sp,sp,48
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203e4c:	b48fc06f          	j	ffffffffc0200194 <cprintf>
        assert(vma != NULL);
ffffffffc0203e50:	00003697          	auipc	a3,0x3
ffffffffc0203e54:	2e868693          	addi	a3,a3,744 # ffffffffc0207138 <etext+0x167e>
ffffffffc0203e58:	00002617          	auipc	a2,0x2
ffffffffc0203e5c:	41060613          	addi	a2,a2,1040 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203e60:	18000593          	li	a1,384
ffffffffc0203e64:	00003517          	auipc	a0,0x3
ffffffffc0203e68:	11450513          	addi	a0,a0,276 # ffffffffc0206f78 <etext+0x14be>
ffffffffc0203e6c:	ddafc0ef          	jal	ffffffffc0200446 <__panic>
    assert(mm != NULL);
ffffffffc0203e70:	00003697          	auipc	a3,0x3
ffffffffc0203e74:	27868693          	addi	a3,a3,632 # ffffffffc02070e8 <etext+0x162e>
ffffffffc0203e78:	00002617          	auipc	a2,0x2
ffffffffc0203e7c:	3f060613          	addi	a2,a2,1008 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203e80:	17800593          	li	a1,376
ffffffffc0203e84:	00003517          	auipc	a0,0x3
ffffffffc0203e88:	0f450513          	addi	a0,a0,244 # ffffffffc0206f78 <etext+0x14be>
ffffffffc0203e8c:	dbafc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma != NULL);
ffffffffc0203e90:	00003697          	auipc	a3,0x3
ffffffffc0203e94:	2a868693          	addi	a3,a3,680 # ffffffffc0207138 <etext+0x167e>
ffffffffc0203e98:	00002617          	auipc	a2,0x2
ffffffffc0203e9c:	3d060613          	addi	a2,a2,976 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203ea0:	18700593          	li	a1,391
ffffffffc0203ea4:	00003517          	auipc	a0,0x3
ffffffffc0203ea8:	0d450513          	addi	a0,a0,212 # ffffffffc0206f78 <etext+0x14be>
ffffffffc0203eac:	d9afc0ef          	jal	ffffffffc0200446 <__panic>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203eb0:	00003697          	auipc	a3,0x3
ffffffffc0203eb4:	2b068693          	addi	a3,a3,688 # ffffffffc0207160 <etext+0x16a6>
ffffffffc0203eb8:	00002617          	auipc	a2,0x2
ffffffffc0203ebc:	3b060613          	addi	a2,a2,944 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203ec0:	19100593          	li	a1,401
ffffffffc0203ec4:	00003517          	auipc	a0,0x3
ffffffffc0203ec8:	0b450513          	addi	a0,a0,180 # ffffffffc0206f78 <etext+0x14be>
ffffffffc0203ecc:	d7afc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203ed0:	00003697          	auipc	a3,0x3
ffffffffc0203ed4:	34868693          	addi	a3,a3,840 # ffffffffc0207218 <etext+0x175e>
ffffffffc0203ed8:	00002617          	auipc	a2,0x2
ffffffffc0203edc:	39060613          	addi	a2,a2,912 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203ee0:	1a300593          	li	a1,419
ffffffffc0203ee4:	00003517          	auipc	a0,0x3
ffffffffc0203ee8:	09450513          	addi	a0,a0,148 # ffffffffc0206f78 <etext+0x14be>
ffffffffc0203eec:	d5afc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203ef0:	00003697          	auipc	a3,0x3
ffffffffc0203ef4:	2f868693          	addi	a3,a3,760 # ffffffffc02071e8 <etext+0x172e>
ffffffffc0203ef8:	00002617          	auipc	a2,0x2
ffffffffc0203efc:	37060613          	addi	a2,a2,880 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203f00:	1a200593          	li	a1,418
ffffffffc0203f04:	00003517          	auipc	a0,0x3
ffffffffc0203f08:	07450513          	addi	a0,a0,116 # ffffffffc0206f78 <etext+0x14be>
ffffffffc0203f0c:	d3afc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma5 == NULL);
ffffffffc0203f10:	00003697          	auipc	a3,0x3
ffffffffc0203f14:	2c868693          	addi	a3,a3,712 # ffffffffc02071d8 <etext+0x171e>
ffffffffc0203f18:	00002617          	auipc	a2,0x2
ffffffffc0203f1c:	35060613          	addi	a2,a2,848 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203f20:	1a000593          	li	a1,416
ffffffffc0203f24:	00003517          	auipc	a0,0x3
ffffffffc0203f28:	05450513          	addi	a0,a0,84 # ffffffffc0206f78 <etext+0x14be>
ffffffffc0203f2c:	d1afc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma4 == NULL);
ffffffffc0203f30:	00003697          	auipc	a3,0x3
ffffffffc0203f34:	29868693          	addi	a3,a3,664 # ffffffffc02071c8 <etext+0x170e>
ffffffffc0203f38:	00002617          	auipc	a2,0x2
ffffffffc0203f3c:	33060613          	addi	a2,a2,816 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203f40:	19e00593          	li	a1,414
ffffffffc0203f44:	00003517          	auipc	a0,0x3
ffffffffc0203f48:	03450513          	addi	a0,a0,52 # ffffffffc0206f78 <etext+0x14be>
ffffffffc0203f4c:	cfafc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma3 == NULL);
ffffffffc0203f50:	00003697          	auipc	a3,0x3
ffffffffc0203f54:	26868693          	addi	a3,a3,616 # ffffffffc02071b8 <etext+0x16fe>
ffffffffc0203f58:	00002617          	auipc	a2,0x2
ffffffffc0203f5c:	31060613          	addi	a2,a2,784 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203f60:	19c00593          	li	a1,412
ffffffffc0203f64:	00003517          	auipc	a0,0x3
ffffffffc0203f68:	01450513          	addi	a0,a0,20 # ffffffffc0206f78 <etext+0x14be>
ffffffffc0203f6c:	cdafc0ef          	jal	ffffffffc0200446 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203f70:	00003697          	auipc	a3,0x3
ffffffffc0203f74:	1d868693          	addi	a3,a3,472 # ffffffffc0207148 <etext+0x168e>
ffffffffc0203f78:	00002617          	auipc	a2,0x2
ffffffffc0203f7c:	2f060613          	addi	a2,a2,752 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203f80:	18f00593          	li	a1,399
ffffffffc0203f84:	00003517          	auipc	a0,0x3
ffffffffc0203f88:	ff450513          	addi	a0,a0,-12 # ffffffffc0206f78 <etext+0x14be>
ffffffffc0203f8c:	cbafc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma2 != NULL);
ffffffffc0203f90:	00003697          	auipc	a3,0x3
ffffffffc0203f94:	21868693          	addi	a3,a3,536 # ffffffffc02071a8 <etext+0x16ee>
ffffffffc0203f98:	00002617          	auipc	a2,0x2
ffffffffc0203f9c:	2d060613          	addi	a2,a2,720 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203fa0:	19a00593          	li	a1,410
ffffffffc0203fa4:	00003517          	auipc	a0,0x3
ffffffffc0203fa8:	fd450513          	addi	a0,a0,-44 # ffffffffc0206f78 <etext+0x14be>
ffffffffc0203fac:	c9afc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma1 != NULL);
ffffffffc0203fb0:	00003697          	auipc	a3,0x3
ffffffffc0203fb4:	1e868693          	addi	a3,a3,488 # ffffffffc0207198 <etext+0x16de>
ffffffffc0203fb8:	00002617          	auipc	a2,0x2
ffffffffc0203fbc:	2b060613          	addi	a2,a2,688 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203fc0:	19800593          	li	a1,408
ffffffffc0203fc4:	00003517          	auipc	a0,0x3
ffffffffc0203fc8:	fb450513          	addi	a0,a0,-76 # ffffffffc0206f78 <etext+0x14be>
ffffffffc0203fcc:	c7afc0ef          	jal	ffffffffc0200446 <__panic>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203fd0:	6914                	ld	a3,16(a0)
ffffffffc0203fd2:	6510                	ld	a2,8(a0)
ffffffffc0203fd4:	0004859b          	sext.w	a1,s1
ffffffffc0203fd8:	00003517          	auipc	a0,0x3
ffffffffc0203fdc:	27050513          	addi	a0,a0,624 # ffffffffc0207248 <etext+0x178e>
ffffffffc0203fe0:	9b4fc0ef          	jal	ffffffffc0200194 <cprintf>
        assert(vma_below_5 == NULL);
ffffffffc0203fe4:	00003697          	auipc	a3,0x3
ffffffffc0203fe8:	28c68693          	addi	a3,a3,652 # ffffffffc0207270 <etext+0x17b6>
ffffffffc0203fec:	00002617          	auipc	a2,0x2
ffffffffc0203ff0:	27c60613          	addi	a2,a2,636 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0203ff4:	1ad00593          	li	a1,429
ffffffffc0203ff8:	00003517          	auipc	a0,0x3
ffffffffc0203ffc:	f8050513          	addi	a0,a0,-128 # ffffffffc0206f78 <etext+0x14be>
ffffffffc0204000:	c46fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0204004 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0204004:	7179                	addi	sp,sp,-48
ffffffffc0204006:	f022                	sd	s0,32(sp)
ffffffffc0204008:	f406                	sd	ra,40(sp)
ffffffffc020400a:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc020400c:	c52d                	beqz	a0,ffffffffc0204076 <user_mem_check+0x72>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc020400e:	002007b7          	lui	a5,0x200
ffffffffc0204012:	04f5ed63          	bltu	a1,a5,ffffffffc020406c <user_mem_check+0x68>
ffffffffc0204016:	ec26                	sd	s1,24(sp)
ffffffffc0204018:	00c584b3          	add	s1,a1,a2
ffffffffc020401c:	0695ff63          	bgeu	a1,s1,ffffffffc020409a <user_mem_check+0x96>
ffffffffc0204020:	4785                	li	a5,1
ffffffffc0204022:	07fe                	slli	a5,a5,0x1f
ffffffffc0204024:	0785                	addi	a5,a5,1 # 200001 <_binary_obj___user_COW_out_size+0x1f5be1>
ffffffffc0204026:	06f4fa63          	bgeu	s1,a5,ffffffffc020409a <user_mem_check+0x96>
ffffffffc020402a:	e84a                	sd	s2,16(sp)
ffffffffc020402c:	e44e                	sd	s3,8(sp)
ffffffffc020402e:	8936                	mv	s2,a3
ffffffffc0204030:	89aa                	mv	s3,a0
ffffffffc0204032:	a829                	j	ffffffffc020404c <user_mem_check+0x48>
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0204034:	6685                	lui	a3,0x1
ffffffffc0204036:	9736                	add	a4,a4,a3
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0204038:	0027f693          	andi	a3,a5,2
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc020403c:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc020403e:	c685                	beqz	a3,ffffffffc0204066 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0204040:	c399                	beqz	a5,ffffffffc0204046 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0204042:	02e46263          	bltu	s0,a4,ffffffffc0204066 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0204046:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0204048:	04947b63          	bgeu	s0,s1,ffffffffc020409e <user_mem_check+0x9a>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc020404c:	85a2                	mv	a1,s0
ffffffffc020404e:	854e                	mv	a0,s3
ffffffffc0204050:	f3eff0ef          	jal	ffffffffc020378e <find_vma>
ffffffffc0204054:	c909                	beqz	a0,ffffffffc0204066 <user_mem_check+0x62>
ffffffffc0204056:	6518                	ld	a4,8(a0)
ffffffffc0204058:	00e46763          	bltu	s0,a4,ffffffffc0204066 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc020405c:	4d1c                	lw	a5,24(a0)
ffffffffc020405e:	fc091be3          	bnez	s2,ffffffffc0204034 <user_mem_check+0x30>
ffffffffc0204062:	8b85                	andi	a5,a5,1
ffffffffc0204064:	f3ed                	bnez	a5,ffffffffc0204046 <user_mem_check+0x42>
ffffffffc0204066:	64e2                	ld	s1,24(sp)
ffffffffc0204068:	6942                	ld	s2,16(sp)
ffffffffc020406a:	69a2                	ld	s3,8(sp)
            return 0;
ffffffffc020406c:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc020406e:	70a2                	ld	ra,40(sp)
ffffffffc0204070:	7402                	ld	s0,32(sp)
ffffffffc0204072:	6145                	addi	sp,sp,48
ffffffffc0204074:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0204076:	c02007b7          	lui	a5,0xc0200
ffffffffc020407a:	fef5eae3          	bltu	a1,a5,ffffffffc020406e <user_mem_check+0x6a>
ffffffffc020407e:	c80007b7          	lui	a5,0xc8000
ffffffffc0204082:	962e                	add	a2,a2,a1
ffffffffc0204084:	0785                	addi	a5,a5,1 # ffffffffc8000001 <end+0x7d5a139>
ffffffffc0204086:	00c5b433          	sltu	s0,a1,a2
ffffffffc020408a:	00f63633          	sltu	a2,a2,a5
ffffffffc020408e:	70a2                	ld	ra,40(sp)
    return KERN_ACCESS(addr, addr + len);
ffffffffc0204090:	00867533          	and	a0,a2,s0
ffffffffc0204094:	7402                	ld	s0,32(sp)
ffffffffc0204096:	6145                	addi	sp,sp,48
ffffffffc0204098:	8082                	ret
ffffffffc020409a:	64e2                	ld	s1,24(sp)
ffffffffc020409c:	bfc1                	j	ffffffffc020406c <user_mem_check+0x68>
ffffffffc020409e:	64e2                	ld	s1,24(sp)
ffffffffc02040a0:	6942                	ld	s2,16(sp)
ffffffffc02040a2:	69a2                	ld	s3,8(sp)
        return 1;
ffffffffc02040a4:	4505                	li	a0,1
ffffffffc02040a6:	b7e1                	j	ffffffffc020406e <user_mem_check+0x6a>

ffffffffc02040a8 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc02040a8:	8526                	mv	a0,s1
	jalr s0
ffffffffc02040aa:	9402                	jalr	s0

	jal do_exit
ffffffffc02040ac:	670000ef          	jal	ffffffffc020471c <do_exit>

ffffffffc02040b0 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc02040b0:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc02040b2:	10800513          	li	a0,264
{
ffffffffc02040b6:	e022                	sd	s0,0(sp)
ffffffffc02040b8:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc02040ba:	c7bfd0ef          	jal	ffffffffc0201d34 <kmalloc>
ffffffffc02040be:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc02040c0:	cd21                	beqz	a0,ffffffffc0204118 <alloc_proc+0x68>
    {
        proc->state = PROC_UNINIT;      // 状态设为未初始化
ffffffffc02040c2:	57fd                	li	a5,-1
ffffffffc02040c4:	1782                	slli	a5,a5,0x20
ffffffffc02040c6:	e11c                	sd	a5,0(a0)
        proc->pid = -1;                 // pid 设为 -1，表示尚未分配有效 pid
        proc->runs = 0;                 // 运行时间/次数初始化为 0
ffffffffc02040c8:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;               // 内核栈尚未分配，设为 0
ffffffffc02040cc:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;         // 不需要立即调度
ffffffffc02040d0:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;            // 父进程暂无
ffffffffc02040d4:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;                // 内存管理结构暂无
ffffffffc02040d8:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context)); // 上下文清零
ffffffffc02040dc:	07000613          	li	a2,112
ffffffffc02040e0:	4581                	li	a1,0
ffffffffc02040e2:	03050513          	addi	a0,a0,48
ffffffffc02040e6:	1ab010ef          	jal	ffffffffc0205a90 <memset>
        proc->tf = NULL;                // 中断帧指针暂空
        proc->pgdir = boot_pgdir_pa;    // 页目录表设为内核页目录表的物理地址 
ffffffffc02040ea:	000a2797          	auipc	a5,0xa2
ffffffffc02040ee:	d8e7b783          	ld	a5,-626(a5) # ffffffffc02a5e78 <boot_pgdir_pa>
        proc->tf = NULL;                // 中断帧指针暂空
ffffffffc02040f2:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;                // 标志位清零
ffffffffc02040f6:	0a042823          	sw	zero,176(s0)
        proc->pgdir = boot_pgdir_pa;    // 页目录表设为内核页目录表的物理地址 
ffffffffc02040fa:	f45c                	sd	a5,168(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1); // 进程名清零
ffffffffc02040fc:	0b440513          	addi	a0,s0,180
ffffffffc0204100:	4641                	li	a2,16
ffffffffc0204102:	4581                	li	a1,0
ffffffffc0204104:	18d010ef          	jal	ffffffffc0205a90 <memset>
        proc->wait_state = 0;        // 等待状态初始化为 0
ffffffffc0204108:	0e042623          	sw	zero,236(s0)
        proc->cptr = NULL;
ffffffffc020410c:	0e043823          	sd	zero,240(s0)
        proc->optr = NULL;
ffffffffc0204110:	10043023          	sd	zero,256(s0)
        proc->yptr = NULL;
ffffffffc0204114:	0e043c23          	sd	zero,248(s0)
    }
    return proc;
}
ffffffffc0204118:	60a2                	ld	ra,8(sp)
ffffffffc020411a:	8522                	mv	a0,s0
ffffffffc020411c:	6402                	ld	s0,0(sp)
ffffffffc020411e:	0141                	addi	sp,sp,16
ffffffffc0204120:	8082                	ret

ffffffffc0204122 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0204122:	000a2797          	auipc	a5,0xa2
ffffffffc0204126:	d8e7b783          	ld	a5,-626(a5) # ffffffffc02a5eb0 <current>
ffffffffc020412a:	73c8                	ld	a0,160(a5)
ffffffffc020412c:	deffc06f          	j	ffffffffc0200f1a <forkrets>

ffffffffc0204130 <user_main>:
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
#else
    KERNEL_EXECVE(COW);
ffffffffc0204130:	000a2797          	auipc	a5,0xa2
ffffffffc0204134:	d807b783          	ld	a5,-640(a5) # ffffffffc02a5eb0 <current>
{
ffffffffc0204138:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE(COW);
ffffffffc020413a:	00003617          	auipc	a2,0x3
ffffffffc020413e:	18660613          	addi	a2,a2,390 # ffffffffc02072c0 <etext+0x1806>
ffffffffc0204142:	43cc                	lw	a1,4(a5)
ffffffffc0204144:	00003517          	auipc	a0,0x3
ffffffffc0204148:	18450513          	addi	a0,a0,388 # ffffffffc02072c8 <etext+0x180e>
{
ffffffffc020414c:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE(COW);
ffffffffc020414e:	846fc0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0204152:	3fe06797          	auipc	a5,0x3fe06
ffffffffc0204156:	2ce78793          	addi	a5,a5,718 # a420 <_binary_obj___user_COW_out_size>
ffffffffc020415a:	e43e                	sd	a5,8(sp)
kernel_execve(const char *name, unsigned char *binary, size_t size)
ffffffffc020415c:	00003517          	auipc	a0,0x3
ffffffffc0204160:	16450513          	addi	a0,a0,356 # ffffffffc02072c0 <etext+0x1806>
ffffffffc0204164:	00007797          	auipc	a5,0x7
ffffffffc0204168:	eac78793          	addi	a5,a5,-340 # ffffffffc020b010 <_binary_obj___user_COW_out_start>
ffffffffc020416c:	f03e                	sd	a5,32(sp)
ffffffffc020416e:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc0204170:	e802                	sd	zero,16(sp)
ffffffffc0204172:	06b010ef          	jal	ffffffffc02059dc <strlen>
ffffffffc0204176:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0204178:	4511                	li	a0,4
ffffffffc020417a:	55a2                	lw	a1,40(sp)
ffffffffc020417c:	4662                	lw	a2,24(sp)
ffffffffc020417e:	5682                	lw	a3,32(sp)
ffffffffc0204180:	4722                	lw	a4,8(sp)
ffffffffc0204182:	48a9                	li	a7,10
ffffffffc0204184:	9002                	ebreak
ffffffffc0204186:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0204188:	65c2                	ld	a1,16(sp)
ffffffffc020418a:	00003517          	auipc	a0,0x3
ffffffffc020418e:	16650513          	addi	a0,a0,358 # ffffffffc02072f0 <etext+0x1836>
ffffffffc0204192:	802fc0ef          	jal	ffffffffc0200194 <cprintf>
#endif
    panic("user_main execve failed.\n");
ffffffffc0204196:	00003617          	auipc	a2,0x3
ffffffffc020419a:	16a60613          	addi	a2,a2,362 # ffffffffc0207300 <etext+0x1846>
ffffffffc020419e:	38400593          	li	a1,900
ffffffffc02041a2:	00003517          	auipc	a0,0x3
ffffffffc02041a6:	17e50513          	addi	a0,a0,382 # ffffffffc0207320 <etext+0x1866>
ffffffffc02041aa:	a9cfc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02041ae <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc02041ae:	6d14                	ld	a3,24(a0)
{
ffffffffc02041b0:	1141                	addi	sp,sp,-16
ffffffffc02041b2:	e406                	sd	ra,8(sp)
ffffffffc02041b4:	c02007b7          	lui	a5,0xc0200
ffffffffc02041b8:	02f6ee63          	bltu	a3,a5,ffffffffc02041f4 <put_pgdir+0x46>
ffffffffc02041bc:	000a2717          	auipc	a4,0xa2
ffffffffc02041c0:	ccc73703          	ld	a4,-820(a4) # ffffffffc02a5e88 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc02041c4:	000a2797          	auipc	a5,0xa2
ffffffffc02041c8:	ccc7b783          	ld	a5,-820(a5) # ffffffffc02a5e90 <npage>
    return pa2page(PADDR(kva));
ffffffffc02041cc:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc02041ce:	82b1                	srli	a3,a3,0xc
ffffffffc02041d0:	02f6fe63          	bgeu	a3,a5,ffffffffc020420c <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc02041d4:	00004797          	auipc	a5,0x4
ffffffffc02041d8:	b447b783          	ld	a5,-1212(a5) # ffffffffc0207d18 <nbase>
ffffffffc02041dc:	000a2517          	auipc	a0,0xa2
ffffffffc02041e0:	cbc53503          	ld	a0,-836(a0) # ffffffffc02a5e98 <pages>
}
ffffffffc02041e4:	60a2                	ld	ra,8(sp)
ffffffffc02041e6:	8e9d                	sub	a3,a3,a5
ffffffffc02041e8:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc02041ea:	4585                	li	a1,1
ffffffffc02041ec:	9536                	add	a0,a0,a3
}
ffffffffc02041ee:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc02041f0:	d41fd06f          	j	ffffffffc0201f30 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc02041f4:	00002617          	auipc	a2,0x2
ffffffffc02041f8:	6dc60613          	addi	a2,a2,1756 # ffffffffc02068d0 <etext+0xe16>
ffffffffc02041fc:	07700593          	li	a1,119
ffffffffc0204200:	00002517          	auipc	a0,0x2
ffffffffc0204204:	65050513          	addi	a0,a0,1616 # ffffffffc0206850 <etext+0xd96>
ffffffffc0204208:	a3efc0ef          	jal	ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020420c:	00002617          	auipc	a2,0x2
ffffffffc0204210:	6ec60613          	addi	a2,a2,1772 # ffffffffc02068f8 <etext+0xe3e>
ffffffffc0204214:	06900593          	li	a1,105
ffffffffc0204218:	00002517          	auipc	a0,0x2
ffffffffc020421c:	63850513          	addi	a0,a0,1592 # ffffffffc0206850 <etext+0xd96>
ffffffffc0204220:	a26fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0204224 <proc_run>:
    if (proc != current)
ffffffffc0204224:	000a2697          	auipc	a3,0xa2
ffffffffc0204228:	c8c6b683          	ld	a3,-884(a3) # ffffffffc02a5eb0 <current>
ffffffffc020422c:	04a68463          	beq	a3,a0,ffffffffc0204274 <proc_run+0x50>
{
ffffffffc0204230:	1101                	addi	sp,sp,-32
ffffffffc0204232:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204234:	100027f3          	csrr	a5,sstatus
ffffffffc0204238:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020423a:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020423c:	ef8d                	bnez	a5,ffffffffc0204276 <proc_run+0x52>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc020423e:	755c                	ld	a5,168(a0)
ffffffffc0204240:	577d                	li	a4,-1
ffffffffc0204242:	177e                	slli	a4,a4,0x3f
ffffffffc0204244:	83b1                	srli	a5,a5,0xc
ffffffffc0204246:	e032                	sd	a2,0(sp)
            current = proc;
ffffffffc0204248:	000a2597          	auipc	a1,0xa2
ffffffffc020424c:	c6a5b423          	sd	a0,-920(a1) # ffffffffc02a5eb0 <current>
ffffffffc0204250:	8fd9                	or	a5,a5,a4
ffffffffc0204252:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context));
ffffffffc0204256:	03050593          	addi	a1,a0,48
ffffffffc020425a:	03068513          	addi	a0,a3,48
ffffffffc020425e:	136010ef          	jal	ffffffffc0205394 <switch_to>
    if (flag)
ffffffffc0204262:	6602                	ld	a2,0(sp)
ffffffffc0204264:	e601                	bnez	a2,ffffffffc020426c <proc_run+0x48>
}
ffffffffc0204266:	60e2                	ld	ra,24(sp)
ffffffffc0204268:	6105                	addi	sp,sp,32
ffffffffc020426a:	8082                	ret
ffffffffc020426c:	60e2                	ld	ra,24(sp)
ffffffffc020426e:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0204270:	e8efc06f          	j	ffffffffc02008fe <intr_enable>
ffffffffc0204274:	8082                	ret
ffffffffc0204276:	e42a                	sd	a0,8(sp)
ffffffffc0204278:	e036                	sd	a3,0(sp)
        intr_disable();
ffffffffc020427a:	e8afc0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc020427e:	6522                	ld	a0,8(sp)
ffffffffc0204280:	6682                	ld	a3,0(sp)
ffffffffc0204282:	4605                	li	a2,1
ffffffffc0204284:	bf6d                	j	ffffffffc020423e <proc_run+0x1a>

ffffffffc0204286 <do_fork>:
    if (nr_process >= MAX_PROCESS)
ffffffffc0204286:	000a2717          	auipc	a4,0xa2
ffffffffc020428a:	c2672703          	lw	a4,-986(a4) # ffffffffc02a5eac <nr_process>
ffffffffc020428e:	6785                	lui	a5,0x1
ffffffffc0204290:	36f75d63          	bge	a4,a5,ffffffffc020460a <do_fork+0x384>
{
ffffffffc0204294:	711d                	addi	sp,sp,-96
ffffffffc0204296:	e8a2                	sd	s0,80(sp)
ffffffffc0204298:	e4a6                	sd	s1,72(sp)
ffffffffc020429a:	e0ca                	sd	s2,64(sp)
ffffffffc020429c:	e06a                	sd	s10,0(sp)
ffffffffc020429e:	ec86                	sd	ra,88(sp)
ffffffffc02042a0:	892e                	mv	s2,a1
ffffffffc02042a2:	84b2                	mv	s1,a2
ffffffffc02042a4:	8d2a                	mv	s10,a0
    if ((proc = alloc_proc()) == NULL) {
ffffffffc02042a6:	e0bff0ef          	jal	ffffffffc02040b0 <alloc_proc>
ffffffffc02042aa:	842a                	mv	s0,a0
ffffffffc02042ac:	30050063          	beqz	a0,ffffffffc02045ac <do_fork+0x326>
    proc->parent = current; 
ffffffffc02042b0:	f05a                	sd	s6,32(sp)
ffffffffc02042b2:	000a2b17          	auipc	s6,0xa2
ffffffffc02042b6:	bfeb0b13          	addi	s6,s6,-1026 # ffffffffc02a5eb0 <current>
ffffffffc02042ba:	000b3783          	ld	a5,0(s6)
    assert(current->wait_state == 0);
ffffffffc02042be:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_softint_out_size-0x7b1c>
    proc->parent = current; 
ffffffffc02042c2:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0);
ffffffffc02042c4:	3c071263          	bnez	a4,ffffffffc0204688 <do_fork+0x402>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc02042c8:	4509                	li	a0,2
ffffffffc02042ca:	c2dfd0ef          	jal	ffffffffc0201ef6 <alloc_pages>
    if (page != NULL)
ffffffffc02042ce:	2c050b63          	beqz	a0,ffffffffc02045a4 <do_fork+0x31e>
ffffffffc02042d2:	fc4e                	sd	s3,56(sp)
    return page - pages + nbase;
ffffffffc02042d4:	000a2997          	auipc	s3,0xa2
ffffffffc02042d8:	bc498993          	addi	s3,s3,-1084 # ffffffffc02a5e98 <pages>
ffffffffc02042dc:	0009b783          	ld	a5,0(s3)
ffffffffc02042e0:	f852                	sd	s4,48(sp)
ffffffffc02042e2:	00004a17          	auipc	s4,0x4
ffffffffc02042e6:	a36a0a13          	addi	s4,s4,-1482 # ffffffffc0207d18 <nbase>
ffffffffc02042ea:	e466                	sd	s9,8(sp)
ffffffffc02042ec:	000a3c83          	ld	s9,0(s4)
ffffffffc02042f0:	40f506b3          	sub	a3,a0,a5
ffffffffc02042f4:	f456                	sd	s5,40(sp)
    return KADDR(page2pa(page));
ffffffffc02042f6:	000a2a97          	auipc	s5,0xa2
ffffffffc02042fa:	b9aa8a93          	addi	s5,s5,-1126 # ffffffffc02a5e90 <npage>
ffffffffc02042fe:	e862                	sd	s8,16(sp)
    return page - pages + nbase;
ffffffffc0204300:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204302:	5c7d                	li	s8,-1
ffffffffc0204304:	000ab783          	ld	a5,0(s5)
    return page - pages + nbase;
ffffffffc0204308:	96e6                	add	a3,a3,s9
    return KADDR(page2pa(page));
ffffffffc020430a:	00cc5c13          	srli	s8,s8,0xc
ffffffffc020430e:	0186f733          	and	a4,a3,s8
ffffffffc0204312:	ec5e                	sd	s7,24(sp)
    return page2ppn(page) << PGSHIFT;
ffffffffc0204314:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204316:	30f77863          	bgeu	a4,a5,ffffffffc0204626 <do_fork+0x3a0>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc020431a:	000b3703          	ld	a4,0(s6)
ffffffffc020431e:	000a2b17          	auipc	s6,0xa2
ffffffffc0204322:	b6ab0b13          	addi	s6,s6,-1174 # ffffffffc02a5e88 <va_pa_offset>
ffffffffc0204326:	000b3783          	ld	a5,0(s6)
ffffffffc020432a:	02873b83          	ld	s7,40(a4)
ffffffffc020432e:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0204330:	e814                	sd	a3,16(s0)
    if (oldmm == NULL)
ffffffffc0204332:	020b8863          	beqz	s7,ffffffffc0204362 <do_fork+0xdc>
    if (clone_flags & CLONE_VM)
ffffffffc0204336:	100d7793          	andi	a5,s10,256
ffffffffc020433a:	18078b63          	beqz	a5,ffffffffc02044d0 <do_fork+0x24a>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc020433e:	030ba703          	lw	a4,48(s7) # fffffffffff80030 <end+0x3fcda168>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204342:	018bb783          	ld	a5,24(s7)
ffffffffc0204346:	c02006b7          	lui	a3,0xc0200
ffffffffc020434a:	2705                	addiw	a4,a4,1
ffffffffc020434c:	02eba823          	sw	a4,48(s7)
    proc->mm = mm;
ffffffffc0204350:	03743423          	sd	s7,40(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204354:	2ed7e563          	bltu	a5,a3,ffffffffc020463e <do_fork+0x3b8>
ffffffffc0204358:	000b3703          	ld	a4,0(s6)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020435c:	6814                	ld	a3,16(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020435e:	8f99                	sub	a5,a5,a4
ffffffffc0204360:	f45c                	sd	a5,168(s0)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204362:	6789                	lui	a5,0x2
ffffffffc0204364:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_softint_out_size-0x6d28>
ffffffffc0204368:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc020436a:	8626                	mv	a2,s1
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020436c:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc020436e:	87b6                	mv	a5,a3
ffffffffc0204370:	12048713          	addi	a4,s1,288
ffffffffc0204374:	6a0c                	ld	a1,16(a2)
ffffffffc0204376:	00063803          	ld	a6,0(a2)
ffffffffc020437a:	6608                	ld	a0,8(a2)
ffffffffc020437c:	eb8c                	sd	a1,16(a5)
ffffffffc020437e:	0107b023          	sd	a6,0(a5)
ffffffffc0204382:	e788                	sd	a0,8(a5)
ffffffffc0204384:	6e0c                	ld	a1,24(a2)
ffffffffc0204386:	02060613          	addi	a2,a2,32
ffffffffc020438a:	02078793          	addi	a5,a5,32
ffffffffc020438e:	feb7bc23          	sd	a1,-8(a5)
ffffffffc0204392:	fee611e3          	bne	a2,a4,ffffffffc0204374 <do_fork+0xee>
    proc->tf->gpr.a0 = 0;
ffffffffc0204396:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020439a:	20090b63          	beqz	s2,ffffffffc02045b0 <do_fork+0x32a>
ffffffffc020439e:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02043a2:	00000797          	auipc	a5,0x0
ffffffffc02043a6:	d8078793          	addi	a5,a5,-640 # ffffffffc0204122 <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02043aa:	fc14                	sd	a3,56(s0)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02043ac:	f81c                	sd	a5,48(s0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02043ae:	100027f3          	csrr	a5,sstatus
ffffffffc02043b2:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02043b4:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02043b6:	20079c63          	bnez	a5,ffffffffc02045ce <do_fork+0x348>
    if (++last_pid >= MAX_PID)
ffffffffc02043ba:	0009d517          	auipc	a0,0x9d
ffffffffc02043be:	65252503          	lw	a0,1618(a0) # ffffffffc02a1a0c <last_pid.1>
ffffffffc02043c2:	6789                	lui	a5,0x2
ffffffffc02043c4:	2505                	addiw	a0,a0,1
ffffffffc02043c6:	0009d717          	auipc	a4,0x9d
ffffffffc02043ca:	64a72323          	sw	a0,1606(a4) # ffffffffc02a1a0c <last_pid.1>
ffffffffc02043ce:	20f55f63          	bge	a0,a5,ffffffffc02045ec <do_fork+0x366>
    if (last_pid >= next_safe)
ffffffffc02043d2:	0009d797          	auipc	a5,0x9d
ffffffffc02043d6:	6367a783          	lw	a5,1590(a5) # ffffffffc02a1a08 <next_safe.0>
ffffffffc02043da:	000a2497          	auipc	s1,0xa2
ffffffffc02043de:	a4e48493          	addi	s1,s1,-1458 # ffffffffc02a5e28 <proc_list>
ffffffffc02043e2:	06f54563          	blt	a0,a5,ffffffffc020444c <do_fork+0x1c6>
ffffffffc02043e6:	000a2497          	auipc	s1,0xa2
ffffffffc02043ea:	a4248493          	addi	s1,s1,-1470 # ffffffffc02a5e28 <proc_list>
ffffffffc02043ee:	0084b883          	ld	a7,8(s1)
        next_safe = MAX_PID;
ffffffffc02043f2:	6789                	lui	a5,0x2
ffffffffc02043f4:	0009d717          	auipc	a4,0x9d
ffffffffc02043f8:	60f72a23          	sw	a5,1556(a4) # ffffffffc02a1a08 <next_safe.0>
ffffffffc02043fc:	86aa                	mv	a3,a0
ffffffffc02043fe:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc0204400:	04988063          	beq	a7,s1,ffffffffc0204440 <do_fork+0x1ba>
ffffffffc0204404:	882e                	mv	a6,a1
ffffffffc0204406:	87c6                	mv	a5,a7
ffffffffc0204408:	6609                	lui	a2,0x2
ffffffffc020440a:	a811                	j	ffffffffc020441e <do_fork+0x198>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc020440c:	00e6d663          	bge	a3,a4,ffffffffc0204418 <do_fork+0x192>
ffffffffc0204410:	00c75463          	bge	a4,a2,ffffffffc0204418 <do_fork+0x192>
                next_safe = proc->pid;
ffffffffc0204414:	863a                	mv	a2,a4
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204416:	4805                	li	a6,1
ffffffffc0204418:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc020441a:	00978d63          	beq	a5,s1,ffffffffc0204434 <do_fork+0x1ae>
            if (proc->pid == last_pid)
ffffffffc020441e:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_softint_out_size-0x6ccc>
ffffffffc0204422:	fed715e3          	bne	a4,a3,ffffffffc020440c <do_fork+0x186>
                if (++last_pid >= next_safe)
ffffffffc0204426:	2685                	addiw	a3,a3,1
ffffffffc0204428:	1cc6db63          	bge	a3,a2,ffffffffc02045fe <do_fork+0x378>
ffffffffc020442c:	679c                	ld	a5,8(a5)
ffffffffc020442e:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc0204430:	fe9797e3          	bne	a5,s1,ffffffffc020441e <do_fork+0x198>
ffffffffc0204434:	00080663          	beqz	a6,ffffffffc0204440 <do_fork+0x1ba>
ffffffffc0204438:	0009d797          	auipc	a5,0x9d
ffffffffc020443c:	5cc7a823          	sw	a2,1488(a5) # ffffffffc02a1a08 <next_safe.0>
ffffffffc0204440:	c591                	beqz	a1,ffffffffc020444c <do_fork+0x1c6>
ffffffffc0204442:	0009d797          	auipc	a5,0x9d
ffffffffc0204446:	5cd7a523          	sw	a3,1482(a5) # ffffffffc02a1a0c <last_pid.1>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc020444a:	8536                	mv	a0,a3
        proc->pid = get_pid();           
ffffffffc020444c:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020444e:	45a9                	li	a1,10
ffffffffc0204450:	1aa010ef          	jal	ffffffffc02055fa <hash32>
ffffffffc0204454:	02051793          	slli	a5,a0,0x20
ffffffffc0204458:	01c7d513          	srli	a0,a5,0x1c
ffffffffc020445c:	0009e797          	auipc	a5,0x9e
ffffffffc0204460:	9cc78793          	addi	a5,a5,-1588 # ffffffffc02a1e28 <hash_list>
ffffffffc0204464:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0204466:	6518                	ld	a4,8(a0)
ffffffffc0204468:	0d840793          	addi	a5,s0,216
ffffffffc020446c:	6490                	ld	a2,8(s1)
    prev->next = next->prev = elm;
ffffffffc020446e:	e31c                	sd	a5,0(a4)
ffffffffc0204470:	e51c                	sd	a5,8(a0)
    elm->next = next;
ffffffffc0204472:	f078                	sd	a4,224(s0)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0204474:	0c840793          	addi	a5,s0,200
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204478:	7018                	ld	a4,32(s0)
    elm->prev = prev;
ffffffffc020447a:	ec68                	sd	a0,216(s0)
    prev->next = next->prev = elm;
ffffffffc020447c:	e21c                	sd	a5,0(a2)
    proc->yptr = NULL;
ffffffffc020447e:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204482:	7b74                	ld	a3,240(a4)
ffffffffc0204484:	e49c                	sd	a5,8(s1)
    elm->next = next;
ffffffffc0204486:	e870                	sd	a2,208(s0)
    elm->prev = prev;
ffffffffc0204488:	e464                	sd	s1,200(s0)
ffffffffc020448a:	10d43023          	sd	a3,256(s0)
ffffffffc020448e:	c299                	beqz	a3,ffffffffc0204494 <do_fork+0x20e>
        proc->optr->yptr = proc;
ffffffffc0204490:	fee0                	sd	s0,248(a3)
    proc->parent->cptr = proc;
ffffffffc0204492:	7018                	ld	a4,32(s0)
    nr_process++;
ffffffffc0204494:	000a2797          	auipc	a5,0xa2
ffffffffc0204498:	a187a783          	lw	a5,-1512(a5) # ffffffffc02a5eac <nr_process>
    proc->parent->cptr = proc;
ffffffffc020449c:	fb60                	sd	s0,240(a4)
    nr_process++;
ffffffffc020449e:	2785                	addiw	a5,a5,1
ffffffffc02044a0:	000a2717          	auipc	a4,0xa2
ffffffffc02044a4:	a0f72623          	sw	a5,-1524(a4) # ffffffffc02a5eac <nr_process>
    if (flag)
ffffffffc02044a8:	14091863          	bnez	s2,ffffffffc02045f8 <do_fork+0x372>
    wakeup_proc(proc);
ffffffffc02044ac:	8522                	mv	a0,s0
ffffffffc02044ae:	751000ef          	jal	ffffffffc02053fe <wakeup_proc>
    ret = proc->pid;
ffffffffc02044b2:	4048                	lw	a0,4(s0)
ffffffffc02044b4:	79e2                	ld	s3,56(sp)
ffffffffc02044b6:	7a42                	ld	s4,48(sp)
ffffffffc02044b8:	7aa2                	ld	s5,40(sp)
ffffffffc02044ba:	7b02                	ld	s6,32(sp)
ffffffffc02044bc:	6be2                	ld	s7,24(sp)
ffffffffc02044be:	6c42                	ld	s8,16(sp)
ffffffffc02044c0:	6ca2                	ld	s9,8(sp)
}
ffffffffc02044c2:	60e6                	ld	ra,88(sp)
ffffffffc02044c4:	6446                	ld	s0,80(sp)
ffffffffc02044c6:	64a6                	ld	s1,72(sp)
ffffffffc02044c8:	6906                	ld	s2,64(sp)
ffffffffc02044ca:	6d02                	ld	s10,0(sp)
ffffffffc02044cc:	6125                	addi	sp,sp,96
ffffffffc02044ce:	8082                	ret
    if ((mm = mm_create()) == NULL)
ffffffffc02044d0:	a8eff0ef          	jal	ffffffffc020375e <mm_create>
ffffffffc02044d4:	8d2a                	mv	s10,a0
ffffffffc02044d6:	c949                	beqz	a0,ffffffffc0204568 <do_fork+0x2e2>
    if ((page = alloc_page()) == NULL)
ffffffffc02044d8:	4505                	li	a0,1
ffffffffc02044da:	a1dfd0ef          	jal	ffffffffc0201ef6 <alloc_pages>
ffffffffc02044de:	c151                	beqz	a0,ffffffffc0204562 <do_fork+0x2dc>
    return page - pages + nbase;
ffffffffc02044e0:	0009b703          	ld	a4,0(s3)
    return KADDR(page2pa(page));
ffffffffc02044e4:	000ab783          	ld	a5,0(s5)
    return page - pages + nbase;
ffffffffc02044e8:	40e506b3          	sub	a3,a0,a4
ffffffffc02044ec:	8699                	srai	a3,a3,0x6
ffffffffc02044ee:	96e6                	add	a3,a3,s9
    return KADDR(page2pa(page));
ffffffffc02044f0:	0186fc33          	and	s8,a3,s8
    return page2ppn(page) << PGSHIFT;
ffffffffc02044f4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02044f6:	1afc7f63          	bgeu	s8,a5,ffffffffc02046b4 <do_fork+0x42e>
ffffffffc02044fa:	000b3783          	ld	a5,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02044fe:	000a2597          	auipc	a1,0xa2
ffffffffc0204502:	9825b583          	ld	a1,-1662(a1) # ffffffffc02a5e80 <boot_pgdir_va>
ffffffffc0204506:	6605                	lui	a2,0x1
ffffffffc0204508:	00f68c33          	add	s8,a3,a5
ffffffffc020450c:	8562                	mv	a0,s8
ffffffffc020450e:	594010ef          	jal	ffffffffc0205aa2 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc0204512:	038b8c93          	addi	s9,s7,56
    mm->pgdir = pgdir;
ffffffffc0204516:	018d3c23          	sd	s8,24(s10)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020451a:	4c05                	li	s8,1
ffffffffc020451c:	418cb7af          	amoor.d	a5,s8,(s9)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc0204520:	03f79713          	slli	a4,a5,0x3f
ffffffffc0204524:	03f75793          	srli	a5,a4,0x3f
ffffffffc0204528:	cb91                	beqz	a5,ffffffffc020453c <do_fork+0x2b6>
    {
        schedule();
ffffffffc020452a:	769000ef          	jal	ffffffffc0205492 <schedule>
ffffffffc020452e:	418cb7af          	amoor.d	a5,s8,(s9)
    while (!try_lock(lock))
ffffffffc0204532:	03f79713          	slli	a4,a5,0x3f
ffffffffc0204536:	03f75793          	srli	a5,a4,0x3f
ffffffffc020453a:	fbe5                	bnez	a5,ffffffffc020452a <do_fork+0x2a4>
        ret = dup_mmap(mm, oldmm);
ffffffffc020453c:	85de                	mv	a1,s7
ffffffffc020453e:	856a                	mv	a0,s10
ffffffffc0204540:	e94ff0ef          	jal	ffffffffc0203bd4 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204544:	57f9                	li	a5,-2
ffffffffc0204546:	60fcb7af          	amoand.d	a5,a5,(s9)
ffffffffc020454a:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc020454c:	12078263          	beqz	a5,ffffffffc0204670 <do_fork+0x3ea>
    if ((mm = mm_create()) == NULL)
ffffffffc0204550:	8bea                	mv	s7,s10
    if (ret != 0)
ffffffffc0204552:	de0506e3          	beqz	a0,ffffffffc020433e <do_fork+0xb8>
    exit_mmap(mm);
ffffffffc0204556:	856a                	mv	a0,s10
ffffffffc0204558:	f14ff0ef          	jal	ffffffffc0203c6c <exit_mmap>
    put_pgdir(mm);
ffffffffc020455c:	856a                	mv	a0,s10
ffffffffc020455e:	c51ff0ef          	jal	ffffffffc02041ae <put_pgdir>
    mm_destroy(mm);
ffffffffc0204562:	856a                	mv	a0,s10
ffffffffc0204564:	d52ff0ef          	jal	ffffffffc0203ab6 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204568:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc020456a:	c02007b7          	lui	a5,0xc0200
ffffffffc020456e:	0ef6e563          	bltu	a3,a5,ffffffffc0204658 <do_fork+0x3d2>
ffffffffc0204572:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage)
ffffffffc0204576:	000ab703          	ld	a4,0(s5)
    return pa2page(PADDR(kva));
ffffffffc020457a:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc020457e:	83b1                	srli	a5,a5,0xc
ffffffffc0204580:	08e7f763          	bgeu	a5,a4,ffffffffc020460e <do_fork+0x388>
    return &pages[PPN(pa) - nbase];
ffffffffc0204584:	000a3703          	ld	a4,0(s4)
ffffffffc0204588:	0009b503          	ld	a0,0(s3)
ffffffffc020458c:	4589                	li	a1,2
ffffffffc020458e:	8f99                	sub	a5,a5,a4
ffffffffc0204590:	079a                	slli	a5,a5,0x6
ffffffffc0204592:	953e                	add	a0,a0,a5
ffffffffc0204594:	99dfd0ef          	jal	ffffffffc0201f30 <free_pages>
}
ffffffffc0204598:	79e2                	ld	s3,56(sp)
ffffffffc020459a:	7a42                	ld	s4,48(sp)
ffffffffc020459c:	7aa2                	ld	s5,40(sp)
ffffffffc020459e:	6be2                	ld	s7,24(sp)
ffffffffc02045a0:	6c42                	ld	s8,16(sp)
ffffffffc02045a2:	6ca2                	ld	s9,8(sp)
    kfree(proc);
ffffffffc02045a4:	8522                	mv	a0,s0
ffffffffc02045a6:	835fd0ef          	jal	ffffffffc0201dda <kfree>
ffffffffc02045aa:	7b02                	ld	s6,32(sp)
    ret = -E_NO_MEM;
ffffffffc02045ac:	5571                	li	a0,-4
    return ret;
ffffffffc02045ae:	bf11                	j	ffffffffc02044c2 <do_fork+0x23c>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02045b0:	8936                	mv	s2,a3
ffffffffc02045b2:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02045b6:	00000797          	auipc	a5,0x0
ffffffffc02045ba:	b6c78793          	addi	a5,a5,-1172 # ffffffffc0204122 <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02045be:	fc14                	sd	a3,56(s0)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02045c0:	f81c                	sd	a5,48(s0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02045c2:	100027f3          	csrr	a5,sstatus
ffffffffc02045c6:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02045c8:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02045ca:	de0788e3          	beqz	a5,ffffffffc02043ba <do_fork+0x134>
        intr_disable();
ffffffffc02045ce:	b36fc0ef          	jal	ffffffffc0200904 <intr_disable>
    if (++last_pid >= MAX_PID)
ffffffffc02045d2:	0009d517          	auipc	a0,0x9d
ffffffffc02045d6:	43a52503          	lw	a0,1082(a0) # ffffffffc02a1a0c <last_pid.1>
ffffffffc02045da:	6789                	lui	a5,0x2
        return 1;
ffffffffc02045dc:	4905                	li	s2,1
ffffffffc02045de:	2505                	addiw	a0,a0,1
ffffffffc02045e0:	0009d717          	auipc	a4,0x9d
ffffffffc02045e4:	42a72623          	sw	a0,1068(a4) # ffffffffc02a1a0c <last_pid.1>
ffffffffc02045e8:	def545e3          	blt	a0,a5,ffffffffc02043d2 <do_fork+0x14c>
        last_pid = 1;
ffffffffc02045ec:	4505                	li	a0,1
ffffffffc02045ee:	0009d797          	auipc	a5,0x9d
ffffffffc02045f2:	40a7af23          	sw	a0,1054(a5) # ffffffffc02a1a0c <last_pid.1>
        goto inside;
ffffffffc02045f6:	bbc5                	j	ffffffffc02043e6 <do_fork+0x160>
        intr_enable();
ffffffffc02045f8:	b06fc0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02045fc:	bd45                	j	ffffffffc02044ac <do_fork+0x226>
                    if (last_pid >= MAX_PID)
ffffffffc02045fe:	6789                	lui	a5,0x2
ffffffffc0204600:	00f6c363          	blt	a3,a5,ffffffffc0204606 <do_fork+0x380>
                        last_pid = 1;
ffffffffc0204604:	4685                	li	a3,1
                    goto repeat;
ffffffffc0204606:	4585                	li	a1,1
ffffffffc0204608:	bbe5                	j	ffffffffc0204400 <do_fork+0x17a>
    int ret = -E_NO_FREE_PROC;
ffffffffc020460a:	556d                	li	a0,-5
}
ffffffffc020460c:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc020460e:	00002617          	auipc	a2,0x2
ffffffffc0204612:	2ea60613          	addi	a2,a2,746 # ffffffffc02068f8 <etext+0xe3e>
ffffffffc0204616:	06900593          	li	a1,105
ffffffffc020461a:	00002517          	auipc	a0,0x2
ffffffffc020461e:	23650513          	addi	a0,a0,566 # ffffffffc0206850 <etext+0xd96>
ffffffffc0204622:	e25fb0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc0204626:	00002617          	auipc	a2,0x2
ffffffffc020462a:	20260613          	addi	a2,a2,514 # ffffffffc0206828 <etext+0xd6e>
ffffffffc020462e:	07100593          	li	a1,113
ffffffffc0204632:	00002517          	auipc	a0,0x2
ffffffffc0204636:	21e50513          	addi	a0,a0,542 # ffffffffc0206850 <etext+0xd96>
ffffffffc020463a:	e0dfb0ef          	jal	ffffffffc0200446 <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020463e:	86be                	mv	a3,a5
ffffffffc0204640:	00002617          	auipc	a2,0x2
ffffffffc0204644:	29060613          	addi	a2,a2,656 # ffffffffc02068d0 <etext+0xe16>
ffffffffc0204648:	17f00593          	li	a1,383
ffffffffc020464c:	00003517          	auipc	a0,0x3
ffffffffc0204650:	cd450513          	addi	a0,a0,-812 # ffffffffc0207320 <etext+0x1866>
ffffffffc0204654:	df3fb0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0204658:	00002617          	auipc	a2,0x2
ffffffffc020465c:	27860613          	addi	a2,a2,632 # ffffffffc02068d0 <etext+0xe16>
ffffffffc0204660:	07700593          	li	a1,119
ffffffffc0204664:	00002517          	auipc	a0,0x2
ffffffffc0204668:	1ec50513          	addi	a0,a0,492 # ffffffffc0206850 <etext+0xd96>
ffffffffc020466c:	ddbfb0ef          	jal	ffffffffc0200446 <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc0204670:	00003617          	auipc	a2,0x3
ffffffffc0204674:	ce860613          	addi	a2,a2,-792 # ffffffffc0207358 <etext+0x189e>
ffffffffc0204678:	03f00593          	li	a1,63
ffffffffc020467c:	00003517          	auipc	a0,0x3
ffffffffc0204680:	cec50513          	addi	a0,a0,-788 # ffffffffc0207368 <etext+0x18ae>
ffffffffc0204684:	dc3fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(current->wait_state == 0);
ffffffffc0204688:	00003697          	auipc	a3,0x3
ffffffffc020468c:	cb068693          	addi	a3,a3,-848 # ffffffffc0207338 <etext+0x187e>
ffffffffc0204690:	00002617          	auipc	a2,0x2
ffffffffc0204694:	bd860613          	addi	a2,a2,-1064 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0204698:	1ac00593          	li	a1,428
ffffffffc020469c:	00003517          	auipc	a0,0x3
ffffffffc02046a0:	c8450513          	addi	a0,a0,-892 # ffffffffc0207320 <etext+0x1866>
ffffffffc02046a4:	fc4e                	sd	s3,56(sp)
ffffffffc02046a6:	f852                	sd	s4,48(sp)
ffffffffc02046a8:	f456                	sd	s5,40(sp)
ffffffffc02046aa:	ec5e                	sd	s7,24(sp)
ffffffffc02046ac:	e862                	sd	s8,16(sp)
ffffffffc02046ae:	e466                	sd	s9,8(sp)
ffffffffc02046b0:	d97fb0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc02046b4:	00002617          	auipc	a2,0x2
ffffffffc02046b8:	17460613          	addi	a2,a2,372 # ffffffffc0206828 <etext+0xd6e>
ffffffffc02046bc:	07100593          	li	a1,113
ffffffffc02046c0:	00002517          	auipc	a0,0x2
ffffffffc02046c4:	19050513          	addi	a0,a0,400 # ffffffffc0206850 <etext+0xd96>
ffffffffc02046c8:	d7ffb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02046cc <kernel_thread>:
{
ffffffffc02046cc:	7129                	addi	sp,sp,-320
ffffffffc02046ce:	fa22                	sd	s0,304(sp)
ffffffffc02046d0:	f626                	sd	s1,296(sp)
ffffffffc02046d2:	f24a                	sd	s2,288(sp)
ffffffffc02046d4:	842a                	mv	s0,a0
ffffffffc02046d6:	84ae                	mv	s1,a1
ffffffffc02046d8:	8932                	mv	s2,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02046da:	850a                	mv	a0,sp
ffffffffc02046dc:	12000613          	li	a2,288
ffffffffc02046e0:	4581                	li	a1,0
{
ffffffffc02046e2:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02046e4:	3ac010ef          	jal	ffffffffc0205a90 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02046e8:	e0a2                	sd	s0,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02046ea:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02046ec:	100027f3          	csrr	a5,sstatus
ffffffffc02046f0:	edd7f793          	andi	a5,a5,-291
ffffffffc02046f4:	1207e793          	ori	a5,a5,288
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02046f8:	860a                	mv	a2,sp
ffffffffc02046fa:	10096513          	ori	a0,s2,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02046fe:	00000717          	auipc	a4,0x0
ffffffffc0204702:	9aa70713          	addi	a4,a4,-1622 # ffffffffc02040a8 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204706:	4581                	li	a1,0
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204708:	e23e                	sd	a5,256(sp)
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020470a:	e63a                	sd	a4,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020470c:	b7bff0ef          	jal	ffffffffc0204286 <do_fork>
}
ffffffffc0204710:	70f2                	ld	ra,312(sp)
ffffffffc0204712:	7452                	ld	s0,304(sp)
ffffffffc0204714:	74b2                	ld	s1,296(sp)
ffffffffc0204716:	7912                	ld	s2,288(sp)
ffffffffc0204718:	6131                	addi	sp,sp,320
ffffffffc020471a:	8082                	ret

ffffffffc020471c <do_exit>:
{
ffffffffc020471c:	7179                	addi	sp,sp,-48
ffffffffc020471e:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc0204720:	000a1417          	auipc	s0,0xa1
ffffffffc0204724:	79040413          	addi	s0,s0,1936 # ffffffffc02a5eb0 <current>
ffffffffc0204728:	601c                	ld	a5,0(s0)
ffffffffc020472a:	000a1717          	auipc	a4,0xa1
ffffffffc020472e:	79673703          	ld	a4,1942(a4) # ffffffffc02a5ec0 <idleproc>
{
ffffffffc0204732:	f406                	sd	ra,40(sp)
ffffffffc0204734:	ec26                	sd	s1,24(sp)
    if (current == idleproc)
ffffffffc0204736:	0ce78b63          	beq	a5,a4,ffffffffc020480c <do_exit+0xf0>
    if (current == initproc)
ffffffffc020473a:	000a1497          	auipc	s1,0xa1
ffffffffc020473e:	77e48493          	addi	s1,s1,1918 # ffffffffc02a5eb8 <initproc>
ffffffffc0204742:	6098                	ld	a4,0(s1)
ffffffffc0204744:	e84a                	sd	s2,16(sp)
ffffffffc0204746:	0ee78a63          	beq	a5,a4,ffffffffc020483a <do_exit+0x11e>
ffffffffc020474a:	892a                	mv	s2,a0
    struct mm_struct *mm = current->mm;
ffffffffc020474c:	7788                	ld	a0,40(a5)
    if (mm != NULL)
ffffffffc020474e:	c115                	beqz	a0,ffffffffc0204772 <do_exit+0x56>
ffffffffc0204750:	000a1797          	auipc	a5,0xa1
ffffffffc0204754:	7287b783          	ld	a5,1832(a5) # ffffffffc02a5e78 <boot_pgdir_pa>
ffffffffc0204758:	577d                	li	a4,-1
ffffffffc020475a:	177e                	slli	a4,a4,0x3f
ffffffffc020475c:	83b1                	srli	a5,a5,0xc
ffffffffc020475e:	8fd9                	or	a5,a5,a4
ffffffffc0204760:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc0204764:	591c                	lw	a5,48(a0)
ffffffffc0204766:	37fd                	addiw	a5,a5,-1
ffffffffc0204768:	d91c                	sw	a5,48(a0)
        if (mm_count_dec(mm) == 0)
ffffffffc020476a:	cfd5                	beqz	a5,ffffffffc0204826 <do_exit+0x10a>
        current->mm = NULL;
ffffffffc020476c:	601c                	ld	a5,0(s0)
ffffffffc020476e:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc0204772:	470d                	li	a4,3
    current->exit_code = error_code;
ffffffffc0204774:	0f27a423          	sw	s2,232(a5)
    current->state = PROC_ZOMBIE;
ffffffffc0204778:	c398                	sw	a4,0(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020477a:	100027f3          	csrr	a5,sstatus
ffffffffc020477e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204780:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204782:	ebe1                	bnez	a5,ffffffffc0204852 <do_exit+0x136>
        proc = current->parent;
ffffffffc0204784:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204786:	800007b7          	lui	a5,0x80000
ffffffffc020478a:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_COW_out_size+0xffffffff7fff5be1>
        proc = current->parent;
ffffffffc020478c:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc020478e:	0ec52703          	lw	a4,236(a0)
ffffffffc0204792:	0cf70463          	beq	a4,a5,ffffffffc020485a <do_exit+0x13e>
        while (current->cptr != NULL)
ffffffffc0204796:	6018                	ld	a4,0(s0)
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204798:	800005b7          	lui	a1,0x80000
ffffffffc020479c:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_COW_out_size+0xffffffff7fff5be1>
        while (current->cptr != NULL)
ffffffffc020479e:	7b7c                	ld	a5,240(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc02047a0:	460d                	li	a2,3
        while (current->cptr != NULL)
ffffffffc02047a2:	e789                	bnez	a5,ffffffffc02047ac <do_exit+0x90>
ffffffffc02047a4:	a83d                	j	ffffffffc02047e2 <do_exit+0xc6>
ffffffffc02047a6:	6018                	ld	a4,0(s0)
ffffffffc02047a8:	7b7c                	ld	a5,240(a4)
ffffffffc02047aa:	cf85                	beqz	a5,ffffffffc02047e2 <do_exit+0xc6>
            current->cptr = proc->optr;
ffffffffc02047ac:	1007b683          	ld	a3,256(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02047b0:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc02047b2:	fb74                	sd	a3,240(a4)
            proc->yptr = NULL;
ffffffffc02047b4:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02047b8:	7978                	ld	a4,240(a0)
ffffffffc02047ba:	10e7b023          	sd	a4,256(a5)
ffffffffc02047be:	c311                	beqz	a4,ffffffffc02047c2 <do_exit+0xa6>
                initproc->cptr->yptr = proc;
ffffffffc02047c0:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc02047c2:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc02047c4:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc02047c6:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc02047c8:	fcc71fe3          	bne	a4,a2,ffffffffc02047a6 <do_exit+0x8a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc02047cc:	0ec52783          	lw	a5,236(a0)
ffffffffc02047d0:	fcb79be3          	bne	a5,a1,ffffffffc02047a6 <do_exit+0x8a>
                    wakeup_proc(initproc);
ffffffffc02047d4:	42b000ef          	jal	ffffffffc02053fe <wakeup_proc>
ffffffffc02047d8:	800005b7          	lui	a1,0x80000
ffffffffc02047dc:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_COW_out_size+0xffffffff7fff5be1>
ffffffffc02047de:	460d                	li	a2,3
ffffffffc02047e0:	b7d9                	j	ffffffffc02047a6 <do_exit+0x8a>
    if (flag)
ffffffffc02047e2:	02091263          	bnez	s2,ffffffffc0204806 <do_exit+0xea>
    schedule();
ffffffffc02047e6:	4ad000ef          	jal	ffffffffc0205492 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc02047ea:	601c                	ld	a5,0(s0)
ffffffffc02047ec:	00003617          	auipc	a2,0x3
ffffffffc02047f0:	bb460613          	addi	a2,a2,-1100 # ffffffffc02073a0 <etext+0x18e6>
ffffffffc02047f4:	20500593          	li	a1,517
ffffffffc02047f8:	43d4                	lw	a3,4(a5)
ffffffffc02047fa:	00003517          	auipc	a0,0x3
ffffffffc02047fe:	b2650513          	addi	a0,a0,-1242 # ffffffffc0207320 <etext+0x1866>
ffffffffc0204802:	c45fb0ef          	jal	ffffffffc0200446 <__panic>
        intr_enable();
ffffffffc0204806:	8f8fc0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc020480a:	bff1                	j	ffffffffc02047e6 <do_exit+0xca>
        panic("idleproc exit.\n");
ffffffffc020480c:	00003617          	auipc	a2,0x3
ffffffffc0204810:	b7460613          	addi	a2,a2,-1164 # ffffffffc0207380 <etext+0x18c6>
ffffffffc0204814:	1d100593          	li	a1,465
ffffffffc0204818:	00003517          	auipc	a0,0x3
ffffffffc020481c:	b0850513          	addi	a0,a0,-1272 # ffffffffc0207320 <etext+0x1866>
ffffffffc0204820:	e84a                	sd	s2,16(sp)
ffffffffc0204822:	c25fb0ef          	jal	ffffffffc0200446 <__panic>
            exit_mmap(mm);
ffffffffc0204826:	e42a                	sd	a0,8(sp)
ffffffffc0204828:	c44ff0ef          	jal	ffffffffc0203c6c <exit_mmap>
            put_pgdir(mm);
ffffffffc020482c:	6522                	ld	a0,8(sp)
ffffffffc020482e:	981ff0ef          	jal	ffffffffc02041ae <put_pgdir>
            mm_destroy(mm);
ffffffffc0204832:	6522                	ld	a0,8(sp)
ffffffffc0204834:	a82ff0ef          	jal	ffffffffc0203ab6 <mm_destroy>
ffffffffc0204838:	bf15                	j	ffffffffc020476c <do_exit+0x50>
        panic("initproc exit.\n");
ffffffffc020483a:	00003617          	auipc	a2,0x3
ffffffffc020483e:	b5660613          	addi	a2,a2,-1194 # ffffffffc0207390 <etext+0x18d6>
ffffffffc0204842:	1d500593          	li	a1,469
ffffffffc0204846:	00003517          	auipc	a0,0x3
ffffffffc020484a:	ada50513          	addi	a0,a0,-1318 # ffffffffc0207320 <etext+0x1866>
ffffffffc020484e:	bf9fb0ef          	jal	ffffffffc0200446 <__panic>
        intr_disable();
ffffffffc0204852:	8b2fc0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0204856:	4905                	li	s2,1
ffffffffc0204858:	b735                	j	ffffffffc0204784 <do_exit+0x68>
            wakeup_proc(proc);
ffffffffc020485a:	3a5000ef          	jal	ffffffffc02053fe <wakeup_proc>
ffffffffc020485e:	bf25                	j	ffffffffc0204796 <do_exit+0x7a>

ffffffffc0204860 <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc0204860:	7179                	addi	sp,sp,-48
ffffffffc0204862:	ec26                	sd	s1,24(sp)
ffffffffc0204864:	e84a                	sd	s2,16(sp)
ffffffffc0204866:	e44e                	sd	s3,8(sp)
ffffffffc0204868:	f406                	sd	ra,40(sp)
ffffffffc020486a:	f022                	sd	s0,32(sp)
ffffffffc020486c:	84aa                	mv	s1,a0
ffffffffc020486e:	892e                	mv	s2,a1
ffffffffc0204870:	000a1997          	auipc	s3,0xa1
ffffffffc0204874:	64098993          	addi	s3,s3,1600 # ffffffffc02a5eb0 <current>
    if (pid != 0)
ffffffffc0204878:	cd19                	beqz	a0,ffffffffc0204896 <do_wait.part.0+0x36>
    if (0 < pid && pid < MAX_PID)
ffffffffc020487a:	6789                	lui	a5,0x2
ffffffffc020487c:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6c0a>
ffffffffc020487e:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204882:	12e7f563          	bgeu	a5,a4,ffffffffc02049ac <do_wait.part.0+0x14c>
}
ffffffffc0204886:	70a2                	ld	ra,40(sp)
ffffffffc0204888:	7402                	ld	s0,32(sp)
ffffffffc020488a:	64e2                	ld	s1,24(sp)
ffffffffc020488c:	6942                	ld	s2,16(sp)
ffffffffc020488e:	69a2                	ld	s3,8(sp)
    return -E_BAD_PROC;
ffffffffc0204890:	5579                	li	a0,-2
}
ffffffffc0204892:	6145                	addi	sp,sp,48
ffffffffc0204894:	8082                	ret
        proc = current->cptr;
ffffffffc0204896:	0009b703          	ld	a4,0(s3)
ffffffffc020489a:	7b60                	ld	s0,240(a4)
        for (; proc != NULL; proc = proc->optr)
ffffffffc020489c:	d46d                	beqz	s0,ffffffffc0204886 <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020489e:	468d                	li	a3,3
ffffffffc02048a0:	a021                	j	ffffffffc02048a8 <do_wait.part.0+0x48>
        for (; proc != NULL; proc = proc->optr)
ffffffffc02048a2:	10043403          	ld	s0,256(s0)
ffffffffc02048a6:	c075                	beqz	s0,ffffffffc020498a <do_wait.part.0+0x12a>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02048a8:	401c                	lw	a5,0(s0)
ffffffffc02048aa:	fed79ce3          	bne	a5,a3,ffffffffc02048a2 <do_wait.part.0+0x42>
    if (proc == idleproc || proc == initproc)
ffffffffc02048ae:	000a1797          	auipc	a5,0xa1
ffffffffc02048b2:	6127b783          	ld	a5,1554(a5) # ffffffffc02a5ec0 <idleproc>
ffffffffc02048b6:	14878263          	beq	a5,s0,ffffffffc02049fa <do_wait.part.0+0x19a>
ffffffffc02048ba:	000a1797          	auipc	a5,0xa1
ffffffffc02048be:	5fe7b783          	ld	a5,1534(a5) # ffffffffc02a5eb8 <initproc>
ffffffffc02048c2:	12f40c63          	beq	s0,a5,ffffffffc02049fa <do_wait.part.0+0x19a>
    if (code_store != NULL)
ffffffffc02048c6:	00090663          	beqz	s2,ffffffffc02048d2 <do_wait.part.0+0x72>
        *code_store = proc->exit_code;
ffffffffc02048ca:	0e842783          	lw	a5,232(s0)
ffffffffc02048ce:	00f92023          	sw	a5,0(s2)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02048d2:	100027f3          	csrr	a5,sstatus
ffffffffc02048d6:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02048d8:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02048da:	10079963          	bnez	a5,ffffffffc02049ec <do_wait.part.0+0x18c>
    __list_del(listelm->prev, listelm->next);
ffffffffc02048de:	6c74                	ld	a3,216(s0)
ffffffffc02048e0:	7078                	ld	a4,224(s0)
    if (proc->optr != NULL)
ffffffffc02048e2:	10043783          	ld	a5,256(s0)
    prev->next = next;
ffffffffc02048e6:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc02048e8:	e314                	sd	a3,0(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc02048ea:	6474                	ld	a3,200(s0)
ffffffffc02048ec:	6878                	ld	a4,208(s0)
    prev->next = next;
ffffffffc02048ee:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc02048f0:	e314                	sd	a3,0(a4)
ffffffffc02048f2:	c789                	beqz	a5,ffffffffc02048fc <do_wait.part.0+0x9c>
        proc->optr->yptr = proc->yptr;
ffffffffc02048f4:	7c78                	ld	a4,248(s0)
ffffffffc02048f6:	fff8                	sd	a4,248(a5)
        proc->yptr->optr = proc->optr;
ffffffffc02048f8:	10043783          	ld	a5,256(s0)
    if (proc->yptr != NULL)
ffffffffc02048fc:	7c78                	ld	a4,248(s0)
ffffffffc02048fe:	c36d                	beqz	a4,ffffffffc02049e0 <do_wait.part.0+0x180>
        proc->yptr->optr = proc->optr;
ffffffffc0204900:	10f73023          	sd	a5,256(a4)
    nr_process--;
ffffffffc0204904:	000a1797          	auipc	a5,0xa1
ffffffffc0204908:	5a87a783          	lw	a5,1448(a5) # ffffffffc02a5eac <nr_process>
ffffffffc020490c:	37fd                	addiw	a5,a5,-1
ffffffffc020490e:	000a1717          	auipc	a4,0xa1
ffffffffc0204912:	58f72f23          	sw	a5,1438(a4) # ffffffffc02a5eac <nr_process>
    if (flag)
ffffffffc0204916:	e271                	bnez	a2,ffffffffc02049da <do_wait.part.0+0x17a>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204918:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc020491a:	c02007b7          	lui	a5,0xc0200
ffffffffc020491e:	10f6e663          	bltu	a3,a5,ffffffffc0204a2a <do_wait.part.0+0x1ca>
ffffffffc0204922:	000a1717          	auipc	a4,0xa1
ffffffffc0204926:	56673703          	ld	a4,1382(a4) # ffffffffc02a5e88 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc020492a:	000a1797          	auipc	a5,0xa1
ffffffffc020492e:	5667b783          	ld	a5,1382(a5) # ffffffffc02a5e90 <npage>
    return pa2page(PADDR(kva));
ffffffffc0204932:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc0204934:	82b1                	srli	a3,a3,0xc
ffffffffc0204936:	0cf6fe63          	bgeu	a3,a5,ffffffffc0204a12 <do_wait.part.0+0x1b2>
    return &pages[PPN(pa) - nbase];
ffffffffc020493a:	00003797          	auipc	a5,0x3
ffffffffc020493e:	3de7b783          	ld	a5,990(a5) # ffffffffc0207d18 <nbase>
ffffffffc0204942:	000a1517          	auipc	a0,0xa1
ffffffffc0204946:	55653503          	ld	a0,1366(a0) # ffffffffc02a5e98 <pages>
ffffffffc020494a:	4589                	li	a1,2
ffffffffc020494c:	8e9d                	sub	a3,a3,a5
ffffffffc020494e:	069a                	slli	a3,a3,0x6
ffffffffc0204950:	9536                	add	a0,a0,a3
ffffffffc0204952:	ddefd0ef          	jal	ffffffffc0201f30 <free_pages>
    kfree(proc);
ffffffffc0204956:	8522                	mv	a0,s0
ffffffffc0204958:	c82fd0ef          	jal	ffffffffc0201dda <kfree>
}
ffffffffc020495c:	70a2                	ld	ra,40(sp)
ffffffffc020495e:	7402                	ld	s0,32(sp)
ffffffffc0204960:	64e2                	ld	s1,24(sp)
ffffffffc0204962:	6942                	ld	s2,16(sp)
ffffffffc0204964:	69a2                	ld	s3,8(sp)
    return 0;
ffffffffc0204966:	4501                	li	a0,0
}
ffffffffc0204968:	6145                	addi	sp,sp,48
ffffffffc020496a:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc020496c:	000a1997          	auipc	s3,0xa1
ffffffffc0204970:	54498993          	addi	s3,s3,1348 # ffffffffc02a5eb0 <current>
ffffffffc0204974:	0009b703          	ld	a4,0(s3)
ffffffffc0204978:	f487b683          	ld	a3,-184(a5)
ffffffffc020497c:	f0e695e3          	bne	a3,a4,ffffffffc0204886 <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204980:	f287a603          	lw	a2,-216(a5)
ffffffffc0204984:	468d                	li	a3,3
ffffffffc0204986:	06d60063          	beq	a2,a3,ffffffffc02049e6 <do_wait.part.0+0x186>
        current->wait_state = WT_CHILD;
ffffffffc020498a:	800007b7          	lui	a5,0x80000
ffffffffc020498e:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_COW_out_size+0xffffffff7fff5be1>
        current->state = PROC_SLEEPING;
ffffffffc0204990:	4685                	li	a3,1
        current->wait_state = WT_CHILD;
ffffffffc0204992:	0ef72623          	sw	a5,236(a4)
        current->state = PROC_SLEEPING;
ffffffffc0204996:	c314                	sw	a3,0(a4)
        schedule();
ffffffffc0204998:	2fb000ef          	jal	ffffffffc0205492 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc020499c:	0009b783          	ld	a5,0(s3)
ffffffffc02049a0:	0b07a783          	lw	a5,176(a5)
ffffffffc02049a4:	8b85                	andi	a5,a5,1
ffffffffc02049a6:	e7b9                	bnez	a5,ffffffffc02049f4 <do_wait.part.0+0x194>
    if (pid != 0)
ffffffffc02049a8:	ee0487e3          	beqz	s1,ffffffffc0204896 <do_wait.part.0+0x36>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02049ac:	45a9                	li	a1,10
ffffffffc02049ae:	8526                	mv	a0,s1
ffffffffc02049b0:	44b000ef          	jal	ffffffffc02055fa <hash32>
ffffffffc02049b4:	02051793          	slli	a5,a0,0x20
ffffffffc02049b8:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02049bc:	0009d797          	auipc	a5,0x9d
ffffffffc02049c0:	46c78793          	addi	a5,a5,1132 # ffffffffc02a1e28 <hash_list>
ffffffffc02049c4:	953e                	add	a0,a0,a5
ffffffffc02049c6:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc02049c8:	a029                	j	ffffffffc02049d2 <do_wait.part.0+0x172>
            if (proc->pid == pid)
ffffffffc02049ca:	f2c7a703          	lw	a4,-212(a5)
ffffffffc02049ce:	f8970fe3          	beq	a4,s1,ffffffffc020496c <do_wait.part.0+0x10c>
    return listelm->next;
ffffffffc02049d2:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02049d4:	fef51be3          	bne	a0,a5,ffffffffc02049ca <do_wait.part.0+0x16a>
ffffffffc02049d8:	b57d                	j	ffffffffc0204886 <do_wait.part.0+0x26>
        intr_enable();
ffffffffc02049da:	f25fb0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02049de:	bf2d                	j	ffffffffc0204918 <do_wait.part.0+0xb8>
        proc->parent->cptr = proc->optr;
ffffffffc02049e0:	7018                	ld	a4,32(s0)
ffffffffc02049e2:	fb7c                	sd	a5,240(a4)
ffffffffc02049e4:	b705                	j	ffffffffc0204904 <do_wait.part.0+0xa4>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02049e6:	f2878413          	addi	s0,a5,-216
ffffffffc02049ea:	b5d1                	j	ffffffffc02048ae <do_wait.part.0+0x4e>
        intr_disable();
ffffffffc02049ec:	f19fb0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc02049f0:	4605                	li	a2,1
ffffffffc02049f2:	b5f5                	j	ffffffffc02048de <do_wait.part.0+0x7e>
            do_exit(-E_KILLED);
ffffffffc02049f4:	555d                	li	a0,-9
ffffffffc02049f6:	d27ff0ef          	jal	ffffffffc020471c <do_exit>
        panic("wait idleproc or initproc.\n");
ffffffffc02049fa:	00003617          	auipc	a2,0x3
ffffffffc02049fe:	9c660613          	addi	a2,a2,-1594 # ffffffffc02073c0 <etext+0x1906>
ffffffffc0204a02:	32c00593          	li	a1,812
ffffffffc0204a06:	00003517          	auipc	a0,0x3
ffffffffc0204a0a:	91a50513          	addi	a0,a0,-1766 # ffffffffc0207320 <etext+0x1866>
ffffffffc0204a0e:	a39fb0ef          	jal	ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204a12:	00002617          	auipc	a2,0x2
ffffffffc0204a16:	ee660613          	addi	a2,a2,-282 # ffffffffc02068f8 <etext+0xe3e>
ffffffffc0204a1a:	06900593          	li	a1,105
ffffffffc0204a1e:	00002517          	auipc	a0,0x2
ffffffffc0204a22:	e3250513          	addi	a0,a0,-462 # ffffffffc0206850 <etext+0xd96>
ffffffffc0204a26:	a21fb0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0204a2a:	00002617          	auipc	a2,0x2
ffffffffc0204a2e:	ea660613          	addi	a2,a2,-346 # ffffffffc02068d0 <etext+0xe16>
ffffffffc0204a32:	07700593          	li	a1,119
ffffffffc0204a36:	00002517          	auipc	a0,0x2
ffffffffc0204a3a:	e1a50513          	addi	a0,a0,-486 # ffffffffc0206850 <etext+0xd96>
ffffffffc0204a3e:	a09fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0204a42 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0204a42:	1141                	addi	sp,sp,-16
ffffffffc0204a44:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0204a46:	d22fd0ef          	jal	ffffffffc0201f68 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc0204a4a:	ae6fd0ef          	jal	ffffffffc0201d30 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc0204a4e:	4601                	li	a2,0
ffffffffc0204a50:	4581                	li	a1,0
ffffffffc0204a52:	fffff517          	auipc	a0,0xfffff
ffffffffc0204a56:	6de50513          	addi	a0,a0,1758 # ffffffffc0204130 <user_main>
ffffffffc0204a5a:	c73ff0ef          	jal	ffffffffc02046cc <kernel_thread>
    if (pid <= 0)
ffffffffc0204a5e:	00a04563          	bgtz	a0,ffffffffc0204a68 <init_main+0x26>
ffffffffc0204a62:	a055                	j	ffffffffc0204b06 <init_main+0xc4>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc0204a64:	22f000ef          	jal	ffffffffc0205492 <schedule>
    if (code_store != NULL)
ffffffffc0204a68:	4581                	li	a1,0
ffffffffc0204a6a:	4501                	li	a0,0
ffffffffc0204a6c:	df5ff0ef          	jal	ffffffffc0204860 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc0204a70:	d975                	beqz	a0,ffffffffc0204a64 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0204a72:	00003517          	auipc	a0,0x3
ffffffffc0204a76:	98e50513          	addi	a0,a0,-1650 # ffffffffc0207400 <etext+0x1946>
ffffffffc0204a7a:	f1afb0ef          	jal	ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204a7e:	000a1797          	auipc	a5,0xa1
ffffffffc0204a82:	43a7b783          	ld	a5,1082(a5) # ffffffffc02a5eb8 <initproc>
ffffffffc0204a86:	7bf8                	ld	a4,240(a5)
ffffffffc0204a88:	ef39                	bnez	a4,ffffffffc0204ae6 <init_main+0xa4>
ffffffffc0204a8a:	7ff8                	ld	a4,248(a5)
ffffffffc0204a8c:	ef29                	bnez	a4,ffffffffc0204ae6 <init_main+0xa4>
ffffffffc0204a8e:	1007b703          	ld	a4,256(a5)
ffffffffc0204a92:	eb31                	bnez	a4,ffffffffc0204ae6 <init_main+0xa4>
    assert(nr_process == 2);
ffffffffc0204a94:	000a1697          	auipc	a3,0xa1
ffffffffc0204a98:	4186a683          	lw	a3,1048(a3) # ffffffffc02a5eac <nr_process>
ffffffffc0204a9c:	4709                	li	a4,2
ffffffffc0204a9e:	0ce69063          	bne	a3,a4,ffffffffc0204b5e <init_main+0x11c>
ffffffffc0204aa2:	000a1697          	auipc	a3,0xa1
ffffffffc0204aa6:	38668693          	addi	a3,a3,902 # ffffffffc02a5e28 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204aaa:	6698                	ld	a4,8(a3)
ffffffffc0204aac:	0c878793          	addi	a5,a5,200
ffffffffc0204ab0:	08f71763          	bne	a4,a5,ffffffffc0204b3e <init_main+0xfc>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204ab4:	629c                	ld	a5,0(a3)
ffffffffc0204ab6:	06f71463          	bne	a4,a5,ffffffffc0204b1e <init_main+0xdc>

    cprintf("init check memory pass.\n");
ffffffffc0204aba:	00003517          	auipc	a0,0x3
ffffffffc0204abe:	a2e50513          	addi	a0,a0,-1490 # ffffffffc02074e8 <etext+0x1a2e>
ffffffffc0204ac2:	ed2fb0ef          	jal	ffffffffc0200194 <cprintf>

    /* After all user processes quit, shut down the machine so grading can finish. */
    cprintf("shutting down...\n");
ffffffffc0204ac6:	00003517          	auipc	a0,0x3
ffffffffc0204aca:	a4250513          	addi	a0,a0,-1470 # ffffffffc0207508 <etext+0x1a4e>
ffffffffc0204ace:	ec6fb0ef          	jal	ffffffffc0200194 <cprintf>
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0204ad2:	4501                	li	a0,0
ffffffffc0204ad4:	4581                	li	a1,0
ffffffffc0204ad6:	4601                	li	a2,0
ffffffffc0204ad8:	48a1                	li	a7,8
ffffffffc0204ada:	00000073          	ecall
    sbi_shutdown();

    /* Should not reach here, but return to satisfy prototype. */
    return 0;
}
ffffffffc0204ade:	60a2                	ld	ra,8(sp)
ffffffffc0204ae0:	4501                	li	a0,0
ffffffffc0204ae2:	0141                	addi	sp,sp,16
ffffffffc0204ae4:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204ae6:	00003697          	auipc	a3,0x3
ffffffffc0204aea:	94268693          	addi	a3,a3,-1726 # ffffffffc0207428 <etext+0x196e>
ffffffffc0204aee:	00001617          	auipc	a2,0x1
ffffffffc0204af2:	77a60613          	addi	a2,a2,1914 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0204af6:	39a00593          	li	a1,922
ffffffffc0204afa:	00003517          	auipc	a0,0x3
ffffffffc0204afe:	82650513          	addi	a0,a0,-2010 # ffffffffc0207320 <etext+0x1866>
ffffffffc0204b02:	945fb0ef          	jal	ffffffffc0200446 <__panic>
        panic("create user_main failed.\n");
ffffffffc0204b06:	00003617          	auipc	a2,0x3
ffffffffc0204b0a:	8da60613          	addi	a2,a2,-1830 # ffffffffc02073e0 <etext+0x1926>
ffffffffc0204b0e:	39100593          	li	a1,913
ffffffffc0204b12:	00003517          	auipc	a0,0x3
ffffffffc0204b16:	80e50513          	addi	a0,a0,-2034 # ffffffffc0207320 <etext+0x1866>
ffffffffc0204b1a:	92dfb0ef          	jal	ffffffffc0200446 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204b1e:	00003697          	auipc	a3,0x3
ffffffffc0204b22:	99a68693          	addi	a3,a3,-1638 # ffffffffc02074b8 <etext+0x19fe>
ffffffffc0204b26:	00001617          	auipc	a2,0x1
ffffffffc0204b2a:	74260613          	addi	a2,a2,1858 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0204b2e:	39d00593          	li	a1,925
ffffffffc0204b32:	00002517          	auipc	a0,0x2
ffffffffc0204b36:	7ee50513          	addi	a0,a0,2030 # ffffffffc0207320 <etext+0x1866>
ffffffffc0204b3a:	90dfb0ef          	jal	ffffffffc0200446 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204b3e:	00003697          	auipc	a3,0x3
ffffffffc0204b42:	94a68693          	addi	a3,a3,-1718 # ffffffffc0207488 <etext+0x19ce>
ffffffffc0204b46:	00001617          	auipc	a2,0x1
ffffffffc0204b4a:	72260613          	addi	a2,a2,1826 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0204b4e:	39c00593          	li	a1,924
ffffffffc0204b52:	00002517          	auipc	a0,0x2
ffffffffc0204b56:	7ce50513          	addi	a0,a0,1998 # ffffffffc0207320 <etext+0x1866>
ffffffffc0204b5a:	8edfb0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_process == 2);
ffffffffc0204b5e:	00003697          	auipc	a3,0x3
ffffffffc0204b62:	91a68693          	addi	a3,a3,-1766 # ffffffffc0207478 <etext+0x19be>
ffffffffc0204b66:	00001617          	auipc	a2,0x1
ffffffffc0204b6a:	70260613          	addi	a2,a2,1794 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0204b6e:	39b00593          	li	a1,923
ffffffffc0204b72:	00002517          	auipc	a0,0x2
ffffffffc0204b76:	7ae50513          	addi	a0,a0,1966 # ffffffffc0207320 <etext+0x1866>
ffffffffc0204b7a:	8cdfb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0204b7e <do_execve>:
{
ffffffffc0204b7e:	7171                	addi	sp,sp,-176
ffffffffc0204b80:	ece6                	sd	s9,88(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204b82:	000a1c97          	auipc	s9,0xa1
ffffffffc0204b86:	32ec8c93          	addi	s9,s9,814 # ffffffffc02a5eb0 <current>
ffffffffc0204b8a:	000cb783          	ld	a5,0(s9)
{
ffffffffc0204b8e:	ed26                	sd	s1,152(sp)
ffffffffc0204b90:	f122                	sd	s0,160(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204b92:	7784                	ld	s1,40(a5)
{
ffffffffc0204b94:	842e                	mv	s0,a1
ffffffffc0204b96:	e94a                	sd	s2,144(sp)
ffffffffc0204b98:	f032                	sd	a2,32(sp)
ffffffffc0204b9a:	892a                	mv	s2,a0
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204b9c:	85aa                	mv	a1,a0
ffffffffc0204b9e:	8622                	mv	a2,s0
ffffffffc0204ba0:	8526                	mv	a0,s1
ffffffffc0204ba2:	4681                	li	a3,0
{
ffffffffc0204ba4:	f506                	sd	ra,168(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204ba6:	c5eff0ef          	jal	ffffffffc0204004 <user_mem_check>
ffffffffc0204baa:	44050263          	beqz	a0,ffffffffc0204fee <do_execve+0x470>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204bae:	4641                	li	a2,16
ffffffffc0204bb0:	1808                	addi	a0,sp,48
ffffffffc0204bb2:	4581                	li	a1,0
ffffffffc0204bb4:	6dd000ef          	jal	ffffffffc0205a90 <memset>
    if (len > PROC_NAME_LEN)
ffffffffc0204bb8:	47bd                	li	a5,15
ffffffffc0204bba:	8622                	mv	a2,s0
ffffffffc0204bbc:	1087e663          	bltu	a5,s0,ffffffffc0204cc8 <do_execve+0x14a>
    memcpy(local_name, name, len);
ffffffffc0204bc0:	85ca                	mv	a1,s2
ffffffffc0204bc2:	1808                	addi	a0,sp,48
ffffffffc0204bc4:	6df000ef          	jal	ffffffffc0205aa2 <memcpy>
    if (mm != NULL)
ffffffffc0204bc8:	c895                	beqz	s1,ffffffffc0204bfc <do_execve+0x7e>
        cputs("mm != NULL");
ffffffffc0204bca:	00002517          	auipc	a0,0x2
ffffffffc0204bce:	51e50513          	addi	a0,a0,1310 # ffffffffc02070e8 <etext+0x162e>
ffffffffc0204bd2:	df8fb0ef          	jal	ffffffffc02001ca <cputs>
ffffffffc0204bd6:	000a1797          	auipc	a5,0xa1
ffffffffc0204bda:	2a27b783          	ld	a5,674(a5) # ffffffffc02a5e78 <boot_pgdir_pa>
ffffffffc0204bde:	577d                	li	a4,-1
ffffffffc0204be0:	177e                	slli	a4,a4,0x3f
ffffffffc0204be2:	83b1                	srli	a5,a5,0xc
ffffffffc0204be4:	8fd9                	or	a5,a5,a4
ffffffffc0204be6:	18079073          	csrw	satp,a5
ffffffffc0204bea:	589c                	lw	a5,48(s1)
ffffffffc0204bec:	37fd                	addiw	a5,a5,-1
ffffffffc0204bee:	d89c                	sw	a5,48(s1)
        if (mm_count_dec(mm) == 0)
ffffffffc0204bf0:	2c078963          	beqz	a5,ffffffffc0204ec2 <do_execve+0x344>
        current->mm = NULL;
ffffffffc0204bf4:	000cb783          	ld	a5,0(s9)
ffffffffc0204bf8:	0207b423          	sd	zero,40(a5)
    cprintf("!!! [DEBUG] load_icode is running! Clearing BSS... !!!\n");
ffffffffc0204bfc:	00003517          	auipc	a0,0x3
ffffffffc0204c00:	92450513          	addi	a0,a0,-1756 # ffffffffc0207520 <etext+0x1a66>
ffffffffc0204c04:	d90fb0ef          	jal	ffffffffc0200194 <cprintf>
    if (current->mm != NULL)
ffffffffc0204c08:	000cb783          	ld	a5,0(s9)
ffffffffc0204c0c:	779c                	ld	a5,40(a5)
ffffffffc0204c0e:	40079c63          	bnez	a5,ffffffffc0205026 <do_execve+0x4a8>
    if ((mm = mm_create()) == NULL)
ffffffffc0204c12:	b4dfe0ef          	jal	ffffffffc020375e <mm_create>
ffffffffc0204c16:	84aa                	mv	s1,a0
ffffffffc0204c18:	1c050a63          	beqz	a0,ffffffffc0204dec <do_execve+0x26e>
    if ((page = alloc_page()) == NULL)
ffffffffc0204c1c:	4505                	li	a0,1
ffffffffc0204c1e:	ad8fd0ef          	jal	ffffffffc0201ef6 <alloc_pages>
ffffffffc0204c22:	3c050c63          	beqz	a0,ffffffffc0204ffa <do_execve+0x47c>
    return page - pages + nbase;
ffffffffc0204c26:	f4de                	sd	s7,104(sp)
ffffffffc0204c28:	000a1b97          	auipc	s7,0xa1
ffffffffc0204c2c:	270b8b93          	addi	s7,s7,624 # ffffffffc02a5e98 <pages>
ffffffffc0204c30:	000bb783          	ld	a5,0(s7)
ffffffffc0204c34:	f8da                	sd	s6,112(sp)
ffffffffc0204c36:	00003b17          	auipc	s6,0x3
ffffffffc0204c3a:	0e2b3b03          	ld	s6,226(s6) # ffffffffc0207d18 <nbase>
ffffffffc0204c3e:	40f506b3          	sub	a3,a0,a5
ffffffffc0204c42:	f0e2                	sd	s8,96(sp)
    return KADDR(page2pa(page));
ffffffffc0204c44:	000a1c17          	auipc	s8,0xa1
ffffffffc0204c48:	24cc0c13          	addi	s8,s8,588 # ffffffffc02a5e90 <npage>
ffffffffc0204c4c:	fcd6                	sd	s5,120(sp)
    return page - pages + nbase;
ffffffffc0204c4e:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204c50:	5afd                	li	s5,-1
ffffffffc0204c52:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc0204c56:	96da                	add	a3,a3,s6
    return KADDR(page2pa(page));
ffffffffc0204c58:	00cad713          	srli	a4,s5,0xc
ffffffffc0204c5c:	ec3a                	sd	a4,24(sp)
ffffffffc0204c5e:	e152                	sd	s4,128(sp)
ffffffffc0204c60:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c62:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204c64:	3ef77563          	bgeu	a4,a5,ffffffffc020504e <do_execve+0x4d0>
ffffffffc0204c68:	000a1a17          	auipc	s4,0xa1
ffffffffc0204c6c:	220a0a13          	addi	s4,s4,544 # ffffffffc02a5e88 <va_pa_offset>
ffffffffc0204c70:	000a3783          	ld	a5,0(s4)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204c74:	000a1597          	auipc	a1,0xa1
ffffffffc0204c78:	20c5b583          	ld	a1,524(a1) # ffffffffc02a5e80 <boot_pgdir_va>
ffffffffc0204c7c:	6605                	lui	a2,0x1
ffffffffc0204c7e:	00f68433          	add	s0,a3,a5
ffffffffc0204c82:	8522                	mv	a0,s0
ffffffffc0204c84:	61f000ef          	jal	ffffffffc0205aa2 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204c88:	7682                	ld	a3,32(sp)
ffffffffc0204c8a:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0204c8e:	ec80                	sd	s0,24(s1)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204c90:	4298                	lw	a4,0(a3)
ffffffffc0204c92:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_COW_out_size+0x464ba15f>
ffffffffc0204c96:	02f70b63          	beq	a4,a5,ffffffffc0204ccc <do_execve+0x14e>
        ret = -E_INVAL_ELF;
ffffffffc0204c9a:	5461                	li	s0,-8
    put_pgdir(mm);
ffffffffc0204c9c:	8526                	mv	a0,s1
ffffffffc0204c9e:	d10ff0ef          	jal	ffffffffc02041ae <put_pgdir>
ffffffffc0204ca2:	6a0a                	ld	s4,128(sp)
ffffffffc0204ca4:	7ae6                	ld	s5,120(sp)
ffffffffc0204ca6:	7b46                	ld	s6,112(sp)
ffffffffc0204ca8:	7ba6                	ld	s7,104(sp)
ffffffffc0204caa:	7c06                	ld	s8,96(sp)
    mm_destroy(mm);
ffffffffc0204cac:	8526                	mv	a0,s1
ffffffffc0204cae:	e09fe0ef          	jal	ffffffffc0203ab6 <mm_destroy>
    do_exit(ret);
ffffffffc0204cb2:	8522                	mv	a0,s0
ffffffffc0204cb4:	e54e                	sd	s3,136(sp)
ffffffffc0204cb6:	e152                	sd	s4,128(sp)
ffffffffc0204cb8:	fcd6                	sd	s5,120(sp)
ffffffffc0204cba:	f8da                	sd	s6,112(sp)
ffffffffc0204cbc:	f4de                	sd	s7,104(sp)
ffffffffc0204cbe:	f0e2                	sd	s8,96(sp)
ffffffffc0204cc0:	e8ea                	sd	s10,80(sp)
ffffffffc0204cc2:	e4ee                	sd	s11,72(sp)
ffffffffc0204cc4:	a59ff0ef          	jal	ffffffffc020471c <do_exit>
    if (len > PROC_NAME_LEN)
ffffffffc0204cc8:	863e                	mv	a2,a5
ffffffffc0204cca:	bddd                	j	ffffffffc0204bc0 <do_execve+0x42>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204ccc:	0386d703          	lhu	a4,56(a3)
ffffffffc0204cd0:	e54e                	sd	s3,136(sp)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204cd2:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204cd6:	00371793          	slli	a5,a4,0x3
ffffffffc0204cda:	8f99                	sub	a5,a5,a4
ffffffffc0204cdc:	078e                	slli	a5,a5,0x3
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204cde:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204ce0:	97ce                	add	a5,a5,s3
ffffffffc0204ce2:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204ce4:	02f9f063          	bgeu	s3,a5,ffffffffc0204d04 <do_execve+0x186>
ffffffffc0204ce8:	e8ea                	sd	s10,80(sp)
ffffffffc0204cea:	e4ee                	sd	s11,72(sp)
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204cec:	0009a783          	lw	a5,0(s3)
ffffffffc0204cf0:	4705                	li	a4,1
ffffffffc0204cf2:	0ee78f63          	beq	a5,a4,ffffffffc0204df0 <do_execve+0x272>
    for (; ph < ph_end; ph++)
ffffffffc0204cf6:	77a2                	ld	a5,40(sp)
ffffffffc0204cf8:	03898993          	addi	s3,s3,56
ffffffffc0204cfc:	fef9e8e3          	bltu	s3,a5,ffffffffc0204cec <do_execve+0x16e>
ffffffffc0204d00:	6d46                	ld	s10,80(sp)
ffffffffc0204d02:	6da6                	ld	s11,72(sp)
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204d04:	4701                	li	a4,0
ffffffffc0204d06:	46ad                	li	a3,11
ffffffffc0204d08:	00100637          	lui	a2,0x100
ffffffffc0204d0c:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204d10:	8526                	mv	a0,s1
ffffffffc0204d12:	df7fe0ef          	jal	ffffffffc0203b08 <mm_map>
ffffffffc0204d16:	842a                	mv	s0,a0
ffffffffc0204d18:	1a051063          	bnez	a0,ffffffffc0204eb8 <do_execve+0x33a>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204d1c:	6c88                	ld	a0,24(s1)
ffffffffc0204d1e:	467d                	li	a2,31
ffffffffc0204d20:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204d24:	959fe0ef          	jal	ffffffffc020367c <pgdir_alloc_page>
ffffffffc0204d28:	3c050663          	beqz	a0,ffffffffc02050f4 <do_execve+0x576>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204d2c:	6c88                	ld	a0,24(s1)
ffffffffc0204d2e:	467d                	li	a2,31
ffffffffc0204d30:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204d34:	949fe0ef          	jal	ffffffffc020367c <pgdir_alloc_page>
ffffffffc0204d38:	38050c63          	beqz	a0,ffffffffc02050d0 <do_execve+0x552>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204d3c:	6c88                	ld	a0,24(s1)
ffffffffc0204d3e:	467d                	li	a2,31
ffffffffc0204d40:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204d44:	939fe0ef          	jal	ffffffffc020367c <pgdir_alloc_page>
ffffffffc0204d48:	36050263          	beqz	a0,ffffffffc02050ac <do_execve+0x52e>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204d4c:	6c88                	ld	a0,24(s1)
ffffffffc0204d4e:	467d                	li	a2,31
ffffffffc0204d50:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204d54:	929fe0ef          	jal	ffffffffc020367c <pgdir_alloc_page>
ffffffffc0204d58:	32050863          	beqz	a0,ffffffffc0205088 <do_execve+0x50a>
    mm->mm_count += 1;
ffffffffc0204d5c:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc0204d5e:	000cb603          	ld	a2,0(s9)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204d62:	6c94                	ld	a3,24(s1)
ffffffffc0204d64:	2785                	addiw	a5,a5,1
ffffffffc0204d66:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc0204d68:	f604                	sd	s1,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204d6a:	c02007b7          	lui	a5,0xc0200
ffffffffc0204d6e:	2ef6ef63          	bltu	a3,a5,ffffffffc020506c <do_execve+0x4ee>
ffffffffc0204d72:	000a3783          	ld	a5,0(s4)
ffffffffc0204d76:	577d                	li	a4,-1
ffffffffc0204d78:	177e                	slli	a4,a4,0x3f
ffffffffc0204d7a:	8e9d                	sub	a3,a3,a5
ffffffffc0204d7c:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204d80:	f654                	sd	a3,168(a2)
ffffffffc0204d82:	8fd9                	or	a5,a5,a4
ffffffffc0204d84:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204d88:	7244                	ld	s1,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204d8a:	4581                	li	a1,0
ffffffffc0204d8c:	12000613          	li	a2,288
ffffffffc0204d90:	8526                	mv	a0,s1
    uintptr_t sstatus = tf->status;
ffffffffc0204d92:	1004b903          	ld	s2,256(s1)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204d96:	4fb000ef          	jal	ffffffffc0205a90 <memset>
    tf->epc = elf->e_entry;
ffffffffc0204d9a:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204d9c:	000cb983          	ld	s3,0(s9)
    tf->status = sstatus & ~SSTATUS_SPP;  
ffffffffc0204da0:	eff97913          	andi	s2,s2,-257
    tf->epc = elf->e_entry;
ffffffffc0204da4:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204da6:	4785                	li	a5,1
ffffffffc0204da8:	07fe                	slli	a5,a5,0x1f
    tf->status |= SSTATUS_SPIE;          
ffffffffc0204daa:	02096913          	ori	s2,s2,32
    tf->epc = elf->e_entry;
ffffffffc0204dae:	10e4b423          	sd	a4,264(s1)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204db2:	e89c                	sd	a5,16(s1)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204db4:	0b498513          	addi	a0,s3,180
ffffffffc0204db8:	4641                	li	a2,16
ffffffffc0204dba:	4581                	li	a1,0
    tf->status |= SSTATUS_SPIE;          
ffffffffc0204dbc:	1124b023          	sd	s2,256(s1)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204dc0:	4d1000ef          	jal	ffffffffc0205a90 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204dc4:	0b498513          	addi	a0,s3,180
ffffffffc0204dc8:	180c                	addi	a1,sp,48
ffffffffc0204dca:	463d                	li	a2,15
ffffffffc0204dcc:	4d7000ef          	jal	ffffffffc0205aa2 <memcpy>
ffffffffc0204dd0:	69aa                	ld	s3,136(sp)
ffffffffc0204dd2:	6a0a                	ld	s4,128(sp)
ffffffffc0204dd4:	7ae6                	ld	s5,120(sp)
ffffffffc0204dd6:	7b46                	ld	s6,112(sp)
ffffffffc0204dd8:	7ba6                	ld	s7,104(sp)
ffffffffc0204dda:	7c06                	ld	s8,96(sp)
}
ffffffffc0204ddc:	70aa                	ld	ra,168(sp)
ffffffffc0204dde:	8522                	mv	a0,s0
ffffffffc0204de0:	740a                	ld	s0,160(sp)
ffffffffc0204de2:	64ea                	ld	s1,152(sp)
ffffffffc0204de4:	694a                	ld	s2,144(sp)
ffffffffc0204de6:	6ce6                	ld	s9,88(sp)
ffffffffc0204de8:	614d                	addi	sp,sp,176
ffffffffc0204dea:	8082                	ret
    int ret = -E_NO_MEM;
ffffffffc0204dec:	5471                	li	s0,-4
ffffffffc0204dee:	b5d1                	j	ffffffffc0204cb2 <do_execve+0x134>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204df0:	0289b603          	ld	a2,40(s3)
ffffffffc0204df4:	0209b783          	ld	a5,32(s3)
ffffffffc0204df8:	20f66363          	bltu	a2,a5,ffffffffc0204ffe <do_execve+0x480>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204dfc:	0049a783          	lw	a5,4(s3)
ffffffffc0204e00:	0027971b          	slliw	a4,a5,0x2
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204e04:	0027f693          	andi	a3,a5,2
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204e08:	8b11                	andi	a4,a4,4
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204e0a:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204e0c:	c6e9                	beqz	a3,ffffffffc0204ed6 <do_execve+0x358>
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204e0e:	1c079663          	bnez	a5,ffffffffc0204fda <do_execve+0x45c>
            perm |= (PTE_W | PTE_R);
ffffffffc0204e12:	47dd                	li	a5,23
            vm_flags |= VM_WRITE;
ffffffffc0204e14:	00276693          	ori	a3,a4,2
            perm |= (PTE_W | PTE_R);
ffffffffc0204e18:	e83e                	sd	a5,16(sp)
        if (vm_flags & VM_EXEC)
ffffffffc0204e1a:	c709                	beqz	a4,ffffffffc0204e24 <do_execve+0x2a6>
            perm |= PTE_X;
ffffffffc0204e1c:	67c2                	ld	a5,16(sp)
ffffffffc0204e1e:	0087e793          	ori	a5,a5,8
ffffffffc0204e22:	e83e                	sd	a5,16(sp)
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204e24:	0109b583          	ld	a1,16(s3)
ffffffffc0204e28:	4701                	li	a4,0
ffffffffc0204e2a:	8526                	mv	a0,s1
ffffffffc0204e2c:	cddfe0ef          	jal	ffffffffc0203b08 <mm_map>
ffffffffc0204e30:	842a                	mv	s0,a0
ffffffffc0204e32:	1c051a63          	bnez	a0,ffffffffc0205006 <do_execve+0x488>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204e36:	0109bd03          	ld	s10,16(s3)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204e3a:	0209b403          	ld	s0,32(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204e3e:	77fd                	lui	a5,0xfffff
ffffffffc0204e40:	00fd75b3          	and	a1,s10,a5
        end = ph->p_va + ph->p_filesz;
ffffffffc0204e44:	946a                	add	s0,s0,s10
        while (start < end)
ffffffffc0204e46:	1a8d7663          	bgeu	s10,s0,ffffffffc0204ff2 <do_execve+0x474>
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204e4a:	0089b903          	ld	s2,8(s3)
ffffffffc0204e4e:	7782                	ld	a5,32(sp)
ffffffffc0204e50:	993e                	add	s2,s2,a5
ffffffffc0204e52:	a881                	j	ffffffffc0204ea2 <do_execve+0x324>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204e54:	6785                	lui	a5,0x1
ffffffffc0204e56:	00f58ab3          	add	s5,a1,a5
                size -= la - end;
ffffffffc0204e5a:	41a40633          	sub	a2,s0,s10
            if (end < la)
ffffffffc0204e5e:	01546463          	bltu	s0,s5,ffffffffc0204e66 <do_execve+0x2e8>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204e62:	41aa8633          	sub	a2,s5,s10
    return page - pages + nbase;
ffffffffc0204e66:	000bb683          	ld	a3,0(s7)
    return KADDR(page2pa(page));
ffffffffc0204e6a:	67e2                	ld	a5,24(sp)
ffffffffc0204e6c:	000c3503          	ld	a0,0(s8)
    return page - pages + nbase;
ffffffffc0204e70:	40dd86b3          	sub	a3,s11,a3
ffffffffc0204e74:	8699                	srai	a3,a3,0x6
ffffffffc0204e76:	96da                	add	a3,a3,s6
    return KADDR(page2pa(page));
ffffffffc0204e78:	00f6f8b3          	and	a7,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204e7c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204e7e:	18a8f863          	bgeu	a7,a0,ffffffffc020500e <do_execve+0x490>
ffffffffc0204e82:	000a3503          	ld	a0,0(s4)
ffffffffc0204e86:	40bd05b3          	sub	a1,s10,a1
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204e8a:	e432                	sd	a2,8(sp)
ffffffffc0204e8c:	9536                	add	a0,a0,a3
ffffffffc0204e8e:	952e                	add	a0,a0,a1
ffffffffc0204e90:	85ca                	mv	a1,s2
ffffffffc0204e92:	411000ef          	jal	ffffffffc0205aa2 <memcpy>
            start += size, from += size;
ffffffffc0204e96:	6622                	ld	a2,8(sp)
ffffffffc0204e98:	9d32                	add	s10,s10,a2
ffffffffc0204e9a:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc0204e9c:	048d7463          	bgeu	s10,s0,ffffffffc0204ee4 <do_execve+0x366>
ffffffffc0204ea0:	85d6                	mv	a1,s5
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204ea2:	6c88                	ld	a0,24(s1)
ffffffffc0204ea4:	6642                	ld	a2,16(sp)
ffffffffc0204ea6:	e42e                	sd	a1,8(sp)
ffffffffc0204ea8:	fd4fe0ef          	jal	ffffffffc020367c <pgdir_alloc_page>
ffffffffc0204eac:	65a2                	ld	a1,8(sp)
ffffffffc0204eae:	8daa                	mv	s11,a0
ffffffffc0204eb0:	f155                	bnez	a0,ffffffffc0204e54 <do_execve+0x2d6>
ffffffffc0204eb2:	6d46                	ld	s10,80(sp)
ffffffffc0204eb4:	6da6                	ld	s11,72(sp)
        ret = -E_NO_MEM;
ffffffffc0204eb6:	5471                	li	s0,-4
    exit_mmap(mm);
ffffffffc0204eb8:	8526                	mv	a0,s1
ffffffffc0204eba:	db3fe0ef          	jal	ffffffffc0203c6c <exit_mmap>
ffffffffc0204ebe:	69aa                	ld	s3,136(sp)
ffffffffc0204ec0:	bbf1                	j	ffffffffc0204c9c <do_execve+0x11e>
            exit_mmap(mm);
ffffffffc0204ec2:	8526                	mv	a0,s1
ffffffffc0204ec4:	da9fe0ef          	jal	ffffffffc0203c6c <exit_mmap>
            put_pgdir(mm);
ffffffffc0204ec8:	8526                	mv	a0,s1
ffffffffc0204eca:	ae4ff0ef          	jal	ffffffffc02041ae <put_pgdir>
            mm_destroy(mm);
ffffffffc0204ece:	8526                	mv	a0,s1
ffffffffc0204ed0:	be7fe0ef          	jal	ffffffffc0203ab6 <mm_destroy>
ffffffffc0204ed4:	b305                	j	ffffffffc0204bf4 <do_execve+0x76>
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204ed6:	0e078e63          	beqz	a5,ffffffffc0204fd2 <do_execve+0x454>
            perm |= PTE_R;
ffffffffc0204eda:	47cd                	li	a5,19
            vm_flags |= VM_READ;
ffffffffc0204edc:	00176693          	ori	a3,a4,1
            perm |= PTE_R;
ffffffffc0204ee0:	e83e                	sd	a5,16(sp)
ffffffffc0204ee2:	bf25                	j	ffffffffc0204e1a <do_execve+0x29c>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204ee4:	0109b403          	ld	s0,16(s3)
ffffffffc0204ee8:	0289b683          	ld	a3,40(s3)
ffffffffc0204eec:	9436                	add	s0,s0,a3
        if (start < la)
ffffffffc0204eee:	075d7f63          	bgeu	s10,s5,ffffffffc0204f6c <do_execve+0x3ee>
            if (start == end)
ffffffffc0204ef2:	e1a402e3          	beq	s0,s10,ffffffffc0204cf6 <do_execve+0x178>
            if (end < la)
ffffffffc0204ef6:	0f546763          	bltu	s0,s5,ffffffffc0204fe4 <do_execve+0x466>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204efa:	41aa8933          	sub	s2,s5,s10
            if (page != NULL) {
ffffffffc0204efe:	060d8663          	beqz	s11,ffffffffc0204f6a <do_execve+0x3ec>
    return page - pages + nbase;
ffffffffc0204f02:	000bb683          	ld	a3,0(s7)
    return KADDR(page2pa(page));
ffffffffc0204f06:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204f0a:	40dd8533          	sub	a0,s11,a3
ffffffffc0204f0e:	8519                	srai	a0,a0,0x6
ffffffffc0204f10:	955a                	add	a0,a0,s6
    return KADDR(page2pa(page));
ffffffffc0204f12:	00c51593          	slli	a1,a0,0xc
ffffffffc0204f16:	81b1                	srli	a1,a1,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0204f18:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0204f1a:	0ec5f963          	bgeu	a1,a2,ffffffffc020500c <do_execve+0x48e>
ffffffffc0204f1e:	000a3603          	ld	a2,0(s4)
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204f22:	6585                	lui	a1,0x1
ffffffffc0204f24:	95ea                	add	a1,a1,s10
ffffffffc0204f26:	415585b3          	sub	a1,a1,s5
ffffffffc0204f2a:	9532                	add	a0,a0,a2
                memset(page2kva(page) + off, 0, size);
ffffffffc0204f2c:	952e                	add	a0,a0,a1
ffffffffc0204f2e:	864a                	mv	a2,s2
ffffffffc0204f30:	4581                	li	a1,0
ffffffffc0204f32:	35f000ef          	jal	ffffffffc0205a90 <memset>
            start += size;
ffffffffc0204f36:	9d4a                	add	s10,s10,s2
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204f38:	015436b3          	sltu	a3,s0,s5
ffffffffc0204f3c:	01547463          	bgeu	s0,s5,ffffffffc0204f44 <do_execve+0x3c6>
ffffffffc0204f40:	dba40be3          	beq	s0,s10,ffffffffc0204cf6 <do_execve+0x178>
ffffffffc0204f44:	e299                	bnez	a3,ffffffffc0204f4a <do_execve+0x3cc>
ffffffffc0204f46:	035d0363          	beq	s10,s5,ffffffffc0204f6c <do_execve+0x3ee>
ffffffffc0204f4a:	00002697          	auipc	a3,0x2
ffffffffc0204f4e:	63668693          	addi	a3,a3,1590 # ffffffffc0207580 <etext+0x1ac6>
ffffffffc0204f52:	00001617          	auipc	a2,0x1
ffffffffc0204f56:	31660613          	addi	a2,a2,790 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0204f5a:	28000593          	li	a1,640
ffffffffc0204f5e:	00002517          	auipc	a0,0x2
ffffffffc0204f62:	3c250513          	addi	a0,a0,962 # ffffffffc0207320 <etext+0x1866>
ffffffffc0204f66:	ce0fb0ef          	jal	ffffffffc0200446 <__panic>
            start += size;
ffffffffc0204f6a:	8d56                	mv	s10,s5
        while (start < end)
ffffffffc0204f6c:	d88d75e3          	bgeu	s10,s0,ffffffffc0204cf6 <do_execve+0x178>
ffffffffc0204f70:	56fd                	li	a3,-1
ffffffffc0204f72:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204f76:	e43e                	sd	a5,8(sp)
ffffffffc0204f78:	a0b1                	j	ffffffffc0204fc4 <do_execve+0x446>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204f7a:	6785                	lui	a5,0x1
ffffffffc0204f7c:	00fa8933          	add	s2,s5,a5
                size -= la - end;
ffffffffc0204f80:	41a40db3          	sub	s11,s0,s10
            if (end < la)
ffffffffc0204f84:	01246463          	bltu	s0,s2,ffffffffc0204f8c <do_execve+0x40e>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204f88:	41a90db3          	sub	s11,s2,s10
    return page - pages + nbase;
ffffffffc0204f8c:	000bb683          	ld	a3,0(s7)
    return KADDR(page2pa(page));
ffffffffc0204f90:	67a2                	ld	a5,8(sp)
ffffffffc0204f92:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204f96:	40d506b3          	sub	a3,a0,a3
ffffffffc0204f9a:	8699                	srai	a3,a3,0x6
ffffffffc0204f9c:	96da                	add	a3,a3,s6
    return KADDR(page2pa(page));
ffffffffc0204f9e:	00f6f533          	and	a0,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204fa2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204fa4:	06b57563          	bgeu	a0,a1,ffffffffc020500e <do_execve+0x490>
ffffffffc0204fa8:	000a3583          	ld	a1,0(s4)
ffffffffc0204fac:	415d0533          	sub	a0,s10,s5
            memset(page2kva(page) + off, 0, size);
ffffffffc0204fb0:	866e                	mv	a2,s11
ffffffffc0204fb2:	96ae                	add	a3,a3,a1
ffffffffc0204fb4:	9536                	add	a0,a0,a3
ffffffffc0204fb6:	4581                	li	a1,0
            start += size;
ffffffffc0204fb8:	9d6e                	add	s10,s10,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204fba:	2d7000ef          	jal	ffffffffc0205a90 <memset>
        while (start < end)
ffffffffc0204fbe:	d28d7ce3          	bgeu	s10,s0,ffffffffc0204cf6 <do_execve+0x178>
ffffffffc0204fc2:	8aca                	mv	s5,s2
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204fc4:	6c88                	ld	a0,24(s1)
ffffffffc0204fc6:	6642                	ld	a2,16(sp)
ffffffffc0204fc8:	85d6                	mv	a1,s5
ffffffffc0204fca:	eb2fe0ef          	jal	ffffffffc020367c <pgdir_alloc_page>
ffffffffc0204fce:	f555                	bnez	a0,ffffffffc0204f7a <do_execve+0x3fc>
ffffffffc0204fd0:	b5cd                	j	ffffffffc0204eb2 <do_execve+0x334>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204fd2:	47c5                	li	a5,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204fd4:	86ba                	mv	a3,a4
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204fd6:	e83e                	sd	a5,16(sp)
ffffffffc0204fd8:	b589                	j	ffffffffc0204e1a <do_execve+0x29c>
            perm |= (PTE_W | PTE_R);
ffffffffc0204fda:	47dd                	li	a5,23
            vm_flags |= VM_READ;
ffffffffc0204fdc:	00376693          	ori	a3,a4,3
            perm |= (PTE_W | PTE_R);
ffffffffc0204fe0:	e83e                	sd	a5,16(sp)
ffffffffc0204fe2:	bd25                	j	ffffffffc0204e1a <do_execve+0x29c>
            if (page != NULL) {
ffffffffc0204fe4:	d00d89e3          	beqz	s11,ffffffffc0204cf6 <do_execve+0x178>
                size -= la - end;
ffffffffc0204fe8:	41a40933          	sub	s2,s0,s10
ffffffffc0204fec:	bf19                	j	ffffffffc0204f02 <do_execve+0x384>
        return -E_INVAL;
ffffffffc0204fee:	5475                	li	s0,-3
ffffffffc0204ff0:	b3f5                	j	ffffffffc0204ddc <do_execve+0x25e>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204ff2:	8aae                	mv	s5,a1
        while (start < end)
ffffffffc0204ff4:	846a                	mv	s0,s10
        page = NULL;
ffffffffc0204ff6:	4d81                	li	s11,0
ffffffffc0204ff8:	bdc5                	j	ffffffffc0204ee8 <do_execve+0x36a>
    int ret = -E_NO_MEM;
ffffffffc0204ffa:	5471                	li	s0,-4
ffffffffc0204ffc:	b945                	j	ffffffffc0204cac <do_execve+0x12e>
            ret = -E_INVAL_ELF;
ffffffffc0204ffe:	6d46                	ld	s10,80(sp)
ffffffffc0205000:	6da6                	ld	s11,72(sp)
ffffffffc0205002:	5461                	li	s0,-8
ffffffffc0205004:	bd55                	j	ffffffffc0204eb8 <do_execve+0x33a>
ffffffffc0205006:	6d46                	ld	s10,80(sp)
ffffffffc0205008:	6da6                	ld	s11,72(sp)
ffffffffc020500a:	b57d                	j	ffffffffc0204eb8 <do_execve+0x33a>
ffffffffc020500c:	86aa                	mv	a3,a0
ffffffffc020500e:	00002617          	auipc	a2,0x2
ffffffffc0205012:	81a60613          	addi	a2,a2,-2022 # ffffffffc0206828 <etext+0xd6e>
ffffffffc0205016:	07100593          	li	a1,113
ffffffffc020501a:	00002517          	auipc	a0,0x2
ffffffffc020501e:	83650513          	addi	a0,a0,-1994 # ffffffffc0206850 <etext+0xd96>
ffffffffc0205022:	c24fb0ef          	jal	ffffffffc0200446 <__panic>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0205026:	00002617          	auipc	a2,0x2
ffffffffc020502a:	53260613          	addi	a2,a2,1330 # ffffffffc0207558 <etext+0x1a9e>
ffffffffc020502e:	21300593          	li	a1,531
ffffffffc0205032:	00002517          	auipc	a0,0x2
ffffffffc0205036:	2ee50513          	addi	a0,a0,750 # ffffffffc0207320 <etext+0x1866>
ffffffffc020503a:	e54e                	sd	s3,136(sp)
ffffffffc020503c:	e152                	sd	s4,128(sp)
ffffffffc020503e:	fcd6                	sd	s5,120(sp)
ffffffffc0205040:	f8da                	sd	s6,112(sp)
ffffffffc0205042:	f4de                	sd	s7,104(sp)
ffffffffc0205044:	f0e2                	sd	s8,96(sp)
ffffffffc0205046:	e8ea                	sd	s10,80(sp)
ffffffffc0205048:	e4ee                	sd	s11,72(sp)
ffffffffc020504a:	bfcfb0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc020504e:	00001617          	auipc	a2,0x1
ffffffffc0205052:	7da60613          	addi	a2,a2,2010 # ffffffffc0206828 <etext+0xd6e>
ffffffffc0205056:	07100593          	li	a1,113
ffffffffc020505a:	00001517          	auipc	a0,0x1
ffffffffc020505e:	7f650513          	addi	a0,a0,2038 # ffffffffc0206850 <etext+0xd96>
ffffffffc0205062:	e54e                	sd	s3,136(sp)
ffffffffc0205064:	e8ea                	sd	s10,80(sp)
ffffffffc0205066:	e4ee                	sd	s11,72(sp)
ffffffffc0205068:	bdefb0ef          	jal	ffffffffc0200446 <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc020506c:	00002617          	auipc	a2,0x2
ffffffffc0205070:	86460613          	addi	a2,a2,-1948 # ffffffffc02068d0 <etext+0xe16>
ffffffffc0205074:	29f00593          	li	a1,671
ffffffffc0205078:	00002517          	auipc	a0,0x2
ffffffffc020507c:	2a850513          	addi	a0,a0,680 # ffffffffc0207320 <etext+0x1866>
ffffffffc0205080:	e8ea                	sd	s10,80(sp)
ffffffffc0205082:	e4ee                	sd	s11,72(sp)
ffffffffc0205084:	bc2fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0205088:	00002697          	auipc	a3,0x2
ffffffffc020508c:	61068693          	addi	a3,a3,1552 # ffffffffc0207698 <etext+0x1bde>
ffffffffc0205090:	00001617          	auipc	a2,0x1
ffffffffc0205094:	1d860613          	addi	a2,a2,472 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0205098:	29a00593          	li	a1,666
ffffffffc020509c:	00002517          	auipc	a0,0x2
ffffffffc02050a0:	28450513          	addi	a0,a0,644 # ffffffffc0207320 <etext+0x1866>
ffffffffc02050a4:	e8ea                	sd	s10,80(sp)
ffffffffc02050a6:	e4ee                	sd	s11,72(sp)
ffffffffc02050a8:	b9efb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc02050ac:	00002697          	auipc	a3,0x2
ffffffffc02050b0:	5a468693          	addi	a3,a3,1444 # ffffffffc0207650 <etext+0x1b96>
ffffffffc02050b4:	00001617          	auipc	a2,0x1
ffffffffc02050b8:	1b460613          	addi	a2,a2,436 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02050bc:	29900593          	li	a1,665
ffffffffc02050c0:	00002517          	auipc	a0,0x2
ffffffffc02050c4:	26050513          	addi	a0,a0,608 # ffffffffc0207320 <etext+0x1866>
ffffffffc02050c8:	e8ea                	sd	s10,80(sp)
ffffffffc02050ca:	e4ee                	sd	s11,72(sp)
ffffffffc02050cc:	b7afb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc02050d0:	00002697          	auipc	a3,0x2
ffffffffc02050d4:	53868693          	addi	a3,a3,1336 # ffffffffc0207608 <etext+0x1b4e>
ffffffffc02050d8:	00001617          	auipc	a2,0x1
ffffffffc02050dc:	19060613          	addi	a2,a2,400 # ffffffffc0206268 <etext+0x7ae>
ffffffffc02050e0:	29800593          	li	a1,664
ffffffffc02050e4:	00002517          	auipc	a0,0x2
ffffffffc02050e8:	23c50513          	addi	a0,a0,572 # ffffffffc0207320 <etext+0x1866>
ffffffffc02050ec:	e8ea                	sd	s10,80(sp)
ffffffffc02050ee:	e4ee                	sd	s11,72(sp)
ffffffffc02050f0:	b56fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc02050f4:	00002697          	auipc	a3,0x2
ffffffffc02050f8:	4cc68693          	addi	a3,a3,1228 # ffffffffc02075c0 <etext+0x1b06>
ffffffffc02050fc:	00001617          	auipc	a2,0x1
ffffffffc0205100:	16c60613          	addi	a2,a2,364 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0205104:	29700593          	li	a1,663
ffffffffc0205108:	00002517          	auipc	a0,0x2
ffffffffc020510c:	21850513          	addi	a0,a0,536 # ffffffffc0207320 <etext+0x1866>
ffffffffc0205110:	e8ea                	sd	s10,80(sp)
ffffffffc0205112:	e4ee                	sd	s11,72(sp)
ffffffffc0205114:	b32fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0205118 <do_yield>:
    current->need_resched = 1;
ffffffffc0205118:	000a1797          	auipc	a5,0xa1
ffffffffc020511c:	d987b783          	ld	a5,-616(a5) # ffffffffc02a5eb0 <current>
ffffffffc0205120:	4705                	li	a4,1
}
ffffffffc0205122:	4501                	li	a0,0
    current->need_resched = 1;
ffffffffc0205124:	ef98                	sd	a4,24(a5)
}
ffffffffc0205126:	8082                	ret

ffffffffc0205128 <do_wait>:
    if (code_store != NULL)
ffffffffc0205128:	c59d                	beqz	a1,ffffffffc0205156 <do_wait+0x2e>
{
ffffffffc020512a:	1101                	addi	sp,sp,-32
ffffffffc020512c:	e02a                	sd	a0,0(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020512e:	000a1517          	auipc	a0,0xa1
ffffffffc0205132:	d8253503          	ld	a0,-638(a0) # ffffffffc02a5eb0 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0205136:	4685                	li	a3,1
ffffffffc0205138:	4611                	li	a2,4
ffffffffc020513a:	7508                	ld	a0,40(a0)
{
ffffffffc020513c:	ec06                	sd	ra,24(sp)
ffffffffc020513e:	e42e                	sd	a1,8(sp)
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0205140:	ec5fe0ef          	jal	ffffffffc0204004 <user_mem_check>
ffffffffc0205144:	6702                	ld	a4,0(sp)
ffffffffc0205146:	67a2                	ld	a5,8(sp)
ffffffffc0205148:	c909                	beqz	a0,ffffffffc020515a <do_wait+0x32>
}
ffffffffc020514a:	60e2                	ld	ra,24(sp)
ffffffffc020514c:	85be                	mv	a1,a5
ffffffffc020514e:	853a                	mv	a0,a4
ffffffffc0205150:	6105                	addi	sp,sp,32
ffffffffc0205152:	f0eff06f          	j	ffffffffc0204860 <do_wait.part.0>
ffffffffc0205156:	f0aff06f          	j	ffffffffc0204860 <do_wait.part.0>
ffffffffc020515a:	60e2                	ld	ra,24(sp)
ffffffffc020515c:	5575                	li	a0,-3
ffffffffc020515e:	6105                	addi	sp,sp,32
ffffffffc0205160:	8082                	ret

ffffffffc0205162 <do_kill>:
    if (0 < pid && pid < MAX_PID)
ffffffffc0205162:	6789                	lui	a5,0x2
ffffffffc0205164:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205168:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6c0a>
ffffffffc020516a:	06e7e463          	bltu	a5,a4,ffffffffc02051d2 <do_kill+0x70>
{
ffffffffc020516e:	1101                	addi	sp,sp,-32
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205170:	45a9                	li	a1,10
{
ffffffffc0205172:	ec06                	sd	ra,24(sp)
ffffffffc0205174:	e42a                	sd	a0,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205176:	484000ef          	jal	ffffffffc02055fa <hash32>
ffffffffc020517a:	02051793          	slli	a5,a0,0x20
ffffffffc020517e:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0205182:	0009d797          	auipc	a5,0x9d
ffffffffc0205186:	ca678793          	addi	a5,a5,-858 # ffffffffc02a1e28 <hash_list>
ffffffffc020518a:	96be                	add	a3,a3,a5
        while ((le = list_next(le)) != list)
ffffffffc020518c:	6622                	ld	a2,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc020518e:	8536                	mv	a0,a3
        while ((le = list_next(le)) != list)
ffffffffc0205190:	a029                	j	ffffffffc020519a <do_kill+0x38>
            if (proc->pid == pid)
ffffffffc0205192:	f2c52703          	lw	a4,-212(a0)
ffffffffc0205196:	00c70963          	beq	a4,a2,ffffffffc02051a8 <do_kill+0x46>
ffffffffc020519a:	6508                	ld	a0,8(a0)
        while ((le = list_next(le)) != list)
ffffffffc020519c:	fea69be3          	bne	a3,a0,ffffffffc0205192 <do_kill+0x30>
}
ffffffffc02051a0:	60e2                	ld	ra,24(sp)
    return -E_INVAL;
ffffffffc02051a2:	5575                	li	a0,-3
}
ffffffffc02051a4:	6105                	addi	sp,sp,32
ffffffffc02051a6:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc02051a8:	fd852703          	lw	a4,-40(a0)
ffffffffc02051ac:	00177693          	andi	a3,a4,1
ffffffffc02051b0:	e29d                	bnez	a3,ffffffffc02051d6 <do_kill+0x74>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc02051b2:	4954                	lw	a3,20(a0)
            proc->flags |= PF_EXITING;
ffffffffc02051b4:	00176713          	ori	a4,a4,1
ffffffffc02051b8:	fce52c23          	sw	a4,-40(a0)
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc02051bc:	0006c663          	bltz	a3,ffffffffc02051c8 <do_kill+0x66>
            return 0;
ffffffffc02051c0:	4501                	li	a0,0
}
ffffffffc02051c2:	60e2                	ld	ra,24(sp)
ffffffffc02051c4:	6105                	addi	sp,sp,32
ffffffffc02051c6:	8082                	ret
                wakeup_proc(proc);
ffffffffc02051c8:	f2850513          	addi	a0,a0,-216
ffffffffc02051cc:	232000ef          	jal	ffffffffc02053fe <wakeup_proc>
ffffffffc02051d0:	bfc5                	j	ffffffffc02051c0 <do_kill+0x5e>
    return -E_INVAL;
ffffffffc02051d2:	5575                	li	a0,-3
}
ffffffffc02051d4:	8082                	ret
        return -E_KILLED;
ffffffffc02051d6:	555d                	li	a0,-9
ffffffffc02051d8:	b7ed                	j	ffffffffc02051c2 <do_kill+0x60>

ffffffffc02051da <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc02051da:	1101                	addi	sp,sp,-32
ffffffffc02051dc:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc02051de:	000a1797          	auipc	a5,0xa1
ffffffffc02051e2:	c4a78793          	addi	a5,a5,-950 # ffffffffc02a5e28 <proc_list>
ffffffffc02051e6:	ec06                	sd	ra,24(sp)
ffffffffc02051e8:	e822                	sd	s0,16(sp)
ffffffffc02051ea:	e04a                	sd	s2,0(sp)
ffffffffc02051ec:	0009d497          	auipc	s1,0x9d
ffffffffc02051f0:	c3c48493          	addi	s1,s1,-964 # ffffffffc02a1e28 <hash_list>
ffffffffc02051f4:	e79c                	sd	a5,8(a5)
ffffffffc02051f6:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc02051f8:	000a1717          	auipc	a4,0xa1
ffffffffc02051fc:	c3070713          	addi	a4,a4,-976 # ffffffffc02a5e28 <proc_list>
ffffffffc0205200:	87a6                	mv	a5,s1
ffffffffc0205202:	e79c                	sd	a5,8(a5)
ffffffffc0205204:	e39c                	sd	a5,0(a5)
ffffffffc0205206:	07c1                	addi	a5,a5,16
ffffffffc0205208:	fee79de3          	bne	a5,a4,ffffffffc0205202 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc020520c:	ea5fe0ef          	jal	ffffffffc02040b0 <alloc_proc>
ffffffffc0205210:	000a1917          	auipc	s2,0xa1
ffffffffc0205214:	cb090913          	addi	s2,s2,-848 # ffffffffc02a5ec0 <idleproc>
ffffffffc0205218:	00a93023          	sd	a0,0(s2)
ffffffffc020521c:	10050363          	beqz	a0,ffffffffc0205322 <proc_init+0x148>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0205220:	4789                	li	a5,2
ffffffffc0205222:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205224:	00003797          	auipc	a5,0x3
ffffffffc0205228:	ddc78793          	addi	a5,a5,-548 # ffffffffc0208000 <bootstack>
ffffffffc020522c:	e91c                	sd	a5,16(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020522e:	0b450413          	addi	s0,a0,180
    idleproc->need_resched = 1;
ffffffffc0205232:	4785                	li	a5,1
ffffffffc0205234:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205236:	4641                	li	a2,16
ffffffffc0205238:	8522                	mv	a0,s0
ffffffffc020523a:	4581                	li	a1,0
ffffffffc020523c:	055000ef          	jal	ffffffffc0205a90 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205240:	8522                	mv	a0,s0
ffffffffc0205242:	463d                	li	a2,15
ffffffffc0205244:	00002597          	auipc	a1,0x2
ffffffffc0205248:	4b458593          	addi	a1,a1,1204 # ffffffffc02076f8 <etext+0x1c3e>
ffffffffc020524c:	057000ef          	jal	ffffffffc0205aa2 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0205250:	000a1797          	auipc	a5,0xa1
ffffffffc0205254:	c5c7a783          	lw	a5,-932(a5) # ffffffffc02a5eac <nr_process>

    current = idleproc;
ffffffffc0205258:	00093703          	ld	a4,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc020525c:	4601                	li	a2,0
    nr_process++;
ffffffffc020525e:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205260:	4581                	li	a1,0
ffffffffc0205262:	fffff517          	auipc	a0,0xfffff
ffffffffc0205266:	7e050513          	addi	a0,a0,2016 # ffffffffc0204a42 <init_main>
    current = idleproc;
ffffffffc020526a:	000a1697          	auipc	a3,0xa1
ffffffffc020526e:	c4e6b323          	sd	a4,-954(a3) # ffffffffc02a5eb0 <current>
    nr_process++;
ffffffffc0205272:	000a1717          	auipc	a4,0xa1
ffffffffc0205276:	c2f72d23          	sw	a5,-966(a4) # ffffffffc02a5eac <nr_process>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc020527a:	c52ff0ef          	jal	ffffffffc02046cc <kernel_thread>
ffffffffc020527e:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0205280:	08a05563          	blez	a0,ffffffffc020530a <proc_init+0x130>
    if (0 < pid && pid < MAX_PID)
ffffffffc0205284:	6789                	lui	a5,0x2
ffffffffc0205286:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6c0a>
ffffffffc0205288:	fff5071b          	addiw	a4,a0,-1
ffffffffc020528c:	02e7e463          	bltu	a5,a4,ffffffffc02052b4 <proc_init+0xda>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205290:	45a9                	li	a1,10
ffffffffc0205292:	368000ef          	jal	ffffffffc02055fa <hash32>
ffffffffc0205296:	02051713          	slli	a4,a0,0x20
ffffffffc020529a:	01c75793          	srli	a5,a4,0x1c
ffffffffc020529e:	00f486b3          	add	a3,s1,a5
ffffffffc02052a2:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc02052a4:	a029                	j	ffffffffc02052ae <proc_init+0xd4>
            if (proc->pid == pid)
ffffffffc02052a6:	f2c7a703          	lw	a4,-212(a5)
ffffffffc02052aa:	04870d63          	beq	a4,s0,ffffffffc0205304 <proc_init+0x12a>
    return listelm->next;
ffffffffc02052ae:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02052b0:	fef69be3          	bne	a3,a5,ffffffffc02052a6 <proc_init+0xcc>
    return NULL;
ffffffffc02052b4:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02052b6:	0b478413          	addi	s0,a5,180
ffffffffc02052ba:	4641                	li	a2,16
ffffffffc02052bc:	4581                	li	a1,0
ffffffffc02052be:	8522                	mv	a0,s0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc02052c0:	000a1717          	auipc	a4,0xa1
ffffffffc02052c4:	bef73c23          	sd	a5,-1032(a4) # ffffffffc02a5eb8 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02052c8:	7c8000ef          	jal	ffffffffc0205a90 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02052cc:	8522                	mv	a0,s0
ffffffffc02052ce:	463d                	li	a2,15
ffffffffc02052d0:	00002597          	auipc	a1,0x2
ffffffffc02052d4:	45058593          	addi	a1,a1,1104 # ffffffffc0207720 <etext+0x1c66>
ffffffffc02052d8:	7ca000ef          	jal	ffffffffc0205aa2 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02052dc:	00093783          	ld	a5,0(s2)
ffffffffc02052e0:	cfad                	beqz	a5,ffffffffc020535a <proc_init+0x180>
ffffffffc02052e2:	43dc                	lw	a5,4(a5)
ffffffffc02052e4:	ebbd                	bnez	a5,ffffffffc020535a <proc_init+0x180>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02052e6:	000a1797          	auipc	a5,0xa1
ffffffffc02052ea:	bd27b783          	ld	a5,-1070(a5) # ffffffffc02a5eb8 <initproc>
ffffffffc02052ee:	c7b1                	beqz	a5,ffffffffc020533a <proc_init+0x160>
ffffffffc02052f0:	43d8                	lw	a4,4(a5)
ffffffffc02052f2:	4785                	li	a5,1
ffffffffc02052f4:	04f71363          	bne	a4,a5,ffffffffc020533a <proc_init+0x160>
}
ffffffffc02052f8:	60e2                	ld	ra,24(sp)
ffffffffc02052fa:	6442                	ld	s0,16(sp)
ffffffffc02052fc:	64a2                	ld	s1,8(sp)
ffffffffc02052fe:	6902                	ld	s2,0(sp)
ffffffffc0205300:	6105                	addi	sp,sp,32
ffffffffc0205302:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0205304:	f2878793          	addi	a5,a5,-216
ffffffffc0205308:	b77d                	j	ffffffffc02052b6 <proc_init+0xdc>
        panic("create init_main failed.\n");
ffffffffc020530a:	00002617          	auipc	a2,0x2
ffffffffc020530e:	3f660613          	addi	a2,a2,1014 # ffffffffc0207700 <etext+0x1c46>
ffffffffc0205312:	3c600593          	li	a1,966
ffffffffc0205316:	00002517          	auipc	a0,0x2
ffffffffc020531a:	00a50513          	addi	a0,a0,10 # ffffffffc0207320 <etext+0x1866>
ffffffffc020531e:	928fb0ef          	jal	ffffffffc0200446 <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0205322:	00002617          	auipc	a2,0x2
ffffffffc0205326:	3be60613          	addi	a2,a2,958 # ffffffffc02076e0 <etext+0x1c26>
ffffffffc020532a:	3b700593          	li	a1,951
ffffffffc020532e:	00002517          	auipc	a0,0x2
ffffffffc0205332:	ff250513          	addi	a0,a0,-14 # ffffffffc0207320 <etext+0x1866>
ffffffffc0205336:	910fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020533a:	00002697          	auipc	a3,0x2
ffffffffc020533e:	41668693          	addi	a3,a3,1046 # ffffffffc0207750 <etext+0x1c96>
ffffffffc0205342:	00001617          	auipc	a2,0x1
ffffffffc0205346:	f2660613          	addi	a2,a2,-218 # ffffffffc0206268 <etext+0x7ae>
ffffffffc020534a:	3cd00593          	li	a1,973
ffffffffc020534e:	00002517          	auipc	a0,0x2
ffffffffc0205352:	fd250513          	addi	a0,a0,-46 # ffffffffc0207320 <etext+0x1866>
ffffffffc0205356:	8f0fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc020535a:	00002697          	auipc	a3,0x2
ffffffffc020535e:	3ce68693          	addi	a3,a3,974 # ffffffffc0207728 <etext+0x1c6e>
ffffffffc0205362:	00001617          	auipc	a2,0x1
ffffffffc0205366:	f0660613          	addi	a2,a2,-250 # ffffffffc0206268 <etext+0x7ae>
ffffffffc020536a:	3cc00593          	li	a1,972
ffffffffc020536e:	00002517          	auipc	a0,0x2
ffffffffc0205372:	fb250513          	addi	a0,a0,-78 # ffffffffc0207320 <etext+0x1866>
ffffffffc0205376:	8d0fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc020537a <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc020537a:	1141                	addi	sp,sp,-16
ffffffffc020537c:	e022                	sd	s0,0(sp)
ffffffffc020537e:	e406                	sd	ra,8(sp)
ffffffffc0205380:	000a1417          	auipc	s0,0xa1
ffffffffc0205384:	b3040413          	addi	s0,s0,-1232 # ffffffffc02a5eb0 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0205388:	6018                	ld	a4,0(s0)
ffffffffc020538a:	6f1c                	ld	a5,24(a4)
ffffffffc020538c:	dffd                	beqz	a5,ffffffffc020538a <cpu_idle+0x10>
        {
            schedule();
ffffffffc020538e:	104000ef          	jal	ffffffffc0205492 <schedule>
ffffffffc0205392:	bfdd                	j	ffffffffc0205388 <cpu_idle+0xe>

ffffffffc0205394 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0205394:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0205398:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc020539c:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc020539e:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc02053a0:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc02053a4:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc02053a8:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc02053ac:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc02053b0:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc02053b4:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc02053b8:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc02053bc:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc02053c0:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc02053c4:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc02053c8:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc02053cc:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc02053d0:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc02053d2:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc02053d4:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc02053d8:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc02053dc:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc02053e0:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc02053e4:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc02053e8:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc02053ec:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc02053f0:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc02053f4:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02053f8:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02053fc:	8082                	ret

ffffffffc02053fe <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02053fe:	4118                	lw	a4,0(a0)
{
ffffffffc0205400:	1101                	addi	sp,sp,-32
ffffffffc0205402:	ec06                	sd	ra,24(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205404:	478d                	li	a5,3
ffffffffc0205406:	06f70763          	beq	a4,a5,ffffffffc0205474 <wakeup_proc+0x76>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020540a:	100027f3          	csrr	a5,sstatus
ffffffffc020540e:	8b89                	andi	a5,a5,2
ffffffffc0205410:	eb91                	bnez	a5,ffffffffc0205424 <wakeup_proc+0x26>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205412:	4789                	li	a5,2
ffffffffc0205414:	02f70763          	beq	a4,a5,ffffffffc0205442 <wakeup_proc+0x44>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205418:	60e2                	ld	ra,24(sp)
            proc->state = PROC_RUNNABLE;
ffffffffc020541a:	c11c                	sw	a5,0(a0)
            proc->wait_state = 0;
ffffffffc020541c:	0e052623          	sw	zero,236(a0)
}
ffffffffc0205420:	6105                	addi	sp,sp,32
ffffffffc0205422:	8082                	ret
        intr_disable();
ffffffffc0205424:	e42a                	sd	a0,8(sp)
ffffffffc0205426:	cdefb0ef          	jal	ffffffffc0200904 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc020542a:	6522                	ld	a0,8(sp)
ffffffffc020542c:	4789                	li	a5,2
ffffffffc020542e:	4118                	lw	a4,0(a0)
ffffffffc0205430:	02f70663          	beq	a4,a5,ffffffffc020545c <wakeup_proc+0x5e>
            proc->state = PROC_RUNNABLE;
ffffffffc0205434:	c11c                	sw	a5,0(a0)
            proc->wait_state = 0;
ffffffffc0205436:	0e052623          	sw	zero,236(a0)
}
ffffffffc020543a:	60e2                	ld	ra,24(sp)
ffffffffc020543c:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020543e:	cc0fb06f          	j	ffffffffc02008fe <intr_enable>
ffffffffc0205442:	60e2                	ld	ra,24(sp)
            warn("wakeup runnable process.\n");
ffffffffc0205444:	00002617          	auipc	a2,0x2
ffffffffc0205448:	36c60613          	addi	a2,a2,876 # ffffffffc02077b0 <etext+0x1cf6>
ffffffffc020544c:	45d1                	li	a1,20
ffffffffc020544e:	00002517          	auipc	a0,0x2
ffffffffc0205452:	34a50513          	addi	a0,a0,842 # ffffffffc0207798 <etext+0x1cde>
}
ffffffffc0205456:	6105                	addi	sp,sp,32
            warn("wakeup runnable process.\n");
ffffffffc0205458:	858fb06f          	j	ffffffffc02004b0 <__warn>
ffffffffc020545c:	00002617          	auipc	a2,0x2
ffffffffc0205460:	35460613          	addi	a2,a2,852 # ffffffffc02077b0 <etext+0x1cf6>
ffffffffc0205464:	45d1                	li	a1,20
ffffffffc0205466:	00002517          	auipc	a0,0x2
ffffffffc020546a:	33250513          	addi	a0,a0,818 # ffffffffc0207798 <etext+0x1cde>
ffffffffc020546e:	842fb0ef          	jal	ffffffffc02004b0 <__warn>
    if (flag)
ffffffffc0205472:	b7e1                	j	ffffffffc020543a <wakeup_proc+0x3c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205474:	00002697          	auipc	a3,0x2
ffffffffc0205478:	30468693          	addi	a3,a3,772 # ffffffffc0207778 <etext+0x1cbe>
ffffffffc020547c:	00001617          	auipc	a2,0x1
ffffffffc0205480:	dec60613          	addi	a2,a2,-532 # ffffffffc0206268 <etext+0x7ae>
ffffffffc0205484:	45a5                	li	a1,9
ffffffffc0205486:	00002517          	auipc	a0,0x2
ffffffffc020548a:	31250513          	addi	a0,a0,786 # ffffffffc0207798 <etext+0x1cde>
ffffffffc020548e:	fb9fa0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0205492 <schedule>:

void schedule(void)
{
ffffffffc0205492:	1101                	addi	sp,sp,-32
ffffffffc0205494:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205496:	100027f3          	csrr	a5,sstatus
ffffffffc020549a:	8b89                	andi	a5,a5,2
ffffffffc020549c:	4301                	li	t1,0
ffffffffc020549e:	e3c1                	bnez	a5,ffffffffc020551e <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc02054a0:	000a1897          	auipc	a7,0xa1
ffffffffc02054a4:	a108b883          	ld	a7,-1520(a7) # ffffffffc02a5eb0 <current>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02054a8:	000a1517          	auipc	a0,0xa1
ffffffffc02054ac:	a1853503          	ld	a0,-1512(a0) # ffffffffc02a5ec0 <idleproc>
        current->need_resched = 0;
ffffffffc02054b0:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02054b4:	04a88f63          	beq	a7,a0,ffffffffc0205512 <schedule+0x80>
ffffffffc02054b8:	0c888693          	addi	a3,a7,200
ffffffffc02054bc:	000a1617          	auipc	a2,0xa1
ffffffffc02054c0:	96c60613          	addi	a2,a2,-1684 # ffffffffc02a5e28 <proc_list>
        le = last;
ffffffffc02054c4:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02054c6:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc02054c8:	4809                	li	a6,2
ffffffffc02054ca:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc02054cc:	00c78863          	beq	a5,a2,ffffffffc02054dc <schedule+0x4a>
                if (next->state == PROC_RUNNABLE)
ffffffffc02054d0:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc02054d4:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc02054d8:	03070363          	beq	a4,a6,ffffffffc02054fe <schedule+0x6c>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc02054dc:	fef697e3          	bne	a3,a5,ffffffffc02054ca <schedule+0x38>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02054e0:	ed99                	bnez	a1,ffffffffc02054fe <schedule+0x6c>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc02054e2:	451c                	lw	a5,8(a0)
ffffffffc02054e4:	2785                	addiw	a5,a5,1
ffffffffc02054e6:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc02054e8:	00a88663          	beq	a7,a0,ffffffffc02054f4 <schedule+0x62>
ffffffffc02054ec:	e41a                	sd	t1,8(sp)
        {
            proc_run(next);
ffffffffc02054ee:	d37fe0ef          	jal	ffffffffc0204224 <proc_run>
ffffffffc02054f2:	6322                	ld	t1,8(sp)
    if (flag)
ffffffffc02054f4:	00031b63          	bnez	t1,ffffffffc020550a <schedule+0x78>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02054f8:	60e2                	ld	ra,24(sp)
ffffffffc02054fa:	6105                	addi	sp,sp,32
ffffffffc02054fc:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02054fe:	4198                	lw	a4,0(a1)
ffffffffc0205500:	4789                	li	a5,2
ffffffffc0205502:	fef710e3          	bne	a4,a5,ffffffffc02054e2 <schedule+0x50>
ffffffffc0205506:	852e                	mv	a0,a1
ffffffffc0205508:	bfe9                	j	ffffffffc02054e2 <schedule+0x50>
}
ffffffffc020550a:	60e2                	ld	ra,24(sp)
ffffffffc020550c:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020550e:	bf0fb06f          	j	ffffffffc02008fe <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205512:	000a1617          	auipc	a2,0xa1
ffffffffc0205516:	91660613          	addi	a2,a2,-1770 # ffffffffc02a5e28 <proc_list>
ffffffffc020551a:	86b2                	mv	a3,a2
ffffffffc020551c:	b765                	j	ffffffffc02054c4 <schedule+0x32>
        intr_disable();
ffffffffc020551e:	be6fb0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0205522:	4305                	li	t1,1
ffffffffc0205524:	bfb5                	j	ffffffffc02054a0 <schedule+0xe>

ffffffffc0205526 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0205526:	000a1797          	auipc	a5,0xa1
ffffffffc020552a:	98a7b783          	ld	a5,-1654(a5) # ffffffffc02a5eb0 <current>
}
ffffffffc020552e:	43c8                	lw	a0,4(a5)
ffffffffc0205530:	8082                	ret

ffffffffc0205532 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0205532:	4501                	li	a0,0
ffffffffc0205534:	8082                	ret

ffffffffc0205536 <sys_putc>:
    cputchar(c);
ffffffffc0205536:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0205538:	1141                	addi	sp,sp,-16
ffffffffc020553a:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc020553c:	c8dfa0ef          	jal	ffffffffc02001c8 <cputchar>
}
ffffffffc0205540:	60a2                	ld	ra,8(sp)
ffffffffc0205542:	4501                	li	a0,0
ffffffffc0205544:	0141                	addi	sp,sp,16
ffffffffc0205546:	8082                	ret

ffffffffc0205548 <sys_kill>:
    return do_kill(pid);
ffffffffc0205548:	4108                	lw	a0,0(a0)
ffffffffc020554a:	c19ff06f          	j	ffffffffc0205162 <do_kill>

ffffffffc020554e <sys_yield>:
    return do_yield();
ffffffffc020554e:	bcbff06f          	j	ffffffffc0205118 <do_yield>

ffffffffc0205552 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0205552:	6d14                	ld	a3,24(a0)
ffffffffc0205554:	6910                	ld	a2,16(a0)
ffffffffc0205556:	650c                	ld	a1,8(a0)
ffffffffc0205558:	6108                	ld	a0,0(a0)
ffffffffc020555a:	e24ff06f          	j	ffffffffc0204b7e <do_execve>

ffffffffc020555e <sys_wait>:
    return do_wait(pid, store);
ffffffffc020555e:	650c                	ld	a1,8(a0)
ffffffffc0205560:	4108                	lw	a0,0(a0)
ffffffffc0205562:	bc7ff06f          	j	ffffffffc0205128 <do_wait>

ffffffffc0205566 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0205566:	000a1797          	auipc	a5,0xa1
ffffffffc020556a:	94a7b783          	ld	a5,-1718(a5) # ffffffffc02a5eb0 <current>
    return do_fork(0, stack, tf);
ffffffffc020556e:	4501                	li	a0,0
    struct trapframe *tf = current->tf;
ffffffffc0205570:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc0205572:	6a0c                	ld	a1,16(a2)
ffffffffc0205574:	d13fe06f          	j	ffffffffc0204286 <do_fork>

ffffffffc0205578 <sys_exit>:
    return do_exit(error_code);
ffffffffc0205578:	4108                	lw	a0,0(a0)
ffffffffc020557a:	9a2ff06f          	j	ffffffffc020471c <do_exit>

ffffffffc020557e <syscall>:

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
    struct trapframe *tf = current->tf;
ffffffffc020557e:	000a1697          	auipc	a3,0xa1
ffffffffc0205582:	9326b683          	ld	a3,-1742(a3) # ffffffffc02a5eb0 <current>
syscall(void) {
ffffffffc0205586:	715d                	addi	sp,sp,-80
ffffffffc0205588:	e0a2                	sd	s0,64(sp)
    struct trapframe *tf = current->tf;
ffffffffc020558a:	72c0                	ld	s0,160(a3)
syscall(void) {
ffffffffc020558c:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020558e:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc0205590:	4834                	lw	a3,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205592:	02d7ec63          	bltu	a5,a3,ffffffffc02055ca <syscall+0x4c>
        if (syscalls[num] != NULL) {
ffffffffc0205596:	00002797          	auipc	a5,0x2
ffffffffc020559a:	46278793          	addi	a5,a5,1122 # ffffffffc02079f8 <syscalls>
ffffffffc020559e:	00369613          	slli	a2,a3,0x3
ffffffffc02055a2:	97b2                	add	a5,a5,a2
ffffffffc02055a4:	639c                	ld	a5,0(a5)
ffffffffc02055a6:	c395                	beqz	a5,ffffffffc02055ca <syscall+0x4c>
            arg[0] = tf->gpr.a1;
ffffffffc02055a8:	7028                	ld	a0,96(s0)
ffffffffc02055aa:	742c                	ld	a1,104(s0)
ffffffffc02055ac:	7830                	ld	a2,112(s0)
ffffffffc02055ae:	7c34                	ld	a3,120(s0)
ffffffffc02055b0:	6c38                	ld	a4,88(s0)
ffffffffc02055b2:	f02a                	sd	a0,32(sp)
ffffffffc02055b4:	f42e                	sd	a1,40(sp)
ffffffffc02055b6:	f832                	sd	a2,48(sp)
ffffffffc02055b8:	fc36                	sd	a3,56(sp)
ffffffffc02055ba:	ec3a                	sd	a4,24(sp)
            arg[1] = tf->gpr.a2;
            arg[2] = tf->gpr.a3;
            arg[3] = tf->gpr.a4;
            arg[4] = tf->gpr.a5;
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02055bc:	0828                	addi	a0,sp,24
ffffffffc02055be:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc02055c0:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02055c2:	e828                	sd	a0,80(s0)
}
ffffffffc02055c4:	6406                	ld	s0,64(sp)
ffffffffc02055c6:	6161                	addi	sp,sp,80
ffffffffc02055c8:	8082                	ret
    print_trapframe(tf);
ffffffffc02055ca:	8522                	mv	a0,s0
ffffffffc02055cc:	e436                	sd	a3,8(sp)
ffffffffc02055ce:	d26fb0ef          	jal	ffffffffc0200af4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc02055d2:	000a1797          	auipc	a5,0xa1
ffffffffc02055d6:	8de7b783          	ld	a5,-1826(a5) # ffffffffc02a5eb0 <current>
ffffffffc02055da:	66a2                	ld	a3,8(sp)
ffffffffc02055dc:	00002617          	auipc	a2,0x2
ffffffffc02055e0:	1f460613          	addi	a2,a2,500 # ffffffffc02077d0 <etext+0x1d16>
ffffffffc02055e4:	43d8                	lw	a4,4(a5)
ffffffffc02055e6:	06200593          	li	a1,98
ffffffffc02055ea:	0b478793          	addi	a5,a5,180
ffffffffc02055ee:	00002517          	auipc	a0,0x2
ffffffffc02055f2:	21250513          	addi	a0,a0,530 # ffffffffc0207800 <etext+0x1d46>
ffffffffc02055f6:	e51fa0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02055fa <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02055fa:	9e3707b7          	lui	a5,0x9e370
ffffffffc02055fe:	2785                	addiw	a5,a5,1 # ffffffff9e370001 <_binary_obj___user_COW_out_size+0xffffffff9e365be1>
ffffffffc0205600:	02a787bb          	mulw	a5,a5,a0
    return (hash >> (32 - bits));
ffffffffc0205604:	02000513          	li	a0,32
ffffffffc0205608:	9d0d                	subw	a0,a0,a1
}
ffffffffc020560a:	00a7d53b          	srlw	a0,a5,a0
ffffffffc020560e:	8082                	ret

ffffffffc0205610 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205610:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0205612:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205616:	f022                	sd	s0,32(sp)
ffffffffc0205618:	ec26                	sd	s1,24(sp)
ffffffffc020561a:	e84a                	sd	s2,16(sp)
ffffffffc020561c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020561e:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205622:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc0205624:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0205628:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020562c:	84aa                	mv	s1,a0
ffffffffc020562e:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc0205630:	03067d63          	bgeu	a2,a6,ffffffffc020566a <printnum+0x5a>
ffffffffc0205634:	e44e                	sd	s3,8(sp)
ffffffffc0205636:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0205638:	4785                	li	a5,1
ffffffffc020563a:	00e7d763          	bge	a5,a4,ffffffffc0205648 <printnum+0x38>
            putch(padc, putdat);
ffffffffc020563e:	85ca                	mv	a1,s2
ffffffffc0205640:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0205642:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0205644:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0205646:	fc65                	bnez	s0,ffffffffc020563e <printnum+0x2e>
ffffffffc0205648:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020564a:	00002797          	auipc	a5,0x2
ffffffffc020564e:	1ce78793          	addi	a5,a5,462 # ffffffffc0207818 <etext+0x1d5e>
ffffffffc0205652:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc0205654:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205656:	0007c503          	lbu	a0,0(a5)
}
ffffffffc020565a:	70a2                	ld	ra,40(sp)
ffffffffc020565c:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020565e:	85ca                	mv	a1,s2
ffffffffc0205660:	87a6                	mv	a5,s1
}
ffffffffc0205662:	6942                	ld	s2,16(sp)
ffffffffc0205664:	64e2                	ld	s1,24(sp)
ffffffffc0205666:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205668:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020566a:	03065633          	divu	a2,a2,a6
ffffffffc020566e:	8722                	mv	a4,s0
ffffffffc0205670:	fa1ff0ef          	jal	ffffffffc0205610 <printnum>
ffffffffc0205674:	bfd9                	j	ffffffffc020564a <printnum+0x3a>

ffffffffc0205676 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0205676:	7119                	addi	sp,sp,-128
ffffffffc0205678:	f4a6                	sd	s1,104(sp)
ffffffffc020567a:	f0ca                	sd	s2,96(sp)
ffffffffc020567c:	ecce                	sd	s3,88(sp)
ffffffffc020567e:	e8d2                	sd	s4,80(sp)
ffffffffc0205680:	e4d6                	sd	s5,72(sp)
ffffffffc0205682:	e0da                	sd	s6,64(sp)
ffffffffc0205684:	f862                	sd	s8,48(sp)
ffffffffc0205686:	fc86                	sd	ra,120(sp)
ffffffffc0205688:	f8a2                	sd	s0,112(sp)
ffffffffc020568a:	fc5e                	sd	s7,56(sp)
ffffffffc020568c:	f466                	sd	s9,40(sp)
ffffffffc020568e:	f06a                	sd	s10,32(sp)
ffffffffc0205690:	ec6e                	sd	s11,24(sp)
ffffffffc0205692:	84aa                	mv	s1,a0
ffffffffc0205694:	8c32                	mv	s8,a2
ffffffffc0205696:	8a36                	mv	s4,a3
ffffffffc0205698:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020569a:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020569e:	05500b13          	li	s6,85
ffffffffc02056a2:	00002a97          	auipc	s5,0x2
ffffffffc02056a6:	456a8a93          	addi	s5,s5,1110 # ffffffffc0207af8 <syscalls+0x100>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02056aa:	000c4503          	lbu	a0,0(s8)
ffffffffc02056ae:	001c0413          	addi	s0,s8,1
ffffffffc02056b2:	01350a63          	beq	a0,s3,ffffffffc02056c6 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc02056b6:	cd0d                	beqz	a0,ffffffffc02056f0 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc02056b8:	85ca                	mv	a1,s2
ffffffffc02056ba:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02056bc:	00044503          	lbu	a0,0(s0)
ffffffffc02056c0:	0405                	addi	s0,s0,1
ffffffffc02056c2:	ff351ae3          	bne	a0,s3,ffffffffc02056b6 <vprintfmt+0x40>
        width = precision = -1;
ffffffffc02056c6:	5cfd                	li	s9,-1
ffffffffc02056c8:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc02056ca:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc02056ce:	4b81                	li	s7,0
ffffffffc02056d0:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02056d2:	00044683          	lbu	a3,0(s0)
ffffffffc02056d6:	00140c13          	addi	s8,s0,1
ffffffffc02056da:	fdd6859b          	addiw	a1,a3,-35
ffffffffc02056de:	0ff5f593          	zext.b	a1,a1
ffffffffc02056e2:	02bb6663          	bltu	s6,a1,ffffffffc020570e <vprintfmt+0x98>
ffffffffc02056e6:	058a                	slli	a1,a1,0x2
ffffffffc02056e8:	95d6                	add	a1,a1,s5
ffffffffc02056ea:	4198                	lw	a4,0(a1)
ffffffffc02056ec:	9756                	add	a4,a4,s5
ffffffffc02056ee:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02056f0:	70e6                	ld	ra,120(sp)
ffffffffc02056f2:	7446                	ld	s0,112(sp)
ffffffffc02056f4:	74a6                	ld	s1,104(sp)
ffffffffc02056f6:	7906                	ld	s2,96(sp)
ffffffffc02056f8:	69e6                	ld	s3,88(sp)
ffffffffc02056fa:	6a46                	ld	s4,80(sp)
ffffffffc02056fc:	6aa6                	ld	s5,72(sp)
ffffffffc02056fe:	6b06                	ld	s6,64(sp)
ffffffffc0205700:	7be2                	ld	s7,56(sp)
ffffffffc0205702:	7c42                	ld	s8,48(sp)
ffffffffc0205704:	7ca2                	ld	s9,40(sp)
ffffffffc0205706:	7d02                	ld	s10,32(sp)
ffffffffc0205708:	6de2                	ld	s11,24(sp)
ffffffffc020570a:	6109                	addi	sp,sp,128
ffffffffc020570c:	8082                	ret
            putch('%', putdat);
ffffffffc020570e:	85ca                	mv	a1,s2
ffffffffc0205710:	02500513          	li	a0,37
ffffffffc0205714:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0205716:	fff44783          	lbu	a5,-1(s0)
ffffffffc020571a:	02500713          	li	a4,37
ffffffffc020571e:	8c22                	mv	s8,s0
ffffffffc0205720:	f8e785e3          	beq	a5,a4,ffffffffc02056aa <vprintfmt+0x34>
ffffffffc0205724:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0205728:	1c7d                	addi	s8,s8,-1
ffffffffc020572a:	fee79de3          	bne	a5,a4,ffffffffc0205724 <vprintfmt+0xae>
ffffffffc020572e:	bfb5                	j	ffffffffc02056aa <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0205730:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0205734:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc0205736:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc020573a:	fd06071b          	addiw	a4,a2,-48
ffffffffc020573e:	24e56a63          	bltu	a0,a4,ffffffffc0205992 <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc0205742:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205744:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc0205746:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc020574a:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020574e:	0197073b          	addw	a4,a4,s9
ffffffffc0205752:	0017171b          	slliw	a4,a4,0x1
ffffffffc0205756:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205758:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020575c:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020575e:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0205762:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc0205766:	feb570e3          	bgeu	a0,a1,ffffffffc0205746 <vprintfmt+0xd0>
            if (width < 0)
ffffffffc020576a:	f60d54e3          	bgez	s10,ffffffffc02056d2 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc020576e:	8d66                	mv	s10,s9
ffffffffc0205770:	5cfd                	li	s9,-1
ffffffffc0205772:	b785                	j	ffffffffc02056d2 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205774:	8db6                	mv	s11,a3
ffffffffc0205776:	8462                	mv	s0,s8
ffffffffc0205778:	bfa9                	j	ffffffffc02056d2 <vprintfmt+0x5c>
ffffffffc020577a:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc020577c:	4b85                	li	s7,1
            goto reswitch;
ffffffffc020577e:	bf91                	j	ffffffffc02056d2 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0205780:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205782:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205786:	00f74463          	blt	a4,a5,ffffffffc020578e <vprintfmt+0x118>
    else if (lflag) {
ffffffffc020578a:	1a078763          	beqz	a5,ffffffffc0205938 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc020578e:	000a3603          	ld	a2,0(s4)
ffffffffc0205792:	46c1                	li	a3,16
ffffffffc0205794:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0205796:	000d879b          	sext.w	a5,s11
ffffffffc020579a:	876a                	mv	a4,s10
ffffffffc020579c:	85ca                	mv	a1,s2
ffffffffc020579e:	8526                	mv	a0,s1
ffffffffc02057a0:	e71ff0ef          	jal	ffffffffc0205610 <printnum>
            break;
ffffffffc02057a4:	b719                	j	ffffffffc02056aa <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc02057a6:	000a2503          	lw	a0,0(s4)
ffffffffc02057aa:	85ca                	mv	a1,s2
ffffffffc02057ac:	0a21                	addi	s4,s4,8
ffffffffc02057ae:	9482                	jalr	s1
            break;
ffffffffc02057b0:	bded                	j	ffffffffc02056aa <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02057b2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02057b4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02057b8:	00f74463          	blt	a4,a5,ffffffffc02057c0 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc02057bc:	16078963          	beqz	a5,ffffffffc020592e <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc02057c0:	000a3603          	ld	a2,0(s4)
ffffffffc02057c4:	46a9                	li	a3,10
ffffffffc02057c6:	8a2e                	mv	s4,a1
ffffffffc02057c8:	b7f9                	j	ffffffffc0205796 <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc02057ca:	85ca                	mv	a1,s2
ffffffffc02057cc:	03000513          	li	a0,48
ffffffffc02057d0:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc02057d2:	85ca                	mv	a1,s2
ffffffffc02057d4:	07800513          	li	a0,120
ffffffffc02057d8:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02057da:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc02057de:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02057e0:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02057e2:	bf55                	j	ffffffffc0205796 <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc02057e4:	85ca                	mv	a1,s2
ffffffffc02057e6:	02500513          	li	a0,37
ffffffffc02057ea:	9482                	jalr	s1
            break;
ffffffffc02057ec:	bd7d                	j	ffffffffc02056aa <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc02057ee:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02057f2:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc02057f4:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc02057f6:	bf95                	j	ffffffffc020576a <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc02057f8:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02057fa:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02057fe:	00f74463          	blt	a4,a5,ffffffffc0205806 <vprintfmt+0x190>
    else if (lflag) {
ffffffffc0205802:	12078163          	beqz	a5,ffffffffc0205924 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc0205806:	000a3603          	ld	a2,0(s4)
ffffffffc020580a:	46a1                	li	a3,8
ffffffffc020580c:	8a2e                	mv	s4,a1
ffffffffc020580e:	b761                	j	ffffffffc0205796 <vprintfmt+0x120>
            if (width < 0)
ffffffffc0205810:	876a                	mv	a4,s10
ffffffffc0205812:	000d5363          	bgez	s10,ffffffffc0205818 <vprintfmt+0x1a2>
ffffffffc0205816:	4701                	li	a4,0
ffffffffc0205818:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020581c:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc020581e:	bd55                	j	ffffffffc02056d2 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc0205820:	000d841b          	sext.w	s0,s11
ffffffffc0205824:	fd340793          	addi	a5,s0,-45
ffffffffc0205828:	00f037b3          	snez	a5,a5
ffffffffc020582c:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205830:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc0205834:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205836:	008a0793          	addi	a5,s4,8
ffffffffc020583a:	e43e                	sd	a5,8(sp)
ffffffffc020583c:	100d8c63          	beqz	s11,ffffffffc0205954 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0205840:	12071363          	bnez	a4,ffffffffc0205966 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205844:	000dc783          	lbu	a5,0(s11)
ffffffffc0205848:	0007851b          	sext.w	a0,a5
ffffffffc020584c:	c78d                	beqz	a5,ffffffffc0205876 <vprintfmt+0x200>
ffffffffc020584e:	0d85                	addi	s11,s11,1
ffffffffc0205850:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205852:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205856:	000cc563          	bltz	s9,ffffffffc0205860 <vprintfmt+0x1ea>
ffffffffc020585a:	3cfd                	addiw	s9,s9,-1
ffffffffc020585c:	008c8d63          	beq	s9,s0,ffffffffc0205876 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205860:	020b9663          	bnez	s7,ffffffffc020588c <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc0205864:	85ca                	mv	a1,s2
ffffffffc0205866:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205868:	000dc783          	lbu	a5,0(s11)
ffffffffc020586c:	0d85                	addi	s11,s11,1
ffffffffc020586e:	3d7d                	addiw	s10,s10,-1
ffffffffc0205870:	0007851b          	sext.w	a0,a5
ffffffffc0205874:	f3ed                	bnez	a5,ffffffffc0205856 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc0205876:	01a05963          	blez	s10,ffffffffc0205888 <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc020587a:	85ca                	mv	a1,s2
ffffffffc020587c:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0205880:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0205882:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc0205884:	fe0d1be3          	bnez	s10,ffffffffc020587a <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205888:	6a22                	ld	s4,8(sp)
ffffffffc020588a:	b505                	j	ffffffffc02056aa <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020588c:	3781                	addiw	a5,a5,-32
ffffffffc020588e:	fcfa7be3          	bgeu	s4,a5,ffffffffc0205864 <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0205892:	03f00513          	li	a0,63
ffffffffc0205896:	85ca                	mv	a1,s2
ffffffffc0205898:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020589a:	000dc783          	lbu	a5,0(s11)
ffffffffc020589e:	0d85                	addi	s11,s11,1
ffffffffc02058a0:	3d7d                	addiw	s10,s10,-1
ffffffffc02058a2:	0007851b          	sext.w	a0,a5
ffffffffc02058a6:	dbe1                	beqz	a5,ffffffffc0205876 <vprintfmt+0x200>
ffffffffc02058a8:	fa0cd9e3          	bgez	s9,ffffffffc020585a <vprintfmt+0x1e4>
ffffffffc02058ac:	b7c5                	j	ffffffffc020588c <vprintfmt+0x216>
            if (err < 0) {
ffffffffc02058ae:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02058b2:	4661                	li	a2,24
            err = va_arg(ap, int);
ffffffffc02058b4:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02058b6:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc02058ba:	8fb9                	xor	a5,a5,a4
ffffffffc02058bc:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02058c0:	02d64563          	blt	a2,a3,ffffffffc02058ea <vprintfmt+0x274>
ffffffffc02058c4:	00002797          	auipc	a5,0x2
ffffffffc02058c8:	38c78793          	addi	a5,a5,908 # ffffffffc0207c50 <error_string>
ffffffffc02058cc:	00369713          	slli	a4,a3,0x3
ffffffffc02058d0:	97ba                	add	a5,a5,a4
ffffffffc02058d2:	639c                	ld	a5,0(a5)
ffffffffc02058d4:	cb99                	beqz	a5,ffffffffc02058ea <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc02058d6:	86be                	mv	a3,a5
ffffffffc02058d8:	00000617          	auipc	a2,0x0
ffffffffc02058dc:	21060613          	addi	a2,a2,528 # ffffffffc0205ae8 <etext+0x2e>
ffffffffc02058e0:	85ca                	mv	a1,s2
ffffffffc02058e2:	8526                	mv	a0,s1
ffffffffc02058e4:	0d8000ef          	jal	ffffffffc02059bc <printfmt>
ffffffffc02058e8:	b3c9                	j	ffffffffc02056aa <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02058ea:	00002617          	auipc	a2,0x2
ffffffffc02058ee:	f4e60613          	addi	a2,a2,-178 # ffffffffc0207838 <etext+0x1d7e>
ffffffffc02058f2:	85ca                	mv	a1,s2
ffffffffc02058f4:	8526                	mv	a0,s1
ffffffffc02058f6:	0c6000ef          	jal	ffffffffc02059bc <printfmt>
ffffffffc02058fa:	bb45                	j	ffffffffc02056aa <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02058fc:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02058fe:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0205902:	00f74363          	blt	a4,a5,ffffffffc0205908 <vprintfmt+0x292>
    else if (lflag) {
ffffffffc0205906:	cf81                	beqz	a5,ffffffffc020591e <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc0205908:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020590c:	02044b63          	bltz	s0,ffffffffc0205942 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0205910:	8622                	mv	a2,s0
ffffffffc0205912:	8a5e                	mv	s4,s7
ffffffffc0205914:	46a9                	li	a3,10
ffffffffc0205916:	b541                	j	ffffffffc0205796 <vprintfmt+0x120>
            lflag ++;
ffffffffc0205918:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020591a:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc020591c:	bb5d                	j	ffffffffc02056d2 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc020591e:	000a2403          	lw	s0,0(s4)
ffffffffc0205922:	b7ed                	j	ffffffffc020590c <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc0205924:	000a6603          	lwu	a2,0(s4)
ffffffffc0205928:	46a1                	li	a3,8
ffffffffc020592a:	8a2e                	mv	s4,a1
ffffffffc020592c:	b5ad                	j	ffffffffc0205796 <vprintfmt+0x120>
ffffffffc020592e:	000a6603          	lwu	a2,0(s4)
ffffffffc0205932:	46a9                	li	a3,10
ffffffffc0205934:	8a2e                	mv	s4,a1
ffffffffc0205936:	b585                	j	ffffffffc0205796 <vprintfmt+0x120>
ffffffffc0205938:	000a6603          	lwu	a2,0(s4)
ffffffffc020593c:	46c1                	li	a3,16
ffffffffc020593e:	8a2e                	mv	s4,a1
ffffffffc0205940:	bd99                	j	ffffffffc0205796 <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc0205942:	85ca                	mv	a1,s2
ffffffffc0205944:	02d00513          	li	a0,45
ffffffffc0205948:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc020594a:	40800633          	neg	a2,s0
ffffffffc020594e:	8a5e                	mv	s4,s7
ffffffffc0205950:	46a9                	li	a3,10
ffffffffc0205952:	b591                	j	ffffffffc0205796 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc0205954:	e329                	bnez	a4,ffffffffc0205996 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205956:	02800793          	li	a5,40
ffffffffc020595a:	853e                	mv	a0,a5
ffffffffc020595c:	00002d97          	auipc	s11,0x2
ffffffffc0205960:	ed5d8d93          	addi	s11,s11,-299 # ffffffffc0207831 <etext+0x1d77>
ffffffffc0205964:	b5f5                	j	ffffffffc0205850 <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205966:	85e6                	mv	a1,s9
ffffffffc0205968:	856e                	mv	a0,s11
ffffffffc020596a:	08a000ef          	jal	ffffffffc02059f4 <strnlen>
ffffffffc020596e:	40ad0d3b          	subw	s10,s10,a0
ffffffffc0205972:	01a05863          	blez	s10,ffffffffc0205982 <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc0205976:	85ca                	mv	a1,s2
ffffffffc0205978:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020597a:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc020597c:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020597e:	fe0d1ce3          	bnez	s10,ffffffffc0205976 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205982:	000dc783          	lbu	a5,0(s11)
ffffffffc0205986:	0007851b          	sext.w	a0,a5
ffffffffc020598a:	ec0792e3          	bnez	a5,ffffffffc020584e <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020598e:	6a22                	ld	s4,8(sp)
ffffffffc0205990:	bb29                	j	ffffffffc02056aa <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205992:	8462                	mv	s0,s8
ffffffffc0205994:	bbd9                	j	ffffffffc020576a <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205996:	85e6                	mv	a1,s9
ffffffffc0205998:	00002517          	auipc	a0,0x2
ffffffffc020599c:	e9850513          	addi	a0,a0,-360 # ffffffffc0207830 <etext+0x1d76>
ffffffffc02059a0:	054000ef          	jal	ffffffffc02059f4 <strnlen>
ffffffffc02059a4:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02059a8:	02800793          	li	a5,40
                p = "(null)";
ffffffffc02059ac:	00002d97          	auipc	s11,0x2
ffffffffc02059b0:	e84d8d93          	addi	s11,s11,-380 # ffffffffc0207830 <etext+0x1d76>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02059b4:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02059b6:	fda040e3          	bgtz	s10,ffffffffc0205976 <vprintfmt+0x300>
ffffffffc02059ba:	bd51                	j	ffffffffc020584e <vprintfmt+0x1d8>

ffffffffc02059bc <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02059bc:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02059be:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02059c2:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02059c4:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02059c6:	ec06                	sd	ra,24(sp)
ffffffffc02059c8:	f83a                	sd	a4,48(sp)
ffffffffc02059ca:	fc3e                	sd	a5,56(sp)
ffffffffc02059cc:	e0c2                	sd	a6,64(sp)
ffffffffc02059ce:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02059d0:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02059d2:	ca5ff0ef          	jal	ffffffffc0205676 <vprintfmt>
}
ffffffffc02059d6:	60e2                	ld	ra,24(sp)
ffffffffc02059d8:	6161                	addi	sp,sp,80
ffffffffc02059da:	8082                	ret

ffffffffc02059dc <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02059dc:	00054783          	lbu	a5,0(a0)
ffffffffc02059e0:	cb81                	beqz	a5,ffffffffc02059f0 <strlen+0x14>
    size_t cnt = 0;
ffffffffc02059e2:	4781                	li	a5,0
        cnt ++;
ffffffffc02059e4:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc02059e6:	00f50733          	add	a4,a0,a5
ffffffffc02059ea:	00074703          	lbu	a4,0(a4)
ffffffffc02059ee:	fb7d                	bnez	a4,ffffffffc02059e4 <strlen+0x8>
    }
    return cnt;
}
ffffffffc02059f0:	853e                	mv	a0,a5
ffffffffc02059f2:	8082                	ret

ffffffffc02059f4 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02059f4:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02059f6:	e589                	bnez	a1,ffffffffc0205a00 <strnlen+0xc>
ffffffffc02059f8:	a811                	j	ffffffffc0205a0c <strnlen+0x18>
        cnt ++;
ffffffffc02059fa:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02059fc:	00f58863          	beq	a1,a5,ffffffffc0205a0c <strnlen+0x18>
ffffffffc0205a00:	00f50733          	add	a4,a0,a5
ffffffffc0205a04:	00074703          	lbu	a4,0(a4)
ffffffffc0205a08:	fb6d                	bnez	a4,ffffffffc02059fa <strnlen+0x6>
ffffffffc0205a0a:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0205a0c:	852e                	mv	a0,a1
ffffffffc0205a0e:	8082                	ret

ffffffffc0205a10 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0205a10:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0205a12:	0005c703          	lbu	a4,0(a1)
ffffffffc0205a16:	0585                	addi	a1,a1,1
ffffffffc0205a18:	0785                	addi	a5,a5,1
ffffffffc0205a1a:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0205a1e:	fb75                	bnez	a4,ffffffffc0205a12 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0205a20:	8082                	ret

ffffffffc0205a22 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205a22:	00054783          	lbu	a5,0(a0)
ffffffffc0205a26:	e791                	bnez	a5,ffffffffc0205a32 <strcmp+0x10>
ffffffffc0205a28:	a01d                	j	ffffffffc0205a4e <strcmp+0x2c>
ffffffffc0205a2a:	00054783          	lbu	a5,0(a0)
ffffffffc0205a2e:	cb99                	beqz	a5,ffffffffc0205a44 <strcmp+0x22>
ffffffffc0205a30:	0585                	addi	a1,a1,1
ffffffffc0205a32:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0205a36:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205a38:	fef709e3          	beq	a4,a5,ffffffffc0205a2a <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205a3c:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0205a40:	9d19                	subw	a0,a0,a4
ffffffffc0205a42:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205a44:	0015c703          	lbu	a4,1(a1)
ffffffffc0205a48:	4501                	li	a0,0
}
ffffffffc0205a4a:	9d19                	subw	a0,a0,a4
ffffffffc0205a4c:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205a4e:	0005c703          	lbu	a4,0(a1)
ffffffffc0205a52:	4501                	li	a0,0
ffffffffc0205a54:	b7f5                	j	ffffffffc0205a40 <strcmp+0x1e>

ffffffffc0205a56 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205a56:	ce01                	beqz	a2,ffffffffc0205a6e <strncmp+0x18>
ffffffffc0205a58:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205a5c:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205a5e:	cb91                	beqz	a5,ffffffffc0205a72 <strncmp+0x1c>
ffffffffc0205a60:	0005c703          	lbu	a4,0(a1)
ffffffffc0205a64:	00f71763          	bne	a4,a5,ffffffffc0205a72 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0205a68:	0505                	addi	a0,a0,1
ffffffffc0205a6a:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205a6c:	f675                	bnez	a2,ffffffffc0205a58 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205a6e:	4501                	li	a0,0
ffffffffc0205a70:	8082                	ret
ffffffffc0205a72:	00054503          	lbu	a0,0(a0)
ffffffffc0205a76:	0005c783          	lbu	a5,0(a1)
ffffffffc0205a7a:	9d1d                	subw	a0,a0,a5
}
ffffffffc0205a7c:	8082                	ret

ffffffffc0205a7e <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0205a7e:	a021                	j	ffffffffc0205a86 <strchr+0x8>
        if (*s == c) {
ffffffffc0205a80:	00f58763          	beq	a1,a5,ffffffffc0205a8e <strchr+0x10>
            return (char *)s;
        }
        s ++;
ffffffffc0205a84:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0205a86:	00054783          	lbu	a5,0(a0)
ffffffffc0205a8a:	fbfd                	bnez	a5,ffffffffc0205a80 <strchr+0x2>
    }
    return NULL;
ffffffffc0205a8c:	4501                	li	a0,0
}
ffffffffc0205a8e:	8082                	ret

ffffffffc0205a90 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205a90:	ca01                	beqz	a2,ffffffffc0205aa0 <memset+0x10>
ffffffffc0205a92:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0205a94:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205a96:	0785                	addi	a5,a5,1
ffffffffc0205a98:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205a9c:	fef61de3          	bne	a2,a5,ffffffffc0205a96 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205aa0:	8082                	ret

ffffffffc0205aa2 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0205aa2:	ca19                	beqz	a2,ffffffffc0205ab8 <memcpy+0x16>
ffffffffc0205aa4:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205aa6:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205aa8:	0005c703          	lbu	a4,0(a1)
ffffffffc0205aac:	0585                	addi	a1,a1,1
ffffffffc0205aae:	0785                	addi	a5,a5,1
ffffffffc0205ab0:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0205ab4:	feb61ae3          	bne	a2,a1,ffffffffc0205aa8 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0205ab8:	8082                	ret
