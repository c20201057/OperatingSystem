#include <pmm.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>
#define IS_POWER_OF_2(x)   (!((x) & ((x) - 1)))
#define LEFT_LEAF(i)       ((i) * 2 + 1)
#define RIGHT_LEAF(i)      ((i) * 2 + 2)
#define PARENT(i)          (((i) + 1) / 2 - 1)
#define MAX(a, b)          ((a) > (b) ? (a) : (b))
#define TEST_PAGES 64
typedef struct {
    unsigned size;         
    unsigned node_count;   
    unsigned *longest;     
    struct Page *base;     
} buddy_t;

static buddy_t buddy;  


static unsigned fix_size(unsigned size) {
    size |= size >> 1;
    size |= size >> 2;
    size |= size >> 4;
    size |= size >> 8;
    size |= size >> 16;
    return size + 1;
}

static void buddy_init(void) {
    memset(&buddy, 0, sizeof(buddy));
}

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

static struct Page *buddy_alloc_pages(size_t n) {
    if (n == 0) n = 1;
    if (!IS_POWER_OF_2(n))
        n = fix_size(n);

    unsigned index = 0;
    unsigned node_size = buddy.size;

    if (buddy.longest[index] < n){
        cprintf("系统内没有足够的连续空闲内存来满足本次分配请求 \n");
        return NULL;
    }
       
    while (node_size != n) {
        if (buddy.longest[LEFT_LEAF(index)] >= n)
            index = LEFT_LEAF(index);
        else
            index = RIGHT_LEAF(index);
        node_size /= 2;
    }

    buddy.longest[index] = 0;
     cprintf("[ALLOC] 分配 %u 页，节点 index=%u, 块大小=%u\n", n, index, node_size);
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


const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .check = buddy_check,
};
