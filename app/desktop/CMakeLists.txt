SET(NAME "dde-desktop")
SET(NAME_SRC "desktop")

add_subdirectory(test)

GEN_JSC_SOURCE(JSC_GEN "jsc")
GEN_DBUS_SOURCE(DBUS_GEN "jsc/dbus.go" "desktop")

SET(SRC_LIST desktop.c inotify_item.c utils.c proxy.c ${JSC_GEN} ${DBUS_GEN})

add_executable(${NAME} ${SRC_LIST})
add_dependencies(${NAME} ${NAME_SRC}_js)

target_link_libraries(${NAME} crypt dcom dentry dbus ${DWEBVIEW_LIBRARIES}
    desktop_test dtest)

include_directories(${DWEBVIEW_INCLUDE_DIRS})

GEN_JS_FILE(${NAME_SRC})

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/${NAME}
    DESTINATION bin
    )
install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME_SRC}
    DESTINATION ${RESOURCE_DIR}
    )

install(
    FILES ${CMAKE_CURRENT_SOURCE_DIR}/dde-desktop.desktop
    DESTINATION ${CMAKE_INSTALL_PREFIX}/share/applications
    )
