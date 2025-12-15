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

### 练习3：阅读分析源代码，理解进程执行 fork/exec/wait/exit 的实现，以及系统调用的实现（不需要编码）

#### 一、fork/exec/wait/exit 执行流程分析

##### 1. fork 执行流程

```
用户态                              内核态
───────                            ─────────
fork()
  │
  └─→ sys_fork()
        │
        └─→ syscall(SYS_fork)
              │
              │  ecall 指令
              ╰─────────────────→ trap() → exception_handler()
                                    │
                                    └─→ syscall() [kern/syscall/syscall.c:82]
                                          │
                                          └─→ sys_fork() [kern/syscall/syscall.c:16]
                                                │
                                                └─→ do_fork() [kern/process/proc.c:437]
                                                      │
                                                      ├─ alloc_proc()      分配PCB
                                                      ├─ setup_kstack()    分配内核栈
                                                      ├─ copy_mm()         复制内存空间
                                                      ├─ copy_thread()     复制trapframe
                                                      ├─ get_pid()         分配PID
                                                      ├─ hash_proc()       加入哈希表
                                                      ├─ set_links()       设置进程关系
                                                      └─ wakeup_proc()     唤醒子进程
                                    │
              ╭─────────────────────╯ (返回值存入 tf->gpr.a0)
              │  sret 指令返回
用户态继续执行 ←╯
(父进程返回子进程PID，子进程返回0)
```

##### 2. exec 执行流程

```
用户态                              内核态
───────                            ─────────
(通过 kernel_execve)
  │
  │  ebreak 指令
  ╰─────────────────────→ trap() → exception_handler()
                                    │ (CAUSE_BREAKPOINT, a7=10)
                                    │
                                    └─→ syscall()
                                          │
                                          └─→ sys_exec() [kern/syscall/syscall.c:30]
                                                │
                                                └─→ do_execve() [kern/process/proc.c:775]
                                                      │
                                                      ├─ 释放旧内存空间
                                                      │   ├─ exit_mmap()
                                                      │   ├─ put_pgdir()
                                                      │   └─ mm_destroy()
                                                      │
                                                      └─ load_icode()  加载新程序
                                                           ├─ mm_create()      创建新mm
                                                           ├─ setup_pgdir()    创建页表
                                                           ├─ 解析ELF，复制代码/数据段
                                                           ├─ 创建用户栈
                                                           └─ 设置trapframe
                                                              ├─ tf->sp = USTACKTOP
                                                              ├─ tf->epc = elf->e_entry
                                                              └─ tf->status (清SPP,设SPIE)
                                    │
              ╭─────────────────────╯ sret 返回
              │
用户态执行新程序 ←╯ (从 elf->e_entry 开始)
```

##### 3. wait 执行流程

```
用户态                              内核态
───────                            ─────────
wait() / waitpid()
  │
  └─→ sys_wait(pid, store)
        │
        │  ecall 指令
        ╰─────────────────→ syscall()
                                    │
                                    └─→ sys_wait() → do_wait() [proc.c:826]
                                          │
                                          ├─ 查找子进程
                                          │   ├─ pid≠0: find_proc(pid)
                                          │   └─ pid=0: 遍历 cptr 链表
                                          │
                                          ├─ 子进程为 ZOMBIE?
                                          │   │
                                          │   ├─ 是: 回收资源
                                          │   │     ├─ *code_store = exit_code
                                          │   │     ├─ unhash_proc()
                                          │   │     ├─ remove_links()
                                          │   │     ├─ put_kstack()
                                          │   │     └─ kfree(proc)
                                          │   │
                                          │   └─ 否: 睡眠等待
                                          │         ├─ state = PROC_SLEEPING
                                          │         ├─ wait_state = WT_CHILD
                                          │         └─ schedule()
                                          │              (子进程exit时唤醒)
                                    │
              ╭─────────────────────╯
用户态继续 ←──╯ (返回 0 或错误码)
```

##### 4. exit 执行流程

```
用户态                              内核态
───────                            ─────────
exit(error_code)
  │
  └─→ sys_exit(error_code)
        │
        │  ecall 指令
        ╰─────────────────→ syscall()
                                    │
                                    └─→ sys_exit() → do_exit() [proc.c:529]
                                          │
                                          ├─ 释放内存资源
                                          │   ├─ exit_mmap(mm)
                                          │   ├─ put_pgdir(mm)
                                          │   └─ mm_destroy(mm)
                                          │
                                          ├─ current->state = PROC_ZOMBIE
                                          ├─ current->exit_code = error_code
                                          │
                                          ├─ 唤醒父进程 (如果在等待)
                                          │   └─ wakeup_proc(parent)
                                          │
                                          ├─ 孤儿进程托管给 initproc
                                          │
                                          └─ schedule()  (不再返回)

(进程终止，不返回用户态)
```

#### 二、用户态与内核态操作的区分

##### 用户态完成的操作

