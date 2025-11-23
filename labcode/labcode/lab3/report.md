# lab3

### 练习一：

完善代码如下：

1. 

```
        case IRQ_S_TIMER:
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
             /* LAB3 EXERCISE1   2314007 :  */
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event();
            
            static int ticks = 0;
            ticks++;
            
            if (ticks % TICK_NUM == 0) {
                print_ticks();
                static int num = 0;
                num++;
                
                if (num == 10) {
                    sbi_shutdown();
                }
            }
            break;
```

这段代码调用 clock.c 中的函数 clock_set_next_event 来设置下一个时钟中断，而在 clock.c 中已经设置每次加的 base_time = 100000，因为在 qemu 模拟的 riscv 内核下的 CPU 频率大致为 10MHz，每一秒 rdtime 会增加 10000000，这样一来就保证了 1s 内 100 次时钟，然后设定每 100 次调用 print_ticks()，并统计 print_ticks() 的数量，最后调用 sbi_shutdown 关机。其中变量都是静态变量，保证全局性。

运行结果如下：
![结果](\结果.png)

图中输出了 10 次 100 ticks 后实现了关机。

### 扩展练习 Challenge1：描述与理解中断流程

#### 中断异常的流程: 假设是在用户态遇到中断/异常，

1. 首先会调用 ecall 让发起系统调用，主动将控制权交给内核。
2. 然后保存当前的 pc 给 sepc;保存中断/异常的类型给 scause;保存辅助信息(访问错误相关，缺页异常)给 stval;将当前的中断使能状态`sstatus.SIE`保存到`sstatus.SPIE`中，并且会将`sstatus.SIE`清零，从而禁用 S 模式下的中断防止处理中断/异常时再被打断;将`sstatus.SPP`设置为 0，表示要返回到 U 模式；
3. 跳转至 stvec 寄存器的地址，即 __alltraps。
4. 进入 __alltraps 执行 SAVE_ALL 宏 ，申请栈空间，并在栈空间上保存所有通用寄存器，同时保存 `sstatus`, `sepc`, `stval`, `scause` 等 CSR 寄存器。
5. 进入 trap 函数处理，根据 cause 的最高位判断进入中断还是异常处理。
6. 返回，执行 RESTORE_ALL 宏，恢复所有 CSR 寄存器，恢复所有通用寄存器，恢复栈指针。
7. 执行`sret`指令，根据`sstatus.SPP`的值（此时为 0）切换回 U 模式。随后，恢复中断使能状态，将`sstatus.SIE`恢复为`sstatus.SPIE`的值。由于在 U 模式下总是使能中断，因此中断会重新开启。接着，更新`sstatus`，将`sstatus.SPIE`设置为 1,`sstatus.SPP`设置为 0，为下一次中断做准备。最后，将`sepc`的值赋给`pc`，并跳转回用户程序（`sepc`指向的地址）继续执行。此时，系统已经安全地从 S 模式返回到 U 模式，用户程序继续执行。

#### mov a0，sp 的目的是什么？

因为现在要执行 trap 函数，其中 trap 函数需要被保存的 trapframe 这个结构体，而 sp 现在的位置就是这个结构体的开头位置，将 sp 赋值给 a0 相当于传参。

#### SAVE_ALL中寄寄存器保存在栈中的位置是什么确定的？

是由 trap.h 中的对 trapframe 这个结构体的定义确定的，SAVE_ALL 要将所有寄存器以 trapframe 的形式保存，而结构体内部的地址是连续的，所以按照 trapframe 的定义顺序确定。

#### 对于任何中断，__alltraps 中都需要保存所有寄存器吗？

需要。内核必须保证被中断的程序在中断返回后寄存器状态完全恢复。在不知道是哪种中断、也不知道中断发生时寄存器哪些被使用的情况下，只有保存全部寄存器才能保证上下文完整性；

### 扩展练习 Challenge2：理解上下文切换机制

#### 在trapentry.S中汇编代码 csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么？

`csrw sscratch, sp` ：

在进入陷阱时，保存进入 trap 前的 sp(stack pointer) 到sscratch。

这样在保存上下文时可以使用新的内核栈，同时保留用户栈指针，以便我们处理完之后返回原地。

值得一提的是 sp 就是 x2 寄存器，所以后续保存 x 寄存器的时候跳过了 x2，因为这里已经保存了。

`csrrw s0, sscratch, x0`：

读取sscratch到s0，同时将sscratch设为0。

目的是将 sscratch（其实就是原来的 sp）保存到 s0，并且将 sscratch 设为0，作为"来自内核"的标记。

#### save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那这样store的意义何在呢？

首先要说明的是 sbadaddr 和 stval 指的是同一个东西，代码中是 sbadaddr。

stval 存储的是陷阱值，包含与异常相关的附加信息（如缺页地址），而 scause 存储的是当前异常的原因。当我们处理好中断或者异常之后，显然恢复他们没有意义，因为我们要做的只是回到原来我们应该在的位置。

当然 store 是有意义的，我们只是在处理完之后不需要了，不代表我们处理的过程不需要，而无论是 stval 还是 scause，对我们分析异常都相当重要，所以我们需要 store 他们。

### 扩展练习Challenge3：完善异常中断

完整代码如下：

```
        case CAUSE_ILLEGAL_INSTRUCTION:
             // 非法指令异常处理
             /* LAB3 CHALLENGE3   YOUR CODE :  */
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Exception: Illegal instruction\n");
            cprintf("Bad instruction address = 0x%08x\n", tf->epc);
            uint16_t inst1 = *(uint16_t *)(tf->epc);
            if ((inst1 & 0x3) != 0x3) {
                tf->epc += 2;  // 压缩指令 
            } else {
                tf->epc += 4;  // 标准
            }
            break;
        case CAUSE_BREAKPOINT:
            //断点异常处理
            /* LAB3 CHALLLENGE3   YOUR CODE :  */
            /*(1)输出指令异常类型（ breakpoint）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Exception: Breakpoint\n");
            cprintf("Breakpoint at address = 0x%08x\n", tf->epc);
            uint16_t inst2 = *(uint16_t *)(tf->epc);
            if ((inst2 & 0x3) != 0x3) {
                tf->epc += 2;  // 压缩指令
            } else {
                tf->epc += 4;  // 标准 
            }
            break;
```

这两个异常处理的分支内部都包含三条语句，第一条语句输出指令异常类型： Illegal instruction或 breakpoint。第二条语句输出异常指令地址，其中tf->epc 保存的是触发该异常的指令地址。第三条语句更新tf->epc寄存器，表示跳过当前指令，从下一条指令继续执行。这里有一点需要注意：在RISC-V中存在两种指令，一种是标准指令（4字节），另一种则是启用了c扩展的压缩指令（2字节）。我们需要进行判断是哪一种。指令机器码的最低二位如果不是11，则是压缩指令。所以，我们写一个if语句进行判断是+2还是+4。

下面，我们来验证我们的输出。为了验证非法指令异常，我们写入一条不存在的指令,在kern/init.c中的kern_init函数中添加代码```__asm__ __volatile__(".word 0xFFFFFFFF");```。为了验证断点异常，我们在kern/init.c中的kern_init函数中添加代码```__asm__ __volatile__("ebreak");```。然后在终端输入make qemu,输出如下：

```
Exception: Illegal instruction
Bad instruction address = 0xc020009c
Exception: Breakpoint
Breakpoint at address = 0xc02000a0
```

0xc020009c与0xc02000a0正好间隔4字节，说明我们的代码已经正确实现。

