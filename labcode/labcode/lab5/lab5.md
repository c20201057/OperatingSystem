# Lab 5
### 练习0：填写已有实验
#### 1.trap.c文件interrupt_handler函数修改：
```c
    case IRQ_S_TIMER:
        /* LAB5 GRADE   YOUR CODE :  */
        /* 时间片轮转： 
        *(1) 设置下一次时钟中断（clock_set_next_event）
        *(2) ticks 计数器自增
        *(3) 每 TICK_NUM 次中断（如 100 次），进行判断当前是否有进程正在运行，如果有则标记该进程需要被重新调度（current->need_resched）
        */
        clock_set_next_event();
        static int ticks = 0;
        ticks++;
        if (ticks % TICK_NUM == 0) {
            print_ticks();
            if (current != NULL) {
                current->need_resched = 1;
            }
        }
        break;
```
按照新更新的注释修改了时间片轮转的代码逻辑。
#### 2.proc.c文件alloc_proc()函数修改：
```c
static struct proc_struct *
alloc_proc(void)
{
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL)
    {
        proc->state = PROC_UNINIT;      // 状态设为未初始化
        proc->pid = -1;                 // pid 设为 -1，表示尚未分配有效 pid
        proc->runs = 0;                 // 运行时间/次数初始化为 0
        proc->kstack = 0;               // 内核栈尚未分配，设为 0
        proc->need_resched = 0;         // 不需要立即调度
        proc->parent = NULL;            // 父进程暂无
        proc->mm = NULL;                // 内存管理结构暂无
        memset(&(proc->context), 0, sizeof(struct context)); // 上下文清零
        proc->tf = NULL;                // 中断帧指针暂空
        proc->pgdir = boot_pgdir_pa;    // 页目录表设为内核页目录表的物理地址 
        proc->flags = 0;                // 标志位清零
        memset(proc->name, 0, PROC_NAME_LEN + 1); // 进程名清零
        proc->wait_state = 0;        // 等待状态初始化为 0
        proc->cptr = NULL;
        proc->optr = NULL;
        proc->yptr = NULL;
    }
    return proc;
}
```
在lab4的基础上，补充了`wait_state`、`*cptr`, `*yptr`, `*optr`的初始化
#### 3.proc.c文件do_fork函数修改：
```c
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf)
{
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS)
    {
        goto fork_out;
    }
    ret = -E_NO_MEM;
    if ((proc = alloc_proc()) == NULL) {
        goto fork_out;
    }
    proc->parent = current; 
    assert(current->wait_state == 0);
    if (setup_kstack(proc) != 0) {
        goto bad_fork_cleanup_proc;
    }
    if (copy_mm(clone_flags, proc) != 0) {
        goto bad_fork_cleanup_kstack;
    }
    copy_thread(proc, stack, tf);
    bool intr_flag = 0;
    local_intr_save(intr_flag); 
    {
        proc->pid = get_pid();           
        hash_proc(proc);
        set_links(proc);              
    }
    local_intr_restore(intr_flag);       
    wakeup_proc(proc);
    ret = proc->pid;

fork_out:
    return ret;

bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
```
在lab4的基础上，添加了`proc->parent = current`，将当前的进程设置为子进程的父进程；`assert(current->wait_state == 0);`，确保当前进程不在等待状态；`set_links(proc);`，将新创建的进程添加到进程链表中。
### 练习1: 加载应用程序并执行（需要编码）

编写代码如下：
```c++
    tf->gpr.sp = USTACKTOP;
    tf->epc = elf->e_entry;
    tf->status = sstatus & ~SSTATUS_SPP;  
    tf->status |= SSTATUS_SPIE;            
```
设计过程：  
1.首先，我们要设置用户栈指针（tf->gpr.sp）
```c++
    tf->gpr.sp = USTACKTOP;
```
将栈指针设置为用户栈顶,使得用户程序从正确的栈位置开始执行。  
2.然后，我们设置程序入口点（tf->epc）
```c++
    tf->epc = elf->e_entry;
```
从ELF文件头中获取程序入口地址,确保在从内核态返回用户态时,CPU跳转到用户程序的正确起始位置。   
3.最后，我们设置状态寄存器（tf->status）
```c++
    tf->status = sstatus & ~SSTATUS_SPP;  
    tf->status |= SSTATUS_SPIE;            
```
- `sstatus & ~SSTATUS_SPP`：清除SPP位为0,表示异常来自用户态，确保 sret 指令返回到用户态
- `tf->status |= SSTATUS_SPIE`：设置SPIE位为1,确保从内核态返回时恢复中断使能状态

