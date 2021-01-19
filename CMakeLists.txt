project(common)

# Create a header-only library
add_library(${PROJECT_NAME} INTERFACE)

# Ensure clients can find the includes
target_include_directories(${PROJECT_NAME} INTERFACE include)

# What to install
install(DIRECTORY include/makestuff DESTINATION include)

configure_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/common.pc.in
  ${CMAKE_CURRENT_BINARY_DIR}/common.pc
@ONLY)

install(
  FILES ${CMAKE_CURRENT_BINARY_DIR}/common.pc
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig
)
