# Lab2
## 练习1：理解first-fit 连续物理内存分配算法(思考题)
### 算法思想
初始化时建立空闲链表并登记可用内存块；当需要分配时，从链表头开始顺序查找，找到第一个大小不小于请求页数的空闲块进行分配，若块过大则拆分并保留剩余部分；释放时将归还的页按地址顺序插入链表，并与相邻空闲块合并，保证空闲内存尽可能连续。
### 代码分析
#### default_init
```c
static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
}
```
该函数的作用是初始化first-fit管理器。

实现过程为首先调用 list_init(&free_list) 初始化空闲链表free_list为一个空的双向链表，然后将总空闲页数 nr_free 设置为 0。

#### default_init_memmap
```c
default_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
}
```
该函数的作用是初始化一块连续物理页(（base 开始、长度 n）)作为初始空闲内存块，并将其加入到空闲链表 free_list 中。

实现过程为：首先遍历从 base 开始的 n 个物理页，为每页设置 flags = 0 (清除 PG_reserved 位，表示非保留)，property = 0 (只有块头才记录块大小)，ref = 0 (页引用计数)。

然后设置该空闲块的第一页 (base) 的 property 为块的总页数 n，并设置其 PG_property 标志，表示它是空闲块的起始页。
再将总空闲页数 nr_free 增加 n。

最后将该空闲块（通过 base->page_link）按地址顺序插入到 free_list 中。

#### default_alloc_pages
```c
default_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
```
该函数的作用是按 first fit 策略分配 n 连续页，返回首页指针；失败返回 NULL。

实现过程如下：首先检查请求的页数 n 是否大于总空闲页数 nr_free，如果是则返回 NULL。然后顺序遍历free_list，寻找第一个满足 p->property >= n 的空闲块 p。

找到后，将该空闲块 p 从 free_list 中移除。如果 p->property > n，说明空闲块大于请求，则将剩余部分作为新的空闲块 (p + n)，更新其 property 并设置 PG_property 标志，然后将新空闲块重新插入到链表中（紧接在原块的前一个节点之后）。

最后更新总空闲页数 nr_free -= n，清除分配块 page 的 PG_property 标志，返回分配块的首地址page。

#### default_free_pages
```c
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;

    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }

    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }

    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}
```
该函数的作用是释放从 base 开始的 n 个连续物理页，并将它们归还给空闲链表。

实现过程如下：首先遍历从 base 开始的 n 个物理页，清除它们的 flags 和 ref。然后在 base 上设置 base->property = n，设置 PG_property 标志，更新总空闲页数 nr_free +=n。

再将释放块 (base) 按地址顺序插入到 free_list 中，同时尝试合并相邻的空闲块。如果释放的页面与前一个页面或后一个页面相邻，会尝试将它们合并为一个更大的空闲块。

#### default_nr_free_pages
```c
default_nr_free_pages(void) {
    return nr_free;
}
```
该函数的作用是获取当前的空闲页面的数量。

最后是两个check函数:  
basic_check函数是用于测试和验证物理内存管理器（PMM）基本功能正确性的一个辅助函数，主要关注分配器最基础的页分配 (alloc_page) 和页释放 (free_page) 操作。  

default_check 函数是用于测试和验证 First-Fit 内存分配算法的特定功能是否正确。它在 basic_check 的基础上，主要关注 First-Fit 算法的：块分配（涉及分割）、块释放（涉及合并）以及查找第一个合适空闲块的逻辑。

### 程序在进行物理内存分配的过程以及各个函数的作用
1.初始化：系统启动时，default_init() 被调用建立空链表。

2.构建空闲区： 通过 default_init_memmap()将可用的物理内存区域初始化为大的空闲块，按地址顺序插入到空闲链表 (free_list) 中。

