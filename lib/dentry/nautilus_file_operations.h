#ifndef NAUTILUS_FILE_OPERATIONS_H_CLK7RFAU
#define NAUTILUS_FILE_OPERATIONS_H_CLK7RFAU

#include <glib.h>
#include <gio/gio.h>

/* Localizers:
 * Feel free to leave out the st, nd, rd and th suffix or
 * make some or all of them match.
 */

/* localizers: tag used to detect the first copy of a file */
extern const char *untranslated_copy_duplicate_tag;
/* localizers: tag used to detect the second copy of a file */
extern const char *untranslated_another_copy_duplicate_tag;

/* localizers: tag used to detect the x11th copy of a file */
extern const char *untranslated_x11th_copy_duplicate_tag;
/* localizers: tag used to detect the x12th copy of a file */
extern const char *untranslated_x12th_copy_duplicate_tag;
/* localizers: tag used to detect the x13th copy of a file */
extern const char *untranslated_x13th_copy_duplicate_tag;

/* localizers: tag used to detect the x1st copy of a file */
extern const char *untranslated_st_copy_duplicate_tag;
/* localizers: tag used to detect the x2nd copy of a file */
extern const char *untranslated_nd_copy_duplicate_tag;
/* localizers: tag used to detect the x3rd copy of a file */
extern const char *untranslated_rd_copy_duplicate_tag;

/* localizers: tag used to detect the xxth copy of a file */
extern const char *untranslated_th_copy_duplicate_tag;

#define NAUTILUS_DOMAIN "nautilus"

#define BIND_NAUTILUS(str) dgettext(NAUTILUS_DOMAIN, str)

#define COPY_DUPLICATE_TAG BIND_NAUTILUS(untranslated_copy_duplicate_tag)
#define ANOTHER_COPY_DUPLICATE_TAG BIND_NAUTILUS(untranslated_another_copy_duplicate_tag)
#define X11TH_COPY_DUPLICATE_TAG BIND_NAUTILUS(untranslated_x11th_copy_duplicate_tag)
#define X12TH_COPY_DUPLICATE_TAG BIND_NAUTILUS(untranslated_x12th_copy_duplicate_tag)
#define X13TH_COPY_DUPLICATE_TAG BIND_NAUTILUS(untranslated_x13th_copy_duplicate_tag)

#define ST_COPY_DUPLICATE_TAG BIND_NAUTILUS(untranslated_st_copy_duplicate_tag)
#define ND_COPY_DUPLICATE_TAG BIND_NAUTILUS(untranslated_nd_copy_duplicate_tag)
#define RD_COPY_DUPLICATE_TAG BIND_NAUTILUS(untranslated_rd_copy_duplicate_tag)
#define TH_COPY_DUPLICATE_TAG BIND_NAUTILUS(untranslated_th_copy_duplicate_tag)

/* localizers: appended to first file copy */
extern const char *untranslated_first_copy_duplicate_format;
/* localizers: appended to second file copy */
extern const char *untranslated_second_copy_duplicate_format;

/* localizers: appended to x11th file copy */
extern const char *untranslated_x11th_copy_duplicate_format;
/* localizers: appended to x12th file copy */
extern const char *untranslated_x12th_copy_duplicate_format;
/* localizers: appended to x13th file copy */
extern const char *untranslated_x13th_copy_duplicate_format;

/* localizers: if in your language there's no difference between 1st, 2nd, 3rd and nth
 * plurals, you can leave the st, nd, rd suffixes out and just make all the translated
 * strings look like "%s (copy %'d)%s".
 */

/* localizers: appended to x1st file copy */
extern const char *untranslated_st_copy_duplicate_format;
/* localizers: appended to x2nd file copy */
extern const char *untranslated_nd_copy_duplicate_format;
/* localizers: appended to x3rd file copy */
extern const char *untranslated_rd_copy_duplicate_format;
/* localizers: appended to xxth file copy */
extern const char *untranslated_th_copy_duplicate_format;

#define FIRST_COPY_DUPLICATE_FORMAT BIND_NAUTILUS(untranslated_first_copy_duplicate_format)
#define SECOND_COPY_DUPLICATE_FORMAT BIND_NAUTILUS(untranslated_second_copy_duplicate_format)
#define X11TH_COPY_DUPLICATE_FORMAT BIND_NAUTILUS(untranslated_x11th_copy_duplicate_format)
#define X12TH_COPY_DUPLICATE_FORMAT BIND_NAUTILUS(untranslated_x12th_copy_duplicate_format)
#define X13TH_COPY_DUPLICATE_FORMAT BIND_NAUTILUS(untranslated_x13th_copy_duplicate_format)

#define ST_COPY_DUPLICATE_FORMAT BIND_NAUTILUS(untranslated_st_copy_duplicate_format)
#define ND_COPY_DUPLICATE_FORMAT BIND_NAUTILUS(untranslated_nd_copy_duplicate_format)
#define RD_COPY_DUPLICATE_FORMAT BIND_NAUTILUS(untranslated_rd_copy_duplicate_format)
#define TH_COPY_DUPLICATE_FORMAT BIND_NAUTILUS(untranslated_th_copy_duplicate_format)

GFile* get_unique_target_file(GFileType file_type, GFile* src, GFile* dest_dir, const char* dest_fs_type, int count);

#endif /* end of include guard: NAUTILUS_FILE_OPERATIONS_H_CLK7RFAU */

