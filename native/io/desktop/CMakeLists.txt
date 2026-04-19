cmake_minimum_required(VERSION 3.10)

# Il nome del progetto può rimanere generico
project(image_pipeline_native C)

find_package(PkgConfig REQUIRED)
pkg_check_modules(VIPS REQUIRED vips)

add_library(transformer SHARED transform.c)

set_target_properties(transformer PROPERTIES 
    OUTPUT_NAME "transformer"
    PREFIX "io_desktop_"  
)

target_include_directories(transformer PRIVATE ${VIPS_INCLUDE_DIRS})
target_link_directories(transformer PRIVATE ${VIPS_LIBRARY_DIRS})
target_link_libraries(transformer PRIVATE ${VIPS_LIBRARIES})

target_compile_options(transformer PRIVATE -O3)