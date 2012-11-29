void item_rename(const char* old, const char* new)
{
    run_command2("mv", old, new);
}

void item_delete(const char* target)
{
    run_command2("mv", target);
}