| 函数 | 用户态操作 |
|------|-----------|
| fork | 调用 `fork()` → `sys_fork()` → 执行 `ecall` 指令触发系统调用 |
| exec | (内核线程通过 `ebreak` 触发) |
| wait | 调用 `wait()`/`waitpid()` → `sys_wait()` → 执行 `ecall` 指令 |
| exit | 调用 `exit()` → `sys_exit()` → 执行 `ecall` 指令 |

##### 内核态完成的操作

| 函数 | 内核态操作 |
|------|-----------|
| fork | PCB分配、内核栈分配、内存复制、页表复制、进程关系设置、调度 |
| exec | 旧内存释放、ELF解析、代码段加载、用户栈创建、trapframe设置 |
| wait | 子进程查找、进程状态检查、睡眠等待、资源回收 |
| exit | 内存释放、状态设置、父进程唤醒、孤儿托管、调度 |

#### 三、用户态与内核态的交错执行机制

##### 1. 进入内核态

用户程序通过 `ecall` 指令触发异常：

```c
// user/libs/syscall.c:19-31
asm volatile (
    "ld a0, %1\n"
    "ld a1, %2\n"
    ...
    "ecall\n"      // 触发 CAUSE_USER_ECALL 异常
    "sd a0, %0"    // 获取返回值
    ...
);
```

CPU 自动完成以下操作：
- 保存 PC 到 `sepc` 寄存器
- 保存特权级到 `sstatus.SPP`
- 切换到 S-mode（内核态）
- 跳转到 `stvec` 指向的异常入口（`__alltraps`）

##### 2. 内核处理系统调用

```c
// kern/trap/trap.c:190-194
case CAUSE_USER_ECALL:
    tf->epc += 4;     // 跳过 ecall 指令
    syscall();        // 分发并处理系统调用
    break;
```

系统调用分发过程：
```c
// kern/syscall/syscall.c:82-94
void syscall(void) {
    struct trapframe *tf = current->tf;
    int num = tf->gpr.a0;                    // 从a0获取系统调用号
    arg[0] = tf->gpr.a1;                     // 从a1-a5获取参数
    ...
    tf->gpr.a0 = syscalls[num](arg);         // 执行并将返回值存入a0
}
```

##### 3. 返回用户态

通过 `sret` 指令完成：
- 从 `sepc` 恢复 PC（指向ecall的下一条指令）
- 从 `sstatus.SPP` 恢复特权级
- 切换回 U-mode（用户态）

##### 4. 返回值传递机制

内核将返回值写入 trapframe 的 a0 寄存器：
```c
tf->gpr.a0 = syscalls[num](arg);  // 返回值写入 trapframe
```

用户态从 a0 寄存器获取返回值：
```c
"sd a0, %0"  // 将 a0 的值存入 ret 变量
```

#### 四、用户态进程的执行状态生命周期图

```
                                    alloc_proc()
                                         │
                                         ▼
                                 ┌───────────────┐
                                 │  PROC_UNINIT  │
                                 │   (未初始化)   │
                                 └───────┬───────┘
                                         │
                          proc_init() / wakeup_proc()
                                         │
                                         ▼
         ┌──────────────────────────────────────────────────────────┐
         │                                                          │
         │                    ┌───────────────┐                     │
         │       ┌──────────▶│ PROC_RUNNABLE │◀──────────┐         │
         │       │            │   (就绪/运行)  │           │         │
         │       │            └───────┬───────┘           │         │
         │       │                    │                   │         │
         │       │               proc_run()               │         │
         │       │               (被调度)                  │         │
         │       │                    │                   │         │
         │       │                    ▼                   │         │
         │       │            ┌───────────────┐           │         │
         │       │            │   RUNNING     │           │         │
         │       │            │   (正在运行)   │           │         │
         │       │            └───────┬───────┘           │         │
         │       │                    │                   │         │
         │       │         ┌──────────┼──────────┐        │         │
         │       │         │          │          │        │         │
         │       │   do_yield()  do_wait()   do_exit()    │         │
         │       │   时间片耗尽  do_sleep()       │        │         │
         │       │         │          │          │        │         │
         │       │         │          ▼          │        │         │
         │       │         │  ┌───────────────┐  │        │         │
         │       │         │  │PROC_SLEEPING  │  │        │         │
         │       │         │  │   (睡眠)      │  │        │         │
         │       │         │  └───────┬───────┘  │        │         │
         │       │         │          │          │        │         │
         │       │         │    wakeup_proc()    │        │         │
         │       │         │     (被唤醒)        │        │         │
         │       │         │          │          │        │         │
         │       └─────────┴──────────┘          │        │         │
         │                                       │        │         │
         │                                       ▼        │         │
         │                               ┌───────────────┐│         │
         │                               │ PROC_ZOMBIE   ││         │
         │                               │   (僵尸)      ││         │
         │                               └───────┬───────┘│         │
         │                                       │        │         │
         │                                 do_wait()      │         │
         │                                (父进程回收)     │         │
         │                                       │        │         │
         │                                       ▼        │         │
         │                               ┌───────────────┐│         │
         │                               │   释放资源     ││         │
         │                               │ (进程消亡)     ││         │
         │                               └───────────────┘│         │
         │                                                          │
         └──────────────────────────────────────────────────────────┘
```

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