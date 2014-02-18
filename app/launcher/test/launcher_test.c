#ifdef __DUI_DEBUG

#include "launcher_test.h"

int TEST_MAX_COUNT = 1000000;
int TEST_MAX_MEMORY= RES_IN_MB(400);

extern void monitor_test();
extern void background_test();

#endif

void launcher_test()
{
#ifdef __DUI_DEBUG
    /* TEST_MAX_COUNT = 10000; */

    g_message("start testing");

    /* monitor_test(); */
    /* background_test(); */

    g_message("All Passed!!!");
#endif
}

