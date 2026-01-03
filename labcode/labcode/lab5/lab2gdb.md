# Lab2 分支任务：GDB 调试页表查询过程

## 一、实验目的

通过 GDB 调试 QEMU 源码，深入理解 RISC-V SV39 页表查询（Page Table Walk）的具体实现过程，观察虚拟地址到物理地址转换的每一个步骤。

## 二、实验环境

- QEMU 4.1.1（模拟 RISC-V 64 位处理器）
- GDB（用于调试 QEMU 进程和 ucore 内核）
- ucore 操作系统（lab2）

## 三、实验原理

### 1. SV39 页表结构

RISC-V SV39 采用三级页表结构，虚拟地址格式如下：

```
63    39 38    30 29    21 20    12 11        0
+-------+--------+--------+--------+-----------+
| 保留  | VPN[2] | VPN[1] | VPN[0] |  Offset   |
+-------+--------+--------+--------+-----------+
  25位     9位      9位      9位       12位
```

- **VPN[2]**: 一级页表索引（9位）
- **VPN[1]**: 二级页表索引（9位）
- **VPN[0]**: 三级页表索引（9位）
- **Offset**: 页内偏移（12位）

### 2. 页表项（PTE）格式

```
63    54 53    10 9   8 7 6 5 4 3 2 1 0
+-------+--------+-----+-+-+-+-+-+-+-+-+
|保留   |  PPN   |RSW  |D|A|G|U|X|W|R|V|
+-------+--------+-----+-+-+-+-+-+-+-+-+
```

关键标志位：
- **V (Valid)**: 有效位
- **R (Read)**: 可读
- **W (Write)**: 可写
- **X (Execute)**: 可执行
- **U (User)**: 用户态可访问

## 四、实验步骤

### 1. 搭建三终端调试环境

本实验需要同时调试两个层次：QEMU 模拟器本身（C 代码）和运行在 QEMU 中的 ucore 内核（RISC-V 代码）。因此需要三个终端协同工作。

#### 终端1：启动 QEMU 模拟器

```bash
cd /root/OS/labcode/lab2
make debug
```

启动 QEMU 并开启 GDB 远程调试端口，等待调试器连接。此时 QEMU 处于暂停状态，ucore 尚未开始执行。

#### 终端2：GDB 附加到 QEMU 进程

```bash
# 首先获取 QEMU 进程的 PID
pgrep -f qemu-system-riscv64
# 输出: 21827
```

找到 QEMU 进程的 PID，以便后续 GDB 附加。

```bash
# 启动 GDB 并附加到 QEMU 进程
sudo gdb
(gdb) attach 21827
```

将 GDB 附加到 QEMU 进程，这样我们就可以调试 QEMU 的 C 源码，观察它如何模拟 RISC-V CPU 的页表查询过程。

```bash
(gdb) handle SIGPIPE nostop noprint
```

忽略 SIGPIPE 信号，避免调试过程中因管道信号导致的干扰。

#### 终端3：RISC-V GDB 调试 ucore 内核

```bash
cd /root/OS/labcode/lab2
make gdb
```

启动 RISC-V 架构的 GDB，连接到 QEMU 的远程调试端口，用于调试 ucore 内核代码。

```bash
(gdb) b kern_init
(gdb) c
```

在 `kern_init` 函数设置断点并继续执行。当 ucore 启动并执行到 `kern_init` 时会暂停，这是我们观察页表查询的起点。

### 2. 定位内存访问指令

当终端3停在 `kern_init` 断点时，我们需要找到一条会触发内存访问的指令：

```gdb
(gdb) x/10i $pc
=> 0xffffffffc02000d6 <kern_init>:      auipc   a0,0x5
   0xffffffffc02000da <kern_init+4>:    addi    a0,a0,-190
   ...
   0xffffffffc02000ec <kern_init+22>:   sd      ra,8(sp)   <-- 目标指令
```

找到一条访存指令。`sd ra,8(sp)` 是一条存储指令，会将 `ra` 寄存器的值写入内存地址 `sp+8`。执行这条指令时，CPU 需要将虚拟地址转换为物理地址，这正是我们要观察的页表查询过程。

