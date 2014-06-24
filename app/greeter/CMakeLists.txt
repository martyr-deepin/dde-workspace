SET(NAME "greeter")

GEN_JSC_SOURCE2(JSC_GEN "jsc" "greeter" "greeter.cfg" "dbus.cfg")
GEN_JSC_SOURCE2(JSC_LOCK_GEN "jsc" "lock" "lock.cfg" "dbus.cfg")
GEN_DBUS_SOURCE(DBUS_GEN "jsc/dbus.go" "greeter")

pkg_check_modules(LIGHTDM REQUIRED liblightdm-gobject-1)
#pkg_check_modules(OPENCV REQUIRED opencv)
pkg_check_modules(GST REQUIRED gstreamer-0.10)

include_directories(${DWEBVIEW_INCLUDE_DIRS} ${LIGHTDM_INCLUDE_DIRS}
    ${GST_INCLUDE_DIRS}
    #${OPENCV_INCLUDE_DIRES}
    )

#set(OPENCV_LIBS opencv_core opencv_imgproc opencv_objdetect)

add_executable(${NAME} greeter.c user.c session.c theme.c mutils.c greeter_util.c ${JSC_GEN}
    ${DBUS_GEN}
    #camera.c settings.c
    )
add_dependencies(${NAME} ${NAME}_js)
target_link_libraries(${NAME} dcom dbus ${DWEBVIEW_LIBRARIES} ${LIGHTDM_LIBRARIES}
    ${GST_LIBRARIES}
    #${OPENCV_LIBS}
    )

add_executable(lock lock.c user.c theme.c lock_util.c mutils.c ${JSC_LOCK_GEN}
    ${DBUS_GEN}
    #camera.c settings.c
    )
add_dependencies(lock ${NAME}_js)
target_link_libraries(lock dcom dbus ${DWEBVIEW_LIBRARIES} 
    ${GST_LIBRARIES}
    #${OPENCV_LIBS}
    )

add_executable(switchtogreeter switchtogreeter.c)
add_dependencies(switchtogreeter ${NAME}_js)
target_link_libraries(switchtogreeter ${DWEBVIEW_LIBRARIES})

add_executable(lockservice lockservice.c)
add_dependencies(lockservice ${NAME}_js)
target_link_libraries(lockservice crypt dcom dbus ${DWEBVIEW_LIBRARIES})

SET_TARGET_PROPERTIES(
    ${NAME}
    PROPERTIES OUTPUT_NAME lightdm-deepin-greeter
    )
SET_TARGET_PROPERTIES(
    lock 
    PROPERTIES OUTPUT_NAME dde-lock
    )
SET_TARGET_PROPERTIES(
    switchtogreeter 
    PROPERTIES OUTPUT_NAME dde-switchtogreeter
    )
SET_TARGET_PROPERTIES(
    lockservice 
    PROPERTIES OUTPUT_NAME dde-lockservice
    )


install(
    PROGRAMS ${PROJECT_BINARY_DIR}/lightdm-deepin-greeter
    DESTINATION bin
    )

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/dde-lock
    DESTINATION bin
    )

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/dde-switchtogreeter
    DESTINATION bin
    )

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/dde-lockservice
    DESTINATION bin
    )

install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}
    DESTINATION ${RESOURCE_DIR}
    )

install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}/greeter-theme
    DESTINATION /usr/share/personalization/
    )


install(
    FILES ${PROJECT_SOURCE_DIR}/app/greeter/com.deepin.dde.lightdm.service
    DESTINATION /usr/share/dbus-1/system-services/
    )

install(
    FILES ${PROJECT_SOURCE_DIR}/app/greeter/com.deepin.dde.lock.service
    DESTINATION /usr/share/dbus-1/services/
    )

install(
    FILES ${PROJECT_SOURCE_DIR}/app/greeter/com.deepin.dde.lock.conf
    DESTINATION /etc/dbus-1/system.d/
    )

GEN_JS_FILE(${NAME})
