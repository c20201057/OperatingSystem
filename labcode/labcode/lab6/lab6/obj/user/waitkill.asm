
obj/__user_waitkill.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <_start>:
    # move down the esp register
    # since it may cause page fault in backtrace
    // subl $0x20, %esp

    # call user-program function
    call umain
  800020:	134000ef          	jal	800154 <umain>
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
  800038:	65c50513          	addi	a0,a0,1628 # 800690 <main+0xc0>
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
  80005a:	77250513          	addi	a0,a0,1906 # 8007c8 <main+0x1f8>
  80005e:	042000ef          	jal	8000a0 <cprintf>
    va_end(ap);
    exit(-E_PANIC);
  800062:	5559                	li	a0,-10
  800064:	0d0000ef          	jal	800134 <exit>

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
  80006e:	0c0000ef          	jal	80012e <sys_putc>
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
  800094:	132000ef          	jal	8001c6 <vprintfmt>
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
  8000c8:	0fe000ef          	jal	8001c6 <vprintfmt>
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

0000000000800120 <sys_yield>:
}

int
sys_yield(void) {
    return syscall(SYS_yield);
  800120:	4529                	li	a0,10
  800122:	bf4d                	j	8000d4 <syscall>

0000000000800124 <sys_kill>:
}

int
sys_kill(int64_t pid) {
  800124:	85aa                	mv	a1,a0
    return syscall(SYS_kill, pid);
  800126:	4531                	li	a0,12
  800128:	b775                	j	8000d4 <syscall>

000000000080012a <sys_getpid>:
}

int
sys_getpid(void) {
    return syscall(SYS_getpid);
  80012a:	4549                	li	a0,18
  80012c:	b765                	j	8000d4 <syscall>

000000000080012e <sys_putc>:
}

int
sys_putc(int64_t c) {
  80012e:	85aa                	mv	a1,a0
    return syscall(SYS_putc, c);
  800130:	4579                	li	a0,30
  800132:	b74d                	j	8000d4 <syscall>

0000000000800134 <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  800134:	1141                	addi	sp,sp,-16
  800136:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  800138:	fd7ff0ef          	jal	80010e <sys_exit>
    cprintf("BUG: exit failed.\n");
  80013c:	00000517          	auipc	a0,0x0
  800140:	57450513          	addi	a0,a0,1396 # 8006b0 <main+0xe0>
  800144:	f5dff0ef          	jal	8000a0 <cprintf>
    while (1);
  800148:	a001                	j	800148 <exit+0x14>

000000000080014a <fork>:
}

int
fork(void) {
    return sys_fork();
  80014a:	b7e9                	j	800114 <sys_fork>

000000000080014c <waitpid>:
    return sys_wait(0, NULL);
}

int
waitpid(int pid, int *store) {
    return sys_wait(pid, store);
  80014c:	b7f1                	j	800118 <sys_wait>

000000000080014e <yield>:
}

void
yield(void) {
    sys_yield();
  80014e:	bfc9                	j	800120 <sys_yield>

0000000000800150 <kill>:
}

int
kill(int pid) {
    return sys_kill(pid);
  800150:	bfd1                	j	800124 <sys_kill>

0000000000800152 <getpid>:
}

