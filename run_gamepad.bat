@echo off
title Zybo Snake Game - EvoFox Controller Bridge
cd /d "%~dp0"
echo ========================================================
echo   Launching Zybo Snake Game Controller Bridge...
echo ========================================================
py -m pip install pyserial pygame
echo.
py play_gamepad.py
pause
