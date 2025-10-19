
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00005297          	auipc	t0,0x5
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0205000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00005297          	auipc	t0,0x5
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0205008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02042b7          	lui	t0,0xc0204
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
ffffffffc020003c:	c0204137          	lui	sp,0xc0204

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d628293          	addi	t0,t0,214 # ffffffffc02000d6 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16 # ffffffffc0203ff0 <bootstack+0x1ff0>
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00001517          	auipc	a0,0x1
ffffffffc0200050:	5ec50513          	addi	a0,a0,1516 # ffffffffc0201638 <etext+0x2>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f2000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07c58593          	addi	a1,a1,124 # ffffffffc02000d6 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	5f650513          	addi	a0,a0,1526 # ffffffffc0201658 <etext+0x22>
ffffffffc020006a:	0de000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	5c858593          	addi	a1,a1,1480 # ffffffffc0201636 <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	60250513          	addi	a0,a0,1538 # ffffffffc0201678 <etext+0x42>
ffffffffc020007e:	0ca000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00005597          	auipc	a1,0x5
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0205018 <free_area>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	60e50513          	addi	a0,a0,1550 # ffffffffc0201698 <etext+0x62>
ffffffffc0200092:	0b6000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00005597          	auipc	a1,0x5
ffffffffc020009a:	fe258593          	addi	a1,a1,-30 # ffffffffc0205078 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	61a50513          	addi	a0,a0,1562 # ffffffffc02016b8 <etext+0x82>
ffffffffc02000a6:	0a2000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00000717          	auipc	a4,0x0
ffffffffc02000ae:	02c70713          	addi	a4,a4,44 # ffffffffc02000d6 <kern_init>
ffffffffc02000b2:	00005797          	auipc	a5,0x5
ffffffffc02000b6:	3c578793          	addi	a5,a5,965 # ffffffffc0205477 <end+0x3ff>
ffffffffc02000ba:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000bc:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c0:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c2:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c6:	95be                	add	a1,a1,a5
ffffffffc02000c8:	85a9                	srai	a1,a1,0xa
ffffffffc02000ca:	00001517          	auipc	a0,0x1
ffffffffc02000ce:	60e50513          	addi	a0,a0,1550 # ffffffffc02016d8 <etext+0xa2>
}
ffffffffc02000d2:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d4:	a895                	j	ffffffffc0200148 <cprintf>

ffffffffc02000d6 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d6:	00005517          	auipc	a0,0x5
ffffffffc02000da:	f4250513          	addi	a0,a0,-190 # ffffffffc0205018 <free_area>
ffffffffc02000de:	00005617          	auipc	a2,0x5
ffffffffc02000e2:	f9a60613          	addi	a2,a2,-102 # ffffffffc0205078 <end>
int kern_init(void) {
ffffffffc02000e6:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000e8:	8e09                	sub	a2,a2,a0
ffffffffc02000ea:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ec:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000ee:	536010ef          	jal	ffffffffc0201624 <memset>
    dtb_init();
ffffffffc02000f2:	136000ef          	jal	ffffffffc0200228 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f6:	128000ef          	jal	ffffffffc020021e <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fa:	00002517          	auipc	a0,0x2
ffffffffc02000fe:	cce50513          	addi	a0,a0,-818 # ffffffffc0201dc8 <etext+0x792>
ffffffffc0200102:	07a000ef          	jal	ffffffffc020017c <cputs>

    print_kerninfo();
ffffffffc0200106:	f45ff0ef          	jal	ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010a:	6d1000ef          	jal	ffffffffc0200fda <pmm_init>

    /* do nothing */
    while (1)
ffffffffc020010e:	a001                	j	ffffffffc020010e <kern_init+0x38>

ffffffffc0200110 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200110:	1101                	addi	sp,sp,-32
ffffffffc0200112:	ec06                	sd	ra,24(sp)
ffffffffc0200114:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc0200116:	10a000ef          	jal	ffffffffc0200220 <cons_putc>
    (*cnt) ++;
ffffffffc020011a:	65a2                	ld	a1,8(sp)
}
ffffffffc020011c:	60e2                	ld	ra,24(sp)
    (*cnt) ++;
ffffffffc020011e:	419c                	lw	a5,0(a1)
ffffffffc0200120:	2785                	addiw	a5,a5,1
ffffffffc0200122:	c19c                	sw	a5,0(a1)
}
ffffffffc0200124:	6105                	addi	sp,sp,32
ffffffffc0200126:	8082                	ret

ffffffffc0200128 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200128:	1101                	addi	sp,sp,-32
ffffffffc020012a:	862a                	mv	a2,a0
ffffffffc020012c:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020012e:	00000517          	auipc	a0,0x0
ffffffffc0200132:	fe250513          	addi	a0,a0,-30 # ffffffffc0200110 <cputch>
ffffffffc0200136:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200138:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013a:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020013c:	0d8010ef          	jal	ffffffffc0201214 <vprintfmt>
    return cnt;
}
ffffffffc0200140:	60e2                	ld	ra,24(sp)
ffffffffc0200142:	4532                	lw	a0,12(sp)
ffffffffc0200144:	6105                	addi	sp,sp,32
ffffffffc0200146:	8082                	ret

