add_executable(main ${CMAKE_CURRENT_LIST_DIR}/main.cpp)
target_link_libraries(main PRIVATE libmbus::libmbus)
