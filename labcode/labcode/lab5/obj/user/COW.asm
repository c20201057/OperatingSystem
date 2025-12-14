
obj/__user_COW.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <_start>:
.text
.globl _start
_start:
    # call user-program function
    call umain
  800020:	122000ef          	jal	800142 <umain>
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
  800038:	74c50513          	addi	a0,a0,1868 # 800780 <main+0x24a>
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
  80005a:	74a50513          	addi	a0,a0,1866 # 8007a0 <main+0x26a>
  80005e:	042000ef          	jal	8000a0 <cprintf>
    va_end(ap);
    exit(-E_PANIC);
  800062:	5559                	li	a0,-10
  800064:	0c4000ef          	jal	800128 <exit>

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
  80006e:	0b4000ef          	jal	800122 <sys_putc>
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
  800094:	120000ef          	jal	8001b4 <vprintfmt>
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
  8000c8:	0ec000ef          	jal	8001b4 <vprintfmt>
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
  8000f6:	6522                	ld	a0,8(sp)
  8000f8:	75a2                	ld	a1,40(sp)
  8000fa:	7642                	ld	a2,48(sp)
  8000fc:	76e2                	ld	a3,56(sp)
  8000fe:	6706                	ld	a4,64(sp)
  800100:	67a6                	ld	a5,72(sp)
  800102:	00000073          	ecall
  800106:	00a13e23          	sd	a0,28(sp)
        "sd a0, %0"
        : "=m" (ret)
        : "m"(num), "m"(a[0]), "m"(a[1]), "m"(a[2]), "m"(a[3]), "m"(a[4])
        :"memory");
    return ret;
}
  80010a:	4572                	lw	a0,28(sp)
  80010c:	6149                	addi	sp,sp,144
  80010e:	8082                	ret

0000000000800110 <sys_exit>:

int
sys_exit(int64_t error_code) {
  800110:	85aa                	mv	a1,a0
    return syscall(SYS_exit, error_code);
  800112:	4505                	li	a0,1
  800114:	b7c1                	j	8000d4 <syscall>

0000000000800116 <sys_fork>:
}

int
sys_fork(void) {
    return syscall(SYS_fork);
  800116:	4509                	li	a0,2
  800118:	bf75                	j	8000d4 <syscall>

000000000080011a <sys_wait>:
}

