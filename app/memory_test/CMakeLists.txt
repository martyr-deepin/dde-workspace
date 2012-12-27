SET(NAME "memory_test")

pkg_check_modules(LIGHTDM REQUIRED liblightdm-gobject-1)

GEN_JSC_SOURCE("jsc" JSC_GEN)

SET(SRC_LIST main.c test.c greeter.c ${JSC_GEN})

add_executable(${NAME} ${SRC_LIST})

target_link_libraries(${NAME} dcom  ${DWEBVIEW_LIBRARIES} ${LIGHTDM_LIBRARIES})

include_directories(${DWEBVIEW_INCLUDE_DIRS} ${LIGHTDM_INCLUDE_DIRS})

execute_process(
    COMMAND make
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}/js
    )
