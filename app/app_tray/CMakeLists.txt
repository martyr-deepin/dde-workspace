pkg_check_modules(GTK REQUIRED gtk+-3.0)

set(NAME dapptray)
GEN_DBUS_SOURCE(DBUS_GEN "jsc/dbus.go" ${NAME})

include_directories(${GTK_INCLUDE_DIRS})

file(GLOB SRC *.c)
add_executable(${NAME} ${SRC} ${DBUS_GEN})
target_link_libraries(${NAME} dcom ${GTK_LIBRARIES} X11 Xext m)

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/${NAME}
    DESTINATION bin
    )

install(
    FILES ${CMAKE_CURRENT_SOURCE_DIR}/deepin-apptray.desktop
    DESTINATION /etc/xdg/autostart/
    )