#### 请简要描述这个用户态进程被ucore选择占用CPU执行（RUNNING态）到具体执行应用程序第一条指令的整个经过。


1. 首先，在`init_main`函数中，通过调用`int pid = kernel_thread(user_main, NULL, 0)`来调用do_fork函数，创建并唤醒进程，执行函数`user_main`，此时线程状态已经变为`PROC_RUNNABLE`，表明该线程开始运行；

2. 跳转到我们的`user_main`函数中，执行`KERNEL_EXECVE(exit)`，相当于调用了`kern_execve`函数；

3. 在`kernel_execve`中执行到`ebreak`之后，发生断点异常，转到`__alltraps`，转到`trap`，再到`trap_dispatch`，然后到`exception_handler`，再到`CAUSE_BREAKPOINT`处，最后调用`syscall`函数

   ```c
   void
   syscall(void) {
       struct trapframe *tf = current->tf;
       uint64_t arg[5];
       int num = tf->gpr.a0;
       if (num >= 0 && num < NUM_SYSCALLS) {
           if (syscalls[num] != NULL) {
               arg[0] = tf->gpr.a1;
               arg[1] = tf->gpr.a2;
               arg[2] = tf->gpr.a3;
               arg[3] = tf->gpr.a4;
               arg[4] = tf->gpr.a5;
               tf->gpr.a0 = syscalls[num](arg);
               return ;
           }
       }
       print_trapframe(tf);
       panic("undefined syscall %d, pid = %d, name = %s.\n",
               num, current->pid, current->name);
   }
   ```

4. 在`syscall`中根据参数，确定执行`sys_exec`，调用`do_execve`

   ```c++
   static int
   sys_exec(uint64_t arg[]) {
       const char *name = (const char *)arg[0];
       size_t len = (size_t)arg[1];
       unsigned char *binary = (unsigned char *)arg[2];
       size_t size = (size_t)arg[3];
       return do_execve(name, len, binary, size);
   }
   ```

5. 在`do_execve`中调用`load_icode`，加载文件

   ```c++
       if ((ret = load_icode(binary, size)) != 0) {
           goto execve_exit;
       }
   ```

6. 加载完毕后一路返回，直到`__alltraps`的末尾，接着执行`__trapret`后的内容，到`sret`，表示退出S态，回到用户态执行，这时开始执行用户的应用程序

### 练习2: 父进程复制自己的内存空间给子进程（需要编码）

编写代码如下：

```
void *src_kvaddr = page2kva(page);
void *dst_kvaddr = page2kva(npage);
memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ret = page_insert(to, npage, start, perm);
```

### 代码解释

1. `void \*src_kvaddr = page2kva(page);`

   我们虽然持有物理页的描述符 `struct Page *page`，但 CPU 操作内存需要使用**虚拟地址**。`page2kva` 将物理页结构体转换为内核可以直接访问的虚拟地址。

2. `void dst_kvaddr = page2kva(npage);`

   同上，我们需要获取新分配的物理页 `npage` 对应的内核虚拟地址，以便往里面写入数据。

3. `memcpy(dst_kvaddr, src_kvaddr, PGSIZE);`

   这是核心步骤。将父进程该页面的实际数据完整地拷贝到子进程的新页面中。大小为一页 。

4. `ret = page_insert(to, npage, start, perm);`

   数据拷贝完成后，我们需要修改子进程的页表 ，其中 `to` 是子进程的页目录基址。

   page_insert 会在页表中建立虚拟地址到 `npage` (物理页) 的映射。

   perm 是直接复用的父进程的权限。

#### 如何设计实现Copy on Write机制？给出概要设计，鼓励给出详细设计。