ffffffffc0200148 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200148:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014a:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc020014e:	f42e                	sd	a1,40(sp)
ffffffffc0200150:	f832                	sd	a2,48(sp)
ffffffffc0200152:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200154:	862a                	mv	a2,a0
ffffffffc0200156:	004c                	addi	a1,sp,4
ffffffffc0200158:	00000517          	auipc	a0,0x0
ffffffffc020015c:	fb850513          	addi	a0,a0,-72 # ffffffffc0200110 <cputch>
ffffffffc0200160:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc0200162:	ec06                	sd	ra,24(sp)
ffffffffc0200164:	e0ba                	sd	a4,64(sp)
ffffffffc0200166:	e4be                	sd	a5,72(sp)
ffffffffc0200168:	e8c2                	sd	a6,80(sp)
ffffffffc020016a:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc020016c:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc020016e:	e41a                	sd	t1,8(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200170:	0a4010ef          	jal	ffffffffc0201214 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200174:	60e2                	ld	ra,24(sp)
ffffffffc0200176:	4512                	lw	a0,4(sp)
ffffffffc0200178:	6125                	addi	sp,sp,96
ffffffffc020017a:	8082                	ret

ffffffffc020017c <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020017c:	1101                	addi	sp,sp,-32
ffffffffc020017e:	e822                	sd	s0,16(sp)
ffffffffc0200180:	ec06                	sd	ra,24(sp)
ffffffffc0200182:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200184:	00054503          	lbu	a0,0(a0)
ffffffffc0200188:	c51d                	beqz	a0,ffffffffc02001b6 <cputs+0x3a>
ffffffffc020018a:	e426                	sd	s1,8(sp)
ffffffffc020018c:	0405                	addi	s0,s0,1
    int cnt = 0;
ffffffffc020018e:	4481                	li	s1,0
    cons_putc(c);
ffffffffc0200190:	090000ef          	jal	ffffffffc0200220 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200194:	00044503          	lbu	a0,0(s0)
ffffffffc0200198:	0405                	addi	s0,s0,1
ffffffffc020019a:	87a6                	mv	a5,s1
    (*cnt) ++;
ffffffffc020019c:	2485                	addiw	s1,s1,1
    while ((c = *str ++) != '\0') {
ffffffffc020019e:	f96d                	bnez	a0,ffffffffc0200190 <cputs+0x14>
    cons_putc(c);
ffffffffc02001a0:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc02001a2:	0027841b          	addiw	s0,a5,2
ffffffffc02001a6:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001a8:	078000ef          	jal	ffffffffc0200220 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001ac:	60e2                	ld	ra,24(sp)
ffffffffc02001ae:	8522                	mv	a0,s0
ffffffffc02001b0:	6442                	ld	s0,16(sp)
ffffffffc02001b2:	6105                	addi	sp,sp,32
ffffffffc02001b4:	8082                	ret
    cons_putc(c);
ffffffffc02001b6:	4529                	li	a0,10
ffffffffc02001b8:	068000ef          	jal	ffffffffc0200220 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001bc:	4405                	li	s0,1
}
ffffffffc02001be:	60e2                	ld	ra,24(sp)
ffffffffc02001c0:	8522                	mv	a0,s0
ffffffffc02001c2:	6442                	ld	s0,16(sp)
ffffffffc02001c4:	6105                	addi	sp,sp,32
ffffffffc02001c6:	8082                	ret

ffffffffc02001c8 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c8:	00005317          	auipc	t1,0x5
ffffffffc02001cc:	e6832303          	lw	t1,-408(t1) # ffffffffc0205030 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d0:	715d                	addi	sp,sp,-80
ffffffffc02001d2:	ec06                	sd	ra,24(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	00030363          	beqz	t1,ffffffffc02001e4 <__panic+0x1c>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x1a>
    is_panic = 1;
ffffffffc02001e4:	4705                	li	a4,1
    va_start(ap, fmt);
ffffffffc02001e6:	103c                	addi	a5,sp,40
ffffffffc02001e8:	e822                	sd	s0,16(sp)
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	862e                	mv	a2,a1
ffffffffc02001ee:	85aa                	mv	a1,a0
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f0:	00001517          	auipc	a0,0x1
ffffffffc02001f4:	51850513          	addi	a0,a0,1304 # ffffffffc0201708 <etext+0xd2>
    is_panic = 1;
ffffffffc02001f8:	00005697          	auipc	a3,0x5
ffffffffc02001fc:	e2e6ac23          	sw	a4,-456(a3) # ffffffffc0205030 <is_panic>
    va_start(ap, fmt);
ffffffffc0200200:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200202:	f47ff0ef          	jal	ffffffffc0200148 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200206:	65a2                	ld	a1,8(sp)
ffffffffc0200208:	8522                	mv	a0,s0
ffffffffc020020a:	f1fff0ef          	jal	ffffffffc0200128 <vcprintf>
    cprintf("\n");
ffffffffc020020e:	00001517          	auipc	a0,0x1
ffffffffc0200212:	51a50513          	addi	a0,a0,1306 # ffffffffc0201728 <etext+0xf2>
ffffffffc0200216:	f33ff0ef          	jal	ffffffffc0200148 <cprintf>
ffffffffc020021a:	6442                	ld	s0,16(sp)
ffffffffc020021c:	b7d9                	j	ffffffffc02001e2 <__panic+0x1a>

ffffffffc020021e <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020021e:	8082                	ret

ffffffffc0200220 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200220:	0ff57513          	zext.b	a0,a0
ffffffffc0200224:	3560106f          	j	ffffffffc020157a <sbi_console_putchar>

ffffffffc0200228 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200228:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc020022a:	00001517          	auipc	a0,0x1
ffffffffc020022e:	50650513          	addi	a0,a0,1286 # ffffffffc0201730 <etext+0xfa>
void dtb_init(void) {
ffffffffc0200232:	f406                	sd	ra,40(sp)
ffffffffc0200234:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc0200236:	f13ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020023a:	00005597          	auipc	a1,0x5
ffffffffc020023e:	dc65b583          	ld	a1,-570(a1) # ffffffffc0205000 <boot_hartid>
ffffffffc0200242:	00001517          	auipc	a0,0x1
ffffffffc0200246:	4fe50513          	addi	a0,a0,1278 # ffffffffc0201740 <etext+0x10a>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020024a:	00005417          	auipc	s0,0x5
ffffffffc020024e:	dbe40413          	addi	s0,s0,-578 # ffffffffc0205008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200252:	ef7ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200256:	600c                	ld	a1,0(s0)
ffffffffc0200258:	00001517          	auipc	a0,0x1
ffffffffc020025c:	4f850513          	addi	a0,a0,1272 # ffffffffc0201750 <etext+0x11a>
ffffffffc0200260:	ee9ff0ef          	jal	ffffffffc0200148 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200264:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200266:	00001517          	auipc	a0,0x1
ffffffffc020026a:	50250513          	addi	a0,a0,1282 # ffffffffc0201768 <etext+0x132>
    if (boot_dtb == 0) {
ffffffffc020026e:	10070163          	beqz	a4,ffffffffc0200370 <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200272:	57f5                	li	a5,-3
ffffffffc0200274:	07fa                	slli	a5,a5,0x1e
ffffffffc0200276:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200278:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc020027a:	d00e06b7          	lui	a3,0xd00e0
ffffffffc020027e:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfedae75>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200282:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200286:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020028a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028e:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200292:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200296:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200298:	8e49                	or	a2,a2,a0
ffffffffc020029a:	0ff7f793          	zext.b	a5,a5
ffffffffc020029e:	8dd1                	or	a1,a1,a2
ffffffffc02002a0:	07a2                	slli	a5,a5,0x8
ffffffffc02002a2:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a4:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc02002a8:	0cd59863          	bne	a1,a3,ffffffffc0200378 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002ac:	4710                	lw	a2,8(a4)
ffffffffc02002ae:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02002b0:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002b2:	0086541b          	srliw	s0,a2,0x8
ffffffffc02002b6:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ba:	01865e1b          	srliw	t3,a2,0x18
ffffffffc02002be:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002c2:	0186151b          	slliw	a0,a2,0x18
ffffffffc02002c6:	0186959b          	slliw	a1,a3,0x18
ffffffffc02002ca:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ce:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d2:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d6:	0106d69b          	srliw	a3,a3,0x10
ffffffffc02002da:	01c56533          	or	a0,a0,t3
ffffffffc02002de:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e2:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e6:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ea:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ee:	0ff6f693          	zext.b	a3,a3
ffffffffc02002f2:	8c49                	or	s0,s0,a0
ffffffffc02002f4:	0622                	slli	a2,a2,0x8
ffffffffc02002f6:	8fcd                	or	a5,a5,a1
ffffffffc02002f8:	06a2                	slli	a3,a3,0x8
ffffffffc02002fa:	8c51                	or	s0,s0,a2
ffffffffc02002fc:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02002fe:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200300:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200302:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200304:	9381                	srli	a5,a5,0x20
ffffffffc0200306:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200308:	4301                	li	t1,0
        switch (token) {
ffffffffc020030a:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020030c:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020030e:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc0200312:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200314:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200316:	0087579b          	srliw	a5,a4,0x8
ffffffffc020031a:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020031e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200322:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200326:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020032e:	8ed1                	or	a3,a3,a2
ffffffffc0200330:	0ff77713          	zext.b	a4,a4
ffffffffc0200334:	8fd5                	or	a5,a5,a3
ffffffffc0200336:	0722                	slli	a4,a4,0x8
ffffffffc0200338:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc020033a:	05178763          	beq	a5,a7,ffffffffc0200388 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020033e:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc0200340:	00f8e963          	bltu	a7,a5,ffffffffc0200352 <dtb_init+0x12a>
ffffffffc0200344:	07c78d63          	beq	a5,t3,ffffffffc02003be <dtb_init+0x196>
ffffffffc0200348:	4709                	li	a4,2
ffffffffc020034a:	00e79763          	bne	a5,a4,ffffffffc0200358 <dtb_init+0x130>
ffffffffc020034e:	4301                	li	t1,0
ffffffffc0200350:	b7d1                	j	ffffffffc0200314 <dtb_init+0xec>
ffffffffc0200352:	4711                	li	a4,4
ffffffffc0200354:	fce780e3          	beq	a5,a4,ffffffffc0200314 <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200358:	00001517          	auipc	a0,0x1
ffffffffc020035c:	4d850513          	addi	a0,a0,1240 # ffffffffc0201830 <etext+0x1fa>
ffffffffc0200360:	de9ff0ef          	jal	ffffffffc0200148 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200364:	64e2                	ld	s1,24(sp)
ffffffffc0200366:	6942                	ld	s2,16(sp)
ffffffffc0200368:	00001517          	auipc	a0,0x1
ffffffffc020036c:	50050513          	addi	a0,a0,1280 # ffffffffc0201868 <etext+0x232>
}
ffffffffc0200370:	7402                	ld	s0,32(sp)
ffffffffc0200372:	70a2                	ld	ra,40(sp)
ffffffffc0200374:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc0200376:	bbc9                	j	ffffffffc0200148 <cprintf>
}
ffffffffc0200378:	7402                	ld	s0,32(sp)
ffffffffc020037a:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020037c:	00001517          	auipc	a0,0x1
ffffffffc0200380:	40c50513          	addi	a0,a0,1036 # ffffffffc0201788 <etext+0x152>
}
ffffffffc0200384:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200386:	b3c9                	j	ffffffffc0200148 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200388:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020038a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020038e:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200392:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200396:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020039a:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020039e:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02003a2:	8ed1                	or	a3,a3,a2
ffffffffc02003a4:	0ff77713          	zext.b	a4,a4
ffffffffc02003a8:	8fd5                	or	a5,a5,a3
ffffffffc02003aa:	0722                	slli	a4,a4,0x8
ffffffffc02003ac:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02003ae:	04031463          	bnez	t1,ffffffffc02003f6 <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02003b2:	1782                	slli	a5,a5,0x20
ffffffffc02003b4:	9381                	srli	a5,a5,0x20
ffffffffc02003b6:	043d                	addi	s0,s0,15
ffffffffc02003b8:	943e                	add	s0,s0,a5
ffffffffc02003ba:	9871                	andi	s0,s0,-4
                break;
ffffffffc02003bc:	bfa1                	j	ffffffffc0200314 <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc02003be:	8522                	mv	a0,s0
ffffffffc02003c0:	e01a                	sd	t1,0(sp)
ffffffffc02003c2:	1d2010ef          	jal	ffffffffc0201594 <strlen>
ffffffffc02003c6:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003c8:	4619                	li	a2,6
ffffffffc02003ca:	8522                	mv	a0,s0
ffffffffc02003cc:	00001597          	auipc	a1,0x1
ffffffffc02003d0:	3e458593          	addi	a1,a1,996 # ffffffffc02017b0 <etext+0x17a>
ffffffffc02003d4:	228010ef          	jal	ffffffffc02015fc <strncmp>
ffffffffc02003d8:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003da:	0411                	addi	s0,s0,4
ffffffffc02003dc:	0004879b          	sext.w	a5,s1
ffffffffc02003e0:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003e2:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003e6:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003e8:	00a36333          	or	t1,t1,a0
                break;
ffffffffc02003ec:	00ff0837          	lui	a6,0xff0
ffffffffc02003f0:	488d                	li	a7,3
ffffffffc02003f2:	4e05                	li	t3,1
ffffffffc02003f4:	b705                	j	ffffffffc0200314 <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02003f6:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02003f8:	00001597          	auipc	a1,0x1
ffffffffc02003fc:	3c058593          	addi	a1,a1,960 # ffffffffc02017b8 <etext+0x182>
ffffffffc0200400:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200402:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200406:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020040a:	0187169b          	slliw	a3,a4,0x18
ffffffffc020040e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200412:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041a:	8ed1                	or	a3,a3,a2
ffffffffc020041c:	0ff77713          	zext.b	a4,a4
ffffffffc0200420:	0722                	slli	a4,a4,0x8
ffffffffc0200422:	8d55                	or	a0,a0,a3
ffffffffc0200424:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200426:	1502                	slli	a0,a0,0x20
ffffffffc0200428:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020042a:	954a                	add	a0,a0,s2
ffffffffc020042c:	e01a                	sd	t1,0(sp)
ffffffffc020042e:	19a010ef          	jal	ffffffffc02015c8 <strcmp>
ffffffffc0200432:	67a2                	ld	a5,8(sp)
ffffffffc0200434:	473d                	li	a4,15
ffffffffc0200436:	6302                	ld	t1,0(sp)
ffffffffc0200438:	00ff0837          	lui	a6,0xff0
ffffffffc020043c:	488d                	li	a7,3
ffffffffc020043e:	4e05                	li	t3,1
ffffffffc0200440:	f6f779e3          	bgeu	a4,a5,ffffffffc02003b2 <dtb_init+0x18a>
ffffffffc0200444:	f53d                	bnez	a0,ffffffffc02003b2 <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200446:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020044a:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020044e:	00001517          	auipc	a0,0x1
ffffffffc0200452:	37250513          	addi	a0,a0,882 # ffffffffc02017c0 <etext+0x18a>
           fdt32_to_cpu(x >> 32);
ffffffffc0200456:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020045a:	0087d31b          	srliw	t1,a5,0x8
ffffffffc020045e:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200462:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200466:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046a:	0187959b          	slliw	a1,a5,0x18
ffffffffc020046e:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200472:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200476:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047a:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047e:	01037333          	and	t1,t1,a6
ffffffffc0200482:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200486:	01e5e5b3          	or	a1,a1,t5
ffffffffc020048a:	0ff7f793          	zext.b	a5,a5
ffffffffc020048e:	01de6e33          	or	t3,t3,t4
ffffffffc0200492:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200496:	01067633          	and	a2,a2,a6
ffffffffc020049a:	0086d31b          	srliw	t1,a3,0x8
ffffffffc020049e:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004a2:	07a2                	slli	a5,a5,0x8
ffffffffc02004a4:	0108d89b          	srliw	a7,a7,0x10
ffffffffc02004a8:	0186df1b          	srliw	t5,a3,0x18
ffffffffc02004ac:	01875e9b          	srliw	t4,a4,0x18
ffffffffc02004b0:	8ddd                	or	a1,a1,a5
ffffffffc02004b2:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b6:	0186979b          	slliw	a5,a3,0x18
ffffffffc02004ba:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004be:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ca:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ce:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d2:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d6:	08a2                	slli	a7,a7,0x8
ffffffffc02004d8:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004dc:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e0:	0ff6f693          	zext.b	a3,a3
ffffffffc02004e4:	01de6833          	or	a6,t3,t4
ffffffffc02004e8:	0ff77713          	zext.b	a4,a4
ffffffffc02004ec:	01166633          	or	a2,a2,a7
ffffffffc02004f0:	0067e7b3          	or	a5,a5,t1
ffffffffc02004f4:	06a2                	slli	a3,a3,0x8
ffffffffc02004f6:	01046433          	or	s0,s0,a6
ffffffffc02004fa:	0722                	slli	a4,a4,0x8
ffffffffc02004fc:	8fd5                	or	a5,a5,a3
ffffffffc02004fe:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc0200500:	1582                	slli	a1,a1,0x20
ffffffffc0200502:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200504:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200506:	9201                	srli	a2,a2,0x20
ffffffffc0200508:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020050a:	1402                	slli	s0,s0,0x20
ffffffffc020050c:	00b7e4b3          	or	s1,a5,a1
ffffffffc0200510:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200512:	c37ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200516:	85a6                	mv	a1,s1
ffffffffc0200518:	00001517          	auipc	a0,0x1
ffffffffc020051c:	2c850513          	addi	a0,a0,712 # ffffffffc02017e0 <etext+0x1aa>
ffffffffc0200520:	c29ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200524:	01445613          	srli	a2,s0,0x14
ffffffffc0200528:	85a2                	mv	a1,s0
ffffffffc020052a:	00001517          	auipc	a0,0x1
ffffffffc020052e:	2ce50513          	addi	a0,a0,718 # ffffffffc02017f8 <etext+0x1c2>
ffffffffc0200532:	c17ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200536:	009405b3          	add	a1,s0,s1
ffffffffc020053a:	15fd                	addi	a1,a1,-1
ffffffffc020053c:	00001517          	auipc	a0,0x1
ffffffffc0200540:	2dc50513          	addi	a0,a0,732 # ffffffffc0201818 <etext+0x1e2>
ffffffffc0200544:	c05ff0ef          	jal	ffffffffc0200148 <cprintf>
        memory_base = mem_base;
ffffffffc0200548:	00005797          	auipc	a5,0x5
ffffffffc020054c:	ae97bc23          	sd	s1,-1288(a5) # ffffffffc0205040 <memory_base>
        memory_size = mem_size;
ffffffffc0200550:	00005797          	auipc	a5,0x5
ffffffffc0200554:	ae87b423          	sd	s0,-1304(a5) # ffffffffc0205038 <memory_size>
ffffffffc0200558:	b531                	j	ffffffffc0200364 <dtb_init+0x13c>

ffffffffc020055a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020055a:	00005517          	auipc	a0,0x5
ffffffffc020055e:	ae653503          	ld	a0,-1306(a0) # ffffffffc0205040 <memory_base>
ffffffffc0200562:	8082                	ret

ffffffffc0200564 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200564:	00005517          	auipc	a0,0x5
ffffffffc0200568:	ad453503          	ld	a0,-1324(a0) # ffffffffc0205038 <memory_size>
ffffffffc020056c:	8082                	ret

ffffffffc020056e <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020056e:	00005797          	auipc	a5,0x5
ffffffffc0200572:	aaa78793          	addi	a5,a5,-1366 # ffffffffc0205018 <free_area>
ffffffffc0200576:	e79c                	sd	a5,8(a5)
ffffffffc0200578:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc020057a:	0007a823          	sw	zero,16(a5)
}
ffffffffc020057e:	8082                	ret

ffffffffc0200580 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200580:	00005517          	auipc	a0,0x5
ffffffffc0200584:	aa856503          	lwu	a0,-1368(a0) # ffffffffc0205028 <free_area+0x10>
ffffffffc0200588:	8082                	ret

ffffffffc020058a <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc020058a:	c145                	beqz	a0,ffffffffc020062a <best_fit_alloc_pages+0xa0>
    if (n > nr_free) {
ffffffffc020058c:	00005817          	auipc	a6,0x5
ffffffffc0200590:	a9c82803          	lw	a6,-1380(a6) # ffffffffc0205028 <free_area+0x10>
ffffffffc0200594:	86aa                	mv	a3,a0
ffffffffc0200596:	00005617          	auipc	a2,0x5
ffffffffc020059a:	a8260613          	addi	a2,a2,-1406 # ffffffffc0205018 <free_area>
ffffffffc020059e:	02081793          	slli	a5,a6,0x20
ffffffffc02005a2:	9381                	srli	a5,a5,0x20
ffffffffc02005a4:	08a7e163          	bltu	a5,a0,ffffffffc0200626 <best_fit_alloc_pages+0x9c>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02005a8:	661c                	ld	a5,8(a2)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02005aa:	06c78e63          	beq	a5,a2,ffffffffc0200626 <best_fit_alloc_pages+0x9c>
    size_t min_size = nr_free + 1;
ffffffffc02005ae:	0018059b          	addiw	a1,a6,1
ffffffffc02005b2:	1582                	slli	a1,a1,0x20
ffffffffc02005b4:	9181                	srli	a1,a1,0x20
    struct Page *page = NULL;
ffffffffc02005b6:	4501                	li	a0,0
        if (p->property >= n) {
ffffffffc02005b8:	ff87e703          	lwu	a4,-8(a5)
            if (p->property < min_size) {
ffffffffc02005bc:	00d76763          	bltu	a4,a3,ffffffffc02005ca <best_fit_alloc_pages+0x40>
ffffffffc02005c0:	00b77563          	bgeu	a4,a1,ffffffffc02005ca <best_fit_alloc_pages+0x40>
                min_size = p->property;
ffffffffc02005c4:	85ba                	mv	a1,a4
        struct Page *p = le2page(le, page_link);
ffffffffc02005c6:	fe878513          	addi	a0,a5,-24
ffffffffc02005ca:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02005cc:	fec796e3          	bne	a5,a2,ffffffffc02005b8 <best_fit_alloc_pages+0x2e>
    if (page != NULL) {
ffffffffc02005d0:	cd21                	beqz	a0,ffffffffc0200628 <best_fit_alloc_pages+0x9e>
        if (page->property > n) {
ffffffffc02005d2:	01052883          	lw	a7,16(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc02005d6:	6d18                	ld	a4,24(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc02005d8:	710c                	ld	a1,32(a0)
ffffffffc02005da:	02089793          	slli	a5,a7,0x20
ffffffffc02005de:	9381                	srli	a5,a5,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02005e0:	e70c                	sd	a1,8(a4)
    next->prev = prev;
ffffffffc02005e2:	e198                	sd	a4,0(a1)
ffffffffc02005e4:	02f6f963          	bgeu	a3,a5,ffffffffc0200616 <best_fit_alloc_pages+0x8c>
            struct Page *p = page + n;
ffffffffc02005e8:	00269793          	slli	a5,a3,0x2
ffffffffc02005ec:	97b6                	add	a5,a5,a3
ffffffffc02005ee:	078e                	slli	a5,a5,0x3
ffffffffc02005f0:	97aa                	add	a5,a5,a0
            SetPageProperty(p);
ffffffffc02005f2:	0087b303          	ld	t1,8(a5)
            p->property = page->property - n;
ffffffffc02005f6:	40d888bb          	subw	a7,a7,a3
ffffffffc02005fa:	0117a823          	sw	a7,16(a5)
            SetPageProperty(p);
ffffffffc02005fe:	00236893          	ori	a7,t1,2
ffffffffc0200602:	0117b423          	sd	a7,8(a5)
            list_add(prev, &(p->page_link));
ffffffffc0200606:	01878893          	addi	a7,a5,24
    prev->next = next->prev = elm;
ffffffffc020060a:	0115b023          	sd	a7,0(a1)
ffffffffc020060e:	01173423          	sd	a7,8(a4)
    elm->next = next;
ffffffffc0200612:	f38c                	sd	a1,32(a5)
    elm->prev = prev;
ffffffffc0200614:	ef98                	sd	a4,24(a5)
        ClearPageProperty(page);
ffffffffc0200616:	651c                	ld	a5,8(a0)
        nr_free -= n;
ffffffffc0200618:	40d8083b          	subw	a6,a6,a3
ffffffffc020061c:	01062823          	sw	a6,16(a2)
        ClearPageProperty(page);
ffffffffc0200620:	9bf5                	andi	a5,a5,-3
ffffffffc0200622:	e51c                	sd	a5,8(a0)
ffffffffc0200624:	8082                	ret
        return NULL;
ffffffffc0200626:	4501                	li	a0,0
}
ffffffffc0200628:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc020062a:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020062c:	00001697          	auipc	a3,0x1
ffffffffc0200630:	25468693          	addi	a3,a3,596 # ffffffffc0201880 <etext+0x24a>
ffffffffc0200634:	00001617          	auipc	a2,0x1
ffffffffc0200638:	25460613          	addi	a2,a2,596 # ffffffffc0201888 <etext+0x252>
ffffffffc020063c:	06b00593          	li	a1,107
ffffffffc0200640:	00001517          	auipc	a0,0x1
ffffffffc0200644:	26050513          	addi	a0,a0,608 # ffffffffc02018a0 <etext+0x26a>
best_fit_alloc_pages(size_t n) {
ffffffffc0200648:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020064a:	b7fff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc020064e <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc020064e:	711d                	addi	sp,sp,-96
ffffffffc0200650:	e0ca                	sd	s2,64(sp)
    return listelm->next;
ffffffffc0200652:	00005917          	auipc	s2,0x5
ffffffffc0200656:	9c690913          	addi	s2,s2,-1594 # ffffffffc0205018 <free_area>
ffffffffc020065a:	00893783          	ld	a5,8(s2)
ffffffffc020065e:	ec86                	sd	ra,88(sp)
ffffffffc0200660:	e8a2                	sd	s0,80(sp)
ffffffffc0200662:	e4a6                	sd	s1,72(sp)
ffffffffc0200664:	fc4e                	sd	s3,56(sp)
ffffffffc0200666:	f852                	sd	s4,48(sp)
ffffffffc0200668:	f456                	sd	s5,40(sp)
ffffffffc020066a:	f05a                	sd	s6,32(sp)
ffffffffc020066c:	ec5e                	sd	s7,24(sp)
ffffffffc020066e:	e862                	sd	s8,16(sp)
ffffffffc0200670:	e466                	sd	s9,8(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200672:	2b278f63          	beq	a5,s2,ffffffffc0200930 <best_fit_check+0x2e2>
    int count = 0, total = 0;
ffffffffc0200676:	4401                	li	s0,0
ffffffffc0200678:	4481                	li	s1,0
        struct Page *p = le2page(le, page_link); 
        assert(PageProperty(p));
ffffffffc020067a:	ff07b703          	ld	a4,-16(a5)
ffffffffc020067e:	8b09                	andi	a4,a4,2
ffffffffc0200680:	2a070c63          	beqz	a4,ffffffffc0200938 <best_fit_check+0x2ea>
        count ++, total += p->property;
ffffffffc0200684:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200688:	679c                	ld	a5,8(a5)
ffffffffc020068a:	2485                	addiw	s1,s1,1
ffffffffc020068c:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020068e:	ff2796e3          	bne	a5,s2,ffffffffc020067a <best_fit_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc0200692:	89a2                	mv	s3,s0
ffffffffc0200694:	13b000ef          	jal	ffffffffc0200fce <nr_free_pages>
ffffffffc0200698:	39351063          	bne	a0,s3,ffffffffc0200a18 <best_fit_check+0x3ca>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020069c:	4505                	li	a0,1
ffffffffc020069e:	119000ef          	jal	ffffffffc0200fb6 <alloc_pages>
ffffffffc02006a2:	8aaa                	mv	s5,a0
ffffffffc02006a4:	3a050a63          	beqz	a0,ffffffffc0200a58 <best_fit_check+0x40a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02006a8:	4505                	li	a0,1
ffffffffc02006aa:	10d000ef          	jal	ffffffffc0200fb6 <alloc_pages>
ffffffffc02006ae:	89aa                	mv	s3,a0
ffffffffc02006b0:	38050463          	beqz	a0,ffffffffc0200a38 <best_fit_check+0x3ea>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02006b4:	4505                	li	a0,1
ffffffffc02006b6:	101000ef          	jal	ffffffffc0200fb6 <alloc_pages>
ffffffffc02006ba:	8a2a                	mv	s4,a0
ffffffffc02006bc:	30050e63          	beqz	a0,ffffffffc02009d8 <best_fit_check+0x38a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02006c0:	40aa87b3          	sub	a5,s5,a0
ffffffffc02006c4:	40a98733          	sub	a4,s3,a0
ffffffffc02006c8:	0017b793          	seqz	a5,a5
ffffffffc02006cc:	00173713          	seqz	a4,a4
ffffffffc02006d0:	8fd9                	or	a5,a5,a4
ffffffffc02006d2:	2e079363          	bnez	a5,ffffffffc02009b8 <best_fit_check+0x36a>
ffffffffc02006d6:	2f3a8163          	beq	s5,s3,ffffffffc02009b8 <best_fit_check+0x36a>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02006da:	000aa783          	lw	a5,0(s5)
ffffffffc02006de:	26079d63          	bnez	a5,ffffffffc0200958 <best_fit_check+0x30a>
ffffffffc02006e2:	0009a783          	lw	a5,0(s3)
ffffffffc02006e6:	26079963          	bnez	a5,ffffffffc0200958 <best_fit_check+0x30a>
ffffffffc02006ea:	411c                	lw	a5,0(a0)
ffffffffc02006ec:	26079663          	bnez	a5,ffffffffc0200958 <best_fit_check+0x30a>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02006f0:	00005797          	auipc	a5,0x5
ffffffffc02006f4:	9807b783          	ld	a5,-1664(a5) # ffffffffc0205070 <pages>
ffffffffc02006f8:	ccccd737          	lui	a4,0xccccd
ffffffffc02006fc:	ccd70713          	addi	a4,a4,-819 # ffffffffcccccccd <end+0xcac7c55>
ffffffffc0200700:	02071693          	slli	a3,a4,0x20
ffffffffc0200704:	96ba                	add	a3,a3,a4
ffffffffc0200706:	40fa8733          	sub	a4,s5,a5
ffffffffc020070a:	870d                	srai	a4,a4,0x3
ffffffffc020070c:	02d70733          	mul	a4,a4,a3
ffffffffc0200710:	00002517          	auipc	a0,0x2
ffffffffc0200714:	8a053503          	ld	a0,-1888(a0) # ffffffffc0201fb0 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200718:	00005697          	auipc	a3,0x5
ffffffffc020071c:	9506b683          	ld	a3,-1712(a3) # ffffffffc0205068 <npage>
ffffffffc0200720:	06b2                	slli	a3,a3,0xc
ffffffffc0200722:	972a                	add	a4,a4,a0

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200724:	0732                	slli	a4,a4,0xc
ffffffffc0200726:	26d77963          	bgeu	a4,a3,ffffffffc0200998 <best_fit_check+0x34a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020072a:	ccccd5b7          	lui	a1,0xccccd
ffffffffc020072e:	ccd58593          	addi	a1,a1,-819 # ffffffffcccccccd <end+0xcac7c55>
ffffffffc0200732:	02059613          	slli	a2,a1,0x20
ffffffffc0200736:	40f98733          	sub	a4,s3,a5
ffffffffc020073a:	962e                	add	a2,a2,a1
ffffffffc020073c:	870d                	srai	a4,a4,0x3
ffffffffc020073e:	02c70733          	mul	a4,a4,a2
ffffffffc0200742:	972a                	add	a4,a4,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0200744:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200746:	40d77963          	bgeu	a4,a3,ffffffffc0200b58 <best_fit_check+0x50a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020074a:	40fa07b3          	sub	a5,s4,a5
ffffffffc020074e:	878d                	srai	a5,a5,0x3
ffffffffc0200750:	02c787b3          	mul	a5,a5,a2
ffffffffc0200754:	97aa                	add	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0200756:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200758:	3ed7f063          	bgeu	a5,a3,ffffffffc0200b38 <best_fit_check+0x4ea>
    assert(alloc_page() == NULL);
ffffffffc020075c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020075e:	00093c03          	ld	s8,0(s2)
ffffffffc0200762:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200766:	00005b17          	auipc	s6,0x5
ffffffffc020076a:	8c2b2b03          	lw	s6,-1854(s6) # ffffffffc0205028 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc020076e:	01293023          	sd	s2,0(s2)
ffffffffc0200772:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc0200776:	00005797          	auipc	a5,0x5
ffffffffc020077a:	8a07a923          	sw	zero,-1870(a5) # ffffffffc0205028 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc020077e:	039000ef          	jal	ffffffffc0200fb6 <alloc_pages>
ffffffffc0200782:	38051b63          	bnez	a0,ffffffffc0200b18 <best_fit_check+0x4ca>
    free_page(p0);
ffffffffc0200786:	8556                	mv	a0,s5
ffffffffc0200788:	4585                	li	a1,1
ffffffffc020078a:	039000ef          	jal	ffffffffc0200fc2 <free_pages>
    free_page(p1);
ffffffffc020078e:	854e                	mv	a0,s3
ffffffffc0200790:	4585                	li	a1,1
ffffffffc0200792:	031000ef          	jal	ffffffffc0200fc2 <free_pages>
    free_page(p2);
ffffffffc0200796:	8552                	mv	a0,s4
ffffffffc0200798:	4585                	li	a1,1
ffffffffc020079a:	029000ef          	jal	ffffffffc0200fc2 <free_pages>
    assert(nr_free == 3);
ffffffffc020079e:	00005717          	auipc	a4,0x5
ffffffffc02007a2:	88a72703          	lw	a4,-1910(a4) # ffffffffc0205028 <free_area+0x10>
ffffffffc02007a6:	478d                	li	a5,3
ffffffffc02007a8:	34f71863          	bne	a4,a5,ffffffffc0200af8 <best_fit_check+0x4aa>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02007ac:	4505                	li	a0,1
ffffffffc02007ae:	009000ef          	jal	ffffffffc0200fb6 <alloc_pages>
ffffffffc02007b2:	89aa                	mv	s3,a0
ffffffffc02007b4:	32050263          	beqz	a0,ffffffffc0200ad8 <best_fit_check+0x48a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02007b8:	4505                	li	a0,1
ffffffffc02007ba:	7fc000ef          	jal	ffffffffc0200fb6 <alloc_pages>
ffffffffc02007be:	8aaa                	mv	s5,a0
ffffffffc02007c0:	2e050c63          	beqz	a0,ffffffffc0200ab8 <best_fit_check+0x46a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02007c4:	4505                	li	a0,1
ffffffffc02007c6:	7f0000ef          	jal	ffffffffc0200fb6 <alloc_pages>
ffffffffc02007ca:	8a2a                	mv	s4,a0
ffffffffc02007cc:	2c050663          	beqz	a0,ffffffffc0200a98 <best_fit_check+0x44a>
    assert(alloc_page() == NULL);
ffffffffc02007d0:	4505                	li	a0,1
ffffffffc02007d2:	7e4000ef          	jal	ffffffffc0200fb6 <alloc_pages>
ffffffffc02007d6:	2a051163          	bnez	a0,ffffffffc0200a78 <best_fit_check+0x42a>
    free_page(p0);
ffffffffc02007da:	4585                	li	a1,1
ffffffffc02007dc:	854e                	mv	a0,s3
ffffffffc02007de:	7e4000ef          	jal	ffffffffc0200fc2 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02007e2:	00893783          	ld	a5,8(s2)
ffffffffc02007e6:	19278963          	beq	a5,s2,ffffffffc0200978 <best_fit_check+0x32a>
    assert((p = alloc_page()) == p0);
ffffffffc02007ea:	4505                	li	a0,1
ffffffffc02007ec:	7ca000ef          	jal	ffffffffc0200fb6 <alloc_pages>
ffffffffc02007f0:	8caa                	mv	s9,a0
ffffffffc02007f2:	54a99363          	bne	s3,a0,ffffffffc0200d38 <best_fit_check+0x6ea>
    assert(alloc_page() == NULL);
ffffffffc02007f6:	4505                	li	a0,1
ffffffffc02007f8:	7be000ef          	jal	ffffffffc0200fb6 <alloc_pages>
ffffffffc02007fc:	50051e63          	bnez	a0,ffffffffc0200d18 <best_fit_check+0x6ca>
    assert(nr_free == 0);
ffffffffc0200800:	00005797          	auipc	a5,0x5
ffffffffc0200804:	8287a783          	lw	a5,-2008(a5) # ffffffffc0205028 <free_area+0x10>
ffffffffc0200808:	4e079863          	bnez	a5,ffffffffc0200cf8 <best_fit_check+0x6aa>
    free_page(p);
ffffffffc020080c:	8566                	mv	a0,s9
ffffffffc020080e:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200810:	01893023          	sd	s8,0(s2)
ffffffffc0200814:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc0200818:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc020081c:	7a6000ef          	jal	ffffffffc0200fc2 <free_pages>
    free_page(p1);
ffffffffc0200820:	8556                	mv	a0,s5
ffffffffc0200822:	4585                	li	a1,1
ffffffffc0200824:	79e000ef          	jal	ffffffffc0200fc2 <free_pages>
    free_page(p2);
ffffffffc0200828:	8552                	mv	a0,s4
ffffffffc020082a:	4585                	li	a1,1
ffffffffc020082c:	796000ef          	jal	ffffffffc0200fc2 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200830:	4515                	li	a0,5
ffffffffc0200832:	784000ef          	jal	ffffffffc0200fb6 <alloc_pages>
ffffffffc0200836:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200838:	4a050063          	beqz	a0,ffffffffc0200cd8 <best_fit_check+0x68a>
    assert(!PageProperty(p0));
ffffffffc020083c:	651c                	ld	a5,8(a0)
ffffffffc020083e:	8b89                	andi	a5,a5,2
ffffffffc0200840:	46079c63          	bnez	a5,ffffffffc0200cb8 <best_fit_check+0x66a>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200844:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200846:	00093b83          	ld	s7,0(s2)
ffffffffc020084a:	00893b03          	ld	s6,8(s2)
ffffffffc020084e:	01293023          	sd	s2,0(s2)
ffffffffc0200852:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc0200856:	760000ef          	jal	ffffffffc0200fb6 <alloc_pages>
ffffffffc020085a:	42051f63          	bnez	a0,ffffffffc0200c98 <best_fit_check+0x64a>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc020085e:	4589                	li	a1,2
ffffffffc0200860:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200864:	00004c17          	auipc	s8,0x4
ffffffffc0200868:	7c4c2c03          	lw	s8,1988(s8) # ffffffffc0205028 <free_area+0x10>
    free_pages(p0 + 4, 1);
ffffffffc020086c:	0a098a93          	addi	s5,s3,160
    nr_free = 0;
ffffffffc0200870:	00004797          	auipc	a5,0x4
ffffffffc0200874:	7a07ac23          	sw	zero,1976(a5) # ffffffffc0205028 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200878:	74a000ef          	jal	ffffffffc0200fc2 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc020087c:	8556                	mv	a0,s5
ffffffffc020087e:	4585                	li	a1,1
ffffffffc0200880:	742000ef          	jal	ffffffffc0200fc2 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200884:	4511                	li	a0,4
ffffffffc0200886:	730000ef          	jal	ffffffffc0200fb6 <alloc_pages>
ffffffffc020088a:	3e051763          	bnez	a0,ffffffffc0200c78 <best_fit_check+0x62a>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc020088e:	0309b783          	ld	a5,48(s3)
ffffffffc0200892:	8b89                	andi	a5,a5,2
ffffffffc0200894:	3c078263          	beqz	a5,ffffffffc0200c58 <best_fit_check+0x60a>
ffffffffc0200898:	0389ac83          	lw	s9,56(s3)
ffffffffc020089c:	4789                	li	a5,2
ffffffffc020089e:	3afc9d63          	bne	s9,a5,ffffffffc0200c58 <best_fit_check+0x60a>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc02008a2:	4505                	li	a0,1
ffffffffc02008a4:	712000ef          	jal	ffffffffc0200fb6 <alloc_pages>
ffffffffc02008a8:	8a2a                	mv	s4,a0
ffffffffc02008aa:	38050763          	beqz	a0,ffffffffc0200c38 <best_fit_check+0x5ea>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc02008ae:	8566                	mv	a0,s9
ffffffffc02008b0:	706000ef          	jal	ffffffffc0200fb6 <alloc_pages>
ffffffffc02008b4:	36050263          	beqz	a0,ffffffffc0200c18 <best_fit_check+0x5ca>
    assert(p0 + 4 == p1);
ffffffffc02008b8:	354a9063          	bne	s5,s4,ffffffffc0200bf8 <best_fit_check+0x5aa>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc02008bc:	854e                	mv	a0,s3
ffffffffc02008be:	4595                	li	a1,5
ffffffffc02008c0:	702000ef          	jal	ffffffffc0200fc2 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02008c4:	4515                	li	a0,5
ffffffffc02008c6:	6f0000ef          	jal	ffffffffc0200fb6 <alloc_pages>
ffffffffc02008ca:	89aa                	mv	s3,a0
ffffffffc02008cc:	30050663          	beqz	a0,ffffffffc0200bd8 <best_fit_check+0x58a>
    assert(alloc_page() == NULL);
ffffffffc02008d0:	4505                	li	a0,1
ffffffffc02008d2:	6e4000ef          	jal	ffffffffc0200fb6 <alloc_pages>
ffffffffc02008d6:	2e051163          	bnez	a0,ffffffffc0200bb8 <best_fit_check+0x56a>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc02008da:	00004797          	auipc	a5,0x4
ffffffffc02008de:	74e7a783          	lw	a5,1870(a5) # ffffffffc0205028 <free_area+0x10>
ffffffffc02008e2:	2a079b63          	bnez	a5,ffffffffc0200b98 <best_fit_check+0x54a>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02008e6:	854e                	mv	a0,s3
ffffffffc02008e8:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc02008ea:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc02008ee:	01793023          	sd	s7,0(s2)
ffffffffc02008f2:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc02008f6:	6cc000ef          	jal	ffffffffc0200fc2 <free_pages>
    return listelm->next;
ffffffffc02008fa:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02008fe:	01278963          	beq	a5,s2,ffffffffc0200910 <best_fit_check+0x2c2>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200902:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200906:	679c                	ld	a5,8(a5)
ffffffffc0200908:	34fd                	addiw	s1,s1,-1
ffffffffc020090a:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020090c:	ff279be3          	bne	a5,s2,ffffffffc0200902 <best_fit_check+0x2b4>
    }
    assert(count == 0);
ffffffffc0200910:	26049463          	bnez	s1,ffffffffc0200b78 <best_fit_check+0x52a>
    assert(total == 0);
ffffffffc0200914:	e075                	bnez	s0,ffffffffc02009f8 <best_fit_check+0x3aa>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200916:	60e6                	ld	ra,88(sp)
ffffffffc0200918:	6446                	ld	s0,80(sp)
ffffffffc020091a:	64a6                	ld	s1,72(sp)
ffffffffc020091c:	6906                	ld	s2,64(sp)
ffffffffc020091e:	79e2                	ld	s3,56(sp)
ffffffffc0200920:	7a42                	ld	s4,48(sp)
ffffffffc0200922:	7aa2                	ld	s5,40(sp)
ffffffffc0200924:	7b02                	ld	s6,32(sp)
ffffffffc0200926:	6be2                	ld	s7,24(sp)
ffffffffc0200928:	6c42                	ld	s8,16(sp)
ffffffffc020092a:	6ca2                	ld	s9,8(sp)
ffffffffc020092c:	6125                	addi	sp,sp,96
ffffffffc020092e:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200930:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200932:	4401                	li	s0,0
ffffffffc0200934:	4481                	li	s1,0
ffffffffc0200936:	bbb9                	j	ffffffffc0200694 <best_fit_check+0x46>
        assert(PageProperty(p));
ffffffffc0200938:	00001697          	auipc	a3,0x1
ffffffffc020093c:	f8068693          	addi	a3,a3,-128 # ffffffffc02018b8 <etext+0x282>
ffffffffc0200940:	00001617          	auipc	a2,0x1
ffffffffc0200944:	f4860613          	addi	a2,a2,-184 # ffffffffc0201888 <etext+0x252>
ffffffffc0200948:	11200593          	li	a1,274
ffffffffc020094c:	00001517          	auipc	a0,0x1
ffffffffc0200950:	f5450513          	addi	a0,a0,-172 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200954:	875ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200958:	00001697          	auipc	a3,0x1
ffffffffc020095c:	01868693          	addi	a3,a3,24 # ffffffffc0201970 <etext+0x33a>
ffffffffc0200960:	00001617          	auipc	a2,0x1
ffffffffc0200964:	f2860613          	addi	a2,a2,-216 # ffffffffc0201888 <etext+0x252>
ffffffffc0200968:	0df00593          	li	a1,223
ffffffffc020096c:	00001517          	auipc	a0,0x1
ffffffffc0200970:	f3450513          	addi	a0,a0,-204 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200974:	855ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200978:	00001697          	auipc	a3,0x1
ffffffffc020097c:	0c068693          	addi	a3,a3,192 # ffffffffc0201a38 <etext+0x402>
ffffffffc0200980:	00001617          	auipc	a2,0x1
ffffffffc0200984:	f0860613          	addi	a2,a2,-248 # ffffffffc0201888 <etext+0x252>
ffffffffc0200988:	0fa00593          	li	a1,250
ffffffffc020098c:	00001517          	auipc	a0,0x1
ffffffffc0200990:	f1450513          	addi	a0,a0,-236 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200994:	835ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200998:	00001697          	auipc	a3,0x1
ffffffffc020099c:	01868693          	addi	a3,a3,24 # ffffffffc02019b0 <etext+0x37a>
ffffffffc02009a0:	00001617          	auipc	a2,0x1
ffffffffc02009a4:	ee860613          	addi	a2,a2,-280 # ffffffffc0201888 <etext+0x252>
ffffffffc02009a8:	0e100593          	li	a1,225
ffffffffc02009ac:	00001517          	auipc	a0,0x1
ffffffffc02009b0:	ef450513          	addi	a0,a0,-268 # ffffffffc02018a0 <etext+0x26a>
ffffffffc02009b4:	815ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02009b8:	00001697          	auipc	a3,0x1
ffffffffc02009bc:	f9068693          	addi	a3,a3,-112 # ffffffffc0201948 <etext+0x312>
ffffffffc02009c0:	00001617          	auipc	a2,0x1
ffffffffc02009c4:	ec860613          	addi	a2,a2,-312 # ffffffffc0201888 <etext+0x252>
ffffffffc02009c8:	0de00593          	li	a1,222
ffffffffc02009cc:	00001517          	auipc	a0,0x1
ffffffffc02009d0:	ed450513          	addi	a0,a0,-300 # ffffffffc02018a0 <etext+0x26a>
ffffffffc02009d4:	ff4ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02009d8:	00001697          	auipc	a3,0x1
ffffffffc02009dc:	f5068693          	addi	a3,a3,-176 # ffffffffc0201928 <etext+0x2f2>
ffffffffc02009e0:	00001617          	auipc	a2,0x1
ffffffffc02009e4:	ea860613          	addi	a2,a2,-344 # ffffffffc0201888 <etext+0x252>
ffffffffc02009e8:	0dc00593          	li	a1,220
ffffffffc02009ec:	00001517          	auipc	a0,0x1
ffffffffc02009f0:	eb450513          	addi	a0,a0,-332 # ffffffffc02018a0 <etext+0x26a>
ffffffffc02009f4:	fd4ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(total == 0);
ffffffffc02009f8:	00001697          	auipc	a3,0x1
ffffffffc02009fc:	17068693          	addi	a3,a3,368 # ffffffffc0201b68 <etext+0x532>
ffffffffc0200a00:	00001617          	auipc	a2,0x1
ffffffffc0200a04:	e8860613          	addi	a2,a2,-376 # ffffffffc0201888 <etext+0x252>
ffffffffc0200a08:	15400593          	li	a1,340
ffffffffc0200a0c:	00001517          	auipc	a0,0x1
ffffffffc0200a10:	e9450513          	addi	a0,a0,-364 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200a14:	fb4ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200a18:	00001697          	auipc	a3,0x1
ffffffffc0200a1c:	eb068693          	addi	a3,a3,-336 # ffffffffc02018c8 <etext+0x292>
ffffffffc0200a20:	00001617          	auipc	a2,0x1
ffffffffc0200a24:	e6860613          	addi	a2,a2,-408 # ffffffffc0201888 <etext+0x252>
ffffffffc0200a28:	11500593          	li	a1,277
ffffffffc0200a2c:	00001517          	auipc	a0,0x1
ffffffffc0200a30:	e7450513          	addi	a0,a0,-396 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200a34:	f94ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200a38:	00001697          	auipc	a3,0x1
ffffffffc0200a3c:	ed068693          	addi	a3,a3,-304 # ffffffffc0201908 <etext+0x2d2>
ffffffffc0200a40:	00001617          	auipc	a2,0x1
ffffffffc0200a44:	e4860613          	addi	a2,a2,-440 # ffffffffc0201888 <etext+0x252>
ffffffffc0200a48:	0db00593          	li	a1,219
ffffffffc0200a4c:	00001517          	auipc	a0,0x1
ffffffffc0200a50:	e5450513          	addi	a0,a0,-428 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200a54:	f74ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a58:	00001697          	auipc	a3,0x1
ffffffffc0200a5c:	e9068693          	addi	a3,a3,-368 # ffffffffc02018e8 <etext+0x2b2>
ffffffffc0200a60:	00001617          	auipc	a2,0x1
ffffffffc0200a64:	e2860613          	addi	a2,a2,-472 # ffffffffc0201888 <etext+0x252>
ffffffffc0200a68:	0da00593          	li	a1,218
ffffffffc0200a6c:	00001517          	auipc	a0,0x1
ffffffffc0200a70:	e3450513          	addi	a0,a0,-460 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200a74:	f54ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200a78:	00001697          	auipc	a3,0x1
ffffffffc0200a7c:	f9868693          	addi	a3,a3,-104 # ffffffffc0201a10 <etext+0x3da>
ffffffffc0200a80:	00001617          	auipc	a2,0x1
ffffffffc0200a84:	e0860613          	addi	a2,a2,-504 # ffffffffc0201888 <etext+0x252>
ffffffffc0200a88:	0f700593          	li	a1,247
ffffffffc0200a8c:	00001517          	auipc	a0,0x1
ffffffffc0200a90:	e1450513          	addi	a0,a0,-492 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200a94:	f34ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200a98:	00001697          	auipc	a3,0x1
ffffffffc0200a9c:	e9068693          	addi	a3,a3,-368 # ffffffffc0201928 <etext+0x2f2>
ffffffffc0200aa0:	00001617          	auipc	a2,0x1
ffffffffc0200aa4:	de860613          	addi	a2,a2,-536 # ffffffffc0201888 <etext+0x252>
ffffffffc0200aa8:	0f500593          	li	a1,245
ffffffffc0200aac:	00001517          	auipc	a0,0x1
ffffffffc0200ab0:	df450513          	addi	a0,a0,-524 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200ab4:	f14ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ab8:	00001697          	auipc	a3,0x1
ffffffffc0200abc:	e5068693          	addi	a3,a3,-432 # ffffffffc0201908 <etext+0x2d2>
ffffffffc0200ac0:	00001617          	auipc	a2,0x1
ffffffffc0200ac4:	dc860613          	addi	a2,a2,-568 # ffffffffc0201888 <etext+0x252>
ffffffffc0200ac8:	0f400593          	li	a1,244
ffffffffc0200acc:	00001517          	auipc	a0,0x1
ffffffffc0200ad0:	dd450513          	addi	a0,a0,-556 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200ad4:	ef4ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ad8:	00001697          	auipc	a3,0x1
ffffffffc0200adc:	e1068693          	addi	a3,a3,-496 # ffffffffc02018e8 <etext+0x2b2>
ffffffffc0200ae0:	00001617          	auipc	a2,0x1
ffffffffc0200ae4:	da860613          	addi	a2,a2,-600 # ffffffffc0201888 <etext+0x252>
ffffffffc0200ae8:	0f300593          	li	a1,243
ffffffffc0200aec:	00001517          	auipc	a0,0x1
ffffffffc0200af0:	db450513          	addi	a0,a0,-588 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200af4:	ed4ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(nr_free == 3);
ffffffffc0200af8:	00001697          	auipc	a3,0x1
ffffffffc0200afc:	f3068693          	addi	a3,a3,-208 # ffffffffc0201a28 <etext+0x3f2>
ffffffffc0200b00:	00001617          	auipc	a2,0x1
ffffffffc0200b04:	d8860613          	addi	a2,a2,-632 # ffffffffc0201888 <etext+0x252>
ffffffffc0200b08:	0f100593          	li	a1,241
ffffffffc0200b0c:	00001517          	auipc	a0,0x1
ffffffffc0200b10:	d9450513          	addi	a0,a0,-620 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200b14:	eb4ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200b18:	00001697          	auipc	a3,0x1
ffffffffc0200b1c:	ef868693          	addi	a3,a3,-264 # ffffffffc0201a10 <etext+0x3da>
ffffffffc0200b20:	00001617          	auipc	a2,0x1
ffffffffc0200b24:	d6860613          	addi	a2,a2,-664 # ffffffffc0201888 <etext+0x252>
ffffffffc0200b28:	0ec00593          	li	a1,236
ffffffffc0200b2c:	00001517          	auipc	a0,0x1
ffffffffc0200b30:	d7450513          	addi	a0,a0,-652 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200b34:	e94ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200b38:	00001697          	auipc	a3,0x1
ffffffffc0200b3c:	eb868693          	addi	a3,a3,-328 # ffffffffc02019f0 <etext+0x3ba>
ffffffffc0200b40:	00001617          	auipc	a2,0x1
ffffffffc0200b44:	d4860613          	addi	a2,a2,-696 # ffffffffc0201888 <etext+0x252>
ffffffffc0200b48:	0e300593          	li	a1,227
ffffffffc0200b4c:	00001517          	auipc	a0,0x1
ffffffffc0200b50:	d5450513          	addi	a0,a0,-684 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200b54:	e74ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200b58:	00001697          	auipc	a3,0x1
ffffffffc0200b5c:	e7868693          	addi	a3,a3,-392 # ffffffffc02019d0 <etext+0x39a>
ffffffffc0200b60:	00001617          	auipc	a2,0x1
ffffffffc0200b64:	d2860613          	addi	a2,a2,-728 # ffffffffc0201888 <etext+0x252>
ffffffffc0200b68:	0e200593          	li	a1,226
ffffffffc0200b6c:	00001517          	auipc	a0,0x1
ffffffffc0200b70:	d3450513          	addi	a0,a0,-716 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200b74:	e54ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(count == 0);
ffffffffc0200b78:	00001697          	auipc	a3,0x1
ffffffffc0200b7c:	fe068693          	addi	a3,a3,-32 # ffffffffc0201b58 <etext+0x522>
ffffffffc0200b80:	00001617          	auipc	a2,0x1
ffffffffc0200b84:	d0860613          	addi	a2,a2,-760 # ffffffffc0201888 <etext+0x252>
ffffffffc0200b88:	15300593          	li	a1,339
ffffffffc0200b8c:	00001517          	auipc	a0,0x1
ffffffffc0200b90:	d1450513          	addi	a0,a0,-748 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200b94:	e34ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(nr_free == 0);
ffffffffc0200b98:	00001697          	auipc	a3,0x1
ffffffffc0200b9c:	ed868693          	addi	a3,a3,-296 # ffffffffc0201a70 <etext+0x43a>
ffffffffc0200ba0:	00001617          	auipc	a2,0x1
ffffffffc0200ba4:	ce860613          	addi	a2,a2,-792 # ffffffffc0201888 <etext+0x252>
ffffffffc0200ba8:	14800593          	li	a1,328
ffffffffc0200bac:	00001517          	auipc	a0,0x1
ffffffffc0200bb0:	cf450513          	addi	a0,a0,-780 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200bb4:	e14ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200bb8:	00001697          	auipc	a3,0x1
ffffffffc0200bbc:	e5868693          	addi	a3,a3,-424 # ffffffffc0201a10 <etext+0x3da>
ffffffffc0200bc0:	00001617          	auipc	a2,0x1
ffffffffc0200bc4:	cc860613          	addi	a2,a2,-824 # ffffffffc0201888 <etext+0x252>
ffffffffc0200bc8:	14200593          	li	a1,322
ffffffffc0200bcc:	00001517          	auipc	a0,0x1
ffffffffc0200bd0:	cd450513          	addi	a0,a0,-812 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200bd4:	df4ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200bd8:	00001697          	auipc	a3,0x1
ffffffffc0200bdc:	f6068693          	addi	a3,a3,-160 # ffffffffc0201b38 <etext+0x502>
ffffffffc0200be0:	00001617          	auipc	a2,0x1
ffffffffc0200be4:	ca860613          	addi	a2,a2,-856 # ffffffffc0201888 <etext+0x252>
ffffffffc0200be8:	14100593          	li	a1,321
ffffffffc0200bec:	00001517          	auipc	a0,0x1
ffffffffc0200bf0:	cb450513          	addi	a0,a0,-844 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200bf4:	dd4ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200bf8:	00001697          	auipc	a3,0x1
ffffffffc0200bfc:	f3068693          	addi	a3,a3,-208 # ffffffffc0201b28 <etext+0x4f2>
ffffffffc0200c00:	00001617          	auipc	a2,0x1
ffffffffc0200c04:	c8860613          	addi	a2,a2,-888 # ffffffffc0201888 <etext+0x252>
ffffffffc0200c08:	13900593          	li	a1,313
ffffffffc0200c0c:	00001517          	auipc	a0,0x1
ffffffffc0200c10:	c9450513          	addi	a0,a0,-876 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200c14:	db4ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200c18:	00001697          	auipc	a3,0x1
ffffffffc0200c1c:	ef868693          	addi	a3,a3,-264 # ffffffffc0201b10 <etext+0x4da>
ffffffffc0200c20:	00001617          	auipc	a2,0x1
ffffffffc0200c24:	c6860613          	addi	a2,a2,-920 # ffffffffc0201888 <etext+0x252>
ffffffffc0200c28:	13800593          	li	a1,312
ffffffffc0200c2c:	00001517          	auipc	a0,0x1
ffffffffc0200c30:	c7450513          	addi	a0,a0,-908 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200c34:	d94ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200c38:	00001697          	auipc	a3,0x1
ffffffffc0200c3c:	eb868693          	addi	a3,a3,-328 # ffffffffc0201af0 <etext+0x4ba>
ffffffffc0200c40:	00001617          	auipc	a2,0x1
ffffffffc0200c44:	c4860613          	addi	a2,a2,-952 # ffffffffc0201888 <etext+0x252>
ffffffffc0200c48:	13700593          	li	a1,311
ffffffffc0200c4c:	00001517          	auipc	a0,0x1
ffffffffc0200c50:	c5450513          	addi	a0,a0,-940 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200c54:	d74ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200c58:	00001697          	auipc	a3,0x1
ffffffffc0200c5c:	e6868693          	addi	a3,a3,-408 # ffffffffc0201ac0 <etext+0x48a>
ffffffffc0200c60:	00001617          	auipc	a2,0x1
ffffffffc0200c64:	c2860613          	addi	a2,a2,-984 # ffffffffc0201888 <etext+0x252>
ffffffffc0200c68:	13500593          	li	a1,309
ffffffffc0200c6c:	00001517          	auipc	a0,0x1
ffffffffc0200c70:	c3450513          	addi	a0,a0,-972 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200c74:	d54ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200c78:	00001697          	auipc	a3,0x1
ffffffffc0200c7c:	e3068693          	addi	a3,a3,-464 # ffffffffc0201aa8 <etext+0x472>
ffffffffc0200c80:	00001617          	auipc	a2,0x1
ffffffffc0200c84:	c0860613          	addi	a2,a2,-1016 # ffffffffc0201888 <etext+0x252>
ffffffffc0200c88:	13400593          	li	a1,308
ffffffffc0200c8c:	00001517          	auipc	a0,0x1
ffffffffc0200c90:	c1450513          	addi	a0,a0,-1004 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200c94:	d34ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200c98:	00001697          	auipc	a3,0x1
ffffffffc0200c9c:	d7868693          	addi	a3,a3,-648 # ffffffffc0201a10 <etext+0x3da>
ffffffffc0200ca0:	00001617          	auipc	a2,0x1
ffffffffc0200ca4:	be860613          	addi	a2,a2,-1048 # ffffffffc0201888 <etext+0x252>
ffffffffc0200ca8:	12800593          	li	a1,296
ffffffffc0200cac:	00001517          	auipc	a0,0x1
ffffffffc0200cb0:	bf450513          	addi	a0,a0,-1036 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200cb4:	d14ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(!PageProperty(p0));
ffffffffc0200cb8:	00001697          	auipc	a3,0x1
ffffffffc0200cbc:	dd868693          	addi	a3,a3,-552 # ffffffffc0201a90 <etext+0x45a>
ffffffffc0200cc0:	00001617          	auipc	a2,0x1
ffffffffc0200cc4:	bc860613          	addi	a2,a2,-1080 # ffffffffc0201888 <etext+0x252>
ffffffffc0200cc8:	11f00593          	li	a1,287
ffffffffc0200ccc:	00001517          	auipc	a0,0x1
ffffffffc0200cd0:	bd450513          	addi	a0,a0,-1068 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200cd4:	cf4ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(p0 != NULL);
ffffffffc0200cd8:	00001697          	auipc	a3,0x1
ffffffffc0200cdc:	da868693          	addi	a3,a3,-600 # ffffffffc0201a80 <etext+0x44a>
ffffffffc0200ce0:	00001617          	auipc	a2,0x1
ffffffffc0200ce4:	ba860613          	addi	a2,a2,-1112 # ffffffffc0201888 <etext+0x252>
ffffffffc0200ce8:	11e00593          	li	a1,286
ffffffffc0200cec:	00001517          	auipc	a0,0x1
ffffffffc0200cf0:	bb450513          	addi	a0,a0,-1100 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200cf4:	cd4ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(nr_free == 0);
ffffffffc0200cf8:	00001697          	auipc	a3,0x1
ffffffffc0200cfc:	d7868693          	addi	a3,a3,-648 # ffffffffc0201a70 <etext+0x43a>
ffffffffc0200d00:	00001617          	auipc	a2,0x1
ffffffffc0200d04:	b8860613          	addi	a2,a2,-1144 # ffffffffc0201888 <etext+0x252>
ffffffffc0200d08:	10000593          	li	a1,256
ffffffffc0200d0c:	00001517          	auipc	a0,0x1
ffffffffc0200d10:	b9450513          	addi	a0,a0,-1132 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200d14:	cb4ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d18:	00001697          	auipc	a3,0x1
ffffffffc0200d1c:	cf868693          	addi	a3,a3,-776 # ffffffffc0201a10 <etext+0x3da>
ffffffffc0200d20:	00001617          	auipc	a2,0x1
ffffffffc0200d24:	b6860613          	addi	a2,a2,-1176 # ffffffffc0201888 <etext+0x252>
ffffffffc0200d28:	0fe00593          	li	a1,254
ffffffffc0200d2c:	00001517          	auipc	a0,0x1
ffffffffc0200d30:	b7450513          	addi	a0,a0,-1164 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200d34:	c94ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200d38:	00001697          	auipc	a3,0x1
ffffffffc0200d3c:	d1868693          	addi	a3,a3,-744 # ffffffffc0201a50 <etext+0x41a>
ffffffffc0200d40:	00001617          	auipc	a2,0x1
ffffffffc0200d44:	b4860613          	addi	a2,a2,-1208 # ffffffffc0201888 <etext+0x252>
ffffffffc0200d48:	0fd00593          	li	a1,253
ffffffffc0200d4c:	00001517          	auipc	a0,0x1
ffffffffc0200d50:	b5450513          	addi	a0,a0,-1196 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200d54:	c74ff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200d58 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200d58:	1141                	addi	sp,sp,-16
ffffffffc0200d5a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200d5c:	14058e63          	beqz	a1,ffffffffc0200eb8 <best_fit_free_pages+0x160>
    for (; p != base + n; p ++) {
ffffffffc0200d60:	00259713          	slli	a4,a1,0x2
ffffffffc0200d64:	972e                	add	a4,a4,a1
ffffffffc0200d66:	070e                	slli	a4,a4,0x3
ffffffffc0200d68:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0200d6c:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0200d6e:	cf09                	beqz	a4,ffffffffc0200d88 <best_fit_free_pages+0x30>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200d70:	6798                	ld	a4,8(a5)
ffffffffc0200d72:	8b0d                	andi	a4,a4,3
ffffffffc0200d74:	12071263          	bnez	a4,ffffffffc0200e98 <best_fit_free_pages+0x140>
        p->flags = 0;
ffffffffc0200d78:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200d7c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200d80:	02878793          	addi	a5,a5,40
ffffffffc0200d84:	fed796e3          	bne	a5,a3,ffffffffc0200d70 <best_fit_free_pages+0x18>
    SetPageProperty(base);
ffffffffc0200d88:	00853883          	ld	a7,8(a0)
    nr_free += n;
ffffffffc0200d8c:	00004717          	auipc	a4,0x4
ffffffffc0200d90:	29c72703          	lw	a4,668(a4) # ffffffffc0205028 <free_area+0x10>
ffffffffc0200d94:	00004697          	auipc	a3,0x4
ffffffffc0200d98:	28468693          	addi	a3,a3,644 # ffffffffc0205018 <free_area>
    return list->next == list;
ffffffffc0200d9c:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc0200d9e:	0028e613          	ori	a2,a7,2
    base->property = n;
ffffffffc0200da2:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200da4:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200da6:	9f2d                	addw	a4,a4,a1
ffffffffc0200da8:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0200daa:	0ad78763          	beq	a5,a3,ffffffffc0200e58 <best_fit_free_pages+0x100>
            struct Page* page = le2page(le, page_link);
ffffffffc0200dae:	fe878713          	addi	a4,a5,-24
ffffffffc0200db2:	4801                	li	a6,0
ffffffffc0200db4:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0200db8:	00e56a63          	bltu	a0,a4,ffffffffc0200dcc <best_fit_free_pages+0x74>
    return listelm->next;
ffffffffc0200dbc:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0200dbe:	06d70563          	beq	a4,a3,ffffffffc0200e28 <best_fit_free_pages+0xd0>
    struct Page *p = base;
ffffffffc0200dc2:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200dc4:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200dc8:	fee57ae3          	bgeu	a0,a4,ffffffffc0200dbc <best_fit_free_pages+0x64>
ffffffffc0200dcc:	00080463          	beqz	a6,ffffffffc0200dd4 <best_fit_free_pages+0x7c>
ffffffffc0200dd0:	0066b023          	sd	t1,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200dd4:	0007b803          	ld	a6,0(a5)
    prev->next = next->prev = elm;
ffffffffc0200dd8:	e390                	sd	a2,0(a5)
ffffffffc0200dda:	00c83423          	sd	a2,8(a6)
    elm->prev = prev;
ffffffffc0200dde:	01053c23          	sd	a6,24(a0)
    elm->next = next;
ffffffffc0200de2:	f11c                	sd	a5,32(a0)
    if (le != &free_list) {
ffffffffc0200de4:	02d80063          	beq	a6,a3,ffffffffc0200e04 <best_fit_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc0200de8:	ff882e03          	lw	t3,-8(a6)
        p = le2page(le, page_link);
ffffffffc0200dec:	fe880313          	addi	t1,a6,-24
        if (p + p->property == base) {
ffffffffc0200df0:	020e1613          	slli	a2,t3,0x20
ffffffffc0200df4:	9201                	srli	a2,a2,0x20
ffffffffc0200df6:	00261713          	slli	a4,a2,0x2
ffffffffc0200dfa:	9732                	add	a4,a4,a2
ffffffffc0200dfc:	070e                	slli	a4,a4,0x3
ffffffffc0200dfe:	971a                	add	a4,a4,t1
ffffffffc0200e00:	02e50e63          	beq	a0,a4,ffffffffc0200e3c <best_fit_free_pages+0xe4>
    if (le != &free_list) {
ffffffffc0200e04:	00d78f63          	beq	a5,a3,ffffffffc0200e22 <best_fit_free_pages+0xca>
        if (base + base->property == p) {
ffffffffc0200e08:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0200e0a:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc0200e0e:	02059613          	slli	a2,a1,0x20
ffffffffc0200e12:	9201                	srli	a2,a2,0x20
ffffffffc0200e14:	00261713          	slli	a4,a2,0x2
ffffffffc0200e18:	9732                	add	a4,a4,a2
ffffffffc0200e1a:	070e                	slli	a4,a4,0x3
ffffffffc0200e1c:	972a                	add	a4,a4,a0
ffffffffc0200e1e:	04e68a63          	beq	a3,a4,ffffffffc0200e72 <best_fit_free_pages+0x11a>
}
ffffffffc0200e22:	60a2                	ld	ra,8(sp)
ffffffffc0200e24:	0141                	addi	sp,sp,16
ffffffffc0200e26:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200e28:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200e2a:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0200e2c:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200e2e:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0200e30:	8332                	mv	t1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200e32:	02d70c63          	beq	a4,a3,ffffffffc0200e6a <best_fit_free_pages+0x112>
ffffffffc0200e36:	4805                	li	a6,1
    struct Page *p = base;
ffffffffc0200e38:	87ba                	mv	a5,a4
ffffffffc0200e3a:	b769                	j	ffffffffc0200dc4 <best_fit_free_pages+0x6c>
            p->property += base->property;
ffffffffc0200e3c:	01c585bb          	addw	a1,a1,t3
ffffffffc0200e40:	feb82c23          	sw	a1,-8(a6)
            ClearPageProperty(base);
ffffffffc0200e44:	ffd8f893          	andi	a7,a7,-3
ffffffffc0200e48:	01153423          	sd	a7,8(a0)
    prev->next = next;
ffffffffc0200e4c:	00f83423          	sd	a5,8(a6)
    next->prev = prev;
ffffffffc0200e50:	0107b023          	sd	a6,0(a5)
            base = p;
ffffffffc0200e54:	851a                	mv	a0,t1
ffffffffc0200e56:	b77d                	j	ffffffffc0200e04 <best_fit_free_pages+0xac>
}
ffffffffc0200e58:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0200e5a:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0200e5e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200e60:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0200e62:	e398                	sd	a4,0(a5)
ffffffffc0200e64:	e798                	sd	a4,8(a5)
}
ffffffffc0200e66:	0141                	addi	sp,sp,16
ffffffffc0200e68:	8082                	ret
    return listelm->prev;
ffffffffc0200e6a:	883e                	mv	a6,a5
ffffffffc0200e6c:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200e6e:	87b6                	mv	a5,a3
ffffffffc0200e70:	bf95                	j	ffffffffc0200de4 <best_fit_free_pages+0x8c>
            base->property += p->property;
ffffffffc0200e72:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(p);
ffffffffc0200e76:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200e7a:	0007b803          	ld	a6,0(a5)
ffffffffc0200e7e:	6790                	ld	a2,8(a5)
            base->property += p->property;
ffffffffc0200e80:	9ead                	addw	a3,a3,a1
ffffffffc0200e82:	c914                	sw	a3,16(a0)
            ClearPageProperty(p);
ffffffffc0200e84:	9b75                	andi	a4,a4,-3
ffffffffc0200e86:	fee7b823          	sd	a4,-16(a5)
}
ffffffffc0200e8a:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0200e8c:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0200e90:	01063023          	sd	a6,0(a2)
ffffffffc0200e94:	0141                	addi	sp,sp,16
ffffffffc0200e96:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200e98:	00001697          	auipc	a3,0x1
ffffffffc0200e9c:	ce068693          	addi	a3,a3,-800 # ffffffffc0201b78 <etext+0x542>
ffffffffc0200ea0:	00001617          	auipc	a2,0x1
ffffffffc0200ea4:	9e860613          	addi	a2,a2,-1560 # ffffffffc0201888 <etext+0x252>
ffffffffc0200ea8:	09a00593          	li	a1,154
ffffffffc0200eac:	00001517          	auipc	a0,0x1
ffffffffc0200eb0:	9f450513          	addi	a0,a0,-1548 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200eb4:	b14ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(n > 0);
ffffffffc0200eb8:	00001697          	auipc	a3,0x1
ffffffffc0200ebc:	9c868693          	addi	a3,a3,-1592 # ffffffffc0201880 <etext+0x24a>
ffffffffc0200ec0:	00001617          	auipc	a2,0x1
ffffffffc0200ec4:	9c860613          	addi	a2,a2,-1592 # ffffffffc0201888 <etext+0x252>
ffffffffc0200ec8:	09700593          	li	a1,151
ffffffffc0200ecc:	00001517          	auipc	a0,0x1
ffffffffc0200ed0:	9d450513          	addi	a0,a0,-1580 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200ed4:	af4ff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200ed8 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc0200ed8:	1141                	addi	sp,sp,-16
ffffffffc0200eda:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200edc:	cdcd                	beqz	a1,ffffffffc0200f96 <best_fit_init_memmap+0xbe>
    for (; p != base + n; p ++) {
ffffffffc0200ede:	00259713          	slli	a4,a1,0x2
ffffffffc0200ee2:	972e                	add	a4,a4,a1
ffffffffc0200ee4:	070e                	slli	a4,a4,0x3
ffffffffc0200ee6:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0200eea:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0200eec:	cf11                	beqz	a4,ffffffffc0200f08 <best_fit_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc0200eee:	6798                	ld	a4,8(a5)
ffffffffc0200ef0:	8b05                	andi	a4,a4,1
ffffffffc0200ef2:	c351                	beqz	a4,ffffffffc0200f76 <best_fit_init_memmap+0x9e>
        p->flags = p->property = 0;
ffffffffc0200ef4:	0007a823          	sw	zero,16(a5)
ffffffffc0200ef8:	0007b423          	sd	zero,8(a5)
ffffffffc0200efc:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200f00:	02878793          	addi	a5,a5,40
ffffffffc0200f04:	fef695e3          	bne	a3,a5,ffffffffc0200eee <best_fit_init_memmap+0x16>
    SetPageProperty(base);
ffffffffc0200f08:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc0200f0a:	00004717          	auipc	a4,0x4
ffffffffc0200f0e:	11e72703          	lw	a4,286(a4) # ffffffffc0205028 <free_area+0x10>
ffffffffc0200f12:	00004697          	auipc	a3,0x4
ffffffffc0200f16:	10668693          	addi	a3,a3,262 # ffffffffc0205018 <free_area>
    return list->next == list;
ffffffffc0200f1a:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc0200f1c:	00266613          	ori	a2,a2,2
    base->property = n;
ffffffffc0200f20:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200f22:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200f24:	9f2d                	addw	a4,a4,a1
ffffffffc0200f26:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0200f28:	00d79763          	bne	a5,a3,ffffffffc0200f36 <best_fit_init_memmap+0x5e>
ffffffffc0200f2c:	a01d                	j	ffffffffc0200f52 <best_fit_init_memmap+0x7a>
    return listelm->next;
ffffffffc0200f2e:	6798                	ld	a4,8(a5)
                } else if (list_next(le) == &free_list) {
ffffffffc0200f30:	02d70a63          	beq	a4,a3,ffffffffc0200f64 <best_fit_init_memmap+0x8c>
ffffffffc0200f34:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200f36:	fe878713          	addi	a4,a5,-24
                if (base < page) {
ffffffffc0200f3a:	fee57ae3          	bgeu	a0,a4,ffffffffc0200f2e <best_fit_init_memmap+0x56>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200f3e:	6398                	ld	a4,0(a5)
                    list_add_before(le, &(base->page_link));
ffffffffc0200f40:	01850693          	addi	a3,a0,24
    prev->next = next->prev = elm;
ffffffffc0200f44:	e394                	sd	a3,0(a5)
}
ffffffffc0200f46:	60a2                	ld	ra,8(sp)
ffffffffc0200f48:	e714                	sd	a3,8(a4)
    elm->prev = prev;
ffffffffc0200f4a:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc0200f4c:	f11c                	sd	a5,32(a0)
ffffffffc0200f4e:	0141                	addi	sp,sp,16
ffffffffc0200f50:	8082                	ret
ffffffffc0200f52:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0200f54:	01850713          	addi	a4,a0,24
ffffffffc0200f58:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200f5a:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0200f5c:	e398                	sd	a4,0(a5)
ffffffffc0200f5e:	e798                	sd	a4,8(a5)
}
ffffffffc0200f60:	0141                	addi	sp,sp,16
ffffffffc0200f62:	8082                	ret
ffffffffc0200f64:	60a2                	ld	ra,8(sp)
                    list_add(le, &(base->page_link));
ffffffffc0200f66:	01850713          	addi	a4,a0,24
ffffffffc0200f6a:	e798                	sd	a4,8(a5)
ffffffffc0200f6c:	e298                	sd	a4,0(a3)
    elm->next = next;
ffffffffc0200f6e:	f114                	sd	a3,32(a0)
    elm->prev = prev;
ffffffffc0200f70:	ed1c                	sd	a5,24(a0)
}
ffffffffc0200f72:	0141                	addi	sp,sp,16
ffffffffc0200f74:	8082                	ret
        assert(PageReserved(p));
ffffffffc0200f76:	00001697          	auipc	a3,0x1
ffffffffc0200f7a:	c2a68693          	addi	a3,a3,-982 # ffffffffc0201ba0 <etext+0x56a>
ffffffffc0200f7e:	00001617          	auipc	a2,0x1
ffffffffc0200f82:	90a60613          	addi	a2,a2,-1782 # ffffffffc0201888 <etext+0x252>
ffffffffc0200f86:	04a00593          	li	a1,74
ffffffffc0200f8a:	00001517          	auipc	a0,0x1
ffffffffc0200f8e:	91650513          	addi	a0,a0,-1770 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200f92:	a36ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(n > 0);
ffffffffc0200f96:	00001697          	auipc	a3,0x1
ffffffffc0200f9a:	8ea68693          	addi	a3,a3,-1814 # ffffffffc0201880 <etext+0x24a>
ffffffffc0200f9e:	00001617          	auipc	a2,0x1
ffffffffc0200fa2:	8ea60613          	addi	a2,a2,-1814 # ffffffffc0201888 <etext+0x252>
ffffffffc0200fa6:	04700593          	li	a1,71
ffffffffc0200faa:	00001517          	auipc	a0,0x1
ffffffffc0200fae:	8f650513          	addi	a0,a0,-1802 # ffffffffc02018a0 <etext+0x26a>
ffffffffc0200fb2:	a16ff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200fb6 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0200fb6:	00004797          	auipc	a5,0x4
ffffffffc0200fba:	0927b783          	ld	a5,146(a5) # ffffffffc0205048 <pmm_manager>
ffffffffc0200fbe:	6f9c                	ld	a5,24(a5)
ffffffffc0200fc0:	8782                	jr	a5

ffffffffc0200fc2 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0200fc2:	00004797          	auipc	a5,0x4
ffffffffc0200fc6:	0867b783          	ld	a5,134(a5) # ffffffffc0205048 <pmm_manager>
ffffffffc0200fca:	739c                	ld	a5,32(a5)
ffffffffc0200fcc:	8782                	jr	a5

ffffffffc0200fce <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc0200fce:	00004797          	auipc	a5,0x4
ffffffffc0200fd2:	07a7b783          	ld	a5,122(a5) # ffffffffc0205048 <pmm_manager>
ffffffffc0200fd6:	779c                	ld	a5,40(a5)
ffffffffc0200fd8:	8782                	jr	a5

ffffffffc0200fda <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200fda:	00001797          	auipc	a5,0x1
ffffffffc0200fde:	e0e78793          	addi	a5,a5,-498 # ffffffffc0201de8 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200fe2:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200fe4:	7139                	addi	sp,sp,-64
ffffffffc0200fe6:	fc06                	sd	ra,56(sp)
ffffffffc0200fe8:	f822                	sd	s0,48(sp)
ffffffffc0200fea:	f426                	sd	s1,40(sp)
ffffffffc0200fec:	ec4e                	sd	s3,24(sp)
ffffffffc0200fee:	f04a                	sd	s2,32(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200ff0:	00004417          	auipc	s0,0x4
ffffffffc0200ff4:	05840413          	addi	s0,s0,88 # ffffffffc0205048 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200ff8:	00001517          	auipc	a0,0x1
ffffffffc0200ffc:	bd050513          	addi	a0,a0,-1072 # ffffffffc0201bc8 <etext+0x592>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201000:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201002:	946ff0ef          	jal	ffffffffc0200148 <cprintf>
    pmm_manager->init();
ffffffffc0201006:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201008:	00004497          	auipc	s1,0x4
ffffffffc020100c:	05848493          	addi	s1,s1,88 # ffffffffc0205060 <va_pa_offset>
    pmm_manager->init();
ffffffffc0201010:	679c                	ld	a5,8(a5)
ffffffffc0201012:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201014:	57f5                	li	a5,-3
ffffffffc0201016:	07fa                	slli	a5,a5,0x1e
ffffffffc0201018:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc020101a:	d40ff0ef          	jal	ffffffffc020055a <get_memory_base>
ffffffffc020101e:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0201020:	d44ff0ef          	jal	ffffffffc0200564 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0201024:	14050c63          	beqz	a0,ffffffffc020117c <pmm_init+0x1a2>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201028:	00a98933          	add	s2,s3,a0
ffffffffc020102c:	e42a                	sd	a0,8(sp)
    cprintf("physcial memory map:\n");
ffffffffc020102e:	00001517          	auipc	a0,0x1
ffffffffc0201032:	be250513          	addi	a0,a0,-1054 # ffffffffc0201c10 <etext+0x5da>
ffffffffc0201036:	912ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc020103a:	65a2                	ld	a1,8(sp)
ffffffffc020103c:	864e                	mv	a2,s3
ffffffffc020103e:	fff90693          	addi	a3,s2,-1
ffffffffc0201042:	00001517          	auipc	a0,0x1
ffffffffc0201046:	be650513          	addi	a0,a0,-1050 # ffffffffc0201c28 <etext+0x5f2>
ffffffffc020104a:	8feff0ef          	jal	ffffffffc0200148 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc020104e:	c80007b7          	lui	a5,0xc8000
ffffffffc0201052:	85ca                	mv	a1,s2
ffffffffc0201054:	0d27e263          	bltu	a5,s2,ffffffffc0201118 <pmm_init+0x13e>
ffffffffc0201058:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020105a:	00005697          	auipc	a3,0x5
ffffffffc020105e:	01d68693          	addi	a3,a3,29 # ffffffffc0206077 <end+0xfff>
ffffffffc0201062:	8efd                	and	a3,a3,a5
    npage = maxpa / PGSIZE;
ffffffffc0201064:	81b1                	srli	a1,a1,0xc
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201066:	fff80837          	lui	a6,0xfff80
    npage = maxpa / PGSIZE;
ffffffffc020106a:	00004797          	auipc	a5,0x4
ffffffffc020106e:	feb7bf23          	sd	a1,-2(a5) # ffffffffc0205068 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201072:	00004797          	auipc	a5,0x4
ffffffffc0201076:	fed7bf23          	sd	a3,-2(a5) # ffffffffc0205070 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020107a:	982e                	add	a6,a6,a1
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020107c:	88b6                	mv	a7,a3
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020107e:	02080963          	beqz	a6,ffffffffc02010b0 <pmm_init+0xd6>
ffffffffc0201082:	00259613          	slli	a2,a1,0x2
ffffffffc0201086:	962e                	add	a2,a2,a1
ffffffffc0201088:	fec007b7          	lui	a5,0xfec00
ffffffffc020108c:	97b6                	add	a5,a5,a3
ffffffffc020108e:	060e                	slli	a2,a2,0x3
ffffffffc0201090:	963e                	add	a2,a2,a5
ffffffffc0201092:	87b6                	mv	a5,a3
        SetPageReserved(pages + i);
ffffffffc0201094:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201096:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9fafb0>
        SetPageReserved(pages + i);
ffffffffc020109a:	00176713          	ori	a4,a4,1
ffffffffc020109e:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02010a2:	fec799e3          	bne	a5,a2,ffffffffc0201094 <pmm_init+0xba>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010a6:	00281793          	slli	a5,a6,0x2
ffffffffc02010aa:	97c2                	add	a5,a5,a6
ffffffffc02010ac:	078e                	slli	a5,a5,0x3
ffffffffc02010ae:	96be                	add	a3,a3,a5
ffffffffc02010b0:	c02007b7          	lui	a5,0xc0200
ffffffffc02010b4:	0af6e863          	bltu	a3,a5,ffffffffc0201164 <pmm_init+0x18a>
ffffffffc02010b8:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02010ba:	77fd                	lui	a5,0xfffff
ffffffffc02010bc:	00f97933          	and	s2,s2,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010c0:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02010c2:	0526ed63          	bltu	a3,s2,ffffffffc020111c <pmm_init+0x142>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02010c6:	601c                	ld	a5,0(s0)
ffffffffc02010c8:	7b9c                	ld	a5,48(a5)
ffffffffc02010ca:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02010cc:	00001517          	auipc	a0,0x1
ffffffffc02010d0:	be450513          	addi	a0,a0,-1052 # ffffffffc0201cb0 <etext+0x67a>
ffffffffc02010d4:	874ff0ef          	jal	ffffffffc0200148 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02010d8:	00003597          	auipc	a1,0x3
ffffffffc02010dc:	f2858593          	addi	a1,a1,-216 # ffffffffc0204000 <boot_page_table_sv39>
ffffffffc02010e0:	00004797          	auipc	a5,0x4
ffffffffc02010e4:	f6b7bc23          	sd	a1,-136(a5) # ffffffffc0205058 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02010e8:	c02007b7          	lui	a5,0xc0200
ffffffffc02010ec:	0af5e463          	bltu	a1,a5,ffffffffc0201194 <pmm_init+0x1ba>
ffffffffc02010f0:	609c                	ld	a5,0(s1)
}
ffffffffc02010f2:	7442                	ld	s0,48(sp)
ffffffffc02010f4:	70e2                	ld	ra,56(sp)
ffffffffc02010f6:	74a2                	ld	s1,40(sp)
ffffffffc02010f8:	7902                	ld	s2,32(sp)
ffffffffc02010fa:	69e2                	ld	s3,24(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02010fc:	40f586b3          	sub	a3,a1,a5
ffffffffc0201100:	00004797          	auipc	a5,0x4
ffffffffc0201104:	f4d7b823          	sd	a3,-176(a5) # ffffffffc0205050 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201108:	00001517          	auipc	a0,0x1
ffffffffc020110c:	bc850513          	addi	a0,a0,-1080 # ffffffffc0201cd0 <etext+0x69a>
ffffffffc0201110:	8636                	mv	a2,a3
}
ffffffffc0201112:	6121                	addi	sp,sp,64
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201114:	834ff06f          	j	ffffffffc0200148 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc0201118:	85be                	mv	a1,a5
ffffffffc020111a:	bf3d                	j	ffffffffc0201058 <pmm_init+0x7e>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020111c:	6705                	lui	a4,0x1
ffffffffc020111e:	177d                	addi	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0201120:	96ba                	add	a3,a3,a4
ffffffffc0201122:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201124:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201128:	02b7f263          	bgeu	a5,a1,ffffffffc020114c <pmm_init+0x172>
    pmm_manager->init_memmap(base, n);
ffffffffc020112c:	6018                	ld	a4,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020112e:	fff80637          	lui	a2,0xfff80
ffffffffc0201132:	97b2                	add	a5,a5,a2
ffffffffc0201134:	00279513          	slli	a0,a5,0x2
ffffffffc0201138:	953e                	add	a0,a0,a5
ffffffffc020113a:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020113c:	40d90933          	sub	s2,s2,a3
ffffffffc0201140:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201142:	00c95593          	srli	a1,s2,0xc
ffffffffc0201146:	9546                	add	a0,a0,a7
ffffffffc0201148:	9782                	jalr	a5
}
ffffffffc020114a:	bfb5                	j	ffffffffc02010c6 <pmm_init+0xec>
        panic("pa2page called with invalid pa");
ffffffffc020114c:	00001617          	auipc	a2,0x1
ffffffffc0201150:	b3460613          	addi	a2,a2,-1228 # ffffffffc0201c80 <etext+0x64a>
ffffffffc0201154:	06a00593          	li	a1,106
ffffffffc0201158:	00001517          	auipc	a0,0x1
ffffffffc020115c:	b4850513          	addi	a0,a0,-1208 # ffffffffc0201ca0 <etext+0x66a>
ffffffffc0201160:	868ff0ef          	jal	ffffffffc02001c8 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201164:	00001617          	auipc	a2,0x1
ffffffffc0201168:	af460613          	addi	a2,a2,-1292 # ffffffffc0201c58 <etext+0x622>
ffffffffc020116c:	05e00593          	li	a1,94
ffffffffc0201170:	00001517          	auipc	a0,0x1
ffffffffc0201174:	a9050513          	addi	a0,a0,-1392 # ffffffffc0201c00 <etext+0x5ca>
ffffffffc0201178:	850ff0ef          	jal	ffffffffc02001c8 <__panic>
        panic("DTB memory info not available");
ffffffffc020117c:	00001617          	auipc	a2,0x1
ffffffffc0201180:	a6460613          	addi	a2,a2,-1436 # ffffffffc0201be0 <etext+0x5aa>
ffffffffc0201184:	04600593          	li	a1,70
ffffffffc0201188:	00001517          	auipc	a0,0x1
ffffffffc020118c:	a7850513          	addi	a0,a0,-1416 # ffffffffc0201c00 <etext+0x5ca>
ffffffffc0201190:	838ff0ef          	jal	ffffffffc02001c8 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201194:	86ae                	mv	a3,a1
ffffffffc0201196:	00001617          	auipc	a2,0x1
ffffffffc020119a:	ac260613          	addi	a2,a2,-1342 # ffffffffc0201c58 <etext+0x622>
ffffffffc020119e:	07900593          	li	a1,121
ffffffffc02011a2:	00001517          	auipc	a0,0x1
ffffffffc02011a6:	a5e50513          	addi	a0,a0,-1442 # ffffffffc0201c00 <etext+0x5ca>
ffffffffc02011aa:	81eff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc02011ae <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02011ae:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02011b0:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02011b4:	f022                	sd	s0,32(sp)
ffffffffc02011b6:	ec26                	sd	s1,24(sp)
ffffffffc02011b8:	e84a                	sd	s2,16(sp)
ffffffffc02011ba:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02011bc:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02011c0:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc02011c2:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02011c6:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02011ca:	84aa                	mv	s1,a0
ffffffffc02011cc:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc02011ce:	03067d63          	bgeu	a2,a6,ffffffffc0201208 <printnum+0x5a>
ffffffffc02011d2:	e44e                	sd	s3,8(sp)
ffffffffc02011d4:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02011d6:	4785                	li	a5,1
ffffffffc02011d8:	00e7d763          	bge	a5,a4,ffffffffc02011e6 <printnum+0x38>
            putch(padc, putdat);
ffffffffc02011dc:	85ca                	mv	a1,s2
ffffffffc02011de:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc02011e0:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02011e2:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02011e4:	fc65                	bnez	s0,ffffffffc02011dc <printnum+0x2e>
ffffffffc02011e6:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02011e8:	00001797          	auipc	a5,0x1
ffffffffc02011ec:	b2878793          	addi	a5,a5,-1240 # ffffffffc0201d10 <etext+0x6da>
ffffffffc02011f0:	97d2                	add	a5,a5,s4
}
ffffffffc02011f2:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02011f4:	0007c503          	lbu	a0,0(a5)
}
ffffffffc02011f8:	70a2                	ld	ra,40(sp)
ffffffffc02011fa:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02011fc:	85ca                	mv	a1,s2
ffffffffc02011fe:	87a6                	mv	a5,s1
}
ffffffffc0201200:	6942                	ld	s2,16(sp)
ffffffffc0201202:	64e2                	ld	s1,24(sp)
ffffffffc0201204:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201206:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201208:	03065633          	divu	a2,a2,a6
ffffffffc020120c:	8722                	mv	a4,s0
ffffffffc020120e:	fa1ff0ef          	jal	ffffffffc02011ae <printnum>
ffffffffc0201212:	bfd9                	j	ffffffffc02011e8 <printnum+0x3a>

ffffffffc0201214 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201214:	7119                	addi	sp,sp,-128
ffffffffc0201216:	f4a6                	sd	s1,104(sp)
ffffffffc0201218:	f0ca                	sd	s2,96(sp)
ffffffffc020121a:	ecce                	sd	s3,88(sp)
ffffffffc020121c:	e8d2                	sd	s4,80(sp)
ffffffffc020121e:	e4d6                	sd	s5,72(sp)
ffffffffc0201220:	e0da                	sd	s6,64(sp)
ffffffffc0201222:	f862                	sd	s8,48(sp)
ffffffffc0201224:	fc86                	sd	ra,120(sp)
ffffffffc0201226:	f8a2                	sd	s0,112(sp)
ffffffffc0201228:	fc5e                	sd	s7,56(sp)
ffffffffc020122a:	f466                	sd	s9,40(sp)
ffffffffc020122c:	f06a                	sd	s10,32(sp)
ffffffffc020122e:	ec6e                	sd	s11,24(sp)
ffffffffc0201230:	84aa                	mv	s1,a0
ffffffffc0201232:	8c32                	mv	s8,a2
ffffffffc0201234:	8a36                	mv	s4,a3
ffffffffc0201236:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201238:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020123c:	05500b13          	li	s6,85
ffffffffc0201240:	00001a97          	auipc	s5,0x1
ffffffffc0201244:	be0a8a93          	addi	s5,s5,-1056 # ffffffffc0201e20 <best_fit_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201248:	000c4503          	lbu	a0,0(s8)
ffffffffc020124c:	001c0413          	addi	s0,s8,1
ffffffffc0201250:	01350a63          	beq	a0,s3,ffffffffc0201264 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0201254:	cd0d                	beqz	a0,ffffffffc020128e <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0201256:	85ca                	mv	a1,s2
ffffffffc0201258:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020125a:	00044503          	lbu	a0,0(s0)
ffffffffc020125e:	0405                	addi	s0,s0,1
ffffffffc0201260:	ff351ae3          	bne	a0,s3,ffffffffc0201254 <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0201264:	5cfd                	li	s9,-1
ffffffffc0201266:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc0201268:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc020126c:	4b81                	li	s7,0
ffffffffc020126e:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201270:	00044683          	lbu	a3,0(s0)
ffffffffc0201274:	00140c13          	addi	s8,s0,1
ffffffffc0201278:	fdd6859b          	addiw	a1,a3,-35
ffffffffc020127c:	0ff5f593          	zext.b	a1,a1
ffffffffc0201280:	02bb6663          	bltu	s6,a1,ffffffffc02012ac <vprintfmt+0x98>
ffffffffc0201284:	058a                	slli	a1,a1,0x2
ffffffffc0201286:	95d6                	add	a1,a1,s5
ffffffffc0201288:	4198                	lw	a4,0(a1)
ffffffffc020128a:	9756                	add	a4,a4,s5
ffffffffc020128c:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020128e:	70e6                	ld	ra,120(sp)
ffffffffc0201290:	7446                	ld	s0,112(sp)
ffffffffc0201292:	74a6                	ld	s1,104(sp)
ffffffffc0201294:	7906                	ld	s2,96(sp)
ffffffffc0201296:	69e6                	ld	s3,88(sp)
ffffffffc0201298:	6a46                	ld	s4,80(sp)
ffffffffc020129a:	6aa6                	ld	s5,72(sp)
ffffffffc020129c:	6b06                	ld	s6,64(sp)
ffffffffc020129e:	7be2                	ld	s7,56(sp)
ffffffffc02012a0:	7c42                	ld	s8,48(sp)
ffffffffc02012a2:	7ca2                	ld	s9,40(sp)
ffffffffc02012a4:	7d02                	ld	s10,32(sp)
ffffffffc02012a6:	6de2                	ld	s11,24(sp)
ffffffffc02012a8:	6109                	addi	sp,sp,128
ffffffffc02012aa:	8082                	ret
            putch('%', putdat);
ffffffffc02012ac:	85ca                	mv	a1,s2
ffffffffc02012ae:	02500513          	li	a0,37
ffffffffc02012b2:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02012b4:	fff44783          	lbu	a5,-1(s0)
ffffffffc02012b8:	02500713          	li	a4,37
ffffffffc02012bc:	8c22                	mv	s8,s0
ffffffffc02012be:	f8e785e3          	beq	a5,a4,ffffffffc0201248 <vprintfmt+0x34>
ffffffffc02012c2:	ffec4783          	lbu	a5,-2(s8)
ffffffffc02012c6:	1c7d                	addi	s8,s8,-1
ffffffffc02012c8:	fee79de3          	bne	a5,a4,ffffffffc02012c2 <vprintfmt+0xae>
ffffffffc02012cc:	bfb5                	j	ffffffffc0201248 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc02012ce:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc02012d2:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc02012d4:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc02012d8:	fd06071b          	addiw	a4,a2,-48
ffffffffc02012dc:	24e56a63          	bltu	a0,a4,ffffffffc0201530 <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc02012e0:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012e2:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc02012e4:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc02012e8:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02012ec:	0197073b          	addw	a4,a4,s9
ffffffffc02012f0:	0017171b          	slliw	a4,a4,0x1
ffffffffc02012f4:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc02012f6:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02012fa:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02012fc:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0201300:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc0201304:	feb570e3          	bgeu	a0,a1,ffffffffc02012e4 <vprintfmt+0xd0>
            if (width < 0)
ffffffffc0201308:	f60d54e3          	bgez	s10,ffffffffc0201270 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc020130c:	8d66                	mv	s10,s9
ffffffffc020130e:	5cfd                	li	s9,-1
ffffffffc0201310:	b785                	j	ffffffffc0201270 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201312:	8db6                	mv	s11,a3
ffffffffc0201314:	8462                	mv	s0,s8
ffffffffc0201316:	bfa9                	j	ffffffffc0201270 <vprintfmt+0x5c>
ffffffffc0201318:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc020131a:	4b85                	li	s7,1
            goto reswitch;
ffffffffc020131c:	bf91                	j	ffffffffc0201270 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc020131e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201320:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201324:	00f74463          	blt	a4,a5,ffffffffc020132c <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0201328:	1a078763          	beqz	a5,ffffffffc02014d6 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc020132c:	000a3603          	ld	a2,0(s4)
ffffffffc0201330:	46c1                	li	a3,16
ffffffffc0201332:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201334:	000d879b          	sext.w	a5,s11
ffffffffc0201338:	876a                	mv	a4,s10
ffffffffc020133a:	85ca                	mv	a1,s2
ffffffffc020133c:	8526                	mv	a0,s1
ffffffffc020133e:	e71ff0ef          	jal	ffffffffc02011ae <printnum>
            break;
ffffffffc0201342:	b719                	j	ffffffffc0201248 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0201344:	000a2503          	lw	a0,0(s4)
ffffffffc0201348:	85ca                	mv	a1,s2
ffffffffc020134a:	0a21                	addi	s4,s4,8
ffffffffc020134c:	9482                	jalr	s1
            break;
ffffffffc020134e:	bded                	j	ffffffffc0201248 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201350:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201352:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201356:	00f74463          	blt	a4,a5,ffffffffc020135e <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc020135a:	16078963          	beqz	a5,ffffffffc02014cc <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc020135e:	000a3603          	ld	a2,0(s4)
ffffffffc0201362:	46a9                	li	a3,10
ffffffffc0201364:	8a2e                	mv	s4,a1
ffffffffc0201366:	b7f9                	j	ffffffffc0201334 <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc0201368:	85ca                	mv	a1,s2
ffffffffc020136a:	03000513          	li	a0,48
ffffffffc020136e:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc0201370:	85ca                	mv	a1,s2
ffffffffc0201372:	07800513          	li	a0,120
ffffffffc0201376:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201378:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc020137c:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020137e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201380:	bf55                	j	ffffffffc0201334 <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc0201382:	85ca                	mv	a1,s2
ffffffffc0201384:	02500513          	li	a0,37
ffffffffc0201388:	9482                	jalr	s1
            break;
ffffffffc020138a:	bd7d                	j	ffffffffc0201248 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc020138c:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201390:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0201392:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0201394:	bf95                	j	ffffffffc0201308 <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc0201396:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201398:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020139c:	00f74463          	blt	a4,a5,ffffffffc02013a4 <vprintfmt+0x190>
    else if (lflag) {
ffffffffc02013a0:	12078163          	beqz	a5,ffffffffc02014c2 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc02013a4:	000a3603          	ld	a2,0(s4)
ffffffffc02013a8:	46a1                	li	a3,8
ffffffffc02013aa:	8a2e                	mv	s4,a1
ffffffffc02013ac:	b761                	j	ffffffffc0201334 <vprintfmt+0x120>
            if (width < 0)
ffffffffc02013ae:	876a                	mv	a4,s10
ffffffffc02013b0:	000d5363          	bgez	s10,ffffffffc02013b6 <vprintfmt+0x1a2>
ffffffffc02013b4:	4701                	li	a4,0
ffffffffc02013b6:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013ba:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc02013bc:	bd55                	j	ffffffffc0201270 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc02013be:	000d841b          	sext.w	s0,s11
ffffffffc02013c2:	fd340793          	addi	a5,s0,-45
ffffffffc02013c6:	00f037b3          	snez	a5,a5
ffffffffc02013ca:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02013ce:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc02013d2:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02013d4:	008a0793          	addi	a5,s4,8
ffffffffc02013d8:	e43e                	sd	a5,8(sp)
ffffffffc02013da:	100d8c63          	beqz	s11,ffffffffc02014f2 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc02013de:	12071363          	bnez	a4,ffffffffc0201504 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02013e2:	000dc783          	lbu	a5,0(s11)
ffffffffc02013e6:	0007851b          	sext.w	a0,a5
ffffffffc02013ea:	c78d                	beqz	a5,ffffffffc0201414 <vprintfmt+0x200>
ffffffffc02013ec:	0d85                	addi	s11,s11,1
ffffffffc02013ee:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02013f0:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02013f4:	000cc563          	bltz	s9,ffffffffc02013fe <vprintfmt+0x1ea>
ffffffffc02013f8:	3cfd                	addiw	s9,s9,-1
ffffffffc02013fa:	008c8d63          	beq	s9,s0,ffffffffc0201414 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02013fe:	020b9663          	bnez	s7,ffffffffc020142a <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc0201402:	85ca                	mv	a1,s2
ffffffffc0201404:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201406:	000dc783          	lbu	a5,0(s11)
ffffffffc020140a:	0d85                	addi	s11,s11,1
ffffffffc020140c:	3d7d                	addiw	s10,s10,-1
ffffffffc020140e:	0007851b          	sext.w	a0,a5
ffffffffc0201412:	f3ed                	bnez	a5,ffffffffc02013f4 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc0201414:	01a05963          	blez	s10,ffffffffc0201426 <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc0201418:	85ca                	mv	a1,s2
ffffffffc020141a:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc020141e:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0201420:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc0201422:	fe0d1be3          	bnez	s10,ffffffffc0201418 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201426:	6a22                	ld	s4,8(sp)
ffffffffc0201428:	b505                	j	ffffffffc0201248 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020142a:	3781                	addiw	a5,a5,-32
ffffffffc020142c:	fcfa7be3          	bgeu	s4,a5,ffffffffc0201402 <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0201430:	03f00513          	li	a0,63
ffffffffc0201434:	85ca                	mv	a1,s2
ffffffffc0201436:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201438:	000dc783          	lbu	a5,0(s11)
ffffffffc020143c:	0d85                	addi	s11,s11,1
ffffffffc020143e:	3d7d                	addiw	s10,s10,-1
ffffffffc0201440:	0007851b          	sext.w	a0,a5
ffffffffc0201444:	dbe1                	beqz	a5,ffffffffc0201414 <vprintfmt+0x200>
ffffffffc0201446:	fa0cd9e3          	bgez	s9,ffffffffc02013f8 <vprintfmt+0x1e4>
ffffffffc020144a:	b7c5                	j	ffffffffc020142a <vprintfmt+0x216>
            if (err < 0) {
ffffffffc020144c:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201450:	4619                	li	a2,6
            err = va_arg(ap, int);
ffffffffc0201452:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201454:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0201458:	8fb9                	xor	a5,a5,a4
ffffffffc020145a:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020145e:	02d64563          	blt	a2,a3,ffffffffc0201488 <vprintfmt+0x274>
ffffffffc0201462:	00001797          	auipc	a5,0x1
ffffffffc0201466:	b1678793          	addi	a5,a5,-1258 # ffffffffc0201f78 <error_string>
ffffffffc020146a:	00369713          	slli	a4,a3,0x3
ffffffffc020146e:	97ba                	add	a5,a5,a4
ffffffffc0201470:	639c                	ld	a5,0(a5)
ffffffffc0201472:	cb99                	beqz	a5,ffffffffc0201488 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201474:	86be                	mv	a3,a5
ffffffffc0201476:	00001617          	auipc	a2,0x1
ffffffffc020147a:	8ca60613          	addi	a2,a2,-1846 # ffffffffc0201d40 <etext+0x70a>
ffffffffc020147e:	85ca                	mv	a1,s2
ffffffffc0201480:	8526                	mv	a0,s1
ffffffffc0201482:	0d8000ef          	jal	ffffffffc020155a <printfmt>
ffffffffc0201486:	b3c9                	j	ffffffffc0201248 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201488:	00001617          	auipc	a2,0x1
ffffffffc020148c:	8a860613          	addi	a2,a2,-1880 # ffffffffc0201d30 <etext+0x6fa>
ffffffffc0201490:	85ca                	mv	a1,s2
ffffffffc0201492:	8526                	mv	a0,s1
ffffffffc0201494:	0c6000ef          	jal	ffffffffc020155a <printfmt>
ffffffffc0201498:	bb45                	j	ffffffffc0201248 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc020149a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020149c:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc02014a0:	00f74363          	blt	a4,a5,ffffffffc02014a6 <vprintfmt+0x292>
    else if (lflag) {
ffffffffc02014a4:	cf81                	beqz	a5,ffffffffc02014bc <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc02014a6:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02014aa:	02044b63          	bltz	s0,ffffffffc02014e0 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc02014ae:	8622                	mv	a2,s0
ffffffffc02014b0:	8a5e                	mv	s4,s7
ffffffffc02014b2:	46a9                	li	a3,10
ffffffffc02014b4:	b541                	j	ffffffffc0201334 <vprintfmt+0x120>
            lflag ++;
ffffffffc02014b6:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014b8:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc02014ba:	bb5d                	j	ffffffffc0201270 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc02014bc:	000a2403          	lw	s0,0(s4)
ffffffffc02014c0:	b7ed                	j	ffffffffc02014aa <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc02014c2:	000a6603          	lwu	a2,0(s4)
ffffffffc02014c6:	46a1                	li	a3,8
ffffffffc02014c8:	8a2e                	mv	s4,a1
ffffffffc02014ca:	b5ad                	j	ffffffffc0201334 <vprintfmt+0x120>
ffffffffc02014cc:	000a6603          	lwu	a2,0(s4)
ffffffffc02014d0:	46a9                	li	a3,10
ffffffffc02014d2:	8a2e                	mv	s4,a1
ffffffffc02014d4:	b585                	j	ffffffffc0201334 <vprintfmt+0x120>
ffffffffc02014d6:	000a6603          	lwu	a2,0(s4)
ffffffffc02014da:	46c1                	li	a3,16
ffffffffc02014dc:	8a2e                	mv	s4,a1
ffffffffc02014de:	bd99                	j	ffffffffc0201334 <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc02014e0:	85ca                	mv	a1,s2
ffffffffc02014e2:	02d00513          	li	a0,45
ffffffffc02014e6:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc02014e8:	40800633          	neg	a2,s0
ffffffffc02014ec:	8a5e                	mv	s4,s7
ffffffffc02014ee:	46a9                	li	a3,10
ffffffffc02014f0:	b591                	j	ffffffffc0201334 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc02014f2:	e329                	bnez	a4,ffffffffc0201534 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014f4:	02800793          	li	a5,40
ffffffffc02014f8:	853e                	mv	a0,a5
ffffffffc02014fa:	00001d97          	auipc	s11,0x1
ffffffffc02014fe:	82fd8d93          	addi	s11,s11,-2001 # ffffffffc0201d29 <etext+0x6f3>
ffffffffc0201502:	b5f5                	j	ffffffffc02013ee <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201504:	85e6                	mv	a1,s9
ffffffffc0201506:	856e                	mv	a0,s11
ffffffffc0201508:	0a4000ef          	jal	ffffffffc02015ac <strnlen>
ffffffffc020150c:	40ad0d3b          	subw	s10,s10,a0
ffffffffc0201510:	01a05863          	blez	s10,ffffffffc0201520 <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc0201514:	85ca                	mv	a1,s2
ffffffffc0201516:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201518:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc020151a:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020151c:	fe0d1ce3          	bnez	s10,ffffffffc0201514 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201520:	000dc783          	lbu	a5,0(s11)
ffffffffc0201524:	0007851b          	sext.w	a0,a5
ffffffffc0201528:	ec0792e3          	bnez	a5,ffffffffc02013ec <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020152c:	6a22                	ld	s4,8(sp)
ffffffffc020152e:	bb29                	j	ffffffffc0201248 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201530:	8462                	mv	s0,s8
ffffffffc0201532:	bbd9                	j	ffffffffc0201308 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201534:	85e6                	mv	a1,s9
ffffffffc0201536:	00000517          	auipc	a0,0x0
ffffffffc020153a:	7f250513          	addi	a0,a0,2034 # ffffffffc0201d28 <etext+0x6f2>
ffffffffc020153e:	06e000ef          	jal	ffffffffc02015ac <strnlen>
ffffffffc0201542:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201546:	02800793          	li	a5,40
                p = "(null)";
ffffffffc020154a:	00000d97          	auipc	s11,0x0
ffffffffc020154e:	7ded8d93          	addi	s11,s11,2014 # ffffffffc0201d28 <etext+0x6f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201552:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201554:	fda040e3          	bgtz	s10,ffffffffc0201514 <vprintfmt+0x300>
ffffffffc0201558:	bd51                	j	ffffffffc02013ec <vprintfmt+0x1d8>

ffffffffc020155a <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020155a:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020155c:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201560:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201562:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201564:	ec06                	sd	ra,24(sp)
ffffffffc0201566:	f83a                	sd	a4,48(sp)
ffffffffc0201568:	fc3e                	sd	a5,56(sp)
ffffffffc020156a:	e0c2                	sd	a6,64(sp)
ffffffffc020156c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020156e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201570:	ca5ff0ef          	jal	ffffffffc0201214 <vprintfmt>
}
ffffffffc0201574:	60e2                	ld	ra,24(sp)
ffffffffc0201576:	6161                	addi	sp,sp,80
ffffffffc0201578:	8082                	ret

ffffffffc020157a <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc020157a:	00004717          	auipc	a4,0x4
ffffffffc020157e:	a9673703          	ld	a4,-1386(a4) # ffffffffc0205010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201582:	4781                	li	a5,0
ffffffffc0201584:	88ba                	mv	a7,a4
ffffffffc0201586:	852a                	mv	a0,a0
ffffffffc0201588:	85be                	mv	a1,a5
ffffffffc020158a:	863e                	mv	a2,a5
ffffffffc020158c:	00000073          	ecall
ffffffffc0201590:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201592:	8082                	ret

ffffffffc0201594 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201594:	00054783          	lbu	a5,0(a0)
ffffffffc0201598:	cb81                	beqz	a5,ffffffffc02015a8 <strlen+0x14>
    size_t cnt = 0;
ffffffffc020159a:	4781                	li	a5,0
        cnt ++;
ffffffffc020159c:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc020159e:	00f50733          	add	a4,a0,a5
ffffffffc02015a2:	00074703          	lbu	a4,0(a4)
ffffffffc02015a6:	fb7d                	bnez	a4,ffffffffc020159c <strlen+0x8>
    }
    return cnt;
}
ffffffffc02015a8:	853e                	mv	a0,a5
ffffffffc02015aa:	8082                	ret

ffffffffc02015ac <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02015ac:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02015ae:	e589                	bnez	a1,ffffffffc02015b8 <strnlen+0xc>
ffffffffc02015b0:	a811                	j	ffffffffc02015c4 <strnlen+0x18>
        cnt ++;
ffffffffc02015b2:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02015b4:	00f58863          	beq	a1,a5,ffffffffc02015c4 <strnlen+0x18>
ffffffffc02015b8:	00f50733          	add	a4,a0,a5
ffffffffc02015bc:	00074703          	lbu	a4,0(a4)
ffffffffc02015c0:	fb6d                	bnez	a4,ffffffffc02015b2 <strnlen+0x6>
ffffffffc02015c2:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02015c4:	852e                	mv	a0,a1
ffffffffc02015c6:	8082                	ret

ffffffffc02015c8 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02015c8:	00054783          	lbu	a5,0(a0)
ffffffffc02015cc:	e791                	bnez	a5,ffffffffc02015d8 <strcmp+0x10>
ffffffffc02015ce:	a01d                	j	ffffffffc02015f4 <strcmp+0x2c>
ffffffffc02015d0:	00054783          	lbu	a5,0(a0)
ffffffffc02015d4:	cb99                	beqz	a5,ffffffffc02015ea <strcmp+0x22>
ffffffffc02015d6:	0585                	addi	a1,a1,1
ffffffffc02015d8:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc02015dc:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02015de:	fef709e3          	beq	a4,a5,ffffffffc02015d0 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02015e2:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02015e6:	9d19                	subw	a0,a0,a4
ffffffffc02015e8:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02015ea:	0015c703          	lbu	a4,1(a1)
ffffffffc02015ee:	4501                	li	a0,0
}
ffffffffc02015f0:	9d19                	subw	a0,a0,a4
ffffffffc02015f2:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02015f4:	0005c703          	lbu	a4,0(a1)
ffffffffc02015f8:	4501                	li	a0,0
ffffffffc02015fa:	b7f5                	j	ffffffffc02015e6 <strcmp+0x1e>

ffffffffc02015fc <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02015fc:	ce01                	beqz	a2,ffffffffc0201614 <strncmp+0x18>
ffffffffc02015fe:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201602:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201604:	cb91                	beqz	a5,ffffffffc0201618 <strncmp+0x1c>
ffffffffc0201606:	0005c703          	lbu	a4,0(a1)
ffffffffc020160a:	00f71763          	bne	a4,a5,ffffffffc0201618 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc020160e:	0505                	addi	a0,a0,1
ffffffffc0201610:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201612:	f675                	bnez	a2,ffffffffc02015fe <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201614:	4501                	li	a0,0
ffffffffc0201616:	8082                	ret
ffffffffc0201618:	00054503          	lbu	a0,0(a0)
ffffffffc020161c:	0005c783          	lbu	a5,0(a1)
ffffffffc0201620:	9d1d                	subw	a0,a0,a5
}
ffffffffc0201622:	8082                	ret

ffffffffc0201624 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201624:	ca01                	beqz	a2,ffffffffc0201634 <memset+0x10>
ffffffffc0201626:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201628:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020162a:	0785                	addi	a5,a5,1
ffffffffc020162c:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201630:	fef61de3          	bne	a2,a5,ffffffffc020162a <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201634:	8082                	ret
