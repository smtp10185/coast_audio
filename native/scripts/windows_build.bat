@echo off
setlocal enabledelayedexpansion

REM Change directory to repository root (native) based on the script location
pushd "%~dp0\.."

REM Create build directory for Windows
if not exist build\windows (
    mkdir build\windows
)
pushd build\windows

REM Configure the project using CMake from native directory
cmake ..\.. ^
  -DCMAKE_INSTALL_PREFIX="..\..\build\windows" ^
  -DOS=WINDOWS ^
  -DSHARED=YES

REM Build the project in Release configuration
cmake --build . --config Release

REM Install the built targets
cmake --install . --config Release

popd

REM Create prebuilt directory for Windows
if not exist prebuilt\windows (
    mkdir prebuilt\windows
)

if exist build\windows\Release\coast_audio.dll (
    copy /Y build\windows\Release\coast_audio.dll prebuilt\windows\coast_audio.dll
) else if exist build\windows\Release\libcoast_audio.dll (
    copy /Y build\windows\Release\libcoast_audio.dll prebuilt\windows\libcoast_audio.dll
) else (
    echo DLL not found in build\windows\Release
)

REM Clean up build folder
rmdir /S /Q build\windows

endlocal
