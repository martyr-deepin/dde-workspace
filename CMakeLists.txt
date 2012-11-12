cmake_minimum_required(VERSION 2.8)


if (DEFINED DEVELOP)
    SET(RESOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/resources")
else()
    SET(RESOURCE_DIR "${CMAKE_INSTALL_PREFIX}/share/deepin-desktop/resources")
endif()

add_definitions("-DRESOURCE_DIR=\"${RESOURCE_DIR}\"")
add_definitions("-DDESKTOP_DB_PATH=\"desktop.db\"")

find_package(PkgConfig)
pkg_check_modules(WEBKIT REQUIRED deepin-webkit-3.0)

set(CMAKE_C_FLAGS "-std=c99")



set(JSC_HEADER ${CMAKE_CURRENT_SOURCE_DIR}/lib/jsc_extension/)
include_directories(${JSC_HEADER})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/lib)

set(BIN_JSC_GEN ${CMAKE_CURRENT_SOURCE_DIR}/lib/jsc_extension/jsc_gen.py)

set(DWEBVIEW_INCLUDE_DIRS ${WEBKIT_INCLUDE_DIRS}) 
set(DWEBVIEW_LIBRARIES ${WEBKIT_LIBRARIES} ${DBUS_LIBRARIES})
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR})


add_subdirectory(lib)
add_subdirectory(app)
#add_subdirectory(po)

