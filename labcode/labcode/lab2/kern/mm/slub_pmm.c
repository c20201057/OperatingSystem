#include <pmm.h>
#include <slub_pmm.h>
#include <memlayout.h>
#include <list.h>
#include <defs.h>
#include <stdio.h>
#include <assert.h>

/* ----------------------------
 * 第一层：按页分配（Page级）
 * ---------------------------- */
static free_area_t free_area;
#define free_list (free_area.free_list)
static size_t nr_free_pages_cnt = 0;

static void slub_init(void) {
    list_init(&free_list);
    nr_free_pages_cnt = 0;
}

static void slub_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p;
    for (p = base; p < base + n; p++) {
        assert(PageReserved(p));
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);
    }

    base->property = n;
    SetPageProperty(base);
    nr_free_pages_cnt += n;

    if (list_empty(&free_list)) {
        list_add(&free_list, &base->page_link);
    } else {
        list_entry_t *le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page *page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &base->page_link);
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &base->page_link);
            }
        }
    }
}

static struct Page *slub_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free_pages_cnt) return NULL;

    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    if (!page) return NULL;

    list_entry_t *prev = list_prev(&page->page_link);
    list_del(&page->page_link);

    if (page->property > n) {
        struct Page *rest = page + n;
        rest->property = page->property - n;
        SetPageProperty(rest);
        list_add(prev, &rest->page_link);
    }

    nr_free_pages_cnt -= n;
    ClearPageProperty(page);
    return page;
}

static void slub_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p;
    for (p = base; p < base + n; p++) {
        p->flags = 0;
        set_page_ref(p, 0);
        ClearPageProperty(p);
    }

    base->property = n;
    SetPageProperty(base);
    nr_free_pages_cnt += n;

    if (list_empty(&free_list)) {
        list_add(&free_list, &base->page_link);
    } else {
        list_entry_t *le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page *page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &base->page_link);
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &base->page_link);
            }
        }
    }

    // 合并前后空闲块
    list_entry_t *le;
    le = list_prev(&base->page_link);
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&base->page_link);
            base = p;
        }
    }
    le = list_next(&base->page_link);
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&p->page_link);
        }
    }
}

static size_t slub_nr_free_pages(void) {
    return nr_free_pages_cnt;
}

/* ----------------------------
 * 第二层：支持多对象大小的 SLUB
 * ---------------------------- */
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

static void init_caches(void) {
    for (int i = 0; i < CACHE_COUNT; i++) {
        caches[i].obj_size = cache_sizes[i];
        caches[i].objs_free_list = NULL;
    }
}

// 分配对象
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

// 释放对象
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

/* ----------------------------
 * 检查函数
 * ---------------------------- */
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

/* ----------------------------
 * SLUB PMM Manager
 * ---------------------------- */
const struct pmm_manager slub_pmm_manager = {
    .name = "slub_pmm_manager",
    .init = slub_init,
    .init_memmap = slub_init_memmap,
    .alloc_pages = slub_alloc_pages,
    .free_pages = slub_free_pages,
    .nr_free_pages = slub_nr_free_pages,
    .check = slub_check,
};