3.当某模块/内核需分配 n 页：调用 alloc_pages(n)，first-fit 在 free_list 顺序遍历找到第一个可以满足 n 的块。如果找到，则将该空闲块的前 n 页分配出去，并将其从空闲链表中删除。如果该空闲块的原大小大于 n，则将剩余的页作为新的空闲块，更新其大小，并重新插入到链表中。更新 nr_free，返回首页。

4.当释放 n 页时：调用 free_pages(base, n)，将释放的页块标记为新空闲块，更新其大小，并按地址顺序插入到 free_list 中。算法会检查这个新插入的空闲块是否与物理地址相邻的前一个和后一个空闲块连续。如果相邻且连续，则将它们合并成一个更大的空闲块。

#### 改进空间
First-Fit 算法的主要缺点是它会导致外部碎片的积累，并且随着时间推移，空闲列表前部的碎片可能会增多，导致每次分配都需要更长的搜索时间。

所以可以从以下方面改进：  
1.采用优化的内存分配策略，如best-fit、next-fit等等，可以减少外部碎片。  
2.改进空闲块的管理结构，如采用Buddy System，可以提高查找和释放操作的速度。  
3.优化空闲块的合并操作，可以提高算法效率。

## 练习2：实现 Best-Fit 连续物理内存分配算法（需要编程）

### 算法思想

对于 best_fit 方法，其与 first-fit 颇为相似，均为维护一个链表来管理空闲页块，区别是在于 alloc 页快时，first-fit 是取当前第一个满足分配的空闲页块，将这个较大的页块分割之后重新链入页表，而 best-fit 则是选取目前能满足分配条件的最小的一个空闲页块，虽然best-fit 每次在分配时需要完整的遍历一遍链表，时间复杂度上可能不如 first-fit 算法，但 best-fit 对内存利用率更高，其每次分配产生的碎片会更少，这样的结果就会方便后续的内存申请，方便后续的请求，自然提高了内存的利用率。

### 代码修改

---

#### 函数：best_fit_init_memmap:

这个函数参考 first_fit，我们要将 n 个页初始化挂进链表当中，首先要做的是清除当前页框的标志和属性信息，将其引用计数器设置为 0，并将 base 这个页块的首页打上这里有 n 个页的信息，最后在总的空闲页计数器上加上 n。在链入时，根据地址排序，这方便合成大块，同时注意这个双向链表的末尾，若已经到头了，就把当前 base 链到最后面。

~~~
static void
best_fit_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));
        /*LAB2 EXERCISE 2: 2314007*/ 
        // 清空当前页框的标志和属性信息，并将页框的引用计数设置为0
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            /*LAB2 EXERCISE 2: 2314007*/ 
            // 编写代码
            // 1、当base < page时，找到第一个大于base的页，将base插入到它前面，并退出循环
            // 2、当list_next(le) == &free_list时，若已经到达链表结尾，将base插入到链表尾部
                if (base < page) {
                    list_add_before(le, &(base->page_link));
                    break;
                } else if (list_next(le) == &free_list) {
                    list_add(le, &(base->page_link));
                    break;
                }

        }
    }
}
~~~

#### 函数：best_fit_alloc_pages 

这个函数就是与 first-fit 最大区别之所在，在这里我们设定临时变量 min_size 和 page 去遍历一遍找到目前符合分配条件的最小的块：

```###
static struct Page *
best_fit_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    size_t min_size = nr_free + 1;
    /*LAB2 EXERCISE 2: 2314007*/ 
    // 下面的代码是first-fit的部分代码，请修改下面的代码改为best-fit
    // 遍历空闲链表，查找满足需求的空闲页框
    // 如果找到满足需求的页面，记录该页面以及当前找到的最小连续空闲页框数量

    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
   //     if (p->property >= n) {
    //       page = p;
      //      break;
        //}

        if (p->property >= n) {
            if (p->property < min_size) {
                min_size = p->property;
                page = p;
            }
        }
    }

    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return pag
}
```

#### 函数:best_fit_free_pages

