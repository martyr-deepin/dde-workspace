/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2013 ~ 2013 Liqiang Lee
 *
 * Author:      Liqiang Lee <liliqiang@linuxdeepin.com>
 * Maintainer:  Liqiang Lee <liliqiang@linuxdeepin.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses/>.
 **/

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
#include "i18n.h"
#include "utils.h"


#define CASCADE_NAME DATA_DIR"/haaracscades/haarcascade_frontalface_alt.xml"
#define CAMERA_WIDTH 640
#define CAMERA_HEIGHT 480
#define MAX_RECO_TIME 5
#define ERR_POST_PREFIX _("Oops...I can't recognize your face. ")
#define ANIMATION_TIME (2 * G_TIME_SPAN_MILLISECOND)


struct RecognitionInfo recognition_info = {
    TRUE, FALSE, NOT_START_RECOGNIZING, 0, 3.0, NULL, 0, 0, NULL, NULL
};

// global {{{
static IplImage* frame = NULL;
static CvHaarClassifierCascade* cascade = NULL;
static CvMemStorage* storage = NULL;

static GstElement *pipeline = NULL;
static GstElement *img_sink = NULL;

static GstBuffer* copy_buffer = NULL;
static GstBuffer* pure_buffer = NULL;
// }}}


// forward decleration {{{
static void do_quit();
static void reco();
static void detect(IplImage* frame);
static gboolean _frame_handler(GstElement *img, GstBuffer *buffer, gpointer data);
// }}}


void init_camera(int argc, char* argv[])
{
    gst_init (&argc, &argv);
    recognition_info.timer = g_timer_new();
}


void connect_camera()
{
    const gchar camera_launch[] = "v4l2src ! video/x-raw-rgb,"
        "width="G_STRINGIFY(CAMERA_WIDTH)",height="G_STRINGIFY(CAMERA_HEIGHT)
        " ! ffmpegcolorspace ! videoflip method=horizontal-flip !"
        " fakesink name=\"imgSink\"";

    pipeline = gst_parse_launch(camera_launch, NULL);
    img_sink = gst_bin_get_by_name(GST_BIN(pipeline), "imgSink");

    g_object_set(G_OBJECT(img_sink), "signal-handoffs", TRUE, NULL);
    gst_element_set_state(pipeline, GST_STATE_PLAYING);
    g_signal_connect(G_OBJECT(img_sink), "handoff",
                     G_CALLBACK(_frame_handler), NULL);
}


void destroy_camera()
{
    if (pipeline != NULL) {
        gst_element_set_state(pipeline, GST_STATE_NULL);
        gst_object_unref(img_sink);
        img_sink = NULL;
        gst_object_unref(GST_OBJECT(pipeline));
        pipeline = NULL;

        do_quit();
    }

    if (recognition_info.timer != NULL) {
        g_timer_stop(recognition_info.timer);
        g_timer_destroy(recognition_info.timer);
    }
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
    if (copy_buffer) {
        gst_buffer_unref(copy_buffer);
        copy_buffer = NULL;
    }

    if (pure_buffer) {
        gst_buffer_unref(pure_buffer);
        pure_buffer = NULL;
    }

    if (frame) {
        cvReleaseImageHeader(&frame);
        frame = NULL;
    }
}




void reco()
{
    // RESOURCE_DIR defined in CMakeLists.txt
    char* args[] = {"/usr/bin/python", RESOURCE_DIR"/greeter/scripts/reco", recognition_info.current_username, NULL};
    GError* err = NULL;
    char* is_same_person = NULL;
    g_spawn_sync(NULL, args, NULL, 0, NULL, NULL, &is_same_person, NULL, NULL, &err);

    if (err != NULL) {
        g_warning("[%s] %s", __func__, err->message);
        g_error_free(err);
    }

    g_debug("[%s] #%s#", __func__, is_same_person);
    if (g_strcmp0(is_same_person, "True") == 0) {
        recognition_info.reco_state = RECOGNIZED;
        g_free(is_same_person);
    } else {
        g_debug("[%s] not recognized", __func__);
        recognition_info.reco_times += 1;

        if (recognition_info.reco_times == MAX_RECO_TIME) {
            g_debug("[%s] reach the max recognition time", __func__);
            JSObjectRef json = json_create();
            char* msg = g_strdup_printf("%s%s", ERR_POST_PREFIX,
                                        _("Please login with your password or click your picture to retry."));
            json_append_string(json, "error", msg);
            g_free(msg);
            js_post_message("failed-too-much", json);

            recognition_info.detect_is_enabled = FALSE;
            recognition_info.reco_state = RECOGNIZE_FINISH;
            g_free(is_same_person);
            return;
        }

        recognition_info.reco_state = NOT_RECOGNIZED;
    }
}


