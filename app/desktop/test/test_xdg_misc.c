#include "desktop_test.h"
void test_xdg_misc()
{
	setup_fixture();

    // the really icon path is determined by theme
    void set_default_theme(const char* theme);
    // deal with the NotShowIn/OnlyShowIn filed. 
    void set_desktop_env_name(const char* name);

    // change the desktop file 's current locale name to "name"
    gboolean change_desktop_entry_name(const char* path, const char* name);

    // convert the icon name to the really icon path, seea also "set_default_theme"
    char* icon_name_to_path(const char* name, int size);
    char* icon_name_to_path_with_check_xpm(const char* name, int size);
    char* lookup_icon_by_gicon(GIcon* icon);

    //--------templates--------//
    char *   nautilus_get_xdg_dir                        (const char *type);

    gboolean nautilus_should_use_templates_directory     (void);
    char *   nautilus_get_templates_directory            (void);
    char *   nautilus_get_templates_directory_uri        (void);
    void     nautilus_create_templates_directory         (void);
    ArrayContainer natilus_get_templates_files(void);

    
#if 0 
    Test({
        char* c = nautilus_get_templates_directory_uri();
        g_message("%s",c);
        g_free(c);
    }, "nautilus_get_templates_directory_uri");
#endif

#if 0
    Test({
        ArrayContainer fs = natilus_get_templates_files();
        GFile* src;
        for(size_t i = 0; i< fs.num;i++)
        {
            src=&(fs.data);
            char* path = g_file_get_path(src);
            g_message("path:%s",path);
            g_free(path);
        }
        ArrayContainer_free(fs);
    }, "natilus_get_templates_files");
#endif
    tear_down_fixture();
}