这个函数和 first_fit 的 free_pages 区别不大，和 first-fit 一样的将当前页块的属性设置为释放的页块数，并标记当前页块的已分配状态、最后增加 nr_free。同时在这个释放函数中，涉及地址连续的页块的合并，主要的判断依据是前一个节点加上其页数的地址是否为当前 base ，同理后一个节点的地址是为否 base 加上 n，若是，则进行合并。

~~~
static void
best_fit_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    /*LAB2 EXERCISE 2: 2314007*/ 
    // 编写代码
    // 具体来说就是设置当前页块的属性为释放的页块数、并将当前页块标记为已分配状态、最后增加nr_free的值
    base->property = n;
    SetPageProperty(base);
    nr_free += n;

    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }

    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        /*LAB2 EXERCISE 2: 2314007*/ 
        // 编写代码
        // 1、判断前面的空闲页块是否与当前页块是连续的，如果是连续的，则将当前页块合并到前面的空闲页块中
        // 2、首先更新前一个空闲页块的大小，加上当前页块的大小
        // 3、清除当前页块的属性标记，表示不再是空闲页块
        // 4、从链表中删除当前页块
        // 5、将指针指向前一个空闲页块，以便继续检查合并后的连续空闲页块
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }

    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}

~~~



## Challenge1：buddy system(伙伴系统)分配算法(需要编程)
### 算法思想
Buddy System（伙伴系统）是一种动态内存分配算法，它将物理内存按2的幂次方大小划分为若干块（称为“伙伴”），每次分配时寻找能容纳请求的最小2ⁿ 大小的空闲块；若没有合适大小的块，就不断把更大的块对半拆分成两个“伙伴”，直到找到一个刚好能够满足请求；释放时，若某块的“伙伴”也空闲且大小相同，就将两者合并成更大的块，如此递归合并。  
这种方式能在保持较快分配与释放速度的同时，减少外部碎片，并方便快速合并与分割。

### 代码设计
我们的整体设计思路是通过一个数组形式的完全二叉树来监控管理内存，二叉树的节点用于标记相应内存块的使用状态，高层节点对应大的块，低层节点对应小的块，在分配和释放中我们就通过这些节点的标记属性来进行块的分离合并。

我们定义了一个全局结构体 buddy_t，用于记录当前 buddy 系统的状态：
```c
typedef struct {
    unsigned size;         
    unsigned node_count;   
    unsigned *longest;     
    struct Page *base;     
} buddy_t;
```
在该结构体中我们定义了三个属性值：size表示总内存块大小；longest用于存储二叉树的所有节点，每个元素记录了该节点下能分配的最大空闲块大小；node_count代表节点数目。

下面，我们定义一些我们后面需要用到的辅助函数。
```c

#define IS_POWER_OF_2(x)   (!((x) & ((x) - 1)))
```
该函数用于判断一个数是否是2的幂次
```c
static unsigned fix_size(unsigned size) {
    size |= size >> 1;
    size |= size >> 2;
    size |= size >> 4;
    size |= size >> 8;
    size |= size >> 16;
    return size + 1;
}
```
该函数用于向上取最近的2次幂。它的实现方法是将一个数的所有有效位都变成1，然后加1。
```c
#define LEFT_LEAF(i)       ((i) * 2 + 1)
#define RIGHT_LEAF(i)      ((i) * 2 + 2)
#define PARENT(i)          (((i) + 1) / 2 - 1)
```
这三个函数的作用是索引计算，将将完全二叉树存储在数组中，用下标表示关系（left表示左子节点，right表示右子节点，parent表示父节点）：  
left(i)=2i+1, right(i)=2i+2，parent(i)=(i+1)/2 - 1