G_GNUC_UNUSED
static void bus_callback(GstBus* bus G_GNUC_UNUSED, GstMessage* msg, gpointer data)
{
    gchar* msg_str;
    GError *error;

    /* Report errors to the console */
    switch (GST_MESSAGE_TYPE(msg)) {
    case GST_MESSAGE_EOS:
        if (data != NULL)
            gst_object_unref(data);
        data = NULL;
        break;
    case GST_MESSAGE_ERROR:
        gst_message_parse_error(msg, &error, &msg_str);
        g_error("GST error: %s\n", msg_str);
        g_free(error);
        g_free(msg_str);
        break;
    default:
        break;
    }
}


static
gboolean recognized_handler(gpointer data G_GNUC_UNUSED)
{
    g_debug("[%s] recognized", __func__);
    js_post_signal("start-login");
    recognition_info.reco_state = RECOGNIZE_FINISH;
    return G_SOURCE_REMOVE;
}


static
gboolean not_recognize_handler(gpointer data G_GNUC_UNUSED)
{
    g_debug("[%s] not recognized", __func__);
    g_debug("[%s] send auth-failed signal", __func__);
    JSObjectRef json = json_create();
    recognition_info.DELAY_TIME = 4.0;
    char* msg = g_strdup_printf(_("%sRetry automatically in %ds"),
                                ERR_POST_PREFIX,
                                (int)recognition_info.DELAY_TIME);
    json_append_string(json, "error", msg);
    g_free(msg);
    js_post_message("auth-failed", json);
    g_timer_start(recognition_info.timer);
    recognition_info.reco_state = NOT_START_RECOGNIZING;

    return G_SOURCE_REMOVE;
}


static gboolean _frame_handler(GstElement *img G_GNUC_UNUSED, GstBuffer *buffer, gpointer data G_GNUC_UNUSED)
{
    static gboolean inited = FALSE;
    static gboolean sended = FALSE;

    if (!inited) {
        g_timer_start(recognition_info.timer);
        inited = TRUE;
    }

    if (frame == NULL)
        frame = cvCreateImageHeader(cvSize(640, 480), IPL_DEPTH_8U, 3);

    switch (recognition_info.reco_state) {
    case NOT_START_RECOGNIZING:
        g_debug("[%s] not start recognizing", __func__);
        if (copy_buffer != NULL)
            gst_buffer_unref(copy_buffer);

        if (pure_buffer != NULL)
            gst_buffer_unref(pure_buffer);

        copy_buffer = gst_buffer_copy((buffer));
        pure_buffer = gst_buffer_copy((buffer));

        frame->imageData = (char*)GST_BUFFER_DATA(copy_buffer);
        if (recognition_info.detect_is_enabled) {
            detect(frame);
        } else {
            g_timer_start(recognition_info.timer);
        }
        recognition_info.source_data = (guchar*)(frame->imageData);
        recognition_info.length = GST_BUFFER_SIZE(copy_buffer);
        recognition_info.has_data = TRUE;
        break;
    case START_RECOGNIZING:
        g_debug("[%s] start recognizing", __func__);
        recognition_info.source_data = (guchar*)GST_BUFFER_DATA(pure_buffer);
        recognition_info.length = GST_BUFFER_SIZE(pure_buffer);
        GdkPixbuf* pixbuf = gdk_pixbuf_new_from_data(recognition_info.source_data,
                                                     GDK_COLORSPACE_RGB,  // color space
                                                     FALSE,  // has alpha
                                                     8,  // bits per sample
                                                     CAMERA_WIDTH,  // width
                                                     CAMERA_HEIGHT,  // height
                                                     3*CAMERA_WIDTH,  // row stride
                                                     NULL,  // destroy function
                                                     NULL  // destroy function data
                                                    );
        GError* error = NULL;
        gdk_pixbuf_save(pixbuf, "/tmp/deepin_user_face.png", "png", &error, NULL);
        if (error != NULL) {
            g_debug("[%s] %s", __func__, error->message);
            g_error_free(error);
        }

        g_object_unref(pixbuf);
        recognition_info.has_data = TRUE;

        js_post_signal("start-animation");
        recognition_info.reco_state = RECOGNIZING;
        sended = FALSE;
        reco();
        break;
    case RECOGNIZED:
        g_debug("[%s] recognized", __func__);
        if (!sended) {
            g_timeout_add(ANIMATION_TIME, recognized_handler, NULL);
            sended = TRUE;
        }
        break;
    case NOT_RECOGNIZED:
        g_debug("[%s] not recognized", __func__);
        if (!sended) {
            g_timeout_add(ANIMATION_TIME, not_recognize_handler, NULL);
            sended = TRUE;
        }
        break;
    case RECOGNIZE_FINISH:
        g_debug("[%s] recognizing finish", __func__);
        if (copy_buffer != NULL)
            gst_buffer_unref(copy_buffer);
        copy_buffer = gst_buffer_copy((buffer));
        recognition_info.source_data = (guchar*)GST_BUFFER_DATA(copy_buffer);
        recognition_info.length = GST_BUFFER_SIZE(pure_buffer);
        recognition_info.has_data = TRUE;
    case RECOGNIZING:
        ;
    }

    return TRUE;
}


