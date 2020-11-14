project(common)

# Create a header-only library
add_library(${PROJECT_NAME} INTERFACE)

# Ensure clients can find the includes
target_include_directories(${PROJECT_NAME} INTERFACE include)

# What to install
install(DIRECTORY include/makestuff DESTINATION include)
