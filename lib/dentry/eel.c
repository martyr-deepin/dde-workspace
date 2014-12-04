//eel stuff copied from nautilus

#include <string.h>
#include <glib.h>
#include "eel.h"

char *
eel_filename_get_extension_offset (const char *filename)
{
    char *end, *end2;

    end = strrchr (filename, '.');

    if (end && end != filename)
    {
	if (strcmp (end, ".gz") == 0 ||
	    strcmp (end, ".bz2") == 0 ||
	    strcmp (end, ".sit") == 0 ||
	    strcmp (end, ".Z") == 0)
	{
	    end2 = end - 1;
	    while (end2 > filename && *end2 != '.')
		end2--;

	    if (end2 != filename)
		end = end2;
	}
    }
    return end;
}

char *
eel_filename_strip_extension (const char * filename_with_extension)
{
    char *filename, *end;

    if (filename_with_extension == NULL)
	return NULL;

    filename = g_strdup (filename_with_extension);
    end = eel_filename_get_extension_offset (filename);

    if (end && end != filename)
	*end = '\0';

    return filename;
}

void
eel_filename_get_rename_region (const char *filename,
				int *start_offset,
				int *end_offset)
{
    char *filename_without_extension;

    g_return_if_fail (start_offset != NULL);
    g_return_if_fail (end_offset != NULL);

    *start_offset = 0;
    *end_offset = 0;

    g_return_if_fail (filename != NULL);

    filename_without_extension = eel_filename_strip_extension (filename);
    *end_offset = g_utf8_strlen (filename_without_extension, -1);

    g_free (filename_without_extension);
}


