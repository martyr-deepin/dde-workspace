#include "desktop_test.h"
extern void setup_fixture();
extern void tear_down_fixture();
extern void func_test_entry_char(char* (*func)(Entry*),Entry* variable,char* value_return);
extern void func_test_entry_arraycontainer(gboolean (*func)(Entry*,const ArrayContainer),Entry* variable,const ArrayContainer fs,gboolean value_return);

gboolean FLAG_PRITN_RESULT = TRUE;
gboolean TEST_OK = FALSE;
GPtrArray *gfileDirectory = NULL;
GPtrArray *gfileDocument = NULL;
GPtrArray *gappinfo= NULL;

#define CURRENT_DIR NULL

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

void test_entry()
{
    setup_fixture();

    #if(TEST_OK)

    extern Entry* dentry_get_desktop();
    Test({
        Entry* e = dentry_get_desktop();
        g_object_unref(e);
    },"dentry_get_desktop");

    extern gboolean dentry_should_move(Entry* e);
    Test({
        dentry_should_move(g_ptr_array_index(gfileDirectory,0));
        dentry_should_move(g_ptr_array_index(gfileDocument,0));
        dentry_should_move(g_ptr_array_index(gappinfo,0));
    },"dentry_should_move");

    extern gboolean dentry_is_native(Entry* e);
    Test({
        dentry_is_native(g_ptr_array_index(gfileDirectory,0));
        dentry_is_native(g_ptr_array_index(gfileDocument,0));
        dentry_is_native(g_ptr_array_index(gappinfo,0));
    },"dentry_is_native");    

    extern double dentry_get_type(Entry* e);
    Test({
        dentry_get_type(g_ptr_array_index(gfileDirectory,0));
        dentry_get_type(g_ptr_array_index(gfileDocument,0));
        dentry_get_type(g_ptr_array_index(gappinfo,0));
    },"dentry_get_type");

    extern JSObjectRef dentry_get_flags (Entry* e);
    Test({
        dentry_get_flags(g_ptr_array_index(gfileDirectory,0));
        dentry_get_flags(g_ptr_array_index(gfileDocument,0));
        dentry_get_flags(g_ptr_array_index(gappinfo,0));
    },"dentry_get_flags");    


    extern char* dentry_get_name(Entry* e);
    Test({
        func_test_entry_char(dentry_get_name,g_ptr_array_index(gfileDirectory,0),"test_files");
        func_test_entry_char(dentry_get_name,g_ptr_array_index(gfileDocument,0),"default_background.jpg");
        func_test_entry_char(dentry_get_name,g_ptr_array_index(gappinfo,0),"Skype");
        },"dentry_get_name");


    extern char* dentry_get_uri(Entry* e);
    Test({
        func_test_entry_char(dentry_get_uri,g_ptr_array_index(gfileDirectory,0),"file:///tmp/test_files");
        func_test_entry_char(dentry_get_uri,g_ptr_array_index(gfileDirectory,1),"file:///tmp/ahsouifghasdgoiasdghah_sdgfuioashfdiosasdiafohdsoig_ashgioasdhaoisdhoifhasoi_aiosdfhasdoifhasodiufh");
        func_test_entry_char(dentry_get_uri,g_ptr_array_index(gfileDirectory,2),"file:///tmp/_ahdsgioahgaosidg_agioasdhgo");
        func_test_entry_char(dentry_get_uri,g_ptr_array_index(gfileDirectory,3),"file:///tmp/%28test_files%29");
        func_test_entry_char(dentry_get_uri,g_ptr_array_index(gfileDirectory,4),"file:///tmp/0ashdgioasdhgo_asdhgio%26asjdgioadsjg");
        func_test_entry_char(dentry_get_uri,g_ptr_array_index(gfileDocument,0), "file:///tmp/test_files/default_background.jpg");
        func_test_entry_char(dentry_get_uri,g_ptr_array_index(gappinfo,0),"file:///home/ycl/Desktop/skype.desktop");
    },"dentry_get_uri"); 
    

    extern char* dentry_get_icon(Entry* e);    
    Test({
        func_test_entry_char(dentry_get_icon,g_ptr_array_index(gfileDirectory,0), "/usr/share/icons/Faenza/places/48/inode-directory.png");
        //the icon isn't icon which in .thumbnail/ ,and the file icon show first in thumbnail (code in desktop_item.coffee->set_icon)
        func_test_entry_char(dentry_get_icon,g_ptr_array_index(gfileDocument,6), "/usr/share/icons/Faenza/mimetypes/48/application-x-ms-dos-executable.png");
        func_test_entry_char(dentry_get_icon,g_ptr_array_index(gappinfo,0), "/usr/share/icons/Deepin/apps/48/skype.png");
        func_test_entry_char(dentry_get_icon,g_ptr_array_index(gappinfo,4), "/usr/share/icons/Deepin/apps/48/audacity.png");
    },"dentry_get_icon");


    extern gboolean dentry_can_thumbnail(Entry* e);
    gboolean bool_return = false;
    Test({
        // bool_return = dentry_can_thumbnail(g_ptr_array_index(gfileDirectory,0));
        bool_return = dentry_can_thumbnail(g_ptr_array_index(gfileDocument,0));
        // dentry_can_thumbnail(g_ptr_array_index(gappinfo,0));
    },"dentry_can_thumbnail");
    g_message("%d",bool_return);


    extern char* dentry_get_thumbnail(Entry* e);
    FLAG_PRITN_RESULT = TRUE;
    Test({
        // gfileDirectory :dentry_can_thumbnail is false
        func_test_entry_char(dentry_get_thumbnail,g_ptr_array_index(gfileDirectory,0), ".thumbnails/normal/692aec2ade9c8ea309697fbd5e9d7899.png");
        // .desktop file :dentry_can_thumbnail is false
        func_test_entry_char(dentry_get_thumbnail,g_ptr_array_index(gfileDocument,0), ".thumbnails/normal/048e2190b2e95ed836646e70e4978378.png");
        func_test_entry_char(dentry_get_thumbnail,g_ptr_array_index(gappinfo,0), "/usr/share/icons/Deepin/apps/48/skype.png");
    },"dentry_get_thumbnail");


    extern char* dentry_get_id(Entry* e);
    Test({
        // func_test_entry_char(dentry_get_id, g_ptr_array_index(gfileDirectory,0),"5565c4012ed4c6f1007c2b86aea48956");
        // func_test_entry_char(dentry_get_id, g_ptr_array_index(gfileDirectory,1),"ecacee630d535cfc22f1862bc7b97e5f");
        // func_test_entry_char(dentry_get_id, g_ptr_array_index(gfileDirectory,2),"9c0ca7cf2d9da7c9038eaa17149b918b");
        // func_test_entry_char(dentry_get_id, g_ptr_array_index(gfileDirectory,3),"e7ad45c1782111ba49c12be65a5ec70c");
        func_test_entry_char(dentry_get_id, g_ptr_array_index(gfileDirectory,4),"a1a31a86cd4d3957bc1a526c92391c8b");

        // func_test_entry_char(dentry_get_id,gfileDocument,"9e59f7e96e3ca18daa14f5adbbbdcf65");
        // func_test_entry_char(dentry_get_id,gfileDocument,"221d498715901ee41709b24e36069fed");
        // func_test_entry_char(dentry_get_id,gfileDocument,"ee38506f63e67c3f1743ca4eeddb1fcb");
        // func_test_entry_char(dentry_get_id,gappinfo,"e9ab3a2fb814421ed6d747c62851abb3");
    },"dentry_get_id");


    extern gboolean dentry_launch(Entry* e, const ArrayContainer fs);
    // const ArrayContainer fs = {g_ptr_array_index(gfileDirectory,0),1};
    // const ArrayContainer fs = _normalize_array_container(*(ArrayContainer*)gfileDirectory);
    // const ArrayContainer fs =  *(ArrayContainer*)gfileDirectory;
    // gpointer* _gp = g_ptr_array_free(gfileDirectory,FALSE) ;
    // gpointer* _gp = gfileDirectory->pdata;
        
    // gpointer* _gp = g_ptr_array_index(gfileDirectory,0);    
    // gpointer* _gp = g_ptr_array_index(gfileDirectory,1);
    // gpointer* _gp = g_ptr_array_index(gappinfo,0);    
    // gpointer* _gp = g_ptr_array_index(gappinfo,1);    
    gpointer* _gp = g_object_ref(g_ptr_array_index(gappinfo,3));    
    const ArrayContainer fs = {&_gp,1};
    Test({
            func_test_entry_arraycontainer(dentry_launch,_gp,fs,TRUE);
        },"dentry_launch");
    g_object_unref(_gp);
    ArrayContainer_free0(fs);
    //g_assert (G_IS_OBJECT(_gp));


    extern ArrayContainer dentry_list_files(GFile* f);
    GFile* f = g_ptr_array_index(gfileDirectory,0);
    Test({
        ArrayContainer array = dentry_list_files(f);
        ArrayContainer_free(array);
    },"dentry_list_files");    

    extern Entry* dentry_create_by_path(const char* path);
    // const char* path = dentry_get_icon_path(g_ptr_array_index(gappinfo,0));
    // const char* path = dentry_get_icon_path(g_ptr_array_index(gappinfo,1));//deepin-desktop.desktop has not default icon ,so it return NULL
    // const char* path = dentry_get_icon_path(g_ptr_array_index(gappinfo,2));
    // const char* path = dentry_get_icon_path(g_ptr_array_index(gappinfo,3));
    // const char* path = dentry_get_icon_path(g_ptr_array_index(gappinfo,4));
    const char* path = dentry_get_icon_path(g_ptr_array_index(gappinfo,5));
    g_message("%s\n",path);
    Test({
        Entry* e = dentry_create_by_path(path);
        g_object_unref(e);
    },"dentry_create_by_path");    


    extern gboolean dentry_is_fileroller_exist();
    gboolean b = FALSE;
    Test({
        b = dentry_is_fileroller_exist();
    },"dentry_is_fileroller_exist");
    g_message("%d",b);


    // those function not test
    //extern double dentry_files_compressibility(ArrayContainer fs);
    //void dentry_compress_files(ArrayContainer fs);
    //void dentry_decompress_files(ArrayContainer fs);
    //void dentry_decompress_files_here(ArrayContainer fs);


    extern double dentry_get_mtime(Entry* e);
    double d = 0;
    Test({
        // d = dentry_get_mtime(g_ptr_array_index(gfileDirectory,0));
        d = dentry_get_mtime(g_ptr_array_index(gfileDocument,0));
        // d = dentry_get_mtime(g_ptr_array_index(gfileDocument,1));
        // d = dentry_get_mtime(g_ptr_array_index(gappinfo,0));
    },"dentry_get_mtime");
    g_message("%f",d);


    extern gboolean dentry_set_name(Entry* e, const char* name);
    gboolean b = 0;
    system("rm -rf test_name_1/");
    b = dentry_set_name(g_ptr_array_index(gfileDirectory,0),"test_name_1");
    Test({
        GFile* f1 = dentry_create_by_path("test_name_1");
        b = dentry_set_name(f1,"test_name_2");
        GFile* f2 = dentry_create_by_path("test_name_2");
        b = dentry_set_name(f2,"test_name_1");
        g_object_unref(f1);
        g_object_unref(f2);
    },"dentry_set_name");
    system("rm -rf test_name_1/");
    g_message("%d",b);

    #endif

    extern gboolean dentry_move(ArrayContainer fs, GFile* dest, gboolean prompt);
    extern void dentry_copy (ArrayContainer fs, GFile* dest);
    extern void dentry_trash(ArrayContainer fs);
    extern void dentry_delete_files(ArrayContainer fs, gboolean show_dialog);

#if(0)
    gpointer* _gp = g_object_ref(g_ptr_array_index(gappinfo,0));    
    ArrayContainer fs = {&_gp,1};
    GFile* dest = g_file_new_for_uri("file:///tmp");

    Test({

    g_message("start");
        dentry_move(fs,dest,FALSE);        
    // g_message("move end");


    // g_message("0copy start");
        GFile* _dest0 = g_file_new_for_uri("file:///tmp/test_files/");
        GFile* _src0 = g_file_new_for_uri("file:///tmp/skype.desktop");
        ArrayContainer _fs0;
        _fs0.data=&_src0;
        _fs0.num = 1;
        dentry_copy(_fs0,_dest0);   
        g_object_unref(_dest0);
        ArrayContainer_free0(_fs0);
    // g_message("0copy end");



    // g_message("1trash start");
        GFile* _src1 = g_file_new_for_uri("file:///tmp/skype.desktop");
        ArrayContainer _fs1;
        _fs1.data=&_src1;
        _fs1.num = 1;
        dentry_trash(_fs1);
        ArrayContainer_free0(_fs1);
    g_message(" end");

// #if(0)

//     g_message("2copy start");
//         GFile* _src2 = g_file_new_for_uri("file:///tmp/test_files/skype.desktop");
//         GFile* _dest2 = g_file_new_for_uri("file:///tmp/");
//         ArrayContainer _fs2;
//         _fs2.data=&_src2;
//         _fs2.num = 1;
//         dentry_copy(_fs2,_dest2);
//         g_object_unref(_dest2);
//         ArrayContainer_free0(_fs2);
//     g_message("2copy end");

//     g_message("3delete start");
//         GFile* _src3 = g_file_new_for_uri("file:///tmp/skype.desktop");
//         ArrayContainer _fs3;
//         _fs3.data=&_src3;
//         _fs3.num = 1;
//         dentry_delete_files(_fs3,FALSE);
//         ArrayContainer_free0(_fs3);
//     g_message("3delete end");
// #endif

//     },"dentry_move");
//     ArrayContainer_free0(fs);
//     g_object_unref(dest);
// #endif    

// #if(0)
//     gpointer* _gp = g_object_ref(g_ptr_array_index(gfileDirectory,0));    
//     ArrayContainer fs = {&_gp,1};
//     GFile* dest = g_file_new_for_uri("file:///home/ycl");

//     Test({
//     g_message("move start");
//         dentry_move(fs,dest,FALSE);        
//     g_message("move end");


//     g_message("0copy start");
//         GFile* _dest0 = g_file_new_for_uri("file:///tmp/");
//         GFile* _src0 = g_file_new_for_uri("file:///tmp/test_files");
//         ArrayContainer _fs0;
//         _fs0.data=&_src0;
//         _fs0.num = 1;
//         dentry_copy(_fs0,_dest0);
//         g_object_unref(_dest0);
//         ArrayContainer_free0(_fs0);
//     g_message("0copy end");


//     g_message("1trash start");
//         GFile* _src1 = g_file_new_for_uri("file:///tmp/test_files");
//         ArrayContainer _fs1;
//         _fs1.data=&_src1;
//         _fs1.num = 1;
//         dentry_trash(_fs1);
//         ArrayContainer_free0(_fs1);
//     g_message("1trash end");


//     g_message("2copy start");
//         GFile* _src2 = g_file_new_for_uri("file:///tmp/test_files");
//         GFile* _dest2 = g_file_new_for_uri("file:///home/ycl/");
//         ArrayContainer _fs2;
//         _fs2.data=&_src2;
//         _fs2.num = 1;
//         dentry_copy(_fs2,_dest2);
//         g_object_unref(_dest2);
//         ArrayContainer_free0(_fs2);
//     g_message("2copy end");

//     g_message("3delete start");
//         GFile* _src3 = g_file_new_for_uri("file:///tmp/test_files");
//         ArrayContainer _fs3;
//         _fs3.data=&_src3;
//         _fs3.num = 1;
//         dentry_delete_files(_fs3,FALSE);
//         ArrayContainer_free0(_fs3);
//     g_message("3delete end");

//     },"dentry_move");
//     ArrayContainer_free0(fs);
//     g_object_unref(dest);
// #endif



    Test({
        system("touch /tmp/test.c");
        g_message("1trash start");
        GFile* _src1 = g_file_new_for_uri("file:///tmp/test.c");
        // ArrayContainer _fs1;
        // _fs1.data=&_src1;
        // _fs1.num = 1;
        // dentry_trash(_fs1);
        // ArrayContainer_free0(_fs1);

        g_file_trash (_src1, NULL, NULL);/*the test program still dead in 28% ,means the GLIB function-org g_file_trash has bug in too times to trash*/
        // g_object_unref(_src1);

        g_message(" trash end");
    },"dentry_trash");

    tear_down_fixture();
}
