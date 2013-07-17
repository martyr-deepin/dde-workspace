#include "desktop_test.h"
void test_fileops_error_reporting()
{
    extern FileOpsResponse* fileops_response_dup (FileOpsResponse* response);
	extern void             fileops_response_free (FileOpsResponse* response);

	//FileOpsResponse fileops_error_show_dialog (GError* error);
	//users should free FileOpsResponse
	extern FileOpsResponse* fileops_delete_trash_error_show_dialog (const char* fileops_str, GError* error, 
								GFile* file, GtkWindow* parent);
	extern FileOpsResponse* fileops_move_copy_error_show_dialog (const char* fileops_str, GError* error, 
		                                             GFile* src, GFile* dest, GtkWindow* parent);

	Test({
		
	},"test_fileops_error_reporting");
}