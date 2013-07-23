#include "desktop_test.h"

void test_background()
{

	
    // extern void setup_background_window();
    // Test({
    //      GdkWindow* _background_window;
    //      setup_background_window();
    //      g_object_unref(_background_window);
    //      _background_window = NULL;
    //      }, "setup_background_window");

    extern GdkWindow* get_background_window();
    Test({
         GdkWindow* _background_window;
         _background_window = get_background_window();
         g_object_unref(_background_window);
         _background_window = NULL;
         }, "get_background_window");

}