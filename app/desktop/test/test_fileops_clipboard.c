#include "desktop_test.h"

void test_fileops_clipboard()
{
	setup_fixture();


	extern gboolean  is_clipboard_empty ();
	extern void fileops_paste(GFile* dest_dir);
    extern void dentry_clipboard_copy(ArrayContainer fs);
    extern void dentry_clipboard_cut(ArrayContainer fs);
	extern void init_fileops_clipboard (GFile* file_list[], guint num, gboolean cut);

	Test({
		
		gboolean b = is_clipboard_empty();
		if(b)
		{
			g_message("is_clipboard_empty -> TRUE");

			g_message("dentry_clipboard_copy start");
	        GFile* src = g_file_new_for_uri("file:///tmp/test_files/skype.desktop");
	        ArrayContainer fs;
	        fs.data=&src;
	        fs.num = 1;
	        // dentry_clipboard_copy(fs);
	        dentry_clipboard_cut(fs);
	        ArrayContainer_free0(fs);
	    	g_message("dentry_clipboard_copy end");
		}
		else
		{
			g_message("is_clipboard_empty -> FALSE");

			g_message("fileops_paste start");
	        GFile* dest1 = g_file_new_for_uri("file:///tmp/");
	        fileops_paste(dest1);
	        g_object_unref(dest1);
	        g_message("fileops_paste end");
		}
		system("rm /tmp/skype.desktop");
		// init_fileops_clipboard();

	},"is_clipboard_empty  fileops_paste init_fileops_clipboard");



	tear_down_fixture();
}