然后我们的重点是定义初始化函数、内存分配函数以及释放函数。
```c
static void buddy_init(void) {
    cprintf("[buddy_init] 初始化 Buddy System 物理内存管理器\n");
    memset(&buddy, 0, sizeof(buddy));
}
```
该函数的作用是初始化全局 buddy 结构体，清零所有状态，对应 uCore 的 pmm_manager.init() 接口。
```c
static void buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    buddy.base = base;

    if (!IS_POWER_OF_2(n))
        n = fix_size(n);
    buddy.size = n;
    buddy.node_count = 2 * n - 1;

    static unsigned buddy_longest_array[65536];
    
    buddy.longest = buddy_longest_array;
    memset(buddy.longest, 0, sizeof(unsigned) * buddy.node_count);

    unsigned node_size = n;
    buddy.longest[0] = node_size;
    for (unsigned i = 1; i < buddy.node_count; ++i) {
        if (IS_POWER_OF_2(i + 1))
            node_size /= 2;
        buddy.longest[i] = node_size;
    }

}
```
该函数为初始化buddy树函数  
首先对size_大小的合法性进行检查，并将其向上取整到最近的2次幂，然后对longest数组进行初始化，longest[0]表示根节点，大小为size_, 层级每增加一层，节点大小减半。  

为什么数组初始化大小要设置为65536，因为我们通过make qemu输出可以得到物理内存大小为128MB，而每页内存为4KB，相除可得页数为32678即longest[0]=32678。然后我们计算二叉树节点个数：count=2*32678-1=65535，不妨向上取到最近2次幂65536。
```c
static struct Page *buddy_alloc_pages(size_t n) {
    if (n == 0) n = 1;
    if (!IS_POWER_OF_2(n))
        n = fix_size(n);

    unsigned index = 0;
    unsigned node_size = buddy.size;

    if (buddy.longest[index] < n)
        return NULL;

    while (node_size != n) {
        if (buddy.longest[LEFT_LEAF(index)] >= n)
            index = LEFT_LEAF(index);
        else
            index = RIGHT_LEAF(index);
        node_size /= 2;
    }

    buddy.longest[index] = 0;
    unsigned offset = (index + 1) * node_size - buddy.size;

    while (index) {
        index = PARENT(index);
        buddy.longest[index] =
            MAX(buddy.longest[LEFT_LEAF(index)], buddy.longest[RIGHT_LEAF(index)]);
    }

    struct Page *page = buddy.base + offset;
    for (size_t i = 0; i < n; i++) {
        SetPageReserved(page + i);
    }

    return page;
}
```
该函数为内存分配函数。  
首先，我们对需要分配的内存向上取值到最近的2次幂，再比较根节点和其大小，若根节点小，说明没有足够大的空闲块可以分配，返回-1。

内存分配的过程为：从根节点开始，根据左右子树的 longest 值，选择能容纳 req_size 的分支继续下，直到找到刚好等于 req_size 的节点，把该节点的 longest[index] 设为 0（表示该块被占用）。再根据公式计算出偏移量offset，最后逐级向上更新父节点信息。

```c
static void buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0 && n <= buddy.size);

    unsigned offset = base - buddy.base;
    unsigned index = offset + buddy.size - 1;
    unsigned node_size = 1;

    while (buddy.longest[index]) {
        node_size *= 2;
        if (index == 0)
            return;
        index = PARENT(index);
    }

    buddy.longest[index] = node_size;

    while (index) {
        index = PARENT(index);
        node_size *= 2;
        unsigned left_longest = buddy.longest[LEFT_LEAF(index)];
        unsigned right_longest = buddy.longest[RIGHT_LEAF(index)];

        if (left_longest + right_longest == node_size)
            buddy.longest[index] = node_size;
        else
            buddy.longest[index] = MAX(left_longest, right_longest);
    }

    for (size_t i = 0; i < n; i++) {
        ClearPageReserved(base + i);
    }
}

```
该函数为内存释放函数。  
首先通过index = offset + size - 1定位到当前叶节点位置，然后向上查找直到找到被标记为 0 的节点（表示当前块被占用）。令longest[index] = node_size恢复块大小信息，表示该块重新空闲。

