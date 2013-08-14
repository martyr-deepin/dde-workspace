#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <signal.h>
#include <unistd.h>

#include <gtk/gtk.h>
#include <glib.h>
#include <gio/gio.h>
#include "opencv/cv.h"
#include "opencv/highgui.h"
#include "camera.h"


#define CASCADE_NAME DATA_DIR"/haaracscades/haarcascade_frontalface_alt.xml"
#define ESC_KEY 27
#define DELAY_TIME 2.0


enum {
    NOT_START_RECOGNIZE,
    START_RECOGNIZE,
    RECOGNIZED
};

static CvCapture* capture = NULL;
static IplImage* small_img = NULL;
static IplImage* gray = NULL;

static IplImage* frame = NULL;
static CvHaarClassifierCascade* cascade = NULL;
static CvMemStorage* storage = NULL;

static char* username = NULL;
static int flag = 0;
static time_t start;
static time_t output = 0;
static double diff_time = 0;
static double scale = 1.3;

static GMainLoop* main_loop = NULL;


void do_quit();
void handler(int signum);
char* reco();
gboolean _camera(gpointer data);


int main(int argc, char *argv[])
{
    main_loop = g_main_loop_new(NULL, TRUE);

    signal(9, handler);

    capture = cvCaptureFromCAM(-1);

    if (capture == NULL)
        return 1;
    flag = NOT_START_RECOGNIZE;
    cvNamedWindow(CAMERA, 0);
    cascade = (CvHaarClassifierCascade*)cvLoad(CASCADE_NAME, 0, 0, 0);
    storage = cvCreateMemStorage(0);

    time(&start);

    g_timeout_add(40, _camera, NULL);

    g_main_loop_run(main_loop);

    do_quit();

    return 0;
}


void do_quit()
{
    /* if (username != NULL) */
    /*     dbus_remove_from_nopwd_login_group(username); */
    if (main_loop)
        g_main_loop_unref(main_loop);

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


char* reco()
{
    int exit_code = 1;
    char* args[] = {"/usr/bin/python", "/home/liliqiang/dde/app/greeter/reco", NULL};
    GError* err = NULL;
    g_spawn_sync(NULL, args, NULL, 0, NULL, NULL, &username, NULL, &exit_code,
                 &err);
    if (err != NULL) {
        g_warning("[reco] %s", err->message);
        g_error_free(err);
    }
    return username;
}


gboolean _camera(gpointer data)
{
    frame = cvQueryFrame(capture);
    time(&output);

    if (flag == NOT_START_RECOGNIZE)
        diff_time = difftime(output, start);

    if (flag != NOT_START_RECOGNIZE || diff_time > DELAY_TIME) {
        if (flag == NOT_START_RECOGNIZE) {
            flag = START_RECOGNIZE;
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

    cvShowImage(CAMERA, frame);
    cvReleaseImage(&gray);
    cvReleaseImage(&small_img);

    /* if ((cvWaitKey(10) & 0xff) == ESC_KEY) */
    /*     do_quit(); */

    if (flag == START_RECOGNIZE) {
        /* g_warning("start animation"); */
        /* system("dbus-send /com/deepin/dde/lock com.deepin.dde.lock.StartAnimation"); */

        /* if (0 == system("touch /tmp/start-animation")) */
        /*     g_warning("emit signal finish"); */


        // stop animation and login
        flag = NOT_START_RECOGNIZE;
        reco();

        // TODO: stop animation
        /* system("touch /tmp/stop-animation"); */
        if (username == NULL) {
            time(&start);
        } else {
            flag = RECOGNIZED;
            g_warning("user name: %s", username);
            // TODO: start login
            system("touch /tmp/start-login");
        }
    }

    return TRUE;
}
