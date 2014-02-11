set(Name ${NAME}-daemon)
file(GLOB GoFiles *.go)
add_custom_target(${Name}
	COMMAND go build -o ${PROJECT_BINARY_DIR}/${Name} ${GoFiles}
	)
