cmake_minimum_required(VERSION 3.16)

file(READ "${CMAKE_CURRENT_LIST_DIR}/../CMakeLists.txt" CMAKELISTS)
string(REGEX MATCH "project\\([^\\(]*VERSION[ \n]+([0-9]+\.[0-9]+)" REGEX_MATCH "${CMAKELISTS}")
if(NOT REGEX_MATCH)
    message(FATAL_ERROR "Could not extract project version from CMakeLists.txt")
endif()
set(PROJECT_VERSION "${CMAKE_MATCH_1}")

if(DEFINED LATEST_RELEASE_VERSION)
    string(LENGTH "${LATEST_RELEASE_VERSION}" LATEST_RELEASE_VERSION_LENGTH)
    string(SUBSTRING "${LATEST_RELEASE_VERSION}" 0 1 LATEST_RELEASE_VERSION_FRONT)
    if(LATEST_RELEASE_VERSION_FRONT STREQUAL "v")
        string(SUBSTRING "${LATEST_RELEASE_VERSION}" 1 ${LATEST_RELEASE_VERSION_LENGTH} LATEST_RELEASE_VERSION_BACK)
        set(LATEST_RELEASE_VERSION "${LATEST_RELEASE_VERSION_BACK}" CACHE "STRING" "" FORCE)
    endif()
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")
include(Package)

set(DEB_SOURCE_PKG_DIR "${CMAKE_CURRENT_LIST_DIR}/../debian")
set(DISTROSERIES "jammy")
file(WRITE "${DEB_SOURCE_PKG_DIR}/control"
"Source: ${DEBIAN_PACKAGE_NAME}
Priority: optional
Maintainer: ${CPACK_DEBIAN_PACKAGE_MAINTAINER}
Build-Depends: cmake, build-essential, debhelper-compat (=13)
Homepage: ${CPACK_DEBIAN_PACKAGE_HOMEPAGE}
Standards-Version: 4.6.2

Package: ${DEBIAN_PACKAGE_NAME}
Architecture: ${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}
Description: ${CPACK_PACKAGE_DESCRIPTION}
"
)
string(TIMESTAMP CURRENT_TIMESTAMP "%a, %d %b %Y %H:%M:%S +0000" UTC)
file(WRITE "${DEB_SOURCE_PKG_DIR}/changelog"
"${DEBIAN_PACKAGE_NAME} (${PACKAGE_VERSION_REVISION}ppa0) ${DISTROSERIES}; urgency=low

  * Version ${PACKAGE_VERSION_REVISION}ppa0

 -- ${CPACK_DEBIAN_PACKAGE_MAINTAINER}  ${CURRENT_TIMESTAMP}
")
file(WRITE "${DEB_SOURCE_PKG_DIR}/rules"
"#!/usr/bin/make -f
%:
\tdh $@

override_dh_auto_configure:
\tdh_auto_configure -- -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF
")
