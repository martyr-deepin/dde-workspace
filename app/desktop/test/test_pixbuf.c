#include "desktop_test.h"
void test_pixbuf()
{
	// setup_fixture();4

	char* generate_directory_icon(const char* p1, const char* p2, const char* p3, const char* p4);// not test
	char* get_data_uri_by_path(const char* path);//test ok
	char* get_data_uri_by_pixbuf(GdkPixbuf* pixbuf);//test in get_data_uri_by_path //test ok
	char* pixbuf_to_canvas_data(GdkPixbuf* pixbuf);//test ok

#if 0
	Test({
    	const char* path  = "/tmp/test_files/default_background.jpg";
    	g_message("start");
        char* c = get_data_uri_by_path(path);
        // g_message("%s",c);
        g_free(c);
    	g_message("end");

    }, "get_data_uri_by_path");
#endif

#if 1
    Test({
    	const char* path  = "/tmp/test_files/bdlogo.gif";
    	GError *error = NULL;
    	GdkPixbuf* pixbuf = gdk_pixbuf_new_from_file(path, &error);
    	if (error != NULL) {
    	    g_warning("%s\n", error->message);
    	    g_error_free(error);
    	}
    	else{
	    	char* c = pixbuf_to_canvas_data(pixbuf);
	        // g_message("%s",c);
	        g_free(c);
    	}
	    g_object_unref(pixbuf);
    }, "pixbuf_to_canvas_data");
#endif

    // tear_down_fixture();
}
