cmake_minimum_required(VERSION 2.8)

macro(GEN_JSC_SOURCE CFG_DIR JSC_GEN)
    execute_process(
        COMMAND ${BIN_JSC_GEN} "${CMAKE_CURRENT_SOURCE_DIR}/${CFG_DIR}"
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
        )
    AUX_SOURCE_DIRECTORY(${CMAKE_CURRENT_BINARY_DIR} JSC_GEN)
endmacro()
macro(GEN_JSC_SOURCE_WITH_NO_INIT CFG_DIR JSC_GEN)
    execute_process(
        COMMAND ${BIN_JSC_GEN} "${CMAKE_CURRENT_SOURCE_DIR}/${CFG_DIR}" "-no-init"
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
        )
    AUX_SOURCE_DIRECTORY(${CMAKE_CURRENT_BINARY_DIR} JSC_GEN)
endmacro()

if (DEVELOP)
    SET(RESOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/resources/")
    add_definitions("-DDATA_DIR=\"../data\"")
else()
    SET(RESOURCE_DIR "${CMAKE_INSTALL_PREFIX}/share/dde/resources/")
    add_definitions("-DDATA_DIR=\"${CMAKE_INSTALL_PREFIX}/share/dde/data\"")
endif()

add_definitions("-DRESOURCE_DIR=\"${RESOURCE_DIR}\"")

find_package(PkgConfig)
pkg_check_modules(WEBKIT REQUIRED deepin-webkit-3.0)

set(CMAKE_C_FLAGS "-std=c99")



set(JSC_HEADER ${CMAKE_CURRENT_SOURCE_DIR}/lib/jsc_extension/)
include_directories(${JSC_HEADER})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/lib)

set(BIN_JSC_GEN ${CMAKE_CURRENT_SOURCE_DIR}/lib/jsc_extension/jsc_gen.py)

set(DWEBVIEW_INCLUDE_DIRS ${WEBKIT_INCLUDE_DIRS}) 
set(DWEBVIEW_LIBRARIES ${WEBKIT_LIBRARIES} ${DBUS_LIBRARIES})
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR})


add_subdirectory(lib)
add_subdirectory(app)
add_subdirectory(po)
add_subdirectory(test)

install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/schemas
    DESTINATION ${CMAKE_INSTALL_PREFIX}/share/glib-2.0
)
install(
    DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/data
    DESTINATION ${CMAKE_INSTALL_PREFIX}/share/dde
    )
