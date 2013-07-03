#ifndef _X_CATEGORY_H_
#define _X_CATEGORY_H_

#define X_CATEGORY_NUM 194

typedef struct _XCategory XCategory;
struct _XCategory {
    char* name;
    int index;
};

extern XCategory x_category_name_index_map[X_CATEGORY_NUM];

#endif  // end of guard: _X_CATEGORY_H_
