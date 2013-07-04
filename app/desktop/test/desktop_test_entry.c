#include "desktop_test.h"
extern void variable_init();
extern void variable_free();
extern void func_test_entry_char(char* (*func)(Entry*),Entry* variable,char* value_return);


gboolean FLAG_PRITN_RESULT = TRUE;
Entry* gfileDirectory = NULL;
Entry* gfileDocument = NULL;
Entry* gappinfo = NULL;

void variable_init()
{  
    gfileDirectory = g_file_new_for_path("/home/ycl/test_files");

    // gfileDocument = g_file_new_for_path("/home/ycl/test_files/001.png");
    // gfileDocument = g_file_new_for_path("/home/ycl/test_files/skype.desktop");
    // gfileDocument = g_file_new_for_path("/home/ycl/test_files/text.css");
    gfileDocument = g_file_new_for_path("/home/ycl/test_files/text.exe");


    // gappinfo = g_desktop_app_info_new_from_filename("/home/ycl/Desktop/skype.desktop");
    gappinfo = g_desktop_app_info_new_from_filename("/home/ycl/test_files/skype.desktop");

}

void variable_free()
{
    g_object_unref(gfileDirectory);
    g_object_unref(gfileDocument);
    g_object_unref(gappinfo);
}

void func_test_entry_char(char* (*func)(Entry*),Entry* variable,char* value_return)
{
        char* s = func(variable);
        if(FLAG_PRITN_RESULT)
        {
            g_message("func result:\n");
            g_message("%s\n",s);
            // fprintf(stderr, "%s\n", s);
            g_message("func result over.\n");
        }
        g_assert(g_str_equal(s, value_return) == TRUE);
        FLAG_PRITN_RESULT = FALSE;
        g_free(s);
}

void test_entry()
{
    variable_init();

    // extern Entry* dentry_get_desktop();
    // Test({
    //     Entry* e = dentry_get_desktop();
    //     g_object_unref(e);
    // },"dentry_get_desktop");

    // extern gboolean dentry_should_move(Entry* e);
    // Test({
    //     dentry_should_move(gfileDirectory);
    //     dentry_should_move(gfileDocument);
    //     dentry_should_move(gappinfo);
    // },"dentry_should_move");

    // extern gboolean dentry_is_native(Entry* e);
    // Test({
    //     dentry_is_native(gfileDirectory);
    //     dentry_is_native(gfileDocument);
    //     dentry_is_native(gappinfo);
    // },"dentry_is_native");    

    // extern double dentry_get_type(Entry* e);
    // Test({
    //     dentry_get_type(gfileDirectory);
    //     dentry_get_type(gfileDocument);
    //     dentry_get_type(gappinfo);
    // },"dentry_get_type");

    // extern JSObjectRef dentry_get_flags (Entry* e);
    // Test({
    //     dentry_get_flags(gfileDirectory);
    //     dentry_get_flags(gfileDocument);
    //     dentry_get_flags(gappinfo);
    // },"dentry_get_flags");    

    // extern char* dentry_get_name(Entry* e);
    // Test({
    //     func_test_entry_char(dentry_get_name,gfileDirectory,"test_files");
    //     func_test_entry_char(dentry_get_name,gfileDocument,"001.png");
    //     func_test_entry_char(dentry_get_name,gappinfo,"Skype");
    //     },"dentry_get_name");


    // extern char* dentry_get_uri(Entry* e);
    // #define DENTRY_GET_URL_TEST(entry, answer) do {\
    //     char* s = dentry_get_uri(entry);\
    //     /*g_message("%s",s);*/\
    //     g_assert(g_str_equal(s, answer) == TRUE);\
    //     g_free(s);\
    // } while(0)

    // Test({
    //     func_test_entry_char(dentry_get_uri,gfileDirectory,"file:///home/ycl/Desktop");
    //     // DENTRY_GET_URL_TEST(gfileDirectory, "file:///home/ycl/test_files");
    //     DENTRY_GET_URL_TEST(gfileDocument, "file:///home/ycl/test_files/001.png");
    //     // cannot get uri
    //     DENTRY_GET_URL_TEST(gappinfo,"file:///home/ycl/Desktop/skype.desktop");
    // },"dentry_get_uri"); 

    
    // extern char* dentry_get_icon(Entry* e);    
    // #define DENTRY_GET_ICON_TEST(entry, answer) do {\
    //     char* s = dentry_get_icon(entry);\
    //     /*g_message("%s",s);*/\
    //     g_assert(g_str_equal(s, answer) == TRUE);\
    //     g_free(s);\
    // } while(0)

    // Test({
    //     DENTRY_GET_ICON_TEST(gappinfo, "/usr/share/icons/Deepin/apps/48/skype.png");
    // },"dentry_get_icon");

    // extern char* dentry_get_uri(Entry* e);
    // Test({
    //     func_test_entry_char(dentry_get_uri,gfileDirectory,"file:///home/ycl/test_files");
    //     func_test_entry_char(dentry_get_uri,gfileDocument, "file:///home/ycl/test_files/001.png");
    //     func_test_entry_char(dentry_get_uri,gappinfo,"file:///home/ycl/Desktop/skype.desktop");
    // },"dentry_get_uri"); 
    
    // extern char* dentry_get_icon(Entry* e);    
    // Test({
    //     func_test_entry_char(dentry_get_icon,gfileDirectory, "/usr/share/icons/Faenza/places/48/inode-directory.png");
    //     func_test_entry_char(dentry_get_icon,gfileDocument, "/usr/share/icons/Faenza/mimetypes/48/image-png.png");
    //     func_test_entry_char(dentry_get_icon,gappinfo, "/usr/share/icons/Deepin/apps/48/skype.png");
    // },"dentry_get_icon");

    extern char* dentry_get_icon_path(Entry* e);
    Test({
        // func_test_entry_char(dentry_get_icon_path,gfileDirectory, "/usr/share/icons/Faenza/places/48/inode-directory.png");
        // func_test_entry_char(dentry_get_icon_path,gfileDocument, "/usr/share/icons/Faenza/mimetypes/48/image-png.png");
        // func_test_entry_char(dentry_get_icon_path,gfileDocument, "/usr/share/icons/Faenza/mimetypes/48/application-x-desktop.png");
        // func_test_entry_char(dentry_get_icon_path,gfileDocument, "/usr/share/icons/Faenza/mimetypes/48/text-css.png");
        func_test_entry_char(dentry_get_icon_path,gfileDocument, "/usr/share/icons/Faenza/mimetypes/48/application-x-ms-dos-executable.png");

        // func_test_entry_char(dentry_get_icon_path,gappinfo, "/usr/share/icons/Deepin/apps/48/skype.png");
    },"dentry_get_icon"); 



    variable_free();
}