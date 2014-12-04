// copied from nautilus

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <locale.h>
#include <libintl.h>

#include "nautilus_file_operations.h"
#include "eel.h"

/* Localizers:
 * Feel free to leave out the st, nd, rd and th suffix or
 * make some or all of them match.
 */

/* localizers: tag used to detect the first copy of a file */
const char *untranslated_copy_duplicate_tag = " (copy)";
/* localizers: tag used to detect the second copy of a file */
const char *untranslated_another_copy_duplicate_tag = " (another copy)";

/* localizers: tag used to detect the x11th copy of a file */
const char *untranslated_x11th_copy_duplicate_tag = "th copy)";
/* localizers: tag used to detect the x12th copy of a file */
const char *untranslated_x12th_copy_duplicate_tag = "th copy)";
/* localizers: tag used to detect the x13th copy of a file */
const char *untranslated_x13th_copy_duplicate_tag = "th copy)";

/* localizers: tag used to detect the x1st copy of a file */
const char *untranslated_st_copy_duplicate_tag = "st copy)";
/* localizers: tag used to detect the x2nd copy of a file */
const char *untranslated_nd_copy_duplicate_tag = "nd copy)";
/* localizers: tag used to detect the x3rd copy of a file */
const char *untranslated_rd_copy_duplicate_tag = "rd copy)";

/* localizers: tag used to detect the xxth copy of a file */
const char *untranslated_th_copy_duplicate_tag = "th copy)";

/* localizers: appended to first file copy */
const char *untranslated_first_copy_duplicate_format = "%s (copy)%s";
/* localizers: appended to second file copy */
const char *untranslated_second_copy_duplicate_format = "%s (another copy)%s";

/* localizers: appended to x11th file copy */
const char *untranslated_x11th_copy_duplicate_format = "%s (%'dth copy)%s";
/* localizers: appended to x12th file copy */
const char *untranslated_x12th_copy_duplicate_format = "%s (%'dth copy)%s";
/* localizers: appended to x13th file copy */
const char *untranslated_x13th_copy_duplicate_format = "%s (%'dth copy)%s";

/* localizers: if in your language there's no difference between 1st, 2nd, 3rd and nth
 * plurals, you can leave the st, nd, rd suffixes out and just make all the translated
 * strings look like "%s (copy %'d)%s".
 */

/* localizers: appended to x1st file copy */
const char *untranslated_st_copy_duplicate_format = "%s (%'dst copy)%s";
/* localizers: appended to x2nd file copy */
const char *untranslated_nd_copy_duplicate_format = "%s (%'dnd copy)%s";
/* localizers: appended to x3rd file copy */
const char *untranslated_rd_copy_duplicate_format = "%s (%'drd copy)%s";
/* localizers: appended to xxth file copy */
const char *untranslated_th_copy_duplicate_format = "%s (%'dth copy)%s";



static
char* extract_string_until (const char *original, const char *until_substring)
{
    char *result;

    g_assert ((int) strlen (original) >= until_substring - original);
    g_assert (until_substring - original >= 0);

    result = g_malloc (until_substring - original + 1);
    strncpy (result, original, until_substring - original);
    result[until_substring - original] = '\0';

    return result;
}


