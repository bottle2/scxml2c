#include <stdio.h>

#include "rax.h"

struct state    { int dummy; };
struct parallel { int dummy; };
struct final    { int dummy; };
struct history  { int dummy; };

#define ID_XS(X, S, P)    \
X(P, STATE   , state   )S \
X(P, PARALLEL, parallel)S \
X(P, FINAL   , final   )S \
X(P, HISTORY , history )

#define COMMA ,
#define AS_ENUM(P, U, L) P##_##U
#define AS_PTR( P, U, L) struct L *L

struct id
{
    enum  { ID_XS(AS_ENUM, COMMA, ID )  } type;
    union { ID_XS(AS_PTR , ;    , NIL); } penis;
};

struct transition
{
    struct id *target;
};

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
#endif
