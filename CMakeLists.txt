cmake_minimum_required(VERSION 3.8)

project(libmbus
        LANGUAGES CXX
                  C)

execute_process(COMMAND git
                        describe
                WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                RESULT_VARIABLE retcode
                OUTPUT_VARIABLE PROJECT_VERSION)
if(NOT "${retcode}" STREQUAL "0")
  set(PROJECT_VERSION "0.0.0")
  message(STATUS "could not get git tag, setting version to ${PROJECT_VERSION}")
endif()

if(CMAKE_BUILD_TYPE STREQUAL "")
  message(STATUS "CMAKE_BUILD_TYPE empty setting to Debug")
  set(CMAKE_BUILD_TYPE "Debug")
endif()

option(LIBMBUS_BUILD_EXAMPLES
       "build examples"
       ON)

set(CMAKE_CXX_STANDARD 17)

# Append our module directory to CMake
list(APPEND CMAKE_MODULE_PATH
            ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
list(APPEND CMAKE_MODULE_PATH
            ${CMAKE_BINARY_DIR})

# Set the output of the libraries and executables.
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin)
set(LIBRARY_OUTPUT_PATH ${PROJECT_BINARY_DIR}/lib)

###
### static analysis
###

if(LIBMBUS_RUN_CLANG_TIDY)
  find_program(CLANG_TIDY_EXE NAMES "clang-tidy" DOC "/usr/bin/clang-tidy")
  if(NOT CLANG_TIDY_EXE)
    message(WARNING "clang-tidy not found.")
  else()
    message(STATUS "clang-tidy found: ${CLANG_TIDY_EXE}")
    set(DO_CLANG_TIDY "${CLANG_TIDY_EXE}")
  endif()
endif(LIBMBUS_RUN_CLANG_TIDY)

###
### library
###

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/mbus/config.h.in
               ${CMAKE_CURRENT_BINARY_DIR}/mbus/config.h)

add_library(${PROJECT_NAME}
            ${CMAKE_CURRENT_SOURCE_DIR}/mbus/mbus.c
            ${CMAKE_CURRENT_SOURCE_DIR}/mbus/mbus.h
            ${CMAKE_CURRENT_SOURCE_DIR}/mbus/mbus-protocol-aux.c
            ${CMAKE_CURRENT_SOURCE_DIR}/mbus/mbus-protocol-aux.h
            ${CMAKE_CURRENT_SOURCE_DIR}/mbus/mbus-protocol.c
            ${CMAKE_CURRENT_SOURCE_DIR}/mbus/mbus-protocol.h
            ${CMAKE_CURRENT_SOURCE_DIR}/mbus/mbus-serial.c
            ${CMAKE_CURRENT_SOURCE_DIR}/mbus/mbus-serial.h
            ${CMAKE_CURRENT_SOURCE_DIR}/mbus/mbus-tcp.c
            ${CMAKE_CURRENT_SOURCE_DIR}/mbus/mbus-tcp.h)
target_include_directories(${PROJECT_NAME}
                           PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/mbus>
                                  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
                                  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/mbus>
                                  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
                           PRIVATE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/mbus/)
# target_compile_options(
#   ${PROJECT_NAME}
#   PRIVATE $<$<OR:$<CXX_COMPILER_ID:AppleClang>,$<CXX_COMPILER_ID:GNU>,$<CXX_COMPILER_ID:Clang>>:-Wall>
#           $<$<OR:$<CXX_COMPILER_ID:AppleClang>,$<CXX_COMPILER_ID:GNU>,$<CXX_COMPILER_ID:Clang>>:-pedantic>
#           $<$<OR:$<CXX_COMPILER_ID:AppleClang>,$<CXX_COMPILER_ID:GNU>,$<CXX_COMPILER_ID:Clang>>:-Wextra>)
if(CLANG_TIDY_EXE)
  set_target_properties(${PROJECT_NAME}
                        PROPERTIES CXX_CLANG_TIDY
                                   "${DO_CLANG_TIDY}")
endif()

add_library(${PROJECT_NAME}::${PROJECT_NAME}
            ALIAS
            ${PROJECT_NAME})

###
### examples
###

if(LIBMBUS_BUILD_EXAMPLES)
  message(STATUS "building examples")
  add_subdirectory(example)
endif()

###
### tests
###

if(LIBMBUS_BUILD_TESTS)
  message(STATUS "building tests")
  enable_testing()
  find_package(GTest)
  add_subdirectory(test)
endif()

###
### install
###

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

set(LIBMBUS_CONFIG_INSTALL_DIR ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME})
install(TARGETS ${PROJECT_NAME}
        EXPORT ${PROJECT_NAME}Targets
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT lib
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT lib)

install(EXPORT ${PROJECT_NAME}Targets
        DESTINATION ${LIBMBUS_CONFIG_INSTALL_DIR}
        NAMESPACE ${PROJECT_NAME}::
        COMPONENT dev)

configure_package_config_file(cmake/Config.cmake.in
                              ${PROJECT_NAME}Config.cmake
                              INSTALL_DESTINATION
                              ${LIBMBUS_CONFIG_INSTALL_DIR})
write_basic_package_version_file(${PROJECT_NAME}ConfigVersion.cmake COMPATIBILITY SameMajorVersion)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
              ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
        DESTINATION ${LIBMBUS_CONFIG_INSTALL_DIR}
        COMPONENT dev)
install(DIRECTORY include/
                  ${CMAKE_CURRENT_BINARY_DIR}/include/
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
        COMPONENT dev
        FILES_MATCHING
        PATTERN "*.h")