### 3. 在 QEMU 中设置页表查询断点

切换到终端2，在 QEMU 的页表查询函数设置断点：

```gdb
(gdb) b get_physical_address
Breakpoint 3 at 0x5590a1961bb5: file /root/OS/qemu-4.1.1/target/riscv/cpu_helper.c, line 158.
(gdb) c
```

`get_physical_address` 是 QEMU 中负责模拟 RISC-V MMU 页表查询的核心函数。当 ucore 执行任何需要地址转换的操作时，QEMU 都会调用此函数。设置断点后，我们就能在页表查询发生时暂停并观察。

### 4. 触发页表查询

切换到终端3，执行单步指令：

```gdb
(gdb) si
```

单步执行一条 RISC-V 指令。由于每条指令的取指和执行都可能涉及内存访问，这会触发 QEMU 调用 `get_physical_address` 进行地址转换。

### 5. 观察页表查询的输入参数

终端2命中断点后，首先查看调用栈和函数参数：

```gdb
(gdb) bt
#0  get_physical_address (env=0x5590d34389a0, physical=0x7ffe28319bb8,
    prot=0x7ffe28319bb0, addr=18446744072637907158, access_type=0, mmu_idx=1)
    at /root/OS/qemu-4.1.1/target/riscv/cpu_helper.c:158
...
```

查看调用栈，了解是什么操作触发了页表查询。从调用栈可以看到这是一次地址转换请求。

```gdb
(gdb) p/x addr
$1 = 0xffffffffc02000d6
```

查看待转换的虚拟地址。`0xffffffffc02000d6` 正是 `kern_init` 函数的地址，说明这是一次**取指令**操作触发的地址转换。

```gdb
(gdb) p access_type
$2 = 0
```

查看访问类型。`access_type=0` 表示 `MMU_INST_FETCH`（取指令），验证了我们的判断。

```gdb
(gdb) p mmu_idx
$3 = 1
```

查看当前特权级。`mmu_idx=1` 表示 S-mode（内核态），说明当前 ucore 正在内核态执行。

### 6. 单步跟踪页表遍历过程

接下来逐行执行，观察页表查询的每个步骤：

#### 步骤1：确定当前特权模式

```gdb
(gdb) n
163         int mode = mmu_idx;
(gdb) n
165         if (mode == PRV_M && access_type != MMU_INST_FETCH) {
(gdb) n
171         if (mode == PRV_M || !riscv_feature(env, RISCV_FEATURE_MMU)) {
```

检查当前特权级和 MMU 状态。如果是 M-mode 或 MMU 未启用，则直接使用物理地址（恒等映射）。当前是 S-mode 且 MMU 已启用，所以需要进行页表查询。

#### 步骤2：获取页表基址和模式

```gdb
(gdb) n
184             base = get_field(env->satp, SATP_PPN) << PGSHIFT;
```

从 `satp` 寄存器提取页表基址。`satp` 寄存器存储了一级页表的物理页号（PPN），左移 12 位（PGSHIFT）得到物理基址。这是页表遍历的起点。

```gdb
(gdb) n
186             vm = get_field(env->satp, SATP_MODE);
(gdb) n
187             switch (vm) {
(gdb) n
191               levels = 3; ptidxbits = 9; ptesize = 8; break;
```

从 `satp` 寄存器提取页表模式。结果显示使用 **SV39** 模式：
- `levels = 3`：三级页表
- `ptidxbits = 9`：每级索引占 9 位（512 个表项）
- `ptesize = 8`：每个 PTE 占 8 字节（64位）

#### 步骤3：计算虚拟地址位数并验证地址合法性

```gdb
(gdb) n
224         int va_bits = PGSHIFT + levels * ptidxbits;
```

计算虚拟地址有效位数。`va_bits = 12 + 3*9 = 39`，即 SV39 的 39 位虚拟地址空间。

```gdb
(gdb) n
225         target_ulong mask = (1L << (TARGET_LONG_BITS - (va_bits - 1))) - 1;
(gdb) n
226         target_ulong masked_msbs = (addr >> (va_bits - 1)) & mask;
(gdb) n
227         if (masked_msbs != 0 && masked_msbs != mask) {
```

