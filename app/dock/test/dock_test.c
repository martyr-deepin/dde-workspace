#ifdef __DUI_DEBUG

#include <stdlib.h>
#include <unistd.h>
#include "dock_test.h"

/* int TEST_MAX_COUNT = 100000; */
int TEST_MAX_COUNT = 1000000;
/* int TEST_MAX_COUNT = 1000; */
/* int TEST_MAX_COUNT = 1; */
int TEST_MAX_MEMORY= RES_IN_MB(90);
/* int TEST_MAX_MEMORY= RES_IN_MB(400); */


extern void dock_test_draw();
extern void dock_test_config();
extern void dock_test_dominant_color();
extern void dock_test_hide();
extern void dock_test_handle_icon();
extern void dock_test_launcher();
extern void dock_test_tasklist();
extern void dock_test_special_window();
extern void dock_test_tray();

void dock_test_dock()
{
    extern void dock_change_workarea_height(double height);
    Test({
         dock_change_workarea_height(60);
         }, "dock_change_workarea_height");
}

void dock_test()
{
    g_message("dock test start...");
    // TODO:
    /* dock_test_hide(); */
    /* dock_test_config(); */
    /* dock_test_dominant_color(); */
    dock_test_handle_icon();

    // TODO: test build_app_info
    /* dock_test_launcher(); */

    // TODO: client_free
    /* dock_test_tasklist(); */

    /* dock_test_special_window(); */
    /* dock_test_dock(); */
    g_message("All dock test passed!!!!");
}

#endif
