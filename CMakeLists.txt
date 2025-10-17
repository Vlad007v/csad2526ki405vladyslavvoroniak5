cmake_minimum_required(VERSION 3.10)

project(csad2526ki405vladyslavvoroniak5 VERSION 0.1.0 LANGUAGES CXX)

# Use C++17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Add executable
add_executable(${PROJECT_NAME} main.cpp)

# Install rule (optional)
install(TARGETS ${PROJECT_NAME}
        RUNTIME DESTINATION bin)

# Enable testing (placeholder)
enable_testing()