检查虚拟地址的高位符号扩展是否正确。SV39 要求第 39-63 位必须与第 38 位相同（符号扩展）。地址 `0xffffffffc02000d6` 的高位全为 1，符合要求。

#### 步骤4：初始化页表遍历循环

```gdb
(gdb) n
231         int ptshift = (levels - 1) * ptidxbits;
```

计算第一级 VPN 的位移量。`ptshift = 2*9 = 18`，表示 VPN[2] 从虚拟地址的第 30 位开始（12 + 18 = 30）。

```gdb
(gdb) n
237         for (i = 0; i < levels; i++, ptshift -= ptidxbits) {
```

开始三级页表遍历循环。每次迭代处理一级页表，`ptshift` 每次减 9，依次处理 VPN[2]、VPN[1]、VPN[0]。

#### 步骤5：计算页表索引

```gdb
(gdb) n
238             target_ulong idx = (addr >> (PGSHIFT + ptshift)) &
(gdb) n
239                                ((1 << ptidxbits) - 1);
```

提取当前级别的 VPN 索引。对于第一级：
- `addr >> (12 + 18)` = `addr >> 30`：右移到 VPN[2] 位置
- `& 0x1FF`：取低 9 位作为索引

#### 步骤6：计算 PTE 物理地址

```gdb
(gdb) n
242             target_ulong pte_addr = base + idx * ptesize;
```

计算页表项的物理地址。`pte_addr = base + idx * 8`，即页表基址加上索引乘以 PTE 大小（8字节）。

#### 步骤7：读取页表项

```gdb
(gdb) n
252             target_ulong pte = ldq_phys(cs->as, pte_addr);
```

从物理内存读取 64 位页表项（PTE）。`ldq_phys` 函数直接访问物理地址，读取 8 字节数据。这是页表查询的核心操作。

#### 步骤8：提取物理页号

```gdb
(gdb) n
254             target_ulong ppn = pte >> PTE_PPN_SHIFT;
```

从 PTE 中提取物理页号（PPN）。PPN 位于 PTE 的第 10-53 位，右移 10 位即可得到。

#### 步骤9：检查 PTE 有效性和类型

```gdb
(gdb) n
256             if (!(pte & PTE_V)) {
```

检查 PTE 的 V（Valid）位。如果 V=0，说明该页表项无效，返回转换失败。

```gdb
(gdb) n
259             } else if (!(pte & (PTE_R | PTE_W | PTE_X))) {
```

检查是否为非叶子节点。如果 R=W=X=0，说明这是一个指向下一级页表的指针，需要继续遍历。此时会执行 `base = ppn << PGSHIFT`，将 PPN 作为下一级页表的基址。

```gdb
(gdb) n
262             } else if ((pte & (PTE_R | PTE_W | PTE_X)) == PTE_W) {
(gdb) n
265             } else if ((pte & (PTE_R | PTE_W | PTE_X)) == (PTE_W | PTE_X)) {
(gdb) n
268             } else if ((pte & PTE_U) && ((mode != PRV_U) &&
(gdb) n
273             } else if (!(pte & PTE_U) && (mode != PRV_S)) {
```

进行一系列权限检查：
- 第 262 行：检查是否为非法的"仅可写"组合（W=1, R=0, X=0）
- 第 265 行：检查是否为非法的"可写可执行"组合（W=1, X=1, R=0）
- 第 268 行：检查用户页在非用户态的访问权限
- 第 273 行：检查内核页在用户态的访问权限

## 五、关键代码分析

### get_physical_address 函数核心逻辑

