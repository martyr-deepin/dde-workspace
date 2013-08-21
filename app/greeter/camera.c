#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <signal.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <glib.h>
#include <gio/gio.h>
#include <opencv/cv.h>
#include <cairo.h>
#include <gst/gst.h>

#include "dwebview.h"
#include "jsextension.h"
#include "camera.h"


#define CASCADE_NAME DATA_DIR"/haaracscades/haarcascade_frontalface_alt.xml"
#define ESC_KEY 27
#define DELAY_TIME 3.0
#define CAMERA_WIDTH 640
#define CAMERA_HEIGHT 480
#define STR_CAMERA_WIDTH "640"
#define STR_CAMERA_HEIGHT "480"


enum {
    NOT_START_RECOGNIZE,
    START_RECOGNIZE,
    RECOGNIZED
};


static IplImage* small_img = NULL;
static IplImage* gray = NULL;

static IplImage* frame = NULL;
static CvHaarClassifierCascade* cascade = NULL;
static CvMemStorage* storage = NULL;
static cairo_t* cr = NULL;

static GstElement *pipeline = NULL;
static GstElement *img_sink = NULL;

static int flag = 0;
static time_t start;
static time_t output = 0;
static double diff_time = 0;
static double scale = 1.3;


static void do_quit();
static void handler(int signum);
void draw_to_canvas(GdkPixbuf* pixbuf);//, cairo_t* cr);
static char* reco();
static gboolean _frame_handler(GstElement *img, GstBuffer *buffer, gpointer data);


void init_camera(int argc, char* argv[])
{
    gst_init (&argc, &argv);

    const gchar camera_launch[] = "v4l2src ! video/x-raw-rgb,"
        "width="STR_CAMERA_WIDTH",height="STR_CAMERA_HEIGHT
        " ! ffmpegcolorspace ! fakesink name=\"imgSink\"";

    g_warning("%s", camera_launch);

    pipeline = gst_parse_launch(camera_launch, NULL);
    g_warning("%d", pipeline == NULL);
    img_sink = gst_bin_get_by_name(GST_BIN(pipeline), "imgSink");

    g_object_set(G_OBJECT(img_sink), "signal-handoffs", TRUE, NULL);
    gst_element_set_state(pipeline, GST_STATE_PLAYING);
}


void destroy_camera()
{
    gst_element_set_state(pipeline, GST_STATE_NULL);
    gst_object_unref(img_sink);
    gst_object_unref(GST_OBJECT(pipeline));
}


gboolean has_camera()
{
    // FIXME: not suit for multi cameras.
    int fd = open("/dev/video0", O_RDONLY);
    if (fd == -1)
        return FALSE;

    close(fd);
    return TRUE;
}


void do_quit()
{
    if (frame)
        cvReleaseImageHeader(&frame);

    if (small_img)
        cvReleaseImage(&small_img);

    if (gray)
        cvReleaseImage(&gray);
}


char* reco()
{
    int exit_code = 1;

    // DATA_DIR defined in CMakeLists.txt
    char* args[] = {"/usr/bin/python", DATA_DIR"/../app/greeter/reco", NULL};
    GError* err = NULL;
    char* username = NULL;
    g_spawn_sync(NULL, args, NULL, 0, NULL, NULL, &username, NULL, &exit_code,
                 &err);
    if (err != NULL) {
        g_warning("[reco] %s", err->message);
        g_error_free(err);
    }

    if (g_strcmp0(username, g_get_user_name()) == 0)
        return username;

    g_free(username);
    return NULL;
}


