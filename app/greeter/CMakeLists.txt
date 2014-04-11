SET(NAME "lightdm-deepin-greeter")
SET(NAME_SRC "greeter")

GEN_JSC_SOURCE2(JSC_GEN "jsc" "greeter" "greeter.cfg" "dbus.cfg")
GEN_JSC_SOURCE2(JSC_LOCK_GEN "jsc" "lock" "lock.cfg" "dbus.cfg")
GEN_DBUS_SOURCE(DBUS_GEN "jsc/dbus.go" "greeter")

pkg_check_modules(LIGHTDM REQUIRED liblightdm-gobject-1)
#pkg_check_modules(OPENCV REQUIRED opencv)
pkg_check_modules(GST REQUIRED gstreamer-0.10)

add_executable(${NAME} greeter.c user.c session.c mutils.c greeter_util.c ${JSC_GEN}
    ${DBUS_GEN}
    #camera.c settings.c ${DBUS_GEN}
    )
add_dependencies(${NAME} ${NAME_SRC}_js)
add_executable(dde-lock lock.c user.c lock_util.c mutils.c ${JSC_LOCK_GEN}
    ${DBUS_GEN}
    #camera.c settings.c ${DBUS_GEN}
    )
add_dependencies(dde-lock ${NAME_SRC}_js)
add_executable(dde-switchtogreeter switchtogreeter.c)
add_dependencies(dde-switchtogreeter ${NAME_SRC}_js)
add_executable(dde-lockservice lockservice.c)
add_dependencies(dde-lockservice ${NAME_SRC}_js)

#set(OPENCV_LIBS opencv_core opencv_imgproc opencv_objdetect)
target_link_libraries(${NAME} dcom dbus ${DWEBVIEW_LIBRARIES} ${LIGHTDM_LIBRARIES}
    ${GST_LIBRARIES}
    #${OPENCV_LIBS} ${GST_LIBRARIES}
    )
target_link_libraries(dde-lock dcom dbus ${DWEBVIEW_LIBRARIES} 
    ${GST_LIBRARIES})
    #${OPENCV_LIBS} ${GST_LIBRARIES})
target_link_libraries(dde-switchtogreeter ${DWEBVIEW_LIBRARIES})
target_link_libraries(dde-lockservice crypt dcom dbus ${DWEBVIEW_LIBRARIES})

include_directories(${DWEBVIEW_INCLUDE_DIRS} ${LIGHTDM_INCLUDE_DIRS}
    ${OPENCV_INCLUDE_DIRES} ${GST_INCLUDE_DIRS})

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/${NAME}
    DESTINATION bin
    )
install(
    PROGRAMS ${PROJECT_BINARY_DIR}/dde-switchtogreeter
    DESTINATION bin
    )

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/dde-lock
    DESTINATION bin
    )

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/dde-lockservice
    DESTINATION bin
    )

install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME_SRC}
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

GEN_JS_FILE(${NAME_SRC})
