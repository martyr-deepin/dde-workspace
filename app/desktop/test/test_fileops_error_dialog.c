#include "desktop_test.h"


void test_fileops_error_dialog()
{
	extern GtkWidget* fileops_error_conflict_dialog_new (GtkWindow* parent, GFile* src, 
	                                      GFile* dest, FileOpsResponse* response);

	Test({

	},"test_fileops_error_dialog");

}