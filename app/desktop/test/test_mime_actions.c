#include "desktop_test.h"



static
GFile* _get_gfile_from_gapp(GDesktopAppInfo* info)
{
    return g_file_new_for_commandline_arg(g_desktop_app_info_get_filename(info));
}


G_GNUC_UNUSED
static ArrayContainer _normalize_array_container(ArrayContainer pfs)
{
    GPtrArray* array = g_ptr_array_new();

    GFile** _array = pfs.data;
    for(size_t i=0; i<pfs.num; i++) {
        if (G_IS_DESKTOP_APP_INFO(_array[i])) {
            g_ptr_array_add(array, _get_gfile_from_gapp(((GDesktopAppInfo*)_array[i])));
        } else {
            g_ptr_array_add(array, g_object_ref(_array[i]));
        }
    }

    ArrayContainer ret;
    ret.num = pfs.num;
    ret.data = g_ptr_array_free(array, FALSE);
    return ret;
}

void test_mime_actions()
{
	setup_fixture();



	extern void desktop_run_in_terminal(char* executable);
    extern char* dentry_get_uri(Entry* e);
	Test({
        GFile* f = g_file_new_for_uri("file:///tmp/test_files/skype.desktop");
		char* s = dentry_get_uri(f);
		// desktop_run_in_terminal(s);//Warning:!!!!! : don't test it , it will open terminal alltimes
		g_free(s);
		g_object_unref(f);
	},"desktop_run_in_terminal");


#if 0
    extern gboolean activate_file (GFile* file, const char* content_type, gboolean is_executable, GFile* _file_arg);
    Test({
    	g_message("activate_file start");
        GFile* f = g_file_new_for_uri("file:///tmp/test_files/skype.desktop");
        ArrayContainer fs;
        fs.data=&f;
        fs.num = 1;
	    	// g_message("file is GFile");
			#if 1

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

				ArrayContainer_free(_fs);

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
#endif

    tear_down_fixture();
}

