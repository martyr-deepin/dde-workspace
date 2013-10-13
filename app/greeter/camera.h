/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 Liqiang Lee
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

#ifndef CAMERA_H
#define CAMERA_H

#define IMAGE_NAME "/tmp/deepin_user_face_for_login.png"


enum RecognizeState {
    NOT_START_RECOGNIZING,
    START_RECOGNIZING,
    RECOGNIZING,
    RECOGNIZED,
    NOT_RECOGNIZED,
    RECOGNIZE_FINISH
};

struct RecognitionInfo {
    gboolean detect_is_enabled;
    gboolean has_data;
    enum RecognizeState reco_state;
    int reco_times;
    double DELAY_TIME;
    GTimer* timer;
    guint length;
    GPid pid;
    guchar* source_data;
    gchar* current_username;
};

extern struct RecognitionInfo recognition_info;

gboolean has_camera();
void init_camera(int argc, char* argv[]);
void connect_camera();
void destroy_camera();
void init_reco_state();

#endif /* end of include guard: CAMERA_H */

