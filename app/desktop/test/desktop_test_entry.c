#include "desktop_test.h"
extern void setup_fixture();
extern void tear_down_fixture();
extern void func_test_entry_char(char* (*func)(Entry*),Entry* variable,char* value_return);


gboolean FLAG_PRITN_RESULT = TRUE;
GPtrArray* gfileDirectory = NULL;
GPtrArray* gfileDocument = NULL;
GPtrArray* gappinfo= NULL;

void setup_fixture()
{
    // g_mkdir("test_files");
    // g_creat("test_files/test.c");
    
    system("rm -rf test_files/");
    // system("rm -rf ahsouifghasdgoiasdghah_sdgfuioashfdiosasdiafohdsoig_ashgioasdhaoisdhoifhasoi_aiosdfhasdoifhasodiufh/");
    // system("rm -rf _ahdsgioahgaosidg_agioasdhgo/");
    // system("rm -rf (test_files)/");
    // system("rm -rf 0ashdgioasdhgo_asdhgio/");
    // system("rm -rf &asdgasd/");


    system("mkdir test_files");
    // system("mkdir ahsouifghasdgoiasdghah_sdgfuioashfdiosasdiafohdsoig_ashgioasdhaoisdhoifhasoi_aiosdfhasdoifhasodiufh");
    // system("mkdir _ahdsgioahgaosidg_agioasdhgo");
    // system("mkdir (test_files)");
    // system("mkdir 0ashdgioasdhgo_asdhgio&asjdgioadsjg");
    // system("mkdir &asdgasd");


    system("cp /usr/share/backgrounds/default_background.jpg test_files/");
    system("touch test_files/test.desktop");
    system("touch test_files/test");
    system("touch test_files/test.coffee");
    system("touch test_files/test.cpp");
    system("touch test_files/test.css");
    system("touch test_files/test.exe");
    system("touch test_files/test.h");
    system("touch test_files/test.html");
    system("touch test_files/test.js");
    system("touch test_files/test.m");
    system("touch test_files/test.test");
    system("touch test_files/test.c");
    system("touch test_files/test.txt");
    system("touch test_files/test.wpt");
    system("touch test_files/test.xls");
    system("touch test_files/test.ppt");
    system("touch test_files/test.doc");

    system("cp /usr/share/applications/skype.desktop test_files/");
    system("cp /usr/share/applications/deepin-desktop.desktop test_files/");
    system("cp /usr/share/applications/deepin-media-player.desktop test_files/");
    system("cp /usr/share/applications/deepin-system-settings.desktop test_files/");
    system("cp /usr/share/applications/audacity.desktop test_files/");
    system("cp /usr/share/applications/brasero.desktop test_files/");

    gfileDirectory = g_ptr_array_new();
    gfileDocument = g_ptr_array_new();
    gappinfo = g_ptr_array_new();

    g_ptr_array_add(gfileDirectory, g_file_new_for_path("test_files"));
    // g_ptr_array_add(gfileDirectory, g_file_new_for_path("ahsouifghasdgoiasdghah_sdgfuioashfdiosasdiafohdsoig_ashgioasdhaoisdhoifhasoi_aiosdfhasdoifhasodiufh"));
    // g_ptr_array_add(gfileDirectory, g_file_new_for_path("_ahdsgioahgaosidg_agioasdhgo"));
    // g_ptr_array_add(gfileDirectory, g_file_new_for_path("(test_files)"));
    // g_ptr_array_add(gfileDirectory, g_file_new_for_path("0ashdgioasdhgo_asdhgio&asjdgioadsjg"));
    // g_ptr_array_add(gfileDirectory, g_file_new_for_path("&asdgasd"));


    g_ptr_array_add(gfileDocument, g_file_new_for_path("test_files/default_background.jpg"));//0
    g_ptr_array_add(gfileDocument, g_file_new_for_path("test_files/skype.desktop"));//1
    g_ptr_array_add(gfileDocument, g_file_new_for_path("test_files/text"));//2
    g_ptr_array_add(gfileDocument, g_file_new_for_path("test_files/text.coffee"));//3
    g_ptr_array_add(gfileDocument, g_file_new_for_path("test_files/text.cpp"));//4
    g_ptr_array_add(gfileDocument, g_file_new_for_path("test_files/text.css"));//5
    g_ptr_array_add(gfileDocument, g_file_new_for_path("test_files/text.exe"));//6
    g_ptr_array_add(gfileDocument, g_file_new_for_path("test_files/text.h"));//7
    g_ptr_array_add(gfileDocument, g_file_new_for_path("test_files/text.html"));//8
    g_ptr_array_add(gfileDocument, g_file_new_for_path("test_files/text.js"));//9
    g_ptr_array_add(gfileDocument, g_file_new_for_path("test_files/text.m"));//10
    g_ptr_array_add(gfileDocument, g_file_new_for_path("test_files/text.test"));//11
    g_ptr_array_add(gfileDocument, g_file_new_for_path("test_files/text.c"));//13
    g_ptr_array_add(gfileDocument, g_file_new_for_path("test_files/text.txt"));//14
    g_ptr_array_add(gfileDocument, g_file_new_for_path("test_files/text.wpt"));//15
    g_ptr_array_add(gfileDocument, g_file_new_for_path("test_files/text.xls"));//16
    g_ptr_array_add(gfileDocument, g_file_new_for_path("test_files/text.ppt"));//17
    g_ptr_array_add(gfileDocument, g_file_new_for_path("test_files/text.doc"));//18
    g_ptr_array_add(gfileDocument, g_file_new_for_path("test_files/deepin-system-settings.desktop"));//19

    g_ptr_array_add(gappinfo, g_desktop_app_info_new_from_filename("test_files/skype.desktop"));//0
    g_ptr_array_add(gappinfo, g_desktop_app_info_new_from_filename("test_files/deepin-desktop.desktop"));//1
    g_ptr_array_add(gappinfo, g_desktop_app_info_new_from_filename("test_files/deepin-media-player.desktop"));//2
    g_ptr_array_add(gappinfo, g_desktop_app_info_new_from_filename("test_files/deepin-system-settings.desktop"));//3
    g_ptr_array_add(gappinfo, g_desktop_app_info_new_from_filename("test_files/audacity.desktop"));//4
    g_ptr_array_add(gappinfo, g_desktop_app_info_new_from_filename("test_files/brasero.desktop"));//5

}

