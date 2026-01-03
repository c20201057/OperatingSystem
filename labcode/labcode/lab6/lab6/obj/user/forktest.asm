
obj/__user_forktest.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <_start>:
    # move down the esp register
    # since it may cause page fault in backtrace
    // subl $0x20, %esp

    # call user-program function
    call umain
  800020:	124000ef          	jal	800144 <umain>
1:  j 1b
  800024:	a001                	j	800024 <_start+0x4>

0000000000800026 <__panic>:
#include <stdio.h>
#include <ulib.h>
#include <error.h>

void
__panic(const char *file, int line, const char *fmt, ...) {
  800026:	715d                	addi	sp,sp,-80
    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
  800028:	02810313          	addi	t1,sp,40
__panic(const char *file, int line, const char *fmt, ...) {
  80002c:	e822                	sd	s0,16(sp)
  80002e:	8432                	mv	s0,a2
    cprintf("user panic at %s:%d:\n    ", file, line);
  800030:	862e                	mv	a2,a1
  800032:	85aa                	mv	a1,a0
  800034:	00000517          	auipc	a0,0x0
  800038:	5ac50513          	addi	a0,a0,1452 # 8005e0 <main+0xa8>
__panic(const char *file, int line, const char *fmt, ...) {
  80003c:	ec06                	sd	ra,24(sp)
  80003e:	f436                	sd	a3,40(sp)
  800040:	f83a                	sd	a4,48(sp)
  800042:	fc3e                	sd	a5,56(sp)
  800044:	e0c2                	sd	a6,64(sp)
  800046:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  800048:	e41a                	sd	t1,8(sp)
    cprintf("user panic at %s:%d:\n    ", file, line);
  80004a:	056000ef          	jal	8000a0 <cprintf>
    vcprintf(fmt, ap);
  80004e:	65a2                	ld	a1,8(sp)
  800050:	8522                	mv	a0,s0
  800052:	02e000ef          	jal	800080 <vcprintf>
    cprintf("\n");
  800056:	00000517          	auipc	a0,0x0
  80005a:	5aa50513          	addi	a0,a0,1450 # 800600 <main+0xc8>
  80005e:	042000ef          	jal	8000a0 <cprintf>
    va_end(ap);
    exit(-E_PANIC);
  800062:	5559                	li	a0,-10
  800064:	0c2000ef          	jal	800126 <exit>

0000000000800068 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
  800068:	1101                	addi	sp,sp,-32
  80006a:	ec06                	sd	ra,24(sp)
  80006c:	e42e                	sd	a1,8(sp)
    sys_putc(c);
  80006e:	0b2000ef          	jal	800120 <sys_putc>
    (*cnt) ++;
  800072:	65a2                	ld	a1,8(sp)
}
  800074:	60e2                	ld	ra,24(sp)
    (*cnt) ++;
  800076:	419c                	lw	a5,0(a1)
  800078:	2785                	addiw	a5,a5,1
  80007a:	c19c                	sw	a5,0(a1)
}
  80007c:	6105                	addi	sp,sp,32
  80007e:	8082                	ret

0000000000800080 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
  800080:	1101                	addi	sp,sp,-32
  800082:	862a                	mv	a2,a0
  800084:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  800086:	00000517          	auipc	a0,0x0
  80008a:	fe250513          	addi	a0,a0,-30 # 800068 <cputch>
  80008e:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
  800090:	ec06                	sd	ra,24(sp)
    int cnt = 0;
  800092:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  800094:	122000ef          	jal	8001b6 <vprintfmt>
    return cnt;
}
  800098:	60e2                	ld	ra,24(sp)
  80009a:	4532                	lw	a0,12(sp)
  80009c:	6105                	addi	sp,sp,32
  80009e:	8082                	ret

