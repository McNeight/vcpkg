# Common Ambient Variables:
#   VCPKG_ROOT_DIR = <C:\path\to\current\vcpkg>
#   TARGET_TRIPLET is the current triplet (x86-windows, etc)
#   PORT is the current port name (zlib, etc)
#   CURRENT_BUILDTREES_DIR = ${VCPKG_ROOT_DIR}\buildtrees\${PORT}
#   CURRENT_PACKAGES_DIR  = ${VCPKG_ROOT_DIR}\packages\${PORT}_${TARGET_TRIPLET}
#

include(vcpkg_common_functions)
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/fltk-1.3.4-2)
vcpkg_download_distfile(ARCHIVE
    URLS "http://fltk.org/pub/fltk/1.3.4/fltk-1.3.4-2-source.tar.gz"
    FILENAME "fltk-1.3.4-2-source.tar.gz"
    SHA512 cc169449b71ca966b2043ceedc55e92220ccb6be07b0ac54eeec36bbed5d60e2f59c6faba2403b5292b9120f5255227880a066d98ac82e57d502522bc627fd4d
)
vcpkg_extract_source_archive(${ARCHIVE})

vcpkg_apply_patches(
    SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/fltk-1.3.4-2
    PATCHES "${CMAKE_CURRENT_LIST_DIR}/findlibsfix.patch"
)

if (VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    set(BUILD_SHARED ON)
else()
    set(BUILD_SHARED OFF)
endif()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
        -DOPTION_BUILD_EXAMPLES=OFF
        -DOPTION_USE_SYSTEM_ZLIB=ON
        -DOPTION_USE_SYSTEM_LIBPNG=ON
        -DOPTION_USE_SYSTEM_LIBJPEG=ON
        -DOPTION_BUILD_SHARED_LIBS=${BUILD_SHARED}
)

vcpkg_install_cmake()

file(REMOVE_RECURSE
    ${CURRENT_PACKAGES_DIR}/CMAKE
    ${CURRENT_PACKAGES_DIR}/debug/CMAKE
    ${CURRENT_PACKAGES_DIR}/debug/include
)

file(COPY ${CURRENT_PACKAGES_DIR}/bin/fluid.exe DESTINATION ${CURRENT_PACKAGES_DIR}/tools/fltk)
file(REMOVE ${CURRENT_PACKAGES_DIR}/bin/fluid.exe)
file(REMOVE ${CURRENT_PACKAGES_DIR}/bin/fltk-config)

file(REMOVE ${CURRENT_PACKAGES_DIR}/debug/bin/fluid.exe)
file(REMOVE ${CURRENT_PACKAGES_DIR}/debug/bin/fltk-config)

vcpkg_copy_pdbs()

vcpkg_copy_tool_dependencies(${CURRENT_PACKAGES_DIR}/tools/fltk)

if(VCPKG_LIBRARY_LINKAGE STREQUAL static)
    file(REMOVE_RECURSE
        ${CURRENT_PACKAGES_DIR}/debug/bin
        ${CURRENT_PACKAGES_DIR}/bin
    )
else()
    file(GLOB SHARED_LIBS "${CURRENT_PACKAGES_DIR}/lib/*_SHARED.lib" "${CURRENT_PACKAGES_DIR}/debug/lib/*_SHAREDd.lib")
    file(GLOB STATIC_LIBS "${CURRENT_PACKAGES_DIR}/lib/*.lib" "${CURRENT_PACKAGES_DIR}/debug/lib/*.lib")
    list(FILTER STATIC_LIBS EXCLUDE REGEX "_SHAREDd?\\.lib\$")
    file(REMOVE ${STATIC_LIBS})
    foreach(SHARED_LIB ${SHARED_LIBS})
        string(REGEX REPLACE "_SHARED(d?)\\.lib\$" "\\1.lib" NEWNAME ${SHARED_LIB})
        file(RENAME ${SHARED_LIB} ${NEWNAME})
    endforeach()
endif()

foreach(FILE Fl_Export.H fl_utf8.h)
    file(READ ${CURRENT_PACKAGES_DIR}/include/FL/${FILE} FLTK_HEADER)
    if(VCPKG_LIBRARY_LINKAGE STREQUAL static)
        string(REPLACE "defined(FL_DLL)" "0" FLTK_HEADER "${FLTK_HEADER}")
    else()
        string(REPLACE "defined(FL_DLL)" "1" FLTK_HEADER "${FLTK_HEADER}")
    endif()
    file(WRITE ${CURRENT_PACKAGES_DIR}/include/FL/${FILE} "${FLTK_HEADER}")
endforeach()

file(INSTALL
    ${SOURCE_PATH}/COPYING
    DESTINATION ${CURRENT_PACKAGES_DIR}/share/fltk
    RENAME copyright
)