核心思想是：

1. **Fork 时**：父子进程共享同一个物理页，但将页表项的权限都设为**只读**。

2. **Read 时**：物理页确实存在，一切正常。

3. **Write 时**：CPU 尝试写入只读页面 -> 触发 **Page Fault (页访问异常)**。

4. **Handler**：内核捕获异常 -> 发现是 CoW 页面 -> 分配新物理页 -> 拷贝数据 -> 修改 PTE 指向新页并开启写权限 -> 恢复执行。

具体实现思路：

1. **内存映射建立阶段 (`pmm.c: copy_range`)**：

- 不再调用 `alloc_page` 和 `memcpy`，而是将子进程的 PTE 指向父进程**相同**的物理页。
- 重点是将父进程和子进程的 PTE 中的 **写权限** 全部抹去。

2. **页访问异常处理阶段**：

- 当发生“写错误”（权限不足）时，检查对应的虚拟内存区域是否本来是可写的。

- 如果是，说明这是 CoW 触发的。

- 分配新页，拷贝原数据。

- 更新 PTE：指向新页，并**恢复 PTE_W 权限**。

### 分支任务：gdb调试系统调用以及返回

#### 1.ecall调试流程

我们首先按照指导书上的步骤运行三个终端：第一个终端启动qemu模拟器，第二个终端附加调试qemu进程，第三个终端调试ucore内核。

然后在第三个终端中，我们设置断点在syscall函数处：
```gdb
(gdb) add-symbol-file obj/__user_exit.out
add symbol table from file "obj/__user_exit.out"
(y or n) y
Reading symbols from obj/__user_exit.out...
(gdb)  break user/libs/syscall.c:18
Breakpoint 1 at 0x8000f8: file user/libs/syscall.c, line 19.
```
接着，我们输入c运行到断点处，并查看一下接下来要执行的几条指令：
```gdb
(gdb) c
Continuing.

Breakpoint 1, syscall (num=num@entry=30) at user/libs/syscall.c:19
19          asm volatile (
(gdb) x/7i $pc
=> 0x8000f8 <syscall+32>:       ld      a0,8(sp)
   0x8000fa <syscall+34>:       ld      a1,40(sp)
   0x8000fc <syscall+36>:       ld      a2,48(sp)
   0x8000fe <syscall+38>:       ld      a3,56(sp)
   0x800100 <syscall+40>:       ld      a4,64(sp)
   0x800102 <syscall+42>:       ld      a5,72(sp)
   0x800104 <syscall+44>:       ecall
```
我们可以看到，encall指令在0x800104处。接着我们单步执行到ecall指令：
```gdb
(gdb) si
0x0000000000800104      19          asm volatile (
(gdb) i r $pc
pc             0x800104 0x800104 <syscall+44>
```
此时，我们就需要为qemu打上断点了，我们在第二个终端里按下Ctrl+C，根据大模型的建议，我们在`riscv_cpu_do_interrupt()`打上断点：
```gdb
(gdb) b riscv_cpu_do_interrupt
Breakpoint 1 at 0x55ce2fdbc5e9: file /root/qemu-4.1.1/target/riscv/cpu_helper.c, line 507.
```
然后我们输入c继续运行qemu到断点处，这时候我们在第三个终端里输入si单步执行进入encall的异常处理流程。接着，我们切换回第二个终端，可以看到输出了以下信息：
```gdb
Thread 3 "qemu-system-ris" hit Breakpoint 1, riscv_cpu_do_interrupt (cs=0x55ce5fd6e890) at /root/qemu-4.1.1/target/riscv/cpu_helper.c:507
507         RISCVCPU *cpu = RISCV_CPU(cs);
```
说明qemu刚刚捕获到了一条RISC-V的异常，也就是我们在第三个终端里执行的ecall指令。

