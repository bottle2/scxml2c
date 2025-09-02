#include <stdio.h>

#include "rax.h"

int main(void)
{
    rax *r = raxNew();

    struct id { int it, refcount; };

    // Use raxSeek to get current and increment refcount etc.

    raxFree(r);

    return 0;
}

#if 0
// Thanks Simon Tatham.
#define crBegin static int state=0; switch(state) { case 0:
#define crYield do { state=__LINE__; return; case __LINE__:; } while (0)
#define crFinish } (void)0

// Let's do a recursive coroutine. We maintain recursive thing inside
// the struct of token itself, it's a tree after all.

{
    switch () {
        case PARALLEL: break;
    }
}
#endif
