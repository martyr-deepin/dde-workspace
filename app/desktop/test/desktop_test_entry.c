#include "desktop_test.h"
extern void variable_init();
extern void variable_free();
extern void func_test_entry_char(char* (*func)(Entry*),Entry* variable,char* value_return);

Entry* gfileDirectory = NULL;
Entry* gfileDocument = NULL;
Entry* gappinfo = NULL;

void variable_init()
{  
    // extern Entry* dentry_get_desktop();
    // Entry* e = dentry_get_desktop();
    Entry* gfileDirectory = g_file_new_for_path("/home/ycl/test_files");
    Entry* gfileDocument = g_file_new_for_path("/home/ycl/test_files/001.png");

/*    Entry* gappinfo = g_app_info_create_from_commandline("skype",NULL,
                                                            G_APP_INFO_CREATE_NONE,
                                                            NULL);*/

    Entry* gappinfo = g_desktop_app_info_new_from_filename("/home/ycl/Desktop/skype.desktop");
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
        /*g_message("%s",s);*/
        g_assert(g_str_equal(s, value_return) == TRUE);
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
    //     dentry_should_move(e);
    // },"dentry_should_move");

    // extern gboolean dentry_is_native(Entry* e);
    // Test({
    //     dentry_is_native(e);
    // },"dentry_is_native");    

    // extern double dentry_get_type(Entry* e);
    // Test({
    //     dentry_get_type(e);
    // },"dentry_get_type");

    // extern JSObjectRef dentry_get_flags (Entry* e);
    // Test({
    //     dentry_get_flags(e);
    // },"dentry_get_flags");    

    // extern char* dentry_get_name(Entry* e);
    // Test({
    //     char* c = dentry_get_name(e);
    //     g_free(c);
    // },"dentry_get_name");


    extern char* dentry_get_uri(Entry* e);
    #define DENTRY_GET_URL_TEST(entry, answer) do {\
        char* s = dentry_get_uri(entry);\
        /*g_message("%s",s);*/\
        g_assert(g_str_equal(s, answer) == TRUE);\
        g_free(s);\
    } while(0)

    Test({
        func_test_entry_char(dentry_get_uri,gfileDirectory,"file:///home/ycl/Desktop")
        // DENTRY_GET_URL_TEST(gfileDirectory, "file:///home/ycl/test_files");
        DENTRY_GET_URL_TEST(gfileDocument, "file:///home/ycl/test_files/001.png");
        // cannot get uri
        DENTRY_GET_URL_TEST(gappinfo,"file:///home/ycl/Desktop/skype.desktop");
    },"dentry_get_uri"); 

    
    extern char* dentry_get_icon(Entry* e);    
    #define DENTRY_GET_ICON_TEST(entry, answer) do {\
        char* s = dentry_get_icon(entry);\
        /*g_message("%s",s);*/\
        g_assert(g_str_equal(s, answer) == TRUE);\
        g_free(s);\
    } while(0)

    Test({
        DENTRY_GET_ICON_TEST(gappinfo, "/usr/share/icons/Deepin/apps/48/skype.png");
    },"dentry_get_icon");



    variable_free();
}