首先，我们输入bt，观察它的调用栈：
```gdb
(gdb) bt
#0  riscv_cpu_do_interrupt (cs=0x55ce5fd6e890) at /root/qemu-4.1.1/target/riscv/cpu_helper.c:507
#1  0x000055ce2fd27e1f in cpu_handle_exception (cpu=0x55ce5fd6e890, ret=0x7efce1f3390c)
    at /root/qemu-4.1.1/accel/tcg/cpu-exec.c:506
#2  0x000055ce2fd284ba in cpu_exec (cpu=0x55ce5fd6e890) at /root/qemu-4.1.1/accel/tcg/cpu-exec.c:712
#3  0x000055ce2fcdaad6 in tcg_cpu_exec (cpu=0x55ce5fd6e890) at /root/qemu-4.1.1/cpus.c:1435
#4  0x000055ce2fcdb38f in qemu_tcg_cpu_thread_fn (arg=0x55ce5fd6e890) at /root/qemu-4.1.1/cpus.c:1743
#5  0x000055ce3015d457 in qemu_thread_start (args=0x55ce5fd84f30) at util/qemu-thread-posix.c:502
#6  0x00007efce48c6ac3 in start_thread (arg=<optimized out>) at ./nptl/pthread_create.c:442
#7  0x00007efce49588c0 in clone3 () at ../sysdeps/unix/sysv/linux/x86_64/clone3.S:81
```
我们重点关注#2、#1、#0这三层调用：`cpu_exec`是qemu的CPU执行主循环函数，它会不断地取指令并执行，当遇到异常时，就会调用cpu_handle_exception函数来处理异常。而`cpu_handle_exception`函数会调用`riscv_cpu_do_interrupt`函数来具体处理RISC-V的异常类型。在这里，我们就进入了RISC-V的异常处理流程。

然后，在大模型的提示下，我们输入`p cs->exception_index`，查看异常类型：
```gdb
(gdb) p cs->exception_index
$1 = 8
```
异常类型8对应的是用户态异常，也就是我们执行encall指令时触发的异常。

最后，我们分析一下`riscv_cpu_do_interrupt`函数的qemu源码，我们输入命令next，逐行代码执行：
```gdb
(gdb) n
508         CPURISCVState *env = &cpu->env;
```
这一步的作用是获取 env 结构体指针，方便访问 CPU 状态寄存器。
```gdb
(gdb) n
513         bool async = !!(cs->exception_index & RISCV_EXCP_INT_FLAG);
(gdb) n
514         target_ulong cause = cs->exception_index & RISCV_EXCP_INT_MASK;
```
这两行代码的作用是解析异常类型，判断是否为异步中断，并提取具体的异常原因。
```gdb
(gdb) n
515         target_ulong deleg = async ? env->mideleg : env->medeleg;
```
这一步的作用是根据异常类型选择合适的委托寄存器，决定异常处理的特权级别。
```gdb
(gdb) n
516         target_ulong tval = 0;
```
这一步的作用是初始化异常值寄存器 tval，用于存储异常相关的信息。
```gdb
(gdb) n
525         if (!async) {
(gdb) n
527             switch (cause) {
(gdb) n
540                 break;
(gdb) n
543             if (cause == RISCV_EXCP_U_ECALL) {
(gdb) n
544                 assert(env->priv <= 3);
(gdb) n
545                 cause = ecall_cause_map[env->priv];
```
这一段代码的作用是处理同步异常，特别是用户态的系统调用异常，将异常原因映射到正确的值。
```gdb
(gdb) n
549         trace_riscv_trap(env->mhartid, async, cause, env->pc, tval, cause < 16 ?
(gdb) n
550             (async ? riscv_intr_names : riscv_excp_names)[cause] : "(unknown)");
```
这几行代码的作用是打印调试信息到 QEMU 的日志中，记录陷阱事件。
```gdb
(gdb) n
552         if (env->priv <= PRV_S &&
(gdb) n
553                 cause < TARGET_LONG_BITS && ((deleg >> cause) & 1)) {
```
这一段代码的作用是判断当前异常是否应当从 M 态“下放（delegate）”给 S 态处理。

