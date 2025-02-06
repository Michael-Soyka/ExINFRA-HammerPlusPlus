@echo off

:: DONT TOUCH CODE BELOW 
reg.exe query "HKU\S-1-5-19">nul 2>&1
if %errorlevel% equ 1 goto UACPrompt

title GameDir linker (C) Moon-6 Team 2022-2025

rem rmdir "%~dp0\game"
rem rmdir "%~dp0\root"
rem rmdir "%~dp0\platform"

set /p "SDK2013MP=ENTER INFRA PATH: "

mklink /d "%~dp0\game" "%SDK2013MP%\infra"
mklink /d "%~dp0\platform" "%SDK2013MP%\platform"
mklink /d "%~dp0\root" "%SDK2013MP%"
exit /b

:UACPrompt
mshta "vbscript:CreateObject("Shell.Application").ShellExecute("%~fs0", "", "", "runas", 1) & Close()"
exit /b