#include "desktop_test.h"
// #include "setup_fixture.c"

void test_thumbnails()
{
	setup_fixture();

    extern gboolean gfile_can_thumbnail (GFile* file);
	extern char*    gfile_lookup_thumbnail (GFile* file);

    // GFile* src = g_file_new_for_uri("file:///tmp/test_files/skype.desktop");//FALSE

    GFile* src = g_file_new_for_uri("file:///tmp/test_files/test.exe");
    char* result = "/home/ycl/.thumbnails/normal/77374021929390f03f990fdc306e7eb0.png";

	Test({

        gboolean b = gfile_can_thumbnail(src);

    	if(b)
    	{
    		g_message("TRUE");
        	char * s = gfile_lookup_thumbnail(src);
        	// g_message("%s",s);
        	g_assert(g_str_equal(s, result) == TRUE);
        	g_free(s);
    	}
    	else
    	{
    		g_message("FALSE");
    	}

    },"gfile_can_thumbnail gfile_lookup_thumbnail");
    g_object_unref(src);
    g_free(result);

	tear_down_fixture();
}