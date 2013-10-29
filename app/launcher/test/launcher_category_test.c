#ifdef __DUI_DEBUG

#include <gio/gdesktopappinfo.h>
#include "launcher_test.h"
#include "../launcher_category.h"

extern int find_category_id(const char* category_name);
extern GList* _remove_other_category(GList* categories);
extern GList* _get_x_category(GDesktopAppInfo* info);
extern GList* get_deepin_categories(GDesktopAppInfo* info);
extern void _load_category_info(GPtrArray* category_infos);

void test_find_category_id()
{
    Test({
         g_assert(find_category_id("system") == 8);
         }, "find_category_id");
}


void test__remove_other_category()
{
    Test({
         GList* l = NULL;
         l = g_list_append(l, GINT_TO_POINTER(-2));
         l = g_list_append(l, GINT_TO_POINTER(-2));
         l = _remove_other_category(l);
         g_assert(g_list_length(l) == 0);
         g_clear_pointer(&l, g_list_free);

         l = g_list_append(l, GINT_TO_POINTER(0));
         l = g_list_append(l, GINT_TO_POINTER(-2));
         l = _remove_other_category(l);
         g_assert(g_list_length(l) == 1
                  && GPOINTER_TO_INT(g_list_first(l)->data) == 0);
         g_list_free(l);
         }, "_remove_other_category");
}


void test__get_x_category()
{
    GDesktopAppInfo* firefox = g_desktop_app_info_new("firefox.desktop");
    // use a app not in deepin database
    GDesktopAppInfo* self = g_desktop_app_info_new("chrome-iiooodelglhkcpgbajoejffhijaclcdg-Default.desktop");
    Test({
         GList* l = _get_x_category(firefox);
         g_assert(g_list_length(l) >= 1);
         g_clear_pointer(&l, g_list_free);

         l = _get_x_category(self);
         g_assert(g_list_length(l) >= 1);
         g_list_free(l);
         }, "_get_x_category");
    g_object_unref(firefox);
    g_object_unref(self);
}


void test_get_deepin_categories()
{
    GDesktopAppInfo* firefox = g_desktop_app_info_new("firefox.desktop");
    GDesktopAppInfo* self = g_desktop_app_info_new("chrome-iiooodelglhkcpgbajoejffhijaclcdg-Default.desktop");
    Test({
         GList* l = get_deepin_categories(firefox);
         g_assert(g_list_length(l) == 1);
         g_clear_pointer(&l, g_list_free);

         l = get_deepin_categories(self);
         g_assert(g_list_length(l) >= 1);
         g_list_free(l);
         }, "get_deepin_categories");
    g_object_unref(firefox);
    g_object_unref(self);
}


void test__load_category_info()
{
    Test({
         GPtrArray* category_infos = g_ptr_array_new_with_free_func(g_free);
         _load_category_info(category_infos);
         g_ptr_array_unref(category_infos);
         }, "_load_category_info");
}


void launcher_category_test()
{
    /* test_find_category_id(); */
    /* test__remove_other_category(); */
    /* test__get_x_category(); */
    /* test_get_deepin_categories(); */
    /* test__load_category_info(); */
}

#endif