static void
parse_previous_duplicate_name (GFileType file_type,
                               const char *name,
                               char **name_base,
                               const char **suffix,
                               int *count)
{
    setlocale(LC_ALL, "");
    bindtextdomain(NAUTILUS_DOMAIN, "/usr/share/");
    const char *tag;

    g_assert (name[0] != '\0');

    if (file_type == G_FILE_TYPE_DIRECTORY) {
        *suffix = NULL;
    } else {
        *suffix = eel_filename_get_extension_offset (name);
    }

    if (*suffix == NULL || (*suffix)[1] == '\0') {
        /* no suffix */
        *suffix = "";
    }

    tag = strstr (name, COPY_DUPLICATE_TAG);
    if (tag != NULL) {
        if (tag > *suffix) {
            /* handle case "foo. (copy)" */
            *suffix = "";
        }
        *name_base = extract_string_until (name, tag);
        *count = 1;
        return;
    }


    tag = strstr (name, ANOTHER_COPY_DUPLICATE_TAG);
    if (tag != NULL) {
        if (tag > *suffix) {
            /* handle case "foo. (another copy)" */
            *suffix = "";
        }
        *name_base = extract_string_until (name, tag);
        *count = 2;
        return;
    }


    /* Check to see if we got one of st, nd, rd, th. */
    tag = strstr (name, X11TH_COPY_DUPLICATE_TAG);

    if (tag == NULL) {
        tag = strstr (name, X12TH_COPY_DUPLICATE_TAG);
    }
    if (tag == NULL) {
        tag = strstr (name, X13TH_COPY_DUPLICATE_TAG);
    }

    if (tag == NULL) {
        tag = strstr (name, ST_COPY_DUPLICATE_TAG);
    }
    if (tag == NULL) {
        tag = strstr (name, ND_COPY_DUPLICATE_TAG);
    }
    if (tag == NULL) {
        tag = strstr (name, RD_COPY_DUPLICATE_TAG);
    }
    if (tag == NULL) {
        tag = strstr (name, TH_COPY_DUPLICATE_TAG);
    }

    /* If we got one of st, nd, rd, th, fish out the duplicate number. */
    if (tag != NULL) {
        /* localizers: opening parentheses to match the "th copy)" string */
        tag = strstr (name, BIND_NAUTILUS(" ("));
        if (tag != NULL) {
            if (tag > *suffix) {
                /* handle case "foo. (22nd copy)" */
                *suffix = "";
            }
            *name_base = extract_string_until (name, tag);
            /* localizers: opening parentheses of the "th copy)" string */
            if (sscanf (tag, BIND_NAUTILUS(" (%'d"), count) == 1) {
                if (*count < 1 || *count > 1000000) {
                    /* keep the count within a reasonable range */
                    *count = 0;
                }
                return;
            }
            *count = 0;
            return;
        }
    }


    *count = 0;
    if (**suffix != '\0') {
        *name_base = extract_string_until (name, *suffix);
    } else {
        *name_base = g_strdup (name);
    }
}


static char *
shorten_utf8_string (const char *base, int reduce_by_num_bytes)
{
    int len;
    char *ret;
    const char *p;

    len = strlen (base);
    len -= reduce_by_num_bytes;

    if (len <= 0) {
        return NULL;
    }

    ret = g_new (char, len + 1);

    p = base;
    while (len) {
        char *next;
        next = g_utf8_next_char (p);
        if (next - p > len || *next == '\0') {
            break;
        }

        len -= next - p;
        p = next;
    }

    if (p - base == 0) {
        g_free (ret);
        return NULL;
    } else {
        memcpy (ret, base, p - base);
        ret[p - base] = '\0';
        return ret;
    }
}


static char *
make_next_duplicate_name (const char *base, const char *suffix, int count, int max_length)
{
    setlocale(LC_ALL, "");
    bindtextdomain(NAUTILUS_DOMAIN, "/usr/share/");
    const char *format;
    char *result;
    int unshortened_length;
    gboolean use_count;

    if (count < 1) {
        g_warning ("bad count %d in get_duplicate_name", count);
        count = 1;
    }

    if (count <= 2) {

        /* Handle special cases for low numbers.
         * Perhaps for some locales we will need to add more.
         */
        switch (count) {
        default:
            g_assert_not_reached ();
            /* fall through */
        case 1:
            format = FIRST_COPY_DUPLICATE_FORMAT;
            break;
        case 2:
            format = SECOND_COPY_DUPLICATE_FORMAT;
            break;

        }

        use_count = FALSE;
    } else {

        /* Handle special cases for the first few numbers of each ten.
         * For locales where getting this exactly right is difficult,
         * these can just be made all the same as the general case below.
         */

        /* Handle special cases for x11th - x20th.
        */
        switch (count % 100) {
        case 11:
            format = X11TH_COPY_DUPLICATE_FORMAT;
            break;
        case 12:
            format = X12TH_COPY_DUPLICATE_FORMAT;
            break;
        case 13:
            format = X13TH_COPY_DUPLICATE_FORMAT;
            break;
        default:
            format = NULL;
            break;
        }

        if (format == NULL) {
            switch (count % 10) {
            case 1:
                format = ST_COPY_DUPLICATE_FORMAT;
                break;
            case 2:
                format = ND_COPY_DUPLICATE_FORMAT;
                break;
            case 3:
                format = RD_COPY_DUPLICATE_FORMAT;
                break;
            default:
                /* The general case. */
                format = TH_COPY_DUPLICATE_FORMAT;
                break;
            }
        }

        use_count = TRUE;

    }

    if (use_count)
        result = g_strdup_printf (format, base, count, suffix);
    else
        result = g_strdup_printf (format, base, suffix);

    if (max_length > 0 && (unshortened_length = strlen (result)) > max_length) {
        char *new_base;

        new_base = shorten_utf8_string (base, unshortened_length - max_length);
        if (new_base) {
            g_free (result);

            if (use_count)
                result = g_strdup_printf (format, new_base, count, suffix);
            else
                result = g_strdup_printf (format, new_base, suffix);

            g_assert (strlen (result) <= (size_t)max_length);
            g_free (new_base);
        }
    }

    return result;
}


