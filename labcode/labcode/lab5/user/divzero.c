#include <stdio.h>
#include <ulib.h>
#pragma GCC optimize ("O0")
int zero;

int
main(void) {
    cprintf("value is %d.\n", 1 / zero);
    panic("FAIL: T.T\n");
}

