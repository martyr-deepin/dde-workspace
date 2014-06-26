SET(NAME "language")

GEN_JSC_SOURCE2(JSC_GEN "jsc" "greeter" "greeter.cfg" "dbus.cfg")
GEN_DBUS_SOURCE(DBUS_GEN "jsc/dbus.go" "greeter")

pkg_check_modules(LIGHTDM REQUIRED liblightdm-gobject-1)
pkg_check_modules(GST REQUIRED gstreamer-0.10)

include_directories(${DWEBVIEW_INCLUDE_DIRS} ${LIGHTDM_INCLUDE_DIRS}
    ${GST_INCLUDE_DIRS}
    )

add_executable(${NAME} greeter.c user.c session.c theme.c mutils.c greeter_util.c lightdmservice.c ${JSC_GEN}
    ${DBUS_GEN}
    )
add_dependencies(${NAME} ${NAME}_js)
target_link_libraries(${NAME} dcom dbus ${DWEBVIEW_LIBRARIES} ${LIGHTDM_LIBRARIES}
    ${GST_LIBRARIES}
    )

SET_TARGET_PROPERTIES(
    ${NAME}
    PROPERTIES OUTPUT_NAME deepin-greeter-language-selection
    )

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/deepin-greeter-language-selection
    DESTINATION bin
    )

install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}
    DESTINATION ${RESOURCE_DIR}
    )

install(
    FILES ${PROJECT_SOURCE_DIR}/app/greeter/com.deepin.dde.lightdm.service
    DESTINATION /usr/share/dbus-1/system-services/
    )

GEN_JS_FILE(${NAME})
