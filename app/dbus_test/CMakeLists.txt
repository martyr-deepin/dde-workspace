set(NAME "dbus_test")


GEN_JSC_SOURCE(JSC_GEN "jsc")
SET(SRC_LIST web.c ${JSC_GEN})

add_executable(${NAME} ${SRC_LIST})

include(CheckCSourceRuns)

include_directories(${DWEBVIEW_INCLUDE_DIRS})
target_link_libraries(${NAME} dcom dbus ${DWEBVIEW_LIBRARIES})

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/${NAME}
    DESTINATION bin
    )
install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}
    DESTINATION ${RESOURCE_DIR}
    )
