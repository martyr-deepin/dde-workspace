#include "desktop_test.h"

#define TEST_THEM FALSE

void test_entry()
{
    setup_fixture();

#if 0

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

#endif
    extern char* dentry_get_icon(Entry* e);
    Test({
        
           /*char * icon  = dentry_get_icon(g_ptr_array_index(gappinfo,0));*/
           char * icon  = dentry_get_icon(g_ptr_array_index(gfileDirectory,0));
           g_free(icon);
        /*func_test_entry_char(dentry_get_icon,g_ptr_array_index(gfileDirectory,0), "/usr/share/icons/Faenza/places/48/inode-directory.png");*/
        //the icon isn't icon which in .thumbnail/ ,and the file icon show first in thumbnail (code in desktop_item.coffee->set_icon)
        /*func_test_entry_char(dentry_get_icon,g_ptr_array_index(gfileDocument,6), "/usr/share/icons/Faenza/mimetypes/48/application-x-ms-dos-executable.png");*/
        /*func_test_entry_char(dentry_get_icon,g_ptr_array_index(gappinfo,0), "/usr/share/icons/Deepin/apps/48/skype.png");*/
        /*func_test_entry_char(dentry_get_icon,g_ptr_array_index(gappinfo,4), "/usr/share/icons/Deepin/apps/48/audacity.png");*/
    },"dentry_get_icon");

#if 0
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

#endif


#if 0
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

#endif

#if 0
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
#endif

#if 0
    extern gboolean dentry_move(ArrayContainer fs, GFile* dest, gboolean prompt);
    extern void dentry_copy (ArrayContainer fs, GFile* dest);
    extern void dentry_trash(ArrayContainer fs);
    extern void dentry_delete_files(ArrayContainer fs, gboolean show_dialog);

    gpointer* _gp = g_object_ref(g_ptr_array_index(gappinfo,0));
    // system("ln -s /tmp/compiz.log /tmp/test_files/");
    // GFile* _gp = g_file_new_for_uri("file:///tmp/test_files/compiz.log");
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


    g_message("2copy start");
        GFile* _src2 = g_file_new_for_uri("file:///tmp/test_files/skype.desktop");
        GFile* _dest2 = g_file_new_for_uri("file:///tmp/");
        ArrayContainer _fs2;
        _fs2.data=&_src2;
        _fs2.num = 1;
        dentry_copy(_fs2,_dest2);
        g_object_unref(_dest2);
        ArrayContainer_free0(_fs2);
    g_message("2copy end");

    g_message("3delete start");
        GFile* _src3 = g_file_new_for_uri("file:///tmp/skype.desktop");
        ArrayContainer _fs3;
        _fs3.data=&_src3;
        _fs3.num = 1;
        dentry_delete_files(_fs3,FALSE);
        ArrayContainer_free0(_fs3);
    g_message("3delete end");

    },"dentry_move");
    ArrayContainer_free0(fs);
    g_object_unref(dest);
#endif

#if 0
    gpointer* _gp = g_object_ref(g_ptr_array_index(gfileDirectory,0));
    ArrayContainer fs = {&_gp,1};
    GFile* dest = g_file_new_for_uri("file:///home/ycl");

    Test({
    g_message("move start");
        dentry_move(fs,dest,FALSE);
    g_message("move end");


    g_message("0copy start");
        GFile* _dest0 = g_file_new_for_uri("file:///tmp/");
        GFile* _src0 = g_file_new_for_uri("file:///tmp/test_files");
        ArrayContainer _fs0;
        _fs0.data=&_src0;
        _fs0.num = 1;
        dentry_copy(_fs0,_dest0);
        g_object_unref(_dest0);
        ArrayContainer_free0(_fs0);
    g_message("0copy end");


    g_message("1trash start");
        GFile* _src1 = g_file_new_for_uri("file:///tmp/test_files");
        ArrayContainer _fs1;
        _fs1.data=&_src1;
        _fs1.num = 1;
        dentry_trash(_fs1);
        ArrayContainer_free0(_fs1);
    g_message("1trash end");


    g_message("2copy start");
        GFile* _src2 = g_file_new_for_uri("file:///tmp/test_files");
        GFile* _dest2 = g_file_new_for_uri("file:///home/ycl/");
        ArrayContainer _fs2;
        _fs2.data=&_src2;
        _fs2.num = 1;
        dentry_copy(_fs2,_dest2);
        g_object_unref(_dest2);
        ArrayContainer_free0(_fs2);
    g_message("2copy end");

    g_message("3delete start");
        GFile* _src3 = g_file_new_for_uri("file:///tmp/test_files");
        ArrayContainer _fs3;
        _fs3.data=&_src3;
        _fs3.num = 1;
        dentry_delete_files(_fs3,FALSE);
        ArrayContainer_free0(_fs3);
    g_message("3delete end");

    },"dentry_move");
    ArrayContainer_free0(fs);
    g_object_unref(dest);
