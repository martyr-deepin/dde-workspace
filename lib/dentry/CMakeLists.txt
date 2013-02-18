cmake_minimum_required(VERSION 2.8)

find_package(PkgConfig REQUIRED)
#used by thumbnails.c/h
pkg_check_modules(GNOME_DESKTOP3 REQUIRED gnome-desktop-3.0)
include_directories(${GNOME_DESKTOP3_INCLUDE_DIRS})
link_directories(${GNOME_DESKTOP3_LIBRARY_DIRS})

include_directories(${DWEBVIEW_INCLUDE_DIRS})

AUX_SOURCE_DIRECTORY(. DEntry)

set(SRC_LIST ${DEntry})

include_directories(${DWEBVIEW_INCLUDE_DIRS})

add_library(dentry ${SRC_LIST})
target_link_libraries(dentry ${DWEBVIEW_LIBRAIRES} ${GNOME_DESKTOP3_LIBRARIES})

