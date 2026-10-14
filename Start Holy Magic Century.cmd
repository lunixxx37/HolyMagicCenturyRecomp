@echo off
rem Starts Holy Magic Century: Recompiled from the portable run folder (double-click this file).
rem Extra arguments are passed on, e.g. --game hmc_en to skip the launcher.
cd /d "%~dp0run" || exit /b 1
start "" "%~dp0out\build\workspace-release\HolyMagicCenturyRecompiled.exe" %*
