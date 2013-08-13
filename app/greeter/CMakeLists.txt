SET(NAME "greeter")

GEN_JSC_SOURCE2(JSC_GEN "jsc" "greeter" "greeter.cfg" "dbus.cfg")
GEN_JSC_SOURCE2(JSC_LOCK_GEN "jsc" "lock" "lock.cfg" "dbus.cfg")
GEN_DBUS_SOURCE(DBUS_GEN "jsc/dbus.go" "greeter")

pkg_check_modules(LIGHTDM REQUIRED liblightdm-gobject-1)
pkg_check_modules(OPENCV REQUIRED opencv)

add_executable(${NAME} greeter.c account.c user.c power.c session.c ${JSC_GEN}
    draw.c settings.c ${DBUS_GEN} connection.c)
add_executable(switchtogreeter switchtogreeter.c)
add_executable(dlock dlock.c gs-grab.c account.c ${JSC_LOCK_GEN} draw.c
    settings.c ${DBUS_GEN} connection.c)
add_executable(lockservice lockservice.c)

set(CAMERA_WINDOW _camera)
add_definitions("-DCAMERA_WINDOW=\"${CAMERA_WINDOW}\"")
add_executable(${CAMERA_WINDOW} camera.c)

set(HAS_CAMERA _has_camera)
add_definitions("-DHAS_CAMERA=\"${HAS_CAMERA}\"")
add_executable(${HAS_CAMERA} has_camera.c)

target_link_libraries(${NAME} dcom dbus ${DWEBVIEW_LIBRARIES}
    ${LIGHTDM_LIBRARIES})
target_link_libraries(switchtogreeter ${DWEBVIEW_LIBRARIES})
target_link_libraries(dlock dcom dbus ${DWEBVIEW_LIBRARIES})
target_link_libraries(lockservice crypt dcom dbus ${DWEBVIEW_LIBRARIES})
target_link_libraries(${CAMERA_WINDOW} ${OPENCV_LIBRARIES} glib-2.0 gobject-2.0
    gio-2.0)
target_link_libraries(${HAS_CAMERA} ${OPENCV_LIBRARIES})

include_directories(${DWEBVIEW_INCLUDE_DIRS} ${LIGHTDM_INCLUDE_DIRS})

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
    PROGRAMS ${PROJECT_BINARY_DIR}/${CAMERA_WINDOW}
    DESTINATION bin
    )

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/${HAS_CAMERA}
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
