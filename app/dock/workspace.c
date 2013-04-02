#include <glib.h>
#include "workspace.h"

Workspace curr_space = {0, 0};

gboolean is_same_workspace(Workspace* lhs, Workspace* rhs)
{
    return lhs->x == rhs->x && lhs->y == rhs->y;
}