接下来是最重要的部分：
```gdb
(gdb) n
555             target_ulong s = env->mstatus;
(gdb) n
556             s = set_field(s, MSTATUS_SPIE, env->priv_ver >= PRIV_VERSION_1_10_0 ?
(gdb) n
558             s = set_field(s, MSTATUS_SPP, env->priv);
(gdb) n
559             s = set_field(s, MSTATUS_SIE, 0);
(gdb) n
560             env->mstatus = s;
```
这一段代码的作用是保存当前特权级别和中断使能状态，为进入 S 态处理异常做准备。
```gdb
(gdb) n
561             env->scause = cause | ((target_ulong)async << (TARGET_LONG_BITS - 1));
(gdb) n
562             env->sepc = env->pc;
(gdb) n
563             env->sbadaddr = tval;
```
这三行代码的作用是设置 S 态的异常原因寄存器、异常程序计数器和坏地址寄存器。
```gdb
(gdb) n
564             env->pc = (env->stvec >> 2 << 2) +
(gdb) n
565                 ((async && (env->stvec & 3) == 1) ? cause * 4 : 0);
```
这两行代码的作用是计算新的 PC 值，即 S 态陷阱处理程序的入口地址。
```gdb
(gdb) n
566             riscv_cpu_set_mode(env, PRV_S);
```
这一行代码的作用是将 CPU 的特权级别切换到 S 态，以便执行 S 态的异常处理程序。
```gdb
(gdb) n
590         cs->exception_index = EXCP_NONE; /* mark handled to qemu */
```
这一行代码的作用是将异常标记为已处理，防止重复处理同一异常。

现在`riscv_cpu_do_interrupt`函数已经执行完了。接下来就会逐层向上返回，最终回到 QEMU 的主循环中。然后，QEMU 会根据更新后的 PC 值跳转到 S 态的异常处理入口地址，开始执行 S 态的异常处理程序。

当我们在第二个终端里执行到最后一步时：
```gdb
(gdb) n
1770            qemu_wait_io_event(cpu);
```
我们切换回第三个终端，可以看到输出了以下信息：
```gdb
(gdb) si
0xffffffffc0200e58 in __alltraps ()
    at kern/trap/trapentry.S:123
123         SAVE_ALL
```
说明这个异常处理入口就是trapentry.S文件中的`__alltraps`函数。

通过以上步骤，我们成功地调试了 encall 指令的异常处理流程，理解了 QEMU 如何模拟 RISC-V CPU 处理系统调用异常的机制。


### 2. sret调试流程
我们还是像前面一样，先在第三个终端里设置断点在`sret`指令处：
```gdb
(gdb) b kern/trap/trapentry.S:133
Breakpoint 1 at 0xffffffffc0200f1a: file kern/trap/trapentry.S, line 133.
```
然后我们输入c运行到断点处
```gdb
(gdb) c
Continuing.

Breakpoint 1, __trapret () at kern/trap/trapentry.S:133
133         sret
```
此时，我们就需要为qemu打上断点了，我们在第二个终端里按下Ctrl+C，根据大模型的建议，我们在`helper_sret`和`riscv_cpu_set_mode`打上断点：
```gdb
(gdb) b helper_sret
Breakpoint 1 at 0x561acdd2dbb5: file /root/qemu-4.1.1/target/riscv/op_helper.c, line 76.
(gdb)  b riscv_cpu_set_mode
Breakpoint 2 at 0x561acdd2e6dc: file /root/qemu-4.1.1/target/riscv/cpu_helper.c, line 127.
```
然后我们输入c继续运行qemu到断点处，这时候我们在第三个终端里输入si单步执行进入`sret`的异常返回流程。接着，我们切换回第二个终端，可以看到输出了以下信息：
```gdb
Thread 3 "qemu-system-ris" hit Breakpoint 1, helper_sret (env=0x561b01eb62a0, cpu_pc_deb=18446744072637910810) at /root/qemu-4.1.1/target/riscv/op_helper.c:76
76          if (!(env->priv >= PRV_S)) {
```
说明qemu已经到达第一个断点处，准备切换RISC-V CPU的特权级别。

