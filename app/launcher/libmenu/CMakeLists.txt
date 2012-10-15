
add_library(menu STATIC canonicalize.c desktop-entries.c entry-directories.c gmenu-tree.c menu-layout.c menu-monitor.c menu-util.c)

find_package(PkgConfig)
pkg_check_modules(UNIXGIO REQUIRED gio-unix-2.0)
pkg_check_modules(GLIB REQUIRED glib-2.0)
include_directories(${UNIXGIO_INCLUDE_DIRS} ${GLIB_INCLUDE_DIRS})

target_link_libraries(menu ${GIO_LIBRARIES})
