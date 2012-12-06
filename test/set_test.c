#include "set.h"

#include <stdio.h>
int main()
{
    char* a[] = {"a", "b", "d", "e", NULL};
    char* b[] = {"a", "d", "b", "c", NULL};
    Set* sa = set_str_build(a);
    Set* sb = set_str_build(b);
    Set* r = set_substract(sb, sa);
    GList* keys = g_hash_table_get_keys(r);
    GList* k = keys;
    do {
        printf("%s\n", (char*)k->data);
    } while (NULL != (k=g_list_next(k)));

    g_list_free(keys);
    return 0;
}
