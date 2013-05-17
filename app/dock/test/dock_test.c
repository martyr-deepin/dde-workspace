#ifdef __DUI_DEBUG

#include "dock_test.h"

int TEST_MAX_COUNT = 100000;
/* int TEST_MAX_COUNT = 1000000; */
/* int TEST_MAX_COUNT = 1000; */
/* int TEST_MAX_COUNT = 1; */
int TEST_MAX_MEMORY= RES_IN_MB(90);


extern void dock_test_draw();
extern void dock_test_config();
extern void dock_test_dominant_color();
extern void dock_test_hide();
extern void dock_test_handle_icon();
extern void dock_test_launcher();
extern void dock_test_tasklist();

void dock_test()
{
    g_message("dock test start...");
    /* dock_test_hide(); */
    /* dock_test_config(); */
    /* dock_test_dominant_color(); */
    /* dock_test_handle_icon(); */
    dock_test_launcher();

    // TODO: test more
    /* dock_test_tasklist(); */
    g_message("All dock test passed!!!!");
}

#endif