static void detect(IplImage* frame)
{
    double const scale = 1.3;

    IplImage* gray = cvCreateImage(cvSize(frame->width, frame->height), 8, 1);
    IplImage* small_img = cvCreateImage(cvSize(cvRound(frame->width/scale),
                                               cvRound(frame->height/scale)),
                                        8, 1);
    cvCvtColor(frame, gray, CV_RGB2GRAY);
    cvResize(gray, small_img, CV_INTER_LINEAR);
    cvEqualizeHist(small_img, small_img);

    if (storage == NULL)
        storage = cvCreateMemStorage(0);

    if (cascade == NULL)
        cascade = (CvHaarClassifierCascade*)cvLoad(CASCADE_NAME, 0, 0, 0);

    cvClearMemStorage(storage);
    CvSeq* objects = NULL;
    objects = cvHaarDetectObjects(small_img, cascade, storage, scale,
                                  3, 0
                                  | CV_HAAR_FIND_BIGGEST_OBJECT
                                  , cvSize(0, 0), cvSize(0, 0));

    if (objects && objects->total > 0) {
        g_timer_stop(recognition_info.timer);
        double diff_time = g_timer_elapsed(recognition_info.timer, NULL);
        if (diff_time < recognition_info.DELAY_TIME)
            goto out;

        for (int i = 0; i < objects->total; ++i) {
            CvRect* r = (CvRect*)cvGetSeqElem(objects, i);
            cvRectangle(frame, cvPoint(r->x * scale, r->y * scale),
                        cvPoint((r->x + r->width) * scale, (r->y + r->height) * scale),
                        cvScalar(0, 0xff, 0xff, 0), 4, 8, 0);
        }

        recognition_info.reco_state = START_RECOGNIZING;
    } else {
        g_timer_start(recognition_info.timer);
    }

out:
    cvReleaseImage(&gray);
    cvReleaseImage(&small_img);
}


void destroy_pixels(guchar* pixels, gpointer user_data)
{
    g_slice_free1(GPOINTER_TO_INT(user_data), pixels);
}

