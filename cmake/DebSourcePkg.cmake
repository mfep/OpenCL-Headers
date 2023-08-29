# This script produces the changelog, control and rules file in the debian
# directory. These files are needed to build a Debian source package from the repository.
# Run this in CMake script mode, e.g.
# $ cd OpenCL-Headers
# $ cmake
#    -DCPACK_DEBIAN_PACKAGE_MAINTAINER="Example Name <example@example.com>"
#    -DDEBIAN_DISTROSERIES=jammy
#    -DORIG_ARCHIVE=../OpenCL-Headers.tar.gz
#    -DLATEST_RELEASE_VERSION=v2023.08.29
#    -P cmake/DebSourcePkg.cmake
# $ debuild -S -sa

cmake_minimum_required(VERSION 3.21) # file(COPY_FILE) is added in CMake 3.21

if(NOT DEFINED DEBIAN_PACKAGE_MAINTAINER)
    message(FATAL_ERROR "DEBIAN_PACKAGE_MAINTAINER is not set")
endif()
if(NOT DEFINED DEBIAN_DISTROSERIES)
    message(FATAL_ERROR "DEBIAN_DISTROSERIES is not set")
endif()
if(NOT DEFINED ORIG_ARCHIVE)
    message(WARNING "ORIG_ARCHIVE is not set")
endif()
if(NOT DEFINED LATEST_RELEASE_VERSION)
    message(WARNING "LATEST_RELEASE_VERSION is not set")
endif()
if(NOT DEFINED DEBIAN_VERSION_SUFFIX)
    message(WARNING "DEBIAN_VERSION_SUFFIX is not set")
endif()

# Extracting the project version from the main CMakeLists.txt via regex
file(READ "${CMAKE_CURRENT_LIST_DIR}/../CMakeLists.txt" CMAKELISTS)
string(REGEX MATCH "project\\([^\\(]*VERSION[ \n]+([0-9]+\.[0-9]+)" REGEX_MATCH "${CMAKELISTS}")
if(NOT REGEX_MATCH)
    message(FATAL_ERROR "Could not extract project version from CMakeLists.txt")
endif()
set(PROJECT_VERSION "${CMAKE_MATCH_1}")

if(DEFINED LATEST_RELEASE_VERSION)
    # Remove leading "v", if exists
    string(LENGTH "${LATEST_RELEASE_VERSION}" LATEST_RELEASE_VERSION_LENGTH)
    string(SUBSTRING "${LATEST_RELEASE_VERSION}" 0 1 LATEST_RELEASE_VERSION_FRONT)
    if(LATEST_RELEASE_VERSION_FRONT STREQUAL "v")
        string(SUBSTRING "${LATEST_RELEASE_VERSION}" 1 ${LATEST_RELEASE_VERSION_LENGTH} LATEST_RELEASE_VERSION)
    endif()
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")
# Package.cmake contains all details for packaging
include(Package)

set(DEB_SOURCE_PKG_DIR "${CMAKE_CURRENT_LIST_DIR}/../debian")
# Write debian/control
file(WRITE "${DEB_SOURCE_PKG_DIR}/control"
"Source: ${DEBIAN_PACKAGE_NAME}
Section: devel
Priority: optional
Maintainer: ${DEBIAN_PACKAGE_MAINTAINER}
Build-Depends: cmake, debhelper-compat (=13)
Homepage: ${CPACK_DEBIAN_PACKAGE_HOMEPAGE}
Standards-Version: 4.6.2.0

Package: ${DEBIAN_PACKAGE_NAME}
Architecture: ${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}
Description: ${CPACK_PACKAGE_DESCRIPTION}
"
)
# Write debian/changelog
string(TIMESTAMP CURRENT_TIMESTAMP "%a, %d %b %Y %H:%M:%S +0000" UTC)
file(WRITE "${DEB_SOURCE_PKG_DIR}/changelog"
"${DEBIAN_PACKAGE_NAME} (${PACKAGE_VERSION_REVISION}ppa0) ${DEBIAN_DISTROSERIES}; urgency=low

  * Released version ${PACKAGE_VERSION_REVISION}ppa0

 -- ${DEBIAN_PACKAGE_MAINTAINER}  ${CURRENT_TIMESTAMP}
")
# Write debian/rules
file(WRITE "${DEB_SOURCE_PKG_DIR}/rules"
"#!/usr/bin/make -f
%:
\tdh $@

override_dh_auto_configure:
\tdh_auto_configure -- -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF
")

if(DEFINED ORIG_ARCHIVE)
    # Copy the passed orig.tar.gz file. The target filename is deduced from the version number, as expected by debuild
    cmake_path(IS_ABSOLUTE ORIG_ARCHIVE IS_ORIG_ARCHIVE_ABSOLUTE)
    if (NOT IS_ORIG_ARCHIVE_ABSOLUTE)
        message(FATAL_ERROR "ORIG_ARCHIVE must be an absolute path (passed: \"${ORIG_ARCHIVE}\")")
    endif()
    cmake_path(GET ORIG_ARCHIVE EXTENSION ORIG_ARCHIVE_EXT)
    cmake_path(GET ORIG_ARCHIVE PARENT_PATH ORIG_ARCHIVE_PARENT)
    set(TARGET_PATH "${ORIG_ARCHIVE_PARENT}/${CPACK_PACKAGE_VENDOR}-${DEBIAN_PACKAGE_NAME}_${CPACK_DEBIAN_PACKAGE_VERSION}${ORIG_ARCHIVE_EXT}")
    message(STATUS "Copying \"${ORIG_ARCHIVE}\" to \"${TARGET_PATH}\"")
    file(COPY_FILE "${ORIG_ARCHIVE}" "${TARGET_PATH}")
endif()
