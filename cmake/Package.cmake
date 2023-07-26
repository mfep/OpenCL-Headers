set(CPACK_PACKAGE_VENDOR "khronos")

set(CPACK_PACKAGE_DESCRIPTION "OpenCL (Open Computing Language) C header files")

set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")

set(CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/README.md")

if(NOT CPACK_PACKAGING_INSTALL_PREFIX)
  set(CPACK_PACKAGING_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")
endif()

# Configuring pkgconfig

# We need two different instances of OpenCL-Headers.pc
# One for installing (cmake --install), which contains CMAKE_INSTALL_PREFIX as prefix
# And another for the Debian package, which contains CPACK_PACKAGING_INSTALL_PREFIX as prefix

join_paths(OPENCL_INCLUDEDIR_PC "\${prefix}" "${CMAKE_INSTALL_INCLUDEDIR}")

set(pkg_config_location ${CMAKE_INSTALL_DATADIR}/pkgconfig)
set(PKGCONFIG_PREFIX "${CMAKE_INSTALL_PREFIX}")
configure_file(
  OpenCL-Headers.pc.in
  ${CMAKE_CURRENT_BINARY_DIR}/pkgconfig_install/OpenCL-Headers.pc
  @ONLY)
install(
  FILES ${CMAKE_CURRENT_BINARY_DIR}/pkgconfig_install/OpenCL-Headers.pc
  DESTINATION ${pkg_config_location}
  COMPONENT pkgconfig_install)

if(NOT (CMAKE_VERSION VERSION_LESS "3.5"))
  set(PKGCONFIG_PREFIX "${CPACK_PACKAGING_INSTALL_PREFIX}")
  configure_file(
    OpenCL-Headers.pc.in
    ${CMAKE_CURRENT_BINARY_DIR}/pkgconfig_package/OpenCL-Headers.pc
    @ONLY)
  # This install component is only needed in the Debian package
  install(
    FILES ${CMAKE_CURRENT_BINARY_DIR}/pkgconfig_package/OpenCL-Headers.pc
    DESTINATION ${pkg_config_location}
    COMPONENT pkgconfig_package
    EXCLUDE_FROM_ALL)

  # By using component based packaging, component pkgconfig_install
  # can be excluded from the package, and component pkgconfig_package
  # can be included.
  set(CPACK_DEB_COMPONENT_INSTALL ON)
  set(CPACK_COMPONENTS_GROUPING "ALL_COMPONENTS_IN_ONE")

  include(CPackComponent)
  cpack_add_component(pkgconfig_install)
  cpack_add_component(pkgconfig_package)
  set(CPACK_COMPONENTS_ALL "Unspecified;pkgconfig_package")
elseif(NOT (CMAKE_INSTALL_PREFIX STREQUAL CPACK_PACKAGING_INSTALL_PREFIX))
  message(FATAL_ERROR "When using CMake version < 3.5, CPACK_PACKAGING_INSTALL_PREFIX should not be set,"
    " or should be the same as CMAKE_INSTALL_PREFIX")
endif()

# DEB packaging configuration
set(CPACK_DEBIAN_PACKAGE_MAINTAINER ${CPACK_PACKAGE_VENDOR})

set(CPACK_DEBIAN_PACKAGE_HOMEPAGE
    "https://github.com/KhronosGroup/OpenCL-Headers")

# Version number [epoch:]upstream_version[-debian_revision]
set(LATEST_RELEASE_VERSION "2023.04.17")
set(CPACK_DEBIAN_PACKAGE_VERSION "${PROJECT_VERSION}~${LATEST_RELEASE_VERSION}")  # upstream_version
set(CPACK_DEBIAN_PACKAGE_RELEASE "1") # debian_revision (because this is a
                                      # non-native pkg)
set(PACKAGE_VERSION_REVISION "${CPACK_DEBIAN_PACKAGE_VERSION}-${CPACK_DEBIAN_PACKAGE_RELEASE}")

set(DEBIAN_PACKAGE_NAME "opencl-c-headers")
set(CPACK_DEBIAN_PACKAGE_NAME
    "${DEBIAN_PACKAGE_NAME}"
    CACHE STRING "Package name" FORCE)

# Get architecture
execute_process(COMMAND dpkg "--print-architecture" OUTPUT_VARIABLE CPACK_DEBIAN_PACKAGE_ARCHITECTURE)
string(STRIP "${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}" CPACK_DEBIAN_PACKAGE_ARCHITECTURE)

# Package file name in deb format:
# <PackageName>_<VersionNumber>-<DebianRevisionNumber>_<DebianArchitecture>.deb
set(CPACK_DEBIAN_FILE_NAME "${CPACK_PACKAGE_VENDOR}-${DEBIAN_PACKAGE_NAME}_${PACKAGE_VERSION_REVISION}_${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}.deb")

set(CPACK_DEBIAN_PACKAGE_DEBUG ON)

include(CPack)
