
obj/__user_softint.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <_start>:
    # move down the esp register
    # since it may cause page fault in backtrace
    // subl $0x20, %esp

    # call user-program function
    call umain
  800020:	0ae000ef          	jal	8000ce <umain>
1:  j 1b
  800024:	a001                	j	800024 <_start+0x4>

0000000000800026 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
  800026:	1101                	addi	sp,sp,-32
  800028:	ec06                	sd	ra,24(sp)
  80002a:	e42e                	sd	a1,8(sp)
    sys_putc(c);
  80002c:	086000ef          	jal	8000b2 <sys_putc>
    (*cnt) ++;
  800030:	65a2                	ld	a1,8(sp)
}
  800032:	60e2                	ld	ra,24(sp)
    (*cnt) ++;
  800034:	419c                	lw	a5,0(a1)
  800036:	2785                	addiw	a5,a5,1
  800038:	c19c                	sw	a5,0(a1)
}
  80003a:	6105                	addi	sp,sp,32
  80003c:	8082                	ret

000000000080003e <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
  80003e:	711d                	addi	sp,sp,-96
    va_list ap;

    va_start(ap, fmt);
  800040:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
  800044:	f42e                	sd	a1,40(sp)
  800046:	f832                	sd	a2,48(sp)
  800048:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  80004a:	862a                	mv	a2,a0
  80004c:	004c                	addi	a1,sp,4
  80004e:	00000517          	auipc	a0,0x0
  800052:	fd850513          	addi	a0,a0,-40 # 800026 <cputch>
  800056:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
  800058:	ec06                	sd	ra,24(sp)
  80005a:	e0ba                	sd	a4,64(sp)
  80005c:	e4be                	sd	a5,72(sp)
  80005e:	e8c2                	sd	a6,80(sp)
  800060:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
  800062:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
  800064:	e41a                	sd	t1,8(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  800066:	0da000ef          	jal	800140 <vprintfmt>
    int cnt = vcprintf(fmt, ap);
    va_end(ap);

    return cnt;
}
  80006a:	60e2                	ld	ra,24(sp)
  80006c:	4512                	lw	a0,4(sp)
  80006e:	6125                	addi	sp,sp,96
  800070:	8082                	ret

0000000000800072 <syscall>:
#include <syscall.h>

#define MAX_ARGS            5

