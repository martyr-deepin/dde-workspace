#include "desktop_test.h"

GPtrArray *gfileDirectory = NULL;
GPtrArray *gfileDocument = NULL;
GPtrArray *gappinfo= NULL;

gboolean FLAG_PRITN_RESULT = TRUE;


gchar *file1 = "/tmp/test_files/360wallpaper38.jpg";
gchar *file2 = "/tmp/test_files/001.png";
gchar *rich_dir = "/tmp/test_files/.deepin_rich_dir_desktop_test";
gchar *app_0 = "/tmp/test_files/skype.desktop";
gchar *app_1 = "/tmp/test_files/deepin-user-manual.desktop";



void setup_fixture()
{
    // g_mkdir("test_files");
    // g_creat("test_files/test.c");
    
    system("rm -rf /tmp/test_files/");
    system("rm -rf /tmp/ahsouifghasdgoiasdghah_sdgfuioashfdiosasdiafohdsoig_ashgioasdhaoisdhoifhasoi_aiosdfhasdoifhasodiufh/");
    system("rm -rf /tmp/_ahdsgioahgaosidg_agioasdhgo/");
    system("rm -rf /tmp/\\(test_files\\)/");
    system("rm -rf /tmp/0ashdgioasdhgo_asdhgio\\&asjdgioadsjg/");
    system("rm -rf /tmp/\\&asdgasd/");


    system("mkdir /tmp/test_files");
    system("mkdir /tmp/ahsouifghasdgoiasdghah_sdgfuioashfdiosasdiafohdsoig_ashgioasdhaoisdhoifhasoi_aiosdfhasdoifhasodiufh");
    system("mkdir /tmp/_ahdsgioahgaosidg_agioasdhgo");
    system("mkdir /tmp/\\(test_files\\)");
    system("mkdir /tmp/0ashdgioasdhgo_asdhgio\\&asjdgioadsjg");
    system("mkdir /tmp/\\&asdgasd");


    system("cp /usr/share/backgrounds/default_background.jpg /tmp/test_files/");
    system("touch /tmp/test_files/test.desktop");
    system("touch /tmp/test_files/test");
    system("touch /tmp/test_files/test.coffee");
    system("touch /tmp/test_files/test.cpp");
    system("touch /tmp/test_files/test.css");
    system("touch /tmp/test_files/test.exe");
    system("touch /tmp/test_files/test.h");
    system("touch /tmp/test_files/test.html");
    system("touch /tmp/test_files/test.js");
    system("touch /tmp/test_files/test.m");
    system("touch /tmp/test_files/test.test");
    system("touch /tmp/test_files/test.c");
    system("touch /tmp/test_files/test.txt");
    system("touch /tmp/test_files/test.wpt");
    system("touch /tmp/test_files/test.xls");
    system("touch /tmp/test_files/test.ppt");
    system("touch /tmp/test_files/test.doc");

    system("cp /usr/share/applications/skype.desktop /tmp/test_files/");
    system("cp /usr/share/applications/deepin-desktop.desktop /tmp/test_files/");
    system("cp /usr/share/applications/deepin-media-player.desktop /tmp/test_files/");
    system("cp /usr/share/applications/deepin-system-settings.desktop /tmp/test_files/");
    system("cp /usr/share/applications/audacity.desktop /tmp/test_files/");
    system("cp /usr/share/applications/brasero.desktop /tmp/test_files/");

    system("touch ~/Desktop/snyh.txt");
    system("touch ~/Desktop/.snyh.txt");
    system("touch ~/Desktop/snyh.txt~");



    //gfileDirectory = g_ptr_array_new();
    // gfileDocument = g_ptr_array_new();
    // gappinfo = g_ptr_array_new();
    gfileDirectory = g_ptr_array_new_with_free_func(g_object_unref);
    gfileDocument = g_ptr_array_new_with_free_func(g_object_unref);
    gappinfo = g_ptr_array_new_with_free_func(g_object_unref);

    
    g_ptr_array_add(gfileDirectory, g_file_new_for_path("/tmp/test_files"));//0
    g_ptr_array_add(gfileDirectory, g_file_new_for_path("/tmp/ahsouifghasdgoiasdghah_sdgfuioashfdiosasdiafohdsoig_ashgioasdhaoisdhoifhasoi_aiosdfhasdoifhasodiufh"));//1
    g_ptr_array_add(gfileDirectory, g_file_new_for_path("/tmp/_ahdsgioahgaosidg_agioasdhgo"));//2
    g_ptr_array_add(gfileDirectory, g_file_new_for_path("/tmp/(test_files)"));//3
    g_ptr_array_add(gfileDirectory, g_file_new_for_path("/tmp/0ashdgioasdhgo_asdhgio&asjdgioadsjg"));//4
    g_ptr_array_add(gfileDirectory, g_file_new_for_path("/tmp/&asdgasd"));//5


    g_ptr_array_add(gfileDocument, g_file_new_for_path("/tmp/test_files/default_background.jpg"));//0
    g_ptr_array_add(gfileDocument, g_file_new_for_path("/tmp/test_files/skype.desktop"));//1
    g_ptr_array_add(gfileDocument, g_file_new_for_path("/tmp/test_files/text"));//2
    g_ptr_array_add(gfileDocument, g_file_new_for_path("/tmp/test_files/text.coffee"));//3
    g_ptr_array_add(gfileDocument, g_file_new_for_path("/tmp/test_files/text.cpp"));//4
    g_ptr_array_add(gfileDocument, g_file_new_for_path("/tmp/test_files/text.css"));//5
    g_ptr_array_add(gfileDocument, g_file_new_for_path("/tmp/test_files/text.exe"));//6
    g_ptr_array_add(gfileDocument, g_file_new_for_path("/tmp/test_files/text.h"));//7
    g_ptr_array_add(gfileDocument, g_file_new_for_path("/tmp/test_files/text.html"));//8
    g_ptr_array_add(gfileDocument, g_file_new_for_path("/tmp/test_files/text.js"));//9
    g_ptr_array_add(gfileDocument, g_file_new_for_path("/tmp/test_files/text.m"));//10
    g_ptr_array_add(gfileDocument, g_file_new_for_path("/tmp/test_files/text.test"));//11
    g_ptr_array_add(gfileDocument, g_file_new_for_path("/tmp/test_files/text.c"));//13
    g_ptr_array_add(gfileDocument, g_file_new_for_path("/tmp/test_files/text.txt"));//14
    g_ptr_array_add(gfileDocument, g_file_new_for_path("/tmp/test_files/text.wpt"));//15
    g_ptr_array_add(gfileDocument, g_file_new_for_path("/tmp/test_files/text.xls"));//16
    g_ptr_array_add(gfileDocument, g_file_new_for_path("/tmp/test_files/text.ppt"));//17
    g_ptr_array_add(gfileDocument, g_file_new_for_path("/tmp/test_files/text.doc"));//18
    g_ptr_array_add(gfileDocument, g_file_new_for_path("/tmp/test_files/deepin-system-settings.desktop"));//19

    g_ptr_array_add(gappinfo, g_desktop_app_info_new_from_filename("/tmp/test_files/skype.desktop"));//0
    g_ptr_array_add(gappinfo, g_desktop_app_info_new_from_filename("/tmp/test_files/deepin-desktop.desktop"));//1
    g_ptr_array_add(gappinfo, g_desktop_app_info_new_from_filename("/tmp/test_files/deepin-media-player.desktop"));//2
    g_ptr_array_add(gappinfo, g_desktop_app_info_new_from_filename("/tmp/test_files/deepin-system-settings.desktop"));//3
    g_ptr_array_add(gappinfo, g_desktop_app_info_new_from_filename("/tmp/test_files/audacity.desktop"));//4
    g_ptr_array_add(gappinfo, g_desktop_app_info_new_from_filename("/tmp/test_files/brasero.desktop"));//5

}

void tear_down_fixture()
{
    g_ptr_array_unref(gfileDirectory);
    g_ptr_array_unref(gfileDocument);
    g_ptr_array_unref(gappinfo);
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

void func_test_entry_arraycontainer(gboolean (*func)(Entry*,const ArrayContainer),Entry* variable,const ArrayContainer fs,gboolean value_return)
{
        gboolean fuc_tmp = func(variable,fs);
        if(FLAG_PRITN_RESULT)
        {
            g_message("func result:\n");
            g_message("%d\n",fuc_tmp);
            g_message("func result over.\n");
        }
        g_assert(fuc_tmp == value_return);
        FLAG_PRITN_RESULT = FALSE;
}