00000000008000a0 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
  8000a0:	711d                	addi	sp,sp,-96
    va_list ap;

    va_start(ap, fmt);
  8000a2:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
  8000a6:	f42e                	sd	a1,40(sp)
  8000a8:	f832                	sd	a2,48(sp)
  8000aa:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  8000ac:	862a                	mv	a2,a0
  8000ae:	004c                	addi	a1,sp,4
  8000b0:	00000517          	auipc	a0,0x0
  8000b4:	fb850513          	addi	a0,a0,-72 # 800068 <cputch>
  8000b8:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
  8000ba:	ec06                	sd	ra,24(sp)
  8000bc:	e0ba                	sd	a4,64(sp)
  8000be:	e4be                	sd	a5,72(sp)
  8000c0:	e8c2                	sd	a6,80(sp)
  8000c2:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
  8000c4:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
  8000c6:	e41a                	sd	t1,8(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  8000c8:	0ee000ef          	jal	8001b6 <vprintfmt>
    int cnt = vcprintf(fmt, ap);
    va_end(ap);

    return cnt;
}
  8000cc:	60e2                	ld	ra,24(sp)
  8000ce:	4512                	lw	a0,4(sp)
  8000d0:	6125                	addi	sp,sp,96
  8000d2:	8082                	ret

00000000008000d4 <syscall>:
#include <syscall.h>

#define MAX_ARGS            5

