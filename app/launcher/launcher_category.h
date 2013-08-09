#ifndef LAUNCHER_CATEGORY_H
#define LAUNCHER_CATEGORY_H

int find_category_id(const char* category_name);
GList* get_deepin_categories(GDesktopAppInfo* info);
const GPtrArray* get_all_categories_array();

#endif /* end of include guard: LAUNCHER_CATEGORY_H */

