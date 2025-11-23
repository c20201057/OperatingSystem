
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00009297          	auipc	t0,0x9
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0209000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00009297          	auipc	t0,0x9
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0209008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02082b7          	lui	t0,0xc0208
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
ffffffffc020003c:	c0208137          	lui	sp,0xc0208

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
ffffffffc020004a:	00009517          	auipc	a0,0x9
ffffffffc020004e:	fe650513          	addi	a0,a0,-26 # ffffffffc0209030 <buf>
ffffffffc0200052:	0000d617          	auipc	a2,0xd
ffffffffc0200056:	4a660613          	addi	a2,a2,1190 # ffffffffc020d4f8 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16 # ffffffffc0207ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	67d030ef          	jal	ffffffffc0203ede <memset>
    dtb_init();
ffffffffc0200066:	4c2000ef          	jal	ffffffffc0200528 <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	44c000ef          	jal	ffffffffc02004b6 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00004597          	auipc	a1,0x4
ffffffffc0200072:	ec258593          	addi	a1,a1,-318 # ffffffffc0203f30 <etext+0x4>
ffffffffc0200076:	00004517          	auipc	a0,0x4
ffffffffc020007a:	eda50513          	addi	a0,a0,-294 # ffffffffc0203f50 <etext+0x24>
ffffffffc020007e:	116000ef          	jal	ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	158000ef          	jal	ffffffffc02001da <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	0c8020ef          	jal	ffffffffc020214e <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	7f0000ef          	jal	ffffffffc020087a <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	7ee000ef          	jal	ffffffffc020087c <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	639020ef          	jal	ffffffffc0202eca <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	610030ef          	jal	ffffffffc02036a6 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	3ca000ef          	jal	ffffffffc0200464 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	7d0000ef          	jal	ffffffffc020086e <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	05d030ef          	jal	ffffffffc02038fe <cpu_idle>

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
ffffffffc02000b6:	00004517          	auipc	a0,0x4
ffffffffc02000ba:	ea250513          	addi	a0,a0,-350 # ffffffffc0203f58 <etext+0x2c>
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
ffffffffc02000c6:	00009997          	auipc	s3,0x9
ffffffffc02000ca:	f6a98993          	addi	s3,s3,-150 # ffffffffc0209030 <buf>
        c = getchar();
ffffffffc02000ce:	0fc000ef          	jal	ffffffffc02001ca <getchar>
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
ffffffffc02000fc:	0ce000ef          	jal	ffffffffc02001ca <getchar>
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
ffffffffc0200140:	00009517          	auipc	a0,0x9
ffffffffc0200144:	ef050513          	addi	a0,a0,-272 # ffffffffc0209030 <buf>
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
ffffffffc0200162:	356000ef          	jal	ffffffffc02004b8 <cons_putc>
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
ffffffffc0200188:	13d030ef          	jal	ffffffffc0203ac4 <vprintfmt>
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
ffffffffc02001bc:	109030ef          	jal	ffffffffc0203ac4 <vprintfmt>
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
ffffffffc02001c8:	acc5                	j	ffffffffc02004b8 <cons_putc>

ffffffffc02001ca <getchar>:
}

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc02001ca:	1141                	addi	sp,sp,-16
ffffffffc02001cc:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02001ce:	31e000ef          	jal	ffffffffc02004ec <cons_getc>
ffffffffc02001d2:	dd75                	beqz	a0,ffffffffc02001ce <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc02001d4:	60a2                	ld	ra,8(sp)
ffffffffc02001d6:	0141                	addi	sp,sp,16
ffffffffc02001d8:	8082                	ret

ffffffffc02001da <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc02001da:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001dc:	00004517          	auipc	a0,0x4
ffffffffc02001e0:	d8450513          	addi	a0,a0,-636 # ffffffffc0203f60 <etext+0x34>
{
ffffffffc02001e4:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001e6:	fafff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc02001ea:	00000597          	auipc	a1,0x0
ffffffffc02001ee:	e6058593          	addi	a1,a1,-416 # ffffffffc020004a <kern_init>
ffffffffc02001f2:	00004517          	auipc	a0,0x4
ffffffffc02001f6:	d8e50513          	addi	a0,a0,-626 # ffffffffc0203f80 <etext+0x54>
ffffffffc02001fa:	f9bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc02001fe:	00004597          	auipc	a1,0x4
ffffffffc0200202:	d2e58593          	addi	a1,a1,-722 # ffffffffc0203f2c <etext>
ffffffffc0200206:	00004517          	auipc	a0,0x4
ffffffffc020020a:	d9a50513          	addi	a0,a0,-614 # ffffffffc0203fa0 <etext+0x74>
ffffffffc020020e:	f87ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200212:	00009597          	auipc	a1,0x9
ffffffffc0200216:	e1e58593          	addi	a1,a1,-482 # ffffffffc0209030 <buf>
ffffffffc020021a:	00004517          	auipc	a0,0x4
ffffffffc020021e:	da650513          	addi	a0,a0,-602 # ffffffffc0203fc0 <etext+0x94>
ffffffffc0200222:	f73ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200226:	0000d597          	auipc	a1,0xd
ffffffffc020022a:	2d258593          	addi	a1,a1,722 # ffffffffc020d4f8 <end>
ffffffffc020022e:	00004517          	auipc	a0,0x4
ffffffffc0200232:	db250513          	addi	a0,a0,-590 # ffffffffc0203fe0 <etext+0xb4>
ffffffffc0200236:	f5fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020023a:	00000717          	auipc	a4,0x0
ffffffffc020023e:	e1070713          	addi	a4,a4,-496 # ffffffffc020004a <kern_init>
ffffffffc0200242:	0000d797          	auipc	a5,0xd
ffffffffc0200246:	6b578793          	addi	a5,a5,1717 # ffffffffc020d8f7 <end+0x3ff>
ffffffffc020024a:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020024c:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200250:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200252:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200256:	95be                	add	a1,a1,a5
ffffffffc0200258:	85a9                	srai	a1,a1,0xa
ffffffffc020025a:	00004517          	auipc	a0,0x4
ffffffffc020025e:	da650513          	addi	a0,a0,-602 # ffffffffc0204000 <etext+0xd4>
}
ffffffffc0200262:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200264:	bf05                	j	ffffffffc0200194 <cprintf>

ffffffffc0200266 <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc0200266:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc0200268:	00004617          	auipc	a2,0x4
ffffffffc020026c:	dc860613          	addi	a2,a2,-568 # ffffffffc0204030 <etext+0x104>
ffffffffc0200270:	04900593          	li	a1,73
ffffffffc0200274:	00004517          	auipc	a0,0x4
ffffffffc0200278:	dd450513          	addi	a0,a0,-556 # ffffffffc0204048 <etext+0x11c>
{
ffffffffc020027c:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020027e:	188000ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0200282 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200282:	1101                	addi	sp,sp,-32
ffffffffc0200284:	e822                	sd	s0,16(sp)
ffffffffc0200286:	e426                	sd	s1,8(sp)
ffffffffc0200288:	ec06                	sd	ra,24(sp)
ffffffffc020028a:	00005417          	auipc	s0,0x5
ffffffffc020028e:	5a640413          	addi	s0,s0,1446 # ffffffffc0205830 <commands>
ffffffffc0200292:	00005497          	auipc	s1,0x5
ffffffffc0200296:	5e648493          	addi	s1,s1,1510 # ffffffffc0205878 <commands+0x48>
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020029a:	6410                	ld	a2,8(s0)
ffffffffc020029c:	600c                	ld	a1,0(s0)
ffffffffc020029e:	00004517          	auipc	a0,0x4
ffffffffc02002a2:	dc250513          	addi	a0,a0,-574 # ffffffffc0204060 <etext+0x134>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002a6:	0461                	addi	s0,s0,24
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002a8:	eedff0ef          	jal	ffffffffc0200194 <cprintf>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002ac:	fe9417e3          	bne	s0,s1,ffffffffc020029a <mon_help+0x18>
    }
    return 0;
}
ffffffffc02002b0:	60e2                	ld	ra,24(sp)
ffffffffc02002b2:	6442                	ld	s0,16(sp)
ffffffffc02002b4:	64a2                	ld	s1,8(sp)
ffffffffc02002b6:	4501                	li	a0,0
ffffffffc02002b8:	6105                	addi	sp,sp,32
ffffffffc02002ba:	8082                	ret

ffffffffc02002bc <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002bc:	1141                	addi	sp,sp,-16
ffffffffc02002be:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002c0:	f1bff0ef          	jal	ffffffffc02001da <print_kerninfo>
    return 0;
}
ffffffffc02002c4:	60a2                	ld	ra,8(sp)
ffffffffc02002c6:	4501                	li	a0,0
ffffffffc02002c8:	0141                	addi	sp,sp,16
ffffffffc02002ca:	8082                	ret

ffffffffc02002cc <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002cc:	1141                	addi	sp,sp,-16
ffffffffc02002ce:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002d0:	f97ff0ef          	jal	ffffffffc0200266 <print_stackframe>
    return 0;
}
ffffffffc02002d4:	60a2                	ld	ra,8(sp)
ffffffffc02002d6:	4501                	li	a0,0
ffffffffc02002d8:	0141                	addi	sp,sp,16
ffffffffc02002da:	8082                	ret

ffffffffc02002dc <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02002dc:	7131                	addi	sp,sp,-192
ffffffffc02002de:	e952                	sd	s4,144(sp)
ffffffffc02002e0:	8a2a                	mv	s4,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002e2:	00004517          	auipc	a0,0x4
ffffffffc02002e6:	d8e50513          	addi	a0,a0,-626 # ffffffffc0204070 <etext+0x144>
kmonitor(struct trapframe *tf) {
ffffffffc02002ea:	fd06                	sd	ra,184(sp)
ffffffffc02002ec:	f922                	sd	s0,176(sp)
ffffffffc02002ee:	f526                	sd	s1,168(sp)
ffffffffc02002f0:	f14a                	sd	s2,160(sp)
ffffffffc02002f2:	e556                	sd	s5,136(sp)
ffffffffc02002f4:	e15a                	sd	s6,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002f6:	e9fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002fa:	00004517          	auipc	a0,0x4
ffffffffc02002fe:	d9e50513          	addi	a0,a0,-610 # ffffffffc0204098 <etext+0x16c>
ffffffffc0200302:	e93ff0ef          	jal	ffffffffc0200194 <cprintf>
    if (tf != NULL) {
ffffffffc0200306:	000a0563          	beqz	s4,ffffffffc0200310 <kmonitor+0x34>
        print_trapframe(tf);
ffffffffc020030a:	8552                	mv	a0,s4
ffffffffc020030c:	758000ef          	jal	ffffffffc0200a64 <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200310:	4501                	li	a0,0
ffffffffc0200312:	4581                	li	a1,0
ffffffffc0200314:	4601                	li	a2,0
ffffffffc0200316:	48a1                	li	a7,8
ffffffffc0200318:	00000073          	ecall
ffffffffc020031c:	00005a97          	auipc	s5,0x5
ffffffffc0200320:	514a8a93          	addi	s5,s5,1300 # ffffffffc0205830 <commands>
        if (argc == MAXARGS - 1) {
ffffffffc0200324:	493d                	li	s2,15
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200326:	00004517          	auipc	a0,0x4
ffffffffc020032a:	d9a50513          	addi	a0,a0,-614 # ffffffffc02040c0 <etext+0x194>
ffffffffc020032e:	d79ff0ef          	jal	ffffffffc02000a6 <readline>
ffffffffc0200332:	842a                	mv	s0,a0
ffffffffc0200334:	d96d                	beqz	a0,ffffffffc0200326 <kmonitor+0x4a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200336:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020033a:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020033c:	e99d                	bnez	a1,ffffffffc0200372 <kmonitor+0x96>
    int argc = 0;
ffffffffc020033e:	8b26                	mv	s6,s1
    if (argc == 0) {
ffffffffc0200340:	fe0b03e3          	beqz	s6,ffffffffc0200326 <kmonitor+0x4a>
ffffffffc0200344:	00005497          	auipc	s1,0x5
ffffffffc0200348:	4ec48493          	addi	s1,s1,1260 # ffffffffc0205830 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020034c:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020034e:	6582                	ld	a1,0(sp)
ffffffffc0200350:	6088                	ld	a0,0(s1)
ffffffffc0200352:	31f030ef          	jal	ffffffffc0203e70 <strcmp>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200356:	478d                	li	a5,3
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200358:	c149                	beqz	a0,ffffffffc02003da <kmonitor+0xfe>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020035a:	2405                	addiw	s0,s0,1
ffffffffc020035c:	04e1                	addi	s1,s1,24
ffffffffc020035e:	fef418e3          	bne	s0,a5,ffffffffc020034e <kmonitor+0x72>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200362:	6582                	ld	a1,0(sp)
ffffffffc0200364:	00004517          	auipc	a0,0x4
ffffffffc0200368:	d8c50513          	addi	a0,a0,-628 # ffffffffc02040f0 <etext+0x1c4>
ffffffffc020036c:	e29ff0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
ffffffffc0200370:	bf5d                	j	ffffffffc0200326 <kmonitor+0x4a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200372:	00004517          	auipc	a0,0x4
ffffffffc0200376:	d5650513          	addi	a0,a0,-682 # ffffffffc02040c8 <etext+0x19c>
ffffffffc020037a:	353030ef          	jal	ffffffffc0203ecc <strchr>
ffffffffc020037e:	c901                	beqz	a0,ffffffffc020038e <kmonitor+0xb2>
ffffffffc0200380:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200384:	00040023          	sb	zero,0(s0)
ffffffffc0200388:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020038a:	d9d5                	beqz	a1,ffffffffc020033e <kmonitor+0x62>
ffffffffc020038c:	b7dd                	j	ffffffffc0200372 <kmonitor+0x96>
        if (*buf == '\0') {
ffffffffc020038e:	00044783          	lbu	a5,0(s0)
ffffffffc0200392:	d7d5                	beqz	a5,ffffffffc020033e <kmonitor+0x62>
        if (argc == MAXARGS - 1) {
ffffffffc0200394:	03248b63          	beq	s1,s2,ffffffffc02003ca <kmonitor+0xee>
        argv[argc ++] = buf;
ffffffffc0200398:	00349793          	slli	a5,s1,0x3
ffffffffc020039c:	978a                	add	a5,a5,sp
ffffffffc020039e:	e380                	sd	s0,0(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a0:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003a4:	2485                	addiw	s1,s1,1
ffffffffc02003a6:	8b26                	mv	s6,s1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a8:	e591                	bnez	a1,ffffffffc02003b4 <kmonitor+0xd8>
ffffffffc02003aa:	bf59                	j	ffffffffc0200340 <kmonitor+0x64>
ffffffffc02003ac:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003b0:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003b2:	d5d1                	beqz	a1,ffffffffc020033e <kmonitor+0x62>
ffffffffc02003b4:	00004517          	auipc	a0,0x4
ffffffffc02003b8:	d1450513          	addi	a0,a0,-748 # ffffffffc02040c8 <etext+0x19c>
ffffffffc02003bc:	311030ef          	jal	ffffffffc0203ecc <strchr>
ffffffffc02003c0:	d575                	beqz	a0,ffffffffc02003ac <kmonitor+0xd0>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003c2:	00044583          	lbu	a1,0(s0)
ffffffffc02003c6:	dda5                	beqz	a1,ffffffffc020033e <kmonitor+0x62>
ffffffffc02003c8:	b76d                	j	ffffffffc0200372 <kmonitor+0x96>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003ca:	45c1                	li	a1,16
ffffffffc02003cc:	00004517          	auipc	a0,0x4
ffffffffc02003d0:	d0450513          	addi	a0,a0,-764 # ffffffffc02040d0 <etext+0x1a4>
ffffffffc02003d4:	dc1ff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc02003d8:	b7c1                	j	ffffffffc0200398 <kmonitor+0xbc>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003da:	00141793          	slli	a5,s0,0x1
ffffffffc02003de:	97a2                	add	a5,a5,s0
ffffffffc02003e0:	078e                	slli	a5,a5,0x3
ffffffffc02003e2:	97d6                	add	a5,a5,s5
ffffffffc02003e4:	6b9c                	ld	a5,16(a5)
ffffffffc02003e6:	fffb051b          	addiw	a0,s6,-1
ffffffffc02003ea:	8652                	mv	a2,s4
ffffffffc02003ec:	002c                	addi	a1,sp,8
ffffffffc02003ee:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003f0:	f2055be3          	bgez	a0,ffffffffc0200326 <kmonitor+0x4a>
}
ffffffffc02003f4:	70ea                	ld	ra,184(sp)
ffffffffc02003f6:	744a                	ld	s0,176(sp)
ffffffffc02003f8:	74aa                	ld	s1,168(sp)
ffffffffc02003fa:	790a                	ld	s2,160(sp)
ffffffffc02003fc:	6a4a                	ld	s4,144(sp)
ffffffffc02003fe:	6aaa                	ld	s5,136(sp)
ffffffffc0200400:	6b0a                	ld	s6,128(sp)
ffffffffc0200402:	6129                	addi	sp,sp,192
ffffffffc0200404:	8082                	ret

ffffffffc0200406 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200406:	0000d317          	auipc	t1,0xd
ffffffffc020040a:	06232303          	lw	t1,98(t1) # ffffffffc020d468 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020040e:	715d                	addi	sp,sp,-80
ffffffffc0200410:	ec06                	sd	ra,24(sp)
ffffffffc0200412:	f436                	sd	a3,40(sp)
ffffffffc0200414:	f83a                	sd	a4,48(sp)
ffffffffc0200416:	fc3e                	sd	a5,56(sp)
ffffffffc0200418:	e0c2                	sd	a6,64(sp)
ffffffffc020041a:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc020041c:	02031e63          	bnez	t1,ffffffffc0200458 <__panic+0x52>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200420:	4705                	li	a4,1

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200422:	103c                	addi	a5,sp,40
ffffffffc0200424:	e822                	sd	s0,16(sp)
ffffffffc0200426:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200428:	862e                	mv	a2,a1
ffffffffc020042a:	85aa                	mv	a1,a0
ffffffffc020042c:	00004517          	auipc	a0,0x4
ffffffffc0200430:	d6c50513          	addi	a0,a0,-660 # ffffffffc0204198 <etext+0x26c>
    is_panic = 1;
ffffffffc0200434:	0000d697          	auipc	a3,0xd
ffffffffc0200438:	02e6aa23          	sw	a4,52(a3) # ffffffffc020d468 <is_panic>
    va_start(ap, fmt);
ffffffffc020043c:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020043e:	d57ff0ef          	jal	ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200442:	65a2                	ld	a1,8(sp)
ffffffffc0200444:	8522                	mv	a0,s0
ffffffffc0200446:	d2fff0ef          	jal	ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc020044a:	00004517          	auipc	a0,0x4
ffffffffc020044e:	d6e50513          	addi	a0,a0,-658 # ffffffffc02041b8 <etext+0x28c>
ffffffffc0200452:	d43ff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0200456:	6442                	ld	s0,16(sp)
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200458:	41c000ef          	jal	ffffffffc0200874 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc020045c:	4501                	li	a0,0
ffffffffc020045e:	e7fff0ef          	jal	ffffffffc02002dc <kmonitor>
    while (1) {
ffffffffc0200462:	bfed                	j	ffffffffc020045c <__panic+0x56>

ffffffffc0200464 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc0200464:	67e1                	lui	a5,0x18
ffffffffc0200466:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020046a:	0000d717          	auipc	a4,0xd
ffffffffc020046e:	00f73323          	sd	a5,6(a4) # ffffffffc020d470 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200472:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200476:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200478:	953e                	add	a0,a0,a5
ffffffffc020047a:	4601                	li	a2,0
ffffffffc020047c:	4881                	li	a7,0
ffffffffc020047e:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200482:	02000793          	li	a5,32
ffffffffc0200486:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020048a:	00004517          	auipc	a0,0x4
ffffffffc020048e:	d3650513          	addi	a0,a0,-714 # ffffffffc02041c0 <etext+0x294>
    ticks = 0;
ffffffffc0200492:	0000d797          	auipc	a5,0xd
ffffffffc0200496:	fe07b323          	sd	zero,-26(a5) # ffffffffc020d478 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020049a:	b9ed                	j	ffffffffc0200194 <cprintf>

ffffffffc020049c <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020049c:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004a0:	0000d797          	auipc	a5,0xd
ffffffffc02004a4:	fd07b783          	ld	a5,-48(a5) # ffffffffc020d470 <timebase>
ffffffffc02004a8:	4581                	li	a1,0
ffffffffc02004aa:	4601                	li	a2,0
ffffffffc02004ac:	953e                	add	a0,a0,a5
ffffffffc02004ae:	4881                	li	a7,0
ffffffffc02004b0:	00000073          	ecall
ffffffffc02004b4:	8082                	ret

ffffffffc02004b6 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02004b6:	8082                	ret

ffffffffc02004b8 <cons_putc>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02004b8:	100027f3          	csrr	a5,sstatus
ffffffffc02004bc:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc02004be:	0ff57513          	zext.b	a0,a0
ffffffffc02004c2:	e799                	bnez	a5,ffffffffc02004d0 <cons_putc+0x18>
ffffffffc02004c4:	4581                	li	a1,0
ffffffffc02004c6:	4601                	li	a2,0
ffffffffc02004c8:	4885                	li	a7,1
ffffffffc02004ca:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc02004ce:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02004d0:	1101                	addi	sp,sp,-32
ffffffffc02004d2:	ec06                	sd	ra,24(sp)
ffffffffc02004d4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02004d6:	39e000ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc02004da:	6522                	ld	a0,8(sp)
ffffffffc02004dc:	4581                	li	a1,0
ffffffffc02004de:	4601                	li	a2,0
ffffffffc02004e0:	4885                	li	a7,1
ffffffffc02004e2:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02004e6:	60e2                	ld	ra,24(sp)
ffffffffc02004e8:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02004ea:	a651                	j	ffffffffc020086e <intr_enable>

ffffffffc02004ec <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02004ec:	100027f3          	csrr	a5,sstatus
ffffffffc02004f0:	8b89                	andi	a5,a5,2
ffffffffc02004f2:	eb89                	bnez	a5,ffffffffc0200504 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02004f4:	4501                	li	a0,0
ffffffffc02004f6:	4581                	li	a1,0
ffffffffc02004f8:	4601                	li	a2,0
ffffffffc02004fa:	4889                	li	a7,2
ffffffffc02004fc:	00000073          	ecall
ffffffffc0200500:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200502:	8082                	ret
int cons_getc(void) {
ffffffffc0200504:	1101                	addi	sp,sp,-32
ffffffffc0200506:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200508:	36c000ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc020050c:	4501                	li	a0,0
ffffffffc020050e:	4581                	li	a1,0
ffffffffc0200510:	4601                	li	a2,0
ffffffffc0200512:	4889                	li	a7,2
ffffffffc0200514:	00000073          	ecall
ffffffffc0200518:	2501                	sext.w	a0,a0
ffffffffc020051a:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020051c:	352000ef          	jal	ffffffffc020086e <intr_enable>
}
ffffffffc0200520:	60e2                	ld	ra,24(sp)
ffffffffc0200522:	6522                	ld	a0,8(sp)
ffffffffc0200524:	6105                	addi	sp,sp,32
ffffffffc0200526:	8082                	ret

ffffffffc0200528 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200528:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc020052a:	00004517          	auipc	a0,0x4
ffffffffc020052e:	cb650513          	addi	a0,a0,-842 # ffffffffc02041e0 <etext+0x2b4>
void dtb_init(void) {
ffffffffc0200532:	f406                	sd	ra,40(sp)
ffffffffc0200534:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc0200536:	c5fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020053a:	00009597          	auipc	a1,0x9
ffffffffc020053e:	ac65b583          	ld	a1,-1338(a1) # ffffffffc0209000 <boot_hartid>
ffffffffc0200542:	00004517          	auipc	a0,0x4
ffffffffc0200546:	cae50513          	addi	a0,a0,-850 # ffffffffc02041f0 <etext+0x2c4>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020054a:	00009417          	auipc	s0,0x9
ffffffffc020054e:	abe40413          	addi	s0,s0,-1346 # ffffffffc0209008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200552:	c43ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200556:	600c                	ld	a1,0(s0)
ffffffffc0200558:	00004517          	auipc	a0,0x4
ffffffffc020055c:	ca850513          	addi	a0,a0,-856 # ffffffffc0204200 <etext+0x2d4>
ffffffffc0200560:	c35ff0ef          	jal	ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200564:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200566:	00004517          	auipc	a0,0x4
ffffffffc020056a:	cb250513          	addi	a0,a0,-846 # ffffffffc0204218 <etext+0x2ec>
    if (boot_dtb == 0) {
ffffffffc020056e:	10070163          	beqz	a4,ffffffffc0200670 <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200572:	57f5                	li	a5,-3
ffffffffc0200574:	07fa                	slli	a5,a5,0x1e
ffffffffc0200576:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200578:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc020057a:	d00e06b7          	lui	a3,0xd00e0
ffffffffc020057e:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfed29f5>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200582:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200586:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020058a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020058e:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200592:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200596:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200598:	8e49                	or	a2,a2,a0
ffffffffc020059a:	0ff7f793          	zext.b	a5,a5
ffffffffc020059e:	8dd1                	or	a1,a1,a2
ffffffffc02005a0:	07a2                	slli	a5,a5,0x8
ffffffffc02005a2:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005a4:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc02005a8:	0cd59863          	bne	a1,a3,ffffffffc0200678 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02005ac:	4710                	lw	a2,8(a4)
ffffffffc02005ae:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005b0:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005b2:	0086541b          	srliw	s0,a2,0x8
ffffffffc02005b6:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ba:	01865e1b          	srliw	t3,a2,0x18
ffffffffc02005be:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005c2:	0186151b          	slliw	a0,a2,0x18
ffffffffc02005c6:	0186959b          	slliw	a1,a3,0x18
ffffffffc02005ca:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ce:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005d2:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005d6:	0106d69b          	srliw	a3,a3,0x10
ffffffffc02005da:	01c56533          	or	a0,a0,t3
ffffffffc02005de:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005e2:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005e6:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ea:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ee:	0ff6f693          	zext.b	a3,a3
ffffffffc02005f2:	8c49                	or	s0,s0,a0
ffffffffc02005f4:	0622                	slli	a2,a2,0x8
ffffffffc02005f6:	8fcd                	or	a5,a5,a1
ffffffffc02005f8:	06a2                	slli	a3,a3,0x8
ffffffffc02005fa:	8c51                	or	s0,s0,a2
ffffffffc02005fc:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005fe:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200600:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200602:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200604:	9381                	srli	a5,a5,0x20
ffffffffc0200606:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200608:	4301                	li	t1,0
        switch (token) {
ffffffffc020060a:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020060c:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020060e:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc0200612:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200614:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200616:	0087579b          	srliw	a5,a4,0x8
ffffffffc020061a:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020061e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200622:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200626:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020062a:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020062e:	8ed1                	or	a3,a3,a2
ffffffffc0200630:	0ff77713          	zext.b	a4,a4
ffffffffc0200634:	8fd5                	or	a5,a5,a3
ffffffffc0200636:	0722                	slli	a4,a4,0x8
ffffffffc0200638:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc020063a:	05178763          	beq	a5,a7,ffffffffc0200688 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020063e:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc0200640:	00f8e963          	bltu	a7,a5,ffffffffc0200652 <dtb_init+0x12a>
ffffffffc0200644:	07c78d63          	beq	a5,t3,ffffffffc02006be <dtb_init+0x196>
ffffffffc0200648:	4709                	li	a4,2
ffffffffc020064a:	00e79763          	bne	a5,a4,ffffffffc0200658 <dtb_init+0x130>
ffffffffc020064e:	4301                	li	t1,0
ffffffffc0200650:	b7d1                	j	ffffffffc0200614 <dtb_init+0xec>
ffffffffc0200652:	4711                	li	a4,4
ffffffffc0200654:	fce780e3          	beq	a5,a4,ffffffffc0200614 <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200658:	00004517          	auipc	a0,0x4
ffffffffc020065c:	c8850513          	addi	a0,a0,-888 # ffffffffc02042e0 <etext+0x3b4>
ffffffffc0200660:	b35ff0ef          	jal	ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200664:	64e2                	ld	s1,24(sp)
ffffffffc0200666:	6942                	ld	s2,16(sp)
ffffffffc0200668:	00004517          	auipc	a0,0x4
ffffffffc020066c:	cb050513          	addi	a0,a0,-848 # ffffffffc0204318 <etext+0x3ec>
}
ffffffffc0200670:	7402                	ld	s0,32(sp)
ffffffffc0200672:	70a2                	ld	ra,40(sp)
ffffffffc0200674:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc0200676:	be39                	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200678:	7402                	ld	s0,32(sp)
ffffffffc020067a:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020067c:	00004517          	auipc	a0,0x4
ffffffffc0200680:	bbc50513          	addi	a0,a0,-1092 # ffffffffc0204238 <etext+0x30c>
}
ffffffffc0200684:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200686:	b639                	j	ffffffffc0200194 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200688:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020068a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020068e:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200692:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200696:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020069a:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020069e:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006a2:	8ed1                	or	a3,a3,a2
ffffffffc02006a4:	0ff77713          	zext.b	a4,a4
ffffffffc02006a8:	8fd5                	or	a5,a5,a3
ffffffffc02006aa:	0722                	slli	a4,a4,0x8
ffffffffc02006ac:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006ae:	04031463          	bnez	t1,ffffffffc02006f6 <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02006b2:	1782                	slli	a5,a5,0x20
ffffffffc02006b4:	9381                	srli	a5,a5,0x20
ffffffffc02006b6:	043d                	addi	s0,s0,15
ffffffffc02006b8:	943e                	add	s0,s0,a5
ffffffffc02006ba:	9871                	andi	s0,s0,-4
                break;
ffffffffc02006bc:	bfa1                	j	ffffffffc0200614 <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc02006be:	8522                	mv	a0,s0
ffffffffc02006c0:	e01a                	sd	t1,0(sp)
ffffffffc02006c2:	768030ef          	jal	ffffffffc0203e2a <strlen>
ffffffffc02006c6:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02006c8:	4619                	li	a2,6
ffffffffc02006ca:	8522                	mv	a0,s0
ffffffffc02006cc:	00004597          	auipc	a1,0x4
ffffffffc02006d0:	b9458593          	addi	a1,a1,-1132 # ffffffffc0204260 <etext+0x334>
ffffffffc02006d4:	7d0030ef          	jal	ffffffffc0203ea4 <strncmp>
ffffffffc02006d8:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02006da:	0411                	addi	s0,s0,4
ffffffffc02006dc:	0004879b          	sext.w	a5,s1
ffffffffc02006e0:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02006e2:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02006e6:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02006e8:	00a36333          	or	t1,t1,a0
                break;
ffffffffc02006ec:	00ff0837          	lui	a6,0xff0
ffffffffc02006f0:	488d                	li	a7,3
ffffffffc02006f2:	4e05                	li	t3,1
ffffffffc02006f4:	b705                	j	ffffffffc0200614 <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006f6:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006f8:	00004597          	auipc	a1,0x4
ffffffffc02006fc:	b7058593          	addi	a1,a1,-1168 # ffffffffc0204268 <etext+0x33c>
ffffffffc0200700:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200702:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200706:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020070a:	0187169b          	slliw	a3,a4,0x18
ffffffffc020070e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200712:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200716:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020071a:	8ed1                	or	a3,a3,a2
ffffffffc020071c:	0ff77713          	zext.b	a4,a4
ffffffffc0200720:	0722                	slli	a4,a4,0x8
ffffffffc0200722:	8d55                	or	a0,a0,a3
ffffffffc0200724:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200726:	1502                	slli	a0,a0,0x20
ffffffffc0200728:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020072a:	954a                	add	a0,a0,s2
ffffffffc020072c:	e01a                	sd	t1,0(sp)
ffffffffc020072e:	742030ef          	jal	ffffffffc0203e70 <strcmp>
ffffffffc0200732:	67a2                	ld	a5,8(sp)
ffffffffc0200734:	473d                	li	a4,15
ffffffffc0200736:	6302                	ld	t1,0(sp)
ffffffffc0200738:	00ff0837          	lui	a6,0xff0
ffffffffc020073c:	488d                	li	a7,3
ffffffffc020073e:	4e05                	li	t3,1
ffffffffc0200740:	f6f779e3          	bgeu	a4,a5,ffffffffc02006b2 <dtb_init+0x18a>
ffffffffc0200744:	f53d                	bnez	a0,ffffffffc02006b2 <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200746:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020074a:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020074e:	00004517          	auipc	a0,0x4
ffffffffc0200752:	b2250513          	addi	a0,a0,-1246 # ffffffffc0204270 <etext+0x344>
           fdt32_to_cpu(x >> 32);
ffffffffc0200756:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020075a:	0087d31b          	srliw	t1,a5,0x8
ffffffffc020075e:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200762:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200766:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020076a:	0187959b          	slliw	a1,a5,0x18
ffffffffc020076e:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200772:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200776:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020077a:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020077e:	01037333          	and	t1,t1,a6
ffffffffc0200782:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200786:	01e5e5b3          	or	a1,a1,t5
ffffffffc020078a:	0ff7f793          	zext.b	a5,a5
ffffffffc020078e:	01de6e33          	or	t3,t3,t4
ffffffffc0200792:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200796:	01067633          	and	a2,a2,a6
ffffffffc020079a:	0086d31b          	srliw	t1,a3,0x8
ffffffffc020079e:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007a2:	07a2                	slli	a5,a5,0x8
ffffffffc02007a4:	0108d89b          	srliw	a7,a7,0x10
ffffffffc02007a8:	0186df1b          	srliw	t5,a3,0x18
ffffffffc02007ac:	01875e9b          	srliw	t4,a4,0x18
ffffffffc02007b0:	8ddd                	or	a1,a1,a5
ffffffffc02007b2:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007b6:	0186979b          	slliw	a5,a3,0x18
ffffffffc02007ba:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007be:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007c2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ca:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007ce:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007d2:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007d6:	08a2                	slli	a7,a7,0x8
ffffffffc02007d8:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007dc:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007e0:	0ff6f693          	zext.b	a3,a3
ffffffffc02007e4:	01de6833          	or	a6,t3,t4
ffffffffc02007e8:	0ff77713          	zext.b	a4,a4
ffffffffc02007ec:	01166633          	or	a2,a2,a7
ffffffffc02007f0:	0067e7b3          	or	a5,a5,t1
ffffffffc02007f4:	06a2                	slli	a3,a3,0x8
ffffffffc02007f6:	01046433          	or	s0,s0,a6
ffffffffc02007fa:	0722                	slli	a4,a4,0x8
ffffffffc02007fc:	8fd5                	or	a5,a5,a3
ffffffffc02007fe:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc0200800:	1582                	slli	a1,a1,0x20
ffffffffc0200802:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200804:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200806:	9201                	srli	a2,a2,0x20
ffffffffc0200808:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020080a:	1402                	slli	s0,s0,0x20
ffffffffc020080c:	00b7e4b3          	or	s1,a5,a1
ffffffffc0200810:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200812:	983ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200816:	85a6                	mv	a1,s1
ffffffffc0200818:	00004517          	auipc	a0,0x4
ffffffffc020081c:	a7850513          	addi	a0,a0,-1416 # ffffffffc0204290 <etext+0x364>
ffffffffc0200820:	975ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200824:	01445613          	srli	a2,s0,0x14
ffffffffc0200828:	85a2                	mv	a1,s0
ffffffffc020082a:	00004517          	auipc	a0,0x4
ffffffffc020082e:	a7e50513          	addi	a0,a0,-1410 # ffffffffc02042a8 <etext+0x37c>
ffffffffc0200832:	963ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200836:	009405b3          	add	a1,s0,s1
ffffffffc020083a:	15fd                	addi	a1,a1,-1
ffffffffc020083c:	00004517          	auipc	a0,0x4
ffffffffc0200840:	a8c50513          	addi	a0,a0,-1396 # ffffffffc02042c8 <etext+0x39c>
ffffffffc0200844:	951ff0ef          	jal	ffffffffc0200194 <cprintf>
        memory_base = mem_base;
ffffffffc0200848:	0000d797          	auipc	a5,0xd
ffffffffc020084c:	c497b023          	sd	s1,-960(a5) # ffffffffc020d488 <memory_base>
        memory_size = mem_size;
ffffffffc0200850:	0000d797          	auipc	a5,0xd
ffffffffc0200854:	c287b823          	sd	s0,-976(a5) # ffffffffc020d480 <memory_size>
ffffffffc0200858:	b531                	j	ffffffffc0200664 <dtb_init+0x13c>

ffffffffc020085a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020085a:	0000d517          	auipc	a0,0xd
ffffffffc020085e:	c2e53503          	ld	a0,-978(a0) # ffffffffc020d488 <memory_base>
ffffffffc0200862:	8082                	ret

ffffffffc0200864 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200864:	0000d517          	auipc	a0,0xd
ffffffffc0200868:	c1c53503          	ld	a0,-996(a0) # ffffffffc020d480 <memory_size>
ffffffffc020086c:	8082                	ret

ffffffffc020086e <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020086e:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200872:	8082                	ret

ffffffffc0200874 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200874:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200878:	8082                	ret

ffffffffc020087a <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc020087a:	8082                	ret

ffffffffc020087c <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020087c:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200880:	00000797          	auipc	a5,0x0
ffffffffc0200884:	3f478793          	addi	a5,a5,1012 # ffffffffc0200c74 <__alltraps>
ffffffffc0200888:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020088c:	000407b7          	lui	a5,0x40
ffffffffc0200890:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200894:	8082                	ret

ffffffffc0200896 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200896:	610c                	ld	a1,0(a0)
{
ffffffffc0200898:	1141                	addi	sp,sp,-16
ffffffffc020089a:	e022                	sd	s0,0(sp)
ffffffffc020089c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020089e:	00004517          	auipc	a0,0x4
ffffffffc02008a2:	a9250513          	addi	a0,a0,-1390 # ffffffffc0204330 <etext+0x404>
{
ffffffffc02008a6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02008a8:	8edff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02008ac:	640c                	ld	a1,8(s0)
ffffffffc02008ae:	00004517          	auipc	a0,0x4
ffffffffc02008b2:	a9a50513          	addi	a0,a0,-1382 # ffffffffc0204348 <etext+0x41c>
ffffffffc02008b6:	8dfff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02008ba:	680c                	ld	a1,16(s0)
ffffffffc02008bc:	00004517          	auipc	a0,0x4
ffffffffc02008c0:	aa450513          	addi	a0,a0,-1372 # ffffffffc0204360 <etext+0x434>
ffffffffc02008c4:	8d1ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02008c8:	6c0c                	ld	a1,24(s0)
ffffffffc02008ca:	00004517          	auipc	a0,0x4
ffffffffc02008ce:	aae50513          	addi	a0,a0,-1362 # ffffffffc0204378 <etext+0x44c>
ffffffffc02008d2:	8c3ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02008d6:	700c                	ld	a1,32(s0)
ffffffffc02008d8:	00004517          	auipc	a0,0x4
ffffffffc02008dc:	ab850513          	addi	a0,a0,-1352 # ffffffffc0204390 <etext+0x464>
ffffffffc02008e0:	8b5ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02008e4:	740c                	ld	a1,40(s0)
ffffffffc02008e6:	00004517          	auipc	a0,0x4
ffffffffc02008ea:	ac250513          	addi	a0,a0,-1342 # ffffffffc02043a8 <etext+0x47c>
ffffffffc02008ee:	8a7ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02008f2:	780c                	ld	a1,48(s0)
ffffffffc02008f4:	00004517          	auipc	a0,0x4
ffffffffc02008f8:	acc50513          	addi	a0,a0,-1332 # ffffffffc02043c0 <etext+0x494>
ffffffffc02008fc:	899ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200900:	7c0c                	ld	a1,56(s0)
ffffffffc0200902:	00004517          	auipc	a0,0x4
ffffffffc0200906:	ad650513          	addi	a0,a0,-1322 # ffffffffc02043d8 <etext+0x4ac>
ffffffffc020090a:	88bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc020090e:	602c                	ld	a1,64(s0)
ffffffffc0200910:	00004517          	auipc	a0,0x4
ffffffffc0200914:	ae050513          	addi	a0,a0,-1312 # ffffffffc02043f0 <etext+0x4c4>
ffffffffc0200918:	87dff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc020091c:	642c                	ld	a1,72(s0)
ffffffffc020091e:	00004517          	auipc	a0,0x4
ffffffffc0200922:	aea50513          	addi	a0,a0,-1302 # ffffffffc0204408 <etext+0x4dc>
ffffffffc0200926:	86fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020092a:	682c                	ld	a1,80(s0)
ffffffffc020092c:	00004517          	auipc	a0,0x4
ffffffffc0200930:	af450513          	addi	a0,a0,-1292 # ffffffffc0204420 <etext+0x4f4>
ffffffffc0200934:	861ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200938:	6c2c                	ld	a1,88(s0)
ffffffffc020093a:	00004517          	auipc	a0,0x4
ffffffffc020093e:	afe50513          	addi	a0,a0,-1282 # ffffffffc0204438 <etext+0x50c>
ffffffffc0200942:	853ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200946:	702c                	ld	a1,96(s0)
ffffffffc0200948:	00004517          	auipc	a0,0x4
ffffffffc020094c:	b0850513          	addi	a0,a0,-1272 # ffffffffc0204450 <etext+0x524>
ffffffffc0200950:	845ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200954:	742c                	ld	a1,104(s0)
ffffffffc0200956:	00004517          	auipc	a0,0x4
ffffffffc020095a:	b1250513          	addi	a0,a0,-1262 # ffffffffc0204468 <etext+0x53c>
ffffffffc020095e:	837ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200962:	782c                	ld	a1,112(s0)
ffffffffc0200964:	00004517          	auipc	a0,0x4
ffffffffc0200968:	b1c50513          	addi	a0,a0,-1252 # ffffffffc0204480 <etext+0x554>
ffffffffc020096c:	829ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200970:	7c2c                	ld	a1,120(s0)
ffffffffc0200972:	00004517          	auipc	a0,0x4
ffffffffc0200976:	b2650513          	addi	a0,a0,-1242 # ffffffffc0204498 <etext+0x56c>
ffffffffc020097a:	81bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020097e:	604c                	ld	a1,128(s0)
ffffffffc0200980:	00004517          	auipc	a0,0x4
ffffffffc0200984:	b3050513          	addi	a0,a0,-1232 # ffffffffc02044b0 <etext+0x584>
ffffffffc0200988:	80dff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020098c:	644c                	ld	a1,136(s0)
ffffffffc020098e:	00004517          	auipc	a0,0x4
ffffffffc0200992:	b3a50513          	addi	a0,a0,-1222 # ffffffffc02044c8 <etext+0x59c>
ffffffffc0200996:	ffeff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020099a:	684c                	ld	a1,144(s0)
ffffffffc020099c:	00004517          	auipc	a0,0x4
ffffffffc02009a0:	b4450513          	addi	a0,a0,-1212 # ffffffffc02044e0 <etext+0x5b4>
ffffffffc02009a4:	ff0ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc02009a8:	6c4c                	ld	a1,152(s0)
ffffffffc02009aa:	00004517          	auipc	a0,0x4
ffffffffc02009ae:	b4e50513          	addi	a0,a0,-1202 # ffffffffc02044f8 <etext+0x5cc>
ffffffffc02009b2:	fe2ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc02009b6:	704c                	ld	a1,160(s0)
ffffffffc02009b8:	00004517          	auipc	a0,0x4
ffffffffc02009bc:	b5850513          	addi	a0,a0,-1192 # ffffffffc0204510 <etext+0x5e4>
ffffffffc02009c0:	fd4ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02009c4:	744c                	ld	a1,168(s0)
ffffffffc02009c6:	00004517          	auipc	a0,0x4
ffffffffc02009ca:	b6250513          	addi	a0,a0,-1182 # ffffffffc0204528 <etext+0x5fc>
ffffffffc02009ce:	fc6ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02009d2:	784c                	ld	a1,176(s0)
ffffffffc02009d4:	00004517          	auipc	a0,0x4
ffffffffc02009d8:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0204540 <etext+0x614>
ffffffffc02009dc:	fb8ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02009e0:	7c4c                	ld	a1,184(s0)
ffffffffc02009e2:	00004517          	auipc	a0,0x4
ffffffffc02009e6:	b7650513          	addi	a0,a0,-1162 # ffffffffc0204558 <etext+0x62c>
ffffffffc02009ea:	faaff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02009ee:	606c                	ld	a1,192(s0)
ffffffffc02009f0:	00004517          	auipc	a0,0x4
ffffffffc02009f4:	b8050513          	addi	a0,a0,-1152 # ffffffffc0204570 <etext+0x644>
ffffffffc02009f8:	f9cff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009fc:	646c                	ld	a1,200(s0)
ffffffffc02009fe:	00004517          	auipc	a0,0x4
ffffffffc0200a02:	b8a50513          	addi	a0,a0,-1142 # ffffffffc0204588 <etext+0x65c>
ffffffffc0200a06:	f8eff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200a0a:	686c                	ld	a1,208(s0)
ffffffffc0200a0c:	00004517          	auipc	a0,0x4
ffffffffc0200a10:	b9450513          	addi	a0,a0,-1132 # ffffffffc02045a0 <etext+0x674>
ffffffffc0200a14:	f80ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200a18:	6c6c                	ld	a1,216(s0)
ffffffffc0200a1a:	00004517          	auipc	a0,0x4
ffffffffc0200a1e:	b9e50513          	addi	a0,a0,-1122 # ffffffffc02045b8 <etext+0x68c>
ffffffffc0200a22:	f72ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200a26:	706c                	ld	a1,224(s0)
ffffffffc0200a28:	00004517          	auipc	a0,0x4
ffffffffc0200a2c:	ba850513          	addi	a0,a0,-1112 # ffffffffc02045d0 <etext+0x6a4>
ffffffffc0200a30:	f64ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200a34:	746c                	ld	a1,232(s0)
ffffffffc0200a36:	00004517          	auipc	a0,0x4
ffffffffc0200a3a:	bb250513          	addi	a0,a0,-1102 # ffffffffc02045e8 <etext+0x6bc>
ffffffffc0200a3e:	f56ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200a42:	786c                	ld	a1,240(s0)
ffffffffc0200a44:	00004517          	auipc	a0,0x4
ffffffffc0200a48:	bbc50513          	addi	a0,a0,-1092 # ffffffffc0204600 <etext+0x6d4>
ffffffffc0200a4c:	f48ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a50:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200a52:	6402                	ld	s0,0(sp)
ffffffffc0200a54:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a56:	00004517          	auipc	a0,0x4
ffffffffc0200a5a:	bc250513          	addi	a0,a0,-1086 # ffffffffc0204618 <etext+0x6ec>
}
ffffffffc0200a5e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a60:	f34ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200a64 <print_trapframe>:
{
ffffffffc0200a64:	1141                	addi	sp,sp,-16
ffffffffc0200a66:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a68:	85aa                	mv	a1,a0
{
ffffffffc0200a6a:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a6c:	00004517          	auipc	a0,0x4
ffffffffc0200a70:	bc450513          	addi	a0,a0,-1084 # ffffffffc0204630 <etext+0x704>
{
ffffffffc0200a74:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a76:	f1eff0ef          	jal	ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a7a:	8522                	mv	a0,s0
ffffffffc0200a7c:	e1bff0ef          	jal	ffffffffc0200896 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a80:	10043583          	ld	a1,256(s0)
ffffffffc0200a84:	00004517          	auipc	a0,0x4
ffffffffc0200a88:	bc450513          	addi	a0,a0,-1084 # ffffffffc0204648 <etext+0x71c>
ffffffffc0200a8c:	f08ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a90:	10843583          	ld	a1,264(s0)
ffffffffc0200a94:	00004517          	auipc	a0,0x4
ffffffffc0200a98:	bcc50513          	addi	a0,a0,-1076 # ffffffffc0204660 <etext+0x734>
ffffffffc0200a9c:	ef8ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200aa0:	11043583          	ld	a1,272(s0)
ffffffffc0200aa4:	00004517          	auipc	a0,0x4
ffffffffc0200aa8:	bd450513          	addi	a0,a0,-1068 # ffffffffc0204678 <etext+0x74c>
ffffffffc0200aac:	ee8ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200ab0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200ab4:	6402                	ld	s0,0(sp)
ffffffffc0200ab6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200ab8:	00004517          	auipc	a0,0x4
ffffffffc0200abc:	bd850513          	addi	a0,a0,-1064 # ffffffffc0204690 <etext+0x764>
}
ffffffffc0200ac0:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200ac2:	ed2ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200ac6 <interrupt_handler>:
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause)
ffffffffc0200ac6:	11853783          	ld	a5,280(a0)
ffffffffc0200aca:	472d                	li	a4,11
ffffffffc0200acc:	0786                	slli	a5,a5,0x1
ffffffffc0200ace:	8385                	srli	a5,a5,0x1
ffffffffc0200ad0:	08f76f63          	bltu	a4,a5,ffffffffc0200b6e <interrupt_handler+0xa8>
ffffffffc0200ad4:	00005717          	auipc	a4,0x5
ffffffffc0200ad8:	da470713          	addi	a4,a4,-604 # ffffffffc0205878 <commands+0x48>
ffffffffc0200adc:	078a                	slli	a5,a5,0x2
ffffffffc0200ade:	97ba                	add	a5,a5,a4
ffffffffc0200ae0:	439c                	lw	a5,0(a5)
ffffffffc0200ae2:	97ba                	add	a5,a5,a4
ffffffffc0200ae4:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200ae6:	00004517          	auipc	a0,0x4
ffffffffc0200aea:	c2250513          	addi	a0,a0,-990 # ffffffffc0204708 <etext+0x7dc>
ffffffffc0200aee:	ea6ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200af2:	00004517          	auipc	a0,0x4
ffffffffc0200af6:	bf650513          	addi	a0,a0,-1034 # ffffffffc02046e8 <etext+0x7bc>
ffffffffc0200afa:	e9aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200afe:	00004517          	auipc	a0,0x4
ffffffffc0200b02:	baa50513          	addi	a0,a0,-1110 # ffffffffc02046a8 <etext+0x77c>
ffffffffc0200b06:	e8eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200b0a:	00004517          	auipc	a0,0x4
ffffffffc0200b0e:	bbe50513          	addi	a0,a0,-1090 # ffffffffc02046c8 <etext+0x79c>
ffffffffc0200b12:	e82ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200b16:	1141                	addi	sp,sp,-16
ffffffffc0200b18:	e406                	sd	ra,8(sp)
        // In fact, Call sbi_set_timer will clear STIP, or you can clear it
        // directly.
        // clear_csr(sip, SIP_STIP);

        /*LAB3 请补充你在lab3中的代码 */ 
        clock_set_next_event();
ffffffffc0200b1a:	983ff0ef          	jal	ffffffffc020049c <clock_set_next_event>
        
        static int ticks = 0;
        ticks++;
ffffffffc0200b1e:	0000d697          	auipc	a3,0xd
ffffffffc0200b22:	9766a683          	lw	a3,-1674(a3) # ffffffffc020d494 <ticks.1>
ffffffffc0200b26:	c28f6737          	lui	a4,0xc28f6
ffffffffc0200b2a:	c297071b          	addiw	a4,a4,-983 # ffffffffc28f5c29 <end+0x26e8731>
ffffffffc0200b2e:	2685                	addiw	a3,a3,1
ffffffffc0200b30:	02d7073b          	mulw	a4,a4,a3
ffffffffc0200b34:	051ec7b7          	lui	a5,0x51ec
ffffffffc0200b38:	8507879b          	addiw	a5,a5,-1968 # 51eb850 <kern_entry-0xffffffffbb0147b0>
ffffffffc0200b3c:	0000d597          	auipc	a1,0xd
ffffffffc0200b40:	94d5ac23          	sw	a3,-1704(a1) # ffffffffc020d494 <ticks.1>
        
        if (ticks % TICK_NUM == 0) {
ffffffffc0200b44:	028f66b7          	lui	a3,0x28f6
ffffffffc0200b48:	c2868693          	addi	a3,a3,-984 # 28f5c28 <kern_entry-0xffffffffbd90a3d8>
        ticks++;
ffffffffc0200b4c:	9fb9                	addw	a5,a5,a4
ffffffffc0200b4e:	0027d71b          	srliw	a4,a5,0x2
ffffffffc0200b52:	01e7979b          	slliw	a5,a5,0x1e
ffffffffc0200b56:	9fb9                	addw	a5,a5,a4
        if (ticks % TICK_NUM == 0) {
ffffffffc0200b58:	00f6fc63          	bgeu	a3,a5,ffffffffc0200b70 <interrupt_handler+0xaa>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200b5c:	60a2                	ld	ra,8(sp)
ffffffffc0200b5e:	0141                	addi	sp,sp,16
ffffffffc0200b60:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200b62:	00004517          	auipc	a0,0x4
ffffffffc0200b66:	bd650513          	addi	a0,a0,-1066 # ffffffffc0204738 <etext+0x80c>
ffffffffc0200b6a:	e2aff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200b6e:	bddd                	j	ffffffffc0200a64 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b70:	06400593          	li	a1,100
ffffffffc0200b74:	00004517          	auipc	a0,0x4
ffffffffc0200b78:	bb450513          	addi	a0,a0,-1100 # ffffffffc0204728 <etext+0x7fc>
ffffffffc0200b7c:	e18ff0ef          	jal	ffffffffc0200194 <cprintf>
            num++;
ffffffffc0200b80:	0000d797          	auipc	a5,0xd
ffffffffc0200b84:	9107a783          	lw	a5,-1776(a5) # ffffffffc020d490 <num.0>
ffffffffc0200b88:	2785                	addiw	a5,a5,1
ffffffffc0200b8a:	0000d717          	auipc	a4,0xd
ffffffffc0200b8e:	90f72323          	sw	a5,-1786(a4) # ffffffffc020d490 <num.0>
ffffffffc0200b92:	b7e9                	j	ffffffffc0200b5c <interrupt_handler+0x96>

ffffffffc0200b94 <exception_handler>:

void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200b94:	11853783          	ld	a5,280(a0)
ffffffffc0200b98:	473d                	li	a4,15
ffffffffc0200b9a:	0cf76563          	bltu	a4,a5,ffffffffc0200c64 <exception_handler+0xd0>
ffffffffc0200b9e:	00005717          	auipc	a4,0x5
ffffffffc0200ba2:	d0a70713          	addi	a4,a4,-758 # ffffffffc02058a8 <commands+0x78>
ffffffffc0200ba6:	078a                	slli	a5,a5,0x2
ffffffffc0200ba8:	97ba                	add	a5,a5,a4
ffffffffc0200baa:	439c                	lw	a5,0(a5)
ffffffffc0200bac:	97ba                	add	a5,a5,a4
ffffffffc0200bae:	8782                	jr	a5
        break;
    case CAUSE_LOAD_PAGE_FAULT:
        cprintf("Load page fault\n");
        break;
    case CAUSE_STORE_PAGE_FAULT:
        cprintf("Store/AMO page fault\n");
ffffffffc0200bb0:	00004517          	auipc	a0,0x4
ffffffffc0200bb4:	d2850513          	addi	a0,a0,-728 # ffffffffc02048d8 <etext+0x9ac>
ffffffffc0200bb8:	ddcff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction address misaligned\n");
ffffffffc0200bbc:	00004517          	auipc	a0,0x4
ffffffffc0200bc0:	b9c50513          	addi	a0,a0,-1124 # ffffffffc0204758 <etext+0x82c>
ffffffffc0200bc4:	dd0ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction access fault\n");
ffffffffc0200bc8:	00004517          	auipc	a0,0x4
ffffffffc0200bcc:	bb050513          	addi	a0,a0,-1104 # ffffffffc0204778 <etext+0x84c>
ffffffffc0200bd0:	dc4ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Illegal instruction\n");
ffffffffc0200bd4:	00004517          	auipc	a0,0x4
ffffffffc0200bd8:	bc450513          	addi	a0,a0,-1084 # ffffffffc0204798 <etext+0x86c>
ffffffffc0200bdc:	db8ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Breakpoint\n");
ffffffffc0200be0:	00004517          	auipc	a0,0x4
ffffffffc0200be4:	bd050513          	addi	a0,a0,-1072 # ffffffffc02047b0 <etext+0x884>
ffffffffc0200be8:	dacff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load address misaligned\n");
ffffffffc0200bec:	00004517          	auipc	a0,0x4
ffffffffc0200bf0:	bd450513          	addi	a0,a0,-1068 # ffffffffc02047c0 <etext+0x894>
ffffffffc0200bf4:	da0ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load access fault\n");
ffffffffc0200bf8:	00004517          	auipc	a0,0x4
ffffffffc0200bfc:	be850513          	addi	a0,a0,-1048 # ffffffffc02047e0 <etext+0x8b4>
ffffffffc0200c00:	d94ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("AMO address misaligned\n");
ffffffffc0200c04:	00004517          	auipc	a0,0x4
ffffffffc0200c08:	bf450513          	addi	a0,a0,-1036 # ffffffffc02047f8 <etext+0x8cc>
ffffffffc0200c0c:	d88ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Store/AMO access fault\n");
ffffffffc0200c10:	00004517          	auipc	a0,0x4
ffffffffc0200c14:	c0050513          	addi	a0,a0,-1024 # ffffffffc0204810 <etext+0x8e4>
ffffffffc0200c18:	d7cff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from U-mode\n");
ffffffffc0200c1c:	00004517          	auipc	a0,0x4
ffffffffc0200c20:	c0c50513          	addi	a0,a0,-1012 # ffffffffc0204828 <etext+0x8fc>
ffffffffc0200c24:	d70ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from S-mode\n");
ffffffffc0200c28:	00004517          	auipc	a0,0x4
ffffffffc0200c2c:	c2050513          	addi	a0,a0,-992 # ffffffffc0204848 <etext+0x91c>
ffffffffc0200c30:	d64ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from H-mode\n");
ffffffffc0200c34:	00004517          	auipc	a0,0x4
ffffffffc0200c38:	c3450513          	addi	a0,a0,-972 # ffffffffc0204868 <etext+0x93c>
ffffffffc0200c3c:	d58ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200c40:	00004517          	auipc	a0,0x4
ffffffffc0200c44:	c4850513          	addi	a0,a0,-952 # ffffffffc0204888 <etext+0x95c>
ffffffffc0200c48:	d4cff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction page fault\n");
ffffffffc0200c4c:	00004517          	auipc	a0,0x4
ffffffffc0200c50:	c5c50513          	addi	a0,a0,-932 # ffffffffc02048a8 <etext+0x97c>
ffffffffc0200c54:	d40ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load page fault\n");
ffffffffc0200c58:	00004517          	auipc	a0,0x4
ffffffffc0200c5c:	c6850513          	addi	a0,a0,-920 # ffffffffc02048c0 <etext+0x994>
ffffffffc0200c60:	d34ff06f          	j	ffffffffc0200194 <cprintf>
        break;
    default:
        print_trapframe(tf);
ffffffffc0200c64:	b501                	j	ffffffffc0200a64 <print_trapframe>

ffffffffc0200c66 <trap>:
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0)
ffffffffc0200c66:	11853783          	ld	a5,280(a0)
ffffffffc0200c6a:	0007c363          	bltz	a5,ffffffffc0200c70 <trap+0xa>
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
ffffffffc0200c6e:	b71d                	j	ffffffffc0200b94 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200c70:	bd99                	j	ffffffffc0200ac6 <interrupt_handler>
	...

ffffffffc0200c74 <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200c74:	14011073          	csrw	sscratch,sp
ffffffffc0200c78:	712d                	addi	sp,sp,-288
ffffffffc0200c7a:	e406                	sd	ra,8(sp)
ffffffffc0200c7c:	ec0e                	sd	gp,24(sp)
ffffffffc0200c7e:	f012                	sd	tp,32(sp)
ffffffffc0200c80:	f416                	sd	t0,40(sp)
ffffffffc0200c82:	f81a                	sd	t1,48(sp)
ffffffffc0200c84:	fc1e                	sd	t2,56(sp)
ffffffffc0200c86:	e0a2                	sd	s0,64(sp)
ffffffffc0200c88:	e4a6                	sd	s1,72(sp)
ffffffffc0200c8a:	e8aa                	sd	a0,80(sp)
ffffffffc0200c8c:	ecae                	sd	a1,88(sp)
ffffffffc0200c8e:	f0b2                	sd	a2,96(sp)
ffffffffc0200c90:	f4b6                	sd	a3,104(sp)
ffffffffc0200c92:	f8ba                	sd	a4,112(sp)
ffffffffc0200c94:	fcbe                	sd	a5,120(sp)
ffffffffc0200c96:	e142                	sd	a6,128(sp)
ffffffffc0200c98:	e546                	sd	a7,136(sp)
ffffffffc0200c9a:	e94a                	sd	s2,144(sp)
ffffffffc0200c9c:	ed4e                	sd	s3,152(sp)
ffffffffc0200c9e:	f152                	sd	s4,160(sp)
ffffffffc0200ca0:	f556                	sd	s5,168(sp)
ffffffffc0200ca2:	f95a                	sd	s6,176(sp)
ffffffffc0200ca4:	fd5e                	sd	s7,184(sp)
ffffffffc0200ca6:	e1e2                	sd	s8,192(sp)
ffffffffc0200ca8:	e5e6                	sd	s9,200(sp)
ffffffffc0200caa:	e9ea                	sd	s10,208(sp)
ffffffffc0200cac:	edee                	sd	s11,216(sp)
ffffffffc0200cae:	f1f2                	sd	t3,224(sp)
ffffffffc0200cb0:	f5f6                	sd	t4,232(sp)
ffffffffc0200cb2:	f9fa                	sd	t5,240(sp)
ffffffffc0200cb4:	fdfe                	sd	t6,248(sp)
ffffffffc0200cb6:	14002473          	csrr	s0,sscratch
ffffffffc0200cba:	100024f3          	csrr	s1,sstatus
ffffffffc0200cbe:	14102973          	csrr	s2,sepc
ffffffffc0200cc2:	143029f3          	csrr	s3,stval
ffffffffc0200cc6:	14202a73          	csrr	s4,scause
ffffffffc0200cca:	e822                	sd	s0,16(sp)
ffffffffc0200ccc:	e226                	sd	s1,256(sp)
ffffffffc0200cce:	e64a                	sd	s2,264(sp)
ffffffffc0200cd0:	ea4e                	sd	s3,272(sp)
ffffffffc0200cd2:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200cd4:	850a                	mv	a0,sp
    jal trap
ffffffffc0200cd6:	f91ff0ef          	jal	ffffffffc0200c66 <trap>

ffffffffc0200cda <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200cda:	6492                	ld	s1,256(sp)
ffffffffc0200cdc:	6932                	ld	s2,264(sp)
ffffffffc0200cde:	10049073          	csrw	sstatus,s1
ffffffffc0200ce2:	14191073          	csrw	sepc,s2
ffffffffc0200ce6:	60a2                	ld	ra,8(sp)
ffffffffc0200ce8:	61e2                	ld	gp,24(sp)
ffffffffc0200cea:	7202                	ld	tp,32(sp)
ffffffffc0200cec:	72a2                	ld	t0,40(sp)
ffffffffc0200cee:	7342                	ld	t1,48(sp)
ffffffffc0200cf0:	73e2                	ld	t2,56(sp)
ffffffffc0200cf2:	6406                	ld	s0,64(sp)
ffffffffc0200cf4:	64a6                	ld	s1,72(sp)
ffffffffc0200cf6:	6546                	ld	a0,80(sp)
ffffffffc0200cf8:	65e6                	ld	a1,88(sp)
ffffffffc0200cfa:	7606                	ld	a2,96(sp)
ffffffffc0200cfc:	76a6                	ld	a3,104(sp)
ffffffffc0200cfe:	7746                	ld	a4,112(sp)
ffffffffc0200d00:	77e6                	ld	a5,120(sp)
ffffffffc0200d02:	680a                	ld	a6,128(sp)
ffffffffc0200d04:	68aa                	ld	a7,136(sp)
ffffffffc0200d06:	694a                	ld	s2,144(sp)
ffffffffc0200d08:	69ea                	ld	s3,152(sp)
ffffffffc0200d0a:	7a0a                	ld	s4,160(sp)
ffffffffc0200d0c:	7aaa                	ld	s5,168(sp)
ffffffffc0200d0e:	7b4a                	ld	s6,176(sp)
ffffffffc0200d10:	7bea                	ld	s7,184(sp)
ffffffffc0200d12:	6c0e                	ld	s8,192(sp)
ffffffffc0200d14:	6cae                	ld	s9,200(sp)
ffffffffc0200d16:	6d4e                	ld	s10,208(sp)
ffffffffc0200d18:	6dee                	ld	s11,216(sp)
ffffffffc0200d1a:	7e0e                	ld	t3,224(sp)
ffffffffc0200d1c:	7eae                	ld	t4,232(sp)
ffffffffc0200d1e:	7f4e                	ld	t5,240(sp)
ffffffffc0200d20:	7fee                	ld	t6,248(sp)
ffffffffc0200d22:	6142                	ld	sp,16(sp)
    # go back from supervisor call
    sret
ffffffffc0200d24:	10200073          	sret

ffffffffc0200d28 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200d28:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200d2a:	bf45                	j	ffffffffc0200cda <__trapret>
ffffffffc0200d2c:	0001                	nop

ffffffffc0200d2e <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200d2e:	00008797          	auipc	a5,0x8
ffffffffc0200d32:	70278793          	addi	a5,a5,1794 # ffffffffc0209430 <free_area>
ffffffffc0200d36:	e79c                	sd	a5,8(a5)
ffffffffc0200d38:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200d3a:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200d3e:	8082                	ret

ffffffffc0200d40 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200d40:	00008517          	auipc	a0,0x8
ffffffffc0200d44:	70056503          	lwu	a0,1792(a0) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200d48:	8082                	ret

ffffffffc0200d4a <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200d4a:	711d                	addi	sp,sp,-96
ffffffffc0200d4c:	e0ca                	sd	s2,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200d4e:	00008917          	auipc	s2,0x8
ffffffffc0200d52:	6e290913          	addi	s2,s2,1762 # ffffffffc0209430 <free_area>
ffffffffc0200d56:	00893783          	ld	a5,8(s2)
ffffffffc0200d5a:	ec86                	sd	ra,88(sp)
ffffffffc0200d5c:	e8a2                	sd	s0,80(sp)
ffffffffc0200d5e:	e4a6                	sd	s1,72(sp)
ffffffffc0200d60:	fc4e                	sd	s3,56(sp)
ffffffffc0200d62:	f852                	sd	s4,48(sp)
ffffffffc0200d64:	f456                	sd	s5,40(sp)
ffffffffc0200d66:	f05a                	sd	s6,32(sp)
ffffffffc0200d68:	ec5e                	sd	s7,24(sp)
ffffffffc0200d6a:	e862                	sd	s8,16(sp)
ffffffffc0200d6c:	e466                	sd	s9,8(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d6e:	2f278763          	beq	a5,s2,ffffffffc020105c <default_check+0x312>
    int count = 0, total = 0;
ffffffffc0200d72:	4401                	li	s0,0
ffffffffc0200d74:	4481                	li	s1,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200d76:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200d7a:	8b09                	andi	a4,a4,2
ffffffffc0200d7c:	2e070463          	beqz	a4,ffffffffc0201064 <default_check+0x31a>
        count ++, total += p->property;
ffffffffc0200d80:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200d84:	679c                	ld	a5,8(a5)
ffffffffc0200d86:	2485                	addiw	s1,s1,1
ffffffffc0200d88:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d8a:	ff2796e3          	bne	a5,s2,ffffffffc0200d76 <default_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc0200d8e:	89a2                	mv	s3,s0
ffffffffc0200d90:	745000ef          	jal	ffffffffc0201cd4 <nr_free_pages>
ffffffffc0200d94:	73351863          	bne	a0,s3,ffffffffc02014c4 <default_check+0x77a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d98:	4505                	li	a0,1
ffffffffc0200d9a:	6c9000ef          	jal	ffffffffc0201c62 <alloc_pages>
ffffffffc0200d9e:	8a2a                	mv	s4,a0
ffffffffc0200da0:	46050263          	beqz	a0,ffffffffc0201204 <default_check+0x4ba>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200da4:	4505                	li	a0,1
ffffffffc0200da6:	6bd000ef          	jal	ffffffffc0201c62 <alloc_pages>
ffffffffc0200daa:	89aa                	mv	s3,a0
ffffffffc0200dac:	72050c63          	beqz	a0,ffffffffc02014e4 <default_check+0x79a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200db0:	4505                	li	a0,1
ffffffffc0200db2:	6b1000ef          	jal	ffffffffc0201c62 <alloc_pages>
ffffffffc0200db6:	8aaa                	mv	s5,a0
ffffffffc0200db8:	4c050663          	beqz	a0,ffffffffc0201284 <default_check+0x53a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200dbc:	40aa07b3          	sub	a5,s4,a0
ffffffffc0200dc0:	40a98733          	sub	a4,s3,a0
ffffffffc0200dc4:	0017b793          	seqz	a5,a5
ffffffffc0200dc8:	00173713          	seqz	a4,a4
ffffffffc0200dcc:	8fd9                	or	a5,a5,a4
ffffffffc0200dce:	30079b63          	bnez	a5,ffffffffc02010e4 <default_check+0x39a>
ffffffffc0200dd2:	313a0963          	beq	s4,s3,ffffffffc02010e4 <default_check+0x39a>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200dd6:	000a2783          	lw	a5,0(s4)
ffffffffc0200dda:	2a079563          	bnez	a5,ffffffffc0201084 <default_check+0x33a>
ffffffffc0200dde:	0009a783          	lw	a5,0(s3)
ffffffffc0200de2:	2a079163          	bnez	a5,ffffffffc0201084 <default_check+0x33a>
ffffffffc0200de6:	411c                	lw	a5,0(a0)
ffffffffc0200de8:	28079e63          	bnez	a5,ffffffffc0201084 <default_check+0x33a>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200dec:	0000c797          	auipc	a5,0xc
ffffffffc0200df0:	6dc7b783          	ld	a5,1756(a5) # ffffffffc020d4c8 <pages>
ffffffffc0200df4:	00005617          	auipc	a2,0x5
ffffffffc0200df8:	cbc63603          	ld	a2,-836(a2) # ffffffffc0205ab0 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200dfc:	0000c697          	auipc	a3,0xc
ffffffffc0200e00:	6c46b683          	ld	a3,1732(a3) # ffffffffc020d4c0 <npage>
ffffffffc0200e04:	40fa0733          	sub	a4,s4,a5
ffffffffc0200e08:	8719                	srai	a4,a4,0x6
ffffffffc0200e0a:	9732                	add	a4,a4,a2
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e0c:	0732                	slli	a4,a4,0xc
ffffffffc0200e0e:	06b2                	slli	a3,a3,0xc
ffffffffc0200e10:	2ad77a63          	bgeu	a4,a3,ffffffffc02010c4 <default_check+0x37a>
    return page - pages + nbase;
ffffffffc0200e14:	40f98733          	sub	a4,s3,a5
ffffffffc0200e18:	8719                	srai	a4,a4,0x6
ffffffffc0200e1a:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e1c:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200e1e:	4ed77363          	bgeu	a4,a3,ffffffffc0201304 <default_check+0x5ba>
    return page - pages + nbase;
ffffffffc0200e22:	40f507b3          	sub	a5,a0,a5
ffffffffc0200e26:	8799                	srai	a5,a5,0x6
ffffffffc0200e28:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e2a:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200e2c:	32d7fc63          	bgeu	a5,a3,ffffffffc0201164 <default_check+0x41a>
    assert(alloc_page() == NULL);
ffffffffc0200e30:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200e32:	00093c03          	ld	s8,0(s2)
ffffffffc0200e36:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200e3a:	00008b17          	auipc	s6,0x8
ffffffffc0200e3e:	606b2b03          	lw	s6,1542(s6) # ffffffffc0209440 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc0200e42:	01293023          	sd	s2,0(s2)
ffffffffc0200e46:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc0200e4a:	00008797          	auipc	a5,0x8
ffffffffc0200e4e:	5e07ab23          	sw	zero,1526(a5) # ffffffffc0209440 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200e52:	611000ef          	jal	ffffffffc0201c62 <alloc_pages>
ffffffffc0200e56:	2e051763          	bnez	a0,ffffffffc0201144 <default_check+0x3fa>
    free_page(p0);
ffffffffc0200e5a:	8552                	mv	a0,s4
ffffffffc0200e5c:	4585                	li	a1,1
ffffffffc0200e5e:	63f000ef          	jal	ffffffffc0201c9c <free_pages>
    free_page(p1);
ffffffffc0200e62:	854e                	mv	a0,s3
ffffffffc0200e64:	4585                	li	a1,1
ffffffffc0200e66:	637000ef          	jal	ffffffffc0201c9c <free_pages>
    free_page(p2);
ffffffffc0200e6a:	8556                	mv	a0,s5
ffffffffc0200e6c:	4585                	li	a1,1
ffffffffc0200e6e:	62f000ef          	jal	ffffffffc0201c9c <free_pages>
    assert(nr_free == 3);
ffffffffc0200e72:	00008717          	auipc	a4,0x8
ffffffffc0200e76:	5ce72703          	lw	a4,1486(a4) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200e7a:	478d                	li	a5,3
ffffffffc0200e7c:	2af71463          	bne	a4,a5,ffffffffc0201124 <default_check+0x3da>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e80:	4505                	li	a0,1
ffffffffc0200e82:	5e1000ef          	jal	ffffffffc0201c62 <alloc_pages>
ffffffffc0200e86:	89aa                	mv	s3,a0
ffffffffc0200e88:	26050e63          	beqz	a0,ffffffffc0201104 <default_check+0x3ba>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e8c:	4505                	li	a0,1
ffffffffc0200e8e:	5d5000ef          	jal	ffffffffc0201c62 <alloc_pages>
ffffffffc0200e92:	8aaa                	mv	s5,a0
ffffffffc0200e94:	3c050863          	beqz	a0,ffffffffc0201264 <default_check+0x51a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200e98:	4505                	li	a0,1
ffffffffc0200e9a:	5c9000ef          	jal	ffffffffc0201c62 <alloc_pages>
ffffffffc0200e9e:	8a2a                	mv	s4,a0
ffffffffc0200ea0:	3a050263          	beqz	a0,ffffffffc0201244 <default_check+0x4fa>
    assert(alloc_page() == NULL);
ffffffffc0200ea4:	4505                	li	a0,1
ffffffffc0200ea6:	5bd000ef          	jal	ffffffffc0201c62 <alloc_pages>
ffffffffc0200eaa:	36051d63          	bnez	a0,ffffffffc0201224 <default_check+0x4da>
    free_page(p0);
ffffffffc0200eae:	4585                	li	a1,1
ffffffffc0200eb0:	854e                	mv	a0,s3
ffffffffc0200eb2:	5eb000ef          	jal	ffffffffc0201c9c <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200eb6:	00893783          	ld	a5,8(s2)
ffffffffc0200eba:	1f278563          	beq	a5,s2,ffffffffc02010a4 <default_check+0x35a>
    assert((p = alloc_page()) == p0);
ffffffffc0200ebe:	4505                	li	a0,1
ffffffffc0200ec0:	5a3000ef          	jal	ffffffffc0201c62 <alloc_pages>
ffffffffc0200ec4:	8caa                	mv	s9,a0
ffffffffc0200ec6:	30a99f63          	bne	s3,a0,ffffffffc02011e4 <default_check+0x49a>
    assert(alloc_page() == NULL);
ffffffffc0200eca:	4505                	li	a0,1
ffffffffc0200ecc:	597000ef          	jal	ffffffffc0201c62 <alloc_pages>
ffffffffc0200ed0:	2e051a63          	bnez	a0,ffffffffc02011c4 <default_check+0x47a>
    assert(nr_free == 0);
ffffffffc0200ed4:	00008797          	auipc	a5,0x8
ffffffffc0200ed8:	56c7a783          	lw	a5,1388(a5) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200edc:	2c079463          	bnez	a5,ffffffffc02011a4 <default_check+0x45a>
    free_page(p);
ffffffffc0200ee0:	8566                	mv	a0,s9
ffffffffc0200ee2:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200ee4:	01893023          	sd	s8,0(s2)
ffffffffc0200ee8:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc0200eec:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc0200ef0:	5ad000ef          	jal	ffffffffc0201c9c <free_pages>
    free_page(p1);
ffffffffc0200ef4:	8556                	mv	a0,s5
ffffffffc0200ef6:	4585                	li	a1,1
ffffffffc0200ef8:	5a5000ef          	jal	ffffffffc0201c9c <free_pages>
    free_page(p2);
ffffffffc0200efc:	8552                	mv	a0,s4
ffffffffc0200efe:	4585                	li	a1,1
ffffffffc0200f00:	59d000ef          	jal	ffffffffc0201c9c <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200f04:	4515                	li	a0,5
ffffffffc0200f06:	55d000ef          	jal	ffffffffc0201c62 <alloc_pages>
ffffffffc0200f0a:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200f0c:	26050c63          	beqz	a0,ffffffffc0201184 <default_check+0x43a>
ffffffffc0200f10:	651c                	ld	a5,8(a0)
ffffffffc0200f12:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200f14:	8b85                	andi	a5,a5,1
ffffffffc0200f16:	54079763          	bnez	a5,ffffffffc0201464 <default_check+0x71a>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200f1a:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f1c:	00093b83          	ld	s7,0(s2)
ffffffffc0200f20:	00893b03          	ld	s6,8(s2)
ffffffffc0200f24:	01293023          	sd	s2,0(s2)
ffffffffc0200f28:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc0200f2c:	537000ef          	jal	ffffffffc0201c62 <alloc_pages>
ffffffffc0200f30:	50051a63          	bnez	a0,ffffffffc0201444 <default_check+0x6fa>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200f34:	08098a13          	addi	s4,s3,128
ffffffffc0200f38:	8552                	mv	a0,s4
ffffffffc0200f3a:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200f3c:	00008c17          	auipc	s8,0x8
ffffffffc0200f40:	504c2c03          	lw	s8,1284(s8) # ffffffffc0209440 <free_area+0x10>
    nr_free = 0;
ffffffffc0200f44:	00008797          	auipc	a5,0x8
ffffffffc0200f48:	4e07ae23          	sw	zero,1276(a5) # ffffffffc0209440 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200f4c:	551000ef          	jal	ffffffffc0201c9c <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200f50:	4511                	li	a0,4
ffffffffc0200f52:	511000ef          	jal	ffffffffc0201c62 <alloc_pages>
ffffffffc0200f56:	4c051763          	bnez	a0,ffffffffc0201424 <default_check+0x6da>
ffffffffc0200f5a:	0889b783          	ld	a5,136(s3)
ffffffffc0200f5e:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200f60:	8b85                	andi	a5,a5,1
ffffffffc0200f62:	4a078163          	beqz	a5,ffffffffc0201404 <default_check+0x6ba>
ffffffffc0200f66:	0909a503          	lw	a0,144(s3)
ffffffffc0200f6a:	478d                	li	a5,3
ffffffffc0200f6c:	48f51c63          	bne	a0,a5,ffffffffc0201404 <default_check+0x6ba>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200f70:	4f3000ef          	jal	ffffffffc0201c62 <alloc_pages>
ffffffffc0200f74:	8aaa                	mv	s5,a0
ffffffffc0200f76:	46050763          	beqz	a0,ffffffffc02013e4 <default_check+0x69a>
    assert(alloc_page() == NULL);
ffffffffc0200f7a:	4505                	li	a0,1
ffffffffc0200f7c:	4e7000ef          	jal	ffffffffc0201c62 <alloc_pages>
ffffffffc0200f80:	44051263          	bnez	a0,ffffffffc02013c4 <default_check+0x67a>
    assert(p0 + 2 == p1);
ffffffffc0200f84:	435a1063          	bne	s4,s5,ffffffffc02013a4 <default_check+0x65a>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200f88:	4585                	li	a1,1
ffffffffc0200f8a:	854e                	mv	a0,s3
ffffffffc0200f8c:	511000ef          	jal	ffffffffc0201c9c <free_pages>
    free_pages(p1, 3);
ffffffffc0200f90:	8552                	mv	a0,s4
ffffffffc0200f92:	458d                	li	a1,3
ffffffffc0200f94:	509000ef          	jal	ffffffffc0201c9c <free_pages>
ffffffffc0200f98:	0089b783          	ld	a5,8(s3)
ffffffffc0200f9c:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200f9e:	8b85                	andi	a5,a5,1
ffffffffc0200fa0:	3e078263          	beqz	a5,ffffffffc0201384 <default_check+0x63a>
ffffffffc0200fa4:	0109aa83          	lw	s5,16(s3)
ffffffffc0200fa8:	4785                	li	a5,1
ffffffffc0200faa:	3cfa9d63          	bne	s5,a5,ffffffffc0201384 <default_check+0x63a>
ffffffffc0200fae:	008a3783          	ld	a5,8(s4)
ffffffffc0200fb2:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200fb4:	8b85                	andi	a5,a5,1
ffffffffc0200fb6:	3a078763          	beqz	a5,ffffffffc0201364 <default_check+0x61a>
ffffffffc0200fba:	010a2703          	lw	a4,16(s4)
ffffffffc0200fbe:	478d                	li	a5,3
ffffffffc0200fc0:	3af71263          	bne	a4,a5,ffffffffc0201364 <default_check+0x61a>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200fc4:	8556                	mv	a0,s5
ffffffffc0200fc6:	49d000ef          	jal	ffffffffc0201c62 <alloc_pages>
ffffffffc0200fca:	36a99d63          	bne	s3,a0,ffffffffc0201344 <default_check+0x5fa>
    free_page(p0);
ffffffffc0200fce:	85d6                	mv	a1,s5
ffffffffc0200fd0:	4cd000ef          	jal	ffffffffc0201c9c <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200fd4:	4509                	li	a0,2
ffffffffc0200fd6:	48d000ef          	jal	ffffffffc0201c62 <alloc_pages>
ffffffffc0200fda:	34aa1563          	bne	s4,a0,ffffffffc0201324 <default_check+0x5da>

    free_pages(p0, 2);
ffffffffc0200fde:	4589                	li	a1,2
ffffffffc0200fe0:	4bd000ef          	jal	ffffffffc0201c9c <free_pages>
    free_page(p2);
ffffffffc0200fe4:	04098513          	addi	a0,s3,64
ffffffffc0200fe8:	85d6                	mv	a1,s5
ffffffffc0200fea:	4b3000ef          	jal	ffffffffc0201c9c <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200fee:	4515                	li	a0,5
ffffffffc0200ff0:	473000ef          	jal	ffffffffc0201c62 <alloc_pages>
ffffffffc0200ff4:	89aa                	mv	s3,a0
ffffffffc0200ff6:	48050763          	beqz	a0,ffffffffc0201484 <default_check+0x73a>
    assert(alloc_page() == NULL);
ffffffffc0200ffa:	8556                	mv	a0,s5
ffffffffc0200ffc:	467000ef          	jal	ffffffffc0201c62 <alloc_pages>
ffffffffc0201000:	2e051263          	bnez	a0,ffffffffc02012e4 <default_check+0x59a>

    assert(nr_free == 0);
ffffffffc0201004:	00008797          	auipc	a5,0x8
ffffffffc0201008:	43c7a783          	lw	a5,1084(a5) # ffffffffc0209440 <free_area+0x10>
ffffffffc020100c:	2a079c63          	bnez	a5,ffffffffc02012c4 <default_check+0x57a>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201010:	854e                	mv	a0,s3
ffffffffc0201012:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc0201014:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc0201018:	01793023          	sd	s7,0(s2)
ffffffffc020101c:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc0201020:	47d000ef          	jal	ffffffffc0201c9c <free_pages>
    return listelm->next;
ffffffffc0201024:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201028:	01278963          	beq	a5,s2,ffffffffc020103a <default_check+0x2f0>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc020102c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201030:	679c                	ld	a5,8(a5)
ffffffffc0201032:	34fd                	addiw	s1,s1,-1
ffffffffc0201034:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201036:	ff279be3          	bne	a5,s2,ffffffffc020102c <default_check+0x2e2>
    }
    assert(count == 0);
ffffffffc020103a:	26049563          	bnez	s1,ffffffffc02012a4 <default_check+0x55a>
    assert(total == 0);
ffffffffc020103e:	46041363          	bnez	s0,ffffffffc02014a4 <default_check+0x75a>
}
ffffffffc0201042:	60e6                	ld	ra,88(sp)
ffffffffc0201044:	6446                	ld	s0,80(sp)
ffffffffc0201046:	64a6                	ld	s1,72(sp)
ffffffffc0201048:	6906                	ld	s2,64(sp)
ffffffffc020104a:	79e2                	ld	s3,56(sp)
ffffffffc020104c:	7a42                	ld	s4,48(sp)
ffffffffc020104e:	7aa2                	ld	s5,40(sp)
ffffffffc0201050:	7b02                	ld	s6,32(sp)
ffffffffc0201052:	6be2                	ld	s7,24(sp)
ffffffffc0201054:	6c42                	ld	s8,16(sp)
ffffffffc0201056:	6ca2                	ld	s9,8(sp)
ffffffffc0201058:	6125                	addi	sp,sp,96
ffffffffc020105a:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc020105c:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020105e:	4401                	li	s0,0
ffffffffc0201060:	4481                	li	s1,0
ffffffffc0201062:	b33d                	j	ffffffffc0200d90 <default_check+0x46>
        assert(PageProperty(p));
ffffffffc0201064:	00004697          	auipc	a3,0x4
ffffffffc0201068:	88c68693          	addi	a3,a3,-1908 # ffffffffc02048f0 <etext+0x9c4>
ffffffffc020106c:	00004617          	auipc	a2,0x4
ffffffffc0201070:	89460613          	addi	a2,a2,-1900 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201074:	0f000593          	li	a1,240
ffffffffc0201078:	00004517          	auipc	a0,0x4
ffffffffc020107c:	8a050513          	addi	a0,a0,-1888 # ffffffffc0204918 <etext+0x9ec>
ffffffffc0201080:	b86ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201084:	00004697          	auipc	a3,0x4
ffffffffc0201088:	95468693          	addi	a3,a3,-1708 # ffffffffc02049d8 <etext+0xaac>
ffffffffc020108c:	00004617          	auipc	a2,0x4
ffffffffc0201090:	87460613          	addi	a2,a2,-1932 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201094:	0be00593          	li	a1,190
ffffffffc0201098:	00004517          	auipc	a0,0x4
ffffffffc020109c:	88050513          	addi	a0,a0,-1920 # ffffffffc0204918 <etext+0x9ec>
ffffffffc02010a0:	b66ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02010a4:	00004697          	auipc	a3,0x4
ffffffffc02010a8:	9fc68693          	addi	a3,a3,-1540 # ffffffffc0204aa0 <etext+0xb74>
ffffffffc02010ac:	00004617          	auipc	a2,0x4
ffffffffc02010b0:	85460613          	addi	a2,a2,-1964 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02010b4:	0d900593          	li	a1,217
ffffffffc02010b8:	00004517          	auipc	a0,0x4
ffffffffc02010bc:	86050513          	addi	a0,a0,-1952 # ffffffffc0204918 <etext+0x9ec>
ffffffffc02010c0:	b46ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02010c4:	00004697          	auipc	a3,0x4
ffffffffc02010c8:	95468693          	addi	a3,a3,-1708 # ffffffffc0204a18 <etext+0xaec>
ffffffffc02010cc:	00004617          	auipc	a2,0x4
ffffffffc02010d0:	83460613          	addi	a2,a2,-1996 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02010d4:	0c000593          	li	a1,192
ffffffffc02010d8:	00004517          	auipc	a0,0x4
ffffffffc02010dc:	84050513          	addi	a0,a0,-1984 # ffffffffc0204918 <etext+0x9ec>
ffffffffc02010e0:	b26ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02010e4:	00004697          	auipc	a3,0x4
ffffffffc02010e8:	8cc68693          	addi	a3,a3,-1844 # ffffffffc02049b0 <etext+0xa84>
ffffffffc02010ec:	00004617          	auipc	a2,0x4
ffffffffc02010f0:	81460613          	addi	a2,a2,-2028 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02010f4:	0bd00593          	li	a1,189
ffffffffc02010f8:	00004517          	auipc	a0,0x4
ffffffffc02010fc:	82050513          	addi	a0,a0,-2016 # ffffffffc0204918 <etext+0x9ec>
ffffffffc0201100:	b06ff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201104:	00004697          	auipc	a3,0x4
ffffffffc0201108:	84c68693          	addi	a3,a3,-1972 # ffffffffc0204950 <etext+0xa24>
ffffffffc020110c:	00003617          	auipc	a2,0x3
ffffffffc0201110:	7f460613          	addi	a2,a2,2036 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201114:	0d200593          	li	a1,210
ffffffffc0201118:	00004517          	auipc	a0,0x4
ffffffffc020111c:	80050513          	addi	a0,a0,-2048 # ffffffffc0204918 <etext+0x9ec>
ffffffffc0201120:	ae6ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free == 3);
ffffffffc0201124:	00004697          	auipc	a3,0x4
ffffffffc0201128:	96c68693          	addi	a3,a3,-1684 # ffffffffc0204a90 <etext+0xb64>
ffffffffc020112c:	00003617          	auipc	a2,0x3
ffffffffc0201130:	7d460613          	addi	a2,a2,2004 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201134:	0d000593          	li	a1,208
ffffffffc0201138:	00003517          	auipc	a0,0x3
ffffffffc020113c:	7e050513          	addi	a0,a0,2016 # ffffffffc0204918 <etext+0x9ec>
ffffffffc0201140:	ac6ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201144:	00004697          	auipc	a3,0x4
ffffffffc0201148:	93468693          	addi	a3,a3,-1740 # ffffffffc0204a78 <etext+0xb4c>
ffffffffc020114c:	00003617          	auipc	a2,0x3
ffffffffc0201150:	7b460613          	addi	a2,a2,1972 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201154:	0cb00593          	li	a1,203
ffffffffc0201158:	00003517          	auipc	a0,0x3
ffffffffc020115c:	7c050513          	addi	a0,a0,1984 # ffffffffc0204918 <etext+0x9ec>
ffffffffc0201160:	aa6ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201164:	00004697          	auipc	a3,0x4
ffffffffc0201168:	8f468693          	addi	a3,a3,-1804 # ffffffffc0204a58 <etext+0xb2c>
ffffffffc020116c:	00003617          	auipc	a2,0x3
ffffffffc0201170:	79460613          	addi	a2,a2,1940 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201174:	0c200593          	li	a1,194
ffffffffc0201178:	00003517          	auipc	a0,0x3
ffffffffc020117c:	7a050513          	addi	a0,a0,1952 # ffffffffc0204918 <etext+0x9ec>
ffffffffc0201180:	a86ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(p0 != NULL);
ffffffffc0201184:	00004697          	auipc	a3,0x4
ffffffffc0201188:	96468693          	addi	a3,a3,-1692 # ffffffffc0204ae8 <etext+0xbbc>
ffffffffc020118c:	00003617          	auipc	a2,0x3
ffffffffc0201190:	77460613          	addi	a2,a2,1908 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201194:	0f800593          	li	a1,248
ffffffffc0201198:	00003517          	auipc	a0,0x3
ffffffffc020119c:	78050513          	addi	a0,a0,1920 # ffffffffc0204918 <etext+0x9ec>
ffffffffc02011a0:	a66ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free == 0);
ffffffffc02011a4:	00004697          	auipc	a3,0x4
ffffffffc02011a8:	93468693          	addi	a3,a3,-1740 # ffffffffc0204ad8 <etext+0xbac>
ffffffffc02011ac:	00003617          	auipc	a2,0x3
ffffffffc02011b0:	75460613          	addi	a2,a2,1876 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02011b4:	0df00593          	li	a1,223
ffffffffc02011b8:	00003517          	auipc	a0,0x3
ffffffffc02011bc:	76050513          	addi	a0,a0,1888 # ffffffffc0204918 <etext+0x9ec>
ffffffffc02011c0:	a46ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011c4:	00004697          	auipc	a3,0x4
ffffffffc02011c8:	8b468693          	addi	a3,a3,-1868 # ffffffffc0204a78 <etext+0xb4c>
ffffffffc02011cc:	00003617          	auipc	a2,0x3
ffffffffc02011d0:	73460613          	addi	a2,a2,1844 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02011d4:	0dd00593          	li	a1,221
ffffffffc02011d8:	00003517          	auipc	a0,0x3
ffffffffc02011dc:	74050513          	addi	a0,a0,1856 # ffffffffc0204918 <etext+0x9ec>
ffffffffc02011e0:	a26ff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02011e4:	00004697          	auipc	a3,0x4
ffffffffc02011e8:	8d468693          	addi	a3,a3,-1836 # ffffffffc0204ab8 <etext+0xb8c>
ffffffffc02011ec:	00003617          	auipc	a2,0x3
ffffffffc02011f0:	71460613          	addi	a2,a2,1812 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02011f4:	0dc00593          	li	a1,220
ffffffffc02011f8:	00003517          	auipc	a0,0x3
ffffffffc02011fc:	72050513          	addi	a0,a0,1824 # ffffffffc0204918 <etext+0x9ec>
ffffffffc0201200:	a06ff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201204:	00003697          	auipc	a3,0x3
ffffffffc0201208:	74c68693          	addi	a3,a3,1868 # ffffffffc0204950 <etext+0xa24>
ffffffffc020120c:	00003617          	auipc	a2,0x3
ffffffffc0201210:	6f460613          	addi	a2,a2,1780 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201214:	0b900593          	li	a1,185
ffffffffc0201218:	00003517          	auipc	a0,0x3
ffffffffc020121c:	70050513          	addi	a0,a0,1792 # ffffffffc0204918 <etext+0x9ec>
ffffffffc0201220:	9e6ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201224:	00004697          	auipc	a3,0x4
ffffffffc0201228:	85468693          	addi	a3,a3,-1964 # ffffffffc0204a78 <etext+0xb4c>
ffffffffc020122c:	00003617          	auipc	a2,0x3
ffffffffc0201230:	6d460613          	addi	a2,a2,1748 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201234:	0d600593          	li	a1,214
ffffffffc0201238:	00003517          	auipc	a0,0x3
ffffffffc020123c:	6e050513          	addi	a0,a0,1760 # ffffffffc0204918 <etext+0x9ec>
ffffffffc0201240:	9c6ff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201244:	00003697          	auipc	a3,0x3
ffffffffc0201248:	74c68693          	addi	a3,a3,1868 # ffffffffc0204990 <etext+0xa64>
ffffffffc020124c:	00003617          	auipc	a2,0x3
ffffffffc0201250:	6b460613          	addi	a2,a2,1716 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201254:	0d400593          	li	a1,212
ffffffffc0201258:	00003517          	auipc	a0,0x3
ffffffffc020125c:	6c050513          	addi	a0,a0,1728 # ffffffffc0204918 <etext+0x9ec>
ffffffffc0201260:	9a6ff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201264:	00003697          	auipc	a3,0x3
ffffffffc0201268:	70c68693          	addi	a3,a3,1804 # ffffffffc0204970 <etext+0xa44>
ffffffffc020126c:	00003617          	auipc	a2,0x3
ffffffffc0201270:	69460613          	addi	a2,a2,1684 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201274:	0d300593          	li	a1,211
ffffffffc0201278:	00003517          	auipc	a0,0x3
ffffffffc020127c:	6a050513          	addi	a0,a0,1696 # ffffffffc0204918 <etext+0x9ec>
ffffffffc0201280:	986ff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201284:	00003697          	auipc	a3,0x3
ffffffffc0201288:	70c68693          	addi	a3,a3,1804 # ffffffffc0204990 <etext+0xa64>
ffffffffc020128c:	00003617          	auipc	a2,0x3
ffffffffc0201290:	67460613          	addi	a2,a2,1652 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201294:	0bb00593          	li	a1,187
ffffffffc0201298:	00003517          	auipc	a0,0x3
ffffffffc020129c:	68050513          	addi	a0,a0,1664 # ffffffffc0204918 <etext+0x9ec>
ffffffffc02012a0:	966ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(count == 0);
ffffffffc02012a4:	00004697          	auipc	a3,0x4
ffffffffc02012a8:	99468693          	addi	a3,a3,-1644 # ffffffffc0204c38 <etext+0xd0c>
ffffffffc02012ac:	00003617          	auipc	a2,0x3
ffffffffc02012b0:	65460613          	addi	a2,a2,1620 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02012b4:	12500593          	li	a1,293
ffffffffc02012b8:	00003517          	auipc	a0,0x3
ffffffffc02012bc:	66050513          	addi	a0,a0,1632 # ffffffffc0204918 <etext+0x9ec>
ffffffffc02012c0:	946ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free == 0);
ffffffffc02012c4:	00004697          	auipc	a3,0x4
ffffffffc02012c8:	81468693          	addi	a3,a3,-2028 # ffffffffc0204ad8 <etext+0xbac>
ffffffffc02012cc:	00003617          	auipc	a2,0x3
ffffffffc02012d0:	63460613          	addi	a2,a2,1588 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02012d4:	11a00593          	li	a1,282
ffffffffc02012d8:	00003517          	auipc	a0,0x3
ffffffffc02012dc:	64050513          	addi	a0,a0,1600 # ffffffffc0204918 <etext+0x9ec>
ffffffffc02012e0:	926ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012e4:	00003697          	auipc	a3,0x3
ffffffffc02012e8:	79468693          	addi	a3,a3,1940 # ffffffffc0204a78 <etext+0xb4c>
ffffffffc02012ec:	00003617          	auipc	a2,0x3
ffffffffc02012f0:	61460613          	addi	a2,a2,1556 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02012f4:	11800593          	li	a1,280
ffffffffc02012f8:	00003517          	auipc	a0,0x3
ffffffffc02012fc:	62050513          	addi	a0,a0,1568 # ffffffffc0204918 <etext+0x9ec>
ffffffffc0201300:	906ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201304:	00003697          	auipc	a3,0x3
ffffffffc0201308:	73468693          	addi	a3,a3,1844 # ffffffffc0204a38 <etext+0xb0c>
ffffffffc020130c:	00003617          	auipc	a2,0x3
ffffffffc0201310:	5f460613          	addi	a2,a2,1524 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201314:	0c100593          	li	a1,193
ffffffffc0201318:	00003517          	auipc	a0,0x3
ffffffffc020131c:	60050513          	addi	a0,a0,1536 # ffffffffc0204918 <etext+0x9ec>
ffffffffc0201320:	8e6ff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201324:	00004697          	auipc	a3,0x4
ffffffffc0201328:	8d468693          	addi	a3,a3,-1836 # ffffffffc0204bf8 <etext+0xccc>
ffffffffc020132c:	00003617          	auipc	a2,0x3
ffffffffc0201330:	5d460613          	addi	a2,a2,1492 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201334:	11200593          	li	a1,274
ffffffffc0201338:	00003517          	auipc	a0,0x3
ffffffffc020133c:	5e050513          	addi	a0,a0,1504 # ffffffffc0204918 <etext+0x9ec>
ffffffffc0201340:	8c6ff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201344:	00004697          	auipc	a3,0x4
ffffffffc0201348:	89468693          	addi	a3,a3,-1900 # ffffffffc0204bd8 <etext+0xcac>
ffffffffc020134c:	00003617          	auipc	a2,0x3
ffffffffc0201350:	5b460613          	addi	a2,a2,1460 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201354:	11000593          	li	a1,272
ffffffffc0201358:	00003517          	auipc	a0,0x3
ffffffffc020135c:	5c050513          	addi	a0,a0,1472 # ffffffffc0204918 <etext+0x9ec>
ffffffffc0201360:	8a6ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201364:	00004697          	auipc	a3,0x4
ffffffffc0201368:	84c68693          	addi	a3,a3,-1972 # ffffffffc0204bb0 <etext+0xc84>
ffffffffc020136c:	00003617          	auipc	a2,0x3
ffffffffc0201370:	59460613          	addi	a2,a2,1428 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201374:	10e00593          	li	a1,270
ffffffffc0201378:	00003517          	auipc	a0,0x3
ffffffffc020137c:	5a050513          	addi	a0,a0,1440 # ffffffffc0204918 <etext+0x9ec>
ffffffffc0201380:	886ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201384:	00004697          	auipc	a3,0x4
ffffffffc0201388:	80468693          	addi	a3,a3,-2044 # ffffffffc0204b88 <etext+0xc5c>
ffffffffc020138c:	00003617          	auipc	a2,0x3
ffffffffc0201390:	57460613          	addi	a2,a2,1396 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201394:	10d00593          	li	a1,269
ffffffffc0201398:	00003517          	auipc	a0,0x3
ffffffffc020139c:	58050513          	addi	a0,a0,1408 # ffffffffc0204918 <etext+0x9ec>
ffffffffc02013a0:	866ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02013a4:	00003697          	auipc	a3,0x3
ffffffffc02013a8:	7d468693          	addi	a3,a3,2004 # ffffffffc0204b78 <etext+0xc4c>
ffffffffc02013ac:	00003617          	auipc	a2,0x3
ffffffffc02013b0:	55460613          	addi	a2,a2,1364 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02013b4:	10800593          	li	a1,264
ffffffffc02013b8:	00003517          	auipc	a0,0x3
ffffffffc02013bc:	56050513          	addi	a0,a0,1376 # ffffffffc0204918 <etext+0x9ec>
ffffffffc02013c0:	846ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013c4:	00003697          	auipc	a3,0x3
ffffffffc02013c8:	6b468693          	addi	a3,a3,1716 # ffffffffc0204a78 <etext+0xb4c>
ffffffffc02013cc:	00003617          	auipc	a2,0x3
ffffffffc02013d0:	53460613          	addi	a2,a2,1332 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02013d4:	10700593          	li	a1,263
ffffffffc02013d8:	00003517          	auipc	a0,0x3
ffffffffc02013dc:	54050513          	addi	a0,a0,1344 # ffffffffc0204918 <etext+0x9ec>
ffffffffc02013e0:	826ff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02013e4:	00003697          	auipc	a3,0x3
ffffffffc02013e8:	77468693          	addi	a3,a3,1908 # ffffffffc0204b58 <etext+0xc2c>
ffffffffc02013ec:	00003617          	auipc	a2,0x3
ffffffffc02013f0:	51460613          	addi	a2,a2,1300 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02013f4:	10600593          	li	a1,262
ffffffffc02013f8:	00003517          	auipc	a0,0x3
ffffffffc02013fc:	52050513          	addi	a0,a0,1312 # ffffffffc0204918 <etext+0x9ec>
ffffffffc0201400:	806ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201404:	00003697          	auipc	a3,0x3
ffffffffc0201408:	72468693          	addi	a3,a3,1828 # ffffffffc0204b28 <etext+0xbfc>
ffffffffc020140c:	00003617          	auipc	a2,0x3
ffffffffc0201410:	4f460613          	addi	a2,a2,1268 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201414:	10500593          	li	a1,261
ffffffffc0201418:	00003517          	auipc	a0,0x3
ffffffffc020141c:	50050513          	addi	a0,a0,1280 # ffffffffc0204918 <etext+0x9ec>
ffffffffc0201420:	fe7fe0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201424:	00003697          	auipc	a3,0x3
ffffffffc0201428:	6ec68693          	addi	a3,a3,1772 # ffffffffc0204b10 <etext+0xbe4>
ffffffffc020142c:	00003617          	auipc	a2,0x3
ffffffffc0201430:	4d460613          	addi	a2,a2,1236 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201434:	10400593          	li	a1,260
ffffffffc0201438:	00003517          	auipc	a0,0x3
ffffffffc020143c:	4e050513          	addi	a0,a0,1248 # ffffffffc0204918 <etext+0x9ec>
ffffffffc0201440:	fc7fe0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201444:	00003697          	auipc	a3,0x3
ffffffffc0201448:	63468693          	addi	a3,a3,1588 # ffffffffc0204a78 <etext+0xb4c>
ffffffffc020144c:	00003617          	auipc	a2,0x3
ffffffffc0201450:	4b460613          	addi	a2,a2,1204 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201454:	0fe00593          	li	a1,254
ffffffffc0201458:	00003517          	auipc	a0,0x3
ffffffffc020145c:	4c050513          	addi	a0,a0,1216 # ffffffffc0204918 <etext+0x9ec>
ffffffffc0201460:	fa7fe0ef          	jal	ffffffffc0200406 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201464:	00003697          	auipc	a3,0x3
ffffffffc0201468:	69468693          	addi	a3,a3,1684 # ffffffffc0204af8 <etext+0xbcc>
ffffffffc020146c:	00003617          	auipc	a2,0x3
ffffffffc0201470:	49460613          	addi	a2,a2,1172 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201474:	0f900593          	li	a1,249
ffffffffc0201478:	00003517          	auipc	a0,0x3
ffffffffc020147c:	4a050513          	addi	a0,a0,1184 # ffffffffc0204918 <etext+0x9ec>
ffffffffc0201480:	f87fe0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201484:	00003697          	auipc	a3,0x3
ffffffffc0201488:	79468693          	addi	a3,a3,1940 # ffffffffc0204c18 <etext+0xcec>
ffffffffc020148c:	00003617          	auipc	a2,0x3
ffffffffc0201490:	47460613          	addi	a2,a2,1140 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201494:	11700593          	li	a1,279
ffffffffc0201498:	00003517          	auipc	a0,0x3
ffffffffc020149c:	48050513          	addi	a0,a0,1152 # ffffffffc0204918 <etext+0x9ec>
ffffffffc02014a0:	f67fe0ef          	jal	ffffffffc0200406 <__panic>
    assert(total == 0);
ffffffffc02014a4:	00003697          	auipc	a3,0x3
ffffffffc02014a8:	7a468693          	addi	a3,a3,1956 # ffffffffc0204c48 <etext+0xd1c>
ffffffffc02014ac:	00003617          	auipc	a2,0x3
ffffffffc02014b0:	45460613          	addi	a2,a2,1108 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02014b4:	12600593          	li	a1,294
ffffffffc02014b8:	00003517          	auipc	a0,0x3
ffffffffc02014bc:	46050513          	addi	a0,a0,1120 # ffffffffc0204918 <etext+0x9ec>
ffffffffc02014c0:	f47fe0ef          	jal	ffffffffc0200406 <__panic>
    assert(total == nr_free_pages());
ffffffffc02014c4:	00003697          	auipc	a3,0x3
ffffffffc02014c8:	46c68693          	addi	a3,a3,1132 # ffffffffc0204930 <etext+0xa04>
ffffffffc02014cc:	00003617          	auipc	a2,0x3
ffffffffc02014d0:	43460613          	addi	a2,a2,1076 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02014d4:	0f300593          	li	a1,243
ffffffffc02014d8:	00003517          	auipc	a0,0x3
ffffffffc02014dc:	44050513          	addi	a0,a0,1088 # ffffffffc0204918 <etext+0x9ec>
ffffffffc02014e0:	f27fe0ef          	jal	ffffffffc0200406 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02014e4:	00003697          	auipc	a3,0x3
ffffffffc02014e8:	48c68693          	addi	a3,a3,1164 # ffffffffc0204970 <etext+0xa44>
ffffffffc02014ec:	00003617          	auipc	a2,0x3
ffffffffc02014f0:	41460613          	addi	a2,a2,1044 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02014f4:	0ba00593          	li	a1,186
ffffffffc02014f8:	00003517          	auipc	a0,0x3
ffffffffc02014fc:	42050513          	addi	a0,a0,1056 # ffffffffc0204918 <etext+0x9ec>
ffffffffc0201500:	f07fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201504 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201504:	1141                	addi	sp,sp,-16
ffffffffc0201506:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201508:	14058663          	beqz	a1,ffffffffc0201654 <default_free_pages+0x150>
    for (; p != base + n; p ++) {
ffffffffc020150c:	00659713          	slli	a4,a1,0x6
ffffffffc0201510:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201514:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0201516:	c30d                	beqz	a4,ffffffffc0201538 <default_free_pages+0x34>
ffffffffc0201518:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020151a:	8b05                	andi	a4,a4,1
ffffffffc020151c:	10071c63          	bnez	a4,ffffffffc0201634 <default_free_pages+0x130>
ffffffffc0201520:	6798                	ld	a4,8(a5)
ffffffffc0201522:	8b09                	andi	a4,a4,2
ffffffffc0201524:	10071863          	bnez	a4,ffffffffc0201634 <default_free_pages+0x130>
        p->flags = 0;
ffffffffc0201528:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc020152c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201530:	04078793          	addi	a5,a5,64
ffffffffc0201534:	fed792e3          	bne	a5,a3,ffffffffc0201518 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201538:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc020153a:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020153e:	4789                	li	a5,2
ffffffffc0201540:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201544:	00008717          	auipc	a4,0x8
ffffffffc0201548:	efc72703          	lw	a4,-260(a4) # ffffffffc0209440 <free_area+0x10>
ffffffffc020154c:	00008697          	auipc	a3,0x8
ffffffffc0201550:	ee468693          	addi	a3,a3,-284 # ffffffffc0209430 <free_area>
    return list->next == list;
ffffffffc0201554:	669c                	ld	a5,8(a3)
ffffffffc0201556:	9f2d                	addw	a4,a4,a1
ffffffffc0201558:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020155a:	0ad78163          	beq	a5,a3,ffffffffc02015fc <default_free_pages+0xf8>
            struct Page* page = le2page(le, page_link);
ffffffffc020155e:	fe878713          	addi	a4,a5,-24
ffffffffc0201562:	4581                	li	a1,0
ffffffffc0201564:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201568:	00e56a63          	bltu	a0,a4,ffffffffc020157c <default_free_pages+0x78>
    return listelm->next;
ffffffffc020156c:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020156e:	04d70c63          	beq	a4,a3,ffffffffc02015c6 <default_free_pages+0xc2>
    struct Page *p = base;
ffffffffc0201572:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201574:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201578:	fee57ae3          	bgeu	a0,a4,ffffffffc020156c <default_free_pages+0x68>
ffffffffc020157c:	c199                	beqz	a1,ffffffffc0201582 <default_free_pages+0x7e>
ffffffffc020157e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201582:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201584:	e390                	sd	a2,0(a5)
ffffffffc0201586:	e710                	sd	a2,8(a4)
    elm->next = next;
    elm->prev = prev;
ffffffffc0201588:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc020158a:	f11c                	sd	a5,32(a0)
    if (le != &free_list) {
ffffffffc020158c:	00d70d63          	beq	a4,a3,ffffffffc02015a6 <default_free_pages+0xa2>
        if (p + p->property == base) {
ffffffffc0201590:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201594:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc0201598:	02059813          	slli	a6,a1,0x20
ffffffffc020159c:	01a85793          	srli	a5,a6,0x1a
ffffffffc02015a0:	97b2                	add	a5,a5,a2
ffffffffc02015a2:	02f50c63          	beq	a0,a5,ffffffffc02015da <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02015a6:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc02015a8:	00d78c63          	beq	a5,a3,ffffffffc02015c0 <default_free_pages+0xbc>
        if (base + base->property == p) {
ffffffffc02015ac:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02015ae:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc02015b2:	02061593          	slli	a1,a2,0x20
ffffffffc02015b6:	01a5d713          	srli	a4,a1,0x1a
ffffffffc02015ba:	972a                	add	a4,a4,a0
ffffffffc02015bc:	04e68c63          	beq	a3,a4,ffffffffc0201614 <default_free_pages+0x110>
}
ffffffffc02015c0:	60a2                	ld	ra,8(sp)
ffffffffc02015c2:	0141                	addi	sp,sp,16
ffffffffc02015c4:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02015c6:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02015c8:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02015ca:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02015cc:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02015ce:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02015d0:	02d70f63          	beq	a4,a3,ffffffffc020160e <default_free_pages+0x10a>
ffffffffc02015d4:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02015d6:	87ba                	mv	a5,a4
ffffffffc02015d8:	bf71                	j	ffffffffc0201574 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc02015da:	491c                	lw	a5,16(a0)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02015dc:	5875                	li	a6,-3
ffffffffc02015de:	9fad                	addw	a5,a5,a1
ffffffffc02015e0:	fef72c23          	sw	a5,-8(a4)
ffffffffc02015e4:	6108b02f          	amoand.d	zero,a6,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02015e8:	01853803          	ld	a6,24(a0)
ffffffffc02015ec:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc02015ee:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02015f0:	00b83423          	sd	a1,8(a6) # ff0008 <kern_entry-0xffffffffbf20fff8>
    return listelm->next;
ffffffffc02015f4:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc02015f6:	0105b023          	sd	a6,0(a1)
ffffffffc02015fa:	b77d                	j	ffffffffc02015a8 <default_free_pages+0xa4>
}
ffffffffc02015fc:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02015fe:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0201602:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201604:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0201606:	e398                	sd	a4,0(a5)
ffffffffc0201608:	e798                	sd	a4,8(a5)
}
ffffffffc020160a:	0141                	addi	sp,sp,16
ffffffffc020160c:	8082                	ret
ffffffffc020160e:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc0201610:	873e                	mv	a4,a5
ffffffffc0201612:	bfad                	j	ffffffffc020158c <default_free_pages+0x88>
            base->property += p->property;
ffffffffc0201614:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201618:	56f5                	li	a3,-3
ffffffffc020161a:	9f31                	addw	a4,a4,a2
ffffffffc020161c:	c918                	sw	a4,16(a0)
ffffffffc020161e:	ff078713          	addi	a4,a5,-16
ffffffffc0201622:	60d7302f          	amoand.d	zero,a3,(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201626:	6398                	ld	a4,0(a5)
ffffffffc0201628:	679c                	ld	a5,8(a5)
}
ffffffffc020162a:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020162c:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020162e:	e398                	sd	a4,0(a5)
ffffffffc0201630:	0141                	addi	sp,sp,16
ffffffffc0201632:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201634:	00003697          	auipc	a3,0x3
ffffffffc0201638:	62c68693          	addi	a3,a3,1580 # ffffffffc0204c60 <etext+0xd34>
ffffffffc020163c:	00003617          	auipc	a2,0x3
ffffffffc0201640:	2c460613          	addi	a2,a2,708 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201644:	08300593          	li	a1,131
ffffffffc0201648:	00003517          	auipc	a0,0x3
ffffffffc020164c:	2d050513          	addi	a0,a0,720 # ffffffffc0204918 <etext+0x9ec>
ffffffffc0201650:	db7fe0ef          	jal	ffffffffc0200406 <__panic>
    assert(n > 0);
ffffffffc0201654:	00003697          	auipc	a3,0x3
ffffffffc0201658:	60468693          	addi	a3,a3,1540 # ffffffffc0204c58 <etext+0xd2c>
ffffffffc020165c:	00003617          	auipc	a2,0x3
ffffffffc0201660:	2a460613          	addi	a2,a2,676 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201664:	08000593          	li	a1,128
ffffffffc0201668:	00003517          	auipc	a0,0x3
ffffffffc020166c:	2b050513          	addi	a0,a0,688 # ffffffffc0204918 <etext+0x9ec>
ffffffffc0201670:	d97fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201674 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201674:	c951                	beqz	a0,ffffffffc0201708 <default_alloc_pages+0x94>
    if (n > nr_free) {
ffffffffc0201676:	00008597          	auipc	a1,0x8
ffffffffc020167a:	dca5a583          	lw	a1,-566(a1) # ffffffffc0209440 <free_area+0x10>
ffffffffc020167e:	86aa                	mv	a3,a0
ffffffffc0201680:	02059793          	slli	a5,a1,0x20
ffffffffc0201684:	9381                	srli	a5,a5,0x20
ffffffffc0201686:	00a7ef63          	bltu	a5,a0,ffffffffc02016a4 <default_alloc_pages+0x30>
    list_entry_t *le = &free_list;
ffffffffc020168a:	00008617          	auipc	a2,0x8
ffffffffc020168e:	da660613          	addi	a2,a2,-602 # ffffffffc0209430 <free_area>
ffffffffc0201692:	87b2                	mv	a5,a2
ffffffffc0201694:	a029                	j	ffffffffc020169e <default_alloc_pages+0x2a>
        if (p->property >= n) {
ffffffffc0201696:	ff87e703          	lwu	a4,-8(a5)
ffffffffc020169a:	00d77763          	bgeu	a4,a3,ffffffffc02016a8 <default_alloc_pages+0x34>
    return listelm->next;
ffffffffc020169e:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02016a0:	fec79be3          	bne	a5,a2,ffffffffc0201696 <default_alloc_pages+0x22>
        return NULL;
ffffffffc02016a4:	4501                	li	a0,0
}
ffffffffc02016a6:	8082                	ret
        if (page->property > n) {
ffffffffc02016a8:	ff87a883          	lw	a7,-8(a5)
    return listelm->prev;
ffffffffc02016ac:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02016b0:	6798                	ld	a4,8(a5)
ffffffffc02016b2:	02089313          	slli	t1,a7,0x20
ffffffffc02016b6:	02035313          	srli	t1,t1,0x20
    prev->next = next;
ffffffffc02016ba:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc02016be:	01073023          	sd	a6,0(a4)
        struct Page *p = le2page(le, page_link);
ffffffffc02016c2:	fe878513          	addi	a0,a5,-24
        if (page->property > n) {
ffffffffc02016c6:	0266fa63          	bgeu	a3,t1,ffffffffc02016fa <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc02016ca:	00669713          	slli	a4,a3,0x6
            p->property = page->property - n;
ffffffffc02016ce:	40d888bb          	subw	a7,a7,a3
            struct Page *p = page + n;
ffffffffc02016d2:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02016d4:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02016d8:	00870313          	addi	t1,a4,8
ffffffffc02016dc:	4889                	li	a7,2
ffffffffc02016de:	4113302f          	amoor.d	zero,a7,(t1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02016e2:	00883883          	ld	a7,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc02016e6:	01870313          	addi	t1,a4,24
    prev->next = next->prev = elm;
ffffffffc02016ea:	0068b023          	sd	t1,0(a7)
ffffffffc02016ee:	00683423          	sd	t1,8(a6)
    elm->next = next;
ffffffffc02016f2:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc02016f6:	01073c23          	sd	a6,24(a4)
        nr_free -= n;
ffffffffc02016fa:	9d95                	subw	a1,a1,a3
ffffffffc02016fc:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02016fe:	5775                	li	a4,-3
ffffffffc0201700:	17c1                	addi	a5,a5,-16
ffffffffc0201702:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201706:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201708:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020170a:	00003697          	auipc	a3,0x3
ffffffffc020170e:	54e68693          	addi	a3,a3,1358 # ffffffffc0204c58 <etext+0xd2c>
ffffffffc0201712:	00003617          	auipc	a2,0x3
ffffffffc0201716:	1ee60613          	addi	a2,a2,494 # ffffffffc0204900 <etext+0x9d4>
ffffffffc020171a:	06200593          	li	a1,98
ffffffffc020171e:	00003517          	auipc	a0,0x3
ffffffffc0201722:	1fa50513          	addi	a0,a0,506 # ffffffffc0204918 <etext+0x9ec>
default_alloc_pages(size_t n) {
ffffffffc0201726:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201728:	cdffe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc020172c <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc020172c:	1141                	addi	sp,sp,-16
ffffffffc020172e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201730:	c9e1                	beqz	a1,ffffffffc0201800 <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc0201732:	00659713          	slli	a4,a1,0x6
ffffffffc0201736:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc020173a:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc020173c:	cf11                	beqz	a4,ffffffffc0201758 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020173e:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201740:	8b05                	andi	a4,a4,1
ffffffffc0201742:	cf59                	beqz	a4,ffffffffc02017e0 <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc0201744:	0007a823          	sw	zero,16(a5)
ffffffffc0201748:	0007b423          	sd	zero,8(a5)
ffffffffc020174c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201750:	04078793          	addi	a5,a5,64
ffffffffc0201754:	fed795e3          	bne	a5,a3,ffffffffc020173e <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201758:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020175a:	4789                	li	a5,2
ffffffffc020175c:	00850713          	addi	a4,a0,8
ffffffffc0201760:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201764:	00008717          	auipc	a4,0x8
ffffffffc0201768:	cdc72703          	lw	a4,-804(a4) # ffffffffc0209440 <free_area+0x10>
ffffffffc020176c:	00008697          	auipc	a3,0x8
ffffffffc0201770:	cc468693          	addi	a3,a3,-828 # ffffffffc0209430 <free_area>
    return list->next == list;
ffffffffc0201774:	669c                	ld	a5,8(a3)
ffffffffc0201776:	9f2d                	addw	a4,a4,a1
ffffffffc0201778:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020177a:	04d78663          	beq	a5,a3,ffffffffc02017c6 <default_init_memmap+0x9a>
            struct Page* page = le2page(le, page_link);
ffffffffc020177e:	fe878713          	addi	a4,a5,-24
ffffffffc0201782:	4581                	li	a1,0
ffffffffc0201784:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201788:	00e56a63          	bltu	a0,a4,ffffffffc020179c <default_init_memmap+0x70>
    return listelm->next;
ffffffffc020178c:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020178e:	02d70263          	beq	a4,a3,ffffffffc02017b2 <default_init_memmap+0x86>
    struct Page *p = base;
ffffffffc0201792:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201794:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201798:	fee57ae3          	bgeu	a0,a4,ffffffffc020178c <default_init_memmap+0x60>
ffffffffc020179c:	c199                	beqz	a1,ffffffffc02017a2 <default_init_memmap+0x76>
ffffffffc020179e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02017a2:	6398                	ld	a4,0(a5)
}
ffffffffc02017a4:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02017a6:	e390                	sd	a2,0(a5)
ffffffffc02017a8:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc02017aa:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc02017ac:	f11c                	sd	a5,32(a0)
ffffffffc02017ae:	0141                	addi	sp,sp,16
ffffffffc02017b0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02017b2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02017b4:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02017b6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02017b8:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02017ba:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02017bc:	00d70e63          	beq	a4,a3,ffffffffc02017d8 <default_init_memmap+0xac>
ffffffffc02017c0:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02017c2:	87ba                	mv	a5,a4
ffffffffc02017c4:	bfc1                	j	ffffffffc0201794 <default_init_memmap+0x68>
}
ffffffffc02017c6:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02017c8:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc02017cc:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02017ce:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc02017d0:	e398                	sd	a4,0(a5)
ffffffffc02017d2:	e798                	sd	a4,8(a5)
}
ffffffffc02017d4:	0141                	addi	sp,sp,16
ffffffffc02017d6:	8082                	ret
ffffffffc02017d8:	60a2                	ld	ra,8(sp)
ffffffffc02017da:	e290                	sd	a2,0(a3)
ffffffffc02017dc:	0141                	addi	sp,sp,16
ffffffffc02017de:	8082                	ret
        assert(PageReserved(p));
ffffffffc02017e0:	00003697          	auipc	a3,0x3
ffffffffc02017e4:	4a868693          	addi	a3,a3,1192 # ffffffffc0204c88 <etext+0xd5c>
ffffffffc02017e8:	00003617          	auipc	a2,0x3
ffffffffc02017ec:	11860613          	addi	a2,a2,280 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02017f0:	04900593          	li	a1,73
ffffffffc02017f4:	00003517          	auipc	a0,0x3
ffffffffc02017f8:	12450513          	addi	a0,a0,292 # ffffffffc0204918 <etext+0x9ec>
ffffffffc02017fc:	c0bfe0ef          	jal	ffffffffc0200406 <__panic>
    assert(n > 0);
ffffffffc0201800:	00003697          	auipc	a3,0x3
ffffffffc0201804:	45868693          	addi	a3,a3,1112 # ffffffffc0204c58 <etext+0xd2c>
ffffffffc0201808:	00003617          	auipc	a2,0x3
ffffffffc020180c:	0f860613          	addi	a2,a2,248 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201810:	04600593          	li	a1,70
ffffffffc0201814:	00003517          	auipc	a0,0x3
ffffffffc0201818:	10450513          	addi	a0,a0,260 # ffffffffc0204918 <etext+0x9ec>
ffffffffc020181c:	bebfe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201820 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201820:	c531                	beqz	a0,ffffffffc020186c <slob_free+0x4c>
		return;

	if (size)
ffffffffc0201822:	e9b9                	bnez	a1,ffffffffc0201878 <slob_free+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201824:	100027f3          	csrr	a5,sstatus
ffffffffc0201828:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020182a:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020182c:	efb1                	bnez	a5,ffffffffc0201888 <slob_free+0x68>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020182e:	00007797          	auipc	a5,0x7
ffffffffc0201832:	7f27b783          	ld	a5,2034(a5) # ffffffffc0209020 <slobfree>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201836:	873e                	mv	a4,a5
ffffffffc0201838:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020183a:	02a77a63          	bgeu	a4,a0,ffffffffc020186e <slob_free+0x4e>
ffffffffc020183e:	00f56463          	bltu	a0,a5,ffffffffc0201846 <slob_free+0x26>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201842:	fef76ae3          	bltu	a4,a5,ffffffffc0201836 <slob_free+0x16>
			break;

	if (b + b->units == cur->next)
ffffffffc0201846:	4110                	lw	a2,0(a0)
ffffffffc0201848:	00461693          	slli	a3,a2,0x4
ffffffffc020184c:	96aa                	add	a3,a3,a0
ffffffffc020184e:	0ad78463          	beq	a5,a3,ffffffffc02018f6 <slob_free+0xd6>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201852:	4310                	lw	a2,0(a4)
ffffffffc0201854:	e51c                	sd	a5,8(a0)
ffffffffc0201856:	00461693          	slli	a3,a2,0x4
ffffffffc020185a:	96ba                	add	a3,a3,a4
ffffffffc020185c:	08d50163          	beq	a0,a3,ffffffffc02018de <slob_free+0xbe>
ffffffffc0201860:	e708                	sd	a0,8(a4)
		cur->next = b->next;
	}
	else
		cur->next = b;

	slobfree = cur;
ffffffffc0201862:	00007797          	auipc	a5,0x7
ffffffffc0201866:	7ae7bf23          	sd	a4,1982(a5) # ffffffffc0209020 <slobfree>
    if (flag) {
ffffffffc020186a:	e9a5                	bnez	a1,ffffffffc02018da <slob_free+0xba>
ffffffffc020186c:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020186e:	fcf574e3          	bgeu	a0,a5,ffffffffc0201836 <slob_free+0x16>
ffffffffc0201872:	fcf762e3          	bltu	a4,a5,ffffffffc0201836 <slob_free+0x16>
ffffffffc0201876:	bfc1                	j	ffffffffc0201846 <slob_free+0x26>
		b->units = SLOB_UNITS(size);
ffffffffc0201878:	25bd                	addiw	a1,a1,15
ffffffffc020187a:	8191                	srli	a1,a1,0x4
ffffffffc020187c:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020187e:	100027f3          	csrr	a5,sstatus
ffffffffc0201882:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201884:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201886:	d7c5                	beqz	a5,ffffffffc020182e <slob_free+0xe>
{
ffffffffc0201888:	1101                	addi	sp,sp,-32
ffffffffc020188a:	e42a                	sd	a0,8(sp)
ffffffffc020188c:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc020188e:	fe7fe0ef          	jal	ffffffffc0200874 <intr_disable>
        return 1;
ffffffffc0201892:	6522                	ld	a0,8(sp)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201894:	00007797          	auipc	a5,0x7
ffffffffc0201898:	78c7b783          	ld	a5,1932(a5) # ffffffffc0209020 <slobfree>
ffffffffc020189c:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020189e:	873e                	mv	a4,a5
ffffffffc02018a0:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02018a2:	06a77663          	bgeu	a4,a0,ffffffffc020190e <slob_free+0xee>
ffffffffc02018a6:	00f56463          	bltu	a0,a5,ffffffffc02018ae <slob_free+0x8e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018aa:	fef76ae3          	bltu	a4,a5,ffffffffc020189e <slob_free+0x7e>
	if (b + b->units == cur->next)
ffffffffc02018ae:	4110                	lw	a2,0(a0)
ffffffffc02018b0:	00461693          	slli	a3,a2,0x4
ffffffffc02018b4:	96aa                	add	a3,a3,a0
ffffffffc02018b6:	06d78363          	beq	a5,a3,ffffffffc020191c <slob_free+0xfc>
	if (cur + cur->units == b)
ffffffffc02018ba:	4310                	lw	a2,0(a4)
ffffffffc02018bc:	e51c                	sd	a5,8(a0)
ffffffffc02018be:	00461693          	slli	a3,a2,0x4
ffffffffc02018c2:	96ba                	add	a3,a3,a4
ffffffffc02018c4:	06d50163          	beq	a0,a3,ffffffffc0201926 <slob_free+0x106>
ffffffffc02018c8:	e708                	sd	a0,8(a4)
	slobfree = cur;
ffffffffc02018ca:	00007797          	auipc	a5,0x7
ffffffffc02018ce:	74e7bb23          	sd	a4,1878(a5) # ffffffffc0209020 <slobfree>
    if (flag) {
ffffffffc02018d2:	e1a9                	bnez	a1,ffffffffc0201914 <slob_free+0xf4>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc02018d4:	60e2                	ld	ra,24(sp)
ffffffffc02018d6:	6105                	addi	sp,sp,32
ffffffffc02018d8:	8082                	ret
        intr_enable();
ffffffffc02018da:	f95fe06f          	j	ffffffffc020086e <intr_enable>
		cur->units += b->units;
ffffffffc02018de:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc02018e0:	853e                	mv	a0,a5
ffffffffc02018e2:	e708                	sd	a0,8(a4)
		cur->units += b->units;
ffffffffc02018e4:	00c687bb          	addw	a5,a3,a2
ffffffffc02018e8:	c31c                	sw	a5,0(a4)
	slobfree = cur;
ffffffffc02018ea:	00007797          	auipc	a5,0x7
ffffffffc02018ee:	72e7bb23          	sd	a4,1846(a5) # ffffffffc0209020 <slobfree>
    if (flag) {
ffffffffc02018f2:	ddad                	beqz	a1,ffffffffc020186c <slob_free+0x4c>
ffffffffc02018f4:	b7dd                	j	ffffffffc02018da <slob_free+0xba>
		b->units += cur->next->units;
ffffffffc02018f6:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc02018f8:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc02018fa:	9eb1                	addw	a3,a3,a2
ffffffffc02018fc:	c114                	sw	a3,0(a0)
	if (cur + cur->units == b)
ffffffffc02018fe:	4310                	lw	a2,0(a4)
ffffffffc0201900:	e51c                	sd	a5,8(a0)
ffffffffc0201902:	00461693          	slli	a3,a2,0x4
ffffffffc0201906:	96ba                	add	a3,a3,a4
ffffffffc0201908:	f4d51ce3          	bne	a0,a3,ffffffffc0201860 <slob_free+0x40>
ffffffffc020190c:	bfc9                	j	ffffffffc02018de <slob_free+0xbe>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020190e:	f8f56ee3          	bltu	a0,a5,ffffffffc02018aa <slob_free+0x8a>
ffffffffc0201912:	b771                	j	ffffffffc020189e <slob_free+0x7e>
}
ffffffffc0201914:	60e2                	ld	ra,24(sp)
ffffffffc0201916:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201918:	f57fe06f          	j	ffffffffc020086e <intr_enable>
		b->units += cur->next->units;
ffffffffc020191c:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc020191e:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201920:	9eb1                	addw	a3,a3,a2
ffffffffc0201922:	c114                	sw	a3,0(a0)
		b->next = cur->next->next;
ffffffffc0201924:	bf59                	j	ffffffffc02018ba <slob_free+0x9a>
		cur->units += b->units;
ffffffffc0201926:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201928:	853e                	mv	a0,a5
		cur->units += b->units;
ffffffffc020192a:	00c687bb          	addw	a5,a3,a2
ffffffffc020192e:	c31c                	sw	a5,0(a4)
		cur->next = b->next;
ffffffffc0201930:	bf61                	j	ffffffffc02018c8 <slob_free+0xa8>

ffffffffc0201932 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201932:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201934:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201936:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc020193a:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc020193c:	326000ef          	jal	ffffffffc0201c62 <alloc_pages>
	if (!page)
ffffffffc0201940:	c91d                	beqz	a0,ffffffffc0201976 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201942:	0000c697          	auipc	a3,0xc
ffffffffc0201946:	b866b683          	ld	a3,-1146(a3) # ffffffffc020d4c8 <pages>
ffffffffc020194a:	00004797          	auipc	a5,0x4
ffffffffc020194e:	1667b783          	ld	a5,358(a5) # ffffffffc0205ab0 <nbase>
    return KADDR(page2pa(page));
ffffffffc0201952:	0000c717          	auipc	a4,0xc
ffffffffc0201956:	b6e73703          	ld	a4,-1170(a4) # ffffffffc020d4c0 <npage>
    return page - pages + nbase;
ffffffffc020195a:	8d15                	sub	a0,a0,a3
ffffffffc020195c:	8519                	srai	a0,a0,0x6
ffffffffc020195e:	953e                	add	a0,a0,a5
    return KADDR(page2pa(page));
ffffffffc0201960:	00c51793          	slli	a5,a0,0xc
ffffffffc0201964:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201966:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201968:	00e7fa63          	bgeu	a5,a4,ffffffffc020197c <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc020196c:	0000c797          	auipc	a5,0xc
ffffffffc0201970:	b4c7b783          	ld	a5,-1204(a5) # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0201974:	953e                	add	a0,a0,a5
}
ffffffffc0201976:	60a2                	ld	ra,8(sp)
ffffffffc0201978:	0141                	addi	sp,sp,16
ffffffffc020197a:	8082                	ret
ffffffffc020197c:	86aa                	mv	a3,a0
ffffffffc020197e:	00003617          	auipc	a2,0x3
ffffffffc0201982:	33260613          	addi	a2,a2,818 # ffffffffc0204cb0 <etext+0xd84>
ffffffffc0201986:	07100593          	li	a1,113
ffffffffc020198a:	00003517          	auipc	a0,0x3
ffffffffc020198e:	34e50513          	addi	a0,a0,846 # ffffffffc0204cd8 <etext+0xdac>
ffffffffc0201992:	a75fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201996 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201996:	7179                	addi	sp,sp,-48
ffffffffc0201998:	f406                	sd	ra,40(sp)
ffffffffc020199a:	f022                	sd	s0,32(sp)
ffffffffc020199c:	ec26                	sd	s1,24(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc020199e:	01050713          	addi	a4,a0,16
ffffffffc02019a2:	6785                	lui	a5,0x1
ffffffffc02019a4:	0af77e63          	bgeu	a4,a5,ffffffffc0201a60 <slob_alloc.constprop.0+0xca>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc02019a8:	00f50413          	addi	s0,a0,15
ffffffffc02019ac:	8011                	srli	s0,s0,0x4
ffffffffc02019ae:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019b0:	100025f3          	csrr	a1,sstatus
ffffffffc02019b4:	8989                	andi	a1,a1,2
ffffffffc02019b6:	edd1                	bnez	a1,ffffffffc0201a52 <slob_alloc.constprop.0+0xbc>
	prev = slobfree;
ffffffffc02019b8:	00007497          	auipc	s1,0x7
ffffffffc02019bc:	66848493          	addi	s1,s1,1640 # ffffffffc0209020 <slobfree>
ffffffffc02019c0:	6090                	ld	a2,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019c2:	6618                	ld	a4,8(a2)
		if (cur->units >= units + delta)
ffffffffc02019c4:	4314                	lw	a3,0(a4)
ffffffffc02019c6:	0886da63          	bge	a3,s0,ffffffffc0201a5a <slob_alloc.constprop.0+0xc4>
		if (cur == slobfree)
ffffffffc02019ca:	00e60a63          	beq	a2,a4,ffffffffc02019de <slob_alloc.constprop.0+0x48>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019ce:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc02019d0:	4394                	lw	a3,0(a5)
ffffffffc02019d2:	0286d863          	bge	a3,s0,ffffffffc0201a02 <slob_alloc.constprop.0+0x6c>
		if (cur == slobfree)
ffffffffc02019d6:	6090                	ld	a2,0(s1)
ffffffffc02019d8:	873e                	mv	a4,a5
ffffffffc02019da:	fee61ae3          	bne	a2,a4,ffffffffc02019ce <slob_alloc.constprop.0+0x38>
    if (flag) {
ffffffffc02019de:	e9b1                	bnez	a1,ffffffffc0201a32 <slob_alloc.constprop.0+0x9c>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc02019e0:	4501                	li	a0,0
ffffffffc02019e2:	f51ff0ef          	jal	ffffffffc0201932 <__slob_get_free_pages.constprop.0>
ffffffffc02019e6:	87aa                	mv	a5,a0
			if (!cur)
ffffffffc02019e8:	c915                	beqz	a0,ffffffffc0201a1c <slob_alloc.constprop.0+0x86>
			slob_free(cur, PAGE_SIZE);
ffffffffc02019ea:	6585                	lui	a1,0x1
ffffffffc02019ec:	e35ff0ef          	jal	ffffffffc0201820 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019f0:	100025f3          	csrr	a1,sstatus
ffffffffc02019f4:	8989                	andi	a1,a1,2
ffffffffc02019f6:	e98d                	bnez	a1,ffffffffc0201a28 <slob_alloc.constprop.0+0x92>
			cur = slobfree;
ffffffffc02019f8:	6098                	ld	a4,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019fa:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc02019fc:	4394                	lw	a3,0(a5)
ffffffffc02019fe:	fc86cce3          	blt	a3,s0,ffffffffc02019d6 <slob_alloc.constprop.0+0x40>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201a02:	04d40563          	beq	s0,a3,ffffffffc0201a4c <slob_alloc.constprop.0+0xb6>
				prev->next = cur + units;
ffffffffc0201a06:	00441613          	slli	a2,s0,0x4
ffffffffc0201a0a:	963e                	add	a2,a2,a5
ffffffffc0201a0c:	e710                	sd	a2,8(a4)
				prev->next->next = cur->next;
ffffffffc0201a0e:	6788                	ld	a0,8(a5)
				prev->next->units = cur->units - units;
ffffffffc0201a10:	9e81                	subw	a3,a3,s0
ffffffffc0201a12:	c214                	sw	a3,0(a2)
				prev->next->next = cur->next;
ffffffffc0201a14:	e608                	sd	a0,8(a2)
				cur->units = units;
ffffffffc0201a16:	c380                	sw	s0,0(a5)
			slobfree = prev;
ffffffffc0201a18:	e098                	sd	a4,0(s1)
    if (flag) {
ffffffffc0201a1a:	ed99                	bnez	a1,ffffffffc0201a38 <slob_alloc.constprop.0+0xa2>
}
ffffffffc0201a1c:	70a2                	ld	ra,40(sp)
ffffffffc0201a1e:	7402                	ld	s0,32(sp)
ffffffffc0201a20:	64e2                	ld	s1,24(sp)
ffffffffc0201a22:	853e                	mv	a0,a5
ffffffffc0201a24:	6145                	addi	sp,sp,48
ffffffffc0201a26:	8082                	ret
        intr_disable();
ffffffffc0201a28:	e4dfe0ef          	jal	ffffffffc0200874 <intr_disable>
			cur = slobfree;
ffffffffc0201a2c:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0201a2e:	4585                	li	a1,1
ffffffffc0201a30:	b7e9                	j	ffffffffc02019fa <slob_alloc.constprop.0+0x64>
        intr_enable();
ffffffffc0201a32:	e3dfe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201a36:	b76d                	j	ffffffffc02019e0 <slob_alloc.constprop.0+0x4a>
ffffffffc0201a38:	e43e                	sd	a5,8(sp)
ffffffffc0201a3a:	e35fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201a3e:	67a2                	ld	a5,8(sp)
}
ffffffffc0201a40:	70a2                	ld	ra,40(sp)
ffffffffc0201a42:	7402                	ld	s0,32(sp)
ffffffffc0201a44:	64e2                	ld	s1,24(sp)
ffffffffc0201a46:	853e                	mv	a0,a5
ffffffffc0201a48:	6145                	addi	sp,sp,48
ffffffffc0201a4a:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201a4c:	6794                	ld	a3,8(a5)
ffffffffc0201a4e:	e714                	sd	a3,8(a4)
ffffffffc0201a50:	b7e1                	j	ffffffffc0201a18 <slob_alloc.constprop.0+0x82>
        intr_disable();
ffffffffc0201a52:	e23fe0ef          	jal	ffffffffc0200874 <intr_disable>
        return 1;
ffffffffc0201a56:	4585                	li	a1,1
ffffffffc0201a58:	b785                	j	ffffffffc02019b8 <slob_alloc.constprop.0+0x22>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201a5a:	87ba                	mv	a5,a4
	prev = slobfree;
ffffffffc0201a5c:	8732                	mv	a4,a2
ffffffffc0201a5e:	b755                	j	ffffffffc0201a02 <slob_alloc.constprop.0+0x6c>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201a60:	00003697          	auipc	a3,0x3
ffffffffc0201a64:	28868693          	addi	a3,a3,648 # ffffffffc0204ce8 <etext+0xdbc>
ffffffffc0201a68:	00003617          	auipc	a2,0x3
ffffffffc0201a6c:	e9860613          	addi	a2,a2,-360 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0201a70:	06300593          	li	a1,99
ffffffffc0201a74:	00003517          	auipc	a0,0x3
ffffffffc0201a78:	29450513          	addi	a0,a0,660 # ffffffffc0204d08 <etext+0xddc>
ffffffffc0201a7c:	98bfe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201a80 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201a80:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201a82:	00003517          	auipc	a0,0x3
ffffffffc0201a86:	29e50513          	addi	a0,a0,670 # ffffffffc0204d20 <etext+0xdf4>
{
ffffffffc0201a8a:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201a8c:	f08fe0ef          	jal	ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201a90:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201a92:	00003517          	auipc	a0,0x3
ffffffffc0201a96:	2a650513          	addi	a0,a0,678 # ffffffffc0204d38 <etext+0xe0c>
}
ffffffffc0201a9a:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201a9c:	ef8fe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201aa0 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201aa0:	1101                	addi	sp,sp,-32
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201aa2:	6685                	lui	a3,0x1
{
ffffffffc0201aa4:	ec06                	sd	ra,24(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201aa6:	16bd                	addi	a3,a3,-17 # fef <kern_entry-0xffffffffc01ff011>
ffffffffc0201aa8:	04a6f963          	bgeu	a3,a0,ffffffffc0201afa <kmalloc+0x5a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201aac:	e42a                	sd	a0,8(sp)
ffffffffc0201aae:	4561                	li	a0,24
ffffffffc0201ab0:	e822                	sd	s0,16(sp)
ffffffffc0201ab2:	ee5ff0ef          	jal	ffffffffc0201996 <slob_alloc.constprop.0>
ffffffffc0201ab6:	842a                	mv	s0,a0
	if (!bb)
ffffffffc0201ab8:	c541                	beqz	a0,ffffffffc0201b40 <kmalloc+0xa0>
	bb->order = find_order(size);
ffffffffc0201aba:	47a2                	lw	a5,8(sp)
	for (; size > 4096; size >>= 1)
ffffffffc0201abc:	6705                	lui	a4,0x1
	int order = 0;
ffffffffc0201abe:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201ac0:	00f75763          	bge	a4,a5,ffffffffc0201ace <kmalloc+0x2e>
ffffffffc0201ac4:	4017d79b          	sraiw	a5,a5,0x1
		order++;
ffffffffc0201ac8:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201aca:	fef74de3          	blt	a4,a5,ffffffffc0201ac4 <kmalloc+0x24>
	bb->order = find_order(size);
ffffffffc0201ace:	c008                	sw	a0,0(s0)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201ad0:	e63ff0ef          	jal	ffffffffc0201932 <__slob_get_free_pages.constprop.0>
ffffffffc0201ad4:	e408                	sd	a0,8(s0)
	if (bb->pages)
ffffffffc0201ad6:	cd31                	beqz	a0,ffffffffc0201b32 <kmalloc+0x92>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201ad8:	100027f3          	csrr	a5,sstatus
ffffffffc0201adc:	8b89                	andi	a5,a5,2
ffffffffc0201ade:	eb85                	bnez	a5,ffffffffc0201b0e <kmalloc+0x6e>
		bb->next = bigblocks;
ffffffffc0201ae0:	0000c797          	auipc	a5,0xc
ffffffffc0201ae4:	9b87b783          	ld	a5,-1608(a5) # ffffffffc020d498 <bigblocks>
		bigblocks = bb;
ffffffffc0201ae8:	0000c717          	auipc	a4,0xc
ffffffffc0201aec:	9a873823          	sd	s0,-1616(a4) # ffffffffc020d498 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201af0:	e81c                	sd	a5,16(s0)
    if (flag) {
ffffffffc0201af2:	6442                	ld	s0,16(sp)
	return __kmalloc(size, 0);
}
ffffffffc0201af4:	60e2                	ld	ra,24(sp)
ffffffffc0201af6:	6105                	addi	sp,sp,32
ffffffffc0201af8:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201afa:	0541                	addi	a0,a0,16
ffffffffc0201afc:	e9bff0ef          	jal	ffffffffc0201996 <slob_alloc.constprop.0>
ffffffffc0201b00:	87aa                	mv	a5,a0
		return m ? (void *)(m + 1) : 0;
ffffffffc0201b02:	0541                	addi	a0,a0,16
ffffffffc0201b04:	fbe5                	bnez	a5,ffffffffc0201af4 <kmalloc+0x54>
		return 0;
ffffffffc0201b06:	4501                	li	a0,0
}
ffffffffc0201b08:	60e2                	ld	ra,24(sp)
ffffffffc0201b0a:	6105                	addi	sp,sp,32
ffffffffc0201b0c:	8082                	ret
        intr_disable();
ffffffffc0201b0e:	d67fe0ef          	jal	ffffffffc0200874 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201b12:	0000c797          	auipc	a5,0xc
ffffffffc0201b16:	9867b783          	ld	a5,-1658(a5) # ffffffffc020d498 <bigblocks>
		bigblocks = bb;
ffffffffc0201b1a:	0000c717          	auipc	a4,0xc
ffffffffc0201b1e:	96873f23          	sd	s0,-1666(a4) # ffffffffc020d498 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201b22:	e81c                	sd	a5,16(s0)
        intr_enable();
ffffffffc0201b24:	d4bfe0ef          	jal	ffffffffc020086e <intr_enable>
		return bb->pages;
ffffffffc0201b28:	6408                	ld	a0,8(s0)
}
ffffffffc0201b2a:	60e2                	ld	ra,24(sp)
		return bb->pages;
ffffffffc0201b2c:	6442                	ld	s0,16(sp)
}
ffffffffc0201b2e:	6105                	addi	sp,sp,32
ffffffffc0201b30:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b32:	8522                	mv	a0,s0
ffffffffc0201b34:	45e1                	li	a1,24
ffffffffc0201b36:	cebff0ef          	jal	ffffffffc0201820 <slob_free>
		return 0;
ffffffffc0201b3a:	4501                	li	a0,0
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b3c:	6442                	ld	s0,16(sp)
ffffffffc0201b3e:	b7e9                	j	ffffffffc0201b08 <kmalloc+0x68>
ffffffffc0201b40:	6442                	ld	s0,16(sp)
		return 0;
ffffffffc0201b42:	4501                	li	a0,0
ffffffffc0201b44:	b7d1                	j	ffffffffc0201b08 <kmalloc+0x68>

ffffffffc0201b46 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201b46:	c571                	beqz	a0,ffffffffc0201c12 <kfree+0xcc>
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201b48:	03451793          	slli	a5,a0,0x34
ffffffffc0201b4c:	e3e1                	bnez	a5,ffffffffc0201c0c <kfree+0xc6>
{
ffffffffc0201b4e:	1101                	addi	sp,sp,-32
ffffffffc0201b50:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b52:	100027f3          	csrr	a5,sstatus
ffffffffc0201b56:	8b89                	andi	a5,a5,2
ffffffffc0201b58:	e7c1                	bnez	a5,ffffffffc0201be0 <kfree+0x9a>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b5a:	0000c797          	auipc	a5,0xc
ffffffffc0201b5e:	93e7b783          	ld	a5,-1730(a5) # ffffffffc020d498 <bigblocks>
    return 0;
ffffffffc0201b62:	4581                	li	a1,0
ffffffffc0201b64:	cbad                	beqz	a5,ffffffffc0201bd6 <kfree+0x90>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201b66:	0000c617          	auipc	a2,0xc
ffffffffc0201b6a:	93260613          	addi	a2,a2,-1742 # ffffffffc020d498 <bigblocks>
ffffffffc0201b6e:	a021                	j	ffffffffc0201b76 <kfree+0x30>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b70:	01070613          	addi	a2,a4,16
ffffffffc0201b74:	c3a5                	beqz	a5,ffffffffc0201bd4 <kfree+0x8e>
		{
			if (bb->pages == block)
ffffffffc0201b76:	6794                	ld	a3,8(a5)
ffffffffc0201b78:	873e                	mv	a4,a5
			{
				*last = bb->next;
ffffffffc0201b7a:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201b7c:	fea69ae3          	bne	a3,a0,ffffffffc0201b70 <kfree+0x2a>
				*last = bb->next;
ffffffffc0201b80:	e21c                	sd	a5,0(a2)
    if (flag) {
ffffffffc0201b82:	edb5                	bnez	a1,ffffffffc0201bfe <kfree+0xb8>
    return pa2page(PADDR(kva));
ffffffffc0201b84:	c02007b7          	lui	a5,0xc0200
ffffffffc0201b88:	0af56263          	bltu	a0,a5,ffffffffc0201c2c <kfree+0xe6>
ffffffffc0201b8c:	0000c797          	auipc	a5,0xc
ffffffffc0201b90:	92c7b783          	ld	a5,-1748(a5) # ffffffffc020d4b8 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0201b94:	0000c697          	auipc	a3,0xc
ffffffffc0201b98:	92c6b683          	ld	a3,-1748(a3) # ffffffffc020d4c0 <npage>
    return pa2page(PADDR(kva));
ffffffffc0201b9c:	8d1d                	sub	a0,a0,a5
    if (PPN(pa) >= npage)
ffffffffc0201b9e:	00c55793          	srli	a5,a0,0xc
ffffffffc0201ba2:	06d7f963          	bgeu	a5,a3,ffffffffc0201c14 <kfree+0xce>
    return &pages[PPN(pa) - nbase];
ffffffffc0201ba6:	00004617          	auipc	a2,0x4
ffffffffc0201baa:	f0a63603          	ld	a2,-246(a2) # ffffffffc0205ab0 <nbase>
ffffffffc0201bae:	0000c517          	auipc	a0,0xc
ffffffffc0201bb2:	91a53503          	ld	a0,-1766(a0) # ffffffffc020d4c8 <pages>
	free_pages(kva2page((void *)kva), 1 << order);
ffffffffc0201bb6:	4314                	lw	a3,0(a4)
ffffffffc0201bb8:	8f91                	sub	a5,a5,a2
ffffffffc0201bba:	079a                	slli	a5,a5,0x6
ffffffffc0201bbc:	4585                	li	a1,1
ffffffffc0201bbe:	953e                	add	a0,a0,a5
ffffffffc0201bc0:	00d595bb          	sllw	a1,a1,a3
ffffffffc0201bc4:	e03a                	sd	a4,0(sp)
ffffffffc0201bc6:	0d6000ef          	jal	ffffffffc0201c9c <free_pages>
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201bca:	6502                	ld	a0,0(sp)
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201bcc:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201bce:	45e1                	li	a1,24
}
ffffffffc0201bd0:	6105                	addi	sp,sp,32
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201bd2:	b1b9                	j	ffffffffc0201820 <slob_free>
ffffffffc0201bd4:	e185                	bnez	a1,ffffffffc0201bf4 <kfree+0xae>
}
ffffffffc0201bd6:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201bd8:	1541                	addi	a0,a0,-16
ffffffffc0201bda:	4581                	li	a1,0
}
ffffffffc0201bdc:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201bde:	b189                	j	ffffffffc0201820 <slob_free>
        intr_disable();
ffffffffc0201be0:	e02a                	sd	a0,0(sp)
ffffffffc0201be2:	c93fe0ef          	jal	ffffffffc0200874 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201be6:	0000c797          	auipc	a5,0xc
ffffffffc0201bea:	8b27b783          	ld	a5,-1870(a5) # ffffffffc020d498 <bigblocks>
ffffffffc0201bee:	6502                	ld	a0,0(sp)
        return 1;
ffffffffc0201bf0:	4585                	li	a1,1
ffffffffc0201bf2:	fbb5                	bnez	a5,ffffffffc0201b66 <kfree+0x20>
ffffffffc0201bf4:	e02a                	sd	a0,0(sp)
        intr_enable();
ffffffffc0201bf6:	c79fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201bfa:	6502                	ld	a0,0(sp)
ffffffffc0201bfc:	bfe9                	j	ffffffffc0201bd6 <kfree+0x90>
ffffffffc0201bfe:	e42a                	sd	a0,8(sp)
ffffffffc0201c00:	e03a                	sd	a4,0(sp)
ffffffffc0201c02:	c6dfe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201c06:	6522                	ld	a0,8(sp)
ffffffffc0201c08:	6702                	ld	a4,0(sp)
ffffffffc0201c0a:	bfad                	j	ffffffffc0201b84 <kfree+0x3e>
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c0c:	1541                	addi	a0,a0,-16
ffffffffc0201c0e:	4581                	li	a1,0
ffffffffc0201c10:	b901                	j	ffffffffc0201820 <slob_free>
ffffffffc0201c12:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201c14:	00003617          	auipc	a2,0x3
ffffffffc0201c18:	16c60613          	addi	a2,a2,364 # ffffffffc0204d80 <etext+0xe54>
ffffffffc0201c1c:	06900593          	li	a1,105
ffffffffc0201c20:	00003517          	auipc	a0,0x3
ffffffffc0201c24:	0b850513          	addi	a0,a0,184 # ffffffffc0204cd8 <etext+0xdac>
ffffffffc0201c28:	fdefe0ef          	jal	ffffffffc0200406 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201c2c:	86aa                	mv	a3,a0
ffffffffc0201c2e:	00003617          	auipc	a2,0x3
ffffffffc0201c32:	12a60613          	addi	a2,a2,298 # ffffffffc0204d58 <etext+0xe2c>
ffffffffc0201c36:	07700593          	li	a1,119
ffffffffc0201c3a:	00003517          	auipc	a0,0x3
ffffffffc0201c3e:	09e50513          	addi	a0,a0,158 # ffffffffc0204cd8 <etext+0xdac>
ffffffffc0201c42:	fc4fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201c46 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201c46:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201c48:	00003617          	auipc	a2,0x3
ffffffffc0201c4c:	13860613          	addi	a2,a2,312 # ffffffffc0204d80 <etext+0xe54>
ffffffffc0201c50:	06900593          	li	a1,105
ffffffffc0201c54:	00003517          	auipc	a0,0x3
ffffffffc0201c58:	08450513          	addi	a0,a0,132 # ffffffffc0204cd8 <etext+0xdac>
pa2page(uintptr_t pa)
ffffffffc0201c5c:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201c5e:	fa8fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201c62 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c62:	100027f3          	csrr	a5,sstatus
ffffffffc0201c66:	8b89                	andi	a5,a5,2
ffffffffc0201c68:	e799                	bnez	a5,ffffffffc0201c76 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201c6a:	0000c797          	auipc	a5,0xc
ffffffffc0201c6e:	8367b783          	ld	a5,-1994(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201c72:	6f9c                	ld	a5,24(a5)
ffffffffc0201c74:	8782                	jr	a5
{
ffffffffc0201c76:	1101                	addi	sp,sp,-32
ffffffffc0201c78:	ec06                	sd	ra,24(sp)
ffffffffc0201c7a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201c7c:	bf9fe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201c80:	0000c797          	auipc	a5,0xc
ffffffffc0201c84:	8207b783          	ld	a5,-2016(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201c88:	6522                	ld	a0,8(sp)
ffffffffc0201c8a:	6f9c                	ld	a5,24(a5)
ffffffffc0201c8c:	9782                	jalr	a5
ffffffffc0201c8e:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201c90:	bdffe0ef          	jal	ffffffffc020086e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201c94:	60e2                	ld	ra,24(sp)
ffffffffc0201c96:	6522                	ld	a0,8(sp)
ffffffffc0201c98:	6105                	addi	sp,sp,32
ffffffffc0201c9a:	8082                	ret

ffffffffc0201c9c <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c9c:	100027f3          	csrr	a5,sstatus
ffffffffc0201ca0:	8b89                	andi	a5,a5,2
ffffffffc0201ca2:	e799                	bnez	a5,ffffffffc0201cb0 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201ca4:	0000b797          	auipc	a5,0xb
ffffffffc0201ca8:	7fc7b783          	ld	a5,2044(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201cac:	739c                	ld	a5,32(a5)
ffffffffc0201cae:	8782                	jr	a5
{
ffffffffc0201cb0:	1101                	addi	sp,sp,-32
ffffffffc0201cb2:	ec06                	sd	ra,24(sp)
ffffffffc0201cb4:	e42e                	sd	a1,8(sp)
ffffffffc0201cb6:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0201cb8:	bbdfe0ef          	jal	ffffffffc0200874 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201cbc:	0000b797          	auipc	a5,0xb
ffffffffc0201cc0:	7e47b783          	ld	a5,2020(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201cc4:	65a2                	ld	a1,8(sp)
ffffffffc0201cc6:	6502                	ld	a0,0(sp)
ffffffffc0201cc8:	739c                	ld	a5,32(a5)
ffffffffc0201cca:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201ccc:	60e2                	ld	ra,24(sp)
ffffffffc0201cce:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201cd0:	b9ffe06f          	j	ffffffffc020086e <intr_enable>

ffffffffc0201cd4 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201cd4:	100027f3          	csrr	a5,sstatus
ffffffffc0201cd8:	8b89                	andi	a5,a5,2
ffffffffc0201cda:	e799                	bnez	a5,ffffffffc0201ce8 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201cdc:	0000b797          	auipc	a5,0xb
ffffffffc0201ce0:	7c47b783          	ld	a5,1988(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201ce4:	779c                	ld	a5,40(a5)
ffffffffc0201ce6:	8782                	jr	a5
{
ffffffffc0201ce8:	1101                	addi	sp,sp,-32
ffffffffc0201cea:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201cec:	b89fe0ef          	jal	ffffffffc0200874 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201cf0:	0000b797          	auipc	a5,0xb
ffffffffc0201cf4:	7b07b783          	ld	a5,1968(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201cf8:	779c                	ld	a5,40(a5)
ffffffffc0201cfa:	9782                	jalr	a5
ffffffffc0201cfc:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201cfe:	b71fe0ef          	jal	ffffffffc020086e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201d02:	60e2                	ld	ra,24(sp)
ffffffffc0201d04:	6522                	ld	a0,8(sp)
ffffffffc0201d06:	6105                	addi	sp,sp,32
ffffffffc0201d08:	8082                	ret

ffffffffc0201d0a <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201d0a:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201d0e:	1ff7f793          	andi	a5,a5,511
ffffffffc0201d12:	078e                	slli	a5,a5,0x3
ffffffffc0201d14:	00f50733          	add	a4,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201d18:	6314                	ld	a3,0(a4)
{
ffffffffc0201d1a:	7139                	addi	sp,sp,-64
ffffffffc0201d1c:	f822                	sd	s0,48(sp)
ffffffffc0201d1e:	f426                	sd	s1,40(sp)
ffffffffc0201d20:	fc06                	sd	ra,56(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201d22:	0016f793          	andi	a5,a3,1
{
ffffffffc0201d26:	842e                	mv	s0,a1
ffffffffc0201d28:	8832                	mv	a6,a2
ffffffffc0201d2a:	0000b497          	auipc	s1,0xb
ffffffffc0201d2e:	79648493          	addi	s1,s1,1942 # ffffffffc020d4c0 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201d32:	ebd1                	bnez	a5,ffffffffc0201dc6 <get_pte+0xbc>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201d34:	16060d63          	beqz	a2,ffffffffc0201eae <get_pte+0x1a4>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d38:	100027f3          	csrr	a5,sstatus
ffffffffc0201d3c:	8b89                	andi	a5,a5,2
ffffffffc0201d3e:	16079e63          	bnez	a5,ffffffffc0201eba <get_pte+0x1b0>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201d42:	0000b797          	auipc	a5,0xb
ffffffffc0201d46:	75e7b783          	ld	a5,1886(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201d4a:	4505                	li	a0,1
ffffffffc0201d4c:	e43a                	sd	a4,8(sp)
ffffffffc0201d4e:	6f9c                	ld	a5,24(a5)
ffffffffc0201d50:	e832                	sd	a2,16(sp)
ffffffffc0201d52:	9782                	jalr	a5
ffffffffc0201d54:	6722                	ld	a4,8(sp)
ffffffffc0201d56:	6842                	ld	a6,16(sp)
ffffffffc0201d58:	87aa                	mv	a5,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201d5a:	14078a63          	beqz	a5,ffffffffc0201eae <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201d5e:	0000b517          	auipc	a0,0xb
ffffffffc0201d62:	76a53503          	ld	a0,1898(a0) # ffffffffc020d4c8 <pages>
ffffffffc0201d66:	000808b7          	lui	a7,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201d6a:	0000b497          	auipc	s1,0xb
ffffffffc0201d6e:	75648493          	addi	s1,s1,1878 # ffffffffc020d4c0 <npage>
ffffffffc0201d72:	40a78533          	sub	a0,a5,a0
ffffffffc0201d76:	8519                	srai	a0,a0,0x6
ffffffffc0201d78:	9546                	add	a0,a0,a7
ffffffffc0201d7a:	6090                	ld	a2,0(s1)
ffffffffc0201d7c:	00c51693          	slli	a3,a0,0xc
    page->ref = val;
ffffffffc0201d80:	4585                	li	a1,1
ffffffffc0201d82:	82b1                	srli	a3,a3,0xc
ffffffffc0201d84:	c38c                	sw	a1,0(a5)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201d86:	0532                	slli	a0,a0,0xc
ffffffffc0201d88:	1ac6f763          	bgeu	a3,a2,ffffffffc0201f36 <get_pte+0x22c>
ffffffffc0201d8c:	0000b697          	auipc	a3,0xb
ffffffffc0201d90:	72c6b683          	ld	a3,1836(a3) # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0201d94:	6605                	lui	a2,0x1
ffffffffc0201d96:	4581                	li	a1,0
ffffffffc0201d98:	9536                	add	a0,a0,a3
ffffffffc0201d9a:	ec42                	sd	a6,24(sp)
ffffffffc0201d9c:	e83e                	sd	a5,16(sp)
ffffffffc0201d9e:	e43a                	sd	a4,8(sp)
ffffffffc0201da0:	13e020ef          	jal	ffffffffc0203ede <memset>
    return page - pages + nbase;
ffffffffc0201da4:	0000b697          	auipc	a3,0xb
ffffffffc0201da8:	7246b683          	ld	a3,1828(a3) # ffffffffc020d4c8 <pages>
ffffffffc0201dac:	67c2                	ld	a5,16(sp)
ffffffffc0201dae:	000808b7          	lui	a7,0x80
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201db2:	6722                	ld	a4,8(sp)
ffffffffc0201db4:	40d786b3          	sub	a3,a5,a3
ffffffffc0201db8:	8699                	srai	a3,a3,0x6
ffffffffc0201dba:	96c6                	add	a3,a3,a7
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201dbc:	06aa                	slli	a3,a3,0xa
ffffffffc0201dbe:	6862                	ld	a6,24(sp)
ffffffffc0201dc0:	0116e693          	ori	a3,a3,17
ffffffffc0201dc4:	e314                	sd	a3,0(a4)
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201dc6:	c006f693          	andi	a3,a3,-1024
ffffffffc0201dca:	6098                	ld	a4,0(s1)
ffffffffc0201dcc:	068a                	slli	a3,a3,0x2
ffffffffc0201dce:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201dd2:	14e7f663          	bgeu	a5,a4,ffffffffc0201f1e <get_pte+0x214>
ffffffffc0201dd6:	0000b897          	auipc	a7,0xb
ffffffffc0201dda:	6e288893          	addi	a7,a7,1762 # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0201dde:	0008b603          	ld	a2,0(a7)
ffffffffc0201de2:	01545793          	srli	a5,s0,0x15
ffffffffc0201de6:	1ff7f793          	andi	a5,a5,511
ffffffffc0201dea:	96b2                	add	a3,a3,a2
ffffffffc0201dec:	078e                	slli	a5,a5,0x3
ffffffffc0201dee:	97b6                	add	a5,a5,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201df0:	6394                	ld	a3,0(a5)
ffffffffc0201df2:	0016f613          	andi	a2,a3,1
ffffffffc0201df6:	e659                	bnez	a2,ffffffffc0201e84 <get_pte+0x17a>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201df8:	0a080b63          	beqz	a6,ffffffffc0201eae <get_pte+0x1a4>
ffffffffc0201dfc:	10002773          	csrr	a4,sstatus
ffffffffc0201e00:	8b09                	andi	a4,a4,2
ffffffffc0201e02:	ef71                	bnez	a4,ffffffffc0201ede <get_pte+0x1d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e04:	0000b717          	auipc	a4,0xb
ffffffffc0201e08:	69c73703          	ld	a4,1692(a4) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201e0c:	4505                	li	a0,1
ffffffffc0201e0e:	e43e                	sd	a5,8(sp)
ffffffffc0201e10:	6f18                	ld	a4,24(a4)
ffffffffc0201e12:	9702                	jalr	a4
ffffffffc0201e14:	67a2                	ld	a5,8(sp)
ffffffffc0201e16:	872a                	mv	a4,a0
ffffffffc0201e18:	0000b897          	auipc	a7,0xb
ffffffffc0201e1c:	6a088893          	addi	a7,a7,1696 # ffffffffc020d4b8 <va_pa_offset>
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e20:	c759                	beqz	a4,ffffffffc0201eae <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201e22:	0000b697          	auipc	a3,0xb
ffffffffc0201e26:	6a66b683          	ld	a3,1702(a3) # ffffffffc020d4c8 <pages>
ffffffffc0201e2a:	00080837          	lui	a6,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201e2e:	608c                	ld	a1,0(s1)
ffffffffc0201e30:	40d706b3          	sub	a3,a4,a3
ffffffffc0201e34:	8699                	srai	a3,a3,0x6
ffffffffc0201e36:	96c2                	add	a3,a3,a6
ffffffffc0201e38:	00c69613          	slli	a2,a3,0xc
    page->ref = val;
ffffffffc0201e3c:	4505                	li	a0,1
ffffffffc0201e3e:	8231                	srli	a2,a2,0xc
ffffffffc0201e40:	c308                	sw	a0,0(a4)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201e42:	06b2                	slli	a3,a3,0xc
ffffffffc0201e44:	10b67663          	bgeu	a2,a1,ffffffffc0201f50 <get_pte+0x246>
ffffffffc0201e48:	0008b503          	ld	a0,0(a7)
ffffffffc0201e4c:	6605                	lui	a2,0x1
ffffffffc0201e4e:	4581                	li	a1,0
ffffffffc0201e50:	9536                	add	a0,a0,a3
ffffffffc0201e52:	e83a                	sd	a4,16(sp)
ffffffffc0201e54:	e43e                	sd	a5,8(sp)
ffffffffc0201e56:	088020ef          	jal	ffffffffc0203ede <memset>
    return page - pages + nbase;
ffffffffc0201e5a:	0000b697          	auipc	a3,0xb
ffffffffc0201e5e:	66e6b683          	ld	a3,1646(a3) # ffffffffc020d4c8 <pages>
ffffffffc0201e62:	6742                	ld	a4,16(sp)
ffffffffc0201e64:	00080837          	lui	a6,0x80
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201e68:	67a2                	ld	a5,8(sp)
ffffffffc0201e6a:	40d706b3          	sub	a3,a4,a3
ffffffffc0201e6e:	8699                	srai	a3,a3,0x6
ffffffffc0201e70:	96c2                	add	a3,a3,a6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201e72:	06aa                	slli	a3,a3,0xa
ffffffffc0201e74:	0116e693          	ori	a3,a3,17
ffffffffc0201e78:	e394                	sd	a3,0(a5)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201e7a:	6098                	ld	a4,0(s1)
ffffffffc0201e7c:	0000b897          	auipc	a7,0xb
ffffffffc0201e80:	63c88893          	addi	a7,a7,1596 # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0201e84:	c006f693          	andi	a3,a3,-1024
ffffffffc0201e88:	068a                	slli	a3,a3,0x2
ffffffffc0201e8a:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201e8e:	06e7fc63          	bgeu	a5,a4,ffffffffc0201f06 <get_pte+0x1fc>
ffffffffc0201e92:	0008b783          	ld	a5,0(a7)
ffffffffc0201e96:	8031                	srli	s0,s0,0xc
ffffffffc0201e98:	1ff47413          	andi	s0,s0,511
ffffffffc0201e9c:	040e                	slli	s0,s0,0x3
ffffffffc0201e9e:	96be                	add	a3,a3,a5
}
ffffffffc0201ea0:	70e2                	ld	ra,56(sp)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201ea2:	00868533          	add	a0,a3,s0
}
ffffffffc0201ea6:	7442                	ld	s0,48(sp)
ffffffffc0201ea8:	74a2                	ld	s1,40(sp)
ffffffffc0201eaa:	6121                	addi	sp,sp,64
ffffffffc0201eac:	8082                	ret
ffffffffc0201eae:	70e2                	ld	ra,56(sp)
ffffffffc0201eb0:	7442                	ld	s0,48(sp)
ffffffffc0201eb2:	74a2                	ld	s1,40(sp)
            return NULL;
ffffffffc0201eb4:	4501                	li	a0,0
}
ffffffffc0201eb6:	6121                	addi	sp,sp,64
ffffffffc0201eb8:	8082                	ret
        intr_disable();
ffffffffc0201eba:	e83a                	sd	a4,16(sp)
ffffffffc0201ebc:	ec32                	sd	a2,24(sp)
ffffffffc0201ebe:	9b7fe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ec2:	0000b797          	auipc	a5,0xb
ffffffffc0201ec6:	5de7b783          	ld	a5,1502(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201eca:	4505                	li	a0,1
ffffffffc0201ecc:	6f9c                	ld	a5,24(a5)
ffffffffc0201ece:	9782                	jalr	a5
ffffffffc0201ed0:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201ed2:	99dfe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201ed6:	6862                	ld	a6,24(sp)
ffffffffc0201ed8:	6742                	ld	a4,16(sp)
ffffffffc0201eda:	67a2                	ld	a5,8(sp)
ffffffffc0201edc:	bdbd                	j	ffffffffc0201d5a <get_pte+0x50>
        intr_disable();
ffffffffc0201ede:	e83e                	sd	a5,16(sp)
ffffffffc0201ee0:	995fe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc0201ee4:	0000b717          	auipc	a4,0xb
ffffffffc0201ee8:	5bc73703          	ld	a4,1468(a4) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201eec:	4505                	li	a0,1
ffffffffc0201eee:	6f18                	ld	a4,24(a4)
ffffffffc0201ef0:	9702                	jalr	a4
ffffffffc0201ef2:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201ef4:	97bfe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201ef8:	6722                	ld	a4,8(sp)
ffffffffc0201efa:	67c2                	ld	a5,16(sp)
ffffffffc0201efc:	0000b897          	auipc	a7,0xb
ffffffffc0201f00:	5bc88893          	addi	a7,a7,1468 # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0201f04:	bf31                	j	ffffffffc0201e20 <get_pte+0x116>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201f06:	00003617          	auipc	a2,0x3
ffffffffc0201f0a:	daa60613          	addi	a2,a2,-598 # ffffffffc0204cb0 <etext+0xd84>
ffffffffc0201f0e:	0fb00593          	li	a1,251
ffffffffc0201f12:	00003517          	auipc	a0,0x3
ffffffffc0201f16:	e8e50513          	addi	a0,a0,-370 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0201f1a:	cecfe0ef          	jal	ffffffffc0200406 <__panic>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201f1e:	00003617          	auipc	a2,0x3
ffffffffc0201f22:	d9260613          	addi	a2,a2,-622 # ffffffffc0204cb0 <etext+0xd84>
ffffffffc0201f26:	0ee00593          	li	a1,238
ffffffffc0201f2a:	00003517          	auipc	a0,0x3
ffffffffc0201f2e:	e7650513          	addi	a0,a0,-394 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0201f32:	cd4fe0ef          	jal	ffffffffc0200406 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f36:	86aa                	mv	a3,a0
ffffffffc0201f38:	00003617          	auipc	a2,0x3
ffffffffc0201f3c:	d7860613          	addi	a2,a2,-648 # ffffffffc0204cb0 <etext+0xd84>
ffffffffc0201f40:	0eb00593          	li	a1,235
ffffffffc0201f44:	00003517          	auipc	a0,0x3
ffffffffc0201f48:	e5c50513          	addi	a0,a0,-420 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0201f4c:	cbafe0ef          	jal	ffffffffc0200406 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f50:	00003617          	auipc	a2,0x3
ffffffffc0201f54:	d6060613          	addi	a2,a2,-672 # ffffffffc0204cb0 <etext+0xd84>
ffffffffc0201f58:	0f800593          	li	a1,248
ffffffffc0201f5c:	00003517          	auipc	a0,0x3
ffffffffc0201f60:	e4450513          	addi	a0,a0,-444 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0201f64:	ca2fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201f68 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0201f68:	1141                	addi	sp,sp,-16
ffffffffc0201f6a:	e022                	sd	s0,0(sp)
ffffffffc0201f6c:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f6e:	4601                	li	a2,0
{
ffffffffc0201f70:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f72:	d99ff0ef          	jal	ffffffffc0201d0a <get_pte>
    if (ptep_store != NULL)
ffffffffc0201f76:	c011                	beqz	s0,ffffffffc0201f7a <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0201f78:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f7a:	c511                	beqz	a0,ffffffffc0201f86 <get_page+0x1e>
ffffffffc0201f7c:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201f7e:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f80:	0017f713          	andi	a4,a5,1
ffffffffc0201f84:	e709                	bnez	a4,ffffffffc0201f8e <get_page+0x26>
}
ffffffffc0201f86:	60a2                	ld	ra,8(sp)
ffffffffc0201f88:	6402                	ld	s0,0(sp)
ffffffffc0201f8a:	0141                	addi	sp,sp,16
ffffffffc0201f8c:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0201f8e:	0000b717          	auipc	a4,0xb
ffffffffc0201f92:	53273703          	ld	a4,1330(a4) # ffffffffc020d4c0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0201f96:	078a                	slli	a5,a5,0x2
ffffffffc0201f98:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201f9a:	00e7ff63          	bgeu	a5,a4,ffffffffc0201fb8 <get_page+0x50>
    return &pages[PPN(pa) - nbase];
ffffffffc0201f9e:	0000b517          	auipc	a0,0xb
ffffffffc0201fa2:	52a53503          	ld	a0,1322(a0) # ffffffffc020d4c8 <pages>
ffffffffc0201fa6:	60a2                	ld	ra,8(sp)
ffffffffc0201fa8:	6402                	ld	s0,0(sp)
ffffffffc0201faa:	079a                	slli	a5,a5,0x6
ffffffffc0201fac:	fe000737          	lui	a4,0xfe000
ffffffffc0201fb0:	97ba                	add	a5,a5,a4
ffffffffc0201fb2:	953e                	add	a0,a0,a5
ffffffffc0201fb4:	0141                	addi	sp,sp,16
ffffffffc0201fb6:	8082                	ret
ffffffffc0201fb8:	c8fff0ef          	jal	ffffffffc0201c46 <pa2page.part.0>

ffffffffc0201fbc <page_remove>:
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la)
{
ffffffffc0201fbc:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201fbe:	4601                	li	a2,0
{
ffffffffc0201fc0:	e822                	sd	s0,16(sp)
ffffffffc0201fc2:	ec06                	sd	ra,24(sp)
ffffffffc0201fc4:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201fc6:	d45ff0ef          	jal	ffffffffc0201d0a <get_pte>
    if (ptep != NULL)
ffffffffc0201fca:	c511                	beqz	a0,ffffffffc0201fd6 <page_remove+0x1a>
    if (*ptep & PTE_V)
ffffffffc0201fcc:	6118                	ld	a4,0(a0)
ffffffffc0201fce:	87aa                	mv	a5,a0
ffffffffc0201fd0:	00177693          	andi	a3,a4,1
ffffffffc0201fd4:	e689                	bnez	a3,ffffffffc0201fde <page_remove+0x22>
    {
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0201fd6:	60e2                	ld	ra,24(sp)
ffffffffc0201fd8:	6442                	ld	s0,16(sp)
ffffffffc0201fda:	6105                	addi	sp,sp,32
ffffffffc0201fdc:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0201fde:	0000b697          	auipc	a3,0xb
ffffffffc0201fe2:	4e26b683          	ld	a3,1250(a3) # ffffffffc020d4c0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0201fe6:	070a                	slli	a4,a4,0x2
ffffffffc0201fe8:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0201fea:	06d77563          	bgeu	a4,a3,ffffffffc0202054 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0201fee:	0000b517          	auipc	a0,0xb
ffffffffc0201ff2:	4da53503          	ld	a0,1242(a0) # ffffffffc020d4c8 <pages>
ffffffffc0201ff6:	071a                	slli	a4,a4,0x6
ffffffffc0201ff8:	fe0006b7          	lui	a3,0xfe000
ffffffffc0201ffc:	9736                	add	a4,a4,a3
ffffffffc0201ffe:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc0202000:	4118                	lw	a4,0(a0)
ffffffffc0202002:	377d                	addiw	a4,a4,-1 # fffffffffdffffff <end+0x3ddf2b07>
ffffffffc0202004:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202006:	cb09                	beqz	a4,ffffffffc0202018 <page_remove+0x5c>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0202008:	0007b023          	sd	zero,0(a5)
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020200c:	12040073          	sfence.vma	s0
}
ffffffffc0202010:	60e2                	ld	ra,24(sp)
ffffffffc0202012:	6442                	ld	s0,16(sp)
ffffffffc0202014:	6105                	addi	sp,sp,32
ffffffffc0202016:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202018:	10002773          	csrr	a4,sstatus
ffffffffc020201c:	8b09                	andi	a4,a4,2
ffffffffc020201e:	eb19                	bnez	a4,ffffffffc0202034 <page_remove+0x78>
        pmm_manager->free_pages(base, n);
ffffffffc0202020:	0000b717          	auipc	a4,0xb
ffffffffc0202024:	48073703          	ld	a4,1152(a4) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0202028:	4585                	li	a1,1
ffffffffc020202a:	e03e                	sd	a5,0(sp)
ffffffffc020202c:	7318                	ld	a4,32(a4)
ffffffffc020202e:	9702                	jalr	a4
    if (flag) {
ffffffffc0202030:	6782                	ld	a5,0(sp)
ffffffffc0202032:	bfd9                	j	ffffffffc0202008 <page_remove+0x4c>
        intr_disable();
ffffffffc0202034:	e43e                	sd	a5,8(sp)
ffffffffc0202036:	e02a                	sd	a0,0(sp)
ffffffffc0202038:	83dfe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc020203c:	0000b717          	auipc	a4,0xb
ffffffffc0202040:	46473703          	ld	a4,1124(a4) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0202044:	6502                	ld	a0,0(sp)
ffffffffc0202046:	4585                	li	a1,1
ffffffffc0202048:	7318                	ld	a4,32(a4)
ffffffffc020204a:	9702                	jalr	a4
        intr_enable();
ffffffffc020204c:	823fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202050:	67a2                	ld	a5,8(sp)
ffffffffc0202052:	bf5d                	j	ffffffffc0202008 <page_remove+0x4c>
ffffffffc0202054:	bf3ff0ef          	jal	ffffffffc0201c46 <pa2page.part.0>

ffffffffc0202058 <page_insert>:
{
ffffffffc0202058:	7139                	addi	sp,sp,-64
ffffffffc020205a:	f426                	sd	s1,40(sp)
ffffffffc020205c:	84b2                	mv	s1,a2
ffffffffc020205e:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202060:	4605                	li	a2,1
{
ffffffffc0202062:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202064:	85a6                	mv	a1,s1
{
ffffffffc0202066:	fc06                	sd	ra,56(sp)
ffffffffc0202068:	e436                	sd	a3,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020206a:	ca1ff0ef          	jal	ffffffffc0201d0a <get_pte>
    if (ptep == NULL)
ffffffffc020206e:	cd61                	beqz	a0,ffffffffc0202146 <page_insert+0xee>
    page->ref += 1;
ffffffffc0202070:	400c                	lw	a1,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202072:	611c                	ld	a5,0(a0)
ffffffffc0202074:	66a2                	ld	a3,8(sp)
ffffffffc0202076:	0015861b          	addiw	a2,a1,1 # 1001 <kern_entry-0xffffffffc01fefff>
ffffffffc020207a:	c010                	sw	a2,0(s0)
ffffffffc020207c:	0017f613          	andi	a2,a5,1
ffffffffc0202080:	872a                	mv	a4,a0
ffffffffc0202082:	e61d                	bnez	a2,ffffffffc02020b0 <page_insert+0x58>
    return &pages[PPN(pa) - nbase];
ffffffffc0202084:	0000b617          	auipc	a2,0xb
ffffffffc0202088:	44463603          	ld	a2,1092(a2) # ffffffffc020d4c8 <pages>
    return page - pages + nbase;
ffffffffc020208c:	8c11                	sub	s0,s0,a2
ffffffffc020208e:	8419                	srai	s0,s0,0x6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202090:	200007b7          	lui	a5,0x20000
ffffffffc0202094:	042a                	slli	s0,s0,0xa
ffffffffc0202096:	943e                	add	s0,s0,a5
ffffffffc0202098:	8ec1                	or	a3,a3,s0
ffffffffc020209a:	0016e693          	ori	a3,a3,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc020209e:	e314                	sd	a3,0(a4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02020a0:	12048073          	sfence.vma	s1
    return 0;
ffffffffc02020a4:	4501                	li	a0,0
}
ffffffffc02020a6:	70e2                	ld	ra,56(sp)
ffffffffc02020a8:	7442                	ld	s0,48(sp)
ffffffffc02020aa:	74a2                	ld	s1,40(sp)
ffffffffc02020ac:	6121                	addi	sp,sp,64
ffffffffc02020ae:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02020b0:	0000b617          	auipc	a2,0xb
ffffffffc02020b4:	41063603          	ld	a2,1040(a2) # ffffffffc020d4c0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02020b8:	078a                	slli	a5,a5,0x2
ffffffffc02020ba:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02020bc:	08c7f763          	bgeu	a5,a2,ffffffffc020214a <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02020c0:	0000b617          	auipc	a2,0xb
ffffffffc02020c4:	40863603          	ld	a2,1032(a2) # ffffffffc020d4c8 <pages>
ffffffffc02020c8:	fe000537          	lui	a0,0xfe000
ffffffffc02020cc:	079a                	slli	a5,a5,0x6
ffffffffc02020ce:	97aa                	add	a5,a5,a0
ffffffffc02020d0:	00f60533          	add	a0,a2,a5
        if (p == page)
ffffffffc02020d4:	00a40963          	beq	s0,a0,ffffffffc02020e6 <page_insert+0x8e>
    page->ref -= 1;
ffffffffc02020d8:	411c                	lw	a5,0(a0)
ffffffffc02020da:	37fd                	addiw	a5,a5,-1 # 1fffffff <kern_entry-0xffffffffa0200001>
ffffffffc02020dc:	c11c                	sw	a5,0(a0)
        if (page_ref(page) ==
ffffffffc02020de:	c791                	beqz	a5,ffffffffc02020ea <page_insert+0x92>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02020e0:	12048073          	sfence.vma	s1
}
ffffffffc02020e4:	b765                	j	ffffffffc020208c <page_insert+0x34>
ffffffffc02020e6:	c00c                	sw	a1,0(s0)
    return page->ref;
ffffffffc02020e8:	b755                	j	ffffffffc020208c <page_insert+0x34>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02020ea:	100027f3          	csrr	a5,sstatus
ffffffffc02020ee:	8b89                	andi	a5,a5,2
ffffffffc02020f0:	e39d                	bnez	a5,ffffffffc0202116 <page_insert+0xbe>
        pmm_manager->free_pages(base, n);
ffffffffc02020f2:	0000b797          	auipc	a5,0xb
ffffffffc02020f6:	3ae7b783          	ld	a5,942(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc02020fa:	4585                	li	a1,1
ffffffffc02020fc:	e83a                	sd	a4,16(sp)
ffffffffc02020fe:	739c                	ld	a5,32(a5)
ffffffffc0202100:	e436                	sd	a3,8(sp)
ffffffffc0202102:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202104:	0000b617          	auipc	a2,0xb
ffffffffc0202108:	3c463603          	ld	a2,964(a2) # ffffffffc020d4c8 <pages>
ffffffffc020210c:	66a2                	ld	a3,8(sp)
ffffffffc020210e:	6742                	ld	a4,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202110:	12048073          	sfence.vma	s1
ffffffffc0202114:	bfa5                	j	ffffffffc020208c <page_insert+0x34>
        intr_disable();
ffffffffc0202116:	ec3a                	sd	a4,24(sp)
ffffffffc0202118:	e836                	sd	a3,16(sp)
ffffffffc020211a:	e42a                	sd	a0,8(sp)
ffffffffc020211c:	f58fe0ef          	jal	ffffffffc0200874 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202120:	0000b797          	auipc	a5,0xb
ffffffffc0202124:	3807b783          	ld	a5,896(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0202128:	6522                	ld	a0,8(sp)
ffffffffc020212a:	4585                	li	a1,1
ffffffffc020212c:	739c                	ld	a5,32(a5)
ffffffffc020212e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202130:	f3efe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202134:	0000b617          	auipc	a2,0xb
ffffffffc0202138:	39463603          	ld	a2,916(a2) # ffffffffc020d4c8 <pages>
ffffffffc020213c:	6762                	ld	a4,24(sp)
ffffffffc020213e:	66c2                	ld	a3,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202140:	12048073          	sfence.vma	s1
ffffffffc0202144:	b7a1                	j	ffffffffc020208c <page_insert+0x34>
        return -E_NO_MEM;
ffffffffc0202146:	5571                	li	a0,-4
ffffffffc0202148:	bfb9                	j	ffffffffc02020a6 <page_insert+0x4e>
ffffffffc020214a:	afdff0ef          	jal	ffffffffc0201c46 <pa2page.part.0>

ffffffffc020214e <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020214e:	00003797          	auipc	a5,0x3
ffffffffc0202152:	79a78793          	addi	a5,a5,1946 # ffffffffc02058e8 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202156:	638c                	ld	a1,0(a5)
{
ffffffffc0202158:	7159                	addi	sp,sp,-112
ffffffffc020215a:	f486                	sd	ra,104(sp)
ffffffffc020215c:	e8ca                	sd	s2,80(sp)
ffffffffc020215e:	e4ce                	sd	s3,72(sp)
ffffffffc0202160:	f85a                	sd	s6,48(sp)
ffffffffc0202162:	f0a2                	sd	s0,96(sp)
ffffffffc0202164:	eca6                	sd	s1,88(sp)
ffffffffc0202166:	e0d2                	sd	s4,64(sp)
ffffffffc0202168:	fc56                	sd	s5,56(sp)
ffffffffc020216a:	f45e                	sd	s7,40(sp)
ffffffffc020216c:	f062                	sd	s8,32(sp)
ffffffffc020216e:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202170:	0000bb17          	auipc	s6,0xb
ffffffffc0202174:	330b0b13          	addi	s6,s6,816 # ffffffffc020d4a0 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202178:	00003517          	auipc	a0,0x3
ffffffffc020217c:	c3850513          	addi	a0,a0,-968 # ffffffffc0204db0 <etext+0xe84>
    pmm_manager = &default_pmm_manager;
ffffffffc0202180:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202184:	810fe0ef          	jal	ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc0202188:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020218c:	0000b997          	auipc	s3,0xb
ffffffffc0202190:	32c98993          	addi	s3,s3,812 # ffffffffc020d4b8 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202194:	679c                	ld	a5,8(a5)
ffffffffc0202196:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202198:	57f5                	li	a5,-3
ffffffffc020219a:	07fa                	slli	a5,a5,0x1e
ffffffffc020219c:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02021a0:	ebafe0ef          	jal	ffffffffc020085a <get_memory_base>
ffffffffc02021a4:	892a                	mv	s2,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02021a6:	ebefe0ef          	jal	ffffffffc0200864 <get_memory_size>
    if (mem_size == 0) {
ffffffffc02021aa:	70050e63          	beqz	a0,ffffffffc02028c6 <pmm_init+0x778>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02021ae:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02021b0:	00003517          	auipc	a0,0x3
ffffffffc02021b4:	c3850513          	addi	a0,a0,-968 # ffffffffc0204de8 <etext+0xebc>
ffffffffc02021b8:	fddfd0ef          	jal	ffffffffc0200194 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02021bc:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02021c0:	864a                	mv	a2,s2
ffffffffc02021c2:	85a6                	mv	a1,s1
ffffffffc02021c4:	fff40693          	addi	a3,s0,-1
ffffffffc02021c8:	00003517          	auipc	a0,0x3
ffffffffc02021cc:	c3850513          	addi	a0,a0,-968 # ffffffffc0204e00 <etext+0xed4>
ffffffffc02021d0:	fc5fd0ef          	jal	ffffffffc0200194 <cprintf>
    if (maxpa > KERNTOP)
ffffffffc02021d4:	c80007b7          	lui	a5,0xc8000
ffffffffc02021d8:	8522                	mv	a0,s0
ffffffffc02021da:	5287ed63          	bltu	a5,s0,ffffffffc0202714 <pmm_init+0x5c6>
ffffffffc02021de:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02021e0:	0000c617          	auipc	a2,0xc
ffffffffc02021e4:	31760613          	addi	a2,a2,791 # ffffffffc020e4f7 <end+0xfff>
ffffffffc02021e8:	8e7d                	and	a2,a2,a5
    npage = maxpa / PGSIZE;
ffffffffc02021ea:	8131                	srli	a0,a0,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02021ec:	0000bb97          	auipc	s7,0xb
ffffffffc02021f0:	2dcb8b93          	addi	s7,s7,732 # ffffffffc020d4c8 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02021f4:	0000b497          	auipc	s1,0xb
ffffffffc02021f8:	2cc48493          	addi	s1,s1,716 # ffffffffc020d4c0 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02021fc:	00cbb023          	sd	a2,0(s7)
    npage = maxpa / PGSIZE;
ffffffffc0202200:	e088                	sd	a0,0(s1)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202202:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202206:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202208:	02f50763          	beq	a0,a5,ffffffffc0202236 <pmm_init+0xe8>
ffffffffc020220c:	4701                	li	a4,0
ffffffffc020220e:	4585                	li	a1,1
ffffffffc0202210:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc0202214:	00671793          	slli	a5,a4,0x6
ffffffffc0202218:	97b2                	add	a5,a5,a2
ffffffffc020221a:	07a1                	addi	a5,a5,8 # 80008 <kern_entry-0xffffffffc017fff8>
ffffffffc020221c:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202220:	6088                	ld	a0,0(s1)
ffffffffc0202222:	0705                	addi	a4,a4,1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202224:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202228:	00d507b3          	add	a5,a0,a3
ffffffffc020222c:	fef764e3          	bltu	a4,a5,ffffffffc0202214 <pmm_init+0xc6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202230:	079a                	slli	a5,a5,0x6
ffffffffc0202232:	00f606b3          	add	a3,a2,a5
ffffffffc0202236:	c02007b7          	lui	a5,0xc0200
ffffffffc020223a:	16f6eee3          	bltu	a3,a5,ffffffffc0202bb6 <pmm_init+0xa68>
ffffffffc020223e:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0202242:	77fd                	lui	a5,0xfffff
ffffffffc0202244:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202246:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202248:	4e86ed63          	bltu	a3,s0,ffffffffc0202742 <pmm_init+0x5f4>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc020224c:	00003517          	auipc	a0,0x3
ffffffffc0202250:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0204e28 <etext+0xefc>
ffffffffc0202254:	f41fd0ef          	jal	ffffffffc0200194 <cprintf>
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202258:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020225c:	0000b917          	auipc	s2,0xb
ffffffffc0202260:	25490913          	addi	s2,s2,596 # ffffffffc020d4b0 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202264:	7b9c                	ld	a5,48(a5)
ffffffffc0202266:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202268:	00003517          	auipc	a0,0x3
ffffffffc020226c:	bd850513          	addi	a0,a0,-1064 # ffffffffc0204e40 <etext+0xf14>
ffffffffc0202270:	f25fd0ef          	jal	ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202274:	00006697          	auipc	a3,0x6
ffffffffc0202278:	d8c68693          	addi	a3,a3,-628 # ffffffffc0208000 <boot_page_table_sv39>
ffffffffc020227c:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202280:	c02007b7          	lui	a5,0xc0200
ffffffffc0202284:	2af6eee3          	bltu	a3,a5,ffffffffc0202d40 <pmm_init+0xbf2>
ffffffffc0202288:	0009b783          	ld	a5,0(s3)
ffffffffc020228c:	8e9d                	sub	a3,a3,a5
ffffffffc020228e:	0000b797          	auipc	a5,0xb
ffffffffc0202292:	20d7bd23          	sd	a3,538(a5) # ffffffffc020d4a8 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202296:	100027f3          	csrr	a5,sstatus
ffffffffc020229a:	8b89                	andi	a5,a5,2
ffffffffc020229c:	48079963          	bnez	a5,ffffffffc020272e <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc02022a0:	000b3783          	ld	a5,0(s6)
ffffffffc02022a4:	779c                	ld	a5,40(a5)
ffffffffc02022a6:	9782                	jalr	a5
ffffffffc02022a8:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02022aa:	6098                	ld	a4,0(s1)
ffffffffc02022ac:	c80007b7          	lui	a5,0xc8000
ffffffffc02022b0:	83b1                	srli	a5,a5,0xc
ffffffffc02022b2:	66e7e663          	bltu	a5,a4,ffffffffc020291e <pmm_init+0x7d0>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02022b6:	00093503          	ld	a0,0(s2)
ffffffffc02022ba:	64050263          	beqz	a0,ffffffffc02028fe <pmm_init+0x7b0>
ffffffffc02022be:	03451793          	slli	a5,a0,0x34
ffffffffc02022c2:	62079e63          	bnez	a5,ffffffffc02028fe <pmm_init+0x7b0>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02022c6:	4601                	li	a2,0
ffffffffc02022c8:	4581                	li	a1,0
ffffffffc02022ca:	c9fff0ef          	jal	ffffffffc0201f68 <get_page>
ffffffffc02022ce:	240519e3          	bnez	a0,ffffffffc0202d20 <pmm_init+0xbd2>
ffffffffc02022d2:	100027f3          	csrr	a5,sstatus
ffffffffc02022d6:	8b89                	andi	a5,a5,2
ffffffffc02022d8:	44079063          	bnez	a5,ffffffffc0202718 <pmm_init+0x5ca>
        page = pmm_manager->alloc_pages(n);
ffffffffc02022dc:	000b3783          	ld	a5,0(s6)
ffffffffc02022e0:	4505                	li	a0,1
ffffffffc02022e2:	6f9c                	ld	a5,24(a5)
ffffffffc02022e4:	9782                	jalr	a5
ffffffffc02022e6:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02022e8:	00093503          	ld	a0,0(s2)
ffffffffc02022ec:	4681                	li	a3,0
ffffffffc02022ee:	4601                	li	a2,0
ffffffffc02022f0:	85d2                	mv	a1,s4
ffffffffc02022f2:	d67ff0ef          	jal	ffffffffc0202058 <page_insert>
ffffffffc02022f6:	280511e3          	bnez	a0,ffffffffc0202d78 <pmm_init+0xc2a>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02022fa:	00093503          	ld	a0,0(s2)
ffffffffc02022fe:	4601                	li	a2,0
ffffffffc0202300:	4581                	li	a1,0
ffffffffc0202302:	a09ff0ef          	jal	ffffffffc0201d0a <get_pte>
ffffffffc0202306:	240509e3          	beqz	a0,ffffffffc0202d58 <pmm_init+0xc0a>
    assert(pte2page(*ptep) == p1);
ffffffffc020230a:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc020230c:	0017f713          	andi	a4,a5,1
ffffffffc0202310:	58070f63          	beqz	a4,ffffffffc02028ae <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc0202314:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202316:	078a                	slli	a5,a5,0x2
ffffffffc0202318:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020231a:	58e7f863          	bgeu	a5,a4,ffffffffc02028aa <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc020231e:	000bb683          	ld	a3,0(s7)
ffffffffc0202322:	079a                	slli	a5,a5,0x6
ffffffffc0202324:	fe000637          	lui	a2,0xfe000
ffffffffc0202328:	97b2                	add	a5,a5,a2
ffffffffc020232a:	97b6                	add	a5,a5,a3
ffffffffc020232c:	14fa1ae3          	bne	s4,a5,ffffffffc0202c80 <pmm_init+0xb32>
    assert(page_ref(p1) == 1);
ffffffffc0202330:	000a2683          	lw	a3,0(s4)
ffffffffc0202334:	4785                	li	a5,1
ffffffffc0202336:	12f695e3          	bne	a3,a5,ffffffffc0202c60 <pmm_init+0xb12>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc020233a:	00093503          	ld	a0,0(s2)
ffffffffc020233e:	77fd                	lui	a5,0xfffff
ffffffffc0202340:	6114                	ld	a3,0(a0)
ffffffffc0202342:	068a                	slli	a3,a3,0x2
ffffffffc0202344:	8efd                	and	a3,a3,a5
ffffffffc0202346:	00c6d613          	srli	a2,a3,0xc
ffffffffc020234a:	0ee67fe3          	bgeu	a2,a4,ffffffffc0202c48 <pmm_init+0xafa>
ffffffffc020234e:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202352:	96e2                	add	a3,a3,s8
ffffffffc0202354:	0006ba83          	ld	s5,0(a3)
ffffffffc0202358:	0a8a                	slli	s5,s5,0x2
ffffffffc020235a:	00fafab3          	and	s5,s5,a5
ffffffffc020235e:	00cad793          	srli	a5,s5,0xc
ffffffffc0202362:	0ce7f6e3          	bgeu	a5,a4,ffffffffc0202c2e <pmm_init+0xae0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202366:	4601                	li	a2,0
ffffffffc0202368:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020236a:	9c56                	add	s8,s8,s5
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020236c:	99fff0ef          	jal	ffffffffc0201d0a <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202370:	0c21                	addi	s8,s8,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202372:	05851ee3          	bne	a0,s8,ffffffffc0202bce <pmm_init+0xa80>
ffffffffc0202376:	100027f3          	csrr	a5,sstatus
ffffffffc020237a:	8b89                	andi	a5,a5,2
ffffffffc020237c:	3e079b63          	bnez	a5,ffffffffc0202772 <pmm_init+0x624>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202380:	000b3783          	ld	a5,0(s6)
ffffffffc0202384:	4505                	li	a0,1
ffffffffc0202386:	6f9c                	ld	a5,24(a5)
ffffffffc0202388:	9782                	jalr	a5
ffffffffc020238a:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc020238c:	00093503          	ld	a0,0(s2)
ffffffffc0202390:	46d1                	li	a3,20
ffffffffc0202392:	6605                	lui	a2,0x1
ffffffffc0202394:	85e2                	mv	a1,s8
ffffffffc0202396:	cc3ff0ef          	jal	ffffffffc0202058 <page_insert>
ffffffffc020239a:	06051ae3          	bnez	a0,ffffffffc0202c0e <pmm_init+0xac0>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020239e:	00093503          	ld	a0,0(s2)
ffffffffc02023a2:	4601                	li	a2,0
ffffffffc02023a4:	6585                	lui	a1,0x1
ffffffffc02023a6:	965ff0ef          	jal	ffffffffc0201d0a <get_pte>
ffffffffc02023aa:	040502e3          	beqz	a0,ffffffffc0202bee <pmm_init+0xaa0>
    assert(*ptep & PTE_U);
ffffffffc02023ae:	611c                	ld	a5,0(a0)
ffffffffc02023b0:	0107f713          	andi	a4,a5,16
ffffffffc02023b4:	7e070163          	beqz	a4,ffffffffc0202b96 <pmm_init+0xa48>
    assert(*ptep & PTE_W);
ffffffffc02023b8:	8b91                	andi	a5,a5,4
ffffffffc02023ba:	7a078e63          	beqz	a5,ffffffffc0202b76 <pmm_init+0xa28>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02023be:	00093503          	ld	a0,0(s2)
ffffffffc02023c2:	611c                	ld	a5,0(a0)
ffffffffc02023c4:	8bc1                	andi	a5,a5,16
ffffffffc02023c6:	78078863          	beqz	a5,ffffffffc0202b56 <pmm_init+0xa08>
    assert(page_ref(p2) == 1);
ffffffffc02023ca:	000c2703          	lw	a4,0(s8)
ffffffffc02023ce:	4785                	li	a5,1
ffffffffc02023d0:	76f71363          	bne	a4,a5,ffffffffc0202b36 <pmm_init+0x9e8>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02023d4:	4681                	li	a3,0
ffffffffc02023d6:	6605                	lui	a2,0x1
ffffffffc02023d8:	85d2                	mv	a1,s4
ffffffffc02023da:	c7fff0ef          	jal	ffffffffc0202058 <page_insert>
ffffffffc02023de:	72051c63          	bnez	a0,ffffffffc0202b16 <pmm_init+0x9c8>
    assert(page_ref(p1) == 2);
ffffffffc02023e2:	000a2703          	lw	a4,0(s4)
ffffffffc02023e6:	4789                	li	a5,2
ffffffffc02023e8:	70f71763          	bne	a4,a5,ffffffffc0202af6 <pmm_init+0x9a8>
    assert(page_ref(p2) == 0);
ffffffffc02023ec:	000c2783          	lw	a5,0(s8)
ffffffffc02023f0:	6e079363          	bnez	a5,ffffffffc0202ad6 <pmm_init+0x988>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02023f4:	00093503          	ld	a0,0(s2)
ffffffffc02023f8:	4601                	li	a2,0
ffffffffc02023fa:	6585                	lui	a1,0x1
ffffffffc02023fc:	90fff0ef          	jal	ffffffffc0201d0a <get_pte>
ffffffffc0202400:	6a050b63          	beqz	a0,ffffffffc0202ab6 <pmm_init+0x968>
    assert(pte2page(*ptep) == p1);
ffffffffc0202404:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202406:	00177793          	andi	a5,a4,1
ffffffffc020240a:	4a078263          	beqz	a5,ffffffffc02028ae <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc020240e:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202410:	00271793          	slli	a5,a4,0x2
ffffffffc0202414:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202416:	48d7fa63          	bgeu	a5,a3,ffffffffc02028aa <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc020241a:	000bb683          	ld	a3,0(s7)
ffffffffc020241e:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202422:	97d6                	add	a5,a5,s5
ffffffffc0202424:	079a                	slli	a5,a5,0x6
ffffffffc0202426:	97b6                	add	a5,a5,a3
ffffffffc0202428:	66fa1763          	bne	s4,a5,ffffffffc0202a96 <pmm_init+0x948>
    assert((*ptep & PTE_U) == 0);
ffffffffc020242c:	8b41                	andi	a4,a4,16
ffffffffc020242e:	64071463          	bnez	a4,ffffffffc0202a76 <pmm_init+0x928>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202432:	00093503          	ld	a0,0(s2)
ffffffffc0202436:	4581                	li	a1,0
ffffffffc0202438:	b85ff0ef          	jal	ffffffffc0201fbc <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc020243c:	000a2c83          	lw	s9,0(s4)
ffffffffc0202440:	4785                	li	a5,1
ffffffffc0202442:	60fc9a63          	bne	s9,a5,ffffffffc0202a56 <pmm_init+0x908>
    assert(page_ref(p2) == 0);
ffffffffc0202446:	000c2783          	lw	a5,0(s8)
ffffffffc020244a:	5e079663          	bnez	a5,ffffffffc0202a36 <pmm_init+0x8e8>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc020244e:	00093503          	ld	a0,0(s2)
ffffffffc0202452:	6585                	lui	a1,0x1
ffffffffc0202454:	b69ff0ef          	jal	ffffffffc0201fbc <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202458:	000a2783          	lw	a5,0(s4)
ffffffffc020245c:	52079d63          	bnez	a5,ffffffffc0202996 <pmm_init+0x848>
    assert(page_ref(p2) == 0);
ffffffffc0202460:	000c2783          	lw	a5,0(s8)
ffffffffc0202464:	50079963          	bnez	a5,ffffffffc0202976 <pmm_init+0x828>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202468:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc020246c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020246e:	000a3783          	ld	a5,0(s4)
ffffffffc0202472:	078a                	slli	a5,a5,0x2
ffffffffc0202474:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202476:	42e7fa63          	bgeu	a5,a4,ffffffffc02028aa <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc020247a:	000bb503          	ld	a0,0(s7)
ffffffffc020247e:	97d6                	add	a5,a5,s5
ffffffffc0202480:	079a                	slli	a5,a5,0x6
    return page->ref;
ffffffffc0202482:	00f506b3          	add	a3,a0,a5
ffffffffc0202486:	4294                	lw	a3,0(a3)
ffffffffc0202488:	4d969763          	bne	a3,s9,ffffffffc0202956 <pmm_init+0x808>
    return page - pages + nbase;
ffffffffc020248c:	8799                	srai	a5,a5,0x6
ffffffffc020248e:	00080637          	lui	a2,0x80
ffffffffc0202492:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202494:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202498:	4ae7f363          	bgeu	a5,a4,ffffffffc020293e <pmm_init+0x7f0>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc020249c:	0009b783          	ld	a5,0(s3)
ffffffffc02024a0:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc02024a2:	639c                	ld	a5,0(a5)
ffffffffc02024a4:	078a                	slli	a5,a5,0x2
ffffffffc02024a6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024a8:	40e7f163          	bgeu	a5,a4,ffffffffc02028aa <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc02024ac:	8f91                	sub	a5,a5,a2
ffffffffc02024ae:	079a                	slli	a5,a5,0x6
ffffffffc02024b0:	953e                	add	a0,a0,a5
ffffffffc02024b2:	100027f3          	csrr	a5,sstatus
ffffffffc02024b6:	8b89                	andi	a5,a5,2
ffffffffc02024b8:	30079863          	bnez	a5,ffffffffc02027c8 <pmm_init+0x67a>
        pmm_manager->free_pages(base, n);
ffffffffc02024bc:	000b3783          	ld	a5,0(s6)
ffffffffc02024c0:	4585                	li	a1,1
ffffffffc02024c2:	739c                	ld	a5,32(a5)
ffffffffc02024c4:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02024c6:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc02024ca:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02024cc:	078a                	slli	a5,a5,0x2
ffffffffc02024ce:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024d0:	3ce7fd63          	bgeu	a5,a4,ffffffffc02028aa <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc02024d4:	000bb503          	ld	a0,0(s7)
ffffffffc02024d8:	fe000737          	lui	a4,0xfe000
ffffffffc02024dc:	079a                	slli	a5,a5,0x6
ffffffffc02024de:	97ba                	add	a5,a5,a4
ffffffffc02024e0:	953e                	add	a0,a0,a5
ffffffffc02024e2:	100027f3          	csrr	a5,sstatus
ffffffffc02024e6:	8b89                	andi	a5,a5,2
ffffffffc02024e8:	2c079463          	bnez	a5,ffffffffc02027b0 <pmm_init+0x662>
ffffffffc02024ec:	000b3783          	ld	a5,0(s6)
ffffffffc02024f0:	4585                	li	a1,1
ffffffffc02024f2:	739c                	ld	a5,32(a5)
ffffffffc02024f4:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc02024f6:	00093783          	ld	a5,0(s2)
ffffffffc02024fa:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fdf1b08>
    asm volatile("sfence.vma");
ffffffffc02024fe:	12000073          	sfence.vma
ffffffffc0202502:	100027f3          	csrr	a5,sstatus
ffffffffc0202506:	8b89                	andi	a5,a5,2
ffffffffc0202508:	28079a63          	bnez	a5,ffffffffc020279c <pmm_init+0x64e>
        ret = pmm_manager->nr_free_pages();
ffffffffc020250c:	000b3783          	ld	a5,0(s6)
ffffffffc0202510:	779c                	ld	a5,40(a5)
ffffffffc0202512:	9782                	jalr	a5
ffffffffc0202514:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202516:	4d441063          	bne	s0,s4,ffffffffc02029d6 <pmm_init+0x888>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc020251a:	00003517          	auipc	a0,0x3
ffffffffc020251e:	c7650513          	addi	a0,a0,-906 # ffffffffc0205190 <etext+0x1264>
ffffffffc0202522:	c73fd0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0202526:	100027f3          	csrr	a5,sstatus
ffffffffc020252a:	8b89                	andi	a5,a5,2
ffffffffc020252c:	24079e63          	bnez	a5,ffffffffc0202788 <pmm_init+0x63a>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202530:	000b3783          	ld	a5,0(s6)
ffffffffc0202534:	779c                	ld	a5,40(a5)
ffffffffc0202536:	9782                	jalr	a5
ffffffffc0202538:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc020253a:	609c                	ld	a5,0(s1)
ffffffffc020253c:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202540:	7a7d                	lui	s4,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202542:	00c79713          	slli	a4,a5,0xc
ffffffffc0202546:	6a85                	lui	s5,0x1
ffffffffc0202548:	02e47c63          	bgeu	s0,a4,ffffffffc0202580 <pmm_init+0x432>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020254c:	00c45713          	srli	a4,s0,0xc
ffffffffc0202550:	30f77063          	bgeu	a4,a5,ffffffffc0202850 <pmm_init+0x702>
ffffffffc0202554:	0009b583          	ld	a1,0(s3)
ffffffffc0202558:	00093503          	ld	a0,0(s2)
ffffffffc020255c:	4601                	li	a2,0
ffffffffc020255e:	95a2                	add	a1,a1,s0
ffffffffc0202560:	faaff0ef          	jal	ffffffffc0201d0a <get_pte>
ffffffffc0202564:	32050363          	beqz	a0,ffffffffc020288a <pmm_init+0x73c>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202568:	611c                	ld	a5,0(a0)
ffffffffc020256a:	078a                	slli	a5,a5,0x2
ffffffffc020256c:	0147f7b3          	and	a5,a5,s4
ffffffffc0202570:	2e879d63          	bne	a5,s0,ffffffffc020286a <pmm_init+0x71c>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202574:	609c                	ld	a5,0(s1)
ffffffffc0202576:	9456                	add	s0,s0,s5
ffffffffc0202578:	00c79713          	slli	a4,a5,0xc
ffffffffc020257c:	fce468e3          	bltu	s0,a4,ffffffffc020254c <pmm_init+0x3fe>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202580:	00093783          	ld	a5,0(s2)
ffffffffc0202584:	639c                	ld	a5,0(a5)
ffffffffc0202586:	42079863          	bnez	a5,ffffffffc02029b6 <pmm_init+0x868>
ffffffffc020258a:	100027f3          	csrr	a5,sstatus
ffffffffc020258e:	8b89                	andi	a5,a5,2
ffffffffc0202590:	24079863          	bnez	a5,ffffffffc02027e0 <pmm_init+0x692>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202594:	000b3783          	ld	a5,0(s6)
ffffffffc0202598:	4505                	li	a0,1
ffffffffc020259a:	6f9c                	ld	a5,24(a5)
ffffffffc020259c:	9782                	jalr	a5
ffffffffc020259e:	842a                	mv	s0,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02025a0:	00093503          	ld	a0,0(s2)
ffffffffc02025a4:	4699                	li	a3,6
ffffffffc02025a6:	10000613          	li	a2,256
ffffffffc02025aa:	85a2                	mv	a1,s0
ffffffffc02025ac:	aadff0ef          	jal	ffffffffc0202058 <page_insert>
ffffffffc02025b0:	46051363          	bnez	a0,ffffffffc0202a16 <pmm_init+0x8c8>
    assert(page_ref(p) == 1);
ffffffffc02025b4:	4018                	lw	a4,0(s0)
ffffffffc02025b6:	4785                	li	a5,1
ffffffffc02025b8:	42f71f63          	bne	a4,a5,ffffffffc02029f6 <pmm_init+0x8a8>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02025bc:	00093503          	ld	a0,0(s2)
ffffffffc02025c0:	6605                	lui	a2,0x1
ffffffffc02025c2:	10060613          	addi	a2,a2,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc02025c6:	4699                	li	a3,6
ffffffffc02025c8:	85a2                	mv	a1,s0
ffffffffc02025ca:	a8fff0ef          	jal	ffffffffc0202058 <page_insert>
ffffffffc02025ce:	72051963          	bnez	a0,ffffffffc0202d00 <pmm_init+0xbb2>
    assert(page_ref(p) == 2);
ffffffffc02025d2:	4018                	lw	a4,0(s0)
ffffffffc02025d4:	4789                	li	a5,2
ffffffffc02025d6:	70f71563          	bne	a4,a5,ffffffffc0202ce0 <pmm_init+0xb92>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc02025da:	00003597          	auipc	a1,0x3
ffffffffc02025de:	cfe58593          	addi	a1,a1,-770 # ffffffffc02052d8 <etext+0x13ac>
ffffffffc02025e2:	10000513          	li	a0,256
ffffffffc02025e6:	079010ef          	jal	ffffffffc0203e5e <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02025ea:	6585                	lui	a1,0x1
ffffffffc02025ec:	10058593          	addi	a1,a1,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc02025f0:	10000513          	li	a0,256
ffffffffc02025f4:	07d010ef          	jal	ffffffffc0203e70 <strcmp>
ffffffffc02025f8:	6c051463          	bnez	a0,ffffffffc0202cc0 <pmm_init+0xb72>
    return page - pages + nbase;
ffffffffc02025fc:	000bb683          	ld	a3,0(s7)
ffffffffc0202600:	000807b7          	lui	a5,0x80
    return KADDR(page2pa(page));
ffffffffc0202604:	6098                	ld	a4,0(s1)
    return page - pages + nbase;
ffffffffc0202606:	40d406b3          	sub	a3,s0,a3
ffffffffc020260a:	8699                	srai	a3,a3,0x6
ffffffffc020260c:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc020260e:	00c69793          	slli	a5,a3,0xc
ffffffffc0202612:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202614:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202616:	32e7f463          	bgeu	a5,a4,ffffffffc020293e <pmm_init+0x7f0>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020261a:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc020261e:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202622:	97b6                	add	a5,a5,a3
ffffffffc0202624:	10078023          	sb	zero,256(a5) # 80100 <kern_entry-0xffffffffc017ff00>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202628:	003010ef          	jal	ffffffffc0203e2a <strlen>
ffffffffc020262c:	66051a63          	bnez	a0,ffffffffc0202ca0 <pmm_init+0xb52>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202630:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202634:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202636:	000a3783          	ld	a5,0(s4) # fffffffffffff000 <end+0x3fdf1b08>
ffffffffc020263a:	078a                	slli	a5,a5,0x2
ffffffffc020263c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020263e:	26e7f663          	bgeu	a5,a4,ffffffffc02028aa <pmm_init+0x75c>
    return page2ppn(page) << PGSHIFT;
ffffffffc0202642:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202646:	2ee7fc63          	bgeu	a5,a4,ffffffffc020293e <pmm_init+0x7f0>
ffffffffc020264a:	0009b783          	ld	a5,0(s3)
ffffffffc020264e:	00f689b3          	add	s3,a3,a5
ffffffffc0202652:	100027f3          	csrr	a5,sstatus
ffffffffc0202656:	8b89                	andi	a5,a5,2
ffffffffc0202658:	1e079163          	bnez	a5,ffffffffc020283a <pmm_init+0x6ec>
        pmm_manager->free_pages(base, n);
ffffffffc020265c:	000b3783          	ld	a5,0(s6)
ffffffffc0202660:	8522                	mv	a0,s0
ffffffffc0202662:	4585                	li	a1,1
ffffffffc0202664:	739c                	ld	a5,32(a5)
ffffffffc0202666:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202668:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage)
ffffffffc020266c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020266e:	078a                	slli	a5,a5,0x2
ffffffffc0202670:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202672:	22e7fc63          	bgeu	a5,a4,ffffffffc02028aa <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202676:	000bb503          	ld	a0,0(s7)
ffffffffc020267a:	fe000737          	lui	a4,0xfe000
ffffffffc020267e:	079a                	slli	a5,a5,0x6
ffffffffc0202680:	97ba                	add	a5,a5,a4
ffffffffc0202682:	953e                	add	a0,a0,a5
ffffffffc0202684:	100027f3          	csrr	a5,sstatus
ffffffffc0202688:	8b89                	andi	a5,a5,2
ffffffffc020268a:	18079c63          	bnez	a5,ffffffffc0202822 <pmm_init+0x6d4>
ffffffffc020268e:	000b3783          	ld	a5,0(s6)
ffffffffc0202692:	4585                	li	a1,1
ffffffffc0202694:	739c                	ld	a5,32(a5)
ffffffffc0202696:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202698:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc020269c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020269e:	078a                	slli	a5,a5,0x2
ffffffffc02026a0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02026a2:	20e7f463          	bgeu	a5,a4,ffffffffc02028aa <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc02026a6:	000bb503          	ld	a0,0(s7)
ffffffffc02026aa:	fe000737          	lui	a4,0xfe000
ffffffffc02026ae:	079a                	slli	a5,a5,0x6
ffffffffc02026b0:	97ba                	add	a5,a5,a4
ffffffffc02026b2:	953e                	add	a0,a0,a5
ffffffffc02026b4:	100027f3          	csrr	a5,sstatus
ffffffffc02026b8:	8b89                	andi	a5,a5,2
ffffffffc02026ba:	14079863          	bnez	a5,ffffffffc020280a <pmm_init+0x6bc>
ffffffffc02026be:	000b3783          	ld	a5,0(s6)
ffffffffc02026c2:	4585                	li	a1,1
ffffffffc02026c4:	739c                	ld	a5,32(a5)
ffffffffc02026c6:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc02026c8:	00093783          	ld	a5,0(s2)
ffffffffc02026cc:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc02026d0:	12000073          	sfence.vma
ffffffffc02026d4:	100027f3          	csrr	a5,sstatus
ffffffffc02026d8:	8b89                	andi	a5,a5,2
ffffffffc02026da:	10079e63          	bnez	a5,ffffffffc02027f6 <pmm_init+0x6a8>
        ret = pmm_manager->nr_free_pages();
ffffffffc02026de:	000b3783          	ld	a5,0(s6)
ffffffffc02026e2:	779c                	ld	a5,40(a5)
ffffffffc02026e4:	9782                	jalr	a5
ffffffffc02026e6:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc02026e8:	1e8c1b63          	bne	s8,s0,ffffffffc02028de <pmm_init+0x790>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc02026ec:	00003517          	auipc	a0,0x3
ffffffffc02026f0:	c6450513          	addi	a0,a0,-924 # ffffffffc0205350 <etext+0x1424>
ffffffffc02026f4:	aa1fd0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc02026f8:	7406                	ld	s0,96(sp)
ffffffffc02026fa:	70a6                	ld	ra,104(sp)
ffffffffc02026fc:	64e6                	ld	s1,88(sp)
ffffffffc02026fe:	6946                	ld	s2,80(sp)
ffffffffc0202700:	69a6                	ld	s3,72(sp)
ffffffffc0202702:	6a06                	ld	s4,64(sp)
ffffffffc0202704:	7ae2                	ld	s5,56(sp)
ffffffffc0202706:	7b42                	ld	s6,48(sp)
ffffffffc0202708:	7ba2                	ld	s7,40(sp)
ffffffffc020270a:	7c02                	ld	s8,32(sp)
ffffffffc020270c:	6ce2                	ld	s9,24(sp)
ffffffffc020270e:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202710:	b70ff06f          	j	ffffffffc0201a80 <kmalloc_init>
    if (maxpa > KERNTOP)
ffffffffc0202714:	853e                	mv	a0,a5
ffffffffc0202716:	b4e1                	j	ffffffffc02021de <pmm_init+0x90>
        intr_disable();
ffffffffc0202718:	95cfe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020271c:	000b3783          	ld	a5,0(s6)
ffffffffc0202720:	4505                	li	a0,1
ffffffffc0202722:	6f9c                	ld	a5,24(a5)
ffffffffc0202724:	9782                	jalr	a5
ffffffffc0202726:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202728:	946fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc020272c:	be75                	j	ffffffffc02022e8 <pmm_init+0x19a>
        intr_disable();
ffffffffc020272e:	946fe0ef          	jal	ffffffffc0200874 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202732:	000b3783          	ld	a5,0(s6)
ffffffffc0202736:	779c                	ld	a5,40(a5)
ffffffffc0202738:	9782                	jalr	a5
ffffffffc020273a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020273c:	932fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202740:	b6ad                	j	ffffffffc02022aa <pmm_init+0x15c>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202742:	6705                	lui	a4,0x1
ffffffffc0202744:	177d                	addi	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0202746:	96ba                	add	a3,a3,a4
ffffffffc0202748:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc020274a:	00c7d713          	srli	a4,a5,0xc
ffffffffc020274e:	14a77e63          	bgeu	a4,a0,ffffffffc02028aa <pmm_init+0x75c>
    pmm_manager->init_memmap(base, n);
ffffffffc0202752:	000b3683          	ld	a3,0(s6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202756:	8c1d                	sub	s0,s0,a5
    return &pages[PPN(pa) - nbase];
ffffffffc0202758:	071a                	slli	a4,a4,0x6
ffffffffc020275a:	fe0007b7          	lui	a5,0xfe000
ffffffffc020275e:	973e                	add	a4,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc0202760:	6a9c                	ld	a5,16(a3)
ffffffffc0202762:	00c45593          	srli	a1,s0,0xc
ffffffffc0202766:	00e60533          	add	a0,a2,a4
ffffffffc020276a:	9782                	jalr	a5
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc020276c:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202770:	bcf1                	j	ffffffffc020224c <pmm_init+0xfe>
        intr_disable();
ffffffffc0202772:	902fe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202776:	000b3783          	ld	a5,0(s6)
ffffffffc020277a:	4505                	li	a0,1
ffffffffc020277c:	6f9c                	ld	a5,24(a5)
ffffffffc020277e:	9782                	jalr	a5
ffffffffc0202780:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202782:	8ecfe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202786:	b119                	j	ffffffffc020238c <pmm_init+0x23e>
        intr_disable();
ffffffffc0202788:	8ecfe0ef          	jal	ffffffffc0200874 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020278c:	000b3783          	ld	a5,0(s6)
ffffffffc0202790:	779c                	ld	a5,40(a5)
ffffffffc0202792:	9782                	jalr	a5
ffffffffc0202794:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202796:	8d8fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc020279a:	b345                	j	ffffffffc020253a <pmm_init+0x3ec>
        intr_disable();
ffffffffc020279c:	8d8fe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc02027a0:	000b3783          	ld	a5,0(s6)
ffffffffc02027a4:	779c                	ld	a5,40(a5)
ffffffffc02027a6:	9782                	jalr	a5
ffffffffc02027a8:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02027aa:	8c4fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02027ae:	b3a5                	j	ffffffffc0202516 <pmm_init+0x3c8>
ffffffffc02027b0:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027b2:	8c2fe0ef          	jal	ffffffffc0200874 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02027b6:	000b3783          	ld	a5,0(s6)
ffffffffc02027ba:	6522                	ld	a0,8(sp)
ffffffffc02027bc:	4585                	li	a1,1
ffffffffc02027be:	739c                	ld	a5,32(a5)
ffffffffc02027c0:	9782                	jalr	a5
        intr_enable();
ffffffffc02027c2:	8acfe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02027c6:	bb05                	j	ffffffffc02024f6 <pmm_init+0x3a8>
ffffffffc02027c8:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027ca:	8aafe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc02027ce:	000b3783          	ld	a5,0(s6)
ffffffffc02027d2:	6522                	ld	a0,8(sp)
ffffffffc02027d4:	4585                	li	a1,1
ffffffffc02027d6:	739c                	ld	a5,32(a5)
ffffffffc02027d8:	9782                	jalr	a5
        intr_enable();
ffffffffc02027da:	894fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02027de:	b1e5                	j	ffffffffc02024c6 <pmm_init+0x378>
        intr_disable();
ffffffffc02027e0:	894fe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02027e4:	000b3783          	ld	a5,0(s6)
ffffffffc02027e8:	4505                	li	a0,1
ffffffffc02027ea:	6f9c                	ld	a5,24(a5)
ffffffffc02027ec:	9782                	jalr	a5
ffffffffc02027ee:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02027f0:	87efe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02027f4:	b375                	j	ffffffffc02025a0 <pmm_init+0x452>
        intr_disable();
ffffffffc02027f6:	87efe0ef          	jal	ffffffffc0200874 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02027fa:	000b3783          	ld	a5,0(s6)
ffffffffc02027fe:	779c                	ld	a5,40(a5)
ffffffffc0202800:	9782                	jalr	a5
ffffffffc0202802:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202804:	86afe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202808:	b5c5                	j	ffffffffc02026e8 <pmm_init+0x59a>
ffffffffc020280a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020280c:	868fe0ef          	jal	ffffffffc0200874 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202810:	000b3783          	ld	a5,0(s6)
ffffffffc0202814:	6522                	ld	a0,8(sp)
ffffffffc0202816:	4585                	li	a1,1
ffffffffc0202818:	739c                	ld	a5,32(a5)
ffffffffc020281a:	9782                	jalr	a5
        intr_enable();
ffffffffc020281c:	852fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202820:	b565                	j	ffffffffc02026c8 <pmm_init+0x57a>
ffffffffc0202822:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202824:	850fe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc0202828:	000b3783          	ld	a5,0(s6)
ffffffffc020282c:	6522                	ld	a0,8(sp)
ffffffffc020282e:	4585                	li	a1,1
ffffffffc0202830:	739c                	ld	a5,32(a5)
ffffffffc0202832:	9782                	jalr	a5
        intr_enable();
ffffffffc0202834:	83afe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202838:	b585                	j	ffffffffc0202698 <pmm_init+0x54a>
        intr_disable();
ffffffffc020283a:	83afe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc020283e:	000b3783          	ld	a5,0(s6)
ffffffffc0202842:	8522                	mv	a0,s0
ffffffffc0202844:	4585                	li	a1,1
ffffffffc0202846:	739c                	ld	a5,32(a5)
ffffffffc0202848:	9782                	jalr	a5
        intr_enable();
ffffffffc020284a:	824fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc020284e:	bd29                	j	ffffffffc0202668 <pmm_init+0x51a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202850:	86a2                	mv	a3,s0
ffffffffc0202852:	00002617          	auipc	a2,0x2
ffffffffc0202856:	45e60613          	addi	a2,a2,1118 # ffffffffc0204cb0 <etext+0xd84>
ffffffffc020285a:	1a400593          	li	a1,420
ffffffffc020285e:	00002517          	auipc	a0,0x2
ffffffffc0202862:	54250513          	addi	a0,a0,1346 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202866:	ba1fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020286a:	00003697          	auipc	a3,0x3
ffffffffc020286e:	98668693          	addi	a3,a3,-1658 # ffffffffc02051f0 <etext+0x12c4>
ffffffffc0202872:	00002617          	auipc	a2,0x2
ffffffffc0202876:	08e60613          	addi	a2,a2,142 # ffffffffc0204900 <etext+0x9d4>
ffffffffc020287a:	1a500593          	li	a1,421
ffffffffc020287e:	00002517          	auipc	a0,0x2
ffffffffc0202882:	52250513          	addi	a0,a0,1314 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202886:	b81fd0ef          	jal	ffffffffc0200406 <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020288a:	00003697          	auipc	a3,0x3
ffffffffc020288e:	92668693          	addi	a3,a3,-1754 # ffffffffc02051b0 <etext+0x1284>
ffffffffc0202892:	00002617          	auipc	a2,0x2
ffffffffc0202896:	06e60613          	addi	a2,a2,110 # ffffffffc0204900 <etext+0x9d4>
ffffffffc020289a:	1a400593          	li	a1,420
ffffffffc020289e:	00002517          	auipc	a0,0x2
ffffffffc02028a2:	50250513          	addi	a0,a0,1282 # ffffffffc0204da0 <etext+0xe74>
ffffffffc02028a6:	b61fd0ef          	jal	ffffffffc0200406 <__panic>
ffffffffc02028aa:	b9cff0ef          	jal	ffffffffc0201c46 <pa2page.part.0>
        panic("pte2page called with invalid pte");
ffffffffc02028ae:	00002617          	auipc	a2,0x2
ffffffffc02028b2:	6a260613          	addi	a2,a2,1698 # ffffffffc0204f50 <etext+0x1024>
ffffffffc02028b6:	07f00593          	li	a1,127
ffffffffc02028ba:	00002517          	auipc	a0,0x2
ffffffffc02028be:	41e50513          	addi	a0,a0,1054 # ffffffffc0204cd8 <etext+0xdac>
ffffffffc02028c2:	b45fd0ef          	jal	ffffffffc0200406 <__panic>
        panic("DTB memory info not available");
ffffffffc02028c6:	00002617          	auipc	a2,0x2
ffffffffc02028ca:	50260613          	addi	a2,a2,1282 # ffffffffc0204dc8 <etext+0xe9c>
ffffffffc02028ce:	06400593          	li	a1,100
ffffffffc02028d2:	00002517          	auipc	a0,0x2
ffffffffc02028d6:	4ce50513          	addi	a0,a0,1230 # ffffffffc0204da0 <etext+0xe74>
ffffffffc02028da:	b2dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02028de:	00003697          	auipc	a3,0x3
ffffffffc02028e2:	88a68693          	addi	a3,a3,-1910 # ffffffffc0205168 <etext+0x123c>
ffffffffc02028e6:	00002617          	auipc	a2,0x2
ffffffffc02028ea:	01a60613          	addi	a2,a2,26 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02028ee:	1bf00593          	li	a1,447
ffffffffc02028f2:	00002517          	auipc	a0,0x2
ffffffffc02028f6:	4ae50513          	addi	a0,a0,1198 # ffffffffc0204da0 <etext+0xe74>
ffffffffc02028fa:	b0dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02028fe:	00002697          	auipc	a3,0x2
ffffffffc0202902:	58268693          	addi	a3,a3,1410 # ffffffffc0204e80 <etext+0xf54>
ffffffffc0202906:	00002617          	auipc	a2,0x2
ffffffffc020290a:	ffa60613          	addi	a2,a2,-6 # ffffffffc0204900 <etext+0x9d4>
ffffffffc020290e:	16600593          	li	a1,358
ffffffffc0202912:	00002517          	auipc	a0,0x2
ffffffffc0202916:	48e50513          	addi	a0,a0,1166 # ffffffffc0204da0 <etext+0xe74>
ffffffffc020291a:	aedfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020291e:	00002697          	auipc	a3,0x2
ffffffffc0202922:	54268693          	addi	a3,a3,1346 # ffffffffc0204e60 <etext+0xf34>
ffffffffc0202926:	00002617          	auipc	a2,0x2
ffffffffc020292a:	fda60613          	addi	a2,a2,-38 # ffffffffc0204900 <etext+0x9d4>
ffffffffc020292e:	16500593          	li	a1,357
ffffffffc0202932:	00002517          	auipc	a0,0x2
ffffffffc0202936:	46e50513          	addi	a0,a0,1134 # ffffffffc0204da0 <etext+0xe74>
ffffffffc020293a:	acdfd0ef          	jal	ffffffffc0200406 <__panic>
    return KADDR(page2pa(page));
ffffffffc020293e:	00002617          	auipc	a2,0x2
ffffffffc0202942:	37260613          	addi	a2,a2,882 # ffffffffc0204cb0 <etext+0xd84>
ffffffffc0202946:	07100593          	li	a1,113
ffffffffc020294a:	00002517          	auipc	a0,0x2
ffffffffc020294e:	38e50513          	addi	a0,a0,910 # ffffffffc0204cd8 <etext+0xdac>
ffffffffc0202952:	ab5fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202956:	00002697          	auipc	a3,0x2
ffffffffc020295a:	7e268693          	addi	a3,a3,2018 # ffffffffc0205138 <etext+0x120c>
ffffffffc020295e:	00002617          	auipc	a2,0x2
ffffffffc0202962:	fa260613          	addi	a2,a2,-94 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202966:	18d00593          	li	a1,397
ffffffffc020296a:	00002517          	auipc	a0,0x2
ffffffffc020296e:	43650513          	addi	a0,a0,1078 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202972:	a95fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202976:	00002697          	auipc	a3,0x2
ffffffffc020297a:	77a68693          	addi	a3,a3,1914 # ffffffffc02050f0 <etext+0x11c4>
ffffffffc020297e:	00002617          	auipc	a2,0x2
ffffffffc0202982:	f8260613          	addi	a2,a2,-126 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202986:	18b00593          	li	a1,395
ffffffffc020298a:	00002517          	auipc	a0,0x2
ffffffffc020298e:	41650513          	addi	a0,a0,1046 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202992:	a75fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202996:	00002697          	auipc	a3,0x2
ffffffffc020299a:	78a68693          	addi	a3,a3,1930 # ffffffffc0205120 <etext+0x11f4>
ffffffffc020299e:	00002617          	auipc	a2,0x2
ffffffffc02029a2:	f6260613          	addi	a2,a2,-158 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02029a6:	18a00593          	li	a1,394
ffffffffc02029aa:	00002517          	auipc	a0,0x2
ffffffffc02029ae:	3f650513          	addi	a0,a0,1014 # ffffffffc0204da0 <etext+0xe74>
ffffffffc02029b2:	a55fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc02029b6:	00003697          	auipc	a3,0x3
ffffffffc02029ba:	85268693          	addi	a3,a3,-1966 # ffffffffc0205208 <etext+0x12dc>
ffffffffc02029be:	00002617          	auipc	a2,0x2
ffffffffc02029c2:	f4260613          	addi	a2,a2,-190 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02029c6:	1a800593          	li	a1,424
ffffffffc02029ca:	00002517          	auipc	a0,0x2
ffffffffc02029ce:	3d650513          	addi	a0,a0,982 # ffffffffc0204da0 <etext+0xe74>
ffffffffc02029d2:	a35fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02029d6:	00002697          	auipc	a3,0x2
ffffffffc02029da:	79268693          	addi	a3,a3,1938 # ffffffffc0205168 <etext+0x123c>
ffffffffc02029de:	00002617          	auipc	a2,0x2
ffffffffc02029e2:	f2260613          	addi	a2,a2,-222 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02029e6:	19500593          	li	a1,405
ffffffffc02029ea:	00002517          	auipc	a0,0x2
ffffffffc02029ee:	3b650513          	addi	a0,a0,950 # ffffffffc0204da0 <etext+0xe74>
ffffffffc02029f2:	a15fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p) == 1);
ffffffffc02029f6:	00003697          	auipc	a3,0x3
ffffffffc02029fa:	86a68693          	addi	a3,a3,-1942 # ffffffffc0205260 <etext+0x1334>
ffffffffc02029fe:	00002617          	auipc	a2,0x2
ffffffffc0202a02:	f0260613          	addi	a2,a2,-254 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202a06:	1ad00593          	li	a1,429
ffffffffc0202a0a:	00002517          	auipc	a0,0x2
ffffffffc0202a0e:	39650513          	addi	a0,a0,918 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202a12:	9f5fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202a16:	00003697          	auipc	a3,0x3
ffffffffc0202a1a:	80a68693          	addi	a3,a3,-2038 # ffffffffc0205220 <etext+0x12f4>
ffffffffc0202a1e:	00002617          	auipc	a2,0x2
ffffffffc0202a22:	ee260613          	addi	a2,a2,-286 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202a26:	1ac00593          	li	a1,428
ffffffffc0202a2a:	00002517          	auipc	a0,0x2
ffffffffc0202a2e:	37650513          	addi	a0,a0,886 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202a32:	9d5fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202a36:	00002697          	auipc	a3,0x2
ffffffffc0202a3a:	6ba68693          	addi	a3,a3,1722 # ffffffffc02050f0 <etext+0x11c4>
ffffffffc0202a3e:	00002617          	auipc	a2,0x2
ffffffffc0202a42:	ec260613          	addi	a2,a2,-318 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202a46:	18700593          	li	a1,391
ffffffffc0202a4a:	00002517          	auipc	a0,0x2
ffffffffc0202a4e:	35650513          	addi	a0,a0,854 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202a52:	9b5fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202a56:	00002697          	auipc	a3,0x2
ffffffffc0202a5a:	53a68693          	addi	a3,a3,1338 # ffffffffc0204f90 <etext+0x1064>
ffffffffc0202a5e:	00002617          	auipc	a2,0x2
ffffffffc0202a62:	ea260613          	addi	a2,a2,-350 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202a66:	18600593          	li	a1,390
ffffffffc0202a6a:	00002517          	auipc	a0,0x2
ffffffffc0202a6e:	33650513          	addi	a0,a0,822 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202a72:	995fd0ef          	jal	ffffffffc0200406 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a76:	00002697          	auipc	a3,0x2
ffffffffc0202a7a:	69268693          	addi	a3,a3,1682 # ffffffffc0205108 <etext+0x11dc>
ffffffffc0202a7e:	00002617          	auipc	a2,0x2
ffffffffc0202a82:	e8260613          	addi	a2,a2,-382 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202a86:	18300593          	li	a1,387
ffffffffc0202a8a:	00002517          	auipc	a0,0x2
ffffffffc0202a8e:	31650513          	addi	a0,a0,790 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202a92:	975fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a96:	00002697          	auipc	a3,0x2
ffffffffc0202a9a:	4e268693          	addi	a3,a3,1250 # ffffffffc0204f78 <etext+0x104c>
ffffffffc0202a9e:	00002617          	auipc	a2,0x2
ffffffffc0202aa2:	e6260613          	addi	a2,a2,-414 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202aa6:	18200593          	li	a1,386
ffffffffc0202aaa:	00002517          	auipc	a0,0x2
ffffffffc0202aae:	2f650513          	addi	a0,a0,758 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202ab2:	955fd0ef          	jal	ffffffffc0200406 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202ab6:	00002697          	auipc	a3,0x2
ffffffffc0202aba:	56268693          	addi	a3,a3,1378 # ffffffffc0205018 <etext+0x10ec>
ffffffffc0202abe:	00002617          	auipc	a2,0x2
ffffffffc0202ac2:	e4260613          	addi	a2,a2,-446 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202ac6:	18100593          	li	a1,385
ffffffffc0202aca:	00002517          	auipc	a0,0x2
ffffffffc0202ace:	2d650513          	addi	a0,a0,726 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202ad2:	935fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202ad6:	00002697          	auipc	a3,0x2
ffffffffc0202ada:	61a68693          	addi	a3,a3,1562 # ffffffffc02050f0 <etext+0x11c4>
ffffffffc0202ade:	00002617          	auipc	a2,0x2
ffffffffc0202ae2:	e2260613          	addi	a2,a2,-478 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202ae6:	18000593          	li	a1,384
ffffffffc0202aea:	00002517          	auipc	a0,0x2
ffffffffc0202aee:	2b650513          	addi	a0,a0,694 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202af2:	915fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202af6:	00002697          	auipc	a3,0x2
ffffffffc0202afa:	5e268693          	addi	a3,a3,1506 # ffffffffc02050d8 <etext+0x11ac>
ffffffffc0202afe:	00002617          	auipc	a2,0x2
ffffffffc0202b02:	e0260613          	addi	a2,a2,-510 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202b06:	17f00593          	li	a1,383
ffffffffc0202b0a:	00002517          	auipc	a0,0x2
ffffffffc0202b0e:	29650513          	addi	a0,a0,662 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202b12:	8f5fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202b16:	00002697          	auipc	a3,0x2
ffffffffc0202b1a:	59268693          	addi	a3,a3,1426 # ffffffffc02050a8 <etext+0x117c>
ffffffffc0202b1e:	00002617          	auipc	a2,0x2
ffffffffc0202b22:	de260613          	addi	a2,a2,-542 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202b26:	17e00593          	li	a1,382
ffffffffc0202b2a:	00002517          	auipc	a0,0x2
ffffffffc0202b2e:	27650513          	addi	a0,a0,630 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202b32:	8d5fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202b36:	00002697          	auipc	a3,0x2
ffffffffc0202b3a:	55a68693          	addi	a3,a3,1370 # ffffffffc0205090 <etext+0x1164>
ffffffffc0202b3e:	00002617          	auipc	a2,0x2
ffffffffc0202b42:	dc260613          	addi	a2,a2,-574 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202b46:	17c00593          	li	a1,380
ffffffffc0202b4a:	00002517          	auipc	a0,0x2
ffffffffc0202b4e:	25650513          	addi	a0,a0,598 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202b52:	8b5fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202b56:	00002697          	auipc	a3,0x2
ffffffffc0202b5a:	51a68693          	addi	a3,a3,1306 # ffffffffc0205070 <etext+0x1144>
ffffffffc0202b5e:	00002617          	auipc	a2,0x2
ffffffffc0202b62:	da260613          	addi	a2,a2,-606 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202b66:	17b00593          	li	a1,379
ffffffffc0202b6a:	00002517          	auipc	a0,0x2
ffffffffc0202b6e:	23650513          	addi	a0,a0,566 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202b72:	895fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0202b76:	00002697          	auipc	a3,0x2
ffffffffc0202b7a:	4ea68693          	addi	a3,a3,1258 # ffffffffc0205060 <etext+0x1134>
ffffffffc0202b7e:	00002617          	auipc	a2,0x2
ffffffffc0202b82:	d8260613          	addi	a2,a2,-638 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202b86:	17a00593          	li	a1,378
ffffffffc0202b8a:	00002517          	auipc	a0,0x2
ffffffffc0202b8e:	21650513          	addi	a0,a0,534 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202b92:	875fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202b96:	00002697          	auipc	a3,0x2
ffffffffc0202b9a:	4ba68693          	addi	a3,a3,1210 # ffffffffc0205050 <etext+0x1124>
ffffffffc0202b9e:	00002617          	auipc	a2,0x2
ffffffffc0202ba2:	d6260613          	addi	a2,a2,-670 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202ba6:	17900593          	li	a1,377
ffffffffc0202baa:	00002517          	auipc	a0,0x2
ffffffffc0202bae:	1f650513          	addi	a0,a0,502 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202bb2:	855fd0ef          	jal	ffffffffc0200406 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202bb6:	00002617          	auipc	a2,0x2
ffffffffc0202bba:	1a260613          	addi	a2,a2,418 # ffffffffc0204d58 <etext+0xe2c>
ffffffffc0202bbe:	08000593          	li	a1,128
ffffffffc0202bc2:	00002517          	auipc	a0,0x2
ffffffffc0202bc6:	1de50513          	addi	a0,a0,478 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202bca:	83dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202bce:	00002697          	auipc	a3,0x2
ffffffffc0202bd2:	3da68693          	addi	a3,a3,986 # ffffffffc0204fa8 <etext+0x107c>
ffffffffc0202bd6:	00002617          	auipc	a2,0x2
ffffffffc0202bda:	d2a60613          	addi	a2,a2,-726 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202bde:	17400593          	li	a1,372
ffffffffc0202be2:	00002517          	auipc	a0,0x2
ffffffffc0202be6:	1be50513          	addi	a0,a0,446 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202bea:	81dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202bee:	00002697          	auipc	a3,0x2
ffffffffc0202bf2:	42a68693          	addi	a3,a3,1066 # ffffffffc0205018 <etext+0x10ec>
ffffffffc0202bf6:	00002617          	auipc	a2,0x2
ffffffffc0202bfa:	d0a60613          	addi	a2,a2,-758 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202bfe:	17800593          	li	a1,376
ffffffffc0202c02:	00002517          	auipc	a0,0x2
ffffffffc0202c06:	19e50513          	addi	a0,a0,414 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202c0a:	ffcfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202c0e:	00002697          	auipc	a3,0x2
ffffffffc0202c12:	3ca68693          	addi	a3,a3,970 # ffffffffc0204fd8 <etext+0x10ac>
ffffffffc0202c16:	00002617          	auipc	a2,0x2
ffffffffc0202c1a:	cea60613          	addi	a2,a2,-790 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202c1e:	17700593          	li	a1,375
ffffffffc0202c22:	00002517          	auipc	a0,0x2
ffffffffc0202c26:	17e50513          	addi	a0,a0,382 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202c2a:	fdcfd0ef          	jal	ffffffffc0200406 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202c2e:	86d6                	mv	a3,s5
ffffffffc0202c30:	00002617          	auipc	a2,0x2
ffffffffc0202c34:	08060613          	addi	a2,a2,128 # ffffffffc0204cb0 <etext+0xd84>
ffffffffc0202c38:	17300593          	li	a1,371
ffffffffc0202c3c:	00002517          	auipc	a0,0x2
ffffffffc0202c40:	16450513          	addi	a0,a0,356 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202c44:	fc2fd0ef          	jal	ffffffffc0200406 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202c48:	00002617          	auipc	a2,0x2
ffffffffc0202c4c:	06860613          	addi	a2,a2,104 # ffffffffc0204cb0 <etext+0xd84>
ffffffffc0202c50:	17200593          	li	a1,370
ffffffffc0202c54:	00002517          	auipc	a0,0x2
ffffffffc0202c58:	14c50513          	addi	a0,a0,332 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202c5c:	faafd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202c60:	00002697          	auipc	a3,0x2
ffffffffc0202c64:	33068693          	addi	a3,a3,816 # ffffffffc0204f90 <etext+0x1064>
ffffffffc0202c68:	00002617          	auipc	a2,0x2
ffffffffc0202c6c:	c9860613          	addi	a2,a2,-872 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202c70:	17000593          	li	a1,368
ffffffffc0202c74:	00002517          	auipc	a0,0x2
ffffffffc0202c78:	12c50513          	addi	a0,a0,300 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202c7c:	f8afd0ef          	jal	ffffffffc0200406 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202c80:	00002697          	auipc	a3,0x2
ffffffffc0202c84:	2f868693          	addi	a3,a3,760 # ffffffffc0204f78 <etext+0x104c>
ffffffffc0202c88:	00002617          	auipc	a2,0x2
ffffffffc0202c8c:	c7860613          	addi	a2,a2,-904 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202c90:	16f00593          	li	a1,367
ffffffffc0202c94:	00002517          	auipc	a0,0x2
ffffffffc0202c98:	10c50513          	addi	a0,a0,268 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202c9c:	f6afd0ef          	jal	ffffffffc0200406 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202ca0:	00002697          	auipc	a3,0x2
ffffffffc0202ca4:	68868693          	addi	a3,a3,1672 # ffffffffc0205328 <etext+0x13fc>
ffffffffc0202ca8:	00002617          	auipc	a2,0x2
ffffffffc0202cac:	c5860613          	addi	a2,a2,-936 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202cb0:	1b600593          	li	a1,438
ffffffffc0202cb4:	00002517          	auipc	a0,0x2
ffffffffc0202cb8:	0ec50513          	addi	a0,a0,236 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202cbc:	f4afd0ef          	jal	ffffffffc0200406 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202cc0:	00002697          	auipc	a3,0x2
ffffffffc0202cc4:	63068693          	addi	a3,a3,1584 # ffffffffc02052f0 <etext+0x13c4>
ffffffffc0202cc8:	00002617          	auipc	a2,0x2
ffffffffc0202ccc:	c3860613          	addi	a2,a2,-968 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202cd0:	1b300593          	li	a1,435
ffffffffc0202cd4:	00002517          	auipc	a0,0x2
ffffffffc0202cd8:	0cc50513          	addi	a0,a0,204 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202cdc:	f2afd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0202ce0:	00002697          	auipc	a3,0x2
ffffffffc0202ce4:	5e068693          	addi	a3,a3,1504 # ffffffffc02052c0 <etext+0x1394>
ffffffffc0202ce8:	00002617          	auipc	a2,0x2
ffffffffc0202cec:	c1860613          	addi	a2,a2,-1000 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202cf0:	1af00593          	li	a1,431
ffffffffc0202cf4:	00002517          	auipc	a0,0x2
ffffffffc0202cf8:	0ac50513          	addi	a0,a0,172 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202cfc:	f0afd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202d00:	00002697          	auipc	a3,0x2
ffffffffc0202d04:	57868693          	addi	a3,a3,1400 # ffffffffc0205278 <etext+0x134c>
ffffffffc0202d08:	00002617          	auipc	a2,0x2
ffffffffc0202d0c:	bf860613          	addi	a2,a2,-1032 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202d10:	1ae00593          	li	a1,430
ffffffffc0202d14:	00002517          	auipc	a0,0x2
ffffffffc0202d18:	08c50513          	addi	a0,a0,140 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202d1c:	eeafd0ef          	jal	ffffffffc0200406 <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202d20:	00002697          	auipc	a3,0x2
ffffffffc0202d24:	1a068693          	addi	a3,a3,416 # ffffffffc0204ec0 <etext+0xf94>
ffffffffc0202d28:	00002617          	auipc	a2,0x2
ffffffffc0202d2c:	bd860613          	addi	a2,a2,-1064 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202d30:	16700593          	li	a1,359
ffffffffc0202d34:	00002517          	auipc	a0,0x2
ffffffffc0202d38:	06c50513          	addi	a0,a0,108 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202d3c:	ecafd0ef          	jal	ffffffffc0200406 <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202d40:	00002617          	auipc	a2,0x2
ffffffffc0202d44:	01860613          	addi	a2,a2,24 # ffffffffc0204d58 <etext+0xe2c>
ffffffffc0202d48:	0cb00593          	li	a1,203
ffffffffc0202d4c:	00002517          	auipc	a0,0x2
ffffffffc0202d50:	05450513          	addi	a0,a0,84 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202d54:	eb2fd0ef          	jal	ffffffffc0200406 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202d58:	00002697          	auipc	a3,0x2
ffffffffc0202d5c:	1c868693          	addi	a3,a3,456 # ffffffffc0204f20 <etext+0xff4>
ffffffffc0202d60:	00002617          	auipc	a2,0x2
ffffffffc0202d64:	ba060613          	addi	a2,a2,-1120 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202d68:	16e00593          	li	a1,366
ffffffffc0202d6c:	00002517          	auipc	a0,0x2
ffffffffc0202d70:	03450513          	addi	a0,a0,52 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202d74:	e92fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202d78:	00002697          	auipc	a3,0x2
ffffffffc0202d7c:	17868693          	addi	a3,a3,376 # ffffffffc0204ef0 <etext+0xfc4>
ffffffffc0202d80:	00002617          	auipc	a2,0x2
ffffffffc0202d84:	b8060613          	addi	a2,a2,-1152 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202d88:	16b00593          	li	a1,363
ffffffffc0202d8c:	00002517          	auipc	a0,0x2
ffffffffc0202d90:	01450513          	addi	a0,a0,20 # ffffffffc0204da0 <etext+0xe74>
ffffffffc0202d94:	e72fd0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0202d98 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202d98:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0202d9a:	00002697          	auipc	a3,0x2
ffffffffc0202d9e:	5d668693          	addi	a3,a3,1494 # ffffffffc0205370 <etext+0x1444>
ffffffffc0202da2:	00002617          	auipc	a2,0x2
ffffffffc0202da6:	b5e60613          	addi	a2,a2,-1186 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202daa:	08800593          	li	a1,136
ffffffffc0202dae:	00002517          	auipc	a0,0x2
ffffffffc0202db2:	5e250513          	addi	a0,a0,1506 # ffffffffc0205390 <etext+0x1464>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202db6:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0202db8:	e4efd0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0202dbc <find_vma>:
    if (mm != NULL)
ffffffffc0202dbc:	c505                	beqz	a0,ffffffffc0202de4 <find_vma+0x28>
        vma = mm->mmap_cache;
ffffffffc0202dbe:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202dc0:	c781                	beqz	a5,ffffffffc0202dc8 <find_vma+0xc>
ffffffffc0202dc2:	6798                	ld	a4,8(a5)
ffffffffc0202dc4:	02e5f363          	bgeu	a1,a4,ffffffffc0202dea <find_vma+0x2e>
    return listelm->next;
ffffffffc0202dc8:	651c                	ld	a5,8(a0)
            while ((le = list_next(le)) != list)
ffffffffc0202dca:	00f50d63          	beq	a0,a5,ffffffffc0202de4 <find_vma+0x28>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0202dce:	fe87b703          	ld	a4,-24(a5) # fffffffffdffffe8 <end+0x3ddf2af0>
ffffffffc0202dd2:	00e5e663          	bltu	a1,a4,ffffffffc0202dde <find_vma+0x22>
ffffffffc0202dd6:	ff07b703          	ld	a4,-16(a5)
ffffffffc0202dda:	00e5ee63          	bltu	a1,a4,ffffffffc0202df6 <find_vma+0x3a>
ffffffffc0202dde:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0202de0:	fef517e3          	bne	a0,a5,ffffffffc0202dce <find_vma+0x12>
    struct vma_struct *vma = NULL;
ffffffffc0202de4:	4781                	li	a5,0
}
ffffffffc0202de6:	853e                	mv	a0,a5
ffffffffc0202de8:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202dea:	6b98                	ld	a4,16(a5)
ffffffffc0202dec:	fce5fee3          	bgeu	a1,a4,ffffffffc0202dc8 <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc0202df0:	e91c                	sd	a5,16(a0)
}
ffffffffc0202df2:	853e                	mv	a0,a5
ffffffffc0202df4:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0202df6:	1781                	addi	a5,a5,-32
            mm->mmap_cache = vma;
ffffffffc0202df8:	e91c                	sd	a5,16(a0)
ffffffffc0202dfa:	bfe5                	j	ffffffffc0202df2 <find_vma+0x36>

ffffffffc0202dfc <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202dfc:	6590                	ld	a2,8(a1)
ffffffffc0202dfe:	0105b803          	ld	a6,16(a1)
{
ffffffffc0202e02:	1141                	addi	sp,sp,-16
ffffffffc0202e04:	e406                	sd	ra,8(sp)
ffffffffc0202e06:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e08:	01066763          	bltu	a2,a6,ffffffffc0202e16 <insert_vma_struct+0x1a>
ffffffffc0202e0c:	a8b9                	j	ffffffffc0202e6a <insert_vma_struct+0x6e>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202e0e:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202e12:	04e66763          	bltu	a2,a4,ffffffffc0202e60 <insert_vma_struct+0x64>
ffffffffc0202e16:	86be                	mv	a3,a5
ffffffffc0202e18:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0202e1a:	fef51ae3          	bne	a0,a5,ffffffffc0202e0e <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0202e1e:	02a68463          	beq	a3,a0,ffffffffc0202e46 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0202e22:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202e26:	fe86b883          	ld	a7,-24(a3)
ffffffffc0202e2a:	08e8f063          	bgeu	a7,a4,ffffffffc0202eaa <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e2e:	04e66e63          	bltu	a2,a4,ffffffffc0202e8a <insert_vma_struct+0x8e>
    }
    if (le_next != list)
ffffffffc0202e32:	00f50a63          	beq	a0,a5,ffffffffc0202e46 <insert_vma_struct+0x4a>
ffffffffc0202e36:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e3a:	05076863          	bltu	a4,a6,ffffffffc0202e8a <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc0202e3e:	ff07b603          	ld	a2,-16(a5)
ffffffffc0202e42:	02c77263          	bgeu	a4,a2,ffffffffc0202e66 <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0202e46:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0202e48:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0202e4a:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0202e4e:	e390                	sd	a2,0(a5)
ffffffffc0202e50:	e690                	sd	a2,8(a3)
}
ffffffffc0202e52:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0202e54:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0202e56:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0202e58:	2705                	addiw	a4,a4,1
ffffffffc0202e5a:	d118                	sw	a4,32(a0)
}
ffffffffc0202e5c:	0141                	addi	sp,sp,16
ffffffffc0202e5e:	8082                	ret
    if (le_prev != list)
ffffffffc0202e60:	fca691e3          	bne	a3,a0,ffffffffc0202e22 <insert_vma_struct+0x26>
ffffffffc0202e64:	bfd9                	j	ffffffffc0202e3a <insert_vma_struct+0x3e>
ffffffffc0202e66:	f33ff0ef          	jal	ffffffffc0202d98 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e6a:	00002697          	auipc	a3,0x2
ffffffffc0202e6e:	53668693          	addi	a3,a3,1334 # ffffffffc02053a0 <etext+0x1474>
ffffffffc0202e72:	00002617          	auipc	a2,0x2
ffffffffc0202e76:	a8e60613          	addi	a2,a2,-1394 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202e7a:	08e00593          	li	a1,142
ffffffffc0202e7e:	00002517          	auipc	a0,0x2
ffffffffc0202e82:	51250513          	addi	a0,a0,1298 # ffffffffc0205390 <etext+0x1464>
ffffffffc0202e86:	d80fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e8a:	00002697          	auipc	a3,0x2
ffffffffc0202e8e:	55668693          	addi	a3,a3,1366 # ffffffffc02053e0 <etext+0x14b4>
ffffffffc0202e92:	00002617          	auipc	a2,0x2
ffffffffc0202e96:	a6e60613          	addi	a2,a2,-1426 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202e9a:	08700593          	li	a1,135
ffffffffc0202e9e:	00002517          	auipc	a0,0x2
ffffffffc0202ea2:	4f250513          	addi	a0,a0,1266 # ffffffffc0205390 <etext+0x1464>
ffffffffc0202ea6:	d60fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202eaa:	00002697          	auipc	a3,0x2
ffffffffc0202eae:	51668693          	addi	a3,a3,1302 # ffffffffc02053c0 <etext+0x1494>
ffffffffc0202eb2:	00002617          	auipc	a2,0x2
ffffffffc0202eb6:	a4e60613          	addi	a2,a2,-1458 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0202eba:	08600593          	li	a1,134
ffffffffc0202ebe:	00002517          	auipc	a0,0x2
ffffffffc0202ec2:	4d250513          	addi	a0,a0,1234 # ffffffffc0205390 <etext+0x1464>
ffffffffc0202ec6:	d40fd0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0202eca <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0202eca:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202ecc:	03000513          	li	a0,48
{
ffffffffc0202ed0:	fc06                	sd	ra,56(sp)
ffffffffc0202ed2:	f822                	sd	s0,48(sp)
ffffffffc0202ed4:	f426                	sd	s1,40(sp)
ffffffffc0202ed6:	f04a                	sd	s2,32(sp)
ffffffffc0202ed8:	ec4e                	sd	s3,24(sp)
ffffffffc0202eda:	e852                	sd	s4,16(sp)
ffffffffc0202edc:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202ede:	bc3fe0ef          	jal	ffffffffc0201aa0 <kmalloc>
    if (mm != NULL)
ffffffffc0202ee2:	18050a63          	beqz	a0,ffffffffc0203076 <vmm_init+0x1ac>
ffffffffc0202ee6:	842a                	mv	s0,a0
    elm->prev = elm->next = elm;
ffffffffc0202ee8:	e508                	sd	a0,8(a0)
ffffffffc0202eea:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0202eec:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0202ef0:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0202ef4:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0202ef8:	02053423          	sd	zero,40(a0)
ffffffffc0202efc:	03200493          	li	s1,50
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202f00:	03000513          	li	a0,48
ffffffffc0202f04:	b9dfe0ef          	jal	ffffffffc0201aa0 <kmalloc>
    if (vma != NULL)
ffffffffc0202f08:	14050763          	beqz	a0,ffffffffc0203056 <vmm_init+0x18c>
        vma->vm_end = vm_end;
ffffffffc0202f0c:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0202f10:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202f12:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0202f16:	e91c                	sd	a5,16(a0)
    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202f18:	85aa                	mv	a1,a0
    for (i = step1; i >= 1; i--)
ffffffffc0202f1a:	14ed                	addi	s1,s1,-5
        insert_vma_struct(mm, vma);
ffffffffc0202f1c:	8522                	mv	a0,s0
ffffffffc0202f1e:	edfff0ef          	jal	ffffffffc0202dfc <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0202f22:	fcf9                	bnez	s1,ffffffffc0202f00 <vmm_init+0x36>
ffffffffc0202f24:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f28:	1f900913          	li	s2,505
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202f2c:	03000513          	li	a0,48
ffffffffc0202f30:	b71fe0ef          	jal	ffffffffc0201aa0 <kmalloc>
    if (vma != NULL)
ffffffffc0202f34:	16050163          	beqz	a0,ffffffffc0203096 <vmm_init+0x1cc>
        vma->vm_end = vm_end;
ffffffffc0202f38:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0202f3c:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202f3e:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0202f42:	e91c                	sd	a5,16(a0)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202f44:	85aa                	mv	a1,a0
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f46:	0495                	addi	s1,s1,5
        insert_vma_struct(mm, vma);
ffffffffc0202f48:	8522                	mv	a0,s0
ffffffffc0202f4a:	eb3ff0ef          	jal	ffffffffc0202dfc <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f4e:	fd249fe3          	bne	s1,s2,ffffffffc0202f2c <vmm_init+0x62>
    return listelm->next;
ffffffffc0202f52:	641c                	ld	a5,8(s0)
ffffffffc0202f54:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0202f56:	1fb00593          	li	a1,507
ffffffffc0202f5a:	8abe                	mv	s5,a5
    {
        assert(le != &(mm->mmap_list));
ffffffffc0202f5c:	20f40d63          	beq	s0,a5,ffffffffc0203176 <vmm_init+0x2ac>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202f60:	fe87b603          	ld	a2,-24(a5)
ffffffffc0202f64:	ffe70693          	addi	a3,a4,-2
ffffffffc0202f68:	14d61763          	bne	a2,a3,ffffffffc02030b6 <vmm_init+0x1ec>
ffffffffc0202f6c:	ff07b683          	ld	a3,-16(a5)
ffffffffc0202f70:	14e69363          	bne	a3,a4,ffffffffc02030b6 <vmm_init+0x1ec>
    for (i = 1; i <= step2; i++)
ffffffffc0202f74:	0715                	addi	a4,a4,5
ffffffffc0202f76:	679c                	ld	a5,8(a5)
ffffffffc0202f78:	feb712e3          	bne	a4,a1,ffffffffc0202f5c <vmm_init+0x92>
ffffffffc0202f7c:	491d                	li	s2,7
ffffffffc0202f7e:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0202f80:	85a6                	mv	a1,s1
ffffffffc0202f82:	8522                	mv	a0,s0
ffffffffc0202f84:	e39ff0ef          	jal	ffffffffc0202dbc <find_vma>
ffffffffc0202f88:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc0202f8a:	22050663          	beqz	a0,ffffffffc02031b6 <vmm_init+0x2ec>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0202f8e:	00148593          	addi	a1,s1,1
ffffffffc0202f92:	8522                	mv	a0,s0
ffffffffc0202f94:	e29ff0ef          	jal	ffffffffc0202dbc <find_vma>
ffffffffc0202f98:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0202f9a:	1e050e63          	beqz	a0,ffffffffc0203196 <vmm_init+0x2cc>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0202f9e:	85ca                	mv	a1,s2
ffffffffc0202fa0:	8522                	mv	a0,s0
ffffffffc0202fa2:	e1bff0ef          	jal	ffffffffc0202dbc <find_vma>
        assert(vma3 == NULL);
ffffffffc0202fa6:	1a051863          	bnez	a0,ffffffffc0203156 <vmm_init+0x28c>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0202faa:	00348593          	addi	a1,s1,3
ffffffffc0202fae:	8522                	mv	a0,s0
ffffffffc0202fb0:	e0dff0ef          	jal	ffffffffc0202dbc <find_vma>
        assert(vma4 == NULL);
ffffffffc0202fb4:	18051163          	bnez	a0,ffffffffc0203136 <vmm_init+0x26c>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0202fb8:	00448593          	addi	a1,s1,4
ffffffffc0202fbc:	8522                	mv	a0,s0
ffffffffc0202fbe:	dffff0ef          	jal	ffffffffc0202dbc <find_vma>
        assert(vma5 == NULL);
ffffffffc0202fc2:	14051a63          	bnez	a0,ffffffffc0203116 <vmm_init+0x24c>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0202fc6:	008a3783          	ld	a5,8(s4)
ffffffffc0202fca:	12979663          	bne	a5,s1,ffffffffc02030f6 <vmm_init+0x22c>
ffffffffc0202fce:	010a3783          	ld	a5,16(s4)
ffffffffc0202fd2:	13279263          	bne	a5,s2,ffffffffc02030f6 <vmm_init+0x22c>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0202fd6:	0089b783          	ld	a5,8(s3)
ffffffffc0202fda:	0e979e63          	bne	a5,s1,ffffffffc02030d6 <vmm_init+0x20c>
ffffffffc0202fde:	0109b783          	ld	a5,16(s3)
ffffffffc0202fe2:	0f279a63          	bne	a5,s2,ffffffffc02030d6 <vmm_init+0x20c>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0202fe6:	0495                	addi	s1,s1,5
ffffffffc0202fe8:	1f900793          	li	a5,505
ffffffffc0202fec:	0915                	addi	s2,s2,5
ffffffffc0202fee:	f8f499e3          	bne	s1,a5,ffffffffc0202f80 <vmm_init+0xb6>
ffffffffc0202ff2:	4491                	li	s1,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0202ff4:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0202ff6:	85a6                	mv	a1,s1
ffffffffc0202ff8:	8522                	mv	a0,s0
ffffffffc0202ffa:	dc3ff0ef          	jal	ffffffffc0202dbc <find_vma>
        if (vma_below_5 != NULL)
ffffffffc0202ffe:	1c051c63          	bnez	a0,ffffffffc02031d6 <vmm_init+0x30c>
    for (i = 4; i >= 0; i--)
ffffffffc0203002:	14fd                	addi	s1,s1,-1
ffffffffc0203004:	ff2499e3          	bne	s1,s2,ffffffffc0202ff6 <vmm_init+0x12c>
    while ((le = list_next(list)) != list)
ffffffffc0203008:	028a8063          	beq	s5,s0,ffffffffc0203028 <vmm_init+0x15e>
    __list_del(listelm->prev, listelm->next);
ffffffffc020300c:	008ab783          	ld	a5,8(s5) # 1008 <kern_entry-0xffffffffc01feff8>
ffffffffc0203010:	000ab703          	ld	a4,0(s5)
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0203014:	fe0a8513          	addi	a0,s5,-32
    prev->next = next;
ffffffffc0203018:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020301a:	e398                	sd	a4,0(a5)
ffffffffc020301c:	b2bfe0ef          	jal	ffffffffc0201b46 <kfree>
    return listelm->next;
ffffffffc0203020:	641c                	ld	a5,8(s0)
ffffffffc0203022:	8abe                	mv	s5,a5
    while ((le = list_next(list)) != list)
ffffffffc0203024:	fef414e3          	bne	s0,a5,ffffffffc020300c <vmm_init+0x142>
    kfree(mm); // kfree mm
ffffffffc0203028:	8522                	mv	a0,s0
ffffffffc020302a:	b1dfe0ef          	jal	ffffffffc0201b46 <kfree>
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc020302e:	00002517          	auipc	a0,0x2
ffffffffc0203032:	53250513          	addi	a0,a0,1330 # ffffffffc0205560 <etext+0x1634>
ffffffffc0203036:	95efd0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc020303a:	7442                	ld	s0,48(sp)
ffffffffc020303c:	70e2                	ld	ra,56(sp)
ffffffffc020303e:	74a2                	ld	s1,40(sp)
ffffffffc0203040:	7902                	ld	s2,32(sp)
ffffffffc0203042:	69e2                	ld	s3,24(sp)
ffffffffc0203044:	6a42                	ld	s4,16(sp)
ffffffffc0203046:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203048:	00002517          	auipc	a0,0x2
ffffffffc020304c:	53850513          	addi	a0,a0,1336 # ffffffffc0205580 <etext+0x1654>
}
ffffffffc0203050:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203052:	942fd06f          	j	ffffffffc0200194 <cprintf>
        assert(vma != NULL);
ffffffffc0203056:	00002697          	auipc	a3,0x2
ffffffffc020305a:	3ba68693          	addi	a3,a3,954 # ffffffffc0205410 <etext+0x14e4>
ffffffffc020305e:	00002617          	auipc	a2,0x2
ffffffffc0203062:	8a260613          	addi	a2,a2,-1886 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0203066:	0da00593          	li	a1,218
ffffffffc020306a:	00002517          	auipc	a0,0x2
ffffffffc020306e:	32650513          	addi	a0,a0,806 # ffffffffc0205390 <etext+0x1464>
ffffffffc0203072:	b94fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(mm != NULL);
ffffffffc0203076:	00002697          	auipc	a3,0x2
ffffffffc020307a:	38a68693          	addi	a3,a3,906 # ffffffffc0205400 <etext+0x14d4>
ffffffffc020307e:	00002617          	auipc	a2,0x2
ffffffffc0203082:	88260613          	addi	a2,a2,-1918 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0203086:	0d200593          	li	a1,210
ffffffffc020308a:	00002517          	auipc	a0,0x2
ffffffffc020308e:	30650513          	addi	a0,a0,774 # ffffffffc0205390 <etext+0x1464>
ffffffffc0203092:	b74fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma != NULL);
ffffffffc0203096:	00002697          	auipc	a3,0x2
ffffffffc020309a:	37a68693          	addi	a3,a3,890 # ffffffffc0205410 <etext+0x14e4>
ffffffffc020309e:	00002617          	auipc	a2,0x2
ffffffffc02030a2:	86260613          	addi	a2,a2,-1950 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02030a6:	0e100593          	li	a1,225
ffffffffc02030aa:	00002517          	auipc	a0,0x2
ffffffffc02030ae:	2e650513          	addi	a0,a0,742 # ffffffffc0205390 <etext+0x1464>
ffffffffc02030b2:	b54fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02030b6:	00002697          	auipc	a3,0x2
ffffffffc02030ba:	38268693          	addi	a3,a3,898 # ffffffffc0205438 <etext+0x150c>
ffffffffc02030be:	00002617          	auipc	a2,0x2
ffffffffc02030c2:	84260613          	addi	a2,a2,-1982 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02030c6:	0eb00593          	li	a1,235
ffffffffc02030ca:	00002517          	auipc	a0,0x2
ffffffffc02030ce:	2c650513          	addi	a0,a0,710 # ffffffffc0205390 <etext+0x1464>
ffffffffc02030d2:	b34fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc02030d6:	00002697          	auipc	a3,0x2
ffffffffc02030da:	41a68693          	addi	a3,a3,1050 # ffffffffc02054f0 <etext+0x15c4>
ffffffffc02030de:	00002617          	auipc	a2,0x2
ffffffffc02030e2:	82260613          	addi	a2,a2,-2014 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02030e6:	0fd00593          	li	a1,253
ffffffffc02030ea:	00002517          	auipc	a0,0x2
ffffffffc02030ee:	2a650513          	addi	a0,a0,678 # ffffffffc0205390 <etext+0x1464>
ffffffffc02030f2:	b14fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc02030f6:	00002697          	auipc	a3,0x2
ffffffffc02030fa:	3ca68693          	addi	a3,a3,970 # ffffffffc02054c0 <etext+0x1594>
ffffffffc02030fe:	00002617          	auipc	a2,0x2
ffffffffc0203102:	80260613          	addi	a2,a2,-2046 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0203106:	0fc00593          	li	a1,252
ffffffffc020310a:	00002517          	auipc	a0,0x2
ffffffffc020310e:	28650513          	addi	a0,a0,646 # ffffffffc0205390 <etext+0x1464>
ffffffffc0203112:	af4fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma5 == NULL);
ffffffffc0203116:	00002697          	auipc	a3,0x2
ffffffffc020311a:	39a68693          	addi	a3,a3,922 # ffffffffc02054b0 <etext+0x1584>
ffffffffc020311e:	00001617          	auipc	a2,0x1
ffffffffc0203122:	7e260613          	addi	a2,a2,2018 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0203126:	0fa00593          	li	a1,250
ffffffffc020312a:	00002517          	auipc	a0,0x2
ffffffffc020312e:	26650513          	addi	a0,a0,614 # ffffffffc0205390 <etext+0x1464>
ffffffffc0203132:	ad4fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma4 == NULL);
ffffffffc0203136:	00002697          	auipc	a3,0x2
ffffffffc020313a:	36a68693          	addi	a3,a3,874 # ffffffffc02054a0 <etext+0x1574>
ffffffffc020313e:	00001617          	auipc	a2,0x1
ffffffffc0203142:	7c260613          	addi	a2,a2,1986 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0203146:	0f800593          	li	a1,248
ffffffffc020314a:	00002517          	auipc	a0,0x2
ffffffffc020314e:	24650513          	addi	a0,a0,582 # ffffffffc0205390 <etext+0x1464>
ffffffffc0203152:	ab4fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma3 == NULL);
ffffffffc0203156:	00002697          	auipc	a3,0x2
ffffffffc020315a:	33a68693          	addi	a3,a3,826 # ffffffffc0205490 <etext+0x1564>
ffffffffc020315e:	00001617          	auipc	a2,0x1
ffffffffc0203162:	7a260613          	addi	a2,a2,1954 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0203166:	0f600593          	li	a1,246
ffffffffc020316a:	00002517          	auipc	a0,0x2
ffffffffc020316e:	22650513          	addi	a0,a0,550 # ffffffffc0205390 <etext+0x1464>
ffffffffc0203172:	a94fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203176:	00002697          	auipc	a3,0x2
ffffffffc020317a:	2aa68693          	addi	a3,a3,682 # ffffffffc0205420 <etext+0x14f4>
ffffffffc020317e:	00001617          	auipc	a2,0x1
ffffffffc0203182:	78260613          	addi	a2,a2,1922 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0203186:	0e900593          	li	a1,233
ffffffffc020318a:	00002517          	auipc	a0,0x2
ffffffffc020318e:	20650513          	addi	a0,a0,518 # ffffffffc0205390 <etext+0x1464>
ffffffffc0203192:	a74fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma2 != NULL);
ffffffffc0203196:	00002697          	auipc	a3,0x2
ffffffffc020319a:	2ea68693          	addi	a3,a3,746 # ffffffffc0205480 <etext+0x1554>
ffffffffc020319e:	00001617          	auipc	a2,0x1
ffffffffc02031a2:	76260613          	addi	a2,a2,1890 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02031a6:	0f400593          	li	a1,244
ffffffffc02031aa:	00002517          	auipc	a0,0x2
ffffffffc02031ae:	1e650513          	addi	a0,a0,486 # ffffffffc0205390 <etext+0x1464>
ffffffffc02031b2:	a54fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma1 != NULL);
ffffffffc02031b6:	00002697          	auipc	a3,0x2
ffffffffc02031ba:	2ba68693          	addi	a3,a3,698 # ffffffffc0205470 <etext+0x1544>
ffffffffc02031be:	00001617          	auipc	a2,0x1
ffffffffc02031c2:	74260613          	addi	a2,a2,1858 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02031c6:	0f200593          	li	a1,242
ffffffffc02031ca:	00002517          	auipc	a0,0x2
ffffffffc02031ce:	1c650513          	addi	a0,a0,454 # ffffffffc0205390 <etext+0x1464>
ffffffffc02031d2:	a34fd0ef          	jal	ffffffffc0200406 <__panic>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc02031d6:	6914                	ld	a3,16(a0)
ffffffffc02031d8:	6510                	ld	a2,8(a0)
ffffffffc02031da:	0004859b          	sext.w	a1,s1
ffffffffc02031de:	00002517          	auipc	a0,0x2
ffffffffc02031e2:	34250513          	addi	a0,a0,834 # ffffffffc0205520 <etext+0x15f4>
ffffffffc02031e6:	faffc0ef          	jal	ffffffffc0200194 <cprintf>
        assert(vma_below_5 == NULL);
ffffffffc02031ea:	00002697          	auipc	a3,0x2
ffffffffc02031ee:	35e68693          	addi	a3,a3,862 # ffffffffc0205548 <etext+0x161c>
ffffffffc02031f2:	00001617          	auipc	a2,0x1
ffffffffc02031f6:	70e60613          	addi	a2,a2,1806 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02031fa:	10700593          	li	a1,263
ffffffffc02031fe:	00002517          	auipc	a0,0x2
ffffffffc0203202:	19250513          	addi	a0,a0,402 # ffffffffc0205390 <etext+0x1464>
ffffffffc0203206:	a00fd0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc020320a <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc020320a:	8526                	mv	a0,s1
	jalr s0
ffffffffc020320c:	9402                	jalr	s0

	jal do_exit
ffffffffc020320e:	47c000ef          	jal	ffffffffc020368a <do_exit>

ffffffffc0203212 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203212:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203214:	0e800513          	li	a0,232
{
ffffffffc0203218:	e022                	sd	s0,0(sp)
ffffffffc020321a:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc020321c:	885fe0ef          	jal	ffffffffc0201aa0 <kmalloc>
ffffffffc0203220:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203222:	c521                	beqz	a0,ffffffffc020326a <alloc_proc+0x58>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        proc->state = PROC_UNINIT;      
ffffffffc0203224:	57fd                	li	a5,-1
ffffffffc0203226:	1782                	slli	a5,a5,0x20
ffffffffc0203228:	e11c                	sd	a5,0(a0)
        proc->pid = -1;                 
        proc->runs = 0;               
ffffffffc020322a:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;               
ffffffffc020322e:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;         
ffffffffc0203232:	00052c23          	sw	zero,24(a0)
        proc->parent = NULL;            
ffffffffc0203236:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;                
ffffffffc020323a:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context)); 
ffffffffc020323e:	07000613          	li	a2,112
ffffffffc0203242:	4581                	li	a1,0
ffffffffc0203244:	03050513          	addi	a0,a0,48
ffffffffc0203248:	497000ef          	jal	ffffffffc0203ede <memset>
        proc->tf = NULL;               
        proc->pgdir = boot_pgdir_pa;    
ffffffffc020324c:	0000a797          	auipc	a5,0xa
ffffffffc0203250:	25c7b783          	ld	a5,604(a5) # ffffffffc020d4a8 <boot_pgdir_pa>
        proc->tf = NULL;               
ffffffffc0203254:	0a043023          	sd	zero,160(s0) # ffffffffc02000a0 <kern_init+0x56>
        proc->flags = 0;                
ffffffffc0203258:	0a042823          	sw	zero,176(s0)
        proc->pgdir = boot_pgdir_pa;    
ffffffffc020325c:	f45c                	sd	a5,168(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);
ffffffffc020325e:	0b440513          	addi	a0,s0,180
ffffffffc0203262:	4641                	li	a2,16
ffffffffc0203264:	4581                	li	a1,0
ffffffffc0203266:	479000ef          	jal	ffffffffc0203ede <memset>
    }
    return proc;
}
ffffffffc020326a:	60a2                	ld	ra,8(sp)
ffffffffc020326c:	8522                	mv	a0,s0
ffffffffc020326e:	6402                	ld	s0,0(sp)
ffffffffc0203270:	0141                	addi	sp,sp,16
ffffffffc0203272:	8082                	ret

ffffffffc0203274 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203274:	0000a797          	auipc	a5,0xa
ffffffffc0203278:	26c7b783          	ld	a5,620(a5) # ffffffffc020d4e0 <current>
ffffffffc020327c:	73c8                	ld	a0,160(a5)
ffffffffc020327e:	aabfd06f          	j	ffffffffc0200d28 <forkrets>

ffffffffc0203282 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0203282:	1101                	addi	sp,sp,-32
ffffffffc0203284:	e822                	sd	s0,16(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc0203286:	0000a417          	auipc	s0,0xa
ffffffffc020328a:	25a43403          	ld	s0,602(s0) # ffffffffc020d4e0 <current>
{
ffffffffc020328e:	e04a                	sd	s2,0(sp)
    memset(name, 0, sizeof(name));
ffffffffc0203290:	4641                	li	a2,16
{
ffffffffc0203292:	892a                	mv	s2,a0
    memset(name, 0, sizeof(name));
ffffffffc0203294:	4581                	li	a1,0
ffffffffc0203296:	00006517          	auipc	a0,0x6
ffffffffc020329a:	1b250513          	addi	a0,a0,434 # ffffffffc0209448 <name.2>
{
ffffffffc020329e:	ec06                	sd	ra,24(sp)
ffffffffc02032a0:	e426                	sd	s1,8(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02032a2:	4044                	lw	s1,4(s0)
    memset(name, 0, sizeof(name));
ffffffffc02032a4:	43b000ef          	jal	ffffffffc0203ede <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc02032a8:	0b440593          	addi	a1,s0,180
ffffffffc02032ac:	463d                	li	a2,15
ffffffffc02032ae:	00006517          	auipc	a0,0x6
ffffffffc02032b2:	19a50513          	addi	a0,a0,410 # ffffffffc0209448 <name.2>
ffffffffc02032b6:	43b000ef          	jal	ffffffffc0203ef0 <memcpy>
ffffffffc02032ba:	862a                	mv	a2,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02032bc:	85a6                	mv	a1,s1
ffffffffc02032be:	00002517          	auipc	a0,0x2
ffffffffc02032c2:	2da50513          	addi	a0,a0,730 # ffffffffc0205598 <etext+0x166c>
ffffffffc02032c6:	ecffc0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg);
ffffffffc02032ca:	85ca                	mv	a1,s2
ffffffffc02032cc:	00002517          	auipc	a0,0x2
ffffffffc02032d0:	2f450513          	addi	a0,a0,756 # ffffffffc02055c0 <etext+0x1694>
ffffffffc02032d4:	ec1fc0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
ffffffffc02032d8:	00002517          	auipc	a0,0x2
ffffffffc02032dc:	2f850513          	addi	a0,a0,760 # ffffffffc02055d0 <etext+0x16a4>
ffffffffc02032e0:	eb5fc0ef          	jal	ffffffffc0200194 <cprintf>
    /* print kernel thread creation/run statistics */
    cprintf("[kthread stats] created=%d, run_first_time=%d\n", created_kthreads, run_kthreads);
ffffffffc02032e4:	0000a617          	auipc	a2,0xa
ffffffffc02032e8:	1ec62603          	lw	a2,492(a2) # ffffffffc020d4d0 <run_kthreads>
ffffffffc02032ec:	0000a597          	auipc	a1,0xa
ffffffffc02032f0:	1e85a583          	lw	a1,488(a1) # ffffffffc020d4d4 <created_kthreads>
ffffffffc02032f4:	00002517          	auipc	a0,0x2
ffffffffc02032f8:	2fc50513          	addi	a0,a0,764 # ffffffffc02055f0 <etext+0x16c4>
ffffffffc02032fc:	e99fc0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc0203300:	60e2                	ld	ra,24(sp)
ffffffffc0203302:	6442                	ld	s0,16(sp)
ffffffffc0203304:	64a2                	ld	s1,8(sp)
ffffffffc0203306:	6902                	ld	s2,0(sp)
ffffffffc0203308:	4501                	li	a0,0
ffffffffc020330a:	6105                	addi	sp,sp,32
ffffffffc020330c:	8082                	ret

ffffffffc020330e <proc_run>:
    if (proc != current)
ffffffffc020330e:	0000a697          	auipc	a3,0xa
ffffffffc0203312:	1d26b683          	ld	a3,466(a3) # ffffffffc020d4e0 <current>
ffffffffc0203316:	06a68563          	beq	a3,a0,ffffffffc0203380 <proc_run+0x72>
{
ffffffffc020331a:	1101                	addi	sp,sp,-32
ffffffffc020331c:	ec06                	sd	ra,24(sp)
ffffffffc020331e:	87aa                	mv	a5,a0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203320:	10002773          	csrr	a4,sstatus
ffffffffc0203324:	8b09                	andi	a4,a4,2
    return 0;
ffffffffc0203326:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203328:	eb2d                	bnez	a4,ffffffffc020339a <proc_run+0x8c>
        if (proc->tf && proc->tf->epc == (uintptr_t)kernel_thread_entry && proc->runs == 0)
ffffffffc020332a:	73d8                	ld	a4,160(a5)
        current = proc;
ffffffffc020332c:	0000a597          	auipc	a1,0xa
ffffffffc0203330:	1af5ba23          	sd	a5,436(a1) # ffffffffc020d4e0 <current>
        if (proc->tf && proc->tf->epc == (uintptr_t)kernel_thread_entry && proc->runs == 0)
ffffffffc0203334:	cb09                	beqz	a4,ffffffffc0203346 <proc_run+0x38>
ffffffffc0203336:	10873583          	ld	a1,264(a4)
ffffffffc020333a:	00000717          	auipc	a4,0x0
ffffffffc020333e:	ed070713          	addi	a4,a4,-304 # ffffffffc020320a <kernel_thread_entry>
ffffffffc0203342:	04e58063          	beq	a1,a4,ffffffffc0203382 <proc_run+0x74>
        lsatp(proc->pgdir);
ffffffffc0203346:	77d8                	ld	a4,168(a5)
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned int pgdir)
{
  write_csr(satp, SATP32_MODE | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203348:	800005b7          	lui	a1,0x80000
ffffffffc020334c:	e432                	sd	a2,8(sp)
ffffffffc020334e:	00c7571b          	srliw	a4,a4,0xc
ffffffffc0203352:	8f4d                	or	a4,a4,a1
ffffffffc0203354:	18071073          	csrw	satp,a4
        switch_to(&prev->context, &proc->context);
ffffffffc0203358:	03078593          	addi	a1,a5,48
ffffffffc020335c:	03068513          	addi	a0,a3,48
ffffffffc0203360:	e03e                	sd	a5,0(sp)
ffffffffc0203362:	5b6000ef          	jal	ffffffffc0203918 <switch_to>
        proc->runs++;
ffffffffc0203366:	6782                	ld	a5,0(sp)
    if (flag) {
ffffffffc0203368:	6622                	ld	a2,8(sp)
ffffffffc020336a:	4798                	lw	a4,8(a5)
ffffffffc020336c:	2705                	addiw	a4,a4,1
ffffffffc020336e:	c798                	sw	a4,8(a5)
ffffffffc0203370:	e601                	bnez	a2,ffffffffc0203378 <proc_run+0x6a>
}
ffffffffc0203372:	60e2                	ld	ra,24(sp)
ffffffffc0203374:	6105                	addi	sp,sp,32
ffffffffc0203376:	8082                	ret
ffffffffc0203378:	60e2                	ld	ra,24(sp)
ffffffffc020337a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020337c:	cf2fd06f          	j	ffffffffc020086e <intr_enable>
ffffffffc0203380:	8082                	ret
        if (proc->tf && proc->tf->epc == (uintptr_t)kernel_thread_entry && proc->runs == 0)
ffffffffc0203382:	4798                	lw	a4,8(a5)
ffffffffc0203384:	f369                	bnez	a4,ffffffffc0203346 <proc_run+0x38>
            run_kthreads++;
ffffffffc0203386:	0000a717          	auipc	a4,0xa
ffffffffc020338a:	14a72703          	lw	a4,330(a4) # ffffffffc020d4d0 <run_kthreads>
ffffffffc020338e:	2705                	addiw	a4,a4,1
ffffffffc0203390:	0000a597          	auipc	a1,0xa
ffffffffc0203394:	14e5a023          	sw	a4,320(a1) # ffffffffc020d4d0 <run_kthreads>
ffffffffc0203398:	b77d                	j	ffffffffc0203346 <proc_run+0x38>
ffffffffc020339a:	e036                	sd	a3,0(sp)
        intr_disable();
ffffffffc020339c:	e42a                	sd	a0,8(sp)
ffffffffc020339e:	cd6fd0ef          	jal	ffffffffc0200874 <intr_disable>
        return 1;
ffffffffc02033a2:	67a2                	ld	a5,8(sp)
ffffffffc02033a4:	6682                	ld	a3,0(sp)
ffffffffc02033a6:	4605                	li	a2,1
ffffffffc02033a8:	b749                	j	ffffffffc020332a <proc_run+0x1c>

ffffffffc02033aa <do_fork>:
    if (nr_process >= MAX_PROCESS)
ffffffffc02033aa:	0000a717          	auipc	a4,0xa
ffffffffc02033ae:	12e72703          	lw	a4,302(a4) # ffffffffc020d4d8 <nr_process>
ffffffffc02033b2:	6785                	lui	a5,0x1
ffffffffc02033b4:	24f75563          	bge	a4,a5,ffffffffc02035fe <do_fork+0x254>
{
ffffffffc02033b8:	7179                	addi	sp,sp,-48
ffffffffc02033ba:	f022                	sd	s0,32(sp)
ffffffffc02033bc:	ec26                	sd	s1,24(sp)
ffffffffc02033be:	e84a                	sd	s2,16(sp)
ffffffffc02033c0:	f406                	sd	ra,40(sp)
ffffffffc02033c2:	8432                	mv	s0,a2
ffffffffc02033c4:	84ae                	mv	s1,a1
    if ((proc = alloc_proc()) == NULL) {
ffffffffc02033c6:	e4dff0ef          	jal	ffffffffc0203212 <alloc_proc>
ffffffffc02033ca:	892a                	mv	s2,a0
ffffffffc02033cc:	22050763          	beqz	a0,ffffffffc02035fa <do_fork+0x250>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc02033d0:	4509                	li	a0,2
ffffffffc02033d2:	891fe0ef          	jal	ffffffffc0201c62 <alloc_pages>
    if (page != NULL)
ffffffffc02033d6:	20050f63          	beqz	a0,ffffffffc02035f4 <do_fork+0x24a>
    return page - pages + nbase;
ffffffffc02033da:	0000a697          	auipc	a3,0xa
ffffffffc02033de:	0ee6b683          	ld	a3,238(a3) # ffffffffc020d4c8 <pages>
ffffffffc02033e2:	00002797          	auipc	a5,0x2
ffffffffc02033e6:	6ce7b783          	ld	a5,1742(a5) # ffffffffc0205ab0 <nbase>
    return KADDR(page2pa(page));
ffffffffc02033ea:	0000a717          	auipc	a4,0xa
ffffffffc02033ee:	0d673703          	ld	a4,214(a4) # ffffffffc020d4c0 <npage>
    return page - pages + nbase;
ffffffffc02033f2:	40d506b3          	sub	a3,a0,a3
ffffffffc02033f6:	8699                	srai	a3,a3,0x6
ffffffffc02033f8:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02033fa:	00c69793          	slli	a5,a3,0xc
ffffffffc02033fe:	e44e                	sd	s3,8(sp)
ffffffffc0203400:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0203402:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203404:	20e7ff63          	bgeu	a5,a4,ffffffffc0203622 <do_fork+0x278>
    assert(current->mm == NULL);
ffffffffc0203408:	0000a797          	auipc	a5,0xa
ffffffffc020340c:	0d87b783          	ld	a5,216(a5) # ffffffffc020d4e0 <current>
ffffffffc0203410:	0000a717          	auipc	a4,0xa
ffffffffc0203414:	0a873703          	ld	a4,168(a4) # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0203418:	779c                	ld	a5,40(a5)
ffffffffc020341a:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc020341c:	00d93823          	sd	a3,16(s2)
    assert(current->mm == NULL);
ffffffffc0203420:	1e079163          	bnez	a5,ffffffffc0203602 <do_fork+0x258>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0203424:	6789                	lui	a5,0x2
ffffffffc0203426:	ee078793          	addi	a5,a5,-288 # 1ee0 <kern_entry-0xffffffffc01fe120>
ffffffffc020342a:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc020342c:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc020342e:	0ad93023          	sd	a3,160(s2)
    *(proc->tf) = *tf;
ffffffffc0203432:	87b6                	mv	a5,a3
ffffffffc0203434:	12040713          	addi	a4,s0,288
ffffffffc0203438:	6a0c                	ld	a1,16(a2)
ffffffffc020343a:	00063803          	ld	a6,0(a2)
ffffffffc020343e:	6608                	ld	a0,8(a2)
ffffffffc0203440:	eb8c                	sd	a1,16(a5)
ffffffffc0203442:	0107b023          	sd	a6,0(a5)
ffffffffc0203446:	e788                	sd	a0,8(a5)
ffffffffc0203448:	6e0c                	ld	a1,24(a2)
ffffffffc020344a:	02060613          	addi	a2,a2,32
ffffffffc020344e:	02078793          	addi	a5,a5,32
ffffffffc0203452:	feb7bc23          	sd	a1,-8(a5)
ffffffffc0203456:	fee611e3          	bne	a2,a4,ffffffffc0203438 <do_fork+0x8e>
    proc->tf->gpr.a0 = 0;
ffffffffc020345a:	0406b823          	sd	zero,80(a3)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020345e:	87b6                	mv	a5,a3
ffffffffc0203460:	12049c63          	bnez	s1,ffffffffc0203598 <do_fork+0x1ee>
ffffffffc0203464:	ea9c                	sd	a5,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203466:	00000797          	auipc	a5,0x0
ffffffffc020346a:	e0e78793          	addi	a5,a5,-498 # ffffffffc0203274 <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc020346e:	02d93c23          	sd	a3,56(s2)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203472:	02f93823          	sd	a5,48(s2)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203476:	100027f3          	csrr	a5,sstatus
ffffffffc020347a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020347c:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020347e:	12079d63          	bnez	a5,ffffffffc02035b8 <do_fork+0x20e>
    if (++last_pid >= MAX_PID)
ffffffffc0203482:	00006517          	auipc	a0,0x6
ffffffffc0203486:	baa52503          	lw	a0,-1110(a0) # ffffffffc020902c <last_pid.1>
ffffffffc020348a:	6789                	lui	a5,0x2
ffffffffc020348c:	2505                	addiw	a0,a0,1
ffffffffc020348e:	00006717          	auipc	a4,0x6
ffffffffc0203492:	b8a72f23          	sw	a0,-1122(a4) # ffffffffc020902c <last_pid.1>
ffffffffc0203496:	14f55063          	bge	a0,a5,ffffffffc02035d6 <do_fork+0x22c>
    if (last_pid >= next_safe)
ffffffffc020349a:	00006797          	auipc	a5,0x6
ffffffffc020349e:	b8e7a783          	lw	a5,-1138(a5) # ffffffffc0209028 <next_safe.0>
ffffffffc02034a2:	0000a417          	auipc	s0,0xa
ffffffffc02034a6:	fb640413          	addi	s0,s0,-74 # ffffffffc020d458 <proc_list>
ffffffffc02034aa:	06f54563          	blt	a0,a5,ffffffffc0203514 <do_fork+0x16a>
ffffffffc02034ae:	0000a417          	auipc	s0,0xa
ffffffffc02034b2:	faa40413          	addi	s0,s0,-86 # ffffffffc020d458 <proc_list>
ffffffffc02034b6:	00843883          	ld	a7,8(s0)
        next_safe = MAX_PID;
ffffffffc02034ba:	6789                	lui	a5,0x2
ffffffffc02034bc:	00006717          	auipc	a4,0x6
ffffffffc02034c0:	b6f72623          	sw	a5,-1172(a4) # ffffffffc0209028 <next_safe.0>
ffffffffc02034c4:	86aa                	mv	a3,a0
ffffffffc02034c6:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc02034c8:	04888063          	beq	a7,s0,ffffffffc0203508 <do_fork+0x15e>
ffffffffc02034cc:	882e                	mv	a6,a1
ffffffffc02034ce:	87c6                	mv	a5,a7
ffffffffc02034d0:	6609                	lui	a2,0x2
ffffffffc02034d2:	a811                	j	ffffffffc02034e6 <do_fork+0x13c>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02034d4:	00e6d663          	bge	a3,a4,ffffffffc02034e0 <do_fork+0x136>
ffffffffc02034d8:	00c75463          	bge	a4,a2,ffffffffc02034e0 <do_fork+0x136>
                next_safe = proc->pid;
ffffffffc02034dc:	863a                	mv	a2,a4
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02034de:	4805                	li	a6,1
ffffffffc02034e0:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02034e2:	00878d63          	beq	a5,s0,ffffffffc02034fc <do_fork+0x152>
            if (proc->pid == last_pid)
ffffffffc02034e6:	f3c7a703          	lw	a4,-196(a5) # 1f3c <kern_entry-0xffffffffc01fe0c4>
ffffffffc02034ea:	fed715e3          	bne	a4,a3,ffffffffc02034d4 <do_fork+0x12a>
                if (++last_pid >= next_safe)
ffffffffc02034ee:	2685                	addiw	a3,a3,1
ffffffffc02034f0:	0ec6dc63          	bge	a3,a2,ffffffffc02035e8 <do_fork+0x23e>
ffffffffc02034f4:	679c                	ld	a5,8(a5)
ffffffffc02034f6:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02034f8:	fe8797e3          	bne	a5,s0,ffffffffc02034e6 <do_fork+0x13c>
ffffffffc02034fc:	00080663          	beqz	a6,ffffffffc0203508 <do_fork+0x15e>
ffffffffc0203500:	00006797          	auipc	a5,0x6
ffffffffc0203504:	b2c7a423          	sw	a2,-1240(a5) # ffffffffc0209028 <next_safe.0>
ffffffffc0203508:	c591                	beqz	a1,ffffffffc0203514 <do_fork+0x16a>
ffffffffc020350a:	00006797          	auipc	a5,0x6
ffffffffc020350e:	b2d7a123          	sw	a3,-1246(a5) # ffffffffc020902c <last_pid.1>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0203512:	8536                	mv	a0,a3
        proc->pid = get_pid();           // 为进程分配唯一pid
ffffffffc0203514:	00a92223          	sw	a0,4(s2)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0203518:	45a9                	li	a1,10
ffffffffc020351a:	52e000ef          	jal	ffffffffc0203a48 <hash32>
ffffffffc020351e:	02051793          	slli	a5,a0,0x20
ffffffffc0203522:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0203526:	00006797          	auipc	a5,0x6
ffffffffc020352a:	f3278793          	addi	a5,a5,-206 # ffffffffc0209458 <hash_list>
ffffffffc020352e:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0203530:	6510                	ld	a2,8(a0)
ffffffffc0203532:	0d890793          	addi	a5,s2,216
ffffffffc0203536:	6414                	ld	a3,8(s0)
        nr_process++;                    // 增加进程计数
ffffffffc0203538:	0000a717          	auipc	a4,0xa
ffffffffc020353c:	fa072703          	lw	a4,-96(a4) # ffffffffc020d4d8 <nr_process>
    prev->next = next->prev = elm;
ffffffffc0203540:	e21c                	sd	a5,0(a2)
ffffffffc0203542:	e51c                	sd	a5,8(a0)
    elm->next = next;
ffffffffc0203544:	0ec93023          	sd	a2,224(s2)
    elm->prev = prev;
ffffffffc0203548:	0ca93c23          	sd	a0,216(s2)
        list_add(&proc_list, &(proc->list_link));  // 加入进程链表
ffffffffc020354c:	0c890613          	addi	a2,s2,200
    prev->next = next->prev = elm;
ffffffffc0203550:	e290                	sd	a2,0(a3)
        nr_process++;                    // 增加进程计数
ffffffffc0203552:	0017079b          	addiw	a5,a4,1
ffffffffc0203556:	e410                	sd	a2,8(s0)
    elm->next = next;
ffffffffc0203558:	0cd93823          	sd	a3,208(s2)
    elm->prev = prev;
ffffffffc020355c:	0c893423          	sd	s0,200(s2)
ffffffffc0203560:	0000a717          	auipc	a4,0xa
ffffffffc0203564:	f6f72c23          	sw	a5,-136(a4) # ffffffffc020d4d8 <nr_process>
        if (stack == 0)
ffffffffc0203568:	e891                	bnez	s1,ffffffffc020357c <do_fork+0x1d2>
            created_kthreads++;
ffffffffc020356a:	0000a797          	auipc	a5,0xa
ffffffffc020356e:	f6a7a783          	lw	a5,-150(a5) # ffffffffc020d4d4 <created_kthreads>
ffffffffc0203572:	2785                	addiw	a5,a5,1
ffffffffc0203574:	0000a717          	auipc	a4,0xa
ffffffffc0203578:	f6f72023          	sw	a5,-160(a4) # ffffffffc020d4d4 <created_kthreads>
    if (flag) {
ffffffffc020357c:	06099363          	bnez	s3,ffffffffc02035e2 <do_fork+0x238>
    wakeup_proc(proc);
ffffffffc0203580:	854a                	mv	a0,s2
ffffffffc0203582:	400000ef          	jal	ffffffffc0203982 <wakeup_proc>
    ret = proc->pid;
ffffffffc0203586:	00492503          	lw	a0,4(s2)
ffffffffc020358a:	69a2                	ld	s3,8(sp)
}
ffffffffc020358c:	70a2                	ld	ra,40(sp)
ffffffffc020358e:	7402                	ld	s0,32(sp)
ffffffffc0203590:	64e2                	ld	s1,24(sp)
ffffffffc0203592:	6942                	ld	s2,16(sp)
ffffffffc0203594:	6145                	addi	sp,sp,48
ffffffffc0203596:	8082                	ret
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203598:	87a6                	mv	a5,s1
ffffffffc020359a:	ea9c                	sd	a5,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020359c:	00000797          	auipc	a5,0x0
ffffffffc02035a0:	cd878793          	addi	a5,a5,-808 # ffffffffc0203274 <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02035a4:	02d93c23          	sd	a3,56(s2)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02035a8:	02f93823          	sd	a5,48(s2)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02035ac:	100027f3          	csrr	a5,sstatus
ffffffffc02035b0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02035b2:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02035b4:	ec0787e3          	beqz	a5,ffffffffc0203482 <do_fork+0xd8>
        intr_disable();
ffffffffc02035b8:	abcfd0ef          	jal	ffffffffc0200874 <intr_disable>
    if (++last_pid >= MAX_PID)
ffffffffc02035bc:	00006517          	auipc	a0,0x6
ffffffffc02035c0:	a7052503          	lw	a0,-1424(a0) # ffffffffc020902c <last_pid.1>
ffffffffc02035c4:	6789                	lui	a5,0x2
        return 1;
ffffffffc02035c6:	4985                	li	s3,1
ffffffffc02035c8:	2505                	addiw	a0,a0,1
ffffffffc02035ca:	00006717          	auipc	a4,0x6
ffffffffc02035ce:	a6a72123          	sw	a0,-1438(a4) # ffffffffc020902c <last_pid.1>
ffffffffc02035d2:	ecf544e3          	blt	a0,a5,ffffffffc020349a <do_fork+0xf0>
        last_pid = 1;
ffffffffc02035d6:	4505                	li	a0,1
ffffffffc02035d8:	00006797          	auipc	a5,0x6
ffffffffc02035dc:	a4a7aa23          	sw	a0,-1452(a5) # ffffffffc020902c <last_pid.1>
        goto inside;
ffffffffc02035e0:	b5f9                	j	ffffffffc02034ae <do_fork+0x104>
        intr_enable();
ffffffffc02035e2:	a8cfd0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02035e6:	bf69                	j	ffffffffc0203580 <do_fork+0x1d6>
                    if (last_pid >= MAX_PID)
ffffffffc02035e8:	6789                	lui	a5,0x2
ffffffffc02035ea:	00f6c363          	blt	a3,a5,ffffffffc02035f0 <do_fork+0x246>
                        last_pid = 1;
ffffffffc02035ee:	4685                	li	a3,1
                    goto repeat;
ffffffffc02035f0:	4585                	li	a1,1
ffffffffc02035f2:	bdd9                	j	ffffffffc02034c8 <do_fork+0x11e>
        kfree(proc);         // 释放进程控制块
ffffffffc02035f4:	854a                	mv	a0,s2
ffffffffc02035f6:	d50fe0ef          	jal	ffffffffc0201b46 <kfree>
    ret = -E_NO_MEM;
ffffffffc02035fa:	5571                	li	a0,-4
ffffffffc02035fc:	bf41                	j	ffffffffc020358c <do_fork+0x1e2>
    int ret = -E_NO_FREE_PROC;
ffffffffc02035fe:	556d                	li	a0,-5
}
ffffffffc0203600:	8082                	ret
    assert(current->mm == NULL);
ffffffffc0203602:	00002697          	auipc	a3,0x2
ffffffffc0203606:	01e68693          	addi	a3,a3,30 # ffffffffc0205620 <etext+0x16f4>
ffffffffc020360a:	00001617          	auipc	a2,0x1
ffffffffc020360e:	2f660613          	addi	a2,a2,758 # ffffffffc0204900 <etext+0x9d4>
ffffffffc0203612:	13000593          	li	a1,304
ffffffffc0203616:	00002517          	auipc	a0,0x2
ffffffffc020361a:	02250513          	addi	a0,a0,34 # ffffffffc0205638 <etext+0x170c>
ffffffffc020361e:	de9fc0ef          	jal	ffffffffc0200406 <__panic>
ffffffffc0203622:	00001617          	auipc	a2,0x1
ffffffffc0203626:	68e60613          	addi	a2,a2,1678 # ffffffffc0204cb0 <etext+0xd84>
ffffffffc020362a:	07100593          	li	a1,113
ffffffffc020362e:	00001517          	auipc	a0,0x1
ffffffffc0203632:	6aa50513          	addi	a0,a0,1706 # ffffffffc0204cd8 <etext+0xdac>
ffffffffc0203636:	dd1fc0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc020363a <kernel_thread>:
{
ffffffffc020363a:	7129                	addi	sp,sp,-320
ffffffffc020363c:	fa22                	sd	s0,304(sp)
ffffffffc020363e:	f626                	sd	s1,296(sp)
ffffffffc0203640:	f24a                	sd	s2,288(sp)
ffffffffc0203642:	842a                	mv	s0,a0
ffffffffc0203644:	84ae                	mv	s1,a1
ffffffffc0203646:	8932                	mv	s2,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0203648:	850a                	mv	a0,sp
ffffffffc020364a:	12000613          	li	a2,288
ffffffffc020364e:	4581                	li	a1,0
{
ffffffffc0203650:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0203652:	08d000ef          	jal	ffffffffc0203ede <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0203656:	e0a2                	sd	s0,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0203658:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc020365a:	100027f3          	csrr	a5,sstatus
ffffffffc020365e:	edd7f793          	andi	a5,a5,-291
ffffffffc0203662:	1207e793          	ori	a5,a5,288
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0203666:	860a                	mv	a2,sp
ffffffffc0203668:	10096513          	ori	a0,s2,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020366c:	00000717          	auipc	a4,0x0
ffffffffc0203670:	b9e70713          	addi	a4,a4,-1122 # ffffffffc020320a <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0203674:	4581                	li	a1,0
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0203676:	e23e                	sd	a5,256(sp)
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0203678:	e63a                	sd	a4,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020367a:	d31ff0ef          	jal	ffffffffc02033aa <do_fork>
}
ffffffffc020367e:	70f2                	ld	ra,312(sp)
ffffffffc0203680:	7452                	ld	s0,304(sp)
ffffffffc0203682:	74b2                	ld	s1,296(sp)
ffffffffc0203684:	7912                	ld	s2,288(sp)
ffffffffc0203686:	6131                	addi	sp,sp,320
ffffffffc0203688:	8082                	ret

ffffffffc020368a <do_exit>:
{
ffffffffc020368a:	1141                	addi	sp,sp,-16
    panic("process exit!!.\n");
ffffffffc020368c:	00002617          	auipc	a2,0x2
ffffffffc0203690:	fc460613          	addi	a2,a2,-60 # ffffffffc0205650 <etext+0x1724>
ffffffffc0203694:	19d00593          	li	a1,413
ffffffffc0203698:	00002517          	auipc	a0,0x2
ffffffffc020369c:	fa050513          	addi	a0,a0,-96 # ffffffffc0205638 <etext+0x170c>
{
ffffffffc02036a0:	e406                	sd	ra,8(sp)
    panic("process exit!!.\n");
ffffffffc02036a2:	d65fc0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc02036a6 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc02036a6:	7179                	addi	sp,sp,-48
ffffffffc02036a8:	ec26                	sd	s1,24(sp)
    elm->prev = elm->next = elm;
ffffffffc02036aa:	0000a797          	auipc	a5,0xa
ffffffffc02036ae:	dae78793          	addi	a5,a5,-594 # ffffffffc020d458 <proc_list>
ffffffffc02036b2:	f406                	sd	ra,40(sp)
ffffffffc02036b4:	f022                	sd	s0,32(sp)
ffffffffc02036b6:	e84a                	sd	s2,16(sp)
ffffffffc02036b8:	e44e                	sd	s3,8(sp)
ffffffffc02036ba:	00006497          	auipc	s1,0x6
ffffffffc02036be:	d9e48493          	addi	s1,s1,-610 # ffffffffc0209458 <hash_list>
ffffffffc02036c2:	e79c                	sd	a5,8(a5)
ffffffffc02036c4:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc02036c6:	0000a717          	auipc	a4,0xa
ffffffffc02036ca:	d9270713          	addi	a4,a4,-622 # ffffffffc020d458 <proc_list>
ffffffffc02036ce:	87a6                	mv	a5,s1
ffffffffc02036d0:	e79c                	sd	a5,8(a5)
ffffffffc02036d2:	e39c                	sd	a5,0(a5)
ffffffffc02036d4:	07c1                	addi	a5,a5,16
ffffffffc02036d6:	fee79de3          	bne	a5,a4,ffffffffc02036d0 <proc_init+0x2a>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc02036da:	b39ff0ef          	jal	ffffffffc0203212 <alloc_proc>
ffffffffc02036de:	0000a917          	auipc	s2,0xa
ffffffffc02036e2:	e1290913          	addi	s2,s2,-494 # ffffffffc020d4f0 <idleproc>
ffffffffc02036e6:	00a93023          	sd	a0,0(s2)
ffffffffc02036ea:	1a050263          	beqz	a0,ffffffffc020388e <proc_init+0x1e8>
    {
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc02036ee:	07000513          	li	a0,112
ffffffffc02036f2:	baefe0ef          	jal	ffffffffc0201aa0 <kmalloc>
    memset(context_mem, 0, sizeof(struct context));
ffffffffc02036f6:	07000613          	li	a2,112
ffffffffc02036fa:	4581                	li	a1,0
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc02036fc:	842a                	mv	s0,a0
    memset(context_mem, 0, sizeof(struct context));
ffffffffc02036fe:	7e0000ef          	jal	ffffffffc0203ede <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
ffffffffc0203702:	00093503          	ld	a0,0(s2)
ffffffffc0203706:	85a2                	mv	a1,s0
ffffffffc0203708:	07000613          	li	a2,112
ffffffffc020370c:	03050513          	addi	a0,a0,48
ffffffffc0203710:	7f8000ef          	jal	ffffffffc0203f08 <memcmp>
ffffffffc0203714:	89aa                	mv	s3,a0

    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc0203716:	453d                	li	a0,15
ffffffffc0203718:	b88fe0ef          	jal	ffffffffc0201aa0 <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc020371c:	463d                	li	a2,15
ffffffffc020371e:	4581                	li	a1,0
    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc0203720:	842a                	mv	s0,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc0203722:	7bc000ef          	jal	ffffffffc0203ede <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
ffffffffc0203726:	00093503          	ld	a0,0(s2)
ffffffffc020372a:	85a2                	mv	a1,s0
ffffffffc020372c:	463d                	li	a2,15
ffffffffc020372e:	0b450513          	addi	a0,a0,180
ffffffffc0203732:	7d6000ef          	jal	ffffffffc0203f08 <memcmp>

    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc0203736:	00093783          	ld	a5,0(s2)
ffffffffc020373a:	0000a717          	auipc	a4,0xa
ffffffffc020373e:	d6e73703          	ld	a4,-658(a4) # ffffffffc020d4a8 <boot_pgdir_pa>
ffffffffc0203742:	77d4                	ld	a3,168(a5)
ffffffffc0203744:	0ee68863          	beq	a3,a4,ffffffffc0203834 <proc_init+0x18e>
    {
        cprintf("alloc_proc() correct!\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0203748:	4709                	li	a4,2
ffffffffc020374a:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc020374c:	00003717          	auipc	a4,0x3
ffffffffc0203750:	8b470713          	addi	a4,a4,-1868 # ffffffffc0206000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203754:	0b478413          	addi	s0,a5,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0203758:	eb98                	sd	a4,16(a5)
    idleproc->need_resched = 1;
ffffffffc020375a:	4705                	li	a4,1
ffffffffc020375c:	cf98                	sw	a4,24(a5)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020375e:	8522                	mv	a0,s0
ffffffffc0203760:	4641                	li	a2,16
ffffffffc0203762:	4581                	li	a1,0
ffffffffc0203764:	77a000ef          	jal	ffffffffc0203ede <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0203768:	8522                	mv	a0,s0
ffffffffc020376a:	463d                	li	a2,15
ffffffffc020376c:	00002597          	auipc	a1,0x2
ffffffffc0203770:	f2c58593          	addi	a1,a1,-212 # ffffffffc0205698 <etext+0x176c>
ffffffffc0203774:	77c000ef          	jal	ffffffffc0203ef0 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0203778:	0000a797          	auipc	a5,0xa
ffffffffc020377c:	d607a783          	lw	a5,-672(a5) # ffffffffc020d4d8 <nr_process>

    current = idleproc;
ffffffffc0203780:	00093703          	ld	a4,0(s2)

    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc0203784:	4601                	li	a2,0
    nr_process++;
ffffffffc0203786:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc0203788:	00002597          	auipc	a1,0x2
ffffffffc020378c:	f1858593          	addi	a1,a1,-232 # ffffffffc02056a0 <etext+0x1774>
ffffffffc0203790:	00000517          	auipc	a0,0x0
ffffffffc0203794:	af250513          	addi	a0,a0,-1294 # ffffffffc0203282 <init_main>
    current = idleproc;
ffffffffc0203798:	0000a697          	auipc	a3,0xa
ffffffffc020379c:	d4e6b423          	sd	a4,-696(a3) # ffffffffc020d4e0 <current>
    nr_process++;
ffffffffc02037a0:	0000a717          	auipc	a4,0xa
ffffffffc02037a4:	d2f72c23          	sw	a5,-712(a4) # ffffffffc020d4d8 <nr_process>
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02037a8:	e93ff0ef          	jal	ffffffffc020363a <kernel_thread>
ffffffffc02037ac:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc02037ae:	0ea05c63          	blez	a0,ffffffffc02038a6 <proc_init+0x200>
    if (0 < pid && pid < MAX_PID)
ffffffffc02037b2:	6789                	lui	a5,0x2
ffffffffc02037b4:	17f9                	addi	a5,a5,-2 # 1ffe <kern_entry-0xffffffffc01fe002>
ffffffffc02037b6:	fff5071b          	addiw	a4,a0,-1
ffffffffc02037ba:	02e7e463          	bltu	a5,a4,ffffffffc02037e2 <proc_init+0x13c>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02037be:	45a9                	li	a1,10
ffffffffc02037c0:	288000ef          	jal	ffffffffc0203a48 <hash32>
ffffffffc02037c4:	02051713          	slli	a4,a0,0x20
ffffffffc02037c8:	01c75793          	srli	a5,a4,0x1c
ffffffffc02037cc:	00f486b3          	add	a3,s1,a5
ffffffffc02037d0:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc02037d2:	a029                	j	ffffffffc02037dc <proc_init+0x136>
            if (proc->pid == pid)
ffffffffc02037d4:	f2c7a703          	lw	a4,-212(a5)
ffffffffc02037d8:	0a870863          	beq	a4,s0,ffffffffc0203888 <proc_init+0x1e2>
    return listelm->next;
ffffffffc02037dc:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02037de:	fef69be3          	bne	a3,a5,ffffffffc02037d4 <proc_init+0x12e>
    return NULL;
ffffffffc02037e2:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02037e4:	0b478413          	addi	s0,a5,180
ffffffffc02037e8:	4641                	li	a2,16
ffffffffc02037ea:	4581                	li	a1,0
ffffffffc02037ec:	8522                	mv	a0,s0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc02037ee:	0000a717          	auipc	a4,0xa
ffffffffc02037f2:	cef73d23          	sd	a5,-774(a4) # ffffffffc020d4e8 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02037f6:	6e8000ef          	jal	ffffffffc0203ede <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02037fa:	8522                	mv	a0,s0
ffffffffc02037fc:	463d                	li	a2,15
ffffffffc02037fe:	00002597          	auipc	a1,0x2
ffffffffc0203802:	ed258593          	addi	a1,a1,-302 # ffffffffc02056d0 <etext+0x17a4>
ffffffffc0203806:	6ea000ef          	jal	ffffffffc0203ef0 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc020380a:	00093783          	ld	a5,0(s2)
ffffffffc020380e:	cbe1                	beqz	a5,ffffffffc02038de <proc_init+0x238>
ffffffffc0203810:	43dc                	lw	a5,4(a5)
ffffffffc0203812:	e7f1                	bnez	a5,ffffffffc02038de <proc_init+0x238>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0203814:	0000a797          	auipc	a5,0xa
ffffffffc0203818:	cd47b783          	ld	a5,-812(a5) # ffffffffc020d4e8 <initproc>
ffffffffc020381c:	c3cd                	beqz	a5,ffffffffc02038be <proc_init+0x218>
ffffffffc020381e:	43d8                	lw	a4,4(a5)
ffffffffc0203820:	4785                	li	a5,1
ffffffffc0203822:	08f71e63          	bne	a4,a5,ffffffffc02038be <proc_init+0x218>
}
ffffffffc0203826:	70a2                	ld	ra,40(sp)
ffffffffc0203828:	7402                	ld	s0,32(sp)
ffffffffc020382a:	64e2                	ld	s1,24(sp)
ffffffffc020382c:	6942                	ld	s2,16(sp)
ffffffffc020382e:	69a2                	ld	s3,8(sp)
ffffffffc0203830:	6145                	addi	sp,sp,48
ffffffffc0203832:	8082                	ret
    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc0203834:	73d8                	ld	a4,160(a5)
ffffffffc0203836:	f00719e3          	bnez	a4,ffffffffc0203748 <proc_init+0xa2>
ffffffffc020383a:	f00997e3          	bnez	s3,ffffffffc0203748 <proc_init+0xa2>
ffffffffc020383e:	4398                	lw	a4,0(a5)
ffffffffc0203840:	f00714e3          	bnez	a4,ffffffffc0203748 <proc_init+0xa2>
ffffffffc0203844:	43d4                	lw	a3,4(a5)
ffffffffc0203846:	577d                	li	a4,-1
ffffffffc0203848:	f0e690e3          	bne	a3,a4,ffffffffc0203748 <proc_init+0xa2>
ffffffffc020384c:	4798                	lw	a4,8(a5)
ffffffffc020384e:	ee071de3          	bnez	a4,ffffffffc0203748 <proc_init+0xa2>
ffffffffc0203852:	6b98                	ld	a4,16(a5)
ffffffffc0203854:	ee071ae3          	bnez	a4,ffffffffc0203748 <proc_init+0xa2>
ffffffffc0203858:	4f98                	lw	a4,24(a5)
ffffffffc020385a:	ee0717e3          	bnez	a4,ffffffffc0203748 <proc_init+0xa2>
ffffffffc020385e:	7398                	ld	a4,32(a5)
ffffffffc0203860:	ee0714e3          	bnez	a4,ffffffffc0203748 <proc_init+0xa2>
ffffffffc0203864:	7798                	ld	a4,40(a5)
ffffffffc0203866:	ee0711e3          	bnez	a4,ffffffffc0203748 <proc_init+0xa2>
ffffffffc020386a:	0b07a703          	lw	a4,176(a5)
ffffffffc020386e:	8f49                	or	a4,a4,a0
ffffffffc0203870:	2701                	sext.w	a4,a4
ffffffffc0203872:	ec071be3          	bnez	a4,ffffffffc0203748 <proc_init+0xa2>
        cprintf("alloc_proc() correct!\n");
ffffffffc0203876:	00002517          	auipc	a0,0x2
ffffffffc020387a:	e0a50513          	addi	a0,a0,-502 # ffffffffc0205680 <etext+0x1754>
ffffffffc020387e:	917fc0ef          	jal	ffffffffc0200194 <cprintf>
    idleproc->pid = 0;
ffffffffc0203882:	00093783          	ld	a5,0(s2)
ffffffffc0203886:	b5c9                	j	ffffffffc0203748 <proc_init+0xa2>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0203888:	f2878793          	addi	a5,a5,-216
ffffffffc020388c:	bfa1                	j	ffffffffc02037e4 <proc_init+0x13e>
        panic("cannot alloc idleproc.\n");
ffffffffc020388e:	00002617          	auipc	a2,0x2
ffffffffc0203892:	dda60613          	addi	a2,a2,-550 # ffffffffc0205668 <etext+0x173c>
ffffffffc0203896:	1ba00593          	li	a1,442
ffffffffc020389a:	00002517          	auipc	a0,0x2
ffffffffc020389e:	d9e50513          	addi	a0,a0,-610 # ffffffffc0205638 <etext+0x170c>
ffffffffc02038a2:	b65fc0ef          	jal	ffffffffc0200406 <__panic>
        panic("create init_main failed.\n");
ffffffffc02038a6:	00002617          	auipc	a2,0x2
ffffffffc02038aa:	e0a60613          	addi	a2,a2,-502 # ffffffffc02056b0 <etext+0x1784>
ffffffffc02038ae:	1d700593          	li	a1,471
ffffffffc02038b2:	00002517          	auipc	a0,0x2
ffffffffc02038b6:	d8650513          	addi	a0,a0,-634 # ffffffffc0205638 <etext+0x170c>
ffffffffc02038ba:	b4dfc0ef          	jal	ffffffffc0200406 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02038be:	00002697          	auipc	a3,0x2
ffffffffc02038c2:	e4268693          	addi	a3,a3,-446 # ffffffffc0205700 <etext+0x17d4>
ffffffffc02038c6:	00001617          	auipc	a2,0x1
ffffffffc02038ca:	03a60613          	addi	a2,a2,58 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02038ce:	1de00593          	li	a1,478
ffffffffc02038d2:	00002517          	auipc	a0,0x2
ffffffffc02038d6:	d6650513          	addi	a0,a0,-666 # ffffffffc0205638 <etext+0x170c>
ffffffffc02038da:	b2dfc0ef          	jal	ffffffffc0200406 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02038de:	00002697          	auipc	a3,0x2
ffffffffc02038e2:	dfa68693          	addi	a3,a3,-518 # ffffffffc02056d8 <etext+0x17ac>
ffffffffc02038e6:	00001617          	auipc	a2,0x1
ffffffffc02038ea:	01a60613          	addi	a2,a2,26 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02038ee:	1dd00593          	li	a1,477
ffffffffc02038f2:	00002517          	auipc	a0,0x2
ffffffffc02038f6:	d4650513          	addi	a0,a0,-698 # ffffffffc0205638 <etext+0x170c>
ffffffffc02038fa:	b0dfc0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc02038fe <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc02038fe:	1141                	addi	sp,sp,-16
ffffffffc0203900:	e022                	sd	s0,0(sp)
ffffffffc0203902:	e406                	sd	ra,8(sp)
ffffffffc0203904:	0000a417          	auipc	s0,0xa
ffffffffc0203908:	bdc40413          	addi	s0,s0,-1060 # ffffffffc020d4e0 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc020390c:	6018                	ld	a4,0(s0)
ffffffffc020390e:	4f1c                	lw	a5,24(a4)
ffffffffc0203910:	dffd                	beqz	a5,ffffffffc020390e <cpu_idle+0x10>
        {
            schedule();
ffffffffc0203912:	0a2000ef          	jal	ffffffffc02039b4 <schedule>
ffffffffc0203916:	bfdd                	j	ffffffffc020390c <cpu_idle+0xe>

ffffffffc0203918 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0203918:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc020391c:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0203920:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0203922:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0203924:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0203928:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc020392c:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0203930:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0203934:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0203938:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc020393c:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0203940:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0203944:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0203948:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc020394c:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0203950:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0203954:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0203956:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0203958:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc020395c:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0203960:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0203964:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0203968:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc020396c:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0203970:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0203974:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0203978:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc020397c:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0203980:	8082                	ret

ffffffffc0203982 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc0203982:	411c                	lw	a5,0(a0)
ffffffffc0203984:	4705                	li	a4,1
ffffffffc0203986:	37f9                	addiw	a5,a5,-2
ffffffffc0203988:	00f77563          	bgeu	a4,a5,ffffffffc0203992 <wakeup_proc+0x10>
    proc->state = PROC_RUNNABLE;
ffffffffc020398c:	4789                	li	a5,2
ffffffffc020398e:	c11c                	sw	a5,0(a0)
ffffffffc0203990:	8082                	ret
wakeup_proc(struct proc_struct *proc) {
ffffffffc0203992:	1141                	addi	sp,sp,-16
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc0203994:	00002697          	auipc	a3,0x2
ffffffffc0203998:	d9468693          	addi	a3,a3,-620 # ffffffffc0205728 <etext+0x17fc>
ffffffffc020399c:	00001617          	auipc	a2,0x1
ffffffffc02039a0:	f6460613          	addi	a2,a2,-156 # ffffffffc0204900 <etext+0x9d4>
ffffffffc02039a4:	45a5                	li	a1,9
ffffffffc02039a6:	00002517          	auipc	a0,0x2
ffffffffc02039aa:	dc250513          	addi	a0,a0,-574 # ffffffffc0205768 <etext+0x183c>
wakeup_proc(struct proc_struct *proc) {
ffffffffc02039ae:	e406                	sd	ra,8(sp)
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02039b0:	a57fc0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc02039b4 <schedule>:
}

void
schedule(void) {
ffffffffc02039b4:	1101                	addi	sp,sp,-32
ffffffffc02039b6:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02039b8:	100027f3          	csrr	a5,sstatus
ffffffffc02039bc:	8b89                	andi	a5,a5,2
ffffffffc02039be:	4301                	li	t1,0
ffffffffc02039c0:	e3c1                	bnez	a5,ffffffffc0203a40 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc02039c2:	0000a897          	auipc	a7,0xa
ffffffffc02039c6:	b1e8b883          	ld	a7,-1250(a7) # ffffffffc020d4e0 <current>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02039ca:	0000a517          	auipc	a0,0xa
ffffffffc02039ce:	b2653503          	ld	a0,-1242(a0) # ffffffffc020d4f0 <idleproc>
        current->need_resched = 0;
ffffffffc02039d2:	0008ac23          	sw	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02039d6:	04a88f63          	beq	a7,a0,ffffffffc0203a34 <schedule+0x80>
ffffffffc02039da:	0c888693          	addi	a3,a7,200
ffffffffc02039de:	0000a617          	auipc	a2,0xa
ffffffffc02039e2:	a7a60613          	addi	a2,a2,-1414 # ffffffffc020d458 <proc_list>
        le = last;
ffffffffc02039e6:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02039e8:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc02039ea:	4809                	li	a6,2
ffffffffc02039ec:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc02039ee:	00c78863          	beq	a5,a2,ffffffffc02039fe <schedule+0x4a>
                if (next->state == PROC_RUNNABLE) {
ffffffffc02039f2:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc02039f6:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc02039fa:	03070363          	beq	a4,a6,ffffffffc0203a20 <schedule+0x6c>
                    break;
                }
            }
        } while (le != last);
ffffffffc02039fe:	fef697e3          	bne	a3,a5,ffffffffc02039ec <schedule+0x38>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0203a02:	ed99                	bnez	a1,ffffffffc0203a20 <schedule+0x6c>
            next = idleproc;
        }
        next->runs ++;
ffffffffc0203a04:	451c                	lw	a5,8(a0)
ffffffffc0203a06:	2785                	addiw	a5,a5,1
ffffffffc0203a08:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc0203a0a:	00a88663          	beq	a7,a0,ffffffffc0203a16 <schedule+0x62>
ffffffffc0203a0e:	e41a                	sd	t1,8(sp)
            proc_run(next);
ffffffffc0203a10:	8ffff0ef          	jal	ffffffffc020330e <proc_run>
ffffffffc0203a14:	6322                	ld	t1,8(sp)
    if (flag) {
ffffffffc0203a16:	00031b63          	bnez	t1,ffffffffc0203a2c <schedule+0x78>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0203a1a:	60e2                	ld	ra,24(sp)
ffffffffc0203a1c:	6105                	addi	sp,sp,32
ffffffffc0203a1e:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0203a20:	4198                	lw	a4,0(a1)
ffffffffc0203a22:	4789                	li	a5,2
ffffffffc0203a24:	fef710e3          	bne	a4,a5,ffffffffc0203a04 <schedule+0x50>
ffffffffc0203a28:	852e                	mv	a0,a1
ffffffffc0203a2a:	bfe9                	j	ffffffffc0203a04 <schedule+0x50>
}
ffffffffc0203a2c:	60e2                	ld	ra,24(sp)
ffffffffc0203a2e:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0203a30:	e3ffc06f          	j	ffffffffc020086e <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0203a34:	0000a617          	auipc	a2,0xa
ffffffffc0203a38:	a2460613          	addi	a2,a2,-1500 # ffffffffc020d458 <proc_list>
ffffffffc0203a3c:	86b2                	mv	a3,a2
ffffffffc0203a3e:	b765                	j	ffffffffc02039e6 <schedule+0x32>
        intr_disable();
ffffffffc0203a40:	e35fc0ef          	jal	ffffffffc0200874 <intr_disable>
        return 1;
ffffffffc0203a44:	4305                	li	t1,1
ffffffffc0203a46:	bfb5                	j	ffffffffc02039c2 <schedule+0xe>

ffffffffc0203a48 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0203a48:	9e3707b7          	lui	a5,0x9e370
ffffffffc0203a4c:	2785                	addiw	a5,a5,1 # ffffffff9e370001 <kern_entry-0x21e8ffff>
ffffffffc0203a4e:	02a787bb          	mulw	a5,a5,a0
    return (hash >> (32 - bits));
ffffffffc0203a52:	02000513          	li	a0,32
ffffffffc0203a56:	9d0d                	subw	a0,a0,a1
}
ffffffffc0203a58:	00a7d53b          	srlw	a0,a5,a0
ffffffffc0203a5c:	8082                	ret

ffffffffc0203a5e <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203a5e:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0203a60:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203a64:	f022                	sd	s0,32(sp)
ffffffffc0203a66:	ec26                	sd	s1,24(sp)
ffffffffc0203a68:	e84a                	sd	s2,16(sp)
ffffffffc0203a6a:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203a6c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203a70:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203a72:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0203a76:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203a7a:	84aa                	mv	s1,a0
ffffffffc0203a7c:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc0203a7e:	03067d63          	bgeu	a2,a6,ffffffffc0203ab8 <printnum+0x5a>
ffffffffc0203a82:	e44e                	sd	s3,8(sp)
ffffffffc0203a84:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0203a86:	4785                	li	a5,1
ffffffffc0203a88:	00e7d763          	bge	a5,a4,ffffffffc0203a96 <printnum+0x38>
            putch(padc, putdat);
ffffffffc0203a8c:	85ca                	mv	a1,s2
ffffffffc0203a8e:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0203a90:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0203a92:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0203a94:	fc65                	bnez	s0,ffffffffc0203a8c <printnum+0x2e>
ffffffffc0203a96:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a98:	00002797          	auipc	a5,0x2
ffffffffc0203a9c:	ce878793          	addi	a5,a5,-792 # ffffffffc0205780 <etext+0x1854>
ffffffffc0203aa0:	97d2                	add	a5,a5,s4
}
ffffffffc0203aa2:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203aa4:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0203aa8:	70a2                	ld	ra,40(sp)
ffffffffc0203aaa:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203aac:	85ca                	mv	a1,s2
ffffffffc0203aae:	87a6                	mv	a5,s1
}
ffffffffc0203ab0:	6942                	ld	s2,16(sp)
ffffffffc0203ab2:	64e2                	ld	s1,24(sp)
ffffffffc0203ab4:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203ab6:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203ab8:	03065633          	divu	a2,a2,a6
ffffffffc0203abc:	8722                	mv	a4,s0
ffffffffc0203abe:	fa1ff0ef          	jal	ffffffffc0203a5e <printnum>
ffffffffc0203ac2:	bfd9                	j	ffffffffc0203a98 <printnum+0x3a>

ffffffffc0203ac4 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0203ac4:	7119                	addi	sp,sp,-128
ffffffffc0203ac6:	f4a6                	sd	s1,104(sp)
ffffffffc0203ac8:	f0ca                	sd	s2,96(sp)
ffffffffc0203aca:	ecce                	sd	s3,88(sp)
ffffffffc0203acc:	e8d2                	sd	s4,80(sp)
ffffffffc0203ace:	e4d6                	sd	s5,72(sp)
ffffffffc0203ad0:	e0da                	sd	s6,64(sp)
ffffffffc0203ad2:	f862                	sd	s8,48(sp)
ffffffffc0203ad4:	fc86                	sd	ra,120(sp)
ffffffffc0203ad6:	f8a2                	sd	s0,112(sp)
ffffffffc0203ad8:	fc5e                	sd	s7,56(sp)
ffffffffc0203ada:	f466                	sd	s9,40(sp)
ffffffffc0203adc:	f06a                	sd	s10,32(sp)
ffffffffc0203ade:	ec6e                	sd	s11,24(sp)
ffffffffc0203ae0:	84aa                	mv	s1,a0
ffffffffc0203ae2:	8c32                	mv	s8,a2
ffffffffc0203ae4:	8a36                	mv	s4,a3
ffffffffc0203ae6:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203ae8:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203aec:	05500b13          	li	s6,85
ffffffffc0203af0:	00002a97          	auipc	s5,0x2
ffffffffc0203af4:	e30a8a93          	addi	s5,s5,-464 # ffffffffc0205920 <default_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203af8:	000c4503          	lbu	a0,0(s8)
ffffffffc0203afc:	001c0413          	addi	s0,s8,1
ffffffffc0203b00:	01350a63          	beq	a0,s3,ffffffffc0203b14 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0203b04:	cd0d                	beqz	a0,ffffffffc0203b3e <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0203b06:	85ca                	mv	a1,s2
ffffffffc0203b08:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203b0a:	00044503          	lbu	a0,0(s0)
ffffffffc0203b0e:	0405                	addi	s0,s0,1
ffffffffc0203b10:	ff351ae3          	bne	a0,s3,ffffffffc0203b04 <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0203b14:	5cfd                	li	s9,-1
ffffffffc0203b16:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc0203b18:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0203b1c:	4b81                	li	s7,0
ffffffffc0203b1e:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b20:	00044683          	lbu	a3,0(s0)
ffffffffc0203b24:	00140c13          	addi	s8,s0,1
ffffffffc0203b28:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0203b2c:	0ff5f593          	zext.b	a1,a1
ffffffffc0203b30:	02bb6663          	bltu	s6,a1,ffffffffc0203b5c <vprintfmt+0x98>
ffffffffc0203b34:	058a                	slli	a1,a1,0x2
ffffffffc0203b36:	95d6                	add	a1,a1,s5
ffffffffc0203b38:	4198                	lw	a4,0(a1)
ffffffffc0203b3a:	9756                	add	a4,a4,s5
ffffffffc0203b3c:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0203b3e:	70e6                	ld	ra,120(sp)
ffffffffc0203b40:	7446                	ld	s0,112(sp)
ffffffffc0203b42:	74a6                	ld	s1,104(sp)
ffffffffc0203b44:	7906                	ld	s2,96(sp)
ffffffffc0203b46:	69e6                	ld	s3,88(sp)
ffffffffc0203b48:	6a46                	ld	s4,80(sp)
ffffffffc0203b4a:	6aa6                	ld	s5,72(sp)
ffffffffc0203b4c:	6b06                	ld	s6,64(sp)
ffffffffc0203b4e:	7be2                	ld	s7,56(sp)
ffffffffc0203b50:	7c42                	ld	s8,48(sp)
ffffffffc0203b52:	7ca2                	ld	s9,40(sp)
ffffffffc0203b54:	7d02                	ld	s10,32(sp)
ffffffffc0203b56:	6de2                	ld	s11,24(sp)
ffffffffc0203b58:	6109                	addi	sp,sp,128
ffffffffc0203b5a:	8082                	ret
            putch('%', putdat);
ffffffffc0203b5c:	85ca                	mv	a1,s2
ffffffffc0203b5e:	02500513          	li	a0,37
ffffffffc0203b62:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0203b64:	fff44783          	lbu	a5,-1(s0)
ffffffffc0203b68:	02500713          	li	a4,37
ffffffffc0203b6c:	8c22                	mv	s8,s0
ffffffffc0203b6e:	f8e785e3          	beq	a5,a4,ffffffffc0203af8 <vprintfmt+0x34>
ffffffffc0203b72:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0203b76:	1c7d                	addi	s8,s8,-1
ffffffffc0203b78:	fee79de3          	bne	a5,a4,ffffffffc0203b72 <vprintfmt+0xae>
ffffffffc0203b7c:	bfb5                	j	ffffffffc0203af8 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0203b7e:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0203b82:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc0203b84:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0203b88:	fd06071b          	addiw	a4,a2,-48
ffffffffc0203b8c:	24e56a63          	bltu	a0,a4,ffffffffc0203de0 <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc0203b90:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b92:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc0203b94:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0203b98:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0203b9c:	0197073b          	addw	a4,a4,s9
ffffffffc0203ba0:	0017171b          	slliw	a4,a4,0x1
ffffffffc0203ba4:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203ba6:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0203baa:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0203bac:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0203bb0:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc0203bb4:	feb570e3          	bgeu	a0,a1,ffffffffc0203b94 <vprintfmt+0xd0>
            if (width < 0)
ffffffffc0203bb8:	f60d54e3          	bgez	s10,ffffffffc0203b20 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0203bbc:	8d66                	mv	s10,s9
ffffffffc0203bbe:	5cfd                	li	s9,-1
ffffffffc0203bc0:	b785                	j	ffffffffc0203b20 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bc2:	8db6                	mv	s11,a3
ffffffffc0203bc4:	8462                	mv	s0,s8
ffffffffc0203bc6:	bfa9                	j	ffffffffc0203b20 <vprintfmt+0x5c>
ffffffffc0203bc8:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0203bca:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0203bcc:	bf91                	j	ffffffffc0203b20 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0203bce:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203bd0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203bd4:	00f74463          	blt	a4,a5,ffffffffc0203bdc <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0203bd8:	1a078763          	beqz	a5,ffffffffc0203d86 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc0203bdc:	000a3603          	ld	a2,0(s4)
ffffffffc0203be0:	46c1                	li	a3,16
ffffffffc0203be2:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0203be4:	000d879b          	sext.w	a5,s11
ffffffffc0203be8:	876a                	mv	a4,s10
ffffffffc0203bea:	85ca                	mv	a1,s2
ffffffffc0203bec:	8526                	mv	a0,s1
ffffffffc0203bee:	e71ff0ef          	jal	ffffffffc0203a5e <printnum>
            break;
ffffffffc0203bf2:	b719                	j	ffffffffc0203af8 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0203bf4:	000a2503          	lw	a0,0(s4)
ffffffffc0203bf8:	85ca                	mv	a1,s2
ffffffffc0203bfa:	0a21                	addi	s4,s4,8
ffffffffc0203bfc:	9482                	jalr	s1
            break;
ffffffffc0203bfe:	bded                	j	ffffffffc0203af8 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0203c00:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203c02:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203c06:	00f74463          	blt	a4,a5,ffffffffc0203c0e <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0203c0a:	16078963          	beqz	a5,ffffffffc0203d7c <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc0203c0e:	000a3603          	ld	a2,0(s4)
ffffffffc0203c12:	46a9                	li	a3,10
ffffffffc0203c14:	8a2e                	mv	s4,a1
ffffffffc0203c16:	b7f9                	j	ffffffffc0203be4 <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc0203c18:	85ca                	mv	a1,s2
ffffffffc0203c1a:	03000513          	li	a0,48
ffffffffc0203c1e:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc0203c20:	85ca                	mv	a1,s2
ffffffffc0203c22:	07800513          	li	a0,120
ffffffffc0203c26:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203c28:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0203c2c:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203c2e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0203c30:	bf55                	j	ffffffffc0203be4 <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc0203c32:	85ca                	mv	a1,s2
ffffffffc0203c34:	02500513          	li	a0,37
ffffffffc0203c38:	9482                	jalr	s1
            break;
ffffffffc0203c3a:	bd7d                	j	ffffffffc0203af8 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0203c3c:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203c40:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0203c42:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0203c44:	bf95                	j	ffffffffc0203bb8 <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc0203c46:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203c48:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203c4c:	00f74463          	blt	a4,a5,ffffffffc0203c54 <vprintfmt+0x190>
    else if (lflag) {
ffffffffc0203c50:	12078163          	beqz	a5,ffffffffc0203d72 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc0203c54:	000a3603          	ld	a2,0(s4)
ffffffffc0203c58:	46a1                	li	a3,8
ffffffffc0203c5a:	8a2e                	mv	s4,a1
ffffffffc0203c5c:	b761                	j	ffffffffc0203be4 <vprintfmt+0x120>
            if (width < 0)
ffffffffc0203c5e:	876a                	mv	a4,s10
ffffffffc0203c60:	000d5363          	bgez	s10,ffffffffc0203c66 <vprintfmt+0x1a2>
ffffffffc0203c64:	4701                	li	a4,0
ffffffffc0203c66:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203c6a:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0203c6c:	bd55                	j	ffffffffc0203b20 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc0203c6e:	000d841b          	sext.w	s0,s11
ffffffffc0203c72:	fd340793          	addi	a5,s0,-45
ffffffffc0203c76:	00f037b3          	snez	a5,a5
ffffffffc0203c7a:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203c7e:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc0203c82:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203c84:	008a0793          	addi	a5,s4,8
ffffffffc0203c88:	e43e                	sd	a5,8(sp)
ffffffffc0203c8a:	100d8c63          	beqz	s11,ffffffffc0203da2 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0203c8e:	12071363          	bnez	a4,ffffffffc0203db4 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c92:	000dc783          	lbu	a5,0(s11)
ffffffffc0203c96:	0007851b          	sext.w	a0,a5
ffffffffc0203c9a:	c78d                	beqz	a5,ffffffffc0203cc4 <vprintfmt+0x200>
ffffffffc0203c9c:	0d85                	addi	s11,s11,1
ffffffffc0203c9e:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203ca0:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203ca4:	000cc563          	bltz	s9,ffffffffc0203cae <vprintfmt+0x1ea>
ffffffffc0203ca8:	3cfd                	addiw	s9,s9,-1
ffffffffc0203caa:	008c8d63          	beq	s9,s0,ffffffffc0203cc4 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203cae:	020b9663          	bnez	s7,ffffffffc0203cda <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc0203cb2:	85ca                	mv	a1,s2
ffffffffc0203cb4:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203cb6:	000dc783          	lbu	a5,0(s11)
ffffffffc0203cba:	0d85                	addi	s11,s11,1
ffffffffc0203cbc:	3d7d                	addiw	s10,s10,-1
ffffffffc0203cbe:	0007851b          	sext.w	a0,a5
ffffffffc0203cc2:	f3ed                	bnez	a5,ffffffffc0203ca4 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc0203cc4:	01a05963          	blez	s10,ffffffffc0203cd6 <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc0203cc8:	85ca                	mv	a1,s2
ffffffffc0203cca:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0203cce:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0203cd0:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc0203cd2:	fe0d1be3          	bnez	s10,ffffffffc0203cc8 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203cd6:	6a22                	ld	s4,8(sp)
ffffffffc0203cd8:	b505                	j	ffffffffc0203af8 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203cda:	3781                	addiw	a5,a5,-32
ffffffffc0203cdc:	fcfa7be3          	bgeu	s4,a5,ffffffffc0203cb2 <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0203ce0:	03f00513          	li	a0,63
ffffffffc0203ce4:	85ca                	mv	a1,s2
ffffffffc0203ce6:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203ce8:	000dc783          	lbu	a5,0(s11)
ffffffffc0203cec:	0d85                	addi	s11,s11,1
ffffffffc0203cee:	3d7d                	addiw	s10,s10,-1
ffffffffc0203cf0:	0007851b          	sext.w	a0,a5
ffffffffc0203cf4:	dbe1                	beqz	a5,ffffffffc0203cc4 <vprintfmt+0x200>
ffffffffc0203cf6:	fa0cd9e3          	bgez	s9,ffffffffc0203ca8 <vprintfmt+0x1e4>
ffffffffc0203cfa:	b7c5                	j	ffffffffc0203cda <vprintfmt+0x216>
            if (err < 0) {
ffffffffc0203cfc:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203d00:	4619                	li	a2,6
            err = va_arg(ap, int);
ffffffffc0203d02:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0203d04:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0203d08:	8fb9                	xor	a5,a5,a4
ffffffffc0203d0a:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203d0e:	02d64563          	blt	a2,a3,ffffffffc0203d38 <vprintfmt+0x274>
ffffffffc0203d12:	00002797          	auipc	a5,0x2
ffffffffc0203d16:	d6678793          	addi	a5,a5,-666 # ffffffffc0205a78 <error_string>
ffffffffc0203d1a:	00369713          	slli	a4,a3,0x3
ffffffffc0203d1e:	97ba                	add	a5,a5,a4
ffffffffc0203d20:	639c                	ld	a5,0(a5)
ffffffffc0203d22:	cb99                	beqz	a5,ffffffffc0203d38 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc0203d24:	86be                	mv	a3,a5
ffffffffc0203d26:	00000617          	auipc	a2,0x0
ffffffffc0203d2a:	23260613          	addi	a2,a2,562 # ffffffffc0203f58 <etext+0x2c>
ffffffffc0203d2e:	85ca                	mv	a1,s2
ffffffffc0203d30:	8526                	mv	a0,s1
ffffffffc0203d32:	0d8000ef          	jal	ffffffffc0203e0a <printfmt>
ffffffffc0203d36:	b3c9                	j	ffffffffc0203af8 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0203d38:	00002617          	auipc	a2,0x2
ffffffffc0203d3c:	a6860613          	addi	a2,a2,-1432 # ffffffffc02057a0 <etext+0x1874>
ffffffffc0203d40:	85ca                	mv	a1,s2
ffffffffc0203d42:	8526                	mv	a0,s1
ffffffffc0203d44:	0c6000ef          	jal	ffffffffc0203e0a <printfmt>
ffffffffc0203d48:	bb45                	j	ffffffffc0203af8 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0203d4a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203d4c:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0203d50:	00f74363          	blt	a4,a5,ffffffffc0203d56 <vprintfmt+0x292>
    else if (lflag) {
ffffffffc0203d54:	cf81                	beqz	a5,ffffffffc0203d6c <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc0203d56:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0203d5a:	02044b63          	bltz	s0,ffffffffc0203d90 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0203d5e:	8622                	mv	a2,s0
ffffffffc0203d60:	8a5e                	mv	s4,s7
ffffffffc0203d62:	46a9                	li	a3,10
ffffffffc0203d64:	b541                	j	ffffffffc0203be4 <vprintfmt+0x120>
            lflag ++;
ffffffffc0203d66:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203d68:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0203d6a:	bb5d                	j	ffffffffc0203b20 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc0203d6c:	000a2403          	lw	s0,0(s4)
ffffffffc0203d70:	b7ed                	j	ffffffffc0203d5a <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc0203d72:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d76:	46a1                	li	a3,8
ffffffffc0203d78:	8a2e                	mv	s4,a1
ffffffffc0203d7a:	b5ad                	j	ffffffffc0203be4 <vprintfmt+0x120>
ffffffffc0203d7c:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d80:	46a9                	li	a3,10
ffffffffc0203d82:	8a2e                	mv	s4,a1
ffffffffc0203d84:	b585                	j	ffffffffc0203be4 <vprintfmt+0x120>
ffffffffc0203d86:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d8a:	46c1                	li	a3,16
ffffffffc0203d8c:	8a2e                	mv	s4,a1
ffffffffc0203d8e:	bd99                	j	ffffffffc0203be4 <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc0203d90:	85ca                	mv	a1,s2
ffffffffc0203d92:	02d00513          	li	a0,45
ffffffffc0203d96:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc0203d98:	40800633          	neg	a2,s0
ffffffffc0203d9c:	8a5e                	mv	s4,s7
ffffffffc0203d9e:	46a9                	li	a3,10
ffffffffc0203da0:	b591                	j	ffffffffc0203be4 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc0203da2:	e329                	bnez	a4,ffffffffc0203de4 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203da4:	02800793          	li	a5,40
ffffffffc0203da8:	853e                	mv	a0,a5
ffffffffc0203daa:	00002d97          	auipc	s11,0x2
ffffffffc0203dae:	9efd8d93          	addi	s11,s11,-1553 # ffffffffc0205799 <etext+0x186d>
ffffffffc0203db2:	b5f5                	j	ffffffffc0203c9e <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203db4:	85e6                	mv	a1,s9
ffffffffc0203db6:	856e                	mv	a0,s11
ffffffffc0203db8:	08a000ef          	jal	ffffffffc0203e42 <strnlen>
ffffffffc0203dbc:	40ad0d3b          	subw	s10,s10,a0
ffffffffc0203dc0:	01a05863          	blez	s10,ffffffffc0203dd0 <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc0203dc4:	85ca                	mv	a1,s2
ffffffffc0203dc6:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203dc8:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc0203dca:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203dcc:	fe0d1ce3          	bnez	s10,ffffffffc0203dc4 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203dd0:	000dc783          	lbu	a5,0(s11)
ffffffffc0203dd4:	0007851b          	sext.w	a0,a5
ffffffffc0203dd8:	ec0792e3          	bnez	a5,ffffffffc0203c9c <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203ddc:	6a22                	ld	s4,8(sp)
ffffffffc0203dde:	bb29                	j	ffffffffc0203af8 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203de0:	8462                	mv	s0,s8
ffffffffc0203de2:	bbd9                	j	ffffffffc0203bb8 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203de4:	85e6                	mv	a1,s9
ffffffffc0203de6:	00002517          	auipc	a0,0x2
ffffffffc0203dea:	9b250513          	addi	a0,a0,-1614 # ffffffffc0205798 <etext+0x186c>
ffffffffc0203dee:	054000ef          	jal	ffffffffc0203e42 <strnlen>
ffffffffc0203df2:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203df6:	02800793          	li	a5,40
                p = "(null)";
ffffffffc0203dfa:	00002d97          	auipc	s11,0x2
ffffffffc0203dfe:	99ed8d93          	addi	s11,s11,-1634 # ffffffffc0205798 <etext+0x186c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203e02:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203e04:	fda040e3          	bgtz	s10,ffffffffc0203dc4 <vprintfmt+0x300>
ffffffffc0203e08:	bd51                	j	ffffffffc0203c9c <vprintfmt+0x1d8>

ffffffffc0203e0a <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203e0a:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0203e0c:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203e10:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203e12:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203e14:	ec06                	sd	ra,24(sp)
ffffffffc0203e16:	f83a                	sd	a4,48(sp)
ffffffffc0203e18:	fc3e                	sd	a5,56(sp)
ffffffffc0203e1a:	e0c2                	sd	a6,64(sp)
ffffffffc0203e1c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0203e1e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203e20:	ca5ff0ef          	jal	ffffffffc0203ac4 <vprintfmt>
}
ffffffffc0203e24:	60e2                	ld	ra,24(sp)
ffffffffc0203e26:	6161                	addi	sp,sp,80
ffffffffc0203e28:	8082                	ret

ffffffffc0203e2a <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203e2a:	00054783          	lbu	a5,0(a0)
ffffffffc0203e2e:	cb81                	beqz	a5,ffffffffc0203e3e <strlen+0x14>
    size_t cnt = 0;
ffffffffc0203e30:	4781                	li	a5,0
        cnt ++;
ffffffffc0203e32:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0203e34:	00f50733          	add	a4,a0,a5
ffffffffc0203e38:	00074703          	lbu	a4,0(a4)
ffffffffc0203e3c:	fb7d                	bnez	a4,ffffffffc0203e32 <strlen+0x8>
    }
    return cnt;
}
ffffffffc0203e3e:	853e                	mv	a0,a5
ffffffffc0203e40:	8082                	ret

ffffffffc0203e42 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0203e42:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203e44:	e589                	bnez	a1,ffffffffc0203e4e <strnlen+0xc>
ffffffffc0203e46:	a811                	j	ffffffffc0203e5a <strnlen+0x18>
        cnt ++;
ffffffffc0203e48:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203e4a:	00f58863          	beq	a1,a5,ffffffffc0203e5a <strnlen+0x18>
ffffffffc0203e4e:	00f50733          	add	a4,a0,a5
ffffffffc0203e52:	00074703          	lbu	a4,0(a4)
ffffffffc0203e56:	fb6d                	bnez	a4,ffffffffc0203e48 <strnlen+0x6>
ffffffffc0203e58:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0203e5a:	852e                	mv	a0,a1
ffffffffc0203e5c:	8082                	ret

ffffffffc0203e5e <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0203e5e:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0203e60:	0005c703          	lbu	a4,0(a1)
ffffffffc0203e64:	0585                	addi	a1,a1,1
ffffffffc0203e66:	0785                	addi	a5,a5,1
ffffffffc0203e68:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0203e6c:	fb75                	bnez	a4,ffffffffc0203e60 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0203e6e:	8082                	ret

ffffffffc0203e70 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e70:	00054783          	lbu	a5,0(a0)
ffffffffc0203e74:	e791                	bnez	a5,ffffffffc0203e80 <strcmp+0x10>
ffffffffc0203e76:	a01d                	j	ffffffffc0203e9c <strcmp+0x2c>
ffffffffc0203e78:	00054783          	lbu	a5,0(a0)
ffffffffc0203e7c:	cb99                	beqz	a5,ffffffffc0203e92 <strcmp+0x22>
ffffffffc0203e7e:	0585                	addi	a1,a1,1
ffffffffc0203e80:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0203e84:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e86:	fef709e3          	beq	a4,a5,ffffffffc0203e78 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e8a:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203e8e:	9d19                	subw	a0,a0,a4
ffffffffc0203e90:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e92:	0015c703          	lbu	a4,1(a1)
ffffffffc0203e96:	4501                	li	a0,0
}
ffffffffc0203e98:	9d19                	subw	a0,a0,a4
ffffffffc0203e9a:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e9c:	0005c703          	lbu	a4,0(a1)
ffffffffc0203ea0:	4501                	li	a0,0
ffffffffc0203ea2:	b7f5                	j	ffffffffc0203e8e <strcmp+0x1e>

ffffffffc0203ea4 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203ea4:	ce01                	beqz	a2,ffffffffc0203ebc <strncmp+0x18>
ffffffffc0203ea6:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0203eaa:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203eac:	cb91                	beqz	a5,ffffffffc0203ec0 <strncmp+0x1c>
ffffffffc0203eae:	0005c703          	lbu	a4,0(a1)
ffffffffc0203eb2:	00f71763          	bne	a4,a5,ffffffffc0203ec0 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0203eb6:	0505                	addi	a0,a0,1
ffffffffc0203eb8:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203eba:	f675                	bnez	a2,ffffffffc0203ea6 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203ebc:	4501                	li	a0,0
ffffffffc0203ebe:	8082                	ret
ffffffffc0203ec0:	00054503          	lbu	a0,0(a0)
ffffffffc0203ec4:	0005c783          	lbu	a5,0(a1)
ffffffffc0203ec8:	9d1d                	subw	a0,a0,a5
}
ffffffffc0203eca:	8082                	ret

ffffffffc0203ecc <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0203ecc:	a021                	j	ffffffffc0203ed4 <strchr+0x8>
        if (*s == c) {
ffffffffc0203ece:	00f58763          	beq	a1,a5,ffffffffc0203edc <strchr+0x10>
            return (char *)s;
        }
        s ++;
ffffffffc0203ed2:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0203ed4:	00054783          	lbu	a5,0(a0)
ffffffffc0203ed8:	fbfd                	bnez	a5,ffffffffc0203ece <strchr+0x2>
    }
    return NULL;
ffffffffc0203eda:	4501                	li	a0,0
}
ffffffffc0203edc:	8082                	ret

ffffffffc0203ede <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0203ede:	ca01                	beqz	a2,ffffffffc0203eee <memset+0x10>
ffffffffc0203ee0:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0203ee2:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0203ee4:	0785                	addi	a5,a5,1
ffffffffc0203ee6:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0203eea:	fef61de3          	bne	a2,a5,ffffffffc0203ee4 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0203eee:	8082                	ret

ffffffffc0203ef0 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0203ef0:	ca19                	beqz	a2,ffffffffc0203f06 <memcpy+0x16>
ffffffffc0203ef2:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0203ef4:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0203ef6:	0005c703          	lbu	a4,0(a1)
ffffffffc0203efa:	0585                	addi	a1,a1,1
ffffffffc0203efc:	0785                	addi	a5,a5,1
ffffffffc0203efe:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0203f02:	feb61ae3          	bne	a2,a1,ffffffffc0203ef6 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0203f06:	8082                	ret

ffffffffc0203f08 <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0203f08:	c205                	beqz	a2,ffffffffc0203f28 <memcmp+0x20>
ffffffffc0203f0a:	962a                	add	a2,a2,a0
ffffffffc0203f0c:	a019                	j	ffffffffc0203f12 <memcmp+0xa>
ffffffffc0203f0e:	00c50d63          	beq	a0,a2,ffffffffc0203f28 <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc0203f12:	00054783          	lbu	a5,0(a0)
ffffffffc0203f16:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0203f1a:	0505                	addi	a0,a0,1
ffffffffc0203f1c:	0585                	addi	a1,a1,1
        if (*s1 != *s2) {
ffffffffc0203f1e:	fee788e3          	beq	a5,a4,ffffffffc0203f0e <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203f22:	40e7853b          	subw	a0,a5,a4
ffffffffc0203f26:	8082                	ret
    }
    return 0;
ffffffffc0203f28:	4501                	li	a0,0
}
ffffffffc0203f2a:	8082                	ret
