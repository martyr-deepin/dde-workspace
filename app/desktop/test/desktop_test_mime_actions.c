#include "desktop_test.h"


// #define TERMINAL_SCHEMA_ID "com.deepin.desktop.default-applications.terminal"
// #define TERMINAL_KEY_EXEC  "exec"
// #define TERMINAL_KEY_EXEC_ARG "exec-arg"

// #define TEST_GFILE(e, f) if (G_IS_FILE(e)) { \
//     GFile* f = e;

// #define TEST_GAPP(e, app) } else if (G_IS_APP_INFO(e)) { \
//     GAppInfo* app = e;

// #define TEST_END } else { g_warn_if_reached();}


void test_mime_actions()
{
	setup_fixture();

    extern gboolean activate_file (GFile* file, const char* content_type, 
                    gboolean is_executable, GFile* _file_arg);


    Test({
    	g_message("activate_file start");
        GFile* f = g_file_new_for_uri("file:///tmp/test_files/skype.desktop");
        ArrayContainer fs;
        fs.data=&f;
        fs.num = 1;
	    	g_message("file is GFile");
			#if 0

	        gboolean launch_res = TRUE;
	        GFileInfo* info = g_file_query_info(f, "standard::content-type,access::can-execute", G_FILE_QUERY_INFO_NONE, NULL, NULL);
	        if (info != NULL) {
	            const char* content_type = g_file_info_get_attribute_string(info, G_FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE);
	            gboolean is_executable = g_file_info_get_attribute_boolean(info, "access::can-execute");
	            //ugly hack here. we just read the first GFile*.
	            GFile* _file_arg = NULL;
	            ArrayContainer _fs;
	            GFile** files = NULL;
	            if (fs.num != 0)
	            {
	                _fs = _normalize_array_container(fs);
	                GFile** files = _fs.data;
	                _file_arg = files[0];
	            }

	            launch_res = activate_file (f, content_type, is_executable, _file_arg);

	            if (fs.num != 0)
	            {
	                for (size_t i=0; i<_fs.num; i++) {
	                     g_object_unref(((GObject**)_fs.data)[i]);
	                }
	                g_free(_fs.data);
	            }

	            g_object_unref(info);
	        } else {
	            g_message("GFileInfo is NULL");
	            char* path = g_file_get_path(f);
	            run_command1("gvfs-open", path);
	            g_free(path);
	        }
			#endif

        ArrayContainer_free0(fs);
    	g_message("activate_file end");

	},"activate_file");


    tear_down_fixture();
}