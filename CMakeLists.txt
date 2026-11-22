cmake_minimum_required(VERSION 3.12)
project(kwaf LANGUAGES C CXX)

set(KANGLE_DIR "" CACHE PATH "Path to the installed kangle directory")
set(KANGLE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../kangle" CACHE PATH
    "Path to the kangle source tree")

if(NOT KANGLE_DIR)
    message(FATAL_ERROR
        "KANGLE_DIR is required and must point to the installed kangle directory")
endif()
if(NOT IS_DIRECTORY "${KANGLE_DIR}")
    message(FATAL_ERROR "KANGLE_DIR does not exist: ${KANGLE_DIR}")
endif()
set(KWAF_KANGLE_SOURCES
    "${KANGLE_SOURCE_DIR}/khttpd/src/KHttpHeader.cpp"
    "${KANGLE_SOURCE_DIR}/khttpd/src/KHttpLib.cpp"
    "${KANGLE_SOURCE_DIR}/khttpd/src/KStream.cpp"
    "${KANGLE_SOURCE_DIR}/khttpd/src/KAutoBuffer.cpp"
    "${KANGLE_SOURCE_DIR}/khttpd/src/KStringBuf.cpp"
    "${KANGLE_SOURCE_DIR}/src/KSequence.cpp"
    "${KANGLE_SOURCE_DIR}/src/KTargetRate.cpp"
    "${KANGLE_SOURCE_DIR}/src/kmd5.cpp"
    "${KANGLE_SOURCE_DIR}/kasync/src/krbtree.c"
    "${KANGLE_SOURCE_DIR}/kasync/src/kmalloc.c")

if(NOT EXISTS "${KANGLE_SOURCE_DIR}/include/ksapi.h"
   OR NOT EXISTS "${KANGLE_SOURCE_DIR}/khttpd/include/KHttpHeader.h"
   OR NOT EXISTS "${KANGLE_SOURCE_DIR}/kasync/include/kmalloc.h")
    message(FATAL_ERROR
        "Cannot find the kangle source tree. Set KANGLE_SOURCE_DIR to the matching "
        "kangle source directory.")
endif()
foreach(source_file IN LISTS KWAF_KANGLE_SOURCES)
    if(NOT EXISTS "${source_file}")
        message(FATAL_ERROR "Required kangle source file is missing: ${source_file}")
    endif()
endforeach()

set(KANGLE_INCLUDE_DIRS)
if(EXISTS "${KANGLE_DIR}/include/ksapi.h"
   AND EXISTS "${KANGLE_DIR}/include/kasync_config.h"
   AND EXISTS "${KANGLE_DIR}/include/khttp.h")
    list(APPEND KANGLE_INCLUDE_DIRS "${KANGLE_DIR}/include")
else()
    if(NOT EXISTS "${KANGLE_SOURCE_DIR}/kasync/include/kasync_config.h.in"
       OR NOT EXISTS "${KANGLE_SOURCE_DIR}/khttpd/include/khttp.h.in")
        message(FATAL_ERROR
            "Cannot find installed kangle development headers or their source "
            "templates. Check KANGLE_DIR and KANGLE_SOURCE_DIR.")
    endif()

    set(GENERATED_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated")
    file(MAKE_DIRECTORY "${GENERATED_INCLUDE_DIR}")
    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        set(LINUX ON)
    elseif(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
        set(FREEBSD ON)
    elseif(APPLE)
        set(DARWIN ON)
    endif()
    configure_file(
        "${KANGLE_SOURCE_DIR}/kasync/include/kasync_config.h.in"
        "${GENERATED_INCLUDE_DIR}/kasync_config.h")
    configure_file(
        "${KANGLE_SOURCE_DIR}/khttpd/include/khttp.h.in"
        "${GENERATED_INCLUDE_DIR}/khttp.h")
    list(APPEND KANGLE_INCLUDE_DIRS "${GENERATED_INCLUDE_DIR}")
endif()
list(APPEND KANGLE_INCLUDE_DIRS
    "${KANGLE_SOURCE_DIR}/include"
    "${KANGLE_SOURCE_DIR}/kasync/include"
    "${KANGLE_SOURCE_DIR}/kasync/fcontext/src"
    "${KANGLE_SOURCE_DIR}/khttpd/include"
    "${KANGLE_SOURCE_DIR}/khttpd/davlib")

file(GLOB KWAF_SOURCE_FILES CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp")
list(APPEND KWAF_SOURCE_FILES ${KWAF_KANGLE_SOURCES})
set_source_files_properties(${KWAF_SOURCE_FILES} PROPERTIES LANGUAGE CXX)

add_library(kwaf MODULE ${KWAF_SOURCE_FILES})
set_target_properties(kwaf PROPERTIES PREFIX "" LINKER_LANGUAGE CXX)
set_property(TARGET kwaf PROPERTY CXX_STANDARD 14)
set_property(TARGET kwaf PROPERTY CXX_STANDARD_REQUIRED ON)
if(MSVC)
    # kangle 源码为 UTF-8 中文注释，MSVC 默认按本地代码页解析会报 C2447
    target_compile_options(kwaf PRIVATE /utf-8)
    if(NOT ZLIB_LIBRARY)
        # vcpkg 的静态 zlib 库名为 zs.lib，FindZLIB 默认不识别
        find_library(ZLIB_LIBRARY NAMES zs zlibstatic zlib z)
    endif()
endif()
find_package(ZLIB REQUIRED)
target_include_directories(kwaf PRIVATE
    ${KANGLE_INCLUDE_DIRS})
target_link_libraries(kwaf PRIVATE ZLIB::ZLIB)

set(CMAKE_INSTALL_PREFIX "${KANGLE_DIR}" CACHE PATH "Install path prefix" FORCE)
install(TARGETS kwaf
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION bin)
install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/ext/" DESTINATION ext)

set(CPACK_PACKAGE_NAME "kwaf")
include(CPack)
