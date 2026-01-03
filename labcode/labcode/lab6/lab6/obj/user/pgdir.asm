
obj/__user_pgdir.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <_start>:
    # move down the esp register
    # since it may cause page fault in backtrace
    // subl $0x20, %esp

    # call user-program function
    call umain
  800020:	0ba000ef          	jal	8000da <umain>
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
  800066:	0e6000ef          	jal	80014c <vprintfmt>
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

00000000008000bc <sys_pgdir>:
}

int
sys_pgdir(void) {
    return syscall(SYS_pgdir);
  8000bc:	457d                	li	a0,31
  8000be:	bf55                	j	800072 <syscall>

00000000008000c0 <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  8000c0:	1141                	addi	sp,sp,-16
  8000c2:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  8000c4:	fe9ff0ef          	jal	8000ac <sys_exit>
    cprintf("BUG: exit failed.\n");
  8000c8:	00000517          	auipc	a0,0x0
  8000cc:	43850513          	addi	a0,a0,1080 # 800500 <main+0x32>
  8000d0:	f6fff0ef          	jal	80003e <cprintf>
    while (1);
  8000d4:	a001                	j	8000d4 <exit+0x14>

00000000008000d6 <getpid>:
    return sys_kill(pid);
}

int
getpid(void) {
    return sys_getpid();
  8000d6:	bff1                	j	8000b2 <sys_getpid>

00000000008000d8 <print_pgdir>:
}

//print_pgdir - print the PDT&PT
void
print_pgdir(void) {
    sys_pgdir();
  8000d8:	b7d5                	j	8000bc <sys_pgdir>

00000000008000da <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  8000da:	1141                	addi	sp,sp,-16
  8000dc:	e406                	sd	ra,8(sp)
    int ret = main();
  8000de:	3f0000ef          	jal	8004ce <main>
    exit(ret);
  8000e2:	fdfff0ef          	jal	8000c0 <exit>

00000000008000e6 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
  8000e6:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  8000e8:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  8000ec:	f022                	sd	s0,32(sp)
  8000ee:	ec26                	sd	s1,24(sp)
  8000f0:	e84a                	sd	s2,16(sp)
  8000f2:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  8000f4:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  8000f8:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
  8000fa:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  8000fe:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
  800102:	84aa                	mv	s1,a0
  800104:	892e                	mv	s2,a1
    if (num >= base) {
  800106:	03067d63          	bgeu	a2,a6,800140 <printnum+0x5a>
  80010a:	e44e                	sd	s3,8(sp)
  80010c:	89be                	mv	s3,a5
        while (-- width > 0)
  80010e:	4785                	li	a5,1
  800110:	00e7d763          	bge	a5,a4,80011e <printnum+0x38>
            putch(padc, putdat);
  800114:	85ca                	mv	a1,s2
  800116:	854e                	mv	a0,s3
        while (-- width > 0)
  800118:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  80011a:	9482                	jalr	s1
        while (-- width > 0)
  80011c:	fc65                	bnez	s0,800114 <printnum+0x2e>
  80011e:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  800120:	00000797          	auipc	a5,0x0
  800124:	3f878793          	addi	a5,a5,1016 # 800518 <main+0x4a>
  800128:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  80012a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  80012c:	0007c503          	lbu	a0,0(a5)
}
  800130:	70a2                	ld	ra,40(sp)
  800132:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  800134:	85ca                	mv	a1,s2
  800136:	87a6                	mv	a5,s1
}
  800138:	6942                	ld	s2,16(sp)
  80013a:	64e2                	ld	s1,24(sp)
  80013c:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  80013e:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  800140:	03065633          	divu	a2,a2,a6
  800144:	8722                	mv	a4,s0
  800146:	fa1ff0ef          	jal	8000e6 <printnum>
  80014a:	bfd9                	j	800120 <printnum+0x3a>

