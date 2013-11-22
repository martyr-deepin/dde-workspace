SET(NAME "shutdown")

GEN_JSC_SOURCE2(JSC_GEN "jsc" "shutdown" "shutdown.cfg" "dbus.cfg")
GEN_DBUS_SOURCE(DBUS_GEN "jsc/dbus.go" "shutdown")

pkg_check_modules(LIGHTDM REQUIRED liblightdm-gobject-1)
pkg_check_modules(OPENCV REQUIRED opencv)
pkg_check_modules(GST REQUIRED gstreamer-0.10)

file(GLOB CFILES *.c)

SET(SRC_LIST ${CFILES} ${JSC_GEN} ${DBUS_GEN})

add_executable(${NAME} ${SRC_LIST})

set(OPENCV_LIBS opencv_core opencv_imgproc opencv_objdetect)
target_link_libraries(${NAME} dcom dbus ${DWEBVIEW_LIBRARIES} ${LIGHTDM_LIBRARIES}
    ${OPENCV_LIBS} ${GST_LIBRARIES}
    )
target_link_libraries(${NAME} dcom dbus ${DWEBVIEW_LIBRARIES} ${OPENCV_LIBS}
    ${GST_LIBRARIES})

include_directories(${DWEBVIEW_INCLUDE_DIRS} ${LIGHTDM_INCLUDE_DIRS}
    ${OPENCV_INCLUDE_DIRES} ${GST_INCLUDE_DIRS})

execute_process(
    COMMAND make
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}/js
    )

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/${NAME}
    DESTINATION bin
    )

install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}
    DESTINATION ${RESOURCE_DIR}
    )

install(
    FILES ${PROJECT_SOURCE_DIR}/app/shutdown/com.deepin.dde.shutdown.service
    DESTINATION /usr/share/dbus-1/system-services/
    )

install(
    FILES ${PROJECT_SOURCE_DIR}/app/shutdown/com.deepin.dde.shutdown.conf
    DESTINATION /etc/dbus-1/system.d/
    )
