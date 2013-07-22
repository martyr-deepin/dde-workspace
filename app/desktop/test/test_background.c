#include "desktop_test.h"

void test_background()
{
	setup_fixture();


	Test({


	},"test_");

	
    extern GdkWindow* _background_window;
    extern void setup_background_window();
    Test({
         setup_background_window();
         g_object_unref(_background_window);
         _background_window = NULL;
         }, "setup_background_window");

	tear_down_fixture();

}