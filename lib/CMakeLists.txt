cmake_minimum_required(VERSION 2.8)
include_directories(${DWEBVIEW_INCLUDE_DIRS})


execute_process(
    COMMAND ${BIN_JSC_GEN} "jsc_extension" "--no-init"
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    )

AUX_SOURCE_DIRECTORY(jsc_extension JSC)
AUX_SOURCE_DIRECTORY(jsc_extension/gen/ JSC_GEN)



set(SRC_LIST utils.c webview.c xdg_misc.c pixbuf.c X_misc.c category.c
    ${JSC} ${JSC_GEN})

add_library(dcom ${SRC_LIST})
target_link_libraries(dcom ${DWEBVIEW_LIBRAIRES})

add_subdirectory(dbus)