static
gboolean _frame_handler(GstElement *img, GstBuffer *buffer, gpointer data)
{
    g_warning("_frame_handler");
    if (frame == NULL)
        frame = cvCreateImageHeader(cvSize(640, 480), IPL_DEPTH_8U, 3);

    frame->imageData = (char*)GST_BUFFER_DATA(buffer);
    /* detect(frame); */
    guchar* source_data = NULL;
    if (0)
        source_data = frame->imageData;
    else
        source_data = (guchar*)GST_BUFFER_DATA(buffer);
    GError* error = NULL;
    GdkPixbuf* pixbuf = gdk_pixbuf_new_from_file("/usr/share/icons/Deepin/apps/48/google-chrome.png", &error);
    /* GdkPixbuf* pixbuf = gdk_pixbuf_new_from_data(g_strdup(source_data), */
    /*                                              GDK_COLORSPACE_RGB,  // color space */
    /*                                              FALSE,  // has alpha */
    /*                                              8,  // bits per sample */
    /*                                              CAMERA_WIDTH,  // width */
    /*                                              CAMERA_HEIGHT,  // height */
    /*                                              3*CAMERA_WIDTH,  // row stride */
    /*                                              (GdkPixbufDestroyNotify)g_free,  // destroy function */
    /*                                              NULL  // destroy function data */
    /*                                              ); */
    /* static int i = 0; */
    /* char name[1024] = {0}; */
    /* sprintf(name, "/tmp/test%d.png", i++); */
    /* gdk_pixbuf_save(pixbuf, name, "png", NULL, NULL); */
    /* g_free(name); */
    if (error != NULL) {
        g_warning("%s", error->message);
        g_error_free(error);
        return FALSE;
    }
    draw_to_canvas(pixbuf);
    g_object_unref(pixbuf);

    return TRUE;
}


void draw_to_canvas(GdkPixbuf* pixbuf)
{
    g_warning("draw_to_canvas");
    cairo_save(cr);

    gdk_cairo_set_source_pixbuf(cr, pixbuf, 0, 0);

    cairo_paint(cr);
    cairo_restore(cr);

    canvas_custom_draw_did(cr, NULL);
}


gboolean detect(IplImage* frame)
{
    gboolean has_face = FALSE;
    gray = cvCreateImage(cvSize(frame->width, frame->height), 8, 1);
    small_img = cvCreateImage(cvSize(cvRound(frame->width/scale),
                                     cvRound(frame->height/scale)),
                              8, 1);
    cvCvtColor(frame, gray, CV_BGR2GRAY);
    cvResize(gray, small_img, CV_INTER_LINEAR);
    cvEqualizeHist(small_img, small_img);

    cvClearMemStorage(storage);
    CvSeq* objects = NULL;
    objects = cvHaarDetectObjects(small_img, cascade, storage, scale,
                                  3, 0
                                  | CV_HAAR_FIND_BIGGEST_OBJECT
                                  , cvSize(0, 0), cvSize(0, 0));

    if (objects && objects->total > 0) {
        has_face = TRUE;

        /* if (flag == START_RECOGNIZE) */
        /*     cvSaveImage("/tmp/deepin_user_face.png", frame, NULL); */

        for (int i = 0; i < objects->total; ++i) {
            CvRect* r = (CvRect*)cvGetSeqElem(objects, i);
            cvRectangle(frame, cvPoint(r->x * scale, r->y * scale),
                        cvPoint((r->x + r->width) * scale, (r->y + r->height) * scale),
                        cvScalar(0xff, 0xff, 0, 0), 4, 8, 0);
        }
    }

    cvReleaseImage(&gray);
    cvReleaseImage(&small_img);

    return has_face;
}


void _draw(JSValueRef canvas, JSData* data)
{
    g_warning("_draw");
    if (JSValueIsNull(data->ctx, canvas)) {
        g_warning("draw with null canvas!");
        return;
    }

    g_warning("get cairo from canvas");
    cairo_destroy(cr);
    cr = fetch_cairo_from_html_canvas(data->ctx, canvas);

    g_warning("set signal connection");
    g_warning("img_sink: %p", img_sink);

    g_warning("set pipeline to playing");
    g_signal_connect(G_OBJECT(img_sink), "handoff",
                     G_CALLBACK(_frame_handler), NULL);
}


JS_EXPORT_API
void greeter_draw_camera(JSValueRef canvas, JSData* data)
{
    _draw(canvas, data);
}


JS_EXPORT_API
void lock_draw_camera(JSValueRef canvas, JSData* data)
{
    g_warning("lock_draw_camera");
    _draw(canvas, data);
}
