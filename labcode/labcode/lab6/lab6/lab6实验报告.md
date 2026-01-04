# Lab6 进程调度

## 练习一

### 1. `sched_class` 结构体分析 

定义：

```c
struct sched_class {
    const char *name;
    void (*init)(struct run_queue *rq);
    void (*enqueue)(struct run_queue *rq, struct proc_struct *proc);
    void (*dequeue)(struct run_queue *rq, struct proc_struct *proc);
    struct proc_struct *(*pick_next)(struct run_queue *rq);
    void (*proc_tick)(struct run_queue *rq, struct proc_struct *proc);
};
```

- **name**：调度类名称字符串，便于调试输出或选择。

- **init(rq)**：初始化运行队列的数据结构。
  - 调用时机：内核启动时或运行队列首次分配时。
  - 作用：将 `rq` 的各个成员`run_list`、`proc_num`、`lab6_run_pool`等设为初始状态。

- **enqueue(rq, proc)**：把进程 `proc` 插入 `rq` 中，使其可被调度。
  - 调用时机：当进程变为 `PROC_RUNNABLE` 时;
  - 作用：根据具体策略把 `proc` 放到适当位置，其中 RR 在链表尾插入，stride 插入 skew-heap，并更新 `proc` 的元信息和 `rq->proc_num`。

- **dequeue(rq, proc)**：从 `rq` 中移除指定进程 `proc`。
  - 调用时机：当进程被选中运行或被销毁/等待时。
  - 作用：从队列结构中删除 `proc`，并维护 `rq` 的统计信息。

- **pick_next(rq)**：从 `rq` 中选出下一个要运行的 `proc`。
  - 调用时机：调度器在 `schedule()` 中需要选择下一个进程时调用。
  - 作用：根据策略返回下一进程指针，其中 RR 取链表头；stride 取步长最小的元素。

- **proc_tick(rq, proc)**：处理时间片或 tick 到来时对当前进程的更新。
  - 调用时机：时钟中断处理函数通过 `sched_class_proc_tick(current)` 触发。
  - 作用：减少进程剩余时间片，或在某些策略中更新权重/步长；若需要切换则设置 `proc->need_resched = 1`。

为什么使用函数指针而不是直接实现？

- **灵活策略模式**：函数指针允许在运行时选择不同的调度策略（RR、stride、或将来的其他算法），代码中只需通过统一接口调用而不改变调度框架。
- **解耦**：调度器核心不需要了解具体算法的内部数据结构或实现细节，只调用接口即可。
- **可测试与可扩展**：增加/替换算法仅需实现 `sched_class` 的函数集合并把 `sched_class` 指针指向它；便于维护与单元测试。

### 2. `run_queue` 结构体分析 

lab6 中的`run_queue`如下所示：

```c
struct run_queue {
    list_entry_t run_list;    // 用于 RR 的链表
    unsigned int proc_num;
    int max_time_slice;
    skew_heap_entry_t *lab6_run_pool; // lab6: 用于 stride 的优先队列
};
```

而 lab5 的 `run_queue`只包含：
- `run_list`、`proc_num`、`max_time_slice`

差异说明：
- **lab6 扩展了 `lab6_run_pool`**，这是为了支持以步长/优先级为选择依据的调度。
- **设计理由**：不同调度算法对底层数据结构的需求不同：
  - RR需要一个 FIFO 队列，链表是简单、低开销且高效
  - stride需要快速地拿到“最小”或“最大”键，适合用堆／斜堆等优先队列

### 3. 框架函数分析：`sched_init()`、`wakeup_proc()`、`schedule()` 

#### sched_init()：

- 在 `sched_init()` 中，内核将 `sched_class` 指向默认调度类`default_sched_class`，并初始化 `rq`，包括设置 `rq->max_time_slice` 和调用 `sched_class->init(rq)`。
- 作用：完成调度框架与具体调度类的绑定，并初始化运行队列。
- 变化：lab6 将 `sched_class` 设为指针，允许在初始化时选定或更换具体策略。

#### wakeup_proc(proc)

- 如果 `proc` 非 runnable，则把 `proc->state=PROC_RUNNABLE; proc->wait_state=0;` 并 如果 proc != current，则通过 `sched_class_enqueue(proc)` 将其插入运行队列。
- 解耦点：`wakeup_proc` 并不关心具体如何入队，只调用统一的 `sched_class->enqueue`。

#### schedule()

