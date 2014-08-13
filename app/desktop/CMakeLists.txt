SET(NAME "desktop")

add_subdirectory(test)

GEN_JSC_SOURCE(JSC_GEN "jsc")
GEN_DBUS_SOURCE(DBUS_GEN "jsc/dbus.go" "desktop")

include_directories(${DWEBVIEW_INCLUDE_DIRS})

SET(SRC_LIST desktop.c inotify_item.c desktop_utils.c proxy.c ${JSC_GEN} ${DBUS_GEN})

add_executable(${NAME} ${SRC_LIST})
add_dependencies(${NAME} ${NAME}_js)

target_link_libraries(${NAME} crypt dcom dentry dbus ${DWEBVIEW_LIBRARIES}
    desktop_test dtest)


SET_TARGET_PROPERTIES(${NAME}
    PROPERTIES OUTPUT_NAME dde-${NAME}
    )

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/dde-${NAME}
    DESTINATION bin
    )
install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}
    DESTINATION ${RESOURCE_DIR}
    )

install(
    FILES ${CMAKE_CURRENT_SOURCE_DIR}/dde-desktop.desktop
    DESTINATION ${CMAKE_INSTALL_PREFIX}/share/applications
    )

GEN_JS_FILE(${NAME})
