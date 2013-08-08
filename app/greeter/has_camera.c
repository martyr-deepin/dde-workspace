#include "opencv/cv.h"
#include "opencv/highgui.h"


int main(int argc, char *argv[])
{
    CvCapture* capture = cvCaptureFromCAM(-1);
    int has_camera = capture == NULL;
    cvReleaseCapture(&capture);

    return has_camera;
}
