# Install script for directory: C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT

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

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/donut/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/feature_demo/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/examples/basic_triangle/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/examples/vertex_buffer/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/examples/deferred_shading/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/examples/headless/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/examples/bindless_rendering/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/examples/variable_shading/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/examples/rt_triangle/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/examples/rt_shadows/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/examples/rt_bindless/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/examples/rt_particles/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/examples/meshlets/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/examples/threaded_rendering/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/examples/rt_reflections/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/examples/shader_specializations/cmake_install.cmake")
endif()

if(CMAKE_INSTALL_COMPONENT)
  set(CMAKE_INSTALL_MANIFEST "install_manifest_${CMAKE_INSTALL_COMPONENT}.txt")
else()
  set(CMAKE_INSTALL_MANIFEST "install_manifest.txt")
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
file(WRITE "C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/${CMAKE_INSTALL_MANIFEST}"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
