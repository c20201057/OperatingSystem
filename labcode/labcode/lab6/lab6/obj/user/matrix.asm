
obj/__user_matrix.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <_start>:
    # move down the esp register
    # since it may cause page fault in backtrace
    // subl $0x20, %esp

    # call user-program function
    call umain
  800020:	138000ef          	jal	800158 <umain>
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
  800038:	77450513          	addi	a0,a0,1908 # 8007a8 <main+0xca>
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
  80005a:	77250513          	addi	a0,a0,1906 # 8007c8 <main+0xea>
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
  800094:	136000ef          	jal	8001ca <vprintfmt>
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
  8000c8:	102000ef          	jal	8001ca <vprintfmt>
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
  800140:	69450513          	addi	a0,a0,1684 # 8007d0 <main+0xf2>
  800144:	f5dff0ef          	jal	8000a0 <cprintf>
    while (1);
  800148:	a001                	j	800148 <exit+0x14>

000000000080014a <fork>:
}

int
fork(void) {
    return sys_fork();
  80014a:	b7e9                	j	800114 <sys_fork>

000000000080014c <wait>:
}

int
wait(void) {
    return sys_wait(0, NULL);
  80014c:	4581                	li	a1,0
  80014e:	4501                	li	a0,0
  800150:	b7e1                	j	800118 <sys_wait>

0000000000800152 <yield>:
    return sys_wait(pid, store);
}

void
yield(void) {
    sys_yield();
  800152:	b7f9                	j	800120 <sys_yield>

0000000000800154 <kill>:
}

int
kill(int pid) {
    return sys_kill(pid);
  800154:	bfc1                	j	800124 <sys_kill>

0000000000800156 <getpid>:
}

int
getpid(void) {
    return sys_getpid();
  800156:	bfd1                	j	80012a <sys_getpid>

0000000000800158 <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  800158:	1141                	addi	sp,sp,-16
  80015a:	e406                	sd	ra,8(sp)
    int ret = main();
  80015c:	582000ef          	jal	8006de <main>
    exit(ret);
  800160:	fd5ff0ef          	jal	800134 <exit>

0000000000800164 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
  800164:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  800166:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  80016a:	f022                	sd	s0,32(sp)
  80016c:	ec26                	sd	s1,24(sp)
  80016e:	e84a                	sd	s2,16(sp)
  800170:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  800172:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800176:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
  800178:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  80017c:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
  800180:	84aa                	mv	s1,a0
  800182:	892e                	mv	s2,a1
    if (num >= base) {
  800184:	03067d63          	bgeu	a2,a6,8001be <printnum+0x5a>
  800188:	e44e                	sd	s3,8(sp)
  80018a:	89be                	mv	s3,a5
        while (-- width > 0)
  80018c:	4785                	li	a5,1
  80018e:	00e7d763          	bge	a5,a4,80019c <printnum+0x38>
            putch(padc, putdat);
  800192:	85ca                	mv	a1,s2
  800194:	854e                	mv	a0,s3
        while (-- width > 0)
  800196:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  800198:	9482                	jalr	s1
        while (-- width > 0)
  80019a:	fc65                	bnez	s0,800192 <printnum+0x2e>
  80019c:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  80019e:	00000797          	auipc	a5,0x0
  8001a2:	64a78793          	addi	a5,a5,1610 # 8007e8 <main+0x10a>
  8001a6:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  8001a8:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  8001aa:	0007c503          	lbu	a0,0(a5)
}
  8001ae:	70a2                	ld	ra,40(sp)
  8001b0:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  8001b2:	85ca                	mv	a1,s2
  8001b4:	87a6                	mv	a5,s1
}
  8001b6:	6942                	ld	s2,16(sp)
  8001b8:	64e2                	ld	s1,24(sp)
  8001ba:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  8001bc:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  8001be:	03065633          	divu	a2,a2,a6
  8001c2:	8722                	mv	a4,s0
  8001c4:	fa1ff0ef          	jal	800164 <printnum>
  8001c8:	bfd9                	j	80019e <printnum+0x3a>

