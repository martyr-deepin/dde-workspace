#include "desktop_test.h"

void test_fileops_delete()
{

    extern void fileops_confirm_delete (GFile* file_list[], guint num, gboolean show_dialog);
    Test({

         int dump G_GNUC_UNUSED = system("touch /tmp/test_files/skype.desktop");

         g_message("fileops_confirm_delete start");
         GFile* src2 = g_file_new_for_uri("file:///tmp/test_files/skype.desktop");
         fileops_confirm_delete(&src2,1,FALSE);
         g_object_unref(src2);
         g_message("fileops_confirm_delete end");

         },"fileops_confirm_delete");

}

