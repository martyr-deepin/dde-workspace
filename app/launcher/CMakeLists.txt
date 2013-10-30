SET(NAME "launcher")


add_subdirectory(test)

GEN_JSC_SOURCE(JSC_GEN "jsc")
GEN_DBUS_SOURCE(DBUS_GEN "jsc/dbus.go" "launcher")

file(GLOB CFILES *.c)

SET(SRC_LIST ${CFILES} ${JSC_GEN} ${DBUS_GEN})

add_executable(${NAME} ${SRC_LIST})

target_link_libraries(${NAME} dcom dentry dbus ${DWEBVIEW_LIBRARIES}
    dlauncher_test)

include_directories(${DWEBVIEW_INCLUDE_DIRS})

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/${NAME}
    DESTINATION bin
    )
install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}
    DESTINATION ${RESOURCE_DIR}
    )

GEN_JS_FILE(${NAME})

install(
    FILES ${CMAKE_CURRENT_SOURCE_DIR}/deepin-launcher.desktop
    DESTINATION /etc/xdg/autostart/
    )
