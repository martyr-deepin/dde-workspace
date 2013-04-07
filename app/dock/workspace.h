#ifndef _WORKSPACE_H_
#define _WORKSPACE_H_

typedef struct {
    int x, y;
} Workspace;


#define MAX_CROSS_WORKSPACE_NUM 4

extern Workspace curr_space;

gboolean is_same_workspace(Workspace*, Workspace*);

#endif
