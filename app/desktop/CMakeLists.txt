SET(NAME "desktop")

add_subdirectory(test)

GEN_JSC_SOURCE(JSC_GEN "jsc")
GEN_DBUS_SOURCE(DBUS_GEN "jsc/dbus.go" "desktop")

SET(SRC_LIST desktop.c background.c background_util.c background_util.h
    inotify_item.c utils.c ${JSC_GEN} ${DBUS_GEN})

add_executable(${NAME} ${SRC_LIST})
add_dependencies(${NAME} ${NAME}_js)

target_link_libraries(${NAME} dcom dentry dbus ${DWEBVIEW_LIBRARIES}
    desktop_test dtest)

include_directories(${DWEBVIEW_INCLUDE_DIRS})

GEN_JS_FILE(${NAME})

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/${NAME}
    DESTINATION bin
    )
install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}
    DESTINATION ${RESOURCE_DIR}
    )

install(
    FILES ${CMAKE_CURRENT_SOURCE_DIR}/deepin-desktop.desktop
    DESTINATION ${CMAKE_INSTALL_PREFIX}/share/applications
    )
