#ifdef __DUI_DEBUG

#include "launcher_test.h"

int TEST_MAX_COUNT = 10000000;
int TEST_MAX_MEMORY= RES_IN_MB(400);

extern void monitor_test();

void launcher_test()
{
    monitor_test();
}

#endif

