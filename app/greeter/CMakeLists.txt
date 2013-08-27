SET(NAME "greeter")

GEN_JSC_SOURCE2(JSC_GEN "jsc" "greeter" "greeter.cfg" "dbus.cfg")
GEN_JSC_SOURCE2(JSC_LOCK_GEN "jsc" "lock" "lock.cfg" "dbus.cfg")
GEN_DBUS_SOURCE(DBUS_GEN "jsc/dbus.go" "greeter")

pkg_check_modules(LIGHTDM REQUIRED liblightdm-gobject-1)
pkg_check_modules(OPENCV REQUIRED opencv)
pkg_check_modules(GST REQUIRED gstreamer-0.10)

add_executable(${NAME} greeter.c account.c user.c power.c session.c ${JSC_GEN}
    camera.c settings.c ${DBUS_GEN})
add_executable(switchtogreeter switchtogreeter.c)
add_executable(dlock dlock.c gs-grab.c account.c ${JSC_LOCK_GEN} camera.c
    settings.c ${DBUS_GEN})
add_executable(lockservice lockservice.c)

set(OPENCV_LIBS opencv_core opencv_imgproc opencv_objdetect)

target_link_libraries(${NAME} dcom dbus ${DWEBVIEW_LIBRARIES}
    ${LIGHTDM_LIBRARIES} ${GST_LIBRARIES} ${OPENCV_LIBS})
target_link_libraries(switchtogreeter ${DWEBVIEW_LIBRARIES})
target_link_libraries(dlock dcom dbus ${DWEBVIEW_LIBRARIES} ${GST_LIBRARIES}
    ${OPENCV_LIBS})
target_link_libraries(lockservice crypt dcom dbus ${DWEBVIEW_LIBRARIES})

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
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}
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