- 工作：
  1. 把 `current->need_resched` 清零并在必要时把 `current` 再加入队列；
  2. 调用 `sched_class_pick_next()` 获取 `next`；若为空则选 `idleproc`；
  3. 若 `next != current`，调用 `proc_run(next)` 进行上下文切换。
- 解耦点：`schedule()` 只负责调度流程的控制，而具体如何选择完全依赖 `sched_class->pick_next`。这使得框架能对不同算法做到透明支持。

### 4. 使用流程分析

#### 调度类的初始化流程

1. **内核入口**`kern_init()`按顺序调用：`pmm_init()`、`pic_init()`、`idt_init()`、`vmm_init()` 等；
2. **调用 `sched_init()`**：
   - 内部设置 `sched_class = &default_sched_class;`
   - 初始化 `rq`;
3. **调用 `proc_init()`** 创建 `idleproc` 和 `initproc`；`idleproc` 设置 `need_resched = 1`；
4. **时钟/中断初始化**完成后，调度子系统处于可用状态。

> 结果：`default_sched_class` 与框架关联完成，框架通过函数指针调用具体实现。

#### 完整的进程调度流程

事件：**时钟中断触发** → 核心步骤如下：

1. 硬件/中断控制器产生中断 → 内核 `interrupt_handler()` 被调用
2. 在 timer 分支中：
   - 调用 `clock_set_next_event()`；
   - 增加全局 `ticks`，必要时打印或关机；
   - 调用 `sched_class_proc_tick(current)`以通知当前进程一个 tick；
3. `sched_class_proc_tick`会执行例如 `proc->time_slice--`，如果耗尽设置 `proc->need_resched = 1`；
4. 中断返回前或在 trap 处理后，若 `current->need_resched` 为真，则调用 `schedule()`；
5. `schedule()` 流程：
   - 若 `current->state == PROC_RUNNABLE`，调用 `sched_class_enqueue(current)` 把当前进程再入队；
   - `next = sched_class_pick_next()`；
   - 若 `next == NULL`，设 `next = idleproc`；
   - 若 `next != current`，执行 `proc_run(next)` 做上下文切换。

ASCII 流程图：

```
时钟中断
   |
   v
interrupt_handler(timer):
   -> clock_set_next_event(), ticks++
   -> sched_class_proc_tick(current)
   -> 可能设置 current->need_resched
   |
   v
如果 (current->need_resched) -> schedule()
   |
   v
schedule():
   -> if current runnable: sched_class_enqueue(current)
   -> next = sched_class_pick_next()
   -> if next != current: proc_run(next)
```

**need_resched 的作用**：
- 作为软中断 / 软请求触发下一次上下文切换的标志。由时间片耗尽、系统调用 `yield`、或显式设置来设置；在 trap/中断结束后检查该标志并执行 `schedule()`，以保证抢占式调度的正确性。

### 5. 调度算法切换机制

要新增算法，需要完成：

1. **实现一个 `sched_class` 实例**：实现 `.init`、`.enqueue`、`.dequeue`、`.pick_next`、`.proc_tick` 等函数；
2. **保证 `run_queue` 支持所需数据结构**：若算法需要优先队列/斜堆，要使用需要新增字段；
3. **将框架指向新的类**：在 `sched_init()` 中将 `sched_class = &stride_sched_class;`；
4. **确保进程的调度相关字段已初始化**并在 `alloc_proc()` 中设置默认值；

为什么当前设计便于切换？
- **函数指针接口**把算法实现与调度核心完全解耦，添加新的 `sched_class` 无须改动 `schedule()`、`wakeup_proc()` 等核心代码；
- **统一的 `run_queue` 封装**让不同算法可以复用或共享资源；只要 `sched_class->init` 建立需要的数据结构即可。

## 练习二

### 一、对比与修改说明

- `kern/schedule/sched.c`
- 改动点：将调度实现解耦为 `sched_class`，把算法实现放到独立的类中；`run_queue` 增加 `lab6_run_pool` 支持优先队列。
- 为什么要改：提高可扩展性与可维护性，便于新增算法而不修改调度核心；若不改，添加新策略会导致调度核心耦合、逻辑复杂且易出错。

### 二、实现细节
- RR_enqueue(rq, proc)
  - 操作：在运行队列尾部插入，设置 `proc->rq = rq`。
  - 选择链表理由：FIFO 语义简单且 O(1) 插入/删除，满足 RR 公平轮转需求。
  - 边界处理：插入前确认 `proc->rq == NULL`，在并发环境需在禁中断或持锁下执行。