```c
static int get_physical_address(CPURISCVState *env, hwaddr *physical,
                                int *prot, target_ulong addr,
                                int access_type, int mmu_idx)
{
    // 1. 获取页表配置（从 satp 寄存器）
    base = get_field(env->satp, SATP_PPN) << PGSHIFT;  // 页表基址
    vm = get_field(env->satp, SATP_MODE);              // 页表模式

    // 2. 根据模式设置参数（SV39: 3级页表，每级9位索引，8字节PTE）
    levels = 3; ptidxbits = 9; ptesize = 8;

    // 3. 三级页表遍历循环
    for (i = 0; i < levels; i++, ptshift -= ptidxbits) {
        // 3.1 计算当前级别的 VPN 索引
        idx = (addr >> (PGSHIFT + ptshift)) & ((1 << ptidxbits) - 1);

        // 3.2 计算 PTE 的物理地址
        pte_addr = base + idx * ptesize;

        // 3.3 从物理内存读取 PTE
        pte = ldq_phys(cs->as, pte_addr);
        ppn = pte >> PTE_PPN_SHIFT;

        // 3.4 检查 PTE 并决定下一步操作
        if (!(pte & PTE_V)) {
            return TRANSLATE_FAIL;           // 无效页表项
        } else if (!(pte & (PTE_R | PTE_W | PTE_X))) {
            base = ppn << PGSHIFT;           // 非叶子节点，继续遍历
        } else {
            // 叶子节点：检查权限，计算物理地址
            *physical = (ppn << PGSHIFT) | (addr & ((1 << PGSHIFT) - 1));
            return TRANSLATE_SUCCESS;
        }
    }
}
```

## 六、实验问题回答

### 问题1：给出关键的调用路径，以及路径上的关键分支语句

#### 完整调用路径

当 ucore 执行一条访存指令时，QEMU 的调用路径如下：

```
CPU 执行循环
    │
    ▼
cpu_exec() [accel/tcg/cpu-exec.c]
    │
    ├─→ 首先查找软件 TLB（快速路径）
    │   tlb_hit() 检查 TLB 是否命中
    │       │
    │       ├─ 命中：直接返回物理地址（无需页表遍历）
    │       │
    │       └─ 未命中：进入慢速路径
    │
    ▼
tlb_fill() [通过 riscv_cpu_tlb_fill 实现]
    │
    ▼
riscv_cpu_tlb_fill() [target/riscv/cpu_helper.c:435]
    │
    ├─→ 调用 get_physical_address() 进行页表遍历
    │
    ├─→ 如果成功，调用 tlb_set_page() 填充软件 TLB
    │
    └─→ 如果失败，调用 raise_mmu_exception() 触发异常

    ▼
get_physical_address() [target/riscv/cpu_helper.c:158]
    │
    ├─→ 检查特权模式和 MMU 状态
    │   if (mode == PRV_M || !MMU_enabled) → 直接返回物理地址
    │
    ├─→ 从 satp 获取页表基址和模式
    │   switch (vm) 选择 SV32/SV39/SV48
    │
    └─→ for 循环遍历页表
        │
        ├─→ 计算 VPN 索引和 PTE 地址
        ├─→ ldq_phys() 读取 PTE
        └─→ 检查 PTE 标志位
            if (!(pte & PTE_V)) → 无效
            else if (R=W=X=0) → 继续遍历下一级
            else → 叶子节点，完成转换
```

#### 关键分支语句

1. **特权模式检查**（cpu_helper.c:171）：
```c
if (mode == PRV_M || !riscv_feature(env, RISCV_FEATURE_MMU)) {
    *physical = addr;  // M-mode 或 MMU 未启用，直接使用物理地址
    return TRANSLATE_SUCCESS;
}
```

2. **页表模式选择**（cpu_helper.c:187-202）：
```c
switch (vm) {
case VM_1_10_SV39:
    levels = 3; ptidxbits = 9; ptesize = 8; break;  // 选择 SV39
case VM_1_10_MBARE:
    *physical = addr;  // 无分页模式
    return TRANSLATE_SUCCESS;
}
```

3. **PTE 类型判断**（cpu_helper.c:256-261）：
```c
if (!(pte & PTE_V)) {
    return TRANSLATE_FAIL;  // 无效 PTE
} else if (!(pte & (PTE_R | PTE_W | PTE_X))) {
    base = ppn << PGSHIFT;  // 非叶子节点，更新基址继续遍历
} else {
    // 叶子节点，进行权限检查...
}
```

### 问题2：解释页表翻译的关键操作流程

#### 三级循环的作用

```c
for (i = 0; i < levels; i++, ptshift -= ptidxbits) {
```

