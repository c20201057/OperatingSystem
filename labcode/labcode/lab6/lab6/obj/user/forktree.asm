
obj/__user_forktree.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <_start>:
    # move down the esp register
    # since it may cause page fault in backtrace
    // subl $0x20, %esp

    # call user-program function
    call umain
  800020:	0c0000ef          	jal	8000e0 <umain>
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
  80002c:	092000ef          	jal	8000be <sys_putc>
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
  800066:	106000ef          	jal	80016c <vprintfmt>
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

00000000008000b2 <sys_fork>:
}

int
sys_fork(void) {
    return syscall(SYS_fork);
  8000b2:	4509                	li	a0,2
  8000b4:	bf7d                	j	800072 <syscall>

00000000008000b6 <sys_yield>:
    return syscall(SYS_wait, pid, store);
}

int
sys_yield(void) {
    return syscall(SYS_yield);
  8000b6:	4529                	li	a0,10
  8000b8:	bf6d                	j	800072 <syscall>

00000000008000ba <sys_getpid>:
    return syscall(SYS_kill, pid);
}

int
sys_getpid(void) {
    return syscall(SYS_getpid);
  8000ba:	4549                	li	a0,18
  8000bc:	bf5d                	j	800072 <syscall>

00000000008000be <sys_putc>:
}

int
sys_putc(int64_t c) {
  8000be:	85aa                	mv	a1,a0
    return syscall(SYS_putc, c);
  8000c0:	4579                	li	a0,30
  8000c2:	bf45                	j	800072 <syscall>

00000000008000c4 <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  8000c4:	1141                	addi	sp,sp,-16
  8000c6:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  8000c8:	fe5ff0ef          	jal	8000ac <sys_exit>
    cprintf("BUG: exit failed.\n");
  8000cc:	00000517          	auipc	a0,0x0
  8000d0:	54450513          	addi	a0,a0,1348 # 800610 <main+0x18>
  8000d4:	f6bff0ef          	jal	80003e <cprintf>
    while (1);
  8000d8:	a001                	j	8000d8 <exit+0x14>

00000000008000da <fork>:
}

int
fork(void) {
    return sys_fork();
  8000da:	bfe1                	j	8000b2 <sys_fork>

00000000008000dc <yield>:
    return sys_wait(pid, store);
}

void
yield(void) {
    sys_yield();
  8000dc:	bfe9                	j	8000b6 <sys_yield>

00000000008000de <getpid>:
    return sys_kill(pid);
}

int
getpid(void) {
    return sys_getpid();
  8000de:	bff1                	j	8000ba <sys_getpid>

00000000008000e0 <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  8000e0:	1141                	addi	sp,sp,-16
  8000e2:	e406                	sd	ra,8(sp)
    int ret = main();
  8000e4:	514000ef          	jal	8005f8 <main>
    exit(ret);
  8000e8:	fddff0ef          	jal	8000c4 <exit>

00000000008000ec <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
  8000ec:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  8000ee:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  8000f2:	f022                	sd	s0,32(sp)
  8000f4:	ec26                	sd	s1,24(sp)
  8000f6:	e84a                	sd	s2,16(sp)
  8000f8:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  8000fa:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  8000fe:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
  800100:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  800104:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
  800108:	84aa                	mv	s1,a0
  80010a:	892e                	mv	s2,a1
    if (num >= base) {
  80010c:	03067d63          	bgeu	a2,a6,800146 <printnum+0x5a>
  800110:	e44e                	sd	s3,8(sp)
  800112:	89be                	mv	s3,a5
        while (-- width > 0)
  800114:	4785                	li	a5,1
  800116:	00e7d763          	bge	a5,a4,800124 <printnum+0x38>
            putch(padc, putdat);
  80011a:	85ca                	mv	a1,s2
  80011c:	854e                	mv	a0,s3
        while (-- width > 0)
  80011e:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  800120:	9482                	jalr	s1
        while (-- width > 0)
  800122:	fc65                	bnez	s0,80011a <printnum+0x2e>
  800124:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  800126:	00000797          	auipc	a5,0x0
  80012a:	50278793          	addi	a5,a5,1282 # 800628 <main+0x30>
  80012e:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  800130:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  800132:	0007c503          	lbu	a0,0(a5)
}
  800136:	70a2                	ld	ra,40(sp)
  800138:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  80013a:	85ca                	mv	a1,s2
  80013c:	87a6                	mv	a5,s1
}
  80013e:	6942                	ld	s2,16(sp)
  800140:	64e2                	ld	s1,24(sp)
  800142:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  800144:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  800146:	03065633          	divu	a2,a2,a6
  80014a:	8722                	mv	a4,s0
  80014c:	fa1ff0ef          	jal	8000ec <printnum>
  800150:	bfd9                	j	800126 <printnum+0x3a>