00000000008001ca <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  8001ca:	7119                	addi	sp,sp,-128
  8001cc:	f4a6                	sd	s1,104(sp)
  8001ce:	f0ca                	sd	s2,96(sp)
  8001d0:	ecce                	sd	s3,88(sp)
  8001d2:	e8d2                	sd	s4,80(sp)
  8001d4:	e4d6                	sd	s5,72(sp)
  8001d6:	e0da                	sd	s6,64(sp)
  8001d8:	f862                	sd	s8,48(sp)
  8001da:	fc86                	sd	ra,120(sp)
  8001dc:	f8a2                	sd	s0,112(sp)
  8001de:	fc5e                	sd	s7,56(sp)
  8001e0:	f466                	sd	s9,40(sp)
  8001e2:	f06a                	sd	s10,32(sp)
  8001e4:	ec6e                	sd	s11,24(sp)
  8001e6:	84aa                	mv	s1,a0
  8001e8:	8c32                	mv	s8,a2
  8001ea:	8a36                	mv	s4,a3
  8001ec:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001ee:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
  8001f2:	05500b13          	li	s6,85
  8001f6:	00000a97          	auipc	s5,0x0
  8001fa:	76aa8a93          	addi	s5,s5,1898 # 800960 <main+0x282>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001fe:	000c4503          	lbu	a0,0(s8)
  800202:	001c0413          	addi	s0,s8,1
  800206:	01350a63          	beq	a0,s3,80021a <vprintfmt+0x50>
            if (ch == '\0') {
  80020a:	cd0d                	beqz	a0,800244 <vprintfmt+0x7a>
            putch(ch, putdat);
  80020c:	85ca                	mv	a1,s2
  80020e:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  800210:	00044503          	lbu	a0,0(s0)
  800214:	0405                	addi	s0,s0,1
  800216:	ff351ae3          	bne	a0,s3,80020a <vprintfmt+0x40>
        width = precision = -1;
  80021a:	5cfd                	li	s9,-1
  80021c:	8d66                	mv	s10,s9
        char padc = ' ';
  80021e:	02000d93          	li	s11,32
        lflag = altflag = 0;
  800222:	4b81                	li	s7,0
  800224:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
  800226:	00044683          	lbu	a3,0(s0)
  80022a:	00140c13          	addi	s8,s0,1
  80022e:	fdd6859b          	addiw	a1,a3,-35
  800232:	0ff5f593          	zext.b	a1,a1
  800236:	02bb6663          	bltu	s6,a1,800262 <vprintfmt+0x98>
  80023a:	058a                	slli	a1,a1,0x2
  80023c:	95d6                	add	a1,a1,s5
  80023e:	4198                	lw	a4,0(a1)
  800240:	9756                	add	a4,a4,s5
  800242:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  800244:	70e6                	ld	ra,120(sp)
  800246:	7446                	ld	s0,112(sp)
  800248:	74a6                	ld	s1,104(sp)
  80024a:	7906                	ld	s2,96(sp)
  80024c:	69e6                	ld	s3,88(sp)
  80024e:	6a46                	ld	s4,80(sp)
  800250:	6aa6                	ld	s5,72(sp)
  800252:	6b06                	ld	s6,64(sp)
  800254:	7be2                	ld	s7,56(sp)
  800256:	7c42                	ld	s8,48(sp)
  800258:	7ca2                	ld	s9,40(sp)
  80025a:	7d02                	ld	s10,32(sp)
  80025c:	6de2                	ld	s11,24(sp)
  80025e:	6109                	addi	sp,sp,128
  800260:	8082                	ret
            putch('%', putdat);
  800262:	85ca                	mv	a1,s2
  800264:	02500513          	li	a0,37
  800268:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
  80026a:	fff44783          	lbu	a5,-1(s0)
  80026e:	02500713          	li	a4,37
  800272:	8c22                	mv	s8,s0
  800274:	f8e785e3          	beq	a5,a4,8001fe <vprintfmt+0x34>
  800278:	ffec4783          	lbu	a5,-2(s8)
  80027c:	1c7d                	addi	s8,s8,-1
  80027e:	fee79de3          	bne	a5,a4,800278 <vprintfmt+0xae>
  800282:	bfb5                	j	8001fe <vprintfmt+0x34>
                ch = *fmt;
  800284:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
  800288:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
  80028a:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
  80028e:	fd06071b          	addiw	a4,a2,-48
  800292:	24e56a63          	bltu	a0,a4,8004e6 <vprintfmt+0x31c>
                ch = *fmt;
  800296:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
  800298:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
  80029a:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
  80029e:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
  8002a2:	0197073b          	addw	a4,a4,s9
  8002a6:	0017171b          	slliw	a4,a4,0x1
  8002aa:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
  8002ac:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
  8002b0:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  8002b2:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
  8002b6:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
  8002ba:	feb570e3          	bgeu	a0,a1,80029a <vprintfmt+0xd0>
            if (width < 0)
  8002be:	f60d54e3          	bgez	s10,800226 <vprintfmt+0x5c>
                width = precision, precision = -1;
  8002c2:	8d66                	mv	s10,s9
  8002c4:	5cfd                	li	s9,-1
  8002c6:	b785                	j	800226 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
  8002c8:	8db6                	mv	s11,a3
  8002ca:	8462                	mv	s0,s8
  8002cc:	bfa9                	j	800226 <vprintfmt+0x5c>
  8002ce:	8462                	mv	s0,s8
            altflag = 1;
  8002d0:	4b85                	li	s7,1
            goto reswitch;
  8002d2:	bf91                	j	800226 <vprintfmt+0x5c>
    if (lflag >= 2) {
  8002d4:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002d6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002da:	00f74463          	blt	a4,a5,8002e2 <vprintfmt+0x118>
    else if (lflag) {
  8002de:	1a078763          	beqz	a5,80048c <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
  8002e2:	000a3603          	ld	a2,0(s4)
  8002e6:	46c1                	li	a3,16
  8002e8:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  8002ea:	000d879b          	sext.w	a5,s11
  8002ee:	876a                	mv	a4,s10
  8002f0:	85ca                	mv	a1,s2
  8002f2:	8526                	mv	a0,s1
  8002f4:	e71ff0ef          	jal	800164 <printnum>
            break;
  8002f8:	b719                	j	8001fe <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
  8002fa:	000a2503          	lw	a0,0(s4)
  8002fe:	85ca                	mv	a1,s2
  800300:	0a21                	addi	s4,s4,8
  800302:	9482                	jalr	s1
            break;
  800304:	bded                	j	8001fe <vprintfmt+0x34>
    if (lflag >= 2) {
  800306:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800308:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  80030c:	00f74463          	blt	a4,a5,800314 <vprintfmt+0x14a>
    else if (lflag) {
  800310:	16078963          	beqz	a5,800482 <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
  800314:	000a3603          	ld	a2,0(s4)
  800318:	46a9                	li	a3,10
  80031a:	8a2e                	mv	s4,a1
  80031c:	b7f9                	j	8002ea <vprintfmt+0x120>
            putch('0', putdat);
  80031e:	85ca                	mv	a1,s2
  800320:	03000513          	li	a0,48
  800324:	9482                	jalr	s1
            putch('x', putdat);
  800326:	85ca                	mv	a1,s2
  800328:	07800513          	li	a0,120
  80032c:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  80032e:	000a3603          	ld	a2,0(s4)
            goto number;
  800332:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  800334:	0a21                	addi	s4,s4,8
            goto number;
  800336:	bf55                	j	8002ea <vprintfmt+0x120>
            putch(ch, putdat);
  800338:	85ca                	mv	a1,s2
  80033a:	02500513          	li	a0,37
  80033e:	9482                	jalr	s1
            break;
  800340:	bd7d                	j	8001fe <vprintfmt+0x34>
            precision = va_arg(ap, int);
  800342:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  800346:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
  800348:	0a21                	addi	s4,s4,8
            goto process_precision;
  80034a:	bf95                	j	8002be <vprintfmt+0xf4>
    if (lflag >= 2) {
  80034c:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80034e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800352:	00f74463          	blt	a4,a5,80035a <vprintfmt+0x190>
    else if (lflag) {
  800356:	12078163          	beqz	a5,800478 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
  80035a:	000a3603          	ld	a2,0(s4)
  80035e:	46a1                	li	a3,8
  800360:	8a2e                	mv	s4,a1
  800362:	b761                	j	8002ea <vprintfmt+0x120>
            if (width < 0)
  800364:	876a                	mv	a4,s10
  800366:	000d5363          	bgez	s10,80036c <vprintfmt+0x1a2>
  80036a:	4701                	li	a4,0
  80036c:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
  800370:	8462                	mv	s0,s8
            goto reswitch;
  800372:	bd55                	j	800226 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
  800374:	000d841b          	sext.w	s0,s11
  800378:	fd340793          	addi	a5,s0,-45
  80037c:	00f037b3          	snez	a5,a5
  800380:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
  800384:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
  800388:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
  80038a:	008a0793          	addi	a5,s4,8
  80038e:	e43e                	sd	a5,8(sp)
  800390:	100d8c63          	beqz	s11,8004a8 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
  800394:	12071363          	bnez	a4,8004ba <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800398:	000dc783          	lbu	a5,0(s11)
  80039c:	0007851b          	sext.w	a0,a5
  8003a0:	c78d                	beqz	a5,8003ca <vprintfmt+0x200>
  8003a2:	0d85                	addi	s11,s11,1
  8003a4:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
  8003a6:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003aa:	000cc563          	bltz	s9,8003b4 <vprintfmt+0x1ea>
  8003ae:	3cfd                	addiw	s9,s9,-1
  8003b0:	008c8d63          	beq	s9,s0,8003ca <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
  8003b4:	020b9663          	bnez	s7,8003e0 <vprintfmt+0x216>
                    putch(ch, putdat);
  8003b8:	85ca                	mv	a1,s2
  8003ba:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003bc:	000dc783          	lbu	a5,0(s11)
  8003c0:	0d85                	addi	s11,s11,1
  8003c2:	3d7d                	addiw	s10,s10,-1
  8003c4:	0007851b          	sext.w	a0,a5
  8003c8:	f3ed                	bnez	a5,8003aa <vprintfmt+0x1e0>
            for (; width > 0; width --) {
  8003ca:	01a05963          	blez	s10,8003dc <vprintfmt+0x212>
                putch(' ', putdat);
  8003ce:	85ca                	mv	a1,s2
  8003d0:	02000513          	li	a0,32
            for (; width > 0; width --) {
  8003d4:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
  8003d6:	9482                	jalr	s1
            for (; width > 0; width --) {
  8003d8:	fe0d1be3          	bnez	s10,8003ce <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
  8003dc:	6a22                	ld	s4,8(sp)
  8003de:	b505                	j	8001fe <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
  8003e0:	3781                	addiw	a5,a5,-32
  8003e2:	fcfa7be3          	bgeu	s4,a5,8003b8 <vprintfmt+0x1ee>
                    putch('?', putdat);
  8003e6:	03f00513          	li	a0,63
  8003ea:	85ca                	mv	a1,s2
  8003ec:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003ee:	000dc783          	lbu	a5,0(s11)
  8003f2:	0d85                	addi	s11,s11,1
  8003f4:	3d7d                	addiw	s10,s10,-1
  8003f6:	0007851b          	sext.w	a0,a5
  8003fa:	dbe1                	beqz	a5,8003ca <vprintfmt+0x200>
  8003fc:	fa0cd9e3          	bgez	s9,8003ae <vprintfmt+0x1e4>
  800400:	b7c5                	j	8003e0 <vprintfmt+0x216>
            if (err < 0) {
  800402:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  800406:	4661                	li	a2,24
            err = va_arg(ap, int);
  800408:	0a21                	addi	s4,s4,8
            if (err < 0) {
  80040a:	41f7d71b          	sraiw	a4,a5,0x1f
  80040e:	8fb9                	xor	a5,a5,a4
  800410:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  800414:	02d64563          	blt	a2,a3,80043e <vprintfmt+0x274>
  800418:	00000797          	auipc	a5,0x0
  80041c:	6a078793          	addi	a5,a5,1696 # 800ab8 <error_string>
  800420:	00369713          	slli	a4,a3,0x3
  800424:	97ba                	add	a5,a5,a4
  800426:	639c                	ld	a5,0(a5)
  800428:	cb99                	beqz	a5,80043e <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
  80042a:	86be                	mv	a3,a5
  80042c:	00000617          	auipc	a2,0x0
  800430:	3ec60613          	addi	a2,a2,1004 # 800818 <main+0x13a>
  800434:	85ca                	mv	a1,s2
  800436:	8526                	mv	a0,s1
  800438:	0d8000ef          	jal	800510 <printfmt>
  80043c:	b3c9                	j	8001fe <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
  80043e:	00000617          	auipc	a2,0x0
  800442:	3ca60613          	addi	a2,a2,970 # 800808 <main+0x12a>
  800446:	85ca                	mv	a1,s2
  800448:	8526                	mv	a0,s1
  80044a:	0c6000ef          	jal	800510 <printfmt>
  80044e:	bb45                	j	8001fe <vprintfmt+0x34>
    if (lflag >= 2) {
  800450:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800452:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
  800456:	00f74363          	blt	a4,a5,80045c <vprintfmt+0x292>
    else if (lflag) {
  80045a:	cf81                	beqz	a5,800472 <vprintfmt+0x2a8>
        return va_arg(*ap, long);
  80045c:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  800460:	02044b63          	bltz	s0,800496 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
  800464:	8622                	mv	a2,s0
  800466:	8a5e                	mv	s4,s7
  800468:	46a9                	li	a3,10
  80046a:	b541                	j	8002ea <vprintfmt+0x120>
            lflag ++;
  80046c:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
  80046e:	8462                	mv	s0,s8
            goto reswitch;
  800470:	bb5d                	j	800226 <vprintfmt+0x5c>
        return va_arg(*ap, int);
  800472:	000a2403          	lw	s0,0(s4)
  800476:	b7ed                	j	800460 <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
  800478:	000a6603          	lwu	a2,0(s4)
  80047c:	46a1                	li	a3,8
  80047e:	8a2e                	mv	s4,a1
  800480:	b5ad                	j	8002ea <vprintfmt+0x120>
  800482:	000a6603          	lwu	a2,0(s4)
  800486:	46a9                	li	a3,10
  800488:	8a2e                	mv	s4,a1
  80048a:	b585                	j	8002ea <vprintfmt+0x120>
  80048c:	000a6603          	lwu	a2,0(s4)
  800490:	46c1                	li	a3,16
  800492:	8a2e                	mv	s4,a1
  800494:	bd99                	j	8002ea <vprintfmt+0x120>
                putch('-', putdat);
  800496:	85ca                	mv	a1,s2
  800498:	02d00513          	li	a0,45
  80049c:	9482                	jalr	s1
                num = -(long long)num;
  80049e:	40800633          	neg	a2,s0
  8004a2:	8a5e                	mv	s4,s7
  8004a4:	46a9                	li	a3,10
  8004a6:	b591                	j	8002ea <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
  8004a8:	e329                	bnez	a4,8004ea <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004aa:	02800793          	li	a5,40
  8004ae:	853e                	mv	a0,a5
  8004b0:	00000d97          	auipc	s11,0x0
  8004b4:	351d8d93          	addi	s11,s11,849 # 800801 <main+0x123>
  8004b8:	b5f5                	j	8003a4 <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004ba:	85e6                	mv	a1,s9
  8004bc:	856e                	mv	a0,s11
  8004be:	0ce000ef          	jal	80058c <strnlen>
  8004c2:	40ad0d3b          	subw	s10,s10,a0
  8004c6:	01a05863          	blez	s10,8004d6 <vprintfmt+0x30c>
                    putch(padc, putdat);
  8004ca:	85ca                	mv	a1,s2
  8004cc:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004ce:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
  8004d0:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004d2:	fe0d1ce3          	bnez	s10,8004ca <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004d6:	000dc783          	lbu	a5,0(s11)
  8004da:	0007851b          	sext.w	a0,a5
  8004de:	ec0792e3          	bnez	a5,8003a2 <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
  8004e2:	6a22                	ld	s4,8(sp)
  8004e4:	bb29                	j	8001fe <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
  8004e6:	8462                	mv	s0,s8
  8004e8:	bbd9                	j	8002be <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004ea:	85e6                	mv	a1,s9
  8004ec:	00000517          	auipc	a0,0x0
  8004f0:	31450513          	addi	a0,a0,788 # 800800 <main+0x122>
  8004f4:	098000ef          	jal	80058c <strnlen>
  8004f8:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004fc:	02800793          	li	a5,40
                p = "(null)";
  800500:	00000d97          	auipc	s11,0x0
  800504:	300d8d93          	addi	s11,s11,768 # 800800 <main+0x122>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800508:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  80050a:	fda040e3          	bgtz	s10,8004ca <vprintfmt+0x300>
  80050e:	bd51                	j	8003a2 <vprintfmt+0x1d8>

0000000000800510 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800510:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  800512:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800516:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  800518:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  80051a:	ec06                	sd	ra,24(sp)
  80051c:	f83a                	sd	a4,48(sp)
  80051e:	fc3e                	sd	a5,56(sp)
  800520:	e0c2                	sd	a6,64(sp)
  800522:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  800524:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  800526:	ca5ff0ef          	jal	8001ca <vprintfmt>
}
  80052a:	60e2                	ld	ra,24(sp)
  80052c:	6161                	addi	sp,sp,80
  80052e:	8082                	ret

0000000000800530 <rand>:
 *
 * The rand() function return a value in the range [0, RAND_MAX].
 * */
int
rand(void) {
    next = (next * 0x5DEECE66DLL + 0xBLL) & ((1LL << 48) - 1);
  800530:	002ef7b7          	lui	a5,0x2ef
  800534:	00001717          	auipc	a4,0x1
  800538:	acc73703          	ld	a4,-1332(a4) # 801000 <next>
  80053c:	76778793          	addi	a5,a5,1895 # 2ef767 <_start-0x5108b9>
  800540:	07b6                	slli	a5,a5,0xd
  800542:	66d78793          	addi	a5,a5,1645
  800546:	02f70733          	mul	a4,a4,a5
    unsigned long long result = (next >> 12);
    return (int)do_div(result, RAND_MAX + 1);
  80054a:	4785                	li	a5,1
  80054c:	1786                	slli	a5,a5,0x21
  80054e:	0795                	addi	a5,a5,5
    next = (next * 0x5DEECE66DLL + 0xBLL) & ((1LL << 48) - 1);
  800550:	072d                	addi	a4,a4,11
  800552:	0742                	slli	a4,a4,0x10
  800554:	8341                	srli	a4,a4,0x10
    unsigned long long result = (next >> 12);
  800556:	00c75513          	srli	a0,a4,0xc
    return (int)do_div(result, RAND_MAX + 1);
  80055a:	02f537b3          	mulhu	a5,a0,a5
    next = (next * 0x5DEECE66DLL + 0xBLL) & ((1LL << 48) - 1);
  80055e:	00001697          	auipc	a3,0x1
  800562:	aae6b123          	sd	a4,-1374(a3) # 801000 <next>
    return (int)do_div(result, RAND_MAX + 1);
  800566:	40f50733          	sub	a4,a0,a5
  80056a:	8305                	srli	a4,a4,0x1
  80056c:	97ba                	add	a5,a5,a4
  80056e:	83f9                	srli	a5,a5,0x1e
  800570:	01f79713          	slli	a4,a5,0x1f
  800574:	40f707b3          	sub	a5,a4,a5
  800578:	8d1d                	sub	a0,a0,a5
}
  80057a:	2505                	addiw	a0,a0,1
  80057c:	8082                	ret

000000000080057e <srand>:
 * srand - seed the random number generator with the given number
 * @seed:   the required seed number
 * */
void
srand(unsigned int seed) {
    next = seed;
  80057e:	1502                	slli	a0,a0,0x20
  800580:	9101                	srli	a0,a0,0x20
  800582:	00001797          	auipc	a5,0x1
  800586:	a6a7bf23          	sd	a0,-1410(a5) # 801000 <next>
}
  80058a:	8082                	ret

000000000080058c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  80058c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  80058e:	e589                	bnez	a1,800598 <strnlen+0xc>
  800590:	a811                	j	8005a4 <strnlen+0x18>
        cnt ++;
  800592:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  800594:	00f58863          	beq	a1,a5,8005a4 <strnlen+0x18>
  800598:	00f50733          	add	a4,a0,a5
  80059c:	00074703          	lbu	a4,0(a4)
  8005a0:	fb6d                	bnez	a4,800592 <strnlen+0x6>
  8005a2:	85be                	mv	a1,a5
    }
    return cnt;
}
  8005a4:	852e                	mv	a0,a1
  8005a6:	8082                	ret

00000000008005a8 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
  8005a8:	ca01                	beqz	a2,8005b8 <memset+0x10>
  8005aa:	962a                	add	a2,a2,a0
    char *p = s;
  8005ac:	87aa                	mv	a5,a0
        *p ++ = c;
  8005ae:	0785                	addi	a5,a5,1
  8005b0:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
  8005b4:	fef61de3          	bne	a2,a5,8005ae <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
  8005b8:	8082                	ret

00000000008005ba <work>:
static int mata[MATSIZE][MATSIZE];
static int matb[MATSIZE][MATSIZE];
static int matc[MATSIZE][MATSIZE];

void
work(unsigned int times) {
  8005ba:	1101                	addi	sp,sp,-32
  8005bc:	e822                	sd	s0,16(sp)
  8005be:	e426                	sd	s1,8(sp)
  8005c0:	ec06                	sd	ra,24(sp)
  8005c2:	84aa                	mv	s1,a0
  8005c4:	00001617          	auipc	a2,0x1
  8005c8:	bfc60613          	addi	a2,a2,-1028 # 8011c0 <matb+0x28>
  8005cc:	00001417          	auipc	s0,0x1
  8005d0:	d8440413          	addi	s0,s0,-636 # 801350 <mata+0x28>
  8005d4:	00001597          	auipc	a1,0x1
  8005d8:	d5458593          	addi	a1,a1,-684 # 801328 <mata>
    int i, j, k, size = MATSIZE;
    for (i = 0; i < size; i ++) {
        for (j = 0; j < size; j ++) {
            mata[i][j] = matb[i][j] = 1;
  8005dc:	4685                	li	a3,1
        for (j = 0; j < size; j ++) {
  8005de:	fd860793          	addi	a5,a2,-40
work(unsigned int times) {
  8005e2:	872e                	mv	a4,a1
            mata[i][j] = matb[i][j] = 1;
  8005e4:	c394                	sw	a3,0(a5)
  8005e6:	c314                	sw	a3,0(a4)
        for (j = 0; j < size; j ++) {
  8005e8:	0791                	addi	a5,a5,4
  8005ea:	0711                	addi	a4,a4,4
  8005ec:	fec79ce3          	bne	a5,a2,8005e4 <work+0x2a>
    for (i = 0; i < size; i ++) {
  8005f0:	02878613          	addi	a2,a5,40
  8005f4:	02858593          	addi	a1,a1,40
  8005f8:	fe8613e3          	bne	a2,s0,8005de <work+0x24>
        }
    }

    yield();
  8005fc:	b57ff0ef          	jal	800152 <yield>

    cprintf("pid %d is running (%d times)!.\n", getpid(), times);
  800600:	b57ff0ef          	jal	800156 <getpid>
  800604:	85aa                	mv	a1,a0
  800606:	8626                	mv	a2,s1
  800608:	00000517          	auipc	a0,0x0
  80060c:	2d850513          	addi	a0,a0,728 # 8008e0 <main+0x202>
  800610:	a91ff0ef          	jal	8000a0 <cprintf>

    while (times -- > 0) {
  800614:	c8cd                	beqz	s1,8006c6 <work+0x10c>
  800616:	34fd                	addiw	s1,s1,-1
  800618:	00001f17          	auipc	t5,0x1
  80061c:	d10f0f13          	addi	t5,t5,-752 # 801328 <mata>
  800620:	00001e97          	auipc	t4,0x1
  800624:	e98e8e93          	addi	t4,t4,-360 # 8014b8 <mata+0x190>
  800628:	5ffd                	li	t6,-1
        for (i = 0; i < size; i ++) {
  80062a:	00001317          	auipc	t1,0x1
  80062e:	9de30313          	addi	t1,t1,-1570 # 801008 <matc>
work(unsigned int times) {
  800632:	8e1a                	mv	t3,t1
  800634:	00001897          	auipc	a7,0x1
  800638:	cf488893          	addi	a7,a7,-780 # 801328 <mata>
  80063c:	00001517          	auipc	a0,0x1
  800640:	cec50513          	addi	a0,a0,-788 # 801328 <mata>
  800644:	8872                	mv	a6,t3
            for (j = 0; j < size; j ++) {
                matc[i][j] = 0;
                for (k = 0; k < size; k ++) {
  800646:	e7050793          	addi	a5,a0,-400
work(unsigned int times) {
  80064a:	86c6                	mv	a3,a7
  80064c:	4601                	li	a2,0
                    matc[i][j] += mata[i][k] * matb[k][j];
  80064e:	428c                	lw	a1,0(a3)
  800650:	4398                	lw	a4,0(a5)
                for (k = 0; k < size; k ++) {
  800652:	02878793          	addi	a5,a5,40
  800656:	0691                	addi	a3,a3,4
                    matc[i][j] += mata[i][k] * matb[k][j];
  800658:	02b7073b          	mulw	a4,a4,a1
  80065c:	9e39                	addw	a2,a2,a4
                for (k = 0; k < size; k ++) {
  80065e:	fea798e3          	bne	a5,a0,80064e <work+0x94>
  800662:	00c82023          	sw	a2,0(a6)
            for (j = 0; j < size; j ++) {
  800666:	00478513          	addi	a0,a5,4
  80066a:	0811                	addi	a6,a6,4
  80066c:	fc851de3          	bne	a0,s0,800646 <work+0x8c>
        for (i = 0; i < size; i ++) {
  800670:	02888893          	addi	a7,a7,40
  800674:	028e0e13          	addi	t3,t3,40
  800678:	fd1e92e3          	bne	t4,a7,80063c <work+0x82>
  80067c:	00001597          	auipc	a1,0x1
  800680:	9b458593          	addi	a1,a1,-1612 # 801030 <matc+0x28>
  800684:	00001817          	auipc	a6,0x1
  800688:	ca480813          	addi	a6,a6,-860 # 801328 <mata>
  80068c:	00001517          	auipc	a0,0x1
  800690:	b0c50513          	addi	a0,a0,-1268 # 801198 <matb>
work(unsigned int times) {
  800694:	86aa                	mv	a3,a0
  800696:	8742                	mv	a4,a6
  800698:	879a                	mv	a5,t1
                }
            }
        }
        for (i = 0; i < size; i ++) {
            for (j = 0; j < size; j ++) {
                mata[i][j] = matb[i][j] = matc[i][j];
  80069a:	6390                	ld	a2,0(a5)
  80069c:	07a1                	addi	a5,a5,8
  80069e:	06a1                	addi	a3,a3,8
  8006a0:	fec6bc23          	sd	a2,-8(a3)
  8006a4:	e310                	sd	a2,0(a4)
            for (j = 0; j < size; j ++) {
  8006a6:	0721                	addi	a4,a4,8
  8006a8:	feb799e3          	bne	a5,a1,80069a <work+0xe0>
        for (i = 0; i < size; i ++) {
  8006ac:	02850513          	addi	a0,a0,40
  8006b0:	02830313          	addi	t1,t1,40
  8006b4:	02880813          	addi	a6,a6,40
  8006b8:	02878593          	addi	a1,a5,40
  8006bc:	fcaf1ce3          	bne	t5,a0,800694 <work+0xda>
    while (times -- > 0) {
  8006c0:	34fd                	addiw	s1,s1,-1
  8006c2:	f7f494e3          	bne	s1,t6,80062a <work+0x70>
            }
        }
    }
    cprintf("pid %d done!.\n", getpid());
  8006c6:	a91ff0ef          	jal	800156 <getpid>
  8006ca:	85aa                	mv	a1,a0
  8006cc:	00000517          	auipc	a0,0x0
  8006d0:	23450513          	addi	a0,a0,564 # 800900 <main+0x222>
  8006d4:	9cdff0ef          	jal	8000a0 <cprintf>
    exit(0);
  8006d8:	4501                	li	a0,0
  8006da:	a5bff0ef          	jal	800134 <exit>

00000000008006de <main>:
}

const int total = 21;

int
main(void) {
  8006de:	7175                	addi	sp,sp,-144
  8006e0:	f4ce                	sd	s3,104(sp)
    int pids[total];
    memset(pids, 0, sizeof(pids));
  8006e2:	0028                	addi	a0,sp,8
  8006e4:	05400613          	li	a2,84
  8006e8:	4581                	li	a1,0
  8006ea:	00810993          	addi	s3,sp,8
main(void) {
  8006ee:	e122                	sd	s0,128(sp)
  8006f0:	fca6                	sd	s1,120(sp)
  8006f2:	f8ca                	sd	s2,112(sp)
  8006f4:	e506                	sd	ra,136(sp)
    memset(pids, 0, sizeof(pids));
  8006f6:	84ce                	mv	s1,s3
  8006f8:	eb1ff0ef          	jal	8005a8 <memset>

    int i;
    for (i = 0; i < total; i ++) {
  8006fc:	4401                	li	s0,0
  8006fe:	4955                	li	s2,21
        if ((pids[i] = fork()) == 0) {
  800700:	a4bff0ef          	jal	80014a <fork>
  800704:	c088                	sw	a0,0(s1)
  800706:	cd25                	beqz	a0,80077e <main+0xa0>
            srand(i * i);
            int times = (((unsigned int)rand()) % total);
            times = (times * times + 10) * 100;
            work(times);
        }
        if (pids[i] < 0) {
  800708:	04054563          	bltz	a0,800752 <main+0x74>
    for (i = 0; i < total; i ++) {
  80070c:	2405                	addiw	s0,s0,1
  80070e:	0491                	addi	s1,s1,4
  800710:	ff2418e3          	bne	s0,s2,800700 <main+0x22>
            goto failed;
        }
    }

    cprintf("fork ok.\n");
  800714:	00000517          	auipc	a0,0x0
  800718:	1fc50513          	addi	a0,a0,508 # 800910 <main+0x232>
  80071c:	985ff0ef          	jal	8000a0 <cprintf>

    for (i = 0; i < total; i ++) {
        if (wait() != 0) {
  800720:	a2dff0ef          	jal	80014c <wait>
  800724:	e10d                	bnez	a0,800746 <main+0x68>
    for (i = 0; i < total; i ++) {
  800726:	347d                	addiw	s0,s0,-1
  800728:	fc65                	bnez	s0,800720 <main+0x42>
            cprintf("wait failed.\n");
            goto failed;
        }
    }

    cprintf("matrix pass.\n");
  80072a:	00000517          	auipc	a0,0x0
  80072e:	20650513          	addi	a0,a0,518 # 800930 <main+0x252>
  800732:	96fff0ef          	jal	8000a0 <cprintf>
        if (pids[i] > 0) {
            kill(pids[i]);
        }
    }
    panic("FAIL: T.T\n");
}
  800736:	60aa                	ld	ra,136(sp)
  800738:	640a                	ld	s0,128(sp)
  80073a:	74e6                	ld	s1,120(sp)
  80073c:	7946                	ld	s2,112(sp)
  80073e:	79a6                	ld	s3,104(sp)
  800740:	4501                	li	a0,0
  800742:	6149                	addi	sp,sp,144
  800744:	8082                	ret
            cprintf("wait failed.\n");
  800746:	00000517          	auipc	a0,0x0
  80074a:	1da50513          	addi	a0,a0,474 # 800920 <main+0x242>
  80074e:	953ff0ef          	jal	8000a0 <cprintf>
    for (i = 0; i < total; i ++) {
  800752:	08e0                	addi	s0,sp,92
        if (pids[i] > 0) {
  800754:	0009a503          	lw	a0,0(s3)
  800758:	00a05463          	blez	a0,800760 <main+0x82>
            kill(pids[i]);
  80075c:	9f9ff0ef          	jal	800154 <kill>
    for (i = 0; i < total; i ++) {
  800760:	0991                	addi	s3,s3,4
  800762:	fe8999e3          	bne	s3,s0,800754 <main+0x76>
    panic("FAIL: T.T\n");
  800766:	00000617          	auipc	a2,0x0
  80076a:	1da60613          	addi	a2,a2,474 # 800940 <main+0x262>
  80076e:	05200593          	li	a1,82
  800772:	00000517          	auipc	a0,0x0
  800776:	1de50513          	addi	a0,a0,478 # 800950 <main+0x272>
  80077a:	8adff0ef          	jal	800026 <__panic>
            srand(i * i);
  80077e:	0284053b          	mulw	a0,s0,s0
  800782:	dfdff0ef          	jal	80057e <srand>
            int times = (((unsigned int)rand()) % total);
  800786:	dabff0ef          	jal	800530 <rand>
  80078a:	47d5                	li	a5,21
  80078c:	02f577bb          	remuw	a5,a0,a5
            times = (times * times + 10) * 100;
  800790:	06400513          	li	a0,100
  800794:	02f787bb          	mulw	a5,a5,a5
  800798:	27a9                	addiw	a5,a5,10
  80079a:	02f5053b          	mulw	a0,a0,a5
            work(times);
  80079e:	e1dff0ef          	jal	8005ba <work>