void _draw(JSValueRef canvas, double dest_width, double dest_height)
{
    static gboolean not_draw G_GNUC_UNUSED = FALSE;

    if (recognition_info.reco_state == RECOGNIZING) {
        /* g_debug("[%s] recognizing", __func__); */
        return;
    }

    if (!recognition_info.has_data) {
        g_debug("[%s] get no data from camera", __func__);
        return;
    }

    if (JSValueIsNull(get_global_context(), canvas)) {
        g_debug("[%s] draw with null canvas!", __func__);
        return;
    }

    if (recognition_info.source_data == NULL) {
        g_debug("[%s] source_data is null", __func__);
        return;
    }

    g_debug("[%s]", __func__);

    cairo_t* cr = fetch_cairo_from_html_canvas(get_global_context(), canvas);
    g_assert(cr != NULL);
    cairo_save(cr);

    gulong len = recognition_info.length;
    guchar* data = g_slice_copy(len, recognition_info.source_data);
    GdkPixbuf* pixbuf = gdk_pixbuf_new_from_data(data,
                                                 GDK_COLORSPACE_RGB,  // color space
                                                 FALSE,  // has alpha
                                                 8,  // bits per sample
                                                 CAMERA_WIDTH,  // width
                                                 CAMERA_HEIGHT,  // height
                                                 3*CAMERA_WIDTH,  // row stride
                                                 destroy_pixels,  // destroy function
                                                 GINT_TO_POINTER(len)  // destroy function data
                                                );

    double scale = 0;
    if (CAMERA_WIDTH > CAMERA_HEIGHT) {
        scale = dest_height/CAMERA_HEIGHT;
        cairo_scale(cr, scale, scale);
        gdk_cairo_set_source_pixbuf(cr, pixbuf, 0.5 * (dest_width / scale -
                                                       CAMERA_WIDTH), 0);
    } else {
        scale = dest_width/CAMERA_WIDTH;
        cairo_scale(cr, scale, scale);
        gdk_cairo_set_source_pixbuf(cr, pixbuf, 0, 0.5 * (dest_height / scale -
                                                          CAMERA_HEIGHT));
    }

    cairo_paint(cr);
    cairo_restore(cr);

    canvas_custom_draw_did(cr, NULL);
    g_object_unref(pixbuf);

    recognition_info.has_data = FALSE;
}


JS_EXPORT_API
void greeter_draw_camera(JSValueRef canvas, double dest_width, double dest_height)
{
    _draw(canvas, dest_width, dest_height);
}


JS_EXPORT_API
void lock_draw_camera(JSValueRef canvas, double dest_width, double dest_height)
{
    _draw(canvas, dest_width, dest_height);
}


static
void _enable_detection(gboolean enabled)
{
    recognition_info.detect_is_enabled = enabled;
}


JS_EXPORT_API
void greeter_enable_detection(gboolean enabled)
{
    _enable_detection(enabled);
}


JS_EXPORT_API
void lock_enable_detection(gboolean enabled)
{
    _enable_detection(enabled);
}


static
void _start_recognize()
{
    if (recognition_info.reco_times == MAX_RECO_TIME)
        recognition_info.reco_times = 0;

    recognition_info.reco_state = NOT_START_RECOGNIZING;
    g_timer_start(recognition_info.timer);
}


JS_EXPORT_API
void lock_start_recognize()
{
    _start_recognize();
}


JS_EXPORT_API
void greeter_start_recognize()
{
    _start_recognize();
}


static
void _set_username(char const* username)
{
    g_free(recognition_info.current_username);
    recognition_info.current_username = g_strdup(username);
}


JS_EXPORT_API
void lock_set_username(char const* username)
{
    _set_username(username);
}


JS_EXPORT_API
void greeter_set_username(char const* username)
{
    _set_username(username);
}


static
void _cancel_detect()
{
    g_warning("cancel");
    _enable_detection(false);
    /* int kill(pid_t, int); */
    /* kill(recognition_info.pid, SIGKILL); */
    /* g_spawn_close_pid(recognition_info.pid); */
    recognition_info.reco_state = NOT_START_RECOGNIZING;
    if (recognition_info.timer != NULL)
        g_timer_start(recognition_info.timer);
    g_warning("cancel end");
}


JS_EXPORT_API
void lock_cancel_detect()
{
    _cancel_detect();
}

JS_EXPORT_API
void greeter_cancel_detect()
{
    _cancel_detect();
}

