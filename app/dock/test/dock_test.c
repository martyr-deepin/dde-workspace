#ifdef __DUI_DEBUG

#include <stdlib.h>
#include <unistd.h>
#include "dock_test.h"

int TEST_MAX_COUNT = 100000;

// resident memory
int TEST_MAX_MEMORY= RES_IN_MB(40);


extern void dock_test_draw();
extern void dock_test_config();
extern void dock_test_dominant_color();
extern void dock_test_hide();
extern void dock_test_handle_icon();

void dock_test_dock()
{
    extern void dock_change_workarea_height(double height);
    Test({
         dock_change_workarea_height(60);
         }, "dock_change_workarea_height");
}

void dock_test()
{
    /* TEST_MAX_COUNT = 1000000; */
    /* TEST_MAX_COUNT = 1000; */
    /* TEST_MAX_COUNT = 1; */

    TEST_MAX_MEMORY= RES_IN_MB(90);
    TEST_MAX_MEMORY= RES_IN_MB(400);

    g_message("dock test start...");
    // TODO:
    /* dock_test_hide(); */
    /* dock_test_config(); */
    /* dock_test_dominant_color(); */
    /* dock_test_handle_icon(); */

    /* dock_test_dock(); */
    g_message("All dock test passed!!!!");
}

#endif