int
getpid(void) {
    return sys_getpid();
  800152:	bfe1                	j	80012a <sys_getpid>

0000000000800154 <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  800154:	1141                	addi	sp,sp,-16
  800156:	e406                	sd	ra,8(sp)
    int ret = main();
  800158:	478000ef          	jal	8005d0 <main>
    exit(ret);
  80015c:	fd9ff0ef          	jal	800134 <exit>

0000000000800160 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
  800160:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  800162:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800166:	f022                	sd	s0,32(sp)
  800168:	ec26                	sd	s1,24(sp)
  80016a:	e84a                	sd	s2,16(sp)
  80016c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  80016e:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800172:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
  800174:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  800178:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
  80017c:	84aa                	mv	s1,a0
  80017e:	892e                	mv	s2,a1
    if (num >= base) {
  800180:	03067d63          	bgeu	a2,a6,8001ba <printnum+0x5a>
  800184:	e44e                	sd	s3,8(sp)
  800186:	89be                	mv	s3,a5
        while (-- width > 0)
  800188:	4785                	li	a5,1
  80018a:	00e7d763          	bge	a5,a4,800198 <printnum+0x38>
            putch(padc, putdat);
  80018e:	85ca                	mv	a1,s2
  800190:	854e                	mv	a0,s3
        while (-- width > 0)
  800192:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  800194:	9482                	jalr	s1
        while (-- width > 0)
  800196:	fc65                	bnez	s0,80018e <printnum+0x2e>
  800198:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  80019a:	00000797          	auipc	a5,0x0
  80019e:	52e78793          	addi	a5,a5,1326 # 8006c8 <main+0xf8>
  8001a2:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  8001a4:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  8001a6:	0007c503          	lbu	a0,0(a5)
}
  8001aa:	70a2                	ld	ra,40(sp)
  8001ac:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  8001ae:	85ca                	mv	a1,s2
  8001b0:	87a6                	mv	a5,s1
}
  8001b2:	6942                	ld	s2,16(sp)
  8001b4:	64e2                	ld	s1,24(sp)
  8001b6:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  8001b8:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  8001ba:	03065633          	divu	a2,a2,a6
  8001be:	8722                	mv	a4,s0
  8001c0:	fa1ff0ef          	jal	800160 <printnum>
  8001c4:	bfd9                	j	80019a <printnum+0x3a>

