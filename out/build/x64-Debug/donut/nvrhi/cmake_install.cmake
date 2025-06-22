# Install script for directory: C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/donut/nvrhi

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/install/x64-Debug")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Debug")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/install/x64-Debug/include/nvrhi")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/install/x64-Debug/include" TYPE DIRECTORY FILES "C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/donut/nvrhi/include/nvrhi")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/donut/nvrhi/nvrhi.lib")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/donut/nvrhi/nvrhi_d3d11.lib")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  include("C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/donut/nvrhi/CMakeFiles/nvrhi_d3d11.dir/install-cxx-module-bmi-Debug.cmake" OPTIONAL)
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/donut/nvrhi/nvrhi_d3d12.lib")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  include("C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/donut/nvrhi/CMakeFiles/nvrhi_d3d12.dir/install-cxx-module-bmi-Debug.cmake" OPTIONAL)
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/donut/nvrhi/nvrhi_vk.lib")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  include("C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/donut/nvrhi/CMakeFiles/nvrhi_vk.dir/install-cxx-module-bmi-Debug.cmake" OPTIONAL)
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for each subdirectory.
  include("C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/donut/nvrhi/thirdparty/Vulkan-Headers/cmake_install.cmake")
  include("C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/donut/nvrhi/thirdparty/DirectX-Headers/cmake_install.cmake")

endif()

