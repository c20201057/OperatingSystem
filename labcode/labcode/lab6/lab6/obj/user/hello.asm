
obj/__user_hello.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <_start>:
    # move down the esp register
    # since it may cause page fault in backtrace
    // subl $0x20, %esp

    # call user-program function
    call umain
  800020:	0b4000ef          	jal	8000d4 <umain>
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
  80002c:	08a000ef          	jal	8000b6 <sys_putc>
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
  800066:	0e0000ef          	jal	800146 <vprintfmt>
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

00000000008000b2 <sys_getpid>:
    return syscall(SYS_kill, pid);
}

int
sys_getpid(void) {
    return syscall(SYS_getpid);
  8000b2:	4549                	li	a0,18
  8000b4:	bf7d                	j	800072 <syscall>

00000000008000b6 <sys_putc>:
}

int
sys_putc(int64_t c) {
  8000b6:	85aa                	mv	a1,a0
    return syscall(SYS_putc, c);
  8000b8:	4579                	li	a0,30
  8000ba:	bf65                	j	800072 <syscall>

00000000008000bc <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  8000bc:	1141                	addi	sp,sp,-16
  8000be:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  8000c0:	fedff0ef          	jal	8000ac <sys_exit>
    cprintf("BUG: exit failed.\n");
  8000c4:	00000517          	auipc	a0,0x0
  8000c8:	43c50513          	addi	a0,a0,1084 # 800500 <main+0x38>
  8000cc:	f73ff0ef          	jal	80003e <cprintf>
    while (1);
  8000d0:	a001                	j	8000d0 <exit+0x14>

00000000008000d2 <getpid>:
    return sys_kill(pid);
}

int
getpid(void) {
    return sys_getpid();
  8000d2:	b7c5                	j	8000b2 <sys_getpid>

00000000008000d4 <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  8000d4:	1141                	addi	sp,sp,-16
  8000d6:	e406                	sd	ra,8(sp)
    int ret = main();
  8000d8:	3f0000ef          	jal	8004c8 <main>
    exit(ret);
  8000dc:	fe1ff0ef          	jal	8000bc <exit>

00000000008000e0 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
  8000e0:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  8000e2:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  8000e6:	f022                	sd	s0,32(sp)
  8000e8:	ec26                	sd	s1,24(sp)
  8000ea:	e84a                	sd	s2,16(sp)
  8000ec:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  8000ee:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  8000f2:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
  8000f4:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  8000f8:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
  8000fc:	84aa                	mv	s1,a0
  8000fe:	892e                	mv	s2,a1
    if (num >= base) {
  800100:	03067d63          	bgeu	a2,a6,80013a <printnum+0x5a>
  800104:	e44e                	sd	s3,8(sp)
  800106:	89be                	mv	s3,a5
        while (-- width > 0)
  800108:	4785                	li	a5,1
  80010a:	00e7d763          	bge	a5,a4,800118 <printnum+0x38>
            putch(padc, putdat);
  80010e:	85ca                	mv	a1,s2
  800110:	854e                	mv	a0,s3
        while (-- width > 0)
  800112:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  800114:	9482                	jalr	s1
        while (-- width > 0)
  800116:	fc65                	bnez	s0,80010e <printnum+0x2e>
  800118:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  80011a:	00000797          	auipc	a5,0x0
  80011e:	3fe78793          	addi	a5,a5,1022 # 800518 <main+0x50>
  800122:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  800124:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  800126:	0007c503          	lbu	a0,0(a5)
}
  80012a:	70a2                	ld	ra,40(sp)
  80012c:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  80012e:	85ca                	mv	a1,s2
  800130:	87a6                	mv	a5,s1
}
  800132:	6942                	ld	s2,16(sp)
  800134:	64e2                	ld	s1,24(sp)
  800136:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  800138:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  80013a:	03065633          	divu	a2,a2,a6
  80013e:	8722                	mv	a4,s0
  800140:	fa1ff0ef          	jal	8000e0 <printnum>
  800144:	bfd9                	j	80011a <printnum+0x3a>