#endif

#if 0
    extern void dentry_copy_dereference_symlink(ArrayContainer fs, GFile* dest_dir);
    system("ln -s /tmp/test_files /tmp/test_files_link ");
    Test({
        system("mkdir /tmp/test_files_tmp");

    g_message("copy_dereference_symlink start");
        GFile* src = g_file_new_for_uri("file:///tmp/test_files_link");
        GFile* dest = g_file_new_for_uri("file:///tmp/test_files_tmp/");
        ArrayContainer fs;
        fs.data=&src;
        fs.num = 1;
        dentry_copy_dereference_symlink(fs,dest);
        ArrayContainer_free0(fs);
        g_object_unref(dest);
    g_message("copy_dereference_symlink end");

        system("rm -rf /tmp/test_files_tmp/");
    },"dentry_copy_dereference_symlink");
#endif

#if 0

    extern void dentry_clipboard_copy(ArrayContainer fs);
    extern void dentry_clipboard_cut(ArrayContainer fs);
    extern void dentry_clipboard_paste(GFile* dest_dir);
    extern gboolean dentry_can_paste ();
    system("rm /tmp/skype.desktop");

    Test({

    g_message("dentry_clipboard_cut start");
        GFile* src2 = g_file_new_for_uri("file:///tmp/test_files/skype.desktop");
        ArrayContainer fs2;
        fs2.data=&src2;
        fs2.num = 1;
        dentry_clipboard_cut(fs2);
        ArrayContainer_free0(fs2);
    g_message("dentry_clipboard_cut end");

    gboolean b1 = dentry_can_paste();
    g_assert(b1 == TRUE);
    if (b1)
    {
        /* code */
        g_message("1dentry_clipboard_paste start");
        GFile* dest1 = g_file_new_for_uri("file:///tmp/");
        dentry_clipboard_paste(dest1);
        g_object_unref(dest1);
        g_message("1dentry_clipboard_paste end");
    }

    g_message("dentry_clipboard_copy start");
        GFile* src = g_file_new_for_uri("file:///tmp/skype.desktop");
        ArrayContainer fs;
        fs.data=&src;
        fs.num = 1;
        dentry_clipboard_copy(fs);
        ArrayContainer_free0(fs);
    g_message("dentry_clipboard_copy end");

    gboolean b2 = dentry_can_paste();
    g_assert(b2 == TRUE);
    if (b2)
    {
        /* code */
        g_message("2dentry_clipboard_paste start");
        GFile* dest2 = g_file_new_for_uri("file:///tmp/test_files/");
        dentry_clipboard_paste(dest2);
        g_object_unref(dest2);
        g_message("2dentry_clipboard_paste end");
    }

    system("rm /tmp/skype.desktop");

    },"dentry_clipboard_copy cut paste can_paste");



    extern void dentry_confirm_trash();
    extern GFile* dentry_get_trash_entry();
    extern double dentry_get_trash_count();
    extern char* dentry_get_uri(Entry* e);
    extern char* dentry_get_name(Entry* e);
    Test(
    {
        // dentry_confirm_trash();

        GFile* f = dentry_get_trash_entry();
        FLAG_PRITN_RESULT = TRUE;
        func_test_entry_char(dentry_get_name,f,"/");
        FLAG_PRITN_RESULT = TRUE;
        func_test_entry_char(dentry_get_uri,f,"trash:///");

        // char* name  = dentry_get_name(f);
        // g_message("name:%s",name);
        // g_assert(0 == g_strcmp0(name,"/");
        // g_free(name);

        // char* uri = dentry_get_uri(f);
        // g_message("uri:%s",uri);
        // g_assert(0 == g_strcmp0(uri,"trash:///");
        // g_free(uri);

        double d = dentry_get_trash_count();
        g_message("count:%f",d);
        g_object_unref(f);

    },"dentry_confirm_trash dentry_get_trash_entry dentry_get_trash_count");
#endif

    tear_down_fixture();
}

