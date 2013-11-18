pkg_check_modules(GTK REQUIRED gtk+-3.0)

set(NAME dde_tray)

file(GLOB SRC *.c)
add_executable(${NAME} ${SRC})
include_directories(${GTK_INCLUDE_DIRS})
target_link_libraries(${NAME} ${GTK_LIBRARIES} dcom dentry dbus
    ${DBUS_LIBRARIES} ${DWEBVIEW_LIBRARIES} dtest)

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/${NAME}
    DESTINATION bin
    )
