SET(NAME "lightdm-deepin-greeter")
SET(NAME_SIMPLE "greeter")

GEN_JSC_SOURCE2(JSC_GEN "jsc" "greeter" "greeter.cfg" "dbus.cfg")
GEN_JSC_SOURCE2(JSC_LOCK_GEN "jsc" "lock" "lock.cfg" "dbus.cfg")
GEN_DBUS_SOURCE(DBUS_GEN "jsc/dbus.go" "greeter")

pkg_check_modules(LIGHTDM REQUIRED liblightdm-gobject-1)
pkg_check_modules(OPENCV REQUIRED opencv)
pkg_check_modules(GST REQUIRED gstreamer-0.10)

add_executable(${NAME} greeter.c user.c session.c mutils.c greeter_util.c ${JSC_GEN}
    camera.c settings.c ${DBUS_GEN}
    )
add_dependencies(${NAME} ${NAME}_js)
add_executable(dlock dlock.c user.c lock_util.c mutils.c ${JSC_LOCK_GEN}
    camera.c settings.c ${DBUS_GEN}
    )
add_dependencies(dlock ${NAME}_js)
add_executable(switchtogreeter switchtogreeter.c)
add_dependencies(switchtogreeter ${NAME}_js)
add_executable(lockservice lockservice.c)
add_dependencies(lockservice ${NAME}_js)

set(OPENCV_LIBS opencv_core opencv_imgproc opencv_objdetect)
target_link_libraries(${NAME} dcom dbus ${DWEBVIEW_LIBRARIES} ${LIGHTDM_LIBRARIES}
    ${OPENCV_LIBS} ${GST_LIBRARIES}
    )
target_link_libraries(dlock dcom dbus ${DWEBVIEW_LIBRARIES} ${OPENCV_LIBS}
    ${GST_LIBRARIES})
target_link_libraries(switchtogreeter ${DWEBVIEW_LIBRARIES})
target_link_libraries(lockservice crypt dcom dbus ${DWEBVIEW_LIBRARIES})

include_directories(${DWEBVIEW_INCLUDE_DIRS} ${LIGHTDM_INCLUDE_DIRS}
    ${OPENCV_INCLUDE_DIRES} ${GST_INCLUDE_DIRS})

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/${NAME}
    DESTINATION bin
    )
install(
    PROGRAMS ${PROJECT_BINARY_DIR}/switchtogreeter
    DESTINATION bin
    )

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/dlock
    DESTINATION bin
    )

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/lockservice
    DESTINATION bin
    )

install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME_SIMPLE}
    DESTINATION ${RESOURCE_DIR}
    )

install(
    FILES ${PROJECT_SOURCE_DIR}/app/greeter/com.deepin.dde.lock.service
    DESTINATION /usr/share/dbus-1/system-services/
    )

install(
    FILES ${PROJECT_SOURCE_DIR}/app/greeter/com.deepin.dde.lock.conf
    DESTINATION /etc/dbus-1/system.d/
    )