首先，我们输入bt，观察它的调用栈：
```gdb
#0  riscv_cpu_set_mode (env=0x55ab489e82a0, newpriv=1) at /root/qemu-4.1.1/target/riscv/cpu_helper.c:127
#1  0x000055ab2d69dd81 in helper_sret (env=0x55ab489e82a0, cpu_pc_deb=18446744072637910810)
    at /root/qemu-4.1.1/target/riscv/op_helper.c:98
#2  0x00007f1dc9828122 in code_gen_buffer ()
#3  0x000055ab2d60a2fb in cpu_tb_exec (cpu=0x55ab489df890, itb=0x7f1dc9828040 <code_gen_buffer+19>)
    at /root/qemu-4.1.1/accel/tcg/cpu-exec.c:173
#4  0x000055ab2d60b141 in cpu_loop_exec_tb (cpu=0x55ab489df890, tb=0x7f1dc9828040 <code_gen_buffer+19>, 
    last_tb=0x7f1dc9826918, tb_exit=0x7f1dc9826910) at /root/qemu-4.1.1/accel/tcg/cpu-exec.c:621
#5  0x000055ab2d60b476 in cpu_exec (cpu=0x55ab489df890) at /root/qemu-4.1.1/accel/tcg/cpu-exec.c:732
#6  0x000055ab2d5bdad6 in tcg_cpu_exec (cpu=0x55ab489df890) at /root/qemu-4.1.1/cpus.c:1435
#7  0x000055ab2d5be38f in qemu_tcg_cpu_thread_fn (arg=0x55ab489df890) at /root/qemu-4.1.1/cpus.c:1743
#8  0x000055ab2da40457 in qemu_thread_start (args=0x55ab489f5f30) at util/qemu-thread-posix.c:502
#9  0x00007f1dcc1b9ac3 in start_thread (arg=<optimized out>) at ./nptl/pthread_create.c:442
#10 0x00007f1dcc24b8c0 in clone3 () at ../sysdeps/unix/sysv/linux/x86_64/clone3.S:81
```
我们重点关注#1、#0这两层调用：`helper_sret`是QEMU中模拟RISC-V的sret指令的函数，它负责处理从S态返回用户态的逻辑。而`riscv_cpu_set_mode`函数则是用于切换CPU的特权级别。在这里，我们就进入了RISC-V的异常返回流程。

然后，我们输入`(gdb) p env->priv`，查看当前的特权级别：
```gdb
(gdb) p env->priv
$1 = 1
```
说明当前CPU处于S态。

最后，我们依然分析一下`helper_sret`和`riscv_cpu_set_mode`函数的qemu源码。

首先是`helper_sret`函数，我们输入命令next，逐行代码执行：
```gdb
(gdb) n 
80 target_ulong retpc = env->sepc;
```
这一行代码的作用是获取用户程序的下一条指令地址，即 sepc 寄存器的值。
```gdb
(gdb) n 
81 if (!riscv_has_ext(env, RVC) && (retpc & 0x3)) {
(gdb) n 
85 if (env->priv_ver >= PRIV_VERSION_1_10_0 &&
(gdb) n 
86 get_field(env->mstatus, MSTATUS_TSR)) {
```
这几行代码作用是进行指令扩展及TSR位的检查。
```gdb
(gdb) n
90          target_ulong mstatus = env->mstatus;
```
这一行代码的作用是获取当前的 mstatus 寄存器值，以便后续修改。
```gdb
(gdb) n
91          target_ulong prev_priv = get_field(mstatus, MSTATUS_SPP);
```
这一行代码的作用是获取之前的特权级别，即 SPP 位的值
```gdb
(gdb) n
92          mstatus = set_field(mstatus,MSTATUS_SIE,get_field(mstatus, MSTATUS_SPIE));
(gdb) n
96          mstatus = set_field(mstatus, MSTATUS_SPIE, 0);
(gdb) n
97          mstatus = set_field(mstatus, MSTATUS_SPP, PRV_U);
```
这几行代码的作用是修改 mstatus 寄存器，分别完成了以下任务：
- 将 SIE 位设置为 SPIE 的值，恢复中断使能状态。
- 将 SPIE 位清零，防止下次进入内核态时中断被错误地使能。
- 将 SPP 位清0，表示返回后是用户态。