这个循环遍历 SV39 的三级页表。每次迭代：
- `i` 表示当前级别（0=一级，1=二级，2=三级）
- `ptshift` 控制从虚拟地址中提取哪一段 VPN：
  - 第一次：`ptshift=18`，提取 VPN[2]（bit 38-30）
  - 第二次：`ptshift=9`，提取 VPN[1]（bit 29-21）
  - 第三次：`ptshift=0`，提取 VPN[0]（bit 20-12）

#### 从当前页表取出页表项

```c
target_ulong idx = (addr >> (PGSHIFT + ptshift)) & ((1 << ptidxbits) - 1);
target_ulong pte_addr = base + idx * ptesize;
target_ulong pte = ldq_phys(cs->as, pte_addr);
```

这三行代码的作用：

1. **计算索引**：`idx = (addr >> (12 + ptshift)) & 0x1FF`
   - 将虚拟地址右移到对应 VPN 位置
   - 与 0x1FF（9位掩码）取低 9 位作为索引

2. **计算 PTE 地址**：`pte_addr = base + idx * 8`
   - `base` 是当前级别页表的物理基址
   - `idx * 8` 是偏移量（每个 PTE 8 字节）

3. **读取 PTE**：`ldq_phys()` 从物理内存读取 64 位数据
   - 这是真正的"查表"操作
   - 直接访问物理地址，不经过 MMU

#### 地址翻译流程图

```
虚拟地址: 0xffffffffc02000d6
         │
         ▼
┌────────────────────────────────────────────────┐
│  提取 VPN[2] = (addr >> 30) & 0x1FF            │
│  计算 PTE1 地址 = satp.PPN << 12 + VPN[2] * 8  │
│  读取 PTE1，获取二级页表基址                    │
└────────────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────────┐
│  提取 VPN[1] = (addr >> 21) & 0x1FF            │
│  计算 PTE2 地址 = PTE1.PPN << 12 + VPN[1] * 8  │
│  读取 PTE2，获取三级页表基址                    │
└────────────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────────┐
│  提取 VPN[0] = (addr >> 12) & 0x1FF            │
│  计算 PTE3 地址 = PTE2.PPN << 12 + VPN[0] * 8  │
│  读取 PTE3，获取物理页号 PPN                    │
└────────────────────────────────────────────────┘
         │
         ▼
物理地址 = (PTE3.PPN << 12) | (addr & 0xFFF)
```

### 问题3：QEMU 中模拟 TLB 查找的代码

#### TLB 查找代码位置

QEMU 使用软件模拟的 TLB，相关代码在 `accel/tcg/cputlb.c` 中：

```c
// cputlb.c:1030 - 取指令时的 TLB 查找
tb_page_addr_t get_page_addr_code(CPUArchState *env, target_ulong addr)
{
    uintptr_t mmu_idx = cpu_mmu_index(env, true);
    uintptr_t index = tlb_index(env, mmu_idx, addr);
    CPUTLBEntry *entry = tlb_entry(env, mmu_idx, addr);

    // 首先检查主 TLB 是否命中
    if (unlikely(!tlb_hit(entry->addr_code, addr))) {
        // 主 TLB 未命中，检查 victim TLB
        if (!VICTIM_TLB_HIT(addr_code, addr)) {
            // victim TLB 也未命中，调用 tlb_fill 进行页表遍历
            tlb_fill(env_cpu(env), addr, 0, MMU_INST_FETCH, mmu_idx, 0);
        }
    }
    // TLB 命中，直接返回物理地址
    ...
}
```

```c
// cputlb.c:1271 - 数据访问时的 TLB 查找
if (!tlb_hit(tlb_addr, addr)) {
    // 主 TLB 未命中
    if (!victim_tlb_hit(env, mmu_idx, index, tlb_off, addr & TARGET_PAGE_MASK)) {
        // victim TLB 也未命中，进行页表遍历
        tlb_fill(env_cpu(env), addr, size, access_type, mmu_idx, retaddr);
    }
}
```

#### TLB 命中检查

