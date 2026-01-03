
obj/__user_priority.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <_start>:
    # move down the esp register
    # since it may cause page fault in backtrace
    // subl $0x20, %esp

    # call user-program function
    call umain
  800020:	142000ef          	jal	800162 <umain>
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
  800038:	6e450513          	addi	a0,a0,1764 # 800718 <main+0x1b0>
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
  80005a:	6e250513          	addi	a0,a0,1762 # 800738 <main+0x1d0>
  80005e:	042000ef          	jal	8000a0 <cprintf>
    va_end(ap);
    exit(-E_PANIC);
  800062:	5559                	li	a0,-10
  800064:	0d8000ef          	jal	80013c <exit>

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
  80006e:	0bc000ef          	jal	80012a <sys_putc>
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
  800094:	140000ef          	jal	8001d4 <vprintfmt>
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
  8000c8:	10c000ef          	jal	8001d4 <vprintfmt>
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

0000000000800120 <sys_kill>:
sys_yield(void) {
    return syscall(SYS_yield);
}

int
sys_kill(int64_t pid) {
  800120:	85aa                	mv	a1,a0
    return syscall(SYS_kill, pid);
  800122:	4531                	li	a0,12
  800124:	bf45                	j	8000d4 <syscall>

0000000000800126 <sys_getpid>:
}

int
sys_getpid(void) {
    return syscall(SYS_getpid);
  800126:	4549                	li	a0,18
  800128:	b775                	j	8000d4 <syscall>

000000000080012a <sys_putc>:
}

int
sys_putc(int64_t c) {
  80012a:	85aa                	mv	a1,a0
    return syscall(SYS_putc, c);
  80012c:	4579                	li	a0,30
  80012e:	b75d                	j	8000d4 <syscall>

0000000000800130 <sys_gettime>:
    return syscall(SYS_pgdir);
}

int
sys_gettime(void) {
    return syscall(SYS_gettime);
  800130:	4545                	li	a0,17
  800132:	b74d                	j	8000d4 <syscall>

0000000000800134 <sys_lab6_set_priority>:
}

void
sys_lab6_set_priority(uint64_t priority)
{
  800134:	85aa                	mv	a1,a0
    syscall(SYS_lab6_set_priority, priority);
  800136:	0ff00513          	li	a0,255
  80013a:	bf69                	j	8000d4 <syscall>

000000000080013c <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  80013c:	1141                	addi	sp,sp,-16
  80013e:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  800140:	fcfff0ef          	jal	80010e <sys_exit>
    cprintf("BUG: exit failed.\n");
  800144:	00000517          	auipc	a0,0x0
  800148:	5fc50513          	addi	a0,a0,1532 # 800740 <main+0x1d8>
  80014c:	f55ff0ef          	jal	8000a0 <cprintf>
    while (1);
  800150:	a001                	j	800150 <exit+0x14>

0000000000800152 <fork>:
}

int
fork(void) {
    return sys_fork();
  800152:	b7c9                	j	800114 <sys_fork>

0000000000800154 <waitpid>:
    return sys_wait(0, NULL);
}

int
waitpid(int pid, int *store) {
    return sys_wait(pid, store);
  800154:	b7d1                	j	800118 <sys_wait>

0000000000800156 <kill>:
    sys_yield();
}

int
kill(int pid) {
    return sys_kill(pid);
  800156:	b7e9                	j	800120 <sys_kill>

0000000000800158 <getpid>:
}

int
getpid(void) {
    return sys_getpid();
  800158:	b7f9                	j	800126 <sys_getpid>

000000000080015a <gettime_msec>:
    sys_pgdir();
}

unsigned int
gettime_msec(void) {
    return (unsigned int)sys_gettime();
  80015a:	bfd9                	j	800130 <sys_gettime>

000000000080015c <lab6_setpriority>:
}