static inline int
syscall(int64_t num, ...) {
  8000d4:	7175                	addi	sp,sp,-144
    va_list ap;
    va_start(ap, num);
    uint64_t a[MAX_ARGS];
    int i, ret;
    for (i = 0; i < MAX_ARGS; i ++) {
        a[i] = va_arg(ap, uint64_t);
  8000d6:	08010313          	addi	t1,sp,128
syscall(int64_t num, ...) {
  8000da:	e42a                	sd	a0,8(sp)
  8000dc:	ecae                	sd	a1,88(sp)
        a[i] = va_arg(ap, uint64_t);
  8000de:	f42e                	sd	a1,40(sp)
syscall(int64_t num, ...) {
  8000e0:	f0b2                	sd	a2,96(sp)
        a[i] = va_arg(ap, uint64_t);
  8000e2:	f832                	sd	a2,48(sp)
syscall(int64_t num, ...) {
  8000e4:	f4b6                	sd	a3,104(sp)
        a[i] = va_arg(ap, uint64_t);
  8000e6:	fc36                	sd	a3,56(sp)
syscall(int64_t num, ...) {
  8000e8:	f8ba                	sd	a4,112(sp)
        a[i] = va_arg(ap, uint64_t);
  8000ea:	e0ba                	sd	a4,64(sp)
syscall(int64_t num, ...) {
  8000ec:	fcbe                	sd	a5,120(sp)
        a[i] = va_arg(ap, uint64_t);
  8000ee:	e4be                	sd	a5,72(sp)
syscall(int64_t num, ...) {
  8000f0:	e142                	sd	a6,128(sp)
  8000f2:	e546                	sd	a7,136(sp)
        a[i] = va_arg(ap, uint64_t);
  8000f4:	f01a                	sd	t1,32(sp)
    }
    va_end(ap);
    asm volatile (
  8000f6:	4522                	lw	a0,8(sp)
  8000f8:	55a2                	lw	a1,40(sp)
  8000fa:	5642                	lw	a2,48(sp)
  8000fc:	56e2                	lw	a3,56(sp)
  8000fe:	4706                	lw	a4,64(sp)
  800100:	47a6                	lw	a5,72(sp)
  800102:	00000073          	ecall
  800106:	ce2a                	sw	a0,28(sp)
          "m" (a[3]),
          "m" (a[4])
        : "memory"
      );
    return ret;
}
  800108:	4572                	lw	a0,28(sp)
  80010a:	6149                	addi	sp,sp,144
  80010c:	8082                	ret

000000000080010e <sys_exit>:

int
sys_exit(int64_t error_code) {
  80010e:	85aa                	mv	a1,a0
    return syscall(SYS_exit, error_code);
  800110:	4505                	li	a0,1
  800112:	b7c9                	j	8000d4 <syscall>

0000000000800114 <sys_fork>:
}

int
sys_fork(void) {
    return syscall(SYS_fork);
  800114:	4509                	li	a0,2
  800116:	bf7d                	j	8000d4 <syscall>

0000000000800118 <sys_wait>:
}

int
sys_wait(int64_t pid, int *store) {
  800118:	862e                	mv	a2,a1
    return syscall(SYS_wait, pid, store);
  80011a:	85aa                	mv	a1,a0
  80011c:	450d                	li	a0,3
  80011e:	bf5d                	j	8000d4 <syscall>

0000000000800120 <sys_putc>:
sys_getpid(void) {
    return syscall(SYS_getpid);
}

int
sys_putc(int64_t c) {
  800120:	85aa                	mv	a1,a0
    return syscall(SYS_putc, c);
  800122:	4579                	li	a0,30
  800124:	bf45                	j	8000d4 <syscall>

0000000000800126 <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  800126:	1141                	addi	sp,sp,-16
  800128:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  80012a:	fe5ff0ef          	jal	80010e <sys_exit>
    cprintf("BUG: exit failed.\n");
  80012e:	00000517          	auipc	a0,0x0
  800132:	4da50513          	addi	a0,a0,1242 # 800608 <main+0xd0>
  800136:	f6bff0ef          	jal	8000a0 <cprintf>
    while (1);
  80013a:	a001                	j	80013a <exit+0x14>

000000000080013c <fork>:
}

int
fork(void) {
    return sys_fork();
  80013c:	bfe1                	j	800114 <sys_fork>

000000000080013e <wait>:
}

int
wait(void) {
    return sys_wait(0, NULL);
  80013e:	4581                	li	a1,0
  800140:	4501                	li	a0,0
  800142:	bfd9                	j	800118 <sys_wait>

0000000000800144 <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  800144:	1141                	addi	sp,sp,-16
  800146:	e406                	sd	ra,8(sp)
    int ret = main();
  800148:	3f0000ef          	jal	800538 <main>
    exit(ret);
  80014c:	fdbff0ef          	jal	800126 <exit>

0000000000800150 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
  800150:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  800152:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800156:	f022                	sd	s0,32(sp)
  800158:	ec26                	sd	s1,24(sp)
  80015a:	e84a                	sd	s2,16(sp)
  80015c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  80015e:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800162:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
  800164:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  800168:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
  80016c:	84aa                	mv	s1,a0
  80016e:	892e                	mv	s2,a1
    if (num >= base) {
  800170:	03067d63          	bgeu	a2,a6,8001aa <printnum+0x5a>
  800174:	e44e                	sd	s3,8(sp)
  800176:	89be                	mv	s3,a5
        while (-- width > 0)
  800178:	4785                	li	a5,1
  80017a:	00e7d763          	bge	a5,a4,800188 <printnum+0x38>
            putch(padc, putdat);
  80017e:	85ca                	mv	a1,s2
  800180:	854e                	mv	a0,s3
        while (-- width > 0)
  800182:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  800184:	9482                	jalr	s1
        while (-- width > 0)
  800186:	fc65                	bnez	s0,80017e <printnum+0x2e>
  800188:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  80018a:	00000797          	auipc	a5,0x0
  80018e:	49678793          	addi	a5,a5,1174 # 800620 <main+0xe8>
  800192:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  800194:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  800196:	0007c503          	lbu	a0,0(a5)
}
  80019a:	70a2                	ld	ra,40(sp)
  80019c:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  80019e:	85ca                	mv	a1,s2
  8001a0:	87a6                	mv	a5,s1
}
  8001a2:	6942                	ld	s2,16(sp)
  8001a4:	64e2                	ld	s1,24(sp)
  8001a6:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  8001a8:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  8001aa:	03065633          	divu	a2,a2,a6
  8001ae:	8722                	mv	a4,s0
  8001b0:	fa1ff0ef          	jal	800150 <printnum>
  8001b4:	bfd9                	j	80018a <printnum+0x3a>

00000000008001b6 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  8001b6:	7119                	addi	sp,sp,-128
  8001b8:	f4a6                	sd	s1,104(sp)
  8001ba:	f0ca                	sd	s2,96(sp)
  8001bc:	ecce                	sd	s3,88(sp)
  8001be:	e8d2                	sd	s4,80(sp)
  8001c0:	e4d6                	sd	s5,72(sp)
  8001c2:	e0da                	sd	s6,64(sp)
  8001c4:	f862                	sd	s8,48(sp)
  8001c6:	fc86                	sd	ra,120(sp)
  8001c8:	f8a2                	sd	s0,112(sp)
  8001ca:	fc5e                	sd	s7,56(sp)
  8001cc:	f466                	sd	s9,40(sp)
  8001ce:	f06a                	sd	s10,32(sp)
  8001d0:	ec6e                	sd	s11,24(sp)
  8001d2:	84aa                	mv	s1,a0
  8001d4:	8c32                	mv	s8,a2
  8001d6:	8a36                	mv	s4,a3
  8001d8:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001da:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
  8001de:	05500b13          	li	s6,85
  8001e2:	00000a97          	auipc	s5,0x0
  8001e6:	5b6a8a93          	addi	s5,s5,1462 # 800798 <main+0x260>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001ea:	000c4503          	lbu	a0,0(s8)
  8001ee:	001c0413          	addi	s0,s8,1
  8001f2:	01350a63          	beq	a0,s3,800206 <vprintfmt+0x50>
            if (ch == '\0') {
  8001f6:	cd0d                	beqz	a0,800230 <vprintfmt+0x7a>
            putch(ch, putdat);
  8001f8:	85ca                	mv	a1,s2
  8001fa:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001fc:	00044503          	lbu	a0,0(s0)
  800200:	0405                	addi	s0,s0,1
  800202:	ff351ae3          	bne	a0,s3,8001f6 <vprintfmt+0x40>
        width = precision = -1;
  800206:	5cfd                	li	s9,-1
  800208:	8d66                	mv	s10,s9
        char padc = ' ';
  80020a:	02000d93          	li	s11,32
        lflag = altflag = 0;
  80020e:	4b81                	li	s7,0
  800210:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
  800212:	00044683          	lbu	a3,0(s0)
  800216:	00140c13          	addi	s8,s0,1
  80021a:	fdd6859b          	addiw	a1,a3,-35
  80021e:	0ff5f593          	zext.b	a1,a1
  800222:	02bb6663          	bltu	s6,a1,80024e <vprintfmt+0x98>
  800226:	058a                	slli	a1,a1,0x2
  800228:	95d6                	add	a1,a1,s5
  80022a:	4198                	lw	a4,0(a1)
  80022c:	9756                	add	a4,a4,s5
  80022e:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  800230:	70e6                	ld	ra,120(sp)
  800232:	7446                	ld	s0,112(sp)
  800234:	74a6                	ld	s1,104(sp)
  800236:	7906                	ld	s2,96(sp)
  800238:	69e6                	ld	s3,88(sp)
  80023a:	6a46                	ld	s4,80(sp)
  80023c:	6aa6                	ld	s5,72(sp)
  80023e:	6b06                	ld	s6,64(sp)
  800240:	7be2                	ld	s7,56(sp)
  800242:	7c42                	ld	s8,48(sp)
  800244:	7ca2                	ld	s9,40(sp)
  800246:	7d02                	ld	s10,32(sp)
  800248:	6de2                	ld	s11,24(sp)
  80024a:	6109                	addi	sp,sp,128
  80024c:	8082                	ret
            putch('%', putdat);
  80024e:	85ca                	mv	a1,s2
  800250:	02500513          	li	a0,37
  800254:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
  800256:	fff44783          	lbu	a5,-1(s0)
  80025a:	02500713          	li	a4,37
  80025e:	8c22                	mv	s8,s0
  800260:	f8e785e3          	beq	a5,a4,8001ea <vprintfmt+0x34>
  800264:	ffec4783          	lbu	a5,-2(s8)
  800268:	1c7d                	addi	s8,s8,-1
  80026a:	fee79de3          	bne	a5,a4,800264 <vprintfmt+0xae>
  80026e:	bfb5                	j	8001ea <vprintfmt+0x34>
                ch = *fmt;
  800270:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
  800274:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
  800276:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
  80027a:	fd06071b          	addiw	a4,a2,-48
  80027e:	24e56a63          	bltu	a0,a4,8004d2 <vprintfmt+0x31c>
                ch = *fmt;
  800282:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
  800284:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
  800286:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
  80028a:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
  80028e:	0197073b          	addw	a4,a4,s9
  800292:	0017171b          	slliw	a4,a4,0x1
  800296:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
  800298:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
  80029c:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  80029e:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
  8002a2:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
  8002a6:	feb570e3          	bgeu	a0,a1,800286 <vprintfmt+0xd0>
            if (width < 0)
  8002aa:	f60d54e3          	bgez	s10,800212 <vprintfmt+0x5c>
                width = precision, precision = -1;
  8002ae:	8d66                	mv	s10,s9
  8002b0:	5cfd                	li	s9,-1
  8002b2:	b785                	j	800212 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
  8002b4:	8db6                	mv	s11,a3
  8002b6:	8462                	mv	s0,s8
  8002b8:	bfa9                	j	800212 <vprintfmt+0x5c>
  8002ba:	8462                	mv	s0,s8
            altflag = 1;
  8002bc:	4b85                	li	s7,1
            goto reswitch;
  8002be:	bf91                	j	800212 <vprintfmt+0x5c>
    if (lflag >= 2) {
  8002c0:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002c2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002c6:	00f74463          	blt	a4,a5,8002ce <vprintfmt+0x118>
    else if (lflag) {
  8002ca:	1a078763          	beqz	a5,800478 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
  8002ce:	000a3603          	ld	a2,0(s4)
  8002d2:	46c1                	li	a3,16
  8002d4:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  8002d6:	000d879b          	sext.w	a5,s11
  8002da:	876a                	mv	a4,s10
  8002dc:	85ca                	mv	a1,s2
  8002de:	8526                	mv	a0,s1
  8002e0:	e71ff0ef          	jal	800150 <printnum>
            break;
  8002e4:	b719                	j	8001ea <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
  8002e6:	000a2503          	lw	a0,0(s4)
  8002ea:	85ca                	mv	a1,s2
  8002ec:	0a21                	addi	s4,s4,8
  8002ee:	9482                	jalr	s1
            break;
  8002f0:	bded                	j	8001ea <vprintfmt+0x34>
    if (lflag >= 2) {
  8002f2:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002f4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002f8:	00f74463          	blt	a4,a5,800300 <vprintfmt+0x14a>
    else if (lflag) {
  8002fc:	16078963          	beqz	a5,80046e <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
  800300:	000a3603          	ld	a2,0(s4)
  800304:	46a9                	li	a3,10
  800306:	8a2e                	mv	s4,a1
  800308:	b7f9                	j	8002d6 <vprintfmt+0x120>
            putch('0', putdat);
  80030a:	85ca                	mv	a1,s2
  80030c:	03000513          	li	a0,48
  800310:	9482                	jalr	s1
            putch('x', putdat);
  800312:	85ca                	mv	a1,s2
  800314:	07800513          	li	a0,120
  800318:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  80031a:	000a3603          	ld	a2,0(s4)
            goto number;
  80031e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  800320:	0a21                	addi	s4,s4,8
            goto number;
  800322:	bf55                	j	8002d6 <vprintfmt+0x120>
            putch(ch, putdat);
  800324:	85ca                	mv	a1,s2
  800326:	02500513          	li	a0,37
  80032a:	9482                	jalr	s1
            break;
  80032c:	bd7d                	j	8001ea <vprintfmt+0x34>
            precision = va_arg(ap, int);
  80032e:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  800332:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
  800334:	0a21                	addi	s4,s4,8
            goto process_precision;
  800336:	bf95                	j	8002aa <vprintfmt+0xf4>
    if (lflag >= 2) {
  800338:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80033a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  80033e:	00f74463          	blt	a4,a5,800346 <vprintfmt+0x190>
    else if (lflag) {
  800342:	12078163          	beqz	a5,800464 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
  800346:	000a3603          	ld	a2,0(s4)
  80034a:	46a1                	li	a3,8
  80034c:	8a2e                	mv	s4,a1
  80034e:	b761                	j	8002d6 <vprintfmt+0x120>
            if (width < 0)
  800350:	876a                	mv	a4,s10
  800352:	000d5363          	bgez	s10,800358 <vprintfmt+0x1a2>
  800356:	4701                	li	a4,0
  800358:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
  80035c:	8462                	mv	s0,s8
            goto reswitch;
  80035e:	bd55                	j	800212 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
  800360:	000d841b          	sext.w	s0,s11
  800364:	fd340793          	addi	a5,s0,-45
  800368:	00f037b3          	snez	a5,a5
  80036c:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
  800370:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
  800374:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
  800376:	008a0793          	addi	a5,s4,8
  80037a:	e43e                	sd	a5,8(sp)
  80037c:	100d8c63          	beqz	s11,800494 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
  800380:	12071363          	bnez	a4,8004a6 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800384:	000dc783          	lbu	a5,0(s11)
  800388:	0007851b          	sext.w	a0,a5
  80038c:	c78d                	beqz	a5,8003b6 <vprintfmt+0x200>
  80038e:	0d85                	addi	s11,s11,1
  800390:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
  800392:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800396:	000cc563          	bltz	s9,8003a0 <vprintfmt+0x1ea>
  80039a:	3cfd                	addiw	s9,s9,-1
  80039c:	008c8d63          	beq	s9,s0,8003b6 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
  8003a0:	020b9663          	bnez	s7,8003cc <vprintfmt+0x216>
                    putch(ch, putdat);
  8003a4:	85ca                	mv	a1,s2
  8003a6:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003a8:	000dc783          	lbu	a5,0(s11)
  8003ac:	0d85                	addi	s11,s11,1
  8003ae:	3d7d                	addiw	s10,s10,-1
  8003b0:	0007851b          	sext.w	a0,a5
  8003b4:	f3ed                	bnez	a5,800396 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
  8003b6:	01a05963          	blez	s10,8003c8 <vprintfmt+0x212>
                putch(' ', putdat);
  8003ba:	85ca                	mv	a1,s2
  8003bc:	02000513          	li	a0,32
            for (; width > 0; width --) {
  8003c0:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
  8003c2:	9482                	jalr	s1
            for (; width > 0; width --) {
  8003c4:	fe0d1be3          	bnez	s10,8003ba <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
  8003c8:	6a22                	ld	s4,8(sp)
  8003ca:	b505                	j	8001ea <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
  8003cc:	3781                	addiw	a5,a5,-32
  8003ce:	fcfa7be3          	bgeu	s4,a5,8003a4 <vprintfmt+0x1ee>
                    putch('?', putdat);
  8003d2:	03f00513          	li	a0,63
  8003d6:	85ca                	mv	a1,s2
  8003d8:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003da:	000dc783          	lbu	a5,0(s11)
  8003de:	0d85                	addi	s11,s11,1
  8003e0:	3d7d                	addiw	s10,s10,-1
  8003e2:	0007851b          	sext.w	a0,a5
  8003e6:	dbe1                	beqz	a5,8003b6 <vprintfmt+0x200>
  8003e8:	fa0cd9e3          	bgez	s9,80039a <vprintfmt+0x1e4>
  8003ec:	b7c5                	j	8003cc <vprintfmt+0x216>
            if (err < 0) {
  8003ee:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003f2:	4661                	li	a2,24
            err = va_arg(ap, int);
  8003f4:	0a21                	addi	s4,s4,8
            if (err < 0) {
  8003f6:	41f7d71b          	sraiw	a4,a5,0x1f
  8003fa:	8fb9                	xor	a5,a5,a4
  8003fc:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  800400:	02d64563          	blt	a2,a3,80042a <vprintfmt+0x274>
  800404:	00000797          	auipc	a5,0x0
  800408:	4ec78793          	addi	a5,a5,1260 # 8008f0 <error_string>
  80040c:	00369713          	slli	a4,a3,0x3
  800410:	97ba                	add	a5,a5,a4
  800412:	639c                	ld	a5,0(a5)
  800414:	cb99                	beqz	a5,80042a <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
  800416:	86be                	mv	a3,a5
  800418:	00000617          	auipc	a2,0x0
  80041c:	23860613          	addi	a2,a2,568 # 800650 <main+0x118>
  800420:	85ca                	mv	a1,s2
  800422:	8526                	mv	a0,s1
  800424:	0d8000ef          	jal	8004fc <printfmt>
  800428:	b3c9                	j	8001ea <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
  80042a:	00000617          	auipc	a2,0x0
  80042e:	21660613          	addi	a2,a2,534 # 800640 <main+0x108>
  800432:	85ca                	mv	a1,s2
  800434:	8526                	mv	a0,s1
  800436:	0c6000ef          	jal	8004fc <printfmt>
  80043a:	bb45                	j	8001ea <vprintfmt+0x34>
    if (lflag >= 2) {
  80043c:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80043e:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
  800442:	00f74363          	blt	a4,a5,800448 <vprintfmt+0x292>
    else if (lflag) {
  800446:	cf81                	beqz	a5,80045e <vprintfmt+0x2a8>
        return va_arg(*ap, long);
  800448:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  80044c:	02044b63          	bltz	s0,800482 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
  800450:	8622                	mv	a2,s0
  800452:	8a5e                	mv	s4,s7
  800454:	46a9                	li	a3,10
  800456:	b541                	j	8002d6 <vprintfmt+0x120>
            lflag ++;
  800458:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
  80045a:	8462                	mv	s0,s8
            goto reswitch;
  80045c:	bb5d                	j	800212 <vprintfmt+0x5c>
        return va_arg(*ap, int);
  80045e:	000a2403          	lw	s0,0(s4)
  800462:	b7ed                	j	80044c <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
  800464:	000a6603          	lwu	a2,0(s4)
  800468:	46a1                	li	a3,8
  80046a:	8a2e                	mv	s4,a1
  80046c:	b5ad                	j	8002d6 <vprintfmt+0x120>
  80046e:	000a6603          	lwu	a2,0(s4)
  800472:	46a9                	li	a3,10
  800474:	8a2e                	mv	s4,a1
  800476:	b585                	j	8002d6 <vprintfmt+0x120>
  800478:	000a6603          	lwu	a2,0(s4)
  80047c:	46c1                	li	a3,16
  80047e:	8a2e                	mv	s4,a1
  800480:	bd99                	j	8002d6 <vprintfmt+0x120>
                putch('-', putdat);
  800482:	85ca                	mv	a1,s2
  800484:	02d00513          	li	a0,45
  800488:	9482                	jalr	s1
                num = -(long long)num;
  80048a:	40800633          	neg	a2,s0
  80048e:	8a5e                	mv	s4,s7
  800490:	46a9                	li	a3,10
  800492:	b591                	j	8002d6 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
  800494:	e329                	bnez	a4,8004d6 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800496:	02800793          	li	a5,40
  80049a:	853e                	mv	a0,a5
  80049c:	00000d97          	auipc	s11,0x0
  8004a0:	19dd8d93          	addi	s11,s11,413 # 800639 <main+0x101>
  8004a4:	b5f5                	j	800390 <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004a6:	85e6                	mv	a1,s9
  8004a8:	856e                	mv	a0,s11
  8004aa:	072000ef          	jal	80051c <strnlen>
  8004ae:	40ad0d3b          	subw	s10,s10,a0
  8004b2:	01a05863          	blez	s10,8004c2 <vprintfmt+0x30c>
                    putch(padc, putdat);
  8004b6:	85ca                	mv	a1,s2
  8004b8:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004ba:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
  8004bc:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004be:	fe0d1ce3          	bnez	s10,8004b6 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004c2:	000dc783          	lbu	a5,0(s11)
  8004c6:	0007851b          	sext.w	a0,a5
  8004ca:	ec0792e3          	bnez	a5,80038e <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
  8004ce:	6a22                	ld	s4,8(sp)
  8004d0:	bb29                	j	8001ea <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
  8004d2:	8462                	mv	s0,s8
  8004d4:	bbd9                	j	8002aa <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004d6:	85e6                	mv	a1,s9
  8004d8:	00000517          	auipc	a0,0x0
  8004dc:	16050513          	addi	a0,a0,352 # 800638 <main+0x100>
  8004e0:	03c000ef          	jal	80051c <strnlen>
  8004e4:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004e8:	02800793          	li	a5,40
                p = "(null)";
  8004ec:	00000d97          	auipc	s11,0x0
  8004f0:	14cd8d93          	addi	s11,s11,332 # 800638 <main+0x100>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004f4:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004f6:	fda040e3          	bgtz	s10,8004b6 <vprintfmt+0x300>
  8004fa:	bd51                	j	80038e <vprintfmt+0x1d8>

00000000008004fc <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004fc:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  8004fe:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800502:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  800504:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800506:	ec06                	sd	ra,24(sp)
  800508:	f83a                	sd	a4,48(sp)
  80050a:	fc3e                	sd	a5,56(sp)
  80050c:	e0c2                	sd	a6,64(sp)
  80050e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  800510:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  800512:	ca5ff0ef          	jal	8001b6 <vprintfmt>
}
  800516:	60e2                	ld	ra,24(sp)
  800518:	6161                	addi	sp,sp,80
  80051a:	8082                	ret

000000000080051c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  80051c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  80051e:	e589                	bnez	a1,800528 <strnlen+0xc>
  800520:	a811                	j	800534 <strnlen+0x18>
        cnt ++;
  800522:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  800524:	00f58863          	beq	a1,a5,800534 <strnlen+0x18>
  800528:	00f50733          	add	a4,a0,a5
  80052c:	00074703          	lbu	a4,0(a4)
  800530:	fb6d                	bnez	a4,800522 <strnlen+0x6>
  800532:	85be                	mv	a1,a5
    }
    return cnt;
}
  800534:	852e                	mv	a0,a1
  800536:	8082                	ret

0000000000800538 <main>:
#include <stdio.h>

const int max_child = 32;

int
main(void) {
  800538:	1101                	addi	sp,sp,-32
  80053a:	e822                	sd	s0,16(sp)
  80053c:	e426                	sd	s1,8(sp)
  80053e:	ec06                	sd	ra,24(sp)
    int n, pid;
    for (n = 0; n < max_child; n ++) {
  800540:	4401                	li	s0,0
  800542:	02000493          	li	s1,32
        if ((pid = fork()) == 0) {
  800546:	bf7ff0ef          	jal	80013c <fork>
  80054a:	c915                	beqz	a0,80057e <main+0x46>
            cprintf("I am child %d\n", n);
            exit(0);
        }
        assert(pid > 0);
  80054c:	04a05e63          	blez	a0,8005a8 <main+0x70>
    for (n = 0; n < max_child; n ++) {
  800550:	2405                	addiw	s0,s0,1
  800552:	fe941ae3          	bne	s0,s1,800546 <main+0xe>
    if (n > max_child) {
        panic("fork claimed to work %d times!\n", n);
    }

    for (; n > 0; n --) {
        if (wait() != 0) {
  800556:	be9ff0ef          	jal	80013e <wait>
  80055a:	ed05                	bnez	a0,800592 <main+0x5a>
    for (; n > 0; n --) {
  80055c:	347d                	addiw	s0,s0,-1
  80055e:	fc65                	bnez	s0,800556 <main+0x1e>
            panic("wait stopped early\n");
        }
    }

    if (wait() == 0) {
  800560:	bdfff0ef          	jal	80013e <wait>
  800564:	c12d                	beqz	a0,8005c6 <main+0x8e>
        panic("wait got too many\n");
    }

    cprintf("forktest pass.\n");
  800566:	00000517          	auipc	a0,0x0
  80056a:	22250513          	addi	a0,a0,546 # 800788 <main+0x250>
  80056e:	b33ff0ef          	jal	8000a0 <cprintf>
    return 0;
}
  800572:	60e2                	ld	ra,24(sp)
  800574:	6442                	ld	s0,16(sp)
  800576:	64a2                	ld	s1,8(sp)
  800578:	4501                	li	a0,0
  80057a:	6105                	addi	sp,sp,32
  80057c:	8082                	ret
            cprintf("I am child %d\n", n);
  80057e:	85a2                	mv	a1,s0
  800580:	00000517          	auipc	a0,0x0
  800584:	19850513          	addi	a0,a0,408 # 800718 <main+0x1e0>
  800588:	b19ff0ef          	jal	8000a0 <cprintf>
            exit(0);
  80058c:	4501                	li	a0,0
  80058e:	b99ff0ef          	jal	800126 <exit>
            panic("wait stopped early\n");
  800592:	00000617          	auipc	a2,0x0
  800596:	1c660613          	addi	a2,a2,454 # 800758 <main+0x220>
  80059a:	45dd                	li	a1,23
  80059c:	00000517          	auipc	a0,0x0
  8005a0:	1ac50513          	addi	a0,a0,428 # 800748 <main+0x210>
  8005a4:	a83ff0ef          	jal	800026 <__panic>
        assert(pid > 0);
  8005a8:	00000697          	auipc	a3,0x0
  8005ac:	18068693          	addi	a3,a3,384 # 800728 <main+0x1f0>
  8005b0:	00000617          	auipc	a2,0x0
  8005b4:	18060613          	addi	a2,a2,384 # 800730 <main+0x1f8>
  8005b8:	45b9                	li	a1,14
  8005ba:	00000517          	auipc	a0,0x0
  8005be:	18e50513          	addi	a0,a0,398 # 800748 <main+0x210>
  8005c2:	a65ff0ef          	jal	800026 <__panic>
        panic("wait got too many\n");
  8005c6:	00000617          	auipc	a2,0x0
  8005ca:	1aa60613          	addi	a2,a2,426 # 800770 <main+0x238>
  8005ce:	45f1                	li	a1,28
  8005d0:	00000517          	auipc	a0,0x0
  8005d4:	17850513          	addi	a0,a0,376 # 800748 <main+0x210>
  8005d8:	a4fff0ef          	jal	800026 <__panic>
