cmake_minimum_required(VERSION 3.20)

# Build structure adapted from HarvestMoon64Recomp (GPL-3.0).
project(HolyMagicCenturyRecompiled LANGUAGES C CXX)
set(CMAKE_C_STANDARD 17)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Library checkouts. They default to the submodule layout under lib/; a shared
# workspace can point several game projects at the same checkouts instead.
set(HMC_RUNTIME_DIR "${CMAKE_SOURCE_DIR}/lib/N64ModernRuntime" CACHE PATH "N64ModernRuntime checkout")
set(HMC_RT64_DIR "${CMAKE_SOURCE_DIR}/lib/rt64" CACHE PATH "rt64 checkout")
set(HMC_FRONTEND_DIR "${CMAKE_SOURCE_DIR}/lib/RecompFrontend" CACHE PATH "RecompFrontend checkout")
set(HMC_DECOMP_DIR "${CMAKE_SOURCE_DIR}/lib/quest64-decomp" CACHE PATH "Quest64 decomp checkout (headers for patches)")
set(HMC_VARIANT "en" CACHE STRING "ROM variant to build (en = Holy Magic Century Europe)")

if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-everything /W4")
endif()

# Opt out of constexpr mutex constructor on windows to prevent vcredist issues
if (WIN32)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR")
endif()

# Avoid warning about DOWNLOAD_EXTRACT_TIMESTAMP in CMake 3.24:
if (CMAKE_VERSION VERSION_GREATER_EQUAL "3.24.0")
    cmake_policy(SET CMP0135 NEW)
endif()

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

set(RT64_STATIC TRUE)
set(RT64_SDL_WINDOW_VULKAN TRUE)
add_compile_definitions(HLSL_CPU)

if (WIN32)
    # rt64's D3D12 backend uses API additions (GPU upload heaps, D3D12_OPTIONS16) that older
    # Windows SDKs lack. Microsoft's DirectX-Headers provide them; they go ahead of the SDK.
    set(HMC_DIRECTX_HEADERS_DIR "" CACHE PATH "Optional DirectX-Headers checkout used ahead of the Windows SDK's D3D12 headers")
    if (HMC_DIRECTX_HEADERS_DIR)
        include_directories(BEFORE "${HMC_DIRECTX_HEADERS_DIR}/include/directx")
    endif()
endif()

add_subdirectory(${HMC_RT64_DIR} ${CMAKE_BINARY_DIR}/rt64)

set(BUILD_SHARED_LIBS OFF)

add_subdirectory(${HMC_RUNTIME_DIR} ${CMAKE_BINARY_DIR}/N64ModernRuntime)

target_include_directories(rt64 PRIVATE ${CMAKE_BINARY_DIR}/rt64/src)

set(RECOMP_INCLUDES
    ${CMAKE_SOURCE_DIR}/include
    ${HMC_RUNTIME_DIR}/ultramodern/include
    ${HMC_RUNTIME_DIR}/librecomp/include
    ${HMC_RUNTIME_DIR}/N64Recomp/include
)