```c
// include/exec/cpu_ldst.h 中的 tlb_hit 宏
static inline bool tlb_hit(target_ulong tlb_addr, target_ulong addr)
{
    return (addr & TARGET_PAGE_MASK) == (tlb_addr & ~TLB_FLAGS_MASK);
}
```

这个函数比较虚拟地址的页号部分是否与 TLB 条目中缓存的地址匹配。

#### Victim TLB

QEMU 实现了一个小型的 victim TLB，当主 TLB 条目被替换时，旧条目会移到 victim TLB：

```c
// cputlb.c:977
static bool victim_tlb_hit(CPUArchState *env, size_t mmu_idx, size_t index,
                           size_t elt_ofs, target_ulong page)
{
    for (vidx = 0; vidx < CPU_VTLB_SIZE; ++vidx) {
        CPUTLBEntry *vtlb = &env_tlb(env)->d[mmu_idx].vtable[vidx];
        if (cmp == page) {
            // 在 victim TLB 中找到，交换回主 TLB
            swap(tlb, vtlb);
            return true;
        }
    }
    return false;
}
```

#### TLB 填充

当 TLB 未命中时，`riscv_cpu_tlb_fill` 会被调用：

```c
// target/riscv/cpu_helper.c:435
bool riscv_cpu_tlb_fill(CPUState *cs, vaddr address, int size,
                        MMUAccessType access_type, int mmu_idx,
                        bool probe, uintptr_t retaddr)
{
    // 调用 get_physical_address 进行页表遍历
    ret = get_physical_address(env, &pa, &prot, address, access_type, mmu_idx);

    if (ret == TRANSLATE_SUCCESS) {
        // 页表遍历成功，将结果填入 TLB
        tlb_set_page(cs, address & TARGET_PAGE_MASK, pa & TARGET_PAGE_MASK,
                     prot, mmu_idx, TARGET_PAGE_SIZE);
        return true;
    }
    // 失败则触发异常
    ...
}
```

### 问题4：QEMU 模拟的 TLB 与真实 CPU TLB 的区别

#### 真实 CPU 的 TLB

1. **硬件实现**：TLB 是 CPU 内部的硬件缓存，由专用电路实现
2. **全相联/组相联**：通常使用 CAM（内容寻址存储器）实现并行查找
3. **TLB Miss 处理**：
   - 硬件自动进行页表遍历（Hardware Page Table Walk）
   - 或触发 TLB Miss 异常由软件处理（Software TLB Refill）
4. **访问延迟**：1-2 个时钟周期

#### QEMU 软件模拟的 TLB

1. **软件实现**：用 C 语言的数组和哈希表模拟
2. **直接映射**：使用虚拟地址的部分位作为索引
   ```c
   index = (addr >> TARGET_PAGE_BITS) & (CPU_TLB_SIZE - 1);
   ```
3. **TLB Miss 处理**：总是由软件（`get_physical_address`）进行页表遍历
4. **访问延迟**：数十到数百个时钟周期（因为是软件模拟）

#### 关键区别对比

| 特性 | 真实 CPU TLB | QEMU 软件 TLB |
|------|------------|--------------|
| 实现方式 | 硬件电路 | 软件数组 |
| 查找方式 | 并行比较（CAM） | 哈希索引 |
| 容量 | 几十到几百条目 | 可配置，默认 256 条 |
| Miss 处理 | 硬件页表遍历 | 软件页表遍历 |
| ASID 支持 | 硬件标签 | 软件模拟 |

#### 未开启虚拟地址空间时的对比

当 MMU 未启用时（如 M-mode 或 `satp.MODE=Bare`）：

**真实 CPU**：
- TLB 被旁路，虚拟地址直接作为物理地址使用
- 不进行任何地址转换

**QEMU 模拟**：
- 仍然会查找软件 TLB（为了代码统一性）
- 但 `get_physical_address` 会直接返回：
  ```c
  if (mode == PRV_M || vm == VM_1_10_MBARE) {
      *physical = addr;  // 恒等映射
      return TRANSLATE_SUCCESS;
  }
  ```
- TLB 中存储的是恒等映射（虚拟地址 = 物理地址）

这种设计让 QEMU 可以用统一的代码路径处理所有内存访问，简化了实现，但牺牲了一些性能。