void
lab6_setpriority(uint32_t priority)
{
    sys_lab6_set_priority(priority);
  80015c:	1502                	slli	a0,a0,0x20
  80015e:	9101                	srli	a0,a0,0x20
  800160:	bfd1                	j	800134 <sys_lab6_set_priority>

0000000000800162 <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  800162:	1141                	addi	sp,sp,-16
  800164:	e406                	sd	ra,8(sp)
    int ret = main();
  800166:	402000ef          	jal	800568 <main>
    exit(ret);
  80016a:	fd3ff0ef          	jal	80013c <exit>

000000000080016e <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
  80016e:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  800170:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800174:	f022                	sd	s0,32(sp)
  800176:	ec26                	sd	s1,24(sp)
  800178:	e84a                	sd	s2,16(sp)
  80017a:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  80017c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800180:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
  800182:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  800186:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
  80018a:	84aa                	mv	s1,a0
  80018c:	892e                	mv	s2,a1
    if (num >= base) {
  80018e:	03067d63          	bgeu	a2,a6,8001c8 <printnum+0x5a>
  800192:	e44e                	sd	s3,8(sp)
  800194:	89be                	mv	s3,a5
        while (-- width > 0)
  800196:	4785                	li	a5,1
  800198:	00e7d763          	bge	a5,a4,8001a6 <printnum+0x38>
            putch(padc, putdat);
  80019c:	85ca                	mv	a1,s2
  80019e:	854e                	mv	a0,s3
        while (-- width > 0)
  8001a0:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  8001a2:	9482                	jalr	s1
        while (-- width > 0)
  8001a4:	fc65                	bnez	s0,80019c <printnum+0x2e>
  8001a6:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  8001a8:	00000797          	auipc	a5,0x0
  8001ac:	5b078793          	addi	a5,a5,1456 # 800758 <main+0x1f0>
  8001b0:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  8001b2:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  8001b4:	0007c503          	lbu	a0,0(a5)
}
  8001b8:	70a2                	ld	ra,40(sp)
  8001ba:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  8001bc:	85ca                	mv	a1,s2
  8001be:	87a6                	mv	a5,s1
}
  8001c0:	6942                	ld	s2,16(sp)
  8001c2:	64e2                	ld	s1,24(sp)
  8001c4:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  8001c6:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  8001c8:	03065633          	divu	a2,a2,a6
  8001cc:	8722                	mv	a4,s0
  8001ce:	fa1ff0ef          	jal	80016e <printnum>
  8001d2:	bfd9                	j	8001a8 <printnum+0x3a>

