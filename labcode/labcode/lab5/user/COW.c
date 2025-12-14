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