void tear_down_fixture()
{
    g_ptr_array_unref(gfileDirectory);
    g_ptr_array_unref(gfileDocument);
    g_ptr_array_unref(gappinfo);

    system("rm -rf test_files/");
    // system("rm -rf ahsouifghasdgoiasdghah_sdgfuioashfdiosasdiafohdsoig_ashgioasdhaoisdhoifhasoi_aiosdfhasdoifhasodiufh/");
    // system("rm -rf _ahdsgioahgaosidg_agioasdhgo/");
    // system("rm -rf (test_files)/");
    // system("rm -rf 0ashdgioasdhgo_asdhgio/");
    // system("rm -rf &asdgasd/");
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
    setup_fixture();

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
    //     set_default_theme("Deepin");
    //     set_desktop_env_name("Deepin");
    //     // func_test_entry_char(dentry_get_icon,gfileDirectory, "/usr/share/icons/Faenza/places/48/inode-directory.png");
    //     //the icon isn't icon which in .thumbnail/ ,and the file icon show first in thumbnail (code in desktop_item.coffee->set_icon)
    //     // func_test_entry_char(dentry_get_icon,gfileDocument, "/usr/share/icons/Faenza/mimetypes/48/application-x-ms-dos-executable.png");
    //     // func_test_entry_char(dentry_get_icon,gappinfo, "/usr/share/icons/Deepin/apps/48/skype.png");
    //     // func_test_entry_char(dentry_get_icon,gappinfo, "/usr/share/icons/Deepin/apps/48/skype.png");
    //     func_test_entry_char(dentry_get_icon,gappinfo, "/usr/share/icons/Deepin/apps/48/audacity.png");
    // },"dentry_get_icon");

    // extern char* dentry_get_icon_path(Entry* e);
    // Test({
    //     // func_test_entry_char(dentry_get_icon_path,gfileDirectory, "/usr/share/icons/Faenza/places/48/inode-directory.png");
    //     // func_test_entry_char(dentry_get_icon_path,gfileDocument, "/usr/share/icons/Faenza/mimetypes/48/image-png.png");
    //     // func_test_entry_char(dentry_get_icon_path,gfileDocument, "/usr/share/icons/Faenza/mimetypes/48/application-x-desktop.png");
    //     // func_test_entry_char(dentry_get_icon_path,gfileDocument, "/usr/share/icons/Faenza/mimetypes/48/text-css.png");
    //     func_test_entry_char(dentry_get_icon_path,gfileDocument, "/usr/share/icons/Faenza/mimetypes/48/application-x-ms-dos-executable.png");

    //     // func_test_entry_char(dentry_get_icon_path,gappinfo, "/usr/share/icons/Deepin/apps/48/skype.png");
    // },"dentry_get_icon_path"); 

    // extern gboolean dentry_can_thumbnail(Entry* e);
    // gboolean bool_return = false;
    // Test({
    //     // gboolean bool_return = dentry_can_thumbnail(gfileDirectory);
    //     bool_return = dentry_can_thumbnail(gfileDocument);
    //     // dentry_can_thumbnail(gappinfo);
    //     // 
    // },"dentry_can_thumbnail");
    // g_message("%d",bool_return);

    // extern char* dentry_get_thumbnail(Entry* e);
    // FLAG_PRITN_RESULT = TRUE;
    // Test({

    //     // gfileDirectory :dentry_can_thumbnail is false
    //     // func_test_entry_char(dentry_get_thumbnail,gfileDirectory,NULL);
    //     // func_test_entry_char(dentry_get_thumbnail,gfileDocument, ".thumbnails/normal/692aec2ade9c8ea309697fbd5e9d7899.png");
    //     // func_test_entry_char(dentry_get_thumbnail,gfileDocument, ".thumbnails/normal/692aec2ade9c8ea309697fbd5e9d7899.png");

    //     // .desktop file :dentry_can_thumbnail is false
    //     // func_test_entry_char(dentry_get_thumbnail,gfileDocument, NULL);
    //     // func_test_entry_char(dentry_get_thumbnail,gfileDocument, NULL);
    //     // func_test_entry_char(dentry_get_thumbnail,gfileDocument, ".thumbnails/normal/048e2190b2e95ed836646e70e4978378.png");

    //     // func_test_entry_char(dentry_get_thumbnail,gappinfo, "/usr/share/icons/Deepin/apps/48/skype.png");
    //     // func_test_entry_char(dentry_get_thumbnail,gappinfo, "/usr/share/icons/Deepin/apps/48/skype.png");
    // },"dentry_get_thumbnail");


    extern char* dentry_get_id(Entry* e);
    Test({
        func_test_entry_char(dentry_get_id, g_ptr_array_index(gfileDirectory,0),"5565c4012ed4c6f1007c2b86aea48956");
        // func_test_entry_char(dentry_get_id,gfileDocument,"9e59f7e96e3ca18daa14f5adbbbdcf65");
        // func_test_entry_char(dentry_get_id,gfileDocument,"221d498715901ee41709b24e36069fed");
        // func_test_entry_char(dentry_get_id,gfileDocument,"ee38506f63e67c3f1743ca4eeddb1fcb");
        // func_test_entry_char(dentry_get_id,gappinfo,"e9ab3a2fb814421ed6d747c62851abb3");
    },"dentry_get_id");




    tear_down_fixture();
}