- RR_dequeue(rq, proc)
  - 操作：从链表删除，清空 `proc->rq`。
  - 边界处理：若 `proc` 不在任何队列（`proc->rq == NULL`），应安全返回避免双重删除。

- RR_pick_next(rq)
  - 操作：取队头作为下一运行进程；在返回前不改变队列结构。
  - 处理空队列：返回 NULL，最终由 `schedule()` 选择 `idleproc`。

- RR_proc_tick(rq, proc)
  - 操作：每 tick 将 `proc->time_slice--`；若 <=0 则设置 `proc->need_resched = 1`。
  - 设计理由：在中断上下文只标记需调度，真实上下文切换由 `schedule()` 在安全点完成，避免嵌套切换或中断上下文复杂性。

### 三、关键代码说明与边界处理
- 使用 `list_add_tail` 保证 FIFO 顺序；使用 `list_del` 做恒定时间删除。
- 在 `proc_run` 切换时必须先 `lsatp(next->pgdir)` 切换页表，然后 `switch_to`，并在切换前后用 `local_intr_save/restore` 保护中断安全。
- `alloc_proc()` 中必须初始化调度相关字段：`time_slice`、`lab6_stride`、`lab6_priority`，否则在 enqueue/pick_next 时可能出现未定义行为。

### 四、测试输出
- 关键信息节选：
```
sched class: RR_scheduler
kernel_execve: pid = 2, name = "priority".
set priority to 6
main: fork ok,now need to wait pids.
set priority to 1
set priority to 2
set priority to 3
set priority to 4
set priority to 5
...（多次 proc_run 切换）...
100 ticks
child pid 7, acc 1168000, time 2010
child pid 3, acc 1256000, time 2020
... 
main: wait pids over
sched result: 1 1 1 1 1
all user-mode processes have quit.
init check memory pass.
Total Score: 50/50
```
- 观察：QEMU 输出显示进程在 pid 3..7 间轮转，时间片由 `proc_tick` 管理，最终统计显示公平性近似，测试通过。

### 五、RR 的优势/局限与时间片调整策略 
- 优点：实现简单、对 CPU-bound 进程公平、易于理解与维护。
- 缺点：不考虑优先级与 I/O 需求；时间片选取权衡上下文切换开销与响应性。
- 时间片调整：
  - 增大时间片：减少上下文切换开销，适合吞吐优化；
  - 减小时间片：提高交互任务响应性，但增加切换开销。
- 为什么设置 `need_resched`：在 tick 用标志通知需要抢占，避免在中断处理里直接做完整切换，以保持中断路径简单且安全。

### 六、拓展思考：优先级 RR & 多核支持 
- 优先级 RR 的改动要点：
  - 可采用多队列，调度时优先级高队列优先发放时间片；
  - 或通过为进程分配基于优先级的时间片长度，在 `proc_tick`/`pick_next` 中考虑权重；
  - 需要实现 aging 或防止低优先级饿死的机制。
- 多核支持可行性：
  - 当前实现面向单核；
  - 要支持多核需改进：每核维护独立 runqueue、增加自旋锁/原子更新、实现跨核唤醒与负载均衡。

## Challenge 1: 实现 Stride Scheduling 调度算法

### 1. 多级反馈队列概要设计

维护若干优先级的 `run_queue`（优先级越高时间片越短），每级可用 RR 运行。整体思路是优先做短作业，长作业会被下放。

新建/被唤醒的进程入最高级，时间片耗尽的进程降级到下一队列，说明这个进程用时较长，需要下放。长期未运行的进程可按 aging 机制提升，避免饥饿。

选择策略：`pick_next` 从最高非空队列取队头；`proc_tick` 扣时间片并决定是否降级。

关键点：按级别设定不同时间片；用定期扫描或时间戳实现 aging；每级队列独立锁/禁中断保护。

### 2. 每个进程分配到的时间片数目和优先级成正比的证明

我们定义步幅 `pass = BIG_STRIDE / priority`，每次被调度后 `stride += pass`。

将调度次数记为 `k_i`，有 `stride_i ≈ k_i * (BIG_STRIDE/pri_i)`。由于选取最小 `stride`，各进程的 `stride` 差保持在一个常数级，故 `k_i / pri_i ≈ k_j / pri_j`，即运行次数与优先级成正比。

### 3. Stride调度算法实现过程

首先讲思路，其实就是在 RR 调度算法基础上，加入了优先级 `priority` 的概念。对于每个进程累计`pass = BIG_STRIDE / priority` 到 `stride` 中，每次取 `stride` 最小的那个进程。由于 `pass` 与 `priority` 呈反比，而 `BIG_STRIDE` 是固定的一个大常数，所以高优先级的进程 `stride` 累计速度更慢，更容易被取出，实现优先级。