000000000080014c <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  80014c:	7119                	addi	sp,sp,-128
  80014e:	f4a6                	sd	s1,104(sp)
  800150:	f0ca                	sd	s2,96(sp)
  800152:	ecce                	sd	s3,88(sp)
  800154:	e8d2                	sd	s4,80(sp)
  800156:	e4d6                	sd	s5,72(sp)
  800158:	e0da                	sd	s6,64(sp)
  80015a:	f862                	sd	s8,48(sp)
  80015c:	fc86                	sd	ra,120(sp)
  80015e:	f8a2                	sd	s0,112(sp)
  800160:	fc5e                	sd	s7,56(sp)
  800162:	f466                	sd	s9,40(sp)
  800164:	f06a                	sd	s10,32(sp)
  800166:	ec6e                	sd	s11,24(sp)
  800168:	84aa                	mv	s1,a0
  80016a:	8c32                	mv	s8,a2
  80016c:	8a36                	mv	s4,a3
  80016e:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  800170:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
  800174:	05500b13          	li	s6,85
  800178:	00000a97          	auipc	s5,0x0
  80017c:	4c8a8a93          	addi	s5,s5,1224 # 800640 <main+0x172>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  800180:	000c4503          	lbu	a0,0(s8)
  800184:	001c0413          	addi	s0,s8,1
  800188:	01350a63          	beq	a0,s3,80019c <vprintfmt+0x50>
            if (ch == '\0') {
  80018c:	cd0d                	beqz	a0,8001c6 <vprintfmt+0x7a>
            putch(ch, putdat);
  80018e:	85ca                	mv	a1,s2
  800190:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  800192:	00044503          	lbu	a0,0(s0)
  800196:	0405                	addi	s0,s0,1
  800198:	ff351ae3          	bne	a0,s3,80018c <vprintfmt+0x40>
        width = precision = -1;
  80019c:	5cfd                	li	s9,-1
  80019e:	8d66                	mv	s10,s9
        char padc = ' ';
  8001a0:	02000d93          	li	s11,32
        lflag = altflag = 0;
  8001a4:	4b81                	li	s7,0
  8001a6:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
  8001a8:	00044683          	lbu	a3,0(s0)
  8001ac:	00140c13          	addi	s8,s0,1
  8001b0:	fdd6859b          	addiw	a1,a3,-35
  8001b4:	0ff5f593          	zext.b	a1,a1
  8001b8:	02bb6663          	bltu	s6,a1,8001e4 <vprintfmt+0x98>
  8001bc:	058a                	slli	a1,a1,0x2
  8001be:	95d6                	add	a1,a1,s5
  8001c0:	4198                	lw	a4,0(a1)
  8001c2:	9756                	add	a4,a4,s5
  8001c4:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  8001c6:	70e6                	ld	ra,120(sp)
  8001c8:	7446                	ld	s0,112(sp)
  8001ca:	74a6                	ld	s1,104(sp)
  8001cc:	7906                	ld	s2,96(sp)
  8001ce:	69e6                	ld	s3,88(sp)
  8001d0:	6a46                	ld	s4,80(sp)
  8001d2:	6aa6                	ld	s5,72(sp)
  8001d4:	6b06                	ld	s6,64(sp)
  8001d6:	7be2                	ld	s7,56(sp)
  8001d8:	7c42                	ld	s8,48(sp)
  8001da:	7ca2                	ld	s9,40(sp)
  8001dc:	7d02                	ld	s10,32(sp)
  8001de:	6de2                	ld	s11,24(sp)
  8001e0:	6109                	addi	sp,sp,128
  8001e2:	8082                	ret
            putch('%', putdat);
  8001e4:	85ca                	mv	a1,s2
  8001e6:	02500513          	li	a0,37
  8001ea:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
  8001ec:	fff44783          	lbu	a5,-1(s0)
  8001f0:	02500713          	li	a4,37
  8001f4:	8c22                	mv	s8,s0
  8001f6:	f8e785e3          	beq	a5,a4,800180 <vprintfmt+0x34>
  8001fa:	ffec4783          	lbu	a5,-2(s8)
  8001fe:	1c7d                	addi	s8,s8,-1
  800200:	fee79de3          	bne	a5,a4,8001fa <vprintfmt+0xae>
  800204:	bfb5                	j	800180 <vprintfmt+0x34>
                ch = *fmt;
  800206:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
  80020a:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
  80020c:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
  800210:	fd06071b          	addiw	a4,a2,-48
  800214:	24e56a63          	bltu	a0,a4,800468 <vprintfmt+0x31c>
                ch = *fmt;
  800218:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
  80021a:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
  80021c:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
  800220:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
  800224:	0197073b          	addw	a4,a4,s9
  800228:	0017171b          	slliw	a4,a4,0x1
  80022c:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
  80022e:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
  800232:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  800234:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
  800238:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
  80023c:	feb570e3          	bgeu	a0,a1,80021c <vprintfmt+0xd0>
            if (width < 0)
  800240:	f60d54e3          	bgez	s10,8001a8 <vprintfmt+0x5c>
                width = precision, precision = -1;
  800244:	8d66                	mv	s10,s9
  800246:	5cfd                	li	s9,-1
  800248:	b785                	j	8001a8 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
  80024a:	8db6                	mv	s11,a3
  80024c:	8462                	mv	s0,s8
  80024e:	bfa9                	j	8001a8 <vprintfmt+0x5c>
  800250:	8462                	mv	s0,s8
            altflag = 1;
  800252:	4b85                	li	s7,1
            goto reswitch;
  800254:	bf91                	j	8001a8 <vprintfmt+0x5c>
    if (lflag >= 2) {
  800256:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800258:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  80025c:	00f74463          	blt	a4,a5,800264 <vprintfmt+0x118>
    else if (lflag) {
  800260:	1a078763          	beqz	a5,80040e <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
  800264:	000a3603          	ld	a2,0(s4)
  800268:	46c1                	li	a3,16
  80026a:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  80026c:	000d879b          	sext.w	a5,s11
  800270:	876a                	mv	a4,s10
  800272:	85ca                	mv	a1,s2
  800274:	8526                	mv	a0,s1
  800276:	e71ff0ef          	jal	8000e6 <printnum>
            break;
  80027a:	b719                	j	800180 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
  80027c:	000a2503          	lw	a0,0(s4)
  800280:	85ca                	mv	a1,s2
  800282:	0a21                	addi	s4,s4,8
  800284:	9482                	jalr	s1
            break;
  800286:	bded                	j	800180 <vprintfmt+0x34>
    if (lflag >= 2) {
  800288:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80028a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  80028e:	00f74463          	blt	a4,a5,800296 <vprintfmt+0x14a>
    else if (lflag) {
  800292:	16078963          	beqz	a5,800404 <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
  800296:	000a3603          	ld	a2,0(s4)
  80029a:	46a9                	li	a3,10
  80029c:	8a2e                	mv	s4,a1
  80029e:	b7f9                	j	80026c <vprintfmt+0x120>
            putch('0', putdat);
  8002a0:	85ca                	mv	a1,s2
  8002a2:	03000513          	li	a0,48
  8002a6:	9482                	jalr	s1
            putch('x', putdat);
  8002a8:	85ca                	mv	a1,s2
  8002aa:	07800513          	li	a0,120
  8002ae:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  8002b0:	000a3603          	ld	a2,0(s4)
            goto number;
  8002b4:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  8002b6:	0a21                	addi	s4,s4,8
            goto number;
  8002b8:	bf55                	j	80026c <vprintfmt+0x120>
            putch(ch, putdat);
  8002ba:	85ca                	mv	a1,s2
  8002bc:	02500513          	li	a0,37
  8002c0:	9482                	jalr	s1
            break;
  8002c2:	bd7d                	j	800180 <vprintfmt+0x34>
            precision = va_arg(ap, int);
  8002c4:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  8002c8:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
  8002ca:	0a21                	addi	s4,s4,8
            goto process_precision;
  8002cc:	bf95                	j	800240 <vprintfmt+0xf4>
    if (lflag >= 2) {
  8002ce:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002d0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002d4:	00f74463          	blt	a4,a5,8002dc <vprintfmt+0x190>
    else if (lflag) {
  8002d8:	12078163          	beqz	a5,8003fa <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
  8002dc:	000a3603          	ld	a2,0(s4)
  8002e0:	46a1                	li	a3,8
  8002e2:	8a2e                	mv	s4,a1
  8002e4:	b761                	j	80026c <vprintfmt+0x120>
            if (width < 0)
  8002e6:	876a                	mv	a4,s10
  8002e8:	000d5363          	bgez	s10,8002ee <vprintfmt+0x1a2>
  8002ec:	4701                	li	a4,0
  8002ee:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
  8002f2:	8462                	mv	s0,s8
            goto reswitch;
  8002f4:	bd55                	j	8001a8 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
  8002f6:	000d841b          	sext.w	s0,s11
  8002fa:	fd340793          	addi	a5,s0,-45
  8002fe:	00f037b3          	snez	a5,a5
  800302:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
  800306:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
  80030a:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
  80030c:	008a0793          	addi	a5,s4,8
  800310:	e43e                	sd	a5,8(sp)
  800312:	100d8c63          	beqz	s11,80042a <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
  800316:	12071363          	bnez	a4,80043c <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80031a:	000dc783          	lbu	a5,0(s11)
  80031e:	0007851b          	sext.w	a0,a5
  800322:	c78d                	beqz	a5,80034c <vprintfmt+0x200>
  800324:	0d85                	addi	s11,s11,1
  800326:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
  800328:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80032c:	000cc563          	bltz	s9,800336 <vprintfmt+0x1ea>
  800330:	3cfd                	addiw	s9,s9,-1
  800332:	008c8d63          	beq	s9,s0,80034c <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
  800336:	020b9663          	bnez	s7,800362 <vprintfmt+0x216>
                    putch(ch, putdat);
  80033a:	85ca                	mv	a1,s2
  80033c:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80033e:	000dc783          	lbu	a5,0(s11)
  800342:	0d85                	addi	s11,s11,1
  800344:	3d7d                	addiw	s10,s10,-1
  800346:	0007851b          	sext.w	a0,a5
  80034a:	f3ed                	bnez	a5,80032c <vprintfmt+0x1e0>
            for (; width > 0; width --) {
  80034c:	01a05963          	blez	s10,80035e <vprintfmt+0x212>
                putch(' ', putdat);
  800350:	85ca                	mv	a1,s2
  800352:	02000513          	li	a0,32
            for (; width > 0; width --) {
  800356:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
  800358:	9482                	jalr	s1
            for (; width > 0; width --) {
  80035a:	fe0d1be3          	bnez	s10,800350 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
  80035e:	6a22                	ld	s4,8(sp)
  800360:	b505                	j	800180 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
  800362:	3781                	addiw	a5,a5,-32
  800364:	fcfa7be3          	bgeu	s4,a5,80033a <vprintfmt+0x1ee>
                    putch('?', putdat);
  800368:	03f00513          	li	a0,63
  80036c:	85ca                	mv	a1,s2
  80036e:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800370:	000dc783          	lbu	a5,0(s11)
  800374:	0d85                	addi	s11,s11,1
  800376:	3d7d                	addiw	s10,s10,-1
  800378:	0007851b          	sext.w	a0,a5
  80037c:	dbe1                	beqz	a5,80034c <vprintfmt+0x200>
  80037e:	fa0cd9e3          	bgez	s9,800330 <vprintfmt+0x1e4>
  800382:	b7c5                	j	800362 <vprintfmt+0x216>
            if (err < 0) {
  800384:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  800388:	4661                	li	a2,24
            err = va_arg(ap, int);
  80038a:	0a21                	addi	s4,s4,8
            if (err < 0) {
  80038c:	41f7d71b          	sraiw	a4,a5,0x1f
  800390:	8fb9                	xor	a5,a5,a4
  800392:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  800396:	02d64563          	blt	a2,a3,8003c0 <vprintfmt+0x274>
  80039a:	00000797          	auipc	a5,0x0
  80039e:	3fe78793          	addi	a5,a5,1022 # 800798 <error_string>
  8003a2:	00369713          	slli	a4,a3,0x3
  8003a6:	97ba                	add	a5,a5,a4
  8003a8:	639c                	ld	a5,0(a5)
  8003aa:	cb99                	beqz	a5,8003c0 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
  8003ac:	86be                	mv	a3,a5
  8003ae:	00000617          	auipc	a2,0x0
  8003b2:	1a260613          	addi	a2,a2,418 # 800550 <main+0x82>
  8003b6:	85ca                	mv	a1,s2
  8003b8:	8526                	mv	a0,s1
  8003ba:	0d8000ef          	jal	800492 <printfmt>
  8003be:	b3c9                	j	800180 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
  8003c0:	00000617          	auipc	a2,0x0
  8003c4:	18060613          	addi	a2,a2,384 # 800540 <main+0x72>
  8003c8:	85ca                	mv	a1,s2
  8003ca:	8526                	mv	a0,s1
  8003cc:	0c6000ef          	jal	800492 <printfmt>
  8003d0:	bb45                	j	800180 <vprintfmt+0x34>
    if (lflag >= 2) {
  8003d2:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8003d4:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
  8003d8:	00f74363          	blt	a4,a5,8003de <vprintfmt+0x292>
    else if (lflag) {
  8003dc:	cf81                	beqz	a5,8003f4 <vprintfmt+0x2a8>
        return va_arg(*ap, long);
  8003de:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  8003e2:	02044b63          	bltz	s0,800418 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
  8003e6:	8622                	mv	a2,s0
  8003e8:	8a5e                	mv	s4,s7
  8003ea:	46a9                	li	a3,10
  8003ec:	b541                	j	80026c <vprintfmt+0x120>
            lflag ++;
  8003ee:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
  8003f0:	8462                	mv	s0,s8
            goto reswitch;
  8003f2:	bb5d                	j	8001a8 <vprintfmt+0x5c>
        return va_arg(*ap, int);
  8003f4:	000a2403          	lw	s0,0(s4)
  8003f8:	b7ed                	j	8003e2 <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
  8003fa:	000a6603          	lwu	a2,0(s4)
  8003fe:	46a1                	li	a3,8
  800400:	8a2e                	mv	s4,a1
  800402:	b5ad                	j	80026c <vprintfmt+0x120>
  800404:	000a6603          	lwu	a2,0(s4)
  800408:	46a9                	li	a3,10
  80040a:	8a2e                	mv	s4,a1
  80040c:	b585                	j	80026c <vprintfmt+0x120>
  80040e:	000a6603          	lwu	a2,0(s4)
  800412:	46c1                	li	a3,16
  800414:	8a2e                	mv	s4,a1
  800416:	bd99                	j	80026c <vprintfmt+0x120>
                putch('-', putdat);
  800418:	85ca                	mv	a1,s2
  80041a:	02d00513          	li	a0,45
  80041e:	9482                	jalr	s1
                num = -(long long)num;
  800420:	40800633          	neg	a2,s0
  800424:	8a5e                	mv	s4,s7
  800426:	46a9                	li	a3,10
  800428:	b591                	j	80026c <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
  80042a:	e329                	bnez	a4,80046c <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80042c:	02800793          	li	a5,40
  800430:	853e                	mv	a0,a5
  800432:	00000d97          	auipc	s11,0x0
  800436:	0ffd8d93          	addi	s11,s11,255 # 800531 <main+0x63>
  80043a:	b5f5                	j	800326 <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
  80043c:	85e6                	mv	a1,s9
  80043e:	856e                	mv	a0,s11
  800440:	072000ef          	jal	8004b2 <strnlen>
  800444:	40ad0d3b          	subw	s10,s10,a0
  800448:	01a05863          	blez	s10,800458 <vprintfmt+0x30c>
                    putch(padc, putdat);
  80044c:	85ca                	mv	a1,s2
  80044e:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
  800450:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
  800452:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
  800454:	fe0d1ce3          	bnez	s10,80044c <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800458:	000dc783          	lbu	a5,0(s11)
  80045c:	0007851b          	sext.w	a0,a5
  800460:	ec0792e3          	bnez	a5,800324 <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
  800464:	6a22                	ld	s4,8(sp)
  800466:	bb29                	j	800180 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
  800468:	8462                	mv	s0,s8
  80046a:	bbd9                	j	800240 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
  80046c:	85e6                	mv	a1,s9
  80046e:	00000517          	auipc	a0,0x0
  800472:	0c250513          	addi	a0,a0,194 # 800530 <main+0x62>
  800476:	03c000ef          	jal	8004b2 <strnlen>
  80047a:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80047e:	02800793          	li	a5,40
                p = "(null)";
  800482:	00000d97          	auipc	s11,0x0
  800486:	0aed8d93          	addi	s11,s11,174 # 800530 <main+0x62>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80048a:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  80048c:	fda040e3          	bgtz	s10,80044c <vprintfmt+0x300>
  800490:	bd51                	j	800324 <vprintfmt+0x1d8>

0000000000800492 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800492:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  800494:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800498:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  80049a:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  80049c:	ec06                	sd	ra,24(sp)
  80049e:	f83a                	sd	a4,48(sp)
  8004a0:	fc3e                	sd	a5,56(sp)
  8004a2:	e0c2                	sd	a6,64(sp)
  8004a4:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  8004a6:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  8004a8:	ca5ff0ef          	jal	80014c <vprintfmt>
}
  8004ac:	60e2                	ld	ra,24(sp)
  8004ae:	6161                	addi	sp,sp,80
  8004b0:	8082                	ret

00000000008004b2 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  8004b2:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  8004b4:	e589                	bnez	a1,8004be <strnlen+0xc>
  8004b6:	a811                	j	8004ca <strnlen+0x18>
        cnt ++;
  8004b8:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  8004ba:	00f58863          	beq	a1,a5,8004ca <strnlen+0x18>
  8004be:	00f50733          	add	a4,a0,a5
  8004c2:	00074703          	lbu	a4,0(a4)
  8004c6:	fb6d                	bnez	a4,8004b8 <strnlen+0x6>
  8004c8:	85be                	mv	a1,a5
    }
    return cnt;
}
  8004ca:	852e                	mv	a0,a1
  8004cc:	8082                	ret

00000000008004ce <main>:
#include <stdio.h>
#include <ulib.h>

int
main(void) {
  8004ce:	1141                	addi	sp,sp,-16
  8004d0:	e406                	sd	ra,8(sp)
    cprintf("I am %d, print pgdir.\n", getpid());
  8004d2:	c05ff0ef          	jal	8000d6 <getpid>
  8004d6:	85aa                	mv	a1,a0
  8004d8:	00000517          	auipc	a0,0x0
  8004dc:	14050513          	addi	a0,a0,320 # 800618 <main+0x14a>
  8004e0:	b5fff0ef          	jal	80003e <cprintf>
    print_pgdir();
  8004e4:	bf5ff0ef          	jal	8000d8 <print_pgdir>
    cprintf("pgdir pass.\n");
  8004e8:	00000517          	auipc	a0,0x0
  8004ec:	14850513          	addi	a0,a0,328 # 800630 <main+0x162>
  8004f0:	b4fff0ef          	jal	80003e <cprintf>
    return 0;
}
  8004f4:	60a2                	ld	ra,8(sp)
  8004f6:	4501                	li	a0,0
  8004f8:	0141                	addi	sp,sp,16
  8004fa:	8082                	ret