static inline int
syscall(int64_t num, ...) {
  800072:	7175                	addi	sp,sp,-144
    va_list ap;
    va_start(ap, num);
    uint64_t a[MAX_ARGS];
    int i, ret;
    for (i = 0; i < MAX_ARGS; i ++) {
        a[i] = va_arg(ap, uint64_t);
  800074:	08010313          	addi	t1,sp,128
syscall(int64_t num, ...) {
  800078:	e42a                	sd	a0,8(sp)
  80007a:	ecae                	sd	a1,88(sp)
        a[i] = va_arg(ap, uint64_t);
  80007c:	f42e                	sd	a1,40(sp)
syscall(int64_t num, ...) {
  80007e:	f0b2                	sd	a2,96(sp)
        a[i] = va_arg(ap, uint64_t);
  800080:	f832                	sd	a2,48(sp)
syscall(int64_t num, ...) {
  800082:	f4b6                	sd	a3,104(sp)
        a[i] = va_arg(ap, uint64_t);
  800084:	fc36                	sd	a3,56(sp)
syscall(int64_t num, ...) {
  800086:	f8ba                	sd	a4,112(sp)
        a[i] = va_arg(ap, uint64_t);
  800088:	e0ba                	sd	a4,64(sp)
syscall(int64_t num, ...) {
  80008a:	fcbe                	sd	a5,120(sp)
        a[i] = va_arg(ap, uint64_t);
  80008c:	e4be                	sd	a5,72(sp)
syscall(int64_t num, ...) {
  80008e:	e142                	sd	a6,128(sp)
  800090:	e546                	sd	a7,136(sp)
        a[i] = va_arg(ap, uint64_t);
  800092:	f01a                	sd	t1,32(sp)
    }
    va_end(ap);
    asm volatile (
  800094:	4522                	lw	a0,8(sp)
  800096:	55a2                	lw	a1,40(sp)
  800098:	5642                	lw	a2,48(sp)
  80009a:	56e2                	lw	a3,56(sp)
  80009c:	4706                	lw	a4,64(sp)
  80009e:	47a6                	lw	a5,72(sp)
  8000a0:	00000073          	ecall
  8000a4:	ce2a                	sw	a0,28(sp)
          "m" (a[3]),
          "m" (a[4])
        : "memory"
      );
    return ret;
}
  8000a6:	4572                	lw	a0,28(sp)
  8000a8:	6149                	addi	sp,sp,144
  8000aa:	8082                	ret

00000000008000ac <sys_exit>:

int
sys_exit(int64_t error_code) {
  8000ac:	85aa                	mv	a1,a0
    return syscall(SYS_exit, error_code);
  8000ae:	4505                	li	a0,1
  8000b0:	b7c9                	j	800072 <syscall>

00000000008000b2 <sys_putc>:
sys_getpid(void) {
    return syscall(SYS_getpid);
}

int
sys_putc(int64_t c) {
  8000b2:	85aa                	mv	a1,a0
    return syscall(SYS_putc, c);
  8000b4:	4579                	li	a0,30
  8000b6:	bf75                	j	800072 <syscall>

00000000008000b8 <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  8000b8:	1141                	addi	sp,sp,-16
  8000ba:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  8000bc:	ff1ff0ef          	jal	8000ac <sys_exit>
    cprintf("BUG: exit failed.\n");
  8000c0:	00000517          	auipc	a0,0x0
  8000c4:	41050513          	addi	a0,a0,1040 # 8004d0 <main+0xe>
  8000c8:	f77ff0ef          	jal	80003e <cprintf>
    while (1);
  8000cc:	a001                	j	8000cc <exit+0x14>

00000000008000ce <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  8000ce:	1141                	addi	sp,sp,-16
  8000d0:	e406                	sd	ra,8(sp)
    int ret = main();
  8000d2:	3f0000ef          	jal	8004c2 <main>
    exit(ret);
  8000d6:	fe3ff0ef          	jal	8000b8 <exit>

00000000008000da <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
  8000da:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  8000dc:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  8000e0:	f022                	sd	s0,32(sp)
  8000e2:	ec26                	sd	s1,24(sp)
  8000e4:	e84a                	sd	s2,16(sp)
  8000e6:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  8000e8:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  8000ec:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
  8000ee:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  8000f2:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
  8000f6:	84aa                	mv	s1,a0
  8000f8:	892e                	mv	s2,a1
    if (num >= base) {
  8000fa:	03067d63          	bgeu	a2,a6,800134 <printnum+0x5a>
  8000fe:	e44e                	sd	s3,8(sp)
  800100:	89be                	mv	s3,a5
        while (-- width > 0)
  800102:	4785                	li	a5,1
  800104:	00e7d763          	bge	a5,a4,800112 <printnum+0x38>
            putch(padc, putdat);
  800108:	85ca                	mv	a1,s2
  80010a:	854e                	mv	a0,s3
        while (-- width > 0)
  80010c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  80010e:	9482                	jalr	s1
        while (-- width > 0)
  800110:	fc65                	bnez	s0,800108 <printnum+0x2e>
  800112:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  800114:	00000797          	auipc	a5,0x0
  800118:	3d478793          	addi	a5,a5,980 # 8004e8 <main+0x26>
  80011c:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  80011e:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  800120:	0007c503          	lbu	a0,0(a5)
}
  800124:	70a2                	ld	ra,40(sp)
  800126:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  800128:	85ca                	mv	a1,s2
  80012a:	87a6                	mv	a5,s1
}
  80012c:	6942                	ld	s2,16(sp)
  80012e:	64e2                	ld	s1,24(sp)
  800130:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  800132:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  800134:	03065633          	divu	a2,a2,a6
  800138:	8722                	mv	a4,s0
  80013a:	fa1ff0ef          	jal	8000da <printnum>
  80013e:	bfd9                	j	800114 <printnum+0x3a>

0000000000800140 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  800140:	7119                	addi	sp,sp,-128
  800142:	f4a6                	sd	s1,104(sp)
  800144:	f0ca                	sd	s2,96(sp)
  800146:	ecce                	sd	s3,88(sp)
  800148:	e8d2                	sd	s4,80(sp)
  80014a:	e4d6                	sd	s5,72(sp)
  80014c:	e0da                	sd	s6,64(sp)
  80014e:	f862                	sd	s8,48(sp)
  800150:	fc86                	sd	ra,120(sp)
  800152:	f8a2                	sd	s0,112(sp)
  800154:	fc5e                	sd	s7,56(sp)
  800156:	f466                	sd	s9,40(sp)
  800158:	f06a                	sd	s10,32(sp)
  80015a:	ec6e                	sd	s11,24(sp)
  80015c:	84aa                	mv	s1,a0
  80015e:	8c32                	mv	s8,a2
  800160:	8a36                	mv	s4,a3
  800162:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  800164:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
  800168:	05500b13          	li	s6,85
  80016c:	00000a97          	auipc	s5,0x0
  800170:	47ca8a93          	addi	s5,s5,1148 # 8005e8 <main+0x126>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  800174:	000c4503          	lbu	a0,0(s8)
  800178:	001c0413          	addi	s0,s8,1
  80017c:	01350a63          	beq	a0,s3,800190 <vprintfmt+0x50>
            if (ch == '\0') {
  800180:	cd0d                	beqz	a0,8001ba <vprintfmt+0x7a>
            putch(ch, putdat);
  800182:	85ca                	mv	a1,s2
  800184:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  800186:	00044503          	lbu	a0,0(s0)
  80018a:	0405                	addi	s0,s0,1
  80018c:	ff351ae3          	bne	a0,s3,800180 <vprintfmt+0x40>
        width = precision = -1;
  800190:	5cfd                	li	s9,-1
  800192:	8d66                	mv	s10,s9
        char padc = ' ';
  800194:	02000d93          	li	s11,32
        lflag = altflag = 0;
  800198:	4b81                	li	s7,0
  80019a:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
  80019c:	00044683          	lbu	a3,0(s0)
  8001a0:	00140c13          	addi	s8,s0,1
  8001a4:	fdd6859b          	addiw	a1,a3,-35
  8001a8:	0ff5f593          	zext.b	a1,a1
  8001ac:	02bb6663          	bltu	s6,a1,8001d8 <vprintfmt+0x98>
  8001b0:	058a                	slli	a1,a1,0x2
  8001b2:	95d6                	add	a1,a1,s5
  8001b4:	4198                	lw	a4,0(a1)
  8001b6:	9756                	add	a4,a4,s5
  8001b8:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  8001ba:	70e6                	ld	ra,120(sp)
  8001bc:	7446                	ld	s0,112(sp)
  8001be:	74a6                	ld	s1,104(sp)
  8001c0:	7906                	ld	s2,96(sp)
  8001c2:	69e6                	ld	s3,88(sp)
  8001c4:	6a46                	ld	s4,80(sp)
  8001c6:	6aa6                	ld	s5,72(sp)
  8001c8:	6b06                	ld	s6,64(sp)
  8001ca:	7be2                	ld	s7,56(sp)
  8001cc:	7c42                	ld	s8,48(sp)
  8001ce:	7ca2                	ld	s9,40(sp)
  8001d0:	7d02                	ld	s10,32(sp)
  8001d2:	6de2                	ld	s11,24(sp)
  8001d4:	6109                	addi	sp,sp,128
  8001d6:	8082                	ret
            putch('%', putdat);
  8001d8:	85ca                	mv	a1,s2
  8001da:	02500513          	li	a0,37
  8001de:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
  8001e0:	fff44783          	lbu	a5,-1(s0)
  8001e4:	02500713          	li	a4,37
  8001e8:	8c22                	mv	s8,s0
  8001ea:	f8e785e3          	beq	a5,a4,800174 <vprintfmt+0x34>
  8001ee:	ffec4783          	lbu	a5,-2(s8)
  8001f2:	1c7d                	addi	s8,s8,-1
  8001f4:	fee79de3          	bne	a5,a4,8001ee <vprintfmt+0xae>
  8001f8:	bfb5                	j	800174 <vprintfmt+0x34>
                ch = *fmt;
  8001fa:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
  8001fe:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
  800200:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
  800204:	fd06071b          	addiw	a4,a2,-48
  800208:	24e56a63          	bltu	a0,a4,80045c <vprintfmt+0x31c>
                ch = *fmt;
  80020c:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
  80020e:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
  800210:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
  800214:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
  800218:	0197073b          	addw	a4,a4,s9
  80021c:	0017171b          	slliw	a4,a4,0x1
  800220:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
  800222:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
  800226:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  800228:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
  80022c:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
  800230:	feb570e3          	bgeu	a0,a1,800210 <vprintfmt+0xd0>
            if (width < 0)
  800234:	f60d54e3          	bgez	s10,80019c <vprintfmt+0x5c>
                width = precision, precision = -1;
  800238:	8d66                	mv	s10,s9
  80023a:	5cfd                	li	s9,-1
  80023c:	b785                	j	80019c <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
  80023e:	8db6                	mv	s11,a3
  800240:	8462                	mv	s0,s8
  800242:	bfa9                	j	80019c <vprintfmt+0x5c>
  800244:	8462                	mv	s0,s8
            altflag = 1;
  800246:	4b85                	li	s7,1
            goto reswitch;
  800248:	bf91                	j	80019c <vprintfmt+0x5c>
    if (lflag >= 2) {
  80024a:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80024c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800250:	00f74463          	blt	a4,a5,800258 <vprintfmt+0x118>
    else if (lflag) {
  800254:	1a078763          	beqz	a5,800402 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
  800258:	000a3603          	ld	a2,0(s4)
  80025c:	46c1                	li	a3,16
  80025e:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  800260:	000d879b          	sext.w	a5,s11
  800264:	876a                	mv	a4,s10
  800266:	85ca                	mv	a1,s2
  800268:	8526                	mv	a0,s1
  80026a:	e71ff0ef          	jal	8000da <printnum>
            break;
  80026e:	b719                	j	800174 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
  800270:	000a2503          	lw	a0,0(s4)
  800274:	85ca                	mv	a1,s2
  800276:	0a21                	addi	s4,s4,8
  800278:	9482                	jalr	s1
            break;
  80027a:	bded                	j	800174 <vprintfmt+0x34>
    if (lflag >= 2) {
  80027c:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80027e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800282:	00f74463          	blt	a4,a5,80028a <vprintfmt+0x14a>
    else if (lflag) {
  800286:	16078963          	beqz	a5,8003f8 <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
  80028a:	000a3603          	ld	a2,0(s4)
  80028e:	46a9                	li	a3,10
  800290:	8a2e                	mv	s4,a1
  800292:	b7f9                	j	800260 <vprintfmt+0x120>
            putch('0', putdat);
  800294:	85ca                	mv	a1,s2
  800296:	03000513          	li	a0,48
  80029a:	9482                	jalr	s1
            putch('x', putdat);
  80029c:	85ca                	mv	a1,s2
  80029e:	07800513          	li	a0,120
  8002a2:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  8002a4:	000a3603          	ld	a2,0(s4)
            goto number;
  8002a8:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  8002aa:	0a21                	addi	s4,s4,8
            goto number;
  8002ac:	bf55                	j	800260 <vprintfmt+0x120>
            putch(ch, putdat);
  8002ae:	85ca                	mv	a1,s2
  8002b0:	02500513          	li	a0,37
  8002b4:	9482                	jalr	s1
            break;
  8002b6:	bd7d                	j	800174 <vprintfmt+0x34>
            precision = va_arg(ap, int);
  8002b8:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  8002bc:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
  8002be:	0a21                	addi	s4,s4,8
            goto process_precision;
  8002c0:	bf95                	j	800234 <vprintfmt+0xf4>
    if (lflag >= 2) {
  8002c2:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002c4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002c8:	00f74463          	blt	a4,a5,8002d0 <vprintfmt+0x190>
    else if (lflag) {
  8002cc:	12078163          	beqz	a5,8003ee <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
  8002d0:	000a3603          	ld	a2,0(s4)
  8002d4:	46a1                	li	a3,8
  8002d6:	8a2e                	mv	s4,a1
  8002d8:	b761                	j	800260 <vprintfmt+0x120>
            if (width < 0)
  8002da:	876a                	mv	a4,s10
  8002dc:	000d5363          	bgez	s10,8002e2 <vprintfmt+0x1a2>
  8002e0:	4701                	li	a4,0
  8002e2:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
  8002e6:	8462                	mv	s0,s8
            goto reswitch;
  8002e8:	bd55                	j	80019c <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
  8002ea:	000d841b          	sext.w	s0,s11
  8002ee:	fd340793          	addi	a5,s0,-45
  8002f2:	00f037b3          	snez	a5,a5
  8002f6:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
  8002fa:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
  8002fe:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
  800300:	008a0793          	addi	a5,s4,8
  800304:	e43e                	sd	a5,8(sp)
  800306:	100d8c63          	beqz	s11,80041e <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
  80030a:	12071363          	bnez	a4,800430 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80030e:	000dc783          	lbu	a5,0(s11)
  800312:	0007851b          	sext.w	a0,a5
  800316:	c78d                	beqz	a5,800340 <vprintfmt+0x200>
  800318:	0d85                	addi	s11,s11,1
  80031a:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
  80031c:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800320:	000cc563          	bltz	s9,80032a <vprintfmt+0x1ea>
  800324:	3cfd                	addiw	s9,s9,-1
  800326:	008c8d63          	beq	s9,s0,800340 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
  80032a:	020b9663          	bnez	s7,800356 <vprintfmt+0x216>
                    putch(ch, putdat);
  80032e:	85ca                	mv	a1,s2
  800330:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800332:	000dc783          	lbu	a5,0(s11)
  800336:	0d85                	addi	s11,s11,1
  800338:	3d7d                	addiw	s10,s10,-1
  80033a:	0007851b          	sext.w	a0,a5
  80033e:	f3ed                	bnez	a5,800320 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
  800340:	01a05963          	blez	s10,800352 <vprintfmt+0x212>
                putch(' ', putdat);
  800344:	85ca                	mv	a1,s2
  800346:	02000513          	li	a0,32
            for (; width > 0; width --) {
  80034a:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
  80034c:	9482                	jalr	s1
            for (; width > 0; width --) {
  80034e:	fe0d1be3          	bnez	s10,800344 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
  800352:	6a22                	ld	s4,8(sp)
  800354:	b505                	j	800174 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
  800356:	3781                	addiw	a5,a5,-32
  800358:	fcfa7be3          	bgeu	s4,a5,80032e <vprintfmt+0x1ee>
                    putch('?', putdat);
  80035c:	03f00513          	li	a0,63
  800360:	85ca                	mv	a1,s2
  800362:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800364:	000dc783          	lbu	a5,0(s11)
  800368:	0d85                	addi	s11,s11,1
  80036a:	3d7d                	addiw	s10,s10,-1
  80036c:	0007851b          	sext.w	a0,a5
  800370:	dbe1                	beqz	a5,800340 <vprintfmt+0x200>
  800372:	fa0cd9e3          	bgez	s9,800324 <vprintfmt+0x1e4>
  800376:	b7c5                	j	800356 <vprintfmt+0x216>
            if (err < 0) {
  800378:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  80037c:	4661                	li	a2,24
            err = va_arg(ap, int);
  80037e:	0a21                	addi	s4,s4,8
            if (err < 0) {
  800380:	41f7d71b          	sraiw	a4,a5,0x1f
  800384:	8fb9                	xor	a5,a5,a4
  800386:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  80038a:	02d64563          	blt	a2,a3,8003b4 <vprintfmt+0x274>
  80038e:	00000797          	auipc	a5,0x0
  800392:	3b278793          	addi	a5,a5,946 # 800740 <error_string>
  800396:	00369713          	slli	a4,a3,0x3
  80039a:	97ba                	add	a5,a5,a4
  80039c:	639c                	ld	a5,0(a5)
  80039e:	cb99                	beqz	a5,8003b4 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
  8003a0:	86be                	mv	a3,a5
  8003a2:	00000617          	auipc	a2,0x0
  8003a6:	17e60613          	addi	a2,a2,382 # 800520 <main+0x5e>
  8003aa:	85ca                	mv	a1,s2
  8003ac:	8526                	mv	a0,s1
  8003ae:	0d8000ef          	jal	800486 <printfmt>
  8003b2:	b3c9                	j	800174 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
  8003b4:	00000617          	auipc	a2,0x0
  8003b8:	15c60613          	addi	a2,a2,348 # 800510 <main+0x4e>
  8003bc:	85ca                	mv	a1,s2
  8003be:	8526                	mv	a0,s1
  8003c0:	0c6000ef          	jal	800486 <printfmt>
  8003c4:	bb45                	j	800174 <vprintfmt+0x34>
    if (lflag >= 2) {
  8003c6:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8003c8:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
  8003cc:	00f74363          	blt	a4,a5,8003d2 <vprintfmt+0x292>
    else if (lflag) {
  8003d0:	cf81                	beqz	a5,8003e8 <vprintfmt+0x2a8>
        return va_arg(*ap, long);
  8003d2:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  8003d6:	02044b63          	bltz	s0,80040c <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
  8003da:	8622                	mv	a2,s0
  8003dc:	8a5e                	mv	s4,s7
  8003de:	46a9                	li	a3,10
  8003e0:	b541                	j	800260 <vprintfmt+0x120>
            lflag ++;
  8003e2:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
  8003e4:	8462                	mv	s0,s8
            goto reswitch;
  8003e6:	bb5d                	j	80019c <vprintfmt+0x5c>
        return va_arg(*ap, int);
  8003e8:	000a2403          	lw	s0,0(s4)
  8003ec:	b7ed                	j	8003d6 <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
  8003ee:	000a6603          	lwu	a2,0(s4)
  8003f2:	46a1                	li	a3,8
  8003f4:	8a2e                	mv	s4,a1
  8003f6:	b5ad                	j	800260 <vprintfmt+0x120>
  8003f8:	000a6603          	lwu	a2,0(s4)
  8003fc:	46a9                	li	a3,10
  8003fe:	8a2e                	mv	s4,a1
  800400:	b585                	j	800260 <vprintfmt+0x120>
  800402:	000a6603          	lwu	a2,0(s4)
  800406:	46c1                	li	a3,16
  800408:	8a2e                	mv	s4,a1
  80040a:	bd99                	j	800260 <vprintfmt+0x120>
                putch('-', putdat);
  80040c:	85ca                	mv	a1,s2
  80040e:	02d00513          	li	a0,45
  800412:	9482                	jalr	s1
                num = -(long long)num;
  800414:	40800633          	neg	a2,s0
  800418:	8a5e                	mv	s4,s7
  80041a:	46a9                	li	a3,10
  80041c:	b591                	j	800260 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
  80041e:	e329                	bnez	a4,800460 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800420:	02800793          	li	a5,40
  800424:	853e                	mv	a0,a5
  800426:	00000d97          	auipc	s11,0x0
  80042a:	0dbd8d93          	addi	s11,s11,219 # 800501 <main+0x3f>
  80042e:	b5f5                	j	80031a <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
  800430:	85e6                	mv	a1,s9
  800432:	856e                	mv	a0,s11
  800434:	072000ef          	jal	8004a6 <strnlen>
  800438:	40ad0d3b          	subw	s10,s10,a0
  80043c:	01a05863          	blez	s10,80044c <vprintfmt+0x30c>
                    putch(padc, putdat);
  800440:	85ca                	mv	a1,s2
  800442:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
  800444:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
  800446:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
  800448:	fe0d1ce3          	bnez	s10,800440 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80044c:	000dc783          	lbu	a5,0(s11)
  800450:	0007851b          	sext.w	a0,a5
  800454:	ec0792e3          	bnez	a5,800318 <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
  800458:	6a22                	ld	s4,8(sp)
  80045a:	bb29                	j	800174 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
  80045c:	8462                	mv	s0,s8
  80045e:	bbd9                	j	800234 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
  800460:	85e6                	mv	a1,s9
  800462:	00000517          	auipc	a0,0x0
  800466:	09e50513          	addi	a0,a0,158 # 800500 <main+0x3e>
  80046a:	03c000ef          	jal	8004a6 <strnlen>
  80046e:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800472:	02800793          	li	a5,40
                p = "(null)";
  800476:	00000d97          	auipc	s11,0x0
  80047a:	08ad8d93          	addi	s11,s11,138 # 800500 <main+0x3e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80047e:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  800480:	fda040e3          	bgtz	s10,800440 <vprintfmt+0x300>
  800484:	bd51                	j	800318 <vprintfmt+0x1d8>

0000000000800486 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800486:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  800488:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  80048c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  80048e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800490:	ec06                	sd	ra,24(sp)
  800492:	f83a                	sd	a4,48(sp)
  800494:	fc3e                	sd	a5,56(sp)
  800496:	e0c2                	sd	a6,64(sp)
  800498:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  80049a:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  80049c:	ca5ff0ef          	jal	800140 <vprintfmt>
}
  8004a0:	60e2                	ld	ra,24(sp)
  8004a2:	6161                	addi	sp,sp,80
  8004a4:	8082                	ret

00000000008004a6 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  8004a6:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  8004a8:	e589                	bnez	a1,8004b2 <strnlen+0xc>
  8004aa:	a811                	j	8004be <strnlen+0x18>
        cnt ++;
  8004ac:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  8004ae:	00f58863          	beq	a1,a5,8004be <strnlen+0x18>
  8004b2:	00f50733          	add	a4,a0,a5
  8004b6:	00074703          	lbu	a4,0(a4)
  8004ba:	fb6d                	bnez	a4,8004ac <strnlen+0x6>
  8004bc:	85be                	mv	a1,a5
    }
    return cnt;
}
  8004be:	852e                	mv	a0,a1
  8004c0:	8082                	ret

00000000008004c2 <main>:
#include <stdio.h>
#include <ulib.h>

int
main(void) {
  8004c2:	1141                	addi	sp,sp,-16
    // asm volatile("int $14");
    exit(0);
  8004c4:	4501                	li	a0,0
main(void) {
  8004c6:	e406                	sd	ra,8(sp)
    exit(0);
  8004c8:	bf1ff0ef          	jal	8000b8 <exit>