0000000000800152 <sprintputch>:
 * @ch:         the character will be printed
 * @b:          the buffer to place the character @ch
 * */
static void
sprintputch(int ch, struct sprintbuf *b) {
    b->cnt ++;
  800152:	499c                	lw	a5,16(a1)
    if (b->buf < b->ebuf) {
  800154:	6198                	ld	a4,0(a1)
  800156:	6594                	ld	a3,8(a1)
    b->cnt ++;
  800158:	2785                	addiw	a5,a5,1
  80015a:	c99c                	sw	a5,16(a1)
    if (b->buf < b->ebuf) {
  80015c:	00d77763          	bgeu	a4,a3,80016a <sprintputch+0x18>
        *b->buf ++ = ch;
  800160:	00170793          	addi	a5,a4,1
  800164:	e19c                	sd	a5,0(a1)
  800166:	00a70023          	sb	a0,0(a4)
    }
}
  80016a:	8082                	ret

000000000080016c <vprintfmt>:
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  80016c:	7119                	addi	sp,sp,-128
  80016e:	f4a6                	sd	s1,104(sp)
  800170:	f0ca                	sd	s2,96(sp)
  800172:	ecce                	sd	s3,88(sp)
  800174:	e8d2                	sd	s4,80(sp)
  800176:	e4d6                	sd	s5,72(sp)
  800178:	e0da                	sd	s6,64(sp)
  80017a:	f862                	sd	s8,48(sp)
  80017c:	fc86                	sd	ra,120(sp)
  80017e:	f8a2                	sd	s0,112(sp)
  800180:	fc5e                	sd	s7,56(sp)
  800182:	f466                	sd	s9,40(sp)
  800184:	f06a                	sd	s10,32(sp)
  800186:	ec6e                	sd	s11,24(sp)
  800188:	84aa                	mv	s1,a0
  80018a:	8c32                	mv	s8,a2
  80018c:	8a36                	mv	s4,a3
  80018e:	892e                	mv	s2,a1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  800190:	02500993          	li	s3,37
        switch (ch = *(unsigned char *)fmt ++) {
  800194:	05500b13          	li	s6,85
  800198:	00000a97          	auipc	s5,0x0
  80019c:	5a8a8a93          	addi	s5,s5,1448 # 800740 <main+0x148>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001a0:	000c4503          	lbu	a0,0(s8)
  8001a4:	001c0413          	addi	s0,s8,1
  8001a8:	01350a63          	beq	a0,s3,8001bc <vprintfmt+0x50>
            if (ch == '\0') {
  8001ac:	cd0d                	beqz	a0,8001e6 <vprintfmt+0x7a>
            putch(ch, putdat);
  8001ae:	85ca                	mv	a1,s2
  8001b0:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001b2:	00044503          	lbu	a0,0(s0)
  8001b6:	0405                	addi	s0,s0,1
  8001b8:	ff351ae3          	bne	a0,s3,8001ac <vprintfmt+0x40>
        width = precision = -1;
  8001bc:	5cfd                	li	s9,-1
  8001be:	8d66                	mv	s10,s9
        char padc = ' ';
  8001c0:	02000d93          	li	s11,32
        lflag = altflag = 0;
  8001c4:	4b81                	li	s7,0
  8001c6:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
  8001c8:	00044683          	lbu	a3,0(s0)
  8001cc:	00140c13          	addi	s8,s0,1
  8001d0:	fdd6859b          	addiw	a1,a3,-35
  8001d4:	0ff5f593          	zext.b	a1,a1
  8001d8:	02bb6663          	bltu	s6,a1,800204 <vprintfmt+0x98>
  8001dc:	058a                	slli	a1,a1,0x2
  8001de:	95d6                	add	a1,a1,s5
  8001e0:	4198                	lw	a4,0(a1)
  8001e2:	9756                	add	a4,a4,s5
  8001e4:	8702                	jr	a4
}
  8001e6:	70e6                	ld	ra,120(sp)
  8001e8:	7446                	ld	s0,112(sp)
  8001ea:	74a6                	ld	s1,104(sp)
  8001ec:	7906                	ld	s2,96(sp)
  8001ee:	69e6                	ld	s3,88(sp)
  8001f0:	6a46                	ld	s4,80(sp)
  8001f2:	6aa6                	ld	s5,72(sp)
  8001f4:	6b06                	ld	s6,64(sp)
  8001f6:	7be2                	ld	s7,56(sp)
  8001f8:	7c42                	ld	s8,48(sp)
  8001fa:	7ca2                	ld	s9,40(sp)
  8001fc:	7d02                	ld	s10,32(sp)
  8001fe:	6de2                	ld	s11,24(sp)
  800200:	6109                	addi	sp,sp,128
  800202:	8082                	ret
            putch('%', putdat);
  800204:	85ca                	mv	a1,s2
  800206:	02500513          	li	a0,37
  80020a:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
  80020c:	fff44783          	lbu	a5,-1(s0)
  800210:	02500713          	li	a4,37
  800214:	8c22                	mv	s8,s0
  800216:	f8e785e3          	beq	a5,a4,8001a0 <vprintfmt+0x34>
  80021a:	ffec4783          	lbu	a5,-2(s8)
  80021e:	1c7d                	addi	s8,s8,-1
  800220:	fee79de3          	bne	a5,a4,80021a <vprintfmt+0xae>
  800224:	bfb5                	j	8001a0 <vprintfmt+0x34>
                ch = *fmt;
  800226:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
  80022a:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
  80022c:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
  800230:	fd06071b          	addiw	a4,a2,-48
  800234:	24e56a63          	bltu	a0,a4,800488 <vprintfmt+0x31c>
                ch = *fmt;
  800238:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
  80023a:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
  80023c:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
  800240:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
  800244:	0197073b          	addw	a4,a4,s9
  800248:	0017171b          	slliw	a4,a4,0x1
  80024c:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
  80024e:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
  800252:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  800254:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
  800258:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
  80025c:	feb570e3          	bgeu	a0,a1,80023c <vprintfmt+0xd0>
            if (width < 0)
  800260:	f60d54e3          	bgez	s10,8001c8 <vprintfmt+0x5c>
                width = precision, precision = -1;
  800264:	8d66                	mv	s10,s9
  800266:	5cfd                	li	s9,-1
  800268:	b785                	j	8001c8 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
  80026a:	8db6                	mv	s11,a3
  80026c:	8462                	mv	s0,s8
  80026e:	bfa9                	j	8001c8 <vprintfmt+0x5c>
  800270:	8462                	mv	s0,s8
            altflag = 1;
  800272:	4b85                	li	s7,1
            goto reswitch;
  800274:	bf91                	j	8001c8 <vprintfmt+0x5c>
    if (lflag >= 2) {
  800276:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800278:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  80027c:	00f74463          	blt	a4,a5,800284 <vprintfmt+0x118>
    else if (lflag) {
  800280:	1a078763          	beqz	a5,80042e <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
  800284:	000a3603          	ld	a2,0(s4)
  800288:	46c1                	li	a3,16
  80028a:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  80028c:	000d879b          	sext.w	a5,s11
  800290:	876a                	mv	a4,s10
  800292:	85ca                	mv	a1,s2
  800294:	8526                	mv	a0,s1
  800296:	e57ff0ef          	jal	8000ec <printnum>
            break;
  80029a:	b719                	j	8001a0 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
  80029c:	000a2503          	lw	a0,0(s4)
  8002a0:	85ca                	mv	a1,s2
  8002a2:	0a21                	addi	s4,s4,8
  8002a4:	9482                	jalr	s1
            break;
  8002a6:	bded                	j	8001a0 <vprintfmt+0x34>
    if (lflag >= 2) {
  8002a8:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002aa:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002ae:	00f74463          	blt	a4,a5,8002b6 <vprintfmt+0x14a>
    else if (lflag) {
  8002b2:	16078963          	beqz	a5,800424 <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
  8002b6:	000a3603          	ld	a2,0(s4)
  8002ba:	46a9                	li	a3,10
  8002bc:	8a2e                	mv	s4,a1
  8002be:	b7f9                	j	80028c <vprintfmt+0x120>
            putch('0', putdat);
  8002c0:	85ca                	mv	a1,s2
  8002c2:	03000513          	li	a0,48
  8002c6:	9482                	jalr	s1
            putch('x', putdat);
  8002c8:	85ca                	mv	a1,s2
  8002ca:	07800513          	li	a0,120
  8002ce:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  8002d0:	000a3603          	ld	a2,0(s4)
            goto number;
  8002d4:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  8002d6:	0a21                	addi	s4,s4,8
            goto number;
  8002d8:	bf55                	j	80028c <vprintfmt+0x120>
            putch(ch, putdat);
  8002da:	85ca                	mv	a1,s2
  8002dc:	02500513          	li	a0,37
  8002e0:	9482                	jalr	s1
            break;
  8002e2:	bd7d                	j	8001a0 <vprintfmt+0x34>
            precision = va_arg(ap, int);
  8002e4:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  8002e8:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
  8002ea:	0a21                	addi	s4,s4,8
            goto process_precision;
  8002ec:	bf95                	j	800260 <vprintfmt+0xf4>
    if (lflag >= 2) {
  8002ee:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002f0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002f4:	00f74463          	blt	a4,a5,8002fc <vprintfmt+0x190>
    else if (lflag) {
  8002f8:	12078163          	beqz	a5,80041a <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
  8002fc:	000a3603          	ld	a2,0(s4)
  800300:	46a1                	li	a3,8
  800302:	8a2e                	mv	s4,a1
  800304:	b761                	j	80028c <vprintfmt+0x120>
            if (width < 0)
  800306:	876a                	mv	a4,s10
  800308:	000d5363          	bgez	s10,80030e <vprintfmt+0x1a2>
  80030c:	4701                	li	a4,0
  80030e:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
  800312:	8462                	mv	s0,s8
            goto reswitch;
  800314:	bd55                	j	8001c8 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
  800316:	000d841b          	sext.w	s0,s11
  80031a:	fd340793          	addi	a5,s0,-45
  80031e:	00f037b3          	snez	a5,a5
  800322:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
  800326:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
  80032a:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
  80032c:	008a0793          	addi	a5,s4,8
  800330:	e43e                	sd	a5,8(sp)
  800332:	100d8c63          	beqz	s11,80044a <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
  800336:	12071363          	bnez	a4,80045c <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80033a:	000dc783          	lbu	a5,0(s11)
  80033e:	0007851b          	sext.w	a0,a5
  800342:	c78d                	beqz	a5,80036c <vprintfmt+0x200>
  800344:	0d85                	addi	s11,s11,1
  800346:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
  800348:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80034c:	000cc563          	bltz	s9,800356 <vprintfmt+0x1ea>
  800350:	3cfd                	addiw	s9,s9,-1
  800352:	008c8d63          	beq	s9,s0,80036c <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
  800356:	020b9663          	bnez	s7,800382 <vprintfmt+0x216>
                    putch(ch, putdat);
  80035a:	85ca                	mv	a1,s2
  80035c:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80035e:	000dc783          	lbu	a5,0(s11)
  800362:	0d85                	addi	s11,s11,1
  800364:	3d7d                	addiw	s10,s10,-1
  800366:	0007851b          	sext.w	a0,a5
  80036a:	f3ed                	bnez	a5,80034c <vprintfmt+0x1e0>
            for (; width > 0; width --) {
  80036c:	01a05963          	blez	s10,80037e <vprintfmt+0x212>
                putch(' ', putdat);
  800370:	85ca                	mv	a1,s2
  800372:	02000513          	li	a0,32
            for (; width > 0; width --) {
  800376:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
  800378:	9482                	jalr	s1
            for (; width > 0; width --) {
  80037a:	fe0d1be3          	bnez	s10,800370 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
  80037e:	6a22                	ld	s4,8(sp)
  800380:	b505                	j	8001a0 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
  800382:	3781                	addiw	a5,a5,-32
  800384:	fcfa7be3          	bgeu	s4,a5,80035a <vprintfmt+0x1ee>
                    putch('?', putdat);
  800388:	03f00513          	li	a0,63
  80038c:	85ca                	mv	a1,s2
  80038e:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800390:	000dc783          	lbu	a5,0(s11)
  800394:	0d85                	addi	s11,s11,1
  800396:	3d7d                	addiw	s10,s10,-1
  800398:	0007851b          	sext.w	a0,a5
  80039c:	dbe1                	beqz	a5,80036c <vprintfmt+0x200>
  80039e:	fa0cd9e3          	bgez	s9,800350 <vprintfmt+0x1e4>
  8003a2:	b7c5                	j	800382 <vprintfmt+0x216>
            if (err < 0) {
  8003a4:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003a8:	4661                	li	a2,24
            err = va_arg(ap, int);
  8003aa:	0a21                	addi	s4,s4,8
            if (err < 0) {
  8003ac:	41f7d71b          	sraiw	a4,a5,0x1f
  8003b0:	8fb9                	xor	a5,a5,a4
  8003b2:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003b6:	02d64563          	blt	a2,a3,8003e0 <vprintfmt+0x274>
  8003ba:	00000797          	auipc	a5,0x0
  8003be:	4de78793          	addi	a5,a5,1246 # 800898 <error_string>
  8003c2:	00369713          	slli	a4,a3,0x3
  8003c6:	97ba                	add	a5,a5,a4
  8003c8:	639c                	ld	a5,0(a5)
  8003ca:	cb99                	beqz	a5,8003e0 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
  8003cc:	86be                	mv	a3,a5
  8003ce:	00000617          	auipc	a2,0x0
  8003d2:	28a60613          	addi	a2,a2,650 # 800658 <main+0x60>
  8003d6:	85ca                	mv	a1,s2
  8003d8:	8526                	mv	a0,s1
  8003da:	0d8000ef          	jal	8004b2 <printfmt>
  8003de:	b3c9                	j	8001a0 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
  8003e0:	00000617          	auipc	a2,0x0
  8003e4:	26860613          	addi	a2,a2,616 # 800648 <main+0x50>
  8003e8:	85ca                	mv	a1,s2
  8003ea:	8526                	mv	a0,s1
  8003ec:	0c6000ef          	jal	8004b2 <printfmt>
  8003f0:	bb45                	j	8001a0 <vprintfmt+0x34>
    if (lflag >= 2) {
  8003f2:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8003f4:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
  8003f8:	00f74363          	blt	a4,a5,8003fe <vprintfmt+0x292>
    else if (lflag) {
  8003fc:	cf81                	beqz	a5,800414 <vprintfmt+0x2a8>
        return va_arg(*ap, long);
  8003fe:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  800402:	02044b63          	bltz	s0,800438 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
  800406:	8622                	mv	a2,s0
  800408:	8a5e                	mv	s4,s7
  80040a:	46a9                	li	a3,10
  80040c:	b541                	j	80028c <vprintfmt+0x120>
            lflag ++;
  80040e:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
  800410:	8462                	mv	s0,s8
            goto reswitch;
  800412:	bb5d                	j	8001c8 <vprintfmt+0x5c>
        return va_arg(*ap, int);
  800414:	000a2403          	lw	s0,0(s4)
  800418:	b7ed                	j	800402 <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
  80041a:	000a6603          	lwu	a2,0(s4)
  80041e:	46a1                	li	a3,8
  800420:	8a2e                	mv	s4,a1
  800422:	b5ad                	j	80028c <vprintfmt+0x120>
  800424:	000a6603          	lwu	a2,0(s4)
  800428:	46a9                	li	a3,10
  80042a:	8a2e                	mv	s4,a1
  80042c:	b585                	j	80028c <vprintfmt+0x120>
  80042e:	000a6603          	lwu	a2,0(s4)
  800432:	46c1                	li	a3,16
  800434:	8a2e                	mv	s4,a1
  800436:	bd99                	j	80028c <vprintfmt+0x120>
                putch('-', putdat);
  800438:	85ca                	mv	a1,s2
  80043a:	02d00513          	li	a0,45
  80043e:	9482                	jalr	s1
                num = -(long long)num;
  800440:	40800633          	neg	a2,s0
  800444:	8a5e                	mv	s4,s7
  800446:	46a9                	li	a3,10
  800448:	b591                	j	80028c <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
  80044a:	e329                	bnez	a4,80048c <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80044c:	02800793          	li	a5,40
  800450:	853e                	mv	a0,a5
  800452:	00000d97          	auipc	s11,0x0
  800456:	1efd8d93          	addi	s11,s11,495 # 800641 <main+0x49>
  80045a:	b5f5                	j	800346 <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
  80045c:	85e6                	mv	a1,s9
  80045e:	856e                	mv	a0,s11
  800460:	0d0000ef          	jal	800530 <strnlen>
  800464:	40ad0d3b          	subw	s10,s10,a0
  800468:	01a05863          	blez	s10,800478 <vprintfmt+0x30c>
                    putch(padc, putdat);
  80046c:	85ca                	mv	a1,s2
  80046e:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
  800470:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
  800472:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
  800474:	fe0d1ce3          	bnez	s10,80046c <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800478:	000dc783          	lbu	a5,0(s11)
  80047c:	0007851b          	sext.w	a0,a5
  800480:	ec0792e3          	bnez	a5,800344 <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
  800484:	6a22                	ld	s4,8(sp)
  800486:	bb29                	j	8001a0 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
  800488:	8462                	mv	s0,s8
  80048a:	bbd9                	j	800260 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
  80048c:	85e6                	mv	a1,s9
  80048e:	00000517          	auipc	a0,0x0
  800492:	1b250513          	addi	a0,a0,434 # 800640 <main+0x48>
  800496:	09a000ef          	jal	800530 <strnlen>
  80049a:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80049e:	02800793          	li	a5,40
                p = "(null)";
  8004a2:	00000d97          	auipc	s11,0x0
  8004a6:	19ed8d93          	addi	s11,s11,414 # 800640 <main+0x48>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004aa:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004ac:	fda040e3          	bgtz	s10,80046c <vprintfmt+0x300>
  8004b0:	bd51                	j	800344 <vprintfmt+0x1d8>

00000000008004b2 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004b2:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  8004b4:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004b8:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  8004ba:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004bc:	ec06                	sd	ra,24(sp)
  8004be:	f83a                	sd	a4,48(sp)
  8004c0:	fc3e                	sd	a5,56(sp)
  8004c2:	e0c2                	sd	a6,64(sp)
  8004c4:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  8004c6:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  8004c8:	ca5ff0ef          	jal	80016c <vprintfmt>
}
  8004cc:	60e2                	ld	ra,24(sp)
  8004ce:	6161                	addi	sp,sp,80
  8004d0:	8082                	ret

00000000008004d2 <snprintf>:
 * @str:        the buffer to place the result into
 * @size:       the size of buffer, including the trailing null space
 * @fmt:        the format string to use
 * */
int
snprintf(char *str, size_t size, const char *fmt, ...) {
  8004d2:	711d                	addi	sp,sp,-96
 * Call this function if you are already dealing with a va_list.
 * Or you probably want snprintf() instead.
 * */
int
vsnprintf(char *str, size_t size, const char *fmt, va_list ap) {
    struct sprintbuf b = {str, str + size - 1, 0};
  8004d4:	15fd                	addi	a1,a1,-1
  8004d6:	95aa                	add	a1,a1,a0
    va_start(ap, fmt);
  8004d8:	03810313          	addi	t1,sp,56
snprintf(char *str, size_t size, const char *fmt, ...) {
  8004dc:	f406                	sd	ra,40(sp)
    struct sprintbuf b = {str, str + size - 1, 0};
  8004de:	e82e                	sd	a1,16(sp)
  8004e0:	e42a                	sd	a0,8(sp)
snprintf(char *str, size_t size, const char *fmt, ...) {
  8004e2:	fc36                	sd	a3,56(sp)
  8004e4:	e0ba                	sd	a4,64(sp)
  8004e6:	e4be                	sd	a5,72(sp)
  8004e8:	e8c2                	sd	a6,80(sp)
  8004ea:	ecc6                	sd	a7,88(sp)
    struct sprintbuf b = {str, str + size - 1, 0};
  8004ec:	cc02                	sw	zero,24(sp)
    va_start(ap, fmt);
  8004ee:	e01a                	sd	t1,0(sp)
    if (str == NULL || b.buf > b.ebuf) {
  8004f0:	c115                	beqz	a0,800514 <snprintf+0x42>
  8004f2:	02a5e163          	bltu	a1,a0,800514 <snprintf+0x42>
        return -E_INVAL;
    }
    // print the string to the buffer
    vprintfmt((void*)sprintputch, &b, fmt, ap);
  8004f6:	00000517          	auipc	a0,0x0
  8004fa:	c5c50513          	addi	a0,a0,-932 # 800152 <sprintputch>
  8004fe:	869a                	mv	a3,t1
  800500:	002c                	addi	a1,sp,8
  800502:	c6bff0ef          	jal	80016c <vprintfmt>
    // null terminate the buffer
    *b.buf = '\0';
  800506:	67a2                	ld	a5,8(sp)
  800508:	00078023          	sb	zero,0(a5)
    return b.cnt;
  80050c:	4562                	lw	a0,24(sp)
}
  80050e:	70a2                	ld	ra,40(sp)
  800510:	6125                	addi	sp,sp,96
  800512:	8082                	ret
        return -E_INVAL;
  800514:	5575                	li	a0,-3
  800516:	bfe5                	j	80050e <snprintf+0x3c>

0000000000800518 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
  800518:	00054783          	lbu	a5,0(a0)
  80051c:	cb81                	beqz	a5,80052c <strlen+0x14>
    size_t cnt = 0;
  80051e:	4781                	li	a5,0
        cnt ++;
  800520:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
  800522:	00f50733          	add	a4,a0,a5
  800526:	00074703          	lbu	a4,0(a4)
  80052a:	fb7d                	bnez	a4,800520 <strlen+0x8>
    }
    return cnt;
}
  80052c:	853e                	mv	a0,a5
  80052e:	8082                	ret

0000000000800530 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  800530:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  800532:	e589                	bnez	a1,80053c <strnlen+0xc>
  800534:	a811                	j	800548 <strnlen+0x18>
        cnt ++;
  800536:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  800538:	00f58863          	beq	a1,a5,800548 <strnlen+0x18>
  80053c:	00f50733          	add	a4,a0,a5
  800540:	00074703          	lbu	a4,0(a4)
  800544:	fb6d                	bnez	a4,800536 <strnlen+0x6>
  800546:	85be                	mv	a1,a5
    }
    return cnt;
}
  800548:	852e                	mv	a0,a1
  80054a:	8082                	ret

000000000080054c <forktree>:
        exit(0);
    }
}

void
forktree(const char *cur) {
  80054c:	1101                	addi	sp,sp,-32
  80054e:	ec06                	sd	ra,24(sp)
  800550:	e822                	sd	s0,16(sp)
  800552:	842a                	mv	s0,a0
    cprintf("%04x: I am '%s'\n", getpid(), cur);
  800554:	b8bff0ef          	jal	8000de <getpid>
  800558:	85aa                	mv	a1,a0
  80055a:	8622                	mv	a2,s0
  80055c:	00000517          	auipc	a0,0x0
  800560:	1c450513          	addi	a0,a0,452 # 800720 <main+0x128>
  800564:	adbff0ef          	jal	80003e <cprintf>
    if (strlen(cur) >= DEPTH)
  800568:	8522                	mv	a0,s0
  80056a:	fafff0ef          	jal	800518 <strlen>
  80056e:	478d                	li	a5,3
  800570:	00a7f963          	bgeu	a5,a0,800582 <forktree+0x36>

    forkchild(cur, '0');
    forkchild(cur, '1');
  800574:	8522                	mv	a0,s0
}
  800576:	6442                	ld	s0,16(sp)
  800578:	60e2                	ld	ra,24(sp)
    forkchild(cur, '1');
  80057a:	03100593          	li	a1,49
}
  80057e:	6105                	addi	sp,sp,32
    forkchild(cur, '1');
  800580:	a03d                	j	8005ae <forkchild>
    snprintf(nxt, DEPTH + 1, "%s%c", cur, branch);
  800582:	03000713          	li	a4,48
  800586:	86a2                	mv	a3,s0
  800588:	00000617          	auipc	a2,0x0
  80058c:	1b060613          	addi	a2,a2,432 # 800738 <main+0x140>
  800590:	4595                	li	a1,5
  800592:	0028                	addi	a0,sp,8
  800594:	f3fff0ef          	jal	8004d2 <snprintf>
    if (fork() == 0) {
  800598:	b43ff0ef          	jal	8000da <fork>
  80059c:	fd61                	bnez	a0,800574 <forktree+0x28>
        forktree(nxt);
  80059e:	0028                	addi	a0,sp,8
  8005a0:	fadff0ef          	jal	80054c <forktree>
        yield();
  8005a4:	b39ff0ef          	jal	8000dc <yield>
        exit(0);
  8005a8:	4501                	li	a0,0
  8005aa:	b1bff0ef          	jal	8000c4 <exit>

00000000008005ae <forkchild>:
forkchild(const char *cur, char branch) {
  8005ae:	7179                	addi	sp,sp,-48
  8005b0:	f022                	sd	s0,32(sp)
  8005b2:	ec26                	sd	s1,24(sp)
  8005b4:	f406                	sd	ra,40(sp)
  8005b6:	84ae                	mv	s1,a1
  8005b8:	842a                	mv	s0,a0
    if (strlen(cur) >= DEPTH)
  8005ba:	f5fff0ef          	jal	800518 <strlen>
  8005be:	478d                	li	a5,3
  8005c0:	00a7f763          	bgeu	a5,a0,8005ce <forkchild+0x20>
}
  8005c4:	70a2                	ld	ra,40(sp)
  8005c6:	7402                	ld	s0,32(sp)
  8005c8:	64e2                	ld	s1,24(sp)
  8005ca:	6145                	addi	sp,sp,48
  8005cc:	8082                	ret
    snprintf(nxt, DEPTH + 1, "%s%c", cur, branch);
  8005ce:	8726                	mv	a4,s1
  8005d0:	86a2                	mv	a3,s0
  8005d2:	00000617          	auipc	a2,0x0
  8005d6:	16660613          	addi	a2,a2,358 # 800738 <main+0x140>
  8005da:	4595                	li	a1,5
  8005dc:	0028                	addi	a0,sp,8
  8005de:	ef5ff0ef          	jal	8004d2 <snprintf>
    if (fork() == 0) {
  8005e2:	af9ff0ef          	jal	8000da <fork>
  8005e6:	fd79                	bnez	a0,8005c4 <forkchild+0x16>
        forktree(nxt);
  8005e8:	0028                	addi	a0,sp,8
  8005ea:	f63ff0ef          	jal	80054c <forktree>
        yield();
  8005ee:	aefff0ef          	jal	8000dc <yield>
        exit(0);
  8005f2:	4501                	li	a0,0
  8005f4:	ad1ff0ef          	jal	8000c4 <exit>

00000000008005f8 <main>:

int
main(void) {
  8005f8:	1141                	addi	sp,sp,-16
    forktree("");
  8005fa:	00000517          	auipc	a0,0x0
  8005fe:	13650513          	addi	a0,a0,310 # 800730 <main+0x138>
main(void) {
  800602:	e406                	sd	ra,8(sp)
    forktree("");
  800604:	f49ff0ef          	jal	80054c <forktree>
    return 0;
}
  800608:	60a2                	ld	ra,8(sp)
  80060a:	4501                	li	a0,0
  80060c:	0141                	addi	sp,sp,16
  80060e:	8082                	ret
