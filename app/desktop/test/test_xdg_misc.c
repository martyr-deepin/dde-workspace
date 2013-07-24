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

    // get the $XDG_DESKTOP_DIR value
    char* get_desktop_dir(gboolean update);

    // convert the icon name to the really icon path, seea also "set_default_theme"
    char* icon_name_to_path(const char* name, int size);
    char* icon_name_to_path_with_check_xpm(const char* name, int size);
    char* lookup_icon_by_gicon(GIcon* icon);

    Test({
        set_default_theme("Deepin-UI");
    }, "set_default_theme");

    tear_down_fixture();
}
