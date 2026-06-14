cmake_minimum_required(VERSION 3.14)

cmake_policy(SET CMP0079 NEW)

set(BINARY_NAME "muvi")

# Disable Windows macros that collide with C++ standard library.
add_definitions(-DNOMINMAX -DWIN32_LEAN_AND_MEAN)

cmake_policy(SET CMP0063 NEW)

# App icons
set(APP_ICON_RESOURCE_FILES "${CMAKE_CURRENT_SOURCE_DIR}/resources/app_icon.rc")

add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "${APP_ICON_RESOURCE_FILES}"
)

apply_standard_settings(${BINARY_NAME})
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)
