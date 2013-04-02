#ifndef _WORKSPACE_H_
#define _WORKSPACE_H_

typedef struct {
    int x, y;
} Workspace;


#define IS_MOUSE_IN_DOCK mouse_pointer_leave
#define MAX_CROSS_WORKSPACE_NUM 4

extern Workspace curr_space;

gboolean is_same_workspace(Workspace*, Workspace*);

#endif
