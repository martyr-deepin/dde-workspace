set(NAME default-terminal)

pkg_check_modules(GIO gio-unix-2.0)
include_directories(${GIO_INCLUDE_DIRS})
add_executable(${NAME} default-terminal.c)
target_link_libraries(${NAME} ${GIO_LIBRARIES})

install(
	PROGRAMS ${PROJECT_BINARY_DIR}/${NAME}
	DESTINATION bin
	)
