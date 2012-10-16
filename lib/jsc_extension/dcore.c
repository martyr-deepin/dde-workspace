#include <glib.h>

char* gen_id(const char* seed)
{
    return g_compute_checksum_for_string(G_CHECKSUM_MD5, seed, strlen(seed));
}

void run_command(const char* cmd)
{
    /*g_printf("run cmd: %s\n", cmd);*/
    g_spawn_command_line_async(cmd, NULL);
}
