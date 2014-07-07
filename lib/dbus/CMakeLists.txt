cmake_minimum_required(VERSION 2.8)

include_directories(${DWEBVIEW_INCLUDE_DIRS})

AUX_SOURCE_DIRECTORY(. DBUS)

set(SRC_LIST ${DBUS})

add_library(dbus ${SRC_LIST})
