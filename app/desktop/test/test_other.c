#include "desktop_test.h"
void test_other()
{
    gboolean on_bg_duration_tick(gpointer data);
    Test({
        on_bg_duration_tick(NULL);
    }, "on_bg_duration_tick");

}
