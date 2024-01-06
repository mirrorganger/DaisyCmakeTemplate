cmake_minimum_required(VERSION 3.26.0)
project(DaisyCmakeTemplate VERSION 0.1.0 LANGUAGES C CXX ASM)

include(cmake/daisy-setup.cmake)

add_subdirectory(${LIBDAISY_DIR} libdaisy)
add_subdirectory(${DAISYSP_DIR} DaisySP)
add_subdirectory(App)

