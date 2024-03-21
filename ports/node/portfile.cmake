set(NODE_VERSION 18.16.0)
vcpkg_download_distfile(ARCHIVE
  URLS "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}.tar.gz"
  FILENAME "node-v${NODE_VERSION}.tar.gz"
  SHA512 0533f998af9df1e4894af9bace85ed0d731f5859c61146f147305761319289277920cfb545d7430829247f8a6a3ca74a6b3d2904961af99f79670af33d1b64e4
)

vcpkg_extract_source_archive(
  SOURCE_PATH
  ARCHIVE ${ARCHIVE}
  PATCHES node_install_dbg.patch
)
set(ENV{CC} "ccache cc")
set(ENV{CXX} "ccache c++")

set(build_dir_release "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel")
set(build_dir_debug "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg")
file(REMOVE_RECURSE
        "${build_dir_release}"
        "${build_dir_debug}"
)
file(MAKE_DIRECTORY "${build_dir_release}")
if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
  file(MAKE_DIRECTORY "${build_dir_debug}")
endif()

vcpkg_list(SET config_cmd
  "./configure" "--verbose" "--prefix=${CURRENT_PACKAGES_DIR}" "--shared" "--shared-zlib" "--without-intl"
)

set(configuring_message "Configuring ${TARGET_TRIPLET}")
set(building_message "Building ${TARGET_TRIPLET}")
set(installing_message "Installing ${TARGET_TRIPLET}")


z_vcpkg_get_cmake_vars(cmake_vars_file)
include("${cmake_vars_file}")
set(cmake_vars_file "${cmake_vars_file}" CACHE INTERNAL "") # Don't run z_vcpkg_get_cmake_vars twice


message(STATUS "${configuring_message}")
vcpkg_execute_build_process(
  COMMAND ${config_cmd}
  WORKING_DIRECTORY ${SOURCE_PATH}
  LOGNAME node-configure
)

if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "Release")
  message(STATUS "${building_message} (Release configuration)")
  vcpkg_execute_build_process(
    COMMAND make -C out -j ${VCPKG_CONCURRENCY} BUILDTYPE=Release V=1
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME node-build-rel
  )
  message(STATUS "${installing_message} (Release configuration)")
  vcpkg_execute_build_process(
    COMMAND python3 ./tools/install.py install / ${CURRENT_PACKAGES_DIR}
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME node-install-rel
  )
endif()

if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "Debug")
  message(STATUS "${building_message} (Debug configuration)")
  vcpkg_execute_build_process(
    COMMAND make -C out -j ${VCPKG_CONCURRENCY} BUILDTYPE=Debug V=1
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME node-build-dbg
  )
  message(STATUS "${installing_message} (Debug configuration)")
  set($ENV{BUILDTYPE} Debug)
  vcpkg_execute_build_process(
    COMMAND python3 ./tools/install.py install / ${CURRENT_PACKAGES_DIR}/debug
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME node-install-dbg
  )
endif()

vcpkg_fixup_pkgconfig()
