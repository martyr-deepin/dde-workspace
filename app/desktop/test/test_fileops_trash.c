#include "desktop_test.h"

void test_fileops_trash()
{
#if 0
	extern void fileops_confirm_trash ();
	Test({
		fileops_confirm_trash();
	},"fileops_confirm_trash");
#endif

	extern void fileops_empty_trash ();
	Test({
		fileops_empty_trash();
	},"fileops_empty_trash");

    extern char* dentry_get_name(Entry* e);
	extern GFile* fileops_get_trash_entry();
	Test({
		GFile* f = fileops_get_trash_entry();
		// char* c = dentry_get_name(f);
		// g_message("%s",c);
		// g_object_unref(c);
        func_test_entry_char(dentry_get_name,f,"/");
		g_object_unref(f);
	},"fileops_get_trash_entry");

	extern double fileops_get_trash_count();
	Test({
		double d = fileops_get_trash_count();
		g_message("%f",d);
	},"fileops_get_trash_count");

}