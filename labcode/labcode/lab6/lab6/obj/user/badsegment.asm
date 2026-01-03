
obj/__user_badsegment.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <_start>:
    # move down the esp register
    # since it may cause page fault in backtrace
    // subl $0x20, %esp

    # call user-program function
    call umain
  800020:	110000ef          	jal	800130 <umain>
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
  800038:	50c50513          	addi	a0,a0,1292 # 800540 <main+0x1c>
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
  80005a:	50a50513          	addi	a0,a0,1290 # 800560 <main+0x3c>
  80005e:	042000ef          	jal	8000a0 <cprintf>
    va_end(ap);
    exit(-E_PANIC);
  800062:	5559                	li	a0,-10
  800064:	0b6000ef          	jal	80011a <exit>

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
  80006e:	0a6000ef          	jal	800114 <sys_putc>
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
  800094:	10e000ef          	jal	8001a2 <vprintfmt>
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
  8000c8:	0da000ef          	jal	8001a2 <vprintfmt>
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

0000000000800114 <sys_putc>:
sys_getpid(void) {
    return syscall(SYS_getpid);
}

int
sys_putc(int64_t c) {
  800114:	85aa                	mv	a1,a0
    return syscall(SYS_putc, c);
  800116:	4579                	li	a0,30
  800118:	bf75                	j	8000d4 <syscall>

000000000080011a <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  80011a:	1141                	addi	sp,sp,-16
  80011c:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  80011e:	ff1ff0ef          	jal	80010e <sys_exit>
    cprintf("BUG: exit failed.\n");
  800122:	00000517          	auipc	a0,0x0
  800126:	44650513          	addi	a0,a0,1094 # 800568 <main+0x44>
  80012a:	f77ff0ef          	jal	8000a0 <cprintf>
    while (1);
  80012e:	a001                	j	80012e <exit+0x14>

0000000000800130 <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  800130:	1141                	addi	sp,sp,-16
  800132:	e406                	sd	ra,8(sp)
    int ret = main();
  800134:	3f0000ef          	jal	800524 <main>
    exit(ret);
  800138:	fe3ff0ef          	jal	80011a <exit>

000000000080013c <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
  80013c:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  80013e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800142:	f022                	sd	s0,32(sp)
  800144:	ec26                	sd	s1,24(sp)
  800146:	e84a                	sd	s2,16(sp)
  800148:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  80014a:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  80014e:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
  800150:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  800154:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
  800158:	84aa                	mv	s1,a0
  80015a:	892e                	mv	s2,a1
    if (num >= base) {
  80015c:	03067d63          	bgeu	a2,a6,800196 <printnum+0x5a>
  800160:	e44e                	sd	s3,8(sp)
  800162:	89be                	mv	s3,a5
        while (-- width > 0)
  800164:	4785                	li	a5,1
  800166:	00e7d763          	bge	a5,a4,800174 <printnum+0x38>
            putch(padc, putdat);
  80016a:	85ca                	mv	a1,s2
  80016c:	854e                	mv	a0,s3
        while (-- width > 0)
  80016e:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  800170:	9482                	jalr	s1
        while (-- width > 0)
  800172:	fc65                	bnez	s0,80016a <printnum+0x2e>
  800174:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  800176:	00000797          	auipc	a5,0x0
  80017a:	40a78793          	addi	a5,a5,1034 # 800580 <main+0x5c>
  80017e:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  800180:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  800182:	0007c503          	lbu	a0,0(a5)
}
  800186:	70a2                	ld	ra,40(sp)
  800188:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  80018a:	85ca                	mv	a1,s2
  80018c:	87a6                	mv	a5,s1
}
  80018e:	6942                	ld	s2,16(sp)
  800190:	64e2                	ld	s1,24(sp)
  800192:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  800194:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  800196:	03065633          	divu	a2,a2,a6
  80019a:	8722                	mv	a4,s0
  80019c:	fa1ff0ef          	jal	80013c <printnum>
  8001a0:	bfd9                	j	800176 <printnum+0x3a>