再进行合并操作：向上逐层遍历，若左右子节点的空闲大小之和等于父节点块大小则合并，
否则取两者中较大的值。


最后，我们在文件末尾注册 pmm_manager：
```c
const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .check = buddy_check,
};
```

### 测试结果
因为系统正常启动运行时，我们得到的二叉树过于庞大，我们上方已经计算过，共有65535个节点，不便于验证正确性。所以我们这里采用自定义测试范围的方法进行验证，我们编写的check函数如下：
```cpp
static void buddy_check(void) {
    static struct Page fake_pages[TEST_PAGES];
    cprintf("\n=============== BUDDY SYSTEM TEST START (Size: %zu pages) ===============\n", TEST_PAGES);

    buddy_init();
    buddy_init_memmap(fake_pages, TEST_PAGES);

    assert(buddy.longest[0] == TEST_PAGES);
    cprintf("[INIT] 初始化完成：根节点 longest=%u，总页数=%u\n", buddy.longest[0], buddy.size);

    cprintf("\n--- [T1] 分配 4 页 ---\n");
    struct Page *p1 = buddy_alloc_pages(4);
    assert(p1 != NULL);
    cprintf("[T1] 分配成功: %p\n", p1);
    cprintf("[T1] 根节点 longest=%u\n", buddy.longest[0]);

    cprintf("\n--- [T2] 分配 10 页 ---\n");
    struct Page *p2 = buddy_alloc_pages(10);
    assert(p2 != NULL);
    cprintf("[T2] 分配成功: %p\n", p2);
    cprintf("[T2] 根节点 longest=%u\n", buddy.longest[0]);

    cprintf("\n--- [T3] 分配 32 页 ---\n");
    struct Page *p3 = buddy_alloc_pages(32);
    assert(p3 != NULL);
    cprintf("[T3] 分配成功: %p\n", p3);
    cprintf("[T3] 根节点 longest=%u\n", buddy.longest[0]);

    cprintf("\n--- [T4] 分配 16 页 ---\n");
    struct Page *p4 = buddy_alloc_pages(16);

    cprintf("\n--- [T5] 释放 10 页 ---\n");
    buddy_free_pages(p2, 10);
    cprintf("[T5] 释放完成，根节点 longest=%u\n", buddy.longest[0]);

    cprintf("\n--- [T6] 释放 4 页 ---\n");
    buddy_free_pages(p1, 4);
    cprintf("[T6] 释放完成，根节点 longest=%u\n", buddy.longest[0]);

    cprintf("\n--- [T7] 释放 32 页 ---\n");
    buddy_free_pages(p3, 32);
    cprintf("[T7] 释放完成，根节点 longest=%u\n", buddy.longest[0]);

    assert(buddy.longest[0] == TEST_PAGES);
    cprintf("\n✅ 所有测试通过，Buddy System 功能正常！\n");
    cprintf("=============== BUDDY SYSTEM TEST END ===============\n\n");
}
```
首先，我们验证内存分配：  
对于步骤T1的输出是：
```
--- [T1] 分配 4 页 ---
[ALLOC] 分配 4 页，节点 index=15, 块大小=4
[T1] 分配成功: 0xffffffffc0245030
[T1] 根节点 longest=32
```
我们画出二叉树，可以发现是index为15的节点被分配，并且向上更新父节点信息后，根节点大小变为32，验证成功。

对于步骤T2和T3的输出是：
```
--- [T2] 分配 10 页 ---
[ALLOC] 分配 16 页，节点 index=4, 块大小=16
[T2] 分配成功: 0xffffffffc02452b0
[T2] 根节点 longest=32

--- [T3] 分配 32 页 ---
[ALLOC] 分配 32 页，节点 index=2, 块大小=32
[T3] 分配成功: 0xffffffffc0245530
[T3] 根节点 longest=8
```
我们也可以通过画出的二叉树验证其正确性。

