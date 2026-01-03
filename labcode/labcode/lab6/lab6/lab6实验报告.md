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