00000000008001a2 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  8001a2:	7119                	addi	sp,sp,-128
  8001a4:	f4a6                	sd	s1,104(sp)
  8001a6:	f0ca                	sd	s2,96(sp)
  8001a8:	ecce                	sd	s3,88(sp)
  8001aa:	e8d2                	sd	s4,80(sp)
  8001ac:	e4d6                	sd	s5,72(sp)
  8001ae:	e0da                	sd	s6,64(sp)
  8001b0:	f862                	sd	s8,48(sp)
  8001b2:	fc86                	sd	ra,120(sp)
  8001b4:	f8a2                	sd	s0,112(sp)
  8001b6:	fc5e                	sd	s7,56(sp)
  8001b8:	f466                	sd	s9,40(sp)
  8001ba:	f06a                	sd	s10,32(sp)
  8001bc:	ec6e                	sd	s11,24(sp)
  8001be:	84aa                	mv	s1,a0
  8001c0:	8c32                	mv	s8,a2
  8001c2:	8a36                	mv	s4,a3
  8001c4:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001c6:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
  8001ca:	05500b13          	li	s6,85
  8001ce:	00000a97          	auipc	s5,0x0
  8001d2:	4cea8a93          	addi	s5,s5,1230 # 80069c <main+0x178>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001d6:	000c4503          	lbu	a0,0(s8)
  8001da:	001c0413          	addi	s0,s8,1
  8001de:	01350a63          	beq	a0,s3,8001f2 <vprintfmt+0x50>
            if (ch == '\0') {
  8001e2:	cd0d                	beqz	a0,80021c <vprintfmt+0x7a>
            putch(ch, putdat);
  8001e4:	85ca                	mv	a1,s2
  8001e6:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001e8:	00044503          	lbu	a0,0(s0)
  8001ec:	0405                	addi	s0,s0,1
  8001ee:	ff351ae3          	bne	a0,s3,8001e2 <vprintfmt+0x40>
        width = precision = -1;
  8001f2:	5cfd                	li	s9,-1
  8001f4:	8d66                	mv	s10,s9
        char padc = ' ';
  8001f6:	02000d93          	li	s11,32
        lflag = altflag = 0;
  8001fa:	4b81                	li	s7,0
  8001fc:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
  8001fe:	00044683          	lbu	a3,0(s0)
  800202:	00140c13          	addi	s8,s0,1
  800206:	fdd6859b          	addiw	a1,a3,-35
  80020a:	0ff5f593          	zext.b	a1,a1
  80020e:	02bb6663          	bltu	s6,a1,80023a <vprintfmt+0x98>
  800212:	058a                	slli	a1,a1,0x2
  800214:	95d6                	add	a1,a1,s5
  800216:	4198                	lw	a4,0(a1)
  800218:	9756                	add	a4,a4,s5
  80021a:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  80021c:	70e6                	ld	ra,120(sp)
  80021e:	7446                	ld	s0,112(sp)
  800220:	74a6                	ld	s1,104(sp)
  800222:	7906                	ld	s2,96(sp)
  800224:	69e6                	ld	s3,88(sp)
  800226:	6a46                	ld	s4,80(sp)
  800228:	6aa6                	ld	s5,72(sp)
  80022a:	6b06                	ld	s6,64(sp)
  80022c:	7be2                	ld	s7,56(sp)
  80022e:	7c42                	ld	s8,48(sp)
  800230:	7ca2                	ld	s9,40(sp)
  800232:	7d02                	ld	s10,32(sp)
  800234:	6de2                	ld	s11,24(sp)
  800236:	6109                	addi	sp,sp,128
  800238:	8082                	ret
            putch('%', putdat);
  80023a:	85ca                	mv	a1,s2
  80023c:	02500513          	li	a0,37
  800240:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
  800242:	fff44783          	lbu	a5,-1(s0)
  800246:	02500713          	li	a4,37
  80024a:	8c22                	mv	s8,s0
  80024c:	f8e785e3          	beq	a5,a4,8001d6 <vprintfmt+0x34>
  800250:	ffec4783          	lbu	a5,-2(s8)
  800254:	1c7d                	addi	s8,s8,-1
  800256:	fee79de3          	bne	a5,a4,800250 <vprintfmt+0xae>
  80025a:	bfb5                	j	8001d6 <vprintfmt+0x34>
                ch = *fmt;
  80025c:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
  800260:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
  800262:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
  800266:	fd06071b          	addiw	a4,a2,-48
  80026a:	24e56a63          	bltu	a0,a4,8004be <vprintfmt+0x31c>
                ch = *fmt;
  80026e:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
  800270:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
  800272:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
  800276:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
  80027a:	0197073b          	addw	a4,a4,s9
  80027e:	0017171b          	slliw	a4,a4,0x1
  800282:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
  800284:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
  800288:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  80028a:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
  80028e:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
  800292:	feb570e3          	bgeu	a0,a1,800272 <vprintfmt+0xd0>
            if (width < 0)
  800296:	f60d54e3          	bgez	s10,8001fe <vprintfmt+0x5c>
                width = precision, precision = -1;
  80029a:	8d66                	mv	s10,s9
  80029c:	5cfd                	li	s9,-1
  80029e:	b785                	j	8001fe <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
  8002a0:	8db6                	mv	s11,a3
  8002a2:	8462                	mv	s0,s8
  8002a4:	bfa9                	j	8001fe <vprintfmt+0x5c>
  8002a6:	8462                	mv	s0,s8
            altflag = 1;
  8002a8:	4b85                	li	s7,1
            goto reswitch;
  8002aa:	bf91                	j	8001fe <vprintfmt+0x5c>
    if (lflag >= 2) {
  8002ac:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002ae:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002b2:	00f74463          	blt	a4,a5,8002ba <vprintfmt+0x118>
    else if (lflag) {
  8002b6:	1a078763          	beqz	a5,800464 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
  8002ba:	000a3603          	ld	a2,0(s4)
  8002be:	46c1                	li	a3,16
  8002c0:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  8002c2:	000d879b          	sext.w	a5,s11
  8002c6:	876a                	mv	a4,s10
  8002c8:	85ca                	mv	a1,s2
  8002ca:	8526                	mv	a0,s1
  8002cc:	e71ff0ef          	jal	80013c <printnum>
            break;
  8002d0:	b719                	j	8001d6 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
  8002d2:	000a2503          	lw	a0,0(s4)
  8002d6:	85ca                	mv	a1,s2
  8002d8:	0a21                	addi	s4,s4,8
  8002da:	9482                	jalr	s1
            break;
  8002dc:	bded                	j	8001d6 <vprintfmt+0x34>
    if (lflag >= 2) {
  8002de:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002e0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002e4:	00f74463          	blt	a4,a5,8002ec <vprintfmt+0x14a>
    else if (lflag) {
  8002e8:	16078963          	beqz	a5,80045a <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
  8002ec:	000a3603          	ld	a2,0(s4)
  8002f0:	46a9                	li	a3,10
  8002f2:	8a2e                	mv	s4,a1
  8002f4:	b7f9                	j	8002c2 <vprintfmt+0x120>
            putch('0', putdat);
  8002f6:	85ca                	mv	a1,s2
  8002f8:	03000513          	li	a0,48
  8002fc:	9482                	jalr	s1
            putch('x', putdat);
  8002fe:	85ca                	mv	a1,s2
  800300:	07800513          	li	a0,120
  800304:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  800306:	000a3603          	ld	a2,0(s4)
            goto number;
  80030a:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  80030c:	0a21                	addi	s4,s4,8
            goto number;
  80030e:	bf55                	j	8002c2 <vprintfmt+0x120>
            putch(ch, putdat);
  800310:	85ca                	mv	a1,s2
  800312:	02500513          	li	a0,37
  800316:	9482                	jalr	s1
            break;
  800318:	bd7d                	j	8001d6 <vprintfmt+0x34>
            precision = va_arg(ap, int);
  80031a:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  80031e:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
  800320:	0a21                	addi	s4,s4,8
            goto process_precision;
  800322:	bf95                	j	800296 <vprintfmt+0xf4>
    if (lflag >= 2) {
  800324:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800326:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  80032a:	00f74463          	blt	a4,a5,800332 <vprintfmt+0x190>
    else if (lflag) {
  80032e:	12078163          	beqz	a5,800450 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
  800332:	000a3603          	ld	a2,0(s4)
  800336:	46a1                	li	a3,8
  800338:	8a2e                	mv	s4,a1
  80033a:	b761                	j	8002c2 <vprintfmt+0x120>
            if (width < 0)
  80033c:	876a                	mv	a4,s10
  80033e:	000d5363          	bgez	s10,800344 <vprintfmt+0x1a2>
  800342:	4701                	li	a4,0
  800344:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
  800348:	8462                	mv	s0,s8
            goto reswitch;
  80034a:	bd55                	j	8001fe <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
  80034c:	000d841b          	sext.w	s0,s11
  800350:	fd340793          	addi	a5,s0,-45
  800354:	00f037b3          	snez	a5,a5
  800358:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
  80035c:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
  800360:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
  800362:	008a0793          	addi	a5,s4,8
  800366:	e43e                	sd	a5,8(sp)
  800368:	100d8c63          	beqz	s11,800480 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
  80036c:	12071363          	bnez	a4,800492 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800370:	000dc783          	lbu	a5,0(s11)
  800374:	0007851b          	sext.w	a0,a5
  800378:	c78d                	beqz	a5,8003a2 <vprintfmt+0x200>
  80037a:	0d85                	addi	s11,s11,1
  80037c:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
  80037e:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800382:	000cc563          	bltz	s9,80038c <vprintfmt+0x1ea>
  800386:	3cfd                	addiw	s9,s9,-1
  800388:	008c8d63          	beq	s9,s0,8003a2 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
  80038c:	020b9663          	bnez	s7,8003b8 <vprintfmt+0x216>
                    putch(ch, putdat);
  800390:	85ca                	mv	a1,s2
  800392:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800394:	000dc783          	lbu	a5,0(s11)
  800398:	0d85                	addi	s11,s11,1
  80039a:	3d7d                	addiw	s10,s10,-1
  80039c:	0007851b          	sext.w	a0,a5
  8003a0:	f3ed                	bnez	a5,800382 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
  8003a2:	01a05963          	blez	s10,8003b4 <vprintfmt+0x212>
                putch(' ', putdat);
  8003a6:	85ca                	mv	a1,s2
  8003a8:	02000513          	li	a0,32
            for (; width > 0; width --) {
  8003ac:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
  8003ae:	9482                	jalr	s1
            for (; width > 0; width --) {
  8003b0:	fe0d1be3          	bnez	s10,8003a6 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
  8003b4:	6a22                	ld	s4,8(sp)
  8003b6:	b505                	j	8001d6 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
  8003b8:	3781                	addiw	a5,a5,-32
  8003ba:	fcfa7be3          	bgeu	s4,a5,800390 <vprintfmt+0x1ee>
                    putch('?', putdat);
  8003be:	03f00513          	li	a0,63
  8003c2:	85ca                	mv	a1,s2
  8003c4:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003c6:	000dc783          	lbu	a5,0(s11)
  8003ca:	0d85                	addi	s11,s11,1
  8003cc:	3d7d                	addiw	s10,s10,-1
  8003ce:	0007851b          	sext.w	a0,a5
  8003d2:	dbe1                	beqz	a5,8003a2 <vprintfmt+0x200>
  8003d4:	fa0cd9e3          	bgez	s9,800386 <vprintfmt+0x1e4>
  8003d8:	b7c5                	j	8003b8 <vprintfmt+0x216>
            if (err < 0) {
  8003da:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003de:	4661                	li	a2,24
            err = va_arg(ap, int);
  8003e0:	0a21                	addi	s4,s4,8
            if (err < 0) {
  8003e2:	41f7d71b          	sraiw	a4,a5,0x1f
  8003e6:	8fb9                	xor	a5,a5,a4
  8003e8:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003ec:	02d64563          	blt	a2,a3,800416 <vprintfmt+0x274>
  8003f0:	00000797          	auipc	a5,0x0
  8003f4:	40878793          	addi	a5,a5,1032 # 8007f8 <error_string>
  8003f8:	00369713          	slli	a4,a3,0x3
  8003fc:	97ba                	add	a5,a5,a4
  8003fe:	639c                	ld	a5,0(a5)
  800400:	cb99                	beqz	a5,800416 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
  800402:	86be                	mv	a3,a5
  800404:	00000617          	auipc	a2,0x0
  800408:	1ac60613          	addi	a2,a2,428 # 8005b0 <main+0x8c>
  80040c:	85ca                	mv	a1,s2
  80040e:	8526                	mv	a0,s1
  800410:	0d8000ef          	jal	8004e8 <printfmt>
  800414:	b3c9                	j	8001d6 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
  800416:	00000617          	auipc	a2,0x0
  80041a:	18a60613          	addi	a2,a2,394 # 8005a0 <main+0x7c>
  80041e:	85ca                	mv	a1,s2
  800420:	8526                	mv	a0,s1
  800422:	0c6000ef          	jal	8004e8 <printfmt>
  800426:	bb45                	j	8001d6 <vprintfmt+0x34>
    if (lflag >= 2) {
  800428:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80042a:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
  80042e:	00f74363          	blt	a4,a5,800434 <vprintfmt+0x292>
    else if (lflag) {
  800432:	cf81                	beqz	a5,80044a <vprintfmt+0x2a8>
        return va_arg(*ap, long);
  800434:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  800438:	02044b63          	bltz	s0,80046e <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
  80043c:	8622                	mv	a2,s0
  80043e:	8a5e                	mv	s4,s7
  800440:	46a9                	li	a3,10
  800442:	b541                	j	8002c2 <vprintfmt+0x120>
            lflag ++;
  800444:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
  800446:	8462                	mv	s0,s8
            goto reswitch;
  800448:	bb5d                	j	8001fe <vprintfmt+0x5c>
        return va_arg(*ap, int);
  80044a:	000a2403          	lw	s0,0(s4)
  80044e:	b7ed                	j	800438 <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
  800450:	000a6603          	lwu	a2,0(s4)
  800454:	46a1                	li	a3,8
  800456:	8a2e                	mv	s4,a1
  800458:	b5ad                	j	8002c2 <vprintfmt+0x120>
  80045a:	000a6603          	lwu	a2,0(s4)
  80045e:	46a9                	li	a3,10
  800460:	8a2e                	mv	s4,a1
  800462:	b585                	j	8002c2 <vprintfmt+0x120>
  800464:	000a6603          	lwu	a2,0(s4)
  800468:	46c1                	li	a3,16
  80046a:	8a2e                	mv	s4,a1
  80046c:	bd99                	j	8002c2 <vprintfmt+0x120>
                putch('-', putdat);
  80046e:	85ca                	mv	a1,s2
  800470:	02d00513          	li	a0,45
  800474:	9482                	jalr	s1
                num = -(long long)num;
  800476:	40800633          	neg	a2,s0
  80047a:	8a5e                	mv	s4,s7
  80047c:	46a9                	li	a3,10
  80047e:	b591                	j	8002c2 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
  800480:	e329                	bnez	a4,8004c2 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800482:	02800793          	li	a5,40
  800486:	853e                	mv	a0,a5
  800488:	00000d97          	auipc	s11,0x0
  80048c:	111d8d93          	addi	s11,s11,273 # 800599 <main+0x75>
  800490:	b5f5                	j	80037c <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
  800492:	85e6                	mv	a1,s9
  800494:	856e                	mv	a0,s11
  800496:	072000ef          	jal	800508 <strnlen>
  80049a:	40ad0d3b          	subw	s10,s10,a0
  80049e:	01a05863          	blez	s10,8004ae <vprintfmt+0x30c>
                    putch(padc, putdat);
  8004a2:	85ca                	mv	a1,s2
  8004a4:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004a6:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
  8004a8:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004aa:	fe0d1ce3          	bnez	s10,8004a2 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004ae:	000dc783          	lbu	a5,0(s11)
  8004b2:	0007851b          	sext.w	a0,a5
  8004b6:	ec0792e3          	bnez	a5,80037a <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
  8004ba:	6a22                	ld	s4,8(sp)
  8004bc:	bb29                	j	8001d6 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
  8004be:	8462                	mv	s0,s8
  8004c0:	bbd9                	j	800296 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004c2:	85e6                	mv	a1,s9
  8004c4:	00000517          	auipc	a0,0x0
  8004c8:	0d450513          	addi	a0,a0,212 # 800598 <main+0x74>
  8004cc:	03c000ef          	jal	800508 <strnlen>
  8004d0:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004d4:	02800793          	li	a5,40
                p = "(null)";
  8004d8:	00000d97          	auipc	s11,0x0
  8004dc:	0c0d8d93          	addi	s11,s11,192 # 800598 <main+0x74>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004e0:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004e2:	fda040e3          	bgtz	s10,8004a2 <vprintfmt+0x300>
  8004e6:	bd51                	j	80037a <vprintfmt+0x1d8>

00000000008004e8 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004e8:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  8004ea:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004ee:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  8004f0:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004f2:	ec06                	sd	ra,24(sp)
  8004f4:	f83a                	sd	a4,48(sp)
  8004f6:	fc3e                	sd	a5,56(sp)
  8004f8:	e0c2                	sd	a6,64(sp)
  8004fa:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  8004fc:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  8004fe:	ca5ff0ef          	jal	8001a2 <vprintfmt>
}
  800502:	60e2                	ld	ra,24(sp)
  800504:	6161                	addi	sp,sp,80
  800506:	8082                	ret

0000000000800508 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  800508:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  80050a:	e589                	bnez	a1,800514 <strnlen+0xc>
  80050c:	a811                	j	800520 <strnlen+0x18>
        cnt ++;
  80050e:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  800510:	00f58863          	beq	a1,a5,800520 <strnlen+0x18>
  800514:	00f50733          	add	a4,a0,a5
  800518:	00074703          	lbu	a4,0(a4)
  80051c:	fb6d                	bnez	a4,80050e <strnlen+0x6>
  80051e:	85be                	mv	a1,a5
    }
    return cnt;
}
  800520:	852e                	mv	a0,a1
  800522:	8082                	ret

0000000000800524 <main>:
#include <ulib.h>

/* try to load the kernel's TSS selector into the DS register */

int
main(void) {
  800524:	1141                	addi	sp,sp,-16
    // asm volatile("movw $0x28,%ax; movw %ax,%ds");
    panic("FAIL: T.T\n");
  800526:	00000617          	auipc	a2,0x0
  80052a:	15260613          	addi	a2,a2,338 # 800678 <main+0x154>
  80052e:	45a5                	li	a1,9
  800530:	00000517          	auipc	a0,0x0
  800534:	15850513          	addi	a0,a0,344 # 800688 <main+0x164>
main(void) {
  800538:	e406                	sd	ra,8(sp)
    panic("FAIL: T.T\n");
  80053a:	aedff0ef          	jal	800026 <__panic>