对于步骤T4的输出是：
```
--- [T4] 分配 16 页 ---
系统内没有足够的连续空闲内存来满足本次分配请求 
```
因为上一步执行完后longest=8，这一步请求分配内存16，自然没有空间。

接下来，我们验证内存释放：  

对于步骤T5的输出是：
```
--- [T5] 释放 10 页 ---
[T5] 释放完成，根节点 longest=16
```
我们将index=4的节点重新赋值为16后，向上更新父节点信息，可以得到根节点为16，验证正确。

对于T6和T7的输出：
```
--- [T6] 释放 4 页 ---
[T6] 释放完成，根节点 longest=32

--- [T7] 释放 32 页 ---
[T7] 释放完成，根节点 longest=64
```
我们依然可以采用画二叉树方法验证其正确性。  
最后，我们可以看到完成所有释放操作后，根节点大小又变回了64，符合事3实。

## Challenge2：任意大小的内存单元slub分配算法

### 算法思想

SLUB 是 Linux 内核中常用的**对象级内存分配器**，设计目标是快速、高效地分配小对象，同时减少内存碎片。核心思想如下：

1. **分层分配**
   - **页级（Page-level）**：首先以页为单位管理物理内存，使用链表记录空闲页。
   - **对象级（Object-level）**：在页上划分固定大小的对象池（cache），从中分配任意大小的小对象。
2. **缓存（Cache）机制**
   - 对于常用对象（如 struct task_struct、inode 等），SLUB 会维护多个 cache，每个 cache 管理同类对象。
   - 当对象被释放时，它会返回到该 cache 的自由链表中，避免频繁调用页分配器。

我觉得核心思想在于分层分配的对象级，而对于常用对象我并没有做实现，而是实现了普通的多种固定大小的对象池，这里我事先的是2的幂次大小。

当然，申请的内存大小如果与对象大小不能完全吻合，就像buddy system一样找一个最小的能满足要求的对象即可。

### 核心代码设计

#### 定义缓存与对象结构

```c
#define CACHE_COUNT 3
static const size_t cache_sizes[CACHE_COUNT] = {64, 128, 256};

typedef struct SlubObj {
    struct SlubObj *next;
} SlubObj;

typedef struct kmem_cache {
    size_t obj_size;
    SlubObj *objs_free_list;  // 避免和宏冲突
} kmem_cache;

static kmem_cache caches[CACHE_COUNT];
```

首先定义了三个对象大小的缓存（64B, 128B, 256B），用于支持多种对象大小的分配。

`SlubObj` 是对象结构体，只包含一个 `next` 指针，用于链表管理空闲对象。

`kmem_cache` 每个 cache（对象池）存储：

- `obj_size`：该 cache 管理的对象大小。

- `objs_free_list`：指向自由链表的头部。

`caches`全局数组，保存所有对象大小对应的 cache。

#### 初始化缓存

```c
static void init_caches(void) {
    for (int i = 0; i < CACHE_COUNT; i++) {
        caches[i].obj_size = cache_sizes[i];
        caches[i].objs_free_list = NULL;
    }
}
```

初始化每个 cache，设置对象大小，自由链表置空。

#### 分配对象

```c
void *slub_alloc_obj(size_t size) {
    kmem_cache *cache = NULL;
    for (int i = 0; i < CACHE_COUNT; i++) {
        if (size <= caches[i].obj_size) {
            cache = &caches[i];
            break;
        }
    }
    if (!cache) return NULL;

    if (!cache->objs_free_list) {
        struct Page *p = slub_alloc_pages(1);
        if (!p) return NULL;

        char *start = (char *)(page2pa(p) + va_pa_offset);
        int count = PGSIZE / cache->obj_size;
        for (int i = 0; i < count; i++) {
            SlubObj *obj = (SlubObj *)(start + i * cache->obj_size);
            obj->next = cache->objs_free_list;
            cache->objs_free_list = obj;
        }
    }

    SlubObj *obj = cache->objs_free_list;
    cache->objs_free_list = obj->next;
    return (void *)obj;
}
```

