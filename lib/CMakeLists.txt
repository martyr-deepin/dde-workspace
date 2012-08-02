cmake_minimum_required(VERSION 2.8)
include_directories(${DWEBVIEW_INCLUDE_DIRS} "jsc_extension")

AUX_SOURCE_DIRECTORY(jsc_extension jsc_ext)
AUX_SOURCE_DIRECTORY(jsc_extension/gen/ jsc_ext_gen)

include(CheckCSourceRuns)
set(CMAKE_REQUIRED_INCLUDES  ${DBUS_INCLUDE_DIRS})
CHECK_C_SOURCE_RUNS(
    "#include <dbus/dbus.h>
    int main() { DBusBasicValue a;}
    "  HasDbusBasicValue)

if (HasDbusBasicValue) 
    add_definitions("-D__DBUSBASIC_VALUE__=1")
endif()


set(SRC_LIST 
    utils.c
    webview.c
    ${jsc_ext}
    ${jsc_ext_gen}
    )

add_library(dwebkit ${SRC_LIST})
target_link_libraries(dwebkit ${DWEBVIEW_LIBRAIRES})
