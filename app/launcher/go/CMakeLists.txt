set(Name ${NAME}-daemon)
file(GLOB GoFiles *.go)
add_custom_target(${Name}
	COMMAND go build -o ${PROJECT_BINARY_DIR}/${Name} ${GoFiles}
	)

install(
	FILES ${PROJECT_BINARY_DIR}/${Name}
	DESTINATION /usr/lib/deepin-daemon/
	)

install(
	FILES ${CMAKE_CURRENT_SOURCE_DIR}/com.deepin.dde.daemon.Laucher.service
	DESTINATION /usr/share/dbus-1/services/
    )