```gdb
(gdb) n
98          riscv_cpu_set_mode(env, prev_priv);
```
这一行代码的作用是调用`riscv_cpu_set_mode`函数，将 CPU 的特权级别切换到原来的用户态。

接下来，我们分析一下`riscv_cpu_set_mode`函数的qemu源码，我们输入命令next，逐行代码执行：
```gdb
(gdb) n
Thread 3 "qemu-system-ris" hit Breakpoint 2, riscv_cpu_set_mode (env=0x561b01eb62a0, newpriv=1) at /root/qemu-4.1.1/target/riscv/cpu_helper.c:127
127         if (newpriv > PRV_M) {
(gdb) n
130         if (newpriv == PRV_H) {
```
这两行代码用于检查即将切换的特权级是否合法。
```gdb
(gdb) n
134         env->priv = newpriv;
```
这一行代码的作用是将 CPU 的特权级别切换到原来的用户态。
```gdb
(gdb) n
144         env->load_res = -1;
```
这一行代码的作用是清除 LR/SC状态。
```gdb
(gdb) n
helper_sret (env=0x55e69eb792a0, cpu_pc_deb=18446744072637910810) at /root/qemu-4.1.1/target/riscv/op_helper.c:99
99          env->mstatus = mstatus;
```
这一步已经回到了`helper_sret`函数，作用是更新 mstatus 寄存器的值。因为mstatus 寄存器包含了 sstatus 的所有关键字段（如 SIE, SPIE, SPP），所以这一步相当于完成中断状态和特权级的恢复。
```gdb
(gdb) n
101         return retpc;
```
这一步的作用是返回用户程序的下一条指令地址，即 sepc 寄存器的值。

现在`helper_sret`函数已经执行完了。接下来就会逐层向上返回，最终回到 QEMU 的主循环中。然后，QEMU 会根据更新后的 PC 值跳转到用户态的下一条指令地址，继续执行用户程序。

当我们在第二个终端里执行到最后一步时：
```gdb
(gdb) n
1770            qemu_wait_io_event(cpu);
```
我们切换回第三个终端，可以看到输出了以下信息：
```gdb
(gdb) si
kernel_thread_entry () at kern/process/entry.S:4
4               move a0, s1
```
说明sret指令的下一步就是entry.S文件中的`kernel_thread_entry`函数。

通过以上步骤，我们成功地调试了 sret 指令的异常返回流程，理解了 QEMU 如何模拟 RISC-V CPU 处理从内核态返回用户态的机制。

### Challenge：实现 copy on write 机制

**内存映射建立阶段 (`pmm.c: copy_range`)**：

对于 copy_range 我们修改如下：

```
npage = page; 
if (*ptep & PTE_W) {
	*ptep = (*ptep) & (~PTE_W);
	tlb_invalidate(from, start);
}
ret = page_insert(to, npage, start, perm & (~PTE_W));
```

具体来说，就是直接服用旧页，同时将父进程写权限去除。最后建立只读映射。

**页访问异常处理阶段**：

我们添加缺页异常处理函数，在 CAUSE_STORE_PAGE_FAULT 时调用。

首先识别目前是因为写权限不足导致异常：

```
if (*ptep & PTE_V) {
    if ((error_code & 2) && !(*ptep & PTE_W)) {
```

1. `*ptep & PTE_V`：页表项是有效的（说明不是单纯的内存未分配，而是权限问题）。

2. `(error_code & 2)`：发生的是写操作。

3. `!(*ptep & PTE_W)`：当前页表项不可写。

然后分如下情况处理：

1. 如果引用数为一，说明目前没有子进程共享页，不需要复制，同时还要恢复其写权限。

   ```
   if (page_ref(page) == 1) {
       page_insert(mm->pgdir, page, addr, (*ptep & PTE_USER) | PTE_W);
       ret = 0;
   }
   ```

   2.否则，我们进行复制，既是分配新页，数据拷贝，重新映射三个步骤。

   ```
   else {
       struct Page *npage = alloc_page();
       void *src_kvaddr = page2kva(page);
       void *dst_kvaddr = page2kva(npage);
       memcpy(dst_kvaddr, src_kvaddr, PGSIZE); // 复制数据
   
       uint32_t perm = (*ptep & PTE_USER) | PTE_W; // 赋予写权限
       if (page_insert(mm->pgdir, npage, addr, perm) != 0) { ... }
       ret = 0;
   }
   ```

   

