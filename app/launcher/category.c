#include "category.h"
#include <stdlib.h>

const char* cs[] = {
    "Games", 
    "Application",
    "Utility",
    "System",
    "Settings",
    "Office",
    "Network",
    "Development",
};

#define ARRAY_LEN(a) (sizeof(a)/sizeof(a[0]))

const char** get_category_list()
{
    return cs;
}

int get_own_category(const char* path)
{
    return rand() % ARRAY_LEN(cs);
}
