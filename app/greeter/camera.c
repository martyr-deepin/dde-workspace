#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <signal.h>
#include <unistd.h>

#include <glib.h>
#include <gio/gio.h>
#include "opencv/cv.h"
#include "opencv/highgui.h"

#include "camera.h"
#include "DBUS_greeter.h"

#define CASCADE_NAME DATA_DIR"/haaracscades/haarcascade_frontalface_alt.xml"
#define ESC_KEY 27
#define DELAY_TIME 2.0

char* reco();

static CvCapture* capture = NULL;
static IplImage* small_img = NULL;
static IplImage* gray = NULL;

static char* username = NULL;


void do_quit()
{
    /* if (username != NULL) */
    /*     dbus_remove_from_nopwd_login_group(username); */

    if (capture)
        cvReleaseCapture(&capture);

    if (small_img)
        cvReleaseImage(&small_img);

    if (gray)
        cvReleaseImage(&gray);
}


void handler(int signum)
{
    if (signum == 9)
        do_quit();
}

enum {
    NOT_START_RECOGNIZE,
    START_RECOGNIZE,
    RECOGNIZED
};


int main(int argc, char *argv[])
{
    signal(9, handler);

    IplImage* frame = NULL;
    capture = cvCaptureFromCAM(-1);

    if (capture == NULL)
        return 1;

    cvNamedWindow(CAMERA, 0);
    CvHaarClassifierCascade* cascade = (CvHaarClassifierCascade*)cvLoad(CASCADE_NAME, 0, 0, 0);
    CvMemStorage* storage = cvCreateMemStorage(0);
    double scale = 1.3;

    int flag = NOT_START_RECOGNIZE;
    time_t start;
    time(&start);
    time_t output = 0;
    double diff_time = 0;


    while (1) {
        frame = cvQueryFrame(capture);

        time(&output);

        if (flag == NOT_START_RECOGNIZE)
            diff_time = difftime(output, start);

        if (flag != NOT_START_RECOGNIZE || diff_time > DELAY_TIME) {
            if (flag == NOT_START_RECOGNIZE) {
                flag = START_RECOGNIZE;
                // TODO: start animation
                /* dbus_start_animation(); */
                g_warning("start animation");
                GError *error = NULL;
                GDBusProxy* proxy = g_dbus_proxy_new_for_bus_sync(G_BUS_TYPE_SYSTEM,
                                                                  0,
                                                                  NULL,
                                                                  "com.deepin.dde.greeter",
                                                                  "/com/deepin/dde/greeter",
                                                                  "com.deepin.dde.greeter",
                                                                  NULL,
                                                                  &error);
                if (error != NULL) {
                    g_warning ("call dbus_start_animation on com.deepin.dde.greeter failed");
                    g_error_free(error);
                }
                if (proxy != NULL) {
                    GVariant* params = NULL;

                    GVariant* retval = g_dbus_proxy_call_sync(proxy,
                                                              "StartAnimation",
                                                              params,
                                                              G_DBUS_CALL_FLAGS_NONE,
                                                              -1, NULL, &error);
                    if (retval != NULL) {
                        g_variant_unref(retval);
                    } else {
                        g_warning("%s", error->message);
                        g_error_free(error);
                    }

                    g_object_unref(proxy);
                }
            }

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
                if (flag == START_RECOGNIZE)
                    cvSaveImage("/tmp/deepin_user_face.png", frame, NULL);

                for (int i = 0; i < objects->total; ++i) {
                    CvRect* r = (CvRect*)cvGetSeqElem(objects, i);
                    cvRectangle(frame, cvPoint(r->x * scale, r->y * scale),
                                cvPoint((r->x + r->width) * scale, (r->y + r->height) * scale),
                                cvScalar(0xff, 0xff, 0, 0), 4, 8, 0);
                }
            }
        }

        cvShowImage(CAMERA, frame);
        cvReleaseImage(&gray);
        cvReleaseImage(&small_img);

        if ((cvWaitKey(10) & 0xff) == ESC_KEY)
            break;

        if (flag == START_RECOGNIZE) {
            flag = NOT_START_RECOGNIZE;
            reco();

            // TODO: stop animation
            /* dbus_stop_animation(); */
            if (username == NULL) {
                time(&start);
            } else {
                flag = RECOGNIZED;
                // TODO: start login
                /* dbus_start_login(); */
            }
        }
    }

    do_quit();

    return 0;
}


char* reco()
{
    int exit_code = 1;
    char* args[] = {"/usr/bin/python", "/home/liliqiang/dde/app/greeter/reco", NULL};
    g_spawn_sync(NULL, args, NULL, 0, NULL, NULL, &username, NULL, &exit_code,
                 NULL);
    return username;
}
