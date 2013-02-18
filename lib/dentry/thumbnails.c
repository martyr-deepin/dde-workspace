#include <gtk/gtk.h>

#define GNOME_DESKTOP_USE_UNSTABLE_API
#include <libgnome-desktop/gnome-desktop-thumbnail.h>

static GnomeDesktopThumbnailFactory *
get_thumbnail_factory (void)
{
    static GnomeDesktopThumbnailFactory *thumbnail_factory = NULL;

    if (thumbnail_factory == NULL) {
        thumbnail_factory = gnome_desktop_thumbnail_factory_new (GNOME_DESKTOP_THUMBNAIL_SIZE_NORMAL);
    }

    return thumbnail_factory;
}
/*
 *      check whether thumbnails can be generated for @file
 */
static gboolean
gfile_can_thumbnail (GFile *file)
{
    GnomeDesktopThumbnailFactory *factory;
    gboolean res;
    char *uri;
    GFileInfo* info;
    time_t mtime;
    const char* content_type;
    char* mime_type;
		
    uri = g_file_get_uri (file);

    info = g_file_query_info (file, "standard::content-type,time::modified",
                              G_FILE_QUERY_INFO_NOFOLLOW_SYMLINKS,
                              NULL, NULL);
    content_type = g_file_info_get_content_type (info);
    mime_type = g_content_type_get_mime_type (content_type);

    mtime = g_file_info_get_attribute_uint64(info, "time::modified");
    g_object_unref (info);
	
    factory = get_thumbnail_factory ();
    res = gnome_desktop_thumbnail_factory_can_thumbnail (factory,
                                                         uri,
                                                         mime_type,
                                                         mtime);
    g_debug ("%s can thumbnail(mime: %s): %d", uri, mime_type,res);
    g_free (uri);
    g_free (mime_type);

    return res;
}

/*
 *      create thumbnail
 *      return : success: the created thumbnail 
 *               failure: NULL
 */
static char* 
gfile_create_thumbnail (GFile* file)
{
    char* thumbnail_path = NULL;

    return thumbnail_path;
}

/*
 *      syncronously create thumbnails. shall we move to a threaded 
 *      implementation?
 */
char*
gfile_lookup_thumbnail (GFile* file)
{
    if (gfile_can_thumbnail (file) == FALSE)
        return NULL;
    /* 
     * gnome_desktop_thumbnail_path_for_uri (uri, GNOME_DESKTOP_THUMBNAIL_SIZE_NORMAL);
     * gnome_desktop_thumbnail_factory_lookup (thumbnail_factory, uri, mtime);
     */
     GnomeDesktopThumbnailFactory *factory;
     char *uri;
     GFileInfo* info;
     time_t mtime;

     char* thumbnail_path = NULL;
		
     uri = g_file_get_uri (file);

     info = g_file_query_info (file, "time::modified",
                               G_FILE_QUERY_INFO_NOFOLLOW_SYMLINKS,
                               NULL, NULL);
     mtime = g_file_info_get_attribute_uint64(info, "time::modified");
     g_object_unref (info);

     factory = get_thumbnail_factory ();

     thumbnail_path = gnome_desktop_thumbnail_factory_lookup (factory, uri, mtime);
     g_debug ("uri: %s\nthumbnail_path: %s\n", uri, thumbnail_path);

     if (thumbnail_path == NULL)
     {
         thumbnail_path = gfile_create_thumbnail (file);
     }

     return thumbnail_path;
}

