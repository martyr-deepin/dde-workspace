cmake_minimum_required(VERSION 2.8)

if (DEFINED DEVELOP)
    SET(RESOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/resources")
else()
    SET(RESOURCE_DIR "${CMAKE_INSTALL_PREFIX}/share/deepin-desktop/resources")
endif()

message("RESOURCE DIR ${RESOURCE_DIR}")
add_definitions("-DRESOURCE_DIR=\"${RESOURCE_DIR}\"")

find_package(PkgConfig)
pkg_check_modules(WEBKIT REQUIRED deepin-webkit-3.0)
#pkg_check_modules(WEBKIT REQUIRED webkitgtk-3.0)
pkg_check_modules(DBUS REQUIRED dbus-glib-1)

set(CMAKE_C_FLAGS "-std=c99")

set(DWEBVIEW_INCLUDE_DIRS
    ${WEBKIT_INCLUDE_DIRS} 
    ${DBUS_INCLUDE_DIRS}
    "${CMAKE_CURRENT_SOURCE_DIR}/lib"
    )
set(test "${CMAKE_CURRENT_SOURCE_DIR}/lib")

set(DWEBVIEW_LIBRARIES ${WEBKIT_LIBRARIES} ${DBUS_LIBRARIES})
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR})


add_subdirectory(lib)
add_subdirectory(app)
