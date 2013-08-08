#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <signal.h>
#include <unistd.h>

#include <glib.h>
#include "opencv/cv.h"
#include "opencv/highgui.h"

#include "camera.h"

#define CASCADE_NAME DATA_DIR"/haaracscades/haarcascade_frontalface_alt.xml"
#define ESC_KEY 27
#define DELAY_TIME 2.0

void* reco(void* arg);

static CvCapture* capture = NULL;
static IplImage* small_img = NULL;
static IplImage* gray = NULL;


void do_quit()
{
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

    int flag = 0;
    time_t start;
    time(&start);
    time_t output = 0;
    double diff_time = 0;

    int exit_code = 1;

    while (1) {
        frame = cvQueryFrame(capture);

        time(&output);

        if (!flag)
            diff_time = difftime(output, start);

        if (flag || diff_time > DELAY_TIME) {
            if (!flag) {
                flag = 1;
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
                if (flag == 1)
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

        if (flag == 1) {
            flag = !flag;
            /* sleep(DELAY_TIME); */
            /* pthread_create(&pid, NULL, reco, NULL); */
            char* args[] = {"/usr/bin/python", "/home/liliqiang/dde/app/greeter/reco", NULL};
            g_spawn_sync(NULL, args, NULL, 0, NULL, NULL, NULL, NULL, &exit_code,
                         NULL);

            if (exit_code != 0) {
                time(&start);
            } else {
                flag = 2;
            }
        }
    }

    do_quit();

    return 0;
}


void* reco(void* arg)
{
    ;
}
