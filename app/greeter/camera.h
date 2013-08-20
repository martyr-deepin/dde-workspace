#ifndef CAMERA_H
#define CAMERA_H

#define IMAGE_NAME "/tmp/deepin_user_face_for_login.png"

gboolean has_camera();
void init_camera(int argc, char* argv[]);
void destroy_camera();

#endif /* end of include guard: CAMERA_H */

