#include <stdio.h>
#include <ulib.h>

int magic = -0x10384;

int
main(void) {
    int pid, code;
    cprintf("I am the parent. Forking the child...\n");
    if ((pid = fork()) == 0) {
        cprintf("I am the child.\n");
        yield();
        yield();
        yield();
        yield();
        yield();
        yield();
        yield();
        exit(magic);
    }
    else {
        cprintf("I am parent, fork a child pid %d\n",pid);
    }
    assert(pid > 0);
    /* debug instrumentation: print values around waitpid to diagnose failures */
    cprintf("[debug] parent: pid=%d, about to wait\n", pid);
    cprintf("I am the parent, waiting now..\n");

    int ret = waitpid(pid, &code);
    cprintf("[debug] waitpid returned %d, code=%d\n", ret, code);
    assert(ret == 0 && code == magic);

    ret = waitpid(pid, &code);
    cprintf("[debug] waitpid(second) returned %d\n", ret);
    assert(ret != 0 && wait() != 0);
    cprintf("waitpid %d ok.\n", pid);

    cprintf("exit pass.\n");
    return 0;
}

