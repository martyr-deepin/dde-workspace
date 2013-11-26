pkg_check_modules(GTK REQUIRED gtk+-3.0)

set(NAME dapptray)

include_directories(${GTK_INCLUDE_DIRS})

file(GLOB SRC *.c)
add_executable(${NAME} ${SRC})
target_link_libraries(${NAME} dcom ${GTK_LIBRARIES} X11 Xext m)

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/${NAME}
    DESTINATION bin
    )
