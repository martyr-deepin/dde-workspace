#ifdef __DUI_DEBUG
#include "desktop_test.h"

int TEST_MAX_COUNT = 100000;
int TEST_MAX_MEMORY = RES_IN_MB(90);

extern void test_entry();
extern void test_fileops_delete();
extern void test_fileops_trash();
extern void test_fileops_clipboard();
extern void test_fileops_error_reporting();
extern void test_fileops_error_dialog();

extern void test_mime_actions();
extern void test_thumbnails();
extern void test_gnome_desktop_thumbnail();

void desktop_test()
{
    g_message("desktop test start...");

    // test_entry();//test ok 
    // ps:
    //1. g_file_trash() has bug when trash times and speed too fast
    //2. dentry_clipborad_paste() has bug when speed too fast ,becuase the X cannot follow it
    //3. find and fix a serious bug : symblic_link copy to desktop will kill the desktop actually
    //4. some bug not fix: 
    //a. void _do_dereference_symlink_copy(GFile* src, GFile* dest)    
    //      if (!g_file_copy(src, dest, G_FILE_COPY_NONE, NULL, NULL, NULL, &error))
    //      ----------------------here we should unity the standard ops for symbolic_link ---------------------
    //      already fix the standard ops for symbolic_link
    //b. traverse_directory
    //      g_warning ("traverse_directory 1: %s", error->message);


    // test_fileops_delete();//test ok
    
    // test_fileops_trash();//test ok
    
    // test_fileops_clipboard();//test ok
    
    // test_fileops_error_reporting();//hsanot tested

    // test_fileops_error_dialog();//hasnot tested
    
    // test_mime_actions();////hasnot tested   because it used in dentry_launch()

    test_thumbnails();//test over
    // but there is a bug ,but cannot be reviewed ,and it is hard to be shown :
    // after test programe run 100% over,there perhaps be a error to kill ./desktop -d but without any messageout
    // when I run test in gdb ,still no useful messageout
    // when I run test in valgrind to track the memory-out,it messageout:
// ==9299==    by 0x7A95AC0: _cairo_compositor_paint (cairo-compositor.c:65)
// ==9299==    by 0x7AD9640: _cairo_surface_paint (cairo-surface.c:2022)
// ==9299==    by 0x7A9D18B: _cairo_gstate_paint (cairo-gstate.c:1067)
// ==9299==    by 0x7A97DC8: _cairo_default_context_paint_with_alpha (cairo-default-context.c:969)
// ==9299==    by 0x7A90726: cairo_paint_with_alpha (cairo.c:2026)
// ==9299== 
// ==9299== LEAK SUMMARY:
// ==9299==    definitely lost: 6,288 bytes in 11 blocks
// ==9299==    indirectly lost: 16,790 bytes in 674 blocks
// ==9299==      possibly lost: 1,821,394 bytes in 16,770 blocks
// ==9299==    still reachable: 2,152,849 bytes in 18,993 blocks
// ==9299==         suppressed: 0 bytes in 0 blocks
// ==9299== Reachable blocks (those to which a pointer was found) are not shown.
// ==9299== To see them, rerun with: --leak-check=full --show-reachable=yes
// ==9299== 
// ==9299== For counts of detected and suppressed errors, rerun with: -v
// ==9299== ERROR SUMMARY: 1655 errors from 1655 contexts (suppressed: 3 from 3)
// 已杀死

    //there still isnot any useful DEBUG message
    //and I g_message in somewhere (begin function ,end function ,begin if and so on ),but ,there still isnot DEBUG message useful

    /* test inotify successful.*/
    //test_inotify();

    // test_dbus();

    /* test_background(); */

    // test_background_util();

    /* test_desktop(); */

    /* test_utils(); */

    //test_other();
    //
    
    g_message("desktop tests All passed!!!");
}

#endif
