@echo off
echo Building %1...

if exist "R:\Environment\Environment.bat" (
    call R:\Environment\Environment.bat
)

if "%MSBUILDPATH%"=="" (
    set MSBUILDDIR=%WINDIR%\Microsoft.NET\Framework\v3.5
)

set builder="%MSBUILDDIR%\msbuild.exe"

call %builder% %1