在实现过程中首先需要讲调度类切换，在 `kern/schedule/sched.c` 中，将 `sched_class` 设为 `stride_sched_class`，启动时打印 `stride_scheduler`。

数据结构：`run_queue` 增加 `lab6_run_pool` 作为 skew-heap 根，即优先队列，进程结构包含 `lab6_run_pool` 节点、`lab6_stride`、`lab6_priority`。

关键函数（`kern/schedule/default_sched_stride.c`）：

`stride_init`：初始化 run_list、`lab6_run_pool=NULL`、`proc_num=0`。

`stride_enqueue`：校正时间片（为 0 或超上限则重置），优先级兜底为 1，然后用 `skew_heap_insert` 入队，`proc_num++`。

`stride_dequeue`：断言归属，`skew_heap_remove` 删除节点，`proc_num--`，清空 `proc->rq`。

`stride_pick_next`：堆空返回 NULL；否则取堆根进程，更新 `lab6_stride += BIG_STRIDE/priority` 后返回。

`stride_proc_tick`：idle 直接置 `need_resched`；普通进程时间片递减，耗尽则置 `need_resched=1`。

测试观察：`sched result` 序列倾向高优进程，表明 stride 生效。

### 4. 两个提问

**提问1：如何证明STRIDE_MAX – STRIDE_MIN <= PASS_MAX**

非常好证明，因为每次会取 `STRIDE_MIN` ，最多加上一个 `PASS_MAX`。而 `STRIDE_MAX` 必然也是在之前小于等于 `STRIDE_MIN` 的时候，加上了一个 `pass = BIG_STRIDE / priority` ，变成了 `STRIDE_MAX`。即 `STRIDE_MAX – PASS_MAX <= STRIDE_MIN`，移项即可获得证明式。

而 `pass` 最大即是当 `priority = 1` 的时候，所以我们顺便还可以推出 **STRIDE_MAX – STRIDE_MIN <= BIG_STRIDE**.

**提问2：在 ucore 中，目前Stride是采用无符号的32位整数表示。则BigStride应该取多少，才能保证比较的正确性？**

这个问题相当有趣，所以我一定要写上一写。

由于Stride是采用无符号的32位整数表示，那么溢出之后的数字，自然会比即将溢出的数字小，直接比较数值就会出错。

巧的是我们可以利用提问1中推出的 `STRIDE_MAX – STRIDE_MIN <= BIG_STRIDE` 来解决这个问题。

首先必须要说明的是，` STRIDE_MAX` 并不是数值最大的那个 stride，而是目前累加 `pass = BIG_STRIDE / priority` 最多的那个。因为在 ucore 中，Stride 是采用无符号的32位整数表示，可能会有溢出。

我们判断两个进程谁的 `stride` 积累更多，就是通过二者相减，将二者之差转为32位的有符号整数，比较正负。有趣之点在于为什么要将二者之差转换为32位的有符号整数，比较正负，下面我们来说明一下。

如果这样做，需要有两个性质：

1. `STRIDE_MAX – STRIDE_MIN <= BIG_STRIDE <= 0x7FFFFFFF`，因为要求大数减小数转换成有符号整数后为正。
2. `STRIDE_MIN – STRIDE_MAX > 0x7FFFFFFF`，因为要求小数减大数转换成有符号整数后为负，即需要超过 $2^{31}-1$。

以上两个不等式均在无符号的32位整数间计算，遵循自然溢出。

如果我们将第二条转换为有符号的正常计算，则可以简单表示为 $\text{STRIDE_MIN}\ –\ \text{STRIDE_MAX} + 2^{32}> 2^{31}-1$。

最终得到 $\text{STRIDE_MAX}\ -\ \text{STRIDE_MIN}<2^{31}+1$。

当然和性质1合并之后就得到 $\text{STRIDE_MAX}\ -\ \text{STRIDE_MIN}\le \text{BIG_STRIDE}\le 2^{31}-1<2^{31}+1$。

看上去性质2毫无作用，但事实上这是一个保险，能够确保数值上较小的那个数字减去较大的数字，在转换成有符号数之后，**一定**是个负数。而在指导书中没有提到。

显然，`BIG_STRIDE` 最大取到 $2^{31}-1$，本实验中我取值为 $2^{30}$。当然，如果取小了会导致 `pass` 难以区分不同的 `priority`，不再赘述。