# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION 3.5)

file(MAKE_DIRECTORY
  "C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/_deps/dxc-src"
  "C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/_deps/dxc-build"
  "C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/_deps/dxc-subbuild/dxc-populate-prefix"
  "C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/_deps/dxc-subbuild/dxc-populate-prefix/tmp"
  "C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/_deps/dxc-subbuild/dxc-populate-prefix/src/dxc-populate-stamp"
  "C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/_deps/dxc-subbuild/dxc-populate-prefix/src"
  "C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/_deps/dxc-subbuild/dxc-populate-prefix/src/dxc-populate-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/_deps/dxc-subbuild/dxc-populate-prefix/src/dxc-populate-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "C:/Eloi/Abertay/CMP505-MastersProject/CGT_CMP504_MASTERS_PROJECT/out/build/x64-Debug/_deps/dxc-subbuild/dxc-populate-prefix/src/dxc-populate-stamp${cfgdir}") # cfgdir has leading slash
endif()