# RecompiledFuncs - the recompiler output for the game itself (generated, see BUILDING.md)
add_library(RecompiledFuncs STATIC)
target_compile_options(RecompiledFuncs PRIVATE -fno-strict-aliasing -Wno-unused-variable -Wno-implicit-function-declaration)
target_include_directories(RecompiledFuncs PRIVATE ${RECOMP_INCLUDES})
file(GLOB FUNC_C_SOURCES ${CMAKE_SOURCE_DIR}/RecompiledFuncs/*.c)
file(GLOB FUNC_CXX_SOURCES ${CMAKE_SOURCE_DIR}/RecompiledFuncs/*.cpp)
target_sources(RecompiledFuncs PRIVATE ${FUNC_C_SOURCES} ${FUNC_CXX_SOURCES})

# PatchesLib - the recompiled output of patches/ (C compiled for MIPS, then recompiled)
add_library(PatchesLib STATIC)
target_compile_options(PatchesLib PRIVATE -fno-strict-aliasing -Wno-unused-variable -Wno-implicit-function-declaration)
target_include_directories(PatchesLib PRIVATE ${RECOMP_INCLUDES})
target_sources(PatchesLib PRIVATE
    ${CMAKE_SOURCE_DIR}/RecompiledPatches/patches.c
    ${CMAKE_SOURCE_DIR}/RecompiledPatches/patches_bin.c
)
set_source_files_properties(${CMAKE_SOURCE_DIR}/RecompiledPatches/patches.c PROPERTIES COMPILE_FLAGS -fno-strict-aliasing)

# Build the patches ELF with a MIPS-capable clang (Windows: the portable LLVM release, see BUILDING.md)
if (NOT DEFINED PATCHES_C_COMPILER)
    set(PATCHES_C_COMPILER clang)
endif()
if (NOT DEFINED PATCHES_LD)
    set(PATCHES_LD ld.lld)
endif()
find_program(N64RECOMP_EXECUTABLE N64Recomp REQUIRED)

add_custom_target(PatchesBin
    COMMAND ${CMAKE_COMMAND} -E env CC=${PATCHES_C_COMPILER} LD=${PATCHES_LD}
            make DECOMP_DIR=${HMC_DECOMP_DIR} RT64_DIR=${HMC_RT64_DIR}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/patches
    BYPRODUCTS ${CMAKE_SOURCE_DIR}/patches/patches.elf
)

# Generate patches_bin.c from patches.bin
add_custom_command(OUTPUT ${CMAKE_SOURCE_DIR}/RecompiledPatches/patches_bin.c
    COMMAND file_to_c ${CMAKE_SOURCE_DIR}/patches/patches.bin game_patches_bin ${CMAKE_SOURCE_DIR}/RecompiledPatches/patches_bin.c ${CMAKE_SOURCE_DIR}/RecompiledPatches/patches_bin.h
    DEPENDS ${CMAKE_SOURCE_DIR}/patches/patches.bin
)

# Recompile the patches ELF into patches.c and patches.bin
add_custom_command(OUTPUT
        ${CMAKE_SOURCE_DIR}/patches/patches.bin
        ${CMAKE_SOURCE_DIR}/RecompiledPatches/patches.c
        ${CMAKE_SOURCE_DIR}/RecompiledPatches/recomp_overlays.inl
        ${CMAKE_SOURCE_DIR}/RecompiledPatches/funcs.h
    COMMAND ${N64RECOMP_EXECUTABLE} patches.${HMC_VARIANT}.toml
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    DEPENDS ${CMAKE_SOURCE_DIR}/patches/patches.elf
)

# Main executable
add_executable(HolyMagicCenturyRecompiled)

set(SOURCES
    ${CMAKE_SOURCE_DIR}/src/main/main.cpp
    ${CMAKE_SOURCE_DIR}/src/main/register_overlays.cpp
    ${CMAKE_SOURCE_DIR}/src/main/register_patches.cpp

    ${CMAKE_SOURCE_DIR}/src/game/config.cpp
    ${CMAKE_SOURCE_DIR}/src/game/recomp_api.cpp
    ${CMAKE_SOURCE_DIR}/src/game/unknown_symbols.cpp

    ${CMAKE_SOURCE_DIR}/rsp/aspMain.cpp
)

target_include_directories(HolyMagicCenturyRecompiled PRIVATE
    ${CMAKE_SOURCE_DIR}/include
    ${HMC_RUNTIME_DIR}/N64Recomp/include
    ${HMC_RUNTIME_DIR}/thirdparty/sse2neon
    ${HMC_RT64_DIR}/src/contrib
    ${HMC_RT64_DIR}/src/contrib/hlslpp/include
    ${HMC_RT64_DIR}/src/contrib/dxc/inc
    ${HMC_RT64_DIR}/src
    ${HMC_RT64_DIR}/src/rhi
    ${HMC_RT64_DIR}/src/render
    ${HMC_FRONTEND_DIR}/recompinput/include
    ${HMC_FRONTEND_DIR}/recompui/include
    ${HMC_FRONTEND_DIR}/recompui/src
    ${HMC_RT64_DIR}/src/contrib/nativefiledialog-extended/src/include
    ${CMAKE_CURRENT_BINARY_DIR}
)

if (CMAKE_SIZEOF_VOID_P EQUAL 8 AND CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|amd64|AMD64")
    target_compile_options(HolyMagicCenturyRecompiled PRIVATE -march=nehalem -fno-strict-aliasing -fms-extensions)
else()
    target_compile_options(HolyMagicCenturyRecompiled PRIVATE -fno-strict-aliasing -fms-extensions)
endif()

if (MSVC)
    # Disable identical code folding, since this breaks mod function patching as multiple functions can get merged into one.
    target_link_options(HolyMagicCenturyRecompiled PRIVATE /OPT:NOICF)
endif()

if (WIN32)
    include(FetchContent)
    if (DEFINED ENV{SDL2_VERSION})
        set(SDL2_VERSION $ENV{SDL2_VERSION})
    else()
        set(SDL2_VERSION "2.30.3")
    endif()

    # Fetch SDL2 on windows
    FetchContent_Declare(
        sdl2
        URL https://github.com/libsdl-org/SDL/releases/download/release-${SDL2_VERSION}/SDL2-devel-${SDL2_VERSION}-VC.zip
    )
    FetchContent_MakeAvailable(sdl2)
    target_include_directories(HolyMagicCenturyRecompiled PRIVATE ${sdl2_SOURCE_DIR}/include)
    target_link_directories(HolyMagicCenturyRecompiled PRIVATE ${sdl2_SOURCE_DIR}/lib/x64)

    # Copy SDL2 and dxc DLLs to output folder as post build step
    add_custom_command(TARGET HolyMagicCenturyRecompiled POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${sdl2_SOURCE_DIR}/lib/x64/SDL2.dll"
            "${HMC_RT64_DIR}/src/contrib/dxc/bin/x64/dxil.dll"
            "${HMC_RT64_DIR}/src/contrib/dxc/bin/x64/dxcompiler.dll"
            $<TARGET_FILE_DIR:HolyMagicCenturyRecompiled>)

    option(HMC_CONSOLE "Use the console subsystem in all build types (logs on stdout/stderr)" OFF)
    if (HMC_CONSOLE)
        set(HMC_NON_DEBUG_SUBSYSTEM "/SUBSYSTEM:CONSOLE")
    else()
        set(HMC_NON_DEBUG_SUBSYSTEM "/SUBSYSTEM:WINDOWS /ENTRY:mainCRTStartup")
    endif()
    set_target_properties(HolyMagicCenturyRecompiled PROPERTIES
        LINK_FLAGS_DEBUG "/SUBSYSTEM:CONSOLE"
        LINK_FLAGS_RELEASE "${HMC_NON_DEBUG_SUBSYSTEM}"
        LINK_FLAGS_RELWITHDEBINFO "${HMC_NON_DEBUG_SUBSYSTEM}"
        LINK_FLAGS_MINSIZEREL "${HMC_NON_DEBUG_SUBSYSTEM}"
    )

    target_link_libraries(HolyMagicCenturyRecompiled PRIVATE SDL2 Winmm.lib)
endif()

if (CMAKE_SYSTEM_NAME MATCHES "Linux")
    find_package(SDL2 REQUIRED)
    add_compile_definitions("PLUME_SDL_VULKAN_ENABLED")
    add_compile_definitions("RT64_SDL_WINDOW_VULKAN")
    target_include_directories(HolyMagicCenturyRecompiled PRIVATE ${SDL2_INCLUDE_DIRS})

    find_package(Freetype REQUIRED)
    include_directories(${FREETYPE_LIBRARIES})
    target_link_libraries(HolyMagicCenturyRecompiled PRIVATE ${FREETYPE_LIBRARIES} SDL2::SDL2)

    set(CMAKE_THREAD_PREFER_PTHREAD TRUE)
    set(THREADS_PREFER_PTHREAD_FLAG TRUE)
    find_package(Threads REQUIRED)
    target_link_libraries(HolyMagicCenturyRecompiled PRIVATE "-latomic -static-libstdc++" ${CMAKE_DL_LIBS} Threads::Threads)
endif()

# TODO fix the rt64 CMake script so that this doesn't need to be duplicated here
# For DXC
set(DXC_COMMON_OPTS "-I${PROJECT_SOURCE_DIR}/src")
set(DXC_DXIL_OPTS "-Wno-ignored-attributes")
set(DXC_SPV_OPTS "-spirv" "-fspv-target-env=vulkan1.0" "-fvk-use-dx-layout")
set(DXC_PS_OPTS "${DXC_COMMON_OPTS}" "-E" "PSMain" "-T ps_6_0" "-D DYNAMIC_RENDER_PARAMS")
set(DXC_VS_OPTS "${DXC_COMMON_OPTS}" "-E" "VSMain" "-T vs_6_0" "-D DYNAMIC_RENDER_PARAMS" "-fvk-invert-y")
set(DXC_CS_OPTS "${DXC_COMMON_OPTS}" "-E" "CSMain" "-T cs_6_0")
set(DXC_GS_OPTS "${DXC_COMMON_OPTS}" "-E" "GSMain" "-T gs_6_0")
set(DXC_RT_OPTS "${DXC_COMMON_OPTS}" "-D" "RT_SHADER" "-T" "lib_6_3" "-fspv-target-env=vulkan1.1spirv1.4" "-fspv-extension=SPV_KHR_ray_tracing" "-fspv-extension=SPV_EXT_descriptor_indexing")

if (WIN32)
    set(DXC "${HMC_RT64_DIR}/src/contrib/dxc/bin/x64/dxc.exe")
    add_compile_definitions(NOMINMAX)
elseif (CMAKE_SIZEOF_VOID_P EQUAL 8 AND CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|amd64|AMD64")
    set(DXC "LD_LIBRARY_PATH=${HMC_RT64_DIR}/src/contrib/dxc/lib/x64" "${HMC_RT64_DIR}/src/contrib/dxc/bin/x64/dxc-linux")
else()
    set(DXC "LD_LIBRARY_PATH=${HMC_RT64_DIR}/src/contrib/dxc/lib/arm64" "${HMC_RT64_DIR}/src/contrib/dxc/bin/arm64/dxc-linux")
endif()

set(RECOMP_FRONTEND_N64MODERNRUNTIME_PATH ${HMC_RUNTIME_DIR})
set(RECOMP_FRONTEND_RT64_PATH ${HMC_RT64_DIR})

add_subdirectory(${HMC_FRONTEND_DIR} ${CMAKE_BINARY_DIR}/RecompFrontend)

target_link_libraries(HolyMagicCenturyRecompiled PRIVATE
    PatchesLib
    RecompiledFuncs
    recompui
    recompinput
    librecomp
    ultramodern
    rt64
    nfd
)

# Embed all .nrm files in the "mods" directory as built-in mods
file(GLOB NRM_FILES "${CMAKE_SOURCE_DIR}/mods/*.nrm")
set(GENERATED_NRM_SOURCES "")
foreach(NRM_FILE ${NRM_FILES})
    get_filename_component(NRM_NAME ${NRM_FILE} NAME_WE)
    set(OUT_C "${CMAKE_CURRENT_BINARY_DIR}/mods/${NRM_NAME}.c")
    set(OUT_H "${CMAKE_CURRENT_BINARY_DIR}/mods/${NRM_NAME}.h")
    add_custom_command(
        OUTPUT ${OUT_C} ${OUT_H}
        COMMAND file_to_c ${NRM_FILE} ${NRM_NAME} ${OUT_C} ${OUT_H}
        DEPENDS ${NRM_FILE}
    )
    list(APPEND GENERATED_NRM_SOURCES ${OUT_C})
endforeach()
target_sources(HolyMagicCenturyRecompiled PRIVATE ${GENERATED_NRM_SOURCES})

target_sources(HolyMagicCenturyRecompiled PRIVATE ${SOURCES})

set_property(TARGET HolyMagicCenturyRecompiled PROPERTY VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}")
