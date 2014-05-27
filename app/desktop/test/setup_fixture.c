#include "desktop_test.h"

GPtrArray *gfileDirectory = NULL;
GPtrArray *gfileDocument = NULL;
GPtrArray *gappinfo= NULL;

gboolean FLAG_PRITN_RESULT = TRUE;


gchar *file1 = "/tmp/test_files/default_background.jpg";
gchar *file2 = "/tmp/test_files/text.test";
gchar *rich_dir = "/tmp/test_files/.deepin_rich_dir_desktop_test";
gchar *app_0 = "/tmp/test_files/skype.desktop";
gchar *app_1 = "/tmp/test_files/deepin-media-player.desktop";



void setup_fixture()
{
    // g_mkdir("test_files");
    // g_creat("test_files/test.c");

    int dump G_GNUC_UNUSED = 0;
    dump = system("rm -rf /tmp/test_files/");
    dump = system("rm -rf /tmp/ahsouifghasdgoiasdghah_sdgfuioashfdiosasdiafohdsoig_ashgioasdhaoisdhoifhasoi_aiosdfhasdoifhasodiufh/");
    dump = system("rm -rf /tmp/_ahdsgioahgaosidg_agioasdhgo/");
    dump = system("rm -rf /tmp/\\(test_files\\)/");
    dump = system("rm -rf /tmp/0ashdgioasdhgo_asdhgio\\&asjdgioadsjg/");
    dump = system("rm -rf /tmp/\\&asdgasd/");


    dump = system("mkdir /tmp/test_files");
    dump = system("mkdir /tmp/ahsouifghasdgoiasdghah_sdgfuioashfdiosasdiafohdsoig_ashgioasdhaoisdhoifhasoi_aiosdfhasdoifhasodiufh");
    dump = system("mkdir /tmp/_ahdsgioahgaosidg_agioasdhgo");
    dump = system("mkdir /tmp/\\(test_files\\)");
    dump = system("mkdir /tmp/0ashdgioasdhgo_asdhgio\\&asjdgioadsjg");
    dump = system("mkdir /tmp/\\&asdgasd");


    dump = system("cp /usr/share/backgrounds/default_background.jpg /tmp/test_files/");
    dump = system("touch /tmp/test_files/test.desktop");
    dump = system("touch /tmp/test_files/test");
    dump = system("touch /tmp/test_files/test.coffee");
    dump = system("touch /tmp/test_files/test.cpp");
    dump = system("touch /tmp/test_files/test.css");
    dump = system("touch /tmp/test_files/test.exe");
    dump = system("touch /tmp/test_files/test.h");
    dump = system("touch /tmp/test_files/test.html");
    dump = system("touch /tmp/test_files/test.js");
    dump = system("touch /tmp/test_files/test.m");
    dump = system("touch /tmp/test_files/test.test");
    dump = system("touch /tmp/test_files/test.c");
    dump = system("touch /tmp/test_files/test.txt");
    dump = system("touch /tmp/test_files/test.wpt");
    dump = system("touch /tmp/test_files/test.xls");
    dump = system("touch /tmp/test_files/test.ppt");
    dump = system("touch /tmp/test_files/test.doc");

    dump = system("cp /usr/share/applications/skype.desktop /tmp/test_files/");
    dump = system("cp /usr/share/applications/deepin-desktop.desktop /tmp/test_files/");
    dump = system("cp /usr/share/applications/deepin-media-player.desktop /tmp/test_files/");
    dump = system("cp /usr/share/applications/deepin-system-settings.desktop /tmp/test_files/");
    dump = system("cp /usr/share/applications/wine.desktop /tmp/test_files/");
    dump = system("cp /usr/share/applications/xchat.desktop /tmp/test_files/");

    dump = system("touch ~/Desktop/snyh.txt");
    dump = system("touch ~/Desktop/.snyh.txt");
    dump = system("touch ~/Desktop/snyh.txt~");



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
        g_assert(0 == g_strcmp0(s, value_return));
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