首先找合适的大小的cache，即第一个大于等于的级别，如果没有就返回NULL。

自由链表为空时，分配一页物理内存，将一页划分为固定大小对象。构建自由链表，将对象逐个挂到链表头。

否则直接取一个就好。

#### 释放对象

```c
void slub_free_obj(void *obj, size_t size) {
    kmem_cache *cache = NULL;
    for (int i = 0; i < CACHE_COUNT; i++) {
        if (size <= caches[i].obj_size) {
            cache = &caches[i];
            break;
        }
    }
    if (!cache) return;

    SlubObj *o = (SlubObj *)obj;
    o->next = cache->objs_free_list;
    cache->objs_free_list = o;
}
```

根据对象大小找到对应 cache。

如果找不到合适 cache，则直接返回（不做操作）。

如果找到了，直接将对象插入自由链表头部。下次分配可以直接复用，避免重新分配页。

### 正确性测试

下面是测试代码。

```c
static void slub_check(void) {
    cprintf("SLUB 检查开始...\n");

    init_caches();

    // 测试不同大小对象（非2的幂）
    size_t sizes[] = {50, 90, 200, 70, 150, 10};
    void *objs[6];
    for (int i = 0; i < 6; i++) {
        objs[i] = slub_alloc_obj(sizes[i]);
        assert(objs[i] != NULL);
        cprintf("分配对象大小 %lu, 地址 %p\n", sizes[i], objs[i]);
    }

    // 释放一部分对象
    for (int i = 0; i < 6; i += 2) {
        slub_free_obj(objs[i], sizes[i]);
        cprintf("释放对象大小 %lu, 地址 %p\n", sizes[i], objs[i]);
    }

    // 再次分配，验证复用
    void *reobjs[3];
    reobjs[0] = slub_alloc_obj(50);
    reobjs[1] = slub_alloc_obj(90);
    reobjs[2] = slub_alloc_obj(200);

    assert(reobjs[0] == objs[0]);
    assert(reobjs[1] != NULL);
    assert(reobjs[2] != NULL);

    cprintf("SLUB 检查完成，测试通过！\n");
}
```

首先初始化缓存，然后通过 `slub_alloc_obj(size)` 分配不同大小的对象，并且用 `assert(objs[i] != NULL)` 确保分配成功，最后用 `cprintf` 输出信息。

释放后复用，再用 `assert` 证明释放效果的正确性。

输出结果如下：

```c
SLUB 检查开始...
分配对象大小 50, 地址 0xffffffffc0346fc0
分配对象大小 90, 地址 0xffffffffc0347f80
分配对象大小 200, 地址 0xffffffffc0348f00
分配对象大小 70, 地址 0xffffffffc0347f00
分配对象大小 150, 地址 0xffffffffc0348e00
分配对象大小 10, 地址 0xffffffffc0346f80
释放对象大小 50, 地址 0xffffffffc0346fc0
释放对象大小 200, 地址 0xffffffffc0348f00
释放对象大小 150, 地址 0xffffffffc0348e00
SLUB 检查完成，测试通过！
```

没有问题，正确性得到验证。

## 思考题

1. 探测法：直接从一个基址开始访问内存，测试哪一段地址是有效的。从一个可能的地址开始进行探测，逐页写入标志值再读出，若访问异常则说明越界了。这个探测法可以分为在本机上调用指令进行探测和利用外设交互来进行探测。
2. 如果是 qemu 模拟下的 OS，可以采取硬编码模式，因为 qemu 会默认物理空间开始地址和大小，我们可以通过硬编码的形式告诉 OS。
3. 如果能访问 DTB 那就访问 DTB 找到对应存储物理内存信息的位置，因为本质上 OpenSBI 之类的固件就是在扫描后将该信息存储在DTB。