00000000008001d4 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  8001d4:	7119                	addi	sp,sp,-128
  8001d6:	f4a6                	sd	s1,104(sp)
  8001d8:	f0ca                	sd	s2,96(sp)
  8001da:	ecce                	sd	s3,88(sp)
  8001dc:	e8d2                	sd	s4,80(sp)
  8001de:	e4d6                	sd	s5,72(sp)
  8001e0:	e0da                	sd	s6,64(sp)
  8001e2:	f862                	sd	s8,48(sp)
  8001e4:	fc86                	sd	ra,120(sp)
  8001e6:	f8a2                	sd	s0,112(sp)
  8001e8:	fc5e                	sd	s7,56(sp)
  8001ea:	f466                	sd	s9,40(sp)
  8001ec:	f06a                	sd	s10,32(sp)
  8001ee:	ec6e                	sd	s11,24(sp)
  8001f0:	84aa                	mv	s1,a0
  8001f2:	8c32                	mv	s8,a2
  8001f4:	8a36                	mv	s4,a3
  8001f6:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001f8:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
  8001fc:	05500b13          	li	s6,85
  800200:	00000a97          	auipc	s5,0x0
  800204:	708a8a93          	addi	s5,s5,1800 # 800908 <main+0x3a0>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  800208:	000c4503          	lbu	a0,0(s8)
  80020c:	001c0413          	addi	s0,s8,1
  800210:	01350a63          	beq	a0,s3,800224 <vprintfmt+0x50>
            if (ch == '\0') {
  800214:	cd0d                	beqz	a0,80024e <vprintfmt+0x7a>
            putch(ch, putdat);
  800216:	85ca                	mv	a1,s2
  800218:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  80021a:	00044503          	lbu	a0,0(s0)
  80021e:	0405                	addi	s0,s0,1
  800220:	ff351ae3          	bne	a0,s3,800214 <vprintfmt+0x40>
        width = precision = -1;
  800224:	5cfd                	li	s9,-1
  800226:	8d66                	mv	s10,s9
        char padc = ' ';
  800228:	02000d93          	li	s11,32
        lflag = altflag = 0;
  80022c:	4b81                	li	s7,0
  80022e:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
  800230:	00044683          	lbu	a3,0(s0)
  800234:	00140c13          	addi	s8,s0,1
  800238:	fdd6859b          	addiw	a1,a3,-35
  80023c:	0ff5f593          	zext.b	a1,a1
  800240:	02bb6663          	bltu	s6,a1,80026c <vprintfmt+0x98>
  800244:	058a                	slli	a1,a1,0x2
  800246:	95d6                	add	a1,a1,s5
  800248:	4198                	lw	a4,0(a1)
  80024a:	9756                	add	a4,a4,s5
  80024c:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  80024e:	70e6                	ld	ra,120(sp)
  800250:	7446                	ld	s0,112(sp)
  800252:	74a6                	ld	s1,104(sp)
  800254:	7906                	ld	s2,96(sp)
  800256:	69e6                	ld	s3,88(sp)
  800258:	6a46                	ld	s4,80(sp)
  80025a:	6aa6                	ld	s5,72(sp)
  80025c:	6b06                	ld	s6,64(sp)
  80025e:	7be2                	ld	s7,56(sp)
  800260:	7c42                	ld	s8,48(sp)
  800262:	7ca2                	ld	s9,40(sp)
  800264:	7d02                	ld	s10,32(sp)
  800266:	6de2                	ld	s11,24(sp)
  800268:	6109                	addi	sp,sp,128
  80026a:	8082                	ret
            putch('%', putdat);
  80026c:	85ca                	mv	a1,s2
  80026e:	02500513          	li	a0,37
  800272:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
  800274:	fff44783          	lbu	a5,-1(s0)
  800278:	02500713          	li	a4,37
  80027c:	8c22                	mv	s8,s0
  80027e:	f8e785e3          	beq	a5,a4,800208 <vprintfmt+0x34>
  800282:	ffec4783          	lbu	a5,-2(s8)
  800286:	1c7d                	addi	s8,s8,-1
  800288:	fee79de3          	bne	a5,a4,800282 <vprintfmt+0xae>
  80028c:	bfb5                	j	800208 <vprintfmt+0x34>
                ch = *fmt;
  80028e:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
  800292:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
  800294:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
  800298:	fd06071b          	addiw	a4,a2,-48
  80029c:	24e56a63          	bltu	a0,a4,8004f0 <vprintfmt+0x31c>
                ch = *fmt;
  8002a0:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
  8002a2:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
  8002a4:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
  8002a8:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
  8002ac:	0197073b          	addw	a4,a4,s9
  8002b0:	0017171b          	slliw	a4,a4,0x1
  8002b4:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
  8002b6:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
  8002ba:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  8002bc:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
  8002c0:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
  8002c4:	feb570e3          	bgeu	a0,a1,8002a4 <vprintfmt+0xd0>
            if (width < 0)
  8002c8:	f60d54e3          	bgez	s10,800230 <vprintfmt+0x5c>
                width = precision, precision = -1;
  8002cc:	8d66                	mv	s10,s9
  8002ce:	5cfd                	li	s9,-1
  8002d0:	b785                	j	800230 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
  8002d2:	8db6                	mv	s11,a3
  8002d4:	8462                	mv	s0,s8
  8002d6:	bfa9                	j	800230 <vprintfmt+0x5c>
  8002d8:	8462                	mv	s0,s8
            altflag = 1;
  8002da:	4b85                	li	s7,1
            goto reswitch;
  8002dc:	bf91                	j	800230 <vprintfmt+0x5c>
    if (lflag >= 2) {
  8002de:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002e0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002e4:	00f74463          	blt	a4,a5,8002ec <vprintfmt+0x118>
    else if (lflag) {
  8002e8:	1a078763          	beqz	a5,800496 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
  8002ec:	000a3603          	ld	a2,0(s4)
  8002f0:	46c1                	li	a3,16
  8002f2:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  8002f4:	000d879b          	sext.w	a5,s11
  8002f8:	876a                	mv	a4,s10
  8002fa:	85ca                	mv	a1,s2
  8002fc:	8526                	mv	a0,s1
  8002fe:	e71ff0ef          	jal	80016e <printnum>
            break;
  800302:	b719                	j	800208 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
  800304:	000a2503          	lw	a0,0(s4)
  800308:	85ca                	mv	a1,s2
  80030a:	0a21                	addi	s4,s4,8
  80030c:	9482                	jalr	s1
            break;
  80030e:	bded                	j	800208 <vprintfmt+0x34>
    if (lflag >= 2) {
  800310:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800312:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800316:	00f74463          	blt	a4,a5,80031e <vprintfmt+0x14a>
    else if (lflag) {
  80031a:	16078963          	beqz	a5,80048c <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
  80031e:	000a3603          	ld	a2,0(s4)
  800322:	46a9                	li	a3,10
  800324:	8a2e                	mv	s4,a1
  800326:	b7f9                	j	8002f4 <vprintfmt+0x120>
            putch('0', putdat);
  800328:	85ca                	mv	a1,s2
  80032a:	03000513          	li	a0,48
  80032e:	9482                	jalr	s1
            putch('x', putdat);
  800330:	85ca                	mv	a1,s2
  800332:	07800513          	li	a0,120
  800336:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  800338:	000a3603          	ld	a2,0(s4)
            goto number;
  80033c:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  80033e:	0a21                	addi	s4,s4,8
            goto number;
  800340:	bf55                	j	8002f4 <vprintfmt+0x120>
            putch(ch, putdat);
  800342:	85ca                	mv	a1,s2
  800344:	02500513          	li	a0,37
  800348:	9482                	jalr	s1
            break;
  80034a:	bd7d                	j	800208 <vprintfmt+0x34>
            precision = va_arg(ap, int);
  80034c:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  800350:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
  800352:	0a21                	addi	s4,s4,8
            goto process_precision;
  800354:	bf95                	j	8002c8 <vprintfmt+0xf4>
    if (lflag >= 2) {
  800356:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800358:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  80035c:	00f74463          	blt	a4,a5,800364 <vprintfmt+0x190>
    else if (lflag) {
  800360:	12078163          	beqz	a5,800482 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
  800364:	000a3603          	ld	a2,0(s4)
  800368:	46a1                	li	a3,8
  80036a:	8a2e                	mv	s4,a1
  80036c:	b761                	j	8002f4 <vprintfmt+0x120>
            if (width < 0)
  80036e:	876a                	mv	a4,s10
  800370:	000d5363          	bgez	s10,800376 <vprintfmt+0x1a2>
  800374:	4701                	li	a4,0
  800376:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
  80037a:	8462                	mv	s0,s8
            goto reswitch;
  80037c:	bd55                	j	800230 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
  80037e:	000d841b          	sext.w	s0,s11
  800382:	fd340793          	addi	a5,s0,-45
  800386:	00f037b3          	snez	a5,a5
  80038a:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
  80038e:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
  800392:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
  800394:	008a0793          	addi	a5,s4,8
  800398:	e43e                	sd	a5,8(sp)
  80039a:	100d8c63          	beqz	s11,8004b2 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
  80039e:	12071363          	bnez	a4,8004c4 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003a2:	000dc783          	lbu	a5,0(s11)
  8003a6:	0007851b          	sext.w	a0,a5
  8003aa:	c78d                	beqz	a5,8003d4 <vprintfmt+0x200>
  8003ac:	0d85                	addi	s11,s11,1
  8003ae:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
  8003b0:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003b4:	000cc563          	bltz	s9,8003be <vprintfmt+0x1ea>
  8003b8:	3cfd                	addiw	s9,s9,-1
  8003ba:	008c8d63          	beq	s9,s0,8003d4 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
  8003be:	020b9663          	bnez	s7,8003ea <vprintfmt+0x216>
                    putch(ch, putdat);
  8003c2:	85ca                	mv	a1,s2
  8003c4:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003c6:	000dc783          	lbu	a5,0(s11)
  8003ca:	0d85                	addi	s11,s11,1
  8003cc:	3d7d                	addiw	s10,s10,-1
  8003ce:	0007851b          	sext.w	a0,a5
  8003d2:	f3ed                	bnez	a5,8003b4 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
  8003d4:	01a05963          	blez	s10,8003e6 <vprintfmt+0x212>
                putch(' ', putdat);
  8003d8:	85ca                	mv	a1,s2
  8003da:	02000513          	li	a0,32
            for (; width > 0; width --) {
  8003de:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
  8003e0:	9482                	jalr	s1
            for (; width > 0; width --) {
  8003e2:	fe0d1be3          	bnez	s10,8003d8 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
  8003e6:	6a22                	ld	s4,8(sp)
  8003e8:	b505                	j	800208 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
  8003ea:	3781                	addiw	a5,a5,-32
  8003ec:	fcfa7be3          	bgeu	s4,a5,8003c2 <vprintfmt+0x1ee>
                    putch('?', putdat);
  8003f0:	03f00513          	li	a0,63
  8003f4:	85ca                	mv	a1,s2
  8003f6:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003f8:	000dc783          	lbu	a5,0(s11)
  8003fc:	0d85                	addi	s11,s11,1
  8003fe:	3d7d                	addiw	s10,s10,-1
  800400:	0007851b          	sext.w	a0,a5
  800404:	dbe1                	beqz	a5,8003d4 <vprintfmt+0x200>
  800406:	fa0cd9e3          	bgez	s9,8003b8 <vprintfmt+0x1e4>
  80040a:	b7c5                	j	8003ea <vprintfmt+0x216>
            if (err < 0) {
  80040c:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  800410:	4661                	li	a2,24
            err = va_arg(ap, int);
  800412:	0a21                	addi	s4,s4,8
            if (err < 0) {
  800414:	41f7d71b          	sraiw	a4,a5,0x1f
  800418:	8fb9                	xor	a5,a5,a4
  80041a:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  80041e:	02d64563          	blt	a2,a3,800448 <vprintfmt+0x274>
  800422:	00000797          	auipc	a5,0x0
  800426:	63e78793          	addi	a5,a5,1598 # 800a60 <error_string>
  80042a:	00369713          	slli	a4,a3,0x3
  80042e:	97ba                	add	a5,a5,a4
  800430:	639c                	ld	a5,0(a5)
  800432:	cb99                	beqz	a5,800448 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
  800434:	86be                	mv	a3,a5
  800436:	00000617          	auipc	a2,0x0
  80043a:	35260613          	addi	a2,a2,850 # 800788 <main+0x220>
  80043e:	85ca                	mv	a1,s2
  800440:	8526                	mv	a0,s1
  800442:	0d8000ef          	jal	80051a <printfmt>
  800446:	b3c9                	j	800208 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
  800448:	00000617          	auipc	a2,0x0
  80044c:	33060613          	addi	a2,a2,816 # 800778 <main+0x210>
  800450:	85ca                	mv	a1,s2
  800452:	8526                	mv	a0,s1
  800454:	0c6000ef          	jal	80051a <printfmt>
  800458:	bb45                	j	800208 <vprintfmt+0x34>
    if (lflag >= 2) {
  80045a:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80045c:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
  800460:	00f74363          	blt	a4,a5,800466 <vprintfmt+0x292>
    else if (lflag) {
  800464:	cf81                	beqz	a5,80047c <vprintfmt+0x2a8>
        return va_arg(*ap, long);
  800466:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  80046a:	02044b63          	bltz	s0,8004a0 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
  80046e:	8622                	mv	a2,s0
  800470:	8a5e                	mv	s4,s7
  800472:	46a9                	li	a3,10
  800474:	b541                	j	8002f4 <vprintfmt+0x120>
            lflag ++;
  800476:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
  800478:	8462                	mv	s0,s8
            goto reswitch;
  80047a:	bb5d                	j	800230 <vprintfmt+0x5c>
        return va_arg(*ap, int);
  80047c:	000a2403          	lw	s0,0(s4)
  800480:	b7ed                	j	80046a <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
  800482:	000a6603          	lwu	a2,0(s4)
  800486:	46a1                	li	a3,8
  800488:	8a2e                	mv	s4,a1
  80048a:	b5ad                	j	8002f4 <vprintfmt+0x120>
  80048c:	000a6603          	lwu	a2,0(s4)
  800490:	46a9                	li	a3,10
  800492:	8a2e                	mv	s4,a1
  800494:	b585                	j	8002f4 <vprintfmt+0x120>
  800496:	000a6603          	lwu	a2,0(s4)
  80049a:	46c1                	li	a3,16
  80049c:	8a2e                	mv	s4,a1
  80049e:	bd99                	j	8002f4 <vprintfmt+0x120>
                putch('-', putdat);
  8004a0:	85ca                	mv	a1,s2
  8004a2:	02d00513          	li	a0,45
  8004a6:	9482                	jalr	s1
                num = -(long long)num;
  8004a8:	40800633          	neg	a2,s0
  8004ac:	8a5e                	mv	s4,s7
  8004ae:	46a9                	li	a3,10
  8004b0:	b591                	j	8002f4 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
  8004b2:	e329                	bnez	a4,8004f4 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004b4:	02800793          	li	a5,40
  8004b8:	853e                	mv	a0,a5
  8004ba:	00000d97          	auipc	s11,0x0
  8004be:	2b7d8d93          	addi	s11,s11,695 # 800771 <main+0x209>
  8004c2:	b5f5                	j	8003ae <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004c4:	85e6                	mv	a1,s9
  8004c6:	856e                	mv	a0,s11
  8004c8:	072000ef          	jal	80053a <strnlen>
  8004cc:	40ad0d3b          	subw	s10,s10,a0
  8004d0:	01a05863          	blez	s10,8004e0 <vprintfmt+0x30c>
                    putch(padc, putdat);
  8004d4:	85ca                	mv	a1,s2
  8004d6:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004d8:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
  8004da:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004dc:	fe0d1ce3          	bnez	s10,8004d4 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004e0:	000dc783          	lbu	a5,0(s11)
  8004e4:	0007851b          	sext.w	a0,a5
  8004e8:	ec0792e3          	bnez	a5,8003ac <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
  8004ec:	6a22                	ld	s4,8(sp)
  8004ee:	bb29                	j	800208 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
  8004f0:	8462                	mv	s0,s8
  8004f2:	bbd9                	j	8002c8 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004f4:	85e6                	mv	a1,s9
  8004f6:	00000517          	auipc	a0,0x0
  8004fa:	27a50513          	addi	a0,a0,634 # 800770 <main+0x208>
  8004fe:	03c000ef          	jal	80053a <strnlen>
  800502:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800506:	02800793          	li	a5,40
                p = "(null)";
  80050a:	00000d97          	auipc	s11,0x0
  80050e:	266d8d93          	addi	s11,s11,614 # 800770 <main+0x208>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800512:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  800514:	fda040e3          	bgtz	s10,8004d4 <vprintfmt+0x300>
  800518:	bd51                	j	8003ac <vprintfmt+0x1d8>

000000000080051a <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  80051a:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  80051c:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800520:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  800522:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800524:	ec06                	sd	ra,24(sp)
  800526:	f83a                	sd	a4,48(sp)
  800528:	fc3e                	sd	a5,56(sp)
  80052a:	e0c2                	sd	a6,64(sp)
  80052c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  80052e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  800530:	ca5ff0ef          	jal	8001d4 <vprintfmt>
}
  800534:	60e2                	ld	ra,24(sp)
  800536:	6161                	addi	sp,sp,80
  800538:	8082                	ret

000000000080053a <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  80053a:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  80053c:	e589                	bnez	a1,800546 <strnlen+0xc>
  80053e:	a811                	j	800552 <strnlen+0x18>
        cnt ++;
  800540:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  800542:	00f58863          	beq	a1,a5,800552 <strnlen+0x18>
  800546:	00f50733          	add	a4,a0,a5
  80054a:	00074703          	lbu	a4,0(a4)
  80054e:	fb6d                	bnez	a4,800540 <strnlen+0x6>
  800550:	85be                	mv	a1,a5
    }
    return cnt;
}
  800552:	852e                	mv	a0,a1
  800554:	8082                	ret

0000000000800556 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
  800556:	ca01                	beqz	a2,800566 <memset+0x10>
  800558:	962a                	add	a2,a2,a0
    char *p = s;
  80055a:	87aa                	mv	a5,a0
        *p ++ = c;
  80055c:	0785                	addi	a5,a5,1
  80055e:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
  800562:	fef61de3          	bne	a2,a5,80055c <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
  800566:	8082                	ret

0000000000800568 <main>:
          j = !j;
     }
}

int
main(void) {
  800568:	715d                	addi	sp,sp,-80
     int i,time;
     memset(pids, 0, sizeof(pids));
  80056a:	4651                	li	a2,20
  80056c:	4581                	li	a1,0
  80056e:	00001517          	auipc	a0,0x1
  800572:	a9250513          	addi	a0,a0,-1390 # 801000 <pids>
main(void) {
  800576:	e486                	sd	ra,72(sp)
  800578:	e0a2                	sd	s0,64(sp)
  80057a:	fc26                	sd	s1,56(sp)
  80057c:	f84a                	sd	s2,48(sp)
  80057e:	f44e                	sd	s3,40(sp)
  800580:	f052                	sd	s4,32(sp)
  800582:	ec56                	sd	s5,24(sp)
     memset(pids, 0, sizeof(pids));
  800584:	fd3ff0ef          	jal	800556 <memset>
     lab6_setpriority(TOTAL + 1);
  800588:	4519                	li	a0,6
  80058a:	00001a97          	auipc	s5,0x1
  80058e:	aa6a8a93          	addi	s5,s5,-1370 # 801030 <acc>
  800592:	00001497          	auipc	s1,0x1
  800596:	a6e48493          	addi	s1,s1,-1426 # 801000 <pids>
  80059a:	bc3ff0ef          	jal	80015c <lab6_setpriority>

     for (i = 0; i < TOTAL; i ++) {
  80059e:	89d6                	mv	s3,s5
     lab6_setpriority(TOTAL + 1);
  8005a0:	8926                	mv	s2,s1
     for (i = 0; i < TOTAL; i ++) {
  8005a2:	4401                	li	s0,0
  8005a4:	4a15                	li	s4,5
          acc[i]=0;
  8005a6:	0009a023          	sw	zero,0(s3)
          if ((pids[i] = fork()) == 0) {
  8005aa:	ba9ff0ef          	jal	800152 <fork>
  8005ae:	00a92023          	sw	a0,0(s2)
  8005b2:	c561                	beqz	a0,80067a <main+0x112>
                        }
                    }
               }
               
          }
          if (pids[i] < 0) {
  8005b4:	12054763          	bltz	a0,8006e2 <main+0x17a>
     for (i = 0; i < TOTAL; i ++) {
  8005b8:	2405                	addiw	s0,s0,1
  8005ba:	0991                	addi	s3,s3,4
  8005bc:	0911                	addi	s2,s2,4
  8005be:	ff4414e3          	bne	s0,s4,8005a6 <main+0x3e>
               goto failed;
          }
     }

     cprintf("main: fork ok,now need to wait pids.\n");
  8005c2:	00000517          	auipc	a0,0x0
  8005c6:	2ae50513          	addi	a0,a0,686 # 800870 <main+0x308>
  8005ca:	00001917          	auipc	s2,0x1
  8005ce:	a4e90913          	addi	s2,s2,-1458 # 801018 <status>
  8005d2:	acfff0ef          	jal	8000a0 <cprintf>
  8005d6:	844a                	mv	s0,s2
  8005d8:	00001997          	auipc	s3,0x1
  8005dc:	a5498993          	addi	s3,s3,-1452 # 80102c <status+0x14>

     for (i = 0; i < TOTAL; i ++) {
         status[i]=0;
         waitpid(pids[i],&status[i]);
  8005e0:	4088                	lw	a0,0(s1)
  8005e2:	85a2                	mv	a1,s0
         status[i]=0;
  8005e4:	00042023          	sw	zero,0(s0)
         waitpid(pids[i],&status[i]);
  8005e8:	b6dff0ef          	jal	800154 <waitpid>
         cprintf("main: pid %d, acc %d, time %d\n",pids[i],status[i],gettime_msec()); 
  8005ec:	0004aa03          	lw	s4,0(s1)
  8005f0:	00042a83          	lw	s5,0(s0)
  8005f4:	b67ff0ef          	jal	80015a <gettime_msec>
  8005f8:	86aa                	mv	a3,a0
  8005fa:	8656                	mv	a2,s5
  8005fc:	85d2                	mv	a1,s4
  8005fe:	00000517          	auipc	a0,0x0
  800602:	29a50513          	addi	a0,a0,666 # 800898 <main+0x330>
     for (i = 0; i < TOTAL; i ++) {
  800606:	0411                	addi	s0,s0,4
         cprintf("main: pid %d, acc %d, time %d\n",pids[i],status[i],gettime_msec()); 
  800608:	a99ff0ef          	jal	8000a0 <cprintf>
     for (i = 0; i < TOTAL; i ++) {
  80060c:	0491                	addi	s1,s1,4
  80060e:	fd3419e3          	bne	s0,s3,8005e0 <main+0x78>
     }
     cprintf("main: wait pids over\n");
  800612:	00000517          	auipc	a0,0x0
  800616:	2a650513          	addi	a0,a0,678 # 8008b8 <main+0x350>
  80061a:	a87ff0ef          	jal	8000a0 <cprintf>
     cprintf("sched result:");
  80061e:	00000517          	auipc	a0,0x0
  800622:	2b250513          	addi	a0,a0,690 # 8008d0 <main+0x368>
  800626:	a7bff0ef          	jal	8000a0 <cprintf>
     for (i = 0; i < TOTAL; i ++)
     {
         cprintf(" %d", (status[i] * 2 / status[0] + 1) / 2);
  80062a:	00092783          	lw	a5,0(s2)
  80062e:	00001717          	auipc	a4,0x1
  800632:	9ea72703          	lw	a4,-1558(a4) # 801018 <status>
  800636:	00000517          	auipc	a0,0x0
  80063a:	2aa50513          	addi	a0,a0,682 # 8008e0 <main+0x378>
  80063e:	0017979b          	slliw	a5,a5,0x1
  800642:	02e7c7bb          	divw	a5,a5,a4
     for (i = 0; i < TOTAL; i ++)
  800646:	0911                	addi	s2,s2,4
         cprintf(" %d", (status[i] * 2 / status[0] + 1) / 2);
  800648:	2785                	addiw	a5,a5,1
  80064a:	01f7d59b          	srliw	a1,a5,0x1f
  80064e:	9dbd                	addw	a1,a1,a5
  800650:	8585                	srai	a1,a1,0x1
  800652:	a4fff0ef          	jal	8000a0 <cprintf>
     for (i = 0; i < TOTAL; i ++)
  800656:	fd391ae3          	bne	s2,s3,80062a <main+0xc2>
     }
     cprintf("\n");
  80065a:	00000517          	auipc	a0,0x0
  80065e:	0de50513          	addi	a0,a0,222 # 800738 <main+0x1d0>
  800662:	a3fff0ef          	jal	8000a0 <cprintf>
          if (pids[i] > 0) {
               kill(pids[i]);
          }
     }
     panic("FAIL: T.T\n");
}
  800666:	60a6                	ld	ra,72(sp)
  800668:	6406                	ld	s0,64(sp)
  80066a:	74e2                	ld	s1,56(sp)
  80066c:	7942                	ld	s2,48(sp)
  80066e:	79a2                	ld	s3,40(sp)
  800670:	7a02                	ld	s4,32(sp)
  800672:	6ae2                	ld	s5,24(sp)
  800674:	4501                	li	a0,0
  800676:	6161                	addi	sp,sp,80
  800678:	8082                	ret
               lab6_setpriority(i + 1);
  80067a:	0014051b          	addiw	a0,s0,1
               acc[i] = 0;
  80067e:	040a                	slli	s0,s0,0x2
  800680:	9aa2                	add	s5,s5,s0
                    if(acc[i]%4000==0) {
  800682:	6405                	lui	s0,0x1
               lab6_setpriority(i + 1);
  800684:	ad9ff0ef          	jal	80015c <lab6_setpriority>
                    if(acc[i]%4000==0) {
  800688:	fa04041b          	addiw	s0,s0,-96 # fa0 <_start-0x7ff080>
               acc[i] = 0;
  80068c:	000aa023          	sw	zero,0(s5)
                        if((time=gettime_msec())>MAX_TIME) {
  800690:	7d000913          	li	s2,2000
  800694:	000aa683          	lw	a3,0(s5)
  800698:	2685                	addiw	a3,a3,1
     for (i = 0; i != 200; ++ i)
  80069a:	0c800713          	li	a4,200
          j = !j;
  80069e:	47b2                	lw	a5,12(sp)
     for (i = 0; i != 200; ++ i)
  8006a0:	377d                	addiw	a4,a4,-1
          j = !j;
  8006a2:	0017b793          	seqz	a5,a5
  8006a6:	c63e                	sw	a5,12(sp)
     for (i = 0; i != 200; ++ i)
  8006a8:	fb7d                	bnez	a4,80069e <main+0x136>
                    if(acc[i]%4000==0) {
  8006aa:	0286f7bb          	remuw	a5,a3,s0
  8006ae:	c399                	beqz	a5,8006b4 <main+0x14c>
  8006b0:	2685                	addiw	a3,a3,1
  8006b2:	b7e5                	j	80069a <main+0x132>
  8006b4:	00daa023          	sw	a3,0(s5)
                        if((time=gettime_msec())>MAX_TIME) {
  8006b8:	aa3ff0ef          	jal	80015a <gettime_msec>
  8006bc:	84aa                	mv	s1,a0
  8006be:	fca95be3          	bge	s2,a0,800694 <main+0x12c>
                            cprintf("child pid %d, acc %d, time %d\n",getpid(),acc[i],time);
  8006c2:	a97ff0ef          	jal	800158 <getpid>
  8006c6:	000aa603          	lw	a2,0(s5)
  8006ca:	85aa                	mv	a1,a0
  8006cc:	86a6                	mv	a3,s1
  8006ce:	00000517          	auipc	a0,0x0
  8006d2:	18250513          	addi	a0,a0,386 # 800850 <main+0x2e8>
  8006d6:	9cbff0ef          	jal	8000a0 <cprintf>
                            exit(acc[i]);
  8006da:	000aa503          	lw	a0,0(s5)
  8006de:	a5fff0ef          	jal	80013c <exit>
  8006e2:	00001417          	auipc	s0,0x1
  8006e6:	93240413          	addi	s0,s0,-1742 # 801014 <pids+0x14>
          if (pids[i] > 0) {
  8006ea:	4088                	lw	a0,0(s1)
  8006ec:	00a05463          	blez	a0,8006f4 <main+0x18c>
               kill(pids[i]);
  8006f0:	a67ff0ef          	jal	800156 <kill>
     for (i = 0; i < TOTAL; i ++) {
  8006f4:	0491                	addi	s1,s1,4
  8006f6:	fe849ae3          	bne	s1,s0,8006ea <main+0x182>
     panic("FAIL: T.T\n");
  8006fa:	00000617          	auipc	a2,0x0
  8006fe:	1ee60613          	addi	a2,a2,494 # 8008e8 <main+0x380>
  800702:	04b00593          	li	a1,75
  800706:	00000517          	auipc	a0,0x0
  80070a:	1f250513          	addi	a0,a0,498 # 8008f8 <main+0x390>
  80070e:	919ff0ef          	jal	800026 <__panic>