int
sys_wait(int64_t pid, int *store) {
  80011a:	862e                	mv	a2,a1
    return syscall(SYS_wait, pid, store);
  80011c:	85aa                	mv	a1,a0
  80011e:	450d                	li	a0,3
  800120:	bf55                	j	8000d4 <syscall>

0000000000800122 <sys_putc>:
sys_getpid(void) {
    return syscall(SYS_getpid);
}

int
sys_putc(int64_t c) {
  800122:	85aa                	mv	a1,a0
    return syscall(SYS_putc, c);
  800124:	4579                	li	a0,30
  800126:	b77d                	j	8000d4 <syscall>

0000000000800128 <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  800128:	1141                	addi	sp,sp,-16
  80012a:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  80012c:	fe5ff0ef          	jal	800110 <sys_exit>
    cprintf("BUG: exit failed.\n");
  800130:	00000517          	auipc	a0,0x0
  800134:	67850513          	addi	a0,a0,1656 # 8007a8 <main+0x272>
  800138:	f69ff0ef          	jal	8000a0 <cprintf>
    while (1);
  80013c:	a001                	j	80013c <exit+0x14>

000000000080013e <fork>:
}

int
fork(void) {
    return sys_fork();
  80013e:	bfe1                	j	800116 <sys_fork>

0000000000800140 <waitpid>:
    return sys_wait(0, NULL);
}

int
waitpid(int pid, int *store) {
    return sys_wait(pid, store);
  800140:	bfe9                	j	80011a <sys_wait>

0000000000800142 <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  800142:	1141                	addi	sp,sp,-16
  800144:	e406                	sd	ra,8(sp)
    int ret = main();
  800146:	3f0000ef          	jal	800536 <main>
    exit(ret);
  80014a:	fdfff0ef          	jal	800128 <exit>

000000000080014e <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
  80014e:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  800150:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800154:	f022                	sd	s0,32(sp)
  800156:	ec26                	sd	s1,24(sp)
  800158:	e84a                	sd	s2,16(sp)
  80015a:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  80015c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800160:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
  800162:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  800166:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
  80016a:	84aa                	mv	s1,a0
  80016c:	892e                	mv	s2,a1
    if (num >= base) {
  80016e:	03067d63          	bgeu	a2,a6,8001a8 <printnum+0x5a>
  800172:	e44e                	sd	s3,8(sp)
  800174:	89be                	mv	s3,a5
        while (-- width > 0)
  800176:	4785                	li	a5,1
  800178:	00e7d763          	bge	a5,a4,800186 <printnum+0x38>
            putch(padc, putdat);
  80017c:	85ca                	mv	a1,s2
  80017e:	854e                	mv	a0,s3
        while (-- width > 0)
  800180:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  800182:	9482                	jalr	s1
        while (-- width > 0)
  800184:	fc65                	bnez	s0,80017c <printnum+0x2e>
  800186:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  800188:	00000797          	auipc	a5,0x0
  80018c:	63878793          	addi	a5,a5,1592 # 8007c0 <main+0x28a>
  800190:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  800192:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  800194:	0007c503          	lbu	a0,0(a5)
}
  800198:	70a2                	ld	ra,40(sp)
  80019a:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  80019c:	85ca                	mv	a1,s2
  80019e:	87a6                	mv	a5,s1
}
  8001a0:	6942                	ld	s2,16(sp)
  8001a2:	64e2                	ld	s1,24(sp)
  8001a4:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  8001a6:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  8001a8:	03065633          	divu	a2,a2,a6
  8001ac:	8722                	mv	a4,s0
  8001ae:	fa1ff0ef          	jal	80014e <printnum>
  8001b2:	bfd9                	j	800188 <printnum+0x3a>

00000000008001b4 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  8001b4:	7119                	addi	sp,sp,-128
  8001b6:	f4a6                	sd	s1,104(sp)
  8001b8:	f0ca                	sd	s2,96(sp)
  8001ba:	ecce                	sd	s3,88(sp)
  8001bc:	e8d2                	sd	s4,80(sp)
  8001be:	e4d6                	sd	s5,72(sp)
  8001c0:	e0da                	sd	s6,64(sp)
  8001c2:	f862                	sd	s8,48(sp)
  8001c4:	fc86                	sd	ra,120(sp)
  8001c6:	f8a2                	sd	s0,112(sp)
  8001c8:	fc5e                	sd	s7,56(sp)
  8001ca:	f466                	sd	s9,40(sp)
  8001cc:	f06a                	sd	s10,32(sp)
  8001ce:	ec6e                	sd	s11,24(sp)
  8001d0:	84aa                	mv	s1,a0
  8001d2:	8c32                	mv	s8,a2
  8001d4:	8a36                	mv	s4,a3
  8001d6:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001d8:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
  8001dc:	05500b13          	li	s6,85
  8001e0:	00001a97          	auipc	s5,0x1
  8001e4:	a10a8a93          	addi	s5,s5,-1520 # 800bf0 <main+0x6ba>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001e8:	000c4503          	lbu	a0,0(s8)
  8001ec:	001c0413          	addi	s0,s8,1
  8001f0:	01350a63          	beq	a0,s3,800204 <vprintfmt+0x50>
            if (ch == '\0') {
  8001f4:	cd0d                	beqz	a0,80022e <vprintfmt+0x7a>
            putch(ch, putdat);
  8001f6:	85ca                	mv	a1,s2
  8001f8:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001fa:	00044503          	lbu	a0,0(s0)
  8001fe:	0405                	addi	s0,s0,1
  800200:	ff351ae3          	bne	a0,s3,8001f4 <vprintfmt+0x40>
        width = precision = -1;
  800204:	5cfd                	li	s9,-1
  800206:	8d66                	mv	s10,s9
        char padc = ' ';
  800208:	02000d93          	li	s11,32
        lflag = altflag = 0;
  80020c:	4b81                	li	s7,0
  80020e:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
  800210:	00044683          	lbu	a3,0(s0)
  800214:	00140c13          	addi	s8,s0,1
  800218:	fdd6859b          	addiw	a1,a3,-35
  80021c:	0ff5f593          	zext.b	a1,a1
  800220:	02bb6663          	bltu	s6,a1,80024c <vprintfmt+0x98>
  800224:	058a                	slli	a1,a1,0x2
  800226:	95d6                	add	a1,a1,s5
  800228:	4198                	lw	a4,0(a1)
  80022a:	9756                	add	a4,a4,s5
  80022c:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  80022e:	70e6                	ld	ra,120(sp)
  800230:	7446                	ld	s0,112(sp)
  800232:	74a6                	ld	s1,104(sp)
  800234:	7906                	ld	s2,96(sp)
  800236:	69e6                	ld	s3,88(sp)
  800238:	6a46                	ld	s4,80(sp)
  80023a:	6aa6                	ld	s5,72(sp)
  80023c:	6b06                	ld	s6,64(sp)
  80023e:	7be2                	ld	s7,56(sp)
  800240:	7c42                	ld	s8,48(sp)
  800242:	7ca2                	ld	s9,40(sp)
  800244:	7d02                	ld	s10,32(sp)
  800246:	6de2                	ld	s11,24(sp)
  800248:	6109                	addi	sp,sp,128
  80024a:	8082                	ret
            putch('%', putdat);
  80024c:	85ca                	mv	a1,s2
  80024e:	02500513          	li	a0,37
  800252:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
  800254:	fff44783          	lbu	a5,-1(s0)
  800258:	02500713          	li	a4,37
  80025c:	8c22                	mv	s8,s0
  80025e:	f8e785e3          	beq	a5,a4,8001e8 <vprintfmt+0x34>
  800262:	ffec4783          	lbu	a5,-2(s8)
  800266:	1c7d                	addi	s8,s8,-1
  800268:	fee79de3          	bne	a5,a4,800262 <vprintfmt+0xae>
  80026c:	bfb5                	j	8001e8 <vprintfmt+0x34>
                ch = *fmt;
  80026e:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
  800272:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
  800274:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
  800278:	fd06071b          	addiw	a4,a2,-48
  80027c:	24e56a63          	bltu	a0,a4,8004d0 <vprintfmt+0x31c>
                ch = *fmt;
  800280:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
  800282:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
  800284:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
  800288:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
  80028c:	0197073b          	addw	a4,a4,s9
  800290:	0017171b          	slliw	a4,a4,0x1
  800294:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
  800296:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
  80029a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  80029c:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
  8002a0:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
  8002a4:	feb570e3          	bgeu	a0,a1,800284 <vprintfmt+0xd0>
            if (width < 0)
  8002a8:	f60d54e3          	bgez	s10,800210 <vprintfmt+0x5c>
                width = precision, precision = -1;
  8002ac:	8d66                	mv	s10,s9
  8002ae:	5cfd                	li	s9,-1
  8002b0:	b785                	j	800210 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
  8002b2:	8db6                	mv	s11,a3
  8002b4:	8462                	mv	s0,s8
  8002b6:	bfa9                	j	800210 <vprintfmt+0x5c>
  8002b8:	8462                	mv	s0,s8
            altflag = 1;
  8002ba:	4b85                	li	s7,1
            goto reswitch;
  8002bc:	bf91                	j	800210 <vprintfmt+0x5c>
    if (lflag >= 2) {
  8002be:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002c0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002c4:	00f74463          	blt	a4,a5,8002cc <vprintfmt+0x118>
    else if (lflag) {
  8002c8:	1a078763          	beqz	a5,800476 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
  8002cc:	000a3603          	ld	a2,0(s4)
  8002d0:	46c1                	li	a3,16
  8002d2:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  8002d4:	000d879b          	sext.w	a5,s11
  8002d8:	876a                	mv	a4,s10
  8002da:	85ca                	mv	a1,s2
  8002dc:	8526                	mv	a0,s1
  8002de:	e71ff0ef          	jal	80014e <printnum>
            break;
  8002e2:	b719                	j	8001e8 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
  8002e4:	000a2503          	lw	a0,0(s4)
  8002e8:	85ca                	mv	a1,s2
  8002ea:	0a21                	addi	s4,s4,8
  8002ec:	9482                	jalr	s1
            break;
  8002ee:	bded                	j	8001e8 <vprintfmt+0x34>
    if (lflag >= 2) {
  8002f0:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002f2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002f6:	00f74463          	blt	a4,a5,8002fe <vprintfmt+0x14a>
    else if (lflag) {
  8002fa:	16078963          	beqz	a5,80046c <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
  8002fe:	000a3603          	ld	a2,0(s4)
  800302:	46a9                	li	a3,10
  800304:	8a2e                	mv	s4,a1
  800306:	b7f9                	j	8002d4 <vprintfmt+0x120>
            putch('0', putdat);
  800308:	85ca                	mv	a1,s2
  80030a:	03000513          	li	a0,48
  80030e:	9482                	jalr	s1
            putch('x', putdat);
  800310:	85ca                	mv	a1,s2
  800312:	07800513          	li	a0,120
  800316:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  800318:	000a3603          	ld	a2,0(s4)
            goto number;
  80031c:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  80031e:	0a21                	addi	s4,s4,8
            goto number;
  800320:	bf55                	j	8002d4 <vprintfmt+0x120>
            putch(ch, putdat);
  800322:	85ca                	mv	a1,s2
  800324:	02500513          	li	a0,37
  800328:	9482                	jalr	s1
            break;
  80032a:	bd7d                	j	8001e8 <vprintfmt+0x34>
            precision = va_arg(ap, int);
  80032c:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  800330:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
  800332:	0a21                	addi	s4,s4,8
            goto process_precision;
  800334:	bf95                	j	8002a8 <vprintfmt+0xf4>
    if (lflag >= 2) {
  800336:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800338:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  80033c:	00f74463          	blt	a4,a5,800344 <vprintfmt+0x190>
    else if (lflag) {
  800340:	12078163          	beqz	a5,800462 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
  800344:	000a3603          	ld	a2,0(s4)
  800348:	46a1                	li	a3,8
  80034a:	8a2e                	mv	s4,a1
  80034c:	b761                	j	8002d4 <vprintfmt+0x120>
            if (width < 0)
  80034e:	876a                	mv	a4,s10
  800350:	000d5363          	bgez	s10,800356 <vprintfmt+0x1a2>
  800354:	4701                	li	a4,0
  800356:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
  80035a:	8462                	mv	s0,s8
            goto reswitch;
  80035c:	bd55                	j	800210 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
  80035e:	000d841b          	sext.w	s0,s11
  800362:	fd340793          	addi	a5,s0,-45
  800366:	00f037b3          	snez	a5,a5
  80036a:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
  80036e:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
  800372:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
  800374:	008a0793          	addi	a5,s4,8
  800378:	e43e                	sd	a5,8(sp)
  80037a:	100d8c63          	beqz	s11,800492 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
  80037e:	12071363          	bnez	a4,8004a4 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800382:	000dc783          	lbu	a5,0(s11)
  800386:	0007851b          	sext.w	a0,a5
  80038a:	c78d                	beqz	a5,8003b4 <vprintfmt+0x200>
  80038c:	0d85                	addi	s11,s11,1
  80038e:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
  800390:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800394:	000cc563          	bltz	s9,80039e <vprintfmt+0x1ea>
  800398:	3cfd                	addiw	s9,s9,-1
  80039a:	008c8d63          	beq	s9,s0,8003b4 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
  80039e:	020b9663          	bnez	s7,8003ca <vprintfmt+0x216>
                    putch(ch, putdat);
  8003a2:	85ca                	mv	a1,s2
  8003a4:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003a6:	000dc783          	lbu	a5,0(s11)
  8003aa:	0d85                	addi	s11,s11,1
  8003ac:	3d7d                	addiw	s10,s10,-1
  8003ae:	0007851b          	sext.w	a0,a5
  8003b2:	f3ed                	bnez	a5,800394 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
  8003b4:	01a05963          	blez	s10,8003c6 <vprintfmt+0x212>
                putch(' ', putdat);
  8003b8:	85ca                	mv	a1,s2
  8003ba:	02000513          	li	a0,32
            for (; width > 0; width --) {
  8003be:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
  8003c0:	9482                	jalr	s1
            for (; width > 0; width --) {
  8003c2:	fe0d1be3          	bnez	s10,8003b8 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
  8003c6:	6a22                	ld	s4,8(sp)
  8003c8:	b505                	j	8001e8 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
  8003ca:	3781                	addiw	a5,a5,-32
  8003cc:	fcfa7be3          	bgeu	s4,a5,8003a2 <vprintfmt+0x1ee>
                    putch('?', putdat);
  8003d0:	03f00513          	li	a0,63
  8003d4:	85ca                	mv	a1,s2
  8003d6:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003d8:	000dc783          	lbu	a5,0(s11)
  8003dc:	0d85                	addi	s11,s11,1
  8003de:	3d7d                	addiw	s10,s10,-1
  8003e0:	0007851b          	sext.w	a0,a5
  8003e4:	dbe1                	beqz	a5,8003b4 <vprintfmt+0x200>
  8003e6:	fa0cd9e3          	bgez	s9,800398 <vprintfmt+0x1e4>
  8003ea:	b7c5                	j	8003ca <vprintfmt+0x216>
            if (err < 0) {
  8003ec:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003f0:	4661                	li	a2,24
            err = va_arg(ap, int);
  8003f2:	0a21                	addi	s4,s4,8
            if (err < 0) {
  8003f4:	41f7d71b          	sraiw	a4,a5,0x1f
  8003f8:	8fb9                	xor	a5,a5,a4
  8003fa:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003fe:	02d64563          	blt	a2,a3,800428 <vprintfmt+0x274>
  800402:	00001797          	auipc	a5,0x1
  800406:	94678793          	addi	a5,a5,-1722 # 800d48 <error_string>
  80040a:	00369713          	slli	a4,a3,0x3
  80040e:	97ba                	add	a5,a5,a4
  800410:	639c                	ld	a5,0(a5)
  800412:	cb99                	beqz	a5,800428 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
  800414:	86be                	mv	a3,a5
  800416:	00000617          	auipc	a2,0x0
  80041a:	3da60613          	addi	a2,a2,986 # 8007f0 <main+0x2ba>
  80041e:	85ca                	mv	a1,s2
  800420:	8526                	mv	a0,s1
  800422:	0d8000ef          	jal	8004fa <printfmt>
  800426:	b3c9                	j	8001e8 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
  800428:	00000617          	auipc	a2,0x0
  80042c:	3b860613          	addi	a2,a2,952 # 8007e0 <main+0x2aa>
  800430:	85ca                	mv	a1,s2
  800432:	8526                	mv	a0,s1
  800434:	0c6000ef          	jal	8004fa <printfmt>
  800438:	bb45                	j	8001e8 <vprintfmt+0x34>
    if (lflag >= 2) {
  80043a:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80043c:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
  800440:	00f74363          	blt	a4,a5,800446 <vprintfmt+0x292>
    else if (lflag) {
  800444:	cf81                	beqz	a5,80045c <vprintfmt+0x2a8>
        return va_arg(*ap, long);
  800446:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  80044a:	02044b63          	bltz	s0,800480 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
  80044e:	8622                	mv	a2,s0
  800450:	8a5e                	mv	s4,s7
  800452:	46a9                	li	a3,10
  800454:	b541                	j	8002d4 <vprintfmt+0x120>
            lflag ++;
  800456:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
  800458:	8462                	mv	s0,s8
            goto reswitch;
  80045a:	bb5d                	j	800210 <vprintfmt+0x5c>
        return va_arg(*ap, int);
  80045c:	000a2403          	lw	s0,0(s4)
  800460:	b7ed                	j	80044a <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
  800462:	000a6603          	lwu	a2,0(s4)
  800466:	46a1                	li	a3,8
  800468:	8a2e                	mv	s4,a1
  80046a:	b5ad                	j	8002d4 <vprintfmt+0x120>
  80046c:	000a6603          	lwu	a2,0(s4)
  800470:	46a9                	li	a3,10
  800472:	8a2e                	mv	s4,a1
  800474:	b585                	j	8002d4 <vprintfmt+0x120>
  800476:	000a6603          	lwu	a2,0(s4)
  80047a:	46c1                	li	a3,16
  80047c:	8a2e                	mv	s4,a1
  80047e:	bd99                	j	8002d4 <vprintfmt+0x120>
                putch('-', putdat);
  800480:	85ca                	mv	a1,s2
  800482:	02d00513          	li	a0,45
  800486:	9482                	jalr	s1
                num = -(long long)num;
  800488:	40800633          	neg	a2,s0
  80048c:	8a5e                	mv	s4,s7
  80048e:	46a9                	li	a3,10
  800490:	b591                	j	8002d4 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
  800492:	e329                	bnez	a4,8004d4 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800494:	02800793          	li	a5,40
  800498:	853e                	mv	a0,a5
  80049a:	00000d97          	auipc	s11,0x0
  80049e:	33fd8d93          	addi	s11,s11,831 # 8007d9 <main+0x2a3>
  8004a2:	b5f5                	j	80038e <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004a4:	85e6                	mv	a1,s9
  8004a6:	856e                	mv	a0,s11
  8004a8:	072000ef          	jal	80051a <strnlen>
  8004ac:	40ad0d3b          	subw	s10,s10,a0
  8004b0:	01a05863          	blez	s10,8004c0 <vprintfmt+0x30c>
                    putch(padc, putdat);
  8004b4:	85ca                	mv	a1,s2
  8004b6:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004b8:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
  8004ba:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004bc:	fe0d1ce3          	bnez	s10,8004b4 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004c0:	000dc783          	lbu	a5,0(s11)
  8004c4:	0007851b          	sext.w	a0,a5
  8004c8:	ec0792e3          	bnez	a5,80038c <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
  8004cc:	6a22                	ld	s4,8(sp)
  8004ce:	bb29                	j	8001e8 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
  8004d0:	8462                	mv	s0,s8
  8004d2:	bbd9                	j	8002a8 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004d4:	85e6                	mv	a1,s9
  8004d6:	00000517          	auipc	a0,0x0
  8004da:	30250513          	addi	a0,a0,770 # 8007d8 <main+0x2a2>
  8004de:	03c000ef          	jal	80051a <strnlen>
  8004e2:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004e6:	02800793          	li	a5,40
                p = "(null)";
  8004ea:	00000d97          	auipc	s11,0x0
  8004ee:	2eed8d93          	addi	s11,s11,750 # 8007d8 <main+0x2a2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004f2:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004f4:	fda040e3          	bgtz	s10,8004b4 <vprintfmt+0x300>
  8004f8:	bd51                	j	80038c <vprintfmt+0x1d8>

00000000008004fa <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004fa:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  8004fc:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800500:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  800502:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800504:	ec06                	sd	ra,24(sp)
  800506:	f83a                	sd	a4,48(sp)
  800508:	fc3e                	sd	a5,56(sp)
  80050a:	e0c2                	sd	a6,64(sp)
  80050c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  80050e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  800510:	ca5ff0ef          	jal	8001b4 <vprintfmt>
}
  800514:	60e2                	ld	ra,24(sp)
  800516:	6161                	addi	sp,sp,80
  800518:	8082                	ret

000000000080051a <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  80051a:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  80051c:	e589                	bnez	a1,800526 <strnlen+0xc>
  80051e:	a811                	j	800532 <strnlen+0x18>
        cnt ++;
  800520:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  800522:	00f58863          	beq	a1,a5,800532 <strnlen+0x18>
  800526:	00f50733          	add	a4,a0,a5
  80052a:	00074703          	lbu	a4,0(a4)
  80052e:	fb6d                	bnez	a4,800520 <strnlen+0x6>
  800530:	85be                	mv	a1,a5
    }
    return cnt;
}
  800532:	852e                	mv	a0,a1
  800534:	8082                	ret

0000000000800536 <main>:
/* 定义一个足够大的全局数组，确保跨越多个页 */
#define ARRAY_SIZE 4096 
volatile int global_data[ARRAY_SIZE];
volatile int simple_var = 100;

int main(void) {
  800536:	1101                	addi	sp,sp,-32
    cprintf("---------- COW TEST START ----------\n");
  800538:	00000517          	auipc	a0,0x0
  80053c:	38050513          	addi	a0,a0,896 # 8008b8 <main+0x382>
int main(void) {
  800540:	e822                	sd	s0,16(sp)
  800542:	ec06                	sd	ra,24(sp)
    cprintf("---------- COW TEST START ----------\n");
  800544:	b5dff0ef          	jal	8000a0 <cprintf>

    // 1. 初始化数据
    int i;
    for (i = 0; i < ARRAY_SIZE; i++) {
  800548:	4781                	li	a5,0
  80054a:	00001417          	auipc	s0,0x1
  80054e:	abe40413          	addi	s0,s0,-1346 # 801008 <global_data>
  800552:	6685                	lui	a3,0x1
        global_data[i] = i;
  800554:	00279713          	slli	a4,a5,0x2
  800558:	9722                	add	a4,a4,s0
  80055a:	c31c                	sw	a5,0(a4)
    for (i = 0; i < ARRAY_SIZE; i++) {
  80055c:	2785                	addiw	a5,a5,1
  80055e:	fed79be3          	bne	a5,a3,800554 <main+0x1e>
    }
    cprintf("Parent: Data initialized.\n");
  800562:	00000517          	auipc	a0,0x0
  800566:	37e50513          	addi	a0,a0,894 # 8008e0 <main+0x3aa>
  80056a:	b37ff0ef          	jal	8000a0 <cprintf>

    // 2. 打印 fork 前的剩余物理页（可选，如果你的 ucore 实现了 sys_get_free_pages）
    // cprintf("Free pages before fork: %d\n", sys_get_free_pages());

    int pid = fork();
  80056e:	bd1ff0ef          	jal	80013e <fork>

    if (pid == 0) {
  800572:	ed71                	bnez	a0,80064e <main+0x118>
        /* =================================================
         * 子进程执行区域
         * ================================================= */
        cprintf("Child: I am running.\n");
  800574:	00000517          	auipc	a0,0x0
  800578:	38c50513          	addi	a0,a0,908 # 800900 <main+0x3ca>
  80057c:	b25ff0ef          	jal	8000a0 <cprintf>

        // [测试点 1]: 读取数据
        // 此时不应该触发 Page Fault (因为是只读)，应该直接读取共享页
        cprintf("Child: Check simple_var = %d (Expect 100)\n", simple_var);
  800580:	00001597          	auipc	a1,0x1
  800584:	a805a583          	lw	a1,-1408(a1) # 801000 <simple_var>
  800588:	00000517          	auipc	a0,0x0
  80058c:	39050513          	addi	a0,a0,912 # 800918 <main+0x3e2>
  800590:	b11ff0ef          	jal	8000a0 <cprintf>
        assert(simple_var == 100);
  800594:	00001717          	auipc	a4,0x1
  800598:	a6c72703          	lw	a4,-1428(a4) # 801000 <simple_var>
  80059c:	06400793          	li	a5,100
  8005a0:	16f71563          	bne	a4,a5,80070a <main+0x1d4>
        cprintf("Child: Check global_data[0] = %d (Expect 0)\n", global_data[0]);
  8005a4:	00001597          	auipc	a1,0x1
  8005a8:	a645a583          	lw	a1,-1436(a1) # 801008 <global_data>
  8005ac:	00000517          	auipc	a0,0x0
  8005b0:	3dc50513          	addi	a0,a0,988 # 800988 <main+0x452>
  8005b4:	aedff0ef          	jal	8000a0 <cprintf>
        assert(global_data[0] == 0);
  8005b8:	00001797          	auipc	a5,0x1
  8005bc:	a507a783          	lw	a5,-1456(a5) # 801008 <global_data>
  8005c0:	18079d63          	bnez	a5,80075a <main+0x224>

        // [测试点 2]: 触发 COW (写操作)
        cprintf("Child: WRITING data to trigger COW...\n");
  8005c4:	00000517          	auipc	a0,0x0
  8005c8:	40c50513          	addi	a0,a0,1036 # 8009d0 <main+0x49a>
  8005cc:	ad5ff0ef          	jal	8000a0 <cprintf>
        
        // 这里的写操作应该触发 Store Page Fault -> do_pgfault -> 复制物理页
        simple_var = 200;
  8005d0:	0c800713          	li	a4,200
        global_data[0] = 9999;
  8005d4:	6789                	lui	a5,0x2
        simple_var = 200;
  8005d6:	00001697          	auipc	a3,0x1
  8005da:	a2e6a523          	sw	a4,-1494(a3) # 801000 <simple_var>
        global_data[0] = 9999;
  8005de:	70f78793          	addi	a5,a5,1807 # 270f <_start-0x7fd911>
  8005e2:	c01c                	sw	a5,0(s0)
        
        cprintf("Child: Modified simple_var to %d\n", simple_var);
  8005e4:	00001597          	auipc	a1,0x1
  8005e8:	a1c5a583          	lw	a1,-1508(a1) # 801000 <simple_var>
  8005ec:	00000517          	auipc	a0,0x0
  8005f0:	40c50513          	addi	a0,a0,1036 # 8009f8 <main+0x4c2>
  8005f4:	aadff0ef          	jal	8000a0 <cprintf>
        cprintf("Child: Modified global_data[0] to %d\n", global_data[0]);
  8005f8:	00001597          	auipc	a1,0x1
  8005fc:	a105a583          	lw	a1,-1520(a1) # 801008 <global_data>
  800600:	00000517          	auipc	a0,0x0
  800604:	42050513          	addi	a0,a0,1056 # 800a20 <main+0x4ea>
  800608:	a99ff0ef          	jal	8000a0 <cprintf>

        // 确保子进程读到的是修改后的值
        assert(simple_var == 200);
  80060c:	00001697          	auipc	a3,0x1
  800610:	9f46a683          	lw	a3,-1548(a3) # 801000 <simple_var>
  800614:	6789                	lui	a5,0x2
  800616:	0c800713          	li	a4,200
  80061a:	70f78793          	addi	a5,a5,1807 # 270f <_start-0x7fd911>
  80061e:	0ce69663          	bne	a3,a4,8006ea <main+0x1b4>
        assert(global_data[0] == 9999);
  800622:	00001717          	auipc	a4,0x1
  800626:	9e672703          	lw	a4,-1562(a4) # 801008 <global_data>
  80062a:	0af70763          	beq	a4,a5,8006d8 <main+0x1a2>
  80062e:	00000697          	auipc	a3,0x0
  800632:	43268693          	addi	a3,a3,1074 # 800a60 <main+0x52a>
  800636:	00000617          	auipc	a2,0x0
  80063a:	32a60613          	addi	a2,a2,810 # 800960 <main+0x42a>
  80063e:	03200593          	li	a1,50
  800642:	00000517          	auipc	a0,0x0
  800646:	33650513          	addi	a0,a0,822 # 800978 <main+0x442>
  80064a:	9ddff0ef          	jal	800026 <__panic>
    } 
    else {
        /* =================================================
         * 父进程执行区域
         * ================================================= */
        cprintf("Parent: Waiting for child...\n");
  80064e:	e42a                	sd	a0,8(sp)
  800650:	00000517          	auipc	a0,0x0
  800654:	43850513          	addi	a0,a0,1080 # 800a88 <main+0x552>
  800658:	a49ff0ef          	jal	8000a0 <cprintf>
        
        // 等待子进程结束，确保子进程已经执行了写操作
        if (waitpid(pid, NULL) == 0) {
  80065c:	6522                	ld	a0,8(sp)
  80065e:	4581                	li	a1,0
  800660:	ae1ff0ef          	jal	800140 <waitpid>
  800664:	c13d                	beqz	a0,8006ca <main+0x194>
            cprintf("Parent: Child exited.\n");
        }

        // [测试点 3]: 检查父进程的数据是否被污染
        // 如果 COW 实现正确，父进程的物理页应该保持原样，不受子进程影响
        cprintf("Parent: Checking data integrity...\n");
  800666:	00000517          	auipc	a0,0x0
  80066a:	45a50513          	addi	a0,a0,1114 # 800ac0 <main+0x58a>
  80066e:	a33ff0ef          	jal	8000a0 <cprintf>

        cprintf("Parent: simple_var = %d (Expect 100)\n", simple_var);
  800672:	00001597          	auipc	a1,0x1
  800676:	98e5a583          	lw	a1,-1650(a1) # 801000 <simple_var>
  80067a:	00000517          	auipc	a0,0x0
  80067e:	46e50513          	addi	a0,a0,1134 # 800ae8 <main+0x5b2>
  800682:	a1fff0ef          	jal	8000a0 <cprintf>
        if (simple_var != 100) {
  800686:	00001717          	auipc	a4,0x1
  80068a:	97a72703          	lw	a4,-1670(a4) # 801000 <simple_var>
  80068e:	06400793          	li	a5,100
  800692:	08f71c63          	bne	a4,a5,80072a <main+0x1f4>
            panic("COW FAIL: Parent's simple_var changed! Memory is incorrectly shared.\n");
        }

        cprintf("Parent: global_data[0] = %d (Expect 0)\n", global_data[0]);
  800696:	00001597          	auipc	a1,0x1
  80069a:	9725a583          	lw	a1,-1678(a1) # 801008 <global_data>
  80069e:	00000517          	auipc	a0,0x0
  8006a2:	4ba50513          	addi	a0,a0,1210 # 800b58 <main+0x622>
  8006a6:	9fbff0ef          	jal	8000a0 <cprintf>
        if (global_data[0] != 0) {
  8006aa:	00001797          	auipc	a5,0x1
  8006ae:	95e7a783          	lw	a5,-1698(a5) # 801008 <global_data>
  8006b2:	ebc1                	bnez	a5,800742 <main+0x20c>
            panic("COW FAIL: Parent's array changed! Memory is incorrectly shared.\n");
        }

        cprintf("---------- COW TEST PASSED ----------\n");
  8006b4:	00000517          	auipc	a0,0x0
  8006b8:	51450513          	addi	a0,a0,1300 # 800bc8 <main+0x692>
  8006bc:	9e5ff0ef          	jal	8000a0 <cprintf>
    }

    return 0;
  8006c0:	60e2                	ld	ra,24(sp)
  8006c2:	6442                	ld	s0,16(sp)
  8006c4:	4501                	li	a0,0
  8006c6:	6105                	addi	sp,sp,32
  8006c8:	8082                	ret
            cprintf("Parent: Child exited.\n");
  8006ca:	00000517          	auipc	a0,0x0
  8006ce:	3de50513          	addi	a0,a0,990 # 800aa8 <main+0x572>
  8006d2:	9cfff0ef          	jal	8000a0 <cprintf>
  8006d6:	bf41                	j	800666 <main+0x130>
        cprintf("Child: Exit.\n");
  8006d8:	00000517          	auipc	a0,0x0
  8006dc:	3a050513          	addi	a0,a0,928 # 800a78 <main+0x542>
  8006e0:	9c1ff0ef          	jal	8000a0 <cprintf>
        exit(0);
  8006e4:	4501                	li	a0,0
  8006e6:	a43ff0ef          	jal	800128 <exit>
        assert(simple_var == 200);
  8006ea:	00000697          	auipc	a3,0x0
  8006ee:	35e68693          	addi	a3,a3,862 # 800a48 <main+0x512>
  8006f2:	00000617          	auipc	a2,0x0
  8006f6:	26e60613          	addi	a2,a2,622 # 800960 <main+0x42a>
  8006fa:	03100593          	li	a1,49
  8006fe:	00000517          	auipc	a0,0x0
  800702:	27a50513          	addi	a0,a0,634 # 800978 <main+0x442>
  800706:	921ff0ef          	jal	800026 <__panic>
        assert(simple_var == 100);
  80070a:	00000697          	auipc	a3,0x0
  80070e:	23e68693          	addi	a3,a3,574 # 800948 <main+0x412>
  800712:	00000617          	auipc	a2,0x0
  800716:	24e60613          	addi	a2,a2,590 # 800960 <main+0x42a>
  80071a:	02200593          	li	a1,34
  80071e:	00000517          	auipc	a0,0x0
  800722:	25a50513          	addi	a0,a0,602 # 800978 <main+0x442>
  800726:	901ff0ef          	jal	800026 <__panic>
            panic("COW FAIL: Parent's simple_var changed! Memory is incorrectly shared.\n");
  80072a:	00000617          	auipc	a2,0x0
  80072e:	3e660613          	addi	a2,a2,998 # 800b10 <main+0x5da>
  800732:	04800593          	li	a1,72
  800736:	00000517          	auipc	a0,0x0
  80073a:	24250513          	addi	a0,a0,578 # 800978 <main+0x442>
  80073e:	8e9ff0ef          	jal	800026 <__panic>
            panic("COW FAIL: Parent's array changed! Memory is incorrectly shared.\n");
  800742:	00000617          	auipc	a2,0x0
  800746:	43e60613          	addi	a2,a2,1086 # 800b80 <main+0x64a>
  80074a:	04d00593          	li	a1,77
  80074e:	00000517          	auipc	a0,0x0
  800752:	22a50513          	addi	a0,a0,554 # 800978 <main+0x442>
  800756:	8d1ff0ef          	jal	800026 <__panic>
        assert(global_data[0] == 0);
  80075a:	00000697          	auipc	a3,0x0
  80075e:	25e68693          	addi	a3,a3,606 # 8009b8 <main+0x482>
  800762:	00000617          	auipc	a2,0x0
  800766:	1fe60613          	addi	a2,a2,510 # 800960 <main+0x42a>
  80076a:	02400593          	li	a1,36
  80076e:	00000517          	auipc	a0,0x0
  800772:	20a50513          	addi	a0,a0,522 # 800978 <main+0x442>
  800776:	8b1ff0ef          	jal	800026 <__panic>
