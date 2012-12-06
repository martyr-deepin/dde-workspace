#include "set.h"

Set* set_str_build(char** a)
{
    int len = 0;
    if (a == NULL || 0 == (len = g_strv_length(a))) {
        return NULL;
    }

    Set* s = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, NULL);
    for (int i=0; i<len; i++) {
        char* e = a[i];
        g_hash_table_insert(s, g_strdup(e), NULL);
    }
    return s;
}

Set* set_substract(Set* a, Set* b)
{
    GList* keys = g_hash_table_get_keys(a);
    if (keys == NULL)
        return NULL;
    Set* r = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, NULL);

    GList* k = keys;
    do {
        if (!g_hash_table_contains(b, k->data)) {
            g_hash_table_insert(r, g_strdup(k->data), NULL);
        }
    } while (NULL != (k = g_list_next(k)));
    g_list_free(keys);
    return r;
}
