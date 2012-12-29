#ifndef __DENTRY_H__

#include <glib.h>
#include <gio/gio.h>
#include <jsextension.h>
typedef void Entry;
#define DEEPIN_RICH_DIR ".deepin_rich_dir_"
#define DEEPIN_RICH_DIR_LEN 17
gboolean dentry_launch(Entry* e, const ArrayContainer fs);
Entry* dentry_create_by_path(const char* path);
gboolean dentry_set_name(Entry* e, const char* name);
char* dentry_get_id(Entry* e);
ArrayContainer dentry_list_files(GFile* f);
char* dentry_get_icon(Entry* e);
void dentry_move(ArrayContainer fs, GFile* dest);
#endif
