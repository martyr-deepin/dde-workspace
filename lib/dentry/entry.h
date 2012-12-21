#ifndef __DENTRY_H__
typedef void Entry;
#define DEEPIN_RICH_DIR ".deepin_rich_dir_"
#define DEEPIN_RICH_DIR_LEN 17
Entry* dentry_create_by_path(const char* path);
#endif
