#ifndef _SET_H__
#define _SET_H__

#include <glib.h>
typedef GHashTable Set;

Set* set_str_build(char**);
#define set_free(s) g_hash_table_destroy(s)

Set* set_substract(Set* o, Set* s);


#endif