static char *
get_duplicate_name (GFileType file_type, const char *name, int count_increment, int max_length)
{
    char *result;
    char *name_base;
    const char *suffix;
    int count;

    parse_previous_duplicate_name (file_type, name, &name_base, &suffix, &count);
    result = make_next_duplicate_name (name_base, suffix, count + count_increment, max_length);

    g_free (name_base);

    return result;
}


#define FAT_FORBIDDEN_CHARACTERS "/:;*?\"<>"

static gboolean
str_replace (char *str,
             const char *chars_to_replace,
             char replacement)
{
    gboolean success;
    int i;

    success = FALSE;
    for (i = 0; str[i] != '\0'; i++) {
        if (strchr (chars_to_replace, str[i])) {
            success = TRUE;
            str[i] = replacement;
        }
    }

    return success;
}


static gboolean
make_file_name_valid_for_dest_fs (char *filename,
                                 const char *dest_fs_type)
{
    if (dest_fs_type != NULL && filename != NULL) {
        if (!strcmp (dest_fs_type, "fat")  ||
            !strcmp (dest_fs_type, "vfat") ||
            !strcmp (dest_fs_type, "msdos") ||
            !strcmp (dest_fs_type, "msdosfs")) {
            gboolean ret;
            size_t i, old_len;

            ret = str_replace (filename, FAT_FORBIDDEN_CHARACTERS, '_');

            old_len = strlen (filename);
            for (i = 0; i < old_len; i++) {
                if (filename[i] != ' ') {
                    g_strchomp (filename);
                    ret |= (old_len != strlen (filename));
                    break;
                }
            }

            return ret;
        }
    }

    return FALSE;
}


static int
get_max_name_length (GFile *file_dir)
{
    int max_length;
    char *dir;
    long max_path;
    long max_name;

    max_length = -1;

    if (!g_file_has_uri_scheme (file_dir, "file"))
        return max_length;

    dir = g_file_get_path (file_dir);
    if (!dir)
        return max_length;

    max_path = pathconf (dir, _PC_PATH_MAX);
    max_name = pathconf (dir, _PC_NAME_MAX);

    if (max_name == -1 && max_path == -1) {
        max_length = -1;
    } else if (max_name == -1 && max_path != -1) {
        max_length = max_path - (strlen (dir) + 1);
    } else if (max_name != -1 && max_path == -1) {
        max_length = max_name;
    } else {
        int leftover;

        leftover = max_path - (strlen (dir) + 1);

        max_length = MIN (leftover, max_name);
    }

    g_free (dir);

    return max_length;
}


GFile*
get_unique_target_file(GFileType file_type, GFile* src, GFile* dest_dir, const char* dest_fs_type, int count)
{
    const char *editname, *end;
    char *basename, *new_name;
    GFileInfo *info;
    GFile *dest;
    int max_length;

    max_length = get_max_name_length (dest_dir);

    dest = NULL;
    info = g_file_query_info (src,
                              G_FILE_ATTRIBUTE_STANDARD_EDIT_NAME,
                              0, NULL, NULL);
    if (info != NULL) {
        editname = g_file_info_get_attribute_string (info, G_FILE_ATTRIBUTE_STANDARD_EDIT_NAME);

        if (editname != NULL) {
            new_name = get_duplicate_name (file_type, editname, count, max_length);
            make_file_name_valid_for_dest_fs (new_name, dest_fs_type);
            dest = g_file_get_child_for_display_name (dest_dir, new_name, NULL);
            g_free (new_name);
        }

        g_object_unref (info);
    }

    if (dest == NULL) {
        basename = g_file_get_basename (src);

        if (g_utf8_validate (basename, -1, NULL)) {
            new_name = get_duplicate_name (file_type, basename, count, max_length);
            make_file_name_valid_for_dest_fs (new_name, dest_fs_type);
            dest = g_file_get_child_for_display_name (dest_dir, new_name, NULL);
            g_free (new_name);
        }

        if (dest == NULL) {
            end = strrchr (basename, '.');
            if (end != NULL) {
                count += atoi (end + 1);
            }
            new_name = g_strdup_printf ("%s.%d", basename, count);
            make_file_name_valid_for_dest_fs (new_name, dest_fs_type);
            dest = g_file_get_child (dest_dir, new_name);
            g_free (new_name);
        }

        g_free (basename);
    }

    return dest;
}