00000000008001c6 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  8001c6:	7119                	addi	sp,sp,-128
  8001c8:	f4a6                	sd	s1,104(sp)
  8001ca:	f0ca                	sd	s2,96(sp)
  8001cc:	ecce                	sd	s3,88(sp)
  8001ce:	e8d2                	sd	s4,80(sp)
  8001d0:	e4d6                	sd	s5,72(sp)
  8001d2:	e0da                	sd	s6,64(sp)
  8001d4:	f862                	sd	s8,48(sp)
  8001d6:	fc86                	sd	ra,120(sp)
  8001d8:	f8a2                	sd	s0,112(sp)
  8001da:	fc5e                	sd	s7,56(sp)
  8001dc:	f466                	sd	s9,40(sp)
  8001de:	f06a                	sd	s10,32(sp)
  8001e0:	ec6e                	sd	s11,24(sp)
  8001e2:	84aa                	mv	s1,a0
  8001e4:	8c32                	mv	s8,a2
  8001e6:	8a36                	mv	s4,a3
  8001e8:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001ea:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
  8001ee:	05500b13          	li	s6,85
  8001f2:	00000a97          	auipc	s5,0x0
  8001f6:	68aa8a93          	addi	s5,s5,1674 # 80087c <main+0x2ac>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001fa:	000c4503          	lbu	a0,0(s8)
  8001fe:	001c0413          	addi	s0,s8,1
  800202:	01350a63          	beq	a0,s3,800216 <vprintfmt+0x50>
            if (ch == '\0') {
  800206:	cd0d                	beqz	a0,800240 <vprintfmt+0x7a>
            putch(ch, putdat);
  800208:	85ca                	mv	a1,s2
  80020a:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  80020c:	00044503          	lbu	a0,0(s0)
  800210:	0405                	addi	s0,s0,1
  800212:	ff351ae3          	bne	a0,s3,800206 <vprintfmt+0x40>
        width = precision = -1;
  800216:	5cfd                	li	s9,-1
  800218:	8d66                	mv	s10,s9
        char padc = ' ';
  80021a:	02000d93          	li	s11,32
        lflag = altflag = 0;
  80021e:	4b81                	li	s7,0
  800220:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
  800222:	00044683          	lbu	a3,0(s0)
  800226:	00140c13          	addi	s8,s0,1
  80022a:	fdd6859b          	addiw	a1,a3,-35
  80022e:	0ff5f593          	zext.b	a1,a1
  800232:	02bb6663          	bltu	s6,a1,80025e <vprintfmt+0x98>
  800236:	058a                	slli	a1,a1,0x2
  800238:	95d6                	add	a1,a1,s5
  80023a:	4198                	lw	a4,0(a1)
  80023c:	9756                	add	a4,a4,s5
  80023e:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  800240:	70e6                	ld	ra,120(sp)
  800242:	7446                	ld	s0,112(sp)
  800244:	74a6                	ld	s1,104(sp)
  800246:	7906                	ld	s2,96(sp)
  800248:	69e6                	ld	s3,88(sp)
  80024a:	6a46                	ld	s4,80(sp)
  80024c:	6aa6                	ld	s5,72(sp)
  80024e:	6b06                	ld	s6,64(sp)
  800250:	7be2                	ld	s7,56(sp)
  800252:	7c42                	ld	s8,48(sp)
  800254:	7ca2                	ld	s9,40(sp)
  800256:	7d02                	ld	s10,32(sp)
  800258:	6de2                	ld	s11,24(sp)
  80025a:	6109                	addi	sp,sp,128
  80025c:	8082                	ret
            putch('%', putdat);
  80025e:	85ca                	mv	a1,s2
  800260:	02500513          	li	a0,37
  800264:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
  800266:	fff44783          	lbu	a5,-1(s0)
  80026a:	02500713          	li	a4,37
  80026e:	8c22                	mv	s8,s0
  800270:	f8e785e3          	beq	a5,a4,8001fa <vprintfmt+0x34>
  800274:	ffec4783          	lbu	a5,-2(s8)
  800278:	1c7d                	addi	s8,s8,-1
  80027a:	fee79de3          	bne	a5,a4,800274 <vprintfmt+0xae>
  80027e:	bfb5                	j	8001fa <vprintfmt+0x34>
                ch = *fmt;
  800280:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
  800284:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
  800286:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
  80028a:	fd06071b          	addiw	a4,a2,-48
  80028e:	24e56a63          	bltu	a0,a4,8004e2 <vprintfmt+0x31c>
                ch = *fmt;
  800292:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
  800294:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
  800296:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
  80029a:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
  80029e:	0197073b          	addw	a4,a4,s9
  8002a2:	0017171b          	slliw	a4,a4,0x1
  8002a6:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
  8002a8:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
  8002ac:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  8002ae:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
  8002b2:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
  8002b6:	feb570e3          	bgeu	a0,a1,800296 <vprintfmt+0xd0>
            if (width < 0)
  8002ba:	f60d54e3          	bgez	s10,800222 <vprintfmt+0x5c>
                width = precision, precision = -1;
  8002be:	8d66                	mv	s10,s9
  8002c0:	5cfd                	li	s9,-1
  8002c2:	b785                	j	800222 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
  8002c4:	8db6                	mv	s11,a3
  8002c6:	8462                	mv	s0,s8
  8002c8:	bfa9                	j	800222 <vprintfmt+0x5c>
  8002ca:	8462                	mv	s0,s8
            altflag = 1;
  8002cc:	4b85                	li	s7,1
            goto reswitch;
  8002ce:	bf91                	j	800222 <vprintfmt+0x5c>
    if (lflag >= 2) {
  8002d0:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002d2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002d6:	00f74463          	blt	a4,a5,8002de <vprintfmt+0x118>
    else if (lflag) {
  8002da:	1a078763          	beqz	a5,800488 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
  8002de:	000a3603          	ld	a2,0(s4)
  8002e2:	46c1                	li	a3,16
  8002e4:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  8002e6:	000d879b          	sext.w	a5,s11
  8002ea:	876a                	mv	a4,s10
  8002ec:	85ca                	mv	a1,s2
  8002ee:	8526                	mv	a0,s1
  8002f0:	e71ff0ef          	jal	800160 <printnum>
            break;
  8002f4:	b719                	j	8001fa <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
  8002f6:	000a2503          	lw	a0,0(s4)
  8002fa:	85ca                	mv	a1,s2
  8002fc:	0a21                	addi	s4,s4,8
  8002fe:	9482                	jalr	s1
            break;
  800300:	bded                	j	8001fa <vprintfmt+0x34>
    if (lflag >= 2) {
  800302:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800304:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800308:	00f74463          	blt	a4,a5,800310 <vprintfmt+0x14a>
    else if (lflag) {
  80030c:	16078963          	beqz	a5,80047e <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
  800310:	000a3603          	ld	a2,0(s4)
  800314:	46a9                	li	a3,10
  800316:	8a2e                	mv	s4,a1
  800318:	b7f9                	j	8002e6 <vprintfmt+0x120>
            putch('0', putdat);
  80031a:	85ca                	mv	a1,s2
  80031c:	03000513          	li	a0,48
  800320:	9482                	jalr	s1
            putch('x', putdat);
  800322:	85ca                	mv	a1,s2
  800324:	07800513          	li	a0,120
  800328:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  80032a:	000a3603          	ld	a2,0(s4)
            goto number;
  80032e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  800330:	0a21                	addi	s4,s4,8
            goto number;
  800332:	bf55                	j	8002e6 <vprintfmt+0x120>
            putch(ch, putdat);
  800334:	85ca                	mv	a1,s2
  800336:	02500513          	li	a0,37
  80033a:	9482                	jalr	s1
            break;
  80033c:	bd7d                	j	8001fa <vprintfmt+0x34>
            precision = va_arg(ap, int);
  80033e:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  800342:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
  800344:	0a21                	addi	s4,s4,8
            goto process_precision;
  800346:	bf95                	j	8002ba <vprintfmt+0xf4>
    if (lflag >= 2) {
  800348:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80034a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  80034e:	00f74463          	blt	a4,a5,800356 <vprintfmt+0x190>
    else if (lflag) {
  800352:	12078163          	beqz	a5,800474 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
  800356:	000a3603          	ld	a2,0(s4)
  80035a:	46a1                	li	a3,8
  80035c:	8a2e                	mv	s4,a1
  80035e:	b761                	j	8002e6 <vprintfmt+0x120>
            if (width < 0)
  800360:	876a                	mv	a4,s10
  800362:	000d5363          	bgez	s10,800368 <vprintfmt+0x1a2>
  800366:	4701                	li	a4,0
  800368:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
  80036c:	8462                	mv	s0,s8
            goto reswitch;
  80036e:	bd55                	j	800222 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
  800370:	000d841b          	sext.w	s0,s11
  800374:	fd340793          	addi	a5,s0,-45
  800378:	00f037b3          	snez	a5,a5
  80037c:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
  800380:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
  800384:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
  800386:	008a0793          	addi	a5,s4,8
  80038a:	e43e                	sd	a5,8(sp)
  80038c:	100d8c63          	beqz	s11,8004a4 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
  800390:	12071363          	bnez	a4,8004b6 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800394:	000dc783          	lbu	a5,0(s11)
  800398:	0007851b          	sext.w	a0,a5
  80039c:	c78d                	beqz	a5,8003c6 <vprintfmt+0x200>
  80039e:	0d85                	addi	s11,s11,1
  8003a0:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
  8003a2:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003a6:	000cc563          	bltz	s9,8003b0 <vprintfmt+0x1ea>
  8003aa:	3cfd                	addiw	s9,s9,-1
  8003ac:	008c8d63          	beq	s9,s0,8003c6 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
  8003b0:	020b9663          	bnez	s7,8003dc <vprintfmt+0x216>
                    putch(ch, putdat);
  8003b4:	85ca                	mv	a1,s2
  8003b6:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003b8:	000dc783          	lbu	a5,0(s11)
  8003bc:	0d85                	addi	s11,s11,1
  8003be:	3d7d                	addiw	s10,s10,-1
  8003c0:	0007851b          	sext.w	a0,a5
  8003c4:	f3ed                	bnez	a5,8003a6 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
  8003c6:	01a05963          	blez	s10,8003d8 <vprintfmt+0x212>
                putch(' ', putdat);
  8003ca:	85ca                	mv	a1,s2
  8003cc:	02000513          	li	a0,32
            for (; width > 0; width --) {
  8003d0:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
  8003d2:	9482                	jalr	s1
            for (; width > 0; width --) {
  8003d4:	fe0d1be3          	bnez	s10,8003ca <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
  8003d8:	6a22                	ld	s4,8(sp)
  8003da:	b505                	j	8001fa <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
  8003dc:	3781                	addiw	a5,a5,-32
  8003de:	fcfa7be3          	bgeu	s4,a5,8003b4 <vprintfmt+0x1ee>
                    putch('?', putdat);
  8003e2:	03f00513          	li	a0,63
  8003e6:	85ca                	mv	a1,s2
  8003e8:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003ea:	000dc783          	lbu	a5,0(s11)
  8003ee:	0d85                	addi	s11,s11,1
  8003f0:	3d7d                	addiw	s10,s10,-1
  8003f2:	0007851b          	sext.w	a0,a5
  8003f6:	dbe1                	beqz	a5,8003c6 <vprintfmt+0x200>
  8003f8:	fa0cd9e3          	bgez	s9,8003aa <vprintfmt+0x1e4>
  8003fc:	b7c5                	j	8003dc <vprintfmt+0x216>
            if (err < 0) {
  8003fe:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  800402:	4661                	li	a2,24
            err = va_arg(ap, int);
  800404:	0a21                	addi	s4,s4,8
            if (err < 0) {
  800406:	41f7d71b          	sraiw	a4,a5,0x1f
  80040a:	8fb9                	xor	a5,a5,a4
  80040c:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  800410:	02d64563          	blt	a2,a3,80043a <vprintfmt+0x274>
  800414:	00000797          	auipc	a5,0x0
  800418:	5c478793          	addi	a5,a5,1476 # 8009d8 <error_string>
  80041c:	00369713          	slli	a4,a3,0x3
  800420:	97ba                	add	a5,a5,a4
  800422:	639c                	ld	a5,0(a5)
  800424:	cb99                	beqz	a5,80043a <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
  800426:	86be                	mv	a3,a5
  800428:	00000617          	auipc	a2,0x0
  80042c:	2d060613          	addi	a2,a2,720 # 8006f8 <main+0x128>
  800430:	85ca                	mv	a1,s2
  800432:	8526                	mv	a0,s1
  800434:	0d8000ef          	jal	80050c <printfmt>
  800438:	b3c9                	j	8001fa <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
  80043a:	00000617          	auipc	a2,0x0
  80043e:	2ae60613          	addi	a2,a2,686 # 8006e8 <main+0x118>
  800442:	85ca                	mv	a1,s2
  800444:	8526                	mv	a0,s1
  800446:	0c6000ef          	jal	80050c <printfmt>
  80044a:	bb45                	j	8001fa <vprintfmt+0x34>
    if (lflag >= 2) {
  80044c:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80044e:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
  800452:	00f74363          	blt	a4,a5,800458 <vprintfmt+0x292>
    else if (lflag) {
  800456:	cf81                	beqz	a5,80046e <vprintfmt+0x2a8>
        return va_arg(*ap, long);
  800458:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  80045c:	02044b63          	bltz	s0,800492 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
  800460:	8622                	mv	a2,s0
  800462:	8a5e                	mv	s4,s7
  800464:	46a9                	li	a3,10
  800466:	b541                	j	8002e6 <vprintfmt+0x120>
            lflag ++;
  800468:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
  80046a:	8462                	mv	s0,s8
            goto reswitch;
  80046c:	bb5d                	j	800222 <vprintfmt+0x5c>
        return va_arg(*ap, int);
  80046e:	000a2403          	lw	s0,0(s4)
  800472:	b7ed                	j	80045c <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
  800474:	000a6603          	lwu	a2,0(s4)
  800478:	46a1                	li	a3,8
  80047a:	8a2e                	mv	s4,a1
  80047c:	b5ad                	j	8002e6 <vprintfmt+0x120>
  80047e:	000a6603          	lwu	a2,0(s4)
  800482:	46a9                	li	a3,10
  800484:	8a2e                	mv	s4,a1
  800486:	b585                	j	8002e6 <vprintfmt+0x120>
  800488:	000a6603          	lwu	a2,0(s4)
  80048c:	46c1                	li	a3,16
  80048e:	8a2e                	mv	s4,a1
  800490:	bd99                	j	8002e6 <vprintfmt+0x120>
                putch('-', putdat);
  800492:	85ca                	mv	a1,s2
  800494:	02d00513          	li	a0,45
  800498:	9482                	jalr	s1
                num = -(long long)num;
  80049a:	40800633          	neg	a2,s0
  80049e:	8a5e                	mv	s4,s7
  8004a0:	46a9                	li	a3,10
  8004a2:	b591                	j	8002e6 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
  8004a4:	e329                	bnez	a4,8004e6 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004a6:	02800793          	li	a5,40
  8004aa:	853e                	mv	a0,a5
  8004ac:	00000d97          	auipc	s11,0x0
  8004b0:	235d8d93          	addi	s11,s11,565 # 8006e1 <main+0x111>
  8004b4:	b5f5                	j	8003a0 <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004b6:	85e6                	mv	a1,s9
  8004b8:	856e                	mv	a0,s11
  8004ba:	072000ef          	jal	80052c <strnlen>
  8004be:	40ad0d3b          	subw	s10,s10,a0
  8004c2:	01a05863          	blez	s10,8004d2 <vprintfmt+0x30c>
                    putch(padc, putdat);
  8004c6:	85ca                	mv	a1,s2
  8004c8:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004ca:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
  8004cc:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004ce:	fe0d1ce3          	bnez	s10,8004c6 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004d2:	000dc783          	lbu	a5,0(s11)
  8004d6:	0007851b          	sext.w	a0,a5
  8004da:	ec0792e3          	bnez	a5,80039e <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
  8004de:	6a22                	ld	s4,8(sp)
  8004e0:	bb29                	j	8001fa <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
  8004e2:	8462                	mv	s0,s8
  8004e4:	bbd9                	j	8002ba <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004e6:	85e6                	mv	a1,s9
  8004e8:	00000517          	auipc	a0,0x0
  8004ec:	1f850513          	addi	a0,a0,504 # 8006e0 <main+0x110>
  8004f0:	03c000ef          	jal	80052c <strnlen>
  8004f4:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004f8:	02800793          	li	a5,40
                p = "(null)";
  8004fc:	00000d97          	auipc	s11,0x0
  800500:	1e4d8d93          	addi	s11,s11,484 # 8006e0 <main+0x110>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800504:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  800506:	fda040e3          	bgtz	s10,8004c6 <vprintfmt+0x300>
  80050a:	bd51                	j	80039e <vprintfmt+0x1d8>

000000000080050c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  80050c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  80050e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800512:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  800514:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800516:	ec06                	sd	ra,24(sp)
  800518:	f83a                	sd	a4,48(sp)
  80051a:	fc3e                	sd	a5,56(sp)
  80051c:	e0c2                	sd	a6,64(sp)
  80051e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  800520:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  800522:	ca5ff0ef          	jal	8001c6 <vprintfmt>
}
  800526:	60e2                	ld	ra,24(sp)
  800528:	6161                	addi	sp,sp,80
  80052a:	8082                	ret

000000000080052c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  80052c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  80052e:	e589                	bnez	a1,800538 <strnlen+0xc>
  800530:	a811                	j	800544 <strnlen+0x18>
        cnt ++;
  800532:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  800534:	00f58863          	beq	a1,a5,800544 <strnlen+0x18>
  800538:	00f50733          	add	a4,a0,a5
  80053c:	00074703          	lbu	a4,0(a4)
  800540:	fb6d                	bnez	a4,800532 <strnlen+0x6>
  800542:	85be                	mv	a1,a5
    }
    return cnt;
}
  800544:	852e                	mv	a0,a1
  800546:	8082                	ret

0000000000800548 <do_yield>:
#include <ulib.h>
#include <stdio.h>

void
do_yield(void) {
  800548:	1141                	addi	sp,sp,-16
  80054a:	e406                	sd	ra,8(sp)
    yield();
  80054c:	c03ff0ef          	jal	80014e <yield>
    yield();
  800550:	bffff0ef          	jal	80014e <yield>
    yield();
  800554:	bfbff0ef          	jal	80014e <yield>
    yield();
  800558:	bf7ff0ef          	jal	80014e <yield>
    yield();
  80055c:	bf3ff0ef          	jal	80014e <yield>
    yield();
}
  800560:	60a2                	ld	ra,8(sp)
  800562:	0141                	addi	sp,sp,16
    yield();
  800564:	b6ed                	j	80014e <yield>

0000000000800566 <loop>:

int parent, pid1, pid2;

void
loop(void) {
  800566:	1141                	addi	sp,sp,-16
    cprintf("child 1.\n");
  800568:	00000517          	auipc	a0,0x0
  80056c:	25850513          	addi	a0,a0,600 # 8007c0 <main+0x1f0>
loop(void) {
  800570:	e406                	sd	ra,8(sp)
    cprintf("child 1.\n");
  800572:	b2fff0ef          	jal	8000a0 <cprintf>
    while (1);
  800576:	a001                	j	800576 <loop+0x10>

0000000000800578 <work>:
}

void
work(void) {
  800578:	1141                	addi	sp,sp,-16
    cprintf("child 2.\n");
  80057a:	00000517          	auipc	a0,0x0
  80057e:	25650513          	addi	a0,a0,598 # 8007d0 <main+0x200>
work(void) {
  800582:	e406                	sd	ra,8(sp)
    cprintf("child 2.\n");
  800584:	b1dff0ef          	jal	8000a0 <cprintf>
    do_yield();
  800588:	fc1ff0ef          	jal	800548 <do_yield>
    if (kill(parent) == 0) {
  80058c:	00001517          	auipc	a0,0x1
  800590:	a7c52503          	lw	a0,-1412(a0) # 801008 <parent>
  800594:	bbdff0ef          	jal	800150 <kill>
  800598:	e105                	bnez	a0,8005b8 <work+0x40>
        cprintf("kill parent ok.\n");
  80059a:	00000517          	auipc	a0,0x0
  80059e:	24650513          	addi	a0,a0,582 # 8007e0 <main+0x210>
  8005a2:	affff0ef          	jal	8000a0 <cprintf>
        do_yield();
  8005a6:	fa3ff0ef          	jal	800548 <do_yield>
        if (kill(pid1) == 0) {
  8005aa:	00001517          	auipc	a0,0x1
  8005ae:	a5a52503          	lw	a0,-1446(a0) # 801004 <pid1>
  8005b2:	b9fff0ef          	jal	800150 <kill>
  8005b6:	c501                	beqz	a0,8005be <work+0x46>
            cprintf("kill child1 ok.\n");
            exit(0);
        }
    }
    exit(-1);
  8005b8:	557d                	li	a0,-1
  8005ba:	b7bff0ef          	jal	800134 <exit>
            cprintf("kill child1 ok.\n");
  8005be:	00000517          	auipc	a0,0x0
  8005c2:	23a50513          	addi	a0,a0,570 # 8007f8 <main+0x228>
  8005c6:	adbff0ef          	jal	8000a0 <cprintf>
            exit(0);
  8005ca:	4501                	li	a0,0
  8005cc:	b69ff0ef          	jal	800134 <exit>

00000000008005d0 <main>:
}

int
main(void) {
  8005d0:	1141                	addi	sp,sp,-16
  8005d2:	e406                	sd	ra,8(sp)
    parent = getpid();
  8005d4:	b7fff0ef          	jal	800152 <getpid>
  8005d8:	00001797          	auipc	a5,0x1
  8005dc:	a2a7a823          	sw	a0,-1488(a5) # 801008 <parent>
    if ((pid1 = fork()) == 0) {
  8005e0:	b6bff0ef          	jal	80014a <fork>
  8005e4:	00001797          	auipc	a5,0x1
  8005e8:	a2a7a023          	sw	a0,-1504(a5) # 801004 <pid1>
  8005ec:	c92d                	beqz	a0,80065e <main+0x8e>
        loop();
    }

    assert(pid1 > 0);
  8005ee:	04a05863          	blez	a0,80063e <main+0x6e>

    if ((pid2 = fork()) == 0) {
  8005f2:	b59ff0ef          	jal	80014a <fork>
  8005f6:	00001797          	auipc	a5,0x1
  8005fa:	a0a7a523          	sw	a0,-1526(a5) # 801000 <pid2>
  8005fe:	c541                	beqz	a0,800686 <main+0xb6>
        work();
    }
    if (pid2 > 0) {
  800600:	06a05163          	blez	a0,800662 <main+0x92>
        cprintf("wait child 1.\n");
  800604:	00000517          	auipc	a0,0x0
  800608:	24450513          	addi	a0,a0,580 # 800848 <main+0x278>
  80060c:	a95ff0ef          	jal	8000a0 <cprintf>
        waitpid(pid1, NULL);
  800610:	00001517          	auipc	a0,0x1
  800614:	9f452503          	lw	a0,-1548(a0) # 801004 <pid1>
  800618:	4581                	li	a1,0
  80061a:	b33ff0ef          	jal	80014c <waitpid>
        panic("waitpid %d returns\n", pid1);
  80061e:	00001697          	auipc	a3,0x1
  800622:	9e66a683          	lw	a3,-1562(a3) # 801004 <pid1>
  800626:	00000617          	auipc	a2,0x0
  80062a:	23260613          	addi	a2,a2,562 # 800858 <main+0x288>
  80062e:	03400593          	li	a1,52
  800632:	00000517          	auipc	a0,0x0
  800636:	20650513          	addi	a0,a0,518 # 800838 <main+0x268>
  80063a:	9edff0ef          	jal	800026 <__panic>
    assert(pid1 > 0);
  80063e:	00000697          	auipc	a3,0x0
  800642:	1d268693          	addi	a3,a3,466 # 800810 <main+0x240>
  800646:	00000617          	auipc	a2,0x0
  80064a:	1da60613          	addi	a2,a2,474 # 800820 <main+0x250>
  80064e:	02c00593          	li	a1,44
  800652:	00000517          	auipc	a0,0x0
  800656:	1e650513          	addi	a0,a0,486 # 800838 <main+0x268>
  80065a:	9cdff0ef          	jal	800026 <__panic>
        loop();
  80065e:	f09ff0ef          	jal	800566 <loop>
    }
    else {
        kill(pid1);
  800662:	00001517          	auipc	a0,0x1
  800666:	9a252503          	lw	a0,-1630(a0) # 801004 <pid1>
  80066a:	ae7ff0ef          	jal	800150 <kill>
    }
    panic("FAIL: T.T\n");
  80066e:	00000617          	auipc	a2,0x0
  800672:	20260613          	addi	a2,a2,514 # 800870 <main+0x2a0>
  800676:	03900593          	li	a1,57
  80067a:	00000517          	auipc	a0,0x0
  80067e:	1be50513          	addi	a0,a0,446 # 800838 <main+0x268>
  800682:	9a5ff0ef          	jal	800026 <__panic>
        work();
  800686:	ef3ff0ef          	jal	800578 <work>
