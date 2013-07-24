#include "desktop_test.h"
void test_pixbuf()
{
	// setup_fixture();4

	char* generate_directory_icon(const char* p1, const char* p2, const char* p3, const char* p4);
	char* get_data_uri_by_path(const char* path);
	char* get_data_uri_by_pixbuf(GdkPixbuf* pixbuf);//test in get_data_uri_by_path
	char* pixbuf_to_canvas_data(GdkPixbuf* pixbuf);

#if 1
    Test({
    	const char* path  = "/tmp/test_files/default_background.jpg";
        char* c = get_data_uri_by_path(path);
        // g_message("%s",c);
        g_free(path);
        g_free(c);
    }, "get_data_uri_by_path");
#endif

#if 0
    Test({
    	const char* path  = "/tmp/test_files/default_background.jpg";
    	GError *error = NULL;
    	GdkPixbuf* pixbuf = gdk_pixbuf_new_from_file(path, &error);
    	if (error != NULL) {
    	    g_warning("%s\n", error->message);
    	    g_error_free(error);
    	    return NULL;
    	}
        char* c = pixbuf_to_canvas_data(pixbuf);
        g_message("%s",c);
        g_free(path);
        g_free(pixbuf);
        g_free(c);

    }, "get_data_uri_by_path");
#endif

    // tear_down_fixture();
}