0000000000800146 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  800146:	7119                	addi	sp,sp,-128
  800148:	f4a6                	sd	s1,104(sp)
  80014a:	f0ca                	sd	s2,96(sp)
  80014c:	ecce                	sd	s3,88(sp)
  80014e:	e8d2                	sd	s4,80(sp)
  800150:	e4d6                	sd	s5,72(sp)
  800152:	e0da                	sd	s6,64(sp)
  800154:	f862                	sd	s8,48(sp)
  800156:	fc86                	sd	ra,120(sp)
  800158:	f8a2                	sd	s0,112(sp)
  80015a:	fc5e                	sd	s7,56(sp)
  80015c:	f466                	sd	s9,40(sp)
  80015e:	f06a                	sd	s10,32(sp)
  800160:	ec6e                	sd	s11,24(sp)
  800162:	84aa                	mv	s1,a0
  800164:	8c32                	mv	s8,a2
  800166:	8a36                	mv	s4,a3
  800168:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  80016a:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
  80016e:	05500b13          	li	s6,85
  800172:	00000a97          	auipc	s5,0x0
  800176:	4dea8a93          	addi	s5,s5,1246 # 800650 <main+0x188>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  80017a:	000c4503          	lbu	a0,0(s8)
  80017e:	001c0413          	addi	s0,s8,1
  800182:	01350a63          	beq	a0,s3,800196 <vprintfmt+0x50>
            if (ch == '\0') {
  800186:	cd0d                	beqz	a0,8001c0 <vprintfmt+0x7a>
            putch(ch, putdat);
  800188:	85ca                	mv	a1,s2
  80018a:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  80018c:	00044503          	lbu	a0,0(s0)
  800190:	0405                	addi	s0,s0,1
  800192:	ff351ae3          	bne	a0,s3,800186 <vprintfmt+0x40>
        width = precision = -1;
  800196:	5cfd                	li	s9,-1
  800198:	8d66                	mv	s10,s9
        char padc = ' ';
  80019a:	02000d93          	li	s11,32
        lflag = altflag = 0;
  80019e:	4b81                	li	s7,0
  8001a0:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
  8001a2:	00044683          	lbu	a3,0(s0)
  8001a6:	00140c13          	addi	s8,s0,1
  8001aa:	fdd6859b          	addiw	a1,a3,-35
  8001ae:	0ff5f593          	zext.b	a1,a1
  8001b2:	02bb6663          	bltu	s6,a1,8001de <vprintfmt+0x98>
  8001b6:	058a                	slli	a1,a1,0x2
  8001b8:	95d6                	add	a1,a1,s5
  8001ba:	4198                	lw	a4,0(a1)
  8001bc:	9756                	add	a4,a4,s5
  8001be:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  8001c0:	70e6                	ld	ra,120(sp)
  8001c2:	7446                	ld	s0,112(sp)
  8001c4:	74a6                	ld	s1,104(sp)
  8001c6:	7906                	ld	s2,96(sp)
  8001c8:	69e6                	ld	s3,88(sp)
  8001ca:	6a46                	ld	s4,80(sp)
  8001cc:	6aa6                	ld	s5,72(sp)
  8001ce:	6b06                	ld	s6,64(sp)
  8001d0:	7be2                	ld	s7,56(sp)
  8001d2:	7c42                	ld	s8,48(sp)
  8001d4:	7ca2                	ld	s9,40(sp)
  8001d6:	7d02                	ld	s10,32(sp)
  8001d8:	6de2                	ld	s11,24(sp)
  8001da:	6109                	addi	sp,sp,128
  8001dc:	8082                	ret
            putch('%', putdat);
  8001de:	85ca                	mv	a1,s2
  8001e0:	02500513          	li	a0,37
  8001e4:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
  8001e6:	fff44783          	lbu	a5,-1(s0)
  8001ea:	02500713          	li	a4,37
  8001ee:	8c22                	mv	s8,s0
  8001f0:	f8e785e3          	beq	a5,a4,80017a <vprintfmt+0x34>
  8001f4:	ffec4783          	lbu	a5,-2(s8)
  8001f8:	1c7d                	addi	s8,s8,-1
  8001fa:	fee79de3          	bne	a5,a4,8001f4 <vprintfmt+0xae>
  8001fe:	bfb5                	j	80017a <vprintfmt+0x34>
                ch = *fmt;
  800200:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
  800204:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
  800206:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
  80020a:	fd06071b          	addiw	a4,a2,-48
  80020e:	24e56a63          	bltu	a0,a4,800462 <vprintfmt+0x31c>
                ch = *fmt;
  800212:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
  800214:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
  800216:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
  80021a:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
  80021e:	0197073b          	addw	a4,a4,s9
  800222:	0017171b          	slliw	a4,a4,0x1
  800226:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
  800228:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
  80022c:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  80022e:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
  800232:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
  800236:	feb570e3          	bgeu	a0,a1,800216 <vprintfmt+0xd0>
            if (width < 0)
  80023a:	f60d54e3          	bgez	s10,8001a2 <vprintfmt+0x5c>
                width = precision, precision = -1;
  80023e:	8d66                	mv	s10,s9
  800240:	5cfd                	li	s9,-1
  800242:	b785                	j	8001a2 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
  800244:	8db6                	mv	s11,a3
  800246:	8462                	mv	s0,s8
  800248:	bfa9                	j	8001a2 <vprintfmt+0x5c>
  80024a:	8462                	mv	s0,s8
            altflag = 1;
  80024c:	4b85                	li	s7,1
            goto reswitch;
  80024e:	bf91                	j	8001a2 <vprintfmt+0x5c>
    if (lflag >= 2) {
  800250:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800252:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800256:	00f74463          	blt	a4,a5,80025e <vprintfmt+0x118>
    else if (lflag) {
  80025a:	1a078763          	beqz	a5,800408 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
  80025e:	000a3603          	ld	a2,0(s4)
  800262:	46c1                	li	a3,16
  800264:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  800266:	000d879b          	sext.w	a5,s11
  80026a:	876a                	mv	a4,s10
  80026c:	85ca                	mv	a1,s2
  80026e:	8526                	mv	a0,s1
  800270:	e71ff0ef          	jal	8000e0 <printnum>
            break;
  800274:	b719                	j	80017a <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
  800276:	000a2503          	lw	a0,0(s4)
  80027a:	85ca                	mv	a1,s2
  80027c:	0a21                	addi	s4,s4,8
  80027e:	9482                	jalr	s1
            break;
  800280:	bded                	j	80017a <vprintfmt+0x34>
    if (lflag >= 2) {
  800282:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800284:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800288:	00f74463          	blt	a4,a5,800290 <vprintfmt+0x14a>
    else if (lflag) {
  80028c:	16078963          	beqz	a5,8003fe <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
  800290:	000a3603          	ld	a2,0(s4)
  800294:	46a9                	li	a3,10
  800296:	8a2e                	mv	s4,a1
  800298:	b7f9                	j	800266 <vprintfmt+0x120>
            putch('0', putdat);
  80029a:	85ca                	mv	a1,s2
  80029c:	03000513          	li	a0,48
  8002a0:	9482                	jalr	s1
            putch('x', putdat);
  8002a2:	85ca                	mv	a1,s2
  8002a4:	07800513          	li	a0,120
  8002a8:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  8002aa:	000a3603          	ld	a2,0(s4)
            goto number;
  8002ae:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  8002b0:	0a21                	addi	s4,s4,8
            goto number;
  8002b2:	bf55                	j	800266 <vprintfmt+0x120>
            putch(ch, putdat);
  8002b4:	85ca                	mv	a1,s2
  8002b6:	02500513          	li	a0,37
  8002ba:	9482                	jalr	s1
            break;
  8002bc:	bd7d                	j	80017a <vprintfmt+0x34>
            precision = va_arg(ap, int);
  8002be:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  8002c2:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
  8002c4:	0a21                	addi	s4,s4,8
            goto process_precision;
  8002c6:	bf95                	j	80023a <vprintfmt+0xf4>
    if (lflag >= 2) {
  8002c8:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002ca:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002ce:	00f74463          	blt	a4,a5,8002d6 <vprintfmt+0x190>
    else if (lflag) {
  8002d2:	12078163          	beqz	a5,8003f4 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
  8002d6:	000a3603          	ld	a2,0(s4)
  8002da:	46a1                	li	a3,8
  8002dc:	8a2e                	mv	s4,a1
  8002de:	b761                	j	800266 <vprintfmt+0x120>
            if (width < 0)
  8002e0:	876a                	mv	a4,s10
  8002e2:	000d5363          	bgez	s10,8002e8 <vprintfmt+0x1a2>
  8002e6:	4701                	li	a4,0
  8002e8:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
  8002ec:	8462                	mv	s0,s8
            goto reswitch;
  8002ee:	bd55                	j	8001a2 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
  8002f0:	000d841b          	sext.w	s0,s11
  8002f4:	fd340793          	addi	a5,s0,-45
  8002f8:	00f037b3          	snez	a5,a5
  8002fc:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
  800300:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
  800304:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
  800306:	008a0793          	addi	a5,s4,8
  80030a:	e43e                	sd	a5,8(sp)
  80030c:	100d8c63          	beqz	s11,800424 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
  800310:	12071363          	bnez	a4,800436 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800314:	000dc783          	lbu	a5,0(s11)
  800318:	0007851b          	sext.w	a0,a5
  80031c:	c78d                	beqz	a5,800346 <vprintfmt+0x200>
  80031e:	0d85                	addi	s11,s11,1
  800320:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
  800322:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800326:	000cc563          	bltz	s9,800330 <vprintfmt+0x1ea>
  80032a:	3cfd                	addiw	s9,s9,-1
  80032c:	008c8d63          	beq	s9,s0,800346 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
  800330:	020b9663          	bnez	s7,80035c <vprintfmt+0x216>
                    putch(ch, putdat);
  800334:	85ca                	mv	a1,s2
  800336:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800338:	000dc783          	lbu	a5,0(s11)
  80033c:	0d85                	addi	s11,s11,1
  80033e:	3d7d                	addiw	s10,s10,-1
  800340:	0007851b          	sext.w	a0,a5
  800344:	f3ed                	bnez	a5,800326 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
  800346:	01a05963          	blez	s10,800358 <vprintfmt+0x212>
                putch(' ', putdat);
  80034a:	85ca                	mv	a1,s2
  80034c:	02000513          	li	a0,32
            for (; width > 0; width --) {
  800350:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
  800352:	9482                	jalr	s1
            for (; width > 0; width --) {
  800354:	fe0d1be3          	bnez	s10,80034a <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
  800358:	6a22                	ld	s4,8(sp)
  80035a:	b505                	j	80017a <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
  80035c:	3781                	addiw	a5,a5,-32
  80035e:	fcfa7be3          	bgeu	s4,a5,800334 <vprintfmt+0x1ee>
                    putch('?', putdat);
  800362:	03f00513          	li	a0,63
  800366:	85ca                	mv	a1,s2
  800368:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80036a:	000dc783          	lbu	a5,0(s11)
  80036e:	0d85                	addi	s11,s11,1
  800370:	3d7d                	addiw	s10,s10,-1
  800372:	0007851b          	sext.w	a0,a5
  800376:	dbe1                	beqz	a5,800346 <vprintfmt+0x200>
  800378:	fa0cd9e3          	bgez	s9,80032a <vprintfmt+0x1e4>
  80037c:	b7c5                	j	80035c <vprintfmt+0x216>
            if (err < 0) {
  80037e:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  800382:	4661                	li	a2,24
            err = va_arg(ap, int);
  800384:	0a21                	addi	s4,s4,8
            if (err < 0) {
  800386:	41f7d71b          	sraiw	a4,a5,0x1f
  80038a:	8fb9                	xor	a5,a5,a4
  80038c:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  800390:	02d64563          	blt	a2,a3,8003ba <vprintfmt+0x274>
  800394:	00000797          	auipc	a5,0x0
  800398:	41478793          	addi	a5,a5,1044 # 8007a8 <error_string>
  80039c:	00369713          	slli	a4,a3,0x3
  8003a0:	97ba                	add	a5,a5,a4
  8003a2:	639c                	ld	a5,0(a5)
  8003a4:	cb99                	beqz	a5,8003ba <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
  8003a6:	86be                	mv	a3,a5
  8003a8:	00000617          	auipc	a2,0x0
  8003ac:	1a860613          	addi	a2,a2,424 # 800550 <main+0x88>
  8003b0:	85ca                	mv	a1,s2
  8003b2:	8526                	mv	a0,s1
  8003b4:	0d8000ef          	jal	80048c <printfmt>
  8003b8:	b3c9                	j	80017a <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
  8003ba:	00000617          	auipc	a2,0x0
  8003be:	18660613          	addi	a2,a2,390 # 800540 <main+0x78>
  8003c2:	85ca                	mv	a1,s2
  8003c4:	8526                	mv	a0,s1
  8003c6:	0c6000ef          	jal	80048c <printfmt>
  8003ca:	bb45                	j	80017a <vprintfmt+0x34>
    if (lflag >= 2) {
  8003cc:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8003ce:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
  8003d2:	00f74363          	blt	a4,a5,8003d8 <vprintfmt+0x292>
    else if (lflag) {
  8003d6:	cf81                	beqz	a5,8003ee <vprintfmt+0x2a8>
        return va_arg(*ap, long);
  8003d8:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  8003dc:	02044b63          	bltz	s0,800412 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
  8003e0:	8622                	mv	a2,s0
  8003e2:	8a5e                	mv	s4,s7
  8003e4:	46a9                	li	a3,10
  8003e6:	b541                	j	800266 <vprintfmt+0x120>
            lflag ++;
  8003e8:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
  8003ea:	8462                	mv	s0,s8
            goto reswitch;
  8003ec:	bb5d                	j	8001a2 <vprintfmt+0x5c>
        return va_arg(*ap, int);
  8003ee:	000a2403          	lw	s0,0(s4)
  8003f2:	b7ed                	j	8003dc <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
  8003f4:	000a6603          	lwu	a2,0(s4)
  8003f8:	46a1                	li	a3,8
  8003fa:	8a2e                	mv	s4,a1
  8003fc:	b5ad                	j	800266 <vprintfmt+0x120>
  8003fe:	000a6603          	lwu	a2,0(s4)
  800402:	46a9                	li	a3,10
  800404:	8a2e                	mv	s4,a1
  800406:	b585                	j	800266 <vprintfmt+0x120>
  800408:	000a6603          	lwu	a2,0(s4)
  80040c:	46c1                	li	a3,16
  80040e:	8a2e                	mv	s4,a1
  800410:	bd99                	j	800266 <vprintfmt+0x120>
                putch('-', putdat);
  800412:	85ca                	mv	a1,s2
  800414:	02d00513          	li	a0,45
  800418:	9482                	jalr	s1
                num = -(long long)num;
  80041a:	40800633          	neg	a2,s0
  80041e:	8a5e                	mv	s4,s7
  800420:	46a9                	li	a3,10
  800422:	b591                	j	800266 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
  800424:	e329                	bnez	a4,800466 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800426:	02800793          	li	a5,40
  80042a:	853e                	mv	a0,a5
  80042c:	00000d97          	auipc	s11,0x0
  800430:	105d8d93          	addi	s11,s11,261 # 800531 <main+0x69>
  800434:	b5f5                	j	800320 <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
  800436:	85e6                	mv	a1,s9
  800438:	856e                	mv	a0,s11
  80043a:	072000ef          	jal	8004ac <strnlen>
  80043e:	40ad0d3b          	subw	s10,s10,a0
  800442:	01a05863          	blez	s10,800452 <vprintfmt+0x30c>
                    putch(padc, putdat);
  800446:	85ca                	mv	a1,s2
  800448:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
  80044a:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
  80044c:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
  80044e:	fe0d1ce3          	bnez	s10,800446 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800452:	000dc783          	lbu	a5,0(s11)
  800456:	0007851b          	sext.w	a0,a5
  80045a:	ec0792e3          	bnez	a5,80031e <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
  80045e:	6a22                	ld	s4,8(sp)
  800460:	bb29                	j	80017a <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
  800462:	8462                	mv	s0,s8
  800464:	bbd9                	j	80023a <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
  800466:	85e6                	mv	a1,s9
  800468:	00000517          	auipc	a0,0x0
  80046c:	0c850513          	addi	a0,a0,200 # 800530 <main+0x68>
  800470:	03c000ef          	jal	8004ac <strnlen>
  800474:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800478:	02800793          	li	a5,40
                p = "(null)";
  80047c:	00000d97          	auipc	s11,0x0
  800480:	0b4d8d93          	addi	s11,s11,180 # 800530 <main+0x68>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800484:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  800486:	fda040e3          	bgtz	s10,800446 <vprintfmt+0x300>
  80048a:	bd51                	j	80031e <vprintfmt+0x1d8>

000000000080048c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  80048c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  80048e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800492:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  800494:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800496:	ec06                	sd	ra,24(sp)
  800498:	f83a                	sd	a4,48(sp)
  80049a:	fc3e                	sd	a5,56(sp)
  80049c:	e0c2                	sd	a6,64(sp)
  80049e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  8004a0:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  8004a2:	ca5ff0ef          	jal	800146 <vprintfmt>
}
  8004a6:	60e2                	ld	ra,24(sp)
  8004a8:	6161                	addi	sp,sp,80
  8004aa:	8082                	ret

00000000008004ac <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  8004ac:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  8004ae:	e589                	bnez	a1,8004b8 <strnlen+0xc>
  8004b0:	a811                	j	8004c4 <strnlen+0x18>
        cnt ++;
  8004b2:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  8004b4:	00f58863          	beq	a1,a5,8004c4 <strnlen+0x18>
  8004b8:	00f50733          	add	a4,a0,a5
  8004bc:	00074703          	lbu	a4,0(a4)
  8004c0:	fb6d                	bnez	a4,8004b2 <strnlen+0x6>
  8004c2:	85be                	mv	a1,a5
    }
    return cnt;
}
  8004c4:	852e                	mv	a0,a1
  8004c6:	8082                	ret

00000000008004c8 <main>:
#include <stdio.h>
#include <ulib.h>

int
main(void) {
  8004c8:	1141                	addi	sp,sp,-16
    cprintf("Hello world!!.\n");
  8004ca:	00000517          	auipc	a0,0x0
  8004ce:	14e50513          	addi	a0,a0,334 # 800618 <main+0x150>
main(void) {
  8004d2:	e406                	sd	ra,8(sp)
    cprintf("Hello world!!.\n");
  8004d4:	b6bff0ef          	jal	80003e <cprintf>
    cprintf("I am process %d.\n", getpid());
  8004d8:	bfbff0ef          	jal	8000d2 <getpid>
  8004dc:	85aa                	mv	a1,a0
  8004de:	00000517          	auipc	a0,0x0
  8004e2:	14a50513          	addi	a0,a0,330 # 800628 <main+0x160>
  8004e6:	b59ff0ef          	jal	80003e <cprintf>
    cprintf("hello pass.\n");
  8004ea:	00000517          	auipc	a0,0x0
  8004ee:	15650513          	addi	a0,a0,342 # 800640 <main+0x178>
  8004f2:	b4dff0ef          	jal	80003e <cprintf>
    return 0;
}
  8004f6:	60a2                	ld	ra,8(sp)
  8004f8:	4501                	li	a0,0
  8004fa:	0141                	addi	sp,sp,16
  8004fc:	8082                	ret