测试用例：

```
#include <stdio.h>
#include <ulib.h>
#include <string.h>

/* 定义一个足够大的全局数组，确保跨越多个页 */
#define ARRAY_SIZE 4096 
volatile int global_data[ARRAY_SIZE];
volatile int simple_var = 100;

int main(void) {
    cprintf("---------- COW TEST START ----------\n");

    // 1. 初始化数据
    int i;
    for (i = 0; i < ARRAY_SIZE; i++) {
        global_data[i] = i;
    }
    cprintf("Parent: Data initialized.\n");

    // 2. 打印 fork 前的剩余物理页（可选，如果你的 ucore 实现了 sys_get_free_pages）
    // cprintf("Free pages before fork: %d\n", sys_get_free_pages());

    int pid = fork();

    if (pid == 0) {
        /* =================================================
         * 子进程执行区域
         * ================================================= */
        cprintf("Child: I am running.\n");

        // [测试点 1]: 读取数据
        // 此时不应该触发 Page Fault (因为是只读)，应该直接读取共享页
        cprintf("Child: Check simple_var = %d (Expect 100)\n", simple_var);
        assert(simple_var == 100);
        cprintf("Child: Check global_data[0] = %d (Expect 0)\n", global_data[0]);
        assert(global_data[0] == 0);

        // [测试点 2]: 触发 COW (写操作)
        cprintf("Child: WRITING data to trigger COW...\n");
        
        // 这里的写操作应该触发 Store Page Fault -> do_pgfault -> 复制物理页
        simple_var = 200;
        global_data[0] = 9999;
        
        cprintf("Child: Modified simple_var to %d\n", simple_var);
        cprintf("Child: Modified global_data[0] to %d\n", global_data[0]);

        // 确保子进程读到的是修改后的值
        assert(simple_var == 200);
        assert(global_data[0] == 9999);

        cprintf("Child: Exit.\n");
        exit(0);
    } 
    else {
        /* =================================================
         * 父进程执行区域
         * ================================================= */
        cprintf("Parent: Waiting for child...\n");
        
        // 等待子进程结束，确保子进程已经执行了写操作
        if (waitpid(pid, NULL) == 0) {
            cprintf("Parent: Child exited.\n");
        }

        // [测试点 3]: 检查父进程的数据是否被污染
        // 如果 COW 实现正确，父进程的物理页应该保持原样，不受子进程影响
        cprintf("Parent: Checking data integrity...\n");

        cprintf("Parent: simple_var = %d (Expect 100)\n", simple_var);
        if (simple_var != 100) {
            panic("COW FAIL: Parent's simple_var changed! Memory is incorrectly shared.\n");
        }

        cprintf("Parent: global_data[0] = %d (Expect 0)\n", global_data[0]);
        if (global_data[0] != 0) {
            panic("COW FAIL: Parent's array changed! Memory is incorrectly shared.\n");
        }

        cprintf("---------- COW TEST PASSED ----------\n");
    }

    return 0;
}
```

测试结果：

![image-20251214162758485](.\RES.png)

#### 用户程序何时被预先加载到内存中？

在 ucore 中用户程序的二进制在构建时被嵌入到内核镜像，因此内核镜像加载到内存后这些二进制数据就已经驻留在物理内存中；但它们并不会自动成为某个进程的用户虚拟空间内容。

真正把程序装入某个进程的用户地址空间是在执行 `exec` 时由内核完成：`do_execve` → `load_icode(binary,size)`，内核为每个可加载段分配用户页，用 `memcpy(page2kva(page)+off, from, size)` 将二进制段从内核镜像复制到这些用户页，使用 `memset` 清零 BSS，并为用户栈分配页面（`USTACKTOP`）。

因此 ucore 的实现是“内存到内存的一次性拷贝、无磁盘 I/O”，与常见操作系统从磁盘读取可执行文件并常用按需缺页加载的策略不同。


