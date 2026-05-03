cmake_minimum_required(VERSION 3.10)

# Il nome del progetto può rimanere generico
project(image_pipeline_native C)

find_package(PkgConfig REQUIRED)
pkg_check_modules(VIPS REQUIRED IMPORTED_TARGET vips)

add_library(transformer SHARED transform.c)

set_target_properties(transformer PROPERTIES 
  OUTPUT_NAME "io_desktop_transformer"
  PREFIX ""
  IMPORT_PREFIX ""
)

target_link_libraries(transformer PRIVATE PkgConfig::VIPS)

target_compile_options(transformer PRIVATE -O3)